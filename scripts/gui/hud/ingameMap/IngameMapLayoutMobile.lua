-- Local values: IngameMapLayoutMobile_mt
IngameMapLayoutMobile = {}
local IngameMapLayoutMobile_mt = Class(IngameMapLayoutMobile, IngameMapLayoutSquare)
function IngameMapLayoutMobile.new()
	-- upvalues: (copy) IngameMapLayoutMobile_mt
	local v2_ = IngameMapLayoutMobile:superClass().new(IngameMapLayoutMobile_mt)
	v2_.mapOffsetX = 0
	return v2_
end

function IngameMapLayoutMobile:storeScaledValues(element, uiScale)
	self.mapPosX = element:scalePixelToScreenVector(IngameMapLayoutMobile.POSITION.MAP)
	local v5_, v6_ = element:scalePixelToScreenVector(IngameMapLayoutMobile.SIZE.MAP)
	self.mapSizeX = v5_
	self.mapSizeY = v6_
	self.mapPosY = IngameMapMobile.HEIGHT_FACTOR - self.mapSizeY * 0.5
end

function IngameMapLayoutMobile:setPlayerPosition(x, z, yRot)
	self.playerU = x
	self.playerV = 1 - z
	self.playerRot = yRot
end

-- Local values: mapWidth, mapHeight, mapPosX, mapPosY, playerScreenX, playerScreenY, playerU, playerV, offX, offY, minMapPosX, minMapPosY
function IngameMapLayoutMobile:getMapPosition()
	local v12_, v13_ = self:getMapSize()
	local v14_ = self.mapPosX + self.mapOffsetX
	local v15_ = self.mapPosY
	local v16_ = v14_ + self.mapSizeX * 0.5
	local v17_ = v15_ + self.mapSizeY * 0.5
	local v18_ = self.playerU
	local v19_ = self.playerV
	local v20_ = v16_ - v18_ * v12_
	local v21_ = v17_ - v19_ * v13_
	local v22_ = v14_ + self.mapSizeX - v12_
	local v23_ = v15_ + self.mapSizeY - v13_
	local v24_ = math.min(v20_, v14_)
	local v25_ = math.max(v24_, v22_)
	local v26_ = math.min(v21_, v15_)
	return v25_, math.max(v26_, v23_)
end

function IngameMapLayoutMobile:getShowsToggleAction()
	return false
end

function IngameMapLayoutMobile:getShowsToggleActionText()
	return true
end

function IngameMapLayoutMobile:getIconZoom()
	return 1.25
end

function IngameMapLayoutMobile:getMapAlpha()
	return 0.85
end

function IngameMapLayoutMobile:setOffset(x)
	self.mapOffsetX = x
end

function IngameMapLayoutMobile:drawBefore()
	set2DMaskFromTexture(self.overlayMask, true, self.mapPosX + self.mapOffsetX, self.mapPosY, self.mapSizeX, self.mapSizeY)
end

function IngameMapLayoutMobile:setWorldSize(worldSizeX, worldSizeZ)
	self.worldSizeFactor = 1.1
end

-- Local values: mapWidth, mapHeight, mapX, mapY, mapSpacePosX, mapSpacePosY, objectX, objectY, mapPosX, mapPosY, minX, maxX, minY, maxY
function IngameMapLayoutMobile:getMapObjectPosition(objectU, objectV, width, height, rot, persistent)
	local v38_, v39_ = self:getMapSize()
	local v40_, v41_ = self:getMapPosition()
	local v42_ = objectU * v38_
	local v43_ = (1 - objectV) * v39_
	local v44_ = v40_ + v42_ - width * 0.5
	local v45_ = v41_ + v43_ - height * 0.5
	local v46_ = self.mapPosX + self.mapOffsetX
	local v47_ = self.mapPosY
	if persistent then
		local v48_ = v46_ + self.mapSizeX - width
		v44_ = math.clamp(v44_, v46_, v48_)
		local v49_ = v47_ + self.mapSizeY - height
		v45_ = math.clamp(v45_, v47_, v49_)
	end
	local v50_ = v46_ - width
	local v51_ = v46_ + self.mapSizeX + width
	local v52_ = v47_ - height
	local v53_ = v47_ + self.mapSizeY + height
	if v44_ < v50_ or (v51_ < v44_ or (v45_ < v52_ or v53_ < v45_)) then
		return 0, 0, 0, false
	else
		return v44_, v45_, rot, true
	end
end
IngameMapLayoutMobile.SIZE = {
	["MAP"] = { 464, 470 }
}
IngameMapLayoutMobile.POSITION = {
	["MAP"] = { 2, 306 }
}
