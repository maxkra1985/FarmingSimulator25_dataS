-- Local values: InterpolationTime_mt
InterpolationTime = {}
local InterpolationTime_mt = Class(InterpolationTime)

-- Upvalues: InterpolationTime_mt
-- Local values: self
function InterpolationTime.new(maxInterpolationAlpha, customMt)
	-- upvalues: (copy) InterpolationTime_mt
	local v4_ = customMt or InterpolationTime_mt
	local v5_ = setmetatable({}, v4_)
	v5_.maxInterpolationAlpha = maxInterpolationAlpha
	v5_.interpolationAlpha = maxInterpolationAlpha
	v5_.interpolationDuration = 80
	v5_.isDirty = false
	v5_.lastPhysicsNetworkTime = nil
	return v5_
end

function InterpolationTime:startNewPhase(interpolationDuration)
	self.interpolationDuration = interpolationDuration
	self.interpolationAlpha = 0
	self.isDirty = true
end

-- Local values: deltaTime, interpTimeLeft
function InterpolationTime:startNewPhaseNetwork()
	local v9_ = g_client.tickDuration
	if self.lastPhysicsNetworkTime ~= nil then
		local v10_ = g_packetPhysicsNetworkTime - self.lastPhysicsNetworkTime
		local v11_ = 3 * g_client.tickDuration
		v9_ = math.min(v10_, v11_)
	end
	self.lastPhysicsNetworkTime = g_packetPhysicsNetworkTime
	local v12_ = g_clientInterpDelay
	if self.interpolationAlpha < 1 then
		local v13_ = (1 - self.interpolationAlpha) * self.interpolationDuration * 0.95 + g_clientInterpDelay * 0.05
		local v14_ = 3 * g_clientInterpDelay
		v12_ = math.min(v13_, v14_)
	end
	self.interpolationDuration = v12_ + v9_
	self.interpolationAlpha = 0
	self.isDirty = true
end

function InterpolationTime:reset()
	self.interpolationAlpha = self.maxInterpolationAlpha
	self.isDirty = false
end

-- Local values: interpolationAlpha
function InterpolationTime:update(dt)
	local v18_ = self.interpolationAlpha + dt / self.interpolationDuration
	if self.maxInterpolationAlpha <= v18_ then
		v18_ = self.maxInterpolationAlpha
		self.isDirty = false
	end
	self.interpolationAlpha = v18_
end

function InterpolationTime:getAlpha()
	return self.interpolationAlpha
end

function InterpolationTime:isInterpolating()
	return self.interpolationAlpha < self.maxInterpolationAlpha
end
