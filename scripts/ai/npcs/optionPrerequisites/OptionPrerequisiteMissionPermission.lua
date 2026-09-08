-- Local values: OptionPrerequisiteMissionPermission_mt
OptionPrerequisiteMissionPermission = {}
OptionPrerequisiteMissionPermission.NAME = "missionPermission"
local OptionPrerequisiteMissionPermission_mt = Class(OptionPrerequisiteMissionPermission)

function OptionPrerequisiteMissionPermission.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath, "Mission Permission", nil, true)
end

-- Upvalues: OptionPrerequisiteMissionPermission_mt
-- Local values: self
function OptionPrerequisiteMissionPermission.new(customMt)
	-- upvalues: (copy) OptionPrerequisiteMissionPermission_mt
	local v5_ = customMt or OptionPrerequisiteMissionPermission_mt
	return setmetatable({}, v5_)
end

-- Local values: connection
function OptionPrerequisiteMissionPermission:getIsValid(player)
	local v7_ = player ~= nil and player.connection or nil
	return g_currentMission:getHasPlayerPermission(Farm.PERMISSION.MANAGE_CONTRACTING, v7_) and true or false
end

function OptionPrerequisiteMissionPermission.createFromXML(xmlFile, key, conversation, baseDirectory, customEnvironment)
	return OptionPrerequisiteMissionPermission.new()
end
g_npcManager:registerConversationOptionPrerequisiteClass(OptionPrerequisiteMissionPermission.NAME, OptionPrerequisiteMissionPermission)
