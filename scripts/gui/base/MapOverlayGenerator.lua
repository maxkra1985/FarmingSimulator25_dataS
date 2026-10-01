MapOverlayGenerator = {}
local MapOverlayGenerator_mt = Class(MapOverlayGenerator)
MapOverlayGenerator.OVERLAY_TYPE = { CROPS = 1, GROWTH = 2, SOIL = 3, FARMLANDS = 4, FIELDS = 5, FARMLAND_SINGLE = 6 }
MapOverlayGenerator.OVERLAY_RESOLUTION = { FOLIAGE_STATE = { 512, 512 }, FARMLANDS = { 512, 512 }, FIELDS = { 512, 512 } }
MapOverlayGenerator.FIELD_REFRESH_INTERVAL = 5000
local NO_CALLBACK = function() end
function MapOverlayGenerator.new(l10n, fruitTypeManager, fillTypeManager, farmlandManager, farmManager, weedSystem)
	local self = setmetatable({}, MapOverlayGenerator_mt)
	self.l10n = l10n
	self.fruitTypeManager = fruitTypeManager
	self.fillTypeManager = fillTypeManager
	self.farmlandManager = farmlandManager
	self.farmManager = farmManager
	self.missionFruitTypes = {}
	self.isColorBlindMode = nil
	self.foliageStateOverlay = createDensityMapVisualizationOverlay("foliageState", unpack(self:adjustedOverlayResolution(MapOverlayGenerator.OVERLAY_RESOLUTION.FOLIAGE_STATE)))
	self.farmlandStateOverlay = createDensityMapVisualizationOverlay("farmlandState", unpack(self:adjustedOverlayResolution(MapOverlayGenerator.OVERLAY_RESOLUTION.FARMLANDS, true)))
	self.fieldsOverlay = createDensityMapVisualizationOverlay("fields", unpack(self:adjustedOverlayResolution(MapOverlayGenerator.OVERLAY_RESOLUTION.FIELDS)))
	self.typeBuilderFunctionMap = { [MapOverlayGenerator.OVERLAY_TYPE.CROPS] = self.buildFruitTypeMapOverlay, [MapOverlayGenerator.OVERLAY_TYPE.GROWTH] = self.buildGrowthStateMapOverlay, [MapOverlayGenerator.OVERLAY_TYPE.SOIL] = self.buildSoilStateMapOverlay, [MapOverlayGenerator.OVERLAY_TYPE.FARMLANDS] = self.buildFarmlandsMapOverlay, [MapOverlayGenerator.OVERLAY_TYPE.FIELDS] = self.buildFieldsOverlay, [MapOverlayGenerator.OVERLAY_TYPE.FARMLAND_SINGLE] = self.buildSingleFarmlandsMapOverlay }
	self.overlayHandles = { [MapOverlayGenerator.OVERLAY_TYPE.CROPS] = self.foliageStateOverlay, [MapOverlayGenerator.OVERLAY_TYPE.GROWTH] = self.foliageStateOverlay, [MapOverlayGenerator.OVERLAY_TYPE.SOIL] = self.foliageStateOverlay, [MapOverlayGenerator.OVERLAY_TYPE.FARMLANDS] = self.farmlandStateOverlay, [MapOverlayGenerator.OVERLAY_TYPE.FIELDS] = self.fieldsOverlay, [MapOverlayGenerator.OVERLAY_TYPE.FARMLAND_SINGLE] = self.farmlandStateOverlay }
	self.currentOverlayHandle = nil
	self.overlayFinishedCallback = NO_CALLBACK
	self.overlayTypeCheckHash = {}
	for k, v in pairs(MapOverlayGenerator.OVERLAY_TYPE) do
		self.overlayTypeCheckHash[v] = k
	end
	self.fieldColor = MapOverlayGenerator.FIELD_COLOR
	self.grassFieldColor = MapOverlayGenerator.FIELD_GRASS_COLOR
	self.fieldsRefreshTimer = 0
	self.fieldsOverlayUpdating = false
	return self
end
function MapOverlayGenerator:delete()
	self:reset()
	delete(self.foliageStateOverlay)
	delete(self.farmlandStateOverlay)
	delete(self.fieldsOverlay)
end
function MapOverlayGenerator:getFieldsOverlay()
	if not self.fieldsOverlayIsReady then
		return nil
	else
		return self.fieldsOverlay
	end
end
function MapOverlayGenerator:adjustedOverlayResolution(default, limitToTwo)
	local profileClass = Utils.getPerformanceClassId()
	if profileClass <= GS_PROFILE_LOW then
		return default
	elseif GS_PROFILE_HIGH <= profileClass and (not limitToTwo and (not Platform.isMobile and (g_currentMission == nil or not g_currentMission.missionDynamicInfo.isMultiplayer or not g_currentMission:getIsServer()))) then
		return { default[1] * 4, default[2] * 4 }
	else
		return { default[1] * 2, default[2] * 2 }
	end
end
function MapOverlayGenerator:setMissionFruitTypes(missionFruitTypes)
	self.missionFruitTypes = {}
	for _, fruitType in ipairs(missionFruitTypes) do
		table.insert(self.missionFruitTypes, { foliageId = fruitType.terrainDataPlaneId, fruitTypeIndex = fruitType.index, shownOnMap = fruitType.shownOnMap, defaultColor = fruitType.defaultMapColor, colorBlindColor = fruitType.colorBlindMapColor })
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
function MapOverlayGenerator:buildFruitTypeMapOverlay(fruitTypeFilter)
	for _, displayCropType in ipairs(self.displayCropTypes) do
		if fruitTypeFilter[displayCropType.fruitTypeIndex] then
			local foliageId = displayCropType.foliageId
			if foliageId == nil or foliageId == 0 then
				continue
			end
			local color = displayCropType.colors[self.isColorBlindMode]
			local r, g, b = color:unpack()
			setDensityMapVisualizationOverlayTypeColor(self.foliageStateOverlay, foliageId, r, g, b)
		end
	end
end
function MapOverlayGenerator:buildFieldsOverlay(fruitTypeFilter)
	self:buildFieldMapOverlay(self.fieldsOverlay)
end
function MapOverlayGenerator:buildGrowthStateMapOverlay(growthStateFilter, fruitTypeFilter)
	for _, displayCropType in ipairs(self.displayCropTypes) do
		if fruitTypeFilter[displayCropType.fruitTypeIndex] then
			local foliageId = displayCropType.foliageId
			local desc = self.fruitTypeManager:getFruitTypeByIndex(displayCropType.fruitTypeIndex)
			if 0 <= desc.maxHarvestingGrowthState then
				if growthStateFilter[MapOverlayGenerator.GROWTH_STATE_INDEX.WITHERED] and desc.witheredState ~= nil then
					local color = self.displayGrowthStates[MapOverlayGenerator.GROWTH_STATE_INDEX.WITHERED].colors[self.isColorBlindMode][1]
					setDensityMapVisualizationOverlayGrowthStateColor(self.foliageStateOverlay, foliageId, desc.witheredState, color[1], color[2], color[3])
				end
				if growthStateFilter[MapOverlayGenerator.GROWTH_STATE_INDEX.HARVESTED] then
					local color = self.displayGrowthStates[MapOverlayGenerator.GROWTH_STATE_INDEX.HARVESTED].colors[self.isColorBlindMode][1]
					for _, cutState in pairs(desc.harvestTransitions) do
						setDensityMapVisualizationOverlayGrowthStateColor(self.foliageStateOverlay, foliageId, cutState, color[1], color[2], color[3])
					end
				end
				if growthStateFilter[MapOverlayGenerator.GROWTH_STATE_INDEX.GROWING] then
					local maxGrowingState = desc.minHarvestingGrowthState - 1
					if 0 <= desc.minPreparingGrowthState then
						maxGrowingState = math.min(maxGrowingState, desc.minPreparingGrowthState - 1)
					end
					local colors = self.displayGrowthStates[MapOverlayGenerator.GROWTH_STATE_INDEX.GROWING].colors[self.isColorBlindMode]
					for i = 1, maxGrowingState do
						local index = math.max(math.floor(#colors / maxGrowingState * i), 1)
						setDensityMapVisualizationOverlayGrowthStateColor(self.foliageStateOverlay, foliageId, i, colors[index][1], colors[index][2], colors[index][3])
					end
				end
				if growthStateFilter[MapOverlayGenerator.GROWTH_STATE_INDEX.TOPPING] and 0 <= desc.minPreparingGrowthState then
					local color = self.displayGrowthStates[MapOverlayGenerator.GROWTH_STATE_INDEX.TOPPING].colors[self.isColorBlindMode][1]
					for i = desc.minPreparingGrowthState, desc.maxPreparingGrowthState do
						setDensityMapVisualizationOverlayGrowthStateColor(self.foliageStateOverlay, foliageId, i, color[1], color[2], color[3])
					end
				end
				if growthStateFilter[MapOverlayGenerator.GROWTH_STATE_INDEX.HARVEST] then
					local colors = self.displayGrowthStates[MapOverlayGenerator.GROWTH_STATE_INDEX.HARVEST].colors[self.isColorBlindMode]
					for i = desc.minHarvestingGrowthState, desc.maxHarvestingGrowthState do
						local index = math.min(i - desc.minHarvestingGrowthState + 1, #colors)
						setDensityMapVisualizationOverlayGrowthStateColor(self.foliageStateOverlay, foliageId, i, colors[index][1], colors[index][2], colors[index][3])
					end
				end
			end
		end
	end
	local mission = g_currentMission
	local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = mission.fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
	local fieldMask = bit32.lshift(bit32.lshift(1, groundTypeNumChannels) - 1, groundTypeFirstChannel)
	if growthStateFilter[MapOverlayGenerator.GROWTH_STATE_INDEX.CULTIVATED] then
		local cultivatorValue = FieldGroundType.getValueByType(FieldGroundType.CULTIVATED)
		local color = self.displayGrowthStates[MapOverlayGenerator.GROWTH_STATE_INDEX.CULTIVATED].colors[self.isColorBlindMode][1]
		setDensityMapVisualizationOverlayStateColor(self.foliageStateOverlay, groundTypeMapId, 0, fieldMask, groundTypeFirstChannel, groundTypeNumChannels, cultivatorValue, color[1], color[2], color[3])
	end
	if growthStateFilter[MapOverlayGenerator.GROWTH_STATE_INDEX.PLOWED] then
		local color = self.displayGrowthStates[MapOverlayGenerator.GROWTH_STATE_INDEX.PLOWED].colors[self.isColorBlindMode][1]
		local plowValue = FieldGroundType.getValueByType(FieldGroundType.PLOWED)
		setDensityMapVisualizationOverlayStateColor(self.foliageStateOverlay, groundTypeMapId, 0, fieldMask, groundTypeFirstChannel, groundTypeNumChannels, plowValue, color[1], color[2], color[3])
	end
	if growthStateFilter[MapOverlayGenerator.GROWTH_STATE_INDEX.STUBBLE_TILLAGE] then
		local color = self.displayGrowthStates[MapOverlayGenerator.GROWTH_STATE_INDEX.STUBBLE_TILLAGE].colors[self.isColorBlindMode][1]
		local stubbleTillageValue = FieldGroundType.getValueByType(FieldGroundType.STUBBLE_TILLAGE)
		setDensityMapVisualizationOverlayStateColor(self.foliageStateOverlay, groundTypeMapId, 0, fieldMask, groundTypeFirstChannel, groundTypeNumChannels, stubbleTillageValue, color[1], color[2], color[3])
	end
	if growthStateFilter[MapOverlayGenerator.GROWTH_STATE_INDEX.SEEDBED] then
		local color = self.displayGrowthStates[MapOverlayGenerator.GROWTH_STATE_INDEX.SEEDBED].colors[self.isColorBlindMode][1]
		local seedBedValue = FieldGroundType.getValueByType(FieldGroundType.SEEDBED)
		setDensityMapVisualizationOverlayStateColor(self.foliageStateOverlay, groundTypeMapId, 0, fieldMask, groundTypeFirstChannel, groundTypeNumChannels, seedBedValue, color[1], color[2], color[3])
		local rolledSeedBedValue = FieldGroundType.getValueByType(FieldGroundType.ROLLED_SEEDBED)
		setDensityMapVisualizationOverlayStateColor(self.foliageStateOverlay, groundTypeMapId, 0, fieldMask, groundTypeFirstChannel, groundTypeNumChannels, rolledSeedBedValue, color[1], color[2], color[3])
	end
end
function MapOverlayGenerator:buildSoilStateMapOverlay(soilStateFilter)
	local mission = g_currentMission
	local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = mission.fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
	local fieldMask = bit32.lshift(bit32.lshift(1, groundTypeNumChannels) - 1, groundTypeFirstChannel)
	if soilStateFilter[MapOverlayGenerator.SOIL_STATE_INDEX.WEEDS] and mission.missionInfo.weedsEnabled then
		local weedSystem = mission.weedSystem
		if weedSystem ~= nil and weedSystem:getMapHasWeed() then
			local weedMapId, _, _ = weedSystem:getDensityMapData()
			local mapColor, mapColorBlind = weedSystem:getColors()
			local colors = self.isColorBlindMode and mapColorBlind or mapColor
			for k, data in ipairs(colors) do
				local stateColor = data.color
				for _, state in ipairs(data.states) do
					setDensityMapVisualizationOverlayGrowthStateColor(self.foliageStateOverlay, weedMapId, state, stateColor[1], stateColor[2], stateColor[3])
				end
			end
		end
	end
	if soilStateFilter[MapOverlayGenerator.SOIL_STATE_INDEX.STONES] and mission.missionInfo.stonesEnabled then
		local stoneSystem = mission.stoneSystem
		if stoneSystem ~= nil and stoneSystem:getMapHasStones() then
			local stoneMapId, _, _ = stoneSystem:getDensityMapData()
			local mapColor, mapColorBlind = stoneSystem:getColors()
			local colors = self.isColorBlindMode and mapColorBlind or mapColor
			for k, data in ipairs(colors) do
				local stateColor = data.color
				for _, state in ipairs(data.states) do
					setDensityMapVisualizationOverlayGrowthStateColor(self.foliageStateOverlay, stoneMapId, state, stateColor[1], stateColor[2], stateColor[3])
				end
			end
		end
	end
	if soilStateFilter[MapOverlayGenerator.SOIL_STATE_INDEX.NEEDS_PLOWING] and mission.missionInfo.plowingRequiredEnabled then
		local color = self.displaySoilStates[MapOverlayGenerator.SOIL_STATE_INDEX.NEEDS_PLOWING].colors[self.isColorBlindMode][1]
		local mapId, plowLevelFirstChannel, plowLevelNumChannels = mission.fieldGroundSystem:getDensityMapData(FieldDensityMap.PLOW_LEVEL)
		setDensityMapVisualizationOverlayStateColor(self.foliageStateOverlay, mapId, groundTypeMapId, fieldMask, plowLevelFirstChannel, plowLevelNumChannels, 0, color[1], color[2], color[3])
	end
	if soilStateFilter[MapOverlayGenerator.SOIL_STATE_INDEX.NEEDS_ROLLING] then
		local color = self.displaySoilStates[MapOverlayGenerator.SOIL_STATE_INDEX.NEEDS_ROLLING].colors[self.isColorBlindMode][1]
		local mapId, rollerLevelFirstChannel, rollerLevelNumChannels = mission.fieldGroundSystem:getDensityMapData(FieldDensityMap.ROLLER_LEVEL)
		setDensityMapVisualizationOverlayStateColor(self.foliageStateOverlay, mapId, 0, fieldMask, rollerLevelFirstChannel, rollerLevelNumChannels, 1, color[1], color[2], color[3])
	end
	if soilStateFilter[MapOverlayGenerator.SOIL_STATE_INDEX.MULCHED] then
		local color = self.displaySoilStates[MapOverlayGenerator.SOIL_STATE_INDEX.MULCHED].colors[self.isColorBlindMode][1]
		local mapId, mulchFirstChannel, mulchNumChannels = mission.fieldGroundSystem:getDensityMapData(FieldDensityMap.STUBBLE_SHRED_LEVEL)
		setDensityMapVisualizationOverlayStateColor(self.foliageStateOverlay, mapId, 0, fieldMask, mulchFirstChannel, mulchNumChannels, 1, color[1], color[2], color[3])
	end
	if not Platform.isMobile and (soilStateFilter[MapOverlayGenerator.SOIL_STATE_INDEX.NEEDS_LIME] and mission.missionInfo.limeRequired) then
		local color = self.displaySoilStates[MapOverlayGenerator.SOIL_STATE_INDEX.NEEDS_LIME].colors[self.isColorBlindMode][1]
		local mapId, limeLevelFirstChannel, limeLevelNumChannels = mission.fieldGroundSystem:getDensityMapData(FieldDensityMap.LIME_LEVEL)
		setDensityMapVisualizationOverlayStateColor(self.foliageStateOverlay, mapId, groundTypeMapId, fieldMask, limeLevelFirstChannel, limeLevelNumChannels, 0, color[1], color[2], color[3])
	end
	if soilStateFilter[MapOverlayGenerator.SOIL_STATE_INDEX.FERTILIZED] then
		local colors = self.displaySoilStates[MapOverlayGenerator.SOIL_STATE_INDEX.FERTILIZED].colors[self.isColorBlindMode]
		local sprayMapId, sprayLevelFirstChannel, sprayLevelNumChannels = mission.fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_LEVEL)
		local maxSprayLevel = mission.fieldGroundSystem:getMaxValue(FieldDensityMap.SPRAY_LEVEL)
		for level = 1, maxSprayLevel do
			local color = colors[math.min(level, #colors)]
			setDensityMapVisualizationOverlayStateColor(self.foliageStateOverlay, sprayMapId, 0, fieldMask, sprayLevelFirstChannel, sprayLevelNumChannels, level, color[1], color[2], color[3])
		end
	end
	if soilStateFilter[MapOverlayGenerator.SOIL_STATE_INDEX.WATERED] then
		local color = self.displaySoilStates[MapOverlayGenerator.SOIL_STATE_INDEX.WATERED].colors[self.isColorBlindMode][1]
		local mapId, firstChannel, numChannels = mission.fieldGroundSystem:getDensityMapData(FieldDensityMap.WATER_LEVEL)
		setDensityMapVisualizationOverlayStateColor(self.foliageStateOverlay, mapId, 0, fieldMask, firstChannel, numChannels, 1, color[1], color[2], color[3])
	end
end
function MapOverlayGenerator:buildFieldMapOverlay(overlay)
	local mission = g_currentMission
	local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = mission.fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
	if groundTypeMapId ~= nil then
		local color = self.fieldColor
		local grassColor = self.grassFieldColor
		for i = 1, bit32.lshift(1, groundTypeNumChannels) - 1 do
			local groundType = FieldGroundType.getTypeByValue(i)
			if groundType == FieldGroundType.GRASS or groundType == FieldGroundType.GRASS_CUT then
				setDensityMapVisualizationOverlayStateColor(overlay, groundTypeMapId, 0, 0, groundTypeFirstChannel, groundTypeNumChannels, i, grassColor[1], grassColor[2], grassColor[3])
			else
				setDensityMapVisualizationOverlayStateColor(overlay, groundTypeMapId, 0, 0, groundTypeFirstChannel, groundTypeNumChannels, i, color[1], color[2], color[3])
			end
		end
	end
end
function MapOverlayGenerator:buildFarmlandsMapOverlay(selectedFarmland)
	local map = self.farmlandManager:getLocalMap()
	local farmlands = self.farmlandManager:getFarmlands()
	setOverlayColor(self.farmlandStateOverlay, 1, 1, 1, MapOverlayGenerator.FARMLANDS_ALPHA)
	for k, farmland in pairs(farmlands) do
		local ownerFarmId = self.farmlandManager:getFarmlandOwner(farmland.id)
		if ownerFarmId == FarmlandManager.NOT_BUYABLE_FARM_ID then
			continue
		end
		if selectedFarmland ~= nil then
			if farmland.id == selectedFarmland.id then
				setDensityMapVisualizationOverlayStateColor(self.farmlandStateOverlay, map, 0, 0, 0, getBitVectorMapNumChannels(map), k, unpack(MapOverlayGenerator.COLOR.FIELD_SELECTED))
			else
				local color = MapOverlayGenerator.COLOR.FIELD_UNOWNED
				if farmland.isOwned then
					local ownerFarm = self.farmManager:getFarmById(ownerFarmId)
					if ownerFarm ~= nil then
						color = ownerFarm:getColor()
					end
				end
				setDensityMapVisualizationOverlayStateColor(self.farmlandStateOverlay, map, 0, 0, 0, getBitVectorMapNumChannels(map), k, unpack(color))
			end
		end
	end
	local profileClass = Utils.getPerformanceClassId()
	if GS_PROFILE_HIGH <= profileClass then
		setDensityMapVisualizationOverlayStateBorderColor(self.farmlandStateOverlay, map, 0, getBitVectorMapNumChannels(map), MapOverlayGenerator.FARMLANDS_BORDER_THICKNESS, FarmlandManager.NOT_BUYABLE_FARM_ID, unpack(MapOverlayGenerator.COLOR.FIELD_BORDER))
	end
	self:buildFieldMapOverlay(self.farmlandStateOverlay)
end
function MapOverlayGenerator:buildSingleFarmlandsMapOverlay(selectedFarmland)
	if selectedFarmland == nil then
		return
	else
		local map = self.farmlandManager:getLocalMap()
		local farmlands = self.farmlandManager:getFarmlands()
		setOverlayColor(self.farmlandStateOverlay, 1, 1, 1, MapOverlayGenerator.FARMLANDS_ALPHA)
		for k, farmland in pairs(farmlands) do
			if farmland.id == selectedFarmland.id then
				setDensityMapVisualizationOverlayStateColor(self.farmlandStateOverlay, map, 0, 0, 0, getBitVectorMapNumChannels(map), k, unpack(MapOverlayGenerator.COLOR.FIELD_SELECTED))
			end
		end
		self:buildFieldMapOverlay(self.farmlandStateOverlay)
	end
end
function MapOverlayGenerator:generateOverlay(mapOverlayType, finishedCallback, overlayState, overlayState2)
	local success = true
	if self.overlayTypeCheckHash[mapOverlayType] == nil then
		Logging.warning("Tried generating a map overlay with an invalid overlay type: [%s]", tostring(mapOverlayType))
		success = false
		return success
	else
		local overlayHandle = self.overlayHandles[mapOverlayType]
		self.overlayFinishedCallback = finishedCallback or NO_CALLBACK
		resetDensityMapVisualizationOverlay(overlayHandle)
		self.currentOverlayHandle = overlayHandle
		local builderFunction = self.typeBuilderFunctionMap[mapOverlayType]
		builderFunction(self, overlayState, overlayState2)
		generateDensityMapVisualizationOverlay(overlayHandle)
		self:checkOverlayFinished()
		return success
	end
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
	if not self.fieldsOverlayUpdating and self.fieldsRefreshTimer < g_time then
		self.fieldsOverlayUpdating = true
		self:generateFieldsOverlay(function(overlayId)
			self.fieldsOverlay = overlayId
			self.fieldsOverlayIsReady = true
			self.fieldsOverlayUpdating = false
			self.fieldsRefreshTimer = g_time + MapOverlayGenerator.FIELD_REFRESH_INTERVAL
		end)
	end
	self:checkOverlayFinished()
end
function MapOverlayGenerator:getDisplayCropTypes()
	local cropTypes = {}
	for _, fruitType in ipairs(self.missionFruitTypes) do
		if fruitType.shownOnMap then
			local fillableIndex = self.fruitTypeManager:getFillTypeIndexByFruitTypeIndex(fruitType.fruitTypeIndex)
			local fillable = self.fillTypeManager:getFillTypeByIndex(fillableIndex)
			local iconFilename = fillable.hudOverlayFilename
			local iconUVs = Overlay.DEFAULT_UVS
			local description = fillable.title
			table.insert(cropTypes, { iconFilename = iconFilename, iconUVs = iconUVs, description = description, colors = { [false] = fruitType.defaultColor, [true] = fruitType.colorBlindColor }, fruitTypeIndex = fruitType.fruitTypeIndex, foliageId = fruitType.foliageId })
		end
	end
	return cropTypes
end
function MapOverlayGenerator:getDisplayGrowthStates()
	local res = {}
	res[MapOverlayGenerator.GROWTH_STATE_INDEX.CULTIVATED] = { colors = { [true] = { MapOverlayGenerator.FRUIT_COLOR_CULTIVATED[true] }, [false] = { MapOverlayGenerator.FRUIT_COLOR_CULTIVATED[false] } }, description = self.l10n:getText(MapOverlayGenerator.L10N_SYMBOL.GROWTH_MAP_CULTIVATED) }
	res[MapOverlayGenerator.GROWTH_STATE_INDEX.STUBBLE_TILLAGE] = { colors = { [true] = { MapOverlayGenerator.FRUIT_COLOR_STUBBLE_TILLAGE[true] }, [false] = { MapOverlayGenerator.FRUIT_COLOR_STUBBLE_TILLAGE[false] } }, description = self.l10n:getText(MapOverlayGenerator.L10N_SYMBOL.GROWTH_MAP_STUBBLE_TILLAGE) }
	res[MapOverlayGenerator.GROWTH_STATE_INDEX.SEEDBED] = { colors = { [true] = { MapOverlayGenerator.FRUIT_COLOR_SEEDBED[true] }, [false] = { MapOverlayGenerator.FRUIT_COLOR_SEEDBED[false] } }, description = self.l10n:getText(MapOverlayGenerator.L10N_SYMBOL.GROWTH_MAP_SEEDBED) }
	res[MapOverlayGenerator.GROWTH_STATE_INDEX.GROWING] = { colors = MapOverlayGenerator.FRUIT_COLORS_GROWING, description = self.l10n:getText(MapOverlayGenerator.L10N_SYMBOL.GROWTH_MAP_GROWING) }
	res[MapOverlayGenerator.GROWTH_STATE_INDEX.HARVEST] = { colors = MapOverlayGenerator.FRUIT_COLORS_HARVEST, description = self.l10n:getText(MapOverlayGenerator.L10N_SYMBOL.GROWTH_MAP_HARVEST) }
	res[MapOverlayGenerator.GROWTH_STATE_INDEX.HARVESTED] = { colors = { [true] = { MapOverlayGenerator.FRUIT_COLOR_CUT }, [false] = { MapOverlayGenerator.FRUIT_COLOR_CUT } }, description = self.l10n:getText(MapOverlayGenerator.L10N_SYMBOL.GROWTH_MAP_HARVESTED) }
	res[MapOverlayGenerator.GROWTH_STATE_INDEX.TOPPING] = { colors = { [true] = { MapOverlayGenerator.FRUIT_COLOR_REMOVE_TOPS[true] }, [false] = { MapOverlayGenerator.FRUIT_COLOR_REMOVE_TOPS[false] } }, description = self.l10n:getText(MapOverlayGenerator.L10N_SYMBOL.GROWTH_MAP_TOPPING) }
	res[MapOverlayGenerator.GROWTH_STATE_INDEX.PLOWED] = { colors = { [true] = { MapOverlayGenerator.FRUIT_COLOR_PLOWED[true] }, [false] = { MapOverlayGenerator.FRUIT_COLOR_PLOWED[false] } }, description = self.l10n:getText(MapOverlayGenerator.L10N_SYMBOL.GROWTH_MAP_PLOWED) }
	if Platform.gameplay.supportsWithering then
		res[MapOverlayGenerator.GROWTH_STATE_INDEX.WITHERED] = { colors = { [true] = { MapOverlayGenerator.FRUIT_COLOR_WITHERED[true] }, [false] = { MapOverlayGenerator.FRUIT_COLOR_WITHERED[false] } }, description = self.l10n:getText(MapOverlayGenerator.L10N_SYMBOL.GROWTH_MAP_WITHERED) }
	end
	return res
end
function MapOverlayGenerator:getDisplaySoilStates()
	local fertilizerColors = {}
	fertilizerColors[true] = {}
	fertilizerColors[false] = {}
	local mission = g_currentMission
	local maxFertilizerStates = mission.fieldGroundSystem:getMaxValue(FieldDensityMap.SPRAY_LEVEL)
	for colorBlind, colors in pairs(MapOverlayGenerator.FRUIT_COLORS_FERTILIZED) do
		for i = #colors, 1, -1 do
			local color = colors[i]
			table.insert(fertilizerColors[colorBlind], 1, color)
			if #fertilizerColors[colorBlind] ~= maxFertilizerStates then
				continue
			end
		end
	end
	local res = {}
	res[MapOverlayGenerator.SOIL_STATE_INDEX.FERTILIZED] = { colors = fertilizerColors, description = self.l10n:getText(MapOverlayGenerator.L10N_SYMBOL.SOIL_MAP_FERTILIZED), isActive = true }
	if Platform.gameplay.usePlowCounter and mission.missionInfo.plowingRequiredEnabled then
		res[MapOverlayGenerator.SOIL_STATE_INDEX.NEEDS_PLOWING] = { colors = { [true] = { MapOverlayGenerator.FRUIT_COLOR_NEEDS_PLOWING[true] }, [false] = { MapOverlayGenerator.FRUIT_COLOR_NEEDS_PLOWING[false] } }, description = self.l10n:getText(MapOverlayGenerator.L10N_SYMBOL.SOIL_MAP_NEED_PLOWING), isActive = mission.missionInfo.plowingRequiredEnabled }
	end
	if Platform.gameplay.useLimeCounter and mission.missionInfo.limeRequired then
		res[MapOverlayGenerator.SOIL_STATE_INDEX.NEEDS_LIME] = { colors = { [true] = { MapOverlayGenerator.FRUIT_COLOR_NEEDS_LIME[true] }, [false] = { MapOverlayGenerator.FRUIT_COLOR_NEEDS_LIME[false] } }, description = self.l10n:getText(MapOverlayGenerator.L10N_SYMBOL.SOIL_MAP_NEED_LIME), isActive = mission.missionInfo.limeRequired }
	end
	if Platform.gameplay.useRolling then
		res[MapOverlayGenerator.SOIL_STATE_INDEX.NEEDS_ROLLING] = { colors = { [true] = { MapOverlayGenerator.FRUIT_COLOR_NEEDS_ROLLING[true] }, [false] = { MapOverlayGenerator.FRUIT_COLOR_NEEDS_ROLLING[false] } }, description = self.l10n:getText(MapOverlayGenerator.L10N_SYMBOL.SOIL_MAP_NEED_ROLLING), isActive = true }
	end
	if Platform.gameplay.useStubbleShred then
		res[MapOverlayGenerator.SOIL_STATE_INDEX.MULCHED] = { colors = { [true] = { MapOverlayGenerator.FRUIT_COLOR_MULCHED[true] }, [false] = { MapOverlayGenerator.FRUIT_COLOR_MULCHED[false] } }, description = self.l10n:getText(MapOverlayGenerator.L10N_SYMBOL.SOIL_MAP_MULCHED), isActive = true }
	end
	res[MapOverlayGenerator.SOIL_STATE_INDEX.WATERED] = { colors = { [true] = { MapOverlayGenerator.FRUIT_COLOR_WATERED[true] }, [false] = { MapOverlayGenerator.FRUIT_COLOR_WATERED[false] } }, description = self.l10n:getText(MapOverlayGenerator.L10N_SYMBOL.SOIL_MAP_WATERED), isActive = true }
	local weedSystem = mission.weedSystem
	if weedSystem ~= nil and (weedSystem:getMapHasWeed() and mission.missionInfo.weedsEnabled) then
		local mapColor, mapColorBlind = weedSystem:getColors()
		local description = weedSystem:getTitle() or ""
		local colors = {}
		colors[true] = {}
		colors[false] = {}
		for k, data in ipairs(mapColor) do
			table.insert(colors[true], mapColorBlind[k].color)
			table.insert(colors[false], data.color)
		end
		res[MapOverlayGenerator.SOIL_STATE_INDEX.WEEDS] = { colors = colors, description = description, isActive = mission.missionInfo.weedsEnabled }
	end
	local stoneSystem = mission.stoneSystem
	if stoneSystem ~= nil and (stoneSystem:getMapHasStones() and mission.missionInfo.stonesEnabled) then
		local mapColor, mapColorBlind = stoneSystem:getColors()
		local description = stoneSystem:getTitle() or ""
		local colors = {}
		colors[true] = {}
		colors[false] = {}
		for k, data in ipairs(mapColor) do
			table.insert(colors[true], mapColorBlind[k].color)
			table.insert(colors[false], data.color)
		end
		res[MapOverlayGenerator.SOIL_STATE_INDEX.STONES] = { colors = colors, description = description, isActive = mission.missionInfo.stonesEnabled }
	end
	return res
end
MapOverlayGenerator.GROWTH_STATE_INDEX = { STUBBLE_TILLAGE = 1, CULTIVATED = 2, PLOWED = 3, SEEDBED = 4, GROWING = 5, HARVEST = 6, HARVESTED = 7, TOPPING = 8, WITHERED = 9 }
MapOverlayGenerator.SOIL_STATE_INDEX = { WEEDS = 1, FERTILIZED = 2, NEEDS_PLOWING = 3, NEEDS_LIME = 4, NEEDS_ROLLING = 5, MULCHED = 6, STONES = 7, WATERED = 8 }
MapOverlayGenerator.FRUIT_COLORS_GROWING = {}
if not Platform.isMobile then
	MapOverlayGenerator.FRUIT_COLORS_GROWING[false] = { { 0.227, 0.5711, 0.0176, 1 }, { 0.1683, 0.4678, 0.0152, 1 }, { 0.1221, 0.3813, 0.013, 1 }, { 0.0823, 0.3006, 0.011, 1 }, { 0.0529, 0.2346, 0.0091, 1 }, { 0.0296, 0.1746, 0.0075, 1 }, { 0.0144, 0.1248, 0.006, 1 }, { 0.0048, 0.0844, 0.0048, 1 } }
	MapOverlayGenerator.FRUIT_COLORS_GROWING[true] = { { 1, 0.9473, 0.227, 1 }, { 1, 0.9046, 0.013, 1 }, { 0.5583, 0.4735, 0.007, 1 }, { 0.2122, 0.1779, 0.0027, 1 } }
else
	MapOverlayGenerator.FRUIT_COLORS_GROWING[false] = { { 0.227, 0.5711, 0.0176, 1 }, { 0.0823, 0.3006, 0.011, 1 }, { 0.0048, 0.0844, 0.0048, 1 } }
	MapOverlayGenerator.FRUIT_COLORS_GROWING[true] = { { 1, 0.9473, 0.227, 1 }, { 0.5583, 0.4735, 0.007, 1 }, { 0.2122, 0.1779, 0.0027, 1 } }
end
MapOverlayGenerator.FRUIT_COLORS_HARVEST = {}
MapOverlayGenerator.FRUIT_COLORS_HARVEST[false] = { { 0.7758, 0.3095, 0.013, 1 } }
MapOverlayGenerator.FRUIT_COLORS_HARVEST[true] = { { 0.0561, 0.1384, 0.5841, 1 } }
MapOverlayGenerator.FRUIT_COLORS_FERTILIZED = {}
if not Platform.isMobile then
	MapOverlayGenerator.FRUIT_COLORS_FERTILIZED[false] = { { 0.0595, 0.2086, 0.8227, 1 }, { 0.0091, 0.0931, 0.5841, 1 }, { 0.0018, 0.0382, 0.2961, 1 } }
	MapOverlayGenerator.FRUIT_COLORS_FERTILIZED[true] = { { 0.0976, 0.2086, 0.8148, 1 }, { 0.0086, 0.0976, 0.5776, 1 }, { 0, 0.0409, 0.2918, 1 } }
else
	MapOverlayGenerator.FRUIT_COLORS_FERTILIZED[false] = { { 0.0091, 0.0931, 0.5841, 1 }, { 0.0018, 0.0382, 0.2961, 1 } }
	MapOverlayGenerator.FRUIT_COLORS_FERTILIZED[true] = { { 0.0086, 0.0976, 0.5776, 1 }, { 0, 0.0409, 0.2918, 1 } }
end
MapOverlayGenerator.FRUIT_COLORS_DISABLED = { { 0.4, 0.4, 0.4, 1 }, { 0.3, 0.3, 0.3, 1 }, { 0.2, 0.2, 0.2, 1 }, { 0.1, 0.1, 0.1, 1 } }
MapOverlayGenerator.FRUIT_COLOR_NEEDS_PLOWING = {}
MapOverlayGenerator.FRUIT_COLOR_NEEDS_PLOWING[false] = { 0.6172, 0.051, 0.051, 1 }
MapOverlayGenerator.FRUIT_COLOR_NEEDS_PLOWING[true] = { 1, 0.8632, 0.0232, 1 }
MapOverlayGenerator.FRUIT_COLOR_NEEDS_LIME = {}
MapOverlayGenerator.FRUIT_COLOR_NEEDS_LIME[false] = { 0.0815, 0.6584, 0.4198, 1 }
MapOverlayGenerator.FRUIT_COLOR_NEEDS_LIME[true] = { 0.6795, 0.6867, 0.7231, 1 }
MapOverlayGenerator.FRUIT_COLOR_NEEDS_ROLLING = {}
MapOverlayGenerator.FRUIT_COLOR_NEEDS_ROLLING[false] = { 0.0967, 0.3758, 0.7084, 1 }
MapOverlayGenerator.FRUIT_COLOR_NEEDS_ROLLING[true] = { 0.2918, 0.3564, 0.7011, 1 }
MapOverlayGenerator.FRUIT_COLOR_MULCHED = {}
MapOverlayGenerator.FRUIT_COLOR_MULCHED[false] = { 0.0908, 0.0467, 0.0865, 1 }
MapOverlayGenerator.FRUIT_COLOR_MULCHED[true] = { 0.0469, 0.0484, 0.0597, 1 }
MapOverlayGenerator.FRUIT_COLOR_REMOVE_TOPS = {}
MapOverlayGenerator.FRUIT_COLOR_REMOVE_TOPS[false] = { 0.7011, 0.0452, 0.0123, 1 }
MapOverlayGenerator.FRUIT_COLOR_REMOVE_TOPS[true] = { 0.3231, 0.3467, 0.4621, 1 }
MapOverlayGenerator.FRUIT_COLOR_WITHERED = {}
MapOverlayGenerator.FRUIT_COLOR_WITHERED[false] = { 0.1441, 0.0452, 0.0123, 1 }
MapOverlayGenerator.FRUIT_COLOR_WITHERED[true] = { 0.1195, 0.1144, 0.0908, 1 }
MapOverlayGenerator.FRUIT_COLOR_CULTIVATED = {}
MapOverlayGenerator.FRUIT_COLOR_CULTIVATED[false] = { 0.0967, 0.3758, 0.7084, 1 }
MapOverlayGenerator.FRUIT_COLOR_CULTIVATED[true] = { 0.2918, 0.3564, 0.7011, 1 }
MapOverlayGenerator.FRUIT_COLOR_STUBBLE_TILLAGE = {}
MapOverlayGenerator.FRUIT_COLOR_STUBBLE_TILLAGE[false] = { 0.1967, 0.4758, 0.3084, 1 }
MapOverlayGenerator.FRUIT_COLOR_STUBBLE_TILLAGE[true] = { 0.3918, 0.4564, 0.3011, 1 }
MapOverlayGenerator.FRUIT_COLOR_SEEDBED = {}
MapOverlayGenerator.FRUIT_COLOR_SEEDBED[false] = { 0.0815, 0.6584, 0.4198, 1 }
MapOverlayGenerator.FRUIT_COLOR_SEEDBED[true] = { 0.6795, 0.6867, 0.7231, 1 }
MapOverlayGenerator.FRUIT_COLOR_PLOWED = {}
MapOverlayGenerator.FRUIT_COLOR_PLOWED[false] = { 0.0908, 0.0467, 0.0865, 1 }
MapOverlayGenerator.FRUIT_COLOR_PLOWED[true] = { 0.0469, 0.0484, 0.0597, 1 }
MapOverlayGenerator.FRUIT_COLOR_SOWN = {}
MapOverlayGenerator.FRUIT_COLOR_SOWN[false] = { 0.9301, 0.6404, 0.0439, 1 }
MapOverlayGenerator.FRUIT_COLOR_SOWN[true] = { 0.7681, 0.6514, 0.0529, 1 }
MapOverlayGenerator.FRUIT_COLOR_CUT = { 0.2647, 0.1038, 0.358, 1 }
MapOverlayGenerator.FRUIT_COLOR_DISABLED = { 0.2, 0.2, 0.2, 1 }
MapOverlayGenerator.FRUIT_COLOR_WATERED = {}
MapOverlayGenerator.FRUIT_COLOR_WATERED[false] = { 0.0967, 0.3758, 0.7084, 1 }
MapOverlayGenerator.FRUIT_COLOR_WATERED[true] = { 0.2918, 0.3564, 0.7011, 1 }
MapOverlayGenerator.FIELD_COLOR = { 0.15, 0.1195, 0.0953 }
MapOverlayGenerator.FIELD_GRASS_COLOR = { 0.147, 0.1441, 0.0823 }
MapOverlayGenerator.COLOR = { FIELD_UNOWNED = { 0, 0, 0 }, FIELD_SELECTED = { 0.07818, 0.16826, 0.00334 }, FIELD_BORDER = { 0.2, 0.2, 0.2 } }
MapOverlayGenerator.FARMLANDS_ALPHA = 0.5
MapOverlayGenerator.FARMLANDS_BORDER_THICKNESS = 3
MapOverlayGenerator.L10N_SYMBOL = { GROWTH_MAP_CULTIVATED = "ui_growthMapCultivated", GROWTH_MAP_GROWING = "ui_growthMapGrowing", GROWTH_MAP_HARVEST = "ui_growthMapReadyToHarvest", GROWTH_MAP_HARVESTED = "ui_growthMapCut", GROWTH_MAP_PLOWED = "ui_growthMapPlowed", GROWTH_MAP_TOPPING = "ui_growthMapReadyToPrepareForHarvest", GROWTH_MAP_WITHERED = "ui_growthMapWithered", GROWTH_MAP_STUBBLE_TILLAGE = "ui_growthMapStubbleTillage", GROWTH_MAP_SEEDBED = "ui_growthMapSeedbed", SOIL_MAP_FERTILIZED = "ui_growthMapFertilized", SOIL_MAP_NEED_PLOWING = "ui_growthMapNeedsPlowing", SOIL_MAP_NEED_LIME = "ui_growthMapNeedsLime", SOIL_MAP_NEED_ROLLING = "ui_growthMapNeedsRolling", SOIL_MAP_MULCHED = "ui_growthMapMulched", SOIL_MAP_WATERED = "ui_growthMapWatered" }
