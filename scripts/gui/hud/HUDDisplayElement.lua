-- Local values: HUDDisplayElement_mt
HUDDisplayElement = {}
local HUDDisplayElement_mt = Class(HUDDisplayElement, HUDElement)
HUDDisplayElement.MOVE_ANIMATION_DURATION = 150

-- Upvalues: HUDDisplayElement_mt
-- Local values: self
function HUDDisplayElement.new(overlay, parentHudElement, customMt)
	-- upvalues: (copy) HUDDisplayElement_mt
	local v5_ = HUDDisplayElement:superClass().new(overlay, parentHudElement, customMt or HUDDisplayElement_mt)
	v5_.origX = 0
	v5_.origY = 0
	v5_.animationState = nil
	return v5_
end

-- Local values: posX, posY, transX, transY
function HUDDisplayElement:setVisible(isVisible, animate)
	if animate and self.animation:getFinished() then
		if isVisible then
			self:animateShow()
		else
			self:animateHide()
		end
	else
		self.animation:stop()
		HUDDisplayElement:superClass().setVisible(self, isVisible)
		local v9_, v10_ = self:getPosition()
		local v11_, v12_ = self:getHidingTranslation()
		if isVisible then
			self:setPosition(self.origX, self.origY)
		else
			self:setPosition(v9_ + v11_, v10_ + v12_)
		end
	end
	self.animationState = isVisible
end

function HUDDisplayElement:setScale(uiScale)
	HUDDisplayElement:superClass().setScale(self, uiScale, uiScale)
end

function HUDDisplayElement:storeOriginalPosition()
	local v16_, v17_ = self:getPosition()
	self.origX = v16_
	self.origY = v17_
end

function HUDDisplayElement:getHidingTranslation()
	return 0, -0.5
end

function HUDDisplayElement:animationSetPositionX(x)
	self:setPosition(x, nil)
end

function HUDDisplayElement:animationSetPositionY(y)
	self:setPosition(nil, y)
end

-- Local values: transX, transY, startX, startY, sequence
function HUDDisplayElement:animateHide()
	local v23_, v24_ = self:getHidingTranslation()
	local v25_, v26_ = self:getPosition()
	local v27_ = TweenSequence.new(self)
	v27_:insertTween(MultiValueTween.new(self.setPosition, { v25_, v26_ }, { v25_ + v23_, v26_ + v24_ }, HUDDisplayElement.MOVE_ANIMATION_DURATION), 0)
	v27_:addCallback(self.onAnimateVisibilityFinished, false)
	v27_:start()
	self.animation = v27_
end

-- Local values: startX, startY, sequence
function HUDDisplayElement:animateShow()
	HUDDisplayElement:superClass().setVisible(self, true)
	local v29_, v30_ = self:getPosition()
	local v31_ = TweenSequence.new(self)
	v31_:insertTween(MultiValueTween.new(self.setPosition, { v29_, v30_ }, { self.origX, self.origY }, HUDDisplayElement.MOVE_ANIMATION_DURATION), 0)
	v31_:addCallback(self.onAnimateVisibilityFinished, true)
	v31_:start()
	self.animation = v31_
end

function HUDDisplayElement:onAnimateVisibilityFinished(isVisible)
	if not isVisible then
		HUDDisplayElement:superClass().setVisible(self, isVisible)
	end
end
