-- Local values: TrailerToggleTipSideEvent_mt
TrailerToggleTipSideEvent = {}
local TrailerToggleTipSideEvent_mt = Class(TrailerToggleTipSideEvent, Event)
InitStaticEventClass(TrailerToggleTipSideEvent, "TrailerToggleTipSideEvent")
function TrailerToggleTipSideEvent.emptyNew()
	-- upvalues: (copy) TrailerToggleTipSideEvent_mt
	return Event.new(TrailerToggleTipSideEvent_mt)
end

-- Local values: self
function TrailerToggleTipSideEvent.new(object, tipSideIndex)
	local v4_ = TrailerToggleTipSideEvent.emptyNew()
	v4_.object = object
	v4_.tipSideIndex = tipSideIndex
	return v4_
end

function TrailerToggleTipSideEvent:readStream(streamId, connection)
	self.object = NetworkUtil.readNodeObject(streamId)
	self.tipSideIndex = streamReadUIntN(streamId, Trailer.TIP_SIDE_NUM_BITS)
	self:run(connection)
end

function TrailerToggleTipSideEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.object)
	streamWriteUIntN(streamId, self.tipSideIndex, Trailer.TIP_SIDE_NUM_BITS)
end

function TrailerToggleTipSideEvent:run(connection)
	if not connection:getIsServer() then
		g_server:broadcastEvent(self, false, connection, self.object)
	end
	if self.object ~= nil and self.object:getIsSynchronized() then
		self.object:setPreferedTipSide(self.tipSideIndex, true)
	end
end
