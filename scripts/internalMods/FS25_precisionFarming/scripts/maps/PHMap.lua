-- Local values: PHMap_mt
PHMap = {}
PHMap.MOD_NAME = g_currentModName
PHMap.NUM_BITS = 5
local PHMap_mt = Class(PHMap, ValueMap)

-- Upvalues: PHMap_mt
-- Local values: self
function PHMap.new(pfModule, customMt)
	-- upvalues: (copy) PHMap_mt
	local v4_ = ValueMap.new(pfModule, customMt or PHMap_mt)
	v4_.name = "pHMap"
	v4_.id = "PH_MAP"
	v4_.label = "ui_mapOverviewPH"
	v4_.densityMapModifiersInitialize = {}
	v4_.densityMapModifiersHarvestMulti = nil
	v4_.densityMapModifiersLockedState = {}
	v4_.densityMapModifiersSpray = nil
	v4_.densityMapModifiersResetLock = {}
	v4_.lastActualValue = -1
	v4_.lastTargetValue = -1
	v4_.lastRegularValue = -1
	v4_.minimapGradientSliceId = "precisionFarming.gradient_ph"
	v4_.minimapGradientColorBlindSliceId = "precisionFarming.gradient_color_blind"
	v4_.minimapLabelName = g_i18n:getText("ui_mapOverviewPH", PHMap.MOD_NAME)
	v4_.realisticSpreadPatternEnabled = true
	v4_.realisticSpreadOutputEnabled = true
	pfModule:addSetting("realisticSpreadPattern", g_i18n:getText("settingTitle_realisticSpreadPattern"), g_i18n:getText("settingDescription_realisticSpreadPattern"), v4_.onRealisticSpreadPatternSettingChanged, v4_, v4_.realisticSpreadPatternEnabled, true, nil, true)
	pfModule:addSetting("realisticSpreadOutput", g_i18n:getText("settingTitle_realisticSpreadOutput"), g_i18n:getText("settingDescription_realisticSpreadOutput"), v4_.onRealisticSpreadOutputSettingChanged, v4_, v4_.realisticSpreadOutputEnabled, true, nil, true)
	if g_server ~= nil then
		addConsoleCommand("pfPHSet", "Sets the given pH level on the given field", "debugSetPHLevel", v4_)
	end
	return v4_
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

-- Local values: i, baseKey, pHValue, j, j, index, pHValue, lastColor, lastColorBlind, i, nextColor, nextColorBlind, i, baseKey, valueTransformation, j, _, internalIndex, _, j, decreaseKey, decreasePerHarvest, ri, _, internalIndex, baseKey, levelDifference, yieldFactor, baseKey, levelDifferenceColor
function PHMap:loadFromXML(xmlFile, key, baseDirectory, configFileName, mapFilename)
	local v12_ = key .. ".pHMap"
	self.firstChannel = getXMLInt(xmlFile, v12_ .. ".bitVectorMap#firstChannel") or 1
	self.numChannels = getXMLInt(xmlFile, v12_ .. ".bitVectorMap#numChannels") or 4
	self.maxValue = getXMLInt(xmlFile, v12_ .. ".bitVectorMap#maxValue") or 2 ^ self.numChannels - 1
	self.sizeX = 1024
	self.sizeY = 1024
	local v13_, v14_ = self:loadSavedBitVectorMap("phMap", "precisionFarming_phMap.grle", self.numChannels, self.sizeX)
	self.bitVectorMap = v13_
	self.newBitVectorMap = v14_
	self:addBitVectorMapToSync(self.bitVectorMap)
	self:addBitVectorMapToSave(self.bitVectorMap, "precisionFarming_phMap.grle")
	self:addBitVectorMapToDelete(self.bitVectorMap)
	self.noiseFilename = getXMLString(xmlFile, v12_ .. ".noiseMap#filename")
	self.noiseNumChannels = getXMLInt(xmlFile, v12_ .. ".noiseMap#numChannels") or 2
	self.noiseResolution = getXMLInt(xmlFile, v12_ .. ".noiseMap#resolution") or 1024
	self.noiseMaxValue = 2 ^ self.noiseNumChannels - 1
	self.bitVectorMapNoise = createBitVectorMap("pHNoiseMap")
	if self.noiseFilename ~= nil then
		self.noiseFilename = Utils.getFilename(self.noiseFilename, baseDirectory)
		if not loadBitVectorMapFromFile(self.bitVectorMapNoise, self.noiseFilename, self.noiseNumChannels) then
			Logging.xmlWarning(configFileName, "Error while loading pH noise map \'%s\'", self.noiseFilename)
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
	self.outdatedLabel = g_i18n:convertText(getXMLString(xmlFile, v12_ .. ".texts#outdatedLabel") or "$l10n_ui_precisionFarming_outdatedData", PHMap.MOD_NAME)
	self.pHValues = {}
	self.pHValuesToDisplay = {}
	self.maxVisibleValue = 0
	local v15_ = 0
	while true do
		local v16_ = string.format("%s.pHValues.pHValue(%d)", v12_, v15_)
		if not hasXMLProperty(xmlFile, v16_) then
			break
		end
		local v17_ = {
			["value"] = getXMLInt(xmlFile, v16_ .. "#value") or 0,
			["realValue"] = getXMLFloat(xmlFile, v16_ .. "#realValue") or 0,
			["color"] = string.getVector(getXMLString(xmlFile, v16_ .. "#color"), 3),
			["colorBlind"] = string.getVector(getXMLString(xmlFile, v16_ .. "#colorBlind"), 3),
			["showOnHud"] = Utils.getNoNil(getXMLBool(xmlFile, v16_ .. "#showOnHud"), true)
		}
		local v18_ = self.pHValues
		table.insert(v18_, v17_)
		if v17_.showOnHud then
			local v19_ = self.pHValuesToDisplay
			table.insert(v19_, v17_)
			v17_.filterIndex = #self.pHValuesToDisplay
			for v20_ = #self.pHValues, 1, -1 do
				if self.pHValues[v20_].filterIndex == nil then
					self.pHValues[v20_].filterIndex = v17_.filterIndex
					break
				end
			end
		end
		self.maxVisibleValue = v17_.value
		v15_ = v15_ + 1
	end
	for v21_ = 1, #self.pHValues do
		if self.pHValues[v21_].filterIndex == nil then
			self.pHValues[v21_].filterIndex = #self.pHValuesToDisplay
		end
	end
	for v22_, v23_ in ipairs(self.pHValues) do
		if v23_.color == nil or v23_.colorBlind == nil then
			local v24_ = nil
			local v25_ = nil
			for v26_ = v22_ - 1, 1, -1 do
				if v26_ > 0 and self.pHValues[v26_].color ~= nil then
					v24_ = self.pHValues[v26_].color
					v25_ = self.pHValues[v26_].colorBlind
					break
				end
			end
			local v27_ = nil
			local v28_ = nil
			for v29_ = v22_ + 1, #self.pHValues do
				if self.pHValues[v29_].color ~= nil then
					v27_ = self.pHValues[v29_].color
					v28_ = self.pHValues[v29_].colorBlind
					break
				end
			end
			if v24_ ~= nil and v27_ ~= nil then
				v23_.color = { (v24_[1] + v27_[1]) * 0.5, (v24_[2] + v27_[2]) * 0.5, (v24_[3] + v27_[3]) * 0.5 }
			end
			if v25_ ~= nil and v28_ ~= nil then
				v23_.colorBlind = { (v25_[1] + v28_[1]) * 0.5, (v25_[2] + v28_[2]) * 0.5, (v25_[3] + v28_[3]) * 0.5 }
			end
		end
	end
	self.pHValuePerState = getXMLFloat(xmlFile, v12_ .. ".pHValues#pHValuePerState") or 0.125
	self.valueTransformations = {}
	local v30_ = 0
	while true do
		local v31_ = string.format("%s.valueTransformations.valueTransformation(%d)", v12_, v30_)
		if not hasXMLProperty(xmlFile, v31_) then
			break
		end
		local v32_ = {
			["soilTypeIndex"] = getXMLInt(xmlFile, v31_ .. "#soilTypeIndex") or 1,
			["baseRange"] = string.getVector(getXMLString(xmlFile, v31_ .. ".baseValue#range"), self.noiseMaxValue + 1)
		}
		if v32_.baseRange == nil then
			Logging.xmlWarning(configFileName, "Invalid base pH range for \'%s\'", v31_)
		else
			for v33_ = 1, #v32_.baseRange do
				local _, v34_ = self:getNearestPhValueFromValue(v32_.baseRange[v33_])
				v32_.baseRange[v33_] = v34_
			end
			local _, v35_ = self:getNearestPhValueFromValue(getXMLFloat(xmlFile, v31_ .. ".optimalValue#value") or 6.5)
			v32_.optimalValue = v35_
			v32_.regularOffset = (getXMLFloat(xmlFile, v31_ .. ".regularOffset#value") or self.pHValuePerState) / self.pHValuePerState
			v32_.decreasePerHarvest = {}
			local v36_ = 0
			while true do
				local v37_ = string.format("%s.decreasePerHarvest(%d)", v31_, v36_)
				if not hasXMLProperty(xmlFile, v37_) then
					break
				end
				local v38_ = {
					["range"] = string.getVector(getXMLString(xmlFile, v37_ .. "#range"), 2)
				}
				if v38_.range ~= nil then
					for v39_ = 1, #v38_.range do
						local _, v40_ = self:getNearestPhValueFromValue(v38_.range[v39_])
						v38_.range[v39_] = v40_
					end
				end
				v38_.decreaseValue = MathUtil.round((getXMLFloat(xmlFile, v37_ .. "#value") or self.pHValuePerState) / self.pHValuePerState)
				local v41_ = v32_.decreasePerHarvest
				table.insert(v41_, v38_)
				v36_ = v36_ + 1
			end
			local v42_ = self.valueTransformations
			table.insert(v42_, v32_)
		end
		v30_ = v30_ + 1
	end
	self.regularLimeUsage = getXMLFloat(xmlFile, v12_ .. ".valueTransformations#regularUsage") or 3000
	self.yieldCurve = AnimCurve.new(linearInterpolator1)
	local v43_ = 0
	while true do
		local v44_ = string.format("%s.yieldMappings.yieldMapping(%d)", v12_, v43_)
		if not hasXMLProperty(xmlFile, v44_) then
			break
		end
		local v45_ = getXMLInt(xmlFile, v44_ .. "#levelDifference") or 0
		local v46_ = {
			getXMLFloat(xmlFile, v44_ .. "#yieldFactor") or 1,
			["time"] = v45_
		}
		self.yieldCurve:addKeyframe(v46_)
		v43_ = v43_ + 1
	end
	self.levelDifferenceColors = {}
	local v47_ = 0
	while true do
		local v48_ = string.format("%s.levelDifferenceColors.levelDifferenceColor(%d)", v12_, v47_)
		if not hasXMLProperty(xmlFile, v48_) then
			break
		end
		local v49_ = {
			["levelDifference"] = getXMLInt(xmlFile, v48_ .. "#levelDifference") or 0,
			["color"] = string.getVector(getXMLString(xmlFile, v48_ .. "#color"), 3) or { 0, 0, 0 },
			["colorBlind"] = string.getVector(getXMLString(xmlFile, v48_ .. "#colorBlind"), 3) or { 0, 0, 0 }
		}
		v49_.color[4] = 1
		v49_.colorBlind[4] = 1
		v49_.additionalText = g_i18n:convertText(getXMLString(xmlFile, v48_ .. "#text"), PHMap.MOD_NAME)
		v49_.showWarning = Utils.getNoNil(getXMLBool(xmlFile, v48_ .. "#showWarning"), false)
		local v50_ = self.levelDifferenceColors
		table.insert(v50_, v49_)
		v47_ = v47_ + 1
	end
	self.limeUsage = {}
	self.limeUsage.usagePerState = getXMLFloat(xmlFile, v12_ .. ".limeUsage#usagePerState") or 730
	local v51_ = self.regularLimeUsage / self.limeUsage.usagePerState
	self.stateChangeDefault = math.ceil(v51_)
	self.minimapGradientLabelName = string.format("pH %.2f - %.2f", self:getMinMaxValue())
	self.coverMap = g_precisionFarming.coverMap
	self.soilMap = g_precisionFarming.soilMap
	return true
end

-- Local values: functionData, modifier, pHFilter, soilFilter, noiseFilter, pHInitModifier, pHInitMaskFilter, i, valueTransformation, j
function PHMap:addSetInitialState(multiModifier, soilBitVector, soilTypeFirstChannel, soilTypeNumChannels, farmlandMask)
	local v58_ = self.densityMapModifiersInitialize
	local v59_ = v58_.modifier
	local v60_ = v58_.pHFilter
	local v61_ = v58_.soilFilter
	local v62_ = v58_.noiseFilter
	local v63_ = v58_.pHInitModifier
	local v64_ = v58_.pHInitMaskFilter
	if v59_ == nil or (v60_ == nil or (v61_ == nil or (v62_ == nil or (v63_ == nil or v64_ == nil)))) then
		v58_.modifier = DensityMapModifier.new(self.bitVectorMap, self.firstChannel, self.numChannels, g_terrainNode)
		v59_ = v58_.modifier
		v58_.pHFilter = DensityMapFilter.new(self.bitVectorMap, self.firstChannel, self.numChannels)
		v58_.pHFilter:setValueCompareParams(DensityValueCompareType.EQUAL, self.maxValue)
		v60_ = v58_.pHFilter
		v58_.soilFilter = DensityMapFilter.new(soilBitVector, soilTypeFirstChannel, soilTypeNumChannels)
		v61_ = v58_.soilFilter
		v58_.noiseFilter = DensityMapFilter.new(self.bitVectorMapNoise, 0, self.noiseNumChannels)
		v62_ = v58_.noiseFilter
		v58_.pHInitModifier = DensityMapModifier.new(self.bitVectorMapPHInitMask, 0, 1, g_terrainNode)
		local _ = v58_.pHInitModifier
		v58_.pHInitMaskFilter = DensityMapFilter.new(self.bitVectorMapPHInitMask, 0, 1)
		v58_.pHInitMaskFilter:setValueCompareParams(DensityValueCompareType.EQUAL, 1)
	end
	for v65_ = 1, #self.valueTransformations do
		local v66_ = self.valueTransformations[v65_]
		v61_:setValueCompareParams(DensityValueCompareType.EQUAL, v66_.soilTypeIndex - 1)
		if farmlandMask == nil then
			multiModifier:addExecuteSet(self.maxValue, v59_, v61_)
		else
			multiModifier:addExecuteSet(self.maxValue, v59_, v61_, farmlandMask)
		end
		for v67_ = 1, self.noiseMaxValue + 1 do
			v62_:setValueCompareParams(DensityValueCompareType.EQUAL, v67_ - 1)
			multiModifier:addExecuteSet(v66_.baseRange[v67_], v59_, v60_, v62_)
		end
	end
end

-- Local values: coverMap, soilMap, functionData, i, valueTransformation, j, decreasePerHarvest, multiModifier, accumulators, numChangedPixels, totalNumPixels, pHMapChanged, indexStr, accumulator, index, valueTransformation, decreasePerHarvest
function PHMap:harvestUpdate(filter, fruitIndex, densityMapShape, useMinForageState, strawChopperActive)
	local v71_ = self.coverMap
	local v72_ = self.soilMap
	if v71_ ~= nil and (v71_.bitVectorMap ~= nil and (v72_ ~= nil and v72_.bitVectorMap ~= nil)) then
		local v73_ = self.densityMapModifiersHarvestMulti
		if v73_ == nil then
			v73_ = {
				["modifier"] = DensityMapModifier.new(self.bitVectorMap, self.firstChannel, self.numChannels, g_terrainNode)
			}
			v73_.modifier:setPolygonRoundingMode(DensityRoundingMode.INCLUSIVE)
			v73_.soilFilter = DensityMapFilter.new(v72_.bitVectorMap, v72_.typeFirstChannel, v72_.typeNumChannels)
			v73_.phFilter = DensityMapFilter.new(self.bitVectorMap, self.firstChannel, self.numChannels)
			v73_.phFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, 2, self.maxValue)
			v73_.modifierTempLock = DensityMapModifier.new(self.bitVectorMapPHStateChange, 0, 1, g_terrainNode)
			v73_.modifierTempLock:setPolygonRoundingMode(DensityRoundingMode.INCLUSIVE)
			v73_.tempLockFilter = DensityMapFilter.new(self.bitVectorMapPHStateChange, 0, 1)
			v73_.tempLockFilter:setValueCompareParams(DensityValueCompareType.EQUAL, 1)
			v73_.multiModifier = DensityMapMultiModifier.new()
			for v74_ = 1, #self.valueTransformations do
				local v75_ = self.valueTransformations[v74_]
				v73_.soilFilter:setValueCompareParams(DensityValueCompareType.EQUAL, v75_.soilTypeIndex - 1)
				for v76_ = 1, #v75_.decreasePerHarvest do
					local v77_ = v75_.decreasePerHarvest[v76_]
					if v77_.range == nil then
						v73_.phFilter:setValueCompareParams(DensityValueCompareType.GREATER, 1)
						v73_.multiModifier:addExecuteAddWithStats(tostring(v74_), -v77_.decreaseValue, v73_.modifier, filter, v73_.soilFilter, v73_.phFilter)
					else
						local v78_ = v73_.phFilter
						local v79_ = DensityValueCompareType.BETWEEN
						local v80_ = v77_.range[1] - 1
						v78_:setValueCompareParams(v79_, math.max(v80_), v77_.range[2] + 1)
						v73_.multiModifier:addExecuteAddWithStats(tostring(v74_), -v77_.decreaseValue, v73_.modifier, filter, v73_.soilFilter, v73_.phFilter)
					end
				end
			end
			v73_.accumulators = {}
			v73_.numChangedPixels = {}
			v73_.totalNumPixels = {}
			self.densityMapModifiersHarvestMulti = v73_
		end
		local v81_ = v73_.multiModifier
		densityMapShape:applyToModifier(v81_)
		local v82_ = v73_.accumulators
		local v83_ = v73_.numChangedPixels
		local v84_ = v73_.totalNumPixels
		v81_:resetStats()
		v81_:execute(v82_, v83_, v84_)
		local v85_ = false
		for v86_, v87_ in pairs(v82_) do
			if v87_ > 0 then
				local v88_ = tonumber(v86_)
				local v89_ = self.valueTransformations[v88_]
				self.lastActualValue = v87_ / v83_[v86_]
				self.lastTargetValue = v89_.optimalValue
				local v90_ = v89_.decreasePerHarvest[1]
				self.lastRegularValue = v89_.optimalValue - v90_.decreaseValue * 1.5 * v89_.regularOffset
				v85_ = true
			end
		end
		if v85_ then
			self:setMinimapRequiresUpdate(true)
		end
		return v85_
	end
end

-- Local values: functionData, soilMap, fieldGroundSystem, sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels
function PHMap:getSprayFunctionData()
	local v92_ = self.densityMapModifiersSpray
	if v92_ == nil then
		v92_ = {}
		local v93_ = self.soilMap
		v92_.modifier = DensityMapModifier.new(self.bitVectorMap, self.firstChannel, self.numChannels, g_terrainNode)
		v92_.soilFilter = DensityMapFilter.new(v93_.bitVectorMap, v93_.typeFirstChannel, v93_.typeNumChannels)
		v92_.phFilter = DensityMapFilter.new(self.bitVectorMap, self.firstChannel, self.numChannels)
		v92_.phFilter:setValueCompareParams(DensityValueCompareType.GREATER, self.maxVisibleValue)
		v92_.phFilterMax = DensityMapFilter.new(self.bitVectorMap, self.firstChannel, self.numChannels)
		v92_.phFilterMax:setValueCompareParams(DensityValueCompareType.GREATER, self.maxVisibleValue)
		v92_.modifierLock = DensityMapModifier.new(self.bitVectorMapPHStateChange, 1, 1, g_terrainNode)
		v92_.lockFilter = DensityMapFilter.new(self.bitVectorMapPHStateChange, 1, 1)
		v92_.lockFilter:setValueCompareParams(DensityValueCompareType.EQUAL, 0)
		local v94_, v95_, v96_ = g_currentMission.fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_TYPE)
		v92_.sprayTypeFilter = DensityMapFilter.new(v94_, v95_, v96_)
		self.densityMapModifiersSpray = v92_
	end
	return v92_
end

-- Local values: coverMap, soilMap, sprayTypeDesc, functionData, modifierLock, sprayTypeFilter
function PHMap:preUpdatePHLevelAtArea(densityMapShape, sprayTypeIndex, delta)
	local v100_ = self.coverMap
	local v101_ = self.soilMap
	if v100_ ~= nil and (v100_.bitVectorMap ~= nil and (v101_ ~= nil and v101_.bitVectorMap ~= nil)) then
		local v102_ = g_sprayTypeManager:getSprayTypeByIndex(sprayTypeIndex)
		if v102_ ~= nil then
			local v103_ = self:getSprayFunctionData()
			local v104_ = v103_.modifierLock
			local v105_ = v103_.sprayTypeFilter
			densityMapShape:applyToModifier(v104_)
			v105_:setSupersamplingMode(DensityFilterSupersamplingMode.ANY)
			v105_:setValueCompareParams(DensityValueCompareType.EQUAL, v102_.sprayGroundType)
			v104_:executeSet(0)
			v104_:executeSet(1, v105_)
		end
	end
end

-- Local values: coverMap, soilMap, sprayTypeDesc, functionData, modifier, modifierLock, phFilterMax, lockFilter, _, numChangedPixels, _
function PHMap:addPHLevelAtArea(densityMapShape, sprayTypeIndex, delta, ignoreLock)
	local v111_ = self.coverMap
	local v112_ = self.soilMap
	if v111_ ~= nil and (v111_.bitVectorMap ~= nil and (v112_ ~= nil and (v112_.bitVectorMap ~= nil and g_sprayTypeManager:getSprayTypeByIndex(sprayTypeIndex) ~= nil))) then
		local v113_ = self:getSprayFunctionData()
		local v114_ = v113_.modifier
		local v115_ = v113_.modifierLock
		local v116_ = v113_.phFilterMax
		local v117_ = v113_.lockFilter
		densityMapShape:applyToModifier(v114_)
		densityMapShape:applyToModifier(v115_)
		if ignoreLock then
			v117_ = nil
		end
		local _, v118_, _ = v114_:executeAddWithStats(delta, v117_)
		v114_:executeSet(self.maxVisibleValue, v116_)
		v115_:executeSet(1, v117_)
		if v118_ > 0 then
			self:setMinimapRequiresUpdate(true)
		end
		return v118_
	end
end

-- Local values: coverMap, soilMap, sprayTypeDesc, functionData, modifier, modifierLock, phFilter, lockFilter, _, numChangedPixels, _
function PHMap:updatePHLevelAtArea(densityMapShape, sprayTypeIndex, targetLevel, ignoreLock)
	local v124_ = self.maxValue
	local v125_ = math.min(targetLevel, v124_)
	local v126_ = self.coverMap
	local v127_ = self.soilMap
	if v126_ ~= nil and (v126_.bitVectorMap ~= nil and (v127_ ~= nil and (v127_.bitVectorMap ~= nil and g_sprayTypeManager:getSprayTypeByIndex(sprayTypeIndex) ~= nil))) then
		local v128_ = self:getSprayFunctionData()
		local v129_ = v128_.modifier
		local v130_ = v128_.modifierLock
		local v131_ = v128_.phFilter
		local v132_ = v128_.lockFilter
		densityMapShape:applyToModifier(v129_)
		densityMapShape:applyToModifier(v130_)
		if ignoreLock then
			v132_ = nil
		end
		v131_:setValueCompareParams(DensityValueCompareType.BETWEEN, 0, v125_ - 1)
		local _, v133_, _ = v129_:executeSetWithStats(v125_, v131_, v132_)
		v130_:executeSet(1, v132_)
		if v133_ > 0 then
			self:setMinimapRequiresUpdate(true)
		end
		return v133_
	end
end

-- Local values: coverMap, soilMap, sprayTypeDesc, functionData, modifier, modifierLock, phFilter, lockFilter, _, numChangedPixels, _
function PHMap:setPHLevelAtArea(densityMapShape, sprayTypeIndex, targetLevel, ignoreLock)
	local v139_ = self.maxValue
	local v140_ = math.clamp(targetLevel, 0, v139_)
	local v141_ = self.coverMap
	local v142_ = self.soilMap
	if v141_ ~= nil and (v141_.bitVectorMap ~= nil and (v142_ ~= nil and (v142_.bitVectorMap ~= nil and g_sprayTypeManager:getSprayTypeByIndex(sprayTypeIndex) ~= nil))) then
		local v143_ = self:getSprayFunctionData()
		local v144_ = v143_.modifier
		local v145_ = v143_.modifierLock
		local _ = v143_.phFilter
		local v146_ = v143_.lockFilter
		densityMapShape:applyToModifier(v144_)
		densityMapShape:applyToModifier(v145_)
		if ignoreLock then
			v146_ = nil
		end
		local _, v147_, _ = v144_:executeSetWithStats(v140_, v146_)
		v145_:executeSet(1, v146_)
		if v147_ > 0 then
			self:setMinimapRequiresUpdate(true)
		end
		return v147_
	end
end

function PHMap:getLevelAtWorldPos(x, z)
	local v151_ = MathUtil.round((x + g_currentMission.terrainSize * 0.5) / g_currentMission.terrainSize * self.sizeX + 0.5) - 1
	local v152_ = MathUtil.round((z + g_currentMission.terrainSize * 0.5) / g_currentMission.terrainSize * self.sizeY + 0.5) - 1
	return not self.coverMap:getIsUncoveredAtPos(v151_, v152_) and 0 or getBitVectorMapPoint(self.bitVectorMap, v151_, v152_, self.firstChannel, self.numChannels)
end

-- Local values: coverMap, soilMap, modifierLock, sprayTypeFilter, coverMaskFilter, fieldGroundSystem, sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels, sprayTypeDesc, _, numPixels, _
function PHMap:getIsLockedAtWorldPos(wx, wz, sprayTypeIndex)
	local v157_ = self.coverMap
	local v158_ = self.soilMap
	if v157_ ~= nil and (v157_.bitVectorMap ~= nil and (v158_ ~= nil and v158_.bitVectorMap ~= nil)) then
		local v159_ = self.densityMapModifiersLockedState.modifierLock
		local v160_ = self.densityMapModifiersLockedState.sprayTypeFilter
		local v161_ = self.densityMapModifiersLockedState.coverMaskFilter
		if v159_ == nil or (v160_ == nil or v161_ == nil) then
			self.densityMapModifiersLockedState.modifierLock = DensityMapModifier.new(self.bitVectorMapPHStateChange, 1, 1, g_terrainNode)
			v159_ = self.densityMapModifiersLockedState.modifierLock
			v159_:setPolygonRoundingMode(DensityRoundingMode.INCLUSIVE)
			local v162_, v163_, v164_ = g_currentMission.fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_TYPE)
			self.densityMapModifiersLockedState.sprayTypeFilter = DensityMapFilter.new(v162_, v163_, v164_)
			v160_ = self.densityMapModifiersLockedState.sprayTypeFilter
			v160_:setSupersamplingMode(DensityFilterSupersamplingMode.ALL)
			self.densityMapModifiersLockedState.coverMaskFilter = DensityMapFilter.new(v157_.bitVectorMap, v157_.firstChannel, v157_.numChannels)
			v161_ = self.densityMapModifiersLockedState.coverMaskFilter
			v161_:setValueCompareParams(DensityValueCompareType.GREATER, 0)
		end
		local v165_ = g_sprayTypeManager:getSprayTypeByIndex(sprayTypeIndex)
		if v165_ ~= nil then
			v159_:setParallelogramWorldCoords(wx, wz, wx + 0.001, wz, wx, wz + 0.001, DensityCoordType.POINT_POINT_POINT)
			v160_:setValueCompareParams(DensityValueCompareType.NOTEQUAL, v165_.sprayGroundType)
			local _, v166_, _ = v159_:executeGet(v161_, v160_)
			return v166_ == 0
		end
	end
	return false
end

-- Local values: distance, foundUncovered, i
function PHMap:getNextValidDetectionPoint(wx, wz, dirX, dirZ, maxDistance, sprayTypeIndex)
	local v174_, v175_ = ValueMap.roundToPixelCenter(wx, wz, g_currentMission.terrainSize, self.sizeX)
	local v176_, v177_
	if math.abs(dirX) > math.abs(dirZ) then
		v176_ = math.sign(dirX)
		v177_ = 0
	else
		v177_ = math.sign(dirZ)
		v176_ = 0
	end
	local v178_ = g_currentMission.terrainSize / self.sizeX
	local v179_ = maxDistance / v178_
	local v180_ = false
	for _ = 1, math.ceil(v179_) do
		if self.coverMap:getIsUncoveredAtPos(v174_, v175_, true) then
			if not self:getIsLockedAtWorldPos(v174_, v175_, sprayTypeIndex) then
				return v174_, v175_, true
			end
			v180_ = true
		end
		v174_ = v174_ + v176_ * v178_
		v175_ = v175_ + v177_ * v178_
	end
	return nil, nil, v180_
end

-- Local values: literPerHectar, litersPerUpdate, regularUsage
function PHMap:getLimeUsage(workingWidth, lastSpeed, statesChanged, dt)
	local v186_ = self:getLimeUsageByStateChange(statesChanged)
	return v186_ * (lastSpeed / 3600) / (10000 / workingWidth) * dt, v186_, self.regularLimeUsage * (lastSpeed / 3600) / (10000 / workingWidth) * dt
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

-- Local values: i, pHValue
function PHMap:getPhValueFromInternalValue(internal)
	for v194_ = 1, #self.pHValues do
		local v195_ = self.pHValues[v194_]
		if v195_.value == math.floor(internal) then
			return v195_.realValue
		end
	end
	return 0
end

-- Local values: minDifference, minValue, minValueInternal, i, pHValue, difference
function PHMap:getNearestPhValueFromValue(value)
	local v198_ = 100
	local v199_ = 0
	local v200_ = 0
	if value > 0 then
		for v201_ = 1, #self.pHValues do
			local v202_ = self.pHValues[v201_].realValue
			local v203_ = value - v202_
			local v204_ = math.abs(v203_)
			if v204_ < v198_ then
				v200_ = self.pHValues[v201_].value
				v199_ = v202_
				v198_ = v204_
			end
		end
	end
	return v199_, v200_
end

-- Local values: i, valueTransformation
function PHMap:getOptimalPHValueForSoilTypeIndex(soilTypeIndex)
	for v207_ = 1, #self.valueTransformations do
		local v208_ = self.valueTransformations[v207_]
		if v208_.soilTypeIndex == soilTypeIndex then
			return v208_.optimalValue
		end
	end
	return 0
end

function PHMap:getMinMaxValue()
	if #self.pHValues > 0 then
		return self.pHValues[1].realValue, self.pHValues[#self.pHValues].realValue, #self.pHValues
	else
		return 0, 1, 0
	end
end

-- Local values: actual, target, regular
function PHMap:updateLastPhValues()
	local v211_ = self.lastActualValue
	local v212_ = self.lastTargetValue
	local v213_ = self.lastRegularValue
	self.lastActualValue = -1
	self.lastTargetValue = -1
	self.lastRegularValue = -1
	return v211_, v212_, v213_
end

function PHMap:getYieldFactorByLevelDifference(difference)
	return self.yieldCurve:get(difference)
end

-- Local values: coverMap, coverMask, i, pHValue, color
function PHMap:buildOverlay(overlay, filter, isColorBlindMode, isMinimap)
	resetDensityMapVisualizationOverlay(overlay)
	setOverlayColor(overlay, 1, 1, 1, 1)
	local v220_ = self.coverMap
	if v220_ ~= nil then
		local v221_ = 2 ^ (v220_.numChannels - 1) - 1
		local v222_ = bit32.lshift(v221_, 1)
		for v223_ = 1, #self.pHValues do
			local v224_ = self.pHValues[v223_]
			if v224_.color ~= nil and filter[v224_.filterIndex] then
				local v225_ = v224_.color
				if isColorBlindMode then
					v225_ = v224_.colorBlind or v224_.color
				end
				setDensityMapVisualizationOverlayStateColor(overlay, self.bitVectorMap, v220_.bitVectorMap, v222_, self.firstChannel, self.numChannels, v224_.value, v225_[1], v225_[2], v225_[3])
			end
		end
	end
end

-- Local values: i, pHValue, yieldValueToDisplay, yieldValueToDisplay
function PHMap:getDisplayValues()
	if self.valuesToDisplay == nil then
		self.valuesToDisplay = {}
		for v227_ = 1, #self.pHValuesToDisplay do
			local v228_ = self.pHValuesToDisplay[v227_]
			local v229_ = {
				["colors"] = {}
			}
			v229_.colors[true] = { v228_.colorBlind or v228_.color }
			v229_.colors[false] = { v228_.color }
			v229_.description = string.format("%.2f", v228_.realValue)
			local v230_ = self.valuesToDisplay
			table.insert(v230_, v229_)
		end
		local v231_ = {
			["colors"] = {}
		}
		v231_.colors[true] = {
			{ 0, 0, 0 }
		}
		v231_.colors[false] = {
			{ 0, 0, 0 }
		}
		v231_.description = self.outdatedLabel
		local v232_ = self.valuesToDisplay
		table.insert(v232_, v231_)
	end
	return self.valuesToDisplay
end

-- Local values: numValues, i
function PHMap:getValueFilter()
	if self.valueFilter == nil or self.valueFilterEnabled == nil then
		self.valueFilter = {}
		self.valueFilterEnabled = {}
		local v234_ = #self.pHValuesToDisplay
		for v235_ = 1, v234_ + 1 do
			local v236_ = self.valueFilter
			table.insert(v236_, true)
			local v237_ = self.valueFilterEnabled
			local v238_ = v235_ <= v234_
			table.insert(v237_, v238_)
		end
	end
	return self.valueFilter, self.valueFilterEnabled
end

function PHMap:getMinimapZoomFactor()
	return 3
end

-- Local values: name
function PHMap:collectFieldInfos(fieldInfoDisplayExtension)
	fieldInfoDisplayExtension:addFieldInfo(g_i18n:getText("fieldInfo_phValue", PHMap.MOD_NAME), self, self.updateFieldInfoDisplay, 2, self.getFieldInfoYieldChange)
end

function PHMap:getAllowCoverage()
	return true
end

function PHMap:getHelpLinePage()
	return 4
end

-- Local values: phLevel, soilTypeIndex, i, valueTransformation, color, additionalText, showWarning, levelDifference, j, levelDifferenceColor
function PHMap:updateFieldInfoDisplay(fieldInfo, x, z, isColorBlindMode)
	local v246_ = self:getLevelAtWorldPos(x, z)
	local v247_ = self.soilMap:getTypeIndexAtWorldPos(x, z)
	for v248_ = 1, #self.valueTransformations do
		local v249_ = self.valueTransformations[v248_]
		if v249_.soilTypeIndex == v247_ then
			local v250_ = v249_.optimalValue - v246_
			local v251_ = math.abs(v250_)
			local v252_ = nil
			local v253_ = nil
			local v254_ = nil
			for v255_ = 1, #self.levelDifferenceColors do
				local v256_ = self.levelDifferenceColors[v255_]
				if v256_.levelDifference <= v251_ then
					if isColorBlindMode then
						v252_ = v256_.colorBlind
					else
						v252_ = v256_.color
					end
					v253_ = v256_.additionalText
					v254_ = v256_.showWarning
				end
			end
			fieldInfo.pHFactor = self:getYieldFactorByLevelDifference(v246_ - v249_.optimalValue)
			return string.format("%.3f / %.3f", self:getPhValueFromInternalValue(v246_), self:getPhValueFromInternalValue(v249_.optimalValue)), v252_, v253_, v254_
		end
	end
	return nil
end

function PHMap:getFieldInfoYieldChange(fieldInfo)
	return fieldInfo.pHFactor or 0, 0.2
end

-- Local values: minTime, maxTime, i, keyframe, value, x
function PHMap:drawYieldDebug(pHActualValue, pHTargetValue)
	if self.debugGraph == nil then
		self.debugGraph = Graph.new(#self.yieldCurve.keyframes, 0.45, 0.05, 0.2, 0.15, 0, 100, false, "%", Graph.STYLE_LINES)
		self.debugGraph:setHorizontalLine(10, true, 1, 1, 1, 1)
		self.debugGraph:setVerticalLine(0.1, false, 1, 1, 1, 1)
		self.debugGraph:setColor(0, 1, 0, 1)
	end
	local v261_ = math.huge
	local v262_ = -math.huge
	for v263_ = 1, #self.yieldCurve.keyframes do
		local v264_ = self.yieldCurve.keyframes[v263_]
		local v265_ = self.yieldCurve:get(v264_.time)
		self.debugGraph:setValue(v263_, v265_ * 100)
		local v266_ = v264_.time
		v261_ = math.min(v266_, v261_)
		local v267_ = v264_.time
		v262_ = math.max(v267_, v262_)
	end
	self.debugGraph:draw()
	if v261_ ~= math.huge then
		local v268_ = self.debugGraph.left + MathUtil.inverseLerp(v261_, v262_, pHActualValue - pHTargetValue) * self.debugGraph.width
		setOverlayColor(self.debugGraph.overlayHLine, 1, 0, 0, 1)
		renderOverlay(self.debugGraph.overlayHLine, v268_, self.debugGraph.bottom, g_pixelSizeX, self.debugGraph.height)
		setOverlayColor(self.debugGraph.overlayHLine, 1, 1, 1, 1)
	end
end

-- Local values: field, area, _, targetLevel
function PHMap:debugSetPHLevel(fieldId, pHLevel)
	local v272_ = tonumber(fieldId)
	local v273_ = tonumber(pHLevel)
	if v272_ == nil or v273_ == nil then
		Logging.error("PHMap: Invalid parameters. Usage: pfPHSetLevel <fieldId> <pHLevel>")
	else
		local v274_ = g_fieldManager:getFieldById((tonumber(v272_)))
		if v274_ ~= nil and v274_.getDensityMapPolygon ~= nil then
			local v275_ = v274_:getDensityMapPolygon()
			local _, v276_ = self:getNearestPhValueFromValue(v273_)
			self:setPHLevelAtArea(v275_, SprayType.LIME, v276_, true)
			Logging.info("PHMap: Set pH level of field %d to %.1f", v272_, v273_)
		end
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
