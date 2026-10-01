ConversationActionStartSelectedMission = {}
ConversationActionStartSelectedMission.NAME = "startSelectedMission"
local ConversationActionStartSelectedMission_mt = Class(ConversationActionStartSelectedMission)
function ConversationActionStartSelectedMission.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath, "", nil, true)
end
function ConversationActionStartSelectedMission.new(conversation, customMt)
	local self = setmetatable({}, customMt or ConversationActionStartSelectedMission_mt)
	self.conversation = conversation
	return self
end
function ConversationActionStartSelectedMission:run()
	if g_server == nil then
		return true
	end
	local npc = self.conversation:getNPC()
	if npc == nil then
		Logging.error("ConversationActionStartSelectedMission.run: No NPC set!")
		return false
	end
	local player = npc:getInteractingPlayer()
	if player == nil then
		Logging.error("ConversationActionStartSelectedMission.run: No player set!")
		return false
	end
	local farm = g_farmManager:getFarmByUserId(player.userId)
	if farm == nil then
		Logging.error("ConversationActionStartSelectedMission.run: Player has no farm!")
		return false
	end
	local farmId = farm:getId()
	if farmId == FarmManager.SPECTATOR_FARM_ID or farmId == FarmManager.INVALID_FARM_ID then
		Logging.error("ConversationActionStartSelectedMission.run: Player has invalid farm id!")
		return false
	end
	local leaseVehicles = npc:getInputData(ConversationInputLeaseVehicles.NAME)
	if leaseVehicles == nil then
		leaseVehicles = false
	end
	local selectedMission = npc:getInputData(ConversationInputSelectedMission.NAME)
	if selectedMission == nil then
		Logging.error("ConversationActionStartSelectedMission.run: No mission selected!")
		return false
	else
		g_client:getServerConnection():sendEvent(MissionStartEvent.new(selectedMission, farmId, leaseVehicles))
		return true
	end
end
function ConversationActionStartSelectedMission.createFromXML(xmlFile, key, conversation, baseDirectory, customEnvironment)
	return ConversationActionStartSelectedMission.new(conversation)
end
g_npcManager:registerConversationActionClass(ConversationActionStartSelectedMission.NAME, ConversationActionStartSelectedMission)
