ConversationPrerequisiteRetriggerDelayIngameDays = {}
ConversationPrerequisiteRetriggerDelayIngameDays.NAME = "retriggerDelayIngameDays"
local ConversationPrerequisiteRetriggerDelayIngameDays_mt = Class(ConversationPrerequisiteRetriggerDelayIngameDays)
function ConversationPrerequisiteRetriggerDelayIngameDays.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.INT, basePath .. "#minDays", "Min number of ingame days since last occurrence", 0, false)
end
function ConversationPrerequisiteRetriggerDelayIngameDays.new(minIngameDays, customMt)
	local self = setmetatable({}, customMt or ConversationPrerequisiteRetriggerDelayIngameDays_mt)
	self.minIngameDays = minIngameDays
	return self
end
function ConversationPrerequisiteRetriggerDelayIngameDays:getIsValid(player, userData)
	if userData ~= nil and userData.lastTriggedMonotonicDay ~= nil then
		local environment = g_currentMission.environment
		local currentMonotonicDay = environment.currentMonotonicDay
		local lastMonotonicDay = userData.lastTriggedMonotonicDay
		if lastMonotonicDay ~= nil then
			local difference = currentMonotonicDay - lastMonotonicDay
			return self.minIngameDays < difference
		end
	end
	return true
end
function ConversationPrerequisiteRetriggerDelayIngameDays.createFromXML(xmlFile, key, conversation, baseDirectory, customEnvironment)
	local minIngameDays = xmlFile:getValue(key .. "#minDays", 0)
	if minIngameDays < 0 then
		Logging.xmlWarning(xmlFile, "Min number of ingame days may not be smaller than 0 for '%s'", key)
		return nil
	else
		return ConversationPrerequisiteRetriggerDelayIngameDays.new(minIngameDays)
	end
end
g_npcManager:registerConversationPrerequisiteClass(ConversationPrerequisiteRetriggerDelayIngameDays.NAME, ConversationPrerequisiteRetriggerDelayIngameDays)
