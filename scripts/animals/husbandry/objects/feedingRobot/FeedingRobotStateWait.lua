-- Local values: FeedingRobotStateWait_mt
FeedingRobotStateWait = {}
local FeedingRobotStateWait_mt = Class(FeedingRobotStateWait, FeedingRobotState)

function FeedingRobotStateWait.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.FLOAT, basePath .. "#waitDuration", "Robot wait duration in seconds")
end

-- Upvalues: FeedingRobotStateWait_mt
-- Local values: self
function FeedingRobotStateWait.new(feedingRobot, customMt)
	-- upvalues: (copy) FeedingRobotStateWait_mt
	local v6_ = FeedingRobotState.new(feedingRobot, customMt or FeedingRobotStateWait_mt)
	v6_.waitDuration = nil
	v6_.waitTimeLeft = nil
	return v6_
end

function FeedingRobotStateWait:load(xmlFile, key)
	FeedingRobotStateWait:superClass().load(self, xmlFile, key)
	self.waitDuration = xmlFile:getFloat(key .. "#waitDuration", 1) * 1000
end

function FeedingRobotStateWait:isDone()
	if self.waitTimeLeft > 0 then
		return false
	else
		return FeedingRobotStateWait:superClass().isDone(self)
	end
end

function FeedingRobotStateWait:update(dt)
	FeedingRobotStateWait:superClass().update(self, dt)
	if self.waitTimeLeft ~= nil then
		local v13_ = self.waitTimeLeft - dt
		self.waitTimeLeft = math.max(v13_, 0)
	end
end

function FeedingRobotStateWait:activate()
	FeedingRobotStateWait:superClass().activate(self)
	self.waitTimeLeft = self.waitDuration
end

function FeedingRobotStateWait:deactivate()
	self.waitTimeLeft = nil
	FeedingRobotStateWait:superClass().deactivate(self)
end
