-- Local values: ConversationActionStartFromList_mt
ConversationActionStartFromList = {}
ConversationActionStartFromList.NAME = "startConversationFromList"
local ConversationActionStartFromList_mt = Class(ConversationActionStartFromList)

function ConversationActionStartFromList.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. ".conversation(?)#uniqueId", "Unique id of the conversation", nil, true)
	schema:register(XMLValueType.STRING, basePath .. ".failConversation(?)#uniqueId", "Unique id of the fail conversation", nil, true)
end

-- Upvalues: ConversationActionStartFromList_mt
-- Local values: self
function ConversationActionStartFromList.new(conversation, uniqueIds, failUniqueIds, customMt)
	-- upvalues: (copy) ConversationActionStartFromList_mt
	local v8_ = customMt or ConversationActionStartFromList_mt
	local v9_ = setmetatable({}, v8_)
	v9_.conversation = conversation
	v9_.uniqueIds = uniqueIds
	v9_.failUniqueIds = failUniqueIds
	return v9_
end

-- Local values: npc, player, conversation
function ConversationActionStartFromList:run()
	local v11_ = self.conversation:getNPC()
	if v11_ == nil then
		Logging.error("ConversationActionStartFromList.run: No NPC set!")
		return false
	else
		local v12_ = v11_:getInteractingPlayer()
		if v12_ == nil then
			Logging.error("ConversationActionStartFromList.run: No player set!")
			return false
		else
			local v13_ = v11_:getRandomConversationFromUniqueIds(v12_, self.uniqueIds)
			if v13_ == nil then
				v13_ = v11_:getRandomConversationFromUniqueIds(v12_, self.failUniqueIds)
			end
			if v13_ == nil then
				Logging.error("ConversationActionStartFromList.run: No conversation currently available for npc \'%s\'!", v11_:getName())
				return false
			else
				if g_server ~= nil then
					v11_:setFollowUpConversation(v13_)
				end
				return true
			end
		end
	end
end

-- Local values: uniqueIds, _, conversationKey, uniqueId, failUniqueIds, _, conversationKey, uniqueId
function ConversationActionStartFromList.createFromXML(xmlFile, key, conversation, baseDirectory, customEnvironment)
	local v17_ = {}
	for _, v18_ in xmlFile:iterator(key .. ".conversation") do
		local v19_ = xmlFile:getValue(v18_ .. "#uniqueId")
		if v19_ == nil then
			Logging.xmlWarning(xmlFile, "Missing \'uniqueId\' for \'%s\'", key)
			return nil
		end
		table.addElement(v17_, v19_)
	end
	if #v17_ == 0 then
		return nil
	end
	local v20_ = {}
	for _, v21_ in xmlFile:iterator(key .. ".failConversation") do
		local v22_ = xmlFile:getValue(v21_ .. "#uniqueId")
		if v22_ == nil then
			Logging.xmlWarning(xmlFile, "Missing \'uniqueId\' for \'%s\'", key)
			return nil
		end
		table.addElement(v20_, v22_)
	end
	return ConversationActionStartFromList.new(conversation, v17_, v20_)
end
g_npcManager:registerConversationActionClass(ConversationActionStartFromList.NAME, ConversationActionStartFromList)
