-- Local values: UsageBuffer_mt
UsageBuffer = {}
local UsageBuffer_mt = Class(UsageBuffer)

-- Upvalues: UsageBuffer_mt
-- Local values: self
function UsageBuffer.new(duration, resolution, numBits)
	-- upvalues: (copy) UsageBuffer_mt
	local v4_ = UsageBuffer_mt
	local v5_ = setmetatable({}, v4_)
	v5_.time = 0
	v5_.valueSum = 0
	v5_.numValues = 0
	v5_.lastValue = 0
	v5_.lastAddedValue = 0
	v5_.duration = duration
	v5_.lastValueSent = 0
	v5_.numBits = numBits or 8
	v5_.maxValue = 2 ^ v5_.numBits - 1
	v5_.isDirty = false
	return v5_
end

function UsageBuffer:add(value, skipBuffer, setDirty)
	if g_server ~= nil then
		if value == nil then
			value = self.lastAddedValue
		end
		self.lastAddedValue = value
		if skipBuffer then
			self.lastValue = value
			self.time = 0
			self.valueSum = 0
			self.numValues = 0
			if setDirty then
				self.isDirty = true
				return
			end
		else
			self.valueSum = self.valueSum + value
			self.numValues = self.numValues + 1
		end
	end
end

function UsageBuffer:update(dt)
	if g_server ~= nil then
		self.time = self.time + dt
		if self.time > self.duration then
			if self.numValues > 0 then
				self.lastValue = self.valueSum / self.numValues
			else
				self.lastValue = 0
			end
			if self.lastValueSent ~= self.lastValue then
				self.isDirty = true
			end
			self.time = 0
			self.valueSum = 0
			self.numValues = 0
		end
	end
end

function UsageBuffer:get()
	return self.lastValue
end

function UsageBuffer:getLastAdded()
	return self.lastAddedValue
end

function UsageBuffer:reset()
	self.time = 0
	self.valueSum = 0
	self.numValues = 0
	self.lastValue = 0
	self.lastAddedValue = 0
end

function UsageBuffer:readStream(streamId, connection)
	self.lastValue = streamReadUIntN(streamId, self.numBits)
	self.lastAddedValue = self.lastValue
end

function UsageBuffer:writeStream(streamId, connection)
	local v19_ = streamWriteUIntN
	local v20_ = self.lastValue
	local v21_ = self.maxValue
	v19_(streamId, math.clamp(v20_, 0, v21_), self.numBits)
end

function UsageBuffer:resetDirtyState()
	self.lastValueSent = self.lastValue
	self.isDirty = false
end

function UsageBuffer:getIsDirty()
	return self.isDirty
end
