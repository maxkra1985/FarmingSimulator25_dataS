-- Local values: BunkerSiloCloseEvent_mt
BunkerSiloCloseEvent = {}
local BunkerSiloCloseEvent_mt = Class(BunkerSiloCloseEvent, Event)
InitStaticEventClass(BunkerSiloCloseEvent, "BunkerSiloCloseEvent")
function BunkerSiloCloseEvent.emptyNew()
	-- upvalues: (copy) BunkerSiloCloseEvent_mt
	return Event.new(BunkerSiloCloseEvent_mt)
end

-- Local values: self
function BunkerSiloCloseEvent.new(bunkerSilo)
	local v3_ = BunkerSiloCloseEvent.emptyNew()
	v3_.bunkerSilo = bunkerSilo
	return v3_
end

function BunkerSiloCloseEvent:readStream(streamId, connection)
	if not connection:getIsServer() then
		self.bunkerSilo = NetworkUtil.readNodeObject(streamId)
	end
	self:run(connection)
end

function BunkerSiloCloseEvent:writeStream(streamId, connection)
	if connection:getIsServer() then
		NetworkUtil.writeNodeObject(streamId, self.bunkerSilo)
	end
end

function BunkerSiloCloseEvent:run(connection)
	if not connection:getIsServer() then
		self.bunkerSilo:setState(BunkerSilo.STATE_CLOSED)
	end
end
