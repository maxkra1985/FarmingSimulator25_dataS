-- Local values: IngameMapLayoutFullscreenMobile_mt
IngameMapLayoutFullscreenMobile = {}
local IngameMapLayoutFullscreenMobile_mt = Class(IngameMapLayoutFullscreenMobile, IngameMapLayout)
function IngameMapLayoutFullscreenMobile.new()
	-- upvalues: (copy) IngameMapLayoutFullscreenMobile_mt
	local v2_ = IngameMapLayoutFullscreenMobile:superClass().new(IngameMapLayoutFullscreenMobile_mt)
	v2_.mapCenterX = 0.5
	v2_.mapCenterY = 0.5
	v2_.zoomFactor = 1
	v2_.width = 1
	v2_.height = 1
	return v2_
end

function IngameMapLayoutFullscreenMobile:delete() end

function IngameMapLayoutFullscreenMobile:createComponents(element) end

function IngameMapLayoutFullscreenMobile:storeScaledValues(element, uiScale) end

function IngameMapLayoutFullscreenMobile:drawBefore() end

function IngameMapLayoutFullscreenMobile:drawAfter() end

-- Local values: height
function IngameMapLayoutFullscreenMobile:getMapSize()
	local v4_ = self.height * self.zoomFactor
	return v4_ / g_screenAspectRatio, v4_
end

-- Local values: width, height
function IngameMapLayoutFullscreenMobile:getMapPosition()
	local v6_, v7_ = self:getMapSize()
	return self.mapCenterX - v6_ * 0.5, self.mapCenterY - v7_ * 0.5
end

function IngameMapLayoutFullscreenMobile:setMapCenter(x, y)
	self.mapCenterX = x
	self.mapCenterY = y
end

function IngameMapLayoutFullscreenMobile:setMapWidth(width)
	self.width = width
	self.height = width * g_screenAspectRatio
end

function IngameMapLayoutFullscreenMobile:setMapZoom(zoomFactor)
	self.zoomFactor = zoomFactor
end

function IngameMapLayoutFullscreenMobile:getIconZoom()
	return 1
end

function IngameMapLayoutFullscreenMobile:getBlinkPlayerArrow()
	return true
end

-- Local values: mapWidth, mapHeight, mapX, mapY, objectX, objectY
function IngameMapLayoutFullscreenMobile:getMapObjectPosition(objectU, objectV, width, height, rot, persistent)
	local v21_, v22_ = self:getMapSize()
	local v23_, v24_ = self:getMapPosition()
	return objectU * v21_ + v23_ - width * 0.5, (1 - objectV) * v22_ + v24_ - height * 0.5, rot, true
end
