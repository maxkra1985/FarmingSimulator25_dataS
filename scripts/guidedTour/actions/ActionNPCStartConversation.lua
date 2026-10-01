ActionNPCStartConversation = {}
ActionNPCStartConversation.NAME = "npcStartConversation"
local ActionNPCStartConversation_mt = Class(ActionNPCStartConversation)
function ActionNPCStartConversation.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. "#npc", "Name of the npc", nil, true)
	schema:register(XMLValueType.STRING, basePath, "Filename of the conversation", nil, true)
	schema:register(XMLValueType.BOOL, basePath .. "#isPhoneConversation", "If the conversation should is a phone conversation", nil, false)
end
function ActionNPCStartConversation.new(npcName, filename, isPhoneConversation, customMt)
	local self = setmetatable({}, customMt or ActionNPCStartConversation_mt)
	self.npcName = npcName
	self.filename = filename
	self.isPhoneConversation = isPhoneConversation
	return self
end
function ActionNPCStartConversation:run(tour, step)
	local npc = g_npcManager:getNPCByName(self.npcName)
	if npc == nil then
		Logging.warning("ActionNPCStartConversation.run: NPC '%s' not found", self.npcName)
		return false
	end
	local conversation = npc:getConversationByFilename(self.filename)
	if conversation == nil then
		Logging.warning("ActionNPCStartConversation.run: Conversation '%s' not defined for NPC '%s'", self.filename, self.npcName)
		return false
	else
		npc:startConversation(g_localPlayer, conversation, true, self.isPhoneConversation)
		return true
	end
end
function ActionNPCStartConversation.createFromXML(xmlFile, key, baseDirectory, customEnvironment)
	local npcName = xmlFile:getValue(key .. "#npc")
	local filename = xmlFile:getValue(key)
	local isPhoneConversation = xmlFile:getValue(key .. "#isPhoneConversation", true)
	if npcName ~= nil and filename ~= nil then
		return ActionNPCStartConversation.new(npcName, filename, isPhoneConversation)
	end
	return nil
end
g_guidedTourManager:registerActionClass(ActionNPCStartConversation.NAME, ActionNPCStartConversation)
