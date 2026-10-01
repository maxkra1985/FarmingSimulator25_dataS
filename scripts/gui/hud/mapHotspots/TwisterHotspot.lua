TwisterHotspot = {}
local TwisterHotspot_mt = Class(TwisterHotspot, MapHotspot)
function TwisterHotspot.new(customMt)
	local self = MapHotspot.new(customMt or TwisterHotspot_mt)
	self.width, self.height = getNormalizedScreenValues(50, 50)
	self.icon = g_overlayManager:createOverlay("mapHotspots.twister", 0, 0, self.width, self.height)
	self.forceNoRotation = true
	return self
end
function TwisterHotspot:delete()
	TwisterHotspot:superClass().delete(self)
	if self.icon ~= nil then
		self.icon:delete()
		self.icon = nil
	end
end
function TwisterHotspot:getWidth()
	if self.icon ~= nil then
		return self.icon.width
	else
		return 0
	end
end
function TwisterHotspot:getHeight()
	if self.icon ~= nil then
		return self.icon.height
	else
		return 0
	end
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
function TwisterHotspot:render(x, y, rotation, small)
	local icon = self.icon
	if icon ~= nil then
		icon:setPosition(x, y)
		icon:setColor(nil, nil, nil, self.isBlinking and self:getCanBlink() and IngameMap.alpha or 1)
		icon:render()
	end
end
function TwisterHotspot:hasMouseOverlap(x, y)
	return false
end
