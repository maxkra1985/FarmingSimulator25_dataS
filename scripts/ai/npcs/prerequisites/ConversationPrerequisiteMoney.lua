ConversationPrerequisiteMoney = {}
ConversationPrerequisiteMoney.NAME = "money"
local ConversationPrerequisiteMoney_mt = Class(ConversationPrerequisiteMoney)
function ConversationPrerequisiteMoney.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.INT, basePath .. "#min", "Min money", 0, false)
	schema:register(XMLValueType.INT, basePath .. "#max", "Max money", 9999999999, false)
end
function ConversationPrerequisiteMoney.new(minMoney, maxMoney, customMt)
	local self = setmetatable({}, customMt or ConversationPrerequisiteMoney_mt)
	self.minMoney = minMoney
	self.maxMoney = maxMoney
	return self
end
function ConversationPrerequisiteMoney:getIsValid(player, userData)
	if player == nil then
		return false
	end
	local farm = g_farmManager:getFarmByUserId(player.userId)
	if farm == nil then
		return false
	end
	local money = farm:getBalance()
	if MathUtil.getIsOutOfBounds(money, self.minMoney, self.maxMoney) then
		return false
	else
		return true
	end
end
function ConversationPrerequisiteMoney.createFromXML(xmlFile, key, conversation, baseDirectory, customEnvironment)
	local minMoney = xmlFile:getValue(key .. "#min", 0)
	local maxMoney = xmlFile:getValue(key .. "#max", math.huge)
	return ConversationPrerequisiteMoney.new(minMoney, maxMoney)
end
g_npcManager:registerConversationPrerequisiteClass(ConversationPrerequisiteMoney.NAME, ConversationPrerequisiteMoney)
