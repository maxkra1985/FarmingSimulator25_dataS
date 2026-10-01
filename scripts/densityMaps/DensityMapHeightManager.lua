DensityMapHeightManager = {}
DensityMapHeightManager.GENERATED_TIP_COLLISION_FILENAME = "infoLayer_tipCollisionGenerated.grle"
DensityMapHeightManager.GENERATED_PLACEMENT_COLLISION_FILENAME = "infoLayer_placementCollisionGenerated.grle"
DensityMapHeightManager.DEBUG_ENABLED = false
DensityMapHeightManager.DEBUG_TIP_COLLISIONS = false
DensityMapHeightManager.DEBUG_PLACEMENT_COLLISIONS = false
DensityMapHeightManager.DEBUG_GROUP_ID = "densityMapHeight"
g_xmlManager:addCreateSchemaFunction(function()
	DensityMapHeightManager.xmlSchema = XMLSchema.new("densityMapHeightTypes")
end)
g_xmlManager:addInitSchemaFunction(function()
	DensityMapHeightManager.registerXMLPaths(DensityMapHeightManager.xmlSchema, "map")
	local missionXMLSchema = Mission00.xmlSchema
	DensityMapHeightManager.registerXMLPaths(missionXMLSchema, "map")
end)
function DensityMapHeightManager.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.INT, basePath .. ".densityMapHeightTypes#firstChannel", "First channel on the density map for height types", 0)
	schema:register(XMLValueType.INT, basePath .. ".densityMapHeightTypes#numChannels", "Number of channel on the density map for height types", 6)
	schema:register(XMLValueType.FLOAT, basePath .. ".densityMapHeightTypes.freeAccessArea(?)#x", "free accees area center world space x coordinate")
	schema:register(XMLValueType.FLOAT, basePath .. ".densityMapHeightTypes.freeAccessArea(?)#z", "free accees area center world space z coordinate")
	schema:register(XMLValueType.FLOAT, basePath .. ".densityMapHeightTypes.freeAccessArea(?)#radius", "free accees area radius in meters")
	local typeKey = basePath .. ".densityMapHeightTypes.densityMapHeightType(?)"
	schema:register(XMLValueType.STRING, typeKey .. "#fillTypeName", "Name of the fill type")
	schema:register(XMLValueType.ANGLE, typeKey .. "#maxSurfaceAngle", "Max. surface angle for this fill type", 26)
	schema:register(XMLValueType.FLOAT, typeKey .. "#fillToGroundScale", "Scale factor for fill to ground", 1)
	schema:register(XMLValueType.BOOL, typeKey .. "#allowsSmoothing", "Allows smoothing", false)
	schema:register(XMLValueType.FLOAT, typeKey .. ".collision#scale", "Collision scale", 1)
	schema:register(XMLValueType.FLOAT, typeKey .. ".collision#baseOffset", "Collision base offset", 0)
	schema:register(XMLValueType.FLOAT, typeKey .. ".collision#minOffset", "Collision min offset", 0)
	schema:register(XMLValueType.FLOAT, typeKey .. ".collision#maxOffset", "Collision max offset", 1)
	schema:register(XMLValueType.BOOL, typeKey .. "#canBeTipped", "Can be tipped", true)
	schema:register(XMLValueType.INT, typeKey .. ".visualHeightMapping.mapping(?)#realValue", "Real density map value (1-64 when using 6 bits)")
	schema:register(XMLValueType.INT, typeKey .. ".visualHeightMapping.mapping(?)#visualValue", "Visual value to show when the real value is reached (1-64 when using 6 bits)")
end
local DensityMapHeightManager_mt = Class(DensityMapHeightManager, AbstractManager)
function DensityMapHeightManager.new(customMt)
	local self = AbstractManager.new(customMt or DensityMapHeightManager_mt)
	self.modDensityHeightMapTypeFilenames = {}
	return self
end
function DensityMapHeightManager:initDataStructures()
	self.numHeightTypes = 0
	self.heightTypes = {}
	self.fillTypeNameToHeightType = {}
	self.fillTypeIndexToHeightType = {}
	self.heightTypeIndexToFillTypeIndex = {}
	self.freeAccessAreas = {}
	self.fixedFillTypesAreas = {}
	self.convertingFillTypesAreas = {}
	self.tipTypeMappings = {}
	if self.terrainDetailHeightUpdater ~= nil then
		delete(self.terrainDetailHeightUpdater)
		self.terrainDetailHeightUpdater = nil
	end
	if self.tipCollisionMap ~= nil then
		if self.tipCollisionMapCreated then
			delete(self.tipCollisionMap)
			self.tipCollisionMapCreated = false
		end
		self.tipCollisionMap = nil
	end
	if self.placementCollisionMap ~= nil then
		if self.placementCollisionMapCreated then
			delete(self.placementCollisionMap)
			self.placementCollisionMapCreated = false
		end
		self.placementCollisionMap = nil
	end
	self.tipCollisionMask = CollisionFlag.GROUND_TIP_BLOCKING
	self.placementCollisionMask = CollisionFlag.PLACEMENT_BLOCKING
end
function DensityMapHeightManager:loadDefaultTypes(missionInfo, baseDirectory)
	self:initDataStructures()
	local xmlFile = loadXMLFile("heightTypes", "data/maps/maps_densityMapHeightTypes.xml")
	self:loadDensityMapHeightTypes(xmlFile, missionInfo, baseDirectory, true)
	delete(xmlFile)
end
function DensityMapHeightManager:loadMapData(xmlFile, missionInfo, baseDirectory)
	DensityMapHeightManager:superClass().loadMapData(self)
	if g_addCheatCommands then
		if g_server ~= nil then
			addConsoleCommand("gsTipCollisionsShow", "Shows the collisions for tipping on the ground", "consoleCommandShowTipCollisions", self)
			addConsoleCommand("gsTipCollisionsUpdate", "Updates the collisions for tipping on the ground around the current camera", "consoleCommandUpdateTipCollisions", self)
			addConsoleCommand("gsTipAnywhereAdd", "Tips a fillType", "consoleCommandTipAnywhereAdd", self, "fillTypeName; amount; [length]; [rows]; [spacing]")
			addConsoleCommand("gsTipAnywhereAddAll", "Tips a heap of every fill type that can be tipped", "consoleCommandTipAnywhereAddAll", self)
			addConsoleCommand("gsTipAnywhereClear", "Clears tip area", "consoleCommandTipAnywhereClear", self, "sizeToClearMeters")
		end
		addConsoleCommand("gsDensityMapToggleDebug", "Toggles debug mode", "consoleCommandToggleDebug", self)
		addConsoleCommand("gsPlacementCollisionsShow", "Shows the collisions for placement and terraforming", "consoleCommandShowPlacementCollisions", self)
	end
	self:loadDefaultTypes(missionInfo, baseDirectory)
	local success = XMLUtil.loadDataFromMapXML(xmlFile, "densityMapHeightTypes", baseDirectory, self, self.loadDensityMapHeightTypes, missionInfo, baseDirectory)
	return success
end
function DensityMapHeightManager:unloadMapData()
	DensityMapHeightManager:superClass().unloadMapData(self)
	removeConsoleCommand("gsTipAnywhereAdd")
	removeConsoleCommand("gsTipAnywhereAddAll")
	removeConsoleCommand("gsTipAnywhereClear")
	removeConsoleCommand("gsDensityMapToggleDebug")
	removeConsoleCommand("gsTipCollisionsShow")
	removeConsoleCommand("gsTipCollisionsUpdate")
	removeConsoleCommand("gsPlacementCollisionsShow")
	if self.debugBitVectorMapTipCollisionsId ~= nil then
		g_debugManager:removeElementById(self.debugBitVectorMapTipCollisionsId)
		self.debugBitVectorMapTipCollisionsId = nil
	end
	if self.debugBitVectorMapPlacementCollisionsId ~= nil then
		g_debugManager:removeElementById(self.debugBitVectorMapPlacementCollisionsId)
		self.debugBitVectorMapPlacementCollisionsId = nil
	end
end
function DensityMapHeightManager:loadDensityMapHeightTypes(xmlFile, missionInfo, baseDirectory, isBaseType)
	if type(xmlFile) ~= "table" then
		xmlFile = XMLFile.wrap(xmlFile, DensityMapHeightManager.xmlSchema)
	end
	local rootName = xmlFile:getRootName()
	self.heightTypeFirstChannel = xmlFile:getValue(rootName .. ".densityMapHeightTypes#firstChannel", self.heightTypeFirstChannel or 0)
	self.heightTypeNumChannels = math.max(xmlFile:getValue(rootName .. ".densityMapHeightTypes#numChannels", self.heightTypeNumChannels or 6), self.heightTypeNumChannels or 6)
	for _, key in xmlFile:iterator(rootName .. ".densityMapHeightTypes.densityMapHeightType") do
		self:loadDensityMapHeightTypeFromXML(xmlFile, key, isBaseType)
	end
	for _, key in xmlFile:iterator(rootName .. ".densityMapHeightTypes.freeAccessArea") do
		local x = xmlFile:getFloat(key .. "#x")
		local z = xmlFile:getFloat(key .. "#z")
		local radius = xmlFile:getFloat(key .. "#radius")
		if x == nil or z == nil or radius == nil then
			continue
		end
		local area = { x = x, z = z, radius = radius }
		table.insert(self.freeAccessAreas, area)
	end
	return true
end
function DensityMapHeightManager:addModDensityMapHeightTypes(xmlFilename)
	table.insert(self.modDensityHeightMapTypeFilenames, xmlFilename)
end
function DensityMapHeightManager:loadModDensityMapHeightTypes()
	for i = #self.modDensityHeightMapTypeFilenames, 1, -1 do
		local filename = self.modDensityHeightMapTypeFilenames[i]
		local heightTypesXmlFile = loadXMLFile("heightTypes", filename)
		if heightTypesXmlFile ~= 0 then
			self:loadDensityMapHeightTypes(heightTypesXmlFile, nil, nil, false)
			delete(heightTypesXmlFile)
		end
		self.modDensityHeightMapTypeFilenames[i] = nil
	end
end
function DensityMapHeightManager:loadFromXMLFile(xmlFilename)
	if xmlFilename == nil then
		return false
	end
	local xmlFile = XMLFile.load("densitymapHeightXML", xmlFilename)
	if xmlFile == nil then
		return false
	else
		self.tipTypeMappings = {}
		xmlFile:iterate("tipTypeMappings.tipTypeMapping", function(_, key)
			local name = xmlFile:getString(key .. "#fillType")
			local index = xmlFile:getInt(key .. "#index")
			if name ~= nil and index ~= nil then
				self.tipTypeMappings[string.lower(name)] = index
			end
		end)
		xmlFile:delete()
		return true
	end
end
function DensityMapHeightManager:saveToXMLFile(xmlFilename)
	local xmlFile = XMLFile.create("densityMapHeightXML", xmlFilename, "tipTypeMappings")
	if xmlFile ~= nil then
		for k, heightType in ipairs(self.heightTypes) do
			local mappingKey = string.format("tipTypeMappings.tipTypeMapping(%d)", k - 1)
			xmlFile:setString(mappingKey .. "#fillType", heightType.fillTypeName)
			xmlFile:setInt(mappingKey .. "#index", heightType.index)
		end
		xmlFile:save()
		xmlFile:delete()
		return true
	else
		return false
	end
end
local sortHeightTypes = function(a, b)
	return a.fillTypeIndex < b.fillTypeIndex
end
function DensityMapHeightManager:sortHeightTypes()
	table.sort(self.heightTypes, sortHeightTypes)
	for i = 1, #self.heightTypes do
		local heightType = self.heightTypes[i]
		heightType.index = i
		self.heightTypeIndexToFillTypeIndex[heightType.index] = heightType.fillTypeIndex
	end
end
function DensityMapHeightManager:loadDensityMapHeightTypeFromXML(xmlFile, key, isBaseType)
	local fillTypeName = xmlFile:getValue(key .. "#fillTypeName")
	local fillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(fillTypeName)
	if fillTypeIndex == nil then
		Logging.xmlError(xmlFile, "'%s' has invalid fill type '%s'!", key, fillTypeName)
	else
		if isBaseType and self.fillTypeNameToHeightType[fillTypeName] ~= nil then
			Logging.error("density height map for '%s' already exists!", fillTypeName)
			return
		end
		local heightType = self.fillTypeNameToHeightType[fillTypeName]
		if heightType == nil then
			local maxNumHeightTypes = 2 ^ g_densityMapHeightManager.heightTypeNumChannels - 1
			if maxNumHeightTypes <= self.numHeightTypes then
				Logging.error("addDensityMapHeightType %q: maximum number (%d) of height types already registered. Adjust densityMapHeightTypes#numChannels to allow for more", fillTypeName, maxNumHeightTypes)
				return
			end
			self.numHeightTypes = self.numHeightTypes + 1
			heightType = {}
			heightType.index = self.numHeightTypes
			heightType.fillTypeName = fillTypeName
			heightType.fillTypeIndex = fillTypeIndex
			table.insert(self.heightTypes, heightType)
			self.fillTypeNameToHeightType[fillTypeName] = heightType
			self.fillTypeIndexToHeightType[fillTypeIndex] = heightType
			self.heightTypeIndexToFillTypeIndex[heightType.index] = fillTypeIndex
			self:sortHeightTypes()
		end
		heightType.maxSurfaceAngle = xmlFile:getValue(key .. "#maxSurfaceAngle") or heightType.maxSurfaceAngle or 0.4537856055185257
		heightType.fillToGroundScale = xmlFile:getValue(key .. "#fillToGroundScale") or heightType.fillToGroundScale or 1
		heightType.allowsSmoothing = xmlFile:getValue(key .. "#allowsSmoothing", Utils.getNoNil(heightType.allowsSmoothing, false))
		heightType.collisionScale = xmlFile:getValue(key .. ".collision#scale") or heightType.collisionScale or 1
		heightType.collisionBaseOffset = xmlFile:getValue(key .. ".collision#baseOffset") or heightType.collisionBaseOffset or 0
		heightType.minCollisionOffset = xmlFile:getValue(key .. ".collision#minOffset") or heightType.minCollisionOffset or 0
		heightType.maxCollisionOffset = xmlFile:getValue(key .. ".collision#maxOffset") or heightType.maxCollisionOffset or 1
		heightType.canBeTipped = xmlFile:getValue(key .. "#canBeTipped", Utils.getNoNil(heightType.canBeTipped, true))
		if xmlFile:hasProperty(key .. ".visualHeightMapping") then
			heightType.visualHeightMapping = {}
			for _, mappingKey in xmlFile:iterator(key .. ".visualHeightMapping.mapping") do
				local mapping = {}
				mapping.realValue = xmlFile:getValue(mappingKey .. "#realValue")
				mapping.visualValue = xmlFile:getValue(mappingKey .. "#visualValue")
				if mapping.realValue ~= nil then
					if mapping.visualValue ~= nil then
						table.insert(heightType.visualHeightMapping, mapping)
					else
						Logging.xmlError(xmlFile, "'%s' has invalid visual height mapping!", mappingKey)
					end
				end
			end
			table.sort(heightType.visualHeightMapping, function(a, b)
				return a.realValue < b.realValue
			end)
		end
	end
end
function DensityMapHeightManager:getDensityMapHeightTypeByIndex(index)
	if index ~= nil then
		return self.heightTypes[index]
	else
		return nil
	end
end
function DensityMapHeightManager:getFillTypeNameByDensityHeightMapIndex(index)
	if index ~= nil and self.heightTypes[index] ~= nil then
		return self.heightTypes[index].fillTypeName
	end
	return nil
end
function DensityMapHeightManager:getFillTypeIndexByDensityHeightMapIndex(index)
	if index ~= nil and self.heightTypes[index] ~= nil then
		return self.heightTypes[index].fillTypeIndex
	end
	return nil
end
function DensityMapHeightManager:getDensityMapHeightTypeByFillTypeName(fillTypeName)
	if fillTypeName ~= nil then
		return self.fillTypeNameToHeightType[fillTypeName]
	else
		return nil
	end
end
function DensityMapHeightManager:getDensityMapHeightTypeByFillTypeIndex(fillTypeIndex)
	if fillTypeIndex ~= nil then
		return self.fillTypeIndexToHeightType[fillTypeIndex]
	else
		return nil
	end
end
function DensityMapHeightManager:getDensityMapHeightTypeIndexByFillTypeName(fillTypeName)
	if fillTypeName ~= nil and self.fillTypeNameToHeightType[fillTypeName] ~= nil then
		return self.fillTypeNameToHeightType[fillTypeName].index
	end
	return nil
end
function DensityMapHeightManager:getDensityMapHeightTypeIndexByFillTypeIndex(fillTypeIndex)
	if fillTypeIndex ~= nil and self.fillTypeIndexToHeightType[fillTypeIndex] ~= nil then
		return self.fillTypeIndexToHeightType[fillTypeIndex].index
	end
	return nil
end
function DensityMapHeightManager:getDensityMapHeightTypes()
	return self.heightTypes
end
function DensityMapHeightManager:getFillTypeToDensityMapHeightTypes()
	return self.fillTypeIndexToHeightType
end
function DensityMapHeightManager:setFixedFillTypesArea(area, fillTypes)
	self.fixedFillTypesAreas[area] = { fillTypes = fillTypes }
end
function DensityMapHeightManager:removeFixedFillTypesArea(area)
	self.fixedFillTypesAreas[area] = nil
end
function DensityMapHeightManager:getFixedFillTypesAreas()
	return self.fixedFillTypesAreas
end
function DensityMapHeightManager:setConvertingFillTypeAreas(area, fillTypes, fillTypeTarget)
	self.convertingFillTypesAreas[area] = { fillTypes = fillTypes, fillTypeTarget = fillTypeTarget }
end
function DensityMapHeightManager:removeConvertingFillTypeAreas(area)
	self.convertingFillTypesAreas[area] = nil
end
function DensityMapHeightManager:getConvertingFillTypesAreas()
	return self.convertingFillTypesAreas
end
function DensityMapHeightManager:checkTypeMappings()
	local typeMappings = self.tipTypeMappings
	if typeMappings ~= nil and next(typeMappings) ~= nil then
		local numUsedMappings = 0
		for _, entry in ipairs(self.heightTypes) do
			local name = g_fillTypeManager:getFillTypeNameByIndex(entry.fillTypeIndex)
			local oldTypeIndex = typeMappings[name]
			if oldTypeIndex == nil or oldTypeIndex ~= entry.index then
				return false
			end
			numUsedMappings = numUsedMappings + 1
		end
		local numMappings = 0
		for _, _ in pairs(typeMappings) do
			numMappings = numMappings + 1
		end
		if numMappings ~= numUsedMappings then
			return false
		end
	end
	return true
end
function DensityMapHeightManager:initialize(isServer, tipCollisionMap, placementCollisionMap)
	local id = g_currentMission.terrainDetailHeightId
	self.tipToGroundIsAllowed = true
	local densitySize = getDensityMapSize(id)
	local deform = TerrainDeformation.new(g_terrainNode)
	local placementMapSize = deform:getBlockedAreaMapSize()
	deform:cancel()
	deform:delete()
	self.worldToDensityMap = densitySize / g_currentMission.terrainSize
	self.densityToWorldMap = g_currentMission.terrainSize / densitySize
	self.worldToPlacementMap = placementMapSize / g_currentMission.terrainSize
	self.placementToWorldMap = g_currentMission.terrainSize / placementMapSize
	self.pendingCollisionRecalculateAreas = {}
	self.collisionRecalculateAreaSize = 16
	self.collisionRecalculateAreaWorldSize = self.collisionRecalculateAreaSize * self.densityToWorldMap
	self.numCollisionRecalculateAreasPerSide = math.floor((densitySize + self.collisionRecalculateAreaSize - 1) / self.collisionRecalculateAreaSize)
	local litersPerMeter = 250
	local maxHeight = getDensityMapMaxHeight(id)
	local unitLength = g_currentMission.terrainSize / densitySize
	self.volumePerPixel = maxHeight * unitLength * unitLength
	self.literPerPixel = litersPerMeter * maxHeight * self.volumePerPixel
	self.fillToGroundScale = self.worldToDensityMap ^ 2 / (litersPerMeter * maxHeight)
	local maxHeightDensityValue = 2 ^ getDensityMapHeightNumChannels(id) - 1
	self.minValidLiterValue = self.literPerPixel / maxHeightDensityValue
	self.minValidVolumeValue = self.volumePerPixel / maxHeightDensityValue
	self.heightToDensityValue = maxHeightDensityValue / maxHeight
	local heightFirstChannel = getDensityMapHeightFirstChannel(id)
	local heightNumChannels = getDensityMapHeightNumChannels(id)
	local typeFirstChannel = self.heightTypeFirstChannel
	local typeNumChannels = self.heightTypeNumChannels
	if heightFirstChannel < typeFirstChannel + typeNumChannels and typeFirstChannel < heightFirstChannel + heightNumChannels then
		Logging.warning("Density map height type channels [%d-%d] are overlapping with the density map height channels [%d-%d]. This will lead to unexpected results.", typeFirstChannel, typeFirstChannel + typeNumChannels - 1, heightFirstChannel, heightFirstChannel + heightNumChannels - 1)
	end
	local densityMapHeightCollisionMask = CollisionFlag.TERRAIN_DELTA
	local displacementHeightCollisionMask = CollisionFlag.TERRAIN_DISPLACEMENT
	self.terrainDetailHeightUpdater = createDensityMapHeightUpdater("TerrainDetailHeightUpdater", id, typeFirstChannel, typeNumChannels, densityMapHeightCollisionMask, displacementHeightCollisionMask)
	local numUsedMappings = 0
	local heightTypes = self:getDensityMapHeightTypes()
	if heightTypes ~= nil then
		for _, entry in ipairs(heightTypes) do
			local oldTypeIndex = entry.index
			if self.tipTypeMappings ~= nil and next(self.tipTypeMappings) ~= nil then
				local name = g_fillTypeManager:getFillTypeNameByIndex(entry.fillTypeIndex)
				local fillTypeName = string.lower(name)
				oldTypeIndex = self.tipTypeMappings[fillTypeName] or -1
				if 0 <= oldTypeIndex then
					numUsedMappings = numUsedMappings + 1
				end
			end
			setDensityMapHeightTypeProperties(self.terrainDetailHeightUpdater, entry.index, oldTypeIndex, entry.maxSurfaceAngle, entry.collisionScale, entry.collisionBaseOffset, entry.minCollisionOffset, entry.maxCollisionOffset)
		end
	end
	g_fillTypeManager:constructFillTypeDistanceTextureArray(g_currentMission.terrainDetailHeightId, typeFirstChannel, typeNumChannels, heightTypes)
	local forceTypeConversion = false
	if self.tipTypeMappings ~= nil then
		local numMappings = 0
		for _, _ in pairs(self.tipTypeMappings) do
			numMappings = numMappings + 1
		end
		if numMappings ~= numUsedMappings then
			forceTypeConversion = true
		end
	end
	initDensityMapHeightTypeProperties(self.terrainDetailHeightUpdater, forceTypeConversion)
	local missionInfo = g_currentMission.missionInfo
	if isServer then
		self.tipCollisionMap = tipCollisionMap
		self.tipCollisionMapCreated = false
		if tipCollisionMap == 0 then
			self.tipCollisionMap = createBitVectorMap("CollisionMap")
			self.tipCollisionMapCreated = true
		end
		local collisionMapValid = false
		if not GS_IS_MOBILE_VERSION and missionInfo:getIsTipCollisionValid(g_currentMission) then
			local savegameFilename = missionInfo.savegameDirectory .. "/" .. DensityMapHeightManager.GENERATED_TIP_COLLISION_FILENAME
			if loadBitVectorMapFromFile(self.tipCollisionMap, savegameFilename, 2) then
				if setDensityMapHeightCollisionMap(self.terrainDetailHeightUpdater, self.tipCollisionMap, false) then
					collisionMapValid = true
				else
					Logging.warning("Failed to load savegame tip collision map '" .. savegameFilename .. "'. Loading default tip collision map and recreating from placeables.")
				end
			end
		end
		if not collisionMapValid then
			local cleanupHeights = false
			if missionInfo.isValid then
				cleanupHeights = true
			end
			if self.tipCollisionMapCreated or not setDensityMapHeightCollisionMap(self.terrainDetailHeightUpdater, self.tipCollisionMap, cleanupHeights) then
				Logging.warning("No tip collision map defined. Creating empty tip placement collision map.")
				loadBitVectorMapNew(self.tipCollisionMap, densitySize, densitySize, 2, false)
				setDensityMapHeightCollisionMap(self.terrainDetailHeightUpdater, self.tipCollisionMap, cleanupHeights)
			end
		end
	end
	if not GS_IS_MOBILE_VERSION then
		self.placementCollisionMap = placementCollisionMap
		self.placementCollisionMapCreated = false
		if placementCollisionMap == 0 then
			self.placementCollisionMap = createBitVectorMap("PlacementCollisionMap")
			self.placementCollisionMapCreated = true
		end
		local placementCollisionMapValid = false
		if missionInfo:getIsPlacementCollisionValid(g_currentMission) then
			local savegameFilename = missionInfo.savegameDirectory .. "/" .. DensityMapHeightManager.GENERATED_PLACEMENT_COLLISION_FILENAME
			if loadBitVectorMapFromFile(self.placementCollisionMap, savegameFilename, 1) then
				local sizeX, _sizeZ = getBitVectorMapSize(self.placementCollisionMap)
				if sizeX ~= placementMapSize then
					Logging.warning("Savegame placement collision map %q size %d does not match expected size %d", savegameFilename, sizeX, placementMapSize)
				else
					placementCollisionMapValid = true
				end
			else
				Logging.warning("Failed to load savegame placement collision map '" .. savegameFilename .. "'. Loading default placement collision map and recreating from placeables.")
			end
		end
		if not placementCollisionMapValid and self.placementCollisionMapCreated then
			Logging.warning("No placement collision map defined. Creating empty placement collision map.")
			loadBitVectorMapNew(self.placementCollisionMap, placementMapSize, placementMapSize, 1, false)
		end
	end
	g_fillTypeManager:constructTerrainFillLayers(heightTypes, g_terrainNode)
	if self.tipCollisionMap ~= nil then
		local tipCollisionMapSize = getBitVectorMapSize(self.tipCollisionMap)
		local tipCollisionCellsize = g_currentMission.terrainSize / tipCollisionMapSize
		self.debugBitVectorMapTipCollisions = DebugBitVectorMap.newSimple(10, tipCollisionCellsize, true, 0.2, nil, true)
		self.debugBitVectorMapTipCollisions.valueToColor = { Color.PRESETS.BLUE:copy(), Color.PRESETS.RED:copy(), [0] = Color.PRESETS.GREEN:copy() }
		self.debugBitVectorMapTipCollisions:createWithCustomFunc(function(instance, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
			local centerX = (startWorldX + widthWorldX + heightWorldX) / 3
			local centerZ = (startWorldZ + widthWorldZ + heightWorldZ) / 3
			local terrainSize = g_currentMission.terrainSize
			local localX = math.floor(0.5 + tipCollisionMapSize * (centerX + terrainSize * 0.5) / terrainSize)
			local localZ = math.floor(0.5 + tipCollisionMapSize * (centerZ + terrainSize * 0.5) / terrainSize)
			local value = getBitVectorMapPoint(self.tipCollisionMap, localX, localZ, 0, 2)
			return value
		end)
	end
	if self.placementCollisionMap ~= nil then
		local placementCollisionMapSize = getBitVectorMapSize(self.placementCollisionMap)
		local placementCellsize = g_currentMission.terrainSize / placementCollisionMapSize
		self.debugBitVectorMapPlacementCollisions = DebugBitVectorMap.newSimple(10, placementCellsize, true, 0.2)
		self.debugBitVectorMapPlacementCollisions.valueToColor = { Color.PRESETS.RED:copy(), [0] = Color.PRESETS.GREEN:copy() }
		self.debugBitVectorMapPlacementCollisions:createWithCustomFunc(function(instance, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
			local centerX = (startWorldX + widthWorldX + heightWorldX) / 3
			local centerZ = (startWorldZ + widthWorldZ + heightWorldZ) / 3
			local terrainSize = g_currentMission.terrainSize
			local localX = math.floor(0.5 + placementCollisionMapSize * (centerX + terrainSize * 0.5) / terrainSize)
			local localZ = math.floor(0.5 + placementCollisionMapSize * (centerZ + terrainSize * 0.5) / terrainSize)
			local value = getBitVectorMapPoint(self.placementCollisionMap, localX, localZ, 0, 1)
			return value
		end)
	end
end
function DensityMapHeightManager:getIsValid()
	return self.terrainDetailHeightUpdater ~= nil
end
function DensityMapHeightManager:getTerrainDetailHeightUpdater()
	return self.terrainDetailHeightUpdater
end
function DensityMapHeightManager:getMinValidLiterValue(fillTypeIndex)
	local heightType = self:getDensityMapHeightTypeByFillTypeIndex(fillTypeIndex)
	if heightType == nil then
		return 0
	else
		return self.minValidLiterValue / heightType.fillToGroundScale
	end
end
function DensityMapHeightManager:getMinValidLiterValuePerSqm(fillTypeIndex)
	local heightType = self:getDensityMapHeightTypeByFillTypeIndex(fillTypeIndex)
	if heightType == nil then
		return 0
	else
		local literPerPixel = self.minValidLiterValue / heightType.fillToGroundScale
		return literPerPixel / (self.densityToWorldMap * self.densityToWorldMap)
	end
end
function DensityMapHeightManager:update(dt)
	if self.terrainDetailHeightUpdater == nil then
		return
	end
	local num = 0
	local terrainHalfSize = g_currentMission.terrainSize * 0.5
	for areaIndex, loopIndex in pairs(self.pendingCollisionRecalculateAreas) do
		if loopIndex <= g_updateLoopIndex then
			self.pendingCollisionRecalculateAreas[areaIndex] = nil
			local zi = math.floor(areaIndex / self.numCollisionRecalculateAreasPerSide)
			local xi = areaIndex - zi * self.numCollisionRecalculateAreasPerSide
			local minX = xi * self.collisionRecalculateAreaWorldSize - terrainHalfSize
			local minZ = zi * self.collisionRecalculateAreaWorldSize - terrainHalfSize
			self:updateCollisionMap(minX, minZ, minX + self.collisionRecalculateAreaWorldSize, minZ + self.collisionRecalculateAreaWorldSize, false)
			num = num + 1
			if not (6 < num) then
				continue
			end
			return
		end
	end
end
function DensityMapHeightManager:saveCollisionMap(directory)
	if self.tipCollisionMap ~= nil then
		saveBitVectorMapToFile(self.tipCollisionMap, directory .. "/" .. DensityMapHeightManager.GENERATED_TIP_COLLISION_FILENAME)
	end
end
function DensityMapHeightManager:prepareSaveCollisionMap(directory)
	if self.tipCollisionMap ~= nil then
		prepareSaveBitVectorMapToFile(self.tipCollisionMap, directory .. "/" .. DensityMapHeightManager.GENERATED_TIP_COLLISION_FILENAME)
	end
end
function DensityMapHeightManager:savePreparedCollisionMap(callback, callbackObject)
	if self.tipCollisionMap ~= nil then
		savePreparedBitVectorMapToFile(self.tipCollisionMap, callback, callbackObject)
	end
end
function DensityMapHeightManager:savePlacementCollisionMap(directory)
	if self.placementCollisionMap ~= nil then
		saveBitVectorMapToFile(self.placementCollisionMap, directory .. "/" .. DensityMapHeightManager.GENERATED_PLACEMENT_COLLISION_FILENAME)
	end
end
function DensityMapHeightManager:prepareSavePlacementCollisionMap(directory)
	if self.placementCollisionMap ~= nil then
		prepareSaveBitVectorMapToFile(self.placementCollisionMap, directory .. "/" .. DensityMapHeightManager.GENERATED_PLACEMENT_COLLISION_FILENAME)
	end
end
function DensityMapHeightManager:savePreparedPlacementCollisionMap(callback, callbackObject)
	if self.placementCollisionMap ~= nil then
		savePreparedBitVectorMapToFile(self.placementCollisionMap, callback, callbackObject)
	end
end
function DensityMapHeightManager:setCollisionMapAreaDirty(minX, minZ, maxX, maxZ, delayed)
	local terrainHalfSize = g_currentMission.terrainSize * 0.5
	local minXi = math.floor((minX + terrainHalfSize) / self.collisionRecalculateAreaWorldSize)
	local minZi = math.floor((minZ + terrainHalfSize) / self.collisionRecalculateAreaWorldSize)
	local maxXi = math.ceil((maxX + terrainHalfSize) / self.collisionRecalculateAreaWorldSize)
	local maxZi = math.ceil((maxZ + terrainHalfSize) / self.collisionRecalculateAreaWorldSize)
	for zi = minZi, maxZi do
		for xi = minXi, maxXi do
			local areaIndex = zi * self.numCollisionRecalculateAreasPerSide + xi
			local frameOffset = 0
			if delayed then
				frameOffset = 2
			end
			self.pendingCollisionRecalculateAreas[areaIndex] = g_updateLoopIndex + frameOffset
		end
	end
end
function DensityMapHeightManager:updateCollisionMap(minX, minZ, maxX, maxZ, synchronous)
	if self.tipCollisionMap ~= nil or self.placementCollisionMap ~= nil then
		local terrainHalfSize = g_currentMission.terrainSize * 0.5
		minX = math.clamp(minX, -terrainHalfSize, terrainHalfSize)
		minZ = math.clamp(minZ, -terrainHalfSize, terrainHalfSize)
		maxX = math.clamp(maxX, -terrainHalfSize, terrainHalfSize)
		maxZ = math.clamp(maxZ, -terrainHalfSize, terrainHalfSize)
		if synchronous == nil then
			synchronous = true
		end
		if self.tipCollisionMap ~= nil then
			updateTerrainCollisionMap(self.tipCollisionMap, g_terrainNode, "tipCollision", 0, self.tipCollisionMask, minX, minZ, maxX, maxZ, synchronous)
		end
		if self.placementCollisionMap ~= nil then
			updatePlacementCollisionMap(self.placementCollisionMap, g_terrainNode, "placementCollision", 0, self.placementCollisionMask, minX, minZ, maxX, maxZ, synchronous)
		end
	end
end
local getIsPlacementAreaBlocked_modifier = nil
local getIsPlacementAreaBlocked_filter = nil
function DensityMapHeightManager:getIsPlacementAreaBlocked(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	if self.placementCollisionMap == nil then
		return false
	else
		if getIsPlacementAreaBlocked_modifier == nil then
			getIsPlacementAreaBlocked_modifier = DensityMapModifier.new(self.placementCollisionMap, 0, 1, g_terrainNode)
			getIsPlacementAreaBlocked_filter = DensityMapFilter.new(self.placementCollisionMap, 0, 1)
		end
		heightWorldX = heightWorldX or startWorldX + 0.05
		heightWorldZ = heightWorldZ or startWorldZ
		getIsPlacementAreaBlocked_modifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
		getIsPlacementAreaBlocked_filter:setValueCompareParams(DensityValueCompareType.EQUAL, 1)
		local blockedPixels = getIsPlacementAreaBlocked_modifier:executeGet(getIsPlacementAreaBlocked_filter)
		return 0 < blockedPixels
	end
end
function DensityMapHeightManager:getIsInFreeAccessArea(sx, sz, ex, ez)
	for _, area in ipairs(self.freeAccessAreas) do
		if MathUtil.vector2Length(area.x - sx, area.z - sz) <= area.radius and MathUtil.vector2Length(area.x - ex, area.z - ez) <= area.radius then
			return true
		end
	end
	return false
end
function DensityMapHeightManager:consoleCommandTipAnywhereAdd(fillTypeName, amount, length, rows, spacing)
	local usage = "Usage: gsTipAnywhereAdd fillTypeName amount [length] [rows] [spacing]"
	if fillTypeName == nil then
		printError("Error: No filltype given")
		return usage
	end
	local fillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(fillTypeName)
	if fillTypeIndex == nil then
		local availableFillTypes = g_fillTypeManager:getFillTypeNamesByIndices(self.fillTypeIndexToHeightType)
		printError(string.format("Error: Invalid fillType '%s'", fillTypeName))
		return string.format("Available fillTypes: %s", table.concat(availableFillTypes, ", "))
	end
	if self.fillTypeIndexToHeightType[fillTypeIndex] == nil then
		local availableFillTypes = g_fillTypeManager:getFillTypeNamesByIndices(self.fillTypeIndexToHeightType)
		printError(string.format("Error: fillType '%s' not supported by tip anywhere", fillTypeName))
		return string.format("Available fillTypes: %s", table.concat(availableFillTypes, ", "))
	end
	amount = tonumber(amount)
	if amount == nil then
		printError("Error: no amount given")
		return usage
	else
		length = Utils.getNoNil(tonumber(length), 1)
		rows = Utils.getNoNil(tonumber(rows), 1)
		spacing = Utils.getNoNil(tonumber(spacing), 3)
		local mission = g_currentMission
		local player = g_localPlayer
		local controlledVehicle = player:getCurrentVehicle()
		local x = 0
		local y = 0
		local z = 0
		local dirX = 1
		local _ = 0
		local dirZ = 0
		if player ~= nil then
			if player:getIsControlled() then
				if player.rootNode ~= nil and player.rootNode ~= 0 then
					x, y, z = getWorldTranslation(player.rootNode)
					local playerYaw = player.mover:getMovementYaw() + 1.5707963267948966
					dirX = -math.cos(playerYaw)
					_ = 0
					dirZ = math.sin(playerYaw)
				end
			elseif controlledVehicle ~= nil then
				x, y, z = getWorldTranslation(controlledVehicle.rootNode)
				dirX, _, dirZ = localDirectionToWorld(controlledVehicle.rootNode, 0, 0, 1)
			end
		end
		local amountTipped = 0
		local initialOffset = (rows - 1) * spacing * -0.5
		for i = 0, rows - 1 do
			local offset = initialOffset + i * spacing
			local lx = x + offset * dirZ
			local ly = y
			local lz = z + offset * -dirX
			amountTipped = amountTipped + DensityMapHeightUtil.tipToGroundAroundLine(controlledVehicle, amount, fillTypeIndex, lx, ly, lz, lx + length * dirX, ly, lz + length * dirZ, 10, 40, nil, nil, nil, nil)
		end
		if mission.controlPlayer and player ~= nil then
			local height = DensityMapHeightUtil.getHeightAtWorldPos(x, y, z)
			player.mover:teleportTo(x, height, z)
		end
		return string.format("Tipped %dl of %s", amountTipped, fillTypeName)
	end
end
function DensityMapHeightManager:consoleCommandTipAnywhereAddAll()
	local player = g_localPlayer
	local controlledVehicle = player:getCurrentVehicle()
	local x = 0
	local y = 0
	local z = 0
	local dirX = 1
	local _ = 0
	local dirZ = 0
	if player ~= nil then
		if player:getIsControlled() then
			if player.rootNode ~= nil and player.rootNode ~= 0 then
				x, y, z = getWorldTranslation(player.rootNode)
				local playerYaw = player.mover:getMovementYaw() + 1.5707963267948966
				dirX = -math.cos(playerYaw)
				_ = 0
				dirZ = math.sin(playerYaw)
			end
		elseif controlledVehicle ~= nil then
			x, y, z = getWorldTranslation(controlledVehicle.rootNode)
			dirX, _, dirZ = localDirectionToWorld(controlledVehicle.rootNode, 0, 0, 1)
		end
	end
	local amounts = { 0, 100, 1000, 5000, 10000, 999999 }
	local sideOffsets = { -4, -1.5, 2, 8, 16, 26 }
	local heapSpacing = 10
	x = x + dirX * 10
	z = z + dirZ * 10
	for heightTypeIndex = 1, #self.heightTypes do
		local heightType = self.heightTypes[heightTypeIndex]
		for amountIndex, amount in ipairs(amounts) do
			local sideOffset = sideOffsets[amountIndex]
			local x1 = x + dirX * heightTypeIndex * 10
			local z1 = z + dirZ * heightTypeIndex * 10
			x1 = x1 + dirZ * sideOffset
			z1 = z1 - dirX * sideOffset
			local x2 = x1 + dirX * 1
			local z2 = z1 + dirZ * 1
			local amount = math.max(g_densityMapHeightManager:getMinValidLiterValue(heightType.fillTypeIndex), amount)
			DensityMapHeightUtil.tipToGroundAroundLine(controlledVehicle, amount, heightType.fillTypeIndex, x1, y, z1, x2, y, z2, 10, 40, nil, nil, nil, nil)
			local debugString = string.format("%s (%.2f)", g_fillTypeManager:getFillTypeNameByIndex(heightType.fillTypeIndex), amount)
			local yRot = MathUtil.getYRotationFromDirection(-dirX, -dirZ)
			local debugText = DebugText3D.new():createWithWorldPos(x1 - dirX * 2, y + 2, z1 - dirZ * 2, 0, yRot, 0, debugString, 0.2)
			g_debugManager:addElement(debugText, nil, nil, math.huge)
		end
	end
end
function DensityMapHeightManager:consoleCommandTipAnywhereClear(sizeStr)
	local usage = "Usage: gsTipAnywhereClear sizeToClearMeters"
	if sizeStr == nil then
		printError("Error: Missing sizeToClearMeters parameter")
		return usage
	end
	local size = tonumber(sizeStr)
	if size == nil then
		printError(string.format("Error: invalid size %q, provide a number", sizeStr))
		return usage
	else
		local mission = g_currentMission
		local player = g_localPlayer
		local controlledVehicle = player:getCurrentVehicle()
		local terrainSizeHalf = mission.terrainSize * 0.5
		local x0 = -terrainSizeHalf
		local z0 = terrainSizeHalf
		local x1 = terrainSizeHalf
		local z1 = terrainSizeHalf
		local x2 = -terrainSizeHalf
		local z2 = -terrainSizeHalf
		local node = nil
		if player ~= nil then
			if player:getIsControlled() then
				if player ~= nil and (player.rootNode ~= nil and player.rootNode ~= 0) then
					node = player.rootNode
				end
			elseif controlledVehicle ~= nil then
				node = controlledVehicle.rootNode
			end
		end
		if node ~= nil then
			local sizeHalf = size * 0.5
			local _ = nil
			x0, _, z0 = localToWorld(node, -sizeHalf, 0, sizeHalf)
			x1, _, z1 = localToWorld(node, sizeHalf, 0, sizeHalf)
			x2, _, z2 = localToWorld(node, -sizeHalf, 0, -sizeHalf)
		end
		DensityMapHeightUtil.clearArea(x0, z0, x1, z1, x2, z2)
		return "Cleared area (" .. size .. "m)"
	end
end
function DensityMapHeightManager:consoleCommandToggleDebug()
	DensityMapHeightManager.DEBUG_ENABLED = not DensityMapHeightManager.DEBUG_ENABLED
	g_debugManager:setGroupVisibility(DensityMapHeightManager.DEBUG_GROUP_ID, DensityMapHeightManager.DEBUG_ENABLED)
	return string.format("DensityMapHeightManager.DEBUG_ENABLED = %s", tostring(DensityMapHeightManager.DEBUG_ENABLED))
end
function DensityMapHeightManager:consoleCommandShowTipCollisions(active)
	if not StartParams.getIsSet("scriptDebug") then
		printError("Error: Game must be started with '-scriptDebug' parameter")
		return
	else
		DensityMapHeightManager.DEBUG_TIP_COLLISIONS = Utils.getNoNil(active, not DensityMapHeightManager.DEBUG_TIP_COLLISIONS)
		if DensityMapHeightManager.DEBUG_TIP_COLLISIONS then
			self.debugBitVectorMapTipCollisionsId = g_debugManager:addElement(self.debugBitVectorMapTipCollisions)
		elseif self.debugBitVectorMapTipCollisionsId ~= nil then
			g_debugManager:removeElementById(self.debugBitVectorMapTipCollisionsId)
			self.debugBitVectorMapTipCollisionsId = nil
		end
		return string.format("DensityMapHeightManager.DEBUG_TIP_COLLISIONS = %s\nEnable debug view (F5) to render collision information", tostring(DensityMapHeightManager.DEBUG_TIP_COLLISIONS))
	end
end
function DensityMapHeightManager:consoleCommandShowPlacementCollisions(active)
	if not StartParams.getIsSet("scriptDebug") then
		printError("Error: Game must be started with '-scriptDebug' parameter")
		return
	else
		DensityMapHeightManager.DEBUG_PLACEMENT_COLLISIONS = Utils.getNoNil(active, not DensityMapHeightManager.DEBUG_PLACEMENT_COLLISIONS)
		if DensityMapHeightManager.DEBUG_PLACEMENT_COLLISIONS then
			self.debugBitVectorMapPlacementCollisionsId = g_debugManager:addElement(self.debugBitVectorMapPlacementCollisions)
		elseif self.debugBitVectorMapPlacementCollisionsId ~= nil then
			g_debugManager:removeElementById(self.debugBitVectorMapPlacementCollisionsId)
			self.debugBitVectorMapPlacementCollisionsId = nil
		end
		return string.format("DensityMapHeightManager.DEBUG_PLACEMENT_COLLISIONS = %s\nEnable debug view (F5) to render collision information", tostring(DensityMapHeightManager.DEBUG_PLACEMENT_COLLISIONS))
	end
end
function DensityMapHeightManager:consoleCommandUpdateTipCollisions(width)
	local x, _, z = getWorldTranslation(g_cameraManager:getActiveCamera())
	width = math.clamp(tonumber(width) or 20, 2, 1000)
	local halfWidth = width / 2
	self:updateCollisionMap(x - halfWidth, z - halfWidth, x + halfWidth, z + halfWidth)
	return string.format("Updated tipCollision in a %ix%i area around the camera. Add a number as a parameter to update a custom area", width, width)
end
g_densityMapHeightManager = DensityMapHeightManager.new()
