-- Local values: SliderElement_mt
SliderElement = {}
local SliderElement_mt = Class(SliderElement, GuiElement)
Gui.registerGuiElement("Slider", SliderElement)
Gui.registerGuiElementProcFunction("Slider", Gui.assignPlaySampleCallback)
SliderElement.DIRECTION_X = 1
SliderElement.DIRECTION_Y = 2

-- Upvalues: SliderElement_mt
-- Local values: self
function SliderElement.new(target, custom_mt)
	-- upvalues: (copy) SliderElement_mt
	local v4_ = GuiElement.new(target, custom_mt or SliderElement_mt)
	v4_:include(PlaySampleMixin)
	v4_.mouseDown = false
	v4_.minValue = 0
	v4_.maxValue = 100
	v4_.currentValue = 0
	v4_.defaultValue = 0
	v4_.sliderValue = 0
	v4_.stepSize = 1
	v4_.direction = SliderElement.DIRECTION_Y
	v4_.hasButtons = true
	v4_.isThreePartBitmap = false
	v4_.overlay = {}
	v4_.sliderOverlay = {}
	v4_.startOverlay = {}
	v4_.endOverlay = {}
	v4_.startSize = { 0, 0 }
	v4_.endSize = { 0, 0 }
	v4_.sliderOffset = 0
	v4_.sliderSize = { 0, 0 }
	v4_.sliderPosition = { 0, 0 }
	v4_.adjustSliderSize = true
	v4_.sliderBoxMargin = nil
	v4_.textElement = nil
	v4_.dataElementId = nil
	v4_.textElementId = nil
	v4_.minAbsSliderPos = 0.08
	v4_.maxAbsSliderPos = 0.92
	v4_.isSliderVisible = true
	v4_.needsSlider = true
	v4_.useStepRounding = false
	v4_.hideParentWhenEmpty = false
	v4_.canResetToDefault = false
	return v4_
end

function SliderElement:delete()
	GuiOverlay.deleteOverlay(self.endOverlay)
	GuiOverlay.deleteOverlay(self.startOverlay)
	GuiOverlay.deleteOverlay(self.sliderOverlay)
	GuiOverlay.deleteOverlay(self.overlay)
	SliderElement:superClass().delete(self)
end

-- Local values: direction
function SliderElement:loadFromXML(xmlFile, key)
	SliderElement:superClass().loadFromXML(self, xmlFile, key)
	GuiOverlay.loadOverlay(self, self.overlay, "image", self.imageSize, nil, xmlFile, key)
	GuiOverlay.loadOverlay(self, self.sliderOverlay, "sliderImage", self.imageSize, nil, xmlFile, key)
	GuiOverlay.loadOverlay(self, self.startOverlay, "startImage", self.imageSize, nil, xmlFile, key)
	GuiOverlay.loadOverlay(self, self.endOverlay, "endImage", self.imageSize, nil, xmlFile, key)
	local v9_ = getXMLString(xmlFile, key .. "#direction")
	if v9_ ~= nil then
		if v9_ == "y" then
			self.direction = SliderElement.DIRECTION_Y
		elseif v9_ == "x" then
			self.direction = SliderElement.DIRECTION_X
		end
	end
	self:addCallback(xmlFile, key .. "#onClick", "onClickCallback")
	self:addCallback(xmlFile, key .. "#onChanged", "onChangedCallback")
	self.hasButtons = Utils.getNoNil(getXMLBool(xmlFile, key .. "#hasButtons"), self.hasButtons)
	self.minValue = getXMLFloat(xmlFile, key .. "#minValue") or self.minValue
	self.maxValue = getXMLFloat(xmlFile, key .. "#maxValue") or self.maxValue
	if self.minValue > self.maxValue then
		Logging.xmlWarning(xmlFile, "\'#minValue\' is higher \'#maxValue\', the value was inverted!")
		local v10_ = self.minValue
		local v11_ = self.maxValue
		local v12_ = math.min(v10_, v11_)
		local v13_ = self.minValue
		local v14_ = self.maxValue
		local v15_ = math.max(v13_, v14_)
		self.minValue = v12_
		self.maxValue = v15_
	end
	self.currentValue = getXMLFloat(xmlFile, key .. "#currentValue") or self.currentValue
	self.defaultValue = self.currentValue
	self:setValue(self.currentValue, nil, true)
	self.stepSize = getXMLFloat(xmlFile, key .. "#stepSize") or self.stepSize
	self.isThreePartBitmap = Utils.getNoNil(getXMLBool(xmlFile, key .. "#isThreePartBitmap"), self.isThreePartBitmap)
	self.hideParentWhenEmpty = Utils.getNoNil(getXMLBool(xmlFile, key .. "#hideParentWhenEmpty"), self.hideParentWhenEmpty)
	self.useStepRounding = Utils.getNoNil(getXMLBool(xmlFile, key .. "#useStepRounding"), self.useStepRounding)
	self.sliderBoxMargin = GuiUtils.getNormalizedValue(getXMLFloat(xmlFile, key .. "#sliderBoxMargin"), self.direction == SliderElement.DIRECTION_X, self.sliderBoxMargin)
	self.sliderOffset = GuiUtils.getNormalizedXValue(getXMLString(xmlFile, key .. "#sliderOffset"), self.sliderOffset)
	self.sliderSize = GuiUtils.getNormalizedScreenValues(getXMLString(xmlFile, key .. "#sliderSize"), self.sliderSize)
	self.startSize = GuiUtils.getNormalizedScreenValues(getXMLString(xmlFile, key .. "#startImageSize"), self.startSize)
	self.endSize = GuiUtils.getNormalizedScreenValues(getXMLString(xmlFile, key .. "#endImageSize"), self.endSize)
	self.dataElementId = getXMLString(xmlFile, key .. "#dataElementId")
	self.dataElementName = getXMLString(xmlFile, key .. "#dataElementName")
	self.textElementId = getXMLString(xmlFile, key .. "#textElementId")
	self.canResetToDefault = getXMLBool(xmlFile, key .. "#resetToDefault") or self.canResetToDefault
	GuiOverlay.createOverlay(self.overlay)
	GuiOverlay.createOverlay(self.sliderOverlay)
	GuiOverlay.createOverlay(self.startOverlay)
	GuiOverlay.createOverlay(self.endOverlay)
end

-- Local values: direction, isHorizontalSlider
function SliderElement:loadProfile(profile, applyProfile)
	SliderElement:superClass().loadProfile(self, profile, applyProfile)
	GuiOverlay.loadOverlay(self, self.overlay, "image", self.imageSize, profile, nil, nil)
	GuiOverlay.loadOverlay(self, self.sliderOverlay, "sliderImage", self.imageSize, profile, nil, nil)
	GuiOverlay.loadOverlay(self, self.startOverlay, "startImage", self.imageSize, profile, nil, nil)
	GuiOverlay.loadOverlay(self, self.endOverlay, "endImage", self.imageSize, profile, nil, nil)
	local v19_ = profile:getValue("direction")
	if v19_ ~= nil then
		if v19_ == "y" then
			self.direction = SliderElement.DIRECTION_Y
		elseif v19_ == "x" then
			self.direction = SliderElement.DIRECTION_X
		end
	end
	self.hasButtons = profile:getBool("hasButtons", self.hasButtons)
	self.minValue = profile:getNumber("minValue", self.minValue)
	self.maxValue = profile:getNumber("maxValue", self.maxValue)
	if self.minValue > self.maxValue then
		Logging.xmlWarning(profile, "\'#minValue\' is higher \'#maxValue\', the value was inverted!")
		local v20_ = self.minValue
		local v21_ = self.maxValue
		local v22_ = math.min(v20_, v21_)
		local v23_ = self.minValue
		local v24_ = self.maxValue
		local v25_ = math.max(v23_, v24_)
		self.minValue = v22_
		self.maxValue = v25_
	end
	self.currentValue = profile:getNumber("currentValue", self.currentValue)
	self.defaultValue = self.currentValue
	self:setValue(self.currentValue, nil, true)
	self.stepSize = profile:getNumber("stepSize", self.stepSize)
	self.isThreePartBitmap = profile:getBool("isThreePartBitmap", self.isThreePartBitmap)
	self.hideParentWhenEmpty = profile:getBool("hideParentWhenEmpty", self.hideParentWhenEmpty)
	self.useStepRounding = profile:getBool("useStepRounding", self.useStepRounding)
	local v26_ = self.direction == SliderElement.DIRECTION_X
	self.sliderSize = GuiUtils.getNormalizedScreenValues(profile:getValue("sliderSize"), self.sliderSize)
	self.sliderBoxMargin = GuiUtils.getNormalizedValue(profile:getValue("sliderBoxMargin"), v26_, self.sliderBoxMargin)
	self.sliderOffset = GuiUtils.getNormalizedValue(profile:getValue("sliderOffset"), v26_, self.sliderOffset)
	self.startSize = GuiUtils.getNormalizedScreenValues(profile:getValue("startImageSize"), self.startSize)
	self.endSize = GuiUtils.getNormalizedScreenValues(profile:getValue("endImageSize"), self.endSize)
	self.canResetToDefault = profile:getBool("resetToDefault", self.canResetToDefault)
end

function SliderElement:copyAttributes(src)
	SliderElement:superClass().copyAttributes(self, src)
	GuiOverlay.copyOverlay(self.overlay, src.overlay)
	GuiOverlay.copyOverlay(self.sliderOverlay, src.sliderOverlay)
	GuiOverlay.copyOverlay(self.startOverlay, src.startOverlay)
	GuiOverlay.copyOverlay(self.endOverlay, src.endOverlay)
	self.direction = src.direction
	self.hasButtons = src.hasButtons
	self.minValue = src.minValue
	self.maxValue = src.maxValue
	self.currentValue = src.currentValue
	self.defaultValue = self.currentValue
	self.stepSize = src.stepSize
	self.sliderOffset = src.sliderOffset
	self.sliderSize = table.clone(src.sliderSize)
	self.isThreePartBitmap = src.isThreePartBitmap
	self.hideParentWhenEmpty = src.hideParentWhenEmpty
	self.useStepRounding = src.useStepRounding
	self.sliderBoxMargin = src.sliderBoxMargin
	self.startSize = table.clone(src.startSize)
	self.endSize = table.clone(src.endSize)
	self.canResetToDefault = src.canResetToDefault
	self.dataElementId = src.dataElementId
	self.dataElementName = src.dataElementName
	self.textElementId = src.textElementId
	self.onClickCallback = src.onClickCallback
	self.onChangedCallback = src.onChangedCallback
	GuiMixin.cloneMixin(PlaySampleMixin, src, self)
end

function SliderElement:setSliderVisible(visible)
	self.isSliderVisible = visible
end

-- Local values: dataElement, findDataElement, dataElement
function SliderElement:onGuiSetupFinished()
	SliderElement:superClass().onGuiSetupFinished(self)
	if self.textElementId ~= nil then
		if self.target[self.textElementId] == nil then
			printWarning("Warning: TextElementId \'" .. self.textElementId .. "\' not found for \'" .. self.target.name .. "\'!")
		else
			self.textElement = self.target[self.textElementId]
		end
	end
	if self.dataElementId == nil then
		if self.dataElementName ~= nil and self.parent then
			local v34_ = self.parent:getFirstDescendant(function(p32_)
				-- upvalues: (copy) self
				local v33_ = p32_.name
				if v33_ then
					v33_ = p32_.name == self.dataElementName
				end
				return v33_
			end)
			if v34_ then
				self:setDataElement(v34_)
			else
				local v35_ = printWarning
				local v36_ = self.dataElementName
				local v37_ = self.parent
				v35_("Warning: DataElementName \'" .. v36_ .. "\' not found as descendant of \'" .. tostring(v37_) .. "\'!")
			end
		end
	elseif self.target[self.dataElementId] == nil then
		printWarning("Warning: DataElementId \'" .. self.dataElementId .. "\' not found for \'" .. self.target.name .. "\'!")
	else
		self:setDataElement(self.target[self.dataElementId])
	end
	if self.sliderBoxMargin ~= nil then
		if self.direction == SliderElement.DIRECTION_X then
			self:setSize(self.size[1] - self.sliderBoxMargin * 2)
			self:setPosition(self.sliderBoxMargin)
			return
		end
		self:setSize(nil, self.size[2] - self.sliderBoxMargin * 2)
		self:setPosition(nil, self.sliderBoxMargin)
	end
end

function SliderElement:addElement(element)
	SliderElement:superClass().addElement(self, element)
	if self.hasButtons then
		if #self.elements == 1 then
			self.upButtonElement = element
			element.target = self
			if self.direction == SliderElement.DIRECTION_Y then
				element:setCallback("onClickCallback", "onScrollDown")
			else
				element:setCallback("onClickCallback", "onScrollUp")
			end
			self:setDisabled(self.disabled)
			return
		end
		if #self.elements == 2 then
			self.downButtonElement = element
			element.target = self
			if self.direction == SliderElement.DIRECTION_Y then
				element:setCallback("onClickCallback", "onScrollUp")
			else
				element:setCallback("onClickCallback", "onScrollDown")
			end
			self:setDisabled(self.disabled)
		end
	end
end

function SliderElement:setDataElement(element)
	if self.dataElement ~= nil then
		self.dataElement.sliderElement = nil
		self.dataElement = nil
	end
	if element ~= nil then
		element.sliderElement = self
		self.dataElement = element
		self:onBindUpdate(element, false)
	end
end

-- Local values: rem, numDecimalPlaces, mult, _, element
function SliderElement:setValue(newValue, doNotUpdateDataElement, immediateMode)
	local v46_ = self.minValue
	local v47_ = self.maxValue
	self.sliderValue = math.clamp(newValue, v46_, v47_)
	self:updateSliderPosition()
	if self.useStepRounding then
		local v48_ = (newValue - self.minValue) % self.stepSize
		local v49_
		if self.stepSize - v48_ <= v48_ then
			v49_ = newValue + self.stepSize - v48_
		else
			v49_ = newValue - v48_
		end
		local v50_ = self.minValue
		local v51_ = self.maxValue
		newValue = math.clamp(v49_, v50_, v51_)
	end
	local v52_ = newValue * 100000 + 0.5
	local v53_ = math.floor(v52_) / 100000
	local v54_ = self.minValue
	local v55_ = self.maxValue
	local v56_ = math.clamp(v53_, v54_, v55_)
	if v56_ == self.currentValue then
		return false
	end
	self.currentValue = v56_
	if self.textElement ~= nil then
		self.textElement:setText(self.currentValue)
	end
	self:callOnChanged()
	for _, v57_ in pairs(self.elements) do
		if v57_.onSliderValueChanged ~= nil then
			v57_:onSliderValueChanged(self, v56_, immediateMode)
		end
	end
	if self.dataElement ~= nil and (doNotUpdateDataElement == nil or not doNotUpdateDataElement) then
		self.dataElement:onSliderValueChanged(self, v56_, immediateMode)
	end
	self:updateSliderButtons()
	return true
end

function SliderElement:updateSliderButtons()
	if self.upButtonElement ~= nil then
		self.upButtonElement:setDisabled(self.disabled or self.currentValue == self.maxValue)
	end
	if self.downButtonElement ~= nil then
		self.downButtonElement:setDisabled(self.disabled or self.currentValue == self.minValue)
	end
end

function SliderElement:setMinValue(minValue)
	self.minValue = math.max(minValue, 1)
	if self.minValue > self.currentValue then
		self:setValue(self.minValue, nil, true)
	end
	self:updateSliderPosition()
end

function SliderElement:setMaxValue(maxValue, newCurrentValue)
	self.maxValue = math.max(maxValue, 1)
	if newCurrentValue == nil then
		newCurrentValue = self.currentValue
	end
	if self.maxValue < newCurrentValue then
		self:setValue(self.maxValue, nil, true)
	end
	self:updateSliderPosition()
end

function SliderElement:getMinValue()
	return self.minValue
end

function SliderElement:getMaxValue()
	return self.maxValue
end

function SliderElement:getValue()
	return self.currentValue
end

function SliderElement:updateAbsolutePosition()
	SliderElement:superClass().updateAbsolutePosition(self)
	self:updateSliderLimits()
end

function SliderElement:setSize(x, y)
	SliderElement:superClass().setSize(self, x, y)
	self:updateSliderLimits()
end

-- Local values: axis, visibleToMaxRatio, _, child
function SliderElement:setSliderSize(visibleItems, maxItems)
	if self.adjustSliderSize then
		local v74_ = self.direction == SliderElement.DIRECTION_Y and 2 or 1
		local v75_
		if maxItems == 0 then
			v75_ = 0
		else
			local v76_ = visibleItems / maxItems
			v75_ = math.min(1, v76_) or 0
		end
		self.sliderSize[v74_] = v75_ > 0 and self.size[v74_] * v75_ or self.size[v74_]
		if self.isThreePartBitmap then
			local v77_ = self.sliderSize
			local v78_ = GuiUtils.alignValueToScreenPixels
			local v79_ = self.sliderSize[v74_]
			local v80_ = self.startSize[v74_] + self.endSize[v74_]
			local v81_ = self.absSize[v74_] * 0.025
			v77_[v74_] = v78_(math.max(v79_, v80_, v81_), v74_ == SliderElement.DIRECTION_X)
		else
			local v82_ = self.sliderSize
			local v83_ = GuiUtils.alignValueToScreenPixels
			local v84_ = self.sliderSize[v74_]
			local v85_ = self.absSize[v74_] * 0.05
			v82_[v74_] = v83_(math.max(v84_, v85_), v74_ == SliderElement.DIRECTION_X)
		end
		self:updateSliderLimits()
	end
	if not self.hasButtons then
		for _, v86_ in pairs(self.elements) do
			v86_:setSize(self.sliderSize[1], self.sliderSize[2])
		end
	end
end

-- Local values: axis
function SliderElement:updateSliderLimits()
	local v88_ = self.direction
	self.minAbsSliderPos = self.absPosition[v88_]
	self.maxAbsSliderPos = self.absPosition[v88_] + self.absSize[v88_] - self.sliderSize[v88_]
	self:updateSliderPosition()
end

function SliderElement:setAlpha(alpha)
	SliderElement:superClass().setAlpha(self, alpha)
	if self.overlay ~= nil then
		self.overlay.alpha = self.alpha
	end
	if self.sliderOverlay ~= nil then
		self.sliderOverlay.alpha = self.alpha
	end
end

-- Local values: newValue, mousePos, deltaY, deltaX
function SliderElement:mouseEvent(posX, posY, isDown, isUp, button, eventUsed)
	if self:getIsActive() then
		eventUsed = SliderElement:superClass().mouseEvent(self, posX, posY, isDown, isUp, button, eventUsed) and true or eventUsed
		if self.mouseDown and (isUp and button == Input.MOUSE_BUTTON_LEFT) then
			self.clickedOnSlider = false
			self.mouseDown = false
			self:raiseCallback("onClickCallback", self.currentValue)
			eventUsed = true
		end
		if not eventUsed and (GuiUtils.checkOverlayOverlap(posX, posY, self.absPosition[1], self.absPosition[2], self.absSize[1], self.absSize[2]) or GuiUtils.checkOverlayOverlap(posX, posY, self.sliderPosition[1], self.sliderPosition[2], self.sliderSize[1], self.sliderSize[2])) then
			eventUsed = true
			if self.canResetToDefault and button == Input.MOUSE_BUTTON_RIGHT then
				self:setValue(self.defaultValue, nil, false)
			end
			if Input.isMouseButtonPressed(Input.MOUSE_BUTTON_WHEEL_UP) then
				self:setValue(self.currentValue - self.stepSize, nil, false)
			end
			if Input.isMouseButtonPressed(Input.MOUSE_BUTTON_WHEEL_DOWN) then
				self:setValue(self.currentValue + self.stepSize, nil, false)
			end
			if isDown and button == Input.MOUSE_BUTTON_LEFT then
				if not self.mouseDown and GuiUtils.checkOverlayOverlap(posX, posY, self.sliderPosition[1], self.sliderPosition[2], self.sliderSize[1], self.sliderSize[2]) then
					self.clickedOnSlider = true
					self.lastMousePosX = posX
					self.lastMousePosY = posY
					self.lastSliderPosX = self.sliderPosition[1]
					self.lastSliderPosY = self.sliderPosition[2]
				end
				self.mouseDown = true
			end
		end
		if self.mouseDown and self.needsSlider then
			eventUsed = true
			local v98_
			if self.direction == SliderElement.DIRECTION_Y then
				if self.clickedOnSlider then
					local v99_ = posY - self.lastMousePosY
					local v100_ = self.lastSliderPosY + v99_
					v98_ = self.minValue + (1 - (v100_ - self.minAbsSliderPos) / (self.maxAbsSliderPos - self.minAbsSliderPos)) * (self.maxValue - self.minValue)
				else
					local v101_
					if self.sliderPosition[2] + self.sliderSize[2] < posY then
						v101_ = posY - self.sliderSize[2]
					else
						v101_ = posY
					end
					v98_ = self.minValue + (1 - (v101_ - self.minAbsSliderPos) / (self.maxAbsSliderPos - self.minAbsSliderPos)) * (self.maxValue - self.minValue)
				end
			else
				local v102_
				if self.clickedOnSlider then
					local v103_ = posX - self.lastMousePosX
					v102_ = self.lastSliderPosX + v103_
				elseif self.sliderPosition[1] + self.sliderSize[1] < posX then
					v102_ = posX - self.sliderSize[1]
				else
					v102_ = posX
				end
				v98_ = self.minValue + (v102_ - self.minAbsSliderPos) / (self.maxAbsSliderPos - self.minAbsSliderPos) * (self.maxValue - self.minValue)
			end
			self:setValue(v98_, nil, true)
		end
	end
	if self.mouseDown and self:isOutOfBound(posX, posY) then
		self.mouseDown = false
	end
	return eventUsed
end

-- Local values: state, _, child
function SliderElement:updateSliderPosition()
	local v105_ = self.maxValue == self.minValue and 0 or ((self.sliderValue - self.minValue) / (self.maxValue - self.minValue) or 0)
	if self.direction == SliderElement.DIRECTION_Y then
		self.sliderPosition[1] = self.absPosition[1] + self.sliderOffset
		self.sliderPosition[2] = MathUtil.lerp(self.minAbsSliderPos, self.maxAbsSliderPos, 1 - v105_)
	else
		self.sliderPosition[1] = MathUtil.lerp(self.minAbsSliderPos, self.maxAbsSliderPos, v105_)
		self.sliderPosition[2] = self.absPosition[2] + self.sliderOffset
	end
	self:updateSliderButtons()
	if not self.hasButtons then
		for _, v106_ in pairs(self.elements) do
			v106_:setAbsolutePosition(self.sliderPosition[1], self.sliderPosition[2])
		end
	end
end

function SliderElement:callOnChanged()
	self:raiseCallback("onChangedCallback", self.currentValue)
end

function SliderElement:keyEvent(unicode, sym, modifier, isDown, eventUsed)
	return self:getIsActive() and SliderElement:superClass().keyEvent(self, unicode, sym, modifier, isDown, eventUsed) and true or false
end

-- Local values: state, x, y
function SliderElement:draw(clipX1, clipY1, clipX2, clipY2)
	local v119_ = self:getOverlayState()
	GuiOverlay.renderOverlay(self.overlay, self.absPosition[1], self.absPosition[2], self.size[1], self.size[2], v119_, clipX1, clipY1, clipX2, clipY2)
	if self.isSliderVisible and self.needsSlider then
		if self.isThreePartBitmap then
			local v120_ = self.sliderPosition[1]
			local v121_ = self.sliderPosition[2]
			if self.direction == SliderElement.DIRECTION_X then
				GuiOverlay.renderOverlay(self.startOverlay, v120_, v121_, self.startSize[1], self.sliderSize[2], v119_, clipX1, clipY1, clipX2, clipY2)
				GuiOverlay.renderOverlay(self.sliderOverlay, v120_ + self.startSize[1], v121_, self.sliderSize[1] - self.startSize[1] - self.endSize[1], self.sliderSize[2], v119_, clipX1, clipY1, clipX2, clipY2)
				GuiOverlay.renderOverlay(self.endOverlay, v120_ + self.sliderSize[1] - self.endSize[1], v121_, self.endSize[1], self.sliderSize[2], v119_, clipX1, clipY1, clipX2, clipY2)
			else
				GuiOverlay.renderOverlay(self.startOverlay, v120_, v121_ + self.sliderSize[2] - self.startSize[2], self.sliderSize[1], self.startSize[2], v119_, clipX1, clipY1, clipX2, clipY2)
				GuiOverlay.renderOverlay(self.sliderOverlay, v120_, v121_ + self.endSize[2], self.sliderSize[1], self.sliderSize[2] - self.startSize[2] - self.endSize[2], v119_, clipX1, clipY1, clipX2, clipY2)
				GuiOverlay.renderOverlay(self.endOverlay, v120_, v121_, self.sliderSize[1], self.endSize[2], v119_, clipX1, clipY1, clipX2, clipY2)
			end
		else
			GuiOverlay.renderOverlay(self.sliderOverlay, self.sliderPosition[1], self.sliderPosition[2], self.sliderSize[1], self.sliderSize[2], v119_, clipX1, clipY1, clipX2, clipY2)
		end
	end
	SliderElement:superClass().draw(self, clipX1, clipY1, clipX2, clipY2)
end

-- Local values: dir1, dir2
function SliderElement:shouldFocusChange(direction)
	local v124_ = FocusManager.LEFT
	local v125_ = FocusManager.RIGHT
	if self.direction == SliderElement.DIRECTION_Y then
		v124_ = FocusManager.TOP
		v125_ = FocusManager.BOTTOM
	end
	if direction == v124_ then
		if self.currentValue < self.minValue then
			return true
		end
		self:setValue(self.currentValue - self.stepSize, nil, false)
		self:raiseCallback("onClickCallback", self.currentValue)
		return false
	end
	if direction ~= v125_ then
		return true
	end
	if self.currentValue - self.maxValue > 0.01 then
		return true
	end
	self:setValue(self.currentValue + self.stepSize, nil, false)
	self:raiseCallback("onClickCallback", self.currentValue)
	return false
end

function SliderElement:canReceiveFocus()
	local v127_ = self.handleFocus
	if v127_ then
		v127_ = self.needsSlider
	end
	return v127_
end

function SliderElement:onFocusActivate()
	self:raiseCallback("onClickCallback", self.currentValue)
end

function SliderElement:onScrollUp()
	self:setValue(self.currentValue + self.stepSize, nil, false)
end

function SliderElement:onScrollDown()
	self:setValue(self.currentValue - self.stepSize, nil, false)
end

-- Local values: newCurrentValue, base, contentSize, scrollViewOffsetDelta, size, scrollSteps, viewSize
function SliderElement:onBindUpdate(element)
	if element:isa(ScrollingLayoutElement) then
		self:setMinValue(1)
		self.useStepRounding = true
		local v133_ = element:getViewOffsetPercentage() * (self.maxValue - self.minValue) + self.minValue
		if element:getNeedsScrolling() then
			self:setMaxValue(element.contentSize / element.absSize[2] * 20, v133_)
			self:setSliderSize(element.absSize[2], element.contentSize)
			self.needsSlider = true
		else
			self:setMaxValue(1)
			self:setSliderSize(10, 100)
			self.needsSlider = false
		end
		self:setValue(v133_, true, true)
	elseif element:isa(SmoothListElement) then
		local v134_ = element.lengthAxis == 1 and g_screenWidth or g_screenHeight
		local v135_ = MathUtil.round(element.contentSize * v134_)
		local v136_ = MathUtil.round(element.scrollViewOffsetDelta * v134_)
		local v137_ = MathUtil.round(element.absSize[element.lengthAxis] * v134_)
		local v138_
		if v136_ == 0 then
			v138_ = 0
		else
			local v139_ = (v135_ - v137_) / v136_
			local v140_ = math.ceil(v139_)
			v138_ = math.max(0, v140_) or 0
		end
		self:setMinValue(1)
		self:setMaxValue(v138_ + 1)
		self:setSliderSize(element.absSize[element.lengthAxis], element.contentSize)
		local v141_
		if self.maxValue > self.minValue then
			v141_ = element.contentSize ~= 0
		else
			v141_ = false
		end
		self.needsSlider = v141_
		self:setValue(element:getViewOffsetPercentage() * (self.maxValue - self.minValue) + self.minValue, true, true)
	end
	if self.hideParentWhenEmpty then
		self.parent:setVisible(self.needsSlider)
	end
end

-- Local values: isOut
function SliderElement:isOutOfBound(posX, posY)
	if self.direction == SliderElement.DIRECTION_X then
		return MathUtil.getIsOutOfBounds(posX, self.absPosition[1], self.absPosition[1] + self.absSize[1])
	else
		return MathUtil.getIsOutOfBounds(posY, self.absPosition[2], self.absPosition[2] + self.absSize[2])
	end
end
