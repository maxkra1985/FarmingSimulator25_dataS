ConversationPrerequisiteNumOwnedVehicles = {}
ConversationPrerequisiteNumOwnedVehicles.NAME = "numOwnedVehicles"
local ConversationPrerequisiteNumOwnedVehicles_mt = Class(ConversationPrerequisiteNumOwnedVehicles)
function ConversationPrerequisiteNumOwnedVehicles.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.INT, basePath .. "#min", "Min number of owned vehicles", 0, false)
	schema:register(XMLValueType.INT, basePath .. "#max", "Max number of owned vehicles", 9999999999, false)
end
function ConversationPrerequisiteNumOwnedVehicles.new(minNumOwnedVehicles, maxNumOwnedVehicles, customMt)
	local self = setmetatable({}, customMt or ConversationPrerequisiteNumOwnedVehicles_mt)
	self.minNumOwnedVehicles = minNumOwnedVehicles
	self.maxNumOwnedVehicles = maxNumOwnedVehicles
	return self
end
function ConversationPrerequisiteNumOwnedVehicles:getIsValid(player, userData)
	if player == nil then
		return false
	end
	local farm = g_farmManager:getFarmByUserId(player.userId)
	if farm == nil then
		return false
	end
	local farmId = farm.farmId
	local numVehicles = 0
	for _, vehicle in ipairs(g_currentMission.vehicleSystem.vehicles) do
		if vehicle:getOwnerFarmId() == farmId then
			numVehicles = numVehicles + 1
		end
	end
	if MathUtil.getIsOutOfBounds(numVehicles, self.minNumOwnedVehicles, self.maxNumOwnedVehicles) then
		return false
	else
		return true
	end
end
function ConversationPrerequisiteNumOwnedVehicles.createFromXML(xmlFile, key, conversation, baseDirectory, customEnvironment)
	local minNumOwnedVehicles = xmlFile:getValue(key .. "#min", 0)
	local maxNumOwnedVehicles = xmlFile:getValue(key .. "#max", math.huge)
	return ConversationPrerequisiteNumOwnedVehicles.new(minNumOwnedVehicles, maxNumOwnedVehicles)
end
g_npcManager:registerConversationPrerequisiteClass(ConversationPrerequisiteNumOwnedVehicles.NAME, ConversationPrerequisiteNumOwnedVehicles)
