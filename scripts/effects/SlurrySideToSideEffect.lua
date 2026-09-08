-- Local values: SlurrySideToSideEffect_mt
SlurrySideToSideEffect = {}
local SlurrySideToSideEffect_mt = Class(SlurrySideToSideEffect, ShaderPlaneEffect)

-- Upvalues: SlurrySideToSideEffect_mt
-- Local values: self
function SlurrySideToSideEffect.new(customMt)
	-- upvalues: (copy) SlurrySideToSideEffect_mt
	return ShaderPlaneEffect.new(customMt or SlurrySideToSideEffect_mt)
end

function SlurrySideToSideEffect:loadEffectAttributes(xmlFile, key, node, i3dNode, i3dMapping)
	if not SlurrySideToSideEffect:superClass().loadEffectAttributes(self, xmlFile, key, node, i3dNode, i3dMapping) then
		return false
	end
	self.refAnimation = Effect.getValue(xmlFile, key, node, "refAnimation")
	self.offset = Effect.getValue(xmlFile, key, node, "offset", 0.5)
	return true
end

-- Local values: z
function SlurrySideToSideEffect:update(dt)
	SlurrySideToSideEffect:superClass().update(self, dt)
	local v11_ = (self.parent:getAnimationTime(self.refAnimation) + self.offset) % 1
	setShaderParameter(self.node, "fadeProgress", self.fadeCur[1], self.fadeCur[2], v11_, 0, false)
end

function SlurrySideToSideEffect:isRunning()
	return SlurrySideToSideEffect:superClass().isRunning(self) or self.state == ShaderPlaneEffect.STATE_ON
end

function SlurrySideToSideEffect.registerEffectXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. "#refAnimation", "(SlurrySideToSideEffect) Reference animation")
	schema:register(XMLValueType.FLOAT, basePath .. "#offset", "(SlurrySideToSideEffect) Animation time offset", 0.5)
end
