InfoDisplayKeyValueBoxMobile = {}
local InfoDisplayKeyValueBoxMobile_mt = Class(InfoDisplayKeyValueBoxMobile, InfoDisplayBox)
function InfoDisplayKeyValueBoxMobile.new(infoDisplay, uiScale)
	local self = InfoDisplayBox.new(infoDisplay, uiScale, InfoDisplayKeyValueBoxMobile_mt)
	self.displayComponents = {}
	self.cachedLines = {}
	self.activeLines = {}
	self.posYOffset = 160 * g_pixelSizeY * (g_screenHeight / g_referenceScreenHeight)
	return self
end
function InfoDisplayKeyValueBoxMobile:canDraw()
	return self.doShowNextFrame
end
function InfoDisplayKeyValueBoxMobile:getDisplayHeight()
	return 2 * self.listMarginHeight + #self.activeLines * self.rowHeight + self.labelTextOffsetY
end
function InfoDisplayKeyValueBoxMobile:draw(posX, posY)
	local _, rightInset = getSafeFrameInsets()
	posX = posX - rightInset
	local rightX = posX
	local leftX = posX - self.boxWidth
	local y = posY + self.posYOffset
	local height = 2 * self.listMarginHeight + #self.activeLines * self.rowHeight
	drawFilledRectRound(leftX, y, self.boxWidth, height, self.uiScale, 0, 0, 0, 0.75)
	y = y + self.listMarginHeight
	leftX = leftX + self.leftTextOffsetX + self.listMarginWidth
	rightX = rightX - self.rightTextOffsetX - self.listMarginWidth
	local textAreaX = self.boxWidth - self.leftTextOffsetX - self.listMarginWidth - self.rightTextOffsetX - self.listMarginWidth
	for i = #self.activeLines, 1, -1 do
		local line = self.activeLines[i]
		setTextBold(true)
		if line.accentuate then
			setTextColor(unpack(line.accentuateColor or InfoDisplayKeyValueBoxMobile.COLOR.TEXT_HIGHLIGHT))
		else
			setTextColor(1, 1, 1, 1)
		end
		setTextAlignment(RenderText.ALIGN_LEFT)
		renderText(leftX, y + self.leftTextOffsetY, self.rowTextSize, line.key)
		setTextAlignment(RenderText.ALIGN_RIGHT)
		local maxWidth = textAreaX - 0.025 * self.boxWidth - getTextWidth(self.rowTextSize, line.key)
		setTextBold(false)
		local text = Utils.limitTextToWidth(line.value, self.rowTextSize, maxWidth, false, "...")
		renderText(rightX, y + self.rightTextOffsetY, self.rowTextSize, text)
		if line.accentuate then
			setTextColor(unpack(InfoDisplayKeyValueBoxMobile.COLOR.TEXT_DEFAULT))
		end
		y = y + self.rowHeight
	end
	setTextAlignment(RenderText.ALIGN_LEFT)
	self.doShowNextFrame = false
end
function InfoDisplayKeyValueBoxMobile:clear()
	for i = #self.activeLines, 1, -1 do
		self.cachedLines[#self.cachedLines + 1] = self.activeLines[i]
		self.activeLines[i] = nil
	end
end
function InfoDisplayKeyValueBoxMobile:setTitle(title) end
function InfoDisplayKeyValueBoxMobile:textSizeToFit(baseSize, text, maxWidth, minSize)
	local size = baseSize
	if minSize == nil then
		minSize = baseSize / 2
	end
	setTextWrapWidth(maxWidth)
	local lengthWithNoLineLimit = getTextLength(size, text, 99999)
	while getTextLength(size, text, 1) < lengthWithNoLineLimit do
		size = size - baseSize * 0.05
		if size <= minSize then
			size = size + baseSize * 0.05
			break
		end
	end
	setTextWrapWidth(0)
	return size
end
function InfoDisplayKeyValueBoxMobile:addLine(key, value, accentuate, accentuateColor)
	local line = nil
	local cached = self.cachedLines
	local numCached = #cached
	if 0 < numCached then
		line = self.cachedLines[numCached]
		self.cachedLines[numCached] = nil
	else
		line = {}
	end
	line.key = key
	line.value = value or ""
	line.accentuate = accentuate
	line.accentuateColor = accentuateColor
	self.activeLines[#self.activeLines + 1] = line
end
function InfoDisplayKeyValueBoxMobile:showNextFrame()
	self.doShowNextFrame = true
end
function InfoDisplayKeyValueBoxMobile:setScale(uiScale)
	self.uiScale = uiScale
	self:storeScaledValues()
end
function InfoDisplayKeyValueBoxMobile:storeScaledValues()
	local scale = self.uiScale
	local normalize = function(x, y)
		return x * scale * g_aspectScaleX / g_referenceScreenWidth, y * scale * g_aspectScaleY / g_referenceScreenHeight
	end
	self.boxWidth = 500 * scale * g_aspectScaleX / g_referenceScreenWidth
	local _ = nil
	local y = HUDElement.TEXT_SIZE.DEFAULT_TEXT_MOBILE
	self.rowTextSize = y * scale * g_aspectScaleY / g_referenceScreenHeight
	_ = 0 * scale * g_aspectScaleX / g_referenceScreenWidth
	self.labelTextOffsetX = 0 * scale * g_aspectScaleX / g_referenceScreenWidth
	self.labelTextOffsetY = 3 * scale * g_aspectScaleY / g_referenceScreenHeight
	self.leftTextOffsetX = 0 * scale * g_aspectScaleX / g_referenceScreenWidth
	self.leftTextOffsetY = 6 * scale * g_aspectScaleY / g_referenceScreenHeight
	self.rightTextOffsetX = 0 * scale * g_aspectScaleX / g_referenceScreenWidth
	self.rightTextOffsetY = 6 * scale * g_aspectScaleY / g_referenceScreenHeight
	self.rowWidth = 450 * scale * g_aspectScaleX / g_referenceScreenWidth
	self.rowHeight = 40 * scale * g_aspectScaleY / g_referenceScreenHeight
	self.listMarginWidth = 25 * scale * g_aspectScaleX / g_referenceScreenWidth
	self.listMarginHeight = 15 * scale * g_aspectScaleY / g_referenceScreenHeight
end
InfoDisplayKeyValueBoxMobile.COLOR = { TEXT_DEFAULT = { 1, 1, 1, 1 }, TEXT_HIGHLIGHT = { 0.0003, 0.5647, 0.9822, 1 }, SEPARATOR = { 1, 1, 1, 0.2 } }
