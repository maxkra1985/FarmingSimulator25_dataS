-- Local values: CoverMap_mt
CoverMap = {}
CoverMap.MOD_NAME = g_currentModName
local CoverMap_mt = Class(CoverMap, ValueMap)
source(g_currentModDirectory .. "scripts/densityMapUpdates/CoverMapDensityMapTask.lua")

-- Upvalues: CoverMap_mt
-- Local values: self
function CoverMap.new(pfModule, customMt)
	-- upvalues: (copy) CoverMap_mt
	local v4_ = ValueMap.new(pfModule, customMt or CoverMap_mt)
	v4_.name = "coverMap"
	if g_server ~= nil then
		addConsoleCommand("pfUncoverField", "Uncovers given field", "debugUncoverField", v4_)
		addConsoleCommand("pfUncoverAll", "Uncovers all fields", "debugUncoverAll", v4_)
		addConsoleCommand("pfReduceCoverState", "Reduces cover State for given field", "debugReduceCoverStateField", v4_)
		addConsoleCommand("pfReduceCoverStateAll", "Reduces cover State for all fields", "debugReduceCoverStateAll", v4_)
	end
	return v4_
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
	local v10_ = key .. ".coverMap"
	self.sizeX = getXMLInt(xmlFile, v10_ .. "#sizeX") or 1024
	self.sizeY = getXMLInt(xmlFile, v10_ .. "#sizeY") or 1024
	self.lockChannel = getXMLInt(xmlFile, v10_ .. "#lockChannel") or 0
	self.firstChannel = getXMLInt(xmlFile, v10_ .. "#firstChannel") or 1
	self.numChannels = getXMLInt(xmlFile, v10_ .. "#numChannels") or 4
	self.maxValue = 2 ^ self.numChannels - 1
	self.maxValue = getXMLInt(xmlFile, v10_ .. "#maxValue") or self.maxValue
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

-- Local values: modifier, maskFilter, modifierFarmIdMap, fieldGroundSystem, groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, _, area, totalArea
function CoverMap:analyseArea(densityMapShape, state, farmId, farmlandId)
	local v17_ = self.densityMapModifiersAnalyse.modifier
	local v18_ = self.densityMapModifiersAnalyse.maskFilter
	local v19_ = self.densityMapModifiersAnalyse.modifierFarmIdMap
	if v17_ == nil or (v18_ == nil or v19_ == nil) then
		self.densityMapModifiersAnalyse.modifier = DensityMapModifier.new(self.bitVectorMap, self.firstChannel, self.numChannels, g_terrainNode)
		v17_ = self.densityMapModifiersAnalyse.modifier
		local v20_, v21_, v22_ = g_currentMission.fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
		self.densityMapModifiersAnalyse.maskFilter = DensityMapFilter.new(v20_, v21_, v22_)
		v18_ = self.densityMapModifiersAnalyse.maskFilter
		v18_:setValueCompareParams(DensityValueCompareType.GREATER, 0)
		self.densityMapModifiersAnalyse.modifierFarmIdMap = DensityMapModifier.new(self.bitVectorMapSoilSampleFarmId, 0, 4, g_terrainNode)
		v19_ = self.densityMapModifiersAnalyse.modifierFarmIdMap
	end
	densityMapShape:applyToModifier(v17_)
	densityMapShape:applyToModifier(v19_)
	local _, v23_, v24_ = v17_:executeSetWithStats(state or self.sampledValue, v18_)
	v19_:executeSet(farmId, v18_)
	self.soilMap:onAnalyseArea(densityMapShape, state, farmId)
	return v23_, v24_
end

-- Local values: updateTask
function CoverMap:uncoverAnalysedArea(farmId)
	local v26_ = CoverMapDensityMapTask.new()
	v26_:setData(farmId, nil)
	v26_:enqueue()
end

-- Local values: updateTask
function CoverMap:uncoverFarmlandArea(farmlandId)
	local v28_ = CoverMapDensityMapTask.new()
	v28_:setData(nil, farmlandId)
	v28_:enqueue()
end

function CoverMap:onCoverUpdateFinished(farmId, farmlandId, sampledPercentageByFarmlandId) end

-- Local values: functionData, fieldGroundSystem, groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, multiModifier, modifier, farmFilter, sampledFilter, farmlandIds, _farmlandId, _farmId, cachedData, multiModifier, modifier, farmlandMaskFilter, fieldFilter, noFieldFilter, farmlandIds
function CoverMap:getCoverMultiModifier(farmId, farmlandId)
	local v32_ = self.densityMapModifiersUncover
	if v32_ == nil then
		v32_ = {
			["modifier"] = DensityMapModifier.new(self.bitVectorMap, self.firstChannel, self.numChannels, g_terrainNode),
			["farmlandMaskFilter"] = DensityMapFilter.new(g_farmlandManager.localMap, 0, g_farmlandManager.numberOfBits),
			["sampledFilter"] = DensityMapFilter.new(self.bitVectorMap, self.firstChannel, self.numChannels)
		}
		v32_.sampledFilter:setValueCompareParams(DensityValueCompareType.EQUAL, self.sampledValue)
		v32_.farmFilter = DensityMapFilter.new(self.bitVectorMapSoilSampleFarmId, 0, 4)
		local v33_, v34_, v35_ = g_currentMission.fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
		v32_.fieldFilter = DensityMapFilter.new(v33_, v34_, v35_)
		v32_.fieldFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)
		v32_.noFieldFilter = DensityMapFilter.new(v33_, v34_, v35_)
		v32_.noFieldFilter:setValueCompareParams(DensityValueCompareType.EQUAL, 0)
		v32_.coverFilter = DensityMapFilter.new(self.bitVectorMap, self.firstChannel, self.numChannels)
		v32_.coverFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, 2, self.maxValue + 1)
		v32_.sampleStateMaskFilters = {}
		v32_.farmlandModifiers = {}
		self.densityMapModifiersUncover = v32_
	end
	if farmId == nil then
		if farmlandId == nil then
			return nil, nil
		end
		local v36_ = v32_.farmlandModifiers[farmlandId]
		if v36_ == nil then
			local v37_ = DensityMapMultiModifier.new()
			local v38_ = v32_.modifier
			local v39_ = v32_.farmlandMaskFilter
			local v40_ = v32_.fieldFilter
			local v41_ = v32_.noFieldFilter
			v39_:setValueCompareParams(DensityValueCompareType.EQUAL, farmlandId)
			if farmlandId < 0 then
				v39_ = nil
			end
			v37_:addExecuteSet(0, v38_, v41_, v39_)
			self.yieldMap:addClearToMultiModifier(v37_, v41_, v39_)
			self.seedRateMap:addClearToMultiModifier(v37_, v41_, v39_)
			self.soilMap:addUncoverToMultiModifier(v37_, v40_, v39_, v41_, v39_)
			v37_:addExecuteSet(self.maxValue, v38_, v40_, v39_)
			local v42_ = { farmlandId }
			self:addSampleStateGetToMultiModifier(v37_, v32_, v42_)
			v36_ = {
				["multiModifier"] = v37_,
				["farmlandIds"] = v42_
			}
			v32_.farmlandModifiers[farmlandId] = v36_
		end
		return v36_.multiModifier, v36_.farmlandIds
	end
	local v43_ = DensityMapMultiModifier.new()
	local v44_ = v32_.modifier
	local v45_ = v32_.farmFilter
	local v46_ = v32_.sampledFilter
	v45_:setValueCompareParams(DensityValueCompareType.EQUAL, farmId)
	if farmId < 0 then
		v45_ = nil
	end
	self.soilMap:addUncoverToMultiModifier(v43_, v46_, v45_)
	v43_:addExecuteSet(self.maxValue, v44_, v46_, v45_)
	local v47_ = {}
	for v48_, v49_ in pairs(g_farmlandManager.farmlandMapping) do
		if v49_ == farmId then
			table.insert(v47_, v48_)
		end
	end
	self:addSampleStateGetToMultiModifier(v43_, v32_, v47_)
	return v43_, v47_
end

-- Local values: farmlandManager, _, farmlandId, maskFilter, fieldLabel, sampledLabel
function CoverMap:addSampleStateGetToMultiModifier(multiModifier, functionData, farmlandIds)
	local v53_ = g_farmlandManager
	for _, v54_ in ipairs(farmlandIds) do
		local v55_ = functionData.sampleStateMaskFilters[v54_]
		if v55_ == nil then
			v55_ = DensityMapFilter.new(v53_.localMap, 0, v53_.numberOfBits)
			v55_:setValueCompareParams(DensityValueCompareType.EQUAL, v54_)
			functionData.sampleStateMaskFilters[v54_] = v55_
		end
		local v56_ = "field_" .. tostring(v54_)
		local v57_ = "sampled_" .. tostring(v54_)
		multiModifier:addExecuteGet(v56_, functionData.modifier, v55_, functionData.fieldFilter)
		multiModifier:addExecuteGet(v57_, functionData.modifier, functionData.coverFilter, v55_, functionData.fieldFilter)
	end
end

-- Local values: modifier, coverFilter, maskFilter, fieldFilter, farmlandManager, fieldGroundSystem, groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, _, areaField, _, _, areaSampled, _
function CoverMap:getFarmlandSampleState(farmlandId)
	local v60_ = self.densityMapModifiersFarmlandState.modifier
	local v61_ = self.densityMapModifiersFarmlandState.coverFilter
	local v62_ = self.densityMapModifiersFarmlandState.maskFilter
	local v63_ = self.densityMapModifiersFarmlandState.fieldFilter
	if v60_ == nil or (v61_ == nil or (v62_ == nil or v63_ == nil)) then
		self.densityMapModifiersFarmlandState.modifier = DensityMapModifier.new(self.bitVectorMap, self.firstChannel, self.numChannels)
		v60_ = self.densityMapModifiersFarmlandState.modifier
		v60_:setParallelogramDensityMapCoords(0, 0, 0, self.sizeY, self.sizeX, 0, DensityCoordType.POINT_POINT_POINT)
		self.densityMapModifiersFarmlandState.coverFilter = DensityMapFilter.new(self.bitVectorMap, self.firstChannel, self.numChannels)
		v61_ = self.densityMapModifiersFarmlandState.coverFilter
		v61_:setValueCompareParams(DensityValueCompareType.BETWEEN, 2, self.maxValue + 1)
		local v64_ = g_farmlandManager
		self.densityMapModifiersFarmlandState.maskFilter = DensityMapFilter.new(v64_.localMap, 0, v64_.numberOfBits)
		v62_ = self.densityMapModifiersFarmlandState.maskFilter
		v62_:setValueCompareParams(DensityValueCompareType.EQUAL, farmlandId)
		local v65_, v66_, v67_ = g_currentMission.fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
		self.densityMapModifiersFarmlandState.fieldFilter = DensityMapFilter.new(v65_, v66_, v67_)
		v63_ = self.densityMapModifiersFarmlandState.fieldFilter
		v63_:setValueCompareParams(DensityValueCompareType.GREATER, 0)
	end
	v62_:setValueCompareParams(DensityValueCompareType.EQUAL, farmlandId)
	local _, v68_, _ = v60_:executeGet(v62_, v63_)
	local _, v69_, _ = v60_:executeGet(v61_, v62_, v63_)
	return v68_ <= 0 and 0 or v69_ / v68_
end

-- Local values: functionData, multiModifiersByHash, hash, _, fruitIndex, multiModifiers, f, useForageStates, multiModifier, _, fruitIndex, desc, fruitFilterHarvestState, minHarvestState, maxHarvestState, fruitFilterPrepareState, multiModifier, _, fruitIndex, desc, fruitFilterHarvestState, minHarvestState, maxHarvestState, fruitFilterPrepareState
function CoverMap:getCoverUpdateDensityMapModifiers(fruitTypes, preUpdate, useMinForageState, strawChopperActive)
	local v74_ = self.densityMapModifiersUpdate
	if v74_ == nil then
		v74_ = {
			["modifier"] = DensityMapModifier.new(self.bitVectorMap, self.firstChannel, self.numChannels, g_terrainNode),
			["lockModifier"] = DensityMapModifier.new(self.bitVectorMapTempHarvestLock, 0, 1, g_terrainNode),
			["lockFilter"] = DensityMapFilter.new(self.bitVectorMapTempHarvestLock, 0, 1)
		}
		v74_.lockFilter:setValueCompareParams(DensityValueCompareType.EQUAL, 1)
		v74_.lockFilterReduction = DensityMapFilter.new(self.bitVectorMapTempHarvestLock, 0, 1)
		v74_.lockFilterReduction:setValueCompareParams(DensityValueCompareType.EQUAL, 1)
		v74_.coverStateFilter = DensityMapFilter.new(self.bitVectorMap, self.firstChannel, self.numChannels)
		v74_.coverStateFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, 2, self.maxValue)
		v74_.multiModifiersPreUpdateByHash = {}
		v74_.numChangedPixelsPre = {}
		v74_.totalNumPixelsPre = {}
		v74_.multiModifiersPostUpdateByHash = {}
		v74_.numChangedPixelsPost = {}
		v74_.totalNumPixelsPost = {}
		self.densityMapModifiersUpdate = v74_
	end
	local v75_ = preUpdate and v74_.multiModifiersPreUpdateByHash or v74_.multiModifiersPostUpdateByHash
	local v76_ = 0
	for _, v77_ in pairs(fruitTypes) do
		v76_ = v76_ + v77_ * 512
	end
	local v78_ = v75_[v76_]
	if v78_ == nil then
		v78_ = {}
		for v79_ = 1, 2 do
			local v80_ = v79_ == 2
			if preUpdate then
				local v81_ = DensityMapMultiModifier.new()
				v81_:addExecuteSet(0, v74_.lockModifier)
				for _, v82_ in pairs(fruitTypes) do
					local v83_ = g_fruitTypeManager:getFruitTypeByIndex(v82_)
					if v83_ ~= nil and v83_.terrainDataPlaneId ~= nil then
						local v84_ = DensityMapFilter.new(v83_.terrainDataPlaneId, v83_.startStateChannel, v83_.numStateChannels)
						local v85_ = v83_.minHarvestingGrowthState
						local v86_ = v83_.maxHarvestingGrowthState
						if v80_ and v83_.minForageGrowthState ~= 0 then
							local v87_ = v83_.minForageGrowthState
							v85_ = math.min(v85_, v87_)
						end
						if v85_ == v86_ then
							v84_:setValueCompareParams(DensityValueCompareType.EQUAL, v85_)
						else
							v84_:setValueCompareParams(DensityValueCompareType.BETWEEN, v85_, v86_)
						end
						v84_:setSupersamplingMode(DensityFilterSupersamplingMode.ANY)
						v81_:addExecuteSetWithStats(tostring(v82_), 1, v74_.lockModifier, v84_)
						if v83_.minPreparingGrowthState ~= nil then
							local v88_ = DensityMapFilter.new(v83_.terrainDataPlaneId, v83_.startStateChannel, v83_.numStateChannels)
							if v83_.minPreparingGrowthState == v83_.maxPreparingGrowthState then
								v88_:setValueCompareParams(DensityValueCompareType.EQUAL, v83_.minPreparingGrowthState)
							else
								v88_:setValueCompareParams(DensityValueCompareType.BETWEEN, v83_.minPreparingGrowthState, v83_.maxPreparingGrowthState)
							end
							v88_:setSupersamplingMode(DensityFilterSupersamplingMode.ANY)
							v81_:addExecuteSetWithStats(tostring(v82_), 1, v74_.lockModifier, v88_)
						end
					end
				end
				v78_[v80_] = v81_
			else
				local v89_ = DensityMapMultiModifier.new()
				for _, v90_ in pairs(fruitTypes) do
					local v91_ = g_fruitTypeManager:getFruitTypeByIndex(v90_)
					if v91_ ~= nil and v91_.terrainDataPlaneId ~= nil then
						local v92_ = DensityMapFilter.new(v91_.terrainDataPlaneId, v91_.startStateChannel, v91_.numStateChannels)
						local v93_ = v91_.minHarvestingGrowthState
						local v94_ = v91_.maxHarvestingGrowthState
						if v80_ and v91_.minForageGrowthState ~= 0 then
							local v95_ = v91_.minForageGrowthState
							v93_ = math.min(v93_, v95_)
						end
						if v93_ == v94_ then
							v92_:setValueCompareParams(DensityValueCompareType.EQUAL, v93_)
						else
							v92_:setValueCompareParams(DensityValueCompareType.BETWEEN, v93_, v94_)
						end
						v92_:setSupersamplingMode(DensityFilterSupersamplingMode.ANY)
						v89_:addExecuteSet(0, v74_.lockModifier, v74_.lockFilter, v92_)
						if v91_.minPreparingGrowthState ~= nil then
							local v96_ = DensityMapFilter.new(v91_.terrainDataPlaneId, v91_.startStateChannel, v91_.numStateChannels)
							if v91_.minPreparingGrowthState == v91_.maxPreparingGrowthState then
								v96_:setValueCompareParams(DensityValueCompareType.EQUAL, v91_.minPreparingGrowthState)
							else
								v96_:setValueCompareParams(DensityValueCompareType.BETWEEN, v91_.minPreparingGrowthState, v91_.maxPreparingGrowthState)
							end
							v96_:setSupersamplingMode(DensityFilterSupersamplingMode.ANY)
							v89_:addExecuteSet(0, v74_.lockModifier, v74_.lockFilter, v96_)
						end
					end
				end
				v89_:addExecuteAdd(-1, v74_.modifier, v74_.lockFilter, v74_.coverStateFilter)
				v89_:addExecuteGet("pixelsToLock", v74_.modifier, v74_.lockFilter)
				v78_[v80_] = v89_
			end
		end
		v75_[v76_] = v78_
	end
	if preUpdate then
		return v78_[useMinForageState], v74_.numChangedPixelsPre, v74_.totalNumPixelsPre
	else
		return v78_[useMinForageState], v74_.numChangedPixelsPost, v74_.totalNumPixelsPost
	end
end

-- Local values: multiModifierPreUpdate, numChangedPixels, totalNumPixels, fruitIndexStr, numPixels
function CoverMap:preUpdateCoverArea(fruitTypes, densityMapShape, useMinForageState, strawChopperActive)
	if useMinForageState == nil then
		useMinForageState = false
	end
	local v102_, v103_, v104_ = self:getCoverUpdateDensityMapModifiers(fruitTypes, true, useMinForageState, strawChopperActive)
	if v102_ ~= nil then
		densityMapShape:applyToModifier(v102_)
		v102_:resetStats()
		v102_:execute(nil, v103_, v104_)
		for v105_, v106_ in pairs(v103_) do
			if v106_ > 0 then
				self.lastUsedFruitIndex = tonumber(v105_)
			end
		end
	end
end

-- Local values: multiModifierPostUpdate, numChangedPixels, totalNumPixels, functionData, lockModifier, lockFilterReduction, pixelsToLock, phMapUpdated, nMapUpdated
function CoverMap:postUpdateCoverArea(fruitTypes, densityMapShape, useMinForageState, strawChopperActive)
	if useMinForageState == nil then
		useMinForageState = false
	end
	local v112_, v113_, v114_ = self:getCoverUpdateDensityMapModifiers(fruitTypes, false, useMinForageState, strawChopperActive)
	if v112_ == nil then
		return false, false
	end
	local v115_ = self.densityMapModifiersUpdate
	if v115_ == nil then
		return false, false
	end
	local v116_ = v115_.lockModifier
	local v117_ = v115_.lockFilterReduction
	densityMapShape:applyToModifier(v112_)
	v112_:resetStats()
	v112_:execute(nil, v113_, v114_)
	local v118_ = false
	local v119_ = false
	if (v113_.pixelsToLock or 0) > 0 and self.lastUsedFruitIndex ~= nil then
		if self.pfModule.nitrogenMap ~= nil then
			v119_ = self.pfModule.nitrogenMap:harvestUpdate(v117_, self.lastUsedFruitIndex, densityMapShape, useMinForageState, strawChopperActive)
		end
		if self.pfModule.pHMap ~= nil then
			v118_ = self.pfModule.pHMap:harvestUpdate(v117_, self.lastUsedFruitIndex, densityMapShape, useMinForageState, strawChopperActive)
		end
		if self.pfModule.seedRateMap ~= nil then
			self.pfModule.seedRateMap:harvestUpdate(v117_, self.lastUsedFruitIndex, densityMapShape, useMinForageState, strawChopperActive)
		end
	end
	densityMapShape:applyToModifier(v116_)
	v116_:executeSet(0)
	return v118_, v119_
end

-- Local values: modifier
function CoverMap:resetCoverLock(densityMapShape)
	local v122_ = self.densityMapModifiersResetLock.modifier
	if v122_ == nil then
		self.densityMapModifiersResetLock.modifier = DensityMapModifier.new(self.bitVectorMap, self.lockChannel, 1, g_terrainNode)
		v122_ = self.densityMapModifiersResetLock.modifier
	end
	densityMapShape:applyToModifier(v122_)
	v122_:executeSet(0)
end

function CoverMap:getNumCoverOverlays()
	return self.maxValue - 1
end

-- Local values: numOverlays, alpha
function CoverMap:buildCoverStateOverlay(overlay, index)
	local v127_ = self:getNumCoverOverlays()
	resetDensityMapVisualizationOverlay(overlay)
	local v128_ = (v127_ - (index - 1)) / v127_
	setOverlayColor(overlay, 1, 1, 1, v128_)
	setDensityMapVisualizationOverlayStateColor(overlay, self.bitVectorMap, 0, 0, self.firstChannel, self.numChannels, index, 0, 0, 0)
end

-- Local values: coverValue
function CoverMap:getIsUncoveredAtPos(x, z, isWorldPos)
	if isWorldPos == true then
		x = MathUtil.round((x + g_currentMission.terrainSize * 0.5) / g_currentMission.terrainSize * self.sizeX + 0.5) - 1
		z = MathUtil.round((z + g_currentMission.terrainSize * 0.5) / g_currentMission.terrainSize * self.sizeY + 0.5) - 1
	end
	local v133_ = getBitVectorMapPoint(self.bitVectorMap, x, z, self.firstChannel, self.numChannels)
	return v133_ > 1 and v133_ <= self.maxValue
end

function CoverMap:getLevelAtWorldPos(x, z)
	local v137_ = MathUtil.round((x + g_currentMission.terrainSize * 0.5) / g_currentMission.terrainSize * self.sizeX + 0.5) - 1
	local v138_ = MathUtil.round((z + g_currentMission.terrainSize * 0.5) / g_currentMission.terrainSize * self.sizeY + 0.5) - 1
	return getBitVectorMapPoint(self.bitVectorMap, v137_, v138_, self.firstChannel, self.numChannels)
end

-- Local values: field, area
function CoverMap:debugReduceCoverStateField(fieldId)
	local v141_ = g_fieldManager:getFieldById((tonumber(fieldId)))
	if v141_ ~= nil and v141_.getDensityMapPolygon ~= nil then
		local v142_ = v141_:getDensityMapPolygon()
		self:preUpdateCoverArea({}, v142_, true, false)
		self:postUpdateCoverArea({}, v142_, true, false)
		self:resetCoverLock(v142_)
	end
	self.pfModule:updatePrecisionFarmingOverlays()
end

-- Local values: i
function CoverMap:debugReduceCoverStateAll()
	for v144_ = 1, #g_fieldManager.fields do
		self:debugReduceCoverStateField(v144_)
	end
end

-- Local values: field, area
function CoverMap:debugUncoverField(fieldId)
	local v147_ = g_fieldManager:getFieldById((tonumber(fieldId)))
	if v147_ ~= nil then
		self:analyseArea(v147_:getDensityMapPolygon(), nil, g_farmlandManager:getFarmlandOwner(v147_.farmland.id), v147_.farmland.id)
		self:uncoverAnalysedArea(-1)
	end
end

-- Local values: i
function CoverMap:debugUncoverAll()
	for v149_ = 1, #g_fieldManager.fields do
		self:debugUncoverField(v149_)
	end
end
