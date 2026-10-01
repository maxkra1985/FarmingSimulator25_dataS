ConversationPrerequisiteRealTime = {}
ConversationPrerequisiteRealTime.NAME = "realTime"
local ConversationPrerequisiteRealTime_mt = Class(ConversationPrerequisiteRealTime)
function ConversationPrerequisiteRealTime.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.FLOAT, basePath .. "#minHour", "Real time min hour", 0, false)
	schema:register(XMLValueType.FLOAT, basePath .. "#maxHour", "Real time max hour", 24, false)
end
function ConversationPrerequisiteRealTime.new(minHour, maxHour, customMt)
	local self = setmetatable({}, customMt or ConversationPrerequisiteRealTime_mt)
	self.minHourMinutes = minHour * 60
	self.maxHourMinutes = maxHour * 60
	return self
end
function ConversationPrerequisiteRealTime:getIsValid(player, userData)
	local hours = tonumber(getDate("%H"))
	local minutes = tonumber(getDate("%M"))
	local timeMinutes = hours * 60 + minutes
	if MathUtil.getIsOutOfBounds(timeMinutes, self.minHourMinutes, self.maxHourMinutes) then
		return false
	else
		return true
	end
end
function ConversationPrerequisiteRealTime.createFromXML(xmlFile, key, conversation, baseDirectory, customEnvironment)
	local minHour = xmlFile:getValue(key .. "#minHour", 0)
	if minHour < 0 or 24 < minHour then
		Logging.xmlWarning(xmlFile, "minHour '%.2f' is out of range (0-24) for '%s'", minHour, key .. "#minHour")
		return nil
	end
	local maxHour = xmlFile:getValue(key .. "#maxHour", 24)
	if maxHour < 0 or 24 < maxHour then
		Logging.xmlWarning(xmlFile, "maxHour '%.2f' is out of range (0-24) for '%s'", maxHour, key .. "#maxHour")
		return nil
	end
	return ConversationPrerequisiteRealTime.new(minHour, maxHour)
end
g_npcManager:registerConversationPrerequisiteClass(ConversationPrerequisiteRealTime.NAME, ConversationPrerequisiteRealTime)
