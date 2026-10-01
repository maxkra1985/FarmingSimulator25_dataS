ObjectPool = {}
local ObjectPool_mt = Class(ObjectPool)
function ObjectPool.EMPTY_TABLE_CONSTRUCTOR()
	return {}
end
function ObjectPool_mt.__len(pool)
	return pool:getLength()
end
function ObjectPool.new(objectConstructor, ...)
	local self = setmetatable({}, ObjectPool_mt)
	self.objectConstructor = objectConstructor or ObjectPool.EMPTY_TABLE_CONSTRUCTOR
	self.objectConstructorArguments = table.pack(...)
	self.pool = {}
	self.poolSet = {}
	return self
end
function ObjectPool:getLength()
	return #self.pool
end
function ObjectPool:clear()
	table.clear(self.poolSet)
	table.clear(self.pool)
end
function ObjectPool:getOrCreateNext()
	local instance = table.remove(self.pool)
	if not instance then
		if self.objectConstructor == ObjectPool.EMPTY_TABLE_CONSTRUCTOR then
			instance = self.objectConstructor()
			return instance
		else
			instance = self.objectConstructor(table.unpack(self.objectConstructorArguments, 1, self.objectConstructorArguments.n))
			return instance
		end
	end
	self.poolSet[instance] = nil
	return instance
end
function ObjectPool:returnToPool(instance)
	if instance == nil then
		return false
	elseif self.poolSet[instance] ~= nil then
		return false
	else
		if self.objectConstructor == ObjectPool.EMPTY_TABLE_CONSTRUCTOR then
			table.clear(instance)
		elseif instance.reset ~= nil then
			instance:reset()
		end
		table.insert(self.pool, instance)
		self.poolSet[instance] = instance
		return true
	end
end
