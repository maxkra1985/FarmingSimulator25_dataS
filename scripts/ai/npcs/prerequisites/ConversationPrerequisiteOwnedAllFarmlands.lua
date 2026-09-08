-- Local values: ConversationPrerequisiteOwnedAllFarmlands_mt
ConversationPrerequisiteOwnedAllFarmlands = {}
ConversationPrerequisiteOwnedAllFarmlands.NAME = "ownedAllFarmlands"
local ConversationPrerequisiteOwnedAllFarmlands_mt = Class(ConversationPrerequisiteOwnedAllFarmlands)

function ConversationPrerequisiteOwnedAllFarmlands.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath, "If should be played if all farmlands are owned", nil, false)
end

-- Upvalues: ConversationPrerequisiteOwnedAllFarmlands_mt
-- Local values: self
function ConversationPrerequisiteOwnedAllFarmlands.new(customMt)
	-- upvalues: (copy) ConversationPrerequisiteOwnedAllFarmlands_mt
	local v5_ = customMt or ConversationPrerequisiteOwnedAllFarmlands_mt
	return setmetatable({}, v5_)
end

-- Local values: farm, farmId, numFarmlands, totalNumFarmlands
function ConversationPrerequisiteOwnedAllFarmlands:getIsValid(player, userData)
	if player == nil then
		return false
	end
	local v7_ = g_farmManager:getFarmByUserId(player.userId)
	if v7_ == nil then
		return false
	end
	local v8_ = v7_.farmid
	return g_farmlandManager:getNumOwnedFarmlandIdsByFarmId(v8_) == #g_farmlandManager:getFarmlands()
end

function ConversationPrerequisiteOwnedAllFarmlands.createFromXML(xmlFile, key, conversation, baseDirectory, customEnvironment)
	return ConversationPrerequisiteOwnedAllFarmlands.new()
end
g_npcManager:registerConversationPrerequisiteClass(ConversationPrerequisiteOwnedAllFarmlands.NAME, ConversationPrerequisiteOwnedAllFarmlands)
