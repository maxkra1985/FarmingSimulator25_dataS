-- Local values: MissionHotspot_mt
MissionHotspot = {}
local MissionHotspot_mt = Class(MissionHotspot, MapHotspot)

-- Upvalues: MissionHotspot_mt
-- Local values: self
function MissionHotspot.new(customMt)
	-- upvalues: (copy) MissionHotspot_mt
	local v3_ = MapHotspot.new(customMt or MissionHotspot_mt)
	local v4_, v5_ = getNormalizedScreenValues(50, 50)
	v3_.width = v4_
	v3_.height = v5_
	v3_.icon = g_overlayManager:createOverlay("mapHotspots.contract", 0, 0, v3_.width, v3_.height)
	return v3_
end

function MissionHotspot:getCategory()
	return MapHotspot.CATEGORY_MISSION
end

function MissionHotspot:getIsPersistent()
	return true
end

function MissionHotspot:getRenderLast()
	return true
end

-- Local values: icon
function MissionHotspot:render(x, y, rotation, small)
	local v9_ = self.icon
	if v9_ ~= nil then
		v9_:setPosition(x, y)
		if self.isBlinking and self:getCanBlink() then
			v9_:setColor(nil, nil, nil, IngameMap.alpha)
		end
		v9_:render()
	end
end
