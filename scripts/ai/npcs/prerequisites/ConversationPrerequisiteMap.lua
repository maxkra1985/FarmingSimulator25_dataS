ConversationPrerequisiteMap = {}
ConversationPrerequisiteMap.NAME = "map"
local ConversationPrerequisiteMap_mt = Class(ConversationPrerequisiteMap)
function ConversationPrerequisiteMap.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. "#mapId", "Map id", nil, false)
end
function ConversationPrerequisiteMap.new(mapId, customMt)
	local self = setmetatable({}, customMt or ConversationPrerequisiteMap_mt)
	self.mapId = mapId
	return self
end
function ConversationPrerequisiteMap:getIsValid(player, userData)
	if self.mapId ~= g_currentMission.missionInfo.mapId then
		return false
	else
		return true
	end
end
function ConversationPrerequisiteMap.createFromXML(xmlFile, key, conversation, baseDirectory, customEnvironment)
	local mapId = xmlFile:getValue(key .. "#mapId", nil)
	if mapId == nil then
		Logging.xmlWarning(xmlFile, "Missing 'mapId' for '%s'", key)
		return nil
	else
		return ConversationPrerequisiteMap.new(mapId)
	end
end
g_npcManager:registerConversationPrerequisiteClass(ConversationPrerequisiteMap.NAME, ConversationPrerequisiteMap)
