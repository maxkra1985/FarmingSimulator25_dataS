FenceSegmentBatchEvent = {}
local FenceSegmentBatchEvent_mt = Class(FenceSegmentBatchEvent, Event)
InitStaticEventClass(FenceSegmentBatchEvent, "FenceSegmentBatchEvent")
FenceSegmentBatchEvent.MAX_SEGMENTS = 32
function FenceSegmentBatchEvent.emptyNew()
	local self = Event.new(FenceSegmentBatchEvent_mt, NetworkNode.CHANNEL_MAIN)
	return self
end
function FenceSegmentBatchEvent.newSegments(fencePlaceable, segments)
	local self = FenceSegmentBatchEvent.emptyNew()
	self.fencePlaceable = fencePlaceable
	self.segments = segments
	return self
end
function FenceSegmentBatchEvent.newProgress(requestId, doneSteps, totalSteps)
	local self = FenceSegmentBatchEvent.emptyNew()
	self.requestId = requestId
	self.doneSteps = doneSteps
	self.totalSteps = totalSteps
	return self
end
function FenceSegmentBatchEvent:readStream(streamId, connection)
	if not streamReadBool(streamId) then
		self.requestId = streamReadUInt8(streamId)
		self.doneSteps = streamReadUInt16(streamId)
		self.totalSteps = streamReadUInt16(streamId)
		self:run(connection)
	else
		self.fencePlaceable = NetworkUtil.readNodeObject(streamId)
		if self.fencePlaceable == nil or self.fencePlaceable.getFence == nil then
			Logging.error("FenceSegmentBatchEvent received for an unknown fence placeable")
			return
		end
		local fence = self.fencePlaceable:getFence()
		local numSegments = streamReadUInt8(streamId)
		self.segments = {}
		for i = 1, numSegments do
			local templateIndex = streamReadUInt8(streamId)
			local templateId = fence:getSegmentTemplateIdByIndex(templateIndex)
			local segment = fence:createNewSegment(templateId)
			segment:readStream(streamId, connection, nil)
			self.segments[i] = segment
		end
		self:run(connection)
	end
end
function FenceSegmentBatchEvent:writeStream(streamId, connection)
	if not streamWriteBool(streamId, self.segments ~= nil) then
		streamWriteUInt8(streamId, self.requestId)
		streamWriteUInt16(streamId, self.doneSteps)
		streamWriteUInt16(streamId, self.totalSteps)
	else
		NetworkUtil.writeNodeObject(streamId, self.fencePlaceable)
		local fence = self.fencePlaceable:getFence()
		streamWriteUInt8(streamId, #self.segments)
		for _, segment in ipairs(self.segments) do
			streamWriteUInt8(streamId, fence:getSegmentTemplateIndexById(segment:getId()))
			segment:writeStream(streamId, connection, nil)
		end
	end
end
function FenceSegmentBatchEvent:run(connection)
	if self.segments == nil then
		g_messageCenter:publish(FenceSegmentBatchEvent, self.requestId, self.doneSteps, self.totalSteps)
	elseif not self.fencePlaceable:getIsSynchronized() then
		for _, segment in ipairs(self.segments) do
			segment:delete()
		end
	else
		for _, segment in ipairs(self.segments) do
			segment:updateMeshes(true, false)
			segment:finalize()
		end
	end
end
