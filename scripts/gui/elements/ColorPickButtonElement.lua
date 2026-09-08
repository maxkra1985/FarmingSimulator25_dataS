-- Local values: ColorPickButtonElement_mt
ColorPickButtonElement = {}
local ColorPickButtonElement_mt = Class(ColorPickButtonElement, ButtonElement)
ColorPickButtonElement.ICON_SCALE = 0.5
ColorPickButtonElement.BRIGHTNESS_THRESHOLD = 0.2
Gui.registerGuiElement("ColorPickButton", ColorPickButtonElement)

-- Upvalues: ColorPickButtonElement_mt
-- Local values: self
function ColorPickButtonElement.new(target, custom_mt)
	-- upvalues: (copy) ColorPickButtonElement_mt
	local v4_ = ColorPickButtonElement:superClass().new(target, custom_mt or ColorPickButtonElement_mt)
	v4_.selectionFrameThickness = { 0, 0 }
	v4_.selectionFrameColor = {
		1,
		1,
		1,
		1
	}
	v4_.material = ColorPickerDialog.MATERIAL_GLOSSY
	v4_.glossyIcon = g_overlayManager:createOverlay("gui.glossyBig")
	v4_.glossyIcon:setScale(ColorPickButtonElement.ICON_SCALE, ColorPickButtonElement.ICON_SCALE)
	v4_.metallicIcon = g_overlayManager:createOverlay("gui.metallicBig")
	v4_.metallicIcon:setScale(ColorPickButtonElement.ICON_SCALE, ColorPickButtonElement.ICON_SCALE)
	v4_.matteIcon = g_overlayManager:createOverlay("gui.matteBig")
	v4_.matteIcon:setScale(ColorPickButtonElement.ICON_SCALE, ColorPickButtonElement.ICON_SCALE)
	return v4_
end

function ColorPickButtonElement:loadFromXML(xmlFile, key)
	ColorPickButtonElement:superClass().loadFromXML(self, xmlFile, key)
	self.selectionFrameThickness = GuiUtils.getNormalizedScreenValues(getXMLString(xmlFile, key .. "#selectionFrameThickness"), self.selectionFrameThickness)
	self.selectionFrameColor = GuiUtils.getColorArray(getXMLString(xmlFile, key .. "#selectionFrameColor"), self.selectionFrameColor)
end

function ColorPickButtonElement:loadProfile(profile, applyProfile)
	ColorPickButtonElement:superClass().loadProfile(self, profile, applyProfile)
	self.selectionFrameThickness = GuiUtils.getNormalizedScreenValues(profile:getValue("selectionFrameThickness"), self.selectionFrameThickness)
	self.selectionFrameColor = GuiUtils.getColorArray(profile:getValue("selectionFrameColor"), self.selectionFrameColor)
end

function ColorPickButtonElement:copyAttributes(src)
	ColorPickButtonElement:superClass().copyAttributes(self, src)
	self.selectionFrameThickness = table.clone(src.selectionFrameThickness)
	self.selectionFrameColor = table.clone(src.selectionFrameColor)
	self.material = src.material
end

-- Local values: color
function ColorPickButtonElement:onGuiSetupFinished()
	ColorPickButtonElement:superClass().onGuiSetupFinished(self)
	local v14_ = GuiOverlay.getOverlayColor(self.overlay, GuiOverlay.STATE_NORMAL)
	v14_[1] = 1
	v14_[2] = 1
	v14_[3] = 1
	v14_[4] = 1
	local v15_ = GuiOverlay.getOverlayColor(self.overlay, GuiOverlay.STATE_HIGHLIGHTED)
	v15_[1] = 1
	v15_[2] = 1
	v15_[3] = 1
	v15_[4] = 0.5
	local v16_ = GuiOverlay.getOverlayColor(self.overlay, GuiOverlay.STATE_SELECTED)
	v16_[1] = 1
	v16_[2] = 1
	v16_[3] = 1
	v16_[4] = 1
	local v17_ = GuiOverlay.getOverlayColor(self.overlay, GuiOverlay.STATE_FOCUSED)
	v17_[1] = 1
	v17_[2] = 1
	v17_[3] = 1
	v17_[4] = 1
	local v18_ = GuiOverlay.getOverlayColor(self.overlay, GuiOverlay.STATE_DISABLED)
	v18_[1] = 1
	v18_[2] = 1
	v18_[3] = 1
	v18_[4] = 1
end

function ColorPickButtonElement:delete()
	self.glossyIcon:delete()
	self.metallicIcon:delete()
	self.matteIcon:delete()
	ColorPickButtonElement:superClass().delete(self)
end

-- Local values: posX1, posY1, width, height, selectedX, selectedY, r, g, b, a, posX2, posY2
function ColorPickButtonElement:draw(clipX1, clipY1, clipX2, clipY2)
	local v25_ = GuiUtils.alignValueToScreenPixels(self.absPosition[1], true)
	local v26_ = GuiUtils.alignValueToScreenPixels(self.absPosition[2], true)
	local v27_ = GuiUtils.alignValueToScreenPixels(self.absSize[1], true)
	local v28_ = GuiUtils.alignValueToScreenPixels(self.absSize[2], false)
	if self:getIsSelected() or self:getIsFocused() then
		local v29_ = v25_ + 7 * g_pixelSizeScaledX
		local v30_ = v26_ + 7 * g_pixelSizeScaledY
		GuiOverlay.renderOverlay(self.overlay, v29_, v30_, v27_ - 14 * g_pixelSizeScaledX, v28_ - 14 * g_pixelSizeScaledY, self:getOverlayState(), clipX1, clipY1, clipX2, clipY2)
		local v31_ = self.selectionFrameColor
		local v32_, v33_, v34_, v35_ = unpack(v31_)
		drawFilledRect(v25_, v26_, v27_, self.selectionFrameThickness[2], v32_, v33_, v34_, v35_, clipX1, clipY1, clipX2, clipY2)
		drawFilledRect(v25_, v26_ + v28_ - self.selectionFrameThickness[2], v27_, self.selectionFrameThickness[2], v32_, v33_, v34_, v35_, clipX1, clipY1, clipX2, clipY2)
		drawFilledRect(v25_, v26_, self.selectionFrameThickness[1], v28_, v32_, v33_, v34_, v35_, clipX1, clipY1, clipX2, clipY2)
		drawFilledRect(v25_ + v27_ - self.selectionFrameThickness[1], v26_, self.selectionFrameThickness[1], v28_, v32_, v33_, v34_, v35_, clipX1, clipY1, clipX2, clipY2)
	else
		GuiOverlay.renderOverlay(self.overlay, v25_, v26_, v27_, v28_, self:getOverlayState(), clipX1, clipY1, clipX2, clipY2)
	end
	if self.debugEnabled or g_uiDebugEnabled then
		local v36_ = GuiUtils.alignValueToScreenPixels(self.absPosition[1] + self.absSize[1] - g_pixelSizeX, false)
		local v37_ = GuiUtils.alignValueToScreenPixels(self.absPosition[2] + self.absSize[2] - g_pixelSizeY, false)
		drawFilledRect(v25_, v26_, v36_ - v25_, g_pixelSizeY, 0, 1, 0, 0.7)
		drawFilledRect(v25_, v37_, v36_ - v25_, g_pixelSizeY, 0, 1, 0, 0.7)
		drawFilledRect(v25_, v26_, g_pixelSizeX, v37_ - v26_, 0, 1, 0, 0.7)
		drawFilledRect(v25_ + v36_ - v25_, v26_, g_pixelSizeX, v37_ - v26_, 0, 1, 0, 0.7)
	end
	if self.material == ColorPickerDialog.MATERIAL_GLOSSY then
		self.glossyIcon:render(clipX1, clipY1, clipX2, clipY2, 1)
		return
	elseif self.material == ColorPickerDialog.MATERIAL_METALLIC then
		self.metallicIcon:render(clipX1, clipY1, clipX2, clipY2)
	elseif self.material == ColorPickerDialog.MATERIAL_MATTE then
		self.matteIcon:render(clipX1, clipY1, clipX2, clipY2)
	end
end

-- Local values: color
function ColorPickButtonElement:setColor(r, g, b, a)
	local v43_ = GuiOverlay.getOverlayColor(self.overlay, GuiOverlay.STATE_NORMAL)
	v43_[1] = r
	v43_[2] = g
	v43_[3] = b
	v43_[4] = a or 1
	local v44_ = GuiOverlay.getOverlayColor(self.overlay, GuiOverlay.STATE_HIGHLIGHTED)
	v44_[1] = r
	v44_[2] = g
	v44_[3] = b
	v44_[4] = a or 0.5
	local v45_ = GuiOverlay.getOverlayColor(self.overlay, GuiOverlay.STATE_SELECTED)
	v45_[1] = r
	v45_[2] = g
	v45_[3] = b
	v45_[4] = a or 1
	local v46_ = GuiOverlay.getOverlayColor(self.overlay, GuiOverlay.STATE_FOCUSED)
	v46_[1] = r
	v46_[2] = g
	v46_[3] = b
	v46_[4] = a or 1
	local v47_ = GuiOverlay.getOverlayColor(self.overlay, GuiOverlay.STATE_DISABLED)
	v47_[1] = r
	v47_[2] = g
	v47_[3] = b
	v47_[4] = a or 1
	if MathUtil.getBrightnessFromColor(r, g, b) >= ColorPickButtonElement.BRIGHTNESS_THRESHOLD then
		self.glossyIcon:setColor(0, 0, 0)
		self.metallicIcon:setColor(0, 0, 0)
		self.matteIcon:setColor(0, 0, 0)
	else
		self.glossyIcon:setColor(1, 1, 1)
		self.metallicIcon:setColor(1, 1, 1)
		self.matteIcon:setColor(1, 1, 1)
	end
end

function ColorPickButtonElement:setMaterial(material)
	self.material = material
end

function ColorPickButtonElement:setIsMatte(isMatte)
	if isMatte then
		self:setMaterial(ColorPickerDialog.MATERIAL_MATTE)
	else
		self:setMaterial(ColorPickerDialog.MATERIAL_GLOSSY)
	end
end

function ColorPickButtonElement:setIsMetallic(isMetallic)
	if isMetallic then
		self:setMaterial(ColorPickerDialog.MATERIAL_METALLIC)
	else
		self:setMaterial(ColorPickerDialog.MATERIAL_GLOSSY)
	end
end

-- Local values: iconX, iconY
function ColorPickButtonElement:setPosition(x, y)
	ColorPickButtonElement:superClass().setPosition(self, x, y)
	if self.glossyIcon ~= nil then
		self:setIconPositions(self.absPosition[1] + self.absSize[1] - self.glossyIcon.width - 6 * g_pixelSizeX, self.absPosition[2] + 6 * g_pixelSizeY)
	end
end

function ColorPickButtonElement:setIconPositions(iconX, iconY)
	self.glossyIcon:setPosition(iconX, iconY)
	self.metallicIcon:setPosition(iconX, iconY)
	self.matteIcon:setPosition(iconX, iconY)
end

function ColorPickButtonElement:setColors(r1, g1, b1, r2, g2, b2)
	log("SET COLORS", r1, g1, b1, r2, g2, b2)
end
