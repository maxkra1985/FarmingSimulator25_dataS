FeedingRobotStateLoading = {}
local FeedingRobotStateLoading_mt = Class(FeedingRobotStateLoading, FeedingRobotState)
function FeedingRobotStateLoading.new(feedingRobot, customMt)
	local self = FeedingRobotState.new(feedingRobot, customMt or FeedingRobotStateLoading_mt)
	self.feedingRobot = feedingRobot
	return self
end
function FeedingRobotStateLoading:isDone()
	if not self.feedingRobot.isLoadingFinished then
		return false
	else
		return FeedingRobotStateLoading:superClass().isDone(self)
	end
end
function FeedingRobotStateLoading:raiseActive()
	return false
end
