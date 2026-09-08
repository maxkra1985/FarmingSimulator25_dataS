-- Local values: PlowPackerStateEvent_mt
PlowPackerStateEvent = {}
local PlowPackerStateEvent_mt = Class(PlowPackerStateEvent, Event)
InitStaticEventClass(PlowPackerStateEvent, "PlowPackerStateEvent")
function PlowPackerStateEvent.emptyNew()
	-- upvalues: (copy) PlowPackerStateEvent_mt
	return Event.new(PlowPackerStateEvent_mt)
end

-- Local values: self
function PlowPackerStateEvent.new(object, state, updateAnimations)
	local v5_ = PlowPackerStateEvent.emptyNew()
	v5_.object = object
	v5_.state = state
	v5_.updateAnimations = updateAnimations
	return v5_
end

function PlowPackerStateEvent:readStream(streamId, connection)
	self.object = NetworkUtil.readNodeObject(streamId)
	self.state = streamReadBool(streamId)
	self.updateAnimations = streamReadBool(streamId)
	self:run(connection)
end

function PlowPackerStateEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.object)
	streamWriteBool(streamId, self.state)
	streamWriteBool(streamId, self.updateAnimations)
end

function PlowPackerStateEvent:run(connection)
	if not connection:getIsServer() then
		g_server:broadcastEvent(self, false, connection, self.object)
	end
	if self.object ~= nil and self.object:getIsSynchronized() then
		self.object:setPackerState(self.state, self.updateAnimations, true)
	end
end

function PlowPackerStateEvent.sendEvent(object, state, updateAnimations, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			g_server:broadcastEvent(PlowPackerStateEvent.new(object, state, updateAnimations), nil, nil, object)
			return
		end
		g_client:getServerConnection():sendEvent(PlowPackerStateEvent.new(object, state, updateAnimations))
	end
end
