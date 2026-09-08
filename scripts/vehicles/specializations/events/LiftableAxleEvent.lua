-- Local values: LiftableAxleEvent_mt
LiftableAxleEvent = {}
local LiftableAxleEvent_mt = Class(LiftableAxleEvent, Event)
InitStaticEventClass(LiftableAxleEvent, "LiftableAxleEvent")
function LiftableAxleEvent.emptyNew()
	-- upvalues: (copy) LiftableAxleEvent_mt
	return Event.new(LiftableAxleEvent_mt)
end

-- Local values: self
function LiftableAxleEvent.new(object, state, fixedHeight)
	local v5_ = LiftableAxleEvent.emptyNew()
	v5_.object = object
	v5_.state = state
	v5_.fixedHeight = fixedHeight
	return v5_
end

function LiftableAxleEvent:readStream(streamId, connection)
	self.object = NetworkUtil.readNodeObject(streamId)
	self.state = streamReadBool(streamId)
	if streamReadBool(streamId) then
		self.fixedHeight = streamReadFloat32(streamId)
	else
		self.fixedHeight = nil
	end
	self:run(connection)
end

function LiftableAxleEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.object)
	streamWriteBool(streamId, self.state)
	if streamWriteBool(streamId, self.fixedHeight ~= nil) then
		streamWriteFloat32(streamId, self.fixedHeight)
	end
end

function LiftableAxleEvent:run(connection)
	if self.object ~= nil and self.object:getIsSynchronized() then
		self.object:setLiftableAxleState(self.state, self.fixedHeight, nil, true)
	end
end

function LiftableAxleEvent.sendEvent(object, state, fixedHeight, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			g_server:broadcastEvent(LiftableAxleEvent.new(object, state, fixedHeight), nil, nil, object)
			return
		end
		g_client:getServerConnection():sendEvent(LiftableAxleEvent.new(object, state, fixedHeight))
	end
end
