FSDensityMapUtil = {}
local old = DensityMapModifier.new
function DensityMapModifier.new(...)
	local modifier = old(...)
	modifier:setPolygonRoundingMode(DensityRoundingMode.INCLUSIVE)
	return modifier
end
FSDensityMapUtil.functionCache = {}
function FSDensityMapUtil.clearCache()
	FSDensityMapUtil.functionCache = {}
end
function FSDensityMapUtil.getFieldDataAtWorldPosition(x, y, z)
	local fieldGroundSystem = g_currentMission.fieldGroundSystem
	local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
	if groundTypeMapId == nil then
		return false, 0, 0
	else
		local densityBits = getDensityAtWorldPos(groundTypeMapId, x, y, z)
		local groundType = bit32.band(bit32.rshift(densityBits, groundTypeFirstChannel), 2 ^ groundTypeNumChannels - 1)
		local isOnField = groundType ~= 0
		return isOnField, densityBits, groundType
	end
end
function FSDensityMapUtil.cutFruitArea(fruitIndex, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, destroySpray, useMinForageState, excludedSprayType, setsWeeds, limitToField)
	local desc = g_fruitTypeManager:getFruitTypeByIndex(fruitIndex)
	if desc.terrainDataPlaneId == nil then
		return 0
	end
	local functionData = FSDensityMapUtil.functionCache.cutFruitArea
	if functionData == nil then
		local terrainRootNode = g_terrainNode
		local fieldGroundSystem = g_currentMission.fieldGroundSystem
		local sprayLevelMapId, sprayLevelFirstChannel, sprayLevelNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_LEVEL)
		local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
		functionData = {}
		functionData.fruitValueModifiers = {}
		functionData.fruitFilters = {}
		functionData.sownType = FieldGroundType.getValueByType(FieldGroundType.SOWN)
		functionData.groundTypeFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
		functionData.groundTypeFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)
		functionData.sprayLevelMaxValue = fieldGroundSystem:getMaxValue(FieldDensityMap.SPRAY_LEVEL)
		functionData.sprayLevelModifier = DensityMapModifier.new(sprayLevelMapId, sprayLevelFirstChannel, sprayLevelNumChannels, terrainRootNode)
		functionData.groundTypeModifier = DensityMapModifier.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, terrainRootNode)
		if Platform.gameplay.useRolling then
			local rollerLevelMapId, rollerLevelFirstChannel, rollerLevelNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.ROLLER_LEVEL)
			functionData.rollerLevelModifier = DensityMapModifier.new(rollerLevelMapId, rollerLevelFirstChannel, rollerLevelNumChannels, terrainRootNode)
			functionData.rollerLevelFilter = DensityMapFilter.new(rollerLevelMapId, rollerLevelFirstChannel, rollerLevelNumChannels)
			functionData.rollerLevelFilter:setValueCompareParams(DensityValueCompareType.EQUAL, 0)
		end
		if Platform.gameplay.usePlowCounter then
			local plowLevelMapId, plowLevelFirstChannel, plowLevelNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.PLOW_LEVEL)
			functionData.plowLevelModifier = DensityMapModifier.new(plowLevelMapId, plowLevelFirstChannel, plowLevelNumChannels, terrainRootNode)
			functionData.plowLevelFilter = DensityMapFilter.new(plowLevelMapId, plowLevelFirstChannel, plowLevelNumChannels)
			functionData.plowLevelFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)
		end
		if Platform.gameplay.useLimeCounter then
			local limeLevelMapId, limeLevelFirstChannel, limeLevelNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.LIME_LEVEL)
			functionData.limeLevelModifier = DensityMapModifier.new(limeLevelMapId, limeLevelFirstChannel, limeLevelNumChannels, terrainRootNode)
		end
		if Platform.gameplay.useStubbleShred then
			local stubbleShredLevelMapId, stubbleShredLevelFirstChannel, stubbleShredLevelNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.STUBBLE_SHRED_LEVEL)
			functionData.stubbleShredModifier = DensityMapModifier.new(stubbleShredLevelMapId, stubbleShredLevelFirstChannel, stubbleShredLevelNumChannels, terrainRootNode)
			functionData.stubbleShredFilter = DensityMapFilter.new(stubbleShredLevelMapId, stubbleShredLevelFirstChannel, stubbleShredLevelNumChannels)
			functionData.stubbleShredFilter:setValueCompareParams(DensityValueCompareType.EQUAL, 1)
		end
		FSDensityMapUtil.functionCache.cutFruitArea = functionData
	end
	local value = desc.cutState
	if value == 0 then
		return 0
	end
	local minState = desc.minHarvestingGrowthState
	if useMinForageState then
		minState = desc.minForageGrowthState
	end
	local sprayLevelModifier = functionData.sprayLevelModifier
	local plowLevelModifier = functionData.plowLevelModifier
	local plowLevelFilter = functionData.plowLevelFilter
	local groundTypeModifier = functionData.groundTypeModifier
	local sprayLevelMaxValue = functionData.sprayLevelMaxValue
	local fruitValueModifier = functionData.fruitValueModifiers[fruitIndex]
	local fruitFilter = functionData.fruitFilters[fruitIndex]
	if fruitValueModifier == nil then
		local terrainRootNode = g_terrainNode
		fruitValueModifier = DensityMapModifier.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels, terrainRootNode)
		fruitValueModifier:setReturnValueShift(-1)
		functionData.fruitValueModifiers[fruitIndex] = fruitValueModifier
		fruitFilter = DensityMapFilter.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)
		functionData.fruitFilters[fruitIndex] = fruitFilter
	end
	fruitFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, minState, desc.maxHarvestingGrowthState)
	fruitValueModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	local fruitArea, _, _ = fruitValueModifier:executeGet(fruitFilter)
	if fruitArea == 0 then
		return 0
	else
		sprayLevelModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
		groundTypeModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
		local sprayPixelsSum, _, _ = sprayLevelModifier:executeGet(fruitFilter)
		if destroySpray then
			FSDensityMapUtil.resetSprayArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, true, excludedSprayType)
			sprayLevelModifier:executeSet(0, fruitFilter)
		end
		if 0 < desc.startSprayLevel then
			sprayLevelModifier:executeSet(math.min(desc.startSprayLevel, sprayLevelMaxValue), fruitFilter, functionData.groundTypeFilter)
			FSDensityMapUtil.resetSprayArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, true, excludedSprayType)
		end
		local plowTotalDelta = 0
		local rollerTotalDelta = 0
		local limeTotalDelta = 0
		local stubbleTotalDelta = 0
		local weedFactor = 1
		local missionInfo = g_currentMission.missionInfo
		FSDensityMapUtil.removeWeedBlockingState(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
		if missionInfo.weedsEnabled then
			if desc.plantsWeed then
				weedFactor = 1 - FSDensityMapUtil.getWeedFactor(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, fruitIndex)
				FSDensityMapUtil.setSparseWeedArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
			else
				FSDensityMapUtil.removeWeedArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
			end
		end
		if Platform.gameplay.usePlowCounter then
			plowLevelModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
			if desc.lowSoilDensityRequired then
				_, plowTotalDelta, _ = plowLevelModifier:executeGet(fruitFilter, plowLevelFilter)
			end
			if desc.increasesSoilDensity and missionInfo.plowingRequiredEnabled then
				plowLevelModifier:executeAdd(-1, fruitFilter)
			end
		end
		if desc.needsRolling and Platform.gameplay.useRolling then
			local rollerLevelModifier = functionData.rollerLevelModifier
			local rollerLevelFilter = functionData.rollerLevelFilter
			rollerLevelModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
			_, rollerTotalDelta, _ = rollerLevelModifier:executeGet(fruitFilter, rollerLevelFilter)
		end
		if desc.consumesLime and (missionInfo.limeRequired and Platform.gameplay.useLimeCounter) then
			local limeLevelModifier = functionData.limeLevelModifier
			limeLevelModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
			_, _, limeTotalDelta, _ = limeLevelModifier:executeAddWithStats(-1, fruitFilter)
		end
		if Platform.gameplay.useStubbleShred then
			local stubbleShredModifier = functionData.stubbleShredModifier
			stubbleShredModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
			_, _, stubbleTotalDelta, _ = stubbleShredModifier:executeAddWithStats(-1, fruitFilter, functionData.stubbleShredFilter)
		end
		local terrainDetailPixelsSum, _, _ = groundTypeModifier:executeGet(fruitFilter)
		if desc.harvestGroundType ~= nil then
			fruitFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, minState, desc.maxHarvestingGrowthState)
			local groundValue = FieldGroundType.getValueByType(desc.harvestGroundType)
			groundTypeModifier:executeSet(groundValue, fruitFilter)
		end
		local groundTypeFilter = nil
		if limitToField then
			groundTypeFilter = functionData.groundTypeFilter
		end
		local numPixels = 0
		local totalNumPixels = 0
		local scaledPixels = 0
		local maxArea = 0
		local growthState = minState
		for src, target in pairs(desc.harvestTransitions) do
			if minState <= src and src <= desc.maxHarvestingGrowthState then
				fruitFilter:setValueCompareParams(DensityValueCompareType.EQUAL, src)
				local _, partialNumPixels, partialTotalNumPixels = fruitValueModifier:executeSetWithStats(target, fruitFilter, groundTypeFilter)
				local yieldScale = desc:getYieldScale(src)
				numPixels = numPixels + partialNumPixels
				scaledPixels = scaledPixels + partialNumPixels * yieldScale
				totalNumPixels = partialTotalNumPixels
				if maxArea < partialNumPixels then
					growthState = src
					maxArea = partialNumPixels
				end
			end
		end
		local plowFactor = 0
		local limeFactor = 0
		local sprayFactor = 0
		local stubbleFactor = 0
		local rollerFactor = 0
		local beeFactor = 0
		if 0 < numPixels then
			if desc.lowSoilDensityRequired then
				plowFactor = missionInfo.plowingRequiredEnabled and math.abs(plowTotalDelta) / numPixels or 1
			end
			if desc.needsRolling then
				rollerFactor = Platform.gameplay.useRolling and math.abs(rollerTotalDelta) / numPixels or 1
			end
			if desc.growthRequiresLime and missionInfo.limeRequired then
				limeFactor = Platform.gameplay.useLimeCounter and math.abs(limeTotalDelta) / numPixels or 1
			end
			sprayFactor = sprayPixelsSum / (numPixels * sprayLevelMaxValue)
			stubbleFactor = Platform.gameplay.useStubbleShred and math.abs(stubbleTotalDelta) / numPixels or 1
			if desc.beeYieldBonusPercentage ~= 0 then
				beeFactor = g_currentMission.beehiveSystem:getBeehiveInfluenceFactorAt(startWorldX, startWorldZ) * desc.beeYieldBonusPercentage
			end
		end
		return scaledPixels, totalNumPixels, sprayFactor, plowFactor, limeFactor, weedFactor, stubbleFactor, rollerFactor, beeFactor, growthState, maxArea, terrainDetailPixelsSum
	end
end
function FSDensityMapUtil.getFruitArea(fruitIndex, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, allowPreparing, useMinForageState)
	local desc = g_fruitTypeManager:getFruitTypeByIndex(fruitIndex)
	if desc.terrainDataPlaneId == nil then
		return 0, 0
	else
		local functionData = FSDensityMapUtil.functionCache.getFruitArea
		if functionData == nil then
			functionData = {}
			functionData.fruitModifiers = {}
			functionData.fruitFilter = {}
			FSDensityMapUtil.functionCache.getFruitArea = functionData
		end
		local fruitModifier = functionData.fruitModifiers[fruitIndex]
		if fruitModifier == nil then
			local terrainRootNode = g_terrainNode
			fruitModifier = DensityMapModifier.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels, terrainRootNode)
			fruitModifier:setReturnValueShift(-1)
			functionData.fruitModifiers[fruitIndex] = fruitModifier
			functionData.fruitFilter[fruitIndex] = DensityMapFilter.new(fruitModifier)
		end
		local fruitFilter = functionData.fruitFilter[fruitIndex]
		local minState = desc.minHarvestingGrowthState
		if useMinForageState then
			minState = desc.minForageGrowthState
		end
		fruitModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
		fruitFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, minState, desc.maxHarvestingGrowthState)
		local ret, numPixels, totalNumPixels = fruitModifier:executeGet(fruitFilter)
		if allowPreparing and (0 <= desc.minPreparingGrowthState and 0 <= desc.maxPreparingGrowthState) then
			fruitFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, desc.minPreparingGrowthState, desc.maxPreparingGrowthState)
			local ret2, numPixels2, totalNumPixels2 = fruitModifier:executeGet(fruitFilter)
			ret = ret + ret2
			numPixels = numPixels + numPixels2
			totalNumPixels = totalNumPixels + totalNumPixels2
		end
		local maxArea = 0
		local growthState = minState
		for i = minState, desc.maxHarvestingGrowthState do
			fruitFilter:setValueCompareParams(DensityValueCompareType.EQUAL, i)
			local _, area = fruitModifier:executeGet(fruitFilter)
			if maxArea < area then
				growthState = i
				maxArea = area
			end
		end
		return ret, numPixels, totalNumPixels, growthState
	end
end
function FSDensityMapUtil.updateRollerArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, angle)
	if not Platform.gameplay.useRolling then
		return 0
	else
		angle = angle or 0
		local functionData = FSDensityMapUtil.functionCache.updateRollerArea
		if functionData == nil then
			functionData = {}
			functionData.multiModifiers = {}
			functionData.numChangedPixels = {}
			FSDensityMapUtil.functionCache.updateRollerArea = functionData
		end
		local label = "rolled"
		local multiModifier = functionData.multiModifiers[angle]
		if multiModifier == nil then
			local terrainRootNode = g_terrainNode
			local fieldGroundSystem = g_currentMission.fieldGroundSystem
			local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
			local groundAngleMapId, groundAngleFirstChannel, groundAngleNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_ANGLE)
			local rollerLevelMapId, rollerLevelFirstChannel, rollerLevelNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.ROLLER_LEVEL)
			local rolledSeedbedType = FieldGroundType.getValueByType(FieldGroundType.ROLLED_SEEDBED)
			local rollerLinesType = FieldGroundType.getValueByType(FieldGroundType.ROLLER_LINES)
			local firstSowableValue, lastSowableValue = fieldGroundSystem:getSowableRange()
			local firstSowingValue, lastSowingValue = fieldGroundSystem:getSowingRange()
			local rollerLevelModifier = DensityMapModifier.new(rollerLevelMapId, rollerLevelFirstChannel, rollerLevelNumChannels, terrainRootNode)
			local groundTypeModifier = DensityMapModifier.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, terrainRootNode)
			local groundTypeAngleModifier = DensityMapModifier.new(groundAngleMapId, groundAngleFirstChannel, groundAngleNumChannels, terrainRootNode)
			local rollerLevelFilter = DensityMapFilter.new(rollerLevelMapId, rollerLevelFirstChannel, rollerLevelNumChannels)
			rollerLevelFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)
			local sownFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
			sownFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, firstSowingValue, lastSowingValue)
			local sowableFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
			sowableFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, firstSowableValue, lastSowableValue)
			local rollerLinesFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
			rollerLinesFilter:setValueCompareParams(DensityValueCompareType.EQUAL, rollerLinesType)
			local rolledSeedbedFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
			rolledSeedbedFilter:setValueCompareParams(DensityValueCompareType.EQUAL, rolledSeedbedType)
			local stoneModifier = nil
			local stoneFilter = nil
			local stoneSystem = g_currentMission.stoneSystem
			if stoneSystem:getMapHasStones() then
				local stoneMapId, stoneFirstChannel, stoneNumChannels = stoneSystem:getDensityMapData()
				local stoneMinValue = stoneSystem:getMinMaxValues()
				stoneModifier = DensityMapModifier.new(stoneMapId, stoneFirstChannel, stoneNumChannels, terrainRootNode)
				stoneModifier:setPolygonRoundingMode(DensityRoundingMode.NEAREST)
				stoneFilter = DensityMapFilter.new(stoneMapId, stoneFirstChannel, stoneNumChannels)
				stoneFilter:setValueCompareParams(DensityValueCompareType.EQUAL, stoneMinValue)
			end
			multiModifier = DensityMapMultiModifier.new()
			for _, desc in pairs(g_fruitTypeManager:getFruitTypes()) do
				if desc.terrainDataPlaneId == nil then
					continue
				end
				local firstGrowthStateFilter = DensityMapFilter.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)
				firstGrowthStateFilter:setValueCompareParams(DensityValueCompareType.EQUAL, 1)
				if stoneModifier ~= nil then
					multiModifier:addExecuteAdd(-1, stoneModifier, stoneFilter, sownFilter, firstGrowthStateFilter)
				end
				multiModifier:addExecuteSetWithStats("rolled", 0, rollerLevelModifier, rollerLevelFilter, sownFilter, firstGrowthStateFilter)
				multiModifier:addExecuteSet(rollerLinesType, groundTypeModifier, sownFilter, firstGrowthStateFilter)
				multiModifier:addExecuteSet(angle, groundTypeAngleModifier, rollerLinesFilter, firstGrowthStateFilter)
			end
			if stoneModifier ~= nil then
				multiModifier:addExecuteAdd(-1, stoneModifier, stoneFilter)
			end
			multiModifier:addExecuteSetWithStats("rolled", 0, rollerLevelModifier, rollerLevelFilter, sowableFilter)
			multiModifier:addExecuteSet(rolledSeedbedType, groundTypeModifier, sowableFilter)
			multiModifier:addExecuteSet(angle, groundTypeAngleModifier, rolledSeedbedFilter)
			FSDensityMapUtil.multiModifierAddResetDisplacement(multiModifier)
			functionData.multiModifiers[angle] = multiModifier
		end
		local numChangedPixels = functionData.numChangedPixels
		multiModifier:updateParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
		multiModifier:resetStats()
		multiModifier:execute(nil, numChangedPixels, nil)
		return numChangedPixels.rolled
	end
end
function FSDensityMapUtil.updateGrassRollerArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, removeStones)
	local functionData = FSDensityMapUtil.functionCache.updateGrassRollerArea
	if functionData == nil then
		local terrainRootNode = g_terrainNode
		local fieldGroundSystem = g_currentMission.fieldGroundSystem
		local sprayLevelMapId, sprayLevelFirstChannel, sprayLevelNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_LEVEL)
		local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
		local sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_TYPE)
		local sprayType = FieldSprayType.getValueByType(FieldSprayType.FERTILIZER)
		local sprayTypeMaxValue = fieldGroundSystem:getMaxValue(FieldDensityMap.SPRAY_TYPE)
		local sprayLevelMaxValue = fieldGroundSystem:getMaxValue(FieldDensityMap.SPRAY_LEVEL)
		local grassDesc = g_fruitTypeManager:getFruitTypeByIndex(FruitType.GRASS)
		local meadowDesc = g_fruitTypeManager:getFruitTypeByIndex(FruitType.MEADOW)
		functionData = {}
		functionData.grassModifier = DensityMapModifier.new(grassDesc.terrainDataPlaneId, grassDesc.startStateChannel, grassDesc.numStateChannels, terrainRootNode)
		functionData.grassFilter = DensityMapFilter.new(grassDesc.terrainDataPlaneId, grassDesc.startStateChannel, grassDesc.numStateChannels)
		functionData.grassFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, 2, grassDesc.cutState)
		functionData.grassFilterFirstStage = DensityMapFilter.new(grassDesc.terrainDataPlaneId, grassDesc.startStateChannel, grassDesc.numStateChannels)
		functionData.grassFilterFirstStage:setValueCompareParams(DensityValueCompareType.BETWEEN, 3, grassDesc.cutState - 1)
		functionData.grassFilterRolledStage = DensityMapFilter.new(grassDesc.terrainDataPlaneId, grassDesc.startStateChannel, grassDesc.numStateChannels)
		functionData.grassFilterRolledStage:setValueCompareParams(DensityValueCompareType.BETWEEN, 3, grassDesc.cutState)
		functionData.grassRolledCutState = grassDesc.rolledCutState
		if meadowDesc ~= nil and meadowDesc.terrainDataPlaneId ~= nil then
			functionData.meadowModifier = DensityMapModifier.new(meadowDesc.terrainDataPlaneId, meadowDesc.startStateChannel, meadowDesc.numStateChannels, terrainRootNode)
			functionData.meadowFilter = DensityMapFilter.new(meadowDesc.terrainDataPlaneId, meadowDesc.startStateChannel, meadowDesc.numStateChannels)
			functionData.meadowFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, 2, grassDesc.cutState)
			functionData.meadowFilterFirstStage = DensityMapFilter.new(meadowDesc.terrainDataPlaneId, meadowDesc.startStateChannel, meadowDesc.numStateChannels)
			functionData.meadowFilterFirstStage:setValueCompareParams(DensityValueCompareType.BETWEEN, 3, meadowDesc.cutState - 1)
			functionData.meadowFilterRolledStage = DensityMapFilter.new(meadowDesc.terrainDataPlaneId, meadowDesc.startStateChannel, meadowDesc.numStateChannels)
			functionData.meadowFilterRolledStage:setValueCompareParams(DensityValueCompareType.BETWEEN, 3, meadowDesc.cutState)
			functionData.meadowRolledCutState = meadowDesc.rolledCutState
			functionData.noMeadowVisibleFilter = DensityMapFilter.new(meadowDesc.terrainDataPlaneId, meadowDesc.startStateChannel, meadowDesc.numStateChannels)
			functionData.noMeadowVisibleFilter:setValueCompareParams(DensityValueCompareType.EQUAL, 0)
		end
		functionData.sprayTypeModifier = DensityMapModifier.new(sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels, terrainRootNode)
		functionData.sprayLevelModifier = DensityMapModifier.new(sprayLevelMapId, sprayLevelFirstChannel, sprayLevelNumChannels, terrainRootNode)
		functionData.outsideFieldFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
		functionData.outsideFieldFilter:setValueCompareParams(DensityValueCompareType.EQUAL, 0)
		functionData.noGrassVisibleFilter = DensityMapFilter.new(grassDesc.terrainDataPlaneId, grassDesc.startStateChannel, grassDesc.numStateChannels)
		functionData.noGrassVisibleFilter:setValueCompareParams(DensityValueCompareType.EQUAL, 0)
		functionData.sprayTypeFilter = DensityMapFilter.new(sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels)
		functionData.sprayTypeFilter:setValueCompareParams(DensityValueCompareType.GREATER, sprayType)
		if 0 < sprayType then
			functionData.sprayTypeFilter2 = DensityMapFilter.new(sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels)
			functionData.sprayTypeFilter2:setValueCompareParams(DensityValueCompareType.BETWEEN, 0, sprayType - 1)
		end
		functionData.notMaxSprayLevelFilter = DensityMapFilter.new(sprayLevelMapId, sprayLevelFirstChannel, sprayLevelNumChannels)
		functionData.notMaxSprayLevelFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, 0, sprayLevelMaxValue - 1)
		functionData.areaMaskedFilter = DensityMapFilter.new(sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels)
		functionData.areaMaskedFilter:setValueCompareParams(DensityValueCompareType.EQUAL, sprayTypeMaxValue)
		functionData.sprayType = sprayType
		functionData.maskValue = sprayTypeMaxValue
		local stoneSystem = g_currentMission.stoneSystem
		if stoneSystem:getMapHasStones() then
			local stoneMapId, stoneFirstChannel, stoneNumChannels = stoneSystem:getDensityMapData()
			local stoneMinValue = stoneSystem:getMinMaxValues()
			functionData.stoneModifier = DensityMapModifier.new(stoneMapId, stoneFirstChannel, stoneNumChannels, terrainRootNode)
			functionData.stoneModifier:setPolygonRoundingMode(DensityRoundingMode.NEAREST)
			functionData.stoneFilter = DensityMapFilter.new(stoneMapId, stoneFirstChannel, stoneNumChannels)
			functionData.stoneFilter:setValueCompareParams(DensityValueCompareType.EQUAL, stoneMinValue)
		end
		FSDensityMapUtil.functionCache.updateGrassRollerArea = functionData
	end
	local grassModifier = functionData.grassModifier
	local grassFilter = functionData.grassFilter
	local grassFilterFirstStage = functionData.grassFilterFirstStage
	local grassFilterRolledStage = functionData.grassFilterRolledStage
	local grassRolledCutState = functionData.grassRolledCutState
	local meadowModifier = functionData.meadowModifier
	local meadowFilter = functionData.meadowFilter
	local meadowFilterFirstStage = functionData.meadowFilterFirstStage
	local meadowFilterRolledStage = functionData.meadowFilterRolledStage
	local meadowRolledCutState = functionData.meadowRolledCutState
	local sprayLevelModifier = functionData.sprayLevelModifier
	local sprayTypeModifier = functionData.sprayTypeModifier
	local stoneModifier = functionData.stoneModifier
	local stoneFilter = functionData.stoneFilter
	local outsideFieldFilter = functionData.outsideFieldFilter
	local noGrassVisibleFilter = functionData.noGrassVisibleFilter
	local noMeadowVisibleFilter = functionData.noMeadowVisibleFilter
	local sprayTypeFilter = functionData.sprayTypeFilter
	local sprayTypeFilter2 = functionData.sprayTypeFilter2
	local notMaxSprayLevelFilter = functionData.notMaxSprayLevelFilter
	local areaMaskedFilter = functionData.areaMaskedFilter
	local sprayType = functionData.sprayType
	local maskValue = functionData.maskValue
	grassModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	if meadowModifier ~= nil then
		meadowModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	end
	sprayLevelModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	sprayTypeModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	if removeStones ~= false and stoneModifier ~= nil then
		stoneModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	end
	sprayTypeModifier:executeSet(maskValue, grassFilter, sprayTypeFilter, notMaxSprayLevelFilter)
	if sprayTypeFilter2 ~= nil then
		sprayTypeModifier:executeSet(maskValue, grassFilter, sprayTypeFilter2, notMaxSprayLevelFilter)
	end
	if meadowFilter ~= nil then
		sprayTypeModifier:executeSet(maskValue, meadowFilter, sprayTypeFilter, notMaxSprayLevelFilter)
		if sprayTypeFilter2 ~= nil then
			sprayTypeModifier:executeSet(maskValue, meadowFilter, sprayTypeFilter2, notMaxSprayLevelFilter)
		end
	end
	sprayTypeModifier:executeSet(0, areaMaskedFilter, outsideFieldFilter)
	sprayTypeModifier:executeSet(0, areaMaskedFilter, noGrassVisibleFilter, noMeadowVisibleFilter)
	local _, _, numPixels, totalNumPixels = sprayLevelModifier:executeAddWithStats(1, areaMaskedFilter)
	sprayTypeModifier:executeSet(sprayType, areaMaskedFilter)
	grassModifier:executeSet(2, grassFilterFirstStage)
	if grassRolledCutState ~= 0 then
		grassModifier:executeSet(grassRolledCutState, grassFilterRolledStage)
	end
	if meadowModifier ~= nil then
		meadowModifier:executeSet(2, meadowFilterFirstStage)
		if meadowRolledCutState ~= 0 then
			meadowModifier:executeSet(meadowRolledCutState, meadowFilterRolledStage)
		end
	end
	if removeStones ~= false and stoneModifier ~= nil then
		stoneModifier:executeAdd(-1, stoneFilter)
	end
	DensityMapHeightUtil.clearArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	return numPixels, totalNumPixels
end
function FSDensityMapUtil.addStoneArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, delta, fieldFilter, customFilter)
	local stoneSystem = g_currentMission.stoneSystem
	if not stoneSystem:getMapHasStones() then
		return
	else
		local functionData = FSDensityMapUtil.functionCache.addStoneArea
		if functionData == nil then
			local terrainRootNode = g_terrainNode
			local stoneMapId, stoneFirstChannel, stoneNumChannels = stoneSystem:getDensityMapData()
			local _, stoneMaxValue = stoneSystem:getMinMaxValues()
			local stoneMaskValue = stoneSystem:getMaskValue()
			functionData = {}
			functionData.stoneModifier = DensityMapModifier.new(stoneMapId, stoneFirstChannel, stoneNumChannels, terrainRootNode)
			functionData.stoneFilter = DensityMapFilter.new(stoneMapId, stoneFirstChannel, stoneNumChannels)
			functionData.stoneFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, stoneMaskValue, stoneMaxValue - 1)
			functionData.stoneMaxReachedFilter = DensityMapFilter.new(stoneMapId, stoneFirstChannel, stoneNumChannels)
			functionData.stoneMaxReachedFilter:setValueCompareParams(DensityValueCompareType.GREATER, stoneMaxValue)
			functionData.stoneMaxValue = stoneMaxValue
			FSDensityMapUtil.functionCache.addStoneArea = functionData
		end
		local stoneModifier = functionData.stoneModifier
		local stoneFilter = functionData.stoneFilter
		local stoneMaxReachedFilter = functionData.stoneMaxReachedFilter
		local stoneMaxValue = functionData.stoneMaxValue
		stoneModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
		if fieldFilter == nil then
			stoneModifier:executeAdd(delta, stoneFilter, customFilter)
		else
			stoneModifier:executeAdd(delta, stoneFilter, fieldFilter, customFilter)
		end
		stoneModifier:executeSet(stoneMaxValue, stoneMaxReachedFilter)
	end
end
function FSDensityMapUtil.removeStoneArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	local numPixels = 0
	local totalNumPixels = 0
	local stoneSystem = g_currentMission.stoneSystem
	if stoneSystem:getMapHasStones() then
		local functionData = FSDensityMapUtil.functionCache.removeStoneArea
		if functionData == nil then
			local terrainRootNode = g_terrainNode
			local stoneMapId, stoneFirstChannel, stoneNumChannels = stoneSystem:getDensityMapData()
			functionData = {}
			functionData.stoneModifier = DensityMapModifier.new(stoneMapId, stoneFirstChannel, stoneNumChannels, terrainRootNode)
			FSDensityMapUtil.functionCache.removeStoneArea = functionData
		end
		local stoneModifier = functionData.stoneModifier
		stoneModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
		local _ = nil
		_, numPixels, totalNumPixels = stoneModifier:executeSetWithStats(0)
	end
	return numPixels, totalNumPixels
end
function FSDensityMapUtil.getStoneArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	local stoneSystem = g_currentMission.stoneSystem
	if not stoneSystem:getMapHasStones() then
		return
	else
		local functionData = FSDensityMapUtil.functionCache.getStoneArea
		if functionData == nil then
			local terrainRootNode = g_terrainNode
			local stoneMapId, stoneFirstChannel, stoneNumChannels = stoneSystem:getDensityMapData()
			local stoneMinValue, stoneMaxValue = stoneSystem:getMinMaxValues()
			functionData = {}
			functionData.stoneModifier = DensityMapModifier.new(stoneMapId, stoneFirstChannel, stoneNumChannels, terrainRootNode)
			functionData.stoneFilters = {}
			for i = 0, stoneMaxValue - stoneMinValue do
				local stoneFilter = DensityMapFilter.new(stoneMapId, stoneFirstChannel, stoneNumChannels)
				stoneFilter:setValueCompareParams(DensityValueCompareType.EQUAL, stoneMinValue + i)
				table.insert(functionData.stoneFilters, stoneFilter)
			end
			FSDensityMapUtil.functionCache.getStoneArea = functionData
		end
		local stoneModifier = functionData.stoneModifier
		stoneModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
		for i = #functionData.stoneFilters, 1, -1 do
			local area, _ = stoneModifier:executeGet(functionData.stoneFilters[i])
			if 0 < area then
				return i
			end
		end
		return 0
	end
end
function FSDensityMapUtil.updateStonePickerArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, angle)
	local stoneSystem = g_currentMission.stoneSystem
	if not stoneSystem:getMapHasStones() then
		return 0, 0, 0
	else
		local functionData = FSDensityMapUtil.functionCache.updateStonePickerArea
		if functionData == nil then
			local terrainRootNode = g_terrainNode
			local fieldGroundSystem = g_currentMission.fieldGroundSystem
			local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
			local groundAngleMapId, groundAngleFirstChannel, groundAngleNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_ANGLE)
			local sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_TYPE)
			local stoneMapId, stoneFirstChannel, stoneNumChannels = stoneSystem:getDensityMapData()
			local stoneMinValue, stoneMaxValue = stoneSystem:getMinMaxValues()
			local cultivatedType = FieldGroundType.getValueByType(FieldGroundType.CULTIVATED)
			local firstSowableValue, lastSowableValue = fieldGroundSystem:getSowableRange()
			local pickedValue = stoneSystem:getPickedValue()
			functionData = {}
			functionData.stoneModifier = DensityMapModifier.new(stoneMapId, stoneFirstChannel, stoneNumChannels, terrainRootNode)
			functionData.stoneFilter = DensityMapFilter.new(stoneMapId, stoneFirstChannel, stoneNumChannels)
			functionData.stoneFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, stoneMinValue, stoneMaxValue)
			functionData.sowableFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
			functionData.sowableFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, firstSowableValue, lastSowableValue)
			functionData.groundTypeModifier = DensityMapModifier.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, terrainRootNode)
			functionData.groundAngleModifier = DensityMapModifier.new(groundAngleMapId, groundAngleFirstChannel, groundAngleNumChannels, terrainRootNode)
			functionData.stoneMinValue = stoneMinValue
			functionData.cultivatedType = cultivatedType
			functionData.pickedValue = pickedValue
			functionData.sprayTypeModifier = DensityMapModifier.new(sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels, terrainRootNode)
			FSDensityMapUtil.functionCache.updateStonePickerArea = functionData
		end
		local stoneModifier = functionData.stoneModifier
		local stoneFilter = functionData.stoneFilter
		local sowableFilter = functionData.sowableFilter
		local groundTypeModifier = functionData.groundTypeModifier
		local groundAngleModifier = functionData.groundAngleModifier
		local stoneMinValue = functionData.stoneMinValue
		local cultivatedType = functionData.cultivatedType
		local pickedValue = functionData.pickedValue
		local sprayTypeModifier = functionData.sprayTypeModifier
		angle = angle or 0
		groundTypeModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
		groundAngleModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
		stoneModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
		sprayTypeModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
		local density, area, totalArea = stoneModifier:executeSetWithStats(pickedValue, stoneFilter, sowableFilter)
		groundTypeModifier:executeSet(cultivatedType, sowableFilter)
		groundAngleModifier:executeSet(angle, sowableFilter)
		sprayTypeModifier:executeSet(0, sowableFilter)
		FSDensityMapUtil.resetDisplacementArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, sowableFilter)
		density = math.max(0, density - area * (stoneMinValue - 1))
		local stoneFactor = 0
		if 0 < area then
			stoneFactor = density / area
		end
		return stoneFactor, area, totalArea
	end
end
function FSDensityMapUtil.removeFieldArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, deleteAll)
	local functionData = FSDensityMapUtil.functionCache.removeFieldArea
	if functionData == nil then
		local terrainRootNode = g_terrainNode
		local fieldGroundSystem = g_currentMission.fieldGroundSystem
		local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
		local sprayLevelMapId, sprayLevelFirstChannel, sprayLevelNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_LEVEL)
		local groundAngleMapId, groundAngleFirstChannel, groundAngleNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_ANGLE)
		local sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_TYPE)
		functionData = {}
		local removeFieldMultiModifier = DensityMapMultiModifier.new()
		local clearFieldModifier = DensityMapModifier.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, terrainRootNode)
		removeFieldMultiModifier:addExecuteSet(0, clearFieldModifier)
		local clearSprayModifier = DensityMapModifier.new(sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels, terrainRootNode)
		removeFieldMultiModifier:addExecuteSet(0, clearSprayModifier)
		local clearSprayLeveldModifier = DensityMapModifier.new(sprayLevelMapId, sprayLevelFirstChannel, sprayLevelNumChannels, terrainRootNode)
		removeFieldMultiModifier:addExecuteSet(0, clearSprayLeveldModifier)
		local clearAngleModifier = DensityMapModifier.new(groundAngleMapId, groundAngleFirstChannel, groundAngleNumChannels, terrainRootNode)
		removeFieldMultiModifier:addExecuteSet(0, clearAngleModifier)
		if Platform.gameplay.usePlowCounter then
			local plowLevelMapId, plowLevelFirstChannel, plowLevelNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.PLOW_LEVEL)
			local clearPlowLevelModifier = DensityMapModifier.new(plowLevelMapId, plowLevelFirstChannel, plowLevelNumChannels, terrainRootNode)
			removeFieldMultiModifier:addExecuteSet(0, clearPlowLevelModifier)
		end
		if Platform.gameplay.useLimeCounter then
			local limeLevelMapId, limeLevelFirstChannel, limeLevelNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.LIME_LEVEL)
			local clearLimeLevelModifier = DensityMapModifier.new(limeLevelMapId, limeLevelFirstChannel, limeLevelNumChannels, terrainRootNode)
			removeFieldMultiModifier:addExecuteSet(0, clearLimeLevelModifier)
		end
		for _, desc in pairs(g_fruitTypeManager:getFruitTypes()) do
			if desc.terrainDataPlaneId == nil then
				continue
			end
			if deleteAll or desc.isCultivationAllowed then
				local clearFruitModifier = DensityMapModifier.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels, terrainRootNode)
				clearFruitModifier:setNewTypeIndexMode(DensityIndexCompareMode.ZERO)
				removeFieldMultiModifier:addExecuteSet(0, clearFruitModifier)
			end
		end
		for i = 1, #g_currentMission.dynamicFoliageLayers do
			local id = g_currentMission.dynamicFoliageLayers[i]
			local numChannels = getTerrainDetailNumChannels(id)
			local clearDynamicFoliageLayerModifier = DensityMapModifier.new(id, 0, numChannels, terrainRootNode)
			removeFieldMultiModifier:addExecuteSet(0, clearDynamicFoliageLayerModifier)
		end
		functionData.removeFieldMultiModifier = removeFieldMultiModifier
		FSDensityMapUtil.functionCache.removeFieldArea = functionData
	end
	local removeFieldMultiModifier = functionData.removeFieldMultiModifier
	removeFieldMultiModifier:updateParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	removeFieldMultiModifier:execute()
end
function FSDensityMapUtil.removeFieldPolygon(polygonVertices, deleteAll)
	local functionData = FSDensityMapUtil.functionCache.removeFieldArea
	if functionData == nil then
		local terrainRootNode = g_terrainNode
		local fieldGroundSystem = g_currentMission.fieldGroundSystem
		local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
		local sprayLevelMapId, sprayLevelFirstChannel, sprayLevelNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_LEVEL)
		local groundAngleMapId, groundAngleFirstChannel, groundAngleNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_ANGLE)
		local sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_TYPE)
		functionData = {}
		local removeFieldMultiModifier = DensityMapMultiModifier.new()
		local clearFieldModifier = DensityMapModifier.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, terrainRootNode)
		removeFieldMultiModifier:addExecuteSet(0, clearFieldModifier)
		local clearSprayModifier = DensityMapModifier.new(sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels, terrainRootNode)
		removeFieldMultiModifier:addExecuteSet(0, clearSprayModifier)
		local clearSprayLeveldModifier = DensityMapModifier.new(sprayLevelMapId, sprayLevelFirstChannel, sprayLevelNumChannels, terrainRootNode)
		removeFieldMultiModifier:addExecuteSet(0, clearSprayLeveldModifier)
		local clearAngleModifier = DensityMapModifier.new(groundAngleMapId, groundAngleFirstChannel, groundAngleNumChannels, terrainRootNode)
		removeFieldMultiModifier:addExecuteSet(0, clearAngleModifier)
		if Platform.gameplay.usePlowCounter then
			local plowLevelMapId, plowLevelFirstChannel, plowLevelNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.PLOW_LEVEL)
			local clearPlowLevelModifier = DensityMapModifier.new(plowLevelMapId, plowLevelFirstChannel, plowLevelNumChannels, terrainRootNode)
			removeFieldMultiModifier:addExecuteSet(0, clearPlowLevelModifier)
		end
		if Platform.gameplay.useLimeCounter then
			local limeLevelMapId, limeLevelFirstChannel, limeLevelNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.LIME_LEVEL)
			local clearLimeLevelModifier = DensityMapModifier.new(limeLevelMapId, limeLevelFirstChannel, limeLevelNumChannels, terrainRootNode)
			removeFieldMultiModifier:addExecuteSet(0, clearLimeLevelModifier)
		end
		for _, desc in pairs(g_fruitTypeManager:getFruitTypes()) do
			if desc.terrainDataPlaneId == nil then
				continue
			end
			if deleteAll or desc.isCultivationAllowed then
				local clearFruitModifier = DensityMapModifier.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels, terrainRootNode)
				clearFruitModifier:setNewTypeIndexMode(DensityIndexCompareMode.ZERO)
				removeFieldMultiModifier:addExecuteSet(0, clearFruitModifier)
			end
		end
		for i = 1, #g_currentMission.dynamicFoliageLayers do
			local id = g_currentMission.dynamicFoliageLayers[i]
			local numChannels = getTerrainDetailNumChannels(id)
			local clearDynamicFoliageLayerModifier = DensityMapModifier.new(id, 0, numChannels, terrainRootNode)
			removeFieldMultiModifier:addExecuteSet(0, clearDynamicFoliageLayerModifier)
		end
		functionData.removeFieldMultiModifier = removeFieldMultiModifier
		FSDensityMapUtil.functionCache.removeFieldArea = functionData
	end
	local removeFieldMultiModifier = functionData.removeFieldMultiModifier
	for i = 1, #polygonVertices, 2 do
		removeFieldMultiModifier:addPolygonPointWorldCoords(polygonVertices[i], polygonVertices[i + 1])
	end
	removeFieldMultiModifier:execute()
	removeFieldMultiModifier:clearPolygonPoints()
end
function FSDensityMapUtil.updateCultivatorArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, createField, limitFruitDestructionToField, angle, blockedSprayTypeIndex, setsWeeds, disableStones)
	local functionData = FSDensityMapUtil.functionCache.updateCultivatorArea
	local missionInfo = g_currentMission.missionInfo
	if functionData == nil then
		local terrainRootNode = g_terrainNode
		local fieldGroundSystem = g_currentMission.fieldGroundSystem
		local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
		local groundAngleMapId, groundAngleFirstChannel, groundAngleNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_ANGLE)
		local cultivatedType = FieldGroundType.getValueByType(FieldGroundType.CULTIVATED)
		functionData = {}
		functionData.modifier = DensityMapModifier.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, terrainRootNode)
		functionData.modifierAngle = DensityMapModifier.new(groundAngleMapId, groundAngleFirstChannel, groundAngleNumChannels, terrainRootNode)
		functionData.filterCultivatorArea = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
		functionData.filterCultivatorArea:setValueCompareParams(DensityValueCompareType.EQUAL, cultivatedType)
		functionData.filterField = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
		functionData.filterField:setValueCompareParams(DensityValueCompareType.GREATER, 0)
		functionData.notCultivatedFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
		functionData.notCultivatedFilter:setValueCompareParams(DensityValueCompareType.NOTEQUAL, cultivatedType)
		functionData.cultivatedType = cultivatedType
		functionData.noFruitFilter = nil
		for _, desc in pairs(g_fruitTypeManager:getFruitTypes()) do
			if desc.terrainDataPlaneId ~= nil then
				functionData.noFruitFilter = DensityMapFilter.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)
				functionData.noFruitFilter:setValueCompareParams(DensityValueCompareType.EQUAL, 0)
				functionData.noFruitFilter:setTypeIndexCompareMode(DensityTypeCompareType.ALWAYS)
				break
			end
		end
		FSDensityMapUtil.functionCache.updateCultivatorArea = functionData
	end
	local modifier = functionData.modifier
	local modifierAngle = functionData.modifierAngle
	local filterCultivatorArea = functionData.filterCultivatorArea
	local filterField = functionData.filterField
	local notCultivatedFilter = functionData.notCultivatedFilter
	local cultivatedType = functionData.cultivatedType
	local noFruitFilter = functionData.noFruitFilter
	createField = Utils.getNoNil(createField, true)
	limitFruitDestructionToField = Utils.getNoNil(limitFruitDestructionToField, true)
	angle = angle or 0
	FSDensityMapUtil.updateDestroyCommonArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, limitFruitDestructionToField, false)
	modifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	modifierAngle:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	local _, areaBefore, _ = modifier:executeGet(filterCultivatorArea)
	FSDensityMapUtil.removeSprayArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, blockedSprayTypeIndex)
	local totalArea = nil
	local changedArea = nil
	if createField then
		filterField = nil
	end
	if missionInfo.stonesEnabled and disableStones ~= true then
		FSDensityMapUtil.addStoneArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, 1, filterField, notCultivatedFilter)
	end
	if missionInfo.weedsEnabled then
		FSDensityMapUtil.setSparseWeedArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	end
	_, _, totalArea = modifier:executeSetWithStats(cultivatedType, filterField, noFruitFilter)
	modifierAngle:executeSet(angle, filterCultivatorArea)
	local _, areaAfter, _ = modifier:executeGet(filterCultivatorArea)
	changedArea = areaAfter - areaBefore
	DensityMapHeightUtil.clearArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	return changedArea, totalArea
end
function FSDensityMapUtil.updateDiscHarrowArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, createField, limitFruitDestructionToField, angle, blockedSprayTypeIndex)
	createField = Utils.getNoNil(createField, true)
	limitFruitDestructionToField = Utils.getNoNil(limitFruitDestructionToField, true)
	angle = angle or 0
	local functionData = FSDensityMapUtil.functionCache.updateDiscHarrowArea
	if functionData == nil then
		local terrainRootNode = g_terrainNode
		local fieldGroundSystem = g_currentMission.fieldGroundSystem
		local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
		local groundAngleMapId, groundAngleFirstChannel, groundAngleNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_ANGLE)
		local stubbleTillageType = FieldGroundType.getValueByType(FieldGroundType.STUBBLE_TILLAGE)
		local seedbedType = FieldGroundType.getValueByType(FieldGroundType.SEEDBED)
		local sprayLevelMapId, sprayLevelFirstChannel, sprayLevelNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_LEVEL)
		local sprayLevelMaxValue = fieldGroundSystem:getMaxValue(FieldDensityMap.SPRAY_LEVEL)
		functionData = {}
		functionData.modifier = DensityMapModifier.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, terrainRootNode)
		functionData.modifierAngle = DensityMapModifier.new(groundAngleMapId, groundAngleFirstChannel, groundAngleNumChannels, terrainRootNode)
		functionData.fieldFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
		functionData.fieldFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)
		functionData.seedbedTypeFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
		functionData.seedbedTypeFilter:setValueCompareParams(DensityValueCompareType.EQUAL, seedbedType)
		functionData.stubbleTillageFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
		functionData.stubbleTillageFilter:setValueCompareParams(DensityValueCompareType.EQUAL, stubbleTillageType)
		functionData.notStubbleTillageFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
		functionData.notStubbleTillageFilter:setValueCompareParams(DensityValueCompareType.NOTEQUAL, stubbleTillageType)
		functionData.sprayLevelModifier = DensityMapModifier.new(sprayLevelMapId, sprayLevelFirstChannel, sprayLevelNumChannels, terrainRootNode)
		functionData.sprayLevelFilter = DensityMapFilter.new(sprayLevelMapId, sprayLevelFirstChannel, sprayLevelNumChannels)
		functionData.sprayLevelFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, 0, sprayLevelMaxValue - 1)
		functionData.multiModifiers = {}
		functionData.fruitFilter = {}
		functionData.preparingModifier = {}
		functionData.preparingFilter = {}
		functionData.noFruitFilter = nil
		functionData.stubbleTillageType = stubbleTillageType
		functionData.seedbedType = seedbedType
		FSDensityMapUtil.functionCache.updateDiscHarrowArea = functionData
	end
	local multiModifiers = functionData.multiModifiers
	local multiModifier = multiModifiers[createField]
	if multiModifier == nil then
		local terrainRootNode = g_terrainNode
		local fruitModifier = nil
		local fieldFilter = nil
		if not createField then
			fieldFilter = functionData.fieldFilter
		end
		local sprayLevelFilter = functionData.sprayLevelFilter
		local sprayLevelModifier = functionData.sprayLevelModifier
		multiModifier = DensityMapMultiModifier.new()
		multiModifiers[createField] = multiModifier
		for index, desc in pairs(g_fruitTypeManager:getFruitTypes()) do
			if desc.terrainDataPlaneId == nil then
				continue
			end
			if functionData.noFruitFilter == nil then
				functionData.noFruitFilter = DensityMapFilter.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)
				functionData.noFruitFilter:setValueCompareParams(DensityValueCompareType.EQUAL, 0)
				functionData.noFruitFilter:setTypeIndexCompareMode(DensityTypeCompareType.ALWAYS)
			end
			if desc.isCultivationAllowed then
				local fruitFilter = functionData.fruitFilter[index]
				if fruitFilter == nil then
					fruitFilter = DensityMapFilter.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)
					fruitFilter:setValueCompareParams(DensityValueCompareType.GREATER, 1)
					functionData.fruitFilter[index] = fruitFilter
				end
				fruitFilter:setValueCompareParams(DensityValueCompareType.GREATER, 1)
				multiModifier:addExecuteSet(functionData.stubbleTillageType, functionData.modifier, fruitFilter, fieldFilter)
				fruitFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, 2, desc.numGrowthStates)
				fruitFilter:setTypeIndexCompareMode(DensityTypeCompareType.EQUAL)
				multiModifier:addExecuteAdd(1, sprayLevelModifier, sprayLevelFilter, fruitFilter, fieldFilter)
				if desc.terrainDataPlaneIdHaulm ~= nil then
					local preparingModifier = functionData.preparingModifier[index]
					if preparingModifier == nil then
						preparingModifier = DensityMapModifier.new(desc.terrainDataPlaneIdHaulm, desc.startStateChannelHaulm, desc.numStateChannelsHaulm)
						functionData.preparingModifier[index] = preparingModifier
					end
					local preparingFilter = functionData.preparingFilter[index]
					if preparingFilter == nil then
						preparingFilter = DensityMapFilter.new(desc.terrainDataPlaneIdHaulm, desc.startStateChannelHaulm, desc.numStateChannelsHaulm)
						preparingFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)
						preparingFilter:setTypeIndexCompareMode(DensityTypeCompareType.ALWAYS)
						functionData.preparingFilter[index] = preparingFilter
					end
					multiModifier:addExecuteSet(0, preparingModifier, preparingFilter)
				end
				if fruitModifier == nil then
					fruitModifier = DensityMapModifier.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)
				else
					fruitModifier:resetDensityMapAndChannels(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)
				end
				fruitModifier:setNewTypeIndexMode(DensityIndexCompareMode.ZERO)
				fruitFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)
				if limitFruitDestructionToField then
					multiModifier:addExecuteSet(0, fruitModifier, fruitFilter, fieldFilter)
				else
					multiModifier:addExecuteSet(0, fruitModifier, fruitFilter)
				end
			end
		end
		for i = 1, #g_currentMission.dynamicFoliageLayers do
			local id = g_currentMission.dynamicFoliageLayers[i]
			local numChannels = getTerrainDetailNumChannels(id)
			local modifier = functionData.dynamicFoliageModifier[id]
			if modifier == nil then
				modifier = DensityMapModifier.new(id, 0, numChannels, terrainRootNode)
				functionData.dynamicFoliageModifier[id] = modifier
			end
			multiModifier:addExecuteSet(0, modifier, fieldFilter)
		end
		FSDensityMapUtil.multiModifierAddResetDisplacement(multiModifier)
	end
	local modifier = functionData.modifier
	local modifierAngle = functionData.modifierAngle
	local fieldFilter = functionData.fieldFilter
	local seedbedTypeFilter = functionData.seedbedTypeFilter
	local stubbleTillageFilter = functionData.stubbleTillageFilter
	local notStubbleTillageFilter = functionData.notStubbleTillageFilter
	local seedbedType = functionData.seedbedType
	local noFruitFilter = functionData.noFruitFilter
	if createField then
		fieldFilter = nil
	end
	local _, areaBeforeSeedbed, _ = modifier:executeGet(seedbedTypeFilter)
	local _, _, totalArea = modifier:executeGet()
	modifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	modifierAngle:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	modifier:executeSet(seedbedType, notStubbleTillageFilter, fieldFilter, noFruitFilter)
	modifierAngle:executeSet(angle, seedbedTypeFilter)
	modifierAngle:executeSet(angle, stubbleTillageFilter)
	local _, areaBeforeStubbleTillage, _ = modifier:executeGet(stubbleTillageFilter)
	multiModifier:updateParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	multiModifier:execute()
	local _, areaAfterSeedbed, _ = modifier:executeGet(seedbedTypeFilter)
	local _, areaAfterStubbleTillage, _ = modifier:executeGet(stubbleTillageFilter)
	FSDensityMapUtil.removeSprayArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, blockedSprayTypeIndex)
	DensityMapHeightUtil.clearArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	if g_currentMission.missionInfo.weedsEnabled then
		FSDensityMapUtil.setSparseWeedArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	else
		FSDensityMapUtil.removeWeedArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	end
	local changedArea = areaAfterSeedbed - areaBeforeSeedbed + (areaAfterStubbleTillage - areaBeforeStubbleTillage)
	return changedArea, totalArea
end
function FSDensityMapUtil.updatePlowPackerArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, angle)
	local functionData = FSDensityMapUtil.functionCache.updatePlowPackerArea
	if functionData == nil then
		local terrainRootNode = g_terrainNode
		local fieldGroundSystem = g_currentMission.fieldGroundSystem
		local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
		local groundAngleMapId, groundAngleFirstChannel, groundAngleNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_ANGLE)
		local cultivatedType = FieldGroundType.getValueByType(FieldGroundType.CULTIVATED)
		local plowedType = FieldGroundType.getValueByType(FieldGroundType.PLOWED)
		local seedbedType = FieldGroundType.getValueByType(FieldGroundType.SEEDBED)
		functionData = {}
		functionData.modifier = DensityMapModifier.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, terrainRootNode)
		functionData.modifierAngle = DensityMapModifier.new(groundAngleMapId, groundAngleFirstChannel, groundAngleNumChannels, terrainRootNode)
		functionData.filterCultivatorArea = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
		functionData.filterCultivatorArea:setValueCompareParams(DensityValueCompareType.EQUAL, cultivatedType)
		functionData.filterPlowArea = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
		functionData.filterPlowArea:setValueCompareParams(DensityValueCompareType.EQUAL, plowedType)
		functionData.filterSeedbedArea = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
		functionData.filterSeedbedArea:setValueCompareParams(DensityValueCompareType.EQUAL, seedbedType)
		functionData.seedbedType = seedbedType
		FSDensityMapUtil.functionCache.updatePlowPackerArea = functionData
	end
	local modifier = functionData.modifier
	local modifierAngle = functionData.modifierAngle
	local filterCultivatorArea = functionData.filterCultivatorArea
	local filterPlowArea = functionData.filterPlowArea
	local filterSeedbedArea = functionData.filterSeedbedArea
	local seedbedType = functionData.seedbedType
	angle = angle or 0
	modifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	modifierAngle:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	FSDensityMapUtil.resetDisplacementArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	local _, areaBefore, _ = modifier:executeGet(filterSeedbedArea)
	local totalArea = nil
	local changedArea = nil
	modifier:executeSet(seedbedType, filterPlowArea)
	_, _, totalArea = modifier:executeSetWithStats(seedbedType, filterCultivatorArea)
	modifierAngle:executeSet(angle, filterSeedbedArea)
	local _, areaAfter, _ = modifier:executeGet(filterSeedbedArea)
	changedArea = areaAfter - areaBefore
	return changedArea, totalArea
end
function FSDensityMapUtil.updateSubsoilerArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, forced)
	if not Platform.gameplay.usePlowCounter then
		return 0, 0
	else
		local functionData = FSDensityMapUtil.functionCache.updateSubsoilerArea
		if functionData == nil then
			local terrainRootNode = g_terrainNode
			local fieldGroundSystem = g_currentMission.fieldGroundSystem
			local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
			local plowLevelMapId, plowLevelFirstChannel, plowLevelNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.PLOW_LEVEL)
			local plowLevelMaxValue = fieldGroundSystem:getMaxValue(FieldDensityMap.PLOW_LEVEL)
			functionData = {}
			functionData.modifier = DensityMapModifier.new(plowLevelMapId, plowLevelFirstChannel, plowLevelNumChannels, terrainRootNode)
			functionData.fieldFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
			functionData.fieldFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)
			functionData.notMaxPlowLevelFilter = DensityMapFilter.new(plowLevelMapId, plowLevelFirstChannel, plowLevelNumChannels)
			functionData.notMaxPlowLevelFilter:setValueCompareParams(DensityValueCompareType.NOTEQUAL, plowLevelMaxValue)
			functionData.plowLevelMaxValue = plowLevelMaxValue
			FSDensityMapUtil.functionCache.updateSubsoilerArea = functionData
		end
		local modifier = functionData.modifier
		local fieldFilter = functionData.fieldFilter
		local notMaxPlowLevelFilter = functionData.notMaxPlowLevelFilter
		local plowLevelMaxValue = functionData.plowLevelMaxValue
		modifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
		if forced then
			fieldFilter = nil
		end
		if g_currentMission.missionInfo.stonesEnabled then
			FSDensityMapUtil.addStoneArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, 2, fieldFilter, notMaxPlowLevelFilter)
		end
		FSDensityMapUtil.resetDisplacementArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
		local _, changedArea, totalArea = modifier:executeSetWithStats(plowLevelMaxValue, fieldFilter)
		return changedArea, totalArea
	end
end
function FSDensityMapUtil.updatePlowArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, createField, limitFruitDestructionToField, angle, resetPlowLevel, stonesDisabled)
	local functionData = FSDensityMapUtil.functionCache.updatePlowArea
	if functionData == nil then
		local terrainRootNode = g_terrainNode
		local fieldGroundSystem = g_currentMission.fieldGroundSystem
		local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
		local groundAngleMapId, groundAngleFirstChannel, groundAngleNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_ANGLE)
		local plowedType = FieldGroundType.getValueByType(FieldGroundType.PLOWED)
		functionData = {}
		functionData.groundTypeModifier = DensityMapModifier.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, terrainRootNode)
		functionData.angleModifier = DensityMapModifier.new(groundAngleMapId, groundAngleFirstChannel, groundAngleNumChannels, terrainRootNode)
		functionData.plowStateFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
		functionData.plowStateFilter:setValueCompareParams(DensityValueCompareType.EQUAL, plowedType)
		functionData.fieldFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
		functionData.fieldFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)
		functionData.notPlowedFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
		functionData.notPlowedFilter:setValueCompareParams(DensityValueCompareType.NOTEQUAL, plowedType)
		functionData.plowedType = plowedType
		if Platform.gameplay.usePlowCounter then
			local plowLevelMapId, plowLevelFirstChannel, plowLevelNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.PLOW_LEVEL)
			functionData.levelModifier = DensityMapModifier.new(plowLevelMapId, plowLevelFirstChannel, plowLevelNumChannels, terrainRootNode)
			functionData.plowLevelMaxValue = fieldGroundSystem:getMaxValue(FieldDensityMap.PLOW_LEVEL)
		end
		functionData.noFruitFilter = nil
		for _, desc in pairs(g_fruitTypeManager:getFruitTypes()) do
			if desc.terrainDataPlaneId ~= nil then
				functionData.noFruitFilter = DensityMapFilter.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)
				functionData.noFruitFilter:setValueCompareParams(DensityValueCompareType.EQUAL, 0)
				functionData.noFruitFilter:setTypeIndexCompareMode(DensityTypeCompareType.ALWAYS)
				break
			end
		end
		FSDensityMapUtil.functionCache.updatePlowArea = functionData
	end
	local groundTypeModifier = functionData.groundTypeModifier
	local angleModifier = functionData.angleModifier
	local levelModifier = functionData.levelModifier
	local plowStateFilter = functionData.plowStateFilter
	local fieldFilter = functionData.fieldFilter
	local notPlowedFilter = functionData.notPlowedFilter
	local plowLevelMaxValue = functionData.plowLevelMaxValue
	local plowedType = functionData.plowedType
	local noFruitFilter = functionData.noFruitFilter
	createField = Utils.getNoNil(createField, true)
	limitFruitDestructionToField = Utils.getNoNil(limitFruitDestructionToField, true)
	angle = angle or 0
	resetPlowLevel = Utils.getNoNil(resetPlowLevel, true)
	FSDensityMapUtil.updateDestroyCommonArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, limitFruitDestructionToField, false)
	groundTypeModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	angleModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	local _, areaBefore, _ = groundTypeModifier:executeGet(plowStateFilter)
	local totalArea = nil
	if createField then
		fieldFilter = nil
		FSDensityMapUtil.clearDecoArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	end
	if g_currentMission.missionInfo.stonesEnabled and stonesDisabled ~= true then
		FSDensityMapUtil.addStoneArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, 1, fieldFilter, notPlowedFilter)
	end
	_, _, totalArea = groundTypeModifier:executeSetWithStats(plowedType, fieldFilter, noFruitFilter)
	if resetPlowLevel and levelModifier ~= nil then
		levelModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
		levelModifier:executeSet(plowLevelMaxValue, fieldFilter)
	end
	angleModifier:executeSet(angle, fieldFilter)
	FSDensityMapUtil.resetSprayArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, true)
	if g_currentMission.missionInfo.weedsEnabled then
		FSDensityMapUtil.setWeedBlockingState(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, plowStateFilter)
	end
	local _, areaAfter, _ = groundTypeModifier:executeGet(plowStateFilter)
	local changedArea = areaAfter - areaBefore
	return changedArea, totalArea
end
function FSDensityMapUtil.updatePlowShareArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, createField, limitFruitDestructionToField, clearFoliageOffset)
	local functionData = FSDensityMapUtil.functionCache.updatePlowShareArea
	if functionData == nil then
		functionData = {}
		local terrainRootNode = g_terrainNode
		local fieldGroundSystem = g_currentMission.fieldGroundSystem
		local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
		local displacementMapId, displacementFirstChannel, displacementNumChannels = fieldGroundSystem:getDisplacementData()
		functionData.modifier = DensityMapModifier.new(displacementMapId, displacementFirstChannel, displacementNumChannels, terrainRootNode)
		functionData.texture = DPUTexture.new("data/maps/textures/terrain/ground/groundType_plowShare_displacement.png")
		local displacementCustomFlagMapId, displacementCustomFlagFirstChannel, displacementCustomFlagNumChannels = fieldGroundSystem:getDisplacementCustomFlagData()
		functionData.modifierCustom = DensityMapModifier.new(displacementCustomFlagMapId, displacementCustomFlagFirstChannel, displacementCustomFlagNumChannels, terrainRootNode)
		functionData.fieldFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
		functionData.fieldFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)
		FSDensityMapUtil.functionCache.updatePlowShareArea = functionData
	end
	local modifier = functionData.modifier
	local modifierCustom = functionData.modifierCustom
	local fieldFilter = functionData.fieldFilter
	local texture = functionData.texture
	if createField then
		fieldFilter = nil
	end
	modifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	modifierCustom:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	modifier:executeSet(0, fieldFilter)
	modifierCustom:executeSet(1, fieldFilter)
	startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ = MathUtil.getWorldParallelogramOffset(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, clearFoliageOffset)
	FSDensityMapUtil.updateDestroyCommonArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, limitFruitDestructionToField, nil, false)
end
function FSDensityMapUtil.resetDisplacementArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, filter1, filter2)
	local functionData = FSDensityMapUtil.functionCache.resetDisplacementArea
	if functionData == nil then
		functionData = {}
		functionData.area = DensityMapParallelogram.new()
	end
	local area = functionData.area
	area:updateFromWorldPositions(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	FSDensityMapUtil.resetDisplacement(area, filter1, filter2)
end
function FSDensityMapUtil.multiModifierAddResetDisplacement(multiModifier, filter1, filter2)
	local terrainRootNode = g_terrainNode
	local fieldGroundSystem = g_currentMission.fieldGroundSystem
	local displacementMapId, displacementFirstChannel, displacementNumChannels = fieldGroundSystem:getDisplacementData()
	local modifier = DensityMapModifier.new(displacementMapId, displacementFirstChannel, displacementNumChannels, terrainRootNode)
	local resetValue = fieldGroundSystem:getDisplacementResetValue()
	local displacementCustomFlagMapId, displacementCustomFlagFirstChannel, displacementCustomFlagNumChannels = fieldGroundSystem:getDisplacementCustomFlagData()
	local modifierCustom = DensityMapModifier.new(displacementCustomFlagMapId, displacementCustomFlagFirstChannel, displacementCustomFlagNumChannels, terrainRootNode)
	multiModifier:addExecuteSet(resetValue, modifier, filter1, filter2)
	multiModifier:addExecuteSet(0, modifierCustom, filter1, filter2)
end
function FSDensityMapUtil.resetDisplacement(densityMapArea, filter1, filter2)
	local functionData = FSDensityMapUtil.functionCache.resetDisplacement
	if functionData == nil then
		functionData = {}
		local terrainRootNode = g_terrainNode
		local fieldGroundSystem = g_currentMission.fieldGroundSystem
		local displacementMapId, displacementFirstChannel, displacementNumChannels = fieldGroundSystem:getDisplacementData()
		functionData.modifier = DensityMapModifier.new(displacementMapId, displacementFirstChannel, displacementNumChannels, terrainRootNode)
		functionData.resetValue = fieldGroundSystem:getDisplacementResetValue()
		local displacementCustomFlagMapId, displacementCustomFlagFirstChannel, displacementCustomFlagNumChannels = fieldGroundSystem:getDisplacementCustomFlagData()
		functionData.modifierCustom = DensityMapModifier.new(displacementCustomFlagMapId, displacementCustomFlagFirstChannel, displacementCustomFlagNumChannels, terrainRootNode)
		FSDensityMapUtil.functionCache.resetDisplacement = functionData
	end
	local modifier = functionData.modifier
	local modifierCustom = functionData.modifierCustom
	local resetValue = functionData.resetValue
	densityMapArea:applyToModifier(modifier)
	densityMapArea:applyToModifier(modifierCustom)
	modifier:executeSet(resetValue, filter1, filter2)
	modifierCustom:executeSet(0, filter1, filter2)
end
function FSDensityMapUtil.updateDestroyCommonArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, onlyOnFields, deleteAll, resetDisplacement)
	onlyOnFields = Utils.getNoNil(onlyOnFields, false)
	deleteAll = Utils.getNoNil(deleteAll, false)
	resetDisplacement = Utils.getNoNil(resetDisplacement, true)
	local functionData = FSDensityMapUtil.functionCache.updateDestroyCommonArea
	if functionData == nil then
		local terrainRootNode = g_terrainNode
		local fieldGroundSystem = g_currentMission.fieldGroundSystem
		local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
		local sprayLevelMapId, sprayLevelFirstChannel, sprayLevelNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_LEVEL)
		local sprayLevelMaxValue = fieldGroundSystem:getMaxValue(FieldDensityMap.SPRAY_LEVEL)
		functionData = {}
		functionData.fieldFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
		functionData.fieldFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)
		functionData.sprayLevelModifier = DensityMapModifier.new(sprayLevelMapId, sprayLevelFirstChannel, sprayLevelNumChannels, terrainRootNode)
		functionData.sprayLevelFilter = DensityMapFilter.new(sprayLevelMapId, sprayLevelFirstChannel, sprayLevelNumChannels)
		functionData.sprayLevelFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, 0, sprayLevelMaxValue - 1)
		functionData.dynamicFoliageModifier = {}
		functionData.fruitFilter = {}
		functionData.preparingModifier = {}
		functionData.preparingFilter = {}
		functionData.multiModifiers = {}
		FSDensityMapUtil.functionCache.updateDestroyCommonArea = functionData
	end
	local multiModifiers = functionData.multiModifiers
	if multiModifiers[onlyOnFields] == nil then
		multiModifiers[onlyOnFields] = {}
	end
	if multiModifiers[onlyOnFields][deleteAll] == nil then
		multiModifiers[onlyOnFields][deleteAll] = {}
	end
	local multiModifier = multiModifiers[onlyOnFields][deleteAll][resetDisplacement]
	if multiModifier == nil then
		local terrainRootNode = g_terrainNode
		local sprayLevelFilter = functionData.sprayLevelFilter
		local sprayLevelModifier = functionData.sprayLevelModifier
		local fruitModifier = nil
		multiModifier = DensityMapMultiModifier.new()
		multiModifiers[onlyOnFields][deleteAll][resetDisplacement] = multiModifier
		local fieldFilter = nil
		if onlyOnFields then
			fieldFilter = functionData.fieldFilter
		end
		for index, desc in pairs(g_fruitTypeManager:getFruitTypes()) do
			if desc.terrainDataPlaneId == nil then
				continue
			end
			local fruitFilter = functionData.fruitFilter[index]
			if fruitFilter == nil then
				fruitFilter = DensityMapFilter.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)
				fruitFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, 2, desc.numGrowthStates)
				functionData.fruitFilter[index] = fruitFilter
			end
			fruitFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, 2, desc.numGrowthStates)
			fruitFilter:setTypeIndexCompareMode(DensityTypeCompareType.EQUAL)
			multiModifier:addExecuteAdd(1, sprayLevelModifier, sprayLevelFilter, fruitFilter, fieldFilter)
			if desc.terrainDataPlaneIdHaulm ~= nil then
				local preparingModifier = functionData.preparingModifier[index]
				if preparingModifier == nil then
					preparingModifier = DensityMapModifier.new(desc.terrainDataPlaneIdHaulm, desc.startStateChannelHaulm, desc.numStateChannelsHaulm)
					functionData.preparingModifier[index] = preparingModifier
				end
				local preparingFilter = functionData.preparingFilter[index]
				if preparingFilter == nil then
					preparingFilter = DensityMapFilter.new(desc.terrainDataPlaneIdHaulm, desc.startStateChannelHaulm, desc.numStateChannelsHaulm)
					preparingFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)
					preparingFilter:setTypeIndexCompareMode(DensityTypeCompareType.ALWAYS)
					functionData.preparingFilter[index] = preparingFilter
				end
				multiModifier:addExecuteSet(0, preparingModifier, preparingFilter)
			end
			if deleteAll or desc.isCultivationAllowed then
				if fruitModifier == nil then
					fruitModifier = DensityMapModifier.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)
				else
					fruitModifier:resetDensityMapAndChannels(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)
				end
				fruitModifier:setNewTypeIndexMode(DensityIndexCompareMode.ZERO)
				fruitFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)
				multiModifier:addExecuteSet(0, fruitModifier, fruitFilter, fieldFilter)
			end
		end
		for i = 1, #g_currentMission.dynamicFoliageLayers do
			local id = g_currentMission.dynamicFoliageLayers[i]
			local numChannels = getTerrainDetailNumChannels(id)
			local modifier = functionData.dynamicFoliageModifier[id]
			if modifier == nil then
				modifier = DensityMapModifier.new(id, 0, numChannels, terrainRootNode)
				functionData.dynamicFoliageModifier[id] = modifier
			end
			multiModifier:addExecuteSet(0, modifier, fieldFilter)
		end
		if resetDisplacement then
			FSDensityMapUtil.multiModifierAddResetDisplacement(multiModifier)
		end
	end
	multiModifier:updateParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	multiModifier:execute()
	FSDensityMapUtil.removeWeedArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	DensityMapHeightUtil.clearArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
end
function FSDensityMapUtil.updateWheelDestructionArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	local functionData = FSDensityMapUtil.functionCache.updateWheelDestructionArea
	if functionData == nil then
		local terrainRootNode = g_terrainNode
		local fieldGroundSystem = g_currentMission.fieldGroundSystem
		local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
		local sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_TYPE)
		functionData = {}
		functionData.modifier = DensityMapModifier.new(sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels, terrainRootNode)
		functionData.multiModifier = nil
		functionData.filter1 = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
		functionData.fieldFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
		functionData.fieldFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)
		FSDensityMapUtil.functionCache.updateWheelDestructionArea = functionData
	end
	local modifier = functionData.modifier
	local multiModifier = functionData.multiModifier
	local filter1 = functionData.filter1
	local fieldFilter = functionData.fieldFilter
	g_currentMission.growthSystem:setIgnoreDensityChanges(true)
	if multiModifier == nil then
		multiModifier = DensityMapMultiModifier.new()
		functionData.multiModifier = multiModifier
		for _, desc in pairs(g_fruitTypeManager:getFruitTypes()) do
			if desc.terrainDataPlaneId == nil or desc.minWheelDestructionState == nil then
				continue
			end
			modifier:resetDensityMapAndChannels(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)
			filter1:resetDensityMapAndChannels(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)
			filter1:setValueCompareParams(DensityValueCompareType.BETWEEN, desc.minWheelDestructionState, desc.maxWheelDestructionState)
			multiModifier:addExecuteSet(desc.wheelDestructionState, modifier, filter1, fieldFilter)
		end
		for i = 1, #g_currentMission.dynamicFoliageLayers do
			local id = g_currentMission.dynamicFoliageLayers[i]
			local numChannels = getTerrainDetailNumChannels(id)
			modifier:resetDensityMapAndChannels(id, 0, numChannels)
			multiModifier:addExecuteSet(0, modifier)
		end
	end
	multiModifier:updateParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	multiModifier:execute()
	FSDensityMapUtil.removeWeedArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	g_currentMission.growthSystem:setIgnoreDensityChanges(false)
end
function FSDensityMapUtil.setGroundTypeLayerArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, value)
	local functionData = FSDensityMapUtil.functionCache.setGroundTypeLayerArea
	if functionData == nil then
		local terrainRootNode = g_terrainNode
		local fieldGroundSystem = g_currentMission.fieldGroundSystem
		local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
		local sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_TYPE)
		functionData = {}
		functionData.groundLayerModifier = DensityMapModifier.new(sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels, terrainRootNode)
		functionData.sprayTypeFilter = DensityMapFilter.new(sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels)
		functionData.fieldFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
		functionData.fieldFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)
		FSDensityMapUtil.functionCache.setGroundTypeLayerArea = functionData
	end
	local groundLayerModifier = functionData.groundLayerModifier
	local sprayTypeFilter = functionData.sprayTypeFilter
	local fieldFilter = functionData.fieldFilter
	groundLayerModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	sprayTypeFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, 0, value - 1)
	local _, numPixels, totalNumPixels = groundLayerModifier:executeSetWithStats(value, sprayTypeFilter, fieldFilter)
	sprayTypeFilter:setValueCompareParams(DensityValueCompareType.GREATER, value)
	local _, numPixels2, totalNumPixels2 = groundLayerModifier:executeSetWithStats(value, sprayTypeFilter, fieldFilter)
	return numPixels + numPixels2, totalNumPixels + totalNumPixels2
end
function FSDensityMapUtil.setStubbleShredLevelArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, value)
	if Platform.gameplay.useStubbleShred then
		local functionData = FSDensityMapUtil.functionCache.setStubbleShredArea
		if functionData == nil then
			local terrainRootNode = g_terrainNode
			local fieldGroundSystem = g_currentMission.fieldGroundSystem
			functionData = {}
			local stubbleShredLevelMapId, stubbleShredLevelFirstChannel, stubbleShredLevelNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.STUBBLE_SHRED_LEVEL)
			functionData.stubbleShredModifier = DensityMapModifier.new(stubbleShredLevelMapId, stubbleShredLevelFirstChannel, stubbleShredLevelNumChannels, terrainRootNode)
			local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
			functionData.fieldFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
			functionData.fieldFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)
			FSDensityMapUtil.functionCache.setStubbleShredArea = functionData
		end
		local stubbleShredModifier = functionData.stubbleShredModifier
		local fieldFilter = functionData.fieldFilter
		stubbleShredModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
		local _, numPixels, totalNumPixels = stubbleShredModifier:executeSetWithStats(value, fieldFilter)
		return numPixels, totalNumPixels
	else
		return
	end
end
function FSDensityMapUtil.updateSprayArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, sprayTypeIndex, sprayAmount)
	local numPixels = 0
	local totalNumPixels = 0
	local desc = g_sprayTypeManager:getSprayTypeByIndex(sprayTypeIndex)
	if desc ~= nil then
		if desc.isLime then
			return FSDensityMapUtil.updateLimeArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, desc.sprayGroundType)
		end
		if desc.isFertilizer then
			return FSDensityMapUtil.updateFertilizerArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, desc.sprayGroundType, sprayAmount)
		end
		if desc.isHerbicide then
			numPixels, totalNumPixels = FSDensityMapUtil.updateHerbicideArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, desc.sprayGroundType)
		end
	end
	return numPixels, totalNumPixels
end
function FSDensityMapUtil.removeSprayArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, blockedSprayTypeIndex, customFilter)
	local functionData = FSDensityMapUtil.functionCache.removeSprayArea
	if functionData == nil then
		local terrainRootNode = g_terrainNode
		local fieldGroundSystem = g_currentMission.fieldGroundSystem
		local sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_TYPE)
		functionData = {}
		functionData.modifier = DensityMapModifier.new(sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels, terrainRootNode)
		functionData.filter = DensityMapFilter.new(sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels)
		FSDensityMapUtil.functionCache.removeSprayArea = functionData
	end
	local modifier = functionData.modifier
	local filter = functionData.filter
	modifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	if blockedSprayTypeIndex ~= nil then
		local sprayType = g_sprayTypeManager:getSprayTypeByIndex(blockedSprayTypeIndex)
		if 0 < sprayType.sprayGroundType then
			filter:setValueCompareParams(DensityValueCompareType.GREATER, sprayType.sprayGroundType)
			modifier:executeSet(0, filter, customFilter)
			if 0 < sprayType.sprayGroundType then
				filter:setValueCompareParams(DensityValueCompareType.BETWEEN, 0, sprayType.sprayGroundType - 1)
				modifier:executeSet(0, filter, customFilter)
			end
		end
	else
		filter:setValueCompareParams(DensityValueCompareType.GREATER, 0)
		modifier:executeSet(0, filter, customFilter)
	end
end
function FSDensityMapUtil.updateFertilizerArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, sprayType, sprayAmount)
	local functionData = FSDensityMapUtil.functionCache.updateFertilizerArea
	if functionData == nil then
		local terrainRootNode = g_terrainNode
		local fieldGroundSystem = g_currentMission.fieldGroundSystem
		local sprayLevelMapId, sprayLevelFirstChannel, sprayLevelNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_LEVEL)
		local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
		local sprayLevelMaxValue = fieldGroundSystem:getMaxValue(FieldDensityMap.SPRAY_LEVEL)
		local sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_TYPE)
		local sprayTypeMaxValue = fieldGroundSystem:getMaxValue(FieldDensityMap.SPRAY_TYPE)
		functionData = {}
		functionData.sprayModifier = DensityMapModifier.new(sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels, terrainRootNode)
		functionData.sprayLevelModifier = DensityMapModifier.new(sprayLevelMapId, sprayLevelFirstChannel, sprayLevelNumChannels, terrainRootNode)
		functionData.growingFruitFilters = {}
		for _, desc in pairs(g_fruitTypeManager:getFruitTypes()) do
			if desc.terrainDataPlaneId == nil then
				continue
			end
			local growingFruitFilter = DensityMapFilter.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)
			growingFruitFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, desc.minHarvestingGrowthState, desc.maxHarvestingGrowthState)
			table.insert(functionData.growingFruitFilters, growingFruitFilter)
		end
		functionData.sprayTypeFilter = DensityMapFilter.new(sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels)
		functionData.sprayTypeFilter:setValueCompareParams(DensityValueCompareType.EQUAL, 0)
		functionData.outsideFieldFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
		functionData.outsideFieldFilter:setValueCompareParams(DensityValueCompareType.EQUAL, 0)
		functionData.maskFilter = DensityMapFilter.new(sprayLevelMapId, sprayLevelFirstChannel, sprayLevelNumChannels)
		functionData.maskFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, 0, sprayLevelMaxValue - 1)
		functionData.maskValue = sprayTypeMaxValue
		FSDensityMapUtil.functionCache.updateFertilizerArea = functionData
	end
	local sprayModifier = functionData.sprayModifier
	local sprayLevelModifier = functionData.sprayLevelModifier
	local sprayTypeFilter = functionData.sprayTypeFilter
	local outsideFieldFilter = functionData.outsideFieldFilter
	local growingFruitFilters = functionData.growingFruitFilters
	local maskFilter = functionData.maskFilter
	local maskValue = functionData.maskValue
	sprayModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	sprayLevelModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	sprayTypeFilter:setValueCompareParams(DensityValueCompareType.NOTEQUAL, sprayType)
	sprayModifier:executeSet(maskValue, sprayTypeFilter, maskFilter)
	sprayTypeFilter:setValueCompareParams(DensityValueCompareType.EQUAL, maskValue)
	sprayModifier:executeSet(0, sprayTypeFilter, outsideFieldFilter)
	for i = 1, #growingFruitFilters do
		local growingFruitFilter = growingFruitFilters[i]
		sprayModifier:executeSet(0, sprayTypeFilter, growingFruitFilter)
	end
	local _ = nil
	local numPixels = nil
	local totalNumPixels = nil
	for i = 1, math.max(sprayAmount or 1, 1) do
		_, _, numPixels, totalNumPixels = sprayLevelModifier:executeAddWithStats(1, sprayTypeFilter, maskFilter)
	end
	sprayModifier:executeSet(sprayType, sprayTypeFilter)
	return numPixels, totalNumPixels
end
function FSDensityMapUtil.updateLimeArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, groundType)
	local functionData = FSDensityMapUtil.functionCache.updateLimeArea
	if functionData == nil then
		local terrainRootNode = g_terrainNode
		local fieldGroundSystem = g_currentMission.fieldGroundSystem
		local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
		local sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_TYPE)
		local limeLevelMapId, limeLevelFirstChannel, limeLevelNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.LIME_LEVEL)
		local limeLevelMaxValue = fieldGroundSystem:getMaxValue(FieldDensityMap.LIME_LEVEL)
		local firstSowableValue, lastSowableValue = fieldGroundSystem:getSowableRange()
		local modifierSprayType = DensityMapModifier.new(sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels, terrainRootNode)
		local modifierLimeLevel = DensityMapModifier.new(limeLevelMapId, limeLevelFirstChannel, limeLevelNumChannels, terrainRootNode)
		local filterLimeLevel = DensityMapFilter.new(limeLevelMapId, limeLevelFirstChannel, limeLevelNumChannels)
		filterLimeLevel:setValueCompareParams(DensityValueCompareType.BETWEEN, 0, limeLevelMaxValue - 1)
		local filterLimeLevelMax = DensityMapFilter.new(limeLevelMapId, limeLevelFirstChannel, limeLevelNumChannels)
		filterLimeLevelMax:setValueCompareParams(DensityValueCompareType.EQUAL, limeLevelMaxValue)
		local fieldFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
		fieldFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)
		local groundFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
		groundFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, firstSowableValue, lastSowableValue)
		local chopperTypeFilter = DensityMapFilter.new(sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels)
		local startChopperValue = FieldChopperType.getValueByType(FieldChopperType.CHOPPER_STRAW)
		local endChopperValue = FieldChopperType.getValueByType(FieldChopperType.CHOPPER_MAIZE)
		chopperTypeFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, startChopperValue, endChopperValue)
		functionData = {}
		functionData.multiModifier = DensityMapMultiModifier.new()
		functionData.modifierLimeLevel = modifierLimeLevel
		functionData.filterLimeLevelMax = filterLimeLevelMax
		local multiModifier = functionData.multiModifier
		local fruitFilter = nil
		local noFruitFilter = nil
		for index, desc in pairs(g_fruitTypeManager:getFruitTypes()) do
			if desc.terrainDataPlaneId == nil then
				continue
			end
			if fruitFilter == nil then
				fruitFilter = DensityMapFilter.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)
				noFruitFilter = DensityMapFilter.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)
				noFruitFilter:setTypeIndexCompareMode(DensityTypeCompareType.ALWAYS)
			else
				fruitFilter:resetDensityMapAndChannels(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)
				noFruitFilter:resetDensityMapAndChannels(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)
			end
			fruitFilter:setValueCompareParams(DensityValueCompareType.EQUAL, 1)
			multiModifier:addExecuteSet(groundType, modifierSprayType, fieldFilter, fruitFilter)
			multiModifier:addExecuteSet(limeLevelMaxValue, modifierLimeLevel, fieldFilter, fruitFilter, filterLimeLevel)
			fruitFilter:setValueCompareParams(DensityValueCompareType.GREATER, desc.maxHarvestingGrowthState)
			multiModifier:addExecuteSet(groundType, modifierSprayType, fieldFilter, fruitFilter)
			multiModifier:addExecuteSet(limeLevelMaxValue, modifierLimeLevel, fieldFilter, fruitFilter, filterLimeLevel)
			noFruitFilter:setValueCompareParams(DensityValueCompareType.EQUAL, 0)
			multiModifier:addExecuteSet(groundType, modifierSprayType, fieldFilter, noFruitFilter)
			multiModifier:addExecuteSet(limeLevelMaxValue, modifierLimeLevel, fieldFilter, noFruitFilter, filterLimeLevel)
		end
		multiModifier:addExecuteSet(groundType, modifierSprayType, groundFilter)
		multiModifier:addExecuteSet(limeLevelMaxValue, modifierLimeLevel, groundFilter, filterLimeLevel)
		multiModifier:addExecuteSet(groundType, modifierSprayType, chopperTypeFilter)
		multiModifier:addExecuteSet(limeLevelMaxValue, modifierLimeLevel, chopperTypeFilter, filterLimeLevel)
		FSDensityMapUtil.functionCache.updateLimeArea = functionData
	end
	local multiModifier = functionData.multiModifier
	local modifierLimeLevel = functionData.modifierLimeLevel
	local filterLimeLevelMax = functionData.filterLimeLevelMax
	modifierLimeLevel:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	local _, areaBefore, totalNumPixels = modifierLimeLevel:executeGet(filterLimeLevelMax)
	multiModifier:updateParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	multiModifier:execute()
	local _, areaAfter, _ = modifierLimeLevel:executeGet(filterLimeLevelMax)
	return areaAfter - areaBefore, totalNumPixels
end
function FSDensityMapUtil.updateHerbicideArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, groundType)
	local weedSystem = g_currentMission.weedSystem
	if not weedSystem:getMapHasWeed() then
		return 0, 0
	else
		local functionData = FSDensityMapUtil.functionCache.updateHerbicideArea
		if functionData == nil then
			functionData = {}
			functionData.numChangedPixels = {}
			functionData.totalNumPixels = {}
			functionData.multiModifiers = {}
			FSDensityMapUtil.functionCache.updateHerbicideArea = functionData
		end
		local labelTotal = "sprayedTotal"
		local labelSprayed = "sprayed"
		local label = "sprayedTotal"
		local multiModifier = groundType and functionData.multiModifiers[groundType] or functionData.defaultMultiModifier
		if multiModifier == nil then
			multiModifier = DensityMapMultiModifier.new()
			local terrainRootNode = g_terrainNode
			local fieldGroundSystem = g_currentMission.fieldGroundSystem
			local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
			local sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_TYPE)
			local weedMapId, weedFirstChannel, weedNumChannels = weedSystem:getDensityMapData()
			local firstSowableValue, lastSowableValue = fieldGroundSystem:getSowableRange()
			local replacementData = weedSystem:getHerbicideReplacements()
			local replacements = replacementData.weed.replacements
			if replacementData.custom ~= nil then
				for _, data in ipairs(replacementData.custom) do
					local desc = data.fruitType
					if desc.terrainDataPlaneId == nil then
						continue
					end
					local fruitModifier = DensityMapModifier.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels, terrainRootNode)
					local sourceStateFilter = DensityMapFilter.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)
					for sourceState, targetState in pairs(replacements) do
						sourceStateFilter:setValueCompareParams(DensityValueCompareType.EQUAL, sourceState)
						multiModifier:addExecuteSetWithStats(label, targetState, fruitModifier, sourceStateFilter)
						label = "sprayed"
					end
				end
			end
			local sprayModifier = DensityMapModifier.new(sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels, terrainRootNode)
			local weedModifier = DensityMapModifier.new(weedMapId, weedFirstChannel, weedNumChannels, terrainRootNode)
			local groundFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
			groundFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, firstSowableValue, lastSowableValue)
			for sourceState, targetState in pairs(replacements) do
				local weedFilter = DensityMapFilter.new(weedMapId, weedFirstChannel, weedNumChannels)
				weedFilter:setValueCompareParams(DensityValueCompareType.EQUAL, sourceState)
				for _, desc in pairs(g_fruitTypeManager:getFruitTypes()) do
					if desc.terrainDataPlaneId == nil then
						continue
					end
					local fruitFilter = DensityMapFilter.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)
					fruitFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, 1, desc.minHarvestingGrowthState - 1)
					multiModifier:addExecuteSet(groundType, sprayModifier, fruitFilter, weedFilter)
					multiModifier:addExecuteSetWithStats(label, targetState, weedModifier, fruitFilter, weedFilter)
					local cutFruitFilter = DensityMapFilter.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)
					cutFruitFilter:setValueCompareParams(DensityValueCompareType.EQUAL, desc.cutState + 1)
					multiModifier:addExecuteSet(groundType, sprayModifier, cutFruitFilter, weedFilter)
					multiModifier:addExecuteSetWithStats(label, targetState, weedModifier, cutFruitFilter, weedFilter)
					if desc.wheelDestructionState == nil or desc.wheelDestructionState == desc.cutState + 1 then
						continue
					end
					local wheelDestructionFruitFilter = DensityMapFilter.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)
					wheelDestructionFruitFilter:setValueCompareParams(DensityValueCompareType.EQUAL, desc.wheelDestructionState)
					multiModifier:addExecuteSet(groundType, sprayModifier, wheelDestructionFruitFilter, weedFilter)
					multiModifier:addExecuteSetWithStats(label, targetState, weedModifier, wheelDestructionFruitFilter, weedFilter)
				end
				multiModifier:addExecuteSet(groundType, sprayModifier, groundFilter, weedFilter)
				multiModifier:addExecuteSetWithStats(label, targetState, weedModifier, groundFilter, weedFilter)
			end
			if groundType then
				functionData.multiModifiers[groundType] = multiModifier
			else
				functionData.defaultMultiModifier = multiModifier
			end
		end
		local numChangedPixels = functionData.numChangedPixels
		local totalNumPixels = functionData.totalNumPixels
		multiModifier:updateParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
		multiModifier:resetStats()
		multiModifier:execute(nil, numChangedPixels, totalNumPixels)
		local area = numChangedPixels.sprayedTotal + numChangedPixels.sprayed
		local totalPixels = totalNumPixels.sprayedTotal or 0
		return area, totalPixels
	end
end
function FSDensityMapUtil.updateWeederArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, isHoeWeeder)
	local weedSystem = g_currentMission.weedSystem
	local _ = nil
	local areaBefore = 0
	local areaAfter = 0
	if weedSystem:getMapHasWeed() then
		local functionData = FSDensityMapUtil.functionCache.updateWeederArea
		if functionData == nil then
			functionData = {}
			FSDensityMapUtil.functionCache.updateWeederArea = functionData
		end
		local weederData = functionData[isHoeWeeder]
		if weederData == nil then
			local terrainRootNode = g_terrainNode
			local fieldGroundSystem = g_currentMission.fieldGroundSystem
			local weedMapId, weedFirstChannel, weedNumChannels = weedSystem:getDensityMapData()
			local replacementData = weedSystem:getWeederReplacements(isHoeWeeder)
			local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
			local firstSowableState, lastSowableState = fieldGroundSystem:getSowableRange()
			weederData = {}
			weederData.weedModifier = DensityMapModifier.new(weedMapId, weedFirstChannel, weedNumChannels, terrainRootNode)
			weederData.allWeedFilter = DensityMapFilter.new(weedMapId, weedFirstChannel, weedNumChannels)
			weederData.allWeedFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)
			weederData.multiModifierGrowing = DensityMapMultiModifier.new()
			weederData.multiModifierSowable = DensityMapMultiModifier.new()
			local fruitStateFilter = nil
			local sourceStateFilter = DensityMapFilter.new(weedMapId, weedFirstChannel, weedNumChannels)
			local sowableFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
			sowableFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, firstSowableState, lastSowableState)
			for sourceState, targetState in pairs(replacementData.weed.replacements) do
				sourceStateFilter:setValueCompareParams(DensityValueCompareType.EQUAL, sourceState)
				for _, desc in pairs(g_fruitTypeManager:getFruitTypes()) do
					if desc.terrainDataPlaneId == nil then
						continue
					end
					if fruitStateFilter == nil then
						fruitStateFilter = DensityMapFilter.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)
					else
						fruitStateFilter:resetDensityMapAndChannels(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)
					end
					local maxWeederState = desc.maxWeederState
					if isHoeWeeder then
						maxWeederState = desc.maxWeederHoeState
					end
					fruitStateFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, 0, maxWeederState)
					weederData.multiModifierGrowing:addExecuteSet(targetState, weederData.weedModifier, sourceStateFilter, fruitStateFilter)
					fruitStateFilter:setValueCompareParams(DensityValueCompareType.EQUAL, desc.cutState)
					weederData.multiModifierGrowing:addExecuteSet(targetState, weederData.weedModifier, sourceStateFilter, fruitStateFilter)
				end
				weederData.multiModifierSowable:addExecuteSet(targetState, weederData.weedModifier, sourceStateFilter, sowableFilter)
			end
			if replacementData.custom ~= nil then
				weederData.multiModifierCustom = DensityMapMultiModifier.new()
				local fruitModifier = nil
				for _, data in ipairs(replacementData.custom) do
					local desc = data.fruitType
					if desc.terrainDataPlaneId == nil then
						continue
					end
					if fruitModifier == nil then
						fruitModifier = DensityMapModifier.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels, terrainRootNode)
					else
						fruitModifier:resetDensityMapAndChannels(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)
					end
					sourceStateFilter:resetDensityMapAndChannels(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)
					for sourceState, targetState in pairs(data.replacements) do
						sourceStateFilter:setValueCompareParams(DensityValueCompareType.EQUAL, sourceState)
						weederData.multiModifierCustom:addExecuteSet(targetState, fruitModifier, sourceStateFilter)
					end
				end
			end
			FSDensityMapUtil.functionCache.updateWeederArea[isHoeWeeder] = weederData
		end
		local weedModifier = weederData.weedModifier
		local allWeedFilter = weederData.allWeedFilter
		local multiModifierGrowing = weederData.multiModifierGrowing
		local multiModifierSowable = weederData.multiModifierSowable
		local multiModifierCustom = weederData.multiModifierCustom
		weedModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
		_, areaBefore, _ = weedModifier:executeGet(allWeedFilter)
		multiModifierGrowing:updateParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
		multiModifierGrowing:execute()
		multiModifierSowable:updateParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
		multiModifierSowable:execute()
		if multiModifierCustom ~= nil then
			multiModifierCustom:updateParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
			multiModifierCustom:execute()
		end
		_, areaAfter, _ = weedModifier:executeGet(allWeedFilter)
	end
	DensityMapHeightUtil.removeFromGroundByArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, FillType.GRASS_WINDROW)
	DensityMapHeightUtil.removeFromGroundByArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, FillType.DRYGRASS_WINDROW)
	return areaBefore - areaAfter
end
function FSDensityMapUtil.removeWeedArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	local numPixels = 0
	local totalNumPixels = 0
	local weedSystem = g_currentMission.weedSystem
	if weedSystem:getMapHasWeed() then
		local functionData = FSDensityMapUtil.functionCache.removeWeedArea
		if functionData == nil then
			local terrainRootNode = g_terrainNode
			local weedMapId, weedFirstChannel, weedNumChannels = weedSystem:getDensityMapData()
			functionData = {}
			functionData.weedModifier = DensityMapModifier.new(weedMapId, weedFirstChannel, weedNumChannels, terrainRootNode)
			FSDensityMapUtil.functionCache.removeWeedArea = functionData
		end
		local weedModifier = functionData.weedModifier
		weedModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
		local _ = nil
		_, numPixels, totalNumPixels = weedModifier:executeSetWithStats(0)
	end
	return numPixels, totalNumPixels
end
function FSDensityMapUtil.setSparseWeedArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	local weedSystem = g_currentMission.weedSystem
	if weedSystem:getMapHasWeed() then
		local functionData = FSDensityMapUtil.functionCache.setSparseWeedArea
		if functionData == nil then
			local terrainRootNode = g_terrainNode
			local fieldGroundSystem = g_currentMission.fieldGroundSystem
			local weedMapId, weedFirstChannel, weedNumChannels = weedSystem:getDensityMapData()
			local infoId, _, _ = weedSystem:getInfoLayerData()
			local blockingStateValue, blockingStateFirstChannel, blockingStateNumChannels = weedSystem:getBlockingStateData()
			local sparseState = weedSystem:getSparseStartState()
			local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
			functionData = {}
			functionData.weedModifier = DensityMapModifier.new(weedMapId, weedFirstChannel, weedNumChannels, terrainRootNode)
			functionData.fieldFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
			functionData.fieldFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)
			functionData.notWeedBlockedFilter = DensityMapFilter.new(infoId, blockingStateFirstChannel, blockingStateNumChannels)
			functionData.notWeedBlockedFilter:setValueCompareParams(DensityValueCompareType.NOTEQUAL, blockingStateValue)
			functionData.sparseState = sparseState
			FSDensityMapUtil.functionCache.setSparseWeedArea = functionData
		end
		local weedModifier = functionData.weedModifier
		local fieldFilter = functionData.fieldFilter
		local notWeedBlockedFilter = functionData.notWeedBlockedFilter
		local sparseState = functionData.sparseState
		weedModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
		weedModifier:executeSet(sparseState, fieldFilter, notWeedBlockedFilter)
	end
end
function FSDensityMapUtil.setSowingWeedArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	local weedSystem = g_currentMission.weedSystem
	if weedSystem:getMapHasWeed() then
		local functionData = FSDensityMapUtil.functionCache.setSowingWeedArea
		if functionData == nil then
			local terrainRootNode = g_terrainNode
			local fieldGroundSystem = g_currentMission.fieldGroundSystem
			local weedMapId, weedFirstChannel, weedNumChannels = weedSystem:getDensityMapData()
			local infoId, _, _ = weedSystem:getInfoLayerData()
			local blockingStateValue, blockingStateFirstChannel, blockingStateNumChannels = weedSystem:getBlockingStateData()
			local sparseState = weedSystem:getSparseStartState()
			local denseState = weedSystem:getDenseStartState()
			local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
			local firstSowableValue, lastSowableValue = fieldGroundSystem:getSowableRange()
			local stubbleTillageValue = FieldGroundType.getValueByType(FieldGroundType.STUBBLE_TILLAGE)
			functionData = {}
			functionData.weedModifier = DensityMapModifier.new(weedMapId, weedFirstChannel, weedNumChannels, terrainRootNode)
			functionData.notBlockedFilter = DensityMapFilter.new(infoId, blockingStateFirstChannel, blockingStateNumChannels)
			functionData.notBlockedFilter:setValueCompareParams(DensityValueCompareType.NOTEQUAL, blockingStateValue)
			functionData.stubbleTillageFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
			functionData.stubbleTillageFilter:setValueCompareParams(DensityValueCompareType.EQUAL, stubbleTillageValue)
			functionData.sowableFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
			functionData.sowableFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, firstSowableValue, lastSowableValue)
			functionData.sparseState = sparseState
			functionData.denseState = denseState
			FSDensityMapUtil.functionCache.setSowingWeedArea = functionData
		end
		local weedModifier = functionData.weedModifier
		local stubbleTillageFilter = functionData.stubbleTillageFilter
		local notBlockedFilter = functionData.notBlockedFilter
		local sowableFilter = functionData.sowableFilter
		local denseState = functionData.denseState
		local sparseState = functionData.sparseState
		weedModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
		weedModifier:executeSet(sparseState, sowableFilter, notBlockedFilter)
		weedModifier:executeSet(denseState, stubbleTillageFilter, notBlockedFilter)
	end
end
function FSDensityMapUtil.setWeedBlockingState(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, customFilter1, customFilter2)
	local weedSystem = g_currentMission.weedSystem
	if weedSystem:getMapHasWeed() then
		local functionData = FSDensityMapUtil.functionCache.setWeedBlockingState
		if functionData == nil then
			local terrainRootNode = g_terrainNode
			local infoId, _, _ = weedSystem:getInfoLayerData()
			local blockingValue, blockingStateFirstChannel, blockingStateNumChannels = weedSystem:getBlockingStateData()
			functionData = {}
			functionData.weedInfoModifier = DensityMapModifier.new(infoId, blockingStateFirstChannel, blockingStateNumChannels, terrainRootNode)
			functionData.blockingValue = blockingValue
			FSDensityMapUtil.functionCache.setWeedBlockingState = functionData
		end
		local weedInfoModifier = functionData.weedInfoModifier
		local blockingValue = functionData.blockingValue
		weedInfoModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
		weedInfoModifier:executeSet(blockingValue, customFilter1, customFilter2)
	end
end
function FSDensityMapUtil.removeWeedBlockingState(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	local weedSystem = g_currentMission.weedSystem
	if weedSystem:getMapHasWeed() then
		local functionData = FSDensityMapUtil.functionCache.removeWeedBlockingState
		if functionData == nil then
			local terrainRootNode = g_terrainNode
			local infoId, _, _ = weedSystem:getInfoLayerData()
			local _, blockingStateFirstChannel, blockingStateNumChannels = weedSystem:getBlockingStateData()
			functionData = {}
			functionData.weedInfoModifier = DensityMapModifier.new(infoId, blockingStateFirstChannel, blockingStateNumChannels, terrainRootNode)
			FSDensityMapUtil.functionCache.removeWeedBlockingState = functionData
		end
		local weedInfoModifier = functionData.weedInfoModifier
		weedInfoModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
		weedInfoModifier:executeSet(0)
	end
end
function FSDensityMapUtil.updateMulcherArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	local functionData = FSDensityMapUtil.functionCache.updateMulcherArea
	if functionData == nil then
		local terrainRootNode = g_terrainNode
		local mission = g_currentMission
		local fieldGroundSystem = mission.fieldGroundSystem
		local sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_TYPE)
		functionData = {}
		functionData.multiModifier = DensityMapMultiModifier.new()
		local multiModifier = functionData.multiModifier
		local stubbleShredModifier = nil
		if Platform.gameplay.useStubbleShred then
			local stubbleShredLevelMapId, stubbleShredLevelFirstChannel, stubbleShredLevelNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.STUBBLE_SHRED_LEVEL)
			stubbleShredModifier = DensityMapModifier.new(stubbleShredLevelMapId, stubbleShredLevelFirstChannel, stubbleShredLevelNumChannels, terrainRootNode)
		end
		local sprayTypeModifier = nil
		if sprayTypeMapId ~= nil then
			sprayTypeModifier = DensityMapModifier.new(sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels, terrainRootNode)
		end
		local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
		local fruitFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
		local mulchedStateFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
		local fruitModifier = nil
		for _, desc in pairs(g_fruitTypeManager:getFruitTypes()) do
			if desc.isCultivationAllowed then
				if desc.terrainDataPlaneId == nil then
					continue
				end
				fruitFilter:resetDensityMapAndChannels(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)
				fruitFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, 2, desc.cutState)
				mulchedStateFilter:resetDensityMapAndChannels(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)
				mulchedStateFilter:setValueCompareParams(DensityValueCompareType.NOTEQUAL, desc.mulchedState or 0)
				if desc.mulcherChopperType ~= nil and sprayTypeModifier ~= nil then
					local chopperTypeValue = FieldChopperType.getValueByType(desc.mulcherChopperType)
					if chopperTypeValue ~= nil then
						multiModifier:addExecuteSetWithStats("", chopperTypeValue, sprayTypeModifier, fruitFilter, mulchedStateFilter)
					end
				end
				if stubbleShredModifier ~= nil then
					multiModifier:addExecuteAddWithStats("", 1, stubbleShredModifier, fruitFilter, mulchedStateFilter)
				end
				if desc.terrainDataPlaneIdHaulm ~= nil then
					local preparingModifier = DensityMapModifier.new(desc.terrainDataPlaneIdHaulm, desc.startStateChannelHaulm, desc.numStateChannelsHaulm)
					local preparingFilter = DensityMapFilter.new(desc.terrainDataPlaneIdHaulm, desc.startStateChannelHaulm, desc.numStateChannelsHaulm)
					preparingFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)
					preparingFilter:setTypeIndexCompareMode(DensityTypeCompareType.ALWAYS)
					multiModifier:addExecuteSet(0, preparingModifier, preparingFilter)
				end
				if fruitModifier == nil then
					fruitModifier = DensityMapModifier.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)
				else
					fruitModifier:resetDensityMapAndChannels(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)
				end
				if (desc.mulchedState or 0) == 0 then
					fruitModifier:setNewTypeIndexMode(DensityIndexCompareMode.ZERO)
				end
				fruitFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)
				multiModifier:addExecuteSetWithStats("", desc.mulchedState or 0, fruitModifier, fruitFilter, mulchedStateFilter)
			end
		end
		local weedSystem = mission.weedSystem
		if weedSystem ~= nil then
			local weedMapId, weedFirstChannel, weedNumChannels = weedSystem:getDensityMapData()
			local sourceStateFilter = DensityMapFilter.new(weedMapId, weedFirstChannel, weedNumChannels)
			local weedModifier = DensityMapModifier.new(weedMapId, weedFirstChannel, weedNumChannels, terrainRootNode)
			local replacementData = weedSystem:getMulcherReplacements()
			if replacementData.weed ~= nil then
				for sourceState, targetState in pairs(replacementData.weed.replacements) do
					sourceStateFilter:setValueCompareParams(DensityValueCompareType.EQUAL, sourceState)
					multiModifier:addExecuteSetWithStats("", targetState, weedModifier, sourceStateFilter)
				end
			end
			if replacementData.custom ~= nil then
				fruitModifier = nil
				for _, data in ipairs(replacementData.custom) do
					local desc = data.fruitType
					if desc.terrainDataPlaneId == nil then
						continue
					end
					if fruitModifier == nil then
						fruitModifier = DensityMapModifier.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels, terrainRootNode)
					else
						fruitModifier:resetDensityMapAndChannels(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)
					end
					if sourceStateFilter == nil then
						sourceStateFilter = DensityMapFilter.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)
					else
						sourceStateFilter:resetDensityMapAndChannels(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)
					end
					for sourceState, targetState in pairs(data.replacements) do
						sourceStateFilter:setValueCompareParams(DensityValueCompareType.EQUAL, sourceState)
						multiModifier:addExecuteSetWithStats("", targetState, fruitModifier, sourceStateFilter)
					end
				end
			end
			local desc = g_fruitTypeManager:getFruitTypeByIndex(FruitType.MEADOW)
			if desc ~= nil and desc.terrainDataPlaneId ~= nil then
				local foliageFilter = nil
				local fruitValueModifier = DensityMapModifier.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels, terrainRootNode)
				fruitValueModifier:setNewTypeIndexMode(DensityIndexCompareMode.UPDATE)
				local foliageSystem = mission.foliageSystem
				if foliageSystem ~= nil then
					local decoFoliages = foliageSystem:getDecoFoliages()
					for _, decoFoliage in pairs(decoFoliages) do
						if decoFoliage.mowable then
							if decoFoliage.terrainDataPlaneId == nil then
								continue
							end
							if foliageFilter == nil then
								foliageFilter = DensityMapFilter.new(decoFoliage.terrainDataPlaneId, decoFoliage.startStateChannel, decoFoliage.numStateChannels)
							else
								foliageFilter:resetDensityMapAndChannels(decoFoliage.terrainDataPlaneId, decoFoliage.startStateChannel, decoFoliage.numStateChannels)
							end
							foliageFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)
							if desc.regrows then
								if desc.mulchedState == nil then
									continue
								end
								multiModifier:addExecuteSetWithStats("", desc.mulchedState, fruitValueModifier, foliageFilter)
							end
						end
					end
				end
			end
		end
		FSDensityMapUtil.functionCache.updateMulcherArea = functionData
	end
	DensityMapHeightUtil.clearArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	local multiModifier = functionData.multiModifier
	multiModifier:updateParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	multiModifier:resetStats()
	local changeArea, changeTotalArea = multiModifier:execute()
	return changeArea, changeTotalArea
end
function FSDensityMapUtil.updateMowerArea(fruitType, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, limitToField)
	local desc = g_fruitTypeManager:getFruitTypeByIndex(FruitType.MEADOW)
	if desc ~= nil and desc.terrainDataPlaneId ~= nil then
		local functionData = FSDensityMapUtil.functionCache.updateMowerArea
		if functionData == nil then
			local terrainRootNode = g_terrainNode
			functionData = {}
			local multiModifier = DensityMapMultiModifier.new()
			local foliageFilter = nil
			local fruitValueModifier = DensityMapModifier.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels, terrainRootNode)
			fruitValueModifier:setNewTypeIndexMode(DensityIndexCompareMode.UPDATE)
			if g_currentMission.foliageSystem ~= nil then
				local decoFoliages = g_currentMission.foliageSystem:getDecoFoliages()
				for _, decoFoliage in pairs(decoFoliages) do
					if decoFoliage.mowable then
						if decoFoliage.terrainDataPlaneId == nil then
							continue
						end
						if foliageFilter == nil then
							foliageFilter = DensityMapFilter.new(decoFoliage.terrainDataPlaneId, decoFoliage.startStateChannel, decoFoliage.numStateChannels)
						else
							foliageFilter:resetDensityMapAndChannels(decoFoliage.terrainDataPlaneId, decoFoliage.startStateChannel, decoFoliage.numStateChannels)
						end
						if desc.regrows then
							if desc.firstRegrowthState == nil then
								continue
							end
							foliageFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)
							multiModifier:addExecuteSet(desc.firstRegrowthState, fruitValueModifier, foliageFilter)
						end
					end
				end
			end
			functionData.multiModifier = multiModifier
			FSDensityMapUtil.functionCache.updateMowerArea = functionData
		end
		local multiModifier = functionData.multiModifier
		if not limitToField then
			multiModifier:updateParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
			multiModifier:execute()
		end
	end
	return FSDensityMapUtil.cutFruitArea(fruitType, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, true, false, nil, nil, limitToField)
end
function FSDensityMapUtil.updateFruitHaulmArea(fruitId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	local functionData = FSDensityMapUtil.functionCache.updateFruitHaulmArea
	if functionData == nil then
		functionData = {}
		functionData.fruitModifiers = {}
		functionData.fruitFilters = {}
		functionData.dropModifiers = {}
		functionData.dropFilters = {}
		FSDensityMapUtil.functionCache.updateFruitHaulmArea = functionData
	end
	local desc = g_fruitTypeManager:getFruitTypeByIndex(fruitId)
	if desc ~= nil and desc.terrainDataPlaneIdHaulm ~= nil then
		local dropModifier = functionData.dropModifiers[fruitId]
		local dropFilter = functionData.dropFilters[fruitId]
		if dropModifier == nil or dropFilter == nil then
			dropModifier = desc:getHaulmModifier()
			functionData.dropModifiers[fruitId] = dropModifier
			dropFilter = DensityMapFilter.new(desc:getModifier())
			dropFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)
			functionData.dropFilters[fruitId] = dropFilter
		end
		dropModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
		local _, numChangedPixels = dropModifier:executeSetWithStats(1, dropFilter)
		return numChangedPixels
	end
	return 0
end
function FSDensityMapUtil.getStubbleFactor(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	if not Platform.gameplay.useStubbleShred then
		return 1
	else
		local functionData = FSDensityMapUtil.functionCache.getStubbleFactor
		if functionData == nil then
			local terrainRootNode = g_terrainNode
			local fieldGroundSystem = g_currentMission.fieldGroundSystem
			local stubbleShredLevelMapId, stubbleShredLevelFirstChannel, stubbleShredLevelNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.STUBBLE_SHRED_LEVEL)
			functionData = {}
			functionData.stubbleShredModifier = DensityMapModifier.new(stubbleShredLevelMapId, stubbleShredLevelFirstChannel, stubbleShredLevelNumChannels, terrainRootNode)
			functionData.stubbleShredFilter = DensityMapFilter.new(stubbleShredLevelMapId, stubbleShredLevelFirstChannel, stubbleShredLevelNumChannels)
			functionData.stubbleShredFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)
			FSDensityMapUtil.functionCache.getStubbleFactor = functionData
		end
		local stubbleShredModifier = functionData.stubbleShredModifier
		stubbleShredModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
		local _, stubbleArea, totalPixels = stubbleShredModifier:executeGet(functionData.stubbleShredFilter)
		return stubbleArea / totalPixels
	end
end
function FSDensityMapUtil.resetSprayArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, force, excludeType)
	local functionData = FSDensityMapUtil.functionCache.resetSprayArea
	if functionData == nil then
		local terrainRootNode = g_terrainNode
		local fieldGroundSystem = g_currentMission.fieldGroundSystem
		local sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_TYPE)
		local sprayLevelMapId, sprayLevelFirstChannel, sprayLevelNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_LEVEL)
		local sprayLevelMaxValue = fieldGroundSystem:getMaxValue(FieldDensityMap.SPRAY_LEVEL)
		functionData = {}
		functionData.resetModifier = DensityMapModifier.new(sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels, terrainRootNode)
		functionData.excludeFilter = DensityMapFilter.new(sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels)
		functionData.sprayLevelFilter = DensityMapFilter.new(sprayLevelMapId, sprayLevelFirstChannel, sprayLevelNumChannels)
		functionData.sprayLevelFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, 0, sprayLevelMaxValue)
		FSDensityMapUtil.functionCache.resetSprayArea = functionData
	end
	local resetModifier = functionData.resetModifier
	local excludeFilter = functionData.excludeFilter
	resetModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	local sprayLevelFilter = nil
	if not force then
		sprayLevelFilter = functionData.sprayLevelFilter
	end
	if excludeType == nil then
		resetModifier:executeSet(0, sprayLevelFilter)
	else
		excludeFilter:setValueCompareParams(DensityValueCompareType.NOTEQUAL, excludeType)
		resetModifier:executeSet(0, excludeFilter, sprayLevelFilter)
	end
end
function FSDensityMapUtil.updateSowingArea(fruitIndex, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, fieldGroundType, ridgeSeeding, angle, growthState, blockedSprayTypeIndex)
	local desc = g_fruitTypeManager:getFruitTypeByIndex(fruitIndex)
	if desc.terrainDataPlaneId == nil then
		return 0, 0
	else
		local functionData = FSDensityMapUtil.functionCache.updateSowingArea
		if functionData == nil then
			local terrainRootNode = g_terrainNode
			local fieldGroundSystem = g_currentMission.fieldGroundSystem
			local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
			local groundAngleMapId, groundAngleFirstChannel, groundAngleNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_ANGLE)
			local rollerLevelMapId, rollerLevelFirstChannel, rollerLevelNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.ROLLER_LEVEL)
			local rollerLevelMaxValue = fieldGroundSystem:getMaxValue(FieldDensityMap.ROLLER_LEVEL)
			local fieldTypeMapId, fieldTypeFirstChannel, fieldTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.FIELD_TYPE)
			local sownType = FieldGroundType.getValueByType(FieldGroundType.SOWN)
			local directSownType = FieldGroundType.getValueByType(FieldGroundType.DIRECT_SOWN)
			local ridgeType = FieldGroundType.getValueByType(FieldGroundType.RIDGE)
			local ridgeTypeSown = FieldGroundType.getValueByType(FieldGroundType.RIDGE_SOWN)
			local stubbleTillagedType = FieldGroundType.getValueByType(FieldGroundType.STUBBLE_TILLAGE)
			local firstSowableValue, lastSowableValue = fieldGroundSystem:getSowableRange()
			local firstSowingValue, lastSowingValue = fieldGroundSystem:getSowingRange()
			functionData = {}
			functionData.groundTypeModifier = DensityMapModifier.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, terrainRootNode)
			functionData.groundAngleModifier = DensityMapModifier.new(groundAngleMapId, groundAngleFirstChannel, groundAngleNumChannels, terrainRootNode)
			functionData.fruitModifiers = {}
			functionData.fruitFilters = {}
			functionData.sowableFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
			functionData.sowableFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, firstSowableValue, lastSowableValue)
			functionData.sowingFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
			functionData.sowingFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, firstSowingValue, lastSowingValue)
			functionData.ridgeFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
			functionData.ridgeFilter:setValueCompareParams(DensityValueCompareType.EQUAL, FieldGroundType.getValueByType(FieldGroundType.RIDGE))
			functionData.fieldTypeFilter = DensityMapFilter.new(fieldTypeMapId, fieldTypeFirstChannel, fieldTypeNumChannels)
			if Platform.gameplay.useRolling then
				functionData.rollerLevelModifier = DensityMapModifier.new(rollerLevelMapId, rollerLevelFirstChannel, rollerLevelNumChannels, terrainRootNode)
				functionData.rollerLevelMaxValue = rollerLevelMaxValue
			end
			functionData.sownType = sownType
			functionData.directSownType = directSownType
			functionData.ridgeTypeSown = ridgeTypeSown
			functionData.firstSowableValue = firstSowableValue
			functionData.lastSowableValue = lastSowableValue
			functionData.firstSowingValue = firstSowingValue
			functionData.lastSowingValue = lastSowingValue
			functionData.stubbleTillageFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
			functionData.stubbleTillageFilter:setValueCompareParams(DensityValueCompareType.EQUAL, stubbleTillagedType)
			functionData.directSownFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
			functionData.directSownFilter:setValueCompareParams(DensityValueCompareType.EQUAL, directSownType)
			functionData.sownFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
			functionData.sownFilter:setValueCompareParams(DensityValueCompareType.EQUAL, sownType)
			FSDensityMapUtil.functionCache.updateSowingArea = functionData
		end
		local fruitModifier = functionData.fruitModifiers[fruitIndex]
		if fruitModifier == nil then
			local terrainRootNode = g_terrainNode
			fruitModifier = DensityMapModifier.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels, terrainRootNode)
			local fruitFilter = DensityMapFilter.new(fruitModifier)
			functionData.fruitModifiers[fruitIndex] = fruitModifier
			functionData.fruitFilters[fruitIndex] = fruitFilter
		end
		local fruitFilter = functionData.fruitFilters[fruitIndex]
		local groundTypeModifier = functionData.groundTypeModifier
		local groundAngleModifier = functionData.groundAngleModifier
		local sowableFilter = functionData.sowableFilter
		local sowingFilter = functionData.sowingFilter
		local ridgeFilter = functionData.ridgeFilter
		local rollerLevelModifier = functionData.rollerLevelModifier
		local rollerLevelMaxValue = functionData.rollerLevelMaxValue
		local stubbleTillageFilter = functionData.stubbleTillageFilter
		local directSownFilter = functionData.directSownFilter
		local sownFilter = functionData.sownFilter
		local directSownType = functionData.directSownType
		local sownType = functionData.sownType
		local ridgeTypeSown = functionData.ridgeTypeSown
		local fieldTypeFilter = nil
		if desc.seedRequiredFieldType ~= nil then
			fieldTypeFilter = functionData.fieldTypeFilter
			fieldTypeFilter:setValueCompareParams(DensityValueCompareType.EQUAL, FieldType.getValueByType(desc.seedRequiredFieldType))
		end
		angle = angle or 0
		growthState = growthState or 1
		fieldGroundType = fieldGroundType or sownType
		fruitModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
		groundTypeModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
		groundAngleModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
		if Platform.gameplay.useRolling then
			rollerLevelModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
			local rollerLevelValue = 0
			if desc.needsRolling then
				rollerLevelValue = rollerLevelMaxValue
			end
			rollerLevelModifier:executeSet(rollerLevelValue, sowableFilter)
		end
		fruitFilter:setValueCompareParams(DensityValueCompareType.NOTEQUAL, growthState)
		local _, numPixels, _ = fruitModifier:executeSetWithStats(growthState, fruitFilter, sowableFilter, fieldTypeFilter)
		if g_currentMission.missionInfo.weedsEnabled then
			if desc.plantsWeed then
				FSDensityMapUtil.setSowingWeedArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
			else
				FSDensityMapUtil.removeWeedArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
			end
		end
		FSDensityMapUtil.removeSprayArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, blockedSprayTypeIndex, sowableFilter)
		FSDensityMapUtil.resetDisplacementArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
		local totalArea = 0
		if fieldGroundType ~= ridgeTypeSown then
			local _, _, totalAreaStubble = groundTypeModifier:executeSetWithStats(directSownType, sowableFilter, stubbleTillageFilter)
			totalArea = totalArea + totalAreaStubble
			local _, directArea, totalSownArea = groundTypeModifier:executeGet(directSownFilter)
			if 0 < totalSownArea and 0.5 < directArea / totalSownArea then
				groundTypeModifier:executeSet(directSownType, sownFilter)
			end
		end
		fruitFilter:setValueCompareParams(DensityValueCompareType.EQUAL, growthState)
		if ridgeSeeding then
			local _, _, totalAreaSown = groundTypeModifier:executeSetWithStats(ridgeTypeSown, ridgeFilter, fruitFilter)
			totalArea = totalArea + totalAreaSown
		end
		local _, _, totalAreaSown = groundTypeModifier:executeSetWithStats(fieldGroundType, sowableFilter, fruitFilter)
		totalArea = totalArea + totalAreaSown
		groundAngleModifier:executeSet(angle, sowingFilter, fruitFilter)
		return numPixels, totalArea
	end
end
function FSDensityMapUtil.updateDirectSowingArea(fruitIndex, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, fieldGroundType, ridgeSeeding, angle, growthState, blockedSprayTypeIndex)
	local fruitTypeManager = g_fruitTypeManager
	local desc = fruitTypeManager:getFruitTypeByIndex(fruitIndex)
	if desc.terrainDataPlaneId == nil then
		return 0, 0
	else
		angle = angle or 0
		growthState = growthState or 1
		local functionData = FSDensityMapUtil.functionCache.updateDirectSowingArea
		if functionData == nil then
			local terrainRootNode = g_terrainNode
			local fieldGroundSystem = g_currentMission.fieldGroundSystem
			local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
			local groundAngleMapId, groundAngleFirstChannel, groundAngleNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_ANGLE)
			local sprayLevelMapId, sprayLevelFirstChannel, sprayLevelNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_LEVEL)
			local sprayLevelMaxValue = fieldGroundSystem:getMaxValue(FieldDensityMap.SPRAY_LEVEL)
			local sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_TYPE)
			local sownType = FieldGroundType.getValueByType(FieldGroundType.SOWN)
			local directSownType = FieldGroundType.getValueByType(FieldGroundType.DIRECT_SOWN)
			local ridgeTypeSown = FieldGroundType.getValueByType(FieldGroundType.RIDGE_SOWN)
			local stubbleTillagedType = FieldGroundType.getValueByType(FieldGroundType.STUBBLE_TILLAGE)
			local firstSowableValue, lastSowableValue = fieldGroundSystem:getSowableRange()
			local firstSowingValue, lastSowingValue = fieldGroundSystem:getSowingRange()
			local rollerLevelMapId, rollerLevelFirstChannel, rollerLevelNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.ROLLER_LEVEL)
			local rollerLevelMaxValue = fieldGroundSystem:getMaxValue(FieldDensityMap.ROLLER_LEVEL)
			local fieldTypeMapId, fieldTypeFirstChannel, fieldTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.FIELD_TYPE)
			functionData = {}
			functionData.multiModifiers = {}
			functionData.fruitModifiers = {}
			functionData.fruitFilters = {}
			functionData.preparingModifier = {}
			functionData.preparingFilter = {}
			functionData.sprayLevelModifier = DensityMapModifier.new(sprayLevelMapId, sprayLevelFirstChannel, sprayLevelNumChannels, terrainRootNode)
			functionData.sprayLevelFilter = DensityMapFilter.new(sprayLevelMapId, sprayLevelFirstChannel, sprayLevelNumChannels)
			functionData.sprayLevelFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, 0, sprayLevelMaxValue - 1)
			functionData.sprayTypeModifier = DensityMapModifier.new(sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels, terrainRootNode)
			functionData.groundTypeModifier = DensityMapModifier.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, terrainRootNode)
			functionData.groundAngleModifier = DensityMapModifier.new(groundAngleMapId, groundAngleFirstChannel, groundAngleNumChannels, terrainRootNode)
			functionData.fieldFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
			functionData.fieldFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)
			functionData.groundTypeFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
			functionData.sowableFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
			functionData.sowableFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, firstSowableValue, lastSowableValue)
			functionData.sowingFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
			functionData.sowingFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, firstSowingValue, lastSowingValue)
			functionData.ridgeFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
			functionData.ridgeFilter:setValueCompareParams(DensityValueCompareType.EQUAL, FieldGroundType.getValueByType(FieldGroundType.RIDGE))
			functionData.stubbleTillageFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
			functionData.stubbleTillageFilter:setValueCompareParams(DensityValueCompareType.EQUAL, stubbleTillagedType)
			functionData.directSownFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
			functionData.directSownFilter:setValueCompareParams(DensityValueCompareType.EQUAL, directSownType)
			functionData.sownFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
			functionData.sownFilter:setValueCompareParams(DensityValueCompareType.EQUAL, sownType)
			functionData.fieldTypeFilter = DensityMapFilter.new(fieldTypeMapId, fieldTypeFirstChannel, fieldTypeNumChannels)
			if Platform.gameplay.useRolling then
				functionData.rollerLevelModifier = DensityMapModifier.new(rollerLevelMapId, rollerLevelFirstChannel, rollerLevelNumChannels, terrainRootNode)
				functionData.rollerLevelMaxValue = rollerLevelMaxValue
			end
			functionData.sownType = sownType
			functionData.directSownType = directSownType
			functionData.ridgeTypeSown = ridgeTypeSown
			FSDensityMapUtil.functionCache.updateDirectSowingArea = functionData
		end
		local sowableFilter = functionData.sowableFilter
		local sowingFilter = functionData.sowingFilter
		local ridgeFilter = functionData.ridgeFilter
		local fieldFilter = functionData.fieldFilter
		local groundTypeFilter = functionData.groundTypeFilter
		local ridgeTypeSown = functionData.ridgeTypeSown
		local directSownType = functionData.directSownType
		local stubbleTillageFilter = functionData.stubbleTillageFilter
		local directSownFilter = functionData.directSownFilter
		local sownFilter = functionData.sownFilter
		local sprayLevelModifier = functionData.sprayLevelModifier
		local sprayLevelFilter = functionData.sprayLevelFilter
		local sprayTypeModifier = functionData.sprayTypeModifier
		local groundTypeModifier = functionData.groundTypeModifier
		local groundAngleModifier = functionData.groundAngleModifier
		local fruitMultiModifier = functionData.multiModifiers[fruitIndex]
		local fruitModifier = functionData.fruitModifiers[fruitIndex]
		local terrainRootNode = g_terrainNode
		local rollerLevelModifier = functionData.rollerLevelModifier
		local rollerLevelMaxValue = functionData.rollerLevelMaxValue
		local fieldTypeFilter = nil
		if desc.seedRequiredFieldType ~= nil then
			fieldTypeFilter = functionData.fieldTypeFilter
			fieldTypeFilter:setValueCompareParams(DensityValueCompareType.EQUAL, FieldType.getValueByType(desc.seedRequiredFieldType))
		end
		if fruitMultiModifier == nil then
			fruitMultiModifier = {}
			functionData.multiModifiers[fruitIndex] = fruitMultiModifier
			fruitModifier = DensityMapModifier.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels, terrainRootNode)
			functionData.fruitModifiers[fruitIndex] = fruitModifier
		end
		local multiModifier = fruitMultiModifier[growthState]
		if multiModifier == nil then
			local stubbleTillagedType = FieldGroundType.getValueByType(FieldGroundType.STUBBLE_TILLAGE)
			multiModifier = DensityMapMultiModifier.new()
			fruitMultiModifier[growthState] = multiModifier
			for index, fruitDesc in pairs(fruitTypeManager:getFruitTypes()) do
				if fruitDesc.terrainDataPlaneId == nil then
					continue
				end
				if fruitDesc.isCultivationAllowed then
					local fruitFilter = functionData.fruitFilters[index]
					if fruitFilter == nil then
						fruitFilter = DensityMapFilter.new(fruitDesc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)
						functionData.fruitFilters[index] = fruitFilter
					end
					if 1 < fruitDesc.cutState then
						fruitFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, 2, fruitDesc.cutState - 1)
						multiModifier:addExecuteAdd(1, sprayLevelModifier, sprayLevelFilter, fieldFilter, fruitFilter)
						multiModifier:addExecuteSet(1, sprayTypeModifier, fieldFilter, fruitFilter)
					end
					if fruitDesc.allowsSeeding then
						if index ~= fruitIndex then
							fruitFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)
							multiModifier:addExecuteSet(stubbleTillagedType, groundTypeModifier, fieldFilter, fruitFilter)
						else
							fruitFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, growthState + 1, math.max(fruitDesc.maxHarvestingGrowthState, fruitDesc.cutState))
							multiModifier:addExecuteSet(stubbleTillagedType, groundTypeModifier, fieldFilter, fruitFilter)
						end
						if fruitDesc.mulchedState ~= nil and (0 < fruitDesc.mulchedState and fruitDesc.mulchedState ~= growthState) then
							fruitFilter:setValueCompareParams(DensityValueCompareType.EQUAL, fruitDesc.mulchedState)
							multiModifier:addExecuteSet(stubbleTillagedType, groundTypeModifier, fieldFilter, fruitFilter)
						end
					end
					if fruitDesc.terrainDataPlaneIdHaulm ~= nil then
						local preparingModifier = functionData.preparingModifier[index]
						if preparingModifier == nil then
							preparingModifier = DensityMapModifier.new(fruitDesc.terrainDataPlaneIdHaulm, fruitDesc.startStateChannelHaulm, fruitDesc.numStateChannelsHaulm)
							functionData.preparingModifier[index] = preparingModifier
						end
						local preparingFilter = functionData.preparingFilter[index]
						if preparingFilter == nil then
							preparingFilter = DensityMapFilter.new(fruitDesc.terrainDataPlaneIdHaulm, fruitDesc.startStateChannelHaulm, fruitDesc.numStateChannelsHaulm)
							preparingFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)
							preparingFilter:setTypeIndexCompareMode(DensityTypeCompareType.ALWAYS)
							functionData.preparingFilter[index] = preparingFilter
						end
						multiModifier:addExecuteSet(0, preparingModifier, preparingFilter)
					end
					local modifier = functionData.fruitModifiers[index]
					if modifier == nil then
						modifier = DensityMapModifier.new(fruitDesc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels, terrainRootNode)
						functionData.fruitModifiers[index] = modifier
					end
					if index ~= fruitIndex then
						fruitFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, 2, math.max(fruitDesc.maxHarvestingGrowthState, fruitDesc.cutState))
					else
						fruitFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, growthState + 1, math.max(fruitDesc.maxHarvestingGrowthState, fruitDesc.cutState))
					end
					multiModifier:addExecuteSet(0, modifier, fruitFilter, fieldFilter)
				end
			end
			local harvestReadyType = FieldGroundType.getValueByType(FieldGroundType.HARVEST_READY)
			groundTypeFilter:setValueCompareParams(DensityValueCompareType.EQUAL, harvestReadyType)
			multiModifier:addExecuteSet(stubbleTillagedType, groundTypeModifier, groundTypeFilter)
			local harvestReadyOtherType = FieldGroundType.getValueByType(FieldGroundType.HARVEST_READY_OTHER)
			groundTypeFilter:setValueCompareParams(DensityValueCompareType.EQUAL, harvestReadyOtherType)
			multiModifier:addExecuteSet(stubbleTillagedType, groundTypeModifier, groundTypeFilter)
			local grassType = FieldGroundType.getValueByType(FieldGroundType.GRASS)
			groundTypeFilter:setValueCompareParams(DensityValueCompareType.EQUAL, grassType)
			multiModifier:addExecuteSet(stubbleTillagedType, groundTypeModifier, groundTypeFilter)
			local grassCutType = FieldGroundType.getValueByType(FieldGroundType.GRASS_CUT)
			groundTypeFilter:setValueCompareParams(DensityValueCompareType.EQUAL, grassCutType)
			multiModifier:addExecuteSet(stubbleTillagedType, groundTypeModifier, groundTypeFilter)
			FSDensityMapUtil.multiModifierAddResetDisplacement(multiModifier)
		end
		fruitModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
		groundTypeModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
		groundAngleModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
		multiModifier:updateParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
		multiModifier:execute()
		if g_currentMission.missionInfo.weedsEnabled then
			if desc.plantsWeed then
				FSDensityMapUtil.setSowingWeedArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
			else
				FSDensityMapUtil.removeWeedArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
			end
		end
		if Platform.gameplay.useRolling then
			rollerLevelModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
			local rollerLevelValue = 0
			if desc.needsRolling then
				rollerLevelValue = rollerLevelMaxValue
			end
			rollerLevelModifier:executeSet(rollerLevelValue, sowableFilter)
		end
		local _, changedArea, totalArea = fruitModifier:executeSetWithStats(growthState, sowableFilter, fieldTypeFilter)
		if fieldGroundType ~= ridgeTypeSown then
			groundTypeModifier:executeSet(directSownType, sowableFilter, stubbleTillageFilter)
			local _, directArea, totalSownArea = groundTypeModifier:executeGet(directSownFilter)
			if 0 < totalSownArea and 0.5 < directArea / totalSownArea then
				groundTypeModifier:executeSet(directSownType, sownFilter)
			end
		end
		if ridgeSeeding then
			groundTypeModifier:executeSet(ridgeTypeSown, ridgeFilter)
		end
		groundTypeModifier:executeSet(fieldGroundType, sowableFilter, fieldTypeFilter)
		groundAngleModifier:executeSet(angle, sowingFilter)
		FSDensityMapUtil.removeSprayArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, blockedSprayTypeIndex)
		DensityMapHeightUtil.clearArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
		return changedArea, totalArea
	end
end
function FSDensityMapUtil.updateRidgeFormerArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, angle)
	local functionData = FSDensityMapUtil.functionCache.updateRidgeFormerArea
	if functionData == nil then
		local terrainRootNode = g_terrainNode
		local fieldGroundSystem = g_currentMission.fieldGroundSystem
		local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
		local groundAngleMapId, groundAngleFirstChannel, groundAngleNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_ANGLE)
		local ridgeType = FieldGroundType.getValueByType(FieldGroundType.RIDGE)
		local firstSowableValue, lastSowableValue = fieldGroundSystem:getSowableRange()
		functionData = {}
		functionData.groundTypeModifier = DensityMapModifier.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, terrainRootNode)
		functionData.groundAngleModifier = DensityMapModifier.new(groundAngleMapId, groundAngleFirstChannel, groundAngleNumChannels, terrainRootNode)
		local sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_TYPE)
		functionData.sprayTypeModifier = DensityMapModifier.new(sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels, terrainRootNode)
		functionData.sowableFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
		functionData.sowableFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, firstSowableValue, lastSowableValue)
		functionData.ridgeType = ridgeType
		functionData.ridgeFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
		functionData.ridgeFilter:setValueCompareParams(DensityValueCompareType.EQUAL, ridgeType)
		FSDensityMapUtil.functionCache.updateRidgeFormerArea = functionData
	end
	local groundTypeModifier = functionData.groundTypeModifier
	local groundAngleModifier = functionData.groundAngleModifier
	local sprayTypeModifier = functionData.sprayTypeModifier
	local sowableFilter = functionData.sowableFilter
	local ridgeFilter = functionData.ridgeFilter
	local ridgeType = functionData.ridgeType
	angle = angle or 0
	groundTypeModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	groundAngleModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	sprayTypeModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	sprayTypeModifier:executeSet(0, sowableFilter)
	local changedArea, totalArea, _ = groundTypeModifier:executeSetWithStats(ridgeType, sowableFilter)
	groundAngleModifier:executeSet(angle, ridgeFilter)
	return changedArea, totalArea
end
function FSDensityMapUtil.updateFruitPreparerArea(fruitId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, startDropWorldX, startDropWorldZ, widthDropWorldX, widthDropWorldZ, heightDropWorldX, heightDropWorldZ, limitToFruit)
	local functionData = FSDensityMapUtil.functionCache.updateFruitPreparerArea
	if functionData == nil then
		functionData = {}
		functionData.fruitModifiers = {}
		functionData.fruitFilters = {}
		functionData.dropModifiers = {}
		functionData.dropFilters = {}
		FSDensityMapUtil.functionCache.updateFruitPreparerArea = functionData
	end
	local desc = g_fruitTypeManager:getFruitTypeByIndex(fruitId)
	local fruitModifier = functionData.fruitModifiers[fruitId]
	if fruitModifier == nil then
		local terrainRootNode = g_terrainNode
		fruitModifier = DensityMapModifier.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels, terrainRootNode)
		functionData.fruitModifiers[fruitId] = fruitModifier
		functionData.fruitFilters[fruitId] = {}
		local fruitFilter = DensityMapFilter.new(fruitModifier)
		fruitFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, desc.minPreparingGrowthState, desc.maxPreparingGrowthState)
		functionData.fruitFilters[fruitId][true] = fruitFilter
		fruitFilter = DensityMapFilter.new(fruitModifier)
		fruitFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, 1, 15)
		functionData.fruitFilters[fruitId][false] = fruitFilter
		if desc.terrainDataPlaneIdHaulm ~= nil then
			local dropModifier = DensityMapModifier.new(desc.terrainDataPlaneIdHaulm, 0, 1, terrainRootNode)
			functionData.dropModifiers[fruitId] = dropModifier
		end
	end
	local fruitFilter = functionData.fruitFilters[fruitId][true]
	fruitModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	local dropModifier = nil
	if desc.terrainDataPlaneIdHaulm ~= nil then
		dropModifier = functionData.dropModifiers[fruitId]
		dropModifier:setParallelogramWorldCoords(startDropWorldX, startDropWorldZ, widthDropWorldX, widthDropWorldZ, heightDropWorldX, heightDropWorldZ, DensityCoordType.POINT_POINT_POINT)
	end
	if dropModifier ~= nil then
		if limitToFruit == nil then
			limitToFruit = true
		end
		local dropFilter = functionData.fruitFilters[fruitId][limitToFruit]
		dropModifier:executeSet(1, dropFilter)
	end
	local _, numChangedPixels = fruitModifier:executeSetWithStats(desc.preparedGrowthState, fruitFilter)
	return numChangedPixels
end
function FSDensityMapUtil.clearDecoArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	local functionData = FSDensityMapUtil.functionCache.clearDecoArea
	if functionData == nil then
		local decoFoliages = nil
		if g_currentMission.foliageSystem ~= nil then
			decoFoliages = g_currentMission.foliageSystem:getDecoFoliages()
		end
		local terrainRootNode = g_terrainNode
		if decoFoliages ~= nil and 0 < #decoFoliages then
			functionData = {}
			functionData.decoModifiers = {}
			functionData.decoFilters = {}
			functionData.decoFoliages = decoFoliages
			for index, decoFoliage in pairs(decoFoliages) do
				if decoFoliage.terrainDataPlaneId == nil then
					continue
				end
				local decoModifier = DensityMapModifier.new(decoFoliage.terrainDataPlaneId, decoFoliage.startStateChannel, decoFoliage.numStateChannels, terrainRootNode)
				decoModifier:setNewTypeIndexMode(DensityIndexCompareMode.ZERO)
				local decoFilter = DensityMapFilter.new(decoFoliage.terrainDataPlaneId, decoFoliage.startStateChannel, decoFoliage.numStateChannels)
				decoFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)
				functionData.decoModifiers[index] = decoModifier
				functionData.decoFilters[index] = decoFilter
			end
			FSDensityMapUtil.functionCache.clearDecoArea = functionData
		end
	end
	if functionData ~= nil then
		local area = 0
		local totalArea = 0
		local nonMowableCut = false
		for index, decoFoliage in pairs(functionData.decoFoliages) do
			if decoFoliage.terrainDataPlaneId == nil then
				continue
			end
			local decoModifier = functionData.decoModifiers[index]
			local decoFilter = functionData.decoFilters[index]
			if decoModifier == nil or decoFilter == nil then
				continue
			end
			decoModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
			local _, _area, _totalArea = decoModifier:executeSetWithStats(0, decoFilter)
			area = area + _area
			totalArea = totalArea + _totalArea
			if 0 < _area then
				if decoFoliage.mowable then
					continue
				end
				nonMowableCut = true
			end
		end
		return area, totalArea, nonMowableCut
	else
		return 0, 0, false
	end
end
function FSDensityMapUtil.createVineArea(fruitId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, customState, ignoreExistingFruits)
	local functionData = FSDensityMapUtil.functionCache.createVineArea
	if functionData == nil then
		functionData = {}
		functionData.fruitData = {}
		local stoneSystem = g_currentMission.stoneSystem
		if stoneSystem:getMapHasStones() then
			local terrainRootNode = g_terrainNode
			local stoneMapId, stoneFirstChannel, stoneNumChannels = stoneSystem:getDensityMapData()
			functionData.stoneModifier = DensityMapModifier.new(stoneMapId, stoneFirstChannel, stoneNumChannels, terrainRootNode)
		end
		if Platform.gameplay.useLimeCounter then
			local fieldGroundSystem = g_currentMission.fieldGroundSystem
			local terrainRootNode = g_terrainNode
			local limeLevelMapId, limeLevelFirstChannel, limeLevelNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.LIME_LEVEL)
			if limeLevelMapId ~= nil then
				functionData.limeLevelModifier = DensityMapModifier.new(limeLevelMapId, limeLevelFirstChannel, limeLevelNumChannels, terrainRootNode)
				functionData.limeLevelMaxValue = fieldGroundSystem:getMaxValue(FieldDensityMap.LIME_LEVEL)
			end
		end
		FSDensityMapUtil.functionCache.createVineArea = functionData
	end
	local fruitData = functionData.fruitData[fruitId]
	if fruitData == nil then
		local terrainRootNode = g_terrainNode
		local desc = g_fruitTypeManager:getFruitTypeByIndex(fruitId)
		local fieldGroundSystem = g_currentMission.fieldGroundSystem
		local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
		local grassType = FieldGroundType.getValueByType(FieldGroundType.GRASS)
		if desc.terrainDataPlaneId == nil then
			return 0
		end
		fruitData = {}
		fruitData.fruitModifier = DensityMapModifier.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels, terrainRootNode)
		fruitData.fruitModifier:setPolygonRoundingMode(DensityRoundingMode.NEAREST)
		fruitData.fruitFilter = DensityMapFilter.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)
		fruitData.fruitFilter:setValueCompareParams(DensityValueCompareType.EQUAL, 0)
		fruitData.groundModifier = DensityMapModifier.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, terrainRootNode)
		fruitData.groundModifier:setPolygonRoundingMode(DensityRoundingMode.NEAREST)
		fruitData.grassType = grassType
		functionData.fruitData[fruitId] = fruitData
	end
	local fruitModifier = fruitData.fruitModifier
	local fruitFilter = fruitData.fruitFilter
	local groundModifier = fruitData.groundModifier
	local grassType = fruitData.grassType
	local stoneModifier = functionData.stoneModifier
	local limeLevelModifier = functionData.limeLevelModifier
	fruitModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	groundModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	FSDensityMapUtil.updateDestroyCommonArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, false, false)
	if stoneModifier ~= nil then
		stoneModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
		stoneModifier:executeSet(0)
	end
	if limeLevelModifier ~= nil then
		limeLevelModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
		limeLevelModifier:executeSet(functionData.limeLevelMaxValue)
	end
	if ignoreExistingFruits then
		fruitFilter = nil
	end
	local _, area = fruitModifier:executeSetWithStats(customState or 1, fruitFilter)
	groundModifier:executeSet(grassType)
	return area
end
function FSDensityMapUtil.destroyVineArea(fruitId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	local functionData = FSDensityMapUtil.functionCache.destroyVineArea
	if functionData == nil then
		local terrainRootNode = g_terrainNode
		local fieldGroundSystem = g_currentMission.fieldGroundSystem
		local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
		functionData = {}
		functionData.groundModifier = DensityMapModifier.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, terrainRootNode)
		functionData.groundModifier:setPolygonRoundingMode(DensityRoundingMode.NEAREST)
		FSDensityMapUtil.functionCache.destroyVineArea = functionData
	end
	local groundModifier = functionData.groundModifier
	FSDensityMapUtil.updateDestroyCommonArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, false, true)
	groundModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	groundModifier:executeSet(0)
end
function FSDensityMapUtil.updateVineAreaValues(fruitId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, values)
	local functionData = FSDensityMapUtil.functionCache.updateVineAreaValues
	if functionData == nil then
		functionData = {}
		functionData.fruitData = {}
		FSDensityMapUtil.functionCache.updateVineAreaValues = functionData
	end
	local fruitData = functionData.fruitData[fruitId]
	if fruitData == nil then
		fruitData = {}
		local terrainRootNode = g_terrainNode
		local desc = g_fruitTypeManager:getFruitTypeByIndex(fruitId)
		if desc.terrainDataPlaneId == nil then
			for i = 0, desc.numStateChannels ^ 2 - 1 do
				values[i] = 0
			end
			return 0
		end
		fruitData.modifier = DensityMapModifier.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels, terrainRootNode)
		fruitData.modifier:setPolygonRoundingMode(DensityRoundingMode.NEAREST)
		fruitData.filters = {}
		for i = 0, desc.numStateChannels ^ 2 - 1 do
			fruitData.filters[i] = DensityMapFilter.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)
			fruitData.filters[i]:setValueCompareParams(DensityValueCompareType.EQUAL, i)
		end
		functionData.fruitData[fruitId] = fruitData
	end
	fruitData.modifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	local totalArea = 0
	for state, _ in pairs(values) do
		local filter = fruitData.filters[state]
		local _, area, tArea = fruitData.modifier:executeGet(filter)
		values[state] = area
		totalArea = math.max(totalArea, tArea)
	end
	return totalArea
end
function FSDensityMapUtil:setVineAreaValue(fruitId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, value)
	local functionData = FSDensityMapUtil.functionCache.setVineAreaValue
	if functionData == nil then
		functionData = {}
		functionData.fruitData = {}
		FSDensityMapUtil.functionCache.setVineAreaValue = functionData
	end
	local fruitData = functionData.fruitData[fruitId]
	if fruitData == nil then
		fruitData = {}
		local terrainRootNode = g_terrainNode
		local desc = g_fruitTypeManager:getFruitTypeByIndex(fruitId)
		fruitData.modifier = DensityMapModifier.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels, terrainRootNode)
		functionData.fruitData[fruitId] = fruitData
	end
	fruitData.modifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	fruitData.modifier:executeSet(value)
end
function FSDensityMapUtil.updateVineCutArea(fruitId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	local functionData = FSDensityMapUtil.functionCache.updateVineCutArea
	local desc = g_fruitTypeManager:getFruitTypeByIndex(fruitId)
	if functionData == nil then
		local terrainRootNode = g_terrainNode
		local fieldGroundSystem = g_currentMission.fieldGroundSystem
		local sprayLevelMapId, sprayLevelFirstChannel, sprayLevelNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_LEVEL)
		functionData = {}
		functionData.fruitData = {}
		functionData.sprayLevelMaxValue = fieldGroundSystem:getMaxValue(FieldDensityMap.SPRAY_LEVEL)
		functionData.sprayLevelModifier = DensityMapModifier.new(sprayLevelMapId, sprayLevelFirstChannel, sprayLevelNumChannels, terrainRootNode)
		if Platform.gameplay.usePlowCounter then
			local plowLevelMapId, plowLevelFirstChannel, plowLevelNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.PLOW_LEVEL)
			local plowLevelModifier = DensityMapModifier.new(plowLevelMapId, plowLevelFirstChannel, plowLevelNumChannels, terrainRootNode)
			functionData.plowLevelModifier = plowLevelModifier
		end
		functionData.sprayLevelFilters = {}
		for i = 1, functionData.sprayLevelMaxValue do
			local sprayLevelFilter = DensityMapFilter.new(sprayLevelMapId, sprayLevelFirstChannel, sprayLevelNumChannels)
			sprayLevelFilter:setValueCompareParams(DensityValueCompareType.EQUAL, i)
			functionData.sprayLevelFilters[i] = sprayLevelFilter
		end
		FSDensityMapUtil.functionCache.updateVineCutArea = functionData
	end
	local fruitData = functionData.fruitData[fruitId]
	if fruitData == nil then
		fruitData = {}
		local terrainRootNode = g_terrainNode
		if desc.terrainDataPlaneId == nil then
			return 0
		end
		fruitData.fruitModifier = DensityMapModifier.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels, terrainRootNode)
		fruitData.fruitModifier:setPolygonRoundingMode(DensityRoundingMode.NEAREST)
		fruitData.transitionFilters = {}
		for src, target in pairs(desc.harvestTransitions) do
			local harvestFilter = DensityMapFilter.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)
			harvestFilter:setValueCompareParams(DensityValueCompareType.EQUAL, src)
			fruitData.transitionFilters[target] = harvestFilter
		end
		fruitData.harvestFilter = DensityMapFilter.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)
		fruitData.harvestFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, desc.minHarvestingGrowthState, desc.maxHarvestingGrowthState)
		if desc.harvestWeedState ~= -1 then
			fruitData.weedFilter = DensityMapFilter.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)
			fruitData.weedFilter:setValueCompareParams(DensityValueCompareType.EQUAL, desc.harvestWeedState)
		end
		functionData.fruitData[fruitId] = fruitData
	end
	local fruitModifier = fruitData.fruitModifier
	local transitionFilters = fruitData.transitionFilters
	local weedFilter = fruitData.weedFilter
	local harvestFilter = fruitData.harvestFilter
	local sprayLevelModifier = functionData.sprayLevelModifier
	local sprayLevelMaxValue = functionData.sprayLevelMaxValue
	local plowLevelModifier = functionData.plowLevelModifier
	local sprayLevelFilters = functionData.sprayLevelFilters
	fruitModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	sprayLevelModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	local _ = nil
	local sprayLevel = 0
	for i, filter in pairs(sprayLevelFilters) do
		local _, sprayLevelArea, _ = sprayLevelModifier:executeGet(filter)
		if 0 < sprayLevelArea and sprayLevel < i then
			sprayLevel = i
		end
	end
	FSDensityMapUtil.resetSprayArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, true, nil)
	sprayLevelModifier:executeSet(0, harvestFilter)
	if 0 < desc.startSprayLevel then
		sprayLevelModifier:executeSet(math.min(desc.startSprayLevel, sprayLevelMaxValue), harvestFilter)
		FSDensityMapUtil.resetSprayArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, true, nil)
	end
	local weedArea = 0
	if weedFilter ~= nil then
		_, weedArea, _ = fruitModifier:executeGet(weedFilter)
	end
	local plowArea = 0
	local plowLevel = 0
	if plowLevelModifier ~= nil then
		plowLevelModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
		plowLevel, _, _ = plowLevelModifier:executeAddWithStats(-1, harvestFilter)
	end
	local area = 0
	local totalArea = nil
	local filterArea = nil
	for target, filter in pairs(transitionFilters) do
		_, filterArea, totalArea = fruitModifier:executeSetWithStats(target, filter)
		area = area + filterArea
	end
	if 0 < plowLevel then
		plowArea = area
	end
	if weedArea < totalArea then
		weedArea = 0
	end
	local weedFactor = 1 - weedArea / totalArea
	local sprayFactor = sprayLevel / sprayLevelMaxValue
	local plowFactor = plowArea / totalArea
	return area, totalArea, weedFactor, sprayFactor, plowFactor
end
function FSDensityMapUtil.updateVinePrepareArea(fruitId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	local functionData = FSDensityMapUtil.functionCache.updateVinePrepareArea
	if functionData == nil then
		functionData = {}
		functionData.fruitData = {}
		FSDensityMapUtil.functionCache.updateVinePrepareArea = functionData
	end
	local fruitData = functionData.fruitData[fruitId]
	if fruitData == nil then
		local terrainRootNode = g_terrainNode
		local desc = g_fruitTypeManager:getFruitTypeByIndex(fruitId)
		if desc.terrainDataPlaneId == nil then
			return 0
		end
		if desc.witheredState == nil then
			return 0
		end
		fruitData = {}
		fruitData.fruitModifier = DensityMapModifier.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels, terrainRootNode)
		fruitData.fruitModifier:setPolygonRoundingMode(DensityRoundingMode.NEAREST)
		fruitData.fruitFilter = DensityMapFilter.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)
		fruitData.fruitFilter:setValueCompareParams(DensityValueCompareType.EQUAL, desc.witheredState)
		functionData.fruitData[fruitId] = fruitData
	end
	local fruitModifier = fruitData.fruitModifier
	local fruitFilter = fruitData.fruitFilter
	fruitModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	local _, area, totalArea = fruitModifier:executeSetWithStats(1, fruitFilter)
	return area, totalArea
end
function FSDensityMapUtil.resetVineArea(fruitId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, resetState)
	local functionData = FSDensityMapUtil.functionCache.resetVineArea
	if functionData == nil then
		functionData = {}
		functionData.fruitData = {}
		FSDensityMapUtil.functionCache.resetVineArea = functionData
	end
	local fruitData = functionData.fruitData[fruitId]
	if fruitData == nil then
		fruitData = {}
		local terrainRootNode = g_terrainNode
		local desc = g_fruitTypeManager:getFruitTypeByIndex(fruitId)
		if desc.terrainDataPlaneId == nil then
			return 0
		end
		fruitData.fruitModifier = DensityMapModifier.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels, terrainRootNode)
		fruitData.fruitModifier:setPolygonRoundingMode(DensityRoundingMode.NEAREST)
		fruitData.fruitFilter = DensityMapFilter.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)
		fruitData.fruitFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)
		functionData.fruitData[fruitId] = fruitData
	end
	local fruitModifier = fruitData.fruitModifier
	local fruitFilter = fruitData.fruitFilter
	fruitModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	local _, area, totalArea = fruitModifier:executeSetWithStats(resetState, fruitFilter)
	return area, totalArea
end
function FSDensityMapUtil.updateVineCultivatorArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, changeGroundType)
	local functionData = FSDensityMapUtil.functionCache.updateVineCultivatorArea
	if changeGroundType == nil then
		changeGroundType = true
	end
	if functionData == nil then
		local terrainRootNode = g_terrainNode
		local fieldGroundSystem = g_currentMission.fieldGroundSystem
		local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
		local cultivatedType = FieldGroundType.getValueByType(FieldGroundType.CULTIVATED)
		local groundModifier = DensityMapModifier.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, terrainRootNode)
		functionData = {}
		functionData.fruitData = {}
		functionData.groundModifier = groundModifier
		functionData.groundFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
		functionData.groundFilter:setValueCompareParams(DensityValueCompareType.EQUAL, cultivatedType)
		local multiModifiers = {}
		multiModifiers[true] = DensityMapMultiModifier.new()
		multiModifiers[false] = DensityMapMultiModifier.new()
		local fruitFilter = nil
		local plowLevelModifier = nil
		if Platform.gameplay.usePlowCounter then
			local plowLevelMapId, plowLevelFirstChannel, plowLevelNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.PLOW_LEVEL)
			plowLevelModifier = DensityMapModifier.new(plowLevelMapId, plowLevelFirstChannel, plowLevelNumChannels, terrainRootNode)
		end
		for index, desc in pairs(g_fruitTypeManager:getFruitTypes()) do
			if desc.terrainDataPlaneId == nil or desc.cultivationStates == nil then
				continue
			end
			if fruitFilter == nil then
				fruitFilter = DensityMapFilter.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)
			else
				fruitFilter:resetDensityMapAndChannels(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)
			end
			for _, state in ipairs(desc.cultivationStates) do
				fruitFilter:setValueCompareParams(DensityValueCompareType.EQUAL, state)
				multiModifiers[true]:addExecuteSet(cultivatedType, groundModifier, fruitFilter)
				if plowLevelModifier == nil then
					continue
				end
				multiModifiers[true]:addExecuteAdd(1, plowLevelModifier, fruitFilter)
				multiModifiers[false]:addExecuteAdd(1, plowLevelModifier, fruitFilter)
			end
		end
		functionData.multiModifiers = multiModifiers
		FSDensityMapUtil.functionCache.updateVineCultivatorArea = functionData
	end
	local multiModifiers = functionData.multiModifiers
	local groundModifier = functionData.groundModifier
	local groundFilter = functionData.groundFilter
	groundModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	local _, areaBefore, _ = groundModifier:executeGet(groundFilter)
	multiModifiers[changeGroundType]:updateParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	multiModifiers[changeGroundType]:execute()
	local _, areaAfter, _ = groundModifier:executeGet(groundFilter)
	FSDensityMapUtil.removeWeedArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	return areaAfter - areaBefore
end
function FSDensityMapUtil.updateDisasterArea(densityMapArea, perlinPercentage)
	local functionData = FSDensityMapUtil.functionCache.updateDisasterArea
	if functionData == nil then
		local fieldGroundSystem = g_currentMission.fieldGroundSystem
		local groundTypeMapId, _, _ = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
		functionData = {}
		functionData.perlinFilters = {}
		functionData.multiModifiers = {}
		functionData.perlinFilter = PerlinNoiseFilter.new(groundTypeMapId, 11, 1, 0.5, math.random(0, 10000))
		FSDensityMapUtil.functionCache.updateDisasterArea = functionData
	end
	local multiModifier = functionData.multiModifiers[perlinPercentage]
	if multiModifier == nil then
		local perlinFilter = functionData.perlinFilter
		perlinFilter:setValueCompareParams(DensityValueCompareType.GREATER, perlinPercentage)
		multiModifier = DensityMapMultiModifier.new()
		local fruitFilter = nil
		local fruitModifier = nil
		for index, desc in pairs(g_fruitTypeManager:getFruitTypes()) do
			if desc.terrainDataPlaneId == nil or desc.minDisasterDestructionState == nil then
				continue
			end
			if fruitFilter == nil then
				fruitFilter = DensityMapFilter.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)
			else
				fruitFilter:resetDensityMapAndChannels(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)
			end
			fruitFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, desc.minDisasterDestructionState, desc.maxDisasterDestructionState)
			if fruitModifier == nil then
				fruitModifier = DensityMapModifier.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)
			else
				fruitModifier:resetDensityMapAndChannels(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)
			end
			if desc.disasterDestructionState == 0 then
				fruitModifier:setNewTypeIndexMode(DensityIndexCompareMode.ZERO)
			else
				fruitModifier:setNewTypeIndexMode(DensityIndexCompareMode.KEEP)
			end
			multiModifier:addExecuteSet(desc.disasterDestructionState, fruitModifier, fruitFilter, perlinFilter)
		end
		local weedSystem = g_currentMission.weedSystem
		local weedMapId, weedFirstChannel, weedNumChannels = weedSystem:getDensityMapData()
		local weedModifier = DensityMapModifier.new(weedMapId, weedFirstChannel, weedNumChannels, g_terrainNode)
		multiModifier:addExecuteSet(0, weedModifier, perlinFilter)
		local fieldGroundSystem = g_currentMission.fieldGroundSystem
		local groundTypeMapId, firstChannel, numChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
		local groundModifier = DensityMapModifier.new(groundTypeMapId, firstChannel, numChannels, g_terrainNode)
		local groundFilter = DensityMapFilter.new(groundTypeMapId, firstChannel, numChannels)
		local groundTypeSown = FieldGroundType.getValueByType(FieldGroundType.SOWN)
		local groundTypeHarvestReady = FieldGroundType.getValueByType(FieldGroundType.HARVEST_READY)
		groundFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, groundTypeSown, groundTypeHarvestReady)
		local groundType = FieldGroundType.getValueByType(FieldGroundType.HARVEST_READY_OTHER)
		multiModifier:addExecuteSet(groundType, groundModifier, perlinFilter, groundFilter)
		functionData.multiModifiers[perlinPercentage] = multiModifier
	end
	densityMapArea:applyToModifier(multiModifier)
	multiModifier:execute()
end
function FSDensityMapUtil.eraseTireTrack(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	local tireTrackSystem = g_currentMission.tireTrackSystem
	if tireTrackSystem ~= nil then
		tireTrackSystem:eraseParallelogram(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	end
end
function FSDensityMapUtil.getAreaDensity(id, firstChannel, numChannels, value, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	local functionData = FSDensityMapUtil.functionCache.getAreaDensity
	if functionData == nil then
		local fieldGroundSystem = g_currentMission.fieldGroundSystem
		local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
		functionData = {}
		functionData.filter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
		functionData.densityMapIdToModifier = {}
		FSDensityMapUtil.functionCache.getAreaDensity = functionData
	end
	local modifier = functionData.densityMapIdToModifier[id]
	local filter = functionData.filter
	if modifier == nil then
		local terrainRootNode = g_terrainNode
		modifier = DensityMapModifier.new(id, firstChannel, numChannels, terrainRootNode)
		functionData.densityMapIdToModifier[id] = modifier
	end
	modifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	filter:setValueCompareParams(DensityValueCompareType.EQUAL, value)
	local accumulator, numMatchingPixels, totalNumPixels = modifier:executeGet(filter)
	return accumulator, numMatchingPixels, totalNumPixels
end
function FSDensityMapUtil.getFruitTypeIndexAtWorldPos(x, z)
	local dataPlaneId = g_fruitTypeManager:getDefaultDataPlaneId()
	if dataPlaneId ~= nil then
		local densityTypeIndex = getDensityTypeIndexAtWorldPos(dataPlaneId, x, 0, z)
		local desc = g_fruitTypeManager:getFruitTypeByDensityTypeIndex(densityTypeIndex)
		if desc ~= nil then
			local state = getDensityStatesAtWorldPos(dataPlaneId, x, 0, z)
			local growthState = desc:getGrowthStateByDensityState(state)
			return desc.index, growthState
		end
	end
	return nil
end
function FSDensityMapUtil.getIsFieldAtWorldPos(x, z)
	local isOnField = getDensityAtWorldPos(g_currentMission.terrainDetailId, x, 0, z) ~= 0
	return isOnField
end
function FSDensityMapUtil.getFieldTypeAtWorldPos(x, z)
	local fieldGroundSystem = g_currentMission.fieldGroundSystem
	local fieldTypeMapId, fieldTypeFirstChannel, fieldTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.FIELD_TYPE)
	local width, height = getBitVectorMapSize(fieldTypeMapId)
	local terrainSize = g_currentMission.terrainSize
	x = math.floor(width * (x + terrainSize * 0.5) / terrainSize)
	z = math.floor(height * (z + terrainSize * 0.5) / terrainSize)
	return getBitVectorMapPoint(fieldTypeMapId, x, z, fieldTypeFirstChannel, fieldTypeNumChannels) + 1
end
function FSDensityMapUtil.getFieldDensity(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	local functionData = FSDensityMapUtil.functionCache.getFieldDensity
	if functionData == nil then
		local terrainRootNode = g_terrainNode
		local fieldGroundSystem = g_currentMission.fieldGroundSystem
		local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
		functionData = {}
		functionData.modifier = DensityMapModifier.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, terrainRootNode)
		functionData.filter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
		functionData.filter:setValueCompareParams(DensityValueCompareType.GREATER, 0)
		FSDensityMapUtil.functionCache.getFieldDensity = functionData
	end
	local modifier = functionData.modifier
	local filter = functionData.filter
	modifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	local accumulator, numMatchingPixels, totalNumPixels = modifier:executeGet(filter)
	return accumulator, numMatchingPixels, totalNumPixels
end
function FSDensityMapUtil.getBushDensity(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	local functionData = FSDensityMapUtil.functionCache.getBushDensity
	if functionData == nil then
		local bushId, _ = getTerrainDataPlaneByName(g_terrainNode, "decoBush")
		if bushId ~= 0 then
			local terrainRootNode = g_terrainNode
			functionData = {}
			functionData.modifier = DensityMapModifier.new(bushId, 0, 4, terrainRootNode)
			functionData.modifier:setReturnValueShift(-1)
			local filter = DensityMapFilter.new(bushId, 0, 4)
			filter:setValueCompareParams(DensityValueCompareType.GREATER, 0)
			functionData.filter = filter
			FSDensityMapUtil.functionCache.getBushDensity = functionData
		else
			return 0, 0, 0
		end
	end
	local modifier = functionData.modifier
	local filter = functionData.filter
	modifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	local accumulator, numMatchingPixels, totalNumPixels = modifier:executeGet(filter)
	return accumulator, numMatchingPixels, totalNumPixels
end
function FSDensityMapUtil.convertToDensityMapAngle(angle, maxDensityValue)
	local value = math.floor(angle / 3.141592653589793 * (maxDensityValue + 1) + 0.5)
	while maxDensityValue < value do
		value = value - (maxDensityValue + 1)
	end
	while value < 0 do
		value = value + (maxDensityValue + 1)
	end
	return value
end
function FSDensityMapUtil.getWeedFactor(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, fruitIndex)
	local weedFactor = 0
	local weedSystem = g_currentMission.weedSystem
	if weedSystem:getMapHasWeed() then
		local functionData = FSDensityMapUtil.functionCache.getWeedFactor
		if functionData == nil then
			local terrainRootNode = g_terrainNode
			local fieldGroundSystem = g_currentMission.fieldGroundSystem
			local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
			local weedMapId, weedFirstChannel, weedNumChannels = weedSystem:getDensityMapData()
			local factors = weedSystem:getFactors()
			functionData = {}
			functionData.weedModifier = DensityMapModifier.new(weedMapId, weedFirstChannel, weedNumChannels, terrainRootNode)
			functionData.fieldFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
			functionData.fieldFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)
			functionData.fruitFilters = {}
			functionData.weedStateFilters = {}
			for state, factor in pairs(factors) do
				local filter = DensityMapFilter.new(weedMapId, weedFirstChannel, weedNumChannels)
				filter:setValueCompareParams(DensityValueCompareType.EQUAL, state)
				functionData.weedStateFilters[filter] = factor
			end
			FSDensityMapUtil.functionCache.getWeedFactor = functionData
		end
		local weedModifier = functionData.weedModifier
		local weedStateFilters = functionData.weedStateFilters
		local fieldFilter = functionData.fieldFilter
		local _ = nil
		local pixels = nil
		local totalPixels = nil
		local fruitFilter = nil
		if fruitIndex ~= nil then
			fruitFilter = functionData.fruitFilters[fruitIndex]
			if fruitFilter == nil then
				local desc = g_fruitTypeManager:getFruitTypeByIndex(fruitIndex)
				fruitFilter = DensityMapFilter.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)
				fruitFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, desc.minForageGrowthState or desc.minHarvestingGrowthState, desc.maxHarvestingGrowthState)
				functionData.fruitFilters[fruitIndex] = fruitFilter
			end
		end
		weedModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
		_, totalPixels, _ = weedModifier:executeGet(fieldFilter, fruitFilter)
		if totalPixels ~= 0 then
			for filter, factor in pairs(weedStateFilters) do
				_, pixels, _ = weedModifier:executeGet(filter, fieldFilter, fruitFilter)
				weedFactor = weedFactor + pixels / totalPixels * factor
			end
		end
	end
	return weedFactor
end
function FSDensityMapUtil.assert(bool, warning)
	if FSDensityMapUtil.DEBUG_ENABLED then
		assert(bool, warning)
	end
end
function FSDensityMapUtil.runBenchmark()
	local size = 128
	local startWorldX = -128
	local startWorldZ = -128
	local widthWorldX = -128
	local heightWorldZ = -128
	local tests = {}
	table.insert(tests, {
		name = "FSDensityMapUtil.updateRollerArea",
		func = function()
			FSDensityMapUtil.updateRollerArea(-128, -128, -128, 128, 128, -128, 0)
		end,
	})
	for _, test in ipairs(tests) do
		Logging.info("Benchmark-Start - %s - Size %dx%dm", test.name, 128, 128)
		local numRuns = 10
		local durationTotal = 0
		for i = 1, 10 do
			local timeBefore = getTimeSec()
			test.func()
			local timeAfter = getTimeSec()
			local duration = (timeAfter - timeBefore) * 1000
			durationTotal = durationTotal + duration
			Logging.info("    Run %d - Time: %.4fms", i, duration)
		end
		Logging.info("Benchmark-Finished - Avg. Time: %.4fms", durationTotal / 10)
	end
end
