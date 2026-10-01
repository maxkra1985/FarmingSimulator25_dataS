RotationAnimation = {}
RotationAnimation.STATE_OFF = 0
RotationAnimation.STATE_ON = 1
RotationAnimation.STATE_TURNING_OFF = 2
local RotationAnimation_mt = Class(RotationAnimation, Animation)
function RotationAnimation.new(customMt)
	local self = Animation.new(customMt or RotationAnimation_mt)
	self.state = RotationAnimation.STATE_OFF
	self.nodes = {}
	self.shaderParameterName = nil
	self.shaderComponentScale = { 1, 0, 0, 0 }
	self.rotSpeed = 0
	self.currentAlpha = 0
	self.initialTurnOnFadeTime = 1000
	self.turnOnOffVariance = nil
	self.turnOnFadeTime = 0
	self.turnOffFadeTime = 0
	self.rotAxis = 1
	self.currentRot = 0
	self.owner = nil
	return self
end
function RotationAnimation:load(xmlFile, key, rootNodes, owner, i3dMapping)
	if not xmlFile:hasProperty(key) then
		return nil
	end
	self.owner = owner
	self.rotSpeed = xmlFile:getValue(key .. "#rotSpeed", 1) * 0.001
	local node = xmlFile:getValue(key .. "#node", nil, rootNodes, i3dMapping)
	if node ~= nil then
		self.nodes[node] = 1
	end
	for _, nodeKey in xmlFile:iterator(key .. ".node") do
		node = xmlFile:getValue(nodeKey .. "#node", nil, rootNodes, i3dMapping)
		if node == nil then
			continue
		end
		local speedScale = xmlFile:getValue(nodeKey .. "#speedScale", 1)
		local rotSpeed = xmlFile:getValue(nodeKey .. "#rotSpeed")
		if rotSpeed ~= nil then
			speedScale = speedScale * (rotSpeed * 0.001) / self.rotSpeed
		end
		self.nodes[node] = speedScale
	end
	if table.size(self.nodes) == 0 then
		Logging.xmlWarning(xmlFile, "Missing node(s) for rotation animation '%s'!", key)
		return nil
	else
		self.rootNode = next(self.nodes)
		self.shaderParameterName = xmlFile:getValue(key .. "#shaderParameterName")
		if self.shaderParameterName ~= nil then
			for node, _ in pairs(self.nodes) do
				if getHasShaderParameter(node, self.shaderParameterName) then
					continue
				end
				Logging.xmlWarning(xmlFile, "Node '%s' has no shader parameter '%s' for animationNode '%s'!", getName(node), self.shaderParameterName, key)
				return nil
			end
			self.shaderParameterPrevName = xmlFile:getValue(key .. "#shaderParameterPrevName")
			if self.shaderParameterPrevName ~= nil then
				for node, _ in pairs(self.nodes) do
					if getHasShaderParameter(node, self.shaderParameterPrevName) then
						continue
					end
					Logging.xmlWarning(xmlFile, "Node '%s' has no shader parameter '%s' (prev) for animationNode '%s'!", getName(node), self.shaderParameterPrevName, key)
					return nil
				end
			else
				local prevName = "prev" .. string.upper(string.sub(self.shaderParameterName, 1, 1)) .. string.sub(self.shaderParameterName, 2)
				if getHasShaderParameter(self.rootNode, prevName) then
					self.shaderParameterPrevName = prevName
				end
			end
		end
		self.shaderComponentScale = xmlFile:getValue(key .. "#shaderComponentScale", "1 0 0 0", true)
		self.rotSpeed = xmlFile:getValue(key .. "#rotSpeed", 1) * 0.001
		self.rotAxis = xmlFile:getValue(key .. "#rotAxis", 2)
		self.turnOnFadeTime = math.max(xmlFile:getValue(key .. "#turnOnFadeTime", 2) * 1000, 1)
		self.turnOffFadeTime = math.max(xmlFile:getValue(key .. "#turnOffFadeTime", 2) * 1000, 1)
		self.turnOnOffVariance = xmlFile:getValue(key .. "#turnOnOffVariance")
		if self.turnOnOffVariance ~= nil then
			self.initialTurnOnFadeTime = self.turnOnFadeTime
			self.initialTurnOffFadeTime = self.turnOffFadeTime
			self.turnOnOffVariance = self.turnOnOffVariance * 1000
		end
		local speedFuncStr = xmlFile:getValue(key .. "#speedFunc")
		if speedFuncStr ~= nil then
			if owner[speedFuncStr] ~= nil then
				self.speedFunc = owner[speedFuncStr]
				self.speedFuncTarget = self.owner
				self.speedFuncParam = xmlFile:getValue(key .. "#speedFuncParam")
			else
				Logging.xmlWarning(xmlFile, "Could not find speed function '%s' for rotation animation '%s'!", speedFuncStr, key)
			end
		end
		self.minAlphaForTurnOff = xmlFile:getValue(key .. "#minAlphaForTurnOff", 0)
		self.delayedTurnOff = false
		self.turnedOffRotation = xmlFile:getValue(key .. "#turnedOffRotation")
		if self.turnedOffRotation ~= nil then
			self.turnOffFadeTimeOrigin = self.turnOffFadeTime
			self.turnedOffSubDivisions = xmlFile:getValue(key .. "#turnedOffSubDivisions", 1)
			if self.shaderParameterName == nil then
				for node, speedScale in pairs(self.nodes) do
					if self.rotAxis == 2 then
						setRotation(node, 0, self.turnedOffRotation * speedScale, 0)
					elseif self.rotAxis == 1 then
						setRotation(node, self.turnedOffRotation * speedScale, 0, 0)
					else
						setRotation(node, 0, 0, self.turnedOffRotation * speedScale)
					end
				end
				self.currentRot = self.turnedOffRotation
			end
		end
		local _ = nil
		if self.rotAxis == 1 then
			self.currentRot, _, _ = getRotation(self.rootNode)
		elseif self.rotAxis == 2 then
			_, self.currentRot, _ = getRotation(self.rootNode)
		else
			_, _, self.currentRot = getRotation(self.rootNode)
		end
		for node, speedScale in pairs(self.nodes) do
			local rx, ry, rz = getRotation(node)
			if self.rotAxis == 2 then
				setRotation(node, rx, self.currentRot * speedScale, rz)
			elseif self.rotAxis == 1 then
				setRotation(node, self.currentRot * speedScale, ry, rz)
			else
				setRotation(node, rx, ry, self.currentRot * speedScale)
			end
		end
		return self
	end
end
function RotationAnimation:update(dt)
	RotationAnimation:superClass().update(self, dt)
	local prevRot = self.currentRot
	local speedFactor = nil
	if self.speedFunc ~= nil then
		speedFactor = self.speedFunc(self.speedFuncTarget, self.speedFuncParam)
	else
		speedFactor = 1
	end
	local frame = 16.66667
	if self.state == RotationAnimation.STATE_ON then
		if self.currentAlpha < 1 then
			while 0 < dt do
				self.currentAlpha = math.min(1, self.currentAlpha + math.min(frame, dt) / self.turnOnFadeTime)
				local rot = self.currentAlpha * math.min(frame, dt) * self.rotSpeed * speedFactor
				self.currentRot = (self.currentRot + rot) % 6.283185307179586
				dt = dt - 16.66667
				if self.currentAlpha ~= 1 then
					continue
				end
				if self.currentRot ~= prevRot then
					if self.shaderParameterName == nil then
						for node, speedScale in pairs(self.nodes) do
							local rx, ry, rz = getRotation(node)
							if self.rotAxis == 2 then
								setRotation(node, rx, self.currentRot * speedScale, rz)
							elseif self.rotAxis == 1 then
								setRotation(node, self.currentRot * speedScale, ry, rz)
							else
								setRotation(node, rx, ry, self.currentRot * speedScale)
							end
						end
					else
						local scaleX = self.shaderComponentScale[1]
						local scaleY = self.shaderComponentScale[2]
						local scaleZ = self.shaderComponentScale[3]
						local scaleW = self.shaderComponentScale[4]
						local prev_x = prevRot * scaleX
						local prev_y = prevRot * scaleY
						local prev_z = prevRot * scaleZ
						local prev_w = prevRot * scaleW
						local x = self.currentRot * scaleX
						local y = self.currentRot * scaleY
						local z = self.currentRot * scaleZ
						local w = self.currentRot * scaleW
						for node, speedScale in pairs(self.nodes) do
							if self.shaderParameterPrevName ~= nil then
								setShaderParameter(node, self.shaderParameterPrevName, prev_x * speedScale, prev_y * speedScale, prev_z * speedScale, prev_w * speedScale, false)
								setShaderParameter(node, self.shaderParameterName, x * speedScale, y * speedScale, z * speedScale, w * speedScale, false)
							else
								setShaderParameter(node, self.shaderParameterName, x * speedScale, y * speedScale, z * speedScale, w * speedScale, false)
							end
						end
					end
					if self.owner ~= nil and self.owner.setMovingToolDirty ~= nil then
						for node, _ in pairs(self.nodes) do
							self.owner:setMovingToolDirty(node, true)
						end
					end
				end
				if self.currentAlpha == 0 then
					self.state = RotationAnimation.STATE_OFF
				end
				if self.delayedTurnOff and self.minAlphaForTurnOff <= self.currentAlpha then
					self.delayedTurnOff = false
					self:stop()
				end
				self:updateDuplicates()
				return
			end
		else
			local rot = self.currentAlpha * dt * self.rotSpeed * speedFactor
			self.currentRot = (self.currentRot + rot) % 6.283185307179586
		end
	elseif self.state == RotationAnimation.STATE_TURNING_OFF then
		while 0 < dt do
			self.currentAlpha = math.max(0, self.currentAlpha - math.min(frame, dt) / self.turnOffFadeTime)
			local rot = self.currentAlpha * math.min(frame, dt) * self.rotSpeed * speedFactor
			self.currentRot = (self.currentRot + rot) % 6.283185307179586
			dt = dt - 16.66667
			if self.currentAlpha ~= 0 then
				continue
			end
		end
	end
end
function RotationAnimation:isRunning()
	return self.state ~= RotationAnimation.STATE_OFF
end
function RotationAnimation:start()
	if self.state ~= RotationAnimation.STATE_ON then
		if self.state == RotationAnimation.STATE_OFF and (self.turnOnOffVariance ~= nil and self.currentAlpha == 0) then
			self.turnOnFadeTime = self.initialTurnOnFadeTime + math.random(-self.turnOnOffVariance, self.turnOnOffVariance)
			self.turnOffFadeTime = self.initialTurnOffFadeTime + math.random(-self.turnOnOffVariance, self.turnOnOffVariance)
		end
		self.state = RotationAnimation.STATE_ON
		self:updateDuplicates()
		return true
	else
		return false
	end
end
function RotationAnimation:stop()
	if self.state ~= RotationAnimation.STATE_OFF then
		if 0 < self.minAlphaForTurnOff and self.currentAlpha < self.minAlphaForTurnOff then
			self.delayedTurnOff = true
			self.state = RotationAnimation.STATE_ON
			return true
		end
		self.state = RotationAnimation.STATE_TURNING_OFF
		self:updateDuplicates()
		if self.turnedOffRotation ~= nil then
			local rx, ry, rz = getRotation(self.rootNode)
			local currentRot = rz
			if self.rotAxis == 1 then
				currentRot = rx
			elseif self.rotAxis == 2 then
				currentRot = ry
			end
			local speedFactor = nil
			if self.speedFunc ~= nil then
				speedFactor = self.speedFunc(self.speedFuncTarget, self.speedFuncParam)
			else
				speedFactor = 1
			end
			self.turnOffFadeTime = Animation.calculateTurnOffFadeTime(self.currentAlpha, self.rotSpeed * speedFactor, math.sign(self.rotSpeed), currentRot, self.turnedOffRotation, self.turnOffFadeTimeOrigin, 6.283185307179586, self.turnedOffSubDivisions)
		end
		return true
	else
		return false
	end
end
function RotationAnimation:reset()
	self.currentAlpha = 0
	self.state = RotationAnimation.STATE_OFF
	self:updateDuplicates()
end
function RotationAnimation:isDuplicate(otherAnimation)
	if otherAnimation:isa(RotationAnimation) and (self.parent == otherAnimation.parent and table.size(self.nodes) == table.size(otherAnimation.nodes)) then
		for node, _ in pairs(self.nodes) do
			if otherAnimation.nodes[node] == nil then
				return false
			end
		end
		return true
	end
	return false
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
