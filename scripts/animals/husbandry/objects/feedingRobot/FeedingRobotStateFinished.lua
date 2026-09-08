-- Local values: FeedingRobotStateFinished_mt
FeedingRobotStateFinished = {}
local FeedingRobotStateFinished_mt = Class(FeedingRobotStateFinished, FeedingRobotState)

-- Upvalues: FeedingRobotStateFinished_mt
-- Local values: self
function FeedingRobotStateFinished.new(feedingRobot, customMt)
	-- upvalues: (copy) FeedingRobotStateFinished_mt
	return FeedingRobotState.new(feedingRobot, customMt or FeedingRobotStateFinished_mt)
end
