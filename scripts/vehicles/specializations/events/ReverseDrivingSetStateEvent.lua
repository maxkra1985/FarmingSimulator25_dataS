-- Local values: ReverseDrivingSetStateEvent_mt
ReverseDrivingSetStateEvent = {}
local ReverseDrivingSetStateEvent_mt = Class(ReverseDrivingSetStateEvent, Event)
InitStaticEventClass(ReverseDrivingSetStateEvent, "ReverseDrivingSetStateEvent")
function ReverseDrivingSetStateEvent.emptyNew()
	-- upvalues: (copy) ReverseDrivingSetStateEvent_mt
	return Event.new(ReverseDrivingSetStateEvent_mt)
end

-- Local values: self
function ReverseDrivingSetStateEvent.new(vehicle, isReverseDriving)
	local v4_ = ReverseDrivingSetStateEvent.emptyNew()
	v4_.vehicle = vehicle
	v4_.isReverseDriving = isReverseDriving
	return v4_
end

function ReverseDrivingSetStateEvent:readStream(streamId, connection)
	self.vehicle = NetworkUtil.readNodeObject(streamId)
	self.isReverseDriving = streamReadBool(streamId)
	self:run(connection)
end

function ReverseDrivingSetStateEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.vehicle)
	streamWriteBool(streamId, self.isReverseDriving)
end

function ReverseDrivingSetStateEvent:run(connection)
	if not connection:getIsServer() then
		g_server:broadcastEvent(self, false, connection, self.vehicle)
	end
	if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
		self.vehicle:setIsReverseDriving(self.isReverseDriving, true)
	end
end

function ReverseDrivingSetStateEvent.sendEvent(vehicle, isReverseDriving, noEventSend)
	if isReverseDriving ~= vehicle.isReverseDriving and (noEventSend == nil or noEventSend == false) then
		if g_server ~= nil then
			g_server:broadcastEvent(ReverseDrivingSetStateEvent.new(vehicle, isReverseDriving), nil, nil, vehicle)
			return
		end
		g_client:getServerConnection():sendEvent(ReverseDrivingSetStateEvent.new(vehicle, isReverseDriving))
	end
end
