-- Local values: MapOverlayGenerator_mt, NO_CALLBACK
MapOverlayGenerator = {}
local MapOverlayGenerator_mt = Class(MapOverlayGenerator)
MapOverlayGenerator.OVERLAY_TYPE = {
	["CROPS"] = 1,
	["GROWTH"] = 2,
	["SOIL"] = 3,
	["FARMLANDS"] = 4,
	["FIELDS"] = 5,
	["FARMLAND_SINGLE"] = 6
}
MapOverlayGenerator.OVERLAY_RESOLUTION = {
	["FOLIAGE_STATE"] = { 512, 512 },
	["FARMLANDS"] = { 512, 512 },
	["FIELDS"] = { 512, 512 }
}
MapOverlayGenerator.FIELD_REFRESH_INTERVAL = 5000
local function NO_CALLBACK() end

-- Upvalues: MapOverlayGenerator_mt, NO_CALLBACK
-- Local values: self, k, v
function MapOverlayGenerator.new(l10n, fruitTypeManager, fillTypeManager, farmlandManager, farmManager, weedSystem)
	-- upvalues: (copy) MapOverlayGenerator_mt, (copy) NO_CALLBACK
	local v8_ = MapOverlayGenerator_mt
	local v9_ = setmetatable({}, v8_)
	v9_.l10n = l10n
	v9_.fruitTypeManager = fruitTypeManager
	v9_.fillTypeManager = fillTypeManager
	v9_.farmlandManager = farmlandManager
	v9_.farmManager = farmManager
	v9_.missionFruitTypes = {}
	v9_.isColorBlindMode = nil
	local v10_ = createDensityMapVisualizationOverlay
	local v11_ = MapOverlayGenerator.OVERLAY_RESOLUTION.FOLIAGE_STATE
	v9_.foliageStateOverlay = v10_("foliageState", unpack(v9_:adjustedOverlayResolution(v11_)))
	local v12_ = createDensityMapVisualizationOverlay
	local v13_ = MapOverlayGenerator.OVERLAY_RESOLUTION.FARMLANDS
	v9_.farmlandStateOverlay = v12_("farmlandState", unpack(v9_:adjustedOverlayResolution(v13_, true)))
	local v14_ = createDensityMapVisualizationOverlay
	local v15_ = MapOverlayGenerator.OVERLAY_RESOLUTION.FIELDS
	v9_.fieldsOverlay = v14_("fields", unpack(v9_:adjustedOverlayResolution(v15_)))
	v9_.typeBuilderFunctionMap = {
		[MapOverlayGenerator.OVERLAY_TYPE.CROPS] = v9_.buildFruitTypeMapOverlay,
		[MapOverlayGenerator.OVERLAY_TYPE.GROWTH] = v9_.buildGrowthStateMapOverlay,
		[MapOverlayGenerator.OVERLAY_TYPE.SOIL] = v9_.buildSoilStateMapOverlay,
		[MapOverlayGenerator.OVERLAY_TYPE.FARMLANDS] = v9_.buildFarmlandsMapOverlay,
		[MapOverlayGenerator.OVERLAY_TYPE.FIELDS] = v9_.buildFieldsOverlay,
		[MapOverlayGenerator.OVERLAY_TYPE.FARMLAND_SINGLE] = v9_.buildSingleFarmlandsMapOverlay
	}
	v9_.overlayHandles = {
		[MapOverlayGenerator.OVERLAY_TYPE.CROPS] = v9_.foliageStateOverlay,
		[MapOverlayGenerator.OVERLAY_TYPE.GROWTH] = v9_.foliageStateOverlay,
		[MapOverlayGenerator.OVERLAY_TYPE.SOIL] = v9_.foliageStateOverlay,
		[MapOverlayGenerator.OVERLAY_TYPE.FARMLANDS] = v9_.farmlandStateOverlay,
		[MapOverlayGenerator.OVERLAY_TYPE.FIELDS] = v9_.fieldsOverlay,
		[MapOverlayGenerator.OVERLAY_TYPE.FARMLAND_SINGLE] = v9_.farmlandStateOverlay
	}
	v9_.currentOverlayHandle = nil
	v9_.overlayFinishedCallback = NO_CALLBACK
	v9_.overlayTypeCheckHash = {}
	for v16_, v17_ in pairs(MapOverlayGenerator.OVERLAY_TYPE) do
		v9_.overlayTypeCheckHash[v17_] = v16_
	end
	v9_.fieldColor = MapOverlayGenerator.FIELD_COLOR
	v9_.grassFieldColor = MapOverlayGenerator.FIELD_GRASS_COLOR
	v9_.fieldsRefreshTimer = 0
	v9_.fieldsOverlayUpdating = false
	return v9_
end

function MapOverlayGenerator:delete()
	self:reset()
	delete(self.foliageStateOverlay)
	delete(self.farmlandStateOverlay)
	delete(self.fieldsOverlay)
end

function MapOverlayGenerator:getFieldsOverlay()
	if self.fieldsOverlayIsReady then
		return self.fieldsOverlay
	else
		return nil
	end
end

-- Local values: profileClass
function MapOverlayGenerator:adjustedOverlayResolution(default, limitToTwo)
	local v22_ = Utils.getPerformanceClassId()
	if v22_ <= GS_PROFILE_LOW then
		return default
	else
		return GS_PROFILE_HIGH <= v22_ and (not limitToTwo and (not Platform.isMobile and (g_currentMission == nil or not (g_currentMission.missionDynamicInfo.isMultiplayer and g_currentMission:getIsServer())))) and { default[1] * 4, default[2] * 4 } or { default[1] * 2, default[2] * 2 }
	end
end

-- Local values: _, fruitType
function MapOverlayGenerator:setMissionFruitTypes(missionFruitTypes)
	self.missionFruitTypes = {}
	for _, v25_ in ipairs(missionFruitTypes) do
		local v26_ = self.missionFruitTypes
		local v27_ = {
			["foliageId"] = v25_.terrainDataPlaneId,
			["fruitTypeIndex"] = v25_.index,
			["shownOnMap"] = v25_.shownOnMap,
			["defaultColor"] = v25_.defaultMapColor,
			["colorBlindColor"] = v25_.colorBlindMapColor
		}
		table.insert(v26_, v27_)
	end
	self.displayCropTypes = self:getDisplayCropTypes()
	self.displayGrowthStates = self:getDisplayGrowthStates()
	self.displaySoilStates = self:getDisplaySoilStates()
end

function MapOverlayGenerator:updateStates()
	self.displayGrowthStates = self:getDisplayGrowthStates()
	self.displaySoilStates = self:getDisplaySoilStates()
end

function MapOverlayGenerator:setColorBlindMode(isColorBlindMode)
	self.isColorBlindMode = isColorBlindMode
end

function MapOverlayGenerator:setFieldColor(color, grassColor)
	self.fieldColor = color or MapOverlayGenerator.FIELD_COLOR
	self.grassFieldColor = grassColor or MapOverlayGenerator.FIELD_GRASS_COLOR
end

-- Local values: _, displayCropType, foliageId, color, r, g, b
function MapOverlayGenerator:buildFruitTypeMapOverlay(fruitTypeFilter)
	for _, v36_ in ipairs(self.displayCropTypes) do
		if fruitTypeFilter[v36_.fruitTypeIndex] then
			local v37_ = v36_.foliageId
			if v37_ ~= nil and v37_ ~= 0 then
				local v38_, v39_, v40_ = v36_.colors[self.isColorBlindMode]:unpack()
				setDensityMapVisualizationOverlayTypeColor(self.foliageStateOverlay, v37_, v38_, v39_, v40_)
			end
		end
	end
end

function MapOverlayGenerator:buildFieldsOverlay(fruitTypeFilter)
	self:buildFieldMapOverlay(self.fieldsOverlay)
end

-- Local values: _, displayCropType, foliageId, desc, color, color, _, cutState, maxGrowingState, colors, i, index, color, i, colors, i, index, mission, groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, fieldMask, cultivatorValue, color, color, plowValue, color, stubbleTillageValue, color, seedBedValue, rolledSeedBedValue
function MapOverlayGenerator:buildGrowthStateMapOverlay(growthStateFilter, fruitTypeFilter)
	for _, v45_ in ipairs(self.displayCropTypes) do
		if fruitTypeFilter[v45_.fruitTypeIndex] then
			local v46_ = v45_.foliageId
			local v47_ = self.fruitTypeManager:getFruitTypeByIndex(v45_.fruitTypeIndex)
			if v47_.maxHarvestingGrowthState >= 0 then
				if growthStateFilter[MapOverlayGenerator.GROWTH_STATE_INDEX.WITHERED] and v47_.witheredState ~= nil then
					local v48_ = self.displayGrowthStates[MapOverlayGenerator.GROWTH_STATE_INDEX.WITHERED].colors[self.isColorBlindMode][1]
					setDensityMapVisualizationOverlayGrowthStateColor(self.foliageStateOverlay, v46_, v47_.witheredState, v48_[1], v48_[2], v48_[3])
				end
				if growthStateFilter[MapOverlayGenerator.GROWTH_STATE_INDEX.HARVESTED] then
					local v49_ = self.displayGrowthStates[MapOverlayGenerator.GROWTH_STATE_INDEX.HARVESTED].colors[self.isColorBlindMode][1]
					for _, v50_ in pairs(v47_.harvestTransitions) do
						setDensityMapVisualizationOverlayGrowthStateColor(self.foliageStateOverlay, v46_, v50_, v49_[1], v49_[2], v49_[3])
					end
				end
				if growthStateFilter[MapOverlayGenerator.GROWTH_STATE_INDEX.GROWING] then
					local v51_ = v47_.minHarvestingGrowthState - 1
					if v47_.minPreparingGrowthState >= 0 then
						local v52_ = v47_.minPreparingGrowthState - 1
						v51_ = math.min(v51_, v52_)
					end
					local v53_ = self.displayGrowthStates[MapOverlayGenerator.GROWTH_STATE_INDEX.GROWING].colors[self.isColorBlindMode]
					for v54_ = 1, v51_ do
						local v55_ = #v53_ / v51_ * v54_
						local v56_ = math.floor(v55_)
						local v57_ = math.max(v56_, 1)
						setDensityMapVisualizationOverlayGrowthStateColor(self.foliageStateOverlay, v46_, v54_, v53_[v57_][1], v53_[v57_][2], v53_[v57_][3])
					end
				end
				if growthStateFilter[MapOverlayGenerator.GROWTH_STATE_INDEX.TOPPING] and v47_.minPreparingGrowthState >= 0 then
					local v58_ = self.displayGrowthStates[MapOverlayGenerator.GROWTH_STATE_INDEX.TOPPING].colors[self.isColorBlindMode][1]
					for v59_ = v47_.minPreparingGrowthState, v47_.maxPreparingGrowthState do
						setDensityMapVisualizationOverlayGrowthStateColor(self.foliageStateOverlay, v46_, v59_, v58_[1], v58_[2], v58_[3])
					end
				end
				if growthStateFilter[MapOverlayGenerator.GROWTH_STATE_INDEX.HARVEST] then
					local v60_ = self.displayGrowthStates[MapOverlayGenerator.GROWTH_STATE_INDEX.HARVEST].colors[self.isColorBlindMode]
					for v61_ = v47_.minHarvestingGrowthState, v47_.maxHarvestingGrowthState do
						local v62_ = v61_ - v47_.minHarvestingGrowthState + 1
						local v63_ = #v60_
						local v64_ = math.min(v62_, v63_)
						setDensityMapVisualizationOverlayGrowthStateColor(self.foliageStateOverlay, v46_, v61_, v60_[v64_][1], v60_[v64_][2], v60_[v64_][3])
					end
				end
			end
		end
	end
	local v65_, v66_, v67_ = g_currentMission.fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
	local v68_ = bit32.lshift(1, v67_) - 1
	local v69_ = bit32.lshift(v68_, v66_)
	if growthStateFilter[MapOverlayGenerator.GROWTH_STATE_INDEX.CULTIVATED] then
		local v70_ = FieldGroundType.getValueByType(FieldGroundType.CULTIVATED)
		local v71_ = self.displayGrowthStates[MapOverlayGenerator.GROWTH_STATE_INDEX.CULTIVATED].colors[self.isColorBlindMode][1]
		setDensityMapVisualizationOverlayStateColor(self.foliageStateOverlay, v65_, 0, v69_, v66_, v67_, v70_, v71_[1], v71_[2], v71_[3])
	end
	if growthStateFilter[MapOverlayGenerator.GROWTH_STATE_INDEX.PLOWED] then
		local v72_ = self.displayGrowthStates[MapOverlayGenerator.GROWTH_STATE_INDEX.PLOWED].colors[self.isColorBlindMode][1]
		local v73_ = FieldGroundType.getValueByType(FieldGroundType.PLOWED)
		setDensityMapVisualizationOverlayStateColor(self.foliageStateOverlay, v65_, 0, v69_, v66_, v67_, v73_, v72_[1], v72_[2], v72_[3])
	end
	if growthStateFilter[MapOverlayGenerator.GROWTH_STATE_INDEX.STUBBLE_TILLAGE] then
		local v74_ = self.displayGrowthStates[MapOverlayGenerator.GROWTH_STATE_INDEX.STUBBLE_TILLAGE].colors[self.isColorBlindMode][1]
		local v75_ = FieldGroundType.getValueByType(FieldGroundType.STUBBLE_TILLAGE)
		setDensityMapVisualizationOverlayStateColor(self.foliageStateOverlay, v65_, 0, v69_, v66_, v67_, v75_, v74_[1], v74_[2], v74_[3])
	end
	if growthStateFilter[MapOverlayGenerator.GROWTH_STATE_INDEX.SEEDBED] then
		local v76_ = self.displayGrowthStates[MapOverlayGenerator.GROWTH_STATE_INDEX.SEEDBED].colors[self.isColorBlindMode][1]
		local v77_ = FieldGroundType.getValueByType(FieldGroundType.SEEDBED)
		setDensityMapVisualizationOverlayStateColor(self.foliageStateOverlay, v65_, 0, v69_, v66_, v67_, v77_, v76_[1], v76_[2], v76_[3])
		local v78_ = FieldGroundType.getValueByType(FieldGroundType.ROLLED_SEEDBED)
		setDensityMapVisualizationOverlayStateColor(self.foliageStateOverlay, v65_, 0, v69_, v66_, v67_, v78_, v76_[1], v76_[2], v76_[3])
	end
end

-- Local values: mission, groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, fieldMask, weedSystem, weedMapId, _, _, mapColor, mapColorBlind, colors, k, data, stateColor, _, state, stoneSystem, stoneMapId, _, _, mapColor, mapColorBlind, colors, k, data, stateColor, _, state, color, mapId, plowLevelFirstChannel, plowLevelNumChannels, color, mapId, rollerLevelFirstChannel, rollerLevelNumChannels, color, mapId, mulchFirstChannel, mulchNumChannels, color, mapId, limeLevelFirstChannel, limeLevelNumChannels, colors, sprayMapId, sprayLevelFirstChannel, sprayLevelNumChannels, maxSprayLevel, level, color, color, mapId, firstChannel, numChannels
function MapOverlayGenerator:buildSoilStateMapOverlay(soilStateFilter)
	local v81_ = g_currentMission
	local v82_, v83_, v84_ = v81_.fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
	local v85_ = bit32.lshift(1, v84_) - 1
	local v86_ = bit32.lshift(v85_, v83_)
	if soilStateFilter[MapOverlayGenerator.SOIL_STATE_INDEX.WEEDS] and v81_.missionInfo.weedsEnabled then
		local v87_ = v81_.weedSystem
		if v87_ ~= nil and v87_:getMapHasWeed() then
			local v88_, _, _ = v87_:getDensityMapData()
			local v89_, v90_ = v87_:getColors()
			if self.isColorBlindMode then
				v89_ = v90_ or v89_
			end
			for _, v91_ in ipairs(v89_) do
				local v92_ = v91_.color
				for _, v93_ in ipairs(v91_.states) do
					setDensityMapVisualizationOverlayGrowthStateColor(self.foliageStateOverlay, v88_, v93_, v92_[1], v92_[2], v92_[3])
				end
			end
		end
	end
	if soilStateFilter[MapOverlayGenerator.SOIL_STATE_INDEX.STONES] and v81_.missionInfo.stonesEnabled then
		local v94_ = v81_.stoneSystem
		if v94_ ~= nil and v94_:getMapHasStones() then
			local v95_, _, _ = v94_:getDensityMapData()
			local v96_, v97_ = v94_:getColors()
			if self.isColorBlindMode then
				v96_ = v97_ or v96_
			end
			for _, v98_ in ipairs(v96_) do
				local v99_ = v98_.color
				for _, v100_ in ipairs(v98_.states) do
					setDensityMapVisualizationOverlayGrowthStateColor(self.foliageStateOverlay, v95_, v100_, v99_[1], v99_[2], v99_[3])
				end
			end
		end
	end
	if soilStateFilter[MapOverlayGenerator.SOIL_STATE_INDEX.NEEDS_PLOWING] and v81_.missionInfo.plowingRequiredEnabled then
		local v101_ = self.displaySoilStates[MapOverlayGenerator.SOIL_STATE_INDEX.NEEDS_PLOWING].colors[self.isColorBlindMode][1]
		local v102_, v103_, v104_ = v81_.fieldGroundSystem:getDensityMapData(FieldDensityMap.PLOW_LEVEL)
		setDensityMapVisualizationOverlayStateColor(self.foliageStateOverlay, v102_, v82_, v86_, v103_, v104_, 0, v101_[1], v101_[2], v101_[3])
	end
	if soilStateFilter[MapOverlayGenerator.SOIL_STATE_INDEX.NEEDS_ROLLING] then
		local v105_ = self.displaySoilStates[MapOverlayGenerator.SOIL_STATE_INDEX.NEEDS_ROLLING].colors[self.isColorBlindMode][1]
		local v106_, v107_, v108_ = v81_.fieldGroundSystem:getDensityMapData(FieldDensityMap.ROLLER_LEVEL)
		setDensityMapVisualizationOverlayStateColor(self.foliageStateOverlay, v106_, 0, v86_, v107_, v108_, 1, v105_[1], v105_[2], v105_[3])
	end
	if soilStateFilter[MapOverlayGenerator.SOIL_STATE_INDEX.MULCHED] then
		local v109_ = self.displaySoilStates[MapOverlayGenerator.SOIL_STATE_INDEX.MULCHED].colors[self.isColorBlindMode][1]
		local v110_, v111_, v112_ = v81_.fieldGroundSystem:getDensityMapData(FieldDensityMap.STUBBLE_SHRED_LEVEL)
		setDensityMapVisualizationOverlayStateColor(self.foliageStateOverlay, v110_, 0, v86_, v111_, v112_, 1, v109_[1], v109_[2], v109_[3])
	end
	if not Platform.isMobile and (soilStateFilter[MapOverlayGenerator.SOIL_STATE_INDEX.NEEDS_LIME] and v81_.missionInfo.limeRequired) then
		local v113_ = self.displaySoilStates[MapOverlayGenerator.SOIL_STATE_INDEX.NEEDS_LIME].colors[self.isColorBlindMode][1]
		local v114_, v115_, v116_ = v81_.fieldGroundSystem:getDensityMapData(FieldDensityMap.LIME_LEVEL)
		setDensityMapVisualizationOverlayStateColor(self.foliageStateOverlay, v114_, v82_, v86_, v115_, v116_, 0, v113_[1], v113_[2], v113_[3])
	end
	if soilStateFilter[MapOverlayGenerator.SOIL_STATE_INDEX.FERTILIZED] then
		local v117_ = self.displaySoilStates[MapOverlayGenerator.SOIL_STATE_INDEX.FERTILIZED].colors[self.isColorBlindMode]
		local v118_, v119_, v120_ = v81_.fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_LEVEL)
		for v121_ = 1, v81_.fieldGroundSystem:getMaxValue(FieldDensityMap.SPRAY_LEVEL) do
			local v122_ = #v117_
			local v123_ = v117_[math.min(v121_, v122_)]
			setDensityMapVisualizationOverlayStateColor(self.foliageStateOverlay, v118_, 0, v86_, v119_, v120_, v121_, v123_[1], v123_[2], v123_[3])
		end
	end
	if soilStateFilter[MapOverlayGenerator.SOIL_STATE_INDEX.WATERED] then
		local v124_ = self.displaySoilStates[MapOverlayGenerator.SOIL_STATE_INDEX.WATERED].colors[self.isColorBlindMode][1]
		local v125_, v126_, v127_ = v81_.fieldGroundSystem:getDensityMapData(FieldDensityMap.WATER_LEVEL)
		setDensityMapVisualizationOverlayStateColor(self.foliageStateOverlay, v125_, 0, v86_, v126_, v127_, 1, v124_[1], v124_[2], v124_[3])
	end
end

-- Local values: mission, groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, color, grassColor, i, groundType
function MapOverlayGenerator:buildFieldMapOverlay(overlay)
	local v130_, v131_, v132_ = g_currentMission.fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
	if v130_ ~= nil then
		local v133_ = self.fieldColor
		local v134_ = self.grassFieldColor
		for v135_ = 1, bit32.lshift(1, v132_) - 1 do
			local v136_ = FieldGroundType.getTypeByValue(v135_)
			if v136_ == FieldGroundType.GRASS or v136_ == FieldGroundType.GRASS_CUT then
				setDensityMapVisualizationOverlayStateColor(overlay, v130_, 0, 0, v131_, v132_, v135_, v134_[1], v134_[2], v134_[3])
			else
				setDensityMapVisualizationOverlayStateColor(overlay, v130_, 0, 0, v131_, v132_, v135_, v133_[1], v133_[2], v133_[3])
			end
		end
	end
end

-- Local values: map, farmlands, k, farmland, ownerFarmId, color, ownerFarm, profileClass
function MapOverlayGenerator:buildFarmlandsMapOverlay(selectedFarmland)
	local v139_ = self.farmlandManager:getLocalMap()
	local v140_ = self.farmlandManager:getFarmlands()
	setOverlayColor(self.farmlandStateOverlay, 1, 1, 1, MapOverlayGenerator.FARMLANDS_ALPHA)
	for v141_, v142_ in pairs(v140_) do
		local v143_ = self.farmlandManager:getFarmlandOwner(v142_.id)
		if v143_ ~= FarmlandManager.NOT_BUYABLE_FARM_ID then
			if selectedFarmland == nil or v142_.id ~= selectedFarmland.id then
				local v144_ = MapOverlayGenerator.COLOR.FIELD_UNOWNED
				if v142_.isOwned then
					local v145_ = self.farmManager:getFarmById(v143_)
					if v145_ ~= nil then
						v144_ = v145_:getColor()
					end
				end
				setDensityMapVisualizationOverlayStateColor(self.farmlandStateOverlay, v139_, 0, 0, 0, getBitVectorMapNumChannels(v139_), v141_, unpack(v144_))
			else
				local v146_ = setDensityMapVisualizationOverlayStateColor
				local v147_ = self.farmlandStateOverlay
				local v148_ = getBitVectorMapNumChannels(v139_)
				local v149_ = MapOverlayGenerator.COLOR.FIELD_SELECTED
				v146_(v147_, v139_, 0, 0, 0, v148_, v141_, unpack(v149_))
			end
		end
	end
	if Utils.getPerformanceClassId() >= GS_PROFILE_HIGH then
		local v150_ = setDensityMapVisualizationOverlayStateBorderColor
		local v151_ = self.farmlandStateOverlay
		local v152_ = getBitVectorMapNumChannels(v139_)
		local v153_ = MapOverlayGenerator.FARMLANDS_BORDER_THICKNESS
		local v154_ = FarmlandManager.NOT_BUYABLE_FARM_ID
		local v155_ = MapOverlayGenerator.COLOR.FIELD_BORDER
		v150_(v151_, v139_, 0, v152_, v153_, v154_, unpack(v155_))
	end
	self:buildFieldMapOverlay(self.farmlandStateOverlay)
end

-- Local values: map, farmlands, k, farmland
function MapOverlayGenerator:buildSingleFarmlandsMapOverlay(selectedFarmland)
	if selectedFarmland ~= nil then
		local v158_ = self.farmlandManager:getLocalMap()
		local v159_ = self.farmlandManager:getFarmlands()
		setOverlayColor(self.farmlandStateOverlay, 1, 1, 1, MapOverlayGenerator.FARMLANDS_ALPHA)
		for v160_, v161_ in pairs(v159_) do
			if v161_.id == selectedFarmland.id then
				local v162_ = setDensityMapVisualizationOverlayStateColor
				local v163_ = self.farmlandStateOverlay
				local v164_ = getBitVectorMapNumChannels(v158_)
				local v165_ = MapOverlayGenerator.COLOR.FIELD_SELECTED
				v162_(v163_, v158_, 0, 0, 0, v164_, v160_, unpack(v165_))
			end
		end
		self:buildFieldMapOverlay(self.farmlandStateOverlay)
	end
end

-- Upvalues: NO_CALLBACK
-- Local values: success, overlayHandle, builderFunction
function MapOverlayGenerator:generateOverlay(mapOverlayType, finishedCallback, overlayState, overlayState2)
	-- upvalues: (copy) NO_CALLBACK
	local v171_ = true
	if self.overlayTypeCheckHash[mapOverlayType] == nil then
		Logging.warning("Tried generating a map overlay with an invalid overlay type: [%s]", (tostring(mapOverlayType)))
		return false
	end
	local v172_ = self.overlayHandles[mapOverlayType]
	self.overlayFinishedCallback = finishedCallback or NO_CALLBACK
	resetDensityMapVisualizationOverlay(v172_)
	self.currentOverlayHandle = v172_
	self.typeBuilderFunctionMap[mapOverlayType](self, overlayState, overlayState2)
	generateDensityMapVisualizationOverlay(v172_)
	self:checkOverlayFinished()
	return v171_
end

function MapOverlayGenerator:generateFruitTypeOverlay(finishedCallback, fruitTypeFilter)
	return self:generateOverlay(MapOverlayGenerator.OVERLAY_TYPE.CROPS, finishedCallback, fruitTypeFilter)
end

function MapOverlayGenerator:generateFieldsOverlay(finishedCallback)
	return self:generateOverlay(MapOverlayGenerator.OVERLAY_TYPE.FIELDS, finishedCallback)
end

function MapOverlayGenerator:generateGrowthStateOverlay(finishedCallback, growthStateFilter, fruitTypeFilter)
	return self:generateOverlay(MapOverlayGenerator.OVERLAY_TYPE.GROWTH, finishedCallback, growthStateFilter, fruitTypeFilter)
end

function MapOverlayGenerator:generateSoilStateOverlay(finishedCallback, soilStateFilter)
	return self:generateOverlay(MapOverlayGenerator.OVERLAY_TYPE.SOIL, finishedCallback, soilStateFilter)
end

function MapOverlayGenerator:generateSingleFarmlandOverlay(finishedCallback, mapPosition)
	return self:generateOverlay(MapOverlayGenerator.OVERLAY_TYPE.FARMLAND_SINGLE, finishedCallback, mapPosition)
end

function MapOverlayGenerator:generateFarmlandOverlay(finishedCallback, mapPosition)
	return self:generateOverlay(MapOverlayGenerator.OVERLAY_TYPE.FARMLANDS, finishedCallback, mapPosition)
end

function MapOverlayGenerator:checkOverlayFinished()
	if self.currentOverlayHandle ~= nil and getIsDensityMapVisualizationOverlayReady(self.currentOverlayHandle) then
		self.overlayFinishedCallback(self.currentOverlayHandle)
		self.currentOverlayHandle = nil
	end
end

function MapOverlayGenerator:reset()
	resetDensityMapVisualizationOverlay(self.foliageStateOverlay)
	resetDensityMapVisualizationOverlay(self.farmlandStateOverlay)
	resetDensityMapVisualizationOverlay(self.fieldsOverlay)
	self.currentOverlayHandle = nil
end

function MapOverlayGenerator:update(dt)
	if not self.fieldsOverlayUpdating and g_time > self.fieldsRefreshTimer then
		self.fieldsOverlayUpdating = true
		self:generateFieldsOverlay(function(p194_)
			-- upvalues: (copy) self
			self.fieldsOverlay = p194_
			self.fieldsOverlayIsReady = true
			self.fieldsOverlayUpdating = false
			self.fieldsRefreshTimer = g_time + MapOverlayGenerator.FIELD_REFRESH_INTERVAL
		end)
	end
	self:checkOverlayFinished()
end

-- Local values: cropTypes, _, fruitType, fillableIndex, fillable, iconFilename, iconUVs, description
function MapOverlayGenerator:getDisplayCropTypes()
	local v196_ = {}
	for _, v197_ in ipairs(self.missionFruitTypes) do
		if v197_.shownOnMap then
			local v198_ = self.fruitTypeManager:getFillTypeIndexByFruitTypeIndex(v197_.fruitTypeIndex)
			local v199_ = self.fillTypeManager:getFillTypeByIndex(v198_)
			local v200_ = v199_.hudOverlayFilename
			local v201_ = Overlay.DEFAULT_UVS
			local v202_ = v199_.title
			local v203_ = {
				["colors"] = {
					[false] = v197_.defaultColor,
					[true] = v197_.colorBlindColor
				},
				["iconFilename"] = v200_,
				["iconUVs"] = v201_,
				["description"] = v202_,
				["fruitTypeIndex"] = v197_.fruitTypeIndex,
				["foliageId"] = v197_.foliageId
			}
			table.insert(v196_, v203_)
		end
	end
	return v196_
end

-- Local values: res
function MapOverlayGenerator:getDisplayGrowthStates()
	local v205_ = {}
	local v206_ = MapOverlayGenerator.GROWTH_STATE_INDEX.CULTIVATED
	local v207_ = {
		["colors"] = {
			[true] = { MapOverlayGenerator.FRUIT_COLOR_CULTIVATED[true] },
			[false] = { MapOverlayGenerator.FRUIT_COLOR_CULTIVATED[false] }
		},
		["description"] = self.l10n:getText(MapOverlayGenerator.L10N_SYMBOL.GROWTH_MAP_CULTIVATED)
	}
	v205_[v206_] = v207_
	local v208_ = MapOverlayGenerator.GROWTH_STATE_INDEX.STUBBLE_TILLAGE
	local v209_ = {
		["colors"] = {
			[true] = { MapOverlayGenerator.FRUIT_COLOR_STUBBLE_TILLAGE[true] },
			[false] = { MapOverlayGenerator.FRUIT_COLOR_STUBBLE_TILLAGE[false] }
		},
		["description"] = self.l10n:getText(MapOverlayGenerator.L10N_SYMBOL.GROWTH_MAP_STUBBLE_TILLAGE)
	}
	v205_[v208_] = v209_
	local v210_ = MapOverlayGenerator.GROWTH_STATE_INDEX.SEEDBED
	local v211_ = {
		["colors"] = {
			[true] = { MapOverlayGenerator.FRUIT_COLOR_SEEDBED[true] },
			[false] = { MapOverlayGenerator.FRUIT_COLOR_SEEDBED[false] }
		},
		["description"] = self.l10n:getText(MapOverlayGenerator.L10N_SYMBOL.GROWTH_MAP_SEEDBED)
	}
	v205_[v210_] = v211_
	v205_[MapOverlayGenerator.GROWTH_STATE_INDEX.GROWING] = {
		["colors"] = MapOverlayGenerator.FRUIT_COLORS_GROWING,
		["description"] = self.l10n:getText(MapOverlayGenerator.L10N_SYMBOL.GROWTH_MAP_GROWING)
	}
	v205_[MapOverlayGenerator.GROWTH_STATE_INDEX.HARVEST] = {
		["colors"] = MapOverlayGenerator.FRUIT_COLORS_HARVEST,
		["description"] = self.l10n:getText(MapOverlayGenerator.L10N_SYMBOL.GROWTH_MAP_HARVEST)
	}
	local v212_ = MapOverlayGenerator.GROWTH_STATE_INDEX.HARVESTED
	local v213_ = {
		["colors"] = {
			[true] = { MapOverlayGenerator.FRUIT_COLOR_CUT },
			[false] = { MapOverlayGenerator.FRUIT_COLOR_CUT }
		},
		["description"] = self.l10n:getText(MapOverlayGenerator.L10N_SYMBOL.GROWTH_MAP_HARVESTED)
	}
	v205_[v212_] = v213_
	local v214_ = MapOverlayGenerator.GROWTH_STATE_INDEX.TOPPING
	local v215_ = {
		["colors"] = {
			[true] = { MapOverlayGenerator.FRUIT_COLOR_REMOVE_TOPS[true] },
			[false] = { MapOverlayGenerator.FRUIT_COLOR_REMOVE_TOPS[false] }
		},
		["description"] = self.l10n:getText(MapOverlayGenerator.L10N_SYMBOL.GROWTH_MAP_TOPPING)
	}
	v205_[v214_] = v215_
	local v216_ = MapOverlayGenerator.GROWTH_STATE_INDEX.PLOWED
	local v217_ = {
		["colors"] = {
			[true] = { MapOverlayGenerator.FRUIT_COLOR_PLOWED[true] },
			[false] = { MapOverlayGenerator.FRUIT_COLOR_PLOWED[false] }
		},
		["description"] = self.l10n:getText(MapOverlayGenerator.L10N_SYMBOL.GROWTH_MAP_PLOWED)
	}
	v205_[v216_] = v217_
	if Platform.gameplay.supportsWithering then
		local v218_ = MapOverlayGenerator.GROWTH_STATE_INDEX.WITHERED
		local v219_ = {
			["colors"] = {
				[true] = { MapOverlayGenerator.FRUIT_COLOR_WITHERED[true] },
				[false] = { MapOverlayGenerator.FRUIT_COLOR_WITHERED[false] }
			},
			["description"] = self.l10n:getText(MapOverlayGenerator.L10N_SYMBOL.GROWTH_MAP_WITHERED)
		}
		v205_[v218_] = v219_
	end
	return v205_
end

-- Local values: fertilizerColors, mission, maxFertilizerStates, colorBlind, colors, i, color, res, weedSystem, mapColor, mapColorBlind, description, colors, k, data, stoneSystem, mapColor, mapColorBlind, description, colors, k, data
function MapOverlayGenerator:getDisplaySoilStates()
	local v221_ = g_currentMission
	local v222_ = v221_.fieldGroundSystem:getMaxValue(FieldDensityMap.SPRAY_LEVEL)
	local v223_ = {
		[true] = {},
		[false] = {}
	}
	for v224_, v225_ in pairs(MapOverlayGenerator.FRUIT_COLORS_FERTILIZED) do
		for v226_ = #v225_, 1, -1 do
			local v227_ = v225_[v226_]
			local v228_ = v223_[v224_]
			table.insert(v228_, 1, v227_)
			if #v223_[v224_] == v222_ then
				break
			end
		end
	end
	local v229_ = {
		[MapOverlayGenerator.SOIL_STATE_INDEX.FERTILIZED] = {
			["colors"] = v223_,
			["description"] = self.l10n:getText(MapOverlayGenerator.L10N_SYMBOL.SOIL_MAP_FERTILIZED),
			["isActive"] = true
		}
	}
	if Platform.gameplay.usePlowCounter and v221_.missionInfo.plowingRequiredEnabled then
		local v230_ = MapOverlayGenerator.SOIL_STATE_INDEX.NEEDS_PLOWING
		local v231_ = {
			["colors"] = {
				[true] = { MapOverlayGenerator.FRUIT_COLOR_NEEDS_PLOWING[true] },
				[false] = { MapOverlayGenerator.FRUIT_COLOR_NEEDS_PLOWING[false] }
			},
			["description"] = self.l10n:getText(MapOverlayGenerator.L10N_SYMBOL.SOIL_MAP_NEED_PLOWING),
			["isActive"] = v221_.missionInfo.plowingRequiredEnabled
		}
		v229_[v230_] = v231_
	end
	if Platform.gameplay.useLimeCounter and v221_.missionInfo.limeRequired then
		local v232_ = MapOverlayGenerator.SOIL_STATE_INDEX.NEEDS_LIME
		local v233_ = {
			["colors"] = {
				[true] = { MapOverlayGenerator.FRUIT_COLOR_NEEDS_LIME[true] },
				[false] = { MapOverlayGenerator.FRUIT_COLOR_NEEDS_LIME[false] }
			},
			["description"] = self.l10n:getText(MapOverlayGenerator.L10N_SYMBOL.SOIL_MAP_NEED_LIME),
			["isActive"] = v221_.missionInfo.limeRequired
		}
		v229_[v232_] = v233_
	end
	if Platform.gameplay.useRolling then
		local v234_ = MapOverlayGenerator.SOIL_STATE_INDEX.NEEDS_ROLLING
		local v235_ = {
			["colors"] = {
				[true] = { MapOverlayGenerator.FRUIT_COLOR_NEEDS_ROLLING[true] },
				[false] = { MapOverlayGenerator.FRUIT_COLOR_NEEDS_ROLLING[false] }
			},
			["description"] = self.l10n:getText(MapOverlayGenerator.L10N_SYMBOL.SOIL_MAP_NEED_ROLLING),
			["isActive"] = true
		}
		v229_[v234_] = v235_
	end
	if Platform.gameplay.useStubbleShred then
		local v236_ = MapOverlayGenerator.SOIL_STATE_INDEX.MULCHED
		local v237_ = {
			["colors"] = {
				[true] = { MapOverlayGenerator.FRUIT_COLOR_MULCHED[true] },
				[false] = { MapOverlayGenerator.FRUIT_COLOR_MULCHED[false] }
			},
			["description"] = self.l10n:getText(MapOverlayGenerator.L10N_SYMBOL.SOIL_MAP_MULCHED),
			["isActive"] = true
		}
		v229_[v236_] = v237_
	end
	local v238_ = MapOverlayGenerator.SOIL_STATE_INDEX.WATERED
	local v239_ = {
		["colors"] = {
			[true] = { MapOverlayGenerator.FRUIT_COLOR_WATERED[true] },
			[false] = { MapOverlayGenerator.FRUIT_COLOR_WATERED[false] }
		},
		["description"] = self.l10n:getText(MapOverlayGenerator.L10N_SYMBOL.SOIL_MAP_WATERED),
		["isActive"] = true
	}
	v229_[v238_] = v239_
	local v240_ = v221_.weedSystem
	if v240_ ~= nil and (v240_:getMapHasWeed() and v221_.missionInfo.weedsEnabled) then
		local v241_, v242_ = v240_:getColors()
		local v243_ = v240_:getTitle() or ""
		local v244_ = {
			[true] = {},
			[false] = {}
		}
		for v245_, v246_ in ipairs(v241_) do
			local v247_ = v244_[true]
			local v248_ = v242_[v245_].color
			table.insert(v247_, v248_)
			local v249_ = v244_[false]
			local v250_ = v246_.color
			table.insert(v249_, v250_)
		end
		v229_[MapOverlayGenerator.SOIL_STATE_INDEX.WEEDS] = {
			["colors"] = v244_,
			["description"] = v243_,
			["isActive"] = v221_.missionInfo.weedsEnabled
		}
	end
	local v251_ = v221_.stoneSystem
	if v251_ ~= nil and (v251_:getMapHasStones() and v221_.missionInfo.stonesEnabled) then
		local v252_, v253_ = v251_:getColors()
		local v254_ = v251_:getTitle() or ""
		local v255_ = {
			[true] = {},
			[false] = {}
		}
		for v256_, v257_ in ipairs(v252_) do
			local v258_ = v255_[true]
			local v259_ = v253_[v256_].color
			table.insert(v258_, v259_)
			local v260_ = v255_[false]
			local v261_ = v257_.color
			table.insert(v260_, v261_)
		end
		v229_[MapOverlayGenerator.SOIL_STATE_INDEX.STONES] = {
			["colors"] = v255_,
			["description"] = v254_,
			["isActive"] = v221_.missionInfo.stonesEnabled
		}
	end
	return v229_
end
MapOverlayGenerator.GROWTH_STATE_INDEX = {
	["STUBBLE_TILLAGE"] = 1,
	["CULTIVATED"] = 2,
	["PLOWED"] = 3,
	["SEEDBED"] = 4,
	["GROWING"] = 5,
	["HARVEST"] = 6,
	["HARVESTED"] = 7,
	["TOPPING"] = 8,
	["WITHERED"] = 9
}
MapOverlayGenerator.SOIL_STATE_INDEX = {
	["WEEDS"] = 1,
	["FERTILIZED"] = 2,
	["NEEDS_PLOWING"] = 3,
	["NEEDS_LIME"] = 4,
	["NEEDS_ROLLING"] = 5,
	["MULCHED"] = 6,
	["STONES"] = 7,
	["WATERED"] = 8
}
MapOverlayGenerator.FRUIT_COLORS_GROWING = {}
if Platform.isMobile then
	MapOverlayGenerator.FRUIT_COLORS_GROWING[false] = {
		{
			0.227,
			0.5711,
			0.0176,
			1
		},
		{
			0.0823,
			0.3006,
			0.011,
			1
		},
		{
			0.0048,
			0.0844,
			0.0048,
			1
		}
	}
	MapOverlayGenerator.FRUIT_COLORS_GROWING[true] = {
		{
			1,
			0.9473,
			0.227,
			1
		},
		{
			0.5583,
			0.4735,
			0.007,
			1
		},
		{
			0.2122,
			0.1779,
			0.0027,
			1
		}
	}
else
	MapOverlayGenerator.FRUIT_COLORS_GROWING[false] = {
		{
			0.227,
			0.5711,
			0.0176,
			1
		},
		{
			0.1683,
			0.4678,
			0.0152,
			1
		},
		{
			0.1221,
			0.3813,
			0.013,
			1
		},
		{
			0.0823,
			0.3006,
			0.011,
			1
		},
		{
			0.0529,
			0.2346,
			0.0091,
			1
		},
		{
			0.0296,
			0.1746,
			0.0075,
			1
		},
		{
			0.0144,
			0.1248,
			0.006,
			1
		},
		{
			0.0048,
			0.0844,
			0.0048,
			1
		}
	}
	MapOverlayGenerator.FRUIT_COLORS_GROWING[true] = {
		{
			1,
			0.9473,
			0.227,
			1
		},
		{
			1,
			0.9046,
			0.013,
			1
		},
		{
			0.5583,
			0.4735,
			0.007,
			1
		},
		{
			0.2122,
			0.1779,
			0.0027,
			1
		}
	}
end
MapOverlayGenerator.FRUIT_COLORS_HARVEST = {}
MapOverlayGenerator.FRUIT_COLORS_HARVEST[false] = {
	{
		0.7758,
		0.3095,
		0.013,
		1
	}
}
MapOverlayGenerator.FRUIT_COLORS_HARVEST[true] = {
	{
		0.0561,
		0.1384,
		0.5841,
		1
	}
}
MapOverlayGenerator.FRUIT_COLORS_FERTILIZED = {}
if Platform.isMobile then
	MapOverlayGenerator.FRUIT_COLORS_FERTILIZED[false] = {
		{
			0.0091,
			0.0931,
			0.5841,
			1
		},
		{
			0.0018,
			0.0382,
			0.2961,
			1
		}
	}
	MapOverlayGenerator.FRUIT_COLORS_FERTILIZED[true] = {
		{
			0.0086,
			0.0976,
			0.5776,
			1
		},
		{
			0,
			0.0409,
			0.2918,
			1
		}
	}
else
	MapOverlayGenerator.FRUIT_COLORS_FERTILIZED[false] = {
		{
			0.0595,
			0.2086,
			0.8227,
			1
		},
		{
			0.0091,
			0.0931,
			0.5841,
			1
		},
		{
			0.0018,
			0.0382,
			0.2961,
			1
		}
	}
	MapOverlayGenerator.FRUIT_COLORS_FERTILIZED[true] = {
		{
			0.0976,
			0.2086,
			0.8148,
			1
		},
		{
			0.0086,
			0.0976,
			0.5776,
			1
		},
		{
			0,
			0.0409,
			0.2918,
			1
		}
	}
end
MapOverlayGenerator.FRUIT_COLORS_DISABLED = {
	{
		0.4,
		0.4,
		0.4,
		1
	},
	{
		0.3,
		0.3,
		0.3,
		1
	},
	{
		0.2,
		0.2,
		0.2,
		1
	},
	{
		0.1,
		0.1,
		0.1,
		1
	}
}
MapOverlayGenerator.FRUIT_COLOR_NEEDS_PLOWING = {}
MapOverlayGenerator.FRUIT_COLOR_NEEDS_PLOWING[false] = {
	0.6172,
	0.051,
	0.051,
	1
}
MapOverlayGenerator.FRUIT_COLOR_NEEDS_PLOWING[true] = {
	1,
	0.8632,
	0.0232,
	1
}
MapOverlayGenerator.FRUIT_COLOR_NEEDS_LIME = {}
MapOverlayGenerator.FRUIT_COLOR_NEEDS_LIME[false] = {
	0.0815,
	0.6584,
	0.4198,
	1
}
MapOverlayGenerator.FRUIT_COLOR_NEEDS_LIME[true] = {
	0.6795,
	0.6867,
	0.7231,
	1
}
MapOverlayGenerator.FRUIT_COLOR_NEEDS_ROLLING = {}
MapOverlayGenerator.FRUIT_COLOR_NEEDS_ROLLING[false] = {
	0.0967,
	0.3758,
	0.7084,
	1
}
MapOverlayGenerator.FRUIT_COLOR_NEEDS_ROLLING[true] = {
	0.2918,
	0.3564,
	0.7011,
	1
}
MapOverlayGenerator.FRUIT_COLOR_MULCHED = {}
MapOverlayGenerator.FRUIT_COLOR_MULCHED[false] = {
	0.0908,
	0.0467,
	0.0865,
	1
}
MapOverlayGenerator.FRUIT_COLOR_MULCHED[true] = {
	0.0469,
	0.0484,
	0.0597,
	1
}
MapOverlayGenerator.FRUIT_COLOR_REMOVE_TOPS = {}
MapOverlayGenerator.FRUIT_COLOR_REMOVE_TOPS[false] = {
	0.7011,
	0.0452,
	0.0123,
	1
}
MapOverlayGenerator.FRUIT_COLOR_REMOVE_TOPS[true] = {
	0.3231,
	0.3467,
	0.4621,
	1
}
MapOverlayGenerator.FRUIT_COLOR_WITHERED = {}
MapOverlayGenerator.FRUIT_COLOR_WITHERED[false] = {
	0.1441,
	0.0452,
	0.0123,
	1
}
MapOverlayGenerator.FRUIT_COLOR_WITHERED[true] = {
	0.1195,
	0.1144,
	0.0908,
	1
}
MapOverlayGenerator.FRUIT_COLOR_CULTIVATED = {}
MapOverlayGenerator.FRUIT_COLOR_CULTIVATED[false] = {
	0.0967,
	0.3758,
	0.7084,
	1
}
MapOverlayGenerator.FRUIT_COLOR_CULTIVATED[true] = {
	0.2918,
	0.3564,
	0.7011,
	1
}
MapOverlayGenerator.FRUIT_COLOR_STUBBLE_TILLAGE = {}
MapOverlayGenerator.FRUIT_COLOR_STUBBLE_TILLAGE[false] = {
	0.1967,
	0.4758,
	0.3084,
	1
}
MapOverlayGenerator.FRUIT_COLOR_STUBBLE_TILLAGE[true] = {
	0.3918,
	0.4564,
	0.3011,
	1
}
MapOverlayGenerator.FRUIT_COLOR_SEEDBED = {}
MapOverlayGenerator.FRUIT_COLOR_SEEDBED[false] = {
	0.0815,
	0.6584,
	0.4198,
	1
}
MapOverlayGenerator.FRUIT_COLOR_SEEDBED[true] = {
	0.6795,
	0.6867,
	0.7231,
	1
}
MapOverlayGenerator.FRUIT_COLOR_PLOWED = {}
MapOverlayGenerator.FRUIT_COLOR_PLOWED[false] = {
	0.0908,
	0.0467,
	0.0865,
	1
}
MapOverlayGenerator.FRUIT_COLOR_PLOWED[true] = {
	0.0469,
	0.0484,
	0.0597,
	1
}
MapOverlayGenerator.FRUIT_COLOR_SOWN = {}
MapOverlayGenerator.FRUIT_COLOR_SOWN[false] = {
	0.9301,
	0.6404,
	0.0439,
	1
}
MapOverlayGenerator.FRUIT_COLOR_SOWN[true] = {
	0.7681,
	0.6514,
	0.0529,
	1
}
MapOverlayGenerator.FRUIT_COLOR_CUT = {
	0.2647,
	0.1038,
	0.358,
	1
}
MapOverlayGenerator.FRUIT_COLOR_DISABLED = {
	0.2,
	0.2,
	0.2,
	1
}
MapOverlayGenerator.FRUIT_COLOR_WATERED = {}
MapOverlayGenerator.FRUIT_COLOR_WATERED[false] = {
	0.0967,
	0.3758,
	0.7084,
	1
}
MapOverlayGenerator.FRUIT_COLOR_WATERED[true] = {
	0.2918,
	0.3564,
	0.7011,
	1
}
MapOverlayGenerator.FIELD_COLOR = { 0.15, 0.1195, 0.0953 }
MapOverlayGenerator.FIELD_GRASS_COLOR = { 0.147, 0.1441, 0.0823 }
MapOverlayGenerator.COLOR = {
	["FIELD_UNOWNED"] = { 0, 0, 0 },
	["FIELD_SELECTED"] = { 0.07818, 0.16826, 0.00334 },
	["FIELD_BORDER"] = { 0.2, 0.2, 0.2 }
}
MapOverlayGenerator.FARMLANDS_ALPHA = 0.5
MapOverlayGenerator.FARMLANDS_BORDER_THICKNESS = 3
MapOverlayGenerator.L10N_SYMBOL = {
	["GROWTH_MAP_CULTIVATED"] = "ui_growthMapCultivated",
	["GROWTH_MAP_GROWING"] = "ui_growthMapGrowing",
	["GROWTH_MAP_HARVEST"] = "ui_growthMapReadyToHarvest",
	["GROWTH_MAP_HARVESTED"] = "ui_growthMapCut",
	["GROWTH_MAP_PLOWED"] = "ui_growthMapPlowed",
	["GROWTH_MAP_TOPPING"] = "ui_growthMapReadyToPrepareForHarvest",
	["GROWTH_MAP_WITHERED"] = "ui_growthMapWithered",
	["GROWTH_MAP_STUBBLE_TILLAGE"] = "ui_growthMapStubbleTillage",
	["GROWTH_MAP_SEEDBED"] = "ui_growthMapSeedbed",
	["SOIL_MAP_FERTILIZED"] = "ui_growthMapFertilized",
	["SOIL_MAP_NEED_PLOWING"] = "ui_growthMapNeedsPlowing",
	["SOIL_MAP_NEED_LIME"] = "ui_growthMapNeedsLime",
	["SOIL_MAP_NEED_ROLLING"] = "ui_growthMapNeedsRolling",
	["SOIL_MAP_MULCHED"] = "ui_growthMapMulched",
	["SOIL_MAP_WATERED"] = "ui_growthMapWatered"
}
