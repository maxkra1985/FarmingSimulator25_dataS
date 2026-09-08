-- Local values: SellVehicleEvent_mt
SellVehicleEvent = {}
local SellVehicleEvent_mt = Class(SellVehicleEvent, Event)
SellVehicleEvent.SELL_SUCCESS = 0
SellVehicleEvent.SELL_VEHICLE_IN_USE = 1
SellVehicleEvent.SELL_NO_PERMISSION = 2
SellVehicleEvent.SELL_LAST_VEHICLE = 3
InitStaticEventClass(SellVehicleEvent, "SellVehicleEvent")
function SellVehicleEvent.emptyNew()
	-- upvalues: (copy) SellVehicleEvent_mt
	return Event.new(SellVehicleEvent_mt)
end

-- Local values: self
function SellVehicleEvent.new(vehicle, multiplier, isDirectSell)
	local v5_ = SellVehicleEvent.emptyNew()
	v5_.vehicle = vehicle
	v5_.multiplier = Utils.getNoNil(multiplier, 1)
	v5_.isDirectSell = Utils.getNoNil(isDirectSell, false)
	v5_.isOwned = true
	return v5_
end

-- Local values: self
function SellVehicleEvent.newServerToClient(errorCode, sellPrice, isDirectSell, isOwned, ownerFarmId)
	local v11_ = SellVehicleEvent.emptyNew()
	v11_.errorCode = errorCode
	v11_.sellPrice = sellPrice
	v11_.isDirectSell = isDirectSell
	v11_.isOwned = isOwned
	v11_.ownerFarmId = ownerFarmId
	return v11_
end

function SellVehicleEvent:readStream(streamId, connection)
	if connection:getIsServer() then
		self.errorCode = streamReadUIntN(streamId, 2)
		if self.errorCode == SellVehicleEvent.SELL_SUCCESS then
			self.sellPrice = streamReadInt32(streamId)
		end
		self.ownerFarmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
	else
		self.vehicle = NetworkUtil.readNodeObject(streamId)
		self.multiplier = streamReadFloat32(streamId)
	end
	self.isDirectSell = streamReadBool(streamId)
	self.isOwned = streamReadBool(streamId)
	self:run(connection)
end

function SellVehicleEvent:writeStream(streamId, connection)
	if connection:getIsServer() then
		NetworkUtil.writeNodeObject(streamId, self.vehicle)
		streamWriteFloat32(streamId, self.multiplier)
	else
		streamWriteUIntN(streamId, self.errorCode, 2)
		if self.errorCode == SellVehicleEvent.SELL_SUCCESS then
			self.sellPrice = streamWriteInt32(streamId, self.sellPrice)
		end
		streamWriteUIntN(streamId, self.ownerFarmId, FarmManager.FARM_ID_SEND_NUM_BITS)
	end
	streamWriteBool(streamId, self.isDirectSell)
	streamWriteBool(streamId, self.isOwned)
end

-- Local values: errorCode, sellPrice, isOwned
function SellVehicleEvent:run(connection)
	if connection:getIsServer() then
		g_messageCenter:publishDelayedAfterFrames(SellVehicleEvent, 2, self.isDirectSell, self.errorCode, self.sellPrice, self.isOwned, self.ownerFarmId)
	else
		local v20_ = SellVehicleEvent.SELL_SUCCESS
		local v21_ = 0
		local v22_ = self.vehicle.propertyState == VehiclePropertyState.OWNED
		if g_currentMission:getHasPlayerPermission(Farm.PERMISSION.SELL_VEHICLE, connection, self.vehicle:getOwnerFarmId()) then
			if self.vehicle:getIsInUse(connection) then
				v20_ = SellVehicleEvent.SELL_VEHICLE_IN_USE
			else
				if self.vehicle.propertyState == VehiclePropertyState.OWNED then
					local v23_ = self.vehicle:getSellPrice() * self.multiplier
					local v24_ = math.floor(v23_)
					local v25_ = self.vehicle
					v21_ = math.min(v24_, v25_:getPrice())
				end
				if v22_ then
					g_currentMission.vehicleSaleSystem:onVehicleWillSell(self.vehicle)
				end
				self.vehicle:delete()
				g_currentMission:addMoney(v21_, self.vehicle:getOwnerFarmId(), MoneyType.SHOP_VEHICLE_SELL, true)
			end
		else
			v20_ = SellVehicleEvent.SELL_NO_PERMISSION
		end
		connection:sendEvent(SellVehicleEvent.newServerToClient(v20_, v21_, self.isDirectSell, v22_, self.vehicle:getOwnerFarmId()))
	end
end
