-- Local values: BitmapElement_mt
BitmapElement = {}
local BitmapElement_mt = Class(BitmapElement, GuiElement)
Gui.registerGuiElement("Bitmap", BitmapElement)

-- Upvalues: BitmapElement_mt
-- Local values: self
function BitmapElement.new(target, custom_mt)
	-- upvalues: (copy) BitmapElement_mt
	local v4_ = GuiElement.new(target, custom_mt or BitmapElement_mt)
	v4_.imageSize = { 2048, 2048 }
	v4_.offset = { 0, 0 }
	v4_.overlay = {}
	v4_.overlayMaskSize = nil
	v4_.overlayMaskPos = nil
	return v4_
end

function BitmapElement:delete()
	GuiOverlay.deleteOverlay(self.overlay)
	BitmapElement:superClass().delete(self)
end

function BitmapElement:loadFromXML(xmlFile, key)
	BitmapElement:superClass().loadFromXML(self, xmlFile, key)
	self.imageSize = string.getVector(getXMLString(xmlFile, key .. "#imageSize"), 2) or self.imageSize
	GuiOverlay.loadOverlay(self, self.overlay, "image", self.imageSize, nil, xmlFile, key)
	self.offset = GuiUtils.getNormalizedScreenValues(getXMLString(xmlFile, key .. "#offset"), self.offset)
	self.focusedOffset = GuiUtils.getNormalizedScreenValues(getXMLString(xmlFile, key .. "#focusedOffset"), self.focusedOffset)
	self.selectedOffset = GuiUtils.getNormalizedScreenValues(getXMLString(xmlFile, key .. "#selectedOffset"), self.selectedOffset)
	self.highlightedOffset = GuiUtils.getNormalizedScreenValues(getXMLString(xmlFile, key .. "#highlightedOffset"), self.highlightedOffset)
	self.pressedOffset = GuiUtils.getNormalizedScreenValues(getXMLString(xmlFile, key .. "#pressedOffset"), self.pressedOffset)
	self.invertX = Utils.getNoNil(getXMLBool(xmlFile, key .. "#invertX"), self.invertX)
	self.invertY = Utils.getNoNil(getXMLBool(xmlFile, key .. "#invert>"), self.invertY)
	self.overlayMaskPos = GuiUtils.getNormalizedScreenValues(getXMLString(xmlFile, key .. "#overlayMaskPos")) or self.overlayMaskPos
	self.overlayMaskSize = GuiUtils.getNormalizedScreenValues(getXMLString(xmlFile, key .. "#overlayMaskSize")) or self.overlayMaskSize
	GuiOverlay.createOverlay(self.overlay)
end

-- Local values: oldFilename, oldPreviewFilename
function BitmapElement:loadProfile(profile, applyProfile)
	BitmapElement:superClass().loadProfile(self, profile, applyProfile)
	self.imageSize = string.getVector(profile:getValue("imageSize"), 2) or self.imageSize
	local v12_ = self.overlay.filename
	local v13_ = self.overlay.previewFilename
	GuiOverlay.loadOverlay(self, self.overlay, "image", self.imageSize, profile, nil, nil)
	self.offset = GuiUtils.getNormalizedScreenValues(profile:getValue("offset"), self.offset)
	self.focusedOffset = GuiUtils.getNormalizedScreenValues(profile:getValue("focusedOffset"), self.focusedOffset)
	self.selectedOffset = GuiUtils.getNormalizedScreenValues(profile:getValue("selectedOffset"), self.selectedOffset)
	self.highlightedOffset = GuiUtils.getNormalizedScreenValues(profile:getValue("highlightedOffset"), self.highlightedOffset)
	self.pressedOffset = GuiUtils.getNormalizedScreenValues(profile:getValue("pressedOffset"), self.pressedOffset)
	self.invertX = profile:getBool("invertX", self.invertX)
	self.invertY = profile:getBool("invertY", self.invertY)
	self.overlayMaskPos = GuiUtils.getNormalizedScreenValues(profile:getValue("overlayMaskPos")) or self.overlayMaskPos
	self.overlayMaskSize = GuiUtils.getNormalizedScreenValues(profile:getValue("overlayMaskSize")) or self.overlayMaskSize
	if v12_ ~= self.overlay.filename or v13_ ~= self.overlay.previewFilename then
		GuiOverlay.deleteOverlay(self.overlay)
		GuiOverlay.createOverlay(self.overlay)
	end
end

function BitmapElement:copyAttributes(src)
	BitmapElement:superClass().copyAttributes(self, src)
	self.imageSize = table.clone(src.imageSize)
	GuiOverlay.copyOverlay(self.overlay, src.overlay)
	self.offset = table.clone(src.offset)
	if src.focusedOffset ~= nil then
		self.focusedOffset = table.clone(src.focusedOffset)
	end
	if src.selectedOffset ~= nil then
		self.selectedOffset = table.clone(src.selectedOffset)
	end
	if src.highlightedOffset ~= nil then
		self.highlightedOffset = table.clone(src.highlightedOffset)
	end
	if src.pressedOffset ~= nil then
		self.pressedOffset = table.clone(src.pressedOffset)
	end
	self.overlayMaskPos = src.overlayMaskPos
	self.overlayMaskSize = src.overlayMaskSize
	self.invertX = src.invertX
	self.invertY = src.invertY
end

function BitmapElement:setAlpha(alpha)
	BitmapElement:superClass().setAlpha(self, alpha)
	if self.overlay ~= nil then
		self.overlay.alpha = self.alpha
	end
end

-- Local values: state, xOffset, yOffset
function BitmapElement:getOffset()
	local v19_ = self:getOverlayState()
	local v20_ = self.offset[1]
	local v21_ = self.offset[2]
	if v19_ == GuiOverlay.STATE_FOCUSED and self.focusedOffset ~= nil then
		return self.focusedOffset[1], self.focusedOffset[2]
	end
	if v19_ == GuiOverlay.STATE_SELECTED and self.selectedOffset ~= nil then
		return self.selectedOffset[1], self.selectedOffset[2]
	end
	if v19_ == GuiOverlay.STATE_HIGHLIGHTED and self.highlightedOffset ~= nil then
		return self.highlightedOffset[1], self.highlightedOffset[2]
	end
	if v19_ == GuiOverlay.STATE_PRESSED and self.pressedOffset ~= nil then
		v20_ = self.pressedOffset[1]
		v21_ = self.pressedOffset[2]
	end
	return v20_, v21_
end

-- Local values: overlayMaskPosX, overlayMaskPosY, overlayMaskSizeX, overlayMaskSizeY
function BitmapElement:getOverlayMaskData(xOffset, yOffset)
	local v23_
	if self.overlayMaskPos == nil then
		v23_ = nil
	else
		v23_ = self.overlayMaskPos[1] or nil
	end
	local v24_
	if self.overlayMaskPos == nil then
		v24_ = nil
	else
		v24_ = self.overlayMaskPos[2] or nil
	end
	local v25_
	if self.overlayMaskSize == nil then
		v25_ = nil
	else
		v25_ = self.overlayMaskSize[1] or nil
	end
	local v26_
	if self.overlayMaskSize == nil then
		v26_ = nil
	else
		v26_ = self.overlayMaskSize[2] or nil
	end
	return v23_, v24_, v25_, v26_
end

function BitmapElement:setIsWebOverlay(isWebOverlay)
	self.overlay.isWebOverlay = isWebOverlay
end

function BitmapElement:setImageFilename(filename)
	self.overlay = GuiOverlay.createOverlay(self.overlay, filename)
end

-- Local values: color
function BitmapElement:setImageColor(state, r, g, b, a)
	local v37_ = GuiOverlay.getOverlayColor(self.overlay, state)
	v37_[1] = r or v37_[1]
	v37_[2] = g or v37_[2]
	v37_[3] = b or v37_[3]
	v37_[4] = a or v37_[4]
end

-- Local values: uvs
function BitmapElement:setImageUVs(state, v0, u0, v1, u1, v2, u2, v3, u3)
	local v48_ = Utils.getNoNil(state, self:getOverlayState())
	local v49_ = GuiOverlay.getOverlayUVs(self.overlay, v48_)
	v49_[1] = v0 or v49_[1]
	v49_[2] = u0 or v49_[2]
	v49_[3] = v1 or v49_[3]
	v49_[4] = u1 or v49_[4]
	v49_[5] = v2 or v49_[5]
	v49_[6] = u2 or v49_[6]
	v49_[7] = v3 or v49_[7]
	v49_[8] = u3 or v49_[8]
	if self.invertX then
		GuiUtils.invertUVs(v49_, true)
	end
	if self.invertY then
		GuiUtils.invertUVs(v49_, false)
	end
end

function BitmapElement:setImageRotation(rotation)
	self.overlay.rotation = rotation
end

-- Local values: slice
function BitmapElement:setImageSlice(state, sliceId)
	local v55_ = g_overlayManager:getSliceInfoById(sliceId)
	if v55_ ~= nil then
		local v56_ = v55_.uvs
		self:setImageUVs(state, unpack(v56_))
		self:setImageFilename(v55_.filename)
		self.overlay.sliceId = sliceId
	end
end

-- Local values: xOffset, yOffset, overlayMaskPosX, overlayMaskPosY, overlayMaskSizeX, overlayMaskSizeY
function BitmapElement:draw(clipX1, clipY1, clipX2, clipY2)
	local v62_, v63_ = self:getOffset()
	local v64_, v65_, v66_, v67_ = self:getOverlayMaskData(v62_, v63_)
	GuiOverlay.renderOverlay(self.overlay, self.absPosition[1] + v62_, self.absPosition[2] + v63_, self.absSize[1], self.absSize[2], self:getOverlayState(), clipX1, clipY1, clipX2, clipY2, v64_, v65_, v66_, v67_)
	BitmapElement:superClass().draw(self, clipX1, clipY1, clipX2, clipY2)
end

-- Local values: _, v
function BitmapElement:canReceiveFocus()
	if not self.visible or #self.elements < 1 then
		return false
	end
	for _, v69_ in ipairs(self.elements) do
		if not v69_:canReceiveFocus() then
			return false
		end
	end
	return true
end

-- Local values: _, firstElement
function BitmapElement:getFocusTarget()
	if #self.elements > 0 then
		local _, v71_ = next(self.elements)
		if v71_ then
			return v71_
		end
	end
	return self
end
