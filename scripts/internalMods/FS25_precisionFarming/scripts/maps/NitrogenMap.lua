NitrogenMap = {}
NitrogenMap.MOD_NAME = g_currentModName
NitrogenMap.NUM_BITS = 6
NitrogenMap.DEBUG_N_OFFSET_MAP = false
local NitrogenMap_mt = Class(NitrogenMap, ValueMap)
function NitrogenMap.new(pfModule, customMt)
	local self = ValueMap.new(pfModule, customMt or NitrogenMap_mt)
	self.name = "nitrogenMap"
	self.id = "N_MAP"
	self.label = "ui_mapOverviewNitrogen"
	self.densityMapModifiersInitialize = {}
	self.densityMapModifiersLockedState = {}
	self.densityMapModifiersSpray = nil
	self.densityMapModifiersDestroyFruit = {}
	self.densityMapModifiersStrawChopper = {}
	self.densityMapModifiersCropSensor = nil
	self.densityMapModifiersResetLock = {}
	self.densityMapModifiersFruitCheck = {}
	self.lastActualValue = -1
	self.lastTargetValue = -1
	self.lastYieldPotential = -1
	self.minimapGradientSliceId = "precisionFarming.gradient_red_green"
	self.minimapGradientColorBlindSliceId = "precisionFarming.gradient_color_blind"
	self.minimapLabelName = g_i18n:getText("ui_mapOverviewNitrogen", NitrogenMap.MOD_NAME)
	self.minimapLabelNameMission = g_i18n:getText("ui_growthMapFertilized")
	if g_server ~= nil then
		addConsoleCommand("pfNitrogenSet", "Sets the given nitrogen level on the given field", "debugSetNitrogenLevel", self, "fieldId; nitrogenLevel; [measured]")
	end
	return self
end
function NitrogenMap:initialize()
	NitrogenMap:superClass().initialize(self)
	self.densityMapModifiersInitialize = {}
	self.densityMapModifiersLockedState = {}
	self.densityMapModifiersSpray = nil
	self.densityMapModifiersDestroyFruit = {}
	self.densityMapModifiersStrawChopper = {}
	self.densityMapModifiersCropSensor = nil
	self.densityMapModifiersResetLock = {}
	self.densityMapModifiersFruitCheck = {}
	self.lastActualValue = -1
	self.lastTargetValue = -1
	self.lastYieldPotential = -1
end
function NitrogenMap:delete()
	if g_server ~= nil then
		removeConsoleCommand("pfNitrogenSet")
	end
	NitrogenMap:superClass().delete(self)
end
function NitrogenMap:loadFromXML(xmlFile, key, baseDirectory, configFileName, mapFilename)
	key = key .. ".nitrogenMap"
	self.firstChannel = getXMLInt(xmlFile, key .. ".bitVectorMap#firstChannel") or 1
	self.numChannels = getXMLInt(xmlFile, key .. ".bitVectorMap#numChannels") or 4
	self.maxValue = getXMLInt(xmlFile, key .. ".bitVectorMap#maxValue") or 2 ^ self.numChannels - 1
	self.sizeX = 1024
	self.sizeY = 1024
	self.bitVectorMap, self.newBitVectorMap = self:loadSavedBitVectorMap("nitrogenMap", "precisionFarming_nitrogenMap.grle", self.numChannels, self.sizeX)
	self:addBitVectorMapToSync(self.bitVectorMap)
	self:addBitVectorMapToSave(self.bitVectorMap, "precisionFarming_nitrogenMap.grle")
	self:addBitVectorMapToDelete(self.bitVectorMap)
	self.noiseFilename = getXMLString(xmlFile, key .. ".noiseMap#filename")
	self.noiseNumChannels = getXMLInt(xmlFile, key .. ".noiseMap#numChannels") or 2
	self.noiseResolution = getXMLInt(xmlFile, key .. ".noiseMap#resolution") or 1024
	self.noiseMaxValue = 2 ^ self.noiseNumChannels - 1
	self.bitVectorMapNoise = createBitVectorMap("nitrogenNoiseMap")
	if self.noiseFilename ~= nil then
		self.noiseFilename = Utils.getFilename(self.noiseFilename, baseDirectory)
		if not loadBitVectorMapFromFile(self.bitVectorMapNoise, self.noiseFilename, self.noiseNumChannels) then
			Logging.xmlWarning(xmlFile, "Error while loading pH noise map '%s'", self.noiseFilename)
			self.noiseFilename = nil
		end
	end
	if self.noiseFilename == nil then
		loadBitVectorMapNew(self.bitVectorMapNoise, self.noiseResolution, self.noiseResolution, self.noiseNumChannels, false)
	end
	self:addBitVectorMapToDelete(self.bitVectorMapNoise)
	self.bitVectorMapNOffset, self.bitVectorMapNOffsetIsNew = self:loadSavedBitVectorMap("nOffsetMap", "precisionFarming_nOffsetMap.grle", 4, self.noiseResolution)
	self:addBitVectorMapToSave(self.bitVectorMapNOffset, "precisionFarming_nOffsetMap.grle")
	self:addBitVectorMapToDelete(self.bitVectorMapNOffset)
	self.nOffsetIndexToOffset = {}
	self.nOffsetIndexToOffset[1] = -5
	self.nOffsetIndexToOffset[2] = -4
	self.nOffsetIndexToOffset[3] = -3
	self.nOffsetIndexToOffset[4] = -2
	self.nOffsetIndexToOffset[5] = -1
	self.nOffsetIndexToOffset[6] = 0
	self.nOffsetIndexToOffset[7] = 1
	self.nOffsetIndexToOffset[8] = 2
	self.bitVectorMapNStateChange = self:loadSavedBitVectorMap("nLockStateMap", "precisionFarming_nLockStateMap.grle", 2, self.noiseResolution)
	self:addBitVectorMapToSave(self.bitVectorMapNStateChange, "precisionFarming_nLockStateMap.grle")
	self:addBitVectorMapToDelete(self.bitVectorMapNStateChange)
	self.bitVectorMapNInitMask = self:loadSavedBitVectorMap("nInitMaskMap", "nInitMaskMap.grle", 1, self.noiseResolution)
	self:addBitVectorMapToDelete(self.bitVectorMapNInitMask)
	self.bitVectorMapNFruitFilterMask = self:loadSavedBitVectorMap("nFruitFilterMask", "nFruitFilterMask.grle", 1, self.noiseResolution)
	self:addBitVectorMapToDelete(self.bitVectorMapNFruitFilterMask)
	self.bitVectorMapNFruitDestroyMask = self:loadSavedBitVectorMap("nFruitDestroyMask", "nFruitDestroyMask.grle", 2, self.noiseResolution)
	self:addBitVectorMapToDelete(self.bitVectorMapNFruitDestroyMask)
	self.bitVectorMapChoppedStrawMask = self:loadSavedBitVectorMap("choppedStrawMask", "choppedStrawMask.grle", 2, self.noiseResolution)
	self:addBitVectorMapToDelete(self.bitVectorMapChoppedStrawMask)
	self.amountPerState = getXMLFloat(xmlFile, key .. ".nitrogenValues#amountPerState") or 5
	self.nitrogenValues = {}
	self.numVisualValues = 0
	self.maxVisibleValue = 0
	local i = 0
	while true do
		local baseKey = string.format("%s.nitrogenValues.nitrogenValue(%d)", key, i)
		if not hasXMLProperty(xmlFile, baseKey) then
			break
		end
		local nitrogenValue = {}
		nitrogenValue.value = getXMLInt(xmlFile, baseKey .. "#value") or 0
		nitrogenValue.realValue = getXMLFloat(xmlFile, baseKey .. "#realValue") or 0
		nitrogenValue.showOnHud = Utils.getNoNil(getXMLBool(xmlFile, baseKey .. "#showOnHud"), true)
		nitrogenValue.color = string.getVector(getXMLString(xmlFile, baseKey .. "#color"), 3)
		nitrogenValue.colorBlind = string.getVector(getXMLString(xmlFile, baseKey .. "#colorBlind"), 3)
		table.insert(self.nitrogenValues, nitrogenValue)
		nitrogenValue.index = #self.nitrogenValues
		nitrogenValue.filterIndex = self.numVisualValues + 1
		if nitrogenValue.showOnHud then
			self.numVisualValues = self.numVisualValues + 1
		end
		self.maxVisibleValue = math.max(self.maxVisibleValue, nitrogenValue.value)
		i = i + 1
	end
	local lastOnHud = nil
	for l = 1, #self.nitrogenValues do
		local nitrogenValue = self.nitrogenValues[l]
		if not nitrogenValue.showOnHud then
			if lastOnHud == nil then
				continue
			end
			nitrogenValue.filterIndex = lastOnHud.filterIndex
			local nextOnHud = nil
			for j = l + 1, #self.nitrogenValues do
				local nextNitrogenValue = self.nitrogenValues[j]
				if nextNitrogenValue.showOnHud then
					nextOnHud = nextNitrogenValue
					break
				end
			end
			if nextOnHud == nil then
				continue
			end
			local numValues = nextOnHud.index - lastOnHud.index
			local r = lastOnHud.color[1] + (nextOnHud.color[1] - lastOnHud.color[1]) / numValues * (l - lastOnHud.index)
			local g = lastOnHud.color[2] + (nextOnHud.color[2] - lastOnHud.color[2]) / numValues * (l - lastOnHud.index)
			local b = lastOnHud.color[3] + (nextOnHud.color[3] - lastOnHud.color[3]) / numValues * (l - lastOnHud.index)
			nitrogenValue.color = { r, g, b }
			r = lastOnHud.colorBlind[1] + (nextOnHud.colorBlind[1] - lastOnHud.colorBlind[1]) / numValues * (l - lastOnHud.index)
			g = lastOnHud.colorBlind[2] + (nextOnHud.colorBlind[2] - lastOnHud.colorBlind[2]) / numValues * (l - lastOnHud.index)
			b = lastOnHud.colorBlind[3] + (nextOnHud.colorBlind[3] - lastOnHud.colorBlind[3]) / numValues * (l - lastOnHud.index)
			nitrogenValue.colorBlind = { r, g, b }
		else
			lastOnHud = nitrogenValue
		end
	end
	self.initialValues = {}
	i = 0
	while true do
		local baseKey = string.format("%s.initialValues.initialValue(%d)", key, i)
		if not hasXMLProperty(xmlFile, baseKey) then
			break
		end
		local initialValue = {}
		initialValue.soilTypeIndex = getXMLInt(xmlFile, baseKey .. "#soilTypeIndex") or 1
		initialValue.baseRange = string.getVector(getXMLString(xmlFile, baseKey .. "#baseValueRange"), self.noiseMaxValue + 1)
		for j = 1, #initialValue.baseRange do
			initialValue.baseRange[j] = MathUtil.round(initialValue.baseRange[j] / self.amountPerState)
		end
		table.insert(self.initialValues, initialValue)
		i = i + 1
	end
	self.initialSprayLevelBonus = string.getVector(getXMLString(xmlFile, key .. ".initialValues#sprayLevelBonus")) or { 0, 0 }
	for j = 1, #self.initialSprayLevelBonus do
		self.initialSprayLevelBonus[j] = MathUtil.round(self.initialSprayLevelBonus[j] / self.amountPerState)
	end
	self.applicationRates = {}
	self:loadApplicationRatesFromXML(xmlFile, key)
	self.fertilizerUsage = {}
	self.fertilizerUsage.nAmounts = {}
	self:loadFertilizerUsageFromXML(xmlFile, key)
	self.fruitRequirements = {}
	self.fruitTypeIndexToFruitRequirement = {}
	self:loadFruitRequirementsFromXML(configFileName, xmlFile, key)
	self.cropSensorFruitTypes = {}
	self:loadCropSensorFruitTypesFromXML(configFileName, xmlFile, key)
	local missionInfo = g_currentMission.missionInfo
	local mapXMLFilename = Utils.getFilename(missionInfo.mapXMLFilename, g_currentMission.baseDirectory)
	local mapXMLFile = loadXMLFile("MapXML", mapXMLFilename)
	if mapXMLFile ~= nil then
		self:loadApplicationRatesFromXML(mapXMLFile, "map.precisionFarming")
		self:loadFertilizerUsageFromXML(mapXMLFile, "map.precisionFarming")
		self:loadFruitRequirementsFromXML(missionInfo.mapXMLFilename, mapXMLFile, "map.precisionFarming")
		self:loadCropSensorFruitTypesFromXML(missionInfo.mapXMLFilename, mapXMLFile, "map.precisionFarming")
		delete(mapXMLFile)
	end
	for _, fruitType in ipairs(g_fruitTypeManager:getFruitTypes()) do
		if self.fruitTypeIndexToFruitRequirement[fruitType.index] == nil then
			local fruitRequirement = {}
			fruitRequirement.fruitTypeName = fruitType.name
			fruitRequirement.fruitType = fruitType
			fruitRequirement.bySoilType = self.fruitRequirements[1].bySoilType
			fruitRequirement.averageTargetLevel = self.fruitRequirements[1].averageTargetLevel or 0
			table.insert(self.fruitRequirements, fruitRequirement)
			self.fruitTypeIndexToFruitRequirement[fruitType.index] = fruitRequirement
			Logging.devInfo("Use default Nitrogen requirements for fruitType '%s'", fruitType.name)
		end
	end
	self.yieldCurve = AnimCurve.new(linearInterpolator1)
	i = 0
	while true do
		local baseKey = string.format("%s.yieldMappings.yieldMapping(%d)", key, i)
		if not hasXMLProperty(xmlFile, baseKey) then
			break
		end
		local difference = (getXMLInt(xmlFile, baseKey .. "#difference") or 0) / self.amountPerState
		local yieldFactor = getXMLFloat(xmlFile, baseKey .. "#yieldFactor") or 1
		self.yieldCurve:addKeyframe({ yieldFactor, ["time"] = difference })
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
		levelDifferenceColor.levelDifference = (getXMLInt(xmlFile, baseKey .. "#levelDifference") or 0) / self.amountPerState
		levelDifferenceColor.color = string.getVector(getXMLString(xmlFile, baseKey .. "#color"), 3) or { 0, 0, 0 }
		levelDifferenceColor.colorBlind = string.getVector(getXMLString(xmlFile, baseKey .. "#colorBlind"), 3) or { 0, 0, 0 }
		levelDifferenceColor.color[4] = 1
		levelDifferenceColor.colorBlind[4] = 1
		levelDifferenceColor.additionalText = g_i18n:convertText(getXMLString(xmlFile, baseKey .. "#text"), NitrogenMap.MOD_NAME)
		levelDifferenceColor.showWarning = Utils.getNoNil(getXMLBool(xmlFile, baseKey .. "#showWarning"), false)
		table.insert(self.levelDifferenceColors, levelDifferenceColor)
		i = i + 1
	end
	self.fertilizerColors = { [true] = {}, [false] = {} }
	local maxFertilizerStates = g_currentMission.fieldGroundSystem:getMaxValue(FieldDensityMap.SPRAY_LEVEL)
	for colorBlind, colors in pairs(MapOverlayGenerator.FRUIT_COLORS_FERTILIZED) do
		for i = #colors, 1, -1 do
			local color = colors[i]
			table.insert(self.fertilizerColors[colorBlind], 1, color)
			if #self.fertilizerColors[colorBlind] ~= maxFertilizerStates then
				continue
			end
		end
	end
	self.fertilizerFillTypes = {}
	for _, applicationRate in ipairs(self.applicationRates) do
		self.fertilizerFillTypes[applicationRate.fillTypeIndex] = applicationRate.fillTypeIndex
	end
	self.stateChangeDefault = math.ceil((getXMLFloat(xmlFile, key .. ".applicationRates#defaultRate") or 100) / self.amountPerState)
	self.choppedStrawStateChange = (getXMLInt(xmlFile, key .. ".choppedStraw#increase") or 25) / self.amountPerState
	self.catchCropsStateChange = (getXMLInt(xmlFile, key .. ".catchCrops#increase") or 25) / self.amountPerState
	self.outdatedLabel = g_i18n:convertText(getXMLString(xmlFile, key .. ".texts#outdatedLabel") or "$l10n_ui_precisionFarming_outdatedData", NitrogenMap.MOD_NAME)
	self.minimapGradientLabelName = string.format("%d - %d kg/ha", self:getMinMaxValue())
	self.coverMap = g_precisionFarming.coverMap
	self.soilMap = g_precisionFarming.soilMap
	self.seedRateMap = g_precisionFarming.seedRateMap
	return true
end
function NitrogenMap:loadApplicationRatesFromXML(xmlFile, key)
	local i = 0
	while true do
		local baseKey = string.format("%s.applicationRates.applicationRate(%d)", key, i)
		if not hasXMLProperty(xmlFile, baseKey) then
			break
		end
		local fillTypeName = getXMLString(xmlFile, baseKey .. "#fillType")
		if fillTypeName ~= nil then
			local fillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(fillTypeName)
			if fillTypeIndex ~= nil then
				if fillTypeIndex ~= FillType.UNKNOWN then
					local applicationRate = {}
					applicationRate.fillTypeIndex = fillTypeIndex
					applicationRate.autoAdjustToFruit = Utils.getNoNil(getXMLBool(xmlFile, baseKey .. "#autoAdjustToFruit"), false)
					applicationRate.regularRate = getXMLFloat(xmlFile, baseKey .. "#regularRate")
					applicationRate.ratesBySoilType = {}
					local j = 0
					while true do
						local soilKey = string.format("%s.soil(%d)", baseKey, j)
						if not hasXMLProperty(xmlFile, soilKey) then
							break
						end
						local rateBySoil = {}
						rateBySoil.soilTypeIndex = getXMLInt(xmlFile, soilKey .. "#soilTypeIndex") or 1
						rateBySoil.rate = (getXMLInt(xmlFile, soilKey .. "#rate") or 5) / self.amountPerState
						table.insert(applicationRate.ratesBySoilType, rateBySoil)
						j = j + 1
					end
					for applicationRateIndex = #self.applicationRates, 1, -1 do
						local _applicationRate = self.applicationRates[applicationRateIndex]
						if _applicationRate.fillTypeIndex == applicationRate.fillTypeIndex then
							table.remove(self.applicationRates, applicationRateIndex)
						end
					end
					table.insert(self.applicationRates, applicationRate)
				else
					Logging.xmlWarning(xmlFile, "Invalid fill type for nitrogen application rate '%s'", baseKey)
				end
			end
		else
			Logging.xmlWarning(xmlFile, "Invalid fill type for nitrogen application rate '%s'", baseKey)
		end
		i = i + 1
	end
end
function NitrogenMap:loadFertilizerUsageFromXML(xmlFile, key)
	local i = 0
	while true do
		local baseKey = string.format("%s.fertilizerUsage.nAmount(%d)", key, i)
		if not hasXMLProperty(xmlFile, baseKey) then
			break
		end
		local fillTypeName = getXMLString(xmlFile, baseKey .. "#fillType")
		if fillTypeName ~= nil then
			local fillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(fillTypeName)
			if fillTypeIndex ~= nil then
				if fillTypeIndex ~= FillType.UNKNOWN then
					local nAmount = {}
					nAmount.fillTypeIndex = fillTypeIndex
					nAmount.amount = getXMLFloat(xmlFile, baseKey .. "#amount") or 1
					for usageIndex = #self.fertilizerUsage.nAmounts, 1, -1 do
						local _nAmount = self.fertilizerUsage.nAmounts[usageIndex]
						if _nAmount.fillTypeIndex == nAmount.fillTypeIndex then
							table.remove(self.fertilizerUsage.nAmounts, usageIndex)
						end
					end
					table.insert(self.fertilizerUsage.nAmounts, nAmount)
				else
					Logging.xmlWarning(xmlFile, "Invalid fill type for nitrogen fertilizer amount '%s'", baseKey)
				end
			end
		else
			Logging.xmlWarning(xmlFile, "Invalid fill type for nitrogen fertilizer amount '%s'", baseKey)
		end
		i = i + 1
	end
end
function NitrogenMap:loadFruitRequirementsFromXML(configFileName, xmlFile, key)
	local i = 0
	while true do
		local baseKey = string.format("%s.fruitRequirements.fruitRequirement(%d)", key, i)
		if not hasXMLProperty(xmlFile, baseKey) then
			break
		end
		local isOverwrittenRequirement = false
		local fruitRequirement = {}
		fruitRequirement.fruitTypeName = getXMLString(xmlFile, baseKey .. "#fruitTypeName")
		if fruitRequirement.fruitTypeName ~= nil then
			for j = 1, #self.fruitRequirements do
				local _fruitRequirement = self.fruitRequirements[j]
				if string.lower(_fruitRequirement.fruitTypeName) == string.lower(fruitRequirement.fruitTypeName) then
					fruitRequirement = _fruitRequirement
					isOverwrittenRequirement = true
				end
			end
			fruitRequirement.alwaysAllowFertilization = Utils.getNoNil(getXMLBool(xmlFile, baseKey .. "#alwaysAllowFertilization"), Utils.getNoNil(fruitRequirement.alwaysAllowFertilization, false))
			fruitRequirement.ignoreOverfertilization = Utils.getNoNil(getXMLBool(xmlFile, baseKey .. "#ignoreOverfertilization"), false)
			fruitRequirement.availableAsDefaultRate = Utils.getNoNil(getXMLBool(xmlFile, baseKey .. "#availableAsDefaultRate"), true)
			fruitRequirement.requiresDefaultMode = Utils.getNoNil(getXMLBool(xmlFile, baseKey .. "#requiresDefaultMode"), false)
			local fruitType = g_fruitTypeManager:getFruitTypeByName(fruitRequirement.fruitTypeName)
			if fruitType ~= nil then
				fruitRequirement.fruitType = fruitType
				fruitRequirement.bySoilType = fruitRequirement.bySoilType or {}
				local j = 0
				while true do
					local soilKey = string.format("%s.soil(%d)", baseKey, j)
					if not hasXMLProperty(xmlFile, soilKey) then
						break
					end
					local soilSettings = {}
					soilSettings.soilTypeIndex = getXMLInt(xmlFile, soilKey .. "#soilTypeIndex") or 1
					local isOverwrittenSoilType = false
					for l = 1, #fruitRequirement.bySoilType do
						local _soilSettings = fruitRequirement.bySoilType[l]
						if _soilSettings.soilTypeIndex == soilSettings.soilTypeIndex then
							soilSettings = _soilSettings
							isOverwrittenSoilType = true
						end
					end
					local targetLevel = getXMLInt(xmlFile, soilKey .. "#targetLevel")
					if targetLevel ~= nil then
						local _, internalTarget = self:getNearestNitrogenValueFromValue(targetLevel)
						targetLevel = internalTarget
					end
					soilSettings.targetLevel = targetLevel or soilSettings.targetLevel or 0
					local reduction = getXMLInt(xmlFile, soilKey .. "#reduction")
					if reduction ~= nil then
						reduction = math.floor(reduction / self.amountPerState)
					end
					soilSettings.reduction = reduction or soilSettings.reduction or 0
					local reductionForage = getXMLInt(xmlFile, soilKey .. "#reductionForage")
					if reductionForage ~= nil then
						reductionForage = math.floor(reductionForage / self.amountPerState)
					end
					soilSettings.reductionForage = reductionForage or soilSettings.reductionForage or soilSettings.reduction
					soilSettings.yieldPotential = getXMLFloat(xmlFile, soilKey .. "#yieldPotential") or soilSettings.yieldPotential or 1
					if not isOverwrittenSoilType then
						table.insert(fruitRequirement.bySoilType, soilSettings)
					end
					j = j + 1
				end
				fruitRequirement.averageTargetLevel = 0
				local numSettings = #fruitRequirement.bySoilType
				if 0 < numSettings then
					local targetLevelSum = 0
					for l = 1, numSettings do
						local soilSettings = fruitRequirement.bySoilType[l]
						targetLevelSum = targetLevelSum + soilSettings.targetLevel
					end
					fruitRequirement.averageTargetLevel = targetLevelSum / numSettings
				end
				if not isOverwrittenRequirement then
					table.insert(self.fruitRequirements, fruitRequirement)
					self.fruitTypeIndexToFruitRequirement[fruitType.index] = fruitRequirement
				end
			end
		else
			Logging.xmlWarning(configFileName, "Invalid fruit type for nitrogen fruitRequirement '%s'", baseKey)
		end
		i = i + 1
	end
end
function NitrogenMap:loadCropSensorFruitTypesFromXML(configFileName, xmlFile, key)
	local fruitTypesStr = getXMLString(xmlFile, key .. ".cropSensor#fruitTypes")
	if fruitTypesStr ~= nil then
		local fruitTypes = fruitTypesStr:split(" ")
		for j = 1, #fruitTypes do
			local fruitType = g_fruitTypeManager:getFruitTypeByName(fruitTypes[j])
			if fruitType ~= nil then
				table.insert(self.cropSensorFruitTypes, fruitType)
			else
				Logging.xmlWarning(xmlFile, "Invalid fruit type '%s' for crop sensor '%s'", fruitTypes[j], key)
			end
		end
	end
end
function NitrogenMap:postLoad(xmlFile, key, baseDirectory, configFileName, mapFilename)
	if self.bitVectorMapNOffsetIsNew then
		local startTime = getTimeSec()
		local modifier = DensityMapModifier.new(self.bitVectorMapNOffset, 0, 3)
		local filter = PerlinNoiseFilter.new(self.bitVectorMapNOffset, 5.5, 1, 0.5, math.random(0, 1000))
		local numValues = 8
		local range = 10000
		for i = 1, 8 do
			local min = (i - 1) / 8 * 10000
			local max = i / 8 * 10000
			filter:setValueCompareParams(DensityValueCompareType.BETWEEN, min, max)
			modifier:executeSet(i - 1, filter)
		end
		Logging.devInfo("Initialized Nitrogen Offset Map in %dms", (getTimeSec() - startTime) * 1000)
	else
		local modifier = DensityMapModifier.new(self.bitVectorMap, self.firstChannel, self.numChannels)
		local filter = DensityMapFilter.new(self.bitVectorMap, self.firstChannel, self.numChannels)
		filter:setValueCompareParams(DensityValueCompareType.GREATER, self.maxValue)
		modifier:executeSet(math.floor(self.maxValue * 0.75), filter)
	end
	return true
end
local worldCoordsToLocalCoords = function(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, size, terrainSize)
	return (startWorldX + terrainSize * 0.5) / terrainSize * size + 0.5 - 1, (startWorldZ + terrainSize * 0.5) / terrainSize * size + 0.5 - 1, (widthWorldX + terrainSize * 0.5) / terrainSize * size + 0.5 - 1, (widthWorldZ + terrainSize * 0.5) / terrainSize * size + 0.5 - 1, (heightWorldX + terrainSize * 0.5) / terrainSize * size + 0.5 - 1, (heightWorldZ + terrainSize * 0.5) / terrainSize * size + 0.5 - 1
end
function NitrogenMap:addSetInitialState(multiModifier, soilBitVector, soilTypeFirstChannel, soilTypeNumChannels, farmlandMask)
	local functionData = self.densityMapModifiersInitialize
	local modifier = functionData.modifier
	local nFilter = functionData.nFilter
	local soilFilter = functionData.soilFilter
	local noiseFilter = functionData.noiseFilter
	local sprayLevelFilter = functionData.sprayLevelFilter
	local sprayLevelFilterInv = functionData.sprayLevelFilterInv
	local maxSprayLevel = functionData.maxSprayLevel
	if modifier == nil or nFilter == nil or soilFilter == nil or noiseFilter == nil or sprayLevelFilter == nil or sprayLevelFilterInv == nil or maxSprayLevel == nil then
		functionData.modifier = DensityMapModifier.new(self.bitVectorMap, self.firstChannel, self.numChannels, g_terrainNode)
		modifier = functionData.modifier
		functionData.nFilter = DensityMapFilter.new(self.bitVectorMap, self.firstChannel, self.numChannels)
		nFilter = functionData.nFilter
		nFilter:setValueCompareParams(DensityValueCompareType.EQUAL, self.maxValue)
		functionData.soilFilter = DensityMapFilter.new(soilBitVector, soilTypeFirstChannel, soilTypeNumChannels)
		soilFilter = functionData.soilFilter
		functionData.noiseFilter = DensityMapFilter.new(self.bitVectorMapNoise, 0, self.noiseNumChannels)
		noiseFilter = functionData.noiseFilter
		local sprayMapId, sprayLevelFirstChannel, sprayLevelNumChannels = g_currentMission.fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_LEVEL)
		functionData.sprayLevelFilter = DensityMapFilter.new(sprayMapId, sprayLevelFirstChannel, sprayLevelNumChannels)
		sprayLevelFilter = functionData.sprayLevelFilter
		functionData.sprayLevelFilterInv = DensityMapFilter.new(sprayMapId, sprayLevelFirstChannel, sprayLevelNumChannels)
		sprayLevelFilterInv = functionData.sprayLevelFilterInv
		functionData.maxSprayLevel = g_currentMission.fieldGroundSystem:getMaxValue(FieldDensityMap.SPRAY_LEVEL)
		maxSprayLevel = functionData.maxSprayLevel
	end
	for i = 1, #self.initialValues do
		local initialValue = self.initialValues[i]
		soilFilter:setValueCompareParams(DensityValueCompareType.EQUAL, initialValue.soilTypeIndex - 1)
		if farmlandMask ~= nil then
			multiModifier:addExecuteSet(self.maxValue, modifier, farmlandMask, soilFilter)
		else
			multiModifier:addExecuteSet(self.maxValue, modifier, soilFilter)
		end
		for j = 1, self.noiseMaxValue + 1 do
			noiseFilter:setValueCompareParams(DensityValueCompareType.EQUAL, j - 1)
			multiModifier:addExecuteSet(initialValue.baseRange[j], modifier, nFilter, noiseFilter)
		end
	end
	if farmlandMask == nil then
		sprayLevelFilter:setSupersamplingMode(DensityFilterSupersamplingMode.ANY)
		sprayLevelFilterInv:setSupersamplingMode(DensityFilterSupersamplingMode.ALL)
		sprayLevelFilter:setValueCompareParams(DensityValueCompareType.EQUAL, 1)
		multiModifier:addExecuteAdd(self.initialSprayLevelBonus[1] or 0, modifier, sprayLevelFilter)
		sprayLevelFilter:setValueCompareParams(DensityValueCompareType.EQUAL, 2)
		sprayLevelFilterInv:setValueCompareParams(DensityValueCompareType.NOTEQUAL, 1)
		multiModifier:addExecuteAdd(self.initialSprayLevelBonus[2] or 0, modifier, sprayLevelFilter, sprayLevelFilterInv)
	end
end
function NitrogenMap:harvestUpdate(filter, fruitIndex, densityMapShape, useMinForageState, strawChopperActive)
	local coverMap = self.coverMap
	local soilMap = self.soilMap
	if coverMap ~= nil and (coverMap.bitVectorMap ~= nil and (soilMap ~= nil and soilMap.bitVectorMap ~= nil)) then
		local functionData = self.densityMapModifiersHarvestMulti
		if functionData == nil then
			functionData = {}
			functionData.modifier = DensityMapModifier.new(self.bitVectorMap, self.firstChannel, self.numChannels, g_terrainNode)
			functionData.soilFilter = DensityMapFilter.new(soilMap.bitVectorMap, soilMap.typeFirstChannel, soilMap.typeNumChannels)
			functionData.modifierOffsetMeasured = DensityMapModifier.new(self.bitVectorMapNOffset, 3, 1, g_terrainNode)
			functionData.multiModifiersByFruitType = {}
			for i = 1, #self.fruitRequirements do
				local fruitRequirement = self.fruitRequirements[i]
				functionData.multiModifiersByFruitType[fruitRequirement.fruitType.index] = {}
				for f = 1, 2 do
					local useForageStates = f == 2
					functionData.multiModifiersByFruitType[fruitRequirement.fruitType.index][useForageStates] = {}
					for strawChopper = 1, 2 do
						local _strawChopperActive = strawChopper == 2
						local multiModifier = DensityMapMultiModifier.new()
						self:addCropSensorUpdateToMultiModifier(multiModifier, filter, false)
						for j = 1, #fruitRequirement.bySoilType do
							local soilSettings = fruitRequirement.bySoilType[j]
							functionData.soilFilter:setValueCompareParams(DensityValueCompareType.EQUAL, soilSettings.soilTypeIndex - 1)
							if useForageStates then
								multiModifier:addExecuteGet(tostring(j), functionData.modifier, filter, functionData.soilFilter)
								if 1 < soilSettings.reductionForage then
									multiModifier:addExecuteAdd(-soilSettings.reductionForage, functionData.modifier, filter, functionData.soilFilter)
								end
							else
								multiModifier:addExecuteGet(tostring(j), functionData.modifier, filter, functionData.soilFilter)
								if 1 < soilSettings.reduction then
									multiModifier:addExecuteAdd(-soilSettings.reduction, functionData.modifier, filter, functionData.soilFilter)
								end
							end
							if _strawChopperActive then
								multiModifier:addExecuteAdd(self.choppedStrawStateChange, functionData.modifier, filter, functionData.soilFilter)
							end
						end
						functionData.multiModifiersByFruitType[fruitRequirement.fruitType.index][useForageStates][_strawChopperActive] = multiModifier
					end
				end
			end
			functionData.accumulators = {}
			functionData.numChangedPixels = {}
			functionData.totalNumPixels = {}
			self.densityMapModifiersHarvestMulti = functionData
		end
		local multiModifiers = functionData.multiModifiersByFruitType[fruitIndex]
		if multiModifiers == nil then
			return false
		end
		multiModifiers = multiModifiers[useMinForageState]
		if multiModifiers == nil then
			return false
		end
		local multiModifier = multiModifiers[strawChopperActive]
		if multiModifier == nil then
			return false
		else
			densityMapShape:applyToModifier(multiModifier)
			local accumulators = functionData.accumulators
			local numChangedPixels = functionData.numChangedPixels
			local totalNumPixels = functionData.totalNumPixels
			multiModifier:resetStats()
			multiModifier:execute(accumulators, numChangedPixels, totalNumPixels)
			local nMapChanged = false
			local fruitRequirement = self.fruitTypeIndexToFruitRequirement[fruitIndex]
			if fruitRequirement ~= nil then
				for indexStr, accumulator in pairs(accumulators) do
					if 0 < accumulator then
						local index = tonumber(indexStr)
						local soilSettings = fruitRequirement.bySoilType[index]
						self.lastActualValue = accumulator / numChangedPixels[indexStr]
						self.lastTargetValue = soilSettings.targetLevel
						self.lastYieldPotential = soilSettings.yieldPotential
						self.lastIgnoreOverfertilization = fruitRequirement.ignoreOverfertilization
						self.lastRegularNValue = fruitRequirement.averageTargetLevel
						nMapChanged = true
					end
				end
			end
			if nMapChanged then
				self:setMinimapRequiresUpdate(true)
			end
			return nMapChanged
		end
	end
end
function NitrogenMap:getSprayFunctionData()
	local functionData = self.densityMapModifiersSpray
	if functionData == nil then
		functionData = {}
		functionData.nModifier = DensityMapModifier.new(self.bitVectorMap, self.firstChannel, self.numChannels, g_terrainNode)
		functionData.nModifier:setPolygonRoundingMode(DensityRoundingMode.INCLUSIVE)
		functionData.modifierLock = DensityMapModifier.new(self.bitVectorMapNStateChange, 1, 1, g_terrainNode)
		functionData.modifierLock:setPolygonRoundingMode(DensityRoundingMode.INCLUSIVE)
		functionData.nFilter = DensityMapFilter.new(self.bitVectorMap, self.firstChannel, self.numChannels)
		functionData.nFilter:setValueCompareParams(DensityValueCompareType.GREATER, self.maxVisibleValue)
		functionData.nFilterMax = DensityMapFilter.new(self.bitVectorMap, self.firstChannel, self.numChannels)
		functionData.nFilterMax:setValueCompareParams(DensityValueCompareType.GREATER, self.maxVisibleValue)
		functionData.lockFilter = DensityMapFilter.new(self.bitVectorMapNStateChange, 1, 1)
		functionData.lockFilter:setValueCompareParams(DensityValueCompareType.EQUAL, 0)
		local fieldGroundSystem = g_currentMission.fieldGroundSystem
		local sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_TYPE)
		functionData.sprayTypeFilter = DensityMapFilter.new(sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels)
		functionData.sprayTypeFilter:setSupersamplingMode(DensityFilterSupersamplingMode.ALL)
		self.densityMapModifiersSpray = functionData
	end
	return functionData
end
function NitrogenMap:preUpdateNitrogenLevelAtArea(densityMapShape, sprayTypeIndex, delta)
	local coverMap = self.coverMap
	local soilMap = self.soilMap
	if coverMap ~= nil and (coverMap.bitVectorMap ~= nil and (soilMap ~= nil and soilMap.bitVectorMap ~= nil)) then
		local functionData = self:getSprayFunctionData()
		local nModifier = functionData.nModifier
		local modifierLock = functionData.modifierLock
		local nFilter = functionData.nFilter
		local nFilterMax = functionData.nFilterMax
		local lockFilter = functionData.lockFilter
		local sprayTypeFilter = functionData.sprayTypeFilter
		local sprayTypeDesc = g_sprayTypeManager:getSprayTypeByIndex(sprayTypeIndex)
		if sprayTypeDesc ~= nil then
			densityMapShape:applyToModifier(modifierLock)
			sprayTypeFilter:setSupersamplingMode(DensityFilterSupersamplingMode.ANY)
			sprayTypeFilter:setValueCompareParams(DensityValueCompareType.EQUAL, sprayTypeDesc.sprayGroundType)
			modifierLock:executeSet(0)
			modifierLock:executeSet(1, sprayTypeFilter)
		end
	end
end
function NitrogenMap:addNitrogenLevelAtArea(densityMapShape, sprayTypeIndex, delta, ignoreLock)
	local coverMap = self.coverMap
	local soilMap = self.soilMap
	if coverMap ~= nil and (coverMap.bitVectorMap ~= nil and (soilMap ~= nil and soilMap.bitVectorMap ~= nil)) then
		local functionData = self:getSprayFunctionData()
		local nModifier = functionData.nModifier
		local modifierLock = functionData.modifierLock
		local nFilterMax = functionData.nFilterMax
		local lockFilter = functionData.lockFilter
		if ignoreLock then
			lockFilter = nil
		end
		local sprayTypeDesc = g_sprayTypeManager:getSprayTypeByIndex(sprayTypeIndex)
		if sprayTypeDesc ~= nil then
			densityMapShape:applyToModifier(nModifier)
			densityMapShape:applyToModifier(modifierLock)
			local _, numChangedPixels, _ = nModifier:executeAddWithStats(delta, lockFilter)
			nModifier:executeSet(self.maxVisibleValue, nFilterMax)
			modifierLock:executeSet(1, lockFilter)
			if 0 < numChangedPixels then
				self:setMinimapRequiresUpdate(true)
			end
			return numChangedPixels
		end
	end
	return 0
end
function NitrogenMap:updateNitrogenLevelAtArea(densityMapShape, sprayTypeIndex, targetLevel, ignoreLock)
	targetLevel = math.min(targetLevel, self.maxValue)
	local coverMap = self.coverMap
	local soilMap = self.soilMap
	if coverMap ~= nil and (coverMap.bitVectorMap ~= nil and (soilMap ~= nil and soilMap.bitVectorMap ~= nil)) then
		local functionData = self:getSprayFunctionData()
		local nModifier = functionData.nModifier
		local modifierLock = functionData.modifierLock
		local nFilter = functionData.nFilter
		local lockFilter = functionData.lockFilter
		if ignoreLock then
			lockFilter = nil
		end
		local sprayTypeDesc = g_sprayTypeManager:getSprayTypeByIndex(sprayTypeIndex)
		if sprayTypeDesc ~= nil then
			densityMapShape:applyToModifier(nModifier)
			densityMapShape:applyToModifier(modifierLock)
			nFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, 0, targetLevel - 1)
			local _, numChangedPixels, _ = nModifier:executeSetWithStats(targetLevel, nFilter, lockFilter)
			modifierLock:executeSet(1, lockFilter)
			if 0 < numChangedPixels then
				self:setMinimapRequiresUpdate(true)
			end
			return numChangedPixels
		end
	end
	return 0
end
function NitrogenMap:setNitrogenLevelAtArea(densityMapShape, sprayTypeIndex, targetLevel, ignoreLock, measured)
	targetLevel = math.clamp(targetLevel, 0, self.maxValue)
	local coverMap = self.coverMap
	local soilMap = self.soilMap
	if coverMap ~= nil and (coverMap.bitVectorMap ~= nil and (soilMap ~= nil and soilMap.bitVectorMap ~= nil)) then
		local functionData = self:getSprayFunctionData()
		local nModifier = functionData.nModifier
		local modifierLock = functionData.modifierLock
		local lockFilter = functionData.lockFilter
		if ignoreLock then
			lockFilter = nil
		end
		local cropSensorFunctionData = self:getCropSensorFunctionData()
		local modifierMeasured = cropSensorFunctionData.modifierMeasured
		local sprayTypeDesc = g_sprayTypeManager:getSprayTypeByIndex(sprayTypeIndex)
		if sprayTypeDesc ~= nil then
			densityMapShape:applyToModifier(nModifier)
			densityMapShape:applyToModifier(modifierLock)
			densityMapShape:applyToModifier(modifierMeasured)
			local _, numChangedPixels, _ = nModifier:executeSetWithStats(targetLevel, lockFilter)
			modifierLock:executeSet(1, lockFilter)
			modifierMeasured:executeSet(Utils.getNoNil(measured, false) and 1 or 0, lockFilter)
			if 0 < numChangedPixels then
				self:setMinimapRequiresUpdate(true)
			end
			return numChangedPixels
		end
	end
	return 0
end
function NitrogenMap:updateDestroyCommonArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	local soilMap = self.soilMap
	if soilMap ~= nil and soilMap.bitVectorMap ~= nil then
		local modifier = self.densityMapModifiersDestroyFruit.modifier
		local nFilter = self.densityMapModifiersDestroyFruit.nFilter
		local fruitFilter = self.densityMapModifiersDestroyFruit.fruitFilter
		local modifierLock = self.densityMapModifiersDestroyFruit.modifierLock
		local lockFilter = self.densityMapModifiersDestroyFruit.lockFilter
		local fruitIndices = self.densityMapModifiersDestroyFruit.fruitIndices
		if modifier == nil or nFilter == nil or fruitFilter == nil or modifierLock == nil or lockFilter == nil or fruitIndices == nil then
			self.densityMapModifiersDestroyFruit.modifier = DensityMapModifier.new(self.bitVectorMap, self.firstChannel, self.numChannels, g_terrainNode)
			modifier = self.densityMapModifiersDestroyFruit.modifier
			modifier:setPolygonRoundingMode(DensityRoundingMode.INCLUSIVE)
			self.densityMapModifiersDestroyFruit.nFilter = DensityMapFilter.new(self.bitVectorMap, self.firstChannel, self.numChannels)
			nFilter = self.densityMapModifiersDestroyFruit.nFilter
			nFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, 0, self.maxValue - 1)
			self.densityMapModifiersDestroyFruit.fruitFilter = DensityMapFilter.new(modifier)
			fruitFilter = self.densityMapModifiersDestroyFruit.fruitFilter
			self.densityMapModifiersDestroyFruit.modifierLock = DensityMapModifier.new(self.bitVectorMapNFruitDestroyMask, 0, 2, g_terrainNode)
			modifierLock = self.densityMapModifiersDestroyFruit.modifierLock
			modifierLock:setPolygonRoundingMode(DensityRoundingMode.INCLUSIVE)
			self.densityMapModifiersDestroyFruit.lockFilter = DensityMapFilter.new(self.bitVectorMapNFruitDestroyMask, 0, 2)
			lockFilter = self.densityMapModifiersDestroyFruit.lockFilter
			lockFilter:setValueCompareParams(DensityValueCompareType.EQUAL, 1)
			self.densityMapModifiersDestroyFruit.fruitIndices = {}
			fruitIndices = self.densityMapModifiersDestroyFruit.fruitIndices
			for i = 1, 15 do
				fruitIndices[i] = { index = 0, terrainDataPlaneId = 0, active = false }
			end
		end
		startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ = worldCoordsToLocalCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, self.sizeX, g_currentMission.terrainSize)
		modifierLock:setParallelogramDensityMapCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
		fruitIndices[1].active = false
		fruitIndices[2].active = false
		fruitIndices[3].active = false
		fruitIndices[4].active = false
		fruitIndices[5].active = false
		fruitIndices[6].active = false
		fruitIndices[7].active = false
		fruitIndices[8].active = false
		fruitIndices[9].active = false
		fruitIndices[10].active = false
		fruitIndices[11].active = false
		fruitIndices[12].active = false
		fruitIndices[13].active = false
		fruitIndices[14].active = false
		fruitIndices[15].active = false
		modifierLock:executeSet(0)
		for index, desc in pairs(g_fruitTypeManager:getFruitTypes()) do
			if desc.weed == nil then
				if desc.terrainDataPlaneId == nil then
					continue
				end
				fruitFilter:resetDensityMapAndChannels(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)
				fruitFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, 2, desc.numGrowthStates)
				local _, numPixels = modifierLock:executeSetWithStats(1, fruitFilter)
				if 0 < numPixels then
					for i = 1, 15 do
						if fruitIndices[i].active then
							continue
						end
						fruitIndices[i].index = index
						fruitIndices[i].terrainDataPlaneId = desc.terrainDataPlaneId
						fruitIndices[i].active = true
						break
					end
				end
			end
		end
	end
	return 0
end
function NitrogenMap:postUpdateDestroyCommonArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	local soilMap = self.soilMap
	if soilMap ~= nil and soilMap.bitVectorMap ~= nil then
		local modifier = self.densityMapModifiersDestroyFruit.modifier
		local nFilter = self.densityMapModifiersDestroyFruit.nFilter
		local fruitFilter = self.densityMapModifiersDestroyFruit.fruitFilter
		local modifierLock = self.densityMapModifiersDestroyFruit.modifierLock
		local lockFilter = self.densityMapModifiersDestroyFruit.lockFilter
		local fruitIndices = self.densityMapModifiersDestroyFruit.fruitIndices
		startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ = worldCoordsToLocalCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, self.sizeX, g_currentMission.terrainSize)
		modifier:setParallelogramDensityMapCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
		for i = 1, 15 do
			if fruitIndices[i].active then
				local desc = g_fruitTypeManager:getFruitTypeByIndex(fruitIndices[i].index)
				fruitFilter:resetDensityMapAndChannels(fruitIndices[i].terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)
				fruitFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, 2, desc.numGrowthStates)
				modifierLock:executeSet(2, fruitFilter)
			end
		end
		nFilter:setValueCompareParams(DensityValueCompareType.EQUAL, self.maxValue - self.catchCropsStateChange)
		modifier:executeSet(self.maxValue, lockFilter, nFilter)
		nFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, 0, self.maxValue - self.catchCropsStateChange)
		modifier:executeAdd(self.catchCropsStateChange, lockFilter, nFilter)
	end
	return 0
end
function NitrogenMap:preUpdateStrawChopperArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, strawGroundType)
	local modifier = self.densityMapModifiersStrawChopper.modifier
	local nFilter = self.densityMapModifiersStrawChopper.nFilter
	local maskModifier = self.densityMapModifiersStrawChopper.maskModifier
	local maskFilter = self.densityMapModifiersStrawChopper.maskFilter
	local sprayTypeFilter = self.densityMapModifiersStrawChopper.sprayTypeFilter
	if modifier == nil or nFilter == nil or maskModifier == nil or maskFilter == nil or sprayTypeFilter == nil then
		self.densityMapModifiersStrawChopper.modifier = DensityMapModifier.new(self.bitVectorMap, self.firstChannel, self.numChannels, g_terrainNode)
		self.densityMapModifiersStrawChopper.nFilter = DensityMapFilter.new(self.bitVectorMap, self.firstChannel, self.numChannels)
		nFilter = self.densityMapModifiersStrawChopper.nFilter
		self.densityMapModifiersStrawChopper.maskModifier = DensityMapModifier.new(self.bitVectorMapChoppedStrawMask, 0, 1, g_terrainNode)
		maskModifier = self.densityMapModifiersStrawChopper.maskModifier
		self.densityMapModifiersStrawChopper.maskFilter = DensityMapFilter.new(self.bitVectorMapChoppedStrawMask, 0, 1)
		maskFilter = self.densityMapModifiersStrawChopper.maskFilter
		maskFilter:setValueCompareParams(DensityValueCompareType.EQUAL, 1)
		local fieldGroundSystem = g_currentMission.fieldGroundSystem
		local sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_TYPE)
		self.densityMapModifiersStrawChopper.sprayTypeFilter = DensityMapFilter.new(sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels)
		sprayTypeFilter = self.densityMapModifiersStrawChopper.sprayTypeFilter
		sprayTypeFilter:setValueCompareParams(DensityValueCompareType.NOTEQUAL, strawGroundType)
	end
	maskModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	maskModifier:executeSet(1)
	sprayTypeFilter:setValueCompareParams(DensityValueCompareType.EQUAL, strawGroundType)
	maskModifier:executeSet(0, sprayTypeFilter)
	nFilter:setValueCompareParams(DensityValueCompareType.GREATER, self.maxValue - self.choppedStrawStateChange)
	maskModifier:executeSet(0, nFilter)
end
function NitrogenMap:postUpdateStrawChopperArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, strawGroundType)
	local modifier = self.densityMapModifiersStrawChopper.modifier
	local maskFilter = self.densityMapModifiersStrawChopper.maskFilter
	local sprayTypeFilter = self.densityMapModifiersStrawChopper.sprayTypeFilter
	sprayTypeFilter:setValueCompareParams(DensityValueCompareType.EQUAL, strawGroundType)
	modifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	modifier:executeAdd(self.choppedStrawStateChange, maskFilter, sprayTypeFilter)
end
function NitrogenMap:updateCropSensorArea(densityMapShape)
	local functionData = self:getCropSensorFunctionData()
	local multiModifier = functionData.multiModifier
	if multiModifier == nil then
		multiModifier = DensityMapMultiModifier.new()
		functionData.multiModifier = multiModifier
		self:addCropSensorUpdateToMultiModifier(multiModifier, nil, true)
	end
	densityMapShape:applyToModifier(multiModifier)
	multiModifier:resetStats()
	local changeArea, _ = multiModifier:execute()
	if 0 < changeArea then
		self:setMinimapRequiresUpdate(true)
	end
end
function NitrogenMap:getCropSensorFunctionData()
	local functionData = self.densityMapModifiersCropSensorMulti
	if functionData == nil then
		functionData = {}
		functionData.modifierMeasured = DensityMapModifier.new(self.bitVectorMapNOffset, 3, 1, g_terrainNode)
		functionData.measuredFilter = DensityMapFilter.new(self.bitVectorMapNOffset, 3, 1)
		functionData.measuredFilter:setValueCompareParams(DensityValueCompareType.EQUAL, 0)
		functionData.nModifier = DensityMapModifier.new(self.bitVectorMap, self.firstChannel, self.numChannels, g_terrainNode)
		functionData.nFilter = DensityMapFilter.new(self.bitVectorMap, self.firstChannel, self.numChannels)
		functionData.nFilter:setValueCompareParams(DensityValueCompareType.GREATER, self.maxValue)
		functionData.offsetFilter = DensityMapFilter.new(self.bitVectorMapNOffset, 0, 3)
		functionData.tempFruitModifier = DensityMapModifier.new(self.bitVectorMapNFruitFilterMask, 0, 1, g_terrainNode)
		functionData.tempFruitModifier:setPolygonRoundingMode(DensityRoundingMode.INCLUSIVE)
		functionData.tempFruitFilter = DensityMapFilter.new(self.bitVectorMapNFruitFilterMask, 0, 1)
		functionData.tempFruitFilter:setValueCompareParams(DensityValueCompareType.EQUAL, 1)
		functionData.fruitFilter = DensityMapFilter.new(self.bitVectorMapNFruitFilterMask, 0, 1)
		functionData.fruitFilter:setValueCompareParams(DensityValueCompareType.EQUAL, 1)
		functionData.multiModifiers = {}
		self.densityMapModifiersCropSensorMulti = functionData
	end
	return functionData
end
function NitrogenMap:addCropSensorUpdateToMultiModifier(multiModifier, changeFilter, setMeasured)
	local functionData = self:getCropSensorFunctionData()
	multiModifier:addExecuteSet(0, functionData.tempFruitModifier)
	if changeFilter == nil then
		for fruitTypeIndex = 1, #self.cropSensorFruitTypes do
			local fruitType = self.cropSensorFruitTypes[fruitTypeIndex]
			if fruitType.terrainDataPlaneId == nil then
				continue
			end
			functionData.fruitFilter:resetDensityMapAndChannels(fruitType.terrainDataPlaneId, fruitType.startStateChannel, fruitType.numStateChannels)
			functionData.fruitFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, 1, fruitType.minHarvestingGrowthState)
			multiModifier:addExecuteSet(1, functionData.tempFruitModifier, functionData.fruitFilter)
		end
	else
		multiModifier:addExecuteSet(1, functionData.tempFruitModifier, changeFilter)
	end
	functionData.measuredFilter:setValueCompareParams(DensityValueCompareType.EQUAL, 1)
	multiModifier:addExecuteSet(0, functionData.tempFruitModifier, functionData.measuredFilter)
	for offsetIndex = 1, #self.nOffsetIndexToOffset do
		local nOffset = self.nOffsetIndexToOffset[offsetIndex]
		functionData.offsetFilter:setValueCompareParams(DensityValueCompareType.EQUAL, offsetIndex - 1)
		functionData.nFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, math.max(1 - nOffset, 1), self.maxValue - nOffset)
		multiModifier:addExecuteAddWithStats("", nOffset, functionData.nModifier, functionData.nFilter, functionData.offsetFilter, functionData.tempFruitFilter)
	end
	if setMeasured then
		functionData.measuredFilter:setValueCompareParams(DensityValueCompareType.EQUAL, 0)
		multiModifier:addExecuteSet(1, functionData.modifierMeasured, functionData.measuredFilter, functionData.tempFruitFilter)
	end
end
function NitrogenMap:getLevelAtWorldPos(x, z)
	x = MathUtil.round((x + g_currentMission.terrainSize * 0.5) / g_currentMission.terrainSize * self.sizeX + 0.5) - 1
	z = MathUtil.round((z + g_currentMission.terrainSize * 0.5) / g_currentMission.terrainSize * self.sizeY + 0.5) - 1
	if self.coverMap:getIsUncoveredAtPos(x, z) then
		return getBitVectorMapPoint(self.bitVectorMap, x, z, self.firstChannel, self.numChannels)
	else
		return 0
	end
end
function NitrogenMap:getIsLockedAtWorldPos(wx, wz, sprayTypeIndex)
	local coverMap = self.coverMap
	local soilMap = self.soilMap
	if coverMap ~= nil and (coverMap.bitVectorMap ~= nil and (soilMap ~= nil and soilMap.bitVectorMap ~= nil)) then
		local modifierLock = self.densityMapModifiersLockedState.modifierLock
		local sprayTypeFilter = self.densityMapModifiersLockedState.sprayTypeFilter
		local coverMaskFilter = self.densityMapModifiersLockedState.coverMaskFilter
		if modifierLock == nil or sprayTypeFilter == nil or coverMaskFilter == nil then
			self.densityMapModifiersLockedState.modifierLock = DensityMapModifier.new(self.bitVectorMapNStateChange, 1, 1, g_terrainNode)
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
function NitrogenMap:getNextValidDetectionPoint(wx, wz, dirX, dirZ, maxDistance, sprayTypeIndex)
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
function NitrogenMap:getTargetLevelAtWorldPos(x, z, size, forcedFruitType, fillType, nLevel, defaultNitrogenRequirementIndex)
	local soilMap = self.soilMap
	if soilMap ~= nil and soilMap.bitVectorMap ~= nil then
		size = size or 1
		local modifierFruit = self.densityMapModifiersFruitCheck.modifierFruit
		if modifierFruit == nil then
			local fieldGroundSystem = g_currentMission.fieldGroundSystem
			local sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_TYPE)
			self.densityMapModifiersFruitCheck.modifierFruit = DensityMapModifier.new(sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels)
			modifierFruit = self.densityMapModifiersFruitCheck.modifierFruit
		end
		local lx = (x + g_currentMission.terrainSize * 0.5) / g_currentMission.terrainSize * soilMap.sizeX
		local lz = (z + g_currentMission.terrainSize * 0.5) / g_currentMission.terrainSize * soilMap.sizeY
		if self.coverMap:getIsUncoveredAtPos(lx, lz) then
			local soilTypeIndex = getBitVectorMapPoint(soilMap.bitVectorMap, lx, lz, soilMap.typeFirstChannel, soilMap.typeNumChannels) + 1
			if fillType ~= nil and fillType ~= FillType.UNKNOWN then
				for i = 1, #self.applicationRates do
					local applicationRate = self.applicationRates[i]
					if applicationRate.fillTypeIndex == fillType and not applicationRate.autoAdjustToFruit then
						for j = 1, #applicationRate.ratesBySoilType do
							local rateBySoilType = applicationRate.ratesBySoilType[j]
							if rateBySoilType.soilTypeIndex == soilTypeIndex then
								return (nLevel or 0) + rateBySoilType.rate, soilTypeIndex, FruitType.UNKNOWN
							end
						end
					end
				end
			end
			local halfSize = size * 0.5
			local startWorldX = x + halfSize
			local startWorldZ = z + halfSize
			local widthWorldX = x - halfSize
			local widthWorldZ = z + halfSize
			local heightWorldX = x + halfSize
			local heightWorldZ = z - halfSize
			modifierFruit:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
			local foundFruitTypeIndex = forcedFruitType
			if foundFruitTypeIndex == nil then
				for index, desc in pairs(g_fruitTypeManager:getFruitTypes()) do
					if desc.weed == nil then
						if desc.terrainDataPlaneId == nil then
							continue
						end
						modifierFruit:resetDensityMapAndChannels(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)
						local acc, numPixels, _ = modifierFruit:executeGet()
						if 0 < numPixels then
							local state = math.floor(acc / numPixels)
							local allowCutState = false
							for i = 1, #self.fruitRequirements do
								if self.fruitRequirements[i].fruitType.index == index then
									allowCutState = self.fruitRequirements[i].alwaysAllowFertilization
								end
							end
							if 0 <= state then
								if state ~= desc.cutState or allowCutState then
									foundFruitTypeIndex = index
								else
								end
								local fruitRequirement = nil
								if foundFruitTypeIndex ~= nil then
									for i = 1, #self.fruitRequirements do
										if self.fruitRequirements[i].fruitType.index == foundFruitTypeIndex then
											fruitRequirement = self.fruitRequirements[i]
											break
										end
									end
								else
									fruitRequirement = self.fruitRequirements[defaultNitrogenRequirementIndex or 1] or self.fruitRequirements[1]
								end
								if fruitRequirement ~= nil then
									for j = 1, #fruitRequirement.bySoilType do
										local soilSettings = fruitRequirement.bySoilType[j]
										if soilSettings.soilTypeIndex == soilTypeIndex then
											return soilSettings.targetLevel, soilTypeIndex, foundFruitTypeIndex
										end
									end
								end
								return 0, soilTypeIndex, FruitType.UNKNOWN
							end
						end
					end
				end
			end
		end
	end
	return 0, 0, FruitType.UNKNOWN
end
function NitrogenMap:getNitrogenApplicationRate(currentLevel, fruitTypeIndex, soilTypeIndex, sprayTypeIndex)
	local sprayTypeDesc = g_sprayTypeManager:getSprayTypeByIndex(sprayTypeIndex)
	if sprayTypeDesc == nil then
		return 0, false
	end
	for i = 1, #self.applicationRates do
		local applicationRate = self.applicationRates[i]
		if applicationRate.fillTypeIndex == sprayTypeDesc.fillType.index and not applicationRate.autoAdjustToFruit then
			for j = 1, #applicationRate.ratesBySoilType do
				local rateBySoilType = applicationRate.ratesBySoilType[j]
				if rateBySoilType.soilTypeIndex == soilTypeIndex then
					return rateBySoilType.rate, false
				end
			end
		end
	end
	local targetLevel = self:getNitrogenTargetLevel(fruitTypeIndex, soilTypeIndex)
	if targetLevel ~= nil then
		return targetLevel - currentLevel, true
	else
		return 0, false
	end
end
function NitrogenMap:getNitrogenTargetLevel(fruitTypeIndex, soilTypeIndex)
	local fruitRequirement = nil
	for i = 1, #self.fruitRequirements do
		if self.fruitRequirements[i].fruitType.index == fruitTypeIndex then
			fruitRequirement = self.fruitRequirements[i]
			break
		end
	end
	if fruitRequirement ~= nil then
		for j = 1, #fruitRequirement.bySoilType do
			local soilSettings = fruitRequirement.bySoilType[j]
			if soilSettings.soilTypeIndex == soilTypeIndex then
				return soilSettings.targetLevel, nil
			end
		end
	end
	return nil, nil
end
function NitrogenMap:getNOffsetDataAtWorldPos(x, z)
	x = (x + g_currentMission.terrainSize * 0.5) / g_currentMission.terrainSize * self.sizeX
	z = (z + g_currentMission.terrainSize * 0.5) / g_currentMission.terrainSize * self.sizeY
	if self.coverMap:getIsUncoveredAtPos(x, z) then
		local isLocked = getBitVectorMapPoint(self.bitVectorMapNOffset, x, z, 3, 1) == 1
		local offsetValue = getBitVectorMapPoint(self.bitVectorMapNOffset, x, z, 0, 3)
		local nOffsetValue = self.nOffsetIndexToOffset[offsetValue + 1] * self.amountPerState
		return isLocked, nOffsetValue
	else
		return false, -1
	end
end
function NitrogenMap:getFertilizerUsage(workingWidth, lastSpeed, statesChanged, fillTypeIndex, dt, sprayAmountAutoMode, nApplyAutoModeFruitType, actualNitrogen, nitrogenUsageLevelOffset)
	local requiredLitersPerHa, _, nitrogenProportion = self:getFertilizerUsageByStateChange(statesChanged, fillTypeIndex, nitrogenUsageLevelOffset or 0)
	local litersPerUpdate = requiredLitersPerHa * (lastSpeed / 3600) / (10000 / workingWidth) * dt
	local regularUsage = 0
	if 0 < requiredLitersPerHa and nApplyAutoModeFruitType ~= nil then
		if nApplyAutoModeFruitType ~= FruitType.UNKNOWN then
			for i = 1, #self.fruitRequirements do
				local fruitRequirement = self.fruitRequirements[i]
				if fruitRequirement.fruitType.index == nApplyAutoModeFruitType then
					local _, internalActualNitrogen = self:getNearestNitrogenValueFromValue(actualNitrogen)
					local requiredLitersPerHaReg, _, _ = self:getFertilizerUsageByStateChange(math.max(fruitRequirement.averageTargetLevel - internalActualNitrogen, 0), fillTypeIndex)
					regularUsage = requiredLitersPerHaReg * (lastSpeed / 3600) / (10000 / workingWidth) * dt
				end
			end
		else
			for i = 1, #self.applicationRates do
				local applicationRate = self.applicationRates[i]
				if applicationRate.fillTypeIndex == fillTypeIndex then
					local requiredLitersPerHaReg, _, _ = self:getFertilizerUsageByNitrogenAmount(applicationRate.regularRate, fillTypeIndex)
					regularUsage = requiredLitersPerHaReg * (lastSpeed / 3600) / (10000 / workingWidth) * dt
				end
			end
		end
	end
	return litersPerUpdate, requiredLitersPerHa, regularUsage, nitrogenProportion
end
function NitrogenMap:getFertilizerUsageByStateChange(statesChanged, fillTypeIndex, nitrogenUsageLevelOffset)
	local requiredNAmount = statesChanged * self.amountPerState
	local nAmountOffset = (nitrogenUsageLevelOffset or 0) * self.amountPerState
	return self:getFertilizerUsageByNitrogenAmount(requiredNAmount, fillTypeIndex, nAmountOffset)
end
function NitrogenMap:getFertilizerUsageByNitrogenAmount(nitrogenAmount, fillTypeIndex, nAmountOffset)
	local requiredLitersPerHa = 0
	local requiredMassPerHa = 0
	local nitrogenProportion = 0
	for i = 1, #self.fertilizerUsage.nAmounts do
		local nAmount = self.fertilizerUsage.nAmounts[i]
		if nAmount.fillTypeIndex == fillTypeIndex then
			local fillTypeDesc = g_fillTypeManager:getFillTypeByIndex(fillTypeIndex)
			local massPerLiter = fillTypeDesc.massPerLiter / FillTypeManager.MASS_SCALE
			if fillTypeIndex ~= FillType.LIQUIDMANURE then
				if fillTypeDesc == nil then
					continue
				end
				requiredLitersPerHa = nitrogenAmount / (massPerLiter * 1000) / nAmount.amount
				requiredMassPerHa = requiredLitersPerHa * massPerLiter
				nitrogenProportion = nAmount.amount
			else
				local nOffsetPct = 1
				if 0 < nitrogenAmount and nAmountOffset ~= nil then
					local realNAmount = nitrogenAmount + nAmountOffset
					nOffsetPct = realNAmount / nitrogenAmount
				end
				requiredLitersPerHa = nitrogenAmount / (nAmount.amount * nOffsetPct)
				requiredMassPerHa = requiredLitersPerHa * massPerLiter
				nitrogenProportion = nAmount.amount * nOffsetPct
			end
		end
	end
	return requiredLitersPerHa, requiredMassPerHa, nitrogenProportion
end
function NitrogenMap:getNextFruitRequirementIndex(index)
	index = index + 1
	if #self.fruitRequirements < index then
		index = 1
	end
	if self.fruitRequirements[index] ~= nil and not self.fruitRequirements[index].availableAsDefaultRate then
		return self:getNextFruitRequirementIndex(index)
	end
	return index
end
function NitrogenMap:getFruitTypeIndexByFruitRequirementIndex(index)
	if self.fruitRequirements[index] ~= nil then
		return self.fruitRequirements[index].fruitType.index
	else
		return nil
	end
end
function NitrogenMap:getFruitTypeRequirementRequiresDefaultMode(index)
	for i = 1, #self.fruitRequirements do
		local fruitRequirement = self.fruitRequirements[i]
		if fruitRequirement.fruitType.index == index and fruitRequirement.requiresDefaultMode then
			return true
		end
	end
	return false
end
function NitrogenMap:getNitrogenAmountFromFillType(fillTypeIndex)
	for i = 1, #self.fertilizerUsage.nAmounts do
		local nAmount = self.fertilizerUsage.nAmounts[i]
		if nAmount.fillTypeIndex == fillTypeIndex then
			return nAmount.amount
		end
	end
	return 0
end
function NitrogenMap:getNitrogenFromChangedStates(statesChanged)
	return statesChanged * self.amountPerState
end
function NitrogenMap:getFillTypeIsFertilizer(fillType)
	return self.fertilizerFillTypes[fillType] ~= nil
end
function NitrogenMap:getDefaultNitrogenStateChange()
	return self.stateChangeDefault
end
function NitrogenMap:getMinMaxValue()
	if self.nitrogenValues ~= nil and 0 < #self.nitrogenValues then
		return self.nitrogenValues[1].realValue, self.nitrogenValues[#self.nitrogenValues].realValue, #self.nitrogenValues
	end
	return 0, 1, 0
end
function NitrogenMap:getNitrogenValueFromInternalValue(internal)
	for i = 1, #self.nitrogenValues do
		local nitrogenValue = self.nitrogenValues[i]
		if nitrogenValue.value == math.floor(internal) then
			return nitrogenValue.realValue
		end
	end
	return 0
end
function NitrogenMap:getNearestNitrogenValueFromValue(value)
	local minDifference = 1000
	local minValue = 0
	local minInternal = 0
	for i = 1, #self.nitrogenValues do
		local nValue = self.nitrogenValues[i].realValue
		local difference = math.abs(value - nValue)
		if difference < minDifference then
			minDifference = difference
			minValue = nValue
			minInternal = self.nitrogenValues[i].value
		end
	end
	return minValue, minInternal
end
function NitrogenMap:updateLastNitrogenValues()
	local actual = self.lastActualValue
	local target = self.lastTargetValue
	local yieldPotential = self.lastYieldPotential
	local ignoreOverfertilization = self.lastIgnoreOverfertilization
	local regularNLevel = self.lastRegularNValue
	self.lastActualValue = -1
	self.lastTargetValue = -1
	self.lastYieldPotential = -1
	self.lastIgnoreOverfertilization = nil
	self.lastRegularNValue = -1
	return actual, target, yieldPotential, regularNLevel, ignoreOverfertilization
end
function NitrogenMap:getYieldFactorByLevelDifference(difference, ignoreOverfertilization)
	if 0 < difference and ignoreOverfertilization == true then
		difference = 0
	end
	return self.yieldCurve:get(difference)
end
function NitrogenMap:buildOverlay(overlay, filter, isColorBlindMode, isMinimap)
	resetDensityMapVisualizationOverlay(overlay)
	setOverlayColor(overlay, 1, 1, 1, 1)
	if not isMinimap or not self.minimapMissionState then
		local coverMap = self.coverMap
		if coverMap ~= nil then
			local coverMask = bit32.lshift(2 ^ (coverMap.numChannels - 1) - 1, 1)
			for i = 1, #self.nitrogenValues do
				local nitrogenValue = self.nitrogenValues[i]
				if filter[nitrogenValue.filterIndex] then
					local color = nitrogenValue.color
					if isColorBlindMode then
						color = nitrogenValue.colorBlind
					end
					if color == nil then
						continue
					end
					setDensityMapVisualizationOverlayStateColor(overlay, self.bitVectorMap, coverMap.bitVectorMap, coverMask, self.firstChannel, self.numChannels, nitrogenValue.value, color[1], color[2], color[3])
				end
			end
		end
	else
		local inGameMenuMapFrame = self.pfModule.inGameMenuMapFrameExtension.inGameMenuMapFrame
		if inGameMenuMapFrame ~= nil then
			local sprayMapId, sprayLevelFirstChannel, sprayLevelNumChannels = g_currentMission.fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_LEVEL)
			local mapOverlayGenerator = g_currentMission.mapOverlayGenerator
			if mapOverlayGenerator ~= nil then
				local colors = self.fertilizerColors[isColorBlindMode]
				local maxSprayLevel = bit32.lshift(1, sprayLevelNumChannels) - 1
				for level = 1, maxSprayLevel do
					local color = colors[math.min(level, #colors)]
					setDensityMapVisualizationOverlayStateColor(overlay, sprayMapId, 0, 0, sprayLevelFirstChannel, sprayLevelNumChannels, level, color[1], color[2], color[3])
				end
			end
		end
	end
	if NitrogenMap.DEBUG_N_OFFSET_MAP then
		resetDensityMapVisualizationOverlay(overlay)
		setOverlayColor(overlay, 1, 1, 1, 1)
		setDensityMapVisualizationOverlayStateColor(overlay, self.bitVectorMapNOffset, 0, 0, 0, 3, 0, 1, 0, 0)
		setDensityMapVisualizationOverlayStateColor(overlay, self.bitVectorMapNOffset, 0, 0, 0, 3, 1, 0.8, 0.2, 0)
		setDensityMapVisualizationOverlayStateColor(overlay, self.bitVectorMapNOffset, 0, 0, 0, 3, 2, 0.6, 0.4, 0)
		setDensityMapVisualizationOverlayStateColor(overlay, self.bitVectorMapNOffset, 0, 0, 0, 3, 3, 0.4, 0.6, 0)
		setDensityMapVisualizationOverlayStateColor(overlay, self.bitVectorMapNOffset, 0, 0, 0, 3, 4, 0.2, 0.8, 0)
		setDensityMapVisualizationOverlayStateColor(overlay, self.bitVectorMapNOffset, 0, 0, 0, 3, 5, 0, 1, 0)
		setDensityMapVisualizationOverlayStateColor(overlay, self.bitVectorMapNOffset, 0, 0, 0, 3, 6, 0, 0.5, 0.5)
		setDensityMapVisualizationOverlayStateColor(overlay, self.bitVectorMapNOffset, 0, 0, 0, 3, 7, 0, 0, 1)
	end
end
function NitrogenMap:getDisplayValues()
	if self.valuesToDisplay == nil then
		self.valuesToDisplay = {}
		for i = 1, #self.nitrogenValues do
			local nitrogenValue = self.nitrogenValues[i]
			if nitrogenValue.showOnHud then
				local nValueToDisplay = {}
				nValueToDisplay.colors = {}
				nValueToDisplay.colors[true] = { nitrogenValue.colorBlind }
				nValueToDisplay.colors[false] = { nitrogenValue.color }
				nValueToDisplay.description = string.format("%d kg/ha", nitrogenValue.realValue)
				table.insert(self.valuesToDisplay, nValueToDisplay)
			end
		end
		local nValueToDisplay = {}
		nValueToDisplay.colors = {}
		nValueToDisplay.colors[true] = { { 0, 0, 0 } }
		nValueToDisplay.colors[false] = { { 0, 0, 0 } }
		nValueToDisplay.description = self.outdatedLabel
		table.insert(self.valuesToDisplay, nValueToDisplay)
	end
	return self.valuesToDisplay
end
function NitrogenMap:getValueFilter()
	if self.valueFilter == nil or self.valueFilterEnabled == nil then
		self.valueFilter = {}
		self.valueFilterEnabled = {}
		for i = 1, self.numVisualValues + 1 do
			table.insert(self.valueFilter, true)
			table.insert(self.valueFilterEnabled, i <= self.numVisualValues)
		end
	end
	return self.valueFilter, self.valueFilterEnabled
end
function NitrogenMap:getMinimapZoomFactor()
	return 3
end
function NitrogenMap:collectFieldInfos(fieldInfoDisplayExtension)
	local name = g_i18n:getText("fieldInfo_nValue", NitrogenMap.MOD_NAME)
	fieldInfoDisplayExtension:addFieldInfo(name, self, self.updateFieldInfoDisplay, 3, self.getFieldInfoYieldChange)
end
function NitrogenMap:getAllowCoverage()
	return true
end
function NitrogenMap:getHelpLinePage()
	return 5
end
function NitrogenMap:updateFieldInfoDisplay(fieldInfo, x, z, isColorBlindMode)
	fieldInfo.yieldPotential = nil
	fieldInfo.yieldPotentialToHa = nil
	fieldInfo.yieldPotentialFactor = nil
	fieldInfo.yieldPotentialFactorBest = nil
	local nLevel = self:getLevelAtWorldPos(x, z)
	local soilTypeIndex = self.soilMap:getTypeIndexAtWorldPos(x, z)
	local fruitTypeIndex, _ = FSDensityMapUtil.getFruitTypeIndexAtWorldPos(x, z)
	if fruitTypeIndex ~= nil then
		local fruitRequirement = self.fruitTypeIndexToFruitRequirement[fruitTypeIndex]
		if fruitRequirement ~= nil then
			local fruitDesc = fruitRequirement.fruitType
			if fruitDesc ~= nil and (fruitDesc.terrainDataPlaneId ~= nil and fruitDesc.terrainDataPlaneId ~= 0) then
				local soilSettings = nil
				for _, _soilSettings in ipairs(fruitRequirement.bySoilType) do
					if _soilSettings.soilTypeIndex == soilTypeIndex then
						soilSettings = _soilSettings
						break
					end
				end
				if soilSettings ~= nil then
					local actualLevelReal = self:getNitrogenValueFromInternalValue(nLevel)
					local targetLevelReal = self:getNitrogenValueFromInternalValue(soilSettings.targetLevel)
					local color = nil
					local additionalText = nil
					local showWarning = nil
					local levelDifference = soilSettings.targetLevel - nLevel
					if fruitRequirement.ignoreOverfertilization then
						levelDifference = math.max(levelDifference, 0)
					end
					if targetLevelReal == 0 then
						levelDifference = 0
					end
					levelDifference = math.abs(levelDifference)
					for li = 1, #self.levelDifferenceColors do
						local levelDifferenceColor = self.levelDifferenceColors[li]
						if levelDifferenceColor.levelDifference <= levelDifference then
							color = isColorBlindMode and levelDifferenceColor.colorBlind or levelDifferenceColor.color
							additionalText = levelDifferenceColor.additionalText
							showWarning = levelDifferenceColor.showWarning
						end
					end
					local seedRateYieldFactorCurrent = 1
					local seedRateYieldFactorBest = 1
					local seedRateMap = self.seedRateMap
					if seedRateMap ~= nil then
						local seedRateRaw = seedRateMap:getSeedRateAtWorldPosition(x, z)
						if seedRateRaw ~= nil then
							seedRateYieldFactorCurrent, seedRateYieldFactorBest = seedRateMap:getSeedRateYieldFactor(seedRateRaw, fruitTypeIndex, soilTypeIndex)
						end
					end
					fieldInfo.yieldPotentialFactor = seedRateYieldFactorCurrent
					fieldInfo.yieldPotentialFactorBest = seedRateYieldFactorBest
					fieldInfo.yieldPotential = soilSettings.yieldPotential
					fieldInfo.nFactor = self:getYieldFactorByLevelDifference(nLevel - soilSettings.targetLevel, fruitRequirement.ignoreOverfertilization)
					local fillType = g_fruitTypeManager:getFillTypeByFruitTypeIndex(fruitDesc.index)
					if fillType ~= nil then
						fieldInfo.yieldPotentialToHa = soilSettings.yieldPotential * fruitDesc.literPerSqm * 10000 * (fillType.massPerLiter / FillTypeManager.MASS_SCALE) * 2
					end
					return string.format("%d / %d kg/ha", actualLevelReal, targetLevelReal), color, additionalText, showWarning
				end
			end
		end
	end
	if nLevel == 0 then
		return nil
	else
		return string.format("%d kg/ha", self:getNitrogenValueFromInternalValue(nLevel))
	end
end
function NitrogenMap:getFieldInfoYieldChange(fieldInfo)
	return fieldInfo.nFactor or 0, 0.5, fieldInfo.yieldPotential, fieldInfo.yieldPotentialToHa, fieldInfo.yieldPotentialFactor, fieldInfo.yieldPotentialFactorBest
end
function NitrogenMap:drawYieldDebug(nActualValue, nTargetValue)
	if self.debugGraph == nil then
		self.debugGraph = Graph.new(#self.yieldCurve.keyframes, 0.2, 0.05, 0.2, 0.15, 0, 100, false, "%", Graph.STYLE_LINES)
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
		local x = self.debugGraph.left + MathUtil.inverseLerp(minTime, maxTime, nActualValue - nTargetValue) * self.debugGraph.width
		setOverlayColor(self.debugGraph.overlayHLine, 1, 0, 0, 1)
		renderOverlay(self.debugGraph.overlayHLine, x, self.debugGraph.bottom, g_pixelSizeX, self.debugGraph.height)
		setOverlayColor(self.debugGraph.overlayHLine, 1, 1, 1, 1)
	end
end
function NitrogenMap:debugSetNitrogenLevel(fieldId, nitrogenLevel, measured)
	fieldId = tonumber(fieldId)
	nitrogenLevel = tonumber(nitrogenLevel)
	measured = measured == "true"
	if fieldId == nil or nitrogenLevel == nil then
		Logging.error("NitrogenMap: Invalid parameters. Usage: pfNitrogenSetLevel <fieldId> <nitrogenLevel> [measured:true|false]")
		return
	end
	local field = g_fieldManager:getFieldById(tonumber(fieldId))
	if field ~= nil and field.getDensityMapPolygon ~= nil then
		local area = field:getDensityMapPolygon()
		local _, targetLevel = self:getNearestNitrogenValueFromValue(nitrogenLevel)
		self:setNitrogenLevelAtArea(area, SprayType.FERTILIZER, targetLevel, true, measured)
		Logging.info("NitrogenMap: Set nitrogen level of field %d to %d kg/ha", fieldId, nitrogenLevel)
	end
end
function NitrogenMap:overwriteGameFunctions(pfModule)
	NitrogenMap:superClass().overwriteGameFunctions(self, pfModule)
	pfModule:overwriteGameFunction(FertilizingSowingMachine, "processSowingMachineArea", function(superFunc, vehicle, superFunc2, workArea, dt)
		if not vehicle.isServer and SowingMachine.CLIENT_DM_UPDATE_RADIUS < vehicle.currentUpdateDistance then
			return superFunc(vehicle, superFunc2, workArea, dt)
		end
		local spec = vehicle.spec_fertilizingSowingMachine
		local specSowingMachine = vehicle.spec_sowingMachine
		local specSpray = vehicle.spec_sprayer
		local sprayerParams = specSpray.workAreaParameters
		local sowingParams = specSowingMachine.workAreaParameters
		if not sowingParams.isActive then
			return superFunc(vehicle, superFunc2, workArea, dt)
		elseif not sowingParams.canFruitBePlanted then
			return superFunc(vehicle, superFunc2, workArea, dt)
		else
			if sprayerParams.sprayFillLevel <= 0 or spec.needsSetIsTurnedOn and not vehicle:getIsTurnedOn() then
				return superFunc(vehicle, superFunc2, workArea, dt)
			end
			if vehicle.preProcessExtUnderRootFertilizerArea ~= nil then
				vehicle:preProcessExtUnderRootFertilizerArea(workArea, dt)
			end
			return superFunc(vehicle, superFunc2, workArea, dt)
		end
	end)
	pfModule:overwriteGameFunction(FertilizingCultivator, "processCultivatorArea", function(superFunc, vehicle, superFunc2, workArea, dt)
		if not vehicle.isServer and Cultivator.CLIENT_DM_UPDATE_RADIUS < vehicle.currentUpdateDistance then
			return superFunc(vehicle, superFunc2, workArea, dt)
		end
		local spec = vehicle.spec_fertilizingCultivator
		local specSpray = vehicle.spec_sprayer
		local sprayerParams = specSpray.workAreaParameters
		if sprayerParams.sprayFillLevel <= 0 or spec.needsSetIsTurnedOn and not vehicle:getIsTurnedOn() then
			return superFunc(vehicle, superFunc2, workArea, dt)
		end
		if vehicle.preProcessExtUnderRootFertilizerArea ~= nil then
			vehicle:preProcessExtUnderRootFertilizerArea(workArea, dt)
		end
		return superFunc(vehicle, superFunc2, workArea, dt)
	end)
	pfModule:overwriteGameFunction(FSDensityMapUtil, "updateFertilizerArea", function(superFunc, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, sprayType, sprayAmount)
		local functionData = FSDensityMapUtil.functionCache.updateFertilizerArea
		if functionData ~= nil then
			local fieldGroundSystem = g_currentMission.fieldGroundSystem
			local sprayLevelMaxValue = fieldGroundSystem:getMaxValue(FieldDensityMap.SPRAY_LEVEL)
			functionData.maskFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, 0, sprayLevelMaxValue)
		end
		return superFunc(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, sprayType, sprayAmount)
	end)
end
