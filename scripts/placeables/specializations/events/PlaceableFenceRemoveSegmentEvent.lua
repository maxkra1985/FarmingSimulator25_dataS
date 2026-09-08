-- Local values: PlaceableFenceRemoveSegmentEvent_mt
PlaceableFenceRemoveSegmentEvent = {}
local PlaceableFenceRemoveSegmentEvent_mt = Class(PlaceableFenceRemoveSegmentEvent, Event)
InitStaticEventClass(PlaceableFenceRemoveSegmentEvent, "PlaceableFenceRemoveSegmentEvent")
function PlaceableFenceRemoveSegmentEvent.emptyNew()
	-- upvalues: (copy) PlaceableFenceRemoveSegmentEvent_mt
	return Event.new(PlaceableFenceRemoveSegmentEvent_mt)
end

-- Local values: self
function PlaceableFenceRemoveSegmentEvent.new(fence, segmentIndex, poleIndex)
	local v5_ = PlaceableFenceRemoveSegmentEvent.emptyNew()
	v5_.fence = fence
	v5_.segmentIndex = segmentIndex
	v5_.poleIndex = poleIndex
	return v5_
end

function PlaceableFenceRemoveSegmentEvent:readStream(streamId, connection)
	self.fence = NetworkUtil.readNodeObject(streamId)
	self.segmentIndex = streamReadInt32(streamId)
	self.poleIndex = streamReadInt32(streamId)
	self:run(connection)
end

function PlaceableFenceRemoveSegmentEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.fence)
	streamWriteInt32(streamId, self.segmentIndex)
	streamWriteInt32(streamId, self.poleIndex)
end

-- Local values: spec
function PlaceableFenceRemoveSegmentEvent:run(connection)
	if self.fence ~= nil and self.fence:getIsSynchronized() then
		local v13_ = self.fence.spec_fence
		self.fence:doDeletePanel(v13_.segments[self.segmentIndex], self.segmentIndex, self.poleIndex)
		g_messageCenter:publish(PlaceableFenceRemoveSegmentEvent, self.fence, self.segmentIndex, self.poleIndex)
		if not connection:getIsServer() then
			g_server:broadcastEvent(self)
		end
	end
end
