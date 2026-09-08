-- Local values: EconomyManager_mt
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

-- Upvalues: EconomyManager_mt
-- Local values: self
function EconomyManager.new(customMt)
	-- upvalues: (copy) EconomyManager_mt
	local v3_ = customMt or EconomyManager_mt
	local v4_ = setmetatable({}, v3_)
	v4_.minuteUpdateInterval = 5
	v4_.minuteTimer = v4_.minuteUpdateInterval
	v4_.showMoneyChangeNextMinute = false
	v4_.greatDemandFillTypes = {}
	v4_.greatDemands = {}
	v4_.numberOfConcurrentDemands = EconomyManager.MAX_GREAT_DEMANDS
	g_messageCenter:subscribe(MessageType.MINUTE_CHANGED, v4_.minuteChanged, v4_)
	g_messageCenter:subscribe(MessageType.HOUR_CHANGED, v4_.hourChanged, v4_)
	g_messageCenter:subscribe(MessageType.DAY_CHANGED, v4_.dayChanged, v4_)
	g_messageCenter:subscribe(MessageType.PERIOD_CHANGED, v4_.periodChanged, v4_)
	v4_.sellingStations = {}
	v4_.sellingStationUpdateIndex = 1
	return v4_
end

-- Local values: _, greatDemand
function EconomyManager:init(mission)
	for _ = 1, self.numberOfConcurrentDemands do
		local v7_ = GreatDemandSpecs.new()
		v7_:setUpRandomDemand(true, self.greatDemands, mission)
		local v8_ = self.greatDemands
		table.insert(v8_, v7_)
	end
end

function EconomyManager:delete()
	g_messageCenter:unsubscribeAll(self)
end

-- Local values: xmlFile
function EconomyManager:saveToXMLFile(xmlFileHandle, key)
	local v_u_13_ = XMLFile.wrap(xmlFileHandle)
	v_u_13_:setSortedTable(key .. ".greatDemands.greatDemand", self.greatDemands, function(p14_, p15_)
		-- upvalues: (copy) v_u_13_
		local v16_ = g_fillTypeManager:getFillTypeNameByIndex(p15_.fillTypeIndex)
		if v16_ ~= nil then
			local v17_ = p15_.sellStation.owningPlaceable:getUniqueId()
			if v17_ ~= nil then
				v_u_13_:setString(p14_ .. "#uniqueId", v17_)
				v_u_13_:setString(p14_ .. "#fillTypeName", v16_)
				v_u_13_:setFloat(p14_ .. "#demandMultiplier", p15_.demandMultiplier)
				v_u_13_:setInt(p14_ .. "#demandStartDay", p15_.demandStart.day)
				v_u_13_:setInt(p14_ .. "#demandStartHour", p15_.demandStart.hour)
				v_u_13_:setInt(p14_ .. "#demandDuration", p15_.demandDuration)
				v_u_13_:setBool(p14_ .. "#isRunning", p15_.isRunning)
				v_u_13_:setBool(p14_ .. "#isValid", p15_.isValid)
			end
		end
	end)
	v_u_13_:setSortedTable(key .. ".fillTypes.fillType", g_fillTypeManager:getFillTypes(), function(p18_, p19_)
		-- upvalues: (copy) v_u_13_
		v_u_13_:setString(p18_ .. "#fillType", p19_.name)
		if p19_.totalAmount > 0 then
			v_u_13_:setInt(p18_ .. "#totalAmount", p19_.totalAmount)
		end
		v_u_13_:setSortedTable(p18_ .. ".history.period", p19_.economy.history, function(p20_, p21_, p22_)
			-- upvalues: (ref) v_u_13_
			SeasonPeriod.saveToXMLFile(v_u_13_, p20_ .. "#period", p22_)
			local v23_ = v_u_13_
			local v24_ = p21_ * 1000
			v23_:setInt(p20_, (math.round(v24_)))
		end)
	end)
	v_u_13_:delete()
end

-- Local values: xmlFile
function EconomyManager:loadFromXMLFile(xmlFileHandle, key)
	local v_u_28_ = XMLFile.wrap(xmlFileHandle)
	self.greatDemandToLoad = {}
	v_u_28_:iterate(key .. ".greatDemands.greatDemand", function(_, p29_)
		-- upvalues: (copy) v_u_28_, (copy) self
		local v30_ = v_u_28_:getString(p29_ .. "#uniqueId")
		if v30_ == nil then
			return
		else
			local v31_ = v_u_28_:getString(p29_ .. "#fillTypeName")
			local v32_ = g_fillTypeManager:getFillTypeByName(v31_)
			local v33_
			if v32_ == nil then
				v33_ = nil
			else
				v33_ = v32_.index
			end
			if v33_ ~= nil then
				local v34_ = {
					["uniqueId"] = v30_,
					["fillTypeIndex"] = v33_,
					["demandMultiplier"] = v_u_28_:getFloat(p29_ .. "#demandMultiplier"),
					["day"] = v_u_28_:getInt(p29_ .. "#demandStartDay"),
					["hour"] = v_u_28_:getInt(p29_ .. "#demandStartHour"),
					["demandDuration"] = v_u_28_:getInt(p29_ .. "#demandDuration"),
					["isRunning"] = v_u_28_:getBool(p29_ .. "#isRunning", false),
					["isValid"] = v_u_28_:getBool(p29_ .. "#isValid", false)
				}
				local v35_ = self.greatDemandToLoad
				table.insert(v35_, v34_)
			end
		end
	end)
	v_u_28_:iterate(key .. ".fillTypes.fillType", function(_, p36_)
		-- upvalues: (copy) v_u_28_
		local v37_ = v_u_28_:getString(p36_ .. "#fillType")
		if v37_ ~= nil then
			local v_u_38_ = g_fillTypeManager:getFillTypeByName(v37_)
			if v_u_38_ ~= nil then
				v_u_38_.totalAmount = v_u_28_:getInt(p36_ .. "#totalAmount", v_u_38_.totalAmount)
				v_u_28_:iterate(p36_ .. ".history.period", function(_, p39_)
					-- upvalues: (ref) v_u_28_, (copy) v_u_38_
					local v40_ = SeasonPeriod.loadFromXMLFile(v_u_28_, p39_ .. "#period")
					if v40_ ~= nil then
						v_u_38_.economy.history[v40_] = v_u_28_:getInt(p39_, v_u_38_.economy.history[v40_]) / 1000
					end
				end)
			end
		end
	end)
	v_u_28_:delete()
end

-- Local values: i, _, greatDemandToLoad, placeable, station, greatDemand
function EconomyManager:finalizeGreatDemandLoading()
	if self.greatDemandToLoad ~= nil then
		local v42_ = 1
		for _, v43_ in ipairs(self.greatDemandToLoad) do
			local v44_ = g_currentMission.placeableSystem:getPlaceableByUniqueId(v43_.uniqueId)
			if v44_ ~= nil then
				if v44_.getSellingStation == nil then
					Logging.warning("Placeable is not a selling station (%s)", v44_.configFileName)
				else
					local v45_ = v44_:getSellingStation()
					if v45_ ~= nil and (v45_.getSupportsGreatDemand and v45_:getSupportsGreatDemand(v43_.fillTypeIndex)) then
						local v46_ = self.greatDemands[v42_]
						v46_.sellStation = v45_
						v46_.fillTypeIndex = v43_.fillTypeIndex
						v46_.demandMultiplier = v43_.demandMultiplier
						v46_.demandStart.day = v43_.day
						v46_.demandStart.hour = v43_.hour
						v46_.demandDuration = v43_.demandDuration
						v46_.isRunning = v43_.isRunning
						v46_.isValid = v43_.isValid
						v42_ = v42_ + 1
					end
				end
			end
		end
		self.greatDemandToLoad = nil
	end
end

-- Local values: alreadyAdded, k, data
function EconomyManager:addSellingStation(sellingStation)
	local v49_ = false
	for _, v50_ in ipairs(self.sellingStations) do
		if v50_.station == sellingStation then
			v49_ = true
			break
		end
	end
	if not v49_ then
		local v51_ = self.sellingStations
		table.insert(v51_, {
			["station"] = sellingStation,
			["dt"] = 0,
			["scaledDt"] = 0
		})
	end
end

-- Local values: k, data, i, greatDemand
function EconomyManager:removeSellingStation(sellingStation)
	for v54_, v55_ in ipairs(self.sellingStations) do
		if v55_.station == sellingStation then
			table.remove(self.sellingStations, v54_)
			if self.currentUpdatingSellingStation == sellingStation then
				self.currentUpdatingSellingStation = nil
			end
			for v56_ = #self.greatDemands, 1, -1 do
				if self.greatDemands[v56_].sellStation == sellingStation then
					table.remove(self.greatDemands, v56_)
				end
			end
			return
		end
	end
end

-- Local values: station, isDone
function EconomyManager:updateSellingStations(dt)
	if self.currentUpdatingSellingStation == nil then
		self.sellingStationUpdateIndex = self.sellingStationUpdateIndex + 1
		if self.sellingStationUpdateIndex > #self.sellingStations then
			self.sellingStationUpdateIndex = 1
		end
		self.currentUpdatingSellingStation = self.sellingStations[self.sellingStationUpdateIndex]
	end
	if self.currentUpdatingSellingStation ~= nil and self.currentUpdatingSellingStation.station:updateSellingStationPrices() then
		self.currentUpdatingSellingStation = nil
	end
end

function EconomyManager:update(dt)
	self:updateSellingStations(dt)
end

-- Local values: timeAdjustment, _, farm, farmId, money, perDayLeasingCosts, _, item, _, vehicle, vehicleUpkeep, facilityUpkeep, storeItem, item, _, realItem, _, realItem
function EconomyManager:dayChanged()
	if g_currentMission:getIsServer() then
		local v61_ = g_currentMission.environment.timeAdjustment
		for _, v62_ in ipairs(g_farmManager.farms) do
			local v63_ = v62_.farmId
			if v63_ ~= FarmManager.SPECTATOR_FARM_ID then
				local v64_ = -v62_:calculateDailyLoanInterest()
				g_currentMission:addMoney(v64_, v63_, MoneyType.LOAN_INTEREST, true)
				local v65_ = 0
				for _, v66_ in pairs(g_currentMission.leasedItems) do
					for _, v67_ in pairs(v66_.items) do
						if v67_:getOwnerFarmId() == v63_ then
							v65_ = v65_ + v67_:getPrice() * EconomyManager.PER_DAY_LEASING_FACTOR * v61_
						end
					end
				end
				if v65_ > 0 then
					g_currentMission:addMoney(-v65_, v63_, MoneyType.LEASING_COSTS, true)
				end
				local v68_ = 0
				local v69_ = 0
				for v70_, v71_ in pairs(g_currentMission.ownedItems) do
					if StoreItemUtil.getIsVehicle(v70_) then
						for _, v72_ in pairs(v71_.items) do
							if v72_:getOwnerFarmId() == v63_ then
								v68_ = v68_ + v72_:getDailyUpkeep() * v61_
							end
						end
					elseif StoreItemUtil.getIsPlaceable(v70_) then
						for _, v73_ in pairs(v71_.items) do
							if v73_:getOwnerFarmId() == v63_ then
								v69_ = v69_ + v73_:getDailyUpkeep() * v61_
							end
						end
					end
				end
				if v68_ > 0 then
					g_currentMission:addMoney(-v68_, v63_, MoneyType.VEHICLE_RUNNING_COSTS, true)
				end
				if v69_ > 0 then
					g_currentMission:addMoney(-v69_, v63_, MoneyType.PROPERTY_MAINTENANCE, true)
				end
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

-- Local values: storeItem, vehicleRunningLeasingCosts
function EconomyManager:vehicleOperatingHourChanged(vehicle)
	if g_currentMission:getIsServer() then
		local v76_ = g_storeManager:getItemByXMLFilename(vehicle.configFileName).runningLeasingFactor * vehicle:getPrice()
		if v76_ > 0 then
			g_currentMission:addMoney(-v76_, vehicle:getOwnerFarmId(), MoneyType.LEASING_COSTS, true)
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

-- Local values: _, greatDemand, station
function EconomyManager:updateGreatDemandsPDASpots()
	for _, v81_ in pairs(self.greatDemands) do
		if v81_.isValid and v81_.isRunning then
			local v82_ = v81_.sellStation
			if v82_ ~= nil and (v82_.mapHotspot ~= nil and not v82_.mapHotspot.isBlinking) then
				v82_.mapHotspot:setBlinking(true)
				v82_.mapHotspot:setPersistent(true)
			end
		end
	end
end

-- Local values: _, greatDemand, station
function EconomyManager:restartGreatDemands()
	self:finalizeGreatDemandLoading()
	for _, v84_ in pairs(self.greatDemands) do
		if v84_.isValid and v84_.isRunning then
			local v85_ = v84_.sellStation
			if v85_ ~= nil and v85_:getSupportsGreatDemand(v84_.fillTypeIndex) then
				v85_:setIsInGreatDemand(v84_.fillTypeIndex, true)
				self.greatDemandFillTypes[v84_.fillTypeIndex] = true
				if v85_.mapHotspot ~= nil then
					v85_.mapHotspot:setBlinking(true)
					v85_.mapHotspot:setPersistent(true)
				end
				v85_:setPriceMultiplier(v84_.fillTypeIndex, v84_.demandMultiplier)
			end
		end
	end
end

-- Local values: _, greatDemand, _, greatDemand
function EconomyManager:manageGreatDemands()
	for _, v87_ in pairs(self.greatDemands) do
		if v87_.isValid then
			if v87_.isRunning then
				v87_.demandDuration = v87_.demandDuration - 1
				if v87_.demandDuration <= 0 then
					self:stopGreatDemand(v87_)
				end
			elseif not v87_.isRunning and (v87_.demandStart.day == g_currentMission.environment.currentMonotonicDay and v87_.demandStart.hour <= g_currentMission.environment.currentHour) then
				self:startGreatDemand(v87_)
			end
		end
	end
	g_server:broadcastEvent(GreatDemandsEvent.new(self.greatDemands))
	for _, v88_ in pairs(self.greatDemands) do
		if not v88_.isValid or not v88_.isRunning and v88_.demandStart.day < g_currentMission.environment.currentMonotonicDay then
			v88_:setUpRandomDemand(true, self.greatDemands, g_currentMission)
		end
	end
end

-- Local values: sellStation
function EconomyManager:stopGreatDemand(greatDemand)
	greatDemand.isRunning = false
	greatDemand.isValid = false
	local v91_ = greatDemand.sellStation
	if v91_ ~= nil and v91_:getSupportsGreatDemand(greatDemand.fillTypeIndex) then
		v91_:setIsInGreatDemand(greatDemand.fillTypeIndex, false)
		self.greatDemandFillTypes[greatDemand.fillTypeIndex] = nil
		if v91_.mapHotspot ~= nil then
			v91_.mapHotspot:setBlinking(false)
			v91_.mapHotspot:setPersistent(false)
		end
		v91_:setPriceMultiplier(greatDemand.fillTypeIndex, 1)
	end
end

-- Local values: sellStation
function EconomyManager:startGreatDemand(greatDemand)
	greatDemand.isRunning = true
	local v94_ = greatDemand.sellStation
	if v94_ ~= nil then
		g_currentMission.hud:addSideNotification(FSBaseMission.INGAME_NOTIFICATION_GREATDEMAND, string.format(g_i18n:getText("notification_greatDemand"), v94_:getName()), 40000, GuiSoundPlayer.SOUND_SAMPLES.NOTIFICATION)
		if v94_:getSupportsGreatDemand(greatDemand.fillTypeIndex) then
			v94_:setIsInGreatDemand(greatDemand.fillTypeIndex, true)
			self.greatDemandFillTypes[greatDemand.fillTypeIndex] = true
			if v94_.mapHotspot ~= nil then
				v94_.mapHotspot:setBlinking(true)
				v94_.mapHotspot:setPersistent(true)
			end
			v94_:setPriceMultiplier(greatDemand.fillTypeIndex, greatDemand.demandMultiplier)
		end
	end
end

function EconomyManager:getGreatDemandById(id)
	return self.greatDemands[id]
end

function EconomyManager:getHasFillTypeGreatDemand(fillTypeIndex)
	return self.greatDemandFillTypes[fillTypeIndex] == true
end

-- Local values: fillType, difficultyMultiplier, period, alpha, seasonalFactor
function EconomyManager:getPricePerLiter(fillTypeIndex, useMultiplier)
	local v102_ = g_fillTypeManager:getFillTypeByIndex(fillTypeIndex)
	local v103_ = EconomyManager.getPriceMultiplier()
	local v104_ = useMultiplier ~= nil and not useMultiplier and 1 or v103_
	local v105_, v106_ = g_currentMission.environment:getPeriodAndAlphaIntoPeriod()
	local v107_ = self:getFillTypeSeasonalFactor(v102_, v105_, v106_)
	return v102_.pricePerLiter * v104_ * v107_
end

-- Local values: fillType, difficultyMultiplier, period, alpha, seasonalFactor
function EconomyManager:getCostPerLiter(fillTypeIndex, useMultiplier)
	local v111_ = g_fillTypeManager:getFillTypeByIndex(fillTypeIndex)
	local v112_ = EconomyManager.getCostMultiplier()
	local v113_ = useMultiplier ~= nil and not useMultiplier and 1 or v112_
	local v114_, v115_ = g_currentMission.environment:getPeriodAndAlphaIntoPeriod()
	local v116_ = self:getFillTypeSeasonalFactor(v111_, v114_, v115_)
	return v111_.pricePerLiter * v113_ * v116_
end

-- Local values: price, upgradePrice, name, id, configs, hasBought
function EconomyManager:getBuyPrice(storeItem, configurations, saleItem)
	local v120_ = storeItem.price
	if saleItem ~= nil then
		v120_ = saleItem.price
	end
	local v121_ = 0
	if configurations ~= nil then
		for v122_, v123_ in pairs(configurations) do
			local v124_ = storeItem.configurations[v122_]
			if v124_ ~= nil then
				local v125_
				if saleItem == nil or saleItem.boughtConfigurations[v122_] == nil then
					v125_ = false
				else
					v125_ = saleItem.boughtConfigurations[v122_][v123_]
				end
				if not v125_ then
					v121_ = v121_ + v124_[v123_].price
					v120_ = v120_ + v124_[v123_].price
				end
			end
		end
	end
	return v120_, v121_
end

function EconomyManager:getSellPrice(object)
	if object.getSellPrice ~= nil then
		return object:getSellPrice()
	end
	local v127_ = object.price * 0.5
	return math.floor(v127_)
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

-- Local values: p0, p1, p2, p3, factors
function EconomyManager:getFillTypeSeasonalFactor(fillType, period, alpha)
	local v132_ = period - 1
	local v133_ = (v132_ - 1) % 12 + 1
	local v134_ = (v132_ + 0) % 12 + 1
	local v135_ = (v132_ + 1) % 12 + 1
	local v136_ = (v132_ + 2) % 12 + 1
	local v137_ = fillType.economy.factors
	return MathUtil.catmullRom(v137_[v133_], v137_[v134_], v137_[v135_], v137_[v136_], alpha)
end

function EconomyManager:getFillTypeHistoricPrice(fillType, period)
	return fillType.economy.history[period] * EconomyManager.getPriceMultiplier()
end

-- Local values: period, fillTypeIndex, fillType, num, total, _, sellingStation, price, historicPrice, price, hoursPassed
function EconomyManager:updateFillTypeHistory()
	local v141_ = g_currentMission.environment.currentPeriod
	for v142_, v143_ in ipairs(g_fillTypeManager:getFillTypes()) do
		local v144_ = 0
		local v145_ = 0
		for _, v146_ in ipairs(self.sellingStations) do
			if v146_.station.acceptedFillTypes[v142_] then
				local v147_ = v146_.station:getEffectiveFillTypePrice(v142_, ToolType.UNDEFINED) / EconomyManager.getPriceMultiplier()
				v144_ = v144_ + 1
				v145_ = v145_ + v147_
			end
		end
		if v144_ > 0 then
			local v148_ = v143_.economy.history[v141_]
			local v149_ = v145_ / v144_
			local v150_ = g_currentMission.environment.currentHour
			local v151_ = (v150_ * v148_ + v149_) / (v150_ + 1)
			v143_.economy.history[v141_] = v151_
		end
	end
end

function EconomyManager:sendPeriodFillTypeHistory(period)
	g_server:broadcastEvent(PricingHistoryEvent.new(period))
end
