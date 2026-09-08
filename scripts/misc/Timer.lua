-- Local values: Timer_mt
Timer = {}
local Timer_mt = Class(Timer)

-- Upvalues: Timer_mt
-- Local values: self
function Timer.new(duration)
	-- upvalues: (copy) Timer_mt
	local v3_ = Timer_mt
	local v4_ = setmetatable({}, v3_)
	v4_.duration = duration
	v4_.callback = nil
	v4_.isRunning = false
	v4_.timeLeft = duration
	return v4_
end

function Timer:delete()
	self:reset()
end

function Timer:reset()
	g_currentMission:removeUpdateable(self)
	self.isRunning = false
end

function Timer:start(noReset)
	if self.duration == nil then
		Logging.error("Timer duration not set")
		printCallstack()
	else
		self.isRunning = true
		if noReset == nil or not noReset then
			self.timeLeft = self.duration
		end
		g_currentMission:addUpdateable(self)
	end
end

function Timer:startIfNotRunning()
	if not self.isRunning then
		self:start()
	end
end

function Timer:stop()
	g_currentMission:removeUpdateable(self)
	self.isRunning = false
end

function Timer:finish()
	g_currentMission:removeUpdateable(self)
	self.timeLeft = 0
	self.isRunning = false
	if self.callback ~= nil then
		self.callback(self)
	end
end

function Timer:getIsRunning()
	return self.isRunning
end

function Timer:setFinishCallback(callback)
	self.callback = callback
	return self
end

function Timer:getTimePassed()
	return self.duration - self.timeLeft
end

function Timer:getTimeLeft()
	return self.timeLeft
end

function Timer:setTimeLeft(timeLeftMs)
	self.timeLeft = timeLeftMs
end

-- Local values: scale
function Timer:update(dt)
	if self.isRunning then
		local v21_ = self.scaleFunc == nil and 1 or self.scaleFunc()
		self.timeLeft = self.timeLeft - dt * v21_
		if self.timeLeft <= 0 then
			self:finish()
		end
	end
end

function Timer:setScaleFunction(scaleFunc)
	self.scaleFunc = scaleFunc
end

-- Local values: timer
function Timer.createOneshot(duration, callback, scaleFunc)
	local v_u_27_ = Timer.new(duration)
	v_u_27_:setFinishCallback(function()
		-- upvalues: (copy) v_u_27_, (copy) callback
		v_u_27_:delete()
		return callback()
	end)
	v_u_27_:setScaleFunction(scaleFunc)
	v_u_27_:start()
	return v_u_27_
end

function Timer:getDuration()
	return self.duration
end

function Timer:setDuration(duration)
	self.duration = duration
	return self
end

function Timer:writeUpdateStream(streamId)
	streamWriteInt32(streamId, self.timeLeft)
end

function Timer:readUpdateStream(streamId)
	self.timeLeft = streamReadInt32(streamId)
end
