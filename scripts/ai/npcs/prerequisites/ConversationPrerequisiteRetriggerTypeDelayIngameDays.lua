-- Local values: ConversationPrerequisiteRetriggerTypeDelayIngameDays_mt
ConversationPrerequisiteRetriggerTypeDelayIngameDays = {}
ConversationPrerequisiteRetriggerTypeDelayIngameDays.NAME = "retriggerTypeDelayIngameDays"
local ConversationPrerequisiteRetriggerTypeDelayIngameDays_mt = Class(ConversationPrerequisiteRetriggerTypeDelayIngameDays)

function ConversationPrerequisiteRetriggerTypeDelayIngameDays.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.INT, basePath .. "#minDays", "Min number of ingame days since last occurrence", 0, false)
	NPCConversationType.registerXMLPath(schema, basePath .. "#type", "Type of the conversation", nil, true)
end

-- Upvalues: ConversationPrerequisiteRetriggerTypeDelayIngameDays_mt
-- Local values: self
function ConversationPrerequisiteRetriggerTypeDelayIngameDays.new(conversation, typeId, minIngameDays, customMt)
	-- upvalues: (copy) ConversationPrerequisiteRetriggerTypeDelayIngameDays_mt
	local v8_ = customMt or ConversationPrerequisiteRetriggerTypeDelayIngameDays_mt
	local v9_ = setmetatable({}, v8_)
	v9_.typeId = typeId
	v9_.conversation = conversation
	v9_.minIngameDays = minIngameDays
	return v9_
end

-- Local values: npc, conversations, playerUserData, environment, currentMonotonicDay, wasTriggered, _, conversation, conversationData, lastMonotonicDay, difference
function ConversationPrerequisiteRetriggerTypeDelayIngameDays:getIsValid(player, userData12)
	local v12_ = self.conversation:getNPC()
	if v12_ == nil then
		Logging.error("ConversationPrerequisiteRetriggerTypeDelayIngameDays.run: No NPC set!")
		return false
	end
	local v13_ = v12_.typeToConversations[self.typeId]
	if v13_ == nil then
		Logging.error("ConversationPrerequisiteRetriggerTypeDelayIngameDays.run: No conversations for type defined!")
		return false
	end
	local v14_ = v12_.userData[player:getUniqueUserId()]
	if v14_ == nil then
		return true
	end
	local v15_ = g_currentMission.environment.currentMonotonicDay
	local v16_ = false
	for _, v17_ in ipairs(v13_) do
		local v18_ = v14_.conversations[v17_:getUniqueId()]
		if v18_ ~= nil then
			local v19_ = v18_.lastTriggedMonotonicDay
			if v19_ ~= nil and v15_ - v19_ < self.minIngameDays then
				v16_ = true
				break
			end
		end
	end
	return not v16_
end

-- Local values: minIngameDays, typeId
function ConversationPrerequisiteRetriggerTypeDelayIngameDays.createFromXML(xmlFile, key, conversation, baseDirectory, customEnvironment)
	local v23_ = xmlFile:getValue(key .. "#minDays", 0)
	if v23_ < 0 then
		Logging.xmlWarning(xmlFile, "Min number of ingame days may not be smaller than 0 for \'%s\'", key)
		return nil
	end
	local v24_ = NPCConversationType.loadFromXMLFile(xmlFile, key .. "#type")
	if v24_ ~= nil then
		return ConversationPrerequisiteRetriggerTypeDelayIngameDays.new(conversation, v24_, v23_)
	end
	Logging.xmlWarning(xmlFile, "NPCConversationType not defined for \'%s\'", key)
	return nil
end
g_npcManager:registerConversationPrerequisiteClass(ConversationPrerequisiteRetriggerTypeDelayIngameDays.NAME, ConversationPrerequisiteRetriggerTypeDelayIngameDays)
