-- Local values: IngameMapLayoutPartialscreen_mt
IngameMapLayoutPartialscreen = {}
local IngameMapLayoutPartialscreen_mt = Class(IngameMapLayoutPartialscreen, IngameMapLayout)
function IngameMapLayoutPartialscreen.new()
	-- upvalues: (copy) IngameMapLayoutPartialscreen_mt
	local v2_ = IngameMapLayoutPartialscreen:superClass().new(IngameMapLayoutPartialscreen_mt)
	v2_.mapCenterX = 0.5
	v2_.mapCenterY = 0.5
	v2_.worldSizeFactor = 1
	v2_.zoomFactor = 1.5
	v2_.width = 1
	v2_.height = 1
	v2_.posX = 0.5
	v2_.posY = 0.5
	v2_.centerOffsetXFactor = 0
	v2_.centerOffsetYFactor = 0
	v2_.mapExtensionScaleFactor = 0
	v2_.mapExtensionOffsetX = 0
	v2_.mapExtensionOffsetZ = 0
	v2_.worldCenterOffsetX = 0
	v2_.worldCenterOffsetZ = 0
	return v2_
end

function IngameMapLayoutPartialscreen:setWorldSize(worldSizeX, worldSizeZ)
	self.worldSizeFactor = worldSizeX / 2048
	self.worldCenterOffsetX = worldSizeX * 0.5
	self.worldCenterOffsetZ = worldSizeZ * 0.5
	self.worldSizeX = worldSizeX
	self.worldSizeZ = worldSizeZ
end

-- Local values: width
function IngameMapLayoutPartialscreen:getMapSize()
	local v7_ = self.zoomFactor * self.worldSizeFactor
	return v7_, v7_ * g_screenAspectRatio
end

-- Local values: usedWidth
function IngameMapLayoutPartialscreen:setMapZoomByWidthAndHeight(width, height)
	if height < width then
		height = width or height
	end
	self.zoomFactor = height / self.worldSizeFactor
end

function IngameMapLayoutPartialscreen:setPreviewPosition(x, y)
	self.posX = x
	self.posY = y
end

function IngameMapLayoutPartialscreen:setPreviewSize(width, height)
	self.width = width
	self.height = height
end

function IngameMapLayoutPartialscreen:setMapExtensionSettings(mapExtensionScaleFactor, extensionOffsetX, extensionOffsetZ)
	self.mapExtensionScaleFactor = mapExtensionScaleFactor
	self.mapExtensionOffsetX = extensionOffsetX
	self.mapExtensionOffsetZ = extensionOffsetZ
end

-- Local values: width, height, offsetX, offsetY, posX, posY
function IngameMapLayoutPartialscreen:getMapPosition()
	local v22_, v23_ = self:getMapSize()
	local v24_ = v22_ * self.centerOffsetXFactor
	local v25_ = v23_ * self.centerOffsetYFactor
	local v26_ = self.posX + v24_ + (self.width - v22_) * 0.5
	local v27_ = self.posY + v25_ + (self.height - v23_) * 0.5
	local v28_ = v26_ - (v22_ - self.width)
	local v29_ = self.posX
	local v30_ = math.clamp(v26_, v28_, v29_)
	local v31_ = v27_ - (v23_ - self.height)
	local v32_ = self.posY
	return v30_, math.clamp(v27_, v31_, v32_)
end

-- Local values: localX, localZ
function IngameMapLayoutPartialscreen:setCenterToWorldPosition(worldPosX, worldPosY)
	local v36_ = -self.worldCenterOffsetX
	local v37_ = self.worldCenterOffsetX
	local v38_ = math.clamp(worldPosX, v36_, v37_)
	local v39_ = -self.worldCenterOffsetZ
	local v40_ = self.worldCenterOffsetZ
	local v41_ = math.clamp(worldPosY, v39_, v40_)
	local v42_ = (v38_ + self.worldCenterOffsetX) / self.worldSizeX * self.mapExtensionScaleFactor + self.mapExtensionOffsetX
	local v43_ = (v41_ + self.worldCenterOffsetZ) / self.worldSizeZ * self.mapExtensionScaleFactor + self.mapExtensionOffsetZ
	self.centerOffsetXFactor = 0.5 - v42_
	self.centerOffsetYFactor = v43_ - 0.5
end

function IngameMapLayoutPartialscreen:setMapCenter(x, y)
	self.mapCenterX = x
	self.mapCenterY = y
end

function IngameMapLayoutPartialscreen:setMapZoom(zoomFactor)
	self.zoomFactor = zoomFactor
end

function IngameMapLayoutPartialscreen:setMapAlpha(alpha)
	self.mapAlpha = alpha
end

function IngameMapLayoutPartialscreen:getIconZoom()
	return 0.25 + self.zoomFactor * 0.25
end

function IngameMapLayoutPartialscreen:getBlinkPlayerArrow()
	return true
end

function IngameMapLayoutPartialscreen:getMapAlpha()
	return self.mapAlpha or 1
end

-- Local values: mapWidth, mapHeight, mapX, mapY, objectX, objectY
function IngameMapLayoutPartialscreen:getMapObjectPosition(objectU, objectV, width, height, rot, persistent)
	local v59_, v60_ = self:getMapSize()
	local v61_, v62_ = self:getMapPosition()
	return objectU * v59_ + v61_ - width * 0.5, (1 - objectV) * v60_ + v62_ - height * 0.5, rot, true
end
