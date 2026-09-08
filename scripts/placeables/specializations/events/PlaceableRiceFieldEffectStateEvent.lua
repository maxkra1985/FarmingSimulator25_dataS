-- Local values: PlaceableRiceFieldEffectStateEvent_mt
PlaceableRiceFieldEffectStateEvent = {}
local PlaceableRiceFieldEffectStateEvent_mt = Class(PlaceableRiceFieldEffectStateEvent, Event)
InitStaticEventClass(PlaceableRiceFieldEffectStateEvent, "PlaceableRiceFieldEffectStateEvent")
function PlaceableRiceFieldEffectStateEvent.emptyNew()
	-- upvalues: (copy) PlaceableRiceFieldEffectStateEvent_mt
	return Event.new(PlaceableRiceFieldEffectStateEvent_mt)
end

-- Local values: self
function PlaceableRiceFieldEffectStateEvent.new(placeableRiceField, fieldIndex, isFilling, isEmptying)
	local v6_ = PlaceableRiceFieldEffectStateEvent.emptyNew()
	v6_.placeableRiceField = placeableRiceField
	v6_.fieldIndex = fieldIndex
	v6_.isFilling = isFilling
	v6_.isEmptying = isEmptying
	return v6_
end

function PlaceableRiceFieldEffectStateEvent:readStream(streamId, connection)
	self.placeableRiceField = NetworkUtil.readNodeObject(streamId)
	self.fieldIndex = streamReadUInt8(streamId)
	self.isFilling = streamReadBool(streamId)
	self.isEmptying = streamReadBool(streamId)
	self:run(connection)
end

function PlaceableRiceFieldEffectStateEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.placeableRiceField)
	streamWriteUInt8(streamId, self.fieldIndex)
	streamWriteBool(streamId, self.isFilling)
	streamWriteBool(streamId, self.isEmptying)
end

function PlaceableRiceFieldEffectStateEvent:run(connection)
	if self.placeableRiceField ~= nil and self.placeableRiceField:getIsSynchronized() then
		self.placeableRiceField:setEffectVisibility(self.fieldIndex, self.isFilling, self.isEmptying)
	end
end
