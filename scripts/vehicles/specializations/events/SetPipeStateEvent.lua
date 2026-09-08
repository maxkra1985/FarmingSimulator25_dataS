-- Local values: SetPipeStateEvent_mt
SetPipeStateEvent = {}
local SetPipeStateEvent_mt = Class(SetPipeStateEvent, Event)
InitStaticEventClass(SetPipeStateEvent, "SetPipeStateEvent")
function SetPipeStateEvent.emptyNew()
	-- upvalues: (copy) SetPipeStateEvent_mt
	return Event.new(SetPipeStateEvent_mt)
end

-- Local values: self
function SetPipeStateEvent.new(object, pipeState)
	local v4_ = SetPipeStateEvent.emptyNew()
	v4_.object = object
	v4_.pipeState = pipeState
	local v5_
	if v4_.pipeState >= 0 then
		v5_ = v4_.pipeState < 8
	else
		v5_ = false
	end
	assert(v5_)
	return v4_
end

function SetPipeStateEvent:readStream(streamId, connection)
	self.object = NetworkUtil.readNodeObject(streamId)
	self.pipeState = streamReadUIntN(streamId, 3)
	self:run(connection)
end

function SetPipeStateEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.object)
	streamWriteUIntN(streamId, self.pipeState, 3)
end

function SetPipeStateEvent:run(connection)
	if self.object ~= nil and self.object:getIsSynchronized() then
		self.object:setPipeState(self.pipeState, true)
	end
	if not connection:getIsServer() then
		g_server:broadcastEvent(SetPipeStateEvent.new(self.object, self.pipeState), nil, connection, self.object)
	end
end
