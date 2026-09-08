-- Local values: AnimalCleanEvent_mt
AnimalCleanEvent = {}
local AnimalCleanEvent_mt = Class(AnimalCleanEvent, Event)
InitStaticEventClass(AnimalCleanEvent, "AnimalCleanEvent")
function AnimalCleanEvent.emptyNew()
	-- upvalues: (copy) AnimalCleanEvent_mt
	return Event.new(AnimalCleanEvent_mt)
end

-- Local values: self
function AnimalCleanEvent.new(husbandry, clusterId, delta)
	local v5_ = AnimalCleanEvent.emptyNew()
	v5_.husbandry = husbandry
	v5_.clusterId = clusterId
	local v6_ = math.floor(delta)
	v5_.delta = math.abs(v6_)
	return v5_
end

function AnimalCleanEvent:readStream(streamId, connection)
	self.husbandry = NetworkUtil.readNodeObject(streamId)
	self.clusterId = streamReadInt32(streamId)
	self.delta = streamReadUIntN(streamId, AnimalClusterHorse.NUM_BITS_DIRT)
	self:run(connection)
end

function AnimalCleanEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.husbandry)
	streamWriteInt32(streamId, self.clusterId)
	streamWriteUIntN(streamId, self.delta, AnimalClusterHorse.NUM_BITS_DIRT)
end

-- Local values: cluster
function AnimalCleanEvent:run(connection)
	if self.husbandry ~= nil then
		local v13_ = self.husbandry:getClusterById(self.clusterId)
		if v13_ ~= nil and v13_.changeDirt ~= nil then
			v13_:changeDirt(-self.delta)
		end
	end
end
