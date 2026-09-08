-- Local values: DestructibleRockMissionHotspot_mt
DestructibleRockMissionHotspot = {}
local DestructibleRockMissionHotspot_mt = Class(DestructibleRockMissionHotspot, MapHotspot)

-- Upvalues: DestructibleRockMissionHotspot_mt
-- Local values: self
function DestructibleRockMissionHotspot.new(customMt)
	-- upvalues: (copy) DestructibleRockMissionHotspot_mt
	local v3_ = MapHotspot.new(customMt or DestructibleRockMissionHotspot_mt)
	local v4_, v5_ = getNormalizedScreenValues(50, 50)
	v3_.width = v4_
	v3_.height = v5_
	v3_.icon = g_overlayManager:createOverlay("mapHotspots.contractStone", 0, 0, v3_.width, v3_.height)
	v3_.circle = g_overlayManager:createOverlay("mapHotspots.circle", 0, 0, v3_.width, v3_.height)
	v3_.circle:setColor(0.5089, 0.016, 0.016, 1)
	v3_.iconSmall = g_overlayManager:createOverlay("mapHotspots.miniMapHotspot", 0, 0, v3_.width, v3_.height)
	v3_.iconSmall:setColor(0.00303, 0.20155, 0.01599, 1)
	v3_.worldRadius = 50
	v3_.forceNoRotation = true
	return v3_
end

function DestructibleRockMissionHotspot:delete()
	DestructibleRockMissionHotspot:superClass().delete(self)
	if self.icon ~= nil then
		self.icon:delete()
		self.icon = nil
	end
	if self.circle ~= nil then
		self.circle:delete()
		self.circle = nil
	end
	if self.iconSmall ~= nil then
		self.iconSmall:delete()
		self.iconSmall = nil
	end
end

function DestructibleRockMissionHotspot:setWorldRadius(worldRadius)
	self.worldRadius = worldRadius
end

-- Local values: ingameMap, layout, mapWidth, mapHeight, width, height
function DestructibleRockMissionHotspot:postUpdate(dt)
	local v10_ = g_currentMission.hud:getIngameMap()
	local v11_, v12_ = v10_.layout:getMapSize()
	local v13_ = self.worldRadius / v10_.worldSizeX * v11_
	local v14_ = self.worldRadius / v10_.worldSizeZ * v12_
	if self.circle ~= nil then
		self.circle:setDimension(v13_, v14_)
	end
end

function DestructibleRockMissionHotspot:getWidth()
	if self.circle == nil then
		return self.lastRenderedIcon == nil and 0 or self.lastRenderedIcon.width
	else
		return self.circle.width
	end
end

function DestructibleRockMissionHotspot:getHeight()
	if self.circle == nil then
		return self.lastRenderedIcon == nil and 0 or self.lastRenderedIcon.height
	else
		return self.circle.height
	end
end

function DestructibleRockMissionHotspot:getDimension()
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

function DestructibleRockMissionHotspot:setScale(scale)
	if self.icon ~= nil then
		self.icon:setScale(scale, scale)
	end
	if self.iconSmall ~= nil then
		self.iconSmall:setScale(scale, scale)
	end
	if self.circle ~= nil then
		self.circle:setScale(scale + 0.5, scale + 0.5)
	end
end

function DestructibleRockMissionHotspot:getCategory()
	return MapHotspot.CATEGORY_MISSION
end

function DestructibleRockMissionHotspot:getIsPersistent()
	return false
end

function DestructibleRockMissionHotspot:getRenderLast()
	return false
end

-- Local values: icon, circle
function DestructibleRockMissionHotspot:render(x, y, rotation, small)
	local v24_ = self.icon
	if small then
		v24_ = self.iconSmall
	end
	self.lastRenderedIcon = v24_
	local v25_ = self.circle
	if v25_ ~= nil then
		v25_:setPosition(x, y)
		v25_:setColor(nil, nil, nil, IngameMap.alpha)
		v25_:render()
		x = x + v25_.width * 0.5
		y = y + v25_.height * 0.5
		if v24_ ~= nil then
			x = x - v24_.width * 0.5
			y = y - v24_.height * 0.5
		end
	end
	if v24_ ~= nil then
		v24_:setPosition(x, y)
		v24_:setColor(nil, nil, nil, self.isBlinking and (self:getCanBlink() and IngameMap.alpha) or 1)
		v24_:render()
	end
end
