-- Local values: FerryHotspot_mt
FerryHotspot = {}
local FerryHotspot_mt = Class(FerryHotspot, MapHotspot)

-- Upvalues: FerryHotspot_mt
-- Local values: self
function FerryHotspot.new(ferry, customMt)
	-- upvalues: (copy) FerryHotspot_mt
	local v4_ = MapHotspot.new(customMt or FerryHotspot_mt)
	v4_.ferry = ferry
	local v5_, v6_ = getNormalizedScreenValues(50, 50)
	v4_.width = v5_
	v4_.height = v6_
	v4_.icon = g_overlayManager:createOverlay("mapHotspots.ferry", 0, 0, v4_.width, v4_.height)
	v4_.clickArea = MapHotspot.getClickArea({
		9,
		13,
		82,
		82
	}, { 100, 100 }, 0)
	return v4_
end

function FerryHotspot:delete()
	FerryHotspot:superClass().delete(self)
	if self.icon ~= nil then
		self.icon:delete()
		self.icon = nil
	end
end

function FerryHotspot:getCategory()
	return MapHotspot.CATEGORY_OTHER
end

function FerryHotspot:getIsPersistent()
	return false
end

function FerryHotspot:getRenderLast()
	return false
end

function FerryHotspot:getName()
	return nil
end

function FerryHotspot:getBeVisited()
	return false
end

function FerryHotspot:getTeleportWorldPosition()
	return nil
end

function FerryHotspot:hasMouseOverlap(x, y)
	return false
end
FerryHotspot.getWorldPosition = MapHotspot.getWorldPosition
FerryHotspot.getWorldRotation = MapHotspot.getWorldRotation
FerryHotspot.setScale = MapHotspot.setScale
FerryHotspot.render = MapHotspot.render
