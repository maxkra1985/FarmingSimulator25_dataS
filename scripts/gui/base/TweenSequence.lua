-- Local values: TweenSequence_mt
TweenSequence = {}
local TweenSequence_mt = Class(TweenSequence, Tween)

-- Upvalues: TweenSequence_mt
-- Local values: self
function TweenSequence.new(functionTarget)
	-- upvalues: (copy) TweenSequence_mt
	local v3_ = Tween.new(nil, nil, nil, nil, TweenSequence_mt)
	v3_.functionTarget = functionTarget
	v3_.callbackStates = {}
	v3_.callbacksCalled = {}
	v3_.tweenUpdateRanges = {}
	v3_.callbackInstants = {}
	v3_.isLooping = false
	v3_.totalDuration = 0
	v3_.isFinished = true
	return v3_
end

function TweenSequence:insertTween(tween, instant)
	self.tweenUpdateRanges[tween] = { instant, instant + tween:getDuration() }
	local v7_ = instant + tween:getDuration()
	local v8_ = self.totalDuration
	self.totalDuration = math.max(v7_, v8_)
	if self.functionTarget ~= nil then
		tween:setTarget(self.functionTarget)
	end
end

function TweenSequence:addTween(tween)
	self:insertTween(tween, self.totalDuration)
end

-- Local values: tween, range, tweenStartInstant, tweenEndInstant, callback, callbackInstant
function TweenSequence:insertInterval(interval, instant)
	for v14_, v15_ in pairs(self.tweenUpdateRanges) do
		local v16_ = v15_[1]
		local v17_ = v15_[2]
		if instant <= v16_ then
			self.tweenUpdateRanges[v14_][1] = v16_ + interval
			self.tweenUpdateRanges[v14_][2] = v17_ + interval
		end
	end
	for v18_, v19_ in pairs(self.callbackInstants) do
		if instant <= v19_ then
			self.callbackInstants[v18_] = v19_ + interval
		end
	end
	self.totalDuration = self.totalDuration + interval
end

function TweenSequence:addInterval(interval)
	self:insertInterval(interval, self.totalDuration)
end

function TweenSequence:insertCallback(callback, callbackState, instant)
	self.callbackInstants[callback] = instant
	self.callbackStates[callback] = callbackState
	self.callbacksCalled[callback] = false
end

function TweenSequence:addCallback(callback, callbackState)
	self:insertCallback(callback, callbackState, self.totalDuration)
end

function TweenSequence:getDuration()
	return self.totalDuration
end

function TweenSequence:setTarget(target)
	self.functionTarget = target
end

function TweenSequence:setLooping(isLooping)
	self.isLooping = isLooping
end

function TweenSequence:start()
	self.isFinished = false
end

function TweenSequence:stop()
	self.isFinished = true
end

-- Local values: tween, callback
function TweenSequence:reset()
	self.elapsedTime = 0
	self.isFinished = true
	for v37_ in pairs(self.tweenUpdateRanges) do
		v37_:reset()
	end
	for v38_ in pairs(self.callbacksCalled) do
		self.callbacksCalled[v38_] = false
	end
end

-- Local values: lastUpdateInstant, allFinished
function TweenSequence:update(dt)
	if not self.isFinished then
		local v41_ = self.elapsedTime
		self.elapsedTime = self.elapsedTime + dt
		local v42_ = self:updateTweens(v41_, dt)
		self:updateCallbacks()
		if self.elapsedTime >= self.totalDuration and v42_ then
			if self.isLooping then
				self:reset()
				self:start()
				return
			end
			self.isFinished = true
		end
	end
end

-- Local values: allFinished, tween, range, tweenStart, maxDt
function TweenSequence:updateTweens(lastInstant, dt)
	local v45_ = true
	for v46_, v47_ in pairs(self.tweenUpdateRanges) do
		local v48_ = v47_[1]
		if not v46_:getFinished() and v48_ <= self.elapsedTime then
			local v49_ = self.elapsedTime - v48_
			v46_:update((math.min(v49_, dt)))
			if v45_ then
				v45_ = v46_:getFinished()
			end
		end
	end
	return v45_
end

-- Local values: callback, instant
function TweenSequence:updateCallbacks()
	for v51_, v52_ in pairs(self.callbackInstants) do
		if not self.callbacksCalled[v51_] and v52_ <= self.elapsedTime then
			if self.functionTarget == nil then
				v51_(self.callbackStates[v51_])
			else
				v51_(self.functionTarget, self.callbackStates[v51_])
			end
			self.callbacksCalled[v51_] = true
		end
	end
end
TweenSequence.NO_SEQUENCE = TweenSequence.new()
function TweenSequence.NO_SEQUENCE.addTween() end
function TweenSequence.NO_SEQUENCE.addInterval() end
function TweenSequence.NO_SEQUENCE.addCallback() end
function TweenSequence.NO_SEQUENCE.insertTween() end
function TweenSequence.NO_SEQUENCE.insertInterval() end
function TweenSequence.NO_SEQUENCE.insertCallback() end
function TweenSequence.NO_SEQUENCE.getFinished()
	return true
end
