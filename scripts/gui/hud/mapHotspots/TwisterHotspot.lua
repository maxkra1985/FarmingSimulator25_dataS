-- Local values: TwisterHotspot_mt
TwisterHotspot = {}
local TwisterHotspot_mt = Class(TwisterHotspot, MapHotspot)

-- Upvalues: TwisterHotspot_mt
-- Local values: self
function TwisterHotspot.new(customMt)
	-- upvalues: (copy) TwisterHotspot_mt
	local v3_ = MapHotspot.new(customMt or TwisterHotspot_mt)
	local v4_, v5_ = getNormalizedScreenValues(50, 50)
	v3_.width = v4_
	v3_.height = v5_
	v3_.icon = g_overlayManager:createOverlay("mapHotspots.twister", 0, 0, v3_.width, v3_.height)
	v3_.forceNoRotation = true
	return v3_
end

function TwisterHotspot:delete()
	TwisterHotspot:superClass().delete(self)
	if self.icon ~= nil then
		self.icon:delete()
		self.icon = nil
	end
end

function TwisterHotspot:getWidth()
	return self.icon == nil and 0 or self.icon.width
end

function TwisterHotspot:getHeight()
	return self.icon == nil and 0 or self.icon.height
end

function TwisterHotspot:getCategory()
	return MapHotspot.CATEGORY_OTHER
end

function TwisterHotspot:getIsPersistent()
	return false
end

function TwisterHotspot:getRenderLast()
	return false
end

-- Local values: icon
function TwisterHotspot:render(x, y, rotation, small)
	local v12_ = self.icon
	if v12_ ~= nil then
		v12_:setPosition(x, y)
		v12_:setColor(nil, nil, nil, self.isBlinking and (self:getCanBlink() and IngameMap.alpha) or 1)
		v12_:render()
	end
end

function TwisterHotspot:hasMouseOverlap(x, y)
	return false
end
