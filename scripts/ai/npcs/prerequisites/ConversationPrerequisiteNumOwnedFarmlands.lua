ConversationPrerequisiteNumOwnedFarmlands = {}
ConversationPrerequisiteNumOwnedFarmlands.NAME = "numOwnedFarmlands"
local ConversationPrerequisiteNumOwnedFarmlands_mt = Class(ConversationPrerequisiteNumOwnedFarmlands)
function ConversationPrerequisiteNumOwnedFarmlands.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.INT, basePath .. "#min", "Min number of owned farmlands", 0, false)
	schema:register(XMLValueType.INT, basePath .. "#max", "Max number of owned farmlands", 9999999999, false)
end
function ConversationPrerequisiteNumOwnedFarmlands.new(minNumOwnedFarmlands, maxNumOwnedFarmlands, customMt)
	local self = setmetatable({}, customMt or ConversationPrerequisiteNumOwnedFarmlands_mt)
	self.minNumOwnedFarmlands = minNumOwnedFarmlands
	self.maxNumOwnedFarmlands = maxNumOwnedFarmlands
	return self
end
function ConversationPrerequisiteNumOwnedFarmlands:getIsValid(player, userData)
	if player == nil then
		return false
	end
	local farm = g_farmManager:getFarmByUserId(player.userId)
	if farm == nil then
		return false
	end
	local farmId = farm.farmId
	local numFields = g_farmlandManager:getNumOwnedFarmlandIdsByFarmId(farmId)
	if MathUtil.getIsOutOfBounds(numFields, self.minNumOwnedFarmlands, self.maxNumOwnedFarmlands) then
		return false
	else
		return true
	end
end
function ConversationPrerequisiteNumOwnedFarmlands.createFromXML(xmlFile, key, conversation, baseDirectory, customEnvironment)
	local minNumOwnedFarmlands = xmlFile:getValue(key .. "#min", 0)
	local maxNumOwnedFarmlands = xmlFile:getValue(key .. "#max", math.huge)
	return ConversationPrerequisiteNumOwnedFarmlands.new(minNumOwnedFarmlands, maxNumOwnedFarmlands)
end
g_npcManager:registerConversationPrerequisiteClass(ConversationPrerequisiteNumOwnedFarmlands.NAME, ConversationPrerequisiteNumOwnedFarmlands)
