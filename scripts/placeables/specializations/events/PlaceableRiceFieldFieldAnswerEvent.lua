-- Local values: PlaceableRiceFieldFieldAnswerEvent_mt
PlaceableRiceFieldFieldAnswerEvent = {}
local PlaceableRiceFieldFieldAnswerEvent_mt = Class(PlaceableRiceFieldFieldAnswerEvent, Event)
InitStaticEventClass(PlaceableRiceFieldFieldAnswerEvent, "PlaceableRiceFieldFieldAnswerEvent")
function PlaceableRiceFieldFieldAnswerEvent.emptyNew()
	-- upvalues: (copy) PlaceableRiceFieldFieldAnswerEvent_mt
	return Event.new(PlaceableRiceFieldFieldAnswerEvent_mt, NetworkNode.CHANNEL_MAIN)
end

-- Local values: self
function PlaceableRiceFieldFieldAnswerEvent.new(placeableRiceField, statusCode)
	local v4_ = PlaceableRiceFieldFieldAnswerEvent.emptyNew()
	v4_.placeableRiceField = placeableRiceField
	v4_.statusCode = statusCode
	return v4_
end

function PlaceableRiceFieldFieldAnswerEvent:readStream(streamId, connection)
	self.placeableRiceField = NetworkUtil.readNodeObject(streamId)
	self.statusCode = streamReadUInt8(streamId)
	self:run(connection)
end

function PlaceableRiceFieldFieldAnswerEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.placeableRiceField)
	streamWriteUInt8(streamId, self.statusCode)
end

function PlaceableRiceFieldFieldAnswerEvent:run(connection)
	if self.placeableRiceField ~= nil and self.placeableRiceField:getIsSynchronized() then
		g_messageCenter:publish(PlaceableRiceFieldFieldAnswerEvent, self.statusCode)
	end
end
