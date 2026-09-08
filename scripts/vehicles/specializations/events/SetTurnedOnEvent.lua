-- Local values: SetTurnedOnEvent_mt
SetTurnedOnEvent = {}
local SetTurnedOnEvent_mt = Class(SetTurnedOnEvent, Event)
InitStaticEventClass(SetTurnedOnEvent, "SetTurnedOnEvent")
function SetTurnedOnEvent.emptyNew()
	-- upvalues: (copy) SetTurnedOnEvent_mt
	return Event.new(SetTurnedOnEvent_mt)
end

-- Local values: self
function SetTurnedOnEvent.new(object, isTurnedOn)
	local v4_ = SetTurnedOnEvent.emptyNew()
	v4_.object = object
	v4_.isTurnedOn = isTurnedOn
	return v4_
end

function SetTurnedOnEvent:readStream(streamId, connection)
	self.object = NetworkUtil.readNodeObject(streamId)
	self.isTurnedOn = streamReadBool(streamId)
	self:run(connection)
end

function SetTurnedOnEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.object)
	streamWriteBool(streamId, self.isTurnedOn)
end

function SetTurnedOnEvent:run(connection)
	if not connection:getIsServer() then
		g_server:broadcastEvent(self, false, connection, self.object)
	end
	if self.object ~= nil and self.object:getIsSynchronized() then
		self.object:setIsTurnedOn(self.isTurnedOn, true)
	end
end

function SetTurnedOnEvent.sendEvent(vehicle, isTurnedOn, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			g_server:broadcastEvent(SetTurnedOnEvent.new(vehicle, isTurnedOn), nil, nil, vehicle)
			return
		end
		g_client:getServerConnection():sendEvent(SetTurnedOnEvent.new(vehicle, isTurnedOn))
	end
end
