-- Local values: GameTestCaseAIDeliver_mt
GameTestCaseAIDeliver = {}
local GameTestCaseAIDeliver_mt = Class(GameTestCaseAIDeliver, GameTestCaseAI)

-- Upvalues: GameTestCaseAIDeliver_mt
-- Local values: self
function GameTestCaseAIDeliver.new(customMt)
	-- upvalues: (copy) GameTestCaseAIDeliver_mt
	local v3_ = GameTestCaseAI.new(customMt or GameTestCaseAIDeliver_mt)
	v3_.vehicleSetup = nil
	v3_.spawnPosition = nil
	v3_.fillType = nil
	v3_.unloadingStation = nil
	return v3_
end

function GameTestCaseAIDeliver:setVehicleSetup(vehicleSetup)
	self.vehicleSetup = vehicleSetup
end

function GameTestCaseAIDeliver:setSpawnPosition(spawnPosition)
	self.spawnPosition = spawnPosition
end

function GameTestCaseAIDeliver:setFillType(fillType)
	self.fillType = fillType
end

function GameTestCaseAIDeliver:setStations(unloadingStation)
	self.unloadingStation = unloadingStation
end

function GameTestCaseAIDeliver:finalize()
	if self.vehicleSetup == nil then
		return false
	end
	if self.spawnPosition == nil then
		return false
	end
	if self.fillType == nil then
		return false
	end
	if self.unloadingStation == nil then
		return false
	end
	self.description = string.format("Deliver \'%s\' from \'%s\' to \'%s\' with \'%s\'", g_fillTypeManager:getFillTypeTitleByIndex(self.fillType), self.spawnPosition.name, self.unloadingStation:getName(), self.vehicleSetup.name)
	self.descriptionShort = string.format("Deliver to %s", self.unloadingStation:getName())
	return true
end

function GameTestCaseAIDeliver:saveToXMLFile(xmlFile, key)
	GameTestCaseAIDeliver:superClass().saveToXMLFile(self, xmlFile, key)
	GameTestCaseAI.saveVehicleSetup(self.vehicleSetup, xmlFile, key .. ".vehicleSetup")
	GameTestCaseAI.savePosition(self.spawnPosition, xmlFile, key .. ".spawnPosition")
	xmlFile:setString(key .. "#filType", g_fillTypeManager:getFillTypeNameByIndex(self.fillType))
	GameTestCaseAI.savePlaceable(self.unloadingStation.owningPlaceable, xmlFile, key .. ".unloadingStation")
end

-- Local values: vehicleSetup, spawnPosition, fillType, filTypeStr, unloadingStationPlaceable, unloadingStations, i, unloadingStationData, case
function GameTestCaseAIDeliver.generateTestCaseFromConfig(xmlFile, key)
	local v18_ = GameTestCaseAI.loadVehicleSetup(xmlFile, key .. ".vehicleSetup")
	if v18_ == nil then
		Logging.xmlError(xmlFile, "Unknown vehicle setup")
		return nil
	end
	local v19_ = GameTestCaseAI.loadPosition(xmlFile, key .. ".spawnPosition")
	if v19_ == nil then
		Logging.xmlError(xmlFile, "Unknown spawn position")
		return nil
	end
	local v20_ = xmlFile:getString(key .. "#filType")
	local v21_
	if v20_ == nil then
		v21_ = nil
	else
		v21_ = g_fillTypeManager:getFillTypeIndexByName(v20_)
	end
	if v21_ == nil then
		Logging.xmlError(xmlFile, "Unknown fill type")
		return nil
	end
	local v22_ = GameTestCaseAI.loadPlaceable(xmlFile, key .. ".unloadingStation")
	if v22_ ~= nil then
		local v23_ = GameTestCaseAIDeliver.loadUnloadingStations()
		for v24_ = 1, #v23_ do
			local v25_ = v23_[v24_]
			if v25_.fillType == v21_ and v25_.unloadingStation.owningPlaceable == v22_ then
				local v26_ = GameTestCaseAIDeliver.new()
				v26_:setVehicleSetup(v18_)
				v26_:setSpawnPosition(v19_)
				v26_:setFillType(v25_.fillType)
				v26_:setStations(v25_.unloadingStation)
				if v26_:finalize() then
					v26_:print("Loaded test case from XML. (%s)", v26_:getDescription())
					return v26_
				end
			end
		end
	end
	Logging.xmlError(xmlFile, "Unable to find unloading station")
	return nil
end

function GameTestCaseAIDeliver:start(finishedCallback)
	GameTestCaseAIDeliver:superClass().start(self, finishedCallback)
	self.testTask = GameTestTaskAIDeliver.new(self)
	self.testTask:setData(self.vehicleSetup, self.spawnPosition, self.fillType, self.unloadingStation)
	self.testTask:start(function(p29_, p30_)
		-- upvalues: (copy) self, (copy) finishedCallback
		self:onFinished(p29_, p30_, finishedCallback)
	end)
end
function GameTestCaseAIDeliver.loadUnloadingStations()
	local v31_ = {}
	for _, v32_ in pairs(g_currentMission.storageSystem:getUnloadingStations()) do
		if v32_:isa(UnloadingStation) then
			local v33_, _, _, _, _ = v32_:getAITargetPositionAndDirection(FillType.UNKNOWN)
			if v33_ ~= nil then
				local v34_ = v32_:getAISupportedFillTypes()
				for v35_, v36_ in pairs(v34_) do
					if v36_ then
						local v37_, _, _, _, _ = v32_:getAITargetPositionAndDirection(v35_)
						if v37_ ~= nil then
							table.insert(v31_, {
								["unloadingStation"] = v32_,
								["fillType"] = v35_
							})
							break
						end
					end
				end
			end
		end
	end
	return v31_
end

-- Local values: spawnPositions, vehicleSetups, unloadingStations, i, unloadingStationData, s, v, vehicleSetup, canLoadFillType, vi, vehicle, fi, vehicleLoadFillTypeIndex, case
function GameTestCaseAIDeliver.generateTestCases(targetTable, xmlFile, key)
	local v41_ = GameTestCaseAI.loadSpawnPositions(xmlFile, key)
	local v42_ = GameTestCaseAI.loadVehicleSetups(xmlFile, key)
	local v43_ = GameTestCaseAIDeliver.loadUnloadingStations()
	for v44_ = 1, #v43_ do
		local v45_ = v43_[v44_]
		for v46_ = 1, #v41_ do
			for v47_ = 1, #v42_ do
				local v48_ = v42_[v47_]
				local v49_ = false
				for v50_ = 1, #v48_.vehicles do
					local v51_ = v48_.vehicles[v50_]
					if v51_.fillTypes ~= nil then
						for v52_ = 1, #v51_.fillTypes do
							if v51_.fillTypes[v52_] == v45_.fillType then
								v49_ = true
								break
							end
						end
					end
				end
				if v49_ then
					local v53_ = GameTestCaseAIDeliver.new()
					v53_:setVehicleSetup(v42_[v47_])
					v53_:setSpawnPosition(v41_[v46_])
					v53_:setFillType(v45_.fillType)
					v53_:setStations(v45_.unloadingStation)
					if v53_:finalize() then
						v53_:print("Found test case. (%s)", v53_:getDescription())
						table.insert(targetTable, v53_)
					end
				end
			end
		end
	end
end

function GameTestCaseAIDeliver.registerXMLPaths(schema, baseKey) end
GameTestManager.registerTestCase(GameTestCaseAIDeliver)
