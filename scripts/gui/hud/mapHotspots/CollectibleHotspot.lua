CollectibleHotspot = {}
local CollectibleHotspot_mt = Class(CollectibleHotspot, MapHotspot)
function CollectibleHotspot.new(collectible)
	local self = MapHotspot.new(CollectibleHotspot_mt)
	self.width, self.height = getNormalizedScreenValues(40, 40)
	self.icon = g_overlayManager:createOverlay("mapHotspots.other", 0, 0, self.width, self.height)
	self.color[1] = 0.8
	self.color[2] = 0.5
	self.color[3] = 0
	local _ = nil
	self.worldX, _, self.worldZ = getWorldTranslation(collectible.node)
	return self
end
function CollectibleHotspot:getCategory()
	return MapHotspot.CATEGORY_OTHER
end
function CollectibleHotspot:hasMouseOverlap(x, y)
	return false
end
