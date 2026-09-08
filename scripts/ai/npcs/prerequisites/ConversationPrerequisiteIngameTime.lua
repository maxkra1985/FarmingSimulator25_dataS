-- Local values: ConversationPrerequisiteIngameTime_mt
ConversationPrerequisiteIngameTime = {}
ConversationPrerequisiteIngameTime.NAME = "ingameTime"
local ConversationPrerequisiteIngameTime_mt = Class(ConversationPrerequisiteIngameTime)

function ConversationPrerequisiteIngameTime.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.FLOAT, basePath .. "#minHour", "Ingame time min hour", 0, false)
	schema:register(XMLValueType.FLOAT, basePath .. "#maxHour", "Ingame time max hour", 24, false)
end

-- Upvalues: ConversationPrerequisiteIngameTime_mt
-- Local values: self
function ConversationPrerequisiteIngameTime.new(minHour, maxHour, customMt)
	-- upvalues: (copy) ConversationPrerequisiteIngameTime_mt
	local v7_ = customMt or ConversationPrerequisiteIngameTime_mt
	local v8_ = setmetatable({}, v7_)
	v8_.minHourMs = MathUtil.hoursToMs(minHour)
	v8_.maxHourMs = MathUtil.hoursToMs(maxHour)
	return v8_
end

-- Local values: environment
function ConversationPrerequisiteIngameTime:getIsValid(player, userData)
	local v10_ = g_currentMission.environment
	return not MathUtil.getIsOutOfBounds(v10_.dayTime, self.minHourMs, self.maxHourMs)
end

-- Local values: minHour, maxHour
function ConversationPrerequisiteIngameTime.createFromXML(xmlFile, key, conversation, baseDirectory, customEnvironment)
	local v13_ = xmlFile:getValue(key .. "#minHour", 0)
	if v13_ < 0 or v13_ > 24 then
		Logging.xmlWarning(xmlFile, "minHour \'%.2f\' is out of range (0-24) for \'%s\'", v13_, key .. "#minHour")
		return nil
	end
	local v14_ = xmlFile:getValue(key .. "#maxHour", 24)
	if v14_ >= 0 and v14_ <= 24 then
		return ConversationPrerequisiteIngameTime.new(v13_, v14_)
	end
	Logging.xmlWarning(xmlFile, "maxHour \'%.2f\' is out of range (0-24) for \'%s\'", v14_, key .. "#maxHour")
	return nil
end
g_npcManager:registerConversationPrerequisiteClass(ConversationPrerequisiteIngameTime.NAME, ConversationPrerequisiteIngameTime)
