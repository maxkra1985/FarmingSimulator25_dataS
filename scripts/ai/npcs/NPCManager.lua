-- Local values: NPCManager_mt
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
	Mission00.xmlSchema:register(XMLValueType.STRING, "map.npcs#filename", "Filename of the npcs available on the map")
	local v2_ = NPCManager.xmlSchema
	v2_:register(XMLValueType.STRING, "map.npcs.npc(?)#name", "Name identifier of npc", nil, true)
	v2_:register(XMLValueType.STRING, "map.npcs.npc(?)", "Path to npc config file", nil, true)
	NPCManager.xmlSchemaSavegame:register(XMLValueType.STRING, "npcs.npc(?)#name", "Name identifier of npc")
end)

-- Upvalues: NPCManager_mt
-- Local values: self
function NPCManager.new(customMt)
	-- upvalues: (copy) NPCManager_mt
	local v4_ = AbstractManager.new(customMt or NPCManager_mt)
	v4_.drawDebug = false
	return v4_
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

-- Local values: _, spot
function NPCManager:unloadMapData()
	g_messageCenter:unsubscribeAll(self)
	if self.npcXMLFile ~= nil then
		self.npcXMLFile:delete()
		self.npcXMLFile = nil
	end
	for _, v7_ in pairs(self.uniqueIdToSpot) do
		v7_:deactivate()
	end
	removeConsoleCommand("gsNPCValidate")
	removeConsoleCommand("gsNPCAnimationReload")
	removeConsoleCommand("gsNPCAnimationDebug")
	removeConsoleCommand("gsNPCSetNextConversation")
	NPCManager:superClass().unloadMapData(self)
end

-- Local values: filename, xmlFilename, _, key
function NPCManager:loadMapData(xmlFile, missionInfo, baseDirectory)
	NPCManager:superClass().loadMapData(self)
	local v12_ = getXMLString(xmlFile, "map.npcs#filename")
	if v12_ ~= nil then
		local v13_ = Utils.getFilename(v12_, baseDirectory)
		self.npcXMLFile = XMLFile.load("npcsXML", v13_, NPCManager.xmlSchema)
		if self.npcXMLFile == nil then
			return false
		end
		for _, v_u_14_ in self.npcXMLFile:iterator("map.npcs.npc") do
			g_asyncTaskManager:addSubtask(function()
				-- upvalues: (copy) self, (copy) v_u_14_, (copy) missionInfo, (copy) baseDirectory
				self:loadNPC(self.npcXMLFile, v_u_14_, missionInfo, baseDirectory)
			end, "NPCManager - loadNPC " .. v_u_14_)
		end
		g_asyncTaskManager:addSubtask(function()
			-- upvalues: (copy) self
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

-- Local values: xmlFilename, name, upperName, npc, isDLCMissing
function NPCManager:loadNPC(xmlFile, key, missionInfo, baseDirectory)
	local v19_ = Utils.getFilename(xmlFile:getValue(key), baseDirectory)
	if v19_ == nil then
		Logging.xmlWarning(xmlFile, "Missing xmlFilename for npc \'%s\'", key)
		return
	else
		local v20_ = xmlFile:getValue(key .. "#name")
		if v20_ == nil then
			Logging.xmlWarning(xmlFile, "Missing name for npc \'%s\'", key)
			return
		else
			local v21_ = string.upper(v20_)
			if self.nameToNPC[v21_] == nil then
				local v22_, v23_ = NPCUtil.createFromXML(v19_)
				if not v23_ then
					if v22_ ~= nil then
						local v24_ = self.npcs
						table.insert(v24_, v22_)
						self.nameToNPC[v21_] = v22_
						self.nameToIndex[v21_] = #self.npcs
						v22_.name = v21_
						v22_.index = #self.npcs
						v22_:register(true)
						g_currentMission.onCreateObjectSystem:add(v22_)
						return true
					end
					Logging.xmlWarning(xmlFile, "Could not create NPC from file \'%s\' for \'%s\'!", v19_, key)
				end
			else
				Logging.xmlWarning(xmlFile, "NPC with name \'%s\' already exists for \'%s\'!", v20_, key)
				return
			end
		end
	end
end

-- Local values: xmlFile, k, npc, key, index, _, spot, key
function NPCManager:saveToXMLFile(xmlFilename)
	local v27_ = XMLFile.create("npcsXML", xmlFilename, "npcs", NPCManager.xmlSchemaSavegame)
	if v27_ == nil then
		Logging.error("Failed to create npc xml file")
		return false
	end
	for v28_, v29_ in ipairs(self.npcs) do
		local v30_ = string.format("npcs.npc(%d)", v28_ - 1)
		v27_:setValue(v30_ .. "#name", v29_.name)
		v29_:saveToSavegameXMLFile(v27_, v30_)
	end
	local v31_ = 0
	for _, v32_ in pairs(self.uniqueIdToSpot) do
		if v32_.needsSaving then
			v32_:saveToSavegameXMLFile(v27_, (string.format("npcs.spots.spot(%d)", v31_)))
			v31_ = v31_ + 1
		end
	end
	v27_:save()
	v27_:delete()
	return true
end

-- Local values: xmlFile, _, key, name, npc, _, key, spot
function NPCManager:loadFromSavegameXMLFile(xmlFilename)
	if xmlFilename == nil then
		return false
	end
	local v35_ = XMLFile.load("npcXML", xmlFilename, NPCManager.xmlSchemaSavegame)
	if v35_ == nil then
		return false
	end
	for _, v36_ in v35_:iterator("npcs.npc") do
		local v37_ = v35_:getValue(v36_ .. "#name")
		local v38_ = self:getNPCByName(v37_)
		if v38_ == nil then
			Logging.xmlWarning(v35_, "Npc \'%s\' not found!", v37_)
		else
			v38_:loadFromSavegameXMLFile(v35_, v36_)
		end
	end
	for _, v39_ in v35_:iterator("npcs.spots.spot") do
		local v40_ = NPCSpot.new()
		if v40_:loadFromSavegameXMLFile(v35_, v39_) then
			self:addSpot(v40_)
		else
			Logging.xmlWarning(v35_, "Npc spot could not be loaded - %s!", v39_)
			v40_:delete()
		end
	end
	v35_:delete()
	return true
end

-- Local values: x, y, z, _, npc, needNewSpot, isActive, distance, spot, spot
function NPCManager:update(dt)
	local v42_, v43_, v44_ = getWorldTranslation(g_cameraManager:getActiveCamera())
	for _, v45_ in ipairs(self.npcs) do
		local v46_ = false
		local v47_ = v45_:getIsActive()
		local v48_
		if v47_ then
			v45_:setDistanceToCamera((MathUtil.vector3Length(v45_.x - v42_, v45_.y + PlayerCamera.FIRST_PERSON_Y_OFFSET - v43_, v45_.z - v44_)))
			v48_ = g_server ~= nil and not v45_:getSpot():getIsAvailable() and true or v46_
		else
			v48_ = true
		end
		if g_server ~= nil and v48_ then
			local v49_ = g_npcManager:getAvailableSpot(v45_)
			if v49_ == nil then
				if v47_ then
					v45_:setSpot(nil)
				end
			else
				v45_:setSpot(v49_)
			end
		end
	end
end

-- Local values: _, npc, spots, spot, _, spot
function NPCManager:onMissionStarted(isNewSavegame)
	if isNewSavegame then
		for _, v52_ in pairs(self.nameToNPC) do
			local v53_ = self.startSpots[v52_]
			if v53_ ~= nil then
				v52_:setSpot(v53_[math.random(1, #v53_)])
			end
		end
	end
	for _, v54_ in pairs(self.uniqueIdToSpot) do
		v54_:activate()
	end
end

-- Local values: npc
function NPCManager:addSpot(spot)
	local v57_ = spot.npc
	if v57_ ~= nil then
		if self.spots[v57_] == nil then
			self.spots[v57_] = {}
		end
		table.addElement(self.spots[v57_], spot)
		if spot.isStartSpot then
			if self.startSpots[v57_] == nil then
				self.startSpots[v57_] = {}
			end
			table.addElement(self.startSpots[v57_], spot)
		end
		if g_currentMission.isMissionStarted then
			spot:activate()
		end
	end
	self.uniqueIdToSpot[spot.uniqueId] = spot
end

-- Local values: _, npc, npc
function NPCManager:removeSpot(spot)
	for _, v60_ in ipairs(self.npcs) do
		if v60_:getSpot() == spot then
			v60_:setSpot(nil)
		end
	end
	spot:deactivate()
	local v61_ = spot.npc
	if v61_ ~= nil then
		if self.spots[v61_] ~= nil then
			table.removeElement(self.spots[v61_], spot)
		end
		if spot.isStartSpot and self.startSpots[v61_] ~= nil then
			table.removeElement(self.startSpots[v61_], spot)
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

-- Local values: spots, availableSpots, _, spot
function NPCManager:getAvailableSpot(npc)
	local v66_ = self.spots[npc]
	if v66_ == nil then
		return nil
	else
		local v67_ = {}
		for _, v68_ in ipairs(v66_) do
			if v68_:getIsAvailable() then
				table.insert(v67_, v68_)
			end
		end
		if #v67_ > 0 then
			return v67_[math.random(1, #v67_)]
		else
			return nil
		end
	end
end

function NPCManager:getRandomNPC()
	return self.npcs[self:getRandomIndex()]
end

function NPCManager:getRandomIndex()
	return #self.npcs > 0 and math.random(1, #self.npcs) or 0
end

function NPCManager:getNPCByIndex(index)
	if index == nil then
		return nil
	else
		return self.npcs[index]
	end
end

function NPCManager:getNPCByName(name)
	if name == nil then
		return nil
	end
	local v75_ = string.upper(name)
	return self.nameToNPC[v75_]
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

-- Local values: _, npc
function NPCManager:consoleCommandAnimationReload()
	for _, v93_ in ipairs(self.npcs) do
		if v93_.playerGraphics ~= nil then
			v93_.playerGraphics:loadAnimation()
		end
	end
	return "Reloaded animation"
end

function NPCManager:consoleCommandAnimationDebug()
	NPCManager.DEBUG_ANIMATIONS = not NPCManager.DEBUG_ANIMATIONS
	return string.format("Animation debug: %s", NPCManager.DEBUG_ANIMATIONS)
end

-- Local values: _, npc, conversation
function NPCManager:consoleCommandSetNextConversation(npcName, conversationUniqueId)
	for _, v97_ in ipairs(self.npcs) do
		if string.upper(npcName) == v97_.name then
			local v98_ = v97_:getConversationById(conversationUniqueId)
			if v98_ == nil then
				return string.format("Conversation \'%s\' not defined for NPC \'%s\'", conversationUniqueId, npcName)
			end
			v97_:setNextConversation(v98_)
			return "Done"
		end
	end
	return string.format("NPC \'%s\' not found", npcName)
end

-- Local values: doAll, index, _, npc, oldSuffix
function NPCManager:consoleCommandValidate(languageSuffix, npcName)
	local v102_ = languageSuffix == "all"
	if not v102_ then
		languageSuffix = languageSuffix or g_languageSuffix
		if not string.startsWith(languageSuffix, "_") then
			return "Invalid language suffix. Please only use \'_en\', \'_de\' or similar"
		end
	end
	local v103_ = 0
	for _, v104_ in ipairs(self.npcs) do
		if npcName == nil or string.upper(npcName) == v104_.name then
			while true do
				if v102_ then
					v103_ = v103_ + 1
					if getNumOfLanguages() <= v103_ then
						break
					end
					languageSuffix = "_" .. getLanguageCode(v103_)
				end
				local v105_ = g_languageSuffix
				g_languageSuffix = languageSuffix
				NPCText.FALLBACK_TEXT_SUFFIX = languageSuffix
				Logging.info("Start NPC Validation: \'%s\' for language: %s", v104_.xmlFilename, languageSuffix)
				v104_:validate()
				Logging.info("Finished NPC Validation")
				g_languageSuffix = v105_
				NPCText.FALLBACK_TEXT_SUFFIX = "_en"
				if not v102_ then
					break
				end
			end
		end
	end
	return "Finished"
end
g_npcManager = NPCManager.new()
