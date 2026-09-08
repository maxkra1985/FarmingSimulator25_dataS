-- Local values: IngameMapLayoutCircle_mt, HALF_PI
IngameMapLayoutCircle = {}
local IngameMapLayoutCircle_mt = Class(IngameMapLayoutCircle, IngameMapLayout)
local HALF_PI = 1.5707963267948966
function IngameMapLayoutCircle.new()
	-- upvalues: (copy) IngameMapLayoutCircle_mt
	local v3_ = IngameMapLayoutCircle:superClass().new(IngameMapLayoutCircle_mt)
	v3_.screenMapPosX = 0
	v3_.screenMapPosY = 0
	v3_.screenMapSizeX = 0
	v3_.screenMapSizeY = 0
	v3_.velocityZoomFactor = 1
	v3_.playerU = 0
	v3_.playerV = 0
	return v3_
end

function IngameMapLayoutCircle:delete()
	delete(self.overlayMask)
	self.overlayMask = nil
	self.background:delete()
	self.northArrow:delete()
	self.unreadMessagesBg:delete()
	self.unreadMessages:delete()
	IngameMapLayoutCircle:superClass().delete(self)
end

function IngameMapLayoutCircle:createComponents(element)
	self.overlayMask = createOverlayTextureFromFile("dataS/menu/hud/minimap_mask.png")
	self.background = g_overlayManager:createOverlay("gui.minimapFrame", 0, 0, 0, 0)
	self.background:setColor(0, 0, 0, 0.75)
	self.northArrow = g_overlayManager:createOverlay("gui.tourdialogue_arrow", 0, 0, 0, 0)
	self.northArrow:setColor(0.5, 0.5, 0.5, 0.9)
	self.unreadMessagesBg = g_overlayManager:createOverlay("gui.gearBg", 0, 0, 0, 0)
	self.unreadMessagesBg:setColor(0, 0, 0, 0.75)
	self.unreadMessages = g_overlayManager:createOverlay("gui.newMessage", 0, 0, 0, 0)
end

-- Local values: posX, posY, width, height, arrowWidth, arrowHeight, mapOffsetX, mapOffsetY, bgWidth, bgHeight, bgOffsetX, bgOffsetY, iconWidth, iconHeight, iconOffsetX, iconOffsetY
function IngameMapLayoutCircle:storeScaledValues(element, uiScale)
	local v8_ = g_hudAnchorLeft
	local v9_ = g_hudAnchorBottom
	local v10_, v11_ = element:scalePixelValuesToScreenVector(256, 256)
	self.background:setDimension(v10_, v11_)
	self.background:setPosition(v8_, v9_)
	local v12_, v13_ = element:scalePixelValuesToScreenVector(9, 7)
	self.northArrow:setDimension(v12_, v13_)
	local v14_, v15_ = element:scalePixelValuesToScreenVector(10, 10)
	local v16_, v17_ = element:scalePixelValuesToScreenVector(236, 236)
	self.mapSizeX = v16_
	self.mapSizeY = v17_
	local v18_ = v8_ + v14_
	local v19_ = v9_ + v15_
	self.mapPosX = v18_
	self.mapPosY = v19_
	self.fontSize = element:scalePixelToScreenHeight(HUDElement.TEXT_SIZE.DEFAULT_TEXT)
	self.coordinateFontSize = element:scalePixelToScreenHeight(14)
	local v20_, v21_ = element:scalePixelValuesToScreenVector(0, 12)
	self.coordOffsetX = v20_
	self.coordOffsetY = v21_
	self.latencyFontSize = element:scalePixelToScreenHeight(10)
	local v22_, v23_ = element:scalePixelValuesToScreenVector(0, -12)
	self.latencyOffsetX = v22_
	self.latencyOffsetY = v23_
	local v24_, v25_ = element:scalePixelValuesToScreenVector(38, 38)
	local v26_, v27_ = element:scalePixelValuesToScreenVector(0, 218)
	self.unreadMessagesBg:setDimension(v24_, v25_)
	self.unreadMessagesBg:setPosition(v8_ + v26_, v9_ + v27_)
	local v28_, v29_ = element:scalePixelValuesToScreenVector(32, 32)
	local v30_, v31_ = element:scalePixelValuesToScreenVector(3, 221)
	self.unreadMessages:setDimension(v28_, v29_)
	self.unreadMessages:setPosition(v8_ + v30_, v9_ + v31_)
end

function IngameMapLayoutCircle:activate()
	self:updateScreenValues()
end

function IngameMapLayoutCircle:postUpdate(dt)
	self:updateScreenValues()
end

-- Local values: width, playerScreenX, playerScreenY
function IngameMapLayoutCircle:updateScreenValues()
	local v35_ = (1 - 0.25 * self.velocityZoomFactor) * self.worldSizeFactor
	self.screenMapSizeX = v35_
	self.screenMapSizeY = v35_ * g_screenAspectRatio
	local v36_ = self.mapPosX + self.mapSizeX / 2
	local v37_ = self.mapPosY + self.mapSizeY / 2
	self.screenMapPosX = v36_ - self.playerU * self.screenMapSizeX
	self.screenMapPosY = v37_ - self.playerV * self.screenMapSizeY
end

function IngameMapLayoutCircle:drawBefore()
	set2DMaskFromTexture(self.overlayMask, true, self.mapPosX, self.mapPosY, self.mapSizeX, self.mapSizeY)
end

function IngameMapLayoutCircle:drawAfter()
	set2DMaskFromTexture(0, true, 0, 0, 0, 0)
	self.background:render()
	if self.hasMessages then
		self.unreadMessagesBg:render()
		self.unreadMessages:render()
	end
	self:drawNorthArrow(-self.playerRot + 1.5707963267948966)
end

-- Local values: x, y
function IngameMapLayoutCircle:drawCoordinates(text)
	setTextAlignment(RenderText.ALIGN_CENTER)
	setTextBold(false)
	local v42_ = self.mapPosX + self.mapSizeX / 2
	local v43_ = self.mapPosY + self.coordOffsetY
	setTextColor(0, 0, 0, 1)
	renderText(v42_ + g_pixelSizeX, v43_ - g_pixelSizeY, self.coordinateFontSize, text)
	setTextColor(1, 1, 1, 1)
	renderText(v42_, v43_, self.coordinateFontSize, text)
	setTextAlignment(RenderText.ALIGN_LEFT)
end

-- Local values: x, y
function IngameMapLayoutCircle:drawLatency(text, color)
	setTextBold(false)
	setTextAlignment(RenderText.ALIGN_CENTER)
	local v47_ = self.mapPosX + self.mapSizeX / 2 + self.latencyOffsetX
	local v48_ = self.mapPosY + self.mapSizeY + self.latencyOffsetY
	setTextColor(0, 0, 0, 1)
	renderText(v47_ + g_pixelSizeX, v48_ - g_pixelSizeY, self.latencyFontSize, text)
	setTextColor(color[1], color[2], color[3], color[4])
	renderText(v47_, v48_, self.latencyFontSize, text)
	setTextAlignment(RenderText.ALIGN_LEFT)
end

-- Upvalues: HALF_PI
-- Local values: radiusX, radiusY, pivotX, pivotY, centerX, centerY, cosRot, sinRot, posX, posY
function IngameMapLayoutCircle:drawNorthArrow(rotation)
	-- upvalues: (copy) HALF_PI
	local v51_ = self.mapSizeX / 2
	local v52_ = self.mapSizeY / 2
	local v53_ = self.northArrow.width * 0.5
	local v54_ = self.mapPosX + v51_
	local v55_ = self.mapPosY + v52_
	local v56_ = math.cos(rotation)
	local v57_ = math.sin(rotation)
	local v58_ = v54_ + v56_ * v51_ - v53_
	local v59_ = v55_ + v57_ * v52_ - 0
	self.northArrow:setPosition(v58_, v59_)
	self.northArrow:setRotation(rotation - 1.5707963267948966, v53_, 0)
	self.northArrow:render()
end

function IngameMapLayoutCircle:setPlayerPosition(x, z, yRot)
	self.playerU = x * 0.5 + 0.25
	self.playerV = (1 - z) * 0.5 + 0.25
	self.playerRot = yRot + 3.141592653589793
end

function IngameMapLayoutCircle:setPlayerVelocity(speed)
	local v66_ = speed / 50
	self.velocityZoomFactor = math.clamp(v66_, 0, 1)
end

function IngameMapLayoutCircle:setWorldSize(worldSizeX, worldSizeZ)
	self.worldSizeFactor = worldSizeX / 2048
end

function IngameMapLayoutCircle:setHasUnreadMessages(hasMessages)
	self.hasMessages = hasMessages
end

function IngameMapLayoutCircle:getMapPosition()
	return self.screenMapPosX, self.screenMapPosY
end

-- Local values: mapWidth, mapHeight
function IngameMapLayoutCircle:getMapPivot()
	local v73_, v74_ = self:getMapSize()
	return self.playerU * v73_, self.playerV * v74_
end

function IngameMapLayoutCircle:getMapRotation()
	return -self.playerRot
end

function IngameMapLayoutCircle:getMapSize()
	return self.screenMapSizeX, self.screenMapSizeY
end

function IngameMapLayoutCircle:getMapAlpha()
	return 0.7
end

function IngameMapLayoutCircle:getShowsToggleAction()
	return false
end

function IngameMapLayoutCircle:getShowSmallIconVariation()
	return true
end

function IngameMapLayoutCircle:getShowsToggleActionText()
	return true
end

function IngameMapLayoutCircle:getIconZoom()
	return 0.5
end

function IngameMapLayoutCircle:getHeight()
	return self.mapSizeY
end

function IngameMapLayoutCircle:getWidth()
	return self.mapSizeX
end

function IngameMapLayoutCircle:getPosition()
	return self.mapPosX, self.mapPosY
end

-- Local values: angle, s, c, cx, cy, xNew, yNew, length, neededLength, factor
function IngameMapLayoutCircle:rotateWithMap(x, y, rot, lockToBorder)
	local v85_ = -self.playerRot
	local v86_ = math.sin(v85_)
	local v87_ = math.cos(v85_)
	local v88_ = self.mapPosX + self.mapSizeX / 2
	local v89_ = self.mapPosY + self.mapSizeY / 2
	local v90_ = (x - v88_) * g_screenAspectRatio
	local v91_ = y - v89_
	local v92_ = v90_ * v87_ - v91_ * v86_
	local v93_ = v90_ * v86_ + v91_ * v87_
	if lockToBorder then
		local v94_ = v92_ * v92_ + v93_ * v93_
		local v95_ = math.sqrt(v94_)
		local v96_ = self.mapSizeY / 2 / v95_
		local v97_ = math.min(v96_, 1)
		v92_ = v92_ * v97_
		v93_ = v93_ * v97_
	end
	return v92_ / g_screenAspectRatio + v88_, v93_ * 1 + v89_, rot + v85_
end

-- Local values: mapWidth, mapHeight, mapX, mapY, objectX, objectY, minX, maxX, minY, maxY
function IngameMapLayoutCircle:getMapObjectPosition(objectU, objectV, width, height, rot, persistent)
	local v105_ = self.screenMapSizeX
	local v106_ = self.screenMapSizeY
	local v107_ = self.screenMapPosX
	local v108_ = self.screenMapPosY
	local v109_, v110_, v111_ = self:rotateWithMap(objectU * v105_ + v107_, (1 - objectV) * v106_ + v108_, rot, persistent)
	local v112_ = v109_ - width * 0.5
	local v113_ = v110_ - height * 0.5
	local v114_ = self.mapPosX - 2 * width
	local v115_ = self.mapPosX + self.mapSizeX + 2 * width
	local v116_ = self.mapPosY - 2 * height
	local v117_ = self.mapPosY + self.mapSizeY + 2 * height
	if v112_ < v114_ or (v115_ < v112_ or (v113_ < v116_ or v117_ < v113_)) then
		return 0, 0, 0, false
	else
		return v112_, v113_, v111_, true
	end
end
