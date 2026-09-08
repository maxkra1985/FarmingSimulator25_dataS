-- Local values: EnterablePassengerEnterResponseEvent_mt
EnterablePassengerEnterResponseEvent = {}
local EnterablePassengerEnterResponseEvent_mt = Class(EnterablePassengerEnterResponseEvent, Event)
InitStaticEventClass(EnterablePassengerEnterResponseEvent, "EnterablePassengerEnterResponseEvent")
function EnterablePassengerEnterResponseEvent.emptyNew()
	-- upvalues: (copy) EnterablePassengerEnterResponseEvent_mt
	return Event.new(EnterablePassengerEnterResponseEvent_mt)
end

-- Local values: self
function EnterablePassengerEnterResponseEvent.new(id, isOwner, seatIndex, userId)
	local v6_ = EnterablePassengerEnterResponseEvent.emptyNew()
	v6_.id = id
	v6_.isOwner = isOwner
	v6_.seatIndex = seatIndex
	v6_.userId = userId
	return v6_
end

function EnterablePassengerEnterResponseEvent:readStream(streamId, connection)
	self.id = NetworkUtil.readNodeObjectId(streamId)
	self.isOwner = streamReadBool(streamId)
	self.seatIndex = streamReadUIntN(streamId, EnterablePassenger.SEAT_INDEX_SEND_NUM_BITS) + 1
	self.userId = User.streamReadUserId(streamId)
	self:run(connection)
end

function EnterablePassengerEnterResponseEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObjectId(streamId, self.id)
	streamWriteBool(streamId, self.isOwner)
	local v12_ = streamWriteUIntN
	local v13_ = self.seatIndex - 1
	local v14_ = 2 ^ EnterablePassenger.SEAT_INDEX_SEND_NUM_BITS - 1
	v12_(streamId, math.clamp(v13_, 0, v14_), EnterablePassenger.SEAT_INDEX_SEND_NUM_BITS)
	User.streamWriteUserId(streamId, self.userId)
end

-- Local values: object, uniqueUserId, player, _, missionPlayer
function EnterablePassengerEnterResponseEvent:run(connection)
	local v16_ = NetworkUtil.getObject(self.id)
	if v16_ ~= nil and v16_:getIsSynchronized() then
		local v17_ = g_currentMission.userManager:getUniqueUserIdByUserId(self.userId)
		local v18_ = nil
		for _, v19_ in pairs(g_currentMission.playerSystem.players) do
			if v19_.uniqueUserId == v17_ then
				v18_ = v19_
				break
			end
		end
		v18_:onEnterVehicleAsPassenger(v16_, self.seatIndex)
	end
end
