-- Local values: AnimalClusterHorse_mt
AnimalClusterHorse = {}
local AnimalClusterHorse_mt = Class(AnimalClusterHorse, AnimalCluster)
AnimalClusterHorse.NUM_BITS_FITNESS = 7
AnimalClusterHorse.NUM_BITS_RIDING = 7
AnimalClusterHorse.NUM_BITS_DIRT = 7
AnimalClusterHorse.DAILY_RIDING_TIME = 300000
AnimalClusterHorse.BRUSH_DELTA = -20

-- Upvalues: AnimalClusterHorse_mt
-- Local values: self
function AnimalClusterHorse.new(customMt)
	-- upvalues: (copy) AnimalClusterHorse_mt
	local v3_ = AnimalCluster.new(customMt or AnimalClusterHorse_mt)
	v3_.fitness = 0
	v3_.riding = 0
	v3_.dirt = 0
	v3_.name = g_currentMission.animalNameSystem:getRandomName()
	v3_.infoCleanliness = {
		["title"] = g_i18n:getText("statistic_cleanliness"),
		["text"] = ""
	}
	v3_.infoFitness = {
		["title"] = g_i18n:getText("ui_horseFitness"),
		["text"] = ""
	}
	v3_.infoRiding = {
		["title"] = g_i18n:getText("ui_horseDailyRiding"),
		["text"] = ""
	}
	return v3_
end

function AnimalClusterHorse:saveToXMLFile(xmlFile, key, usedModNames)
	AnimalClusterHorse:superClass().saveToXMLFile(self, xmlFile, key, usedModNames)
	xmlFile:setString(key .. "#name", self.name)
	xmlFile:setInt(key .. "#fitness", self.fitness)
	xmlFile:setInt(key .. "#riding", self.riding)
	xmlFile:setInt(key .. "#dirt", self.dirt)
end

function AnimalClusterHorse:loadFromXMLFile(xmlFile, key)
	if not AnimalClusterHorse:superClass().loadFromXMLFile(self, xmlFile, key) then
		return false
	end
	local v11_ = xmlFile:getInt(key .. "#fitness", self.fitness)
	self.fitness = math.clamp(v11_, 0, 100)
	self.name = xmlFile:getString(key .. "#name", self.name)
	local v12_ = xmlFile:getInt(key .. "#riding", self.riding)
	self.riding = math.clamp(v12_, 0, 100)
	local v13_ = xmlFile:getInt(key .. "#dirt", self.dirt)
	self.dirt = math.clamp(v13_, 0, 100)
	return true
end

function AnimalClusterHorse:readStream(streamId, connection)
	AnimalClusterHorse:superClass().readStream(self, streamId, connection)
	self.name = streamReadString(streamId)
	self.fitness = streamReadUIntN(streamId, AnimalClusterHorse.NUM_BITS_FITNESS)
	self.riding = streamReadUIntN(streamId, AnimalClusterHorse.NUM_BITS_RIDING)
	self.dirt = streamReadUIntN(streamId, AnimalClusterHorse.NUM_BITS_DIRT)
end

function AnimalClusterHorse:writeStream(streamId, connection)
	AnimalClusterHorse:superClass().writeStream(self, streamId, connection)
	streamWriteString(streamId, self.name)
	local v20_ = streamWriteUIntN
	local v21_ = self.fitness
	v20_(streamId, math.floor(v21_), AnimalClusterHorse.NUM_BITS_FITNESS)
	local v22_ = streamWriteUIntN
	local v23_ = self.riding
	v22_(streamId, math.floor(v23_), AnimalClusterHorse.NUM_BITS_RIDING)
	local v24_ = streamWriteUIntN
	local v25_ = self.dirt
	v24_(streamId, math.floor(v25_), AnimalClusterHorse.NUM_BITS_DIRT)
end

function AnimalClusterHorse:readUpdateStream(streamId, connection)
	AnimalClusterHorse:superClass().readUpdateStream(self, streamId, connection)
	self.fitness = streamReadUIntN(streamId, AnimalClusterHorse.NUM_BITS_FITNESS)
	self.riding = streamReadUIntN(streamId, AnimalClusterHorse.NUM_BITS_RIDING)
	self.dirt = streamReadUIntN(streamId, AnimalClusterHorse.NUM_BITS_DIRT)
end

function AnimalClusterHorse:writeUpdateStream(streamId, connection)
	AnimalClusterHorse:superClass().writeUpdateStream(self, streamId, connection)
	local v32_ = streamWriteUIntN
	local v33_ = self.fitness
	v32_(streamId, math.floor(v33_), AnimalClusterHorse.NUM_BITS_FITNESS)
	local v34_ = streamWriteUIntN
	local v35_ = self.riding
	v34_(streamId, math.floor(v35_), AnimalClusterHorse.NUM_BITS_RIDING)
	local v36_ = streamWriteUIntN
	local v37_ = self.dirt
	v36_(streamId, math.floor(v37_), AnimalClusterHorse.NUM_BITS_DIRT)
end

-- Local values: ret
function AnimalClusterHorse:clone()
	local v39_ = AnimalClusterHorse:superClass().clone(self)
	v39_.fitness = self.fitness
	v39_.name = self.name
	v39_.riding = self.riding
	v39_.dirt = self.dirt
	return v39_
end

-- Local values: ridingFactor, subType, minRidingFactor, factor, delta, deltaFitness
function AnimalClusterHorse:onDayChanged()
	AnimalClusterHorse:superClass().onDayChanged(self)
	local v41_ = self:getRidingFactor()
	local v42_ = g_currentMission.animalSystem:getSubTypeByIndex(self:getSubTypeIndex()).ridingThresholdFactor
	local v43_, v44_
	if v42_ < v41_ then
		v43_ = (v41_ - v42_) / (1 - v42_)
		v44_ = 25
	else
		v43_ = v41_ / v42_ - 1
		v44_ = 10
	end
	self:changeFitness(v44_ * v43_ * g_currentMission.environment.timeAdjustment)
	self:resetRiding()
	self:changeDirt(10)
end

function AnimalClusterHorse:getName()
	return self.name
end

-- Local values: fitnessFactor, cleanlinessFactor
function AnimalClusterHorse:getHealthChangeFactor(foodFactor)
	local v48_ = self:getFitnessFactor()
	if not Platform.gameplay.needHorseCleaning then
		return 0.6 * foodFactor + 0.4 * v48_
	end
	local v49_ = 1 - self:getDirtFactor()
	return 0.5 * foodFactor + 0.4 * v48_ + 0.1 * v49_
end

function AnimalClusterHorse:setName(name)
	self.name = name
end

function AnimalClusterHorse:getFitnessFactor()
	return self.fitness / 100
end

-- Local values: old
function AnimalClusterHorse:changeFitness(delta)
	local v55_ = self.fitness
	local v56_ = self.fitness + delta
	local v57_ = math.floor(v56_)
	self.fitness = math.clamp(v57_, 0, 100)
	local v58_ = self.fitness - v55_
	if math.abs(v58_) > 0 then
		self:setDirty()
	end
end

function AnimalClusterHorse:getRidingFactor()
	return self.riding / 100
end

function AnimalClusterHorse:setRiding(riding)
	self.riding = riding
end

function AnimalClusterHorse:resetRiding()
	self.riding = 0
	self:setDirty()
end

-- Local values: old
function AnimalClusterHorse:changeRiding(delta)
	local v65_ = self.riding
	local v66_ = self.riding + delta
	local v67_ = math.floor(v66_)
	self.riding = math.clamp(v67_, 0, 100)
	local v68_ = self.riding - v65_
	if math.abs(v68_) > 0 then
		self:setDirty()
	end
end

function AnimalClusterHorse:getDirtFactor()
	return self.dirt / 100
end

-- Local values: old
function AnimalClusterHorse:changeDirt(delta)
	local v72_ = self.dirt
	local v73_ = self.dirt + delta
	local v74_ = math.floor(v73_)
	self.dirt = math.clamp(v74_, 0, 100)
	local v75_ = self.dirt - v72_
	if math.abs(v75_) > 0 then
		self:setDirty()
	end
end

-- Local values: subType, sellPrice, healthFactor, fitnessFactor
function AnimalClusterHorse:getSellPrice()
	local v77_ = g_currentMission.animalSystem:getSubTypeByIndex(self:getSubTypeIndex()).sellPrice:get(self.age)
	local v78_ = self:getHealthFactor()
	local v79_ = self:getFitnessFactor()
	return v77_ * (0.3 + 0.5 * v78_ + 0.2 * v79_)
end

function AnimalClusterHorse:getDailyRidingTime()
	return AnimalClusterHorse.DAILY_RIDING_TIME
end

function AnimalClusterHorse:getSupportsMerging()
	return false
end

-- Local values: hash, fitness, dirt, riding
function AnimalClusterHorse:getHash()
	local v81_ = AnimalClusterHorse:superClass().getHash(self)
	local v82_ = 1000000000000 * (100 + self.fitness)
	local v83_ = 1000000000000000 * (100 + self.dirt)
	local v84_ = 1e18 * (100 + self.riding)
	return v81_ + v82_ + v83_ + v84_
end

function AnimalClusterHorse:showInfo(box)
	box:addLine(g_i18n:getText("infohud_name"), self.name)
	AnimalClusterHorse:superClass().showInfo(self, box)
	box:addLine(g_i18n:getText("infohud_riding"), string.format("%d %%", self.riding))
	box:addLine(g_i18n:getText("infohud_fitness"), string.format("%d %%", self.fitness))
	if Platform.gameplay.needHorseCleaning then
		box:addLine(g_i18n:getText("statistic_cleanliness"), string.format("%d %%", 100 - self.dirt))
	end
end

-- Local values: cleanlinessFactor, fitnessFactor, ridingFactor
function AnimalClusterHorse:addInfos(infos)
	AnimalClusterHorse:superClass().addInfos(self, infos)
	if Platform.gameplay.needHorseCleaning then
		local v89_ = 1 - self:getDirtFactor()
		self.infoCleanliness.value = v89_
		self.infoCleanliness.ratio = v89_
		self.infoCleanliness.valueText = string.format("%s %%", g_i18n:formatNumber(v89_ * 100, 0))
		local v90_ = self.infoCleanliness
		table.insert(infos, v90_)
	end
	local v91_ = self:getFitnessFactor()
	self.infoFitness.value = v91_
	self.infoFitness.ratio = v91_
	self.infoFitness.valueText = string.format("%s %%", g_i18n:formatNumber(v91_ * 100, 0))
	local v92_ = self.infoFitness
	table.insert(infos, v92_)
	local v93_ = self:getRidingFactor()
	self.infoRiding.value = v93_
	self.infoRiding.ratio = v93_
	self.infoRiding.valueText = string.format("%s %%", g_i18n:formatNumber(v93_ * 100, 0))
	local v94_ = self.infoRiding
	table.insert(infos, v94_)
end
