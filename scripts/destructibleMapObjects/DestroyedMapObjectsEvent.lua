-- Local values: DestroyedMapObjectsEvent_mt
DestroyedMapObjectsEvent = {}
local DestroyedMapObjectsEvent_mt = Class(DestroyedMapObjectsEvent, Event)
InitStaticEventClass(DestroyedMapObjectsEvent, "DestroyedMapObjectsEvent")
function DestroyedMapObjectsEvent.emptyNew()
	-- upvalues: (copy) DestroyedMapObjectsEvent_mt
	return Event.new(DestroyedMapObjectsEvent_mt)
end

-- Local values: self
function DestroyedMapObjectsEvent.new(groupId, childIndicesStatus)
	local v4_ = DestroyedMapObjectsEvent.emptyNew()
	v4_.groupId = groupId
	v4_.childIndicesStatus = childIndicesStatus
	return v4_
end

-- Local values: numChildIndices, i
function DestroyedMapObjectsEvent:readStream(streamId, connection)
	self.groupId = streamReadUIntN(streamId, DestructibleMapObjectSystem.GROUP_ID_NUM_BITS)
	local v8_ = streamReadUIntN(streamId, DestructibleMapObjectSystem.CHILD_INDEX_NUM_BITS)
	self.childIndicesStatus = {}
	for v9_ = 1, v8_ do
		self.childIndicesStatus[v9_] = streamReadBool(streamId)
	end
	self:run(connection)
end

-- Local values: _, childVisibility
function DestroyedMapObjectsEvent:writeStream(streamId, connection)
	streamWriteUIntN(streamId, self.groupId, DestructibleMapObjectSystem.GROUP_ID_NUM_BITS)
	streamWriteUIntN(streamId, #self.childIndicesStatus, DestructibleMapObjectSystem.CHILD_INDEX_NUM_BITS)
	for _, v12_ in ipairs(self.childIndicesStatus) do
		streamWriteBool(streamId, v12_)
	end
end

-- Local values: childIndex, isDestroyed
function DestroyedMapObjectsEvent:run(connection)
	if connection:getIsServer() and (self.groupId and self.childIndicesStatus) then
		for v15_, v16_ in ipairs(self.childIndicesStatus) do
			if v16_ then
				g_currentMission.destructibleMapObjectSystem:setGroupChildIndexDestroyed(self.groupId, v15_ - 1, false, false)
			end
		end
	end
end
