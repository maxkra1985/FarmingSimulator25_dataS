RingBuffer = {}
local RingBuffer_mt = Class(RingBuffer)
function RingBuffer.new(size, customMt)
	local self = setmetatable({}, customMt or RingBuffer_mt)
	self.size = size
	self.index = 1
	self.values = table.create(size)
	self.values[1] = 0
	return self
end
function RingBuffer:add(value)
	self.values[self.index] = value
	self:incrementIndex()
end
function RingBuffer:incrementIndex()
	self.index = self.index + 1
	if self.size < self.index then
		self.index = 1
	end
end
function RingBuffer:calculateIndex(localIndex)
	local index = self.index + (localIndex - 1)
	if index <= self.size and 0 < index then
		return index
	end
	return (index - 1) % self.size + 1
end
function RingBuffer:getLocallyIndexed(localIndex)
	local absoluteIndex = self:calculateIndex(localIndex)
	return self:getAbsolutelyIndexed(absoluteIndex)
end
function RingBuffer:getAbsolutelyIndexed(absoluteIndex)
	return self.values[absoluteIndex]
end
function RingBuffer:getAverage()
	local sum = 0
	for _, value in ipairs(self.values) do
		sum = sum + value
	end
	return sum / #self.values
end
