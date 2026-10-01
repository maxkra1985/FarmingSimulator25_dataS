ConversationActionStartMissionSelection = {}
ConversationActionStartMissionSelection.NAME = "startMissionSelection"
local ConversationActionStartMissionSelection_mt = Class(ConversationActionStartMissionSelection)
function ConversationActionStartMissionSelection.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. "#uniqueIdMissionAvailable", "Unique id of the conversation that should be started if missions are available", nil, true)
	schema:register(XMLValueType.STRING, basePath .. "#uniqueIdMissionUnavailable", "Unique id of the conversation that should be started if no missions are available", nil, true)
end
function ConversationActionStartMissionSelection.new(conversation, uniqueIdMissionAvailable, uniqueIdMissionUnavailable, customMt)
	local self = setmetatable({}, customMt or ConversationActionStartMissionSelection_mt)
	self.conversation = conversation
	self.uniqueIdMissionAvailable = uniqueIdMissionAvailable
	self.uniqueIdMissionUnavailable = uniqueIdMissionUnavailable
	return self
end
function ConversationActionStartMissionSelection:run()
	local npc = self.conversation:getNPC()
	if npc == nil then
		Logging.error("ConversationActionStartMissionSelection.run: No NPC set!")
		return false
	end
	local missionAvailableConversation = npc:getConversationById(self.uniqueIdMissionAvailable)
	if missionAvailableConversation == nil then
		Logging.error("ConversationActionStartMissionSelection.run: No conversation with unique id '%s' defined for npc '%s'!", self.uniqueId, npc:getName())
		return false
	end
	local noMissionConversation = npc:getConversationById(self.uniqueIdMissionUnavailable)
	if noMissionConversation == nil then
		Logging.error("ConversationActionStartMissionSelection.run: No conversation with unique id '%s' defined for npc '%s'!", self.uniqueId, npc:getName())
		return false
	else
		local nextConversation = noMissionConversation
		local missions = g_missionManager:getMissions()
		for _, mission in ipairs(missions) do
			local missionNpc = mission:getNPC()
			local isSameNPC = missionNpc ~= nil and missionNpc == npc
			local isMissionReady = mission:getIsReadyToStart()
			if isSameNPC and isMissionReady then
				nextConversation = missionAvailableConversation
				break
			end
		end
		if g_server ~= nil then
			npc:setFollowUpConversation(nextConversation)
		end
		return true
	end
end
function ConversationActionStartMissionSelection.createFromXML(xmlFile, key, conversation, baseDirectory, customEnvironment)
	local uniqueIdMissionAvailable = xmlFile:getValue(key .. "#uniqueIdMissionAvailable")
	if uniqueIdMissionAvailable == nil then
		Logging.xmlWarning(xmlFile, "Missing 'uniqueIdMissionAvailable' for '%s'", key)
		return nil
	end
	local uniqueIdMissionUnavailable = xmlFile:getValue(key .. "#uniqueIdMissionUnavailable")
	if uniqueIdMissionUnavailable == nil then
		Logging.xmlWarning(xmlFile, "Missing 'uniqueIdMissionUnavailable' for '%s'", key)
		return nil
	else
		return ConversationActionStartMissionSelection.new(conversation, uniqueIdMissionAvailable, uniqueIdMissionUnavailable)
	end
end
g_npcManager:registerConversationActionClass(ConversationActionStartMissionSelection.NAME, ConversationActionStartMissionSelection)
