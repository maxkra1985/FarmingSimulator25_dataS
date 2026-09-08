-- Local values: ConversationPrerequisiteRealTime_mt
ConversationPrerequisiteRealTime = {}
ConversationPrerequisiteRealTime.NAME = "realTime"
local ConversationPrerequisiteRealTime_mt = Class(ConversationPrerequisiteRealTime)

function ConversationPrerequisiteRealTime.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.FLOAT, basePath .. "#minHour", "Real time min hour", 0, false)
	schema:register(XMLValueType.FLOAT, basePath .. "#maxHour", "Real time max hour", 24, false)
end

-- Upvalues: ConversationPrerequisiteRealTime_mt
-- Local values: self
function ConversationPrerequisiteRealTime.new(minHour, maxHour, customMt)
	-- upvalues: (copy) ConversationPrerequisiteRealTime_mt
	local v7_ = customMt or ConversationPrerequisiteRealTime_mt
	local v8_ = setmetatable({}, v7_)
	v8_.minHourMinutes = minHour * 60
	v8_.maxHourMinutes = maxHour * 60
	return v8_
end

-- Local values: hours, minutes, timeMinutes
function ConversationPrerequisiteRealTime:getIsValid(player, userData)
	local v10_ = getDate
	local v11_ = tonumber(v10_("%H"))
	local v12_ = getDate
	local v13_ = tonumber(v12_("%M"))
	local v14_ = v11_ * 60 + v13_
	return not MathUtil.getIsOutOfBounds(v14_, self.minHourMinutes, self.maxHourMinutes)
end

-- Local values: minHour, maxHour
function ConversationPrerequisiteRealTime.createFromXML(xmlFile, key, conversation, baseDirectory, customEnvironment)
	local v17_ = xmlFile:getValue(key .. "#minHour", 0)
	if v17_ < 0 or v17_ > 24 then
		Logging.xmlWarning(xmlFile, "minHour \'%.2f\' is out of range (0-24) for \'%s\'", v17_, key .. "#minHour")
		return nil
	end
	local v18_ = xmlFile:getValue(key .. "#maxHour", 24)
	if v18_ >= 0 and v18_ <= 24 then
		return ConversationPrerequisiteRealTime.new(v17_, v18_)
	end
	Logging.xmlWarning(xmlFile, "maxHour \'%.2f\' is out of range (0-24) for \'%s\'", v18_, key .. "#maxHour")
	return nil
end
g_npcManager:registerConversationPrerequisiteClass(ConversationPrerequisiteRealTime.NAME, ConversationPrerequisiteRealTime)
