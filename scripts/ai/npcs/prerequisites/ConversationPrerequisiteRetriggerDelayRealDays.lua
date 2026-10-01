ConversationPrerequisiteRetriggerDelayRealDays = {}
ConversationPrerequisiteRetriggerDelayRealDays.NAME = "retriggerDelayRealDays"
local ConversationPrerequisiteRetriggerDelayRealDays_mt = Class(ConversationPrerequisiteRetriggerDelayRealDays)
function ConversationPrerequisiteRetriggerDelayRealDays.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.INT, basePath .. "#minDays", "Min number of real days since last occurrence", 0, false)
end
function ConversationPrerequisiteRetriggerDelayRealDays.new(minRealDays, customMt)
	local self = setmetatable({}, customMt or ConversationPrerequisiteRetriggerDelayRealDays_mt)
	self.minRealDaysSeconds = minRealDays * 24 * 60 * 60
	return self
end
function ConversationPrerequisiteRetriggerDelayRealDays:getIsValid(player, userData)
	if userData ~= nil and userData.lastTriggedDate ~= nil then
		local yearCur, monthCur, dayCur = string.match(getDate("%Y/%m/%d"), "(%d+)/(%d+)/(%d+)")
		yearCur = tonumber(yearCur)
		monthCur = tonumber(monthCur)
		dayCur = tonumber(dayCur)
		local year, month, day = string.match(userData.lastTriggedDate, "(%d+)/(%d+)/(%d+)")
		year = tonumber(year)
		month = tonumber(month)
		day = tonumber(day)
		if year then
			local diffSeconds = math.abs(getDateDiffSeconds(year, month, day, 0, 0, 0, yearCur, monthCur, dayCur, 0, 0, 0))
			if diffSeconds < self.minRealDaysSeconds then
				return false
			end
		end
	end
	return true
end
function ConversationPrerequisiteRetriggerDelayRealDays.createFromXML(xmlFile, key, conversation, baseDirectory, customEnvironment)
	local minRealDays = xmlFile:getValue(key .. "#minDays", 0)
	if minRealDays < 0 then
		Logging.xmlWarning(xmlFile, "Min number of real days may not be smaller than 0 for '%s'", key)
		return nil
	else
		return ConversationPrerequisiteRetriggerDelayRealDays.new(minRealDays)
	end
end
g_npcManager:registerConversationPrerequisiteClass(ConversationPrerequisiteRetriggerDelayRealDays.NAME, ConversationPrerequisiteRetriggerDelayRealDays)
