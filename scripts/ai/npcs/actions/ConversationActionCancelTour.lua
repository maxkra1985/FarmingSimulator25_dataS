-- Local values: ConversationActionCancelTour_mt
ConversationActionCancelTour = {}
ConversationActionCancelTour.NAME = "cancelTour"
local ConversationActionCancelTour_mt = Class(ConversationActionCancelTour)

function ConversationActionCancelTour.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath, "Cancel tour", nil, false)
end

-- Upvalues: ConversationActionCancelTour_mt
-- Local values: self
function ConversationActionCancelTour.new(customMt)
	-- upvalues: (copy) ConversationActionCancelTour_mt
	local v5_ = customMt or ConversationActionCancelTour_mt
	return setmetatable({}, v5_)
end

function ConversationActionCancelTour:run()
	g_guidedTourManager:abortTour()
	return true
end

function ConversationActionCancelTour.createFromXML(xmlFile, key, conversation, baseDirectory, customEnvironment)
	return ConversationActionCancelTour.new()
end
g_npcManager:registerConversationActionClass(ConversationActionCancelTour.NAME, ConversationActionCancelTour)
