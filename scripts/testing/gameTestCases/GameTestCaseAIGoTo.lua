-- Local values: GameTestCaseAIGoTo_mt
GameTestCaseAIGoTo = {}
local GameTestCaseAIGoTo_mt = Class(GameTestCaseAIGoTo, GameTestCaseAI)

-- Upvalues: GameTestCaseAIGoTo_mt
-- Local values: self
function GameTestCaseAIGoTo.new(customMt)
	-- upvalues: (copy) GameTestCaseAIGoTo_mt
	local v3_ = GameTestCaseAI.new(customMt or GameTestCaseAIGoTo_mt)
	v3_.vehicleSetup = nil
	v3_.spawnPosition = nil
	v3_.targetPosition = nil
	return v3_
end

function GameTestCaseAIGoTo:setVehicleSetup(vehicleSetup)
	self.vehicleSetup = vehicleSetup
end

function GameTestCaseAIGoTo:setSpawnPosition(spawnPosition)
	self.spawnPosition = spawnPosition
end

function GameTestCaseAIGoTo:setTargetPosition(targetPosition)
	self.targetPosition = targetPosition
end

function GameTestCaseAIGoTo:finalize()
	if self.vehicleSetup == nil then
		return false
	end
	if self.spawnPosition == nil then
		return false
	end
	if self.targetPosition == nil then
		return false
	end
	self.description = string.format("Go from \'%s\' to \'%s\' with \'%s\'", self.spawnPosition.name, self.targetPosition.name, self.vehicleSetup.name)
	self.descriptionShort = string.format("GoTo %s-%s", self.spawnPosition.name, self.targetPosition.name)
	return true
end

function GameTestCaseAIGoTo:saveToXMLFile(xmlFile, key)
	GameTestCaseAIGoTo:superClass().saveToXMLFile(self, xmlFile, key)
	GameTestCaseAI.saveVehicleSetup(self.vehicleSetup, xmlFile, key .. ".vehicleSetup")
	GameTestCaseAI.savePosition(self.spawnPosition, xmlFile, key .. ".spawnPosition")
	GameTestCaseAI.savePosition(self.targetPosition, xmlFile, key .. ".targetPosition")
end

-- Local values: vehicleSetup, spawnPosition, targetPosition, case
function GameTestCaseAIGoTo.generateTestCaseFromConfig(xmlFile, key)
	local v16_ = GameTestCaseAI.loadVehicleSetup(xmlFile, key .. ".vehicleSetup")
	if v16_ == nil then
		Logging.xmlError(xmlFile, "Unknown vehicle setup")
		return nil
	end
	local v17_ = GameTestCaseAI.loadPosition(xmlFile, key .. ".spawnPosition")
	if v17_ == nil then
		Logging.xmlError(xmlFile, "Unknown spawn position")
		return nil
	end
	local v18_ = GameTestCaseAI.loadPosition(xmlFile, key .. ".targetPosition")
	if v18_ == nil then
		Logging.xmlError(xmlFile, "Unknown target position")
		return nil
	end
	local v19_ = GameTestCaseAIGoTo.new()
	v19_:setVehicleSetup(v16_)
	v19_:setSpawnPosition(v17_)
	v19_:setTargetPosition(v18_)
	if not v19_:finalize() then
		return nil
	end
	v19_:print("Found test case. (%s)", v19_:getDescription())
	return v19_
end

function GameTestCaseAIGoTo:start(finishedCallback)
	GameTestCaseAIGoTo:superClass().start(self, finishedCallback)
	self.testTask = GameTestTaskAIGoTo.new(self)
	self.testTask:setData(self.vehicleSetup, self.spawnPosition, self.targetPosition)
	self.testTask:start(function(p22_, p23_)
		-- upvalues: (copy) self, (copy) finishedCallback
		self:onFinished(p22_, p23_, finishedCallback)
	end)
end

-- Local values: spawnPositions, vehicleSetups, s, t, v, case
function GameTestCaseAIGoTo.generateTestCases(targetTable, xmlFile, key)
	local v27_ = GameTestCaseAI.loadSpawnPositions(xmlFile, key)
	local v28_ = GameTestCaseAI.loadVehicleSetups(xmlFile, key)
	for v29_ = 1, #v27_ do
		for v30_ = 1, #v27_ do
			if v29_ ~= v30_ then
				for v31_ = 1, #v28_ do
					local v32_ = GameTestCaseAIGoTo.new()
					v32_:setVehicleSetup(v28_[v31_])
					v32_:setSpawnPosition(v27_[v29_])
					v32_:setTargetPosition(v27_[v30_])
					if v32_:finalize() then
						v32_:print("Found test case. (%s)", v32_:getDescription())
						table.insert(targetTable, v32_)
					end
				end
			end
		end
	end
end

function GameTestCaseAIGoTo.registerXMLPaths(schema, baseKey) end
GameTestManager.registerTestCase(GameTestCaseAIGoTo)
