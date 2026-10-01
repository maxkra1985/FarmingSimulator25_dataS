GameTestCaseAILoadAndDeliver = {}
local GameTestCaseAILoadAndDeliver_mt = Class(GameTestCaseAILoadAndDeliver, GameTestCaseAI)
function GameTestCaseAILoadAndDeliver.new(customMt)
	local self = GameTestCaseAI.new(customMt or GameTestCaseAILoadAndDeliver_mt)
	self.vehicleSetup = nil
	self.spawnPosition = nil
	self.fillType = nil
	self.loadingStation = nil
	self.unloadingStation = nil
	return self
end
function GameTestCaseAILoadAndDeliver:setVehicleSetup(vehicleSetup)
	self.vehicleSetup = vehicleSetup
end
function GameTestCaseAILoadAndDeliver:setSpawnPosition(spawnPosition)
	self.spawnPosition = spawnPosition
end
function GameTestCaseAILoadAndDeliver:setFillType(fillType)
	self.fillType = fillType
end
function GameTestCaseAILoadAndDeliver:setStations(loadingStation, unloadingStation)
	self.loadingStation = loadingStation
	self.unloadingStation = unloadingStation
end
function GameTestCaseAILoadAndDeliver:finalize()
	if self.vehicleSetup == nil then
		return false
	elseif self.spawnPosition == nil then
		return false
	elseif self.fillType == nil then
		return false
	elseif self.loadingStation == nil then
		return false
	elseif self.unloadingStation == nil then
		return false
	else
		self.description = string.format("Load '%s' from '%s' and deliver to '%s' with '%s'", g_fillTypeManager:getFillTypeTitleByIndex(self.fillType), self.loadingStation:getName(), self.unloadingStation:getName(), self.vehicleSetup.name)
		self.descriptionShort = string.format("Load/Deliver %s-%s", self.loadingStation:getName(), self.unloadingStation:getName())
		return true
	end
end
function GameTestCaseAILoadAndDeliver:saveToXMLFile(xmlFile, key)
	GameTestCaseAILoadAndDeliver:superClass().saveToXMLFile(self, xmlFile, key)
	GameTestCaseAI.saveVehicleSetup(self.vehicleSetup, xmlFile, key .. ".vehicleSetup")
	GameTestCaseAI.savePosition(self.spawnPosition, xmlFile, key .. ".spawnPosition")
	xmlFile:setString(key .. "#filType", g_fillTypeManager:getFillTypeNameByIndex(self.fillType))
	GameTestCaseAI.savePlaceable(self.loadingStation.owningPlaceable, xmlFile, key .. ".loadingStation")
	GameTestCaseAI.savePlaceable(self.unloadingStation.owningPlaceable, xmlFile, key .. ".unloadingStation")
end
function GameTestCaseAILoadAndDeliver.generateTestCaseFromConfig(xmlFile, key)
	local vehicleSetup = GameTestCaseAI.loadVehicleSetup(xmlFile, key .. ".vehicleSetup")
	if vehicleSetup == nil then
		Logging.xmlError(xmlFile, "Unknown vehicle setup")
		return nil
	end
	local spawnPosition = GameTestCaseAI.loadPosition(xmlFile, key .. ".spawnPosition")
	if spawnPosition == nil then
		Logging.xmlError(xmlFile, "Unknown spawn position")
		return nil
	end
	local fillType = nil
	local filTypeStr = xmlFile:getString(key .. "#filType")
	if filTypeStr ~= nil then
		fillType = g_fillTypeManager:getFillTypeIndexByName(filTypeStr)
	end
	if fillType == nil then
		Logging.xmlError(xmlFile, "Unknown fill type")
		return nil
	else
		local loadingStationPlaceable = GameTestCaseAI.loadPlaceable(xmlFile, key .. ".loadingStation")
		local unloadingStationPlaceable = GameTestCaseAI.loadPlaceable(xmlFile, key .. ".unloadingStation")
		if loadingStationPlaceable ~= nil and unloadingStationPlaceable ~= nil then
			local loadingUnloadingCombinations = GameTestCaseAILoadAndDeliver.loadUnloadingLoadingStationCombinations()
			for i = 1, #loadingUnloadingCombinations do
				local combination = loadingUnloadingCombinations[i]
				if combination.fillType == fillType and (combination.loadingStation.owningPlaceable == loadingStationPlaceable and combination.unloadingStation.owningPlaceable == unloadingStationPlaceable) then
					local case = GameTestCaseAILoadAndDeliver.new()
					case:setVehicleSetup(vehicleSetup)
					case:setSpawnPosition(spawnPosition)
					case:setFillType(combination.fillType)
					case:setStations(combination.loadingStation, combination.unloadingStation)
					if case:finalize() then
						case:print("Loaded test case from XML. (%s)", case:getDescription())
						return case
					end
				end
			end
		end
		Logging.xmlError(xmlFile, "Unable to find loading/unloading station combination")
		return nil
	end
end
function GameTestCaseAILoadAndDeliver:start(finishedCallback)
	GameTestCaseAILoadAndDeliver:superClass().start(self, finishedCallback)
	self.testTask = GameTestTaskAILoadAndDeliver.new(self)
	self.testTask:setData(self.vehicleSetup, self.spawnPosition, self.fillType, self.unloadingStation, self.loadingStation)
	self.testTask:start(function(result, reason)
		self:onFinished(result, reason, finishedCallback)
	end)
end
function GameTestCaseAILoadAndDeliver.loadUnloadingLoadingStationCombinations()
	local loadingUnloadingCombinations = {}
	for _, loadingStation in pairs(g_currentMission.storageSystem:getLoadingStations()) do
		local x, _, _, _, _ = loadingStation:getAITargetPositionAndDirection(FillType.UNKNOWN)
		if x == nil then
			continue
		end
		local loadFillTypes = loadingStation:getAISupportedFillTypes()
		for loadFillTypeIndex, state in pairs(loadFillTypes) do
			x, _, _, _, _ = loadingStation:getAITargetPositionAndDirection(loadFillTypeIndex)
			if state then
				if x == nil then
					continue
				end
				for _, unloadingStation in pairs(g_currentMission.storageSystem:getUnloadingStations()) do
					if unloadingStation:isa(UnloadingStation) then
						if loadingStation.owningPlaceable == unloadingStation.owningPlaceable then
							continue
						end
						x, _, _, _, _ = unloadingStation:getAITargetPositionAndDirection(loadFillTypeIndex)
						if x == nil then
							continue
						end
						local unloadFillTypes = unloadingStation:getAISupportedFillTypes()
						for unloadFillTypeIndex, _state in pairs(unloadFillTypes) do
							if _state and loadFillTypeIndex == unloadFillTypeIndex then
								local alreadyAdded = false
								for i = 1, #loadingUnloadingCombinations do
									local combination = loadingUnloadingCombinations[i]
									if combination.loadingStation == loadingStation and combination.unloadingStation == unloadingStation then
										alreadyAdded = true
										break
									end
								end
								if alreadyAdded then
									continue
								end
								table.insert(loadingUnloadingCombinations, { loadingStation = loadingStation, unloadingStation = unloadingStation, fillType = loadFillTypeIndex })
							end
						end
					end
				end
			end
		end
	end
	table.sort(loadingUnloadingCombinations, function(a, b)
		local strA = a.loadingStation.owningPlaceable.configFileName .. a.unloadingStation.owningPlaceable.configFileName .. a.fillType
		local strB = b.loadingStation.owningPlaceable.configFileName .. b.unloadingStation.owningPlaceable.configFileName .. b.fillType
		return strB < strA
	end)
	return loadingUnloadingCombinations
end
function GameTestCaseAILoadAndDeliver.generateTestCases(targetTable, xmlFile, key)
	local spawnPositions = GameTestCaseAI.loadSpawnPositions(xmlFile, key)
	local vehicleSetups = GameTestCaseAI.loadVehicleSetups(xmlFile, key)
	local loadingUnloadingCombinations = GameTestCaseAILoadAndDeliver.loadUnloadingLoadingStationCombinations()
	for i = 1, #loadingUnloadingCombinations do
		local combination = loadingUnloadingCombinations[i]
		for s = 1, #spawnPositions do
			for v = 1, #vehicleSetups do
				local vehicleSetup = vehicleSetups[v]
				local canLoadFillType = false
				for vi = 1, #vehicleSetup.vehicles do
					local vehicle = vehicleSetup.vehicles[vi]
					if vehicle.fillTypes == nil then
						continue
					end
					for fi = 1, #vehicle.fillTypes do
						local vehicleLoadFillTypeIndex = vehicle.fillTypes[fi]
						if vehicleLoadFillTypeIndex == combination.fillType then
							canLoadFillType = true
							break
						end
					end
				end
				if canLoadFillType then
					local case = GameTestCaseAILoadAndDeliver.new()
					case:setVehicleSetup(vehicleSetups[v])
					case:setSpawnPosition(spawnPositions[s])
					case:setFillType(combination.fillType)
					case:setStations(combination.loadingStation, combination.unloadingStation)
					if case:finalize() then
						case:print("Found test case. (%s)", case:getDescription())
						table.insert(targetTable, case)
					end
				end
			end
		end
	end
end
function GameTestCaseAILoadAndDeliver.registerXMLPaths(schema, baseKey) end
GameTestManager.registerTestCase(GameTestCaseAILoadAndDeliver)
