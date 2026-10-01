ConversationPrerequisiteNumTriggered = {}
ConversationPrerequisiteNumTriggered.NAME = "numTriggered"
local ConversationPrerequisiteNumTriggered_mt = Class(ConversationPrerequisiteNumTriggered)
function ConversationPrerequisiteNumTriggered.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.INT, basePath .. "#max", "Max number of triggers", 1, false)
end
function ConversationPrerequisiteNumTriggered.new(conversation, maxNumTriggers, customMt)
	local self = setmetatable({}, customMt or ConversationPrerequisiteNumTriggered_mt)
	self.conversation = conversation
	self.maxNumTriggers = maxNumTriggers
	return self
end
function ConversationPrerequisiteNumTriggered:getIsValid(player, userData)
	local npc = self.conversation:getNPC()
	if npc == nil then
		Logging.error("ConversationPrerequisiteNumTriggered.run: No NPC set!")
		return false
	else
		local numTriggered = npc:getConversationNumTriggered(player, self.conversation:getUniqueId())
		if numTriggered == nil or numTriggered < self.maxNumTriggers then
			return true
		end
		return false
	end
end
function ConversationPrerequisiteNumTriggered.createFromXML(xmlFile, key, conversation, baseDirectory, customEnvironment)
	local max = xmlFile:getValue(key .. "#max", 1)
	if max < 0 then
		Logging.xmlWarning(xmlFile, "'max' may not be negative for '%s'", key)
		return nil
	else
		return ConversationPrerequisiteNumTriggered.new(conversation, max)
	end
end
g_npcManager:registerConversationPrerequisiteClass(ConversationPrerequisiteNumTriggered.NAME, ConversationPrerequisiteNumTriggered)
