-- Local values: VariableMotionPathEffect_mt
VariableMotionPathEffect = {}
local VariableMotionPathEffect_mt = Class(VariableMotionPathEffect, TypedMotionPathEffect)

-- Upvalues: VariableMotionPathEffect_mt
-- Local values: self
function VariableMotionPathEffect.new(customMt)
	-- upvalues: (copy) VariableMotionPathEffect_mt
	return TypedMotionPathEffect.new(customMt or VariableMotionPathEffect_mt)
end

-- Local values: _, stateKey, referenceValue, density, speedScale, visibilityXMin, visibilityXMax, visibilityYMin, visibilityYMax, visibilityZMin, visibilityZMax, scaleX, scaleY, scaleZ
function VariableMotionPathEffect:loadEffectAttributes(xmlFile, key, node, i3dNode, i3dMapping)
	if not VariableMotionPathEffect:superClass().loadEffectAttributes(self, xmlFile, key, node, i3dNode, i3dMapping) then
		return false
	end
	self.referenceNode = xmlFile:getValue(key .. ".variableState#referenceNode", nil, Utils.getNoNil(node, self.rootNodes), i3dMapping)
	if self.referenceNode ~= nil then
		self.referenceRotAxis = xmlFile:getValue(key .. ".variableState#referenceRotAxis")
		self.referenceTransAxis = xmlFile:getValue(key .. ".variableState#referenceTransAxis")
		self.axisValues = { 0, 0, 0 }
		if self.referenceRotAxis == nil and self.referenceTransAxis == nil then
			Logging.xmlWarning(xmlFile, "VariableMotionPathEffect: No reference rotation or translation axis defined in (%s)", key)
		end
	end
	self.referenceUseVehicleSpeed = xmlFile:getValue(key .. ".variableState#referenceUseVehicleSpeed", false)
	for _, v9_ in xmlFile:iterator(key .. ".variableState.state") do
		local v10_ = xmlFile:getValue(v9_ .. "#referenceValue")
		if self.referenceRotAxis ~= nil then
			v10_ = math.rad(v10_)
		end
		local v11_ = xmlFile:getValue(v9_ .. "#density")
		if v11_ ~= nil then
			if self.animCurveDensity == nil then
				self.animCurveDensity = AnimCurve.new(linearInterpolatorN)
			end
			self.animCurveDensity:addKeyframe({
				v11_,
				["time"] = v10_
			})
		end
		local v12_ = xmlFile:getValue(v9_ .. "#speedScale")
		if v12_ ~= nil then
			if self.animCurveSpeedScale == nil then
				self.animCurveSpeedScale = AnimCurve.new(linearInterpolatorN)
			end
			self.animCurveSpeedScale:addKeyframe({
				v12_,
				["time"] = v10_
			})
		end
		local v13_, v14_ = xmlFile:getValue(v9_ .. "#visibilityX")
		local v15_, v16_ = xmlFile:getValue(v9_ .. "#visibilityY")
		local v17_, v18_ = xmlFile:getValue(v9_ .. "#visibilityZ")
		if v13_ ~= nil or (v14_ ~= nil or (v15_ ~= nil or (v16_ ~= nil or (v17_ ~= nil or v18_ ~= nil)))) then
			if self.animCurveVisibility == nil then
				self.animCurveVisibility = AnimCurve.new(linearInterpolatorN)
			end
			self.animCurveVisibility:addKeyframe({
				v13_,
				v14_,
				v15_,
				v16_,
				v17_,
				v18_,
				["time"] = v10_
			})
		end
		local v19_, v20_, v21_ = xmlFile:getValue(v9_ .. "#scale")
		if v19_ ~= nil or (v20_ ~= nil or v21_ ~= nil) then
			if self.animCurveScale == nil then
				self.animCurveScale = AnimCurve.new(linearInterpolatorN)
			end
			self.animCurveScale:addKeyframe({
				v19_,
				v20_,
				v21_,
				["time"] = v10_
			})
		end
	end
	return true
end

-- Local values: refValue, density, speedScale, visibilityXMin, visibilityXMax, visibilityYMin, visibilityYMax, visibilityZMin, visibilityZMax, visibilityXChanged, visibilityYChanged, visibilityZChanged, _, effectNode, scaleX, scaleY, scaleZ, _, effectNode
function VariableMotionPathEffect:update(dt)
	VariableMotionPathEffect:superClass().update(self, dt)
	local v24_ = 0
	if self.referenceNode ~= nil then
		if self.referenceRotAxis == nil then
			if self.referenceTransAxis ~= nil then
				local v25_ = self.axisValues
				local v26_ = self.axisValues
				local v27_ = self.axisValues
				local v28_, v29_, v30_ = getTranslation(self.referenceNode)
				v25_[1] = v28_
				v26_[2] = v29_
				v27_[3] = v30_
				v24_ = self.axisValues[self.referenceTransAxis]
			end
		else
			local v31_ = self.axisValues
			local v32_ = self.axisValues
			local v33_ = self.axisValues
			local v34_, v35_, v36_ = getRotation(self.referenceNode)
			v31_[1] = v34_
			v32_[2] = v35_
			v33_[3] = v36_
			v24_ = self.axisValues[self.referenceRotAxis]
		end
	end
	if self.referenceUseVehicleSpeed and self.parent.getLastSpeed ~= nil then
		v24_ = self.parent:getLastSpeed()
	end
	if self.animCurveDensity ~= nil then
		local v37_ = self.animCurveDensity:get(v24_)
		if v37_ ~= nil then
			self.effectDensityScaleSetting = v37_
		end
	end
	if self.animCurveSpeedScale ~= nil then
		local v38_ = self.animCurveSpeedScale:get(v24_)
		if v38_ ~= nil then
			self.effectSpeedScale = v38_
			self.effectSpeedScaleOrig = v38_
		end
	end
	if self.animCurveVisibility ~= nil then
		local v39_, v40_, v41_, v42_, v43_, v44_ = self.animCurveVisibility:get(v24_)
		local v45_ = false
		local v46_ = false
		local v47_
		if v39_ == nil then
			v47_ = false
		else
			self.visibilityX[1] = v39_
			v47_ = true
		end
		if v40_ ~= nil then
			self.visibilityX[2] = v40_
			v47_ = true
		end
		if v41_ ~= nil then
			self.visibilityY[1] = v41_
			v45_ = true
		end
		if v42_ ~= nil then
			self.visibilityY[2] = v42_
			v45_ = true
		end
		if v43_ ~= nil then
			self.visibilityZ[1] = v43_
			v46_ = true
		end
		if v44_ ~= nil then
			self.visibilityZ[2] = v44_
			v46_ = true
		end
		for _, v48_ in ipairs(self.currentEffectNodes) do
			if v47_ and (self.visibilityX ~= nil and #self.visibilityX == 2) then
				setShaderParameterRecursive(v48_, "visibilityX", self.visibilityX[1], self.visibilityX[2], nil, nil, false)
			end
			if v45_ and (self.visibilityY ~= nil and #self.visibilityY == 2) then
				setShaderParameterRecursive(v48_, "visibilityY", self.visibilityY[1], self.visibilityY[2], nil, nil, false)
			end
			if v46_ and (self.visibilityZ ~= nil and #self.visibilityZ == 2) then
				setShaderParameterRecursive(v48_, "visibilityZ", self.visibilityZ[1], self.visibilityZ[2], nil, nil, false)
			end
		end
	end
	if self.animCurveScale ~= nil then
		local v49_, v50_, v51_ = self.animCurveScale:get(v24_)
		for _, v52_ in ipairs(self.currentEffectNodes) do
			setScale(v52_, v49_, v50_, v51_)
		end
	end
end

function VariableMotionPathEffect.registerEffectXMLPaths(schema, basePath)
	TypedMotionPathEffect.registerEffectXMLPaths(schema, basePath)
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".variableState#referenceNode", "(VariableMotionPathEffect) Reference Node")
	schema:register(XMLValueType.INT, basePath .. ".variableState#referenceRotAxis", "(VariableMotionPathEffect) Reference Rotation Axis")
	schema:register(XMLValueType.INT, basePath .. ".variableState#referenceTransAxis", "(VariableMotionPathEffect) Reference Translation Axis")
	schema:register(XMLValueType.BOOL, basePath .. ".variableState#referenceUseVehicleSpeed", "(VariableMotionPathEffect) Use vehicle speed as reference value", false)
	schema:register(XMLValueType.FLOAT, basePath .. ".variableState.state(?)#referenceValue", "(VariableMotionPathEffect) Reference Value")
	schema:register(XMLValueType.FLOAT, basePath .. ".variableState.state(?)#density", "(VariableMotionPathEffect) Density in this state")
	schema:register(XMLValueType.FLOAT, basePath .. ".variableState.state(?)#speedScale", "(VariableMotionPathEffect) Speed scale in this state")
	schema:register(XMLValueType.VECTOR_2, basePath .. ".variableState.state(?)#visibilityX", "(VariableMotionPathEffect) Visibility cut on X axis in this state", "50 -50")
	schema:register(XMLValueType.VECTOR_2, basePath .. ".variableState.state(?)#visibilityY", "(VariableMotionPathEffect) Visibility cut on Y axis in this state", "50 -50")
	schema:register(XMLValueType.VECTOR_2, basePath .. ".variableState.state(?)#visibilityZ", "(VariableMotionPathEffect) Visibility cut on Z axis in this state", "50 -50")
	schema:register(XMLValueType.VECTOR_SCALE, basePath .. ".variableState.state(?)#scale", "(VariableMotionPathEffect) Scale of the mesh in this state")
end
