-- Local values: ConversationPrerequisiteNumOwnedAnimals_mt
ConversationPrerequisiteNumOwnedAnimals = {}
ConversationPrerequisiteNumOwnedAnimals.NAME = "numOwnedAnimals"
local ConversationPrerequisiteNumOwnedAnimals_mt = Class(ConversationPrerequisiteNumOwnedAnimals)

function ConversationPrerequisiteNumOwnedAnimals.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.INT, basePath .. "#min", "Min number of owned animals", 0, false)
	schema:register(XMLValueType.INT, basePath .. "#max", "Max number of owned animals", 9999999999, false)
	schema:register(XMLValueType.STRING, basePath .. "#type", "Animal type", nil, false)
end

-- Upvalues: ConversationPrerequisiteNumOwnedAnimals_mt
-- Local values: self
function ConversationPrerequisiteNumOwnedAnimals.new(minNumOwnedAnimals, maxNumOwnedAnimals, animalTypeName, customMt)
	-- upvalues: (copy) ConversationPrerequisiteNumOwnedAnimals_mt
	local v8_ = customMt or ConversationPrerequisiteNumOwnedAnimals_mt
	local v9_ = setmetatable({}, v8_)
	v9_.minNumOwnedAnimals = minNumOwnedAnimals
	v9_.maxNumOwnedAnimals = maxNumOwnedAnimals
	v9_.animalTypeName = animalTypeName
	return v9_
end

-- Local values: farm, animalTypeIndex, farmId, placeables, numAnimals, _, placeable
function ConversationPrerequisiteNumOwnedAnimals:getIsValid(player, userData)
	if player == nil then
		return false
	end
	local v12_ = g_farmManager:getFarmByUserId(player.userId)
	if v12_ == nil then
		return false
	end
	local v13_
	if self.animalTypeName == nil then
		v13_ = nil
	else
		v13_ = g_currentMission.animalSystem:getTypeIndexByName(self.animalTypeName)
	end
	local v14_ = v12_.farmId
	local v15_ = g_currentMission.husbandrySystem:getPlaceablesByFarm(v14_, v13_)
	local v16_ = 0
	for _, v17_ in ipairs(v15_) do
		v16_ = v16_ + v17_:getNumOfAnimals()
	end
	return not MathUtil.getIsOutOfBounds(v16_, self.minNumOwnedAnimals, self.maxNumOwnedAnimals)
end

-- Local values: minNumOwnedAnimals, maxNumOwnedAnimals, animalTypeName
function ConversationPrerequisiteNumOwnedAnimals.createFromXML(xmlFile, key, conversation, baseDirectory, customEnvironment)
	local v20_ = xmlFile:getValue(key .. "#min", 0)
	local v21_ = xmlFile:getValue(key .. "#max", math.huge)
	local v22_ = xmlFile:getValue(key .. "#type")
	return ConversationPrerequisiteNumOwnedAnimals.new(v20_, v21_, v22_)
end
g_npcManager:registerConversationPrerequisiteClass(ConversationPrerequisiteNumOwnedAnimals.NAME, ConversationPrerequisiteNumOwnedAnimals)
