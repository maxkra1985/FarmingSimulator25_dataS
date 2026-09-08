-- Local values: AITargetHotspot_mt
AITargetHotspot = {}
local AITargetHotspot_mt = Class(AITargetHotspot, MapHotspot)

-- Upvalues: AITargetHotspot_mt
-- Local values: self
function AITargetHotspot.new(customMt)
	-- upvalues: (copy) AITargetHotspot_mt
	local v3_ = MapHotspot.new(customMt or AITargetHotspot_mt)
	if Platform.isMobile then
		local v4_, v5_ = getNormalizedScreenValues(150, 150)
		v3_.width = v4_
		v3_.height = v5_
	else
		local v6_, v7_ = getNormalizedScreenValues(80, 80)
		v3_.width = v6_
		v3_.height = v7_
	end
	v3_.icon = g_overlayManager:createOverlay("mapHotspots.workerDirection", 0, 0, v3_.width, v3_.height)
	return v3_
end

function AITargetHotspot:getCategory()
	return MapHotspot.CATEGORY_MAP_UTILITY
end

function AITargetHotspot:getIsPersistent()
	return true
end

function AITargetHotspot:getRenderLast()
	return true
end
