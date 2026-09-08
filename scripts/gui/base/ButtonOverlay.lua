-- Local values: ButtonOverlay_mt
ButtonOverlay = {}
local ButtonOverlay_mt = Class(ButtonOverlay)

-- Upvalues: ButtonOverlay_mt
-- Local values: self
function ButtonOverlay.new(customMt)
	-- upvalues: (copy) ButtonOverlay_mt
	local v3_ = customMt or ButtonOverlay_mt
	local v4_ = setmetatable({}, v3_)
	v4_.textSizeFactor = 0.55
	v4_.textYOffsetFactor = 0.17
	v4_.buttonScaleOverlay = g_overlayManager:createOverlay("gui.button_middle", 0, 0, 0, 0)
	v4_.buttonLeftOverlay = g_overlayManager:createOverlay("gui.button_left", 0, 0, 0, 0)
	v4_.buttonRightOverlay = g_overlayManager:createOverlay("gui.button_right", 0, 0, 0, 0)
	v4_.buttonLeftWidthToHeightRatio = 0.24
	v4_.leftRightPaddingHeightRatio = 0.48
	v4_:setColor(1, 1, 1, 1)
	v4_.minWidth = nil
	v4_.debugEnabled = nil
	return v4_
end

function ButtonOverlay:delete()
	if self.buttonScaleOverlay ~= nil then
		self.buttonScaleOverlay:delete()
		self.buttonScaleOverlay = nil
	end
	if self.buttonLeftOverlay ~= nil then
		self.buttonLeftOverlay:delete()
		self.buttonLeftOverlay = nil
	end
	if self.buttonRightOverlay ~= nil then
		self.buttonRightOverlay:delete()
		self.buttonRightOverlay = nil
	end
end

function ButtonOverlay:setColor(r, g, b, a, r2, g2, b2, a2)
	self.r = r or self.r
	self.g = g or self.g
	self.b = b or self.b
	self.a = a or self.a
	self.r2 = r2 or (self.r2 or r)
	self.g2 = g2 or (self.g2 or g)
	self.b2 = b2 or (self.b2 or b)
	self.a2 = a2 or (self.a2 or a)
	if self.buttonScaleOverlay ~= nil then
		self.buttonScaleOverlay:setColor(self.r2, self.g2, self.b2, self.a2)
	end
	if self.buttonLeftOverlay ~= nil then
		self.buttonLeftOverlay:setColor(self.r2, self.g2, self.b2, self.a2)
	end
	if self.buttonRightOverlay ~= nil then
		self.buttonRightOverlay:setColor(self.r2, self.g2, self.b2, self.a2)
	end
end

-- Local values: leftRightWidth, scaleWidth
function ButtonOverlay:renderBackground(posX, posY, width, height, clipX1, clipY1, clipX2, clipY2)
	local v24_ = height * self.buttonLeftWidthToHeightRatio / g_screenAspectRatio
	local v25_ = width - 2 * v24_
	self.buttonLeftOverlay:setDimension(v24_, height)
	self.buttonScaleOverlay:setDimension(v25_, height)
	self.buttonRightOverlay:setDimension(v24_, height)
	self.buttonLeftOverlay:setPosition(posX, posY)
	self.buttonScaleOverlay:setPosition(self.buttonLeftOverlay.x + self.buttonLeftOverlay.width, posY)
	self.buttonRightOverlay:setPosition(self.buttonScaleOverlay.x + self.buttonScaleOverlay.width, posY)
	self.buttonLeftOverlay:render(clipX1, clipY1, clipX2, clipY2)
	self.buttonScaleOverlay:render(clipX1, clipY1, clipX2, clipY2)
	self.buttonRightOverlay:render(clipX1, clipY1, clipX2, clipY2)
end

-- Local values: width, widthNoOffset, textSize, textPosX, textPosY, totalWidth
function ButtonOverlay:renderButton(buttonText, posX, posY, height, colorText, clipX1, clipY1, clipX2, clipY2, customOffsetLeft, customButtonInputText)
	local v38_ = utf8ToUpper((tostring(buttonText)))
	local v39_, v40_ = self:getButtonWidth(v38_, height, customOffsetLeft or 0, customButtonInputText)
	self:renderBackground(posX, posY, v39_, height, clipX1, clipY1, clipX2, clipY2)
	local v41_ = height * self.textSizeFactor
	setTextBold(true)
	setTextAlignment(RenderText.ALIGN_CENTER)
	setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_MIDDLE)
	if clipX1 ~= nil then
		setTextClipArea(clipX1, clipY1, clipX2, clipY2)
	end
	if colorText then
		setTextColor(self.r, self.g, self.b, self.a)
	else
		setTextColor(1, 1, 1, self.a)
	end
	local v42_ = self.buttonRightOverlay.x + self.buttonRightOverlay.width - v40_ * 0.5
	local v43_ = posY + height * 0.5 + v41_ * self.textYOffsetFactor
	renderText(v42_, v43_, v41_, v38_)
	setTextAlignment(RenderText.ALIGN_LEFT)
	if customButtonInputText ~= nil then
		setTextColor(0.5, 0.5, 0.5, 1)
		renderText(self.buttonScaleOverlay.x, v43_, v41_, customButtonInputText)
	end
	if clipX1 ~= nil then
		setTextClipArea(0, 0, 1, 1)
	end
	setTextBold(false)
	setTextColor(1, 1, 1, 1)
	setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_BASELINE)
	local v44_ = self.buttonRightOverlay.x + self.buttonRightOverlay.width - self.buttonLeftOverlay.x
	if self.debugEnabled or g_uiDebugEnabled then
		setOverlayColor(GuiElement.debugOverlay, 1, 0, 1, 0.5)
		renderOverlay(GuiElement.debugOverlay, posX - g_pixelSizeX, posY - g_pixelSizeY, v44_ + 2 * g_pixelSizeX, g_pixelSizeY)
		renderOverlay(GuiElement.debugOverlay, posX - g_pixelSizeX, posY + height, v44_ + 2 * g_pixelSizeX, g_pixelSizeY)
		renderOverlay(GuiElement.debugOverlay, posX - g_pixelSizeX, posY, g_pixelSizeX, height)
		renderOverlay(GuiElement.debugOverlay, posX + v44_, posY, g_pixelSizeX, height)
	end
	return v44_
end

-- Local values: textSize, textWidth, textWidthCustom, leftRightPadding, widthNoOffset, width
function ButtonOverlay:getButtonWidth(buttonText, height, customOffsetLeft, customButtonInputText)
	local v50_ = height * self.textSizeFactor
	setTextBold(true)
	local v51_ = utf8ToUpper((tostring(buttonText)))
	local v52_ = getTextWidth(v50_, v51_)
	local v53_ = customButtonInputText == nil and 0 or getTextWidth(v50_, customButtonInputText)
	setTextBold(false)
	local v54_ = v52_ + 2 * (height * self.leftRightPaddingHeightRatio / g_screenAspectRatio)
	local v55_ = v54_ + (customOffsetLeft or 0) + v53_
	if self.minWidth ~= nil then
		local v56_ = self.minWidth
		v55_ = math.max(v55_, v56_)
		local v57_ = self.minWidth
		v54_ = math.max(v54_, v57_)
	end
	return v55_, v54_
end

function ButtonOverlay:setMinWidth(width)
	self.minWidth = width
end
