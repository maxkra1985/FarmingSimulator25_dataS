-- Local values: InlineBaleOpenEvent_mt
InlineBaleOpenEvent = {}
local InlineBaleOpenEvent_mt = Class(InlineBaleOpenEvent, Event)
InitStaticEventClass(InlineBaleOpenEvent, "InlineBaleOpenEvent")
function InlineBaleOpenEvent.emptyNew()
	-- upvalues: (copy) InlineBaleOpenEvent_mt
	return Event.new(InlineBaleOpenEvent_mt)
end

-- Local values: self
function InlineBaleOpenEvent.new(inlineBale, x, y, z)
	local v6_ = InlineBaleOpenEvent.emptyNew()
	v6_.inlineBale = inlineBale
	v6_.x = x
	v6_.y = y
	v6_.z = z
	return v6_
end

function InlineBaleOpenEvent:readStream(streamId, connection)
	if not connection:getIsServer() then
		self.inlineBale = NetworkUtil.readNodeObject(streamId)
		self.x = streamReadFloat32(streamId)
		self.y = streamReadFloat32(streamId)
		self.z = streamReadFloat32(streamId)
	end
	self:run(connection)
end

function InlineBaleOpenEvent:writeStream(streamId, connection)
	if connection:getIsServer() then
		NetworkUtil.writeNodeObject(streamId, self.inlineBale)
		streamWriteFloat32(streamId, self.x)
		streamWriteFloat32(streamId, self.y)
		streamWriteFloat32(streamId, self.z)
	end
end

function InlineBaleOpenEvent:run(connection)
	if not connection:getIsServer() then
		self.inlineBale:openBaleAtPosition(self.x, self.y, self.z)
	end
end
