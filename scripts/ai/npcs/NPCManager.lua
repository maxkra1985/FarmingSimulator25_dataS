source("dataS/scripts/ai/npcs/NPCSpot.lua")
source("dataS/scripts/ai/npcs/NPCConversationFailedState.lua")
NPCManager = {}
NPCManager.DEBUG_ANIMATIONS = false
local NPCManager_mt = Class(NPCManager, AbstractManager)
g_xmlManager:addCreateSchemaFunction(function()
	NPCManager.xmlSchema = XMLSchema.new("npcs")
	NPCManager.xmlSchemaSavegame = XMLSchema.new("savegame_npcs")
end)
g_xmlManager:addInitSchemaFunction(function()
	local missionXMLSchema = Mission00.xmlSchema
	missionXMLSchema:register(XMLValueType.STRING, "map.npcs#filename", "Filename of the npcs available on the map")
	local schema = NPCManager.xmlSchema
	schema:register(XMLValueType.STRING, "map.npcs.npc(?)#name", "Name identifier of npc", nil, true)
	schema:register(XMLValueType.STRING, "map.npcs.npc(?)", "Path to npc config file", nil, true)
	local savegameSchema = NPCManager.xmlSchemaSavegame
	savegameSchema:register(XMLValueType.STRING, "npcs.npc(?)#name", "Name identifier of npc")
end)
function NPCManager.new(customMt)
	local self = AbstractManager.new(customMt or NPCManager_mt)
	self.drawDebug = false
	return self
end
function NPCManager:initDataStructures()
	self.npcs = {}
	self.nameToNPC = {}
	self.nameToIndex = {}
	self.spots = {}
	self.uniqueIdToSpot = {}
	self.startSpots = {}
	self.conversationActionClasses = {}
	self.conversationPrerequisiteClasses = {}
	self.conversationInputClasses = {}
	self.conversationOptionPrerequisiteClasses = {}
end
function NPCManager:loadDefaultTypes(missionInfo, baseDirectory) end
function NPCManager:unloadMapData()
	g_messageCenter:unsubscribeAll(self)
	if self.npcXMLFile ~= nil then
		self.npcXMLFile:delete()
		self.npcXMLFile = nil
	end
	for _, spot in pairs(self.uniqueIdToSpot) do
		spot:deactivate()
	end
	removeConsoleCommand("gsNPCValidate")
	removeConsoleCommand("gsNPCAnimationReload")
	removeConsoleCommand("gsNPCAnimationDebug")
	removeConsoleCommand("gsNPCSetNextConversation")
	NPCManager:superClass().unloadMapData(self)
end
function NPCManager:loadMapData(xmlFile, missionInfo, baseDirectory)
	NPCManager:superClass().loadMapData(self)
	local filename = getXMLString(xmlFile, "map.npcs#filename")
	if filename ~= nil then
		local xmlFilename = Utils.getFilename(filename, baseDirectory)
		self.npcXMLFile = XMLFile.load("npcsXML", xmlFilename, NPCManager.xmlSchema)
		if self.npcXMLFile == nil then
			return false
		end
		for _, key in self.npcXMLFile:iterator("map.npcs.npc") do
			g_asyncTaskManager:addSubtask(function()
				self:loadNPC(self.npcXMLFile, key, missionInfo, baseDirectory)
			end, "NPCManager - loadNPC " .. key)
		end
		g_asyncTaskManager:addSubtask(function()
			if self.npcXMLFile ~= nil then
				self.npcXMLFile:delete()
				self.npcXMLFile = nil
			end
			g_messageCenter:subscribeOneshot(MessageType.CURRENT_MISSION_START, NPCManager.onMissionStarted, self)
		end)
	end
	if g_addTestCommands then
		addConsoleCommand("gsNPCValidate", "Validates selected language", "consoleCommandValidate", self, "[languageSuffix]")
		addConsoleCommand("gsNPCAnimationReload", "Reloads the animations", "consoleCommandAnimationReload", self)
		addConsoleCommand("gsNPCAnimationDebug", "Reloads the animations", "consoleCommandAnimationDebug", self)
		addConsoleCommand("gsNPCSetNextConversation", "Sets the next conversation", "consoleCommandSetNextConversation", self)
	end
	return true
end
function NPCManager:loadNPC(xmlFile, key, missionInfo, baseDirectory)
	local xmlFilename = Utils.getFilename(xmlFile:getValue(key), baseDirectory)
	if xmlFilename == nil then
		Logging.xmlWarning(xmlFile, "Missing xmlFilename for npc '%s'", key)
		return
	end
	local name = xmlFile:getValue(key .. "#name")
	if name == nil then
		Logging.xmlWarning(xmlFile, "Missing name for npc '%s'", key)
		return
	end
	local upperName = string.upper(name)
	if self.nameToNPC[upperName] ~= nil then
		Logging.xmlWarning(xmlFile, "NPC with name '%s' already exists for '%s'!", name, key)
		return
	end
	local npc, isDLCMissing = NPCUtil.createFromXML(xmlFilename)
	if isDLCMissing then
		return
	elseif npc == nil then
		Logging.xmlWarning(xmlFile, "Could not create NPC from file '%s' for '%s'!", xmlFilename, key)
		return
	else
		table.insert(self.npcs, npc)
		self.nameToNPC[upperName] = npc
		self.nameToIndex[upperName] = #self.npcs
		npc.name = upperName
		npc.index = #self.npcs
		npc:register(true)
		g_currentMission.onCreateObjectSystem:add(npc)
		return true
	end
end
function NPCManager:saveToXMLFile(xmlFilename)
	local xmlFile = XMLFile.create("npcsXML", xmlFilename, "npcs", NPCManager.xmlSchemaSavegame)
	if xmlFile == nil then
		Logging.error("Failed to create npc xml file")
		return false
	else
		for k, npc in ipairs(self.npcs) do
			local key = string.format("npcs.npc(%d)", k - 1)
			xmlFile:setValue(key .. "#name", npc.name)
			npc:saveToSavegameXMLFile(xmlFile, key)
		end
		local index = 0
		for _, spot in pairs(self.uniqueIdToSpot) do
			if spot.needsSaving then
				local key = string.format("npcs.spots.spot(%d)", index)
				spot:saveToSavegameXMLFile(xmlFile, key)
				index = index + 1
			end
		end
		xmlFile:save()
		xmlFile:delete()
		return true
	end
end
function NPCManager:loadFromSavegameXMLFile(xmlFilename)
	if xmlFilename == nil then
		return false
	end
	local xmlFile = XMLFile.load("npcXML", xmlFilename, NPCManager.xmlSchemaSavegame)
	if xmlFile == nil then
		return false
	else
		for _, key in xmlFile:iterator("npcs.npc") do
			local name = xmlFile:getValue(key .. "#name")
			local npc = self:getNPCByName(name)
			if npc ~= nil then
				npc:loadFromSavegameXMLFile(xmlFile, key)
			else
				Logging.xmlWarning(xmlFile, "Npc '%s' not found!", name)
			end
		end
		for _, key in xmlFile:iterator("npcs.spots.spot") do
			local spot = NPCSpot.new()
			if spot:loadFromSavegameXMLFile(xmlFile, key) then
				self:addSpot(spot)
			else
				Logging.xmlWarning(xmlFile, "Npc spot could not be loaded - %s!", key)
				spot:delete()
			end
		end
		xmlFile:delete()
		return true
	end
end
function NPCManager:update(dt)
	local x, y, z = getWorldTranslation(g_cameraManager:getActiveCamera())
	for _, npc in ipairs(self.npcs) do
		local needNewSpot = false
		local isActive = npc:getIsActive()
		if isActive then
			local distance = MathUtil.vector3Length(npc.x - x, npc.y + PlayerCamera.FIRST_PERSON_Y_OFFSET - y, npc.z - z)
			npc:setDistanceToCamera(distance)
			if g_server ~= nil then
				local spot = npc:getSpot()
				if not spot:getIsAvailable() then
					needNewSpot = true
				end
			end
		else
			needNewSpot = true
		end
		if g_server == nil then
			continue
		end
		if needNewSpot then
			local spot = g_npcManager:getAvailableSpot(npc)
			if spot ~= nil then
				npc:setSpot(spot)
			elseif isActive then
				npc:setSpot(nil)
			end
		end
	end
end
function NPCManager:onMissionStarted(isNewSavegame)
	if isNewSavegame then
		for _, npc in pairs(self.nameToNPC) do
			local spots = self.startSpots[npc]
			if spots == nil then
				continue
			end
			local spot = spots[math.random(1, #spots)]
			npc:setSpot(spot)
		end
	end
	for _, spot in pairs(self.uniqueIdToSpot) do
		spot:activate()
	end
end
function NPCManager:addSpot(spot)
	local npc = spot.npc
	if npc ~= nil then
		if self.spots[npc] == nil then
			self.spots[npc] = {}
		end
		table.addElement(self.spots[npc], spot)
		if spot.isStartSpot then
			if self.startSpots[npc] == nil then
				self.startSpots[npc] = {}
			end
			table.addElement(self.startSpots[npc], spot)
		end
		if g_currentMission.isMissionStarted then
			spot:activate()
		end
	end
	self.uniqueIdToSpot[spot.uniqueId] = spot
end
function NPCManager:removeSpot(spot)
	for _, npc in ipairs(self.npcs) do
		if npc:getSpot() == spot then
			npc:setSpot(nil)
		end
	end
	spot:deactivate()
	local npc = spot.npc
	if npc ~= nil then
		if self.spots[npc] ~= nil then
			table.removeElement(self.spots[npc], spot)
		end
		if spot.isStartSpot and self.startSpots[npc] ~= nil then
			table.removeElement(self.startSpots[npc], spot)
		end
	end
	if spot.uniqueId ~= nil then
		self.uniqueIdToSpot[spot.uniqueId] = nil
	end
end
function NPCManager:getSpotByUniqueId(uniqueId)
	if uniqueId == nil then
		return nil
	else
		return self.uniqueIdToSpot[uniqueId]
	end
end
function NPCManager:getAvailableSpot(npc)
	local spots = self.spots[npc]
	if spots == nil then
		return nil
	end
	local availableSpots = {}
	for _, spot in ipairs(spots) do
		if spot:getIsAvailable() then
			table.insert(availableSpots, spot)
		end
	end
	if 0 < #availableSpots then
		return availableSpots[math.random(1, #availableSpots)]
	else
		return nil
	end
end
function NPCManager:getRandomNPC()
	return self.npcs[self:getRandomIndex()]
end
function NPCManager:getRandomIndex()
	return 0 < #self.npcs and math.random(1, #self.npcs) or 0
end
function NPCManager:getNPCByIndex(index)
	if index ~= nil then
		return self.npcs[index]
	else
		return nil
	end
end
function NPCManager:getNPCByName(name)
	if name ~= nil then
		name = string.upper(name)
		return self.nameToNPC[name]
	else
		return nil
	end
end
function NPCManager:registerConversationActionClass(name, class)
	self.conversationActionClasses[name] = class
end
function NPCManager:getAllConverationActionClasses()
	return self.conversationActionClasses
end
function NPCManager:registerConversationPrerequisiteClass(name, class)
	self.conversationPrerequisiteClasses[name] = class
end
function NPCManager:getAllConverationPrerequisiteClasses()
	return self.conversationPrerequisiteClasses
end
function NPCManager:registerConversationInputClass(name, class)
	self.conversationInputClasses[name] = class
end
function NPCManager:getAllConverationInputClasses()
	return self.conversationInputClasses
end
function NPCManager:registerConversationOptionPrerequisiteClass(name, class)
	self.conversationOptionPrerequisiteClasses[name] = class
end
function NPCManager:getAllConverationOptionPrerequisiteClasses()
	return self.conversationOptionPrerequisiteClasses
end
function NPCManager:consoleCommandAnimationReload()
	for _, npc in ipairs(self.npcs) do
		if npc.playerGraphics == nil then
			continue
		end
		npc.playerGraphics:loadAnimation()
	end
	return "Reloaded animation"
end
function NPCManager:consoleCommandAnimationDebug()
	NPCManager.DEBUG_ANIMATIONS = not NPCManager.DEBUG_ANIMATIONS
	return string.format("Animation debug: %s", NPCManager.DEBUG_ANIMATIONS)
end
function NPCManager:consoleCommandSetNextConversation(npcName, conversationUniqueId)
	for _, npc in ipairs(self.npcs) do
		if string.upper(npcName) == npc.name then
			local conversation = npc:getConversationById(conversationUniqueId)
			if conversation ~= nil then
				npc:setNextConversation(conversation)
				return "Done"
			else
				return string.format("Conversation '%s' not defined for NPC '%s'", conversationUniqueId, npcName)
			end
		end
	end
	return string.format("NPC '%s' not found", npcName)
end
function NPCManager:consoleCommandValidate(languageSuffix, npcName)
	local doAll = languageSuffix == "all"
	if not doAll then
		languageSuffix = languageSuffix or g_languageSuffix
		if not string.startsWith(languageSuffix, "_") then
			return "Invalid language suffix. Please only use '_en', '_de' or similar"
		end
	end
	local index = 0
	for _, npc in ipairs(self.npcs) do
		if npcName ~= nil and string.upper(npcName) == npc.name then
			while doAll do
				index = index + 1
				if not (getNumOfLanguages() <= index) then
					languageSuffix = getLanguageCode(index)
					languageSuffix = "_" .. languageSuffix
					break
				end
			end
			while true do
				local oldSuffix = g_languageSuffix
				g_languageSuffix = languageSuffix
				NPCText.FALLBACK_TEXT_SUFFIX = languageSuffix
				Logging.info("Start NPC Validation: '%s' for language: %s", npc.xmlFilename, languageSuffix)
				npc:validate()
				Logging.info("Finished NPC Validation")
				g_languageSuffix = oldSuffix
				NPCText.FALLBACK_TEXT_SUFFIX = "_en"
				if not doAll then
					break
				end
			end
		end
	end
	return "Finished"
end
g_npcManager = NPCManager.new()
