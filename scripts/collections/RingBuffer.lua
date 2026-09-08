-- Local values: RingBuffer_mt
RingBuffer = {}
local RingBuffer_mt = Class(RingBuffer)

-- Upvalues: RingBuffer_mt
-- Local values: self
function RingBuffer.new(size, customMt)
	-- upvalues: (copy) RingBuffer_mt
	local v4_ = customMt or RingBuffer_mt
	local v5_ = setmetatable({}, v4_)
	v5_.size = size
	v5_.index = 1
	v5_.values = table.create(size)
	v5_.values[1] = 0
	return v5_
end

function RingBuffer:add(value)
	self.values[self.index] = value
	self:incrementIndex()
end

function RingBuffer:incrementIndex()
	self.index = self.index + 1
	if self.index > self.size then
		self.index = 1
	end
end

-- Local values: index
function RingBuffer:calculateIndex(localIndex)
	local v11_ = self.index + (localIndex - 1)
	if v11_ <= self.size and v11_ > 0 then
		return v11_
	else
		return (v11_ - 1) % self.size + 1
	end
end

-- Local values: absoluteIndex
function RingBuffer:getLocallyIndexed(localIndex)
	return self:getAbsolutelyIndexed((self:calculateIndex(localIndex)))
end

function RingBuffer:getAbsolutelyIndexed(absoluteIndex)
	return self.values[absoluteIndex]
end

-- Local values: sum, _, value
function RingBuffer:getAverage()
	local v17_ = 0
	for _, v18_ in ipairs(self.values) do
		v17_ = v17_ + v18_
	end
	return v17_ / #self.values
end
