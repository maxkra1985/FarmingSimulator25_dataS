MapManager = {}
local MapManager_mt = Class(MapManager, AbstractManager)
function MapManager.new(customMt)
	local self = AbstractManager.new(customMt or MapManager_mt)
	return self
end
function MapManager:initDataStructures()
	self.maps = {}
	self.idToMap = {}
end
function MapManager:addMapItem(id, scriptFilename, className, configFile, defaultVehiclesXMLFilename, defaultHandToolsXMLFilename, defaultPlaceablesXMLFilename, defaultItemsXMLFilename, title, description, iconFilename, baseDirectory, customEnvironment, isMultiplayerSupported, isModMap, prohibitOtherMods, isSelectable)
	if self.idToMap[id] ~= nil then
		Logging.warning("Duplicate map id '%s'. Ignoring this map definition.", id)
		return false
	else
		local item = {}
		item.id = tostring(id)
		item.scriptFilename = scriptFilename
		item.mapXMLFilename = configFile
		item.className = className
		item.defaultVehiclesXMLFilename = defaultVehiclesXMLFilename
		item.defaultHandToolsXMLFilename = defaultHandToolsXMLFilename
		item.defaultPlaceablesXMLFilename = defaultPlaceablesXMLFilename
		item.defaultItemsXMLFilename = defaultItemsXMLFilename
		item.title = title
		item.description = description
		item.iconFilename = iconFilename
		item.baseDirectory = baseDirectory
		item.customEnvironment = customEnvironment
		item.isMultiplayerSupported = isMultiplayerSupported
		item.isModMap = isModMap
		item.prohibitOtherMods = prohibitOtherMods
		item.isSelectable = isSelectable
		table.insert(self.maps, item)
		self.idToMap[id] = item
		return true
	end
end
function MapManager:loadMapFromXML(xmlFile, baseName, modDir, modName, isMultiplayerSupported, isDLCFile, isModMap, isInternalMod)
	local mapId = xmlFile:getString(baseName .. "#id", "")
	if mapId == "" then
		Logging.error("Failed to load map '%s'. Missing attribute '%s#id'.", modName or "Basemap", baseName)
		return false
	end
	local name = nil
	if modName ~= nil then
		name = modName
	end
	local defaultVehiclesXMLFilename = xmlFile:getString(baseName .. "#defaultVehiclesXMLFilename", "")
	local defaultHandToolsXMLFilename = xmlFile:getString(baseName .. "#defaultHandToolsXMLFilename", "")
	local defaultPlaceablesXMLFilename = xmlFile:getString(baseName .. "#defaultPlaceablesXMLFilename", "")
	local defaultItemsXMLFilename = xmlFile:getString(baseName .. "#defaultItemsXMLFilename", "")
	local mapTitle = xmlFile:getI18NValue(baseName .. ".title", "", name, true)
	local mapDesc = xmlFile:getI18NValue(baseName .. ".description", "", name, true)
	local mapClassName = xmlFile:getString(baseName .. "#className", "Mission00")
	local mapFilename = xmlFile:getString(baseName .. "#filename", "$dataS/scripts/mission00.lua")
	local configFilename = xmlFile:getString(baseName .. "#configFilename", "")
	local mapIconFilename = xmlFile:getI18NValue(baseName .. ".iconFilename", "", name, true)
	local mapName = mapId
	if modName ~= nil then
		mapName = mapName .. " " .. mapId
	end
	if mapClassName:find("[^%w_]") ~= nil then
		Logging.error("Failed to load map '%s'. Invalid map class name: '%s'. No whitespaces allowed.", mapName, mapClassName)
		return false
	elseif mapClassName == "" then
		Logging.error("Failed to load map '%s'. Missing attribute '%s#className'.", mapName, baseName)
		return false
	elseif mapTitle == "" then
		Logging.error("Failed to load map '%s'. Missing element '%s.title'.", mapName, baseName)
		return false
	elseif mapFilename == "" then
		Logging.error("Failed to load map '%s'. Missing attribute '%s#filename'.", mapName, baseName)
		return false
	elseif defaultVehiclesXMLFilename == "" then
		Logging.error("Failed to load map '%s'. Missing attribute '%s#defaultVehiclesXMLFilename'.", mapName, baseName)
		return false
	elseif defaultHandToolsXMLFilename == "" then
		Logging.error("Failed to load map '%s'. Missing attribute '%s#defaultHandToolsXMLFilename'.", mapName, baseName)
		return false
	elseif defaultPlaceablesXMLFilename == "" then
		Logging.error("Failed to load map '%s'. Missing attribute '%s#defaultPlaceablesXMLFilename'.", mapName, baseName)
		return false
	elseif defaultItemsXMLFilename == "" then
		Logging.error("Failed to load map '%s'. Missing attribute '%s#defaultItemsXMLFilename'.", mapName, baseName)
		return false
	elseif mapIconFilename == "" then
		Logging.error("Failed to load map '%s'. Missing element '%s.iconFilename'.", mapName, baseName)
		return false
	else
		local useModDirectory = nil
		mapFilename, useModDirectory = Utils.getFilename(mapFilename, modDir)
		if useModDirectory then
			mapClassName = modName .. "." .. mapClassName
		end
		local prohibitOtherMods = nil
		if isDLCFile or isInternalMod then
			prohibitOtherMods = xmlFile:getBool(baseName .. ".prohibitOtherMods", nil) or nil
		end
		local isSelectable = true
		if isDLCFile or isInternalMod then
			isSelectable = xmlFile:getBool(baseName .. ".isSelectable", isSelectable)
		end
		local fullConfigFilename = Utils.getFilename(configFilename, modDir)
		local customEnvironment, _ = Utils.getModNameAndBaseDirectory(fullConfigFilename)
		if modName ~= nil then
			mapId = modName .. "." .. mapId
		end
		mapIconFilename = Utils.getFilename(mapIconFilename, modDir)
		defaultVehiclesXMLFilename = Utils.getFilename(defaultVehiclesXMLFilename, modDir)
		defaultHandToolsXMLFilename = Utils.getFilename(defaultHandToolsXMLFilename, modDir)
		defaultPlaceablesXMLFilename = Utils.getFilename(defaultPlaceablesXMLFilename, modDir)
		defaultItemsXMLFilename = Utils.getFilename(defaultItemsXMLFilename, modDir)
		if not GS_IS_CONSOLE_VERSION or isDLCFile or not useModDirectory or isInternalMod then
			return self:addMapItem(mapId, mapFilename, mapClassName, configFilename, defaultVehiclesXMLFilename, defaultHandToolsXMLFilename, defaultPlaceablesXMLFilename, defaultItemsXMLFilename, mapTitle, mapDesc, mapIconFilename, modDir, customEnvironment, isMultiplayerSupported, isModMap, prohibitOtherMods, isSelectable)
		end
		Logging.error("Can't register map '%s' with scripts on consoles.", mapId)
		return false
	end
end
function MapManager:getModNameFromMapId(mapId)
	local parts = string.split(mapId, ".")
	if 1 < #parts then
		return parts[1]
	else
		return nil
	end
end
function MapManager:getMapById(id)
	return self.idToMap[id]
end
function MapManager:removeMapItem(index)
	local item = self.maps[index]
	if item ~= nil then
		self.idToMap[item.id] = nil
		table.remove(self.maps, index)
	end
end
function MapManager:getNumOfMaps()
	return #self.maps
end
function MapManager:getMapDataByIndex(index)
	return self.maps[index]
end
function MapManager:getMapByConfigFilename(xmlFilename)
	for _, map in ipairs(self.maps) do
		if map.mapXMLFilename == xmlFilename then
			return map
		end
	end
	return nil
end
g_mapManager = MapManager.new()
