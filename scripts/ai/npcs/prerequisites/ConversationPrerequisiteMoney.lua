-- Local values: ConversationPrerequisiteMoney_mt
ConversationPrerequisiteMoney = {}
ConversationPrerequisiteMoney.NAME = "money"
local ConversationPrerequisiteMoney_mt = Class(ConversationPrerequisiteMoney)

function ConversationPrerequisiteMoney.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.INT, basePath .. "#min", "Min money", 0, false)
	schema:register(XMLValueType.INT, basePath .. "#max", "Max money", 9999999999, false)
end

-- Upvalues: ConversationPrerequisiteMoney_mt
-- Local values: self
function ConversationPrerequisiteMoney.new(minMoney, maxMoney, customMt)
	-- upvalues: (copy) ConversationPrerequisiteMoney_mt
	local v7_ = customMt or ConversationPrerequisiteMoney_mt
	local v8_ = setmetatable({}, v7_)
	v8_.minMoney = minMoney
	v8_.maxMoney = maxMoney
	return v8_
end

-- Local values: farm, money
function ConversationPrerequisiteMoney:getIsValid(player, userData)
	if player == nil then
		return false
	end
	local v11_ = g_farmManager:getFarmByUserId(player.userId)
	if v11_ == nil then
		return false
	end
	local v12_ = v11_:getBalance()
	return not MathUtil.getIsOutOfBounds(v12_, self.minMoney, self.maxMoney)
end

-- Local values: minMoney, maxMoney
function ConversationPrerequisiteMoney.createFromXML(xmlFile, key, conversation, baseDirectory, customEnvironment)
	local v15_ = xmlFile:getValue(key .. "#min", 0)
	local v16_ = xmlFile:getValue(key .. "#max", math.huge)
	return ConversationPrerequisiteMoney.new(v15_, v16_)
end
g_npcManager:registerConversationPrerequisiteClass(ConversationPrerequisiteMoney.NAME, ConversationPrerequisiteMoney)
