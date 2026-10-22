AnimalWorkerTaskUtil = {}
function AnimalWorkerTaskUtil.getClusterFlag(cluster, methodName)
	local method = cluster[methodName]
	if method == nil then
		return false
	else
		local result = method(cluster)
		return result ~= nil and result ~= false
	end
end
function AnimalWorkerTaskUtil.getNumAnimals(placeable, methodName)
	if methodName == nil then
		return 0
	else
		local numAnimals = 0
		for _, cluster in ipairs(placeable:getClusters()) do
			local clusterNumAnimals = cluster:getNumAnimals()
			if 0 < clusterNumAnimals and AnimalWorkerTaskUtil.getClusterFlag(cluster, methodName) then
				numAnimals = numAnimals + clusterNumAnimals
			end
		end
		return numAnimals
	end
end
function AnimalWorkerTaskUtil.applyToClusters(placeable, methodName)
	if methodName == nil then
		return 0
	else
		local numHandled = 0
		for _, cluster in ipairs(placeable:getClusters()) do
			local clusterNumAnimals = cluster:getNumAnimals()
			if 0 < clusterNumAnimals and AnimalWorkerTaskUtil.getClusterFlag(cluster, methodName) then
				numHandled = numHandled + clusterNumAnimals
			end
		end
		return numHandled
	end
end
function AnimalWorkerTaskUtil.getHasSubTypeField(placeable, fieldName)
	local animalSystem = g_currentMission.animalSystem
	if animalSystem == nil or placeable.getAnimalTypeIndex == nil then
		return false
	end
	local animalTypeIndex = placeable:getAnimalTypeIndex()
	if animalTypeIndex == nil then
		return false
	end
	local animalType = animalSystem:getTypeByIndex(animalTypeIndex)
	if animalType == nil then
		return false
	else
		for _, subTypeIndex in ipairs(animalType.subTypes) do
			local subType = animalSystem:getSubTypeByIndex(subTypeIndex)
			if subType == nil or subType[fieldName] == nil then
				continue
			end
			return true
		end
		return false
	end
end
