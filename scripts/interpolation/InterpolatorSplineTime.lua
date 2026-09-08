-- Local values: InterpolatorSplineTime_mt
InterpolatorSplineTime = {}
local InterpolatorSplineTime_mt = Class(InterpolatorSplineTime)

-- Upvalues: InterpolatorSplineTime_mt
-- Local values: self
function InterpolatorSplineTime.new(value, isLooping, customMt)
	-- upvalues: (copy) InterpolatorSplineTime_mt
	local v5_ = customMt or InterpolatorSplineTime_mt
	local v6_ = setmetatable({}, v5_)
	v6_.value = value
	v6_.lastValue = value
	v6_.targetValue = value
	v6_.isLooping = isLooping
	if not isLooping then
		v6_.min = 0
		v6_.max = 1
	end
	return v6_
end

function InterpolatorSplineTime:setValue(value)
	self.value = value
	self.lastValue = value
	self.targetValue = value
end

function InterpolatorSplineTime:setTargetValue(value, direction)
	if self.isLooping then
		if direction == 1 then
			if value < self.lastValue then
				self.lastValue = self.lastValue - 1
			end
		elseif self.lastValue < value then
			self.lastValue = self.lastValue + 1
		end
	end
	self.targetValue = self:clampValue(value)
	self.lastValue = self.value
end

function InterpolatorSplineTime:getInterpolatedValue(interpolationAlpha)
	self.value = self.lastValue + interpolationAlpha * (self.targetValue - self.lastValue)
	self.value = self:clampValue(self.value)
	if self.value == self.min or self.value == self.max then
		self:setValue(self.value)
	end
	if self.isLooping then
		return self.value % 1
	else
		return self.value
	end
end

function InterpolatorSplineTime:clampValue(value)
	if self.min ~= nil then
		local v16_ = self.min
		value = math.max(value, v16_)
	end
	if self.max ~= nil then
		local v17_ = self.max
		value = math.min(value, v17_)
	end
	return value
end
