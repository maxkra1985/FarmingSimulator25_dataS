-- Local values: HandToolSystem_mt
source("dataS/scripts/handTools/HandToolUtil.lua")
source("dataS/scripts/handTools/HandTool.lua")
source("dataS/scripts/handTools/HandToolLoadingData.lua")
source("dataS/scripts/handTools/HandToolLoadingState.lua")
source("dataS/scripts/handTools/HandToolHolder.lua")
source("dataS/scripts/handTools/HandToolHolderActivatable.lua")
source("dataS/scripts/handTools/events/HandToolSetHolderEvent.lua")
HandToolSystem = {}
local HandToolSystem_mt = Class(HandToolSystem, AbstractManager)
HandToolSystem.UNIQUE_ID_PREFIX = "HandTool"
g_xmlManager:addCreateSchemaFunction(function()
	HandToolSystem.registerXMLPaths()
	HandToolSystem.savegameXMLSchema = XMLSchema.new("savegame_handTools")
	HandToolSystem.registerSavegameXMLPaths(HandToolSystem.savegameXMLSchema)
end)
function HandToolSystem.registerXMLPaths()
	Mission00.xmlSchema:register(XMLValueType.STRING, "map.newPlayerHandTools.handTool(?)#xmlFilename", "Filename of the hand tool\'s xml file", nil, false)
	HandTool.registerXMLPaths()
end

function HandToolSystem.registerSavegameXMLPaths(savegameXMLSchema)
	savegameXMLSchema:register(XMLValueType.INT, "handTools#version", "The version of the save file", nil, true)
	HandTool.registerSavegameXMLPaths(savegameXMLSchema)
end
function HandToolSystem.new()
	-- upvalues: (copy) HandToolSystem_mt
	local v3_ = HandToolSystem_mt
	local v4_ = setmetatable({}, v3_)
	v4_.version = 1
	v4_.handTools = {}
	v4_.handToolsByUniqueId = {}
	v4_.pendingHandTools = {}
	v4_.startingPlayerHandTools = {}
	v4_.handToolsToDelete = {}
	v4_.handToolHolders = {}
	v4_.handToolHoldersByUniqueId = {}
	v4_.handToolHoldersByClickBox = {}
	v4_.isHandToolReloadRunning = false
	if g_addTestCommands then
		addConsoleCommand("gsHandToolsPendingLoadings", "Prints the pending handtool loadings", "consoleCommandPrintPendingLoadings", v4_)
	end
	addConsoleCommand("gsHandToolReload", "Reloads the currently held hand tool", "consoleCommandReloadHandTool", v4_)
	return v4_
end

-- Local values: k, handTool, _, handTool, _, handToolHolder
function HandToolSystem:delete()
	for _, v6_ in pairs(self.handToolsToDelete) do
		v6_:delete()
	end
	table.clear(self.handToolsToDelete)
	for _, v7_ in ipairs(self.handTools) do
		v7_:delete()
	end
	table.clear(self.handTools)
	for _, v8_ in ipairs(self.handToolHolders) do
		v8_:delete()
	end
	table.clear(self.handToolHolders)
	if self.savegameXMLFile ~= nil then
		self.savegameXMLFile:delete()
		self.savegameXMLFile = nil
	end
	removeConsoleCommand("gsHandToolsPendingLoadings")
	removeConsoleCommand("gsHandToolReload")
end

-- Local values: _, handToolNodeKey, handToolXMLFilename
function HandToolSystem:loadMapData(xmlFile, missionInfo, baseDirectory)
	if xmlFile ~= nil then
		local v12_ = XMLFile.wrap(xmlFile, Mission00.xmlSchema)
		for _, v13_ in v12_:iterator("map.newPlayerHandTools.handTool") do
			local v14_ = v12_:getValue(v13_ .. "#xmlFilename")
			if string.isNilOrWhitespace(v14_) then
				Logging.xmlError(v12_, "Player starting hand tool at %q has a missing filename!", v13_)
			else
				local v15_ = Utils.getFilename(v14_, baseDirectory)
				table.addElement(self.startingPlayerHandTools, v15_)
			end
		end
	end
end

function HandToolSystem:getStartingHandTools()
	return self.startingPlayerHandTools
end

function HandToolSystem:addHandTool(handTool)
	if handTool == nil or handTool:isa(HandTool) == nil then
		Logging.error("Given object is not a handtool")
		return false
	elseif handTool:getUniqueId() == nil or self.handToolsByUniqueId[handTool:getUniqueId()] == nil then
		if handTool:getUniqueId() == nil then
			handTool:setUniqueId(Utils.getUniqueId(handTool, self.handToolsByUniqueId, HandToolSystem.UNIQUE_ID_PREFIX))
		end
		table.addElement(self.handTools, handTool)
		self.handToolsByUniqueId[handTool:getUniqueId()] = handTool
		g_messageCenter:publish(MessageType.HANDTOOL_ADDED)
		return true
	else
		local v19_ = Logging.warning
		local v20_ = handTool:getUniqueId()
		local v21_ = self.handToolsByUniqueId[handTool:getUniqueId()]
		v19_("Tried to add existing handTool with unique id of %s! Existing: %s, new: %s", v20_, tostring(v21_), (tostring(handTool)))
		return false
	end
end

-- Local values: uniqueId
function HandToolSystem:removeHandTool(handTool)
	if handTool ~= nil then
		table.removeElement(self.handTools, handTool)
		local v24_ = handTool:getUniqueId()
		if v24_ ~= nil and self.handToolsByUniqueId[v24_] == handTool then
			self.handToolsByUniqueId[v24_] = nil
		end
		g_messageCenter:publish(MessageType.HANDTOOL_REMOVED)
	end
end

function HandToolSystem:getHandToolByUniqueId(uniqueId)
	return self.handToolsByUniqueId[uniqueId]
end

-- Local values: k, handTool
function HandToolSystem:deleteMarkedHandTools()
	for v28_, v29_ in pairs(self.handToolsToDelete) do
		v29_:delete()
		self.handToolsToDelete[v28_] = nil
	end
end

function HandToolSystem:markHandToolForDeletion(handTool)
	self.handToolsToDelete[handTool] = handTool
end

-- Local values: uniqueId, _, clickBoxNode
function HandToolSystem:addHandToolHolder(handToolHolder)
	if handToolHolder == nil or handToolHolder:isa(HandToolHolder) == nil then
		Logging.error("Given object is not a HandToolHolder")
		return false
	end
	table.addElement(self.handToolHolders, handToolHolder)
	local v34_ = handToolHolder:getUniqueId()
	if v34_ ~= nil and self.handToolHoldersByUniqueId[v34_] ~= nil then
		local v35_ = Logging.warning
		local v36_ = self.handToolHoldersByUniqueId[v34_]
		v35_("Tried to add existing handToolHolder (%s) but uniqueId is already in use! Existing: %s, new: %s", v34_, tostring(v36_), (tostring(handToolHolder)))
		return false
	end
	if v34_ == nil then
		v34_ = Utils.getUniqueId(handToolHolder, self.handToolHoldersByUniqueId, HandToolSystem.UNIQUE_ID_HOLDER_PREFIX)
		handToolHolder:setUniqueId(v34_)
	end
	self.handToolHoldersByUniqueId[v34_] = handToolHolder
	Logging.devInfo("Added handtool holder %q (%s)", handToolHolder, v34_)
	for _, v37_ in ipairs(handToolHolder.clickBoxes) do
		self.handToolHoldersByClickBox[v37_] = handToolHolder
	end
	return true
end

-- Local values: uniqueId, _, clickBoxNode
function HandToolSystem:removeHandToolHolder(handToolHolder)
	if handToolHolder ~= nil then
		table.removeElement(self.handToolHolders, handToolHolder)
		local v40_ = handToolHolder:getUniqueId()
		if v40_ ~= nil and self.handToolHoldersByUniqueId[v40_] == handToolHolder then
			self.handToolHoldersByUniqueId[v40_] = nil
		end
		if handToolHolder.clickBoxes ~= nil then
			for _, v41_ in ipairs(handToolHolder.clickBoxes) do
				self.handToolHoldersByClickBox[v41_] = nil
			end
		end
	end
end

function HandToolSystem:getHandToolHolderByUniqueId(uniqueId)
	return self.handToolHoldersByUniqueId[uniqueId]
end

function HandToolSystem:getHandToolHolderByClickBox(clickBoxNode)
	return clickBoxNode ~= nil and self.handToolHoldersByClickBox[clickBoxNode] or nil
end

-- Local values: xmlFile
function HandToolSystem:save(xmlFilename, usedModNames)
	local v49_ = XMLFile.create("handToolsXML", xmlFilename, "handTools", HandToolSystem.savegameXMLSchema)
	if v49_ ~= nil then
		self:saveToXML(self.handTools, v49_, usedModNames)
		v49_:delete()
	end
end

-- Local values: xmlIndex, i, handTool
function HandToolSystem:saveToXML(handTools, xmlFile, usedModNames)
	if xmlFile ~= nil then
		local v54_ = 0
		for v55_, v56_ in ipairs(handTools) do
			if v56_:getNeedsSaving() then
				self:saveHandToolToXML(v56_, xmlFile, v54_, v55_, usedModNames)
				v54_ = v54_ + 1
			end
		end
		xmlFile:save(false, true)
	end
end

-- Local values: handToolKey, modName
function HandToolSystem:saveHandToolToXML(handTool, xmlFile, index, i, usedModNames)
	local v61_ = string.format("handTools.handTool(%d)", index)
	local v62_ = handTool.customEnvironment
	if v62_ ~= nil then
		if usedModNames ~= nil then
			usedModNames[v62_] = v62_
		end
		xmlFile:setValue(v61_ .. "#modName", v62_)
	end
	xmlFile:setValue(v61_ .. "#filename", HTMLUtil.encodeToHTML(NetworkUtil.convertToNetworkFilename(handTool.configFileName)))
	handTool:saveToXMLFile(xmlFile, v61_, usedModNames)
end

function HandToolSystem:load(xmlFilename, asyncCallbackFunction, asyncCallbackObject, asyncCallbackArguments)
	self.savegameXMLFile = XMLFile.loadIfExists("handToolsXML", xmlFilename, HandToolSystem.savegameXMLSchema)
	if self.savegameXMLFile == nil then
		if asyncCallbackFunction ~= nil then
			asyncCallbackFunction(asyncCallbackObject, {}, HandToolLoadingState.OK, asyncCallbackArguments)
		end
	else
		self:loadFromXMLFile(self.savegameXMLFile, asyncCallbackFunction, asyncCallbackObject, asyncCallbackArguments)
	end
end

-- Local values: _, key
function HandToolSystem:loadFromXMLFile(xmlFile, asyncCallbackFunction, asyncCallbackObject, asyncCallbackArguments)
	self.loadedHandTools = {}
	self.handToolsToLoad = 0
	self.handToolLoadingState = nil
	self.asyncCallbackFunction = asyncCallbackFunction
	self.asyncCallbackObject = asyncCallbackObject
	self.asyncCallbackArguments = asyncCallbackArguments
	for _, v_u_73_ in xmlFile:iterator("handTools.handTool") do
		g_asyncTaskManager:addSubtask(function()
			-- upvalues: (copy) self, (copy) xmlFile, (copy) v_u_73_
			self:loadHandToolFromXML(xmlFile, v_u_73_)
		end)
	end
	if self.asyncCallbackFunction ~= nil then
		g_asyncTaskManager:addSubtask(function()
			-- upvalues: (copy) self
			if self.handToolsToLoad <= 0 then
				self.asyncCallbackFunction(self.asyncCallbackObject, self.loadedHandTools, HandToolLoadingState.OK, self.asyncCallbackArguments)
				self.asyncCallbackFunction = nil
				self.asyncCallbackObject = nil
				self.asyncCallbackArguments = nil
			end
		end)
	end
end

-- Local values: filename, allowedToLoad, savegame, storeItem, data
function HandToolSystem:loadHandToolFromXML(xmlFile, key)
	local v77_ = xmlFile:getValue(key .. "#filename")
	local v78_ = NetworkUtil.convertFromNetworkFilename(v77_)
	local v79_ = {
		["xmlFile"] = xmlFile,
		["key"] = key
	}
	local v80_ = g_storeManager:getItemByXMLFilename(v78_)
	if v80_ == nil then
		return false
	end
	self.handToolsToLoad = self.handToolsToLoad + 1
	local v81_ = HandToolLoadingData.new()
	v81_:setStoreItem(v80_)
	v81_:setSavegameData(v79_)
	v81_:load(self.loadHandToolFinished, self)
	return true
end

function HandToolSystem:loadHandToolFinished(handTool, loadingState)
	if loadingState == HandToolLoadingState.OK then
		local v85_ = self.loadedHandTools
		table.insert(v85_, handTool)
	else
		self.handToolLoadingState = self.handToolLoadingState or loadingState
	end
	self.handToolsToLoad = self.handToolsToLoad - 1
	if self.handToolsToLoad <= 0 and self.asyncCallbackFunction ~= nil then
		self.asyncCallbackFunction(self.asyncCallbackObject, self.loadedHandTools, self.handToolLoadingState or HandToolLoadingState.OK, self.asyncCallbackArguments)
		self.asyncCallbackFunction = nil
		self.asyncCallbackObject = nil
		self.asyncCallbackArguments = nil
		self.loadedHandTools = nil
		self.handToolLoadingState = nil
	end
end

function HandToolSystem:addPendingHandToolLoad(handTool)
	table.addElement(self.pendingHandTools, handTool)
end

function HandToolSystem:removePendingHandToolLoad(handTool)
	table.removeElement(self.pendingHandTools, handTool)
end

function HandToolSystem:getNumPendingHandTools()
	return #self.pendingHandTools
end

-- Local values: _, handTool
function HandToolSystem:canStartMission()
	for _, v92_ in ipairs(self.handTools) do
		if not v92_:getIsSynchronized() then
			return false
		end
	end
	return #self.pendingHandTools <= 0
end

-- Local values: _, handTool, _, handTool
function HandToolSystem:consoleCommandPrintPendingLoadings()
	Logging.info("Pending HandTool Loadings:")
	for _, v94_ in ipairs(self.pendingHandTools) do
		Logging.info("    - %s", v94_.configFileName or "Unknown")
		Logging.info("        LoadingState: %s", HandToolLoadingState.getName(v94_.loadingState))
		Logging.info("        LoadingStep: %s", SpecializationUtil.getLoadingStepName(v94_.loadingStep))
		Logging.info("        Num-Tasks: %d", #v94_.loadingTasks)
	end
	Logging.info("Pending HandTool:")
	for _, v95_ in ipairs(self.handTools) do
		if not v95_:getIsSynchronized() then
			Logging.info("    - LoadingState: %s | LoadingStep: %s | %s", HandToolLoadingState.getName(v95_.loadingState), SpecializationUtil.getLoadingStepName(v95_.loadingStep), v95_.configFileName or "Unknown")
		end
	end
end

-- Local values: player, handTool, configFileName, ownerFarmId, storeItem, xmlFile, data
function HandToolSystem:consoleCommandReloadHandTool()
	if not g_currentMission:getIsServer() or g_currentMission.missionDynamicInfo.isMultiplayer then
		return "Error: Reloading only available in singleplayer!"
	end
	if self.isHandToolReloadRunning then
		return "Error: Reloading of hand tool already in progress!"
	end
	local v97_ = g_localPlayer
	if v97_ == nil then
		return "Error: No local player found!"
	end
	local v98_ = v97_:getHeldHandTool()
	if v98_ == nil then
		return "Error: No hand tool currently held! Hold a hand tool first."
	end
	local v99_ = v98_.configFileName
	local v100_ = v98_:getOwnerFarmId()
	local v101_ = g_storeManager:getItemByXMLFilename(v99_)
	local v102_ = XMLFile.create("reloadHandToolXMLFile", "", "handTools", HandToolSystem.savegameXMLSchema)
	if v102_ == nil then
		return "Error: Unable to create XML for saving hand tool state"
	end
	self:saveHandToolToXML(v98_, v102_, 0, 1, nil)
	v102_:save(false, true)
	self.handToolsByUniqueId[v98_:getUniqueId()] = nil
	v98_:delete()
	g_i3DManager:clearEntireSharedI3DFileCache(false)
	self.isHandToolReloadRunning = true
	local v103_ = HandToolLoadingData.new()
	if v101_ == nil then
		v103_:setFilename(v99_)
	else
		v103_:setStoreItem(v101_)
	end
	v103_:setOwnerFarmId(v100_)
	v103_:setHolder(v97_)
	v103_:setSavegameData({
		["xmlFile"] = v102_,
		["key"] = "handTools.handTool(0)"
	})
	v103_:load(self.onReloadHandToolFinished, self, {
		["xmlFile"] = v102_,
		["player"] = v97_,
		["configFileName"] = v99_
	})
end

-- Local values: player
function HandToolSystem:onReloadHandToolFinished(handTool, loadingState, arguments)
	self.isHandToolReloadRunning = false
	arguments.xmlFile:delete()
	if loadingState == HandToolLoadingState.OK and handTool ~= nil then
		local v108_ = arguments.player
		handTool.pendingHolder = nil
		handTool:setHolder(v108_)
		v108_:setCurrentHandTool(handTool)
		Logging.info("Hand tool \'%s\' reloaded successfully", arguments.configFileName)
	else
		Logging.error("Failed to reload hand tool \'%s\'!", arguments.configFileName)
	end
end
