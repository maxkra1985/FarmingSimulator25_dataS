RingBufferTest = {}
function RingBufferTest.test_incrementIndex()
	local v1_ = RingBuffer.new(10)
	for _ = 1, v1_.size * 3 do
		Assert.isBetween(v1_.index, 1, v1_.size, nil, nil, "Increment function caused index to go out of bounds!")
		v1_:incrementIndex()
	end
end
function RingBufferTest.test_calculateIndex()
	local v2_ = RingBuffer.new(10)
	for v3_ = 1, v2_.size * 3 do
		local v4_ = (v3_ - 1) % v2_.size + 1
		local v5_ = v2_:calculateIndex(v3_)
		Assert.areEqual(v5_, v4_, "Index did not increment as expected!")
		Assert.isBetween(v5_, 1, v2_.size, nil, nil, "Calculated index was out of bounds!")
	end
	for v6_ = 1, v2_.size * 3 do
		local v7_ = (v6_ - 1) % v2_.size + 1
		local v8_ = v2_:calculateIndex(1)
		Assert.areEqual(v8_, v7_, "Buffer index did not increment as expected!")
		Assert.isBetween(v8_, 1, v2_.size, nil, nil, "Calculated index was out of bounds!")
		v2_:incrementIndex()
	end
	local v9_ = v2_.size
	for v10_ = 0, -v2_.size + 1, -1 do
		local v11_ = v2_:calculateIndex(v10_)
		Assert.areEqual(v11_, v9_, "Buffer index did not decrement as expected!")
		Assert.isBetween(v11_, 1, v2_.size, nil, nil, "Calculated index was out of bounds!")
		v9_ = v9_ - 1
	end
end
