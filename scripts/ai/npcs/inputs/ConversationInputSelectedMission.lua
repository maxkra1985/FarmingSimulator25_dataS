ConversationInputSelectedMission = {}
ConversationInputSelectedMission.NAME = "selectedMission"
local ConversationInputSelectedMission_mt = Class(ConversationInputSelectedMission)
function ConversationInputSelectedMission.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. "#type", "Mission type", nil, true)
end
function ConversationInputSelectedMission.new(conversation, missionTypeName, customMt)
	local self = setmetatable({}, customMt or ConversationInputSelectedMission_mt)
	self.conversation = conversation
	self.missionTypeName = missionTypeName
	return self
end
function ConversationInputSelectedMission:run()
	local npc = self.conversation:getNPC()
	if npc == nil then
		Logging.error("ConversationInputSelectedMission.run: No NPC set!")
		return false
	end
	local missionType = g_missionManager:getMissionType(self.missionTypeName)
	if missionType == nil then
		Logging.error("ConversationInputSelectedMission.run: Mission type '%s' not defined!", self.missionTypeName)
		return false
	end
	local availableMissions = npc:getInputData(ConversationInputAvailableMissions.NAME)
	if availableMissions == nil then
		Logging.error("ConversationInputSelectedMission.run: No available missions set!")
		return false
	end
	local selectedMission = availableMissions[missionType.typeId]
	if selectedMission == nil then
		Logging.error("ConversationInputSelectedMission.run: No mission of type '%s' available!", self.missionTypeName)
		return false
	else
		npc:setInputData(ConversationInputSelectedMission.NAME, selectedMission)
		return true
	end
end
function ConversationInputSelectedMission.createFromXML(xmlFile, key, conversation, baseDirectory, customEnvironment)
	local missionTypeName = xmlFile:getValue(key .. "#type")
	if missionTypeName == nil then
		Logging.xmlWarning(xmlFile, "Missing type for '%s'", key)
		return nil
	else
		return ConversationInputSelectedMission.new(conversation, missionTypeName)
	end
end
g_npcManager:registerConversationInputClass(ConversationInputSelectedMission.NAME, ConversationInputSelectedMission)
