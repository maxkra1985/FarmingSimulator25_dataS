-- Local values: GameTestCaseAIFieldWork_mt
GameTestCaseAIFieldWork = {}
GameTestCaseAIFieldWork.WORK_TYPE = {}
GameTestCaseAIFieldWork.WORK_TYPE.CULTIVATION = 1
GameTestCaseAIFieldWork.WORK_TYPE.SOWING = 2
GameTestCaseAIFieldWork.WORK_TYPE.COMBINE_HARVESTER = 3
GameTestCaseAIFieldWork.WORK_TYPE.SPRAYING = 4
GameTestCaseAIFieldWork.WORK_TYPE.MOWING = 5
GameTestCaseAIFieldWork.WORK_TYPE.PLOWING = 6
Enum(GameTestCaseAIFieldWork.WORK_TYPE)
GameTestCaseAIFieldWork.WORK_TYPE_TO_NAME = {}
GameTestCaseAIFieldWork.WORK_TYPE_TO_NAME[GameTestCaseAIFieldWork.WORK_TYPE.CULTIVATION] = "Cultivation"
GameTestCaseAIFieldWork.WORK_TYPE_TO_NAME[GameTestCaseAIFieldWork.WORK_TYPE.SOWING] = "Sowing"
GameTestCaseAIFieldWork.WORK_TYPE_TO_NAME[GameTestCaseAIFieldWork.WORK_TYPE.COMBINE_HARVESTER] = "Combine Harvester"
GameTestCaseAIFieldWork.WORK_TYPE_TO_NAME[GameTestCaseAIFieldWork.WORK_TYPE.SPRAYING] = "Spraying"
GameTestCaseAIFieldWork.WORK_TYPE_TO_NAME[GameTestCaseAIFieldWork.WORK_TYPE.MOWING] = "Mowing"
GameTestCaseAIFieldWork.WORK_TYPE_TO_NAME[GameTestCaseAIFieldWork.WORK_TYPE.PLOWING] = "Plowing"
local GameTestCaseAIFieldWork_mt = Class(GameTestCaseAIFieldWork, GameTestCaseAI)

-- Upvalues: GameTestCaseAIFieldWork_mt
-- Local values: self
function GameTestCaseAIFieldWork.new(customMt)
	-- upvalues: (copy) GameTestCaseAIFieldWork_mt
	local v3_ = GameTestCaseAI.new(customMt or GameTestCaseAIFieldWork_mt)
	v3_.vehicleSetup = nil
	v3_.spawnPosition = nil
	v3_.workType = nil
	v3_.fruitTypeIndex = nil
	v3_.minFieldPercentage = 0.95
	v3_.maxLeftOverArea = 100
	return v3_
end

function GameTestCaseAIFieldWork:setVehicleSetup(vehicleSetup)
	self.vehicleSetup = vehicleSetup
end

function GameTestCaseAIFieldWork:setSpawnPosition(spawnPosition)
	self.spawnPosition = spawnPosition
end

function GameTestCaseAIFieldWork:setWorkType(workType)
	self.workType = workType
end

function GameTestCaseAIFieldWork:setFruitTypeIndex(fruitTypeIndex)
	self.fruitTypeIndex = fruitTypeIndex
end

function GameTestCaseAIFieldWork:setSegments(segments)
	self.segments = segments
end

function GameTestCaseAIFieldWork:setSegmentStartIndex(segmentStartIndex)
	self.segmentStartIndex = segmentStartIndex
end

function GameTestCaseAIFieldWork:setGoals(minFieldPercentage, maxLeftOverArea)
	self.minFieldPercentage = minFieldPercentage or self.minFieldPercentage
	self.maxLeftOverArea = maxLeftOverArea or self.maxLeftOverArea
end

-- Local values: workName
function GameTestCaseAIFieldWork:finalize()
	if self.vehicleSetup == nil then
		return false
	end
	if self.spawnPosition == nil then
		return false
	end
	if self.workType == nil then
		return false
	end
	local v20_ = GameTestCaseAIFieldWork.WORK_TYPE_TO_NAME[self.workType]
	self.description = string.format("%s on \'%s\' with \'%s\'", v20_, self.spawnPosition.name, self.vehicleSetup.name)
	self.descriptionShort = string.format("%s on %s", v20_, self.spawnPosition.name)
	return true
end

function GameTestCaseAIFieldWork:saveToXMLFile(xmlFile, key)
	GameTestCaseAIFieldWork:superClass().saveToXMLFile(self, xmlFile, key)
	GameTestCaseAI.saveVehicleSetup(self.vehicleSetup, xmlFile, key .. ".vehicleSetup")
	GameTestCaseAI.savePosition(self.spawnPosition, xmlFile, key .. ".spawnPosition")
	GameTestCaseAIFieldWork.saveSegments(self.segments, xmlFile, key)
	xmlFile:setString(key .. "#workType", GameTestCaseAIFieldWork.WORK_TYPE.getName(self.workType))
	if self.fruitTypeIndex ~= nil then
		xmlFile:setString(key .. "#fruitType", g_fruitTypeManager:getFruitTypeNameByIndex(self.fruitTypeIndex))
	end
	xmlFile:setFloat(key .. ".goals#minFieldPercentage", self.minFieldPercentage)
	xmlFile:setFloat(key .. ".goals#maxLeftOverArea", self.maxLeftOverArea)
end

-- Local values: vehicleSetup, spawnPosition, workType, workTypeStr, fruitTypeIndex, fruitTypeStr, minFieldPercentage, maxLeftOverArea, case
function GameTestCaseAIFieldWork.generateTestCaseFromConfig(xmlFile, key)
	local v26_ = GameTestCaseAI.loadVehicleSetup(xmlFile, key .. ".vehicleSetup")
	if v26_ == nil then
		Logging.xmlError(xmlFile, "Unknown vehicle setup")
		return nil
	end
	local v27_ = GameTestCaseAI.loadPosition(xmlFile, key .. ".spawnPosition")
	if v27_ == nil then
		Logging.xmlError(xmlFile, "Unknown spawn position")
		return nil
	end
	local v28_ = xmlFile:getString(key .. "#workType")
	local v29_
	if v28_ == nil then
		v29_ = nil
	else
		v29_ = GameTestCaseAIFieldWork.WORK_TYPE[string.upper(v28_)]
	end
	if v29_ == nil then
		Logging.xmlError(xmlFile, "Unknown work type")
		return nil
	end
	local v30_ = xmlFile:getString(key .. "#fruitType")
	local v31_
	if v30_ == nil then
		v31_ = nil
	else
		v31_ = g_fruitTypeManager:getFruitTypeIndexByName(v30_)
	end
	local v32_ = xmlFile:getFloat(key .. ".goals#minFieldPercentage")
	local v33_ = xmlFile:getFloat(key .. ".goals#maxLeftOverArea")
	local v34_ = GameTestCaseAIFieldWork.new()
	v34_:setVehicleSetup(v26_)
	v34_:setSpawnPosition(v27_)
	v34_:setWorkType(v29_)
	v34_:setFruitTypeIndex(v31_)
	v34_:setGoals(v32_, v33_)
	if StartParams.getIsSet("gameTestCaseSegmentIndex") then
		v34_:setSegments(GameTestCaseAIFieldWork.loadSegments(xmlFile, key))
		v34_:setSegmentStartIndex(StartParams.getValue("gameTestCaseSegmentIndex"))
	end
	if not v34_:finalize() then
		return nil
	end
	v34_:print("Loaded test case from XML. (%s)", v34_:getDescription())
	return v34_
end

function GameTestCaseAIFieldWork:start(finishedCallback)
	GameTestCaseAIFieldWork:superClass().start(self, finishedCallback)
	self.testTask = GameTestTaskAIFieldWork.new(self)
	self.testTask:setData(self.vehicleSetup, self.spawnPosition, self.workType, self.fruitTypeIndex, self.segments, self.segmentStartIndex, self.minFieldPercentage, self.maxLeftOverArea)
	self.testTask:start(function(p37_, p38_)
		-- upvalues: (copy) self, (copy) finishedCallback
		self.descriptionShort = self.descriptionShort .. string.format(" (%.2f%%)", self.testTask.fieldAreaSuccessPct * 100)
		self:onFinished(p37_, p38_, finishedCallback)
	end)
end

-- Local values: spawnPositions, vehicleSetups, workTypeStr, workType, minFieldPercentage, maxLeftOverArea, fruitTypeIndex, fruitTypeStr, s, v, case
function GameTestCaseAIFieldWork.generateTestCases(targetTable, xmlFile, key)
	local v42_ = GameTestCaseAI.loadSpawnPositions(xmlFile, key)
	local v43_ = GameTestCaseAI.loadVehicleSetups(xmlFile, key)
	local v44_ = xmlFile:getString(key .. "#workType")
	if v44_ ~= nil then
		local v45_ = GameTestCaseAIFieldWork.WORK_TYPE[string.upper(v44_)]
		if v45_ ~= nil then
			local v46_ = xmlFile:getFloat(key .. ".goals#minFieldPercentage")
			local v47_ = xmlFile:getFloat(key .. ".goals#maxLeftOverArea")
			local v48_ = xmlFile:getString(key .. "#fruitType")
			local v49_
			if v48_ == nil then
				v49_ = nil
			else
				v49_ = g_fruitTypeManager:getFruitTypeIndexByName(v48_)
			end
			for v50_ = 1, #v42_ do
				for v51_ = 1, #v43_ do
					local v52_ = GameTestCaseAIFieldWork.new()
					v52_:setVehicleSetup(v43_[v51_])
					v52_:setSpawnPosition(v42_[v50_])
					v52_:setWorkType(v45_)
					v52_:setFruitTypeIndex(v49_)
					v52_:setGoals(v46_, v47_)
					if v52_:finalize() then
						v52_:print("Found test case. (%s)", v52_:getDescription())
						table.insert(targetTable, v52_)
					end
				end
			end
		end
	end
end

-- Local values: segments, index, segmentKey, segment, _, positionKey, value
function GameTestCaseAIFieldWork.loadSegments(xmlFile, key)
	local v55_ = not xmlFile:hasProperty(key .. ".segments") and "testCaseReport.aiFieldWorker" or key
	local v56_ = {}
	for v57_, v58_ in xmlFile:iterator(v55_ .. ".segments.segment") do
		local v59_ = {
			["index"] = v57_,
			["isTurn"] = xmlFile:getBool(v55_ .. "#isTurn", false),
			["isHeadlandSegment"] = xmlFile:getBool(v55_ .. "#isHeadlandSegment", false),
			["isIslandSegment"] = xmlFile:getBool(v55_ .. "#isIslandSegment", false),
			["length"] = xmlFile:getBool(v55_ .. "#length", 0),
			["positions"] = {}
		}
		for _, v60_ in xmlFile:iterator(v58_ .. ".position") do
			local v61_ = xmlFile:getVector(v60_ .. "#value")
			local v62_ = v59_.positions
			table.insert(v62_, v61_)
		end
		table.insert(v56_, v59_)
	end
	return v56_
end

-- Local values: index, segment, segmentsKey, positionIndex, position, translationKey
function GameTestCaseAIFieldWork.saveSegments(segments, xmlFile, key)
	if segments ~= nil then
		for v66_, v67_ in ipairs(segments) do
			local v68_ = string.format("%s.segments.segment(%d)", key, v66_ - 1)
			xmlFile:setBool(v68_ .. "#isTurn", Utils.getNoNil(v67_.isTurn, false))
			xmlFile:setBool(v68_ .. "#isHeadlandSegment", Utils.getNoNil(v67_.isHeadlandSegment, false))
			xmlFile:setBool(v68_ .. "#isIslandSegment", Utils.getNoNil(v67_.isIslandSegment, false))
			xmlFile:setFloat(v68_ .. "#length", v67_.length or 0)
			for v69_, v70_ in ipairs(v67_.positions) do
				xmlFile:setVector(string.format("%s.position(%d)", v68_, v69_ - 1) .. "#value", v70_)
			end
		end
	end
end

function GameTestCaseAIFieldWork.registerXMLPaths(schema, baseKey) end
GameTestManager.registerTestCase(GameTestCaseAIFieldWork)
