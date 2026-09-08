-- Local values: ItemSystem_mt
ItemSystem = {}
ItemSystem.UNIQUE_ID_PREFIX = "item"
local ItemSystem_mt = Class(ItemSystem)
g_xmlManager:addCreateSchemaFunction(function()
	ItemSystem.xmlSchemaSavegame = XMLSchema.new("savegame_items")
end)
g_xmlManager:addInitSchemaFunction(function()
	local v2_ = ItemSystem.xmlSchemaSavegame
	v2_:register(XMLValueType.BOOL, "items#loadAnyFarmInSingleplayer", "Load any farm in singleplayer", false)
	v2_:register(XMLValueType.STRING, "items.item(?)#className", "Class name")
	v2_:register(XMLValueType.BOOL, "items.item(?)#defaultFarmProperty", "Is property of default farm", false)
	v2_:register(XMLValueType.INT, "items.item(?)#farmId", "Farm id")
	v2_:register(XMLValueType.STRING, "items.item(?)#modName", "Name of mod")
end)

-- Upvalues: ItemSystem_mt
-- Local values: self
function ItemSystem.new(mission, customMt)
	-- upvalues: (copy) ItemSystem_mt
	local v5_ = customMt or ItemSystem_mt
	local v6_ = setmetatable({}, v5_)
	v6_.mission = mission
	v6_.itemsToSave = {}
	v6_.sortedItemsToSave = {}
	v6_.itemByUniqueId = {}
	if v6_.mission:getIsServer() and g_addTestCommands then
		addConsoleCommand("gsItemRemoveAll", "Removes all items from current mission", "consoleCommandItemRemoveAll", v6_, nil, true)
	end
	return v6_
end

-- Local values: _, item
function ItemSystem:delete()
	for _, v8_ in pairs(self.itemsToSave) do
		v8_.item:delete()
	end
end

-- Local values: count, _, item
function ItemSystem:deleteAll()
	local v10_ = 0
	for _, v11_ in pairs(self.itemsToSave) do
		v11_.item:delete()
		v10_ = v10_ + 1
	end
	return v10_
end

-- Local values: xmlFile
function ItemSystem:loadItems(xmlFilename, resetItems, missionInfo, missionDynamicInfo, asyncCallbackFunction, asyncCallbackObject, asyncCallbackArguments)
	self:loadItemsFromXML(XMLFile.load("ItemsXMLFile", xmlFilename, ItemSystem.xmlSchemaSavegame), xmlFilename, resetItems, missionInfo, missionDynamicInfo, asyncCallbackFunction, asyncCallbackObject, asyncCallbackArguments)
end

-- Local values: loadingData
function ItemSystem:loadItemsFromXML(xmlFile, xmlFilename, resetItems, missionInfo, missionDynamicInfo, asyncCallbackFunction, asyncCallbackObject, asyncCallbackArguments)
	local v29_ = {
		["xmlFile"] = xmlFile,
		["xmlFilename"] = xmlFilename,
		["resetItems"] = resetItems,
		["missionInfo"] = missionInfo,
		["missionDynamicInfo"] = missionDynamicInfo,
		["index"] = 0,
		["asyncCallbackFunction"] = asyncCallbackFunction,
		["asyncCallbackObject"] = asyncCallbackObject,
		["asyncCallbackArguments"] = asyncCallbackArguments
	}
	if not self:loadNextItemsFromSavegame(v29_) then
		self:loadItemsFromSavegameFinished(v29_)
	end
end

-- Local values: itemIndex, xmlFile, missionInfo, missionDynamicInfo, resetItems, defaultItemsToSPFarm, key, className, defaultProperty, farmId, loadForCompetitive, loadDefaultProperty, allowedToLoad, modName, itemClass, item, success
function ItemSystem:loadNextItemsFromSavegame(loadingData)
	if g_currentMission.cancelLoading then
		return false
	end
	local v32_ = loadingData.index
	loadingData.index = loadingData.index + 1
	local v33_ = loadingData.xmlFile
	if v33_ == nil then
		Logging.devInfo("Skipped item loading. Savegame xml was deleted")
		self:loadItemsFromSavegameStepFinished(nil, false, loadingData)
		return true
	end
	local v34_ = loadingData.missionInfo
	local v35_ = loadingData.missionDynamicInfo
	local v36_ = loadingData.resetItems
	local v37_ = v33_:getValue("items#loadAnyFarmInSingleplayer", false)
	local v38_ = string.format("items.item(%d)", v32_)
	if not v33_:hasProperty(v38_) then
		return false
	end
	local v39_ = v33_:getValue(v38_ .. "#className")
	if v39_ == nil then
		Logging.xmlError(v33_, "No className given for item \'%s\'", v38_)
		self:loadItemsFromSavegameStepFinished(nil, false, loadingData)
		return true
	end
	local v40_ = v33_:getValue(v38_ .. "#defaultFarmProperty")
	local v41_ = v33_:getValue(v38_ .. "#farmId")
	local v42_ = v40_ and v34_.isCompetitiveMultiplayer
	if v42_ then
		v42_ = g_farmManager:getFarmById(v41_) ~= nil
	end
	local v43_ = v40_ and (v34_.loadDefaultFarm and not v35_.isMultiplayer)
	if v43_ then
		v43_ = v41_ == FarmManager.SINGLEPLAYER_FARM_ID and true or v37_
	end
	local v44_ = v34_.isValid or (not v40_ or (v43_ or v42_))
	local v45_ = v33_:getValue(v38_ .. "#modName")
	if v45_ ~= nil and not g_modIsLoaded[v45_] then
		Logging.xmlError(v33_, "Could not load item because mod \'%s\' is not available or loaded for \'%s\'", v45_, v38_)
		self:loadItemsFromSavegameStepFinished(nil, false, loadingData)
		return true
	end
	if not v44_ then
		Logging.xmlInfo(v33_, "Item is not allowed to be loaded", v38_)
		self:loadItemsFromSavegameStepFinished(nil, false, loadingData)
		return true
	end
	local v46_ = ClassUtil.getClassObject(v39_)
	if v46_ == nil or v46_.new == nil then
		Logging.xmlError(v33_, "Class \'%s\' not defined  for item \'%s\'", v39_, v38_)
		self:loadItemsFromSavegameStepFinished(nil, false, loadingData)
		return true
	end
	local v47_ = v46_.new(self.mission:getIsServer(), self.mission:getIsClient())
	loadingData.key = v38_
	loadingData.className = v39_
	loadingData.loadDefaultProperty = v43_
	loadingData.defaultItemsToSPFarm = v37_
	loadingData.farmId = v41_
	if v47_.loadAsyncFromXMLFile == nil then
		if v47_.loadFromXMLFile ~= nil then
			self:loadItemsFromSavegameStepFinished(v47_, v47_:loadFromXMLFile(v33_, v38_, v36_), loadingData)
		end
	else
		v47_:loadAsyncFromXMLFile(v33_, v38_, v36_, self.loadItemsFromSavegameStepFinished, self, loadingData)
	end
	return true
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
				Logging.xmlError(loadingData.xmlFile, "Item \'%s\' could not be loaded correctly", item.configFileName)
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
		-- upvalues: (copy) loadingData
		loadingData.xmlFile:delete()
		if loadingData.asyncCallbackFunction ~= nil then
			loadingData.asyncCallbackFunction(loadingData.asyncCallbackObject, loadingData.asyncCallbackArguments)
		end
	end)
end

function ItemSystem:getItemByUniqueId(uniqueId)
	return self.itemByUniqueId[uniqueId]
end

-- Local values: xmlFile
function ItemSystem:save(xmlFilename, usedModNames)
	local v58_ = XMLFile.create("itemsXMLFile", xmlFilename, "items", ItemSystem.xmlSchemaSavegame)
	if v58_ ~= nil then
		self:saveToXML(v58_, usedModNames)
		v58_:delete()
	end
end

-- Local values: xmlIndex, _, item, itemKey, modName, classModName
function ItemSystem:saveToXML(xmlFile, usedModNames)
	if xmlFile ~= nil then
		local v62_ = 0
		for _, v63_ in pairs(self.itemsToSave) do
			if v63_.item.getNeedsSaving == nil or v63_.item:getNeedsSaving() then
				local v64_ = string.format("%s.item(%d)", "items", v62_)
				xmlFile:setValue(v64_ .. "#className", v63_.className)
				local v65_ = v63_.item.customEnvironment
				local v66_ = ClassUtil.getClassModName(v63_.className)
				if v65_ == nil then
					v65_ = v66_
				end
				if v65_ ~= nil then
					if usedModNames ~= nil then
						usedModNames[v65_] = v65_
					end
					xmlFile:setValue(v64_ .. "#modName", v65_)
				end
				if v66_ ~= nil and usedModNames ~= nil then
					usedModNames[v66_] = v66_
				end
				v63_.item:saveToXMLFile(xmlFile, v64_, usedModNames)
				v62_ = v62_ + 1
			end
		end
		xmlFile:save()
	end
end

function ItemSystem:addItem(item)
	if item.saveToXMLFile == nil then
		Logging.error("Adding item which does not have a saveToXMLFile function")
		return
	elseif item.getUniqueId == nil then
		Logging.error("Adding item which does not have a getUniqueId function")
		return
	elseif self.mission.objectsToClassName[item] == nil then
		Logging.error("Adding item which does not have a className registered. Use registerObjectClassName(object,className)")
		return
	elseif self.itemsToSave[item] == nil then
		self.itemsToSave[item] = {
			["item"] = item,
			["className"] = self.mission.objectsToClassName[item]
		}
		if item:getUniqueId() == nil or self.itemByUniqueId[item:getUniqueId()] == nil then
			if item:getUniqueId() == nil then
				item:setUniqueId(Utils.getUniqueId(item, self.itemByUniqueId, ItemSystem.UNIQUE_ID_PREFIX))
			end
			self.itemByUniqueId[item:getUniqueId()] = item
			table.addElement(self.sortedItemsToSave, self.itemsToSave[item])
		else
			local v69_ = Logging.warning
			local v70_ = item:getUniqueId()
			local v71_ = self.itemByUniqueId[item:getUniqueId()]
			v69_("Tried to add existing item with unique id of %s! Existing: %s, new: %s", v70_, tostring(v71_), (tostring(item)))
		end
	else
		return
	end
end

-- Local values: itemData
function ItemSystem:removeItem(item)
	local v74_ = self.itemsToSave[item]
	if v74_ == nil then
		Logging.devInfo("ItemSystem: Trying to remove item that was never added before. Ignoring it.")
		printCallstack()
	else
		table.removeElement(self.sortedItemsToSave, v74_)
		self.itemsToSave[item] = nil
		self.itemByUniqueId[item:getUniqueId()] = nil
	end
end

-- Local values: numDeleted
function ItemSystem:consoleCommandItemRemoveAll()
	local v76_ = self:deleteAll() + self.mission.vehicleSystem:deleteAllPallets()
	return string.format("Deleted %i item(s)!", v76_)
end
