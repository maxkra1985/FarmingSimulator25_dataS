NPCConversationGuidedTour = {}
local NPCConversationGuidedTour_mt = Class(NPCConversationGuidedTour, NPCConversation)
function NPCConversationGuidedTour.new(npc, uniqueId, customMt)
	local self = NPCConversation.new(npc, uniqueId, customMt or NPCConversationGuidedTour_mt)
	return self
end
function NPCConversationGuidedTour:updateUserData(userData) end
function NPCConversationGuidedTour:saveToSavegameXMLFile(xmlFile, key, userData) end
function NPCConversationGuidedTour:loadFromSavegameXMLFile(xmlFile, key, userData) end
function NPCConversationGuidedTour:getCanBeCanceled()
	return false
end
