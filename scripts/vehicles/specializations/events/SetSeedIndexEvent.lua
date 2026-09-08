-- Local values: SetSeedIndexEvent_mt
SetSeedIndexEvent = {}
local SetSeedIndexEvent_mt = Class(SetSeedIndexEvent, Event)
InitStaticEventClass(SetSeedIndexEvent, "SetSeedIndexEvent")
function SetSeedIndexEvent.emptyNew()
	-- upvalues: (copy) SetSeedIndexEvent_mt
	return Event.new(SetSeedIndexEvent_mt)
end

-- Local values: self
function SetSeedIndexEvent.new(object, seedIndex)
	local v4_ = SetSeedIndexEvent.emptyNew()
	v4_.object = object
	v4_.seedIndex = seedIndex
	return v4_
end

function SetSeedIndexEvent:readStream(streamId, connection)
	self.object = NetworkUtil.readNodeObject(streamId)
	self.seedIndex = streamReadUInt8(streamId)
	self:run(connection)
end

function SetSeedIndexEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.object)
	streamWriteUInt8(streamId, self.seedIndex)
end

function SetSeedIndexEvent:run(connection)
	if not connection:getIsServer() then
		g_server:broadcastEvent(self, false, connection, self.object)
	end
	if self.object ~= nil and self.object:getIsSynchronized() then
		self.object:setSeedIndex(self.seedIndex, true)
	end
end

function SetSeedIndexEvent.sendEvent(object, seedIndex, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			g_server:broadcastEvent(SetSeedIndexEvent.new(object, seedIndex), nil, nil, object)
			return
		end
		g_client:getServerConnection():sendEvent(SetSeedIndexEvent.new(object, seedIndex))
	end
end
