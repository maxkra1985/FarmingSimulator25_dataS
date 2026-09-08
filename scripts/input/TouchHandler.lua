-- Local values: TouchHandler_mt
TouchHandler = {}
local TouchHandler_mt = Class(TouchHandler)
TouchHandler.DRAW_DEBUG = false
TouchHandler.TRIGGER_DOWN = 1
TouchHandler.TRIGGER_ALWAYS = 2
TouchHandler.TRIGGER_UP = 3
TouchHandler.GESTURE_AXIS_X = 1
TouchHandler.GESTURE_AXIS_Y = 2
TouchHandler.GESTURE_DOUBLE_TAP = 3
TouchHandler.GESTURE_PINCH = 4
TouchHandler.DOUBLE_TAP_TIME = 250
TouchHandler.MOUSE_TOUCH_ID = -1
function TouchHandler.new()
	-- upvalues: (copy) TouchHandler_mt
	local v2_ = TouchHandler_mt
	local v3_ = setmetatable({}, v2_)
	v3_.areas = {}
	v3_.gestureListener = {}
	v3_.pinchGesture = {}
	v3_.toTrigger = {}
	v3_.lastDownTime = 0
	v3_.lastUpTime = 0
	local v4_, v5_ = getNormalizedScreenValues(1.5, 1.5)
	v3_.debugLineWidth = v4_
	v3_.debugLineHeight = v5_
	local v6_, v7_ = getNormalizedScreenValues(3, 3)
	v3_.debugPointWidth = v6_
	v3_.debugPointHeight = v7_
	v3_.debugPoints = {}
	v3_.contextName = nil
	v3_.isActiveOnTopOfGUI = false
	return v3_
end

-- Local values: wasInsideAnyArea, toTrigger, i, area, areaPosX, areaPosY, areaWidth, areaHeight, isInsideArea, isStart, isAlways, isEnd, i, isPinching, diff, diff
function TouchHandler:onTouchEvent(posX, posY, isDown, isUp, touchId)
	if TouchHandler.DRAW_DEBUG and isDown then
		self:addDebugPoint(posX, posY)
	end
	local v14_ = self.toTrigger
	local v15_ = false
	for v16_ = 1, #self.areas do
		local v17_ = self.areas[v16_]
		if v17_.lastTouchId == nil or v17_.lastTouchId == touchId then
			self:updateAreaPosition(v17_)
			local v18_, v19_, v20_, v21_ = self:getAreaDimensions(v17_)
			local v22_
			if v18_ < posX and (posX < v18_ + v20_ and v19_ < posY) then
				v22_ = posY < v19_ + v21_
			else
				v22_ = false
			end
			local v23_ = false
			local v24_ = false
			local v25_ = false
			if v22_ and (v17_.visibility and (v17_.contextName == self.contextName and (self.isActiveOnTopOfGUI or not g_gui:getIsGuiVisible()))) then
				if isUp then
					if v17_.isPressed then
						v17_.isPressed = false
						v17_.lastTouchId = nil
						v25_ = true
					end
				elseif isDown then
					v17_.isPressed = true
					v17_.lastTouchId = touchId
					v23_ = true
				elseif v17_.isPressed then
					v24_ = true
				end
				local v26_ = v17_.lastTouchPosition
				local v27_ = v17_.lastTouchPosition
				v26_[1] = posX
				v27_[2] = posY
				v15_ = true
			elseif v17_.isPressed then
				v17_.isPressed = false
				v17_.lastTouchId = nil
				v17_.isCancel = true
				v25_ = true
			end
			if v23_ and v17_.triggerType == TouchHandler.TRIGGER_DOWN or (v24_ and v17_.triggerType == TouchHandler.TRIGGER_ALWAYS or v25_ and v17_.triggerType == TouchHandler.TRIGGER_UP) then
				v14_[#v14_ + 1] = v17_
			end
		end
	end
	for v28_ = 1, #v14_ do
		self:raiseCallback(v14_[v28_], posX, posY)
		v14_[v28_].isCancel = false
		v14_[v28_] = nil
	end
	if v15_ then
		self:onPinchUpEvent(touchId)
	else
		if isDown then
			self.lastPositionX = posX
			self.lastPositionY = posY
			self.lastDownTime = g_time
		elseif isUp then
			self.lastPositionX = nil
			self.lastPositionY = nil
			if self.lastUpTime ~= nil and (self.lastDownTime > self.lastUpTime and g_time - self.lastUpTime < TouchHandler.DOUBLE_TAP_TIME) then
				self:raiseGestureEvent(TouchHandler.GESTURE_DOUBLE_TAP)
			end
			self.lastUpTime = g_time
			self.lastUpId = touchId
		end
		local v29_ = false
		if isDown then
			self:onPinchDownEvent(touchId)
		elseif isUp then
			self:onPinchUpEvent(touchId)
		else
			v29_ = self:onPinchUpdateEvent(posX, posY, touchId)
		end
		if v29_ then
			self.lastPositionX = nil
			self.lastPositionY = nil
			return
		end
		if self.lastPositionX ~= nil then
			local v30_ = posX - self.lastPositionX
			self:raiseGestureEvent(TouchHandler.GESTURE_AXIS_X, v30_)
			self.lastPositionX = posX
		end
		if self.lastPositionY ~= nil then
			local v31_ = posY - self.lastPositionY
			self:raiseGestureEvent(TouchHandler.GESTURE_AXIS_Y, v31_)
			self.lastPositionY = posY
			return
		end
	end
end

function TouchHandler:onPinchDownEvent(touchId)
	if self.lastPositionId ~= nil and self.lastPositionId ~= touchId then
		self.pinchGesture[1] = {
			["touchId"] = touchId
		}
		self.pinchGesture[2] = {
			["touchId"] = self.lastPositionId
		}
	end
	self.lastPositionId = touchId
end

-- Local values: pinch1, pinch2, distance, offset, pinchCenterX, pinchCenterY, curPinch
function TouchHandler:onPinchUpdateEvent(posX, posY, touchId)
	local v38_ = self.pinchGesture[1]
	local v39_ = self.pinchGesture[2]
	if v38_ == nil or v39_ == nil then
		return false
	end
	if v38_.touchId == touchId and (v38_.lastX ~= nil and v39_.lastX ~= nil) then
		local v40_ = MathUtil.vector2Length(v38_.lastX - v39_.lastX, v38_.lastY - v39_.lastY)
		local v41_ = (v38_.lastDistance or v40_) - v40_
		local v42_ = v39_.lastX + (v38_.lastX - v39_.lastX) * 0.5
		local v43_ = v39_.lastY + (v38_.lastY - v39_.lastY) * 0.5
		self:raiseGestureEvent(TouchHandler.GESTURE_PINCH, v41_, v42_, v43_, v40_)
		v38_.lastDistance = v40_
	end
	if v38_.touchId == touchId then
		v39_ = v38_ or v39_
	end
	v39_.lastX = posX
	v39_.lastY = posY
	return true
end

-- Local values: i
function TouchHandler:onPinchUpEvent(touchId)
	for v46_ = 1, 2 do
		if self.pinchGesture[v46_] == nil then
			self.lastPositionId = nil
		elseif self.pinchGesture[v46_].touchId == touchId then
			if v46_ == 1 then
				self.lastPositionId = self.pinchGesture[2].touchId
			else
				self.lastPositionId = self.pinchGesture[1].touchId
			end
			self.pinchGesture[1] = nil
			self.pinchGesture[2] = nil
			return
		end
	end
end

-- Local values: listener
function TouchHandler:registerGestureListener(gestureType, callback, callbackTarget)
	local v51_ = {
		["gestureType"] = gestureType,
		["callback"] = callback,
		["callbackTarget"] = callbackTarget,
		["contextName"] = self.contextName
	}
	local v52_ = self.gestureListener
	table.insert(v52_, v51_)
	return v51_
end

function TouchHandler:removeGestureListener(listener)
	table.removeElement(self.gestureListener, listener)
end
function TouchHandler.raiseGestureEvent(p55_, p56_, ...)
	for _, v57_ in ipairs(p55_.gestureListener) do
		if v57_.contextName == p55_.contextName and v57_.gestureType == p56_ then
			v57_.callback(v57_.callbackTarget, ...)
		end
	end
end

-- Local values: area
function TouchHandler:registerTouchArea(posX, posY, sizeX, sizeY, areaOffsetX, areaOffsetY, triggerType, callback, callbackTarget, extraArguments)
	local v69_ = {
		["posX"] = posX,
		["posY"] = posY,
		["sizeX"] = sizeX,
		["sizeY"] = sizeY,
		["areaOffsetX"] = areaOffsetX
	}
	if type(areaOffsetX) == "number" then
		v69_.areaOffsetX = { areaOffsetX / 2, areaOffsetX / 2 }
	end
	v69_.areaOffsetY = areaOffsetY
	if type(areaOffsetY) == "number" then
		v69_.areaOffsetY = { areaOffsetY / 2, areaOffsetY / 2 }
	end
	v69_.isPressedSizeGain = 1
	v69_.isPressedSizeGained = v69_.isPressedSizeGain - 1
	v69_.absoluteDimensions = {
		0,
		0,
		0,
		0
	}
	v69_.absoluteDimensionsPressed = {
		0,
		0,
		0,
		0
	}
	self:updateDimensions(v69_)
	v69_.visibility = true
	v69_.isPressed = false
	v69_.lastTouchPosition = { posX + sizeX * 0.5, posY + sizeY * 0.5 }
	v69_.triggerType = triggerType
	v69_.callback = callback
	v69_.callbackTarget = callbackTarget
	v69_.extraArguments = extraArguments or {}
	v69_.contextName = self.contextName
	local v70_ = self.areas
	table.insert(v70_, v69_)
	return v69_
end

-- Local values: area
function TouchHandler:registerTouchAreaOverlay(overlay, areaOffsetX, areaOffsetY, triggerType, callback, callbackTarget, extraArguments)
	local v79_ = self:registerTouchArea(overlay.x, overlay.y, overlay.width, overlay.height, areaOffsetX, areaOffsetY, triggerType, callback, callbackTarget, extraArguments)
	v79_.overlay = overlay
	return v79_
end

function TouchHandler:resetPendingTouchAreaInput(area)
	if area.triggerType == TouchHandler.TRIGGER_UP and area.isPressed then
		self:raiseCallback(area, area.lastTouchPosition[1], area.lastTouchPosition[2])
		area.isPressed = false
		area.lastTouchId = nil
	end
end

function TouchHandler:removeTouchArea(area)
	self:resetPendingTouchAreaInput(area)
	table.removeElement(self.areas, area)
end

-- Local values: i
function TouchHandler:setCustomContext(name, isActiveOnTopOfGUI)
	if name ~= self.contextName then
		for v87_ = 1, #self.areas do
			if self.areas[v87_].contextName == self.contextName then
				self:resetPendingTouchAreaInput(self.areas[v87_])
			end
		end
	end
	self.contextName = name
	self.isActiveOnTopOfGUI = Utils.getNoNil(isActiveOnTopOfGUI, false)
end

function TouchHandler:revertCustomContext()
	self:setCustomContext(nil, false)
end

function TouchHandler:getAreaDimensions(area, pressed)
	if pressed == nil then
		pressed = area.isPressed
	end
	if pressed then
		local v91_ = area.absoluteDimensionsPressed
		return unpack(v91_)
	else
		local v92_ = area.absoluteDimensions
		return unpack(v92_)
	end
end

function TouchHandler:removeAllTouchAreas()
	self.areas = {}
end

function TouchHandler:setAreaPosition(area, posX, posY, sizeX, sizeY)
	area.posX = posX
	area.posY = posY
	area.sizeX = sizeX
	area.sizeY = sizeY
	self:updateDimensions(area)
end

function TouchHandler:setAreaPressedSizeGain(area, gain)
	area.isPressedSizeGain = gain
	area.isPressedSizeGained = gain - 1
	self:updateDimensions(area)
end

-- Local values: x, y, w, h, gainPos, gainSize
function TouchHandler:updateDimensions(area)
	local v104_ = area.posX - area.areaOffsetX[1] * area.sizeX
	local v105_ = area.posY - area.areaOffsetY[1] * area.sizeY
	local v106_ = area.sizeX + (area.sizeX * area.areaOffsetX[1] + area.sizeX * area.areaOffsetX[2])
	local v107_ = area.sizeY + (area.sizeY * area.areaOffsetY[1] + area.sizeY * area.areaOffsetY[2])
	area.absoluteDimensions[1] = v104_
	area.absoluteDimensions[2] = v105_
	area.absoluteDimensions[3] = v106_
	area.absoluteDimensions[4] = v107_
	local v108_ = v106_ * area.isPressedSizeGained * 0.5
	local v109_ = v107_ * area.isPressedSizeGained * 0.5 * g_screenAspectRatio
	local v110_ = math.min(v108_, v109_)
	local v111_ = v106_ * area.isPressedSizeGain - v106_
	local v112_ = (v107_ * area.isPressedSizeGain - v107_) * g_screenAspectRatio
	local v113_ = math.min(v111_, v112_)
	area.absoluteDimensionsPressed[1] = v104_ - v110_ / g_screenAspectRatio
	area.absoluteDimensionsPressed[2] = v105_ - v110_
	area.absoluteDimensionsPressed[3] = v106_ + v113_ / g_screenAspectRatio
	area.absoluteDimensionsPressed[4] = v107_ + v113_
end

-- Local values: overlay
function TouchHandler:updateAreaPosition(area)
	if area.overlay ~= nil then
		local v116_ = area.overlay
		self:setAreaPosition(area, v116_.x, v116_.y, v116_.width, v116_.height)
	end
end

function TouchHandler:setTouchAreaVisibility(area, visibility)
	area.visibility = visibility
end

function TouchHandler:raiseCallback(area, posX, posY)
	local v122_ = area.callback
	local v123_ = area.callbackTarget
	local v124_ = area.isCancel
	local v125_ = area.extraArguments
	v122_(v123_, posX, posY, v124_, unpack(v125_))
end

-- Local values: i, point
function TouchHandler:update(dt)
	if TouchHandler.DRAW_DEBUG then
		for v128_, v129_ in pairs(self.debugPoints) do
			v129_.time = v129_.time - dt
			if v129_.time < 0 then
				table.remove(self.debugPoints, v128_)
			end
		end
	end
end

-- Local values: i, area, areaPosX, areaPosY, areaWidth, areaHeight, _, point
function TouchHandler:draw()
	if TouchHandler.DRAW_DEBUG then
		if not g_gui:getIsGuiVisible() then
			for v131_ = 1, #self.areas do
				local v132_ = self.areas[v131_]
				if v132_.visibility and v132_.contextName == self.contextName then
					local v133_, v134_, v135_, v136_ = self:getAreaDimensions(v132_, false)
					drawOutlineRect(v133_, v134_, v135_, v136_, self.debugLineWidth, self.debugLineHeight, 1, 0, 0, 1)
					if v132_.isPressed then
						local v137_, v138_, v139_, v140_ = self:getAreaDimensions(v132_, true)
						drawOutlineRect(v137_, v138_, v139_, v140_, self.debugLineWidth, self.debugLineHeight, 0, 1, 0, 1)
					end
				end
			end
		end
		for _, v141_ in pairs(self.debugPoints) do
			drawPoint(v141_.x, v141_.y, self.debugPointWidth, self.debugPointHeight, 0, 1, 0, 1)
		end
	end
end

function TouchHandler:addDebugPoint(x, y)
	local v145_ = self.debugPoints
	table.insert(v145_, {
		["time"] = 5000,
		["x"] = x,
		["y"] = y
	})
end
