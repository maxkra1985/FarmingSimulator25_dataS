GlyphButtonOverlay = {}
local GlyphButtonOverlay_mt = Class(GlyphButtonOverlay, ButtonOverlay)
function GlyphButtonOverlay.new(customMt)
	local self = ButtonOverlay.new(GlyphButtonOverlay_mt)
	return self
end
function GlyphButtonOverlay:renderButton(glyphButtons, isComboButton, ignoreComboButtons, posX, posY, height, colorText, clipX1, clipY1, clipX2, clipY2, customOffsetLeft, customButtonInputText)
	customOffsetLeft = customOffsetLeft or 0
	local width, widthNoOffset = self:getButtonWidth(glyphButtons, isComboButton, ignoreComboButtons, height, customOffsetLeft, customButtonInputText)
	self:renderBackground(posX, posY, width, height, clipX1, clipY1, clipX2, clipY2)
	local leftRightPadding = height * self.leftRightPaddingHeightRatio / g_screenAspectRatio
	local buttonPosX = posX + width - widthNoOffset + leftRightPadding * 0.5
	for k, button in ipairs(glyphButtons) do
		if not ignoreComboButtons or isComboButton[k] == false then
			local scaleFactor = height / button.height
			local buttonWidth = button.width * scaleFactor
			button:renderCustom(buttonPosX, posY, buttonWidth, height, self.r, self.g, self.b, self.a)
			buttonPosX = buttonPosX + buttonWidth + g_pixelSizeX * 3
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
		local textSize = height * self.textSizeFactor
		local textPosY = posY + height * 0.5 + textSize * self.textYOffsetFactor
		renderText(self.buttonScaleOverlay.x, textPosY, textSize, customButtonInputText)
		if clipX1 ~= nil then
			setTextClipArea(0, 0, 1, 1)
		end
		setTextBold(false)
		setTextColor(1, 1, 1, 1)
		setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_BASELINE)
	end
	local totalWidth = self.buttonRightOverlay.x + self.buttonRightOverlay.width - self.buttonLeftOverlay.x
	return totalWidth
end
function GlyphButtonOverlay:getButtonWidth(glyphButtons, isComboButton, ignoreComboButtons, height, customOffsetLeft, customButtonInputText)
	local width = 0
	for k, button in ipairs(glyphButtons) do
		if not ignoreComboButtons or isComboButton[k] == false then
			local scaleFactor = height / button.height
			width = width + button.width * scaleFactor
		end
	end
	local customOffset = customOffsetLeft or 0
	if customButtonInputText ~= nil then
		local textSize = height * self.textSizeFactor
		setTextBold(true)
		customButtonInputText = utf8ToUpper(tostring(customButtonInputText))
		customOffset = customOffset + getTextWidth(textSize, customButtonInputText)
		setTextBold(false)
	end
	local leftRightPadding = height * self.leftRightPaddingHeightRatio / g_screenAspectRatio
	local totalWidthNoOffset = width + leftRightPadding
	local totalWidth = totalWidthNoOffset + customOffset
	if self.minWidth ~= nil then
		totalWidthNoOffset = math.max(totalWidthNoOffset, self.minWidth)
		totalWidth = math.max(totalWidth, self.minWidth)
	end
	return totalWidth, totalWidthNoOffset
end
