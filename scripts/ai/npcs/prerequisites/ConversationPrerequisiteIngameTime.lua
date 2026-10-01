ConversationPrerequisiteIngameTime = {}
ConversationPrerequisiteIngameTime.NAME = "ingameTime"
local ConversationPrerequisiteIngameTime_mt = Class(ConversationPrerequisiteIngameTime)
function ConversationPrerequisiteIngameTime.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.FLOAT, basePath .. "#minHour", "Ingame time min hour", 0, false)
	schema:register(XMLValueType.FLOAT, basePath .. "#maxHour", "Ingame time max hour", 24, false)
end
function ConversationPrerequisiteIngameTime.new(minHour, maxHour, customMt)
	local self = setmetatable({}, customMt or ConversationPrerequisiteIngameTime_mt)
	self.minHourMs = MathUtil.hoursToMs(minHour)
	self.maxHourMs = MathUtil.hoursToMs(maxHour)
	return self
end
function ConversationPrerequisiteIngameTime:getIsValid(player, userData)
	local environment = g_currentMission.environment
	if MathUtil.getIsOutOfBounds(environment.dayTime, self.minHourMs, self.maxHourMs) then
		return false
	else
		return true
	end
end
function ConversationPrerequisiteIngameTime.createFromXML(xmlFile, key, conversation, baseDirectory, customEnvironment)
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
	return ConversationPrerequisiteIngameTime.new(minHour, maxHour)
end
g_npcManager:registerConversationPrerequisiteClass(ConversationPrerequisiteIngameTime.NAME, ConversationPrerequisiteIngameTime)
