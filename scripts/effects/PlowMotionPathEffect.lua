PlowMotionPathEffect = {}
local PlowMotionPathEffect_mt = Class(PlowMotionPathEffect, TypedMotionPathEffect)
function PlowMotionPathEffect.new(customMt)
	local self = TypedMotionPathEffect.new(customMt or PlowMotionPathEffect_mt)
	self.useVehicleSpeed = true
	self.isReverseFadeOutMode = false
	return self
end
function PlowMotionPathEffect:loadEffectAttributes(xmlFile, key, node, i3dNode, i3dMapping)
	if not PlowMotionPathEffect:superClass().loadEffectAttributes(self, xmlFile, key, node, i3dNode, i3dMapping) then
		return false
	else
		self.fadeOutScale = 0.25
		self.maxScaleSpeed = xmlFile:getValue(key .. ".motionPathEffect#maxScaleSpeed", 10)
		self.minScaleOffset = xmlFile:getValue(key .. ".motionPathEffect#minScaleOffset", -0.07)
		return true
	end
end
function PlowMotionPathEffect:update(dt)
	local lastSpeed = self.parent:getLastSpeed()
	local reverseFadeOut = true
	if self.parent.movingDirection >= 0 or not (0.5 < lastSpeed) then
		reverseFadeOut = self.isReverseFadeOutMode
	end
	self.inversedFadeOut = true
	if self.state ~= MotionPathEffect.STATE_OFF then
		self.fadeOutScale = lastSpeed < 2 and 0.25 or 1
		if reverseFadeOut then
			if not self.isReverseFadeOutMode then
				self.isReverseFadeOutMode = true
			end
			self.fadeOutScale = 0.5
		end
		local isFullyHidden = false
		for i, effectNode in ipairs(self.currentEffectNodes) do
			local x, _, z = getWorldTranslation(getParent(effectNode))
			local y = getTerrainHeightAtWorldPos(g_terrainNode, x, 0, z)
			local _, ly, _ = worldToLocal(getParent(effectNode), x, y, z)
			ly = math.min(ly, (1 - math.min(lastSpeed / self.maxScaleSpeed)) * self.minScaleOffset)
			ly = -((1 - ly) ^ 2 - 1)
			if not reverseFadeOut then
				setTranslation(effectNode, 0, ly, 0)
			else
				x, y, z = getTranslation(effectNode)
				ly = math.min(y - dt * 0.0005, ly)
				setTranslation(effectNode, x, ly, z)
				if ly < -1 then
					isFullyHidden = true
				end
			end
		end
		if isFullyHidden then
			if self.state == MotionPathEffect.STATE_TURNING_OFF then
				self.state = MotionPathEffect.STATE_OFF
			end
			self.fadeIn = self.minFade
			self.fadeOut = self.minFade
			self.isReverseFadeOutMode = false
		end
		if self.isReverseFadeOutMode and (1 < self.parent:getLastSpeed() and 0 < self.parent.movingDirection) then
			self.isReverseFadeOutMode = false
			self.fadeIn = self.minFade
			self.fadeOut = self.minFade
		end
	else
		for i, effectNode in ipairs(self.currentEffectNodes) do
			setTranslation(effectNode, 0, 0, 0)
		end
		self.fadeIn = self.minFade
		self.fadeOut = self.minFade
		self.isReverseFadeOutMode = false
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
	schema:register(XMLValueType.FLOAT, basePath .. ".motionPathEffect#minScaleOffset", "(PlowMotionPathEffect) Y Offset when the scale is at it's minimum", -0.07)
end
