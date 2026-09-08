FertilizingCultivator = {}
FertilizingCultivator.CLIENT_DM_UPDATE_RADIUS = 50

function FertilizingCultivator.prerequisitesPresent(specializations)
	local v2_ = SpecializationUtil.hasSpecialization(Cultivator, specializations)
	if v2_ then
		v2_ = SpecializationUtil.hasSpecialization(Sprayer, specializations)
	end
	return v2_
end
function FertilizingCultivator.initSpecialization()
	local v3_ = Vehicle.xmlSchema
	v3_:setXMLSpecializationType("FertilizingCultivator")
	v3_:register(XMLValueType.BOOL, "vehicle.fertilizingCultivator#needsSetIsTurnedOn", "Needs to be turned on to spray", false)
	v3_:setXMLSpecializationType()
end

function FertilizingCultivator.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "processCultivatorArea", FertilizingCultivator.processCultivatorArea)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "setSprayerAITerrainDetailProhibitedRange", FertilizingCultivator.setSprayerAITerrainDetailProhibitedRange)
end

function FertilizingCultivator.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", FertilizingCultivator)
end

-- Local values: spec
function FertilizingCultivator:onLoad(savegame)
	self.spec_fertilizingCultivator.needsSetIsTurnedOn = self.xmlFile:getValue("vehicle.fertilizingCultivator#needsSetIsTurnedOn", false)
	self.spec_sprayer.useSpeedLimit = false
	self:clearAITerrainDetailRequiredRange()
	self:updateCultivatorAIRequirements()
end

-- Local values: spec, specCultivator, specSpray, cultivatorParams, sprayerParams, rootVehicle, xs, _, zs, xw, _, zw, xh, _, zh, sprayTypeIndex, cultivatorChangedArea, cultivatorTotalArea, sprayAmount, sprayChangedArea, sprayTotalArea
function FertilizingCultivator:processCultivatorArea(superFunc, workArea, dt)
	local v9_ = self.spec_fertilizingCultivator
	local v10_ = self.spec_cultivator
	local v11_ = self.spec_sprayer
	local v12_ = v10_.workAreaParameters
	local v13_ = v11_.workAreaParameters
	if (v11_.isSlurryTanker and g_currentMission.missionInfo.helperSlurrySource == 1 or (v11_.isManureSpreader and g_currentMission.missionInfo.helperManureSource == 1 or v11_.isFertilizerSprayer and not g_currentMission.missionInfo.helperBuyFertilizer)) and self:getIsAIActive() then
		if v13_.sprayFillType == nil or v13_.sprayFillType == FillType.UNKNOWN then
			if v13_.lastAIHasSprayed ~= nil then
				self.rootVehicle:stopCurrentAIJob(AIMessageErrorOutOfFill.new())
				v13_.lastAIHasSprayed = nil
			end
		else
			v13_.lastAIHasSprayed = true
		end
	end
	local v14_, _, v15_ = getWorldTranslation(workArea.start)
	local v16_, _, v17_ = getWorldTranslation(workArea.width)
	local v18_, _, v19_ = getWorldTranslation(workArea.height)
	FSDensityMapUtil.eraseTireTrack(v14_, v15_, v16_, v17_, v18_, v19_)
	if not self.isServer and self.currentUpdateDistance > FertilizingCultivator.CLIENT_DM_UPDATE_RADIUS then
		return 0, 0
	end
	local v20_ = SprayType.FERTILIZER
	if v13_.sprayFillLevel <= 0 or v9_.needsSetIsTurnedOn and not self:getIsTurnedOn() then
		v20_ = nil
	end
	local v21_, v22_
	if v10_.isEnabled then
		if v10_.useDeepMode then
			local v23_
			v23_, v21_ = FSDensityMapUtil.updateCultivatorArea(v14_, v15_, v16_, v17_, v18_, v19_, not v12_.limitToField, v12_.limitFruitDestructionToField, v12_.angle, v20_)
			v22_ = v23_ + FSDensityMapUtil.updateVineCultivatorArea(v14_, v15_, v16_, v17_, v18_, v19_)
		else
			local v24_
			v24_, v21_ = FSDensityMapUtil.updateDiscHarrowArea(v14_, v15_, v16_, v17_, v18_, v19_, not v12_.limitToField, v12_.limitFruitDestructionToField, v12_.angle, v20_)
			v22_ = v24_ + FSDensityMapUtil.updateVineCultivatorArea(v14_, v15_, v16_, v17_, v18_, v19_)
		end
		v12_.lastChangedArea = v12_.lastChangedArea + v22_
		v12_.lastTotalArea = v12_.lastTotalArea + v21_
		v12_.lastStatsArea = v12_.lastStatsArea + v22_
	else
		v22_ = 0
		v21_ = 0
	end
	if v10_.isSubsoiler then
		FSDensityMapUtil.updateSubsoilerArea(v14_, v15_, v16_, v17_, v18_, v19_)
	end
	if v20_ ~= nil then
		local v25_ = v11_.doubledAmountIsActive and 2 or 1
		local v26_, v27_ = FSDensityMapUtil.updateSprayArea(v14_, v15_, v16_, v17_, v18_, v19_, v20_, v25_)
		v13_.lastChangedArea = v13_.lastChangedArea + v26_
		v13_.lastTotalArea = v13_.lastTotalArea + v27_
		v13_.lastStatsArea = 0
		v13_.isActive = true
	end
	v10_.isWorking = self:getLastSpeed() > 0.5
	return v22_, v21_
end

-- Local values: sprayTypeDesc, mission, sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels, sprayLevelMapId, sprayLevelFirstChannel, sprayLevelNumChannels, sprayLevelMaxValue
function FertilizingCultivator:setSprayerAITerrainDetailProhibitedRange(superFunc, fillType)
	if self.addAITerrainDetailProhibitedRange ~= nil then
		self:clearAITerrainDetailProhibitedRange()
		local v30_ = g_sprayTypeManager:getSprayTypeByFillTypeIndex(fillType)
		if v30_ ~= nil then
			local v31_ = g_currentMission
			local v32_, v33_, v34_ = v31_.fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_TYPE)
			local v35_, v36_, v37_ = v31_.fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_LEVEL)
			local v38_ = v31_.fieldGroundSystem:getMaxValue(FieldDensityMap.SPRAY_LEVEL)
			self:addAIFruitProhibitions(0, v30_.sprayGroundType, v30_.sprayGroundType, v32_, v33_, v34_)
			self:addAIFruitProhibitions(0, v38_, v38_, v35_, v36_, v37_)
		end
	end
end
