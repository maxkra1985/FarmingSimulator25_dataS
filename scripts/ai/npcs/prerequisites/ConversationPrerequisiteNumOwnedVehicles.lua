-- Local values: ConversationPrerequisiteNumOwnedVehicles_mt
ConversationPrerequisiteNumOwnedVehicles = {}
ConversationPrerequisiteNumOwnedVehicles.NAME = "numOwnedVehicles"
local ConversationPrerequisiteNumOwnedVehicles_mt = Class(ConversationPrerequisiteNumOwnedVehicles)

function ConversationPrerequisiteNumOwnedVehicles.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.INT, basePath .. "#min", "Min number of owned vehicles", 0, false)
	schema:register(XMLValueType.INT, basePath .. "#max", "Max number of owned vehicles", 9999999999, false)
end

-- Upvalues: ConversationPrerequisiteNumOwnedVehicles_mt
-- Local values: self
function ConversationPrerequisiteNumOwnedVehicles.new(minNumOwnedVehicles, maxNumOwnedVehicles, customMt)
	-- upvalues: (copy) ConversationPrerequisiteNumOwnedVehicles_mt
	local v7_ = customMt or ConversationPrerequisiteNumOwnedVehicles_mt
	local v8_ = setmetatable({}, v7_)
	v8_.minNumOwnedVehicles = minNumOwnedVehicles
	v8_.maxNumOwnedVehicles = maxNumOwnedVehicles
	return v8_
end

-- Local values: farm, farmId, numVehicles, _, vehicle
function ConversationPrerequisiteNumOwnedVehicles:getIsValid(player, userData)
	if player == nil then
		return false
	end
	local v11_ = g_farmManager:getFarmByUserId(player.userId)
	if v11_ == nil then
		return false
	end
	local v12_ = v11_.farmId
	local v13_ = 0
	for _, v14_ in ipairs(g_currentMission.vehicleSystem.vehicles) do
		if v14_:getOwnerFarmId() == v12_ then
			v13_ = v13_ + 1
		end
	end
	return not MathUtil.getIsOutOfBounds(v13_, self.minNumOwnedVehicles, self.maxNumOwnedVehicles)
end

-- Local values: minNumOwnedVehicles, maxNumOwnedVehicles
function ConversationPrerequisiteNumOwnedVehicles.createFromXML(xmlFile, key, conversation, baseDirectory, customEnvironment)
	local v17_ = xmlFile:getValue(key .. "#min", 0)
	local v18_ = xmlFile:getValue(key .. "#max", math.huge)
	return ConversationPrerequisiteNumOwnedVehicles.new(v17_, v18_)
end
g_npcManager:registerConversationPrerequisiteClass(ConversationPrerequisiteNumOwnedVehicles.NAME, ConversationPrerequisiteNumOwnedVehicles)
