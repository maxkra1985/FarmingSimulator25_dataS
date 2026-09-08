-- Local values: ConversationPrerequisiteRetriggerDelayIngameDays_mt
ConversationPrerequisiteRetriggerDelayIngameDays = {}
ConversationPrerequisiteRetriggerDelayIngameDays.NAME = "retriggerDelayIngameDays"
local ConversationPrerequisiteRetriggerDelayIngameDays_mt = Class(ConversationPrerequisiteRetriggerDelayIngameDays)

function ConversationPrerequisiteRetriggerDelayIngameDays.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.INT, basePath .. "#minDays", "Min number of ingame days since last occurrence", 0, false)
end

-- Upvalues: ConversationPrerequisiteRetriggerDelayIngameDays_mt
-- Local values: self
function ConversationPrerequisiteRetriggerDelayIngameDays.new(minIngameDays, customMt)
	-- upvalues: (copy) ConversationPrerequisiteRetriggerDelayIngameDays_mt
	local v6_ = customMt or ConversationPrerequisiteRetriggerDelayIngameDays_mt
	local v7_ = setmetatable({}, v6_)
	v7_.minIngameDays = minIngameDays
	return v7_
end

-- Local values: environment, currentMonotonicDay, lastMonotonicDay, difference
function ConversationPrerequisiteRetriggerDelayIngameDays:getIsValid(player, userData)
	if userData ~= nil and userData.lastTriggedMonotonicDay ~= nil then
		local v10_ = g_currentMission.environment.currentMonotonicDay
		local v11_ = userData.lastTriggedMonotonicDay
		if v11_ ~= nil then
			return v10_ - v11_ > self.minIngameDays
		end
	end
	return true
end

-- Local values: minIngameDays
function ConversationPrerequisiteRetriggerDelayIngameDays.createFromXML(xmlFile, key, conversation, baseDirectory, customEnvironment)
	local v14_ = xmlFile:getValue(key .. "#minDays", 0)
	if v14_ >= 0 then
		return ConversationPrerequisiteRetriggerDelayIngameDays.new(v14_)
	end
	Logging.xmlWarning(xmlFile, "Min number of ingame days may not be smaller than 0 for \'%s\'", key)
	return nil
end
g_npcManager:registerConversationPrerequisiteClass(ConversationPrerequisiteRetriggerDelayIngameDays.NAME, ConversationPrerequisiteRetriggerDelayIngameDays)
