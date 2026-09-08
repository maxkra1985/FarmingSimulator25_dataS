-- Local values: ConversationActionStartSelectedMission_mt
ConversationActionStartSelectedMission = {}
ConversationActionStartSelectedMission.NAME = "startSelectedMission"
local ConversationActionStartSelectedMission_mt = Class(ConversationActionStartSelectedMission)

function ConversationActionStartSelectedMission.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath, "", nil, true)
end

-- Upvalues: ConversationActionStartSelectedMission_mt
-- Local values: self
function ConversationActionStartSelectedMission.new(conversation, customMt)
	-- upvalues: (copy) ConversationActionStartSelectedMission_mt
	local v6_ = customMt or ConversationActionStartSelectedMission_mt
	local v7_ = setmetatable({}, v6_)
	v7_.conversation = conversation
	return v7_
end

-- Local values: npc, player, farm, farmId, leaseVehicles, selectedMission
function ConversationActionStartSelectedMission:run()
	if g_server == nil then
		return true
	else
		local v9_ = self.conversation:getNPC()
		if v9_ == nil then
			Logging.error("ConversationActionStartSelectedMission.run: No NPC set!")
			return false
		else
			local v10_ = v9_:getInteractingPlayer()
			if v10_ == nil then
				Logging.error("ConversationActionStartSelectedMission.run: No player set!")
				return false
			else
				local v11_ = g_farmManager:getFarmByUserId(v10_.userId)
				if v11_ == nil then
					Logging.error("ConversationActionStartSelectedMission.run: Player has no farm!")
					return false
				else
					local v12_ = v11_:getId()
					if v12_ == FarmManager.SPECTATOR_FARM_ID or v12_ == FarmManager.INVALID_FARM_ID then
						Logging.error("ConversationActionStartSelectedMission.run: Player has invalid farm id!")
						return false
					else
						local v13_ = v9_:getInputData(ConversationInputLeaseVehicles.NAME)
						if v13_ == nil then
							v13_ = false
						end
						local v14_ = v9_:getInputData(ConversationInputSelectedMission.NAME)
						if v14_ == nil then
							Logging.error("ConversationActionStartSelectedMission.run: No mission selected!")
							return false
						else
							g_client:getServerConnection():sendEvent(MissionStartEvent.new(v14_, v12_, v13_))
							return true
						end
					end
				end
			end
		end
	end
end

function ConversationActionStartSelectedMission.createFromXML(xmlFile, key, conversation, baseDirectory, customEnvironment)
	return ConversationActionStartSelectedMission.new(conversation)
end
g_npcManager:registerConversationActionClass(ConversationActionStartSelectedMission.NAME, ConversationActionStartSelectedMission)
