AnimalClusterHusbandry = {}
local AnimalClusterHusbandry_mt = Class(AnimalClusterHusbandry)
function AnimalClusterHusbandry.new(placeable, animalTypeName, maxVisualAnimals, customMt)
	local self = setmetatable({}, customMt or AnimalClusterHusbandry_mt)
	self.placeable = placeable
	self.husbandryId = nil
	self.navigationNode = nil
	self.maxVisualAnimals = maxVisualAnimals
	self.animalTypeName = animalTypeName
	self.animalSystem = g_currentMission.animalSystem
	self.animalIdToCluster = {}
	self.animalIdToVisualAnimalIndex = {}
	self.totalNumAnimalsPerVisualAnimalIndex = {}
	g_soundManager:addIndoorStateChangedListener(self)
	return self
end
function AnimalClusterHusbandry:delete()
	g_soundManager:removeIndoorStateChangedListener(self)
	self:deleteHusbandry()
end
function AnimalClusterHusbandry:deleteHusbandry()
	if self.husbandryId ~= nil then
		for animalId, _ in pairs(self.animalIdToCluster) do
			removeHusbandryAnimal(self.husbandryId, animalId)
		end
		delete(self.husbandryId)
		self.husbandryId = nil
	end
end
function AnimalClusterHusbandry:update(dt)
	if self.husbandryId ~= nil then
		setAnimalDaytime(self.husbandryId, g_currentMission.environment.dayTime)
		if self.visualUpdatePending and isHusbandryReady(self.husbandryId) then
			self:updateVisuals()
			self.visualUpdatePending = false
		end
	end
end
function AnimalClusterHusbandry:setMaxNumVisualAnimals(maxNum)
	self.maxVisualAnimals = maxNum
	self.visualUpdatePending = true
end
function AnimalClusterHusbandry:getNeedsUpdate()
	return self.visualUpdatePending
end
function AnimalClusterHusbandry:create(xmlFilename, navigationNode, raycastDistance, collisionMask)
	if self.husbandryId ~= nil then
		self:deleteHusbandry()
	end
	self.navigationNode = navigationNode
	local raycastCollisionFlag = CollisionMask.ANIMAL_POSITIONING
	local husbandryId = createAnimalHusbandry(self.animalTypeName, navigationNode, xmlFilename, raycastDistance, raycastCollisionFlag, collisionMask, AudioGroup.ENVIRONMENT)
	if husbandryId == 0 then
		Logging.error("Failed to create animal husbandry for %q with navigation mesh %q and config %q", self.animalTypeName, I3DUtil.getNodePath(navigationNode), xmlFilename)
		return nil
	else
		self.husbandryId = husbandryId
		self.visualUpdatePending = true
		self:onIndoorStateChanged()
		return self.husbandryId
	end
end
function AnimalClusterHusbandry:getPlaceable()
	return self.placeable
end
function AnimalClusterHusbandry:updateVisuals()
	if self.husbandryId == nil or not isHusbandryReady(self.husbandryId) then
		self.visualUpdatePending = true
		return
	end
	local clusters = self.nextUpdateClusters or {}
	self.totalNumAnimalsPerVisualAnimalIndex = {}
	local clusterToNumAnimals = {}
	local clusterToVisualAnimalIndex = {}
	local newAnimalMapping = {}
	local newAnimalIdToVisualAnimalIndex = {}
	local groupedClusters = {}
	local visualAnimalIndexToDataIndex = {}
	local totalNumAnimals = 0
	for _, cluster in ipairs(clusters) do
		local numAnimals = cluster:getNumAnimals()
		if 0 < numAnimals then
			local subTypeIndex = cluster:getSubTypeIndex()
			local age = cluster:getAge()
			local visualAnimalIndex = self.animalSystem:getVisualAnimalIndexByAge(subTypeIndex, age)
			clusterToVisualAnimalIndex[cluster] = visualAnimalIndex
			totalNumAnimals = totalNumAnimals + numAnimals
			local index = visualAnimalIndexToDataIndex[visualAnimalIndex]
			if index == nil then
				table.insert(groupedClusters, { visualAnimalIndex = visualAnimalIndex, numAnimals = 0, clusters = {}, minClusterId = math.huge })
				index = #groupedClusters
				visualAnimalIndexToDataIndex[visualAnimalIndex] = index
			end
			local data = groupedClusters[index]
			data.numAnimals = data.numAnimals + numAnimals
			data.minClusterId = math.min(cluster.id, data.minClusterId)
			table.insert(data.clusters, cluster)
			self.totalNumAnimalsPerVisualAnimalIndex[visualAnimalIndex] = (self.totalNumAnimalsPerVisualAnimalIndex[visualAnimalIndex] or 0) + numAnimals
		end
	end
	table.sort(groupedClusters, function(a, b)
		if a.numAnimals == b.numAnimals then
			return a.minClusterId < b.minClusterId
		else
			return b.numAnimals < a.numAnimals
		end
	end)
	for _, data in ipairs(groupedClusters) do
		table.sort(data.clusters, AnimalClusterHusbandry.sortClusters)
	end
	local exclusiveSlots = math.min(#groupedClusters, self.maxVisualAnimals)
	local freeSlots = self.maxVisualAnimals - exclusiveSlots
	for _, data in ipairs(groupedClusters) do
		local numAnimals = 0
		if 0 < exclusiveSlots then
			numAnimals = 1
			exclusiveSlots = exclusiveSlots - 1
		end
		if 0 < freeSlots then
			local ratio = self.totalNumAnimalsPerVisualAnimalIndex[data.visualAnimalIndex] / totalNumAnimals
			local additionalAnimals = math.min(math.ceil(ratio * freeSlots), freeSlots, data.numAnimals - 1)
			numAnimals = numAnimals + additionalAnimals
			freeSlots = freeSlots - additionalAnimals
		end
		local index = 1
		while 0 < numAnimals do
			if #data.clusters < index then
				index = 1
			end
			local cluster = data.clusters[index]
			if clusterToNumAnimals[cluster] == nil then
				clusterToNumAnimals[cluster] = 0
			end
			if clusterToNumAnimals[cluster] < cluster.numAnimals then
				clusterToNumAnimals[cluster] = clusterToNumAnimals[cluster] + 1
				numAnimals = numAnimals - 1
			end
			index = index + 1
		end
		if exclusiveSlots == 0 then
			if freeSlots ~= 0 then
				continue
			end
			for animalId, cluster in pairs(self.animalIdToCluster) do
				if clusterToNumAnimals[cluster] == nil then
					continue
				end
				local visualAnimalIndex = self.animalIdToVisualAnimalIndex[animalId]
				local clusterVisualAnimalIndex = clusterToVisualAnimalIndex[cluster]
				if visualAnimalIndex ~= clusterVisualAnimalIndex then
					setAnimalSubType(self.husbandryId, animalId, clusterVisualAnimalIndex - 1)
				end
				clusterToNumAnimals[cluster] = clusterToNumAnimals[cluster] - 1
				if clusterToNumAnimals[cluster] <= 0 then
					clusterToNumAnimals[cluster] = nil
				end
				newAnimalMapping[animalId] = cluster
				newAnimalIdToVisualAnimalIndex[animalId] = clusterVisualAnimalIndex
				self.animalIdToCluster[animalId] = nil
				self.animalIdToVisualAnimalIndex[animalId] = nil
			end
			for cluster, numAnimals in pairs(clusterToNumAnimals) do
				for i = 1, numAnimals do
					local found = false
					local visualAnimalIndex = clusterToVisualAnimalIndex[cluster]
					for animalId, typeIndex in pairs(self.animalIdToVisualAnimalIndex) do
						if visualAnimalIndex == typeIndex then
							self.animalIdToCluster[animalId] = nil
							newAnimalMapping[animalId] = cluster
							newAnimalIdToVisualAnimalIndex[animalId] = typeIndex
							clusterToNumAnimals[cluster] = clusterToNumAnimals[cluster] - 1
							if clusterToNumAnimals[cluster] <= 0 then
								clusterToNumAnimals[cluster] = nil
								break
							end
							found = true
							break
						end
					end
					if found then
						continue
					end
				end
			end
			for animalId, cluster in pairs(self.animalIdToCluster) do
				removeHusbandryAnimal(self.husbandryId, animalId)
			end
			for cluster, numAnimals in pairs(clusterToNumAnimals) do
				for i = 1, numAnimals do
					local visualAnimalIndex = clusterToVisualAnimalIndex[cluster]
					local animalId = addHusbandryAnimal(self.husbandryId, visualAnimalIndex - 1)
					if animalId == 0 then
						Logging.error("Unable to add animal with visual index %d for husbandry %d", visualAnimalIndex - 1, self.husbandryId)
					else
						local subTypeIndex = cluster:getSubTypeIndex()
						local age = cluster:getAge()
						local visualData = self.animalSystem:getVisualByAge(subTypeIndex, age)
						local variations = visualData.visualAnimal.variations
						if 1 < #variations then
							local variation = variations[math.random(1, #variations)]
							setAnimalTextureTile(self.husbandryId, animalId, variation.tileUIndex, variation.tileVIndex)
						end
						newAnimalMapping[animalId] = cluster
						newAnimalIdToVisualAnimalIndex[animalId] = visualAnimalIndex
					end
				end
			end
			for animalId, cluster in pairs(newAnimalMapping) do
				local dirtFactor = 0
				if cluster.getDirtFactor ~= nil and Platform.gameplay.needHorseCleaning then
					dirtFactor = cluster:getDirtFactor()
				end
				local animalRootNode = getAnimalRootNode(self.husbandryId, animalId)
				I3DUtil.setShaderParameterRec(animalRootNode, "dirt", dirtFactor, nil, nil, nil)
				local x, y, z, w = getAnimalShaderParameter(self.husbandryId, animalId, "atlasInvSizeAndOffsetUV")
				I3DUtil.setShaderParameterRec(animalRootNode, "atlasInvSizeAndOffsetUV", x, y, z, w)
			end
			self.animalIdToCluster = newAnimalMapping
			self.animalIdToVisualAnimalIndex = newAnimalIdToVisualAnimalIndex
			self.nextUpdateClusters = nil
			return
		end
	end
end
function AnimalClusterHusbandry:setClusters(clusters)
	self.nextUpdateClusters = clusters
	self.visualUpdatePending = true
end
function AnimalClusterHusbandry:getHusbandryId()
	return self.husbandryId
end
function AnimalClusterHusbandry:getAnimalPosition(clusterId)
	for animalId, cluster in pairs(self.animalIdToCluster) do
		if cluster.id == clusterId then
			local x, y, z = getAnimalPosition(self.husbandryId, animalId)
			local rx, ry, rz = getAnimalRotation(self.husbandryId, animalId)
			return x, y, z, rx, ry, rz
		end
	end
	return nil
end
function AnimalClusterHusbandry:getClusterByAnimalId(animalId)
	return self.animalIdToCluster[animalId]
end
function AnimalClusterHusbandry:onIndoorStateChanged(isIndoor)
	if self.husbandryId == nil then
		return
	else
		setAnimalUseOutdoorAudioSetup(self.husbandryId, not g_soundManager:getIsIndoor())
	end
end
function AnimalClusterHusbandry.sortClusters(a, b)
	local numAnimalsA = a:getNumAnimals()
	local numAnimalsB = b:getNumAnimals()
	if numAnimalsA == numAnimalsB then
		return a.id < b.id
	else
		return b:getNumAnimals() < a:getNumAnimals()
	end
end
