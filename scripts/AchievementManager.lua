-- Local values: AchievementManager_mt
AchievementManager = {}
local AchievementManager_mt = Class(AchievementManager, AbstractManager)

-- Upvalues: AchievementManager_mt
-- Local values: self
function AchievementManager.new(customMt)
	-- upvalues: (copy) AchievementManager_mt
	return AbstractManager.new(customMt or AchievementManager_mt)
end

function AchievementManager:initDataStructures()
	self.achievementList = {}
	self.achievementListById = {}
	self.achievementListByName = {}
	self.pendingAchievements = {}
	self.numberOfAchievements = 0
	self.numberOfUnlockedAchievements = 0
	self.achievementsValid = false
	self.achievementTimer = 0
	self.achievementTimeInterval = 30000
	self.fillTypeAchievements = {}
end

-- Local values: xmlFile, usePlatinum, xmlFileContent, _achievementIndex, key, id, idName, score, targetScore, showScore, imageFilename, imageSize, imageUVs, psnType, name, description, lockedImageSize
function AchievementManager:load()
	local v5_ = XMLFile.load("achievementsXML", "dataS/achievements.xml")
	if v5_ == nil then
		return false
	end
	local v6_ = GS_PLATFORM_PLAYSTATION
	local v7_ = v5_:getAsString()
	initAchievements(v7_)
	self.numberOfAchievements = 0
	for _, v8_ in v5_:iterator("achievements.achievement") do
		local v9_ = v5_:getInt(v8_ .. "#id")
		if v9_ == nil then
			Logging.xmlDevWarning(v5_, "Missing or non-integer \'id\' for achievement \'%s\'", v8_)
		else
			local v10_ = v5_:getString(v8_ .. "#idName")
			if string.isNilOrWhitespace(v10_) then
				Logging.xmlDevWarning(v5_, "Missing \'idName\' for achievement \'%s\'", v8_)
			else
				local v11_ = v5_:getInt(v8_ .. "#score")
				local v12_ = v5_:getInt(v8_ .. "#targetScore")
				local v13_ = v5_:getBool(v8_ .. "#showScore")
				local v14_ = v5_:getString(v8_ .. "#imageFilename")
				local v15_ = string.getVector(v5_:getString(v8_ .. "#imageSize"), 2) or { 2048, 2048 }
				local v16_ = GuiUtils.getUVs(v5_:getString(v8_ .. "#imageUVs") or "0 0 1 1", v15_)
				if (v5_:getString(v8_ .. "#psn_type") or "") ~= "P" or v6_ then
					local v17_ = g_i18n:getText("achievement_name" .. v10_)
					local v18_ = g_i18n:getText("achievement_desc" .. v10_)
					local v19_ = string.gsub(v18_, "$MEASURING_UNIT", g_i18n:getMeasuringUnit(true))
					self:addAchievement(v9_, v10_, v17_, string.gsub(v19_, "$CURRENCY_SYMBOL", g_i18n:getCurrencySymbol(true)), v11_, v12_, v13_, v14_, v16_)
				end
			end
		end
	end
	local v20_ = string.getVector(v5_:getString("achievements#lockedImageSize"), 2) or { 2048, 2048 }
	self.lockedImage = v5_:getString("achievements#lockedImageFilename")
	self.lockedUVs = GuiUtils.getUVs(v5_:getString("achievements#lockedImageUVs") or "0 0 1 1", v20_)
	v5_:delete()
	if areAchievementsAvailable() then
		self:loadAchievementsState(false)
	end
	return true
end

-- Local values: mission, isNewSPCareer, stats, farm, _, fillType, achievementName, fillTypeAchievement
function AchievementManager:loadMapData()
	local v22_ = g_currentMission
	local v23_ = v22_.missionInfo.isNewSPCareer
	if v23_ then
		self.startPlayTime = nil
		self.startMoney = nil
		self.startMissionCount = nil
		self.startCultivatedHectares = nil
		self.startSownHectares = nil
		self.startFertilizedHectares = nil
		self.startThreshedHectares = nil
		self.startCutTreeCount = nil
		self.startBreedCowsCount = nil
		self.startBreedSheepCount = nil
		self.startBreedPigsCount = nil
		self.startBreedChickenCount = nil
		self.startPetDogCount = nil
		self.startTractorDistance = nil
		self.startTruckDistance = nil
		self.startCarDistance = nil
		self.startRepairVehicleCount = nil
		self.startRepaintVehicleCount = nil
		self.startHorseDistance = nil
		self.startHorseJumpCount = nil
		self.startSoldCottonBales = nil
		self.startWrappedBales = nil
	else
		local v24_ = v22_:farmStats()
		local v25_ = v24_:getTotalValue("playTime") / 60 + 0.0001
		self.startPlayTime = math.floor(v25_)
		self.startMoney = g_farmManager:getFarmById(0).money
		self.startMissionCount = v24_:getTotalValue("missionCount")
		self.startCultivatedHectares = v24_:getTotalValue("cultivatedHectares")
		self.startSownHectares = v24_:getTotalValue("sownHectares")
		self.startFertilizedHectares = v24_:getTotalValue("sprayedHectares")
		self.startThreshedHectares = v24_:getTotalValue("threshedHectares")
		self.startCutTreeCount = v24_:getTotalValue("cutTreeCount")
		self.startBreedCowsCount = v24_:getTotalValue("breedCowsCount")
		self.startBreedSheepCount = v24_:getTotalValue("breedSheepCount")
		self.startBreedPigsCount = v24_:getTotalValue("breedPigsCount")
		self.startBreedChickenCount = v24_:getTotalValue("breedChickenCount")
		self.startPetDogCount = v24_:getTotalValue("petDogCount")
		self.startTractorDistance = v24_:getTotalValue("tractorDistance")
		self.startTruckDistance = v24_:getTotalValue("truckDistance")
		self.startCarDistance = v24_:getTotalValue("carDistance")
		self.startRepairVehicleCount = v24_:getTotalValue("repairVehicleCount")
		self.startRepaintVehicleCount = v24_:getTotalValue("repaintVehicleCount")
		self.startHorseDistance = v24_:getTotalValue("horseDistance")
		self.startHorseJumpCount = v24_:getTotalValue("horseJumpCount")
		self.startSoldCottonBales = v24_:getTotalValue("soldCottonBales")
		self.startWrappedBales = v24_:getTotalValue("wrappedBales")
	end
	self.fillTypeAchievements = {}
	for _, v26_ in ipairs(g_fillTypeManager:getFillTypes()) do
		local v27_ = v26_.achievementName
		if v27_ ~= nil and self.achievementListByName[v27_] ~= nil then
			local v28_ = {
				["name"] = v27_,
				["fillType"] = v26_
			}
			if not v23_ then
				v28_.startValue = v26_.totalAmount
			end
			local v29_ = self.fillTypeAchievements
			table.insert(v29_, v28_)
		end
	end
	return true
end

-- Local values: achievement
function AchievementManager:addAchievement(id, idName, name, description, score, targetScore, showScore, imageFilename, imageUVs)
	local v40_ = {
		["id"] = id,
		["idName"] = idName,
		["name"] = name,
		["description"] = description,
		["score"] = score,
		["targetScore"] = targetScore,
		["showScore"] = showScore,
		["imageFilename"] = imageFilename,
		["imageUVs"] = imageUVs,
		["unlocked"] = false
	}
	local v41_ = self.achievementList
	table.insert(v41_, v40_)
	self.achievementListById[id] = v40_
	self.achievementListByName[idName] = v40_
	self.numberOfAchievements = self.numberOfAchievements + 1
	return v40_
end

-- Local values: _, achievement
function AchievementManager:resetAchievementsState()
	self.numberOfUnlockedAchievements = 0
	for _, v43_ in pairs(self.achievementList) do
		v43_.unlocked = false
	end
	self.achievementsValid = false
end

-- Local values: _, achievement, oldUnlocked
function AchievementManager:loadAchievementsState(showGui)
	self.numberOfUnlockedAchievements = 0
	for _, v46_ in pairs(self.achievementList) do
		local v47_ = v46_.unlocked
		v46_.unlocked = getAchievement(v46_.id)
		if v46_.unlocked then
			if not v47_ and (showGui and not hasNativeAchievementGUI()) then
				g_messageCenter:publish(MessageType.ACHIEVEMENT_UNLOCKED, v46_.name, v46_.description, v46_.imageFilename, v46_.imageUVs)
			end
			self.numberOfUnlockedAchievements = self.numberOfUnlockedAchievements + 1
		end
	end
	self.achievementsValid = true
end

-- Local values: currentAchievement, ignoreAchievement, mission
function AchievementManager:handleStandardScoreAchievement(idName, currentScore, startScore)
	local v52_ = self.achievementListByName[idName]
	if v52_ ~= nil and not v52_.unlocked and (g_currentMission.missionInfo.isNewSPCareer or (startScore == nil or currentScore ~= startScore)) then
		v52_.score = currentScore
		setAchievementProgress(v52_.id, v52_.score, v52_.targetScore)
		if not areAchievementsAvailable() then
			self.pendingAchievements[v52_] = true
		end
	end
end

-- Local values: currentAchievement
function AchievementManager:tryUnlock(idName, score)
	if self:getCanUnlockAchievement() then
		local v56_ = self.achievementListByName[idName]
		if v56_ ~= nil and not v56_.unlocked then
			v56_.score = score
			setAchievementProgress(v56_.id, score, v56_.targetScore)
			if not areAchievementsAvailable() then
				self.pendingAchievements[v56_] = true
			end
		end
	end
end

-- Local values: achievement, _
function AchievementManager:update(dt)
	if areAchievementsAvailable() then
		for v59_, _ in pairs(self.pendingAchievements) do
			self:tryUnlock(v59_.id, v59_.score)
			self.pendingAchievements[v59_] = nil
		end
		if getHaveAchievementsChanged() then
			self.achievementsValid = false
		end
		if not self.achievementsValid then
			self:loadAchievementsState(true)
		end
		if self:getCanUnlockAchievement() then
			self:updateAchievements(dt)
		end
	end
end

-- Local values: mission
function AchievementManager:getCanUnlockAchievement()
	local v60_ = g_currentMission
	if v60_ == nil then
		return false
	elseif v60_.missionInfo:isa(FSCareerMissionInfo) then
		if v60_.missionDynamicInfo.isMultiplayer then
			return false
		else
			return v60_.gameStarted and true or false
		end
	else
		return false
	end
end

-- Local values: mission, farm, stats, cultivatedHectares, sownHectares, sprayedHectares, threshedHectares, horseRiding, _, fillTypeAchievement
function AchievementManager:updateAchievements(dt)
	self.achievementTimer = self.achievementTimer + dt
	if self.achievementTimer >= self.achievementTimeInterval then
		local v63_ = g_currentMission
		local v64_ = g_farmManager:getFarmById(v63_:getFarmId())
		if v64_ == nil then
			return
		end
		local v65_ = v64_.stats
		local v66_ = v65_:getTotalValue("playTime") / 60 + 0.0001
		self:handleStandardScoreAchievement("PlayTime", math.floor(v66_), self.startPlayTime)
		self:handleStandardScoreAchievement("Money", v64_.money, self.startMoney)
		local v67_ = v65_:getTotalValue("cultivatedHectares")
		self:handleStandardScoreAchievement("CultivateFirst", v67_, self.startCultivatedHectares)
		self:handleStandardScoreAchievement("Cultivate", v67_, self.startCultivatedHectares)
		local v68_ = v65_:getTotalValue("sownHectares")
		self:handleStandardScoreAchievement("SowFirst", v68_, self.startSownHectares)
		self:handleStandardScoreAchievement("Sow", v68_, self.startSownHectares)
		local v69_ = v65_:getTotalValue("sprayedHectares")
		self:handleStandardScoreAchievement("FertilizeFirst", v69_, self.startFertilizedHectares)
		self:handleStandardScoreAchievement("Fertilize", v69_, self.startFertilizedHectares)
		local v70_ = v65_:getTotalValue("threshedHectares")
		self:handleStandardScoreAchievement("HarvestedFirst", v70_, self.startThreshedHectares)
		self:handleStandardScoreAchievement("Harvested", v70_, self.startThreshedHectares)
		self:handleStandardScoreAchievement("BreedCows", v65_:getTotalValue("breedCowsCount"), self.startBreedCowsCount)
		self:handleStandardScoreAchievement("BreedSheep", v65_:getTotalValue("breedSheepCount"), self.startBreedSheepCount)
		self:handleStandardScoreAchievement("BreedPigs", v65_:getTotalValue("breedPigsCount"), self.startBreedPigsCount)
		self:handleStandardScoreAchievement("BreedChicken", v65_:getTotalValue("breedChickenCount"), self.startBreedChickenCount)
		self:handleStandardScoreAchievement("TractorDriving", v65_:getTotalValue("tractorDistance"), self.startTractorDistance)
		self:handleStandardScoreAchievement("TruckDriving", v65_:getTotalValue("truckDistance"), self.startTruckDistance)
		self:handleStandardScoreAchievement("CarDriving", v65_:getTotalValue("carDistance"), self.startCarDistance)
		local v71_ = v65_:getTotalValue("horseDistance")
		self:handleStandardScoreAchievement("HorseRidingFirst", v71_, self.startHorseDistance)
		self:handleStandardScoreAchievement("HorseRiding", v71_, self.startHorseDistance)
		for _, v72_ in ipairs(self.fillTypeAchievements) do
			self:handleStandardScoreAchievement(v72_.name, v72_.fillType.totalAmount, v72_.startValue)
		end
		self.achievementTimer = 0
	end
end

function AchievementManager:getLockedImageData()
	return self.lockedImage, self.lockedUVs
end
