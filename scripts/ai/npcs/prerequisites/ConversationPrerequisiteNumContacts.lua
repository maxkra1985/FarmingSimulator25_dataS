-- Local values: ConversationPrerequisiteNumContacts_mt
ConversationPrerequisiteNumContacts = {}
ConversationPrerequisiteNumContacts.NAME = "numContacts"
local ConversationPrerequisiteNumContacts_mt = Class(ConversationPrerequisiteNumContacts)

function ConversationPrerequisiteNumContacts.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.INT, basePath .. "#min", "Min number of contacts", 0, false)
	schema:register(XMLValueType.INT, basePath .. "#max", "Max number of contacts", 9999999999, false)
end

-- Upvalues: ConversationPrerequisiteNumContacts_mt
-- Local values: self
function ConversationPrerequisiteNumContacts.new(minNumContacts, maxNumContacts, customMt)
	-- upvalues: (copy) ConversationPrerequisiteNumContacts_mt
	local v7_ = customMt or ConversationPrerequisiteNumContacts_mt
	local v8_ = setmetatable({}, v7_)
	v8_.minNumContacts = minNumContacts
	v8_.maxNumContacts = maxNumContacts
	return v8_
end

-- Local values: farm, numFields
function ConversationPrerequisiteNumContacts:getIsValid(player, userData)
	if player == nil then
		return false
	end
	local v11_ = g_farmManager:getFarmByUserId(player.userId)
	if v11_ == nil then
		return false
	end
	local v12_ = g_farmlandManager:getNumOwnedFarmlandIdsByFarmId(v11_.farmId)
	return not MathUtil.getIsOutOfBounds(v12_, self.minNumContacts, self.maxNumContacts)
end

-- Local values: minNumContacts, maxNumContacts
function ConversationPrerequisiteNumContacts.createFromXML(xmlFile, key, conversation, baseDirectory, customEnvironment)
	local v15_ = xmlFile:getValue(key .. "#min", 0)
	local v16_ = xmlFile:getValue(key .. "#max", math.huge)
	return ConversationPrerequisiteNumContacts.new(v15_, v16_)
end
g_npcManager:registerConversationPrerequisiteClass(ConversationPrerequisiteNumContacts.NAME, ConversationPrerequisiteNumContacts)
