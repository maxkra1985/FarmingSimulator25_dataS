-- Local values: TreeTransportMissionHotspot_mt
TreeTransportMissionHotspot = {}
local TreeTransportMissionHotspot_mt = Class(TreeTransportMissionHotspot, MapHotspot)

-- Upvalues: TreeTransportMissionHotspot_mt
-- Local values: self
function TreeTransportMissionHotspot.new(customMt)
	-- upvalues: (copy) TreeTransportMissionHotspot_mt
	local v3_ = MapHotspot.new(customMt or TreeTransportMissionHotspot_mt)
	local v4_, v5_ = getNormalizedScreenValues(50, 50)
	v3_.width = v4_
	v3_.height = v5_
	v3_.icon = g_overlayManager:createOverlay("mapHotspots.contractWoodTransport", 0, 0, v3_.width, v3_.height)
	v3_.circle = g_overlayManager:createOverlay("mapHotspots.circle", 0, 0, v3_.width, v3_.height)
	v3_.circle:setColor(0.5089, 0.016, 0.016, 1)
	v3_.worldRadius = 50
	v3_.forceNoRotation = true
	return v3_
end

function TreeTransportMissionHotspot:delete()
	TreeTransportMissionHotspot:superClass().delete(self)
	if self.icon ~= nil then
		self.icon:delete()
		self.icon = nil
	end
	if self.circle ~= nil then
		self.circle:delete()
		self.circle = nil
	end
end

function TreeTransportMissionHotspot:setWorldRadius(worldRadius)
	self.worldRadius = worldRadius
end

-- Local values: ingameMap, layout, mapWidth, mapHeight, width, height
function TreeTransportMissionHotspot:postUpdate(dt)
	local v10_ = g_currentMission.hud:getIngameMap()
	local v11_, v12_ = v10_.layout:getMapSize()
	local v13_ = self.worldRadius / v10_.worldSizeX * v11_
	local v14_ = self.worldRadius / v10_.worldSizeZ * v12_
	if self.circle ~= nil then
		self.circle:setDimension(v13_, v14_)
	end
end

function TreeTransportMissionHotspot:getWidth()
	if self.circle == nil then
		return self.lastRenderedIcon == nil and 0 or self.lastRenderedIcon.width
	else
		return self.circle.width
	end
end

function TreeTransportMissionHotspot:getHeight()
	if self.circle == nil then
		return self.lastRenderedIcon == nil and 0 or self.lastRenderedIcon.height
	else
		return self.circle.height
	end
end

function TreeTransportMissionHotspot:getDimension()
	if self.circle == nil then
		if self.lastRenderedIcon == nil then
			return 0, 0
		else
			return self.lastRenderedIcon.width, self.lastRenderedIcon.height
		end
	else
		return self.circle.width, self.circle.height
	end
end

function TreeTransportMissionHotspot:setScale(scale)
	if self.icon ~= nil then
		self.icon:setScale(scale, scale)
	end
end

function TreeTransportMissionHotspot:getCategory()
	return MapHotspot.CATEGORY_MISSION
end

function TreeTransportMissionHotspot:getIsPersistent()
	return false
end

function TreeTransportMissionHotspot:getRenderLast()
	return false
end

-- Local values: icon, circle
function TreeTransportMissionHotspot:render(x, y, rotation, small)
	local v23_ = self.icon
	local v24_ = self.circle
	if v24_ ~= nil then
		v24_:setPosition(x, y)
		v24_:setColor(nil, nil, nil, IngameMap.alpha)
		v24_:render()
		x = x + v24_.width * 0.5
		y = y + v24_.height * 0.5
		if v23_ ~= nil then
			x = x - v23_.width * 0.5
			y = y - v23_.height * 0.5
		end
	end
	if v23_ ~= nil then
		v23_:setPosition(x, y)
		v23_:setColor(nil, nil, nil, self.isBlinking and (self:getCanBlink() and IngameMap.alpha) or 1)
		v23_:render()
	end
end
