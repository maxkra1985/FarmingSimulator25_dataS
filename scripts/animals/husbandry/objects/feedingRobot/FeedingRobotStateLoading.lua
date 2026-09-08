-- Local values: FeedingRobotStateLoading_mt
FeedingRobotStateLoading = {}
local FeedingRobotStateLoading_mt = Class(FeedingRobotStateLoading, FeedingRobotState)

-- Upvalues: FeedingRobotStateLoading_mt
-- Local values: self
function FeedingRobotStateLoading.new(feedingRobot, customMt)
	-- upvalues: (copy) FeedingRobotStateLoading_mt
	local v4_ = FeedingRobotState.new(feedingRobot, customMt or FeedingRobotStateLoading_mt)
	v4_.feedingRobot = feedingRobot
	return v4_
end

function FeedingRobotStateLoading:isDone()
	if self.feedingRobot.isLoadingFinished then
		return FeedingRobotStateLoading:superClass().isDone(self)
	else
		return false
	end
end

function FeedingRobotStateLoading:raiseActive()
	return false
end
