-- Local values: FerryStateEvent_mt
FerryStateEvent = {}
local FerryStateEvent_mt = Class(FerryStateEvent, Event)
InitStaticEventClass(FerryStateEvent, "FerryStateEvent")
function FerryStateEvent.emptyNew()
	-- upvalues: (copy) FerryStateEvent_mt
	return Event.new(FerryStateEvent_mt)
end

-- Local values: self
function FerryStateEvent.new(ferry, state)
	local v4_ = FerryStateEvent.emptyNew()
	v4_.ferry = ferry
	v4_.state = state
	return v4_
end

function FerryStateEvent:readStream(streamId, connection)
	self.ferry = NetworkUtil.readNodeObject(streamId)
	self.state = streamReadUInt8(streamId)
	self:run(connection)
end

function FerryStateEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.ferry)
	streamWriteUInt8(streamId, self.state)
end

function FerryStateEvent:run(connection)
	if self.ferry ~= nil then
		self.ferry:setState(self.state)
	end
end
