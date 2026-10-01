FerryStateEvent = {}
local FerryStateEvent_mt = Class(FerryStateEvent, Event)
InitStaticEventClass(FerryStateEvent, "FerryStateEvent")
function FerryStateEvent.emptyNew()
	local self = Event.new(FerryStateEvent_mt)
	return self
end
function FerryStateEvent.new(ferry, state)
	local self = FerryStateEvent.emptyNew()
	self.ferry = ferry
	self.state = state
	return self
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
