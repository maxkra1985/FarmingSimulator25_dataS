-- Local values: ValueDelay_mt
ValueDelay = {}
local ValueDelay_mt = Class(ValueDelay)

-- Upvalues: ValueDelay_mt
-- Local values: self, _
function ValueDelay.new(duration, direction, customMt)
	-- upvalues: (copy) ValueDelay_mt
	local v5_ = customMt or ValueDelay_mt
	local v6_ = setmetatable({}, v5_)
	v6_.duration = duration
	v6_.direction = direction
	v6_.values = {}
	local v7_ = duration / 16.666666666666668
	for _ = 1, math.floor(v7_) + 1 do
		local v8_ = v6_.values
		table.insert(v8_, {
			["value"] = 0,
			["time"] = -1
		})
	end
	v6_.insertIndex = 0
	v6_.maxFrames = #v6_.values
	v6_.isReseted = true
	return v6_
end

-- Local values: valueData, minTime, minSlot, minValue, slotValid, i, readIndex, slotTime, difference, returnValue
function ValueDelay:add(value, dt)
	self.isReseted = false
	if self.maxFrames == 0 then
		return value
	end
	self.insertIndex = self.insertIndex + 1
	if self.insertIndex > self.maxFrames then
		self.insertIndex = 1
	end
	local v11_ = self.values[self.insertIndex]
	v11_.value = value
	v11_.time = g_time
	local v12_ = math.huge
	local v13_ = 0
	local v14_ = false
	local v15_ = 0
	for v16_ = 1, self.maxFrames - 1 do
		local v17_ = self.insertIndex - v16_
		if v17_ <= 0 then
			v17_ = v17_ + self.maxFrames
		end
		local v18_ = self.values[v17_].time
		if v18_ == -1 then
			break
		end
		local v19_ = self.duration - (v11_.time - v18_)
		if v19_ < v12_ and v19_ > 0 then
			v15_ = self.values[v17_].value
			v13_ = v17_
			v12_ = v19_
		elseif v19_ < 0 then
			v14_ = true
			break
		end
		if v16_ == self.maxFrames - 1 then
			v14_ = true
		end
	end
	local v20_ = 0
	if v13_ == 0 then
		v15_ = v20_
	elseif not v14_ then
		v15_ = v20_
	end
	if self.direction ~= nil then
		if self.direction == -1 then
			if v15_ < value then
				return value
			end
		elseif value < v15_ then
			return value
		end
	end
	return v15_
end

-- Local values: i
function ValueDelay:reset()
	if not self.isReseted then
		for v22_ = 1, self.maxFrames do
			self.values[v22_].value = 0
			self.values[v22_].time = -1
		end
		self.isReseted = true
	end
end
