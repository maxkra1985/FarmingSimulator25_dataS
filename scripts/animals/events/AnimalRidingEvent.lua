-- Local values: AnimalRidingEvent_mt
AnimalRidingEvent = {}
local AnimalRidingEvent_mt = Class(AnimalRidingEvent, Event)
InitStaticEventClass(AnimalRidingEvent, "AnimalRidingEvent")
function AnimalRidingEvent.emptyNew()
	-- upvalues: (copy) AnimalRidingEvent_mt
	return Event.new(AnimalRidingEvent_mt)
end

-- Local values: self
function AnimalRidingEvent.new(husbandry, clusterId, player)
	local v5_ = AnimalRidingEvent.emptyNew()
	v5_.husbandry = husbandry
	v5_.clusterId = clusterId
	v5_.player = player
	return v5_
end

function AnimalRidingEvent:readStream(streamId, connection)
	self.husbandry = NetworkUtil.readNodeObject(streamId)
	self.clusterId = streamReadInt32(streamId)
	self.player = NetworkUtil.readNodeObject(streamId)
	self:run(connection)
end

function AnimalRidingEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.husbandry)
	streamWriteInt32(streamId, self.clusterId)
	NetworkUtil.writeNodeObject(streamId, self.player)
end

function AnimalRidingEvent:run(connection)
	self.husbandry:startRiding(self.clusterId, self.player)
end
