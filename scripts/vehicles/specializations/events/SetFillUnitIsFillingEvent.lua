-- Local values: SetFillUnitIsFillingEvent_mt
SetFillUnitIsFillingEvent = {}
local SetFillUnitIsFillingEvent_mt = Class(SetFillUnitIsFillingEvent, Event)
InitStaticEventClass(SetFillUnitIsFillingEvent, "SetFillUnitIsFillingEvent")
function SetFillUnitIsFillingEvent.emptyNew()
	-- upvalues: (copy) SetFillUnitIsFillingEvent_mt
	return Event.new(SetFillUnitIsFillingEvent_mt)
end

-- Local values: self
function SetFillUnitIsFillingEvent.new(vehicle, isFilling)
	local v4_ = SetFillUnitIsFillingEvent.emptyNew()
	v4_.vehicle = vehicle
	v4_.isFilling = isFilling
	return v4_
end

function SetFillUnitIsFillingEvent:readStream(streamId, connection)
	self.vehicle = NetworkUtil.readNodeObject(streamId)
	self.isFilling = streamReadBool(streamId)
	self:run(connection)
end

function SetFillUnitIsFillingEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.vehicle)
	streamWriteBool(streamId, self.isFilling)
end

function SetFillUnitIsFillingEvent:run(connection)
	if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
		self.vehicle:setFillUnitIsFilling(self.isFilling, true)
	end
	if not connection:getIsServer() then
		g_server:broadcastEvent(SetFillUnitIsFillingEvent.new(self.vehicle, self.isFilling), nil, connection, self.vehicle)
	end
end
