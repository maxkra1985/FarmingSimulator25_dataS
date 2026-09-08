-- Local values: GameTestCaseAILoadAndDeliver_mt
GameTestCaseAILoadAndDeliver = {}
local GameTestCaseAILoadAndDeliver_mt = Class(GameTestCaseAILoadAndDeliver, GameTestCaseAI)

-- Upvalues: GameTestCaseAILoadAndDeliver_mt
-- Local values: self
function GameTestCaseAILoadAndDeliver.new(customMt)
	-- upvalues: (copy) GameTestCaseAILoadAndDeliver_mt
	local v3_ = GameTestCaseAI.new(customMt or GameTestCaseAILoadAndDeliver_mt)
	v3_.vehicleSetup = nil
	v3_.spawnPosition = nil
	v3_.fillType = nil
	v3_.loadingStation = nil
	v3_.unloadingStation = nil
	return v3_
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
	end
	if self.spawnPosition == nil then
		return false
	end
	if self.fillType == nil then
		return false
	end
	if self.loadingStation == nil then
		return false
	end
	if self.unloadingStation == nil then
		return false
	end
	self.description = string.format("Load \'%s\' from \'%s\' and deliver to \'%s\' with \'%s\'", g_fillTypeManager:getFillTypeTitleByIndex(self.fillType), self.loadingStation:getName(), self.unloadingStation:getName(), self.vehicleSetup.name)
	self.descriptionShort = string.format("Load/Deliver %s-%s", self.loadingStation:getName(), self.unloadingStation:getName())
	return true
end

function GameTestCaseAILoadAndDeliver:saveToXMLFile(xmlFile, key)
	GameTestCaseAILoadAndDeliver:superClass().saveToXMLFile(self, xmlFile, key)
	GameTestCaseAI.saveVehicleSetup(self.vehicleSetup, xmlFile, key .. ".vehicleSetup")
	GameTestCaseAI.savePosition(self.spawnPosition, xmlFile, key .. ".spawnPosition")
	xmlFile:setString(key .. "#filType", g_fillTypeManager:getFillTypeNameByIndex(self.fillType))
	GameTestCaseAI.savePlaceable(self.loadingStation.owningPlaceable, xmlFile, key .. ".loadingStation")
	GameTestCaseAI.savePlaceable(self.unloadingStation.owningPlaceable, xmlFile, key .. ".unloadingStation")
end

-- Local values: vehicleSetup, spawnPosition, fillType, filTypeStr, loadingStationPlaceable, unloadingStationPlaceable, loadingUnloadingCombinations, i, combination, case
function GameTestCaseAILoadAndDeliver.generateTestCaseFromConfig(xmlFile, key)
	local v19_ = GameTestCaseAI.loadVehicleSetup(xmlFile, key .. ".vehicleSetup")
	if v19_ == nil then
		Logging.xmlError(xmlFile, "Unknown vehicle setup")
		return nil
	end
	local v20_ = GameTestCaseAI.loadPosition(xmlFile, key .. ".spawnPosition")
	if v20_ == nil then
		Logging.xmlError(xmlFile, "Unknown spawn position")
		return nil
	end
	local v21_ = xmlFile:getString(key .. "#filType")
	local v22_
	if v21_ == nil then
		v22_ = nil
	else
		v22_ = g_fillTypeManager:getFillTypeIndexByName(v21_)
	end
	if v22_ == nil then
		Logging.xmlError(xmlFile, "Unknown fill type")
		return nil
	end
	local v23_ = GameTestCaseAI.loadPlaceable(xmlFile, key .. ".loadingStation")
	local v24_ = GameTestCaseAI.loadPlaceable(xmlFile, key .. ".unloadingStation")
	if v23_ ~= nil and v24_ ~= nil then
		local v25_ = GameTestCaseAILoadAndDeliver.loadUnloadingLoadingStationCombinations()
		for v26_ = 1, #v25_ do
			local v27_ = v25_[v26_]
			if v27_.fillType == v22_ and (v27_.loadingStation.owningPlaceable == v23_ and v27_.unloadingStation.owningPlaceable == v24_) then
				local v28_ = GameTestCaseAILoadAndDeliver.new()
				v28_:setVehicleSetup(v19_)
				v28_:setSpawnPosition(v20_)
				v28_:setFillType(v27_.fillType)
				v28_:setStations(v27_.loadingStation, v27_.unloadingStation)
				if v28_:finalize() then
					v28_:print("Loaded test case from XML. (%s)", v28_:getDescription())
					return v28_
				end
			end
		end
	end
	Logging.xmlError(xmlFile, "Unable to find loading/unloading station combination")
	return nil
end

function GameTestCaseAILoadAndDeliver:start(finishedCallback)
	GameTestCaseAILoadAndDeliver:superClass().start(self, finishedCallback)
	self.testTask = GameTestTaskAILoadAndDeliver.new(self)
	self.testTask:setData(self.vehicleSetup, self.spawnPosition, self.fillType, self.unloadingStation, self.loadingStation)
	self.testTask:start(function(p31_, p32_)
		-- upvalues: (copy) self, (copy) finishedCallback
		self:onFinished(p31_, p32_, finishedCallback)
	end)
end
function GameTestCaseAILoadAndDeliver.loadUnloadingLoadingStationCombinations()
	local v33_ = {}
	for _, v34_ in pairs(g_currentMission.storageSystem:getLoadingStations()) do
		local v35_, _, _, _, _ = v34_:getAITargetPositionAndDirection(FillType.UNKNOWN)
		if v35_ ~= nil then
			local v36_ = v34_:getAISupportedFillTypes()
			for v37_, v38_ in pairs(v36_) do
				local v39_, _, _, _, _ = v34_:getAITargetPositionAndDirection(v37_)
				if v38_ and v39_ ~= nil then
					for _, v40_ in pairs(g_currentMission.storageSystem:getUnloadingStations()) do
						if v40_:isa(UnloadingStation) and v34_.owningPlaceable ~= v40_.owningPlaceable then
							local v41_, _, _, _, _ = v40_:getAITargetPositionAndDirection(v37_)
							if v41_ ~= nil then
								local v42_ = v40_:getAISupportedFillTypes()
								for v43_, v44_ in pairs(v42_) do
									if v44_ and v37_ == v43_ then
										local v45_ = false
										for v46_ = 1, #v33_ do
											local v47_ = v33_[v46_]
											if v47_.loadingStation == v34_ and v47_.unloadingStation == v40_ then
												v45_ = true
												break
											end
										end
										if not v45_ then
											table.insert(v33_, {
												["loadingStation"] = v34_,
												["unloadingStation"] = v40_,
												["fillType"] = v37_
											})
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
	table.sort(v33_, function(p48_, p49_)
		return p48_.loadingStation.owningPlaceable.configFileName .. p48_.unloadingStation.owningPlaceable.configFileName .. p48_.fillType > p49_.loadingStation.owningPlaceable.configFileName .. p49_.unloadingStation.owningPlaceable.configFileName .. p49_.fillType
	end)
	return v33_
end

-- Local values: spawnPositions, vehicleSetups, loadingUnloadingCombinations, i, combination, s, v, vehicleSetup, canLoadFillType, vi, vehicle, fi, vehicleLoadFillTypeIndex, case
function GameTestCaseAILoadAndDeliver.generateTestCases(targetTable, xmlFile, key)
	local v53_ = GameTestCaseAI.loadSpawnPositions(xmlFile, key)
	local v54_ = GameTestCaseAI.loadVehicleSetups(xmlFile, key)
	local v55_ = GameTestCaseAILoadAndDeliver.loadUnloadingLoadingStationCombinations()
	for v56_ = 1, #v55_ do
		local v57_ = v55_[v56_]
		for v58_ = 1, #v53_ do
			for v59_ = 1, #v54_ do
				local v60_ = v54_[v59_]
				local v61_ = false
				for v62_ = 1, #v60_.vehicles do
					local v63_ = v60_.vehicles[v62_]
					if v63_.fillTypes ~= nil then
						for v64_ = 1, #v63_.fillTypes do
							if v63_.fillTypes[v64_] == v57_.fillType then
								v61_ = true
								break
							end
						end
					end
				end
				if v61_ then
					local v65_ = GameTestCaseAILoadAndDeliver.new()
					v65_:setVehicleSetup(v54_[v59_])
					v65_:setSpawnPosition(v53_[v58_])
					v65_:setFillType(v57_.fillType)
					v65_:setStations(v57_.loadingStation, v57_.unloadingStation)
					if v65_:finalize() then
						v65_:print("Found test case. (%s)", v65_:getDescription())
						table.insert(targetTable, v65_)
					end
				end
			end
		end
	end
end

function GameTestCaseAILoadAndDeliver.registerXMLPaths(schema, baseKey) end
GameTestManager.registerTestCase(GameTestCaseAILoadAndDeliver)
