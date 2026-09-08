-- Local values: ConversationPrerequisiteNumTriggered_mt
ConversationPrerequisiteNumTriggered = {}
ConversationPrerequisiteNumTriggered.NAME = "numTriggered"
local ConversationPrerequisiteNumTriggered_mt = Class(ConversationPrerequisiteNumTriggered)

function ConversationPrerequisiteNumTriggered.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.INT, basePath .. "#max", "Max number of triggers", 1, false)
end

-- Upvalues: ConversationPrerequisiteNumTriggered_mt
-- Local values: self
function ConversationPrerequisiteNumTriggered.new(conversation, maxNumTriggers, customMt)
	-- upvalues: (copy) ConversationPrerequisiteNumTriggered_mt
	local v7_ = customMt or ConversationPrerequisiteNumTriggered_mt
	local v8_ = setmetatable({}, v7_)
	v8_.conversation = conversation
	v8_.maxNumTriggers = maxNumTriggers
	return v8_
end

-- Local values: npc, numTriggered
function ConversationPrerequisiteNumTriggered:getIsValid(player, userData)
	local v11_ = self.conversation:getNPC()
	if v11_ == nil then
		Logging.error("ConversationPrerequisiteNumTriggered.run: No NPC set!")
		return false
	else
		local v12_ = v11_:getConversationNumTriggered(player, self.conversation:getUniqueId())
		return v12_ == nil or v12_ < self.maxNumTriggers
	end
end

-- Local values: max
function ConversationPrerequisiteNumTriggered.createFromXML(xmlFile, key, conversation, baseDirectory, customEnvironment)
	local v16_ = xmlFile:getValue(key .. "#max", 1)
	if v16_ >= 0 then
		return ConversationPrerequisiteNumTriggered.new(conversation, v16_)
	end
	Logging.xmlWarning(xmlFile, "\'max\' may not be negative for \'%s\'", key)
	return nil
end
g_npcManager:registerConversationPrerequisiteClass(ConversationPrerequisiteNumTriggered.NAME, ConversationPrerequisiteNumTriggered)
