FertilizingSowingMachine = {}
FertilizingSowingMachine.CLIENT_DM_UPDATE_RADIUS = 50

function FertilizingSowingMachine.prerequisitesPresent(specializations)
	local v2_ = SpecializationUtil.hasSpecialization(SowingMachine, specializations)
	if v2_ then
		v2_ = SpecializationUtil.hasSpecialization(Sprayer, specializations)
	end
	return v2_
end
function FertilizingSowingMachine.initSpecialization()
	local v3_ = Vehicle.xmlSchema
	v3_:setXMLSpecializationType("FertilizingSowingMachine")
	v3_:register(XMLValueType.BOOL, "vehicle.fertilizingSowingMachine#needsSetIsTurnedOn", "Needs to be turned on to spray", false)
	v3_:setXMLSpecializationType()
end

function FertilizingSowingMachine.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "processSowingMachineArea", FertilizingSowingMachine.processSowingMachineArea)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getUseSprayerAIRequirements", FertilizingSowingMachine.getUseSprayerAIRequirements)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAreEffectsVisible", FertilizingSowingMachine.getAreEffectsVisible)
end

function FertilizingSowingMachine.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", FertilizingSowingMachine)
end

-- Local values: spec
function FertilizingSowingMachine:onLoad(savegame)
	self.spec_fertilizingSowingMachine.needsSetIsTurnedOn = self.xmlFile:getValue("vehicle.fertilizingSowingMachine#needsSetIsTurnedOn", false)
	self.spec_sprayer.needsToBeFilledToTurnOn = false
	self.spec_sprayer.useSpeedLimit = false
	self.needWaterInfo = true
end

-- Local values: spec, specSowingMachine, specSpray, sprayerParams, sowingParams, changedArea, totalArea, rootVehicle, rootVehicle, rootVehicle, rootVehicle, startX, _, startZ, widthX, _, widthZ, heightX, _, heightZ, sprayTypeIndex, fruitTypeDesc, cx, cz, rootVehicle, sprayAmount, sprayChangedArea, sprayTotalArea, farmId, ha
function FertilizingSowingMachine:processSowingMachineArea(superFunc, workArea, dt)
	local v10_ = self.spec_fertilizingSowingMachine
	local v11_ = self.spec_sowingMachine
	local v12_ = self.spec_sprayer
	local v13_ = v12_.workAreaParameters
	local v14_ = v11_.workAreaParameters
	self.spec_sowingMachine.isWorking = self:getLastSpeed() > 0.5
	if v11_.waterSeeding and not self.isInWater then
		v11_.showWaterPlantingRequiredWarning = true
		if self:getIsAIActive() then
			self.rootVehicle:stopCurrentAIJob(AIMessageErrorNoFieldFound.new())
		end
		return 0, 0
	end
	if not v11_.waterSeeding and self.isInWater then
		v11_.showWaterPlantingProhibitedWarning = true
		if self:getIsAIActive() then
			self.rootVehicle:stopCurrentAIJob(AIMessageErrorNoFieldFound.new())
		end
		return 0, 0
	end
	if not v14_.isActive then
		return 0, 0
	end
	if not (self:getIsAIActive() and g_currentMission.missionInfo.helperBuySeeds) and v14_.seedsVehicle == nil then
		if self:getIsAIActive() then
			self.rootVehicle:stopCurrentAIJob(AIMessageErrorOutOfFill.new())
		end
		return 0, 0
	end
	if (v12_.isSlurryTanker and g_currentMission.missionInfo.helperSlurrySource == 1 or (v12_.isManureSpreader and g_currentMission.missionInfo.helperManureSource == 1 or v12_.isFertilizerSprayer and not g_currentMission.missionInfo.helperBuyFertilizer)) and self:getIsAIActive() then
		if v13_.sprayFillType == nil or v13_.sprayFillType == FillType.UNKNOWN then
			if v13_.lastAIHasSprayed ~= nil then
				self.rootVehicle:stopCurrentAIJob(AIMessageErrorOutOfFill.new())
				v13_.lastAIHasSprayed = nil
			end
		else
			v13_.lastAIHasSprayed = true
		end
	end
	if not v14_.canFruitBePlanted then
		return 0, 0
	end
	local v15_, _, v16_ = getWorldTranslation(workArea.start)
	local v17_, _, v18_ = getWorldTranslation(workArea.width)
	local v19_, _, v20_ = getWorldTranslation(workArea.height)
	FSDensityMapUtil.eraseTireTrack(v15_, v16_, v17_, v18_, v19_, v20_)
	if not self.isServer and self.currentUpdateDistance > FertilizingSowingMachine.CLIENT_DM_UPDATE_RADIUS then
		return 0, 0
	end
	local v21_ = SprayType.FERTILIZER
	if v13_.sprayFillLevel <= 0 or v10_.needsSetIsTurnedOn and not self:getIsTurnedOn() then
		v21_ = nil
	end
	local v22_ = g_fruitTypeManager:getFruitTypeByIndex(v11_.workAreaParameters.seedsFruitType)
	if v22_.seedRequiredFieldType ~= nil then
		local v23_ = (v15_ + v17_ + v19_) / 3
		local v24_ = (v16_ + v18_ + v20_) / 3
		if FSDensityMapUtil.getFieldTypeAtWorldPos(v23_, v24_) ~= v22_.seedRequiredFieldType then
			if v22_.seedRequiredFieldType == FieldType.RICE then
				v11_.showFieldTypeWarningRiceRequired = true
			else
				v11_.showFieldTypeWarningRegularRequired = true
			end
			if self:getIsAIActive() then
				self.rootVehicle:stopCurrentAIJob(AIMessageErrorNoFieldFound.new())
			end
		end
	end
	local v25_, v26_
	if v11_.useDirectPlanting then
		v25_, v26_ = FSDensityMapUtil.updateDirectSowingArea(v14_.seedsFruitType, v15_, v16_, v17_, v18_, v19_, v20_, v14_.fieldGroundType, v14_.ridgeSeeding, v14_.angle, nil, v21_)
	else
		v25_, v26_ = FSDensityMapUtil.updateSowingArea(v14_.seedsFruitType, v15_, v16_, v17_, v18_, v19_, v20_, v14_.fieldGroundType, v14_.ridgeSeeding, v14_.angle, nil, v21_)
	end
	self.spec_sowingMachine.isProcessing = self.spec_sowingMachine.isWorking
	if v21_ ~= nil then
		local v27_ = v12_.doubledAmountIsActive and 2 or 1
		local v28_, v29_ = FSDensityMapUtil.updateSprayArea(v15_, v16_, v17_, v18_, v19_, v20_, v21_, v27_)
		v13_.lastChangedArea = v13_.lastChangedArea + v28_
		v13_.lastTotalArea = v13_.lastTotalArea + v29_
		v13_.lastStatsArea = 0
		v13_.isActive = true
		v13_.lastSprayTime = g_time
		local v30_ = self:getLastTouchedFarmlandFarmId()
		local v31_ = MathUtil.areaToHa(v13_.lastChangedArea, g_currentMission:getFruitPixelsToSqm())
		g_farmManager:updateFarmStats(v30_, "sprayedHectares", v31_)
		g_farmManager:updateFarmStats(v30_, "sprayedTime", dt / 60000)
		g_farmManager:updateFarmStats(v30_, "sprayUsage", v13_.usage)
	end
	v14_.lastChangedArea = v14_.lastChangedArea + v25_
	v14_.lastStatsArea = v14_.lastStatsArea + v25_
	v14_.lastTotalArea = v14_.lastTotalArea + v26_
	self:updateMissionSowingWarning(v15_, v16_)
	return v25_, v26_
end

function FertilizingSowingMachine:getUseSprayerAIRequirements(superFunc)
	return false
end

function FertilizingSowingMachine:getAreEffectsVisible(superFunc)
	local v34_ = superFunc(self)
	if v34_ then
		v34_ = self:getFillUnitFillType(self:getSprayerFillUnitIndex()) ~= FillType.UNKNOWN
	end
	return v34_
end
