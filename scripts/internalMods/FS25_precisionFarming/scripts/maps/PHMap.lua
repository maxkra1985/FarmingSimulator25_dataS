PHMap = {}
PHMap.MOD_NAME = g_currentModName
PHMap.NUM_BITS = 5
local PHMap_mt = Class(PHMap, ValueMap)
function PHMap.new(pfModule, customMt)
	local self = ValueMap.new(pfModule, customMt or PHMap_mt)
	self.name = "pHMap"
	self.id = "PH_MAP"
	self.label = "ui_mapOverviewPH"
	self.densityMapModifiersInitialize = {}
	self.densityMapModifiersHarvestMulti = nil
	self.densityMapModifiersLockedState = {}
	self.densityMapModifiersSpray = nil
	self.densityMapModifiersResetLock = {}
	self.lastActualValue = -1
	self.lastTargetValue = -1
	self.lastRegularValue = -1
	self.minimapGradientSliceId = "precisionFarming.gradient_ph"
	self.minimapGradientColorBlindSliceId = "precisionFarming.gradient_color_blind"
	self.minimapLabelName = g_i18n:getText("ui_mapOverviewPH", PHMap.MOD_NAME)
	self.realisticSpreadPatternEnabled = true
	self.realisticSpreadOutputEnabled = true
	pfModule:addSetting("realisticSpreadPattern", g_i18n:getText("settingTitle_realisticSpreadPattern"), g_i18n:getText("settingDescription_realisticSpreadPattern"), self.onRealisticSpreadPatternSettingChanged, self, self.realisticSpreadPatternEnabled, true, nil, true)
	pfModule:addSetting("realisticSpreadOutput", g_i18n:getText("settingTitle_realisticSpreadOutput"), g_i18n:getText("settingDescription_realisticSpreadOutput"), self.onRealisticSpreadOutputSettingChanged, self, self.realisticSpreadOutputEnabled, true, nil, true)
	if g_server ~= nil then
		addConsoleCommand("pfPHSet", "Sets the given pH level on the given field", "debugSetPHLevel", self)
	end
	return self
end
function PHMap:initialize()
	PHMap:superClass().initialize(self)
	self.densityMapModifiersInitialize = {}
	self.densityMapModifiersHarvestMulti = nil
	self.densityMapModifiersLockedState = {}
	self.densityMapModifiersSpray = nil
	self.densityMapModifiersResetLock = {}
	self.lastActualValue = -1
	self.lastTargetValue = -1
	self.lastRegularValue = -1
end
function PHMap:delete()
	if g_server ~= nil then
		removeConsoleCommand("pfPHSet")
	end
	PHMap:superClass().delete(self)
end
function PHMap:loadFromXML(xmlFile, key, baseDirectory, configFileName, mapFilename)
	key = key .. ".pHMap"
	self.firstChannel = getXMLInt(xmlFile, key .. ".bitVectorMap#firstChannel") or 1
	self.numChannels = getXMLInt(xmlFile, key .. ".bitVectorMap#numChannels") or 4
	self.maxValue = getXMLInt(xmlFile, key .. ".bitVectorMap#maxValue") or 2 ^ self.numChannels - 1
	self.sizeX = 1024
	self.sizeY = 1024
	self.bitVectorMap, self.newBitVectorMap = self:loadSavedBitVectorMap("phMap", "precisionFarming_phMap.grle", self.numChannels, self.sizeX)
	self:addBitVectorMapToSync(self.bitVectorMap)
	self:addBitVectorMapToSave(self.bitVectorMap, "precisionFarming_phMap.grle")
	self:addBitVectorMapToDelete(self.bitVectorMap)
	self.noiseFilename = getXMLString(xmlFile, key .. ".noiseMap#filename")
	self.noiseNumChannels = getXMLInt(xmlFile, key .. ".noiseMap#numChannels") or 2
	self.noiseResolution = getXMLInt(xmlFile, key .. ".noiseMap#resolution") or 1024
	self.noiseMaxValue = 2 ^ self.noiseNumChannels - 1
	self.bitVectorMapNoise = createBitVectorMap("pHNoiseMap")
	if self.noiseFilename ~= nil then
		self.noiseFilename = Utils.getFilename(self.noiseFilename, baseDirectory)
		if not loadBitVectorMapFromFile(self.bitVectorMapNoise, self.noiseFilename, self.noiseNumChannels) then
			Logging.xmlWarning(configFileName, "Error while loading pH noise map '%s'", self.noiseFilename)
			self.noiseFilename = nil
		end
	end
	if self.noiseFilename == nil then
		loadBitVectorMapNew(self.bitVectorMapNoise, self.noiseResolution, self.noiseResolution, self.noiseNumChannels, false)
	end
	self:addBitVectorMapToDelete(self.bitVectorMapNoise)
	self.bitVectorMapPHStateChange = self:loadSavedBitVectorMap("pHLockStateMap", "precisionFarming_pHLockStateMap.grle", 2, self.noiseResolution)
	self:addBitVectorMapToSave(self.bitVectorMapPHStateChange, "precisionFarming_pHLockStateMap.grle")
	self:addBitVectorMapToDelete(self.bitVectorMapPHStateChange)
	self.bitVectorMapPHInitMask = self:loadSavedBitVectorMap("pHInitMaskMap", "pHInitMaskMap.grle", 1, self.noiseResolution)
	self:addBitVectorMapToDelete(self.bitVectorMapPHInitMask)
	self.outdatedLabel = g_i18n:convertText(getXMLString(xmlFile, key .. ".texts#outdatedLabel") or "$l10n_ui_precisionFarming_outdatedData", PHMap.MOD_NAME)
	self.pHValues = {}
	self.pHValuesToDisplay = {}
	self.maxVisibleValue = 0
	local i = 0
	while true do
		local baseKey = string.format("%s.pHValues.pHValue(%d)", key, i)
		if not hasXMLProperty(xmlFile, baseKey) then
			break
		end
		local pHValue = {}
		pHValue.value = getXMLInt(xmlFile, baseKey .. "#value") or 0
		pHValue.realValue = getXMLFloat(xmlFile, baseKey .. "#realValue") or 0
		pHValue.color = string.getVector(getXMLString(xmlFile, baseKey .. "#color"), 3)
		pHValue.colorBlind = string.getVector(getXMLString(xmlFile, baseKey .. "#colorBlind"), 3)
		pHValue.showOnHud = Utils.getNoNil(getXMLBool(xmlFile, baseKey .. "#showOnHud"), true)
		table.insert(self.pHValues, pHValue)
		if pHValue.showOnHud then
			table.insert(self.pHValuesToDisplay, pHValue)
			pHValue.filterIndex = #self.pHValuesToDisplay
			for j = #self.pHValues, 1, -1 do
				if self.pHValues[j].filterIndex == nil then
					self.pHValues[j].filterIndex = pHValue.filterIndex
					break
				end
			end
		end
		self.maxVisibleValue = pHValue.value
		i = i + 1
	end
	for j = 1, #self.pHValues do
		if self.pHValues[j].filterIndex == nil then
			self.pHValues[j].filterIndex = #self.pHValuesToDisplay
		end
	end
	for index, pHValue in ipairs(self.pHValues) do
		if pHValue.color == nil or pHValue.colorBlind == nil then
			local lastColor = nil
			local lastColorBlind = nil
			for i = index - 1, 1, -1 do
				if 0 < i and self.pHValues[i].color ~= nil then
					lastColor = self.pHValues[i].color
					lastColorBlind = self.pHValues[i].colorBlind
					break
				end
			end
			local nextColor = nil
			local nextColorBlind = nil
			for i = index + 1, #self.pHValues do
				if self.pHValues[i].color ~= nil then
					nextColor = self.pHValues[i].color
					nextColorBlind = self.pHValues[i].colorBlind
					break
				end
			end
			if lastColor ~= nil and nextColor ~= nil then
				pHValue.color = { (lastColor[1] + nextColor[1]) * 0.5, (lastColor[2] + nextColor[2]) * 0.5, (lastColor[3] + nextColor[3]) * 0.5 }
			end
			if lastColorBlind == nil or nextColorBlind == nil then
				continue
			end
			pHValue.colorBlind = { (lastColorBlind[1] + nextColorBlind[1]) * 0.5, (lastColorBlind[2] + nextColorBlind[2]) * 0.5, (lastColorBlind[3] + nextColorBlind[3]) * 0.5 }
		end
	end
	self.pHValuePerState = getXMLFloat(xmlFile, key .. ".pHValues#pHValuePerState") or 0.125
	self.valueTransformations = {}
	i = 0
	while true do
		local baseKey = string.format("%s.valueTransformations.valueTransformation(%d)", key, i)
		if not hasXMLProperty(xmlFile, baseKey) then
			break
		end
		local valueTransformation = {}
		valueTransformation.soilTypeIndex = getXMLInt(xmlFile, baseKey .. "#soilTypeIndex") or 1
		valueTransformation.baseRange = string.getVector(getXMLString(xmlFile, baseKey .. ".baseValue#range"), self.noiseMaxValue + 1)
		if valueTransformation.baseRange ~= nil then
			for j = 1, #valueTransformation.baseRange do
				local _, internalIndex = self:getNearestPhValueFromValue(valueTransformation.baseRange[j])
				valueTransformation.baseRange[j] = internalIndex
			end
			local _ = nil
			_, valueTransformation.optimalValue = self:getNearestPhValueFromValue(getXMLFloat(xmlFile, baseKey .. ".optimalValue#value") or 6.5)
			valueTransformation.regularOffset = (getXMLFloat(xmlFile, baseKey .. ".regularOffset#value") or self.pHValuePerState) / self.pHValuePerState
			valueTransformation.decreasePerHarvest = {}
			local j = 0
			while true do
				local decreaseKey = string.format("%s.decreasePerHarvest(%d)", baseKey, j)
				if not hasXMLProperty(xmlFile, decreaseKey) then
					break
				end
				local decreasePerHarvest = {}
				decreasePerHarvest.range = string.getVector(getXMLString(xmlFile, decreaseKey .. "#range"), 2)
				if decreasePerHarvest.range ~= nil then
					for ri = 1, #decreasePerHarvest.range do
						local _, internalIndex = self:getNearestPhValueFromValue(decreasePerHarvest.range[ri])
						decreasePerHarvest.range[ri] = internalIndex
					end
				end
				decreasePerHarvest.decreaseValue = MathUtil.round((getXMLFloat(xmlFile, decreaseKey .. "#value") or self.pHValuePerState) / self.pHValuePerState)
				table.insert(valueTransformation.decreasePerHarvest, decreasePerHarvest)
				j = j + 1
			end
			table.insert(self.valueTransformations, valueTransformation)
		else
			Logging.xmlWarning(configFileName, "Invalid base pH range for '%s'", baseKey)
		end
		i = i + 1
	end
	self.regularLimeUsage = getXMLFloat(xmlFile, key .. ".valueTransformations#regularUsage") or 3000
	self.yieldCurve = AnimCurve.new(linearInterpolator1)
	i = 0
	while true do
		local baseKey = string.format("%s.yieldMappings.yieldMapping(%d)", key, i)
		if not hasXMLProperty(xmlFile, baseKey) then
			break
		end
		local levelDifference = getXMLInt(xmlFile, baseKey .. "#levelDifference") or 0
		local yieldFactor = getXMLFloat(xmlFile, baseKey .. "#yieldFactor") or 1
		self.yieldCurve:addKeyframe({ yieldFactor, ["time"] = levelDifference })
		i = i + 1
	end
	self.levelDifferenceColors = {}
	i = 0
	while true do
		local baseKey = string.format("%s.levelDifferenceColors.levelDifferenceColor(%d)", key, i)
		if not hasXMLProperty(xmlFile, baseKey) then
			break
		end
		local levelDifferenceColor = {}
		levelDifferenceColor.levelDifference = getXMLInt(xmlFile, baseKey .. "#levelDifference") or 0
		levelDifferenceColor.color = string.getVector(getXMLString(xmlFile, baseKey .. "#color"), 3) or { 0, 0, 0 }
		levelDifferenceColor.colorBlind = string.getVector(getXMLString(xmlFile, baseKey .. "#colorBlind"), 3) or { 0, 0, 0 }
		levelDifferenceColor.color[4] = 1
		levelDifferenceColor.colorBlind[4] = 1
		levelDifferenceColor.additionalText = g_i18n:convertText(getXMLString(xmlFile, baseKey .. "#text"), PHMap.MOD_NAME)
		levelDifferenceColor.showWarning = Utils.getNoNil(getXMLBool(xmlFile, baseKey .. "#showWarning"), false)
		table.insert(self.levelDifferenceColors, levelDifferenceColor)
		i = i + 1
	end
	self.limeUsage = {}
	self.limeUsage.usagePerState = getXMLFloat(xmlFile, key .. ".limeUsage#usagePerState") or 730
	self.stateChangeDefault = math.ceil(self.regularLimeUsage / self.limeUsage.usagePerState)
	self.minimapGradientLabelName = string.format("pH %.2f - %.2f", self:getMinMaxValue())
	self.coverMap = g_precisionFarming.coverMap
	self.soilMap = g_precisionFarming.soilMap
	return true
end
function PHMap:addSetInitialState(multiModifier, soilBitVector, soilTypeFirstChannel, soilTypeNumChannels, farmlandMask)
	local functionData = self.densityMapModifiersInitialize
	local modifier = functionData.modifier
	local pHFilter = functionData.pHFilter
	local soilFilter = functionData.soilFilter
	local noiseFilter = functionData.noiseFilter
	local pHInitModifier = functionData.pHInitModifier
	local pHInitMaskFilter = functionData.pHInitMaskFilter
	if modifier == nil or pHFilter == nil or soilFilter == nil or noiseFilter == nil or pHInitModifier == nil or pHInitMaskFilter == nil then
		functionData.modifier = DensityMapModifier.new(self.bitVectorMap, self.firstChannel, self.numChannels, g_terrainNode)
		modifier = functionData.modifier
		functionData.pHFilter = DensityMapFilter.new(self.bitVectorMap, self.firstChannel, self.numChannels)
		functionData.pHFilter:setValueCompareParams(DensityValueCompareType.EQUAL, self.maxValue)
		pHFilter = functionData.pHFilter
		functionData.soilFilter = DensityMapFilter.new(soilBitVector, soilTypeFirstChannel, soilTypeNumChannels)
		soilFilter = functionData.soilFilter
		functionData.noiseFilter = DensityMapFilter.new(self.bitVectorMapNoise, 0, self.noiseNumChannels)
		noiseFilter = functionData.noiseFilter
		functionData.pHInitModifier = DensityMapModifier.new(self.bitVectorMapPHInitMask, 0, 1, g_terrainNode)
		pHInitModifier = functionData.pHInitModifier
		functionData.pHInitMaskFilter = DensityMapFilter.new(self.bitVectorMapPHInitMask, 0, 1)
		pHInitMaskFilter = functionData.pHInitMaskFilter
		pHInitMaskFilter:setValueCompareParams(DensityValueCompareType.EQUAL, 1)
	end
	for i = 1, #self.valueTransformations do
		local valueTransformation = self.valueTransformations[i]
		soilFilter:setValueCompareParams(DensityValueCompareType.EQUAL, valueTransformation.soilTypeIndex - 1)
		if farmlandMask ~= nil then
			multiModifier:addExecuteSet(self.maxValue, modifier, soilFilter, farmlandMask)
		else
			multiModifier:addExecuteSet(self.maxValue, modifier, soilFilter)
		end
		for j = 1, self.noiseMaxValue + 1 do
			noiseFilter:setValueCompareParams(DensityValueCompareType.EQUAL, j - 1)
			multiModifier:addExecuteSet(valueTransformation.baseRange[j], modifier, pHFilter, noiseFilter)
		end
	end
end
function PHMap:harvestUpdate(filter, fruitIndex, densityMapShape, useMinForageState, strawChopperActive)
	local coverMap = self.coverMap
	local soilMap = self.soilMap
	if coverMap ~= nil and (coverMap.bitVectorMap ~= nil and (soilMap ~= nil and soilMap.bitVectorMap ~= nil)) then
		local functionData = self.densityMapModifiersHarvestMulti
		if functionData == nil then
			functionData = {}
			functionData.modifier = DensityMapModifier.new(self.bitVectorMap, self.firstChannel, self.numChannels, g_terrainNode)
			functionData.modifier:setPolygonRoundingMode(DensityRoundingMode.INCLUSIVE)
			functionData.soilFilter = DensityMapFilter.new(soilMap.bitVectorMap, soilMap.typeFirstChannel, soilMap.typeNumChannels)
			functionData.phFilter = DensityMapFilter.new(self.bitVectorMap, self.firstChannel, self.numChannels)
			functionData.phFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, 2, self.maxValue)
			functionData.modifierTempLock = DensityMapModifier.new(self.bitVectorMapPHStateChange, 0, 1, g_terrainNode)
			functionData.modifierTempLock:setPolygonRoundingMode(DensityRoundingMode.INCLUSIVE)
			functionData.tempLockFilter = DensityMapFilter.new(self.bitVectorMapPHStateChange, 0, 1)
			functionData.tempLockFilter:setValueCompareParams(DensityValueCompareType.EQUAL, 1)
			functionData.multiModifier = DensityMapMultiModifier.new()
			for i = 1, #self.valueTransformations do
				local valueTransformation = self.valueTransformations[i]
				functionData.soilFilter:setValueCompareParams(DensityValueCompareType.EQUAL, valueTransformation.soilTypeIndex - 1)
				for j = 1, #valueTransformation.decreasePerHarvest do
					local decreasePerHarvest = valueTransformation.decreasePerHarvest[j]
					if decreasePerHarvest.range ~= nil then
						functionData.phFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, math.max(decreasePerHarvest.range[1] - 1), decreasePerHarvest.range[2] + 1)
						functionData.multiModifier:addExecuteAddWithStats(tostring(i), -decreasePerHarvest.decreaseValue, functionData.modifier, filter, functionData.soilFilter, functionData.phFilter)
					else
						functionData.phFilter:setValueCompareParams(DensityValueCompareType.GREATER, 1)
						functionData.multiModifier:addExecuteAddWithStats(tostring(i), -decreasePerHarvest.decreaseValue, functionData.modifier, filter, functionData.soilFilter, functionData.phFilter)
					end
				end
			end
			functionData.accumulators = {}
			functionData.numChangedPixels = {}
			functionData.totalNumPixels = {}
			self.densityMapModifiersHarvestMulti = functionData
		end
		local multiModifier = functionData.multiModifier
		densityMapShape:applyToModifier(multiModifier)
		local accumulators = functionData.accumulators
		local numChangedPixels = functionData.numChangedPixels
		local totalNumPixels = functionData.totalNumPixels
		multiModifier:resetStats()
		multiModifier:execute(accumulators, numChangedPixels, totalNumPixels)
		local pHMapChanged = false
		for indexStr, accumulator in pairs(accumulators) do
			if 0 < accumulator then
				local index = tonumber(indexStr)
				local valueTransformation = self.valueTransformations[index]
				self.lastActualValue = accumulator / numChangedPixels[indexStr]
				self.lastTargetValue = valueTransformation.optimalValue
				local decreasePerHarvest = valueTransformation.decreasePerHarvest[1]
				self.lastRegularValue = valueTransformation.optimalValue - decreasePerHarvest.decreaseValue * 1.5 * valueTransformation.regularOffset
				pHMapChanged = true
			end
		end
		if pHMapChanged then
			self:setMinimapRequiresUpdate(true)
		end
		return pHMapChanged
	end
end
function PHMap:getSprayFunctionData()
	local functionData = self.densityMapModifiersSpray
	if functionData == nil then
		functionData = {}
		local soilMap = self.soilMap
		functionData.modifier = DensityMapModifier.new(self.bitVectorMap, self.firstChannel, self.numChannels, g_terrainNode)
		functionData.soilFilter = DensityMapFilter.new(soilMap.bitVectorMap, soilMap.typeFirstChannel, soilMap.typeNumChannels)
		functionData.phFilter = DensityMapFilter.new(self.bitVectorMap, self.firstChannel, self.numChannels)
		functionData.phFilter:setValueCompareParams(DensityValueCompareType.GREATER, self.maxVisibleValue)
		functionData.phFilterMax = DensityMapFilter.new(self.bitVectorMap, self.firstChannel, self.numChannels)
		functionData.phFilterMax:setValueCompareParams(DensityValueCompareType.GREATER, self.maxVisibleValue)
		functionData.modifierLock = DensityMapModifier.new(self.bitVectorMapPHStateChange, 1, 1, g_terrainNode)
		functionData.lockFilter = DensityMapFilter.new(self.bitVectorMapPHStateChange, 1, 1)
		functionData.lockFilter:setValueCompareParams(DensityValueCompareType.EQUAL, 0)
		local fieldGroundSystem = g_currentMission.fieldGroundSystem
		local sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_TYPE)
		functionData.sprayTypeFilter = DensityMapFilter.new(sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels)
		self.densityMapModifiersSpray = functionData
	end
	return functionData
end
function PHMap:preUpdatePHLevelAtArea(densityMapShape, sprayTypeIndex, delta)
	local coverMap = self.coverMap
	local soilMap = self.soilMap
	if coverMap ~= nil and (coverMap.bitVectorMap ~= nil and (soilMap ~= nil and soilMap.bitVectorMap ~= nil)) then
		local sprayTypeDesc = g_sprayTypeManager:getSprayTypeByIndex(sprayTypeIndex)
		if sprayTypeDesc ~= nil then
			local functionData = self:getSprayFunctionData()
			local modifierLock = functionData.modifierLock
			local sprayTypeFilter = functionData.sprayTypeFilter
			densityMapShape:applyToModifier(modifierLock)
			sprayTypeFilter:setSupersamplingMode(DensityFilterSupersamplingMode.ANY)
			sprayTypeFilter:setValueCompareParams(DensityValueCompareType.EQUAL, sprayTypeDesc.sprayGroundType)
			modifierLock:executeSet(0)
			modifierLock:executeSet(1, sprayTypeFilter)
		end
	end
end
function PHMap:addPHLevelAtArea(densityMapShape, sprayTypeIndex, delta, ignoreLock)
	local coverMap = self.coverMap
	local soilMap = self.soilMap
	if coverMap ~= nil and (coverMap.bitVectorMap ~= nil and (soilMap ~= nil and soilMap.bitVectorMap ~= nil)) then
		local sprayTypeDesc = g_sprayTypeManager:getSprayTypeByIndex(sprayTypeIndex)
		if sprayTypeDesc ~= nil then
			local functionData = self:getSprayFunctionData()
			local modifier = functionData.modifier
			local modifierLock = functionData.modifierLock
			local phFilterMax = functionData.phFilterMax
			local lockFilter = functionData.lockFilter
			densityMapShape:applyToModifier(modifier)
			densityMapShape:applyToModifier(modifierLock)
			if ignoreLock then
				lockFilter = nil
			end
			local _, numChangedPixels, _ = modifier:executeAddWithStats(delta, lockFilter)
			modifier:executeSet(self.maxVisibleValue, phFilterMax)
			modifierLock:executeSet(1, lockFilter)
			if 0 < numChangedPixels then
				self:setMinimapRequiresUpdate(true)
			end
			return numChangedPixels
		end
	end
end
function PHMap:updatePHLevelAtArea(densityMapShape, sprayTypeIndex, targetLevel, ignoreLock)
	targetLevel = math.min(targetLevel, self.maxValue)
	local coverMap = self.coverMap
	local soilMap = self.soilMap
	if coverMap ~= nil and (coverMap.bitVectorMap ~= nil and (soilMap ~= nil and soilMap.bitVectorMap ~= nil)) then
		local sprayTypeDesc = g_sprayTypeManager:getSprayTypeByIndex(sprayTypeIndex)
		if sprayTypeDesc ~= nil then
			local functionData = self:getSprayFunctionData()
			local modifier = functionData.modifier
			local modifierLock = functionData.modifierLock
			local phFilter = functionData.phFilter
			local lockFilter = functionData.lockFilter
			densityMapShape:applyToModifier(modifier)
			densityMapShape:applyToModifier(modifierLock)
			if ignoreLock then
				lockFilter = nil
			end
			phFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, 0, targetLevel - 1)
			local _, numChangedPixels, _ = modifier:executeSetWithStats(targetLevel, phFilter, lockFilter)
			modifierLock:executeSet(1, lockFilter)
			if 0 < numChangedPixels then
				self:setMinimapRequiresUpdate(true)
			end
			return numChangedPixels
		end
	end
end
function PHMap:setPHLevelAtArea(densityMapShape, sprayTypeIndex, targetLevel, ignoreLock)
	targetLevel = math.clamp(targetLevel, 0, self.maxValue)
	local coverMap = self.coverMap
	local soilMap = self.soilMap
	if coverMap ~= nil and (coverMap.bitVectorMap ~= nil and (soilMap ~= nil and soilMap.bitVectorMap ~= nil)) then
		local sprayTypeDesc = g_sprayTypeManager:getSprayTypeByIndex(sprayTypeIndex)
		if sprayTypeDesc ~= nil then
			local functionData = self:getSprayFunctionData()
			local modifier = functionData.modifier
			local modifierLock = functionData.modifierLock
			local phFilter = functionData.phFilter
			local lockFilter = functionData.lockFilter
			densityMapShape:applyToModifier(modifier)
			densityMapShape:applyToModifier(modifierLock)
			if ignoreLock then
				lockFilter = nil
			end
			local _, numChangedPixels, _ = modifier:executeSetWithStats(targetLevel, lockFilter)
			modifierLock:executeSet(1, lockFilter)
			if 0 < numChangedPixels then
				self:setMinimapRequiresUpdate(true)
			end
			return numChangedPixels
		end
	end
end
function PHMap:getLevelAtWorldPos(x, z)
	x = MathUtil.round((x + g_currentMission.terrainSize * 0.5) / g_currentMission.terrainSize * self.sizeX + 0.5) - 1
	z = MathUtil.round((z + g_currentMission.terrainSize * 0.5) / g_currentMission.terrainSize * self.sizeY + 0.5) - 1
	if self.coverMap:getIsUncoveredAtPos(x, z) then
		return getBitVectorMapPoint(self.bitVectorMap, x, z, self.firstChannel, self.numChannels)
	else
		return 0
	end
end
function PHMap:getIsLockedAtWorldPos(wx, wz, sprayTypeIndex)
	local coverMap = self.coverMap
	local soilMap = self.soilMap
	if coverMap ~= nil and (coverMap.bitVectorMap ~= nil and (soilMap ~= nil and soilMap.bitVectorMap ~= nil)) then
		local modifierLock = self.densityMapModifiersLockedState.modifierLock
		local sprayTypeFilter = self.densityMapModifiersLockedState.sprayTypeFilter
		local coverMaskFilter = self.densityMapModifiersLockedState.coverMaskFilter
		if modifierLock == nil or sprayTypeFilter == nil or coverMaskFilter == nil then
			self.densityMapModifiersLockedState.modifierLock = DensityMapModifier.new(self.bitVectorMapPHStateChange, 1, 1, g_terrainNode)
			modifierLock = self.densityMapModifiersLockedState.modifierLock
			modifierLock:setPolygonRoundingMode(DensityRoundingMode.INCLUSIVE)
			local fieldGroundSystem = g_currentMission.fieldGroundSystem
			local sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_TYPE)
			self.densityMapModifiersLockedState.sprayTypeFilter = DensityMapFilter.new(sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels)
			sprayTypeFilter = self.densityMapModifiersLockedState.sprayTypeFilter
			sprayTypeFilter:setSupersamplingMode(DensityFilterSupersamplingMode.ALL)
			self.densityMapModifiersLockedState.coverMaskFilter = DensityMapFilter.new(coverMap.bitVectorMap, coverMap.firstChannel, coverMap.numChannels)
			coverMaskFilter = self.densityMapModifiersLockedState.coverMaskFilter
			coverMaskFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)
		end
		local sprayTypeDesc = g_sprayTypeManager:getSprayTypeByIndex(sprayTypeIndex)
		if sprayTypeDesc ~= nil then
			modifierLock:setParallelogramWorldCoords(wx, wz, wx + 0.001, wz, wx, wz + 0.001, DensityCoordType.POINT_POINT_POINT)
			sprayTypeFilter:setValueCompareParams(DensityValueCompareType.NOTEQUAL, sprayTypeDesc.sprayGroundType)
			local _, numPixels, _ = modifierLock:executeGet(coverMaskFilter, sprayTypeFilter)
			return numPixels == 0
		end
	end
	return false
end
function PHMap:getNextValidDetectionPoint(wx, wz, dirX, dirZ, maxDistance, sprayTypeIndex)
	wx, wz = ValueMap.roundToPixelCenter(wx, wz, g_currentMission.terrainSize, self.sizeX)
	if math.abs(dirZ) < math.abs(dirX) then
		dirX = math.sign(dirX)
		dirZ = 0
	else
		dirX = 0
		dirZ = math.sign(dirZ)
	end
	local distance = g_currentMission.terrainSize / self.sizeX
	local foundUncovered = false
	for i = 1, math.ceil(maxDistance / distance) do
		if self.coverMap:getIsUncoveredAtPos(wx, wz, true) then
			foundUncovered = true
			if not self:getIsLockedAtWorldPos(wx, wz, sprayTypeIndex) then
				return wx, wz, true
			end
		end
		wx = wx + dirX * distance
		wz = wz + dirZ * distance
	end
	return nil, nil, foundUncovered
end
function PHMap:getLimeUsage(workingWidth, lastSpeed, statesChanged, dt)
	local literPerHectar = self:getLimeUsageByStateChange(statesChanged)
	local litersPerUpdate = literPerHectar * (lastSpeed / 3600) / (10000 / workingWidth) * dt
	local regularUsage = self.regularLimeUsage * (lastSpeed / 3600) / (10000 / workingWidth) * dt
	return litersPerUpdate, literPerHectar, regularUsage
end
function PHMap:getLimeUsageByStateChange(statesChanged)
	return self.limeUsage.usagePerState * statesChanged
end
function PHMap:getDefaultLimeStateChange()
	return self.stateChangeDefault
end
function PHMap:getPhValueFromChangedStates(statesChanged)
	return statesChanged * self.pHValuePerState
end
function PHMap:getPhValueFromInternalValue(internal)
	for i = 1, #self.pHValues do
		local pHValue = self.pHValues[i]
		if pHValue.value == math.floor(internal) then
			return pHValue.realValue
		end
	end
	return 0
end
function PHMap:getNearestPhValueFromValue(value)
	local minDifference = 100
	local minValue = 0
	local minValueInternal = 0
	if 0 < value then
		for i = 1, #self.pHValues do
			local pHValue = self.pHValues[i].realValue
			local difference = math.abs(value - pHValue)
			if difference < minDifference then
				minDifference = difference
				minValue = pHValue
				minValueInternal = self.pHValues[i].value
			end
		end
	end
	return minValue, minValueInternal
end
function PHMap:getOptimalPHValueForSoilTypeIndex(soilTypeIndex)
	for i = 1, #self.valueTransformations do
		local valueTransformation = self.valueTransformations[i]
		if valueTransformation.soilTypeIndex == soilTypeIndex then
			return valueTransformation.optimalValue
		end
	end
	return 0
end
function PHMap:getMinMaxValue()
	if 0 < #self.pHValues then
		return self.pHValues[1].realValue, self.pHValues[#self.pHValues].realValue, #self.pHValues
	else
		return 0, 1, 0
	end
end
function PHMap:updateLastPhValues()
	local actual = self.lastActualValue
	local target = self.lastTargetValue
	local regular = self.lastRegularValue
	self.lastActualValue = -1
	self.lastTargetValue = -1
	self.lastRegularValue = -1
	return actual, target, regular
end
function PHMap:getYieldFactorByLevelDifference(difference)
	return self.yieldCurve:get(difference)
end
function PHMap:buildOverlay(overlay, filter, isColorBlindMode, isMinimap)
	resetDensityMapVisualizationOverlay(overlay)
	setOverlayColor(overlay, 1, 1, 1, 1)
	local coverMap = self.coverMap
	if coverMap ~= nil then
		local coverMask = bit32.lshift(2 ^ (coverMap.numChannels - 1) - 1, 1)
		for i = 1, #self.pHValues do
			local pHValue = self.pHValues[i]
			if pHValue.color == nil then
				continue
			end
			if filter[pHValue.filterIndex] then
				local color = pHValue.color
				if isColorBlindMode then
					color = pHValue.colorBlind or pHValue.color
				end
				setDensityMapVisualizationOverlayStateColor(overlay, self.bitVectorMap, coverMap.bitVectorMap, coverMask, self.firstChannel, self.numChannels, pHValue.value, color[1], color[2], color[3])
			end
		end
	end
end
function PHMap:getDisplayValues()
	if self.valuesToDisplay == nil then
		self.valuesToDisplay = {}
		for i = 1, #self.pHValuesToDisplay do
			local pHValue = self.pHValuesToDisplay[i]
			local yieldValueToDisplay = {}
			yieldValueToDisplay.colors = {}
			yieldValueToDisplay.colors[true] = { pHValue.colorBlind or pHValue.color }
			yieldValueToDisplay.colors[false] = { pHValue.color }
			yieldValueToDisplay.description = string.format("%.2f", pHValue.realValue)
			table.insert(self.valuesToDisplay, yieldValueToDisplay)
		end
		local yieldValueToDisplay = {}
		yieldValueToDisplay.colors = {}
		yieldValueToDisplay.colors[true] = { { 0, 0, 0 } }
		yieldValueToDisplay.colors[false] = { { 0, 0, 0 } }
		yieldValueToDisplay.description = self.outdatedLabel
		table.insert(self.valuesToDisplay, yieldValueToDisplay)
	end
	return self.valuesToDisplay
end
function PHMap:getValueFilter()
	if self.valueFilter == nil or self.valueFilterEnabled == nil then
		self.valueFilter = {}
		self.valueFilterEnabled = {}
		local numValues = #self.pHValuesToDisplay
		for i = 1, numValues + 1 do
			table.insert(self.valueFilter, true)
			table.insert(self.valueFilterEnabled, i <= numValues)
		end
	end
	return self.valueFilter, self.valueFilterEnabled
end
function PHMap:getMinimapZoomFactor()
	return 3
end
function PHMap:collectFieldInfos(fieldInfoDisplayExtension)
	local name = g_i18n:getText("fieldInfo_phValue", PHMap.MOD_NAME)
	fieldInfoDisplayExtension:addFieldInfo(name, self, self.updateFieldInfoDisplay, 2, self.getFieldInfoYieldChange)
end
function PHMap:getAllowCoverage()
	return true
end
function PHMap:getHelpLinePage()
	return 4
end
function PHMap:updateFieldInfoDisplay(fieldInfo, x, z, isColorBlindMode)
	local phLevel = self:getLevelAtWorldPos(x, z)
	local soilTypeIndex = self.soilMap:getTypeIndexAtWorldPos(x, z)
	for i = 1, #self.valueTransformations do
		local valueTransformation = self.valueTransformations[i]
		if valueTransformation.soilTypeIndex == soilTypeIndex then
			local color = nil
			local additionalText = nil
			local showWarning = nil
			local levelDifference = math.abs(valueTransformation.optimalValue - phLevel)
			for j = 1, #self.levelDifferenceColors do
				local levelDifferenceColor = self.levelDifferenceColors[j]
				if levelDifferenceColor.levelDifference <= levelDifference then
					color = isColorBlindMode and levelDifferenceColor.colorBlind or levelDifferenceColor.color
					additionalText = levelDifferenceColor.additionalText
					showWarning = levelDifferenceColor.showWarning
				end
			end
			fieldInfo.pHFactor = self:getYieldFactorByLevelDifference(phLevel - valueTransformation.optimalValue)
			return string.format("%.3f / %.3f", self:getPhValueFromInternalValue(phLevel), self:getPhValueFromInternalValue(valueTransformation.optimalValue)), color, additionalText, showWarning
		end
	end
	return nil
end
function PHMap:getFieldInfoYieldChange(fieldInfo)
	return fieldInfo.pHFactor or 0, 0.2
end
function PHMap:drawYieldDebug(pHActualValue, pHTargetValue)
	if self.debugGraph == nil then
		self.debugGraph = Graph.new(#self.yieldCurve.keyframes, 0.45, 0.05, 0.2, 0.15, 0, 100, false, "%", Graph.STYLE_LINES)
		self.debugGraph:setHorizontalLine(10, true, 1, 1, 1, 1)
		self.debugGraph:setVerticalLine(0.1, false, 1, 1, 1, 1)
		self.debugGraph:setColor(0, 1, 0, 1)
	end
	local minTime = math.huge
	local maxTime = -math.huge
	for i = 1, #self.yieldCurve.keyframes do
		local keyframe = self.yieldCurve.keyframes[i]
		local value = self.yieldCurve:get(keyframe.time)
		self.debugGraph:setValue(i, value * 100)
		minTime = math.min(keyframe.time, minTime)
		maxTime = math.max(keyframe.time, maxTime)
	end
	self.debugGraph:draw()
	if minTime ~= math.huge then
		local x = self.debugGraph.left + MathUtil.inverseLerp(minTime, maxTime, pHActualValue - pHTargetValue) * self.debugGraph.width
		setOverlayColor(self.debugGraph.overlayHLine, 1, 0, 0, 1)
		renderOverlay(self.debugGraph.overlayHLine, x, self.debugGraph.bottom, g_pixelSizeX, self.debugGraph.height)
		setOverlayColor(self.debugGraph.overlayHLine, 1, 1, 1, 1)
	end
end
function PHMap:debugSetPHLevel(fieldId, pHLevel)
	fieldId = tonumber(fieldId)
	pHLevel = tonumber(pHLevel)
	if fieldId == nil or pHLevel == nil then
		Logging.error("PHMap: Invalid parameters. Usage: pfPHSetLevel <fieldId> <pHLevel>")
		return
	end
	local field = g_fieldManager:getFieldById(tonumber(fieldId))
	if field ~= nil and field.getDensityMapPolygon ~= nil then
		local area = field:getDensityMapPolygon()
		local _, targetLevel = self:getNearestPhValueFromValue(pHLevel)
		self:setPHLevelAtArea(area, SprayType.LIME, targetLevel, true)
		Logging.info("PHMap: Set pH level of field %d to %.1f", fieldId, pHLevel)
	end
end
function PHMap:onRealisticSpreadPatternSettingChanged(value)
	self.realisticSpreadPatternEnabled = value
end
function PHMap:onRealisticSpreadOutputSettingChanged(value)
	self.realisticSpreadOutputEnabled = value
end
function PHMap:overwriteGameFunctions(pfModule)
	PHMap:superClass().overwriteGameFunctions(self, pfModule)
end
