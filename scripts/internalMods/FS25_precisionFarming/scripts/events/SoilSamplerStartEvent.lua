-- Local values: SoilSamplerStartEvent_mt
SoilSamplerStartEvent = {}
local SoilSamplerStartEvent_mt = Class(SoilSamplerStartEvent, Event)
InitEventClass(SoilSamplerStartEvent, "SoilSamplerStartEvent")
function SoilSamplerStartEvent.emptyNew()
	-- upvalues: (copy) SoilSamplerStartEvent_mt
	return Event.new(SoilSamplerStartEvent_mt)
end

-- Local values: self
function SoilSamplerStartEvent.new(object)
	local v3_ = SoilSamplerStartEvent.emptyNew()
	v3_.object = object
	return v3_
end

function SoilSamplerStartEvent:readStream(streamId, connection)
	self.object = NetworkUtil.readNodeObject(streamId)
	self:run(connection)
end

function SoilSamplerStartEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.object)
end

function SoilSamplerStartEvent:run(connection)
	if not connection:getIsServer() then
		g_server:broadcastEvent(self, false, connection, self.object)
	end
	if self.object ~= nil and self.object:getIsSynchronized() then
		self.object:startSoilSampling(true)
	end
end

function SoilSamplerStartEvent.sendEvent(object, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			g_server:broadcastEvent(SoilSamplerStartEvent.new(object), nil, nil, object)
			return
		end
		g_client:getServerConnection():sendEvent(SoilSamplerStartEvent.new(object))
	end
end
