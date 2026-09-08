-- Local values: ObjectPool_mt
ObjectPool = {}
local ObjectPool_mt = Class(ObjectPool)
function ObjectPool.EMPTY_TABLE_CONSTRUCTOR()
	return {}
end

function ObjectPool_mt.__len(pool)
	return pool:getLength()
end
function ObjectPool.new(p3_, ...)
	-- upvalues: (copy) ObjectPool_mt
	local v4_ = ObjectPool_mt
	local v5_ = setmetatable({}, v4_)
	v5_.objectConstructor = p3_ or ObjectPool.EMPTY_TABLE_CONSTRUCTOR
	v5_.objectConstructorArguments = table.pack(...)
	v5_.pool = {}
	v5_.poolSet = {}
	return v5_
end

function ObjectPool:getLength()
	return #self.pool
end

function ObjectPool:clear()
	table.clear(self.poolSet)
	table.clear(self.pool)
end

-- Local values: instance
function ObjectPool:getOrCreateNext()
	local v9_ = table.remove(self.pool)
	if v9_ then
		self.poolSet[v9_] = nil
		return v9_
	end
	if self.objectConstructor == ObjectPool.EMPTY_TABLE_CONSTRUCTOR then
		return self.objectConstructor()
	end
	local v10_ = self.objectConstructor
	local v11_ = self.objectConstructorArguments
	local v12_ = self.objectConstructorArguments.n
	return v10_(table.unpack(v11_, 1, v12_))
end

function ObjectPool:returnToPool(instance)
	if instance == nil then
		return false
	end
	if self.poolSet[instance] ~= nil then
		return false
	end
	if self.objectConstructor == ObjectPool.EMPTY_TABLE_CONSTRUCTOR then
		table.clear(instance)
	elseif instance.reset ~= nil then
		instance:reset()
	end
	local v15_ = self.pool
	table.insert(v15_, instance)
	self.poolSet[instance] = instance
	return true
end
