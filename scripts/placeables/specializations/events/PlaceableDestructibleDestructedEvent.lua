-- Local values: PlaceableDestructibleDestructedEvent_mt
PlaceableDestructibleDestructedEvent = {}
local PlaceableDestructibleDestructedEvent_mt = Class(PlaceableDestructibleDestructedEvent, Event)
InitStaticEventClass(PlaceableDestructibleDestructedEvent, "PlaceableDestructibleDestructedEvent")
function PlaceableDestructibleDestructedEvent.emptyNew()
	-- upvalues: (copy) PlaceableDestructibleDestructedEvent_mt
	return Event.new(PlaceableDestructibleDestructedEvent_mt)
end

-- Local values: self
function PlaceableDestructibleDestructedEvent.new(placeable)
	local v3_ = PlaceableDestructibleDestructedEvent.emptyNew()
	v3_.placeable = placeable
	return v3_
end

function PlaceableDestructibleDestructedEvent:readStream(streamId, connection)
	self.placeable = NetworkUtil.readNodeObject(streamId)
	self:run(connection)
end

function PlaceableDestructibleDestructedEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.placeable)
end

-- Local values: placeable
function PlaceableDestructibleDestructedEvent:run(connection)
	local v10_ = self.placeable
	if v10_ ~= nil and v10_:getIsSynchronized() then
		v10_:destructed()
	end
end
