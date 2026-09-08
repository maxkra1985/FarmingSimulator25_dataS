-- Local values: PictureElement_mt
PictureElement = {}
local PictureElement_mt = Class(PictureElement, BitmapElement)
Gui.registerGuiElement("Picture", PictureElement)
PictureElement.CONTENT_MODE = {
	["NO_SCALING"] = 0,
	["SCALE_TO_FILL"] = 1,
	["SCALE_ASPECT_FIT"] = 2
}

-- Upvalues: PictureElement_mt
-- Local values: self
function PictureElement.new(target, custom_mt)
	-- upvalues: (copy) PictureElement_mt
	local v4_ = BitmapElement.new(target, custom_mt or PictureElement_mt)
	v4_.contentMode = PictureElement.CONTENT_MODE.SCALE_ASPECT_FIT
	v4_.imageSize = { 2048, 2048 }
	v4_.aspectRatio = 1
	return v4_
end

function PictureElement:loadFromXML(xmlFile, key)
	PictureElement:superClass().loadFromXML(self, xmlFile, key)
	self.imageSize = GuiUtils.getNormalizedScreenValues(getXMLString(xmlFile, key .. "#imageSize"), self.imageSize)
	self.aspectRatio = self.imageSize[1] / self.imageSize[2]
end

-- Local values: mode
function PictureElement:loadProfile(profile, applyProfile)
	PictureElement:superClass().loadProfile(self, profile, applyProfile)
	self.imageSize = GuiUtils.getNormalizedScreenValues(profile:getValue("imageSize"), self.imageSize)
	self.aspectRatio = self.imageSize[1] / self.imageSize[2]
	local v11_ = profile:getValue("pictureContentMode")
	if v11_ == "noScaling" then
		self.contentMode = PictureElement.CONTENT_MODE.NO_SCALING
		return
	elseif v11_ == "scaleToFill" then
		self.contentMode = PictureElement.CONTENT_MODE.SCALE_TO_FILL
	elseif v11_ == "scaleAspectFit" then
		self.contentMode = PictureElement.CONTENT_MODE.SCALE_ASPECT_FIT
	end
end

function PictureElement:copyAttributes(src)
	PictureElement:superClass().copyAttributes(self, src)
	self.contentMode = src.contentMode
	self.aspectRatio = src.aspectRatio
	self.imageSize = src.imageSize
end

function PictureElement:setImageSize(width, height)
	self.imageSize[1] = Utils.getNoNil(width, self.imageSize[1])
	self.imageSize[2] = Utils.getNoNil(height, self.imageSize[2])
	self.aspectRatio = self.imageSize[1] / self.imageSize[2]
end

-- Local values: xScale, yScale
function PictureElement:setAspectRatio(ratio)
	local v19_, v20_ = self:getAspectScale()
	self.aspectRatio = ratio * v19_ / v20_
end

-- Local values: xOffset, yOffset, x, y, width, height, elementAspect, imageAspect, r
function PictureElement:getAdjustedPosition()
	local v22_, v23_ = self:getOffset()
	local v24_ = self.absSize[1]
	local v25_ = self.absSize[2]
	if self.contentMode == PictureElement.CONTENT_MODE.SCALE_TO_FILL then
		if self.absSize[1] / g_aspectScaleX / (self.absSize[2] * g_aspectScaleY) >= self.aspectRatio then
			return v22_, v23_, self.absSize[1], self.absSize[2] * g_screenAspectRatio
		else
			return v22_, v23_, self.absSize[1], self.absSize[2]
		end
	else
		if self.contentMode == PictureElement.CONTENT_MODE.SCALE_ASPECT_FIT then
			local v26_ = g_referenceScreenWidth / g_referenceScreenHeight
			v24_ = self.absSize[1]
			v25_ = v24_ / self.aspectRatio * v26_
			if self.absSize[2] < v25_ then
				v25_ = self.absSize[2]
				v24_ = v25_ * self.aspectRatio / v26_
				v22_ = v22_ + (self.absSize[1] - v24_) / 2
			end
		end
		return v22_, v23_, v24_, v25_
	end
end

-- Local values: x, y, width, height
function PictureElement:draw(clipX1, clipY1, clipX2, clipY2)
	local v32_, v33_, v34_, v35_ = self:getAdjustedPosition()
	GuiOverlay.renderOverlay(self.overlay, self.absPosition[1] + v32_, self.absPosition[2] + v33_, v34_, v35_, self:getOverlayState(), clipX1, clipY1, clipX2, clipY2)
	if self.debugEnabled or g_uiDebugEnabled then
		drawFilledRect(self.absPosition[1] - g_pixelSizeX + v32_, self.absPosition[2] - g_pixelSizeY + v33_, v34_ + 2 * g_pixelSizeX, g_pixelSizeY, 1, 1, 0, 1)
		drawFilledRect(self.absPosition[1] - g_pixelSizeX + v32_, self.absPosition[2] + v35_ + v33_, v34_ + 2 * g_pixelSizeX, g_pixelSizeY, 1, 1, 0, 1)
		drawFilledRect(self.absPosition[1] - g_pixelSizeX + v32_, self.absPosition[2] + v33_, g_pixelSizeX, v35_, 1, 1, 0, 1)
		drawFilledRect(self.absPosition[1] + v34_ + v32_, self.absPosition[2] + v33_, g_pixelSizeX, v35_, 1, 1, 0, 1)
	end
	PictureElement:superClass():superClass().draw(self, clipX1, clipY1, clipX2, clipY2)
end
