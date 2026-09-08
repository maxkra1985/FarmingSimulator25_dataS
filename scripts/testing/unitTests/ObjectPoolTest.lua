ObjectPoolTest = {}
function ObjectPoolTest.test_constructor()
	Assert.throwsError(function()
		ObjectPool.new(100)
	end)
	local v1_ = ObjectPool.new()
	Assert.areEqual(v1_.objectConstructor, ObjectPool.EMPTY_TABLE_CONSTRUCTOR, "Default object pool constructor was not used!")
end
function ObjectPoolTest.test_length()
	local v2_ = ObjectPool.new()
	local v3_ = {}
	for _ = 1, 20 do
		local v4_ = v2_:getOrCreateNext()
		Assert.isNotNil(v4_, "Object created from pool was nil.")
		table.insert(v3_, v4_)
	end
	for v5_ = 1, 20 do
		v2_:returnToPool((table.remove(v3_)))
		Assert.areEqual(v2_:getLength(), v5_)
	end
end
function ObjectPoolTest.test_duplicates()
	local v6_ = ObjectPool.new()
	local v7_ = v6_:getOrCreateNext()
	Assert.isNotNil(v7_, "Object created from pool was nil.")
	local v8_ = v6_:returnToPool(v7_)
	Assert.isTrue(v8_, "Object could not be added to empty pool.")
	local v9_ = v6_:returnToPool(v7_)
	Assert.isFalse(v9_, "Duplicate object was accepted.")
	local v10_ = v6_:getOrCreateNext()
	Assert.areEqual(v10_, v7_, "Got a different object out of pool than was put in")
	local v11_ = v6_:returnToPool(v10_)
	Assert.isTrue(v11_, "Object could not be re-added to pool.")
end
function ObjectPoolTest.test_addNil()
	local v12_ = ObjectPool.new():returnToPool(nil)
	Assert.isFalse(v12_, "Object pool accepted nil value.")
end
function ObjectPoolTest.test_instanceReset()
	local v13_ = ObjectPool.new()
	local v14_ = v13_:getOrCreateNext()
	v14_.testValue = true
	v13_:returnToPool(v14_)
	local v15_ = v13_:getOrCreateNext()
	Assert.areEqual(v14_, v15_, "Table was not properly pooled, different value was given on second function call!")
	Assert.isNil(v14_.testValue, "Table was not cleared when pooled!")
end
