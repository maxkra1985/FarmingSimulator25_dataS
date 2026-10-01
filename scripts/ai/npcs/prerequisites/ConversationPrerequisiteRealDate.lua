ConversationPrerequisiteRealDate = {}
ConversationPrerequisiteRealDate.NAME = "realDate"
local ConversationPrerequisiteRealDate_mt = Class(ConversationPrerequisiteRealDate)
function ConversationPrerequisiteRealDate.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.INT, basePath .. "#year", "Real date year", 0, false)
	schema:register(XMLValueType.INT, basePath .. "#month", "Real date month", 0, false)
	schema:register(XMLValueType.INT, basePath .. "#day", "Real date day", 0, false)
end
function ConversationPrerequisiteRealDate.new(year, month, day, customMt)
	local self = setmetatable({}, customMt or ConversationPrerequisiteRealDate_mt)
	self.year = year
	self.month = month
	self.day = day
	return self
end
function ConversationPrerequisiteRealDate:getIsValid(player, userData)
	local yearCur, monthCur, dayCur = string.match(getDate("%Y/%m/%d"), "(%d+)/(%d+)/(%d+)")
	yearCur = tonumber(yearCur)
	monthCur = tonumber(monthCur)
	dayCur = tonumber(dayCur)
	if 0 < self.year and self.year ~= yearCur then
		return false
	end
	if 0 < self.month and self.month ~= monthCur then
		return false
	end
	if 0 < self.day and self.day ~= dayCur then
		return false
	end
	return true
end
function ConversationPrerequisiteRealDate.createFromXML(xmlFile, key, conversation, baseDirectory, customEnvironment)
	local year = xmlFile:getValue(key .. "#year", 0)
	if year < 0 then
		Logging.xmlWarning(xmlFile, "'year' out of range [0: every year, 2024-XXXX] for '%s'", year)
		return nil
	else
		local month = xmlFile:getValue(key .. "#month", 0)
		if month < 0 or 12 < month then
			Logging.xmlWarning(xmlFile, "'month' out of range [0: every month, 1-12] for '%s'", month)
			return nil
		end
		local day = xmlFile:getValue(key .. "#day", 0)
		if day < 0 or 31 < day then
			Logging.xmlWarning(xmlFile, "'day' out of range [0: every day, 1-31] for '%s'", month)
			return nil
		end
		return ConversationPrerequisiteRealDate.new(year, month, day)
	end
end
g_npcManager:registerConversationPrerequisiteClass(ConversationPrerequisiteRealDate.NAME, ConversationPrerequisiteRealDate)
