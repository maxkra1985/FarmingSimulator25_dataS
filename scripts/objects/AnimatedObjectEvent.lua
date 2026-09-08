-- Local values: AnimatedObjectEvent_mt
AnimatedObjectEvent = {}
local AnimatedObjectEvent_mt = Class(AnimatedObjectEvent, Event)
InitStaticEventClass(AnimatedObjectEvent, "AnimatedObjectEvent")
function AnimatedObjectEvent.emptyNew()
	-- upvalues: (copy) AnimatedObjectEvent_mt
	return Event.new(AnimatedObjectEvent_mt)
end

-- Local values: self
function AnimatedObjectEvent.new(animatedObject, direction)
	local v4_ = AnimatedObjectEvent.emptyNew()
	v4_.animatedObject = animatedObject
	v4_.direction = direction
	return v4_
end

-- Local values: objectId
function AnimatedObjectEvent:readStream(streamId, connection)
	local v8_ = g_currentMission
	assert(v8_:getIsServer())
	local v9_ = NetworkUtil.readNodeObjectId(streamId)
	self.animatedObject = NetworkUtil.getObject(v9_)
	if self.animatedObject == nil then
		Logging.warning("AnimatedObjectEvent: AnimatedObject with id \'%s\' does not exist on server!", v9_)
	end
	self.direction = streamReadUIntN(streamId, 2) - 1
	self:run(connection)
end

function AnimatedObjectEvent:writeStream(streamId, connection)
	assert(connection:getIsServer())
	NetworkUtil.writeNodeObject(streamId, self.animatedObject)
	streamWriteUIntN(streamId, self.direction + 1, 2)
end

function AnimatedObjectEvent:run(connection)
	if self.animatedObject ~= nil then
		self.animatedObject:setDirection(self.direction)
	end
end
