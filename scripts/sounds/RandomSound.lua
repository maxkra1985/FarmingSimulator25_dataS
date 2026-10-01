RandomSound = {}
RandomSound.STATE_WAITING = 0
RandomSound.STATE_PLAYING = 1
local RandomSound_mt = Class(RandomSound)
function RandomSound:onCreate(id)
	g_currentMission:addNonUpdateable(RandomSound.new(id))
end
function RandomSound.new(id, customMt)
	local self = setmetatable({}, customMt or RandomSound_mt)
	self.soundId = id
	self.randomMin = Utils.getNoNil(getUserAttribute(id, "randomMin"), 1000)
	self.randomMax = Utils.getNoNil(getUserAttribute(id, "randomMax"), 2000)
	self.playByNight = Utils.getNoNil(getUserAttribute(id, "playByNight"), false)
	self.playTime = getSampleDuration(getAudioSourceSample(id))
	setVisibility(id, false)
	self.playState = RandomSound.STATE_WAITING
	self.timerId = addTimer(self:getRandomTime(), "randomSoundTimerCallback", self)
	return self
end
function RandomSound:delete()
	removeTimer(self.timerId)
end
function RandomSound:randomSoundTimerCallback()
	if self.playState == RandomSound.STATE_WAITING then
		local play = false
		if g_currentMission ~= nil and g_currentMission.isRunning then
			play = self.playByNight or 18000000 >= g_currentMission.environment.dayTime or g_currentMission.environment.dayTime < 79200000
		end
		if play then
			setVisibility(self.soundId, true)
			setTimerTime(self.timerId, self.playTime)
		else
			setVisibility(self.soundId, false)
			setTimerTime(self.timerId, self.randomMax)
		end
		self.playState = RandomSound.STATE_PLAYING
	else
		setVisibility(self.soundId, false)
		local randomDelay = self:getRandomTime()
		setTimerTime(self.timerId, randomDelay)
		self.playState = RandomSound.STATE_WAITING
	end
	return true
end
function RandomSound:getRandomTime()
	return math.random(self.randomMin, self.randomMax)
end
