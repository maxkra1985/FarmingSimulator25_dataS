RollercoasterPassengerEnterRequestEvent = {}
local RollercoasterPassengerEnterRequestEvent_mt = Class(RollercoasterPassengerEnterRequestEvent, Event)
InitStaticEventClass(RollercoasterPassengerEnterRequestEvent, "RollercoasterPassengerEnterRequestEvent")
function RollercoasterPassengerEnterRequestEvent.emptyNew()
	local self = Event.new(RollercoasterPassengerEnterRequestEvent_mt)
	return self
end
function RollercoasterPassengerEnterRequestEvent.new(rollercoaster, player)
	local self = RollercoasterPassengerEnterRequestEvent.emptyNew()
	self.rollercoaster = rollercoaster
	self.player = player
	return self
end
function RollercoasterPassengerEnterRequestEvent:readStream(streamId, connection)
	self.rollercoaster = NetworkUtil.readNodeObject(streamId)
	self.player = NetworkUtil.readNodeObject(streamId)
	self:run(connection)
end
function RollercoasterPassengerEnterRequestEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.rollercoaster)
	NetworkUtil.writeNodeObject(streamId, self.player)
end
function RollercoasterPassengerEnterRequestEvent:run(connection)
	if self.rollercoaster ~= nil and self.rollercoaster:getIsSynchronized() then
		self.rollercoaster:tryEnterRide(connection, self.player)
	end
end
