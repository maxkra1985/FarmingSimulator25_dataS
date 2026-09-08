-- Local values: WindUpdater_mt
WindUpdater = {}
WindUpdater.MAX_SPEED = 42
local WindUpdater_mt = Class(WindUpdater)

-- Upvalues: WindUpdater_mt
-- Local values: self
function WindUpdater.new(customMt)
	-- upvalues: (copy) WindUpdater_mt
	local v3_ = customMt or WindUpdater_mt
	local v4_ = setmetatable({}, v3_)
	v4_.listeners = {}
	v4_.isDirty = false
	v4_.alpha = 1
	v4_.duration = 1
	v4_.currentDirX = 1
	v4_.currentDirZ = 0
	v4_.currentVelocity = 1
	v4_.currentCirrusSpeedFactor = 1
	v4_.lastDirX = 1
	v4_.lastDirZ = 0
	v4_.lastVelocity = 1
	v4_.lastCirrusSpeedFactor = 1
	v4_.targetDirX = 1
	v4_.targetDirZ = 0
	v4_.targetVelocity = 1
	v4_.targetCirrusSpeedFactor = 1
	v4_.sharedShaderParamValueWindSpeed = v4_.currentVelocity / WindUpdater.MAX_SPEED
	v4_.sharedShaderParamValueWindDirX = 1
	v4_.sharedShaderParamValueWindDirZ = 0
	v4_.randomWindWaving = true
	return v4_
end

function WindUpdater:delete()
	self.listeners = {}
end

-- Local values: windSpeed, _, listener, t, sin, offset, inputSpeed, amplitude, speed
function WindUpdater:update(scaledDt)
	if self.alpha ~= 1 then
		local v8_ = self.alpha + scaledDt / self.duration
		self.alpha = math.min(v8_, 1)
		self.currentDirX = MathUtil.lerp(self.lastDirX, self.targetDirX, self.alpha)
		self.currentDirZ = MathUtil.lerp(self.lastDirZ, self.targetDirZ, self.alpha)
		self.currentVelocity = MathUtil.lerp(self.lastVelocity, self.targetVelocity, self.alpha)
		self.currentCirrusSpeedFactor = MathUtil.lerp(self.lastCirrusSpeedFactor, self.targetCirrusSpeedFactor, self.alpha)
		self.isDirty = true
	end
	if self.isDirty then
		local v9_
		if self.randomWindWaving then
			v9_ = nil
		else
			local v10_ = self.currentVelocity / WindUpdater.MAX_SPEED
			v9_ = math.clamp(v10_, 0, 1)
		end
		self:setSharedShaderParameterValues(v9_, self.currentDirX, self.currentDirZ)
		for _, v11_ in ipairs(self.listeners) do
			v11_:setWindValues(self.currentDirX, self.currentDirZ, self.currentVelocity, self.currentCirrusSpeedFactor)
		end
		self.isDirty = false
	end
	if self.randomWindWaving then
		local v12_ = g_time / 60000
		local v13_ = math.sin
		local v14_ = (v13_(v12_) + v13_(2.2 * v12_ + 5.52) + v13_(2.9 * v12_ + 0.93)) / 4
		local v15_ = self.currentVelocity / WindUpdater.MAX_SPEED
		local v16_ = math.clamp(v15_, 0, 1)
		local v17_ = v16_ * 0.05 * v14_ + v16_
		self:setSharedShaderParameterValues(math.clamp(v17_, 0, 1), nil, nil)
	end
end

function WindUpdater:setSharedShaderParameterValues(windSpeed, windDirX, windDirZ)
	self.sharedShaderParamValueWindSpeed = windSpeed or self.sharedShaderParamValueWindSpeed
	self.sharedShaderParamValueWindDirX = windDirX or self.sharedShaderParamValueWindDirX
	self.sharedShaderParamValueWindDirZ = windDirZ or self.sharedShaderParamValueWindDirZ
	setSharedShaderParameter(Shader.PARAM_SHARED_WIND_SPEED, self.sharedShaderParamValueWindSpeed)
	setSharedShaderParameter(Shader.PARAM_SHARED_WIND_DIR_X, self.sharedShaderParamValueWindDirX)
	setSharedShaderParameter(Shader.PARAM_SHARED_WIND_DIR_Z, self.sharedShaderParamValueWindDirZ)
end

function WindUpdater:getCurrentValues()
	return self.currentDirX, self.currentDirZ, self.currentVelocity, self.currentCirrusSpeedFactor
end

function WindUpdater:setTargetValues(windDirX, windDirZ, windVelocity, cirrusCloudSpeedFactor, duration)
	self.alpha = 0
	self.duration = math.max(1, duration)
	self.lastDirX = self.currentDirX
	self.lastDirZ = self.currentDirZ
	self.lastVelocity = self.currentVelocity
	self.lastCirrusSpeedFactor = self.currentCirrusSpeedFactor
	self.targetDirX = windDirX
	self.targetDirZ = windDirZ
	self.targetVelocity = windVelocity
	self.targetCirrusSpeedFactor = cirrusCloudSpeedFactor
end

function WindUpdater:addWindChangedListener(listener)
	table.addElement(self.listeners, listener)
end

function WindUpdater:removeWindChangedListener(listener)
	table.removeElement(self.listeners, listener)
end
