-- Local values: InfoDisplayKeyValueBox_mt
InfoDisplayKeyValueBox = {}
local InfoDisplayKeyValueBox_mt = Class(InfoDisplayKeyValueBox, InfoDisplayBox)

-- Upvalues: InfoDisplayKeyValueBox_mt
-- Local values: self, r, g, b, a
function InfoDisplayKeyValueBox.new(infoDisplay, uiScale, customMt)
	-- upvalues: (copy) InfoDisplayKeyValueBox_mt
	local v5_ = InfoDisplayBox.new(infoDisplay, uiScale, customMt or InfoDisplayKeyValueBox_mt)
	v5_.lines = {}
	v5_.title = "Unknown Title"
	local v6_ = HUD.COLOR.BACKGROUND
	local v7_, v8_, v9_, v10_ = unpack(v6_)
	v5_.bgScale = g_overlayManager:createOverlay("gui.fieldInfo_middle", 0, 0, 0, 0)
	v5_.bgScale:setColor(v7_, v8_, v9_, v10_)
	v5_.bgBottom = g_overlayManager:createOverlay("gui.fieldInfo_bottom", 0, 0, 0, 0)
	v5_.bgBottom:setColor(v7_, v8_, v9_, v10_)
	v5_.bgTop = g_overlayManager:createOverlay("gui.fieldInfo_top", 0, 0, 0, 0)
	v5_.bgTop:setColor(v7_, v8_, v9_, v10_)
	local v11_ = HUD.COLOR.ACTIVE
	local v12_, v13_, v14_, v15_ = unpack(v11_)
	v5_.warningIcon = g_overlayManager:createOverlay("gui.fieldInfo_warning", 0, 0, 0, 0)
	v5_.warningIcon:setColor(v12_, v13_, v14_, v15_)
	return v5_
end

function InfoDisplayKeyValueBox:delete()
	self.bgScale:delete()
	self.bgBottom:delete()
	self.bgTop:delete()
	self.warningIcon:delete()
end

-- Local values: infoDisplay, bgWidth, bgBottomHeight, bgTopHeight, iconWidth, iconHeight
function InfoDisplayKeyValueBox:storeScaledValues()
	local v18_ = self.infoDisplay
	local v19_, v20_ = v18_:scalePixelValuesToScreenVector(340, 6)
	local v21_ = v18_:scalePixelToScreenHeight(6)
	self.bgBottom:setDimension(v19_, v20_)
	self.bgTop:setDimension(v19_, v21_)
	self.bgScale:setDimension(v19_, 0)
	self.boxWidth = v18_:scalePixelToScreenWidth(340)
	self.keyTextSize = v18_:scalePixelToScreenHeight(14)
	self.valueTextSize = v18_:scalePixelToScreenHeight(14)
	self.titleTextSize = v18_:scalePixelToScreenHeight(15)
	self.titleToLineOffsetY = v18_:scalePixelToScreenHeight(-24)
	self.lineToLineOffsetY = v18_:scalePixelToScreenHeight(-21)
	self.lineHeight = v18_:scalePixelToScreenHeight(21)
	self.titleAndBoxHeight = v18_:scalePixelToScreenHeight(45)
	self.dashedLineHeight = g_pixelSizeY
	self.dashWidth = v18_:scalePixelToScreenWidth(6)
	self.dashGapWidth = v18_:scalePixelToScreenWidth(3)
	self.keyOffsetX = v18_:scalePixelToScreenWidth(30)
	local v22_, v23_ = v18_:scalePixelValuesToScreenVector(30, -3)
	self.warningOffsetX = v22_
	self.warningOffsetY = v23_
	self.valueOffsetX = v18_:scalePixelToScreenWidth(-14)
	local v24_, v25_ = v18_:scalePixelValuesToScreenVector(14, -27)
	self.titleOffsetX = v24_
	self.titleOffsetY = v25_
	self.titleMaxWidth = v18_:scalePixelToScreenWidth(312)
	local v26_, v27_ = v18_:scalePixelValuesToScreenVector(20, 20)
	self.warningIcon:setDimension(v26_, v27_)
	local v28_, v29_ = v18_:scalePixelValuesToScreenVector(10, -4)
	self.warningIconOffsetX = v28_
	self.warningIconOffsetY = v29_
end
function InfoDisplayKeyValueBox.draw(p30_, p31_, p32_)
	local v33_ = p31_ - p30_.boxWidth
	local v34_ = p30_.titleAndBoxHeight
	for _, v35_ in ipairs(p30_.lines) do
		if v35_.isActive then
			v34_ = v34_ + p30_.lineHeight
			if v35_.isWarning then
				local v36_ = p30_.warningOffsetY
				v34_ = v34_ + math.abs(v36_)
			end
		end
	end
	p30_.bgScale:setDimension(nil, v34_ - p30_.bgBottom.height - p30_.bgTop.height)
	p30_.bgBottom:setPosition(v33_, p32_)
	p30_.bgBottom:render()
	p30_.bgScale:setPosition(v33_, p30_.bgBottom.y + p30_.bgBottom.height)
	p30_.bgScale:render()
	p30_.bgTop:setPosition(v33_, p30_.bgScale.y + p30_.bgScale.height)
	p30_.bgTop:render()
	local v37_ = v33_ + p30_.titleOffsetX
	local v38_ = p30_.bgTop.y + p30_.bgTop.height + p30_.titleOffsetY
	setTextAlignment(RenderText.ALIGN_LEFT)
	setTextColor(1, 1, 1, 1)
	setTextBold(true)
	renderText(v37_, v38_, p30_.titleTextSize, p30_.title)
	setTextBold(false)
	local v39_ = v33_ + p30_.keyOffsetX
	local v40_ = v33_ + p30_.warningOffsetX
	local v41_ = v33_ + p30_.warningIconOffsetX
	local v42_ = p31_ + p30_.valueOffsetX
	local v43_ = v38_ + p30_.titleToLineOffsetY
	local v44_ = HUD.COLOR.ACTIVE
	local v45_ = HUD.COLOR.INACTIVE
	for _, v46_ in ipairs(p30_.lines) do
		if v46_.isActive then
			local v47_ = v46_.key
			local v48_ = v46_.value
			local v49_
			if v46_.isWarning then
				setTextAlignment(RenderText.ALIGN_LEFT)
				setTextColor(v44_[1], v44_[2], v44_[3], v44_[4])
				setTextBold(true)
				v43_ = v43_ + p30_.warningOffsetY
				renderText(v40_, v43_, p30_.keyTextSize, v47_)
				v49_ = getTextWidth(p30_.keyTextSize, v47_)
				setTextBold(false)
				p30_.warningIcon:setPosition(v41_, v43_ + p30_.warningIconOffsetY)
				p30_.warningIcon:render()
			else
				setTextColor(1, 1, 1, 1)
				setTextAlignment(RenderText.ALIGN_LEFT)
				renderText(v39_, v43_, p30_.keyTextSize, v47_)
				v49_ = getTextWidth(p30_.keyTextSize, v47_)
			end
			if v48_ ~= nil and v48_ ~= "" then
				setTextColor(1, 1, 1, 1)
				setTextAlignment(RenderText.ALIGN_RIGHT)
				renderText(v42_, v43_, p30_.valueTextSize, v48_)
				local v50_ = getTextWidth(p30_.valueTextSize, v48_)
				local v51_ = v39_ + v49_ + 3 * g_pixelSizeX
				local v52_ = v42_ - v50_ - v51_ - 3 * g_pixelSizeX
				drawDashedLine(v51_, v43_, v52_, p30_.dashedLineHeight, p30_.dashWidth, p30_.dashGapWidth, v45_[1], v45_[2], v45_[3], v45_[4], true)
			end
			v43_ = v43_ + p30_.lineToLineOffsetY
		end
	end
	local v53_ = p30_.bgTop.y + p30_.bgTop.height
	setTextAlignment(RenderText.ALIGN_LEFT)
	setTextColor(1, 1, 1, 1)
	p30_.doShowNextFrame = false
	return p31_, v53_
end

function InfoDisplayKeyValueBox:canDraw()
	return self.doShowNextFrame
end

function InfoDisplayKeyValueBox:showNextFrame()
	self.doShowNextFrame = true
end

-- Local values: _, line
function InfoDisplayKeyValueBox:clear()
	for _, v57_ in ipairs(self.lines) do
		v57_.isActive = false
	end
	self.currentLineIndex = 0
end

-- Local values: line
function InfoDisplayKeyValueBox:addLine(key, value, isWarning)
	self.currentLineIndex = self.currentLineIndex + 1
	local v62_ = self.lines[self.currentLineIndex]
	if v62_ == nil then
		v62_ = {
			["key"] = "",
			["value"] = "",
			["isWarning"] = false
		}
		table.addElement(self.lines, v62_)
	end
	v62_.key = key
	v62_.value = value or ""
	v62_.isWarning = isWarning
	v62_.isActive = true
end

function InfoDisplayKeyValueBox:setTitle(title)
	local v65_ = utf8ToUpper(title)
	if v65_ ~= self.title then
		self.title = Utils.limitTextToWidth(v65_, self.titleTextSize, self.titleMaxWidth, false, "...")
	end
end
