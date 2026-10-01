DestructibleRockMission = {}
source("dataS/scripts/missions/map/DestructibleRockMissionHotspot.lua")
source("dataS/scripts/missions/map/WrongRockDestroyedEvent.lua")
DestructibleRockMission.COLLISION_MASK = CollisionFlag.STATIC_OBJECT
DestructibleRockMission.NAME = "destructibleRockMission"
local DestructibleRockMission_mt = Class(DestructibleRockMission, AbstractMission)
InitStaticObjectClass(DestructibleRockMission, "DestructibleRockMission")
function DestructibleRockMission.registerXMLPaths(schema, key)
	DestructibleRockMission:superClass().registerXMLPaths(schema, key)
	schema:register(XMLValueType.INT, key .. "#minNumRocks", "Min number of rocks")
	schema:register(XMLValueType.INT, key .. "#maxNumRocks", "Min number of rocks")
	schema:register(XMLValueType.INT, key .. "#maxNumInstances", "Max number of instances")
	schema:register(XMLValueType.INT, key .. "#rewardPerRock", "Reward per tree")
	schema:register(XMLValueType.INT, key .. "#penaltyPerRock", "Penalty per tree")
	schema:register(XMLValueType.STRING, key .. ".spots#filename", "Filename to rock spots")
	schema:register(XMLValueType.STRING, key .. ".marker#filename", "Filename to rock marker")
end
function DestructibleRockMission.registerSavegameXMLPaths(schema, key)
	DestructibleRockMission:superClass().registerSavegameXMLPaths(schema, key)
	schema:register(XMLValueType.INT, key .. "#spotIndex", "Spot index")
	schema:register(XMLValueType.INT, key .. "#numRocksDestroyed", "Number of destroyed rocks")
	schema:register(XMLValueType.INT, key .. ".destructible(?)#groupId", "Rock groupd id")
	schema:register(XMLValueType.INT, key .. ".destructible(?)#index", "Rock index")
	schema:register(XMLValueType.BOOL, key .. ".destructible(?)#isPartOfMission", "Rock is part of mission")
end
function DestructibleRockMission.registerMetaXMLPaths(schema, key)
	DestructibleRockMission:superClass().registerMetaXMLPaths(schema, key)
	schema:register(XMLValueType.INT, key .. "#nextDay", "Earliest day a new mission can spawn")
end
function DestructibleRockMission.new(isServer, isClient, customMt)
	local title = g_i18n:getText("contract_map_destructibleRock_title")
	local description = g_i18n:getText("contract_map_destructibleRock_description")
	local self = AbstractMission.new(isServer, isClient, title, description, customMt or DestructibleRockMission_mt)
	self.spot = nil
	self.rocks = {}
	self.rocksKeys = {}
	self.rocksAll = {}
	self.rocksAllKeys = {}
	self.rockToMarker = {}
	self.markerRootNode = nil
	self.numRocksDestroyed = 0
	self.wronglyDestroyedRocksPenalty = 0
	self.mapHotspot = nil
	self.isHotspotAdded = false
	g_currentMission.destructibleMapObjectSystem:registerDestructibleDestroyedListener(self, self.onRockDestroyed)
	local data = g_missionManager:getMissionTypeDataByName(DestructibleRockMission.NAME)
	table.addElement(data.activeMissions, self)
	return self
end
function DestructibleRockMission:init(spot, availableRocksOnFarmland)
	local res = DestructibleRockMission:superClass().init(self)
	if spot == nil then
		return false
	else
		self:setSpot(spot)
		local data = g_missionManager:getMissionTypeDataByName(DestructibleRockMission.NAME)
		for _, destructible in ipairs(availableRocksOnFarmland) do
			local rocksMaxReached = data.maxNumRocks <= #self.rocks
			local rocksMinReached = data.minNumRocks <= #self.rocks
			if not not rocksMinReached then
				local isPartOfMission = not rocksMaxReached and Utils.getCoinToss()
			end
			self:addDestructible(destructible, isPartOfMission)
		end
		local rewardPerRock = data.rewardPerRock
		self.reward = #self.rocks * rewardPerRock
		return res
	end
end
function DestructibleRockMission:addDestructible(destructible, isPartOfMission)
	if isPartOfMission then
		table.insert(self.rocks, destructible)
		self.rocksKeys[destructible] = true
	end
	table.insert(self.rocksAll, destructible)
	self.rocksAllKeys[destructible] = true
end
function DestructibleRockMission:setSpot(spot)
	self.spot = spot
	spot.isInUse = true
	self.farmlandId = spot.farmlandId
	if self.mapHotspot == nil then
		self.mapHotspot = DestructibleRockMissionHotspot.new()
	end
	local x = self.spot.x
	local z = self.spot.z
	local radius = self.spot.radius
	self.mapHotspot:setWorldPosition(x, z)
	self.mapHotspot:setWorldRadius(radius + 3)
	self.mapHotspots = { self.mapHotspot }
end
function DestructibleRockMission:delete()
	DestructibleRockMission:superClass().delete(self)
	local data = g_missionManager:getMissionTypeDataByName(DestructibleRockMission.NAME)
	if data ~= nil then
		table.removeElement(data.activeMissions, self)
		if self.spot ~= nil then
			data.spotsDisabled[self.spot] = nil
		end
	end
	self:removeHotspot()
	for _, rock in ipairs(self.rocksAll) do
		g_currentMission.destructibleMapObjectSystem:restoreDestructible(rock)
	end
	for _, marker in pairs(self.rockToMarker) do
		delete(marker)
	end
	self.rockToMarker = nil
	if self.markerRootNode ~= nil then
		delete(self.markerRootNode)
		self.markerRootNode = nil
	end
	g_currentMission.destructibleMapObjectSystem:unregisterDestructibleDestroyedListener(self)
	if self.spot ~= nil then
		self.spot.isInUse = false
		self.spot = nil
	end
	if self.mapHotspot ~= nil then
		self.mapHotspot:delete()
		self.mapHotspot = nil
	end
	self.mapHotspots = nil
end
function DestructibleRockMission:saveToXMLFile(xmlFile, key)
	DestructibleRockMission:superClass().saveToXMLFile(self, xmlFile, key)
	xmlFile:setValue(key .. "#spotIndex", self.spot.index)
	xmlFile:setValue(key .. "#numRocksDestroyed", self.numRocksDestroyed)
	for i, rock in ipairs(self.rocksAll) do
		local rockKey = string.format("%s.destructible(%d)", key, i - 1)
		local group, index = g_currentMission.destructibleMapObjectSystem:getGroupAndIndexForDestructible(rock)
		xmlFile:setValue(rockKey .. "#groupId", group.groupId)
		xmlFile:setValue(rockKey .. "#index", index)
		if self.rocksKeys[rock] == nil then
			xmlFile:setValue(rockKey .. "#isPartOfMission", false)
		end
	end
end
function DestructibleRockMission:loadFromXMLFile(xmlFile, key)
	DestructibleRockMission:superClass().loadFromXMLFile(self, xmlFile, key)
	local spotIndex = xmlFile:getValue(key .. "#spotIndex") or 0
	local data = g_missionManager:getMissionTypeDataByName(DestructibleRockMission.NAME)
	local spot = data.spots[spotIndex]
	if spot == nil then
		return false
	else
		self:setSpot(spot)
		self.numRocksDestroyed = xmlFile:getValue(key .. "#numRocksDestroyed")
		for _, destructibleKey in xmlFile:iterator(key .. ".destructible") do
			local groupId = xmlFile:getValue(destructibleKey .. "#groupId")
			local index = xmlFile:getValue(destructibleKey .. "#index")
			local isPartOfMission = xmlFile:getValue(destructibleKey .. "#isPartOfMission", true)
			local groupRoot = g_currentMission.destructibleMapObjectSystem:getGroupRootById(groupId)
			if groupRoot == nil then
				Logging.xmlWarning(xmlFile, "DestructibleRockMission: GroupId %q in mission %q is not defined in the map, ignoring", groupId, key)
			else
				local numChildren = getNumOfChildren(groupRoot)
				if numChildren - 1 < index then
					Logging.xmlWarning(xmlFile, "DestructibleRockMission: Index %d out of range for groupId %q in mission %q, group only has %d children, ignoring", index, groupId, key, numChildren)
				else
					local destructible = getChildAt(groupRoot, index)
					self:addDestructible(destructible, isPartOfMission)
				end
			end
		end
		return true
	end
end
function DestructibleRockMission:writeStream(streamId, connection)
	DestructibleRockMission:superClass().writeStream(self, streamId, connection)
	streamWriteUInt8(streamId, self.spot.index)
	streamWriteUInt8(streamId, self.numRocksDestroyed)
	streamWriteUInt8(streamId, #self.rocksAll)
	for i, rock in ipairs(self.rocksAll) do
		local group, index = g_currentMission.destructibleMapObjectSystem:getGroupAndIndexForDestructible(rock)
		streamWriteUIntN(streamId, group.groupId, DestructibleMapObjectSystem.GROUP_ID_NUM_BITS)
		streamWriteUIntN(streamId, index, DestructibleMapObjectSystem.CHILD_INDEX_NUM_BITS)
		streamWriteBool(streamId, self.rocksKeys[rock] ~= nil)
	end
end
function DestructibleRockMission:readStream(streamId, connection)
	DestructibleRockMission:superClass().readStream(self, streamId, connection)
	local spotIndex = streamReadUInt8(streamId)
	local data = g_missionManager:getMissionTypeDataByName(DestructibleRockMission.NAME)
	local spot = data.spots[spotIndex]
	self:setSpot(spot)
	self.numRocksDestroyed = streamReadUInt8(streamId)
	local numRocksAll = streamReadUInt8(streamId)
	for i = 1, numRocksAll do
		local groupId = streamReadUIntN(streamId, DestructibleMapObjectSystem.GROUP_ID_NUM_BITS)
		local index = streamReadUIntN(streamId, DestructibleMapObjectSystem.CHILD_INDEX_NUM_BITS)
		local isPartOfMission = streamReadBool(streamId)
		local groupRoot = g_currentMission.destructibleMapObjectSystem:getGroupRootById(groupId)
		local destructible = getChildAt(groupRoot, index)
		self:addDestructible(destructible, isPartOfMission)
	end
end
function DestructibleRockMission:readUpdateStream(streamId, timestamp, connection)
	DestructibleRockMission:superClass().readUpdateStream(self, streamId, timestamp, connection)
	self.numRocksDestroyed = streamReadUInt8(streamId)
end
function DestructibleRockMission:writeUpdateStream(streamId, connection, dirtyMask)
	DestructibleRockMission:superClass().writeUpdateStream(self, streamId, connection, dirtyMask)
	streamWriteUInt8(streamId, self.numRocksDestroyed)
end
function DestructibleRockMission:update(dt)
	if self.status == MissionStatus.RUNNING and (g_localPlayer ~= nil and (g_localPlayer.farmId == self.farmId and not self.isHotspotAdded)) then
		self:addHotspot()
	end
	if not self.markersAdded and self.status == MissionStatus.RUNNING then
		self:addRockMarkers()
	end
	DestructibleRockMission:superClass().update(self, dt)
end
function DestructibleRockMission:getDestructibleIsInMissionArea(destructible, farmId)
	if self.status == MissionStatus.RUNNING and self.farmId == farmId then
		return self.rocksAllKeys[destructible] ~= nil
	end
	return false
end
function DestructibleRockMission:onRockDestroyed(destructible)
	if self.status ~= MissionStatus.RUNNING then
		return
	end
	if not self.rocksAllKeys[destructible] then
		return
	end
	if self.rocksKeys[destructible] then
		local marker = self.rockToMarker[destructible]
		if marker then
			setVisibility(marker, false)
		end
		if self.isServer then
			self.numRocksDestroyed = self.numRocksDestroyed + 1
		end
	elseif self.isServer then
		local data = g_missionManager:getMissionTypeDataByName(DestructibleRockMission.NAME)
		self.wronglyDestroyedRocksPenalty = self.wronglyDestroyedRocksPenalty + data.penaltyPerRock
		g_currentMission:broadcastEventToFarm(WrongRockDestroyedEvent.new(), self.farmId, true)
	end
end
function DestructibleRockMission:rockMarkerRaycastCallback(nodeId, x, y, z)
	if nodeId ~= 0 and nodeId ~= g_terrainNode then
		if self.rockToMarker == nil or self.status ~= MissionStatus.RUNNING then
			return false
		end
		local destructibleMapObjectSystem = g_currentMission.destructibleMapObjectSystem
		local destructible = destructibleMapObjectSystem:getDestructibleFromNode(nodeId)
		if destructible then
			local marker = self.rockToMarker[destructible]
			if marker then
				setWorldTranslation(marker, x, y - 0.15, z)
				setWorldRotation(marker, 0, 0, 0)
			end
			return false
		end
	end
	return true
end
function DestructibleRockMission:addRockMarkers()
	if self.markersAdded then
		return
	else
		if self.markerRootNode == nil then
			self.markerRootNode = createTransformGroup("destructibleRockMissionMarkers")
			link(getRootNode(), self.markerRootNode)
		end
		local data = g_missionManager:getMissionTypeDataByName(DestructibleRockMission.NAME)
		for index, rock in pairs(self.rocks) do
			if getEffectiveVisibility(rock) then
				local marker = clone(data.markerNode, false, false, false)
				link(self.markerRootNode, marker)
				self.rockToMarker[rock] = marker
				local x, y, z = getWorldTranslation(rock)
				raycastAll(x, y + 10, z, 0, -1, 0, 10, "rockMarkerRaycastCallback", self, DestructibleRockMission.COLLISION_MASK)
			end
		end
		self.markersAdded = true
	end
end
function DestructibleRockMission:getLocation()
	return string.format(g_i18n:getText("contract_farmland"), self.farmlandId)
end
function DestructibleRockMission:getMapHotspots()
	return self.mapHotspots
end
function DestructibleRockMission:getWorldPosition()
	local spot = self.spot
	if spot ~= nil then
		return spot.x, spot.z
	else
		local farmland = g_farmlandManager:getFarmlandById(self.farmlandId)
		return farmland:getIndicatorPosition()
	end
end
function DestructibleRockMission:finish(finishState)
	self:removeHotspot()
	local data = g_missionManager:getMissionTypeDataByName(DestructibleRockMission.NAME)
	if #self.rocksAll - self.numRocksDestroyed < data.minNumRocks then
		data.spotsDisabled[self.spot] = true
	end
	local mission = g_currentMission
	if mission:getFarmId() == self.farmId then
		if finishState == MissionFinishState.SUCCESS then
			mission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_OK, string.format(g_i18n:getText("contract_map_destructibleRock_completed"), self.farmlandId))
		elseif finishState == MissionFinishState.FAILED then
			mission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_CRITICAL, string.format(g_i18n:getText("contract_map_destructibleRock_failed"), self.farmlandId))
		elseif finishState == MissionFinishState.TIMED_OUT then
			mission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_CRITICAL, string.format(g_i18n:getText("contract_map_destructibleRock_timedOut"), self.farmlandId))
		end
	end
	DestructibleRockMission:superClass().finish(self, finishState)
end
function DestructibleRockMission:addHotspot()
	if self.mapHotspot ~= nil then
		self.isHotspotAdded = true
		g_currentMission:addMapHotspot(self.mapHotspot)
	end
end
function DestructibleRockMission:removeHotspot()
	if self.mapHotspot ~= nil then
		g_currentMission:removeMapHotspot(self.mapHotspot)
		self.isHotspotAdded = false
	end
end
function DestructibleRockMission:validate()
	local res = DestructibleRockMission:superClass().validate(self)
	if not res then
		return false
	else
		local farmland = g_farmlandManager:getFarmlandById(self.farmlandId)
		if farmland == nil or farmland.isOwned then
			return false
		end
		return res
	end
end
function DestructibleRockMission:dismiss()
	if self.isServer then
		local change = 0
		if self.finishState == MissionFinishState.SUCCESS then
			change = self:getReward()
		end
		change = change - self.wronglyDestroyedRocksPenalty
		if change ~= 0 then
			g_currentMission:addMoney(change, self.farmId, MoneyType.MISSIONS, true, true)
		end
	end
end
function DestructibleRockMission:getNPC()
	local farmland = g_farmlandManager:getFarmlandById(self.farmlandId)
	local npc = g_npcManager:getNPCByIndex(farmland.npcIndex)
	return npc
end
function DestructibleRockMission:getExtraProgressText()
	local remaining = #self.rocks - self.numRocksDestroyed
	if remaining == 1 then
		return g_i18n:getText("contract_map_destructibleRock_oneRemainingRock")
	else
		return string.format(g_i18n:getText("contract_map_destructibleRock_remainingRocks"), remaining)
	end
end
function DestructibleRockMission:getCompletion()
	return self.numRocksDestroyed / #self.rocks
end
function DestructibleRockMission:getReward()
	return self.reward
end
function DestructibleRockMission:getFarmlandId()
	return self.farmlandId
end
function DestructibleRockMission:getDetails()
	local details = DestructibleRockMission:superClass().getDetails(self)
	local data = g_missionManager:getMissionTypeDataByName(DestructibleRockMission.NAME)
	table.insert(details, { title = g_i18n:getText("contract_details_farmland"), value = self.farmlandId })
	table.insert(details, { title = g_i18n:getText("contract_map_destructibleRock_details_reward"), value = g_i18n:formatMoney(data.rewardPerRock, 0, true) })
	table.insert(details, { title = g_i18n:getText("contract_map_destructibleRock_details_penalty"), value = g_i18n:formatMoney(data.penaltyPerRock, 0, true) })
	table.insert(details, { title = g_i18n:getText("contract_map_destructibleRock_details_totalNumRocks"), value = #self.rocks })
	if self.status ~= MissionStatus.CREATED then
		table.insert(details, { title = g_i18n:getText("contract_map_destructibleRock_details_destroyedNumRocks"), value = self.numRocksDestroyed })
	end
	return details
end
function DestructibleRockMission:calculateStealingCost()
	return self.wronglyDestroyedRocksPenalty
end
function DestructibleRockMission:getMissionTypeName()
	return DestructibleRockMission.NAME
end
function DestructibleRockMission.loadMapData(xmlFile, key, baseDirectory)
	if not xmlFile:hasProperty(key) then
		return
	end
	local data = g_missionManager:getMissionTypeDataByName(DestructibleRockMission.NAME)
	data.spots = {}
	data.spotsDisabled = {}
	data.activeMissions = {}
	data.minNumRocks = xmlFile:getFloat(key .. "#minNumRocks") or 4
	data.maxNumRocks = xmlFile:getFloat(key .. "#maxNumRocks") or 10
	data.maxNumInstances = xmlFile:getInt(key .. "#maxNumInstances") or 1
	data.rewardPerRock = xmlFile:getFloat(key .. "#rewardPerRock") or 550
	data.penaltyPerRock = xmlFile:getFloat(key .. "#penaltyPerRock") or 1000
	local spotFilename = xmlFile:getString(key .. ".spots#filename")
	if spotFilename == nil then
		Logging.xmlWarning(xmlFile, "Missing spot definition file for destructible rock mission (%s)", key)
		return false
	end
	spotFilename = Utils.getFilename(spotFilename, baseDirectory)
	local i3dNode = g_i3DManager:loadI3DFile(spotFilename, false, false)
	if i3dNode == 0 then
		return false
	end
	local root = getChildAt(i3dNode, 0)
	link(getRootNode(), root)
	for i = 0, getNumOfChildren(root) - 1 do
		local spotNode = getChildAt(root, i)
		local x, y, z = getTranslation(spotNode)
		local radius = tonumber(getUserAttribute(spotNode, "radius"))
		if radius ~= nil then
			local farmlandId = g_farmlandManager:getFarmlandIdAtWorldPosition(x, z)
			local isValidFarmland = farmlandId ~= nil and farmlandId ~= FarmlandManager.NOT_BUYABLE_FARM_ID
			if isValidFarmland then
				y = getTerrainHeightAtWorldPos(g_terrainNode, x, y, z)
				local spot = { x = x, y = y, z = z, radius = radius, farmlandId = farmlandId }
				spot.index = #data.spots + 1
				spot.isInUse = false
				table.insert(data.spots, spot)
			else
				local farmland = "Not defined"
				if farmlandId == FarmlandManager.NOT_BUYABLE_FARM_ID then
					farmland = string.format("Not buyable (%d)", farmlandId)
				end
				Logging.xmlWarning(xmlFile, "Invalid farmland '%s' found for destructible rock mission spot '%s' at %d %d!", farmland, getName(spotNode), x, z)
			end
		else
			Logging.xmlWarning(xmlFile, "No radius defined for destructible rock mission spot '%s'!", getName(spotNode))
		end
	end
	data.spotRoot = root
	delete(i3dNode)
	local markerFilename = xmlFile:getString(key .. ".marker#filename")
	if markerFilename == nil then
		Logging.xmlWarning(xmlFile, "Missing marker file for destructible rock mission (%s)", key)
		return false
	end
	markerFilename = Utils.getFilename(markerFilename, baseDirectory)
	local markerI3dNode = g_i3DManager:loadI3DFile(markerFilename, false, false)
	if markerI3dNode == 0 then
		return false
	else
		data.markerNode = getChildAt(markerI3dNode, 0)
		unlink(data.markerNode)
		delete(markerI3dNode)
		return true
	end
end
function DestructibleRockMission.unloadMapData()
	local data = g_missionManager:getMissionTypeDataByName(DestructibleRockMission.NAME)
	if data.spotRoot ~= nil then
		delete(data.spotRoot)
	end
	if data.markerNode ~= nil then
		delete(data.markerNode)
	end
end
function DestructibleRockMission.loadMetaDataFromXMLFile(xmlFile, key)
	local data = g_missionManager:getMissionTypeDataByName(DestructibleRockMission.NAME)
	data.nextMissionDay = xmlFile:getValue(key .. "#nextDay")
end
function DestructibleRockMission.saveMetaDataToXMLFile(xmlFile, key)
	local data = g_missionManager:getMissionTypeDataByName(DestructibleRockMission.NAME)
	if data.nextMissionDay ~= nil then
		xmlFile:setValue(key .. "#nextDay", data.nextMissionDay)
	end
end
function DestructibleRockMission.onFinishCallback()
	local data = g_missionManager:getMissionTypeDataByName(DestructibleRockMission.NAME)
	data.rockCheck.isRunning = false
end
function DestructibleRockMission.onRockCallback(_, transformId, subShapeIndex, isLast)
	if transformId ~= 0 and getHasClassId(transformId, ClassIds.SHAPE) then
		local destructibleMapObjectSystem = g_currentMission.destructibleMapObjectSystem
		local destructible = destructibleMapObjectSystem:getDestructibleFromNode(transformId)
		if destructible ~= nil then
			local x, _, z = getWorldTranslation(transformId)
			local farmlandId = g_farmlandManager:getFarmlandIdAtWorldPosition(x, z)
			local data = g_missionManager:getMissionTypeDataByName(DestructibleRockMission.NAME)
			local rockCheck = data.rockCheck
			if farmlandId == rockCheck.farmlandId then
				table.insert(rockCheck.rocks, destructible)
			end
		end
	end
	if isLast then
		DestructibleRockMission.onFinishCallback()
	end
	return true
end
function DestructibleRockMission.tryGenerateMission()
	if DestructibleRockMission.canRun() then
		local data = g_missionManager:getMissionTypeDataByName(DestructibleRockMission.NAME)
		local rockCheck = data.rockCheck
		if rockCheck == nil then
			local spots = data.spots
			Utils.shuffle(spots)
			local blockedFarmlands = {}
			for _, activeMission in ipairs(data.activeMissions) do
				blockedFarmlands[activeMission.spot.farmlandId] = true
			end
			local foundSpot = nil
			for _, spot in ipairs(spots) do
				if data.spotsDisabled[spot] == nil then
					if spot.isInUse then
						continue
					end
					if blockedFarmlands[spot.farmlandId] == nil and g_farmlandManager:getFarmlandOwner(spot.farmlandId) == FarmlandManager.NO_OWNER_FARM_ID then
						foundSpot = spot
						break
					end
				end
			end
			if foundSpot == nil then
				return nil
			else
				rockCheck = {}
				rockCheck.spot = foundSpot
				rockCheck.isRunning = true
				rockCheck.rocks = {}
				rockCheck.farmlandId = foundSpot.farmlandId
				local x = foundSpot.x
				local y = foundSpot.y
				local z = foundSpot.z
				local radius = foundSpot.radius
				local collisionMask = DestructibleRockMission.COLLISION_MASK
				local height = foundSpot.height or 20
				overlapCylinderAsync(x, y, z, radius, height, Axis.Y, "onRockCallback", DestructibleRockMission, collisionMask)
				data.rockCheck = rockCheck
				return nil
			end
		elseif rockCheck.isRunning then
			return nil
		elseif #rockCheck.rocks < data.minNumRocks then
			data.spotsDisabled[rockCheck.spot] = true
			data.rockCheck = nil
			return nil
		else
			local mission = DestructibleRockMission.new(true, g_client ~= nil)
			if mission:init(rockCheck.spot, rockCheck.rocks) then
				local environment = g_currentMission.environment
				mission:setEndDate(environment.currentMonotonicDay + 2, MathUtil.hoursToMs(math.random(10, 18)))
				data.nextMissionDay = environment.currentMonotonicDay + math.random(4, 9)
			else
				mission:delete()
				mission = nil
			end
			data.rockCheck = nil
			return mission
		end
	end
	return nil
end
function DestructibleRockMission.canRun()
	local data = g_missionManager:getMissionTypeDataByName(DestructibleRockMission.NAME)
	if data.spots == nil then
		return false
	end
	local numSpots = #data.spots
	if numSpots == 0 then
		return false
	elseif data.maxNumInstances <= data.numInstances then
		return false
	else
		if data.nextMissionDay ~= nil then
			local monotonicDay = g_currentMission.environment.currentMonotonicDay
			if monotonicDay < data.nextMissionDay then
				return false
			end
		end
		return true
	end
end
g_missionManager:registerMissionType(DestructibleRockMission, DestructibleRockMission.NAME, 2)
