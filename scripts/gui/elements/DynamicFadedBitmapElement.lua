-- Local values: DynamicFadedBitmapElement_mt
DynamicFadedBitmapElement = {}
local DynamicFadedBitmapElement_mt = Class(DynamicFadedBitmapElement, PictureElement)
Gui.registerGuiElement("DynamicFadedBitmap", DynamicFadedBitmapElement)

-- Upvalues: DynamicFadedBitmapElement_mt
-- Local values: self
function DynamicFadedBitmapElement.new(target, custom_mt)
	-- upvalues: (copy) DynamicFadedBitmapElement_mt
	local v4_ = DynamicFadedBitmapElement:superClass().new(target, custom_mt or DynamicFadedBitmapElement_mt)
	v4_.templateOverlay = {}
	v4_.fadeTime = 2500
	v4_.fadeInterval = 10000
	v4_.alpha = 1
	v4_.filenames = {}
	v4_.overlays = {}
	v4_.currentImageIndex = 1
	v4_.fadeAlpha = 0
	return v4_
end

-- Local values: _, overlay
function DynamicFadedBitmapElement:delete()
	for _, v6_ in ipairs(self.overlays) do
		GuiOverlay.deleteOverlay(v6_)
	end
	GuiOverlay.deleteOverlay(self.templateOverlay)
	DynamicFadedBitmapElement:superClass().delete(self)
end

function DynamicFadedBitmapElement:loadFromXML(xmlFile, key)
	DynamicFadedBitmapElement:superClass().loadFromXML(self, xmlFile, key)
	self.fadeTime = getXMLInt(xmlFile, key .. "#fadeTime") or self.fadeTime
	self.fadeInterval = getXMLInt(xmlFile, key .. "#fadeInterval") or self.fadeInterval
	GuiOverlay.loadOverlay(self, self.templateOverlay, "image", self.imageSize, nil, xmlFile, key)
	GuiOverlay.createOverlay(self.templateOverlay)
end

-- Local values: oldFilename, oldPreviewFilename, filenameList
function DynamicFadedBitmapElement:loadProfile(profile, applyProfile)
	DynamicFadedBitmapElement:superClass().loadProfile(self, profile, applyProfile)
	self.fadeTime = profile:getNumber("fadeTime", self.fadeTime)
	self.fadeInterval = profile:getNumber("fadeInterval", self.fadeInterval)
	local v13_ = self.templateOverlay.filename
	local v14_ = self.templateOverlay.previewFilename
	GuiOverlay.loadOverlay(self, self.templateOverlay, "image", self.imageSize, profile, nil, nil)
	if v13_ ~= self.templateOverlay.filename or v14_ ~= self.templateOverlay.previewFilename then
		GuiOverlay.createOverlay(self.templateOverlay)
	end
	local v15_ = profile:getValue("imageFilenames")
	if v15_ ~= nil then
		self.filenames = v15_:split(";")
		self:buildOverlays()
	end
end

function DynamicFadedBitmapElement:copyAttributes(src)
	DynamicFadedBitmapElement:superClass().copyAttributes(self, src)
	GuiOverlay.copyOverlay(self.templateOverlay, src.templateOverlay)
	self.filenames = table.clone(src.filenames)
	self.fadeTime = src.fadeTime
	self.fadeInterval = src.fadeInterval
	self:buildOverlays()
end

function DynamicFadedBitmapElement:setAlpha(alpha)
	DynamicFadedBitmapElement:superClass().setAlpha(self, alpha)
	self.alpha = alpha
end

function DynamicFadedBitmapElement:setImageFilenames(filenames)
	self.filenames = filenames
	self:buildOverlays()
end

function DynamicFadedBitmapElement:setImagesUVs(uvs)
	self.uvs = uvs
	self:buildOverlays()
end

-- Local values: i, i, filename
function DynamicFadedBitmapElement:buildOverlays()
	for v25_ = 1, #self.overlays do
		GuiOverlay.deleteOverlay(self.overlays[v25_])
		self.overlays[v25_] = nil
	end
	for v26_, _ in ipairs(self.filenames) do
		self.overlays[v26_] = {}
		GuiOverlay.copyOverlay(self.overlays[v26_], self.templateOverlay, self.filenames[v26_])
		if self.uvs ~= nil then
			self.overlays[v26_].uvs = self.uvs
		end
	end
end

-- Local values: newValue
function DynamicFadedBitmapElement:update(dt)
	DynamicFadedBitmapElement:superClass().update(self, dt)
	if #self.filenames ~= 0 then
		local v29_ = g_time % (self.fadeInterval * #self.filenames)
		local v30_ = v29_ / self.fadeInterval
		self.currentImageIndex = math.floor(v30_) + 1
		self.fadeAlpha = v29_ % self.fadeInterval / self.fadeInterval
	end
end

-- Local values: x, y, w, h, state, primaryIndex, secondaryIndex, alpha, primaryFade, secondaryFade
function DynamicFadedBitmapElement:draw(clipX1, clipY1, clipX2, clipY2)
	local v36_, v37_, v38_, v39_ = self:getAdjustedPosition()
	local v40_ = self:getOverlayState()
	local v41_ = self.currentImageIndex
	local v42_ = v41_ % #self.filenames + 1
	local v43_ = MathUtil.smoothstep(1 - self.fadeTime / self.fadeInterval, 1, self.fadeAlpha)
	self.overlays[v41_].color[4] = 1 * self.alpha
	GuiOverlay.renderOverlay(self.overlays[v41_], v36_, v37_, v38_, v39_, v40_, clipX1, clipY1, clipX2, clipY2)
	if v43_ > 0 then
		self.overlays[v42_].color[4] = v43_ * self.alpha
		GuiOverlay.renderOverlay(self.overlays[v42_], v36_, v37_, v38_, v39_, v40_, clipX1, clipY1, clipX2, clipY2)
	end
end

-- Local values: _, v
function DynamicFadedBitmapElement:canReceiveFocus()
	if not self.visible or #self.elements < 1 then
		return false
	end
	for _, v45_ in ipairs(self.elements) do
		if not v45_:canReceiveFocus() then
			return false
		end
	end
	return true
end

-- Local values: _, firstElement
function DynamicFadedBitmapElement:getFocusTarget()
	if #self.elements > 0 then
		local _, v47_ = next(self.elements)
		if v47_ then
			return v47_
		end
	end
	return self
end
