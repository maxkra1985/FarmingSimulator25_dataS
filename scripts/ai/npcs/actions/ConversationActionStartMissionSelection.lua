-- Local values: ConversationActionStartMissionSelection_mt
ConversationActionStartMissionSelection = {}
ConversationActionStartMissionSelection.NAME = "startMissionSelection"
local ConversationActionStartMissionSelection_mt = Class(ConversationActionStartMissionSelection)

function ConversationActionStartMissionSelection.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. "#uniqueIdMissionAvailable", "Unique id of the conversation that should be started if missions are available", nil, true)
	schema:register(XMLValueType.STRING, basePath .. "#uniqueIdMissionUnavailable", "Unique id of the conversation that should be started if no missions are available", nil, true)
end

-- Upvalues: ConversationActionStartMissionSelection_mt
-- Local values: self
function ConversationActionStartMissionSelection.new(conversation, uniqueIdMissionAvailable, uniqueIdMissionUnavailable, customMt)
	-- upvalues: (copy) ConversationActionStartMissionSelection_mt
	local v8_ = customMt or ConversationActionStartMissionSelection_mt
	local v9_ = setmetatable({}, v8_)
	v9_.conversation = conversation
	v9_.uniqueIdMissionAvailable = uniqueIdMissionAvailable
	v9_.uniqueIdMissionUnavailable = uniqueIdMissionUnavailable
	return v9_
end

-- Local values: npc, missionAvailableConversation, noMissionConversation, nextConversation, missions, _, mission, missionNpc, isSameNPC, isMissionReady
function ConversationActionStartMissionSelection:run()
	local v11_ = self.conversation:getNPC()
	if v11_ == nil then
		Logging.error("ConversationActionStartMissionSelection.run: No NPC set!")
		return false
	end
	local v12_ = v11_:getConversationById(self.uniqueIdMissionAvailable)
	if v12_ == nil then
		Logging.error("ConversationActionStartMissionSelection.run: No conversation with unique id \'%s\' defined for npc \'%s\'!", self.uniqueId, v11_:getName())
		return false
	end
	local v13_ = v11_:getConversationById(self.uniqueIdMissionUnavailable)
	if v13_ == nil then
		Logging.error("ConversationActionStartMissionSelection.run: No conversation with unique id \'%s\' defined for npc \'%s\'!", self.uniqueId, v11_:getName())
		return false
	end
	local v14_ = g_missionManager:getMissions()
	for _, v15_ in ipairs(v14_) do
		local v16_ = v15_:getNPC()
		local v17_
		if v16_ == nil then
			v17_ = false
		else
			v17_ = v16_ == v11_
		end
		if v17_ and v15_:getIsReadyToStart() then
			v13_ = v12_
			break
		end
	end
	if g_server ~= nil then
		v11_:setFollowUpConversation(v13_)
	end
	return true
end

-- Local values: uniqueIdMissionAvailable, uniqueIdMissionUnavailable
function ConversationActionStartMissionSelection.createFromXML(xmlFile, key, conversation, baseDirectory, customEnvironment)
	local v21_ = xmlFile:getValue(key .. "#uniqueIdMissionAvailable")
	if v21_ == nil then
		Logging.xmlWarning(xmlFile, "Missing \'uniqueIdMissionAvailable\' for \'%s\'", key)
		return nil
	end
	local v22_ = xmlFile:getValue(key .. "#uniqueIdMissionUnavailable")
	if v22_ ~= nil then
		return ConversationActionStartMissionSelection.new(conversation, v21_, v22_)
	end
	Logging.xmlWarning(xmlFile, "Missing \'uniqueIdMissionUnavailable\' for \'%s\'", key)
	return nil
end
g_npcManager:registerConversationActionClass(ConversationActionStartMissionSelection.NAME, ConversationActionStartMissionSelection)
