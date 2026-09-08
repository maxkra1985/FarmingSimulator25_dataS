-- Local values: HandsPickUpFailedEvent_mt
HandsPickUpFailedEvent = {}
local HandsPickUpFailedEvent_mt = Class(HandsPickUpFailedEvent, Event)
InitStaticEventClass(HandsPickUpFailedEvent, "HandsPickUpFailedEvent")
function HandsPickUpFailedEvent.emptyNew()
	-- upvalues: (copy) HandsPickUpFailedEvent_mt
	return Event.new(HandsPickUpFailedEvent_mt)
end

-- Local values: self
function HandsPickUpFailedEvent.new(hands)
	local v3_ = HandsPickUpFailedEvent.emptyNew()
	v3_.hands = hands
	return v3_
end

function HandsPickUpFailedEvent:readStream(streamId, connection)
	self.hands = NetworkUtil.readNodeObject(streamId)
	self:run(connection)
end

function HandsPickUpFailedEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.hands)
end

function HandsPickUpFailedEvent:run(connection)
	local v11_ = connection:getIsServer()
	assert(v11_, "HandsPickUpFailedEvent is a server to client only event")
	if self.hands ~= nil and self.hands:getIsSynchronized() then
		self.hands:pickupFailed()
	end
end
