-- Local values: HUDRoundedBarElement_mt
HUDRoundedBarElement = {}
local HUDRoundedBarElement_mt = Class(HUDRoundedBarElement, HUDElement)

-- Upvalues: HUDRoundedBarElement_mt
-- Local values: overlay, self
function HUDRoundedBarElement.new(posX, posY, width, height, isHorizontal, customMt)
	-- upvalues: (copy) HUDRoundedBarElement_mt
	local v8_ = Overlay.new(nil, posX, posY, width, height)
	local v9_ = HUDElement.new(v8_, nil, customMt or HUDRoundedBarElement_mt)
	v9_.isHorizontal = isHorizontal or false
	v9_.xPadding = 0
	v9_.yPadding = 0
	v9_.value = 0
	v9_:createComponents()
	return v9_
end

function HUDRoundedBarElement:delete()
	if self.overlayFront ~= nil then
		self.overlayFront:delete()
		self.overlayFront = nil
		self.overlayMiddle:delete()
		self.overlayMiddle = nil
		self.overlayBack:delete()
		self.overlayBack = nil
		self.barOverlayFront:delete()
		self.barOverlayFront = nil
		self.barOverlayMiddle:delete()
		self.barOverlayMiddle = nil
		self.barOverlayBack:delete()
		self.barOverlayBack = nil
	end
	HUDRoundedBarElement:superClass().delete(self)
end

-- Local values: sliceIds
function HUDRoundedBarElement:createComponents()
	local v12_ = HUDRoundedBarElement.SLICE_IDS.HORIZONTAL[self.isHorizontal]
	self.overlayFront = g_overlayManager:createOverlay(v12_.FRONT)
	local v13_ = self.overlayFront
	local v14_ = HUDRoundedBarElement.COLOR.BACKGROUND
	v13_:setColor(unpack(v14_))
	self.overlayMiddle = g_overlayManager:createOverlay(v12_.MIDDLE)
	local v15_ = self.overlayMiddle
	local v16_ = HUDRoundedBarElement.COLOR.BACKGROUND
	v15_:setColor(unpack(v16_))
	self.overlayBack = g_overlayManager:createOverlay(v12_.BACK)
	local v17_ = self.overlayBack
	local v18_ = HUDRoundedBarElement.COLOR.BACKGROUND
	v17_:setColor(unpack(v18_))
	self.barOverlayFront = g_overlayManager:createOverlay(v12_.FRONT)
	self.barOverlayMiddle = g_overlayManager:createOverlay(v12_.MIDDLE)
	self.barOverlayBack = g_overlayManager:createOverlay(v12_.BACK)
	self:updateComponents()
end

function HUDRoundedBarElement:setValue(value, d)
	local v21_ = math.clamp(value, 0, 1)
	local v22_ = v21_ - self.value
	if math.abs(v22_) > 0.005 then
		self.value = v21_
		self:updateComponents(true)
	end
end

function HUDRoundedBarElement:setBarColor(r, g, b)
	self.barOverlayFront:setColor(r, g, b, 1)
	self.barOverlayMiddle:setColor(r, g, b, 1)
	self.barOverlayBack:setColor(r, g, b, 1)
end

function HUDRoundedBarElement:setBarAlpha(alpha)
	self.barOverlayFront:setColor(nil, nil, nil, alpha)
	self.barOverlayMiddle:setColor(nil, nil, nil, alpha)
	self.barOverlayBack:setColor(nil, nil, nil, alpha)
end

function HUDRoundedBarElement:setPosition(x, y)
	HUDRoundedBarElement:superClass().setPosition(self, x, y)
	self:updateComponents()
end

-- Local values: origAlpha
function HUDRoundedBarElement:setAlpha(alpha)
	self.overlay:setColor(nil, nil, nil, alpha)
	self.barOverlayFront:setColor(nil, nil, nil, alpha)
	self.barOverlayMiddle:setColor(nil, nil, nil, alpha)
	self.barOverlayBack:setColor(nil, nil, nil, alpha)
	local v34_ = HUDRoundedBarElement.COLOR.BACKGROUND[4]
	self.overlayFront:setColor(nil, nil, nil, alpha * v34_)
	self.overlayMiddle:setColor(nil, nil, nil, alpha * v34_)
	self.overlayBack:setColor(nil, nil, nil, alpha * v34_)
end

function HUDRoundedBarElement:setDimension(width, height)
	self.overlay:setDimension(width, height)
	self:updateComponents()
end

-- Local values: baseX, baseY, width, height, endSizeX, endSizeY, paddingX, paddingY, endWidth, barWidth, barHeight, endWidth, barWidthValued, endHeight, barWidth, barHeight, endHeight, barHeightValued
function HUDRoundedBarElement:updateComponents(barOnly)
	local v40_ = self.overlay.x
	local v41_ = self.overlay.y
	local v42_ = self.overlay.width
	local v43_ = self.overlay.height
	local v44_ = g_overlayManager:getSliceInfoById(HUDRoundedBarElement.SLICE_IDS.HORIZONTAL[self.isHorizontal].BACK).uvs
	local v45_, v46_ = unpack(v44_)
	local v47_ = getNormalizedScreenValues
	local v48_ = HUDRoundedBarElement.PADDING[self.isHorizontal]
	local v49_, v50_ = v47_(unpack(v48_))
	if self.isHorizontal then
		if not barOnly then
			local v51_ = v45_ / v46_ * v43_
			self.overlayFront:setDimension(v51_, v43_)
			self.overlayFront:setPosition(v40_, v41_)
			self.overlayMiddle:setDimension(v42_ - 2 * v51_, v43_)
			self.overlayMiddle:setPosition(v40_ + v51_, v41_)
			self.overlayBack:setDimension(v51_, v43_)
			self.overlayBack:setPosition(v40_ + v42_ - v51_, v41_)
		end
		local v52_ = v42_ - 2 * v49_
		local v53_ = v43_ - 2 * v50_
		local v54_ = 1 * g_pixelSizeY
		local v55_ = math.max(v53_, v54_)
		local v56_ = v45_ / v46_ * v55_
		local v57_ = (v52_ - 2 * v56_) * self.value + 2 * v56_
		self.barOverlayFront:setDimension(v56_, v55_)
		self.barOverlayFront:setPosition(v40_ + v49_, v41_ + v50_)
		self.barOverlayMiddle:setDimension(v57_ - 2 * v56_, v55_)
		self.barOverlayMiddle:setPosition(v40_ + v49_ + v56_, v41_ + v50_)
		self.barOverlayBack:setDimension(v56_, v55_)
		self.barOverlayBack:setPosition(v40_ + v49_ + v57_ - v56_, v41_ + v50_)
	else
		if not barOnly then
			local v58_ = v46_ / v45_ * v42_
			self.overlayFront:setDimension(v42_, v58_)
			self.overlayFront:setPosition(v40_, v41_)
			self.overlayMiddle:setDimension(v42_, v43_ - 2 * v58_)
			self.overlayMiddle:setPosition(v40_, v41_ + v58_)
			self.overlayBack:setDimension(v42_, v58_)
			self.overlayBack:setPosition(v40_, v41_ + v43_ - v58_)
		end
		local v59_ = v42_ - 2 * v49_
		local v60_ = g_pixelSizeX
		local v61_ = math.max(v59_, v60_)
		local v62_ = v43_ - 2 * v50_
		local v63_ = v46_ / v45_ * v61_
		local v64_ = (v62_ - 2 * v63_) * self.value + 2 * v63_
		self.barOverlayFront:setDimension(v61_, v63_)
		self.barOverlayFront:setPosition(v40_ + v49_, v41_ + v50_)
		self.barOverlayMiddle:setDimension(v61_, v64_ - 2 * v63_)
		self.barOverlayMiddle:setPosition(v40_ + v49_, v41_ + v50_ + v63_)
		self.barOverlayBack:setDimension(v61_, v63_)
		self.barOverlayBack:setPosition(v40_ + v49_, v41_ + v50_ + v64_ - v63_)
	end
end

function HUDRoundedBarElement:draw()
	if self.overlay.visible then
		self.overlayFront:render()
		self.overlayMiddle:render()
		self.overlayBack:render()
		self.barOverlayFront:render()
		self.barOverlayMiddle:render()
		self.barOverlayBack:render()
	end
end
HUDRoundedBarElement.PADDING = {
	[true] = { 3.5, 3 },
	[false] = { 3, 3.5 }
}
local v66_ = HUDRoundedBarElement
local v67_ = {}
local v68_ = {
	[true] = {
		["FRONT"] = "gui.whiteBarHorizontalEnd",
		["MIDDLE"] = "gui.whiteBarHorizontalMid",
		["BACK"] = "gui.whiteBarHorizontalStart"
	},
	[false] = {
		["FRONT"] = "gui.whiteBarVerticalEnd",
		["MIDDLE"] = "gui.whiteBarVerticalMid",
		["BACK"] = "gui.whiteBarVerticalStart"
	}
}
v67_.HORIZONTAL = v68_
v66_.SLICE_IDS = v67_
HUDRoundedBarElement.COLOR = {
	["BACKGROUND"] = {
		0,
		0,
		0,
		0.54
	}
}
