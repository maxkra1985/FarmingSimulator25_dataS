-- Local values: ConversationPrerequisiteSeasonPeriod_mt
ConversationPrerequisiteSeasonPeriod = {}
ConversationPrerequisiteSeasonPeriod.NAME = "seasonPeriod"
local ConversationPrerequisiteSeasonPeriod_mt = Class(ConversationPrerequisiteSeasonPeriod)

function ConversationPrerequisiteSeasonPeriod.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. "#min", "Name of the min season period", "EARLY_SPRING", false)
	schema:register(XMLValueType.STRING, basePath .. "#max", "Name of the max season period", "LATE_WINTER", false)
end

-- Upvalues: ConversationPrerequisiteSeasonPeriod_mt
-- Local values: self
function ConversationPrerequisiteSeasonPeriod.new(minSeasonPeriod, maxSeasonPeriod, customMt)
	-- upvalues: (copy) ConversationPrerequisiteSeasonPeriod_mt
	local v7_ = customMt or ConversationPrerequisiteSeasonPeriod_mt
	local v8_ = setmetatable({}, v7_)
	v8_.minSeasonPeriod = minSeasonPeriod
	v8_.maxSeasonPeriod = maxSeasonPeriod
	return v8_
end

-- Local values: environment
function ConversationPrerequisiteSeasonPeriod:getIsValid(player, userData)
	local v10_ = g_currentMission.environment
	return not MathUtil.getIsOutOfBounds(v10_.currentPeriod, self.minSeasonPeriod, self.maxSeasonPeriod)
end

-- Local values: minSeasonPeriodStr, minSeasonPeriod, maxSeasonPeriodStr, maxSeasonPeriod
function ConversationPrerequisiteSeasonPeriod.createFromXML(xmlFile, key, conversation, baseDirectory, customEnvironment)
	local v13_ = xmlFile:getValue(key .. "#min", "EARLY_SPRING")
	local v14_ = SeasonPeriod.getByName(v13_)
	if v14_ == nil then
		Logging.xmlWarning(xmlFile, "SeasonPeriod min-value \'%s\' is not defined for \'%s\'. Set to EARLY_SPRING.", v13_, key .. "#min")
		return nil
	end
	local v15_ = xmlFile:getValue(key .. "#max", "LATE_WINTER")
	local v16_ = SeasonPeriod.getByName(v15_)
	if v16_ ~= nil then
		return ConversationPrerequisiteSeasonPeriod.new(v14_, v16_)
	end
	Logging.xmlWarning(xmlFile, "SeasonPeriod max-value \'%s\' is not defined for \'%s\'. Set to LATE_WINTER.", v15_, key .. "#max")
	return nil
end
g_npcManager:registerConversationPrerequisiteClass(ConversationPrerequisiteSeasonPeriod.NAME, ConversationPrerequisiteSeasonPeriod)
