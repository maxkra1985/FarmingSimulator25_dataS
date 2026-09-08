-- Local values: ConversationPrerequisiteNumOwnedFarmlands_mt
ConversationPrerequisiteNumOwnedFarmlands = {}
ConversationPrerequisiteNumOwnedFarmlands.NAME = "numOwnedFarmlands"
local ConversationPrerequisiteNumOwnedFarmlands_mt = Class(ConversationPrerequisiteNumOwnedFarmlands)

function ConversationPrerequisiteNumOwnedFarmlands.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.INT, basePath .. "#min", "Min number of owned farmlands", 0, false)
	schema:register(XMLValueType.INT, basePath .. "#max", "Max number of owned farmlands", 9999999999, false)
end

-- Upvalues: ConversationPrerequisiteNumOwnedFarmlands_mt
-- Local values: self
function ConversationPrerequisiteNumOwnedFarmlands.new(minNumOwnedFarmlands, maxNumOwnedFarmlands, customMt)
	-- upvalues: (copy) ConversationPrerequisiteNumOwnedFarmlands_mt
	local v7_ = customMt or ConversationPrerequisiteNumOwnedFarmlands_mt
	local v8_ = setmetatable({}, v7_)
	v8_.minNumOwnedFarmlands = minNumOwnedFarmlands
	v8_.maxNumOwnedFarmlands = maxNumOwnedFarmlands
	return v8_
end

-- Local values: farm, farmId, numFields
function ConversationPrerequisiteNumOwnedFarmlands:getIsValid(player, userData)
	if player == nil then
		return false
	end
	local v11_ = g_farmManager:getFarmByUserId(player.userId)
	if v11_ == nil then
		return false
	end
	local v12_ = v11_.farmId
	local v13_ = g_farmlandManager:getNumOwnedFarmlandIdsByFarmId(v12_)
	return not MathUtil.getIsOutOfBounds(v13_, self.minNumOwnedFarmlands, self.maxNumOwnedFarmlands)
end

-- Local values: minNumOwnedFarmlands, maxNumOwnedFarmlands
function ConversationPrerequisiteNumOwnedFarmlands.createFromXML(xmlFile, key, conversation, baseDirectory, customEnvironment)
	local v16_ = xmlFile:getValue(key .. "#min", 0)
	local v17_ = xmlFile:getValue(key .. "#max", math.huge)
	return ConversationPrerequisiteNumOwnedFarmlands.new(v16_, v17_)
end
g_npcManager:registerConversationPrerequisiteClass(ConversationPrerequisiteNumOwnedFarmlands.NAME, ConversationPrerequisiteNumOwnedFarmlands)
