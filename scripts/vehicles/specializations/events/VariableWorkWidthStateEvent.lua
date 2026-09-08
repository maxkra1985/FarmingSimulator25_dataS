-- Local values: VariableWorkWidthStateEvent_mt
VariableWorkWidthStateEvent = {}
local VariableWorkWidthStateEvent_mt = Class(VariableWorkWidthStateEvent, Event)
InitStaticEventClass(VariableWorkWidthStateEvent, "VariableWorkWidthStateEvent")
function VariableWorkWidthStateEvent.emptyNew()
	-- upvalues: (copy) VariableWorkWidthStateEvent_mt
	return Event.new(VariableWorkWidthStateEvent_mt)
end

-- Local values: self
function VariableWorkWidthStateEvent.new(vehicle, leftSide, rightSide)
	local v5_ = VariableWorkWidthStateEvent.emptyNew()
	v5_.vehicle = vehicle
	v5_.leftSide = leftSide
	v5_.rightSide = rightSide
	return v5_
end

function VariableWorkWidthStateEvent:readStream(streamId, connection)
	self.vehicle = NetworkUtil.readNodeObject(streamId)
	self.leftSide = streamReadUIntN(streamId, VariableWorkWidth.SEND_NUM_BITS)
	self.rightSide = streamReadUIntN(streamId, VariableWorkWidth.SEND_NUM_BITS)
	self:run(connection)
end

function VariableWorkWidthStateEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.vehicle)
	streamWriteUIntN(streamId, self.leftSide, VariableWorkWidth.SEND_NUM_BITS)
	streamWriteUIntN(streamId, self.rightSide, VariableWorkWidth.SEND_NUM_BITS)
end

function VariableWorkWidthStateEvent:run(connection)
	if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
		self.vehicle:setSectionsActive(self.leftSide, self.rightSide, true)
	end
	if not connection:getIsServer() then
		g_server:broadcastEvent(VariableWorkWidthStateEvent.new(self.vehicle, self.leftSide, self.rightSide), nil, connection, self.object)
	end
end

function VariableWorkWidthStateEvent.sendEvent(vehicle, leftSide, rightSide, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			g_server:broadcastEvent(VariableWorkWidthStateEvent.new(vehicle, leftSide, rightSide), nil, nil, vehicle)
			return
		end
		g_client:getServerConnection():sendEvent(VariableWorkWidthStateEvent.new(vehicle, leftSide, rightSide))
	end
end
