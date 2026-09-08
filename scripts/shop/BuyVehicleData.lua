-- Local values: BuyVehicleData_mt
BuyVehicleData = {}
local BuyVehicleData_mt = Class(BuyVehicleData)

-- Upvalues: BuyVehicleData_mt
-- Local values: self
function BuyVehicleData.new(customMt)
	-- upvalues: (copy) BuyVehicleData_mt
	local v3_ = customMt or BuyVehicleData_mt
	local v4_ = setmetatable({}, v3_)
	v4_.storeItem = nil
	v4_.isFreeOfCharge = false
	v4_.configurations = {}
	v4_.boughtConfigurations = {}
	v4_.configurationData = {}
	v4_.leaseVehicle = false
	v4_.ownerFarmId = AccessHandler.EVERYONE
	v4_.licensePlateData = nil
	v4_.saleItem = nil
	v4_.price = 0
	return v4_
end

function BuyVehicleData:isValid()
	if self.storeItem == nil then
		return false
	else
		return (not GS_IS_CONSOLE_VERSION or fileExists(self.storeItem.xmlFilename)) and true or false
	end
end

function BuyVehicleData:setStoreItem(storeItem)
	self.storeItem = storeItem
end

function BuyVehicleData:setIsFreeOfCharge(isFreeOfCharge)
	self.isFreeOfCharge = isFreeOfCharge
end

-- Local values: configName, index
function BuyVehicleData:setConfigurations(configurations, boughtConfigurations)
	self.configurations = configurations or self.configurations
	self.boughtConfigurations = boughtConfigurations or self.boughtConfigurations
	for v13_, v14_ in pairs(self.configurations) do
		if self.boughtConfigurations[v13_] == nil then
			self.boughtConfigurations[v13_] = {}
		end
		self.boughtConfigurations[v13_][v14_] = true
	end
end

function BuyVehicleData:setConfigurationData(configurationData)
	self.configurationData = configurationData or self.configurationData
end

function BuyVehicleData:setLeaseVehicle(leaseVehicle)
	self.leaseVehicle = leaseVehicle
end

function BuyVehicleData:setOwnerFarmId(ownerFarmId)
	self.ownerFarmId = ownerFarmId
end

function BuyVehicleData:setLicensePlateData(licensePlateData)
	self.licensePlateData = licensePlateData
end

function BuyVehicleData:setSaleItem(saleItem)
	self.saleItem = saleItem
end

function BuyVehicleData:setPrice(price)
	self.price = price
end

function BuyVehicleData:updatePrice()
	self.price = g_currentMission.economyManager:getBuyPrice(self.storeItem, self.configurations, self.saleItem)
	if self.leaseVehicle then
		self.price = g_currentMission.economyManager:getInitialLeasingPrice(self.price)
	end
end

-- Local values: xmlFile, isBalePurchase, isPalletPurchase
function BuyVehicleData:getIsLimitedObjectPurchase()
	local v29_ = XMLFile.load("BuyVehicleDataVehicleXML", self.storeItem.xmlFilename, nil)
	local v30_ = v29_:hasProperty("vehicle.multipleItemPurchase")
	if v30_ then
		v30_ = v29_:getBool("vehicle.multipleItemPurchase#isVehicle") == false
	end
	local v31_ = v29_:hasProperty("vehicle.multipleItemPurchase")
	if v31_ then
		v31_ = v29_:getBool("vehicle.multipleItemPurchase#isVehicle")
	end
	v29_:delete()
	return v30_, v31_
end

-- Local values: xmlFilename, saleId
function BuyVehicleData:readStream(streamId, connection)
	local v35_ = NetworkUtil.convertFromNetworkFilename(streamReadString(streamId))
	self.storeItem = g_storeManager:getItemByXMLFilename(string.lower(v35_))
	self.isFreeOfCharge = streamReadBool(streamId)
	local v36_, v37_, v38_ = ConfigurationUtil.readConfigurationsFromStream(g_vehicleConfigurationManager, streamId, connection, v35_)
	self.configurations = v36_
	self.boughtConfigurations = v37_
	self.configurationData = v38_
	self.leaseVehicle = streamReadBool(streamId)
	self.ownerFarmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
	self.licensePlateData = LicensePlateManager.readLicensePlateData(streamId, connection)
	local v39_ = streamReadUInt8(streamId)
	if v39_ ~= 0 then
		self.saleItem = g_currentMission.vehicleSaleSystem:getSaleById(v39_)
	end
end

function BuyVehicleData:writeStream(streamId, connection)
	streamWriteString(streamId, NetworkUtil.convertToNetworkFilename(self.storeItem.xmlFilename))
	streamWriteBool(streamId, self.isFreeOfCharge)
	ConfigurationUtil.writeConfigurationsToStream(g_vehicleConfigurationManager, streamId, connection, self.storeItem.xmlFilename, self.configurations, self.boughtConfigurations, self.configurationData)
	streamWriteBool(streamId, self.leaseVehicle)
	streamWriteUIntN(streamId, self.ownerFarmId, FarmManager.FARM_ID_SEND_NUM_BITS)
	LicensePlateManager.writeLicensePlateData(streamId, connection, self.licensePlateData)
	if self.saleItem == nil then
		streamWriteUInt8(streamId, 0)
	else
		streamWriteUInt8(streamId, self.saleItem.id)
	end
end

-- Local values: data
function BuyVehicleData:buy(storePlaces, usedStorePlaces, callback, callbackTarget, callbackArguments)
	local v49_ = VehicleLoadingData.new()
	v49_:setStoreItem(self.storeItem)
	v49_:setConfigurations(self.configurations, self.boughtConfigurations)
	v49_:setConfigurationData(self.configurationData)
	v49_:setLoadingPlace(storePlaces, usedStorePlaces)
	v49_:setPropertyState(self.leaseVehicle and VehiclePropertyState.LEASED or VehiclePropertyState.OWNED)
	v49_:setOwnerFarmId(self.ownerFarmId)
	v49_:setSaleItem(self.saleItem)
	v49_:load(self.onBought, self, {
		["callback"] = callback,
		["callbackTarget"] = callbackTarget,
		["callbackArguments"] = callbackArguments
	})
end

-- Local values: _, vehicle, financeCategory
function BuyVehicleData:onBought(vehicles, loadingState, arguments)
	if loadingState == VehicleLoadingState.OK then
		for _, v54_ in pairs(vehicles) do
			if v54_.setLicensePlatesData ~= nil and (v54_.getHasLicensePlates ~= nil and v54_:getHasLicensePlates()) then
				v54_:setLicensePlatesData(self.licensePlateData)
			end
		end
		if not self.isFreeOfCharge then
			if self.leaseVehicle then
				g_currentMission:addMoney(-self.price, self.ownerFarmId, MoneyType.LEASING_COSTS, true)
			else
				local v55_ = MoneyType.getMoneyTypeByName(self.storeItem.financeCategory) or MoneyType.SHOP_VEHICLE_BUY
				g_currentMission:addMoney(-self.price, self.ownerFarmId, v55_, true)
				if self.saleItem ~= nil then
					g_currentMission.vehicleSaleSystem:onVehicleBought(self.saleItem)
				end
			end
		end
	end
	if arguments.callback ~= nil then
		arguments.callback(arguments.callbackTarget, vehicles, loadingState, arguments.callbackArguments)
	end
end
