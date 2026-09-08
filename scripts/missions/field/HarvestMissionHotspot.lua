-- Local values: HarvestMissionHotspot_mt
HarvestMissionHotspot = {}
local HarvestMissionHotspot_mt = Class(HarvestMissionHotspot, MapHotspot)

-- Upvalues: HarvestMissionHotspot_mt
-- Local values: self
function HarvestMissionHotspot.new(customMt)
	-- upvalues: (copy) HarvestMissionHotspot_mt
	local v3_ = MapHotspot.new(customMt or HarvestMissionHotspot_mt)
	local v4_, v5_ = getNormalizedScreenValues(50, 50)
	v3_.width = v4_
	v3_.height = v5_
	v3_.circle = g_overlayManager:createOverlay("mapHotspots.circle", 0, 0, v3_.width, v3_.height)
	v3_.circle:setColor(0.5089, 0.016, 0.016, 1)
	v3_.worldRadius = 50
	v3_.forceNoRotation = true
	return v3_
end

function HarvestMissionHotspot:delete()
	HarvestMissionHotspot:superClass().delete(self)
	if self.circle ~= nil then
		self.circle:delete()
		self.circle = nil
	end
end

function HarvestMissionHotspot:setWorldRadius(worldRadius)
	self.worldRadius = worldRadius
end

-- Local values: ingameMap, layout, mapWidth, mapHeight, width, height
function HarvestMissionHotspot:postUpdate(dt)
	local v10_ = g_currentMission.hud:getIngameMap()
	local v11_, v12_ = v10_.layout:getMapSize()
	local v13_ = self.worldRadius / v10_.worldSizeX * v11_
	local v14_ = self.worldRadius / v10_.worldSizeZ * v12_
	if self.circle ~= nil then
		self.circle:setDimension(v13_, v14_)
	end
end

function HarvestMissionHotspot:getWidth()
	return self.circle == nil and 0 or self.circle.width
end

function HarvestMissionHotspot:getHeight()
	return self.circle == nil and 0 or self.circle.height
end

function HarvestMissionHotspot:getDimension()
	if self.circle == nil then
		return 0, 0
	else
		return self.circle.width, self.circle.height
	end
end

function HarvestMissionHotspot:setScale(scale) end

function HarvestMissionHotspot:getCategory()
	return MapHotspot.CATEGORY_MISSION
end

function HarvestMissionHotspot:getIsPersistent()
	return false
end

function HarvestMissionHotspot:getRenderLast()
	return false
end

-- Local values: circle
function HarvestMissionHotspot:render(x, y, rotation, small)
	local v21_ = self.circle
	if v21_ ~= nil then
		v21_:setPosition(x, y)
		v21_:setColor(nil, nil, nil, IngameMap.alpha)
		v21_:render()
		local _ = x + v21_.width * 0.5
		local _ = y + v21_.height * 0.5
	end
end
