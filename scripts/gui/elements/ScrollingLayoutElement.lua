ScrollingLayoutElement = {}
local ScrollingLayoutElement_mt = Class(ScrollingLayoutElement, BoxLayoutElement)
Gui.registerGuiElement("ScrollingLayout", ScrollingLayoutElement)
function ScrollingLayoutElement.new(target, custom_mt)
	local self = BoxLayoutElement.new(target, custom_mt or ScrollingLayoutElement_mt)
	self.clipping = true
	self.wrapAround = true
	self.scrollDirection = self.flowDirection
	self.sliderElement = nil
	self.contentOffsetX = 0
	self.contentOffsetY = 0
	self.targetContentOffsetX = 0
	self.targetContentOffsetY = 0
	self.contentSize = 1
	self.lastTouchPos = nil
	self.usedTouchId = nil
	self.currentTouchDelta = 0
	self.scrollSpeed = 0
	self.initialScrollSpeed = 0
	self.supportsTouchScrolling = Platform.hasTouchInput
	self.totalTouchMoveDistance = 0
	self.touchMoveDistanceThreshold = 30
	return self
end
function ScrollingLayoutElement:loadFromXML(xmlFile, key)
	ScrollingLayoutElement:superClass().loadFromXML(self, xmlFile, key)
	self.topClipperElementName = getXMLString(xmlFile, key .. "#topClipperElementName")
	self.bottomClipperElementName = getXMLString(xmlFile, key .. "#bottomClipperElementName")
	self.supportsTouchScrolling = Utils.getNoNil(getXMLBool(xmlFile, key .. "#supportsTouchScrolling"), self.supportsTouchScrolling)
end
function ScrollingLayoutElement:loadProfile(profile, applyProfile)
	ScrollingLayoutElement:superClass().loadProfile(self, profile, applyProfile)
	self.supportsTouchScrolling = profile:getBool("supportsTouchScrolling", self.supportsTouchScrolling)
end
function ScrollingLayoutElement:copyAttributes(src)
	ScrollingLayoutElement:superClass().copyAttributes(self, src)
	self.topClipperElementName = src.topClipperElementName
	self.bottomClipperElementName = src.bottomClipperElementName
	self.supportsTouchScrolling = src.supportsTouchScrolling
end
function ScrollingLayoutElement:onGuiSetupFinished()
	ScrollingLayoutElement:superClass().onGuiSetupFinished(self)
	if self.topClipperElementName ~= nil then
		self.topClipperElement = self.parent:getDescendantByName(self.topClipperElementName)
	end
	if self.bottomClipperElementName ~= nil then
		self.bottomClipperElement = self.parent:getDescendantByName(self.bottomClipperElementName)
	end
	for _, e in pairs(self.elements) do
		self:addFocusListener(e)
	end
	if self.flowDirection == "vertical" then
		if self.numFlows == 1 or self.flowDirection == "horizontal" and self.numFlows ~= 1 then
			self.scrollDirection = "vertical"
		else
			self.scrollDirection = "horizontal"
		end
	end
	if self.scrollDirection == "horizontal" then
		self.scrollSpeedInterval = GuiElement.SCROLL_SPEED_PIXEL_PER_MS * g_pixelSizeX
	else
		self.scrollSpeedInterval = GuiElement.SCROLL_SPEED_PIXEL_PER_MS * g_pixelSizeY
	end
end
function ScrollingLayoutElement:updateLayoutCells(ignoreVisibility)
	ScrollingLayoutElement:superClass().updateLayoutCells(self, ignoreVisibility, true)
	for _, e in pairs(self.elements) do
		self:addFocusListener(e)
	end
end
function ScrollingLayoutElement:invalidateLayout(ignoreVisibility, blockLayoutUpdate)
	local needsUpdate = not blockLayoutUpdate
	if needsUpdate then
		self:updateLayoutCells(ignoreVisibility)
	end
	self:applyCellPositions(self.contentOffsetX, self.contentOffsetY)
	if self.handleFocus and (self.focusDirection ~= BoxLayoutElement.FLOW_NONE and needsUpdate) then
		self:focusLinkCells(self.cells)
	end
	if needsUpdate then
		self:updateContentSize()
	end
	self:updateScrollClippers()
	return self.maxFlowSize
end
function ScrollingLayoutElement:updateScrollClippers(initial)
	if self.scrollDirection == "vertical" then
		if self.topClipperElement ~= nil then
			local visible = 0.01 < self.contentOffsetY
			self.topClipperElement:setVisible(visible)
		end
		if self.bottomClipperElement ~= nil then
			local visible = self.contentOffsetY - (self.contentSize - self.absSize[2]) < -0.01
			self.bottomClipperElement:setVisible(visible)
		end
	else
		if self.topClipperElement ~= nil then
			local visible = 0.01 < self.contentOffsetX
			self.topClipperElement:setVisible(visible)
		end
		if self.bottomClipperElement ~= nil then
			local visible = self.contentOffsetX - (self.contentSize - self.absSize[1]) < -0.01
			self.bottomClipperElement:setVisible(visible)
		end
	end
end
function ScrollingLayoutElement:onSliderValueChanged(slider, newValue)
	if self.scrollDirection == "vertical" then
		local newStartY = 0
		if slider.minValue ~= slider.maxValue then
			newStartY = (self.contentSize - self.absSize[2]) / (slider.maxValue - slider.minValue) * (newValue - slider.minValue)
		end
		self:scrollTo(newStartY, false)
	else
		local newStartX = 0
		if slider.minValue ~= slider.maxValue then
			newStartX = (self.contentSize - self.absSize[1]) / (slider.maxValue - slider.minValue) * (-newValue + slider.minValue)
		end
		self:scrollTo(newStartX, false)
	end
end
function ScrollingLayoutElement:scrollTo(startPos, updateSlider, noUpdateTarget)
	if self.scrollDirection == "vertical" then
		self.contentOffsetY = startPos
		if not noUpdateTarget then
			self.targetContentOffsetY = startPos
			self.isMovingToTarget = false
		end
		self:invalidateLayout(false, true)
		if (updateSlider == nil or updateSlider) and self.sliderElement ~= nil then
			local newValue = startPos / ((self.contentSize - self.absSize[2]) / self.sliderElement.maxValue)
			self.sliderElement:setValue(newValue, true)
		end
	else
		self.contentOffsetX = startPos
		if not noUpdateTarget then
			self.targetContentOffsetX = startPos
			self.isMovingToTarget = false
		end
		self:invalidateLayout(false, true)
		if (updateSlider == nil or updateSlider) and self.sliderElement ~= nil then
			local endPos = (-self.contentSize + self.absSize[1]) / self.sliderElement.maxValue
			local newValue = startPos / (endPos ~= 0 and endPos or 1)
			self.sliderElement:setValue(newValue, true)
		end
	end
	self:raiseCallback("onScrollCallback")
end
function ScrollingLayoutElement:scrollToEnd()
	if self.scrollDirection == "vertical" then
		self:scrollTo(math.max(self.contentSize - self.absSize[2], 0), true)
	else
		self:scrollTo(-math.max(self.contentSize - self.absSize[1], 0), true)
	end
end
function ScrollingLayoutElement:smoothScrollTo(offset)
	if self.scrollDirection == "vertical" then
		offset = math.max(math.min(offset, self.contentSize - self.absSize[2]), 0)
		self.targetContentOffsetY = offset
		self.isMovingToTarget = true
	else
		offset = math.min(math.min(offset, self.contentSize - self.absSize[1]), 0)
		self.targetContentOffsetX = offset
		self.isMovingToTarget = true
	end
end
function ScrollingLayoutElement:updateContentSize()
	if self.numFlows == 1 then
		self.contentSize = self.maxFlowSize
	elseif self.numFlows == 0 then
		self.contentSize = self.totalLateralSize
	else
		self.contentSize = self.numFlows * self.lateralFlowSize
	end
	if self.scrollDirection == "vertical" then
		self.contentOffsetY = math.max(math.min(self.contentOffsetY, self.contentSize), 0)
		self.targetContentOffsetY = math.max(math.min(self.targetContentOffsetY, self.contentSize), 0)
	else
		self.contentOffsetX = math.min(math.min(self.contentOffsetX, self.contentSize), 0)
		self.targetContentOffsetX = math.min(math.min(self.targetContentOffsetX, self.contentSize), 0)
	end
	self:raiseSliderUpdateEvent()
end
function ScrollingLayoutElement:getNeedsScrolling()
	if self.scrollDirection == "vertical" then
		return self.absSize[2] < self.contentSize
	else
		return self.absSize[1] < self.contentSize
	end
end
function ScrollingLayoutElement:raiseSliderUpdateEvent()
	if self.sliderElement ~= nil then
		self.sliderElement:onBindUpdate(self)
	end
end
function ScrollingLayoutElement:getViewOffsetPercentage()
	local size = nil
	if self.scrollDirection == "vertical" then
		size = self.contentSize - self.absSize[2]
		if size ~= 0 then
			return self.contentOffsetY / size
		end
	else
		size = self.contentSize - self.absSize[1]
		if size ~= 0 then
			return self.contentOffsetX / size
		end
	end
	return 1
end
function ScrollingLayoutElement:addFocusListener(element)
	element = element:findFirstFocusable(true)
	if element.scrollingFocusEnter_orig == nil then
		element.scrollingFocusEnter_orig = element.onFocusEnter
	end
	function element.onFocusEnter(e)
		e.scrollingFocusEnter_orig(e)
		self:scrollToMakeElementVisible(e)
	end
end
function ScrollingLayoutElement:removeElement(element)
	ScrollingLayoutElement:superClass().removeElement(self, element)
	if element.scrollingFocusEnter_orig == nil then
		element.onFocusEnter = element.scrollingFocusEnter_orig
	end
end
function ScrollingLayoutElement:mouseEvent(posX, posY, isDown, isUp, button, eventUsed)
	if self:getIsActive() then
		local hasOverlap = GuiUtils.checkOverlayOverlap(posX, posY, self.absPosition[1], self.absPosition[2], self.absSize[1], self.absSize[2])
		if hasOverlap and ScrollingLayoutElement:superClass().mouseEvent(self, posX, posY, isDown, isUp, button, eventUsed) then
			eventUsed = true
		end
		if not GS_IS_CONSOLE_VERSION then
			self.useMouse = true
		end
		if not eventUsed and hasOverlap then
			local deltaIndex = 0
			if Input.isMouseButtonPressed(Input.MOUSE_BUTTON_WHEEL_UP) then
				deltaIndex = -1
			elseif Input.isMouseButtonPressed(Input.MOUSE_BUTTON_WHEEL_DOWN) then
				deltaIndex = 1
			end
			if deltaIndex ~= 0 then
				self:smoothScrollTo(self.targetContentOffsetY + deltaIndex * self.contentSize * 0.05)
			end
			eventUsed = true
		end
	end
	return eventUsed
end
function ScrollingLayoutElement:touchEvent(posX, posY, isDown, isUp, touchId, eventUsed)
	if self:getIsActive() and not self.isMovingToTarget then
		if Platform.isMobile and (self.supportsTouchScrolling and (isUp and self.touchMoveDistanceThreshold <= self.totalTouchMoveDistance)) then
			eventUsed = true
		end
		if ScrollingLayoutElement:superClass().touchEvent(self, posX, posY, isDown, isUp, touchId, eventUsed) then
			eventUsed = true
		end
		if Platform.isMobile and (self.supportsTouchScrolling and self.totalTouchMoveDistance < self.touchMoveDistanceThreshold) then
			eventUsed = false
		end
		if self.supportsTouchScrolling then
			if not eventUsed and self.usedTouchId == nil then
				if isDown and GuiUtils.checkOverlayOverlap(posX, posY, self.absPosition[1], self.absPosition[2], self.absSize[1], self.absSize[2]) then
					self.currentTouchDelta = 0
					if self.scrollDirection == "horizontal" then
						self.lastTouchPos = posX
					else
						self.lastTouchPos = posY
					end
					self.usedTouchId = touchId
					eventUsed = true
					self.totalTouchMoveDistance = 0
					return eventUsed
				end
				return eventUsed
			end
			if self.usedTouchId == touchId then
				if isUp then
					self.usedTouchId = nil
					self.initialScrollSpeed = self.scrollSpeed
					self.totalTouchMoveDistance = 0
					return eventUsed
				end
				local delta = nil
				local distancePixels = nil
				if self.scrollDirection == "horizontal" then
					delta = posX - (self.lastTouchPos or posX)
					distancePixels = (self.lastTouchPos - posX) * g_screenWidth
					self.lastTouchPos = posX
				else
					delta = posY - (self.lastTouchPos or posY)
					distancePixels = (self.lastTouchPos - posY) * g_screenHeight
					self.lastTouchPos = posY
				end
				self.currentTouchDelta = (self.currentTouchDelta or 0) + delta
				self.totalTouchMoveDistance = self.totalTouchMoveDistance + math.abs(distancePixels)
			end
		end
	end
end
function ScrollingLayoutElement:scrollToMakeElementVisible(element)
	if self.scrollDirection == "vertical" then
		local min = self.absPosition[2]
		local max = self.absPosition[2] + self.absSize[2] - element.absSize[2]
		if element.forceFocusScrollToTop then
			self:smoothScrollTo(0, true)
			return
		end
		local alreadyInView = min <= element.absPosition[2] and element.absPosition[2] <= max
		if not alreadyInView then
			local diffMin = min - element.absPosition[2]
			local diffMax = max - element.absPosition[2]
			local newY = nil
			newY = element.absPosition[2] < self.absPosition[2] + self.absSize[2] / 2 and self.contentOffsetY + diffMin + 0.01 or self.contentOffsetY + diffMax - 0.01
			newY = math.clamp(newY, 0, self.contentSize - self.absSize[2])
			self:smoothScrollTo(newY, true)
		end
	else
		local min = self.absPosition[1]
		local max = self.absPosition[1] + self.absSize[1] - element.absSize[1]
		if element.forceFocusScrollToTop then
			self:smoothScrollTo(0, true)
			return
		end
		local alreadyInView = min <= element.absPosition[1] and element.absPosition[1] <= max
		if not alreadyInView then
			local diffMin = min - element.absPosition[1]
			local diffMax = max - element.absPosition[1]
			local newX = nil
			newX = element.absPosition[1] < self.absPosition[1] + self.absSize[1] / 2 and self.contentOffsetX + diffMin + 0.01 or self.contentOffsetX + diffMax - 0.01
			newX = math.clamp(newX, 0, self.contentSize - self.absSize[1])
			self:smoothScrollTo(newX, true)
		end
	end
end
function ScrollingLayoutElement:registerActionEvents()
	g_inputBinding:registerActionEvent(InputAction.MENU_AXIS_UP_DOWN_SECONDARY, self, self.onVerticalCursorInput, false, false, true, true)
end
function ScrollingLayoutElement:removeActionEvents()
	g_inputBinding:removeActionEventsByTarget(self)
end
function ScrollingLayoutElement:onVerticalCursorInput(_, inputValue)
	if not self.useMouse then
		self.sliderElement:setValue(self.sliderElement.currentValue + self.sliderElement.stepSize * inputValue)
	end
	self.useMouse = false
end
function ScrollingLayoutElement:update(dt)
	ScrollingLayoutElement:superClass().update(self, dt)
	if self.isMovingToTarget then
		local offset = nil
		if self:getIsVisible() then
			offset = self.contentOffsetY + (self.targetContentOffsetY - self.contentOffsetY) * 0.01 * dt
			if math.abs(self.targetContentOffsetY - offset) < 0.0005 then
				self.isMovingToTarget = false
			end
		else
			offset = self.targetContentOffsetY
			self.isMovingToTarget = false
		end
		self:scrollTo(offset, nil, true)
	end
	if self.supportsTouchScrolling then
		local isTouchActionActive = self.usedTouchId ~= nil
		local scrollSpeedAbs = math.abs(self.scrollSpeed)
		if isTouchActionActive or 0.0001 < scrollSpeedAbs then
			local delta = 0
			local offset = 0
			offset = self.scrollDirection == "vertical" and self.contentOffsetY + (self.targetContentOffsetY - self.contentOffsetY) * 0.01 * dt or self.contentOffsetX + (self.targetContentOffsetX - self.contentOffsetX) * 0.01 * dt
			if isTouchActionActive then
				self.scrollSpeed = self.currentTouchDelta / dt
				delta = self.currentTouchDelta
			else
				local dir = math.sign(self.scrollSpeed)
				local speedToBreakRatio = self.scrollSpeed / self.initialScrollSpeed
				self.scrollSpeed = math.max(scrollSpeedAbs - dt * self.scrollSpeedInterval, 0) * dir
				delta = self.scrollSpeed * speedToBreakRatio ^ 3 * dt
			end
			if delta ~= 0 then
				if self.scrollDirection == "vertical" then
					self:scrollTo(math.max(math.min(self.contentSize - self.absSize[2], offset + delta), 0))
				elseif delta ~= 0 then
					self:scrollTo(math.min(math.max(-self.contentSize + self.absSize[1], offset + delta), 0))
				end
			end
			self.currentTouchDelta = 0
		end
	end
end
