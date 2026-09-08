-- Local values: BaleWrapperAutomaticDropEvent_mt
BaleWrapperAutomaticDropEvent = {}
local BaleWrapperAutomaticDropEvent_mt = Class(BaleWrapperAutomaticDropEvent, Event)
InitStaticEventClass(BaleWrapperAutomaticDropEvent, "BaleWrapperAutomaticDropEvent")
function BaleWrapperAutomaticDropEvent.emptyNew()
	-- upvalues: (copy) BaleWrapperAutomaticDropEvent_mt
	return Event.new(BaleWrapperAutomaticDropEvent_mt)
end

-- Local values: self
function BaleWrapperAutomaticDropEvent.new(object, automaticDrop)
	local v4_ = BaleWrapperAutomaticDropEvent.emptyNew()
	v4_.object = object
	v4_.automaticDrop = automaticDrop
	return v4_
end

function BaleWrapperAutomaticDropEvent:readStream(streamId, connection)
	self.object = NetworkUtil.readNodeObject(streamId)
	self.automaticDrop = streamReadBool(streamId)
	self:run(connection)
end

function BaleWrapperAutomaticDropEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.object)
	streamWriteBool(streamId, self.automaticDrop)
end

function BaleWrapperAutomaticDropEvent:run(connection)
	if not connection:getIsServer() then
		g_server:broadcastEvent(self, false, connection, self.object)
	end
	if self.object ~= nil and self.object:getIsSynchronized() then
		self.object:setBaleWrapperAutomaticDrop(self.automaticDrop, true)
	end
end

function BaleWrapperAutomaticDropEvent.sendEvent(object, automaticDrop, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			g_server:broadcastEvent(BaleWrapperAutomaticDropEvent.new(object, automaticDrop), nil, nil, object)
			return
		end
		g_client:getServerConnection():sendEvent(BaleWrapperAutomaticDropEvent.new(object, automaticDrop))
	end
end
