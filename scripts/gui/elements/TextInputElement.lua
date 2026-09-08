-- Local values: TextInputElement_mt, localGetClipboard
TextInputElement = {}
local TextInputElement_mt = Class(TextInputElement, ButtonElement)
Gui.registerGuiElement("TextInput", TextInputElement)
TextInputElement.INPUT_CONTEXT_NAME = "TEXT_INPUT"
TextInputElement.inputContextActive = false
TextInputElement.INITIAL_REPEAT_DELAY = 250
TextInputElement.MIN_REPEAT_DELAY = 50
local localGetClipboard = getClipboard or function()
	return ""
end

-- Upvalues: TextInputElement_mt
-- Local values: self
function TextInputElement.new(target, custom_mt)
	-- upvalues: (copy) TextInputElement_mt
	local v5_ = ButtonElement.new(target, custom_mt or TextInputElement_mt)
	v5_.textInputMouseDown = false
	v5_.forcePressed = false
	v5_.isPassword = false
	v5_.displayText = ""
	v5_.cursor = {}
	v5_.cursorBlinkTime = 0
	v5_.cursorBlinkInterval = 400
	v5_.cursorOffset = { 0, 0 }
	v5_.cursorSize = { 0.0016, 0.018 }
	v5_.cursorNeededSize = { v5_.cursorOffset[1] + v5_.cursorSize[1], v5_.cursorOffset[2] + v5_.cursorSize[2] }
	v5_.cursorPosition = 1
	v5_.firstVisibleCharacterPosition = 1
	v5_.lastVisibleCharacterPosition = 1
	v5_.maxCharacters = nil
	v5_.maxInputTextWidth = nil
	v5_.frontDotsText = "..."
	v5_.backDotsText = "..."
	v5_.text = ""
	v5_.useIme = imeIsSupported()
	v5_.preImeText = ""
	v5_.imeActive = false
	v5_.blockTime = 0
	v5_.isReturnDown = false
	v5_.isEscDown = false
	v5_.isCapturingInput = false
	v5_.hadFocusOnCapture = false
	v5_.enterWhenClickOutside = true
	v5_.applyProfanityFilter = nil
	v5_.disallowFocusedHighlight = true
	v5_.imeKeyboardType = "normal"
	v5_.forceFocus = true
	v5_.customFocusSample = GuiSoundPlayer.SOUND_SAMPLES.TEXTBOX
	return v5_
end

function TextInputElement:delete()
	self:abortIme()
	GuiOverlay.deleteOverlay(self.cursor)
	TextInputElement:superClass().delete(self)
end

function TextInputElement:translate(str)
	if str then
		str = g_i18n:convertText(str)
	end
	return str
end

function TextInputElement:loadFromXML(xmlFile, key)
	TextInputElement:superClass().loadFromXML(self, xmlFile, key)
	self:addCallback(xmlFile, key .. "#onEnter", "onEnterCallback")
	self:addCallback(xmlFile, key .. "#onTextChanged", "onTextChangedCallback")
	self:addCallback(xmlFile, key .. "#onEnterPressed", "onEnterPressedCallback")
	self:addCallback(xmlFile, key .. "#onEscPressed", "onEscPressedCallback")
	self:addCallback(xmlFile, key .. "#onIsUnicodeAllowed", "onIsUnicodeAllowedCallback")
	self.imeKeyboardType = getXMLString(xmlFile, key .. "#imeKeyboardType") or self.imeKeyboardType
	self.imeTitle = self:translate(getXMLString(xmlFile, key .. "#imeTitle"))
	self.imeDescription = self:translate(getXMLString(xmlFile, key .. "#imeDescription"))
	self.imePlaceholder = self:translate(getXMLString(xmlFile, key .. "#imePlaceholder"))
	self.maxCharacters = getXMLInt(xmlFile, key .. "#maxCharacters") or self.maxCharacters
	self.maxInputTextWidth = GuiUtils.getNormalizedXValue(getXMLString(xmlFile, key .. "#maxInputTextWidth"), self.maxInputTextWidth)
	self.cursorOffset = GuiUtils.getNormalizedScreenValues(getXMLString(xmlFile, key .. "#cursorOffset"), self.cursorOffset)
	self.cursorSize = GuiUtils.getNormalizedScreenValues(getXMLString(xmlFile, key .. "#cursorSize"), self.cursorSize)
	if g_screenWidth > 1 then
		local v11_ = self.cursorSize
		local v12_ = self.cursorSize[1]
		local v13_ = g_pixelSizeX
		v11_[1] = math.max(v12_, v13_)
	end
	self.enterWhenClickOutside = Utils.getNoNil(getXMLBool(xmlFile, key .. "#enterWhenClickOutside"), self.enterWhenClickOutside)
	self.applyProfanityFilter = Utils.getNoNil(getXMLBool(xmlFile, key .. "#applyProfanityFilter"), self.applyProfanityFilter)
	GuiOverlay.loadOverlay(self, self.cursor, "cursor", self.imageSize, nil, xmlFile, key)
	GuiOverlay.createOverlay(self.cursor)
	self.isPassword = Utils.getNoNil(getXMLBool(xmlFile, key .. "#isPassword"), self.isPassword)
	self:finalize()
end

function TextInputElement:loadProfile(profile, applyProfile)
	TextInputElement:superClass().loadProfile(self, profile, applyProfile)
	self.maxCharacters = profile:getNumber("maxCharacters", self.maxCharacters)
	self.maxInputTextWidth = GuiUtils.getNormalizedXValue(profile:getValue("maxInputTextWidth"), self.maxInputTextWidth)
	self.cursorOffset = GuiUtils.getNormalizedScreenValues(profile:getValue("cursorOffset"), self.cursorOffset)
	self.cursorSize = GuiUtils.getNormalizedScreenValues(profile:getValue("cursorSize"), self.cursorSize)
	self.isPassword = profile:getBool("isPassword", self.isPassword)
	self.cursorImageSize = GuiUtils.getNormalizedValues(profile:getValue("cursorImageSize"), self.outputSize, self.imageSize)
	self.applyProfanityFilter = profile:getBool("applyProfanityFilter", self.applyProfanityFilter)
	GuiOverlay.loadOverlay(self, self.cursor, "cursor", self.cursorImageSize, profile, nil, nil)
	if g_screenWidth > 1 then
		local v17_ = self.cursorSize
		local v18_ = self.cursorSize[1]
		local v19_ = g_pixelSizeX
		v17_[1] = math.max(v18_, v19_)
	end
	self:finalize()
end

function TextInputElement:copyAttributes(src)
	TextInputElement:superClass().copyAttributes(self, src)
	self.imeKeyboardType = src.imeKeyboardType
	self.imeTitle = src.imeTitle
	self.imeDescription = src.imeDescription
	self.imePlaceholder = src.imePlaceholder
	self.maxCharacters = src.maxCharacters
	self.maxInputTextWidth = src.maxInputTextWidth
	GuiOverlay.copyOverlay(self.cursor, src.cursor)
	self.cursorOffset = table.clone(src.cursorOffset)
	self.cursorSize = table.clone(src.cursorSize)
	self.isPassword = src.isPassword
	self.onEnterCallback = src.onEnterCallback
	self.onTextChangedCallback = src.onTextChangedCallback
	self.onEnterPressedCallback = src.onEnterPressedCallback
	self.onEscPressedCallback = src.onEscPressedCallback
	self.onIsUnicodeAllowedCallback = src.onIsUnicodeAllowedCallback
	self.enterWhenClickOutside = src.enterWhenClickOutside
	self.applyProfanityFilter = src.applyProfanityFilter
	self:finalize()
end

function TextInputElement:finalize()
	self.cursorNeededSize = { self.cursorOffset[1] + self.cursorSize[1], self.cursorOffset[2] + self.cursorSize[2] }
	if not self.maxInputTextWidth and (self.textAlignment == RenderText.ALIGN_CENTER or self.textAlignment == RenderText.ALIGN_RIGHT) then
		Logging.error("TextInputElement loading using \"center\" or \"right\" alignment requires specification of \"maxInputTextWidth\"")
	end
	if self.maxInputTextWidth and self.maxInputTextWidth <= getTextWidth(self.textSize, self.frontDotsText) + self.cursorNeededSize[1] + getTextWidth(self.textSize, self.backDotsText) then
		Logging.warning("TextInputElement loading specified \"maxInputTextWidth\" is too small (%.4f) to display needed data", self.maxInputTextWidth)
	end
end

function TextInputElement:getIsActive()
	return GuiElement.getIsActive(self)
end

-- Local values: baseText, filteredText
function TextInputElement:setCaptureInput(isCapturing)
	self.blockTime = 200
	if self.isCapturingInput or not isCapturing then
		if self.isCapturingInput and not isCapturing then
			if TextInputElement.inputContextActive then
				g_inputBinding:revertContext(true)
				TextInputElement.inputContextActive = false
			end
			self.target:disableInputForDuration(200)
			self.isCapturingInput = false
			if not self.isPassword and self.applyProfanityFilter ~= false then
				local v26_ = self.text
				local v27_ = filterText(v26_, true, true)
				if v26_ ~= "" and v26_ ~= v27_ then
					self:setText(v27_)
				end
			end
		end
	else
		self.isReturnDown = false
		self.isEscDown = false
		self.target:disableInputForDuration(0)
		if TextInputElement.inputContextActive then
			g_inputBinding:revertContext(true)
		end
		g_inputBinding:setContext(TextInputElement.INPUT_CONTEXT_NAME, true, false)
		TextInputElement.inputContextActive = true
		if not GS_IS_CONSOLE_VERSION then
			g_inputBinding:registerActionEvent(InputAction.MENU_BACK, self, self.inputEvent, false, true, false, true)
			g_inputBinding:registerActionEvent(InputAction.MENU_ACCEPT, self, self.inputEvent, false, true, false, true)
		end
		self.isCapturingInput = true
	end
end

function TextInputElement:setAlpha(alpha)
	TextInputElement:superClass().setAlpha(self, alpha)
	if self.cursor ~= nil then
		self.cursor.alpha = self.alpha
	end
end

function TextInputElement:getDoRenderText()
	return false
end

function TextInputElement:reset()
	TextInputElement:superClass().reset(self)
	if self.isRepeatingSpecialKeyDown then
		self:stopSpecialKeyRepeating()
	end
end

-- Local values: textLength
function TextInputElement:setText(text)
	local v33_ = utf8Strlen(text)
	if self.maxCharacters and self.maxCharacters < v33_ then
		text = utf8Substr(text, 0, self.maxCharacters)
		v33_ = utf8Strlen(text)
	end
	TextInputElement:superClass().setText(self, text)
	self.cursorPosition = v33_ + 1
	self:updateVisibleTextElements()
end

function TextInputElement:setForcePressed(force)
	if force then
		self.hadFocusOnCapture = self:getIsFocused()
		self:setCaptureInput(true)
	else
		self:setCaptureInput(false)
	end
	self.forcePressed = force
	if self.forcePressed then
		FocusManager:setFocus(self)
	else
		if self.hadFocusOnCapture then
			FocusManager:setFocus(self)
			TextInputElement:superClass().onFocusEnter(self)
		else
			self:setFocused(false)
			TextInputElement:superClass().onFocusLeave(self)
		end
		self.hadFocusOnCapture = false
	end
	if self.isRepeatingSpecialKeyDown then
		self:stopSpecialKeyRepeating()
	end
	self:updateVisibleTextElements()
end

function TextInputElement:getIsUnicodeAllowed(unicode)
	if unicode == 13 or unicode == 10 then
		return false
	elseif getCanRenderUnicode(unicode) then
		return Utils.getNoNil(self:raiseCallback("onIsUnicodeAllowedCallback", unicode), true)
	else
		return false
	end
end

-- Local values: isCursorInside
function TextInputElement:mouseEvent(posX, posY, isDown, isUp, button, eventUsed)
	if self:getIsActive() then
		local v45_ = GuiUtils.checkOverlayOverlap(posX, posY, self.absPosition[1], self.absPosition[2], self.size[1], self.size[2])
		if self.forcePressed then
			if not v45_ and (isUp and button == Input.MOUSE_BUTTON_LEFT) then
				self:setForcePressed(false)
				if self.enterWhenClickOutside then
					self:abortIme()
					self:raiseCallback("onEnterPressedCallback", self, true)
				end
			end
		elseif eventUsed or (not v45_ or FocusManager:isLocked()) then
			if isDown and button == Input.MOUSE_BUTTON_LEFT or (self.textInputMouseDown or not self.forcePressed) then
				FocusManager:unsetHighlight(self)
			end
			self.textInputMouseDown = false
		else
			FocusManager:setHighlight(self)
			eventUsed = true
			if isDown and button == Input.MOUSE_BUTTON_LEFT then
				self.textInputMouseDown = true
				if not self.useIme then
					self:setForcePressed(true)
				end
			end
			if isUp and (button == Input.MOUSE_BUTTON_LEFT and self.textInputMouseDown) then
				self.textInputMouseDown = false
				self:setForcePressed(true)
				if self.useIme then
					self:openIme()
				end
			end
		end
		eventUsed = eventUsed or TextInputElement:superClass().mouseEvent(self, posX, posY, isDown, isUp, button, eventUsed)
	end
	return eventUsed
end

-- Local values: textBeforeCursor, lastSpacePos
function TextInputElement:moveCursorLeft(isLeftCtrlPressed)
	if isLeftCtrlPressed then
		local v48_ = utf8Substr(self:getText(), 0, self.cursorPosition - 1)
		local v49_ = string.rtrim(v48_)
		local v50_ = string.findLast(v49_, " ")
		if v50_ == nil then
			self:setCursorPosition(1)
		else
			self:setCursorPosition(v50_ + 1)
		end
	else
		self:setCursorPosition(self.cursorPosition - 1)
		return
	end
end

-- Local values: nextSpacePos, nextNonSpacePos
function TextInputElement:moveCursorRight(isLeftCtrlPressed)
	if isLeftCtrlPressed then
		local v53_ = string.find(self:getText(), " ", self.cursorPosition)
		local v54_ = v53_ == nil and math.huge or (string.find(self:getText(), "%w", v53_) or math.huge)
		if v54_ ~= nil then
			self:setCursorPosition(v54_)
			return
		end
	end
	self:setCursorPosition(self.cursorPosition + 1)
end

function TextInputElement:setCursorPosition(position)
	local v57_ = utf8Strlen(self.text) + 1
	local v58_ = math.min(v57_, position)
	self.cursorPosition = math.max(1, v58_)
end

-- Local values: textLength, canDelete, deleteOffset
function TextInputElement:deleteText(deleteRightCharacterFromCursor)
	local v61_ = utf8Strlen(self.text)
	if v61_ > 0 then
		local v62_ = false
		local v63_ = nil
		if deleteRightCharacterFromCursor then
			if self.cursorPosition <= v61_ then
				v62_ = true
				v63_ = 0
			end
		elseif self.cursorPosition > 1 then
			v62_ = true
			v63_ = -1
		end
		if v62_ then
			self.text = (self.cursorPosition + v63_ > 1 and (utf8Substr(self.text, 0, self.cursorPosition + v63_ - 1) or "") or "") .. (self.cursorPosition + v63_ < v61_ and (utf8Substr(self.text, self.cursorPosition + v63_, -1) or "") or "")
			self.cursorPosition = self.cursorPosition + v63_
			self:raiseCallback("onTextChangedCallback", self, self.text)
		end
	end
end

function TextInputElement:stopSpecialKeyRepeating()
	self.isRepeatingSpecialKeyDown = false
	self.repeatingSpecialKeySym = nil
	self.repeatingSpecialKeyDelayTime = nil
	self.repeatingSpecialKeyRemainingDelayTime = nil
end

function TextInputElement:onPauseChanged(isPaused)
	if isPaused then
		self:abortIme()
	end
end

function TextInputElement:openIme()
	if not (self.useIme and imeOpen(self.text, self.imeTitle or "", self.imeDescription or "", self.imePlaceholder or "", self.imeKeyboardType or "normal", Utils.getNoNil(self.maxCharacters, 512), self.absPosition[1], self.absPosition[2], self.size[1], self.size[2])) then
		return false
	end
	self.imeActive = true
	self.preImeText = self.text
	g_messageCenter:subscribe(MessageType.PAUSE, self.onPauseChanged, self)
	return true
end

function TextInputElement:abortIme()
	if self.useIme and self.imeActive then
		self.imeActive = false
		self.preImeText = ""
		imeAbort()
		g_messageCenter:unsubscribe(MessageType.PAUSE, self)
	end
end

-- Upvalues: localGetClipboard
-- Local values: wasSpecialKey, lctrlModifier, startSpecialKeyRepeating, textLeftOfCursor, textRightOfCursor, text, lastSpacePos, newText, cursorPosition, clipboardText, textLength
function TextInputElement:keyEvent(unicode, sym, modifier, isDown, eventUsed)
	-- upvalues: (copy) localGetClipboard
	local v75_ = TextInputElement:superClass().keyEvent(self, unicode, sym, modifier, isDown, eventUsed) and true or eventUsed
	if self.isRepeatingSpecialKeyDown and (not isDown and self.repeatingSpecialKeySym == sym) then
		self:stopSpecialKeyRepeating()
	end
	if self.blockTime <= 0 and (self:getIsActive() and self.forcePressed) then
		local v76_ = false
		if isDown then
			local v77_ = Input.MOD_LCTRL
			if GS_PLATFORM_ID == PlatformId.MAC then
				v77_ = Input.MOD_LMETA
			end
			local v78_ = false
			if sym == Input.KEY_left then
				self:moveCursorLeft(bit32.band(modifier, v77_) > 0)
				v78_ = true
				v76_ = true
			elseif sym == Input.KEY_right then
				self:moveCursorRight(bit32.band(modifier, v77_) > 0)
				v78_ = true
				v76_ = true
			elseif sym == Input.KEY_home then
				self.cursorPosition = 1
				v76_ = true
			elseif sym == Input.KEY_end then
				self.cursorPosition = utf8Strlen(self.text) + 1
				v76_ = true
			elseif sym == Input.KEY_delete then
				self:deleteText(true)
				v78_ = true
				v76_ = true
			elseif sym == Input.KEY_backspace then
				if bit32.band(modifier, v77_) > 0 then
					if self.isPassword then
						self:setText("")
						v78_ = true
						v76_ = true
					else
						local v79_ = utf8Substr(self:getText(), 0, self.cursorPosition - 1) or ""
						local v80_ = utf8Substr(self:getText(), self.cursorPosition - 1) or ""
						local v81_ = string.rtrim(v79_)
						local v82_ = string.findLast(v81_, " ")
						local v83_ = utf8Substr(v81_, 0, v82_)
						local v84_ = self.cursorPosition
						self:setText(v83_ .. v80_)
						self.cursorPosition = v84_ - (utf8Strlen(v79_) - utf8Strlen(v83_))
						self:raiseCallback("onTextChangedCallback", self, self.text)
						v78_ = true
						v76_ = true
					end
				else
					self:deleteText(false)
					v78_ = true
					v76_ = true
				end
			elseif sym == Input.KEY_esc then
				self.isEscDown = true
				v76_ = true
			elseif sym == Input.KEY_return or sym == Input.KEY_KP_enter then
				self.isReturnDown = true
				v76_ = true
			elseif sym == Input.KEY_v and bit32.band(modifier, v77_) > 0 then
				local v85_ = localGetClipboard()
				self:setText(self:getText() .. v85_)
				v76_ = true
			end
			if v78_ then
				self.isRepeatingSpecialKeyDown = true
				self.repeatingSpecialKeySym = sym
				self.repeatingSpecialKeyDelayTime = TextInputElement.INITIAL_REPEAT_DELAY
				self.repeatingSpecialKeyRemainingDelayTime = self.repeatingSpecialKeyDelayTime
			end
			if not v76_ and self:getIsUnicodeAllowed(unicode) then
				local v86_ = utf8Strlen(self.text)
				if self.maxCharacters == nil or v86_ < self.maxCharacters then
					self.text = (self.cursorPosition > 1 and (utf8Substr(self.text, 0, self.cursorPosition - 1) or "") or "") .. unicodeToUtf8(unicode) .. (self.cursorPosition <= v86_ and (utf8Substr(self.text, self.cursorPosition - 1) or "") or "")
					self.cursorPosition = self.cursorPosition + 1
					self:raiseCallback("onTextChangedCallback", self, self.text)
				end
			end
			self:updateVisibleTextElements()
			v75_ = true
		else
			if (sym == Input.KEY_return or sym == Input.KEY_KP_enter) and self.isReturnDown then
				self.isReturnDown = false
				self:setForcePressed(not self.forcePressed)
				self:raiseCallback("onEnterPressedCallback", self)
				return v75_
			end
			if sym == Input.KEY_esc then
				self.isEscDown = false
				self:setForcePressed(not self.forcePressed)
				self:raiseCallback("onEscPressedCallback", self)
				return v75_
			end
		end
	end
	return v75_
end

function TextInputElement:inputEvent(action, value, eventUsed)
	if self.blockTime <= 0 and (not self.imeActive and (self:getIsActive() and self.forcePressed)) then
		if action == InputAction.MENU_ACCEPT then
			if self.forcePressed then
				self:setForcePressed(false)
			else
				self:setForcePressed(true)
			end
			self:raiseCallback("onEnterPressedCallback", self)
			return true
		end
		if action == InputAction.MENU_CANCEL or action == InputAction.MENU_BACK then
			if self.forcePressed then
				self:setForcePressed(false)
			else
				self:setForcePressed(true)
			end
			self:raiseCallback("onEscPressedCallback", self)
			eventUsed = true
		end
	end
	return eventUsed
end

-- Local values: done, cancel
function TextInputElement:update(dt)
	TextInputElement:superClass().update(self, dt)
	self.cursorBlinkTime = self.cursorBlinkTime + dt
	while self.cursorBlinkTime > 2 * self.cursorBlinkInterval do
		self.cursorBlinkTime = self.cursorBlinkTime - 2 * self.cursorBlinkInterval
	end
	if self.isRepeatingSpecialKeyDown then
		self.repeatingSpecialKeyRemainingDelayTime = self.repeatingSpecialKeyRemainingDelayTime - dt
		if self.repeatingSpecialKeyRemainingDelayTime <= 0 then
			if self.repeatingSpecialKeySym == Input.KEY_left then
				self:moveCursorLeft()
			elseif self.repeatingSpecialKeySym == Input.KEY_right then
				self:moveCursorRight()
			elseif self.repeatingSpecialKeySym == Input.KEY_delete then
				self:deleteText(true)
			elseif self.repeatingSpecialKeySym == Input.KEY_backspace then
				self:deleteText(false)
			end
			self:updateVisibleTextElements()
			local v92_ = TextInputElement.MIN_REPEAT_DELAY
			local v93_ = (self.repeatingSpecialKeyDelayTime or TextInputElement.INITIAL_REPEAT_DELAY) * 0.1 ^ (dt / 100)
			self.repeatingSpecialKeyDelayTime = math.max(v92_, v93_)
			self.repeatingSpecialKeyRemainingDelayTime = self.repeatingSpecialKeyDelayTime
		end
	end
	if self.useIme and self.imeActive then
		local v94_, v95_ = imeIsComplete()
		if v94_ then
			self.imeActive = false
			self:setForcePressed(false)
			if v95_ then
				self:setText(self.preImeText)
				self.preImeText = ""
				self:raiseCallback("onEscPressedCallback", self)
			else
				self:setText(imeGetLastString())
				self:raiseCallback("onEnterPressedCallback", self)
			end
		else
			self:setText(imeGetLastString())
			self:setCursorPosition(imeGetCursorPos() + 1)
			self:updateVisibleTextElements()
		end
	end
	if self.blockTime > 0 then
		self.blockTime = self.blockTime - dt
	end
end

-- Local values: text, neededWidth, textXPos, _, yOffset, _, yPos, textYPos, displacementX, additionalDisplacement, additionalDisplacement, additionalDisplacement, additionalDisplacement
function TextInputElement:draw(clipX1, clipY1, clipX2, clipY2)
	local v101_ = self.text
	self.text = ""
	TextInputElement:superClass().draw(self, clipX1, clipY1, clipX2, clipY2)
	self.text = v101_
	setTextAlignment(self.textAlignment)
	local v102_ = self:getNeededTextWidth()
	local v103_ = self.absPosition[1] + self.textOffset[1]
	if self.textAlignment == RenderText.ALIGN_CENTER then
		v103_ = v103_ + self.maxInputTextWidth * 0.5 - v102_ * 0.5
	elseif self.textAlignment == RenderText.ALIGN_RIGHT then
		v103_ = v103_ + self.maxInputTextWidth - v102_
	end
	local v104_ = v103_ + (self.size[1] - self.maxInputTextWidth) / 2
	local _, v105_ = self:getTextOffset()
	local _, v106_ = self:getTextPosition(self.text)
	local v107_ = v106_ + v105_
	if clipX1 ~= nil then
		setTextClipArea(clipX1, clipY1, clipX2, clipY2)
	end
	local v108_ = 0
	if self.areFrontDotsVisible then
		v108_ = v108_ + self:drawTextPart(self.frontDotsText, v104_, v108_, v107_)
	end
	if self.isVisibleTextPart1Visible then
		v108_ = v108_ + self:drawTextPart(self.visibleTextPart1, v104_, v108_, v107_)
	end
	if self.isCursorVisible then
		v108_ = v108_ + self:drawCursor(v104_, v108_, v107_)
	end
	if self.isVisibleTextPart2Visible then
		v108_ = v108_ + self:drawTextPart(self.visibleTextPart2, v104_, v108_, v107_)
	end
	if self.areBackDotsVisible then
		self:drawTextPart(self.backDotsText, v104_, v108_, v107_)
	end
	setTextBold(false)
	setTextAlignment(RenderText.ALIGN_LEFT)
	setTextColor(1, 1, 1, 1)
	if clipX1 ~= nil then
		setTextClipArea(0, 0, 1, 1)
	end
end

function TextInputElement:shouldFocusChange(direction)
	return not self.forcePressed
end

function TextInputElement:onFocusLeave()
	self:abortIme()
	self:setForcePressed(false)
	TextInputElement:superClass().onFocusLeave(self)
end

function TextInputElement:onFocusActivate()
	if self.blockTime <= 0 then
		TextInputElement:superClass().onFocusActivate(self)
		self:raiseCallback("onEnterCallback", self)
		if self.forcePressed then
			self:abortIme()
			self:setForcePressed(false)
			self:raiseCallback("onEnterPressedCallback", self)
			return
		end
		self:openIme()
		self:setForcePressed(true)
	end
end

function TextInputElement:onClose()
	TextInputElement:superClass().onClose(self)
	self:abortIme()
	self:setForcePressed(false)
end

-- Local values: textWidth, alignmentDisplacement
function TextInputElement:drawTextPart(text, textXPos, displacementX, textYPos)
	local v118_
	if text == "" then
		v118_ = 0
	else
		setTextBold(self.textBold)
		v118_ = getTextWidth(self.textSize, text)
		local v119_ = 0
		if self.textAlignment == RenderText.ALIGN_CENTER then
			v119_ = v118_ * 0.5
		elseif self.textAlignment == RenderText.ALIGN_RIGHT then
			v119_ = v118_
		end
		if self.text2Size > 0 then
			setTextBold(self.text2Bold)
			setTextColor(unpack(self:getText2Color()))
			renderText(textXPos + v119_ + displacementX + (self.text2Offset[1] - self.textOffset[1]), textYPos + (self.text2Offset[2] - self.textOffset[2]), self.text2Size, text)
		end
		setTextBold(self.textBold)
		setTextColor(unpack(self:getTextColor()))
		renderText(textXPos + v119_ + displacementX, textYPos, self.textSize, text)
	end
	return v118_
end

-- Local values: x
function TextInputElement:drawCursor(textXPos, displacementX, textYPos)
	if self.cursorBlinkTime < self.cursorBlinkInterval then
		local v124_ = (textXPos + displacementX + self.cursorOffset[1]) / g_pixelSizeX
		local v125_ = math.floor(v124_) * g_pixelSizeX
		GuiOverlay.renderOverlay(self.cursor, v125_, textYPos + self.cursorOffset[2], self.cursorSize[1], self.cursorSize[2])
	end
	return self.cursorNeededSize[1]
end

-- Local values: displayText, textLength, availableTextWidth, textInvisibleFrontTrimmed, textWidthInvisibleFrontTrimmed, visibleText, visibleTextWidth, visibleTextLength, textTrimmedAtCursor, lastCharacterPosition, nextCharacter, additionalCharacterWidth, availableWidthWithoutFrontDots, neededWidthForCompleteText, textWidth
function TextInputElement:updateVisibleTextElements()
	self.isCursorVisible = false
	self.isVisibleTextPart1Visible = false
	self.visibleTextPart1 = ""
	self.isVisibleTextPart2Visible = false
	self.visibleTextPart2 = ""
	self.areFrontDotsVisible = false
	self.areBackDotsVisible = false
	self.firstVisibleCharacterPosition = 1
	setTextBold(self.textBold)
	local v127_ = self.text
	if self.isPassword then
		v127_ = string.rep("*", utf8Strlen(self.text))
	end
	local v128_ = utf8Strlen(v127_)
	local v129_ = self:getAvailableTextWidth()
	if self:getIsActive() and self.forcePressed then
		self.isCursorVisible = true
		if self.cursorPosition < self.firstVisibleCharacterPosition then
			self.firstVisibleCharacterPosition = self.cursorPosition
		end
		if self.firstVisibleCharacterPosition > 1 then
			self.areFrontDotsVisible = true
		end
		local v130_ = utf8Substr(v127_, self.firstVisibleCharacterPosition - 1)
		local v131_ = getTextWidth(self.textSize, v130_)
		local v132_ = self:getAvailableTextWidth()
		if v132_ and (v132_ < v131_ and self.cursorPosition <= v128_) then
			self.areBackDotsVisible = true
			v132_ = self:getAvailableTextWidth()
		end
		local v133_ = TextInputElement.limitTextToAvailableWidth(v130_, self.textSize, v132_)
		local v134_ = getTextWidth(self.textSize, v133_)
		local v135_ = utf8Strlen(v133_)
		if v132_ and self.cursorPosition > self.firstVisibleCharacterPosition + v135_ then
			self.areFrontDotsVisible = true
			v132_ = self:getAvailableTextWidth()
			local v136_ = utf8Substr(v130_, 0, self.cursorPosition - self.firstVisibleCharacterPosition)
			v133_ = TextInputElement.limitTextToAvailableWidth(v136_, self.textSize, v132_, true)
			v134_ = getTextWidth(self.textSize, v133_)
			v135_ = utf8Strlen(v133_)
			self.firstVisibleCharacterPosition = self.cursorPosition - v135_
		end
		if v132_ and (not self.areBackDotsVisible and self.firstVisibleCharacterPosition > 1) then
			local v137_ = v135_ + self.firstVisibleCharacterPosition
			local v138_ = utf8Substr(v127_, self.firstVisibleCharacterPosition - 1, 1) or ""
			local v139_ = getTextWidth(self.textSize, v138_)
			if v134_ + v139_ <= v132_ and self.firstVisibleCharacterPosition > 1 then
				while v134_ + v139_ <= v132_ and self.firstVisibleCharacterPosition > 1 do
					self.firstVisibleCharacterPosition = self.firstVisibleCharacterPosition - 1
					v134_ = v134_ + v139_
					local v140_ = utf8Substr(v127_, self.firstVisibleCharacterPosition - 1, 1) or ""
					v139_ = getTextWidth(self.textSize, v140_)
				end
				if self.firstVisibleCharacterPosition > 1 then
					self.areFrontDotsVisible = false
					local v141_ = self:getAvailableTextWidth()
					self.areFrontDotsVisible = true
					if getTextWidth(self.textSize, v127_) <= v141_ then
						self.areFrontDotsVisible = false
						self.firstVisibleCharacterPosition = 1
					end
				else
					self.areFrontDotsVisible = false
				end
				v133_ = utf8Substr(v127_, self.firstVisibleCharacterPosition - 1, v137_)
			end
		end
		self.isVisibleTextPart1Visible = true
		self.visibleTextPart1 = utf8Substr(v133_, 0, self.cursorPosition - self.firstVisibleCharacterPosition)
		if self.cursorPosition - self.firstVisibleCharacterPosition < v135_ then
			self.isVisibleTextPart2Visible = true
			self.visibleTextPart2 = utf8Substr(v133_, self.cursorPosition - self.firstVisibleCharacterPosition)
		end
	else
		local v142_ = getTextWidth(self.textSize, v127_)
		if v129_ and v129_ < v142_ then
			self.areBackDotsVisible = true
			v129_ = self:getAvailableTextWidth()
		end
		if v129_ and v129_ < v142_ then
			self.visibleTextPart1 = TextInputElement.limitTextToAvailableWidth(v127_, self.textSize, v129_)
			self.isVisibleTextPart1Visible = true
		else
			self.visibleTextPart1 = v127_
			self.isVisibleTextPart1Visible = true
		end
	end
	setTextBold(false)
end

-- Local values: resultingText, indexOfFirstCharacter, indexOfLastCharacter, textLength
function TextInputElement.limitTextToAvailableWidth(text, textSize, availableWidth, trimFront)
	local v147_ = 0
	local v148_ = utf8Strlen(text)
	if availableWidth then
		if trimFront then
			while availableWidth < getTextWidth(textSize, text) do
				text = utf8Substr(text, 1)
				v147_ = v147_ + 1
			end
		else
			local v149_ = utf8Strlen(text)
			while availableWidth < getTextWidth(textSize, text) do
				v149_ = v149_ - 1
				text = utf8Substr(text, 0, v149_)
				v148_ = v148_ - 1
			end
		end
	end
	return text, v147_, v148_
end

-- Local values: availableTextWidth
function TextInputElement:getAvailableTextWidth()
	if not self.maxInputTextWidth then
		return nil
	end
	local v151_ = self.maxInputTextWidth
	if self.areFrontDotsVisible then
		v151_ = v151_ - getTextWidth(self.textSize, self.frontDotsText)
	end
	if self.isCursorVisible then
		v151_ = v151_ - self.cursorNeededSize[1]
	end
	if self.areBackDotsVisible then
		v151_ = v151_ - getTextWidth(self.textSize, self.backDotsText)
	end
	return v151_
end

-- Local values: neededWidth
function TextInputElement:getNeededTextWidth()
	local v153_ = 0
	if self.areFrontDotsVisible then
		v153_ = v153_ + getTextWidth(self.textSize, self.frontDotsText)
	end
	if self.isVisibleTextPart1Visible then
		v153_ = v153_ + getTextWidth(self.textSize, self.visibleTextPart1)
	end
	if self.isCursorVisible then
		v153_ = v153_ + self.cursorNeededSize[1]
	end
	if self.isVisibleTextPart2Visible then
		v153_ = v153_ + getTextWidth(self.textSize, self.visibleTextPart2)
	end
	if self.areBackDotsVisible then
		v153_ = v153_ + getTextWidth(self.textSize, self.backDotsText)
	end
	return v153_
end

function TextInputElement:getText()
	return self.text
end

function TextInputElement:updateAbsolutePosition()
	self.sourceText = self.text
	TextInputElement:superClass().updateAbsolutePosition(self)
end
