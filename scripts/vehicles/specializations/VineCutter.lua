VineCutter = {}
function VineCutter.initSpecialization()
	g_vehicleConfigurationManager:addConfigurationType("vineCutter", g_i18n:getText("shop_configuration"), "vineCutter", VehicleConfigurationItem)
	local v1_ = Vehicle.xmlSchema
	v1_:setXMLSpecializationType("VineCutter")
	v1_:register(XMLValueType.STRING, "vehicle.vineCutter#fruitType", "Fruit type")
	v1_:register(XMLValueType.STRING, "vehicle.vineCutter.vineCutterConfigurations.vineCutterConfiguration(?)#fruitType", "Fruit type")
	v1_:setXMLSpecializationType()
end

function VineCutter.prerequisitesPresent(specializations)
	return SpecializationUtil.hasSpecialization(VineDetector, specializations)
end

function VineCutter.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "getCombine", VineCutter.getCombine)
	SpecializationUtil.registerFunction(vehicleType, "harvestCallback", VineCutter.harvestCallback)
end

function VineCutter.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "doCheckSpeedLimit", VineCutter.doCheckSpeedLimit)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanStartVineDetection", VineCutter.getCanStartVineDetection)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsValidVinePlaceable", VineCutter.getIsValidVinePlaceable)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "handleVinePlaceable", VineCutter.handleVinePlaceable)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "clearCurrentVinePlaceable", VineCutter.clearCurrentVinePlaceable)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAIImplementUseVineSegment", VineCutter.getAIImplementUseVineSegment)
end

function VineCutter.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", VineCutter)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", VineCutter)
	SpecializationUtil.registerEventListener(vehicleType, "onDraw", VineCutter)
	SpecializationUtil.registerEventListener(vehicleType, "onTurnedOff", VineCutter)
end

-- Local values: spec, configurationId, configKey, fruitTypeName, fruitType
function VineCutter:onLoad(savegame)
	local v7_ = self.spec_vineCutter
	local v8_ = self.configurations.vineCutter or 1
	local v9_ = string.format("vehicle.vineCutter.vineCutterConfigurations.vineCutterConfiguration(%d)", v8_ - 1)
	local v10_ = self.xmlFile:getValue(v9_ .. "#fruitType")
	if v10_ == nil then
		v10_ = self.xmlFile:getValue("vehicle.vineCutter#fruitType")
	end
	local v11_ = g_fruitTypeManager:getFruitTypeByName(v10_)
	if v11_ == nil then
		v7_.inputFruitTypeIndex = FruitType.GRAPE
	else
		v7_.inputFruitTypeIndex = v11_.index
	end
	v7_.outputFillTypeIndex = g_fruitTypeManager:getFillTypeIndexByFruitTypeIndex(v7_.inputFruitTypeIndex)
	v7_.showFarmlandNotOwnedWarning = false
	v7_.warningYouDontHaveAccessToThisLand = g_i18n:getText("warning_youDontHaveAccessToThisLand")
end

function VineCutter:onPostLoad(savegame)
	if self.addCutterToCombine ~= nil then
		self:addCutterToCombine(self)
	end
end

-- Local values: spec
function VineCutter:onDraw(isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v14_ = self.spec_vineCutter
	if v14_.showFarmlandNotOwnedWarning then
		g_currentMission:showBlinkingWarning(v14_.warningYouDontHaveAccessToThisLand)
	end
end

-- Local values: spec
function VineCutter:onTurnedOff()
	self:cancelVineDetection()
	local v16_ = self.spec_vineCutter
	if v16_.lastHarvestingPlaceable ~= nil and v16_.lastHarvestingNode ~= nil then
		v16_.lastHarvestingPlaceable:setShakingFactor(v16_.lastHarvestingNode, 0, 0, 0, 0)
	end
	v16_.showFarmlandNotOwnedWarning = false
end

-- Local values: isTurnedOn
function VineCutter:getCanStartVineDetection(superFunc)
	if superFunc(self) then
		if self:getIsTurnedOn() then
			return self.movingDirection >= 0
		else
			return false
		end
	else
		return false
	end
end

-- Local values: spec
function VineCutter:getIsValidVinePlaceable(superFunc, placeable)
	if not superFunc(self, placeable) then
		return false
	end
	local v22_ = self.spec_vineCutter
	return placeable:getVineFruitType() == v22_.inputFruitTypeIndex
end

-- Local values: spec, farmlandId, landOwner, farmId, accessible, combineVehicle, alternativeCombine, requiredFillType, startPosX, startPosY, startPosZ, currentPosX, currentPosY, currentPosZ
function VineCutter:handleVinePlaceable(superFunc, node, placeable, x, y, z, distance)
	local v31_ = self.spec_vineCutter
	v31_.showFarmlandNotOwnedWarning = false
	if not superFunc(self, node, placeable, x, y, z, distance) then
		return false
	end
	local v32_ = g_farmlandManager:getFarmlandIdAtWorldPosition(x, z)
	if v32_ == nil then
		v31_.showFarmlandNotOwnedWarning = true
		return false
	end
	if v32_ == FarmlandManager.NOT_BUYABLE_FARM_ID then
		v31_.showFarmlandNotOwnedWarning = true
		return false
	end
	local v33_ = g_farmlandManager:getFarmlandOwner(v32_)
	local v34_ = self:getOwnerFarmId()
	local v35_
	if v33_ == 0 then
		v35_ = false
	else
		v35_ = g_currentMission.accessHandler:canFarmAccessOtherId(v34_, v33_)
	end
	if not v35_ then
		v31_.showFarmlandNotOwnedWarning = true
		return false
	end
	local v37_, v37_, v38_ = self:getCombine()
	if v37_ == nil then
		local _ = v38_ == nil
	end
	if v37_ == nil then
		if v31_.lastHarvestingNode ~= nil then
			v31_.lastHarvestingPlaceable:setShakingFactor(v31_.lastHarvestingNode, 0, 0, 0, 0)
		end
		return false
	end
	if placeable == nil then
		return false
	end
	local v39_, v40_, v41_ = self:getFirstVineHitPosition()
	local v42_, v43_, v44_ = self:getCurrentVineHitPosition()
	v31_.currentCombineVehicle = v37_
	v31_.lastTouchedFarmlandFarmId = v33_
	placeable:harvestVine(node, v39_, v40_, v41_, v42_, v43_, v44_, self.harvestCallback, self)
	placeable:setShakingFactor(node, v42_, v43_, v44_, 1)
	if v31_.lastHarvestingNode ~= nil and v31_.lastHarvestingNode ~= node then
		v31_.lastHarvestingPlaceable:setShakingFactor(v31_.lastHarvestingNode, v42_, v43_, v44_, 0)
	end
	v31_.lastHarvestingNode = node
	v31_.lastHarvestingPlaceable = placeable
	return true
end

-- Local values: spec
function VineCutter:clearCurrentVinePlaceable(superFunc)
	superFunc(self)
	local v47_ = self.spec_vineCutter
	if v47_.lastHarvestingPlaceable ~= nil and v47_.lastHarvestingNode ~= nil then
		v47_.lastHarvestingPlaceable:setShakingFactor(v47_.lastHarvestingNode, 0, 0, 0, 0)
	end
	v47_.lastHarvestingPlaceable = nil
	v47_.lastHarvestingNode = nil
	v47_.showFarmlandNotOwnedWarning = false
end

function VineCutter:getAIImplementUseVineSegment(superFunc, placeable, segment, segmentSide)
	if segmentSide >= 0 then
		return placeable:getHasSegmentTargetGrowthState(segment, self.spec_vineCutter.inputFruitTypeIndex, true, false)
	else
		return false
	end
end

-- Local values: spec, limeFactor, stubbleTillageFactor, rollerFactor, beeYieldBonusPerc, multiplier, realArea, liters, ha
function VineCutter:harvestCallback(placeable, area, totalArea, weedFactor, sprayFactor, plowFactor, sectionLength)
	local v58_ = self.spec_vineCutter
	local v59_ = area * g_currentMission:getHarvestScaleMultiplier(v58_.inputFruitTypeIndex, sprayFactor, plowFactor, 1, weedFactor, 1, 1, 0)
	local v60_ = g_fruitTypeManager:getFruitTypeAreaLiters(v58_.inputFruitTypeIndex, v59_, false)
	v58_.currentCombineVehicle:addCutterArea(area, v60_, v58_.inputFruitTypeIndex, v58_.outputFillTypeIndex, 0, v58_.lastTouchedFarmlandFarmId, 1)
	if v58_.inputFruitTypeIndex == FruitType.GRAPE then
		g_farmManager:updateFarmStats(v58_.lastTouchedFarmlandFarmId, "harvestedGrapes", sectionLength)
		return
	elseif v58_.inputFruitTypeIndex == FruitType.OLIVE then
		g_farmManager:updateFarmStats(v58_.lastTouchedFarmlandFarmId, "harvestedOlives", sectionLength)
	else
		local v61_ = MathUtil.areaToHa(area, g_currentMission:getFruitPixelsToSqm())
		g_farmManager:updateFarmStats(v58_.lastTouchedFarmlandFarmId, "threshedHectares", v61_)
		g_farmManager:updateFarmStats(v58_.lastTouchedFarmlandFarmId, "workedHectares", v61_)
	end
end

function VineCutter:doCheckSpeedLimit(superFunc)
	return superFunc(self) or self:getIsTurnedOn()
end

-- Local values: spec, attacherVehicle
function VineCutter:getCombine()
	local v65_ = self.spec_vineCutter
	if self.verifyCombine ~= nil then
		return self:verifyCombine(v65_.inputFruitTypeIndex, v65_.outputFillTypeIndex)
	end
	if self.getAttacherVehicle ~= nil then
		local v66_ = self:getAttacherVehicle()
		if v66_ ~= nil and v66_.verifyCombine ~= nil then
			return v66_:verifyCombine(v65_.inputFruitTypeIndex, v65_.outputFillTypeIndex)
		end
	end
	return nil
end
function VineCutter.getDefaultSpeedLimit()
	return 5
end
