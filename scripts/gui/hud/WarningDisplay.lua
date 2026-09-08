-- Local values: data, old, WarningDisplay_mt, warningDisplay
local v1_
if WarningDisplay == nil then
	v1_ = nil
else
	local v2_ = g_currentMission.hud.warningDisplay
	v1_ = {
		["uiScale"] = v2_.uiScale,
		["isVisible"] = v2_:getVisible()
	}
	v2_:delete()
end
WarningDisplay = {}
WarningDisplay.MAX_NOTIFICATIONS = 5
local data = Class(WarningDisplay, HUDDisplay)

-- Upvalues: WarningDisplay_mt
-- Local values: self
function WarningDisplay.new(customMt)
	-- upvalues: (copy) data
	local v4_ = WarningDisplay:superClass().new(data)
	v4_.warnings = {}
	v4_.icon = g_overlayManager:createOverlay("gui.storeAttribute_info", 0, 0, 0, 0)
	v4_.icon:setColor(0.8, 0.8, 0.8, 0.7)
	return v4_
end

function WarningDisplay:delete()
	self.icon:delete()
end

-- Local values: offsetX, offsetY, posX, posY, iconWidth, iconHeight
function WarningDisplay:storeScaledValues()
	local v7_, v8_ = self:scalePixelValuesToScreenVector(0, 0)
	self:setPosition(0.5 + v7_, 0.45 + v8_)
	self.maxTextWidth = self:scalePixelToScreenWidth(600)
	self.textSize = self:scalePixelToScreenHeight(16)
	local v9_, v10_ = self:scalePixelValuesToScreenVector(20, 10)
	self.boxPaddingX = v9_
	self.boxPaddingY = v10_
	self.textOffsetY = self:scalePixelToScreenHeight(2)
	self.boxOffsetY = self:scalePixelToScreenHeight(6)
	self.iconTextOffsetX = self:scalePixelToScreenHeight(10)
	local v11_, v12_ = self:scalePixelValuesToScreenVector(36, 36)
	self.icon:setDimension(v11_, v12_)
end

-- Local values: i, warning
function WarningDisplay:update(dt)
	for v15_ = #self.warnings, 1, -1 do
		local v16_ = self.warnings[v15_]
		v16_.duration = v16_.duration - dt
		if v16_.duration < 0 then
			table.remove(self.warnings, v15_)
		end
	end
end

-- Local values: numWarnings, posX, posY, textSize, textOffsetY, totalHeight, _, warning, text, textHeight, alpha, _, warning, text, textWidth, textHeight, boxWidth, boxHeight, boxX, boxY
function WarningDisplay:draw()
	WarningDisplay:superClass().draw(self)
	if #self.warnings ~= 0 then
		setTextWrapWidth(self.maxTextWidth)
		local v18_, v19_ = self:getPosition()
		local v20_ = self.textSize
		local v21_ = self.textOffsetY
		local v22_ = 0
		for _, v23_ in ipairs(self.warnings) do
			local v24_ = v23_.text
			v22_ = v22_ + getTextHeight(v20_, v24_) + 2 * self.boxPaddingY + self.boxOffsetY
		end
		local v25_ = v19_ + (v22_ - self.boxOffsetY) * 0.5
		setTextBold(true)
		setTextAlignment(RenderText.ALIGN_LEFT)
		setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_MIDDLE)
		local v26_ = 0.4 + 0.6 * IngameMap.alpha
		setTextColor(0.7796, 0.0578, 0.0612, v26_)
		for _, v27_ in ipairs(self.warnings) do
			local v28_ = v27_.text
			local v29_ = getTextWidth(v20_, v28_)
			local v30_ = getTextHeight(v20_, v28_)
			local v31_ = v29_ + self.iconTextOffsetX + self.icon.width + 2 * self.boxPaddingX
			local v32_ = v30_ + 2 * self.boxPaddingY
			local v33_ = self.icon.height + 2 * self.boxPaddingY
			local v34_ = math.max(v32_, v33_)
			local v35_ = v18_ - v31_ * 0.5
			local v36_ = v25_ - v34_ * 0.5
			drawFilledRectRound(v35_, v36_, v31_, v34_, 0.35, 0, 0, 0, 0.8)
			local v37_ = v25_ - v34_
			self.icon:setPosition(v35_ + self.boxPaddingX, v36_ + v34_ * 0.5 - self.icon.height * 0.5)
			self.icon:render()
			renderText(self.icon.x + self.icon.width + self.iconTextOffsetX, v36_ + v34_ * 0.5 + v21_, self.textSize, v28_)
			v25_ = v37_ - self.boxOffsetY
		end
		setTextAlignment(RenderText.ALIGN_LEFT)
		setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_BASELINE)
		setTextColor(1, 1, 1, 1)
		setTextBold(false)
	end
end

-- Local values: found, _, warning
function WarningDisplay:addWarning(text, duration, customIdentifier)
	local v42_ = duration or 200
	local v43_ = false
	for _, v44_ in ipairs(self.warnings) do
		if v44_.text == text or customIdentifier ~= nil and v44_.customIdentifier == customIdentifier then
			v44_.text = text
			v44_.duration = v42_
			v43_ = true
		end
	end
	if not v43_ then
		local v45_ = self.warnings
		table.insert(v45_, {
			["text"] = text,
			["duration"] = v42_,
			["customIdentifier"] = customIdentifier
		})
	end
end
if v1_ ~= nil then
	local v46_ = WarningDisplay.new()
	v46_:setScale(v1_.uiScale)
	v46_:setVisible(v1_.isVisible)
	g_currentMission.hud.warningDisplay = v46_
	g_currentMission.hud.displayComponents.warningDisplay = v46_
	Logging.info("Reloaded WarningDisplay")
end
