-- Local values: NitrogenMap_mt, worldCoordsToLocalCoords
NitrogenMap = {}
NitrogenMap.MOD_NAME = g_currentModName
NitrogenMap.NUM_BITS = 6
NitrogenMap.DEBUG_N_OFFSET_MAP = false
local NitrogenMap_mt = Class(NitrogenMap, ValueMap)

-- Upvalues: NitrogenMap_mt
-- Local values: self
function NitrogenMap.new(pfModule, customMt)
	-- upvalues: (copy) NitrogenMap_mt
	local v4_ = ValueMap.new(pfModule, customMt or NitrogenMap_mt)
	v4_.name = "nitrogenMap"
	v4_.id = "N_MAP"
	v4_.label = "ui_mapOverviewNitrogen"
	v4_.densityMapModifiersInitialize = {}
	v4_.densityMapModifiersLockedState = {}
	v4_.densityMapModifiersSpray = nil
	v4_.densityMapModifiersDestroyFruit = {}
	v4_.densityMapModifiersStrawChopper = {}
	v4_.densityMapModifiersCropSensor = nil
	v4_.densityMapModifiersResetLock = {}
	v4_.densityMapModifiersFruitCheck = {}
	v4_.lastActualValue = -1
	v4_.lastTargetValue = -1
	v4_.lastYieldPotential = -1
	v4_.minimapGradientSliceId = "precisionFarming.gradient_red_green"
	v4_.minimapGradientColorBlindSliceId = "precisionFarming.gradient_color_blind"
	v4_.minimapLabelName = g_i18n:getText("ui_mapOverviewNitrogen", NitrogenMap.MOD_NAME)
	v4_.minimapLabelNameMission = g_i18n:getText("ui_growthMapFertilized")
	if g_server ~= nil then
		addConsoleCommand("pfNitrogenSet", "Sets the given nitrogen level on the given field", "debugSetNitrogenLevel", v4_, "fieldId; nitrogenLevel; [measured]")
	end
	return v4_
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

-- Local values: i, baseKey, nitrogenValue, lastOnHud, l, nitrogenValue, nextOnHud, j, nextNitrogenValue, numValues, r, g, b, baseKey, initialValue, j, j, missionInfo, mapXMLFilename, mapXMLFile, _, fruitType, fruitRequirement, baseKey, difference, yieldFactor, baseKey, levelDifferenceColor, maxFertilizerStates, colorBlind, colors, i, color, _, applicationRate
function NitrogenMap:loadFromXML(xmlFile, key, baseDirectory, configFileName, mapFilename)
	local v12_ = key .. ".nitrogenMap"
	self.firstChannel = getXMLInt(xmlFile, v12_ .. ".bitVectorMap#firstChannel") or 1
	self.numChannels = getXMLInt(xmlFile, v12_ .. ".bitVectorMap#numChannels") or 4
	self.maxValue = getXMLInt(xmlFile, v12_ .. ".bitVectorMap#maxValue") or 2 ^ self.numChannels - 1
	self.sizeX = 1024
	self.sizeY = 1024
	local v13_, v14_ = self:loadSavedBitVectorMap("nitrogenMap", "precisionFarming_nitrogenMap.grle", self.numChannels, self.sizeX)
	self.bitVectorMap = v13_
	self.newBitVectorMap = v14_
	self:addBitVectorMapToSync(self.bitVectorMap)
	self:addBitVectorMapToSave(self.bitVectorMap, "precisionFarming_nitrogenMap.grle")
	self:addBitVectorMapToDelete(self.bitVectorMap)
	self.noiseFilename = getXMLString(xmlFile, v12_ .. ".noiseMap#filename")
	self.noiseNumChannels = getXMLInt(xmlFile, v12_ .. ".noiseMap#numChannels") or 2
	self.noiseResolution = getXMLInt(xmlFile, v12_ .. ".noiseMap#resolution") or 1024
	self.noiseMaxValue = 2 ^ self.noiseNumChannels - 1
	self.bitVectorMapNoise = createBitVectorMap("nitrogenNoiseMap")
	if self.noiseFilename ~= nil then
		self.noiseFilename = Utils.getFilename(self.noiseFilename, baseDirectory)
		if not loadBitVectorMapFromFile(self.bitVectorMapNoise, self.noiseFilename, self.noiseNumChannels) then
			Logging.xmlWarning(xmlFile, "Error while loading pH noise map \'%s\'", self.noiseFilename)
			self.noiseFilename = nil
		end
	end
	if self.noiseFilename == nil then
		loadBitVectorMapNew(self.bitVectorMapNoise, self.noiseResolution, self.noiseResolution, self.noiseNumChannels, false)
	end
	self:addBitVectorMapToDelete(self.bitVectorMapNoise)
	local v15_, v16_ = self:loadSavedBitVectorMap("nOffsetMap", "precisionFarming_nOffsetMap.grle", 4, self.noiseResolution)
	self.bitVectorMapNOffset = v15_
	self.bitVectorMapNOffsetIsNew = v16_
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
	self.amountPerState = getXMLFloat(xmlFile, v12_ .. ".nitrogenValues#amountPerState") or 5
	self.nitrogenValues = {}
	self.numVisualValues = 0
	self.maxVisibleValue = 0
	local v17_ = 0
	while true do
		local v18_ = string.format("%s.nitrogenValues.nitrogenValue(%d)", v12_, v17_)
		if not hasXMLProperty(xmlFile, v18_) then
			break
		end
		local v19_ = {
			["value"] = getXMLInt(xmlFile, v18_ .. "#value") or 0,
			["realValue"] = getXMLFloat(xmlFile, v18_ .. "#realValue") or 0,
			["showOnHud"] = Utils.getNoNil(getXMLBool(xmlFile, v18_ .. "#showOnHud"), true),
			["color"] = string.getVector(getXMLString(xmlFile, v18_ .. "#color"), 3),
			["colorBlind"] = string.getVector(getXMLString(xmlFile, v18_ .. "#colorBlind"), 3)
		}
		local v20_ = self.nitrogenValues
		table.insert(v20_, v19_)
		v19_.index = #self.nitrogenValues
		v19_.filterIndex = self.numVisualValues + 1
		if v19_.showOnHud then
			self.numVisualValues = self.numVisualValues + 1
		end
		local v21_ = self.maxVisibleValue
		local v22_ = v19_.value
		self.maxVisibleValue = math.max(v21_, v22_)
		v17_ = v17_ + 1
	end
	local v23_ = nil
	for v24_ = 1, #self.nitrogenValues do
		local v25_ = self.nitrogenValues[v24_]
		if v25_.showOnHud then
			v23_ = v25_
		elseif v23_ ~= nil then
			v25_.filterIndex = v23_.filterIndex
			local v26_ = nil
			for v27_ = v24_ + 1, #self.nitrogenValues do
				local v28_ = self.nitrogenValues[v27_]
				if v28_.showOnHud then
					v26_ = v28_
					break
				end
			end
			if v26_ ~= nil then
				local v29_ = v26_.index - v23_.index
				v25_.color = { v23_.color[1] + (v26_.color[1] - v23_.color[1]) / v29_ * (v24_ - v23_.index), v23_.color[2] + (v26_.color[2] - v23_.color[2]) / v29_ * (v24_ - v23_.index), v23_.color[3] + (v26_.color[3] - v23_.color[3]) / v29_ * (v24_ - v23_.index) }
				v25_.colorBlind = { v23_.colorBlind[1] + (v26_.colorBlind[1] - v23_.colorBlind[1]) / v29_ * (v24_ - v23_.index), v23_.colorBlind[2] + (v26_.colorBlind[2] - v23_.colorBlind[2]) / v29_ * (v24_ - v23_.index), v23_.colorBlind[3] + (v26_.colorBlind[3] - v23_.colorBlind[3]) / v29_ * (v24_ - v23_.index) }
			end
		end
	end
	self.initialValues = {}
	local v30_ = 0
	while true do
		local v31_ = string.format("%s.initialValues.initialValue(%d)", v12_, v30_)
		if not hasXMLProperty(xmlFile, v31_) then
			break
		end
		local v32_ = {
			["soilTypeIndex"] = getXMLInt(xmlFile, v31_ .. "#soilTypeIndex") or 1,
			["baseRange"] = string.getVector(getXMLString(xmlFile, v31_ .. "#baseValueRange"), self.noiseMaxValue + 1)
		}
		for v33_ = 1, #v32_.baseRange do
			v32_.baseRange[v33_] = MathUtil.round(v32_.baseRange[v33_] / self.amountPerState)
		end
		local v34_ = self.initialValues
		table.insert(v34_, v32_)
		v30_ = v30_ + 1
	end
	self.initialSprayLevelBonus = string.getVector(getXMLString(xmlFile, v12_ .. ".initialValues#sprayLevelBonus")) or { 0, 0 }
	for v35_ = 1, #self.initialSprayLevelBonus do
		self.initialSprayLevelBonus[v35_] = MathUtil.round(self.initialSprayLevelBonus[v35_] / self.amountPerState)
	end
	self.applicationRates = {}
	self:loadApplicationRatesFromXML(xmlFile, v12_)
	self.fertilizerUsage = {}
	self.fertilizerUsage.nAmounts = {}
	self:loadFertilizerUsageFromXML(xmlFile, v12_)
	self.fruitRequirements = {}
	self.fruitTypeIndexToFruitRequirement = {}
	self:loadFruitRequirementsFromXML(configFileName, xmlFile, v12_)
	self.cropSensorFruitTypes = {}
	self:loadCropSensorFruitTypesFromXML(configFileName, xmlFile, v12_)
	local v36_ = g_currentMission.missionInfo
	local v37_ = Utils.getFilename(v36_.mapXMLFilename, g_currentMission.baseDirectory)
	local v38_ = loadXMLFile("MapXML", v37_)
	if v38_ ~= nil then
		self:loadApplicationRatesFromXML(v38_, "map.precisionFarming")
		self:loadFertilizerUsageFromXML(v38_, "map.precisionFarming")
		self:loadFruitRequirementsFromXML(v36_.mapXMLFilename, v38_, "map.precisionFarming")
		self:loadCropSensorFruitTypesFromXML(v36_.mapXMLFilename, v38_, "map.precisionFarming")
		delete(v38_)
	end
	for _, v39_ in ipairs(g_fruitTypeManager:getFruitTypes()) do
		if self.fruitTypeIndexToFruitRequirement[v39_.index] == nil then
			local v40_ = {
				["fruitTypeName"] = v39_.name,
				["fruitType"] = v39_,
				["bySoilType"] = self.fruitRequirements[1].bySoilType,
				["averageTargetLevel"] = self.fruitRequirements[1].averageTargetLevel or 0
			}
			local v41_ = self.fruitRequirements
			table.insert(v41_, v40_)
			self.fruitTypeIndexToFruitRequirement[v39_.index] = v40_
			Logging.devInfo("Use default Nitrogen requirements for fruitType \'%s\'", v39_.name)
		end
	end
	self.yieldCurve = AnimCurve.new(linearInterpolator1)
	local v42_ = 0
	while true do
		local v43_ = string.format("%s.yieldMappings.yieldMapping(%d)", v12_, v42_)
		if not hasXMLProperty(xmlFile, v43_) then
			break
		end
		local v44_ = (getXMLInt(xmlFile, v43_ .. "#difference") or 0) / self.amountPerState
		local v45_ = {
			getXMLFloat(xmlFile, v43_ .. "#yieldFactor") or 1,
			["time"] = v44_
		}
		self.yieldCurve:addKeyframe(v45_)
		v42_ = v42_ + 1
	end
	self.levelDifferenceColors = {}
	local v46_ = 0
	while true do
		local v47_ = string.format("%s.levelDifferenceColors.levelDifferenceColor(%d)", v12_, v46_)
		if not hasXMLProperty(xmlFile, v47_) then
			break
		end
		local v48_ = {
			["levelDifference"] = (getXMLInt(xmlFile, v47_ .. "#levelDifference") or 0) / self.amountPerState,
			["color"] = string.getVector(getXMLString(xmlFile, v47_ .. "#color"), 3) or { 0, 0, 0 },
			["colorBlind"] = string.getVector(getXMLString(xmlFile, v47_ .. "#colorBlind"), 3) or { 0, 0, 0 }
		}
		v48_.color[4] = 1
		v48_.colorBlind[4] = 1
		v48_.additionalText = g_i18n:convertText(getXMLString(xmlFile, v47_ .. "#text"), NitrogenMap.MOD_NAME)
		v48_.showWarning = Utils.getNoNil(getXMLBool(xmlFile, v47_ .. "#showWarning"), false)
		local v49_ = self.levelDifferenceColors
		table.insert(v49_, v48_)
		v46_ = v46_ + 1
	end
	self.fertilizerColors = {
		[true] = {},
		[false] = {}
	}
	local v50_ = g_currentMission.fieldGroundSystem:getMaxValue(FieldDensityMap.SPRAY_LEVEL)
	for v51_, v52_ in pairs(MapOverlayGenerator.FRUIT_COLORS_FERTILIZED) do
		for v53_ = #v52_, 1, -1 do
			local v54_ = v52_[v53_]
			local v55_ = self.fertilizerColors[v51_]
			table.insert(v55_, 1, v54_)
			if #self.fertilizerColors[v51_] == v50_ then
				break
			end
		end
	end
	self.fertilizerFillTypes = {}
	for _, v56_ in ipairs(self.applicationRates) do
		self.fertilizerFillTypes[v56_.fillTypeIndex] = v56_.fillTypeIndex
	end
	local v57_ = (getXMLFloat(xmlFile, v12_ .. ".applicationRates#defaultRate") or 100) / self.amountPerState
	self.stateChangeDefault = math.ceil(v57_)
	self.choppedStrawStateChange = (getXMLInt(xmlFile, v12_ .. ".choppedStraw#increase") or 25) / self.amountPerState
	self.catchCropsStateChange = (getXMLInt(xmlFile, v12_ .. ".catchCrops#increase") or 25) / self.amountPerState
	self.outdatedLabel = g_i18n:convertText(getXMLString(xmlFile, v12_ .. ".texts#outdatedLabel") or "$l10n_ui_precisionFarming_outdatedData", NitrogenMap.MOD_NAME)
	self.minimapGradientLabelName = string.format("%d - %d kg/ha", self:getMinMaxValue())
	self.coverMap = g_precisionFarming.coverMap
	self.soilMap = g_precisionFarming.soilMap
	self.seedRateMap = g_precisionFarming.seedRateMap
	return true
end

-- Local values: i, baseKey, fillTypeName, fillTypeIndex, applicationRate, j, soilKey, rateBySoil, applicationRateIndex, _applicationRate
function NitrogenMap:loadApplicationRatesFromXML(xmlFile, key)
	local v61_ = 0
	while true do
		local v62_ = string.format("%s.applicationRates.applicationRate(%d)", key, v61_)
		if not hasXMLProperty(xmlFile, v62_) then
			break
		end
		local v63_ = getXMLString(xmlFile, v62_ .. "#fillType")
		if v63_ == nil then
			Logging.xmlWarning(xmlFile, "Invalid fill type for nitrogen application rate \'%s\'", v62_)
		else
			local v64_ = g_fillTypeManager:getFillTypeIndexByName(v63_)
			if v64_ == nil or v64_ == FillType.UNKNOWN then
				Logging.xmlWarning(xmlFile, "Invalid fill type for nitrogen application rate \'%s\'", v62_)
			else
				local v65_ = {
					["fillTypeIndex"] = v64_,
					["autoAdjustToFruit"] = Utils.getNoNil(getXMLBool(xmlFile, v62_ .. "#autoAdjustToFruit"), false),
					["regularRate"] = getXMLFloat(xmlFile, v62_ .. "#regularRate"),
					["ratesBySoilType"] = {}
				}
				local v66_ = 0
				while true do
					local v67_ = string.format("%s.soil(%d)", v62_, v66_)
					if not hasXMLProperty(xmlFile, v67_) then
						break
					end
					local v68_ = {
						["soilTypeIndex"] = getXMLInt(xmlFile, v67_ .. "#soilTypeIndex") or 1,
						["rate"] = (getXMLInt(xmlFile, v67_ .. "#rate") or 5) / self.amountPerState
					}
					local v69_ = v65_.ratesBySoilType
					table.insert(v69_, v68_)
					v66_ = v66_ + 1
				end
				for v70_ = #self.applicationRates, 1, -1 do
					if self.applicationRates[v70_].fillTypeIndex == v65_.fillTypeIndex then
						table.remove(self.applicationRates, v70_)
					end
				end
				local v71_ = self.applicationRates
				table.insert(v71_, v65_)
			end
		end
		v61_ = v61_ + 1
	end
end

-- Local values: i, baseKey, fillTypeName, fillTypeIndex, nAmount, usageIndex, _nAmount
function NitrogenMap:loadFertilizerUsageFromXML(xmlFile, key)
	local v75_ = 0
	while true do
		local v76_ = string.format("%s.fertilizerUsage.nAmount(%d)", key, v75_)
		if not hasXMLProperty(xmlFile, v76_) then
			break
		end
		local v77_ = getXMLString(xmlFile, v76_ .. "#fillType")
		if v77_ == nil then
			Logging.xmlWarning(xmlFile, "Invalid fill type for nitrogen fertilizer amount \'%s\'", v76_)
		else
			local v78_ = g_fillTypeManager:getFillTypeIndexByName(v77_)
			if v78_ == nil or v78_ == FillType.UNKNOWN then
				Logging.xmlWarning(xmlFile, "Invalid fill type for nitrogen fertilizer amount \'%s\'", v76_)
			else
				local v79_ = {
					["fillTypeIndex"] = v78_,
					["amount"] = getXMLFloat(xmlFile, v76_ .. "#amount") or 1
				}
				for v80_ = #self.fertilizerUsage.nAmounts, 1, -1 do
					if self.fertilizerUsage.nAmounts[v80_].fillTypeIndex == v79_.fillTypeIndex then
						table.remove(self.fertilizerUsage.nAmounts, v80_)
					end
				end
				local v81_ = self.fertilizerUsage.nAmounts
				table.insert(v81_, v79_)
			end
		end
		v75_ = v75_ + 1
	end
end

-- Local values: i, baseKey, isOverwrittenRequirement, fruitRequirement, j, _fruitRequirement, fruitType, j, soilKey, soilSettings, isOverwrittenSoilType, l, _soilSettings, targetLevel, _, internalTarget, reduction, reductionForage, numSettings, targetLevelSum, l, soilSettings
function NitrogenMap:loadFruitRequirementsFromXML(configFileName, xmlFile, key)
	local v86_ = 0
	while true do
		local v87_ = string.format("%s.fruitRequirements.fruitRequirement(%d)", key, v86_)
		if not hasXMLProperty(xmlFile, v87_) then
			break
		end
		local v88_ = false
		local v89_ = {
			["fruitTypeName"] = getXMLString(xmlFile, v87_ .. "#fruitTypeName")
		}
		if v89_.fruitTypeName == nil then
			Logging.xmlWarning(configFileName, "Invalid fruit type for nitrogen fruitRequirement \'%s\'", v87_)
		else
			for v90_ = 1, #self.fruitRequirements do
				local v91_ = self.fruitRequirements[v90_]
				if string.lower(v91_.fruitTypeName) == string.lower(v89_.fruitTypeName) then
					v89_ = v91_
					v88_ = true
				end
			end
			v89_.alwaysAllowFertilization = Utils.getNoNil(getXMLBool(xmlFile, v87_ .. "#alwaysAllowFertilization"), Utils.getNoNil(v89_.alwaysAllowFertilization, false))
			v89_.ignoreOverfertilization = Utils.getNoNil(getXMLBool(xmlFile, v87_ .. "#ignoreOverfertilization"), false)
			v89_.availableAsDefaultRate = Utils.getNoNil(getXMLBool(xmlFile, v87_ .. "#availableAsDefaultRate"), true)
			v89_.requiresDefaultMode = Utils.getNoNil(getXMLBool(xmlFile, v87_ .. "#requiresDefaultMode"), false)
			local v92_ = g_fruitTypeManager:getFruitTypeByName(v89_.fruitTypeName)
			if v92_ ~= nil then
				v89_.fruitType = v92_
				v89_.bySoilType = v89_.bySoilType or {}
				local v93_ = 0
				while true do
					local v94_ = string.format("%s.soil(%d)", v87_, v93_)
					if not hasXMLProperty(xmlFile, v94_) then
						break
					end
					local v95_ = {
						["soilTypeIndex"] = getXMLInt(xmlFile, v94_ .. "#soilTypeIndex") or 1
					}
					local v96_ = false
					for v97_ = 1, #v89_.bySoilType do
						local v98_ = v89_.bySoilType[v97_]
						if v98_.soilTypeIndex == v95_.soilTypeIndex then
							v95_ = v98_
							v96_ = true
						end
					end
					local v99_ = getXMLInt(xmlFile, v94_ .. "#targetLevel")
					if v99_ ~= nil then
						local v100_
						v100_, v99_ = self:getNearestNitrogenValueFromValue(v99_)
					end
					v95_.targetLevel = v99_ or (v95_.targetLevel or 0)
					local v101_ = getXMLInt(xmlFile, v94_ .. "#reduction")
					if v101_ ~= nil then
						local v102_ = v101_ / self.amountPerState
						v101_ = math.floor(v102_)
					end
					v95_.reduction = v101_ or (v95_.reduction or 0)
					local v103_ = getXMLInt(xmlFile, v94_ .. "#reductionForage")
					if v103_ ~= nil then
						local v104_ = v103_ / self.amountPerState
						v103_ = math.floor(v104_)
					end
					v95_.reductionForage = v103_ or (v95_.reductionForage or v95_.reduction)
					v95_.yieldPotential = getXMLFloat(xmlFile, v94_ .. "#yieldPotential") or (v95_.yieldPotential or 1)
					if not v96_ then
						local v105_ = v89_.bySoilType
						table.insert(v105_, v95_)
					end
					v93_ = v93_ + 1
				end
				v89_.averageTargetLevel = 0
				local v106_ = #v89_.bySoilType
				if v106_ > 0 then
					local v107_ = 0
					for v108_ = 1, v106_ do
						v107_ = v107_ + v89_.bySoilType[v108_].targetLevel
					end
					v89_.averageTargetLevel = v107_ / v106_
				end
				if not v88_ then
					local v109_ = self.fruitRequirements
					table.insert(v109_, v89_)
					self.fruitTypeIndexToFruitRequirement[v92_.index] = v89_
				end
			end
		end
		v86_ = v86_ + 1
	end
end

-- Local values: fruitTypesStr, fruitTypes, j, fruitType
function NitrogenMap:loadCropSensorFruitTypesFromXML(configFileName, xmlFile, key)
	local v113_ = getXMLString(xmlFile, key .. ".cropSensor#fruitTypes")
	if v113_ ~= nil then
		local v114_ = v113_:split(" ")
		for v115_ = 1, #v114_ do
			local v116_ = g_fruitTypeManager:getFruitTypeByName(v114_[v115_])
			if v116_ == nil then
				Logging.xmlWarning(xmlFile, "Invalid fruit type \'%s\' for crop sensor \'%s\'", v114_[v115_], key)
			else
				local v117_ = self.cropSensorFruitTypes
				table.insert(v117_, v116_)
			end
		end
	end
end

-- Local values: startTime, modifier, filter, numValues, range, i, min, max, modifier, filter
function NitrogenMap:postLoad(xmlFile, key, baseDirectory, configFileName, mapFilename)
	if self.bitVectorMapNOffsetIsNew then
		local v119_ = getTimeSec()
		local v120_ = DensityMapModifier.new(self.bitVectorMapNOffset, 0, 3)
		local v121_ = PerlinNoiseFilter.new(self.bitVectorMapNOffset, 5.5, 1, 0.5, math.random(0, 1000))
		for v122_ = 1, 8 do
			local v123_ = (v122_ - 1) / 8 * 10000
			local v124_ = v122_ / 8 * 10000
			v121_:setValueCompareParams(DensityValueCompareType.BETWEEN, v123_, v124_)
			v120_:executeSet(v122_ - 1, v121_)
		end
		Logging.devInfo("Initialized Nitrogen Offset Map in %dms", (getTimeSec() - v119_) * 1000)
	else
		local v125_ = DensityMapModifier.new(self.bitVectorMap, self.firstChannel, self.numChannels)
		local v126_ = DensityMapFilter.new(self.bitVectorMap, self.firstChannel, self.numChannels)
		v126_:setValueCompareParams(DensityValueCompareType.GREATER, self.maxValue)
		local v127_ = self.maxValue * 0.75
		v125_:executeSet(math.floor(v127_), v126_)
	end
	return true
end
local function v_u_136_(p128_, p129_, p130_, p131_, p132_, p133_, p134_, p135_)
	return (p128_ + p135_ * 0.5) / p135_ * p134_ + 0.5 - 1, (p129_ + p135_ * 0.5) / p135_ * p134_ + 0.5 - 1, (p130_ + p135_ * 0.5) / p135_ * p134_ + 0.5 - 1, (p131_ + p135_ * 0.5) / p135_ * p134_ + 0.5 - 1, (p132_ + p135_ * 0.5) / p135_ * p134_ + 0.5 - 1, (p133_ + p135_ * 0.5) / p135_ * p134_ + 0.5 - 1
end

-- Local values: functionData, modifier, nFilter, soilFilter, noiseFilter, sprayLevelFilter, sprayLevelFilterInv, maxSprayLevel, sprayMapId, sprayLevelFirstChannel, sprayLevelNumChannels, i, initialValue, j
function NitrogenMap:addSetInitialState(multiModifier, soilBitVector, soilTypeFirstChannel, soilTypeNumChannels, farmlandMask)
	local v143_ = self.densityMapModifiersInitialize
	local v144_ = v143_.modifier
	local v145_ = v143_.nFilter
	local v146_ = v143_.soilFilter
	local v147_ = v143_.noiseFilter
	local v148_ = v143_.sprayLevelFilter
	local v149_ = v143_.sprayLevelFilterInv
	local v150_ = v143_.maxSprayLevel
	if v144_ == nil or (v145_ == nil or (v146_ == nil or (v147_ == nil or (v148_ == nil or (v149_ == nil or v150_ == nil))))) then
		v143_.modifier = DensityMapModifier.new(self.bitVectorMap, self.firstChannel, self.numChannels, g_terrainNode)
		v144_ = v143_.modifier
		v143_.nFilter = DensityMapFilter.new(self.bitVectorMap, self.firstChannel, self.numChannels)
		v145_ = v143_.nFilter
		v145_:setValueCompareParams(DensityValueCompareType.EQUAL, self.maxValue)
		v143_.soilFilter = DensityMapFilter.new(soilBitVector, soilTypeFirstChannel, soilTypeNumChannels)
		v146_ = v143_.soilFilter
		v143_.noiseFilter = DensityMapFilter.new(self.bitVectorMapNoise, 0, self.noiseNumChannels)
		v147_ = v143_.noiseFilter
		local v151_, v152_, v153_ = g_currentMission.fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_LEVEL)
		v143_.sprayLevelFilter = DensityMapFilter.new(v151_, v152_, v153_)
		v148_ = v143_.sprayLevelFilter
		v143_.sprayLevelFilterInv = DensityMapFilter.new(v151_, v152_, v153_)
		v149_ = v143_.sprayLevelFilterInv
		v143_.maxSprayLevel = g_currentMission.fieldGroundSystem:getMaxValue(FieldDensityMap.SPRAY_LEVEL)
		local _ = v143_.maxSprayLevel
	end
	for v154_ = 1, #self.initialValues do
		local v155_ = self.initialValues[v154_]
		v146_:setValueCompareParams(DensityValueCompareType.EQUAL, v155_.soilTypeIndex - 1)
		if farmlandMask == nil then
			multiModifier:addExecuteSet(self.maxValue, v144_, v146_)
		else
			multiModifier:addExecuteSet(self.maxValue, v144_, farmlandMask, v146_)
		end
		for v156_ = 1, self.noiseMaxValue + 1 do
			v147_:setValueCompareParams(DensityValueCompareType.EQUAL, v156_ - 1)
			multiModifier:addExecuteSet(v155_.baseRange[v156_], v144_, v145_, v147_)
		end
	end
	if farmlandMask == nil then
		v148_:setSupersamplingMode(DensityFilterSupersamplingMode.ANY)
		v149_:setSupersamplingMode(DensityFilterSupersamplingMode.ALL)
		v148_:setValueCompareParams(DensityValueCompareType.EQUAL, 1)
		multiModifier:addExecuteAdd(self.initialSprayLevelBonus[1] or 0, v144_, v148_)
		v148_:setValueCompareParams(DensityValueCompareType.EQUAL, 2)
		v149_:setValueCompareParams(DensityValueCompareType.NOTEQUAL, 1)
		multiModifier:addExecuteAdd(self.initialSprayLevelBonus[2] or 0, v144_, v148_, v149_)
	end
end

-- Local values: coverMap, soilMap, functionData, i, fruitRequirement, f, useForageStates, strawChopper, _strawChopperActive, multiModifier, j, soilSettings, multiModifiers, multiModifier, accumulators, numChangedPixels, totalNumPixels, nMapChanged, fruitRequirement, indexStr, accumulator, index, soilSettings
function NitrogenMap:harvestUpdate(filter, fruitIndex, densityMapShape, useMinForageState, strawChopperActive)
	local v163_ = self.coverMap
	local v164_ = self.soilMap
	if v163_ ~= nil and (v163_.bitVectorMap ~= nil and (v164_ ~= nil and v164_.bitVectorMap ~= nil)) then
		local v165_ = self.densityMapModifiersHarvestMulti
		if v165_ == nil then
			v165_ = {
				["modifier"] = DensityMapModifier.new(self.bitVectorMap, self.firstChannel, self.numChannels, g_terrainNode),
				["soilFilter"] = DensityMapFilter.new(v164_.bitVectorMap, v164_.typeFirstChannel, v164_.typeNumChannels),
				["modifierOffsetMeasured"] = DensityMapModifier.new(self.bitVectorMapNOffset, 3, 1, g_terrainNode),
				["multiModifiersByFruitType"] = {}
			}
			for v166_ = 1, #self.fruitRequirements do
				local v167_ = self.fruitRequirements[v166_]
				v165_.multiModifiersByFruitType[v167_.fruitType.index] = {}
				for v168_ = 1, 2 do
					local v169_ = v168_ == 2
					v165_.multiModifiersByFruitType[v167_.fruitType.index][v169_] = {}
					for v170_ = 1, 2 do
						local v171_ = v170_ == 2
						local v172_ = DensityMapMultiModifier.new()
						self:addCropSensorUpdateToMultiModifier(v172_, filter, false)
						for v173_ = 1, #v167_.bySoilType do
							local v174_ = v167_.bySoilType[v173_]
							v165_.soilFilter:setValueCompareParams(DensityValueCompareType.EQUAL, v174_.soilTypeIndex - 1)
							if v169_ then
								v172_:addExecuteGet(tostring(v173_), v165_.modifier, filter, v165_.soilFilter)
								if v174_.reductionForage > 1 then
									v172_:addExecuteAdd(-v174_.reductionForage, v165_.modifier, filter, v165_.soilFilter)
								end
							else
								v172_:addExecuteGet(tostring(v173_), v165_.modifier, filter, v165_.soilFilter)
								if v174_.reduction > 1 then
									v172_:addExecuteAdd(-v174_.reduction, v165_.modifier, filter, v165_.soilFilter)
								end
							end
							if v171_ then
								v172_:addExecuteAdd(self.choppedStrawStateChange, v165_.modifier, filter, v165_.soilFilter)
							end
						end
						v165_.multiModifiersByFruitType[v167_.fruitType.index][v169_][v171_] = v172_
					end
				end
			end
			v165_.accumulators = {}
			v165_.numChangedPixels = {}
			v165_.totalNumPixels = {}
			self.densityMapModifiersHarvestMulti = v165_
		end
		local v175_ = v165_.multiModifiersByFruitType[fruitIndex]
		if v175_ == nil then
			return false
		end
		local v176_ = v175_[useMinForageState]
		if v176_ == nil then
			return false
		end
		local v177_ = v176_[strawChopperActive]
		if v177_ == nil then
			return false
		end
		densityMapShape:applyToModifier(v177_)
		local v178_ = v165_.accumulators
		local v179_ = v165_.numChangedPixels
		local v180_ = v165_.totalNumPixels
		v177_:resetStats()
		v177_:execute(v178_, v179_, v180_)
		local v181_ = false
		local v182_ = self.fruitTypeIndexToFruitRequirement[fruitIndex]
		if v182_ ~= nil then
			for v183_, v184_ in pairs(v178_) do
				if v184_ > 0 then
					local v185_ = tonumber(v183_)
					local v186_ = v182_.bySoilType[v185_]
					self.lastActualValue = v184_ / v179_[v183_]
					self.lastTargetValue = v186_.targetLevel
					self.lastYieldPotential = v186_.yieldPotential
					self.lastIgnoreOverfertilization = v182_.ignoreOverfertilization
					self.lastRegularNValue = v182_.averageTargetLevel
					v181_ = true
				end
			end
		end
		if v181_ then
			self:setMinimapRequiresUpdate(true)
		end
		return v181_
	end
end

-- Local values: functionData, fieldGroundSystem, sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels
function NitrogenMap:getSprayFunctionData()
	local v188_ = self.densityMapModifiersSpray
	if v188_ == nil then
		v188_ = {
			["nModifier"] = DensityMapModifier.new(self.bitVectorMap, self.firstChannel, self.numChannels, g_terrainNode)
		}
		v188_.nModifier:setPolygonRoundingMode(DensityRoundingMode.INCLUSIVE)
		v188_.modifierLock = DensityMapModifier.new(self.bitVectorMapNStateChange, 1, 1, g_terrainNode)
		v188_.modifierLock:setPolygonRoundingMode(DensityRoundingMode.INCLUSIVE)
		v188_.nFilter = DensityMapFilter.new(self.bitVectorMap, self.firstChannel, self.numChannels)
		v188_.nFilter:setValueCompareParams(DensityValueCompareType.GREATER, self.maxVisibleValue)
		v188_.nFilterMax = DensityMapFilter.new(self.bitVectorMap, self.firstChannel, self.numChannels)
		v188_.nFilterMax:setValueCompareParams(DensityValueCompareType.GREATER, self.maxVisibleValue)
		v188_.lockFilter = DensityMapFilter.new(self.bitVectorMapNStateChange, 1, 1)
		v188_.lockFilter:setValueCompareParams(DensityValueCompareType.EQUAL, 0)
		local v189_, v190_, v191_ = g_currentMission.fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_TYPE)
		v188_.sprayTypeFilter = DensityMapFilter.new(v189_, v190_, v191_)
		v188_.sprayTypeFilter:setSupersamplingMode(DensityFilterSupersamplingMode.ALL)
		self.densityMapModifiersSpray = v188_
	end
	return v188_
end

-- Local values: coverMap, soilMap, functionData, nModifier, modifierLock, nFilter, nFilterMax, lockFilter, sprayTypeFilter, sprayTypeDesc
function NitrogenMap:preUpdateNitrogenLevelAtArea(densityMapShape, sprayTypeIndex, delta)
	local v195_ = self.coverMap
	local v196_ = self.soilMap
	if v195_ ~= nil and (v195_.bitVectorMap ~= nil and (v196_ ~= nil and v196_.bitVectorMap ~= nil)) then
		local v197_ = self:getSprayFunctionData()
		local _ = v197_.nModifier
		local v198_ = v197_.modifierLock
		local _ = v197_.nFilter
		local _ = v197_.nFilterMax
		local _ = v197_.lockFilter
		local v199_ = v197_.sprayTypeFilter
		local v200_ = g_sprayTypeManager:getSprayTypeByIndex(sprayTypeIndex)
		if v200_ ~= nil then
			densityMapShape:applyToModifier(v198_)
			v199_:setSupersamplingMode(DensityFilterSupersamplingMode.ANY)
			v199_:setValueCompareParams(DensityValueCompareType.EQUAL, v200_.sprayGroundType)
			v198_:executeSet(0)
			v198_:executeSet(1, v199_)
		end
	end
end

-- Local values: coverMap, soilMap, functionData, nModifier, modifierLock, nFilterMax, lockFilter, sprayTypeDesc, _, numChangedPixels, _
function NitrogenMap:addNitrogenLevelAtArea(densityMapShape, sprayTypeIndex, delta, ignoreLock)
	local v206_ = self.coverMap
	local v207_ = self.soilMap
	if v206_ ~= nil and (v206_.bitVectorMap ~= nil and (v207_ ~= nil and v207_.bitVectorMap ~= nil)) then
		local v208_ = self:getSprayFunctionData()
		local v209_ = v208_.nModifier
		local v210_ = v208_.modifierLock
		local v211_ = v208_.nFilterMax
		local v212_ = v208_.lockFilter
		if ignoreLock then
			v212_ = nil
		end
		if g_sprayTypeManager:getSprayTypeByIndex(sprayTypeIndex) ~= nil then
			densityMapShape:applyToModifier(v209_)
			densityMapShape:applyToModifier(v210_)
			local _, v213_, _ = v209_:executeAddWithStats(delta, v212_)
			v209_:executeSet(self.maxVisibleValue, v211_)
			v210_:executeSet(1, v212_)
			if v213_ > 0 then
				self:setMinimapRequiresUpdate(true)
			end
			return v213_
		end
	end
	return 0
end

-- Local values: coverMap, soilMap, functionData, nModifier, modifierLock, nFilter, lockFilter, sprayTypeDesc, _, numChangedPixels, _
function NitrogenMap:updateNitrogenLevelAtArea(densityMapShape, sprayTypeIndex, targetLevel, ignoreLock)
	local v219_ = self.maxValue
	local v220_ = math.min(targetLevel, v219_)
	local v221_ = self.coverMap
	local v222_ = self.soilMap
	if v221_ ~= nil and (v221_.bitVectorMap ~= nil and (v222_ ~= nil and v222_.bitVectorMap ~= nil)) then
		local v223_ = self:getSprayFunctionData()
		local v224_ = v223_.nModifier
		local v225_ = v223_.modifierLock
		local v226_ = v223_.nFilter
		local v227_ = v223_.lockFilter
		if ignoreLock then
			v227_ = nil
		end
		if g_sprayTypeManager:getSprayTypeByIndex(sprayTypeIndex) ~= nil then
			densityMapShape:applyToModifier(v224_)
			densityMapShape:applyToModifier(v225_)
			v226_:setValueCompareParams(DensityValueCompareType.BETWEEN, 0, v220_ - 1)
			local _, v228_, _ = v224_:executeSetWithStats(v220_, v226_, v227_)
			v225_:executeSet(1, v227_)
			if v228_ > 0 then
				self:setMinimapRequiresUpdate(true)
			end
			return v228_
		end
	end
	return 0
end

-- Local values: coverMap, soilMap, functionData, nModifier, modifierLock, lockFilter, cropSensorFunctionData, modifierMeasured, sprayTypeDesc, _, numChangedPixels, _
function NitrogenMap:setNitrogenLevelAtArea(densityMapShape, sprayTypeIndex, targetLevel, ignoreLock, measured)
	local v235_ = self.maxValue
	local v236_ = math.clamp(targetLevel, 0, v235_)
	local v237_ = self.coverMap
	local v238_ = self.soilMap
	if v237_ ~= nil and (v237_.bitVectorMap ~= nil and (v238_ ~= nil and v238_.bitVectorMap ~= nil)) then
		local v239_ = self:getSprayFunctionData()
		local v240_ = v239_.nModifier
		local v241_ = v239_.modifierLock
		local v242_ = v239_.lockFilter
		if ignoreLock then
			v242_ = nil
		end
		local v243_ = self:getCropSensorFunctionData().modifierMeasured
		if g_sprayTypeManager:getSprayTypeByIndex(sprayTypeIndex) ~= nil then
			densityMapShape:applyToModifier(v240_)
			densityMapShape:applyToModifier(v241_)
			densityMapShape:applyToModifier(v243_)
			local _, v244_, _ = v240_:executeSetWithStats(v236_, v242_)
			v241_:executeSet(1, v242_)
			v243_:executeSet(Utils.getNoNil(measured, false) and 1 or 0, v242_)
			if v244_ > 0 then
				self:setMinimapRequiresUpdate(true)
			end
			return v244_
		end
	end
	return 0
end

-- Upvalues: worldCoordsToLocalCoords
-- Local values: soilMap, modifier, nFilter, fruitFilter, modifierLock, lockFilter, fruitIndices, i, index, desc, _, numPixels, i
function NitrogenMap:updateDestroyCommonArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	-- upvalues: (copy) v_u_136_
	local v252_ = self.soilMap
	if v252_ ~= nil and v252_.bitVectorMap ~= nil then
		local v253_ = self.densityMapModifiersDestroyFruit.modifier
		local v254_ = self.densityMapModifiersDestroyFruit.nFilter
		local v255_ = self.densityMapModifiersDestroyFruit.fruitFilter
		local v256_ = self.densityMapModifiersDestroyFruit.modifierLock
		local v257_ = self.densityMapModifiersDestroyFruit.lockFilter
		local v258_ = self.densityMapModifiersDestroyFruit.fruitIndices
		if v253_ == nil or (v254_ == nil or (v255_ == nil or (v256_ == nil or (v257_ == nil or v258_ == nil)))) then
			self.densityMapModifiersDestroyFruit.modifier = DensityMapModifier.new(self.bitVectorMap, self.firstChannel, self.numChannels, g_terrainNode)
			local v259_ = self.densityMapModifiersDestroyFruit.modifier
			v259_:setPolygonRoundingMode(DensityRoundingMode.INCLUSIVE)
			self.densityMapModifiersDestroyFruit.nFilter = DensityMapFilter.new(self.bitVectorMap, self.firstChannel, self.numChannels)
			self.densityMapModifiersDestroyFruit.nFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, 0, self.maxValue - 1)
			self.densityMapModifiersDestroyFruit.fruitFilter = DensityMapFilter.new(v259_)
			v255_ = self.densityMapModifiersDestroyFruit.fruitFilter
			self.densityMapModifiersDestroyFruit.modifierLock = DensityMapModifier.new(self.bitVectorMapNFruitDestroyMask, 0, 2, g_terrainNode)
			v256_ = self.densityMapModifiersDestroyFruit.modifierLock
			v256_:setPolygonRoundingMode(DensityRoundingMode.INCLUSIVE)
			self.densityMapModifiersDestroyFruit.lockFilter = DensityMapFilter.new(self.bitVectorMapNFruitDestroyMask, 0, 2)
			self.densityMapModifiersDestroyFruit.lockFilter:setValueCompareParams(DensityValueCompareType.EQUAL, 1)
			self.densityMapModifiersDestroyFruit.fruitIndices = {}
			v258_ = self.densityMapModifiersDestroyFruit.fruitIndices
			for v260_ = 1, 15 do
				v258_[v260_] = {
					["index"] = 0,
					["terrainDataPlaneId"] = 0,
					["active"] = false
				}
			end
		end
		local v261_, v262_, v263_, v264_, v265_, v266_ = v_u_136_(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, self.sizeX, g_currentMission.terrainSize)
		v256_:setParallelogramDensityMapCoords(v261_, v262_, v263_, v264_, v265_, v266_, DensityCoordType.POINT_POINT_POINT)
		v258_[1].active = false
		v258_[2].active = false
		v258_[3].active = false
		v258_[4].active = false
		v258_[5].active = false
		v258_[6].active = false
		v258_[7].active = false
		v258_[8].active = false
		v258_[9].active = false
		v258_[10].active = false
		v258_[11].active = false
		v258_[12].active = false
		v258_[13].active = false
		v258_[14].active = false
		v258_[15].active = false
		v256_:executeSet(0)
		for v267_, v268_ in pairs(g_fruitTypeManager:getFruitTypes()) do
			if v268_.weed == nil and v268_.terrainDataPlaneId ~= nil then
				v255_:resetDensityMapAndChannels(v268_.terrainDataPlaneId, v268_.startStateChannel, v268_.numStateChannels)
				v255_:setValueCompareParams(DensityValueCompareType.BETWEEN, 2, v268_.numGrowthStates)
				local _, v269_ = v256_:executeSetWithStats(1, v255_)
				if v269_ > 0 then
					for v270_ = 1, 15 do
						if not v258_[v270_].active then
							v258_[v270_].index = v267_
							v258_[v270_].terrainDataPlaneId = v268_.terrainDataPlaneId
							v258_[v270_].active = true
							break
						end
					end
				end
			end
		end
	end
	return 0
end

-- Upvalues: worldCoordsToLocalCoords
-- Local values: soilMap, modifier, nFilter, fruitFilter, modifierLock, lockFilter, fruitIndices, i, desc
function NitrogenMap:postUpdateDestroyCommonArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	-- upvalues: (copy) v_u_136_
	local v278_ = self.soilMap
	if v278_ ~= nil and v278_.bitVectorMap ~= nil then
		local v279_ = self.densityMapModifiersDestroyFruit.modifier
		local v280_ = self.densityMapModifiersDestroyFruit.nFilter
		local v281_ = self.densityMapModifiersDestroyFruit.fruitFilter
		local v282_ = self.densityMapModifiersDestroyFruit.modifierLock
		local v283_ = self.densityMapModifiersDestroyFruit.lockFilter
		local v284_ = self.densityMapModifiersDestroyFruit.fruitIndices
		local v285_, v286_, v287_, v288_, v289_, v290_ = v_u_136_(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, self.sizeX, g_currentMission.terrainSize)
		v279_:setParallelogramDensityMapCoords(v285_, v286_, v287_, v288_, v289_, v290_, DensityCoordType.POINT_POINT_POINT)
		for v291_ = 1, 15 do
			if not v284_[v291_].active then
				break
			end
			local v292_ = g_fruitTypeManager:getFruitTypeByIndex(v284_[v291_].index)
			v281_:resetDensityMapAndChannels(v284_[v291_].terrainDataPlaneId, v292_.startStateChannel, v292_.numStateChannels)
			v281_:setValueCompareParams(DensityValueCompareType.BETWEEN, 2, v292_.numGrowthStates)
			v282_:executeSet(2, v281_)
		end
		v280_:setValueCompareParams(DensityValueCompareType.EQUAL, self.maxValue - self.catchCropsStateChange)
		v279_:executeSet(self.maxValue, v283_, v280_)
		v280_:setValueCompareParams(DensityValueCompareType.BETWEEN, 0, self.maxValue - self.catchCropsStateChange)
		v279_:executeAdd(self.catchCropsStateChange, v283_, v280_)
	end
	return 0
end

-- Local values: modifier, nFilter, maskModifier, maskFilter, sprayTypeFilter, fieldGroundSystem, sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels
function NitrogenMap:preUpdateStrawChopperArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, strawGroundType)
	local v301_ = self.densityMapModifiersStrawChopper.modifier
	local v302_ = self.densityMapModifiersStrawChopper.nFilter
	local v303_ = self.densityMapModifiersStrawChopper.maskModifier
	local v304_ = self.densityMapModifiersStrawChopper.maskFilter
	local v305_ = self.densityMapModifiersStrawChopper.sprayTypeFilter
	if v301_ == nil or (v302_ == nil or (v303_ == nil or (v304_ == nil or v305_ == nil))) then
		self.densityMapModifiersStrawChopper.modifier = DensityMapModifier.new(self.bitVectorMap, self.firstChannel, self.numChannels, g_terrainNode)
		self.densityMapModifiersStrawChopper.nFilter = DensityMapFilter.new(self.bitVectorMap, self.firstChannel, self.numChannels)
		v302_ = self.densityMapModifiersStrawChopper.nFilter
		self.densityMapModifiersStrawChopper.maskModifier = DensityMapModifier.new(self.bitVectorMapChoppedStrawMask, 0, 1, g_terrainNode)
		v303_ = self.densityMapModifiersStrawChopper.maskModifier
		self.densityMapModifiersStrawChopper.maskFilter = DensityMapFilter.new(self.bitVectorMapChoppedStrawMask, 0, 1)
		self.densityMapModifiersStrawChopper.maskFilter:setValueCompareParams(DensityValueCompareType.EQUAL, 1)
		local v306_, v307_, v308_ = g_currentMission.fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_TYPE)
		self.densityMapModifiersStrawChopper.sprayTypeFilter = DensityMapFilter.new(v306_, v307_, v308_)
		v305_ = self.densityMapModifiersStrawChopper.sprayTypeFilter
		v305_:setValueCompareParams(DensityValueCompareType.NOTEQUAL, strawGroundType)
	end
	v303_:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	v303_:executeSet(1)
	v305_:setValueCompareParams(DensityValueCompareType.EQUAL, strawGroundType)
	v303_:executeSet(0, v305_)
	v302_:setValueCompareParams(DensityValueCompareType.GREATER, self.maxValue - self.choppedStrawStateChange)
	v303_:executeSet(0, v302_)
end

-- Local values: modifier, maskFilter, sprayTypeFilter
function NitrogenMap:postUpdateStrawChopperArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, strawGroundType)
	local v317_ = self.densityMapModifiersStrawChopper.modifier
	local v318_ = self.densityMapModifiersStrawChopper.maskFilter
	local v319_ = self.densityMapModifiersStrawChopper.sprayTypeFilter
	v319_:setValueCompareParams(DensityValueCompareType.EQUAL, strawGroundType)
	v317_:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	v317_:executeAdd(self.choppedStrawStateChange, v318_, v319_)
end

-- Local values: functionData, multiModifier, changeArea, _
function NitrogenMap:updateCropSensorArea(densityMapShape)
	local v322_ = self:getCropSensorFunctionData()
	local v323_ = v322_.multiModifier
	if v323_ == nil then
		v323_ = DensityMapMultiModifier.new()
		v322_.multiModifier = v323_
		self:addCropSensorUpdateToMultiModifier(v323_, nil, true)
	end
	densityMapShape:applyToModifier(v323_)
	v323_:resetStats()
	local v324_, _ = v323_:execute()
	if v324_ > 0 then
		self:setMinimapRequiresUpdate(true)
	end
end

-- Local values: functionData
function NitrogenMap:getCropSensorFunctionData()
	local v326_ = self.densityMapModifiersCropSensorMulti
	if v326_ == nil then
		v326_ = {
			["modifierMeasured"] = DensityMapModifier.new(self.bitVectorMapNOffset, 3, 1, g_terrainNode),
			["measuredFilter"] = DensityMapFilter.new(self.bitVectorMapNOffset, 3, 1)
		}
		v326_.measuredFilter:setValueCompareParams(DensityValueCompareType.EQUAL, 0)
		v326_.nModifier = DensityMapModifier.new(self.bitVectorMap, self.firstChannel, self.numChannels, g_terrainNode)
		v326_.nFilter = DensityMapFilter.new(self.bitVectorMap, self.firstChannel, self.numChannels)
		v326_.nFilter:setValueCompareParams(DensityValueCompareType.GREATER, self.maxValue)
		v326_.offsetFilter = DensityMapFilter.new(self.bitVectorMapNOffset, 0, 3)
		v326_.tempFruitModifier = DensityMapModifier.new(self.bitVectorMapNFruitFilterMask, 0, 1, g_terrainNode)
		v326_.tempFruitModifier:setPolygonRoundingMode(DensityRoundingMode.INCLUSIVE)
		v326_.tempFruitFilter = DensityMapFilter.new(self.bitVectorMapNFruitFilterMask, 0, 1)
		v326_.tempFruitFilter:setValueCompareParams(DensityValueCompareType.EQUAL, 1)
		v326_.fruitFilter = DensityMapFilter.new(self.bitVectorMapNFruitFilterMask, 0, 1)
		v326_.fruitFilter:setValueCompareParams(DensityValueCompareType.EQUAL, 1)
		v326_.multiModifiers = {}
		self.densityMapModifiersCropSensorMulti = v326_
	end
	return v326_
end

-- Local values: functionData, fruitTypeIndex, fruitType, offsetIndex, nOffset
function NitrogenMap:addCropSensorUpdateToMultiModifier(multiModifier, changeFilter, setMeasured)
	local v331_ = self:getCropSensorFunctionData()
	multiModifier:addExecuteSet(0, v331_.tempFruitModifier)
	if changeFilter == nil then
		for v332_ = 1, #self.cropSensorFruitTypes do
			local v333_ = self.cropSensorFruitTypes[v332_]
			if v333_.terrainDataPlaneId ~= nil then
				v331_.fruitFilter:resetDensityMapAndChannels(v333_.terrainDataPlaneId, v333_.startStateChannel, v333_.numStateChannels)
				v331_.fruitFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, 1, v333_.minHarvestingGrowthState)
				multiModifier:addExecuteSet(1, v331_.tempFruitModifier, v331_.fruitFilter)
			end
		end
	else
		multiModifier:addExecuteSet(1, v331_.tempFruitModifier, changeFilter)
	end
	v331_.measuredFilter:setValueCompareParams(DensityValueCompareType.EQUAL, 1)
	multiModifier:addExecuteSet(0, v331_.tempFruitModifier, v331_.measuredFilter)
	for v334_ = 1, #self.nOffsetIndexToOffset do
		local v335_ = self.nOffsetIndexToOffset[v334_]
		v331_.offsetFilter:setValueCompareParams(DensityValueCompareType.EQUAL, v334_ - 1)
		local v336_ = v331_.nFilter
		local v337_ = DensityValueCompareType.BETWEEN
		local v338_ = 1 - v335_
		v336_:setValueCompareParams(v337_, math.max(v338_, 1), self.maxValue - v335_)
		multiModifier:addExecuteAddWithStats("", v335_, v331_.nModifier, v331_.nFilter, v331_.offsetFilter, v331_.tempFruitFilter)
	end
	if setMeasured then
		v331_.measuredFilter:setValueCompareParams(DensityValueCompareType.EQUAL, 0)
		multiModifier:addExecuteSet(1, v331_.modifierMeasured, v331_.measuredFilter, v331_.tempFruitFilter)
	end
end

function NitrogenMap:getLevelAtWorldPos(x, z)
	local v342_ = MathUtil.round((x + g_currentMission.terrainSize * 0.5) / g_currentMission.terrainSize * self.sizeX + 0.5) - 1
	local v343_ = MathUtil.round((z + g_currentMission.terrainSize * 0.5) / g_currentMission.terrainSize * self.sizeY + 0.5) - 1
	return not self.coverMap:getIsUncoveredAtPos(v342_, v343_) and 0 or getBitVectorMapPoint(self.bitVectorMap, v342_, v343_, self.firstChannel, self.numChannels)
end

-- Local values: coverMap, soilMap, modifierLock, sprayTypeFilter, coverMaskFilter, fieldGroundSystem, sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels, sprayTypeDesc, _, numPixels, _
function NitrogenMap:getIsLockedAtWorldPos(wx, wz, sprayTypeIndex)
	local v348_ = self.coverMap
	local v349_ = self.soilMap
	if v348_ ~= nil and (v348_.bitVectorMap ~= nil and (v349_ ~= nil and v349_.bitVectorMap ~= nil)) then
		local v350_ = self.densityMapModifiersLockedState.modifierLock
		local v351_ = self.densityMapModifiersLockedState.sprayTypeFilter
		local v352_ = self.densityMapModifiersLockedState.coverMaskFilter
		if v350_ == nil or (v351_ == nil or v352_ == nil) then
			self.densityMapModifiersLockedState.modifierLock = DensityMapModifier.new(self.bitVectorMapNStateChange, 1, 1, g_terrainNode)
			v350_ = self.densityMapModifiersLockedState.modifierLock
			v350_:setPolygonRoundingMode(DensityRoundingMode.INCLUSIVE)
			local v353_, v354_, v355_ = g_currentMission.fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_TYPE)
			self.densityMapModifiersLockedState.sprayTypeFilter = DensityMapFilter.new(v353_, v354_, v355_)
			v351_ = self.densityMapModifiersLockedState.sprayTypeFilter
			v351_:setSupersamplingMode(DensityFilterSupersamplingMode.ALL)
			self.densityMapModifiersLockedState.coverMaskFilter = DensityMapFilter.new(v348_.bitVectorMap, v348_.firstChannel, v348_.numChannels)
			v352_ = self.densityMapModifiersLockedState.coverMaskFilter
			v352_:setValueCompareParams(DensityValueCompareType.GREATER, 0)
		end
		local v356_ = g_sprayTypeManager:getSprayTypeByIndex(sprayTypeIndex)
		if v356_ ~= nil then
			v350_:setParallelogramWorldCoords(wx, wz, wx + 0.001, wz, wx, wz + 0.001, DensityCoordType.POINT_POINT_POINT)
			v351_:setValueCompareParams(DensityValueCompareType.NOTEQUAL, v356_.sprayGroundType)
			local _, v357_, _ = v350_:executeGet(v352_, v351_)
			return v357_ == 0
		end
	end
	return false
end

-- Local values: distance, foundUncovered, i
function NitrogenMap:getNextValidDetectionPoint(wx, wz, dirX, dirZ, maxDistance, sprayTypeIndex)
	local v365_, v366_ = ValueMap.roundToPixelCenter(wx, wz, g_currentMission.terrainSize, self.sizeX)
	local v367_, v368_
	if math.abs(dirX) > math.abs(dirZ) then
		v367_ = math.sign(dirX)
		v368_ = 0
	else
		v368_ = math.sign(dirZ)
		v367_ = 0
	end
	local v369_ = g_currentMission.terrainSize / self.sizeX
	local v370_ = maxDistance / v369_
	local v371_ = false
	for _ = 1, math.ceil(v370_) do
		if self.coverMap:getIsUncoveredAtPos(v365_, v366_, true) then
			if not self:getIsLockedAtWorldPos(v365_, v366_, sprayTypeIndex) then
				return v365_, v366_, true
			end
			v371_ = true
		end
		v365_ = v365_ + v367_ * v369_
		v366_ = v366_ + v368_ * v369_
	end
	return nil, nil, v371_
end

-- Local values: soilMap, modifierFruit, fieldGroundSystem, sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels, lx, lz, soilTypeIndex, i, applicationRate, j, rateBySoilType, halfSize, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, foundFruitTypeIndex, index, desc, acc, numPixels, _, state, allowCutState, i, fruitRequirement, i, j, soilSettings
function NitrogenMap:getTargetLevelAtWorldPos(x, z, size, forcedFruitType, fillType, nLevel, defaultNitrogenRequirementIndex)
	local v380_ = self.soilMap
	if v380_ ~= nil and v380_.bitVectorMap ~= nil then
		local v381_ = size or 1
		local v382_ = self.densityMapModifiersFruitCheck.modifierFruit
		if v382_ == nil then
			local v383_, v384_, v385_ = g_currentMission.fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_TYPE)
			self.densityMapModifiersFruitCheck.modifierFruit = DensityMapModifier.new(v383_, v384_, v385_)
			v382_ = self.densityMapModifiersFruitCheck.modifierFruit
		end
		local v386_ = (x + g_currentMission.terrainSize * 0.5) / g_currentMission.terrainSize * v380_.sizeX
		local v387_ = (z + g_currentMission.terrainSize * 0.5) / g_currentMission.terrainSize * v380_.sizeY
		if self.coverMap:getIsUncoveredAtPos(v386_, v387_) then
			local v388_ = getBitVectorMapPoint(v380_.bitVectorMap, v386_, v387_, v380_.typeFirstChannel, v380_.typeNumChannels) + 1
			if fillType ~= nil and fillType ~= FillType.UNKNOWN then
				for v389_ = 1, #self.applicationRates do
					local v390_ = self.applicationRates[v389_]
					if v390_.fillTypeIndex == fillType and not v390_.autoAdjustToFruit then
						for v391_ = 1, #v390_.ratesBySoilType do
							local v392_ = v390_.ratesBySoilType[v391_]
							if v392_.soilTypeIndex == v388_ then
								return (nLevel or 0) + v392_.rate, v388_, FruitType.UNKNOWN
							end
						end
					end
				end
			end
			local v393_ = v381_ * 0.5
			v382_:setParallelogramWorldCoords(x + v393_, z + v393_, x - v393_, z + v393_, x + v393_, z - v393_, DensityCoordType.POINT_POINT_POINT)
			if forcedFruitType == nil then
				for v394_, v395_ in pairs(g_fruitTypeManager:getFruitTypes()) do
					if v395_.weed == nil and v395_.terrainDataPlaneId ~= nil then
						v382_:resetDensityMapAndChannels(v395_.terrainDataPlaneId, v395_.startStateChannel, v395_.numStateChannels)
						local v396_, v397_, _ = v382_:executeGet()
						if v397_ > 0 then
							local v398_ = v396_ / v397_
							local v399_ = math.floor(v398_)
							local v400_ = false
							for v401_ = 1, #self.fruitRequirements do
								if self.fruitRequirements[v401_].fruitType.index == v394_ then
									v400_ = self.fruitRequirements[v401_].alwaysAllowFertilization
								end
							end
							if v399_ >= 0 and v399_ ~= v395_.cutState or v400_ then
								forcedFruitType = v394_
								break
							end
						end
					end
				end
			end
			local v402_ = nil
			if forcedFruitType == nil then
				v402_ = self.fruitRequirements[defaultNitrogenRequirementIndex or 1] or self.fruitRequirements[1]
			else
				for v403_ = 1, #self.fruitRequirements do
					if self.fruitRequirements[v403_].fruitType.index == forcedFruitType then
						v402_ = self.fruitRequirements[v403_]
						break
					end
				end
			end
			if v402_ ~= nil then
				for v404_ = 1, #v402_.bySoilType do
					local v405_ = v402_.bySoilType[v404_]
					if v405_.soilTypeIndex == v388_ then
						return v405_.targetLevel, v388_, forcedFruitType
					end
				end
			end
			return 0, v388_, FruitType.UNKNOWN
		end
	end
	return 0, 0, FruitType.UNKNOWN
end

-- Local values: sprayTypeDesc, i, applicationRate, j, rateBySoilType, targetLevel
function NitrogenMap:getNitrogenApplicationRate(currentLevel, fruitTypeIndex, soilTypeIndex, sprayTypeIndex)
	local v411_ = g_sprayTypeManager:getSprayTypeByIndex(sprayTypeIndex)
	if v411_ == nil then
		return 0, false
	else
		for v412_ = 1, #self.applicationRates do
			local v413_ = self.applicationRates[v412_]
			if v413_.fillTypeIndex == v411_.fillType.index and not v413_.autoAdjustToFruit then
				for v414_ = 1, #v413_.ratesBySoilType do
					local v415_ = v413_.ratesBySoilType[v414_]
					if v415_.soilTypeIndex == soilTypeIndex then
						return v415_.rate, false
					end
				end
			end
		end
		local v416_ = self:getNitrogenTargetLevel(fruitTypeIndex, soilTypeIndex)
		if v416_ == nil then
			return 0, false
		else
			return v416_ - currentLevel, true
		end
	end
end

-- Local values: fruitRequirement, i, j, soilSettings
function NitrogenMap:getNitrogenTargetLevel(fruitTypeIndex, soilTypeIndex)
	local v420_ = nil
	for v421_ = 1, #self.fruitRequirements do
		if self.fruitRequirements[v421_].fruitType.index == fruitTypeIndex then
			v420_ = self.fruitRequirements[v421_]
			break
		end
	end
	if v420_ ~= nil then
		for v422_ = 1, #v420_.bySoilType do
			local v423_ = v420_.bySoilType[v422_]
			if v423_.soilTypeIndex == soilTypeIndex then
				return v423_.targetLevel, nil
			end
		end
	end
	return nil, nil
end

-- Local values: isLocked, offsetValue, nOffsetValue
function NitrogenMap:getNOffsetDataAtWorldPos(x, z)
	local v427_ = (x + g_currentMission.terrainSize * 0.5) / g_currentMission.terrainSize * self.sizeX
	local v428_ = (z + g_currentMission.terrainSize * 0.5) / g_currentMission.terrainSize * self.sizeY
	if not self.coverMap:getIsUncoveredAtPos(v427_, v428_) then
		return false, -1
	end
	local v429_ = getBitVectorMapPoint(self.bitVectorMapNOffset, v427_, v428_, 3, 1) == 1
	local v430_ = getBitVectorMapPoint(self.bitVectorMapNOffset, v427_, v428_, 0, 3)
	return v429_, self.nOffsetIndexToOffset[v430_ + 1] * self.amountPerState
end

-- Local values: requiredLitersPerHa, _, nitrogenProportion, litersPerUpdate, regularUsage, i, fruitRequirement, _, internalActualNitrogen, requiredLitersPerHaReg, _, _, i, applicationRate, requiredLitersPerHaReg, _, _
function NitrogenMap:getFertilizerUsage(workingWidth, lastSpeed, statesChanged, fillTypeIndex, dt, sprayAmountAutoMode, nApplyAutoModeFruitType, actualNitrogen, nitrogenUsageLevelOffset)
	local v440_, _, v441_ = self:getFertilizerUsageByStateChange(statesChanged, fillTypeIndex, nitrogenUsageLevelOffset or 0)
	local v442_ = v440_ * (lastSpeed / 3600) / (10000 / workingWidth) * dt
	local v443_ = 0
	if v440_ > 0 then
		if nApplyAutoModeFruitType == nil or nApplyAutoModeFruitType == FruitType.UNKNOWN then
			for v444_ = 1, #self.applicationRates do
				local v445_ = self.applicationRates[v444_]
				if v445_.fillTypeIndex == fillTypeIndex then
					local v446_, _, _ = self:getFertilizerUsageByNitrogenAmount(v445_.regularRate, fillTypeIndex)
					v443_ = v446_ * (lastSpeed / 3600) / (10000 / workingWidth) * dt
				end
			end
		else
			for v447_ = 1, #self.fruitRequirements do
				local v448_ = self.fruitRequirements[v447_]
				if v448_.fruitType.index == nApplyAutoModeFruitType then
					local _, v449_ = self:getNearestNitrogenValueFromValue(actualNitrogen)
					local v450_ = v448_.averageTargetLevel - v449_
					local v451_, _, _ = self:getFertilizerUsageByStateChange(math.max(v450_, 0), fillTypeIndex)
					v443_ = v451_ * (lastSpeed / 3600) / (10000 / workingWidth) * dt
				end
			end
		end
	end
	return v442_, v440_, v443_, v441_
end

-- Local values: requiredNAmount, nAmountOffset
function NitrogenMap:getFertilizerUsageByStateChange(statesChanged, fillTypeIndex, nitrogenUsageLevelOffset)
	return self:getFertilizerUsageByNitrogenAmount(statesChanged * self.amountPerState, fillTypeIndex, (nitrogenUsageLevelOffset or 0) * self.amountPerState)
end

-- Local values: requiredLitersPerHa, requiredMassPerHa, nitrogenProportion, i, nAmount, fillTypeDesc, massPerLiter, nOffsetPct, realNAmount
function NitrogenMap:getFertilizerUsageByNitrogenAmount(nitrogenAmount, fillTypeIndex, nAmountOffset)
	local v460_ = 0
	local v461_ = 0
	local v462_ = 0
	for v463_ = 1, #self.fertilizerUsage.nAmounts do
		local v464_ = self.fertilizerUsage.nAmounts[v463_]
		if v464_.fillTypeIndex == fillTypeIndex then
			local v465_ = g_fillTypeManager:getFillTypeByIndex(fillTypeIndex)
			local v466_ = v465_.massPerLiter / FillTypeManager.MASS_SCALE
			if fillTypeIndex == FillType.LIQUIDMANURE then
				local v467_ = (nitrogenAmount <= 0 or nAmountOffset == nil) and 1 or (nitrogenAmount + nAmountOffset) / nitrogenAmount
				v460_ = nitrogenAmount / (v464_.amount * v467_)
				v461_ = v460_ * v466_
				v462_ = v464_.amount * v467_
			elseif v465_ ~= nil then
				v460_ = nitrogenAmount / (v466_ * 1000) / v464_.amount
				v461_ = v460_ * v466_
				v462_ = v464_.amount
			end
		end
	end
	return v460_, v461_, v462_
end

function NitrogenMap:getNextFruitRequirementIndex(index)
	local v470_ = index + 1
	local v471_ = #self.fruitRequirements < v470_ and 1 or v470_
	if self.fruitRequirements[v471_] == nil or self.fruitRequirements[v471_].availableAsDefaultRate then
		return v471_
	else
		return self:getNextFruitRequirementIndex(v471_)
	end
end

function NitrogenMap:getFruitTypeIndexByFruitRequirementIndex(index)
	if self.fruitRequirements[index] == nil then
		return nil
	else
		return self.fruitRequirements[index].fruitType.index
	end
end

-- Local values: i, fruitRequirement
function NitrogenMap:getFruitTypeRequirementRequiresDefaultMode(index)
	for v476_ = 1, #self.fruitRequirements do
		local v477_ = self.fruitRequirements[v476_]
		if v477_.fruitType.index == index and v477_.requiresDefaultMode then
			return true
		end
	end
	return false
end

-- Local values: i, nAmount
function NitrogenMap:getNitrogenAmountFromFillType(fillTypeIndex)
	for v480_ = 1, #self.fertilizerUsage.nAmounts do
		local v481_ = self.fertilizerUsage.nAmounts[v480_]
		if v481_.fillTypeIndex == fillTypeIndex then
			return v481_.amount
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
	if self.nitrogenValues == nil or #self.nitrogenValues <= 0 then
		return 0, 1, 0
	else
		return self.nitrogenValues[1].realValue, self.nitrogenValues[#self.nitrogenValues].realValue, #self.nitrogenValues
	end
end

-- Local values: i, nitrogenValue
function NitrogenMap:getNitrogenValueFromInternalValue(internal)
	for v490_ = 1, #self.nitrogenValues do
		local v491_ = self.nitrogenValues[v490_]
		if v491_.value == math.floor(internal) then
			return v491_.realValue
		end
	end
	return 0
end

-- Local values: minDifference, minValue, minInternal, i, nValue, difference
function NitrogenMap:getNearestNitrogenValueFromValue(value)
	local v494_ = 1000
	local v495_ = 0
	local v496_ = 0
	for v497_ = 1, #self.nitrogenValues do
		local v498_ = self.nitrogenValues[v497_].realValue
		local v499_ = value - v498_
		local v500_ = math.abs(v499_)
		if v500_ < v494_ then
			v496_ = self.nitrogenValues[v497_].value
			v495_ = v498_
			v494_ = v500_
		end
	end
	return v495_, v496_
end

-- Local values: actual, target, yieldPotential, ignoreOverfertilization, regularNLevel
function NitrogenMap:updateLastNitrogenValues()
	local v502_ = self.lastActualValue
	local v503_ = self.lastTargetValue
	local v504_ = self.lastYieldPotential
	local v505_ = self.lastIgnoreOverfertilization
	local v506_ = self.lastRegularNValue
	self.lastActualValue = -1
	self.lastTargetValue = -1
	self.lastYieldPotential = -1
	self.lastIgnoreOverfertilization = nil
	self.lastRegularNValue = -1
	return v502_, v503_, v504_, v506_, v505_
end

function NitrogenMap:getYieldFactorByLevelDifference(difference, ignoreOverfertilization)
	local v510_ = difference > 0 and ignoreOverfertilization == true and 0 or difference
	return self.yieldCurve:get(v510_)
end

-- Local values: coverMap, coverMask, i, nitrogenValue, color, inGameMenuMapFrame, sprayMapId, sprayLevelFirstChannel, sprayLevelNumChannels, mapOverlayGenerator, colors, maxSprayLevel, level, color
function NitrogenMap:buildOverlay(overlay, filter, isColorBlindMode, isMinimap)
	resetDensityMapVisualizationOverlay(overlay)
	setOverlayColor(overlay, 1, 1, 1, 1)
	if isMinimap and self.minimapMissionState then
		if self.pfModule.inGameMenuMapFrameExtension.inGameMenuMapFrame ~= nil then
			local v516_, v517_, v518_ = g_currentMission.fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_LEVEL)
			if g_currentMission.mapOverlayGenerator ~= nil then
				local v519_ = self.fertilizerColors[isColorBlindMode]
				for v520_ = 1, bit32.lshift(1, v518_) - 1 do
					local v521_ = #v519_
					local v522_ = v519_[math.min(v520_, v521_)]
					setDensityMapVisualizationOverlayStateColor(overlay, v516_, 0, 0, v517_, v518_, v520_, v522_[1], v522_[2], v522_[3])
				end
			end
		end
	else
		local v523_ = self.coverMap
		if v523_ ~= nil then
			local v524_ = 2 ^ (v523_.numChannels - 1) - 1
			local v525_ = bit32.lshift(v524_, 1)
			for v526_ = 1, #self.nitrogenValues do
				local v527_ = self.nitrogenValues[v526_]
				if filter[v527_.filterIndex] then
					local v528_ = v527_.color
					if isColorBlindMode then
						v528_ = v527_.colorBlind
					end
					if v528_ ~= nil then
						setDensityMapVisualizationOverlayStateColor(overlay, self.bitVectorMap, v523_.bitVectorMap, v525_, self.firstChannel, self.numChannels, v527_.value, v528_[1], v528_[2], v528_[3])
					end
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

-- Local values: i, nitrogenValue, nValueToDisplay, nValueToDisplay
function NitrogenMap:getDisplayValues()
	if self.valuesToDisplay == nil then
		self.valuesToDisplay = {}
		for v530_ = 1, #self.nitrogenValues do
			local v531_ = self.nitrogenValues[v530_]
			if v531_.showOnHud then
				local v532_ = {
					["colors"] = {}
				}
				v532_.colors[true] = { v531_.colorBlind }
				v532_.colors[false] = { v531_.color }
				v532_.description = string.format("%d kg/ha", v531_.realValue)
				local v533_ = self.valuesToDisplay
				table.insert(v533_, v532_)
			end
		end
		local v534_ = {
			["colors"] = {}
		}
		v534_.colors[true] = {
			{ 0, 0, 0 }
		}
		v534_.colors[false] = {
			{ 0, 0, 0 }
		}
		v534_.description = self.outdatedLabel
		local v535_ = self.valuesToDisplay
		table.insert(v535_, v534_)
	end
	return self.valuesToDisplay
end

-- Local values: i
function NitrogenMap:getValueFilter()
	if self.valueFilter == nil or self.valueFilterEnabled == nil then
		self.valueFilter = {}
		self.valueFilterEnabled = {}
		for v537_ = 1, self.numVisualValues + 1 do
			local v538_ = self.valueFilter
			table.insert(v538_, true)
			local v539_ = self.valueFilterEnabled
			local v540_ = v537_ <= self.numVisualValues
			table.insert(v539_, v540_)
		end
	end
	return self.valueFilter, self.valueFilterEnabled
end

function NitrogenMap:getMinimapZoomFactor()
	return 3
end

-- Local values: name
function NitrogenMap:collectFieldInfos(fieldInfoDisplayExtension)
	fieldInfoDisplayExtension:addFieldInfo(g_i18n:getText("fieldInfo_nValue", NitrogenMap.MOD_NAME), self, self.updateFieldInfoDisplay, 3, self.getFieldInfoYieldChange)
end

function NitrogenMap:getAllowCoverage()
	return true
end

function NitrogenMap:getHelpLinePage()
	return 5
end

-- Local values: nLevel, soilTypeIndex, fruitTypeIndex, _, fruitRequirement, fruitDesc, soilSettings, _, _soilSettings, actualLevelReal, targetLevelReal, color, additionalText, showWarning, levelDifference, li, levelDifferenceColor, seedRateYieldFactorCurrent, seedRateYieldFactorBest, seedRateMap, seedRateRaw, fillType
function NitrogenMap:updateFieldInfoDisplay(fieldInfo, x, z, isColorBlindMode)
	fieldInfo.yieldPotential = nil
	fieldInfo.yieldPotentialToHa = nil
	fieldInfo.yieldPotentialFactor = nil
	fieldInfo.yieldPotentialFactorBest = nil
	local v548_ = self:getLevelAtWorldPos(x, z)
	local v549_ = self.soilMap:getTypeIndexAtWorldPos(x, z)
	local v550_, _ = FSDensityMapUtil.getFruitTypeIndexAtWorldPos(x, z)
	if v550_ ~= nil then
		local v551_ = self.fruitTypeIndexToFruitRequirement[v550_]
		if v551_ ~= nil then
			local v552_ = v551_.fruitType
			if v552_ ~= nil and (v552_.terrainDataPlaneId ~= nil and v552_.terrainDataPlaneId ~= 0) then
				local v553_ = nil
				for _, v554_ in ipairs(v551_.bySoilType) do
					if v554_.soilTypeIndex == v549_ then
						v553_ = v554_
						break
					end
				end
				if v553_ ~= nil then
					local v555_ = self:getNitrogenValueFromInternalValue(v548_)
					local v556_ = self:getNitrogenValueFromInternalValue(v553_.targetLevel)
					local v557_ = nil
					local v558_ = nil
					local v559_ = nil
					local v560_ = v553_.targetLevel - v548_
					if v551_.ignoreOverfertilization then
						v560_ = math.max(v560_, 0)
					end
					local v561_ = v556_ == 0 and 0 or v560_
					local v562_ = math.abs(v561_)
					for v563_ = 1, #self.levelDifferenceColors do
						local v564_ = self.levelDifferenceColors[v563_]
						if v564_.levelDifference <= v562_ then
							if isColorBlindMode then
								v557_ = v564_.colorBlind
							else
								v557_ = v564_.color
							end
							v558_ = v564_.additionalText
							v559_ = v564_.showWarning
						end
					end
					local v565_ = 1
					local v566_ = 1
					local v567_ = self.seedRateMap
					if v567_ ~= nil then
						local v568_ = v567_:getSeedRateAtWorldPosition(x, z)
						if v568_ ~= nil then
							v565_, v566_ = v567_:getSeedRateYieldFactor(v568_, v550_, v549_)
						end
					end
					fieldInfo.yieldPotentialFactor = v565_
					fieldInfo.yieldPotentialFactorBest = v566_
					fieldInfo.yieldPotential = v553_.yieldPotential
					fieldInfo.nFactor = self:getYieldFactorByLevelDifference(v548_ - v553_.targetLevel, v551_.ignoreOverfertilization)
					local v569_ = g_fruitTypeManager:getFillTypeByFruitTypeIndex(v552_.index)
					if v569_ ~= nil then
						fieldInfo.yieldPotentialToHa = v553_.yieldPotential * v552_.literPerSqm * 10000 * (v569_.massPerLiter / FillTypeManager.MASS_SCALE) * 2
					end
					return string.format("%d / %d kg/ha", v555_, v556_), v557_, v558_, v559_
				end
			end
		end
	end
	if v548_ == 0 then
		return nil
	else
		return string.format("%d kg/ha", self:getNitrogenValueFromInternalValue(v548_))
	end
end

function NitrogenMap:getFieldInfoYieldChange(fieldInfo)
	return fieldInfo.nFactor or 0, 0.5, fieldInfo.yieldPotential, fieldInfo.yieldPotentialToHa, fieldInfo.yieldPotentialFactor, fieldInfo.yieldPotentialFactorBest
end

-- Local values: minTime, maxTime, i, keyframe, value, x
function NitrogenMap:drawYieldDebug(nActualValue, nTargetValue)
	if self.debugGraph == nil then
		self.debugGraph = Graph.new(#self.yieldCurve.keyframes, 0.2, 0.05, 0.2, 0.15, 0, 100, false, "%", Graph.STYLE_LINES)
		self.debugGraph:setHorizontalLine(10, true, 1, 1, 1, 1)
		self.debugGraph:setVerticalLine(0.1, false, 1, 1, 1, 1)
		self.debugGraph:setColor(0, 1, 0, 1)
	end
	local v574_ = math.huge
	local v575_ = -math.huge
	for v576_ = 1, #self.yieldCurve.keyframes do
		local v577_ = self.yieldCurve.keyframes[v576_]
		local v578_ = self.yieldCurve:get(v577_.time)
		self.debugGraph:setValue(v576_, v578_ * 100)
		local v579_ = v577_.time
		v574_ = math.min(v579_, v574_)
		local v580_ = v577_.time
		v575_ = math.max(v580_, v575_)
	end
	self.debugGraph:draw()
	if v574_ ~= math.huge then
		local v581_ = self.debugGraph.left + MathUtil.inverseLerp(v574_, v575_, nActualValue - nTargetValue) * self.debugGraph.width
		setOverlayColor(self.debugGraph.overlayHLine, 1, 0, 0, 1)
		renderOverlay(self.debugGraph.overlayHLine, v581_, self.debugGraph.bottom, g_pixelSizeX, self.debugGraph.height)
		setOverlayColor(self.debugGraph.overlayHLine, 1, 1, 1, 1)
	end
end

-- Local values: field, area, _, targetLevel
function NitrogenMap:debugSetNitrogenLevel(fieldId, nitrogenLevel, measured)
	local v586_ = tonumber(fieldId)
	local v587_ = tonumber(nitrogenLevel)
	local v588_ = measured == "true"
	if v586_ == nil or v587_ == nil then
		Logging.error("NitrogenMap: Invalid parameters. Usage: pfNitrogenSetLevel <fieldId> <nitrogenLevel> [measured:true|false]")
	else
		local v589_ = g_fieldManager:getFieldById((tonumber(v586_)))
		if v589_ ~= nil and v589_.getDensityMapPolygon ~= nil then
			local v590_ = v589_:getDensityMapPolygon()
			local _, v591_ = self:getNearestNitrogenValueFromValue(v587_)
			self:setNitrogenLevelAtArea(v590_, SprayType.FERTILIZER, v591_, true, v588_)
			Logging.info("NitrogenMap: Set nitrogen level of field %d to %d kg/ha", v586_, v587_)
		end
	end
end

function NitrogenMap:overwriteGameFunctions(pfModule)
	NitrogenMap:superClass().overwriteGameFunctions(self, pfModule)
	pfModule:overwriteGameFunction(FertilizingSowingMachine, "processSowingMachineArea", function(p594_, p595_, p596_, p597_, p598_)
		if not p595_.isServer and p595_.currentUpdateDistance > SowingMachine.CLIENT_DM_UPDATE_RADIUS then
			return p594_(p595_, p596_, p597_, p598_)
		end
		local v599_ = p595_.spec_fertilizingSowingMachine
		local v600_ = p595_.spec_sowingMachine
		local v601_ = p595_.spec_sprayer.workAreaParameters
		local v602_ = v600_.workAreaParameters
		if not v602_.isActive then
			return p594_(p595_, p596_, p597_, p598_)
		end
		if not v602_.canFruitBePlanted then
			return p594_(p595_, p596_, p597_, p598_)
		end
		if v601_.sprayFillLevel <= 0 or v599_.needsSetIsTurnedOn and not p595_:getIsTurnedOn() then
			return p594_(p595_, p596_, p597_, p598_)
		end
		if p595_.preProcessExtUnderRootFertilizerArea ~= nil then
			p595_:preProcessExtUnderRootFertilizerArea(p597_, p598_)
		end
		return p594_(p595_, p596_, p597_, p598_)
	end)
	pfModule:overwriteGameFunction(FertilizingCultivator, "processCultivatorArea", function(p603_, p604_, p605_, p606_, p607_)
		if not p604_.isServer and p604_.currentUpdateDistance > Cultivator.CLIENT_DM_UPDATE_RADIUS then
			return p603_(p604_, p605_, p606_, p607_)
		end
		local v608_ = p604_.spec_fertilizingCultivator
		if p604_.spec_sprayer.workAreaParameters.sprayFillLevel <= 0 or v608_.needsSetIsTurnedOn and not p604_:getIsTurnedOn() then
			return p603_(p604_, p605_, p606_, p607_)
		end
		if p604_.preProcessExtUnderRootFertilizerArea ~= nil then
			p604_:preProcessExtUnderRootFertilizerArea(p606_, p607_)
		end
		return p603_(p604_, p605_, p606_, p607_)
	end)
	pfModule:overwriteGameFunction(FSDensityMapUtil, "updateFertilizerArea", function(p609_, p610_, p611_, p612_, p613_, p614_, p615_, p616_, p617_)
		local v618_ = FSDensityMapUtil.functionCache.updateFertilizerArea
		if v618_ ~= nil then
			local v619_ = g_currentMission.fieldGroundSystem:getMaxValue(FieldDensityMap.SPRAY_LEVEL)
			v618_.maskFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, 0, v619_)
		end
		return p609_(p610_, p611_, p612_, p613_, p614_, p615_, p616_, p617_)
	end)
end
