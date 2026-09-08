-- Local values: WoodHarvesterHeaderTiltEvent_mt
WoodHarvesterHeaderTiltEvent = {}
local WoodHarvesterHeaderTiltEvent_mt = Class(WoodHarvesterHeaderTiltEvent, Event)
InitStaticEventClass(WoodHarvesterHeaderTiltEvent, "WoodHarvesterHeaderTiltEvent")
function WoodHarvesterHeaderTiltEvent.emptyNew()
	-- upvalues: (copy) WoodHarvesterHeaderTiltEvent_mt
	return Event.new(WoodHarvesterHeaderTiltEvent_mt)
end

-- Local values: self
function WoodHarvesterHeaderTiltEvent.new(object, state)
	local v4_ = WoodHarvesterHeaderTiltEvent.emptyNew()
	v4_.object = object
	v4_.state = state
	return v4_
end

function WoodHarvesterHeaderTiltEvent:readStream(streamId, connection)
	self.object = NetworkUtil.readNodeObject(streamId)
	self.state = streamReadBool(streamId)
	self:run(connection)
end

function WoodHarvesterHeaderTiltEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.object)
	streamWriteBool(streamId, self.state)
end

function WoodHarvesterHeaderTiltEvent:run(connection)
	if self.object ~= nil and self.object:getIsSynchronized() then
		self.object:setWoodHarvesterTiltState(self.state, true)
	end
end

function WoodHarvesterHeaderTiltEvent.sendEvent(object, state, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			g_server:broadcastEvent(WoodHarvesterHeaderTiltEvent.new(object, state), nil, nil, object)
			return
		end
		g_client:getServerConnection():sendEvent(WoodHarvesterHeaderTiltEvent.new(object, state))
	end
end
