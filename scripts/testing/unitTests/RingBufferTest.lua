RingBufferTest = {}
function RingBufferTest.test_incrementIndex()
	local buffer = RingBuffer.new(10)
	for i = 1, buffer.size * 3 do
		Assert.isBetween(buffer.index, 1, buffer.size, nil, nil, "Increment function caused index to go out of bounds!")
		buffer:incrementIndex()
	end
end
function RingBufferTest.test_calculateIndex()
	local buffer = RingBuffer.new(10)
	for i = 1, buffer.size * 3 do
		local expectedIndex = (i - 1) % buffer.size + 1
		local index = buffer:calculateIndex(i)
		Assert.areEqual(index, expectedIndex, "Index did not increment as expected!")
		Assert.isBetween(index, 1, buffer.size, nil, nil, "Calculated index was out of bounds!")
	end
	for i = 1, buffer.size * 3 do
		local expectedIndex = (i - 1) % buffer.size + 1
		local index = buffer:calculateIndex(1)
		Assert.areEqual(index, expectedIndex, "Buffer index did not increment as expected!")
		Assert.isBetween(index, 1, buffer.size, nil, nil, "Calculated index was out of bounds!")
		buffer:incrementIndex()
	end
	local expectedIndex = buffer.size
	for i = 0, -buffer.size + 1, -1 do
		local index = buffer:calculateIndex(i)
		Assert.areEqual(index, expectedIndex, "Buffer index did not decrement as expected!")
		Assert.isBetween(index, 1, buffer.size, nil, nil, "Calculated index was out of bounds!")
		expectedIndex = expectedIndex - 1
	end
end
