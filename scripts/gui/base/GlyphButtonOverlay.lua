-- Local values: GlyphButtonOverlay_mt
GlyphButtonOverlay = {}
local GlyphButtonOverlay_mt = Class(GlyphButtonOverlay, ButtonOverlay)

-- Upvalues: GlyphButtonOverlay_mt
-- Local values: self
function GlyphButtonOverlay.new(customMt)
	-- upvalues: (copy) GlyphButtonOverlay_mt
	return ButtonOverlay.new(GlyphButtonOverlay_mt)
end

-- Local values: width, widthNoOffset, leftRightPadding, buttonPosX, buttonPosY, k, button, scaleFactor, buttonWidth, textSize, textPosY, totalWidth
function GlyphButtonOverlay:renderButton(glyphButtons, isComboButton, ignoreComboButtons, posX, posY, height, colorText, clipX1, clipY1, clipX2, clipY2, customOffsetLeft, customButtonInputText)
	local v15_, v16_ = self:getButtonWidth(glyphButtons, isComboButton, ignoreComboButtons, height, customOffsetLeft or 0, customButtonInputText)
	self:renderBackground(posX, posY, v15_, height, clipX1, clipY1, clipX2, clipY2)
	local v17_ = height * self.leftRightPaddingHeightRatio / g_screenAspectRatio
	local v18_ = posX + v15_ - v16_ + v17_ * 0.5
	for v19_, v20_ in ipairs(glyphButtons) do
		if not ignoreComboButtons or isComboButton[v19_] == false then
			local v21_ = height / v20_.height
			local v22_ = v20_.width * v21_
			v20_:renderCustom(v18_, posY, v22_, height, self.r, self.g, self.b, self.a)
			v18_ = v18_ + v22_ + g_pixelSizeX * 3
		end
	end
	if customButtonInputText ~= nil then
		setTextBold(true)
		setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_MIDDLE)
		setTextAlignment(RenderText.ALIGN_LEFT)
		if clipX1 ~= nil then
			setTextClipArea(clipX1, clipY1, clipX2, clipY2)
		end
		setTextColor(0.5, 0.5, 0.5, 1)
		local v23_ = height * self.textSizeFactor
		local v24_ = posY + height * 0.5 + v23_ * self.textYOffsetFactor
		renderText(self.buttonScaleOverlay.x, v24_, v23_, customButtonInputText)
		if clipX1 ~= nil then
			setTextClipArea(0, 0, 1, 1)
		end
		setTextBold(false)
		setTextColor(1, 1, 1, 1)
		setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_BASELINE)
	end
	return self.buttonRightOverlay.x + self.buttonRightOverlay.width - self.buttonLeftOverlay.x
end

-- Local values: width, k, button, scaleFactor, customOffset, textSize, leftRightPadding, totalWidthNoOffset, totalWidth
function GlyphButtonOverlay:getButtonWidth(glyphButtons, isComboButton, ignoreComboButtons, height, customOffsetLeft, customButtonInputText)
	local v32_ = 0
	for v33_, v34_ in ipairs(glyphButtons) do
		if not ignoreComboButtons or isComboButton[v33_] == false then
			local v35_ = height / v34_.height
			v32_ = v32_ + v34_.width * v35_
		end
	end
	local v36_ = customOffsetLeft or 0
	if customButtonInputText ~= nil then
		local v37_ = height * self.textSizeFactor
		setTextBold(true)
		local v38_ = utf8ToUpper((tostring(customButtonInputText)))
		v36_ = v36_ + getTextWidth(v37_, v38_)
		setTextBold(false)
	end
	local v39_ = v32_ + height * self.leftRightPaddingHeightRatio / g_screenAspectRatio
	local v40_ = v39_ + v36_
	if self.minWidth ~= nil then
		local v41_ = self.minWidth
		v39_ = math.max(v39_, v41_)
		local v42_ = self.minWidth
		v40_ = math.max(v40_, v42_)
	end
	return v40_, v39_
end
