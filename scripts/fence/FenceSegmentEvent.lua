-- Local values: FenceSegmentEvent_mt
FenceSegmentEvent = {}
local FenceSegmentEvent_mt = Class(FenceSegmentEvent, Event)
InitStaticEventClass(FenceSegmentEvent, "FenceSegmentEvent")
function FenceSegmentEvent.emptyNew()
	-- upvalues: (copy) FenceSegmentEvent_mt
	return Event.new(FenceSegmentEvent_mt, NetworkNode.CHANNEL_MAIN)
end

-- Local values: self
function FenceSegmentEvent.new(fencePlaceable, segment)
	local v4_ = FenceSegmentEvent.emptyNew()
	v4_.fencePlaceable = fencePlaceable
	v4_.segment = segment
	return v4_
end

-- Local values: templateIndex, fence, templateId
function FenceSegmentEvent:readStream(streamId, connection)
	self.fencePlaceable = NetworkUtil.readNodeObject(streamId)
	local v8_ = streamReadUInt8(streamId)
	local v9_ = self.fencePlaceable:getFence()
	self.segment = v9_:createNewSegment((v9_:getSegmentTemplateIdByIndex(v8_)))
	self.segment:readStream(streamId, connection)
	self:run(connection)
end

-- Local values: segmentId, fence, fenceTemplateIndex
function FenceSegmentEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.fencePlaceable)
	local v13_ = self.segment:getId()
	local v14_ = self.fencePlaceable:getFence():getSegmentTemplateIndexById(v13_)
	streamWriteUInt8(streamId, v14_)
	self.segment:writeStream(streamId, connection)
end

function FenceSegmentEvent:run(connection)
	if self.fencePlaceable ~= nil and self.fencePlaceable:getIsSynchronized() then
		self.segment:updateMeshes(true, false)
		self.segment:finalize()
	end
end
