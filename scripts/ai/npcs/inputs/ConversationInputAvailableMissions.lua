-- Local values: ConversationInputAvailableMissions_mt
ConversationInputAvailableMissions = {}
ConversationInputAvailableMissions.NAME = "availableMissions"
local ConversationInputAvailableMissions_mt = Class(ConversationInputAvailableMissions)

function ConversationInputAvailableMissions.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath, "", nil, true)
end

-- Upvalues: ConversationInputAvailableMissions_mt
-- Local values: self
function ConversationInputAvailableMissions.new(conversation, customMt)
	-- upvalues: (copy) ConversationInputAvailableMissions_mt
	local v6_ = customMt or ConversationInputAvailableMissions_mt
	local v7_ = setmetatable({}, v6_)
	v7_.conversation = conversation
	return v7_
end

function ConversationInputAvailableMissions:run()
	return true
end

function ConversationInputAvailableMissions.createFromXML(xmlFile, key, conversation, baseDirectory, customEnvironment)
	return ConversationInputAvailableMissions.new(conversation)
end
g_npcManager:registerConversationInputClass(ConversationInputAvailableMissions.NAME, ConversationInputAvailableMissions)
