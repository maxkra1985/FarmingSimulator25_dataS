ProductionChainManager = {}
ProductionChainManager.NUM_MAX_PRODUCTION_POINTS = 60
local ProductionChainManager_mt = Class(ProductionChainManager, AbstractManager)
function ProductionChainManager.new(isServer, customMt)
	local self = AbstractManager.new(customMt or ProductionChainManager_mt)
	self.isServer = isServer
	addConsoleCommand("gsProductionPointsList", "List all production points on map", "commandListProductionPoints", self)
	addConsoleCommand("gsProductionPointsPrintAutoDeliverMapping", "Prints which fillTypes are required by which production points", "commandPrintAutoDeliverMapping", self)
	addConsoleCommand("gsProductionPointSetOwner", "", "commandSetOwner", self)
	addConsoleCommand("gsProductionPointSetProductionState", "", "commandSetProductionState", self)
	addConsoleCommand("gsProductionPointSetOutputMode", "", "commandSetOutputMode", self)
	addConsoleCommand("gsProductionPointSetFillLevel", "", "commandSetFillLevel", self)
	if self.isServer then
		g_messageCenter:subscribe(MessageType.HOUR_CHANGED, self.hourChanged, self)
	end
	return self
end
function ProductionChainManager:initDataStructures()
	self.productionPoints = {}
	self.reverseProductionPoint = {}
	self.factories = {}
	self.reverseFactory = {}
	self.farmIds = {}
	self.currentUpdateIndex = 1
	self.hourChangedDirty = false
	self.hourChangeUpdating = false
end
function ProductionChainManager:unloadMapData()
	removeConsoleCommand("gsProductionPointsList")
	removeConsoleCommand("gsProductionPointsPrintAutoDeliverMapping")
	removeConsoleCommand("gsProductionPointSetOwner")
	removeConsoleCommand("gsProductionPointSetProductionState")
	removeConsoleCommand("gsProductionPointSetOutputMode")
	removeConsoleCommand("gsProductionPointSetFillLevel")
	if self.isServer then
		g_messageCenter:unsubscribe(MessageType.HOUR_CHANGED, self)
	end
	ProductionChainManager:superClass().unloadMapData(self)
end
function ProductionChainManager:addProductionPoint(productionPoint)
	if self.reverseProductionPoint[productionPoint] then
		Logging.warning("Production point '%s' already registered.", productionPoint:tableId())
		return false
	elseif ProductionChainManager.NUM_MAX_PRODUCTION_POINTS <= #self.productionPoints then
		printf("Maximum number of %i Production Points reached.", ProductionChainManager.NUM_MAX_PRODUCTION_POINTS)
		return false
	else
		if #self.productionPoints == 0 and self.isServer then
			g_currentMission:addUpdateable(self)
		end
		self.reverseProductionPoint[productionPoint] = true
		table.insert(self.productionPoints, productionPoint)
		local farmId = productionPoint:getOwnerFarmId()
		if farmId ~= AccessHandler.EVERYONE then
			if not self.farmIds[farmId] then
				self.farmIds[farmId] = {}
			end
			self:addProductionPointToFarm(productionPoint, self.farmIds[farmId])
		end
		return true
	end
end
function ProductionChainManager:addProductionPointToFarm(productionPoint, farmTable)
	if not farmTable.productionPoints then
		farmTable.productionPoints = {}
	end
	table.insert(farmTable.productionPoints, productionPoint)
	if not farmTable.inputTypeToProductionPoints then
		farmTable.inputTypeToProductionPoints = {}
	end
	for inputType in pairs(productionPoint.inputFillTypeIds) do
		if not farmTable.inputTypeToProductionPoints[inputType] then
			farmTable.inputTypeToProductionPoints[inputType] = {}
		end
		table.insert(farmTable.inputTypeToProductionPoints[inputType], productionPoint)
	end
end
function ProductionChainManager:addFactory(factory)
	if self.reverseFactory[factory] then
		Logging.warning("Factory '%s' already registered.", factory:tableId())
		return false
	else
		self.reverseFactory[factory] = true
		table.insert(self.factories, factory)
		local farmId = factory:getOwnerFarmId()
		if farmId ~= AccessHandler.EVERYONE then
			if not self.farmIds[farmId] then
				self.farmIds[farmId] = {}
			end
			self:addFactoryToFarm(factory, self.farmIds[farmId])
		end
		return true
	end
end
function ProductionChainManager:addFactoryToFarm(factory, farmTable)
	if not farmTable.factories then
		farmTable.factories = {}
	end
	table.insert(farmTable.factories, factory)
end
function ProductionChainManager:removeProductionPoint(productionPoint)
	self.reverseProductionPoint[productionPoint] = nil
	if table.removeElement(self.productionPoints, productionPoint) then
		local farmId = productionPoint:getOwnerFarmId()
		if farmId ~= AccessHandler.EVERYONE then
			self.farmIds[farmId] = self:removeProductionPointFromFarm(productionPoint, self.farmIds[farmId])
		end
	end
	if #self.productionPoints == 0 and self.isServer then
		g_currentMission:removeUpdateable(self)
	end
end
function ProductionChainManager:removeProductionPointFromFarm(productionPoint, farmTable)
	if farmTable.productionPoints == nil then
		return farmTable
	else
		table.removeElement(farmTable.productionPoints, productionPoint)
		local inputTypeToProductionPoints = farmTable.inputTypeToProductionPoints
		for inputType in pairs(productionPoint.inputFillTypeIds) do
			if inputTypeToProductionPoints[inputType] then
				if not table.removeElement(inputTypeToProductionPoints[inputType], productionPoint) then
					printError("Error: ProductionChainManager:removeProductionPoint(): Unable to remove production point from input type mapping")
				end
				if #inputTypeToProductionPoints[inputType] == 0 then
					inputTypeToProductionPoints[inputType] = nil
				end
			end
		end
		if #farmTable.productionPoints == 0 and farmTable.factories == nil then
			farmTable = nil
		end
		return farmTable
	end
end
function ProductionChainManager:removeFactory(factory, farmId)
	self.reverseFactory[factory] = nil
	if table.removeElement(self.factories, factory) and (farmId ~= AccessHandler.EVERYONE and self.farmIds[farmId] ~= nil) then
		self.farmIds[farmId] = self:removeFactoryFromFarm(factory, self.farmIds[farmId])
	end
end
function ProductionChainManager:removeFactoryFromFarm(factory, farmTable)
	if farmTable.factories == nil then
		return farmTable
	else
		table.removeElement(farmTable.factories, factory)
		if #farmTable.factories == 0 and farmTable.productionPoints == nil then
			farmTable = nil
		end
		return farmTable
	end
end
function ProductionChainManager:getProductionPointsForFarmId(farmId)
	return self.farmIds[farmId] and self.farmIds[farmId].productionPoints or {}
end
function ProductionChainManager:getFactoriesForFarmId(farmId)
	return self.farmIds[farmId] and self.farmIds[farmId].factories or {}
end
function ProductionChainManager:getNumOfProductionPoints()
	return #self.productionPoints
end
function ProductionChainManager:getUnownedProductionPoints()
	local unownedPoints = {}
	for _, point in pairs(self.productionPoints) do
		if point:getOwnerFarmId() == AccessHandler.EVERYONE then
			table.insert(unownedPoints, point)
		end
	end
	return unownedPoints
end
function ProductionChainManager:getUnownedFactories()
	local unownedFactories = {}
	for _, factory in pairs(self.factories) do
		if factory:getOwnerFarmId() == AccessHandler.EVERYONE then
			table.insert(unownedFactories, factory)
		end
	end
	return unownedFactories
end
function ProductionChainManager:getHasFreeSlots()
	return #self.productionPoints < ProductionChainManager.NUM_MAX_PRODUCTION_POINTS
end
function ProductionChainManager:update()
	if #self.productionPoints == 0 then
		return
	else
		if #self.productionPoints < self.currentUpdateIndex then
			self.currentUpdateIndex = 1
			if self.hourChangedDirty then
				self.hourChangeUpdating = true
				self.hourChangedDirty = false
			elseif self.hourChangeUpdating then
				self.hourChangeUpdating = false
				self:distributeGoods()
			end
		end
		local prodPoint = self.productionPoints[self.currentUpdateIndex]
		if prodPoint then
			prodPoint:updateProduction()
			if self.hourChangeUpdating and (self.isServer and prodPoint.isOwned) then
				prodPoint:claimProductionCosts()
				prodPoint:directlySellOutputs()
				prodPoint:updateBalaceDirectlySoldOutputs()
			end
		end
		self.currentUpdateIndex = self.currentUpdateIndex + 1
	end
end
function ProductionChainManager:hourChanged()
	self.hourChangedDirty = true
end
function ProductionChainManager:distributeGoods()
	if not self.isServer then
		return
	else
		for _, farmTable in pairs(self.farmIds) do
			if farmTable.productionPoints == nil then
				continue
			end
			for i = 1, #farmTable.productionPoints do
				local distributingProdPoint = farmTable.productionPoints[i]
				for fillTypeIdToDistribute in pairs(distributingProdPoint.outputFillTypeIdsAutoDeliver) do
					local amountToDistribute = distributingProdPoint.storage:getFillLevel(fillTypeIdToDistribute)
					if 0 < amountToDistribute then
						local prodPointsInDemand = farmTable.inputTypeToProductionPoints[fillTypeIdToDistribute] or {}
						local totalFreeCapacity = 0
						for n = 1, #prodPointsInDemand do
							totalFreeCapacity = totalFreeCapacity + prodPointsInDemand[n].storage:getFreeCapacity(fillTypeIdToDistribute, true)
						end
						if 0 < totalFreeCapacity then
							for n = 1, #prodPointsInDemand do
								local prodPointInDemand = prodPointsInDemand[n]
								local maxAmountToReceive = prodPointInDemand.storage:getFreeCapacity(fillTypeIdToDistribute, true)
								if 0 < maxAmountToReceive then
									local amountToTransfer = math.min(maxAmountToReceive, amountToDistribute * (maxAmountToReceive / totalFreeCapacity))
									local distanceSourceToTarget = calcDistanceFrom(distributingProdPoint.owningPlaceable.rootNode, prodPointInDemand.owningPlaceable.rootNode)
									local transferCosts = amountToTransfer * distanceSourceToTarget * ProductionPoint.DIRECT_DELIVERY_PRICE
									g_currentMission:addMoney(-transferCosts, prodPointInDemand.ownerFarmId, MoneyType.PRODUCTION_COSTS, true)
									prodPointInDemand.storage:setFillLevel(prodPointInDemand.storage:getFillLevel(fillTypeIdToDistribute) + amountToTransfer, fillTypeIdToDistribute)
									distributingProdPoint.storage:setFillLevel(distributingProdPoint.storage:getFillLevel(fillTypeIdToDistribute) - amountToTransfer, fillTypeIdToDistribute)
								end
							end
						end
					end
				end
			end
		end
	end
end
function ProductionChainManager:updateBalance() end
function ProductionChainManager:commandListProductionPoints()
	if 0 < #self.productionPoints then
		print("available production points:")
		for i = 1, #self.productionPoints do
			local productionPoint = self.productionPoints[i]
			print(string.format("%i: %s", i, productionPoint:toString()))
		end
		return string.format("listed %i production points", #self.productionPoints)
	else
		return "no productions points available"
	end
end
function ProductionChainManager:commandPrintAutoDeliverMapping()
	print("AutoDeliverMapping")
	for farmId, farmTable in pairs(self.farmIds) do
		printf("  Farm %i", farmId)
		for inputType, prodPoints in pairs(farmTable.inputTypeToProductionPoints) do
			print(string.format("    FillType %s distributed to", g_fillTypeManager:getFillTypeNameByIndex(inputType)))
			for _, prodPoint in pairs(prodPoints) do
				print(string.format("      %s", prodPoint:toString()))
			end
		end
	end
end
function ProductionChainManager:commandSetOwner(ppIdentifier, farmId)
	local usage = "Usage: gsProductionPointSetOwner ppIdentifier farmId"
	local productionPoints = self:getProductionPointsFromString(ppIdentifier)
	farmId = tonumber(farmId)
	if productionPoints == false then
		return "Error: no production point given\n" .. "Usage: gsProductionPointSetOwner ppIdentifier farmId"
	elseif farmId == nil then
		return "Error: no farmId given\n" .. "Usage: gsProductionPointSetOwner ppIdentifier farmId"
	else
		productionPoints = table.clone(productionPoints)
		for _, prodPoint in pairs(productionPoints) do
			prodPoint:setOwnerFarmId(farmId, true)
		end
		return string.format("Updated owner for %d production points", table.size(productionPoints))
	end
end
function ProductionChainManager:commandSetProductionState(ppIdentifier, productionIdentifier, state)
	local usage = "Usage: gsProductionPointSetProductionState ppIdentifier productionIdentifier|all state"
	local productionPoints = self:getProductionPointsFromString(ppIdentifier)
	state = Utils.stringToBoolean(state)
	if productionPoints == false then
		return "Error: no production point given\n" .. "Usage: gsProductionPointSetProductionState ppIdentifier productionIdentifier|all state"
	end
	if productionIdentifier == nil then
		return "Error: no production identifier given\n" .. "Usage: gsProductionPointSetProductionState ppIdentifier productionIdentifier|all state"
	end
	if state == nil then
		return "Error: no valid state given\n" .. "Usage: gsProductionPointSetProductionState ppIdentifier productionIdentifier|all state"
	end
	local productions = {}
	for _, prodPoint in pairs(productionPoints) do
		if string.lower(productionIdentifier) == "all" then
			for _, production in pairs(prodPoint.productions) do
				table.insert(productions, { prodPoint, production })
			end
		else
			local production = prodPoint.productionsIdToObj[productionIdentifier]
			if production then
				table.insert(productions, { prodPoint, production })
			end
		end
	end
	if #productions == 0 then
		return string.format("Error: no productions found for identifier '%s'\n%s", productionIdentifier, "Usage: gsProductionPointSetProductionState ppIdentifier productionIdentifier|all state")
	else
		for _, ppProdPair in pairs(productions) do
			local prodPoint = ppProdPair[1]
			local production = ppProdPair[2]
			prodPoint:setProductionState(production.id, state)
			print(string.format("%s (%s): %s = %s", prodPoint:getName(), prodPoint:tableId(), production.id, state))
		end
		return string.format("Updated state for %d productions", table.size(productions))
	end
end
function ProductionChainManager:commandSetOutputMode(ppIdentifier, outputFillTypeIdentifier, mode)
	local usage = "Usage: gsProductionPointSetOutputMode ppIdentifier outputFillType|all outputMode"
	local outputModes = function()
		local str = {}
		for key, val in pairs(ProductionPoint.OUTPUT_MODE) do
			table.insert(str, val .. "=" .. key)
		end
		return table.concat(str, "\n")
	end
	local productionPoints = self:getProductionPointsFromString(ppIdentifier)
	if productionPoints == false then
		return "Error: no production point given\n" .. "Usage: gsProductionPointSetOutputMode ppIdentifier outputFillType|all outputMode"
	elseif not outputFillTypeIdentifier then
		return "Error: Missing argument outputFillType.\n" .. "Usage: gsProductionPointSetOutputMode ppIdentifier outputFillType|all outputMode"
	elseif not table.hasElement(ProductionPoint.OUTPUT_MODE, tonumber(mode)) then
		return string.format("Error: Invalid output mode '%s'. Available modes:\n%s", mode, outputModes())
	else
		if string.lower(outputFillTypeIdentifier) ~= "all" then
			local outputType = g_fillTypeManager:getFillTypeIndexByName(outputFillTypeIdentifier)
			for _, prodPoint in pairs(productionPoints) do
				if prodPoint.outputFillTypeIds[outputType] then
					prodPoint:setOutputDistributionMode(outputType, mode)
				end
			end
		else
			for _, prodPoint in pairs(productionPoints) do
				for outputType in pairs(prodPoint.outputFillTypeIds) do
					prodPoint:setOutputDistributionMode(outputType, mode)
				end
			end
		end
		return "Updated production points"
	end
end
function ProductionChainManager:commandSetFillLevel(ppIdentifier, fillTypeIdentifier, fillLevel)
	local usage = "Usage: gsProductionPointSetFillLevel ppIdentifier fillTypeName|all fillLevel"
	local productionPoints = self:getProductionPointsFromString(ppIdentifier)
	if productionPoints == false then
		return "Error: no production point given\n" .. "Usage: gsProductionPointSetFillLevel ppIdentifier fillTypeName|all fillLevel"
	end
	local fillType = g_fillTypeManager:getFillTypeIndexByName(fillTypeIdentifier)
	if not fillTypeIdentifier or string.lower(fillTypeIdentifier) ~= "all" and not fillType then
		return "Error: no valid fillType given\n" .. "Usage: gsProductionPointSetFillLevel ppIdentifier fillTypeName|all fillLevel"
	end
	fillLevel = tonumber(fillLevel)
	if not fillLevel then
		return "Error: no fillLevel given\n" .. "Usage: gsProductionPointSetFillLevel ppIdentifier fillTypeName|all fillLevel"
	else
		local numStorageSpaces = 0
		for _, prodPoint in pairs(productionPoints) do
			if string.lower(fillTypeIdentifier) ~= "all" then
				if fillType and prodPoint.storage:getIsFillTypeSupported(fillType) then
					prodPoint.storage:setFillLevel(fillLevel, fillType)
					numStorageSpaces = numStorageSpaces + 1
				end
			else
				for supportedFillType in pairs(prodPoint.storage:getSupportedFillTypes()) do
					prodPoint.storage:setFillLevel(fillLevel, supportedFillType)
					numStorageSpaces = numStorageSpaces + 1
				end
			end
		end
		return string.format("Filled %i storage spaces", numStorageSpaces)
	end
end
function ProductionChainManager:consoleCommandToggleProdPointDebug()
	self.debugEnabled = not self.debugEnabled
	if g_currentMission ~= nil then
		for _, prodPoint in pairs(self.productionPoints) do
			if self.debugEnabled then
				g_currentMission:addDrawable(prodPoint)
			else
				g_currentMission:removeDrawable(prodPoint)
			end
		end
	end
	return "ProductionChainManager.debugEnabled=" .. tostring(self.debugEnabled)
end
function ProductionChainManager:getProductionPointsFromString(identificationString)
	if not identificationString or identificationString == "" then
		return false
	end
	local prodPoints = {}
	if string.lower(identificationString) == "all" then
		prodPoints = self.productionPoints
		return prodPoints
	end
	local prodPoint = self.productionPoints[tonumber(identificationString)]
	if not prodPoint and 4 <= string.len(identificationString) then
		for _, productionPoint in pairs(self.productionPoints) do
			if string.find(productionPoint:tableId(), identificationString) then
				if prodPoint == nil then
					prodPoint = productionPoint
				else
					printError(string.format("Error: Multiple production points for index/identifier '%s'. Please provide a longer identifier.", identificationString))
					self:commandListProductionPoints()
					return false
				end
			end
		end
	end
	if not prodPoint then
		printError(string.format("Error: No Production Point for index/identifier '%s'", identificationString))
		self:commandListProductionPoints()
		return false
	else
		table.insert(prodPoints, prodPoint)
		return prodPoints
	end
end
