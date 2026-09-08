-- Local values: RotationAnimationSpikesGravity_mt
RotationAnimationSpikesGravity = {}
local RotationAnimationSpikesGravity_mt = Class(RotationAnimationSpikesGravity, RotationAnimation)

-- Upvalues: RotationAnimationSpikesGravity_mt
function RotationAnimationSpikesGravity.new(customMt)
	-- upvalues: (copy) RotationAnimationSpikesGravity_mt
	return RotationAnimation.new(customMt or RotationAnimationSpikesGravity_mt)
end

function RotationAnimationSpikesGravity:load(xmlFile, key, rootNodes, owner, i3dMapping)
	if RotationAnimationSpikesGravity:superClass().load(self, xmlFile, key, rootNodes, owner, i3dMapping) == nil then
		return nil
	end
	if table.size(self.nodes) ~= 1 then
		Logging.xmlWarning(xmlFile, "RotationAnimationSpikesGravity does only support one link node in \'%s\'", key)
		return nil
	end
	self.minSpikeRot = xmlFile:getValue(key .. ".spikes#minRot", -10)
	self.maxSpikeRot = xmlFile:getValue(key .. ".spikes#maxRot", 10)
	self.spikeRotAxis = xmlFile:getValue(key .. ".spikes#rotAxis", 1)
	self.gravityFactor = xmlFile:getValue(key .. ".spikes#gravityFactor", 1) * 2 * 3.141592653589793 / 1000
	self.spikes = {}
	xmlFile:iterate(key .. ".spikes.spike", function(_, p9_)
		-- upvalues: (copy) xmlFile, (copy) rootNodes, (copy) i3dMapping, (copy) self
		local v10_ = {
			["node"] = xmlFile:getValue(p9_ .. "#node", nil, rootNodes, i3dMapping)
		}
		if v10_.node ~= nil then
			v10_.initialRot = { getRotation(v10_.node) }
			v10_.rotation = { getRotation(v10_.node) }
			local v11_ = v10_.initialRot[self.spikeRotAxis] + self.minSpikeRot
			local v12_ = v10_.initialRot[self.spikeRotAxis] + self.maxSpikeRot
			v10_.minRot = v11_
			v10_.maxRot = v12_
			v10_.curRot = 0
			v10_.targetRot = 0
			v10_.lastSignedSpeed = 1
			local v13_ = self.spikes
			table.insert(v13_, v10_)
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

function RotationAnimationSpikesGravity:update(dt)
	RotationAnimationSpikesGravity:superClass().update(self, dt)
	if self.currentAlpha > 0 then
		self.activeDirtyTime = 1000
	end
	if self.activeDirtyTime > 0 then
		self.activeDirtyTime = self.activeDirtyTime - dt
		self:updateSpikes(dt)
	end
end

-- Local values: isActive, i, spike
function RotationAnimationSpikesGravity:isRunning()
	if RotationAnimationSpikesGravity:superClass().isRunning(self) then
		return true
	end
	local v17_ = false
	for v18_ = 1, #self.spikes do
		local v19_ = self.spikes[v18_]
		local v20_ = v19_.targetRot - v19_.curRot
		if math.abs(v20_) > 0.00001 then
			return true
		end
	end
	return v17_
end

-- Local values: speed, signedSpeed, speedScale, i, spike, limitedTargetRot, rootRot, targetRotReal, direction, limit
function RotationAnimationSpikesGravity:updateSpikes(dt)
	local v23_ = self.currentRot - self.lastRot
	if v23_ > 3.141592653589793 then
		v23_ = v23_ - 6.283185307179586
	elseif v23_ < -3.141592653589793 then
		v23_ = v23_ + 6.283185307179586
	end
	local v24_ = math.sign(v23_)
	self.lastRot = self.currentRot
	local v25_ = math.abs(v23_) / dt * 100
	local v26_ = (math.clamp(v25_, 0.1, 1) - 0.1) / 0.9
	for v27_ = 1, #self.spikes do
		local v28_ = self.spikes[v27_]
		if v24_ == 0 then
			v24_ = v28_.lastSignedSpeed
		elseif v24_ ~= v28_.lastSignedSpeed then
			v28_.lastSignedSpeed = v24_
		end
		local v29_
		if v26_ < 1 then
			local v30_ = self.currentRot
			if v30_ > 3.141592653589793 then
				v30_ = v30_ - 6.283185307179586
			end
			local v31_ = 3.141592653589793 - v30_
			if MathUtil.getIsOutOfBounds(v31_, v28_.minRot, v28_.maxRot) then
				if not MathUtil.getIsOutOfBounds(v31_ + 6.283185307179586, v28_.minRot, v28_.maxRot) then
					v31_ = v31_ + 6.283185307179586
				end
				if not MathUtil.getIsOutOfBounds(v31_ - 6.283185307179586, v28_.minRot, v28_.maxRot) then
					v31_ = v31_ - 6.283185307179586
				end
			end
			if v24_ > 0 and (MathUtil.getIsOutOfBounds(v31_, v28_.minRot, v28_.maxRot) and v28_.maxRot < v31_) then
				v31_ = v28_.minRot
			end
			local v32_ = v28_.minRot
			local v33_ = v28_.maxRot
			v29_ = math.clamp(v31_, v32_, v33_)
		else
			v29_ = 0
		end
		v28_.targetRot = v29_ * (1 - v26_) + v28_.initialRot[self.spikeRotAxis] * v26_
		local v34_ = v28_.targetRot - v28_.curRot
		local v35_ = math.sign(v34_)
		v28_.curRot = (v35_ > 0 and math.min or math.max)(v28_.curRot + v35_ * self.gravityFactor * dt, v28_.targetRot)
		v28_.rotation[self.spikeRotAxis] = v28_.curRot
		setRotation(v28_.node, v28_.rotation[1], v28_.rotation[2], v28_.rotation[3])
	end
end

function RotationAnimationSpikesGravity.registerAnimationClassXMLPaths(schema, basePath)
	schema:register(XMLValueType.INT, basePath .. ".spikes#rotAxis", "(RotationAnimationSpikes) Rotation axis", 3)
	schema:register(XMLValueType.ANGLE, basePath .. ".spikes#minRot", "(RotationAnimationSpikes) Min. spike rotation")
	schema:register(XMLValueType.ANGLE, basePath .. ".spikes#maxRot", "(RotationAnimationSpikes) Max. spike rotation")
	schema:register(XMLValueType.FLOAT, basePath .. ".spikes#gravityFactor", "(RotationAnimationSpikesGravity) Factor to adjust how fast the spike adjusts and falls down")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".spikes.spike(?)#node", "(RotationAnimationSpikes) Spike node")
end
