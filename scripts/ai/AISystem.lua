-- Local values: AISystem_mt
AISystem = {}
AISystem.xmlSchema = nil
AISystem.COSTMAP_MAX_VALUE = 16
AISystem.NEXT_JOB_ID = 0
local AISystem_mt = Class(AISystem)

-- Local values: maxWidth, maxTurningRadius, maxHeight
function AISystem.onCreateAIRoadSpline(_, node)
	if node ~= nil and node ~= 0 then
		local v3_ = getUserAttribute
		local v4_ = tonumber(v3_(node, "maxWidth"))
		local v5_ = getUserAttribute
		local v6_ = tonumber(v5_(node, "maxTurningRadius"))
		local v7_ = getUserAttribute
		local v8_ = tonumber(v7_(node, "maxHeight"))
		g_currentMission.aiSystem:addRoadSpline(node, v4_, v6_, v8_)
	end
end

-- Upvalues: AISystem_mt
-- Local values: self
function AISystem.new(isServer, mission, customMt)
	-- upvalues: (copy) AISystem_mt
	local v12_ = customMt or AISystem_mt
	local v13_ = setmetatable({}, v12_)
	v13_.isServer = isServer
	v13_.mission = mission
	v13_.filename = "vehicleNavigationCostmap.dat"
	v13_.navigationMap = nil
	v13_.planningDebugEnabled = false
	v13_.lastPlanningBitVectorMap = nil
	v13_.activeAgents = {}
	v13_.jobsToRemove = {}
	v13_.activeJobs = {}
	v13_.activeJobVehicles = {}
	v13_.delayedRoadSplines = {}
	AISystem.xmlSchema = XMLSchema.new("aiSystem")
	v13_:registerXMLPaths(AISystem.xmlSchema)
	return v13_
end

function AISystem:registerXMLPaths(schema)
	schema:register(XMLValueType.ANGLE, "aiSystem.maxSlopeAngle", "Maximum terrain angle in degrees which is classified as drivable", 15)
	schema:register(XMLValueType.STRING, "aiSystem.blockedAreaInfoLayer#name", "Map info layer name defining areas which are blocked for AI driving", "navigationCollision")
	schema:register(XMLValueType.INT, "aiSystem.blockedAreaInfoLayer#channel", "Map info layer channel defining areas which are blocked for AI driving", 0)
	schema:register(XMLValueType.FLOAT, "aiSystem.vehicleMaxHeight", "Maximum expected vehicle height used for generating the costmap, e.g. relevant for overhanging collisions", 4)
	schema:register(XMLValueType.FLOAT, "aiSystem.vehicleMaxHeightSpline", "Default maximum vehicle height allowed for driving on splines, can be adjusted per spline via userAttribute \'maxHeight\'", 10)
	schema:register(XMLValueType.BOOL, "aiSystem.isLeftHandTraffic", "Map has left-hand traffic. This setting will only affect collision avoidance, traffic and ai splines need to be set up as left hand in map itself", false)
end

-- Local values: i, job, jobId, i, job
function AISystem:delete()
	if self.isServer then
		for v16_ = #self.jobsToRemove, 1, -1 do
			local v17_ = self.jobsToRemove[v16_]
			local v18_ = v17_.jobId
			table.removeElement(self.activeJobs, v17_)
			table.remove(self.jobsToRemove, v16_)
			g_messageCenter:publish(MessageType.AI_JOB_REMOVED, v18_)
		end
		for v19_ = #self.activeJobs, 1, -1 do
			self:stopJob(self.activeJobs[v19_], AIMessageErrorUnknown.new())
		end
	end
	if self.navigationMap ~= nil then
		delete(self.navigationMap)
		self.navigationMap = nil
	end
	if self.debug ~= nil and self.debug.marker ~= nil then
		g_debugManager:removeElement(self.debug.marker)
		self.debug.marker = nil
	end
	if self.lastPlanningBitVectorMap ~= nil then
		delete(self.lastPlanningBitVectorMap)
		self.lastPlanningBitVectorMap = nil
	end
	self.activeAgents = {}
	g_messageCenter:unsubscribeAll(self)
	removeConsoleCommand("gsAISetTarget")
	removeConsoleCommand("gsAISetLastTarget")
	removeConsoleCommand("gsAIStart")
	removeConsoleCommand("gsAIEnableDebug")
	removeConsoleCommand("gsAISplinesShow")
	removeConsoleCommand("gsAISplinesCheckInterference")
	removeConsoleCommand("gsAIStationsShow")
	removeConsoleCommand("gsAIObstaclesShow")
	removeConsoleCommand("gsAICostsShow")
	removeConsoleCommand("gsAICostsUpdate")
	removeConsoleCommand("gsAICostsExport")
	removeConsoleCommand("gsAIAgentSetState")
end

-- Local values: relFilename, filepath, xmlFileAISystem
function AISystem:loadMapData(xmlFile, missionInfo, baseDirectory)
	if g_addCheatCommands then
		if self.isServer then
			addConsoleCommand("gsAISetTarget", "Sets AI Target", "consoleCommandAISetTarget", self)
			addConsoleCommand("gsAISetLastTarget", "Sets AI Target to last position", "consoleCommandAISetLastTarget", self)
			addConsoleCommand("gsAIStart", "Starts driving to target", "consoleCommandAIStart", self)
			if g_isDevelopmentVersion then
				addConsoleCommand("gsAIAgentSetState", "Sets the AI Agent State", "consoleCommandAIAgentSetState", self)
			end
		end
		addConsoleCommand("gsAIEnableDebug", "Enables AI debugging", "consoleCommandAIEnableDebug", self)
		addConsoleCommand("gsAISplinesShow", "Toggle AI system spline visibility", "consoleCommandAIToggleSplineVisibility", self)
		addConsoleCommand("gsAISplinesCheckInterference", "Check if AI splines interfere with any objects", "consoleCommandAICheckSplineInterference", self, "[stepLength]; [heightOffset]; [defaultSplineWidth]; [defaultSplineHeight]")
		addConsoleCommand("gsAIStationsShow", "Toggle AI system stations ai nodes visibility", "consoleCommandAIToggleAINodeDebug", self)
		addConsoleCommand("gsAIObstaclesShow", "Shows the obstacles around the camera", "consoleCommandAIShowObstacles", self)
		addConsoleCommand("gsAIPlanningDebug", "Shows the last planning bit vector map", "consoleCommandShowPlanningDebug", self)
		addConsoleCommand("gsAICostsShow", "Shows the costs per cell", "consoleCommandAIShowCosts", self)
		addConsoleCommand("gsAICostsUpdate", "Update costmap given width around the camera", "consoleCommandAISetAreaDirty", self, "[width=30]")
		addConsoleCommand("gsAICostsExport", "Export costmap to image file", "consoleCommandAICostmapExport", self)
	end
	self.cellSizeMeters = 1
	self.maxSlopeAngle = 0.2617993877991494
	self.infoLayerName = "navigationCollision"
	self.infoLayerChannel = 0
	self.aiDrivableCollisionMask = CollisionFlag.AI_DRIVABLE
	self.obstacleCollisionMask = CollisionFlag.AI_BLOCKING
	self.vehicleMaxHeight = 4
	self.defaultVehicleMaxWidth = 6
	self.defaultVehicleMaxTurningRadius = 20
	self.defaultVehicleMaxHeightSpline = 10
	self.isLeftHandTraffic = false
	local v23_ = getXMLString(xmlFile, "map.aiSystem#filename")
	if v23_ ~= nil then
		local v24_ = Utils.getFilename(v23_, baseDirectory)
		if v24_ ~= nil then
			local v25_ = XMLFile.load("mapAISystem", v24_, AISystem.xmlSchema)
			if v25_ ~= nil then
				self.maxSlopeAngle = v25_:getValue("aiSystem.maxSlopeAngle") or self.maxSlopeAngle
				self.infoLayerName = v25_:getValue("aiSystem.blockedAreaInfoLayer#name") or self.infoLayerName
				self.infoLayerChannel = v25_:getValue("aiSystem.blockedAreaInfoLayer#channel") or self.infoLayerChannel
				self.vehicleMaxHeight = v25_:getValue("aiSystem.vehicleMaxHeight") or self.vehicleMaxHeight
				self.defaultVehicleMaxHeightSpline = v25_:getValue("aiSystem.vehicleMaxHeightSpline") or self.defaultVehicleMaxHeightSpline
				self.isLeftHandTraffic = Utils.getNoNil(v25_:getValue("aiSystem.isLeftHandTraffic"), self.isLeftHandTraffic)
				v25_:delete()
			end
		end
	end
	self.debugEnabled = g_isDevelopmentVersion
	self.debug = {}
	self.debug.target = nil
	self.debug.isCostRenderingActive = false
	self.debug.colors = {}
	self.debug.colors.default = {
		0,
		1,
		0,
		1
	}
	self.debug.colors.blocking = {
		1,
		0,
		0,
		1
	}
	self.debug.colors.spline = {
		0,
		0,
		1,
		1
	}
	self.activeJobs = {}
	self.jobsToRemove = {}
	self.splinesVisible = false
	self.roadSplines = {}
end

-- Local values: delayedSplineData
function AISystem:addRoadSpline(spline, maxWidth, maxTurningRadius, maxHeight)
	if self.isServer and spline ~= nil then
		if self.navigationMap ~= nil then
			I3DUtil.iterateRecursively(spline, function(p31_)
				-- upvalues: (copy) maxWidth, (copy) self, (copy) maxHeight, (copy) maxTurningRadius
				if I3DUtil.getIsSpline(p31_) and getUserAttribute(p31_, "isAISpline") ~= false then
					local v32_ = maxWidth or self.defaultVehicleMaxWidth
					local v33_ = maxHeight or self.defaultVehicleMaxHeightSpline
					local v34_ = maxTurningRadius or self.defaultVehicleMaxTurningRadius
					addRoadsToVehicleNavigationMap(self.navigationMap, p31_, v32_, v33_, v34_)
					setVisibility(p31_, self.splinesVisible)
					table.addElement(self.roadSplines, p31_)
				end
			end, true)
			return
		end
		table.addElement(self.delayedRoadSplines, {
			["spline"] = spline,
			["maxWidth"] = maxWidth,
			["maxTurningRadius"] = maxTurningRadius,
			["maxHeight"] = maxHeight
		})
	end
end

-- Local values: _, delayedSplineData
function AISystem:removeRoadSpline(spline)
	if self.isServer and spline ~= nil then
		if self.navigationMap ~= nil then
			removeRoadsFromVehicleNavigationMap(self.navigationMap, spline)
			setVisibility(spline, false)
			table.removeElement(self.roadSplines, spline)
			return
		end
		for _, v37_ in ipairs(self.delayedRoadSplines) do
			if v37_.spline == spline then
				table.removeElement(self.delayedRoadSplines, v37_)
				return
			end
		end
	end
end

-- Local values: blockingRegionId
function AISystem:addBlockingRegion(x, y, z, rx, ry, rz, sizeX, sizeY, sizeZ, stopDistance, callbackFuncName, callbackTarget)
	if not self.isServer then
		return nil
	end
	if self.navigationMap ~= nil then
		return addVehicleNavigationWorldBlockingRegion(self.navigationMap, x, y, z, rx, ry, rz, sizeX, sizeY, sizeZ, stopDistance, callbackFuncName, callbackTarget)
	end
	Logging.warning("AISystem:addBlockingRegion(): vehicle navigation not initialized yet/anymore")
	printCallstack()
	return nil
end

function AISystem:removeBlockingRegion(blockingRegionId)
	if self.isServer then
		if self.navigationMap ~= nil and blockingRegionId ~= nil then
			removeVehicleNavigationWorldBlockingRegion(self.navigationMap, blockingRegionId)
		end
	else
		return
	end
end

function AISystem:setBlockingRegionState(blockingRegionId, isBlocking)
	if self.isServer then
		if self.navigationMap == nil then
			Logging.warning("AISystem:setBlockingRegionState(): vehicle navigation not initialized yet/anymore")
			printCallstack()
		else
			setVehicleNavigationWorldBlockingRegionState(self.navigationMap, blockingRegionId, isBlocking)
		end
	else
		return
	end
end

-- Local values: roadSplineRootNodeId, i, delayedSplineData, missionInfo, loadFromSave, path, success
function AISystem:onTerrainLoad(terrainNode)
	if self.isServer then
		self.navigationMap = createVehicleNavigationMap(self.cellSizeMeters, terrainNode, self.maxSlopeAngle, self.infoLayerName, self.infoLayerChannel, self.aiDrivableCollisionMask, self.obstacleCollisionMask, self.vehicleMaxHeight, self.isLeftHandTraffic)
		if self.mission.trafficSystem ~= nil then
			self:addRoadSpline(self.mission.trafficSystem.rootNodeId)
		end
		for _ = #self.delayedRoadSplines, 1, -1 do
			local v58_ = table.remove(self.delayedRoadSplines, 1)
			self:addRoadSpline(v58_.spline, v58_.maxWidth, v58_.maxTurningRadius, v58_.maxHeight)
		end
		local v59_ = self.mission.missionInfo
		local v60_ = false
		if v59_.isValid and v59_:getIsNavigationCollisionValid(self.mission) then
			local v61_ = v59_.savegameDirectory .. "/" .. self.filename
			if loadVehicleNavigationCostMapFromFile(self.navigationMap, v61_) then
				Logging.info("Loaded navigation cost map from savegame")
				v60_ = true
			end
		end
		if not v60_ then
			g_messageCenter:subscribeOneshot(MessageType.CURRENT_MISSION_START, AISystem.onMissionStarted, self)
		end
		g_messageCenter:publishDelayedAfterFrames(MessageType.AI_SYSTEM_LOADED, 2)
	end
	return true
end

-- Local values: worldSizeHalf
function AISystem:onMissionStarted(isNewSavegame)
	local v63_ = 0.5 * self.mission.terrainSize
	Logging.info("No vehicle navigation cost map found. Start scanning map...")
	updateVehicleNavigationMap(self.navigationMap, -v63_, v63_, -v63_, v63_)
end

-- Local values: xmlFile, x, y, z, dirX, dirY, dirZ
function AISystem:loadFromXMLFile(xmlFilename)
	local v66_ = XMLFile.load("aiSystemXML", xmlFilename)
	if v66_ ~= nil then
		local v67_ = v66_:getFloat("aiSystem.debug.target#posX")
		local v68_ = v66_:getFloat("aiSystem.debug.target#posY")
		local v69_ = v66_:getFloat("aiSystem.debug.target#posZ")
		local v70_ = v66_:getFloat("aiSystem.debug.target#dirX")
		local v71_ = v66_:getFloat("aiSystem.debug.target#dirY")
		local v72_ = v66_:getFloat("aiSystem.debug.target#dirZ")
		if v67_ ~= nil and (v68_ ~= nil and (v69_ ~= nil and (v70_ ~= nil and (v71_ ~= nil and v72_ ~= nil)))) then
			self.debug.target = {}
			self.debug.target.x = v67_
			self.debug.target.y = v68_
			self.debug.target.z = v69_
			self.debug.target.dirX = v70_
			self.debug.target.dirY = v71_
			self.debug.target.dirZ = v72_
		end
		v66_:delete()
	end
end

-- Local values: xmlFile, hasData, target
function AISystem:save(xmlFilename, usedModNames)
	local v75_ = XMLFile.create("aiSystemXML", xmlFilename, "aiSystem")
	if v75_ ~= nil then
		local v76_
		if self.debug.target == nil then
			v76_ = false
		else
			local v77_ = self.debug.target
			v75_:setFloat("aiSystem.debug.target#posX", v77_.x)
			v75_:setFloat("aiSystem.debug.target#posY", v77_.y)
			v75_:setFloat("aiSystem.debug.target#posZ", v77_.z)
			v75_:setFloat("aiSystem.debug.target#dirX", v77_.dirX)
			v75_:setFloat("aiSystem.debug.target#dirY", v77_.dirY)
			v75_:setFloat("aiSystem.debug.target#dirZ", v77_.dirZ)
			v76_ = true
		end
		if v76_ then
			v75_:save()
		end
		v75_:delete()
	end
end

function AISystem:getNavigationMapFilename()
	return self.filename
end

function AISystem:getNavigationMap()
	return self.navigationMap
end

-- Local values: i, job, jobId, _, job
function AISystem:update(dt)
	for v82_ = #self.jobsToRemove, 1, -1 do
		local v83_ = self.jobsToRemove[v82_]
		local v84_ = v83_.jobId
		table.removeElement(self.activeJobs, v83_)
		table.remove(self.jobsToRemove, v82_)
		g_messageCenter:publish(MessageType.AI_JOB_REMOVED, v84_)
	end
	for _, v85_ in ipairs(self.activeJobs) do
		v85_:update(dt)
		if self.isServer and g_currentMission.isRunning then
			v85_:updateCost(dt)
		end
	end
end

-- Local values: _, job
function AISystem:onClientJoined(connection)
	for _, v88_ in ipairs(self.activeJobs) do
		connection:sendEvent(AIJobStartEvent.new(v88_, v88_.startedFarmId))
	end
end

function AISystem:setAreaDirty(minX, maxX, minZ, maxZ)
	if self.navigationMap ~= nil then
		updateVehicleNavigationMap(self.navigationMap, minX, maxX, minZ, maxZ)
	end
end

function AISystem:addAgent(agentId, vehicle)
	self.activeAgents[agentId] = vehicle
end

function AISystem:removeAgent(agentId)
	self.activeAgents[agentId] = nil
end

function AISystem:getVehicleByAgent(agentId)
	return self.activeAgents[agentId]
end

function AISystem:removeJob(job)
	local v103_ = self.jobsToRemove
	table.insert(v103_, job)
end

function AISystem:addJob(job)
	local v106_ = self.activeJobs
	table.insert(v106_, job)
end

function AISystem:getNumActiveJobs()
	return #self.activeJobs
end

function AISystem:getActiveJobs()
	return self.activeJobs
end

function AISystem:startJob(job, startFarmId)
	local v112_ = self.isServer
	assert(v112_)
	if self.isServer then
		job:setId(AISystem.NEXT_JOB_ID)
		AISystem.NEXT_JOB_ID = AISystem.NEXT_JOB_ID + 1
		g_server:broadcastEvent(AIJobStartEvent.new(job, startFarmId))
		self:startJobInternal(job, startFarmId)
	end
end

function AISystem:startJobInternal(job, startFarmId)
	job:start(startFarmId)
	self:addJob(job)
	g_messageCenter:publish(MessageType.AI_JOB_STARTED, job, startFarmId)
end

function AISystem:stopJob(job, aiMessage)
	if self.isServer then
		self:stopJobInternal(job, aiMessage)
		g_server:broadcastEvent(AIJobStopEvent.new(job, aiMessage))
	else
		g_client:getServerConnection():sendEvent(AIJobStopEvent.new(job, aiMessage))
	end
end

function AISystem:stopJobInternal(job, aiMessage)
	job:stop(aiMessage)
	self:removeJob(job)
	g_messageCenter:publish(MessageType.AI_JOB_STOPPED, job, aiMessage)
end

function AISystem:skipCurrentTask(job)
	g_client:getServerConnection():sendEvent(AIJobSkipTaskEvent.new(job))
end

function AISystem:skipCurrentTaskInternal(job)
	job:skipCurrentTask()
end

-- Local values: job
function AISystem:stopJobById(jobId, aiMessage, noEventSend)
	local v128_ = self:getJobById(jobId)
	if v128_ == nil then
		return false
	end
	self:stopJob(v128_, aiMessage, noEventSend)
	return true
end

-- Local values: _, job
function AISystem:getJobById(jobId)
	for _, v131_ in ipairs(self.activeJobs) do
		if v131_.jobId == jobId then
			return v131_
		end
	end
	return nil
end

function AISystem:addJobVehicle(vehicle)
	table.addElement(self.activeJobVehicles, vehicle)
end

function AISystem:removeJobVehicle(vehicle)
	table.removeElement(self.activeJobVehicles, vehicle)
end

function AISystem:getAILimitedReached()
	return #self.activeJobVehicles >= g_currentMission.maxNumHirables
end

-- Local values: costs, isBlocking
function AISystem:getIsPositionReachable(x, y, z)
	if self.navigationMap == nil or not self.isServer then
		return true
	end
	local v141_, v142_
	if math.abs(x) <= self.mission.mapWidth * 0.5 and math.abs(z) <= self.mission.mapHeight * 0.5 then
		v141_, v142_ = getVehicleNavigationMapCostAtWorldPos(self.navigationMap, x, y, z)
	else
		v141_ = nil
		v142_ = true
	end
	return v141_ ~= 255 and not v142_ and true or false
end

-- Local values: x, _, z, object, cellSizeHalf, range, terrainSizeHalf, minX, minZ, maxX, maxZ, worldPosX, worldPosY, worldPosZ, terrainNode, cost, isBlocking, color, textSize, r, g, b, stepZ, stepX
function AISystem:drawDebug()
	if self.debug.isCostRenderingActive and (not g_gui:getIsGuiVisible() or g_gui.currentGuiName == "ConstructionScreen") then
		local v144_, _, v145_ = getWorldTranslation(g_cameraManager:getActiveCamera())
		if g_localPlayer:getCurrentVehicle() ~= nil then
			local v146_ = g_localPlayer:getCurrentVehicle()
			if g_localPlayer:getCurrentVehicle().selectedImplement ~= nil then
				v146_ = g_localPlayer:getCurrentVehicle().selectedImplement.object
			end
			local v147_
			v144_, v147_, v145_ = getWorldTranslation(v146_.components[1].node)
		end
		local v148_ = self.cellSizeMeters * 0.5
		local v149_ = v144_ / self.cellSizeMeters
		local v150_ = math.floor(v149_) * self.cellSizeMeters + v148_
		local v151_ = v145_ / self.cellSizeMeters
		local v152_ = math.floor(v151_) * self.cellSizeMeters + v148_
		local v153_ = 15 * self.cellSizeMeters
		local v154_ = self.mission.terrainSize * 0.5
		local v155_ = v150_ - v153_
		local v156_ = -v154_ + v148_
		local v157_ = math.max(v155_, v156_)
		local v158_ = v152_ - v153_
		local v159_ = -v154_ + v148_
		local v160_ = math.max(v158_, v159_)
		local v161_ = v150_ + v153_
		local v162_ = v154_ - v148_
		local v163_ = math.min(v161_, v162_)
		local v164_ = v152_ + v153_
		local v165_ = v154_ - v148_
		local v166_ = math.min(v164_, v165_)
		local v167_ = g_terrainNode
		local v168_ = getCorrectTextSize(0.015)
		for v169_ = v160_, v166_, self.cellSizeMeters do
			for v170_ = v157_, v163_, self.cellSizeMeters do
				local v171_ = getTerrainHeightAtWorldPos(v167_, v170_, 0, v169_)
				local v172_, v173_ = getVehicleNavigationMapCostAtWorldPos(self.navigationMap, v170_, v171_, v169_)
				local v174_ = self.debug.colors.default
				if v173_ then
					v174_ = self.debug.colors.blocking
				else
					local v175_, v176_, v177_ = Utils.getGreenRedBlendedColor(v172_ / AISystem.COSTMAP_MAX_VALUE)
					v174_[1] = v175_
					v174_[2] = v176_
					v174_[3] = v177_
				end
				Utils.renderTextAtWorldPosition(v170_, v171_, v169_, string.format("%.1f", v172_), v168_, 0, v174_)
			end
		end
	end
end

function AISystem:addObstacle(node, centerOffsetX, centerOffsetY, centerOffsetZ, sizeX, sizeY, sizeZ, brakeAcceleration, isPassable)
	if self.isServer and (self.navigationMap ~= nil and node ~= nil) then
		local v188_ = Utils.getNoNil(isPassable, true)
		addVehicleNavigationPhysicsObstacle(self.navigationMap, node, centerOffsetX or 0, centerOffsetY or 0, centerOffsetZ or 0, sizeX or 0, sizeY or 0, sizeZ or 0, brakeAcceleration or 0)
		if not v188_ then
			setVehicleNavigationPhysicsObstacleIsPassable(self.navigationMap, node, false)
		end
	end
end

function AISystem:removeObstacle(node)
	if self.isServer and (self.navigationMap ~= nil and node ~= nil) then
		removeVehicleNavigationPhysicsObstacle(self.navigationMap, node)
	end
end

function AISystem:setObstacleIsPassable(node, isPassable)
	if self.isServer and (self.navigationMap ~= nil and node ~= nil) then
		setVehicleNavigationPhysicsObstacleIsPassable(self.navigationMap, node, isPassable)
	end
end

-- Local values: splines, _, roadSplineOrTG
function AISystem:getRoadSplines(existingTable)
	local v_u_196_ = existingTable or {}
	for _, v197_ in ipairs(self.roadSplines) do
		if I3DUtil.getIsSpline(v197_) then
			v_u_196_[v197_] = true
		end
		I3DUtil.iterateRecursively(v197_, function(p198_)
			-- upvalues: (copy) v_u_196_
			if I3DUtil.getIsSpline(p198_) then
				v_u_196_[p198_] = true
			end
		end)
	end
	return v_u_196_
end

-- Local values: bitVectorMapSize, cellSize
function AISystem:setPlanningBitVectorMap(bitVectorMap)
	if self.lastPlanningBitVectorMap ~= nil then
		delete(self.lastPlanningBitVectorMap)
	end
	if self.debugBitVectorMap ~= nil then
		g_debugManager:removeElement(self.debugBitVectorMap)
		self.debugBitVectorMap = nil
	end
	self.lastPlanningBitVectorMap = bitVectorMap
	if self.debugBitVectorMap == nil then
		local v_u_201_ = getBitVectorMapSize(bitVectorMap)
		local v_u_202_ = g_currentMission.terrainSize / v_u_201_
		self.debugBitVectorMap = DebugBitVectorMap.newSimple(250, v_u_202_, false, 0.1, 0.1, false)
		self.debugBitVectorMap.displayLegend = false
		self.debugBitVectorMap:createWithCustomFunc(function(_, p203_, p204_, p205_, _, _, p206_)
			-- upvalues: (copy) v_u_202_, (copy) v_u_201_, (copy) self
			local v207_ = (p203_ + p205_) * 0.5 / v_u_202_ + v_u_201_ * 0.5
			local v208_ = (p204_ + p206_) * 0.5 / v_u_202_ + v_u_201_ * 0.5
			return getBitVectorMapPoint(self.lastPlanningBitVectorMap, v207_, v208_, 0, 1) == 1 and 1 or nil
		end)
		function self.debugBitVectorMap.getShouldBeDrawn()
			-- upvalues: (copy) self
			return self.planningDebugEnabled
		end
		g_debugManager:addElement(self.debugBitVectorMap)
	end
end

function AISystem:consoleCommandShowPlanningDebug()
	self.planningDebugEnabled = not self.planningDebugEnabled
	Logging.info("AI Planning debug " .. (self.planningDebugEnabled and "on" or "off"))
end

function AISystem:consoleCommandAIShowCosts()
	if self.isServer then
		self.debug.isCostRenderingActive = not self.debug.isCostRenderingActive
		if self.debug.isCostRenderingActive then
			g_debugManager:addDrawable(self)
			return "showCosts=true"
		else
			g_debugManager:removeDrawable(self)
			return "showCosts=false"
		end
	else
		return "gsAICostsShow is a server-only command"
	end
end

-- Local values: x, y, z, dirX, dirY, dirZ, _, localPlayer, yaw, normX, _, normZ
function AISystem:consoleCommandAISetTarget(offsetX, offsetZ)
	if not self.isServer then
		return "gsAISetTarget is a server-only command"
	end
	local v214_ = 0
	local v215_ = 0
	local v216_ = 0
	local v217_ = 1
	local v218_ = 0
	local v219_ = 0
	local v220_ = g_localPlayer
	if v220_:getIsInVehicle() then
		if v220_:getCurrentVehicle() == nil then
			v214_, v215_, v216_ = getWorldTranslation(g_cameraManager:getActiveCamera())
			local v221_
			v217_, v221_, v219_ = localDirectionToWorld(g_cameraManager:getActiveCamera(), 0, 0, -1)
		else
			v214_, v215_, v216_ = getWorldTranslation(v220_:getCurrentVehicle().rootNode)
			local v222_
			v217_, v222_, v219_ = localDirectionToWorld(v220_:getCurrentVehicle().rootNode, 0, 0, 1)
		end
	elseif v220_ ~= nil and (v220_:getIsControlled() and (v220_.rootNode ~= nil and v220_.rootNode ~= 0)) then
		local v223_
		v214_, v216_, v223_ = v220_:getMapPositionAndLookYaw()
		v215_ = getTerrainHeightAtWorldPos(g_terrainNode, v214_, 0, v216_)
		v217_, v219_ = MathUtil.getDirectionFromYRotation(v223_)
	end
	local v224_, _, v225_ = MathUtil.crossProduct(0, 1, 0, v217_, 0, v219_)
	local v226_ = tonumber(offsetX) or 0
	local v227_ = tonumber(offsetZ) or 0
	local v228_ = v214_ + v217_ * v227_ + v224_ * v226_
	local v229_ = v216_ + v219_ * v227_ + v225_ * v226_
	self.debug.target = {
		["x"] = v228_,
		["y"] = v215_,
		["z"] = v229_,
		["dirX"] = v217_,
		["dirY"] = v218_,
		["dirZ"] = v219_
	}
	if self.debug.marker ~= nil then
		g_debugManager:removeElement(self.debug.marker)
		self.debug.marker = nil
	end
	self.debug.marker = DebugFlag.new():create(v228_, v215_, v229_, v217_, v219_):setText("AI Target")
	g_debugManager:addElement(self.debug.marker, "AI")
	return "Set AI Target"
end

-- Local values: x, y, z, dirX, dirZ, marker
function AISystem:consoleCommandAISetLastTarget()
	if not self.isServer then
		return "gsAISetLastTarget is a server-only command"
	end
	if self.debug.target == nil then
		return "No last target found"
	end
	local v231_ = self.debug.target.x
	local v232_ = self.debug.target.y
	local v233_ = self.debug.target.z
	local v234_ = self.debug.target.dirX
	local v235_ = self.debug.target.dirZ
	local v236_ = self.debug.marker
	if v236_ ~= nil then
		v236_:create(v231_, v232_, v233_, v234_, v235_)
	end
	return "Set target to last target"
end

-- Local values: target, job, angle, success, errorMessage
function AISystem:consoleCommandAIStart()
	if not self.isServer then
		return "Only available on server"
	end
	if g_localPlayer:getCurrentVehicle() == nil then
		return "Please enter a vehicle first"
	end
	local v238_ = self.debug.target
	if v238_ == nil then
		return "Please set a target first"
	end
	local v239_ = g_currentMission.aiJobTypeManager:createJob(AIJobType.GOTO)
	local v240_ = MathUtil.getYRotationFromDirection(v238_.dirX, v238_.dirZ)
	v239_.vehicleParameter:setVehicle(g_localPlayer:getCurrentVehicle())
	v239_.positionAngleParameter:setPosition(v238_.x, v238_.z)
	v239_.positionAngleParameter:setAngle(v240_)
	v239_:setValues()
	local v241_, v242_ = v239_:validate(g_localPlayer.farmId)
	if not v241_ then
		return "Error: " .. tostring(v242_)
	end
	self:startJob(v239_, g_localPlayer.farmId)
	return "Started ai..."
end

-- Local values: fixedState
function AISystem:consoleCommandAIAgentSetState(state)
	if state == nil then
		Logging.error("No state given")
		print(string.format("Available states: %s", table.concatKeys(AgentState, " ")))
		return
	else
		if AISystem.getVehicleNavigationAgentNextCurvature == nil then
			AISystem.getVehicleNavigationAgentNextCurvature = getVehicleNavigationAgentNextCurvature
		end
		local v_u_244_ = AgentState[string.upper(state)]
		if v_u_244_ == nil then
			getVehicleNavigationAgentNextCurvature = AISystem.getVehicleNavigationAgentNextCurvature
		else
			function getVehicleNavigationAgentNextCurvature(...)
				-- upvalues: (copy) v_u_244_
				return 0, 0, v_u_244_
			end
		end
	end
end

function AISystem:consoleCommandAIEnableDebug()
	self.debugEnabled = not self.debugEnabled
	local v246_ = self.debugEnabled
	return "debugEnabled=" .. tostring(v246_)
end

-- Local values: debugMat, spline, r, g, b, debugSpline, spline
function AISystem:consoleCommandAIToggleSplineVisibility()
	if not self.isServer then
		return "gsAISplinesShow is a server-only command"
	end
	self.splinesVisible = not self.splinesVisible
	if self.splinesVisible then
		local v248_ = g_debugManager:getDebugMat()
		for v249_ in pairs(self:getRoadSplines()) do
			local v250_, v251_, v252_ = DebugUtil.getDebugColor(v249_):unpack()
			setMaterial(v249_, v248_, 0)
			setShaderParameter(v249_, "color", v250_, v251_, v252_, 0, false)
			setShaderParameter(v249_, "alpha", 1, 0, 0, 0, false)
			local v253_ = DebugSpline.new():createWithNode(v249_):setColorRGBA(v250_, v251_, v252_):setClipDistance(250)
			g_debugManager:addElement(v253_, "AISystemSplines")
		end
	else
		g_debugManager:removeGroup("AISystemSplines")
		for v254_ in pairs(self:getRoadSplines()) do
			setVisibility(v254_, false)
		end
	end
	if g_currentMission.trafficSystem ~= nil and g_currentMission.trafficSystem.rootNodeId ~= nil then
		setVisibility(g_currentMission.trafficSystem.rootNodeId, self.splinesVisible)
	end
	local v255_ = self.splinesVisible
	return "AISystem.splinesVisible=" .. tostring(v255_)
end

-- Local values: _, unloadingStation, x, _, _, _, unloadTrigger, text, gizmo, _, loadingStation, x, _, _, _, loadTrigger, text, gizmo, _, gizmo
function AISystem:consoleCommandAIToggleAINodeDebug()
	self.stationsAINodesVisible = not self.stationsAINodesVisible
	if self.stationsAINodesVisible then
		self.stationsAINodesDebugElements = {}
		for _, v257_ in pairs(g_currentMission.storageSystem:getUnloadingStations()) do
			if v257_:isa(UnloadingStation) then
				local v258_, _, _, _, v259_ = v257_:getAITargetPositionAndDirection(FillType.UNKNOWN)
				if v258_ ~= nil then
					local v260_ = "UnloadingStation: " .. v257_:getName()
					local v261_ = DebugGizmo.new():createWithNode(v259_.aiNode, v260_, nil, nil, nil, false)
					g_debugManager:addElement(v261_)
					local v262_ = self.stationsAINodesDebugElements
					table.insert(v262_, v261_)
				end
			end
		end
		for _, v263_ in pairs(g_currentMission.storageSystem:getLoadingStations()) do
			local v264_, _, _, _, v265_ = v263_:getAITargetPositionAndDirection(FillType.UNKNOWN)
			if v264_ ~= nil then
				local v266_ = "LoadingStation: " .. v263_:getName()
				local v267_ = DebugGizmo.new():createWithNode(v265_.aiNode, v266_, nil, nil, nil, false)
				g_debugManager:addElement(v267_)
				local v268_ = self.stationsAINodesDebugElements
				table.insert(v268_, v267_)
			end
		end
	else
		for _, v269_ in pairs(self.stationsAINodesDebugElements) do
			g_debugManager:removeElement(v269_)
			v269_:delete()
		end
		self.stationsAINodesDebugElements = nil
	end
	if self.stationsAINodesVisible then
		Logging.warning("Nodes in reloaded placeables are not updated automatically. Toggle this command again to update the station nodes if placeables were reloaded.")
	end
	local v270_ = self.stationsAINodesVisible
	return "AISystem.stationsAINodesVisible=" .. tostring(v270_)
end

function AISystem:consoleCommandAIShowObstacles()
	if not self.isServer then
		return "gsAIObstaclesShow is a server-only command"
	end
	self.mapDebugRenderingEnabled = not self.mapDebugRenderingEnabled
	enableVehicleNavigationMapDebugRendering(self.navigationMap, self.mapDebugRenderingEnabled)
	local v272_ = self.mapDebugRenderingEnabled
	return "AIShowObstacles=" .. tostring(v272_)
end

-- Local values: x, _, z, halfWidth
function AISystem:consoleCommandAISetAreaDirty(width)
	if not self.isServer then
		return "gsAICostsUpdate is a server-only command"
	end
	local v275_, _, v276_ = getWorldTranslation(g_cameraManager:getActiveCamera())
	local v277_ = tonumber(width) or 30
	local v278_ = g_terrainSize or 2048
	local v279_ = math.clamp(v277_, 2, v278_)
	local v280_ = v279_ / 2
	self:setAreaDirty(v275_ - v280_, v275_ + v280_, v276_ - v280_, v276_ + v280_)
	return string.format("Updated costmap in a %dx%d area around the camera", v279_, v279_)
end

-- Local values: imageFormat, terrainSizeHalf, cellSizeHalf, imageSize, isGreymap, colorBlocking, colorSpline, splines, posToHasSpline, spline, splineLength, splineTime, wx, _, wz, xInt, zInt, terrainNode, getPixelsIterator
function AISystem:consoleCommandAICostmapExport(imageFormatStr)
	if not self.isServer then
		return "gsAICostsExport is a server-only command"
	end
	if g_currentMission.missionInfo.savegameDirectory == nil then
		return "Error: Savegame directory does not exist yet, please save the game first"
	end
	local v283_ = BitmapUtil.FORMAT.PIXELMAP
	if imageFormatStr ~= nil then
		v283_ = BitmapUtil.FORMAT[string.upper(imageFormatStr)]
		if v283_ == nil then
			Logging.error("Unknown image format \'%s\'. Available formats: %s", imageFormatStr, table.concatKeys(BitmapUtil.FORMAT, ", "))
			return "Error: Costmap export failed"
		end
	end
	local v_u_284_ = self.mission.terrainSize * 0.5
	local v_u_285_ = self.cellSizeMeters / 2
	local v286_ = self.mission.terrainSize
	local v_u_287_ = v283_ == BitmapUtil.FORMAT.GREYMAP
	local v_u_288_ = self.debug.colors.blocking
	local v_u_289_ = self.debug.colors.spline
	local v290_ = self:getRoadSplines()
	local v_u_291_ = {}
	for v292_ in pairs(v290_) do
		for v293_ = 0, 1, 1 / getSplineLength(v292_) do
			local v294_, _, v295_ = getSplinePosition(v292_, v293_)
			local v296_ = MathUtil.round(v294_)
			local v297_ = MathUtil.round(v295_)
			v_u_291_[v296_] = v_u_291_[v296_] or {}
			v_u_291_[v296_][v297_] = true
		end
	end
	local v_u_298_ = g_terrainNode
	return BitmapUtil.writeBitmapToFileFromIterator(function()
		-- upvalues: (copy) v_u_284_, (copy) v_u_285_, (copy) v_u_298_, (copy) self, (copy) v_u_291_, (copy) v_u_287_, (copy) v_u_289_, (copy) v_u_288_
		local v_u_299_ = -v_u_284_ + v_u_285_
		local v_u_300_ = -v_u_284_ + v_u_285_
		local v_u_301_ = { 0, 0, 0 }
		return function()
			-- upvalues: (ref) v_u_299_, (ref) v_u_284_, (ref) v_u_285_, (ref) v_u_298_, (ref) v_u_300_, (ref) self, (ref) v_u_291_, (ref) v_u_287_, (copy) v_u_301_, (ref) v_u_289_, (ref) v_u_288_
			if v_u_299_ > v_u_284_ - v_u_285_ then
				return nil
			end
			local v302_ = getTerrainHeightAtWorldPos(v_u_298_, v_u_300_, 0, v_u_299_)
			local v303_, v304_ = getVehicleNavigationMapCostAtWorldPos(self.navigationMap, v_u_300_, v302_, v_u_299_)
			local v305_ = MathUtil.round(v_u_300_)
			local v306_ = MathUtil.round(v_u_299_)
			local v307_ = v_u_291_[v305_]
			if v307_ then
				v307_ = v_u_291_[v305_][v306_]
			end
			if v_u_287_ then
				if v307_ then
					v_u_301_[1] = 1
				else
					v_u_301_[1] = v303_
				end
				v_u_301_[1] = v_u_301_[1] / AISystem.COSTMAP_MAX_VALUE * 255
			else
				if v307_ then
					local v308_ = v_u_301_
					local v309_ = v_u_301_
					local v310_ = v_u_301_
					local v311_ = v_u_289_[1]
					local v312_ = v_u_289_[2]
					local v313_ = v_u_289_[3]
					v308_[1] = v311_
					v309_[2] = v312_
					v310_[3] = v313_
				elseif v304_ then
					local v314_ = v_u_301_
					local v315_ = v_u_301_
					local v316_ = v_u_301_
					local v317_ = v_u_288_[1]
					local v318_ = v_u_288_[2]
					local v319_ = v_u_288_[3]
					v314_[1] = v317_
					v315_[2] = v318_
					v316_[3] = v319_
				else
					local v320_ = v_u_301_
					local v321_ = v_u_301_
					local v322_ = v_u_301_
					local v323_, v324_, v325_ = Utils.getGreenRedBlendedColor(v303_ / AISystem.COSTMAP_MAX_VALUE)
					v320_[1] = v323_
					v321_[2] = v324_
					v322_[3] = v325_
				end
				local v326_ = v_u_301_
				local v327_ = v_u_301_
				local v328_ = v_u_301_
				local v329_ = v_u_301_[1] * 255
				local v330_ = v_u_301_[2] * 255
				local v331_ = v_u_301_[3] * 255
				v326_[1] = v329_
				v327_[2] = v330_
				v328_[3] = v331_
			end
			if v_u_300_ < v_u_284_ - self.cellSizeMeters then
				v_u_300_ = v_u_300_ + self.cellSizeMeters
			else
				v_u_300_ = -v_u_284_ + v_u_285_
				v_u_299_ = v_u_299_ + self.cellSizeMeters
			end
			return v_u_301_
		end
	end, v286_, v286_, g_currentMission.missionInfo.savegameDirectory .. "/navigationMap", v283_) and "Finished costmap export" or "Error: Costmap export failed"
end

-- Local values: usage, debugLastPos, debugNumInterferences, collisionMask, overlapFactor, numSplines, testPosition, splineMaxWidth, splineMaxHeight, splinesWithIntersections, callbackTarget, checkInterference, filterSplines, _, aiSpline, spline
function AISystem:consoleCommandAICheckSplineInterference(stepLength, heightOffset, defaultSplineWidth, defaultSplineHeight)
	if not self.isServer then
		return "gsAISplinesCheckInterference is a server-only command"
	end
	g_debugManager:removeGroup("AIInterference")
	local v_u_337_ = {}
	local v_u_338_ = 0
	local v_u_339_ = tonumber(stepLength) or 5
	local v_u_340_ = tonumber(heightOffset) or 0.2
	local v_u_341_ = tonumber(defaultSplineWidth) or self.defaultVehicleMaxWidth
	local v_u_342_ = tonumber(defaultSplineHeight) or self.defaultVehicleMaxHeightSpline
	local v_u_343_ = CollisionMask.ALL - CollisionFlag.TERRAIN - CollisionFlag.TERRAIN_DELTA - CollisionFlag.TERRAIN_DISPLACEMENT - CollisionFlag.TRIGGER - CollisionFlag.FILLABLE
	local v_u_344_ = 0.9
	Logging.info("Checking interference: stepLength=%.2f heightOffset=%.2f defaultSplineWidth=%.2f defaultSplineHeight=%.2f", v_u_339_, v_u_340_, v_u_341_, v_u_342_)
	local v_u_345_ = 0
	local v_u_346_ = createTransformGroup("testPosition")
	local v_u_347_ = nil
	local v_u_348_ = nil
	local v_u_349_ = {}
	local v_u_356_ = {
		["onOverlapCallback"] = function(_, p350_)
			-- upvalues: (ref) v_u_337_, (copy) v_u_349_, (ref) v_u_338_
			if p350_ == 0 then
				return
			elseif getCollisionFilterMask(p350_) == 1 then
				return
			elseif CollisionFlag.getHasGroupFlagSet(p350_, CollisionFlag.VEHICLE) or CollisionFlag.getHasGroupFlagSet(p350_, CollisionFlag.TRAFFIC_VEHICLE) then
				return
			elseif not CollisionFlag.getHasGroupFlagSet(p350_, CollisionFlag.ROAD) then
				local v351_ = v_u_337_
				local v352_ = getUserAttribute(p350_, "maxWidth")
				local v353_ = v352_ and string.format(" (maxWidth UserAttribute: %.2f)", v352_) or ""
				local v354_ = string.format("%s|%s", getName(getParent(p350_)), getName(p350_))
				Logging.warning("found interference for spline \'%s\'%s with object \'%s\' at %d %d %d", getName(v351_.spline), v353_, v354_, v351_.wx, v351_.wy, v351_.wz)
				local v355_ = DebugBox.new():createFromOverlapBoxParameters(v351_.wx, v351_.wy, v351_.wz, v351_.rx, v351_.ry, v351_.rz, v351_.sx, v351_.sy, v351_.sz)
				v355_:setText(v354_)
				v355_:addToManager("AIInterference")
				v_u_349_[v351_.spline] = true
				v_u_338_ = v_u_338_ + 1
			end
		end
	}
	local function v_u_377_(p357_)
		-- upvalues: (ref) v_u_345_, (ref) v_u_347_, (ref) v_u_341_, (ref) v_u_348_, (ref) v_u_342_, (ref) v_u_339_, (copy) v_u_346_, (ref) v_u_340_, (ref) v_u_337_, (copy) v_u_356_, (copy) v_u_343_, (copy) v_u_344_
		v_u_345_ = v_u_345_ + 1
		local v358_ = getUserAttribute(p357_, "maxWidth") or (v_u_347_ or v_u_341_)
		local v359_ = getUserAttribute(p357_, "maxHeight") or (v_u_348_ or v_u_342_)
		local v360_ = getSplineLength(p357_)
		local v361_ = v_u_339_ * 0.9 / v360_
		for v362_ = 0, 1 + v361_, v361_ do
			local v363_ = math.clamp(v362_, 0, 1)
			local v364_, v365_, v366_ = getSplinePosition(p357_, v363_)
			local v367_, v368_, v369_ = getSplineDirection(p357_, v363_)
			setWorldTranslation(v_u_346_, v364_, v365_, v366_)
			setDirection(v_u_346_, v367_, v368_, v369_, 0, 1, 0)
			local v370_, v371_, v372_ = getWorldRotation(v_u_346_)
			local v373_ = v358_ / 2
			local v374_ = v359_ / 2 - v_u_340_ / 2
			local v375_ = v_u_339_ / 2
			local v376_ = v365_ + v374_ + v_u_340_
			v_u_337_ = {
				["rx"] = v370_,
				["ry"] = v371_,
				["rz"] = v372_,
				["sx"] = v373_,
				["sy"] = v374_,
				["sz"] = v375_,
				["wx"] = v364_,
				["wy"] = v376_,
				["wz"] = v366_,
				["spline"] = p357_
			}
			overlapBox(v364_, v376_, v366_, v370_, v371_, v372_, v373_, v374_, v375_, "onOverlapCallback", v_u_356_, v_u_343_, false, true, true, true)
		end
	end
	local function v379_(p378_, _)
		-- upvalues: (copy) v_u_377_, (ref) v_u_347_, (ref) v_u_348_
		if I3DUtil.getIsSpline(p378_) then
			v_u_377_(p378_)
		else
			v_u_347_ = getUserAttribute(p378_, "maxWidth")
			v_u_348_ = getUserAttribute(p378_, "maxHeight")
		end
	end
	local v380_ = v_u_345_
	for _, v381_ in ipairs(self.roadSplines) do
		I3DUtil.iterateRecursively(v381_, v379_, true)
	end
	for v382_ in pairs(v_u_349_) do
		DebugSpline.new():createWithNode(v382_):addToManager("AIInterference")
	end
	delete(v_u_346_)
	return string.format("Checked %d splines, found %d interferences\n%s", v380_, v_u_338_, "gsAISplineCheckInterference [stepLength] [heightOffset] [defaultSplineWidth] [defaultSplineHeight]\nUse \'gsDebugManagerClearElements\' to remove boxes.")
end

-- Local values: k, v
function AISystem.getAgentStateName(index)
	for v384_, v385_ in pairs(AgentState) do
		if v385_ == index then
			return v384_
		end
	end
	return "UNKNOWN"
end
