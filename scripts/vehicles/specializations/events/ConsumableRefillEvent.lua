-- Local values: ConsumableRefillEvent_mt
ConsumableRefillEvent = {}
local ConsumableRefillEvent_mt = Class(ConsumableRefillEvent, Event)
InitStaticEventClass(ConsumableRefillEvent, "ConsumableRefillEvent")
function ConsumableRefillEvent.emptyNew()
	-- upvalues: (copy) ConsumableRefillEvent_mt
	return Event.new(ConsumableRefillEvent_mt)
end

-- Local values: self
function ConsumableRefillEvent.new(object, typeIndex, variationIndex)
	local v5_ = ConsumableRefillEvent.emptyNew()
	v5_.object = object
	v5_.typeIndex = typeIndex
	v5_.variationIndex = variationIndex
	return v5_
end

function ConsumableRefillEvent:readStream(streamId, connection)
	self.object = NetworkUtil.readNodeObject(streamId)
	self.typeIndex = streamReadUInt8(streamId)
	self.variationIndex = streamReadUIntN(streamId, ConsumableManager.NUM_VARIATION_BITS)
	if not connection:getIsServer() then
		self:run(connection)
	end
end

function ConsumableRefillEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.object)
	streamWriteUInt8(streamId, self.typeIndex)
	streamWriteUIntN(streamId, self.variationIndex, ConsumableManager.NUM_VARIATION_BITS)
end

-- Local values: spec, type, delta, price
function ConsumableRefillEvent:run(connection)
	if self.object ~= nil then
		local v12_ = self.object.spec_consumable.types[self.typeIndex]
		v12_.consumingVariationIndex = self.variationIndex
		local v13_ = self.object:addFillUnitFillLevel(self.object:getOwnerFarmId(), v12_.fillUnitIndex, v12_.numStorageSlots, self.object:getFillUnitFirstSupportedFillType(v12_.fillUnitIndex), ToolType.UNDEFINED, nil)
		self.object:updateConsumable(v12_.typeName, 0)
		local v14_ = v13_ + self.object:addFillUnitFillLevel(self.object:getOwnerFarmId(), v12_.fillUnitIndex, v12_.numConsumingSlots, self.object:getFillUnitFirstSupportedFillType(v12_.fillUnitIndex), ToolType.UNDEFINED, nil)
		self.object:updateConsumable(v12_.typeName, 0)
		local v15_ = g_consumableManager:getConsumableVariationPriceByIndex(self.variationIndex) * v14_
		if v15_ > 0 then
			g_farmManager:updateFarmStats(self.object:getActiveFarm(), "expenses", v15_)
			g_currentMission:addMoney(-v15_, self.object:getActiveFarm(), MoneyType.PURCHASE_CONSUMABLES, true)
			g_currentMission:showMoneyChange(MoneyType.PURCHASE_CONSUMABLES, nil, false, self.object:getActiveFarm())
		end
	end
end

function ConsumableRefillEvent.sendEvent(vehicle, typeIndex, variationIndex)
	if g_server == nil then
		g_client:getServerConnection():sendEvent(ConsumableRefillEvent.new(vehicle, typeIndex, variationIndex))
	else
		g_server:broadcastEvent(ConsumableRefillEvent.new(vehicle, typeIndex, variationIndex), true, nil, vehicle)
	end
end
