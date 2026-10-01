TramlineMap = {}
TramlineMap.MIN_STRAIGHT_SEGMENT_LENGTH = 10
source(g_currentModDirectory .. "scripts/gui/TramlineSettingsDialog.lua")
source(g_currentModDirectory .. "scripts/densityMapUpdates/TramlineMapDensityMapTask.lua")
local TramlineMap_mt = Class(TramlineMap, ValueMap)
function TramlineMap.new(pfModule, customMt)
	local self = ValueMap.new(pfModule, customMt or TramlineMap_mt)
	self.filename = "precisionFarming_tramlineMap.grle"
	self.name = "tramlineMap"
	self.id = "TRAMLINE_MAP"
	self.label = ""
	if g_server ~= nil then
		addConsoleCommand("pfTramlineSet", "Sets the tramlines for a specific farmland", "debugTramlineSet", self)
	end
	self.farmlandTramlineStates = {}
	self.implementWidths = { 0, 15, 18, 20, 21, 24, 27, 28, 30, 33, 36, 39, 40, 42, 44, 45, 51, 52, 54, 60 }
	self.implementWidthTexts = {}
	for _, number in ipairs(self.implementWidths) do
		if number ~= 0 then
			table.insert(self.implementWidthTexts, string.format("%dm", number))
		else
			table.insert(self.implementWidthTexts, g_i18n:getText("ui_tramlinesOff"))
		end
	end
	self.spacings = { 2, 2.5, 3, 3.5 }
	self.spacingTexts = {}
	for _, number in ipairs(self.spacings) do
		table.insert(self.spacingTexts, string.format("%.1fm", number))
	end
	self.workDirectionTexts = {}
	self.workDirectionTextToDeg = {}
	table.insert(self.workDirectionTexts, g_i18n:getText("ai_settingAutomatic"))
	self.workDirectionTextToDeg[1] = -57.29577951308232
	for i = 0, 175, 5 do
		table.insert(self.workDirectionTexts, string.format("%d \194\176", i))
		self.workDirectionTextToDeg[#self.workDirectionTexts] = i
	end
	MessageType.PRECISION_FARMING_TRAMLINES_CHANGED = nextMessageTypeId()
	return self
end
function TramlineMap:initialize()
	TramlineMap:superClass().initialize(self)
	self.densityMapModifiersPaint = {}
	self.densityMapModifiersClear = {}
	self.densityMapModifiersReset = nil
	TramlineSettingsDialog.register()
end
function TramlineMap:delete()
	TramlineMap:superClass().delete(self)
	if g_server ~= nil then
		removeConsoleCommand("pfTramlineSet")
	end
	g_messageCenter:unsubscribeAll(self)
end
function TramlineMap:loadFromXML(xmlFile, key, baseDirectory, configFileName, mapFilename)
	key = key .. ".tramlineMap"
	self.npcFieldFruitTypes = {}
	self:loadTramlineFruitTypesFromXML(xmlFile, key .. ".npcFields#fruitTypes")
	local missionInfo = g_currentMission.missionInfo
	local mapXMLFilename = Utils.getFilename(missionInfo.mapXMLFilename, g_currentMission.baseDirectory)
	local mapXMLFile = loadXMLFile("MapXML", mapXMLFilename)
	if mapXMLFile ~= nil then
		self:loadTramlineFruitTypesFromXML(mapXMLFile, "map.precisionFarming.npcTramlines#fruitTypes")
		delete(mapXMLFile)
	end
	self.npcWorkingWidth = getXMLInt(xmlFile, key .. ".npcFields#workingWidth") or 27
	self.npcSpacing = getXMLFloat(xmlFile, key .. ".npcFields#spacing") or 2
	if g_server ~= nil then
		g_messageCenter:subscribe(MessageType.FARMLAND_OWNER_CHANGED, self.onFarmlandStateChanged, self)
	end
	return true
end
function TramlineMap:initTerrain(mission, terrainId, filename)
	TramlineMap:superClass().initTerrain(self, mission, terrainId, filename)
	self.numChannels = 2
	self.size = g_currentMission.fruitMapSize
	self.bitVectorMap = self:loadSavedBitVectorMap("TramlineMap", self.filename, self.numChannels, self.size)
	self:addBitVectorMapToSave(self.bitVectorMap, self.filename)
	self:addBitVectorMapToDelete(self.bitVectorMap)
end
function TramlineMap:loadTramlineFruitTypesFromXML(xmlFile, key)
	local fruitTypesStr = getXMLString(xmlFile, key)
	if fruitTypesStr ~= nil then
		local fruitTypes = fruitTypesStr:split(" ")
		for j = 1, #fruitTypes do
			local fruitType = g_fruitTypeManager:getFruitTypeByName(fruitTypes[j])
			if fruitType ~= nil then
				self.npcFieldFruitTypes[fruitType.index] = true
			else
				Logging.xmlWarning(xmlFile, "Invalid fruit type '%s' for npc fields '%s'", fruitTypes[j], key)
			end
		end
	end
end
function TramlineMap:loadFromItemsXML(xmlFile, key)
	key = key .. ".tramlineMap"
	xmlFile:iterate(key .. ".farmland", function(_, baseKey)
		local farmlandId = xmlFile:getInt(baseKey .. "#farmlandId")
		if farmlandId ~= nil then
			local state = {}
			state.workingWidth = xmlFile:getFloat(baseKey .. "#width")
			if state.workingWidth ~= nil then
				state.workDirection = xmlFile:getFloat(baseKey .. "#workDirection", -57.29577951308232)
				state.spacing = xmlFile:getFloat(baseKey .. "#spacing", 2)
				state.pendingUpdate = xmlFile:getBool(baseKey .. "#pendingUpdate", false)
				self.farmlandTramlineStates[farmlandId] = state
			end
		end
	end)
end
function TramlineMap:saveToXMLFile(xmlFile, key, usedModNames)
	key = key .. ".tramlineMap"
	local i = 0
	for farmlandId, state in pairs(self.farmlandTramlineStates) do
		local baseKey = string.format("%s.farmland(%d)", key, i)
		xmlFile:setInt(baseKey .. "#farmlandId", farmlandId)
		xmlFile:setFloat(baseKey .. "#width", state.workingWidth)
		xmlFile:setFloat(baseKey .. "#workDirection", state.workDirection)
		xmlFile:setFloat(baseKey .. "#spacing", state.spacing or 2)
		xmlFile:setBool(baseKey .. "#pendingUpdate", Utils.getNoNil(state.pendingUpdate, false))
		i = i + 1
	end
end
function TramlineMap:sendInitialClientState(connection, user, farm)
	connection:sendEvent(TramlineMapInitialEvent.new(self.farmlandTramlineStates))
end
function TramlineMap:setMapFrame(mapFrame)
	self.mapFrame = mapFrame
end
function TramlineMap:update(dt) end
local worldCoordsToLocalCoords = function(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, size, terrainSize)
	return (startWorldX + terrainSize * 0.5) / terrainSize * size + 0.5 - 1, (startWorldZ + terrainSize * 0.5) / terrainSize * size + 0.5 - 1, (widthWorldX + terrainSize * 0.5) / terrainSize * size + 0.5 - 1, (widthWorldZ + terrainSize * 0.5) / terrainSize * size + 0.5 - 1, (heightWorldX + terrainSize * 0.5) / terrainSize * size + 0.5 - 1, (heightWorldZ + terrainSize * 0.5) / terrainSize * size + 0.5 - 1
end
function TramlineMap:getTramlineWidthAtWorldPos(worldPosX, worldPosZ)
	local farmlandId = g_farmlandManager:getFarmlandIdAtWorldPosition(worldPosX, worldPosZ)
	if farmlandId ~= nil and self.farmlandTramlineStates[farmlandId] ~= nil then
		return self.farmlandTramlineStates[farmlandId].workingWidth
	end
	return nil
end
function TramlineMap:paintLine(sx, sz, ex, ez, spacing)
	spacing = spacing or 2
	local modifier = self.densityMapModifiersPaint.modifier
	if modifier == nil then
		self.densityMapModifiersPaint.modifier = DensityMapModifier.new(self.bitVectorMap, 0, 1)
		modifier = self.densityMapModifiersPaint.modifier
		modifier:setPolygonRoundingMode(DensityRoundingMode.NEAREST_EXPAND)
	end
	local dirX, dirZ = MathUtil.vector2Normalize(ex - sx, ez - sz)
	local yRot = math.abs(MathUtil.getYRotationFromDirection(dirX, dirZ))
	yRot = yRot % 1.5707963267948966
	local rotOffsetFactor = yRot / 1.5707963267948966
	if 0.5 < rotOffsetFactor then
		rotOffsetFactor = 1 - rotOffsetFactor
	end
	rotOffsetFactor = rotOffsetFactor * 2
	local offset = spacing * 0.5 + rotOffsetFactor * 0.25
	local sideDirX = -dirZ
	local sideDirZ = dirX
	if math.abs(sideDirZ) < math.abs(sideDirX) then
		sideDirX = math.sign(sideDirX)
		sideDirZ = 0
	else
		sideDirX = 0
		sideDirZ = math.sign(sideDirZ)
	end
	modifier:resetDensityMapAndChannels(self.bitVectorMap, 0, 1)
	local minOffset = -offset - 0.01
	local maxOffset = -offset + 0.01
	local startWorldX = sx + sideDirX * minOffset
	local startWorldZ = sz + sideDirZ * minOffset
	local widthWorldX = sx + sideDirX * maxOffset
	local widthWorldZ = sz + sideDirZ * maxOffset
	local heightWorldX = ex + sideDirX * minOffset
	local heightWorldZ = ez + sideDirZ * minOffset
	startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ = worldCoordsToLocalCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, self.size, g_currentMission.terrainSize)
	modifier:setParallelogramDensityMapCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	modifier:executeSet(1)
	minOffset = offset - 0.01
	maxOffset = offset + 0.01
	startWorldX = sx + sideDirX * minOffset
	startWorldZ = sz + sideDirZ * minOffset
	widthWorldX = sx + sideDirX * maxOffset
	widthWorldZ = sz + sideDirZ * maxOffset
	heightWorldX = ex + sideDirX * minOffset
	heightWorldZ = ez + sideDirZ * minOffset
	startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ = worldCoordsToLocalCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, self.size, g_currentMission.terrainSize)
	modifier:setParallelogramDensityMapCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	modifier:executeSet(1)
	modifier:resetDensityMapAndChannels(self.bitVectorMap, 1, 1)
	minOffset = -(spacing * 0.5 + 1)
	maxOffset = spacing * 0.5 + 1
	startWorldX = sx + sideDirX * minOffset
	startWorldZ = sz + sideDirZ * minOffset
	widthWorldX = sx + sideDirX * maxOffset
	widthWorldZ = sz + sideDirZ * maxOffset
	heightWorldX = ex + sideDirX * minOffset
	heightWorldZ = ez + sideDirZ * minOffset
	startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ = worldCoordsToLocalCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, self.size, g_currentMission.terrainSize)
	modifier:setParallelogramDensityMapCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	modifier:executeSet(1)
end
function TramlineMap:clearTramlines(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, densityMapShape, npcField)
	local multiModifiers = self.densityMapModifiersClear.multiModifiers
	if multiModifiers == nil then
		self.densityMapModifiersClear.multiModifiers = {}
		self.densityMapModifiersClear.multiModifiers[true] = DensityMapMultiModifier.new()
		self.densityMapModifiersClear.multiModifiers[false] = DensityMapMultiModifier.new()
		self:addTramlineClearToMultiModifier(self.densityMapModifiersClear.multiModifiers[true], true)
		self:addTramlineClearToMultiModifier(self.densityMapModifiersClear.multiModifiers[false], false)
		multiModifiers = self.densityMapModifiersClear.multiModifiers
	end
	npcField = Utils.getNoNil(npcField, false)
	local multiModifier = multiModifiers[npcField]
	if densityMapShape ~= nil then
		densityMapShape:applyToModifier(multiModifier)
	else
		multiModifier:updateParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	end
	multiModifier:execute()
end
function TramlineMap:addTramlineClearToMultiModifier(multiModifier, npcField)
	local tramlineFilter = DensityMapFilter.new(self.bitVectorMap, 0, 1)
	tramlineFilter:setValueCompareParams(DensityValueCompareType.EQUAL, 1)
	local weedSystem = g_currentMission.weedSystem
	if weedSystem:getMapHasWeed() then
		local weedMapId, weedFirstChannel, weedNumChannels = weedSystem:getDensityMapData()
		local weedModifier = DensityMapModifier.new(weedMapId, weedFirstChannel, weedNumChannels, g_terrainNode)
		multiModifier:addExecuteSet(0, weedModifier, tramlineFilter)
	end
	local fruitFilter = nil
	local fruitModifier = nil
	for _, desc in pairs(g_fruitTypeManager:getFruitTypes()) do
		if not npcField or self.npcFieldFruitTypes[desc.index] then
			if desc.terrainDataPlaneId == nil then
				continue
			end
			if fruitFilter == nil then
				fruitFilter = DensityMapFilter.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)
			else
				fruitFilter:resetDensityMapAndChannels(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)
			end
			fruitFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)
			if fruitModifier == nil then
				fruitModifier = DensityMapModifier.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)
			else
				fruitModifier:resetDensityMapAndChannels(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)
			end
			fruitModifier:setNewTypeIndexMode(DensityIndexCompareMode.ZERO)
			multiModifier:addExecuteSet(0, fruitModifier, tramlineFilter, fruitFilter)
		end
	end
end
function TramlineMap:setFarmlandTramlines(farmlandId, workingWidth, workDirection, spacing, enabled, clearFruit, noEventSend)
	if enabled then
		self:resetFarmlandTramlines(farmlandId)
	end
	if 0.1 < math.abs(workingWidth) then
		local farmland = g_farmlandManager:getFarmlandById(farmlandId)
		if farmland ~= nil then
			local state = {}
			state.workingWidth = workingWidth
			state.workDirection = workDirection
			state.spacing = spacing
			state.enabled = enabled
			state.pendingUpdate = state.enabled
			state.clearFruit = clearFruit
			self.farmlandTramlineStates[farmlandId] = state
		else
			Logging.devError("TramlineMap: Farmland with id %d not found", farmlandId)
		end
	else
		self.farmlandTramlineStates[farmlandId] = nil
	end
	TramlineMapSetEvent.sendEvent(farmlandId, workingWidth, workDirection, spacing, enabled, clearFruit, noEventSend)
	g_messageCenter:publish(MessageType.PRECISION_FARMING_TRAMLINES_CHANGED)
end
function TramlineMap:onDensityMapUpdateFinished(farmlandId)
	local farmland = g_farmlandManager:getFarmlandById(farmlandId)
	local state = self.farmlandTramlineStates[farmlandId]
	if farmland ~= nil and (state ~= nil and state.pendingUpdate) then
		state.pendingUpdate = false
		if g_server ~= nil then
			local posX, posZ = farmland:getIndicatorPosition()
			local fieldCourseSettings = FieldCourseSettings.new()
			fieldCourseSettings.implementWidth = state.workingWidth
			fieldCourseSettings.workDirection = math.rad(state.workDirection)
			fieldCourseSettings.numHeadlands = 1
			fieldCourseSettings.segmentExtendedToBoundary = true
			fieldCourseSettings.segmentHeadlandReverseLines = true
			fieldCourseSettings.segmentMinOffset = 3
			fieldCourseSettings.segmentMinLength = 25
			local segmentFunc = function(sx, sz, ex, ez, segmentLength, headlandIndex, islandIndex, totalCourseLength)
				if TramlineMap.MIN_STRAIGHT_SEGMENT_LENGTH < segmentLength or headlandIndex ~= nil then
					self:paintLine(sx, sz, ex, ez, state.spacing)
				end
			end
			local finishedFunc = function()
				if state.clearFruit then
					state.clearFruit = false
					local field = g_fieldManager:getFieldById(farmlandId)
					if field ~= nil then
						local area = field:getDensityMapPolygon()
						self:clearTramlines(nil, nil, nil, nil, nil, nil, area, not farmland.isOwned)
					end
				end
				Logging.devInfo("TramlineMap: Set tramlines for farmland %d (%d m)", farmlandId, state.workingWidth)
			end
			FieldCourseIterator.new(posX, posZ, fieldCourseSettings, segmentFunc, finishedFunc)
		end
	end
end
function TramlineMap:resetFarmlandTramlines(farmlandId)
	local updateTask = TramlineMapDensityMapTask.new()
	updateTask:setData(farmlandId)
	updateTask:enqueue()
end
function TramlineMap:getResetTramlinesMultiMudifier(farmlandId)
	local functionData = self.densityMapModifiersReset
	if functionData == nil then
		functionData = {}
		functionData.modifier = DensityMapModifier.new(self.bitVectorMap, 0, self.numChannels, g_terrainNode)
		functionData.multiModifiers = {}
		self.densityMapModifiersReset = functionData
	end
	local multiModifier = functionData.multiModifiers[farmlandId]
	if multiModifier == nil then
		multiModifier = DensityMapMultiModifier.new()
		functionData.multiModifiers[farmlandId] = multiModifier
		multiModifier:addExecuteSet(0, functionData.modifier)
	end
	return multiModifier
end
function TramlineMap:buildOverlay(overlay, yieldFilter, isColorBlindMode)
	resetDensityMapVisualizationOverlay(overlay)
	setOverlayColor(overlay, 1, 1, 1, 0.1)
	setDensityMapVisualizationOverlayStateColor(overlay, self.bitVectorMap, 0, 0, 0, 2, 0, 0, 0, 0)
	setDensityMapVisualizationOverlayStateColor(overlay, self.bitVectorMap, 0, 0, 0, 2, 2, 0, 1, 0)
	setDensityMapVisualizationOverlayStateColor(overlay, self.bitVectorMap, 0, 0, 0, 2, 3, 0, 1, 0)
end
function TramlineMap:getShowInMenu()
	return false
end
function TramlineMap:collectFarmlandHotspotActions(actions)
	table.insert(actions, { callbackTarget = self, title = g_i18n:getText("ui_tramlines"), callback = self.onSetUpTramlines })
end
function TramlineMap:onSetUpTramlines(farmlandId)
	local callback = function(applyChanges, farmlands, implementWidthIndex, workDirectionIndex, spacingIndex)
		local numFarmlands = #farmlands
		if applyChanges and (0 < numFarmlands and (implementWidthIndex ~= 0 and workDirectionIndex ~= 0)) then
			local workingWidth = self.implementWidths[implementWidthIndex]
			local workDirection = self.workDirectionTextToDeg[workDirectionIndex]
			local spacing = self.spacings[spacingIndex]
			for index, farmland in ipairs(farmlands) do
				local enabled = index == numFarmlands
				self:setFarmlandTramlines(farmland:getId(), workingWidth, workDirection, spacing, enabled, false)
			end
		end
		if self.mapFrame ~= nil then
			self.mapFrame:toggleMapInput(true)
			self.mapFrame.ingameMap:onOpen()
			self.mapFrame.ingameMap:registerActionEvents()
			self.mapFrame.ingameMapBase:restoreDefaultFilter()
		end
	end
	local state = self.farmlandTramlineStates[farmlandId]
	local implementWidthIndex = 1
	local workDirectionIndex = 1
	local spacingIndex = 1
	if state ~= nil then
		for i, number in ipairs(self.implementWidths) do
			if number == state.workingWidth then
				implementWidthIndex = i
				break
			end
		end
		for i, _ in ipairs(self.workDirectionTextToDeg) do
			if math.abs(state.workDirection - self.workDirectionTextToDeg[i]) < 0.1 then
				workDirectionIndex = i
				break
			end
		end
		for i, number in ipairs(self.spacings) do
			if math.abs(state.spacing - number) < 0.1 then
				spacingIndex = i
				break
			end
		end
	end
	local fieldX = 0
	local fieldZ = 0
	local farmland = g_farmlandManager:getFarmlandById(farmlandId)
	if farmland ~= nil then
		fieldX, fieldZ = farmland:getIndicatorPosition()
	end
	if self.mapFrame ~= nil then
		self.mapFrame.ingameMap:onClose()
		self.mapFrame:toggleMapInput(false)
		self.mapFrame.ingameMapBase:restoreDefaultFilter()
	end
	TramlineSettingsDialog.show(implementWidthIndex, workDirectionIndex, spacingIndex, fieldX, fieldZ, callback)
end
function TramlineMap:debugTramlineSet(fieldId, workingWidth, workDirection, spacing)
	fieldId = tonumber(fieldId)
	workingWidth = tonumber(workingWidth) or 30
	workDirection = tonumber(workDirection) or -57.29577951308232
	spacing = tonumber(spacing) or 2
	local field = g_fieldManager:getFieldById(fieldId)
	if field ~= nil and field.getDensityMapPolygon ~= nil then
		self:setFarmlandTramlines(field:getId(), workingWidth, workDirection, spacing, true, true)
	end
end
function TramlineMap:onFarmlandStateChanged(farmlandId, farmId, loadFromSavegame)
	if not loadFromSavegame then
		if farmId == FarmlandManager.NO_OWNER_FARM_ID then
			local field = g_fieldManager:getFieldById(farmlandId)
			if field ~= nil then
				self:setFarmlandTramlines(farmlandId, self.npcWorkingWidth, -57.29577951308232, self.npcSpacing, true, false)
			end
		else
			Logging.devInfo("TramlineMap: Reset tramlines on bought farmland %d", farmlandId)
			self:setFarmlandTramlines(farmlandId, 0, 0, 0, true, false)
		end
	end
end
function TramlineMap:overwriteGameFunctions(pfModule)
	TramlineMap:superClass().overwriteGameFunctions(self, pfModule)
	pfModule:overwriteGameFunction(FSDensityMapUtil, "updateSowingArea", function(superFunc, fruitIndex, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, ...)
		local changedArea, totalArea = superFunc(fruitIndex, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, ...)
		local missionId = g_missionManager:getMissionMapActiveMissionIdAtWorldPosition((startWorldX + widthWorldX) * 0.5, (startWorldZ + widthWorldZ) * 0.5)
		if 0 < changedArea and missionId == 0 then
			self:clearTramlines(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, nil, false)
		end
		return changedArea, totalArea
	end)
	pfModule:overwriteGameFunction(FSDensityMapUtil, "updateDirectSowingArea", function(superFunc, fruitIndex, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, ...)
		local changedArea, totalArea = superFunc(fruitIndex, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, ...)
		local missionId = g_missionManager:getMissionMapActiveMissionIdAtWorldPosition((startWorldX + widthWorldX) * 0.5, (startWorldZ + widthWorldZ) * 0.5)
		if 0 < changedArea and missionId == 0 then
			self:clearTramlines(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, nil, false)
		end
		return changedArea, totalArea
	end)
	pfModule:overwriteGameFunction(FSDensityMapUtil, "updateWheelDestructionArea", function(superFunc, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, ...)
		local functionData = self.updateWheelDestructionAreaData
		if functionData == nil then
			local terrainRootNode = g_terrainNode
			local fieldGroundSystem = g_currentMission.fieldGroundSystem
			local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
			local sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_TYPE)
			functionData = {}
			functionData.modifier = DensityMapModifier.new(sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels, terrainRootNode)
			functionData.multiModifier = nil
			functionData.filter1 = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
			functionData.fieldFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
			functionData.fieldFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)
			functionData.tramlineFilter = DensityMapFilter.new(self.bitVectorMap, 1, 1)
			functionData.tramlineFilter:setValueCompareParams(DensityValueCompareType.EQUAL, 0)
			self.updateWheelDestructionAreaData = functionData
		end
		local modifier = functionData.modifier
		local multiModifier = functionData.multiModifier
		local filter1 = functionData.filter1
		local fieldFilter = functionData.fieldFilter
		local tramlineFilter = functionData.tramlineFilter
		g_currentMission.growthSystem:setIgnoreDensityChanges(true)
		if multiModifier == nil then
			multiModifier = DensityMapMultiModifier.new()
			functionData.multiModifier = multiModifier
			for _, desc in pairs(g_fruitTypeManager:getFruitTypes()) do
				if desc.terrainDataPlaneId == nil or desc.minWheelDestructionState == nil then
					continue
				end
				modifier:resetDensityMapAndChannels(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)
				filter1:resetDensityMapAndChannels(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)
				filter1:setValueCompareParams(DensityValueCompareType.BETWEEN, desc.minWheelDestructionState, desc.maxWheelDestructionState)
				multiModifier:addExecuteSet(desc.wheelDestructionState, modifier, filter1, fieldFilter, tramlineFilter)
			end
			for i = 1, #g_currentMission.dynamicFoliageLayers do
				local id = g_currentMission.dynamicFoliageLayers[i]
				local numChannels = getTerrainDetailNumChannels(id)
				modifier:resetDensityMapAndChannels(id, 0, numChannels)
				multiModifier:addExecuteSet(0, modifier)
			end
		end
		multiModifier:updateParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
		multiModifier:execute()
		FSDensityMapUtil.removeWeedArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
		g_currentMission.growthSystem:setIgnoreDensityChanges(false)
	end)
	pfModule:overwriteGameFunction(FieldUpdateTask, "prepare", function(superFunc, _self, ...)
		superFunc(_self, ...)
		self:addTramlineClearToMultiModifier(_self.multiModifier, true)
	end)
	pfModule:overwriteGameFunction(FarmlandManager, "loadFromXMLFile", function(superFunc, _self, xmlFilename, ...)
		local success = superFunc(_self, xmlFilename, ...)
		if self.npcWorkingWidth ~= nil then
			for _, farmland in ipairs(g_farmlandManager.sortedFarmlands) do
				local farmlandId = farmland:getId()
				if farmland.isOwned then
					continue
				end
				local field = g_fieldManager:getFieldById(farmlandId)
				if field == nil then
					continue
				end
				if self.farmlandTramlineStates[farmlandId] == nil then
					Logging.devInfo("Initialize tramlines on NPC field '%d'", farmlandId)
					self:setFarmlandTramlines(farmland:getId(), self.npcWorkingWidth, -57.29577951308232, self.npcSpacing, true, true, true)
				end
			end
		end
		return success
	end)
	pfModule:overwriteGameFunction(AbstractFieldMission, "initializeModifier", function(superFunc, _self, ...)
		superFunc(_self, ...)
		if self.missionTramlineModifier ~= nil then
			local densityMapPolygon = _self.field:getDensityMapPolygon()
			densityMapPolygon:applyToModifier(self.missionTramlineModifier)
		end
	end)
	pfModule:overwriteGameFunction(SowMission, "createModifier", function(superFunc, _self, ...)
		superFunc(_self, ...)
		if self.missionTramlineModifier == nil then
			self.missionTramlineModifier = DensityMapModifier.new(self.bitVectorMap, 0, 1, g_terrainNode)
			self.missionTramlineFilter = DensityMapFilter.new(self.bitVectorMap, 0, 1)
			self.missionTramlineFilter:setValueCompareParams(DensityValueCompareType.EQUAL, 1)
		end
	end)
	pfModule:overwriteGameFunction(SowMission, "getPartitionCompletion", function(superFunc, _self, partitionIndex, ...)
		local sumPixels, area, totalArea = superFunc(_self, partitionIndex, ...)
		if self.missionTramlineModifier ~= nil then
			if _self.completionPartitions ~= nil and 1 < #_self.completionPartitions then
				local partition = _self.completionPartitions[partitionIndex]
				self.missionTramlineModifier:setPolygonClipRegion(partition.minZ, partition.maxZ)
			end
			local _, tramlineArea, _ = self.missionTramlineModifier:executeGet(self.missionTramlineFilter)
			totalArea = totalArea - tramlineArea
		end
		return sumPixels, area, totalArea
	end)
end
