local data = nil
if FillLevelsDisplay ~= nil then
	local old = g_currentMission.hud.fillLevelsDisplay
	data = {}
	data.vehicle = old.vehicle
	data.uiScale = old.uiScale
	data.isVisible = old:getVisible()
	old:delete()
end
FillLevelsDisplay = {}
FillLevelsDisplay.TYPE_BAR = 1
FillLevelsDisplay.TYPE_STEP = 2
FillLevelsDisplay.MAX_BOXES = 5
FillLevelsDisplay.MAX_NUM_STEPS = 25
local FillLevelsDisplay_mt = Class(FillLevelsDisplay, HUDDisplay)
function FillLevelsDisplay.new()
	local self = FillLevelsDisplay:superClass().new(FillLevelsDisplay_mt)
	local r, g, b, a = unpack(HUD.COLOR.BACKGROUND)
	self.bgScale = g_overlayManager:createOverlay("gui.filltypes_middle", 0, 0, 0, 0)
	self.bgScale:setColor(r, g, b, a)
	self.bgLeft = g_overlayManager:createOverlay("gui.filltypes_left", 0, 0, 0, 0)
	self.bgLeft:setColor(r, g, b, a)
	self.bgRight = g_overlayManager:createOverlay("gui.filltypes_right", 0, 0, 0, 0)
	self.bgRight:setColor(r, g, b, a)
	self.maxWeightIcon = g_overlayManager:createOverlay("gui.vehicleOverview_maxWeight", 0, 0, 0, 0)
	self.bar = ThreePartOverlay.new()
	self.bar:setLeftPart("gui.progressbar_left", 0, 0)
	self.bar:setMiddlePart("gui.progressbar_middle", 0, 0)
	self.bar:setRightPart("gui.progressbar_right", 0, 0)
	self.vehicle = nil
	self.fillTypeIcons = {}
	self.fillLevelData = {}
	return self
end
function FillLevelsDisplay:delete()
	self.bgLeft:delete()
	self.bgRight:delete()
	self.bgScale:delete()
	self.maxWeightIcon:delete()
	self.bar:delete()
	for _, icon in pairs(self.fillTypeIcons) do
		icon:delete()
	end
end
function FillLevelsDisplay:storeScaledValues()
	self.offsetX, self.offsetY = self:scalePixelValuesToScreenVector(0, 236)
	local posX = g_hudAnchorRight
	local posY = g_hudAnchorBottom
	self:setPosition(posX, posY)
	local bgLeftWidth, bgHeight = self:scalePixelValuesToScreenVector(12, 45)
	local bgRightWidth = self:scalePixelToScreenWidth(12)
	local bgScaleWidth = self:scalePixelToScreenWidth(290) - bgLeftWidth - bgRightWidth
	self.bgTotalWidth = bgScaleWidth + bgLeftWidth + bgRightWidth
	self.bgLeft:setDimension(bgLeftWidth, bgHeight)
	self.bgRight:setDimension(bgRightWidth, bgHeight)
	self.bgScale:setDimension(bgScaleWidth, bgHeight)
	self.bgRight:setPosition(posX - self.bgRight.width, nil)
	self.bgScale:setPosition(self.bgRight.x - self.bgScale.width, nil)
	self.bgLeft:setPosition(self.bgScale.x - self.bgLeft.width, nil)
	self.boxOffsetY = self:scalePixelToScreenHeight(5)
	self.fillTypeTextSize = self:scalePixelToScreenHeight(14)
	self.fillLevelTextSize = self:scalePixelToScreenHeight(14)
	self.fillTypeTextOffsetX, self.fillTypeTextOffsetY = self:scalePixelValuesToScreenVector(40, 22)
	self.fillLevelTextOffsetX, self.fillLevelTextOffsetY = self:scalePixelValuesToScreenVector(-12, 22)
	self.typeLevelOffsetX = self:scalePixelToScreenWidth(5)
	local barPartWidth, barPartHeight = self:scalePixelValuesToScreenVector(3, 6)
	local barTotalWidth, _ = self:scalePixelValuesToScreenVector(237, 0)
	self.barTotalWidth = barTotalWidth
	self.barHeight = barPartHeight
	self.barMinWidth = 2 * barPartWidth
	self.barMaxScaleWidth = barTotalWidth - 2 * barPartWidth
	self.bar:setLeftPart(nil, barPartWidth, barPartHeight)
	self.bar:setMiddlePart(nil, self.barMaxScaleWidth, barPartHeight)
	self.bar:setRightPart(nil, barPartWidth, barPartHeight)
	self.barOffsetX, self.barOffsetY = self:scalePixelValuesToScreenVector(40, 9)
	self.barStepOffsetX = self:scalePixelToScreenWidth(3)
	self.iconOffsetX, self.iconOffsetY = self:scalePixelValuesToScreenVector(7, 9)
	self.iconWidth, self.iconHeight = self:scalePixelValuesToScreenVector(27, 27)
	local weightIconWidth, weightIconHeight = self:scalePixelValuesToScreenVector(50, 17)
	self.maxWeightIcon:setDimension(weightIconWidth, weightIconHeight)
	for _, icon in pairs(self.fillTypeIcons) do
		icon:setDimension(self.iconWidth, self.iconHeight)
	end
	self.helpAnchorPosX = self.bgLeft.x + self:scalePixelToScreenWidth(-15)
	self.helpAnchorPosY = posY + self.bgScale.height * 0.5
end
function FillLevelsDisplay:update(dt)
	FillLevelsDisplay:superClass().update(self, dt)
	if self.vehicle ~= nil then
		self:updateFillLevelData()
	end
end
function FillLevelsDisplay:draw()
	FillLevelsDisplay:superClass().draw(self)
	local posX, posY = self:getPosition()
	if g_currentMission.hud.speedMeter:getVisible() then
		posX = posX + self.offsetX
		posY = posY + self.offsetY
	end
	for _, data in ipairs(self.fillLevelData) do
		if data.isValid then
			local height = self:drawFillLevel(posX, posY, data)
			posY = posY + height + self.boxOffsetY
			data.isValid = false
		end
	end
end
function FillLevelsDisplay:drawFillLevel(posX, posY, data)
	local barBgColor = HUD.COLOR.BACKGROUND_DARK
	local activeColor = HUD.COLOR.ACTIVE
	self.bgRight:setPosition(nil, posY)
	self.bgLeft:setPosition(nil, posY)
	self.bgScale:setPosition(nil, posY)
	self.bgRight:render()
	self.bgLeft:render()
	self.bgScale:render()
	local icon = self.fillTypeIcons[data.fillType]
	if icon ~= nil then
		icon:setPosition(self.bgLeft.x + self.iconOffsetX, self.bgLeft.y + self.iconOffsetY)
		icon:render()
	end
	if data.typeId == FillLevelsDisplay.TYPE_BAR then
		self.bar:setColor(barBgColor[1], barBgColor[2], barBgColor[3], barBgColor[4])
		self.bar:setMiddlePart(nil, self.barMaxScaleWidth, nil)
		self.bar:setPosition(self.bgLeft.x + self.barOffsetX, self.bgLeft.y + self.barOffsetY)
		self.bar:render()
		local scale = 0
		if 0 < data.capacity then
			scale = data.fillLevel / data.capacity
		end
		if 0 < scale then
			self.bar:setColor(activeColor[1], activeColor[2], activeColor[3], activeColor[4])
			self.bar:setMiddlePart(nil, self.barMaxScaleWidth * scale, nil)
			self.bar:setPosition(self.bar.x, self.bar.y)
			self.bar:render()
		end
		setTextColor(1, 1, 1, 1)
		setTextBold(false)
		setTextAlignment(RenderText.ALIGN_RIGHT)
		renderText(posX + self.fillLevelTextOffsetX, self.bgLeft.y + self.fillLevelTextOffsetY, self.fillLevelTextSize, data.fillLevelText)
		local fillTypeText = data.customFillTypeText
		if fillTypeText == nil and data.fillType ~= FillType.UNKNOWN then
			fillTypeText = g_fillTypeManager:getFillTypeTitleByIndex(data.fillType)
		end
		if fillTypeText ~= nil then
			if data.infoText ~= nil then
				fillTypeText = fillTypeText .. " (" .. data.infoText .. ")"
			end
			local textLength = getTextWidth(self.fillLevelTextSize, data.fillLevelText)
			local maxWidth = self.bgTotalWidth - textLength - self.fillTypeTextOffsetX - math.abs(self.fillLevelTextOffsetX) - self.typeLevelOffsetX
			local text = Utils.limitTextToWidth(fillTypeText, self.fillTypeTextSize, maxWidth, false, "...")
			setTextBold(true)
			setTextAlignment(RenderText.ALIGN_LEFT)
			renderText(self.bgLeft.x + self.fillTypeTextOffsetX, self.bgLeft.y + self.fillTypeTextOffsetY, self.fillTypeTextSize, text)
			setTextBold(false)
		end
	elseif data.typeId == FillLevelsDisplay.TYPE_STEP then
		local numSteps, _ = math.modf(data.capacity)
		local numFilledSteps, fractialStep = math.modf(data.fillLevel)
		numFilledSteps = numFilledSteps + 1
		numSteps = math.clamp(numSteps, 1, FillLevelsDisplay.MAX_NUM_STEPS)
		local numOffsets = numSteps - 1
		local barWidth = self.barTotalWidth - self.barStepOffsetX * numOffsets - self.barMinWidth * numSteps
		local barScaleWidth = barWidth / numSteps
		self.bar:setMiddlePart(nil, barScaleWidth, nil)
		local barPosX = self.bgLeft.x + self.barOffsetX
		local barPosY = self.bgLeft.y + self.barOffsetY
		for i = 1, numSteps do
			self.bar:setColor(barBgColor[1], barBgColor[2], barBgColor[3], barBgColor[4])
			self.bar:setPosition(barPosX, barPosY)
			self.bar:setMiddlePart(nil, barScaleWidth, nil)
			self.bar:render()
			local scale = 0
			if i == numFilledSteps then
				scale = fractialStep
			elseif i < numFilledSteps then
				scale = 1
			end
			if 0 < scale then
				self.bar:setColor(activeColor[1], activeColor[2], activeColor[3], activeColor[4])
				self.bar:setMiddlePart(nil, barScaleWidth * scale, nil)
				self.bar:render()
			end
			barPosX = barPosX + self.barMinWidth + barScaleWidth + self.barStepOffsetX
		end
		setTextBold(false)
		setTextAlignment(RenderText.ALIGN_RIGHT)
		renderText(posX + self.fillLevelTextOffsetX, self.bgLeft.y + self.fillLevelTextOffsetY, self.fillLevelTextSize, data.fillLevelText)
		local fillTypeText = data.customFillTypeText
		if fillTypeText == nil and data.fillType ~= FillType.UNKNOWN then
			fillTypeText = g_fillTypeManager:getFillTypeTitleByIndex(data.fillType)
		end
		if fillTypeText ~= nil then
			local textLength = getTextWidth(self.fillLevelTextSize, data.fillLevelText)
			local maxWidth = self.bgTotalWidth - textLength - self.fillTypeTextOffsetX - math.abs(self.fillLevelTextOffsetX) - self.typeLevelOffsetX
			local text = Utils.limitTextToWidth(fillTypeText, self.fillTypeTextSize, maxWidth, false, "...")
			setTextBold(true)
			setTextAlignment(RenderText.ALIGN_LEFT)
			renderText(self.bgLeft.x + self.fillTypeTextOffsetX, self.bgLeft.y + self.fillTypeTextOffsetY, self.fillTypeTextSize, text)
			setTextBold(false)
		end
	end
	if data.maxReached then
		local weightIconPosX = self.bgLeft.x + self.barOffsetX + self.barTotalWidth * 0.5 - self.maxWeightIcon.width * 0.5
		local weightIconPosY = self.bgLeft.y + self.barOffsetY + self.barHeight * 0.5 - self.maxWeightIcon.height * 0.5
		self.maxWeightIcon:setPosition(weightIconPosX, weightIconPosY)
		self.maxWeightIcon:render()
	end
	setTextBold(false)
	setTextAlignment(RenderText.ALIGN_LEFT)
	return self.bgScale.height
end
function FillLevelsDisplay:setVehicle(vehicle)
	self.vehicle = vehicle
end
function FillLevelsDisplay:resetFillTypes()
	for _, v in pairs(self.fillTypeIcons) do
		v:delete()
	end
	table.clear(self.fillTypeIcons)
end
function FillLevelsDisplay:updateFillLevelData()
	self.vehicle:getFillLevelInformation(self)
	for k, data in ipairs(self.fillLevelData) do
		if data.isValid and (0 < data.capacity or 0 < data.fillLevel) then
			if data.typeId == FillLevelsDisplay.TYPE_BAR then
				local value = 0
				if 0 < data.capacity then
					value = data.fillLevel / data.capacity
				end
				local precision = data.precision or 0
				local formattedNumber = nil
				if 0 < precision then
					local rounded = MathUtil.round(data.fillLevel, precision)
					formattedNumber = string.format("%d%s%0" .. precision .. "d", math.floor(rounded), g_i18n.decimalSeparator, (rounded - math.floor(rounded)) * 10 ^ precision)
				else
					formattedNumber = string.format("%d", MathUtil.round(data.fillLevel))
				end
				local fillTypeDesc = g_fillTypeManager:getFillTypeByIndex(data.fillType)
				data.fillLevelText = string.format("%s%s (%d%%)", formattedNumber, fillTypeDesc.unitShort or "", math.floor(100 * value))
			elseif data.typeId == FillLevelsDisplay.TYPE_STEP then
				data.fillLevelText = string.format("%d / %d", math.ceil(data.fillLevel), data.capacity)
			end
		end
	end
end
function FillLevelsDisplay:addFillLevel(fillType, fillLevel, capacity, precision, maxReached, typeId, customFillTypeText, infoText)
	typeId = typeId or FillLevelsDisplay.TYPE_BAR
	local dataItem = nil
	for k, data in ipairs(self.fillLevelData) do
		if not data.isValid then
			dataItem = data
			dataItem.capacity = 0
			dataItem.fillLevel = 0
			break
		end
		if data.fillType == fillType and (data.typeId == typeId and data.infoText == infoText) then
			dataItem = data
			break
		end
	end
	if dataItem == nil and #self.fillLevelData < FillLevelsDisplay.MAX_BOXES then
		dataItem = { fillLevel = 0, capacity = 0 }
		table.insert(self.fillLevelData, dataItem)
	end
	if dataItem ~= nil then
		dataItem.isValid = true
		dataItem.customFillTypeText = customFillTypeText
		dataItem.infoText = infoText
		dataItem.typeId = typeId
		dataItem.fillType = fillType
		dataItem.fillLevel = dataItem.fillLevel + fillLevel
		dataItem.capacity = dataItem.capacity + capacity
		dataItem.precision = precision
		dataItem.maxReached = maxReached
		if self.fillTypeIcons[fillType] == nil then
			local fillTypeDesc = g_fillTypeManager:getFillTypeByIndex(fillType)
			local iconOverlay = Overlay.new(fillTypeDesc.hudOverlayFilename, 0, 0, self.iconWidth, self.iconHeight)
			self.fillTypeIcons[fillType] = iconOverlay
		end
	end
end
function FillLevelsDisplay:getHelpAnchorPosition()
	local posX = self.helpAnchorPosX
	local posY = self.helpAnchorPosY
	if g_currentMission.hud.speedMeter:getVisible() then
		posX = posX + self.offsetX
		posY = posY + self.offsetY
	end
	return posX, posY
end
if data ~= nil then
	local fillLevelsDisplay = FillLevelsDisplay.new()
	fillLevelsDisplay:setScale(data.uiScale)
	fillLevelsDisplay:setVisible(data.isVisible)
	fillLevelsDisplay:setVehicle(data.vehicle)
	g_currentMission.hud.fillLevelsDisplay = fillLevelsDisplay
	g_currentMission.hud.displayComponents.fillLevelsDisplay = fillLevelsDisplay
	Logging.info("Reloaded FillLevelsDisplay")
end
