OrchardBoundaryEditor = {}
local OrchardBoundaryEditor_mt = Class(OrchardBoundaryEditor)
OrchardBoundaryEditor.MIN_BOUNDARY_POINTS = 3
OrchardBoundaryEditor.MIN_CORNER_DISTANCE = 1
OrchardBoundaryEditor.NUM_HEADLANDS = 1
OrchardBoundaryEditor.DRAW_Y_OFFSET = 0.2
OrchardBoundaryEditor.PENDING_COLOR = Color.PRESETS.ORANGE
OrchardBoundaryEditor.INVALID_COLOR = Color.PRESETS.RED
OrchardBoundaryEditor.FINISH_COLOR = Color.PRESETS.GREEN
OrchardBoundaryEditor.LINE_SCALE = 4
OrchardBoundaryEditor.DETECTION_TIME_BUDGET = 0.002
OrchardBoundaryEditor.BOUNDARY_INSET = 1
OrchardBoundaryEditor.BOUNDARY_SIMPLIFY_TOLERANCE = 1
OrchardBoundaryEditor.BOUNDARY_CLOSING_THRESHOLD = 0.01
function OrchardBoundaryEditor.new(brush, custom_mt)
	local self = setmetatable({}, custom_mt or OrchardBoundaryEditor_mt)
	self.brush = brush
	self.boundaryPoints = {}
	self.isDetectingBoundary = false
	self.detectionField = nil
	self.isBoundaryImported = false
	self.canImportBoundary = false
	self.detectingText = g_i18n:getText("ui_construction_detectingFieldBoundary")
	self.lineVisualization = Line3D.new()
	self.lineVisualization:setLineScale(OrchardBoundaryEditor.LINE_SCALE, OrchardBoundaryEditor.LINE_SCALE)
	return self
end
function OrchardBoundaryEditor:delete()
	g_messageCenter:unsubscribe(OrchardBuildFinishedEvent, self)
	self:cancelFieldBoundaryDetection()
	self.lineVisualization:delete()
end
function OrchardBoundaryEditor:activate()
	self:resetBoundary()
	g_messageCenter:subscribe(OrchardBuildFinishedEvent, self.onBuildFinished, self)
end
function OrchardBoundaryEditor:deactivate()
	g_messageCenter:unsubscribe(OrchardBuildFinishedEvent, self)
	self:resetBoundary()
	self.lineVisualization:clearVisualization()
end
function OrchardBoundaryEditor:getIsBuilding()
	local buildClient = g_currentMission.orchardBuildClient
	local _v1 = false
	if buildClient ~= nil then
		_v1 = buildClient:getIsBuilding()
	end
	return _v1
end
function OrchardBoundaryEditor:getIsBusy()
	return self:getIsBuilding() or self.isDetectingBoundary
end
function OrchardBoundaryEditor:getCanCancel()
	return self.isDetectingBoundary or 0 < #self.boundaryPoints
end
function OrchardBoundaryEditor:resetBoundary()
	self.boundaryPoints = {}
	self.isBoundaryImported = false
	self:cancelFieldBoundaryDetection()
end
function OrchardBoundaryEditor:clearVisualization()
	self.lineVisualization:clearVisualization()
end
function OrchardBoundaryEditor:getBoundaryCursorPosition()
	local x, y, z = self.brush.cursor:getHitTerrainPosition()
	if x == nil then
		return nil
	else
		if self.brush.snappingActive then
			x = MathUtil.snapValue(x, self.brush.snappingSize)
			z = MathUtil.snapValue(z, self.brush.snappingSize)
			y = getTerrainHeightAtWorldPos(g_terrainNode, x, 0, z)
		end
		return x, y, z
	end
end
function OrchardBoundaryEditor:getIsNearLastPoint(x, z, minDistance)
	if #self.boundaryPoints < 1 then
		return false
	else
		local lastPoint = self.boundaryPoints[#self.boundaryPoints]
		local distance = MathUtil.vector2Length(lastPoint[1] - x, lastPoint[3] - z)
		return distance < minDistance
	end
end
function OrchardBoundaryEditor:getIsNearFirstPoint(x, z, minDistance)
	if #self.boundaryPoints < 1 then
		return false
	else
		local firstPoint = self.boundaryPoints[1]
		local distance = MathUtil.vector2Length(firstPoint[1] - x, firstPoint[3] - z)
		return distance < minDistance
	end
end
function OrchardBoundaryEditor:getIsCursorOnOwnedLand(x, z)
	local farmId = g_localPlayer.farmId
	local numPoints = #self.boundaryPoints
	if numPoints == 0 then
		return g_farmlandManager:getIsOwnedByFarmAtWorldPosition(farmId, x, z)
	else
		local lastPoint = self.boundaryPoints[numPoints]
		return g_farmlandManager:getIsOwnedByFarmAlongLine(farmId, lastPoint[1], lastPoint[3], x, z)
	end
end
function OrchardBoundaryEditor:getIsBoundaryLineOnOwnedLand(boundaryLine)
	local farmId = g_localPlayer.farmId
	for index = 1, #boundaryLine - 1 do
		local position = boundaryLine[index]
		local nextPosition = boundaryLine[index + 1]
		if g_farmlandManager:getIsOwnedByFarmAlongLine(farmId, position[1], position[2], nextPosition[1], nextPosition[2]) then
			continue
		end
		return false
	end
	return true
end
function OrchardBoundaryEditor:getIsCursorClearOfRiceFields(x, z)
	local numPoints = #self.boundaryPoints
	if numPoints == 0 then
		return self.brush:getIsPositionClearOfRiceFields(x, z)
	else
		local lastPoint = self.boundaryPoints[numPoints]
		return self.brush:getIsLineClearOfRiceFields(lastPoint[1], lastPoint[3], x, z)
	end
end
function OrchardBoundaryEditor:getIsBoundaryClearOfRiceFields(boundaryLine)
	if #boundaryLine < OrchardBoundaryEditor.MIN_BOUNDARY_POINTS then
		return true
	else
		local area = DensityMapPolygon.new()
		for _, position in ipairs(boundaryLine) do
			area:addPolygonPoint(position[1], position[2])
		end
		local numRicePixels = FSDensityMapUtil.getFieldTypeAreaInPolygon(FieldType.RICE, area)
		return numRicePixels == 0
	end
end
function OrchardBoundaryEditor:getCanImportFieldBoundary()
	if self.brush:getOrchardBuildPlaceable() == nil then
		return false
	end
	if self:getIsBusy() then
		return false
	end
	if 0 < #self.boundaryPoints then
		return false
	end
	if not self.brush:hasPlayerPermission() then
		return false
	end
	local x, y, z = self:getBoundaryCursorPosition()
	if x == nil or y == nil or z == nil then
		return false
	end
	local isOnField = FSDensityMapUtil.getFieldDataAtWorldPosition(x, y, z)
	if not isOnField then
		return false
	else
		return self:getIsCursorOnOwnedLand(x, z)
	end
end
function OrchardBoundaryEditor:setCanImportBoundary(canImport)
	if self.canImportBoundary == canImport then
		return
	else
		self.canImportBoundary = canImport
		self.brush:setInputTextDirty()
	end
end
function OrchardBoundaryEditor:startFieldBoundaryDetection()
	if self.isDetectingBoundary then
		return
	end
	local x, _, z = self:getBoundaryCursorPosition()
	if x == nil or z == nil then
		return
	end
	self.isDetectingBoundary = true
	self.brush:setInputTextDirty()
	local settings = FieldCourseSettings.new()
	local courseField = FieldCourseField.generateAtPosition(x, z, settings, self.onFieldBoundaryDetected, self)
	if not self.isDetectingBoundary then
		return
	else
		self.detectionField = courseField
		courseField:setIgnoreIslands(true)
		courseField:setIgnoreCollisions(true)
	end
end
function OrchardBoundaryEditor:cancelFieldBoundaryDetection()
	if not self.isDetectingBoundary then
		return
	else
		self.isDetectingBoundary = false
		self.detectionField = nil
		self.brush:setInputTextDirty()
	end
end
function OrchardBoundaryEditor:onFieldBoundaryDetected(courseField, success)
	if not self.isDetectingBoundary then
		return
	else
		self.isDetectingBoundary = false
		self.detectionField = nil
		self.brush:setInputTextDirty()
		if not success or courseField.fieldRootBoundary == nil then
			g_currentMission:showBlinkingWarning(g_i18n:getText("ui_construction_fieldBoundaryNotFound"))
			return
		end
		self:adoptFieldBoundary(courseField.fieldRootBoundary)
	end
end
function OrchardBoundaryEditor:adoptFieldBoundary(boundary)
	local insetBoundary = boundary:extend(OrchardBoundaryEditor.BOUNDARY_INSET) or boundary
	local boundaryLine = insetBoundary.boundaryLine
	FieldCourseUtil.douglasPeucker(boundaryLine, OrchardBoundaryEditor.BOUNDARY_SIMPLIFY_TOLERANCE)
	if not self:getIsBoundaryLineOnOwnedLand(boundaryLine) then
		g_currentMission:showBlinkingWarning(g_i18n:getText(ConstructionBrush.ERROR_MESSAGES[ConstructionBrush.ERROR.LAND_UNOWNED]))
		return
	end
	local numPositions = #boundaryLine
	if 1 < numPositions then
		local firstPosition = boundaryLine[1]
		local lastPosition = boundaryLine[numPositions]
		local closingDistance = MathUtil.vector2Length(lastPosition[1] - firstPosition[1], lastPosition[2] - firstPosition[2])
		if closingDistance < OrchardBoundaryEditor.BOUNDARY_CLOSING_THRESHOLD then
			numPositions = numPositions - 1
		end
	end
	if numPositions < OrchardBoundaryEditor.MIN_BOUNDARY_POINTS then
		g_currentMission:showBlinkingWarning(g_i18n:getText("ui_construction_fieldBoundaryNotFound"))
	elseif not self:getIsBoundaryClearOfRiceFields(boundaryLine) then
		g_currentMission:showBlinkingWarning(g_i18n:getText("ui_construction_overlapsWithObject"))
	else
		local boundaryPoints = {}
		for index = 1, numPositions do
			local position = boundaryLine[index]
			local y = getTerrainHeightAtWorldPos(g_terrainNode, position[1], 0, position[2])
			table.insert(boundaryPoints, { position[1], y, position[2] })
		end
		self.boundaryPoints = boundaryPoints
		self.isBoundaryImported = true
		self.brush:setInputTextDirty()
		self:openPreview()
	end
end
function OrchardBoundaryEditor:getBuildLimitWarning()
	if self.isBoundaryImported then
		return nil
	else
		local placeable = self.brush:getOrchardBuildPlaceable()
		if placeable == nil or placeable.getOrchardBuildLimitWarning == nil then
			return nil
		end
		local panelLength = self.brush:getOrchardPanelLength()
		return placeable:getOrchardBuildLimitWarning(1, panelLength or 0, panelLength)
	end
end
function OrchardBoundaryEditor:getBoundaryLine()
	local boundaryLine = {}
	for _, point in ipairs(self.boundaryPoints) do
		table.insert(boundaryLine, { point[1], point[3] })
	end
	return boundaryLine
end
function OrchardBoundaryEditor:openPreview()
	if self:getIsBuilding() then
		return
	end
	local placeable = self.brush:getOrchardBuildPlaceable()
	if placeable == nil then
		return
	end
	if #self.boundaryPoints < OrchardBoundaryEditor.MIN_BOUNDARY_POINTS then
		return
	end
	local spacing = self.brush:getOrchardRowSpacing()
	local boundaryLine = self:getBoundaryLine()
	if not self:getIsBoundaryClearOfRiceFields(boundaryLine) then
		g_currentMission:showBlinkingWarning(g_i18n:getText("ui_construction_overlapsWithObject"))
	else
		local firstPoint = self.boundaryPoints[1]
		table.insert(boundaryLine, { firstPoint[1], firstPoint[3] })
		local settings = FieldCourseSettings.new()
		settings.implementWidth = spacing
		settings.workDirectionForceStraightLines = true
		settings.numHeadlands = OrchardBoundaryEditor.NUM_HEADLANDS
		settings.segmentExtendedToBoundary = true
		local pricePerMeter = self.brush:getOrchardPricePerMeter()
		local panelLength = self.brush:getOrchardPanelLength()
		local customOptions = nil
		if placeable.getOrchardBrushOptions ~= nil then
			customOptions = placeable:getOrchardBrushOptions()
		end
		OrchardBrushDialog.show(boundaryLine, settings, spacing, pricePerMeter, panelLength, customOptions, placeable, self.onPreviewClosed, self)
	end
end
function OrchardBoundaryEditor:onPreviewClosed(confirmed, settings, segments, optionStates)
	if not confirmed then
		self.isBoundaryImported = false
	else
		if segments == nil or #segments == 0 then
			return
		end
		self:startBuild(segments, optionStates)
	end
end
function OrchardBoundaryEditor:startBuild(segments, optionStates)
	local placeable = self.brush:getOrchardBuildPlaceable()
	if placeable == nil then
		return
	end
	local buildClient = g_currentMission.orchardBuildClient
	if buildClient == nil then
		return
	end
	local templateId = self.brush:getOrchardBuildTemplateId()
	if not buildClient:startBuild(placeable, templateId, segments, self:getBoundaryLine(), optionStates) then
		return
	else
		self.brush:setInputTextDirty()
	end
end
function OrchardBoundaryEditor:onBuildFinished(requestId, statusCode, builtSteps)
	self.brush:setInputTextDirty()
	if 0 < builtSteps then
		self:resetBoundary()
	end
end
function OrchardBoundaryEditor:update(dt)
	self.lineVisualization:clearVisualization()
	self:setCanImportBoundary(self:getCanImportFieldBoundary())
	if self.isDetectingBoundary then
		self:updateBoundaryDetection(dt)
		return
	end
	local cursor = self.brush.cursor
	if self.brush:getOrchardBuildPlaceable() == nil then
		if not self.brush:hasPlayerPermission() then
			cursor:setColorMode(GuiTopDownCursor.SHAPES_COLORS.ERROR)
			cursor:setErrorMessage(g_i18n:getText(ConstructionBrush.ERROR_MESSAGES[ConstructionBrush.ERROR.NO_PERMISSION]))
		end
	elseif not self:getIsBuilding() then
		local x, y, z = self:getBoundaryCursorPosition()
		if x == nil or y == nil or z == nil then
			return
		end
		cursor:setPosition(x, y, z)
		local isOnOwnedLand = self.isBoundaryImported or self:getIsCursorOnOwnedLand(x, z)
		local isClearOfRiceFields = true
		if isOnOwnedLand and not self.isBoundaryImported then
			isClearOfRiceFields = self:getIsCursorClearOfRiceFields(x, z)
		end
		local isCursorValid = isOnOwnedLand and isClearOfRiceFields
		local limitWarning = nil
		if isCursorValid then
			limitWarning = self:getBuildLimitWarning()
		end
		if not isOnOwnedLand then
			cursor:setColorMode(GuiTopDownCursor.SHAPES_COLORS.ERROR)
			cursor:setErrorMessage(g_i18n:getText(ConstructionBrush.ERROR_MESSAGES[ConstructionBrush.ERROR.LAND_UNOWNED]))
		elseif not isClearOfRiceFields then
			cursor:setColorMode(GuiTopDownCursor.SHAPES_COLORS.ERROR)
			cursor:setErrorMessage(g_i18n:getText("ui_construction_overlapsWithObject"))
		elseif limitWarning ~= nil then
			cursor:setColorMode(GuiTopDownCursor.SHAPES_COLORS.ERROR)
			cursor:setErrorMessage(limitWarning)
		else
			cursor:setColorMode(GuiTopDownCursor.SHAPES_COLORS.SUCCESS)
		end
		self:updateBoundaryVisualization(x, y, z, isCursorValid)
	end
end
function OrchardBoundaryEditor:updateInactive()
	self.lineVisualization:clearVisualization()
	self:setCanImportBoundary(false)
end
function OrchardBoundaryEditor:updateBoundaryDetection(dt)
	if self.detectionField == nil then
		self:cancelFieldBoundaryDetection()
	else
		self.brush.cursor:setMessage(self.detectingText)
		self.detectionField:update(dt, OrchardBoundaryEditor.DETECTION_TIME_BUDGET)
	end
end
function OrchardBoundaryEditor:updateBoundaryVisualization(cursorX, cursorY, cursorZ, isCursorValid)
	local numPoints = #self.boundaryPoints
	if numPoints == 0 then
		return
	else
		local offset = OrchardBoundaryEditor.DRAW_Y_OFFSET
		local placedColor = OrchardBoundaryEditor.MIN_BOUNDARY_POINTS <= numPoints and OrchardBoundaryEditor.FINISH_COLOR or OrchardBoundaryEditor.PENDING_COLOR
		for i = 1, numPoints - 1 do
			local point1 = self.boundaryPoints[i]
			local point2 = self.boundaryPoints[i + 1]
			self.lineVisualization:visualizeLine(point1[1], point1[2] + offset, point1[3], point2[1], point2[2] + offset, point2[3], false, placedColor)
		end
		local lastPoint = self.boundaryPoints[numPoints]
		if not self.isBoundaryImported then
			local previewColor = isCursorValid and OrchardBoundaryEditor.PENDING_COLOR or OrchardBoundaryEditor.INVALID_COLOR
			self.lineVisualization:visualizeLine(lastPoint[1], lastPoint[2] + offset, lastPoint[3], cursorX, cursorY + offset, cursorZ, false, previewColor)
		end
		if canFinish then
			local firstPoint = self.boundaryPoints[1]
			self.lineVisualization:visualizeLine(lastPoint[1], lastPoint[2] + offset, lastPoint[3], firstPoint[1], firstPoint[2] + offset, firstPoint[3], false, OrchardBoundaryEditor.FINISH_COLOR)
		end
	end
end
function OrchardBoundaryEditor:onButtonPrimary()
	if self:getIsBusy() then
		return
	end
	if self.brush:getOrchardBuildPlaceable() == nil then
		return
	end
	if not self.brush:hasPlayerPermission() then
		return
	end
	local x, y, z = self:getBoundaryCursorPosition()
	if x == nil or y == nil or z == nil then
		return
	end
	if not self:getIsCursorOnOwnedLand(x, z) then
		return
	elseif not self:getIsCursorClearOfRiceFields(x, z) then
		return
	elseif self:getIsNearFirstPoint(x, z, OrchardBoundaryEditor.MIN_CORNER_DISTANCE) then
		if OrchardBoundaryEditor.MIN_BOUNDARY_POINTS <= #self.boundaryPoints then
			self:openPreview()
		end
	elseif not self:getIsNearLastPoint(x, z, OrchardBoundaryEditor.MIN_CORNER_DISTANCE) then
		self.isBoundaryImported = false
		table.insert(self.boundaryPoints, { x, y, z })
		self.brush:setInputTextDirty()
	end
end
function OrchardBoundaryEditor:onButtonSecondary()
	if self:getIsBusy() then
		return
	else
		if OrchardBoundaryEditor.MIN_BOUNDARY_POINTS <= #self.boundaryPoints then
			self:openPreview()
		end
	end
end
function OrchardBoundaryEditor:onButtonTertiary()
	if self:getIsBusy() then
		return
	elseif 0 < #self.boundaryPoints then
		table.remove(self.boundaryPoints)
		self.isBoundaryImported = false
		self.brush:setInputTextDirty()
	else
		if self.canImportBoundary then
			self:startFieldBoundaryDetection()
		end
	end
end
function OrchardBoundaryEditor:cancel()
	self:resetBoundary()
	self.brush:setInputTextDirty()
end
function OrchardBoundaryEditor:getButtonPrimaryText()
	if self.isDetectingBoundary then
		return nil
	else
		return g_i18n:getText("action_orchardBrushAddPoint")
	end
end
function OrchardBoundaryEditor:getButtonSecondaryText()
	if self.isDetectingBoundary then
		return nil
	elseif #self.boundaryPoints >= OrchardBoundaryEditor.MIN_BOUNDARY_POINTS then
		return g_i18n:getText("action_orchardBrushFinishBoundary")
	else
		return nil
	end
end
function OrchardBoundaryEditor:getButtonTertiaryText()
	if self.isDetectingBoundary then
		return nil
	elseif 0 < #self.boundaryPoints then
		return g_i18n:getText("action_orchardBrushRemovePoint")
	elseif self.canImportBoundary then
		return g_i18n:getText("action_orchardBrushUseField")
	else
		return nil
	end
end
