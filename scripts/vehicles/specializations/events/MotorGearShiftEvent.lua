-- Local values: MotorGearShiftEvent_mt
MotorGearShiftEvent = {}
MotorGearShiftEvent.TYPE_SHIFT_UP = 1
MotorGearShiftEvent.TYPE_SHIFT_DOWN = 2
MotorGearShiftEvent.TYPE_SELECT_GEAR = 3
MotorGearShiftEvent.TYPE_SHIFT_GROUP_UP = 4
MotorGearShiftEvent.TYPE_SHIFT_GROUP_DOWN = 5
MotorGearShiftEvent.TYPE_SELECT_GROUP = 6
MotorGearShiftEvent.TYPE_DIRECTION_CHANGE = 7
MotorGearShiftEvent.TYPE_DIRECTION_CHANGE_POS = 8
MotorGearShiftEvent.TYPE_DIRECTION_CHANGE_NEG = 9
local MotorGearShiftEvent_mt = Class(MotorGearShiftEvent, Event)
InitStaticEventClass(MotorGearShiftEvent, "MotorGearShiftEvent")
function MotorGearShiftEvent.emptyNew()
	-- upvalues: (copy) MotorGearShiftEvent_mt
	return Event.new(MotorGearShiftEvent_mt)
end

-- Local values: self
function MotorGearShiftEvent.new(vehicle, shiftType, shiftValue)
	local v5_ = MotorGearShiftEvent.emptyNew()
	v5_.vehicle = vehicle
	v5_.shiftType = shiftType
	v5_.shiftValue = shiftValue
	return v5_
end

function MotorGearShiftEvent:readStream(streamId, connection)
	self.vehicle = NetworkUtil.readNodeObject(streamId)
	self.shiftType = streamReadUIntN(streamId, 4)
	if self.shiftType == MotorGearShiftEvent.TYPE_SELECT_GEAR or self.shiftType == MotorGearShiftEvent.TYPE_SELECT_GROUP then
		self.shiftValue = streamReadUIntN(streamId, 5)
	end
	self:run(connection)
end

function MotorGearShiftEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.vehicle)
	streamWriteUIntN(streamId, self.shiftType, 4)
	if self.shiftType == MotorGearShiftEvent.TYPE_SELECT_GEAR or self.shiftType == MotorGearShiftEvent.TYPE_SELECT_GROUP then
		streamWriteUIntN(streamId, self.shiftValue, 5)
	end
end

-- Local values: vehicle, spec
function MotorGearShiftEvent:run(connection)
	local v12_ = self.vehicle
	if v12_ ~= nil and v12_:getIsSynchronized() then
		local v13_ = v12_.spec_motorized
		if v13_ ~= nil then
			if self.shiftType == MotorGearShiftEvent.TYPE_SHIFT_UP then
				v13_.motor:shiftGear(true)
				return
			end
			if self.shiftType == MotorGearShiftEvent.TYPE_SHIFT_DOWN then
				v13_.motor:shiftGear(false)
				return
			end
			if self.shiftType == MotorGearShiftEvent.TYPE_SELECT_GEAR then
				v13_.motor:selectGear(self.shiftValue, self.shiftValue ~= 0)
				return
			end
			if self.shiftType == MotorGearShiftEvent.TYPE_SHIFT_GROUP_UP then
				v13_.motor:shiftGroup(true)
				return
			end
			if self.shiftType == MotorGearShiftEvent.TYPE_SHIFT_GROUP_DOWN then
				v13_.motor:shiftGroup(false)
				return
			end
			if self.shiftType == MotorGearShiftEvent.TYPE_SELECT_GROUP then
				v13_.motor:selectGroup(self.shiftValue, self.shiftValue ~= 0)
				return
			end
			if self.shiftType == MotorGearShiftEvent.TYPE_DIRECTION_CHANGE then
				v13_.motor:changeDirection()
				return
			end
			if self.shiftType == MotorGearShiftEvent.TYPE_DIRECTION_CHANGE_POS then
				v13_.motor:changeDirection(1)
				return
			end
			if self.shiftType == MotorGearShiftEvent.TYPE_DIRECTION_CHANGE_NEG then
				v13_.motor:changeDirection(-1)
			end
		end
	end
end

function MotorGearShiftEvent.sendToServer(vehicle, shiftType, shiftValue)
	if g_client ~= nil then
		g_client:getServerConnection():sendEvent(MotorGearShiftEvent.new(vehicle, shiftType, shiftValue))
	end
end
