-- Local values: InfoDisplayKeyValueBoxMobile_mt
InfoDisplayKeyValueBoxMobile = {}
local InfoDisplayKeyValueBoxMobile_mt = Class(InfoDisplayKeyValueBoxMobile, InfoDisplayBox)

-- Upvalues: InfoDisplayKeyValueBoxMobile_mt
-- Local values: self
function InfoDisplayKeyValueBoxMobile.new(infoDisplay, uiScale)
	-- upvalues: (copy) InfoDisplayKeyValueBoxMobile_mt
	local v4_ = InfoDisplayBox.new(infoDisplay, uiScale, InfoDisplayKeyValueBoxMobile_mt)
	v4_.displayComponents = {}
	v4_.cachedLines = {}
	v4_.activeLines = {}
	v4_.posYOffset = 160 * g_pixelSizeY * (g_screenHeight / g_referenceScreenHeight)
	return v4_
end

function InfoDisplayKeyValueBoxMobile:canDraw()
	return self.doShowNextFrame
end

function InfoDisplayKeyValueBoxMobile:getDisplayHeight()
	return 2 * self.listMarginHeight + #self.activeLines * self.rowHeight + self.labelTextOffsetY
end

-- Local values: _, rightInset, rightX, leftX, y, height, textAreaX, i, line, maxWidth, text
function InfoDisplayKeyValueBoxMobile:draw(posX, posY)
	local _, v10_ = getSafeFrameInsets()
	local v11_ = posX - v10_
	local v12_ = v11_ - self.boxWidth
	local v13_ = posY + self.posYOffset
	local v14_ = 2 * self.listMarginHeight + #self.activeLines * self.rowHeight
	drawFilledRectRound(v12_, v13_, self.boxWidth, v14_, self.uiScale, 0, 0, 0, 0.75)
	local v15_ = v13_ + self.listMarginHeight
	local v16_ = v12_ + self.leftTextOffsetX + self.listMarginWidth
	local v17_ = v11_ - self.rightTextOffsetX - self.listMarginWidth
	local v18_ = self.boxWidth - self.leftTextOffsetX - self.listMarginWidth - self.rightTextOffsetX - self.listMarginWidth
	for v19_ = #self.activeLines, 1, -1 do
		local v20_ = self.activeLines[v19_]
		setTextBold(true)
		if v20_.accentuate then
			local v21_ = setTextColor
			local v22_ = v20_.accentuateColor or InfoDisplayKeyValueBoxMobile.COLOR.TEXT_HIGHLIGHT
			v21_(unpack(v22_))
		else
			setTextColor(1, 1, 1, 1)
		end
		setTextAlignment(RenderText.ALIGN_LEFT)
		renderText(v16_, v15_ + self.leftTextOffsetY, self.rowTextSize, v20_.key)
		setTextAlignment(RenderText.ALIGN_RIGHT)
		local v23_ = v18_ - 0.025 * self.boxWidth - getTextWidth(self.rowTextSize, v20_.key)
		setTextBold(false)
		local v24_ = Utils.limitTextToWidth(v20_.value, self.rowTextSize, v23_, false, "...")
		renderText(v17_, v15_ + self.rightTextOffsetY, self.rowTextSize, v24_)
		if v20_.accentuate then
			local v25_ = setTextColor
			local v26_ = InfoDisplayKeyValueBoxMobile.COLOR.TEXT_DEFAULT
			v25_(unpack(v26_))
		end
		v15_ = v15_ + self.rowHeight
	end
	setTextAlignment(RenderText.ALIGN_LEFT)
	self.doShowNextFrame = false
end

-- Local values: i
function InfoDisplayKeyValueBoxMobile:clear()
	for v28_ = #self.activeLines, 1, -1 do
		self.cachedLines[#self.cachedLines + 1] = self.activeLines[v28_]
		self.activeLines[v28_] = nil
	end
end

function InfoDisplayKeyValueBoxMobile:setTitle(title) end

-- Local values: size, lengthWithNoLineLimit
function InfoDisplayKeyValueBoxMobile:textSizeToFit(baseSize, text, maxWidth, minSize)
	if minSize == nil then
		minSize = baseSize / 2
	end
	setTextWrapWidth(maxWidth)
	local v33_ = getTextLength(baseSize, text, 99999)
	local v34_ = baseSize
	while getTextLength(baseSize, text, 1) < v33_ do
		baseSize = baseSize - v34_ * 0.05
		if baseSize <= minSize then
			baseSize = baseSize + v34_ * 0.05
			break
		end
	end
	setTextWrapWidth(0)
	return baseSize
end

-- Local values: line, cached, numCached
function InfoDisplayKeyValueBoxMobile:addLine(key, value, accentuate, accentuateColor)
	local v40_ = #self.cachedLines
	local v41_
	if v40_ > 0 then
		v41_ = self.cachedLines[v40_]
		self.cachedLines[v40_] = nil
	else
		v41_ = {}
	end
	v41_.key = key
	v41_.value = value or ""
	v41_.accentuate = accentuate
	v41_.accentuateColor = accentuateColor
	self.activeLines[#self.activeLines + 1] = v41_
end

function InfoDisplayKeyValueBoxMobile:showNextFrame()
	self.doShowNextFrame = true
end

function InfoDisplayKeyValueBoxMobile:setScale(uiScale)
	self.uiScale = uiScale
	self:storeScaledValues()
end

-- Local values: scale, normalize, _, y
function InfoDisplayKeyValueBoxMobile:storeScaledValues()
	local v46_ = self.uiScale
	local v47_ = 500 * v46_ * g_aspectScaleX / g_referenceScreenWidth
	local _ = 0 * v46_ * g_aspectScaleY / g_referenceScreenHeight
	self.boxWidth = v47_
	local v48_ = HUDElement.TEXT_SIZE.DEFAULT_TEXT_MOBILE
	local _ = 0 * v46_ * g_aspectScaleX / g_referenceScreenWidth
	self.rowTextSize = v48_ * v46_ * g_aspectScaleY / g_referenceScreenHeight
	local v49_ = 0 * v46_ * g_aspectScaleX / g_referenceScreenWidth
	local v50_ = 3 * v46_ * g_aspectScaleY / g_referenceScreenHeight
	self.labelTextOffsetX = v49_
	self.labelTextOffsetY = v50_
	local v51_ = 0 * v46_ * g_aspectScaleX / g_referenceScreenWidth
	local v52_ = 6 * v46_ * g_aspectScaleY / g_referenceScreenHeight
	self.leftTextOffsetX = v51_
	self.leftTextOffsetY = v52_
	local v53_ = 0 * v46_ * g_aspectScaleX / g_referenceScreenWidth
	local v54_ = 6 * v46_ * g_aspectScaleY / g_referenceScreenHeight
	self.rightTextOffsetX = v53_
	self.rightTextOffsetY = v54_
	local v55_ = 450 * v46_ * g_aspectScaleX / g_referenceScreenWidth
	local v56_ = 40 * v46_ * g_aspectScaleY / g_referenceScreenHeight
	self.rowWidth = v55_
	self.rowHeight = v56_
	local v57_ = 25 * v46_ * g_aspectScaleX / g_referenceScreenWidth
	local v58_ = 15 * v46_ * g_aspectScaleY / g_referenceScreenHeight
	self.listMarginWidth = v57_
	self.listMarginHeight = v58_
end
InfoDisplayKeyValueBoxMobile.COLOR = {
	["TEXT_DEFAULT"] = {
		1,
		1,
		1,
		1
	},
	["TEXT_HIGHLIGHT"] = {
		0.0003,
		0.5647,
		0.9822,
		1
	},
	["SEPARATOR"] = {
		1,
		1,
		1,
		0.2
	}
}
