HarvestExtension = {}
HarvestExtension.YIELD_DEBUG = false
HarvestExtension.MOD_NAME = g_currentModName
local HarvestExtension_mt = Class(HarvestExtension)
function HarvestExtension.new(pfModule, customMt)
	local self = setmetatable({}, customMt or HarvestExtension_mt)
	self.pfModule = pfModule
	self.debugValues = { nActualValue = 0, nTargetValue = 0, nFactor = 0, regularNFactor = 0, nRegularValue = 0, yieldPotential = 0, ignoreOverfertilization = false, pHActualValue = 0, pHTargetValue = 0, pHRegularValue = 0, pHFactor = 0, regularPHFactor = 0, plowFactor = 0, weedFactor = 0, stubbleFactor = 0, rollerFactor = 0, yieldFactor = 0, yieldFactorRegular = 0, seedRateYieldFactor = 0, lastSeedRateFound = 0, lastSeedRateTarget = 0 }
	self.densityMapParallelogram = DensityMapParallelogram.new()
	g_messageCenter:subscribe(MessageType.UNLOADING_STATIONS_CHANGED, self.onUnloadingStationsChanged, self)
	if g_server ~= nil then
		addConsoleCommand("pfShowYieldDebug", "Displayes precision farming yield debug", "toggleYieldDebug", self)
	end
	return self
end
function HarvestExtension:delete()
	g_messageCenter:unsubscribeAll(self)
	if g_server ~= nil then
		removeConsoleCommand("pfShowYieldDebug")
	end
end
function HarvestExtension:loadFromXML(xmlFile, key, baseDirectory, configFileName, mapFilename)
	return true
end
function HarvestExtension:toggleYieldDebug()
	HarvestExtension.YIELD_DEBUG = not HarvestExtension.YIELD_DEBUG
end
function HarvestExtension:update(dt) end
function HarvestExtension:draw()
	if HarvestExtension.YIELD_DEBUG then
		local debugValues = self.debugValues
		local nitrogenMap = self.pfModule.nitrogenMap
		local pHMap = self.pfModule.pHMap
		local seedRateMap = self.pfModule.seedRateMap
		renderText(0.01, 0.42, 0.015, string.format("Nitrogen: Actual: %d | Target: %d | Regular: %d => Factor: %d%% | Regular Factor: %d%%", nitrogenMap:getNitrogenValueFromInternalValue(debugValues.nActualValue), nitrogenMap:getNitrogenValueFromInternalValue(debugValues.nTargetValue), nitrogenMap:getNitrogenValueFromInternalValue(debugValues.nRegularValue), debugValues.nFactor * 100, debugValues.regularNFactor * 100))
		renderText(0.01, 0.4, 0.015, string.format("Nitrogen: Yield Potential: %d%% | ignoreOverfertilization: %s", debugValues.yieldPotential * 100, debugValues.ignoreOverfertilization))
		renderText(0.01, 0.38, 0.015, string.format("Seed Rate: Yield: %d%% | Optimal Rate: %s | Found Rate: %s", debugValues.seedRateYieldFactor * 100, seedRateMap:getRateLabelByIndex(debugValues.lastSeedRateTarget), seedRateMap:getRateLabelByIndex(debugValues.lastSeedRateFound)))
		renderText(0.01, 0.36, 0.015, string.format("pH: Actual: %.3f | Target: %.3f | Regular: %.3f => Factor: %d%% | Regular Factor: %d%%", pHMap:getPhValueFromInternalValue(debugValues.pHActualValue), pHMap:getPhValueFromInternalValue(debugValues.pHTargetValue), pHMap:getPhValueFromInternalValue(debugValues.pHRegularValue), debugValues.pHFactor * 100, debugValues.regularPHFactor * 100))
		renderText(0.01, 0.34, 0.015, string.format("Plow Factor: %d%% | Weed Factor: %d%% | Stubble Factor: %d%% | Roller Factor: %d%%", debugValues.plowFactor * 100, debugValues.weedFactor * 100, debugValues.stubbleFactor * 100, debugValues.rollerFactor * 100))
		renderText(0.01, 0.32, 0.015, string.format("Yield: %d%% | Regular Yield: %d%%", debugValues.yieldFactor / 2 * 100, debugValues.yieldFactorRegular / 2 * 100))
		nitrogenMap:drawYieldDebug(debugValues.nActualValue, debugValues.nTargetValue)
		pHMap:drawYieldDebug(debugValues.pHActualValue, debugValues.pHTargetValue)
	end
end
function HarvestExtension:onUnloadingStationsChanged()
	self.unloadingStations = g_currentMission.storageSystem:getUnloadingStations()
end
function HarvestExtension:getYieldFromArea(combine, cutter, inputFruitType, realArea)
	local pixelToSqm = g_currentMission:getFruitPixelsToSqm()
	local literPerSqm = 1
	if inputFruitType ~= FruitType.UNKNOWN then
		local fruitDesc = g_fruitTypeManager:getFruitTypeByIndex(inputFruitType)
		literPerSqm = fruitDesc.literPerSqm
	end
	local sqm = realArea * pixelToSqm
	local yield = sqm * literPerSqm * combine.spec_combine.threshingScale
	local farmId = cutter:getLastTouchedFarmlandFarmId()
	if farmId ~= AccessHandler.EVERYONE then
		local damage = combine:getVehicleDamage()
		if 0 < damage then
			yield = yield * (1 - damage * Combine.DAMAGED_YIELD_REDUCTION)
		end
	end
	return yield
end
function HarvestExtension:getBestPriceForFillType(fillType)
	if self.unloadingStations == nil then
		self.unloadingStations = g_currentMission.storageSystem:getUnloadingStations()
	end
	local maxPrice = 0
	for _, unloadingStation in pairs(self.unloadingStations) do
		if unloadingStation.getEffectiveFillTypePrice == nil then
			continue
		end
		if unloadingStation:getIsFillTypeAllowed(fillType.index) and (unloadingStation.getAppearsOnStats == nil or unloadingStation:getAppearsOnStats()) then
			maxPrice = math.max(maxPrice, unloadingStation:getEffectiveFillTypePrice(fillType.index, ToolType.UNDEFINED))
		end
	end
	if maxPrice == 0 then
		maxPrice = fillType.pricePerLiter or 0
	end
	return maxPrice
end
function HarvestExtension:updateLatestFactors(pfModule, vehicle, requiresPHFactorUpdate, requiresNFactorUpdate)
	local nFactor = vehicle.lastNFactor or 0
	local regularNFactor = vehicle.lastRegularNFactor or 0
	local currentYieldPotential = vehicle.lastYieldPotential or 1
	if requiresNFactorUpdate then
		local nActualValue, nTargetValue, yieldPotential, nRegularValue, lastIgnoreOverfertilization = pfModule.nitrogenMap:updateLastNitrogenValues()
		if -1 < nActualValue and -1 < nTargetValue then
			nFactor = pfModule.nitrogenMap:getYieldFactorByLevelDifference(nActualValue - nTargetValue, lastIgnoreOverfertilization)
			vehicle.lastNFactor = nFactor
			vehicle.lastYieldPotential = yieldPotential
			currentYieldPotential = yieldPotential
			regularNFactor = pfModule.nitrogenMap:getYieldFactorByLevelDifference(nRegularValue - nTargetValue, lastIgnoreOverfertilization)
			vehicle.lastRegularNFactor = regularNFactor
			vehicle.lastNActualValue = nActualValue
			vehicle.lastNTargetValue = nTargetValue
			vehicle.lastIgnoreOverfertilization = lastIgnoreOverfertilization
			if HarvestExtension.YIELD_DEBUG then
				local debugValues = self.debugValues
				debugValues.nActualValue = nActualValue
				debugValues.nTargetValue = nTargetValue
				debugValues.yieldPotential = yieldPotential
				debugValues.nRegularValue = nRegularValue
				debugValues.ignoreOverfertilization = lastIgnoreOverfertilization
				debugValues.nFactor = nFactor
				debugValues.regularNFactor = regularNFactor
			end
		end
	end
	local pHFactor = vehicle.lastPHFactor or 0
	local regularPHFactor = vehicle.lastRegularPHFactor or 0
	if requiresPHFactorUpdate then
		local pHActualValue, pHTargetValue, pHRegularValue = pfModule.pHMap:updateLastPhValues()
		if -1 < pHActualValue and (-1 < pHTargetValue and -1 < pHRegularValue) then
			pHFactor = pfModule.pHMap:getYieldFactorByLevelDifference(pHActualValue - pHTargetValue)
			vehicle.lastPHFactor = pHFactor
			regularPHFactor = pfModule.pHMap:getYieldFactorByLevelDifference(pHRegularValue - pHTargetValue)
			vehicle.lastRegularPHFactor = regularPHFactor
			vehicle.lastPHActualValue = pHActualValue
			vehicle.lastPHTargetValue = pHTargetValue
			if HarvestExtension.YIELD_DEBUG then
				local debugValues = self.debugValues
				debugValues.pHFactor = pHFactor
				debugValues.regularPHFactor = regularPHFactor
				debugValues.pHActualValue = pHActualValue
				debugValues.pHTargetValue = pHTargetValue
				debugValues.pHRegularValue = pHRegularValue
			end
		end
	end
	local seedRateYieldFactor, lastSeedRateFound, lastSeedRateTarget = pfModule.seedRateMap:updateLastYieldValues()
	seedRateYieldFactor = seedRateYieldFactor or vehicle.lastSeedRateMultiplier or 1
	if seedRateYieldFactor ~= nil then
		currentYieldPotential = currentYieldPotential * seedRateYieldFactor
		vehicle.lastSeedRateMultiplier = seedRateYieldFactor
		if HarvestExtension.YIELD_DEBUG then
			local debugValues = self.debugValues
			debugValues.seedRateYieldFactor = seedRateYieldFactor
			debugValues.lastSeedRateFound = lastSeedRateFound or debugValues.lastSeedRateFound
			debugValues.lastSeedRateTarget = lastSeedRateTarget or debugValues.lastSeedRateTarget
		end
	end
	return nFactor, math.min(regularNFactor, nFactor), currentYieldPotential, pHFactor, math.min(regularPHFactor, pHFactor)
end
function HarvestExtension:getLastMultipliers(yieldPotential, regularNFactor, nFactor, regularPHFactor, pHFactor)
	if self.lastPlowFactor == nil then
		return 1, 1
	else
		local regularMultiplier = 1
		regularMultiplier = regularMultiplier + self.lastPlowFactor * 0.1
		regularMultiplier = regularMultiplier + self.lastWeedFactor * 0.15
		regularMultiplier = regularMultiplier + self.lastStubbleFactor * 0.025
		regularMultiplier = regularMultiplier + self.lastRollerFactor * 0.025
		regularMultiplier = regularMultiplier + regularNFactor * 0.5
		regularMultiplier = regularMultiplier + regularPHFactor * 0.2
		regularMultiplier = regularMultiplier * yieldPotential
		local newMultiplier = 1
		newMultiplier = newMultiplier + self.lastPlowFactor * 0.1
		newMultiplier = newMultiplier + self.lastWeedFactor * 0.15
		newMultiplier = newMultiplier + self.lastStubbleFactor * 0.025
		newMultiplier = newMultiplier + self.lastRollerFactor * 0.025
		newMultiplier = newMultiplier + nFactor * 0.5
		newMultiplier = newMultiplier + pHFactor * 0.2
		newMultiplier = newMultiplier * yieldPotential
		return regularMultiplier, newMultiplier
	end
end
function HarvestExtension:updateWeedFactor(vehicle)
	if self.lastWeedFactor == nil then
		return
	else
		if vehicle.smoothedWeedFactor == nil then
			vehicle.smoothedWeedFactor = 0
		end
		vehicle.smoothedWeedFactor = vehicle.smoothedWeedFactor * 0.95 + self.lastWeedFactor * 0.05
		self.lastWeedFactor = vehicle.smoothedWeedFactor
	end
end
function HarvestExtension:preProcessMowerArea(vehicle, workArea, dt)
	local specMower = vehicle.spec_mower
	local pfModule = g_precisionFarming
	local xs = nil
	local zs = nil
	local xw = nil
	local zw = nil
	local xh = nil
	local zh = nil
	local _ = nil
	xs, _, zs = getWorldTranslation(workArea.start)
	xw, _, zw = getWorldTranslation(workArea.width)
	xh, _, zh = getWorldTranslation(workArea.height)
	if specMower.pfFruitTypeConverters == nil then
		specMower.pfFruitTypeConverters = {}
		for fruitTypeIndex, _ in pairs(specMower.fruitTypeConverters) do
			table.insert(specMower.pfFruitTypeConverters, fruitTypeIndex)
		end
	end
	self.densityMapParallelogram:updateFromWorldPositions(xs, zs, xw, zw, xh, zh)
	vehicle.pfUsedFruitIndex = pfModule.coverMap:preUpdateCoverArea(specMower.pfFruitTypeConverters, self.densityMapParallelogram, pfModule:getIsMaizePlusActive(), false) or vehicle.pfUsedFruitIndex
	local nFactor, regularNFactor, currentYieldPotential, pHFactor, regularPHFactor = self:updateLatestFactors(pfModule, vehicle, false, false)
	self.replaceNFactor = nFactor
	self.replaceRegularNFactor = regularNFactor
	self.replacePHFactor = pHFactor
	self.replaceRegularPHFactor = regularPHFactor
	self.replaceYieldPotential = currentYieldPotential
	self.checkMultiplier = true
	self.replaceMultiplier = true
end
function HarvestExtension:postProcessMowerArea(vehicle, workArea, dt, lastRealArea)
	local specMower = vehicle.spec_mower
	self.checkMultiplier = false
	self.replaceMultiplier = false
	self:updateWeedFactor(vehicle)
	local pfModule = g_precisionFarming
	local xs = nil
	local zs = nil
	local xw = nil
	local zw = nil
	local xh = nil
	local zh = nil
	local _ = nil
	xs, _, zs = getWorldTranslation(workArea.start)
	xw, _, zw = getWorldTranslation(workArea.width)
	xh, _, zh = getWorldTranslation(workArea.height)
	local farmlandId = g_farmlandManager:getFarmlandIdAtWorldPosition((xs + xw) * 0.5, (zs + zw) * 0.5)
	local mission = g_missionManager:getMissionAtWorldPosition(xs, zs) or g_missionManager:getMissionAtWorldPosition(xw, zw) or g_missionManager:getMissionAtWorldPosition(xh, zh)
	local fillTypeIndex = nil
	local dropArea = vehicle:getDropArea(workArea)
	if dropArea ~= nil then
		fillTypeIndex = dropArea.fillType
	elseif specMower.fillUnitIndex ~= nil then
		fillTypeIndex = vehicle:getFillUnitFillType(specMower.fillUnitIndex)
	end
	self.densityMapParallelogram:updateFromWorldPositions(xs, zs, xw, zw, xh, zh)
	local phMapUpdated, nMapUpdated = pfModule.coverMap:postUpdateCoverArea(specMower.pfFruitTypeConverters, self.densityMapParallelogram, pfModule:getIsMaizePlusActive(), false, vehicle.pfUsedFruitIndex)
	self:updateLatestFactors(pfModule, vehicle, phMapUpdated, nMapUpdated)
	self:setLastScoringValues(lastRealArea, farmlandId, vehicle.lastNActualValue, vehicle.lastNTargetValue, vehicle.lastPHActualValue, vehicle.lastPHTargetValue, vehicle.lastIgnoreOverfertilization, fillTypeIndex)
	local regularMultiplier, newMultiplier = self:getLastMultipliers(self.replaceYieldPotential, self.replaceRegularNFactor, self.replaceNFactor, self.replaceRegularPHFactor, self.replacePHFactor)
	if 0 < lastRealArea and mission == nil then
		local rawPickupLiters = workArea.pickedUpLiters / newMultiplier
		local regularPickupLiters = rawPickupLiters * regularMultiplier
		if fillTypeIndex ~= nil and fillTypeIndex ~= FillType.UNKNOWN then
			if pfModule.yieldMap ~= nil then
				pfModule.yieldMap:setAreaYield(xs, zs, xw, zw, xh, zh, newMultiplier)
			end
			if HarvestExtension.YIELD_DEBUG then
				local debugValues = self.debugValues
				debugValues.yieldFactor = newMultiplier
				debugValues.yieldFactorRegular = regularMultiplier
			end
			local fillType = g_fillTypeManager:getFillTypeByIndex(fillTypeIndex)
			local pickupWeight = workArea.pickedUpLiters * (fillType.massPerLiter / FillTypeManager.MASS_SCALE)
			if vehicle.updatePFStatistic ~= nil then
				vehicle:updatePFStatistic("yield", workArea.pickedUpLiters)
				vehicle:updatePFStatistic("yieldWeight", pickupWeight)
				vehicle:updatePFStatistic("yieldRegular", regularPickupLiters)
				local maxPrice = self:getBestPriceForFillType(fillType)
				vehicle:updatePFStatistic("yieldBestPrice", maxPrice * workArea.pickedUpLiters)
			end
		end
	end
	self.lastMultiplier = nil
	self.lastPlowFactor = nil
	self.lastWeedFactor = nil
	self.lastStubbleFactor = nil
	self.lastRollerFactor = nil
end
function HarvestExtension:setLastScoringValues(area, farmlandId, nActual, nTarget, pHActual, pHTarget, ignoreOverfertilization, fillTypeIndex) end
function HarvestExtension:overwriteGameFunctions(pfModule)
	local fruitTypes = {}
	local tempTarget = {}
	pfModule:overwriteGameFunction(FSDensityMapUtil, "updateVineCutArea", function(superFunc, fruitId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
		self.densityMapParallelogram:updateFromWorldPositions(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
		fruitTypes[1] = fruitId
		if tempTarget[fruitId] == nil then
			tempTarget[fruitId] = {}
		end
		tempTarget[fruitId].pfUsedFruitIndex = pfModule.coverMap:preUpdateCoverArea(fruitTypes, self.densityMapParallelogram, false, false) or tempTarget[fruitId].pfUsedFruitIndex
		local nFactor, regularNFactor, currentYieldPotential, pHFactor, regularPHFactor = self:updateLatestFactors(pfModule, tempTarget[fruitId], false, false)
		self.replaceNFactor = nFactor
		self.replaceRegularNFactor = regularNFactor
		self.replacePHFactor = pHFactor
		self.replaceRegularPHFactor = regularPHFactor
		self.replaceYieldPotential = currentYieldPotential
		self.checkMultiplier = true
		self.replaceMultiplier = true
		if self.replaceVineMultiplierArea == nil then
			self.replaceVineMultiplierArea = { 0, 0, 0, 0, 0, 0 }
		end
		self.replaceVineMultiplierArea[1] = startWorldX
		self.replaceVineMultiplierArea[2] = startWorldZ
		self.replaceVineMultiplierArea[3] = widthWorldX
		self.replaceVineMultiplierArea[4] = widthWorldZ
		self.replaceVineMultiplierArea[5] = heightWorldX
		self.replaceVineMultiplierArea[6] = heightWorldZ
		return superFunc(fruitId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	end)
	pfModule:overwriteGameFunction(VineCutter, "harvestCallback", function(superFunc, vehicle, placeable, area, totalArea, weedFactor, sprayFactor, plowFactor, sectionLength)
		superFunc(vehicle, placeable, area, totalArea, weedFactor, sprayFactor, plowFactor, sectionLength)
		self.checkMultiplier = false
		self.replaceMultiplier = false
		if self.replaceVineMultiplierArea ~= nil then
			local spec = vehicle.spec_vineCutter
			local startWorldX = self.replaceVineMultiplierArea[1]
			local startWorldZ = self.replaceVineMultiplierArea[2]
			local widthWorldX = self.replaceVineMultiplierArea[3]
			local widthWorldZ = self.replaceVineMultiplierArea[4]
			local heightWorldX = self.replaceVineMultiplierArea[5]
			local heightWorldZ = self.replaceVineMultiplierArea[6]
			local farmlandId = g_farmlandManager:getFarmlandIdAtWorldPosition((startWorldX + widthWorldX) * 0.5, (startWorldZ + widthWorldZ) * 0.5)
			local fillType = g_fillTypeManager:getFillTypeByIndex(spec.inputFruitTypeIndex)
			if fillType ~= nil then
				if tempTarget[spec.inputFruitTypeIndex] == nil then
					tempTarget[spec.inputFruitTypeIndex] = {}
				end
				self.densityMapParallelogram:updateFromWorldPositions(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
				local target = tempTarget[spec.inputFruitTypeIndex]
				local phMapUpdated, nMapUpdated = pfModule.coverMap:postUpdateCoverArea(fruitTypes, self.densityMapParallelogram, false, false, target.pfUsedFruitIndex)
				self:updateLatestFactors(pfModule, target, phMapUpdated, nMapUpdated)
				self:setLastScoringValues(area, farmlandId, target.lastNActualValue, target.lastNTargetValue, target.lastPHActualValue, target.lastPHTargetValue, target.lastIgnoreOverfertilization, fillType.index)
				local regularMultiplier, newMultiplier = self:getLastMultipliers(self.replaceYieldPotential, self.replaceRegularNFactor, self.replaceNFactor, self.replaceRegularPHFactor, self.replacePHFactor)
				if pfModule.yieldMap ~= nil then
					pfModule.yieldMap:setAreaYield(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, newMultiplier)
				end
				if HarvestExtension.YIELD_DEBUG then
					local debugValues = self.debugValues
					debugValues.yieldFactor = newMultiplier
					debugValues.yieldFactorRegular = regularMultiplier
				end
				local liters = g_fruitTypeManager:getFruitTypeAreaLiters(spec.inputFruitTypeIndex, area * newMultiplier, false)
				local regularLiters = g_fruitTypeManager:getFruitTypeAreaLiters(spec.inputFruitTypeIndex, area * regularMultiplier, false)
				local yieldWeight = liters * (fillType.massPerLiter / FillTypeManager.MASS_SCALE)
				if vehicle.updatePFStatistic ~= nil then
					vehicle:updatePFStatistic("yield", liters)
					vehicle:updatePFStatistic("yieldWeight", yieldWeight)
					vehicle:updatePFStatistic("yieldRegular", regularLiters)
					local maxPrice = self:getBestPriceForFillType(fillType)
					vehicle:updatePFStatistic("yieldBestPrice", maxPrice * liters)
				end
				local combine = spec.currentCombineVehicle
				if combine ~= nil and combine.setLastYieldValues ~= nil then
					local yieldPerHa = self:getYieldFromArea(combine, vehicle, spec.inputFruitTypeIndex, 10000 / g_currentMission:getFruitPixelsToSqm())
					local yieldPerHaWeight = yieldPerHa * (fillType.massPerLiter / FillTypeManager.MASS_SCALE)
					combine:setLastYieldValues(yieldPerHaWeight, newMultiplier * 0.5 * 100, self.replaceYieldPotential * 100)
				end
			end
		end
		self.lastMultiplier = nil
		self.lastPlowFactor = nil
		self.lastWeedFactor = nil
		self.lastStubbleFactor = nil
		self.lastRollerFactor = nil
	end)
	pfModule:overwriteGameFunction(Cutter, "processCutterArea", function(superFunc, vehicle, workArea, dt)
		if not vehicle.isServer and Cutter.CLIENT_DM_UPDATE_RADIUS < vehicle.currentUpdateDistance then
			return superFunc(vehicle, workArea)
		end
		local specCutter = vehicle.spec_cutter
		local combine = specCutter.workAreaParameters.combineVehicle
		if combine == nil then
			return superFunc(vehicle, workArea, dt)
		else
			local xs, _, zs = getWorldTranslation(workArea.start)
			local xw, _, zw = getWorldTranslation(workArea.width)
			local xh, _, zh = getWorldTranslation(workArea.height)
			self.densityMapParallelogram:updateFromWorldPositions(xs, zs, xw, zw, xh, zh)
			local strawChopperActive = false
			local combineSpec = combine.spec_combine
			if combineSpec ~= nil then
				local strawFruitType = combineSpec.lastValidInputFruitType
				if strawFruitType == nil then
					strawFruitType = g_fruitTypeManager:getFruitTypeIndexByFillTypeIndex(combineSpec.lastCuttersOutputFillType)
				end
				if strawFruitType ~= nil then
					local fruitTypeDesc = g_fruitTypeManager:getFruitTypeByIndex(strawFruitType)
					if fruitTypeDesc ~= nil and (fruitTypeDesc.chopperType ~= nil and not combineSpec.isSwathActive) then
						strawChopperActive = true
					end
				end
			end
			vehicle.pfUsedFruitIndex = pfModule.coverMap:preUpdateCoverArea(specCutter.workAreaParameters.fruitTypeIndicesToUse, self.densityMapParallelogram, specCutter.allowsForageGrowthState, strawChopperActive) or vehicle.pfUsedFruitIndex
			local nFactor, regularNFactor, currentYieldPotential, pHFactor, regularPHFactor = self:updateLatestFactors(pfModule, vehicle, false, false)
			self.replaceNFactor = nFactor
			self.replaceRegularNFactor = regularNFactor
			self.replacePHFactor = pHFactor
			self.replaceRegularPHFactor = regularPHFactor
			self.replaceYieldPotential = currentYieldPotential
			local farmlandId = g_farmlandManager:getFarmlandIdAtWorldPosition((xs + xw) * 0.5, (zs + zw) * 0.5)
			local mission = g_missionManager:getMissionAtWorldPosition(xs, zs) or g_missionManager:getMissionAtWorldPosition(xw, zw) or g_missionManager:getMissionAtWorldPosition(xh, zh)
			self.checkMultiplier = true
			self.replaceMultiplier = mission == nil
			local lastRealArea, lastArea = superFunc(vehicle, workArea, dt)
			self.checkMultiplier = false
			self.replaceMultiplier = false
			self:updateWeedFactor(vehicle)
			local phMapUpdated, nMapUpdated = pfModule.coverMap:postUpdateCoverArea(specCutter.workAreaParameters.fruitTypeIndicesToUse, self.densityMapParallelogram, specCutter.allowsForageGrowthState, strawChopperActive, vehicle.pfUsedFruitIndex)
			self:updateLatestFactors(pfModule, vehicle, phMapUpdated, nMapUpdated)
			self:setLastScoringValues(lastRealArea, farmlandId, vehicle.lastNActualValue, vehicle.lastNTargetValue, vehicle.lastPHActualValue, vehicle.lastPHTargetValue, vehicle.lastIgnoreOverfertilization, fillTypeIndex)
			local fillTypeIndex = nil
			local inputFruitType = specCutter.workAreaParameters.lastFruitType
			if inputFruitType ~= nil then
				fillTypeIndex = g_fruitTypeManager:getFillTypeIndexByFruitTypeIndex(inputFruitType)
			end
			local regularMultiplier, newMultiplier = self:getLastMultipliers(self.replaceYieldPotential, self.replaceRegularNFactor, self.replaceNFactor, self.replaceRegularPHFactor, self.replacePHFactor)
			if 0 < lastRealArea and mission == nil then
				local regularMultiplierArea = specCutter.workAreaParameters.lastArea * regularMultiplier
				specCutter.workAreaParameters.lastMultiplierArea = specCutter.workAreaParameters.lastArea * 1.05 * newMultiplier
				if pfModule.yieldMap ~= nil then
					pfModule.yieldMap:setAreaYield(xs, zs, xw, zw, xh, zh, newMultiplier)
				end
				if HarvestExtension.YIELD_DEBUG then
					local debugValues = self.debugValues
					debugValues.yieldFactor = newMultiplier
					debugValues.yieldFactorRegular = regularMultiplier
					debugValues.plowFactor = self.lastPlowFactor
					debugValues.weedFactor = self.lastWeedFactor
					debugValues.stubbleFactor = self.lastStubbleFactor
					debugValues.rollerFactor = self.lastRollerFactor
				end
				local conversionFactor = 1
				if specCutter.fruitTypeConverters[inputFruitType] ~= nil then
					fillTypeIndex = specCutter.fruitTypeConverters[inputFruitType].fillTypeIndex
					conversionFactor = specCutter.fruitTypeConverters[inputFruitType].conversionFactor
				end
				local fillType = g_fillTypeManager:getFillTypeByIndex(fillTypeIndex)
				local yield = self:getYieldFromArea(combine, vehicle, inputFruitType, specCutter.workAreaParameters.lastMultiplierArea) * conversionFactor
				local yieldWeight = yield * (fillType.massPerLiter / FillTypeManager.MASS_SCALE)
				local regularYield = self:getYieldFromArea(combine, vehicle, inputFruitType, regularMultiplierArea) * conversionFactor
				if vehicle.updatePFStatistic ~= nil then
					vehicle:updatePFStatistic("yield", yield)
					vehicle:updatePFStatistic("yieldWeight", yieldWeight)
					vehicle:updatePFStatistic("yieldRegular", regularYield)
					local maxPrice = self:getBestPriceForFillType(fillType)
					vehicle:updatePFStatistic("yieldBestPrice", maxPrice * yield)
				end
				if combine.setLastYieldValues ~= nil then
					local yieldPerHa = self:getYieldFromArea(combine, vehicle, inputFruitType, 10000 / g_currentMission:getFruitPixelsToSqm() * newMultiplier) * conversionFactor
					local yieldPerHaWeight = yieldPerHa * (fillType.massPerLiter / FillTypeManager.MASS_SCALE)
					combine:setLastYieldValues(yieldPerHaWeight, newMultiplier * 0.5 * 100, currentYieldPotential * 100)
				end
			end
			self.lastMultiplier = nil
			self.lastPlowFactor = nil
			self.lastWeedFactor = nil
			self.lastStubbleFactor = nil
			self.lastRollerFactor = nil
			return lastRealArea, lastArea
		end
	end)
	pfModule:overwriteGameFunction(FSBaseMission, "getHarvestScaleMultiplier", function(superFunc, mission, fruitTypeIndex, sprayFactor, plowFactor, limeFactor, weedFactor, stubbleFactor, rollerFactor, beeYieldBonusPercentage)
		local multiplier = superFunc(mission, fruitTypeIndex, sprayFactor, plowFactor, limeFactor, weedFactor, stubbleFactor, rollerFactor, beeYieldBonusPercentage)
		if self.checkMultiplier then
			self.lastMultiplier = multiplier
			self.lastPlowFactor = plowFactor
			self.lastWeedFactor = weedFactor
			self.lastStubbleFactor = stubbleFactor
			self.lastRollerFactor = rollerFactor
			local _, newMultiplier = self:getLastMultipliers(self.replaceYieldPotential, self.replaceRegularNFactor, self.replaceNFactor, self.replaceRegularPHFactor, self.replacePHFactor)
			if self.replaceMultiplier then
				return newMultiplier
			end
		end
		return multiplier
	end)
	pfModule:overwriteGameFunction(FSDensityMapUtil, "updateDestroyCommonArea", function(superFunc, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, onlyOnFields, deleteAll, resetDisplacement)
		pfModule.nitrogenMap:updateDestroyCommonArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
		superFunc(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, onlyOnFields, deleteAll, resetDisplacement)
		pfModule.nitrogenMap:postUpdateDestroyCommonArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	end)
	pfModule:overwriteGameFunction(FSDensityMapUtil, "updateDiscHarrowArea", function(superFunc, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, createField, limitFruitDestructionToField, angle, blockedSprayTypeIndex)
		pfModule.nitrogenMap:updateDestroyCommonArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
		local changedArea, totalArea = superFunc(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, createField, limitFruitDestructionToField, angle, blockedSprayTypeIndex)
		pfModule.nitrogenMap:postUpdateDestroyCommonArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
		return changedArea, totalArea
	end)
	pfModule:overwriteGameFunction(FSDensityMapUtil, "updateDirectSowingArea", function(superFunc, fruitIndex, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, fieldGroundType, ridgeSeeding, angle, growthState, blockedSprayTypeIndex)
		pfModule.nitrogenMap:updateDestroyCommonArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
		local changedArea, totalArea = superFunc(fruitIndex, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, fieldGroundType, ridgeSeeding, angle, growthState, blockedSprayTypeIndex)
		pfModule.nitrogenMap:postUpdateDestroyCommonArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
		return changedArea, totalArea
	end)
	pfModule:overwriteGameFunction(FSDensityMapUtil, "getWeedFactor", function(superFunc, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, fruitIndex)
		local weedFactor = superFunc(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, fruitIndex)
		if 0 < weedFactor then
			return 1
		else
			return 0
		end
	end)
end
