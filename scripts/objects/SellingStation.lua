-- Local values: SellingStation_mt
SellingStation = {}
SellingStation.PRICE_FALLING = 1
SellingStation.PRICE_CLIMBING = 2
SellingStation.PRICE_GREAT_DEMAND = 5
SellingStation.RANDOM_DELTA_IMPACT = 0.3
SellingStation.PRICE_DROP_DELAY = 3600000
SellingStation.NUM_PRICE_UPDATES_PER_FRAME = 5
local SellingStation_mt = Class(SellingStation, UnloadingStation)
InitStaticObjectClass(SellingStation, "SellingStation")

-- Upvalues: SellingStation_mt
-- Local values: self
function SellingStation.new(isServer, isClient, customMt)
	-- upvalues: (copy) SellingStation_mt
	local v5_ = UnloadingStation.new(isServer, isClient, customMt or SellingStation_mt)
	v5_.lastMoneyChange = -1
	v5_.incomeName = "harvestIncome"
	v5_.incomeNameWool = "soldWool"
	v5_.incomeNameMilk = "soldMilk"
	v5_.incomeNameBale = "soldBales"
	v5_.incomeNameProduct = "soldProducts"
	v5_.isSellingPoint = true
	v5_.allowMissions = true
	return v5_
end

-- Local values: fillTypeCategories, fillTypeNames, _, fillType, _, fillType, litersForFullPriceDrop, fullPriceRecoverHours, _, fillTypeKey, fillTypeStr, fillTypeIndex, priceScale, fillType, price, supportsGreatDemand, disablePriceDrop, fillTypeIndex, _, fillType, price
function SellingStation:load(components, xmlFile, key, customEnv, i3dMappings, rootNode)
	if not SellingStation:superClass().load(self, components, xmlFile, key, customEnv, i3dMappings, rootNode) then
		return false
	end
	if #self.unloadTriggers == 0 then
		local v13_ = xmlFile:getValue(key .. "#fillTypeCategories")
		local v14_ = xmlFile:getValue(key .. "#fillTypes")
		if v13_ ~= nil then
			for _, v15_ in pairs(g_fillTypeManager:getFillTypesByCategoryNames(v13_, "Warning: SellingStation has invalid fillTypeCategory \'%s\'.")) do
				self.supportedFillTypes[v15_] = true
			end
		end
		if v14_ ~= nil then
			for _, v16_ in pairs(g_fillTypeManager:getFillTypesByNames(v14_, "Warning: SellingStation has invalid fillType \'%s\'.")) do
				self.supportedFillTypes[v16_] = true
			end
		end
	end
	self.fixedIncomeName = xmlFile:getValue(key .. "#incomeName", nil)
	self.appearsOnStats = xmlFile:getValue(key .. "#appearsOnStats", false)
	self.suppressWarnings = xmlFile:getValue(key .. "#suppressWarnings", false)
	self.allowMissions = xmlFile:getValue(key .. "#allowMissions", true)
	self.hasDynamic = xmlFile:getValue(key .. "#hasDynamic", true)
	local v17_ = xmlFile:getValue(key .. "#litersForFullPriceDrop")
	if v17_ ~= nil then
		self.priceDropPerLiter = (1 - EconomyManager.PRICE_DROP_MIN_PERCENT) / v17_
	end
	local v18_ = xmlFile:getValue(key .. "#fullPriceRecoverHours")
	if v18_ == nil then
		self.priceRecoverPerSecond = 1
	else
		self.priceRecoverPerSecond = (1 - EconomyManager.PRICE_DROP_MIN_PERCENT) / (v18_ * 60 * 60)
	end
	self.acceptedFillTypes = {}
	self.numFillTypesForSelling = 0
	self.fillTypeSupportsGreatDemand = {}
	self.priceDropDisabled = {}
	self.originalFillTypePricesUnscaled = {}
	self.originalFillTypePrices = {}
	self.fillTypePrices = {}
	self.fillTypePriceInfo = {}
	self.fillTypePriceRandomDelta = {}
	self.priceMultipliers = {}
	self.totalReceived = {}
	self.totalPaid = {}
	self.pendingPriceDrop = {}
	self.prevFillLevel = {}
	self.prevTotalReceived = {}
	self.prevTotalPaid = {}
	self.lastUpdateTime = {}
	self.missions = {}
	for _, v19_ in xmlFile:iterator(key .. ".fillType") do
		local v20_ = xmlFile:getValue(v19_ .. "#name")
		local v21_ = g_fillTypeManager:getFillTypeIndexByName(v20_)
		if v21_ == nil then
			Logging.xmlWarning(xmlFile, "Invalid fillType \'%s\' in \'%s\'", v20_, v19_)
		elseif self.supportedFillTypes[v21_] == nil then
			Logging.xmlWarning(xmlFile, "FillType \'%s\' is not supported by unload triggers for selling station", v20_)
		else
			local v22_ = xmlFile:getValue(v19_ .. "#priceScale", 1)
			self:addAcceptedFillType(v21_, g_fillTypeManager:getFillTypeByIndex(v21_).pricePerLiter * v22_, xmlFile:getValue(v19_ .. "#supportsGreatDemand", true), (xmlFile:getValue(v19_ .. "#disablePriceDrop", false)))
		end
	end
	for v23_, _ in pairs(self.supportedFillTypes) do
		if self.acceptedFillTypes[v23_] == nil then
			self:addAcceptedFillType(v23_, g_fillTypeManager:getFillTypeByIndex(v23_).pricePerLiter, false, false)
		end
	end
	if self.isServer then
		self.moneyChangeType = MoneyType.register("soldMaterials", "finance_other")
	end
	self.priceDropTimer = 0
	self.pricingDynamics = {}
	self:initPricingDynamics()
	self.priceSyncTimerDuration = 30000
	self.priceSyncTimer = self.priceSyncTimerDuration
	self.unloadingStationDirtyFlag = self:getNextDirtyFlag()
	g_currentMission.economyManager:addSellingStation(self)
	return true
end

-- Local values: mission, _
function SellingStation:delete()
	if self.missions ~= nil then
		for v25_, _ in pairs(self.missions) do
			if v25_.onDeleteSellingStation ~= nil then
				v25_:onDeleteSellingStation(self)
			end
		end
	end
	SellingStation:superClass().delete(self)
end

-- Local values: price, acceptedFillType, _
function SellingStation:addAcceptedFillType(fillType, priceUnscaled, supportsGreatDemand, disablePriceDrop)
	if fillType == nil or self.acceptedFillTypes[fillType] ~= nil then
		return
	elseif priceUnscaled <= 0 then
		Logging.error("Cannot add fillType %q to selling station %q as it has no price defined", g_fillTypeManager:getFillTypeNameByIndex(fillType), self:getName() or self.rootNodeName)
	else
		self.acceptedFillTypes[fillType] = true
		self.fillTypeSupportsGreatDemand[fillType] = supportsGreatDemand
		if supportsGreatDemand then
			self.supportsGreatDemand = true
		end
		self.priceDropDisabled[fillType] = disablePriceDrop
		self.originalFillTypePricesUnscaled[fillType] = priceUnscaled
		self.originalFillTypePrices[fillType] = priceUnscaled
		self.fillTypePrices[fillType] = priceUnscaled
		self.fillTypePriceInfo[fillType] = 0
		self.fillTypePriceRandomDelta[fillType] = 0
		self.priceMultipliers[fillType] = 1
		self.totalReceived[fillType] = 0
		self.totalPaid[fillType] = 0
		self.pendingPriceDrop[fillType] = 0
		self.prevFillLevel[fillType] = 0
		self.prevTotalReceived[fillType] = 0
		self.prevTotalPaid[fillType] = 0
		self.lastUpdateTime[fillType] = 0
		self.numFillTypesForSelling = 0
		for v31_, _ in pairs(self.acceptedFillTypes) do
			if self.originalFillTypePrices[v31_] > 0 then
				self.numFillTypesForSelling = self.numFillTypesForSelling + 1
			end
		end
	end
end

-- Local values: moneyTypeId, numFillTypes, i, fillType
function SellingStation:readStream(streamId, connection)
	local v35_ = streamReadUInt16(streamId)
	self.moneyChangeType = MoneyType.registerWithId(v35_, "soldMaterials", "finance_other")
	SellingStation:superClass().readStream(self, streamId, connection)
	if connection:getIsServer() then
		for _ = 1, streamReadUInt8(streamId) do
			local v36_ = streamReadUIntN(streamId, FillTypeManager.SEND_NUM_BITS)
			self.fillTypePrices[v36_] = streamReadUInt16(streamId) / 1000
			self.fillTypePriceInfo[v36_] = streamReadUIntN(streamId, 6)
		end
	end
end

-- Local values: fillType, _, price
function SellingStation:writeStream(streamId, connection)
	streamWriteUInt16(streamId, self.moneyChangeType.id)
	SellingStation:superClass().writeStream(self, streamId, connection)
	if not connection:getIsServer() then
		streamWriteUInt8(streamId, self.numFillTypesForSelling)
		if self.numFillTypesForSelling > 0 then
			for v40_, _ in pairs(self.acceptedFillTypes) do
				if self.originalFillTypePrices[v40_] > 0 then
					streamWriteUIntN(streamId, v40_, FillTypeManager.SEND_NUM_BITS)
					local v41_ = self:getEffectiveFillTypePrice(v40_) * 1000 + 0.5
					local v42_ = math.floor(v41_)
					streamWriteUInt16(streamId, (math.min(v42_, 65535)))
					streamWriteUIntN(streamId, self:getCurrentPricingTrend(v40_), 6)
				end
			end
		end
	end
end

-- Local values: numFillTypes, i, fillType
function SellingStation:readUpdateStream(streamId, timestamp, connection)
	SellingStation:superClass().readUpdateStream(self, streamId, timestamp, connection)
	if connection:getIsServer() and streamReadBool(streamId) then
		for _ = 1, streamReadUInt8(streamId) do
			local v47_ = streamReadUIntN(streamId, FillTypeManager.SEND_NUM_BITS)
			self.fillTypePrices[v47_] = streamReadUInt16(streamId) / 1000
			self.fillTypePriceInfo[v47_] = streamReadUIntN(streamId, 6)
		end
	end
end

-- Local values: fillType, _, price
function SellingStation:writeUpdateStream(streamId, connection, dirtyMask)
	SellingStation:superClass().writeUpdateStream(self, streamId, connection, dirtyMask)
	if not connection:getIsServer() then
		local v52_ = streamWriteBool
		local v53_ = self.unloadingStationDirtyFlag
		if v52_(streamId, bit32.band(dirtyMask, v53_) ~= 0) then
			streamWriteUInt8(streamId, self.numFillTypesForSelling)
			if self.numFillTypesForSelling > 0 then
				for v54_, _ in pairs(self.acceptedFillTypes) do
					if self.originalFillTypePrices[v54_] > 0 then
						streamWriteUIntN(streamId, v54_, FillTypeManager.SEND_NUM_BITS)
						local v55_ = self:getEffectiveFillTypePrice(v54_) * 1000 + 0.5
						local v56_ = math.floor(v55_)
						streamWriteUInt16(streamId, (math.min(v56_, 65535)))
						streamWriteUIntN(streamId, self:getCurrentPricingTrend(v54_), 6)
					end
				end
			end
		end
	end
end

function SellingStation:update(dt)
	if self.lastMoneyChange > 0 then
		self.lastMoneyChange = self.lastMoneyChange - 1
		if self.lastMoneyChange == 0 then
			g_currentMission:showMoneyChange(self.moneyChangeType, "finance_" .. self.lastIncomeName, false, self.lastMoneyChangeFarmId)
		end
		self:raiseActive()
	end
end

function SellingStation:updateSellingStation(dt, scaledDt) end

function SellingStation:updatePrices(dt) end

-- Local values: currentTime, fillType, i, deltaTime, isGreatDemandFillType
function SellingStation:updateSellingStationPrices()
	if not self.hasDynamic then
		return true
	end
	if not self.isServer then
		return true
	end
	local v59_ = g_currentMission.time
	if self.priceSyncTimer < v59_ then
		self:raiseDirtyFlags(self.unloadingStationDirtyFlag)
		self.priceSyncTimer = v59_ + self.priceSyncTimerDuration
	end
	local v60_ = self.currentUpdateFillType
	local v61_ = 0
	while SellingStation.NUM_PRICE_UPDATES_PER_FRAME > v61_ do
		v60_ = next(self.acceptedFillTypes, v60_)
		self.currentUpdateFillType = v60_
		if self.currentUpdateFillType == nil then
			return true
		end
		local v62_ = v59_ - self.lastUpdateTime[v60_]
		local v63_ = self.isGreatDemandActive
		if v63_ then
			v63_ = self.greatDemandFillType == v60_
		end
		if v62_ > 0 and not v63_ then
			self:updateFillTypePrice(v60_, v62_)
		end
		self.lastUpdateTime[v60_] = v59_
		v61_ = v61_ + 1
		if next(self.acceptedFillTypes, v60_) == nil then
			self.currentUpdateFillType = nil
			return true
		end
	end
	return false
end

-- Local values: trend, priceRecoverBase, priceRecover
function SellingStation:updateFillTypePrice(fillType, dt)
	self.pricingDynamics[fillType]:update(dt)
	self.fillTypePriceRandomDelta[fillType] = self.pricingDynamics[fillType]:evaluate()
	self.fillTypePriceInfo[fillType] = Utils.clearBit(self.fillTypePriceInfo[fillType], SellingStation.PRICE_CLIMBING)
	self.fillTypePriceInfo[fillType] = Utils.clearBit(self.fillTypePriceInfo[fillType], SellingStation.PRICE_FALLING)
	local v67_ = self:getTrend(fillType)
	if v67_ == PricingDynamics.TREND_FALLING then
		self.fillTypePriceInfo[fillType] = Utils.setBit(self.fillTypePriceInfo[fillType], SellingStation.PRICE_FALLING)
	elseif v67_ == PricingDynamics.TREND_CLIMBING then
		self.fillTypePriceInfo[fillType] = Utils.setBit(self.fillTypePriceInfo[fillType], SellingStation.PRICE_CLIMBING)
	end
	local v68_ = self.priceRecoverPerSecond * dt * 0.001 * self.originalFillTypePrices[fillType]
	local v69_ = self.fillTypePrices
	local v70_ = self.fillTypePrices[fillType] + v68_
	local v71_ = self.originalFillTypePrices[fillType]
	v69_[fillType] = math.min(v70_, v71_)
end

-- Local values: i, statsKey, fillTypeStr, fillType
function SellingStation:loadFromXMLFile(xmlFile, key)
	local v75_ = 0
	while true do
		local v76_ = string.format(key .. ".stats(%d)", v75_)
		if not xmlFile:hasProperty(v76_) then
			break
		end
		local v77_ = xmlFile:getValue(v76_ .. "#fillType")
		local v78_ = g_fillTypeManager:getFillTypeIndexByName(v77_)
		if v78_ ~= nil and self.acceptedFillTypes[v78_] then
			self.totalReceived[v78_] = xmlFile:getValue(v76_ .. "#received", 0)
			self.totalPaid[v78_] = xmlFile:getValue(v76_ .. "#paid", 0)
			self.pricingDynamics[v78_]:loadFromXMLFile(xmlFile, v76_)
		end
		v75_ = v75_ + 1
	end
	return true
end

-- Local values: index, fillTypeIndex, _, fillTypeName, statsKey
function SellingStation:saveToXMLFile(xmlFile, key, usedModNames)
	local v83_ = 0
	for v84_, _ in pairs(self.acceptedFillTypes) do
		if self.originalFillTypePrices[v84_] > 0 then
			local v85_ = g_fillTypeManager:getFillTypeNameByIndex(v84_)
			local v86_ = string.format("%s.stats(%d)", key, v83_)
			xmlFile:setValue(v86_ .. "#fillType", v85_)
			xmlFile:setValue(v86_ .. "#received", self.totalReceived[v84_])
			xmlFile:setValue(v86_ .. "#paid", self.totalPaid[v84_])
			self.pricingDynamics[v84_]:saveToXMLFile(xmlFile, v86_, usedModNames)
			v83_ = v83_ + 1
		end
	end
end

function SellingStation:getName()
	return self.stationName or self.owningPlaceable and self.owningPlaceable:getName() or "Selling Station"
end

function SellingStation:getIsFillTypeAllowed(fillTypeIndex, extraAttributes)
	return self.acceptedFillTypes[fillTypeIndex] and true or false
end

-- Local values: movedFillLevel, storeGoods, storageAccess, usedMission, highestProgress, usedByMission, _, mission, progress, skipSell
function SellingStation:addFillLevelFromTool(farmId, deltaFillLevel, fillTypeIndex, fillInfo, toolType, extraAttributes)
	local v97_ = 0
	if deltaFillLevel > 0 then
		local v98_ = self:getStoreGoods(farmId, fillTypeIndex)
		local v99_ = not v98_ or self:getIsFillAllowedFromFarm(farmId)
		if self:getIsFillTypeAllowed(fillTypeIndex, extraAttributes) and v99_ then
			local v100_ = 0
			local v101_ = nil
			local v102_ = false
			for _, v103_ in pairs(self.missions) do
				if v103_.fillSold ~= nil and (v103_.fillTypeIndex == fillTypeIndex and v103_.farmId == farmId) then
					local v104_ = v103_:getCompletion()
					if v100_ < v104_ then
						v101_ = v103_
						v100_ = v104_
					end
				end
			end
			if v101_ ~= nil then
				v101_:fillSold(deltaFillLevel)
				v102_ = true
			end
			if v98_ and not v102_ then
				deltaFillLevel = SellingStation:superClass().addFillLevelFromTool(self, farmId, deltaFillLevel, fillTypeIndex, fillInfo, toolType, extraAttributes)
			else
				self:startFx(fillTypeIndex)
			end
			if not v102_ and (not self:getSkipSell(farmId, fillTypeIndex) and deltaFillLevel > 0.001) then
				self:sellFillType(farmId, deltaFillLevel, fillTypeIndex, toolType, extraAttributes)
			end
		else
			deltaFillLevel = v97_
		end
		self:activateSimpleFillplanes(fillTypeIndex)
	else
		deltaFillLevel = v97_
	end
	return deltaFillLevel
end

function SellingStation:getStoreGoods(farmId, fillTypeIndex)
	return false
end

function SellingStation:getSkipSell(farmId, fillTypeIndex)
	return false
end

-- Local values: fillType, pricePerLiter, priceScale, price
function SellingStation:sellFillType(farmId, fillDelta, fillTypeIndex, toolType, extraAttributes)
	if not self.priceDropDisabled[fillTypeIndex] then
		self:doPriceDrop(fillDelta, fillTypeIndex)
	end
	local v111_ = g_fillTypeManager:getFillTypeByIndex(fillTypeIndex)
	v111_.totalAmount = v111_.totalAmount + fillDelta
	self.totalReceived[fillTypeIndex] = self.totalReceived[fillTypeIndex] + fillDelta
	local v112_ = self:getEffectiveFillTypePrice(fillTypeIndex, toolType)
	local v113_ = 1
	if extraAttributes ~= nil then
		v112_ = extraAttributes.price or v112_
		v113_ = extraAttributes.priceScale or v113_
	end
	local v114_ = fillDelta * v112_ * v113_
	self.totalPaid[fillTypeIndex] = self.totalPaid[fillTypeIndex] + v114_
	self.lastIncomeName = self:getIncomeNameForFillType(fillTypeIndex, toolType)
	self.moneyChangeType.statistic = self.lastIncomeName
	g_currentMission:addMoney(v114_, farmId, self.moneyChangeType, true)
	self.lastMoneyChange = 30
	self.lastMoneyChangeFarmId = farmId
	self:raiseActive()
	return v114_
end

-- Local values: period, alpha, fillTypeDesc, seasonalFactor
function SellingStation:getEffectiveFillTypePrice(fillType, toolType)
	if self.fillTypePrices[fillType] == nil then
		log("Missing filltype", g_fillTypeManager:getFillTypeNameByIndex(fillType), (tostring(self:getName())))
		printCallstack()
	end
	if not self.isServer then
		return self.fillTypePrices[fillType]
	end
	local v117_, v118_ = g_currentMission.environment:getPeriodAndAlphaIntoPeriod()
	local v119_ = g_fillTypeManager:getFillTypeByIndex(fillType)
	local v120_ = g_currentMission.economyManager:getFillTypeSeasonalFactor(v119_, v117_, v118_)
	return v120_ == 0 and 0 or (self.fillTypePrices[fillType] * v120_ + self.fillTypePriceRandomDelta[fillType] * SellingStation.RANDOM_DELTA_IMPACT) * self.priceMultipliers[fillType] * EconomyManager.getPriceMultiplier()
end

function SellingStation:getIncomeNameForFillType(fillType, toolType)
	if self.fixedIncomeName == nil then
		if toolType == ToolType.BALE then
			return self.incomeNameBale
		elseif fillType == FillType.WOOL then
			return self.incomeNameWool
		elseif fillType == FillType.MILK then
			return self.incomeNameMilk
		elseif fillType == FillType.WOOD then
			return "soldWood"
		elseif g_fillTypeManager:getIsFillTypeInCategory(fillType, "PRODUCT") then
			return self.incomeNameProduct
		else
			return self.incomeName
		end
	else
		return self.fixedIncomeName
	end
end

-- Local values: timeScaling, amp, ampVar, ampDist, per, perVar, perDist, plateauFactor, initialPlateauFraction, amp2, ampVar2, ampDist2, per2, perVar2, perDist2, fillType, _
function SellingStation:initPricingDynamics()
	local v125_ = PricingDynamics.AMP_DIST_LINEAR_DOWN
	local v126_ = 172800000
	local v127_ = 0.375 * v126_
	local v128_ = PricingDynamics.AMP_DIST_CONSTANT
	local v129_ = PricingDynamics.AMP_DIST_CONSTANT
	local v130_ = 604800000
	local v131_ = 0.2 * v130_
	local v132_ = PricingDynamics.AMP_DIST_CONSTANT
	self.levelThreshold = 0.032
	local v133_ = v126_ / 1
	local v134_ = v127_ / 1
	local v135_ = v130_ / 1
	local v136_ = v131_ / 1
	local v137_ = 0.02
	local v138_ = 0.02
	local v139_ = 0.04
	local v140_ = 0.15
	for v141_, _ in pairs(self.acceptedFillTypes) do
		self.pricingDynamics[v141_] = PricingDynamics.new(0, v139_ * self.originalFillTypePrices[v141_], v140_ * self.originalFillTypePrices[v141_], v125_, v133_, v134_, v128_, 0.3, 0.75)
		self.pricingDynamics[v141_]:addCurve(v137_ * self.originalFillTypePrices[v141_], v138_ * self.originalFillTypePrices[v141_], v129_, v135_, v136_, v132_)
	end
end

function SellingStation:executePriceDrop(priceDrop, fillType) end

function SellingStation:doPriceDrop(fillLevel, fillType) end

-- Local values: fillTypeDesc, N, randomDelta1, randomDelta2, period, alpha, alpha2, period2, seasonalFactor1, seasonalFactor2, price1, price2, delta
function SellingStation:getTrend(fillType)
	local v144_ = g_fillTypeManager:getFillTypeByIndex(fillType)
	local v145_ = self.fillTypePriceRandomDelta[fillType] / self.fillTypePrices[fillType]
	local v146_ = self.pricingDynamics[fillType]:evaluateForTrend(14400000) / self.fillTypePrices[fillType]
	local v147_, v148_ = g_currentMission.environment:getPeriodAndAlphaIntoPeriod()
	local v149_ = v148_ + 0.16666666666666666 / g_currentMission.environment.daysPerPeriod
	local v150_
	if v149_ > 1 then
		v149_ = v149_ - 1
		v150_ = v147_ + 1
	else
		v150_ = v147_
	end
	local v151_ = g_currentMission.economyManager:getFillTypeSeasonalFactor(v144_, v147_, v148_)
	local v152_ = g_currentMission.economyManager:getFillTypeSeasonalFactor(v144_, v150_, v149_)
	local v153_ = v151_ + v145_ * SellingStation.RANDOM_DELTA_IMPACT
	local v154_ = v152_ + v146_ * SellingStation.RANDOM_DELTA_IMPACT - v153_
	if math.abs(v154_) < 0.002 then
		return PricingDynamics.TREND_PLATEAU
	elseif v154_ > 0 then
		return PricingDynamics.TREND_CLIMBING
	else
		return PricingDynamics.TREND_FALLING
	end
end

function SellingStation:setPriceMultiplier(fillType, priceMultiplier)
	self.priceMultipliers[fillType] = priceMultiplier
end

function SellingStation:getSupportsGreatDemand(fillType)
	if fillType == nil or self.fillTypeSupportsGreatDemand[fillType] == nil then
		return false
	else
		return self.fillTypeSupportsGreatDemand[fillType]
	end
end

function SellingStation:setIsInGreatDemand(fillType, isInGreatDemand)
	if isInGreatDemand then
		self.fillTypePriceInfo[fillType] = Utils.setBit(self.fillTypePriceInfo[fillType], SellingStation.PRICE_GREAT_DEMAND)
		self.isGreatDemandActive = true
		self.greatDemandFillType = fillType
	else
		if self.greatDemandFillType ~= nil and self.fillTypePriceInfo[self.greatDemandFillType] ~= nil then
			self.fillTypePriceInfo[self.greatDemandFillType] = Utils.clearBit(self.fillTypePriceInfo[self.greatDemandFillType], SellingStation.PRICE_GREAT_DEMAND)
		end
		self.isGreatDemandActive = false
		self.greatDemandFillType = FillType.UNKNOWN
	end
	self:raiseDirtyFlags(self.unloadingStationDirtyFlag)
	self.priceSyncTimer = self.priceSyncTimerDuration
end

function SellingStation:getPriceMultiplier(fillType)
	return self.priceMultipliers[fillType]
end

function SellingStation:getTotalReceived(fillType)
	return self.totalReceived[fillType]
end

function SellingStation:getTotalPaid(fillType)
	return self.totalPaid[fillType]
end

function SellingStation:getCurrentPricingTrend(fillType)
	return self.fillTypePriceInfo[fillType]
end

function SellingStation:getFreeCapacity(fillTypeIndex, farmId)
	return not self:getStoreGoods(farmId, fillTypeIndex) and math.huge or SellingStation:superClass().getFreeCapacity(self, fillTypeIndex, farmId)
end

function SellingStation:getIsFillAllowedFromFarm(farmId)
	return not self:getStoreGoods(farmId, nil) and true or SellingStation:superClass().getIsFillAllowedFromFarm(self, farmId)
end

function SellingStation:getAppearsOnStats()
	return self.appearsOnStats
end

function SellingStation.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.BOOL, basePath .. "#appearsOnStats", "Appears on Stats", false)
	schema:register(XMLValueType.BOOL, basePath .. "#suppressWarnings", "Suppress warnings", false)
	schema:register(XMLValueType.BOOL, basePath .. "#allowMissions", "Allow missions", true)
	schema:register(XMLValueType.BOOL, basePath .. "#hasDynamic", "Has dynamic prices", true)
	schema:register(XMLValueType.INT, basePath .. "#litersForFullPriceDrop", "Liters for full price drop")
	schema:register(XMLValueType.FLOAT, basePath .. "#fullPriceRecoverHours", "Full price recover ingame hours")
	schema:register(XMLValueType.STRING, basePath .. "#fillTypeCategories", "Supported filltypes if no unloafillLevelriggers defined")
	schema:register(XMLValueType.STRING, basePath .. "#fillTypes", "Supported filltypes if no unloafillLevelriggers defined")
	schema:register(XMLValueType.STRING, basePath .. "#incomeName", "Income name for stats")
	schema:register(XMLValueType.STRING, basePath .. ".fillType(?)#name", "Fill type name")
	schema:register(XMLValueType.FLOAT, basePath .. ".fillType(?)#priceScale", "Price scale", 1)
	schema:register(XMLValueType.BOOL, basePath .. ".fillType(?)#supportsGreatDemand", "Supports great demand", true)
	schema:register(XMLValueType.BOOL, basePath .. ".fillType(?)#disablePriceDrop", "Disable price drop", false)
	UnloadingStation.registerXMLPaths(schema, basePath)
end

function SellingStation.registerSavegameXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. ".stats(?)#fillType", "Fill type")
	schema:register(XMLValueType.FLOAT, basePath .. ".stats(?)#received", "Recieved fill level", 0)
	schema:register(XMLValueType.FLOAT, basePath .. ".stats(?)#paid", "Payed fill level", 0)
	PricingDynamics.registerSavegameXMLPaths(schema, basePath .. ".stats(?)")
end

-- Local values: fillTypeNames, fillTypesNamesString, _, fillTypeName, unloadTriggerFillTypeNames, fillTypeName
function SellingStation.loadSpecValueFillTypes(xmlFile, customEnvironment, baseDir)
	local v184_ = xmlFile:getValue("placeable.sellingStation#fillTypes")
	local v185_
	if string.isNilOrWhitespace(v184_) then
		v185_ = nil
	else
		v185_ = {}
		for _, v186_ in pairs(string.split(v184_, " ")) do
			v185_[v186_] = true
		end
	end
	if xmlFile:hasProperty("placeable.sellingStation") then
		local v187_ = UnloadTrigger.loadSpecValueFillTypes(xmlFile, "placeable.sellingStation", customEnvironment, baseDir)
		if v187_ ~= nil then
			v185_ = v185_ or {}
			for v188_ in pairs(v187_) do
				v185_[v188_] = true
			end
		end
	end
	if PlaceableConstructible ~= nil and xmlFile:hasProperty("placeable.constructible") then
		v185_ = PlaceableConstructible.loadSpecValueFillTypes(xmlFile, customEnvironment, baseDir, v185_)
	end
	return v185_
end

function SellingStation.getSpecValueFillTypes(storeItem, realItem)
	if storeItem.specs.sellingStationFillTypes == nil then
		return nil
	else
		return g_fillTypeManager:getFillTypesByNames(table.concatKeys(storeItem.specs.sellingStationFillTypes, " "))
	end
end
