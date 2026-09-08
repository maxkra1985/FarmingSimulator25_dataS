-- Local values: PlaceableRiceFieldFieldEvent_mt
PlaceableRiceFieldFieldEvent = {}
local PlaceableRiceFieldFieldEvent_mt = Class(PlaceableRiceFieldFieldEvent, Event)
InitStaticEventClass(PlaceableRiceFieldFieldEvent, "PlaceableRiceFieldFieldEvent")
function PlaceableRiceFieldFieldEvent.emptyNew()
	-- upvalues: (copy) PlaceableRiceFieldFieldEvent_mt
	return Event.new(PlaceableRiceFieldFieldEvent_mt, NetworkNode.CHANNEL_MAIN)
end

-- Local values: self
function PlaceableRiceFieldFieldEvent.new(placeableRiceField, field)
	local v4_ = PlaceableRiceFieldFieldEvent.emptyNew()
	v4_.placeableRiceField = placeableRiceField
	v4_.field = field
	return v4_
end

-- Local values: height, field, numVertices, i
function PlaceableRiceFieldFieldEvent:readStream(streamId, connection)
	self.placeableRiceField = NetworkUtil.readNodeObject(streamId)
	local v8_ = streamReadFloat32(streamId)
	local v9_ = self.placeableRiceField:createNewField(v8_)
	local v10_ = streamReadUInt16(streamId)
	v9_.polygon = Polygon2D.new(v10_)
	for _ = 1, v10_ do
		v9_.polygon:addPos(streamReadFloat32(streamId), streamReadFloat32(streamId))
	end
	v9_.waterHeight = streamReadFloat32(streamId)
	self.field = v9_
	self:run(connection)
end

-- Local values: _, vertex
function PlaceableRiceFieldFieldEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.placeableRiceField)
	streamWriteFloat32(streamId, self.field.height)
	streamWriteUInt16(streamId, self.field.polygon:getNumVertices())
	for _, v13_ in ipairs(self.field.polygon:getVertices()) do
		streamWriteFloat32(streamId, v13_)
	end
	streamWriteFloat32(streamId, self.field.waterHeight)
end

function PlaceableRiceFieldFieldEvent:run(connection)
	if self.placeableRiceField ~= nil and self.placeableRiceField:getIsSynchronized() then
		self.placeableRiceField:finalizeNewField(self.field, true, function(p16_)
			-- upvalues: (copy) connection, (copy) self
			connection:sendEvent(PlaceableRiceFieldFieldAnswerEvent.new(self.placeableRiceField, p16_))
		end)
	end
end
