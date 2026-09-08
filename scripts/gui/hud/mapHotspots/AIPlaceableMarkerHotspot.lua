-- Local values: AIPlaceableMarkerHotspot_mt
AIPlaceableMarkerHotspot = {}
AIPlaceableMarkerHotspot.SLICE_ID = "mapHotspots.missionBorder"
local AIPlaceableMarkerHotspot_mt = Class(AIPlaceableMarkerHotspot, MapHotspot)

-- Upvalues: AIPlaceableMarkerHotspot_mt
-- Local values: self
function AIPlaceableMarkerHotspot.new(customMt)
	-- upvalues: (copy) AIPlaceableMarkerHotspot_mt
	local v3_ = MapHotspot.new(customMt or AIPlaceableMarkerHotspot_mt)
	if Platform.isMobile then
		local v4_, v5_ = getNormalizedScreenValues(90, 90)
		v3_.width = v4_
		v3_.height = v5_
	else
		local v6_, v7_ = getNormalizedScreenValues(50, 50)
		v3_.width = v6_
		v3_.height = v7_
	end
	v3_.icon = g_overlayManager:createOverlay(AIPlaceableMarkerHotspot.SLICE_ID, 0, 0, v3_.width, v3_.height)
	v3_.isBlinking = not Platform.isMobile
	return v3_
end

function AIPlaceableMarkerHotspot:getCategory()
	return MapHotspot.CATEGORY_MAP_UTILITY
end

function AIPlaceableMarkerHotspot:getIsPersistent()
	return true
end

function AIPlaceableMarkerHotspot:getRenderLast()
	return true
end
