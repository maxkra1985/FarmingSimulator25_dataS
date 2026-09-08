-- Local values: InfoDisplayBoxPrecisionFarming_mt
InfoDisplayBoxPrecisionFarming = {}
local InfoDisplayBoxPrecisionFarming_mt = Class(InfoDisplayBoxPrecisionFarming, InfoDisplayKeyValueBox)

-- Upvalues: InfoDisplayBoxPrecisionFarming_mt
-- Local values: self
function InfoDisplayBoxPrecisionFarming.new(infoDisplay, uiScale)
	-- upvalues: (copy) InfoDisplayBoxPrecisionFarming_mt
	return InfoDisplayKeyValueBox.new(infoDisplay, uiScale, InfoDisplayBoxPrecisionFarming_mt)
end
function InfoDisplayBoxPrecisionFarming.draw(p4_, p5_, p6_)
	local v7_ = p5_ - p4_.boxWidth
	local v8_ = p4_.titleAndBoxHeight
	for _, v9_ in ipairs(p4_.lines) do
		if v9_.isActive then
			v8_ = v8_ + p4_.lineHeight
			if v9_.isWarning then
				local v10_ = p4_.warningOffsetY
				v8_ = v8_ + math.abs(v10_)
			end
		end
	end
	p4_.bgScale:setDimension(nil, v8_ - p4_.bgBottom.height - p4_.bgTop.height)
	p4_.bgBottom:setPosition(v7_, p6_)
	p4_.bgBottom:render()
	p4_.bgScale:setPosition(v7_, p4_.bgBottom.y + p4_.bgBottom.height)
	p4_.bgScale:render()
	p4_.bgTop:setPosition(v7_, p4_.bgScale.y + p4_.bgScale.height)
	p4_.bgTop:render()
	local v11_ = v7_ + p4_.titleOffsetX
	local v12_ = p4_.bgTop.y + p4_.bgTop.height + p4_.titleOffsetY
	setTextAlignment(RenderText.ALIGN_LEFT)
	setTextColor(1, 1, 1, 1)
	setTextBold(true)
	renderText(v11_, v12_, p4_.titleTextSize, p4_.title)
	setTextBold(false)
	local v13_ = v7_ + p4_.keyOffsetX
	local v14_ = v7_ + p4_.warningIconOffsetX
	local v15_ = p5_ + p4_.valueOffsetX
	local v16_ = v12_ + p4_.titleToLineOffsetY
	local v17_ = HUD.COLOR.ACTIVE
	local v18_ = HUD.COLOR.INACTIVE
	for _, v19_ in ipairs(p4_.lines) do
		if v19_.isActive then
			local v20_ = v19_.key
			local v21_ = v19_.value
			local v22_ = v19_.isWarning
			local v23_ = v19_.customColor
			local v24_, v25_, v26_, v27_
			if v22_ then
				v24_ = v17_[1]
				v25_ = v17_[2]
				v26_ = v17_[3]
				v27_ = v17_[4]
			else
				v27_ = 1
				v24_ = 1
				v25_ = 1
				v26_ = 1
			end
			if v23_ ~= nil then
				v24_ = v23_[1]
				v25_ = v23_[2]
				v26_ = v23_[3]
				v27_ = v23_[4] or v27_
			end
			if v22_ then
				p4_.warningIcon:setPosition(v14_, v16_ + p4_.warningIconOffsetY)
				p4_.warningIcon:setColor(v24_, v25_, v26_)
				p4_.warningIcon:render()
			end
			setTextColor(v24_, v25_, v26_, v27_)
			setTextAlignment(RenderText.ALIGN_LEFT)
			renderText(v13_, v16_, p4_.keyTextSize, v20_)
			local v28_ = getTextWidth(p4_.keyTextSize, v20_)
			setTextAlignment(RenderText.ALIGN_RIGHT)
			renderText(v15_, v16_, p4_.valueTextSize, v21_)
			local v29_ = getTextWidth(p4_.valueTextSize, v21_)
			local v30_ = v13_ + v28_ + 3 * g_pixelSizeX
			local v31_ = v15_ - v29_ - v30_ - 3 * g_pixelSizeX
			drawDashedLine(v30_, v16_, v31_, p4_.dashedLineHeight, p4_.dashWidth, p4_.dashGapWidth, v18_[1], v18_[2], v18_[3], v18_[4], true)
			v16_ = v16_ + p4_.lineToLineOffsetY
		end
	end
	local v32_ = p4_.bgTop.y + p4_.bgTop.height
	setTextAlignment(RenderText.ALIGN_LEFT)
	setTextColor(1, 1, 1, 1)
	p4_.doShowNextFrame = false
	return p5_, v32_
end

-- Local values: line
function InfoDisplayBoxPrecisionFarming:addLine(key, value, isWarning, customColor)
	self.currentLineIndex = self.currentLineIndex + 1
	local v38_ = self.lines[self.currentLineIndex]
	if v38_ == nil then
		v38_ = {
			["key"] = "",
			["value"] = "",
			["isWarning"] = false
		}
		table.addElement(self.lines, v38_)
	end
	v38_.key = key
	v38_.value = value or ""
	v38_.isWarning = isWarning
	v38_.customColor = customColor
	v38_.isActive = true
end
