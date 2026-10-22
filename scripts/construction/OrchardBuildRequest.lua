OrchardBuildRequest = {}
local OrchardBuildRequest_mt = Class(OrchardBuildRequest)
OrchardBuildRequest.STATE = { PREPARE_AREA = 1, ROWS = 2, EXTRA_CONTENT_PENDING = 3, EXTRA_CONTENT_WAITING = 4, EXTRA_CONTENT = 5, FINISHED = 6 }
OrchardBuildRequest.BUILD_TIME_BUDGET = 0.008
OrchardBuildRequest.PROGRESS_INTERVAL = 0.2
OrchardBuildRequest.PLACEABLE_LOAD_TIMEOUT = 15000
OrchardBuildRequest.PLACEABLE_SYNC_TIMEOUT = 5000
OrchardBuildRequest.PREPARE_TIMEOUT = 15000
OrchardBuildRequest.GROUND_COVER_GROWTH_STATE = "greenSmall"
OrchardBuildRequest.PREPARE_AREA_MARGIN = 1
OrchardBuildRequest.BOUNDARY_MAX_MARGIN = 25
OrchardBuildRequest.LEGACY_FENCE_BRUSH_TYPES = { fence = true, vineOrchard = true }
function OrchardBuildRequest.new(connection, requestId, fencePlaceable, templateId, courseSegments, boundaryLine, optionStates, custom_mt)
	local self = setmetatable({}, custom_mt or OrchardBuildRequest_mt)
	self.connection = connection
	self.requestId = requestId
	self.fencePlaceable = fencePlaceable
	self.templateId = templateId
	self.courseSegments = courseSegments
	self.boundaryLine = boundaryLine
	self.optionStates = optionStates
	self.rowIndex = 1
	self.doneSteps = 0
	self.totalSteps = #courseSegments + 1
	self.builtSteps = 0
	self.statusCode = OrchardBuildFinishedEvent.STATUS.SUCCESS
	self.state = OrchardBuildRequest.STATE.PREPARE_AREA
	self.isCancelled = false
	self.areaTask = nil
	self.areaTimer = 0
	self.batchSegments = {}
	self.batchPlaceable = nil
	self.lastProgressTime = 0
	self.lockedPlaceables = {}
	self.extraLineIndex = 1
	self.extraNeedsBroadcast = false
	self.extraPendingTimer = 0
	self.extraSyncTimer = 0
	return self
end
function OrchardBuildRequest:start()
	if not g_currentMission:getHasPlayerPermission(Farm.PERMISSION.BUY_PLACEABLE, self.connection) then
		self:finish(OrchardBuildFinishedEvent.STATUS.NO_PERMISSION)
		return
	end
	local player = g_currentMission:getPlayerByConnection(self.connection)
	if player == nil or player.farmId == nil or player.farmId == FarmManager.SPECTATOR_FARM_ID then
		self:finish(OrchardBuildFinishedEvent.STATUS.NO_PERMISSION)
		return
	end
	self.farmId = player.farmId
	if self.fencePlaceable == nil or not self.fencePlaceable:getIsSynchronized() then
		self:finish(OrchardBuildFinishedEvent.STATUS.INVALID_REQUEST)
		return
	end
	self.isLegacyFence = OrchardBuildRequest.getIsLegacyFencePlaceable(self.fencePlaceable)
	local statusCode = nil
	if self.isLegacyFence then
		statusCode = self:validateLegacyFence()
	else
		statusCode = self:validateFence()
	end
	if statusCode ~= nil then
		self:finish(statusCode)
		return
	end
	if not self:getIsBoundaryValid() then
		self:finish(OrchardBuildFinishedEvent.STATUS.INVALID_REQUEST)
		return
	end
	if not self:getIsBoundaryOwned() then
		self:finish(OrchardBuildFinishedEvent.STATUS.LAND_UNOWNED)
		return
	end
	local areaPolygon = self:getAreaPolygon()
	if not self:getIsAreaClearOfRiceFields(areaPolygon) then
		self:finish(OrchardBuildFinishedEvent.STATUS.OVERLAP)
	else
		self:lockPlaceable(self.fencePlaceable)
		self:startAreaPreparation(areaPolygon)
		self.extraContent = self:getExtraContent()
		if self.extraContent ~= nil then
			self.totalSteps = self.totalSteps + #self.extraContent.lines
		end
		self.lastProgressTime = getTimeSec()
		self:sendProgress()
	end
end
function OrchardBuildRequest:validateFence()
	if self.fencePlaceable.getFence == nil then
		return OrchardBuildFinishedEvent.STATUS.INVALID_REQUEST
	end
	self.fence = self.fencePlaceable:getFence()
	if self.fence == nil then
		return OrchardBuildFinishedEvent.STATUS.INVALID_REQUEST
	elseif self.templateId == nil or self.fence:getSegmentTemplateById(self.templateId) == nil then
		return OrchardBuildFinishedEvent.STATUS.INVALID_REQUEST
	else
		return nil
	end
end
function OrchardBuildRequest:validateLegacyFence()
	if self.templateId ~= nil then
		return OrchardBuildFinishedEvent.STATUS.INVALID_REQUEST
	end
	if self.fencePlaceable:getOwnerFarmId() ~= self.farmId then
		return OrchardBuildFinishedEvent.STATUS.NO_PERMISSION
	end
	local panelLength = self.fencePlaceable:getPanelLength()
	if panelLength == nil or panelLength <= 0 then
		return OrchardBuildFinishedEvent.STATUS.INVALID_REQUEST
	end
	self.pricePerMeter = OrchardBuildRequest.getLegacyPricePerMeter(self.fencePlaceable)
	if self.pricePerMeter == nil then
		return OrchardBuildFinishedEvent.STATUS.INVALID_REQUEST
	else
		self.panelLength = panelLength
		return nil
	end
end
function OrchardBuildRequest:cancel()
	self.isCancelled = true
end
function OrchardBuildRequest:getHasFinished()
	return self.state == OrchardBuildRequest.STATE.FINISHED
end
function OrchardBuildRequest:update(dt)
	if self.isCancelled then
		self:finish(OrchardBuildFinishedEvent.STATUS.CANCELLED)
	else
		local budgetEndTime = getTimeSec() + OrchardBuildRequest.BUILD_TIME_BUDGET
		if self.state == OrchardBuildRequest.STATE.PREPARE_AREA then
			self:updateAreaPreparation(dt)
		end
		if self.state == OrchardBuildRequest.STATE.ROWS then
			self:updateRows(budgetEndTime)
		end
		if self.state == OrchardBuildRequest.STATE.EXTRA_CONTENT_PENDING then
			self:updateExtraContentPending(dt)
		end
		if self.state == OrchardBuildRequest.STATE.EXTRA_CONTENT_WAITING then
			self:updateExtraContentWaiting(dt)
		end
		if self.state == OrchardBuildRequest.STATE.EXTRA_CONTENT then
			self:updateExtraContent(budgetEndTime)
		end
		self:updateProgress()
	end
end
function OrchardBuildRequest:getIsBoundaryValid()
	local minRowX = math.huge
	local minRowZ = math.huge
	local maxRowX = -math.huge
	local maxRowZ = -math.huge
	for _, courseSegment in ipairs(self.courseSegments) do
		for _, position in ipairs(courseSegment.positions) do
			minRowX = math.min(minRowX, position[1])
			minRowZ = math.min(minRowZ, position[2])
			maxRowX = math.max(maxRowX, position[1])
			maxRowZ = math.max(maxRowZ, position[2])
		end
	end
	local margin = OrchardBuildRequest.BOUNDARY_MAX_MARGIN
	for _, position in ipairs(self.boundaryLine) do
		local isInsideX = minRowX - margin <= position[1] and position[1] <= maxRowX + margin
		local isInsideZ = minRowZ - margin <= position[2] and position[2] <= maxRowZ + margin
		if not isInsideX or not isInsideZ then
			return false
		end
	end
	return true
end
function OrchardBuildRequest:getIsBoundaryOwned()
	local numPositions = #self.boundaryLine
	for index = 1, numPositions do
		local position = self.boundaryLine[index]
		local nextPosition = self.boundaryLine[index % numPositions + 1]
		if g_farmlandManager:getIsOwnedByFarmAlongLine(self.farmId, position[1], position[2], nextPosition[1], nextPosition[2]) then
			continue
		end
		return false
	end
	return true
end
function OrchardBuildRequest:startAreaPreparation(areaPolygon)
	local fieldGroundSystem = g_currentMission.fieldGroundSystem
	local plowLevelMaxValue = Platform.gameplay.usePlowCounter and fieldGroundSystem:getMaxValue(FieldDensityMap.PLOW_LEVEL) or 0
	local limeLevelMaxValue = Platform.gameplay.useLimeCounter and fieldGroundSystem:getMaxValue(FieldDensityMap.LIME_LEVEL) or 0
	local areaTask = FieldUpdateTask.new()
	areaTask:setName(string.format("orchard build area of request %d", self.requestId))
	areaTask:setArea(areaPolygon)
	areaTask:clearCultivatedFruit()
	areaTask:clearDecoFoliage()
	self:setGroundCoverFruit(areaTask)
	areaTask:setWeedState(0)
	areaTask:setStoneLevel(0)
	areaTask:setGroundType(FieldGroundType.GRASS)
	areaTask:setGroundAngle(0)
	areaTask:setFieldType(FieldType.DEFAULT)
	areaTask:setSprayType(FieldSprayType.NONE)
	areaTask:setSprayLevel(0)
	areaTask:setPlowLevel(plowLevelMaxValue)
	areaTask:setLimeLevel(limeLevelMaxValue)
	areaTask:setRollerLevel(0)
	areaTask:setStubbleShredLevel(0)
	areaTask:setWaterLevel(0)
	areaTask:clearHeight()
	areaTask:resetDisplacement()
	areaTask:clearTireTracks()
	areaTask:start()
	self.areaTask = areaTask
	self.areaTimer = OrchardBuildRequest.PREPARE_TIMEOUT
end
function OrchardBuildRequest:getAreaPolygon()
	local boundaryPolygon = Polygon2D.new(#self.boundaryLine)
	for _, position in ipairs(self.boundaryLine) do
		boundaryPolygon:addPos(position[1], position[2])
	end
	local grownPolygon = boundaryPolygon:getOffsetPolygon(OrchardBuildRequest.PREPARE_AREA_MARGIN)
	if grownPolygon == nil then
		Logging.devWarning("Orchard build could not grow the boundary of request %d, preparing it as it is", self.requestId)
		grownPolygon = boundaryPolygon
	end
	local areaPolygon = DensityMapPolygon.new()
	areaPolygon:updateFromPolygon2D(grownPolygon)
	return areaPolygon
end
function OrchardBuildRequest:getIsAreaClearOfRiceFields(areaPolygon)
	local numRicePixels = FSDensityMapUtil.getFieldTypeAreaInPolygon(FieldType.RICE, areaPolygon)
	return numRicePixels == 0
end
function OrchardBuildRequest:setGroundCoverFruit(areaTask)
	if FruitType.MEADOW == nil then
		return
	end
	local fruitTypeDesc = g_fruitTypeManager:getFruitTypeByIndex(FruitType.MEADOW)
	if fruitTypeDesc == nil then
		return
	end
	local growthState = fruitTypeDesc:getGrowthStateByName(OrchardBuildRequest.GROUND_COVER_GROWTH_STATE)
	if growthState == nil then
		return
	else
		areaTask:setFruit(FruitType.MEADOW, growthState)
	end
end
function OrchardBuildRequest:updateAreaPreparation(dt)
	if self.areaTask == nil then
		self:finishAreaPreparation()
		return
	end
	self.areaTask:update(dt)
	if self.areaTask:getIsFinished() then
		self:finishAreaPreparation()
	else
		self.areaTimer = self.areaTimer - dt
		if self.areaTimer <= 0 then
			Logging.warning("Orchard build ground preparation did not finish in time, building the rows anyway")
			self:finishAreaPreparation()
		end
	end
end
function OrchardBuildRequest:finishAreaPreparation()
	self:dropAreaTask()
	self.doneSteps = self.doneSteps + 1
	self.state = OrchardBuildRequest.STATE.ROWS
end
function OrchardBuildRequest:dropAreaTask()
	if self.areaTask == nil then
		return
	else
		self.areaTask:cancel()
		self.areaTask = nil
	end
end
function OrchardBuildRequest:updateRows(budgetEndTime)
	while self.rowIndex <= #self.courseSegments do
		local positions = self.courseSegments[self.rowIndex].positions
		local startPos = positions[1]
		local endPos = positions[#positions]
		local continueRun = nil
		if self.isLegacyFence then
			continueRun = self:buildLegacyLine(startPos[1], startPos[2], endPos[1], endPos[2])
		else
			continueRun = self:buildLine(self.fencePlaceable, self.fence, self.templateId, startPos[1], startPos[2], endPos[1], endPos[2], true)
		end
		if not continueRun then
			return
		end
		self.rowIndex = self.rowIndex + 1
		if budgetEndTime <= getTimeSec() then
			return
		end
	end
	self:flushSegmentBatch()
	self:startExtraContentPhase()
end
function OrchardBuildRequest:getExtraContent()
	if self.fencePlaceable.getOrchardBuildExtraContent == nil then
		return nil
	end
	local extraContent = self.fencePlaceable:getOrchardBuildExtraContent(self.courseSegments, self.optionStates)
	if extraContent == nil then
		return nil
	elseif extraContent.placeableFilename ~= nil and extraContent.lines ~= nil and #extraContent.lines ~= 0 then
		return extraContent
	else
		return nil
	end
end
function OrchardBuildRequest:startExtraContentPhase()
	if self.extraContent == nil then
		self:finish(OrchardBuildFinishedEvent.STATUS.SUCCESS)
		return
	end
	local storeItem = g_storeManager:getItemByXMLFilename(self.extraContent.placeableFilename)
	if storeItem == nil then
		Logging.error("No store item found for orchard build extra content %q", tostring(self.extraContent.placeableFilename))
		self:finish(OrchardBuildFinishedEvent.STATUS.EXTRA_CONTENT_FAILED)
		return
	end
	self.extraStoreItem = storeItem
	local extraPlaceable = g_currentMission.placeableSystem:getExistingPlaceableByXMLFilename(storeItem.xmlFilename)
	if extraPlaceable ~= nil then
		self.extraNeedsBroadcast = true
		self:beginExtraContentBuild(extraPlaceable)
	else
		self:loadExtraPlaceable()
	end
end
function OrchardBuildRequest:loadExtraPlaceable()
	local loadingData = PlaceableLoadingData.new()
	loadingData:setStoreItem(self.extraStoreItem)
	loadingData:setPosition(0, PlacementUtil.NETHER_HEIGHT - 1, 0)
	loadingData:setRotation(0, 0, 0)
	loadingData:setOwnerFarmId(AccessHandler.EVERYONE)
	loadingData:setIsRegistered(false)
	self.extraNeedsBroadcast = false
	self.extraPendingTimer = OrchardBuildRequest.PLACEABLE_LOAD_TIMEOUT
	self.state = OrchardBuildRequest.STATE.EXTRA_CONTENT_PENDING
	loadingData:load(self.onExtraPlaceableLoaded, self)
end
function OrchardBuildRequest:onExtraPlaceableLoaded(placeable, loadingState, arguments)
	if self.state ~= OrchardBuildRequest.STATE.EXTRA_CONTENT_PENDING then
		if placeable ~= nil and loadingState == PlaceableLoadingState.OK then
			placeable:delete()
		end
	else
		if placeable == nil or loadingState ~= PlaceableLoadingState.OK then
			self:finish(OrchardBuildFinishedEvent.STATUS.EXTRA_CONTENT_FAILED)
			return
		end
		placeable:finalizePlacement()
		placeable:onBuy()
		if placeable.isDeleted then
			local existingPlaceable = g_currentMission.placeableSystem:getExistingPlaceableByXMLFilename(self.extraStoreItem.xmlFilename)
			if existingPlaceable == nil then
				self:finish(OrchardBuildFinishedEvent.STATUS.EXTRA_CONTENT_FAILED)
				return
			else
				self.extraNeedsBroadcast = true
				self:beginExtraContentBuild(existingPlaceable)
				return
			end
		end
		self.extraCreatedPlaceable = placeable
		self:beginExtraContentBuild(placeable)
	end
end
function OrchardBuildRequest:updateExtraContentPending(dt)
	self.extraPendingTimer = self.extraPendingTimer - dt
	if self.extraPendingTimer <= 0 then
		Logging.error("Orchard build extra content placeable did not finish loading in time")
		self:finish(OrchardBuildFinishedEvent.STATUS.EXTRA_CONTENT_FAILED)
	end
end
function OrchardBuildRequest:beginExtraContentBuild(extraPlaceable)
	if extraPlaceable.getFence == nil then
		self:finish(OrchardBuildFinishedEvent.STATUS.EXTRA_CONTENT_FAILED)
		return
	end
	local fence = extraPlaceable:getFence()
	if fence == nil then
		self:finish(OrchardBuildFinishedEvent.STATUS.EXTRA_CONTENT_FAILED)
		return
	end
	local templateId = fence:getSegmentTemplates()[1]
	if templateId == nil then
		self:finish(OrchardBuildFinishedEvent.STATUS.EXTRA_CONTENT_FAILED)
		return
	end
	self:lockPlaceable(extraPlaceable)
	self.extraPlaceable = extraPlaceable
	self.extraFence = fence
	self.extraTemplateId = templateId
	if not self.extraNeedsBroadcast then
		self.state = OrchardBuildRequest.STATE.EXTRA_CONTENT
	else
		self.extraSyncTimer = OrchardBuildRequest.PLACEABLE_SYNC_TIMEOUT
		self.state = OrchardBuildRequest.STATE.EXTRA_CONTENT_WAITING
	end
end
function OrchardBuildRequest:getIsSegmentCoveredForConnection(connection, placeable)
	if g_server:hasGhostObject(connection, placeable) then
		return true
	end
	local objectInfo = connection.objectsInfo[placeable.id]
	if objectInfo == nil then
		return true
	else
		return objectInfo.sync ~= Connection.SYNC_SYNCING
	end
end
function OrchardBuildRequest:getIsSegmentCovered(placeable)
	for _, connection in pairs(g_server.clientConnections) do
		if self:getIsSegmentCoveredForConnection(connection, placeable) then
			continue
		end
		return false
	end
	return true
end
function OrchardBuildRequest:updateExtraContentWaiting(dt)
	if self:getIsSegmentCovered(self.extraPlaceable) then
		self.state = OrchardBuildRequest.STATE.EXTRA_CONTENT
	else
		self.extraSyncTimer = self.extraSyncTimer - dt
		if self.extraSyncTimer <= 0 then
			Logging.warning("Orchard build gave up waiting for %q to reach every client", tostring(self.extraStoreItem.xmlFilename))
			self.state = OrchardBuildRequest.STATE.EXTRA_CONTENT
		end
	end
end
function OrchardBuildRequest:updateExtraContent(budgetEndTime)
	local lines = self.extraContent.lines
	while self.extraLineIndex <= #lines do
		local positions = lines[self.extraLineIndex]
		local startPos = positions[1]
		local endPos = positions[#positions]
		if not self:buildLine(self.extraPlaceable, self.extraFence, self.extraTemplateId, startPos[1], startPos[2], endPos[1], endPos[2], self.extraNeedsBroadcast) then
			return
		end
		self.extraLineIndex = self.extraLineIndex + 1
		if budgetEndTime <= getTimeSec() then
			return
		end
	end
	self:finish(OrchardBuildFinishedEvent.STATUS.SUCCESS)
end
function OrchardBuildRequest:buildLine(placeable, fence, templateId, startX, startZ, endX, endZ, needsBroadcast)
	if not g_farmlandManager:getIsOwnedByFarmAlongLine(self.farmId, startX, startZ, endX, endZ) then
		self:finish(OrchardBuildFinishedEvent.STATUS.LAND_UNOWNED)
		return false
	end
	local segment = fence:createNewSegment(templateId)
	if segment == nil then
		self:finish(OrchardBuildFinishedEvent.STATUS.INVALID_REQUEST)
		return false
	end
	local startY = getTerrainHeightAtWorldPos(g_terrainNode, startX, 0, startZ)
	local endY = getTerrainHeightAtWorldPos(g_terrainNode, endX, 0, endZ)
	segment:setStartPos(startX, startY, startZ)
	segment:setEndPos(endX, endY, endZ)
	if not segment:updateMeshes(true) then
		segment:delete()
		self.doneSteps = self.doneSteps + 1
		self.builtSteps = self.builtSteps + 1
		return true
	else
		local canBeBuilt = true
		if segment.getCanBeBuilt ~= nil then
			canBeBuilt = segment:getCanBeBuilt(self.farmId)
		end
		if not canBeBuilt then
			segment:delete()
			self:finish(OrchardBuildFinishedEvent.STATUS.BUILD_RESTRICTED)
			return false
		end
		local price = segment:getPrice()
		if g_currentMission:getMoney(self.farmId) < price then
			segment:delete()
			self:finish(OrchardBuildFinishedEvent.STATUS.NOT_ENOUGH_MONEY)
			return false
		else
			g_currentMission:addMoney(-price, self.farmId, MoneyType.SHOP_PROPERTY_BUY, true)
			segment:finalize()
			self.doneSteps = self.doneSteps + 1
			self.builtSteps = self.builtSteps + 1
			if needsBroadcast then
				self:addSegmentToBatch(placeable, segment)
			end
			return true
		end
	end
end
function OrchardBuildRequest:buildLegacyLine(startX, startZ, endX, endZ)
	if not g_farmlandManager:getIsOwnedByFarmAlongLine(self.farmId, startX, startZ, endX, endZ) then
		self:finish(OrchardBuildFinishedEvent.STATUS.LAND_UNOWNED)
		return false
	end
	local dirX = endX - startX
	local dirZ = endZ - startZ
	local lineLength = MathUtil.vector2Length(dirX, dirZ)
	local length = math.floor(lineLength / self.panelLength) * self.panelLength
	if length < self.panelLength then
		self.doneSteps = self.doneSteps + 1
		self.builtSteps = self.builtSteps + 1
		return true
	end
	local normalizedX = dirX / lineLength
	local normalizedZ = dirZ / lineLength
	local segment = self.fencePlaceable:createSegment(startX, startZ, startX + normalizedX * length, startZ + normalizedZ * length, true, nil)
	self.fencePlaceable:calculateSegmentPoles(segment)
	local verticalAngle = self.fencePlaceable:getMaxVerticalAngleAndYForSegment(segment)
	if self.fencePlaceable:getMaxVerticalAngle() < verticalAngle then
		self.doneSteps = self.doneSteps + 1
		self.builtSteps = self.builtSteps + 1
		return true
	end
	local price = length * self.pricePerMeter
	if g_currentMission:getMoney(self.farmId) < price then
		self:finish(OrchardBuildFinishedEvent.STATUS.NOT_ENOUGH_MONEY)
		return false
	else
		g_currentMission:addMoney(-price, self.farmId, MoneyType.SHOP_PROPERTY_BUY, true)
		self.fencePlaceable:addSegment(segment, true)
		g_messageCenter:publish(PlaceableFenceAddSegmentEvent, self.fencePlaceable, segment)
		self.doneSteps = self.doneSteps + 1
		self.builtSteps = self.builtSteps + 1
		self:addSegmentToBatch(self.fencePlaceable, segment)
		return true
	end
end
function OrchardBuildRequest:addSegmentToBatch(placeable, segment)
	local maxSegments = FenceSegmentBatchEvent.MAX_SEGMENTS
	if OrchardBuildRequest.getIsLegacyFencePlaceable(placeable) then
		maxSegments = PlaceableFenceSegmentBatchEvent.MAX_SEGMENTS
	end
	if self.batchPlaceable ~= placeable or maxSegments <= #self.batchSegments then
		self:flushSegmentBatch()
	end
	self.batchPlaceable = placeable
	table.insert(self.batchSegments, segment)
end
function OrchardBuildRequest:flushSegmentBatch()
	if #self.batchSegments == 0 then
		return
	else
		local event = nil
		if OrchardBuildRequest.getIsLegacyFencePlaceable(self.batchPlaceable) then
			event = PlaceableFenceSegmentBatchEvent.new(self.batchPlaceable, self.batchSegments)
		else
			event = FenceSegmentBatchEvent.newSegments(self.batchPlaceable, self.batchSegments)
		end
		g_server:broadcastEvent(event, false, nil, self.batchPlaceable)
		self.batchSegments = {}
		self.batchPlaceable = nil
	end
end
function OrchardBuildRequest:updateProgress()
	if self:getHasFinished() then
		return
	end
	if getTimeSec() - self.lastProgressTime >= OrchardBuildRequest.PROGRESS_INTERVAL then
		self:flushSegmentBatch()
		self:sendProgress()
		self.lastProgressTime = getTimeSec()
	end
end
function OrchardBuildRequest:sendProgress()
	if not self.connection.isConnected then
		return
	else
		self.connection:sendEvent(FenceSegmentBatchEvent.newProgress(self.requestId, self.doneSteps, self.totalSteps))
	end
end
function OrchardBuildRequest:lockPlaceable(placeable)
	if placeable.setBuildLocked ~= nil and not self.lockedPlaceables[placeable] then
		placeable:setBuildLocked(true)
		self.lockedPlaceables[placeable] = true
	end
end
function OrchardBuildRequest:finish(statusCode)
	if self:getHasFinished() then
		return
	else
		self.state = OrchardBuildRequest.STATE.FINISHED
		self.statusCode = statusCode
		self:dropAreaTask()
		self:flushSegmentBatch()
		if self.extraCreatedPlaceable ~= nil and not self.extraCreatedPlaceable.isDeleted then
			self.extraCreatedPlaceable:register()
			self.extraCreatedPlaceable = nil
		end
		for placeable in pairs(self.lockedPlaceables) do
			if placeable.isDeleted then
				continue
			end
			placeable:setBuildLocked(false)
		end
		self.lockedPlaceables = {}
		if 0 < self.builtSteps then
			g_currentMission:showMoneyChange(MoneyType.SHOP_PROPERTY_BUY, nil, false, self.farmId)
		end
		if self.connection.isConnected then
			self.connection:sendEvent(OrchardBuildFinishedEvent.new(self.requestId, statusCode, self.builtSteps))
		end
	end
end
function OrchardBuildRequest.getIsLegacyFencePlaceable(placeable)
	return placeable.spec_fence ~= nil and placeable.getFence == nil
end
function OrchardBuildRequest.getLegacyPricePerMeter(placeable)
	for _, storeItem in ipairs(g_storeManager:getItems()) do
		local brush = storeItem.brush
		if brush == nil then
			continue
		end
		if OrchardBuildRequest.LEGACY_FENCE_BRUSH_TYPES[brush.type] then
			local isGate = brush.parameters[2] == "true"
			if isGate then
				continue
			end
			if brush.parameters[1] == placeable.configFileName then
				return storeItem.price
			end
		end
	end
	return nil
end
