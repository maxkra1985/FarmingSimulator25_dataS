-- Local values: RandomSound_mt
RandomSound = {}
RandomSound.STATE_WAITING = 0
RandomSound.STATE_PLAYING = 1
local RandomSound_mt = Class(RandomSound)

function RandomSound:onCreate(id)
	g_currentMission:addNonUpdateable(RandomSound.new(id))
end

-- Upvalues: RandomSound_mt
-- Local values: self
function RandomSound.new(id, customMt)
	-- upvalues: (copy) RandomSound_mt
	local v5_ = customMt or RandomSound_mt
	local v6_ = setmetatable({}, v5_)
	v6_.soundId = id
	v6_.randomMin = Utils.getNoNil(getUserAttribute(id, "randomMin"), 1000)
	v6_.randomMax = Utils.getNoNil(getUserAttribute(id, "randomMax"), 2000)
	v6_.playByNight = Utils.getNoNil(getUserAttribute(id, "playByNight"), false)
	v6_.playTime = getSampleDuration(getAudioSourceSample(id))
	setVisibility(id, false)
	v6_.playState = RandomSound.STATE_WAITING
	v6_.timerId = addTimer(v6_:getRandomTime(), "randomSoundTimerCallback", v6_)
	return v6_
end

function RandomSound:delete()
	removeTimer(self.timerId)
end

-- Local values: play, randomDelay
function RandomSound:randomSoundTimerCallback()
	if self.playState == RandomSound.STATE_WAITING then
		local v9_
		if g_currentMission == nil or not g_currentMission.isRunning then
			v9_ = false
		else
			v9_ = self.playByNight
			if not v9_ then
				if g_currentMission.environment.dayTime > 18000000 then
					v9_ = g_currentMission.environment.dayTime < 79200000
				else
					v9_ = false
				end
			end
		end
		if v9_ then
			setVisibility(self.soundId, true)
			setTimerTime(self.timerId, self.playTime)
		else
			setVisibility(self.soundId, false)
			setTimerTime(self.timerId, self.randomMax)
		end
		self.playState = RandomSound.STATE_PLAYING
	else
		setVisibility(self.soundId, false)
		local v10_ = self:getRandomTime()
		setTimerTime(self.timerId, v10_)
		self.playState = RandomSound.STATE_WAITING
	end
	return true
end

function RandomSound:getRandomTime()
	return math.random(self.randomMin, self.randomMax)
end
