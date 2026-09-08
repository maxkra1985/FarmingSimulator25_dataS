-- Local values: StatusBar_mt
StatusBar = {}
local StatusBar_mt = Class(StatusBar)

-- Upvalues: StatusBar_mt
-- Local values: self
function StatusBar.new(x, y, width, height, bgColor, valueColor, markerSize, custom_mt)
	-- upvalues: (copy) StatusBar_mt
	if custom_mt == nil then
		custom_mt = StatusBar_mt
	end
	local v10_ = setmetatable({}, custom_mt)
	v10_.value = 0
	v10_.isDisabled = false
	v10_.markerSize = markerSize
	v10_.width = width
	v10_.height = height
	v10_.x = x
	v10_.y = y
	v10_.overlayBackground = g_overlayManager:createOverlay(g_plainColorSliceId, x, y, width, height)
	v10_.overlayBackground:setColor(unpack(bgColor))
	v10_.overlayValue = g_overlayManager:createOverlay(g_plainColorSliceId, x, y, width, height)
	v10_.overlayValue:setColor(unpack(valueColor))
	if markerSize ~= nil then
		v10_.overlayMarker = g_overlayManager:createOverlay(g_plainColorSliceId, x - markerSize[1] / 2, y + (height - markerSize[2]) / 2, markerSize[1], markerSize[2])
		v10_.overlayMarker:setDimension(markerSize[1], markerSize[2])
		v10_.overlayMarker:setPosition(x - markerSize[1] / 2, y + (height - markerSize[2]) / 2)
		v10_.overlayMarker:setColor(unpack(valueColor))
	end
	v10_:setValue(0)
	return v10_
end

function StatusBar:delete()
	if self.overlayBackground ~= nil then
		self.overlayBackground:delete()
	end
	if self.overlayValue ~= nil then
		self.overlayValue:delete()
	end
	if self.overlayMarker ~= nil then
		self.overlayMarker:delete()
	end
end

function StatusBar:setDisabled(isDisabled)
	self.isDisabled = isDisabled
end

function StatusBar:setPosition(x, y)
	self.x = x
	self.y = y
	if self.overlayBackground ~= nil then
		self.overlayBackground:setPosition(x, y)
	end
	if self.overlayValue ~= nil then
		self.overlayValue:setPosition(x, y)
	end
	if self.overlayMarker ~= nil then
		self.overlayMarker:setPosition(x - self.markerSize[1] / 2, y + (self.height - self.markerSize[2]) / 2)
	end
end

function StatusBar:setColor(r, g, b, a)
	if self.overlayMarker ~= nil then
		self.overlayMarker:setColor(r, g, b, a)
	end
	if self.overlayValue ~= nil then
		self.overlayValue:setColor(r, g, b, a)
	end
end

-- Local values: markerPosX
function StatusBar:setValue(newValue)
	self.value = math.clamp(newValue, 0, 1)
	local v24_ = newValue * self.width
	self.overlayValue:setDimension(newValue * self.width, self.overlayValue.height)
	if self.overlayMarker ~= nil then
		self.overlayMarker:setPosition(self.x + v24_ - self.markerSize[1] / 2, self.overlayMarker.y)
	end
end

function StatusBar:render()
	self.overlayBackground:render()
	if not self.isDisabled then
		self.overlayValue:render()
		if self.overlayMarker ~= nil then
			self.overlayMarker:render()
		end
	end
end
