-- Local values: GrainTankEffect_mt
GrainTankEffect = {}
local GrainTankEffect_mt = Class(GrainTankEffect, ShaderPlaneEffect)

-- Upvalues: GrainTankEffect_mt
-- Local values: self
function GrainTankEffect.new(customMt)
	-- upvalues: (copy) GrainTankEffect_mt
	return ShaderPlaneEffect.new(customMt or GrainTankEffect_mt)
end

function GrainTankEffect:loadEffectAttributes(xmlFile, key, node, i3dNode, i3dMapping)
	if not GrainTankEffect:superClass().loadEffectAttributes(self, xmlFile, key, node, i3dNode, i3dMapping) then
		return false
	end
	self.minVisHeight = Effect.getValue(xmlFile, key, node, "minVisHeight", -math.huge)
	self.maxVisHeight = Effect.getValue(xmlFile, key, node, "maxVisHeight", math.huge)
	return true
end

-- Local values: _, y, _
function GrainTankEffect:update(dt)
	GrainTankEffect:superClass().update(self, dt)
	local _, v11_, _ = getTranslation(self.node)
	local v12_ = setVisibility
	local v13_ = self.node
	local v14_
	if self.minVisHeight < v11_ then
		v14_ = v11_ < self.maxVisHeight
	else
		v14_ = false
	end
	v12_(v13_, v14_)
end

function GrainTankEffect.registerEffectXMLPaths(schema, basePath)
	schema:register(XMLValueType.FLOAT, basePath .. "#minVisHeight", "(GrainTankEffect) Min. height to be visible", "-inf")
	schema:register(XMLValueType.FLOAT, basePath .. "#maxVisHeight", "(GrainTankEffect) Max. height to be visible", "inf")
end
