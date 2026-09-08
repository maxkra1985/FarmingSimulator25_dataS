-- Local values: ParticleEffect_mt
ParticleEffect = {}
local ParticleEffect_mt = Class(ParticleEffect, Effect)

-- Upvalues: ParticleEffect_mt
-- Local values: self
function ParticleEffect.new(customMt)
	-- upvalues: (copy) ParticleEffect_mt
	local v3_ = Effect.new(customMt or ParticleEffect_mt)
	v3_.isActive = false
	v3_.currentFillTypeIndex = FillType.UNKNOWN
	return v3_
end

function ParticleEffect:loadEffectAttributes(xmlFile, key, node, i3dNode, i3dMapping)
	if not ParticleEffect:superClass().loadEffectAttributes(self, xmlFile, key, node, i3dNode, i3dMapping) then
		return false
	end
	self.emitterShape = self.node
	self.emitCountScale = Effect.getValue(xmlFile, key, node, "emitCountScale", 1)
	self.particleType = Effect.getValue(xmlFile, key, node, "particleType", "unloading")
	self.materialType = Effect.getValue(xmlFile, key, node, "materialType")
	self.useFruitColor = Effect.getValue(xmlFile, key, node, "useFruitColor", false)
	self.worldSpace = Effect.getValue(xmlFile, key, node, "worldSpace", true)
	self.delay = Effect.getValue(xmlFile, key, node, "delay", 0)
	self.startTime = Effect.getValue(xmlFile, key, node, "startTime", self.delay)
	self.startTimeMs = self.startTime * 1000
	self.stopTime = Effect.getValue(xmlFile, key, node, "stopTime", self.delay)
	self.stopTimeMs = self.stopTime * 1000
	self.lifespan = Effect.getValue(xmlFile, key, node, "lifespan")
	self.extraDistance = Effect.getValue(xmlFile, key, node, "extraDistance", 0.5)
	self.ignoreDistanceLifeSpan = Effect.getValue(xmlFile, key, node, "ignoreDistanceLifeSpan", false)
	self.alphaScale = Effect.getValue(xmlFile, key, node, "alphaScale", 1)
	self.velocityScale = Effect.getValue(xmlFile, key, node, "velocityScale")
	if string.lower(self.particleType) == "unloading" and self.materialType == nil then
		Logging.xmlWarning(xmlFile, "ParticleEffect \'%s\' is missing the \'materialType\' attribute.", key)
		return false
	end
	self.spriteScale = Effect.getValue(xmlFile, key, node, "spriteScale", 1)
	self.spriteGainScale = Effect.getValue(xmlFile, key, node, "spriteGainScale", self.spriteScale)
	self.speedScale = Effect.getValue(xmlFile, key, node, "speedScale", 1)
	self.realStartTime = math.huge
	self.realStopTime = math.huge
	self.useCuttingWidth = Effect.getValue(xmlFile, key, node, "useCuttingWidth", true)
	self.lastEmitterScale = 1
	self.currentEmitCountScale = 1
	self.particleSystem = nil
	return true
end

function ParticleEffect:delete()
	ParticleEffect:superClass().delete(self)
	ParticleUtil.deleteParticleSystem(self.particleSystem)
end

function ParticleEffect:isRunning()
	return self.isActive
end

function ParticleEffect:start()
	if not self:canStart() or self.particleSystem == nil then
		return false
	end
	ParticleUtil.setEmittingState(self.particleSystem, self.totalWidth == nil and true or self.totalWidth > 0)
	self.isActive = true
	self.realStartTime = g_time
	self.realStopTime = math.huge
	setVisibility(self.emitterShape, true)
	return true
end

-- Local values: x, y, z, scale
function ParticleEffect:update(dt)
	ParticleEffect:superClass().update(self, dt)
	if self.isActive then
		local v15_, v16_, v17_ = getScale(self.emitterShape)
		local v18_ = v15_ * v16_ * v17_
		local v19_ = math.min(v18_, 1)
		local v20_ = v19_ - self.lastEmitterScale
		if math.abs(v20_) > 0.05 then
			self.lastEmitterScale = v19_
			ParticleUtil.setMaxNumOfParticlesToEmitScale(self.particleSystem, self.currentEmitCountScale * v19_)
		end
	end
end

function ParticleEffect:stop()
	ParticleUtil.setEmittingState(self.particleSystem, false)
	if self.particleSystem ~= nil then
		self.realStopTime = g_time
	end
	self.isActive = false
	setVisibility(self.emitterShape, false)
end

function ParticleEffect:reset()
	ParticleUtil.resetNumOfEmittedParticles(self.particleSystem)
end

function ParticleEffect:setEffectTypeInfo(fillTypeIndex, fruitTypeIndex, growthState)
	if fruitTypeIndex ~= nil then
		fillTypeIndex = g_fruitTypeManager:getFillTypeIndexByFruitTypeIndex(fruitTypeIndex)
	end
	if fillTypeIndex == nil then
		return false
	end
	self.useFruitColor = true
	return self:setFillType(fillTypeIndex)
end

-- Local values: success, sourceParticleSystem, psClone, particleSystem, originalSpriteScaleX, originalSpriteScaleY, originalSpriteGainScaleX, originalSpriteGainScaleY, j, invJ, lifespans, i, lifespan, normalSpeed, _, gravity, distance, fillTypeDesc, _, _, _, a, x, y, _, _
function ParticleEffect:setFillType(fillTypeIndex)
	local v28_ = true
	if self.currentFillTypeIndex ~= fillTypeIndex or self.particleSystem == nil then
		if self.particleSystem ~= nil then
			ParticleUtil.deleteParticleSystem(self.particleSystem)
			self.particleSystem = nil
		end
		local v29_ = g_particleSystemManager:getParticleSystem(self.particleType)
		if v29_ == nil then
			Logging.error("Failed to find particle system for type \'%s\'.", self.particleType)
			v28_ = false
		else
			local v30_ = clone(v29_.shape, true, false, true)
			local v31_ = {}
			ParticleUtil.loadParticleSystemFromNode(v30_, v31_, false, self.worldSpace, v29_.forceFullLifespan)
			ParticleUtil.setEmitterShape(v31_, self.emitterShape)
			self.currentEmitCountScale = v31_.emitterShapeSize / v31_.defaultEmitterShapeSize * self.emitCountScale
			ParticleUtil.initEmitterScale(v31_, self.currentEmitCountScale)
			ParticleUtil.setParticleSystemSpeed(v31_, ParticleUtil.getParticleSystemSpeed(v31_) * self.speedScale)
			ParticleUtil.setEmitCountScale(v31_, 1)
			if self.lifespan ~= nil then
				ParticleUtil.setParticleLifespan(v31_, self.lifespan * 1000)
				v31_.originalLifespan = self.lifespan * 1000
			end
			ParticleUtil.setParticleStartStopTime(v31_, self.startTime, self.stopTime)
			if self.spriteScale ~= 1 then
				local v32_ = ParticleUtil.getParticleSystemSpriteScaleX(v31_)
				ParticleUtil.setParticleSystemSpriteScaleX(v31_, v32_ * self.spriteScale)
				local v33_ = ParticleUtil.getParticleSystemSpriteScaleY(v31_)
				ParticleUtil.setParticleSystemSpriteScaleY(v31_, v33_ * self.spriteScale)
			end
			if self.spriteGainScale ~= 1 then
				local v34_ = ParticleUtil.getParticleSystemSpriteScaleXGain(v31_)
				ParticleUtil.setParticleSystemSpriteScaleXGain(v31_, v34_ * self.spriteGainScale)
				local v35_ = ParticleUtil.getParticleSystemSpriteScaleYGain(v31_)
				ParticleUtil.setParticleSystemSpriteScaleYGain(v31_, v35_ * self.spriteGainScale)
			end
			if v31_.worldSpace then
				if self.velocityScale ~= nil then
					ParticleUtil.setParticleSystemVelocityScale(v31_, self.velocityScale)
				end
			else
				link(getParent(self.emitterShape), v31_.shape)
				setWorldTranslation(v31_.shape, getWorldTranslation(self.emitterShape))
				setWorldRotation(v31_.shape, getWorldRotation(self.emitterShape))
				ParticleUtil.setParticleSystemVelocityScale(v31_, 0)
			end
			self.particleSystem = v31_
			self.distanceToLifespans = {}
			for v36_ = 0, 1, 0.1 do
				local v37_ = 1 - v36_
				local v38_ = AnimCurve.new(linearInterpolator1)
				for v39_ = 1, 20 do
					local v40_ = v39_ * 100
					local v41_, _ = getParticleSystemAverageSpeed(self.particleSystem.geometry)
					v38_:addKeyframe({
						v40_,
						["time"] = v41_ * v40_ * v37_ + 7.17e-6 * v40_ * v40_
					})
				end
				local v42_ = self.distanceToLifespans
				table.insert(v42_, v38_)
			end
		end
		if self.particleSystem ~= nil and self.particleSystem.shape ~= nil then
			local v43_ = g_fillTypeManager:getFillTypeByIndex(fillTypeIndex)
			if v43_ == nil then
				if getHasShaderParameter(self.particleSystem.shape, "colorAlpha") then
					local _, _, _, v44_ = getShaderParameter(self.particleSystem.shape, "colorAlpha")
					setShaderParameter(self.particleSystem.shape, "colorAlpha", nil, nil, nil, v44_ * self.alphaScale, false)
				end
			else
				self.currentEmitCountScale = v43_:setParticleSystemFillType(self.particleSystem, self.particleType, self.materialType, self.useFruitColor, self.emitCountScale, self.alphaScale) or self.currentEmitCountScale
			end
			if getHasShaderParameter(self.particleSystem.shape, "playScale") then
				local v45_, v46_, _, _ = getShaderParameter(self.particleSystem.shape, "playScale")
				setShaderParameter(self.particleSystem.shape, "playScale", v45_ * self.speedScale, v46_ * self.speedScale, nil, nil, false)
			end
		end
		self.currentFillTypeIndex = fillTypeIndex
	end
	return v28_
end

function ParticleEffect:setColor(r, g, b, a)
	if self.particleSystem ~= nil and getHasShaderParameter(self.particleSystem.shape, "colorAlpha") then
		setShaderParameter(self.particleSystem.shape, "colorAlpha", r, g, b, a * self.alphaScale, false)
	end
end

-- Local values: widthX, emitterShape, _, sy, sz, _, y, z
function ParticleEffect:setMinMaxWidth(minValue, maxValue, minWidthNorm, maxWidthNorm, reset)
	if self.useCuttingWidth then
		local v55_ = minValue - maxValue
		local v56_ = math.abs(v55_)
		local v57_ = self.emitterShape
		local _, v58_, v59_ = getScale(v57_)
		setScale(v57_, v56_, v58_, v59_)
		local _, v60_, v61_ = getTranslation(v57_)
		setTranslation(v57_, -(maxValue - v56_ * 0.5), v60_, v61_)
		ParticleUtil.setEmitCountScale(self.particleSystem, v56_)
		self.totalWidth = v56_
		if self.isActive then
			ParticleUtil.setEmittingState(self.particleSystem, v56_ > 0)
		end
	end
end

-- Local values: _, dirY, _, direction, index, curve, lifespan
function ParticleEffect:setDistance(distance, terrain)
	if self.particleSystem ~= nil and not (self.ignoreDistanceLifeSpan or self.particleSystem.forceFullLifespan) then
		local _, v64_, _ = localDirectionToWorld(self.particleSystem.emitterShape, 0, 1, 0)
		local v65_ = v64_ / 1 * #self.distanceToLifespans
		local v66_ = math.floor(v65_)
		local v67_ = self.distanceToLifespans
		local v68_ = #self.distanceToLifespans
		local v69_ = v67_[math.clamp(v66_, 1, v68_)]:get(distance + self.extraDistance)
		ParticleUtil.setParticleLifespan(self.particleSystem, v69_)
	end
end

function ParticleEffect:setDensity(density)
	if self.particleSystem ~= nil then
		ParticleUtil.setEmitCountScale(self.particleSystem, self.emitCountScale * density)
	end
end

function ParticleEffect:getIsVisible()
	return self:getIsFullyVisible()
end

function ParticleEffect:getIsFullyVisible()
	local v74_
	if self.realStartTime + self.startTimeMs < g_time then
		v74_ = self.realStopTime + self.stopTimeMs > g_time
	else
		v74_ = false
	end
	return v74_
end

function ParticleEffect.registerEffectXMLPaths(schema, basePath)
	schema:register(XMLValueType.FLOAT, basePath .. "#emitCountScale", "(ParticleEffect) Emit count scale", 1)
	schema:register(XMLValueType.STRING, basePath .. "#particleType", "(ParticleEffect) Particle type", "unloading")
	schema:register(XMLValueType.STRING, basePath .. "#materialType", "(ParticleEffect) Material type")
	schema:register(XMLValueType.BOOL, basePath .. "#useFruitColor", "(ParticleEffect) Apply the fruit color to the smoke effect instead of the fill color", false)
	schema:register(XMLValueType.BOOL, basePath .. "#worldSpace", "(ParticleEffect) World space", true)
	schema:register(XMLValueType.FLOAT, basePath .. "#delay", "(ParticleEffect) Delay", 0)
	schema:register(XMLValueType.FLOAT, basePath .. "#startTime", "(ParticleEffect) Start time", "delay")
	schema:register(XMLValueType.FLOAT, basePath .. "#stopTime", "(ParticleEffect) Stop time", "delay")
	schema:register(XMLValueType.FLOAT, basePath .. "#lifespan", "(ParticleEffect) Lifespan")
	schema:register(XMLValueType.FLOAT, basePath .. "#extraDistance", "(ParticleEffect) Extra distance", 0.5)
	schema:register(XMLValueType.BOOL, basePath .. "#ignoreDistanceLifeSpan", "(ParticleEffect) Ignore distance based lifespan and apply fixed lifespan", false)
	schema:register(XMLValueType.FLOAT, basePath .. "#alphaScale", "(ParticleEffect) Scale for the color alpha value", 1)
	schema:register(XMLValueType.FLOAT, basePath .. "#velocityScale", "(ParticleEffect) Overwrite velocity scale of particles (only if world space)")
	schema:register(XMLValueType.FLOAT, basePath .. "#spriteScale", "(ParticleEffect) Scale factor that is applied on sprite scale loaded from particle system", 1)
	schema:register(XMLValueType.FLOAT, basePath .. "#spriteGainScale", "(ParticleEffect) Scale factor that is applied on sprite gain scale loaded from particle system", "#spriteScale value")
	schema:register(XMLValueType.FLOAT, basePath .. "#speedScale", "(ParticleEffect) Scale factor for particle speed")
	schema:register(XMLValueType.BOOL, basePath .. "#useCuttingWidth", "(ParticleEffect) Use cutting width", true)
end
