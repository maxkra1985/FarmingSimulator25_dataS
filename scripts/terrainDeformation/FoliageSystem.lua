-- Local values: FoliageSystem_mt, _sub, _len, _oldaddFoliageTypeFromXML, _addFoliageTypeFromXML
FoliageSystem = {}
local FoliageSystem_mt = Class(FoliageSystem)
g_xmlManager:addInitSchemaFunction(function()
	local v2_ = FruitTypeDesc.xmlSchema
	DensityMapHeightManager.registerXMLPaths(v2_, "foliageType")
	FruitTypeManager.registerXMLPaths(v2_, "foliageType")
	FillTypeManager.registerXMLPaths(v2_, "foliageType")
	MotionPathEffectManager.registerMotionPathXMLFiles(v2_, "foliageType")
	local v3_ = FillTypeManager.xmlSchema
	FillTypeManager.registerXMLPaths(v3_, "foliageType")
end)

-- Upvalues: FoliageSystem_mt
-- Local values: self
function FoliageSystem.new(customMt)
	-- upvalues: (copy) FoliageSystem_mt
	local v5_ = customMt or FoliageSystem_mt
	local v6_ = setmetatable({}, v5_)
	v6_.terrainRootNode = 0
	v6_.paintableFoliages = {}
	v6_.decoFoliages = {}
	v6_.decoFoliageMappings = {}
	v6_.modFoliageTypesToLoad = {}
	return v6_
end

function FoliageSystem:delete()
	self.paintableFoliages = {}
	self.decoFoliages = {}
	self.modFoliageTypesToLoad = {}
end

-- Local values: xmlFile, decoFoliageLayerNames, newFoliageTypes, i, newFoliageType, i, foliageType
function FoliageSystem:loadMapData(mapXmlFile, missionInfo, baseDirectory)
	local v_u_11_ = XMLFile.wrap(mapXmlFile)
	v_u_11_:iterate("map.paintableFoliages.paintableFoliage", function(_, p12_)
		-- upvalues: (copy) v_u_11_, (copy) self
		local v13_ = v_u_11_:getString(p12_ .. "#layerName")
		if v13_ == nil then
			Logging.xmlWarning(v_u_11_, "Missing layerName for paintableFoliage \'%s\'", p12_)
		else
			local v14_ = {
				["layerName"] = v13_,
				["startStateChannel"] = v_u_11_:getInt(p12_ .. "#startChannel", 0),
				["numStateChannels"] = v_u_11_:getInt(p12_ .. "#numChannels", 4),
				["state"] = v_u_11_:getInt(p12_ .. "#state", 0),
				["id"] = #self.paintableFoliages + 1
			}
			local v15_ = self.paintableFoliages
			table.insert(v15_, v14_)
		end
	end)
	local v_u_16_ = {}
	v_u_11_:iterate("map.decoFoliages.decoFoliage", function(_, p17_)
		-- upvalues: (copy) v_u_11_, (copy) v_u_16_, (copy) self
		local v18_ = {
			["layerName"] = v_u_11_:getString(p17_ .. "#layerName")
		}
		if v18_.layerName == nil then
			Logging.xmlWarning(v_u_11_, "Missing layerName for decoFoliage \'%s\'", p17_)
		else
			v18_.startStateChannel = v_u_11_:getInt(p17_ .. "#startChannel", 0)
			v18_.numStateChannels = v_u_11_:getInt(p17_ .. "#numChannels", 4)
			v18_.mowable = v_u_11_:getBool(p17_ .. "#mowable")
			v_u_16_[string.upper(v18_.layerName)] = v18_
			local v19_ = self.decoFoliages
			table.insert(v19_, v18_)
		end
	end)
	self.decoFoliageMappings = {}
	v_u_11_:iterate("map.decoFoliages.mapping", function(_, p20_)
		-- upvalues: (copy) v_u_11_, (copy) self, (copy) v_u_16_
		local v21_ = v_u_11_:getString(p20_ .. "#name")
		if v21_ == nil then
			Logging.xmlWarning(v_u_11_, "Missing name for decoFoliage mapping \'%s\'", p20_)
			return
		else
			local v22_ = string.upper(v21_)
			if self.decoFoliageMappings[v22_] == nil then
				local v23_ = v_u_11_:getString(p20_ .. "#layerName")
				if v23_ == nil then
					Logging.xmlWarning(v_u_11_, "Missing layerName for decoFoliage mapping \'%s\'", p20_)
					return
				else
					local v24_ = v_u_16_[string.upper(v23_)]
					if v24_ == nil then
						Logging.xmlWarning(v_u_11_, "Mapping layerName \'%s\' not defined deco foliages for \'%s\'", v23_, p20_)
					else
						local v25_ = {
							["decoFoliage"] = v24_,
							["state"] = v_u_11_:getInt(p20_ .. "#state")
						}
						self.decoFoliageMappings[v22_] = v25_
					end
				end
			else
				Logging.xmlWarning(v_u_11_, "Name \'%s\' already defined for decoFoliage mapping \'%s\'", v21_, p20_)
				return
			end
		end
	end)
	v_u_11_:delete()
	self.modFoliageTypesToLoad = missionInfo.foliageTypes or self.modFoliageTypesToLoad
	local v26_ = g_fruitTypeManager.modFoliageTypesToLoad
	for v27_ = 1, #v26_ do
		local v28_ = v26_[v27_]
		self:addModFoliageType(v28_.name, v28_.filename)
	end
	for v29_ = 1, #self.modFoliageTypesToLoad do
		local v30_ = self.modFoliageTypesToLoad[v29_]
		self:loadModFoliageType(v30_.name, v30_.filename)
	end
	if #self.modFoliageTypesToLoad > 0 then
		g_fruitTypeManager:initializeFruitTypeConverters()
	end
	return true
end

function FoliageSystem:unloadMapData()
	self.paintableFoliages = {}
end

-- Local values: _, foliageType
function FoliageSystem:streamWriteModFoliageTypes(streamId, connection)
	streamWriteUInt8(streamId, #self.modFoliageTypesToLoad)
	for _, v34_ in ipairs(self.modFoliageTypesToLoad) do
		streamWriteString(streamId, v34_.name)
		streamWriteString(streamId, NetworkUtil.convertToNetworkFilename(v34_.filename))
	end
end

-- Local values: numLoadedFoliageTypes, numTypes, i, name, filename
function FoliageSystem:streamReadModFoliageTypes(streamId, connection)
	local v37_ = 0
	for _ = 1, streamReadUInt8(streamId) do
		local v38_ = streamReadString(streamId)
		local v39_ = NetworkUtil.convertFromNetworkFilename(streamReadString(streamId))
		if self:addModFoliageType(v38_, v39_) and self:loadModFoliageType(v38_, v39_) then
			v37_ = v37_ + v37_
		end
	end
	if v37_ > 0 then
		g_fruitTypeManager:initializeFruitTypeConverters()
	end
end

-- Local values: i, foliageType, key
function FoliageSystem:saveToXMLFile(xmlFile)
	for v42_ = 1, #self.modFoliageTypesToLoad do
		local v43_ = self.modFoliageTypesToLoad[v42_]
		local v44_ = string.format("careerSavegame.foliageTypes.foliageType(%d)", v42_ - 1)
		setXMLString(xmlFile, v44_ .. "#name", v43_.name)
		setXMLString(xmlFile, v44_ .. "#filename", NetworkUtil.convertToNetworkFilename(v43_.filename))
	end
end

-- Local values: key, paintableFoliage, id, _, key, decoFoliage, id, _
function FoliageSystem:initTerrain(mission, terrainRootNode, terrainDetailId)
	self.terrainRootNode = terrainRootNode
	for _, v47_ in pairs(self.paintableFoliages) do
		local v48_, _ = getTerrainDataPlaneByName(self.terrainRootNode, v47_.layerName)
		if v48_ == nil or v48_ == 0 then
			v47_.disabled = true
		else
			v47_.terrainDataPlaneId = v48_
			v47_.paintModifier = DensityMapModifier.new(v48_, v47_.startStateChannel, v47_.numStateChannels, terrainRootNode)
			v47_.paintFilter = DensityMapFilter.new(v47_.paintModifier)
		end
	end
	for _, v49_ in pairs(self.decoFoliages) do
		local v50_, _ = getTerrainDataPlaneByName(self.terrainRootNode, v49_.layerName)
		if v50_ ~= nil and v50_ ~= 0 then
			v49_.terrainDataPlaneId = v50_
			v49_.modifier = DensityMapModifier.new(v50_, v49_.startStateChannel, v49_.numStateChannels, terrainRootNode)
		end
	end
	self:loadModFoliageTypes()
end

-- Local values: key, decoFoliage
function FoliageSystem:addDensityMapSyncer(densityMapSyncer)
	for _, v53_ in pairs(self.decoFoliages) do
		if v53_.terrainDataPlaneId ~= nil then
			densityMapSyncer:addDensityMap(v53_.terrainDataPlaneId)
		end
	end
end

-- Local values: _, paintableFoliage, _, area, x, z, x1, z1, x2, z2
function FoliageSystem:applyAreas(modifiedAreas, paintTerrainFoliageId)
	for _, v57_ in pairs(self.paintableFoliages) do
		if v57_.id == paintTerrainFoliageId and not v57_.disabled then
			for _, v58_ in pairs(modifiedAreas) do
				local v59_, v60_, v61_, v62_, v63_, v64_ = unpack(v58_)
				self:apply(v57_, v59_, v60_, v61_ - v59_, v62_ - v60_, v63_ - v59_, v64_ - v60_)
			end
			return true
		end
	end
	return false
end

-- Local values: _, paintableFoliage
function FoliageSystem:getFoliagePaint(id)
	for _, v67_ in pairs(self.paintableFoliages) do
		if v67_.id == id and not v67_.disabled then
			return v67_
		end
	end
	return nil
end

-- Local values: _, paintableFoliage
function FoliageSystem:getFoliagePaintByName(name)
	for _, v70_ in pairs(self.paintableFoliages) do
		if v70_.layerName == name and not v70_.disabled then
			return v70_
		end
	end
	return nil
end

-- Local values: modifier, filter, _, numPixels, _
function FoliageSystem:apply(foliage, x, z, x1, z1, x2, z2, value)
	local v79_ = foliage.paintModifier
	local v80_ = foliage.paintFilter
	if value == nil then
		value = foliage.value
	end
	v79_:setParallelogramWorldCoords(x, z, x1, z1, x2, z2, DensityCoordType.POINT_POINT_POINT)
	v80_:setValueCompareParams(DensityValueCompareType.NOTEQUAL, value)
	local _, v81_, _ = v79_:executeSetWithStats(value, v80_)
	return v81_ / 4
end

function FoliageSystem:getDecoFoliages()
	return self.decoFoliages
end

-- Local values: nameUpper, data
function FoliageSystem:getIsDecoLayerDefined(decoName)
	local v85_ = string.upper(decoName)
	return self.decoFoliageMappings[v85_] ~= nil
end

-- Local values: data, decoFoliage
function FoliageSystem:getDensityMapData(decoFoliageName)
	local v88_ = self.decoFoliageMappings[string.upper(decoFoliageName)]
	if v88_ == nil then
		return nil
	end
	local v89_ = v88_.decoFoliage
	return v89_.terrainDataPlaneId, v89_.startStateChannel, v89_.numStateChannels, v88_.state
end

-- Local values: nameUpper, data, decoFoliage, state, modifier
function FoliageSystem:applyDecoFoliage(decoName, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	local v98_ = string.upper(decoName)
	local v99_ = self.decoFoliageMappings[v98_]
	if v99_ ~= nil then
		local v100_ = v99_.decoFoliage
		local v101_ = v99_.state
		local v102_ = v100_.modifier
		if v102_ ~= nil then
			v102_:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
			v102_:executeSet(v101_)
		end
	end
end

-- Local values: foliageXMLFile, foliageXMLFileHandle
function FoliageSystem:loadModFoliageType(name, filename, missionInfo, baseDirectory)
	if g_fruitTypeManager.filenameToFruitType[filename] ~= nil then
		Logging.devInfo("FoliageSystem - FoliageType \'%s\' already loaded from \'%s\'", name, filename)
		return false
	end
	local v107_ = XMLFile.load("fillTypeXMLFile", filename, FruitTypeDesc.xmlSchema)
	if v107_ == nil then
		return false
	end
	local v108_ = v107_:getHandle()
	g_fillTypeManager:loadFillTypes(v107_, "", false, nil, true)
	g_fruitTypeManager:loadFruitTypeFromXML(filename)
	g_fruitTypeManager:loadMapCategoriesAndConverters(v108_, missionInfo, baseDirectory)
	g_densityMapHeightManager:loadDensityMapHeightTypes(v107_, missionInfo, nil, false)
	g_motionPathEffectManager:loadMotionPathEffects(v108_, "foliageType.motionPathEffects.motionPathEffect", baseDirectory, nil)
	v107_:delete()
	Logging.devInfo("FoliageSystem - Loaded mod foliageType \'%s\'", name)
	return true
end

-- Local values: j, foliageType
function FoliageSystem:addModFoliageType(name, configFilename)
	for v112_ = 1, #self.modFoliageTypesToLoad do
		if name == self.modFoliageTypesToLoad[v112_].name then
			Logging.devWarning("FoliageSystem - Mod foliageType \'%s\' is already added. Skipping...", name)
			return false
		end
	end
	Logging.devWarning("FoliageSystem - Added Mod foliageType \'%s\'", name)
	local v113_ = self.modFoliageTypesToLoad
	table.insert(v113_, {
		["name"] = name,
		["filename"] = configFilename
	})
	return true
end
local v_u_114_ = string.sub
local _ = string.len
local v_u_115_ = addFoliageTypeFromXML

-- Upvalues: _sub, _oldaddFoliageTypeFromXML
-- Local values: terrainNode, i, foliageType, id, _, _, fruitType, terrainId, dmId, name, xmlFilename, path
function FoliageSystem:loadModFoliageTypes()
	-- upvalues: (copy) v_u_114_, (copy) v_u_115_
	local v117_ = g_terrainNode
	for v118_ = 1, #self.modFoliageTypesToLoad do
		local v119_ = self.modFoliageTypesToLoad[v118_]
		local v120_ = nil
		for _, v121_ in ipairs(g_fruitTypeManager:getFruitTypes()) do
			local v122_
			v120_, v122_ = getTerrainDataPlaneByName(self.terrainRootNode, v121_.layerName)
			if v120_ ~= nil then
				break
			end
		end
		if v120_ == nil then
			Logging.warning("Failed to load foliage xml \'%s\'", v119_.filename)
		else
			local v123_ = v119_.name
			local v124_ = v119_.filename
			if v_u_114_(v124_, 1, 12) == "data/foliage" then
				v_u_115_(v117_, v120_, v123_, v124_)
			else
				Logging.error("Failed to load foliage xml \'%s\'", v124_)
			end
		end
	end
end
