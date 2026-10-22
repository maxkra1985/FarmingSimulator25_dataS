PlaceableFenceSegmentBatchEvent = {}
local PlaceableFenceSegmentBatchEvent_mt = Class(PlaceableFenceSegmentBatchEvent, Event)
InitStaticEventClass(PlaceableFenceSegmentBatchEvent, "PlaceableFenceSegmentBatchEvent")
PlaceableFenceSegmentBatchEvent.MAX_SEGMENTS = 32
function PlaceableFenceSegmentBatchEvent.emptyNew()
	local self = Event.new(PlaceableFenceSegmentBatchEvent_mt, NetworkNode.CHANNEL_MAIN)
	return self
end
function PlaceableFenceSegmentBatchEvent.new(fencePlaceable, segments)
	local self = PlaceableFenceSegmentBatchEvent.emptyNew()
	self.fencePlaceable = fencePlaceable
	self.segments = segments
	return self
end
function PlaceableFenceSegmentBatchEvent:readStream(streamId, connection)
	self.fencePlaceable = NetworkUtil.readNodeObject(streamId)
	if self.fencePlaceable == nil or self.fencePlaceable.createSegment == nil then
		Logging.error("PlaceableFenceSegmentBatchEvent received for an unknown fence placeable")
		return
	end
	local numSegments = streamReadUInt8(streamId)
	self.segments = {}
	for i = 1, numSegments do
		local x1 = streamReadFloat32(streamId)
		local z1 = streamReadFloat32(streamId)
		local x2 = streamReadFloat32(streamId)
		local z2 = streamReadFloat32(streamId)
		local renderFirst = streamReadBool(streamId)
		local renderLast = streamReadBool(streamId)
		local segment = self.fencePlaceable:createSegment(x1, z1, x2, z2, renderFirst, nil)
		segment.renderLast = renderLast
		self.segments[i] = segment
	end
	self:run(connection)
end
function PlaceableFenceSegmentBatchEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.fencePlaceable)
	streamWriteUInt8(streamId, #self.segments)
	for _, segment in ipairs(self.segments) do
		streamWriteFloat32(streamId, segment.x1)
		streamWriteFloat32(streamId, segment.z1)
		streamWriteFloat32(streamId, segment.x2)
		streamWriteFloat32(streamId, segment.z2)
		streamWriteBool(streamId, segment.renderFirst)
		streamWriteBool(streamId, segment.renderLast)
	end
end
function PlaceableFenceSegmentBatchEvent:run(connection)
	if not connection:getIsServer() then
		return
	end
	if not self.fencePlaceable:getIsSynchronized() then
		return
	end
	for _, segment in ipairs(self.segments) do
		self.fencePlaceable:addSegment(segment, false)
		g_messageCenter:publish(PlaceableFenceAddSegmentEvent, self.fencePlaceable, segment)
	end
end
