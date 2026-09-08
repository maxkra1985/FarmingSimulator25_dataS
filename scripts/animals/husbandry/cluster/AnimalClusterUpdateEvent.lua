-- Local values: AnimalClusterUpdateEvent_mt
AnimalClusterUpdateEvent = {}
local AnimalClusterUpdateEvent_mt = Class(AnimalClusterUpdateEvent, Event)
InitStaticEventClass(AnimalClusterUpdateEvent, "AnimalClusterUpdateEvent")
function AnimalClusterUpdateEvent.emptyNew()
	-- upvalues: (copy) AnimalClusterUpdateEvent_mt
	return Event.new(AnimalClusterUpdateEvent_mt)
end

-- Local values: self
function AnimalClusterUpdateEvent.new(owner, clusters)
	local v4_ = AnimalClusterUpdateEvent.emptyNew()
	local v5_ = #clusters < 65535
	assert(v5_, "Number of clusters is too big")
	v4_.owner = owner
	v4_.clusters = clusters
	return v4_
end

-- Local values: clusterSystem
function AnimalClusterUpdateEvent:readStream(streamId, connection)
	self.owner = NetworkUtil.readNodeObject(streamId)
	self.owner:getClusterSystem():readStream(streamId, connection)
end

-- Local values: clusterSystem
function AnimalClusterUpdateEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.owner)
	self.owner:getClusterSystem():writeStream(streamId, connection)
end

function AnimalClusterUpdateEvent:run(connection) end
