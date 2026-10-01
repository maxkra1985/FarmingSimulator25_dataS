RotationAnimationSpikesGravity = {}
local RotationAnimationSpikesGravity_mt = Class(RotationAnimationSpikesGravity, RotationAnimation)
function RotationAnimationSpikesGravity.new(customMt)
	return RotationAnimation.new(customMt or RotationAnimationSpikesGravity_mt)
end
function RotationAnimationSpikesGravity:load(xmlFile, key, rootNodes, owner, i3dMapping)
	if RotationAnimationSpikesGravity:superClass().load(self, xmlFile, key, rootNodes, owner, i3dMapping) == nil then
		return nil
	elseif table.size(self.nodes) ~= 1 then
		Logging.xmlWarning(xmlFile, "RotationAnimationSpikesGravity does only support one link node in '%s'", key)
		return nil
	else
		self.minSpikeRot = xmlFile:getValue(key .. ".spikes#minRot", -10)
		self.maxSpikeRot = xmlFile:getValue(key .. ".spikes#maxRot", 10)
		self.spikeRotAxis = xmlFile:getValue(key .. ".spikes#rotAxis", 1)
		self.gravityFactor = xmlFile:getValue(key .. ".spikes#gravityFactor", 1) * 2 * 3.141592653589793 / 1000
		self.spikes = {}
		xmlFile:iterate(key .. ".spikes.spike", function(index, spikeKey)
			local spike = {}
			spike.node = xmlFile:getValue(spikeKey .. "#node", nil, rootNodes, i3dMapping)
			if spike.node ~= nil then
				spike.initialRot = { getRotation(spike.node) }
				spike.rotation = { getRotation(spike.node) }
				spike.minRot = spike.initialRot[self.spikeRotAxis] + self.minSpikeRot
				spike.maxRot = spike.initialRot[self.spikeRotAxis] + self.maxSpikeRot
				spike.curRot = 0
				spike.targetRot = 0
				spike.lastSignedSpeed = 1
				table.insert(self.spikes, spike)
			end
		end)
		if self.rotSpeed < 0 then
			self.lastRot = self.currentRot + 1
		else
			self.lastRot = self.currentRot + 1
		end
		self.activeDirtyTime = 0
		self:updateSpikes(9999)
		return self
	end
end
function RotationAnimationSpikesGravity:update(dt)
	RotationAnimationSpikesGravity:superClass().update(self, dt)
	if 0 < self.currentAlpha then
		self.activeDirtyTime = 1000
	end
	if 0 < self.activeDirtyTime then
		self.activeDirtyTime = self.activeDirtyTime - dt
		self:updateSpikes(dt)
	end
end
function RotationAnimationSpikesGravity:isRunning()
	if RotationAnimationSpikesGravity:superClass().isRunning(self) then
		return true
	else
		local isActive = false
		for i = 1, #self.spikes do
			local spike = self.spikes[i]
			if 0.00001 < math.abs(spike.targetRot - spike.curRot) then
				isActive = true
				return isActive
			end
		end
		return isActive
	end
end
function RotationAnimationSpikesGravity:updateSpikes(dt)
	local speed = self.currentRot - self.lastRot
	if 3.141592653589793 < speed then
		speed = speed - 6.283185307179586
	elseif speed < -3.141592653589793 then
		speed = speed + 6.283185307179586
	end
	local signedSpeed = math.sign(speed)
	self.lastRot = self.currentRot
	local speedScale = (math.clamp(math.abs(speed) / dt * 100, 0.1, 1) - 0.1) / 0.9
	for i = 1, #self.spikes do
		local spike = self.spikes[i]
		if signedSpeed ~= 0 then
			if signedSpeed ~= spike.lastSignedSpeed then
				spike.lastSignedSpeed = signedSpeed
			end
		else
			signedSpeed = spike.lastSignedSpeed
		end
		local limitedTargetRot = 0
		if speedScale < 1 then
			local rootRot = self.currentRot
			if 3.141592653589793 < rootRot then
				rootRot = rootRot - 6.283185307179586
			end
			local targetRotReal = 3.141592653589793 - rootRot
			if MathUtil.getIsOutOfBounds(targetRotReal, spike.minRot, spike.maxRot) then
				if not MathUtil.getIsOutOfBounds(targetRotReal + 6.283185307179586, spike.minRot, spike.maxRot) then
					targetRotReal = targetRotReal + 6.283185307179586
				end
				if not MathUtil.getIsOutOfBounds(targetRotReal - 6.283185307179586, spike.minRot, spike.maxRot) then
					targetRotReal = targetRotReal - 6.283185307179586
				end
			end
			if 0 < signedSpeed and (MathUtil.getIsOutOfBounds(targetRotReal, spike.minRot, spike.maxRot) and spike.maxRot < targetRotReal) then
				targetRotReal = spike.minRot
			end
			limitedTargetRot = math.clamp(targetRotReal, spike.minRot, spike.maxRot)
		end
		spike.targetRot = limitedTargetRot * (1 - speedScale) + spike.initialRot[self.spikeRotAxis] * speedScale
		local direction = math.sign(spike.targetRot - spike.curRot)
		local limit = 0 < direction and math.min or math.max
		spike.curRot = limit(spike.curRot + direction * self.gravityFactor * dt, spike.targetRot)
		spike.rotation[self.spikeRotAxis] = spike.curRot
		setRotation(spike.node, spike.rotation[1], spike.rotation[2], spike.rotation[3])
	end
end
function RotationAnimationSpikesGravity.registerAnimationClassXMLPaths(schema, basePath)
	schema:register(XMLValueType.INT, basePath .. ".spikes#rotAxis", "(RotationAnimationSpikes) Rotation axis", 3)
	schema:register(XMLValueType.ANGLE, basePath .. ".spikes#minRot", "(RotationAnimationSpikes) Min. spike rotation")
	schema:register(XMLValueType.ANGLE, basePath .. ".spikes#maxRot", "(RotationAnimationSpikes) Max. spike rotation")
	schema:register(XMLValueType.FLOAT, basePath .. ".spikes#gravityFactor", "(RotationAnimationSpikesGravity) Factor to adjust how fast the spike adjusts and falls down")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".spikes.spike(?)#node", "(RotationAnimationSpikes) Spike node")
end
