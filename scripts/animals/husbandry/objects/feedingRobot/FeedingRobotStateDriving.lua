-- Local values: FeedingRobotStateDriving_mt
FeedingRobotStateDriving = {}
local FeedingRobotStateDriving_mt = Class(FeedingRobotStateDriving, FeedingRobotState)

function FeedingRobotStateDriving.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.BOOL, basePath .. "#resetRobot", "")
	schema:register(XMLValueType.BOOL, basePath .. "#resetRobotOnDeactivate", "")
	schema:register(XMLValueType.BOOL, basePath .. "#startMixingAnimation", "")
	schema:register(XMLValueType.BOOL, basePath .. "#stopMixingAnimation", "")
	schema:register(XMLValueType.BOOL, basePath .. "#startDriving", "")
	schema:register(XMLValueType.BOOL, basePath .. "#stopDriving", "")
end

-- Upvalues: FeedingRobotStateDriving_mt
-- Local values: self
function FeedingRobotStateDriving.new(feedingRobot, customMt)
	-- upvalues: (copy) FeedingRobotStateDriving_mt
	local v6_ = FeedingRobotState.new(feedingRobot, customMt or FeedingRobotStateDriving_mt)
	v6_.startFillScale = 0
	return v6_
end

function FeedingRobotStateDriving:load(xmlFile, key)
	FeedingRobotStateDriving:superClass().load(self, xmlFile, key)
	self.resetRobot = xmlFile:getBool(key .. "#resetRobot", true)
	self.resetRobotOnDeactivate = xmlFile:getBool(key .. "#resetRobotOnDeactivate", self.resetRobot)
	self.startMixingAnimation = xmlFile:getBool(key .. "#startMixingAnimation", true)
	self.stopMixingAnimation = xmlFile:getBool(key .. "#stopMixingAnimation", true)
	self.startDriving = xmlFile:getBool(key .. "#startDriving", true)
	self.stopDriving = xmlFile:getBool(key .. "#stopDriving", true)
end

function FeedingRobotStateDriving:isDone()
	if self.feedingRobot.spline.time == 1 or self.feedingRobot.reachedStopPoint then
		return FeedingRobotStateDriving:superClass().isDone(self)
	else
		return false
	end
end

-- Local values: robot, acc, feedingFactor, fillScale
function FeedingRobotStateDriving:update(dt)
	FeedingRobotStateDriving:superClass().update(self, dt)
	if self.feedingRobot.isServer then
		local v13_ = self.feedingRobot.robot
		local v14_ = v13_.acceleration
		if v13_.isBlocked then
			v14_ = v13_.deceleration
		end
		local v15_ = v13_.speed + v14_ * g_physicsDt / 1000
		local v16_ = v13_.maxSpeed
		v13_.speed = math.clamp(v15_, 0, v16_)
		if v13_.speed > 0 then
			self.feedingRobot:addSplineDelta(dt * v13_.speed)
		end
	end
	local v17_ = self.feedingRobot:getFeedingFactor()
	local v18_ = self.startFillScale - self.startFillScale * v17_
	self.feedingRobot:setFillScale(v18_)
end

function FeedingRobotStateDriving:activate()
	FeedingRobotStateDriving:superClass().activate(self)
	if self.startMixingAnimation then
		self.feedingRobot:setMixingAnimationActive(true)
	end
	if self.resetRobot then
		self.feedingRobot:resetRobot()
	end
	self.startFillScale = self.feedingRobot.robot.fillPlane.fillLevel / self.feedingRobot.robot.fillPlane.capacity
	if self.startDriving then
		self.feedingRobot:setIsDriving(true)
	end
end

function FeedingRobotStateDriving:deactivate()
	if self.stopMixingAnimation then
		self.feedingRobot:setMixingAnimationActive(false)
	end
	if self.resetRobot then
		if self.resetRobotOnDeactivate then
			self.feedingRobot:resetRobot()
		end
		self.feedingRobot:setFillScale(0)
		self.startFillScale = 0
	end
	self.feedingRobot.reachedStopPoint = false
	if self.stopDriving then
		self.feedingRobot:setIsDriving(false)
	end
	FeedingRobotStateDriving:superClass().deactivate(self)
end
