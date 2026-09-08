-- Local values: ConversationPrerequisiteIngameDaysPlayed_mt
ConversationPrerequisiteIngameDaysPlayed = {}
ConversationPrerequisiteIngameDaysPlayed.NAME = "ingameDaysPlayed"
local ConversationPrerequisiteIngameDaysPlayed_mt = Class(ConversationPrerequisiteIngameDaysPlayed)

function ConversationPrerequisiteIngameDaysPlayed.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.INT, basePath .. "#min", "Min number of ingame days played", 0, false)
	schema:register(XMLValueType.INT, basePath .. "#max", "Max number of ingame days played", 9999999999, false)
end

-- Upvalues: ConversationPrerequisiteIngameDaysPlayed_mt
-- Local values: self
function ConversationPrerequisiteIngameDaysPlayed.new(minIngamePlayedDays, maxIngamePlayedDays, customMt)
	-- upvalues: (copy) ConversationPrerequisiteIngameDaysPlayed_mt
	local v7_ = customMt or ConversationPrerequisiteIngameDaysPlayed_mt
	local v8_ = setmetatable({}, v7_)
	v8_.minIngamePlayedDays = minIngamePlayedDays
	v8_.maxIngamePlayedDays = maxIngamePlayedDays
	return v8_
end

-- Local values: environment, daysPlayed
function ConversationPrerequisiteIngameDaysPlayed:getIsValid(player, userData)
	local v10_ = g_currentMission.environment:getDaysPlayed()
	return not MathUtil.getIsOutOfBounds(v10_, self.minIngamePlayedDays, self.maxIngamePlayedDays)
end

-- Local values: minIngamePlayedDays, maxIngamePlayedDays
function ConversationPrerequisiteIngameDaysPlayed.createFromXML(xmlFile, key, conversation, baseDirectory, customEnvironment)
	local v13_ = xmlFile:getValue(key .. "#min", 0)
	local v14_ = xmlFile:getValue(key .. "#max", math.huge)
	return ConversationPrerequisiteIngameDaysPlayed.new(v13_, v14_)
end
g_npcManager:registerConversationPrerequisiteClass(ConversationPrerequisiteIngameDaysPlayed.NAME, ConversationPrerequisiteIngameDaysPlayed)
