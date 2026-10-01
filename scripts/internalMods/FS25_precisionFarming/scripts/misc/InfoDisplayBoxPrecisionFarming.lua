InfoDisplayBoxPrecisionFarming = {}
local InfoDisplayBoxPrecisionFarming_mt = Class(InfoDisplayBoxPrecisionFarming, InfoDisplayKeyValueBox)
function InfoDisplayBoxPrecisionFarming.new(infoDisplay, uiScale)
	local self = InfoDisplayKeyValueBox.new(infoDisplay, uiScale, InfoDisplayBoxPrecisionFarming_mt)
	return self
end
function InfoDisplayBoxPrecisionFarming:draw(posX, posY)
	local leftX = posX - self.boxWidth
	local y = posY
	local height = self.titleAndBoxHeight
	for _, line in ipairs(self.lines) do
		if line.isActive then
			height = height + self.lineHeight
			if line.isWarning then
				height = height + math.abs(self.warningOffsetY)
			end
		end
	end
	self.bgScale:setDimension(nil, height - self.bgBottom.height - self.bgTop.height)
	self.bgBottom:setPosition(leftX, y)
	self.bgBottom:render()
	self.bgScale:setPosition(leftX, self.bgBottom.y + self.bgBottom.height)
	self.bgScale:render()
	self.bgTop:setPosition(leftX, self.bgScale.y + self.bgScale.height)
	self.bgTop:render()
	local textPosX = leftX + self.titleOffsetX
	local textPosY = self.bgTop.y + self.bgTop.height + self.titleOffsetY
	setTextAlignment(RenderText.ALIGN_LEFT)
	setTextColor(1, 1, 1, 1)
	setTextBold(true)
	renderText(textPosX, textPosY, self.titleTextSize, self.title)
	setTextBold(false)
	local keyPosX = leftX + self.keyOffsetX
	local warningIconPosX = leftX + self.warningIconOffsetX
	local valuePosX = posX + self.valueOffsetX
	local linePosY = textPosY + self.titleToLineOffsetY
	local activeColor = HUD.COLOR.ACTIVE
	local inactiveColor = HUD.COLOR.INACTIVE
	for _, line in ipairs(self.lines) do
		if line.isActive then
			local key = line.key
			local value = line.value
			local isWarning = line.isWarning
			local customColor = line.customColor
			local r = 1
			local g = 1
			local b = 1
			local a = 1
			if isWarning then
				r = activeColor[1]
				g = activeColor[2]
				b = activeColor[3]
				a = activeColor[4]
			end
			if customColor ~= nil then
				r = customColor[1]
				g = customColor[2]
				b = customColor[3]
				a = customColor[4] or a
			end
			if isWarning then
				self.warningIcon:setPosition(warningIconPosX, linePosY + self.warningIconOffsetY)
				self.warningIcon:setColor(r, g, b)
				self.warningIcon:render()
			end
			setTextColor(r, g, b, a)
			setTextAlignment(RenderText.ALIGN_LEFT)
			renderText(keyPosX, linePosY, self.keyTextSize, key)
			local keyWidth = getTextWidth(self.keyTextSize, key)
			setTextAlignment(RenderText.ALIGN_RIGHT)
			renderText(valuePosX, linePosY, self.valueTextSize, value)
			local valueWidth = getTextWidth(self.valueTextSize, value)
			local dashedLineStartX = keyPosX + keyWidth + 3 * g_pixelSizeX
			local dashedLineWidth = valuePosX - valueWidth - dashedLineStartX - 3 * g_pixelSizeX
			drawDashedLine(dashedLineStartX, linePosY, dashedLineWidth, self.dashedLineHeight, self.dashWidth, self.dashGapWidth, inactiveColor[1], inactiveColor[2], inactiveColor[3], inactiveColor[4], true)
			linePosY = linePosY + self.lineToLineOffsetY
		end
	end
	posY = self.bgTop.y + self.bgTop.height
	setTextAlignment(RenderText.ALIGN_LEFT)
	setTextColor(1, 1, 1, 1)
	self.doShowNextFrame = false
	return posX, posY
end
function InfoDisplayBoxPrecisionFarming:addLine(key, value, isWarning, customColor)
	self.currentLineIndex = self.currentLineIndex + 1
	local line = self.lines[self.currentLineIndex]
	if line == nil then
		line = { key = "", value = "", isWarning = false }
		table.addElement(self.lines, line)
	end
	line.key = key
	line.value = value or ""
	line.isWarning = isWarning
	line.customColor = customColor
	line.isActive = true
end
