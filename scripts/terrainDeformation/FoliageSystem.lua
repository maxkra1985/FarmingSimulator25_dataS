FoliageSystem = {}
local FoliageSystem_mt = Class(FoliageSystem)
g_xmlManager:addInitSchemaFunction(function()
	local xmlSchemaFruitType = FruitTypeDesc.xmlSchema
	DensityMapHeightManager.registerXMLPaths(xmlSchemaFruitType, "foliageType")
	FruitTypeManager.registerXMLPaths(xmlSchemaFruitType, "foliageType")
	FillTypeManager.registerXMLPaths(xmlSchemaFruitType, "foliageType")
	MotionPathEffectManager.registerMotionPathXMLFiles(xmlSchemaFruitType, "foliageType")
	local xmlSchemaFillType = FillTypeManager.xmlSchema
	FillTypeManager.registerXMLPaths(xmlSchemaFillType, "foliageType")
end)
function FoliageSystem.new(customMt)
	local self = setmetatable({}, customMt or FoliageSystem_mt)
	self.terrainRootNode = 0
	self.paintableFoliages = {}
	self.decoFoliages = {}
	self.decoFoliageMappings = {}
	self.modFoliageTypesToLoad = {}
	return self
end
function FoliageSystem:delete()
	self.paintableFoliages = {}
	self.decoFoliages = {}
	self.modFoliageTypesToLoad = {}
end
function FoliageSystem:loadMapData(mapXmlFile, missionInfo, baseDirectory)
	local xmlFile = XMLFile.wrap(mapXmlFile)
	xmlFile:iterate("map.paintableFoliages.paintableFoliage", function(index, key)
		local layerName = xmlFile:getString(key .. "#layerName")
		if layerName ~= nil then
			local startStateChannel = xmlFile:getInt(key .. "#startChannel", 0)
			local numStateChannels = xmlFile:getInt(key .. "#numChannels", 4)
			local state = xmlFile:getInt(key .. "#state", 0)
			local paintableFoliage = { layerName = layerName, startStateChannel = startStateChannel, numStateChannels = numStateChannels, state = state }
			paintableFoliage.id = #self.paintableFoliages + 1
			table.insert(self.paintableFoliages, paintableFoliage)
		else
			Logging.xmlWarning(xmlFile, "Missing layerName for paintableFoliage '%s'", key)
		end
	end)
	local decoFoliageLayerNames = {}
	xmlFile:iterate("map.decoFoliages.decoFoliage", function(index, key)
		local decoFoliage = {}
		decoFoliage.layerName = xmlFile:getString(key .. "#layerName")
		if decoFoliage.layerName ~= nil then
			decoFoliage.startStateChannel = xmlFile:getInt(key .. "#startChannel", 0)
			decoFoliage.numStateChannels = xmlFile:getInt(key .. "#numChannels", 4)
			decoFoliage.mowable = xmlFile:getBool(key .. "#mowable")
			decoFoliageLayerNames[string.upper(decoFoliage.layerName)] = decoFoliage
			table.insert(self.decoFoliages, decoFoliage)
		else
			Logging.xmlWarning(xmlFile, "Missing layerName for decoFoliage '%s'", key)
		end
	end)
	self.decoFoliageMappings = {}
	xmlFile:iterate("map.decoFoliages.mapping", function(index, key)
		local name = xmlFile:getString(key .. "#name")
		if name ~= nil then
			local nameUpper = string.upper(name)
			if self.decoFoliageMappings[nameUpper] == nil then
				local layerName = xmlFile:getString(key .. "#layerName")
				if layerName ~= nil then
					local layerNameUpper = string.upper(layerName)
					local decoFoliage = decoFoliageLayerNames[layerNameUpper]
					if decoFoliage ~= nil then
						local state = xmlFile:getInt(key .. "#state")
						self.decoFoliageMappings[nameUpper] = { decoFoliage = decoFoliage, state = state }
						return
					else
						Logging.xmlWarning(xmlFile, "Mapping layerName '%s' not defined deco foliages for '%s'", layerName, key)
						return
					end
				end
				Logging.xmlWarning(xmlFile, "Missing layerName for decoFoliage mapping '%s'", key)
				return
			else
				Logging.xmlWarning(xmlFile, "Name '%s' already defined for decoFoliage mapping '%s'", name, key)
				return
			end
		end
		Logging.xmlWarning(xmlFile, "Missing name for decoFoliage mapping '%s'", key)
	end)
	xmlFile:delete()
	self.modFoliageTypesToLoad = missionInfo.foliageTypes or self.modFoliageTypesToLoad
	local newFoliageTypes = g_fruitTypeManager.modFoliageTypesToLoad
	for i = 1, #newFoliageTypes do
		local newFoliageType = newFoliageTypes[i]
		self:addModFoliageType(newFoliageType.name, newFoliageType.filename)
	end
	for i = 1, #self.modFoliageTypesToLoad do
		local foliageType = self.modFoliageTypesToLoad[i]
		self:loadModFoliageType(foliageType.name, foliageType.filename)
	end
	if 0 < #self.modFoliageTypesToLoad then
		g_fruitTypeManager:initializeFruitTypeConverters()
	end
	return true
end
function FoliageSystem:unloadMapData()
	self.paintableFoliages = {}
end
function FoliageSystem:streamWriteModFoliageTypes(streamId, connection)
	streamWriteUInt8(streamId, #self.modFoliageTypesToLoad)
	for _, foliageType in ipairs(self.modFoliageTypesToLoad) do
		streamWriteString(streamId, foliageType.name)
		streamWriteString(streamId, NetworkUtil.convertToNetworkFilename(foliageType.filename))
	end
end
function FoliageSystem:streamReadModFoliageTypes(streamId, connection)
	local numLoadedFoliageTypes = 0
	local numTypes = streamReadUInt8(streamId)
	for i = 1, numTypes do
		local name = streamReadString(streamId)
		local filename = NetworkUtil.convertFromNetworkFilename(streamReadString(streamId))
		if self:addModFoliageType(name, filename) and self:loadModFoliageType(name, filename) then
			numLoadedFoliageTypes = numLoadedFoliageTypes + numLoadedFoliageTypes
		end
	end
	if 0 < numLoadedFoliageTypes then
		g_fruitTypeManager:initializeFruitTypeConverters()
	end
end
function FoliageSystem:saveToXMLFile(xmlFile)
	for i = 1, #self.modFoliageTypesToLoad do
		local foliageType = self.modFoliageTypesToLoad[i]
		local key = string.format("careerSavegame.foliageTypes.foliageType(%d)", i - 1)
		setXMLString(xmlFile, key .. "#name", foliageType.name)
		setXMLString(xmlFile, key .. "#filename", NetworkUtil.convertToNetworkFilename(foliageType.filename))
	end
end
function FoliageSystem:initTerrain(mission, terrainRootNode, terrainDetailId)
	self.terrainRootNode = terrainRootNode
	for key, paintableFoliage in pairs(self.paintableFoliages) do
		local id, _ = getTerrainDataPlaneByName(self.terrainRootNode, paintableFoliage.layerName)
		if id ~= nil then
			if id ~= 0 then
				paintableFoliage.terrainDataPlaneId = id
				paintableFoliage.paintModifier = DensityMapModifier.new(id, paintableFoliage.startStateChannel, paintableFoliage.numStateChannels, terrainRootNode)
				paintableFoliage.paintFilter = DensityMapFilter.new(paintableFoliage.paintModifier)
			else
				paintableFoliage.disabled = true
			end
		end
	end
	for key, decoFoliage in pairs(self.decoFoliages) do
		local id, _ = getTerrainDataPlaneByName(self.terrainRootNode, decoFoliage.layerName)
		if id == nil or id == 0 then
			continue
		end
		decoFoliage.terrainDataPlaneId = id
		decoFoliage.modifier = DensityMapModifier.new(id, decoFoliage.startStateChannel, decoFoliage.numStateChannels, terrainRootNode)
	end
	self:loadModFoliageTypes()
end
function FoliageSystem:addDensityMapSyncer(densityMapSyncer)
	for key, decoFoliage in pairs(self.decoFoliages) do
		if decoFoliage.terrainDataPlaneId == nil then
			continue
		end
		densityMapSyncer:addDensityMap(decoFoliage.terrainDataPlaneId)
	end
end
function FoliageSystem:applyAreas(modifiedAreas, paintTerrainFoliageId)
	for _, paintableFoliage in pairs(self.paintableFoliages) do
		if paintableFoliage.id == paintTerrainFoliageId then
			if paintableFoliage.disabled then
				continue
			end
			for _, area in pairs(modifiedAreas) do
				local x, z, x1, z1, x2, z2 = unpack(area)
				self:apply(paintableFoliage, x, z, x1 - x, z1 - z, x2 - x, z2 - z)
			end
			return true
		end
	end
	return false
end
function FoliageSystem:getFoliagePaint(id)
	for _, paintableFoliage in pairs(self.paintableFoliages) do
		if paintableFoliage.id == id then
			if paintableFoliage.disabled then
				continue
			end
			return paintableFoliage
		end
	end
	return nil
end
function FoliageSystem:getFoliagePaintByName(name)
	for _, paintableFoliage in pairs(self.paintableFoliages) do
		if paintableFoliage.layerName == name then
			if paintableFoliage.disabled then
				continue
			end
			return paintableFoliage
		end
	end
	return nil
end
function FoliageSystem:apply(foliage, x, z, x1, z1, x2, z2, value)
	local modifier = foliage.paintModifier
	local filter = foliage.paintFilter
	if value == nil then
		value = foliage.value
	end
	modifier:setParallelogramWorldCoords(x, z, x1, z1, x2, z2, DensityCoordType.POINT_POINT_POINT)
	filter:setValueCompareParams(DensityValueCompareType.NOTEQUAL, value)
	local _, numPixels, _ = modifier:executeSetWithStats(value, filter)
	return numPixels / 4
end
function FoliageSystem:getDecoFoliages()
	return self.decoFoliages
end
function FoliageSystem:getIsDecoLayerDefined(decoName)
	local nameUpper = string.upper(decoName)
	local data = self.decoFoliageMappings[nameUpper]
	return data ~= nil
end
function FoliageSystem:getDensityMapData(decoFoliageName)
	local data = self.decoFoliageMappings[string.upper(decoFoliageName)]
	if data == nil then
		return nil
	else
		local decoFoliage = data.decoFoliage
		return decoFoliage.terrainDataPlaneId, decoFoliage.startStateChannel, decoFoliage.numStateChannels, data.state
	end
end
function FoliageSystem:applyDecoFoliage(decoName, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	local nameUpper = string.upper(decoName)
	local data = self.decoFoliageMappings[nameUpper]
	if data ~= nil then
		local decoFoliage = data.decoFoliage
		local state = data.state
		local modifier = decoFoliage.modifier
		if modifier ~= nil then
			modifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
			modifier:executeSet(state)
		end
	end
end
function FoliageSystem:loadModFoliageType(name, filename, missionInfo, baseDirectory)
	if g_fruitTypeManager.filenameToFruitType[filename] ~= nil then
		Logging.devInfo("FoliageSystem - FoliageType '%s' already loaded from '%s'", name, filename)
		return false
	end
	local foliageXMLFile = XMLFile.load("fillTypeXMLFile", filename, FruitTypeDesc.xmlSchema)
	if foliageXMLFile ~= nil then
		local foliageXMLFileHandle = foliageXMLFile:getHandle()
		g_fillTypeManager:loadFillTypes(foliageXMLFile, "", false, nil, true)
		g_fruitTypeManager:loadFruitTypeFromXML(filename)
		g_fruitTypeManager:loadMapCategoriesAndConverters(foliageXMLFileHandle, missionInfo, baseDirectory)
		g_densityMapHeightManager:loadDensityMapHeightTypes(foliageXMLFile, missionInfo, nil, false)
		g_motionPathEffectManager:loadMotionPathEffects(foliageXMLFileHandle, "foliageType.motionPathEffects.motionPathEffect", baseDirectory, nil)
		foliageXMLFile:delete()
		Logging.devInfo("FoliageSystem - Loaded mod foliageType '%s'", name)
		return true
	else
		return false
	end
end
function FoliageSystem:addModFoliageType(name, configFilename)
	for j = 1, #self.modFoliageTypesToLoad do
		local foliageType = self.modFoliageTypesToLoad[j]
		if name == foliageType.name then
			Logging.devWarning("FoliageSystem - Mod foliageType '%s' is already added. Skipping...", name)
			return false
		end
	end
	Logging.devWarning("FoliageSystem - Added Mod foliageType '%s'", name)
	table.insert(self.modFoliageTypesToLoad, { name = name, filename = configFilename })
	return true
end
local _sub = string.sub
local _len = string.len
local _oldaddFoliageTypeFromXML = addFoliageTypeFromXML
local _addFoliageTypeFromXML = function(terrainId, dmId, name, xmlFilename)
	local path = "data/foliage"
	if _sub(xmlFilename, 1, 12) == "data/foliage" then
		return _oldaddFoliageTypeFromXML(terrainId, dmId, name, xmlFilename)
	else
		Logging.error("Failed to load foliage xml '%s'", xmlFilename)
		return nil
	end
end
function FoliageSystem:loadModFoliageTypes()
	local terrainNode = g_terrainNode
	for i = 1, #self.modFoliageTypesToLoad do
		local foliageType = self.modFoliageTypesToLoad[i]
		local id = nil
		local _ = nil
		for _, fruitType in ipairs(g_fruitTypeManager:getFruitTypes()) do
			id, _ = getTerrainDataPlaneByName(self.terrainRootNode, fruitType.layerName)
			if id == nil then
				continue
			end
			if id ~= nil then
				local dmId = id
				local name = foliageType.name
				local xmlFilename = foliageType.filename
				local path = "data/foliage"
				if _sub(xmlFilename, 1, 12) == "data/foliage" then
					_oldaddFoliageTypeFromXML(terrainNode, dmId, name, xmlFilename)
				else
					Logging.error("Failed to load foliage xml '%s'", xmlFilename)
				end
			else
				Logging.warning("Failed to load foliage xml '%s'", foliageType.filename)
			end
		end
	end
end
