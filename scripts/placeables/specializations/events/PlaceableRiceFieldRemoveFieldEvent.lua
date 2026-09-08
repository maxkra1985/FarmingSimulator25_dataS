-- Local values: PlaceableRiceFieldRemoveFieldEvent_mt
PlaceableRiceFieldRemoveFieldEvent = {}
local PlaceableRiceFieldRemoveFieldEvent_mt = Class(PlaceableRiceFieldRemoveFieldEvent, Event)
InitStaticEventClass(PlaceableRiceFieldRemoveFieldEvent, "PlaceableRiceFieldRemoveFieldEvent")
function PlaceableRiceFieldRemoveFieldEvent.emptyNew()
	-- upvalues: (copy) PlaceableRiceFieldRemoveFieldEvent_mt
	return Event.new(PlaceableRiceFieldRemoveFieldEvent_mt, NetworkNode.CHANNEL_MAIN)
end

-- Local values: self
function PlaceableRiceFieldRemoveFieldEvent.new(placeableRiceField, fieldIndex)
	local v4_ = PlaceableRiceFieldRemoveFieldEvent.emptyNew()
	v4_.placeableRiceField = placeableRiceField
	v4_.fieldIndex = fieldIndex
	return v4_
end

function PlaceableRiceFieldRemoveFieldEvent:readStream(streamId, connection)
	self.placeableRiceField = NetworkUtil.readNodeObject(streamId)
	self.fieldIndex = streamReadUInt8(streamId)
	self:run(connection)
end

function PlaceableRiceFieldRemoveFieldEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.placeableRiceField)
	streamWriteUInt8(streamId, self.fieldIndex)
end

function PlaceableRiceFieldRemoveFieldEvent:run(connection)
	if self.placeableRiceField ~= nil and self.placeableRiceField:getIsSynchronized() then
		self.placeableRiceField:removeFieldByIndex(self.fieldIndex)
		if not connection:getIsServer() then
			g_server:broadcastEvent(self)
		end
	end
end
