ConversationInputLeaseVehicles = {}
ConversationInputLeaseVehicles.NAME = "leaseVehicles"
local ConversationInputLeaseVehicles_mt = Class(ConversationInputLeaseVehicles)
function ConversationInputLeaseVehicles.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.BOOL, basePath .. "#value", "True if vehicles should be leased, else false", false, false)
end
function ConversationInputLeaseVehicles.new(conversation, doLeaseVehicles, customMt)
	local self = setmetatable({}, customMt or ConversationInputLeaseVehicles_mt)
	self.conversation = conversation
	self.doLeaseVehicles = doLeaseVehicles
	return self
end
function ConversationInputLeaseVehicles:run()
	local npc = self.conversation:getNPC()
	if npc == nil then
		Logging.error("ConversationInputLeaseVehicles.run: No NPC set!")
		return false
	else
		npc:setInputData(ConversationInputLeaseVehicles.NAME, self.doLeaseVehicles)
		return true
	end
end
function ConversationInputLeaseVehicles.createFromXML(xmlFile, key, conversation, baseDirectory, customEnvironment)
	local doLeaseVehicles = xmlFile:getValue(key .. "#value")
	if doLeaseVehicles == nil then
		Logging.xmlWarning(xmlFile, "Missing 'value' for '%s'", key)
		return nil
	else
		return ConversationInputLeaseVehicles.new(conversation, doLeaseVehicles)
	end
end
g_npcManager:registerConversationInputClass(ConversationInputLeaseVehicles.NAME, ConversationInputLeaseVehicles)
