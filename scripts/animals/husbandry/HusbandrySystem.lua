-- Local values: HusbandrySystem_mt
HusbandrySystem = {}
HusbandrySystem.GAME_LIMIT = 15
local HusbandrySystem_mt = Class(HusbandrySystem)

-- Upvalues: HusbandrySystem_mt
-- Local values: self
function HusbandrySystem.new(isServer, mission, customMt)
	-- upvalues: (copy) HusbandrySystem_mt
	local v5_ = customMt or HusbandrySystem_mt
	local v6_ = setmetatable({}, v5_)
	v6_.isServer = isServer
	v6_.mission = mission
	v6_.manureHeaps = {}
	v6_.placeables = {}
	v6_.clusterHusbandries = {}
	v6_.rideables = {}
	v6_.maxNumRidables = 4
	v6_.husbandrys = {}
	v6_.livestockTrailers = {}
	return v6_
end

function HusbandrySystem:delete() end

-- Local values: success
function HusbandrySystem:addPlaceable(placeable)
	local v9_ = table.addElement(self.placeables, placeable)
	if v9_ then
		g_messageCenter:publish(MessageType.HUSBANDRY_SYSTEM_ADDED_PLACEABLE)
	end
	return v9_
end

-- Local values: success
function HusbandrySystem:removePlaceable(placeable)
	local v12_ = table.removeElement(self.placeables, placeable)
	if v12_ and v12_ then
		g_messageCenter:publish(MessageType.HUSBANDRY_SYSTEM_REMOVED_PLACEABLE)
	end
	return v12_
end

function HusbandrySystem:addClusterHusbandry(clusterHusbandry)
	return table.addElement(self.clusterHusbandries, clusterHusbandry)
end

function HusbandrySystem:removeClusterHusbandry(clusterHusbandry)
	return table.removeElement(self.clusterHusbandries, clusterHusbandry)
end

-- Local values: placeables, _, placeable
function HusbandrySystem:getPlaceablesByFarm(farmId, animalTypeIndex)
	local v20_ = farmId or g_localPlayer.farmId
	local v21_ = {}
	for _, v22_ in ipairs(self.placeables) do
		if v20_ == v22_:getOwnerFarmId() and (animalTypeIndex == nil or v22_:getAnimalTypeIndex() == animalTypeIndex) then
			table.insert(v21_, v22_)
		end
	end
	return v21_
end

-- Local values: _, clusterHusbandry
function HusbandrySystem:getClusterHusbandryById(husbandryId)
	for _, v25_ in ipairs(self.clusterHusbandries) do
		if v25_:getHusbandryId() == husbandryId then
			return v25_
		end
	end
	return nil
end

function HusbandrySystem:getLimitReached()
	return #self.placeables >= HusbandrySystem.GAME_LIMIT
end

function HusbandrySystem:addManureHeap(manureHeap)
	return table.addElement(self.manureHeaps, manureHeap)
end

function HusbandrySystem:removeManureHeap(manureHeap)
	return table.removeElement(self.manureHeaps, manureHeap)
end

function HusbandrySystem:addRideable(rideable)
	table.addElement(self.rideables, rideable)
end

function HusbandrySystem:removeRideable(rideable)
	table.removeElement(self.rideables, rideable)
end

-- Local values: num, _, rideable
function HusbandrySystem:getNumRideablesPerFarm(farmId)
	local v37_ = 0
	for _, v38_ in ipairs(self.rideables) do
		if v38_:getOwnerFarmId() == farmId then
			v37_ = v37_ + 1
		end
	end
	return v37_
end

-- Local values: numRidables
function HusbandrySystem:getCanAddRideable(farmId)
	return self:getNumRideablesPerFarm(farmId) < self.maxNumRidables
end

-- Local values: farmId, cluster, animalSystem, typeIndex, _, placeable
function HusbandrySystem:getFirstAvailableHusbandry(rideable)
	local v43_ = rideable:getOwnerFarmId()
	local v44_ = rideable:getCluster()
	local v45_ = g_currentMission.animalSystem:getTypeIndexBySubTypeIndex(v44_:getSubTypeIndex())
	for _, v46_ in ipairs(self.placeables) do
		if v46_:getOwnerFarmId() == v43_ and (v46_:getAnimalTypeIndex() == v45_ and v46_:getNumOfFreeAnimalSlots() > 0) then
			return v46_
		end
	end
	return nil
end

-- Local values: farmId, cluster, animalSystem, typeIndex, placeableInRange, isInRange, x, _, z, _, placeable
function HusbandrySystem:getHusbandryInRideableRange(rideable)
	local v49_ = rideable:getOwnerFarmId()
	local v50_ = rideable:getCluster()
	local v51_ = g_currentMission.animalSystem:getTypeIndexBySubTypeIndex(v50_:getSubTypeIndex())
	local v52_, _, v53_ = getWorldTranslation(rideable.rootNode)
	local v54_ = false
	local v55_ = nil
	for _, v56_ in ipairs(self.placeables) do
		if v56_:getOwnerFarmId() == v49_ and v56_:getIsInAnimalDeliveryArea(v52_, v53_) then
			v54_ = true
			if v56_:getAnimalTypeIndex() == v51_ and v56_:getNumOfFreeAnimalSlots() > 0 then
				v55_ = v56_
			end
		end
	end
	return v54_, v55_
end

function HusbandrySystem:addLivestockTrailer(trailer)
	table.addElement(self.livestockTrailers, trailer)
end

function HusbandrySystem:removeLivestockTrailer(trailer)
	table.removeElement(self.livestockTrailers, trailer)
end

-- Local values: usedSlots, totalSlots, animalSystem, typeIndex, _, placeable, _, livestockTrailer, animalType, _, rideable, cluster, rideableSubTypeIndex
function HusbandrySystem:getNumOfFreeAnimalSlots(farmId, subTypeIndex)
	local v64_ = g_currentMission.animalSystem
	local v65_ = v64_:getTypeIndexBySubTypeIndex(subTypeIndex)
	local v66_ = 0
	local v67_ = 0
	for _, v68_ in ipairs(self.placeables) do
		if v68_:getOwnerFarmId() == farmId and v68_:getAnimalTypeIndex() == v65_ then
			v66_ = v66_ + v68_:getMaxNumOfAnimals()
			v67_ = v67_ + v68_:getNumOfAnimals()
		end
	end
	for _, v69_ in ipairs(self.livestockTrailers) do
		if v69_:getOwnerFarmId() == farmId then
			local v70_ = v69_:getCurrentAnimalType()
			if v70_ ~= nil and v70_.typeIndex == v65_ then
				v67_ = v67_ + v69_:getNumOfAnimals()
			end
		end
	end
	for _, v71_ in ipairs(self.rideables) do
		if v71_:getOwnerFarmId() == farmId then
			local v72_ = v71_:getCluster()
			if v72_ ~= nil and v64_:getTypeIndexBySubTypeIndex((v72_:getSubTypeIndex())) == v65_ then
				v67_ = v67_ + 1
			end
		end
	end
	return v66_ - v67_
end
