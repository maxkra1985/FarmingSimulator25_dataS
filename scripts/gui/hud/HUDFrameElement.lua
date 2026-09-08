-- Local values: HUDFrameElement_mt
HUDFrameElement = {}
local HUDFrameElement_mt = Class(HUDFrameElement, HUDElement)

-- Upvalues: HUDFrameElement_mt
-- Local values: backgroundOverlay, self
function HUDFrameElement.new(posX, posY, width, height, parent, showBar, frameThickness, barThickness)
	-- upvalues: (copy) HUDFrameElement_mt
	local v10_ = g_overlayManager:createOverlay(g_plainColorSliceId, posX, posY, width, height)
	v10_:setColor(0, 0, 0, 0)
	local v11_ = HUDElement.new(v10_, parent, HUDFrameElement_mt)
	v11_.topLine = nil
	v11_.leftLine = nil
	v11_.rightLine = nil
	v11_.bottomBar = nil
	v11_.frameWidth = 0
	v11_.frameHeight = 0
	v11_.showBar = Utils.getNoNil(showBar, true)
	v11_.frameThickness = frameThickness or HUDFrameElement.THICKNESS.FRAME
	v11_.barThickness = barThickness or HUDFrameElement.THICKNESS.BAR
	v11_:createComponents(posX, posY, width, height)
	return v11_
end

-- Local values: refPixelX, refPixelY, onePixelX, onePixelY, posX, posY, frameWidth, frameHeight, pixelsX, pixelsY, lineOverlay, lineElement, barSize, barColor, _, barHeight, barOverlay, barElement
function HUDFrameElement:createComponents(baseX, baseY, width, height)
	local v17_ = 1 / g_referenceScreenWidth
	local v18_ = 1 / g_referenceScreenHeight
	local v19_ = g_pixelSizeX
	local v20_ = math.max(v17_, v19_)
	local v21_ = g_pixelSizeY
	local v22_ = math.max(v18_, v21_)
	local v23_ = baseY + self:getHeight()
	local v24_, v25_ = getNormalizedScreenValues(self.frameThickness, self.frameThickness)
	local v26_ = v24_ / v20_
	local v27_ = math.ceil(v26_)
	local v28_ = v25_ / v22_
	local v29_ = math.ceil(v28_)
	local v30_ = v27_ * v20_
	local v31_ = v29_ * v22_
	self.frameWidth = v30_
	self.frameHeight = v31_
	local v32_ = g_overlayManager:createOverlay(g_plainColorSliceId, baseX, v23_ - self.frameHeight, width, self.frameHeight)
	local v33_ = HUDFrameElement.COLOR.FRAME
	v32_:setColor(unpack(v33_))
	local v34_ = HUDElement.new(v32_)
	self.topLine = v34_
	self:addChild(v34_)
	local v35_ = baseY + self.frameHeight
	local v36_ = g_overlayManager:createOverlay(g_plainColorSliceId, baseX, v35_, self.frameWidth, height - self.frameHeight * 2)
	local v37_ = HUDFrameElement.COLOR.FRAME
	v36_:setColor(unpack(v37_))
	local v38_ = HUDElement.new(v36_)
	self.leftLine = v38_
	self:addChild(v38_)
	local v39_ = baseX + width - self.frameWidth
	local v40_ = baseY + self.frameHeight
	local v41_ = g_overlayManager:createOverlay(g_plainColorSliceId, v39_, v40_, self.frameWidth, height - self.frameHeight * 2)
	local v42_ = HUDFrameElement.COLOR.FRAME
	v41_:setColor(unpack(v42_))
	local v43_ = HUDElement.new(v41_)
	self.rightLine = v43_
	self:addChild(v43_)
	local v44_ = self.barThickness
	local v45_ = HUDFrameElement.COLOR.BAR
	if not self.showBar then
		v44_ = self.frameThickness
		v45_ = HUDFrameElement.COLOR.FRAME
	end
	local _, v46_ = getNormalizedScreenValues(0, v44_)
	local v47_ = v46_ / v22_
	local v48_ = math.ceil(v47_)
	local v49_ = g_overlayManager:createOverlay(g_plainColorSliceId, baseX, baseY, width, v48_ * v22_)
	v49_:setColor(unpack(v45_))
	local v50_ = HUDElement.new(v49_)
	self.bottomBar = v50_
	self:addChild(v50_)
end

-- Local values: lineHeight, x, y
function HUDFrameElement:setDimension(width, height)
	HUDFrameElement:superClass().setDimension(self, width, height)
	local v54_
	if height == nil then
		v54_ = nil
	else
		v54_ = height - self.frameHeight * 2
	end
	self.topLine:setDimension(width, nil)
	self.leftLine:setDimension(nil, v54_)
	self.rightLine:setDimension(nil, v54_)
	self.bottomBar:setDimension(width, nil)
	local v55_, v56_ = self:getPosition()
	self.topLine:setPosition(nil, v56_ + self:getHeight() - self.frameHeight)
	self.rightLine:setPosition(v55_ + self:getWidth() - self.frameWidth, nil)
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
HUDFrameElement.THICKNESS = {
	["FRAME"] = 1,
	["BAR"] = 4
}
HUDFrameElement.COLOR = {
	["FRAME"] = {
		1,
		1,
		1,
		0.3
	},
	["BAR"] = {
		0.0227,
		0.5346,
		0.8519,
		1
	}
}
