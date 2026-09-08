-- Local values: HarvestExtension_mt
HarvestExtension = {}
HarvestExtension.YIELD_DEBUG = false
HarvestExtension.MOD_NAME = g_currentModName
local HarvestExtension_mt = Class(HarvestExtension)

-- Upvalues: HarvestExtension_mt
-- Local values: self
function HarvestExtension.new(pfModule, customMt)
	-- upvalues: (copy) HarvestExtension_mt
	local v4_ = customMt or HarvestExtension_mt
	local v5_ = setmetatable({}, v4_)
	v5_.pfModule = pfModule
	v5_.debugValues = {
		["nActualValue"] = 0,
		["nTargetValue"] = 0,
		["nFactor"] = 0,
		["regularNFactor"] = 0,
		["nRegularValue"] = 0,
		["yieldPotential"] = 0,
		["ignoreOverfertilization"] = false,
		["pHActualValue"] = 0,
		["pHTargetValue"] = 0,
		["pHRegularValue"] = 0,
		["pHFactor"] = 0,
		["regularPHFactor"] = 0,
		["plowFactor"] = 0,
		["weedFactor"] = 0,
		["stubbleFactor"] = 0,
		["rollerFactor"] = 0,
		["yieldFactor"] = 0,
		["yieldFactorRegular"] = 0,
		["seedRateYieldFactor"] = 0,
		["lastSeedRateFound"] = 0,
		["lastSeedRateTarget"] = 0
	}
	v5_.densityMapParallelogram = DensityMapParallelogram.new()
	g_messageCenter:subscribe(MessageType.UNLOADING_STATIONS_CHANGED, v5_.onUnloadingStationsChanged, v5_)
	if g_server ~= nil then
		addConsoleCommand("pfShowYieldDebug", "Displayes precision farming yield debug", "toggleYieldDebug", v5_)
	end
	return v5_
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

-- Local values: debugValues, nitrogenMap, pHMap, seedRateMap
function HarvestExtension:draw()
	if HarvestExtension.YIELD_DEBUG then
		local v8_ = self.debugValues
		local v9_ = self.pfModule.nitrogenMap
		local v10_ = self.pfModule.pHMap
		local v11_ = self.pfModule.seedRateMap
		renderText(0.01, 0.42, 0.015, string.format("Nitrogen: Actual: %d | Target: %d | Regular: %d => Factor: %d%% | Regular Factor: %d%%", v9_:getNitrogenValueFromInternalValue(v8_.nActualValue), v9_:getNitrogenValueFromInternalValue(v8_.nTargetValue), v9_:getNitrogenValueFromInternalValue(v8_.nRegularValue), v8_.nFactor * 100, v8_.regularNFactor * 100))
		renderText(0.01, 0.4, 0.015, string.format("Nitrogen: Yield Potential: %d%% | ignoreOverfertilization: %s", v8_.yieldPotential * 100, v8_.ignoreOverfertilization))
		renderText(0.01, 0.38, 0.015, string.format("Seed Rate: Yield: %d%% | Optimal Rate: %s | Found Rate: %s", v8_.seedRateYieldFactor * 100, v11_:getRateLabelByIndex(v8_.lastSeedRateTarget), v11_:getRateLabelByIndex(v8_.lastSeedRateFound)))
		renderText(0.01, 0.36, 0.015, string.format("pH: Actual: %.3f | Target: %.3f | Regular: %.3f => Factor: %d%% | Regular Factor: %d%%", v10_:getPhValueFromInternalValue(v8_.pHActualValue), v10_:getPhValueFromInternalValue(v8_.pHTargetValue), v10_:getPhValueFromInternalValue(v8_.pHRegularValue), v8_.pHFactor * 100, v8_.regularPHFactor * 100))
		renderText(0.01, 0.34, 0.015, string.format("Plow Factor: %d%% | Weed Factor: %d%% | Stubble Factor: %d%% | Roller Factor: %d%%", v8_.plowFactor * 100, v8_.weedFactor * 100, v8_.stubbleFactor * 100, v8_.rollerFactor * 100))
		renderText(0.01, 0.32, 0.015, string.format("Yield: %d%% | Regular Yield: %d%%", v8_.yieldFactor / 2 * 100, v8_.yieldFactorRegular / 2 * 100))
		v9_:drawYieldDebug(v8_.nActualValue, v8_.nTargetValue)
		v10_:drawYieldDebug(v8_.pHActualValue, v8_.pHTargetValue)
	end
end

function HarvestExtension:onUnloadingStationsChanged()
	self.unloadingStations = g_currentMission.storageSystem:getUnloadingStations()
end

-- Local values: pixelToSqm, literPerSqm, fruitDesc, sqm, yield, farmId, damage
function HarvestExtension:getYieldFromArea(combine, cutter, inputFruitType, realArea)
	local v17_ = g_currentMission:getFruitPixelsToSqm()
	local v18_ = inputFruitType == FruitType.UNKNOWN and 1 or g_fruitTypeManager:getFruitTypeByIndex(inputFruitType).literPerSqm
	local v19_ = realArea * v17_ * v18_ * combine.spec_combine.threshingScale
	if cutter:getLastTouchedFarmlandFarmId() ~= AccessHandler.EVERYONE then
		local v20_ = combine:getVehicleDamage()
		if v20_ > 0 then
			v19_ = v19_ * (1 - v20_ * Combine.DAMAGED_YIELD_REDUCTION)
		end
	end
	return v19_
end

-- Local values: maxPrice, _, unloadingStation
function HarvestExtension:getBestPriceForFillType(fillType)
	if self.unloadingStations == nil then
		self.unloadingStations = g_currentMission.storageSystem:getUnloadingStations()
	end
	local v23_ = 0
	for _, v24_ in pairs(self.unloadingStations) do
		if v24_.getEffectiveFillTypePrice ~= nil and (v24_:getIsFillTypeAllowed(fillType.index) and (v24_.getAppearsOnStats == nil or v24_:getAppearsOnStats())) then
			local v25_ = fillType.index
			local v26_ = ToolType.UNDEFINED
			v23_ = math.max(v23_, v24_:getEffectiveFillTypePrice(v25_, v26_))
		end
	end
	return v23_ == 0 and (fillType.pricePerLiter or 0) or v23_
end

-- Local values: nFactor, regularNFactor, currentYieldPotential, nActualValue, nTargetValue, yieldPotential, nRegularValue, lastIgnoreOverfertilization, debugValues, pHFactor, regularPHFactor, pHActualValue, pHTargetValue, pHRegularValue, debugValues, seedRateYieldFactor, lastSeedRateFound, lastSeedRateTarget, debugValues
function HarvestExtension:updateLatestFactors(pfModule, vehicle, requiresPHFactorUpdate, requiresNFactorUpdate)
	local v32_ = vehicle.lastNFactor or 0
	local v33_ = vehicle.lastRegularNFactor or 0
	local v34_ = vehicle.lastYieldPotential or 1
	local v35_
	if requiresNFactorUpdate then
		local v36_, v37_, v38_, v39_
		v36_, v37_, v35_, v38_, v39_ = pfModule.nitrogenMap:updateLastNitrogenValues()
		if v36_ > -1 and v37_ > -1 then
			v32_ = pfModule.nitrogenMap:getYieldFactorByLevelDifference(v36_ - v37_, v39_)
			vehicle.lastNFactor = v32_
			vehicle.lastYieldPotential = v35_
			v33_ = pfModule.nitrogenMap:getYieldFactorByLevelDifference(v38_ - v37_, v39_)
			vehicle.lastRegularNFactor = v33_
			vehicle.lastNActualValue = v36_
			vehicle.lastNTargetValue = v37_
			vehicle.lastIgnoreOverfertilization = v39_
			if HarvestExtension.YIELD_DEBUG then
				local v40_ = self.debugValues
				v40_.nActualValue = v36_
				v40_.nTargetValue = v37_
				v40_.yieldPotential = v35_
				v40_.nRegularValue = v38_
				v40_.ignoreOverfertilization = v39_
				v40_.nFactor = v32_
				v40_.regularNFactor = v33_
			end
		else
			v35_ = v34_
		end
	else
		v35_ = v34_
	end
	local v41_ = vehicle.lastPHFactor or 0
	local v42_ = vehicle.lastRegularPHFactor or 0
	if requiresPHFactorUpdate then
		local v43_, v44_, v45_ = pfModule.pHMap:updateLastPhValues()
		if v43_ > -1 and (v44_ > -1 and v45_ > -1) then
			v41_ = pfModule.pHMap:getYieldFactorByLevelDifference(v43_ - v44_)
			vehicle.lastPHFactor = v41_
			v42_ = pfModule.pHMap:getYieldFactorByLevelDifference(v45_ - v44_)
			vehicle.lastRegularPHFactor = v42_
			vehicle.lastPHActualValue = v43_
			vehicle.lastPHTargetValue = v44_
			if HarvestExtension.YIELD_DEBUG then
				local v46_ = self.debugValues
				v46_.pHFactor = v41_
				v46_.regularPHFactor = v42_
				v46_.pHActualValue = v43_
				v46_.pHTargetValue = v44_
				v46_.pHRegularValue = v45_
			end
		end
	end
	local v47_, v48_, v49_ = pfModule.seedRateMap:updateLastYieldValues()
	local v50_ = v47_ or (vehicle.lastSeedRateMultiplier or 1)
	if v50_ ~= nil then
		v35_ = v35_ * v50_
		vehicle.lastSeedRateMultiplier = v50_
		if HarvestExtension.YIELD_DEBUG then
			local v51_ = self.debugValues
			v51_.seedRateYieldFactor = v50_
			v51_.lastSeedRateFound = v48_ or v51_.lastSeedRateFound
			v51_.lastSeedRateTarget = v49_ or v51_.lastSeedRateTarget
		end
	end
	return v32_, math.min(v33_, v32_), v35_, v41_, math.min(v42_, v41_)
end

-- Local values: regularMultiplier, newMultiplier
function HarvestExtension:getLastMultipliers(yieldPotential, regularNFactor, nFactor, regularPHFactor, pHFactor)
	if self.lastPlowFactor == nil then
		return 1, 1
	else
		return (1 + self.lastPlowFactor * 0.1 + self.lastWeedFactor * 0.15 + self.lastStubbleFactor * 0.025 + self.lastRollerFactor * 0.025 + regularNFactor * 0.5 + regularPHFactor * 0.2) * yieldPotential, (1 + self.lastPlowFactor * 0.1 + self.lastWeedFactor * 0.15 + self.lastStubbleFactor * 0.025 + self.lastRollerFactor * 0.025 + nFactor * 0.5 + pHFactor * 0.2) * yieldPotential
	end
end

function HarvestExtension:updateWeedFactor(vehicle)
	if self.lastWeedFactor ~= nil then
		if vehicle.smoothedWeedFactor == nil then
			vehicle.smoothedWeedFactor = 0
		end
		vehicle.smoothedWeedFactor = vehicle.smoothedWeedFactor * 0.95 + self.lastWeedFactor * 0.05
		self.lastWeedFactor = vehicle.smoothedWeedFactor
	end
end

-- Local values: specMower, pfModule, xs, zs, xw, zw, xh, zh, _, fruitTypeIndex, _, nFactor, regularNFactor, currentYieldPotential, pHFactor, regularPHFactor
function HarvestExtension:preProcessMowerArea(vehicle, workArea, dt)
	local v63_ = vehicle.spec_mower
	local v64_ = g_precisionFarming
	local v65_, _, v66_ = getWorldTranslation(workArea.start)
	local v67_, _, v68_ = getWorldTranslation(workArea.width)
	local v69_, _, v70_ = getWorldTranslation(workArea.height)
	if v63_.pfFruitTypeConverters == nil then
		v63_.pfFruitTypeConverters = {}
		for v71_, _ in pairs(v63_.fruitTypeConverters) do
			local v72_ = v63_.pfFruitTypeConverters
			table.insert(v72_, v71_)
		end
	end
	self.densityMapParallelogram:updateFromWorldPositions(v65_, v66_, v67_, v68_, v69_, v70_)
	v64_.coverMap:preUpdateCoverArea(v63_.pfFruitTypeConverters, self.densityMapParallelogram, v64_:getIsMaizePlusActive(), false)
	local v73_, v74_, v75_, v76_, v77_ = self:updateLatestFactors(v64_, vehicle, false, false)
	self.replaceNFactor = v73_
	self.replaceRegularNFactor = v74_
	self.replacePHFactor = v76_
	self.replaceRegularPHFactor = v77_
	self.replaceYieldPotential = v75_
	self.checkMultiplier = true
	self.replaceMultiplier = true
end

-- Local values: specMower, pfModule, xs, zs, xw, zw, xh, zh, _, farmlandId, mission, fillTypeIndex, dropArea, phMapUpdated, nMapUpdated, regularMultiplier, newMultiplier, rawPickupLiters, regularPickupLiters, debugValues, fillType, pickupWeight, maxPrice
function HarvestExtension:postProcessMowerArea(vehicle, workArea, dt, lastRealArea)
	local v82_ = vehicle.spec_mower
	self.checkMultiplier = false
	self.replaceMultiplier = false
	self:updateWeedFactor(vehicle)
	local v83_ = g_precisionFarming
	local v84_, _, v85_ = getWorldTranslation(workArea.start)
	local v86_, _, v87_ = getWorldTranslation(workArea.width)
	local v88_, _, v89_ = getWorldTranslation(workArea.height)
	local v90_ = g_farmlandManager:getFarmlandIdAtWorldPosition((v84_ + v86_) * 0.5, (v85_ + v87_) * 0.5)
	local v91_ = g_missionManager:getMissionAtWorldPosition(v84_, v85_) or (g_missionManager:getMissionAtWorldPosition(v86_, v87_) or g_missionManager:getMissionAtWorldPosition(v88_, v89_))
	local v92_ = nil
	local v93_ = vehicle:getDropArea(workArea)
	if v93_ == nil then
		if v82_.fillUnitIndex ~= nil then
			v92_ = vehicle:getFillUnitFillType(v82_.fillUnitIndex)
		end
	else
		v92_ = v93_.fillType
	end
	self.densityMapParallelogram:updateFromWorldPositions(v84_, v85_, v86_, v87_, v88_, v89_)
	local v94_, v95_ = v83_.coverMap:postUpdateCoverArea(v82_.pfFruitTypeConverters, self.densityMapParallelogram, v83_:getIsMaizePlusActive(), false)
	self:updateLatestFactors(v83_, vehicle, v94_, v95_)
	self:setLastScoringValues(lastRealArea, v90_, vehicle.lastNActualValue, vehicle.lastNTargetValue, vehicle.lastPHActualValue, vehicle.lastPHTargetValue, vehicle.lastIgnoreOverfertilization, v92_)
	local v96_, v97_ = self:getLastMultipliers(self.replaceYieldPotential, self.replaceRegularNFactor, self.replaceNFactor, self.replaceRegularPHFactor, self.replacePHFactor)
	if lastRealArea > 0 and v91_ == nil then
		local v98_ = workArea.pickedUpLiters / v97_ * v96_
		if v92_ ~= nil and v92_ ~= FillType.UNKNOWN then
			if v83_.yieldMap ~= nil then
				v83_.yieldMap:setAreaYield(v84_, v85_, v86_, v87_, v88_, v89_, v97_)
			end
			if HarvestExtension.YIELD_DEBUG then
				local v99_ = self.debugValues
				v99_.yieldFactor = v97_
				v99_.yieldFactorRegular = v96_
			end
			local v100_ = g_fillTypeManager:getFillTypeByIndex(v92_)
			local v101_ = workArea.pickedUpLiters * (v100_.massPerLiter / FillTypeManager.MASS_SCALE)
			if vehicle.updatePFStatistic ~= nil then
				vehicle:updatePFStatistic("yield", workArea.pickedUpLiters)
				vehicle:updatePFStatistic("yieldWeight", v101_)
				vehicle:updatePFStatistic("yieldRegular", v98_)
				vehicle:updatePFStatistic("yieldBestPrice", self:getBestPriceForFillType(v100_) * workArea.pickedUpLiters)
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

-- Local values: fruitTypes, tempTarget
function HarvestExtension:overwriteGameFunctions(pfModule)
	local v_u_104_ = {}
	local v_u_105_ = {}
	pfModule:overwriteGameFunction(FSDensityMapUtil, "updateVineCutArea", function(p106_, p107_, p108_, p109_, p110_, p111_, p112_, p113_)
		-- upvalues: (copy) self, (copy) v_u_104_, (copy) v_u_105_, (copy) pfModule
		self.densityMapParallelogram:updateFromWorldPositions(p108_, p109_, p110_, p111_, p112_, p113_)
		v_u_104_[1] = p107_
		if v_u_105_[p107_] == nil then
			v_u_105_[p107_] = {}
		end
		pfModule.coverMap:preUpdateCoverArea(v_u_104_, self.densityMapParallelogram, false, false)
		local v114_, v115_, v116_, v117_, v118_ = self:updateLatestFactors(pfModule, v_u_105_[p107_], false, false)
		self.replaceNFactor = v114_
		self.replaceRegularNFactor = v115_
		self.replacePHFactor = v117_
		self.replaceRegularPHFactor = v118_
		self.replaceYieldPotential = v116_
		self.checkMultiplier = true
		self.replaceMultiplier = true
		if self.replaceVineMultiplierArea == nil then
			self.replaceVineMultiplierArea = {
				0,
				0,
				0,
				0,
				0,
				0
			}
		end
		local v119_ = self.replaceVineMultiplierArea
		local v120_ = self.replaceVineMultiplierArea
		v119_[1] = p108_
		v120_[2] = p109_
		local v121_ = self.replaceVineMultiplierArea
		local v122_ = self.replaceVineMultiplierArea
		v121_[3] = p110_
		v122_[4] = p111_
		local v123_ = self.replaceVineMultiplierArea
		local v124_ = self.replaceVineMultiplierArea
		v123_[5] = p112_
		v124_[6] = p113_
		return p106_(p107_, p108_, p109_, p110_, p111_, p112_, p113_)
	end)
	pfModule:overwriteGameFunction(VineCutter, "harvestCallback", function(p125_, p126_, p127_, p128_, p129_, p130_, p131_, p132_, p133_)
		-- upvalues: (copy) self, (copy) v_u_105_, (copy) pfModule, (copy) v_u_104_
		p125_(p126_, p127_, p128_, p129_, p130_, p131_, p132_, p133_)
		self.checkMultiplier = false
		self.replaceMultiplier = false
		if self.replaceVineMultiplierArea ~= nil then
			local v134_ = p126_.spec_vineCutter
			local v135_ = self.replaceVineMultiplierArea[1]
			local v136_ = self.replaceVineMultiplierArea[2]
			local v137_ = self.replaceVineMultiplierArea[3]
			local v138_ = self.replaceVineMultiplierArea[4]
			local v139_ = self.replaceVineMultiplierArea[5]
			local v140_ = self.replaceVineMultiplierArea[6]
			local v141_ = g_farmlandManager:getFarmlandIdAtWorldPosition((v135_ + v137_) * 0.5, (v136_ + v138_) * 0.5)
			local v142_ = g_fillTypeManager:getFillTypeByIndex(v134_.inputFruitTypeIndex)
			if v142_ ~= nil then
				if v_u_105_[v134_.inputFruitTypeIndex] == nil then
					v_u_105_[v134_.inputFruitTypeIndex] = {}
				end
				self.densityMapParallelogram:updateFromWorldPositions(v135_, v136_, v137_, v138_, v139_, v140_)
				local v143_, v144_ = pfModule.coverMap:postUpdateCoverArea(v_u_104_, self.densityMapParallelogram, false, false)
				local v145_ = v_u_105_[v134_.inputFruitTypeIndex]
				self:updateLatestFactors(pfModule, v145_, v143_, v144_)
				self:setLastScoringValues(p128_, v141_, v145_.lastNActualValue, v145_.lastNTargetValue, v145_.lastPHActualValue, v145_.lastPHTargetValue, v145_.lastIgnoreOverfertilization, v142_.index)
				local v146_, v147_ = self:getLastMultipliers(self.replaceYieldPotential, self.replaceRegularNFactor, self.replaceNFactor, self.replaceRegularPHFactor, self.replacePHFactor)
				if pfModule.yieldMap ~= nil then
					pfModule.yieldMap:setAreaYield(v135_, v136_, v137_, v138_, v139_, v140_, v147_)
				end
				if HarvestExtension.YIELD_DEBUG then
					local v148_ = self.debugValues
					v148_.yieldFactor = v147_
					v148_.yieldFactorRegular = v146_
				end
				local v149_ = g_fruitTypeManager:getFruitTypeAreaLiters(v134_.inputFruitTypeIndex, p128_ * v147_, false)
				local v150_ = g_fruitTypeManager:getFruitTypeAreaLiters(v134_.inputFruitTypeIndex, p128_ * v146_, false)
				local v151_ = v149_ * (v142_.massPerLiter / FillTypeManager.MASS_SCALE)
				if p126_.updatePFStatistic ~= nil then
					p126_:updatePFStatistic("yield", v149_)
					p126_:updatePFStatistic("yieldWeight", v151_)
					p126_:updatePFStatistic("yieldRegular", v150_)
					p126_:updatePFStatistic("yieldBestPrice", self:getBestPriceForFillType(v142_) * v149_)
				end
				local v152_ = v134_.currentCombineVehicle
				if v152_ ~= nil and v152_.setLastYieldValues ~= nil then
					v152_:setLastYieldValues(self:getYieldFromArea(v152_, p126_, v134_.inputFruitTypeIndex, 10000 / g_currentMission:getFruitPixelsToSqm()) * (v142_.massPerLiter / FillTypeManager.MASS_SCALE), v147_ * 0.5 * 100, self.replaceYieldPotential * 100)
				end
			end
		end
		self.lastMultiplier = nil
		self.lastPlowFactor = nil
		self.lastWeedFactor = nil
		self.lastStubbleFactor = nil
		self.lastRollerFactor = nil
	end)
	pfModule:overwriteGameFunction(Cutter, "processCutterArea", function(p153_, p154_, p155_, p156_)
		-- upvalues: (copy) self, (copy) pfModule
		if not p154_.isServer and p154_.currentUpdateDistance > Cutter.CLIENT_DM_UPDATE_RADIUS then
			return p153_(p154_, p155_)
		end
		local v157_ = p154_.spec_cutter
		local v158_ = v157_.workAreaParameters.combineVehicle
		if v158_ == nil then
			return p153_(p154_, p155_, p156_)
		end
		local v159_, _, v160_ = getWorldTranslation(p155_.start)
		local v161_, _, v162_ = getWorldTranslation(p155_.width)
		local v163_, _, v164_ = getWorldTranslation(p155_.height)
		self.densityMapParallelogram:updateFromWorldPositions(v159_, v160_, v161_, v162_, v163_, v164_)
		local v165_ = false
		local v166_ = v158_.spec_combine
		if v166_ ~= nil then
			local v167_ = v166_.lastValidInputFruitType
			if v167_ == nil then
				v167_ = g_fruitTypeManager:getFruitTypeIndexByFillTypeIndex(v166_.lastCuttersOutputFillType)
			end
			if v167_ ~= nil then
				local v168_ = g_fruitTypeManager:getFruitTypeByIndex(v167_)
				v165_ = v168_ ~= nil and (v168_.chopperType ~= nil and not v166_.isSwathActive) and true or v165_
			end
		end
		pfModule.coverMap:preUpdateCoverArea(v157_.workAreaParameters.fruitTypeIndicesToUse, self.densityMapParallelogram, v157_.allowsForageGrowthState, v165_)
		local v169_, v170_, v171_, v172_, v173_ = self:updateLatestFactors(pfModule, p154_, false, false)
		self.replaceNFactor = v169_
		self.replaceRegularNFactor = v170_
		self.replacePHFactor = v172_
		self.replaceRegularPHFactor = v173_
		self.replaceYieldPotential = v171_
		local v174_ = g_farmlandManager:getFarmlandIdAtWorldPosition((v159_ + v161_) * 0.5, (v160_ + v162_) * 0.5)
		local v175_ = g_missionManager:getMissionAtWorldPosition(v159_, v160_) or (g_missionManager:getMissionAtWorldPosition(v161_, v162_) or g_missionManager:getMissionAtWorldPosition(v163_, v164_))
		self.checkMultiplier = true
		self.replaceMultiplier = v175_ == nil
		local v176_, v177_ = p153_(p154_, p155_, p156_)
		self.checkMultiplier = false
		self.replaceMultiplier = false
		self:updateWeedFactor(p154_)
		local v178_, v179_ = pfModule.coverMap:postUpdateCoverArea(v157_.workAreaParameters.fruitTypeIndicesToUse, self.densityMapParallelogram, v157_.allowsForageGrowthState, v165_)
		self:updateLatestFactors(pfModule, p154_, v178_, v179_)
		self:setLastScoringValues(v176_, v174_, p154_.lastNActualValue, p154_.lastNTargetValue, p154_.lastPHActualValue, p154_.lastPHTargetValue, p154_.lastIgnoreOverfertilization, fillTypeIndex)
		local v180_ = v157_.workAreaParameters.lastFruitType
		local v181_
		if v180_ == nil then
			v181_ = nil
		else
			v181_ = g_fruitTypeManager:getFillTypeIndexByFruitTypeIndex(v180_)
		end
		local v182_, v183_ = self:getLastMultipliers(self.replaceYieldPotential, self.replaceRegularNFactor, self.replaceNFactor, self.replaceRegularPHFactor, self.replacePHFactor)
		if v176_ > 0 and v175_ == nil then
			local v184_ = v157_.workAreaParameters.lastArea * v182_
			v157_.workAreaParameters.lastMultiplierArea = v157_.workAreaParameters.lastArea * 1.05 * v183_
			if pfModule.yieldMap ~= nil then
				pfModule.yieldMap:setAreaYield(v159_, v160_, v161_, v162_, v163_, v164_, v183_)
			end
			if HarvestExtension.YIELD_DEBUG then
				local v185_ = self.debugValues
				v185_.yieldFactor = v183_
				v185_.yieldFactorRegular = v182_
				v185_.plowFactor = self.lastPlowFactor
				v185_.weedFactor = self.lastWeedFactor
				v185_.stubbleFactor = self.lastStubbleFactor
				v185_.rollerFactor = self.lastRollerFactor
			end
			local v186_
			if v157_.fruitTypeConverters[v180_] == nil then
				v186_ = 1
			else
				v181_ = v157_.fruitTypeConverters[v180_].fillTypeIndex
				v186_ = v157_.fruitTypeConverters[v180_].conversionFactor
			end
			local v187_ = g_fillTypeManager:getFillTypeByIndex(v181_)
			local v188_ = self:getYieldFromArea(v158_, p154_, v180_, v157_.workAreaParameters.lastMultiplierArea) * v186_
			local v189_ = v188_ * (v187_.massPerLiter / FillTypeManager.MASS_SCALE)
			local v190_ = self:getYieldFromArea(v158_, p154_, v180_, v184_) * v186_
			if p154_.updatePFStatistic ~= nil then
				p154_:updatePFStatistic("yield", v188_)
				p154_:updatePFStatistic("yieldWeight", v189_)
				p154_:updatePFStatistic("yieldRegular", v190_)
				p154_:updatePFStatistic("yieldBestPrice", self:getBestPriceForFillType(v187_) * v188_)
			end
			if v158_.setLastYieldValues ~= nil then
				v158_:setLastYieldValues(self:getYieldFromArea(v158_, p154_, v180_, 10000 / g_currentMission:getFruitPixelsToSqm() * v183_) * v186_ * (v187_.massPerLiter / FillTypeManager.MASS_SCALE), v183_ * 0.5 * 100, v171_ * 100)
			end
		end
		self.lastMultiplier = nil
		self.lastPlowFactor = nil
		self.lastWeedFactor = nil
		self.lastStubbleFactor = nil
		self.lastRollerFactor = nil
		return v176_, v177_
	end)
	pfModule:overwriteGameFunction(FSBaseMission, "getHarvestScaleMultiplier", function(p191_, p192_, p193_, p194_, p195_, p196_, p197_, p198_, p199_, p200_)
		-- upvalues: (copy) self
		local v201_ = p191_(p192_, p193_, p194_, p195_, p196_, p197_, p198_, p199_, p200_)
		if self.checkMultiplier then
			self.lastMultiplier = v201_
			self.lastPlowFactor = p195_
			self.lastWeedFactor = p197_
			self.lastStubbleFactor = p198_
			self.lastRollerFactor = p199_
			local _, v202_ = self:getLastMultipliers(self.replaceYieldPotential, self.replaceRegularNFactor, self.replaceNFactor, self.replaceRegularPHFactor, self.replacePHFactor)
			if self.replaceMultiplier then
				return v202_
			end
		end
		return v201_
	end)
	pfModule:overwriteGameFunction(FSDensityMapUtil, "updateDestroyCommonArea", function(p203_, p204_, p205_, p206_, p207_, p208_, p209_, p210_, p211_, p212_)
		-- upvalues: (copy) pfModule
		pfModule.nitrogenMap:updateDestroyCommonArea(p204_, p205_, p206_, p207_, p208_, p209_)
		p203_(p204_, p205_, p206_, p207_, p208_, p209_, p210_, p211_, p212_)
		pfModule.nitrogenMap:postUpdateDestroyCommonArea(p204_, p205_, p206_, p207_, p208_, p209_)
	end)
	pfModule:overwriteGameFunction(FSDensityMapUtil, "updateDiscHarrowArea", function(p213_, p214_, p215_, p216_, p217_, p218_, p219_, p220_, p221_, p222_, p223_)
		-- upvalues: (copy) pfModule
		pfModule.nitrogenMap:updateDestroyCommonArea(p214_, p215_, p216_, p217_, p218_, p219_)
		local v224_, v225_ = p213_(p214_, p215_, p216_, p217_, p218_, p219_, p220_, p221_, p222_, p223_)
		pfModule.nitrogenMap:postUpdateDestroyCommonArea(p214_, p215_, p216_, p217_, p218_, p219_)
		return v224_, v225_
	end)
	pfModule:overwriteGameFunction(FSDensityMapUtil, "updateDirectSowingArea", function(p226_, p227_, p228_, p229_, p230_, p231_, p232_, p233_, p234_, p235_, p236_, p237_, p238_)
		-- upvalues: (copy) pfModule
		pfModule.nitrogenMap:updateDestroyCommonArea(p228_, p229_, p230_, p231_, p232_, p233_)
		local v239_, v240_ = p226_(p227_, p228_, p229_, p230_, p231_, p232_, p233_, p234_, p235_, p236_, p237_, p238_)
		pfModule.nitrogenMap:postUpdateDestroyCommonArea(p228_, p229_, p230_, p231_, p232_, p233_)
		return v239_, v240_
	end)
	pfModule:overwriteGameFunction(FSDensityMapUtil, "getWeedFactor", function(p241_, p242_, p243_, p244_, p245_, p246_, p247_, p248_)
		return p241_(p242_, p243_, p244_, p245_, p246_, p247_, p248_) > 0 and 1 or 0
	end)
end
