SnowPlowMotionPathEffect = {}
local SnowPlowMotionPathEffect_mt = Class(SnowPlowMotionPathEffect, TypedMotionPathEffect)
SnowPlowMotionPathEffect.Y_OFFSET = 0.75
function SnowPlowMotionPathEffect.new(customMt)
	local self = TypedMotionPathEffect.new(customMt or SnowPlowMotionPathEffect_mt)
	self.fillLevelPct = 0
	self.lastSpeed = 0
	return self
end
function SnowPlowMotionPathEffect:loadEffectAttributes(xmlFile, key, node, i3dNode, i3dMapping)
	if not SnowPlowMotionPathEffect:superClass().loadEffectAttributes(self, xmlFile, key, node, i3dNode, i3dMapping) then
		return false
	else
		self.shaderPlaneNode = xmlFile:getValue(key .. ".snowPlowEffect#shaderPlane", nil, self.rootNodes, i3dMapping)
		self.shaderPlaneMinScale = xmlFile:getValue(key .. ".snowPlowEffect#minScale", nil, true) or { 1, 1, 1 }
		self.shaderPlaneMaxScale = xmlFile:getValue(key .. ".snowPlowEffect#maxScale", nil, true) or { 1, 1, 1 }
		self.shaderPlaneScrollSpeed = xmlFile:getValue(key .. ".snowPlowEffect#scrollSpeed", 1) * 0.001
		self.shaderPlaneScrollTime = 0
		self.effectTransNode = createTransformGroup("effectTransNode")
		link(self.linkNodes[1], self.effectTransNode)
		if self.shaderPlaneNode ~= nil then
			local x, y, z = localToLocal(self.shaderPlaneNode, self.effectTransNode, 0, 0, 0)
			local rx, ry, rz = localRotationToLocal(self.shaderPlaneNode, self.effectTransNode, 0, 0, 0)
			link(self.effectTransNode, self.shaderPlaneNode)
			setTranslation(self.shaderPlaneNode, x, y, z)
			setRotation(self.shaderPlaneNode, rx, ry, rz)
		end
		setTranslation(self.effectTransNode, 0, -SnowPlowMotionPathEffect.Y_OFFSET, 0)
		setRotation(self.effectTransNode, 0, 0, 0)
		self.linkNodes[1] = self.effectTransNode
		return true
	end
end
function SnowPlowMotionPathEffect:update(dt)
	self.fadeIn = 1
	self.fadeOut = 0
	if self.hasCurrentEffectNodes then
		local activeState = 0.005 < self.fillLevelPct and 0.1 < self.lastSpeed
		local alpha = math.clamp(self.lastSpeed / 20, 0.1, 1)
		if self.state ~= MotionPathEffect.STATE_OFF then
			for _, effectNode in ipairs(self.currentEffectNodes) do
				setShaderParameterRecursive(effectNode, "scrollPos", nil, 0, 1, alpha, false)
			end
			if self.shaderPlaneNode ~= nil then
				local sx, sy, sz = MathUtil.vector3ArrayLerp(self.shaderPlaneMinScale, self.shaderPlaneMaxScale, alpha)
				setScale(self.shaderPlaneNode, sx, sy, sz)
				self.shaderPlaneScrollTime = self.shaderPlaneScrollTime + self.shaderPlaneScrollSpeed * dt * self.effectSpeedScale
				setShaderParameter(self.shaderPlaneNode, "offsetUV", self.shaderPlaneScrollTime, 0, 0, 0, false)
				setShaderParameter(self.shaderPlaneNode, "VertxoffsetVertexdeformMotionUVscale", -35, 1, self.shaderPlaneScrollTime, 6, false)
			end
		end
		if activeState then
			self.effectSpeedScale = self.effectSpeedScaleOrig * math.max(alpha, 0.3)
			local x, y, z = getTranslation(self.effectTransNode)
			y = math.min(y + dt * 0.001, 0)
			local wx, wy, wz = getWorldTranslation(self.effectTransNode)
			local terrainHeight = getTerrainHeightAtWorldPos(g_terrainNode, wx, wy, wz) - 0.5
			local _, minY, _ = worldToLocal(getParent(self.effectTransNode), wx, terrainHeight, wz)
			y = math.max(y, minY)
			setTranslation(self.effectTransNode, x, y, z)
			setVisibility(self.effectTransNode, -SnowPlowMotionPathEffect.Y_OFFSET < y)
		else
			self.effectSpeedScale = self.effectSpeedScaleOrig * 0.5
			local x, y, z = getTranslation(self.effectTransNode)
			y = math.max(y - dt * 0.001, -SnowPlowMotionPathEffect.Y_OFFSET)
			setTranslation(self.effectTransNode, x, y, z)
			setVisibility(self.effectTransNode, -SnowPlowMotionPathEffect.Y_OFFSET < y)
		end
	end
	SnowPlowMotionPathEffect:superClass().update(self, dt)
end
function SnowPlowMotionPathEffect:setFillLevel(fillLevelPct)
	self.fillLevelPct = fillLevelPct
end
function SnowPlowMotionPathEffect:setLastVehicleSpeed(lastSpeed)
	self.lastSpeed = lastSpeed
end
function SnowPlowMotionPathEffect:stop()
	return SnowPlowMotionPathEffect:superClass().stop(self)
end
function SnowPlowMotionPathEffect:reset()
	return SnowPlowMotionPathEffect:superClass().reset(self)
end
function SnowPlowMotionPathEffect.loadEffectDefinitionFromXML(motionPathEffect, xmlFile, key)
	TypedMotionPathEffect.loadEffectDefinitionFromXML(motionPathEffect, xmlFile, key)
end
function SnowPlowMotionPathEffect.loadEffectMeshFromXML(effectMesh, xmlFile, key)
	TypedMotionPathEffect.loadEffectMeshFromXML(effectMesh, xmlFile, key)
end
function SnowPlowMotionPathEffect.loadEffectMaterialFromXML(effectMaterial, xmlFile, key)
	TypedMotionPathEffect.loadEffectMaterialFromXML(effectMaterial, xmlFile, key)
end
function SnowPlowMotionPathEffect.registerEffectDefinitionXMLPaths(schema, basePath)
	TypedMotionPathEffect.registerEffectDefinitionXMLPaths(schema, basePath)
end
function SnowPlowMotionPathEffect.registerEffectMeshXMLPaths(schema, basePath)
	TypedMotionPathEffect.registerEffectMeshXMLPaths(schema, basePath)
end
function SnowPlowMotionPathEffect.registerEffectMaterialXMLPaths(schema, basePath)
	TypedMotionPathEffect.registerEffectMaterialXMLPaths(schema, basePath)
end
function SnowPlowMotionPathEffect.registerEffectXMLPaths(schema, basePath)
	TypedMotionPathEffect.registerEffectXMLPaths(schema, basePath)
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".snowPlowEffect#shaderPlane", "(SnowPlowMotionPathEffect) Node of shader plane effect to control the same way")
	schema:register(XMLValueType.VECTOR_SCALE, basePath .. ".snowPlowEffect#minScale", "(SnowPlowMotionPathEffect) Min. Scale which corresponds to the first motion path array state", "1 1 1")
	schema:register(XMLValueType.VECTOR_SCALE, basePath .. ".snowPlowEffect#maxScale", "(SnowPlowMotionPathEffect) Max. Scale which corresponds to the second motion path array state", "1 1 1")
	schema:register(XMLValueType.FLOAT, basePath .. ".snowPlowEffect#scrollSpeed", "(SnowPlowMotionPathEffect) UV scroll speed", 1)
end
