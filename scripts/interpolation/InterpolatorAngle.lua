-- Local values: InterpolatorAngle_mt
InterpolatorAngle = {}
local InterpolatorAngle_mt = Class(InterpolatorAngle)

-- Upvalues: InterpolatorAngle_mt
-- Local values: self
function InterpolatorAngle.new(value, customMt)
	-- upvalues: (copy) InterpolatorAngle_mt
	local v4_ = customMt or InterpolatorAngle_mt
	local v5_ = setmetatable({}, v4_)
	v5_.value = value
	v5_.lastValue = value
	v5_.targetValue = value
	return v5_
end

function InterpolatorAngle:setAngle(value)
	self.value = value
	self.lastValue = value
	self.targetValue = value
end

function InterpolatorAngle:setTargetAngle(targetValue)
	local v10_ = self:clampValue(targetValue)
	self.targetValue = v10_
	self.lastValue = self.value
	if v10_ - self.value > 3.141592653589793 then
		self.lastValue = self.value + 6.283185307179586
	elseif v10_ - self.value < -3.141592653589793 then
		self.lastValue = self.value - 6.283185307179586
	end
end

function InterpolatorAngle:getInterpolatedValue(interpolationAlpha)
	self.value = self.lastValue + interpolationAlpha * (self.targetValue - self.lastValue)
	self.value = self:clampValue(self.value)
	if self.value == self.min or self.value == self.max then
		self:setAngle(self.value)
	end
	return self.value
end

function InterpolatorAngle:clampValue(value)
	if self.min ~= nil then
		local v15_ = self.min
		value = math.max(value, v15_)
	end
	if self.max ~= nil then
		local v16_ = self.max
		value = math.min(value, v16_)
	end
	return value
end

function InterpolatorAngle:setMinMax(min, max)
	self.min = Utils.getNoNil(min, self.min)
	self.max = Utils.getNoNil(max, self.max)
end
