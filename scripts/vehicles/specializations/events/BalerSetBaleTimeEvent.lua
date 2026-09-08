-- Local values: BalerSetBaleTimeEvent_mt
BalerSetBaleTimeEvent = {}
local BalerSetBaleTimeEvent_mt = Class(BalerSetBaleTimeEvent, Event)
InitStaticEventClass(BalerSetBaleTimeEvent, "BalerSetBaleTimeEvent")
function BalerSetBaleTimeEvent.emptyNew()
	-- upvalues: (copy) BalerSetBaleTimeEvent_mt
	return Event.new(BalerSetBaleTimeEvent_mt)
end

-- Local values: self
function BalerSetBaleTimeEvent.new(object, bale, baleTime)
	local v5_ = BalerSetBaleTimeEvent.emptyNew()
	v5_.object = object
	v5_.bale = bale
	v5_.baleTime = baleTime
	return v5_
end

function BalerSetBaleTimeEvent:readStream(streamId, connection)
	self.object = NetworkUtil.readNodeObject(streamId)
	self.bale = streamReadInt32(streamId)
	self.baleTime = streamReadFloat32(streamId)
	self:run(connection)
end

function BalerSetBaleTimeEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.object)
	streamWriteInt32(streamId, self.bale)
	streamWriteFloat32(streamId, self.baleTime)
end

function BalerSetBaleTimeEvent:run(connection)
	if self.object ~= nil and self.object:getIsSynchronized() then
		self.object:setBaleTime(self.bale, self.baleTime)
	end
end
