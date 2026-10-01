PlaceableDestructibleDestructedEvent = {}
local PlaceableDestructibleDestructedEvent_mt = Class(PlaceableDestructibleDestructedEvent, Event)
InitStaticEventClass(PlaceableDestructibleDestructedEvent, "PlaceableDestructibleDestructedEvent")
function PlaceableDestructibleDestructedEvent.emptyNew()
	local self = Event.new(PlaceableDestructibleDestructedEvent_mt)
	return self
end
function PlaceableDestructibleDestructedEvent.new(placeable)
	local self = PlaceableDestructibleDestructedEvent.emptyNew()
	self.placeable = placeable
	return self
end
function PlaceableDestructibleDestructedEvent:readStream(streamId, connection)
	self.placeable = NetworkUtil.readNodeObject(streamId)
	self:run(connection)
end
function PlaceableDestructibleDestructedEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.placeable)
end
function PlaceableDestructibleDestructedEvent:run(connection)
	local placeable = self.placeable
	if placeable ~= nil and placeable:getIsSynchronized() then
		placeable:destructed()
	end
end
