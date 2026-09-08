-- Local values: InterpolatorValue_mt
InterpolatorValue = {}
local InterpolatorValue_mt = Class(InterpolatorValue)

-- Upvalues: InterpolatorValue_mt
-- Local values: self
function InterpolatorValue.new(value, customMt)
	-- upvalues: (copy) InterpolatorValue_mt
	local v4_ = customMt or InterpolatorValue_mt
	local v5_ = setmetatable({}, v4_)
	v5_.value = value
	v5_.lastValue = value
	v5_.targetValue = value
	return v5_
end

function InterpolatorValue:setValue(value)
	self.value = value
	self.lastValue = value
	self.targetValue = value
end

function InterpolatorValue:setTargetValue(value)
	self.targetValue = self:clampValue(value)
	self.lastValue = self.value
end

function InterpolatorValue:getInterpolatedValue(interpolationAlpha)
	self.value = self.lastValue + interpolationAlpha * (self.targetValue - self.lastValue)
	self.value = self:clampValue(self.value)
	if self.value == self.min or self.value == self.max then
		self:setValue(self.value)
	end
	return self.value
end

function InterpolatorValue:clampValue(value)
	if self.min ~= nil then
		local v14_ = self.min
		value = math.max(value, v14_)
	end
	if self.max ~= nil then
		local v15_ = self.max
		value = math.min(value, v15_)
	end
	return value
end

function InterpolatorValue:setMinMax(min, max)
	self.min = Utils.getNoNil(min, self.min)
	self.max = Utils.getNoNil(max, self.max)
end
