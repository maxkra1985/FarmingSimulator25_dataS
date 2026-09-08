-- Local values: TipEffect_mt
TipEffect = {}
local TipEffect_mt = Class(TipEffect, Effect)

-- Upvalues: TipEffect_mt
-- Local values: self
function TipEffect.new(customMt)
	-- upvalues: (copy) TipEffect_mt
	local v3_ = Effect.new(customMt or TipEffect_mt)
	v3_.activeEffect = nil
	return v3_
end

function TipEffect:load(xmlFile, baseName, rootNodes, parent, i3dMapping)
	self.effects = g_effectManager:loadEffect(xmlFile, baseName, rootNodes, parent, i3dMapping)
	return self
end

-- Local values: _, effect
function TipEffect:delete()
	for _, v11_ in ipairs(self.effects) do
		v11_:delete()
	end
end

function TipEffect:update(dt)
	if self.activeEffect ~= nil then
		self.activeEffect:update(dt)
	end
end

function TipEffect:isRunning()
	local v15_
	if self.activeEffect == nil then
		v15_ = false
	else
		v15_ = self.activeEffect:isRunning()
	end
	return v15_
end

function TipEffect:start()
	if self:canStart() and self.activeEffect ~= nil then
		return self.activeEffect:start()
	else
		return false
	end
end

function TipEffect:stop()
	if self.activeEffect == nil then
		return false
	else
		return self.activeEffect:stop()
	end
end

-- Local values: _, effect
function TipEffect:reset()
	for _, v19_ in ipairs(self.effects) do
		v19_:reset()
	end
end

-- Local values: prioritizedEffectType, _, effect, className, foundEffect, _, effect
function TipEffect:setEffectTypeInfo(fillTypeIndex, fruitTypeIndex, growthState)
	local v24_ = g_fillTypeManager:getPrioritizedEffectTypeByFillTypeIndex(fillTypeIndex)
	if v24_ ~= nil then
		for _, v25_ in ipairs(self.effects) do
			if v25_.setEffectTypeInfo ~= nil then
				local v26_ = ClassUtil.getClassNameByObject(v25_)
				if v26_ ~= nil and (string.lower(v26_) == string.lower(v24_) and v25_:setEffectTypeInfo(fillTypeIndex, fruitTypeIndex, growthState)) then
					self.activeEffect = v25_
					return true
				end
			end
		end
	end
	local v27_ = false
	for _, v28_ in ipairs(self.effects) do
		if v28_.setEffectTypeInfo ~= nil and v28_:setEffectTypeInfo(fillTypeIndex, fruitTypeIndex, growthState) then
			self.activeEffect = v28_
			return true
		end
	end
	return v27_
end

function TipEffect:setDistance(distance)
	if self.activeEffect ~= nil and self.activeEffect.setDistance ~= nil then
		self.activeEffect:setDistance(distance)
	end
end

function TipEffect:getIsVisible()
	if self.activeEffect == nil or self.activeEffect.getIsVisible == nil then
		return false
	else
		return self.activeEffect:getIsVisible()
	end
end

function TipEffect:getIsFullyVisible()
	if self.activeEffect == nil or self.activeEffect.getIsFullyVisible == nil then
		return false
	else
		return self.activeEffect:getIsFullyVisible()
	end
end

function TipEffect.registerEffectXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. ".effectNode(?)#effectClass", "Effect class", "ShaderPlaneEffect")
	Effect.registerEffectXMLPaths(schema, basePath .. ".effectNode(?)")
	ExhaustEffect.registerEffectXMLPaths(schema, basePath .. ".effectNode(?)")
	LevelerEffect.registerEffectXMLPaths(schema, basePath .. ".effectNode(?)")
	MorphPositionEffect.registerEffectXMLPaths(schema, basePath .. ".effectNode(?)")
	ParticleEffect.registerEffectXMLPaths(schema, basePath .. ".effectNode(?)")
	PipeEffect.registerEffectXMLPaths(schema, basePath .. ".effectNode(?)")
	ShaderPlaneEffect.registerEffectXMLPaths(schema, basePath .. ".effectNode(?)")
	SlurrySideToSideEffect.registerEffectXMLPaths(schema, basePath .. ".effectNode(?)")
	WindrowerEffect.registerEffectXMLPaths(schema, basePath .. ".effectNode(?)")
	GrainTankEffect.registerEffectXMLPaths(schema, basePath .. ".effectNode(?)")
	CutterMotionPathEffect.registerEffectXMLPaths(schema, basePath .. ".effectNode(?)")
	CultivatorMotionPathEffect.registerEffectXMLPaths(schema, basePath .. ".effectNode(?)")
	PlowMotionPathEffect.registerEffectXMLPaths(schema, basePath .. ".effectNode(?)")
	WindrowerMotionPathEffect.registerEffectXMLPaths(schema, basePath .. ".effectNode(?)")
	MotionPathEffect.registerEffectXMLPaths(schema, basePath .. ".effectNode(?)")
	VariableMotionPathEffect.registerEffectXMLPaths(schema, basePath .. ".effectNode(?)")
end
