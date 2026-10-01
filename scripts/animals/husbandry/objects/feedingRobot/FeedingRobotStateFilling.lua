FeedingRobotStateFilling = {}
local FeedingRobotStateFilling_mt = Class(FeedingRobotStateFilling, FeedingRobotState)
function FeedingRobotStateFilling.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.INT, basePath .. "#deltaFillLevel", "Delta fill level")
	schema:register(XMLValueType.INT, basePath .. "#unloadingSpotIndex", "The index of the unloading spot that should be activated")
	schema:register(XMLValueType.FLOAT, basePath .. "#waitDuration", "Robot wait duration in seconds")
end
function FeedingRobotStateFilling.new(feedingRobot, customMt)
	local self = FeedingRobotState.new(feedingRobot, customMt or FeedingRobotStateFilling_mt)
	self.deltaFillLevel = nil
	self.waitDuration = nil
	self.waitTimeLeft = nil
	self.unloadingSpotIndex = nil
	return self
end
function FeedingRobotStateFilling:load(xmlFile, key)
	FeedingRobotStateFilling:superClass().load(self, xmlFile, key)
	self.deltaFillLevel = xmlFile:getInt(key .. "#deltaFillLevel")
	self.unloadingSpotIndex = xmlFile:getInt(key .. "#unloadingSpotIndex")
	local waitDuration = xmlFile:getFloat(key .. "#waitDuration")
	if waitDuration ~= nil then
		self.waitDuration = waitDuration * 1000
	end
end
function FeedingRobotStateFilling:isDone()
	if self.waitDuration ~= nil and 0 < self.waitTimeLeft then
		return false
	end
	return FeedingRobotStateFilling:superClass().isDone(self)
end
function FeedingRobotStateFilling:update(dt)
	FeedingRobotStateFilling:superClass().update(self, dt)
	if self.waitDuration ~= nil and self.waitTimeLeft ~= nil then
		self.waitTimeLeft = math.max(self.waitTimeLeft - dt, 0)
		local delta = self.deltaFillLevel / self.waitDuration * dt
		local fillPlane = self.feedingRobot.robot.fillPlane
		local fillScale = (fillPlane.fillLevel + delta) / fillPlane.capacity
		self.feedingRobot:setFillScale(fillScale)
	end
end
function FeedingRobotStateFilling:activate()
	FeedingRobotStateFilling:superClass().activate(self)
	if self.waitDuration ~= nil then
		self.waitTimeLeft = self.waitDuration
	end
	if self.unloadingSpotIndex ~= nil then
		self.feedingRobot:setUnloadingSpotActive(self.unloadingSpotIndex, true)
	end
end
function FeedingRobotStateFilling:deactivate()
	if self.waitDuration == nil and self.deltaFillLevel ~= nil then
		local fillPlane = self.feedingRobot.robot.fillPlane
		local fillScale = (fillPlane.fillLevel + self.deltaFillLevel) / fillPlane.capacity
		self.feedingRobot:setFillScale(fillScale)
	end
	self.waitTimeLeft = nil
	if self.unloadingSpotIndex ~= nil then
		self.feedingRobot:setUnloadingSpotActive(self.unloadingSpotIndex, false)
	end
	FeedingRobotStateFilling:superClass().deactivate(self)
end
