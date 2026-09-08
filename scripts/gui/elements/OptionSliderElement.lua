-- Local values: OptionSliderElement_mt
OptionSliderElement = {}
local OptionSliderElement_mt = Class(OptionSliderElement, MultiTextOptionElement)
Gui.registerGuiElement("OptionSlider", OptionSliderElement)
Gui.registerGuiElementProcFunction("OptionSlider", Gui.assignPlaySampleCallback)

-- Upvalues: OptionSliderElement_mt
-- Local values: self
function OptionSliderElement.new(target, custom_mt)
	-- upvalues: (copy) OptionSliderElement_mt
	local v4_ = MultiTextOptionElement.new(target, custom_mt or OptionSliderElement_mt)
	v4_.sliderElement = nil
	v4_.sliderOffset = nil
	v4_.defaultProfileSlider = nil
	v4_.defaultProfileSliderRound = nil
	v4_.useFillingBar = false
	v4_.fillingBarElement = nil
	v4_.defaultProfileFillingBar = nil
	v4_.defaultProfileFillingBarThreePart = nil
	v4_.updateTextPosition = true
	return v4_
end

function OptionSliderElement:loadFromXML(xmlFile, key)
	OptionSliderElement:superClass().loadFromXML(self, xmlFile, key)
	self.sliderOffset = GuiUtils.getNormalizedXValue(getXMLInt(xmlFile, key .. "#sliderOffset"), self.sliderOffset)
	self.useFillingBar = getXMLBool(xmlFile, key .. "#useFillingBar") or self.useFillingBar
	self.updateTextPosition = getXMLBool(xmlFile, key .. "#updateTextPosition") or self.updateTextPosition
end

function OptionSliderElement:loadProfile(profile, applyProfile)
	OptionSliderElement:superClass().loadProfile(self, profile, applyProfile)
	self.sliderOffset = GuiUtils.getNormalizedXValue(profile:getValue("sliderOffset"), self.sliderOffset)
	self.useFillingBar = profile:getBool("useFillingBar", self.useFillingBar)
	self.updateTextPosition = profile:getBool("updateTextPosition", self.updateTextPosition)
	self.defaultProfileSlider = profile:getValue("defaultProfileSlider", self.defaultProfileSlider)
	self.defaultProfileSliderRound = profile:getValue("defaultProfileSliderRound", self.defaultProfileSliderRound)
	self.defaultProfileFillingBar = profile:getValue("defaultProfileFillingBar", self.defaultProfileFillingBar)
	self.defaultProfileFillingBarThreePart = profile:getValue("defaultProfileFillingBarThreePart", self.defaultProfileFillingBarThreePart)
end

function OptionSliderElement:copyAttributes(src)
	OptionSliderElement:superClass().copyAttributes(self, src)
	self.sliderOffset = src.sliderOffset
	self.useFillingBar = src.useFillingBar
	self.updateTextPosition = src.updateTextPosition
	self.defaultProfileSlider = src.defaultProfileSlider
	self.defaultProfileSliderRound = src.defaultProfileSliderRound
	self.defaultProfileFillingBar = src.defaultProfileFillingBar
	self.defaultProfileFillingBarThreePart = src.defaultProfileFillingBarThreePart
end

-- Local values: _, element
function OptionSliderElement:setElementsByName()
	OptionSliderElement:superClass().setElementsByName(self)
	for _, v14_ in pairs(self.elements) do
		if v14_.name == "slider" then
			self.sliderElement = v14_
			v14_.target = self
		end
		if v14_.name == "fillingBar" then
			self.fillingBarElement = v14_
			v14_.target = self
		end
	end
	if self.fillingBarElement == nil then
		self.useFillingBar = false
	end
	if self.sliderElement == nil then
		Logging.warning("OptionSliderElement: could not find a slider element for element with profile " .. self.profile)
	elseif self.leftButtonElement ~= nil and self.sliderElement.absSize[1] + self.leftButtonElement.absSize[1] * 2 >= self.absSize[1] then
		self.sliderOffset = self.absSize[1] / 2
		Logging.warning("OptionSliderElement: not enough space for slider movement with current settings in profile " .. self.profile)
	end
end

-- Local values: baseElement, baseElement, baseElement, baseElement
function OptionSliderElement:addDefaultElements()
	OptionSliderElement:superClass().addDefaultElements(self)
	if self.autoAddDefaultElements then
		if self:getDescendantByName("fillingBar") == nil then
			if self.defaultProfileFillingBar == nil then
				if self.defaultProfileFillingBarThreePart ~= nil then
					local v16_ = ThreePartBitmapElement.new(self)
					v16_.name = "fillingBar"
					self:addElement(v16_)
					v16_:applyProfile(self.defaultProfileFillingBarThreePart)
				end
			else
				local v17_ = BitmapElement.new(self)
				v17_.name = "fillingBar"
				self:addElement(v17_)
				v17_:applyProfile(self.defaultProfileFillingBar)
			end
		end
		if self:getDescendantByName("slider") == nil then
			if self.defaultProfileSliderRound ~= nil then
				local v18_ = RoundCornerElement.new(self)
				v18_.name = "slider"
				self:addElement(v18_)
				v18_:applyProfile(self.defaultProfileSliderRound)
				return
			end
			if self.defaultProfileSlider ~= nil then
				local v19_ = BitmapElement.new(self)
				v19_.name = "slider"
				self:addElement(v19_)
				v19_:applyProfile(self.defaultProfileSlider)
			end
		end
	end
end

function OptionSliderElement:onOpen()
	OptionSliderElement:superClass().onOpen(self)
	self:updateSlider()
end

-- Local values: leftButton, rightButton, slider, slider, sliderWidth, stepSize, mouseMoveDistance, sliderLocalPosX, sliderPosX, state
function OptionSliderElement:mouseEvent(posX, posY, isDown, isUp, button, eventUsed)
	if self:getIsActive() then
		eventUsed = self.wasContinuousTrigger and isUp and true or (MultiTextOptionElement:superClass().mouseEvent(self, posX, posY, isDown, isUp, button, eventUsed) and true or eventUsed)
		if isDown then
			local v28_ = self.leftButtonElement
			local v29_ = not self.hideLeftRightButtons
			if v29_ then
				v29_ = GuiUtils.checkOverlayOverlap(posX, posY, v28_.absPosition[1], v28_.absPosition[2], v28_.absSize[1], v28_.absSize[2], v28_.hotspot)
			end
			self.isLeftButtonPressed = v29_
			local v30_ = self.rightButtonElement
			local v31_ = not self.hideLeftRightButtons
			if v31_ then
				v31_ = GuiUtils.checkOverlayOverlap(posX, posY, v30_.absPosition[1], v30_.absPosition[2], v30_.absSize[1], v30_.absSize[2], v30_.hotspot)
			end
			self.isRightButtonPressed = v31_
			local v32_ = self.sliderElement
			local v33_
			if v32_ == nil then
				v33_ = false
			else
				v33_ = GuiUtils.checkOverlayOverlap(posX, posY, v32_.absPosition[1], v32_.absPosition[2], v32_.absSize[1], v32_.absSize[2], v32_.hotspot)
			end
			self.isSliderPressed = v33_
			self.isSliderAreaPressed = GuiUtils.checkOverlayOverlap(posX, posY, self.absPosition[1] + self.sliderOffset, self.absPosition[2], self.absSize[1] - 2 * self.sliderOffset, self.absSize[2])
			if self.sliderMousePosX == nil then
				self.sliderMousePosX = posX
			end
			self.delayTime = g_time
		elseif isUp then
			self.delayTime = math.huge
			self.scrollDelayDuration = MultiTextOptionElement.FIRST_INPUT_DELAY
			self.wasContinuousTrigger = false
			self.continuousTriggerTime = 0
			self.isLeftButtonPressed = false
			self.leftDelayTime = 0
			self.isRightButtonPressed = false
			self.rightDelayTime = 0
			self.isSliderPressed = false
			self.isSliderAreaPressed = false
			self.sliderMousePosX = nil
			self.hasWrapped = false
		end
		if eventUsed or not GuiUtils.checkOverlayOverlap(posX, posY, self.absPosition[1], self.absPosition[2], self.absSize[1], self.absSize[2], nil) then
			if self.inputEntered and not self.focusActive then
				FocusManager:unsetHighlight(self)
				self.inputEntered = false
			end
		else
			if not (self.inputEntered or self:getIsFocused()) then
				FocusManager:setHighlight(self)
				self.inputEntered = true
			end
			if #self.texts > 1 and self.isSliderAreaPressed then
				if not self:getIsFocused() then
					FocusManager:setFocus(self)
				end
				local v34_ = self.sliderElement
				local v35_ = v34_.absSize[1]
				local v36_ = (self.absSize[1] - 2 * self.sliderOffset - v35_) / (#self.texts - 1)
				local v37_ = posX - self.sliderMousePosX
				local v38_ = posX - self.absPosition[1] - self.sliderOffset - v34_.absSize[1] * 0.5
				if self.isSliderPressed then
					v38_ = v34_.absPosition[1] - self.absPosition[1] - self.sliderOffset
				end
				local v39_ = MathUtil.snapValue(v38_ + v37_, v36_)
				local v40_ = self.absSize[1] - v35_ - 2 * self.sliderOffset
				local v41_ = math.clamp(v39_, 0, v40_)
				local v42_ = MathUtil.round(v41_ / v36_) + 1
				if v42_ ~= self.state then
					if self.isSliderPressed then
						self.sliderMousePosX = self.sliderMousePosX + v36_ * (v42_ - self.state)
					end
					self.isSliderPressed = true
					self:setState(v42_, true)
				end
				v34_:setAbsolutePosition(self.absPosition[1] + v41_ + self.sliderOffset, v34_.absPosition[2])
				if self.updateTextPosition then
					self.textElement:setAbsolutePosition(v34_.absPosition[1] - (self.textElement.absSize[1] - v34_.absSize[1]) * 0.5, self.textElement.absPosition[2])
				end
				if self.useFillingBar then
					self.fillingBarElement:setSize((self.state - 1) / (#self.texts - 1) * (self.absSize[1] - self.sliderOffset * 2) + self.sliderOffset, nil)
					return eventUsed
				end
			end
		end
	end
	return eventUsed
end

-- Local values: leftButton, rightButton, slider, slider, sliderWidth, stepSize, mouseMoveDistance, sliderLocalPosX, sliderPosX, state
function OptionSliderElement:touchEvent(posX, posY, isDown, isUp, touchId, eventUsed)
	if self:getIsActive() then
		eventUsed = self.wasContinuousTrigger and isUp and true or (MultiTextOptionElement:superClass().touchEvent(self, posX, posY, isDown, isUp, touchId, eventUsed) and true or eventUsed)
		if isDown then
			local v50_ = self.leftButtonElement
			local v51_ = not self.hideLeftRightButtons
			if v51_ then
				v51_ = GuiUtils.checkOverlayOverlap(posX, posY, v50_.absPosition[1], v50_.absPosition[2], v50_.absSize[1], v50_.absSize[2], v50_.hotspot)
			end
			self.isLeftButtonPressed = v51_
			local v52_ = self.rightButtonElement
			local v53_ = not self.hideLeftRightButtons
			if v53_ then
				v53_ = GuiUtils.checkOverlayOverlap(posX, posY, v52_.absPosition[1], v52_.absPosition[2], v52_.absSize[1], v52_.absSize[2], v52_.hotspot)
			end
			self.isRightButtonPressed = v53_
			local v54_ = self.sliderElement
			local v55_
			if v54_ == nil then
				v55_ = false
			else
				v55_ = GuiUtils.checkOverlayOverlap(posX, posY, v54_.absPosition[1], v54_.absPosition[2], v54_.absSize[1], v54_.absSize[2], v54_.hotspot)
			end
			self.isSliderPressed = v55_
			if self.sliderMousePosX == nil then
				self.sliderMousePosX = posX
			end
			self.delayTime = g_time
		elseif isUp then
			self.delayTime = math.huge
			self.scrollDelayDuration = MultiTextOptionElement.FIRST_INPUT_DELAY
			self.wasContinuousTrigger = false
			self.continuousTriggerTime = 0
			self.isLeftButtonPressed = false
			self.leftDelayTime = 0
			self.isRightButtonPressed = false
			self.rightDelayTime = 0
			self.isSliderPressed = false
			self.sliderMousePosX = nil
			self.hasWrapped = false
		end
		if eventUsed or not GuiUtils.checkOverlayOverlap(posX, posY, self.absPosition[1], self.absPosition[2], self.absSize[1], self.absSize[2], nil) then
			if self.inputEntered and not self:getIsFocused() then
				FocusManager:unsetHighlight(self)
				self.inputEntered = false
			end
		else
			if not (self.inputEntered or self:getIsFocused()) then
				FocusManager:setHighlight(self)
				self.inputEntered = true
			end
			if self.isSliderPressed and #self.texts > 1 then
				if not self:getIsFocused() then
					FocusManager:setFocus(self)
				end
				local v56_ = self.sliderElement
				local v57_ = v56_.absSize[1]
				local v58_ = (self.absSize[1] - 2 * self.sliderOffset - v57_) / (#self.texts - 1)
				local v59_ = posX - self.sliderMousePosX
				local v60_ = v56_.absPosition[1] - self.absPosition[1] - self.sliderOffset
				local v61_ = MathUtil.snapValue(v60_ + v59_, v58_)
				local v62_ = self.absSize[1] - v57_ - 2 * self.sliderOffset
				local v63_ = math.clamp(v61_, 0, v62_)
				local v64_ = MathUtil.round(v63_ / v58_) + 1
				if v64_ ~= self.state then
					self.sliderMousePosX = self.sliderMousePosX + v58_ * (v64_ - self.state)
					self:setState(v64_, true)
				end
				v56_:setAbsolutePosition(self.absPosition[1] + v63_ + self.sliderOffset, v56_.absPosition[2])
				if self.updateTextPosition then
					self.textElement:setAbsolutePosition(v56_.absPosition[1] - (self.textElement.absSize[1] - v56_.absSize[1]) * 0.5, self.textElement.absPosition[2])
				end
				if self.useFillingBar then
					self.fillingBarElement:setSize((self.state - 1) / (#self.texts - 1) * (self.absSize[1] - self.sliderOffset * 2) + self.sliderOffset, nil)
					return eventUsed
				end
			end
		end
	end
	return eventUsed
end

-- Local values: text, slider, minVal, maxVal, pos, fillingBarSize
function OptionSliderElement:updateSlider()
	if self.sliderElement ~= nil then
		if self.sliderOffset == nil then
			self.sliderOffset = self.leftButtonElement.absSize[1]
		end
		local v66_ = self.textElement
		local v67_ = self.sliderElement
		local v68_ = self.absPosition[1] + self.sliderOffset
		local v69_ = self.absPosition[1] + self.absSize[1] - v67_.absSize[1] - self.sliderOffset
		if #self.texts > 1 then
			v69_ = v68_ + (self.state - 1) / (#self.texts - 1) * (v69_ - v68_)
		end
		v67_:setAbsolutePosition(v69_, v67_.absPosition[2])
		if self.updateTextPosition then
			v66_:setAbsolutePosition(v69_ - (v66_.absSize[1] - v67_.absSize[1]) * 0.5, v66_.absPosition[2])
		end
		if self.useFillingBar then
			local v70_ = self.absSize[1] - self.sliderOffset
			if #self.texts > 1 then
				v70_ = (self.state - 1) / (#self.texts - 1) * (self.absSize[1] - self.sliderOffset * 2) + self.sliderOffset
			end
			self.fillingBarElement:setSize(v70_, nil)
		end
	end
end

function OptionSliderElement:updateAbsolutePosition()
	OptionSliderElement:superClass().updateAbsolutePosition(self)
	self:updateSlider()
end

function OptionSliderElement:updateContentElement()
	OptionSliderElement:superClass().updateContentElement(self)
	self:updateSlider()
end
