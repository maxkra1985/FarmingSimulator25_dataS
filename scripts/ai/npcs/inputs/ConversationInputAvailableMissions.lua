ConversationInputAvailableMissions = {}
ConversationInputAvailableMissions.NAME = "availableMissions"
local ConversationInputAvailableMissions_mt = Class(ConversationInputAvailableMissions)
function ConversationInputAvailableMissions.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath, "", nil, true)
end
function ConversationInputAvailableMissions.new(conversation, customMt)
	local self = setmetatable({}, customMt or ConversationInputAvailableMissions_mt)
	self.conversation = conversation
	return self
end
function ConversationInputAvailableMissions:run()
	return true
end
function ConversationInputAvailableMissions.createFromXML(xmlFile, key, conversation, baseDirectory, customEnvironment)
	return ConversationInputAvailableMissions.new(conversation)
end
g_npcManager:registerConversationInputClass(ConversationInputAvailableMissions.NAME, ConversationInputAvailableMissions)
