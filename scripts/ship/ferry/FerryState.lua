FerryState = {}
local FerryState_mt = Class(FerryState)
function FerryState.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.INT, basePath .. ".animatedObject(?)#index", "Animated object index")
	schema:register(XMLValueType.INT, basePath .. ".animatedObject(?)#direction", "Animated object direction")
	schema:register(XMLValueType.INT, basePath .. ".animatedObject(?)#time", "Animated object time")
	schema:register(XMLValueType.BOOL, basePath .. ".animatedObject(?)#reset", "Animated object reset on state deactivate")
end
function FerryState.new(ferry, customMt)
	local self = setmetatable({}, customMt or FerryState_mt)
	self.ferry = ferry
	self.animatedObjects = {}
	return self
end
function FerryState:load(xmlFile, key)
	for _, animKey in xmlFile:iterator(key .. ".animatedObject") do
		local index = xmlFile:getValue(animKey .. "#index")
		local object = self.ferry.animatedObjects[index]
		if object == nil then
			continue
		end
		local animatedObject = {}
		animatedObject.object = object
		animatedObject.direction = xmlFile:getValue(animKey .. "#direction", 1)
		animatedObject.time = xmlFile:getValue(animKey .. "#time", 1)
		animatedObject.reset = xmlFile:getValue(animKey .. "#reset", false)
		table.insert(self.animatedObjects, animatedObject)
	end
	return true
end
function FerryState:isDone()
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
function FerryState:update(dt) end
function FerryState:activate()
	if self.ferry.isServer then
		for _, animatedObject in ipairs(self.animatedObjects) do
			if animatedObject.reset then
				animatedObject.object:setAnimTime(0)
			end
			animatedObject.object:setDirection(animatedObject.direction)
		end
	end
end
function FerryState:deactivate() end
function FerryState:raiseActive()
	return true
end
function FerryState:getCanFinishState()
	return false
end
