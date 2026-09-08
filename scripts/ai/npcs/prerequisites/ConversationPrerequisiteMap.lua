-- Local values: ConversationPrerequisiteMap_mt
ConversationPrerequisiteMap = {}
ConversationPrerequisiteMap.NAME = "map"
local ConversationPrerequisiteMap_mt = Class(ConversationPrerequisiteMap)

function ConversationPrerequisiteMap.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. "#mapId", "Map id", nil, false)
end

-- Upvalues: ConversationPrerequisiteMap_mt
-- Local values: self
function ConversationPrerequisiteMap.new(mapId, customMt)
	-- upvalues: (copy) ConversationPrerequisiteMap_mt
	local v6_ = customMt or ConversationPrerequisiteMap_mt
	local v7_ = setmetatable({}, v6_)
	v7_.mapId = mapId
	return v7_
end

function ConversationPrerequisiteMap:getIsValid(player, userData)
	return self.mapId == g_currentMission.missionInfo.mapId
end

-- Local values: mapId
function ConversationPrerequisiteMap.createFromXML(xmlFile, key, conversation, baseDirectory, customEnvironment)
	local v11_ = xmlFile:getValue(key .. "#mapId", nil)
	if v11_ ~= nil then
		return ConversationPrerequisiteMap.new(v11_)
	end
	Logging.xmlWarning(xmlFile, "Missing \'mapId\' for \'%s\'", key)
	return nil
end
g_npcManager:registerConversationPrerequisiteClass(ConversationPrerequisiteMap.NAME, ConversationPrerequisiteMap)
