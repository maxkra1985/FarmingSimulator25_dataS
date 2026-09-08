-- Local values: ReceivingHopperSetCreateBoxesEvent_mt
ReceivingHopperSetCreateBoxesEvent = {}
local ReceivingHopperSetCreateBoxesEvent_mt = Class(ReceivingHopperSetCreateBoxesEvent, Event)
InitStaticEventClass(ReceivingHopperSetCreateBoxesEvent, "ReceivingHopperSetCreateBoxesEvent")
function ReceivingHopperSetCreateBoxesEvent.emptyNew()
	-- upvalues: (copy) ReceivingHopperSetCreateBoxesEvent_mt
	return Event.new(ReceivingHopperSetCreateBoxesEvent_mt)
end

-- Local values: self
function ReceivingHopperSetCreateBoxesEvent.new(object, state)
	local v4_ = ReceivingHopperSetCreateBoxesEvent.emptyNew()
	v4_.object = object
	v4_.state = state
	return v4_
end

function ReceivingHopperSetCreateBoxesEvent:readStream(streamId, connection)
	self.object = NetworkUtil.readNodeObject(streamId)
	self.state = streamReadBool(streamId)
	self:run(connection)
end

function ReceivingHopperSetCreateBoxesEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.object)
	streamWriteBool(streamId, self.state)
end

function ReceivingHopperSetCreateBoxesEvent:run(connection)
	if self.object ~= nil and self.object:getIsSynchronized() then
		self.object:setCreateBoxes(self.state, true)
	end
	if not connection:getIsServer() then
		g_server:broadcastEvent(ReceivingHopperSetCreateBoxesEvent.new(self.object, self.state), nil, connection, self.object)
	end
end

function ReceivingHopperSetCreateBoxesEvent.sendEvent(vehicle, state, noEventSend)
	if state ~= vehicle.state and (noEventSend == nil or noEventSend == false) then
		if g_server ~= nil then
			g_server:broadcastEvent(ReceivingHopperSetCreateBoxesEvent.new(vehicle, state), nil, nil, vehicle)
			return
		end
		g_client:getServerConnection():sendEvent(ReceivingHopperSetCreateBoxesEvent.new(vehicle, state))
	end
end
