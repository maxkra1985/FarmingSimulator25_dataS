-- Local values: MissionManager_mt
MissionManager = {}
MissionManager.UNIQUE_ID_PREFIX = "mission"
MissionManager.MAX_MISSIONS = 30
MissionManager.MISSION_GENERATION_INTERVAL = 360000
MissionManager.MAX_MISSIONS_PER_FARM = 3
MissionManager.VERSION = 0
MissionManager.DEBUG_ENABLED = false
local MissionManager_mt = Class(MissionManager, AbstractManager)
g_xmlManager:addCreateSchemaFunction(function()
	MissionManager.xmlSchema = XMLSchema.new("missionVehicles")
	MissionManager.xmlSchemaSavegame = XMLSchema.new("savegame_missions")
end)
g_xmlManager:addInitSchemaFunction(function()
	local v2_ = Mission00.xmlSchema
	v2_:register(XMLValueType.BOOL, "map.missions#enabled", "")
	v2_:register(XMLValueType.STRING, "map.missions#vehicleFilename", "")
	for _, v3_ in ipairs(g_missionManager.missionTypes) do
		local v4_ = v3_.classObject
		local v5_ = string.format("map.missions.%s", v3_.name)
		v2_:register(XMLValueType.INT, v5_ .. "#maxNumInstances")
		if v4_.registerXMLPaths ~= nil then
			v4_.registerXMLPaths(v2_, v5_)
		end
	end
	local v6_ = MissionManager.xmlSchema
	v6_:register(XMLValueType.STRING, "missionVehicles.mission(?)#type", "Type of the mission", nil, true)
	v6_:register(XMLValueType.STRING, "missionVehicles.mission(?).group(?)#size", "Size of the mission", "medium", false, { "small", "medium", "large" })
	v6_:register(XMLValueType.FLOAT, "missionVehicles.mission(?).group(?)#rewardScale", "Reward scale factor", 1, false)
	v6_:register(XMLValueType.STRING, "missionVehicles.mission(?).group(?)#variant", "Name of the variant", nil, false)
	v6_:register(XMLValueType.STRING, "missionVehicles.mission(?).group(?).vehicle(?)#filename", "Filename of the vehicle", nil, true)
	v6_:registerAutoCompletionDataSource("missionVehicles.mission(?).group(?).vehicle(?)#filename", "dataS/storeItems.xml", "storeItems.storeItem#xmlFilename")
	v6_:register(XMLValueType.STRING, "missionVehicles.mission(?).group(?).vehicle(?).configuration(?)#name", "Name of the configuration", nil, true)
	v6_:register(XMLValueType.INT, "missionVehicles.mission(?).group(?).vehicle(?).configuration(?)#id", "Id of the configuration", nil, true)
	local v7_ = MissionManager.xmlSchemaSavegame
	v7_:register(XMLValueType.INT, "missions#version", "Version")
	for _, v8_ in ipairs(g_missionManager.missionTypes) do
		local v9_ = v8_.classObject
		local v10_ = string.format("missions.meta.%s", v8_.name)
		if v9_.registerMetaXMLPaths ~= nil then
			v9_.registerMetaXMLPaths(v7_, v10_)
		end
	end
	for _, v11_ in ipairs(g_missionManager.missionTypes) do
		local v12_ = v11_.classObject
		local v13_ = string.format("missions.%s(?)", v11_.name)
		if v12_.registerSavegameXMLPaths ~= nil then
			v12_.registerSavegameXMLPaths(v7_, v13_)
		end
	end
end)

-- Upvalues: MissionManager_mt
-- Local values: self
function MissionManager.new(customMt)
	-- upvalues: (copy) MissionManager_mt
	local v15_ = AbstractManager.new(customMt or MissionManager_mt)
	v15_.defaultMissionMapWidth = 512
	v15_.defaultMissionMapHeight = 512
	v15_.missionMapNumChannels = 4
	return v15_
end

function MissionManager:initDataStructures()
	self.missions = {}
	self.missionsToDelete = {}
	self.missionTypes = {}
	self.nameToMissionType = {}
	self.missionByUniqueId = {}
	self.missionMap = nil
	self.currentMissionTypeIndex = 0
	self.startMissionTypeIndex = 0
	self.pendingMissionVehicleFiles = {}
	self.missionVehicles = {}
	self.nextGeneratedMissionId = 1
	self.generationTimer = 0
end

function MissionManager:delete()
	if self.debugBitVectorMap ~= nil then
		g_debugManager:removeElement(self.debugBitVectorMap)
	end
end

-- Local values: isEnabled, currentMission, xmlFileObj, _, missionType, classObject, key, data, missionVehicleXmlFilename, path, _, info
function MissionManager:loadMapData(xmlFile)
	MissionManager:superClass().loadMapData(self)
	if Utils.getNoNil(getXMLBool(xmlFile, "map.missions#enabled"), true) then
		self:createMissionMap()
		local v20_ = g_currentMission
		local v21_ = XMLFile.wrap(xmlFile, Mission00.xmlSchema)
		for _, v22_ in ipairs(self.missionTypes) do
			local v23_ = v22_.classObject
			local v24_ = string.format("map.missions.%s", v22_.name)
			local v25_ = v22_.data
			v25_.maxNumInstances = v21_:getInt(v24_ .. "#maxNumInstances") or v25_.maxNumInstances
			if v23_.loadMapData ~= nil then
				v23_.loadMapData(v21_, v24_, v20_.baseDirectory)
			end
		end
		v21_:delete()
		if v20_:getIsServer() then
			v20_:addUpdateable(self)
		end
		local v26_ = getXMLString(xmlFile, "map.missions#vehicleFilename")
		if v26_ == nil then
			Logging.xmlDevWarning(xmlFile, "MissionManager: No vehicleFilename defined for mission vehicles")
		else
			local v27_ = Utils.getFilename(v26_, v20_.baseDirectory)
			if v27_ ~= nil then
				self:loadVehicleGroups(v27_, v20_.baseDirectory)
			end
		end
		for _, v28_ in ipairs(self.pendingMissionVehicleFiles) do
			self:loadVehicleGroups(v28_[1], v28_[2])
		end
		if g_addTestCommands and g_server ~= nil then
			addConsoleCommand("gsMissionGenerate", "Force generating a new mission for given farmland", "consoleGenerateMission", self, "farmlandId; missionType")
			addConsoleCommand("gsMissionLoadVehicleSet", "Loads a specific vehicle set", "consoleLoadVehicleSet", self, "missionType; [size (small|medium|large)]; [groupIndex]")
			addConsoleCommand("gsMissionLoadVehiclesAll", "Loads all mission vehicles", "consoleLoadAllVehicleSets", self, "")
		end
	else
		Logging.xmlInfo(xmlFile, "MissionManager: Disabled missions according to configuration")
	end
end

-- Local values: currentMission, _, missionType, classObject
function MissionManager:unloadMapData()
	g_messageCenter:unsubscribeAll(self)
	g_currentMission:removeUpdateable(self)
	for _, v30_ in ipairs(self.missionTypes) do
		local v31_ = v30_.classObject
		if v31_.unloadMapData ~= nil then
			v31_.unloadMapData(v30_.data)
		end
	end
	self:destroyMissionMap()
	removeConsoleCommand("gsMissionGenerate")
	removeConsoleCommand("gsMissionLoadVehicleSet")
	removeConsoleCommand("gsMissionLoadVehiclesAll")
	MissionManager:superClass().unloadMapData(self)
end

-- Local values: xmlFile, _, missionType, classObject, key, counts, k, mission, missionKey
function MissionManager:saveToXMLFile(xmlFilename)
	local v34_ = XMLFile.create("missionXML", xmlFilename, "missions", MissionManager.xmlSchemaSavegame)
	if v34_ ~= nil then
		for _, v35_ in ipairs(self.missionTypes) do
			local v36_ = v35_.classObject
			local v37_ = string.format("missions.meta.%s", v35_.name)
			if v36_.saveMetaDataToXMLFile ~= nil then
				v36_.saveMetaDataToXMLFile(v34_, v37_)
			end
		end
		v34_:setValue("missions#version", MissionManager.VERSION)
		local v38_ = {}
		for _, v39_ in ipairs(self.missions) do
			v38_[v39_.type.name] = (v38_[v39_.type.name] or 0) + 1
			v39_:saveToXMLFile(v34_, (string.format("missions.%s(%d)", v39_.type.name, v38_[v39_.type.name] - 1)))
		end
		v34_:save()
		v34_:delete()
	end
	return false
end

-- Local values: xmlFile, version, _, missionType, classObject, key, numElements, _, key, missionTypeName, missionTypeKey, missionType, mission, hasValidFarm
function MissionManager:loadFromXMLFile(xmlFilename)
	if xmlFilename == nil then
		return false
	end
	local v42_ = XMLFile.load("missionsXML", xmlFilename, MissionManager.xmlSchemaSavegame)
	if v42_ == nil then
		return false
	end
	if v42_:getValue("missions#version") ~= MissionManager.VERSION then
		Logging.xmlWarning(v42_, "Missions version does not match current mission manager version")
		v42_:delete()
		return true
	end
	for _, v43_ in ipairs(self.missionTypes) do
		local v44_ = v43_.classObject
		local v45_ = string.format("missions.meta.%s", v43_.name)
		if v44_.loadMetaDataFromXMLFile ~= nil then
			v44_.loadMetaDataFromXMLFile(v42_, v45_)
		end
	end
	local v46_ = {}
	for _, v47_ in v42_:iterator("missions.*") do
		local v48_ = v42_:getElementName(v47_)
		v46_[v48_] = (v46_[v48_] or 0) + 1
		local v49_ = string.format("missions.%s(%d)", v48_, v46_[v48_] - 1)
		if v48_ ~= "meta" then
			local v50_ = self:getMissionType(v48_)
			if v50_ == nil then
				Logging.xmlWarning(v42_, "Mission type \'%s\' not found for \'%s!", v48_, v49_)
			else
				local v51_ = v50_.classObject.new(true, g_client ~= nil)
				v51_.type = v50_
				self:assignGenerationTime(v51_)
				if v51_:loadFromXMLFile(v42_, v49_) then
					if v51_.farmId == nil and true or g_farmManager:getFarmById(v51_.farmId) ~= nil then
						v51_:register()
						self:addMission(v51_)
					else
						local v52_ = self.missionsToDelete
						table.insert(v52_, v51_)
					end
				else
					if v51_.failedToLoadFromXMLFile ~= nil then
						v51_:failedToLoadFromXMLFile()
					end
					local v53_ = self.missionsToDelete
					table.insert(v53_, v51_)
				end
			end
		end
	end
	v42_:delete()
	return true
end

function MissionManager:getCanStartNewMissionGeneration()
	local v55_ = not self.missionGenerationInProgress
	if v55_ then
		if #self.missions < MissionManager.MAX_MISSIONS then
			v55_ = self.generationTimer < 0
		else
			v55_ = false
		end
	end
	return v55_
end

-- Local values: currentMission
function MissionManager:update(dt)
	local v58_ = g_currentMission
	if v58_:getIsServer() and Platform.gameplay.hasMissions then
		self.generationTimer = self.generationTimer - v58_:getEffectiveTimeScale() * dt
		self:updateMissions(dt)
		if self:getCanStartNewMissionGeneration() then
			self:startMissionGeneration()
			return
		end
		if self.missionGenerationInProgress then
			self:generateMission()
		end
	end
end

-- Local values: _, mission, i, mission
function MissionManager:updateMissions(dt)
	for _, v60_ in ipairs(self.missions) do
		if v60_.status == MissionStatus.CREATED and not v60_:validate() then
			local v61_ = self.missionsToDelete
			table.insert(v61_, v60_)
		end
	end
	for v62_ = #self.missionsToDelete, 1, -1 do
		table.remove(self.missionsToDelete, v62_):delete()
	end
end

function MissionManager:startMissionGeneration()
	g_messageCenter:publish(MessageType.MISSION_GENERATION_START)
	self.currentMissionTypeIndex = math.random(1, #self.missionTypes)
	self.startMissionTypeIndex = self.currentMissionTypeIndex
	self.missionGenerationInProgress = true
end

function MissionManager:finishMissionGeneration()
	g_messageCenter:publish(MessageType.MISSION_GENERATION_END)
	self.generationTimer = MissionManager.MISSION_GENERATION_INTERVAL
	self.missionGenerationInProgress = false
end

-- Local values: missionType, success, classObject, mission
function MissionManager:generateMission()
	local v66_ = self.missionTypes[self.currentMissionTypeIndex]
	if v66_ == nil then
		self:finishMissionGeneration()
		return
	else
		local v67_ = false
		local v68_ = v66_.classObject
		if v68_.tryGenerateMission ~= nil then
			local v69_ = v68_.tryGenerateMission()
			if v69_ ~= nil then
				self:registerMission(v69_, v66_)
				v67_ = true
			end
		end
		self.currentMissionTypeIndex = self.currentMissionTypeIndex + 1
		if self.currentMissionTypeIndex > #self.missionTypes then
			self.currentMissionTypeIndex = 1
		end
		if self.currentMissionTypeIndex == self.startMissionTypeIndex then
			self:finishMissionGeneration()
			return
		elseif v67_ then
			self:finishMissionGeneration()
		end
	end
end

function MissionManager:registerMission(mission, missionType)
	mission.type = missionType
	mission:register()
	self:addMission(mission)
	g_messageCenter:publish(MessageType.MISSION_GENERATED, mission)
end

function MissionManager:addMission(mission)
	if mission:getUniqueId() == nil or self.missionByUniqueId[mission:getUniqueId()] == nil then
		if mission:getUniqueId() == nil then
			mission:setUniqueId(Utils.getUniqueId(mission, self.missionByUniqueId, MissionManager.UNIQUE_ID_PREFIX))
		end
		self.missionByUniqueId[mission:getUniqueId()] = mission
		table.addElement(self.missions, mission)
	else
		local v75_ = Logging.warning
		local v76_ = mission:getUniqueId()
		local v77_ = self.missionByUniqueId[mission:getUniqueId()]
		v75_("Tried to add existing mission with unique id of %s! Existing: %s, new: %s", v76_, tostring(v77_), (tostring(mission)))
	end
end

-- Local values: uniqueId
function MissionManager:removeMission(mission)
	table.removeElement(self.missions, mission)
	local v80_ = mission:getUniqueId()
	if v80_ ~= nil then
		self.missionByUniqueId[v80_] = nil
	end
end

function MissionManager:markMissionForDeletion(mission)
	table.addElement(self.missionsToDelete, mission)
end

function MissionManager:getMissionByUniqueId(uniqueId)
	return self.missionByUniqueId[uniqueId]
end

-- Local values: currentMission, _, activeMission
function MissionManager:startMission(mission, farmId, spawnVehicles)
	local v89_ = g_currentMission:getIsServer()
	assert(v89_, "MissionManager:startMission is a server-only function")
	if farmId == FarmManager.SPECTATOR_FARM_ID then
		return MissionStartState.NO_ACCESS
	elseif self:hasFarmReachedMissionLimit(farmId) then
		return MissionStartState.LIMIT_REACHED
	elseif mission.activeMissionId then
		return MissionStartState.ALREADY_STARTED
	else
		for _, v90_ in ipairs(self.missions) do
			if v90_.status == MissionStatus.PREPARING then
				return MissionStartState.PENDING_MISSION
			end
		end
		if mission:validate() then
			mission.activeMissionId = self:getFreeActiveMissionId()
			if mission.activeMissionId == 0 then
				return MissionStartState.CANNOT_BE_STARTED_NOW
			else
				mission.farmId = farmId
				if mission:start(spawnVehicles) then
					g_messageCenter:publish(MissionStartedEvent, mission)
					return MissionStartState.OK
				else
					mission:delete()
					return MissionStartState.CANNOT_BE_STARTED_NOW
				end
			end
		else
			mission:delete()
			return MissionStartState.NOT_AVAILABLE_ANYMORE
		end
	end
end

-- Local values: currentMission
function MissionManager:cancelMission(mission)
	local v92_ = g_currentMission:getIsServer()
	assert(v92_, "MissionManager:cancelMission is a server-only function")
	if mission == nil or mission.status == MissionStatus.FINISHED then
		return false
	end
	mission:finish(MissionFinishState.CANCELED)
	return true
end

-- Local values: currentMission
function MissionManager:dismissMission(mission)
	local v94_ = g_currentMission:getIsServer()
	assert(v94_, "MissionManager:dismissMission is a server-only function")
	mission:dismiss()
	mission:delete()
	return true
end

function MissionManager:getMissions()
	return self.missions
end

function MissionManager:getMissionsByFarmId(farmId)
	return table.ifilter(self.missions, function(p98_)
		-- upvalues: (copy) farmId
		return p98_.farmId == nil and true or p98_.farmId == farmId
	end)
end

-- Local values: farmlandId, _, mission
function MissionManager:getIsMissionRunningOnFarmland(farmland)
	if farmland == nil then
		return false
	end
	local v101_ = farmland:getId()
	for _, v102_ in ipairs(self.missions) do
		if v102_.getFarmlandId ~= nil and (v102_:getFarmlandId() == v101_ and v102_:getIsInProgress()) then
			return true
		end
	end
	return false
end

-- Local values: _, mission
function MissionManager:getMissionByFarmlandId(farmlandId)
	if farmlandId == nil then
		return nil
	end
	for _, v105_ in ipairs(self.missions) do
		if v105_.getFarmlandId ~= nil and v105_:getFarmlandId() == farmlandId then
			return v105_
		end
	end
	return nil
end

-- Local values: missionType
function MissionManager:getMissionsByType(typeIndex)
	local v_u_108_ = self.missionTypes[typeIndex]
	if v_u_108_ == nil then
		return nil
	else
		return table.ifilter(self.missions, function(p109_)
			-- upvalues: (copy) v_u_108_
			return p109_:isa(v_u_108_.classObject)
		end)
	end
end

-- Local values: total, _, mission
function MissionManager:hasFarmReachedMissionLimit(farmId)
	local v112_ = 0
	for _, v113_ in ipairs(self.missions) do
		if v113_.farmId == farmId and v113_:getWasStarted() then
			v112_ = v112_ + 1
		end
	end
	return MissionManager.MAX_MISSIONS_PER_FARM <= v112_
end

-- Local values: currentMission, cellsize
function MissionManager:createMissionMap()
	self.missionMap = InfoLayer.new("MissionAccessMap")
	self.missionMap:create(self.defaultMissionMapWidth, self.defaultMissionMapHeight, self.missionMapNumChannels, false)
	local v115_ = g_currentMission
	if v115_:getIsServer() then
		v115_.growthSystem:setGrowthMask(self.missionMap:getId(), 0, self.missionMapNumChannels)
	end
	if MissionManager.DEBUG_ENABLED then
		local v116_ = v115_.terrainSize / self.defaultMissionMapWidth
		self.debugBitVectorMap = DebugBitVectorMap.newSimple(20, v116_, false, 0.2)
		self.debugBitVectorMap:createWithCustomFunc(function(_, p117_, p118_, p119_, p120_, p121_, p122_)
			-- upvalues: (copy) self
			local v123_ = (p117_ + p119_ + p121_) / 3
			local v124_ = (p118_ + p120_ + p122_) / 3
			return self.missionMap:getValueAtWorldPos(v123_, v124_)
		end)
		g_debugManager:addElement(self.debugBitVectorMap)
	end
end

-- Local values: currentMission
function MissionManager:destroyMissionMap()
	local v126_ = g_currentMission
	if v126_:getIsServer() then
		v126_.growthSystem:resetGrowthMask()
	end
	if self.missionMap ~= nil then
		self.missionMap:delete()
		self.missionMap = nil
	end
end

function MissionManager:setMissionMapActiveMissionId(area, missionId)
	if self.missionMap ~= nil then
		self.missionMap:setValueAtArea(area, missionId)
	end
end

function MissionManager:getMissionMapActiveMissionIdAtWorldPosition(worldX, worldZ)
	return self.missionMap == nil and 0 or self.missionMap:getValueAtWorldPos(worldX, worldZ, nil, nil)
end

-- Local values: missionId
function MissionManager:getMissionAtWorldPosition(worldX, worldZ)
	local v136_ = self:getMissionMapActiveMissionIdAtWorldPosition(worldX, worldZ)
	if v136_ > 0 then
		return self:getMissionByActiveMissionId(v136_)
	else
		return nil
	end
end

-- Local values: _, mission
function MissionManager:getMissionByActiveMissionId(activeMissionId)
	for _, v139_ in ipairs(self.missions) do
		if v139_.activeMissionId == activeMissionId then
			return v139_
		end
	end
	return nil
end

-- Local values: i
function MissionManager:getFreeActiveMissionId()
	for v141_ = 1, MissionManager.MAX_MISSIONS do
		if self:getMissionByActiveMissionId(v141_) == nil then
			return v141_
		end
	end
	return 0
end

-- Local values: mission
function MissionManager:getIsMissionWorkAllowed(farmId, x, z, workAreaType, vehicle)
	local v148_ = self:getMissionAtWorldPosition(x, z)
	return v148_ ~= nil and (v148_.farmId == farmId and v148_:getIsWorkAllowed(farmId, x, z, workAreaType, vehicle)) and true or false
end

-- Local values: missionType
function MissionManager:registerMissionType(classObject, name, defaultMaxNumInstances)
	if classObject ~= nil and name ~= nil then
		local v153_ = {
			["name"] = name,
			["classObject"] = classObject,
			["typeId"] = #self.missionTypes + 1,
			["data"] = {
				["numInstances"] = 0,
				["maxNumInstances"] = defaultMaxNumInstances or 2
			}
		}
		local v154_ = self.missionTypes
		table.insert(v154_, v153_)
		self.nameToMissionType[string.upper(name)] = v153_
	end
end

-- Local values: i, type
function MissionManager:unregisterMissionType(name)
	if name ~= nil then
		for v157_, v158_ in ipairs(self.missionTypes) do
			if v158_.name == name then
				table.remove(self.missionType, v157_)
				return
			end
		end
	end
end

function MissionManager:getMissionType(name)
	return self.nameToMissionType[string.upper(name)]
end

function MissionManager:getMissionTypeById(id)
	return self.missionTypes[id]
end

-- Local values: missionType
function MissionManager:getMissionTypeDataByName(name)
	if name == nil then
		Logging.devError("MissionManager.getMissionTypeDataByName: no mission type name defined")
		if g_isDevelopmentVersion then
			printCallstack()
		end
		return nil
	else
		local v165_ = self.nameToMissionType[string.upper(name)]
		if v165_ == nil then
			return nil
		else
			return v165_.data
		end
	end
end

-- Local values: _, mission
function MissionManager:getMissionBySplitShape(shape)
	if shape == nil or shape == 0 then
		return nil
	end
	for _, v168_ in ipairs(self.missions) do
		if v168_.getIsMissionSplitShape ~= nil and v168_:getIsMissionSplitShape(shape) then
			return v168_
		end
	end
	return nil
end

-- Local values: _, mission, isAllowed
function MissionManager:getIsShapeCutAllowed(shape, x, z, farmId)
	for _, v174_ in ipairs(self.missions) do
		if v174_.getIsShapeCutAllowed ~= nil then
			local v175_ = v174_:getIsShapeCutAllowed(shape, x, z, farmId)
			if v175_ ~= nil then
				return v175_
			end
		end
	end
	return nil
end

-- Local values: _, mission
function MissionManager:getIsMissionDestructible(farmId, nodeId)
	for _, v179_ in ipairs(self.missions) do
		if v179_.getDestructibleIsInMissionArea ~= nil and v179_:getDestructibleIsInMissionArea(nodeId, farmId) then
			return true
		end
	end
	return false
end

function MissionManager:addPendingMissionVehiclesFile(filename, baseDirectory)
	local v183_ = self.pendingMissionVehicleFiles
	table.insert(v183_, { filename, baseDirectory })
end

-- Local values: xmlFile, _, missionKey, missionTypeName, missionType, groups, _, groupKey, size, rewardScale, success, vehicles, group, _, vehicleKey, vehicleXMLFilename, storeItem, configurations, _, configKey, name, id
function MissionManager:loadVehicleGroups(xmlFilename, baseDirectory)
	local v187_ = XMLFile.load("MissionVehicles", xmlFilename, MissionManager.xmlSchema)
	if v187_ == nil then
		return false
	end
	for _, v188_ in v187_:iterator("missionVehicles.mission") do
		local v189_ = v187_:getValue(v188_ .. "#type")
		if v189_ == nil then
			Logging.xmlError(v187_, "Property type must exist on each mission - \'%s\'", v188_)
		elseif self:getMissionType(v189_) == nil then
			Logging.xmlError(v187_, "Mission type \'%s\' is not defined - \'%s\'", v189_, v188_)
		else
			if self.missionVehicles[v189_] == nil then
				self.missionVehicles[v189_] = {}
			end
			local v190_ = self.missionVehicles[v189_]
			for _, v191_ in v187_:iterator(v188_ .. ".group") do
				local v192_ = v187_:getValue(v191_ .. "#size", "medium")
				local v193_ = {}
				local v194_ = {
					["rewardScale"] = v187_:getValue(v191_ .. "#rewardScale", 1),
					["vehicles"] = v193_,
					["variant"] = v187_:getValue(v191_ .. "#variant")
				}
				local v195_ = true
				for _, v196_ in v187_:iterator(v191_ .. ".vehicle") do
					local v197_ = Utils.getFilename(v187_:getValue(v196_ .. "#filename"), baseDirectory)
					if v197_ == nil then
						Logging.xmlError(v187_, "Missing \'filename\' attribute for vehicle %q", v196_)
						v195_ = false
						break
					end
					if g_storeManager:getItemByXMLFilename(v197_) == nil then
						Logging.xmlError(v187_, "Unable to load store item for xml filename \'%q at %q", v197_, v196_)
						v195_ = false
						break
					end
					local v198_ = nil
					for _, v199_ in v187_:iterator(v196_ .. ".configuration") do
						local v200_ = v187_:getValue(v199_ .. "#name")
						local v201_ = v187_:getValue(v199_ .. "#id")
						if v200_ == nil then
							Logging.xmlError(v187_, "Missing \'name\' attribute for configuration at %q", v199_)
						elseif v201_ == nil then
							Logging.xmlError(v187_, "Missing \'id\' attribute for configuration %q at %q", v200_, v199_)
						else
							v198_ = v198_ or {}
							v198_[v200_] = v201_
						end
					end
					table.insert(v193_, {
						["filename"] = v197_,
						["configurations"] = v198_
					})
				end
				if v195_ then
					if v190_[v192_] == nil then
						v190_[v192_] = {}
					end
					local v202_ = v190_[v192_]
					table.insert(v202_, v194_)
					v194_.identifier = #v190_[v192_]
				end
			end
		end
	end
	v187_:delete()
	return true
end

-- Local values: groups, sized, variantGroups, group
function MissionManager:getRandomVehicleGroup(missionType, size, variant)
	local v207_ = self.missionVehicles[missionType]
	if v207_ == nil then
		return nil, 1
	else
		local v208_ = v207_[size]
		if v208_ == nil then
			return nil, 1
		else
			local v210_ = table.ifilter(v208_, function(p209_)
				-- upvalues: (copy) variant
				return variant == nil and true or p209_.variant == variant
			end)
			local v211_ = table.getRandomElement(v210_)
			if v211_ == nil then
				return nil, 1
			else
				return v211_.vehicles, v211_.identifier
			end
		end
	end
end

-- Local values: groups, sized, group
function MissionManager:getVehicleGroupFromIdentifier(missionType, fieldSize, identifier)
	local v216_ = self.missionVehicles[missionType]
	if v216_ == nil then
		return nil, 1, "No vehicles for missionType"
	else
		local v217_ = v216_[fieldSize]
		if v217_ == nil then
			return nil, 1, "No vehicles for fieldSize"
		else
			local v218_ = v217_[identifier]
			if v218_ == nil then
				return nil, 1, "No vehicles for index/indetifier"
			else
				return v218_.vehicles, v218_.rewardScale, "", v218_
			end
		end
	end
end

function MissionManager:assignGenerationTime(mission)
	mission.generationTime = self.nextGeneratedMissionId
	self.nextGeneratedMissionId = self.nextGeneratedMissionId + 1
end

-- Local values: farmland, field, success, missionType, classObject, mission
function MissionManager:consoleGenerateMission(farmlandId, missionTypeName)
	local v224_ = tonumber(farmlandId)
	local v225_ = g_farmlandManager:getFarmlandById(v224_)
	if v225_ == nil then
		printError("Error: Given farmland not found")
		return
	else
		local v226_ = v225_:getField()
		g_fieldManager.debugField = v226_
		if missionTypeName == nil then
			printError(string.format("Error: No mission type given"))
			print(string.format("Available mission types: %s", table.concatKeys(self.nameToMissionType, ", ")))
			return
		else
			local v227_ = false
			local v228_ = self:getMissionType(missionTypeName)
			if v228_ == nil then
				printError(string.format("Error: Given missionType %q not found", missionTypeName))
				print(string.format("Available mission types: %s", table.concatKeys(self.nameToMissionType, ", ")))
			else
				local v229_ = v228_.classObject
				if v229_.tryGenerateMission ~= nil then
					local v230_ = v229_.tryGenerateMission()
					if v230_ ~= nil then
						self:registerMission(v230_, v228_)
						v227_ = true
					end
				end
				g_fieldManager.debugField = nil
				if v227_ then
					return "Mission created"
				end
				printError("Error: Failed to create mission")
			end
		end
	end
end

-- Local values: foundMissionType, missionTypeNames, _, missionType, vehicles, _, errorMessage, numLoadedVehicles, numVehiclesToLoad, onSpawnedVehicle, _, vehicleInfo, data, mission
function MissionManager:consoleLoadVehicleSet(missionTypeName, size, groupIndex)
	local v235_ = tonumber(groupIndex) or 1
	local v236_ = {}
	local v237_ = false
	local v238_ = size or "medium"
	for _, v239_ in ipairs(self.missionTypes) do
		local v240_ = v239_.name
		table.insert(v236_, v240_)
		if v239_.name == missionTypeName then
			v237_ = true
		end
	end
	if v237_ then
		local v241_, _, v242_ = self:getVehicleGroupFromIdentifier(missionTypeName, v238_, v235_)
		if v241_ == nil then
			Logging.error("No vehicles defined for parameter. %s", v242_)
		else
			local v_u_243_ = 0
			local v_u_244_ = #v241_
			local function v248_(_, p245_, p246_, _)
				-- upvalues: (ref) v_u_243_, (copy) v_u_244_
				if p246_ == VehicleLoadingState.OK then
					v_u_243_ = v_u_243_ + 1
					if v_u_243_ == v_u_244_ then
						Logging.info("Finished mission vehicle loading")
						return
					end
				else
					for _, v247_ in ipairs(p245_) do
						v247_:delete()
					end
					Logging.error("Failed to load vehicles")
				end
			end
			for _, v249_ in ipairs(v241_) do
				local v250_ = VehicleLoadingData.new()
				v250_:setFilename(v249_.filename)
				if v250_.isValid then
					if v249_.configurations ~= nil then
						v250_:setConfigurations(v249_.configurations)
					end
					local v251_ = g_currentMission
					v250_:setLoadingPlace(v251_.storeSpawnPlaces, v251_.usedStorePlaces)
					v250_:setOwnerFarmId(g_localPlayer:getFarmId())
					v250_:load(v248_, nil, nil)
				end
			end
		end
	else
		Logging.error("Unknown missionType %q", missionTypeName)
		print(string.format("Available mission types: %s", table.concat(v236_, ", ")))
		return
	end
end

-- Local values: vehiclesToLoad, missionType, missionSizes, missionSize, variants, _, variant, _, vehicle, numVehicles, loadNextVehicle, onSpawnedVehicle
function MissionManager:consoleLoadAllVehicleSets()
	local v_u_253_ = {}
	for _, v254_ in pairs(self.missionVehicles) do
		for _, v255_ in pairs(v254_) do
			for _, v256_ in ipairs(v255_) do
				for _, v257_ in ipairs(v256_.vehicles) do
					table.insert(v_u_253_, v257_)
				end
			end
		end
	end
	local v_u_258_ = #v_u_253_
	local v_u_259_ = nil
	local function v_u_262_(_, p260_, _, _)
		-- upvalues: (copy) v_u_253_, (ref) v_u_259_
		for _, v261_ in ipairs(p260_) do
			v261_:delete()
		end
		if #v_u_253_ > 0 then
			v_u_259_()
		else
			Logging.info("Finished mission vehicle loading")
		end
	end
	v_u_259_ = function()
		-- upvalues: (copy) v_u_253_, (copy) v_u_258_, (copy) v_u_262_
		local v263_ = table.remove(v_u_253_, 1)
		if v263_ ~= nil then
			Logging.info("loading mission vehicle %d/%d", v_u_258_ - #v_u_253_, v_u_258_)
			local v264_ = VehicleLoadingData.new()
			v264_:setFilename(v263_.filename)
			if v263_.configurations ~= nil then
				v264_:setConfigurations(v263_.configurations)
			end
			local v265_ = g_currentMission
			v264_:setLoadingPlace(v265_.storeSpawnPlaces, v265_.usedStorePlaces)
			v264_:setOwnerFarmId(g_localPlayer:getFarmId())
			v264_:load(v_u_262_, nil, nil)
		end
	end
	Logging.info("Started loading %d mission vehicles", v_u_258_)
	v_u_259_()
end
g_missionManager = MissionManager.new()
