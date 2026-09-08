-- Local values: FeedingRobotStatePaused_mt
FeedingRobotStatePaused = {}
local FeedingRobotStatePaused_mt = Class(FeedingRobotStatePaused, FeedingRobotState)

-- Upvalues: FeedingRobotStatePaused_mt
-- Local values: self
function FeedingRobotStatePaused.new(feedingRobot, customMt)
	-- upvalues: (copy) FeedingRobotStatePaused_mt
	local v4_ = FeedingRobotState.new(feedingRobot, customMt or FeedingRobotStatePaused_mt)
	v4_.feedingRobot = feedingRobot
	return v4_
end

function FeedingRobotStatePaused:isDone()
	if self.feedingRobot.requestedStart then
		return FeedingRobotStatePaused:superClass().isDone(self)
	else
		return false
	end
end

function FeedingRobotStatePaused:deactivate()
	self.feedingRobot.requestedStart = false
	FeedingRobotStatePaused:superClass().deactivate(self)
end

function FeedingRobotStatePaused:raiseActive()
	return false
end
