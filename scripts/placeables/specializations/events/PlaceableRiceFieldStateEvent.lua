-- Local values: PlaceableRiceFieldStateEvent_mt
PlaceableRiceFieldStateEvent = {}
local PlaceableRiceFieldStateEvent_mt = Class(PlaceableRiceFieldStateEvent, Event)
InitStaticEventClass(PlaceableRiceFieldStateEvent, "PlaceableRiceFieldStateEvent")
function PlaceableRiceFieldStateEvent.emptyNew()
	-- upvalues: (copy) PlaceableRiceFieldStateEvent_mt
	return Event.new(PlaceableRiceFieldStateEvent_mt)
end

-- Local values: self
function PlaceableRiceFieldStateEvent.new(placeableRiceField, fieldIndex)
	local v4_ = PlaceableRiceFieldStateEvent.emptyNew()
	v4_.placeableRiceField = placeableRiceField
	v4_.fieldIndex = fieldIndex
	return v4_
end

-- Local values: self
function PlaceableRiceFieldStateEvent.newServerToClient(placeableRiceField, fieldIndex, fruitTypeIndex, growthStateIndex)
	local v9_ = PlaceableRiceFieldStateEvent.emptyNew()
	v9_.placeableRiceField = placeableRiceField
	v9_.fieldIndex = fieldIndex
	v9_.fruitTypeIndex = fruitTypeIndex
	v9_.growthStateIndex = growthStateIndex
	return v9_
end

function PlaceableRiceFieldStateEvent:readStream(streamId, connection)
	self.placeableRiceField = NetworkUtil.readNodeObject(streamId)
	self.fieldIndex = streamReadUInt8(streamId)
	if connection:getIsServer() then
		self.fruitTypeIndex = streamReadUIntN(streamId, FruitTypeManager.SEND_NUM_BITS)
		self.growthStateIndex = streamReadUInt8(streamId)
	end
	self:run(connection)
end

function PlaceableRiceFieldStateEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.placeableRiceField)
	streamWriteUInt8(streamId, self.fieldIndex)
	if not connection:getIsServer() then
		streamWriteUIntN(streamId, self.fruitTypeIndex, FruitTypeManager.SEND_NUM_BITS)
		streamWriteUInt8(streamId, self.growthStateIndex)
	end
end

function PlaceableRiceFieldStateEvent:run(connection)
	if self.placeableRiceField == nil or not self.placeableRiceField:getIsSynchronized() then
		return
	elseif connection:getIsServer() then
		g_messageCenter:publish(PlaceableRiceFieldStateEvent, self.fruitTypeIndex, self.growthStateIndex)
	else
		self.placeableRiceField:getRiceFieldState(self.fieldIndex, function(_, p18_, p19_)
			-- upvalues: (copy) connection, (copy) self
			connection:sendEvent(PlaceableRiceFieldStateEvent.newServerToClient(self.placeableRiceField, self.fieldIndex, p18_, p19_))
		end)
	end
end
