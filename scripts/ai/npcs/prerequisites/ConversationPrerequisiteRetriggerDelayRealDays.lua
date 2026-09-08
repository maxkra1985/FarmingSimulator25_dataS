-- Local values: ConversationPrerequisiteRetriggerDelayRealDays_mt
ConversationPrerequisiteRetriggerDelayRealDays = {}
ConversationPrerequisiteRetriggerDelayRealDays.NAME = "retriggerDelayRealDays"
local ConversationPrerequisiteRetriggerDelayRealDays_mt = Class(ConversationPrerequisiteRetriggerDelayRealDays)

function ConversationPrerequisiteRetriggerDelayRealDays.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.INT, basePath .. "#minDays", "Min number of real days since last occurrence", 0, false)
end

-- Upvalues: ConversationPrerequisiteRetriggerDelayRealDays_mt
-- Local values: self
function ConversationPrerequisiteRetriggerDelayRealDays.new(minRealDays, customMt)
	-- upvalues: (copy) ConversationPrerequisiteRetriggerDelayRealDays_mt
	local v6_ = customMt or ConversationPrerequisiteRetriggerDelayRealDays_mt
	local v7_ = setmetatable({}, v6_)
	v7_.minRealDaysSeconds = minRealDays * 24 * 60 * 60
	return v7_
end

-- Local values: yearCur, monthCur, dayCur, year, month, day, diffSeconds
function ConversationPrerequisiteRetriggerDelayRealDays:getIsValid(player, userData)
	if userData ~= nil and userData.lastTriggedDate ~= nil then
		local v10_, v11_, v12_ = string.match(getDate("%Y/%m/%d"), "(%d+)/(%d+)/(%d+)")
		local v13_ = tonumber(v10_)
		local v14_ = tonumber(v11_)
		local v15_ = tonumber(v12_)
		local v16_, v17_, v18_ = string.match(userData.lastTriggedDate, "(%d+)/(%d+)/(%d+)")
		local v19_ = tonumber(v16_)
		local v20_ = tonumber(v17_)
		local v21_ = tonumber(v18_)
		if v19_ then
			local v22_ = getDateDiffSeconds(v19_, v20_, v21_, 0, 0, 0, v13_, v14_, v15_, 0, 0, 0)
			if math.abs(v22_) < self.minRealDaysSeconds then
				return false
			end
		end
	end
	return true
end

-- Local values: minRealDays
function ConversationPrerequisiteRetriggerDelayRealDays.createFromXML(xmlFile, key, conversation, baseDirectory, customEnvironment)
	local v25_ = xmlFile:getValue(key .. "#minDays", 0)
	if v25_ >= 0 then
		return ConversationPrerequisiteRetriggerDelayRealDays.new(v25_)
	end
	Logging.xmlWarning(xmlFile, "Min number of real days may not be smaller than 0 for \'%s\'", key)
	return nil
end
g_npcManager:registerConversationPrerequisiteClass(ConversationPrerequisiteRetriggerDelayRealDays.NAME, ConversationPrerequisiteRetriggerDelayRealDays)
