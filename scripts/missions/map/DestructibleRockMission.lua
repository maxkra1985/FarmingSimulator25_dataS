-- Local values: DestructibleRockMission_mt
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

-- Upvalues: DestructibleRockMission_mt
-- Local values: title, description, self, data
function DestructibleRockMission.new(isServer, isClient, customMt)
	-- upvalues: (copy) DestructibleRockMission_mt
	local v11_ = g_i18n:getText("contract_map_destructibleRock_title")
	local v12_ = g_i18n:getText("contract_map_destructibleRock_description")
	local v13_ = AbstractMission.new(isServer, isClient, v11_, v12_, customMt or DestructibleRockMission_mt)
	v13_.spot = nil
	v13_.rocks = {}
	v13_.rocksKeys = {}
	v13_.rocksAll = {}
	v13_.rocksAllKeys = {}
	v13_.rockToMarker = {}
	v13_.markerRootNode = nil
	v13_.numRocksDestroyed = 0
	v13_.wronglyDestroyedRocksPenalty = 0
	v13_.mapHotspot = nil
	v13_.isHotspotAdded = false
	g_currentMission.destructibleMapObjectSystem:registerDestructibleDestroyedListener(v13_, v13_.onRockDestroyed)
	local v14_ = g_missionManager:getMissionTypeDataByName(DestructibleRockMission.NAME)
	table.addElement(v14_.activeMissions, v13_)
	return v13_
end

-- Local values: res, data, _, destructible, rocksMaxReached, rocksMinReached, isPartOfMission, rewardPerRock
function DestructibleRockMission:init(spot, availableRocksOnFarmland)
	local v18_ = DestructibleRockMission:superClass().init(self)
	if spot == nil then
		return false
	end
	self:setSpot(spot)
	local v19_ = g_missionManager:getMissionTypeDataByName(DestructibleRockMission.NAME)
	for _, v20_ in ipairs(availableRocksOnFarmland) do
		local v21_ = #self.rocks >= v19_.maxNumRocks
		local v22_ = #self.rocks >= v19_.minNumRocks and not v21_ and true or false
		if v22_ then
			v22_ = Utils.getCoinToss()
		end
		self:addDestructible(v20_, v22_)
	end
	local v23_ = v19_.rewardPerRock
	self.reward = #self.rocks * v23_
	return v18_
end

function DestructibleRockMission:addDestructible(destructible, isPartOfMission)
	if isPartOfMission then
		local v27_ = self.rocks
		table.insert(v27_, destructible)
		self.rocksKeys[destructible] = true
	end
	local v28_ = self.rocksAll
	table.insert(v28_, destructible)
	self.rocksAllKeys[destructible] = true
end

-- Local values: x, z, radius
function DestructibleRockMission:setSpot(spot)
	self.spot = spot
	spot.isInUse = true
	self.farmlandId = spot.farmlandId
	if self.mapHotspot == nil then
		self.mapHotspot = DestructibleRockMissionHotspot.new()
	end
	local v31_ = self.spot.x
	local v32_ = self.spot.z
	local v33_ = self.spot.radius
	self.mapHotspot:setWorldPosition(v31_, v32_)
	self.mapHotspot:setWorldRadius(v33_ + 3)
	self.mapHotspots = { self.mapHotspot }
end

-- Local values: data, _, rock, _, marker
function DestructibleRockMission:delete()
	DestructibleRockMission:superClass().delete(self)
	local v35_ = g_missionManager:getMissionTypeDataByName(DestructibleRockMission.NAME)
	if v35_ ~= nil then
		table.removeElement(v35_.activeMissions, self)
		if self.spot ~= nil then
			v35_.spotsDisabled[self.spot] = nil
		end
	end
	self:removeHotspot()
	for _, v36_ in ipairs(self.rocksAll) do
		g_currentMission.destructibleMapObjectSystem:restoreDestructible(v36_)
	end
	for _, v37_ in pairs(self.rockToMarker) do
		delete(v37_)
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

-- Local values: i, rock, rockKey, group, index
function DestructibleRockMission:saveToXMLFile(xmlFile, key)
	DestructibleRockMission:superClass().saveToXMLFile(self, xmlFile, key)
	xmlFile:setValue(key .. "#spotIndex", self.spot.index)
	xmlFile:setValue(key .. "#numRocksDestroyed", self.numRocksDestroyed)
	for v41_, v42_ in ipairs(self.rocksAll) do
		local v43_ = string.format("%s.destructible(%d)", key, v41_ - 1)
		local v44_, v45_ = g_currentMission.destructibleMapObjectSystem:getGroupAndIndexForDestructible(v42_)
		xmlFile:setValue(v43_ .. "#groupId", v44_.groupId)
		xmlFile:setValue(v43_ .. "#index", v45_)
		if self.rocksKeys[v42_] == nil then
			xmlFile:setValue(v43_ .. "#isPartOfMission", false)
		end
	end
end

-- Local values: spotIndex, data, spot, _, destructibleKey, groupId, index, isPartOfMission, groupRoot, numChildren, destructible
function DestructibleRockMission:loadFromXMLFile(xmlFile, key)
	DestructibleRockMission:superClass().loadFromXMLFile(self, xmlFile, key)
	local v49_ = xmlFile:getValue(key .. "#spotIndex") or 0
	local v50_ = g_missionManager:getMissionTypeDataByName(DestructibleRockMission.NAME).spots[v49_]
	if v50_ == nil then
		return false
	end
	self:setSpot(v50_)
	self.numRocksDestroyed = xmlFile:getValue(key .. "#numRocksDestroyed")
	for _, v51_ in xmlFile:iterator(key .. ".destructible") do
		local v52_ = xmlFile:getValue(v51_ .. "#groupId")
		local v53_ = xmlFile:getValue(v51_ .. "#index")
		local v54_ = xmlFile:getValue(v51_ .. "#isPartOfMission", true)
		local v55_ = g_currentMission.destructibleMapObjectSystem:getGroupRootById(v52_)
		if v55_ == nil then
			Logging.xmlWarning(xmlFile, "DestructibleRockMission: GroupId %q in mission %q is not defined in the map, ignoring", v52_, key)
		else
			local v56_ = getNumOfChildren(v55_)
			if v56_ - 1 < v53_ then
				Logging.xmlWarning(xmlFile, "DestructibleRockMission: Index %d out of range for groupId %q in mission %q, group only has %d children, ignoring", v53_, v52_, key, v56_)
			else
				self:addDestructible(getChildAt(v55_, v53_), v54_)
			end
		end
	end
	return true
end

-- Local values: i, rock, group, index
function DestructibleRockMission:writeStream(streamId, connection)
	DestructibleRockMission:superClass().writeStream(self, streamId, connection)
	streamWriteUInt8(streamId, self.spot.index)
	streamWriteUInt8(streamId, self.numRocksDestroyed)
	streamWriteUInt8(streamId, #self.rocksAll)
	for _, v60_ in ipairs(self.rocksAll) do
		local v61_, v62_ = g_currentMission.destructibleMapObjectSystem:getGroupAndIndexForDestructible(v60_)
		streamWriteUIntN(streamId, v61_.groupId, DestructibleMapObjectSystem.GROUP_ID_NUM_BITS)
		streamWriteUIntN(streamId, v62_, DestructibleMapObjectSystem.CHILD_INDEX_NUM_BITS)
		streamWriteBool(streamId, self.rocksKeys[v60_] ~= nil)
	end
end

-- Local values: spotIndex, data, spot, numRocksAll, i, groupId, index, isPartOfMission, groupRoot, destructible
function DestructibleRockMission:readStream(streamId, connection)
	DestructibleRockMission:superClass().readStream(self, streamId, connection)
	local v66_ = streamReadUInt8(streamId)
	self:setSpot(g_missionManager:getMissionTypeDataByName(DestructibleRockMission.NAME).spots[v66_])
	self.numRocksDestroyed = streamReadUInt8(streamId)
	for _ = 1, streamReadUInt8(streamId) do
		local v67_ = streamReadUIntN(streamId, DestructibleMapObjectSystem.GROUP_ID_NUM_BITS)
		local v68_ = streamReadUIntN(streamId, DestructibleMapObjectSystem.CHILD_INDEX_NUM_BITS)
		local v69_ = streamReadBool(streamId)
		local v70_ = g_currentMission.destructibleMapObjectSystem:getGroupRootById(v67_)
		self:addDestructible(getChildAt(v70_, v68_), v69_)
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
	else
		return false
	end
end

-- Local values: marker, data
function DestructibleRockMission:onRockDestroyed(destructible)
	if self.status == MissionStatus.RUNNING then
		if self.rocksAllKeys[destructible] then
			if self.rocksKeys[destructible] then
				local v86_ = self.rockToMarker[destructible]
				if v86_ then
					setVisibility(v86_, false)
				end
				if self.isServer then
					self.numRocksDestroyed = self.numRocksDestroyed + 1
					return
				end
			elseif self.isServer then
				local v87_ = g_missionManager:getMissionTypeDataByName(DestructibleRockMission.NAME)
				self.wronglyDestroyedRocksPenalty = self.wronglyDestroyedRocksPenalty + v87_.penaltyPerRock
				g_currentMission:broadcastEventToFarm(WrongRockDestroyedEvent.new(), self.farmId, true)
			end
		end
	else
		return
	end
end

-- Local values: destructibleMapObjectSystem, destructible, marker
function DestructibleRockMission:rockMarkerRaycastCallback(nodeId, x, y, z)
	if nodeId ~= 0 and nodeId ~= g_terrainNode then
		if self.rockToMarker == nil or self.status ~= MissionStatus.RUNNING then
			return false
		end
		local v93_ = g_currentMission.destructibleMapObjectSystem:getDestructibleFromNode(nodeId)
		if v93_ then
			local v94_ = self.rockToMarker[v93_]
			if v94_ then
				setWorldTranslation(v94_, x, y - 0.15, z)
				setWorldRotation(v94_, 0, 0, 0)
			end
			return false
		end
	end
	return true
end

-- Local values: data, index, rock, marker, x, y, z
function DestructibleRockMission:addRockMarkers()
	if not self.markersAdded then
		if self.markerRootNode == nil then
			self.markerRootNode = createTransformGroup("destructibleRockMissionMarkers")
			link(getRootNode(), self.markerRootNode)
		end
		local v96_ = g_missionManager:getMissionTypeDataByName(DestructibleRockMission.NAME)
		for _, v97_ in pairs(self.rocks) do
			if getEffectiveVisibility(v97_) then
				local v98_ = clone(v96_.markerNode, false, false, false)
				link(self.markerRootNode, v98_)
				self.rockToMarker[v97_] = v98_
				local v99_, v100_, v101_ = getWorldTranslation(v97_)
				raycastAll(v99_, v100_ + 10, v101_, 0, -1, 0, 10, "rockMarkerRaycastCallback", self, DestructibleRockMission.COLLISION_MASK)
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

-- Local values: spot, farmland
function DestructibleRockMission:getWorldPosition()
	local v105_ = self.spot
	if v105_ == nil then
		return g_farmlandManager:getFarmlandById(self.farmlandId):getIndicatorPosition()
	else
		return v105_.x, v105_.z
	end
end

-- Local values: data, mission
function DestructibleRockMission:finish(finishState)
	self:removeHotspot()
	local v108_ = g_missionManager:getMissionTypeDataByName(DestructibleRockMission.NAME)
	if #self.rocksAll - self.numRocksDestroyed < v108_.minNumRocks then
		v108_.spotsDisabled[self.spot] = true
	end
	local v109_ = g_currentMission
	if v109_:getFarmId() == self.farmId then
		if finishState == MissionFinishState.SUCCESS then
			v109_:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_OK, string.format(g_i18n:getText("contract_map_destructibleRock_completed"), self.farmlandId))
		elseif finishState == MissionFinishState.FAILED then
			v109_:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_CRITICAL, string.format(g_i18n:getText("contract_map_destructibleRock_failed"), self.farmlandId))
		elseif finishState == MissionFinishState.TIMED_OUT then
			v109_:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_CRITICAL, string.format(g_i18n:getText("contract_map_destructibleRock_timedOut"), self.farmlandId))
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

-- Local values: res, farmland
function DestructibleRockMission:validate()
	local v113_ = DestructibleRockMission:superClass().validate(self)
	if v113_ then
		local v114_ = g_farmlandManager:getFarmlandById(self.farmlandId)
		if v114_ == nil or v114_.isOwned then
			return false
		else
			return v113_
		end
	else
		return false
	end
end

-- Local values: change
function DestructibleRockMission:dismiss()
	if self.isServer then
		local v116_ = (self.finishState ~= MissionFinishState.SUCCESS and 0 or self:getReward()) - self.wronglyDestroyedRocksPenalty
		if v116_ ~= 0 then
			g_currentMission:addMoney(v116_, self.farmId, MoneyType.MISSIONS, true, true)
		end
	end
end

-- Local values: farmland, npc
function DestructibleRockMission:getNPC()
	local v118_ = g_farmlandManager:getFarmlandById(self.farmlandId)
	return g_npcManager:getNPCByIndex(v118_.npcIndex)
end

-- Local values: remaining
function DestructibleRockMission:getExtraProgressText()
	local v120_ = #self.rocks - self.numRocksDestroyed
	if v120_ == 1 then
		return g_i18n:getText("contract_map_destructibleRock_oneRemainingRock")
	else
		return string.format(g_i18n:getText("contract_map_destructibleRock_remainingRocks"), v120_)
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

-- Local values: details, data
function DestructibleRockMission:getDetails()
	local v125_ = DestructibleRockMission:superClass().getDetails(self)
	local v126_ = g_missionManager:getMissionTypeDataByName(DestructibleRockMission.NAME)
	local v127_ = {
		["title"] = g_i18n:getText("contract_details_farmland"),
		["value"] = self.farmlandId
	}
	table.insert(v125_, v127_)
	local v128_ = {
		["title"] = g_i18n:getText("contract_map_destructibleRock_details_reward"),
		["value"] = g_i18n:formatMoney(v126_.rewardPerRock, 0, true)
	}
	table.insert(v125_, v128_)
	local v129_ = {
		["title"] = g_i18n:getText("contract_map_destructibleRock_details_penalty"),
		["value"] = g_i18n:formatMoney(v126_.penaltyPerRock, 0, true)
	}
	table.insert(v125_, v129_)
	local v130_ = {
		["title"] = g_i18n:getText("contract_map_destructibleRock_details_totalNumRocks"),
		["value"] = #self.rocks
	}
	table.insert(v125_, v130_)
	if self.status ~= MissionStatus.CREATED then
		local v131_ = {
			["title"] = g_i18n:getText("contract_map_destructibleRock_details_destroyedNumRocks"),
			["value"] = self.numRocksDestroyed
		}
		table.insert(v125_, v131_)
	end
	return v125_
end

function DestructibleRockMission:calculateStealingCost()
	return self.wronglyDestroyedRocksPenalty
end

function DestructibleRockMission:getMissionTypeName()
	return DestructibleRockMission.NAME
end

-- Local values: data, spotFilename, i3dNode, root, i, spotNode, x, y, z, radius, farmlandId, isValidFarmland, spot, farmland, markerFilename, markerI3dNode
function DestructibleRockMission.loadMapData(xmlFile, key, baseDirectory)
	if xmlFile:hasProperty(key) then
		local v136_ = g_missionManager:getMissionTypeDataByName(DestructibleRockMission.NAME)
		v136_.spots = {}
		v136_.spotsDisabled = {}
		v136_.activeMissions = {}
		v136_.minNumRocks = xmlFile:getFloat(key .. "#minNumRocks") or 4
		v136_.maxNumRocks = xmlFile:getFloat(key .. "#maxNumRocks") or 10
		v136_.maxNumInstances = xmlFile:getInt(key .. "#maxNumInstances") or 1
		v136_.rewardPerRock = xmlFile:getFloat(key .. "#rewardPerRock") or 550
		v136_.penaltyPerRock = xmlFile:getFloat(key .. "#penaltyPerRock") or 1000
		local v137_ = xmlFile:getString(key .. ".spots#filename")
		if v137_ == nil then
			Logging.xmlWarning(xmlFile, "Missing spot definition file for destructible rock mission (%s)", key)
			return false
		end
		local v138_ = Utils.getFilename(v137_, baseDirectory)
		local v139_ = g_i3DManager:loadI3DFile(v138_, false, false)
		if v139_ == 0 then
			return false
		end
		local v140_ = getChildAt(v139_, 0)
		link(getRootNode(), v140_)
		for v141_ = 0, getNumOfChildren(v140_) - 1 do
			local v142_ = getChildAt(v140_, v141_)
			local v143_, v144_, v145_ = getTranslation(v142_)
			local v146_ = getUserAttribute
			local v147_ = tonumber(v146_(v142_, "radius"))
			if v147_ == nil then
				Logging.xmlWarning(xmlFile, "No radius defined for destructible rock mission spot \'%s\'!", getName(v142_))
			else
				local v148_ = g_farmlandManager:getFarmlandIdAtWorldPosition(v143_, v145_)
				local v149_
				if v148_ == nil then
					v149_ = false
				else
					v149_ = v148_ ~= FarmlandManager.NOT_BUYABLE_FARM_ID
				end
				if v149_ then
					local v150_ = getTerrainHeightAtWorldPos(g_terrainNode, v143_, v144_, v145_)
					local v151_ = {
						["index"] = #v136_.spots + 1,
						["x"] = v143_,
						["y"] = v150_,
						["z"] = v145_,
						["radius"] = v147_,
						["isInUse"] = false,
						["farmlandId"] = v148_
					}
					local v152_ = v136_.spots
					table.insert(v152_, v151_)
				else
					local v153_ = v148_ ~= FarmlandManager.NOT_BUYABLE_FARM_ID and "Not defined" or string.format("Not buyable (%d)", v148_)
					Logging.xmlWarning(xmlFile, "Invalid farmland \'%s\' found for destructible rock mission spot \'%s\' at %d %d!", v153_, getName(v142_), v143_, v145_)
				end
			end
		end
		v136_.spotRoot = v140_
		delete(v139_)
		local v154_ = xmlFile:getString(key .. ".marker#filename")
		if v154_ == nil then
			Logging.xmlWarning(xmlFile, "Missing marker file for destructible rock mission (%s)", key)
			return false
		end
		local v155_ = Utils.getFilename(v154_, baseDirectory)
		local v156_ = g_i3DManager:loadI3DFile(v155_, false, false)
		if v156_ == 0 then
			return false
		end
		v136_.markerNode = getChildAt(v156_, 0)
		unlink(v136_.markerNode)
		delete(v156_)
		return true
	end
end
function DestructibleRockMission.unloadMapData()
	local v157_ = g_missionManager:getMissionTypeDataByName(DestructibleRockMission.NAME)
	if v157_.spotRoot ~= nil then
		delete(v157_.spotRoot)
	end
	if v157_.markerNode ~= nil then
		delete(v157_.markerNode)
	end
end

-- Local values: data
function DestructibleRockMission.loadMetaDataFromXMLFile(xmlFile, key)
	g_missionManager:getMissionTypeDataByName(DestructibleRockMission.NAME).nextMissionDay = xmlFile:getValue(key .. "#nextDay")
end

-- Local values: data
function DestructibleRockMission.saveMetaDataToXMLFile(xmlFile, key)
	local v162_ = g_missionManager:getMissionTypeDataByName(DestructibleRockMission.NAME)
	if v162_.nextMissionDay ~= nil then
		xmlFile:setValue(key .. "#nextDay", v162_.nextMissionDay)
	end
end
function DestructibleRockMission.onFinishCallback()
	g_missionManager:getMissionTypeDataByName(DestructibleRockMission.NAME).rockCheck.isRunning = false
end

-- Local values: destructibleMapObjectSystem, destructible, x, _, z, farmlandId, data, rockCheck
function DestructibleRockMission.onRockCallback(_, transformId, subShapeIndex, isLast)
	if transformId ~= 0 and getHasClassId(transformId, ClassIds.SHAPE) then
		local v165_ = g_currentMission.destructibleMapObjectSystem:getDestructibleFromNode(transformId)
		if v165_ ~= nil then
			local v166_, _, v167_ = getWorldTranslation(transformId)
			local v168_ = g_farmlandManager:getFarmlandIdAtWorldPosition(v166_, v167_)
			local v169_ = g_missionManager:getMissionTypeDataByName(DestructibleRockMission.NAME).rockCheck
			if v168_ == v169_.farmlandId then
				local v170_ = v169_.rocks
				table.insert(v170_, v165_)
			end
		end
	end
	if isLast then
		DestructibleRockMission.onFinishCallback()
	end
	return true
end
function DestructibleRockMission.tryGenerateMission()
	if not DestructibleRockMission.canRun() then
		return nil
	end
	local v171_ = g_missionManager:getMissionTypeDataByName(DestructibleRockMission.NAME)
	local v172_ = v171_.rockCheck
	if v172_ ~= nil then
		if v172_.isRunning then
			return nil
		end
		if #v172_.rocks < v171_.minNumRocks then
			v171_.spotsDisabled[v172_.spot] = true
			v171_.rockCheck = nil
			return nil
		end
		local v173_ = DestructibleRockMission.new(true, g_client ~= nil)
		if v173_:init(v172_.spot, v172_.rocks) then
			local v174_ = g_currentMission.environment
			v173_:setEndDate(v174_.currentMonotonicDay + 2, MathUtil.hoursToMs(math.random(10, 18)))
			v171_.nextMissionDay = v174_.currentMonotonicDay + math.random(4, 9)
		else
			v173_:delete()
			v173_ = nil
		end
		v171_.rockCheck = nil
		return v173_
	end
	local v175_ = v171_.spots
	Utils.shuffle(v175_)
	local v176_ = {}
	for _, v177_ in ipairs(v171_.activeMissions) do
		v176_[v177_.spot.farmlandId] = true
	end
	local v178_ = nil
	for _, v179_ in ipairs(v175_) do
		if v171_.spotsDisabled[v179_] == nil and (not v179_.isInUse and (v176_[v179_.farmlandId] == nil and g_farmlandManager:getFarmlandOwner(v179_.farmlandId) == FarmlandManager.NO_OWNER_FARM_ID)) then
			v178_ = v179_
			break
		end
	end
	if v178_ == nil then
		return nil
	end
	local v180_ = {
		["spot"] = v178_,
		["isRunning"] = true,
		["rocks"] = {},
		["farmlandId"] = v178_.farmlandId
	}
	local v181_ = v178_.x
	local v182_ = v178_.y
	local v183_ = v178_.z
	local v184_ = v178_.radius
	local v185_ = DestructibleRockMission.COLLISION_MASK
	local v186_ = v178_.height or 20
	overlapCylinderAsync(v181_, v182_, v183_, v184_, v186_, Axis.Y, "onRockCallback", DestructibleRockMission, v185_)
	v171_.rockCheck = v180_
	return nil
end
function DestructibleRockMission.canRun()
	local v187_ = g_missionManager:getMissionTypeDataByName(DestructibleRockMission.NAME)
	if v187_.spots == nil then
		return false
	elseif #v187_.spots == 0 then
		return false
	elseif v187_.numInstances >= v187_.maxNumInstances then
		return false
	else
		return v187_.nextMissionDay == nil or g_currentMission.environment.currentMonotonicDay >= v187_.nextMissionDay
	end
end
g_missionManager:registerMissionType(DestructibleRockMission, DestructibleRockMission.NAME, 2)
