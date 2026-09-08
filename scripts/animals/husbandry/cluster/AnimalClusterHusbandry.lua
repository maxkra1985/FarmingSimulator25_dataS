-- Local values: AnimalClusterHusbandry_mt
AnimalClusterHusbandry = {}
local AnimalClusterHusbandry_mt = Class(AnimalClusterHusbandry)

-- Upvalues: AnimalClusterHusbandry_mt
-- Local values: self
function AnimalClusterHusbandry.new(placeable, animalTypeName, maxVisualAnimals, customMt)
	-- upvalues: (copy) AnimalClusterHusbandry_mt
	local v6_ = customMt or AnimalClusterHusbandry_mt
	local v7_ = setmetatable({}, v6_)
	v7_.placeable = placeable
	v7_.husbandryId = nil
	v7_.navigationNode = nil
	v7_.maxVisualAnimals = maxVisualAnimals
	v7_.animalTypeName = animalTypeName
	v7_.animalSystem = g_currentMission.animalSystem
	v7_.animalIdToCluster = {}
	v7_.animalIdToVisualAnimalIndex = {}
	v7_.totalNumAnimalsPerVisualAnimalIndex = {}
	g_soundManager:addIndoorStateChangedListener(v7_)
	return v7_
end

function AnimalClusterHusbandry:delete()
	g_soundManager:removeIndoorStateChangedListener(self)
	self:deleteHusbandry()
end

-- Local values: animalId, _
function AnimalClusterHusbandry:deleteHusbandry()
	if self.husbandryId ~= nil then
		for v10_, _ in pairs(self.animalIdToCluster) do
			removeHusbandryAnimal(self.husbandryId, v10_)
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

-- Local values: raycastCollisionFlag, husbandryId
function AnimalClusterHusbandry:create(xmlFilename, navigationNode, raycastDistance, collisionMask)
	if self.husbandryId ~= nil then
		self:deleteHusbandry()
	end
	self.navigationNode = navigationNode
	local v20_ = CollisionMask.ANIMAL_POSITIONING
	local v21_ = createAnimalHusbandry(self.animalTypeName, navigationNode, xmlFilename, raycastDistance, v20_, collisionMask, AudioGroup.ENVIRONMENT)
	if v21_ == 0 then
		Logging.error("Failed to create animal husbandry for %q with navigation mesh %q and config %q", self.animalTypeName, I3DUtil.getNodePath(navigationNode), xmlFilename)
		return nil
	end
	self.husbandryId = v21_
	self.visualUpdatePending = true
	self:onIndoorStateChanged()
	return self.husbandryId
end

function AnimalClusterHusbandry:getPlaceable()
	return self.placeable
end

-- Local values: clusters, clusterToNumAnimals, clusterToVisualAnimalIndex, newAnimalMapping, newAnimalIdToVisualAnimalIndex, groupedClusters, visualAnimalIndexToDataIndex, totalNumAnimals, _, cluster, numAnimals, subTypeIndex, age, visualAnimalIndex, index, data, _, data, exclusiveSlots, freeSlots, _, data, numAnimals, ratio, additionalAnimals, index, cluster, animalId, cluster, visualAnimalIndex, clusterVisualAnimalIndex, cluster, numAnimals, i, found, visualAnimalIndex, animalId, typeIndex, animalId, cluster, cluster, numAnimals, i, visualAnimalIndex, animalId, subTypeIndex, age, visualData, variations, variation, animalId, cluster, dirtFactor, animalRootNode, x, y, z, w
function AnimalClusterHusbandry:updateVisuals()
	if self.husbandryId == nil or not isHusbandryReady(self.husbandryId) then
		self.visualUpdatePending = true
		return
	end
	local v24_ = self.nextUpdateClusters or {}
	self.totalNumAnimalsPerVisualAnimalIndex = {}
	local v25_ = {}
	local v26_ = 0
	local v27_ = {}
	local v28_ = {}
	local v29_ = {}
	local v30_ = {}
	local v31_ = {}
	for _, v32_ in ipairs(v24_) do
		local v33_ = v32_:getNumAnimals()
		if v33_ > 0 then
			local v34_ = v32_:getSubTypeIndex()
			local v35_ = v32_:getAge()
			local v36_ = self.animalSystem:getVisualAnimalIndexByAge(v34_, v35_)
			v25_[v32_] = v36_
			v26_ = v26_ + v33_
			local v37_ = v27_[v36_]
			if v37_ == nil then
				table.insert(v28_, {
					["visualAnimalIndex"] = v36_,
					["numAnimals"] = 0,
					["clusters"] = {},
					["minClusterId"] = math.huge
				})
				v37_ = #v28_
				v27_[v36_] = v37_
			end
			local v38_ = v28_[v37_]
			v38_.numAnimals = v38_.numAnimals + v33_
			local v39_ = v32_.id
			local v40_ = v38_.minClusterId
			v38_.minClusterId = math.min(v39_, v40_)
			local v41_ = v38_.clusters
			table.insert(v41_, v32_)
			self.totalNumAnimalsPerVisualAnimalIndex[v36_] = (self.totalNumAnimalsPerVisualAnimalIndex[v36_] or 0) + v33_
		end
	end
	table.sort(v28_, function(p42_, p43_)
		if p42_.numAnimals == p43_.numAnimals then
			return p42_.minClusterId < p43_.minClusterId
		else
			return p42_.numAnimals > p43_.numAnimals
		end
	end)
	for _, v44_ in ipairs(v28_) do
		table.sort(v44_.clusters, AnimalClusterHusbandry.sortClusters)
	end
	local v45_ = #v28_
	local v46_ = self.maxVisualAnimals
	local v47_ = math.min(v45_, v46_)
	local v48_ = self.maxVisualAnimals - v47_
	for _, v49_ in ipairs(v28_) do
		local v50_
		if v47_ > 0 then
			v47_ = v47_ - 1
			v50_ = 1
		else
			v50_ = 0
		end
		if v48_ > 0 then
			local v51_ = self.totalNumAnimalsPerVisualAnimalIndex[v49_.visualAnimalIndex] / v26_ * v48_
			local v52_ = math.ceil(v51_)
			local v53_ = v49_.numAnimals - 1
			local v54_ = math.min(v52_, v48_, v53_)
			v50_ = v50_ + v54_
			v48_ = v48_ - v54_
		end
		local v55_ = 1
		while v50_ > 0 do
			local v56_ = #v49_.clusters < v55_ and 1 or v55_
			local v57_ = v49_.clusters[v56_]
			if v29_[v57_] == nil then
				v29_[v57_] = 0
			end
			if v29_[v57_] < v57_.numAnimals then
				v29_[v57_] = v29_[v57_] + 1
				v50_ = v50_ - 1
			end
			v55_ = v56_ + 1
		end
		if v47_ == 0 and v48_ == 0 then
			break
		end
	end
	for v58_, v59_ in pairs(self.animalIdToCluster) do
		if v29_[v59_] ~= nil then
			local v60_ = self.animalIdToVisualAnimalIndex[v58_]
			local v61_ = v25_[v59_]
			if v60_ ~= v61_ then
				setAnimalSubType(self.husbandryId, v58_, v61_ - 1)
			end
			v29_[v59_] = v29_[v59_] - 1
			if v29_[v59_] <= 0 then
				v29_[v59_] = nil
			end
			v30_[v58_] = v59_
			v31_[v58_] = v61_
			self.animalIdToCluster[v58_] = nil
			self.animalIdToVisualAnimalIndex[v58_] = nil
		end
	end
	for v62_, v63_ in pairs(v29_) do
		for _ = 1, v63_ do
			local v64_ = v25_[v62_]
			local v65_ = false
			for v66_, v67_ in pairs(self.animalIdToVisualAnimalIndex) do
				if v64_ == v67_ then
					self.animalIdToCluster[v66_] = nil
					v30_[v66_] = v62_
					v31_[v66_] = v67_
					v29_[v62_] = v29_[v62_] - 1
					if v29_[v62_] <= 0 then
						v29_[v62_] = nil
					else
						v65_ = true
					end
					break
				end
			end
			if not v65_ then
				break
			end
		end
	end
	for v68_, _ in pairs(self.animalIdToCluster) do
		removeHusbandryAnimal(self.husbandryId, v68_)
	end
	for v69_, v70_ in pairs(v29_) do
		for _ = 1, v70_ do
			local v71_ = v25_[v69_]
			local v72_ = addHusbandryAnimal(self.husbandryId, v71_ - 1)
			if v72_ == 0 then
				Logging.error("Unable to add animal with visual index %d for husbandry %d", v71_ - 1, self.husbandryId)
			else
				local v73_ = v69_:getSubTypeIndex()
				local v74_ = v69_:getAge()
				local v75_ = self.animalSystem:getVisualByAge(v73_, v74_).visualAnimal.variations
				if #v75_ > 1 then
					local v76_ = v75_[math.random(1, #v75_)]
					setAnimalTextureTile(self.husbandryId, v72_, v76_.tileUIndex, v76_.tileVIndex)
				end
				v30_[v72_] = v69_
				v31_[v72_] = v71_
			end
		end
	end
	for v77_, v78_ in pairs(v30_) do
		local v79_ = (v78_.getDirtFactor == nil or not Platform.gameplay.needHorseCleaning) and 0 or v78_:getDirtFactor()
		local v80_ = getAnimalRootNode(self.husbandryId, v77_)
		I3DUtil.setShaderParameterRec(v80_, "dirt", v79_, nil, nil, nil)
		local v81_, v82_, v83_, v84_ = getAnimalShaderParameter(self.husbandryId, v77_, "atlasInvSizeAndOffsetUV")
		I3DUtil.setShaderParameterRec(v80_, "atlasInvSizeAndOffsetUV", v81_, v82_, v83_, v84_)
	end
	self.animalIdToCluster = v30_
	self.animalIdToVisualAnimalIndex = v31_
	self.nextUpdateClusters = nil
end

function AnimalClusterHusbandry:setClusters(clusters)
	self.nextUpdateClusters = clusters
	self.visualUpdatePending = true
end

function AnimalClusterHusbandry:getHusbandryId()
	return self.husbandryId
end

-- Local values: animalId, cluster, x, y, z, rx, ry, rz
function AnimalClusterHusbandry:getAnimalPosition(clusterId)
	for v90_, v91_ in pairs(self.animalIdToCluster) do
		if v91_.id == clusterId then
			local v92_, v93_, v94_ = getAnimalPosition(self.husbandryId, v90_)
			local v95_, v96_, v97_ = getAnimalRotation(self.husbandryId, v90_)
			return v92_, v93_, v94_, v95_, v96_, v97_
		end
	end
	return nil
end

function AnimalClusterHusbandry:getClusterByAnimalId(animalId)
	return self.animalIdToCluster[animalId]
end

function AnimalClusterHusbandry:onIndoorStateChanged(isIndoor)
	if self.husbandryId ~= nil then
		setAnimalUseOutdoorAudioSetup(self.husbandryId, not g_soundManager:getIsIndoor())
	end
end

-- Local values: numAnimalsA, numAnimalsB
function AnimalClusterHusbandry.sortClusters(a, b)
	if a:getNumAnimals() == b:getNumAnimals() then
		return a.id < b.id
	else
		return a:getNumAnimals() > b:getNumAnimals()
	end
end
