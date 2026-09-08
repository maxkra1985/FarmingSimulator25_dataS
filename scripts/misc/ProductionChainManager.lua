-- Local values: ProductionChainManager_mt
ProductionChainManager = {}
ProductionChainManager.NUM_MAX_PRODUCTION_POINTS = 60
local ProductionChainManager_mt = Class(ProductionChainManager, AbstractManager)

-- Upvalues: ProductionChainManager_mt
-- Local values: self
function ProductionChainManager.new(isServer, customMt)
	-- upvalues: (copy) ProductionChainManager_mt
	local v4_ = AbstractManager.new(customMt or ProductionChainManager_mt)
	v4_.isServer = isServer
	addConsoleCommand("gsProductionPointsList", "List all production points on map", "commandListProductionPoints", v4_)
	addConsoleCommand("gsProductionPointsPrintAutoDeliverMapping", "Prints which fillTypes are required by which production points", "commandPrintAutoDeliverMapping", v4_)
	addConsoleCommand("gsProductionPointSetOwner", "", "commandSetOwner", v4_)
	addConsoleCommand("gsProductionPointSetProductionState", "", "commandSetProductionState", v4_)
	addConsoleCommand("gsProductionPointSetOutputMode", "", "commandSetOutputMode", v4_)
	addConsoleCommand("gsProductionPointSetFillLevel", "", "commandSetFillLevel", v4_)
	if v4_.isServer then
		g_messageCenter:subscribe(MessageType.HOUR_CHANGED, v4_.hourChanged, v4_)
	end
	return v4_
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

-- Local values: farmId
function ProductionChainManager:addProductionPoint(productionPoint)
	if self.reverseProductionPoint[productionPoint] then
		Logging.warning("Production point \'%s\' already registered.", productionPoint:tableId())
		return false
	end
	if #self.productionPoints >= ProductionChainManager.NUM_MAX_PRODUCTION_POINTS then
		printf("Maximum number of %i Production Points reached.", ProductionChainManager.NUM_MAX_PRODUCTION_POINTS)
		return false
	end
	if #self.productionPoints == 0 and self.isServer then
		g_currentMission:addUpdateable(self)
	end
	self.reverseProductionPoint[productionPoint] = true
	local v9_ = self.productionPoints
	table.insert(v9_, productionPoint)
	local v10_ = productionPoint:getOwnerFarmId()
	if v10_ ~= AccessHandler.EVERYONE then
		if not self.farmIds[v10_] then
			self.farmIds[v10_] = {}
		end
		self:addProductionPointToFarm(productionPoint, self.farmIds[v10_])
	end
	return true
end

-- Local values: inputType
function ProductionChainManager:addProductionPointToFarm(productionPoint, farmTable)
	if not farmTable.productionPoints then
		farmTable.productionPoints = {}
	end
	local v13_ = farmTable.productionPoints
	table.insert(v13_, productionPoint)
	if not farmTable.inputTypeToProductionPoints then
		farmTable.inputTypeToProductionPoints = {}
	end
	for v14_ in pairs(productionPoint.inputFillTypeIds) do
		if not farmTable.inputTypeToProductionPoints[v14_] then
			farmTable.inputTypeToProductionPoints[v14_] = {}
		end
		local v15_ = farmTable.inputTypeToProductionPoints[v14_]
		table.insert(v15_, productionPoint)
	end
end

-- Local values: farmId
function ProductionChainManager:addFactory(factory)
	if self.reverseFactory[factory] then
		Logging.warning("Factory \'%s\' already registered.", factory:tableId())
		return false
	end
	self.reverseFactory[factory] = true
	local v18_ = self.factories
	table.insert(v18_, factory)
	local v19_ = factory:getOwnerFarmId()
	if v19_ ~= AccessHandler.EVERYONE then
		if not self.farmIds[v19_] then
			self.farmIds[v19_] = {}
		end
		self:addFactoryToFarm(factory, self.farmIds[v19_])
	end
	return true
end

function ProductionChainManager:addFactoryToFarm(factory, farmTable)
	if not farmTable.factories then
		farmTable.factories = {}
	end
	local v22_ = farmTable.factories
	table.insert(v22_, factory)
end

-- Local values: farmId
function ProductionChainManager:removeProductionPoint(productionPoint)
	self.reverseProductionPoint[productionPoint] = nil
	if table.removeElement(self.productionPoints, productionPoint) then
		local v25_ = productionPoint:getOwnerFarmId()
		if v25_ ~= AccessHandler.EVERYONE then
			self.farmIds[v25_] = self:removeProductionPointFromFarm(productionPoint, self.farmIds[v25_])
		end
	end
	if #self.productionPoints == 0 and self.isServer then
		g_currentMission:removeUpdateable(self)
	end
end

-- Local values: inputTypeToProductionPoints, inputType
function ProductionChainManager:removeProductionPointFromFarm(productionPoint, farmTable)
	if farmTable.productionPoints == nil then
		return farmTable
	end
	table.removeElement(farmTable.productionPoints, productionPoint)
	local v28_ = farmTable.inputTypeToProductionPoints
	for v29_ in pairs(productionPoint.inputFillTypeIds) do
		if v28_[v29_] then
			if not table.removeElement(v28_[v29_], productionPoint) then
				printError("Error: ProductionChainManager:removeProductionPoint(): Unable to remove production point from input type mapping")
			end
			if #v28_[v29_] == 0 then
				v28_[v29_] = nil
			end
		end
	end
	if #farmTable.productionPoints == 0 and farmTable.factories == nil then
		farmTable = nil
	end
	return farmTable
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
	end
	table.removeElement(farmTable.factories, factory)
	if #farmTable.factories == 0 and farmTable.productionPoints == nil then
		farmTable = nil
	end
	return farmTable
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

-- Local values: unownedPoints, _, point
function ProductionChainManager:getUnownedProductionPoints()
	local v41_ = {}
	for _, v42_ in pairs(self.productionPoints) do
		if v42_:getOwnerFarmId() == AccessHandler.EVERYONE then
			table.insert(v41_, v42_)
		end
	end
	return v41_
end

-- Local values: unownedFactories, _, factory
function ProductionChainManager:getUnownedFactories()
	local v44_ = {}
	for _, v45_ in pairs(self.factories) do
		if v45_:getOwnerFarmId() == AccessHandler.EVERYONE then
			table.insert(v44_, v45_)
		end
	end
	return v44_
end

function ProductionChainManager:getHasFreeSlots()
	return #self.productionPoints < ProductionChainManager.NUM_MAX_PRODUCTION_POINTS
end

-- Local values: prodPoint
function ProductionChainManager:update()
	if #self.productionPoints ~= 0 then
		if self.currentUpdateIndex > #self.productionPoints then
			self.currentUpdateIndex = 1
			if self.hourChangedDirty then
				self.hourChangeUpdating = true
				self.hourChangedDirty = false
			elseif self.hourChangeUpdating then
				self.hourChangeUpdating = false
				self:distributeGoods()
			end
		end
		local v48_ = self.productionPoints[self.currentUpdateIndex]
		if v48_ then
			v48_:updateProduction()
			if self.hourChangeUpdating and (self.isServer and v48_.isOwned) then
				v48_:claimProductionCosts()
				v48_:directlySellOutputs()
				v48_:updateBalaceDirectlySoldOutputs()
			end
		end
		self.currentUpdateIndex = self.currentUpdateIndex + 1
	end
end

function ProductionChainManager:hourChanged()
	self.hourChangedDirty = true
end

-- Local values: _, farmTable, i, distributingProdPoint, fillTypeIdToDistribute, amountToDistribute, prodPointsInDemand, totalFreeCapacity, n, n, prodPointInDemand, maxAmountToReceive, amountToTransfer, distanceSourceToTarget, transferCosts
function ProductionChainManager:distributeGoods()
	if self.isServer then
		for _, v51_ in pairs(self.farmIds) do
			if v51_.productionPoints ~= nil then
				for v52_ = 1, #v51_.productionPoints do
					local v53_ = v51_.productionPoints[v52_]
					for v54_ in pairs(v53_.outputFillTypeIdsAutoDeliver) do
						local v55_ = v53_.storage:getFillLevel(v54_)
						if v55_ > 0 then
							local v56_ = v51_.inputTypeToProductionPoints[v54_] or {}
							local v57_ = 0
							for v58_ = 1, #v56_ do
								v57_ = v57_ + v56_[v58_].storage:getFreeCapacity(v54_, true)
							end
							if v57_ > 0 then
								for v59_ = 1, #v56_ do
									local v60_ = v56_[v59_]
									local v61_ = v60_.storage:getFreeCapacity(v54_, true)
									if v61_ > 0 then
										local v62_ = v55_ * (v61_ / v57_)
										local v63_ = math.min(v61_, v62_)
										local v64_ = v63_ * calcDistanceFrom(v53_.owningPlaceable.rootNode, v60_.owningPlaceable.rootNode) * ProductionPoint.DIRECT_DELIVERY_PRICE
										g_currentMission:addMoney(-v64_, v60_.ownerFarmId, MoneyType.PRODUCTION_COSTS, true)
										v60_.storage:setFillLevel(v60_.storage:getFillLevel(v54_) + v63_, v54_)
										v53_.storage:setFillLevel(v53_.storage:getFillLevel(v54_) - v63_, v54_)
									end
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

-- Local values: i, productionPoint
function ProductionChainManager:commandListProductionPoints()
	if #self.productionPoints <= 0 then
		return "no productions points available"
	end
	print("available production points:")
	for v66_ = 1, #self.productionPoints do
		local v67_ = self.productionPoints[v66_]
		print(string.format("%i: %s", v66_, v67_:toString()))
	end
	return string.format("listed %i production points", #self.productionPoints)
end

-- Local values: farmId, farmTable, inputType, prodPoints, _, prodPoint
function ProductionChainManager:commandPrintAutoDeliverMapping()
	print("AutoDeliverMapping")
	for v69_, v70_ in pairs(self.farmIds) do
		printf("  Farm %i", v69_)
		for v71_, v72_ in pairs(v70_.inputTypeToProductionPoints) do
			print(string.format("    FillType %s distributed to", g_fillTypeManager:getFillTypeNameByIndex(v71_)))
			for _, v73_ in pairs(v72_) do
				print(string.format("      %s", v73_:toString()))
			end
		end
	end
end

-- Local values: usage, productionPoints, _, prodPoint
function ProductionChainManager:commandSetOwner(ppIdentifier, farmId)
	local v77_ = self:getProductionPointsFromString(ppIdentifier)
	local v78_ = tonumber(farmId)
	if v77_ == false then
		return "Error: no production point given\nUsage: gsProductionPointSetOwner ppIdentifier farmId"
	end
	if v78_ == nil then
		return "Error: no farmId given\nUsage: gsProductionPointSetOwner ppIdentifier farmId"
	end
	local v79_ = table.clone(v77_)
	for _, v80_ in pairs(v79_) do
		v80_:setOwnerFarmId(v78_, true)
	end
	return string.format("Updated owner for %d production points", table.size(v79_))
end

-- Local values: usage, productionPoints, productions, _, prodPoint, _, production, production, _, ppProdPair, prodPoint, production
function ProductionChainManager:commandSetProductionState(ppIdentifier, productionIdentifier, state)
	local v85_ = self:getProductionPointsFromString(ppIdentifier)
	local v86_ = Utils.stringToBoolean(state)
	if v85_ == false then
		return "Error: no production point given\nUsage: gsProductionPointSetProductionState ppIdentifier productionIdentifier|all state"
	end
	if productionIdentifier == nil then
		return "Error: no production identifier given\nUsage: gsProductionPointSetProductionState ppIdentifier productionIdentifier|all state"
	end
	if v86_ == nil then
		return "Error: no valid state given\nUsage: gsProductionPointSetProductionState ppIdentifier productionIdentifier|all state"
	end
	local v87_ = {}
	for _, v88_ in pairs(v85_) do
		if string.lower(productionIdentifier) == "all" then
			for _, v89_ in pairs(v88_.productions) do
				table.insert(v87_, { v88_, v89_ })
			end
		else
			local v90_ = v88_.productionsIdToObj[productionIdentifier]
			if v90_ then
				table.insert(v87_, { v88_, v90_ })
			end
		end
	end
	if #v87_ == 0 then
		return string.format("Error: no productions found for identifier \'%s\'\n%s", productionIdentifier, "Usage: gsProductionPointSetProductionState ppIdentifier productionIdentifier|all state")
	end
	for _, v91_ in pairs(v87_) do
		local v92_ = v91_[1]
		local v93_ = v91_[2]
		v92_:setProductionState(v93_.id, v86_)
		print(string.format("%s (%s): %s = %s", v92_:getName(), v92_:tableId(), v93_.id, v86_))
	end
	return string.format("Updated state for %d productions", table.size(v87_))
end

-- Local values: usage, outputModes, productionPoints, outputType, _, prodPoint, _, prodPoint, outputType
function ProductionChainManager:commandSetOutputMode(ppIdentifier, outputFillTypeIdentifier, mode)
	local function v102_()
		local v98_ = {}
		for v99_, v100_ in pairs(ProductionPoint.OUTPUT_MODE) do
			local v101_ = v100_ .. "=" .. v99_
			table.insert(v98_, v101_)
		end
		return table.concat(v98_, "\n")
	end
	local v103_ = self:getProductionPointsFromString(ppIdentifier)
	if v103_ == false then
		return "Error: no production point given\nUsage: gsProductionPointSetOutputMode ppIdentifier outputFillType|all outputMode"
	end
	if not outputFillTypeIdentifier then
		return "Error: Missing argument outputFillType.\nUsage: gsProductionPointSetOutputMode ppIdentifier outputFillType|all outputMode"
	end
	if not table.hasElement(ProductionPoint.OUTPUT_MODE, (tonumber(mode))) then
		return string.format("Error: Invalid output mode \'%s\'. Available modes:\n%s", mode, v102_())
	end
	if string.lower(outputFillTypeIdentifier) == "all" then
		for _, v104_ in pairs(v103_) do
			for v105_ in pairs(v104_.outputFillTypeIds) do
				v104_:setOutputDistributionMode(v105_, mode)
			end
		end
	else
		local v106_ = g_fillTypeManager:getFillTypeIndexByName(outputFillTypeIdentifier)
		for _, v107_ in pairs(v103_) do
			if v107_.outputFillTypeIds[v106_] then
				v107_:setOutputDistributionMode(v106_, mode)
			end
		end
	end
	return "Updated production points"
end

-- Local values: usage, productionPoints, fillType, numStorageSpaces, _, prodPoint, supportedFillType
function ProductionChainManager:commandSetFillLevel(ppIdentifier, fillTypeIdentifier, fillLevel)
	local v112_ = self:getProductionPointsFromString(ppIdentifier)
	if v112_ == false then
		return "Error: no production point given\nUsage: gsProductionPointSetFillLevel ppIdentifier fillTypeName|all fillLevel"
	end
	local v113_ = g_fillTypeManager:getFillTypeIndexByName(fillTypeIdentifier)
	if not fillTypeIdentifier or string.lower(fillTypeIdentifier) ~= "all" and not v113_ then
		return "Error: no valid fillType given\nUsage: gsProductionPointSetFillLevel ppIdentifier fillTypeName|all fillLevel"
	end
	local v114_ = tonumber(fillLevel)
	if not v114_ then
		return "Error: no fillLevel given\nUsage: gsProductionPointSetFillLevel ppIdentifier fillTypeName|all fillLevel"
	end
	local v115_ = 0
	for _, v116_ in pairs(v112_) do
		if string.lower(fillTypeIdentifier) == "all" then
			for v117_ in pairs(v116_.storage:getSupportedFillTypes()) do
				v116_.storage:setFillLevel(v114_, v117_)
				v115_ = v115_ + 1
			end
		elseif v113_ and v116_.storage:getIsFillTypeSupported(v113_) then
			v116_.storage:setFillLevel(v114_, v113_)
			v115_ = v115_ + 1
		end
	end
	return string.format("Filled %i storage spaces", v115_)
end

-- Local values: _, prodPoint
function ProductionChainManager:consoleCommandToggleProdPointDebug()
	self.debugEnabled = not self.debugEnabled
	if g_currentMission ~= nil then
		for _, v119_ in pairs(self.productionPoints) do
			if self.debugEnabled then
				g_currentMission:addDrawable(v119_)
			else
				g_currentMission:removeDrawable(v119_)
			end
		end
	end
	local v120_ = self.debugEnabled
	return "ProductionChainManager.debugEnabled=" .. tostring(v120_)
end

-- Local values: prodPoints, prodPoint, _, productionPoint
function ProductionChainManager:getProductionPointsFromString(identificationString)
	if not identificationString or identificationString == "" then
		return false
	end
	local v123_ = {}
	if string.lower(identificationString) == "all" then
		return self.productionPoints
	end
	local v124_ = self.productionPoints[tonumber(identificationString)]
	if not v124_ and string.len(identificationString) >= 4 then
		for _, v125_ in pairs(self.productionPoints) do
			if string.find(v125_:tableId(), identificationString) then
				if v124_ ~= nil then
					printError(string.format("Error: Multiple production points for index/identifier \'%s\'. Please provide a longer identifier.", identificationString))
					self:commandListProductionPoints()
					return false
				end
				v124_ = v125_
			end
		end
	end
	if v124_ then
		table.insert(v123_, v124_)
		return v123_
	end
	printError(string.format("Error: No Production Point for index/identifier \'%s\'", identificationString))
	self:commandListProductionPoints()
	return false
end
