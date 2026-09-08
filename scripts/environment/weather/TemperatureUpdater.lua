-- Local values: TemperatureUpdater_mt
TemperatureUpdater = {}
local TemperatureUpdater_mt = Class(TemperatureUpdater)

-- Upvalues: TemperatureUpdater_mt
-- Local values: self
function TemperatureUpdater.new(customMt)
	-- upvalues: (copy) TemperatureUpdater_mt
	local v3_ = customMt or TemperatureUpdater_mt
	local v4_ = setmetatable({}, v3_)
	v4_.dayLength = 1
	v4_.isDirty = false
	v4_.currentMin = 15
	v4_.currentMax = 20
	v4_.targetMin = 15
	v4_.targetMax = 20
	v4_.changeDuration = 3600000
	return v4_
end

function TemperatureUpdater:delete() end

-- Local values: change
function TemperatureUpdater:update(dt)
	if self.isDirty then
		local v7_ = dt / self.changeDuration
		if self.currentMax < self.targetMax then
			local v8_ = self.currentMax + v7_
			local v9_ = self.targetMax
			self.currentMax = math.min(v8_, v9_)
		else
			local v10_ = self.currentMax - v7_
			local v11_ = self.targetMax
			self.currentMax = math.max(v10_, v11_)
		end
		if self.currentMin < self.targetMin then
			local v12_ = self.currentMin + v7_
			local v13_ = self.targetMin
			self.currentMin = math.min(v12_, v13_)
		else
			local v14_ = self.currentMin - v7_
			local v15_ = self.targetMin
			self.currentMin = math.max(v14_, v15_)
		end
		self.isDirty = self.currentMin ~= self.targetMin and true or self.currentMax ~= self.targetMax
	end
end

function TemperatureUpdater:setDayLength(dayLength)
	self.dayLength = dayLength
end

function TemperatureUpdater:getCurrentValues()
	return self.currentMin, self.currentMax
end

function TemperatureUpdater:setTargetValues(targetMin, targetMax, immediate)
	self.isDirty = not immediate
	self.targetMin = targetMin
	self.targetMax = targetMax
	if immediate then
		self.currentMin = targetMin
		self.currentMax = targetMax
	end
end

-- Local values: normalizedDayTime, deltaTemperature, deltaTemperatureHalf, x, temperature
function TemperatureUpdater:getTemperatureAtTime(dayTime)
	local v25_ = dayTime / self.dayLength
	local v26_ = 0.5 * (self.currentMax - self.currentMin)
	local v27_ = 6.283185307179586 * v25_ - 2.5
	return v26_ * math.sin(v27_) + self.currentMin + v26_
end
