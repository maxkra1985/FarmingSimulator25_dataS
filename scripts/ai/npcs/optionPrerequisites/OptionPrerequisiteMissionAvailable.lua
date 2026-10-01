OptionPrerequisiteMissionAvailable = {}
OptionPrerequisiteMissionAvailable.NAME = "missionAvailable"
local OptionPrerequisiteMissionAvailable_mt = Class(OptionPrerequisiteMissionAvailable)
function OptionPrerequisiteMissionAvailable.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. "#type", "Mission type", nil, true)
	schema:register(XMLValueType.STRING, basePath .. "#variant", "Variant name of the available mission", nil, false)
end
function OptionPrerequisiteMissionAvailable.new(conversation, missionTypeName, variantName, customMt)
	local self = setmetatable({}, customMt or OptionPrerequisiteMissionAvailable_mt)
	self.conversation = conversation
	self.missionTypeName = missionTypeName
	self.variantName = variantName
	return self
end
function OptionPrerequisiteMissionAvailable:getIsValid(player)
	local selectedMission = nil
	local npc = self.conversation:getNPC()
	if npc == nil then
		Logging.error("OptionPrerequisiteMissionAvailable.getIsValid: No NPC set!")
		return false
	end
	local missionType = g_missionManager:getMissionType(self.missionTypeName)
	if missionType == nil then
		Logging.error("OptionPrerequisiteMissionAvailable.getIsValid: Mission type '%s' not defined!", self.missionTypeName)
		return false
	else
		local availableMissions = npc:getInputData(ConversationInputAvailableMissions.NAME)
		if availableMissions ~= nil then
			selectedMission = availableMissions[missionType.typeId]
			if selectedMission ~= nil and self.variantName ~= nil then
				local missionVariant = string.upper(selectedMission:getVariant())
				if missionVariant ~= self.variantName then
					selectedMission = nil
				end
			end
		end
		return selectedMission ~= nil
	end
end
function OptionPrerequisiteMissionAvailable.createFromXML(xmlFile, key, conversation, baseDirectory, customEnvironment)
	local missionTypeName = xmlFile:getValue(key .. "#type")
	if missionTypeName == nil then
		Logging.xmlWarning(xmlFile, "Missing type for '%s'", key)
		return nil
	else
		local variantName = xmlFile:getValue(key .. "#variant")
		if string.isNilOrWhitespace(variantName) then
			variantName = nil
		else
			variantName = string.upper(variantName)
		end
		return OptionPrerequisiteMissionAvailable.new(conversation, missionTypeName, variantName)
	end
end
g_npcManager:registerConversationOptionPrerequisiteClass(OptionPrerequisiteMissionAvailable.NAME, OptionPrerequisiteMissionAvailable)
