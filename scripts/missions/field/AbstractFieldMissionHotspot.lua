-- Local values: AbstractFieldMissionHotspot_mt
AbstractFieldMissionHotspot = {}
local AbstractFieldMissionHotspot_mt = Class(AbstractFieldMissionHotspot, MapHotspot)

-- Upvalues: AbstractFieldMissionHotspot_mt
-- Local values: self
function AbstractFieldMissionHotspot.new(customMt)
	-- upvalues: (copy) AbstractFieldMissionHotspot_mt
	local v3_ = MapHotspot.new(customMt or AbstractFieldMissionHotspot_mt)
	local v4_, v5_ = getNormalizedScreenValues(50, 50)
	v3_.width = v4_
	v3_.height = v5_
	v3_.circle = g_overlayManager:createOverlay("mapHotspots.circle", 0, 0, v3_.width, v3_.height)
	v3_.circle:setColor(0.5089, 0.016, 0.016, 1)
	v3_.worldRadius = 50
	v3_.forceNoRotation = true
	return v3_
end

function AbstractFieldMissionHotspot:delete()
	AbstractFieldMissionHotspot:superClass().delete(self)
	if self.circle ~= nil then
		self.circle:delete()
		self.circle = nil
	end
end

-- Local values: x, z
function AbstractFieldMissionHotspot:setField(field)
	self.field = field
	local v9_, v10_ = field:getIndicatorPosition()
	self:setWorldPosition(v9_, v10_)
end

function AbstractFieldMissionHotspot:setWorldRadius(worldRadius)
	self.worldRadius = worldRadius
end

-- Local values: ingameMap, layout, mapWidth, mapHeight, width, height
function AbstractFieldMissionHotspot:postUpdate(dt)
	local v14_ = g_currentMission.hud:getIngameMap()
	local v15_, v16_ = v14_.layout:getMapSize()
	local v17_ = self.worldRadius / v14_.worldSizeX * v15_
	local v18_ = self.worldRadius / v14_.worldSizeZ * v16_
	if self.circle ~= nil then
		self.circle:setDimension(v17_, v18_)
	end
end

function AbstractFieldMissionHotspot:getWidth()
	return self.circle == nil and 0 or self.circle.width
end

function AbstractFieldMissionHotspot:getHeight()
	return self.circle == nil and 0 or self.circle.height
end

function AbstractFieldMissionHotspot:getDimension()
	if self.circle == nil then
		return 0, 0
	else
		return self.circle.width, self.circle.height
	end
end

function AbstractFieldMissionHotspot:setScale(scale) end

function AbstractFieldMissionHotspot:getCategory()
	return MapHotspot.CATEGORY_MISSION
end

function AbstractFieldMissionHotspot:getIsPersistent()
	return false
end

function AbstractFieldMissionHotspot:getRenderLast()
	return false
end

-- Local values: circle
function AbstractFieldMissionHotspot:render(x, y, rotation, small)
	local v25_ = self.circle
	if v25_ ~= nil then
		v25_:setPosition(x, y)
		v25_:setColor(nil, nil, nil, IngameMap.alpha)
		v25_:render()
		local _ = x + v25_.width * 0.5
		local _ = y + v25_.height * 0.5
	end
end
