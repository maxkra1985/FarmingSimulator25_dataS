ConversationPrerequisiteNumContacts = {}
ConversationPrerequisiteNumContacts.NAME = "numContacts"
local ConversationPrerequisiteNumContacts_mt = Class(ConversationPrerequisiteNumContacts)
function ConversationPrerequisiteNumContacts.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.INT, basePath .. "#min", "Min number of contacts", 0, false)
	schema:register(XMLValueType.INT, basePath .. "#max", "Max number of contacts", 9999999999, false)
end
function ConversationPrerequisiteNumContacts.new(minNumContacts, maxNumContacts, customMt)
	local self = setmetatable({}, customMt or ConversationPrerequisiteNumContacts_mt)
	self.minNumContacts = minNumContacts
	self.maxNumContacts = maxNumContacts
	return self
end
function ConversationPrerequisiteNumContacts:getIsValid(player, userData)
	if player == nil then
		return false
	end
	local farm = g_farmManager:getFarmByUserId(player.userId)
	if farm == nil then
		return false
	end
	local numFields = g_farmlandManager:getNumOwnedFarmlandIdsByFarmId(farm.farmId)
	if MathUtil.getIsOutOfBounds(numFields, self.minNumContacts, self.maxNumContacts) then
		return false
	else
		return true
	end
end
function ConversationPrerequisiteNumContacts.createFromXML(xmlFile, key, conversation, baseDirectory, customEnvironment)
	local minNumContacts = xmlFile:getValue(key .. "#min", 0)
	local maxNumContacts = xmlFile:getValue(key .. "#max", math.huge)
	return ConversationPrerequisiteNumContacts.new(minNumContacts, maxNumContacts)
end
g_npcManager:registerConversationPrerequisiteClass(ConversationPrerequisiteNumContacts.NAME, ConversationPrerequisiteNumContacts)
