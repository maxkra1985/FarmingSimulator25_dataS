-- Local values: ConversationPrerequisiteFirstContact_mt
ConversationPrerequisiteFirstContact = {}
ConversationPrerequisiteFirstContact.NAME = "firstContact"
local ConversationPrerequisiteFirstContact_mt = Class(ConversationPrerequisiteFirstContact)

function ConversationPrerequisiteFirstContact.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath, "If should be played on first contact only", nil, false)
end

-- Upvalues: ConversationPrerequisiteFirstContact_mt
-- Local values: self
function ConversationPrerequisiteFirstContact.new(conversation, customMt)
	-- upvalues: (copy) ConversationPrerequisiteFirstContact_mt
	local v6_ = customMt or ConversationPrerequisiteFirstContact_mt
	local v7_ = setmetatable({}, v6_)
	v7_.conversation = conversation
	return v7_
end

-- Local values: npc
function ConversationPrerequisiteFirstContact:getIsValid(player, userData)
	local v10_ = self.conversation:getNPC()
	if v10_ ~= nil then
		return v10_:getIsFirstContact(player)
	end
	Logging.error("ConversationPrerequisiteFirstContact.run: No NPC set!")
	return false
end

function ConversationPrerequisiteFirstContact.createFromXML(xmlFile, key, conversation, baseDirectory, customEnvironment)
	return ConversationPrerequisiteFirstContact.new(conversation)
end
g_npcManager:registerConversationPrerequisiteClass(ConversationPrerequisiteFirstContact.NAME, ConversationPrerequisiteFirstContact)
