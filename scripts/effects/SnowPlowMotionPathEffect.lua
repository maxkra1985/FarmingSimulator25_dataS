-- Local values: SnowPlowMotionPathEffect_mt
SnowPlowMotionPathEffect = {}
local SnowPlowMotionPathEffect_mt = Class(SnowPlowMotionPathEffect, TypedMotionPathEffect)
SnowPlowMotionPathEffect.Y_OFFSET = 0.75

-- Upvalues: SnowPlowMotionPathEffect_mt
-- Local values: self
function SnowPlowMotionPathEffect.new(customMt)
	-- upvalues: (copy) SnowPlowMotionPathEffect_mt
	local v3_ = TypedMotionPathEffect.new(customMt or SnowPlowMotionPathEffect_mt)
	v3_.fillLevelPct = 0
	v3_.lastSpeed = 0
	return v3_
end

-- Local values: x, y, z, rx, ry, rz
function SnowPlowMotionPathEffect:loadEffectAttributes(xmlFile, key, node, i3dNode, i3dMapping)
	if not SnowPlowMotionPathEffect:superClass().loadEffectAttributes(self, xmlFile, key, node, i3dNode, i3dMapping) then
		return false
	end
	self.shaderPlaneNode = xmlFile:getValue(key .. ".snowPlowEffect#shaderPlane", nil, self.rootNodes, i3dMapping)
	self.shaderPlaneMinScale = xmlFile:getValue(key .. ".snowPlowEffect#minScale", nil, true) or { 1, 1, 1 }
	self.shaderPlaneMaxScale = xmlFile:getValue(key .. ".snowPlowEffect#maxScale", nil, true) or { 1, 1, 1 }
	self.shaderPlaneScrollSpeed = xmlFile:getValue(key .. ".snowPlowEffect#scrollSpeed", 1) * 0.001
	self.shaderPlaneScrollTime = 0
	self.effectTransNode = createTransformGroup("effectTransNode")
	link(self.linkNodes[1], self.effectTransNode)
	if self.shaderPlaneNode ~= nil then
		local v10_, v11_, v12_ = localToLocal(self.shaderPlaneNode, self.effectTransNode, 0, 0, 0)
		local v13_, v14_, v15_ = localRotationToLocal(self.shaderPlaneNode, self.effectTransNode, 0, 0, 0)
		link(self.effectTransNode, self.shaderPlaneNode)
		setTranslation(self.shaderPlaneNode, v10_, v11_, v12_)
		setRotation(self.shaderPlaneNode, v13_, v14_, v15_)
	end
	setTranslation(self.effectTransNode, 0, -SnowPlowMotionPathEffect.Y_OFFSET, 0)
	setRotation(self.effectTransNode, 0, 0, 0)
	self.linkNodes[1] = self.effectTransNode
	return true
end

-- Local values: activeState, alpha, _, effectNode, sx, sy, sz, x, y, z, wx, wy, wz, terrainHeight, _, minY, _, x, y, z
function SnowPlowMotionPathEffect:update(dt)
	self.fadeIn = 1
	self.fadeOut = 0
	if self.hasCurrentEffectNodes then
		local v18_
		if self.fillLevelPct > 0.005 then
			v18_ = self.lastSpeed > 0.1
		else
			v18_ = false
		end
		local v19_ = self.lastSpeed / 20
		local v20_ = math.clamp(v19_, 0.1, 1)
		if self.state ~= MotionPathEffect.STATE_OFF then
			for _, v21_ in ipairs(self.currentEffectNodes) do
				setShaderParameterRecursive(v21_, "scrollPos", nil, 0, 1, v20_, false)
			end
			if self.shaderPlaneNode ~= nil then
				local v22_, v23_, v24_ = MathUtil.vector3ArrayLerp(self.shaderPlaneMinScale, self.shaderPlaneMaxScale, v20_)
				setScale(self.shaderPlaneNode, v22_, v23_, v24_)
				self.shaderPlaneScrollTime = self.shaderPlaneScrollTime + self.shaderPlaneScrollSpeed * dt * self.effectSpeedScale
				setShaderParameter(self.shaderPlaneNode, "offsetUV", self.shaderPlaneScrollTime, 0, 0, 0, false)
				setShaderParameter(self.shaderPlaneNode, "VertxoffsetVertexdeformMotionUVscale", -35, 1, self.shaderPlaneScrollTime, 6, false)
			end
		end
		if v18_ then
			self.effectSpeedScale = self.effectSpeedScaleOrig * math.max(v20_, 0.3)
			local v25_, v26_, v27_ = getTranslation(self.effectTransNode)
			local v28_ = v26_ + dt * 0.001
			local v29_ = math.min(v28_, 0)
			local v30_, v31_, v32_ = getWorldTranslation(self.effectTransNode)
			local v33_ = getTerrainHeightAtWorldPos(g_terrainNode, v30_, v31_, v32_) - 0.5
			local _, v34_, _ = worldToLocal(getParent(self.effectTransNode), v30_, v33_, v32_)
			local v35_ = math.max(v29_, v34_)
			setTranslation(self.effectTransNode, v25_, v35_, v27_)
			setVisibility(self.effectTransNode, -SnowPlowMotionPathEffect.Y_OFFSET < v35_)
		else
			self.effectSpeedScale = self.effectSpeedScaleOrig * 0.5
			local v36_, v37_, v38_ = getTranslation(self.effectTransNode)
			local v39_ = v37_ - dt * 0.001
			local v40_ = -SnowPlowMotionPathEffect.Y_OFFSET
			local v41_ = math.max(v39_, v40_)
			setTranslation(self.effectTransNode, v36_, v41_, v38_)
			setVisibility(self.effectTransNode, -SnowPlowMotionPathEffect.Y_OFFSET < v41_)
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
