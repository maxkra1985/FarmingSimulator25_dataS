-- Local values: FenceDeleteSegmentEvent_mt
FenceDeleteSegmentEvent = {}
local FenceDeleteSegmentEvent_mt = Class(FenceDeleteSegmentEvent, Event)
InitStaticEventClass(FenceDeleteSegmentEvent, "FenceDeleteSegmentEvent")
function FenceDeleteSegmentEvent.emptyNew()
	-- upvalues: (copy) FenceDeleteSegmentEvent_mt
	return Event.new(FenceDeleteSegmentEvent_mt, NetworkNode.CHANNEL_MAIN)
end

-- Local values: self
function FenceDeleteSegmentEvent.new(fencePlaceable, segmentId)
	local v4_ = FenceDeleteSegmentEvent.emptyNew()
	v4_.fencePlaceable = fencePlaceable
	v4_.segmentId = segmentId
	return v4_
end

function FenceDeleteSegmentEvent:readStream(streamId, connection)
	self.fencePlaceable = NetworkUtil.readNodeObject(streamId)
	self.segmentId = streamReadUInt16(streamId)
	self:run(connection)
end

function FenceDeleteSegmentEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.fencePlaceable)
	streamWriteUInt16(streamId, self.segmentId)
end

-- Local values: fence, segment
function FenceDeleteSegmentEvent:run(connection)
	if self.fencePlaceable ~= nil and self.fencePlaceable:getIsSynchronized() then
		if g_server ~= nil then
			g_server:broadcastEvent(self, false, nil)
		end
		local v11_ = self.fencePlaceable:getFence()
		local v12_ = v11_:getSegmentById(self.segmentId)
		if v12_ ~= nil then
			v11_:removeSegment(v12_)
			v12_:delete()
			g_messageCenter:publish(FenceDeleteSegmentEvent, self.fencePlaceable, v12_)
		end
	end
end
