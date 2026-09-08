-- Local values: FertilizerMotionPathEffect_mt
FertilizerMotionPathEffect = {}
local FertilizerMotionPathEffect_mt = Class(FertilizerMotionPathEffect, TypedMotionPathEffect)

-- Upvalues: FertilizerMotionPathEffect_mt
-- Local values: self
function FertilizerMotionPathEffect.new(customMt)
	-- upvalues: (copy) FertilizerMotionPathEffect_mt
	local v3_ = TypedMotionPathEffect.new(customMt or FertilizerMotionPathEffect_mt)
	v3_.isLeft = false
	return v3_
end

function FertilizerMotionPathEffect:loadEffectAttributes(xmlFile, key, node, i3dNode, i3dMapping)
	if not FertilizerMotionPathEffect:superClass().loadEffectAttributes(self, xmlFile, key, node, i3dNode, i3dMapping) then
		return false
	end
	self.isLeft = xmlFile:getValue(key .. ".motionPathEffect#isLeft", self.isLeft)
	self.smoothY1 = nil
	self.smoothY2 = nil
	return true
end

-- Local values: currentWidth, maxWidth, isValid, i, effectNode, _, y1, _, x2, y2, z2, _, y, _, angle
function FertilizerMotionPathEffect:update(dt)
	if (self.state == MotionPathEffect.STATE_TURNING_ON or self.state == MotionPathEffect.STATE_ON) and self.parent.getVariableWorkWidth ~= nil then
		local v12_, v13_, v14_ = self.parent:getVariableWorkWidth(self.isLeft)
		if self.textureRealWidth ~= nil then
			v13_ = self.textureRealWidth * math.sign(v13_)
		end
		self.fadeVisibilityMax = 1 - v12_ / v13_
		local v15_ = not v14_ and 10 or v12_
		for _, v16_ in ipairs(self.currentEffectNodes) do
			if v15_ == 0 then
				setRotation(v16_, 0, 0, 0)
			else
				local _, v17_, _ = localToWorld(v16_, 0, 0, 0)
				if self.smoothY1 == nil then
					self.smoothY1 = v17_
				end
				self.smoothY1 = self.smoothY1 * 0.98 + v17_ * 0.02
				local v18_, v19_, v20_ = localToWorld(getParent(v16_), v15_, 0, 0)
				if self.smoothY2 == nil then
					self.smoothY2 = v19_
				end
				self.smoothY2 = self.smoothY2 * 0.98 + v19_ * 0.02
				local _, v21_, _ = worldToLocal(getParent(v16_), v18_, self.smoothY2 + (v17_ - self.smoothY1), v20_)
				local v22_ = v21_ / v15_
				local v23_ = math.atan(v22_)
				setRotation(v16_, 0, 0, v23_)
			end
		end
	end
	FertilizerMotionPathEffect:superClass().update(self, dt)
end

function FertilizerMotionPathEffect:stop()
	self.smoothY1 = nil
	self.smoothY2 = nil
	return FertilizerMotionPathEffect:superClass().stop(self)
end

function FertilizerMotionPathEffect:reset()
	return FertilizerMotionPathEffect:superClass().reset(self)
end

function FertilizerMotionPathEffect.loadEffectDefinitionFromXML(motionPathEffect, xmlFile, key)
	TypedMotionPathEffect.loadEffectDefinitionFromXML(motionPathEffect, xmlFile, key)
end

function FertilizerMotionPathEffect.loadEffectMeshFromXML(effectMesh, xmlFile, key)
	TypedMotionPathEffect.loadEffectMeshFromXML(effectMesh, xmlFile, key)
end

function FertilizerMotionPathEffect.loadEffectMaterialFromXML(effectMaterial, xmlFile, key)
	TypedMotionPathEffect.loadEffectMaterialFromXML(effectMaterial, xmlFile, key)
end

function FertilizerMotionPathEffect.registerEffectDefinitionXMLPaths(schema, basePath)
	TypedMotionPathEffect.registerEffectDefinitionXMLPaths(schema, basePath)
end

function FertilizerMotionPathEffect.registerEffectMeshXMLPaths(schema, basePath)
	TypedMotionPathEffect.registerEffectMeshXMLPaths(schema, basePath)
end

function FertilizerMotionPathEffect.registerEffectMaterialXMLPaths(schema, basePath)
	TypedMotionPathEffect.registerEffectMaterialXMLPaths(schema, basePath)
end

function FertilizerMotionPathEffect.registerEffectXMLPaths(schema, basePath)
	TypedMotionPathEffect.registerEffectXMLPaths(schema, basePath)
	schema:register(XMLValueType.BOOL, basePath .. ".motionPathEffect#isLeft", "(FertilizerMotionPathEffect) Defines if the effect is left or right", false)
end
