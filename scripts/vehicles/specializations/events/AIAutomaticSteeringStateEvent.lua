-- Local values: AIAutomaticSteeringStateEvent_mt
AIAutomaticSteeringStateEvent = {}
local AIAutomaticSteeringStateEvent_mt = Class(AIAutomaticSteeringStateEvent, Event)
InitStaticEventClass(AIAutomaticSteeringStateEvent, "AIAutomaticSteeringStateEvent")
function AIAutomaticSteeringStateEvent.emptyNew()
	-- upvalues: (copy) AIAutomaticSteeringStateEvent_mt
	return Event.new(AIAutomaticSteeringStateEvent_mt)
end

-- Local values: self
function AIAutomaticSteeringStateEvent.new(vehicle, state, segmentIndex, segmentIsLeft)
	local v6_ = AIAutomaticSteeringStateEvent.emptyNew()
	v6_.vehicle = vehicle
	v6_.state = state
	v6_.segmentIndex = segmentIndex
	v6_.segmentIsLeft = segmentIsLeft
	return v6_
end

function AIAutomaticSteeringStateEvent:readStream(streamId, connection)
	self.vehicle = NetworkUtil.readNodeObject(streamId)
	self.state = streamReadBool(streamId)
	if streamReadBool(streamId) then
		self.segmentIndex = streamReadUInt16(streamId)
		self.segmentIsLeft = streamReadBool(streamId)
	end
	self:run(connection)
end

function AIAutomaticSteeringStateEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.vehicle)
	streamWriteBool(streamId, self.state)
	local v12_ = streamWriteBool
	local v13_
	if self.segmentIndex == nil then
		v13_ = false
	else
		v13_ = self.segmentIndex > 0
	end
	if v12_(streamId, v13_) then
		streamWriteUInt16(streamId, self.segmentIndex)
		streamWriteBool(streamId, Utils.getNoNil(self.segmentIsLeft, false))
	end
end

function AIAutomaticSteeringStateEvent:run(connection)
	if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
		local v16_, v17_ = self.vehicle:setAIAutomaticSteeringEnabled(self.state, self.segmentIndex, self.segmentIsLeft, true)
		self.segmentIndex = v16_
		self.segmentIsLeft = v17_
	end
	if not connection:getIsServer() then
		g_server:broadcastEvent(AIAutomaticSteeringStateEvent.new(self.vehicle, self.state, self.segmentIndex, self.segmentIsLeft), nil, nil, self.vehicle)
	end
end

function AIAutomaticSteeringStateEvent.sendEvent(vehicle, state, segmentIndex, segmentIsLeft, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			g_server:broadcastEvent(AIAutomaticSteeringStateEvent.new(vehicle, state, segmentIndex, segmentIsLeft), nil, nil, vehicle)
			return
		end
		g_client:getServerConnection():sendEvent(AIAutomaticSteeringStateEvent.new(vehicle, state, segmentIndex, segmentIsLeft))
	end
end
