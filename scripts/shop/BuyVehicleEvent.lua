-- Local values: BuyVehicleEvent_mt
BuyVehicleEvent = {}
local BuyVehicleEvent_mt = Class(BuyVehicleEvent, Event)
BuyVehicleEvent.STATE_SUCCESS = 0
BuyVehicleEvent.STATE_FAILED_TO_LOAD = 1
BuyVehicleEvent.STATE_NO_SPACE = 2
BuyVehicleEvent.STATE_NO_PERMISSION = 3
BuyVehicleEvent.STATE_NOT_ENOUGH_MONEY = 4
BuyVehicleEvent.STATE_TOO_MANY_BALES = 5
BuyVehicleEvent.STATE_TOO_MANY_PALLETS = 6
InitStaticEventClass(BuyVehicleEvent, "BuyVehicleEvent")
function BuyVehicleEvent.emptyNew()
	-- upvalues: (copy) BuyVehicleEvent_mt
	return Event.new(BuyVehicleEvent_mt)
end

-- Local values: self
function BuyVehicleEvent.new(vehicleBuyData)
	local v3_ = BuyVehicleEvent.emptyNew()
	v3_.vehicleBuyData = vehicleBuyData
	return v3_
end

-- Local values: self
function BuyVehicleEvent.newServerToClient(errorCode, vehicleBuyData)
	local v6_ = BuyVehicleEvent.emptyNew()
	v6_.errorCode = errorCode
	v6_.vehicleBuyData = vehicleBuyData
	return v6_
end

function BuyVehicleEvent:readStream(streamId, connection)
	if self.vehicleBuyData == nil then
		self.vehicleBuyData = BuyVehicleData.new()
	end
	if connection:getIsServer() then
		self.errorCode = streamReadUIntN(streamId, 3)
		self.vehicleBuyData:readStream(streamId, connection)
	else
		self.vehicleBuyData:readStream(streamId, connection)
		self.vehicleBuyData:updatePrice()
	end
	self:run(connection)
end

function BuyVehicleEvent:writeStream(streamId, connection)
	if connection:getIsServer() then
		self.vehicleBuyData:writeStream(streamId, connection)
	else
		streamWriteUIntN(streamId, self.errorCode, 3)
		self.vehicleBuyData:writeStream(streamId, connection)
	end
end

-- Local values: userId, farm, isBalePurchase, isPalletPurchase
function BuyVehicleEvent:run(connection)
	if connection:getIsServer() then
		g_messageCenter:publish(BuyVehicleEvent, self.errorCode, self.vehicleBuyData.leaseVehicle, self.vehicleBuyData.price, self.vehicleBuyData.licensePlateData)
		return
	else
		local v15_ = g_currentMission.userManager:getUserIdByConnection(connection)
		local v16_ = g_farmManager:getFarmByUserId(v15_)
		if v16_ == nil or not g_currentMission:getHasPlayerPermission(Farm.PERMISSION.BUY_VEHICLE, connection) then
			connection:sendEvent(BuyVehicleEvent.newServerToClient(BuyVehicleEvent.STATE_NO_PERMISSION, self.vehicleBuyData))
			return
		elseif self.vehicleBuyData:isValid() then
			if self.vehicleBuyData.price > g_currentMission:getMoney(v16_.farmId) then
				connection:sendEvent(BuyVehicleEvent.newServerToClient(BuyVehicleEvent.STATE_NOT_ENOUGH_MONEY, self.vehicleBuyData))
				return
			else
				local v17_, v18_ = self.vehicleBuyData:getIsLimitedObjectPurchase()
				if v17_ and not g_currentMission.slotSystem:getCanAddLimitedObjects(SlotSystem.LIMITED_OBJECT_BALE, 1) then
					connection:sendEvent(BuyVehicleEvent.newServerToClient(BuyVehicleEvent.STATE_TOO_MANY_BALES, self.vehicleBuyData))
					return
				elseif v18_ and not g_currentMission.slotSystem:getCanAddLimitedObjects(SlotSystem.LIMITED_OBJECT_PALLET, 1) then
					connection:sendEvent(BuyVehicleEvent.newServerToClient(BuyVehicleEvent.STATE_TOO_MANY_PALLETS, self.vehicleBuyData))
				else
					self.vehicleBuyData:buy(g_currentMission.storeSpawnPlaces, g_currentMission.usedStorePlaces, self.onVehicleBoughtCallback, self, {
						["connection"] = connection
					})
				end
			end
		else
			connection:sendEvent(BuyVehicleEvent.newServerToClient(BuyVehicleEvent.STATE_FAILED_TO_LOAD, self.vehicleBuyData))
			return
		end
	end
end

-- Local values: errorCode
function BuyVehicleEvent:onVehicleBoughtCallback(vehicles, loadingState, arguments)
	local v22_ = BuyVehicleEvent.STATE_FAILED_TO_LOAD
	if loadingState == VehicleLoadingState.OK then
		v22_ = BuyVehicleEvent.STATE_SUCCESS
	elseif loadingState == VehicleLoadingState.NO_SPACE then
		v22_ = BuyVehicleEvent.STATE_NO_SPACE
	end
	arguments.connection:sendEvent(BuyVehicleEvent.newServerToClient(v22_, self.vehicleBuyData))
end
