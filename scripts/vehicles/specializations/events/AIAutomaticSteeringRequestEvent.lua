-- Local values: AIAutomaticSteeringRequestEvent_mt
AIAutomaticSteeringRequestEvent = {}
local AIAutomaticSteeringRequestEvent_mt = Class(AIAutomaticSteeringRequestEvent, Event)
InitStaticEventClass(AIAutomaticSteeringRequestEvent, "AIAutomaticSteeringRequestEvent")
function AIAutomaticSteeringRequestEvent.emptyNew()
	-- upvalues: (copy) AIAutomaticSteeringRequestEvent_mt
	return Event.new(AIAutomaticSteeringRequestEvent_mt)
end

-- Local values: self
function AIAutomaticSteeringRequestEvent.new(vehicle, x, z, fieldCourseSettings)
	local v6_ = AIAutomaticSteeringRequestEvent.emptyNew()
	v6_.vehicle = vehicle
	v6_.x = x
	v6_.z = z
	v6_.fieldCourseSettings = fieldCourseSettings
	return v6_
end

-- Local values: attributes
function AIAutomaticSteeringRequestEvent:readStream(streamId, connection)
	self.vehicle = NetworkUtil.readNodeObject(streamId)
	local v10_, v11_ = g_fieldCourseManager:readTerrainDetailPixel(streamId)
	self.x = v10_
	self.z = v11_
	local v12_ = FieldCourseSettings.readStream(streamId, connection)
	self.fieldCourseSettings = FieldCourseSettings.new(self.vehicle)
	self.fieldCourseSettings:applyAttributes(v12_)
	self:run(connection)
end

function AIAutomaticSteeringRequestEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.vehicle)
	g_fieldCourseManager:writeTerrainDetailPixel(streamId, self.x, self.z)
	self.fieldCourseSettings:writeStream(streamId, connection)
end

function AIAutomaticSteeringRequestEvent:run(connection)
	if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
		self.vehicle:generateSteeringFieldCourse(self.x, self.z, self.fieldCourseSettings)
	end
end
