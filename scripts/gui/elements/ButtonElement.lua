-- Local values: ButtonElement_mt
ButtonElement = {}
local ButtonElement_mt = Class(ButtonElement, TextElement)
Gui.registerGuiElement("Button", ButtonElement)
Gui.registerGuiElementProcFunction("Button", Gui.assignPlaySampleCallback)

-- Upvalues: ButtonElement_mt
-- Local values: self
function ButtonElement.new(target, custom_mt)
	-- upvalues: (copy) ButtonElement_mt
	local v4_ = TextElement.new(target, custom_mt or ButtonElement_mt)
	v4_:include(PlaySampleMixin)
	v4_.inputDown = false
	v4_.forceFocus = false
	v4_.overlay = {}
	v4_.icon = {}
	v4_.touchIcon = {}
	v4_.iconSize = { 0, 0 }
	v4_.touchIconSize = { 0, 0 }
	v4_.gamepadIconSize = { getNormalizedScreenValues(60, 60) }
	v4_.iconTextOffset = { 0, 0 }
	v4_.focusedTextOffset = { 0, 0 }
	v4_.needExternalClick = false
	v4_.clickSoundName = GuiSoundPlayer.SOUND_SAMPLES.CLICK
	v4_.fitToContent = false
	v4_.fitExtraWidth = 0
	v4_.hideKeyboardGlyph = false
	v4_.isTouchButton = false
	v4_.isTouchButtonWithBg = false
	v4_.gamepadUsesTouchButton = false
	v4_.addTouchArea = true
	v4_.isTriggerableByGlobalAction = true
	v4_.ignorePressedOverlayState = false
	v4_.pressed = false
	v4_.sendActionOnRelease = true
	v4_.textAlignment = RenderText.ALIGN_CENTER
	v4_.textSeparator = nil
	v4_.inputActionName = nil
	v4_.hasLoadedInputGlyph = false
	v4_.isKeyboardMode = false
	v4_.keyDisplayText = nil
	v4_.keyOverlay = nil
	v4_.keyGlyphOffsetX = 0
	v4_.keyGlyphSize = { 0, 0 }
	v4_.iconColors = {
		["color"] = {
			1,
			1,
			1,
			1
		}
	}
	v4_.iconImageSize = { 2048, 2048 }
	v4_.drawChildrenLast = false
	return v4_
end

function ButtonElement:delete()
	GuiOverlay.deleteOverlay(self.touchIcon)
	GuiOverlay.deleteOverlay(self.overlay)
	GuiOverlay.deleteOverlay(self.icon)
	ButtonElement:superClass().delete(self)
end

-- Local values: inputActionName, sampleName, resolvedSampleName
function ButtonElement:loadFromXML(xmlFile, key)
	ButtonElement:superClass().loadFromXML(self, xmlFile, key)
	self:addCallback(xmlFile, key .. "#onClick", "onClickCallback")
	self:addCallback(xmlFile, key .. "#onFocus", "onFocusCallback")
	self:addCallback(xmlFile, key .. "#onLeave", "onLeaveCallback")
	self:addCallback(xmlFile, key .. "#onHighlight", "onHighlightCallback")
	self:addCallback(xmlFile, key .. "#onHighlightRemove", "onHighlightRemoveCallback")
	self:addCallback(xmlFile, key .. "#onSizeChanged", "onSizeChangedCallback")
	GuiOverlay.loadOverlay(self, self.overlay, "image", self.imageSize, nil, xmlFile, key)
	self.iconSize = GuiUtils.getNormalizedScreenValues(getXMLString(xmlFile, key .. "#iconSize"), self.iconSize)
	self.touchIconSize = GuiUtils.getNormalizedScreenValues(getXMLString(xmlFile, key .. "#touchIconSize"), self.touchIconSize)
	self.gamepadIconSize = GuiUtils.getNormalizedScreenValues(getXMLString(xmlFile, key .. "#gamepadIconSize"), self.gamepadIconSize)
	self.iconTextOffset = GuiUtils.getNormalizedScreenValues(getXMLString(xmlFile, key .. "#iconTextOffset"), self.iconTextOffset)
	self.forceFocus = Utils.getNoNil(getXMLBool(xmlFile, key .. "#forceFocus"), self.forceFocus)
	self.needExternalClick = Utils.getNoNil(getXMLBool(xmlFile, key .. "#needExternalClick"), self.needExternalClick)
	self.fitToContent = Utils.getNoNil(getXMLBool(xmlFile, key .. "#fitToContent"), self.fitToContent)
	self.fitExtraWidth = GuiUtils.getNormalizedXValue(getXMLString(xmlFile, key .. "#fitExtraWidth"), self.fitExtraWidth)
	self.hideKeyboardGlyph = Utils.getNoNil(getXMLBool(xmlFile, key .. "#hideKeyboardGlyph"), self.hideKeyboardGlyph)
	self.isTouchButton = Utils.getNoNil(getXMLBool(xmlFile, key .. "#isTouchButton"), self.isTouchButton)
	self.isTouchButtonWithBg = Utils.getNoNil(getXMLBool(xmlFile, key .. "#isTouchButtonWithBg"), self.isTouchButtonWithBg)
	self.gamepadUsesTouchButton = Utils.getNoNil(getXMLBool(xmlFile, key .. "#gamepadUsesTouchButton"), self.gamepadUsesTouchButton)
	self.addTouchArea = Utils.getNoNil(getXMLBool(xmlFile, key .. "#addTouchArea"), self.addTouchArea)
	self.touchAreaColor = GuiUtils.getColorArray(getXMLString(xmlFile, key .. "#touchAreaColor"), self.touchAreaColor)
	self.isTriggerableByGlobalAction = Utils.getNoNil(getXMLBool(xmlFile, key .. "#isTriggerableByGlobalAction"), self.isTriggerableByGlobalAction)
	self.ignorePressedOverlayState = Utils.getNoNil(getXMLBool(xmlFile, key .. "#ignorePressedOverlayState"), self.ignorePressedOverlayState)
	self.sendActionOnRelease = Utils.getNoNil(getXMLBool(xmlFile, key .. "#sendActionOnRelease"), self.sendActionOnRelease)
	self.textSeparator = Utils.getNoNil(getXMLString(xmlFile, key .. "#textSeparator"), self.textSeparator)
	self.drawChildrenLast = Utils.getNoNil(getXMLBool(xmlFile, key .. "#drawChildrenLast"), self.drawChildrenLast)
	local v9_ = getXMLString(xmlFile, key .. "#inputAction")
	if v9_ == nil or InputAction[v9_] == nil then
		self.iconImageSize = string.getVector(getXMLString(xmlFile, key .. "#iconImageSize"), 2) or self.iconImageSize
		GuiOverlay.loadOverlay(self, self.icon, "icon", self.iconImageSize, nil, xmlFile, key)
		GuiOverlay.createOverlay(self.icon)
	else
		self.inputActionName = v9_
		self:loadInputGlyphColors(nil, xmlFile, key)
	end
	if (self.isTouchButton or (self.isTouchButtonWithBg or self.gamepadUsesTouchButton)) and Platform.isMobile then
		GuiOverlay.loadOverlay(self, self.touchIcon, "touchIcon", self.imageSize, nil, xmlFile, key)
		GuiOverlay.createOverlay(self.touchIcon)
	end
	local v10_ = getXMLString(xmlFile, key .. "#clickSound") or self.clickSoundName
	local v11_ = GuiSoundPlayer.SOUND_SAMPLES[v10_]
	if v11_ ~= nil then
		self.clickSoundName = v11_
	end
	GuiOverlay.createOverlay(self.overlay)
	self:updateSize()
end

-- Local values: inputActionName, iconImageSizeStr, sampleName, resolvedSampleName
function ButtonElement:loadProfile(profile, applyProfile)
	ButtonElement:superClass().loadProfile(self, profile, applyProfile)
	GuiOverlay.loadOverlay(self, self.overlay, "image", self.imageSize, profile, nil, nil)
	local v15_ = profile:getValue("inputAction", self.inputActionName)
	if v15_ == nil or InputAction[v15_] == nil then
		local v16_ = profile:getValue("iconImageSize")
		if not string.isNilOrWhitespace(v16_) then
			self.iconImageSize = string.getVector(v16_, 2)
		end
		GuiOverlay.loadOverlay(self, self.icon, "icon", self.iconImageSize, profile, nil, nil)
		GuiOverlay.createOverlay(self.icon)
	else
		self.inputActionName = v15_
		self:loadInputGlyphColors(profile, nil, nil)
	end
	if (self.isTouchButton or (self.isTouchButtonWithBg or self.gamepadUsesTouchButton)) and Platform.isMobile then
		GuiOverlay.loadOverlay(self, self.touchIcon, "touchIcon", self.imageSize, profile, nil, nil)
		GuiOverlay.createOverlay(self.touchIcon)
	end
	self.iconSize = GuiUtils.getNormalizedScreenValues(profile:getValue("iconSize"), self.iconSize)
	self.touchIconSize = GuiUtils.getNormalizedScreenValues(profile:getValue("touchIconSize"), self.touchIconSize)
	self.gamepadIconSize = GuiUtils.getNormalizedScreenValues(profile:getValue("gamepadIconSize"), self.gamepadIconSize)
	self.iconTextOffset = GuiUtils.getNormalizedScreenValues(profile:getValue("iconTextOffset"), self.iconTextOffset)
	self.forceFocus = profile:getBool("forceFocus", self.forceFocus)
	self.needExternalClick = profile:getBool("needExternalClick", self.needExternalClick)
	self.fitToContent = profile:getBool("fitToContent", self.fitToContent)
	self.fitExtraWidth = GuiUtils.getNormalizedXValue(profile:getValue("fitExtraWidth"), self.fitExtraWidth)
	self.hideKeyboardGlyph = profile:getBool("hideKeyboardGlyph", self.hideKeyboardGlyph)
	self.isTouchButton = profile:getBool("isTouchButton", self.isTouchButton)
	self.isTouchButtonWithBg = profile:getBool("isTouchButtonWithBg", self.isTouchButtonWithBg)
	self.gamepadUsesTouchButton = profile:getBool("gamepadUsesTouchButton", self.gamepadUsesTouchButton)
	self.addTouchArea = profile:getBool("addTouchArea", self.addTouchArea)
	self.touchAreaColor = GuiUtils.getColorArray(profile:getValue("touchAreaColor"))
	self.isTriggerableByGlobalAction = profile:getBool("isTriggerableByGlobalAction", self.isTriggerableByGlobalAction)
	self.ignorePressedOverlayState = profile:getBool("ignorePressedOverlayState", self.ignorePressedOverlayState)
	self.sendActionOnRelease = profile:getBool("sendActionOnRelease", self.sendActionOnRelease)
	self.textSeparator = profile:getValue("textSeparator", self.textSeparator)
	self.drawChildrenLast = profile:getBool("drawChildrenLast", self.drawChildrenLast)
	local v17_ = profile:getValue("clickSound", self.clickSoundName)
	local v18_ = GuiSoundPlayer.SOUND_SAMPLES[v17_]
	if v18_ ~= nil then
		self.clickSoundName = v18_
	end
	GuiOverlay.createOverlay(self.overlay)
	if applyProfile then
		self:updateSize()
	end
end

function ButtonElement:copyAttributes(src)
	ButtonElement:superClass().copyAttributes(self, src)
	GuiOverlay.copyOverlay(self.overlay, src.overlay)
	GuiOverlay.copyOverlay(self.icon, src.icon)
	if (src.isTouchButton or (src.isTouchButtonWithBg or self.gamepadUsesTouchButton)) and Platform.isMobile then
		GuiOverlay.copyOverlay(self.touchIcon, src.touchIcon)
		self.touchIconSize = table.clone(src.touchIconSize)
		self.gamepadIconSize = table.clone(src.gamepadIconSize)
	end
	self.iconSize = table.clone(src.iconSize)
	self.iconTextOffset = table.clone(src.iconTextOffset)
	self.forceFocus = src.forceFocus
	self.needExternalClick = src.needExternalClick
	self.inputActionName = src.inputActionName
	self.clickSoundName = src.clickSoundName
	self.hideKeyboardGlyph = src.hideKeyboardGlyph
	self.fitExtraWidth = src.fitExtraWidth
	self.fitToContent = src.fitToContent
	self.isTouchButton = src.isTouchButton
	self.isTouchButtonWithBg = src.isTouchButtonWithBg
	self.gamepadUsesTouchButton = src.gamepadUsesTouchButton
	self.addTouchArea = src.addTouchArea
	self.touchAreaColor = src.touchAreaColor
	self.isTriggerableByGlobalAction = src.isTriggerableByGlobalAction
	self.ignorePressedOverlayState = src.ignorePressedOverlayState
	self.sendActionOnRelease = src.sendActionOnRelease
	self.textSeparator = src.textSeparator
	self.drawChildrenLast = src.drawChildrenLast
	self.iconColors = src.iconColors
	self.pressed = src.pressed
	self.onClickCallback = src.onClickCallback
	self.onLeaveCallback = src.onLeaveCallback
	self.onFocusCallback = src.onFocusCallback
	self.onHighlightCallback = src.onHighlightCallback
	self.onHighlightRemoveCallback = src.onHighlightRemoveCallback
	self.onSizeChangedCallback = src.onSizeChangedCallback
	GuiMixin.cloneMixin(PlaySampleMixin, src, self)
end

function ButtonElement:loadInputGlyphColors(profile, xmlFile, key)
	if xmlFile == nil then
		if profile ~= nil then
			GuiOverlay.loadProfileColors(profile, self.icon, "icon")
			GuiOverlay.loadProfileColors(profile, self.iconColors, "iconBg")
		end
	else
		GuiOverlay.loadXMLColors(xmlFile, key, self.icon, "icon")
		GuiOverlay.loadXMLColors(xmlFile, key, self.iconColors, "iconBg")
	end
end

-- Local values: overlay, keyText, refWidth, newWidth, dynOffset
function ButtonElement:loadInputGlyph(force)
	if not self.icon.filename or force then
		local v27_ = g_inputDisplayManager:getGamepadInputActionOverlay(self.inputActionName, Binding.AXIS_COMPONENT.POSITIVE)
		if v27_ ~= nil then
			GuiOverlay.copyColors(v27_, self.icon)
			GuiOverlay.deleteOverlay(self.icon)
			self.icon = v27_
			self.hasLoadedInputGlyph = true
		end
	end
	if not (GS_IS_CONSOLE_VERSION or GS_IS_MOBILE_VERSION) then
		local v28_ = g_inputDisplayManager:getKeyboardInputActionKey(self.inputActionName, Binding.AXIS_COMPONENT.POSITIVE)
		if v28_ ~= nil then
			self.keyDisplayText = v28_
			self.keyOverlay = g_inputDisplayManager:getKeyboardKeyOverlay()
			local v29_ = self.iconSize[1]
			local v30_ = self.keyOverlay:getButtonWidth(v28_, self.iconSize[2])
			self.keyGlyphSize = { v30_, self.iconSize[2] }
			self.keyGlyphOffsetX = v30_ - v29_
		end
	end
end

-- Local values: didChange
function ButtonElement:setInputMode(isKeyboardMode, isTouchMode, isGamepadMode)
	local v35_
	if self.isKeyboardMode == isKeyboardMode then
		v35_ = false
	else
		self.isKeyboardMode = isKeyboardMode
		v35_ = true
		if not self.hasLoadedInputGlyph then
			self:loadInputGlyph()
		end
	end
	if self.isGamepadMode ~= isGamepadMode then
		self.isGamepadMode = isGamepadMode
		v35_ = true
		if not self.hasLoadedInputGlyph then
			self:loadInputGlyph()
		end
	end
	if self.isTouchMode ~= isTouchMode and (self.isTouchButton or self.isTouchButtonWithBg) then
		self.isTouchMode = isTouchMode
		v35_ = true
	end
	if v35_ then
		self:updateSize()
	end
end

function ButtonElement:setAlpha(alpha)
	ButtonElement:superClass().setAlpha(self, alpha)
	if self.overlay ~= nil then
		self.overlay.alpha = self.alpha
	end
	if self.icon ~= nil then
		self.icon.alpha = self.alpha
	end
end

function ButtonElement:setDisabled(disabled)
	ButtonElement:superClass().setDisabled(self, disabled)
	if disabled then
		FocusManager:unsetFocus(self)
		self.inputEntered = false
		self:raiseCallback("onLeaveCallback", self)
		self.inputDown = false
	end
end

function ButtonElement:setInputAction(inputActionName)
	if inputActionName ~= nil and InputAction[inputActionName] ~= nil then
		self.inputActionName = inputActionName
		self:loadInputGlyph(true)
	end
end

function ButtonElement:onOpen()
	ButtonElement:superClass().onOpen(self)
	if self.inputActionName ~= nil then
		self.hasLoadedInputGlyph = false
		self:loadInputGlyph(true)
	end
end

function ButtonElement:onClose()
	ButtonElement:superClass().onClose(self)
	self:reset()
end

function ButtonElement:reset()
	ButtonElement:superClass().reset(self)
	self:setPressed(false)
	self:setFocused(false)
	self:setHighlighted(false)
	self.inputDown = false
end

function ButtonElement:setImageFilename(filename, iconFilename)
	if filename ~= nil then
		self.overlay = GuiOverlay.createOverlay(self.overlay, filename)
	end
	if iconFilename ~= nil then
		self.icon = GuiOverlay.createOverlay(self.icon, iconFilename)
	end
end

function ButtonElement:setImageUVs(backgroundUVs, iconUVs)
	if backgroundUVs ~= nil then
		self.overlay.uvs = backgroundUVs
	end
	if iconUVs ~= nil then
		self.icon.uvs = iconUVs
	end
end

-- Local values: backgroundSlice, iconSlice, backgroundUVs, backgroundFilename, iconUVs, iconFilename
function ButtonElement:setImageSlice(backgroundSliceId, iconSliceId)
	local v54_ = g_overlayManager:getSliceInfoById(backgroundSliceId)
	local v55_ = g_overlayManager:getSliceInfoById(iconSliceId)
	local v56_
	if v54_ == nil then
		v56_ = nil
	else
		v56_ = v54_.uvs or nil
	end
	local v57_
	if v54_ == nil then
		v57_ = nil
	else
		v57_ = v54_.filename or nil
	end
	local v58_
	if v55_ == nil then
		v58_ = nil
	else
		v58_ = v55_.uvs or nil
	end
	local v59_
	if v55_ == nil then
		v59_ = nil
	else
		v59_ = v55_.filename or nil
	end
	self:setImageUVs(v56_, v58_)
	self:setImageFilename(v57_, v59_)
end

-- Local values: baseActive
function ButtonElement:getIsActive()
	local v61_ = ButtonElement:superClass().getIsActive(self)
	if v61_ then
		v61_ = self.onClickCallback ~= nil
	end
	return v61_
end

-- Local values: clickInElement
function ButtonElement:mouseEvent(posX, posY, isDown, isUp, button, eventUsed)
	if self:getIsActive() then
		eventUsed = eventUsed or ButtonElement:superClass().mouseEvent(self, posX, posY, isDown, isUp, button, eventUsed)
		local v69_ = GuiUtils.checkOverlayOverlap(posX, posY, self.absPosition[1], self.absPosition[2], self.size[1], self.size[2], self.hotspot)
		if v69_ then
			if not self.inputEntered then
				if self.handleFocus and not self:getIsHighlighted() then
					FocusManager:setHighlight(self)
				end
				self.inputEntered = true
			end
		else
			self.inputDown = false
			self.inputEntered = false
			if self:getIsHighlighted() and (self.parent == nil or not self.parent:getIsHighlighted()) then
				FocusManager:unsetHighlight(self)
			end
		end
		if not eventUsed and (v69_ and not FocusManager:isLocked()) then
			if isDown and button == Input.MOUSE_BUTTON_LEFT then
				if self.handleFocus and not self.forceFocus then
					FocusManager:setFocus(self)
					eventUsed = true
					if not self.sendActionOnRelease then
						self:sendAction()
					end
				end
				self.inputDown = true
			end
			if isUp and (button == Input.MOUSE_BUTTON_LEFT and self.inputDown) then
				if self.sendActionOnRelease then
					self:sendAction()
					eventUsed = true
				else
					eventUsed = true
				end
			end
			if self.inputDown then
				self:setPressed(true)
			end
		end
	end
	if isUp then
		self.inputDown = false
		self:setPressed(false)
	end
	return eventUsed
end

-- Local values: clickInElement
function ButtonElement:touchEvent(posX, posY, isDown, isUp, touchId, eventUsed)
	if self:getIsActive() then
		eventUsed = eventUsed or ButtonElement:superClass().touchEvent(self, posX, posY, isDown, isUp, touchId, eventUsed)
		local v77_ = GuiUtils.checkOverlayOverlap(posX, posY, self.absPosition[1], self.absPosition[2], self.size[1], self.size[2], self.hotspot)
		if v77_ then
			if not self.inputEntered then
				if self.handleFocus and not self:getIsHighlighted() then
					FocusManager:setHighlight(self)
				end
				self.inputEntered = true
			end
		else
			self.inputDown = false
			self.inputEntered = false
			if self:getIsHighlighted() and (self.parent == nil or not self.parent:getIsHighlighted()) then
				FocusManager:unsetHighlight(self)
			end
		end
		if not eventUsed and (v77_ and not FocusManager:isLocked()) then
			if isDown then
				if self.handleFocus and not self.forceFocus then
					FocusManager:setFocus(self)
					eventUsed = true
					if not self.sendActionOnRelease then
						self:sendAction()
					end
				end
				self.inputDown = true
			end
			if isUp and self.inputDown then
				if self.sendActionOnRelease then
					self:sendAction()
					eventUsed = true
				else
					eventUsed = true
				end
			end
			if self.inputDown then
				self:setPressed(true)
			end
		end
	end
	if isUp then
		self.inputDown = false
		self:setPressed(false)
	end
	return eventUsed
end

function ButtonElement:keyEvent(unicode, sym, modifier, isDown, eventUsed)
	if self:getIsActive() then
		return ButtonElement:superClass().keyEvent(self, unicode, sym, modifier, isDown, eventUsed)
	else
		return false
	end
end

-- Local values: iconSizeX, iconSizeY, xOffset, yOffset
function ButtonElement:getIconOffset(textWidth, textHeight)
	local v87_, v88_ = self:getIconSize()
	local v89_ = self.iconTextOffset[1]
	local v90_ = self.iconTextOffset[2]
	if self.textAlignment == RenderText.ALIGN_LEFT then
		v89_ = v89_ - v87_
	elseif self.textAlignment == RenderText.ALIGN_CENTER then
		v89_ = v89_ - textWidth * 0.5 - v87_
	elseif self.textAlignment == RenderText.ALIGN_RIGHT then
		v89_ = v89_ - textWidth - v87_
	end
	if self.textVerticalAlignment == TextElement.VERTICAL_ALIGNMENT.TOP then
		return v89_, v90_ - textHeight
	end
	if self.textVerticalAlignment == TextElement.VERTICAL_ALIGNMENT.MIDDLE then
		v90_ = v90_ + (textHeight - v88_) * 0.5
	end
	return v89_, v90_
end

-- Local values: overlayState, lastInputMode, xPos, yPos, textOffsetX, textOffsetY, xOffset, yOffset, iconXPos, iconYPos, iconSizeX, iconSizeY, textColor, bgColor, r, g, b, a, r2, g2, b2, a2, r, g, b, a, icon, iconSize, touchIconYPos, posX1, posX2, posY1, posY2
function ButtonElement:draw(clipX1, clipY1, clipX2, clipY2)
	if not self.drawChildrenLast then
		ButtonElement:superClass().draw(self, clipX1, clipY1, clipX2, clipY2)
	end
	local v96_ = self:getOverlayState()
	local v97_ = g_inputBinding:getInputHelpMode()
	local v98_
	if self.keyDisplayText == nil then
		v98_ = false
	else
		v98_ = g_inputBinding:getInputHelpMode() == GS_INPUT_HELP_MODE_KEYBOARD
	end
	local v99_ = ((not self.isTouchButton or v97_ ~= GS_INPUT_HELP_MODE_TOUCH) and true or false) and self.gamepadUsesTouchButton
	if v99_ then
		if v97_ == GS_INPUT_HELP_MODE_GAMEPAD then
			v99_ = Platform.isMobile
		else
			v99_ = false
		end
	end
	self:setInputMode(v98_, v99_, g_inputBinding:getInputHelpMode() == GS_INPUT_HELP_MODE_GAMEPAD)
	GuiOverlay.renderOverlay(self.overlay, self.absPosition[1], self.absPosition[2], self.size[1], self.size[2], v96_, clipX1, clipY1, clipX2, clipY2)
	local v100_, v101_ = self:getTextPosition(self.text)
	local v102_, v103_ = self:getTextOffset()
	local v104_, v105_ = self:getIconOffset(self:getTextWidth(), getTextHeight(self.textSize, self.text))
	local v106_ = v100_ + v102_ + v104_
	local v107_ = v101_ + v103_ + v105_
	local v108_, v109_ = self:getIconSize()
	if self.keyDisplayText == nil or not self.isKeyboardMode then
		if self.isTouchMode then
			if self.addTouchArea then
				local v110_, v111_, v112_, v113_
				if self.touchAreaColor == nil then
					v110_ = 1
					v111_ = 1
					v112_ = 1
					v113_ = 1
				else
					v112_ = self.touchAreaColor[1]
					v110_ = self.touchAreaColor[2]
					v113_ = self.touchAreaColor[3]
					v111_ = self.touchAreaColor[4]
				end
				drawTouchButton(self.absPosition[1], self.absPosition[2] + self.absSize[2] / 2, self.absSize[1], v96_ == GuiOverlay.STATE_PRESSED, self.isTouchButtonWithBg, v112_, v110_, v113_, v111_, clipX1, clipY1, clipX2, clipY2)
			end
			local v114_ = self.touchIcon
			local v115_ = self.touchIconSize
			if self.isGamepadMode then
				v114_ = self.icon
				v106_ = v106_ - self.gamepadIconSize[1] * 0.25
				v115_ = self.gamepadIconSize
			end
			if v114_ ~= nil then
				local v116_ = self.absPosition[2] + self.absSize[2] / 2 - v115_[2] / 2
				GuiOverlay.renderOverlay(v114_, v106_, v116_, v115_[1], v115_[2], v96_, clipX1, clipY1, clipX2, clipY2)
			end
		else
			GuiOverlay.renderOverlay(self.icon, v106_, v107_, v108_, v109_, v96_, clipX1, clipY1, clipX2, clipY2)
		end
	elseif not self.hideKeyboardGlyph then
		local v117_ = GuiOverlay.getOverlayColor(self.icon, v96_)
		local v118_ = GuiOverlay.getOverlayColor(self.iconColors, v96_)
		local v119_, v120_, v121_, v122_ = unpack(v117_)
		local v123_, v124_, v125_, v126_ = unpack(v118_)
		self.keyOverlay:setColor(v119_, v120_, v121_, v122_, v123_, v124_, v125_, v126_)
		self.keyOverlay:renderButton(self.keyDisplayText, v106_, v107_, v109_, true, clipX1, clipY1, clipX2, clipY2)
	end
	if self.debugEnabled or g_uiDebugEnabled then
		local v127_ = self.absPosition[1]
		local v128_ = self.absPosition[1] + self.size[1] - g_pixelSizeX
		local v129_ = self.absPosition[2]
		local v130_ = self.absPosition[2] + self.size[2] - g_pixelSizeY
		drawFilledRect(v127_, v129_, v128_ - v127_, g_pixelSizeY, 0, 1, 0, 0.7)
		drawFilledRect(v127_, v130_, v128_ - v127_, g_pixelSizeY, 0, 1, 0, 0.7)
		drawFilledRect(v127_, v129_, g_pixelSizeX, v130_ - v129_, 0, 1, 0, 0.7)
		drawFilledRect(v127_ + v128_ - v127_, v129_, g_pixelSizeX, v130_ - v129_, 0, 1, 0, 0.7)
	end
	if self.drawChildrenLast then
		ButtonElement:superClass().draw(self, clipX1, clipY1, clipX2, clipY2)
	end
end

-- Local values: xOffset, yOffset, iconWidth, _
function ButtonElement:getIconModifiedTextOffset(textOffsetX, textOffsetY)
	local v134_, _ = self:getIconSize()
	if self.textAlignment == RenderText.ALIGN_LEFT then
		return textOffsetX - self.iconTextOffset[1] + v134_, textOffsetY
	end
	if self.textAlignment == RenderText.ALIGN_CENTER then
		textOffsetX = textOffsetX + (v134_ - self.iconTextOffset[1]) * 0.5
	end
	return textOffsetX, textOffsetY
end

-- Local values: xOffset, yOffset
function ButtonElement:getTextOffset()
	local v136_, v137_ = ButtonElement:superClass().getTextOffset(self)
	if self.isTouchMode and self.addTouchArea then
		v136_ = v136_ + 0.020833333333333332
	end
	return self:getIconModifiedTextOffset(v136_, v137_)
end

-- Local values: xOffset, yOffset
function ButtonElement:getText2Offset()
	local v139_, v140_ = ButtonElement:superClass().getText2Offset(self)
	return self:getIconModifiedTextOffset(v139_, v140_)
end

function ButtonElement:getIconSize()
	if self.isKeyboardMode then
		return self.keyGlyphSize[1], self.keyGlyphSize[2]
	else
		return self.iconSize[1], self.iconSize[2]
	end
end

function ButtonElement:setIconSize(x, y)
	self.iconSize[1] = Utils.getNoNil(x, self.iconSize[1])
	self.iconSize[2] = Utils.getNoNil(y, self.iconSize[2])
	self:updateSize()
end

function ButtonElement:canReceiveFocus()
	local v146_ = not self.disabled and self:getIsVisible() and true or false
	if v146_ then
		v146_ = self:getHandleFocus()
	end
	return v146_
end

function ButtonElement:onFocusLeave()
	ButtonElement:superClass().onFocusLeave(self)
	self:raiseCallback("onLeaveCallback", self)
end

function ButtonElement:onFocusEnter()
	ButtonElement:superClass().onFocusEnter(self)
	self:raiseCallback("onFocusCallback", self)
end

function ButtonElement:onHighlight()
	ButtonElement:superClass().onHighlight(self)
	self:raiseCallback("onHighlightCallback", self)
end

function ButtonElement:onHighlightRemove()
	ButtonElement:superClass().onHighlightRemove(self)
	self:raiseCallback("onHighlightRemoveCallback", self)
end

function ButtonElement:onFocusActivate()
	if self:getIsActive() then
		self:sendAction()
	end
end

-- Local values: _, child
function ButtonElement:setPressed(pressed)
	self.pressed = pressed
	if self.updateChildrenState then
		for _, v154_ in pairs(self.elements) do
			if v154_.setPressed ~= nil then
				v154_:setPressed(pressed)
			end
		end
	end
end

function ButtonElement:getIsPressed()
	return self.pressed
end

function ButtonElement:getOverlayState()
	if self:getIsDisabled() then
		return GuiOverlay.STATE_DISABLED
	elseif self:getIsPressed() and not self.ignorePressedOverlayState then
		return GuiOverlay.STATE_PRESSED
	elseif self:getIsSelected() then
		return GuiOverlay.STATE_SELECTED
	elseif self:getIsFocused() then
		return GuiOverlay.STATE_FOCUSED
	elseif self:getIsHighlighted() then
		return GuiOverlay.STATE_HIGHLIGHTED
	else
		return GuiOverlay.STATE_NORMAL
	end
end

-- Local values: width, height, needsCallbackRaised, textHeight, _, iconWidth, iconHeight, textWidth
function ButtonElement:updateSize(forceTextSize)
	local v159_ = false
	local v160_, _ = self:getTextHeight()
	local v161_, v162_ = self:getIconSize()
	local v163_, v164_
	if (self.fitToContent or self.textAutoWidth) and not forceTextSize then
		setTextBold(self.textBold)
		local v165_ = getTextWidth(self.textSize, self.sourceText) + 0.001
		setTextBold(false)
		v163_ = v161_ + v165_ + self.fitExtraWidth
		if (self.isTouchButton or (self.isTouchButtonWithBg or self.gamepadUsesTouchButton)) and (self.isTouchMode and self.addTouchArea) then
			v163_ = v163_ + 0.030208333333333334
			v164_ = 0.09375
			if self.originalHeight == nil then
				v159_ = true
			else
				self.originalHeight = self.size[2]
				v159_ = true
			end
		else
			v164_ = self.originalHeight
			self.originalHeight = nil
		end
	else
		v163_ = nil
		v164_ = nil
	end
	if (self.fitToContent or self.textAutoHeight) and not forceTextSize then
		v164_ = math.max(v160_, v162_)
	end
	if v163_ ~= nil and not MathUtil.equalEpsilon(v163_, self.absSize[1]) or v164_ ~= nil and not MathUtil.equalEpsilon(v164_, self.absSize[2]) then
		self:setSize(v163_, v164_)
		if v159_ then
			self:raiseCallback("onSizeChangedCallback", self)
		end
		if self.parent ~= nil and (self.parent.invalidateLayout ~= nil and self.parent.autoValidateLayout) then
			self.parent:invalidateLayout()
		end
	end
end

function ButtonElement:setText(text, forceTextSize, isInitializing, forceScrollingParameterUpdate)
	if self.textSeparator ~= nil then
		text = self.textSeparator .. text
	end
	ButtonElement:superClass().setText(self, text, forceTextSize, isInitializing, forceScrollingParameterUpdate)
	self:updateSize()
end

function ButtonElement:setTextSize(size)
	ButtonElement:superClass().setTextSize(self, size)
	self:updateSize()
end

function ButtonElement:setClickSound(soundName)
	self.clickSoundName = soundName
end

-- Local values: eventUsed
function ButtonElement:sendAction()
	local v176_ = not self:raiseCallback("onClickCallback", self)
	if not self.soundDisabled and v176_ then
		self:playSample(self.clickSoundName)
	end
end
