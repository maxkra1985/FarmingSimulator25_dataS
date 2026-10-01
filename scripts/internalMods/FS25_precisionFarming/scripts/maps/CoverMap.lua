CoverMap = {}
CoverMap.MOD_NAME = g_currentModName
local CoverMap_mt = Class(CoverMap, ValueMap)
source(g_currentModDirectory .. "scripts/densityMapUpdates/CoverMapDensityMapTask.lua")
function CoverMap.new(pfModule, customMt)
	local self = ValueMap.new(pfModule, customMt or CoverMap_mt)
	self.name = "coverMap"
	if g_server ~= nil then
		addConsoleCommand("pfUncoverField", "Uncovers given field", "debugUncoverField", self)
		addConsoleCommand("pfUncoverAll", "Uncovers all fields", "debugUncoverAll", self)
		addConsoleCommand("pfReduceCoverState", "Reduces cover State for given field", "debugReduceCoverStateField", self)
		addConsoleCommand("pfReduceCoverStateAll", "Reduces cover State for all fields", "debugReduceCoverStateAll", self)
	end
	return self
end
function CoverMap:initialize()
	CoverMap:superClass().initialize(self)
	self.densityMapModifiersAnalyse = {}
	self.densityMapModifiersUncover = nil
	self.densityMapModifiersFarmlandState = {}
	self.densityMapModifiersUpdate = nil
	self.densityMapModifiersResetLock = {}
end
function CoverMap:delete()
	if g_server ~= nil then
		removeConsoleCommand("pfUncoverField")
		removeConsoleCommand("pfUncoverAll")
		removeConsoleCommand("pfReduceCoverState")
		removeConsoleCommand("pfReduceCoverStateAll")
	end
	CoverMap:superClass().delete(self)
end
function CoverMap:loadFromXML(xmlFile, key, baseDirectory, configFileName, mapFilename)
	key = key .. ".coverMap"
	self.sizeX = getXMLInt(xmlFile, key .. "#sizeX") or 1024
	self.sizeY = getXMLInt(xmlFile, key .. "#sizeY") or 1024
	self.lockChannel = getXMLInt(xmlFile, key .. "#lockChannel") or 0
	self.firstChannel = getXMLInt(xmlFile, key .. "#firstChannel") or 1
	self.numChannels = getXMLInt(xmlFile, key .. "#numChannels") or 4
	self.maxValue = 2 ^ self.numChannels - 1
	self.maxValue = getXMLInt(xmlFile, key .. "#maxValue") or self.maxValue
	self.sampledValue = self.maxValue + 1
	self.bitVectorMap = self:loadSavedBitVectorMap("coverMap", "precisionFarming_coverMap.grle", self.firstChannel + self.numChannels, self.sizeX)
	self:addBitVectorMapToSync(self.bitVectorMap)
	self:addBitVectorMapToSave(self.bitVectorMap, "precisionFarming_coverMap.grle")
	self:addBitVectorMapToDelete(self.bitVectorMap)
	self.bitVectorMapSoilSampleFarmId = self:loadSavedBitVectorMap("soilSampleFarmIdMap", "precisionFarming_soilSampleFarmIdMap.grle", 4, self.sizeX)
	self:addBitVectorMapToSave(self.bitVectorMapSoilSampleFarmId, "precisionFarming_soilSampleFarmIdMap.grle")
	self:addBitVectorMapToDelete(self.bitVectorMapSoilSampleFarmId)
	self.bitVectorMapTempHarvestLock = self:loadSavedBitVectorMap("bitVectorMapTempHarvestLock", "bitVectorMapTempHarvestLock.grle", 1, self.sizeX)
	self:addBitVectorMapToDelete(self.bitVectorMapTempHarvestLock)
	self.soilMap = g_precisionFarming.soilMap
	self.yieldMap = g_precisionFarming.yieldMap
	self.seedRateMap = g_precisionFarming.seedRateMap
	return true
end
function CoverMap:overwriteGameFunctions(pfModule)
	CoverMap:superClass().overwriteGameFunctions(self, pfModule)
end
function CoverMap:getShowInMenu()
	return false
end
function CoverMap:analyseArea(densityMapShape, state, farmId, farmlandId)
	local modifier = self.densityMapModifiersAnalyse.modifier
	local maskFilter = self.densityMapModifiersAnalyse.maskFilter
	local modifierFarmIdMap = self.densityMapModifiersAnalyse.modifierFarmIdMap
	if modifier == nil or maskFilter == nil or modifierFarmIdMap == nil then
		self.densityMapModifiersAnalyse.modifier = DensityMapModifier.new(self.bitVectorMap, self.firstChannel, self.numChannels, g_terrainNode)
		modifier = self.densityMapModifiersAnalyse.modifier
		local fieldGroundSystem = g_currentMission.fieldGroundSystem
		local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
		self.densityMapModifiersAnalyse.maskFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
		maskFilter = self.densityMapModifiersAnalyse.maskFilter
		maskFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)
		self.densityMapModifiersAnalyse.modifierFarmIdMap = DensityMapModifier.new(self.bitVectorMapSoilSampleFarmId, 0, 4, g_terrainNode)
		modifierFarmIdMap = self.densityMapModifiersAnalyse.modifierFarmIdMap
	end
	densityMapShape:applyToModifier(modifier)
	densityMapShape:applyToModifier(modifierFarmIdMap)
	local _, area, totalArea = modifier:executeSetWithStats(state or self.sampledValue, maskFilter)
	modifierFarmIdMap:executeSet(farmId, maskFilter)
	self.soilMap:onAnalyseArea(densityMapShape, state, farmId)
	return area, totalArea
end
function CoverMap:uncoverAnalysedArea(farmId)
	local updateTask = CoverMapDensityMapTask.new()
	updateTask:setData(farmId, nil)
	updateTask:enqueue()
end
function CoverMap:uncoverFarmlandArea(farmlandId)
	local updateTask = CoverMapDensityMapTask.new()
	updateTask:setData(nil, farmlandId)
	updateTask:enqueue()
end
function CoverMap:onCoverUpdateFinished(farmId, farmlandId, sampledPercentageByFarmlandId) end
function CoverMap:getCoverMultiModifier(farmId, farmlandId)
	local functionData = self.densityMapModifiersUncover
	if functionData == nil then
		functionData = {}
		functionData.modifier = DensityMapModifier.new(self.bitVectorMap, self.firstChannel, self.numChannels, g_terrainNode)
		functionData.farmlandMaskFilter = DensityMapFilter.new(g_farmlandManager.localMap, 0, g_farmlandManager.numberOfBits)
		functionData.sampledFilter = DensityMapFilter.new(self.bitVectorMap, self.firstChannel, self.numChannels)
		functionData.sampledFilter:setValueCompareParams(DensityValueCompareType.EQUAL, self.sampledValue)
		functionData.farmFilter = DensityMapFilter.new(self.bitVectorMapSoilSampleFarmId, 0, 4)
		local fieldGroundSystem = g_currentMission.fieldGroundSystem
		local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
		functionData.fieldFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
		functionData.fieldFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)
		functionData.noFieldFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
		functionData.noFieldFilter:setValueCompareParams(DensityValueCompareType.EQUAL, 0)
		functionData.coverFilter = DensityMapFilter.new(self.bitVectorMap, self.firstChannel, self.numChannels)
		functionData.coverFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, 2, self.maxValue + 1)
		functionData.sampleStateMaskFilters = {}
		functionData.farmlandModifiers = {}
		self.densityMapModifiersUncover = functionData
	end
	if farmId ~= nil then
		local multiModifier = DensityMapMultiModifier.new()
		local modifier = functionData.modifier
		local farmFilter = functionData.farmFilter
		local sampledFilter = functionData.sampledFilter
		farmFilter:setValueCompareParams(DensityValueCompareType.EQUAL, farmId)
		if farmId < 0 then
			farmFilter = nil
		end
		self.soilMap:addUncoverToMultiModifier(multiModifier, sampledFilter, farmFilter)
		multiModifier:addExecuteSet(self.maxValue, modifier, sampledFilter, farmFilter)
		local farmlandIds = {}
		for _farmlandId, _farmId in pairs(g_farmlandManager.farmlandMapping) do
			if _farmId == farmId then
				table.insert(farmlandIds, _farmlandId)
			end
		end
		self:addSampleStateGetToMultiModifier(multiModifier, functionData, farmlandIds)
		return multiModifier, farmlandIds
	elseif farmlandId ~= nil then
		local cachedData = functionData.farmlandModifiers[farmlandId]
		if cachedData == nil then
			local multiModifier = DensityMapMultiModifier.new()
			local modifier = functionData.modifier
			local farmlandMaskFilter = functionData.farmlandMaskFilter
			local fieldFilter = functionData.fieldFilter
			local noFieldFilter = functionData.noFieldFilter
			farmlandMaskFilter:setValueCompareParams(DensityValueCompareType.EQUAL, farmlandId)
			if farmlandId < 0 then
				farmlandMaskFilter = nil
			end
			multiModifier:addExecuteSet(0, modifier, noFieldFilter, farmlandMaskFilter)
			self.yieldMap:addClearToMultiModifier(multiModifier, noFieldFilter, farmlandMaskFilter)
			self.seedRateMap:addClearToMultiModifier(multiModifier, noFieldFilter, farmlandMaskFilter)
			self.soilMap:addUncoverToMultiModifier(multiModifier, fieldFilter, farmlandMaskFilter, noFieldFilter, farmlandMaskFilter)
			multiModifier:addExecuteSet(self.maxValue, modifier, fieldFilter, farmlandMaskFilter)
			local farmlandIds = { farmlandId }
			self:addSampleStateGetToMultiModifier(multiModifier, functionData, farmlandIds)
			cachedData = { multiModifier = multiModifier, farmlandIds = farmlandIds }
			functionData.farmlandModifiers[farmlandId] = cachedData
		end
		return cachedData.multiModifier, cachedData.farmlandIds
	else
		return nil, nil
	end
end
function CoverMap:addSampleStateGetToMultiModifier(multiModifier, functionData, farmlandIds)
	local farmlandManager = g_farmlandManager
	for _, farmlandId in ipairs(farmlandIds) do
		local maskFilter = functionData.sampleStateMaskFilters[farmlandId]
		if maskFilter == nil then
			maskFilter = DensityMapFilter.new(farmlandManager.localMap, 0, farmlandManager.numberOfBits)
			maskFilter:setValueCompareParams(DensityValueCompareType.EQUAL, farmlandId)
			functionData.sampleStateMaskFilters[farmlandId] = maskFilter
		end
		local fieldLabel = "field_" .. tostring(farmlandId)
		local sampledLabel = "sampled_" .. tostring(farmlandId)
		multiModifier:addExecuteGet(fieldLabel, functionData.modifier, maskFilter, functionData.fieldFilter)
		multiModifier:addExecuteGet(sampledLabel, functionData.modifier, functionData.coverFilter, maskFilter, functionData.fieldFilter)
	end
end
function CoverMap:getFarmlandSampleState(farmlandId)
	local modifier = self.densityMapModifiersFarmlandState.modifier
	local coverFilter = self.densityMapModifiersFarmlandState.coverFilter
	local maskFilter = self.densityMapModifiersFarmlandState.maskFilter
	local fieldFilter = self.densityMapModifiersFarmlandState.fieldFilter
	if modifier == nil or coverFilter == nil or maskFilter == nil or fieldFilter == nil then
		self.densityMapModifiersFarmlandState.modifier = DensityMapModifier.new(self.bitVectorMap, self.firstChannel, self.numChannels)
		modifier = self.densityMapModifiersFarmlandState.modifier
		modifier:setParallelogramDensityMapCoords(0, 0, 0, self.sizeY, self.sizeX, 0, DensityCoordType.POINT_POINT_POINT)
		self.densityMapModifiersFarmlandState.coverFilter = DensityMapFilter.new(self.bitVectorMap, self.firstChannel, self.numChannels)
		coverFilter = self.densityMapModifiersFarmlandState.coverFilter
		coverFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, 2, self.maxValue + 1)
		local farmlandManager = g_farmlandManager
		self.densityMapModifiersFarmlandState.maskFilter = DensityMapFilter.new(farmlandManager.localMap, 0, farmlandManager.numberOfBits)
		maskFilter = self.densityMapModifiersFarmlandState.maskFilter
		maskFilter:setValueCompareParams(DensityValueCompareType.EQUAL, farmlandId)
		local fieldGroundSystem = g_currentMission.fieldGroundSystem
		local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
		self.densityMapModifiersFarmlandState.fieldFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
		fieldFilter = self.densityMapModifiersFarmlandState.fieldFilter
		fieldFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)
	end
	maskFilter:setValueCompareParams(DensityValueCompareType.EQUAL, farmlandId)
	local _, areaField, _ = modifier:executeGet(maskFilter, fieldFilter)
	local _, areaSampled, _ = modifier:executeGet(coverFilter, maskFilter, fieldFilter)
	if 0 < areaField then
		return areaSampled / areaField
	else
		return 0
	end
end
function CoverMap:getCoverUpdateDensityMapModifiers(fruitTypes, preUpdate, useMinForageState, strawChopperActive)
	local functionData = self.densityMapModifiersUpdate
	if functionData == nil then
		functionData = {}
		functionData.modifier = DensityMapModifier.new(self.bitVectorMap, self.firstChannel, self.numChannels, g_terrainNode)
		functionData.lockModifier = DensityMapModifier.new(self.bitVectorMapTempHarvestLock, 0, 1, g_terrainNode)
		functionData.lockFilter = DensityMapFilter.new(self.bitVectorMapTempHarvestLock, 0, 1)
		functionData.lockFilter:setValueCompareParams(DensityValueCompareType.EQUAL, 1)
		functionData.lockFilterReduction = DensityMapFilter.new(self.bitVectorMapTempHarvestLock, 0, 1)
		functionData.lockFilterReduction:setValueCompareParams(DensityValueCompareType.EQUAL, 1)
		functionData.coverStateFilter = DensityMapFilter.new(self.bitVectorMap, self.firstChannel, self.numChannels)
		functionData.coverStateFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, 2, self.maxValue)
		functionData.multiModifiersPreUpdateByHash = {}
		functionData.numChangedPixelsPre = {}
		functionData.totalNumPixelsPre = {}
		functionData.multiModifiersPostUpdateByHash = {}
		functionData.numChangedPixelsPost = {}
		functionData.totalNumPixelsPost = {}
		self.densityMapModifiersUpdate = functionData
	end
	local multiModifiersByHash = preUpdate and functionData.multiModifiersPreUpdateByHash or functionData.multiModifiersPostUpdateByHash
	local hash = 0
	for _, fruitIndex in pairs(fruitTypes) do
		hash = hash + fruitIndex * 512
	end
	local multiModifiers = multiModifiersByHash[hash]
	if multiModifiers == nil then
		multiModifiers = {}
		for f = 1, 2 do
			local useForageStates = f == 2
			if preUpdate then
				local multiModifier = DensityMapMultiModifier.new()
				multiModifier:addExecuteSet(0, functionData.lockModifier)
				for _, fruitIndex in pairs(fruitTypes) do
					local desc = g_fruitTypeManager:getFruitTypeByIndex(fruitIndex)
					if desc == nil or desc.terrainDataPlaneId == nil then
						continue
					end
					local fruitFilterHarvestState = DensityMapFilter.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)
					local minHarvestState = desc.minHarvestingGrowthState
					local maxHarvestState = desc.maxHarvestingGrowthState
					if useForageStates and desc.minForageGrowthState ~= 0 then
						minHarvestState = math.min(minHarvestState, desc.minForageGrowthState)
					end
					if minHarvestState == maxHarvestState then
						fruitFilterHarvestState:setValueCompareParams(DensityValueCompareType.EQUAL, minHarvestState)
					else
						fruitFilterHarvestState:setValueCompareParams(DensityValueCompareType.BETWEEN, minHarvestState, maxHarvestState)
					end
					fruitFilterHarvestState:setSupersamplingMode(DensityFilterSupersamplingMode.ANY)
					multiModifier:addExecuteSetWithStats(tostring(fruitIndex), 1, functionData.lockModifier, fruitFilterHarvestState)
					if desc.minPreparingGrowthState == nil then
						continue
					end
					local fruitFilterPrepareState = DensityMapFilter.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)
					if desc.minPreparingGrowthState == desc.maxPreparingGrowthState then
						fruitFilterPrepareState:setValueCompareParams(DensityValueCompareType.EQUAL, desc.minPreparingGrowthState)
					else
						fruitFilterPrepareState:setValueCompareParams(DensityValueCompareType.BETWEEN, desc.minPreparingGrowthState, desc.maxPreparingGrowthState)
					end
					fruitFilterPrepareState:setSupersamplingMode(DensityFilterSupersamplingMode.ANY)
					multiModifier:addExecuteSetWithStats(tostring(fruitIndex), 1, functionData.lockModifier, fruitFilterPrepareState)
				end
				multiModifiers[useForageStates] = multiModifier
			else
				local multiModifier = DensityMapMultiModifier.new()
				for _, fruitIndex in pairs(fruitTypes) do
					local desc = g_fruitTypeManager:getFruitTypeByIndex(fruitIndex)
					if desc == nil or desc.terrainDataPlaneId == nil then
						continue
					end
					local fruitFilterHarvestState = DensityMapFilter.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)
					local minHarvestState = desc.minHarvestingGrowthState
					local maxHarvestState = desc.maxHarvestingGrowthState
					if useForageStates and desc.minForageGrowthState ~= 0 then
						minHarvestState = math.min(minHarvestState, desc.minForageGrowthState)
					end
					if minHarvestState == maxHarvestState then
						fruitFilterHarvestState:setValueCompareParams(DensityValueCompareType.EQUAL, minHarvestState)
					else
						fruitFilterHarvestState:setValueCompareParams(DensityValueCompareType.BETWEEN, minHarvestState, maxHarvestState)
					end
					fruitFilterHarvestState:setSupersamplingMode(DensityFilterSupersamplingMode.ANY)
					multiModifier:addExecuteSet(0, functionData.lockModifier, functionData.lockFilter, fruitFilterHarvestState)
					if desc.minPreparingGrowthState == nil then
						continue
					end
					local fruitFilterPrepareState = DensityMapFilter.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)
					if desc.minPreparingGrowthState == desc.maxPreparingGrowthState then
						fruitFilterPrepareState:setValueCompareParams(DensityValueCompareType.EQUAL, desc.minPreparingGrowthState)
					else
						fruitFilterPrepareState:setValueCompareParams(DensityValueCompareType.BETWEEN, desc.minPreparingGrowthState, desc.maxPreparingGrowthState)
					end
					fruitFilterPrepareState:setSupersamplingMode(DensityFilterSupersamplingMode.ANY)
					multiModifier:addExecuteSet(0, functionData.lockModifier, functionData.lockFilter, fruitFilterPrepareState)
				end
				multiModifier:addExecuteAdd(-1, functionData.modifier, functionData.lockFilter, functionData.coverStateFilter)
				multiModifier:addExecuteGet("pixelsToLock", functionData.modifier, functionData.lockFilter)
				multiModifiers[useForageStates] = multiModifier
			end
		end
		multiModifiersByHash[hash] = multiModifiers
	end
	if preUpdate then
		return multiModifiers[useMinForageState], functionData.numChangedPixelsPre, functionData.totalNumPixelsPre
	else
		return multiModifiers[useMinForageState], functionData.numChangedPixelsPost, functionData.totalNumPixelsPost
	end
end
function CoverMap:preUpdateCoverArea(fruitTypes, densityMapShape, useMinForageState, strawChopperActive)
	if useMinForageState == nil then
		useMinForageState = false
	end
	local multiModifierPreUpdate, numChangedPixels, totalNumPixels = self:getCoverUpdateDensityMapModifiers(fruitTypes, true, useMinForageState, strawChopperActive)
	if multiModifierPreUpdate == nil then
		return nil
	else
		densityMapShape:applyToModifier(multiModifierPreUpdate)
		multiModifierPreUpdate:resetStats()
		multiModifierPreUpdate:execute(nil, numChangedPixels, totalNumPixels)
		local usedFruitIndex = nil
		for _, fruitIndex in pairs(fruitTypes) do
			local numPixels = numChangedPixels[tostring(fruitIndex)]
			if numPixels == nil then
				continue
			end
			if 0 < numPixels then
				usedFruitIndex = fruitIndex
			end
		end
		self.lastUsedFruitIndex = usedFruitIndex or self.lastUsedFruitIndex
		return usedFruitIndex
	end
end
function CoverMap:postUpdateCoverArea(fruitTypes, densityMapShape, useMinForageState, strawChopperActive, usedFruitIndex)
	if useMinForageState == nil then
		useMinForageState = false
	end
	if usedFruitIndex == nil then
		usedFruitIndex = self.lastUsedFruitIndex
	end
	local multiModifierPostUpdate, numChangedPixels, totalNumPixels = self:getCoverUpdateDensityMapModifiers(fruitTypes, false, useMinForageState, strawChopperActive)
	if multiModifierPostUpdate == nil then
		return false, false
	end
	local functionData = self.densityMapModifiersUpdate
	if functionData == nil then
		return false, false
	else
		local lockModifier = functionData.lockModifier
		local lockFilterReduction = functionData.lockFilterReduction
		densityMapShape:applyToModifier(multiModifierPostUpdate)
		multiModifierPostUpdate:resetStats()
		multiModifierPostUpdate:execute(nil, numChangedPixels, totalNumPixels)
		local pixelsToLock = numChangedPixels.pixelsToLock or 0
		local phMapUpdated = false
		local nMapUpdated = false
		if 0 < pixelsToLock and usedFruitIndex ~= nil then
			if self.pfModule.nitrogenMap ~= nil then
				nMapUpdated = self.pfModule.nitrogenMap:harvestUpdate(lockFilterReduction, usedFruitIndex, densityMapShape, useMinForageState, strawChopperActive)
			end
			if self.pfModule.pHMap ~= nil then
				phMapUpdated = self.pfModule.pHMap:harvestUpdate(lockFilterReduction, usedFruitIndex, densityMapShape, useMinForageState, strawChopperActive)
			end
			if self.pfModule.seedRateMap ~= nil then
				self.pfModule.seedRateMap:harvestUpdate(lockFilterReduction, usedFruitIndex, densityMapShape, useMinForageState, strawChopperActive)
			end
		end
		densityMapShape:applyToModifier(lockModifier)
		lockModifier:executeSet(0)
		return phMapUpdated, nMapUpdated
	end
end
function CoverMap:resetCoverLock(densityMapShape)
	local modifier = self.densityMapModifiersResetLock.modifier
	if modifier == nil then
		self.densityMapModifiersResetLock.modifier = DensityMapModifier.new(self.bitVectorMap, self.lockChannel, 1, g_terrainNode)
		modifier = self.densityMapModifiersResetLock.modifier
	end
	densityMapShape:applyToModifier(modifier)
	modifier:executeSet(0)
end
function CoverMap:getNumCoverOverlays()
	return self.maxValue - 1
end
function CoverMap:buildCoverStateOverlay(overlay, index)
	local numOverlays = self:getNumCoverOverlays()
	resetDensityMapVisualizationOverlay(overlay)
	local alpha = (numOverlays - (index - 1)) / numOverlays
	setOverlayColor(overlay, 1, 1, 1, alpha)
	setDensityMapVisualizationOverlayStateColor(overlay, self.bitVectorMap, 0, 0, self.firstChannel, self.numChannels, index, 0, 0, 0)
end
function CoverMap:getIsUncoveredAtPos(x, z, isWorldPos)
	if isWorldPos == true then
		x = MathUtil.round((x + g_currentMission.terrainSize * 0.5) / g_currentMission.terrainSize * self.sizeX + 0.5) - 1
		z = MathUtil.round((z + g_currentMission.terrainSize * 0.5) / g_currentMission.terrainSize * self.sizeY + 0.5) - 1
	end
	local coverValue = getBitVectorMapPoint(self.bitVectorMap, x, z, self.firstChannel, self.numChannels)
	if 1 < coverValue and coverValue <= self.maxValue then
		return true
	end
	return false
end
function CoverMap:getLevelAtWorldPos(x, z)
	x = MathUtil.round((x + g_currentMission.terrainSize * 0.5) / g_currentMission.terrainSize * self.sizeX + 0.5) - 1
	z = MathUtil.round((z + g_currentMission.terrainSize * 0.5) / g_currentMission.terrainSize * self.sizeY + 0.5) - 1
	return getBitVectorMapPoint(self.bitVectorMap, x, z, self.firstChannel, self.numChannels)
end
function CoverMap:debugReduceCoverStateField(fieldId)
	local field = g_fieldManager:getFieldById(tonumber(fieldId))
	if field ~= nil and field.getDensityMapPolygon ~= nil then
		local area = field:getDensityMapPolygon()
		local usedFruitIndex = self:preUpdateCoverArea({}, area, true, false)
		self:postUpdateCoverArea({}, area, true, false, usedFruitIndex)
		self:resetCoverLock(area)
	end
	self.pfModule:updatePrecisionFarmingOverlays()
end
function CoverMap:debugReduceCoverStateAll()
	for i = 1, #g_fieldManager.fields do
		self:debugReduceCoverStateField(i)
	end
end
function CoverMap:debugUncoverField(fieldId)
	local field = g_fieldManager:getFieldById(tonumber(fieldId))
	if field ~= nil then
		local area = field:getDensityMapPolygon()
		self:analyseArea(area, nil, g_farmlandManager:getFarmlandOwner(field.farmland.id), field.farmland.id)
		self:uncoverAnalysedArea(-1)
	end
end
function CoverMap:debugUncoverAll()
	for i = 1, #g_fieldManager.fields do
		self:debugUncoverField(i)
	end
end
