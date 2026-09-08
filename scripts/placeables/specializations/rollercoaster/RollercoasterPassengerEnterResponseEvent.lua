-- Local values: RollercoasterPassengerEnterResponseEvent_mt
RollercoasterPassengerEnterResponseEvent = {}
local RollercoasterPassengerEnterResponseEvent_mt = Class(RollercoasterPassengerEnterResponseEvent, Event)
InitStaticEventClass(RollercoasterPassengerEnterResponseEvent, "RollercoasterPassengerEnterResponseEvent")
function RollercoasterPassengerEnterResponseEvent.emptyNew()
	-- upvalues: (copy) RollercoasterPassengerEnterResponseEvent_mt
	return Event.new(RollercoasterPassengerEnterResponseEvent_mt)
end

-- Local values: self
function RollercoasterPassengerEnterResponseEvent.new(rollercoaster, userId, seatIndex)
	local v5_ = RollercoasterPassengerEnterResponseEvent.emptyNew()
	v5_.rollercoaster = rollercoaster
	v5_.userId = userId
	v5_.seatIndex = seatIndex
	return v5_
end

function RollercoasterPassengerEnterResponseEvent:readStream(streamId, connection)
	self.rollercoaster = NetworkUtil.readNodeObject(streamId)
	self.userId = User.streamReadUserId(streamId)
	self.seatIndex = streamReadUIntN(streamId, PlaceableRollercoaster.SEAT_INDEX_NUM_BITS) + 1
	self:run(connection)
end

function RollercoasterPassengerEnterResponseEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.rollercoaster)
	User.streamWriteUserId(streamId, self.userId)
	streamWriteUIntN(streamId, self.seatIndex - 1, PlaceableRollercoaster.SEAT_INDEX_NUM_BITS)
end

-- Local values: uniqueUserId, player, _, missionPlayer
function RollercoasterPassengerEnterResponseEvent:run(connection)
	if self.rollercoaster ~= nil and self.rollercoaster:getIsSynchronized() then
		local v12_ = g_currentMission.userManager:getUniqueUserIdByUserId(self.userId)
		local v13_ = nil
		for _, v14_ in pairs(g_currentMission.playerSystem.players) do
			if v14_.uniqueUserId == v12_ then
				v13_ = v14_
				break
			end
		end
		v13_:onEnterRollercoaster(self.rollercoaster, self.seatIndex)
	end
end
