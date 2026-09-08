-- Local values: BitmapElement_mt
ClearElement = {}
local BitmapElement_mt = Class(ClearElement, GuiElement)
Gui.registerGuiElement("Clear", ClearElement)

-- Upvalues: BitmapElement_mt
-- Local values: self
function ClearElement.new(target, custom_mt)
	-- upvalues: (copy) BitmapElement_mt
	local v4_ = GuiElement.new(target, custom_mt or BitmapElement_mt)
	v4_.offset = { 0, 0 }
	v4_.focusedOffset = { 0, 0 }
	v4_.overlay = {}
	return v4_
end

function ClearElement:delete()
	GuiOverlay.deleteOverlay(self.overlay)
	ClearElement:superClass().delete(self)
end

function ClearElement:loadFromXML(xmlFile, key)
	ClearElement:superClass().loadFromXML(self, xmlFile, key)
	GuiOverlay.loadOverlay(self, self.overlay, "clear", self.imageSize, nil, xmlFile, key)
	self.offset = GuiUtils.getNormalizedScreenValues(getXMLString(xmlFile, key .. "#offset"), self.offset)
	self.focusedOffset = GuiUtils.getNormalizedScreenValues(getXMLString(xmlFile, key .. "#focusedOffset"), self.focusedOffset)
end

function ClearElement:loadProfile(profile, applyProfile)
	ClearElement:superClass().loadProfile(self, profile, applyProfile)
	GuiOverlay.loadOverlay(self, self.overlay, "clear", self.imageSize, profile, nil, nil)
	self.offset = GuiUtils.getNormalizedScreenValues(profile:getValue("offset"), self.offset)
	self.focusedOffset = GuiUtils.getNormalizedScreenValues(profile:getValue("focusedOffset"), { self.offset[1], self.offset[2] })
end

function ClearElement:copyAttributes(src)
	ClearElement:superClass().copyAttributes(self, src)
	GuiOverlay.copyOverlay(self.overlay, src.overlay)
	self.offset = table.clone(src.offset)
	self.focusedOffset = table.clone(src.focusedOffset)
end

-- Local values: xOffset, yOffset, state
function ClearElement:getOffset()
	local v15_ = self.offset[1]
	local v16_ = self.offset[2]
	local v17_ = self:getOverlayState()
	if v17_ == GuiOverlay.STATE_FOCUSED or (v17_ == GuiOverlay.STATE_PRESSED or (v17_ == GuiOverlay.STATE_SELECTED or GuiOverlay.STATE_HIGHLIGHTED)) then
		v15_ = self.focusedOffset[1]
		v16_ = self.focusedOffset[2]
	end
	return v15_, v16_
end

function ClearElement:setImageRotation(rotation)
	self.overlay.rotation = rotation
end

-- Local values: xOffset, yOffset
function ClearElement:draw(clipX1, clipY1, clipX2, clipY2)
	local v25_, v26_ = self:getOffset()
	clearOverlayArea(self.absPosition[1] + v25_, self.absPosition[2] + v26_, self.size[1], self.size[2], self.overlay.rotation, self.size[1] / 2, self.size[2] / 2)
	ClearElement:superClass().draw(self, clipX1, clipY1, clipX2, clipY2)
end

-- Local values: _, v
function ClearElement:canReceiveFocus()
	if not self.visible or #self.elements < 1 then
		return false
	end
	for _, v28_ in ipairs(self.elements) do
		if not v28_:canReceiveFocus() then
			return false
		end
	end
	return true
end

-- Local values: _, firstElement
function ClearElement:getFocusTarget()
	local _, v30_ = next(self.elements)
	return v30_ or self
end
