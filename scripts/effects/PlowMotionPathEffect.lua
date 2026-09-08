-- Local values: PlowMotionPathEffect_mt
PlowMotionPathEffect = {}
local PlowMotionPathEffect_mt = Class(PlowMotionPathEffect, TypedMotionPathEffect)

-- Upvalues: PlowMotionPathEffect_mt
-- Local values: self
function PlowMotionPathEffect.new(customMt)
	-- upvalues: (copy) PlowMotionPathEffect_mt
	local v3_ = TypedMotionPathEffect.new(customMt or PlowMotionPathEffect_mt)
	v3_.useVehicleSpeed = true
	v3_.isReverseFadeOutMode = false
	return v3_
end

function PlowMotionPathEffect:loadEffectAttributes(xmlFile, key, node, i3dNode, i3dMapping)
	if not PlowMotionPathEffect:superClass().loadEffectAttributes(self, xmlFile, key, node, i3dNode, i3dMapping) then
		return false
	end
	self.fadeOutScale = 0.25
	self.maxScaleSpeed = xmlFile:getValue(key .. ".motionPathEffect#maxScaleSpeed", 10)
	self.minScaleOffset = xmlFile:getValue(key .. ".motionPathEffect#minScaleOffset", -0.07)
	return true
end

-- Local values: lastSpeed, reverseFadeOut, isFullyHidden, i, effectNode, x, _, z, y, _, ly, _, i, effectNode
function PlowMotionPathEffect:update(dt)
	local v12_ = self.parent:getLastSpeed()
	local v13_ = self.parent.movingDirection < 0 and v12_ > 0.5 and true or self.isReverseFadeOutMode
	self.inversedFadeOut = self.fadeIn < 0.5 and true or v13_
	if self.state == MotionPathEffect.STATE_OFF then
		for _, v14_ in ipairs(self.currentEffectNodes) do
			setTranslation(v14_, 0, 0, 0)
		end
		self.fadeIn = self.minFade
		self.fadeOut = self.minFade
		self.isReverseFadeOutMode = false
	else
		self.fadeOutScale = v12_ < 2 and 0.25 or 1
		if v13_ then
			if not self.isReverseFadeOutMode then
				self.isReverseFadeOutMode = true
			end
			self.fadeOutScale = 0.5
		end
		local v15_ = false
		for _, v16_ in ipairs(self.currentEffectNodes) do
			local v17_, _, v18_ = getWorldTranslation(getParent(v16_))
			local v19_ = getTerrainHeightAtWorldPos(g_terrainNode, v17_, 0, v18_)
			local _, v20_, _ = worldToLocal(getParent(v16_), v17_, v19_, v18_)
			local v21_ = v12_ / self.maxScaleSpeed
			local v22_ = (1 - math.min(v21_)) * self.minScaleOffset
			local v23_ = -((1 - math.min(v20_, v22_)) ^ 2 - 1)
			if v13_ then
				local v24_, v25_, v26_ = getTranslation(v16_)
				local v27_ = v25_ - dt * 0.0005
				local v28_ = math.min(v27_, v23_)
				setTranslation(v16_, v24_, v28_, v26_)
				if v28_ < -1 then
					v15_ = true
				end
			else
				setTranslation(v16_, 0, v23_, 0)
			end
		end
		if v15_ then
			if self.state == MotionPathEffect.STATE_TURNING_OFF then
				self.state = MotionPathEffect.STATE_OFF
			end
			self.fadeIn = self.minFade
			self.fadeOut = self.minFade
			self.isReverseFadeOutMode = false
		end
		if self.isReverseFadeOutMode and (self.parent:getLastSpeed() > 1 and self.parent.movingDirection > 0) then
			self.isReverseFadeOutMode = false
			self.fadeIn = self.minFade
			self.fadeOut = self.minFade
		end
	end
	PlowMotionPathEffect:superClass().update(self, dt)
end

function PlowMotionPathEffect:stop()
	return PlowMotionPathEffect:superClass().stop(self)
end

function PlowMotionPathEffect:reset()
	return PlowMotionPathEffect:superClass().reset(self)
end

function PlowMotionPathEffect.loadEffectDefinitionFromXML(motionPathEffect, xmlFile, key)
	TypedMotionPathEffect.loadEffectDefinitionFromXML(motionPathEffect, xmlFile, key)
end

function PlowMotionPathEffect.loadEffectMeshFromXML(effectMesh, xmlFile, key)
	TypedMotionPathEffect.loadEffectMeshFromXML(effectMesh, xmlFile, key)
end

function PlowMotionPathEffect.loadEffectMaterialFromXML(effectMaterial, xmlFile, key)
	TypedMotionPathEffect.loadEffectMaterialFromXML(effectMaterial, xmlFile, key)
end

function PlowMotionPathEffect.registerEffectDefinitionXMLPaths(schema, basePath)
	TypedMotionPathEffect.registerEffectDefinitionXMLPaths(schema, basePath)
end

function PlowMotionPathEffect.registerEffectMeshXMLPaths(schema, basePath)
	TypedMotionPathEffect.registerEffectMeshXMLPaths(schema, basePath)
end

function PlowMotionPathEffect.registerEffectMaterialXMLPaths(schema, basePath)
	TypedMotionPathEffect.registerEffectMaterialXMLPaths(schema, basePath)
end

function PlowMotionPathEffect.registerEffectXMLPaths(schema, basePath)
	TypedMotionPathEffect.registerEffectXMLPaths(schema, basePath)
	schema:register(XMLValueType.FLOAT, basePath .. ".motionPathEffect#maxScaleSpeed", "(PlowMotionPathEffect) Speed at which the effect reaches the max. scale", 10)
	schema:register(XMLValueType.FLOAT, basePath .. ".motionPathEffect#minScaleOffset", "(PlowMotionPathEffect) Y Offset when the scale is at it\'s minimum", -0.07)
end
