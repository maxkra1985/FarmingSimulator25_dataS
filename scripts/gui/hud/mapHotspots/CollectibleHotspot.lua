-- Local values: CollectibleHotspot_mt
CollectibleHotspot = {}
local CollectibleHotspot_mt = Class(CollectibleHotspot, MapHotspot)

-- Upvalues: CollectibleHotspot_mt
-- Local values: self, _
function CollectibleHotspot.new(collectible)
	-- upvalues: (copy) CollectibleHotspot_mt
	local v3_ = MapHotspot.new(CollectibleHotspot_mt)
	local v4_, v5_ = getNormalizedScreenValues(40, 40)
	v3_.width = v4_
	v3_.height = v5_
	v3_.icon = g_overlayManager:createOverlay("mapHotspots.other", 0, 0, v3_.width, v3_.height)
	v3_.color[1] = 0.8
	v3_.color[2] = 0.5
	v3_.color[3] = 0
	local v6_, _, v7_ = getWorldTranslation(collectible.node)
	v3_.worldX = v6_
	v3_.worldZ = v7_
	return v3_
end

function CollectibleHotspot:getCategory()
	return MapHotspot.CATEGORY_OTHER
end

function CollectibleHotspot:hasMouseOverlap(x, y)
	return false
end
