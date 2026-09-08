-- Local values: BaleUnpackEvent_mt
BaleUnpackEvent = {}
local BaleUnpackEvent_mt = Class(BaleUnpackEvent, Event)
InitStaticEventClass(BaleUnpackEvent, "BaleUnpackEvent")
function BaleUnpackEvent.emptyNew()
	-- upvalues: (copy) BaleUnpackEvent_mt
	return Event.new(BaleUnpackEvent_mt)
end

-- Local values: self
function BaleUnpackEvent.new(bale)
	local v3_ = BaleUnpackEvent.emptyNew()
	v3_.bale = bale
	return v3_
end

function BaleUnpackEvent:readStream(streamId, connection)
	if not connection:getIsServer() then
		self.bale = NetworkUtil.readNodeObject(streamId)
	end
	self:run(connection)
end

function BaleUnpackEvent:writeStream(streamId, connection)
	if connection:getIsServer() then
		NetworkUtil.writeNodeObject(streamId, self.bale)
	end
end

function BaleUnpackEvent:run(connection)
	self.bale:unpack()
end
