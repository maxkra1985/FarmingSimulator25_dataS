-- Local values: ConversationActionNavigateToNPC_mt
ConversationActionNavigateToNPC = {}
ConversationActionNavigateToNPC.NAME = "navigateToNPC"
local ConversationActionNavigateToNPC_mt = Class(ConversationActionNavigateToNPC)

function ConversationActionNavigateToNPC.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. "#npcName", "Name of the npc", nil, true)
end

-- Upvalues: ConversationActionNavigateToNPC_mt
-- Local values: self
function ConversationActionNavigateToNPC.new(npcName, customMt)
	-- upvalues: (copy) ConversationActionNavigateToNPC_mt
	local v6_ = customMt or ConversationActionNavigateToNPC_mt
	local v7_ = setmetatable({}, v6_)
	v7_.npcName = npcName
	return v7_
end

-- Local values: npc, mapHotspot
function ConversationActionNavigateToNPC:run()
	local v9_ = g_npcManager:getNPCByName(self.npcName)
	if v9_ == nil then
		Logging.error("ConversationActionNavigateToNPC.run: NPC \'%s\' not defined", self.npcName)
		return false
	end
	local v10_ = v9_:getMapHotspot()
	if v10_ == nil then
		return false
	end
	g_currentMission:setMapTargetHotspot(v10_)
	return true
end

-- Local values: npcName
function ConversationActionNavigateToNPC.createFromXML(xmlFile, key, conversation, baseDirectory, customEnvironment)
	local v13_ = xmlFile:getValue(key .. "#npcName")
	if v13_ ~= nil then
		return ConversationActionNavigateToNPC.new(v13_)
	end
	Logging.xmlWarning(xmlFile, "Missing \'npcName\' for \'%s\'", key)
	return nil
end
g_npcManager:registerConversationActionClass(ConversationActionNavigateToNPC.NAME, ConversationActionNavigateToNPC)
