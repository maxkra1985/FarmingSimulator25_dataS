-- Local values: ActionNPCStartConversation_mt
ActionNPCStartConversation = {}
ActionNPCStartConversation.NAME = "npcStartConversation"
local ActionNPCStartConversation_mt = Class(ActionNPCStartConversation)

function ActionNPCStartConversation.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. "#npc", "Name of the npc", nil, true)
	schema:register(XMLValueType.STRING, basePath, "Filename of the conversation", nil, true)
	schema:register(XMLValueType.BOOL, basePath .. "#isPhoneConversation", "If the conversation should is a phone conversation", nil, false)
end

-- Upvalues: ActionNPCStartConversation_mt
-- Local values: self
function ActionNPCStartConversation.new(npcName, filename, isPhoneConversation, customMt)
	-- upvalues: (copy) ActionNPCStartConversation_mt
	local v8_ = customMt or ActionNPCStartConversation_mt
	local v9_ = setmetatable({}, v8_)
	v9_.npcName = npcName
	v9_.filename = filename
	v9_.isPhoneConversation = isPhoneConversation
	return v9_
end

-- Local values: npc, conversation
function ActionNPCStartConversation:run(tour, step)
	local v11_ = g_npcManager:getNPCByName(self.npcName)
	if v11_ == nil then
		Logging.warning("ActionNPCStartConversation.run: NPC \'%s\' not found", self.npcName)
		return false
	else
		local v12_ = v11_:getConversationByFilename(self.filename)
		if v12_ == nil then
			Logging.warning("ActionNPCStartConversation.run: Conversation \'%s\' not defined for NPC \'%s\'", self.filename, self.npcName)
			return false
		else
			v11_:startConversation(g_localPlayer, v12_, true, self.isPhoneConversation)
			return true
		end
	end
end

-- Local values: npcName, filename, isPhoneConversation
function ActionNPCStartConversation.createFromXML(xmlFile, key, baseDirectory, customEnvironment)
	local v15_ = xmlFile:getValue(key .. "#npc")
	local v16_ = xmlFile:getValue(key)
	local v17_ = xmlFile:getValue(key .. "#isPhoneConversation", true)
	if v15_ == nil or v16_ == nil then
		return nil
	else
		return ActionNPCStartConversation.new(v15_, v16_, v17_)
	end
end
g_guidedTourManager:registerActionClass(ActionNPCStartConversation.NAME, ActionNPCStartConversation)
