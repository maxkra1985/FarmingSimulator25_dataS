-- Local values: TimerElement_mt
TimerElement = {}
local TimerElement_mt = Class(TimerElement, GuiElement)
Gui.registerGuiElement("Timer", TimerElement)

-- Upvalues: TimerElement_mt
-- Local values: self
function TimerElement.new(target, custom_mt)
	-- upvalues: (copy) TimerElement_mt
	if custom_mt == nil then
		custom_mt = TimerElement_mt
	end
	local v4_ = GuiElement.new(target, custom_mt)
	v4_.value = 0
	v4_.timerSize = { 1, 1 }
	v4_.markerSize = { 1, 1 }
	v4_.radius = 1
	v4_.timerOffset = nil
	v4_.overlayFront = {}
	v4_.overlayBackground1 = {}
	v4_.overlayBackground2 = {}
	v4_.overlayValue1 = {}
	v4_.overlayValue2 = {}
	v4_.overlayMarker = {}
	return v4_
end

function TimerElement:delete()
	GuiOverlay.deleteOverlay(self.overlayFront)
	GuiOverlay.deleteOverlay(self.overlayBackground1)
	GuiOverlay.deleteOverlay(self.overlayBackground2)
	GuiOverlay.deleteOverlay(self.overlayValue1)
	GuiOverlay.deleteOverlay(self.overlayValue2)
	GuiOverlay.deleteOverlay(self.overlayMarker)
	TimerElement:superClass().delete(self)
end

-- Local values: radius
function TimerElement:loadFromXML(xmlFile, key)
	TimerElement:superClass().loadFromXML(self, xmlFile, key)
	GuiOverlay.loadOverlay(self, self.overlayFront, "image", self.imageSize, nil, xmlFile, key)
	GuiOverlay.loadOverlay(self, self.overlayBackground1, "bgImage", self.imageSize, nil, xmlFile, key)
	GuiOverlay.loadOverlay(self, self.overlayBackground2, "bgImage", self.imageSize, nil, xmlFile, key)
	GuiOverlay.loadOverlay(self, self.overlayValue1, "valueImage", self.imageSize, nil, xmlFile, key)
	GuiOverlay.loadOverlay(self, self.overlayValue2, "valueImage", self.imageSize, nil, xmlFile, key)
	GuiOverlay.loadOverlay(self, self.overlayMarker, "markerImage", self.imageSize, nil, xmlFile, key)
	self.timerSize = GuiUtils.getNormalizedScreenValues(getXMLString(xmlFile, key .. "#timerSize"), self.timerSize)
	self.markerSize = GuiUtils.getNormalizedScreenValues(getXMLString(xmlFile, key .. "#markerSize"), self.markerSize)
	self.value = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#value"), self.value)
	local v9_ = getXMLString(xmlFile, key .. "#radius")
	if v9_ ~= nil then
		self.radius = GuiUtils.getNormalizedScreenValues(v9_ .. " " .. v9_, self.radius)
	end
	GuiOverlay.createOverlay(self.overlayFront)
	GuiOverlay.createOverlay(self.overlayBackground1)
	GuiOverlay.createOverlay(self.overlayBackground2)
	GuiOverlay.createOverlay(self.overlayValue1)
	GuiOverlay.createOverlay(self.overlayValue2)
	GuiOverlay.createOverlay(self.overlayMarker)
	self:updateUVs(self.overlayValue2, 3.141592653589793)
	self:setValue(self.value)
end

-- Local values: radius
function TimerElement:loadProfile(profile, applyProfile)
	TimerElement:superClass().loadProfile(self, profile, applyProfile)
	GuiOverlay.loadOverlay(self, self.overlayFront, "image", self.imageSize, profile, nil, nil)
	GuiOverlay.loadOverlay(self, self.overlayBackground1, "bgImage", self.imageSize, profile, nil, nil)
	GuiOverlay.loadOverlay(self, self.overlayBackground2, "bgImage", self.imageSize, profile, nil, nil)
	GuiOverlay.loadOverlay(self, self.overlayValue1, "valueImage", self.imageSize, profile, nil, nil)
	GuiOverlay.loadOverlay(self, self.overlayValue2, "valueImage", self.imageSize, profile, nil, nil)
	GuiOverlay.loadOverlay(self, self.overlayMarker, "markerImage", self.imageSize, profile, nil, nil)
	self.timerSize = GuiUtils.getNormalizedScreenValues(profile:getValue("timerSize"), self.timerSize)
	self.markerSize = GuiUtils.getNormalizedScreenValues(profile:getValue("markerSize"), self.markerSize)
	self.value = profile:getNumber("value", self.value)
	local v13_ = profile:getValue("radius")
	if v13_ ~= nil then
		self.radius = GuiUtils.getNormalizedScreenValues(v13_ .. " " .. v13_, self.outputSize)
	end
end

function TimerElement:copyAttributes(src)
	TimerElement:superClass().copyAttributes(self, src)
	self.timerSize = { src.timerSize[1], src.timerSize[2] }
	self.markerSize = { src.markerSize[1], src.markerSize[2] }
	self.timerOffset = { src.timerOffset[1], src.timerOffset[2] }
	self.radius = { src.radius[1], src.radius[2] }
	self.value = src.value
	GuiOverlay.copyOverlay(self.overlayFront, src.overlayFront)
	GuiOverlay.copyOverlay(self.overlayBackground1, src.overlayBackground1)
	GuiOverlay.copyOverlay(self.overlayBackground2, src.overlayBackground2)
	GuiOverlay.copyOverlay(self.overlayValue1, src.overlayValue1)
	GuiOverlay.copyOverlay(self.overlayValue2, src.overlayValue2)
	GuiOverlay.copyOverlay(self.overlayMarker, src.overlayMarker)
end

function TimerElement:setValue(newValue)
	self.value = math.clamp(newValue, 0, 1)
	local v18_ = self.overlayValue1
	local v19_ = (1 - self.value) * 360
	self:updateUVs(v18_, (math.rad(v19_)))
	local v20_ = self.overlayBackground1
	local v21_ = 180 + -self.value * 360
	self:updateUVs(v20_, (math.rad(v21_)))
end

-- Local values: uvs
function TimerElement:updateUVs(overlay, rotation)
	local v24_ = GuiOverlay.getOverlayUVs(overlay)
	local v25_ = -rotation
	local v26_ = -0.5 * math.cos(v25_)
	local v27_ = -rotation
	v24_[1] = v26_ + 0.5 * math.sin(v27_) + 0.5
	local v28_ = -rotation
	local v29_ = -0.5 * math.sin(v28_)
	local v30_ = -rotation
	v24_[2] = v29_ - 0.5 * math.cos(v30_) + 0.5
	local v31_ = -rotation
	local v32_ = -0.5 * math.cos(v31_)
	local v33_ = -rotation
	v24_[3] = v32_ - 0.5 * math.sin(v33_) + 0.5
	local v34_ = -rotation
	local v35_ = -0.5 * math.sin(v34_)
	local v36_ = -rotation
	v24_[4] = v35_ + 0.5 * math.cos(v36_) + 0.5
	local v37_ = -rotation
	local v38_ = 0.5 * math.cos(v37_)
	local v39_ = -rotation
	v24_[5] = v38_ + 0.5 * math.sin(v39_) + 0.5
	local v40_ = -rotation
	local v41_ = 0.5 * math.sin(v40_)
	local v42_ = -rotation
	v24_[6] = v41_ - 0.5 * math.cos(v42_) + 0.5
	local v43_ = -rotation
	local v44_ = 0.5 * math.cos(v43_)
	local v45_ = -rotation
	v24_[7] = v44_ - 0.5 * math.sin(v45_) + 0.5
	local v46_ = -rotation
	local v47_ = 0.5 * math.sin(v46_)
	local v48_ = -rotation
	v24_[8] = v47_ + 0.5 * math.cos(v48_) + 0.5
end

-- Local values: state, markerPosX, markerPosY
function TimerElement:draw(clipX1, clipY1, clipX2, clipY2)
	TimerElement:superClass().draw(self, clipX1, clipY1, clipX2, clipY2)
	local v54_ = GuiOverlay.STATE_NORMAL
	if self.disabled then
		v54_ = GuiOverlay.STATE_DISABLED
	end
	if self.value > 0.5 then
		GuiOverlay.renderOverlay(self.overlayBackground2, self.absPosition[1] + self.timerOffset[1], self.absPosition[2] + self.timerOffset[2], self.timerSize[1], self.timerSize[2], v54_)
	end
	GuiOverlay.renderOverlay(self.overlayValue1, self.absPosition[1] + self.timerOffset[1], self.absPosition[2] + self.timerOffset[2], self.timerSize[1], self.timerSize[2], v54_)
	if self.value > 0.5 then
		GuiOverlay.renderOverlay(self.overlayValue2, self.absPosition[1] + self.timerOffset[1], self.absPosition[2] + self.timerOffset[2], self.timerSize[1], self.timerSize[2], v54_)
	else
		GuiOverlay.renderOverlay(self.overlayBackground2, self.absPosition[1] + self.timerOffset[1], self.absPosition[2] + self.timerOffset[2], self.timerSize[1], self.timerSize[2], v54_)
		GuiOverlay.renderOverlay(self.overlayBackground1, self.absPosition[1] + self.timerOffset[1], self.absPosition[2] + self.timerOffset[2], self.timerSize[1], self.timerSize[2], v54_)
	end
	GuiOverlay.renderOverlay(self.overlayFront, self.absPosition[1], self.absPosition[2], self.size[1], self.size[2], v54_)
	local v55_ = (1 - self.value) * 360 + 90
	local v56_ = math.rad(v55_)
	local v57_ = math.cos(v56_) * self.radius[1]
	local v58_ = (1 - self.value) * 360 + 90
	local v59_ = math.rad(v58_)
	local v60_ = math.sin(v59_) * self.radius[2]
	GuiOverlay.renderOverlay(self.overlayMarker, self.absPosition[1] + self.size[1] / 2 - self.markerSize[1] / 2 + v57_, self.absPosition[2] + self.size[2] / 2 - self.markerSize[2] / 2 + v60_, self.markerSize[1], self.markerSize[2], v54_)
end
