-- Local values: ConversationInputSelectedMission_mt
ConversationInputSelectedMission = {}
ConversationInputSelectedMission.NAME = "selectedMission"
local ConversationInputSelectedMission_mt = Class(ConversationInputSelectedMission)

function ConversationInputSelectedMission.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. "#type", "Mission type", nil, true)
end

-- Upvalues: ConversationInputSelectedMission_mt
-- Local values: self
function ConversationInputSelectedMission.new(conversation, missionTypeName, customMt)
	-- upvalues: (copy) ConversationInputSelectedMission_mt
	local v7_ = customMt or ConversationInputSelectedMission_mt
	local v8_ = setmetatable({}, v7_)
	v8_.conversation = conversation
	v8_.missionTypeName = missionTypeName
	return v8_
end

-- Local values: npc, missionType, availableMissions, selectedMission
function ConversationInputSelectedMission:run()
	local v10_ = self.conversation:getNPC()
	if v10_ == nil then
		Logging.error("ConversationInputSelectedMission.run: No NPC set!")
		return false
	else
		local v11_ = g_missionManager:getMissionType(self.missionTypeName)
		if v11_ == nil then
			Logging.error("ConversationInputSelectedMission.run: Mission type \'%s\' not defined!", self.missionTypeName)
			return false
		else
			local v12_ = v10_:getInputData(ConversationInputAvailableMissions.NAME)
			if v12_ == nil then
				Logging.error("ConversationInputSelectedMission.run: No available missions set!")
				return false
			else
				local v13_ = v12_[v11_.typeId]
				if v13_ == nil then
					Logging.error("ConversationInputSelectedMission.run: No mission of type \'%s\' available!", self.missionTypeName)
					return false
				else
					v10_:setInputData(ConversationInputSelectedMission.NAME, v13_)
					return true
				end
			end
		end
	end
end

-- Local values: missionTypeName
function ConversationInputSelectedMission.createFromXML(xmlFile, key, conversation, baseDirectory, customEnvironment)
	local v17_ = xmlFile:getValue(key .. "#type")
	if v17_ ~= nil then
		return ConversationInputSelectedMission.new(conversation, v17_)
	end
	Logging.xmlWarning(xmlFile, "Missing type for \'%s\'", key)
	return nil
end
g_npcManager:registerConversationInputClass(ConversationInputSelectedMission.NAME, ConversationInputSelectedMission)
