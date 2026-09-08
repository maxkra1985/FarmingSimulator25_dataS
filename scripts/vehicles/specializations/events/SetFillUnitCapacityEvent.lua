-- Local values: SetFillUnitCapacityEvent_mt
SetFillUnitCapacityEvent = {}
local SetFillUnitCapacityEvent_mt = Class(SetFillUnitCapacityEvent, Event)
InitStaticEventClass(SetFillUnitCapacityEvent, "SetFillUnitCapacityEvent")
function SetFillUnitCapacityEvent.emptyNew()
	-- upvalues: (copy) SetFillUnitCapacityEvent_mt
	return Event.new(SetFillUnitCapacityEvent_mt)
end

-- Local values: self
function SetFillUnitCapacityEvent.new(vehicle, fillUnitIndex, capacity)
	local v5_ = SetFillUnitCapacityEvent.emptyNew()
	v5_.vehicle = vehicle
	v5_.fillUnitIndex = fillUnitIndex
	v5_.capacity = capacity
	return v5_
end

function SetFillUnitCapacityEvent:readStream(streamId, connection)
	self.vehicle = NetworkUtil.readNodeObject(streamId)
	self.fillUnitIndex = streamReadUIntN(streamId, 8)
	self.capacity = streamReadFloat32(streamId)
	self:run(connection)
end

function SetFillUnitCapacityEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.vehicle)
	streamWriteUIntN(streamId, self.fillUnitIndex, 8)
	streamWriteFloat32(streamId, self.capacity)
end

function SetFillUnitCapacityEvent:run(connection)
	if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
		self.vehicle:setFillUnitCapacity(self.fillUnitIndex, self.capacity, true)
	end
	if not connection:getIsServer() then
		g_server:broadcastEvent(SetFillUnitCapacityEvent.new(self.vehicle, self.fillUnitIndex, self.capacity), nil, connection, self.vehicle)
	end
end

function SetFillUnitCapacityEvent.sendEvent(vehicle, fillUnitIndex, capacity, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			g_server:broadcastEvent(SetFillUnitCapacityEvent.new(vehicle, fillUnitIndex, capacity), nil, nil, vehicle)
			return
		end
		g_client:getServerConnection():sendEvent(SetFillUnitCapacityEvent.new(vehicle, fillUnitIndex, capacity))
	end
end
