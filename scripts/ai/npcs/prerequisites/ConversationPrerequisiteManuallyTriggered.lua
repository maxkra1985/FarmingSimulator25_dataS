-- Local values: ConversationPrerequisiteManuallyTriggered_mt
ConversationPrerequisiteManuallyTriggered = {}
ConversationPrerequisiteManuallyTriggered.NAME = "manuallyTriggered"
local ConversationPrerequisiteManuallyTriggered_mt = Class(ConversationPrerequisiteManuallyTriggered)

function ConversationPrerequisiteManuallyTriggered.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath, "The conversation is manually triggered", nil, false)
end

-- Upvalues: ConversationPrerequisiteManuallyTriggered_mt
-- Local values: self
function ConversationPrerequisiteManuallyTriggered.new(customMt)
	-- upvalues: (copy) ConversationPrerequisiteManuallyTriggered_mt
	local v5_ = customMt or ConversationPrerequisiteManuallyTriggered_mt
	return setmetatable({}, v5_)
end

function ConversationPrerequisiteManuallyTriggered:getIsValid(player, userData)
	return false
end

function ConversationPrerequisiteManuallyTriggered.createFromXML(xmlFile, key, conversation, baseDirectory, customEnvironment)
	return ConversationPrerequisiteManuallyTriggered.new()
end
g_npcManager:registerConversationPrerequisiteClass(ConversationPrerequisiteManuallyTriggered.NAME, ConversationPrerequisiteManuallyTriggered)
