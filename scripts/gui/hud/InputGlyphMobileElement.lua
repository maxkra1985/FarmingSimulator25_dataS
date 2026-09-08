-- Local values: InputGlyphMobileElement_mt
InputGlyphMobileElement = {}
local InputGlyphMobileElement_mt = Class(InputGlyphMobileElement, InputGlyphElement)

-- Upvalues: InputGlyphMobileElement_mt
-- Local values: glyphWidth, glyphHeight, self, bgLeftWidth, bgLeftHeight, overlayLeft, bgMiddleWidth, bgMiddleHeight, overlayMiddle, bgRightWidth, bgRightHeight, overlayRight
function InputGlyphMobileElement.new(inputDisplayManager, customMt)
	-- upvalues: (copy) InputGlyphMobileElement_mt
	local v4_ = getNormalizedScreenValues
	local v5_ = InputGlyphMobileElement.SIZE.GLYPH_ICON
	local v6_, v7_ = v4_(unpack(v5_))
	local v8_ = InputGlyphElement.new(inputDisplayManager, v6_, v7_, customMt or InputGlyphMobileElement_mt)
	local v9_ = getNormalizedScreenValues
	local v10_ = InputGlyphMobileElement.SIZE.BG_LEFT
	local v11_, v12_ = v9_(unpack(v10_))
	local v13_ = Overlay.new(g_baseHUDFilename, 0, 0, v11_, v12_)
	v13_:setUVs(GuiUtils.getUVs(InputGlyphMobileElement.UV.BG_LEFT))
	v8_.glyphBackgroundLeft = HUDElement.new(v13_)
	local v14_ = getNormalizedScreenValues
	local v15_ = InputGlyphMobileElement.SIZE.BG_MIDDLE
	local v16_, v17_ = v14_(unpack(v15_))
	local v18_ = Overlay.new(g_baseHUDFilename, 0, 0, v16_, v17_)
	v18_:setUVs(GuiUtils.getUVs(InputGlyphMobileElement.UV.BG_MIDDLE))
	v8_.glyphBackgroundMiddle = HUDElement.new(v18_)
	local v19_ = getNormalizedScreenValues
	local v20_ = InputGlyphMobileElement.SIZE.BG_RIGHT
	local v21_, v22_ = v19_(unpack(v20_))
	local v23_ = Overlay.new(g_baseHUDFilename, 0, 0, v21_, v22_)
	v23_:setUVs(GuiUtils.getUVs(InputGlyphMobileElement.UV.BG_RIGHT))
	v8_.glyphBackgroundRight = HUDElement.new(v23_)
	local v24_ = getNormalizedScreenValues
	local v25_ = InputGlyphMobileElement.POSITION.BG_OFFSET_LEFT
	v8_.bgOffsetLeftX = v24_(unpack(v25_))
	local v26_ = getNormalizedScreenValues
	local v27_ = InputGlyphMobileElement.POSITION.BG_OFFSET_RIGHT
	v8_.bgOffsetRightX = v26_(unpack(v27_))
	v8_.plusOverlay:setColor(0, 0, 0, 1)
	v8_.uiScale = 1
	return v8_
end

function InputGlyphMobileElement:delete()
	self.glyphBackgroundLeft:delete()
	self.glyphBackgroundMiddle:delete()
	self.glyphBackgroundRight:delete()
	InputGlyphMobileElement:superClass().delete(self)
end

-- Local values: x, y, bgWidthLeft, bgHeight, totalGlyphWidth, posY, posXLeft, posXRight, middleWidth
function InputGlyphMobileElement:draw(clipX1, clipY1, clipX2, clipY2)
	if #self.actionNames == 0 or not (self.overlay:getIsVisible() and self.hasButtonOverlays) then
		return
	elseif g_inputBinding:getLastInputMode() == GS_INPUT_HELP_MODE_GAMEPAD then
		local v34_, v35_ = self:getPosition()
		local v36_ = self.glyphBackgroundLeft:getWidth()
		local v37_ = self.glyphBackgroundLeft:getHeight()
		local v38_ = self:getGlyphWidth()
		local v39_ = v35_ - (v37_ - self.iconSizeY) * 0.5
		local v40_ = v34_ + self.bgOffsetLeftX * self.uiScale
		local v41_ = v34_ + v38_ + self.bgOffsetRightX * self.uiScale
		if not self.isLeftAligned then
			v40_ = v40_ - v38_
			v41_ = v34_ + self.bgOffsetRightX * self.uiScale
		end
		self.glyphBackgroundLeft:setPosition(v40_, v39_)
		self.glyphBackgroundLeft:draw(clipX1, clipY1, clipX2, clipY2)
		self.glyphBackgroundRight:setPosition(v41_, v39_)
		self.glyphBackgroundRight:draw(clipX1, clipY1, clipX2, clipY2)
		local v42_ = v41_ - v40_ - v36_
		if v42_ > 0 then
			self.glyphBackgroundMiddle:setDimension(v42_, nil)
			self.glyphBackgroundMiddle:setPosition(v40_ + v36_, v39_)
			self.glyphBackgroundMiddle:draw(clipX1, clipY1, clipX2, clipY2)
		end
		InputGlyphMobileElement:superClass().draw(self, clipX1, clipY1, clipX2, clipY2)
	end
end

function InputGlyphMobileElement:getPositionOffset()
	if self.isLeftAligned then
		return 0, 0
	else
		return -self:getGlyphWidth(), 0
	end
end

function InputGlyphMobileElement:getDrawSeparator()
	return true
end

function InputGlyphMobileElement:setScale(widthScale, heightScale)
	InputGlyphMobileElement:superClass().setScale(self, widthScale, heightScale)
	self.glyphBackgroundLeft:setScale(widthScale, heightScale)
	self.glyphBackgroundRight:setScale(widthScale, heightScale)
	self.glyphBackgroundMiddle:setScale(widthScale, heightScale)
	self.uiScale = widthScale
	self.glyphOffsetX = -5 / g_pixelSizeX
end
InputGlyphMobileElement.POSITION = {
	["ICON_OFFSET"] = { -2, -1 },
	["BG_OFFSET_LEFT"] = { -22, 0 },
	["BG_OFFSET_RIGHT"] = { -24, 0 }
}
InputGlyphMobileElement.SIZE = {
	["BG_LEFT"] = { 46, 96 },
	["BG_MIDDLE"] = { 34, 96 },
	["BG_RIGHT"] = { 46, 96 },
	["GLYPH_ICON"] = { 48, 48 }
}
InputGlyphMobileElement.UV = {
	["BG_LEFT"] = {
		288,
		432,
		46,
		96
	},
	["BG_MIDDLE"] = {
		334,
		432,
		38,
		96
	},
	["BG_RIGHT"] = {
		372,
		432,
		46,
		96
	}
}
InputGlyphMobileElement.COLOR = {
	["INPUT_GLYPH"] = {
		0,
		0,
		0,
		1
	}
}
