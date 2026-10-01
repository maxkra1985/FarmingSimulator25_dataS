ConversationPrerequisiteRetriggerTypeDelayIngameDays = {}
ConversationPrerequisiteRetriggerTypeDelayIngameDays.NAME = "retriggerTypeDelayIngameDays"
local ConversationPrerequisiteRetriggerTypeDelayIngameDays_mt = Class(ConversationPrerequisiteRetriggerTypeDelayIngameDays)
function ConversationPrerequisiteRetriggerTypeDelayIngameDays.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.INT, basePath .. "#minDays", "Min number of ingame days since last occurrence", 0, false)
	NPCConversationType.registerXMLPath(schema, basePath .. "#type", "Type of the conversation", nil, true)
end
function ConversationPrerequisiteRetriggerTypeDelayIngameDays.new(conversation, typeId, minIngameDays, customMt)
	local self = setmetatable({}, customMt or ConversationPrerequisiteRetriggerTypeDelayIngameDays_mt)
	self.typeId = typeId
	self.conversation = conversation
	self.minIngameDays = minIngameDays
	return self
end
function ConversationPrerequisiteRetriggerTypeDelayIngameDays:getIsValid(player, userData12)
	local npc = self.conversation:getNPC()
	if npc == nil then
		Logging.error("ConversationPrerequisiteRetriggerTypeDelayIngameDays.run: No NPC set!")
		return false
	end
	local conversations = npc.typeToConversations[self.typeId]
	if conversations == nil then
		Logging.error("ConversationPrerequisiteRetriggerTypeDelayIngameDays.run: No conversations for type defined!")
		return false
	end
	local playerUserData = npc.userData[player:getUniqueUserId()]
	if playerUserData == nil then
		return true
	else
		local environment = g_currentMission.environment
		local currentMonotonicDay = environment.currentMonotonicDay
		local wasTriggered = false
		for _, conversation in ipairs(conversations) do
			local conversationData = playerUserData.conversations[conversation:getUniqueId()]
			if conversationData == nil then
				continue
			end
			local lastMonotonicDay = conversationData.lastTriggedMonotonicDay
			if lastMonotonicDay == nil then
				continue
			end
			local difference = currentMonotonicDay - lastMonotonicDay
			if difference < self.minIngameDays then
				wasTriggered = true
				break
			end
		end
		return not wasTriggered
	end
end
function ConversationPrerequisiteRetriggerTypeDelayIngameDays.createFromXML(xmlFile, key, conversation, baseDirectory, customEnvironment)
	local minIngameDays = xmlFile:getValue(key .. "#minDays", 0)
	if minIngameDays < 0 then
		Logging.xmlWarning(xmlFile, "Min number of ingame days may not be smaller than 0 for '%s'", key)
		return nil
	end
	local typeId = NPCConversationType.loadFromXMLFile(xmlFile, key .. "#type")
	if typeId == nil then
		Logging.xmlWarning(xmlFile, "NPCConversationType not defined for '%s'", key)
		return nil
	else
		return ConversationPrerequisiteRetriggerTypeDelayIngameDays.new(conversation, typeId, minIngameDays)
	end
end
g_npcManager:registerConversationPrerequisiteClass(ConversationPrerequisiteRetriggerTypeDelayIngameDays.NAME, ConversationPrerequisiteRetriggerTypeDelayIngameDays)
