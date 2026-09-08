-- Local values: RotationAnimation_mt
RotationAnimation = {}
RotationAnimation.STATE_OFF = 0
RotationAnimation.STATE_ON = 1
RotationAnimation.STATE_TURNING_OFF = 2
local RotationAnimation_mt = Class(RotationAnimation, Animation)

-- Upvalues: RotationAnimation_mt
-- Local values: self
function RotationAnimation.new(customMt)
	-- upvalues: (copy) RotationAnimation_mt
	local v3_ = Animation.new(customMt or RotationAnimation_mt)
	v3_.state = RotationAnimation.STATE_OFF
	v3_.nodes = {}
	v3_.shaderParameterName = nil
	v3_.shaderComponentScale = {
		1,
		0,
		0,
		0
	}
	v3_.rotSpeed = 0
	v3_.currentAlpha = 0
	v3_.initialTurnOnFadeTime = 1000
	v3_.turnOnOffVariance = nil
	v3_.turnOnFadeTime = 0
	v3_.turnOffFadeTime = 0
	v3_.rotAxis = 1
	v3_.currentRot = 0
	v3_.owner = nil
	return v3_
end

-- Local values: node, _, nodeKey, speedScale, rotSpeed, node, _, node, _, prevName, speedFuncStr, node, speedScale, _, node, speedScale, rx, ry, rz
function RotationAnimation:load(xmlFile, key, rootNodes, owner, i3dMapping)
	if not xmlFile:hasProperty(key) then
		return nil
	end
	self.owner = owner
	self.rotSpeed = xmlFile:getValue(key .. "#rotSpeed", 1) * 0.001
	local v10_ = xmlFile:getValue(key .. "#node", nil, rootNodes, i3dMapping)
	if v10_ ~= nil then
		self.nodes[v10_] = 1
	end
	for _, v11_ in xmlFile:iterator(key .. ".node") do
		local v12_ = xmlFile:getValue(v11_ .. "#node", nil, rootNodes, i3dMapping)
		if v12_ ~= nil then
			local v13_ = xmlFile:getValue(v11_ .. "#speedScale", 1)
			local v14_ = xmlFile:getValue(v11_ .. "#rotSpeed")
			if v14_ ~= nil then
				v13_ = v13_ * (v14_ * 0.001) / self.rotSpeed
			end
			self.nodes[v12_] = v13_
		end
	end
	if table.size(self.nodes) == 0 then
		Logging.xmlWarning(xmlFile, "Missing node(s) for rotation animation \'%s\'!", key)
		return nil
	end
	self.rootNode = next(self.nodes)
	self.shaderParameterName = xmlFile:getValue(key .. "#shaderParameterName")
	if self.shaderParameterName ~= nil then
		for v15_, _ in pairs(self.nodes) do
			if not getHasShaderParameter(v15_, self.shaderParameterName) then
				Logging.xmlWarning(xmlFile, "Node \'%s\' has no shader parameter \'%s\' for animationNode \'%s\'!", getName(v15_), self.shaderParameterName, key)
				return nil
			end
		end
		self.shaderParameterPrevName = xmlFile:getValue(key .. "#shaderParameterPrevName")
		if self.shaderParameterPrevName == nil then
			local v16_ = string.upper
			local v17_ = self.shaderParameterName
			local v18_ = v16_((string.sub(v17_, 1, 1)))
			local v19_ = self.shaderParameterName
			local v20_ = "prev" .. v18_ .. string.sub(v19_, 2)
			if getHasShaderParameter(self.rootNode, v20_) then
				self.shaderParameterPrevName = v20_
			end
		else
			for v21_, _ in pairs(self.nodes) do
				if not getHasShaderParameter(v21_, self.shaderParameterPrevName) then
					Logging.xmlWarning(xmlFile, "Node \'%s\' has no shader parameter \'%s\' (prev) for animationNode \'%s\'!", getName(v21_), self.shaderParameterPrevName, key)
					return nil
				end
			end
		end
	end
	self.shaderComponentScale = xmlFile:getValue(key .. "#shaderComponentScale", "1 0 0 0", true)
	self.rotSpeed = xmlFile:getValue(key .. "#rotSpeed", 1) * 0.001
	self.rotAxis = xmlFile:getValue(key .. "#rotAxis", 2)
	local v22_ = xmlFile:getValue(key .. "#turnOnFadeTime", 2) * 1000
	self.turnOnFadeTime = math.max(v22_, 1)
	local v23_ = xmlFile:getValue(key .. "#turnOffFadeTime", 2) * 1000
	self.turnOffFadeTime = math.max(v23_, 1)
	self.turnOnOffVariance = xmlFile:getValue(key .. "#turnOnOffVariance")
	if self.turnOnOffVariance ~= nil then
		self.initialTurnOnFadeTime = self.turnOnFadeTime
		self.initialTurnOffFadeTime = self.turnOffFadeTime
		self.turnOnOffVariance = self.turnOnOffVariance * 1000
	end
	local v24_ = xmlFile:getValue(key .. "#speedFunc")
	if v24_ ~= nil then
		if owner[v24_] == nil then
			Logging.xmlWarning(xmlFile, "Could not find speed function \'%s\' for rotation animation \'%s\'!", v24_, key)
		else
			self.speedFunc = owner[v24_]
			self.speedFuncTarget = self.owner
			self.speedFuncParam = xmlFile:getValue(key .. "#speedFuncParam")
		end
	end
	self.minAlphaForTurnOff = xmlFile:getValue(key .. "#minAlphaForTurnOff", 0)
	self.delayedTurnOff = false
	self.turnedOffRotation = xmlFile:getValue(key .. "#turnedOffRotation")
	if self.turnedOffRotation ~= nil then
		self.turnOffFadeTimeOrigin = self.turnOffFadeTime
		self.turnedOffSubDivisions = xmlFile:getValue(key .. "#turnedOffSubDivisions", 1)
		if self.shaderParameterName == nil then
			for v25_, v26_ in pairs(self.nodes) do
				if self.rotAxis == 2 then
					setRotation(v25_, 0, self.turnedOffRotation * v26_, 0)
				elseif self.rotAxis == 1 then
					setRotation(v25_, self.turnedOffRotation * v26_, 0, 0)
				else
					setRotation(v25_, 0, 0, self.turnedOffRotation * v26_)
				end
			end
			self.currentRot = self.turnedOffRotation
		end
	end
	if self.rotAxis == 1 then
		local v27_, _, _ = getRotation(self.rootNode)
		self.currentRot = v27_
	elseif self.rotAxis == 2 then
		local _, v28_, _ = getRotation(self.rootNode)
		self.currentRot = v28_
	else
		local _, _, v29_ = getRotation(self.rootNode)
		self.currentRot = v29_
	end
	for v30_, v31_ in pairs(self.nodes) do
		local v32_, v33_, v34_ = getRotation(v30_)
		if self.rotAxis == 2 then
			setRotation(v30_, v32_, self.currentRot * v31_, v34_)
		elseif self.rotAxis == 1 then
			setRotation(v30_, self.currentRot * v31_, v33_, v34_)
		else
			setRotation(v30_, v32_, v33_, self.currentRot * v31_)
		end
	end
	return self
end

-- Local values: prevRot, speedFactor, frame, rot, rot, rot, node, speedScale, rx, ry, rz, scaleX, scaleY, scaleZ, scaleW, prev_x, prev_y, prev_z, prev_w, x, y, z, w, node, speedScale, node, _
function RotationAnimation:update(dt)
	RotationAnimation:superClass().update(self, dt)
	local v37_ = self.currentRot
	local v38_ = self.speedFunc == nil and 1 or self.speedFunc(self.speedFuncTarget, self.speedFuncParam)
	local v39_ = 16.66667
	if self.state == RotationAnimation.STATE_ON then
		if self.currentAlpha < 1 then
			while dt > 0 do
				local v40_ = self.currentAlpha + math.min(v39_, dt) / self.turnOnFadeTime
				self.currentAlpha = math.min(1, v40_)
				local v41_ = self.currentAlpha * math.min(v39_, dt) * self.rotSpeed * v38_
				self.currentRot = (self.currentRot + v41_) % 6.283185307179586
				dt = dt - 16.66667
				if self.currentAlpha == 1 then
					break
				end
			end
		else
			local v42_ = self.currentAlpha * dt * self.rotSpeed * v38_
			self.currentRot = (self.currentRot + v42_) % 6.283185307179586
		end
	elseif self.state == RotationAnimation.STATE_TURNING_OFF then
		while dt > 0 do
			local v43_ = self.currentAlpha - math.min(v39_, dt) / self.turnOffFadeTime
			self.currentAlpha = math.max(0, v43_)
			local v44_ = self.currentAlpha * math.min(v39_, dt) * self.rotSpeed * v38_
			self.currentRot = (self.currentRot + v44_) % 6.283185307179586
			dt = dt - 16.66667
			if self.currentAlpha == 0 then
				break
			end
		end
	end
	if self.currentRot ~= v37_ then
		if self.shaderParameterName == nil then
			for v45_, v46_ in pairs(self.nodes) do
				local v47_, v48_, v49_ = getRotation(v45_)
				if self.rotAxis == 2 then
					setRotation(v45_, v47_, self.currentRot * v46_, v49_)
				elseif self.rotAxis == 1 then
					setRotation(v45_, self.currentRot * v46_, v48_, v49_)
				else
					setRotation(v45_, v47_, v48_, self.currentRot * v46_)
				end
			end
		else
			local v50_ = self.shaderComponentScale[1]
			local v51_ = self.shaderComponentScale[2]
			local v52_ = self.shaderComponentScale[3]
			local v53_ = self.shaderComponentScale[4]
			local v54_ = v37_ * v50_
			local v55_ = v37_ * v51_
			local v56_ = v37_ * v52_
			local v57_ = v37_ * v53_
			local v58_ = self.currentRot * v50_
			local v59_ = self.currentRot * v51_
			local v60_ = self.currentRot * v52_
			local v61_ = self.currentRot * v53_
			for v62_, v63_ in pairs(self.nodes) do
				if self.shaderParameterPrevName == nil then
					setShaderParameter(v62_, self.shaderParameterName, v58_ * v63_, v59_ * v63_, v60_ * v63_, v61_ * v63_, false)
				else
					setShaderParameter(v62_, self.shaderParameterPrevName, v54_ * v63_, v55_ * v63_, v56_ * v63_, v57_ * v63_, false)
					setShaderParameter(v62_, self.shaderParameterName, v58_ * v63_, v59_ * v63_, v60_ * v63_, v61_ * v63_, false)
				end
			end
		end
		if self.owner ~= nil and self.owner.setMovingToolDirty ~= nil then
			for v64_, _ in pairs(self.nodes) do
				self.owner:setMovingToolDirty(v64_, true)
			end
		end
	end
	if self.currentAlpha == 0 then
		self.state = RotationAnimation.STATE_OFF
	end
	if self.delayedTurnOff and self.currentAlpha >= self.minAlphaForTurnOff then
		self.delayedTurnOff = false
		self:stop()
	end
	self:updateDuplicates()
end

function RotationAnimation:isRunning()
	return self.state ~= RotationAnimation.STATE_OFF
end

function RotationAnimation:start()
	if self.state == RotationAnimation.STATE_ON then
		return false
	end
	if self.state == RotationAnimation.STATE_OFF and (self.turnOnOffVariance ~= nil and self.currentAlpha == 0) then
		self.turnOnFadeTime = self.initialTurnOnFadeTime + math.random(-self.turnOnOffVariance, self.turnOnOffVariance)
		self.turnOffFadeTime = self.initialTurnOffFadeTime + math.random(-self.turnOnOffVariance, self.turnOnOffVariance)
	end
	self.state = RotationAnimation.STATE_ON
	self:updateDuplicates()
	return true
end
function RotationAnimation.stop()
	-- failed to decompile
end

function RotationAnimation:reset()
	self.currentAlpha = 0
	self.state = RotationAnimation.STATE_OFF
	self:updateDuplicates()
end

-- Local values: node, _
function RotationAnimation:isDuplicate(otherAnimation)
	if not otherAnimation:isa(RotationAnimation) or (self.parent ~= otherAnimation.parent or table.size(self.nodes) ~= table.size(otherAnimation.nodes)) then
		return false
	end
	for v70_, _ in pairs(self.nodes) do
		if otherAnimation.nodes[v70_] == nil then
			return false
		end
	end
	return true
end

function RotationAnimation:updateDuplicate(otherAnimation)
	otherAnimation.currentAlpha = self.currentAlpha
	otherAnimation.currentRot = self.currentRot
	otherAnimation.state = self.state
end

function RotationAnimation.registerAnimationClassXMLPaths(schema, basePath)
	schema:register(XMLValueType.NODE_INDEX, basePath .. "#node", "Node")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".node(?)#node", "Node")
	schema:register(XMLValueType.FLOAT, basePath .. ".node(?)#speedScale", "Speed scale", 1)
	schema:register(XMLValueType.ANGLE, basePath .. ".node(?)#rotSpeed", "Rotation speed", "Default rotation speed")
	schema:register(XMLValueType.STRING, basePath .. "#shaderParameterName", "Shader parameter name")
	schema:register(XMLValueType.VECTOR_4, basePath .. "#shaderComponentScale", "Shader parameter name", "1 0 0 0")
	schema:register(XMLValueType.ANGLE, basePath .. "#rotSpeed", "Rotation speed", 1)
	schema:register(XMLValueType.ANGLE, basePath .. "#turnedOffRotation", "(RotationAnimation) Target rotation while turned off")
	schema:register(XMLValueType.FLOAT, basePath .. "#minAlphaForTurnOff", "Min. alpha for turn off (speed [0-1])", 0)
	schema:register(XMLValueType.FLOAT, basePath .. "#turnedOffSubDivisions", "Amount of sub divisions which have the same state", 1)
	schema:register(XMLValueType.FLOAT, basePath .. "#rotAxis", "Rotation axis", 2)
	schema:register(XMLValueType.FLOAT, basePath .. "#turnOnFadeTime", "Turn on fade time", 2)
	schema:register(XMLValueType.FLOAT, basePath .. "#turnOffFadeTime", "Turn off fade time", 2)
	schema:register(XMLValueType.FLOAT, basePath .. "#turnOnOffVariance", "Turn off time variance")
	schema:register(XMLValueType.STRING, basePath .. "#speedFunc", "Lua speed function")
	schema:register(XMLValueType.STRING, basePath .. "#speedFuncParam", "Additional string parameter that is passed to the speedFunc")
end
