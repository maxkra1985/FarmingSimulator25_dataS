-- Local values: ConversationPrerequisiteGameMode_mt
ConversationPrerequisiteGameMode = {}
ConversationPrerequisiteGameMode.NAME = "gameMode"
local ConversationPrerequisiteGameMode_mt = Class(ConversationPrerequisiteGameMode)

function ConversationPrerequisiteGameMode.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.BOOL, basePath .. "#singleplayer", "Is available in singleplayer", true, false)
	schema:register(XMLValueType.BOOL, basePath .. "#multiplayer", "Is available in multiplayer", true, false)
end

-- Upvalues: ConversationPrerequisiteGameMode_mt
-- Local values: self
function ConversationPrerequisiteGameMode.new(singleplayer, multiplayer, customMt)
	-- upvalues: (copy) ConversationPrerequisiteGameMode_mt
	local v7_ = customMt or ConversationPrerequisiteGameMode_mt
	local v8_ = setmetatable({}, v7_)
	v8_.singleplayer = singleplayer
	v8_.multiplayer = multiplayer
	return v8_
end

-- Local values: isMultiplayer
function ConversationPrerequisiteGameMode:getIsValid(player, userData)
	if g_currentMission.missionDynamicInfo.isMultiplayer then
		return self.multiplayer
	else
		return self.singleplayer
	end
end

-- Local values: singleplayer, multiplayer
function ConversationPrerequisiteGameMode.createFromXML(xmlFile, key, conversation, baseDirectory, customEnvironment)
	local v12_ = xmlFile:getValue(key .. "#singleplayer", true)
	local v13_ = xmlFile:getValue(key .. "#multiplayer", true)
	return ConversationPrerequisiteGameMode.new(v12_, v13_)
end
g_npcManager:registerConversationPrerequisiteClass(ConversationPrerequisiteGameMode.NAME, ConversationPrerequisiteGameMode)
