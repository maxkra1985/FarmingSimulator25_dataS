-- Local values: VehicleBrokenEvent_mt
VehicleBrokenEvent = {}
local VehicleBrokenEvent_mt = Class(VehicleBrokenEvent, Event)
InitStaticEventClass(VehicleBrokenEvent, "VehicleBrokenEvent")
function VehicleBrokenEvent.emptyNew()
	-- upvalues: (copy) VehicleBrokenEvent_mt
	return Event.new(VehicleBrokenEvent_mt)
end

-- Local values: self
function VehicleBrokenEvent.new(object)
	local v3_ = VehicleBrokenEvent.emptyNew()
	v3_.object = object
	return v3_
end

function VehicleBrokenEvent:readStream(streamId, connection)
	self.object = NetworkUtil.readNodeObject(streamId)
	self:run(connection)
end

function VehicleBrokenEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.object)
end

function VehicleBrokenEvent:run(connection)
	if self.object ~= nil and self.object:getIsSynchronized() then
		self.object:setBroken()
	end
end
