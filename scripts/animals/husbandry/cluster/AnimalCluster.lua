-- Local values: AnimalCluster_mt
AnimalCluster = {}
local AnimalCluster_mt = Class(AnimalCluster)
AnimalCluster.NUM_BITS_NUM_ANIMALS = 16
AnimalCluster.NUM_BITS_AGE = 6
AnimalCluster.NUM_BITS_HEALTH = 7
AnimalCluster.NUM_BITS_REPRODUCTION = 7
AnimalCluster.NUM_BITS_SUB_TYPE = 7
AnimalCluster.CLUSTER_ID = 1
function AnimalCluster.getNextClusterId()
	AnimalCluster.CLUSTER_ID = AnimalCluster.CLUSTER_ID + 1
	return AnimalCluster.CLUSTER_ID
end
function AnimalCluster.resetClusterIds()
	local v2_ = g_server == nil and true or next(g_server.objects) == nil
	assert(v2_)
	AnimalCluster.CLUSTER_ID = 1
end

function AnimalCluster.registerSavegameXMLPaths(schema, basePath)
	schema:register(XMLValueType.INT, basePath .. "#numAnimals")
	schema:register(XMLValueType.INT, basePath .. "#age")
	schema:register(XMLValueType.INT, basePath .. "#health")
	schema:register(XMLValueType.INT, basePath .. "#reproduction")
end

-- Upvalues: AnimalCluster_mt
-- Local values: self, reproductionText
function AnimalCluster.new(customMt)
	-- upvalues: (copy) AnimalCluster_mt
	local v6_ = customMt or AnimalCluster_mt
	local v7_ = setmetatable({}, v6_)
	v7_.id = AnimalCluster.getNextClusterId()
	if g_isDevelopmentVersion and not g_currentMission:getIsServer() then
		v7_.id = math.random(1, 99999999)
	end
	v7_.clusterSystem = nil
	v7_.numAnimals = 0
	v7_.maxNumAnimals = 2 ^ AnimalCluster.NUM_BITS_NUM_ANIMALS - 1
	v7_.age = 0
	v7_.health = 0
	v7_.reproduction = 0
	v7_.subTypeIndex = 1
	v7_.isDirty = false
	local v8_ = g_i18n:getText("statistic_reproduction")
	v7_.infoReproduction = {
		["title"] = v8_,
		["titleOrg"] = v8_,
		["text"] = ""
	}
	v7_.infoReproductionMinAge = {
		["title"] = g_i18n:getText("infohud_reproductionMinAge"),
		["text"] = ""
	}
	v7_.infoHealth = {
		["title"] = g_i18n:getText("ui_horseHealth"),
		["text"] = ""
	}
	return v7_
end

function AnimalCluster:saveToXMLFile(xmlFile, key, usedModNames)
	xmlFile:setInt(key .. "#numAnimals", self.numAnimals)
	xmlFile:setInt(key .. "#age", self.age)
	xmlFile:setInt(key .. "#health", self.health)
	xmlFile:setInt(key .. "#reproduction", self.reproduction)
end

function AnimalCluster:loadFromXMLFile(xmlFile, key)
	local v15_ = xmlFile:getInt(key .. "#numAnimals", self.numAnimals)
	local v16_ = self.maxNumAnimals
	self.numAnimals = math.clamp(v15_, 0, v16_)
	local v17_ = xmlFile:getInt(key .. "#age", self.age)
	self.age = math.clamp(v17_, 0, 60)
	local v18_ = xmlFile:getInt(key .. "#health", self.health)
	self.health = math.clamp(v18_, 0, 100)
	local v19_ = xmlFile:getInt(key .. "#reproduction", self.reproduction)
	self.reproduction = math.clamp(v19_, 0, 100)
	return true
end

function AnimalCluster:readStream(streamId, connection)
	self.numAnimals = streamReadUIntN(streamId, AnimalCluster.NUM_BITS_NUM_ANIMALS)
	self.age = streamReadUIntN(streamId, AnimalCluster.NUM_BITS_AGE)
	self.health = streamReadUIntN(streamId, AnimalCluster.NUM_BITS_HEALTH)
	self.reproduction = streamReadUIntN(streamId, AnimalCluster.NUM_BITS_REPRODUCTION)
end

function AnimalCluster:writeStream(streamId, connection)
	streamWriteUIntN(streamId, self.numAnimals, AnimalCluster.NUM_BITS_NUM_ANIMALS)
	local v24_ = streamWriteUIntN
	local v25_ = self.age
	v24_(streamId, math.floor(v25_), AnimalCluster.NUM_BITS_AGE)
	local v26_ = streamWriteUIntN
	local v27_ = self.health
	v26_(streamId, math.floor(v27_), AnimalCluster.NUM_BITS_HEALTH)
	local v28_ = streamWriteUIntN
	local v29_ = self.reproduction
	v28_(streamId, math.floor(v29_), AnimalCluster.NUM_BITS_REPRODUCTION)
end

function AnimalCluster:readUpdateStream(streamId, connection) end

function AnimalCluster:writeUpdateStream(streamId, connection) end

function AnimalCluster:onDayChanged() end

function AnimalCluster:onPeriodChanged()
	self:changeAge(1)
end

-- Local values: ret
function AnimalCluster:clone()
	local v32_ = self.new()
	self.maxNumAnimals = 2 ^ AnimalCluster.NUM_BITS_NUM_ANIMALS - 1
	v32_.age = self.age
	v32_.health = self.health
	v32_.reproduction = self.reproduction
	v32_.subTypeIndex = self.subTypeIndex
	return v32_
end

function AnimalCluster:setClusterSystem(clusterSystem)
	self.clusterSystem = clusterSystem
end

function AnimalCluster:getNumAnimals()
	return self.numAnimals
end

-- Local values: old
function AnimalCluster:changeNumAnimals(delta)
	local v38_ = self.numAnimals
	local v39_ = self.numAnimals + delta
	local v40_ = math.floor(v39_)
	local v41_ = self.maxNumAnimals
	self.numAnimals = math.clamp(v40_, 0, v41_)
	local v42_ = self.numAnimals - v38_
	if math.abs(v42_) > 0 then
		self:setDirty()
	end
	return delta - (self.numAnimals - v38_)
end

function AnimalCluster:getSubTypeIndex()
	return self.subTypeIndex
end

function AnimalCluster:getAge()
	return self.age
end

function AnimalCluster:getAgeFactor()
	local v46_ = self.age / 60
	return math.clamp(v46_, 0, 1)
end

-- Local values: old
function AnimalCluster:changeAge(delta)
	local v49_ = self.age
	local v50_ = self.age + delta
	local v51_ = math.floor(v50_)
	self.age = math.clamp(v51_, 0, 60)
	local v52_ = self.age - v49_
	if math.abs(v52_) > 0 then
		self:setDirty()
	end
end

-- Local values: subType, healthFactor, healthThresholdFactor, factor, delta, healthDelta
function AnimalCluster:updateHealth(foodFactor)
	local v55_ = g_currentMission.animalSystem:getSubTypeByIndex(self:getSubTypeIndex())
	local v56_ = self:getHealthChangeFactor(foodFactor)
	local v57_ = v55_.healthThresholdFactor
	local v58_, v59_
	if v57_ <= v56_ then
		v58_ = (v56_ - v57_) / (1 - v57_)
		v59_ = v55_.healthIncreaseHour
	else
		v58_ = v56_ / v57_ - 1
		v59_ = v55_.healthDecreaseHour
	end
	local v60_ = v59_ * v58_
	if v60_ ~= 0 then
		self:changeHealth(v60_)
	end
end

function AnimalCluster:getHealthChangeFactor(foodFactor)
	return foodFactor
end

-- Local values: old
function AnimalCluster:changeHealth(delta)
	local v64_ = self.health
	local v65_ = self.health + delta
	local v66_ = math.floor(v65_)
	self.health = math.clamp(v66_, 0, 100)
	local v67_ = self.health - v64_
	if math.abs(v67_) > 0 then
		self:setDirty()
	end
end

function AnimalCluster:getHealthFactor()
	return self.health / 100
end

-- Local values: old
function AnimalCluster:changeReproduction(delta)
	local v71_ = self.reproduction
	local v72_ = self.reproduction + delta
	local v73_ = math.floor(v72_)
	self.reproduction = math.clamp(v73_, 0, 100)
	local v74_ = self.reproduction - v71_
	if math.abs(v74_) > 0 then
		self:setDirty()
	end
end

function AnimalCluster:getReproductionFactor()
	return self.reproduction / 100
end

function AnimalCluster:getReproductionDelta(duration)
	if duration <= 0 then
		return 0
	end
	local v77_ = 100 / duration
	return math.floor(v77_)
end

-- Local values: subType, reproductionDelta
function AnimalCluster:updateReproduction()
	if self:getCanReproduce() then
		local v79_ = self:getReproductionDelta(g_currentMission.animalSystem:getSubTypeByIndex(self:getSubTypeIndex()).reproductionDurationMonth)
		if v79_ > 0 then
			self:changeReproduction(v79_)
			if self.reproduction >= 100 then
				self.reproduction = 0
				self:setDirty()
				return self.numAnimals
			end
		end
	end
	return 0
end

-- Local values: subType
function AnimalCluster:getSupportsReproduction()
	return g_currentMission.animalSystem:getSubTypeByIndex(self:getSubTypeIndex()).supportsReproduction
end

-- Local values: subType, healthFactor
function AnimalCluster:getCanReproduce()
	local v82_ = g_currentMission.animalSystem:getSubTypeByIndex(self:getSubTypeIndex())
	if not v82_.supportsReproduction then
		return false
	end
	local v83_
	if self:getHealthFactor() >= v82_.reproductionMinHealth then
		v83_ = self.age >= v82_.reproductionMinAgeMonth
	else
		v83_ = false
	end
	return v83_
end

function AnimalCluster:setDirty()
	self.isDirty = true
	if self.clusterSystem ~= nil then
		self.clusterSystem:setDirty()
	end
end

-- Local values: subType, sellPrice, healthFactor
function AnimalCluster:getSellPrice()
	local v86_ = g_currentMission.animalSystem:getSubTypeByIndex(self:getSubTypeIndex()).sellPrice:get(self.age)
	local v87_ = self:getHealthFactor()
	return v86_ * 0.4 + v86_ * (0.6 * v87_)
end

function AnimalCluster:getCanBeSold()
	return true
end

-- Local values: subType
function AnimalCluster:getRidableFilename()
	return g_currentMission.animalSystem:getSubTypeByIndex(self.subTypeIndex).rideableFilename
end

function AnimalCluster:getTranportationFee(numItems)
	return g_currentMission.animalSystem:getAnimalTransportFee(self.subTypeIndex, self.age) * numItems
end

function AnimalCluster:getSupportsMerging()
	return true
end

function AnimalCluster:merge(otherCluster)
	local v93_ = self.age - otherCluster.age
	if math.abs(v93_) <= 0.5 then
		local v94_ = self.health - otherCluster.health
		if math.abs(v94_) <= 0.5 then
			local v95_ = self.reproduction - otherCluster.reproduction
			if math.abs(v95_) <= 0.5 then
				::l4::
				local v96_ = self.numAnimals + otherCluster.numAnimals
				self.numAnimals = math.clamp(v96_, 0, 65535)
				return true
			end
		end
	end
	Logging.warning("Cluster-Collision detected: Merged (Age: %.4f, Health: %.4f, Reproduction: %.4f) with (Age: %.4f, Health: %.4f, Reproduction: %.4f)", self.health, self.age, self.reproduction, otherCluster.health, otherCluster.age, otherCluster.reproduction)
	goto l4
end

-- Local values: age, health, reproduction, subTypeIndex
function AnimalCluster:getHash()
	local v98_ = self.age
	local v99_ = self.health
	local v100_ = self.reproduction
	local v101_ = self.subTypeIndex
	local v102_ = 100 + v98_
	local v103_ = 1000 * (100 + v99_)
	local v104_ = 1000000 * (100 + v100_)
	local v105_ = 1000000000 * (100 + v101_)
	return v102_ + v103_ + v104_ + v105_
end

function AnimalCluster:getMergeSupport()
	return true
end

-- Local values: animalSystem, subType
function AnimalCluster:showInfo(box)
	local v108_ = g_currentMission.animalSystem:getSubTypeByIndex(self.subTypeIndex)
	box:addLine(g_i18n:getText("infohud_type"), g_fillTypeManager:getFillTypeTitleByIndex(v108_.fillTypeIndex))
	box:addLine(g_i18n:getText("infohud_age"), g_i18n:formatNumMonth(self.age))
	if self.numAnimals > 1 then
		local v109_ = g_i18n:getText("infohud_numAnimals")
		local v110_ = self.numAnimals
		box:addLine(v109_, (tostring(v110_)))
	end
	box:addLine(g_i18n:getText("infohud_health"), string.format("%d %%", self.health))
	box:addLine(g_i18n:getText("infohud_reproduction"), string.format("%d %%", self.reproduction))
end

-- Local values: healthFactor, subType, minAgeFactor, reproductionFactor
function AnimalCluster:addInfos(infos)
	local v113_ = self:getHealthFactor()
	self.infoHealth.value = v113_
	self.infoHealth.ratio = v113_
	self.infoHealth.valueText = string.format("%s %%", g_i18n:formatNumber(v113_ * 100, 0))
	local v114_ = self.infoHealth
	table.insert(infos, v114_)
	if self:getSupportsReproduction() then
		local v115_ = g_currentMission.animalSystem:getSubTypeByIndex(self:getSubTypeIndex())
		if self.age < v115_.reproductionMinAgeMonth then
			local v116_ = self:getAge() / v115_.reproductionMinAgeMonth
			local v117_ = math.clamp(v116_, 0, 1)
			self.infoReproductionMinAge.value = v117_
			self.infoReproductionMinAge.ratio = v117_
			self.infoReproductionMinAge.valueText = string.format("%s %%", g_i18n:formatNumber(v117_ * 100, 0))
			local v118_ = self.infoReproductionMinAge
			table.insert(infos, v118_)
			return
		end
		local v119_ = self:getReproductionFactor()
		self.infoReproduction.value = v119_
		self.infoReproduction.ratio = v119_
		self.infoReproduction.valueText = string.format("%s %%", g_i18n:formatNumber(v119_ * 100, 0))
		self.infoReproduction.disabled = not self:getCanReproduce()
		local v120_ = self.infoReproduction
		table.insert(infos, v120_)
	end
end
