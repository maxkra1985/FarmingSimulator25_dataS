-- Local values: MorphPositionEffect_mt
MorphPositionEffect = {}
local MorphPositionEffect_mt = Class(MorphPositionEffect, ShaderPlaneEffect)

-- Upvalues: MorphPositionEffect_mt
-- Local values: self
function MorphPositionEffect.new(customMt)
	-- upvalues: (copy) MorphPositionEffect_mt
	return ShaderPlaneEffect.new(customMt or MorphPositionEffect_mt)
end

function MorphPositionEffect:loadEffectAttributes(xmlFile, key, node, i3dNode, i3dMapping)
	if not MorphPositionEffect:superClass().loadEffectAttributes(self, xmlFile, key, node, i3dNode, i3dMapping) then
		return false
	end
	self.speed = Effect.getValue(xmlFile, key, node, "speed", 1)
	self.fadeCur = { 0, 0 }
	self.fadeDir = { 0, 0 }
	self.scrollLength = Effect.getValue(xmlFile, key, node, "scrollLength", 1)
	self.scrollLengthOrig = self.scrollLength
	self.scrollSpeed = Effect.getValue(xmlFile, key, node, "scrollSpeed", 1) * 0.001
	self.scrollPosition = 0
	self.scrollUpdate = true
	setShaderParameter(self.node, "morphPos", 0, 1, 1, 0, false)
	setShaderParameter(self.node, "prevMorphPos", 0, 1, 1, 0, false)
	setVisibility(self.node, false)
	return true
end

-- Local values: running, fadeTime, isVisible
function MorphPositionEffect:update(dt)
	local v11_ = false
	if self.state == ShaderPlaneEffect.STATE_OFF then
		v11_ = true
	else
		local v12_ = self.fadeInTime
		if self.state == ShaderPlaneEffect.STATE_TURNING_OFF then
			v12_ = self.fadeOutTime
		end
		local v13_ = self.fadeCur
		local v14_ = self.fadeCur[1] + self.fadeDir[1] * (dt / v12_)
		local v15_ = math.min(1, v14_)
		v13_[1] = math.max(0, v15_)
		local v16_ = self.fadeCur
		local v17_ = self.fadeCur[2] + self.fadeDir[2] * (dt / v12_)
		local v18_ = math.min(1, v17_)
		local v19_ = self.offset
		v16_[2] = math.max(0, v18_, v19_)
		if self.state ~= ShaderPlaneEffect.STATE_OFF and self.state ~= ShaderPlaneEffect.STATE_TURNING_OFF then
			self.fadeCur[1] = self.offset
		end
		g_animationManager:setPrevShaderParameter(self.node, "morphPos", self.fadeCur[1], self.fadeCur[2], 1, self.speed, false, "prevMorphPos")
		local v20_
		if self.state == ShaderPlaneEffect.STATE_TURNING_OFF and self.fadeCur[1] == 1 then
			self.fadeCur[1] = 0
			self.fadeCur[2] = 0
			self.state = ShaderPlaneEffect.STATE_OFF
			v20_ = false
		else
			v20_ = true
		end
		setVisibility(self.node, v20_)
		if self.state ~= ShaderPlaneEffect.STATE_TURNING_ON or (self.fadeCur[1] ~= 0 or self.fadeCur[2] ~= 1) then
			v11_ = (self.state ~= ShaderPlaneEffect.STATE_TURNING_OFF or (self.fadeCur[1] ~= 1 or self.fadeCur[2] ~= 1)) and true or v11_
		end
	end
	if self.scrollUpdate then
		self.scrollPosition = (self.scrollPosition + dt * self.scrollSpeed) % self.scrollLength
		setShaderParameter(self.node, "offsetUV", self.scrollPosition, nil, nil, nil, false)
	end
	if not v11_ then
		if self.state == ShaderPlaneEffect.STATE_TURNING_ON then
			self.state = ShaderPlaneEffect.STATE_ON
			return
		end
		if self.state == ShaderPlaneEffect.STATE_TURNING_OFF then
			self.state = ShaderPlaneEffect.STATE_OFF
		end
	end
end

function MorphPositionEffect:start(skipDelay)
	if self.startDelay ~= 0 and not skipDelay then
		return false, self.startDelay
	end
	if not self:canStart() or (self.state == ShaderPlaneEffect.STATE_TURNING_ON or self.state == ShaderPlaneEffect.STATE_ON) then
		return false
	end
	self.state = ShaderPlaneEffect.STATE_TURNING_ON
	local v23_ = self.fadeCur
	local v24_ = self.fadeCur
	local v25_ = self.offset
	local v26_ = math.min(v25_, 0)
	local v27_ = self.offset
	local v28_ = self.fadeCur[2]
	local v29_ = math.min(v27_, v28_)
	v23_[1] = v26_
	v24_[2] = v29_
	local v30_ = self.fadeDir
	local v31_ = self.fadeDir
	v30_[1] = 0
	v31_[2] = 1
	return true
end

function MorphPositionEffect:stop(skipDelay)
	if self.stopDelay ~= 0 and not skipDelay then
		return false, self.stopDelay
	end
	if self.state == ShaderPlaneEffect.STATE_TURNING_OFF or self.state == ShaderPlaneEffect.STATE_OFF then
		return false
	end
	self.state = ShaderPlaneEffect.STATE_TURNING_OFF
	local v34_ = self.fadeDir
	local v35_ = self.fadeDir
	v34_[1] = 1
	v35_[2] = 1
	return true
end

function MorphPositionEffect:reset()
	local v37_ = self.fadeCur
	local v38_ = self.fadeCur
	local v39_ = self.offset
	local v40_ = math.min(v39_, 0)
	local v41_ = self.offset
	local v42_ = math.min(v41_, 0)
	v37_[1] = v40_
	v38_[2] = v42_
	local v43_ = self.fadeDir
	local v44_ = self.fadeDir
	v43_[1] = 0
	v44_[2] = 1
	g_animationManager:setPrevShaderParameter(self.node, "morphPos", self.fadeCur[1], self.fadeCur[2], 0, self.scrollSpeed, false, "prevMorphPos")
	setVisibility(self.node, false)
	self.state = ShaderPlaneEffect.STATE_OFF
end

function MorphPositionEffect:setScrollUpdate(state)
	if state == nil then
		self.scrollUpdate = not self.scrollUpdate
	else
		self.scrollUpdate = state
	end
end

function MorphPositionEffect:getIsVisible()
	return self.fadeCur[1] > 0
end

function MorphPositionEffect:getIsFullyVisible()
	local v49_
	if self.fadeCur[2] == 1 then
		v49_ = self.fadeCur[1] == 0
	else
		v49_ = false
	end
	return v49_
end

-- Local values: fillTypeDesc
function MorphPositionEffect:setEffectTypeInfo(fillTypeIndex, fruitTypeIndex, growthState, force)
	self.scrollLength = self.scrollLengthOrig
	if fillTypeIndex ~= nil and (fillTypeIndex ~= FillType.UNKNOWN and self.useFillTypeTextureArrays) then
		local v55_ = g_fillTypeManager:getFillTypeByIndex(fillTypeIndex)
		if v55_ ~= nil then
			self.scrollLength = self.scrollLengthOrig * v55_:getTextureUnitSize()
		end
	end
	return MorphPositionEffect:superClass().setEffectTypeInfo(self, fillTypeIndex, fruitTypeIndex, growthState, force)
end

function MorphPositionEffect.registerEffectXMLPaths(schema, basePath)
	schema:register(XMLValueType.FLOAT, basePath .. "#speed", "speed", 1)
	schema:register(XMLValueType.FLOAT, basePath .. "#scrollLength", "(MorphPositionEffect) scroll length", 1)
	schema:register(XMLValueType.FLOAT, basePath .. "#scrollSpeed", "(MorphPositionEffect) scroll speed", 1)
end
