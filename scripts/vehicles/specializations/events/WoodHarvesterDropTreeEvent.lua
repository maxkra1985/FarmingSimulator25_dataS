-- Local values: WoodHarvesterDropTreeEvent_mt
WoodHarvesterDropTreeEvent = {}
local WoodHarvesterDropTreeEvent_mt = Class(WoodHarvesterDropTreeEvent, Event)
InitStaticEventClass(WoodHarvesterDropTreeEvent, "WoodHarvesterDropTreeEvent")
function WoodHarvesterDropTreeEvent.emptyNew()
	-- upvalues: (copy) WoodHarvesterDropTreeEvent_mt
	return Event.new(WoodHarvesterDropTreeEvent_mt)
end

-- Local values: self
function WoodHarvesterDropTreeEvent.new(object)
	local v3_ = WoodHarvesterDropTreeEvent.emptyNew()
	v3_.object = object
	return v3_
end

function WoodHarvesterDropTreeEvent:readStream(streamId, connection)
	self.object = NetworkUtil.readNodeObject(streamId)
	self:run(connection)
end

function WoodHarvesterDropTreeEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.object)
end

function WoodHarvesterDropTreeEvent:run(connection)
	if not connection:getIsServer() then
		g_server:broadcastEvent(WoodHarvesterDropTreeEvent.new(self.object), nil, connection, self.object)
	end
	if self.object ~= nil and self.object:getIsSynchronized() then
		self.object:dropWoodHarvesterTree(true)
	end
end

function WoodHarvesterDropTreeEvent.sendEvent(object, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			g_server:broadcastEvent(WoodHarvesterDropTreeEvent.new(object), nil, nil, object)
			return
		end
		g_client:getServerConnection():sendEvent(WoodHarvesterDropTreeEvent.new(object))
	end
end
