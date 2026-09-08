-- Local values: CropSensorStateEvent_mt
CropSensorStateEvent = {}
local CropSensorStateEvent_mt = Class(CropSensorStateEvent, Event)
InitEventClass(CropSensorStateEvent, "CropSensorStateEvent")
function CropSensorStateEvent.emptyNew()
	-- upvalues: (copy) CropSensorStateEvent_mt
	return Event.new(CropSensorStateEvent_mt)
end

-- Local values: self
function CropSensorStateEvent.new(object, state)
	local v4_ = CropSensorStateEvent.emptyNew()
	v4_.object = object
	v4_.state = state
	return v4_
end

function CropSensorStateEvent:readStream(streamId, connection)
	self.object = NetworkUtil.readNodeObject(streamId)
	self.state = streamReadBool(streamId)
	self:run(connection)
end

function CropSensorStateEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.object)
	streamWriteBool(streamId, self.state)
end

function CropSensorStateEvent:run(connection)
	if not connection:getIsServer() then
		g_server:broadcastEvent(self, false, connection, self.object)
	end
	if self.object ~= nil and self.object:getIsSynchronized() then
		self.object:setCropSensorActive(self.state, true)
	end
end

function CropSensorStateEvent.sendEvent(object, state, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			g_server:broadcastEvent(CropSensorStateEvent.new(object, state), nil, nil, object)
			return
		end
		g_client:getServerConnection():sendEvent(CropSensorStateEvent.new(object, state))
	end
end
