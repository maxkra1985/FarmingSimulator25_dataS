-- Local values: old
FSDensityMapUtil = {}
local old = DensityMapModifier.new
function DensityMapModifier.new(...)
	-- upvalues: (copy) old
	local v2_ = old(...)
	v2_:setPolygonRoundingMode(DensityRoundingMode.INCLUSIVE)
	return v2_
end
FSDensityMapUtil.functionCache = {}
function FSDensityMapUtil.clearCache()
	FSDensityMapUtil.functionCache = {}
end

-- Local values: fieldGroundSystem, groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, densityBits, groundType, isOnField
function FSDensityMapUtil.getFieldDataAtWorldPosition(x, y, z)
	local v6_, v7_, v8_ = g_currentMission.fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
	if v6_ == nil then
		return false, 0, 0
	end
	local v9_ = getDensityAtWorldPos(v6_, x, y, z)
	local v10_ = bit32.rshift(v9_, v7_)
	local v11_ = 2 ^ v8_ - 1
	local v12_ = bit32.band(v10_, v11_)
	return v12_ ~= 0, v9_, v12_
end

-- Local values: desc, functionData, terrainRootNode, fieldGroundSystem, sprayLevelMapId, sprayLevelFirstChannel, sprayLevelNumChannels, groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, rollerLevelMapId, rollerLevelFirstChannel, rollerLevelNumChannels, plowLevelMapId, plowLevelFirstChannel, plowLevelNumChannels, limeLevelMapId, limeLevelFirstChannel, limeLevelNumChannels, stubbleShredLevelMapId, stubbleShredLevelFirstChannel, stubbleShredLevelNumChannels, value, minState, sprayLevelModifier, plowLevelModifier, plowLevelFilter, groundTypeModifier, sprayLevelMaxValue, fruitValueModifier, fruitFilter, terrainRootNode, fruitArea, _, _, sprayPixelsSum, _, _, plowTotalDelta, rollerTotalDelta, limeTotalDelta, stubbleTotalDelta, weedFactor, missionInfo, rollerLevelModifier, rollerLevelFilter, limeLevelModifier, stubbleShredModifier, terrainDetailPixelsSum, _, _, groundValue, groundTypeFilter, numPixels, totalNumPixels, scaledPixels, maxArea, growthState, src, target, _, partialNumPixels, partialTotalNumPixels, yieldScale, plowFactor, limeFactor, sprayFactor, stubbleFactor, rollerFactor, beeFactor
function FSDensityMapUtil.cutFruitArea(fruitIndex, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, destroySpray, useMinForageState, excludedSprayType, setsWeeds, limitToField)
	local v24_ = g_fruitTypeManager:getFruitTypeByIndex(fruitIndex)
	if v24_.terrainDataPlaneId == nil then
		return 0
	end
	local v25_ = FSDensityMapUtil.functionCache.cutFruitArea
	if v25_ == nil then
		local v26_ = g_terrainNode
		local v27_ = g_currentMission.fieldGroundSystem
		local v28_, v29_, v30_ = v27_:getDensityMapData(FieldDensityMap.SPRAY_LEVEL)
		local v31_, v32_, v33_ = v27_:getDensityMapData(FieldDensityMap.GROUND_TYPE)
		v25_ = {
			["fruitValueModifiers"] = {},
			["fruitFilters"] = {},
			["sownType"] = FieldGroundType.getValueByType(FieldGroundType.SOWN),
			["groundTypeFilter"] = DensityMapFilter.new(v31_, v32_, v33_)
		}
		v25_.groundTypeFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)
		v25_.sprayLevelMaxValue = v27_:getMaxValue(FieldDensityMap.SPRAY_LEVEL)
		v25_.sprayLevelModifier = DensityMapModifier.new(v28_, v29_, v30_, v26_)
		v25_.groundTypeModifier = DensityMapModifier.new(v31_, v32_, v33_, v26_)
		if Platform.gameplay.useRolling then
			local v34_, v35_, v36_ = v27_:getDensityMapData(FieldDensityMap.ROLLER_LEVEL)
			v25_.rollerLevelModifier = DensityMapModifier.new(v34_, v35_, v36_, v26_)
			v25_.rollerLevelFilter = DensityMapFilter.new(v34_, v35_, v36_)
			v25_.rollerLevelFilter:setValueCompareParams(DensityValueCompareType.EQUAL, 0)
		end
		if Platform.gameplay.usePlowCounter then
			local v37_, v38_, v39_ = v27_:getDensityMapData(FieldDensityMap.PLOW_LEVEL)
			v25_.plowLevelModifier = DensityMapModifier.new(v37_, v38_, v39_, v26_)
			v25_.plowLevelFilter = DensityMapFilter.new(v37_, v38_, v39_)
			v25_.plowLevelFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)
		end
		if Platform.gameplay.useLimeCounter then
			local v40_, v41_, v42_ = v27_:getDensityMapData(FieldDensityMap.LIME_LEVEL)
			v25_.limeLevelModifier = DensityMapModifier.new(v40_, v41_, v42_, v26_)
		end
		if Platform.gameplay.useStubbleShred then
			local v43_, v44_, v45_ = v27_:getDensityMapData(FieldDensityMap.STUBBLE_SHRED_LEVEL)
			v25_.stubbleShredModifier = DensityMapModifier.new(v43_, v44_, v45_, v26_)
			v25_.stubbleShredFilter = DensityMapFilter.new(v43_, v44_, v45_)
			v25_.stubbleShredFilter:setValueCompareParams(DensityValueCompareType.EQUAL, 1)
		end
		FSDensityMapUtil.functionCache.cutFruitArea = v25_
	end
	if v24_.cutState == 0 then
		return 0
	end
	local v46_ = v24_.minHarvestingGrowthState
	if useMinForageState then
		v46_ = v24_.minForageGrowthState
	end
	local v47_ = v25_.sprayLevelModifier
	local v48_ = v25_.plowLevelModifier
	local v49_ = v25_.plowLevelFilter
	local v50_ = v25_.groundTypeModifier
	local v51_ = v25_.sprayLevelMaxValue
	local v52_ = v25_.fruitValueModifiers[fruitIndex]
	local v53_ = v25_.fruitFilters[fruitIndex]
	if v52_ == nil then
		local v54_ = g_terrainNode
		v52_ = DensityMapModifier.new(v24_.terrainDataPlaneId, v24_.startStateChannel, v24_.numStateChannels, v54_)
		v52_:setReturnValueShift(-1)
		v25_.fruitValueModifiers[fruitIndex] = v52_
		v53_ = DensityMapFilter.new(v24_.terrainDataPlaneId, v24_.startStateChannel, v24_.numStateChannels)
		v25_.fruitFilters[fruitIndex] = v53_
	end
	v53_:setValueCompareParams(DensityValueCompareType.BETWEEN, v46_, v24_.maxHarvestingGrowthState)
	v52_:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	local v55_, _, _ = v52_:executeGet(v53_)
	if v55_ == 0 then
		return 0
	end
	v47_:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	v50_:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	local v56_, _, _ = v47_:executeGet(v53_)
	if destroySpray then
		FSDensityMapUtil.resetSprayArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, true, excludedSprayType)
		v47_:executeSet(0, v53_)
	end
	if v24_.startSprayLevel > 0 then
		local v57_ = v24_.startSprayLevel
		v47_:executeSet(math.min(v57_, v51_), v53_, v25_.groundTypeFilter)
		FSDensityMapUtil.resetSprayArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, true, excludedSprayType)
	end
	local v58_ = 0
	local v59_ = 0
	local v60_ = 0
	local v61_ = 0
	local v62_ = 1
	local v63_ = g_currentMission.missionInfo
	FSDensityMapUtil.removeWeedBlockingState(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	if v63_.weedsEnabled and v24_.plantsWeed then
		v62_ = 1 - FSDensityMapUtil.getWeedFactor(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, fruitIndex)
		FSDensityMapUtil.setSparseWeedArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	else
		FSDensityMapUtil.removeWeedArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	end
	if Platform.gameplay.usePlowCounter then
		v48_:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
		if v24_.lowSoilDensityRequired then
			local v64_, v65_
			v64_, v58_, v65_ = v48_:executeGet(v53_, v49_)
		end
		if v24_.increasesSoilDensity and v63_.plowingRequiredEnabled then
			v48_:executeAdd(-1, v53_)
		end
	end
	if v24_.needsRolling and Platform.gameplay.useRolling then
		local v66_ = v25_.rollerLevelModifier
		local v67_ = v25_.rollerLevelFilter
		v66_:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
		local v68_, v69_
		v68_, v59_, v69_ = v66_:executeGet(v53_, v67_)
	end
	if v24_.consumesLime and (v63_.limeRequired and Platform.gameplay.useLimeCounter) then
		local v70_ = v25_.limeLevelModifier
		v70_:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
		local v71_, v72_, v73_
		v71_, v72_, v60_, v73_ = v70_:executeAddWithStats(-1, v53_)
	end
	if Platform.gameplay.useStubbleShred then
		local v74_ = v25_.stubbleShredModifier
		v74_:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
		local v75_, v76_, v77_
		v75_, v76_, v61_, v77_ = v74_:executeAddWithStats(-1, v53_, v25_.stubbleShredFilter)
	end
	local v78_, _, _ = v50_:executeGet(v53_)
	if v24_.harvestGroundType ~= nil then
		v53_:setValueCompareParams(DensityValueCompareType.BETWEEN, v46_, v24_.maxHarvestingGrowthState)
		v50_:executeSet(FieldGroundType.getValueByType(v24_.harvestGroundType), v53_)
	end
	local v79_
	if limitToField then
		v79_ = v25_.groundTypeFilter
	else
		v79_ = nil
	end
	local v80_ = v46_
	local v81_ = 0
	local v82_ = 0
	local v83_ = 0
	local v84_ = 0
	for v85_, v86_ in pairs(v24_.harvestTransitions) do
		if v46_ <= v85_ and v85_ <= v24_.maxHarvestingGrowthState then
			v53_:setValueCompareParams(DensityValueCompareType.EQUAL, v85_)
			local v87_, v88_
			v87_, v88_, v84_ = v52_:executeSetWithStats(v86_, v53_, v79_)
			local v89_ = v24_:getYieldScale(v85_)
			v81_ = v81_ + v88_
			v82_ = v82_ + v88_ * v89_
			if v83_ < v88_ then
				v80_ = v85_
				v83_ = v88_
			end
		end
	end
	local v90_ = 0
	local v91_, v92_, v93_, v94_, v95_
	if v81_ > 0 then
		v91_ = not (v24_.lowSoilDensityRequired and v63_.plowingRequiredEnabled) and 1 or math.abs(v58_) / v81_
		v92_ = not (v24_.needsRolling and Platform.gameplay.useRolling) and 1 or math.abs(v59_) / v81_
		v93_ = not (v24_.growthRequiresLime and (v63_.limeRequired and Platform.gameplay.useLimeCounter)) and 1 or math.abs(v60_) / v81_
		v94_ = v56_ / (v81_ * v51_)
		v95_ = not Platform.gameplay.useStubbleShred and 1 or math.abs(v61_) / v81_
		if v24_.beeYieldBonusPercentage ~= 0 then
			v90_ = g_currentMission.beehiveSystem:getBeehiveInfluenceFactorAt(startWorldX, startWorldZ) * v24_.beeYieldBonusPercentage
		end
	else
		v94_ = 0
		v91_ = 0
		v93_ = 0
		v95_ = 0
		v92_ = 0
	end
	return v82_, v84_, v94_, v91_, v93_, v62_, v95_, v92_, v90_, v80_, v83_, v78_
end

-- Local values: desc, functionData, fruitModifier, terrainRootNode, fruitFilter, minState, ret, numPixels, totalNumPixels, ret2, numPixels2, totalNumPixels2, maxArea, growthState, i, _, area
function FSDensityMapUtil.getFruitArea(fruitIndex, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, allowPreparing, useMinForageState)
	local v105_ = g_fruitTypeManager:getFruitTypeByIndex(fruitIndex)
	if v105_.terrainDataPlaneId == nil then
		return 0, 0
	end
	local v106_ = FSDensityMapUtil.functionCache.getFruitArea
	if v106_ == nil then
		v106_ = {
			["fruitModifiers"] = {},
			["fruitFilter"] = {}
		}
		FSDensityMapUtil.functionCache.getFruitArea = v106_
	end
	local v107_ = v106_.fruitModifiers[fruitIndex]
	if v107_ == nil then
		local v108_ = g_terrainNode
		v107_ = DensityMapModifier.new(v105_.terrainDataPlaneId, v105_.startStateChannel, v105_.numStateChannels, v108_)
		v107_:setReturnValueShift(-1)
		v106_.fruitModifiers[fruitIndex] = v107_
		v106_.fruitFilter[fruitIndex] = DensityMapFilter.new(v107_)
	end
	local v109_ = v106_.fruitFilter[fruitIndex]
	local v110_ = v105_.minHarvestingGrowthState
	if useMinForageState then
		v110_ = v105_.minForageGrowthState
	end
	v107_:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	v109_:setValueCompareParams(DensityValueCompareType.BETWEEN, v110_, v105_.maxHarvestingGrowthState)
	local v111_, v112_, v113_ = v107_:executeGet(v109_)
	if allowPreparing and (v105_.minPreparingGrowthState >= 0 and v105_.maxPreparingGrowthState >= 0) then
		v109_:setValueCompareParams(DensityValueCompareType.BETWEEN, v105_.minPreparingGrowthState, v105_.maxPreparingGrowthState)
		local v114_, v115_, v116_ = v107_:executeGet(v109_)
		v111_ = v111_ + v114_
		v112_ = v112_ + v115_
		v113_ = v113_ + v116_
	end
	local v117_ = 0
	for v118_ = v110_, v105_.maxHarvestingGrowthState do
		v109_:setValueCompareParams(DensityValueCompareType.EQUAL, v118_)
		local _, v119_ = v107_:executeGet(v109_)
		if v117_ < v119_ then
			v110_ = v118_
			v117_ = v119_
		end
	end
	return v111_, v112_, v113_, v110_
end

-- Local values: functionData, label, multiModifier, terrainRootNode, fieldGroundSystem, groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, groundAngleMapId, groundAngleFirstChannel, groundAngleNumChannels, rollerLevelMapId, rollerLevelFirstChannel, rollerLevelNumChannels, rolledSeedbedType, rollerLinesType, firstSowableValue, lastSowableValue, firstSowingValue, lastSowingValue, rollerLevelModifier, groundTypeModifier, groundTypeAngleModifier, rollerLevelFilter, sownFilter, sowableFilter, rollerLinesFilter, rolledSeedbedFilter, stoneModifier, stoneFilter, stoneSystem, stoneMapId, stoneFirstChannel, stoneNumChannels, stoneMinValue, _, desc, firstGrowthStateFilter, numChangedPixels
function FSDensityMapUtil.updateRollerArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, angle)
	if not Platform.gameplay.useRolling then
		return 0
	end
	local v127_ = angle or 0
	local v128_ = FSDensityMapUtil.functionCache.updateRollerArea
	if v128_ == nil then
		v128_ = {
			["multiModifiers"] = {},
			["numChangedPixels"] = {}
		}
		FSDensityMapUtil.functionCache.updateRollerArea = v128_
	end
	local v129_ = v128_.multiModifiers[v127_]
	if v129_ == nil then
		local v130_ = g_terrainNode
		local v131_ = g_currentMission.fieldGroundSystem
		local v132_, v133_, v134_ = v131_:getDensityMapData(FieldDensityMap.GROUND_TYPE)
		local v135_, v136_, v137_ = v131_:getDensityMapData(FieldDensityMap.GROUND_ANGLE)
		local v138_, v139_, v140_ = v131_:getDensityMapData(FieldDensityMap.ROLLER_LEVEL)
		local v141_ = FieldGroundType.getValueByType(FieldGroundType.ROLLED_SEEDBED)
		local v142_ = FieldGroundType.getValueByType(FieldGroundType.ROLLER_LINES)
		local v143_, v144_ = v131_:getSowableRange()
		local v145_, v146_ = v131_:getSowingRange()
		local v147_ = DensityMapModifier.new(v138_, v139_, v140_, v130_)
		local v148_ = DensityMapModifier.new(v132_, v133_, v134_, v130_)
		local v149_ = DensityMapModifier.new(v135_, v136_, v137_, v130_)
		local v150_ = DensityMapFilter.new(v138_, v139_, v140_)
		v150_:setValueCompareParams(DensityValueCompareType.GREATER, 0)
		local v151_ = DensityMapFilter.new(v132_, v133_, v134_)
		v151_:setValueCompareParams(DensityValueCompareType.BETWEEN, v145_, v146_)
		local v152_ = DensityMapFilter.new(v132_, v133_, v134_)
		v152_:setValueCompareParams(DensityValueCompareType.BETWEEN, v143_, v144_)
		local v153_ = DensityMapFilter.new(v132_, v133_, v134_)
		v153_:setValueCompareParams(DensityValueCompareType.EQUAL, v142_)
		local v154_ = DensityMapFilter.new(v132_, v133_, v134_)
		v154_:setValueCompareParams(DensityValueCompareType.EQUAL, v141_)
		local v155_ = g_currentMission.stoneSystem
		local v156_, v157_
		if v155_:getMapHasStones() then
			local v158_, v159_, v160_ = v155_:getDensityMapData()
			local v161_ = v155_:getMinMaxValues()
			v156_ = DensityMapModifier.new(v158_, v159_, v160_, v130_)
			v156_:setPolygonRoundingMode(DensityRoundingMode.NEAREST)
			v157_ = DensityMapFilter.new(v158_, v159_, v160_)
			v157_:setValueCompareParams(DensityValueCompareType.EQUAL, v161_)
		else
			v156_ = nil
			v157_ = nil
		end
		v129_ = DensityMapMultiModifier.new()
		for _, v162_ in pairs(g_fruitTypeManager:getFruitTypes()) do
			if v162_.terrainDataPlaneId ~= nil then
				local v163_ = DensityMapFilter.new(v162_.terrainDataPlaneId, v162_.startStateChannel, v162_.numStateChannels)
				v163_:setValueCompareParams(DensityValueCompareType.EQUAL, 1)
				if v156_ ~= nil then
					v129_:addExecuteAdd(-1, v156_, v157_, v151_, v163_)
				end
				v129_:addExecuteSetWithStats("rolled", 0, v147_, v150_, v151_, v163_)
				v129_:addExecuteSet(v142_, v148_, v151_, v163_)
				v129_:addExecuteSet(v127_, v149_, v153_, v163_)
			end
		end
		if v156_ ~= nil then
			v129_:addExecuteAdd(-1, v156_, v157_)
		end
		v129_:addExecuteSetWithStats("rolled", 0, v147_, v150_, v152_)
		v129_:addExecuteSet(v141_, v148_, v152_)
		v129_:addExecuteSet(v127_, v149_, v154_)
		FSDensityMapUtil.multiModifierAddResetDisplacement(v129_)
		v128_.multiModifiers[v127_] = v129_
	end
	local v164_ = v128_.numChangedPixels
	v129_:updateParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	v129_:resetStats()
	v129_:execute(nil, v164_, nil)
	return v164_.rolled
end

-- Local values: functionData, terrainRootNode, fieldGroundSystem, sprayLevelMapId, sprayLevelFirstChannel, sprayLevelNumChannels, groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels, sprayType, sprayTypeMaxValue, sprayLevelMaxValue, grassDesc, meadowDesc, stoneSystem, stoneMapId, stoneFirstChannel, stoneNumChannels, stoneMinValue, grassModifier, grassFilter, grassFilterFirstStage, grassFilterRolledStage, grassRolledCutState, meadowModifier, meadowFilter, meadowFilterFirstStage, meadowFilterRolledStage, meadowRolledCutState, sprayLevelModifier, sprayTypeModifier, stoneModifier, stoneFilter, outsideFieldFilter, noGrassVisibleFilter, noMeadowVisibleFilter, sprayTypeFilter, sprayTypeFilter2, notMaxSprayLevelFilter, areaMaskedFilter, sprayType, maskValue, _, _, numPixels, totalNumPixels
function FSDensityMapUtil.updateGrassRollerArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, removeStones)
	local v172_ = FSDensityMapUtil.functionCache.updateGrassRollerArea
	if v172_ == nil then
		local v173_ = g_terrainNode
		local v174_ = g_currentMission.fieldGroundSystem
		local v175_, v176_, v177_ = v174_:getDensityMapData(FieldDensityMap.SPRAY_LEVEL)
		local v178_, v179_, v180_ = v174_:getDensityMapData(FieldDensityMap.GROUND_TYPE)
		local v181_, v182_, v183_ = v174_:getDensityMapData(FieldDensityMap.SPRAY_TYPE)
		local v184_ = FieldSprayType.getValueByType(FieldSprayType.FERTILIZER)
		local v185_ = v174_:getMaxValue(FieldDensityMap.SPRAY_TYPE)
		local v186_ = v174_:getMaxValue(FieldDensityMap.SPRAY_LEVEL)
		local v187_ = g_fruitTypeManager:getFruitTypeByIndex(FruitType.GRASS)
		local v188_ = g_fruitTypeManager:getFruitTypeByIndex(FruitType.MEADOW)
		v172_ = {
			["grassModifier"] = DensityMapModifier.new(v187_.terrainDataPlaneId, v187_.startStateChannel, v187_.numStateChannels, v173_),
			["grassFilter"] = DensityMapFilter.new(v187_.terrainDataPlaneId, v187_.startStateChannel, v187_.numStateChannels)
		}
		v172_.grassFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, 2, v187_.cutState)
		v172_.grassFilterFirstStage = DensityMapFilter.new(v187_.terrainDataPlaneId, v187_.startStateChannel, v187_.numStateChannels)
		v172_.grassFilterFirstStage:setValueCompareParams(DensityValueCompareType.BETWEEN, 3, v187_.cutState - 1)
		v172_.grassFilterRolledStage = DensityMapFilter.new(v187_.terrainDataPlaneId, v187_.startStateChannel, v187_.numStateChannels)
		v172_.grassFilterRolledStage:setValueCompareParams(DensityValueCompareType.BETWEEN, 3, v187_.cutState)
		v172_.grassRolledCutState = v187_.rolledCutState
		if v188_ ~= nil and v188_.terrainDataPlaneId ~= nil then
			v172_.meadowModifier = DensityMapModifier.new(v188_.terrainDataPlaneId, v188_.startStateChannel, v188_.numStateChannels, v173_)
			v172_.meadowFilter = DensityMapFilter.new(v188_.terrainDataPlaneId, v188_.startStateChannel, v188_.numStateChannels)
			v172_.meadowFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, 2, v187_.cutState)
			v172_.meadowFilterFirstStage = DensityMapFilter.new(v188_.terrainDataPlaneId, v188_.startStateChannel, v188_.numStateChannels)
			v172_.meadowFilterFirstStage:setValueCompareParams(DensityValueCompareType.BETWEEN, 3, v188_.cutState - 1)
			v172_.meadowFilterRolledStage = DensityMapFilter.new(v188_.terrainDataPlaneId, v188_.startStateChannel, v188_.numStateChannels)
			v172_.meadowFilterRolledStage:setValueCompareParams(DensityValueCompareType.BETWEEN, 3, v188_.cutState)
			v172_.meadowRolledCutState = v188_.rolledCutState
			v172_.noMeadowVisibleFilter = DensityMapFilter.new(v188_.terrainDataPlaneId, v188_.startStateChannel, v188_.numStateChannels)
			v172_.noMeadowVisibleFilter:setValueCompareParams(DensityValueCompareType.EQUAL, 0)
		end
		v172_.sprayTypeModifier = DensityMapModifier.new(v181_, v182_, v183_, v173_)
		v172_.sprayLevelModifier = DensityMapModifier.new(v175_, v176_, v177_, v173_)
		v172_.outsideFieldFilter = DensityMapFilter.new(v178_, v179_, v180_)
		v172_.outsideFieldFilter:setValueCompareParams(DensityValueCompareType.EQUAL, 0)
		v172_.noGrassVisibleFilter = DensityMapFilter.new(v187_.terrainDataPlaneId, v187_.startStateChannel, v187_.numStateChannels)
		v172_.noGrassVisibleFilter:setValueCompareParams(DensityValueCompareType.EQUAL, 0)
		v172_.sprayTypeFilter = DensityMapFilter.new(v181_, v182_, v183_)
		v172_.sprayTypeFilter:setValueCompareParams(DensityValueCompareType.GREATER, v184_)
		if v184_ > 0 then
			v172_.sprayTypeFilter2 = DensityMapFilter.new(v181_, v182_, v183_)
			v172_.sprayTypeFilter2:setValueCompareParams(DensityValueCompareType.BETWEEN, 0, v184_ - 1)
		end
		v172_.notMaxSprayLevelFilter = DensityMapFilter.new(v175_, v176_, v177_)
		v172_.notMaxSprayLevelFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, 0, v186_ - 1)
		v172_.areaMaskedFilter = DensityMapFilter.new(v181_, v182_, v183_)
		v172_.areaMaskedFilter:setValueCompareParams(DensityValueCompareType.EQUAL, v185_)
		v172_.sprayType = v184_
		v172_.maskValue = v185_
		local v189_ = g_currentMission.stoneSystem
		if v189_:getMapHasStones() then
			local v190_, v191_, v192_ = v189_:getDensityMapData()
			local v193_ = v189_:getMinMaxValues()
			v172_.stoneModifier = DensityMapModifier.new(v190_, v191_, v192_, v173_)
			v172_.stoneModifier:setPolygonRoundingMode(DensityRoundingMode.NEAREST)
			v172_.stoneFilter = DensityMapFilter.new(v190_, v191_, v192_)
			v172_.stoneFilter:setValueCompareParams(DensityValueCompareType.EQUAL, v193_)
		end
		FSDensityMapUtil.functionCache.updateGrassRollerArea = v172_
	end
	local v194_ = v172_.grassModifier
	local v195_ = v172_.grassFilter
	local v196_ = v172_.grassFilterFirstStage
	local v197_ = v172_.grassFilterRolledStage
	local v198_ = v172_.grassRolledCutState
	local v199_ = v172_.meadowModifier
	local v200_ = v172_.meadowFilter
	local v201_ = v172_.meadowFilterFirstStage
	local v202_ = v172_.meadowFilterRolledStage
	local v203_ = v172_.meadowRolledCutState
	local v204_ = v172_.sprayLevelModifier
	local v205_ = v172_.sprayTypeModifier
	local v206_ = v172_.stoneModifier
	local v207_ = v172_.stoneFilter
	local v208_ = v172_.outsideFieldFilter
	local v209_ = v172_.noGrassVisibleFilter
	local v210_ = v172_.noMeadowVisibleFilter
	local v211_ = v172_.sprayTypeFilter
	local v212_ = v172_.sprayTypeFilter2
	local v213_ = v172_.notMaxSprayLevelFilter
	local v214_ = v172_.areaMaskedFilter
	local v215_ = v172_.sprayType
	local v216_ = v172_.maskValue
	v194_:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	if v199_ ~= nil then
		v199_:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	end
	v204_:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	v205_:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	if removeStones ~= false and v206_ ~= nil then
		v206_:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	end
	v205_:executeSet(v216_, v195_, v211_, v213_)
	if v212_ ~= nil then
		v205_:executeSet(v216_, v195_, v212_, v213_)
	end
	if v200_ ~= nil then
		v205_:executeSet(v216_, v200_, v211_, v213_)
		if v212_ ~= nil then
			v205_:executeSet(v216_, v200_, v212_, v213_)
		end
	end
	v205_:executeSet(0, v214_, v208_)
	v205_:executeSet(0, v214_, v209_, v210_)
	local _, _, v217_, v218_ = v204_:executeAddWithStats(1, v214_)
	v205_:executeSet(v215_, v214_)
	v194_:executeSet(2, v196_)
	if v198_ ~= 0 then
		v194_:executeSet(v198_, v197_)
	end
	if v199_ ~= nil then
		v199_:executeSet(2, v201_)
		if v203_ ~= 0 then
			v199_:executeSet(v203_, v202_)
		end
	end
	if removeStones ~= false and v206_ ~= nil then
		v206_:executeAdd(-1, v207_)
	end
	DensityMapHeightUtil.clearArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	return v217_, v218_
end

-- Local values: stoneSystem, functionData, terrainRootNode, stoneMapId, stoneFirstChannel, stoneNumChannels, _, stoneMaxValue, stoneMaskValue, stoneModifier, stoneFilter, stoneMaxReachedFilter, stoneMaxValue
function FSDensityMapUtil.addStoneArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, delta, fieldFilter, customFilter)
	local v228_ = g_currentMission.stoneSystem
	if v228_:getMapHasStones() then
		local v229_ = FSDensityMapUtil.functionCache.addStoneArea
		if v229_ == nil then
			local v230_ = g_terrainNode
			local v231_, v232_, v233_ = v228_:getDensityMapData()
			local _, v234_ = v228_:getMinMaxValues()
			local v235_ = v228_:getMaskValue()
			v229_ = {
				["stoneModifier"] = DensityMapModifier.new(v231_, v232_, v233_, v230_),
				["stoneFilter"] = DensityMapFilter.new(v231_, v232_, v233_)
			}
			v229_.stoneFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, v235_, v234_ - 1)
			v229_.stoneMaxReachedFilter = DensityMapFilter.new(v231_, v232_, v233_)
			v229_.stoneMaxReachedFilter:setValueCompareParams(DensityValueCompareType.GREATER, v234_)
			v229_.stoneMaxValue = v234_
			FSDensityMapUtil.functionCache.addStoneArea = v229_
		end
		local v236_ = v229_.stoneModifier
		local v237_ = v229_.stoneFilter
		local v238_ = v229_.stoneMaxReachedFilter
		local v239_ = v229_.stoneMaxValue
		v236_:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
		if fieldFilter == nil then
			v236_:executeAdd(delta, v237_, customFilter)
		else
			v236_:executeAdd(delta, v237_, fieldFilter, customFilter)
		end
		v236_:executeSet(v239_, v238_)
	end
end

-- Local values: numPixels, totalNumPixels, stoneSystem, functionData, terrainRootNode, stoneMapId, stoneFirstChannel, stoneNumChannels, stoneModifier, _
function FSDensityMapUtil.removeStoneArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	local v246_ = g_currentMission.stoneSystem
	local v247_, v248_
	if v246_:getMapHasStones() then
		local v249_ = FSDensityMapUtil.functionCache.removeStoneArea
		if v249_ == nil then
			local v250_ = g_terrainNode
			local v251_, v252_, v253_ = v246_:getDensityMapData()
			v249_ = {
				["stoneModifier"] = DensityMapModifier.new(v251_, v252_, v253_, v250_)
			}
			FSDensityMapUtil.functionCache.removeStoneArea = v249_
		end
		local v254_ = v249_.stoneModifier
		v254_:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
		local v255_
		v255_, v247_, v248_ = v254_:executeSetWithStats(0)
	else
		v247_ = 0
		v248_ = 0
	end
	return v247_, v248_
end

-- Local values: stoneSystem, functionData, terrainRootNode, stoneMapId, stoneFirstChannel, stoneNumChannels, stoneMinValue, stoneMaxValue, i, stoneFilter, stoneModifier, i, area, _
function FSDensityMapUtil.getStoneArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	local v262_ = g_currentMission.stoneSystem
	if v262_:getMapHasStones() then
		local v263_ = FSDensityMapUtil.functionCache.getStoneArea
		if v263_ == nil then
			local v264_ = g_terrainNode
			local v265_, v266_, v267_ = v262_:getDensityMapData()
			local v268_, v269_ = v262_:getMinMaxValues()
			v263_ = {
				["stoneModifier"] = DensityMapModifier.new(v265_, v266_, v267_, v264_),
				["stoneFilters"] = {}
			}
			for v270_ = 0, v269_ - v268_ do
				local v271_ = DensityMapFilter.new(v265_, v266_, v267_)
				v271_:setValueCompareParams(DensityValueCompareType.EQUAL, v268_ + v270_)
				local v272_ = v263_.stoneFilters
				table.insert(v272_, v271_)
			end
			FSDensityMapUtil.functionCache.getStoneArea = v263_
		end
		local v273_ = v263_.stoneModifier
		v273_:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
		for v274_ = #v263_.stoneFilters, 1, -1 do
			local v275_, _ = v273_:executeGet(v263_.stoneFilters[v274_])
			if v275_ > 0 then
				return v274_
			end
		end
		return 0
	end
end

-- Local values: stoneSystem, functionData, terrainRootNode, fieldGroundSystem, groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, groundAngleMapId, groundAngleFirstChannel, groundAngleNumChannels, sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels, stoneMapId, stoneFirstChannel, stoneNumChannels, stoneMinValue, stoneMaxValue, cultivatedType, firstSowableValue, lastSowableValue, pickedValue, stoneModifier, stoneFilter, sowableFilter, groundTypeModifier, groundAngleModifier, stoneMinValue, cultivatedType, pickedValue, sprayTypeModifier, density, area, totalArea, stoneFactor
function FSDensityMapUtil.updateStonePickerArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, angle)
	local v283_ = g_currentMission.stoneSystem
	if not v283_:getMapHasStones() then
		return 0, 0, 0
	end
	local v284_ = FSDensityMapUtil.functionCache.updateStonePickerArea
	if v284_ == nil then
		local v285_ = g_terrainNode
		local v286_ = g_currentMission.fieldGroundSystem
		local v287_, v288_, v289_ = v286_:getDensityMapData(FieldDensityMap.GROUND_TYPE)
		local v290_, v291_, v292_ = v286_:getDensityMapData(FieldDensityMap.GROUND_ANGLE)
		local v293_, v294_, v295_ = v286_:getDensityMapData(FieldDensityMap.SPRAY_TYPE)
		local v296_, v297_, v298_ = v283_:getDensityMapData()
		local v299_, v300_ = v283_:getMinMaxValues()
		local v301_ = FieldGroundType.getValueByType(FieldGroundType.CULTIVATED)
		local v302_, v303_ = v286_:getSowableRange()
		local v304_ = v283_:getPickedValue()
		v284_ = {
			["stoneModifier"] = DensityMapModifier.new(v296_, v297_, v298_, v285_),
			["stoneFilter"] = DensityMapFilter.new(v296_, v297_, v298_)
		}
		v284_.stoneFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, v299_, v300_)
		v284_.sowableFilter = DensityMapFilter.new(v287_, v288_, v289_)
		v284_.sowableFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, v302_, v303_)
		v284_.groundTypeModifier = DensityMapModifier.new(v287_, v288_, v289_, v285_)
		v284_.groundAngleModifier = DensityMapModifier.new(v290_, v291_, v292_, v285_)
		v284_.stoneMinValue = v299_
		v284_.cultivatedType = v301_
		v284_.pickedValue = v304_
		v284_.sprayTypeModifier = DensityMapModifier.new(v293_, v294_, v295_, v285_)
		FSDensityMapUtil.functionCache.updateStonePickerArea = v284_
	end
	local v305_ = v284_.stoneModifier
	local v306_ = v284_.stoneFilter
	local v307_ = v284_.sowableFilter
	local v308_ = v284_.groundTypeModifier
	local v309_ = v284_.groundAngleModifier
	local v310_ = v284_.stoneMinValue
	local v311_ = v284_.cultivatedType
	local v312_ = v284_.pickedValue
	local v313_ = v284_.sprayTypeModifier
	v308_:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	v309_:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	v305_:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	v313_:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	local v314_, v315_, v316_ = v305_:executeSetWithStats(v312_, v306_, v307_)
	v308_:executeSet(v311_, v307_)
	v309_:executeSet(angle or 0, v307_)
	v313_:executeSet(0, v307_)
	FSDensityMapUtil.resetDisplacementArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, v307_)
	local v317_ = v314_ - v315_ * (v310_ - 1)
	local v318_ = math.max(0, v317_)
	return v315_ <= 0 and 0 or v318_ / v315_, v315_, v316_
end

-- Local values: functionData, terrainRootNode, fieldGroundSystem, groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, sprayLevelMapId, sprayLevelFirstChannel, sprayLevelNumChannels, groundAngleMapId, groundAngleFirstChannel, groundAngleNumChannels, sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels, removeFieldMultiModifier, clearFieldModifier, clearSprayModifier, clearSprayLeveldModifier, clearAngleModifier, plowLevelMapId, plowLevelFirstChannel, plowLevelNumChannels, clearPlowLevelModifier, limeLevelMapId, limeLevelFirstChannel, limeLevelNumChannels, clearLimeLevelModifier, _, desc, clearFruitModifier, i, id, numChannels, clearDynamicFoliageLayerModifier, removeFieldMultiModifier
function FSDensityMapUtil.removeFieldArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, deleteAll)
	local v326_ = FSDensityMapUtil.functionCache.removeFieldArea
	if v326_ == nil then
		local v327_ = g_terrainNode
		local v328_ = g_currentMission.fieldGroundSystem
		local v329_, v330_, v331_ = v328_:getDensityMapData(FieldDensityMap.GROUND_TYPE)
		local v332_, v333_, v334_ = v328_:getDensityMapData(FieldDensityMap.SPRAY_LEVEL)
		local v335_, v336_, v337_ = v328_:getDensityMapData(FieldDensityMap.GROUND_ANGLE)
		local v338_, v339_, v340_ = v328_:getDensityMapData(FieldDensityMap.SPRAY_TYPE)
		v326_ = {}
		local v341_ = DensityMapMultiModifier.new()
		v341_:addExecuteSet(0, (DensityMapModifier.new(v329_, v330_, v331_, v327_)))
		v341_:addExecuteSet(0, (DensityMapModifier.new(v338_, v339_, v340_, v327_)))
		v341_:addExecuteSet(0, (DensityMapModifier.new(v332_, v333_, v334_, v327_)))
		v341_:addExecuteSet(0, (DensityMapModifier.new(v335_, v336_, v337_, v327_)))
		if Platform.gameplay.usePlowCounter then
			local v342_, v343_, v344_ = v328_:getDensityMapData(FieldDensityMap.PLOW_LEVEL)
			v341_:addExecuteSet(0, (DensityMapModifier.new(v342_, v343_, v344_, v327_)))
		end
		if Platform.gameplay.useLimeCounter then
			local v345_, v346_, v347_ = v328_:getDensityMapData(FieldDensityMap.LIME_LEVEL)
			v341_:addExecuteSet(0, (DensityMapModifier.new(v345_, v346_, v347_, v327_)))
		end
		for _, v348_ in pairs(g_fruitTypeManager:getFruitTypes()) do
			if v348_.terrainDataPlaneId ~= nil and (deleteAll or v348_.isCultivationAllowed) then
				local v349_ = DensityMapModifier.new(v348_.terrainDataPlaneId, v348_.startStateChannel, v348_.numStateChannels, v327_)
				v349_:setNewTypeIndexMode(DensityIndexCompareMode.ZERO)
				v341_:addExecuteSet(0, v349_)
			end
		end
		for v350_ = 1, #g_currentMission.dynamicFoliageLayers do
			local v351_ = g_currentMission.dynamicFoliageLayers[v350_]
			local v352_ = getTerrainDetailNumChannels(v351_)
			v341_:addExecuteSet(0, (DensityMapModifier.new(v351_, 0, v352_, v327_)))
		end
		v326_.removeFieldMultiModifier = v341_
		FSDensityMapUtil.functionCache.removeFieldArea = v326_
	end
	local v353_ = v326_.removeFieldMultiModifier
	v353_:updateParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	v353_:execute()
end

-- Local values: functionData, terrainRootNode, fieldGroundSystem, groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, sprayLevelMapId, sprayLevelFirstChannel, sprayLevelNumChannels, groundAngleMapId, groundAngleFirstChannel, groundAngleNumChannels, sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels, removeFieldMultiModifier, clearFieldModifier, clearSprayModifier, clearSprayLeveldModifier, clearAngleModifier, plowLevelMapId, plowLevelFirstChannel, plowLevelNumChannels, clearPlowLevelModifier, limeLevelMapId, limeLevelFirstChannel, limeLevelNumChannels, clearLimeLevelModifier, _, desc, clearFruitModifier, i, id, numChannels, clearDynamicFoliageLayerModifier, removeFieldMultiModifier, i
function FSDensityMapUtil.removeFieldPolygon(polygonVertices, deleteAll)
	local v356_ = FSDensityMapUtil.functionCache.removeFieldArea
	if v356_ == nil then
		local v357_ = g_terrainNode
		local v358_ = g_currentMission.fieldGroundSystem
		local v359_, v360_, v361_ = v358_:getDensityMapData(FieldDensityMap.GROUND_TYPE)
		local v362_, v363_, v364_ = v358_:getDensityMapData(FieldDensityMap.SPRAY_LEVEL)
		local v365_, v366_, v367_ = v358_:getDensityMapData(FieldDensityMap.GROUND_ANGLE)
		local v368_, v369_, v370_ = v358_:getDensityMapData(FieldDensityMap.SPRAY_TYPE)
		v356_ = {}
		local v371_ = DensityMapMultiModifier.new()
		v371_:addExecuteSet(0, (DensityMapModifier.new(v359_, v360_, v361_, v357_)))
		v371_:addExecuteSet(0, (DensityMapModifier.new(v368_, v369_, v370_, v357_)))
		v371_:addExecuteSet(0, (DensityMapModifier.new(v362_, v363_, v364_, v357_)))
		v371_:addExecuteSet(0, (DensityMapModifier.new(v365_, v366_, v367_, v357_)))
		if Platform.gameplay.usePlowCounter then
			local v372_, v373_, v374_ = v358_:getDensityMapData(FieldDensityMap.PLOW_LEVEL)
			v371_:addExecuteSet(0, (DensityMapModifier.new(v372_, v373_, v374_, v357_)))
		end
		if Platform.gameplay.useLimeCounter then
			local v375_, v376_, v377_ = v358_:getDensityMapData(FieldDensityMap.LIME_LEVEL)
			v371_:addExecuteSet(0, (DensityMapModifier.new(v375_, v376_, v377_, v357_)))
		end
		for _, v378_ in pairs(g_fruitTypeManager:getFruitTypes()) do
			if v378_.terrainDataPlaneId ~= nil and (deleteAll or v378_.isCultivationAllowed) then
				local v379_ = DensityMapModifier.new(v378_.terrainDataPlaneId, v378_.startStateChannel, v378_.numStateChannels, v357_)
				v379_:setNewTypeIndexMode(DensityIndexCompareMode.ZERO)
				v371_:addExecuteSet(0, v379_)
			end
		end
		for v380_ = 1, #g_currentMission.dynamicFoliageLayers do
			local v381_ = g_currentMission.dynamicFoliageLayers[v380_]
			local v382_ = getTerrainDetailNumChannels(v381_)
			v371_:addExecuteSet(0, (DensityMapModifier.new(v381_, 0, v382_, v357_)))
		end
		v356_.removeFieldMultiModifier = v371_
		FSDensityMapUtil.functionCache.removeFieldArea = v356_
	end
	local v383_ = v356_.removeFieldMultiModifier
	for v384_ = 1, #polygonVertices, 2 do
		v383_:addPolygonPointWorldCoords(polygonVertices[v384_], polygonVertices[v384_ + 1])
	end
	v383_:execute()
	v383_:clearPolygonPoints()
end

-- Local values: functionData, missionInfo, terrainRootNode, fieldGroundSystem, groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, groundAngleMapId, groundAngleFirstChannel, groundAngleNumChannels, cultivatedType, _, desc, modifier, modifierAngle, filterCultivatorArea, filterField, notCultivatedFilter, cultivatedType, noFruitFilter, _, areaBefore, _, totalArea, changedArea, _, areaAfter, _
function FSDensityMapUtil.updateCultivatorArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, createField, limitFruitDestructionToField, angle, blockedSprayTypeIndex, setsWeeds, disableStones)
	local v396_ = FSDensityMapUtil.functionCache.updateCultivatorArea
	local v397_ = g_currentMission.missionInfo
	if v396_ == nil then
		local v398_ = g_terrainNode
		local v399_ = g_currentMission.fieldGroundSystem
		local v400_, v401_, v402_ = v399_:getDensityMapData(FieldDensityMap.GROUND_TYPE)
		local v403_, v404_, v405_ = v399_:getDensityMapData(FieldDensityMap.GROUND_ANGLE)
		local v406_ = FieldGroundType.getValueByType(FieldGroundType.CULTIVATED)
		v396_ = {
			["modifier"] = DensityMapModifier.new(v400_, v401_, v402_, v398_),
			["modifierAngle"] = DensityMapModifier.new(v403_, v404_, v405_, v398_),
			["filterCultivatorArea"] = DensityMapFilter.new(v400_, v401_, v402_)
		}
		v396_.filterCultivatorArea:setValueCompareParams(DensityValueCompareType.EQUAL, v406_)
		v396_.filterField = DensityMapFilter.new(v400_, v401_, v402_)
		v396_.filterField:setValueCompareParams(DensityValueCompareType.GREATER, 0)
		v396_.notCultivatedFilter = DensityMapFilter.new(v400_, v401_, v402_)
		v396_.notCultivatedFilter:setValueCompareParams(DensityValueCompareType.NOTEQUAL, v406_)
		v396_.cultivatedType = v406_
		v396_.noFruitFilter = nil
		for _, v407_ in pairs(g_fruitTypeManager:getFruitTypes()) do
			if v407_.terrainDataPlaneId ~= nil then
				v396_.noFruitFilter = DensityMapFilter.new(v407_.terrainDataPlaneId, v407_.startStateChannel, v407_.numStateChannels)
				v396_.noFruitFilter:setValueCompareParams(DensityValueCompareType.EQUAL, 0)
				v396_.noFruitFilter:setTypeIndexCompareMode(DensityTypeCompareType.ALWAYS)
				break
			end
		end
		FSDensityMapUtil.functionCache.updateCultivatorArea = v396_
	end
	local v408_ = v396_.modifier
	local v409_ = v396_.modifierAngle
	local v410_ = v396_.filterCultivatorArea
	local v411_ = v396_.filterField
	local v412_ = v396_.notCultivatedFilter
	local v413_ = v396_.cultivatedType
	local v414_ = v396_.noFruitFilter
	local v415_ = Utils.getNoNil(createField, true)
	local v416_ = Utils.getNoNil(limitFruitDestructionToField, true)
	local v417_ = angle or 0
	FSDensityMapUtil.updateDestroyCommonArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, v416_, false)
	v408_:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	v409_:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	local _, v418_, _ = v408_:executeGet(v410_)
	FSDensityMapUtil.removeSprayArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, blockedSprayTypeIndex)
	if v415_ then
		v411_ = nil
	end
	if v397_.stonesEnabled and disableStones ~= true then
		FSDensityMapUtil.addStoneArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, 1, v411_, v412_)
	end
	if v397_.weedsEnabled then
		FSDensityMapUtil.setSparseWeedArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	end
	local _, _, v419_ = v408_:executeSetWithStats(v413_, v411_, v414_)
	v409_:executeSet(v417_, v410_)
	local _, v420_, _ = v408_:executeGet(v410_)
	local v421_ = v420_ - v418_
	DensityMapHeightUtil.clearArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	return v421_, v419_
end

-- Local values: functionData, terrainRootNode, fieldGroundSystem, groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, groundAngleMapId, groundAngleFirstChannel, groundAngleNumChannels, stubbleTillageType, seedbedType, sprayLevelMapId, sprayLevelFirstChannel, sprayLevelNumChannels, sprayLevelMaxValue, multiModifiers, multiModifier, terrainRootNode, fruitModifier, fieldFilter, sprayLevelFilter, sprayLevelModifier, index, desc, fruitFilter, preparingModifier, preparingFilter, i, id, numChannels, modifier, modifier, modifierAngle, fieldFilter, seedbedTypeFilter, stubbleTillageFilter, notStubbleTillageFilter, seedbedType, noFruitFilter, _, areaBeforeSeedbed, _, _, _, totalArea, _, areaBeforeStubbleTillage, _, _, areaAfterSeedbed, _, _, areaAfterStubbleTillage, _, changedArea
function FSDensityMapUtil.updateDiscHarrowArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, createField, limitFruitDestructionToField, angle, blockedSprayTypeIndex)
	local v432_ = Utils.getNoNil(createField, true)
	local v433_ = Utils.getNoNil(limitFruitDestructionToField, true)
	local v434_ = angle or 0
	local v435_ = FSDensityMapUtil.functionCache.updateDiscHarrowArea
	if v435_ == nil then
		local v436_ = g_terrainNode
		local v437_ = g_currentMission.fieldGroundSystem
		local v438_, v439_, v440_ = v437_:getDensityMapData(FieldDensityMap.GROUND_TYPE)
		local v441_, v442_, v443_ = v437_:getDensityMapData(FieldDensityMap.GROUND_ANGLE)
		local v444_ = FieldGroundType.getValueByType(FieldGroundType.STUBBLE_TILLAGE)
		local v445_ = FieldGroundType.getValueByType(FieldGroundType.SEEDBED)
		local v446_, v447_, v448_ = v437_:getDensityMapData(FieldDensityMap.SPRAY_LEVEL)
		local v449_ = v437_:getMaxValue(FieldDensityMap.SPRAY_LEVEL)
		v435_ = {
			["modifier"] = DensityMapModifier.new(v438_, v439_, v440_, v436_),
			["modifierAngle"] = DensityMapModifier.new(v441_, v442_, v443_, v436_),
			["fieldFilter"] = DensityMapFilter.new(v438_, v439_, v440_)
		}
		v435_.fieldFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)
		v435_.seedbedTypeFilter = DensityMapFilter.new(v438_, v439_, v440_)
		v435_.seedbedTypeFilter:setValueCompareParams(DensityValueCompareType.EQUAL, v445_)
		v435_.stubbleTillageFilter = DensityMapFilter.new(v438_, v439_, v440_)
		v435_.stubbleTillageFilter:setValueCompareParams(DensityValueCompareType.EQUAL, v444_)
		v435_.notStubbleTillageFilter = DensityMapFilter.new(v438_, v439_, v440_)
		v435_.notStubbleTillageFilter:setValueCompareParams(DensityValueCompareType.NOTEQUAL, v444_)
		v435_.sprayLevelModifier = DensityMapModifier.new(v446_, v447_, v448_, v436_)
		v435_.sprayLevelFilter = DensityMapFilter.new(v446_, v447_, v448_)
		v435_.sprayLevelFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, 0, v449_ - 1)
		v435_.multiModifiers = {}
		v435_.fruitFilter = {}
		v435_.preparingModifier = {}
		v435_.preparingFilter = {}
		v435_.noFruitFilter = nil
		v435_.stubbleTillageType = v444_
		v435_.seedbedType = v445_
		FSDensityMapUtil.functionCache.updateDiscHarrowArea = v435_
	end
	local v450_ = v435_.multiModifiers
	local v451_ = v450_[v432_]
	if v451_ == nil then
		local v452_ = g_terrainNode
		local v453_ = nil
		local v454_
		if v432_ then
			v454_ = nil
		else
			v454_ = v435_.fieldFilter
		end
		local v455_ = v435_.sprayLevelFilter
		local v456_ = v435_.sprayLevelModifier
		v451_ = DensityMapMultiModifier.new()
		v450_[v432_] = v451_
		for v457_, v458_ in pairs(g_fruitTypeManager:getFruitTypes()) do
			if v458_.terrainDataPlaneId ~= nil then
				if v435_.noFruitFilter == nil then
					v435_.noFruitFilter = DensityMapFilter.new(v458_.terrainDataPlaneId, v458_.startStateChannel, v458_.numStateChannels)
					v435_.noFruitFilter:setValueCompareParams(DensityValueCompareType.EQUAL, 0)
					v435_.noFruitFilter:setTypeIndexCompareMode(DensityTypeCompareType.ALWAYS)
				end
				if v458_.isCultivationAllowed then
					local v459_ = v435_.fruitFilter[v457_]
					if v459_ == nil then
						v459_ = DensityMapFilter.new(v458_.terrainDataPlaneId, v458_.startStateChannel, v458_.numStateChannels)
						v459_:setValueCompareParams(DensityValueCompareType.GREATER, 1)
						v435_.fruitFilter[v457_] = v459_
					end
					v459_:setValueCompareParams(DensityValueCompareType.GREATER, 1)
					v451_:addExecuteSet(v435_.stubbleTillageType, v435_.modifier, v459_, v454_)
					v459_:setValueCompareParams(DensityValueCompareType.BETWEEN, 2, v458_.numGrowthStates)
					v459_:setTypeIndexCompareMode(DensityTypeCompareType.EQUAL)
					v451_:addExecuteAdd(1, v456_, v455_, v459_, v454_)
					if v458_.terrainDataPlaneIdHaulm ~= nil then
						local v460_ = v435_.preparingModifier[v457_]
						if v460_ == nil then
							v460_ = DensityMapModifier.new(v458_.terrainDataPlaneIdHaulm, v458_.startStateChannelHaulm, v458_.numStateChannelsHaulm)
							v435_.preparingModifier[v457_] = v460_
						end
						local v461_ = v435_.preparingFilter[v457_]
						if v461_ == nil then
							v461_ = DensityMapFilter.new(v458_.terrainDataPlaneIdHaulm, v458_.startStateChannelHaulm, v458_.numStateChannelsHaulm)
							v461_:setValueCompareParams(DensityValueCompareType.GREATER, 0)
							v461_:setTypeIndexCompareMode(DensityTypeCompareType.ALWAYS)
							v435_.preparingFilter[v457_] = v461_
						end
						v451_:addExecuteSet(0, v460_, v461_)
					end
					if v453_ == nil then
						v453_ = DensityMapModifier.new(v458_.terrainDataPlaneId, v458_.startStateChannel, v458_.numStateChannels)
					else
						v453_:resetDensityMapAndChannels(v458_.terrainDataPlaneId, v458_.startStateChannel, v458_.numStateChannels)
					end
					v453_:setNewTypeIndexMode(DensityIndexCompareMode.ZERO)
					v459_:setValueCompareParams(DensityValueCompareType.GREATER, 0)
					if v433_ then
						v451_:addExecuteSet(0, v453_, v459_, v454_)
					else
						v451_:addExecuteSet(0, v453_, v459_)
					end
				end
			end
		end
		for v462_ = 1, #g_currentMission.dynamicFoliageLayers do
			local v463_ = g_currentMission.dynamicFoliageLayers[v462_]
			local v464_ = getTerrainDetailNumChannels(v463_)
			local v465_ = v435_.dynamicFoliageModifier[v463_]
			if v465_ == nil then
				v465_ = DensityMapModifier.new(v463_, 0, v464_, v452_)
				v435_.dynamicFoliageModifier[v463_] = v465_
			end
			v451_:addExecuteSet(0, v465_, v454_)
		end
		FSDensityMapUtil.multiModifierAddResetDisplacement(v451_)
	end
	local v466_ = v435_.modifier
	local v467_ = v435_.modifierAngle
	local v468_ = v435_.fieldFilter
	local v469_ = v435_.seedbedTypeFilter
	local v470_ = v435_.stubbleTillageFilter
	local v471_ = v435_.notStubbleTillageFilter
	local v472_ = v435_.seedbedType
	local v473_ = v435_.noFruitFilter
	if v432_ then
		v468_ = nil
	end
	local _, v474_, _ = v466_:executeGet(v469_)
	local _, _, v475_ = v466_:executeGet()
	v466_:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	v467_:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	v466_:executeSet(v472_, v471_, v468_, v473_)
	v467_:executeSet(v434_, v469_)
	v467_:executeSet(v434_, v470_)
	local _, v476_, _ = v466_:executeGet(v470_)
	v451_:updateParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	v451_:execute()
	local _, v477_, _ = v466_:executeGet(v469_)
	local _, v478_, _ = v466_:executeGet(v470_)
	FSDensityMapUtil.removeSprayArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, blockedSprayTypeIndex)
	DensityMapHeightUtil.clearArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	if g_currentMission.missionInfo.weedsEnabled then
		FSDensityMapUtil.setSparseWeedArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	else
		FSDensityMapUtil.removeWeedArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	end
	return v477_ - v474_ + (v478_ - v476_), v475_
end

-- Local values: functionData, terrainRootNode, fieldGroundSystem, groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, groundAngleMapId, groundAngleFirstChannel, groundAngleNumChannels, cultivatedType, plowedType, seedbedType, modifier, modifierAngle, filterCultivatorArea, filterPlowArea, filterSeedbedArea, seedbedType, _, areaBefore, _, totalArea, changedArea, _, areaAfter, _
function FSDensityMapUtil.updatePlowPackerArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, angle)
	local v486_ = FSDensityMapUtil.functionCache.updatePlowPackerArea
	if v486_ == nil then
		local v487_ = g_terrainNode
		local v488_ = g_currentMission.fieldGroundSystem
		local v489_, v490_, v491_ = v488_:getDensityMapData(FieldDensityMap.GROUND_TYPE)
		local v492_, v493_, v494_ = v488_:getDensityMapData(FieldDensityMap.GROUND_ANGLE)
		local v495_ = FieldGroundType.getValueByType(FieldGroundType.CULTIVATED)
		local v496_ = FieldGroundType.getValueByType(FieldGroundType.PLOWED)
		local v497_ = FieldGroundType.getValueByType(FieldGroundType.SEEDBED)
		v486_ = {
			["modifier"] = DensityMapModifier.new(v489_, v490_, v491_, v487_),
			["modifierAngle"] = DensityMapModifier.new(v492_, v493_, v494_, v487_),
			["filterCultivatorArea"] = DensityMapFilter.new(v489_, v490_, v491_)
		}
		v486_.filterCultivatorArea:setValueCompareParams(DensityValueCompareType.EQUAL, v495_)
		v486_.filterPlowArea = DensityMapFilter.new(v489_, v490_, v491_)
		v486_.filterPlowArea:setValueCompareParams(DensityValueCompareType.EQUAL, v496_)
		v486_.filterSeedbedArea = DensityMapFilter.new(v489_, v490_, v491_)
		v486_.filterSeedbedArea:setValueCompareParams(DensityValueCompareType.EQUAL, v497_)
		v486_.seedbedType = v497_
		FSDensityMapUtil.functionCache.updatePlowPackerArea = v486_
	end
	local v498_ = v486_.modifier
	local v499_ = v486_.modifierAngle
	local v500_ = v486_.filterCultivatorArea
	local v501_ = v486_.filterPlowArea
	local v502_ = v486_.filterSeedbedArea
	local v503_ = v486_.seedbedType
	v498_:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	v499_:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	FSDensityMapUtil.resetDisplacementArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	local _, v504_, _ = v498_:executeGet(v502_)
	v498_:executeSet(v503_, v501_)
	local _, _, v505_ = v498_:executeSetWithStats(v503_, v500_)
	v499_:executeSet(angle or 0, v502_)
	local _, v506_, _ = v498_:executeGet(v502_)
	return v506_ - v504_, v505_
end

-- Local values: functionData, terrainRootNode, fieldGroundSystem, groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, plowLevelMapId, plowLevelFirstChannel, plowLevelNumChannels, plowLevelMaxValue, modifier, fieldFilter, notMaxPlowLevelFilter, plowLevelMaxValue, _, changedArea, totalArea
function FSDensityMapUtil.updateSubsoilerArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, forced)
	if not Platform.gameplay.usePlowCounter then
		return 0, 0
	end
	local v514_ = FSDensityMapUtil.functionCache.updateSubsoilerArea
	if v514_ == nil then
		local v515_ = g_terrainNode
		local v516_ = g_currentMission.fieldGroundSystem
		local v517_, v518_, v519_ = v516_:getDensityMapData(FieldDensityMap.GROUND_TYPE)
		local v520_, v521_, v522_ = v516_:getDensityMapData(FieldDensityMap.PLOW_LEVEL)
		local v523_ = v516_:getMaxValue(FieldDensityMap.PLOW_LEVEL)
		v514_ = {
			["modifier"] = DensityMapModifier.new(v520_, v521_, v522_, v515_),
			["fieldFilter"] = DensityMapFilter.new(v517_, v518_, v519_)
		}
		v514_.fieldFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)
		v514_.notMaxPlowLevelFilter = DensityMapFilter.new(v520_, v521_, v522_)
		v514_.notMaxPlowLevelFilter:setValueCompareParams(DensityValueCompareType.NOTEQUAL, v523_)
		v514_.plowLevelMaxValue = v523_
		FSDensityMapUtil.functionCache.updateSubsoilerArea = v514_
	end
	local v524_ = v514_.modifier
	local v525_ = v514_.fieldFilter
	local v526_ = v514_.notMaxPlowLevelFilter
	local v527_ = v514_.plowLevelMaxValue
	v524_:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	if forced then
		v525_ = nil
	end
	if g_currentMission.missionInfo.stonesEnabled then
		FSDensityMapUtil.addStoneArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, 2, v525_, v526_)
	end
	FSDensityMapUtil.resetDisplacementArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	local _, v528_, v529_ = v524_:executeSetWithStats(v527_, v525_)
	return v528_, v529_
end

-- Local values: functionData, terrainRootNode, fieldGroundSystem, groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, groundAngleMapId, groundAngleFirstChannel, groundAngleNumChannels, plowedType, plowLevelMapId, plowLevelFirstChannel, plowLevelNumChannels, _, desc, groundTypeModifier, angleModifier, levelModifier, plowStateFilter, fieldFilter, notPlowedFilter, plowLevelMaxValue, plowedType, noFruitFilter, _, areaBefore, _, totalArea, _, areaAfter, _, changedArea
function FSDensityMapUtil.updatePlowArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, createField, limitFruitDestructionToField, angle, resetPlowLevel, stonesDisabled)
	local v541_ = FSDensityMapUtil.functionCache.updatePlowArea
	if v541_ == nil then
		local v542_ = g_terrainNode
		local v543_ = g_currentMission.fieldGroundSystem
		local v544_, v545_, v546_ = v543_:getDensityMapData(FieldDensityMap.GROUND_TYPE)
		local v547_, v548_, v549_ = v543_:getDensityMapData(FieldDensityMap.GROUND_ANGLE)
		local v550_ = FieldGroundType.getValueByType(FieldGroundType.PLOWED)
		v541_ = {
			["groundTypeModifier"] = DensityMapModifier.new(v544_, v545_, v546_, v542_),
			["angleModifier"] = DensityMapModifier.new(v547_, v548_, v549_, v542_),
			["plowStateFilter"] = DensityMapFilter.new(v544_, v545_, v546_)
		}
		v541_.plowStateFilter:setValueCompareParams(DensityValueCompareType.EQUAL, v550_)
		v541_.fieldFilter = DensityMapFilter.new(v544_, v545_, v546_)
		v541_.fieldFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)
		v541_.notPlowedFilter = DensityMapFilter.new(v544_, v545_, v546_)
		v541_.notPlowedFilter:setValueCompareParams(DensityValueCompareType.NOTEQUAL, v550_)
		v541_.plowedType = v550_
		if Platform.gameplay.usePlowCounter then
			local v551_, v552_, v553_ = v543_:getDensityMapData(FieldDensityMap.PLOW_LEVEL)
			v541_.levelModifier = DensityMapModifier.new(v551_, v552_, v553_, v542_)
			v541_.plowLevelMaxValue = v543_:getMaxValue(FieldDensityMap.PLOW_LEVEL)
		end
		v541_.noFruitFilter = nil
		for _, v554_ in pairs(g_fruitTypeManager:getFruitTypes()) do
			if v554_.terrainDataPlaneId ~= nil then
				v541_.noFruitFilter = DensityMapFilter.new(v554_.terrainDataPlaneId, v554_.startStateChannel, v554_.numStateChannels)
				v541_.noFruitFilter:setValueCompareParams(DensityValueCompareType.EQUAL, 0)
				v541_.noFruitFilter:setTypeIndexCompareMode(DensityTypeCompareType.ALWAYS)
				break
			end
		end
		FSDensityMapUtil.functionCache.updatePlowArea = v541_
	end
	local v555_ = v541_.groundTypeModifier
	local v556_ = v541_.angleModifier
	local v557_ = v541_.levelModifier
	local v558_ = v541_.plowStateFilter
	local v559_ = v541_.fieldFilter
	local v560_ = v541_.notPlowedFilter
	local v561_ = v541_.plowLevelMaxValue
	local v562_ = v541_.plowedType
	local v563_ = v541_.noFruitFilter
	local v564_ = Utils.getNoNil(createField, true)
	local v565_ = Utils.getNoNil(limitFruitDestructionToField, true)
	local v566_ = angle or 0
	local v567_ = Utils.getNoNil(resetPlowLevel, true)
	FSDensityMapUtil.updateDestroyCommonArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, v565_, false)
	v555_:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	v556_:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	local _, v568_, _ = v555_:executeGet(v558_)
	if v564_ then
		FSDensityMapUtil.clearDecoArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
		v559_ = nil
	end
	if g_currentMission.missionInfo.stonesEnabled and stonesDisabled ~= true then
		FSDensityMapUtil.addStoneArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, 1, v559_, v560_)
	end
	local _, _, v569_ = v555_:executeSetWithStats(v562_, v559_, v563_)
	if v567_ and v557_ ~= nil then
		v557_:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
		v557_:executeSet(v561_, v559_)
	end
	v556_:executeSet(v566_, v559_)
	FSDensityMapUtil.resetSprayArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, true)
	if g_currentMission.missionInfo.weedsEnabled then
		FSDensityMapUtil.setWeedBlockingState(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, v558_)
	end
	local _, v570_, _ = v555_:executeGet(v558_)
	return v570_ - v568_, v569_
end

-- Local values: functionData, terrainRootNode, fieldGroundSystem, groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, displacementMapId, displacementFirstChannel, displacementNumChannels, displacementCustomFlagMapId, displacementCustomFlagFirstChannel, displacementCustomFlagNumChannels, modifier, modifierCustom, fieldFilter, texture
function FSDensityMapUtil.updatePlowShareArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, createField, limitFruitDestructionToField, clearFoliageOffset)
	local v580_ = FSDensityMapUtil.functionCache.updatePlowShareArea
	if v580_ == nil then
		v580_ = {}
		local v581_ = g_terrainNode
		local v582_ = g_currentMission.fieldGroundSystem
		local v583_, v584_, v585_ = v582_:getDensityMapData(FieldDensityMap.GROUND_TYPE)
		local v586_, v587_, v588_ = v582_:getDisplacementData()
		v580_.modifier = DensityMapModifier.new(v586_, v587_, v588_, v581_)
		v580_.texture = DPUTexture.new("data/maps/textures/terrain/ground/groundType_plowShare_displacement.png")
		local v589_, v590_, v591_ = v582_:getDisplacementCustomFlagData()
		v580_.modifierCustom = DensityMapModifier.new(v589_, v590_, v591_, v581_)
		v580_.fieldFilter = DensityMapFilter.new(v583_, v584_, v585_)
		v580_.fieldFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)
		FSDensityMapUtil.functionCache.updatePlowShareArea = v580_
	end
	local v592_ = v580_.modifier
	local v593_ = v580_.modifierCustom
	local v594_ = v580_.fieldFilter
	local _ = v580_.texture
	if createField then
		v594_ = nil
	end
	v592_:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	v593_:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	v592_:executeSet(0, v594_)
	v593_:executeSet(1, v594_)
	local v595_, v596_, v597_, v598_, v599_, v600_ = MathUtil.getWorldParallelogramOffset(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, clearFoliageOffset)
	FSDensityMapUtil.updateDestroyCommonArea(v595_, v596_, v597_, v598_, v599_, v600_, limitFruitDestructionToField, nil, false)
end

-- Local values: functionData, area
function FSDensityMapUtil.resetDisplacementArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, filter1, filter2)
	local v609_ = FSDensityMapUtil.functionCache.resetDisplacementArea
	local v610_ = (v609_ == nil and {
		["area"] = DensityMapParallelogram.new()
	} or v609_).area
	v610_:updateFromWorldPositions(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	FSDensityMapUtil.resetDisplacement(v610_, filter1, filter2)
end

-- Local values: terrainRootNode, fieldGroundSystem, displacementMapId, displacementFirstChannel, displacementNumChannels, modifier, resetValue, displacementCustomFlagMapId, displacementCustomFlagFirstChannel, displacementCustomFlagNumChannels, modifierCustom
function FSDensityMapUtil.multiModifierAddResetDisplacement(multiModifier, filter1, filter2)
	local v614_ = g_terrainNode
	local v615_ = g_currentMission.fieldGroundSystem
	local v616_, v617_, v618_ = v615_:getDisplacementData()
	local v619_ = DensityMapModifier.new(v616_, v617_, v618_, v614_)
	local v620_ = v615_:getDisplacementResetValue()
	local v621_, v622_, v623_ = v615_:getDisplacementCustomFlagData()
	local v624_ = DensityMapModifier.new(v621_, v622_, v623_, v614_)
	multiModifier:addExecuteSet(v620_, v619_, filter1, filter2)
	multiModifier:addExecuteSet(0, v624_, filter1, filter2)
end

-- Local values: functionData, terrainRootNode, fieldGroundSystem, displacementMapId, displacementFirstChannel, displacementNumChannels, displacementCustomFlagMapId, displacementCustomFlagFirstChannel, displacementCustomFlagNumChannels, modifier, modifierCustom, resetValue
function FSDensityMapUtil.resetDisplacement(densityMapArea, filter1, filter2)
	local v628_ = FSDensityMapUtil.functionCache.resetDisplacement
	if v628_ == nil then
		v628_ = {}
		local v629_ = g_terrainNode
		local v630_ = g_currentMission.fieldGroundSystem
		local v631_, v632_, v633_ = v630_:getDisplacementData()
		v628_.modifier = DensityMapModifier.new(v631_, v632_, v633_, v629_)
		v628_.resetValue = v630_:getDisplacementResetValue()
		local v634_, v635_, v636_ = v630_:getDisplacementCustomFlagData()
		v628_.modifierCustom = DensityMapModifier.new(v634_, v635_, v636_, v629_)
		FSDensityMapUtil.functionCache.resetDisplacement = v628_
	end
	local v637_ = v628_.modifier
	local v638_ = v628_.modifierCustom
	local v639_ = v628_.resetValue
	densityMapArea:applyToModifier(v637_)
	densityMapArea:applyToModifier(v638_)
	v637_:executeSet(v639_, filter1, filter2)
	v638_:executeSet(0, filter1, filter2)
end

-- Local values: functionData, terrainRootNode, fieldGroundSystem, groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, sprayLevelMapId, sprayLevelFirstChannel, sprayLevelNumChannels, sprayLevelMaxValue, multiModifiers, multiModifier, terrainRootNode, sprayLevelFilter, sprayLevelModifier, fruitModifier, fieldFilter, index, desc, fruitFilter, preparingModifier, preparingFilter, i, id, numChannels, modifier
function FSDensityMapUtil.updateDestroyCommonArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, onlyOnFields, deleteAll, resetDisplacement)
	local v649_ = Utils.getNoNil(onlyOnFields, false)
	local v650_ = Utils.getNoNil(deleteAll, false)
	local v651_ = Utils.getNoNil(resetDisplacement, true)
	local v652_ = FSDensityMapUtil.functionCache.updateDestroyCommonArea
	if v652_ == nil then
		local v653_ = g_terrainNode
		local v654_ = g_currentMission.fieldGroundSystem
		local v655_, v656_, v657_ = v654_:getDensityMapData(FieldDensityMap.GROUND_TYPE)
		local v658_, v659_, v660_ = v654_:getDensityMapData(FieldDensityMap.SPRAY_LEVEL)
		local v661_ = v654_:getMaxValue(FieldDensityMap.SPRAY_LEVEL)
		v652_ = {
			["fieldFilter"] = DensityMapFilter.new(v655_, v656_, v657_)
		}
		v652_.fieldFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)
		v652_.sprayLevelModifier = DensityMapModifier.new(v658_, v659_, v660_, v653_)
		v652_.sprayLevelFilter = DensityMapFilter.new(v658_, v659_, v660_)
		v652_.sprayLevelFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, 0, v661_ - 1)
		v652_.dynamicFoliageModifier = {}
		v652_.fruitFilter = {}
		v652_.preparingModifier = {}
		v652_.preparingFilter = {}
		v652_.multiModifiers = {}
		FSDensityMapUtil.functionCache.updateDestroyCommonArea = v652_
	end
	local v662_ = v652_.multiModifiers
	if v662_[v649_] == nil then
		v662_[v649_] = {}
	end
	if v662_[v649_][v650_] == nil then
		v662_[v649_][v650_] = {}
	end
	local v663_ = v662_[v649_][v650_][v651_]
	if v663_ == nil then
		local v664_ = g_terrainNode
		local v665_ = v652_.sprayLevelFilter
		local v666_ = v652_.sprayLevelModifier
		local v667_ = nil
		v663_ = DensityMapMultiModifier.new()
		v662_[v649_][v650_][v651_] = v663_
		local v668_
		if v649_ then
			v668_ = v652_.fieldFilter
		else
			v668_ = nil
		end
		for v669_, v670_ in pairs(g_fruitTypeManager:getFruitTypes()) do
			if v670_.terrainDataPlaneId ~= nil then
				local v671_ = v652_.fruitFilter[v669_]
				if v671_ == nil then
					v671_ = DensityMapFilter.new(v670_.terrainDataPlaneId, v670_.startStateChannel, v670_.numStateChannels)
					v671_:setValueCompareParams(DensityValueCompareType.BETWEEN, 2, v670_.numGrowthStates)
					v652_.fruitFilter[v669_] = v671_
				end
				v671_:setValueCompareParams(DensityValueCompareType.BETWEEN, 2, v670_.numGrowthStates)
				v671_:setTypeIndexCompareMode(DensityTypeCompareType.EQUAL)
				v663_:addExecuteAdd(1, v666_, v665_, v671_, v668_)
				if v670_.terrainDataPlaneIdHaulm ~= nil then
					local v672_ = v652_.preparingModifier[v669_]
					if v672_ == nil then
						v672_ = DensityMapModifier.new(v670_.terrainDataPlaneIdHaulm, v670_.startStateChannelHaulm, v670_.numStateChannelsHaulm)
						v652_.preparingModifier[v669_] = v672_
					end
					local v673_ = v652_.preparingFilter[v669_]
					if v673_ == nil then
						v673_ = DensityMapFilter.new(v670_.terrainDataPlaneIdHaulm, v670_.startStateChannelHaulm, v670_.numStateChannelsHaulm)
						v673_:setValueCompareParams(DensityValueCompareType.GREATER, 0)
						v673_:setTypeIndexCompareMode(DensityTypeCompareType.ALWAYS)
						v652_.preparingFilter[v669_] = v673_
					end
					v663_:addExecuteSet(0, v672_, v673_)
				end
				if v650_ or v670_.isCultivationAllowed then
					if v667_ == nil then
						v667_ = DensityMapModifier.new(v670_.terrainDataPlaneId, v670_.startStateChannel, v670_.numStateChannels)
					else
						v667_:resetDensityMapAndChannels(v670_.terrainDataPlaneId, v670_.startStateChannel, v670_.numStateChannels)
					end
					v667_:setNewTypeIndexMode(DensityIndexCompareMode.ZERO)
					v671_:setValueCompareParams(DensityValueCompareType.GREATER, 0)
					v663_:addExecuteSet(0, v667_, v671_, v668_)
				end
			end
		end
		for v674_ = 1, #g_currentMission.dynamicFoliageLayers do
			local v675_ = g_currentMission.dynamicFoliageLayers[v674_]
			local v676_ = getTerrainDetailNumChannels(v675_)
			local v677_ = v652_.dynamicFoliageModifier[v675_]
			if v677_ == nil then
				v677_ = DensityMapModifier.new(v675_, 0, v676_, v664_)
				v652_.dynamicFoliageModifier[v675_] = v677_
			end
			v663_:addExecuteSet(0, v677_, v668_)
		end
		if v651_ then
			FSDensityMapUtil.multiModifierAddResetDisplacement(v663_)
		end
	end
	v663_:updateParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	v663_:execute()
	FSDensityMapUtil.removeWeedArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	DensityMapHeightUtil.clearArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
end

-- Local values: functionData, terrainRootNode, fieldGroundSystem, groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels, modifier, multiModifier, filter1, fieldFilter, _, desc, i, id, numChannels
function FSDensityMapUtil.updateWheelDestructionArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	local v684_ = FSDensityMapUtil.functionCache.updateWheelDestructionArea
	if v684_ == nil then
		local v685_ = g_terrainNode
		local v686_ = g_currentMission.fieldGroundSystem
		local v687_, v688_, v689_ = v686_:getDensityMapData(FieldDensityMap.GROUND_TYPE)
		local v690_, v691_, v692_ = v686_:getDensityMapData(FieldDensityMap.SPRAY_TYPE)
		v684_ = {
			["modifier"] = DensityMapModifier.new(v690_, v691_, v692_, v685_),
			["multiModifier"] = nil,
			["filter1"] = DensityMapFilter.new(v687_, v688_, v689_),
			["fieldFilter"] = DensityMapFilter.new(v687_, v688_, v689_)
		}
		v684_.fieldFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)
		FSDensityMapUtil.functionCache.updateWheelDestructionArea = v684_
	end
	local v693_ = v684_.modifier
	local v694_ = v684_.multiModifier
	local v695_ = v684_.filter1
	local v696_ = v684_.fieldFilter
	g_currentMission.growthSystem:setIgnoreDensityChanges(true)
	if v694_ == nil then
		v694_ = DensityMapMultiModifier.new()
		v684_.multiModifier = v694_
		for _, v697_ in pairs(g_fruitTypeManager:getFruitTypes()) do
			if v697_.terrainDataPlaneId ~= nil and v697_.minWheelDestructionState ~= nil then
				v693_:resetDensityMapAndChannels(v697_.terrainDataPlaneId, v697_.startStateChannel, v697_.numStateChannels)
				v695_:resetDensityMapAndChannels(v697_.terrainDataPlaneId, v697_.startStateChannel, v697_.numStateChannels)
				v695_:setValueCompareParams(DensityValueCompareType.BETWEEN, v697_.minWheelDestructionState, v697_.maxWheelDestructionState)
				v694_:addExecuteSet(v697_.wheelDestructionState, v693_, v695_, v696_)
			end
		end
		for v698_ = 1, #g_currentMission.dynamicFoliageLayers do
			local v699_ = g_currentMission.dynamicFoliageLayers[v698_]
			v693_:resetDensityMapAndChannels(v699_, 0, (getTerrainDetailNumChannels(v699_)))
			v694_:addExecuteSet(0, v693_)
		end
	end
	v694_:updateParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	v694_:execute()
	FSDensityMapUtil.removeWeedArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	g_currentMission.growthSystem:setIgnoreDensityChanges(false)
end

-- Local values: functionData, terrainRootNode, fieldGroundSystem, groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels, groundLayerModifier, sprayTypeFilter, fieldFilter, _, numPixels, totalNumPixels, _, numPixels2, totalNumPixels2
function FSDensityMapUtil.setGroundTypeLayerArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, value)
	local v707_ = FSDensityMapUtil.functionCache.setGroundTypeLayerArea
	if v707_ == nil then
		local v708_ = g_terrainNode
		local v709_ = g_currentMission.fieldGroundSystem
		local v710_, v711_, v712_ = v709_:getDensityMapData(FieldDensityMap.GROUND_TYPE)
		local v713_, v714_, v715_ = v709_:getDensityMapData(FieldDensityMap.SPRAY_TYPE)
		v707_ = {
			["groundLayerModifier"] = DensityMapModifier.new(v713_, v714_, v715_, v708_),
			["sprayTypeFilter"] = DensityMapFilter.new(v713_, v714_, v715_),
			["fieldFilter"] = DensityMapFilter.new(v710_, v711_, v712_)
		}
		v707_.fieldFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)
		FSDensityMapUtil.functionCache.setGroundTypeLayerArea = v707_
	end
	local v716_ = v707_.groundLayerModifier
	local v717_ = v707_.sprayTypeFilter
	local v718_ = v707_.fieldFilter
	v716_:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	v717_:setValueCompareParams(DensityValueCompareType.BETWEEN, 0, value - 1)
	local _, v719_, v720_ = v716_:executeSetWithStats(value, v717_, v718_)
	v717_:setValueCompareParams(DensityValueCompareType.GREATER, value)
	local _, v721_, v722_ = v716_:executeSetWithStats(value, v717_, v718_)
	return v719_ + v721_, v720_ + v722_
end

-- Local values: functionData, terrainRootNode, fieldGroundSystem, stubbleShredLevelMapId, stubbleShredLevelFirstChannel, stubbleShredLevelNumChannels, groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, stubbleShredModifier, fieldFilter, _, numPixels, totalNumPixels
function FSDensityMapUtil.setStubbleShredLevelArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, value)
	if Platform.gameplay.useStubbleShred then
		local v730_ = FSDensityMapUtil.functionCache.setStubbleShredArea
		if v730_ == nil then
			local v731_ = g_terrainNode
			local v732_ = g_currentMission.fieldGroundSystem
			v730_ = {}
			local v733_, v734_, v735_ = v732_:getDensityMapData(FieldDensityMap.STUBBLE_SHRED_LEVEL)
			v730_.stubbleShredModifier = DensityMapModifier.new(v733_, v734_, v735_, v731_)
			local v736_, v737_, v738_ = v732_:getDensityMapData(FieldDensityMap.GROUND_TYPE)
			v730_.fieldFilter = DensityMapFilter.new(v736_, v737_, v738_)
			v730_.fieldFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)
			FSDensityMapUtil.functionCache.setStubbleShredArea = v730_
		end
		local v739_ = v730_.stubbleShredModifier
		local v740_ = v730_.fieldFilter
		v739_:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
		local _, v741_, v742_ = v739_:executeSetWithStats(value, v740_)
		return v741_, v742_
	end
end

-- Local values: numPixels, totalNumPixels, desc
function FSDensityMapUtil.updateSprayArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, sprayTypeIndex, sprayAmount)
	local v751_ = 0
	local v752_ = 0
	local v753_ = g_sprayTypeManager:getSprayTypeByIndex(sprayTypeIndex)
	if v753_ ~= nil then
		if v753_.isLime then
			local v754_, v755_ = FSDensityMapUtil.updateLimeArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, v753_.sprayGroundType)
			return v754_, v755_
		end
		if v753_.isFertilizer then
			local v756_, v757_ = FSDensityMapUtil.updateFertilizerArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, v753_.sprayGroundType, sprayAmount)
			return v756_, v757_
		end
		if v753_.isHerbicide then
			v751_, v752_ = FSDensityMapUtil.updateHerbicideArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, v753_.sprayGroundType)
		end
	end
	return v751_, v752_
end

-- Local values: functionData, terrainRootNode, fieldGroundSystem, sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels, modifier, filter, sprayType
function FSDensityMapUtil.removeSprayArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, blockedSprayTypeIndex, customFilter)
	local v766_ = FSDensityMapUtil.functionCache.removeSprayArea
	if v766_ == nil then
		local v767_ = g_terrainNode
		local v768_, v769_, v770_ = g_currentMission.fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_TYPE)
		v766_ = {
			["modifier"] = DensityMapModifier.new(v768_, v769_, v770_, v767_),
			["filter"] = DensityMapFilter.new(v768_, v769_, v770_)
		}
		FSDensityMapUtil.functionCache.removeSprayArea = v766_
	end
	local v771_ = v766_.modifier
	local v772_ = v766_.filter
	v771_:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	if blockedSprayTypeIndex == nil then
		v772_:setValueCompareParams(DensityValueCompareType.GREATER, 0)
		v771_:executeSet(0, v772_, customFilter)
	else
		local v773_ = g_sprayTypeManager:getSprayTypeByIndex(blockedSprayTypeIndex)
		if v773_.sprayGroundType > 0 then
			v772_:setValueCompareParams(DensityValueCompareType.GREATER, v773_.sprayGroundType)
			v771_:executeSet(0, v772_, customFilter)
			if v773_.sprayGroundType > 0 then
				v772_:setValueCompareParams(DensityValueCompareType.BETWEEN, 0, v773_.sprayGroundType - 1)
				v771_:executeSet(0, v772_, customFilter)
				return
			end
		end
	end
end

-- Local values: functionData, terrainRootNode, fieldGroundSystem, sprayLevelMapId, sprayLevelFirstChannel, sprayLevelNumChannels, groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, sprayLevelMaxValue, sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels, sprayTypeMaxValue, _, desc, growingFruitFilter, sprayModifier, sprayLevelModifier, sprayTypeFilter, outsideFieldFilter, growingFruitFilters, maskFilter, maskValue, i, growingFruitFilter, _, numPixels, totalNumPixels, i
function FSDensityMapUtil.updateFertilizerArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, sprayType, sprayAmount)
	local v782_ = FSDensityMapUtil.functionCache.updateFertilizerArea
	if v782_ == nil then
		local v783_ = g_terrainNode
		local v784_ = g_currentMission.fieldGroundSystem
		local v785_, v786_, v787_ = v784_:getDensityMapData(FieldDensityMap.SPRAY_LEVEL)
		local v788_, v789_, v790_ = v784_:getDensityMapData(FieldDensityMap.GROUND_TYPE)
		local v791_ = v784_:getMaxValue(FieldDensityMap.SPRAY_LEVEL)
		local v792_, v793_, v794_ = v784_:getDensityMapData(FieldDensityMap.SPRAY_TYPE)
		local v795_ = v784_:getMaxValue(FieldDensityMap.SPRAY_TYPE)
		v782_ = {
			["sprayModifier"] = DensityMapModifier.new(v792_, v793_, v794_, v783_),
			["sprayLevelModifier"] = DensityMapModifier.new(v785_, v786_, v787_, v783_),
			["growingFruitFilters"] = {}
		}
		for _, v796_ in pairs(g_fruitTypeManager:getFruitTypes()) do
			if v796_.terrainDataPlaneId ~= nil then
				local v797_ = DensityMapFilter.new(v796_.terrainDataPlaneId, v796_.startStateChannel, v796_.numStateChannels)
				v797_:setValueCompareParams(DensityValueCompareType.BETWEEN, v796_.minHarvestingGrowthState, v796_.maxHarvestingGrowthState)
				local v798_ = v782_.growingFruitFilters
				table.insert(v798_, v797_)
			end
		end
		v782_.sprayTypeFilter = DensityMapFilter.new(v792_, v793_, v794_)
		v782_.sprayTypeFilter:setValueCompareParams(DensityValueCompareType.EQUAL, 0)
		v782_.outsideFieldFilter = DensityMapFilter.new(v788_, v789_, v790_)
		v782_.outsideFieldFilter:setValueCompareParams(DensityValueCompareType.EQUAL, 0)
		v782_.maskFilter = DensityMapFilter.new(v785_, v786_, v787_)
		v782_.maskFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, 0, v791_ - 1)
		v782_.maskValue = v795_
		FSDensityMapUtil.functionCache.updateFertilizerArea = v782_
	end
	local v799_ = v782_.sprayModifier
	local v800_ = v782_.sprayLevelModifier
	local v801_ = v782_.sprayTypeFilter
	local v802_ = v782_.outsideFieldFilter
	local v803_ = v782_.growingFruitFilters
	local v804_ = v782_.maskFilter
	local v805_ = v782_.maskValue
	v799_:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	v800_:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	v801_:setValueCompareParams(DensityValueCompareType.NOTEQUAL, sprayType)
	v799_:executeSet(v805_, v801_, v804_)
	v801_:setValueCompareParams(DensityValueCompareType.EQUAL, v805_)
	v799_:executeSet(0, v801_, v802_)
	for v806_ = 1, #v803_ do
		v799_:executeSet(0, v801_, v803_[v806_])
	end
	local v807_ = nil
	local v808_ = nil
	for _ = 1, math.max(sprayAmount or 1, 1) do
		local v809_, v810_
		v809_, v810_, v807_, v808_ = v800_:executeAddWithStats(1, v801_, v804_)
	end
	v799_:executeSet(sprayType, v801_)
	return v807_, v808_
end

-- Local values: functionData, terrainRootNode, fieldGroundSystem, groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels, limeLevelMapId, limeLevelFirstChannel, limeLevelNumChannels, limeLevelMaxValue, firstSowableValue, lastSowableValue, modifierSprayType, modifierLimeLevel, filterLimeLevel, filterLimeLevelMax, fieldFilter, groundFilter, chopperTypeFilter, startChopperValue, endChopperValue, multiModifier, fruitFilter, noFruitFilter, index, desc, multiModifier, modifierLimeLevel, filterLimeLevelMax, _, areaBefore, totalNumPixels, _, areaAfter, _
function FSDensityMapUtil.updateLimeArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, groundType)
	local v818_ = FSDensityMapUtil.functionCache.updateLimeArea
	if v818_ == nil then
		local v819_ = g_terrainNode
		local v820_ = g_currentMission.fieldGroundSystem
		local v821_, v822_, v823_ = v820_:getDensityMapData(FieldDensityMap.GROUND_TYPE)
		local v824_, v825_, v826_ = v820_:getDensityMapData(FieldDensityMap.SPRAY_TYPE)
		local v827_, v828_, v829_ = v820_:getDensityMapData(FieldDensityMap.LIME_LEVEL)
		local v830_ = v820_:getMaxValue(FieldDensityMap.LIME_LEVEL)
		local v831_, v832_ = v820_:getSowableRange()
		local v833_ = DensityMapModifier.new(v824_, v825_, v826_, v819_)
		local v834_ = DensityMapModifier.new(v827_, v828_, v829_, v819_)
		local v835_ = DensityMapFilter.new(v827_, v828_, v829_)
		v835_:setValueCompareParams(DensityValueCompareType.BETWEEN, 0, v830_ - 1)
		local v836_ = DensityMapFilter.new(v827_, v828_, v829_)
		v836_:setValueCompareParams(DensityValueCompareType.EQUAL, v830_)
		local v837_ = DensityMapFilter.new(v821_, v822_, v823_)
		v837_:setValueCompareParams(DensityValueCompareType.GREATER, 0)
		local v838_ = DensityMapFilter.new(v821_, v822_, v823_)
		v838_:setValueCompareParams(DensityValueCompareType.BETWEEN, v831_, v832_)
		local v839_ = DensityMapFilter.new(v824_, v825_, v826_)
		local v840_ = FieldChopperType.getValueByType(FieldChopperType.CHOPPER_STRAW)
		local v841_ = FieldChopperType.getValueByType(FieldChopperType.CHOPPER_MAIZE)
		v839_:setValueCompareParams(DensityValueCompareType.BETWEEN, v840_, v841_)
		v818_ = {
			["multiModifier"] = DensityMapMultiModifier.new(),
			["modifierLimeLevel"] = v834_,
			["filterLimeLevelMax"] = v836_
		}
		local v842_ = v818_.multiModifier
		local v843_ = nil
		local v844_ = nil
		for _, v845_ in pairs(g_fruitTypeManager:getFruitTypes()) do
			if v845_.terrainDataPlaneId ~= nil then
				if v843_ == nil then
					v843_ = DensityMapFilter.new(v845_.terrainDataPlaneId, v845_.startStateChannel, v845_.numStateChannels)
					v844_ = DensityMapFilter.new(v845_.terrainDataPlaneId, v845_.startStateChannel, v845_.numStateChannels)
					v844_:setTypeIndexCompareMode(DensityTypeCompareType.ALWAYS)
				else
					v843_:resetDensityMapAndChannels(v845_.terrainDataPlaneId, v845_.startStateChannel, v845_.numStateChannels)
					v844_:resetDensityMapAndChannels(v845_.terrainDataPlaneId, v845_.startStateChannel, v845_.numStateChannels)
				end
				v843_:setValueCompareParams(DensityValueCompareType.EQUAL, 1)
				v842_:addExecuteSet(groundType, v833_, v837_, v843_)
				v842_:addExecuteSet(v830_, v834_, v837_, v843_, v835_)
				v843_:setValueCompareParams(DensityValueCompareType.GREATER, v845_.maxHarvestingGrowthState)
				v842_:addExecuteSet(groundType, v833_, v837_, v843_)
				v842_:addExecuteSet(v830_, v834_, v837_, v843_, v835_)
				v844_:setValueCompareParams(DensityValueCompareType.EQUAL, 0)
				v842_:addExecuteSet(groundType, v833_, v837_, v844_)
				v842_:addExecuteSet(v830_, v834_, v837_, v844_, v835_)
			end
		end
		v842_:addExecuteSet(groundType, v833_, v838_)
		v842_:addExecuteSet(v830_, v834_, v838_, v835_)
		v842_:addExecuteSet(groundType, v833_, v839_)
		v842_:addExecuteSet(v830_, v834_, v839_, v835_)
		FSDensityMapUtil.functionCache.updateLimeArea = v818_
	end
	local v846_ = v818_.multiModifier
	local v847_ = v818_.modifierLimeLevel
	local v848_ = v818_.filterLimeLevelMax
	v847_:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	local _, v849_, v850_ = v847_:executeGet(v848_)
	v846_:updateParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	v846_:execute()
	local _, v851_, _ = v847_:executeGet(v848_)
	return v851_ - v849_, v850_
end

-- Local values: weedSystem, functionData, labelTotal, labelSprayed, label, multiModifier, terrainRootNode, fieldGroundSystem, groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels, weedMapId, weedFirstChannel, weedNumChannels, firstSowableValue, lastSowableValue, replacementData, replacements, _, data, desc, fruitModifier, sourceStateFilter, sourceState, targetState, sprayModifier, weedModifier, groundFilter, sourceState, targetState, weedFilter, _, desc, fruitFilter, cutFruitFilter, wheelDestructionFruitFilter, numChangedPixels, totalNumPixels, area, totalPixels
function FSDensityMapUtil.updateHerbicideArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, groundType)
	local v859_ = g_currentMission.weedSystem
	if not v859_:getMapHasWeed() then
		return 0, 0
	end
	local v860_ = FSDensityMapUtil.functionCache.updateHerbicideArea
	if v860_ == nil then
		v860_ = {
			["numChangedPixels"] = {},
			["totalNumPixels"] = {},
			["multiModifiers"] = {}
		}
		FSDensityMapUtil.functionCache.updateHerbicideArea = v860_
	end
	local v861_ = "sprayedTotal"
	local v862_ = groundType and v860_.multiModifiers[groundType] or v860_.defaultMultiModifier
	if v862_ == nil then
		v862_ = DensityMapMultiModifier.new()
		local v863_ = g_terrainNode
		local v864_ = g_currentMission.fieldGroundSystem
		local v865_, v866_, v867_ = v864_:getDensityMapData(FieldDensityMap.GROUND_TYPE)
		local v868_, v869_, v870_ = v864_:getDensityMapData(FieldDensityMap.SPRAY_TYPE)
		local v871_, v872_, v873_ = v859_:getDensityMapData()
		local v874_, v875_ = v864_:getSowableRange()
		local v876_ = v859_:getHerbicideReplacements()
		local v877_ = v876_.weed.replacements
		if v876_.custom ~= nil then
			for _, v878_ in ipairs(v876_.custom) do
				local v879_ = v878_.fruitType
				if v879_.terrainDataPlaneId ~= nil then
					local v880_ = DensityMapModifier.new(v879_.terrainDataPlaneId, v879_.startStateChannel, v879_.numStateChannels, v863_)
					local v881_ = DensityMapFilter.new(v879_.terrainDataPlaneId, v879_.startStateChannel, v879_.numStateChannels)
					for v882_, v883_ in pairs(v877_) do
						v881_:setValueCompareParams(DensityValueCompareType.EQUAL, v882_)
						v862_:addExecuteSetWithStats(v861_, v883_, v880_, v881_)
						v861_ = "sprayed"
					end
				end
			end
		end
		local v884_ = DensityMapModifier.new(v868_, v869_, v870_, v863_)
		local v885_ = DensityMapModifier.new(v871_, v872_, v873_, v863_)
		local v886_ = DensityMapFilter.new(v865_, v866_, v867_)
		v886_:setValueCompareParams(DensityValueCompareType.BETWEEN, v874_, v875_)
		for v887_, v888_ in pairs(v877_) do
			local v889_ = DensityMapFilter.new(v871_, v872_, v873_)
			v889_:setValueCompareParams(DensityValueCompareType.EQUAL, v887_)
			for _, v890_ in pairs(g_fruitTypeManager:getFruitTypes()) do
				if v890_.terrainDataPlaneId ~= nil then
					local v891_ = DensityMapFilter.new(v890_.terrainDataPlaneId, v890_.startStateChannel, v890_.numStateChannels)
					v891_:setValueCompareParams(DensityValueCompareType.BETWEEN, 1, v890_.minHarvestingGrowthState - 1)
					v862_:addExecuteSet(groundType, v884_, v891_, v889_)
					v862_:addExecuteSetWithStats(v861_, v888_, v885_, v891_, v889_)
					local v892_ = DensityMapFilter.new(v890_.terrainDataPlaneId, v890_.startStateChannel, v890_.numStateChannels)
					v892_:setValueCompareParams(DensityValueCompareType.EQUAL, v890_.cutState + 1)
					v862_:addExecuteSet(groundType, v884_, v892_, v889_)
					v862_:addExecuteSetWithStats(v861_, v888_, v885_, v892_, v889_)
					if v890_.wheelDestructionState ~= nil and v890_.wheelDestructionState ~= v890_.cutState + 1 then
						local v893_ = DensityMapFilter.new(v890_.terrainDataPlaneId, v890_.startStateChannel, v890_.numStateChannels)
						v893_:setValueCompareParams(DensityValueCompareType.EQUAL, v890_.wheelDestructionState)
						v862_:addExecuteSet(groundType, v884_, v893_, v889_)
						v862_:addExecuteSetWithStats(v861_, v888_, v885_, v893_, v889_)
					end
				end
			end
			v862_:addExecuteSet(groundType, v884_, v886_, v889_)
			v862_:addExecuteSetWithStats(v861_, v888_, v885_, v886_, v889_)
		end
		if groundType then
			v860_.multiModifiers[groundType] = v862_
		else
			v860_.defaultMultiModifier = v862_
		end
	end
	local v894_ = v860_.numChangedPixels
	local v895_ = v860_.totalNumPixels
	v862_:updateParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	v862_:resetStats()
	v862_:execute(nil, v894_, v895_)
	return v894_.sprayedTotal + v894_.sprayed, v895_.sprayedTotal or 0
end

-- Local values: weedSystem, _, areaBefore, areaAfter, functionData, weederData, terrainRootNode, fieldGroundSystem, weedMapId, weedFirstChannel, weedNumChannels, replacementData, groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, firstSowableState, lastSowableState, fruitStateFilter, sourceStateFilter, sowableFilter, sourceState, targetState, _, desc, maxWeederState, fruitModifier, _, data, desc, sourceState, targetState, weedModifier, allWeedFilter, multiModifierGrowing, multiModifierSowable, multiModifierCustom
function FSDensityMapUtil.updateWeederArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, isHoeWeeder)
	local v903_ = g_currentMission.weedSystem
	local v904_, v905_
	if v903_:getMapHasWeed() then
		local v906_ = FSDensityMapUtil.functionCache.updateWeederArea
		if v906_ == nil then
			v906_ = {}
			FSDensityMapUtil.functionCache.updateWeederArea = v906_
		end
		local v907_ = v906_[isHoeWeeder]
		if v907_ == nil then
			local v908_ = g_terrainNode
			local v909_ = g_currentMission.fieldGroundSystem
			local v910_, v911_, v912_ = v903_:getDensityMapData()
			local v913_ = v903_:getWeederReplacements(isHoeWeeder)
			local v914_, v915_, v916_ = v909_:getDensityMapData(FieldDensityMap.GROUND_TYPE)
			local v917_, v918_ = v909_:getSowableRange()
			v907_ = {
				["weedModifier"] = DensityMapModifier.new(v910_, v911_, v912_, v908_),
				["allWeedFilter"] = DensityMapFilter.new(v910_, v911_, v912_)
			}
			v907_.allWeedFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)
			v907_.multiModifierGrowing = DensityMapMultiModifier.new()
			v907_.multiModifierSowable = DensityMapMultiModifier.new()
			local v919_ = DensityMapFilter.new(v910_, v911_, v912_)
			local v920_ = DensityMapFilter.new(v914_, v915_, v916_)
			v920_:setValueCompareParams(DensityValueCompareType.BETWEEN, v917_, v918_)
			local v921_ = nil
			for v922_, v923_ in pairs(v913_.weed.replacements) do
				v919_:setValueCompareParams(DensityValueCompareType.EQUAL, v922_)
				for _, v924_ in pairs(g_fruitTypeManager:getFruitTypes()) do
					if v924_.terrainDataPlaneId ~= nil then
						if v921_ == nil then
							v921_ = DensityMapFilter.new(v924_.terrainDataPlaneId, v924_.startStateChannel, v924_.numStateChannels)
						else
							v921_:resetDensityMapAndChannels(v924_.terrainDataPlaneId, v924_.startStateChannel, v924_.numStateChannels)
						end
						local v925_ = v924_.maxWeederState
						if isHoeWeeder then
							v925_ = v924_.maxWeederHoeState
						end
						v921_:setValueCompareParams(DensityValueCompareType.BETWEEN, 0, v925_)
						v907_.multiModifierGrowing:addExecuteSet(v923_, v907_.weedModifier, v919_, v921_)
						v921_:setValueCompareParams(DensityValueCompareType.EQUAL, v924_.cutState)
						v907_.multiModifierGrowing:addExecuteSet(v923_, v907_.weedModifier, v919_, v921_)
					end
				end
				v907_.multiModifierSowable:addExecuteSet(v923_, v907_.weedModifier, v919_, v920_)
			end
			if v913_.custom ~= nil then
				v907_.multiModifierCustom = DensityMapMultiModifier.new()
				local v926_ = nil
				for _, v927_ in ipairs(v913_.custom) do
					local v928_ = v927_.fruitType
					if v928_.terrainDataPlaneId ~= nil then
						if v926_ == nil then
							v926_ = DensityMapModifier.new(v928_.terrainDataPlaneId, v928_.startStateChannel, v928_.numStateChannels, v908_)
						else
							v926_:resetDensityMapAndChannels(v928_.terrainDataPlaneId, v928_.startStateChannel, v928_.numStateChannels)
						end
						v919_:resetDensityMapAndChannels(v928_.terrainDataPlaneId, v928_.startStateChannel, v928_.numStateChannels)
						for v929_, v930_ in pairs(v927_.replacements) do
							v919_:setValueCompareParams(DensityValueCompareType.EQUAL, v929_)
							v907_.multiModifierCustom:addExecuteSet(v930_, v926_, v919_)
						end
					end
				end
			end
			FSDensityMapUtil.functionCache.updateWeederArea[isHoeWeeder] = v907_
		end
		local v931_ = v907_.weedModifier
		local v932_ = v907_.allWeedFilter
		local v933_ = v907_.multiModifierGrowing
		local v934_ = v907_.multiModifierSowable
		local v935_ = v907_.multiModifierCustom
		v931_:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
		local v936_, v937_
		v936_, v904_, v937_ = v931_:executeGet(v932_)
		v933_:updateParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
		v933_:execute()
		v934_:updateParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
		v934_:execute()
		if v935_ ~= nil then
			v935_:updateParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
			v935_:execute()
		end
		local v938_, v939_
		v938_, v905_, v939_ = v931_:executeGet(v932_)
	else
		v904_ = 0
		v905_ = 0
	end
	DensityMapHeightUtil.removeFromGroundByArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, FillType.GRASS_WINDROW)
	DensityMapHeightUtil.removeFromGroundByArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, FillType.DRYGRASS_WINDROW)
	return v904_ - v905_
end

-- Local values: numPixels, totalNumPixels, weedSystem, functionData, terrainRootNode, weedMapId, weedFirstChannel, weedNumChannels, weedModifier, _
function FSDensityMapUtil.removeWeedArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	local v946_ = g_currentMission.weedSystem
	local v947_, v948_
	if v946_:getMapHasWeed() then
		local v949_ = FSDensityMapUtil.functionCache.removeWeedArea
		if v949_ == nil then
			local v950_ = g_terrainNode
			local v951_, v952_, v953_ = v946_:getDensityMapData()
			v949_ = {
				["weedModifier"] = DensityMapModifier.new(v951_, v952_, v953_, v950_)
			}
			FSDensityMapUtil.functionCache.removeWeedArea = v949_
		end
		local v954_ = v949_.weedModifier
		v954_:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
		local v955_
		v955_, v947_, v948_ = v954_:executeSetWithStats(0)
	else
		v947_ = 0
		v948_ = 0
	end
	return v947_, v948_
end

-- Local values: weedSystem, functionData, terrainRootNode, fieldGroundSystem, weedMapId, weedFirstChannel, weedNumChannels, infoId, _, _, blockingStateValue, blockingStateFirstChannel, blockingStateNumChannels, sparseState, groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, weedModifier, fieldFilter, notWeedBlockedFilter, sparseState
function FSDensityMapUtil.setSparseWeedArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	local v962_ = g_currentMission.weedSystem
	if v962_:getMapHasWeed() then
		local v963_ = FSDensityMapUtil.functionCache.setSparseWeedArea
		if v963_ == nil then
			local v964_ = g_terrainNode
			local v965_ = g_currentMission.fieldGroundSystem
			local v966_, v967_, v968_ = v962_:getDensityMapData()
			local v969_, _, _ = v962_:getInfoLayerData()
			local v970_, v971_, v972_ = v962_:getBlockingStateData()
			local v973_ = v962_:getSparseStartState()
			local v974_, v975_, v976_ = v965_:getDensityMapData(FieldDensityMap.GROUND_TYPE)
			v963_ = {
				["weedModifier"] = DensityMapModifier.new(v966_, v967_, v968_, v964_),
				["fieldFilter"] = DensityMapFilter.new(v974_, v975_, v976_)
			}
			v963_.fieldFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)
			v963_.notWeedBlockedFilter = DensityMapFilter.new(v969_, v971_, v972_)
			v963_.notWeedBlockedFilter:setValueCompareParams(DensityValueCompareType.NOTEQUAL, v970_)
			v963_.sparseState = v973_
			FSDensityMapUtil.functionCache.setSparseWeedArea = v963_
		end
		local v977_ = v963_.weedModifier
		local v978_ = v963_.fieldFilter
		local v979_ = v963_.notWeedBlockedFilter
		local v980_ = v963_.sparseState
		v977_:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
		v977_:executeSet(v980_, v978_, v979_)
	end
end

-- Local values: weedSystem, functionData, terrainRootNode, fieldGroundSystem, weedMapId, weedFirstChannel, weedNumChannels, infoId, _, _, blockingStateValue, blockingStateFirstChannel, blockingStateNumChannels, sparseState, denseState, groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, firstSowableValue, lastSowableValue, stubbleTillageValue, weedModifier, stubbleTillageFilter, notBlockedFilter, sowableFilter, denseState, sparseState
function FSDensityMapUtil.setSowingWeedArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	local v987_ = g_currentMission.weedSystem
	if v987_:getMapHasWeed() then
		local v988_ = FSDensityMapUtil.functionCache.setSowingWeedArea
		if v988_ == nil then
			local v989_ = g_terrainNode
			local v990_ = g_currentMission.fieldGroundSystem
			local v991_, v992_, v993_ = v987_:getDensityMapData()
			local v994_, _, _ = v987_:getInfoLayerData()
			local v995_, v996_, v997_ = v987_:getBlockingStateData()
			local v998_ = v987_:getSparseStartState()
			local v999_ = v987_:getDenseStartState()
			local v1000_, v1001_, v1002_ = v990_:getDensityMapData(FieldDensityMap.GROUND_TYPE)
			local v1003_, v1004_ = v990_:getSowableRange()
			local v1005_ = FieldGroundType.getValueByType(FieldGroundType.STUBBLE_TILLAGE)
			v988_ = {
				["weedModifier"] = DensityMapModifier.new(v991_, v992_, v993_, v989_),
				["notBlockedFilter"] = DensityMapFilter.new(v994_, v996_, v997_)
			}
			v988_.notBlockedFilter:setValueCompareParams(DensityValueCompareType.NOTEQUAL, v995_)
			v988_.stubbleTillageFilter = DensityMapFilter.new(v1000_, v1001_, v1002_)
			v988_.stubbleTillageFilter:setValueCompareParams(DensityValueCompareType.EQUAL, v1005_)
			v988_.sowableFilter = DensityMapFilter.new(v1000_, v1001_, v1002_)
			v988_.sowableFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, v1003_, v1004_)
			v988_.sparseState = v998_
			v988_.denseState = v999_
			FSDensityMapUtil.functionCache.setSowingWeedArea = v988_
		end
		local v1006_ = v988_.weedModifier
		local v1007_ = v988_.stubbleTillageFilter
		local v1008_ = v988_.notBlockedFilter
		local v1009_ = v988_.sowableFilter
		local v1010_ = v988_.denseState
		local v1011_ = v988_.sparseState
		v1006_:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
		v1006_:executeSet(v1011_, v1009_, v1008_)
		v1006_:executeSet(v1010_, v1007_, v1008_)
	end
end

-- Local values: weedSystem, functionData, terrainRootNode, infoId, _, _, blockingValue, blockingStateFirstChannel, blockingStateNumChannels, weedInfoModifier, blockingValue
function FSDensityMapUtil.setWeedBlockingState(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, customFilter1, customFilter2)
	local v1020_ = g_currentMission.weedSystem
	if v1020_:getMapHasWeed() then
		local v1021_ = FSDensityMapUtil.functionCache.setWeedBlockingState
		if v1021_ == nil then
			local v1022_ = g_terrainNode
			local v1023_, _, _ = v1020_:getInfoLayerData()
			local v1024_, v1025_, v1026_ = v1020_:getBlockingStateData()
			v1021_ = {
				["weedInfoModifier"] = DensityMapModifier.new(v1023_, v1025_, v1026_, v1022_),
				["blockingValue"] = v1024_
			}
			FSDensityMapUtil.functionCache.setWeedBlockingState = v1021_
		end
		local v1027_ = v1021_.weedInfoModifier
		local v1028_ = v1021_.blockingValue
		v1027_:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
		v1027_:executeSet(v1028_, customFilter1, customFilter2)
	end
end

-- Local values: weedSystem, functionData, terrainRootNode, infoId, _, _, _, blockingStateFirstChannel, blockingStateNumChannels, weedInfoModifier
function FSDensityMapUtil.removeWeedBlockingState(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	local v1035_ = g_currentMission.weedSystem
	if v1035_:getMapHasWeed() then
		local v1036_ = FSDensityMapUtil.functionCache.removeWeedBlockingState
		if v1036_ == nil then
			local v1037_ = g_terrainNode
			local v1038_, _, _ = v1035_:getInfoLayerData()
			local _, v1039_, v1040_ = v1035_:getBlockingStateData()
			v1036_ = {
				["weedInfoModifier"] = DensityMapModifier.new(v1038_, v1039_, v1040_, v1037_)
			}
			FSDensityMapUtil.functionCache.removeWeedBlockingState = v1036_
		end
		local v1041_ = v1036_.weedInfoModifier
		v1041_:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
		v1041_:executeSet(0)
	end
end

-- Local values: functionData, terrainRootNode, mission, fieldGroundSystem, sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels, multiModifier, stubbleShredModifier, stubbleShredLevelMapId, stubbleShredLevelFirstChannel, stubbleShredLevelNumChannels, sprayTypeModifier, groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, fruitFilter, mulchedStateFilter, fruitModifier, _, desc, chopperTypeValue, preparingModifier, preparingFilter, weedSystem, weedMapId, weedFirstChannel, weedNumChannels, sourceStateFilter, weedModifier, replacementData, sourceState, targetState, _, data, desc, sourceState, targetState, desc, foliageFilter, fruitValueModifier, foliageSystem, decoFoliages, _, decoFoliage, multiModifier, changeArea, changeTotalArea
function FSDensityMapUtil.updateMulcherArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	local v1048_ = FSDensityMapUtil.functionCache.updateMulcherArea
	if v1048_ == nil then
		local v1049_ = g_terrainNode
		local v1050_ = g_currentMission
		local v1051_ = v1050_.fieldGroundSystem
		local v1052_, v1053_, v1054_ = v1051_:getDensityMapData(FieldDensityMap.SPRAY_TYPE)
		v1048_ = {
			["multiModifier"] = DensityMapMultiModifier.new()
		}
		local v1055_ = v1048_.multiModifier
		local v1056_
		if Platform.gameplay.useStubbleShred then
			local v1057_, v1058_, v1059_ = v1051_:getDensityMapData(FieldDensityMap.STUBBLE_SHRED_LEVEL)
			v1056_ = DensityMapModifier.new(v1057_, v1058_, v1059_, v1049_)
		else
			v1056_ = nil
		end
		local v1060_
		if v1052_ == nil then
			v1060_ = nil
		else
			v1060_ = DensityMapModifier.new(v1052_, v1053_, v1054_, v1049_)
		end
		local v1061_, v1062_, v1063_ = v1051_:getDensityMapData(FieldDensityMap.GROUND_TYPE)
		local v1064_ = DensityMapFilter.new(v1061_, v1062_, v1063_)
		local v1065_ = DensityMapFilter.new(v1061_, v1062_, v1063_)
		local v1066_ = nil
		for _, v1067_ in pairs(g_fruitTypeManager:getFruitTypes()) do
			if v1067_.isCultivationAllowed and v1067_.terrainDataPlaneId ~= nil then
				v1064_:resetDensityMapAndChannels(v1067_.terrainDataPlaneId, v1067_.startStateChannel, v1067_.numStateChannels)
				v1064_:setValueCompareParams(DensityValueCompareType.BETWEEN, 2, v1067_.cutState)
				v1065_:resetDensityMapAndChannels(v1067_.terrainDataPlaneId, v1067_.startStateChannel, v1067_.numStateChannels)
				v1065_:setValueCompareParams(DensityValueCompareType.NOTEQUAL, v1067_.mulchedState or 0)
				if v1067_.mulcherChopperType ~= nil and v1060_ ~= nil then
					local v1068_ = FieldChopperType.getValueByType(v1067_.mulcherChopperType)
					if v1068_ ~= nil then
						v1055_:addExecuteSetWithStats("", v1068_, v1060_, v1064_, v1065_)
					end
				end
				if v1056_ ~= nil then
					v1055_:addExecuteAddWithStats("", 1, v1056_, v1064_, v1065_)
				end
				if v1067_.terrainDataPlaneIdHaulm ~= nil then
					local v1069_ = DensityMapModifier.new(v1067_.terrainDataPlaneIdHaulm, v1067_.startStateChannelHaulm, v1067_.numStateChannelsHaulm)
					local v1070_ = DensityMapFilter.new(v1067_.terrainDataPlaneIdHaulm, v1067_.startStateChannelHaulm, v1067_.numStateChannelsHaulm)
					v1070_:setValueCompareParams(DensityValueCompareType.GREATER, 0)
					v1070_:setTypeIndexCompareMode(DensityTypeCompareType.ALWAYS)
					v1055_:addExecuteSet(0, v1069_, v1070_)
				end
				if v1066_ == nil then
					v1066_ = DensityMapModifier.new(v1067_.terrainDataPlaneId, v1067_.startStateChannel, v1067_.numStateChannels)
				else
					v1066_:resetDensityMapAndChannels(v1067_.terrainDataPlaneId, v1067_.startStateChannel, v1067_.numStateChannels)
				end
				if (v1067_.mulchedState or 0) == 0 then
					v1066_:setNewTypeIndexMode(DensityIndexCompareMode.ZERO)
				end
				v1064_:setValueCompareParams(DensityValueCompareType.GREATER, 0)
				v1055_:addExecuteSetWithStats("", v1067_.mulchedState or 0, v1066_, v1064_, v1065_)
			end
		end
		local v1071_ = v1050_.weedSystem
		if v1071_ ~= nil then
			local v1072_, v1073_, v1074_ = v1071_:getDensityMapData()
			local v1075_ = DensityMapFilter.new(v1072_, v1073_, v1074_)
			local v1076_ = DensityMapModifier.new(v1072_, v1073_, v1074_, v1049_)
			local v1077_ = v1071_:getMulcherReplacements()
			if v1077_.weed ~= nil then
				for v1078_, v1079_ in pairs(v1077_.weed.replacements) do
					v1075_:setValueCompareParams(DensityValueCompareType.EQUAL, v1078_)
					v1055_:addExecuteSetWithStats("", v1079_, v1076_, v1075_)
				end
			end
			if v1077_.custom ~= nil then
				local v1080_ = nil
				for _, v1081_ in ipairs(v1077_.custom) do
					local v1082_ = v1081_.fruitType
					if v1082_.terrainDataPlaneId ~= nil then
						if v1080_ == nil then
							v1080_ = DensityMapModifier.new(v1082_.terrainDataPlaneId, v1082_.startStateChannel, v1082_.numStateChannels, v1049_)
						else
							v1080_:resetDensityMapAndChannels(v1082_.terrainDataPlaneId, v1082_.startStateChannel, v1082_.numStateChannels)
						end
						if v1075_ == nil then
							v1075_ = DensityMapFilter.new(v1082_.terrainDataPlaneId, v1082_.startStateChannel, v1082_.numStateChannels)
						else
							v1075_:resetDensityMapAndChannels(v1082_.terrainDataPlaneId, v1082_.startStateChannel, v1082_.numStateChannels)
						end
						for v1083_, v1084_ in pairs(v1081_.replacements) do
							v1075_:setValueCompareParams(DensityValueCompareType.EQUAL, v1083_)
							v1055_:addExecuteSetWithStats("", v1084_, v1080_, v1075_)
						end
					end
				end
			end
			local v1085_ = g_fruitTypeManager:getFruitTypeByIndex(FruitType.MEADOW)
			if v1085_ ~= nil and v1085_.terrainDataPlaneId ~= nil then
				local v1086_ = nil
				local v1087_ = DensityMapModifier.new(v1085_.terrainDataPlaneId, v1085_.startStateChannel, v1085_.numStateChannels, v1049_)
				v1087_:setNewTypeIndexMode(DensityIndexCompareMode.UPDATE)
				local v1088_ = v1050_.foliageSystem
				if v1088_ ~= nil then
					local v1089_ = v1088_:getDecoFoliages()
					for _, v1090_ in pairs(v1089_) do
						if v1090_.mowable and v1090_.terrainDataPlaneId ~= nil then
							if v1086_ == nil then
								v1086_ = DensityMapFilter.new(v1090_.terrainDataPlaneId, v1090_.startStateChannel, v1090_.numStateChannels)
							else
								v1086_:resetDensityMapAndChannels(v1090_.terrainDataPlaneId, v1090_.startStateChannel, v1090_.numStateChannels)
							end
							v1086_:setValueCompareParams(DensityValueCompareType.GREATER, 0)
							if v1085_.regrows and v1085_.mulchedState ~= nil then
								v1055_:addExecuteSetWithStats("", v1085_.mulchedState, v1087_, v1086_)
							end
						end
					end
				end
			end
		end
		FSDensityMapUtil.functionCache.updateMulcherArea = v1048_
	end
	DensityMapHeightUtil.clearArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	local v1091_ = v1048_.multiModifier
	v1091_:updateParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	v1091_:resetStats()
	local v1092_, v1093_ = v1091_:execute()
	return v1092_, v1093_
end

-- Local values: desc, functionData, terrainRootNode, multiModifier, foliageFilter, fruitValueModifier, decoFoliages, _, decoFoliage, multiModifier
function FSDensityMapUtil.updateMowerArea(fruitType, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, limitToField)
	local v1102_ = g_fruitTypeManager:getFruitTypeByIndex(FruitType.MEADOW)
	if v1102_ ~= nil and v1102_.terrainDataPlaneId ~= nil then
		local v1103_ = FSDensityMapUtil.functionCache.updateMowerArea
		if v1103_ == nil then
			local v1104_ = g_terrainNode
			v1103_ = {}
			local v1105_ = DensityMapMultiModifier.new()
			local v1106_ = nil
			local v1107_ = DensityMapModifier.new(v1102_.terrainDataPlaneId, v1102_.startStateChannel, v1102_.numStateChannels, v1104_)
			v1107_:setNewTypeIndexMode(DensityIndexCompareMode.UPDATE)
			if g_currentMission.foliageSystem ~= nil then
				local v1108_ = g_currentMission.foliageSystem:getDecoFoliages()
				for _, v1109_ in pairs(v1108_) do
					if v1109_.mowable and v1109_.terrainDataPlaneId ~= nil then
						if v1106_ == nil then
							v1106_ = DensityMapFilter.new(v1109_.terrainDataPlaneId, v1109_.startStateChannel, v1109_.numStateChannels)
						else
							v1106_:resetDensityMapAndChannels(v1109_.terrainDataPlaneId, v1109_.startStateChannel, v1109_.numStateChannels)
						end
						if v1102_.regrows and v1102_.firstRegrowthState ~= nil then
							v1106_:setValueCompareParams(DensityValueCompareType.GREATER, 0)
							v1105_:addExecuteSet(v1102_.firstRegrowthState, v1107_, v1106_)
						end
					end
				end
			end
			v1103_.multiModifier = v1105_
			FSDensityMapUtil.functionCache.updateMowerArea = v1103_
		end
		local v1110_ = v1103_.multiModifier
		if not limitToField then
			v1110_:updateParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
			v1110_:execute()
		end
	end
	return FSDensityMapUtil.cutFruitArea(fruitType, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, true, false, nil, nil, limitToField)
end

-- Local values: functionData, desc, dropModifier, dropFilter, _, numChangedPixels
function FSDensityMapUtil.updateFruitHaulmArea(fruitId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	local v1118_ = FSDensityMapUtil.functionCache.updateFruitHaulmArea
	if v1118_ == nil then
		v1118_ = {
			["fruitModifiers"] = {},
			["fruitFilters"] = {},
			["dropModifiers"] = {},
			["dropFilters"] = {}
		}
		FSDensityMapUtil.functionCache.updateFruitHaulmArea = v1118_
	end
	local v1119_ = g_fruitTypeManager:getFruitTypeByIndex(fruitId)
	if v1119_ == nil or v1119_.terrainDataPlaneIdHaulm == nil then
		return 0
	end
	local v1120_ = v1118_.dropModifiers[fruitId]
	local v1121_ = v1118_.dropFilters[fruitId]
	if v1120_ == nil or v1121_ == nil then
		v1120_ = v1119_:getHaulmModifier()
		v1118_.dropModifiers[fruitId] = v1120_
		v1121_ = DensityMapFilter.new(v1119_:getModifier())
		v1121_:setValueCompareParams(DensityValueCompareType.GREATER, 0)
		v1118_.dropFilters[fruitId] = v1121_
	end
	v1120_:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	local _, v1122_ = v1120_:executeSetWithStats(1, v1121_)
	return v1122_
end

-- Local values: functionData, terrainRootNode, fieldGroundSystem, stubbleShredLevelMapId, stubbleShredLevelFirstChannel, stubbleShredLevelNumChannels, stubbleShredModifier, _, stubbleArea, totalPixels
function FSDensityMapUtil.getStubbleFactor(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	if not Platform.gameplay.useStubbleShred then
		return 1
	end
	local v1129_ = FSDensityMapUtil.functionCache.getStubbleFactor
	if v1129_ == nil then
		local v1130_ = g_terrainNode
		local v1131_, v1132_, v1133_ = g_currentMission.fieldGroundSystem:getDensityMapData(FieldDensityMap.STUBBLE_SHRED_LEVEL)
		v1129_ = {
			["stubbleShredModifier"] = DensityMapModifier.new(v1131_, v1132_, v1133_, v1130_),
			["stubbleShredFilter"] = DensityMapFilter.new(v1131_, v1132_, v1133_)
		}
		v1129_.stubbleShredFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)
		FSDensityMapUtil.functionCache.getStubbleFactor = v1129_
	end
	local v1134_ = v1129_.stubbleShredModifier
	v1134_:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	local _, v1135_, v1136_ = v1134_:executeGet(v1129_.stubbleShredFilter)
	return v1135_ / v1136_
end

-- Local values: functionData, terrainRootNode, fieldGroundSystem, sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels, sprayLevelMapId, sprayLevelFirstChannel, sprayLevelNumChannels, sprayLevelMaxValue, resetModifier, excludeFilter, sprayLevelFilter
function FSDensityMapUtil.resetSprayArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, force, excludeType)
	local v1145_ = FSDensityMapUtil.functionCache.resetSprayArea
	if v1145_ == nil then
		local v1146_ = g_terrainNode
		local v1147_ = g_currentMission.fieldGroundSystem
		local v1148_, v1149_, v1150_ = v1147_:getDensityMapData(FieldDensityMap.SPRAY_TYPE)
		local v1151_, v1152_, v1153_ = v1147_:getDensityMapData(FieldDensityMap.SPRAY_LEVEL)
		local v1154_ = v1147_:getMaxValue(FieldDensityMap.SPRAY_LEVEL)
		v1145_ = {
			["resetModifier"] = DensityMapModifier.new(v1148_, v1149_, v1150_, v1146_),
			["excludeFilter"] = DensityMapFilter.new(v1148_, v1149_, v1150_),
			["sprayLevelFilter"] = DensityMapFilter.new(v1151_, v1152_, v1153_)
		}
		v1145_.sprayLevelFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, 0, v1154_)
		FSDensityMapUtil.functionCache.resetSprayArea = v1145_
	end
	local v1155_ = v1145_.resetModifier
	local v1156_ = v1145_.excludeFilter
	v1155_:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	local v1157_
	if force then
		v1157_ = nil
	else
		v1157_ = v1145_.sprayLevelFilter
	end
	if excludeType == nil then
		v1155_:executeSet(0, v1157_)
	else
		v1156_:setValueCompareParams(DensityValueCompareType.NOTEQUAL, excludeType)
		v1155_:executeSet(0, v1156_, v1157_)
	end
end

-- Local values: desc, functionData, terrainRootNode, fieldGroundSystem, groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, groundAngleMapId, groundAngleFirstChannel, groundAngleNumChannels, rollerLevelMapId, rollerLevelFirstChannel, rollerLevelNumChannels, rollerLevelMaxValue, fieldTypeMapId, fieldTypeFirstChannel, fieldTypeNumChannels, sownType, directSownType, ridgeType, ridgeTypeSown, stubbleTillagedType, firstSowableValue, lastSowableValue, firstSowingValue, lastSowingValue, fruitModifier, terrainRootNode, fruitFilter, fruitFilter, groundTypeModifier, groundAngleModifier, sowableFilter, sowingFilter, ridgeFilter, rollerLevelModifier, rollerLevelMaxValue, stubbleTillageFilter, directSownFilter, sownFilter, directSownType, sownType, ridgeTypeSown, fieldTypeFilter, rollerLevelValue, _, numPixels, _, totalArea, _, _, totalAreaStubble, _, directArea, totalSownArea, _, _, totalAreaSown, _, _, totalAreaSown, changedArea
function FSDensityMapUtil.updateSowingArea(fruitIndex, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, fieldGroundType, ridgeSeeding, angle, growthState, blockedSprayTypeIndex)
	local v1170_ = g_fruitTypeManager:getFruitTypeByIndex(fruitIndex)
	if v1170_.terrainDataPlaneId == nil then
		return 0, 0
	end
	local v1171_ = FSDensityMapUtil.functionCache.updateSowingArea
	if v1171_ == nil then
		local v1172_ = g_terrainNode
		local v1173_ = g_currentMission.fieldGroundSystem
		local v1174_, v1175_, v1176_ = v1173_:getDensityMapData(FieldDensityMap.GROUND_TYPE)
		local v1177_, v1178_, v1179_ = v1173_:getDensityMapData(FieldDensityMap.GROUND_ANGLE)
		local v1180_, v1181_, v1182_ = v1173_:getDensityMapData(FieldDensityMap.ROLLER_LEVEL)
		local v1183_ = v1173_:getMaxValue(FieldDensityMap.ROLLER_LEVEL)
		local v1184_, v1185_, v1186_ = v1173_:getDensityMapData(FieldDensityMap.FIELD_TYPE)
		local v1187_ = FieldGroundType.getValueByType(FieldGroundType.SOWN)
		local v1188_ = FieldGroundType.getValueByType(FieldGroundType.DIRECT_SOWN)
		FieldGroundType.getValueByType(FieldGroundType.RIDGE)
		local v1189_ = FieldGroundType.getValueByType(FieldGroundType.RIDGE_SOWN)
		local v1190_ = FieldGroundType.getValueByType(FieldGroundType.STUBBLE_TILLAGE)
		local v1191_, v1192_ = v1173_:getSowableRange()
		local v1193_, v1194_ = v1173_:getSowingRange()
		v1171_ = {
			["groundTypeModifier"] = DensityMapModifier.new(v1174_, v1175_, v1176_, v1172_),
			["groundAngleModifier"] = DensityMapModifier.new(v1177_, v1178_, v1179_, v1172_),
			["fruitModifiers"] = {},
			["fruitFilters"] = {},
			["sowableFilter"] = DensityMapFilter.new(v1174_, v1175_, v1176_)
		}
		v1171_.sowableFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, v1191_, v1192_)
		v1171_.sowingFilter = DensityMapFilter.new(v1174_, v1175_, v1176_)
		v1171_.sowingFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, v1193_, v1194_)
		v1171_.ridgeFilter = DensityMapFilter.new(v1174_, v1175_, v1176_)
		v1171_.ridgeFilter:setValueCompareParams(DensityValueCompareType.EQUAL, FieldGroundType.getValueByType(FieldGroundType.RIDGE))
		v1171_.fieldTypeFilter = DensityMapFilter.new(v1184_, v1185_, v1186_)
		if Platform.gameplay.useRolling then
			v1171_.rollerLevelModifier = DensityMapModifier.new(v1180_, v1181_, v1182_, v1172_)
			v1171_.rollerLevelMaxValue = v1183_
		end
		v1171_.sownType = v1187_
		v1171_.directSownType = v1188_
		v1171_.ridgeTypeSown = v1189_
		v1171_.firstSowableValue = v1191_
		v1171_.lastSowableValue = v1192_
		v1171_.firstSowingValue = v1193_
		v1171_.lastSowingValue = v1194_
		v1171_.stubbleTillageFilter = DensityMapFilter.new(v1174_, v1175_, v1176_)
		v1171_.stubbleTillageFilter:setValueCompareParams(DensityValueCompareType.EQUAL, v1190_)
		v1171_.directSownFilter = DensityMapFilter.new(v1174_, v1175_, v1176_)
		v1171_.directSownFilter:setValueCompareParams(DensityValueCompareType.EQUAL, v1188_)
		v1171_.sownFilter = DensityMapFilter.new(v1174_, v1175_, v1176_)
		v1171_.sownFilter:setValueCompareParams(DensityValueCompareType.EQUAL, v1187_)
		FSDensityMapUtil.functionCache.updateSowingArea = v1171_
	end
	local v1195_ = v1171_.fruitModifiers[fruitIndex]
	if v1195_ == nil then
		local v1196_ = g_terrainNode
		v1195_ = DensityMapModifier.new(v1170_.terrainDataPlaneId, v1170_.startStateChannel, v1170_.numStateChannels, v1196_)
		local v1197_ = DensityMapFilter.new(v1195_)
		v1171_.fruitModifiers[fruitIndex] = v1195_
		v1171_.fruitFilters[fruitIndex] = v1197_
	end
	local v1198_ = v1171_.fruitFilters[fruitIndex]
	local v1199_ = v1171_.groundTypeModifier
	local v1200_ = v1171_.groundAngleModifier
	local v1201_ = v1171_.sowableFilter
	local v1202_ = v1171_.sowingFilter
	local v1203_ = v1171_.ridgeFilter
	local v1204_ = v1171_.rollerLevelModifier
	local v1205_ = v1171_.rollerLevelMaxValue
	local v1206_ = v1171_.stubbleTillageFilter
	local v1207_ = v1171_.directSownFilter
	local v1208_ = v1171_.sownFilter
	local v1209_ = v1171_.directSownType
	local v1210_ = v1171_.sownType
	local v1211_ = v1171_.ridgeTypeSown
	local v1212_
	if v1170_.seedRequiredFieldType == nil then
		v1212_ = nil
	else
		v1212_ = v1171_.fieldTypeFilter
		v1212_:setValueCompareParams(DensityValueCompareType.EQUAL, FieldType.getValueByType(v1170_.seedRequiredFieldType))
	end
	local v1213_ = angle or 0
	local v1214_ = growthState or 1
	local v1215_ = fieldGroundType or v1210_
	v1195_:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	v1199_:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	v1200_:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	if Platform.gameplay.useRolling then
		v1204_:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
		v1204_:executeSet(not v1170_.needsRolling and 0 or v1205_, v1201_)
	end
	v1198_:setValueCompareParams(DensityValueCompareType.NOTEQUAL, v1214_)
	local _, v1216_, _ = v1195_:executeSetWithStats(v1214_, v1198_, v1201_, v1212_)
	if g_currentMission.missionInfo.weedsEnabled and v1170_.plantsWeed then
		FSDensityMapUtil.setSowingWeedArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	else
		FSDensityMapUtil.removeWeedArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	end
	FSDensityMapUtil.removeSprayArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, blockedSprayTypeIndex, v1201_)
	FSDensityMapUtil.resetDisplacementArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	local v1217_ = 0
	if v1215_ ~= v1211_ then
		local _, _, v1218_ = v1199_:executeSetWithStats(v1209_, v1201_, v1206_)
		v1217_ = v1217_ + v1218_
		local _, v1219_, v1220_ = v1199_:executeGet(v1207_)
		if v1220_ > 0 and v1219_ / v1220_ > 0.5 then
			v1199_:executeSet(v1209_, v1208_)
		end
	end
	v1198_:setValueCompareParams(DensityValueCompareType.EQUAL, v1214_)
	if ridgeSeeding then
		local _, _, v1221_ = v1199_:executeSetWithStats(v1211_, v1203_, v1198_)
		v1217_ = v1217_ + v1221_
	end
	local _, _, v1222_ = v1199_:executeSetWithStats(v1215_, v1201_, v1198_)
	local v1223_ = v1217_ + v1222_
	v1200_:executeSet(v1213_, v1202_, v1198_)
	return v1216_, v1223_
end

-- Local values: fruitTypeManager, desc, functionData, terrainRootNode, fieldGroundSystem, groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, groundAngleMapId, groundAngleFirstChannel, groundAngleNumChannels, sprayLevelMapId, sprayLevelFirstChannel, sprayLevelNumChannels, sprayLevelMaxValue, sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels, sownType, directSownType, ridgeTypeSown, stubbleTillagedType, firstSowableValue, lastSowableValue, firstSowingValue, lastSowingValue, rollerLevelMapId, rollerLevelFirstChannel, rollerLevelNumChannels, rollerLevelMaxValue, fieldTypeMapId, fieldTypeFirstChannel, fieldTypeNumChannels, sowableFilter, sowingFilter, ridgeFilter, fieldFilter, groundTypeFilter, ridgeTypeSown, directSownType, stubbleTillageFilter, directSownFilter, sownFilter, sprayLevelModifier, sprayLevelFilter, sprayTypeModifier, groundTypeModifier, groundAngleModifier, fruitMultiModifier, fruitModifier, terrainRootNode, rollerLevelModifier, rollerLevelMaxValue, fieldTypeFilter, multiModifier, stubbleTillagedType, index, fruitDesc, fruitFilter, preparingModifier, preparingFilter, modifier, harvestReadyType, harvestReadyOtherType, grassType, grassCutType, rollerLevelValue, _, changedArea, totalArea, _, directArea, totalSownArea
function FSDensityMapUtil.updateDirectSowingArea(fruitIndex, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, fieldGroundType, ridgeSeeding, angle, growthState, blockedSprayTypeIndex)
	local v1236_ = g_fruitTypeManager
	local v1237_ = v1236_:getFruitTypeByIndex(fruitIndex)
	if v1237_.terrainDataPlaneId == nil then
		return 0, 0
	end
	local v1238_ = angle or 0
	local v1239_ = growthState or 1
	local v1240_ = FSDensityMapUtil.functionCache.updateDirectSowingArea
	if v1240_ == nil then
		local v1241_ = g_terrainNode
		local v1242_ = g_currentMission.fieldGroundSystem
		local v1243_, v1244_, v1245_ = v1242_:getDensityMapData(FieldDensityMap.GROUND_TYPE)
		local v1246_, v1247_, v1248_ = v1242_:getDensityMapData(FieldDensityMap.GROUND_ANGLE)
		local v1249_, v1250_, v1251_ = v1242_:getDensityMapData(FieldDensityMap.SPRAY_LEVEL)
		local v1252_ = v1242_:getMaxValue(FieldDensityMap.SPRAY_LEVEL)
		local v1253_, v1254_, v1255_ = v1242_:getDensityMapData(FieldDensityMap.SPRAY_TYPE)
		local v1256_ = FieldGroundType.getValueByType(FieldGroundType.SOWN)
		local v1257_ = FieldGroundType.getValueByType(FieldGroundType.DIRECT_SOWN)
		local v1258_ = FieldGroundType.getValueByType(FieldGroundType.RIDGE_SOWN)
		local v1259_ = FieldGroundType.getValueByType(FieldGroundType.STUBBLE_TILLAGE)
		local v1260_, v1261_ = v1242_:getSowableRange()
		local v1262_, v1263_ = v1242_:getSowingRange()
		local v1264_, v1265_, v1266_ = v1242_:getDensityMapData(FieldDensityMap.ROLLER_LEVEL)
		local v1267_ = v1242_:getMaxValue(FieldDensityMap.ROLLER_LEVEL)
		local v1268_, v1269_, v1270_ = v1242_:getDensityMapData(FieldDensityMap.FIELD_TYPE)
		v1240_ = {
			["multiModifiers"] = {},
			["fruitModifiers"] = {},
			["fruitFilters"] = {},
			["preparingModifier"] = {},
			["preparingFilter"] = {},
			["sprayLevelModifier"] = DensityMapModifier.new(v1249_, v1250_, v1251_, v1241_),
			["sprayLevelFilter"] = DensityMapFilter.new(v1249_, v1250_, v1251_)
		}
		v1240_.sprayLevelFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, 0, v1252_ - 1)
		v1240_.sprayTypeModifier = DensityMapModifier.new(v1253_, v1254_, v1255_, v1241_)
		v1240_.groundTypeModifier = DensityMapModifier.new(v1243_, v1244_, v1245_, v1241_)
		v1240_.groundAngleModifier = DensityMapModifier.new(v1246_, v1247_, v1248_, v1241_)
		v1240_.fieldFilter = DensityMapFilter.new(v1243_, v1244_, v1245_)
		v1240_.fieldFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)
		v1240_.groundTypeFilter = DensityMapFilter.new(v1243_, v1244_, v1245_)
		v1240_.sowableFilter = DensityMapFilter.new(v1243_, v1244_, v1245_)
		v1240_.sowableFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, v1260_, v1261_)
		v1240_.sowingFilter = DensityMapFilter.new(v1243_, v1244_, v1245_)
		v1240_.sowingFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, v1262_, v1263_)
		v1240_.ridgeFilter = DensityMapFilter.new(v1243_, v1244_, v1245_)
		v1240_.ridgeFilter:setValueCompareParams(DensityValueCompareType.EQUAL, FieldGroundType.getValueByType(FieldGroundType.RIDGE))
		v1240_.stubbleTillageFilter = DensityMapFilter.new(v1243_, v1244_, v1245_)
		v1240_.stubbleTillageFilter:setValueCompareParams(DensityValueCompareType.EQUAL, v1259_)
		v1240_.directSownFilter = DensityMapFilter.new(v1243_, v1244_, v1245_)
		v1240_.directSownFilter:setValueCompareParams(DensityValueCompareType.EQUAL, v1257_)
		v1240_.sownFilter = DensityMapFilter.new(v1243_, v1244_, v1245_)
		v1240_.sownFilter:setValueCompareParams(DensityValueCompareType.EQUAL, v1256_)
		v1240_.fieldTypeFilter = DensityMapFilter.new(v1268_, v1269_, v1270_)
		if Platform.gameplay.useRolling then
			v1240_.rollerLevelModifier = DensityMapModifier.new(v1264_, v1265_, v1266_, v1241_)
			v1240_.rollerLevelMaxValue = v1267_
		end
		v1240_.sownType = v1256_
		v1240_.directSownType = v1257_
		v1240_.ridgeTypeSown = v1258_
		FSDensityMapUtil.functionCache.updateDirectSowingArea = v1240_
	end
	local v1271_ = v1240_.sowableFilter
	local v1272_ = v1240_.sowingFilter
	local v1273_ = v1240_.ridgeFilter
	local v1274_ = v1240_.fieldFilter
	local v1275_ = v1240_.groundTypeFilter
	local v1276_ = v1240_.ridgeTypeSown
	local v1277_ = v1240_.directSownType
	local v1278_ = v1240_.stubbleTillageFilter
	local v1279_ = v1240_.directSownFilter
	local v1280_ = v1240_.sownFilter
	local v1281_ = v1240_.sprayLevelModifier
	local v1282_ = v1240_.sprayLevelFilter
	local v1283_ = v1240_.sprayTypeModifier
	local v1284_ = v1240_.groundTypeModifier
	local v1285_ = v1240_.groundAngleModifier
	local v1286_ = v1240_.multiModifiers[fruitIndex]
	local v1287_ = v1240_.fruitModifiers[fruitIndex]
	local v1288_ = g_terrainNode
	local v1289_ = v1240_.rollerLevelModifier
	local v1290_ = v1240_.rollerLevelMaxValue
	local v1291_
	if v1237_.seedRequiredFieldType == nil then
		v1291_ = nil
	else
		v1291_ = v1240_.fieldTypeFilter
		v1291_:setValueCompareParams(DensityValueCompareType.EQUAL, FieldType.getValueByType(v1237_.seedRequiredFieldType))
	end
	if v1286_ == nil then
		v1286_ = {}
		v1240_.multiModifiers[fruitIndex] = v1286_
		v1287_ = DensityMapModifier.new(v1237_.terrainDataPlaneId, v1237_.startStateChannel, v1237_.numStateChannels, v1288_)
		v1240_.fruitModifiers[fruitIndex] = v1287_
	end
	local v1292_ = v1286_[v1239_]
	if v1292_ == nil then
		local v1293_ = FieldGroundType.getValueByType(FieldGroundType.STUBBLE_TILLAGE)
		v1292_ = DensityMapMultiModifier.new()
		v1286_[v1239_] = v1292_
		for v1294_, v1295_ in pairs(v1236_:getFruitTypes()) do
			if v1295_.terrainDataPlaneId ~= nil and v1295_.isCultivationAllowed then
				local v1296_ = v1240_.fruitFilters[v1294_]
				if v1296_ == nil then
					v1296_ = DensityMapFilter.new(v1295_.terrainDataPlaneId, v1237_.startStateChannel, v1237_.numStateChannels)
					v1240_.fruitFilters[v1294_] = v1296_
				end
				if v1295_.cutState > 1 then
					v1296_:setValueCompareParams(DensityValueCompareType.BETWEEN, 2, v1295_.cutState - 1)
					v1292_:addExecuteAdd(1, v1281_, v1282_, v1274_, v1296_)
					v1292_:addExecuteSet(1, v1283_, v1274_, v1296_)
				end
				if v1295_.allowsSeeding then
					if v1294_ == fruitIndex then
						local v1297_ = DensityValueCompareType.BETWEEN
						local v1298_ = v1239_ + 1
						local v1299_ = v1295_.maxHarvestingGrowthState
						local v1300_ = v1295_.cutState
						v1296_:setValueCompareParams(v1297_, v1298_, (math.max(v1299_, v1300_)))
						v1292_:addExecuteSet(v1293_, v1284_, v1274_, v1296_)
					else
						v1296_:setValueCompareParams(DensityValueCompareType.GREATER, 0)
						v1292_:addExecuteSet(v1293_, v1284_, v1274_, v1296_)
					end
					if v1295_.mulchedState ~= nil and (v1295_.mulchedState > 0 and v1295_.mulchedState ~= v1239_) then
						v1296_:setValueCompareParams(DensityValueCompareType.EQUAL, v1295_.mulchedState)
						v1292_:addExecuteSet(v1293_, v1284_, v1274_, v1296_)
					end
				end
				if v1295_.terrainDataPlaneIdHaulm ~= nil then
					local v1301_ = v1240_.preparingModifier[v1294_]
					if v1301_ == nil then
						v1301_ = DensityMapModifier.new(v1295_.terrainDataPlaneIdHaulm, v1295_.startStateChannelHaulm, v1295_.numStateChannelsHaulm)
						v1240_.preparingModifier[v1294_] = v1301_
					end
					local v1302_ = v1240_.preparingFilter[v1294_]
					if v1302_ == nil then
						v1302_ = DensityMapFilter.new(v1295_.terrainDataPlaneIdHaulm, v1295_.startStateChannelHaulm, v1295_.numStateChannelsHaulm)
						v1302_:setValueCompareParams(DensityValueCompareType.GREATER, 0)
						v1302_:setTypeIndexCompareMode(DensityTypeCompareType.ALWAYS)
						v1240_.preparingFilter[v1294_] = v1302_
					end
					v1292_:addExecuteSet(0, v1301_, v1302_)
				end
				local v1303_ = v1240_.fruitModifiers[v1294_]
				if v1303_ == nil then
					v1303_ = DensityMapModifier.new(v1295_.terrainDataPlaneId, v1237_.startStateChannel, v1237_.numStateChannels, v1288_)
					v1240_.fruitModifiers[v1294_] = v1303_
				end
				if v1294_ == fruitIndex then
					local v1304_ = DensityValueCompareType.BETWEEN
					local v1305_ = v1239_ + 1
					local v1306_ = v1295_.maxHarvestingGrowthState
					local v1307_ = v1295_.cutState
					v1296_:setValueCompareParams(v1304_, v1305_, (math.max(v1306_, v1307_)))
				else
					local v1308_ = DensityValueCompareType.BETWEEN
					local v1309_ = v1295_.maxHarvestingGrowthState
					local v1310_ = v1295_.cutState
					v1296_:setValueCompareParams(v1308_, 2, (math.max(v1309_, v1310_)))
				end
				v1292_:addExecuteSet(0, v1303_, v1296_, v1274_)
			end
		end
		local v1311_ = FieldGroundType.getValueByType(FieldGroundType.HARVEST_READY)
		v1275_:setValueCompareParams(DensityValueCompareType.EQUAL, v1311_)
		v1292_:addExecuteSet(v1293_, v1284_, v1275_)
		local v1312_ = FieldGroundType.getValueByType(FieldGroundType.HARVEST_READY_OTHER)
		v1275_:setValueCompareParams(DensityValueCompareType.EQUAL, v1312_)
		v1292_:addExecuteSet(v1293_, v1284_, v1275_)
		local v1313_ = FieldGroundType.getValueByType(FieldGroundType.GRASS)
		v1275_:setValueCompareParams(DensityValueCompareType.EQUAL, v1313_)
		v1292_:addExecuteSet(v1293_, v1284_, v1275_)
		local v1314_ = FieldGroundType.getValueByType(FieldGroundType.GRASS_CUT)
		v1275_:setValueCompareParams(DensityValueCompareType.EQUAL, v1314_)
		v1292_:addExecuteSet(v1293_, v1284_, v1275_)
		FSDensityMapUtil.multiModifierAddResetDisplacement(v1292_)
	end
	v1287_:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	v1284_:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	v1285_:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	v1292_:updateParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	v1292_:execute()
	if g_currentMission.missionInfo.weedsEnabled and v1237_.plantsWeed then
		FSDensityMapUtil.setSowingWeedArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	else
		FSDensityMapUtil.removeWeedArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	end
	if Platform.gameplay.useRolling then
		v1289_:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
		v1289_:executeSet(not v1237_.needsRolling and 0 or v1290_, v1271_)
	end
	local _, v1315_, v1316_ = v1287_:executeSetWithStats(v1239_, v1271_, v1291_)
	if fieldGroundType ~= v1276_ then
		v1284_:executeSet(v1277_, v1271_, v1278_)
		local _, v1317_, v1318_ = v1284_:executeGet(v1279_)
		if v1318_ > 0 and v1317_ / v1318_ > 0.5 then
			v1284_:executeSet(v1277_, v1280_)
		end
	end
	if ridgeSeeding then
		v1284_:executeSet(v1276_, v1273_)
	end
	v1284_:executeSet(fieldGroundType, v1271_, v1291_)
	v1285_:executeSet(v1238_, v1272_)
	FSDensityMapUtil.removeSprayArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, blockedSprayTypeIndex)
	DensityMapHeightUtil.clearArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	return v1315_, v1316_
end

-- Local values: functionData, terrainRootNode, fieldGroundSystem, groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, groundAngleMapId, groundAngleFirstChannel, groundAngleNumChannels, ridgeType, firstSowableValue, lastSowableValue, sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels, groundTypeModifier, groundAngleModifier, sprayTypeModifier, sowableFilter, ridgeFilter, ridgeType, changedArea, totalArea, _
function FSDensityMapUtil.updateRidgeFormerArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, angle)
	local v1326_ = FSDensityMapUtil.functionCache.updateRidgeFormerArea
	if v1326_ == nil then
		local v1327_ = g_terrainNode
		local v1328_ = g_currentMission.fieldGroundSystem
		local v1329_, v1330_, v1331_ = v1328_:getDensityMapData(FieldDensityMap.GROUND_TYPE)
		local v1332_, v1333_, v1334_ = v1328_:getDensityMapData(FieldDensityMap.GROUND_ANGLE)
		local v1335_ = FieldGroundType.getValueByType(FieldGroundType.RIDGE)
		local v1336_, v1337_ = v1328_:getSowableRange()
		v1326_ = {
			["groundTypeModifier"] = DensityMapModifier.new(v1329_, v1330_, v1331_, v1327_),
			["groundAngleModifier"] = DensityMapModifier.new(v1332_, v1333_, v1334_, v1327_)
		}
		local v1338_, v1339_, v1340_ = v1328_:getDensityMapData(FieldDensityMap.SPRAY_TYPE)
		v1326_.sprayTypeModifier = DensityMapModifier.new(v1338_, v1339_, v1340_, v1327_)
		v1326_.sowableFilter = DensityMapFilter.new(v1329_, v1330_, v1331_)
		v1326_.sowableFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, v1336_, v1337_)
		v1326_.ridgeType = v1335_
		v1326_.ridgeFilter = DensityMapFilter.new(v1329_, v1330_, v1331_)
		v1326_.ridgeFilter:setValueCompareParams(DensityValueCompareType.EQUAL, v1335_)
		FSDensityMapUtil.functionCache.updateRidgeFormerArea = v1326_
	end
	local v1341_ = v1326_.groundTypeModifier
	local v1342_ = v1326_.groundAngleModifier
	local v1343_ = v1326_.sprayTypeModifier
	local v1344_ = v1326_.sowableFilter
	local v1345_ = v1326_.ridgeFilter
	local v1346_ = v1326_.ridgeType
	v1341_:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	v1342_:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	v1343_:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	v1343_:executeSet(0, v1344_)
	local v1347_, v1348_, _ = v1341_:executeSetWithStats(v1346_, v1344_)
	v1342_:executeSet(angle or 0, v1345_)
	return v1347_, v1348_
end

-- Local values: functionData, desc, fruitModifier, terrainRootNode, fruitFilter, dropModifier, fruitFilter, dropModifier, dropFilter, _, numChangedPixels
function FSDensityMapUtil.updateFruitPreparerArea(fruitId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, startDropWorldX, startDropWorldZ, widthDropWorldX, widthDropWorldZ, heightDropWorldX, heightDropWorldZ, limitToFruit)
	local v1363_ = FSDensityMapUtil.functionCache.updateFruitPreparerArea
	if v1363_ == nil then
		v1363_ = {
			["fruitModifiers"] = {},
			["fruitFilters"] = {},
			["dropModifiers"] = {},
			["dropFilters"] = {}
		}
		FSDensityMapUtil.functionCache.updateFruitPreparerArea = v1363_
	end
	local v1364_ = g_fruitTypeManager:getFruitTypeByIndex(fruitId)
	local v1365_ = v1363_.fruitModifiers[fruitId]
	if v1365_ == nil then
		local v1366_ = g_terrainNode
		v1365_ = DensityMapModifier.new(v1364_.terrainDataPlaneId, v1364_.startStateChannel, v1364_.numStateChannels, v1366_)
		v1363_.fruitModifiers[fruitId] = v1365_
		v1363_.fruitFilters[fruitId] = {}
		local v1367_ = DensityMapFilter.new(v1365_)
		v1367_:setValueCompareParams(DensityValueCompareType.BETWEEN, v1364_.minPreparingGrowthState, v1364_.maxPreparingGrowthState)
		v1363_.fruitFilters[fruitId][true] = v1367_
		local v1368_ = DensityMapFilter.new(v1365_)
		v1368_:setValueCompareParams(DensityValueCompareType.BETWEEN, 1, 15)
		v1363_.fruitFilters[fruitId][false] = v1368_
		if v1364_.terrainDataPlaneIdHaulm ~= nil then
			local v1369_ = DensityMapModifier.new(v1364_.terrainDataPlaneIdHaulm, 0, 1, v1366_)
			v1363_.dropModifiers[fruitId] = v1369_
		end
	end
	local v1370_ = v1363_.fruitFilters[fruitId][true]
	v1365_:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	local v1371_
	if v1364_.terrainDataPlaneIdHaulm == nil then
		v1371_ = nil
	else
		v1371_ = v1363_.dropModifiers[fruitId]
		v1371_:setParallelogramWorldCoords(startDropWorldX, startDropWorldZ, widthDropWorldX, widthDropWorldZ, heightDropWorldX, heightDropWorldZ, DensityCoordType.POINT_POINT_POINT)
	end
	if v1371_ ~= nil then
		local v1372_ = limitToFruit == nil and true or limitToFruit
		v1371_:executeSet(1, v1363_.fruitFilters[fruitId][v1372_])
	end
	local _, v1373_ = v1365_:executeSetWithStats(v1364_.preparedGrowthState, v1370_)
	return v1373_
end

-- Local values: functionData, decoFoliages, terrainRootNode, index, decoFoliage, decoModifier, decoFilter, area, totalArea, nonMowableCut, index, decoFoliage, decoModifier, decoFilter, _, _area, _totalArea
function FSDensityMapUtil.clearDecoArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	local v1380_ = FSDensityMapUtil.functionCache.clearDecoArea
	if v1380_ == nil then
		local v1381_
		if g_currentMission.foliageSystem == nil then
			v1381_ = nil
		else
			v1381_ = g_currentMission.foliageSystem:getDecoFoliages()
		end
		local v1382_ = g_terrainNode
		if v1381_ ~= nil and #v1381_ > 0 then
			v1380_ = {
				["decoModifiers"] = {},
				["decoFilters"] = {},
				["decoFoliages"] = v1381_
			}
			for v1383_, v1384_ in pairs(v1381_) do
				if v1384_.terrainDataPlaneId ~= nil then
					local v1385_ = DensityMapModifier.new(v1384_.terrainDataPlaneId, v1384_.startStateChannel, v1384_.numStateChannels, v1382_)
					v1385_:setNewTypeIndexMode(DensityIndexCompareMode.ZERO)
					local v1386_ = DensityMapFilter.new(v1384_.terrainDataPlaneId, v1384_.startStateChannel, v1384_.numStateChannels)
					v1386_:setValueCompareParams(DensityValueCompareType.GREATER, 0)
					v1380_.decoModifiers[v1383_] = v1385_
					v1380_.decoFilters[v1383_] = v1386_
				end
			end
			FSDensityMapUtil.functionCache.clearDecoArea = v1380_
		end
	end
	if v1380_ == nil then
		return 0, 0, false
	end
	local v1387_ = 0
	local v1388_ = 0
	local v1389_ = false
	for v1390_, v1391_ in pairs(v1380_.decoFoliages) do
		if v1391_.terrainDataPlaneId ~= nil then
			local v1392_ = v1380_.decoModifiers[v1390_]
			local v1393_ = v1380_.decoFilters[v1390_]
			if v1392_ ~= nil and v1393_ ~= nil then
				v1392_:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
				local _, v1394_, v1395_ = v1392_:executeSetWithStats(0, v1393_)
				v1387_ = v1387_ + v1394_
				v1388_ = v1388_ + v1395_
				if v1394_ > 0 and not v1391_.mowable then
					v1389_ = true
				end
			end
		end
	end
	return v1387_, v1388_, v1389_
end

-- Local values: functionData, stoneSystem, terrainRootNode, stoneMapId, stoneFirstChannel, stoneNumChannels, fieldGroundSystem, terrainRootNode, limeLevelMapId, limeLevelFirstChannel, limeLevelNumChannels, fruitData, terrainRootNode, desc, fieldGroundSystem, groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, grassType, fruitModifier, fruitFilter, groundModifier, grassType, stoneModifier, limeLevelModifier, _, area
function FSDensityMapUtil.createVineArea(fruitId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, customState, ignoreExistingFruits)
	local v1405_ = FSDensityMapUtil.functionCache.createVineArea
	if v1405_ == nil then
		v1405_ = {
			["fruitData"] = {}
		}
		local v1406_ = g_currentMission.stoneSystem
		if v1406_:getMapHasStones() then
			local v1407_ = g_terrainNode
			local v1408_, v1409_, v1410_ = v1406_:getDensityMapData()
			v1405_.stoneModifier = DensityMapModifier.new(v1408_, v1409_, v1410_, v1407_)
		end
		if Platform.gameplay.useLimeCounter then
			local v1411_ = g_currentMission.fieldGroundSystem
			local v1412_ = g_terrainNode
			local v1413_, v1414_, v1415_ = v1411_:getDensityMapData(FieldDensityMap.LIME_LEVEL)
			if v1413_ ~= nil then
				v1405_.limeLevelModifier = DensityMapModifier.new(v1413_, v1414_, v1415_, v1412_)
				v1405_.limeLevelMaxValue = v1411_:getMaxValue(FieldDensityMap.LIME_LEVEL)
			end
		end
		FSDensityMapUtil.functionCache.createVineArea = v1405_
	end
	local v1416_ = v1405_.fruitData[fruitId]
	if v1416_ == nil then
		local v1417_ = g_terrainNode
		local v1418_ = g_fruitTypeManager:getFruitTypeByIndex(fruitId)
		local v1419_, v1420_, v1421_ = g_currentMission.fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
		local v1422_ = FieldGroundType.getValueByType(FieldGroundType.GRASS)
		if v1418_.terrainDataPlaneId == nil then
			return 0
		end
		v1416_ = {
			["fruitModifier"] = DensityMapModifier.new(v1418_.terrainDataPlaneId, v1418_.startStateChannel, v1418_.numStateChannels, v1417_)
		}
		v1416_.fruitModifier:setPolygonRoundingMode(DensityRoundingMode.NEAREST)
		v1416_.fruitFilter = DensityMapFilter.new(v1418_.terrainDataPlaneId, v1418_.startStateChannel, v1418_.numStateChannels)
		v1416_.fruitFilter:setValueCompareParams(DensityValueCompareType.EQUAL, 0)
		v1416_.groundModifier = DensityMapModifier.new(v1419_, v1420_, v1421_, v1417_)
		v1416_.groundModifier:setPolygonRoundingMode(DensityRoundingMode.NEAREST)
		v1416_.grassType = v1422_
		v1405_.fruitData[fruitId] = v1416_
	end
	local v1423_ = v1416_.fruitModifier
	local v1424_ = v1416_.fruitFilter
	local v1425_ = v1416_.groundModifier
	local v1426_ = v1416_.grassType
	local v1427_ = v1405_.stoneModifier
	local v1428_ = v1405_.limeLevelModifier
	v1423_:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	v1425_:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	FSDensityMapUtil.updateDestroyCommonArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, false, false)
	if v1427_ ~= nil then
		v1427_:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
		v1427_:executeSet(0)
	end
	if v1428_ ~= nil then
		v1428_:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
		v1428_:executeSet(v1405_.limeLevelMaxValue)
	end
	if ignoreExistingFruits then
		v1424_ = nil
	end
	local _, v1429_ = v1423_:executeSetWithStats(customState or 1, v1424_)
	v1425_:executeSet(v1426_)
	return v1429_
end

-- Local values: functionData, terrainRootNode, fieldGroundSystem, groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, groundModifier
function FSDensityMapUtil.destroyVineArea(fruitId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	local v1436_ = FSDensityMapUtil.functionCache.destroyVineArea
	if v1436_ == nil then
		local v1437_ = g_terrainNode
		local v1438_, v1439_, v1440_ = g_currentMission.fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
		v1436_ = {
			["groundModifier"] = DensityMapModifier.new(v1438_, v1439_, v1440_, v1437_)
		}
		v1436_.groundModifier:setPolygonRoundingMode(DensityRoundingMode.NEAREST)
		FSDensityMapUtil.functionCache.destroyVineArea = v1436_
	end
	local v1441_ = v1436_.groundModifier
	FSDensityMapUtil.updateDestroyCommonArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, false, true)
	v1441_:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	v1441_:executeSet(0)
end

-- Local values: functionData, fruitData, terrainRootNode, desc, i, i, totalArea, state, _, filter, _, area, tArea
function FSDensityMapUtil.updateVineAreaValues(fruitId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, values)
	local v1450_ = FSDensityMapUtil.functionCache.updateVineAreaValues
	if v1450_ == nil then
		v1450_ = {
			["fruitData"] = {}
		}
		FSDensityMapUtil.functionCache.updateVineAreaValues = v1450_
	end
	local v1451_ = v1450_.fruitData[fruitId]
	if v1451_ == nil then
		v1451_ = {}
		local v1452_ = g_terrainNode
		local v1453_ = g_fruitTypeManager:getFruitTypeByIndex(fruitId)
		if v1453_.terrainDataPlaneId == nil then
			for v1454_ = 0, v1453_.numStateChannels ^ 2 - 1 do
				values[v1454_] = 0
			end
			return 0
		end
		v1451_.modifier = DensityMapModifier.new(v1453_.terrainDataPlaneId, v1453_.startStateChannel, v1453_.numStateChannels, v1452_)
		v1451_.modifier:setPolygonRoundingMode(DensityRoundingMode.NEAREST)
		v1451_.filters = {}
		for v1455_ = 0, v1453_.numStateChannels ^ 2 - 1 do
			v1451_.filters[v1455_] = DensityMapFilter.new(v1453_.terrainDataPlaneId, v1453_.startStateChannel, v1453_.numStateChannels)
			v1451_.filters[v1455_]:setValueCompareParams(DensityValueCompareType.EQUAL, v1455_)
		end
		v1450_.fruitData[fruitId] = v1451_
	end
	v1451_.modifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	local v1456_ = 0
	for v1457_, _ in pairs(values) do
		local v1458_ = v1451_.filters[v1457_]
		local _, v1459_, v1460_ = v1451_.modifier:executeGet(v1458_)
		values[v1457_] = v1459_
		v1456_ = math.max(v1456_, v1460_)
	end
	return v1456_
end

-- Local values: functionData, fruitData, terrainRootNode, desc
function FSDensityMapUtil:setVineAreaValue(fruitId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, value)
	local v1469_ = FSDensityMapUtil.functionCache.setVineAreaValue
	if v1469_ == nil then
		v1469_ = {
			["fruitData"] = {}
		}
		FSDensityMapUtil.functionCache.setVineAreaValue = v1469_
	end
	local v1470_ = v1469_.fruitData[fruitId]
	if v1470_ == nil then
		v1470_ = {}
		local v1471_ = g_terrainNode
		local v1472_ = g_fruitTypeManager:getFruitTypeByIndex(fruitId)
		v1470_.modifier = DensityMapModifier.new(v1472_.terrainDataPlaneId, v1472_.startStateChannel, v1472_.numStateChannels, v1471_)
		v1469_.fruitData[fruitId] = v1470_
	end
	v1470_.modifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	v1470_.modifier:executeSet(value)
end

-- Local values: functionData, desc, terrainRootNode, fieldGroundSystem, sprayLevelMapId, sprayLevelFirstChannel, sprayLevelNumChannels, plowLevelMapId, plowLevelFirstChannel, plowLevelNumChannels, plowLevelModifier, i, sprayLevelFilter, fruitData, terrainRootNode, src, target, harvestFilter, fruitModifier, transitionFilters, weedFilter, harvestFilter, sprayLevelModifier, sprayLevelMaxValue, plowLevelModifier, sprayLevelFilters, _, sprayLevel, i, filter, _, sprayLevelArea, _, weedArea, plowArea, plowLevel, area, totalArea, filterArea, target, filter, weedFactor, sprayFactor, plowFactor
function FSDensityMapUtil.updateVineCutArea(fruitId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	local v1480_ = FSDensityMapUtil.functionCache.updateVineCutArea
	local v1481_ = g_fruitTypeManager:getFruitTypeByIndex(fruitId)
	if v1480_ == nil then
		local v1482_ = g_terrainNode
		local v1483_ = g_currentMission.fieldGroundSystem
		local v1484_, v1485_, v1486_ = v1483_:getDensityMapData(FieldDensityMap.SPRAY_LEVEL)
		v1480_ = {
			["fruitData"] = {},
			["sprayLevelMaxValue"] = v1483_:getMaxValue(FieldDensityMap.SPRAY_LEVEL),
			["sprayLevelModifier"] = DensityMapModifier.new(v1484_, v1485_, v1486_, v1482_)
		}
		if Platform.gameplay.usePlowCounter then
			local v1487_, v1488_, v1489_ = v1483_:getDensityMapData(FieldDensityMap.PLOW_LEVEL)
			v1480_.plowLevelModifier = DensityMapModifier.new(v1487_, v1488_, v1489_, v1482_)
		end
		v1480_.sprayLevelFilters = {}
		for v1490_ = 1, v1480_.sprayLevelMaxValue do
			local v1491_ = DensityMapFilter.new(v1484_, v1485_, v1486_)
			v1491_:setValueCompareParams(DensityValueCompareType.EQUAL, v1490_)
			v1480_.sprayLevelFilters[v1490_] = v1491_
		end
		FSDensityMapUtil.functionCache.updateVineCutArea = v1480_
	end
	local v1492_ = v1480_.fruitData[fruitId]
	if v1492_ == nil then
		v1492_ = {}
		local v1493_ = g_terrainNode
		if v1481_.terrainDataPlaneId == nil then
			return 0
		end
		v1492_.fruitModifier = DensityMapModifier.new(v1481_.terrainDataPlaneId, v1481_.startStateChannel, v1481_.numStateChannels, v1493_)
		v1492_.fruitModifier:setPolygonRoundingMode(DensityRoundingMode.NEAREST)
		v1492_.transitionFilters = {}
		for v1494_, v1495_ in pairs(v1481_.harvestTransitions) do
			local v1496_ = DensityMapFilter.new(v1481_.terrainDataPlaneId, v1481_.startStateChannel, v1481_.numStateChannels)
			v1496_:setValueCompareParams(DensityValueCompareType.EQUAL, v1494_)
			v1492_.transitionFilters[v1495_] = v1496_
		end
		v1492_.harvestFilter = DensityMapFilter.new(v1481_.terrainDataPlaneId, v1481_.startStateChannel, v1481_.numStateChannels)
		v1492_.harvestFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, v1481_.minHarvestingGrowthState, v1481_.maxHarvestingGrowthState)
		if v1481_.harvestWeedState ~= -1 then
			v1492_.weedFilter = DensityMapFilter.new(v1481_.terrainDataPlaneId, v1481_.startStateChannel, v1481_.numStateChannels)
			v1492_.weedFilter:setValueCompareParams(DensityValueCompareType.EQUAL, v1481_.harvestWeedState)
		end
		v1480_.fruitData[fruitId] = v1492_
	end
	local v1497_ = v1492_.fruitModifier
	local v1498_ = v1492_.transitionFilters
	local v1499_ = v1492_.weedFilter
	local v1500_ = v1492_.harvestFilter
	local v1501_ = v1480_.sprayLevelModifier
	local v1502_ = v1480_.sprayLevelMaxValue
	local v1503_ = v1480_.plowLevelModifier
	local v1504_ = v1480_.sprayLevelFilters
	v1497_:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	v1501_:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	local v1505_ = 0
	for v1506_, v1507_ in pairs(v1504_) do
		local _, v1508_, _ = v1501_:executeGet(v1507_)
		if v1508_ > 0 and v1505_ < v1506_ then
			v1505_ = v1506_
		end
	end
	FSDensityMapUtil.resetSprayArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, true, nil)
	v1501_:executeSet(0, v1500_)
	if v1481_.startSprayLevel > 0 then
		local v1509_ = v1481_.startSprayLevel
		v1501_:executeSet(math.min(v1509_, v1502_), v1500_)
		FSDensityMapUtil.resetSprayArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, true, nil)
	end
	local v1510_
	if v1499_ == nil then
		v1510_ = 0
	else
		local v1511_, v1512_
		v1511_, v1510_, v1512_ = v1497_:executeGet(v1499_)
	end
	local v1513_ = 0
	local v1514_
	if v1503_ == nil then
		v1514_ = 0
	else
		v1503_:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
		local v1515_, v1516_
		v1514_, v1515_, v1516_ = v1503_:executeAddWithStats(-1, v1500_)
	end
	local v1517_ = 0
	local v1518_ = nil
	for v1519_, v1520_ in pairs(v1498_) do
		local v1521_, v1522_
		v1521_, v1522_, v1518_ = v1497_:executeSetWithStats(v1519_, v1520_)
		v1517_ = v1517_ + v1522_
	end
	if v1514_ > 0 then
		v1513_ = v1517_
	end
	return v1517_, v1518_, 1 - (v1510_ < v1518_ and 0 or v1510_) / v1518_, v1505_ / v1502_, v1513_ / v1518_
end

-- Local values: functionData, fruitData, terrainRootNode, desc, fruitModifier, fruitFilter, _, area, totalArea
function FSDensityMapUtil.updateVinePrepareArea(fruitId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	local v1530_ = FSDensityMapUtil.functionCache.updateVinePrepareArea
	if v1530_ == nil then
		v1530_ = {
			["fruitData"] = {}
		}
		FSDensityMapUtil.functionCache.updateVinePrepareArea = v1530_
	end
	local v1531_ = v1530_.fruitData[fruitId]
	if v1531_ == nil then
		local v1532_ = g_terrainNode
		local v1533_ = g_fruitTypeManager:getFruitTypeByIndex(fruitId)
		if v1533_.terrainDataPlaneId == nil then
			return 0
		end
		if v1533_.witheredState == nil then
			return 0
		end
		v1531_ = {
			["fruitModifier"] = DensityMapModifier.new(v1533_.terrainDataPlaneId, v1533_.startStateChannel, v1533_.numStateChannels, v1532_)
		}
		v1531_.fruitModifier:setPolygonRoundingMode(DensityRoundingMode.NEAREST)
		v1531_.fruitFilter = DensityMapFilter.new(v1533_.terrainDataPlaneId, v1533_.startStateChannel, v1533_.numStateChannels)
		v1531_.fruitFilter:setValueCompareParams(DensityValueCompareType.EQUAL, v1533_.witheredState)
		v1530_.fruitData[fruitId] = v1531_
	end
	local v1534_ = v1531_.fruitModifier
	local v1535_ = v1531_.fruitFilter
	v1534_:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	local _, v1536_, v1537_ = v1534_:executeSetWithStats(1, v1535_)
	return v1536_, v1537_
end

-- Local values: functionData, fruitData, terrainRootNode, desc, fruitModifier, fruitFilter, _, area, totalArea
function FSDensityMapUtil.resetVineArea(fruitId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, resetState)
	local v1546_ = FSDensityMapUtil.functionCache.resetVineArea
	if v1546_ == nil then
		v1546_ = {
			["fruitData"] = {}
		}
		FSDensityMapUtil.functionCache.resetVineArea = v1546_
	end
	local v1547_ = v1546_.fruitData[fruitId]
	if v1547_ == nil then
		v1547_ = {}
		local v1548_ = g_terrainNode
		local v1549_ = g_fruitTypeManager:getFruitTypeByIndex(fruitId)
		if v1549_.terrainDataPlaneId == nil then
			return 0
		end
		v1547_.fruitModifier = DensityMapModifier.new(v1549_.terrainDataPlaneId, v1549_.startStateChannel, v1549_.numStateChannels, v1548_)
		v1547_.fruitModifier:setPolygonRoundingMode(DensityRoundingMode.NEAREST)
		v1547_.fruitFilter = DensityMapFilter.new(v1549_.terrainDataPlaneId, v1549_.startStateChannel, v1549_.numStateChannels)
		v1547_.fruitFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)
		v1546_.fruitData[fruitId] = v1547_
	end
	local v1550_ = v1547_.fruitModifier
	local v1551_ = v1547_.fruitFilter
	v1550_:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	local _, v1552_, v1553_ = v1550_:executeSetWithStats(resetState, v1551_)
	return v1552_, v1553_
end

-- Local values: functionData, terrainRootNode, fieldGroundSystem, groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, cultivatedType, groundModifier, multiModifiers, fruitFilter, plowLevelModifier, plowLevelMapId, plowLevelFirstChannel, plowLevelNumChannels, index, desc, _, state, multiModifiers, groundModifier, groundFilter, _, areaBefore, _, _, areaAfter, _
function FSDensityMapUtil.updateVineCultivatorArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, changeGroundType)
	local v1561_ = FSDensityMapUtil.functionCache.updateVineCultivatorArea
	local v1562_ = changeGroundType == nil and true or changeGroundType
	if v1561_ == nil then
		local v1563_ = g_terrainNode
		local v1564_ = g_currentMission.fieldGroundSystem
		local v1565_, v1566_, v1567_ = v1564_:getDensityMapData(FieldDensityMap.GROUND_TYPE)
		local v1568_ = FieldGroundType.getValueByType(FieldGroundType.CULTIVATED)
		local v1569_ = DensityMapModifier.new(v1565_, v1566_, v1567_, v1563_)
		v1561_ = {
			["fruitData"] = {},
			["groundModifier"] = v1569_,
			["groundFilter"] = DensityMapFilter.new(v1565_, v1566_, v1567_)
		}
		v1561_.groundFilter:setValueCompareParams(DensityValueCompareType.EQUAL, v1568_)
		local v1570_ = {
			[true] = DensityMapMultiModifier.new(),
			[false] = DensityMapMultiModifier.new()
		}
		local v1571_ = nil
		local v1572_
		if Platform.gameplay.usePlowCounter then
			local v1573_, v1574_, v1575_ = v1564_:getDensityMapData(FieldDensityMap.PLOW_LEVEL)
			v1572_ = DensityMapModifier.new(v1573_, v1574_, v1575_, v1563_)
		else
			v1572_ = nil
		end
		for _, v1576_ in pairs(g_fruitTypeManager:getFruitTypes()) do
			if v1576_.terrainDataPlaneId ~= nil and v1576_.cultivationStates ~= nil then
				if v1571_ == nil then
					v1571_ = DensityMapFilter.new(v1576_.terrainDataPlaneId, v1576_.startStateChannel, v1576_.numStateChannels)
				else
					v1571_:resetDensityMapAndChannels(v1576_.terrainDataPlaneId, v1576_.startStateChannel, v1576_.numStateChannels)
				end
				for _, v1577_ in ipairs(v1576_.cultivationStates) do
					v1571_:setValueCompareParams(DensityValueCompareType.EQUAL, v1577_)
					v1570_[true]:addExecuteSet(v1568_, v1569_, v1571_)
					if v1572_ ~= nil then
						v1570_[true]:addExecuteAdd(1, v1572_, v1571_)
						v1570_[false]:addExecuteAdd(1, v1572_, v1571_)
					end
				end
			end
		end
		v1561_.multiModifiers = v1570_
		FSDensityMapUtil.functionCache.updateVineCultivatorArea = v1561_
	end
	local v1578_ = v1561_.multiModifiers
	local v1579_ = v1561_.groundModifier
	local v1580_ = v1561_.groundFilter
	v1579_:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	local _, v1581_, _ = v1579_:executeGet(v1580_)
	v1578_[v1562_]:updateParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	v1578_[v1562_]:execute()
	local _, v1582_, _ = v1579_:executeGet(v1580_)
	FSDensityMapUtil.removeWeedArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	return v1582_ - v1581_
end

-- Local values: functionData, fieldGroundSystem, groundTypeMapId, _, _, multiModifier, perlinFilter, fruitFilter, fruitModifier, index, desc, weedSystem, weedMapId, weedFirstChannel, weedNumChannels, weedModifier, fieldGroundSystem, groundTypeMapId, firstChannel, numChannels, groundModifier, groundFilter, groundTypeSown, groundTypeHarvestReady, groundType
function FSDensityMapUtil.updateDisasterArea(densityMapArea, perlinPercentage)
	local v1585_ = FSDensityMapUtil.functionCache.updateDisasterArea
	if v1585_ == nil then
		local v1586_, _, _ = g_currentMission.fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
		v1585_ = {
			["perlinFilters"] = {},
			["multiModifiers"] = {},
			["perlinFilter"] = PerlinNoiseFilter.new(v1586_, 11, 1, 0.5, math.random(0, 10000))
		}
		FSDensityMapUtil.functionCache.updateDisasterArea = v1585_
	end
	local v1587_ = v1585_.multiModifiers[perlinPercentage]
	if v1587_ == nil then
		local v1588_ = v1585_.perlinFilter
		v1588_:setValueCompareParams(DensityValueCompareType.GREATER, perlinPercentage)
		v1587_ = DensityMapMultiModifier.new()
		local v1589_ = nil
		local v1590_ = nil
		for _, v1591_ in pairs(g_fruitTypeManager:getFruitTypes()) do
			if v1591_.terrainDataPlaneId ~= nil and v1591_.minDisasterDestructionState ~= nil then
				if v1589_ == nil then
					v1589_ = DensityMapFilter.new(v1591_.terrainDataPlaneId, v1591_.startStateChannel, v1591_.numStateChannels)
				else
					v1589_:resetDensityMapAndChannels(v1591_.terrainDataPlaneId, v1591_.startStateChannel, v1591_.numStateChannels)
				end
				v1589_:setValueCompareParams(DensityValueCompareType.BETWEEN, v1591_.minDisasterDestructionState, v1591_.maxDisasterDestructionState)
				if v1590_ == nil then
					v1590_ = DensityMapModifier.new(v1591_.terrainDataPlaneId, v1591_.startStateChannel, v1591_.numStateChannels)
				else
					v1590_:resetDensityMapAndChannels(v1591_.terrainDataPlaneId, v1591_.startStateChannel, v1591_.numStateChannels)
				end
				if v1591_.disasterDestructionState == 0 then
					v1590_:setNewTypeIndexMode(DensityIndexCompareMode.ZERO)
				else
					v1590_:setNewTypeIndexMode(DensityIndexCompareMode.KEEP)
				end
				v1587_:addExecuteSet(v1591_.disasterDestructionState, v1590_, v1589_, v1588_)
			end
		end
		local v1592_, v1593_, v1594_ = g_currentMission.weedSystem:getDensityMapData()
		v1587_:addExecuteSet(0, DensityMapModifier.new(v1592_, v1593_, v1594_, g_terrainNode), v1588_)
		local v1595_, v1596_, v1597_ = g_currentMission.fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
		local v1598_ = DensityMapModifier.new(v1595_, v1596_, v1597_, g_terrainNode)
		local v1599_ = DensityMapFilter.new(v1595_, v1596_, v1597_)
		local v1600_ = FieldGroundType.getValueByType(FieldGroundType.SOWN)
		local v1601_ = FieldGroundType.getValueByType(FieldGroundType.HARVEST_READY)
		v1599_:setValueCompareParams(DensityValueCompareType.BETWEEN, v1600_, v1601_)
		v1587_:addExecuteSet(FieldGroundType.getValueByType(FieldGroundType.HARVEST_READY_OTHER), v1598_, v1588_, v1599_)
		v1585_.multiModifiers[perlinPercentage] = v1587_
	end
	densityMapArea:applyToModifier(v1587_)
	v1587_:execute()
end

-- Local values: tireTrackSystem
function FSDensityMapUtil.eraseTireTrack(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	local v1608_ = g_currentMission.tireTrackSystem
	if v1608_ ~= nil then
		v1608_:eraseParallelogram(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	end
end

-- Local values: functionData, fieldGroundSystem, groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, modifier, filter, terrainRootNode, accumulator, numMatchingPixels, totalNumPixels
function FSDensityMapUtil.getAreaDensity(id, firstChannel, numChannels, value, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	local v1619_ = FSDensityMapUtil.functionCache.getAreaDensity
	if v1619_ == nil then
		local v1620_, v1621_, v1622_ = g_currentMission.fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
		v1619_ = {
			["filter"] = DensityMapFilter.new(v1620_, v1621_, v1622_),
			["densityMapIdToModifier"] = {}
		}
		FSDensityMapUtil.functionCache.getAreaDensity = v1619_
	end
	local v1623_ = v1619_.densityMapIdToModifier[id]
	local v1624_ = v1619_.filter
	if v1623_ == nil then
		local v1625_ = g_terrainNode
		v1623_ = DensityMapModifier.new(id, firstChannel, numChannels, v1625_)
		v1619_.densityMapIdToModifier[id] = v1623_
	end
	v1623_:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	v1624_:setValueCompareParams(DensityValueCompareType.EQUAL, value)
	local v1626_, v1627_, v1628_ = v1623_:executeGet(v1624_)
	return v1626_, v1627_, v1628_
end

-- Local values: dataPlaneId, densityTypeIndex, desc, state, growthState
function FSDensityMapUtil.getFruitTypeIndexAtWorldPos(x, z)
	local v1631_ = g_fruitTypeManager:getDefaultDataPlaneId()
	if v1631_ ~= nil then
		local v1632_ = getDensityTypeIndexAtWorldPos(v1631_, x, 0, z)
		local v1633_ = g_fruitTypeManager:getFruitTypeByDensityTypeIndex(v1632_)
		if v1633_ ~= nil then
			local v1634_ = v1633_:getGrowthStateByDensityState((getDensityStatesAtWorldPos(v1631_, x, 0, z)))
			return v1633_.index, v1634_
		end
	end
	return nil
end

-- Local values: isOnField
function FSDensityMapUtil.getIsFieldAtWorldPos(x, z)
	return getDensityAtWorldPos(g_currentMission.terrainDetailId, x, 0, z) ~= 0
end

-- Local values: fieldGroundSystem, fieldTypeMapId, fieldTypeFirstChannel, fieldTypeNumChannels, width, height, terrainSize
function FSDensityMapUtil.getFieldTypeAtWorldPos(x, z)
	local v1639_, v1640_, v1641_ = g_currentMission.fieldGroundSystem:getDensityMapData(FieldDensityMap.FIELD_TYPE)
	local v1642_, v1643_ = getBitVectorMapSize(v1639_)
	local v1644_ = g_currentMission.terrainSize
	local v1645_ = v1642_ * (x + v1644_ * 0.5) / v1644_
	local v1646_ = math.floor(v1645_)
	local v1647_ = v1643_ * (z + v1644_ * 0.5) / v1644_
	local v1648_ = math.floor(v1647_)
	return getBitVectorMapPoint(v1639_, v1646_, v1648_, v1640_, v1641_) + 1
end

-- Local values: functionData, terrainRootNode, fieldGroundSystem, groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, modifier, filter, accumulator, numMatchingPixels, totalNumPixels
function FSDensityMapUtil.getFieldDensity(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	local v1655_ = FSDensityMapUtil.functionCache.getFieldDensity
	if v1655_ == nil then
		local v1656_ = g_terrainNode
		local v1657_, v1658_, v1659_ = g_currentMission.fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
		v1655_ = {
			["modifier"] = DensityMapModifier.new(v1657_, v1658_, v1659_, v1656_),
			["filter"] = DensityMapFilter.new(v1657_, v1658_, v1659_)
		}
		v1655_.filter:setValueCompareParams(DensityValueCompareType.GREATER, 0)
		FSDensityMapUtil.functionCache.getFieldDensity = v1655_
	end
	local v1660_ = v1655_.modifier
	local v1661_ = v1655_.filter
	v1660_:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	local v1662_, v1663_, v1664_ = v1660_:executeGet(v1661_)
	return v1662_, v1663_, v1664_
end

-- Local values: functionData, bushId, _, terrainRootNode, filter, modifier, filter, accumulator, numMatchingPixels, totalNumPixels
function FSDensityMapUtil.getBushDensity(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	local v1671_ = FSDensityMapUtil.functionCache.getBushDensity
	if v1671_ == nil then
		local v1672_, _ = getTerrainDataPlaneByName(g_terrainNode, "decoBush")
		if v1672_ == 0 then
			return 0, 0, 0
		end
		local v1673_ = g_terrainNode
		v1671_ = {
			["modifier"] = DensityMapModifier.new(v1672_, 0, 4, v1673_)
		}
		v1671_.modifier:setReturnValueShift(-1)
		local v1674_ = DensityMapFilter.new(v1672_, 0, 4)
		v1674_:setValueCompareParams(DensityValueCompareType.GREATER, 0)
		v1671_.filter = v1674_
		FSDensityMapUtil.functionCache.getBushDensity = v1671_
	end
	local v1675_ = v1671_.modifier
	local v1676_ = v1671_.filter
	v1675_:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	local v1677_, v1678_, v1679_ = v1675_:executeGet(v1676_)
	return v1677_, v1678_, v1679_
end

-- Local values: value
function FSDensityMapUtil.convertToDensityMapAngle(angle, maxDensityValue)
	local v1682_ = angle / 3.141592653589793 * (maxDensityValue + 1) + 0.5
	local v1683_ = math.floor(v1682_)
	while maxDensityValue < v1683_ do
		v1683_ = v1683_ - (maxDensityValue + 1)
	end
	while v1683_ < 0 do
		v1683_ = v1683_ + (maxDensityValue + 1)
	end
	return v1683_
end

-- Local values: weedFactor, weedSystem, functionData, terrainRootNode, fieldGroundSystem, groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, weedMapId, weedFirstChannel, weedNumChannels, factors, state, factor, filter, weedModifier, weedStateFilters, fieldFilter, _, pixels, totalPixels, fruitFilter, desc, filter, factor
function FSDensityMapUtil.getWeedFactor(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, fruitIndex)
	local v1691_ = 0
	local v1692_ = g_currentMission.weedSystem
	if v1692_:getMapHasWeed() then
		local v1693_ = FSDensityMapUtil.functionCache.getWeedFactor
		if v1693_ == nil then
			local v1694_ = g_terrainNode
			local v1695_, v1696_, v1697_ = g_currentMission.fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
			local v1698_, v1699_, v1700_ = v1692_:getDensityMapData()
			local v1701_ = v1692_:getFactors()
			v1693_ = {
				["weedModifier"] = DensityMapModifier.new(v1698_, v1699_, v1700_, v1694_),
				["fieldFilter"] = DensityMapFilter.new(v1695_, v1696_, v1697_)
			}
			v1693_.fieldFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)
			v1693_.fruitFilters = {}
			v1693_.weedStateFilters = {}
			for v1702_, v1703_ in pairs(v1701_) do
				local v1704_ = DensityMapFilter.new(v1698_, v1699_, v1700_)
				v1704_:setValueCompareParams(DensityValueCompareType.EQUAL, v1702_)
				v1693_.weedStateFilters[v1704_] = v1703_
			end
			FSDensityMapUtil.functionCache.getWeedFactor = v1693_
		end
		local v1705_ = v1693_.weedModifier
		local v1706_ = v1693_.weedStateFilters
		local v1707_ = v1693_.fieldFilter
		local v1708_
		if fruitIndex == nil then
			v1708_ = nil
		else
			v1708_ = v1693_.fruitFilters[fruitIndex]
			if v1708_ == nil then
				local v1709_ = g_fruitTypeManager:getFruitTypeByIndex(fruitIndex)
				v1708_ = DensityMapFilter.new(v1709_.terrainDataPlaneId, v1709_.startStateChannel, v1709_.numStateChannels)
				v1708_:setValueCompareParams(DensityValueCompareType.BETWEEN, v1709_.minForageGrowthState or v1709_.minHarvestingGrowthState, v1709_.maxHarvestingGrowthState)
				v1693_.fruitFilters[fruitIndex] = v1708_
			end
		end
		v1705_:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
		local _, v1710_, _ = v1705_:executeGet(v1707_, v1708_)
		if v1710_ ~= 0 then
			for v1711_, v1712_ in pairs(v1706_) do
				local _, v1713_, _ = v1705_:executeGet(v1711_, v1707_, v1708_)
				v1691_ = v1691_ + v1713_ / v1710_ * v1712_
			end
		end
	end
	return v1691_
end

function FSDensityMapUtil.assert(bool, warning)
	if FSDensityMapUtil.DEBUG_ENABLED then
		assert(bool, warning)
	end
end
function FSDensityMapUtil.runBenchmark()
	local v_u_1716_ = 128
	local v_u_1717_ = -128
	local v_u_1718_ = -128
	local v_u_1719_ = -128
	local v_u_1720_ = -128
	local v1721_ = {}
	table.insert(v1721_, {
		["name"] = "FSDensityMapUtil.updateRollerArea",
		["func"] = function()
			-- upvalues: (copy) v_u_1717_, (copy) v_u_1718_, (copy) v_u_1719_, (copy) v_u_1716_, (copy) v_u_1716_, (copy) v_u_1720_
			FSDensityMapUtil.updateRollerArea(-128, -128, -128, 128, 128, -128, 0)
		end
	})
	for _, v1722_ in ipairs(v1721_) do
		Logging.info("Benchmark-Start - %s - Size %dx%dm", v1722_.name, 128, 128)
		local v1723_ = 0
		for v1724_ = 1, 10 do
			local v1725_ = getTimeSec()
			v1722_.func()
			local v1726_ = (getTimeSec() - v1725_) * 1000
			v1723_ = v1723_ + v1726_
			Logging.info("    Run %d - Time: %.4fms", v1724_, v1726_)
		end
		Logging.info("Benchmark-Finished - Avg. Time: %.4fms", v1723_ / 10)
	end
end
