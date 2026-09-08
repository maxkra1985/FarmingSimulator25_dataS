-- Local values: WoodHarvesterCutTreeEvent_mt
WoodHarvesterCutTreeEvent = {}
local WoodHarvesterCutTreeEvent_mt = Class(WoodHarvesterCutTreeEvent, Event)
InitStaticEventClass(WoodHarvesterCutTreeEvent, "WoodHarvesterCutTreeEvent")
function WoodHarvesterCutTreeEvent.emptyNew()
	-- upvalues: (copy) WoodHarvesterCutTreeEvent_mt
	return Event.new(WoodHarvesterCutTreeEvent_mt)
end

-- Local values: self
function WoodHarvesterCutTreeEvent.new(object, length)
	local v4_ = WoodHarvesterCutTreeEvent.emptyNew()
	v4_.object = object
	v4_.length = length
	return v4_
end

function WoodHarvesterCutTreeEvent:readStream(streamId, connection)
	self.object = NetworkUtil.readNodeObject(streamId)
	self.length = streamReadFloat32(streamId)
	self:run(connection)
end

function WoodHarvesterCutTreeEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.object)
	streamWriteFloat32(streamId, self.length)
end

function WoodHarvesterCutTreeEvent:run(connection)
	if not connection:getIsServer() then
		g_server:broadcastEvent(WoodHarvesterCutTreeEvent.new(self.object, self.length), nil, connection, self.object)
	end
	if self.object ~= nil and self.object:getIsSynchronized() then
		self.object:cutTree(self.length, true)
	end
end

function WoodHarvesterCutTreeEvent.sendEvent(object, length, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			g_server:broadcastEvent(WoodHarvesterCutTreeEvent.new(object, length), nil, nil, object)
			return
		end
		g_client:getServerConnection():sendEvent(WoodHarvesterCutTreeEvent.new(object, length))
	end
end
