-- Local values: IngameMapLayoutSquare_mt
IngameMapLayoutSquare = {}
local IngameMapLayoutSquare_mt = Class(IngameMapLayoutSquare, IngameMapLayout)

-- Upvalues: IngameMapLayoutSquare_mt
-- Local values: self
function IngameMapLayoutSquare.new(customMt)
	-- upvalues: (copy) IngameMapLayoutSquare_mt
	local v3_ = IngameMapLayoutSquare:superClass().new(customMt or IngameMapLayoutSquare_mt)
	v3_.screenMapPosX = 0
	v3_.screenMapPosY = 0
	v3_.screenMapSizeX = 0
	v3_.screenMapSizeY = 0
	v3_.velocityZoomFactor = 1
	v3_.playerU = 0
	v3_.playerV = 0
	return v3_
end

function IngameMapLayoutSquare:delete()
	delete(self.overlayMask)
	self.overlayMask = nil
	self.background:delete()
	self.unreadMessagesBg:delete()
	self.unreadMessages:delete()
	IngameMapLayoutSquare:superClass().delete(self)
end

function IngameMapLayoutSquare:createComponents(element)
	self.overlayMask = createOverlayTextureFromFile("dataS/menu/hud/minimap_mask_square.png")
	self.background = g_overlayManager:createOverlay("gui.colorPreset", 0, 0, 0, 0)
	self.background:setColor(0, 0, 0, 0.75)
	self.unreadMessagesBg = g_overlayManager:createOverlay("gui.gearBg", 0, 0, 0, 0)
	self.unreadMessagesBg:setColor(0, 0, 0, 0.75)
	self.unreadMessages = g_overlayManager:createOverlay("gui.newMessage", 0, 0, 0, 0)
end

-- Local values: posX, posY, width, height, mapOffsetX, mapOffsetY, bgWidth, bgHeight, bgOffsetX, bgOffsetY, iconWidth, iconHeight, iconOffsetX, iconOffsetY
function IngameMapLayoutSquare:storeScaledValues(element, uiScale)
	local v8_ = g_hudAnchorLeft
	local v9_ = g_hudAnchorBottom
	local v10_, v11_ = element:scalePixelValuesToScreenVector(256, 256)
	self.background:setDimension(v10_, v11_)
	self.background:setPosition(v8_, v9_)
	local v12_, v13_ = element:scalePixelValuesToScreenVector(5, 5)
	local v14_, v15_ = element:scalePixelValuesToScreenVector(246, 246)
	self.mapSizeX = v14_
	self.mapSizeY = v15_
	local v16_ = v8_ + v12_
	local v17_ = v9_ + v13_
	self.mapPosX = v16_
	self.mapPosY = v17_
	self.fontSize = element:scalePixelToScreenHeight(HUDElement.TEXT_SIZE.DEFAULT_TEXT)
	self.coordinateFontSize = element:scalePixelToScreenHeight(14)
	local v18_, v19_ = element:scalePixelValuesToScreenVector(-4, 4)
	self.coordOffsetX = v18_
	self.coordOffsetY = v19_
	self.latencyFontSize = element:scalePixelToScreenHeight(10)
	local v20_, v21_ = element:scalePixelValuesToScreenVector(0, -12)
	self.latencyOffsetX = v20_
	self.latencyOffsetY = v21_
	local v22_, v23_ = element:scalePixelValuesToScreenVector(38, 38)
	local v24_, v25_ = element:scalePixelValuesToScreenVector(0, 262)
	self.unreadMessagesBg:setDimension(v22_, v23_)
	self.unreadMessagesBg:setPosition(v8_ + v24_, v9_ + v25_)
	local v26_, v27_ = element:scalePixelValuesToScreenVector(32, 32)
	local v28_, v29_ = element:scalePixelValuesToScreenVector(3, 259)
	self.unreadMessages:setDimension(v26_, v27_)
	self.unreadMessages:setPosition(v8_ + v28_, v9_ + v29_)
end

function IngameMapLayoutSquare:drawBefore()
	self.background:render()
	set2DMaskFromTexture(self.overlayMask, true, self.mapPosX, self.mapPosY, self.mapSizeX, self.mapSizeY)
end

function IngameMapLayoutSquare:drawAfter()
	set2DMaskFromTexture(0, true, 0, 0, 0, 0)
	if self.hasMessages then
		self.unreadMessagesBg:render()
		self.unreadMessages:render()
	end
end

-- Local values: x, y
function IngameMapLayoutSquare:drawCoordinates(text)
	setTextAlignment(RenderText.ALIGN_CENTER)
	setTextBold(false)
	local v34_ = self.mapPosX + self.mapSizeX / 2
	local v35_ = self.mapPosY + self.coordOffsetY
	setTextColor(0, 0, 0, 1)
	renderText(v34_ + g_pixelSizeX, v35_ - g_pixelSizeY, self.coordinateFontSize, text)
	local v36_ = setTextColor
	local v37_ = IngameMap.COLOR.COORDINATES_TEXT
	v36_(unpack(v37_))
	renderText(v34_, v35_, self.coordinateFontSize, text)
	setTextAlignment(RenderText.ALIGN_LEFT)
end

-- Local values: x, y
function IngameMapLayoutSquare:drawLatency(text, color)
	setTextBold(false)
	setTextAlignment(RenderText.ALIGN_RIGHT)
	local v41_ = self.mapPosX + self.mapSizeX + self.latencyOffsetX
	local v42_ = self.mapPosY + self.latencyOffsetY
	setTextColor(0, 0, 0, 1)
	renderText(v41_ + g_pixelSizeX, v42_ - g_pixelSizeY, self.latencyFontSize, text)
	setTextColor(unpack(color))
	renderText(v41_, v42_, self.latencyFontSize, text)
	setTextAlignment(RenderText.ALIGN_LEFT)
end

function IngameMapLayoutSquare:setPlayerPosition(x, z, yRot)
	self.playerU = x * 0.5 + 0.25
	self.playerV = (1 - z) * 0.5 + 0.25
	self.playerRot = yRot
end

function IngameMapLayoutSquare:setPlayerVelocity(speed)
	local v49_ = speed / 50
	self.velocityZoomFactor = math.clamp(v49_, 0, 1)
end

function IngameMapLayoutSquare:setWorldSize(worldSizeX, worldSizeZ)
	self.worldSizeFactor = worldSizeX / 2048
end

function IngameMapLayoutSquare:setHasUnreadMessages(hasMessages)
	self.hasMessages = hasMessages
end

function IngameMapLayoutSquare:postUpdate(dt)
	self:updateScreenValues()
end

function IngameMapLayoutSquare:activate()
	self:updateScreenValues()
end

-- Local values: width, playerScreenX, playerScreenY
function IngameMapLayoutSquare:updateScreenValues()
	local v57_ = (1 - 0.25 * self.velocityZoomFactor) * self.worldSizeFactor
	self.screenMapSizeX = v57_
	self.screenMapSizeY = v57_ * g_screenAspectRatio
	local v58_ = self.mapPosX + self.mapSizeX / 2
	local v59_ = self.mapPosY + self.mapSizeY / 2
	self.screenMapPosX = v58_ - self.playerU * self.screenMapSizeX
	self.screenMapPosY = v59_ - self.playerV * self.screenMapSizeY
end

function IngameMapLayoutSquare:getMapPosition()
	return self.screenMapPosX, self.screenMapPosY
end

function IngameMapLayoutSquare:getMapSize()
	return self.screenMapSizeX, self.screenMapSizeY
end

function IngameMapLayoutSquare:getMapAlpha()
	return 0.7
end

function IngameMapLayoutSquare:getShowsToggleAction()
	return false
end

function IngameMapLayoutSquare:getShowsToggleActionText()
	return true
end

function IngameMapLayoutSquare:getShowSmallIconVariation()
	return true
end

function IngameMapLayoutSquare:getIconZoom()
	return 0.5
end

function IngameMapLayoutSquare:getHeight()
	return self.mapSizeY
end

function IngameMapLayoutSquare:getWidth()
	return self.mapSizeX
end

function IngameMapLayoutSquare:getPosition()
	return self.mapPosX, self.mapPosY
end

-- Local values: mapPosX, mapPosY, mapSizeX, mapSizeY, mapWidth, mapHeight, mapX, mapY, objectX, objectY, minX, maxX, minY, maxY
function IngameMapLayoutSquare:getMapObjectPosition(objectU, objectV, width, height, rot, persistent)
	local v72_ = self.mapPosX
	local v73_ = self.mapPosY
	local v74_ = self.mapSizeX
	local v75_ = self.mapSizeY
	local v76_ = self.screenMapSizeX
	local v77_ = self.screenMapSizeY
	local v78_ = self.screenMapPosX
	local v79_ = self.screenMapPosY
	local v80_ = objectU * v76_ + v78_ - width * 0.5
	local v81_ = (1 - objectV) * v77_ + v79_ - height * 0.5
	if persistent then
		local v82_ = v72_ - width * 0.5
		local v83_ = v72_ + v74_ - width * 0.5
		v80_ = math.clamp(v80_, v82_, v83_)
		local v84_ = v73_ - height * 0.5
		local v85_ = v73_ + v75_ - height * 0.5
		v81_ = math.clamp(v81_, v84_, v85_)
	end
	local v86_ = v72_ - width
	local v87_ = v72_ + v74_ + width
	local v88_ = v73_ - height
	local v89_ = v73_ + v75_ + height
	if v80_ < v86_ or (v87_ < v80_ or (v81_ < v88_ or v89_ < v81_)) then
		return 0, 0, 0, false
	else
		return v80_, v81_, rot, true
	end
end
