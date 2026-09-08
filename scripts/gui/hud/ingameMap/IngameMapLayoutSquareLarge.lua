-- Local values: IngameMapLayoutSquareLarge_mt
IngameMapLayoutSquareLarge = {}
local IngameMapLayoutSquareLarge_mt = Class(IngameMapLayoutSquareLarge, IngameMapLayout)
function IngameMapLayoutSquareLarge.new()
	-- upvalues: (copy) IngameMapLayoutSquareLarge_mt
	return IngameMapLayoutSquareLarge:superClass().new(IngameMapLayoutSquareLarge_mt)
end

function IngameMapLayoutSquareLarge:delete()
	delete(self.overlayMask)
	self.overlayMask = nil
	self.background:delete()
	IngameMapLayoutSquareLarge:superClass().delete(self)
end

function IngameMapLayoutSquareLarge:createComponents(element)
	self.overlayMask = createOverlayTextureFromFile("dataS/menu/hud/minimap_mask_square.png")
	self.background = g_overlayManager:createOverlay("gui.colorPreset", 0, 0, 0, 0)
	self.background:setColor(0, 0, 0, 0.75)
end

-- Local values: posX, posY, width, height, mapOffsetX, mapOffsetY
function IngameMapLayoutSquareLarge:storeScaledValues(element, uiScale)
	local v6_ = g_hudAnchorLeft
	local v7_ = g_hudAnchorBottom
	local v8_, v9_ = element:scalePixelValuesToScreenVector(700, 700)
	self.background:setDimension(v8_, v9_)
	self.background:setPosition(v6_, v7_)
	local v10_, v11_ = element:scalePixelValuesToScreenVector(5, 5)
	local v12_, v13_ = element:scalePixelValuesToScreenVector(690, 690)
	self.mapSizeX = v12_
	self.mapSizeY = v13_
	local v14_ = v6_ + v10_
	local v15_ = v7_ + v11_
	self.mapPosX = v14_
	self.mapPosY = v15_
	self.coordinateFontSize = element:scalePixelToScreenHeight(14)
	local v16_, v17_ = element:scalePixelValuesToScreenVector(0, 4)
	self.coordOffsetX = v16_
	self.coordOffsetY = v17_
	self.latencyFontSize = element:scalePixelToScreenHeight(10)
	local v18_, v19_ = element:scalePixelValuesToScreenVector(0, -12)
	self.latencyOffsetX = v18_
	self.latencyOffsetY = v19_
	local v20_ = -self.mapSizeX / 2 + self.mapPosX
	local v21_ = -self.mapSizeY / 2 + self.mapPosY
	self.screenMapPosX = v20_
	self.screenMapPosY = v21_
	local v22_ = self.mapSizeX * 2
	local v23_ = self.mapSizeY * 2
	self.screenMapSizeX = v22_
	self.screenMapSizeY = v23_
end

function IngameMapLayoutSquareLarge:drawBefore()
	self.background:render()
	set2DMaskFromTexture(self.overlayMask, true, self.mapPosX, self.mapPosY, self.mapSizeX, self.mapSizeY)
end

function IngameMapLayoutSquareLarge:drawAfter()
	set2DMaskFromTexture(0, true, 0, 0, 0, 0)
end

-- Local values: x, y
function IngameMapLayoutSquareLarge:drawCoordinates(text)
	setTextAlignment(RenderText.ALIGN_CENTER)
	setTextBold(false)
	local v27_ = self.mapPosX + self.mapSizeX / 2
	local v28_ = self.mapPosY + self.coordOffsetY
	setTextColor(0, 0, 0, 1)
	renderText(v27_ + g_pixelSizeX, v28_ - g_pixelSizeY, self.coordinateFontSize, text)
	local v29_ = setTextColor
	local v30_ = IngameMap.COLOR.COORDINATES_TEXT
	v29_(unpack(v30_))
	renderText(v27_, v28_, self.coordinateFontSize, text)
	setTextAlignment(RenderText.ALIGN_LEFT)
end

-- Local values: x, y
function IngameMapLayoutSquareLarge:drawLatency(text, color)
	setTextBold(false)
	setTextAlignment(RenderText.ALIGN_RIGHT)
	local v34_ = self.mapPosX + self.mapSizeX + self.latencyOffsetX
	local v35_ = self.mapPosY + self.latencyOffsetY
	setTextColor(0, 0, 0, 1)
	renderText(v34_ + g_pixelSizeX, v35_ - g_pixelSizeY, self.latencyFontSize, text)
	setTextColor(unpack(color))
	renderText(v34_, v35_, self.latencyFontSize, text)
end

function IngameMapLayoutSquareLarge:getMapPosition()
	return -self.mapSizeX / 2 + self.mapPosX, -self.mapSizeY / 2 + self.mapPosY
end

function IngameMapLayoutSquareLarge:getMapSize()
	return self.mapSizeX * 2, self.mapSizeY * 2
end

function IngameMapLayoutSquareLarge:getMapAlpha()
	return 0.7
end

function IngameMapLayoutSquareLarge:getShowsToggleAction()
	return false
end

function IngameMapLayoutSquareLarge:getShowsToggleActionText()
	return true
end

function IngameMapLayoutSquareLarge:getShowSmallIconVariation()
	return true
end

function IngameMapLayoutSquareLarge:getIconZoom()
	return 0.75
end

function IngameMapLayoutSquareLarge:getHeight()
	return self.mapSizeY
end

function IngameMapLayoutSquareLarge:getWidth()
	return self.mapSizeX
end

function IngameMapLayoutSquareLarge:getPosition()
	return self.mapPosX, self.mapPosY
end

-- Local values: mapWidth, mapHeight, mapX, mapY, objectX, objectY
function IngameMapLayoutSquareLarge:getMapObjectPosition(objectU, objectV, width, height, rot, persistent)
	local v47_ = self.screenMapSizeX
	local v48_ = self.screenMapSizeY
	local v49_ = self.screenMapPosX
	local v50_ = self.screenMapPosY
	return objectU * v47_ + v49_ - width * 0.5, (1 - objectV) * v48_ + v50_ - height * 0.5, rot, true
end
