FeedingRobotState = {}
local FeedingRobotState_mt = Class(FeedingRobotState)
function FeedingRobotState.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.INT, basePath .. ".animatedObject(?)#index", "Animated object index")
	schema:register(XMLValueType.INT, basePath .. ".animatedObject(?)#direction", "Animated object direction")
	schema:register(XMLValueType.INT, basePath .. ".animatedObject(?)#time", "Animated object time")
	schema:register(XMLValueType.BOOL, basePath .. ".animatedObject(?)#reset", "Animated object reset on state deactivate")
	ObjectChangeUtil.registerObjectChangeXMLPaths(schema, basePath)
end
function FeedingRobotState.new(feedingRobot, customMt)
	local self = setmetatable({}, customMt or FeedingRobotState_mt)
	self.feedingRobot = feedingRobot
	self.animatedObjects = {}
	return self
end
function FeedingRobotState:load(xmlFile, key)
	xmlFile:iterate(key .. ".animatedObject", function(_, animKey)
		local index = xmlFile:getValue(animKey .. "#index")
		if index ~= nil and self.feedingRobot.animatedObjects[index] ~= nil then
			local animatedObject = {}
			animatedObject.object = self.feedingRobot.animatedObjects[index]
			animatedObject.direction = xmlFile:getValue(animKey .. "#direction", 1)
			animatedObject.time = xmlFile:getValue(animKey .. "#time", 1)
			animatedObject.reset = xmlFile:getValue(animKey .. "#reset", false)
			table.insert(self.animatedObjects, animatedObject)
		end
	end)
	self.objectChanges = ObjectChangeUtil.loadObjectChangeFromXML(xmlFile, key, nil, self.feedingRobot.components, self.feedingRobot)
end
function FeedingRobotState:isDone()
	local isDone = true
	for _, animatedObject in ipairs(self.animatedObjects) do
		local animation = animatedObject.object.animation
		if animation.direction ~= 0 and animation.direction ~= animatedObject.direction then
			isDone = false
			return isDone
		end
		if 0.001 < math.abs(animation.time - animatedObject.time) then
			isDone = false
			return isDone
		end
	end
	return isDone
end
function FeedingRobotState:update(dt) end
function FeedingRobotState:activate()
	for _, animatedObject in ipairs(self.animatedObjects) do
		if animatedObject.reset then
			animatedObject.object:resetTime()
		end
		animatedObject.object:setDirection(animatedObject.direction)
	end
	ObjectChangeUtil.setObjectChanges(self.objectChanges, true)
end
function FeedingRobotState:deactivate() end
function FeedingRobotState:raiseActive()
	return true
end
