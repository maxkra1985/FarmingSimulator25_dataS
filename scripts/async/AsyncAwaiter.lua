-- Local values: AsyncAwaiter_mt
AsyncAwaiter = {}
local AsyncAwaiter_mt = Class(AsyncAwaiter)

-- Upvalues: AsyncAwaiter_mt
-- Local values: self
function AsyncAwaiter.new(targetFunction)
	-- upvalues: (copy) AsyncAwaiter_mt
	local v3_ = AsyncAwaiter_mt
	local v4_ = setmetatable({}, v3_)
	v4_.targetFunction = targetFunction
	v4_.dependencies = {}
	v4_.dependenciesCount = 0
	return v4_
end

function AsyncAwaiter:getDependenciesCount()
	return self.dependenciesCount
end

function AsyncAwaiter:addDependency(dependency)
	if dependency == nil or self.dependencies[dependency] ~= nil then
		return false
	end
	self.dependencies[dependency] = dependency
	self.dependenciesCount = self.dependenciesCount + 1
	return true
end

-- Local values: _, dependency
function AsyncAwaiter:addDependencies(dependencies)
	for _, v10_ in pairs(dependencies) do
		self:addDependency(v10_)
	end
end

-- Local values: shouldExecute
function AsyncAwaiter:onDependencyAvailable(dependency)
	if self.dependencies[dependency] == nil then
		return false
	end
	self.dependencies[dependency] = nil
	self.dependenciesCount = self.dependenciesCount - 1
	local v13_ = self.dependenciesCount <= 0
	if v13_ then
		self.targetFunction()
	end
	return v13_
end

function AsyncAwaiter:cancel()
	self:reset()
end

function AsyncAwaiter:reset()
	table.clear(self.dependencies)
	self.dependenciesCount = 0
	self.targetFunction = nil
end
