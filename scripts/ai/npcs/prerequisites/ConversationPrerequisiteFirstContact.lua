ConversationPrerequisiteFirstContact = {}
ConversationPrerequisiteFirstContact.NAME = "firstContact"
local ConversationPrerequisiteFirstContact_mt = Class(ConversationPrerequisiteFirstContact)
function ConversationPrerequisiteFirstContact.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath, "If should be played on first contact only", nil, false)
end
function ConversationPrerequisiteFirstContact.new(conversation, customMt)
	local self = setmetatable({}, customMt or ConversationPrerequisiteFirstContact_mt)
	self.conversation = conversation
	return self
end
function ConversationPrerequisiteFirstContact:getIsValid(player, userData)
	local npc = self.conversation:getNPC()
	if npc == nil then
		Logging.error("ConversationPrerequisiteFirstContact.run: No NPC set!")
		return false
	else
		return npc:getIsFirstContact(player)
	end
end
function ConversationPrerequisiteFirstContact.createFromXML(xmlFile, key, conversation, baseDirectory, customEnvironment)
	return ConversationPrerequisiteFirstContact.new(conversation)
end
g_npcManager:registerConversationPrerequisiteClass(ConversationPrerequisiteFirstContact.NAME, ConversationPrerequisiteFirstContact)
