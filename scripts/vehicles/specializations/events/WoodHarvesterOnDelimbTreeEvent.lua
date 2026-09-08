-- Local values: WoodHarvesterOnDelimbTreeEvent_mt
WoodHarvesterOnDelimbTreeEvent = {}
local WoodHarvesterOnDelimbTreeEvent_mt = Class(WoodHarvesterOnDelimbTreeEvent, Event)
InitStaticEventClass(WoodHarvesterOnDelimbTreeEvent, "WoodHarvesterOnDelimbTreeEvent")
function WoodHarvesterOnDelimbTreeEvent.emptyNew()
	-- upvalues: (copy) WoodHarvesterOnDelimbTreeEvent_mt
	return Event.new(WoodHarvesterOnDelimbTreeEvent_mt)
end

-- Local values: self
function WoodHarvesterOnDelimbTreeEvent.new(object, state)
	local v4_ = WoodHarvesterOnDelimbTreeEvent.emptyNew()
	v4_.object = object
	v4_.state = state
	return v4_
end

function WoodHarvesterOnDelimbTreeEvent:readStream(streamId, connection)
	self.object = NetworkUtil.readNodeObject(streamId)
	self.state = streamReadBool(streamId)
	self:run(connection)
end

function WoodHarvesterOnDelimbTreeEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.object)
	streamWriteBool(streamId, self.state)
end

function WoodHarvesterOnDelimbTreeEvent:run(connection)
	if not connection:getIsServer() then
		g_server:broadcastEvent(WoodHarvesterOnDelimbTreeEvent.new(self.object, self.state), nil, connection, self.object)
	end
	if self.object ~= nil and self.object:getIsSynchronized() then
		self.object:onDelimbTree(self.state)
	end
end
