-- Local values: data, old, IngameMessage_mt, ingameMessage, _, m
local v1_
if IngameMessage == nil then
	v1_ = nil
else
	local v2_ = g_currentMission.hud.ingameMessage
	v1_ = {
		["uiScale"] = v2_.uiScale,
		["isVisible"] = v2_:getVisible(),
		["pendingMessages"] = v2_.pendingMessages
	}
	if v2_.currentMessage ~= nil then
		v2_:stopMessage()
	end
	v2_:delete()
end
IngameMessage = {}
IngameMessage.MIN_DURATION = 1000
IngameMessage.DURATION_PER_CHARACTER = 80
IngameMessage.MAX_DURATION = 300000
IngameMessage.INPUT_CONTEXT_NAME = "IngameMessage"
local data = Class(IngameMessage, HUDDisplay)

-- Upvalues: IngameMessage_mt
-- Local values: self
function IngameMessage.new(customMt)
	-- upvalues: (copy) data
	local v4_ = IngameMessage:superClass().new(data)
	v4_.pendingMessages = {}
	v4_.isCustomInputActive = false
	v4_.lastInputMode = g_inputBinding:getInputHelpMode()
	v4_.glyphButtonOverlay = GlyphButtonOverlay.new()
	v4_.glyphButtonOverlay:setColor(0.22323, 0.40724, 0.0036, 1, 0, 0, 0, 0.8)
	v4_.keyButtonOverlay = ButtonOverlay.new()
	v4_.keyButtonOverlay:setColor(0.22323, 0.40724, 0.00368, 1, 0, 0, 0, 0.8)
	v4_.skipText = g_i18n:getText("button_ok")
	v4_.skipControl = nil
	v4_.isGamePaused = false
	v4_.nextMessageTimer = -1
	return v4_
end

function IngameMessage:delete()
	self.glyphButtonOverlay:delete()
	self.keyButtonOverlay:delete()
end

-- Local values: offsetX, offsetY, posX, posY
function IngameMessage:storeScaledValues()
	local v7_, v8_ = self:scalePixelValuesToScreenVector(0, 0)
	self:setPosition(0.5 + v7_, g_hudAnchorBottom + v8_)
	self.width = self:scalePixelToScreenWidth(640)
	self.skipTextSize = self:scalePixelToScreenHeight(17)
	local v9_, v10_ = self:scalePixelValuesToScreenVector(5, 22)
	self.skipTextOffsetX = v9_
	self.skipTextOffsetY = v10_
	self.skipButtonOffsetY = self:scalePixelToScreenHeight(12)
	self.skipHeight = self:scalePixelToScreenHeight(30)
	self.titleTextSize = self:scalePixelToScreenHeight(19)
	self.titleToTextOffsetY = self:scalePixelToScreenHeight(10)
	self.titleOffsetY = self:scalePixelToScreenHeight(20)
	self.textSize = self:scalePixelToScreenHeight(17)
	self.textOffsetY = self:scalePixelToScreenHeight(18)
	local v11_, v12_ = self:scalePixelValuesToScreenVector(20, 20)
	self.textOffsetX = v11_
	self.textOffsetY = v12_
	self.maxTextWidth = self.width - 2 * self.textOffsetX
	self.controlTextSize = self:scalePixelToScreenHeight(17)
	local v13_, v14_ = self:scalePixelValuesToScreenVector(10, 15)
	self.controlTextOffsetX = v13_
	self.controlTextOffsetY = v14_
	self.textControlsOffsetY = self:scalePixelToScreenHeight(15)
	self.controlsHeight = self:scalePixelToScreenHeight(42)
	self.keyButtonOverlay:setMinWidth(self:scalePixelToScreenWidth(35))
	self.glyphButtonOverlay:setMinWidth(self:scalePixelToScreenWidth(35))
	self.buttonHeight = self:scalePixelToScreenHeight(30)
	self:updateControls()
end

-- Local values: controls, _, control, helpElement
function IngameMessage:updateControls()
	if self.currentMessage ~= nil then
		self.skipControl = g_inputDisplayManager:getControllerSymbolOverlays(InputAction.SKIP_MESSAGE_BOX, "", "", false)
		local v16_ = self.currentMessage.controls
		if v16_ ~= nil then
			for _, v17_ in ipairs(v16_) do
				local v18_ = g_inputDisplayManager:getControllerSymbolOverlays(v17_.actionName, v17_.actionName2, "", false)
				v17_.buttons = v18_.buttons
				v17_.isComboButtonMapping = v18_.isComboButtonMapping
				v17_.keys = v18_.keys
			end
		end
	end
end

-- Local values: inputMode
function IngameMessage:update(dt)
	if not (g_gui:getIsMenuVisible() or (self.isGamePaused or g_sleepManager:getIsSleeping())) then
		if self.currentMessage == nil then
			if self.nextMessageTimer > 0 then
				self.nextMessageTimer = self.nextMessageTimer - dt
			elseif #self.pendingMessages > 0 then
				self:startMessage()
			end
		else
			self.currentMessage.timeLeft = self.currentMessage.timeLeft - dt
			if self.currentMessage.timeLeft <= 0 then
				self:stopMessage()
			end
		end
		if self.currentMessage ~= nil then
			local v21_ = g_inputBinding:getInputHelpMode()
			if v21_ ~= self.lastInputMode then
				self.lastInputMode = v21_
				self:updateControls()
			end
		end
	end
end

function IngameMessage:setPaused(isPaused)
	self.isGamePaused = isPaused
end

function IngameMessage:setVisible(isVisible)
	self:setInputActive(isVisible)
	IngameMessage:superClass().setVisible(self, isVisible)
end

-- Local values: _, eventId
function IngameMessage:setInputActive(isActive)
	if self.isCustomInputActive or not isActive then
		if self.isCustomInputActive and not isActive then
			g_inputBinding:removeActionEventsByTarget(self)
			g_inputBinding:revertContext(true)
			self.isCustomInputActive = false
		end
	else
		g_inputBinding:setContext(IngameMessage.INPUT_CONTEXT_NAME, true, false)
		local _, v28_ = g_inputBinding:registerActionEvent(InputAction.MENU_ACCEPT, self, self.stopMessage, false, true, false, true)
		g_inputBinding:setActionEventTextVisibility(v28_, false)
		local _, v29_ = g_inputBinding:registerActionEvent(InputAction.SKIP_MESSAGE_BOX, self, self.stopMessage, false, true, false, true)
		g_inputBinding:setActionEventTextVisibility(v29_, false)
		self.isCustomInputActive = true
	end
end

-- Local values: ingameMap, pendingMessage
function IngameMessage:startMessage()
	local v31_ = g_currentMission.hud.ingameMap
	v31_:setAllowToggle(false)
	v31_:turnSmall()
	local v32_ = table.remove(self.pendingMessages, 1)
	if v32_ ~= nil then
		self.currentMessage = v32_
		self:updateControls()
		self:setVisible(true)
	end
end

function IngameMessage:stopMessage()
	if self.currentMessage ~= nil then
		g_currentMission.hud.ingameMap:setAllowToggle(true)
		if self.currentMessage ~= nil and self.currentMessage.callback ~= nil then
			if self.currentMessage.target == nil then
				self.currentMessage.callback(self)
			else
				self.currentMessage.callback(self.currentMessage.target)
			end
		end
		self:setVisible(false)
		self.currentMessage = nil
		self.nextMessageTimer = 500
	end
end

-- Local values: message
function IngameMessage:showMessage(title, text, duration, controls, callback, target)
	local v41_ = duration or -1
	if v41_ == 0 then
		v41_ = IngameMessage.MIN_DURATION + utf8Strlen(text) * IngameMessage.DURATION_PER_CHARACTER
	elseif v41_ < 0 then
		v41_ = IngameMessage.MAX_DURATION
	end
	if title ~= nil then
		title = utf8ToUpper(title)
	end
	local v42_ = self.pendingMessages
	table.insert(v42_, {
		["isDialog"] = false,
		["title"] = title,
		["text"] = text,
		["timeLeft"] = v41_,
		["controls"] = controls,
		["callback"] = callback,
		["target"] = target
	})
end

-- Local values: message, title, text, controls, posX, posY, height, titleHeight, textHeight, numControls, color, textPosX, currentPosY, lineStart, lineEnd, lineStart, lineEnd, offsetY, _, control, width, maxWidth, controlText, numControls, skipTextWidth, skipTextPosX, skipTextPosY, skipPosX, skipPosY
function IngameMessage:draw()
	IngameMessage:superClass().draw(self)
	if self:getVisible() then
		if not g_gui:getIsGuiVisible() then
			local v44_ = self.currentMessage
			if v44_ ~= nil then
				local v45_ = v44_.title
				local v46_ = v44_.text
				local v47_ = v44_.controls
				local v48_, v49_ = self:getPosition()
				local v50_ = v48_ - self.width * 0.5
				local v51_ = 2 * self.textOffsetY + self.skipHeight
				setTextColor(1, 1, 1, 1)
				setTextAlignment(RenderText.ALIGN_LEFT)
				setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_TOP)
				setTextWrapWidth(self.maxTextWidth)
				local v52_
				if v45_ == nil then
					v52_ = 0
				else
					setTextBold(true)
					v52_ = getTextHeight(self.titleTextSize, v45_)
					v51_ = v51_ + v52_ + self.titleToTextOffsetY
				end
				local v53_
				if v46_ == nil then
					v53_ = 0
				else
					setTextBold(false)
					v53_ = getTextHeight(self.textSize, v46_)
					v51_ = v51_ + v53_
				end
				if v47_ ~= nil then
					local v54_ = #v47_
					v51_ = v51_ + self.controlsHeight * v54_ + g_pixelSizeY * (v54_ - 1)
				end
				if v45_ ~= nil or v46_ ~= nil then
					v51_ = v51_ + self.textControlsOffsetY
				end
				local v55_ = HUD.COLOR.BACKGROUND_DARK
				drawFilledRectRound(v50_, v49_, self.width, v51_, 0.5, v55_[1], v55_[2], v55_[3], v55_[4])
				local v56_ = v50_ + self.textOffsetX
				local v57_ = v49_ + v51_ - self.textOffsetY
				if v45_ ~= nil then
					setTextBold(true)
					renderText(v56_, v57_, self.titleTextSize, v45_)
					v57_ = v57_ - self.titleToTextOffsetY - v52_
				end
				if v46_ ~= nil then
					setTextBold(false)
					renderText(v56_, v57_, self.textSize, v46_)
					v57_ = v57_ - v53_
				end
				setTextWrapWidth(0)
				setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_BASELINE)
				if v45_ ~= nil or v46_ ~= nil then
					v57_ = v57_ - self.textControlsOffsetY
					local v58_ = v50_ + self.textOffsetX
					local v59_ = v58_ + self.maxTextWidth
					drawLine2D(v58_, v57_, v59_, v57_, g_pixelSizeY, 1, 1, 1, 0.2)
				end
				if v47_ ~= nil then
					local v60_ = v50_ + self.textOffsetX
					local v61_ = v60_ + self.maxTextWidth
					local v62_ = (self.controlsHeight - self.buttonHeight) * 0.5
					for _, v63_ in ipairs(v47_) do
						v57_ = v57_ - self.controlsHeight
						local v64_ = self:drawControl(v63_, v61_, v57_ + v62_)
						local v65_ = self.maxTextWidth - v64_ - self.controlTextOffsetX
						local v66_ = Utils.limitTextToWidth(v63_.text, self.controlTextSize, v65_, false, "...")
						setTextBold(true)
						renderText(v56_, v57_ + self.controlTextOffsetY, self.controlTextSize, v66_)
						drawLine2D(v60_, v57_, v61_, v57_, g_pixelSizeY, 1, 1, 1, 0.2)
					end
					local v67_ = #v47_
					local _ = v51_ + self.controlsHeight * v67_ + g_pixelSizeY * (v67_ - 1)
				end
				setTextBold(true)
				setTextAlignment(RenderText.ALIGN_RIGHT)
				local v68_ = getTextWidth(self.skipTextSize, self.skipText)
				local v69_ = v50_ + self.textOffsetX + self.maxTextWidth * 0.5 + v68_
				local v70_ = v49_ + self.skipTextOffsetY
				renderText(v69_, v70_, self.skipTextSize, self.skipText)
				local v71_ = v69_ - self.skipTextOffsetX - v68_
				local v72_ = v49_ + self.skipButtonOffsetY
				self:drawControl(self.skipControl, v71_, v72_)
				setTextColor(1, 1, 1, 1)
				setTextAlignment(RenderText.ALIGN_LEFT)
			end
		end
	else
		return
	end
end

-- Local values: buttons, keys, isComboButtonMapping, width, totalWidth, startPosX, startPosX, i, key, keyWidth, totalWidth
function IngameMessage:drawControl(control, posX, posY)
	local v77_ = control.buttons
	local v78_ = control.keys
	local v79_ = control.isComboButtonMapping
	local v80_ = 0
	if #v77_ <= 0 then
		if #v78_ > 0 then
			for v81_ = #v78_, 1, -1 do
				local v82_ = v78_[v81_]
				local v83_ = self.keyButtonOverlay:getButtonWidth(v82_, self.buttonHeight) + g_pixelSizeX
				posX = posX - v83_
				v80_ = v80_ + v83_
				self.keyButtonOverlay:renderButton(v82_, posX, posY, self.buttonHeight, true)
			end
		end
		return v80_
	end
	local v84_ = self.glyphButtonOverlay:getButtonWidth(v77_, v79_, false, self.buttonHeight)
	local v85_ = posX - v84_
	self.glyphButtonOverlay:renderButton(v77_, v79_, false, v85_, posY, self.buttonHeight)
	return v80_ + v84_
end
if v1_ ~= nil then
	local v86_ = IngameMessage.new()
	v86_:setScale(v1_.uiScale)
	v86_:setVisible(v1_.isVisible)
	for _, v87_ in ipairs(v1_.pendingMessages) do
		v86_:showMessage(v87_.title, v87_.text, v87_.duration, v87_.controls, v87_.callback, v87_.target)
	end
	g_currentMission.hud.ingameMessage = v86_
	g_currentMission.hud.displayComponents.ingameMessage = v86_
	Logging.info("Reloaded IngameMessage")
end
