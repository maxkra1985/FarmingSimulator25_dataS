-- Local values: FarmStats_mt
FarmStats = {}
local FarmStats_mt = Class(FarmStats)
FarmStats.STAT_NAMES = {
	"fuelUsage",
	"seedUsage",
	"sprayUsage",
	"traveledDistance",
	"workedHectares",
	"cultivatedHectares",
	"plowedHectares",
	"sownHectares",
	"sprayedHectares",
	"threshedHectares",
	"weededHectares",
	"harvestedGrapes",
	"harvestedOlives",
	"workedTime",
	"cultivatedTime",
	"plowedTime",
	"sownTime",
	"sprayedTime",
	"threshedTime",
	"weededTime",
	"baleCount",
	"breedCowsCount",
	"breedPigsCount",
	"breedSheepCount",
	"breedChickenCount",
	"breedHorsesCount",
	"breedGoatsCount",
	"breedWaterBuffaloCount",
	"revenue",
	"expenses",
	"playTime",
	"workersHired",
	"storedBales",
	"storedPallets",
	"missionCount",
	"plantedTreeCount",
	"cutTreeCount",
	"woodTonsSold",
	"treeTypesCut",
	"windTurbineCount",
	"petDogCount",
	"tractorDistance",
	"carDistance",
	"truckDistance",
	"horseDistance",
	"horseJumpCount",
	"repairVehicleCount",
	"repaintVehicleCount",
	"soldCottonBales",
	"wrappedBales"
}
FarmStats.HERO_STAT_NAMES = {
	"playTime",
	"moneyEarned",
	"traveledDistance",
	"completedMissions",
	"threshedHectares"
}
function FarmStats.new()
	-- upvalues: (copy) FarmStats_mt
	local v2_ = FarmStats_mt
	local v3_ = setmetatable({}, v2_)
	v3_.statistics = {}
	for _, v4_ in pairs(FarmStats.STAT_NAMES) do
		v3_.statistics[v4_] = {
			["session"] = 0,
			["total"] = 0
		}
	end
	v3_.statistics.treeTypesCut = "000000"
	v3_.finances = FinanceStats.new()
	v3_.financesHistory = {}
	v3_.heroStats = {}
	for _, v5_ in pairs(FarmStats.HERO_STAT_NAMES) do
		v3_.heroStats[v5_] = {
			["id"] = nil,
			["value"] = nil,
			["accumValue"] = 0
		}
	end
	v3_.heroStatsLoaded = false
	v3_.moneyEarnedHeroAccum = 0
	v3_.nextHeroAccumUpdate = 0
	if g_currentMission:getIsServer() then
		g_currentMission:addUpdateable(v3_)
	end
	v3_.financesVersionCounter = 0
	v3_.financesHistoryVersionCounter = 0
	v3_.financesHistoryVersionCounterLocal = 0
	v3_.updatePlayTime = true
	return v3_
end

function FarmStats:delete()
	g_currentMission:removeUpdateable(self)
end

-- Local values: toSave, numHistoricItems
function FarmStats:saveToXMLFile(xmlFile, key)
	xmlFile:setFloat(key .. ".statistics.traveledDistance", self.statistics.traveledDistance.total)
	xmlFile:setFloat(key .. ".statistics.fuelUsage", self.statistics.fuelUsage.total)
	xmlFile:setFloat(key .. ".statistics.seedUsage", self.statistics.seedUsage.total)
	xmlFile:setFloat(key .. ".statistics.sprayUsage", self.statistics.sprayUsage.total)
	xmlFile:setFloat(key .. ".statistics.workedHectares", self.statistics.workedHectares.total)
	xmlFile:setFloat(key .. ".statistics.cultivatedHectares", self.statistics.cultivatedHectares.total)
	xmlFile:setFloat(key .. ".statistics.sownHectares", self.statistics.sownHectares.total)
	xmlFile:setFloat(key .. ".statistics.sprayedHectares", self.statistics.sprayedHectares.total)
	xmlFile:setFloat(key .. ".statistics.threshedHectares", self.statistics.threshedHectares.total)
	xmlFile:setFloat(key .. ".statistics.plowedHectares", self.statistics.plowedHectares.total)
	xmlFile:setFloat(key .. ".statistics.harvestedGrapes", self.statistics.harvestedGrapes.total)
	xmlFile:setFloat(key .. ".statistics.harvestedOlives", self.statistics.harvestedOlives.total)
	xmlFile:setFloat(key .. ".statistics.workedTime", self.statistics.workedTime.total)
	xmlFile:setFloat(key .. ".statistics.cultivatedTime", self.statistics.cultivatedTime.total)
	xmlFile:setFloat(key .. ".statistics.sownTime", self.statistics.sownTime.total)
	xmlFile:setFloat(key .. ".statistics.sprayedTime", self.statistics.sprayedTime.total)
	xmlFile:setFloat(key .. ".statistics.threshedTime", self.statistics.threshedTime.total)
	xmlFile:setFloat(key .. ".statistics.plowedTime", self.statistics.plowedTime.total)
	xmlFile:setInt(key .. ".statistics.baleCount", self.statistics.baleCount.total)
	xmlFile:setInt(key .. ".statistics.breedCowsCount", self.statistics.breedCowsCount.total)
	xmlFile:setInt(key .. ".statistics.breedSheepCount", self.statistics.breedSheepCount.total)
	xmlFile:setInt(key .. ".statistics.breedPigsCount", self.statistics.breedPigsCount.total)
	xmlFile:setInt(key .. ".statistics.breedChickenCount", self.statistics.breedChickenCount.total)
	xmlFile:setInt(key .. ".statistics.breedHorsesCount", self.statistics.breedHorsesCount.total)
	xmlFile:setInt(key .. ".statistics.breedGoatsCount", self.statistics.breedGoatsCount.total)
	xmlFile:setInt(key .. ".statistics.breedWaterBuffaloCount", self.statistics.breedWaterBuffaloCount.total)
	xmlFile:setInt(key .. ".statistics.missionCount", self.statistics.missionCount.total)
	xmlFile:setFloat(key .. ".statistics.revenue", self.statistics.revenue.total)
	xmlFile:setFloat(key .. ".statistics.expenses", self.statistics.expenses.total)
	xmlFile:setFloat(key .. ".statistics.playTime", self.statistics.playTime.total)
	xmlFile:setInt(key .. ".statistics.plantedTreeCount", self.statistics.plantedTreeCount.total)
	xmlFile:setInt(key .. ".statistics.cutTreeCount", self.statistics.cutTreeCount.total)
	xmlFile:setFloat(key .. ".statistics.woodTonsSold", self.statistics.woodTonsSold.total)
	xmlFile:setString(key .. ".statistics.treeTypesCut", self.statistics.treeTypesCut)
	xmlFile:setInt(key .. ".statistics.petDogCount", self.statistics.petDogCount.total)
	xmlFile:setInt(key .. ".statistics.repairVehicleCount", self.statistics.repairVehicleCount.total)
	xmlFile:setInt(key .. ".statistics.repaintVehicleCount", self.statistics.repaintVehicleCount.total)
	xmlFile:setInt(key .. ".statistics.horseJumpCount", self.statistics.horseJumpCount.total)
	xmlFile:setInt(key .. ".statistics.soldCottonBales", self.statistics.soldCottonBales.total)
	xmlFile:setInt(key .. ".statistics.wrappedBales", self.statistics.wrappedBales.total)
	xmlFile:setFloat(key .. ".statistics.tractorDistance", self.statistics.tractorDistance.total)
	xmlFile:setFloat(key .. ".statistics.carDistance", self.statistics.carDistance.total)
	xmlFile:setFloat(key .. ".statistics.truckDistance", self.statistics.truckDistance.total)
	xmlFile:setFloat(key .. ".statistics.horseDistance", self.statistics.horseDistance.total)
	local v10_ = { self.finances }
	local v11_ = #self.financesHistory
	if v11_ > 3 then
		local v12_ = self.financesHistory[v11_ - 3]
		table.insert(v10_, v12_)
	end
	if v11_ > 2 then
		local v13_ = self.financesHistory[v11_ - 2]
		table.insert(v10_, v13_)
	end
	if v11_ > 1 then
		local v14_ = self.financesHistory[v11_ - 1]
		table.insert(v10_, v14_)
	end
	if v11_ > 0 then
		local v15_ = self.financesHistory[v11_ - 0]
		table.insert(v10_, v15_)
	end
	xmlFile:setSortedTable(key .. ".finances.stats", v10_, function(p16_, p17_, p18_)
		-- upvalues: (copy) xmlFile
		xmlFile:setInt(p16_ .. "#day", p18_ - 1)
		p17_:saveToXMLFile(xmlFile, p16_)
	end)
end

-- Local values: key
function FarmStats:loadFromXMLFile(xmlFile, rootKey)
	local v22_ = rootKey .. ".statistics"
	self.statistics.traveledDistance.total = xmlFile:getFloat(v22_ .. ".traveledDistance", 0)
	self.statistics.fuelUsage.total = xmlFile:getFloat(v22_ .. ".fuelUsage", 0)
	self.statistics.seedUsage.total = xmlFile:getFloat(v22_ .. ".seedUsage", 0)
	self.statistics.sprayUsage.total = xmlFile:getFloat(v22_ .. ".sprayUsage", 0)
	self.statistics.workedHectares.total = xmlFile:getFloat(v22_ .. ".workedHectares", 0)
	self.statistics.cultivatedHectares.total = xmlFile:getFloat(v22_ .. ".cultivatedHectares", 0)
	self.statistics.sownHectares.total = xmlFile:getFloat(v22_ .. ".sownHectares", 0)
	self.statistics.sprayedHectares.total = xmlFile:getFloat(v22_ .. ".sprayedHectares", 0)
	self.statistics.threshedHectares.total = xmlFile:getFloat(v22_ .. ".threshedHectares", 0)
	self.statistics.weededHectares.total = xmlFile:getFloat(v22_ .. ".weededHectares", 0)
	self.statistics.plowedHectares.total = xmlFile:getFloat(v22_ .. ".plowedHectares", 0)
	self.statistics.harvestedGrapes.total = xmlFile:getFloat(v22_ .. ".harvestedGrapes", 0)
	self.statistics.harvestedOlives.total = xmlFile:getFloat(v22_ .. ".harvestedOlives", 0)
	self.statistics.workedTime.total = xmlFile:getFloat(v22_ .. ".workedTime", 0)
	self.statistics.cultivatedTime.total = xmlFile:getFloat(v22_ .. ".cultivatedTime", 0)
	self.statistics.sownTime.total = xmlFile:getFloat(v22_ .. ".sownTime", 0)
	self.statistics.sprayedTime.total = xmlFile:getFloat(v22_ .. ".sprayedTime", 0)
	self.statistics.threshedTime.total = xmlFile:getFloat(v22_ .. ".threshedTime", 0)
	self.statistics.weededTime.total = xmlFile:getFloat(v22_ .. ".weededTime", 0)
	self.statistics.plowedTime.total = xmlFile:getFloat(v22_ .. ".plowedTime", 0)
	self.statistics.baleCount.total = xmlFile:getInt(v22_ .. ".baleCount", 0)
	self.statistics.breedCowsCount.total = xmlFile:getInt(v22_ .. ".breedCowsCount", 0)
	self.statistics.breedSheepCount.total = xmlFile:getInt(v22_ .. ".breedSheepCount", 0)
	self.statistics.breedPigsCount.total = xmlFile:getInt(v22_ .. ".breedPigsCount", 0)
	self.statistics.breedChickenCount.total = xmlFile:getInt(v22_ .. ".breedChickenCount", 0)
	self.statistics.breedHorsesCount.total = xmlFile:getInt(v22_ .. ".breedHorsesCount", 0)
	self.statistics.breedGoatsCount.total = xmlFile:getInt(v22_ .. ".breedGoatsCount", 0)
	self.statistics.breedWaterBuffaloCount.total = xmlFile:getInt(v22_ .. ".breedWaterBuffaloCount", 0)
	self.statistics.missionCount.total = xmlFile:getInt(v22_ .. ".missionCount", 0)
	self.statistics.plantedTreeCount.total = xmlFile:getInt(v22_ .. ".plantedTreeCount", 0)
	self.statistics.cutTreeCount.total = xmlFile:getInt(v22_ .. ".cutTreeCount", 0)
	self.statistics.woodTonsSold.total = xmlFile:getFloat(v22_ .. ".woodTonsSold", 0)
	self.statistics.treeTypesCut = xmlFile:getString(v22_ .. ".treeTypesCut", "000000")
	self.statistics.revenue.total = xmlFile:getFloat(v22_ .. ".revenue", 0)
	self.statistics.expenses.total = xmlFile:getFloat(v22_ .. ".expenses", 0)
	self.statistics.playTime.total = xmlFile:getFloat(v22_ .. ".playTime", 0)
	self.statistics.petDogCount.total = xmlFile:getInt(v22_ .. ".petDogCount", 0)
	self.statistics.repaintVehicleCount.total = xmlFile:getInt(v22_ .. ".repaintVehicleCount", 0)
	self.statistics.repairVehicleCount.total = xmlFile:getInt(v22_ .. ".repairVehicleCount", 0)
	self.statistics.tractorDistance.total = xmlFile:getFloat(v22_ .. ".tractorDistance", 0)
	self.statistics.carDistance.total = xmlFile:getFloat(v22_ .. ".carDistance", 0)
	self.statistics.truckDistance.total = xmlFile:getFloat(v22_ .. ".truckDistance", 0)
	self.statistics.horseDistance.total = xmlFile:getFloat(v22_ .. ".horseDistance", 0)
	self.statistics.horseJumpCount.total = xmlFile:getInt(v22_ .. ".horseJumpCount", 0)
	self.statistics.soldCottonBales.total = xmlFile:getInt(v22_ .. ".soldCottonBales", 0)
	self.statistics.wrappedBales.total = xmlFile:getInt(v22_ .. ".wrappedBales", 0)
	xmlFile:iterate(rootKey .. ".finances.stats", function(p23_, p24_)
		-- upvalues: (copy) xmlFile, (copy) self
		local v25_ = FinanceStats.new()
		v25_:loadFromXMLFile(xmlFile, p24_)
		if p23_ == 1 then
			self.finances = v25_
		else
			local v26_ = self.financesHistory
			table.insert(v26_, v25_)
		end
	end)
end

-- Local values: heroStatName, heroStat
function FarmStats:update(dt)
	if GS_PLATFORM_XBOX then
		if not self.heroStatsLoaded and areStatsAvailable() then
			self.heroStatsLoaded = true
			for v29_, v30_ in pairs(self.heroStats) do
				v30_.id = statsGetIndex(v29_)
				v30_.value = statsGet(v30_.id)
				if v30_.accumValue ~= 0 then
					v30_.value = v30_.value + v30_.accumValue
					statsSet(v30_.id, v30_.value)
					v30_.accumValue = 0
				end
			end
		end
		if g_time >= self.nextHeroAccumUpdate and self.moneyEarnedHeroAccum > 0 then
			self:addValueToHeroStat("moneyEarned", self.moneyEarnedHeroAccum)
			self.moneyEarnedHeroAccum = 0
			self.nextHeroAccumUpdate = g_time + 10000
		end
	end
	self:updateStats("playTime", dt / 60000, self.updatePlayTime)
end

-- Local values: heroStat
function FarmStats:addValueToHeroStat(name, value)
	local v34_ = self.heroStats[name]
	if self.heroStatsLoaded then
		v34_.value = v34_.value + value
		statsSet(v34_.id, v34_.value)
	else
		v34_.accumValue = v34_.accumValue + value
	end
end

function FarmStats:changeFinanceStats(amount, statType)
	if statType ~= nil and self.finances[statType] ~= nil then
		self.finances[statType] = self.finances[statType] + amount
		if g_currentMission:getIsServer() then
			self.financesVersionCounter = self.financesVersionCounter + 1
			if self.financesVersionCounter > 999999 then
				self.financesVersionCounter = 0
			end
		end
	end
end

function FarmStats:archiveFinances()
	if g_currentMission:getIsServer() then
		local v39_ = self.financesHistory
		local v40_ = self.finances
		table.insert(v39_, v40_)
		self.finances = FinanceStats.new()
		self.financesVersionCounter = self.financesVersionCounter + 1
		if self.financesVersionCounter > 999999 then
			self.financesVersionCounter = 0
		end
		self.financesHistoryVersionCounter = self.financesHistoryVersionCounter + 1
		if self.financesHistoryVersionCounter > 127 then
			self.financesHistoryVersionCounter = 0
		end
	end
end

function FarmStats:getCompletedMissions()
	return self:getTotalValue("missionCount")
end

function FarmStats:getCompletedMissionsSession()
	return self:getSessionValue("missionCount")
end

-- Local values: total, session
function FarmStats:updateStats(statName, delta, ignoreHeroStats)
	local v47_ = nil
	local v48_ = nil
	if delta == nil then
		printCallstack()
	end
	if self.statistics[statName] == nil then
		printError("Error: Invalid statistic \'" .. statName .. "\'")
	else
		self.statistics[statName].session = self.statistics[statName].session + delta
		v48_ = self.statistics[statName].session
		if self.statistics[statName].total ~= nil then
			self.statistics[statName].total = self.statistics[statName].total + delta
			v47_ = self.statistics[statName].total
		end
	end
	if ignoreHeroStats == nil or not ignoreHeroStats then
		self:addHeroStat(statName, delta)
	end
	return v47_, v48_
end

function FarmStats:addHeroStat(statName, delta)
	if self.heroStats[statName] == nil then
		if statName == "missionCount" then
			self:addValueToHeroStat("completedMissions", delta)
		end
		return
	elseif statName == "moneyEarned" then
		self.moneyEarnedHeroAccum = self.moneyEarnedHeroAccum + delta
	else
		self:addValueToHeroStat(statName, delta)
	end
end

function FarmStats:getTotalValue(statName)
	if self.statistics[statName] == nil then
		return nil
	else
		return self.statistics[statName].total
	end
end

function FarmStats:getSessionValue(statName)
	if self.statistics[statName] == nil then
		return nil
	else
		return self.statistics[statName].session
	end
end

-- Local values: trees, i, treeName, treeMatch, _, subTreeName, stats
function FarmStats:updateTreeTypesCut(splitTypeName)
	for v58_, v59_ in ipairs({
		"oak",
		"birch",
		"maple",
		{ "spruce", "pine" },
		"poplar",
		"ash"
	}) do
		local v60_ = false
		if type(v59_) == "table" then
			for _, v61_ in pairs(v59_) do
				if splitTypeName == v61_ then
					v60_ = true
				end
			end
		elseif splitTypeName == v59_ then
			v60_ = true
		end
		if v60_ then
			local v62_ = self.statistics
			local v63_ = v62_.treeTypesCut
			local v64_ = v58_ - 1
			local v65_ = string.sub(v63_, 1, v64_)
			local v66_ = v62_.treeTypesCut
			local v67_ = v58_ + 1
			local v68_ = v62_.treeTypesCut
			local v69_ = string.len(v68_)
			v62_.treeTypesCut = v65_ .. "1" .. string.sub(v66_, v67_, v69_)
		end
	end
end

function FarmStats:updateMissionDone()
	self:updateStats("missionCount", 1)
	self:updateJobAchievements()
end

-- Local values: missionCount
function FarmStats:updateJobAchievements()
	local v72_ = self:getTotalValue("missionCount")
	g_achievementManager:tryUnlock("MissionFirst", v72_)
	g_achievementManager:tryUnlock("Mission", v72_)
end

-- Local values: year
function FarmStats:getStatisticData()
	if not (g_currentMission.missionDynamicInfo.isMultiplayer and g_currentMission.missionDynamicInfo.isClient) then
		self:addStatistic("workedHectares", g_i18n:getAreaUnit(false), g_i18n:getArea(self:getSessionValue("workedHectares")), g_i18n:getArea(self:getTotalValue("workedHectares")), "%.2f")
		self:addStatistic("cultivatedHectares", g_i18n:getAreaUnit(false), g_i18n:getArea(self:getSessionValue("cultivatedHectares")), g_i18n:getArea(self:getTotalValue("cultivatedHectares")), "%.2f")
		self:addStatistic("plowedHectares", g_i18n:getAreaUnit(false), g_i18n:getArea(self:getSessionValue("plowedHectares")), g_i18n:getArea(self:getTotalValue("plowedHectares")), "%.2f")
		self:addStatistic("sownHectares", g_i18n:getAreaUnit(false), g_i18n:getArea(self:getSessionValue("sownHectares")), g_i18n:getArea(self:getTotalValue("sownHectares")), "%.2f")
		self:addStatistic("sprayedHectares", g_i18n:getAreaUnit(false), g_i18n:getArea(self:getSessionValue("sprayedHectares")), g_i18n:getArea(self:getTotalValue("sprayedHectares")), "%.2f")
		self:addStatistic("threshedHectares", g_i18n:getAreaUnit(false), g_i18n:getArea(self:getSessionValue("threshedHectares")), g_i18n:getArea(self:getTotalValue("threshedHectares")), "%.2f")
		self:addStatistic("harvestedOlives", "m", g_i18n:getArea(self:getSessionValue("harvestedOlives")), g_i18n:getArea(self:getTotalValue("harvestedOlives")), "%.1f")
		self:addStatistic("harvestedGrapes", "m", g_i18n:getArea(self:getSessionValue("harvestedGrapes")), g_i18n:getArea(self:getTotalValue("harvestedGrapes")), "%.1f")
		if not GS_IS_MOBILE_VERSION then
			self:addStatistic("workedTime", nil, Utils.formatTime(self:getSessionValue("workedTime")), Utils.formatTime(self:getTotalValue("workedTime")), "%s")
			self:addStatistic("cultivatedTime", nil, Utils.formatTime(self:getSessionValue("cultivatedTime")), Utils.formatTime(self:getTotalValue("cultivatedTime")), "%s")
			self:addStatistic("plowedTime", nil, Utils.formatTime(self:getSessionValue("plowedTime")), Utils.formatTime(self:getTotalValue("plowedTime")), "%s")
			self:addStatistic("sownTime", nil, Utils.formatTime(self:getSessionValue("sownTime")), Utils.formatTime(self:getTotalValue("sownTime")), "%s")
			self:addStatistic("sprayedTime", nil, Utils.formatTime(self:getSessionValue("sprayedTime")), Utils.formatTime(self:getTotalValue("sprayedTime")), "%s")
			self:addStatistic("threshedTime", nil, Utils.formatTime(self:getSessionValue("threshedTime")), Utils.formatTime(self:getTotalValue("threshedTime")), "%s")
		end
		self:addStatistic("traveledDistance", g_i18n:getMeasuringUnit(), g_i18n:getDistance(self:getSessionValue("traveledDistance")), g_i18n:getDistance(self:getTotalValue("traveledDistance")), "%.2f")
		self:addStatistic("fuelUsage", g_i18n:getText("unit_liter"), g_i18n:getFluid(self:getSessionValue("fuelUsage")), g_i18n:getFluid(self:getTotalValue("fuelUsage")), "%.2f")
		self:addStatistic("seedUsage", g_i18n:getText("unit_liter"), g_i18n:getFluid(self:getSessionValue("seedUsage")), g_i18n:getFluid(self:getTotalValue("seedUsage")), "%.2f")
		self:addStatistic("sprayUsage", g_i18n:getText("unit_liter"), g_i18n:getFluid(self:getSessionValue("sprayUsage")), g_i18n:getFluid(self:getTotalValue("sprayUsage")), "%.2f")
		self:addStatistic("baleCount", nil, self:getSessionValue("baleCount"), self:getTotalValue("baleCount"), "%d")
		self:addStatistic("plantedTreeCount", nil, self:getSessionValue("plantedTreeCount"), self:getTotalValue("plantedTreeCount"), "%d")
		self:addStatistic("cutTreeCount", nil, self:getSessionValue("cutTreeCount"), self:getTotalValue("cutTreeCount"), "%d")
		if not GS_IS_MOBILE_VERSION then
			self:addStatistic("missionCount", nil, self:getSessionValue("missionCount"), self:getTotalValue("missionCount"), "%d")
		end
		self:addStatistic("playTime", nil, Utils.formatTime(self:getSessionValue("playTime")), Utils.formatTime(self:getTotalValue("playTime")), "%s")
		local v74_ = g_currentMission.environment.currentYear
		if g_currentMission.environment.currentPeriod >= SeasonPeriod.MID_WINTER then
			v74_ = v74_ + 1
		end
		self:addStatistic("yearsPlayed", nil, nil, v74_, "%s")
		self:addStatistic("workersHired", nil, self:getSessionValue("workersHired"), nil, "%s")
		self:addStatistic("storedBales", nil, self:getSessionValue("storedBales"), nil, "%s")
		self:addStatistic("storedPallets", nil, self:getSessionValue("storedPallets"), nil, "%s")
		if g_currentMission.collectiblesSystem:getIsActive() then
			self:addStatistic("collectibles", nil, nil, g_currentMission.collectiblesSystem:getTotalCollected() .. " / " .. g_currentMission.collectiblesSystem:getTotalCollectable(), "%s")
		end
	end
	return Utils.getNoNil(self.statisticData, {})
end

-- Local values: formattedName, newDataSet
function FarmStats:addStatistic(name, unit, valueSession, valueTotal, stringFormat, customEnv)
	if self.statisticData == nil then
		self.statisticData = {}
		self.statisticDataRev = {}
	end
	local v82_ = g_i18n:getText("statistic_" .. name, customEnv or g_currentMission.missionInfo.customEnvironment)
	if unit ~= nil then
		v82_ = v82_ .. " [" .. unit .. "]"
	end
	local v83_ = self.statisticDataRev[name]
	if v83_ == nil then
		v83_ = {}
		self.statisticDataRev[name] = v83_
		local v84_ = self.statisticData
		table.insert(v84_, v83_)
	end
	v83_.name = v82_
	v83_.valueSession = string.format(stringFormat, Utils.getNoNil(valueSession, ""))
	v83_.valueTotal = string.format(stringFormat, Utils.getNoNil(valueTotal, ""))
end

-- Local values: _, statName, cut, i
function FarmStats:merge(other)
	for _, v87_ in ipairs(FarmStats.STAT_NAMES) do
		if v87_ == "treeTypesCut" then
			local v88_ = self.statistics.treeTypesCut
			for v89_ = 1, string.len(v88_) do
				local v90_ = other.statistics.treeTypesCut
				if string.sub(v90_, v89_, v89_) == "1" then
					local v91_ = v89_ - 1
					local v92_ = string.sub(v88_, 1, v91_)
					local v93_ = v89_ + 1
					local v94_ = string.len(v88_)
					v88_ = v92_ .. "1" .. string.sub(v88_, v93_, v94_)
				end
			end
			self.statistics.treeTypesCut = v88_
		else
			self.statistics[v87_].total = self.statistics[v87_].total + other.statistics[v87_].total
		end
	end
	self.finances:merge(other.finances)
	return self
end
