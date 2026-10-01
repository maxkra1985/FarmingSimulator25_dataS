HUDFrameElement = {}
local HUDFrameElement_mt = Class(HUDFrameElement, HUDElement)
function HUDFrameElement.new(posX, posY, width, height, parent, showBar, frameThickness, barThickness)
	local backgroundOverlay = g_overlayManager:createOverlay(g_plainColorSliceId, posX, posY, width, height)
	backgroundOverlay:setColor(0, 0, 0, 0)
	local self = HUDElement.new(backgroundOverlay, parent, HUDFrameElement_mt)
	self.topLine = nil
	self.leftLine = nil
	self.rightLine = nil
	self.bottomBar = nil
	self.frameWidth = 0
	self.frameHeight = 0
	self.showBar = Utils.getNoNil(showBar, true)
	self.frameThickness = frameThickness or HUDFrameElement.THICKNESS.FRAME
	self.barThickness = barThickness or HUDFrameElement.THICKNESS.BAR
	self:createComponents(posX, posY, width, height)
	return self
end
function HUDFrameElement:createComponents(baseX, baseY, width, height)
	local refPixelX = 1 / g_referenceScreenWidth
	local refPixelY = 1 / g_referenceScreenHeight
	local onePixelX = math.max(refPixelX, g_pixelSizeX)
	local onePixelY = math.max(refPixelY, g_pixelSizeY)
	local posX = baseX
	local posY = baseY + self:getHeight()
	local frameWidth, frameHeight = getNormalizedScreenValues(self.frameThickness, self.frameThickness)
	local pixelsX = math.ceil(frameWidth / onePixelX)
	local pixelsY = math.ceil(frameHeight / onePixelY)
	self.frameWidth = pixelsX * onePixelX
	self.frameHeight = pixelsY * onePixelY
	local lineOverlay = g_overlayManager:createOverlay(g_plainColorSliceId, posX, posY - self.frameHeight, width, self.frameHeight)
	lineOverlay:setColor(unpack(HUDFrameElement.COLOR.FRAME))
	local lineElement = HUDElement.new(lineOverlay)
	self.topLine = lineElement
	self:addChild(lineElement)
	posX = baseX
	posY = baseY + self.frameHeight
	lineOverlay = g_overlayManager:createOverlay(g_plainColorSliceId, posX, posY, self.frameWidth, height - self.frameHeight * 2)
	lineOverlay:setColor(unpack(HUDFrameElement.COLOR.FRAME))
	lineElement = HUDElement.new(lineOverlay)
	self.leftLine = lineElement
	self:addChild(lineElement)
	posX = baseX + width - self.frameWidth
	posY = baseY + self.frameHeight
	lineOverlay = g_overlayManager:createOverlay(g_plainColorSliceId, posX, posY, self.frameWidth, height - self.frameHeight * 2)
	lineOverlay:setColor(unpack(HUDFrameElement.COLOR.FRAME))
	lineElement = HUDElement.new(lineOverlay)
	self.rightLine = lineElement
	self:addChild(lineElement)
	local barSize = self.barThickness
	local barColor = HUDFrameElement.COLOR.BAR
	if not self.showBar then
		barSize = self.frameThickness
		barColor = HUDFrameElement.COLOR.FRAME
	end
	local _, barHeight = getNormalizedScreenValues(0, barSize)
	pixelsY = math.ceil(barHeight / onePixelY)
	local barOverlay = g_overlayManager:createOverlay(g_plainColorSliceId, baseX, baseY, width, pixelsY * onePixelY)
	barOverlay:setColor(unpack(barColor))
	local barElement = HUDElement.new(barOverlay)
	self.bottomBar = barElement
	self:addChild(barElement)
end
function HUDFrameElement:setDimension(width, height)
	HUDFrameElement:superClass().setDimension(self, width, height)
	local lineHeight = nil
	if height ~= nil then
		lineHeight = height - self.frameHeight * 2
	end
	self.topLine:setDimension(width, nil)
	self.leftLine:setDimension(nil, lineHeight)
	self.rightLine:setDimension(nil, lineHeight)
	self.bottomBar:setDimension(width, nil)
	local x, y = self:getPosition()
	self.topLine:setPosition(nil, y + self:getHeight() - self.frameHeight)
	self.rightLine:setPosition(x + self:getWidth() - self.frameWidth, nil)
end
function HUDFrameElement:setBottomBarHeight(height)
	self.bottomBar:setDimension(nil, height)
end
function HUDFrameElement:setBottomBarColor(r, g, b, a)
	self.bottomBar:setColor(r, g, b, a)
end
function HUDFrameElement:setLeftLineVisible(visible)
	self.leftLine:setVisible(visible)
end
function HUDFrameElement:setRightLineVisible(visible)
	self.rightLine:setVisible(visible)
end
function HUDFrameElement:setFrameColor(r, g, b, a)
	self.topLine:setColor(r, g, b, a)
	self.leftLine:setColor(r, g, b, a)
	self.rightLine:setColor(r, g, b, a)
	self.bottomBar:setColor(r, g, b, a)
end
HUDFrameElement.THICKNESS = { FRAME = 1, BAR = 4 }
HUDFrameElement.COLOR = { FRAME = { 1, 1, 1, 0.3 }, BAR = { 0.0227, 0.5346, 0.8519, 1 } }
