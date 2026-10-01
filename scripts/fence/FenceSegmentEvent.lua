FenceSegmentEvent = {}
local FenceSegmentEvent_mt = Class(FenceSegmentEvent, Event)
InitStaticEventClass(FenceSegmentEvent, "FenceSegmentEvent")
function FenceSegmentEvent.emptyNew()
	return Event.new(FenceSegmentEvent_mt, NetworkNode.CHANNEL_MAIN)
end
function FenceSegmentEvent.new(fencePlaceable, segment)
	local self = FenceSegmentEvent.emptyNew()
	self.fencePlaceable = fencePlaceable
	self.segment = segment
	return self
end
function FenceSegmentEvent:readStream(streamId, connection)
	self.fencePlaceable = NetworkUtil.readNodeObject(streamId)
	local templateIndex = streamReadUInt8(streamId)
	local fence = self.fencePlaceable:getFence()
	local templateId = fence:getSegmentTemplateIdByIndex(templateIndex)
	self.segment = fence:createNewSegment(templateId)
	self.segment:readStream(streamId, connection)
	self:run(connection)
end
function FenceSegmentEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.fencePlaceable)
	local segmentId = self.segment:getId()
	local fence = self.fencePlaceable:getFence()
	local fenceTemplateIndex = fence:getSegmentTemplateIndexById(segmentId)
	streamWriteUInt8(streamId, fenceTemplateIndex)
	self.segment:writeStream(streamId, connection)
end
function FenceSegmentEvent:run(connection)
	if self.fencePlaceable ~= nil and self.fencePlaceable:getIsSynchronized() then
		self.segment:updateMeshes(true, false)
		self.segment:finalize()
	end
end
