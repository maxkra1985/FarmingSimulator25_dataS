-- Local values: PipeEffect_mt
PipeEffect = {}
PipeEffect.SAFETY_OFFSET = 0.01
local PipeEffect_mt = Class(PipeEffect, ShaderPlaneEffect)

-- Upvalues: PipeEffect_mt
-- Local values: self
function PipeEffect.new(customMt)
	-- upvalues: (copy) PipeEffect_mt
	return ShaderPlaneEffect.new(customMt or PipeEffect_mt)
end

-- Local values: positionUpdateNodesStr, nodeStrs, _, nodeStr, updateNode
function PipeEffect:loadEffectAttributes(xmlFile, key, node, i3dNode, i3dMapping)
	if not PipeEffect:superClass().loadEffectAttributes(self, xmlFile, key, node, i3dNode, i3dMapping) then
		return false
	end
	self.maxBending = Effect.getValue(xmlFile, key, node, "maxBending", 0.25)
	self.shapeScaleSpread = Effect.getValue(xmlFile, key, node, "shapeScaleSpread", "0.6 1 1 0", true)
	self.uvScaleSpeedFreqAmp = Effect.getValue(xmlFile, key, node, "uvScaleSpeedFreqAmp", nil, true)
	local v9_ = Effect.getValue(xmlFile, key, node, "positionUpdateNodes")
	if v9_ ~= nil then
		local v10_ = v9_:split(" ")
		self.positionUpdateNodes = {}
		for _, v11_ in pairs(v10_) do
			local v12_ = I3DUtil.indexToObject(Utils.getNoNil(node, self.rootNodes), v11_, i3dMapping)
			if v12_ ~= nil then
				local v13_ = self.positionUpdateNodes
				table.insert(v13_, v12_)
			end
		end
	end
	self.updateDistance = Effect.getValue(xmlFile, key, node, "updateDistance", true)
	self.extraDistance = Effect.getValue(xmlFile, key, node, "extraDistance", 0)
	self.worldTarget = { 0, 0, 0 }
	self.controlPoint = Effect.getValue(xmlFile, key, node, "controlPoint", "10 0.25 0 0", true)
	self.controlPointY = 0
	self.distance = 0
	return true
end

-- Local values: mCos, mSin, y, z, wx, wy, wz, _, node
function PipeEffect:update(dt)
	PipeEffect:superClass().update(self, dt)
	if self.distance > 0 then
		local v16_ = self.controlPointY
		local v17_ = math.cos(v16_)
		local v18_ = self.controlPointY
		local v19_ = math.sin(v18_)
		local v20_ = MathUtil.dotProduct(0, 0, self.distance, 0, v17_, -v19_)
		local v21_ = MathUtil.dotProduct(0, 0, self.distance, 0, v19_, v17_)
		local v22_, v23_, v24_ = localToWorld(self.node, 0, v20_, v21_)
		local v25_ = self.worldTarget
		local v26_ = self.worldTarget
		local v27_ = self.worldTarget
		v25_[1] = v22_
		v26_[2] = v23_
		v27_[3] = v24_
	end
	if self.positionUpdateNodes ~= nil then
		for _, v28_ in pairs(self.positionUpdateNodes) do
			setWorldTranslation(v28_, self.worldTarget[1], self.worldTarget[2], self.worldTarget[3])
		end
	end
end

-- Local values: _, dirY, _, mCos, mSin, y, z, realDistance
function PipeEffect:setDistance(distance, terrain)
	setVisibility(self.node, distance > 0)
	if self.updateDistance and getHasShaderParameter(self.node, "controlPoint") then
		local v31_ = distance + self.extraDistance
		local _, v32_, _ = localDirectionToWorld(self.node, 0, 1, 0)
		self.controlPointY = v32_ * self.maxBending
		self.distance = v31_
		local v33_ = self.controlPointY
		local v34_ = math.cos(v33_)
		local v35_ = self.controlPointY
		local v36_ = math.sin(v35_)
		local v37_ = MathUtil.dotProduct(0, 0, v31_, 0, v34_, -v36_)
		local v38_ = MathUtil.dotProduct(0, 0, v31_, 0, v36_, v34_)
		local v39_ = v31_ + (v31_ - MathUtil.vector2Length(v37_, v38_))
		setShaderParameter(self.node, "controlPoint", v39_ - PipeEffect.SAFETY_OFFSET, self.controlPointY, 0, 0, false)
	end
end

-- Local values: success
function PipeEffect:setEffectTypeInfo(fillTypeIndex, fruitTypeIndex, growthState)
	local v44_ = PipeEffect:superClass().setEffectTypeInfo(self, fillTypeIndex, fruitTypeIndex, growthState)
	if v44_ then
		if getHasShaderParameter(self.node, "shapeScaleSpread") then
			setShaderParameter(self.node, "shapeScaleSpread", self.shapeScaleSpread[1], self.shapeScaleSpread[2], self.shapeScaleSpread[3], self.shapeScaleSpread[4], false)
		end
		if self.uvScaleSpeedFreqAmp ~= nil and getHasShaderParameter(self.node, "uvScaleSpeedFreqAmp") then
			setShaderParameter(self.node, "uvScaleSpeedFreqAmp", self.uvScaleSpeedFreqAmp[1], self.uvScaleSpeedFreqAmp[2], self.uvScaleSpeedFreqAmp[3], self.uvScaleSpeedFreqAmp[4], false)
		end
		if getHasShaderParameter(self.node, "controlPoint") then
			setShaderParameter(self.node, "controlPoint", self.controlPoint[1], self.controlPoint[2], 0, 0, false)
		end
	end
	return v44_
end

function PipeEffect.registerEffectXMLPaths(schema, basePath)
	schema:register(XMLValueType.FLOAT, basePath .. "#maxBending", "(PipeEffect) Max bending", 0.25)
	schema:register(XMLValueType.VECTOR_4, basePath .. "#shapeScaleSpread", "(PipeEffect) Shape scale spread", "0.6 1 1 0")
	schema:register(XMLValueType.VECTOR_4, basePath .. "#uvScaleSpeedFreqAmp", "(PipeEffect) UV Scale, speed, frequency, amplitude")
	schema:register(XMLValueType.STRING, basePath .. "#positionUpdateNodes", "(PipeEffect) List of nodes to position at control point")
	schema:register(XMLValueType.STRING, basePath .. "#updateDistance", "(PipeEffect) Update effect distance", true)
	schema:register(XMLValueType.STRING, basePath .. "#extraDistance", "(PipeEffect) Extra distance", 0)
	schema:register(XMLValueType.VECTOR_4, basePath .. "#controlPoint", "(PipeEffect) Control point position", "10 0.25 0 0")
end
