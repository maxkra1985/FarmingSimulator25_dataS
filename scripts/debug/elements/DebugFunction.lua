-- Local values: DebugFunction_mt
DebugFunction = {}
local DebugFunction_mt = Class(DebugFunction)

-- Upvalues: DebugFunction_mt
-- Local values: self
function DebugFunction.new(updateFunc, drawFunc, initFunc, deleteFunc, customMt)
	-- upvalues: (copy) DebugFunction_mt
	local v7_ = customMt or DebugFunction_mt
	local v8_ = setmetatable({}, v7_)
	v8_.updateFunc = updateFunc
	v8_.drawFunc = drawFunc
	v8_.deleteFunc = deleteFunc
	if initFunc ~= nil then
		initFunc(v8_)
	end
	return v8_
end

function DebugFunction:delete()
	if self.deleteFunc ~= nil then
		self.deleteFunc(self)
	end
end

function DebugFunction:update(dt)
	if self.updateFunc ~= nil then
		self.updateFunc(self, dt)
	end
end

function DebugFunction:getShouldBeDrawn()
	return true
end

function DebugFunction:draw()
	if self.drawFunc ~= nil then
		self.drawFunc(self)
	end
end
