-- Local values: AIAutomaticSteeringCourseEvent_mt
AIAutomaticSteeringCourseEvent = {}
local AIAutomaticSteeringCourseEvent_mt = Class(AIAutomaticSteeringCourseEvent, Event)
InitStaticEventClass(AIAutomaticSteeringCourseEvent, "AIAutomaticSteeringCourseEvent")
function AIAutomaticSteeringCourseEvent.emptyNew()
	-- upvalues: (copy) AIAutomaticSteeringCourseEvent_mt
	return Event.new(AIAutomaticSteeringCourseEvent_mt)
end

-- Local values: self
function AIAutomaticSteeringCourseEvent.new(vehicle, steeringFieldCourse)
	local v4_ = AIAutomaticSteeringCourseEvent.emptyNew()
	v4_.vehicle = vehicle
	v4_.steeringFieldCourse = steeringFieldCourse
	return v4_
end

function AIAutomaticSteeringCourseEvent:readStream(streamId, connection)
	self.vehicle = NetworkUtil.readNodeObject(streamId)
	if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
		self.vehicle:setAIAutomaticSteeringCourse(nil, true)
	end
	if streamReadBool(streamId) then
		SteeringFieldCourse.readStream(streamId, connection, function(p8_)
			-- upvalues: (copy) self
			if p8_ ~= nil and (self.vehicle ~= nil and self.vehicle:getIsSynchronized()) then
				self.vehicle:setAIAutomaticSteeringCourse(p8_, true)
			end
		end)
	end
end

function AIAutomaticSteeringCourseEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.vehicle)
	if streamWriteBool(streamId, self.steeringFieldCourse ~= nil) then
		self.steeringFieldCourse:writeStream(streamId, connection)
	end
end

function AIAutomaticSteeringCourseEvent:run(connection) end
