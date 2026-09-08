-- Local values: GameStats_mt
GameStats = {}
GameStats.STEP_IDLE = 1
GameStats.STEP_UPDATE_FARMLANDS = 2
GameStats.STEP_UPDATE_FIELDS = 3
GameStats.STEP_UPDATE_PLAYERS = 4
GameStats.STEP_UPDATE_VEHICLES_INIT = 5
GameStats.STEP_UPDATE_VEHICLES = 6
GameStats.STEP_UPDATE_FINISHED = 7
local GameStats_mt = Class(GameStats)

-- Upvalues: GameStats_mt
-- Local values: self
function GameStats.new(filename, updateIntervalMs, customMt)
	-- upvalues: (copy) GameStats_mt
	local v5_ = customMt or GameStats_mt
	local v6_ = setmetatable({}, v5_)
	v6_.statsXMLFile = nil
	v6_.filename = filename
	v6_.updateIntervalMs = updateIntervalMs
	v6_.updateTime = 0
	v6_.maxVehiclesPerFrame = 3
	v6_.pendingVehicles = {}
	v6_.currentStep = GameStats.STEP_IDLE
	return v6_
end

-- Local values: xmlFile, mapSize, mapName, map, i, _, mod, modKey, k, farmland, farmlandKey, k, field, fieldKey
function GameStats:init(mission)
	local v9_ = createXMLFile("serverStatsFile", self.filename, "Server")
	if v9_ == 0 then
		Logging.error("Failed to create serverStats xml file")
	else
		self.mission = mission
		self.statsXMLFile = v9_
		local v10_ = mission.terrainSize or 2048
		local v11_ = g_mapManager:getMapById(mission.missionInfo.mapId)
		local v12_ = v11_ == nil and "Unknown" or v11_.title
		setXMLString(v9_, "Server#game", g_gameTitle)
		setXMLString(v9_, "Server#version", g_gameVersionDisplay .. g_gameVersionDisplayExtra)
		setXMLString(v9_, "Server#mapOverviewFilename", NetworkUtil.convertToNetworkFilename(mission.mapImageFilename))
		setXMLInt(v9_, "Server#mapSize", v10_)
		setXMLString(v9_, "Server#mapName", HTMLUtil.encodeToHTML(v12_))
		setXMLInt(v9_, "Server.Slots#capacity", 1)
		setXMLInt(v9_, "Server.Slots#numUsed", 0)
		local v13_ = 0
		for _, v14_ in pairs(mission.missionDynamicInfo.mods) do
			local v15_ = string.format("Server.Mods.Mod(%d)", v13_)
			setXMLString(v9_, v15_ .. "#name", HTMLUtil.encodeToHTML(v14_.modName))
			setXMLString(v9_, v15_ .. "#author", HTMLUtil.encodeToHTML(v14_.author))
			setXMLString(v9_, v15_ .. "#version", HTMLUtil.encodeToHTML(v14_.version))
			setXMLString(v9_, v15_, HTMLUtil.encodeToHTML(v14_.title, true))
			if v14_.fileHash ~= nil then
				setXMLString(v9_, v15_ .. "#hash", HTMLUtil.encodeToHTML(v14_.fileHash))
			end
			v13_ = v13_ + 1
		end
		for v16_, v17_ in ipairs(g_farmlandManager.sortedFarmlands) do
			local v18_ = string.format("Server.Farmlands.Farmland(%d)", v16_ - 1)
			local v19_ = setXMLString
			local v20_ = v18_ .. "#name"
			local v21_ = v17_.name
			v19_(v9_, v20_, (tostring(v21_)))
			setXMLInt(v9_, v18_ .. "#id", v17_.id)
			setXMLInt(v9_, v18_ .. "#owner", g_farmlandManager:getFarmlandOwner(v17_.id))
			setXMLFloat(v9_, v18_ .. "#area", v17_.areaInHa)
			local v22_ = setXMLInt
			local v23_ = v18_ .. "#price"
			local v24_ = v17_.price
			v22_(v9_, v23_, (math.round(v24_)))
			setXMLFloat(v9_, v18_ .. "#x", v17_.xWorldPos)
			setXMLFloat(v9_, v18_ .. "#z", v17_.zWorldPos)
		end
		for v25_, v26_ in ipairs(g_fieldManager:getFields()) do
			local v27_ = string.format("Server.Fields.Field(%d)", v25_ - 1)
			setXMLString(v9_, v27_ .. "#id", (tostring(v26_:getId())))
			setXMLFloat(v9_, v27_ .. "#x", v26_.posX)
			setXMLFloat(v9_, v27_ .. "#z", v26_.posZ)
			setXMLBool(v9_, v27_ .. "#isOwned", v26_:getHasOwner())
		end
		saveXMLFile(v9_)
		g_messageCenter:subscribe(MessageType.USER_ADDED, self.onUserAdded, self)
		g_messageCenter:subscribe(MessageType.USER_REMOVED, self.onUserRemoved, self)
		if mission:getIsServer() and g_addTestCommands then
			addConsoleCommand("gsGameStatsUpdate", "Updates the game stats xml file", "consoleCommandUpdateGameStats", self)
		end
	end
end

function GameStats:delete()
	if self.statsXMLFile ~= nil then
		delete(self.statsXMLFile)
		self.statsXMLFile = nil
	end
	self.mission = nil
	g_messageCenter:unsubscribeAll(self)
	removeConsoleCommand("gsGameStatsUpdate")
end

function GameStats:update(dt)
	if self.updateTime > 0 then
		self.updateTime = self.updateTime - dt
	else
		self:processStep()
	end
end

function GameStats:processStep()
	if self.statsXMLFile == nil then
		return
	elseif self.currentStep == GameStats.STEP_IDLE then
		self.currentStep = GameStats.STEP_UPDATE_FARMLANDS
		self:updateStatsInfo()
		return
	elseif self.currentStep == GameStats.STEP_UPDATE_FARMLANDS then
		self.currentStep = GameStats.STEP_UPDATE_FIELDS
		self:updateStatsFarmlands()
		return
	elseif self.currentStep == GameStats.STEP_UPDATE_FIELDS then
		self.currentStep = GameStats.STEP_UPDATE_PLAYERS
		self:updateStatsFields()
		return
	elseif self.currentStep == GameStats.STEP_UPDATE_PLAYERS then
		self.currentStep = GameStats.STEP_UPDATE_VEHICLES_INIT
		self:updateStatsPlayers()
		return
	elseif self.currentStep == GameStats.STEP_UPDATE_VEHICLES_INIT then
		self.currentStep = GameStats.STEP_UPDATE_VEHICLES
		self:updateStatsVehiclesInit()
		return
	elseif self.currentStep == GameStats.STEP_UPDATE_VEHICLES then
		if #self.pendingVehicles == 0 then
			self.currentStep = GameStats.STEP_UPDATE_FINISHED
		else
			self:updateStatsVehicleStep()
		end
	else
		if self.currentStep == GameStats.STEP_UPDATE_FINISHED then
			self.currentStep = GameStats.STEP_IDLE
			self:updateStatsFinished()
		end
		return
	end
end

-- Local values: xmlFile, gameName, dayTime
function GameStats:updateStatsInfo()
	local v33_ = self.statsXMLFile
	if v33_ == nil then
		return
	elseif self.mission ~= nil then
		local v34_ = self.mission.missionDynamicInfo.serverName or ""
		local v35_ = self.mission.environment == nil and 0 or self.mission.environment.dayTime
		setXMLString(v33_, "Server#name", HTMLUtil.encodeToHTML(v34_))
		setXMLInt(v33_, "Server#dayTime", v35_)
	end
end

-- Local values: xmlFile, k, farmland, farmlandKey
function GameStats:updateStatsFarmlands()
	local v37_ = self.statsXMLFile
	if v37_ ~= nil then
		for v38_, v39_ in ipairs(g_farmlandManager.sortedFarmlands) do
			local v40_ = string.format("Server.Farmlands.Farmland(%d)", v38_ - 1)
			setXMLInt(v37_, v40_ .. "#owner", g_farmlandManager:getFarmlandOwner(v39_.id))
		end
	end
end

-- Local values: xmlFile, k, field, fieldKey
function GameStats:updateStatsFields()
	local v42_ = self.statsXMLFile
	if v42_ ~= nil then
		for v43_, v44_ in ipairs(g_fieldManager:getFields()) do
			local v45_ = string.format("Server.Fields.Field(%d)", v43_ - 1)
			setXMLBool(v42_, v45_ .. "#isOwned", v44_:getHasOwner())
		end
	end
end

-- Local values: xmlFile, userManager, numUsers, capacity, i, playerKey, user, player, connection, uptimeMinutes, x, y, z
function GameStats:updateStatsPlayers()
	local v47_ = self.statsXMLFile
	if v47_ == nil then
		return
	elseif self.mission ~= nil then
		local v48_ = self.mission.userManager
		local v49_ = v48_:getNumberOfUsers()
		if g_dedicatedServer ~= nil then
			v49_ = v49_ - 1
		end
		local v50_ = self.mission.missionDynamicInfo.capacity or 0
		setXMLInt(v47_, "Server.Slots#capacity", v50_)
		setXMLInt(v47_, "Server.Slots#numUsed", v49_)
		for v51_ = 1, g_serverMaxCapacity do
			local v52_ = string.format("Server.Slots.Player(%d)", v51_ - 1)
			removeXMLProperty(v47_, v52_)
			if v51_ <= v50_ then
				local v53_ = v48_:getUsers()[v51_ + 1]
				if v53_ == nil then
					setXMLBool(v47_, v52_ .. "#isUsed", false)
				else
					local v54_ = v53_:getConnection()
					local v55_
					if v54_ == nil then
						v55_ = nil
					else
						v55_ = self.mission.connectionsToPlayer[v54_]
					end
					local v56_ = (self.mission.time - v53_:getConnectedTime()) / 60000
					local v57_ = math.round(v56_)
					setXMLBool(v47_, v52_ .. "#isUsed", true)
					setXMLBool(v47_, v52_ .. "#isAdmin", v53_:getIsMasterUser())
					setXMLInt(v47_, v52_ .. "#uptime", v57_)
					if v55_ ~= nil and (v55_.isControlled and (v55_.rootNode ~= nil and v55_.rootNode ~= 0)) then
						local v58_, v59_, v60_ = getWorldTranslation(v55_.rootNode)
						setXMLFloat(v47_, v52_ .. "#x", v58_)
						setXMLFloat(v47_, v52_ .. "#y", v59_)
						setXMLFloat(v47_, v52_ .. "#z", v60_)
					end
					setXMLString(v47_, v52_, HTMLUtil.encodeToHTML(v53_:getNickname(), true))
				end
			end
		end
	end
end

-- Local values: xmlFile, vehicleSystem, _, vehicle, vehicleId
function GameStats:updateStatsVehiclesInit()
	table.clear(self.pendingVehicles)
	local v62_ = self.statsXMLFile
	if v62_ ~= nil then
		local v63_ = g_currentMission.vehicleSystem
		removeXMLProperty(v62_, "Server.Vehicles")
		for _, v64_ in ipairs(v63_.vehicles) do
			local v65_ = NetworkUtil.getObjectId(v64_)
			local v66_ = self.pendingVehicles
			table.insert(v66_, v65_)
		end
	end
end

-- Local values: xmlFile, i, vehicleId, vehicle, numElements, vehicleKey
function GameStats:updateStatsVehicleStep()
	local v68_ = self.statsXMLFile
	if v68_ == nil then
		return
	end
	local v69_ = 0
	while self.maxVehiclesPerFrame >= v69_ do
		local v70_ = table.remove(self.pendingVehicles, 1)
		if v70_ == nil then
			break
		end
		local v71_ = NetworkUtil.getObject(v70_)
		if v71_ ~= nil then
			local v72_ = getXMLNumOfElements(v68_, "Server.Vehicles.Vehicle")
			v71_:saveStatsToXMLFile(v68_, (string.format("Server.Vehicles.Vehicle(%d)", v72_)))
		end
		v69_ = v69_ + 1
	end
end

-- Local values: xmlFile
function GameStats:updateStatsFinished()
	self.updateTime = self.updateIntervalMs
	local v74_ = self.statsXMLFile
	if v74_ ~= nil then
		saveXMLFile(v74_)
	end
end

function GameStats:setDirty()
	if self.currentStep ~= GameStats.STEP_IDLE then
		return false
	end
	self.updateTime = 0
	return true
end

function GameStats:onUserAdded(user)
	self:setDirty()
end

function GameStats:onUserRemoved(user)
	self:setDirty()
end

function GameStats:consoleCommandUpdateGameStats()
	return self:setDirty() and "Triggered game stats update" or "Could not start game stats update. Update is currently in progress..."
end
