InputGlyphMobileElement = {}
local InputGlyphMobileElement_mt = Class(InputGlyphMobileElement, InputGlyphElement)
function InputGlyphMobileElement.new(inputDisplayManager, customMt)
	local glyphWidth, glyphHeight = getNormalizedScreenValues(unpack(InputGlyphMobileElement.SIZE.GLYPH_ICON))
	local self = InputGlyphElement.new(inputDisplayManager, glyphWidth, glyphHeight, customMt or InputGlyphMobileElement_mt)
	local bgLeftWidth, bgLeftHeight = getNormalizedScreenValues(unpack(InputGlyphMobileElement.SIZE.BG_LEFT))
	local overlayLeft = Overlay.new(g_baseHUDFilename, 0, 0, bgLeftWidth, bgLeftHeight)
	overlayLeft:setUVs(GuiUtils.getUVs(InputGlyphMobileElement.UV.BG_LEFT))
	self.glyphBackgroundLeft = HUDElement.new(overlayLeft)
	local bgMiddleWidth, bgMiddleHeight = getNormalizedScreenValues(unpack(InputGlyphMobileElement.SIZE.BG_MIDDLE))
	local overlayMiddle = Overlay.new(g_baseHUDFilename, 0, 0, bgMiddleWidth, bgMiddleHeight)
	overlayMiddle:setUVs(GuiUtils.getUVs(InputGlyphMobileElement.UV.BG_MIDDLE))
	self.glyphBackgroundMiddle = HUDElement.new(overlayMiddle)
	local bgRightWidth, bgRightHeight = getNormalizedScreenValues(unpack(InputGlyphMobileElement.SIZE.BG_RIGHT))
	local overlayRight = Overlay.new(g_baseHUDFilename, 0, 0, bgRightWidth, bgRightHeight)
	overlayRight:setUVs(GuiUtils.getUVs(InputGlyphMobileElement.UV.BG_RIGHT))
	self.glyphBackgroundRight = HUDElement.new(overlayRight)
	self.bgOffsetLeftX = getNormalizedScreenValues(unpack(InputGlyphMobileElement.POSITION.BG_OFFSET_LEFT))
	self.bgOffsetRightX = getNormalizedScreenValues(unpack(InputGlyphMobileElement.POSITION.BG_OFFSET_RIGHT))
	self.plusOverlay:setColor(0, 0, 0, 1)
	self.uiScale = 1
	return self
end
function InputGlyphMobileElement:delete()
	self.glyphBackgroundLeft:delete()
	self.glyphBackgroundMiddle:delete()
	self.glyphBackgroundRight:delete()
	InputGlyphMobileElement:superClass().delete(self)
end
function InputGlyphMobileElement:draw(clipX1, clipY1, clipX2, clipY2)
	if #self.actionNames == 0 or not self.overlay:getIsVisible() or not self.hasButtonOverlays then
		return
	end
	if g_inputBinding:getLastInputMode() ~= GS_INPUT_HELP_MODE_GAMEPAD then
		return
	else
		local x, y = self:getPosition()
		local bgWidthLeft = self.glyphBackgroundLeft:getWidth()
		local bgHeight = self.glyphBackgroundLeft:getHeight()
		local totalGlyphWidth = self:getGlyphWidth()
		local posY = y - (bgHeight - self.iconSizeY) * 0.5
		local posXLeft = x + self.bgOffsetLeftX * self.uiScale
		local posXRight = x + totalGlyphWidth + self.bgOffsetRightX * self.uiScale
		if not self.isLeftAligned then
			posXLeft = posXLeft - totalGlyphWidth
			posXRight = x + self.bgOffsetRightX * self.uiScale
		end
		self.glyphBackgroundLeft:setPosition(posXLeft, posY)
		self.glyphBackgroundLeft:draw(clipX1, clipY1, clipX2, clipY2)
		self.glyphBackgroundRight:setPosition(posXRight, posY)
		self.glyphBackgroundRight:draw(clipX1, clipY1, clipX2, clipY2)
		local middleWidth = posXRight - posXLeft - bgWidthLeft
		if 0 < middleWidth then
			self.glyphBackgroundMiddle:setDimension(middleWidth, nil)
			self.glyphBackgroundMiddle:setPosition(posXLeft + bgWidthLeft, posY)
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
InputGlyphMobileElement.POSITION = { ICON_OFFSET = { -2, -1 }, BG_OFFSET_LEFT = { -22, 0 }, BG_OFFSET_RIGHT = { -24, 0 } }
InputGlyphMobileElement.SIZE = { BG_LEFT = { 46, 96 }, BG_MIDDLE = { 34, 96 }, BG_RIGHT = { 46, 96 }, GLYPH_ICON = { 48, 48 } }
InputGlyphMobileElement.UV = { BG_LEFT = { 288, 432, 46, 96 }, BG_MIDDLE = { 334, 432, 38, 96 }, BG_RIGHT = { 372, 432, 46, 96 } }
InputGlyphMobileElement.COLOR = { INPUT_GLYPH = { 0, 0, 0, 1 } }
