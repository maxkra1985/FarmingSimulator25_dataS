ChangeVehicleConfigEvent = {}
local ChangeVehicleConfigEvent_mt = Class(ChangeVehicleConfigEvent, Event)
ChangeVehicleConfigEvent.STATE_SUCCESS = 0
ChangeVehicleConfigEvent.STATE_FAILED = 1
ChangeVehicleConfigEvent.STATE_NO_PERMISSION = 2
ChangeVehicleConfigEvent.STATE_NOT_ENOUGH_MONEY = 3
ChangeVehicleConfigEvent.STATE_SEND_NUM_BITS = 2
InitStaticEventClass(ChangeVehicleConfigEvent, "ChangeVehicleConfigEvent")
function ChangeVehicleConfigEvent.emptyNew()
	local self = Event.new(ChangeVehicleConfigEvent_mt)
	return self
end
function ChangeVehicleConfigEvent.new(vehicle, vehicleBuyData, isOwnWorkshop)
	local self = ChangeVehicleConfigEvent.emptyNew()
	self.vehicle = vehicle
	self.vehicleBuyData = vehicleBuyData
	self.isOwnWorkshop = isOwnWorkshop == true
	return self
end
function ChangeVehicleConfigEvent.newServerToClient(errorCode)
	local self = ChangeVehicleConfigEvent.emptyNew()
	self.errorCode = errorCode
	return self
end
function ChangeVehicleConfigEvent:readStream(streamId, connection)
	if not connection:getIsServer() then
		self.vehicle = NetworkUtil.readNodeObject(streamId)
		self.vehicleBuyData = BuyVehicleData.new()
		self.vehicleBuyData:readStream(streamId, connection)
		self.isOwnWorkshop = streamReadBool(streamId)
	else
		self.errorCode = streamReadUIntN(streamId, ChangeVehicleConfigEvent.STATE_SEND_NUM_BITS)
	end
	self:run(connection)
end
function ChangeVehicleConfigEvent:writeStream(streamId, connection)
	if connection:getIsServer() then
		NetworkUtil.writeNodeObject(streamId, self.vehicle)
		self.vehicleBuyData:writeStream(streamId, connection)
		streamWriteBool(streamId, self.isOwnWorkshop)
	else
		streamWriteUIntN(streamId, self.errorCode, ChangeVehicleConfigEvent.STATE_SEND_NUM_BITS)
	end
end
function ChangeVehicleConfigEvent:run(connection)
	if connection:getIsServer() then
		g_workshopScreen:onVehicleChanged(self.errorCode)
		return
	end
	local vehicle = self.vehicle
	if vehicle == nil then
		connection:sendEvent(ChangeVehicleConfigEvent.newServerToClient(ChangeVehicleConfigEvent.STATE_FAILED))
		return
	end
	local isControlled = false
	if vehicle.getIsControlled ~= nil then
		isControlled = vehicle:getIsControlled()
	end
	local isOwned = vehicle.propertyState == VehiclePropertyState.OWNED
	if not vehicle.isVehicleSaved or not isOwned or isControlled then
		connection:sendEvent(ChangeVehicleConfigEvent.newServerToClient(ChangeVehicleConfigEvent.STATE_FAILED))
		return
	end
	if not g_currentMission:getHasPlayerPermission(Farm.PERMISSION.BUY_VEHICLE, connection) then
		connection:sendEvent(ChangeVehicleConfigEvent.newServerToClient(ChangeVehicleConfigEvent.STATE_NO_PERMISSION))
		return
	end
	local storeItem = g_storeManager:getItemByXMLFilename(vehicle.configFileName)
	if storeItem == nil then
		connection:sendEvent(ChangeVehicleConfigEvent.newServerToClient(ChangeVehicleConfigEvent.STATE_FAILED))
		return
	end
	local farmId = vehicle:getOwnerFarmId()
	local price = self:getChangePrice(storeItem, vehicle)
	local boughtConfigurations = self:getBoughtConfigurations(vehicle)
	if g_currentMission:getMoney(farmId) < price then
		connection:sendEvent(ChangeVehicleConfigEvent.newServerToClient(ChangeVehicleConfigEvent.STATE_NOT_ENOUGH_MONEY))
	else
		local vehicleSystem = g_currentMission.vehicleSystem
		vehicle:setConfigurations(self.vehicleBuyData.configurations, boughtConfigurations, self.vehicleBuyData.configurationData)
		if vehicle.setLicensePlatesData ~= nil and (vehicle.getHasLicensePlates ~= nil and vehicle:getHasLicensePlates()) then
			vehicle:setLicensePlatesData(self.vehicleBuyData.licensePlateData)
		end
		local spec = vehicle.spec_attacherJoints
		if spec ~= nil and spec.attachedImplements ~= nil then
			for i = #spec.attachedImplements, 1, -1 do
				local implement = spec.attachedImplements[i]
				if implement.object:getIsAdditionalAttachment() then
					continue
				end
				vehicle:detachImplementByObject(implement.object, true)
			end
		end
		vehicle.isReconfigurating = true
		g_server:broadcastEvent(VehicleSetIsReconfiguratingEvent.new(vehicle), nil, nil, vehicle)
		local xmlFile = vehicle:getReloadXML()
		local asyncCallbackFunction = function(_, vehicles)
			local errorCode = ChangeVehicleConfigEvent.STATE_FAILED
			if 0 < #vehicles then
				errorCode = ChangeVehicleConfigEvent.STATE_SUCCESS
				g_currentMission:addMoney(-price, farmId, MoneyType.SHOP_VEHICLE_BUY, true)
				vehicle:removeFromPhysics()
				vehicle:delete(true)
			else
				vehicle:addToPhysics()
				vehicleSystem.vehicleByUniqueId[vehicle:getUniqueId()] = vehicle
			end
			xmlFile:delete()
			connection:sendEvent(ChangeVehicleConfigEvent.newServerToClient(errorCode))
		end
		g_asyncTaskManager:addTask(function()
			vehicleSystem.vehicleByUniqueId[vehicle:getUniqueId()] = nil
			vehicleSystem:loadFromXMLFile(xmlFile, asyncCallbackFunction, nil, {})
		end)
	end
end
function ChangeVehicleConfigEvent:getChangePrice(storeItem, vehicle)
	local serviceFee, upgradePrice, hasChanges = g_currentMission.economyManager:getConfigurationChangePrice(storeItem, vehicle, self.vehicleBuyData.configurations, self.isOwnWorkshop)
	if not hasChanges and ConfigurationUtil.getConfigurationDataHasChanged(vehicle.configFileName, self.vehicleBuyData.configurationData, vehicle.configurationData) then
		hasChanges = true
	end
	if not hasChanges then
		return 0
	else
		return serviceFee + upgradePrice
	end
end
function ChangeVehicleConfigEvent:getBoughtConfigurations(vehicle)
	local boughtConfigurations = table.clone(vehicle.boughtConfigurations, math.huge)
	for configName, configId in pairs(self.vehicleBuyData.configurations) do
		if boughtConfigurations[configName] == nil then
			boughtConfigurations[configName] = {}
		end
		boughtConfigurations[configName][configId] = true
	end
	return boughtConfigurations
end
