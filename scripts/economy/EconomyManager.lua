EconomyManager = {}
source("dataS/scripts/economy/GreatDemandsEvent.lua")
source("dataS/scripts/economy/PricingHistoryInitialEvent.lua")
source("dataS/scripts/economy/PricingHistoryEvent.lua")
source("dataS/scripts/economy/PricingDynamics.lua")
local EconomyManager_mt = Class(EconomyManager)
EconomyManager.sendNumBits = 2
EconomyManager.MAX_GREAT_DEMANDS = 2 ^ EconomyManager.sendNumBits - 1
EconomyManager.PER_DAY_LEASING_FACTOR = 0.01
EconomyManager.DEFAULT_RUNNING_LEASING_FACTOR = 0.021
EconomyManager.DEFAULT_LEASING_DEPOSIT_FACTOR = 0.02
EconomyManager.PRICE_DROP_MIN_PERCENT = 0.6
EconomyManager.PRICE_MULTIPLIER = { 3, 1.8, 1 }
EconomyManager.COST_MULTIPLIER = { 0.4, 0.7, 1 }
EconomyManager.LIFETIME_OPERATINGTIME_RATIO = 0.08333
EconomyManager.CONFIG_CHANGE_PRICE = 1000
EconomyManager.DIRECT_SELL_MULTIPLIER = 1.1
EconomyManager.MAX_DAILYUPKEEP_MULTIPLIER = 4
function EconomyManager.new(customMt)
	local self = setmetatable({}, customMt or EconomyManager_mt)
	self.minuteUpdateInterval = 5
	self.minuteTimer = self.minuteUpdateInterval
	self.showMoneyChangeNextMinute = false
	self.greatDemandFillTypes = {}
	self.greatDemands = {}
	self.numberOfConcurrentDemands = EconomyManager.MAX_GREAT_DEMANDS
	g_messageCenter:subscribe(MessageType.MINUTE_CHANGED, self.minuteChanged, self)
	g_messageCenter:subscribe(MessageType.HOUR_CHANGED, self.hourChanged, self)
	g_messageCenter:subscribe(MessageType.DAY_CHANGED, self.dayChanged, self)
	g_messageCenter:subscribe(MessageType.PERIOD_CHANGED, self.periodChanged, self)
	self.sellingStations = {}
	self.sellingStationUpdateIndex = 1
	return self
end
function EconomyManager:init(mission)
	for _ = 1, self.numberOfConcurrentDemands do
		local greatDemand = GreatDemandSpecs.new()
		greatDemand:setUpRandomDemand(true, self.greatDemands, mission)
		table.insert(self.greatDemands, greatDemand)
	end
end
function EconomyManager:delete()
	g_messageCenter:unsubscribeAll(self)
end
function EconomyManager:saveToXMLFile(xmlFileHandle, key)
	local xmlFile = XMLFile.wrap(xmlFileHandle)
	xmlFile:setSortedTable(key .. ".greatDemands.greatDemand", self.greatDemands, function(demandKey, greatDemand)
		local fillTypeName = g_fillTypeManager:getFillTypeNameByIndex(greatDemand.fillTypeIndex)
		if fillTypeName ~= nil then
			local uniqueId = greatDemand.sellStation.owningPlaceable:getUniqueId()
			if uniqueId ~= nil then
				xmlFile:setString(demandKey .. "#uniqueId", uniqueId)
				xmlFile:setString(demandKey .. "#fillTypeName", fillTypeName)
				xmlFile:setFloat(demandKey .. "#demandMultiplier", greatDemand.demandMultiplier)
				xmlFile:setInt(demandKey .. "#demandStartDay", greatDemand.demandStart.day)
				xmlFile:setInt(demandKey .. "#demandStartHour", greatDemand.demandStart.hour)
				xmlFile:setInt(demandKey .. "#demandDuration", greatDemand.demandDuration)
				xmlFile:setBool(demandKey .. "#isRunning", greatDemand.isRunning)
				xmlFile:setBool(demandKey .. "#isValid", greatDemand.isValid)
			end
		end
	end)
	xmlFile:setSortedTable(key .. ".fillTypes.fillType", g_fillTypeManager:getFillTypes(), function(fillTypeKey, fillType)
		xmlFile:setString(fillTypeKey .. "#fillType", fillType.name)
		if 0 < fillType.totalAmount then
			xmlFile:setInt(fillTypeKey .. "#totalAmount", fillType.totalAmount)
		end
		xmlFile:setSortedTable(fillTypeKey .. ".history.period", fillType.economy.history, function(periodKey, price, period)
			SeasonPeriod.saveToXMLFile(xmlFile, periodKey .. "#period", period)
			xmlFile:setInt(periodKey, math.round(price * 1000))
		end)
	end)
	xmlFile:delete()
end
function EconomyManager:loadFromXMLFile(xmlFileHandle, key)
	local xmlFile = XMLFile.wrap(xmlFileHandle)
	self.greatDemandToLoad = {}
	xmlFile:iterate(key .. ".greatDemands.greatDemand", function(_, demandKey)
		local uniqueId = xmlFile:getString(demandKey .. "#uniqueId")
		if uniqueId == nil then
			return
		end
		local fillTypeName = xmlFile:getString(demandKey .. "#fillTypeName")
		local fillType = g_fillTypeManager:getFillTypeByName(fillTypeName)
		local fillTypeIndex = nil
		if fillType ~= nil then
			fillTypeIndex = fillType.index
		end
		if fillTypeIndex == nil then
			return
		else
			local greatDemand = {}
			greatDemand.uniqueId = uniqueId
			greatDemand.fillTypeIndex = fillTypeIndex
			greatDemand.demandMultiplier = xmlFile:getFloat(demandKey .. "#demandMultiplier")
			greatDemand.day = xmlFile:getInt(demandKey .. "#demandStartDay")
			greatDemand.hour = xmlFile:getInt(demandKey .. "#demandStartHour")
			greatDemand.demandDuration = xmlFile:getInt(demandKey .. "#demandDuration")
			greatDemand.isRunning = xmlFile:getBool(demandKey .. "#isRunning", false)
			greatDemand.isValid = xmlFile:getBool(demandKey .. "#isValid", false)
			table.insert(self.greatDemandToLoad, greatDemand)
		end
	end)
	xmlFile:iterate(key .. ".fillTypes.fillType", function(_, fillTypeKey)
		local fillTypeName = xmlFile:getString(fillTypeKey .. "#fillType")
		if fillTypeName == nil then
			return
		else
			local fillType = g_fillTypeManager:getFillTypeByName(fillTypeName)
			if fillType ~= nil then
				fillType.totalAmount = xmlFile:getInt(fillTypeKey .. "#totalAmount", fillType.totalAmount)
				xmlFile:iterate(fillTypeKey .. ".history.period", function(_, periodKey)
					local period = SeasonPeriod.loadFromXMLFile(xmlFile, periodKey .. "#period")
					if period ~= nil then
						fillType.economy.history[period] = xmlFile:getInt(periodKey, fillType.economy.history[period]) / 1000
					end
				end)
			end
		end
	end)
	xmlFile:delete()
end
function EconomyManager:finalizeGreatDemandLoading()
	if self.greatDemandToLoad ~= nil then
		local i = 1
		for _, greatDemandToLoad in ipairs(self.greatDemandToLoad) do
			local placeable = g_currentMission.placeableSystem:getPlaceableByUniqueId(greatDemandToLoad.uniqueId)
			if placeable == nil then
				continue
			end
			if placeable.getSellingStation ~= nil then
				local station = placeable:getSellingStation()
				if station == nil then
					continue
				end
				if station.getSupportsGreatDemand and station:getSupportsGreatDemand(greatDemandToLoad.fillTypeIndex) then
					local greatDemand = self.greatDemands[i]
					greatDemand.sellStation = station
					greatDemand.fillTypeIndex = greatDemandToLoad.fillTypeIndex
					greatDemand.demandMultiplier = greatDemandToLoad.demandMultiplier
					greatDemand.demandStart.day = greatDemandToLoad.day
					greatDemand.demandStart.hour = greatDemandToLoad.hour
					greatDemand.demandDuration = greatDemandToLoad.demandDuration
					greatDemand.isRunning = greatDemandToLoad.isRunning
					greatDemand.isValid = greatDemandToLoad.isValid
					i = i + 1
				end
			else
				Logging.warning("Placeable is not a selling station (%s)", placeable.configFileName)
			end
		end
		self.greatDemandToLoad = nil
	end
end
function EconomyManager:addSellingStation(sellingStation)
	local alreadyAdded = false
	for k, data in ipairs(self.sellingStations) do
		if data.station == sellingStation then
			alreadyAdded = true
			break
		end
	end
	if not alreadyAdded then
		table.insert(self.sellingStations, { station = sellingStation, dt = 0, scaledDt = 0 })
	end
end
function EconomyManager:removeSellingStation(sellingStation)
	for k, data in ipairs(self.sellingStations) do
		if data.station == sellingStation then
			table.remove(self.sellingStations, k)
			if self.currentUpdatingSellingStation == sellingStation then
				self.currentUpdatingSellingStation = nil
			end
			for i = #self.greatDemands, 1, -1 do
				local greatDemand = self.greatDemands[i]
				if greatDemand.sellStation == sellingStation then
					table.remove(self.greatDemands, i)
				end
			end
			return
		end
	end
end
function EconomyManager:updateSellingStations(dt)
	if self.currentUpdatingSellingStation == nil then
		self.sellingStationUpdateIndex = self.sellingStationUpdateIndex + 1
		if #self.sellingStations < self.sellingStationUpdateIndex then
			self.sellingStationUpdateIndex = 1
		end
		self.currentUpdatingSellingStation = self.sellingStations[self.sellingStationUpdateIndex]
	end
	if self.currentUpdatingSellingStation ~= nil then
		local station = self.currentUpdatingSellingStation.station
		local isDone = station:updateSellingStationPrices()
		if isDone then
			self.currentUpdatingSellingStation = nil
		end
	end
end
function EconomyManager:update(dt)
	self:updateSellingStations(dt)
end
function EconomyManager:dayChanged()
	if g_currentMission:getIsServer() then
		local timeAdjustment = g_currentMission.environment.timeAdjustment
		for _, farm in ipairs(g_farmManager.farms) do
			local farmId = farm.farmId
			if farmId == FarmManager.SPECTATOR_FARM_ID then
				continue
			end
			local money = -farm:calculateDailyLoanInterest()
			g_currentMission:addMoney(money, farmId, MoneyType.LOAN_INTEREST, true)
			local perDayLeasingCosts = 0
			for _, item in pairs(g_currentMission.leasedItems) do
				for _, vehicle in pairs(item.items) do
					if vehicle:getOwnerFarmId() == farmId then
						perDayLeasingCosts = perDayLeasingCosts + vehicle:getPrice() * EconomyManager.PER_DAY_LEASING_FACTOR * timeAdjustment
					end
				end
			end
			if 0 < perDayLeasingCosts then
				g_currentMission:addMoney(-perDayLeasingCosts, farmId, MoneyType.LEASING_COSTS, true)
			end
			local vehicleUpkeep = 0
			local facilityUpkeep = 0
			for storeItem, item in pairs(g_currentMission.ownedItems) do
				if StoreItemUtil.getIsVehicle(storeItem) then
					for _, realItem in pairs(item.items) do
						if realItem:getOwnerFarmId() == farmId then
							vehicleUpkeep = vehicleUpkeep + realItem:getDailyUpkeep() * timeAdjustment
						end
					end
				elseif StoreItemUtil.getIsPlaceable(storeItem) then
					for _, realItem in pairs(item.items) do
						if realItem:getOwnerFarmId() == farmId then
							facilityUpkeep = facilityUpkeep + realItem:getDailyUpkeep() * timeAdjustment
						end
					end
				end
			end
			if 0 < vehicleUpkeep then
				g_currentMission:addMoney(-vehicleUpkeep, farmId, MoneyType.VEHICLE_RUNNING_COSTS, true)
			end
			if 0 < facilityUpkeep then
				g_currentMission:addMoney(-facilityUpkeep, farmId, MoneyType.PROPERTY_MAINTENANCE, true)
			end
		end
		self.showMoneyChangeNextMinute = true
	end
end
function EconomyManager:hourChanged(hour)
	if g_currentMission:getIsServer() then
		self:manageGreatDemands()
	end
	self:updateFillTypeHistory()
end
function EconomyManager:vehicleOperatingHourChanged(vehicle)
	if g_currentMission:getIsServer() then
		local storeItem = g_storeManager:getItemByXMLFilename(vehicle.configFileName)
		local vehicleRunningLeasingCosts = storeItem.runningLeasingFactor * vehicle:getPrice()
		if 0 < vehicleRunningLeasingCosts then
			g_currentMission:addMoney(-vehicleRunningLeasingCosts, vehicle:getOwnerFarmId(), MoneyType.LEASING_COSTS, true)
		end
	end
end
function EconomyManager:minuteChanged()
	if self.showMoneyChangeNextMinute then
		g_currentMission:showMoneyChange(MoneyType.LOAN_INTEREST)
		g_currentMission:showMoneyChange(MoneyType.LEASING_COSTS)
		g_currentMission:showMoneyChange(MoneyType.VEHICLE_RUNNING_COSTS)
		g_currentMission:showMoneyChange(MoneyType.PROPERTY_MAINTENANCE)
		g_currentMission:showMoneyChange(MoneyType.PROPERTY_INCOME)
		g_currentMission:showMoneyChange(MoneyType.ANIMAL_UPKEEP)
		g_currentMission:showMoneyChange(MoneyType.PRODUCTION_COSTS)
		self.showMoneyChangeNextMinute = false
	end
end
function EconomyManager:periodChanged(period)
	if g_currentMission:getIsServer() then
		self:sendPeriodFillTypeHistory((period - 2) % 12 + 1)
	end
end
function EconomyManager:updateGreatDemandsPDASpots()
	for _, greatDemand in pairs(self.greatDemands) do
		if greatDemand.isValid and greatDemand.isRunning then
			local station = greatDemand.sellStation
			if station == nil or station.mapHotspot == nil or station.mapHotspot.isBlinking then
				continue
			end
			station.mapHotspot:setBlinking(true)
			station.mapHotspot:setPersistent(true)
		end
	end
end
function EconomyManager:restartGreatDemands()
	self:finalizeGreatDemandLoading()
	for _, greatDemand in pairs(self.greatDemands) do
		if greatDemand.isValid and greatDemand.isRunning then
			local station = greatDemand.sellStation
			if station == nil then
				continue
			end
			if station:getSupportsGreatDemand(greatDemand.fillTypeIndex) then
				station:setIsInGreatDemand(greatDemand.fillTypeIndex, true)
				self.greatDemandFillTypes[greatDemand.fillTypeIndex] = true
				if station.mapHotspot ~= nil then
					station.mapHotspot:setBlinking(true)
					station.mapHotspot:setPersistent(true)
				end
				station:setPriceMultiplier(greatDemand.fillTypeIndex, greatDemand.demandMultiplier)
			end
		end
	end
end
function EconomyManager:manageGreatDemands()
	for _, greatDemand in pairs(self.greatDemands) do
		if greatDemand.isValid then
			if greatDemand.isRunning then
				greatDemand.demandDuration = greatDemand.demandDuration - 1
				if greatDemand.demandDuration <= 0 then
					self:stopGreatDemand(greatDemand)
				end
			else
				if greatDemand.isRunning then
					continue
				end
				if greatDemand.demandStart.day == g_currentMission.environment.currentMonotonicDay and greatDemand.demandStart.hour <= g_currentMission.environment.currentHour then
					self:startGreatDemand(greatDemand)
				end
			end
		end
	end
	g_server:broadcastEvent(GreatDemandsEvent.new(self.greatDemands))
	for _, greatDemand in pairs(self.greatDemands) do
		if not greatDemand.isValid or not greatDemand.isRunning and greatDemand.demandStart.day < g_currentMission.environment.currentMonotonicDay then
			greatDemand:setUpRandomDemand(true, self.greatDemands, g_currentMission)
		end
	end
end
function EconomyManager:stopGreatDemand(greatDemand)
	greatDemand.isRunning = false
	greatDemand.isValid = false
	local sellStation = greatDemand.sellStation
	if sellStation ~= nil and sellStation:getSupportsGreatDemand(greatDemand.fillTypeIndex) then
		sellStation:setIsInGreatDemand(greatDemand.fillTypeIndex, false)
		self.greatDemandFillTypes[greatDemand.fillTypeIndex] = nil
		if sellStation.mapHotspot ~= nil then
			sellStation.mapHotspot:setBlinking(false)
			sellStation.mapHotspot:setPersistent(false)
		end
		sellStation:setPriceMultiplier(greatDemand.fillTypeIndex, 1)
	end
end
function EconomyManager:startGreatDemand(greatDemand)
	greatDemand.isRunning = true
	local sellStation = greatDemand.sellStation
	if sellStation ~= nil then
		g_currentMission.hud:addSideNotification(FSBaseMission.INGAME_NOTIFICATION_GREATDEMAND, string.format(g_i18n:getText("notification_greatDemand"), sellStation:getName()), 40000, GuiSoundPlayer.SOUND_SAMPLES.NOTIFICATION)
		if sellStation:getSupportsGreatDemand(greatDemand.fillTypeIndex) then
			sellStation:setIsInGreatDemand(greatDemand.fillTypeIndex, true)
			self.greatDemandFillTypes[greatDemand.fillTypeIndex] = true
			if sellStation.mapHotspot ~= nil then
				sellStation.mapHotspot:setBlinking(true)
				sellStation.mapHotspot:setPersistent(true)
			end
			sellStation:setPriceMultiplier(greatDemand.fillTypeIndex, greatDemand.demandMultiplier)
		end
	end
end
function EconomyManager:getGreatDemandById(id)
	return self.greatDemands[id]
end
function EconomyManager:getHasFillTypeGreatDemand(fillTypeIndex)
	return self.greatDemandFillTypes[fillTypeIndex] == true
end
function EconomyManager:getPricePerLiter(fillTypeIndex, useMultiplier)
	local fillType = g_fillTypeManager:getFillTypeByIndex(fillTypeIndex)
	local difficultyMultiplier = EconomyManager.getPriceMultiplier()
	if useMultiplier ~= nil and not useMultiplier then
		difficultyMultiplier = 1
	end
	local period, alpha = g_currentMission.environment:getPeriodAndAlphaIntoPeriod()
	local seasonalFactor = self:getFillTypeSeasonalFactor(fillType, period, alpha)
	return fillType.pricePerLiter * difficultyMultiplier * seasonalFactor
end
function EconomyManager:getCostPerLiter(fillTypeIndex, useMultiplier)
	local fillType = g_fillTypeManager:getFillTypeByIndex(fillTypeIndex)
	local difficultyMultiplier = EconomyManager.getCostMultiplier()
	if useMultiplier ~= nil and not useMultiplier then
		difficultyMultiplier = 1
	end
	local period, alpha = g_currentMission.environment:getPeriodAndAlphaIntoPeriod()
	local seasonalFactor = self:getFillTypeSeasonalFactor(fillType, period, alpha)
	return fillType.pricePerLiter * difficultyMultiplier * seasonalFactor
end
function EconomyManager:getBuyPrice(storeItem, configurations, saleItem)
	local price = storeItem.price
	if saleItem ~= nil then
		price = saleItem.price
	end
	local upgradePrice = 0
	if configurations ~= nil then
		for name, id in pairs(configurations) do
			local configs = storeItem.configurations[name]
			if configs == nil then
				continue
			end
			local hasBought = false
			if saleItem ~= nil then
				hasBought = false
				if saleItem.boughtConfigurations[name] ~= nil then
					hasBought = saleItem.boughtConfigurations[name][id]
				end
			end
			if hasBought then
				continue
			end
			upgradePrice = upgradePrice + configs[id].price
			price = price + configs[id].price
		end
	end
	return price, upgradePrice
end
function EconomyManager:getConfigurationChangePrice(storeItem, vehicle, configurations, isOwnWorkshop)
	local upgradePrice = 0
	local hasConfigurationChanges = false
	if storeItem.configurations ~= nil and configurations ~= nil then
		for name, id in pairs(configurations) do
			if vehicle.configurations[name] == id then
				continue
			end
			hasConfigurationChanges = true
			local configs = storeItem.configurations[name]
			if configs == nil or configs[id] == nil or ConfigurationUtil.hasBoughtConfiguration(vehicle, name, id) then
				continue
			end
			upgradePrice = upgradePrice + configs[id].price
		end
	end
	local serviceFee = 0
	if not isOwnWorkshop then
		serviceFee = EconomyManager.CONFIG_CHANGE_PRICE
	end
	return serviceFee, upgradePrice, hasConfigurationChanges
end
function EconomyManager:getSellPrice(object)
	if object.getSellPrice ~= nil then
		return object:getSellPrice()
	else
		return math.floor(object.price * 0.5)
	end
end
function EconomyManager:getInitialLeasingPrice(price)
	return price * (EconomyManager.DEFAULT_LEASING_DEPOSIT_FACTOR + EconomyManager.PER_DAY_LEASING_FACTOR + EconomyManager.DEFAULT_RUNNING_LEASING_FACTOR)
end
function EconomyManager.getPriceMultiplier(fillType, fillFormat)
	return EconomyManager.PRICE_MULTIPLIER[g_currentMission.missionInfo.economicDifficulty]
end
function EconomyManager.getCostMultiplier(fillTypeIndex)
	return EconomyManager.COST_MULTIPLIER[g_currentMission.missionInfo.economicDifficulty]
end
function EconomyManager:getFillTypeSeasonalFactor(fillType, period, alpha)
	period = period - 1
	local p0 = (period - 1) % 12 + 1
	local p1 = (period + 0) % 12 + 1
	local p2 = (period + 1) % 12 + 1
	local p3 = (period + 2) % 12 + 1
	local factors = fillType.economy.factors
	return MathUtil.catmullRom(factors[p0], factors[p1], factors[p2], factors[p3], alpha)
end
function EconomyManager:getFillTypeHistoricPrice(fillType, period)
	return fillType.economy.history[period] * EconomyManager.getPriceMultiplier()
end
function EconomyManager:updateFillTypeHistory()
	local period = g_currentMission.environment.currentPeriod
	for fillTypeIndex, fillType in ipairs(g_fillTypeManager:getFillTypes()) do
		local num = 0
		local total = 0
		for _, sellingStation in ipairs(self.sellingStations) do
			if sellingStation.station.acceptedFillTypes[fillTypeIndex] then
				local price = sellingStation.station:getEffectiveFillTypePrice(fillTypeIndex, ToolType.UNDEFINED) / EconomyManager.getPriceMultiplier()
				num = num + 1
				total = total + price
			end
		end
		if 0 < num then
			local historicPrice = fillType.economy.history[period]
			local price = total / num
			local hoursPassed = g_currentMission.environment.currentHour
			historicPrice = (hoursPassed * historicPrice + price) / (hoursPassed + 1)
			fillType.economy.history[period] = historicPrice
		end
	end
end
function EconomyManager:sendPeriodFillTypeHistory(period)
	g_server:broadcastEvent(PricingHistoryEvent.new(period))
end
