-- Local values: ConversationPrerequisiteMissionAvailable_mt
ConversationPrerequisiteMissionAvailable = {}
ConversationPrerequisiteMissionAvailable.NAME = "missionAvailable"
local ConversationPrerequisiteMissionAvailable_mt = Class(ConversationPrerequisiteMissionAvailable)

function ConversationPrerequisiteMissionAvailable.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. ".type(?)#name", "Type name of the available mission", nil, false)
	schema:register(XMLValueType.STRING, basePath .. ".type(?)#variant", "Variant name of the available mission", nil, false)
end

-- Upvalues: ConversationPrerequisiteMissionAvailable_mt
-- Local values: self
function ConversationPrerequisiteMissionAvailable.new(conversation, missionTypes, customMt)
	-- upvalues: (copy) ConversationPrerequisiteMissionAvailable_mt
	local v7_ = customMt or ConversationPrerequisiteMissionAvailable_mt
	local v8_ = setmetatable({}, v7_)
	v8_.conversation = conversation
	v8_.missionTypes = missionTypes
	v8_.availableMissions = {}
	return v8_
end

-- Local values: npc, missionManager, hasMission, _, setting, typeName, missionType, missions, _, mission, missionNPC, isSameNPC, isMissionReady, isSameVariant, variant
function ConversationPrerequisiteMissionAvailable:getIsValid(player, userData)
	if g_server == nil then
		return false
	end
	local v11_ = self.conversation:getNPC()
	if v11_ == nil then
		Logging.error("ConversationPrerequisiteMissionAvailable.run: No NPC set!")
		return false
	end
	local v12_ = g_missionManager
	if v12_:hasFarmReachedMissionLimit(player.farmId) then
		Logging.devInfo("ConversationPrerequisiteMissionAvailable.run: Mission limit reached!")
		return false
	end
	self.availableMissions = {}
	Utils.shuffle(self.missionTypes)
	local v13_ = false
	for _, v14_ in ipairs(self.missionTypes) do
		local v15_ = v14_.name
		local v16_ = v12_:getMissionType(v15_)
		if v16_ == nil then
			Logging.error("ConversationPrerequisiteMissionAvailable.getIsValid: Mission type \'%s\' not defined!", v15_)
		elseif self.availableMissions[v16_.typeId] == nil then
			local v17_ = v12_:getMissionsByType(v16_.typeId)
			Utils.shuffle(v17_)
			for _, v18_ in ipairs(v17_) do
				local v19_ = v18_:getNPC()
				local v20_
				if v19_ == nil then
					v20_ = false
				else
					v20_ = v19_ == v11_
				end
				local v21_ = v18_:getIsReadyToStart()
				local v22_ = true
				if not string.isNilOrWhitespace(v14_.variantName) then
					local v23_ = v18_:getVariant()
					if string.upper(v23_) ~= string.upper(v14_.variantName) then
						v22_ = false
					end
				end
				if v20_ and (v22_ and v21_) then
					self.availableMissions[v16_.typeId] = v18_
					v13_ = true
					break
				end
			end
		end
	end
	return v13_
end

-- Local values: npc
function ConversationPrerequisiteMissionAvailable:onConversationStart()
	local v25_ = self.conversation:getNPC()
	if v25_ == nil then
		Logging.error("ConversationPrerequisiteMissionAvailable.run: No NPC set!")
	else
		v25_:setInputData(ConversationInputAvailableMissions.NAME, self.availableMissions)
	end
end

-- Local values: missionTypes, _, typeKey, typeName, variantName, setting
function ConversationPrerequisiteMissionAvailable.createFromXML(xmlFile, key, conversation, baseDirectory, customEnvironment)
	local v29_ = {}
	for _, v30_ in xmlFile:iterator(key .. ".type") do
		local v31_ = xmlFile:getValue(v30_ .. "#name")
		if not string.isNilOrWhitespace(v31_) then
			local v32_ = {
				["name"] = v31_,
				["variantName"] = xmlFile:getValue(v30_ .. "#variant")
			}
			table.addElement(v29_, v32_)
		end
	end
	if #v29_ ~= 0 then
		return ConversationPrerequisiteMissionAvailable.new(conversation, v29_)
	end
	Logging.xmlWarning(xmlFile, "No mission types defined for \'%s\'", key)
	return nil
end
g_npcManager:registerConversationPrerequisiteClass(ConversationPrerequisiteMissionAvailable.NAME, ConversationPrerequisiteMissionAvailable)
