-- Local values: EnterablePassengerEnterRequestEvent_mt
EnterablePassengerEnterRequestEvent = {}
local EnterablePassengerEnterRequestEvent_mt = Class(EnterablePassengerEnterRequestEvent, Event)
InitStaticEventClass(EnterablePassengerEnterRequestEvent, "EnterablePassengerEnterRequestEvent")
function EnterablePassengerEnterRequestEvent.emptyNew()
	-- upvalues: (copy) EnterablePassengerEnterRequestEvent_mt
	return Event.new(EnterablePassengerEnterRequestEvent_mt)
end

-- Local values: self
function EnterablePassengerEnterRequestEvent.new(object, seatIndex)
	local v4_ = EnterablePassengerEnterRequestEvent.emptyNew()
	v4_.object = object
	v4_.objectId = NetworkUtil.getObjectId(v4_.object)
	v4_.seatIndex = seatIndex
	return v4_
end

function EnterablePassengerEnterRequestEvent:readStream(streamId, connection)
	self.objectId = NetworkUtil.readNodeObjectId(streamId)
	self.seatIndex = streamReadUIntN(streamId, EnterablePassenger.SEAT_INDEX_SEND_NUM_BITS) + 1
	self.object = NetworkUtil.getObject(self.objectId)
	self:run(connection)
end

function EnterablePassengerEnterRequestEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObjectId(streamId, self.objectId)
	local v10_ = streamWriteUIntN
	local v11_ = self.seatIndex - 1
	local v12_ = 2 ^ EnterablePassenger.SEAT_INDEX_SEND_NUM_BITS - 1
	v10_(streamId, math.clamp(v11_, 0, v12_), EnterablePassenger.SEAT_INDEX_SEND_NUM_BITS)
end

-- Local values: userId
function EnterablePassengerEnterRequestEvent:run(connection)
	if self.object ~= nil and (self.object:getIsSynchronized() and self.object:getIsPassengerSeatIndexAvailable(self.seatIndex)) then
		local v15_ = g_currentMission.userManager:getUserIdByConnection(connection)
		g_server:broadcastEvent(EnterablePassengerEnterResponseEvent.new(self.objectId, false, self.seatIndex, v15_), true, connection)
		connection:sendEvent(EnterablePassengerEnterResponseEvent.new(self.objectId, true, self.seatIndex, v15_))
	end
end
