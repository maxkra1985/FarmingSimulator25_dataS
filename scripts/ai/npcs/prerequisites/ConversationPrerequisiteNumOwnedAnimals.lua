ConversationPrerequisiteNumOwnedAnimals = {}
ConversationPrerequisiteNumOwnedAnimals.NAME = "numOwnedAnimals"
local ConversationPrerequisiteNumOwnedAnimals_mt = Class(ConversationPrerequisiteNumOwnedAnimals)
function ConversationPrerequisiteNumOwnedAnimals.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.INT, basePath .. "#min", "Min number of owned animals", 0, false)
	schema:register(XMLValueType.INT, basePath .. "#max", "Max number of owned animals", 9999999999, false)
	schema:register(XMLValueType.STRING, basePath .. "#type", "Animal type", nil, false)
end
function ConversationPrerequisiteNumOwnedAnimals.new(minNumOwnedAnimals, maxNumOwnedAnimals, animalTypeName, customMt)
	local self = setmetatable({}, customMt or ConversationPrerequisiteNumOwnedAnimals_mt)
	self.minNumOwnedAnimals = minNumOwnedAnimals
	self.maxNumOwnedAnimals = maxNumOwnedAnimals
	self.animalTypeName = animalTypeName
	return self
end
function ConversationPrerequisiteNumOwnedAnimals:getIsValid(player, userData)
	if player == nil then
		return false
	end
	local farm = g_farmManager:getFarmByUserId(player.userId)
	if farm == nil then
		return false
	end
	local animalTypeIndex = nil
	if self.animalTypeName ~= nil then
		animalTypeIndex = g_currentMission.animalSystem:getTypeIndexByName(self.animalTypeName)
	end
	local farmId = farm.farmId
	local placeables = g_currentMission.husbandrySystem:getPlaceablesByFarm(farmId, animalTypeIndex)
	local numAnimals = 0
	for _, placeable in ipairs(placeables) do
		numAnimals = numAnimals + placeable:getNumOfAnimals()
	end
	if MathUtil.getIsOutOfBounds(numAnimals, self.minNumOwnedAnimals, self.maxNumOwnedAnimals) then
		return false
	else
		return true
	end
end
function ConversationPrerequisiteNumOwnedAnimals.createFromXML(xmlFile, key, conversation, baseDirectory, customEnvironment)
	local minNumOwnedAnimals = xmlFile:getValue(key .. "#min", 0)
	local maxNumOwnedAnimals = xmlFile:getValue(key .. "#max", math.huge)
	local animalTypeName = xmlFile:getValue(key .. "#type")
	return ConversationPrerequisiteNumOwnedAnimals.new(minNumOwnedAnimals, maxNumOwnedAnimals, animalTypeName)
end
g_npcManager:registerConversationPrerequisiteClass(ConversationPrerequisiteNumOwnedAnimals.NAME, ConversationPrerequisiteNumOwnedAnimals)
