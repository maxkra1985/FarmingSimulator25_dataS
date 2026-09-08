-- Local values: PlaceableObjectStorageStoreEvent_mt
PlaceableObjectStorageStoreEvent = {}
local PlaceableObjectStorageStoreEvent_mt = Class(PlaceableObjectStorageStoreEvent, Event)
InitStaticEventClass(PlaceableObjectStorageStoreEvent, "PlaceableObjectStorageStoreEvent")
function PlaceableObjectStorageStoreEvent.emptyNew()
	-- upvalues: (copy) PlaceableObjectStorageStoreEvent_mt
	return Event.new(PlaceableObjectStorageStoreEvent_mt)
end

-- Local values: self
function PlaceableObjectStorageStoreEvent.new(placeable)
	local v3_ = PlaceableObjectStorageStoreEvent.emptyNew()
	v3_.placeable = placeable
	return v3_
end

function PlaceableObjectStorageStoreEvent:readStream(streamId, connection)
	self.placeable = NetworkUtil.readNodeObject(streamId)
	self:run(connection)
end

function PlaceableObjectStorageStoreEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.placeable)
end

function PlaceableObjectStorageStoreEvent:run(connection)
	if self.placeable ~= nil and (self.placeable:getIsSynchronized() and self.placeable.storePendingManualObjects ~= nil) then
		self.placeable:storePendingManualObjects()
	end
end
