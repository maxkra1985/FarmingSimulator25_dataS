-- Local values: RoundStatusBar_mt
RoundStatusBar = {}
local RoundStatusBar_mt = Class(RoundStatusBar)

-- Upvalues: RoundStatusBar_mt
-- Local values: self
function RoundStatusBar.new(frontSliceId, valueSliceId, markerSliceId, x, y, width, height, valueWidth, valueHeight, radius, color, bgColor, valueColor, markerSize, custom_mt)
	-- upvalues: (copy) RoundStatusBar_mt
	if custom_mt == nil then
		custom_mt = RoundStatusBar_mt
	end
	local v16_ = setmetatable({}, custom_mt)
	v16_.value = 0
	v16_.x = x
	v16_.y = y
	v16_.width = width
	v16_.height = height
	v16_.radius = radius
	v16_.offsetX = (width - valueWidth) / 2
	v16_.offsetY = (height - valueHeight) / 2
	if frontSliceId ~= nil then
		v16_.overlayBackground = g_overlayManager:createOverlay(frontSliceId, x, y, width, height)
	end
	v16_.overlayBackground1 = g_overlayManager:createOverlay(valueSliceId, x + v16_.offsetX, y + v16_.offsetY, valueWidth, valueHeight)
	v16_.overlayBackground1:setColor(unpack(bgColor))
	v16_.overlayBackground2 = g_overlayManager:createOverlay(valueSliceId, x + v16_.offsetX, y + v16_.offsetY, valueWidth, valueHeight)
	v16_.overlayBackground2:setColor(unpack(bgColor))
	v16_.overlayValue1 = g_overlayManager:createOverlay(valueSliceId, x + v16_.offsetX, y + v16_.offsetY, valueWidth, valueHeight)
	v16_.overlayValue1:setColor(unpack(valueColor))
	v16_.overlayValue2 = g_overlayManager:createOverlay(valueSliceId, x + v16_.offsetX, y + v16_.offsetY, valueWidth, valueHeight)
	v16_.overlayValue2:setColor(unpack(valueColor))
	if markerSliceId ~= nil then
		v16_.overlayMarker = g_overlayManager:createOverlay(valueSliceId, x, y, markerSize[1], markerSize[2])
		v16_.overlayMarker:setColor(unpack(valueColor))
	end
	v16_.overlayValue2:setRotation(3.141592653589793, v16_.overlayValue2.width * 0.5, v16_.overlayValue2.height * 0.5)
	v16_:setValue(0)
	return v16_
end

function RoundStatusBar:delete()
	if self.overlayFront ~= nil then
		self.overlayFront:delete()
	end
	if self.overlayBackground1 ~= nil then
		self.overlayBackground1:delete()
	end
	if self.overlayBackground2 ~= nil then
		self.overlayBackground2:delete()
	end
	if self.overlayValue1 ~= nil then
		self.overlayValue1:delete()
	end
	if self.overlayValue2 ~= nil then
		self.overlayValue2:delete()
	end
	if self.overlayMarker ~= nil then
		self.overlayMarker:delete()
	end
end

function RoundStatusBar:setPosition(x, y)
	self.x = Utils.getNoNil(x, self.x)
	self.y = Utils.getNoNil(y, self.y)
	self.overlayValue1:setPosition(self.x + self.offsetX, self.y + self.offsetY)
	self.overlayValue2:setPosition(self.x + self.offsetX, self.y + self.offsetY)
	self.overlayBackground1:setPosition(self.x + self.offsetX, self.y + self.offsetY)
	self.overlayBackground2:setPosition(self.x + self.offsetX, self.y + self.offsetY)
	if self.overlayFront ~= nil then
		self.overlayFront:setPosition(self.x, self.y)
	end
end

-- Local values: markerPosX, markerPosY
function RoundStatusBar:setValue(newValue)
	self.value = math.clamp(newValue, 0, 1)
	local v23_ = self.overlayValue1
	local v24_ = (1 - self.value) * 360
	v23_:setRotation(math.rad(v24_), self.overlayValue1.width * 0.5, self.overlayValue1.height * 0.5)
	local v25_ = self.overlayBackground1
	local v26_ = 180 + -self.value * 360
	v25_:setRotation(math.rad(v26_), self.overlayBackground1.width * 0.5, self.overlayBackground1.height * 0.5)
	if self.overlayMarker ~= nil then
		local v27_ = (1 - self.value) * 360 + 90
		local v28_ = math.rad(v27_)
		local v29_ = math.cos(v28_) * self.radius[1]
		local v30_ = (1 - self.value) * 360 + 90
		local v31_ = math.rad(v30_)
		local v32_ = math.sin(v31_) * self.radius[2]
		self.overlayMarker:setPosition(self.x + self.width / 2 - self.overlayMarker.width / 2 + v29_, self.y + self.height / 2 - self.overlayMarker.height / 2 + v32_)
	end
end

function RoundStatusBar:render()
	if self.value > 0.5 then
		self.overlayBackground2:render()
	end
	self.overlayValue1:render()
	if self.value > 0.5 then
		self.overlayValue2:render()
	else
		self.overlayBackground2:render()
		self.overlayBackground1:render()
	end
	if self.overlayFront ~= nil then
		self.overlayFront:render()
	end
	if self.overlayMarker ~= nil then
		self.overlayMarker:render()
	end
end
