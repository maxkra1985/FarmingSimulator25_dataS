-- Local values: HUDSliderElement_mt
HUDSliderElement = {}
local HUDSliderElement_mt = Class(HUDSliderElement, HUDElement)

-- Upvalues: HUDSliderElement_mt
-- Local values: self
function HUDSliderElement.new(overlay, backgroundOverlay, touchAreaOffsetX, touchAreaOffsetY, touchAreaPressedGain, transAxis, minTrans, centerTrans, maxTrans, lockTrans)
	-- upvalues: (copy) HUDSliderElement_mt
	local v12_ = HUDSliderElement:superClass().new(overlay, nil, HUDSliderElement_mt)
	v12_.position = { overlay.x, overlay.y }
	v12_.size = { overlay.width, overlay.height }
	v12_.transAxis = transAxis
	v12_.minTrans = minTrans
	v12_.centerTrans = centerTrans
	v12_.maxTrans = maxTrans
	v12_.lockTrans = lockTrans
	v12_.speed = 0.0002
	v12_.backgroundOverlay = backgroundOverlay
	v12_.overlay = overlay
	v12_.moveToCenterPosition = false
	v12_.moveToCenterSpeedFactor = 1
	v12_.snapPositions = {}
	v12_.touchAreaDown = g_touchHandler:registerTouchAreaOverlay(backgroundOverlay, touchAreaOffsetX, touchAreaOffsetY, TouchHandler.TRIGGER_DOWN, v12_.onSliderDown, v12_)
	v12_.touchAreaAlways = g_touchHandler:registerTouchAreaOverlay(backgroundOverlay, touchAreaOffsetX, touchAreaOffsetY, TouchHandler.TRIGGER_ALWAYS, v12_.onSliderAlways, v12_)
	v12_.touchAreaUp = g_touchHandler:registerTouchAreaOverlay(backgroundOverlay, touchAreaOffsetX, touchAreaOffsetY, TouchHandler.TRIGGER_UP, v12_.onSliderUp, v12_)
	g_touchHandler:setAreaPressedSizeGain(v12_.touchAreaDown, touchAreaPressedGain)
	g_touchHandler:setAreaPressedSizeGain(v12_.touchAreaAlways, touchAreaPressedGain)
	g_touchHandler:setAreaPressedSizeGain(v12_.touchAreaUp, touchAreaPressedGain)
	return v12_
end

function HUDSliderElement:delete()
	if self.overlay ~= nil and not entityExists(self.overlay.overlayId) then
		self.overlay = nil
	end
	g_touchHandler:removeTouchArea(self.touchAreaDown)
	g_touchHandler:removeTouchArea(self.touchAreaAlways)
	g_touchHandler:removeTouchArea(self.touchAreaUp)
	HUDSliderElement:superClass().delete(self)
end

function HUDSliderElement:setTouchIsActive(state)
	g_touchHandler:setTouchAreaVisibility(self.touchAreaDown, state)
	g_touchHandler:setTouchAreaVisibility(self.touchAreaAlways, state)
	g_touchHandler:setTouchAreaVisibility(self.touchAreaUp, state)
end

function HUDSliderElement:setCallback(callback, callbackTarget)
	self.callback = callback
	self.callbackTarget = callbackTarget
end

function HUDSliderElement:addSnapPosition(position)
	local v21_ = self.snapPositions
	table.insert(v21_, position)
end

-- Local values: i
function HUDSliderElement:clearSnapPositions()
	for v23_ = 1, #self.snapPositions do
		self.snapPositions[v23_] = nil
	end
end

function HUDSliderElement:resetSlider()
	self.moveToCenterPosition = false
	self:setAxisPosition(self.centerTrans)
end

-- Local values: curTouchPosition
function HUDSliderElement:onSliderDown(posX, posY, isCancel)
	local v28_ = self:getAxisPosition(posX, posY) - self:getAxisPosition(self.parent:getPosition())
	local v29_ = self.size
	self:setAxisPosition(v28_ - self:getAxisPosition(unpack(v29_)) / 2)
	self.startOverlayPos = self:getAxisPosition(self:getPosition()) - self:getAxisPosition(self.parent:getPosition())
	self.lastTouchPosition = self:getAxisPosition(posX, posY)
	self.moveToCenterPosition = false
end

-- Local values: curTouchPosition, touchOffset
function HUDSliderElement:onSliderAlways(posX, posY, isCancel)
	local v33_ = self:getAxisPosition(posX, posY) - self.lastTouchPosition
	self:setAxisPosition(self.startOverlayPos + v33_)
end

function HUDSliderElement:onSliderUp(posX, posY, isCancel)
	if #self.snapPositions == 0 and (self.lockTrans == nil or self:getAxisPosition(self:getPosition()) ~= self.lockTrans + self:getAxisPosition(self.parent:getPosition())) then
		self.moveToCenterPosition = true
	end
end

function HUDSliderElement:getAxisPosition(posX, posY)
	if self.transAxis == 1 then
		return posX
	else
		return self.transAxis ~= 2 and 0 or posY
	end
end

-- Local values: closestSnap, minDistance, i, snap, diff
function HUDSliderElement:setAxisPosition(pos, noCallback)
	if #self.snapPositions > 0 then
		local v41_ = math.huge
		local v42_ = -1
		for v43_ = 1, #self.snapPositions do
			local v44_ = pos - self.snapPositions[v43_]
			local v45_ = math.abs(v44_)
			if v45_ < v41_ then
				v42_ = v43_
				v41_ = v45_
			end
		end
		pos = self.snapPositions[v42_]
	end
	local v46_ = self.minTrans
	local v47_ = self.maxTrans
	local v48_ = math.clamp(pos, v46_, v47_)
	if self.callback ~= nil and noCallback ~= true then
		v48_ = self.callback(self.callbackTarget, (v48_ - self.minTrans) / (self.maxTrans - self.minTrans)) or v48_
	end
	local v49_ = self:getAxisPosition(self.parent:getPosition()) + v48_
	if self.transAxis == 1 then
		self:setPosition(v49_, nil)
	elseif self.transAxis == 2 then
		self:setPosition(nil, v49_)
	end
end

function HUDSliderElement:setMoveToCenterSpeedFactor(moveToCenterSpeedFactor)
	self.moveToCenterSpeedFactor = moveToCenterSpeedFactor
end

-- Local values: curPosition, speedFactor, direction, limit, newPosition
function HUDSliderElement:update(dt)
	if self.moveToCenterPosition then
		local v54_ = self:getAxisPosition(self:getPosition()) - self:getAxisPosition(self.parent:getPosition())
		if v54_ == self.centerTrans then
			self.moveToCenterPosition = false
			return
		end
		local v55_ = self.centerTrans - v54_
		local v56_ = 1 + math.abs(v55_)
		local v57_ = math.pow(v56_, 3) * self.moveToCenterSpeedFactor
		local v58_ = self.centerTrans - v54_
		local v59_ = math.sign(v58_)
		self:setAxisPosition(((v59_ == 1 and math.min or math.max)(v54_ + v59_ * dt * self.speed * v57_, self.centerTrans)))
	end
end

function HUDSliderElement:setScale(scaleWidth, scaleHeight)
	HUDSliderElement:superClass().setScale(self, scaleWidth, scaleHeight)
	self.size[1] = self.overlay.width
	self.size[2] = self.overlay.height
end

function HUDSliderElement:setRange(minTrans, centerTrans, maxTrans, lockTrans)
	self.minTrans = minTrans
	self.centerTrans = centerTrans
	self.maxTrans = maxTrans
	self.lockTrans = lockTrans
end
