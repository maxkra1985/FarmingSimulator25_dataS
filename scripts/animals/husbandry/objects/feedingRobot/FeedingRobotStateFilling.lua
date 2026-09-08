-- Local values: FeedingRobotStateFilling_mt
FeedingRobotStateFilling = {}
local FeedingRobotStateFilling_mt = Class(FeedingRobotStateFilling, FeedingRobotState)

function FeedingRobotStateFilling.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.INT, basePath .. "#deltaFillLevel", "Delta fill level")
	schema:register(XMLValueType.INT, basePath .. "#unloadingSpotIndex", "The index of the unloading spot that should be activated")
	schema:register(XMLValueType.FLOAT, basePath .. "#waitDuration", "Robot wait duration in seconds")
end

-- Upvalues: FeedingRobotStateFilling_mt
-- Local values: self
function FeedingRobotStateFilling.new(feedingRobot, customMt)
	-- upvalues: (copy) FeedingRobotStateFilling_mt
	local v6_ = FeedingRobotState.new(feedingRobot, customMt or FeedingRobotStateFilling_mt)
	v6_.deltaFillLevel = nil
	v6_.waitDuration = nil
	v6_.waitTimeLeft = nil
	v6_.unloadingSpotIndex = nil
	return v6_
end

-- Local values: waitDuration
function FeedingRobotStateFilling:load(xmlFile, key)
	FeedingRobotStateFilling:superClass().load(self, xmlFile, key)
	self.deltaFillLevel = xmlFile:getInt(key .. "#deltaFillLevel")
	self.unloadingSpotIndex = xmlFile:getInt(key .. "#unloadingSpotIndex")
	local v10_ = xmlFile:getFloat(key .. "#waitDuration")
	if v10_ ~= nil then
		self.waitDuration = v10_ * 1000
	end
end

function FeedingRobotStateFilling:isDone()
	if self.waitDuration == nil or self.waitTimeLeft <= 0 then
		return FeedingRobotStateFilling:superClass().isDone(self)
	else
		return false
	end
end

-- Local values: delta, fillPlane, fillScale
function FeedingRobotStateFilling:update(dt)
	FeedingRobotStateFilling:superClass().update(self, dt)
	if self.waitDuration ~= nil and self.waitTimeLeft ~= nil then
		local v14_ = self.waitTimeLeft - dt
		self.waitTimeLeft = math.max(v14_, 0)
		local v15_ = self.deltaFillLevel / self.waitDuration * dt
		local v16_ = self.feedingRobot.robot.fillPlane
		local v17_ = (v16_.fillLevel + v15_) / v16_.capacity
		self.feedingRobot:setFillScale(v17_)
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

-- Local values: fillPlane, fillScale
function FeedingRobotStateFilling:deactivate()
	if self.waitDuration == nil and self.deltaFillLevel ~= nil then
		local v20_ = self.feedingRobot.robot.fillPlane
		local v21_ = (v20_.fillLevel + self.deltaFillLevel) / v20_.capacity
		self.feedingRobot:setFillScale(v21_)
	end
	self.waitTimeLeft = nil
	if self.unloadingSpotIndex ~= nil then
		self.feedingRobot:setUnloadingSpotActive(self.unloadingSpotIndex, false)
	end
	FeedingRobotStateFilling:superClass().deactivate(self)
end
