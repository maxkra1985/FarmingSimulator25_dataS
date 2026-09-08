-- Local values: DailySound_mt
DailySound = {}
local DailySound_mt = Class(DailySound)

function DailySound:onCreate(id)
	g_currentMission:addNonUpdateable(DailySound.new(id))
end

-- Upvalues: DailySound_mt
-- Local values: self
function DailySound.new(id, customMt)
	-- upvalues: (copy) DailySound_mt
	local v5_ = customMt or DailySound_mt
	local v6_ = setmetatable({}, v5_)
	v6_.soundId = id
	v6_.startTime = Utils.getNoNil(getUserAttribute(id, "startTime"), 0)
	v6_.endTime = Utils.getNoNil(getUserAttribute(id, "endTime"), 24)
	setVisibility(id, false)
	v6_.isActive = false
	v6_.oldIsActive = false
	v6_.timerId = addTimer(1000, "dailySoundTimerCallback", v6_)
	return v6_
end

function DailySound:delete()
	removeTimer(self.timerId)
end

function DailySound:dailySoundTimerCallback()
	if g_currentMission ~= nil then
		if self.startTime > self.endTime then
			self.isActive = g_currentMission.environment.dayTime > self.startTime * 60 * 60 * 1000 and true or g_currentMission.environment.dayTime < self.endTime * 60 * 60 * 1000
		else
			local v9_
			if g_currentMission.environment.dayTime > self.startTime * 60 * 60 * 1000 then
				v9_ = g_currentMission.environment.dayTime < self.endTime * 60 * 60 * 1000
			else
				v9_ = false
			end
			self.isActive = v9_
		end
		if self.isActive ~= self.oldIsActive then
			setVisibility(self.soundId, self.isActive)
			self.oldIsActive = self.isActive
		end
	end
	return true
end
