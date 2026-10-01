SeedRateMap = {}
SeedRateMap.MOD_NAME = g_currentModName
local SeedRateMap_mt = Class(SeedRateMap, ValueMap)
function SeedRateMap.new(pfModule, customMt)
	local self = ValueMap.new(pfModule, customMt or SeedRateMap_mt)
	self.filename = "precisionFarming_seedRateMap.grle"
	self.name = "seedRateMap"
	self.id = "SEED_RATE_MAP"
	self.label = "ui_mapOverviewSeedRate"
	self.texts = {}
	self.texts.cropNameHeader = g_i18n:getText("ui_cropName", SeedRateMap.MOD_NAME)
	self.texts.cropType1 = g_i18n:getText("ui_soilType_1", SeedRateMap.MOD_NAME)
	self.texts.cropType2 = g_i18n:getText("ui_soilType_2", SeedRateMap.MOD_NAME)
	self.texts.cropType3 = g_i18n:getText("ui_soilType_3", SeedRateMap.MOD_NAME)
	self.texts.cropType4 = g_i18n:getText("ui_soilType_4", SeedRateMap.MOD_NAME)
	self.densityMapModifiersSeedUpdate = {}
	self.densityMapModifiersHarvestMulti = nil
	self.densityMapModifiersClear = nil
	if g_server ~= nil then
		addConsoleCommand("pfSeedRateSet", "Sets the given seed rate on the given field", "debugSetSeedRateLevel", self, "fieldId; seedRate")
	end
	return self
end
function SeedRateMap:initialize()
	SeedRateMap:superClass().initialize(self)
	self.densityMapModifiersSeedUpdate = {}
	self.densityMapModifiersHarvestMulti = nil
	self.densityMapModifiersClear = nil
end
function SeedRateMap:delete()
	if g_server ~= nil then
		removeConsoleCommand("pfSeedRateSet")
	end
	SeedRateMap:superClass().delete(self)
end
function SeedRateMap:loadFromXML(xmlFile, key, baseDirectory, configFileName, mapFilename)
	key = key .. ".seedRateMap"
	self.numChannels = getXMLInt(xmlFile, key .. ".bitVectorMap#numChannels") or 2
	self.maxValue = 2 ^ self.numChannels - 1
	self.sizeX = getXMLInt(xmlFile, key .. ".bitVectorMap#sizeX") or 1024
	self.sizeY = getXMLInt(xmlFile, key .. ".bitVectorMap#sizeY") or 1024
	self.bitVectorMap = self:loadSavedBitVectorMap("SeedRateMap", self.filename, self.numChannels, self.sizeX)
	if 64 < g_maxModDescVersion then
		self:addBitVectorMapToSync(self.bitVectorMap)
	end
	self:addBitVectorMapToSave(self.bitVectorMap, self.filename)
	self:addBitVectorMapToDelete(self.bitVectorMap)
	self.rateValues = {}
	local i = 0
	while true do
		local baseKey = string.format("%s.rateValues.rateValue(%d)", key, i)
		if not hasXMLProperty(xmlFile, baseKey) then
			break
		end
		local rateValue = {}
		rateValue.value = getXMLInt(xmlFile, baseKey .. "#value") or 0
		rateValue.text = g_i18n:convertText(getXMLString(xmlFile, baseKey .. "#text"), SeedRateMap.MOD_NAME)
		rateValue.color = string.getVector(getXMLString(xmlFile, baseKey .. "#color"), 3) or { 0, 0, 0 }
		rateValue.colorBlind = string.getVector(getXMLString(xmlFile, baseKey .. "#colorBlind"), 3)
		table.insert(self.rateValues, rateValue)
		i = i + 1
	end
	self.defaultSeedRate = MathUtil.round(#self.rateValues * 0.5)
	self.fruitTypes = {}
	self:loadFruitTypeSeedRatesFromXML(xmlFile, key)
	local missionInfo = g_currentMission.missionInfo
	local mapXMLFilename = Utils.getFilename(missionInfo.mapXMLFilename, g_currentMission.baseDirectory)
	local mapXMLFile = loadXMLFile("MapXML", mapXMLFilename)
	if mapXMLFile ~= nil then
		self:loadFruitTypeSeedRatesFromXML(mapXMLFile, "map.precisionFarming.seedRateMap")
		delete(mapXMLFile)
	end
	self.coverMap = g_precisionFarming.coverMap
	return true
end
function SeedRateMap:loadFruitTypeSeedRatesFromXML(xmlFile, key)
	local i = 0
	while true do
		local baseKey = string.format("%s.fruitTypes.fruitType(%d)", key, i)
		if not hasXMLProperty(xmlFile, baseKey) then
			break
		end
		local fruitTypeName = getXMLString(xmlFile, baseKey .. "#name")
		if fruitTypeName ~= nil then
			local fruitTypeDesc = g_fruitTypeManager:getFruitTypeByName(fruitTypeName)
			if fruitTypeDesc ~= nil then
				local fruitType = {}
				fruitType.index = fruitTypeDesc.index
				fruitType.seedRates = self:getRateValues(xmlFile, baseKey .. ".seedRates#rates", #self.rateValues)
				fruitType.seedUsages = self:getRateValues(xmlFile, baseKey .. ".seedRates#usages", #self.rateValues)
				if fruitType.seedRates ~= nil then
					if fruitType.seedUsages ~= nil then
						fruitType.soilTypes = {}
						local soilTypeIndex = 0
						while true do
							local soilKey = string.format("%s.soilTypes.soilType(%d)", baseKey, soilTypeIndex)
							if not hasXMLProperty(xmlFile, soilKey) then
								break
							end
							local soilType = {}
							soilType.index = getXMLInt(xmlFile, soilKey .. "#index") or 1
							soilType.yields = self:getRateValues(xmlFile, soilKey .. "#yields", #self.rateValues)
							if soilType.yields ~= nil then
								soilType.bestYieldIndex = 1
								local maxYield = 0
								for j = 1, #soilType.yields do
									if maxYield < soilType.yields[j] then
										maxYield = soilType.yields[j]
										soilType.bestYieldIndex = j
									end
								end
								fruitType.soilTypes[soilType.index] = soilType
							else
								Logging.warning("Invalid yield definitions in '%s'", soilKey)
							end
							soilTypeIndex = soilTypeIndex + 1
						end
						self.fruitTypes[fruitTypeDesc.index] = fruitType
					else
						Logging.warning("Invalid seed rates or usages in '%s'", baseKey)
					end
				end
			end
		end
		i = i + 1
	end
end
function SeedRateMap:getRateValues(xmlFile, key, numValues)
	local str = getXMLString(xmlFile, key)
	local values = str:split(" ")
	if #values == numValues then
		for i = 1, #values do
			values[i] = tonumber(values[i])
		end
		return values
	else
		return nil
	end
end
function SeedRateMap:getRateLabelByIndex(index)
	local rate = self.rateValues[index]
	if rate ~= nil then
		return rate.text
	else
		return "unknown"
	end
end
function SeedRateMap:update(dt) end
function SeedRateMap:updateSeedArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, fruitTypeIndex, autoMode, manualSeedRate)
	local soilMap = self.pfModule.soilMap
	if soilMap ~= nil then
		local modifier = self.densityMapModifiersSeedUpdate.modifier
		local maskFilter = self.densityMapModifiersSeedUpdate.maskFilter
		local soilFilter = self.densityMapModifiersSeedUpdate.soilFilter
		if modifier == nil or maskFilter == nil or soilFilter == nil then
			self.densityMapModifiersSeedUpdate.modifier = DensityMapModifier.new(self.bitVectorMap, 0, self.numChannels, g_terrainNode)
			modifier = self.densityMapModifiersSeedUpdate.modifier
			local fieldGroundSystem = g_currentMission.fieldGroundSystem
			local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
			self.densityMapModifiersSeedUpdate.maskFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
			maskFilter = self.densityMapModifiersSeedUpdate.maskFilter
			maskFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)
			self.densityMapModifiersSeedUpdate.soilFilter = DensityMapFilter.new(soilMap.bitVectorMap, soilMap.typeFirstChannel, soilMap.typeNumChannels)
			soilFilter = self.densityMapModifiersSeedUpdate.soilFilter
		end
		if type(startWorldX) == "number" then
			modifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
		elseif type(startWorldX) == "table" then
			startWorldX:applyToModifier(modifier)
		end
		local fruitTypeData = self.fruitTypes[fruitTypeIndex]
		if fruitTypeData ~= nil then
			if autoMode then
				local numPixelsChanged = 0
				local seedUsageSum = 0
				local seedRateSum = 0
				local seedRateIndexSum = 0
				for soilTypeIndex, soilTypeData in pairs(fruitTypeData.soilTypes) do
					if soilTypeData.bestYieldIndex == nil then
						continue
					end
					soilFilter:setValueCompareParams(DensityValueCompareType.EQUAL, soilTypeIndex - 1)
					local _, numPixels, _ = modifier:executeSetWithStats(soilTypeData.bestYieldIndex, maskFilter, soilFilter)
					numPixelsChanged = numPixelsChanged + numPixels
					seedUsageSum = seedUsageSum + fruitTypeData.seedUsages[soilTypeData.bestYieldIndex] * numPixels
					seedRateSum = seedRateSum + fruitTypeData.seedRates[soilTypeData.bestYieldIndex] * numPixels
					seedRateIndexSum = seedRateIndexSum + soilTypeData.bestYieldIndex * numPixels
				end
				if 0 < numPixelsChanged then
					return seedUsageSum / numPixelsChanged, seedRateSum / numPixelsChanged, MathUtil.round(seedRateIndexSum / numPixelsChanged)
				end
			else
				modifier:executeSet(manualSeedRate, maskFilter)
				return fruitTypeData.seedUsages[manualSeedRate], fruitTypeData.seedRates[manualSeedRate], manualSeedRate
			end
		elseif autoMode then
			modifier:executeSet(self.defaultSeedRate, maskFilter)
		else
			modifier:executeSet(manualSeedRate, maskFilter)
		end
	end
	return 0
end
function SeedRateMap:harvestUpdate(filter, fruitIndex, densityMapShape, useMinForageState, strawChopperActive)
	local soilMap = self.pfModule.soilMap
	if soilMap ~= nil and soilMap.bitVectorMap ~= nil then
		local functionData = self.densityMapModifiersHarvestMulti
		if functionData == nil then
			functionData = {}
			functionData.modifier = DensityMapModifier.new(self.bitVectorMap, 0, self.numChannels, g_terrainNode)
			functionData.modifier:setPolygonRoundingMode(DensityRoundingMode.INCLUSIVE)
			functionData.soilFilter = DensityMapFilter.new(soilMap.bitVectorMap, soilMap.typeFirstChannel, soilMap.typeNumChannels)
			functionData.multiModifiersByFruitIndex = {}
			functionData.accumulators = {}
			functionData.numChangedPixels = {}
			functionData.totalNumPixels = {}
			self.densityMapModifiersHarvestMulti = functionData
		end
		local fruitTypeData = self.fruitTypes[fruitIndex]
		if fruitTypeData == nil then
			self.lastSeedRateMultiplier = 1
			return
		end
		local multiModifier = functionData.multiModifiersByFruitIndex[fruitIndex]
		if multiModifier == nil then
			multiModifier = DensityMapMultiModifier.new()
			functionData.multiModifiersByFruitIndex[fruitIndex] = multiModifier
			for soilTypeIndex, soilTypeData in pairs(fruitTypeData.soilTypes) do
				if soilTypeData.bestYieldIndex == nil then
					continue
				end
				functionData.soilFilter:setValueCompareParams(DensityValueCompareType.EQUAL, soilTypeIndex - 1)
				multiModifier:addExecuteGet(tostring(soilTypeIndex), functionData.modifier, functionData.soilFilter)
			end
		end
		densityMapShape:applyToModifier(multiModifier)
		local accumulators = functionData.accumulators
		local numChangedPixels = functionData.numChangedPixels
		local totalNumPixels = functionData.totalNumPixels
		multiModifier:resetStats()
		multiModifier:execute(accumulators, numChangedPixels, totalNumPixels)
		local totalYield = 0
		local numTypes = 0
		for indexStr, accumulator in pairs(accumulators) do
			if 0 < accumulator then
				local index = tonumber(indexStr)
				local soilTypeData = fruitTypeData.soilTypes[index]
				local state = MathUtil.round(accumulator / numChangedPixels[indexStr])
				if soilTypeData.yields[state] == nil then
					continue
				end
				totalYield = totalYield + soilTypeData.yields[state]
				numTypes = numTypes + 1
				self.lastSeedRateFound = state
				self.lastSeedRateTarget = soilTypeData.bestYieldIndex
			end
		end
		local yield = 1
		if 0 < numTypes then
			yield = totalYield / numTypes
		end
		self.lastSeedRateMultiplier = yield
	end
end
function SeedRateMap:addClearToMultiModifier(multiModifier, filter1, filter2)
	local functionData = self.densityMapModifiersClear
	if functionData == nil then
		functionData = {}
		functionData.modifier = DensityMapModifier.new(self.bitVectorMap, 0, self.numChannels, g_terrainNode)
		self.densityMapModifiersClear = functionData
	end
	multiModifier:addExecuteSet(0, functionData.modifier, filter1, filter2)
end
function SeedRateMap:getSeedRateAtWorldPosition(x, z)
	x = MathUtil.round((x + g_currentMission.terrainSize * 0.5) / g_currentMission.terrainSize * self.sizeX + 0.5) - 1
	z = MathUtil.round((z + g_currentMission.terrainSize * 0.5) / g_currentMission.terrainSize * self.sizeY + 0.5) - 1
	if self.coverMap:getIsUncoveredAtPos(x, z) then
		return getBitVectorMapPoint(self.bitVectorMap, x, z, 0, self.numChannels)
	else
		return 0
	end
end
function SeedRateMap:getSeedRateYieldFactor(rawValue, fruitTypeIndex, soilTypeIndex)
	local fruitTypeData = self.fruitTypes[fruitTypeIndex]
	if fruitTypeData == nil then
		return 1, 1
	else
		local soilTypeData = fruitTypeData.soilTypes[soilTypeIndex]
		if soilTypeData == nil or soilTypeData.bestYieldIndex == nil then
			return 1, 1
		end
		local seedRateIndex = nil
		for i = 1, #self.rateValues do
			if self.rateValues[i].value == rawValue then
				seedRateIndex = i
				break
			end
		end
		if seedRateIndex ~= nil and soilTypeData.yields[seedRateIndex] ~= nil then
			return soilTypeData.yields[seedRateIndex], soilTypeData.yields[soilTypeData.bestYieldIndex]
		end
		return 1, 1
	end
end
function SeedRateMap:debugSetSeedRateLevel(fieldId, seedRate)
	fieldId = tonumber(fieldId)
	seedRate = tonumber(seedRate)
	if fieldId == nil or seedRate == nil then
		Logging.error("SeedRateMap: Invalid parameters. Usage: pfSeedRateSet <fieldId> <seedRate>")
		return
	end
	local field = g_fieldManager:getFieldById(tonumber(fieldId))
	if field ~= nil and field.getDensityMapPolygon ~= nil then
		local area = field:getDensityMapPolygon()
		local seedRateDesc = nil
		for i = 1, #self.rateValues do
			if self.rateValues[i].value == seedRate then
				seedRateDesc = self.rateValues[i]
				break
			end
		end
		if seedRateDesc ~= nil then
			self:updateSeedArea(area, nil, nil, nil, nil, nil, nil, false, seedRateDesc.value)
			Logging.info("SeedRateMap: Set seed rate of field %d to %d / %s", fieldId, seedRateDesc.value, seedRateDesc.text)
			return
		end
		Logging.error("SeedRateMap: Invalid seed rate value %d", seedRate)
	end
end
function SeedRateMap:updateLastYieldValues()
	local lastSeedRateMultiplier = self.lastSeedRateMultiplier
	local lastSeedRateFound = self.lastSeedRateFound
	local lastSeedRateTarget = self.lastSeedRateTarget
	self.lastSeedRateMultiplier = nil
	self.lastSeedRateFound = nil
	self.lastSeedRateTarget = nil
	return lastSeedRateMultiplier, lastSeedRateFound, lastSeedRateTarget
end
function SeedRateMap:buildOverlay(overlay, seedRateFilter, isColorBlindMode)
	resetDensityMapVisualizationOverlay(overlay)
	setOverlayColor(overlay, 1, 1, 1, 1)
	local seedRateMapId = self.bitVectorMap
	for i = 1, #self.rateValues do
		if seedRateFilter[i] then
			local rateValue = self.rateValues[i]
			local r = nil
			local g = nil
			local b = nil
			if isColorBlindMode then
				r = rateValue.colorBlind[1]
				g = rateValue.colorBlind[2]
				b = rateValue.colorBlind[3]
			else
				r = rateValue.color[1]
				g = rateValue.color[2]
				b = rateValue.color[3]
			end
			setDensityMapVisualizationOverlayStateColor(overlay, seedRateMapId, 0, 0, 0, self.numChannels, rateValue.value, r, g, b)
		end
	end
end
function SeedRateMap:getDisplayValues()
	if self.valuesToDisplay == nil then
		self.valuesToDisplay = {}
		for i = 1, #self.rateValues do
			local rateValue = self.rateValues[i]
			local rateValueToDisplay = {}
			rateValueToDisplay.colors = {}
			rateValueToDisplay.colors[true] = { rateValue.colorBlind or rateValue.color }
			rateValueToDisplay.colors[false] = { rateValue.color }
			rateValueToDisplay.description = rateValue.text
			table.insert(self.valuesToDisplay, rateValueToDisplay)
		end
	end
	return self.valuesToDisplay
end
function SeedRateMap:getValueFilter()
	if self.valueFilter == nil then
		self.valueFilter = {}
		for i = 1, #self.rateValues do
			table.insert(self.valueFilter, true)
		end
	end
	return self.valueFilter
end
function SeedRateMap:getHelpLinePage()
	return 7
end
function SeedRateMap:getSeedRateByFruitTypeAndIndex(fruitTypeIndex, seedRateIndex)
	if fruitTypeIndex ~= nil then
		local fruitTypeData = self.fruitTypes[fruitTypeIndex]
		if fruitTypeData ~= nil then
			return fruitTypeData.seedRates[seedRateIndex]
		end
	end
	return 0
end
function SeedRateMap:getIsFruitTypeSupported(fruitTypeIndex)
	if fruitTypeIndex ~= nil then
		return self.fruitTypes[fruitTypeIndex] ~= nil
	else
		return false
	end
end
function SeedRateMap:getOptimalSeedRateByFruitTypeAndSoiltype(fruitTypeIndex, soilTypeIndex)
	if fruitTypeIndex ~= nil then
		local fruitTypeData = self.fruitTypes[fruitTypeIndex]
		if fruitTypeData ~= nil then
			local soilType = fruitTypeData.soilTypes[soilTypeIndex]
			if soilType ~= nil then
				return soilType.bestYieldIndex
			end
		end
	end
	return nil
end
function SeedRateMap:createHelpMenuSeedRateTableRow(contentBox, template, isHeader, cropName, text1, text2, text3, text4)
	local row = template:clone(contentBox)
	if self.rowIndex % 2 == 0 then
		row:getDescendantByName("background"):setVisible(false)
	end
	if isHeader then
		row:getDescendantByName("cropName"):applyProfile("precisionFarmingSeedRateTextHeader", true)
		row:getDescendantByName("soil1"):applyProfile("precisionFarmingSeedRateTextHeader", true)
		row:getDescendantByName("soil2"):applyProfile("precisionFarmingSeedRateTextHeader", true)
		row:getDescendantByName("soil3"):applyProfile("precisionFarmingSeedRateTextHeader", true)
		row:getDescendantByName("soil4"):applyProfile("precisionFarmingSeedRateTextHeader", true)
	end
	row:getDescendantByName("cropName"):setText(cropName)
	row:getDescendantByName("soil1"):setText(text1)
	row:getDescendantByName("soil2"):setText(text2)
	row:getDescendantByName("soil3"):setText(text3)
	row:getDescendantByName("soil4"):setText(text4)
	row:updateAbsolutePosition()
	self.rowIndex = self.rowIndex + 1
end
function SeedRateMap:createHelpMenuSeedRateTable(contentBox, template)
	self.rowIndex = 0
	self:createHelpMenuSeedRateTableRow(contentBox, template, true, self.texts.cropNameHeader, self.texts.cropType1, self.texts.cropType2, self.texts.cropType3, self.texts.cropType4)
	for _, fruitType in pairs(self.fruitTypes) do
		local fillType = g_fruitTypeManager:getFillTypeByFruitTypeIndex(fruitType.index)
		if fillType == nil then
			continue
		end
		local title = fillType.title
		local bestYieldText = { "", "", "", "" }
		for j = 1, #fruitType.soilTypes do
			local soilType = fruitType.soilTypes[j]
			if soilType.bestYieldIndex == nil then
				continue
			end
			bestYieldText[j] = self:getRateLabelByIndex(soilType.bestYieldIndex)
		end
		self:createHelpMenuSeedRateTableRow(contentBox, template, false, title, unpack(bestYieldText))
	end
	contentBox:invalidateLayout()
end
