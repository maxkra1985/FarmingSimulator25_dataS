-- Local values: PlaceableObjectStorageUnloadEvent_mt
PlaceableObjectStorageUnloadEvent = {}
local PlaceableObjectStorageUnloadEvent_mt = Class(PlaceableObjectStorageUnloadEvent, Event)
InitStaticEventClass(PlaceableObjectStorageUnloadEvent, "PlaceableObjectStorageUnloadEvent")
function PlaceableObjectStorageUnloadEvent.emptyNew()
	-- upvalues: (copy) PlaceableObjectStorageUnloadEvent_mt
	return Event.new(PlaceableObjectStorageUnloadEvent_mt)
end

-- Local values: self
function PlaceableObjectStorageUnloadEvent.new(placeable, objectInfoIndex, objectAmount)
	local v5_ = PlaceableObjectStorageUnloadEvent.emptyNew()
	v5_.placeable = placeable
	v5_.objectInfoIndex = objectInfoIndex
	v5_.objectAmount = objectAmount
	return v5_
end

function PlaceableObjectStorageUnloadEvent:readStream(streamId, connection)
	self.placeable = NetworkUtil.readNodeObject(streamId)
	self.objectInfoIndex = streamReadUIntN(streamId, PlaceableObjectStorage.NUM_BITS_OBJECT_INFO)
	self.objectAmount = streamReadUIntN(streamId, PlaceableObjectStorage.NUM_BITS_AMOUNT)
	self:run(connection)
end

function PlaceableObjectStorageUnloadEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.placeable)
	streamWriteUIntN(streamId, self.objectInfoIndex, PlaceableObjectStorage.NUM_BITS_OBJECT_INFO)
	streamWriteUIntN(streamId, self.objectAmount, PlaceableObjectStorage.NUM_BITS_AMOUNT)
end

function PlaceableObjectStorageUnloadEvent:run(connection)
	if self.placeable ~= nil and (self.placeable:getIsSynchronized() and self.placeable.removeAbstractObjectsFromStorage ~= nil) then
		self.placeable:removeAbstractObjectsFromStorage(self.objectInfoIndex, self.objectAmount, connection)
	end
end
