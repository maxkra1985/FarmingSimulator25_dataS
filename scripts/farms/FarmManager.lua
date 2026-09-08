-- Local values: FarmManager_mt
FarmManager = {}
FarmManager.FARM_ID_SEND_NUM_BITS = 4
FarmManager.MAX_NUM_FARMS = 8
FarmManager.MAX_FARM_ID = FarmManager.MAX_NUM_FARMS
FarmManager.SPECTATOR_FARM_ID = 0
FarmManager.SINGLEPLAYER_FARM_ID = 1
FarmManager.GUIDED_TOUR_FARM_ID = FarmManager.FARM_ID_SEND_NUM_BITS ^ 2 - 2
FarmManager.INVALID_FARM_ID = FarmManager.FARM_ID_SEND_NUM_BITS ^ 2 - 1
local FarmManager_mt = Class(FarmManager, AbstractManager)

-- Upvalues: FarmManager_mt
-- Local values: self
function FarmManager.new(customMt)
	-- upvalues: (copy) FarmManager_mt
	return AbstractManager.new(customMt or FarmManager_mt)
end

function FarmManager:initDataStructures()
	self.farms = {}
	self.farmIdToFarm = {}
	self.defaultHandtools = {}
	self.mergedFarms = nil
end

-- Local values: spectatorFarm, guidedTourFarm, xmlFileObj
function FarmManager:loadMapData(xmlFile)
	FarmManager:superClass().loadMapData(self)
	if g_currentMission:getIsServer() then
		g_currentMission:addUpdateable(self)
		local v6_ = Farm.new(true, g_client ~= nil, true)
		v6_.farmId = FarmManager.SPECTATOR_FARM_ID
		v6_.isSpectator = true
		v6_.showInFarmScreen = false
		v6_.stats.updatePlayTime = false
		v6_:register()
		local v7_ = self.farms
		table.insert(v7_, v6_)
		self.farmIdToFarm[v6_.farmId] = v6_
		local v8_ = Farm.new(true, g_client ~= nil, true)
		v8_.farmId = FarmManager.GUIDED_TOUR_FARM_ID
		v8_.isSpectator = false
		v8_.showInFarmScreen = false
		v8_.stats.updatePlayTime = false
		v8_:register()
		local v9_ = self.farms
		table.insert(v9_, v8_)
		self.farmIdToFarm[v8_.farmId] = v8_
	end
	local v_u_10_ = XMLFile.wrap(xmlFile)
	v_u_10_:iterate("map.farms.defaultHandTools.handTool", function(_, p11_)
		-- upvalues: (copy) self, (copy) v_u_10_
		local v12_ = self.defaultHandtools
		local v13_ = v_u_10_
		local v14_ = p11_ .. "#filename"
		table.insert(v12_, v13_:getString(v14_))
	end)
	v_u_10_:delete()
	addConsoleCommand("gsFarmSet", "Set farm for current player or vehicle", "consoleCommandSetFarm", self)
end

function FarmManager:unloadMapData()
	g_currentMission:removeUpdateable(self)
	removeConsoleCommand("gsFarmSet")
	if g_addTestCommands then
		removeConsoleCommand("debugCreateFarm")
	end
	FarmManager:superClass().unloadMapData(self)
end

-- Local values: xmlFile
function FarmManager:saveToXMLFile(xmlFilename)
	local v_u_18_ = XMLFile.create("farmsXML", xmlFilename, "farms")
	v_u_18_:setTable("farms.farm", self.farms, function(p19_, p20_)
		-- upvalues: (copy) v_u_18_
		if p20_.farmId == FarmManager.SPECTATOR_FARM_ID or p20_.farmId == FarmManager.GUIDED_TOUR_FARM_ID then
			return 0
		end
		p20_:saveToXMLFile(v_u_18_, p19_)
	end)
	v_u_18_:save()
	v_u_18_:delete()
end

-- Local values: xmlFile, _, key, farm, uniqueUserId
function FarmManager:loadFromXMLFile(xmlFilename)
	if xmlFilename == nil then
		self:loadDefaults()
		return false
	end
	local v23_ = XMLFile.load("TempXML", xmlFilename)
	if v23_ == nil then
		return false
	end
	for _, v24_ in v23_:iterator("farms.farm") do
		local v25_ = Farm.new(true, g_client ~= nil)
		if v25_:loadFromXMLFile(v23_, v24_) then
			v25_:register()
			local v26_ = self.farms
			table.insert(v26_, v25_)
			self.farmIdToFarm[v25_.farmId] = v25_
		else
			v25_:delete()
		end
	end
	self:mergeFarmsForSingleplayer()
	if g_currentMission:getIsClient() then
		self:playerJoinedGame(getUniqueUserId(), g_currentMission:getServerUserId())
	end
	v23_:delete()
	return true
end

-- Local values: farm
function FarmManager:loadDefaults()
	if not g_currentMission.missionDynamicInfo.isMultiplayer then
		self:createFarm(g_i18n:getText("ui_defaultFarmName"), 1, nil, FarmManager.SINGLEPLAYER_FARM_ID):addUser(g_currentMission:getServerUserId(), getUniqueUserId(), true)
	end
	self:playerJoinedGame(getUniqueUserId(), g_currentMission:getServerUserId())
end

-- Local values: specFarm, tourFarm, spFarm, _, farm, farmId
function FarmManager:mergeFarmsForSingleplayer()
	if not g_currentMission.missionDynamicInfo.isMultiplayer then
		local v29_ = self.farmIdToFarm[FarmManager.SPECTATOR_FARM_ID]
		local v30_ = self.farmIdToFarm[FarmManager.GUIDED_TOUR_FARM_ID]
		local v31_ = self.farmIdToFarm[FarmManager.SINGLEPLAYER_FARM_ID]
		if v31_ == nil then
			v31_ = self:createFarm(g_i18n:getText("ui_defaultFarmName"), 1, nil, FarmManager.SINGLEPLAYER_FARM_ID)
			v31_:addUser(g_currentMission:getServerUserId(), getUniqueUserId(), true)
		end
		for _, v32_ in ipairs(self.farms) do
			local v33_ = v32_.farmId
			if v33_ ~= FarmManager.SPECTATOR_FARM_ID and (v33_ ~= FarmManager.GUIDED_TOUR_FARM_ID and v33_ ~= FarmManager.SINGLEPLAYER_FARM_ID) then
				if self.mergedFarms == nil then
					self.mergedFarms = {}
				end
				self.mergedFarms[v33_] = FarmManager.SINGLEPLAYER_FARM_ID
				v31_:merge(v32_)
			end
		end
		v31_.farmId = FarmManager.SINGLEPLAYER_FARM_ID
		self.farmIdToFarm = {}
		self.farmIdToFarm[FarmManager.SPECTATOR_FARM_ID] = v29_
		self.farmIdToFarm[FarmManager.GUIDED_TOUR_FARM_ID] = v30_
		self.farmIdToFarm[FarmManager.SINGLEPLAYER_FARM_ID] = v31_
		self.farms = { v29_, v31_, v30_ }
		self.farmIdToFarm[FarmManager.SINGLEPLAYER_FARM_ID]:resetToSingleplayer()
	end
end

-- Local values: _, farmland, ownerFarmId, newFarmId
function FarmManager:mergeFarmlandsForSingleplayer()
	if not g_currentMission.missionDynamicInfo.isMultiplayer and self.mergedFarms ~= nil then
		for _, v35_ in pairs(g_farmlandManager:getFarmlands()) do
			local v36_ = g_farmlandManager:getFarmlandOwner(v35_.id)
			local v37_ = self.mergedFarms[v36_]
			if v37_ ~= nil then
				g_farmlandManager:setLandOwnership(v35_.id, v37_, true)
			end
		end
	end
end

-- Local values: _, vehicle, ownerFarmId, newFarmId, _, placeable, ownerFarmId, newFarmId, _, handTool, ownerFarmId, newFarmId, _, saveItem, item, ownerFarmId, newFarmId
function FarmManager:mergeObjectsForSingleplayer()
	if not g_currentMission.missionDynamicInfo.isMultiplayer and self.mergedFarms ~= nil then
		for _, v39_ in pairs(g_currentMission.vehicleSystem.vehicles) do
			local v40_ = v39_:getOwnerFarmId()
			local v41_ = self.mergedFarms[v40_]
			if v41_ ~= nil then
				v39_:setOwnerFarmId(v41_)
			end
		end
		for _, v42_ in pairs(g_currentMission.placeableSystem.placeables) do
			local v43_ = v42_:getOwnerFarmId()
			local v44_ = self.mergedFarms[v43_]
			if v44_ ~= nil then
				v42_:setOwnerFarmId(v44_)
			end
		end
		for _, v45_ in pairs(g_currentMission.handToolSystem.handTools) do
			local v46_ = v45_:getOwnerFarmId()
			local v47_ = self.mergedFarms[v46_]
			if v47_ ~= nil then
				v45_:setOwnerFarmId(v47_)
			end
		end
		for _, v48_ in pairs(g_currentMission.itemSystem.itemsToSave) do
			local v49_ = v48_.item
			if v49_ ~= nil and v49_.getOwnerFarmId ~= nil then
				local v50_ = v49_:getOwnerFarmId()
				local v51_ = self.mergedFarms[v50_]
				if v51_ ~= nil then
					v49_:setOwnerFarmId(v51_)
				end
			end
		end
	end
end

function FarmManager:delete() end

function FarmManager:update(dt)
	if g_currentMission:getIsClient() and (self.mergedFarms ~= nil and not self.mergedMessageShown) then
		InfoDialog.show(g_i18n:getText("ui_farmedMergedSP"), nil, nil, DialogElement.TYPE_INFO)
		self.mergedMessageShown = true
	end
end

-- Local values: _, farm, player
function FarmManager:getFarmForUniqueUserId(uniqueUserId)
	if not g_currentMission.missionDynamicInfo.isMultiplayer then
		return self.farmIdToFarm[FarmManager.SINGLEPLAYER_FARM_ID]
	end
	for _, v55_ in ipairs(self.farms) do
		local v56_ = v55_.uniqueUserIdToPlayer[uniqueUserId]
		if not v55_.isSpectator and v56_ ~= nil then
			return v55_
		end
	end
	return self.farmIdToFarm[FarmManager.SPECTATOR_FARM_ID]
end

-- Local values: _, farm, player
function FarmManager:getFarmByUserId(userId)
	if not g_currentMission.missionDynamicInfo.isMultiplayer then
		return self.farmIdToFarm[FarmManager.SINGLEPLAYER_FARM_ID]
	end
	for _, v59_ in ipairs(self.farms) do
		if v59_.userIdToPlayer[userId] ~= nil then
			return v59_
		end
	end
	return self.farmIdToFarm[0]
end

function FarmManager:getFarmById(farmId)
	return self.farmIdToFarm[farmId]
end

-- Local values: farm
function FarmManager:getSpawnPoint(farmId)
	local v64_ = self:getFarmById(farmId)
	if v64_ == nil then
		return nil
	else
		return v64_:getSpawnPoint()
	end
end

-- Local values: farm
function FarmManager:getSleepCamera(farmId)
	local v67_ = self:getFarmById(farmId)
	if v67_ == nil then
		return nil
	else
		return v67_:getSleepCamera()
	end
end

-- Local values: _, farm
function FarmManager:updateFarms(farms, playerFarmId)
	self.farms = farms
	self.farmIdToFarm = {}
	for _, v70_ in ipairs(self.farms) do
		self.farmIdToFarm[v70_.farmId] = v70_
	end
end

function FarmManager:appendFarm(farm)
	if self.farmIdToFarm[farm.farmId] == nil then
		self.farmIdToFarm[farm.farmId] = farm
		local v73_ = self.farms
		table.insert(v73_, farm)
	end
end

function FarmManager:getFarms()
	return self.farms
end

function FarmManager:onFarmObjectCreated(object)
	if not g_currentMission:getIsServer() then
		self:appendFarm(object)
		g_messageCenter:publish(MessageType.FARM_CREATED, object.farmId)
	end
end

function FarmManager:onFarmObjectDeleted(object)
	self:removeFarm(object.farmId)
	g_messageCenter:publishDelayed(MessageType.FARM_DELETED, object.farmId)
end

-- Local values: farm
function FarmManager:updateFarmStats(farmId, stat, delta)
	local v83_ = self.farmIdToFarm[farmId]
	if v83_ == nil then
		return nil, nil
	else
		return v83_.stats:updateStats(stat, delta)
	end
end

-- Local values: farm
function FarmManager:getFarmStatValue(farmId, stat)
	local v87_ = self.farmIdToFarm[farmId]
	if v87_ == nil then
		return 0, 0
	else
		return v87_.stats:getSessionValue(stat), v87_.stats:getTotalValue(stat)
	end
end

-- Local values: farm, didJoinFarm, player
function FarmManager:playerJoinedGame(uniqueUserId, userId, user, connection)
	if g_currentMission:getIsServer() then
		local v93_ = self:getFarmForUniqueUserId(uniqueUserId)
		local v94_ = v93_:onUserJoinGame(uniqueUserId, userId, user)
		g_server:broadcastEvent(PlayerSwitchedFarmEvent.new(FarmManager.INVALID_FARM_ID, v93_.farmId, userId), nil, connection)
		if v94_ then
			local v95_ = v93_.userIdToPlayer[userId]
			if v95_ ~= nil then
				g_server:broadcastEvent(PlayerPermissionsEvent.new(userId, v95_.permissions, v95_.isFarmManager), nil, connection)
				return
			end
		end
	else
		printError("Error: FarmManager:playerJoinedGame() only allowed on server")
	end
end

-- Local values: farm
function FarmManager:playerQuitGame(userId)
	if g_currentMission:getIsServer() then
		local v98_ = self:getFarmByUserId(userId)
		v98_:onUserQuitGame(userId)
		g_server:broadcastEvent(PlayerSwitchedFarmEvent.new(v98_.farmId, FarmManager.INVALID_FARM_ID, userId))
	else
		printError("Error: FarmManager:playerQuitGame() only allowed on server")
	end
end

function FarmManager:transferMoney(destinationFarm, amount)
	g_client:getServerConnection():sendEvent(TransferMoneyEvent.new(amount, destinationFarm.farmId))
end

function FarmManager:removeUserFromFarm(userId)
	g_client:getServerConnection():sendEvent(RemovePlayerFromFarmEvent.new(userId))
end

-- Local values: farm
function FarmManager:createFarm(name, color, password, farmId)
	if not g_currentMission:getIsServer() then
		printError("Error: FarmManager:createFarm() only allowed on server")
		return nil
	end
	if farmId ~= FarmManager.SINGLEPLAYER_FARM_ID and (not g_currentMission.missionDynamicInfo.isMultiplayer and #self.farms > 2) then
		return nil
	end
	local v107_ = Farm.new(true, g_client ~= nil)
	if farmId ~= FarmManager.SINGLEPLAYER_FARM_ID and #self.farms == FarmManager.MAX_NUM_FARMS + 2 then
		return nil, "Farm limit reached"
	end
	if self.farmIdToFarm[farmId] ~= nil then
		farmId = nil
	end
	if farmId == nil then
		farmId = self:findNextFarmId()
	end
	v107_.farmId = farmId
	v107_.name = name
	v107_.color = color
	if password ~= "" then
		v107_.password = password
	end
	v107_:register()
	local v108_ = self.farms
	table.insert(v108_, v107_)
	self.farmIdToFarm[v107_.farmId] = v107_
	g_messageCenter:publish(MessageType.FARM_CREATED, v107_.farmId)
	return v107_
end

-- Local values: farm, i, vehicle, i, placeable, _, item
function FarmManager:destroyFarm(farmId)
	if g_currentMission.missionDynamicInfo.isMultiplayer then
		local v111_ = self.farmIdToFarm[farmId]
		if v111_ ~= nil then
			v111_:delete()
			self:removeFarm(farmId)
			for v112_ = #g_currentMission.vehicleSystem.vehicles, 1, -1 do
				local v113_ = g_currentMission.vehicleSystem.vehicles[v112_]
				if v113_:getOwnerFarmId() == farmId then
					v113_:delete()
				end
			end
			for v114_ = #g_currentMission.placeableSystem.placeables, 1, -1 do
				local v115_ = g_currentMission.placeableSystem.placeables[v114_]
				if v115_:getOwnerFarmId() == farmId then
					if v115_:getSellAction() == Placeable.SELL_AND_SPECTATOR_FARM then
						v115_:setOwnerFarmId(FarmManager.SPECTATOR_FARM_ID)
					else
						v115_:delete()
					end
				end
			end
			for _, v116_ in pairs(g_currentMission.itemSystem.itemsToSave) do
				if v116_.getOwnerFarmId ~= nil and v116_:getOwnerFarmId() == farmId then
					v116_:delete()
				end
			end
			g_messageCenter:publish(MessageType.FARM_DELETED, farmId)
		end
	end
end

-- Local values: i, farm
function FarmManager:removeFarm(farmId)
	self.farmIdToFarm[farmId] = nil
	for v119_, v120_ in ipairs(self.farms) do
		if v120_.farmId == farmId then
			table.remove(self.farms, v119_)
			return
		end
	end
end

-- Local values: i, inUse, _, farm
function FarmManager:findNextFarmId()
	for v122_ = 1, FarmManager.MAX_FARM_ID do
		local v123_ = false
		for _, v124_ in ipairs(self.farms) do
			if v122_ == v124_.farmId then
				v123_ = true
				break
			end
		end
		if not v123_ then
			return v122_
		end
	end
	return nil
end

-- Local values: playerVehicle, farm
function FarmManager:consoleCommandSetFarm(farmId)
	local v127_ = g_localPlayer:getCurrentVehicle()
	if farmId == nil then
		if v127_ == nil then
			return string.format("No farmId specified. Current player farmId is %d", g_localPlayer:getFarmId())
		else
			return string.format("No farmId specified. Current vehicle farmId is %s", v127_:getOwnerFarmId())
		end
	else
		local v128_ = tonumber(farmId)
		if v127_ == nil then
			g_client:getServerConnection():sendEvent(PlayerSetFarmEvent.new(g_localPlayer, v128_))
			return string.format("Updated farm id for player to \'%d\'", v128_)
		end
		if not g_currentMission:getIsServer() then
			return "This command currently only works on server"
		end
		if self:getFarmById(v128_) == nil then
			return string.format("Farm with id %d does not exist.", v128_)
		end
		v127_:setOwnerFarmId(v128_)
		return string.format("Updated farm id for vehicle \'%s\' to \'%d\'", v127_.configFileName, v128_)
	end
end
g_farmManager = FarmManager.new()
