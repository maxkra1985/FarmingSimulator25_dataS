-- Local values: ThreePartBitmapElement_mt
ThreePartBitmapElement = {}
local ThreePartBitmapElement_mt = Class(ThreePartBitmapElement, BitmapElement)
Gui.registerGuiElement("ThreePartBitmap", ThreePartBitmapElement)

-- Upvalues: ThreePartBitmapElement_mt
-- Local values: self
function ThreePartBitmapElement.new(target, custom_mt)
	-- upvalues: (copy) ThreePartBitmapElement_mt
	local v4_ = BitmapElement.new(target, custom_mt or ThreePartBitmapElement_mt)
	v4_.startOverlay = {}
	v4_.endOverlay = {}
	v4_.startSize = { 0, 0 }
	v4_.endSize = { 0, 0 }
	v4_.isHorizontal = true
	return v4_
end

function ThreePartBitmapElement:delete()
	GuiOverlay.deleteOverlay(self.startOverlay)
	GuiOverlay.deleteOverlay(self.endOverlay)
	ThreePartBitmapElement:superClass().delete(self)
end

function ThreePartBitmapElement:loadFromXML(xmlFile, key)
	ThreePartBitmapElement:superClass().loadFromXML(self, xmlFile, key)
	GuiOverlay.loadOverlay(self, self.startOverlay, "startImage", self.imageSize, nil, xmlFile, key)
	GuiOverlay.loadOverlay(self, self.endOverlay, "endImage", self.imageSize, nil, xmlFile, key)
	self.startSize = GuiUtils.getNormalizedScreenValues(getXMLString(xmlFile, key .. "#startImageSize"), self.startSize)
	self.endSize = GuiUtils.getNormalizedScreenValues(getXMLString(xmlFile, key .. "#endImageSize"), self.endSize)
	self.isHorizontal = Utils.getNoNil(getXMLBool(xmlFile, key .. "#isHorizontal"), self.isHorizontal)
	GuiOverlay.createOverlay(self.startOverlay)
	GuiOverlay.createOverlay(self.endOverlay)
	local v9_ = GuiOverlay.getOverlayColor
	local v10_ = self.overlay
	local v11_ = GuiOverlay.STATE_NORMAL
	self:setImageColor(nil, unpack(v9_(v10_, v11_)))
end

-- Local values: startOld, endOld
function ThreePartBitmapElement:loadProfile(profile, applyProfile)
	ThreePartBitmapElement:superClass().loadProfile(self, profile, applyProfile)
	local v15_ = self.startOverlay.filename
	local v16_ = self.endOverlay.filename
	GuiOverlay.loadOverlay(self, self.startOverlay, "startImage", self.imageSize, profile, nil, nil)
	GuiOverlay.loadOverlay(self, self.endOverlay, "endImage", self.imageSize, profile, nil, nil)
	self.startSize = GuiUtils.getNormalizedScreenValues(profile:getValue("startImageSize"), self.startSize)
	self.endSize = GuiUtils.getNormalizedScreenValues(profile:getValue("endImageSize"), self.endSize)
	self.isHorizontal = profile:getBool("isHorizontal", self.isHorizontal)
	if v15_ ~= self.startOverlay.filename then
		GuiOverlay.createOverlay(self.startOverlay)
	end
	if v16_ ~= self.endOverlay.filename then
		GuiOverlay.createOverlay(self.endOverlay)
	end
end

function ThreePartBitmapElement:copyAttributes(src)
	ThreePartBitmapElement:superClass().copyAttributes(self, src)
	self.startSize = table.clone(src.startSize)
	self.endSize = table.clone(src.endSize)
	self.isHorizontal = src.isHorizontal
	GuiOverlay.copyOverlay(self.startOverlay, src.startOverlay)
	GuiOverlay.copyOverlay(self.endOverlay, src.endOverlay)
end

-- Local values: color
function ThreePartBitmapElement:setImageColor(state, r, g, b, a)
	ThreePartBitmapElement:superClass().setImageColor(self, state, r, g, b, a)
	local v25_ = GuiOverlay.getOverlayColor(self.startOverlay, state)
	v25_[1] = r or v25_[1]
	v25_[2] = g or v25_[2]
	v25_[3] = b or v25_[3]
	v25_[4] = a or v25_[4]
	local v26_ = GuiOverlay.getOverlayColor(self.endOverlay, state)
	v26_[1] = r or v26_[1]
	v26_[2] = g or v26_[2]
	v26_[3] = b or v26_[3]
	v26_[4] = a or v26_[4]
end

-- Local values: xOffset, yOffset, x, y, state
function ThreePartBitmapElement:draw(clipX1, clipY1, clipX2, clipY2)
	local v32_, v33_ = self:getOffset()
	local v34_ = self.absPosition[1] + v32_
	local v35_ = self.absPosition[2] + v33_
	local v36_ = self:getOverlayState()
	if self.isHorizontal then
		GuiOverlay.renderOverlay(self.startOverlay, v34_, v35_, self.startSize[1], self.absSize[2], v36_, clipX1, clipY1, clipX2, clipY2)
		GuiOverlay.renderOverlay(self.overlay, v34_ + self.startSize[1], v35_, self.absSize[1] - self.startSize[1] - self.endSize[1], self.absSize[2], v36_, clipX1, clipY1, clipX2, clipY2)
		GuiOverlay.renderOverlay(self.endOverlay, v34_ + self.absSize[1] - self.endSize[1], v35_, self.endSize[1], self.absSize[2], v36_, clipX1, clipY1, clipX2, clipY2)
	else
		GuiOverlay.renderOverlay(self.startOverlay, v34_, v35_ + self.absSize[2] - self.startSize[2], self.absSize[1], self.startSize[2], v36_, clipX1, clipY1, clipX2, clipY2)
		GuiOverlay.renderOverlay(self.overlay, v34_, v35_ + self.endSize[2], self.absSize[1], self.absSize[2] - self.startSize[2] - self.endSize[2], v36_, clipX1, clipY1, clipX2, clipY2)
		GuiOverlay.renderOverlay(self.endOverlay, v34_, v35_, self.absSize[1], self.endSize[2], v36_, clipX1, clipY1, clipX2, clipY2)
	end
	BitmapElement:superClass().draw(self, clipX1, clipY1, clipX2, clipY2)
end
