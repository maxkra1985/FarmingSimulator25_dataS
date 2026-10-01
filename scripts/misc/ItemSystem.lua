ItemSystem = {}
ItemSystem.UNIQUE_ID_PREFIX = "item"
local ItemSystem_mt = Class(ItemSystem)
g_xmlManager:addCreateSchemaFunction(function()
	ItemSystem.xmlSchemaSavegame = XMLSchema.new("savegame_items")
end)
g_xmlManager:addInitSchemaFunction(function()
	local schema = ItemSystem.xmlSchemaSavegame
	schema:register(XMLValueType.BOOL, "items#loadAnyFarmInSingleplayer", "Load any farm in singleplayer", false)
	schema:register(XMLValueType.STRING, "items.item(?)#className", "Class name")
	schema:register(XMLValueType.BOOL, "items.item(?)#defaultFarmProperty", "Is property of default farm", false)
	schema:register(XMLValueType.INT, "items.item(?)#farmId", "Farm id")
	schema:register(XMLValueType.STRING, "items.item(?)#modName", "Name of mod")
end)
function ItemSystem.new(mission, customMt)
	local self = setmetatable({}, customMt or ItemSystem_mt)
	self.mission = mission
	self.itemsToSave = {}
	self.sortedItemsToSave = {}
	self.itemByUniqueId = {}
	if self.mission:getIsServer() and g_addTestCommands then
		addConsoleCommand("gsItemRemoveAll", "Removes all items from current mission", "consoleCommandItemRemoveAll", self, nil, true)
	end
	return self
end
function ItemSystem:delete()
	for _, item in pairs(self.itemsToSave) do
		item.item:delete()
	end
end
function ItemSystem:deleteAll()
	local count = 0
	for _, item in pairs(self.itemsToSave) do
		item.item:delete()
		count = count + 1
	end
	return count
end
function ItemSystem:loadItems(xmlFilename, resetItems, missionInfo, missionDynamicInfo, asyncCallbackFunction, asyncCallbackObject, asyncCallbackArguments)
	local xmlFile = XMLFile.load("ItemsXMLFile", xmlFilename, ItemSystem.xmlSchemaSavegame)
	self:loadItemsFromXML(xmlFile, xmlFilename, resetItems, missionInfo, missionDynamicInfo, asyncCallbackFunction, asyncCallbackObject, asyncCallbackArguments)
end
function ItemSystem:loadItemsFromXML(xmlFile, xmlFilename, resetItems, missionInfo, missionDynamicInfo, asyncCallbackFunction, asyncCallbackObject, asyncCallbackArguments)
	local loadingData = {}
	loadingData.xmlFile = xmlFile
	loadingData.xmlFilename = xmlFilename
	loadingData.resetItems = resetItems
	loadingData.missionInfo = missionInfo
	loadingData.missionDynamicInfo = missionDynamicInfo
	loadingData.index = 0
	loadingData.asyncCallbackFunction = asyncCallbackFunction
	loadingData.asyncCallbackObject = asyncCallbackObject
	loadingData.asyncCallbackArguments = asyncCallbackArguments
	if not self:loadNextItemsFromSavegame(loadingData) then
		self:loadItemsFromSavegameFinished(loadingData)
	end
end
function ItemSystem:loadNextItemsFromSavegame(loadingData)
	if g_currentMission.cancelLoading then
		return false
	end
	local itemIndex = loadingData.index
	loadingData.index = loadingData.index + 1
	local xmlFile = loadingData.xmlFile
	if xmlFile == nil then
		Logging.devInfo("Skipped item loading. Savegame xml was deleted")
		self:loadItemsFromSavegameStepFinished(nil, false, loadingData)
		return true
	end
	local missionInfo = loadingData.missionInfo
	local missionDynamicInfo = loadingData.missionDynamicInfo
	local resetItems = loadingData.resetItems
	local defaultItemsToSPFarm = xmlFile:getValue("items#loadAnyFarmInSingleplayer", false)
	local key = string.format("items.item(%d)", itemIndex)
	if not xmlFile:hasProperty(key) then
		return false
	end
	local className = xmlFile:getValue(key .. "#className")
	if className == nil then
		Logging.xmlError(xmlFile, "No className given for item '%s'", key)
		self:loadItemsFromSavegameStepFinished(nil, false, loadingData)
		return true
	end
	local defaultProperty = xmlFile:getValue(key .. "#defaultFarmProperty")
	local farmId = xmlFile:getValue(key .. "#farmId")
	local loadForCompetitive = defaultProperty and missionInfo.isCompetitiveMultiplayer and g_farmManager:getFarmById(farmId) ~= nil
	if defaultProperty and (missionInfo.loadDefaultFarm and not missionDynamicInfo.isMultiplayer) then
		local loadDefaultProperty = true
		if farmId ~= FarmManager.SINGLEPLAYER_FARM_ID then
			loadDefaultProperty = defaultItemsToSPFarm
		end
	end
	local allowedToLoad = missionInfo.isValid or not defaultProperty or loadDefaultProperty or loadForCompetitive
	local modName = xmlFile:getValue(key .. "#modName")
	if modName ~= nil and not g_modIsLoaded[modName] then
		Logging.xmlError(xmlFile, "Could not load item because mod '%s' is not available or loaded for '%s'", modName, key)
		self:loadItemsFromSavegameStepFinished(nil, false, loadingData)
		return true
	end
	if not allowedToLoad then
		Logging.xmlInfo(xmlFile, "Item is not allowed to be loaded", key)
		self:loadItemsFromSavegameStepFinished(nil, false, loadingData)
		return true
	else
		local itemClass = ClassUtil.getClassObject(className)
		if itemClass == nil or itemClass.new == nil then
			Logging.xmlError(xmlFile, "Class '%s' not defined  for item '%s'", className, key)
			self:loadItemsFromSavegameStepFinished(nil, false, loadingData)
			return true
		end
		local item = itemClass.new(self.mission:getIsServer(), self.mission:getIsClient())
		loadingData.key = key
		loadingData.className = className
		loadingData.loadDefaultProperty = loadDefaultProperty
		loadingData.defaultItemsToSPFarm = defaultItemsToSPFarm
		loadingData.farmId = farmId
		if item.loadAsyncFromXMLFile ~= nil then
			item:loadAsyncFromXMLFile(xmlFile, key, resetItems, self.loadItemsFromSavegameStepFinished, self, loadingData)
		elseif item.loadFromXMLFile ~= nil then
			local success = item:loadFromXMLFile(xmlFile, key, resetItems)
			self:loadItemsFromSavegameStepFinished(item, success, loadingData)
		end
		return true
	end
end
function ItemSystem:loadItemsFromSavegameStepFinished(item, success, loadingData)
	if g_currentMission.cancelLoading then
		self:loadItemsFromSavegameFinished(loadingData)
	else
		if item ~= nil then
			if success then
				if loadingData.loadDefaultProperty and (loadingData.defaultItemsToSPFarm and loadingData.farmId ~= FarmManager.SINGLEPLAYER_FARM_ID) then
					item:setOwnerFarmId(FarmManager.SINGLEPLAYER_FARM_ID)
				end
				item:register()
				self:addItem(item)
			else
				Logging.xmlError(loadingData.xmlFile, "Item '%s' could not be loaded correctly", item.configFileName)
				item:delete()
			end
		end
		if not self:loadNextItemsFromSavegame(loadingData) then
			self:loadItemsFromSavegameFinished(loadingData)
		end
	end
end
function ItemSystem:loadItemsFromSavegameFinished(loadingData)
	g_asyncTaskManager:addTask(function()
		loadingData.xmlFile:delete()
		if loadingData.asyncCallbackFunction ~= nil then
			loadingData.asyncCallbackFunction(loadingData.asyncCallbackObject, loadingData.asyncCallbackArguments)
		end
	end)
end
function ItemSystem:getItemByUniqueId(uniqueId)
	return self.itemByUniqueId[uniqueId]
end
function ItemSystem:save(xmlFilename, usedModNames)
	local xmlFile = XMLFile.create("itemsXMLFile", xmlFilename, "items", ItemSystem.xmlSchemaSavegame)
	if xmlFile ~= nil then
		self:saveToXML(xmlFile, usedModNames)
		xmlFile:delete()
	end
end
function ItemSystem:saveToXML(xmlFile, usedModNames)
	if xmlFile ~= nil then
		local xmlIndex = 0
		for _, item in pairs(self.itemsToSave) do
			if item.item.getNeedsSaving == nil or item.item:getNeedsSaving() then
				local itemKey = string.format("%s.item(%d)", "items", xmlIndex)
				xmlFile:setValue(itemKey .. "#className", item.className)
				local modName = item.item.customEnvironment
				local classModName = ClassUtil.getClassModName(item.className)
				if modName == nil then
					modName = classModName
				end
				if modName ~= nil then
					if usedModNames ~= nil then
						usedModNames[modName] = modName
					end
					xmlFile:setValue(itemKey .. "#modName", modName)
				end
				if classModName ~= nil and usedModNames ~= nil then
					usedModNames[classModName] = classModName
				end
				item.item:saveToXMLFile(xmlFile, itemKey, usedModNames)
				xmlIndex = xmlIndex + 1
			end
		end
		xmlFile:save()
	end
end
function ItemSystem:addItem(item)
	if item.saveToXMLFile == nil then
		Logging.error("Adding item which does not have a saveToXMLFile function")
	elseif item.getUniqueId == nil then
		Logging.error("Adding item which does not have a getUniqueId function")
	elseif self.mission.objectsToClassName[item] == nil then
		Logging.error("Adding item which does not have a className registered. Use registerObjectClassName(object,className)")
	elseif self.itemsToSave[item] == nil then
		self.itemsToSave[item] = { item = item, className = self.mission.objectsToClassName[item] }
		if item:getUniqueId() ~= nil and self.itemByUniqueId[item:getUniqueId()] ~= nil then
			Logging.warning("Tried to add existing item with unique id of %s! Existing: %s, new: %s", item:getUniqueId(), tostring(self.itemByUniqueId[item:getUniqueId()]), tostring(item))
			return
		end
		if item:getUniqueId() == nil then
			item:setUniqueId(Utils.getUniqueId(item, self.itemByUniqueId, ItemSystem.UNIQUE_ID_PREFIX))
		end
		self.itemByUniqueId[item:getUniqueId()] = item
		table.addElement(self.sortedItemsToSave, self.itemsToSave[item])
	end
end
function ItemSystem:removeItem(item)
	local itemData = self.itemsToSave[item]
	if itemData == nil then
		Logging.devInfo("ItemSystem: Trying to remove item that was never added before. Ignoring it.")
		printCallstack()
	else
		table.removeElement(self.sortedItemsToSave, itemData)
		self.itemsToSave[item] = nil
		self.itemByUniqueId[item:getUniqueId()] = nil
	end
end
function ItemSystem:consoleCommandItemRemoveAll()
	local numDeleted = self:deleteAll()
	numDeleted = numDeleted + self.mission.vehicleSystem:deleteAllPallets()
	return string.format("Deleted %i item(s)!", numDeleted)
end
