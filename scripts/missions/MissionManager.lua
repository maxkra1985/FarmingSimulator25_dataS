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
	local missionSchema = Mission00.xmlSchema
	missionSchema:register(XMLValueType.BOOL, "map.missions#enabled", "")
	missionSchema:register(XMLValueType.STRING, "map.missions#vehicleFilename", "")
	for _, missionType in ipairs(g_missionManager.missionTypes) do
		local classObject = missionType.classObject
		local key = string.format("map.missions.%s", missionType.name)
		missionSchema:register(XMLValueType.INT, key .. "#maxNumInstances")
		if classObject.registerXMLPaths == nil then
			continue
		end
		classObject.registerXMLPaths(missionSchema, key)
	end
	local schema = MissionManager.xmlSchema
	local baseKey = "missionVehicles.mission(?)"
	schema:register(XMLValueType.STRING, "missionVehicles.mission(?)" .. "#type", "Type of the mission", nil, true)
	schema:register(XMLValueType.STRING, "missionVehicles.mission(?)" .. ".group(?)#size", "Size of the mission", "medium", false, { "small", "medium", "large" })
	schema:register(XMLValueType.FLOAT, "missionVehicles.mission(?)" .. ".group(?)#rewardScale", "Reward scale factor", 1, false)
	schema:register(XMLValueType.STRING, "missionVehicles.mission(?)" .. ".group(?)#variant", "Name of the variant", nil, false)
	schema:register(XMLValueType.STRING, "missionVehicles.mission(?)" .. ".group(?).vehicle(?)#filename", "Filename of the vehicle", nil, true)
	schema:registerAutoCompletionDataSource("missionVehicles.mission(?)" .. ".group(?).vehicle(?)#filename", "dataS/storeItems.xml", "storeItems.storeItem#xmlFilename")
	schema:register(XMLValueType.STRING, "missionVehicles.mission(?)" .. ".group(?).vehicle(?).configuration(?)#name", "Name of the configuration", nil, true)
	schema:register(XMLValueType.INT, "missionVehicles.mission(?)" .. ".group(?).vehicle(?).configuration(?)#id", "Id of the configuration", nil, true)
	local savegameSchema = MissionManager.xmlSchemaSavegame
	savegameSchema:register(XMLValueType.INT, "missions#version", "Version")
	for _, missionType in ipairs(g_missionManager.missionTypes) do
		local classObject = missionType.classObject
		local key = string.format("missions.meta.%s", missionType.name)
		if classObject.registerMetaXMLPaths == nil then
			continue
		end
		classObject.registerMetaXMLPaths(savegameSchema, key)
	end
	for _, missionType in ipairs(g_missionManager.missionTypes) do
		local classObject = missionType.classObject
		local key = string.format("missions.%s(?)", missionType.name)
		if classObject.registerSavegameXMLPaths == nil then
			continue
		end
		classObject.registerSavegameXMLPaths(savegameSchema, key)
	end
end)
function MissionManager.new(customMt)
	local self = AbstractManager.new(customMt or MissionManager_mt)
	self.defaultMissionMapWidth = 512
	self.defaultMissionMapHeight = 512
	self.missionMapNumChannels = 4
	return self
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
function MissionManager:loadMapData(xmlFile)
	MissionManager:superClass().loadMapData(self)
	local isEnabled = Utils.getNoNil(getXMLBool(xmlFile, "map.missions#enabled"), true)
	if not isEnabled then
		Logging.xmlInfo(xmlFile, "MissionManager: Disabled missions according to configuration")
	else
		self:createMissionMap()
		local currentMission = g_currentMission
		local xmlFileObj = XMLFile.wrap(xmlFile, Mission00.xmlSchema)
		for _, missionType in ipairs(self.missionTypes) do
			local classObject = missionType.classObject
			local key = string.format("map.missions.%s", missionType.name)
			local data = missionType.data
			data.maxNumInstances = xmlFileObj:getInt(key .. "#maxNumInstances") or data.maxNumInstances
			if classObject.loadMapData == nil then
				continue
			end
			classObject.loadMapData(xmlFileObj, key, currentMission.baseDirectory)
		end
		xmlFileObj:delete()
		if currentMission:getIsServer() then
			currentMission:addUpdateable(self)
		end
		local missionVehicleXmlFilename = getXMLString(xmlFile, "map.missions#vehicleFilename")
		if missionVehicleXmlFilename ~= nil then
			local path = Utils.getFilename(missionVehicleXmlFilename, currentMission.baseDirectory)
			if path ~= nil then
				self:loadVehicleGroups(path, currentMission.baseDirectory)
			end
		else
			Logging.xmlDevWarning(xmlFile, "MissionManager: No vehicleFilename defined for mission vehicles")
		end
		for _, info in ipairs(self.pendingMissionVehicleFiles) do
			self:loadVehicleGroups(info[1], info[2])
		end
		if g_addTestCommands and g_server ~= nil then
			addConsoleCommand("gsMissionGenerate", "Force generating a new mission for given farmland", "consoleGenerateMission", self, "farmlandId; missionType")
			addConsoleCommand("gsMissionLoadVehicleSet", "Loads a specific vehicle set", "consoleLoadVehicleSet", self, "missionType; [size (small|medium|large)]; [groupIndex]")
			addConsoleCommand("gsMissionLoadVehiclesAll", "Loads all mission vehicles", "consoleLoadAllVehicleSets", self, "")
		end
	end
end
function MissionManager:unloadMapData()
	g_messageCenter:unsubscribeAll(self)
	local currentMission = g_currentMission
	currentMission:removeUpdateable(self)
	for _, missionType in ipairs(self.missionTypes) do
		local classObject = missionType.classObject
		if classObject.unloadMapData == nil then
			continue
		end
		classObject.unloadMapData(missionType.data)
	end
	self:destroyMissionMap()
	removeConsoleCommand("gsMissionGenerate")
	removeConsoleCommand("gsMissionLoadVehicleSet")
	removeConsoleCommand("gsMissionLoadVehiclesAll")
	MissionManager:superClass().unloadMapData(self)
end
function MissionManager:saveToXMLFile(xmlFilename)
	local xmlFile = XMLFile.create("missionXML", xmlFilename, "missions", MissionManager.xmlSchemaSavegame)
	if xmlFile ~= nil then
		for _, missionType in ipairs(self.missionTypes) do
			local classObject = missionType.classObject
			local key = string.format("missions.meta.%s", missionType.name)
			if classObject.saveMetaDataToXMLFile == nil then
				continue
			end
			classObject.saveMetaDataToXMLFile(xmlFile, key)
		end
		local counts = {}
		xmlFile:setValue("missions#version", MissionManager.VERSION)
		for k, mission in ipairs(self.missions) do
			counts[mission.type.name] = (counts[mission.type.name] or 0) + 1
			local missionKey = string.format("missions.%s(%d)", mission.type.name, counts[mission.type.name] - 1)
			mission:saveToXMLFile(xmlFile, missionKey)
		end
		xmlFile:save()
		xmlFile:delete()
	end
	return false
end
function MissionManager:loadFromXMLFile(xmlFilename)
	if xmlFilename == nil then
		return false
	end
	local xmlFile = XMLFile.load("missionsXML", xmlFilename, MissionManager.xmlSchemaSavegame)
	if xmlFile == nil then
		return false
	end
	local version = xmlFile:getValue("missions#version")
	if version ~= MissionManager.VERSION then
		Logging.xmlWarning(xmlFile, "Missions version does not match current mission manager version")
		xmlFile:delete()
		return true
	else
		for _, missionType in ipairs(self.missionTypes) do
			local classObject = missionType.classObject
			local key = string.format("missions.meta.%s", missionType.name)
			if classObject.loadMetaDataFromXMLFile == nil then
				continue
			end
			classObject.loadMetaDataFromXMLFile(xmlFile, key)
		end
		local numElements = {}
		for _, key in xmlFile:iterator("missions.*") do
			local missionTypeName = xmlFile:getElementName(key)
			numElements[missionTypeName] = (numElements[missionTypeName] or 0) + 1
			local missionTypeKey = string.format("missions.%s(%d)", missionTypeName, numElements[missionTypeName] - 1)
			if missionTypeName == "meta" then
				continue
			end
			local missionType = self:getMissionType(missionTypeName)
			if missionType ~= nil then
				local mission = missionType.classObject.new(true, g_client ~= nil)
				mission.type = missionType
				self:assignGenerationTime(mission)
				if mission:loadFromXMLFile(xmlFile, missionTypeKey) then
					local hasValidFarm = mission.farmId == nil or g_farmManager:getFarmById(mission.farmId) ~= nil
					if hasValidFarm then
						mission:register()
						self:addMission(mission)
					else
						table.insert(self.missionsToDelete, mission)
					end
				else
					if mission.failedToLoadFromXMLFile ~= nil then
						mission:failedToLoadFromXMLFile()
					end
					table.insert(self.missionsToDelete, mission)
				end
			else
				Logging.xmlWarning(xmlFile, "Mission type '%s' not found for '%s!", missionTypeName, missionTypeKey)
			end
		end
		xmlFile:delete()
		return true
	end
end
function MissionManager:getCanStartNewMissionGeneration()
	return not self.missionGenerationInProgress and #self.missions < MissionManager.MAX_MISSIONS and self.generationTimer < 0
end
function MissionManager:update(dt)
	local currentMission = g_currentMission
	if currentMission:getIsServer() and Platform.gameplay.hasMissions then
		self.generationTimer = self.generationTimer - currentMission:getEffectiveTimeScale() * dt
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
function MissionManager:updateMissions(dt)
	for _, mission in ipairs(self.missions) do
		if mission.status == MissionStatus.CREATED then
			if mission:validate() then
				continue
			end
			table.insert(self.missionsToDelete, mission)
		end
	end
	for i = #self.missionsToDelete, 1, -1 do
		local mission = table.remove(self.missionsToDelete, i)
		mission:delete()
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
function MissionManager:generateMission()
	local missionType = self.missionTypes[self.currentMissionTypeIndex]
	if missionType == nil then
		self:finishMissionGeneration()
		return
	end
	local success = false
	local classObject = missionType.classObject
	if classObject.tryGenerateMission ~= nil then
		local mission = classObject.tryGenerateMission()
		if mission ~= nil then
			self:registerMission(mission, missionType)
			success = true
		end
	end
	self.currentMissionTypeIndex = self.currentMissionTypeIndex + 1
	if #self.missionTypes < self.currentMissionTypeIndex then
		self.currentMissionTypeIndex = 1
	end
	if self.currentMissionTypeIndex == self.startMissionTypeIndex then
		self:finishMissionGeneration()
	elseif success then
		self:finishMissionGeneration()
	end
end
function MissionManager:registerMission(mission, missionType)
	mission.type = missionType
	mission:register()
	self:addMission(mission)
	g_messageCenter:publish(MessageType.MISSION_GENERATED, mission)
end
function MissionManager:addMission(mission)
	if mission:getUniqueId() ~= nil and self.missionByUniqueId[mission:getUniqueId()] ~= nil then
		Logging.warning("Tried to add existing mission with unique id of %s! Existing: %s, new: %s", mission:getUniqueId(), tostring(self.missionByUniqueId[mission:getUniqueId()]), tostring(mission))
		return
	end
	if mission:getUniqueId() == nil then
		mission:setUniqueId(Utils.getUniqueId(mission, self.missionByUniqueId, MissionManager.UNIQUE_ID_PREFIX))
	end
	self.missionByUniqueId[mission:getUniqueId()] = mission
	table.addElement(self.missions, mission)
end
function MissionManager:removeMission(mission)
	table.removeElement(self.missions, mission)
	local uniqueId = mission:getUniqueId()
	if uniqueId ~= nil then
		self.missionByUniqueId[uniqueId] = nil
	end
end
function MissionManager:markMissionForDeletion(mission)
	table.addElement(self.missionsToDelete, mission)
end
function MissionManager:getMissionByUniqueId(uniqueId)
	return self.missionByUniqueId[uniqueId]
end
function MissionManager:startMission(mission, farmId, spawnVehicles)
	local currentMission = g_currentMission
	assert(currentMission:getIsServer(), "MissionManager:startMission is a server-only function")
	if farmId == FarmManager.SPECTATOR_FARM_ID then
		return MissionStartState.NO_ACCESS
	end
	if self:hasFarmReachedMissionLimit(farmId) then
		return MissionStartState.LIMIT_REACHED
	end
	if mission.activeMissionId then
		return MissionStartState.ALREADY_STARTED
	end
	for _, activeMission in ipairs(self.missions) do
		if activeMission.status == MissionStatus.PREPARING then
			return MissionStartState.PENDING_MISSION
		end
	end
	if not mission:validate() then
		mission:delete()
		return MissionStartState.NOT_AVAILABLE_ANYMORE
	end
	mission.activeMissionId = self:getFreeActiveMissionId()
	if mission.activeMissionId == 0 then
		return MissionStartState.CANNOT_BE_STARTED_NOW
	end
	mission.farmId = farmId
	if not mission:start(spawnVehicles) then
		mission:delete()
		return MissionStartState.CANNOT_BE_STARTED_NOW
	else
		g_messageCenter:publish(MissionStartedEvent, mission)
		return MissionStartState.OK
	end
end
function MissionManager:cancelMission(mission)
	local currentMission = g_currentMission
	assert(currentMission:getIsServer(), "MissionManager:cancelMission is a server-only function")
	if mission ~= nil and mission.status ~= MissionStatus.FINISHED then
		mission:finish(MissionFinishState.CANCELED)
		return true
	end
	return false
end
function MissionManager:dismissMission(mission)
	local currentMission = g_currentMission
	assert(currentMission:getIsServer(), "MissionManager:dismissMission is a server-only function")
	mission:dismiss()
	mission:delete()
	return true
end
function MissionManager:getMissions()
	return self.missions
end
function MissionManager:getMissionsByFarmId(farmId)
	return table.ifilter(self.missions, function(mission)
		return mission.farmId == nil or mission.farmId == farmId
	end)
end
function MissionManager:getIsMissionRunningOnFarmland(farmland)
	if farmland == nil then
		return false
	else
		local farmlandId = farmland:getId()
		for _, mission in ipairs(self.missions) do
			if mission.getFarmlandId == nil then
				continue
			end
			if mission:getFarmlandId() == farmlandId and mission:getIsInProgress() then
				return true
			end
		end
		return false
	end
end
function MissionManager:getMissionByFarmlandId(farmlandId)
	if farmlandId == nil then
		return nil
	else
		for _, mission in ipairs(self.missions) do
			if mission.getFarmlandId == nil then
				continue
			end
			if mission:getFarmlandId() == farmlandId then
				return mission
			end
		end
		return nil
	end
end
function MissionManager:getMissionsByType(typeIndex)
	local missionType = self.missionTypes[typeIndex]
	if missionType == nil then
		return nil
	else
		return table.ifilter(self.missions, function(mission)
			return mission:isa(missionType.classObject)
		end)
	end
end
function MissionManager:hasFarmReachedMissionLimit(farmId)
	local total = 0
	for _, mission in ipairs(self.missions) do
		if mission.farmId == farmId and mission:getWasStarted() then
			total = total + 1
		end
	end
	return MissionManager.MAX_MISSIONS_PER_FARM <= total
end
function MissionManager:createMissionMap()
	self.missionMap = InfoLayer.new("MissionAccessMap")
	self.missionMap:create(self.defaultMissionMapWidth, self.defaultMissionMapHeight, self.missionMapNumChannels, false)
	local currentMission = g_currentMission
	if currentMission:getIsServer() then
		currentMission.growthSystem:setGrowthMask(self.missionMap:getId(), 0, self.missionMapNumChannels)
	end
	if MissionManager.DEBUG_ENABLED then
		local cellsize = currentMission.terrainSize / self.defaultMissionMapWidth
		self.debugBitVectorMap = DebugBitVectorMap.newSimple(20, cellsize, false, 0.2)
		self.debugBitVectorMap:createWithCustomFunc(function(instance, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
			local centerX = (startWorldX + widthWorldX + heightWorldX) / 3
			local centerZ = (startWorldZ + widthWorldZ + heightWorldZ) / 3
			local value = self.missionMap:getValueAtWorldPos(centerX, centerZ)
			return value
		end)
		g_debugManager:addElement(self.debugBitVectorMap)
	end
end
function MissionManager:destroyMissionMap()
	local currentMission = g_currentMission
	if currentMission:getIsServer() then
		currentMission.growthSystem:resetGrowthMask()
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
	if self.missionMap == nil then
		return 0
	else
		return self.missionMap:getValueAtWorldPos(worldX, worldZ, nil, nil)
	end
end
function MissionManager:getMissionAtWorldPosition(worldX, worldZ)
	local missionId = self:getMissionMapActiveMissionIdAtWorldPosition(worldX, worldZ)
	if 0 < missionId then
		return self:getMissionByActiveMissionId(missionId)
	else
		return nil
	end
end
function MissionManager:getMissionByActiveMissionId(activeMissionId)
	for _, mission in ipairs(self.missions) do
		if mission.activeMissionId == activeMissionId then
			return mission
		end
	end
	return nil
end
function MissionManager:getFreeActiveMissionId()
	for i = 1, MissionManager.MAX_MISSIONS do
		if self:getMissionByActiveMissionId(i) == nil then
			return i
		end
	end
	return 0
end
function MissionManager:getIsMissionWorkAllowed(farmId, x, z, workAreaType, vehicle)
	local mission = self:getMissionAtWorldPosition(x, z)
	if mission ~= nil and (mission.farmId == farmId and mission:getIsWorkAllowed(farmId, x, z, workAreaType, vehicle)) then
		return true
	end
	return false
end
function MissionManager:registerMissionType(classObject, name, defaultMaxNumInstances)
	if classObject ~= nil and name ~= nil then
		local missionType = { name = name, classObject = classObject }
		missionType.typeId = #self.missionTypes + 1
		missionType.data = { numInstances = 0, maxNumInstances = defaultMaxNumInstances or 2 }
		table.insert(self.missionTypes, missionType)
		self.nameToMissionType[string.upper(name)] = missionType
	end
end
function MissionManager:unregisterMissionType(name)
	if name ~= nil then
		for i, type in ipairs(self.missionTypes) do
			if type.name == name then
				table.remove(self.missionType, i)
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
function MissionManager:getMissionTypeDataByName(name)
	if name == nil then
		Logging.devError("MissionManager.getMissionTypeDataByName: no mission type name defined")
		if g_isDevelopmentVersion then
			printCallstack()
		end
		return nil
	end
	local missionType = self.nameToMissionType[string.upper(name)]
	if missionType ~= nil then
		return missionType.data
	else
		return nil
	end
end
function MissionManager:getMissionBySplitShape(shape)
	if shape == nil or shape == 0 then
		return nil
	end
	for _, mission in ipairs(self.missions) do
		if mission.getIsMissionSplitShape == nil then
			continue
		end
		if mission:getIsMissionSplitShape(shape) then
			return mission
		end
	end
	return nil
end
function MissionManager:getIsShapeCutAllowed(shape, x, z, farmId)
	for _, mission in ipairs(self.missions) do
		if mission.getIsShapeCutAllowed == nil then
			continue
		end
		local isAllowed = mission:getIsShapeCutAllowed(shape, x, z, farmId)
		if isAllowed == nil then
			continue
		end
		return isAllowed
	end
	return nil
end
function MissionManager:getIsMissionDestructible(farmId, nodeId)
	for _, mission in ipairs(self.missions) do
		if mission.getDestructibleIsInMissionArea == nil then
			continue
		end
		if mission:getDestructibleIsInMissionArea(nodeId, farmId) then
			return true
		end
	end
	return false
end
function MissionManager:addPendingMissionVehiclesFile(filename, baseDirectory)
	table.insert(self.pendingMissionVehicleFiles, { filename, baseDirectory })
end
function MissionManager:loadVehicleGroups(xmlFilename, baseDirectory)
	local xmlFile = XMLFile.load("MissionVehicles", xmlFilename, MissionManager.xmlSchema)
	if xmlFile == nil then
		return false
	else
		for _, missionKey in xmlFile:iterator("missionVehicles.mission") do
			local missionTypeName = xmlFile:getValue(missionKey .. "#type")
			if missionTypeName == nil then
				Logging.xmlError(xmlFile, "Property type must exist on each mission - '%s'", missionKey)
			else
				local missionType = self:getMissionType(missionTypeName)
				if missionType == nil then
					Logging.xmlError(xmlFile, "Mission type '%s' is not defined - '%s'", missionTypeName, missionKey)
				else
					if self.missionVehicles[missionTypeName] == nil then
						self.missionVehicles[missionTypeName] = {}
					end
					local groups = self.missionVehicles[missionTypeName]
					for _, groupKey in xmlFile:iterator(missionKey .. ".group") do
						local size = xmlFile:getValue(groupKey .. "#size", "medium")
						local rewardScale = xmlFile:getValue(groupKey .. "#rewardScale", 1)
						local success = true
						local vehicles = {}
						local group = { rewardScale = rewardScale, vehicles = vehicles }
						group.variant = xmlFile:getValue(groupKey .. "#variant")
						for _, vehicleKey in xmlFile:iterator(groupKey .. ".vehicle") do
							local vehicleXMLFilename = Utils.getFilename(xmlFile:getValue(vehicleKey .. "#filename"), baseDirectory)
							if vehicleXMLFilename == nil then
								success = false
								Logging.xmlError(xmlFile, "Missing 'filename' attribute for vehicle %q", vehicleKey)
								break
							end
							local storeItem = g_storeManager:getItemByXMLFilename(vehicleXMLFilename)
							if storeItem == nil then
								success = false
								Logging.xmlError(xmlFile, "Unable to load store item for xml filename '%q at %q", vehicleXMLFilename, vehicleKey)
								break
							end
							local configurations = nil
							for _, configKey in xmlFile:iterator(vehicleKey .. ".configuration") do
								local name = xmlFile:getValue(configKey .. "#name")
								local id = xmlFile:getValue(configKey .. "#id")
								if name == nil then
									Logging.xmlError(xmlFile, "Missing 'name' attribute for configuration at %q", configKey)
								elseif id == nil then
									Logging.xmlError(xmlFile, "Missing 'id' attribute for configuration %q at %q", name, configKey)
								else
									configurations = configurations or {}
									configurations[name] = id
								end
							end
							table.insert(vehicles, { filename = vehicleXMLFilename, configurations = configurations })
						end
						if success then
							if groups[size] == nil then
								groups[size] = {}
							end
							table.insert(groups[size], group)
							group.identifier = #groups[size]
						end
					end
				end
			end
		end
		xmlFile:delete()
		return true
	end
end
function MissionManager:getRandomVehicleGroup(missionType, size, variant)
	local groups = self.missionVehicles[missionType]
	if groups == nil then
		return nil, 1
	end
	local sized = groups[size]
	if sized == nil then
		return nil, 1
	end
	local variantGroups = table.ifilter(sized, function(group)
		return variant == nil or group.variant == variant
	end)
	local group = table.getRandomElement(variantGroups)
	if group == nil then
		return nil, 1
	else
		return group.vehicles, group.identifier
	end
end
function MissionManager:getVehicleGroupFromIdentifier(missionType, fieldSize, identifier)
	local groups = self.missionVehicles[missionType]
	if groups == nil then
		return nil, 1, "No vehicles for missionType"
	end
	local sized = groups[fieldSize]
	if sized == nil then
		return nil, 1, "No vehicles for fieldSize"
	end
	local group = sized[identifier]
	if group == nil then
		return nil, 1, "No vehicles for index/indetifier"
	else
		return group.vehicles, group.rewardScale, "", group
	end
end
function MissionManager:assignGenerationTime(mission)
	mission.generationTime = self.nextGeneratedMissionId
	self.nextGeneratedMissionId = self.nextGeneratedMissionId + 1
end
function MissionManager:consoleGenerateMission(farmlandId, missionTypeName)
	farmlandId = tonumber(farmlandId)
	local farmland = g_farmlandManager:getFarmlandById(farmlandId)
	if farmland == nil then
		printError("Error: Given farmland not found")
		return
	end
	local field = farmland:getField()
	g_fieldManager.debugField = field
	if missionTypeName == nil then
		printError(string.format("Error: No mission type given"))
		print(string.format("Available mission types: %s", table.concatKeys(self.nameToMissionType, ", ")))
		return
	end
	local success = false
	local missionType = self:getMissionType(missionTypeName)
	if missionType == nil then
		printError(string.format("Error: Given missionType %q not found", missionTypeName))
		print(string.format("Available mission types: %s", table.concatKeys(self.nameToMissionType, ", ")))
		return
	end
	local classObject = missionType.classObject
	if classObject.tryGenerateMission ~= nil then
		local mission = classObject.tryGenerateMission()
		if mission ~= nil then
			self:registerMission(mission, missionType)
			success = true
		end
	end
	g_fieldManager.debugField = nil
	if success then
		return "Mission created"
	else
		printError("Error: Failed to create mission")
		return
	end
end
function MissionManager:consoleLoadVehicleSet(missionTypeName, size, groupIndex)
	size = size or "medium"
	groupIndex = tonumber(groupIndex) or 1
	local foundMissionType = false
	local missionTypeNames = {}
	for _, missionType in ipairs(self.missionTypes) do
		table.insert(missionTypeNames, missionType.name)
		if missionType.name == missionTypeName then
			foundMissionType = true
		end
	end
	if not foundMissionType then
		Logging.error("Unknown missionType %q", missionTypeName)
		print(string.format("Available mission types: %s", table.concat(missionTypeNames, ", ")))
		return
	end
	local vehicles, _, errorMessage = self:getVehicleGroupFromIdentifier(missionTypeName, size, groupIndex)
	if vehicles == nil then
		Logging.error("No vehicles defined for parameter. %s", errorMessage)
	else
		local numLoadedVehicles = 0
		local numVehiclesToLoad = #vehicles
		local onSpawnedVehicle = function(_, loadedVehicles, vehicleLoadState, arguments)
			if vehicleLoadState == VehicleLoadingState.OK then
				numLoadedVehicles = numLoadedVehicles + 1
				if numLoadedVehicles == numVehiclesToLoad then
					Logging.info("Finished mission vehicle loading")
				end
			else
				for _, vehicle in ipairs(loadedVehicles) do
					vehicle:delete()
				end
				Logging.error("Failed to load vehicles")
			end
		end
		for _, vehicleInfo in ipairs(vehicles) do
			local data = VehicleLoadingData.new()
			data:setFilename(vehicleInfo.filename)
			if data.isValid then
				if vehicleInfo.configurations ~= nil then
					data:setConfigurations(vehicleInfo.configurations)
				end
				local mission = g_currentMission
				data:setLoadingPlace(mission.storeSpawnPlaces, mission.usedStorePlaces)
				data:setOwnerFarmId(g_localPlayer:getFarmId())
				data:load(onSpawnedVehicle, nil, nil)
			end
		end
	end
end
function MissionManager:consoleLoadAllVehicleSets()
	local vehiclesToLoad = {}
	for missionType, missionSizes in pairs(self.missionVehicles) do
		for missionSize, variants in pairs(missionSizes) do
			for _, variant in ipairs(variants) do
				for _, vehicle in ipairs(variant.vehicles) do
					table.insert(vehiclesToLoad, vehicle)
				end
			end
		end
	end
	local numVehicles = #vehiclesToLoad
	local loadNextVehicle = nil
	local onSpawnedVehicle = function(_, loadedVehicles, vehicleLoadState, arguments)
		for _, vehicle in ipairs(loadedVehicles) do
			vehicle:delete()
		end
		if 0 < #vehiclesToLoad then
			loadNextVehicle()
		else
			Logging.info("Finished mission vehicle loading")
		end
	end
	function loadNextVehicle()
		local vehicleToLoad = table.remove(vehiclesToLoad, 1)
		if vehicleToLoad == nil then
			return
		else
			Logging.info("loading mission vehicle %d/%d", numVehicles - #vehiclesToLoad, numVehicles)
			local data = VehicleLoadingData.new()
			data:setFilename(vehicleToLoad.filename)
			if vehicleToLoad.configurations ~= nil then
				data:setConfigurations(vehicleToLoad.configurations)
			end
			local mission = g_currentMission
			data:setLoadingPlace(mission.storeSpawnPlaces, mission.usedStorePlaces)
			data:setOwnerFarmId(g_localPlayer:getFarmId())
			data:load(onSpawnedVehicle, nil, nil)
		end
	end
	Logging.info("Started loading %d mission vehicles", numVehicles)
	loadNextVehicle()
end
g_missionManager = MissionManager.new()
