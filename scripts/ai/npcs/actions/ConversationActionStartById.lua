-- Local values: ConversationActionStartById_mt
ConversationActionStartById = {}
ConversationActionStartById.NAME = "startConversationById"
local ConversationActionStartById_mt = Class(ConversationActionStartById)

function ConversationActionStartById.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. "#uniqueId", "Unique id of the conversation", nil, true)
end

-- Upvalues: ConversationActionStartById_mt
-- Local values: self
function ConversationActionStartById.new(conversation, uniqueId, customMt)
	-- upvalues: (copy) ConversationActionStartById_mt
	local v7_ = customMt or ConversationActionStartById_mt
	local v8_ = setmetatable({}, v7_)
	v8_.conversation = conversation
	v8_.uniqueId = uniqueId
	return v8_
end

-- Local values: npc, conversation
function ConversationActionStartById:run()
	local v10_ = self.conversation:getNPC()
	if v10_ == nil then
		Logging.error("ConversationActionStartById.run: No NPC set!")
		return false
	else
		local v11_ = v10_:getConversationById(self.uniqueId)
		if v11_ == nil then
			Logging.error("ConversationActionStartById.run: No conversation with unique id \'%s\' defined for npc \'%s\'!", self.uniqueId, v10_:getName())
			return false
		else
			if g_server ~= nil then
				v10_:setFollowUpConversation(v11_)
			end
			return true
		end
	end
end

-- Local values: uniqueId
function ConversationActionStartById.createFromXML(xmlFile, key, conversation, baseDirectory, customEnvironment)
	local v15_ = xmlFile:getValue(key .. "#uniqueId")
	if v15_ ~= nil then
		return ConversationActionStartById.new(conversation, v15_)
	end
	Logging.xmlWarning(xmlFile, "Missing \'uniqueId\' for \'%s\'", key)
	return nil
end
g_npcManager:registerConversationActionClass(ConversationActionStartById.NAME, ConversationActionStartById)
