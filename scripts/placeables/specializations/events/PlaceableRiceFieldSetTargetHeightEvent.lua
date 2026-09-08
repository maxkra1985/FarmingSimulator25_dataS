-- Local values: PlaceableRiceFieldSetTargetHeightEvent_mt
PlaceableRiceFieldSetTargetHeightEvent = {}
local PlaceableRiceFieldSetTargetHeightEvent_mt = Class(PlaceableRiceFieldSetTargetHeightEvent, Event)
InitStaticEventClass(PlaceableRiceFieldSetTargetHeightEvent, "PlaceableRiceFieldSetTargetHeightEvent")
function PlaceableRiceFieldSetTargetHeightEvent.emptyNew()
	-- upvalues: (copy) PlaceableRiceFieldSetTargetHeightEvent_mt
	return Event.new(PlaceableRiceFieldSetTargetHeightEvent_mt)
end

-- Local values: self
function PlaceableRiceFieldSetTargetHeightEvent.new(placeableRiceField, fieldIndex, targetHeight)
	local v5_ = PlaceableRiceFieldSetTargetHeightEvent.emptyNew()
	v5_.placeableRiceField = placeableRiceField
	v5_.fieldIndex = fieldIndex
	v5_.targetHeight = targetHeight
	return v5_
end

function PlaceableRiceFieldSetTargetHeightEvent:readStream(streamId, connection)
	self.placeableRiceField = NetworkUtil.readNodeObject(streamId)
	self.fieldIndex = streamReadUInt8(streamId)
	self.targetHeight = streamReadFloat32(streamId)
	self:run(connection)
end

function PlaceableRiceFieldSetTargetHeightEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.placeableRiceField)
	streamWriteUInt8(streamId, self.fieldIndex)
	streamWriteFloat32(streamId, self.targetHeight)
end

function PlaceableRiceFieldSetTargetHeightEvent:run(connection)
	if self.placeableRiceField ~= nil and self.placeableRiceField:getIsSynchronized() then
		self.placeableRiceField:setWaterHeightTarget(self.fieldIndex, self.targetHeight, true)
		if not connection:getIsServer() then
			g_server:broadcastEvent(self)
		end
	end
end
