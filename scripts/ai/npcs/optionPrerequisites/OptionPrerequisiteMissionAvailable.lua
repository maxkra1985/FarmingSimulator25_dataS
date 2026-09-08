-- Local values: OptionPrerequisiteMissionAvailable_mt
OptionPrerequisiteMissionAvailable = {}
OptionPrerequisiteMissionAvailable.NAME = "missionAvailable"
local OptionPrerequisiteMissionAvailable_mt = Class(OptionPrerequisiteMissionAvailable)

function OptionPrerequisiteMissionAvailable.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. "#type", "Mission type", nil, true)
	schema:register(XMLValueType.STRING, basePath .. "#variant", "Variant name of the available mission", nil, false)
end

-- Upvalues: OptionPrerequisiteMissionAvailable_mt
-- Local values: self
function OptionPrerequisiteMissionAvailable.new(conversation, missionTypeName, variantName, customMt)
	-- upvalues: (copy) OptionPrerequisiteMissionAvailable_mt
	local v8_ = customMt or OptionPrerequisiteMissionAvailable_mt
	local v9_ = setmetatable({}, v8_)
	v9_.conversation = conversation
	v9_.missionTypeName = missionTypeName
	v9_.variantName = variantName
	return v9_
end

-- Local values: selectedMission, npc, missionType, availableMissions, missionVariant
function OptionPrerequisiteMissionAvailable:getIsValid(player)
	local v11_ = nil
	local v12_ = self.conversation:getNPC()
	if v12_ == nil then
		Logging.error("OptionPrerequisiteMissionAvailable.getIsValid: No NPC set!")
		return false
	end
	local v13_ = g_missionManager:getMissionType(self.missionTypeName)
	if v13_ == nil then
		Logging.error("OptionPrerequisiteMissionAvailable.getIsValid: Mission type \'%s\' not defined!", self.missionTypeName)
		return false
	end
	local v14_ = v12_:getInputData(ConversationInputAvailableMissions.NAME)
	if v14_ ~= nil then
		v11_ = v14_[v13_.typeId]
		if v11_ ~= nil and (self.variantName ~= nil and string.upper(v11_:getVariant()) ~= self.variantName) then
			v11_ = nil
		end
	end
	return v11_ ~= nil
end

-- Local values: missionTypeName, variantName
function OptionPrerequisiteMissionAvailable.createFromXML(xmlFile, key, conversation, baseDirectory, customEnvironment)
	local v18_ = xmlFile:getValue(key .. "#type")
	if v18_ == nil then
		Logging.xmlWarning(xmlFile, "Missing type for \'%s\'", key)
		return nil
	end
	local v19_ = xmlFile:getValue(key .. "#variant")
	local v20_
	if string.isNilOrWhitespace(v19_) then
		v20_ = nil
	else
		v20_ = string.upper(v19_)
	end
	return OptionPrerequisiteMissionAvailable.new(conversation, v18_, v20_)
end
g_npcManager:registerConversationOptionPrerequisiteClass(OptionPrerequisiteMissionAvailable.NAME, OptionPrerequisiteMissionAvailable)
