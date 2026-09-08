-- Local values: BuyingStation_mt
BuyingStation = {}
local BuyingStation_mt = Class(BuyingStation, LoadingStation)
InitStaticObjectClass(BuyingStation, "BuyingStation")

-- Upvalues: BuyingStation_mt
-- Local values: self
function BuyingStation.new(isServer, isClient, customMt)
	-- upvalues: (copy) BuyingStation_mt
	local v5_ = LoadingStation.new(isServer, isClient, customMt or BuyingStation_mt)
	v5_.incomeName = "other"
	v5_.incomeNameFuel = "purchaseFuel"
	v5_.incomeNameLime = "other"
	return v5_
end

-- Local values: i, fillTypeKey, fillTypeStr, fillTypeIndex, fillTypeStatsName, priceScale, fillTypeIndex
function BuyingStation:load(components, xmlFile, key, customEnv, i3dMappings)
	if not BuyingStation:superClass().load(self, components, xmlFile, key, customEnv, i3dMappings) then
		return false
	end
	self.lastMoneyChange = 0
	self.providedFillTypes = {}
	self.fillTypePricesScale = {}
	self.fillTypeStatsName = {}
	local v12_ = 0
	while true do
		local v13_ = string.format(key .. ".fillType(%d)", v12_)
		if not xmlFile:hasProperty(v13_) then
			break
		end
		local v14_ = xmlFile:getValue(v13_ .. "#name")
		local v15_ = g_fillTypeManager:getFillTypeIndexByName(v14_)
		local v16_ = xmlFile:getValue(v13_ .. "#statsName", "other")
		if FinanceStats.statNameToIndex[v16_] == nil then
			Logging.xmlWarning(xmlFile, "StatsName \'%s\' for fillType \'%s\' is not defined for buying station", v16_, v14_)
			v16_ = "other"
		end
		if v15_ ~= nil then
			if self.supportedFillTypes[v15_] == nil then
				Logging.xmlWarning(xmlFile, "FillType \'%s\' is not supported by loading triggers for buying station", v14_)
			else
				local v17_ = xmlFile:getValue(v13_ .. "#priceScale", 1)
				self.fillTypePricesScale[v15_] = v17_
				self.fillTypeStatsName[v15_] = v16_
				self.providedFillTypes[v15_] = true
			end
		end
		v12_ = v12_ + 1
	end
	for v18_ in pairs(self.supportedFillTypes) do
		if self.fillTypePricesScale[v18_] == nil then
			self.fillTypePricesScale[v18_] = 1
			self.fillTypeStatsName[v18_] = "other"
			self.providedFillTypes[v18_] = true
		end
	end
	if self.isServer then
		self.moneyChangeType = MoneyType.register("other", "finance_other")
	end
	return true
end

-- Local values: moneyTypeId
function BuyingStation:readStream(streamId, connection)
	local v22_ = streamReadUInt16(streamId)
	self.moneyChangeType = MoneyType.registerWithId(v22_, "other", "finance_other")
	BuyingStation:superClass().readStream(self, streamId, connection)
end

function BuyingStation:writeStream(streamId, connection)
	streamWriteUInt16(streamId, self.moneyChangeType.id)
	BuyingStation:superClass().writeStream(self, streamId, connection)
end

function BuyingStation:update(dt)
	if self.lastMoneyChange > 0 then
		self.lastMoneyChange = self.lastMoneyChange - 1
		if self.lastMoneyChange == 0 then
			g_currentMission:showMoneyChange(self.moneyChangeType, "finance_" .. self.lastIncomeName, false, self.lastMoneyChangeFarmId)
		end
		self:raiseActive()
	end
end

function BuyingStation:addSourceStorage(storage)
	printError("Error: LoadingStation \'" .. tostring(self:getName()) .. "\' is a buying point and does not accept any storages!")
	return false
end

-- Local values: fillLevels, capacity, fillType, _
function BuyingStation:getAllFillLevels()
	local v29_ = {}
	local v30_ = 1
	for v31_, _ in pairs(self.supportedFillTypes) do
		v29_[v31_] = 1
	end
	return v29_, v30_
end

-- Local values: fillType, multiplier, pricePerLiter
function BuyingStation:getEffectiveFillTypePrice(fillTypeIndex)
	local v34_ = g_fillTypeManager:getFillTypeByIndex(fillTypeIndex)
	local v35_ = EconomyManager.getPriceMultiplier(fillTypeIndex)
	local v36_ = (fillTypeIndex == FillType.DIESEL or fillTypeIndex == FillType.DEF) and 1 or v35_
	return self.fillTypePricesScale[fillTypeIndex] * v34_.pricePerLiter * v36_
end

-- Local values: farmId, price
function BuyingStation:addFillLevelToFillableObject(fillableObject, fillUnitIndex, fillTypeIndex, fillDelta, fillInfo, toolType)
	if fillableObject == nil or (fillTypeIndex == FillType.UNKNOWN or (fillDelta == 0 or toolType == nil)) then
		return 0
	end
	local v44_ = fillableObject:getOwnerFarmId()
	local v45_
	if g_currentMission:getMoney(v44_) > 0 then
		v45_ = fillableObject:addFillUnitFillLevel(v44_, fillUnitIndex, fillDelta, fillTypeIndex, toolType, fillInfo)
		if v45_ > 0 then
			local v46_ = self:getEffectiveFillTypePrice(fillTypeIndex) * v45_
			self.lastIncomeName = self:getIncomeNameForFillType(fillTypeIndex, toolType)
			self.moneyChangeType.statistic = self.lastIncomeName
			g_currentMission:addMoney(-v46_, v44_, self.moneyChangeType, true)
			self.lastMoneyChangeFarmId = v44_
			self.lastMoneyChange = 30
			self:raiseActive()
			return v45_
		end
	else
		v45_ = 0
	end
	return v45_
end

function BuyingStation:getIncomeNameForFillType(fillType, toolType)
	if fillType == FillType.DIESEL then
		return self.incomeNameFuel
	elseif fillType == FillType.LIME then
		return self.incomeNameLime
	elseif self.fillTypeStatsName[fillType] == nil then
		return self.incomeName
	else
		return self.fillTypeStatsName[fillType]
	end
end

function BuyingStation:getIsFillAllowedToFarm(farmId)
	return true
end

function BuyingStation:getIsFillTypeSupported(fillType)
	return self.providedFillTypes[fillType] == true
end

function BuyingStation.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. ".fillType(?)#name", "Fill type name")
	schema:register(XMLValueType.STRING, basePath .. ".fillType(?)#statsName", "Name in stats", "other")
	schema:register(XMLValueType.FLOAT, basePath .. ".fillType(?)#priceScale", "Price scale", 1)
	LoadingStation.registerXMLPaths(schema, basePath)
end

-- Local values: fillTypeNames, fillTypesNamesString, _, fillTypeName, _, unloadTriggerKey, fillTypeNamesString, _, fillTypeName
function BuyingStation.loadSpecValueFillTypes(xmlFile, customEnvironment, baseDir)
	local v56_ = xmlFile:getValue("placeable.buyingStation#fillTypes")
	local v57_
	if v56_ == nil or v56_:trim() == "" then
		v57_ = nil
	else
		v57_ = {}
		for _, v58_ in pairs(string.split(v56_, " ")) do
			v57_[string.upper(v58_)] = true
		end
	end
	for _, v59_ in xmlFile:iterator("placeable.buyingStation.loadTrigger") do
		local v60_ = xmlFile:getValue(v59_ .. "#fillTypes")
		if v60_ ~= nil and v60_:trim() ~= "" then
			v57_ = v57_ or {}
			for _, v61_ in pairs(string.split(v60_, " ")) do
				v57_[string.upper(v61_)] = true
			end
		end
	end
	return PlaceableHeapSpawner.loadSpecValueFillTypes(xmlFile, customEnvironment, baseDir, v57_)
end

function BuyingStation.getSpecValueFillTypes(storeItem, realItem)
	if storeItem.specs.buyingStationFillTypes == nil then
		return nil
	else
		return g_fillTypeManager:getFillTypesByNames(table.concatKeys(storeItem.specs.buyingStationFillTypes, " "))
	end
end
