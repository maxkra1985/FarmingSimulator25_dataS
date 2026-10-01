GameTestManager = {}
GameTestManager.xmlSchema = nil
GameTestManager.registeredTestCases = {}
function GameTestManager.registerTestCase(class)
	table.insert(GameTestManager.registeredTestCases, class)
end
source("dataS/scripts/testing/gameTestCases/GameTestCase.lua")
source("dataS/scripts/testing/gameTestCases/GameTestCaseAI.lua")
source("dataS/scripts/testing/gameTestCases/GameTestCaseAIDeliver.lua")
source("dataS/scripts/testing/gameTestCases/GameTestCaseAIFieldWork.lua")
source("dataS/scripts/testing/gameTestCases/GameTestCaseAIGoTo.lua")
source("dataS/scripts/testing/gameTestCases/GameTestCaseAILoadAndDeliver.lua")
source("dataS/scripts/testing/gameTests/GameTestTask.lua")
source("dataS/scripts/testing/gameTests/GameTestTaskAI.lua")
source("dataS/scripts/testing/gameTests/GameTestTaskAIDeliver.lua")
source("dataS/scripts/testing/gameTests/GameTestTaskAIFieldWork.lua")
source("dataS/scripts/testing/gameTests/GameTestTaskAIGoTo.lua")
source("dataS/scripts/testing/gameTests/GameTestTaskAILoadAndDeliver.lua")
local GameTestManager_mt = Class(GameTestManager, AbstractManager)
function GameTestManager.new(customMt)
	local self = AbstractManager.new(customMt or GameTestManager_mt)
	GameTestManager.xmlSchema = XMLSchema.new("testing")
	GameTestManager.registerXMLPaths(GameTestManager.xmlSchema)
	addConsoleCommand("gsGameTestPrintVehicleSetups", "Prints all vehicle setups on the map to be used inside a test config file", "consoleCommandPrintVehicleSetups", self)
	return self
end
function GameTestManager:initDataStructures()
	self.configXMLFilesToLoad = {}
	self.currentTestCase = nil
	self.totalNumTestCases = 0
	self.clientNumTestCases = 0
	self.clientNumTestCasesSuccess = 0
	self.clientNumTestCasesFailed = 0
	self.clientNumTestCasesInPool = 0
	self.clientNumTestCasesSession = 0
	self.testCasesLoaded = false
	self.numTestClients = tonumber(StartParams.getValue("gameTestNumClients") or "1")
	self.testClientIndex = tonumber(StartParams.getValue("gameTestClientIndex") or "1")
	self.createGameTestConfigs = StartParams.getIsSet("createGameTestConfigs")
	self.svnRevision = tonumber(StartParams.getValue("gameTestSVNRevision") or "-1")
	self.disableTrafficSystem = StartParams.getValue("gameTestDisableTraffic") ~= "false"
	local limitedCaseClassNamesStr = StartParams.getValue("gameTestLimitedCaseClassNames")
	if limitedCaseClassNamesStr ~= nil and limitedCaseClassNamesStr ~= "" then
		local limitedCaseClassNames = string.split(limitedCaseClassNamesStr, ";")
		self.limitedCaseClassNames = {}
		for _, v in ipairs(limitedCaseClassNames) do
			self.limitedCaseClassNames[v] = true
		end
	end
	self.testCaseConfigFile = StartParams.getValue("gameTestCaseConfigFile")
	if self.testCaseConfigFile ~= nil then
		if not fileExists(self.testCaseConfigFile) then
			self.testCaseConfigFile = nil
			Logging.warning("Unknown game test config file '%s'", self.testCaseConfigFile)
		else
			self.createGameTestConfigs = true
		end
	end
	self.gameTestsFolder = getUserProfileAppPath() .. "gameTests/"
	createFolder(self.gameTestsFolder)
	self.currentTestFolder = StartParams.getValue("gameTestDirectory")
	if self.currentTestFolder == nil then
		self.currentTestFolder = self.gameTestsFolder .. getDate("%Y_%m_%d_%H_%M_%S") .. "/"
		createFolder(self.currentTestFolder)
	else
		self.currentTestFolder = self.currentTestFolder:gsub("\\", "/") .. "/"
	end
	self.currentCaseConfigFolder = self.currentTestFolder .. "configs/"
	createFolder(self.currentCaseConfigFolder)
	self.currentCaseLogFolder = self.currentTestFolder .. "logs/"
	createFolder(self.currentCaseLogFolder)
	if self.testCaseConfigFile == nil then
		local logFileIndex = 1
		while true do
			local logFilename = string.format("%slog_client%02d_%03d.txt", self.currentCaseLogFolder, self.testClientIndex, logFileIndex)
			if not fileExists(logFilename) then
				break
			end
			logFileIndex = logFileIndex + 1
		end
		self:print("Set log file directory to: " .. logFilename)
		setFileLogName(logFilename)
	end
	Platform.hasAdjustableFrameLimit = false
end
function GameTestManager:loadMapData(xmlFile, missionInfo, baseDirectory)
	GameTestManager:superClass().loadMapData(self)
	for _, class in ipairs(GameTestManager.registeredTestCases) do
		if class.overwriteFunctions == nil then
			continue
		end
		class.overwriteFunctions()
	end
	local filename = Utils.getFilename(missionInfo.mapXMLFilename, baseDirectory)
	local directory = Utils.getDirectory(filename)
	directory = directory .. "/gameTests"
	if self.testCaseConfigFile == nil then
		local files = Files.new(directory)
		for _, file in pairs(files.files) do
			if file.isDirectory then
				continue
			end
			if file.filename:contains(".xml") then
				table.insert(self.configXMLFilesToLoad, directory .. "/" .. file.filename)
			end
		end
		if 0 < #self.configXMLFilesToLoad then
			g_messageCenter:subscribeOneshot(MessageType.CURRENT_MISSION_START, GameTestManager.onMissionStarted, self)
		else
			self:print("No test case config files found in '%s'", directory)
		end
	else
		g_messageCenter:subscribeOneshot(MessageType.CURRENT_MISSION_START, GameTestManager.onMissionStarted, self)
	end
	if self.disableTrafficSystem then
		missionInfo.trafficEnabled = false
	end
	setCaption(string.format("Game Test Client %d of %d (rev %d)", self.testClientIndex, self.numTestClients, self.svnRevision))
	toggleShowFPS()
	setFramerateLimiter(true, 30)
	setLODDistanceCoeff(3)
	setTextureStreamingMemoryBudget(5)
	missionInfo.growthMode = GrowthMode.DISABLED
	g_currentMission.growthSystem:setGrowthEnabled(false)
	WheelPhysics.COLLISION_MASK = CollisionMask.ALL - CollisionFlag.TERRAIN_DISPLACEMENT
end
function GameTestManager:onLoadMapFinished(mapRootNode)
	self:removeVisualsRec(mapRootNode, 0)
end
function GameTestManager:removeVisualsRec(node, index)
	if getUserAttribute(node, "onCreate") ~= nil then
		return
	elseif getHasClassId(node, ClassIds.SHAPE) then
		local materialId = getMaterial(node, 0)
		if materialId ~= 0 then
			local shaderFilename = getMaterialCustomShaderFilename(materialId)
			if not shaderFilename:contains("characterShader.xml") and (not shaderFilename:contains("fruitGrowthFoliageShader.xml") and (not shaderFilename:contains("precipitationShader.xml") and (not shaderFilename:contains("solidFoliageShader.xml") and not string.contains(string.lower(getName(node)), "effect")))) then
				if getRigidBodyType(node) == RigidBodyType.NONE then
					if getNumOfChildren(node) == 0 then
						local transformGroup = createTransformGroup("dummy")
						link(getParent(node), transformGroup, index)
						delete(node)
						return
					end
					local transformGroup = createTransformGroup("dummy")
					link(getParent(node), transformGroup, index)
					setWorldTranslation(transformGroup, getWorldTranslation(node))
					setWorldRotation(transformGroup, getWorldRotation(node))
					for i = getNumOfChildren(node), 1, -1 do
						local child = getChildAt(node, i - 1)
						local x, y, z = getWorldTranslation(child)
						local rx, ry, rz = getWorldRotation(child)
						link(transformGroup, child)
						setWorldTranslation(child, x, y, z)
						setWorldRotation(child, rx, ry, rz)
					end
					delete(node)
					node = transformGroup
				else
					local debugMaterialId = g_debugManager:getDebugMat()
					if materialId ~= debugMaterialId then
						self:overwriteMaterialRec(getRootNode(), materialId, debugMaterialId)
					end
					if getIsNonRenderable(node) and (not getHasTrigger(node) and not getName(node):contains("aiTrafficCollision")) then
						setIsNonRenderable(node, false)
						setClipDistance(node, 300)
					end
				end
				for i = getNumOfChildren(node), 1, -1 do
					self:removeVisualsRec(getChildAt(node, i - 1), i - 1)
				end
				return
			end
			if shaderFilename:contains("characterShader.xml") then
				local debugMaterialId = g_debugManager:getDebugMat()
				if getHasClassId(node, ClassIds.SHAPE) then
					for i = 1, getNumOfMaterials(node) do
						setMaterial(node, debugMaterialId, i - 1)
					end
				end
			end
		end
	elseif getHasClassId(node, ClassIds.MESH_SPLIT_SHAPE) or getHasClassId(node, ClassIds.GEOMETRY) then
		if getIsNonRenderable(node) then
			setIsNonRenderable(node, false)
			setClipDistance(node, 300)
		end
	end
end
function GameTestManager:overwriteMaterialRec(node, materialId, newMaterialId)
	if getHasClassId(node, ClassIds.SHAPE) then
		for i = 1, getNumOfMaterials(node) do
			if getMaterial(node, i - 1) == materialId then
				setMaterial(node, newMaterialId, i - 1)
			end
		end
	end
	for i = getNumOfChildren(node), 1, -1 do
		self:overwriteMaterialRec(getChildAt(node, i - 1), materialId, newMaterialId)
	end
end
function GameTestManager:loadXMLConfigFile(testCases, xmlFile)
	xmlFile:iterate("testing.testCases", function(index, caseKey)
		local className = xmlFile:getValue(caseKey .. "#className")
		if self.limitedCaseClassNames == nil or self.limitedCaseClassNames[className] == true then
			local class = ClassUtil.getClassObject(className)
			if class ~= nil then
				class.generateTestCases(testCases, xmlFile, caseKey)
			end
		end
	end)
end
function GameTestManager:unloadMapData()
	if self.currentTestCase ~= nil then
		self.currentTestCase:delete()
		self.currentTestCase = nil
	end
	GameTestManager:superClass().unloadMapData(self)
end
function GameTestManager:onMissionStarted(isNewSavegame)
	if self.createGameTestConfigs then
		self:print("Create test configs..")
		local testCases = {}
		for i = 1, #self.configXMLFilesToLoad do
			local testCaseConfigFilename = self.configXMLFilesToLoad[i]
			self:print("Loading test cases from config file '%s'", testCaseConfigFilename)
			local testXMLFile = XMLFile.load("TempTesting", testCaseConfigFilename, GameTestManager.xmlSchema)
			if testXMLFile == nil then
				continue
			end
			self:loadXMLConfigFile(testCases, testXMLFile)
			testXMLFile:delete()
		end
		if self.testCaseConfigFile ~= nil then
			self:print("Loading test cases from config file '%s'", self.testCaseConfigFile)
			local testCaseConfigFile = XMLFile.load("testCaseConfigFile", self.testCaseConfigFile, GameTestManager.xmlSchema)
			if testCaseConfigFile ~= nil then
				local className = testCaseConfigFile:getString("testCaseReport.config#className")
				if className ~= nil then
					local class = ClassUtil.getClassObject(className)
					if class ~= nil then
						local testCase = class.generateTestCaseFromConfig(testCaseConfigFile, "testCaseReport.config")
						if testCase ~= nil then
							table.insert(testCases, testCase)
						end
					end
				end
				testCaseConfigFile:delete()
			end
		end
		self.totalNumTestCases = #testCases
		for i, testCase in ipairs(testCases) do
			local filename = string.format("%stestCase%04d.xml", self.currentCaseConfigFolder, i)
			local xmlFile = XMLFile.create("testConfig", filename, "testConfig", nil)
			testCase:saveToXMLFile(xmlFile, "testConfig")
			xmlFile:save()
			xmlFile:delete()
		end
		self:print("Found %d test cases.", self.totalNumTestCases)
	end
	self:loadMetaData()
	self:writeMetaData()
	for _, class in ipairs(GameTestManager.registeredTestCases) do
		if class.onMissionStarted == nil then
			continue
		end
		class.onMissionStarted(isNewSavegame)
	end
	self.testCasesLoaded = true
end
function GameTestManager:update(dt)
	if self.testCasesLoaded and not g_pendingExit then
		if self.currentTestCase == nil then
			local files = Files.new(self.currentCaseConfigFolder).files
			self.clientNumTestCasesInPool = #files
			local testCaseToUse = nil
			for k, file in pairs(files) do
				if file.isDirectory then
					continue
				end
				local filename = self.currentCaseConfigFolder .. file.filename
				local xmlFile = XMLFile.load("testConfig", filename, nil)
				if xmlFile ~= nil then
					local className = xmlFile:getString("testConfig#className")
					if className ~= nil then
						local class = ClassUtil.getClassObject(className)
						if class ~= nil then
							local testCase = class.generateTestCaseFromConfig(xmlFile, "testConfig")
							if testCase ~= nil then
								testCase.index = tonumber(file.filename:sub(9, 12))
								testCaseToUse = testCase
								self:print("Loaded test case from config file '%s'", filename)
								xmlFile:delete()
								deleteFile(filename)
								break
							else
								break
							end
						else
							break
						end
					else
						break
					end
				end
				self:print("Failed to load test case from config file '%s'", filename)
			end
			if testCaseToUse ~= nil then
				self.currentTestCase = testCaseToUse
				testCaseToUse:start(function(result)
					self.clientNumTestCases = self.clientNumTestCases + 1
					self.clientNumTestCasesSession = self.clientNumTestCasesSession + 1
					if result == GameTestCase.RESULT.SUCCESS then
						self.clientNumTestCasesSuccess = self.clientNumTestCasesSuccess + 1
					else
						self.clientNumTestCasesFailed = self.clientNumTestCasesFailed + 1
					end
					self:onTestCaseFinished()
				end)
				return
			end
			if self.testCaseConfigFile == nil and (120000 < g_time or self.clientNumTestCases ~= 0) then
				self:print("No test cases found. Closing.")
				doExit()
			end
		else
			self.currentTestCase:update(dt)
		end
	end
end
function GameTestManager:onTestCaseFinished()
	self:writeMetaData()
	self.currentTestCase = nil
	if 1 < self.numTestClients and 10 < self.clientNumTestCasesSession then
		self:print("Forcing restart after 10 test cases")
		doExit()
	end
end
function GameTestManager:loadMetaData()
	local filename = self.currentTestFolder .. "meta.xml"
	if fileExists(filename) then
		local xmlFile = XMLFile.load("meta", filename, nil)
		if xmlFile ~= nil then
			local clientKey = string.format("meta.clients.client(%d)", self.testClientIndex - 1)
			self.clientNumTestCases = xmlFile:getInt(clientKey .. "#numCases", self.clientNumTestCases)
			self.clientNumTestCasesSuccess = xmlFile:getInt(clientKey .. "#numCasesSuccess", self.clientNumTestCasesSuccess)
			self.clientNumTestCasesFailed = xmlFile:getInt(clientKey .. "#numCasesFailed", self.clientNumTestCasesFailed)
			xmlFile:delete()
		end
	end
end
function GameTestManager:writeMetaData()
	local filename = self.currentTestFolder .. "meta.xml"
	local xmlFile = nil
	if fileExists(filename) then
		xmlFile = XMLFile.load("meta", filename, nil)
	end
	if xmlFile == nil then
		xmlFile = XMLFile.create("meta", filename, "meta", nil)
	end
	local clientKey = string.format("meta.clients.client(%d)", self.testClientIndex - 1)
	xmlFile:setInt(clientKey .. "#clientIndex", self.testClientIndex)
	xmlFile:setFloat(clientKey .. "#duration", g_time / 1000 / 60)
	xmlFile:setInt(clientKey .. "#numCases", self.clientNumTestCases)
	xmlFile:setInt(clientKey .. "#numCasesSuccess", self.clientNumTestCasesSuccess)
	xmlFile:setInt(clientKey .. "#numCasesFailed", self.clientNumTestCasesFailed)
	xmlFile:setInt(clientKey .. "#luaMemory", collectgarbage("count"))
	if self.currentTestCase ~= nil then
		local testCase = self.currentTestCase
		local key = string.format("meta.results.testCase(%d)", testCase.index - 1)
		xmlFile:setInt(key .. "#index", testCase.index)
		xmlFile:setInt(key .. "#clientIndex", self.testClientIndex)
		xmlFile:setString(key .. "#result", GameTestCase.getResultName(testCase.result))
		xmlFile:setString(key .. "#reason", testCase.resultReason)
		xmlFile:setString(key .. "#taskName", testCase:getName())
		xmlFile:setString(key .. "#description", testCase:getDescription())
		xmlFile:setString(key .. "#descriptionShort", testCase:getShortDescription())
	end
	if self.testClientIndex == 1 then
		if not xmlFile:hasProperty("meta#totalTestCases") then
			xmlFile:setInt("meta#totalTestCases", self.totalNumTestCases)
		end
		xmlFile:setString("meta#gameVersion", g_gameVersionDisplay)
		xmlFile:setString("meta#gameTitle", g_gameTitle)
		xmlFile:setString("meta#gameDirectory", getAppBasePath())
		xmlFile:setInt("meta#svnRevision", self.svnRevision)
		xmlFile:setInt("meta.clients#numClients", self.numTestClients)
		for _, class in ipairs(GameTestManager.registeredTestCases) do
			if class.fillMetaData == nil then
				continue
			end
			class.fillMetaData(xmlFile, "meta")
		end
	end
	xmlFile:save()
	xmlFile:delete()
	self:print("Saved meta data to '%s'", filename)
end
function GameTestManager:draw(dt)
	if self.currentTestCase ~= nil then
		local minutes = g_time / 1000 / 60
		local hours = math.floor(minutes / 60)
		local durationStr = string.format("%02d:%02dh", hours, minutes - hours * 60)
		setTextAlignment(RenderText.ALIGN_CENTER)
		setTextBold(true)
		setTextColor(1, 1, 1, 1)
		renderText(0.5, 0.2, 0.025, string.format("Test Client %d/%d (%d failed - %d success - %d waiting - %s)", self.testClientIndex, self.numTestClients, self.clientNumTestCasesFailed, self.clientNumTestCasesSuccess, self.clientNumTestCasesInPool, durationStr))
		renderText(0.5, 0.175, 0.025, self.currentTestCase:getFullName())
		renderText(0.5, 0.15, 0.025, self.currentTestCase:getDescription())
		setTextAlignment(RenderText.ALIGN_LEFT)
	end
end
function GameTestManager:print(text, ...)
	print("   GameTestManager: " .. string.format(text, ...))
end
function GameTestManager:consoleCommandPrintVehicleSetups()
	local vehicles = g_currentMission.vehicleSystem.vehicles
	local setupByType = {}
	setupByType.CULTIVATION = {}
	setupByType.SOWING = {}
	setupByType.COMBINE_HARVESTER = {}
	setupByType.SPRAYING = {}
	setupByType.MOWING = {}
	setupByType.PLOWING = {}
	local usedVehicles = {}
	for _, vehicle in ipairs(vehicles) do
		local rootVehicle = vehicle.rootVehicle
		if usedVehicles[rootVehicle] == nil then
			usedVehicles[rootVehicle] = true
			local vehicleToIndex = {}
			local name = rootVehicle:getName()
			table.sort(rootVehicle.childVehicles, function(a, b)
				return a == rootVehicle
			end)
			for index, childVehicle in ipairs(rootVehicle.childVehicles) do
				if childVehicle ~= rootVehicle then
					name = name .. " + " .. childVehicle:getName()
				end
				vehicleToIndex[childVehicle] = index
			end
			local rootNode = rootVehicle.rootNode
			local zOffset = 0
			local output = ""
			local workType = nil
			for _, childVehicle in ipairs(rootVehicle.childVehicles) do
				local filename = childVehicle.configFileName
				if string.startsWith(filename, "data") then
					filename = "$" .. filename
				end
				local x, y, z = localToLocal(childVehicle.rootNode, rootNode, 0, 0, 0)
				local _, _, minZ = localToLocal(childVehicle.rootNode, rootNode, 0, 0, -childVehicle.size.length * 0.5 + childVehicle.size.lengthOffset)
				zOffset = math.min(zOffset, minZ)
				output = output .. string.format('            <vehicle xmlFilename="%s" offset="%.3f %.3f %.3f" rotationOffset="%.3f"/>\n', filename, x, y, z, 0)
				local typeNameLower = string.lower(childVehicle.typeName)
				if string.contains(typeNameLower, "combine") then
					workType = "COMBINE_HARVESTER"
				elseif string.contains(typeNameLower, "sowingmachine") then
					workType = "SOWING"
				elseif string.contains(typeNameLower, "cultivator") then
					workType = "CULTIVATION"
				elseif string.contains(typeNameLower, "sprayer") then
					workType = "SPRAYING"
				elseif string.contains(typeNameLower, "mower") then
					workType = "MOWING"
				elseif string.contains(typeNameLower, "plow") then
					workType = "PLOWING"
				end
			end
			for _, childVehicle in ipairs(rootVehicle.childVehicles) do
				if childVehicle.getAttachedImplements == nil then
					continue
				end
				local implements = childVehicle:getAttachedImplements()
				for _, implement in ipairs(implements) do
					output = output .. string.format('\n            <attachment rootVehicleId="%d" attachmentId="%d" jointIndex="%d" inputAttacherJointIndex="%d"/>\n', vehicleToIndex[childVehicle], vehicleToIndex[implement.object], implement.jointDescIndex, implement.inputJointDescIndex)
				end
			end
			output = string.format('        <vehicleSetup name="%s" zOffset="%.1f">\n', name, math.abs(zOffset)) .. output
			output = output .. "        </vehicleSetup>"
			if workType == nil then
				continue
			end
			table.insert(setupByType[workType], output)
		end
	end
	local out = "\n"
	for workType, setups in pairs(setupByType) do
		if 0 < #setups then
			out = out .. string.format('<testCases className="GameTestCaseAIFieldWork" workType="%s">\n', workType)
			out = out .. '    <spawnPositions useBasePositions="true" />\n\n'
			out = out .. "    <vehicleSetups>\n"
			for _, setup in ipairs(setups) do
				out = out .. setup .. "\n"
			end
			out = out .. "    </vehicleSetups>\n"
			out = out .. "</testCases>\n\n"
		end
	end
	print(out)
end
function GameTestManager.registerXMLPaths(schema)
	schema:register(XMLValueType.STRING, "testing.testCases(?)#className", "LUA class name of the test")
	for _, class in ipairs(GameTestManager.registeredTestCases) do
		if class.registerXMLPaths == nil then
			continue
		end
		class.registerXMLPaths(schema, "testing.testCases(?)")
	end
end
Mission00.getIsTourSupported = Utils.overwrittenFunction(Mission00.getIsTourSupported, function(superFunc)
	return false
end)
FieldManager.addFieldUpdateTask = Utils.overwrittenFunction(FieldManager.addFieldUpdateTask, function(superFunc, updateTask) end)
BaseMission.loadMapFinished = Utils.overwrittenFunction(BaseMission.loadMapFinished, function(superFunc, node, ...)
	g_gameTestManager:onLoadMapFinished(node)
	superFunc(self, node, ...)
end)
TypeManager.finalizeTypes = Utils.prependedFunction(TypeManager.finalizeTypes, function(superFunc)
	if self.typeName == "vehicle" then
		PowerTakeOffs.loadPowerTakeOffsFromXML = Utils.overwrittenFunction(PowerTakeOffs.loadPowerTakeOffsFromXML, function(superFunc) end)
		Wheels.loadHubsFromXML = Utils.overwrittenFunction(Wheels.loadHubsFromXML, function(superFunc)
			local spec = self.spec_wheels
			spec.hubs = {}
		end)
		SharedLight.loadFromXML = Utils.overwrittenFunction(SharedLight.loadFromXML, function(superFunc)
			return false
		end)
		DynamicallyLoadedParts.onLoad = Utils.overwrittenFunction(DynamicallyLoadedParts.onLoad, function(superFunc)
			local spec = self.spec_dynamicallyLoadedParts
			spec.sharedLoadRequestIds = {}
			spec.parts = {}
		end)
		WheelVisualPart.loadFromXML = Utils.overwrittenFunction(WheelVisualPart.loadFromXML, function(superFunc)
			return false
		end)
		Crawlers.loadCrawlerFromXML = Utils.overwrittenFunction(Crawlers.loadCrawlerFromXML, function(superFunc)
			return false
		end)
	else
		if self.typeName == "placeable" then
			PlaceableConstructible.onFinalizePlacement = Utils.overwrittenFunction(PlaceableConstructible.onFinalizePlacement, function(superFunc, savegame, ...)
				local spec = self.spec_constructible
				if spec.stateIndexPending ~= nil then
					spec.stateIndexPending = #spec.stateMachine
				else
					spec.startStateIndex = #spec.stateMachine
				end
				return superFunc(self, savegame, ...)
			end)
			AnimatedObject.setAnimTime = Utils.overwrittenFunction(AnimatedObject.setAnimTime, function(superFunc, time, ...)
				return superFunc(self, 1, ...)
			end)
		end
	end
end)
Platform.hasWardrobe = false
g_gameTestManager = GameTestManager.new()
