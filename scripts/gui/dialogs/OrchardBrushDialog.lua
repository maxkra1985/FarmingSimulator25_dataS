OrchardBrushDialog = {}
OrchardBrushDialog.LINE_COLORS = {}
OrchardBrushDialog.LINE_COLORS.BOUNDARY = { 0.0273, 0.0612, 0.3324, 1 }
OrchardBrushDialog.LINE_COLORS.HEADLAND = { 0.2122, 0.5029, 0.402, 1 }
OrchardBrushDialog.LINE_COLORS.STRAIGHT = { 0.402, 0.2051, 0.0144, 1 }
OrchardBrushDialog.COLOR_AFFORDABLE = { 0.32811, 0.6038, 0.04229, 1 }
OrchardBrushDialog.COLOR_NOT_AFFORDABLE = { 0.80692, 0.09085, 0.07034, 1 }
OrchardBrushDialog.WORK_DIRECTION_AUTOMATIC = -1
OrchardBrushDialog.WORK_DIRECTION_STEP_DEG = 1
OrchardBrushDialog.WORK_DIRECTION_MAX_DEG = 179
OrchardBrushDialog.FIELD_COURSE_UPDATE_DELAY = 1000
OrchardBrushDialog.MAP_BOUNDARY_PADDING = 0.1
OrchardBrushDialog.MIN_SEGMENT_LENGTH = 0.25
OrchardBrushDialog.MIN_BOUNDARY_POSITIONS = 4
local OrchardBrushDialog_mt = Class(OrchardBrushDialog, MessageDialog)
function OrchardBrushDialog.register()
	local dialog = OrchardBrushDialog.new()
	g_gui:loadGui("dataS/gui/dialogs/OrchardBrushDialog.xml", "OrchardBrushDialog", dialog)
	OrchardBrushDialog.INSTANCE = dialog
end
function OrchardBrushDialog.show(boundaryLine, fieldCourseSettings, rowSpacing, pricePerMeter, panelLength, customOptions, optionsProvider, callback, target)
	if OrchardBrushDialog.INSTANCE == nil then
		return
	else
		local dialog = OrchardBrushDialog.INSTANCE
		dialog:setCallback(callback, target)
		dialog.boundaryLine = boundaryLine
		dialog.fieldCourseSettings = fieldCourseSettings
		dialog.rowSpacing = rowSpacing
		dialog.pricePerMeter = pricePerMeter
		dialog.panelLength = panelLength
		dialog.customOptions = customOptions
		dialog.optionsProvider = optionsProvider
		g_gui:showDialog("OrchardBrushDialog")
	end
end
function OrchardBrushDialog.new(target, custom_mt)
	local self = MessageDialog.new(target, custom_mt or OrchardBrushDialog_mt)
	self.ingameMapElement = nil
	self.fieldCourseUpdateTimer = 0
	self.fieldCourseLoading = false
	self.lineWidth = 1 / g_screenHeight
	self.workDirectionValues = {}
	self.defaultWorkDirection = nil
	self.pricePerMeter = 0
	self.panelLength = nil
	self.customOptions = nil
	self.optionsProvider = nil
	self.optionStates = {}
	self.elementToOptionIndex = {}
	self.hasExistingRows = false
	return self
end
function OrchardBrushDialog:delete()
	if self.customOptionTemplate ~= nil then
		self.customOptionTemplate:delete()
		self.customOptionTemplate = nil
	end
	OrchardBrushDialog:superClass().delete(self)
end
function OrchardBrushDialog.createFromExistingGui(gui, guiName)
	OrchardBrushDialog.register()
	OrchardBrushDialog.show(gui.boundaryLine, gui.fieldCourseSettings, gui.rowSpacing, gui.pricePerMeter, gui.panelLength, gui.customOptions, gui.optionsProvider, gui.callbackFunc, gui.target)
end
function OrchardBrushDialog:onGuiSetupFinished()
	OrchardBrushDialog:superClass().onGuiSetupFinished(self)
	self.workDirectionValues = {}
	local texts = {}
	for degrees = 0, OrchardBrushDialog.WORK_DIRECTION_MAX_DEG, OrchardBrushDialog.WORK_DIRECTION_STEP_DEG do
		local workDirection = math.rad(OrchardBrushDialog.flipWorkDirectionSense(degrees))
		table.insert(self.workDirectionValues, workDirection)
		table.insert(texts, string.format("%d\194\176", degrees))
	end
	self.workDirectionOption:setTexts(texts)
	self.customOptionTemplate:unlinkElement()
	FocusManager:removeElement(self.customOptionTemplate)
end
function OrchardBrushDialog:setCallback(callbackFunc, target)
	self.callbackFunc = callbackFunc
	self.target = target
end
function OrchardBrushDialog:onOpen()
	OrchardBrushDialog:superClass().onOpen(self)
	self.ingameMapElement.drawHotspots = false
	self.ingameMapElement:setIngameMap(g_currentMission.hud:getIngameMap())
	self.ingameMapElement:onOpen()
	self.fieldCourse = nil
	self.fieldCourseUpdateTimer = 0
	self.hasExistingRows = false
	self.fieldCourseSettings.workDirection = OrchardBrushDialog.WORK_DIRECTION_AUTOMATIC
	self.defaultWorkDirection = nil
	local areaHa = self:getBoundaryAreaHa()
	self.fieldAreaText:setText(g_i18n:formatArea(areaHa, 2))
	self:assignCustomOptions()
	self:updateOptionStates()
	self:updateFieldCourse()
	g_messageCenter:subscribe(MessageType.MONEY_CHANGED, self.updateBuildStatus, self)
	FocusManager:setFocus(self.workDirectionOption)
end
function OrchardBrushDialog:assignCustomOptions()
	for i = #self.customOptionsLayout.elements, 1, -1 do
		self.customOptionsLayout.elements[i]:delete()
		self.customOptionsLayout.elements[i] = nil
	end
	self.optionStates = {}
	self.elementToOptionIndex = {}
	if self.customOptions ~= nil then
		for index, optionData in ipairs(self.customOptions) do
			local row = self.customOptionTemplate:clone(self.customOptionsLayout)
			local nameElement = row:getDescendantByName("name")
			nameElement:setText(optionData.title)
			local defaultState = optionData.default or 1
			local optionElement = row:getDescendantByName("option")
			optionElement:setTexts(optionData.texts)
			optionElement:setState(defaultState)
			self.optionStates[index] = defaultState
			self.elementToOptionIndex[optionElement] = index
		end
	end
	self.customOptionsLayout:invalidateLayout()
end
function OrchardBrushDialog:onClose()
	OrchardBrushDialog:superClass().onClose(self)
	g_messageCenter:unsubscribe(MessageType.MONEY_CHANGED, self)
	self.ingameMapElement:onClose()
	self.fieldCourse = nil
	self.hasExistingRows = false
	if g_gui.currentlyReloading then
		return
	else
		self.boundaryLine = nil
		self.fieldCourseSettings = nil
		self.pricePerMeter = 0
		self.panelLength = nil
		self.customOptions = nil
		self.optionsProvider = nil
		self.callbackFunc = nil
		self.target = nil
	end
end
function OrchardBrushDialog:update(dt)
	OrchardBrushDialog:superClass().update(self, dt)
	if 0 < self.fieldCourseUpdateTimer then
		self.fieldCourseUpdateTimer = self.fieldCourseUpdateTimer - dt
		if self.fieldCourseUpdateTimer <= 0 then
			self:updateFieldCourse()
		end
	end
end
function OrchardBrushDialog:updateOptionStates()
	self.workDirectionOption:setState(self:getWorkDirectionIndex(self.fieldCourseSettings.workDirection))
end
function OrchardBrushDialog:createCourseField()
	local courseField = FieldCourseField.new(self.fieldCourseSettings)
	local boundaryPositions = {}
	for _, point in ipairs(self.boundaryLine) do
		local x, z = g_fieldCourseManager:roundToTerrainDetailPixel(point[1], point[2])
		table.insert(boundaryPositions, { x, z })
	end
	FieldCourseUtil.removeShortSegments(boundaryPositions, OrchardBrushDialog.MIN_SEGMENT_LENGTH)
	if #boundaryPositions < OrchardBrushDialog.MIN_BOUNDARY_POSITIONS then
		return nil
	end
	if FieldCourseBoundary.getIsBoundaryLineInverted(boundaryPositions) then
		local inverted = {}
		for i = #boundaryPositions, 1, -1 do
			table.insert(inverted, boundaryPositions[i])
		end
		boundaryPositions = inverted
	end
	courseField.boundaryPositions = boundaryPositions
	courseField.fieldRootBoundary = FieldCourseBoundary.createByBoundaryLine(boundaryPositions, courseField.segmentSplitAngle)
	courseField.islands = {}
	courseField.headlandBoundaries = {}
	courseField.state = FieldCourseDetectionState.FINISHED
	if courseField.fieldRootBoundary == nil then
		return nil
	else
		return courseField
	end
end
function OrchardBrushDialog:updateFieldCourse()
	if self.boundaryLine == nil or self.fieldCourseLoading then
		return
	end
	local courseField = self:createCourseField()
	if courseField == nil then
		self.fieldCourse = nil
		self:updateMapState()
	else
		self.fieldCourseLoading = true
		local generator = FieldCourseSegmentGenerator.new(self.fieldCourseSettings, function(segments, generatedField, isVineyardCourse)
			self.fieldCourseLoading = false
			if self.boundaryLine == nil then
				return
			else
				self.hasExistingRows = isVineyardCourse
				local numSegments = segments ~= nil and #segments or 0
				if 0 < numSegments then
					if not self.hasExistingRows then
						local fieldCourse = FieldCourse.new(self.fieldCourseSettings, generatedField, isVineyardCourse)
						fieldCourse:addSegments(segments)
						fieldCourse.isUICourse = true
						self.fieldCourse = fieldCourse
						self:captureDefaultWorkDirection()
					else
						self.fieldCourse = nil
					end
				end
				self:updateMapState()
			end
		end)
		generator:setIsUICourse()
		generator:setFieldData(courseField)
		generator:setHeadlandSettings(false, true)
		generator:generate()
		self:updateMapState()
	end
end
function OrchardBrushDialog:updateMapState()
	local minX, maxX, minZ, maxZ = self:getBoundaryBoundingBox()
	self.ingameMapElement:fitToBoundary(minX, maxX, minZ, maxZ, OrchardBrushDialog.MAP_BOUNDARY_PADDING)
	self.ingameMapElement:setMapAlpha(1)
	local hasCourse = self.fieldCourse ~= nil
	local showNoFieldFound = not self.fieldCourseLoading and not hasCourse and not self.hasExistingRows
	self.loadingAnimation:setVisible(self.fieldCourseLoading)
	self.noFieldFoundText:setVisible(showNoFieldFound)
	self:updateWorkDirectionArrow(hasCourse)
	self.rowCountText:setText(string.format("%d", self:getPlantingRowCount()))
	self:updateBuildStatus()
end
function OrchardBrushDialog:updateWorkDirectionArrow(hasCourse)
	local workDirection = self.fieldCourseSettings.workDirection
	local isVisible = hasCourse and workDirection ~= OrchardBrushDialog.WORK_DIRECTION_AUTOMATIC
	self.workDirectionArrow:setVisible(isVisible)
	if isVisible then
		self.workDirectionArrow:setImageRotation(3.141592653589793 + workDirection)
	end
end
function OrchardBrushDialog:getBoundaryAreaHa()
	if self.boundaryLine == nil or #self.boundaryLine < 3 then
		return 0
	end
	local polygon = Polygon2D.new()
	for _, point in ipairs(self.boundaryLine) do
		polygon:addPos(point[1], point[2])
	end
	return polygon:getArea() / 10000
end
function OrchardBrushDialog:getPlantingRowCount()
	if self.fieldCourse == nil then
		return 0
	else
		local count = 0
		for _, segment in ipairs(self.fieldCourse.segments) do
			if segment.isHeadlandSegment or segment.isIslandSegment then
				continue
			end
			count = count + 1
		end
		return count
	end
end
function OrchardBrushDialog:getTotalBuildableLength()
	if self.fieldCourse == nil then
		return 0
	else
		local panelLength = self.panelLength
		if panelLength == nil or panelLength <= 0 then
			return self.fieldCourse.totalLength
		end
		local total = 0
		for _, segment in ipairs(self.fieldCourse.segments) do
			local numPanels = math.floor(segment.length / panelLength)
			total = total + numPanels * panelLength
		end
		return total
	end
end
function OrchardBrushDialog:getCustomOptionsPrice()
	if self.fieldCourse == nil or self.optionsProvider == nil or self.optionsProvider.getOrchardBrushExtraPrice == nil then
		return 0
	end
	return self.optionsProvider:getOrchardBrushExtraPrice(self.fieldCourse.segments, self.optionStates)
end
function OrchardBrushDialog:getBuildLimitWarning()
	if self.fieldCourse == nil or self.optionsProvider == nil or self.optionsProvider.getOrchardBuildLimitWarning == nil then
		return nil
	end
	local numRows = self:getPlantingRowCount()
	local totalLength = self:getTotalBuildableLength()
	return self.optionsProvider:getOrchardBuildLimitWarning(numRows, totalLength, self.panelLength)
end
function OrchardBrushDialog:updateBuildStatus()
	local hasCourse = self.fieldCourse ~= nil
	local totalPrice = self:getTotalBuildableLength() * (self.pricePerMeter or 0)
	totalPrice = totalPrice + self:getCustomOptionsPrice()
	self.priceText:setText(g_i18n:formatMoney(totalPrice, 0, true, false))
	local canAfford = totalPrice <= g_currentMission:getMoney(g_localPlayer.farmId)
	local priceColor = OrchardBrushDialog.COLOR_AFFORDABLE
	if not canAfford then
		priceColor = OrchardBrushDialog.COLOR_NOT_AFFORDABLE
	end
	self.priceText:setTextColor(unpack(priceColor))
	local limitWarning = self:getBuildLimitWarning()
	local warning = nil
	if hasCourse then
		if not canAfford then
			warning = g_i18n:getText("ui_construction_notEnoughMoney")
		elseif limitWarning ~= nil then
			warning = limitWarning
		elseif self.hasExistingRows then
			warning = g_i18n:getText("ui_construction_spaceAlreadyOccupied")
		end
	end
	self.warningText:setText(warning or "")
	self.warningText:setVisible(warning ~= nil)
	local canBuild = hasCourse and canAfford and limitWarning == nil
	self.buildButton:setDisabled(not canBuild)
end
function OrchardBrushDialog:getBoundaryBoundingBox()
	local minX = math.huge
	local maxX = -math.huge
	local minZ = math.huge
	local maxZ = -math.huge
	for _, point in ipairs(self.boundaryLine) do
		minX = math.min(minX, point[1])
		maxX = math.max(maxX, point[1])
		minZ = math.min(minZ, point[2])
		maxZ = math.max(maxZ, point[2])
	end
	return minX, maxX, minZ, maxZ
end
function OrchardBrushDialog:drawLineOnMap(ingameMap, posX, posY, sizeX, sizeZ, positions, color)
	for i = 1, #positions - 1 do
		local pos1 = positions[i]
		local pos2 = positions[i + 1]
		local x1 = ((pos1[1] / ingameMap.worldSizeX + 0.5) * ingameMap.mapExtensionScaleFactor + ingameMap.mapExtensionOffsetX) * sizeX + posX
		local y1 = (1 - ((pos1[2] / ingameMap.worldSizeZ + 0.5) * ingameMap.mapExtensionScaleFactor + ingameMap.mapExtensionOffsetX)) * sizeZ + posY
		local x2 = ((pos2[1] / ingameMap.worldSizeX + 0.5) * ingameMap.mapExtensionScaleFactor + ingameMap.mapExtensionOffsetX) * sizeX + posX
		local y2 = (1 - ((pos2[2] / ingameMap.worldSizeZ + 0.5) * ingameMap.mapExtensionScaleFactor + ingameMap.mapExtensionOffsetX)) * sizeZ + posY
		drawLine2D(x1, y1, x2, y2, self.lineWidth, color[1], color[2], color[3], color[4])
	end
end
function OrchardBrushDialog:onDrawPostIngameMapHotspots(element, ingameMap)
	local posX, posY = self.ingameMapElement:getMapPosition()
	local sizeX, sizeZ = self.ingameMapElement:getMapSize()
	if self.boundaryLine ~= nil then
		self:drawLineOnMap(ingameMap, posX, posY, sizeX, sizeZ, self.boundaryLine, OrchardBrushDialog.LINE_COLORS.BOUNDARY)
	end
	if self.fieldCourse ~= nil then
		for _, segment in ipairs(self.fieldCourse.segments) do
			local color = OrchardBrushDialog.LINE_COLORS.STRAIGHT
			if segment.isHeadlandSegment or segment.isIslandSegment then
				color = OrchardBrushDialog.LINE_COLORS.HEADLAND
			end
			self:drawLineOnMap(ingameMap, posX, posY, sizeX, sizeZ, segment.positions, color)
		end
		self:drawCustomOptionPreviewLines(ingameMap, posX, posY, sizeX, sizeZ)
	end
end
function OrchardBrushDialog:drawCustomOptionPreviewLines(ingameMap, posX, posY, sizeX, sizeZ)
	if self.optionsProvider == nil or self.optionsProvider.getOrchardBrushPreviewLines == nil then
		return
	end
	local lines = self.optionsProvider:getOrchardBrushPreviewLines(self.fieldCourse.segments, self.optionStates)
	if lines == nil then
		return
	else
		for _, line in ipairs(lines) do
			self:drawLineOnMap(ingameMap, posX, posY, sizeX, sizeZ, line.positions, line.color)
		end
	end
end
function OrchardBrushDialog:onClickWorkDirection(state)
	local value = self.workDirectionValues[state]
	if value == nil then
		return
	else
		self:setWorkDirectionValue(value)
	end
end
function OrchardBrushDialog:onClickResetDirection()
	if self.defaultWorkDirection == nil then
		return
	else
		self:setWorkDirectionValue(self.defaultWorkDirection)
		self:updateOptionStates()
	end
end
function OrchardBrushDialog:captureDefaultWorkDirection()
	if self.defaultWorkDirection ~= nil then
		return
	end
	local resolvedAngle = self:getResolvedAutomaticWorkDirection()
	if resolvedAngle == nil then
		return
	else
		local degrees = math.clamp(MathUtil.round(math.deg(resolvedAngle)), 0, OrchardBrushDialog.WORK_DIRECTION_MAX_DEG)
		self.defaultWorkDirection = math.rad(degrees)
		self:setWorkDirectionValue(self.defaultWorkDirection)
		self:updateOptionStates()
	end
end
function OrchardBrushDialog:getResolvedAutomaticWorkDirection()
	if self.fieldCourse == nil then
		return nil
	else
		for _, segment in ipairs(self.fieldCourse.segments) do
			local isPlantingRow = not segment.isHeadlandSegment and not segment.isIslandSegment
			if isPlantingRow and 2 <= #segment.positions then
				local startPos = segment.positions[1]
				local endPos = segment.positions[2]
				local dirX, dirZ = MathUtil.vector2Normalize(endPos[1] - startPos[1], endPos[2] - startPos[2])
				local angle = MathUtil.getYRotationFromDirection(dirX, dirZ) % 3.141592653589793
				return angle
			end
		end
		return nil
	end
end
function OrchardBrushDialog.flipWorkDirectionSense(degrees)
	local rangeDeg = OrchardBrushDialog.WORK_DIRECTION_MAX_DEG + OrchardBrushDialog.WORK_DIRECTION_STEP_DEG
	return (rangeDeg - degrees) % rangeDeg
end
function OrchardBrushDialog:getWorkDirectionIndex(radians)
	local degrees = math.clamp(MathUtil.round(math.deg(radians)), 0, OrchardBrushDialog.WORK_DIRECTION_MAX_DEG)
	return OrchardBrushDialog.flipWorkDirectionSense(degrees) + 1
end
function OrchardBrushDialog:setWorkDirectionValue(value)
	self.fieldCourseSettings.workDirection = value
	self.fieldCourseUpdateTimer = OrchardBrushDialog.FIELD_COURSE_UPDATE_DELAY
	self:updateMapState()
end
function OrchardBrushDialog:onClickBuild()
	if self.fieldCourse == nil then
		return
	end
	if self.buildButton:getIsDisabled() then
		return
	end
	local segments = self.fieldCourse.segments
	local settings = self.fieldCourseSettings
	local optionStates = self.optionStates
	local callbackFunc = self.callbackFunc
	local target = self.target
	self:close()
	if callbackFunc ~= nil then
		if target ~= nil then
			callbackFunc(target, true, settings, segments, optionStates)
			return
		end
		callbackFunc(true, settings, segments, optionStates)
	end
end
function OrchardBrushDialog:onClickCustomOption(state, element)
	local index = self.elementToOptionIndex[element]
	if index == nil then
		return
	else
		self.optionStates[index] = state
		self:updateBuildStatus()
	end
end
function OrchardBrushDialog:onClickCancel()
	local callbackFunc = self.callbackFunc
	local target = self.target
	self:close()
	if callbackFunc ~= nil then
		if target ~= nil then
			callbackFunc(target, false, nil, nil)
			return
		end
		callbackFunc(false, nil, nil)
	end
end
function OrchardBrushDialog:onClickBack()
	self:onClickCancel()
	return true
end
