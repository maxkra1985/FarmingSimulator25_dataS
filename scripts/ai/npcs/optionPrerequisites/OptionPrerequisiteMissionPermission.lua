OptionPrerequisiteMissionPermission = {}
OptionPrerequisiteMissionPermission.NAME = "missionPermission"
local OptionPrerequisiteMissionPermission_mt = Class(OptionPrerequisiteMissionPermission)
function OptionPrerequisiteMissionPermission.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath, "Mission Permission", nil, true)
end
function OptionPrerequisiteMissionPermission.new(customMt)
	local self = setmetatable({}, customMt or OptionPrerequisiteMissionPermission_mt)
	return self
end
function OptionPrerequisiteMissionPermission:getIsValid(player)
	local connection = player ~= nil and player.connection or nil
	if not g_currentMission:getHasPlayerPermission(Farm.PERMISSION.MANAGE_CONTRACTING, connection) then
		return false
	else
		return true
	end
end
function OptionPrerequisiteMissionPermission.createFromXML(xmlFile, key, conversation, baseDirectory, customEnvironment)
	return OptionPrerequisiteMissionPermission.new()
end
g_npcManager:registerConversationOptionPrerequisiteClass(OptionPrerequisiteMissionPermission.NAME, OptionPrerequisiteMissionPermission)
