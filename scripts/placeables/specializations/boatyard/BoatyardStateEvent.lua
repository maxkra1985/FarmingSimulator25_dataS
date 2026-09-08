-- Local values: BoatyardStateEvent_mt
BoatyardStateEvent = {}
local BoatyardStateEvent_mt = Class(BoatyardStateEvent, Event)
InitStaticEventClass(BoatyardStateEvent, "BoatyardStateEvent")
function BoatyardStateEvent.emptyNew()
	-- upvalues: (copy) BoatyardStateEvent_mt
	return Event.new(BoatyardStateEvent_mt)
end

-- Local values: self
function BoatyardStateEvent.new(boatyard, stateIndex)
	local v4_ = BoatyardStateEvent.emptyNew()
	v4_.boatyard = boatyard
	v4_.stateIndex = stateIndex
	return v4_
end

function BoatyardStateEvent:readStream(streamId, connection)
	self.boatyard = NetworkUtil.readNodeObject(streamId)
	self.stateIndex = streamReadUInt8(streamId)
	self:run(connection)
end

function BoatyardStateEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.boatyard)
	streamWriteUInt8(streamId, self.stateIndex)
end

function BoatyardStateEvent:run(connection)
	if self.boatyard ~= nil and self.boatyard:getIsSynchronized() then
		self.boatyard:setState(self.stateIndex)
	end
end
