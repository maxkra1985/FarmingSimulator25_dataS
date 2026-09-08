-- Local values: FeedingRobotStateStarting_mt
FeedingRobotStateStarting = {}
local FeedingRobotStateStarting_mt = Class(FeedingRobotStateStarting, FeedingRobotState)

-- Upvalues: FeedingRobotStateStarting_mt
-- Local values: self
function FeedingRobotStateStarting.new(feedingRobot, customMt)
	-- upvalues: (copy) FeedingRobotStateStarting_mt
	return FeedingRobotState.new(feedingRobot, customMt or FeedingRobotStateStarting_mt)
end
