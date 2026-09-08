-- Local values: FeedingRobotState_mt
FeedingRobotState = {}
local FeedingRobotState_mt = Class(FeedingRobotState)

function FeedingRobotState.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.INT, basePath .. ".animatedObject(?)#index", "Animated object index")
	schema:register(XMLValueType.INT, basePath .. ".animatedObject(?)#direction", "Animated object direction")
	schema:register(XMLValueType.INT, basePath .. ".animatedObject(?)#time", "Animated object time")
	schema:register(XMLValueType.BOOL, basePath .. ".animatedObject(?)#reset", "Animated object reset on state deactivate")
	ObjectChangeUtil.registerObjectChangeXMLPaths(schema, basePath)
end

-- Upvalues: FeedingRobotState_mt
-- Local values: self
function FeedingRobotState.new(feedingRobot, customMt)
	-- upvalues: (copy) FeedingRobotState_mt
	local v6_ = customMt or FeedingRobotState_mt
	local v7_ = setmetatable({}, v6_)
	v7_.feedingRobot = feedingRobot
	v7_.animatedObjects = {}
	return v7_
end

function FeedingRobotState:load(xmlFile, key)
	xmlFile:iterate(key .. ".animatedObject", function(_, p11_)
		-- upvalues: (copy) xmlFile, (copy) self
		local v12_ = xmlFile:getValue(p11_ .. "#index")
		if v12_ ~= nil and self.feedingRobot.animatedObjects[v12_] ~= nil then
			local v13_ = {
				["object"] = self.feedingRobot.animatedObjects[v12_],
				["direction"] = xmlFile:getValue(p11_ .. "#direction", 1),
				["time"] = xmlFile:getValue(p11_ .. "#time", 1),
				["reset"] = xmlFile:getValue(p11_ .. "#reset", false)
			}
			local v14_ = self.animatedObjects
			table.insert(v14_, v13_)
		end
	end)
	self.objectChanges = ObjectChangeUtil.loadObjectChangeFromXML(xmlFile, key, nil, self.feedingRobot.components, self.feedingRobot)
end

-- Local values: isDone, _, animatedObject, animation
function FeedingRobotState:isDone()
	local v16_ = true
	for _, v17_ in ipairs(self.animatedObjects) do
		local v18_ = v17_.object.animation
		if v18_.direction ~= 0 and v18_.direction ~= v17_.direction then
			return false
		end
		local v19_ = v18_.time - v17_.time
		if math.abs(v19_) > 0.001 then
			return false
		end
	end
	return v16_
end

function FeedingRobotState:update(dt) end

-- Local values: _, animatedObject
function FeedingRobotState:activate()
	for _, v21_ in ipairs(self.animatedObjects) do
		if v21_.reset then
			v21_.object:resetTime()
		end
		v21_.object:setDirection(v21_.direction)
	end
	ObjectChangeUtil.setObjectChanges(self.objectChanges, true)
end

function FeedingRobotState:deactivate() end

function FeedingRobotState:raiseActive()
	return true
end
