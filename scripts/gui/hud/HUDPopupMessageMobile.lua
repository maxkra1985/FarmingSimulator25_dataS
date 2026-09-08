-- Local values: HUDPopupMessageMobile_mt
HUDPopupMessageMobile = {}
local HUDPopupMessageMobile_mt = Class(HUDPopupMessageMobile, HUDDisplayElement)
HUDPopupMessageMobile.INPUT_CONTEXT_NAME = "POPUP_MESSAGE"
HUDPopupMessageMobile.MAX_PENDING_MESSAGE_COUNT = 8
HUDPopupMessageMobile.MAX_INPUT_ROW_COUNT = 8
HUDPopupMessageMobile.MIN_DURATION = 1000
HUDPopupMessageMobile.DURATION_PER_CHARACTER = 80
HUDPopupMessageMobile.MAX_DURATION = 300000

-- Upvalues: HUDPopupMessageMobile_mt
-- Local values: backgroundOverlay, self
function HUDPopupMessageMobile.new(hudAtlasPath, ingameMap)
	-- upvalues: (copy) HUDPopupMessageMobile_mt
	local v4_ = HUDPopupMessageMobile.createBackground(hudAtlasPath)
	local v5_ = HUDPopupMessageMobile:superClass().new(v4_, nil, HUDPopupMessageMobile_mt)
	v5_.ingameMap = ingameMap
	v5_.pendingMessages = {}
	v5_.isCustomInputActive = false
	v5_.lastInputMode = g_inputBinding:getInputHelpMode()
	v5_.inputRows = {}
	v5_.inputGlyphs = {}
	v5_.continueGlyph = nil
	v5_.time = 0
	v5_.isGamePaused = false
	v5_.continueText = g_i18n:getText("introduction_continueTextTouch")
	v5_:storeScaledValues()
	v5_:createComponents(hudAtlasPath)
	return v5_
end

function HUDPopupMessageMobile:delete()
	if self.blurAreaActive then
		g_depthOfFieldManager:popArea()
		self.blurAreaActive = false
	end
	HUDPopupMessageMobile:superClass().delete(self)
end

-- Local values: message, i
function HUDPopupMessageMobile:showMessage(title, text, duration, controls, callback, target)
	if duration == 0 then
		duration = HUDPopupMessageMobile.MIN_DURATION + string.len(text) * HUDPopupMessageMobile.DURATION_PER_CHARACTER
	elseif duration < 0 then
		duration = HUDPopupMessageMobile.MAX_DURATION
	end
	while #self.pendingMessages > HUDPopupMessageMobile.MAX_PENDING_MESSAGE_COUNT do
		table.remove(self.pendingMessages, 1)
	end
	local v14_ = {
		["isDialog"] = false,
		["title"] = title,
		["message"] = text,
		["duration"] = duration,
		["controls"] = Utils.getNoNil(controls, {}),
		["callback"] = callback,
		["target"] = target
	}
	if #v14_.controls > HUDPopupMessageMobile.MAX_INPUT_ROW_COUNT then
		for v15_ = #v14_.controls, HUDPopupMessageMobile.MAX_INPUT_ROW_COUNT + 1, -1 do
			table.remove(v14_.controls, v15_)
		end
	end
	local v16_ = self.pendingMessages
	table.insert(v16_, v14_)
end

function HUDPopupMessageMobile:setPaused(isPaused)
	self.isGamePaused = isPaused
end

function HUDPopupMessageMobile:getVisible()
	local v20_ = HUDPopupMessageMobile:superClass().getVisible(self)
	if v20_ then
		v20_ = self.currentMessage ~= nil
	end
	return v20_
end

function HUDPopupMessageMobile:getHidingTranslation()
	return 0, -self:getHeight() - g_safeFrameOffsetY - 0.01
end

-- Local values: isTouch
function HUDPopupMessageMobile:assignCurrentMessage(message)
	self.time = 0
	self.currentMessage = message
	if g_touchHandler ~= nil then
		g_touchHandler:setCustomContext("guidedTour", true)
		g_touchHandler:registerTouchArea(0, 0, 1, 1, 0, 0, TouchHandler.TRIGGER_UP, self.onConfirmMessage, self)
	end
	local v24_ = g_inputBinding:getInputHelpMode() == GS_INPUT_HELP_MODE_TOUCH
	self.continueGlyph:setVisible(not v24_)
	self:setCurrentMessageHeight()
	self:updateButtonGlyphs()
end

-- Local values: reqHeight
function HUDPopupMessageMobile:setCurrentMessageHeight()
	local v26_ = self:getTitleHeight() + self:getTextHeight() + self:getInputRowsHeight() + self.borderPaddingY * 2 + self.textOffsetY + self.titleTextSize + self.textSize
	if #self.currentMessage.controls > 0 then
		v26_ = v26_ + self.inputRowsOffsetY
	end
	local v27_ = v26_ + self.continueButtonHeight
	local v28_ = self:getWidth()
	local v29_ = self.minHeight
	self:setDimension(v28_, (math.max(v29_, v27_)))
end

-- Local values: height, title, lineHeight, numTitleRows
function HUDPopupMessageMobile:getTitleHeight()
	local v31_
	if self.currentMessage == nil then
		v31_ = 0
	else
		setTextAlignment(RenderText.ALIGN_CENTER)
		setTextBold(false)
		setTextWrapWidth(self:getWidth() - 2 * self.borderPaddingX)
		local v32_ = utf8ToUpper(self.currentMessage.title)
		local v33_, v34_ = getTextHeight(self.titleTextSize, v32_)
		v31_ = v34_ * v33_
		setTextWrapWidth(0)
		setTextAlignment(RenderText.ALIGN_LEFT)
	end
	return v31_
end

-- Local values: height
function HUDPopupMessageMobile:getTextHeight()
	local v36_
	if self.currentMessage == nil then
		v36_ = 0
	else
		setTextAlignment(RenderText.ALIGN_LEFT)
		setTextBold(false)
		setTextWrapWidth(self:getWidth() - 2 * self.borderPaddingX)
		setTextLineHeightScale(HUDPopupMessageMobile.TEXT_LINE_HEIGHT_SCALE)
		v36_ = getTextHeight(self.textSize, self.currentMessage.message)
		setTextWrapWidth(0)
		setTextLineHeightScale(RenderText.DEFAULT_LINE_HEIGHT_SCALE)
	end
	return v36_
end

-- Local values: height
function HUDPopupMessageMobile:getInputRowsHeight()
	return self.currentMessage == nil and 0 or (#self.currentMessage.controls + 1) * self.inputRowHeight
end

function HUDPopupMessageMobile:animateHide()
	HUDPopupMessageMobile:superClass().animateHide(self)
	g_depthOfFieldManager:popArea()
	self.blurAreaActive = false
	self.animation:addCallback(self.finishMessage)
end

function HUDPopupMessageMobile:startMessage()
	self.ingameMap:setAllowToggle(false)
	self.ingameMap:turnSmall()
	self:assignCurrentMessage(self.pendingMessages[1])
	table.remove(self.pendingMessages, 1)
end

function HUDPopupMessageMobile:finishMessage()
	self.ingameMap:setAllowToggle(true)
	if self.currentMessage ~= nil and self.currentMessage.callback ~= nil then
		if self.currentMessage.target == nil then
			self.currentMessage.callback(self)
		else
			self.currentMessage.callback(self.currentMessage.target)
		end
	end
	self.currentMessage = nil
end

-- Local values: inputMode, isTouch
function HUDPopupMessageMobile:update(dt)
	if not g_gui:getIsMenuVisible() then
		HUDPopupMessageMobile:superClass().update(self, dt)
		if not (self.isGamePaused or g_sleepManager:getIsSleeping()) then
			self.time = self.time + dt
			self:updateCurrentMessage()
		end
		if self:getVisible() then
			local v43_ = g_inputBinding:getInputHelpMode()
			if v43_ ~= self.lastInputMode then
				self.lastInputMode = v43_
				self:updateButtonGlyphs()
				local v44_ = v43_ == GS_INPUT_HELP_MODE_TOUCH
				self.continueGlyph:setVisible(not v44_)
			end
		end
	end
end

function HUDPopupMessageMobile:updateCurrentMessage()
	if self.currentMessage == nil then
		if #self.pendingMessages > 0 then
			self:startMessage()
			self:setVisible(true, true)
			self.animation:addCallback(function()
				-- upvalues: (copy) self
				local v46_, v47_ = self:getPosition()
				g_depthOfFieldManager:pushArea(v46_, v47_, self:getWidth(), self:getHeight())
				self.blurAreaActive = true
			end)
		end
	elseif self.time > self.currentMessage.duration then
		self.time = -math.huge
		self:setVisible(false, true)
		return
	end
end

-- Local values: controlIndex, i, rowIndex, inputRowVisible, control
function HUDPopupMessageMobile:updateButtonGlyphs()
	if self.continueGlyph ~= nil then
		self.continueGlyph:setAction(InputAction.SKIP_MESSAGE_BOX, g_i18n:getText(HUDPopupMessageMobile.L10N_SYMBOL.BUTTON_OK), self.continueTextSize, true, false)
	end
	if self.currentMessage ~= nil then
		local v49_ = 1
		for v50_ = 1, HUDPopupMessageMobile.MAX_INPUT_ROW_COUNT do
			local v51_ = HUDPopupMessageMobile.MAX_INPUT_ROW_COUNT - v50_ + 1 <= #self.currentMessage.controls
			self.inputRows[v50_]:setVisible(v51_)
			if v51_ then
				local v52_ = self.currentMessage.controls[v49_]
				self.inputGlyphs[v50_]:setActions(v52_:getActionNames(), "", self.textSize, false, false)
				self.inputGlyphs[v50_]:setKeyboardGlyphColor(HUDPopupMessageMobile.COLOR.INPUT_GLYPH)
				v49_ = v49_ + 1
			end
		end
	end
end

-- Local values: inputBinding, _, eventId
function HUDPopupMessageMobile:setInputActive(isActive)
	local v55_ = g_inputBinding
	if self.isCustomInputActive or not isActive then
		if self.isCustomInputActive and not isActive then
			v55_:removeActionEventsByTarget(self)
			v55_:revertContext(true)
			self.isCustomInputActive = false
		end
	else
		v55_:setContext(HUDPopupMessageMobile.INPUT_CONTEXT_NAME, true, false)
		local _, v56_ = v55_:registerActionEvent(InputAction.MENU_ACCEPT, self, self.onConfirmMessage, false, true, false, true)
		v55_:setActionEventTextVisibility(v56_, false)
		local _, v57_ = v55_:registerActionEvent(InputAction.SKIP_MESSAGE_BOX, self, self.onConfirmMessage, false, true, false, true)
		v55_:setActionEventTextVisibility(v57_, false)
		self.isCustomInputActive = true
	end
end

function HUDPopupMessageMobile:onConfirmMessage(actionName, inputValue)
	if self.animation:getFinished() then
		if g_touchHandler ~= nil then
			g_touchHandler:revertCustomContext()
		end
		self:setVisible(false, true)
	end
end

function HUDPopupMessageMobile:setVisible(isVisible, animate)
	self:setInputActive(isVisible)
	HUDPopupMessageMobile:superClass().setVisible(self, isVisible, animate)
end

-- Local values: baseX, baseY, width, height, textPosY, title, posX, posY, i, inputText, continueX, continueY
function HUDPopupMessageMobile:draw()
	if not g_gui:getIsMenuVisible() and (self:getVisible() and self.currentMessage ~= nil) then
		HUDPopupMessageMobile:superClass().draw(self)
		local v63_, v64_ = self:getPosition()
		local v65_ = self:getWidth()
		local v66_ = self:getHeight()
		local v67_ = setTextColor
		local v68_ = HUDPopupMessageMobile.COLOR.TITLE
		v67_(unpack(v68_))
		setTextBold(true)
		setTextAlignment(RenderText.ALIGN_CENTER)
		setTextWrapWidth(v65_ - 2 * self.borderPaddingX)
		local v69_ = v64_ + v66_ - self.borderPaddingY
		if self.currentMessage.title ~= "" then
			local v70_ = utf8ToUpper(self.currentMessage.title)
			v69_ = v69_ - self.titleTextSize
			renderText(v63_ + v65_ * 0.5, v69_, self.titleTextSize, v70_)
		end
		setTextBold(false)
		local v71_ = setTextColor
		local v72_ = HUDPopupMessageMobile.COLOR.TEXT
		v71_(unpack(v72_))
		setTextAlignment(RenderText.ALIGN_LEFT)
		setTextLineHeightScale(HUDPopupMessageMobile.TEXT_LINE_HEIGHT_SCALE)
		local v73_ = v69_ - self.textSize + self.textOffsetY
		renderText(v63_ + self.borderPaddingX, v73_, self.textSize, self.currentMessage.message)
		local v74_ = v73_ - getTextHeight(self.textSize, self.currentMessage.message)
		local v75_ = setTextColor
		local v76_ = HUDPopupMessageMobile.COLOR.CONTINUE_TEXT
		v75_(unpack(v76_))
		setTextAlignment(RenderText.ALIGN_RIGHT)
		local v77_ = v63_ + v65_ - self.borderPaddingX
		local v78_ = v74_ + self.inputRowsOffsetY - self.inputRowHeight - self.textSize
		for v79_ = 1, #self.currentMessage.controls do
			local v80_ = self.currentMessage.controls[v79_].text
			renderText(v77_ + self.inputRowTextX, v78_ + self.inputRowTextY, self.textSize, v80_)
			v78_ = v78_ - self.inputRowHeight
		end
		setTextAlignment(RenderText.ALIGN_CENTER)
		if g_inputBinding:getInputHelpMode() == GS_INPUT_HELP_MODE_TOUCH then
			local v81_, v82_ = self.continueGlyph:getPosition()
			local v83_ = v81_ + self.continueGlyph.baseWidth / 2
			local v84_ = v82_ + self.continueTextSize / 2
			renderText(v83_, v84_, self.continueTextSize, self.continueText)
		end
		setTextAlignment(RenderText.ALIGN_LEFT)
		setTextWrapWidth(0)
		setTextLineHeightScale(RenderText.DEFAULT_LINE_HEIGHT_SCALE)
	end
end

-- Local values: offX, offY
function HUDPopupMessageMobile.getBackgroundPosition(uiScale)
	local v86_ = getNormalizedScreenValues
	local v87_ = HUDPopupMessageMobile.POSITION.SELF
	local v88_, v89_ = v86_(unpack(v87_))
	return 0.5 + v88_ * uiScale, g_safeFrameOffsetY + v89_ * uiScale
end

-- Local values: posX, posY, width
function HUDPopupMessageMobile:setScale(uiScale)
	HUDPopupMessageMobile:superClass().setScale(self, uiScale)
	self:storeScaledValues()
	local v92_, v93_ = HUDPopupMessageMobile.getBackgroundPosition(uiScale)
	self:setPosition(v92_ - self:getWidth() * 0.5, v93_)
end

function HUDPopupMessageMobile:setDimension(width, height)
	HUDPopupMessageMobile:superClass().setDimension(self, width, height)
end

function HUDPopupMessageMobile:storeScaledValues()
	local v98_, v99_ = self:scalePixelToScreenVector(HUDPopupMessageMobile.SIZE.SELF)
	self.minWidth = v98_
	self.minHeight = v99_
	local v100_, v101_ = self:scalePixelToScreenVector(HUDPopupMessageMobile.POSITION.MESSAGE_TEXT)
	self.textOffsetX = v100_
	self.textOffsetY = v101_
	local v102_, v103_ = self:scalePixelToScreenVector(HUDPopupMessageMobile.POSITION.INPUT_ROWS)
	self.inputRowsOffsetX = v102_
	self.inputRowsOffsetY = v103_
	local v104_, v105_ = self:scalePixelToScreenVector(HUDPopupMessageMobile.POSITION.CONTINUE_BUTTON)
	self.continueButtonOffsetX = v104_
	self.continueButtonOffsetY = v105_
	local v106_, v107_ = self:scalePixelToScreenVector(HUDPopupMessageMobile.SIZE.CONTINUE_BUTTON)
	self.continueButtonWidth = v106_
	self.continueButtonHeight = v107_
	local v108_, v109_ = self:scalePixelToScreenVector(HUDPopupMessageMobile.SIZE.INPUT_ROW)
	self.inputRowWidth = v108_
	self.inputRowHeight = v109_
	local v110_, v111_ = self:scalePixelToScreenVector(HUDPopupMessageMobile.SIZE.BORDER_PADDING)
	self.borderPaddingX = v110_
	self.borderPaddingY = v111_
	local v112_, v113_ = self:scalePixelToScreenVector(HUDPopupMessageMobile.POSITION.INPUT_TEXT)
	self.inputRowTextX = v112_
	self.inputRowTextY = v113_
	self.titleTextSize = self:scalePixelToScreenHeight(HUDPopupMessageMobile.TEXT_SIZE.TITLE)
	self.textSize = self:scalePixelToScreenHeight(HUDPopupMessageMobile.TEXT_SIZE.TEXT)
	self.continueTextSize = self:scalePixelToScreenHeight(HUDPopupMessageMobile.TEXT_SIZE.CONTINUE_TEXT)
end

-- Local values: posX, posY, width, height, overlay
function HUDPopupMessageMobile.createBackground(hudAtlasPath)
	local v115_, v116_ = HUDPopupMessageMobile.getBackgroundPosition(1)
	local v117_ = getNormalizedScreenValues
	local v118_ = HUDPopupMessageMobile.SIZE.SELF
	local v119_, v120_ = v117_(unpack(v118_))
	local v121_ = Overlay.new(hudAtlasPath, v115_ - v119_ * 0.5, v116_, v119_, v120_)
	v121_:setUVs(GuiUtils.getUVs(HUDPopupMessageMobile.UV.BACKGROUND))
	local v122_ = HUDPopupMessageMobile.COLOR.BACKGROUND
	v121_:setColor(unpack(v122_))
	return v121_
end

-- Local values: basePosX, basePosY, baseWidth, _, inputRowHeight, posY, i, buttonRow, inputGlyph, rowIndex, offX, offY, glyphWidth, glyphHeight, continueGlyph
function HUDPopupMessageMobile:createComponents(hudAtlasPath)
	local v125_, v126_ = self:getPosition()
	local v127_ = self:getWidth()
	local _, v128_ = self:scalePixelToScreenVector(HUDPopupMessageMobile.SIZE.INPUT_ROW)
	local v129_ = v126_ + v128_
	for v130_ = 1, HUDPopupMessageMobile.MAX_INPUT_ROW_COUNT do
		local v131_, v132_
		v131_, v132_, v129_ = self:createInputRow(hudAtlasPath, v125_, v129_)
		local v133_ = HUDPopupMessageMobile.MAX_INPUT_ROW_COUNT - v130_ + 1
		self.inputRows[v133_] = v131_
		self.inputGlyphs[v133_] = v132_
		self:addChild(v131_)
	end
	local v134_, v135_ = self:scalePixelToScreenVector(HUDPopupMessageMobile.POSITION.CONTINUE_BUTTON)
	local v136_, v137_ = self:scalePixelToScreenVector(HUDPopupMessageMobile.SIZE.INPUT_GLYPH)
	local v138_ = InputGlyphElement.new(g_inputDisplayManager, v136_, v137_)
	v138_:setPosition(v125_ + (v127_ - v136_) * 0.5 + v134_, v126_ - v135_)
	v138_:setAction(InputAction.SKIP_MESSAGE_BOX, g_i18n:getText(HUDPopupMessageMobile.L10N_SYMBOL.BUTTON_OK), self.continueTextSize, true, false)
	self.continueGlyph = v138_
	self:addChild(v138_)
end

-- Local values: overlay, buttonPanel, rowHeight, glyphWidth, glyphHeight, inputGlyph, offX, offY, glyphX, glyphY, width, height, separator
function HUDPopupMessageMobile:createInputRow(hudAtlasPath, posX, posY)
	local v143_ = Overlay.new(hudAtlasPath, posX, posY, self.inputRowWidth, self.inputRowHeight)
	v143_:setUVs(GuiUtils.getUVs(HUDPopupMessageMobile.UV.BACKGROUND))
	local v144_ = HUDPopupMessageMobile.COLOR.INPUT_ROW
	v143_:setColor(unpack(v144_))
	local v145_ = HUDElement.new(v143_)
	local v146_ = v145_:getHeight()
	local v147_, v148_ = self:scalePixelToScreenVector(HUDPopupMessageMobile.SIZE.INPUT_GLYPH)
	local v149_ = InputGlyphElement.new(g_inputDisplayManager, v147_, v148_)
	local v150_, v151_ = self:scalePixelToScreenVector(HUDPopupMessageMobile.POSITION.INPUT_GLYPH)
	v149_:setPosition(posX + self.borderPaddingX + v150_, posY + (v146_ - v148_) * 0.5 + v151_)
	v145_:addChild(v149_)
	local v152_, v153_ = self:scalePixelToScreenVector(HUDPopupMessageMobile.SIZE.SEPARATOR)
	local v154_ = HUDPopupMessageMobile.SIZE.SEPARATOR[2] / g_screenHeight
	local v155_ = math.max(v153_, v154_)
	local v156_, v157_ = self:scalePixelToScreenVector(HUDPopupMessageMobile.POSITION.SEPARATOR)
	local v158_ = Overlay.new(hudAtlasPath, posX + v156_, posY + v157_, v152_, v155_)
	v158_:setUVs(GuiUtils.getUVs(GameInfoDisplay.UV.SEPARATOR))
	local v159_ = GameInfoDisplay.COLOR.SEPARATOR
	v158_:setColor(unpack(v159_))
	v145_:addChild((HUDElement.new(v158_)))
	return v145_, v149_, posY + v146_
end
HUDPopupMessageMobile.UV = {
	["BACKGROUND"] = {
		8,
		8,
		2,
		2
	}
}
HUDPopupMessageMobile.SIZE = {
	["SELF"] = { 1100, 200 },
	["INPUT_ROW"] = { 1100, 80 },
	["CONTINUE_BUTTON"] = { 60, 60 },
	["BORDER_PADDING"] = { 60, 45 },
	["INPUT_GLYPH"] = { 60, 60 },
	["SEPARATOR"] = { 1100, 1 }
}
HUDPopupMessageMobile.POSITION = {
	["SELF"] = { 0, 200 },
	["MESSAGE_TEXT"] = { 0, -25 },
	["INPUT_ROWS"] = { 0, -20 },
	["CONTINUE_BUTTON"] = { 0, -12 },
	["INPUT_GLYPH"] = { 0, 0 },
	["INPUT_TEXT"] = { 0, 3 },
	["SEPARATOR"] = { 0, 0 }
}
HUDPopupMessageMobile.TEXT_LINE_HEIGHT_SCALE = 1.5
HUDPopupMessageMobile.TEXT_SIZE = {
	["TITLE"] = 40,
	["TEXT"] = 32,
	["CONTINUE_TEXT"] = 35
}
HUDPopupMessageMobile.COLOR = {
	["BACKGROUND"] = {
		0,
		0,
		0,
		0.54
	},
	["INPUT_ROW"] = {
		0.0075,
		0.0075,
		0.0075,
		0
	},
	["SEPARATOR"] = {
		0.0382,
		0.0382,
		0.0382,
		1
	},
	["TITLE"] = {
		1,
		1,
		1,
		1
	},
	["TEXT"] = {
		0.9,
		0.9,
		0.9,
		1
	},
	["CONTINUE_TEXT"] = {
		1,
		1,
		1,
		1
	},
	["INPUT_GLYPH"] = {
		1,
		1,
		1,
		1
	}
}
HUDPopupMessageMobile.L10N_SYMBOL = {
	["BUTTON_OK"] = "button_ok"
}
