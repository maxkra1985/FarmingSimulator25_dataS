-- Local values: MapObjectDestroyedEvent_mt
MapObjectDestroyedEvent = {}
local MapObjectDestroyedEvent_mt = Class(MapObjectDestroyedEvent, Event)
InitStaticEventClass(MapObjectDestroyedEvent, "MapObjectDestroyedEvent")
function MapObjectDestroyedEvent.emptyNew()
	-- upvalues: (copy) MapObjectDestroyedEvent_mt
	return Event.new(MapObjectDestroyedEvent_mt)
end

-- Local values: self
function MapObjectDestroyedEvent.new(groupId, childIndex)
	local v4_ = MapObjectDestroyedEvent.emptyNew()
	v4_.groupId = groupId
	v4_.childIndex = childIndex
	return v4_
end

function MapObjectDestroyedEvent:readStream(streamId, connection)
	self.groupId = streamReadUIntN(streamId, DestructibleMapObjectSystem.GROUP_ID_NUM_BITS)
	self.childIndex = streamReadUIntN(streamId, DestructibleMapObjectSystem.CHILD_INDEX_NUM_BITS)
	self:run(connection)
end

function MapObjectDestroyedEvent:writeStream(streamId, connection)
	streamWriteUIntN(streamId, self.groupId, DestructibleMapObjectSystem.GROUP_ID_NUM_BITS)
	streamWriteUIntN(streamId, self.childIndex, DestructibleMapObjectSystem.CHILD_INDEX_NUM_BITS)
end

function MapObjectDestroyedEvent:run(connection)
	if connection:getIsServer() and (self.groupId and self.childIndex) then
		g_currentMission.destructibleMapObjectSystem:setGroupChildIndexDestroyed(self.groupId, self.childIndex, false, true)
	end
end
