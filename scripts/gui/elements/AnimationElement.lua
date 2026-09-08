-- Local values: AnimationElement_mt
AnimationElement = {}
local AnimationElement_mt = Class(AnimationElement, BitmapElement)
Gui.registerGuiElement("Animation", AnimationElement)
AnimationElement.MODE = {
	["UV_SHIFT"] = 1,
	["ROTATE"] = 2
}

-- Upvalues: AnimationElement_mt
-- Local values: self
function AnimationElement.new(target, custom_mt)
	-- upvalues: (copy) AnimationElement_mt
	local v4_ = BitmapElement.new(target, custom_mt or AnimationElement_mt)
	v4_.animationMode = AnimationElement.MODE.UV_SHIFT
	v4_.animationOffset = -1
	v4_.animationFrames = 8
	v4_.animationTimer = 0
	v4_.animationSpeed = 120
	v4_.animationFrameSize = 0
	v4_.animationStartPos = 0
	v4_.animationUVOffset = 0
	v4_.animationRotation = 0
	v4_.animationRotationPivot = nil
	return v4_
end

-- Local values: animationUVOffset, uvs, mode
function AnimationElement:loadFromXML(xmlFile, key)
	AnimationElement:superClass().loadFromXML(self, xmlFile, key)
	self.animationOffset = getXMLInt(xmlFile, key .. "#animationOffset") or self.animationOffset
	self.animationFrames = getXMLInt(xmlFile, key .. "#animationFrames") or self.animationFrames
	self.animationSpeed = getXMLInt(xmlFile, key .. "#animationSpeed") or self.animationSpeed
	self.animationRotationPivot = string.getVector(getXMLString(xmlFile, key .. "#animationRotationPivot"), 2) or self.animationRotationPivot
	local v8_ = getXMLString(xmlFile, key .. "#animationUVOffset")
	if v8_ ~= nil then
		self.animationUVOffset = GuiUtils.getNormalizedValues(v8_, self.imageSize)[1]
	end
	local v9_ = GuiOverlay.getOverlayUVs(self.overlay, self:getOverlayState())
	self.animationDefaultUVs = table.clone(v9_)
	local v10_ = getXMLString(xmlFile, key .. "#animationMode")
	if v10_ ~= nil then
		if string.lower(v10_) == "uvshift" then
			self.animationMode = AnimationElement.MODE.UV_SHIFT
		else
			self.animationMode = AnimationElement.MODE.ROTATE
		end
	end
	self:setAnimationData()
end

-- Local values: animationUVOffset, mode
function AnimationElement:loadProfile(profile, applyProfile)
	AnimationElement:superClass().loadProfile(self, profile, applyProfile)
	self.animationOffset = profile:getNumber("animationOffset", self.animationOffset)
	self.animationFrames = profile:getNumber("animationFrames", self.animationFrames)
	self.animationSpeed = profile:getNumber("animationSpeed", self.animationSpeed)
	self.animationRotationPivot = string.getVector(profile:getValue("animationRotationPivot"), 2) or self.animationRotationPivot
	local v14_ = profile:getValue("animationUVOffset")
	if v14_ ~= nil then
		self.animationUVOffset = GuiUtils.getNormalizedValues(v14_, self.imageSize)[1]
	end
	local v15_ = profile:getValue("animationMode")
	if v15_ ~= nil then
		if string.lower(v15_) == "uvshift" then
			self.animationMode = AnimationElement.MODE.UV_SHIFT
			return
		end
		self.animationMode = AnimationElement.MODE.ROTATE
	end
end

function AnimationElement:copyAttributes(src)
	AnimationElement:superClass().copyAttributes(self, src)
	self.animationDefaultUVs = table.clone(src.animationDefaultUVs)
	self.animationOffset = src.animationOffset
	self.animationFrames = src.animationFrames
	self.animationSpeed = src.animationSpeed
	self.animationUVOffset = src.animationUVOffset
	self.animationMode = src.animationMode
	local v18_ = self.animationDefaultUVs
	self:setImageUVs(nil, unpack(v18_))
	self:setAnimationData()
end

function AnimationElement:update(dt)
	AnimationElement:superClass().update(self, dt)
	if self.animationMode == AnimationElement.MODE.UV_SHIFT then
		self.animationTimer = self.animationTimer - dt
		if self.animationTimer < 0 then
			self.animationTimer = self.animationSpeed
			self.animationOffset = self.animationOffset + 1
			if self.animationOffset > self.animationFrames - 1 then
				self.animationOffset = 0
			end
			self:updateAnimationUVs()
			return
		end
	elseif self.animationMode == AnimationElement.MODE.ROTATE then
		self.animationRotation = self.animationRotation - 6.283185307179586 * (dt / self.animationSpeed)
		self:updateRotation()
	end
end

-- Local values: frameOffset
function AnimationElement:updateAnimationUVs()
	if self.animationMode == AnimationElement.MODE.UV_SHIFT then
		local v22_ = self.animationStartPos + (self.animationFrameSize + self.animationUVOffset) * self.animationOffset
		self:setImageUVs(nil, v22_, nil, v22_, nil, v22_ + self.animationFrameSize, nil, v22_ + self.animationFrameSize, nil)
	end
end

-- Local values: pivot, x, y
function AnimationElement:updateRotation()
	local v24_ = self.pivot
	if self.animationRotationPivot ~= nil then
		v24_ = self.animationRotationPivot
	end
	local v25_ = self.absSize[1] * v24_[1]
	local v26_ = self.absSize[2] * v24_[2]
	GuiOverlay.setRotation(self.overlay, self.animationRotation, v25_, v26_)
end

-- Local values: uvs
function AnimationElement:setAnimationData()
	if self.overlay ~= nil then
		local v28_ = GuiOverlay.getOverlayUVs(self.overlay, self:getOverlayState())
		self.animationFrameSize = (v28_[5] - v28_[1] - self.animationUVOffset * (self.animationFrames - 1)) / self.animationFrames
		self.animationStartPos = v28_[1]
		self:updateAnimationUVs()
	end
end
