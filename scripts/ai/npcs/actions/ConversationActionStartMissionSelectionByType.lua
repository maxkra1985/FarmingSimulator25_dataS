-- Local values: ConversationActionStartMissionSelection_mt
ConversationActionStartMissionSelection = {}
ConversationActionStartMissionSelection.NAME = "startMissionSelectionByType"
local ConversationActionStartMissionSelection_mt = Class(ConversationActionStartMissionSelection)

function ConversationActionStartMissionSelection.registerXMLPaths(schema, basePath)
	NPCConversationType.registerXMLPath(schema, basePath .. "#typeMissionAvailable", "Type of the conversation that should be started if missions are available", nil, true)
	NPCConversationType.registerXMLPath(schema, basePath .. "#typeMissionUnavailable", "Type of the conversation that should be started if no missions are available", nil, true)
end

-- Upvalues: ConversationActionStartMissionSelection_mt
-- Local values: self
function ConversationActionStartMissionSelection.new(conversation, typeMissionAvailable, typeMissionUnavailable, customMt)
	-- upvalues: (copy) ConversationActionStartMissionSelection_mt
	local v8_ = customMt or ConversationActionStartMissionSelection_mt
	local v9_ = setmetatable({}, v8_)
	v9_.conversation = conversation
	v9_.typeMissionAvailable = typeMissionAvailable
	v9_.typeMissionUnavailable = typeMissionUnavailable
	return v9_
end

-- Local values: npc, isMissionReady, missions, _, mission, missionNpc, isSameNPC, player, nextConversation
function ConversationActionStartMissionSelection:run()
	local v11_ = self.conversation:getNPC()
	if v11_ == nil then
		Logging.error("ConversationActionStartMissionSelection.run: No NPC set!")
		return false
	end
	local v12_ = g_missionManager:getMissions()
	local v13_ = false
	for _, v14_ in ipairs(v12_) do
		local v15_ = v14_:getNPC()
		local v16_
		if v15_ == nil then
			v16_ = false
		else
			v16_ = v15_ == v11_
		end
		if v16_ and v14_:getIsReadyToStart() then
			v13_ = true
			break
		end
	end
	local v17_ = v11_:getInteractingPlayer()
	if v17_ == nil then
		Logging.error("ConversationActionStartMissionSelection.run: No player set!")
		return false
	end
	local v18_
	if v13_ then
		v18_ = v11_:getRandomConversation(v17_, self.typeMissionAvailable)
		if v18_ == nil then
			Logging.error("ConversationActionStartMissionSelection.run: No conversation available of type \'%s\' for npc \'%s\'!", NPCConversationType.getName(self.typeMissionAvailable), v11_:getName())
			return false
		end
	else
		v18_ = v11_:getRandomConversation(v17_, self.typeMissionUnavailable)
		if v18_ == nil then
			Logging.error("ConversationActionStartMissionSelection.run: No conversation available of type \'%s\' for npc \'%s\'!", NPCConversationType.getName(self.typeMissionUnavailable), v11_:getName())
			return false
		end
	end
	if g_server ~= nil then
		v11_:setFollowUpConversation(v18_)
	end
	return true
end

-- Local values: typeMissionAvailable, typeMissionUnavailable
function ConversationActionStartMissionSelection.createFromXML(xmlFile, key, conversation, baseDirectory, customEnvironment)
	local v22_ = NPCConversationType.loadFromXMLFile(xmlFile, key .. "#typeMissionAvailable")
	if v22_ == nil then
		Logging.xmlWarning(xmlFile, "NPCConversationType not defined for \'%s#typeMissionAvailable\'", key)
		return nil
	end
	local v23_ = NPCConversationType.loadFromXMLFile(xmlFile, key .. "#typeMissionUnavailable")
	if v23_ ~= nil then
		return ConversationActionStartMissionSelection.new(conversation, v22_, v23_)
	end
	Logging.xmlWarning(xmlFile, "NPCConversationType not defined for \'%s#typeMissionUnavailable\'", key)
	return nil
end
g_npcManager:registerConversationActionClass(ConversationActionStartMissionSelection.NAME, ConversationActionStartMissionSelection)
