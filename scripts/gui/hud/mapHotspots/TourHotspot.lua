TourHotspot = {}
local TourHotspot_mt = Class(TourHotspot, MapHotspot)
function TourHotspot.new(customMt)
	local self = MapHotspot.new(customMt or TourHotspot_mt)
	if Platform.isMobile then
		self.width, self.height = getNormalizedScreenValues(90, 90)
	else
		self.width, self.height = getNormalizedScreenValues(50, 50)
	end
	local circleFilename = Utils.getFilename("$dataS/menu/hud/hud_elements.png", "")
	local circleUVs = GuiUtils.getUVs({ 48, 291, 256, 256 }, { 1024, 1024 })
	self.icon = Overlay.new(circleFilename, 0, 0, self.width, self.height)
	self.icon:setUVs(circleUVs)
	self.icon:setColor(0.5089, 0.016, 0.016, 1)
	self.forceNoRotation = true
	return self
end
function TourHotspot:getCategory()
	return MapHotspot.CATEGORY_TOUR
end
function TourHotspot:getIsPersistent()
	return true
end
function TourHotspot:getRenderLast()
	return true
end
function TourHotspot:render(x, y, rotation, small)
	local icon = self.icon
	if icon ~= nil then
		icon:setPosition(x, y)
		icon:setColor(nil, nil, nil, IngameMap.alpha)
		icon:render()
	end
end
