-- Local values: ConversationPrerequisiteRealDate_mt
ConversationPrerequisiteRealDate = {}
ConversationPrerequisiteRealDate.NAME = "realDate"
local ConversationPrerequisiteRealDate_mt = Class(ConversationPrerequisiteRealDate)

function ConversationPrerequisiteRealDate.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.INT, basePath .. "#year", "Real date year", 0, false)
	schema:register(XMLValueType.INT, basePath .. "#month", "Real date month", 0, false)
	schema:register(XMLValueType.INT, basePath .. "#day", "Real date day", 0, false)
end

-- Upvalues: ConversationPrerequisiteRealDate_mt
-- Local values: self
function ConversationPrerequisiteRealDate.new(year, month, day, customMt)
	-- upvalues: (copy) ConversationPrerequisiteRealDate_mt
	local v8_ = customMt or ConversationPrerequisiteRealDate_mt
	local v9_ = setmetatable({}, v8_)
	v9_.year = year
	v9_.month = month
	v9_.day = day
	return v9_
end

-- Local values: yearCur, monthCur, dayCur
function ConversationPrerequisiteRealDate:getIsValid(player, userData)
	local v11_, v12_, v13_ = string.match(getDate("%Y/%m/%d"), "(%d+)/(%d+)/(%d+)")
	local v14_ = tonumber(v11_)
	local v15_ = tonumber(v12_)
	local v16_ = tonumber(v13_)
	if self.year > 0 and self.year ~= v14_ then
		return false
	elseif self.month > 0 and self.month ~= v15_ then
		return false
	else
		return self.day <= 0 or self.day == v16_
	end
end

-- Local values: year, month, day
function ConversationPrerequisiteRealDate.createFromXML(xmlFile, key, conversation, baseDirectory, customEnvironment)
	local v19_ = xmlFile:getValue(key .. "#year", 0)
	if v19_ < 0 then
		Logging.xmlWarning(xmlFile, "\'year\' out of range [0: every year, 2024-XXXX] for \'%s\'", v19_)
		return nil
	end
	local v20_ = xmlFile:getValue(key .. "#month", 0)
	if v20_ < 0 or v20_ > 12 then
		Logging.xmlWarning(xmlFile, "\'month\' out of range [0: every month, 1-12] for \'%s\'", v20_)
		return nil
	end
	local v21_ = xmlFile:getValue(key .. "#day", 0)
	if v21_ >= 0 and v21_ <= 31 then
		return ConversationPrerequisiteRealDate.new(v19_, v20_, v21_)
	end
	Logging.xmlWarning(xmlFile, "\'day\' out of range [0: every day, 1-31] for \'%s\'", v20_)
	return nil
end
g_npcManager:registerConversationPrerequisiteClass(ConversationPrerequisiteRealDate.NAME, ConversationPrerequisiteRealDate)
