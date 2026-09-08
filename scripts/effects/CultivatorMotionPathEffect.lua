-- Local values: CultivatorMotionPathEffect_mt
CultivatorMotionPathEffect = {}
local CultivatorMotionPathEffect_mt = Class(CultivatorMotionPathEffect, TypedMotionPathEffect)

-- Upvalues: CultivatorMotionPathEffect_mt
-- Local values: self
function CultivatorMotionPathEffect.new(customMt)
	-- upvalues: (copy) CultivatorMotionPathEffect_mt
	local v3_ = TypedMotionPathEffect.new(customMt or CultivatorMotionPathEffect_mt)
	v3_.shapeVariationStateDelay = ValueDelay.new(500)
	v3_.shapeVariationStateSmoothed = 0
	v3_.densityScale = math.random(75, 100) * 0.01
	v3_.autoTurnOffSpeed = 1
	return v3_
end

function CultivatorMotionPathEffect:loadEffectAttributes(xmlFile, key, node, i3dNode, i3dMapping)
	if not CultivatorMotionPathEffect:superClass().loadEffectAttributes(self, xmlFile, key, node, i3dNode, i3dMapping) then
		return false
	end
	self.isCultivatorSweepEffect = xmlFile:getValue(key .. ".motionPathEffect#isCultivatorSweepEffect", false)
	self.minDensity = 0.4
	self.maxDensitySpeed = 4
	if self.isCultivatorSweepEffect then
		self.minDensity = 0
		self.maxDensitySpeed = 10
	end
	self.minDensity = xmlFile:getValue(key .. ".motionPathEffect#minDensity", self.minDensity)
	self.maxDensitySpeed = xmlFile:getValue(key .. ".motionPathEffect#maxDensitySpeed", self.maxDensitySpeed)
	self.densityScale = xmlFile:getValue(key .. ".motionPathEffect#densityScale", self.densityScale)
	self.maxVariationState = xmlFile:getValue(key .. ".motionPathEffect#maxVariationState", 1)
	return true
end

-- Local values: lastSpeed, variationState, speedScale, x, y, z, i, effectNode, density, variationMin, variationMax, variationAlpha, variationState, _, effectNode
function CultivatorMotionPathEffect:update(dt)
	local v12_ = self.parent:getLastSpeed()
	if self.isCultivatorSweepEffect then
		if self.state == MotionPathEffect.STATE_TURNING_ON or self.state == MotionPathEffect.STATE_ON then
			local v13_ = (v12_ - 5) / 10
			local v14_ = math.clamp(v13_, 0, 1)
			self.effectSpeedScale = self.effectSpeedScaleOrig * (0.5 + v14_ * 0.5)
		end
	else
		local v15_ = v12_ / 10
		local v16_ = math.clamp(v15_, 0, 1)
		self.effectSpeedScale = self.effectSpeedScaleOrig * (0.5 + v16_ * 0.5)
	end
	if self.state == MotionPathEffect.STATE_ON and v12_ < self.autoTurnOffSpeed then
		g_effectManager:stopEffect(self)
	end
	if self.hasCurrentEffectNodes then
		if self.state == MotionPathEffect.STATE_TURNING_OFF then
			local v17_ = self.effectSpeedScaleOrig
			local v18_ = v12_ / 10
			self.effectSpeedScale = v17_ * math.clamp(v18_, 0.4, 1)
		end
		local v19_ = 0
		for _, v20_ in ipairs(self.currentEffectNodes) do
			if self.state == MotionPathEffect.STATE_TURNING_OFF then
				local v21_, v22_, v23_ = getTranslation(v20_)
				v19_ = v22_ - dt * 0.001
				setTranslation(v20_, v21_, v19_, v23_)
				if v19_ < -0.5 then
					setTranslation(v20_, 0, 0, 0)
				end
			else
				setTranslation(v20_, 0, 0, 0)
			end
		end
		if v19_ < -0.5 then
			self.fadeIn = self.minFade
			self.fadeOut = self.minFade
			self.state = MotionPathEffect.STATE_OFF
		end
	elseif self.state == MotionPathEffect.STATE_TURNING_OFF then
		self.fadeIn = self.minFade
		self.fadeOut = self.minFade
		self.state = MotionPathEffect.STATE_OFF
	end
	CultivatorMotionPathEffect:superClass().update(self, dt)
	if self.hasCurrentEffectNodes then
		if self.state == MotionPathEffect.STATE_TURNING_ON or self.state == MotionPathEffect.STATE_ON then
			local v24_ = v12_ / self.maxDensitySpeed
			self:setDensity((math.min(v24_, 1) * (1 - self.minDensity) + self.minDensity) * self.densityScale)
			local v25_, v26_, v27_
			if self.isCultivatorSweepEffect then
				local v28_ = (v12_ - 5) / 10
				local v29_ = self.maxVariationState
				local v30_ = math.clamp(v28_, 0, v29_)
				self.shapeVariationStateSmoothed = self.shapeVariationStateSmoothed * 0.985 + v30_ * 0.015
				local v31_ = self.shapeVariationStateSmoothed * 2
				v25_ = math.floor(v31_)
				local v32_ = self.shapeVariationStateSmoothed * 2 + 1
				v26_ = math.floor(v32_)
				v27_ = self.shapeVariationStateSmoothed * 2 % 1
			else
				v25_ = 0
				v26_ = 0
				v27_ = 0
			end
			for _, v33_ in ipairs(self.currentEffectNodes) do
				setShaderParameterRecursive(v33_, "scrollPos", nil, v25_, v26_, v27_, false)
			end
		end
		if self.state == MotionPathEffect.STATE_OFF then
			self.shapeVariationStateDelay:reset()
			self.shapeVariationStateSmoothed = 0
		end
	end
end

function CultivatorMotionPathEffect:stop()
	return CultivatorMotionPathEffect:superClass().stop(self)
end

function CultivatorMotionPathEffect:reset()
	return CultivatorMotionPathEffect:superClass().reset(self)
end

function CultivatorMotionPathEffect.loadEffectDefinitionFromXML(motionPathEffect, xmlFile, key)
	TypedMotionPathEffect.loadEffectDefinitionFromXML(motionPathEffect, xmlFile, key)
end

function CultivatorMotionPathEffect.loadEffectMeshFromXML(effectMesh, xmlFile, key)
	TypedMotionPathEffect.loadEffectMeshFromXML(effectMesh, xmlFile, key)
end

function CultivatorMotionPathEffect.loadEffectMaterialFromXML(effectMaterial, xmlFile, key)
	TypedMotionPathEffect.loadEffectMaterialFromXML(effectMaterial, xmlFile, key)
end

function CultivatorMotionPathEffect.registerEffectDefinitionXMLPaths(schema, basePath)
	TypedMotionPathEffect.registerEffectDefinitionXMLPaths(schema, basePath)
end

function CultivatorMotionPathEffect.registerEffectMeshXMLPaths(schema, basePath)
	TypedMotionPathEffect.registerEffectMeshXMLPaths(schema, basePath)
end

function CultivatorMotionPathEffect.registerEffectMaterialXMLPaths(schema, basePath)
	TypedMotionPathEffect.registerEffectMaterialXMLPaths(schema, basePath)
end

function CultivatorMotionPathEffect.registerEffectXMLPaths(schema, basePath)
	TypedMotionPathEffect.registerEffectXMLPaths(schema, basePath)
	schema:register(XMLValueType.BOOL, basePath .. ".motionPathEffect#isCultivatorSweepEffect", "(CultivatorMotionPathEffect) Is sweep effect", false)
	schema:register(XMLValueType.FLOAT, basePath .. ".motionPathEffect#minDensity", "(CultivatorMotionPathEffect) Min. Density", 0.5)
	schema:register(XMLValueType.FLOAT, basePath .. ".motionPathEffect#maxDensitySpeed", "(CultivatorMotionPathEffect) Speed at which the density is 1", 8)
	schema:register(XMLValueType.FLOAT, basePath .. ".motionPathEffect#densityScale", "(CultivatorMotionPathEffect) Density Scale", "Random between 0.75 and 1")
	schema:register(XMLValueType.FLOAT, basePath .. ".motionPathEffect#maxVariationState", "(CultivatorMotionPathEffect) Max. variation state", "Max state of variation depending on speed (0 -> slow, 0.5 -> normal, 1 -> fast)")
end
