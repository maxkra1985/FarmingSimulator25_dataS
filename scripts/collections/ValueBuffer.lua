-- Local values: ValueBuffer_mt
ValueBuffer = {}
local ValueBuffer_mt = Class(ValueBuffer)

-- Upvalues: ValueBuffer_mt
-- Local values: self
function ValueBuffer.new(duration, customMt)
	-- upvalues: (copy) ValueBuffer_mt
	local v4_ = customMt or ValueBuffer_mt
	local v5_ = setmetatable({}, v4_)
	v5_.duration = duration
	v5_.index = 1
	v5_.values = {}
	v5_.time = 0
	return v5_
end

-- Local values: i
function ValueBuffer:add(value)
	self.values[self.index] = value
	self.index = self.index + 1
	if g_time - self.time > self.duration then
		if #self.values > self.index then
			for v8_ = #self.values, self.index, -1 do
				table.remove(self.values, v8_)
			end
		end
		self.time = g_time
		self.index = 1
	end
end

-- Local values: value, _, sValue
function ValueBuffer:get(duration)
	local v11_ = 0
	for _, v12_ in ipairs(self.values) do
		v11_ = v11_ + v12_
	end
	return v11_ * ((duration or self.duration) / self.duration)
end

-- Local values: value, _, sValue
function ValueBuffer:getAverage()
	local v14_ = 0
	for _, v15_ in ipairs(self.values) do
		v14_ = v14_ + v15_
	end
	return v14_ / #self.values
end
