-- Local values: HUDTextDisplay_mt
HUDTextDisplay = {}
local HUDTextDisplay_mt = Class(HUDTextDisplay, HUDDisplayElement)
HUDTextDisplay.SHADOW_OFFSET_FACTOR = 0.05

-- Upvalues: HUDTextDisplay_mt
-- Local values: backgroundOverlay, self
function HUDTextDisplay.new(posX, posY, textSize, textAlignment, textColor, textBold)
	-- upvalues: (copy) HUDTextDisplay_mt
	local v8_ = Overlay.new(nil, 0, 0, 0, 0)
	v8_:setColor(1, 1, 1, 1)
	local v9_ = HUDTextDisplay:superClass().new(v8_, nil, HUDTextDisplay_mt)
	v9_.initialPosX = posX
	v9_.initialPosY = posY
	v9_.text = ""
	v9_.textSize = textSize or 0
	v9_.screenTextSize = v9_:scalePixelToScreenHeight(v9_.textSize)
	v9_.textAlignment = textAlignment or RenderText.ALIGN_LEFT
	v9_.textColor = textColor or {
		1,
		1,
		1,
		1
	}
	v9_.textBold = textBold or false
	v9_.hasShadow = false
	v9_.shadowColor = {
		0,
		0,
		0,
		1
	}
	return v9_
end

-- Local values: width, height, posX, posY
function HUDTextDisplay:setText(text, textSize, textAlignment, textColor, textBold)
	self.text = text or self.text
	self.textSize = textSize or self.textSize
	self.screenTextSize = self:scalePixelToScreenHeight(self.textSize)
	self.textAlignment = textAlignment or self.textAlignment
	self.textColor = textColor or self.textColor
	self.textBold = textBold or self.textBold
	self:setDimension(getTextWidth(self.screenTextSize, self.text), (getTextHeight(self.screenTextSize, self.text)))
	self:setPosition(self.initialPosX, self.initialPosY)
end

function HUDTextDisplay:setScale(uiScale)
	HUDTextDisplay:superClass().setScale(self, uiScale)
	self.screenTextSize = self:scalePixelToScreenHeight(self.textSize)
end

function HUDTextDisplay:setVisible(isVisible, animate)
	HUDElement.setVisible(self, isVisible)
	if animate then
		if not (isVisible and self.animation:getFinished()) then
			self.animation:reset()
		end
		if isVisible then
			self.animation:start()
		end
	end
end

function HUDTextDisplay:setAlpha(alpha)
	self:setColor(nil, nil, nil, alpha)
end

function HUDTextDisplay:setTextColorChannels(r, g, b, a)
	self.textColor[1] = r
	self.textColor[2] = g
	self.textColor[3] = b
	self.textColor[4] = a
end

function HUDTextDisplay:setTextShadow(isShadowEnabled, shadowColor)
	self.hasShadow = isShadowEnabled or self.hasShadow
	self.shadowColor = shadowColor or self.shadowColor
end

function HUDTextDisplay:setAnimation(animationTween)
	self:storeOriginalPosition()
	self.animation = animationTween or TweenSequence.NO_SEQUENCE
end

function HUDTextDisplay:update(dt)
	if self:getVisible() then
		HUDTextDisplay:superClass().update(self, dt)
	end
end

-- Local values: posX, posY, offset, r, g, b, a, r, g, b, a
function HUDTextDisplay:draw()
	if self.text == "" then
		return
	elseif self:getVisible() then
		setTextBold(self.textBold)
		local v36_, v37_ = self:getPosition()
		setTextAlignment(self.textAlignment)
		setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_BASELINE)
		setTextWrapWidth(0.9)
		if self.hasShadow then
			local v38_ = self.screenTextSize * HUDTextDisplay.SHADOW_OFFSET_FACTOR
			local v39_ = self.shadowColor
			local v40_, v41_, v42_, v43_ = unpack(v39_)
			setTextColor(v40_, v41_, v42_, v43_ * self.overlay.a)
			renderText(v36_ + v38_, v37_ - v38_, self.screenTextSize, self.text)
		end
		local v44_ = self.textColor
		local v45_, v46_, v47_, v48_ = unpack(v44_)
		setTextColor(v45_, v46_, v47_, v48_ * self.overlay.a)
		renderText(v36_, v37_, self.screenTextSize, self.text)
		setTextAlignment(RenderText.ALIGN_LEFT)
		setTextWrapWidth(0)
		setTextBold(false)
		setTextColor(1, 1, 1, 1)
	end
end
