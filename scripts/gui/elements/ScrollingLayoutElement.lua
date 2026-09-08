-- Local values: ScrollingLayoutElement_mt
ScrollingLayoutElement = {}
local ScrollingLayoutElement_mt = Class(ScrollingLayoutElement, BoxLayoutElement)
Gui.registerGuiElement("ScrollingLayout", ScrollingLayoutElement)

-- Upvalues: ScrollingLayoutElement_mt
-- Local values: self
function ScrollingLayoutElement.new(target, custom_mt)
	-- upvalues: (copy) ScrollingLayoutElement_mt
	local v4_ = BoxLayoutElement.new(target, custom_mt or ScrollingLayoutElement_mt)
	v4_.clipping = true
	v4_.wrapAround = true
	v4_.scrollDirection = v4_.flowDirection
	v4_.sliderElement = nil
	v4_.contentOffsetX = 0
	v4_.contentOffsetY = 0
	v4_.targetContentOffsetX = 0
	v4_.targetContentOffsetY = 0
	v4_.contentSize = 1
	v4_.lastTouchPos = nil
	v4_.usedTouchId = nil
	v4_.currentTouchDelta = 0
	v4_.scrollSpeed = 0
	v4_.initialScrollSpeed = 0
	v4_.supportsTouchScrolling = Platform.hasTouchInput
	v4_.totalTouchMoveDistance = 0
	v4_.touchMoveDistanceThreshold = 30
	return v4_
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

-- Local values: _, e
function ScrollingLayoutElement:onGuiSetupFinished()
	ScrollingLayoutElement:superClass().onGuiSetupFinished(self)
	if self.topClipperElementName ~= nil then
		self.topClipperElement = self.parent:getDescendantByName(self.topClipperElementName)
	end
	if self.bottomClipperElementName ~= nil then
		self.bottomClipperElement = self.parent:getDescendantByName(self.bottomClipperElementName)
	end
	for _, v14_ in pairs(self.elements) do
		self:addFocusListener(v14_)
	end
	if self.flowDirection == "vertical" and self.numFlows == 1 or self.flowDirection == "horizontal" and self.numFlows ~= 1 then
		self.scrollDirection = "vertical"
	else
		self.scrollDirection = "horizontal"
	end
	if self.scrollDirection == "horizontal" then
		self.scrollSpeedInterval = GuiElement.SCROLL_SPEED_PIXEL_PER_MS * g_pixelSizeX
	else
		self.scrollSpeedInterval = GuiElement.SCROLL_SPEED_PIXEL_PER_MS * g_pixelSizeY
	end
end

-- Local values: _, e
function ScrollingLayoutElement:updateLayoutCells(ignoreVisibility)
	ScrollingLayoutElement:superClass().updateLayoutCells(self, ignoreVisibility, true)
	for _, v17_ in pairs(self.elements) do
		self:addFocusListener(v17_)
	end
end

-- Local values: needsUpdate
function ScrollingLayoutElement:invalidateLayout(ignoreVisibility, blockLayoutUpdate)
	local v21_ = not blockLayoutUpdate
	if v21_ then
		self:updateLayoutCells(ignoreVisibility)
	end
	self:applyCellPositions(self.contentOffsetX, self.contentOffsetY)
	if self.handleFocus and (self.focusDirection ~= BoxLayoutElement.FLOW_NONE and v21_) then
		self:focusLinkCells(self.cells)
	end
	if v21_ then
		self:updateContentSize()
	end
	self:updateScrollClippers()
	return self.maxFlowSize
end

-- Local values: visible, visible, visible, visible
function ScrollingLayoutElement:updateScrollClippers(initial)
	if self.scrollDirection == "vertical" then
		if self.topClipperElement ~= nil then
			local v23_ = self.contentOffsetY > 0.01
			self.topClipperElement:setVisible(v23_)
		end
		if self.bottomClipperElement ~= nil then
			local v24_ = self.contentOffsetY - (self.contentSize - self.absSize[2]) < -0.01
			self.bottomClipperElement:setVisible(v24_)
			return
		end
	else
		if self.topClipperElement ~= nil then
			local v25_ = self.contentOffsetX > 0.01
			self.topClipperElement:setVisible(v25_)
		end
		if self.bottomClipperElement ~= nil then
			local v26_ = self.contentOffsetX - (self.contentSize - self.absSize[1]) < -0.01
			self.bottomClipperElement:setVisible(v26_)
		end
	end
end

-- Local values: newStartY, newStartX
function ScrollingLayoutElement:onSliderValueChanged(slider, newValue)
	if self.scrollDirection == "vertical" then
		self:scrollTo(slider.minValue == slider.maxValue and 0 or (self.contentSize - self.absSize[2]) / (slider.maxValue - slider.minValue) * (newValue - slider.minValue), false)
	else
		self:scrollTo(slider.minValue == slider.maxValue and 0 or (self.contentSize - self.absSize[1]) / (slider.maxValue - slider.minValue) * (-newValue + slider.minValue), false)
	end
end

-- Local values: newValue, endPos, newValue
function ScrollingLayoutElement:scrollTo(startPos, updateSlider, noUpdateTarget)
	if self.scrollDirection == "vertical" then
		self.contentOffsetY = startPos
		if not noUpdateTarget then
			self.targetContentOffsetY = startPos
			self.isMovingToTarget = false
		end
		self:invalidateLayout(false, true)
		if (updateSlider == nil or updateSlider) and self.sliderElement ~= nil then
			local v34_ = startPos / ((self.contentSize - self.absSize[2]) / self.sliderElement.maxValue)
			self.sliderElement:setValue(v34_, true)
		end
	else
		self.contentOffsetX = startPos
		if not noUpdateTarget then
			self.targetContentOffsetX = startPos
			self.isMovingToTarget = false
		end
		self:invalidateLayout(false, true)
		if (updateSlider == nil or updateSlider) and self.sliderElement ~= nil then
			local v35_ = (-self.contentSize + self.absSize[1]) / self.sliderElement.maxValue
			local v36_ = startPos / ((v35_ == 0 or not v35_) and 1 or v35_)
			self.sliderElement:setValue(v36_, true)
		end
	end
	self:raiseCallback("onScrollCallback")
end

function ScrollingLayoutElement:scrollToEnd()
	if self.scrollDirection == "vertical" then
		local v38_ = self.contentSize - self.absSize[2]
		self:scrollTo(math.max(v38_, 0), true)
	else
		local v39_ = self.contentSize - self.absSize[1]
		self:scrollTo(-math.max(v39_, 0), true)
	end
end

function ScrollingLayoutElement:smoothScrollTo(offset)
	if self.scrollDirection == "vertical" then
		local v42_ = self.contentSize - self.absSize[2]
		local v43_ = math.min(offset, v42_)
		self.targetContentOffsetY = math.max(v43_, 0)
		self.isMovingToTarget = true
	else
		local v44_ = self.contentSize - self.absSize[1]
		local v45_ = math.min(offset, v44_)
		self.targetContentOffsetX = math.min(v45_, 0)
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
		local v47_ = self.contentOffsetY
		local v48_ = self.contentSize
		local v49_ = math.min(v47_, v48_)
		self.contentOffsetY = math.max(v49_, 0)
		local v50_ = self.targetContentOffsetY
		local v51_ = self.contentSize
		local v52_ = math.min(v50_, v51_)
		self.targetContentOffsetY = math.max(v52_, 0)
	else
		local v53_ = self.contentOffsetX
		local v54_ = self.contentSize
		local v55_ = math.min(v53_, v54_)
		self.contentOffsetX = math.min(v55_, 0)
		local v56_ = self.targetContentOffsetX
		local v57_ = self.contentSize
		local v58_ = math.min(v56_, v57_)
		self.targetContentOffsetX = math.min(v58_, 0)
	end
	self:raiseSliderUpdateEvent()
end

function ScrollingLayoutElement:getNeedsScrolling()
	if self.scrollDirection == "vertical" then
		return self.contentSize > self.absSize[2]
	else
		return self.contentSize > self.absSize[1]
	end
end

function ScrollingLayoutElement:raiseSliderUpdateEvent()
	if self.sliderElement ~= nil then
		self.sliderElement:onBindUpdate(self)
	end
end

-- Local values: size
function ScrollingLayoutElement:getViewOffsetPercentage()
	if self.scrollDirection == "vertical" then
		local v62_ = self.contentSize - self.absSize[2]
		if v62_ ~= 0 then
			return self.contentOffsetY / v62_
		end
	else
		local v63_ = self.contentSize - self.absSize[1]
		if v63_ ~= 0 then
			return self.contentOffsetX / v63_
		end
	end
	return 1
end

function ScrollingLayoutElement:addFocusListener(element)
	local v66_ = element:findFirstFocusable(true)
	if v66_.scrollingFocusEnter_orig == nil then
		v66_.scrollingFocusEnter_orig = v66_.onFocusEnter
	end
	function v66_.onFocusEnter(p67_)
		-- upvalues: (copy) self
		p67_.scrollingFocusEnter_orig(p67_)
		self:scrollToMakeElementVisible(p67_)
	end
end

function ScrollingLayoutElement:removeElement(element)
	ScrollingLayoutElement:superClass().removeElement(self, element)
	if element.scrollingFocusEnter_orig == nil then
		element.onFocusEnter = element.scrollingFocusEnter_orig
	end
end

-- Local values: hasOverlap, deltaIndex
function ScrollingLayoutElement:mouseEvent(posX, posY, isDown, isUp, button, eventUsed)
	if self:getIsActive() then
		local v77_ = GuiUtils.checkOverlayOverlap(posX, posY, self.absPosition[1], self.absPosition[2], self.absSize[1], self.absSize[2])
		eventUsed = v77_ and ScrollingLayoutElement:superClass().mouseEvent(self, posX, posY, isDown, isUp, button, eventUsed) and true or eventUsed
		if not GS_IS_CONSOLE_VERSION then
			self.useMouse = true
		end
		if not eventUsed and v77_ then
			local v78_ = Input.isMouseButtonPressed(Input.MOUSE_BUTTON_WHEEL_UP) and -1 or (Input.isMouseButtonPressed(Input.MOUSE_BUTTON_WHEEL_DOWN) and 1 or 0)
			if v78_ == 0 then
				eventUsed = true
			else
				self:smoothScrollTo(self.targetContentOffsetY + v78_ * self.contentSize * 0.05)
				eventUsed = true
			end
		end
	end
	return eventUsed
end

-- Local values: delta, distancePixels
function ScrollingLayoutElement:touchEvent(posX, posY, isDown, isUp, touchId, eventUsed)
	if self:getIsActive() and not self.isMovingToTarget then
		local v86_ = Platform.isMobile and (self.supportsTouchScrolling and (isUp and self.totalTouchMoveDistance >= self.touchMoveDistanceThreshold)) and true or eventUsed
		eventUsed = ScrollingLayoutElement:superClass().touchEvent(self, posX, posY, isDown, isUp, touchId, v86_) and true or v86_
		if Platform.isMobile and (self.supportsTouchScrolling and self.totalTouchMoveDistance < self.touchMoveDistanceThreshold) then
			eventUsed = false
		end
		if self.supportsTouchScrolling then
			if eventUsed or self.usedTouchId ~= nil then
				if self.usedTouchId == touchId then
					if isUp then
						self.usedTouchId = nil
						self.initialScrollSpeed = self.scrollSpeed
						self.totalTouchMoveDistance = 0
						return eventUsed
					end
					local v87_, v88_
					if self.scrollDirection == "horizontal" then
						v87_ = posX - (self.lastTouchPos or posX)
						v88_ = (self.lastTouchPos - posX) * g_screenWidth
						self.lastTouchPos = posX
					else
						v87_ = posY - (self.lastTouchPos or posY)
						v88_ = (self.lastTouchPos - posY) * g_screenHeight
						self.lastTouchPos = posY
					end
					self.currentTouchDelta = (self.currentTouchDelta or 0) + v87_
					self.totalTouchMoveDistance = self.totalTouchMoveDistance + math.abs(v88_)
				end
			elseif isDown and GuiUtils.checkOverlayOverlap(posX, posY, self.absPosition[1], self.absPosition[2], self.absSize[1], self.absSize[2]) then
				self.currentTouchDelta = 0
				if self.scrollDirection == "horizontal" then
					self.lastTouchPos = posX
				else
					self.lastTouchPos = posY
				end
				self.usedTouchId = touchId
				self.totalTouchMoveDistance = 0
				return true
			end
		end
	end
	return eventUsed
end

-- Local values: min, max, alreadyInView, diffMin, diffMax, newY, min, max, alreadyInView, diffMin, diffMax, newX
function ScrollingLayoutElement:scrollToMakeElementVisible(element)
	if self.scrollDirection == "vertical" then
		local v91_ = self.absPosition[2]
		local v92_ = self.absPosition[2] + self.absSize[2] - element.absSize[2]
		if element.forceFocusScrollToTop then
			self:smoothScrollTo(0, true)
			return
		end
		local v93_
		if v91_ <= element.absPosition[2] then
			v93_ = element.absPosition[2] <= v92_
		else
			v93_ = false
		end
		if not v93_ then
			local v94_ = v91_ - element.absPosition[2]
			local v95_ = v92_ - element.absPosition[2]
			local v96_
			if element.absPosition[2] < self.absPosition[2] + self.absSize[2] / 2 then
				v96_ = self.contentOffsetY + v94_ + 0.01
			else
				v96_ = self.contentOffsetY + v95_ - 0.01
			end
			local v97_ = self.contentSize - self.absSize[2]
			self:smoothScrollTo(math.clamp(v96_, 0, v97_), true)
			return
		end
	else
		local v98_ = self.absPosition[1]
		local v99_ = self.absPosition[1] + self.absSize[1] - element.absSize[1]
		if element.forceFocusScrollToTop then
			self:smoothScrollTo(0, true)
			return
		end
		local v100_
		if v98_ <= element.absPosition[1] then
			v100_ = element.absPosition[1] <= v99_
		else
			v100_ = false
		end
		if not v100_ then
			local v101_ = v98_ - element.absPosition[1]
			local v102_ = v99_ - element.absPosition[1]
			local v103_
			if element.absPosition[1] < self.absPosition[1] + self.absSize[1] / 2 then
				v103_ = self.contentOffsetX + v101_ + 0.01
			else
				v103_ = self.contentOffsetX + v102_ - 0.01
			end
			local v104_ = self.contentSize - self.absSize[1]
			self:smoothScrollTo(math.clamp(v103_, 0, v104_), true)
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

-- Local values: offset, isTouchActionActive, scrollSpeedAbs, delta, offset, dir, speedToBreakRatio
function ScrollingLayoutElement:update(dt)
	ScrollingLayoutElement:superClass().update(self, dt)
	if self.isMovingToTarget then
		local v111_
		if self:getIsVisible() then
			v111_ = self.contentOffsetY + (self.targetContentOffsetY - self.contentOffsetY) * 0.01 * dt
			local v112_ = self.targetContentOffsetY - v111_
			if math.abs(v112_) < 0.0005 then
				self.isMovingToTarget = false
			end
		else
			v111_ = self.targetContentOffsetY
			self.isMovingToTarget = false
		end
		self:scrollTo(v111_, nil, true)
	end
	if self.supportsTouchScrolling then
		local v113_ = self.usedTouchId ~= nil
		local v114_ = self.scrollSpeed
		local v115_ = math.abs(v114_)
		if v113_ or v115_ > 0.0001 then
			local v116_
			if self.scrollDirection == "vertical" then
				v116_ = self.contentOffsetY + (self.targetContentOffsetY - self.contentOffsetY) * 0.01 * dt
			else
				v116_ = self.contentOffsetX + (self.targetContentOffsetX - self.contentOffsetX) * 0.01 * dt
			end
			local v117_
			if v113_ then
				self.scrollSpeed = self.currentTouchDelta / dt
				v117_ = self.currentTouchDelta
			else
				local v118_ = self.scrollSpeed
				local v119_ = math.sign(v118_)
				local v120_ = self.scrollSpeed / self.initialScrollSpeed
				local v121_ = v115_ - dt * self.scrollSpeedInterval
				self.scrollSpeed = math.max(v121_, 0) * v119_
				v117_ = self.scrollSpeed * v120_ ^ 3 * dt
			end
			if v117_ == 0 or self.scrollDirection ~= "vertical" then
				if v117_ ~= 0 then
					local v122_ = -self.contentSize + self.absSize[1]
					local v123_ = v116_ + v117_
					local v124_ = math.max(v122_, v123_)
					self:scrollTo((math.min(v124_, 0)))
				end
			else
				local v125_ = self.contentSize - self.absSize[2]
				local v126_ = v116_ + v117_
				local v127_ = math.min(v125_, v126_)
				self:scrollTo((math.max(v127_, 0)))
			end
			self.currentTouchDelta = 0
		end
	end
end
