BuyingStation = {}
local BuyingStation_mt = Class(BuyingStation, LoadingStation)
InitStaticObjectClass(BuyingStation, "BuyingStation")
function BuyingStation.new(isServer, isClient, customMt)
	local self = LoadingStation.new(isServer, isClient, customMt or BuyingStation_mt)
	self.incomeName = "other"
	self.incomeNameFuel = "purchaseFuel"
	self.incomeNameLime = "other"
	return self
end
function BuyingStation:load(components, xmlFile, key, customEnv, i3dMappings)
	if not BuyingStation:superClass().load(self, components, xmlFile, key, customEnv, i3dMappings) then
		return false
	else
		self.lastMoneyChange = 0
		self.providedFillTypes = {}
		self.fillTypePricesScale = {}
		self.fillTypeStatsName = {}
		local i = 0
		while true do
			local fillTypeKey = string.format(key .. ".fillType(%d)", i)
			if not xmlFile:hasProperty(fillTypeKey) then
				break
			end
			local fillTypeStr = xmlFile:getValue(fillTypeKey .. "#name")
			local fillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(fillTypeStr)
			local fillTypeStatsName = xmlFile:getValue(fillTypeKey .. "#statsName", "other")
			if FinanceStats.statNameToIndex[fillTypeStatsName] == nil then
				Logging.xmlWarning(xmlFile, "StatsName '%s' for fillType '%s' is not defined for buying station", fillTypeStatsName, fillTypeStr)
				fillTypeStatsName = "other"
			end
			if fillTypeIndex ~= nil then
				if self.supportedFillTypes[fillTypeIndex] ~= nil then
					local priceScale = xmlFile:getValue(fillTypeKey .. "#priceScale", 1)
					self.fillTypePricesScale[fillTypeIndex] = priceScale
					self.fillTypeStatsName[fillTypeIndex] = fillTypeStatsName
					self.providedFillTypes[fillTypeIndex] = true
				else
					Logging.xmlWarning(xmlFile, "FillType '%s' is not supported by loading triggers for buying station", fillTypeStr)
				end
			end
			i = i + 1
		end
		for fillTypeIndex in pairs(self.supportedFillTypes) do
			if self.fillTypePricesScale[fillTypeIndex] == nil then
				self.fillTypePricesScale[fillTypeIndex] = 1
				self.fillTypeStatsName[fillTypeIndex] = "other"
				self.providedFillTypes[fillTypeIndex] = true
			end
		end
		if self.isServer then
			self.moneyChangeType = MoneyType.register("other", "finance_other")
		end
		return true
	end
end
function BuyingStation:readStream(streamId, connection)
	local moneyTypeId = streamReadUInt16(streamId)
	self.moneyChangeType = MoneyType.registerWithId(moneyTypeId, "other", "finance_other")
	BuyingStation:superClass().readStream(self, streamId, connection)
end
function BuyingStation:writeStream(streamId, connection)
	streamWriteUInt16(streamId, self.moneyChangeType.id)
	BuyingStation:superClass().writeStream(self, streamId, connection)
end
function BuyingStation:update(dt)
	if 0 < self.lastMoneyChange then
		self.lastMoneyChange = self.lastMoneyChange - 1
		if self.lastMoneyChange == 0 then
			g_currentMission:showMoneyChange(self.moneyChangeType, "finance_" .. self.lastIncomeName, false, self.lastMoneyChangeFarmId)
		end
		self:raiseActive()
	end
end
function BuyingStation:addSourceStorage(storage)
	printError("Error: LoadingStation '" .. tostring(self:getName()) .. "' is a buying point and does not accept any storages!")
	return false
end
function BuyingStation:getAllFillLevels()
	local fillLevels = {}
	local capacity = 1
	for fillType, _ in pairs(self.supportedFillTypes) do
		fillLevels[fillType] = 1
	end
	return fillLevels, capacity
end
function BuyingStation:getEffectiveFillTypePrice(fillTypeIndex)
	local fillType = g_fillTypeManager:getFillTypeByIndex(fillTypeIndex)
	local multiplier = EconomyManager.getPriceMultiplier(fillTypeIndex)
	if fillTypeIndex == FillType.DIESEL or fillTypeIndex == FillType.DEF then
		multiplier = 1
	end
	local pricePerLiter = self.fillTypePricesScale[fillTypeIndex] * fillType.pricePerLiter * multiplier
	return pricePerLiter
end
function BuyingStation:addFillLevelToFillableObject(fillableObject, fillUnitIndex, fillTypeIndex, fillDelta, fillInfo, toolType)
	if fillableObject == nil or fillTypeIndex == FillType.UNKNOWN or fillDelta == 0 or toolType == nil then
		return 0
	end
	local farmId = fillableObject:getOwnerFarmId()
	if 0 < g_currentMission:getMoney(farmId) then
		fillDelta = fillableObject:addFillUnitFillLevel(farmId, fillUnitIndex, fillDelta, fillTypeIndex, toolType, fillInfo)
		if 0 < fillDelta then
			local price = self:getEffectiveFillTypePrice(fillTypeIndex) * fillDelta
			self.lastIncomeName = self:getIncomeNameForFillType(fillTypeIndex, toolType)
			self.moneyChangeType.statistic = self.lastIncomeName
			g_currentMission:addMoney(-price, farmId, self.moneyChangeType, true)
			self.lastMoneyChangeFarmId = farmId
			self.lastMoneyChange = 30
			self:raiseActive()
			return fillDelta
		end
	else
		fillDelta = 0
	end
	return fillDelta
end
function BuyingStation:getIncomeNameForFillType(fillType, toolType)
	if fillType == FillType.DIESEL then
		return self.incomeNameFuel
	elseif fillType == FillType.LIME then
		return self.incomeNameLime
	elseif self.fillTypeStatsName[fillType] ~= nil then
		return self.fillTypeStatsName[fillType]
	else
		return self.incomeName
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
function BuyingStation.loadSpecValueFillTypes(xmlFile, customEnvironment, baseDir)
	local fillTypeNames = nil
	local fillTypesNamesString = xmlFile:getValue("placeable.buyingStation#fillTypes")
	if fillTypesNamesString ~= nil and fillTypesNamesString:trim() ~= "" then
		fillTypeNames = {}
		for _, fillTypeName in pairs(string.split(fillTypesNamesString, " ")) do
			fillTypeNames[string.upper(fillTypeName)] = true
		end
	end
	for _, unloadTriggerKey in xmlFile:iterator("placeable.buyingStation.loadTrigger") do
		local fillTypeNamesString = xmlFile:getValue(unloadTriggerKey .. "#fillTypes")
		if fillTypeNamesString == nil or fillTypeNamesString:trim() == "" then
			continue
		end
		fillTypeNames = fillTypeNames or {}
		for _, fillTypeName in pairs(string.split(fillTypeNamesString, " ")) do
			fillTypeNames[string.upper(fillTypeName)] = true
		end
	end
	fillTypeNames = PlaceableHeapSpawner.loadSpecValueFillTypes(xmlFile, customEnvironment, baseDir, fillTypeNames)
	return fillTypeNames
end
function BuyingStation.getSpecValueFillTypes(storeItem, realItem)
	if storeItem.specs.buyingStationFillTypes == nil then
		return nil
	else
		return g_fillTypeManager:getFillTypesByNames(table.concatKeys(storeItem.specs.buyingStationFillTypes, " "))
	end
end
