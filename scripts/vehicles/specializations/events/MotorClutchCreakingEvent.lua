-- Local values: MotorClutchCreakingEvent_mt
MotorClutchCreakingEvent = {}
local MotorClutchCreakingEvent_mt = Class(MotorClutchCreakingEvent, Event)
InitStaticEventClass(MotorClutchCreakingEvent, "MotorClutchCreakingEvent")
function MotorClutchCreakingEvent.emptyNew()
	-- upvalues: (copy) MotorClutchCreakingEvent_mt
	return Event.new(MotorClutchCreakingEvent_mt)
end

-- Local values: self
function MotorClutchCreakingEvent.new(vehicle, isEvent, groupTransmission, gearIndex, groupIndex)
	local v7_ = MotorClutchCreakingEvent.emptyNew()
	v7_.vehicle = vehicle
	v7_.isEvent = isEvent
	v7_.groupTransmission = groupTransmission
	v7_.gearIndex = gearIndex
	v7_.groupIndex = groupIndex
	return v7_
end

function MotorClutchCreakingEvent:readStream(streamId, connection)
	self.vehicle = NetworkUtil.readNodeObject(streamId)
	self.isEvent = streamReadBool(streamId)
	self.groupTransmission = streamReadBool(streamId)
	if streamReadBool(streamId) then
		self.gearIndex = streamReadUIntN(streamId, 6)
	end
	if streamReadBool(streamId) then
		self.groupIndex = streamReadUIntN(streamId, 5)
	end
	self:run(connection)
end

function MotorClutchCreakingEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.vehicle)
	streamWriteBool(streamId, self.isEvent)
	streamWriteBool(streamId, self.groupTransmission)
	if streamWriteBool(streamId, self.gearIndex ~= nil) then
		streamWriteUIntN(streamId, self.gearIndex, 6)
	end
	if streamWriteBool(streamId, self.groupIndex ~= nil) then
		streamWriteUIntN(streamId, self.groupIndex, 5)
	end
end

-- Local values: vehicle
function MotorClutchCreakingEvent:run(connection)
	local v14_ = self.vehicle
	if v14_ ~= nil and v14_:getIsSynchronized() then
		SpecializationUtil.raiseEvent(self.vehicle, "onClutchCreaking", self.isEvent, self.groupTransmission, self.gearIndex, self.groupIndex)
	end
end
