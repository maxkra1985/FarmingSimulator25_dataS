-- Local values: RollercoasterPassengerEnterRequestEvent_mt
RollercoasterPassengerEnterRequestEvent = {}
local RollercoasterPassengerEnterRequestEvent_mt = Class(RollercoasterPassengerEnterRequestEvent, Event)
InitStaticEventClass(RollercoasterPassengerEnterRequestEvent, "RollercoasterPassengerEnterRequestEvent")
function RollercoasterPassengerEnterRequestEvent.emptyNew()
	-- upvalues: (copy) RollercoasterPassengerEnterRequestEvent_mt
	return Event.new(RollercoasterPassengerEnterRequestEvent_mt)
end

-- Local values: self
function RollercoasterPassengerEnterRequestEvent.new(rollercoaster, player)
	local v4_ = RollercoasterPassengerEnterRequestEvent.emptyNew()
	v4_.rollercoaster = rollercoaster
	v4_.player = player
	return v4_
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
