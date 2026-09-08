-- Local values: MapManager_mt
MapManager = {}
local MapManager_mt = Class(MapManager, AbstractManager)

-- Upvalues: MapManager_mt
-- Local values: self
function MapManager.new(customMt)
	-- upvalues: (copy) MapManager_mt
	return AbstractManager.new(customMt or MapManager_mt)
end

function MapManager:initDataStructures()
	self.maps = {}
	self.idToMap = {}
end

-- Local values: item
function MapManager:addMapItem(id, scriptFilename, className, configFile, defaultVehiclesXMLFilename, defaultHandToolsXMLFilename, defaultPlaceablesXMLFilename, defaultItemsXMLFilename, title, description, iconFilename, baseDirectory, customEnvironment, isMultiplayerSupported, isModMap, prohibitOtherMods, isSelectable)
	if self.idToMap[id] ~= nil then
		Logging.warning("Duplicate map id \'%s\'. Ignoring this map definition.", id)
		return false
	end
	local v22_ = {
		["id"] = tostring(id),
		["scriptFilename"] = scriptFilename,
		["mapXMLFilename"] = configFile,
		["className"] = className,
		["defaultVehiclesXMLFilename"] = defaultVehiclesXMLFilename,
		["defaultHandToolsXMLFilename"] = defaultHandToolsXMLFilename,
		["defaultPlaceablesXMLFilename"] = defaultPlaceablesXMLFilename,
		["defaultItemsXMLFilename"] = defaultItemsXMLFilename,
		["title"] = title,
		["description"] = description,
		["iconFilename"] = iconFilename,
		["baseDirectory"] = baseDirectory,
		["customEnvironment"] = customEnvironment,
		["isMultiplayerSupported"] = isMultiplayerSupported,
		["isModMap"] = isModMap,
		["prohibitOtherMods"] = prohibitOtherMods,
		["isSelectable"] = isSelectable
	}
	local v23_ = self.maps
	table.insert(v23_, v22_)
	self.idToMap[id] = v22_
	return true
end

-- Local values: mapId, name, defaultVehiclesXMLFilename, defaultHandToolsXMLFilename, defaultPlaceablesXMLFilename, defaultItemsXMLFilename, mapTitle, mapDesc, mapClassName, mapFilename, configFilename, mapIconFilename, mapName, useModDirectory, baseDirectory, prohibitOtherMods, isSelectable, fullConfigFilename, customEnvironment, _
function MapManager:loadMapFromXML(xmlFile, baseName, modDir, modName, isMultiplayerSupported, isDLCFile, isModMap, isInternalMod)
	local v33_ = xmlFile:getString(baseName .. "#id", "")
	if v33_ == "" then
		Logging.error("Failed to load map \'%s\'. Missing attribute \'%s#id\'.", modName or "Basemap", baseName)
		return false
	end
	local v34_
	if modName == nil then
		v34_ = nil
	else
		v34_ = modName
	end
	local v35_ = xmlFile:getString(baseName .. "#defaultVehiclesXMLFilename", "")
	local v36_ = xmlFile:getString(baseName .. "#defaultHandToolsXMLFilename", "")
	local v37_ = xmlFile:getString(baseName .. "#defaultPlaceablesXMLFilename", "")
	local v38_ = xmlFile:getString(baseName .. "#defaultItemsXMLFilename", "")
	local v39_ = xmlFile:getI18NValue(baseName .. ".title", "", v34_, true)
	local v40_ = xmlFile:getI18NValue(baseName .. ".description", "", v34_, true)
	local v41_ = xmlFile:getString(baseName .. "#className", "Mission00")
	local v42_ = xmlFile:getString(baseName .. "#filename", "$dataS/scripts/mission00.lua")
	local v43_ = xmlFile:getString(baseName .. "#configFilename", "")
	local v44_ = xmlFile:getI18NValue(baseName .. ".iconFilename", "", v34_, true)
	local v45_
	if modName == nil then
		v45_ = v33_
	else
		v45_ = v33_ .. " " .. v33_
	end
	if v41_:find("[^%w_]") ~= nil then
		Logging.error("Failed to load map \'%s\'. Invalid map class name: \'%s\'. No whitespaces allowed.", v45_, v41_)
		return false
	end
	if v41_ == "" then
		Logging.error("Failed to load map \'%s\'. Missing attribute \'%s#className\'.", v45_, baseName)
		return false
	end
	if v39_ == "" then
		Logging.error("Failed to load map \'%s\'. Missing element \'%s.title\'.", v45_, baseName)
		return false
	end
	if v42_ == "" then
		Logging.error("Failed to load map \'%s\'. Missing attribute \'%s#filename\'.", v45_, baseName)
		return false
	end
	if v35_ == "" then
		Logging.error("Failed to load map \'%s\'. Missing attribute \'%s#defaultVehiclesXMLFilename\'.", v45_, baseName)
		return false
	end
	if v36_ == "" then
		Logging.error("Failed to load map \'%s\'. Missing attribute \'%s#defaultHandToolsXMLFilename\'.", v45_, baseName)
		return false
	end
	if v37_ == "" then
		Logging.error("Failed to load map \'%s\'. Missing attribute \'%s#defaultPlaceablesXMLFilename\'.", v45_, baseName)
		return false
	end
	if v38_ == "" then
		Logging.error("Failed to load map \'%s\'. Missing attribute \'%s#defaultItemsXMLFilename\'.", v45_, baseName)
		return false
	end
	if v44_ == "" then
		Logging.error("Failed to load map \'%s\'. Missing element \'%s.iconFilename\'.", v45_, baseName)
		return false
	end
	local v46_, v47_ = Utils.getFilename(v42_, modDir)
	if v47_ then
		v41_ = modName .. "." .. v41_
	end
	local v48_
	if isDLCFile or isInternalMod then
		v48_ = xmlFile:getBool(baseName .. ".prohibitOtherMods", nil) or nil
	else
		v48_ = nil
	end
	local v49_ = true
	if isDLCFile or isInternalMod then
		v49_ = xmlFile:getBool(baseName .. ".isSelectable", v49_)
	end
	local v50_ = Utils.getFilename(v43_, modDir)
	local v51_, _ = Utils.getModNameAndBaseDirectory(v50_)
	if modName ~= nil then
		v33_ = modName .. "." .. v33_
	end
	local v52_ = Utils.getFilename(v44_, modDir)
	local v53_ = Utils.getFilename(v35_, modDir)
	local v54_ = Utils.getFilename(v36_, modDir)
	local v55_ = Utils.getFilename(v37_, modDir)
	local v56_ = Utils.getFilename(v38_, modDir)
	if not GS_IS_CONSOLE_VERSION or (isDLCFile or (not v47_ or isInternalMod)) then
		return self:addMapItem(v33_, v46_, v41_, v43_, v53_, v54_, v55_, v56_, v39_, v40_, v52_, modDir, v51_, isMultiplayerSupported, isModMap, v48_, v49_)
	end
	Logging.error("Can\'t register map \'%s\' with scripts on consoles.", v33_)
	return false
end

-- Local values: parts
function MapManager:getModNameFromMapId(mapId)
	local v58_ = string.split(mapId, ".")
	if #v58_ > 1 then
		return v58_[1]
	else
		return nil
	end
end

function MapManager:getMapById(id)
	return self.idToMap[id]
end

-- Local values: item
function MapManager:removeMapItem(index)
	local v63_ = self.maps[index]
	if v63_ ~= nil then
		self.idToMap[v63_.id] = nil
		table.remove(self.maps, index)
	end
end

function MapManager:getNumOfMaps()
	return #self.maps
end

function MapManager:getMapDataByIndex(index)
	return self.maps[index]
end

-- Local values: _, map
function MapManager:getMapByConfigFilename(xmlFilename)
	for _, v69_ in ipairs(self.maps) do
		if v69_.mapXMLFilename == xmlFilename then
			return v69_
		end
	end
	return nil
end
g_mapManager = MapManager.new()
