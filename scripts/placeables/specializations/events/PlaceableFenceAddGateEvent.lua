-- Local values: PlaceableFenceAddGateEvent_mt
PlaceableFenceAddGateEvent = {}
local PlaceableFenceAddGateEvent_mt = Class(PlaceableFenceAddGateEvent, Event)
InitStaticEventClass(PlaceableFenceAddGateEvent, "PlaceableFenceAddGateEvent")
function PlaceableFenceAddGateEvent.emptyNew()
	-- upvalues: (copy) PlaceableFenceAddGateEvent_mt
	return Event.new(PlaceableFenceAddGateEvent_mt)
end

-- Local values: self
function PlaceableFenceAddGateEvent.new(fence, segmentIndex, animatedObject)
	local v5_ = PlaceableFenceAddGateEvent.emptyNew()
	v5_.fence = fence
	v5_.segmentIndex = segmentIndex
	v5_.animatedObject = animatedObject
	return v5_
end

-- Local values: animatedObjectId
function PlaceableFenceAddGateEvent:readStream(streamId, connection)
	self.fence = NetworkUtil.readNodeObject(streamId)
	self.segmentIndex = streamReadInt32(streamId)
	self.animatedObject = self.fence:getSegment(self.segmentIndex).animatedObject
	local v9_ = NetworkUtil.readNodeObjectId(streamId)
	self.animatedObject:readStream(streamId, connection)
	g_client:finishRegisterObject(self.animatedObject, v9_)
	self:run(connection)
end

function PlaceableFenceAddGateEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.fence)
	streamWriteInt32(streamId, self.segmentIndex)
	NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(self.animatedObject))
	self.animatedObject:writeStream(streamId, connection)
	g_server:registerObjectInStream(connection, self.animatedObject)
end

function PlaceableFenceAddGateEvent:run(connection) end
