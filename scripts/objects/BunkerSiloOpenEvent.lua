-- Local values: BunkerSiloOpenEvent_mt
BunkerSiloOpenEvent = {}
local BunkerSiloOpenEvent_mt = Class(BunkerSiloOpenEvent, Event)
InitStaticEventClass(BunkerSiloOpenEvent, "BunkerSiloOpenEvent")
function BunkerSiloOpenEvent.emptyNew()
	-- upvalues: (copy) BunkerSiloOpenEvent_mt
	return Event.new(BunkerSiloOpenEvent_mt)
end

-- Local values: self
function BunkerSiloOpenEvent.new(bunkerSilo, x, y, z)
	local v6_ = BunkerSiloOpenEvent.emptyNew()
	v6_.bunkerSilo = bunkerSilo
	v6_.x = x
	v6_.y = y
	v6_.z = z
	return v6_
end

function BunkerSiloOpenEvent:readStream(streamId, connection)
	if not connection:getIsServer() then
		self.bunkerSilo = NetworkUtil.readNodeObject(streamId)
		self.x = streamReadFloat32(streamId)
		self.y = streamReadFloat32(streamId)
		self.z = streamReadFloat32(streamId)
	end
	self:run(connection)
end

function BunkerSiloOpenEvent:writeStream(streamId, connection)
	if connection:getIsServer() then
		NetworkUtil.writeNodeObject(streamId, self.bunkerSilo)
		streamWriteFloat32(streamId, self.x)
		streamWriteFloat32(streamId, self.y)
		streamWriteFloat32(streamId, self.z)
	end
end

function BunkerSiloOpenEvent:run(connection)
	if not connection:getIsServer() then
		self.bunkerSilo:openSilo(self.x, self.y, self.z)
	end
end
