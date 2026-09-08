-- Local values: GroundTypeManager_mt
GroundTypeManager = {}
local GroundTypeManager_mt = Class(GroundTypeManager, AbstractManager)

-- Upvalues: GroundTypeManager_mt
-- Local values: self
function GroundTypeManager.new(customMt)
	-- upvalues: (copy) GroundTypeManager_mt
	return AbstractManager.new(customMt or GroundTypeManager_mt)
end

function GroundTypeManager:initDataStructures()
	self.groundTypes = {}
	self.groundTypeMappings = {}
	self.terrainLayerMapping = {}
end

-- Local values: xmlFile, i, key, name, groundType, fallbackLayerNames
function GroundTypeManager:loadGroundTypes()
	self.groundTypes = {}
	local v5_ = loadXMLFile("fuitTypes", "data/maps/groundTypes.xml")
	local v6_ = 0
	while true do
		local v7_ = string.format("groundTypes.groundType(%d)", v6_)
		if not hasXMLProperty(v5_, v7_) then
			break
		end
		local v8_ = getXMLString(v5_, v7_ .. "#name")
		if v8_ == nil then
			Logging.xmlWarning(v5_, "Missing groundType name for \'%s\'", v7_)
		else
			local v9_ = {}
			local v10_ = getXMLString(v5_, v7_ .. "#fallbacks")
			if not string.isNilOrWhitespace(v10_) then
				v9_.fallbacks = string.split(v10_, " ")
			end
			self.groundTypes[v8_] = v9_
		end
		v6_ = v6_ + 1
	end
	delete(v5_)
end

function GroundTypeManager:loadMapData(xmlFile, missionInfo, baseDirectory)
	GroundTypeManager:superClass().loadMapData(self)
	self:loadGroundTypes()
	return XMLUtil.loadDataFromMapXML(xmlFile, "groundTypeMappings", baseDirectory, self, self.loadGroundTypeMappings, missionInfo)
end

-- Local values: i, key, typeName, layerName, title, groundType
function GroundTypeManager:loadGroundTypeMappings(xmlFile, missionInfo)
	local v17_ = 0
	while true do
		local v18_ = string.format("map.groundTypeMappings.groundTypeMapping(%d)", v17_)
		if not hasXMLProperty(xmlFile, v18_) then
			break
		end
		local v19_ = getXMLString(xmlFile, v18_ .. "#type")
		if v19_ == nil then
			Logging.xmlWarning(xmlFile, "Missing groudTypeMapping type for \'%s\'", v18_)
		else
			local v20_ = getXMLString(xmlFile, v18_ .. "#layer")
			if v20_ == nil then
				Logging.xmlWarning(xmlFile, "Missing groudTypeMapping layerName for \'%s\'", v18_)
			else
				local v21_ = getXMLString(xmlFile, v18_ .. "#title")
				if v21_ == nil then
					Logging.xmlWarning(xmlFile, "Missing groudTypeMapping title for \'%s\'", v18_)
				else
					local v22_ = {
						["typeName"] = v19_,
						["layerName"] = v20_,
						["title"] = v21_
					}
					self.groundTypeMappings[v22_.typeName] = v22_
				end
			end
		end
		v17_ = v17_ + 1
	end
	return true
end

-- Local values: numLayers, i, layerName
function GroundTypeManager:initTerrain(terrainRootNode)
	self.terrainLayerMapping = {}
	for v25_ = 0, getTerrainNumOfLayers(terrainRootNode) - 1 do
		local v26_ = getTerrainLayerName(terrainRootNode, v25_)
		self.terrainLayerMapping[v26_] = v25_
	end
end

function GroundTypeManager:getTerrainTitleByType(typeName)
	return self.groundTypeMappings[typeName].title
end

-- Local values: layerName, layer, groundType, _, fallbackTypeName, callbackLayer, fallbackLayerName, layer
function GroundTypeManager:getTerrainLayerByType(typeName)
	local v31_
	if typeName == nil or self.groundTypeMappings[typeName] == nil then
		v31_ = nil
	else
		v31_ = self.groundTypeMappings[typeName].layerName
	end
	if v31_ ~= nil then
		local v32_ = self.terrainLayerMapping[v31_]
		if v32_ ~= nil then
			return v32_
		end
	end
	local v33_ = self.groundTypes[typeName]
	if v33_ ~= nil and v33_.fallbacks ~= nil then
		for _, v34_ in pairs(v33_.fallbacks) do
			if self.groundTypeMappings[v34_] == nil then
				Logging.warning("Unknown fallback layer \'%s\' for ground type \'%s\'", v34_, typeName)
			else
				local v35_ = self.groundTypeMappings[v34_].layerName
				if v35_ ~= nil then
					local v36_ = self.terrainLayerMapping[v35_]
					if v36_ ~= nil then
						return v36_
					end
				end
			end
		end
	end
	return 0
end
g_groundTypeManager = GroundTypeManager.new()
