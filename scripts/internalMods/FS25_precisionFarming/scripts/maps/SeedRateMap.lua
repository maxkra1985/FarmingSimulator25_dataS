-- Local values: SeedRateMap_mt
SeedRateMap = {}
SeedRateMap.MOD_NAME = g_currentModName
local SeedRateMap_mt = Class(SeedRateMap, ValueMap)

-- Upvalues: SeedRateMap_mt
-- Local values: self
function SeedRateMap.new(pfModule, customMt)
	-- upvalues: (copy) SeedRateMap_mt
	local v4_ = ValueMap.new(pfModule, customMt or SeedRateMap_mt)
	v4_.filename = "precisionFarming_seedRateMap.grle"
	v4_.name = "seedRateMap"
	v4_.id = "SEED_RATE_MAP"
	v4_.label = "ui_mapOverviewSeedRate"
	v4_.texts = {}
	v4_.texts.cropNameHeader = g_i18n:getText("ui_cropName", SeedRateMap.MOD_NAME)
	v4_.texts.cropType1 = g_i18n:getText("ui_soilType_1", SeedRateMap.MOD_NAME)
	v4_.texts.cropType2 = g_i18n:getText("ui_soilType_2", SeedRateMap.MOD_NAME)
	v4_.texts.cropType3 = g_i18n:getText("ui_soilType_3", SeedRateMap.MOD_NAME)
	v4_.texts.cropType4 = g_i18n:getText("ui_soilType_4", SeedRateMap.MOD_NAME)
	v4_.densityMapModifiersSeedUpdate = {}
	v4_.densityMapModifiersHarvestMulti = nil
	v4_.densityMapModifiersClear = nil
	if g_server ~= nil then
		addConsoleCommand("pfSeedRateSet", "Sets the given seed rate on the given field", "debugSetSeedRateLevel", v4_, "fieldId; seedRate")
	end
	return v4_
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

-- Local values: i, baseKey, rateValue, missionInfo, mapXMLFilename, mapXMLFile
function SeedRateMap:loadFromXML(xmlFile, key, baseDirectory, configFileName, mapFilename)
	local v10_ = key .. ".seedRateMap"
	self.numChannels = getXMLInt(xmlFile, v10_ .. ".bitVectorMap#numChannels") or 2
	self.maxValue = 2 ^ self.numChannels - 1
	self.sizeX = getXMLInt(xmlFile, v10_ .. ".bitVectorMap#sizeX") or 1024
	self.sizeY = getXMLInt(xmlFile, v10_ .. ".bitVectorMap#sizeY") or 1024
	self.bitVectorMap = self:loadSavedBitVectorMap("SeedRateMap", self.filename, self.numChannels, self.sizeX)
	if g_maxModDescVersion > 64 then
		self:addBitVectorMapToSync(self.bitVectorMap)
	end
	self:addBitVectorMapToSave(self.bitVectorMap, self.filename)
	self:addBitVectorMapToDelete(self.bitVectorMap)
	self.rateValues = {}
	local v11_ = 0
	while true do
		local v12_ = string.format("%s.rateValues.rateValue(%d)", v10_, v11_)
		if not hasXMLProperty(xmlFile, v12_) then
			break
		end
		local v13_ = {
			["value"] = getXMLInt(xmlFile, v12_ .. "#value") or 0,
			["text"] = g_i18n:convertText(getXMLString(xmlFile, v12_ .. "#text"), SeedRateMap.MOD_NAME),
			["color"] = string.getVector(getXMLString(xmlFile, v12_ .. "#color"), 3) or { 0, 0, 0 },
			["colorBlind"] = string.getVector(getXMLString(xmlFile, v12_ .. "#colorBlind"), 3)
		}
		local v14_ = self.rateValues
		table.insert(v14_, v13_)
		v11_ = v11_ + 1
	end
	self.defaultSeedRate = MathUtil.round(#self.rateValues * 0.5)
	self.fruitTypes = {}
	self:loadFruitTypeSeedRatesFromXML(xmlFile, v10_)
	local v15_ = g_currentMission.missionInfo
	local v16_ = Utils.getFilename(v15_.mapXMLFilename, g_currentMission.baseDirectory)
	local v17_ = loadXMLFile("MapXML", v16_)
	if v17_ ~= nil then
		self:loadFruitTypeSeedRatesFromXML(v17_, "map.precisionFarming.seedRateMap")
		delete(v17_)
	end
	self.coverMap = g_precisionFarming.coverMap
	return true
end

-- Local values: i, baseKey, fruitTypeName, fruitTypeDesc, fruitType, soilTypeIndex, soilKey, soilType, maxYield, j
function SeedRateMap:loadFruitTypeSeedRatesFromXML(xmlFile, key)
	local v21_ = 0
	while true do
		local v22_ = string.format("%s.fruitTypes.fruitType(%d)", key, v21_)
		if not hasXMLProperty(xmlFile, v22_) then
			break
		end
		local v23_ = getXMLString(xmlFile, v22_ .. "#name")
		if v23_ ~= nil then
			local v24_ = g_fruitTypeManager:getFruitTypeByName(v23_)
			if v24_ ~= nil then
				local v25_ = {
					["index"] = v24_.index,
					["seedRates"] = self:getRateValues(xmlFile, v22_ .. ".seedRates#rates", #self.rateValues),
					["seedUsages"] = self:getRateValues(xmlFile, v22_ .. ".seedRates#usages", #self.rateValues)
				}
				if v25_.seedRates == nil or v25_.seedUsages == nil then
					Logging.warning("Invalid seed rates or usages in \'%s\'", v22_)
				else
					v25_.soilTypes = {}
					local v26_ = 0
					while true do
						local v27_ = string.format("%s.soilTypes.soilType(%d)", v22_, v26_)
						if not hasXMLProperty(xmlFile, v27_) then
							break
						end
						local v28_ = {
							["index"] = getXMLInt(xmlFile, v27_ .. "#index") or 1,
							["yields"] = self:getRateValues(xmlFile, v27_ .. "#yields", #self.rateValues)
						}
						if v28_.yields == nil then
							Logging.warning("Invalid yield definitions in \'%s\'", v27_)
						else
							v28_.bestYieldIndex = 1
							local v29_ = 0
							for v30_ = 1, #v28_.yields do
								if v29_ < v28_.yields[v30_] then
									v29_ = v28_.yields[v30_]
									v28_.bestYieldIndex = v30_
								end
							end
							v25_.soilTypes[v28_.index] = v28_
						end
						v26_ = v26_ + 1
					end
					self.fruitTypes[v24_.index] = v25_
				end
			end
		end
		v21_ = v21_ + 1
	end
end

-- Local values: str, values, i
function SeedRateMap:getRateValues(xmlFile, key, numValues)
	local v34_ = getXMLString(xmlFile, key):split(" ")
	if #v34_ ~= numValues then
		return nil
	end
	for v35_ = 1, #v34_ do
		local v36_ = v34_[v35_]
		v34_[v35_] = tonumber(v36_)
	end
	return v34_
end

-- Local values: rate
function SeedRateMap:getRateLabelByIndex(index)
	local v39_ = self.rateValues[index]
	return v39_ == nil and "unknown" or v39_.text
end

function SeedRateMap:update(dt) end

-- Local values: soilMap, modifier, maskFilter, soilFilter, fieldGroundSystem, groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, fruitTypeData, numPixelsChanged, seedUsageSum, seedRateSum, seedRateIndexSum, soilTypeIndex, soilTypeData, _, numPixels, _
function SeedRateMap:updateSeedArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, fruitTypeIndex, autoMode, manualSeedRate)
	local v50_ = self.pfModule.soilMap
	if v50_ ~= nil then
		local v51_ = self.densityMapModifiersSeedUpdate.modifier
		local v52_ = self.densityMapModifiersSeedUpdate.maskFilter
		local v53_ = self.densityMapModifiersSeedUpdate.soilFilter
		if v51_ == nil or (v52_ == nil or v53_ == nil) then
			self.densityMapModifiersSeedUpdate.modifier = DensityMapModifier.new(self.bitVectorMap, 0, self.numChannels, g_terrainNode)
			v51_ = self.densityMapModifiersSeedUpdate.modifier
			local v54_, v55_, v56_ = g_currentMission.fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
			self.densityMapModifiersSeedUpdate.maskFilter = DensityMapFilter.new(v54_, v55_, v56_)
			v52_ = self.densityMapModifiersSeedUpdate.maskFilter
			v52_:setValueCompareParams(DensityValueCompareType.GREATER, 0)
			self.densityMapModifiersSeedUpdate.soilFilter = DensityMapFilter.new(v50_.bitVectorMap, v50_.typeFirstChannel, v50_.typeNumChannels)
			v53_ = self.densityMapModifiersSeedUpdate.soilFilter
		end
		if type(startWorldX) == "number" then
			v51_:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
		elseif type(startWorldX) == "table" then
			startWorldX:applyToModifier(v51_)
		end
		local v57_ = self.fruitTypes[fruitTypeIndex]
		if v57_ == nil then
			if autoMode then
				v51_:executeSet(self.defaultSeedRate, v52_)
			else
				v51_:executeSet(manualSeedRate, v52_)
			end
		else
			if not autoMode then
				v51_:executeSet(manualSeedRate, v52_)
				return v57_.seedUsages[manualSeedRate], v57_.seedRates[manualSeedRate], manualSeedRate
			end
			local v58_ = 0
			local v59_ = 0
			local v60_ = 0
			local v61_ = 0
			for v62_, v63_ in pairs(v57_.soilTypes) do
				if v63_.bestYieldIndex ~= nil then
					v53_:setValueCompareParams(DensityValueCompareType.EQUAL, v62_ - 1)
					local _, v64_, _ = v51_:executeSetWithStats(v63_.bestYieldIndex, v52_, v53_)
					v60_ = v60_ + v64_
					v61_ = v61_ + v57_.seedUsages[v63_.bestYieldIndex] * v64_
					v58_ = v58_ + v57_.seedRates[v63_.bestYieldIndex] * v64_
					v59_ = v59_ + v63_.bestYieldIndex * v64_
				end
			end
			if v60_ > 0 then
				return v61_ / v60_, v58_ / v60_, MathUtil.round(v59_ / v60_)
			end
		end
	end
	return 0
end

-- Local values: soilMap, functionData, fruitTypeData, multiModifier, soilTypeIndex, soilTypeData, accumulators, numChangedPixels, totalNumPixels, totalYield, numTypes, indexStr, accumulator, index, soilTypeData, state, yield
function SeedRateMap:harvestUpdate(filter, fruitIndex, densityMapShape, useMinForageState, strawChopperActive)
	local v68_ = self.pfModule.soilMap
	if v68_ ~= nil and v68_.bitVectorMap ~= nil then
		local v69_ = self.densityMapModifiersHarvestMulti
		if v69_ == nil then
			v69_ = {
				["modifier"] = DensityMapModifier.new(self.bitVectorMap, 0, self.numChannels, g_terrainNode)
			}
			v69_.modifier:setPolygonRoundingMode(DensityRoundingMode.INCLUSIVE)
			v69_.soilFilter = DensityMapFilter.new(v68_.bitVectorMap, v68_.typeFirstChannel, v68_.typeNumChannels)
			v69_.multiModifiersByFruitIndex = {}
			v69_.accumulators = {}
			v69_.numChangedPixels = {}
			v69_.totalNumPixels = {}
			self.densityMapModifiersHarvestMulti = v69_
		end
		local v70_ = self.fruitTypes[fruitIndex]
		if v70_ == nil then
			self.lastSeedRateMultiplier = 1
			return
		end
		local v71_ = v69_.multiModifiersByFruitIndex[fruitIndex]
		if v71_ == nil then
			v71_ = DensityMapMultiModifier.new()
			v69_.multiModifiersByFruitIndex[fruitIndex] = v71_
			for v72_, v73_ in pairs(v70_.soilTypes) do
				if v73_.bestYieldIndex ~= nil then
					v69_.soilFilter:setValueCompareParams(DensityValueCompareType.EQUAL, v72_ - 1)
					v71_:addExecuteGet(tostring(v72_), v69_.modifier, v69_.soilFilter)
				end
			end
		end
		densityMapShape:applyToModifier(v71_)
		local v74_ = v69_.accumulators
		local v75_ = v69_.numChangedPixels
		local v76_ = v69_.totalNumPixels
		v71_:resetStats()
		v71_:execute(v74_, v75_, v76_)
		local v77_ = 0
		local v78_ = 0
		for v79_, v80_ in pairs(v74_) do
			if v80_ > 0 then
				local v81_ = tonumber(v79_)
				local v82_ = v70_.soilTypes[v81_]
				local v83_ = MathUtil.round(v80_ / v75_[v79_])
				if v82_.yields[v83_] ~= nil then
					v77_ = v77_ + v82_.yields[v83_]
					v78_ = v78_ + 1
					self.lastSeedRateFound = v83_
					self.lastSeedRateTarget = v82_.bestYieldIndex
				end
			end
		end
		self.lastSeedRateMultiplier = v78_ <= 0 and 1 or v77_ / v78_
	end
end

-- Local values: functionData
function SeedRateMap:addClearToMultiModifier(multiModifier, filter1, filter2)
	local v88_ = self.densityMapModifiersClear
	if v88_ == nil then
		v88_ = {
			["modifier"] = DensityMapModifier.new(self.bitVectorMap, 0, self.numChannels, g_terrainNode)
		}
		self.densityMapModifiersClear = v88_
	end
	multiModifier:addExecuteSet(0, v88_.modifier, filter1, filter2)
end

function SeedRateMap:getSeedRateAtWorldPosition(x, z)
	local v92_ = MathUtil.round((x + g_currentMission.terrainSize * 0.5) / g_currentMission.terrainSize * self.sizeX + 0.5) - 1
	local v93_ = MathUtil.round((z + g_currentMission.terrainSize * 0.5) / g_currentMission.terrainSize * self.sizeY + 0.5) - 1
	return not self.coverMap:getIsUncoveredAtPos(v92_, v93_) and 0 or getBitVectorMapPoint(self.bitVectorMap, v92_, v93_, 0, self.numChannels)
end

-- Local values: fruitTypeData, soilTypeData, seedRateIndex, i
function SeedRateMap:getSeedRateYieldFactor(rawValue, fruitTypeIndex, soilTypeIndex)
	local v98_ = self.fruitTypes[fruitTypeIndex]
	if v98_ == nil then
		return 1, 1
	end
	local v99_ = v98_.soilTypes[soilTypeIndex]
	if v99_ == nil or v99_.bestYieldIndex == nil then
		return 1, 1
	end
	local v100_ = nil
	for v101_ = 1, #self.rateValues do
		if self.rateValues[v101_].value == rawValue then
			v100_ = v101_
			break
		end
	end
	if v100_ == nil or v99_.yields[v100_] == nil then
		return 1, 1
	else
		return v99_.yields[v100_], v99_.yields[v99_.bestYieldIndex]
	end
end

-- Local values: field, area, seedRateDesc, i
function SeedRateMap:debugSetSeedRateLevel(fieldId, seedRate)
	local v105_ = tonumber(fieldId)
	local v106_ = tonumber(seedRate)
	if v105_ == nil or v106_ == nil then
		Logging.error("SeedRateMap: Invalid parameters. Usage: pfSeedRateSet <fieldId> <seedRate>")
		return
	end
	local v107_ = g_fieldManager:getFieldById((tonumber(v105_)))
	if v107_ ~= nil and v107_.getDensityMapPolygon ~= nil then
		local v108_ = v107_:getDensityMapPolygon()
		local v109_ = nil
		for v110_ = 1, #self.rateValues do
			if self.rateValues[v110_].value == v106_ then
				v109_ = self.rateValues[v110_]
				break
			end
		end
		if v109_ ~= nil then
			self:updateSeedArea(v108_, nil, nil, nil, nil, nil, nil, false, v109_.value)
			Logging.info("SeedRateMap: Set seed rate of field %d to %d / %s", v105_, v109_.value, v109_.text)
			return
		end
		Logging.error("SeedRateMap: Invalid seed rate value %d", v106_)
	end
end

-- Local values: lastSeedRateMultiplier, lastSeedRateFound, lastSeedRateTarget
function SeedRateMap:updateLastYieldValues()
	local v112_ = self.lastSeedRateMultiplier
	local v113_ = self.lastSeedRateFound
	local v114_ = self.lastSeedRateTarget
	self.lastSeedRateMultiplier = nil
	self.lastSeedRateFound = nil
	self.lastSeedRateTarget = nil
	return v112_, v113_, v114_
end

-- Local values: seedRateMapId, i, rateValue, r, g, b
function SeedRateMap:buildOverlay(overlay, seedRateFilter, isColorBlindMode)
	resetDensityMapVisualizationOverlay(overlay)
	setOverlayColor(overlay, 1, 1, 1, 1)
	local v119_ = self.bitVectorMap
	for v120_ = 1, #self.rateValues do
		if seedRateFilter[v120_] then
			local v121_ = self.rateValues[v120_]
			local v122_, v123_, v124_
			if isColorBlindMode then
				v122_ = v121_.colorBlind[1]
				v123_ = v121_.colorBlind[2]
				v124_ = v121_.colorBlind[3]
			else
				v122_ = v121_.color[1]
				v123_ = v121_.color[2]
				v124_ = v121_.color[3]
			end
			setDensityMapVisualizationOverlayStateColor(overlay, v119_, 0, 0, 0, self.numChannels, v121_.value, v122_, v123_, v124_)
		end
	end
end

-- Local values: i, rateValue, rateValueToDisplay
function SeedRateMap:getDisplayValues()
	if self.valuesToDisplay == nil then
		self.valuesToDisplay = {}
		for v126_ = 1, #self.rateValues do
			local v127_ = self.rateValues[v126_]
			local v128_ = {
				["colors"] = {}
			}
			v128_.colors[true] = { v127_.colorBlind or v127_.color }
			v128_.colors[false] = { v127_.color }
			v128_.description = v127_.text
			local v129_ = self.valuesToDisplay
			table.insert(v129_, v128_)
		end
	end
	return self.valuesToDisplay
end

-- Local values: i
function SeedRateMap:getValueFilter()
	if self.valueFilter == nil then
		self.valueFilter = {}
		for _ = 1, #self.rateValues do
			local v131_ = self.valueFilter
			table.insert(v131_, true)
		end
	end
	return self.valueFilter
end

function SeedRateMap:getHelpLinePage()
	return 7
end

-- Local values: fruitTypeData
function SeedRateMap:getSeedRateByFruitTypeAndIndex(fruitTypeIndex, seedRateIndex)
	if fruitTypeIndex ~= nil then
		local v135_ = self.fruitTypes[fruitTypeIndex]
		if v135_ ~= nil then
			return v135_.seedRates[seedRateIndex]
		end
	end
	return 0
end

function SeedRateMap:getIsFruitTypeSupported(fruitTypeIndex)
	if fruitTypeIndex == nil then
		return false
	else
		return self.fruitTypes[fruitTypeIndex] ~= nil
	end
end

-- Local values: fruitTypeData, soilType
function SeedRateMap:getOptimalSeedRateByFruitTypeAndSoiltype(fruitTypeIndex, soilTypeIndex)
	if fruitTypeIndex ~= nil then
		local v141_ = self.fruitTypes[fruitTypeIndex]
		if v141_ ~= nil then
			local v142_ = v141_.soilTypes[soilTypeIndex]
			if v142_ ~= nil then
				return v142_.bestYieldIndex
			end
		end
	end
	return nil
end

-- Local values: row
function SeedRateMap:createHelpMenuSeedRateTableRow(contentBox, template, isHeader, cropName, text1, text2, text3, text4)
	local v152_ = template:clone(contentBox)
	if self.rowIndex % 2 == 0 then
		v152_:getDescendantByName("background"):setVisible(false)
	end
	if isHeader then
		v152_:getDescendantByName("cropName"):applyProfile("precisionFarmingSeedRateTextHeader", true)
		v152_:getDescendantByName("soil1"):applyProfile("precisionFarmingSeedRateTextHeader", true)
		v152_:getDescendantByName("soil2"):applyProfile("precisionFarmingSeedRateTextHeader", true)
		v152_:getDescendantByName("soil3"):applyProfile("precisionFarmingSeedRateTextHeader", true)
		v152_:getDescendantByName("soil4"):applyProfile("precisionFarmingSeedRateTextHeader", true)
	end
	v152_:getDescendantByName("cropName"):setText(cropName)
	v152_:getDescendantByName("soil1"):setText(text1)
	v152_:getDescendantByName("soil2"):setText(text2)
	v152_:getDescendantByName("soil3"):setText(text3)
	v152_:getDescendantByName("soil4"):setText(text4)
	v152_:updateAbsolutePosition()
	self.rowIndex = self.rowIndex + 1
end

-- Local values: _, fruitType, fillType, title, bestYieldText, j, soilType
function SeedRateMap:createHelpMenuSeedRateTable(contentBox, template)
	self.rowIndex = 0
	self:createHelpMenuSeedRateTableRow(contentBox, template, true, self.texts.cropNameHeader, self.texts.cropType1, self.texts.cropType2, self.texts.cropType3, self.texts.cropType4)
	for _, v156_ in pairs(self.fruitTypes) do
		local v157_ = g_fruitTypeManager:getFillTypeByFruitTypeIndex(v156_.index)
		if v157_ ~= nil then
			local v158_ = v157_.title
			local v159_ = {
				"",
				"",
				"",
				""
			}
			for v160_ = 1, #v156_.soilTypes do
				local v161_ = v156_.soilTypes[v160_]
				if v161_.bestYieldIndex ~= nil then
					v159_[v160_] = self:getRateLabelByIndex(v161_.bestYieldIndex)
				end
			end
			self:createHelpMenuSeedRateTableRow(contentBox, template, false, v158_, unpack(v159_))
		end
	end
	contentBox:invalidateLayout()
end
