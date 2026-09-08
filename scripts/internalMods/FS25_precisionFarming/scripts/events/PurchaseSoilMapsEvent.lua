-- Local values: PurchaseSoilMapsEvent_mt
PurchaseSoilMapsEvent = {}
local PurchaseSoilMapsEvent_mt = Class(PurchaseSoilMapsEvent, Event)
InitEventClass(PurchaseSoilMapsEvent, "PurchaseSoilMapsEvent")
function PurchaseSoilMapsEvent.emptyNew()
	-- upvalues: (copy) PurchaseSoilMapsEvent_mt
	return Event.new(PurchaseSoilMapsEvent_mt)
end

-- Local values: self
function PurchaseSoilMapsEvent.new(farmlandId)
	local v3_ = PurchaseSoilMapsEvent.emptyNew()
	v3_.farmlandId = farmlandId
	return v3_
end

function PurchaseSoilMapsEvent:readStream(streamId, connection)
	self.farmlandId = streamReadUIntN(streamId, g_farmlandManager.numberOfBits)
	self:run(connection)
end

function PurchaseSoilMapsEvent:writeStream(streamId, connection)
	streamWriteUIntN(streamId, self.farmlandId, g_farmlandManager.numberOfBits)
end

function PurchaseSoilMapsEvent:run(connection)
	if not connection:getIsServer() and (g_precisionFarming ~= nil and g_precisionFarming.soilMap ~= nil) then
		g_precisionFarming.soilMap:purchaseSoilMaps(self.farmlandId)
		g_precisionFarming:updatePrecisionFarmingOverlays()
	end
end
