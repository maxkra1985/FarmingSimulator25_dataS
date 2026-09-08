-- Local values: GameTestManager_mt
GameTestManager = {}
GameTestManager.xmlSchema = nil
GameTestManager.registeredTestCases = {}

function GameTestManager.registerTestCase(class)
	local v2_ = GameTestManager.registeredTestCases
	table.insert(v2_, class)
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
local v_u_3_ = Class(GameTestManager, AbstractManager)

-- Upvalues: GameTestManager_mt
-- Local values: self
function GameTestManager.new(customMt)
	-- upvalues: (copy) v_u_3_
	local v5_ = AbstractManager.new(customMt or v_u_3_)
	GameTestManager.xmlSchema = XMLSchema.new("testing")
	GameTestManager.registerXMLPaths(GameTestManager.xmlSchema)
	addConsoleCommand("gsGameTestPrintVehicleSetups", "Prints all vehicle setups on the map to be used inside a test config file", "consoleCommandPrintVehicleSetups", v5_)
	return v5_
end

-- Local values: limitedCaseClassNamesStr, limitedCaseClassNames, _, v, logFileIndex, logFilename
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
	local v7_ = StartParams.getValue("gameTestNumClients") or "1"
	self.numTestClients = tonumber(v7_)
	local v8_ = StartParams.getValue("gameTestClientIndex") or "1"
	self.testClientIndex = tonumber(v8_)
	self.createGameTestConfigs = StartParams.getIsSet("createGameTestConfigs")
	local v9_ = StartParams.getValue("gameTestSVNRevision") or "-1"
	self.svnRevision = tonumber(v9_)
	self.disableTrafficSystem = StartParams.getValue("gameTestDisableTraffic") ~= "false"
	local v10_ = StartParams.getValue("gameTestLimitedCaseClassNames")
	if v10_ ~= nil and v10_ ~= "" then
		local v11_ = string.split(v10_, ";")
		self.limitedCaseClassNames = {}
		for _, v12_ in ipairs(v11_) do
			self.limitedCaseClassNames[v12_] = true
		end
	end
	self.testCaseConfigFile = StartParams.getValue("gameTestCaseConfigFile")
	if self.testCaseConfigFile ~= nil then
		if fileExists(self.testCaseConfigFile) then
			self.createGameTestConfigs = true
		else
			self.testCaseConfigFile = nil
			Logging.warning("Unknown game test config file \'%s\'", self.testCaseConfigFile)
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
		local v13_ = 1
		while true do
			local v14_ = string.format("%slog_client%02d_%03d.txt", self.currentCaseLogFolder, self.testClientIndex, v13_)
			if not fileExists(v14_) then
				break
			end
			v13_ = v13_ + 1
		end
		self:print("Set log file directory to: " .. v14_)
		setFileLogName(v14_)
	end
	Platform.hasAdjustableFrameLimit = false
end

-- Local values: _, class, filename, directory, files, _, file
function GameTestManager:loadMapData(xmlFile, missionInfo, baseDirectory)
	GameTestManager:superClass().loadMapData(self)
	for _, v18_ in ipairs(GameTestManager.registeredTestCases) do
		if v18_.overwriteFunctions ~= nil then
			v18_.overwriteFunctions()
		end
	end
	local v19_ = Utils.getFilename(missionInfo.mapXMLFilename, baseDirectory)
	local v20_ = Utils.getDirectory(v19_) .. "/gameTests"
	if self.testCaseConfigFile == nil then
		local v21_ = Files.new(v20_)
		for _, v22_ in pairs(v21_.files) do
			if not v22_.isDirectory and v22_.filename:contains(".xml") then
				local v23_ = self.configXMLFilesToLoad
				local v24_ = v20_ .. "/" .. v22_.filename
				table.insert(v23_, v24_)
			end
		end
		if #self.configXMLFilesToLoad > 0 then
			g_messageCenter:subscribeOneshot(MessageType.CURRENT_MISSION_START, GameTestManager.onMissionStarted, self)
		else
			self:print("No test case config files found in \'%s\'", v20_)
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

-- Local values: materialId, shaderFilename, transformGroup, transformGroup, i, child, x, y, z, rx, ry, rz, debugMaterialId, debugMaterialId, i, i
function GameTestManager:removeVisualsRec(node, index)
	if getUserAttribute(node, "onCreate") == nil then
		if getHasClassId(node, ClassIds.SHAPE) then
			local v30_ = getMaterial(node, 0)
			if v30_ ~= 0 then
				local v31_ = getMaterialCustomShaderFilename(v30_)
				if v31_:contains("characterShader.xml") or (v31_:contains("fruitGrowthFoliageShader.xml") or (v31_:contains("precipitationShader.xml") or (v31_:contains("solidFoliageShader.xml") or string.contains(string.lower(getName(node)), "effect")))) then
					if v31_:contains("characterShader.xml") then
						local v32_ = g_debugManager:getDebugMat()
						if getHasClassId(node, ClassIds.SHAPE) then
							for v33_ = 1, getNumOfMaterials(node) do
								setMaterial(node, v32_, v33_ - 1)
							end
						end
					end
				elseif getRigidBodyType(node) == RigidBodyType.NONE then
					if getNumOfChildren(node) == 0 then
						local v34_ = createTransformGroup("dummy")
						link(getParent(node), v34_, index)
						delete(node)
						return
					end
					local v35_ = createTransformGroup("dummy")
					link(getParent(node), v35_, index)
					setWorldTranslation(v35_, getWorldTranslation(node))
					setWorldRotation(v35_, getWorldRotation(node))
					for v36_ = getNumOfChildren(node), 1, -1 do
						local v37_ = getChildAt(node, v36_ - 1)
						local v38_, v39_, v40_ = getWorldTranslation(v37_)
						local v41_, v42_, v43_ = getWorldRotation(v37_)
						link(v35_, v37_)
						setWorldTranslation(v37_, v38_, v39_, v40_)
						setWorldRotation(v37_, v41_, v42_, v43_)
					end
					delete(node)
					node = v35_
				else
					local v44_ = g_debugManager:getDebugMat()
					if v30_ ~= v44_ then
						self:overwriteMaterialRec(getRootNode(), v30_, v44_)
					end
					if getIsNonRenderable(node) and not (getHasTrigger(node) or getName(node):contains("aiTrafficCollision")) then
						setIsNonRenderable(node, false)
						setClipDistance(node, 300)
					end
				end
			end
		elseif (getHasClassId(node, ClassIds.MESH_SPLIT_SHAPE) or getHasClassId(node, ClassIds.GEOMETRY)) and getIsNonRenderable(node) then
			setIsNonRenderable(node, false)
			setClipDistance(node, 300)
		end
		for v45_ = getNumOfChildren(node), 1, -1 do
			self:removeVisualsRec(getChildAt(node, v45_ - 1), v45_ - 1)
		end
	end
end

-- Local values: i, i
function GameTestManager:overwriteMaterialRec(node, materialId, newMaterialId)
	if getHasClassId(node, ClassIds.SHAPE) then
		for v50_ = 1, getNumOfMaterials(node) do
			if getMaterial(node, v50_ - 1) == materialId then
				setMaterial(node, newMaterialId, v50_ - 1)
			end
		end
	end
	for v51_ = getNumOfChildren(node), 1, -1 do
		self:overwriteMaterialRec(getChildAt(node, v51_ - 1), materialId, newMaterialId)
	end
end

function GameTestManager:loadXMLConfigFile(testCases, xmlFile)
	xmlFile:iterate("testing.testCases", function(_, p55_)
		-- upvalues: (copy) xmlFile, (copy) self, (copy) testCases
		local v56_ = xmlFile:getValue(p55_ .. "#className")
		if self.limitedCaseClassNames == nil or self.limitedCaseClassNames[v56_] == true then
			local v57_ = ClassUtil.getClassObject(v56_)
			if v57_ ~= nil then
				v57_.generateTestCases(testCases, xmlFile, p55_)
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

-- Local values: testCases, i, testCaseConfigFilename, testXMLFile, testCaseConfigFile, className, class, testCase, i, testCase, filename, xmlFile, _, class
function GameTestManager:onMissionStarted(isNewSavegame)
	if self.createGameTestConfigs then
		self:print("Create test configs..")
		local v61_ = {}
		for v62_ = 1, #self.configXMLFilesToLoad do
			local v63_ = self.configXMLFilesToLoad[v62_]
			self:print("Loading test cases from config file \'%s\'", v63_)
			local v64_ = XMLFile.load("TempTesting", v63_, GameTestManager.xmlSchema)
			if v64_ ~= nil then
				self:loadXMLConfigFile(v61_, v64_)
				v64_:delete()
			end
		end
		if self.testCaseConfigFile ~= nil then
			self:print("Loading test cases from config file \'%s\'", self.testCaseConfigFile)
			local v65_ = XMLFile.load("testCaseConfigFile", self.testCaseConfigFile, GameTestManager.xmlSchema)
			if v65_ ~= nil then
				local v66_ = v65_:getString("testCaseReport.config#className")
				if v66_ ~= nil then
					local v67_ = ClassUtil.getClassObject(v66_)
					if v67_ ~= nil then
						local v68_ = v67_.generateTestCaseFromConfig(v65_, "testCaseReport.config")
						if v68_ ~= nil then
							table.insert(v61_, v68_)
						end
					end
				end
				v65_:delete()
			end
		end
		self.totalNumTestCases = #v61_
		for v69_, v70_ in ipairs(v61_) do
			local v71_ = string.format("%stestCase%04d.xml", self.currentCaseConfigFolder, v69_)
			local v72_ = XMLFile.create("testConfig", v71_, "testConfig", nil)
			v70_:saveToXMLFile(v72_, "testConfig")
			v72_:save()
			v72_:delete()
		end
		self:print("Found %d test cases.", self.totalNumTestCases)
	end
	self:loadMetaData()
	self:writeMetaData()
	for _, v73_ in ipairs(GameTestManager.registeredTestCases) do
		if v73_.onMissionStarted ~= nil then
			v73_.onMissionStarted(isNewSavegame)
		end
	end
	self.testCasesLoaded = true
end

-- Local values: files, testCaseToUse, k, file, filename, xmlFile, className, class, testCase
function GameTestManager:update(dt)
	if self.testCasesLoaded and not g_pendingExit then
		if self.currentTestCase == nil then
			local v76_ = Files.new(self.currentCaseConfigFolder).files
			self.clientNumTestCasesInPool = #v76_
			local v77_ = nil
			for _, v78_ in pairs(v76_) do
				if not v78_.isDirectory then
					local v79_ = self.currentCaseConfigFolder .. v78_.filename
					local v80_ = XMLFile.load("testConfig", v79_, nil)
					if v80_ ~= nil then
						local v81_ = v80_:getString("testConfig#className")
						local v82_
						if v81_ == nil then
							v82_ = v77_
						else
							local v83_ = ClassUtil.getClassObject(v81_)
							if v83_ == nil then
								v82_ = v77_
							else
								v82_ = v83_.generateTestCaseFromConfig(v80_, "testConfig")
								if v82_ == nil then
									v82_ = v77_
								else
									local v84_ = v78_.filename
									v82_.index = tonumber(v84_:sub(9, 12))
								end
							end
						end
						self:print("Loaded test case from config file \'%s\'", v79_)
						v80_:delete()
						deleteFile(v79_)
						v77_ = v82_
						break
					end
					self:print("Failed to load test case from config file \'%s\'", v79_)
				end
			end
			if v77_ ~= nil then
				self.currentTestCase = v77_
				v77_:start(function(p85_)
					-- upvalues: (copy) self
					self.clientNumTestCases = self.clientNumTestCases + 1
					self.clientNumTestCasesSession = self.clientNumTestCasesSession + 1
					if p85_ == GameTestCase.RESULT.SUCCESS then
						self.clientNumTestCasesSuccess = self.clientNumTestCasesSuccess + 1
					else
						self.clientNumTestCasesFailed = self.clientNumTestCasesFailed + 1
					end
					self:onTestCaseFinished()
				end)
				return
			end
			if self.testCaseConfigFile == nil and (g_time > 120000 or self.clientNumTestCases ~= 0) then
				self:print("No test cases found. Closing.")
				doExit()
				return
			end
		else
			self.currentTestCase:update(dt)
		end
	end
end

function GameTestManager:onTestCaseFinished()
	self:writeMetaData()
	self.currentTestCase = nil
	if self.numTestClients > 1 and self.clientNumTestCasesSession > 10 then
		self:print("Forcing restart after 10 test cases")
		doExit()
	end
end

-- Local values: filename, xmlFile, clientKey
function GameTestManager:loadMetaData()
	local v88_ = self.currentTestFolder .. "meta.xml"
	if fileExists(v88_) then
		local v89_ = XMLFile.load("meta", v88_, nil)
		if v89_ ~= nil then
			local v90_ = string.format("meta.clients.client(%d)", self.testClientIndex - 1)
			self.clientNumTestCases = v89_:getInt(v90_ .. "#numCases", self.clientNumTestCases)
			self.clientNumTestCasesSuccess = v89_:getInt(v90_ .. "#numCasesSuccess", self.clientNumTestCasesSuccess)
			self.clientNumTestCasesFailed = v89_:getInt(v90_ .. "#numCasesFailed", self.clientNumTestCasesFailed)
			v89_:delete()
		end
	end
end

-- Local values: filename, xmlFile, clientKey, testCase, key, _, class
function GameTestManager:writeMetaData()
	local v92_ = self.currentTestFolder .. "meta.xml"
	local v93_
	if fileExists(v92_) then
		v93_ = XMLFile.load("meta", v92_, nil)
	else
		v93_ = nil
	end
	if v93_ == nil then
		v93_ = XMLFile.create("meta", v92_, "meta", nil)
	end
	local v94_ = string.format("meta.clients.client(%d)", self.testClientIndex - 1)
	v93_:setInt(v94_ .. "#clientIndex", self.testClientIndex)
	v93_:setFloat(v94_ .. "#duration", g_time / 1000 / 60)
	v93_:setInt(v94_ .. "#numCases", self.clientNumTestCases)
	v93_:setInt(v94_ .. "#numCasesSuccess", self.clientNumTestCasesSuccess)
	v93_:setInt(v94_ .. "#numCasesFailed", self.clientNumTestCasesFailed)
	v93_:setInt(v94_ .. "#luaMemory", collectgarbage("count"))
	if self.currentTestCase ~= nil then
		local v95_ = self.currentTestCase
		local v96_ = string.format("meta.results.testCase(%d)", v95_.index - 1)
		v93_:setInt(v96_ .. "#index", v95_.index)
		v93_:setInt(v96_ .. "#clientIndex", self.testClientIndex)
		v93_:setString(v96_ .. "#result", GameTestCase.getResultName(v95_.result))
		v93_:setString(v96_ .. "#reason", v95_.resultReason)
		v93_:setString(v96_ .. "#taskName", v95_:getName())
		v93_:setString(v96_ .. "#description", v95_:getDescription())
		v93_:setString(v96_ .. "#descriptionShort", v95_:getShortDescription())
	end
	if self.testClientIndex == 1 then
		if not v93_:hasProperty("meta#totalTestCases") then
			v93_:setInt("meta#totalTestCases", self.totalNumTestCases)
		end
		v93_:setString("meta#gameVersion", g_gameVersionDisplay)
		v93_:setString("meta#gameTitle", g_gameTitle)
		v93_:setString("meta#gameDirectory", getAppBasePath())
		v93_:setInt("meta#svnRevision", self.svnRevision)
		v93_:setInt("meta.clients#numClients", self.numTestClients)
		for _, v97_ in ipairs(GameTestManager.registeredTestCases) do
			if v97_.fillMetaData ~= nil then
				v97_.fillMetaData(v93_, "meta")
			end
		end
	end
	v93_:save()
	v93_:delete()
	self:print("Saved meta data to \'%s\'", v92_)
end

-- Local values: minutes, hours, durationStr
function GameTestManager:draw(dt)
	if self.currentTestCase ~= nil then
		local v99_ = g_time / 1000 / 60
		local v100_ = v99_ / 60
		local v101_ = math.floor(v100_)
		local v102_ = string.format("%02d:%02dh", v101_, v99_ - v101_ * 60)
		setTextAlignment(RenderText.ALIGN_CENTER)
		setTextBold(true)
		setTextColor(1, 1, 1, 1)
		renderText(0.5, 0.2, 0.025, string.format("Test Client %d/%d (%d failed - %d success - %d waiting - %s)", self.testClientIndex, self.numTestClients, self.clientNumTestCasesFailed, self.clientNumTestCasesSuccess, self.clientNumTestCasesInPool, v102_))
		renderText(0.5, 0.175, 0.025, self.currentTestCase:getFullName())
		renderText(0.5, 0.15, 0.025, self.currentTestCase:getDescription())
		setTextAlignment(RenderText.ALIGN_LEFT)
	end
end
function GameTestManager.print(_, p103_, ...)
	print("   GameTestManager: " .. string.format(p103_, ...))
end

-- Local values: vehicles, setupByType, usedVehicles, _, vehicle, rootVehicle, vehicleToIndex, name, index, childVehicle, rootNode, zOffset, output, workType, _, childVehicle, filename, x, y, z, _, _, minZ, typeNameLower, _, childVehicle, implements, _, implement, out, workType, setups, _, setup
function GameTestManager:consoleCommandPrintVehicleSetups()
	local v104_ = g_currentMission.vehicleSystem.vehicles
	local v105_ = {}
	local v106_ = {
		["CULTIVATION"] = {},
		["SOWING"] = {},
		["COMBINE_HARVESTER"] = {},
		["SPRAYING"] = {},
		["MOWING"] = {},
		["PLOWING"] = {}
	}
	for _, v107_ in ipairs(v104_) do
		local v_u_108_ = v107_.rootVehicle
		if v105_[v_u_108_] == nil then
			v105_[v_u_108_] = true
			local v109_ = v_u_108_:getName()
			table.sort(v_u_108_.childVehicles, function(p110_, _)
				-- upvalues: (copy) v_u_108_
				return p110_ == v_u_108_
			end)
			local v111_ = {}
			for v112_, v113_ in ipairs(v_u_108_.childVehicles) do
				if v113_ ~= v_u_108_ then
					v109_ = v109_ .. " + " .. v113_:getName()
				end
				v111_[v113_] = v112_
			end
			local v114_ = v_u_108_.rootNode
			local v115_ = 0
			local v116_ = ""
			local v117_ = nil
			for _, v118_ in ipairs(v_u_108_.childVehicles) do
				local v119_ = v118_.configFileName
				if string.startsWith(v119_, "data") then
					v119_ = "$" .. v119_
				end
				local v120_, v121_, v122_ = localToLocal(v118_.rootNode, v114_, 0, 0, 0)
				local _, _, v123_ = localToLocal(v118_.rootNode, v114_, 0, 0, -v118_.size.length * 0.5 + v118_.size.lengthOffset)
				v115_ = math.min(v115_, v123_)
				v116_ = v116_ .. string.format("            <vehicle xmlFilename=\"%s\" offset=\"%.3f %.3f %.3f\" rotationOffset=\"%.3f\"/>\n", v119_, v120_, v121_, v122_, 0)
				local v124_ = string.lower(v118_.typeName)
				if string.contains(v124_, "combine") then
					v117_ = "COMBINE_HARVESTER"
				elseif string.contains(v124_, "sowingmachine") then
					v117_ = "SOWING"
				elseif string.contains(v124_, "cultivator") then
					v117_ = "CULTIVATION"
				elseif string.contains(v124_, "sprayer") then
					v117_ = "SPRAYING"
				elseif string.contains(v124_, "mower") then
					v117_ = "MOWING"
				elseif string.contains(v124_, "plow") then
					v117_ = "PLOWING"
				end
			end
			for _, v125_ in ipairs(v_u_108_.childVehicles) do
				if v125_.getAttachedImplements ~= nil then
					local v126_ = v125_:getAttachedImplements()
					for _, v127_ in ipairs(v126_) do
						v116_ = v116_ .. string.format("\n            <attachment rootVehicleId=\"%d\" attachmentId=\"%d\" jointIndex=\"%d\" inputAttacherJointIndex=\"%d\"/>\n", v111_[v125_], v111_[v127_.object], v127_.jointDescIndex, v127_.inputJointDescIndex)
					end
				end
			end
			local v128_ = (string.format("        <vehicleSetup name=\"%s\" zOffset=\"%.1f\">\n", v109_, (math.abs(v115_))) .. v116_) .. "        </vehicleSetup>"
			if v117_ ~= nil then
				local v129_ = v106_[v117_]
				table.insert(v129_, v128_)
			end
		end
	end
	local v130_ = "\n"
	for v131_, v132_ in pairs(v106_) do
		if #v132_ > 0 then
			local v133_ = ((v130_ .. string.format("<testCases className=\"GameTestCaseAIFieldWork\" workType=\"%s\">\n", v131_)) .. "    <spawnPositions useBasePositions=\"true\" />\n\n") .. "    <vehicleSetups>\n"
			for _, v134_ in ipairs(v132_) do
				v133_ = v133_ .. v134_ .. "\n"
			end
			v130_ = (v133_ .. "    </vehicleSetups>\n") .. "</testCases>\n\n"
		end
	end
	print(v130_)
end

-- Local values: _, class
function GameTestManager.registerXMLPaths(schema)
	schema:register(XMLValueType.STRING, "testing.testCases(?)#className", "LUA class name of the test")
	for _, v136_ in ipairs(GameTestManager.registeredTestCases) do
		if v136_.registerXMLPaths ~= nil then
			v136_.registerXMLPaths(schema, "testing.testCases(?)")
		end
	end
end
Mission00.getIsTourSupported = Utils.overwrittenFunction(Mission00.getIsTourSupported, function(_, _)
	return false
end)
FieldManager.addFieldUpdateTask = Utils.overwrittenFunction(FieldManager.addFieldUpdateTask, function(_, _, _) end)
BaseMission.loadMapFinished = Utils.overwrittenFunction(BaseMission.loadMapFinished, function(p137_, p138_, p139_, ...)
	g_gameTestManager:onLoadMapFinished(p139_)
	p138_(p137_, p139_, ...)
end)
TypeManager.finalizeTypes = Utils.prependedFunction(TypeManager.finalizeTypes, function(p140_, _)
	if p140_.typeName == "vehicle" then
		PowerTakeOffs.loadPowerTakeOffsFromXML = Utils.overwrittenFunction(PowerTakeOffs.loadPowerTakeOffsFromXML, function(_, _) end)
		Wheels.loadHubsFromXML = Utils.overwrittenFunction(Wheels.loadHubsFromXML, function(p141_, _)
			p141_.spec_wheels.hubs = {}
		end)
		SharedLight.loadFromXML = Utils.overwrittenFunction(SharedLight.loadFromXML, function(_, _)
			return false
		end)
		DynamicallyLoadedParts.onLoad = Utils.overwrittenFunction(DynamicallyLoadedParts.onLoad, function(p142_, _)
			local v143_ = p142_.spec_dynamicallyLoadedParts
			v143_.sharedLoadRequestIds = {}
			v143_.parts = {}
		end)
		WheelVisualPart.loadFromXML = Utils.overwrittenFunction(WheelVisualPart.loadFromXML, function(_, _)
			return false
		end)
		Crawlers.loadCrawlerFromXML = Utils.overwrittenFunction(Crawlers.loadCrawlerFromXML, function(_, _)
			return false
		end)
	elseif p140_.typeName == "placeable" then
		PlaceableConstructible.onFinalizePlacement = Utils.overwrittenFunction(PlaceableConstructible.onFinalizePlacement, function(p144_, p145_, p146_, ...)
			local v147_ = p144_.spec_constructible
			if v147_.stateIndexPending == nil then
				v147_.startStateIndex = #v147_.stateMachine
			else
				v147_.stateIndexPending = #v147_.stateMachine
			end
			return p145_(p144_, p146_, ...)
		end)
		AnimatedObject.setAnimTime = Utils.overwrittenFunction(AnimatedObject.setAnimTime, function(p148_, p149_, _, ...)
			return p149_(p148_, 1, ...)
		end)
	end
end)
Platform.hasWardrobe = false
g_gameTestManager = GameTestManager.new()
