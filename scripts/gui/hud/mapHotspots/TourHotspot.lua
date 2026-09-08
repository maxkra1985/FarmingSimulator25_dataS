-- Local values: TourHotspot_mt
TourHotspot = {}
local TourHotspot_mt = Class(TourHotspot, MapHotspot)

-- Upvalues: TourHotspot_mt
-- Local values: self, circleFilename, circleUVs
function TourHotspot.new(customMt)
	-- upvalues: (copy) TourHotspot_mt
	local v3_ = MapHotspot.new(customMt or TourHotspot_mt)
	if Platform.isMobile then
		local v4_, v5_ = getNormalizedScreenValues(90, 90)
		v3_.width = v4_
		v3_.height = v5_
	else
		local v6_, v7_ = getNormalizedScreenValues(50, 50)
		v3_.width = v6_
		v3_.height = v7_
	end
	local v8_ = Utils.getFilename("$dataS/menu/hud/hud_elements.png", "")
	local v9_ = GuiUtils.getUVs({
		48,
		291,
		256,
		256
	}, { 1024, 1024 })
	v3_.icon = Overlay.new(v8_, 0, 0, v3_.width, v3_.height)
	v3_.icon:setUVs(v9_)
	v3_.icon:setColor(0.5089, 0.016, 0.016, 1)
	v3_.forceNoRotation = true
	return v3_
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

-- Local values: icon
function TourHotspot:render(x, y, rotation, small)
	local v13_ = self.icon
	if v13_ ~= nil then
		v13_:setPosition(x, y)
		v13_:setColor(nil, nil, nil, IngameMap.alpha)
		v13_:render()
	end
end
