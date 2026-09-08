-- Local values: VehicleSaleRemoveEvent_mt
VehicleSaleRemoveEvent = {}
local VehicleSaleRemoveEvent_mt = Class(VehicleSaleRemoveEvent, Event)
InitStaticEventClass(VehicleSaleRemoveEvent, "VehicleSaleRemoveEvent")
function VehicleSaleRemoveEvent.emptyNew()
	-- upvalues: (copy) VehicleSaleRemoveEvent_mt
	return Event.new(VehicleSaleRemoveEvent_mt)
end

-- Local values: self
function VehicleSaleRemoveEvent.new(saleItemId)
	local v3_ = VehicleSaleRemoveEvent.emptyNew()
	v3_.saleItemId = saleItemId
	return v3_
end

function VehicleSaleRemoveEvent:readStream(streamId, connection)
	self.saleItemId = streamReadUInt8(streamId)
	self:run(connection)
end

function VehicleSaleRemoveEvent:writeStream(streamId, connection)
	streamWriteUInt8(streamId, self.saleItemId)
end

function VehicleSaleRemoveEvent:run(connection)
	if connection:getIsServer() then
		g_currentMission.vehicleSaleSystem:removeSaleWithId(self.saleItemId)
	end
end
