-- Local values: FenceRequestDeleteSegmentEvent_mt
FenceRequestDeleteSegmentEvent = {}
local FenceRequestDeleteSegmentEvent_mt = Class(FenceRequestDeleteSegmentEvent, Event)
InitStaticEventClass(FenceRequestDeleteSegmentEvent, "FenceRequestDeleteSegmentEvent")
function FenceRequestDeleteSegmentEvent.emptyNew()
	-- upvalues: (copy) FenceRequestDeleteSegmentEvent_mt
	return Event.new(FenceRequestDeleteSegmentEvent_mt, NetworkNode.CHANNEL_MAIN)
end

-- Local values: self
function FenceRequestDeleteSegmentEvent.new(fencePlaceable, segmentId)
	local v4_ = FenceRequestDeleteSegmentEvent.emptyNew()
	v4_.fencePlaceable = fencePlaceable
	v4_.segmentId = segmentId
	return v4_
end

-- Local values: self
function FenceRequestDeleteSegmentEvent.newServerToClient(success)
	local v6_ = FenceRequestDeleteSegmentEvent.emptyNew()
	v6_.success = success
	return v6_
end

function FenceRequestDeleteSegmentEvent:readStream(streamId, connection)
	if connection:getIsServer() then
		self.success = streamReadBool(streamId)
	else
		self.fencePlaceable = NetworkUtil.readNodeObject(streamId)
		self.segmentId = streamReadUInt16(streamId)
	end
	self:run(connection)
end

function FenceRequestDeleteSegmentEvent:writeStream(streamId, connection)
	if connection:getIsServer() then
		NetworkUtil.writeNodeObject(streamId, self.fencePlaceable)
		streamWriteUInt16(streamId, self.segmentId)
	else
		streamWriteBool(streamId, self.success)
	end
end

-- Local values: fence, segment
function FenceRequestDeleteSegmentEvent:run(connection)
	if connection:getIsServer() then
		g_messageCenter:publish(FenceRequestDeleteSegmentEvent, self.success)
	elseif self.fencePlaceable ~= nil and self.fencePlaceable:getIsSynchronized() then
		local v15_ = self.fencePlaceable:getFence()
		local v16_ = v15_:getSegmentById(self.segmentId)
		if v16_ == nil then
			connection:sendEvent(FenceRequestDeleteSegmentEvent.newServerToClient(false))
			return
		end
		v15_:removeSegment(v16_)
		v16_:delete()
		connection:sendEvent(FenceRequestDeleteSegmentEvent.newServerToClient(true))
		g_server:broadcastEvent(FenceDeleteSegmentEvent.new(self.fencePlaceable, self.segmentId), false, connection)
	end
end
