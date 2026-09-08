-- Local values: IngameMapLayoutFullscreen_mt
IngameMapLayoutFullscreen = {}
local IngameMapLayoutFullscreen_mt = Class(IngameMapLayoutFullscreen, IngameMapLayout)
function IngameMapLayoutFullscreen.new()
	-- upvalues: (copy) IngameMapLayoutFullscreen_mt
	local v2_ = IngameMapLayoutFullscreen:superClass().new(IngameMapLayoutFullscreen_mt)
	v2_.mapCenterX = 0.5
	v2_.mapCenterY = 0.5
	v2_.zoomFactor = 1
	return v2_
end

function IngameMapLayoutFullscreen:delete() end

function IngameMapLayoutFullscreen:createComponents(element) end

function IngameMapLayoutFullscreen:storeScaledValues(element, uiScale) end

function IngameMapLayoutFullscreen:drawBefore() end

function IngameMapLayoutFullscreen:drawAfter() end

-- Local values: height
function IngameMapLayoutFullscreen:getMapSize()
	local v4_ = 2 * self.zoomFactor * self.sizeRatio
	return v4_ / g_screenAspectRatio, v4_
end

-- Local values: width, height
function IngameMapLayoutFullscreen:getMapPosition()
	local v6_, v7_ = self:getMapSize()
	return self.mapCenterX - v6_ * 0.5, self.mapCenterY - v7_ * 0.5
end

function IngameMapLayoutFullscreen:setMapCenter(x, y)
	self.mapCenterX = x
	self.mapCenterY = y
end

function IngameMapLayoutFullscreen:setMapWidth(width)
	self.sizeRatio = width * g_screenAspectRatio
end

function IngameMapLayoutFullscreen:setMapZoom(zoomFactor)
	self.zoomFactor = zoomFactor
end

-- Local values: zoom
function IngameMapLayoutFullscreen:getIconZoom()
	local v16_ = 0.25 + self.zoomFactor * 0.25
	return math.min(v16_, 0.75)
end

function IngameMapLayoutFullscreen:getBlinkPlayerArrow()
	return true
end

-- Local values: mapWidth, mapHeight, mapX, mapY, objectX, objectY
function IngameMapLayoutFullscreen:getMapObjectPosition(objectU, objectV, width, height, rot, persistent)
	local v23_, v24_ = self:getMapSize()
	local v25_, v26_ = self:getMapPosition()
	return objectU * v23_ + v25_ - width * 0.5, (1 - objectV) * v24_ + v26_ - height * 0.5, rot, true
end
