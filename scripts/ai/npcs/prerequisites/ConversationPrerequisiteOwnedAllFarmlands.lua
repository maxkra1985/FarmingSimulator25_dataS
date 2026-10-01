ConversationPrerequisiteOwnedAllFarmlands = {}
ConversationPrerequisiteOwnedAllFarmlands.NAME = "ownedAllFarmlands"
local ConversationPrerequisiteOwnedAllFarmlands_mt = Class(ConversationPrerequisiteOwnedAllFarmlands)
function ConversationPrerequisiteOwnedAllFarmlands.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath, "If should be played if all farmlands are owned", nil, false)
end
function ConversationPrerequisiteOwnedAllFarmlands.new(customMt)
	local self = setmetatable({}, customMt or ConversationPrerequisiteOwnedAllFarmlands_mt)
	return self
end
function ConversationPrerequisiteOwnedAllFarmlands:getIsValid(player, userData)
	if player == nil then
		return false
	end
	local farm = g_farmManager:getFarmByUserId(player.userId)
	if farm == nil then
		return false
	end
	local farmId = farm.farmid
	local numFarmlands = g_farmlandManager:getNumOwnedFarmlandIdsByFarmId(farmId)
	local totalNumFarmlands = #g_farmlandManager:getFarmlands()
	if numFarmlands ~= totalNumFarmlands then
		return false
	else
		return true
	end
end
function ConversationPrerequisiteOwnedAllFarmlands.createFromXML(xmlFile, key, conversation, baseDirectory, customEnvironment)
	return ConversationPrerequisiteOwnedAllFarmlands.new()
end
g_npcManager:registerConversationPrerequisiteClass(ConversationPrerequisiteOwnedAllFarmlands.NAME, ConversationPrerequisiteOwnedAllFarmlands)
