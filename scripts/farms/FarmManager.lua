FarmManager = {}
FarmManager.FARM_ID_SEND_NUM_BITS = 4
FarmManager.MAX_NUM_FARMS = 8
FarmManager.MAX_FARM_ID = FarmManager.MAX_NUM_FARMS
FarmManager.SPECTATOR_FARM_ID = 0
FarmManager.SINGLEPLAYER_FARM_ID = 1
FarmManager.GUIDED_TOUR_FARM_ID = FarmManager.FARM_ID_SEND_NUM_BITS ^ 2 - 2
FarmManager.INVALID_FARM_ID = FarmManager.FARM_ID_SEND_NUM_BITS ^ 2 - 1
local FarmManager_mt = Class(FarmManager, AbstractManager)
function FarmManager.new(customMt)
	local self = AbstractManager.new(customMt or FarmManager_mt)
	return self
end
function FarmManager:initDataStructures()
	self.farms = {}
	self.farmIdToFarm = {}
	self.defaultHandtools = {}
	self.mergedFarms = nil
end
function FarmManager:loadMapData(xmlFile)
	FarmManager:superClass().loadMapData(self)
	if g_currentMission:getIsServer() then
		g_currentMission:addUpdateable(self)
		local spectatorFarm = Farm.new(true, g_client ~= nil, true)
		spectatorFarm.farmId = FarmManager.SPECTATOR_FARM_ID
		spectatorFarm.isSpectator = true
		spectatorFarm.showInFarmScreen = false
		spectatorFarm.stats.updatePlayTime = false
		spectatorFarm:register()
		table.insert(self.farms, spectatorFarm)
		self.farmIdToFarm[spectatorFarm.farmId] = spectatorFarm
		local guidedTourFarm = Farm.new(true, g_client ~= nil, true)
		guidedTourFarm.farmId = FarmManager.GUIDED_TOUR_FARM_ID
		guidedTourFarm.isSpectator = false
		guidedTourFarm.showInFarmScreen = false
		guidedTourFarm.stats.updatePlayTime = false
		guidedTourFarm:register()
		table.insert(self.farms, guidedTourFarm)
		self.farmIdToFarm[guidedTourFarm.farmId] = guidedTourFarm
	end
	local xmlFileObj = XMLFile.wrap(xmlFile)
	xmlFileObj:iterate("map.farms.defaultHandTools.handTool", function(_, key)
		table.insert(self.defaultHandtools, xmlFileObj:getString(key .. "#filename"))
	end)
	xmlFileObj:delete()
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
function FarmManager:saveToXMLFile(xmlFilename)
	local xmlFile = XMLFile.create("farmsXML", xmlFilename, "farms")
	xmlFile:setTable("farms.farm", self.farms, function(path, farm)
		if farm.farmId == FarmManager.SPECTATOR_FARM_ID or farm.farmId == FarmManager.GUIDED_TOUR_FARM_ID then
			return 0
		end
		farm:saveToXMLFile(xmlFile, path)
	end)
	xmlFile:save()
	xmlFile:delete()
end
function FarmManager:loadFromXMLFile(xmlFilename)
	if xmlFilename == nil then
		self:loadDefaults()
		return false
	end
	local xmlFile = XMLFile.load("TempXML", xmlFilename)
	if xmlFile == nil then
		return false
	else
		for _, key in xmlFile:iterator("farms.farm") do
			local farm = Farm.new(true, g_client ~= nil)
			if farm:loadFromXMLFile(xmlFile, key) then
				farm:register()
				table.insert(self.farms, farm)
				self.farmIdToFarm[farm.farmId] = farm
			else
				farm:delete()
			end
		end
		self:mergeFarmsForSingleplayer()
		if g_currentMission:getIsClient() then
			local uniqueUserId = getUniqueUserId()
			self:playerJoinedGame(uniqueUserId, g_currentMission:getServerUserId())
		end
		xmlFile:delete()
		return true
	end
end
function FarmManager:loadDefaults()
	if not g_currentMission.missionDynamicInfo.isMultiplayer then
		local farm = self:createFarm(g_i18n:getText("ui_defaultFarmName"), 1, nil, FarmManager.SINGLEPLAYER_FARM_ID)
		farm:addUser(g_currentMission:getServerUserId(), getUniqueUserId(), true)
	end
	self:playerJoinedGame(getUniqueUserId(), g_currentMission:getServerUserId())
end
function FarmManager:mergeFarmsForSingleplayer()
	if g_currentMission.missionDynamicInfo.isMultiplayer then
		return
	else
		local specFarm = self.farmIdToFarm[FarmManager.SPECTATOR_FARM_ID]
		local tourFarm = self.farmIdToFarm[FarmManager.GUIDED_TOUR_FARM_ID]
		local spFarm = self.farmIdToFarm[FarmManager.SINGLEPLAYER_FARM_ID]
		if spFarm == nil then
			spFarm = self:createFarm(g_i18n:getText("ui_defaultFarmName"), 1, nil, FarmManager.SINGLEPLAYER_FARM_ID)
			spFarm:addUser(g_currentMission:getServerUserId(), getUniqueUserId(), true)
		end
		for _, farm in ipairs(self.farms) do
			local farmId = farm.farmId
			if farmId == FarmManager.SPECTATOR_FARM_ID or farmId == FarmManager.GUIDED_TOUR_FARM_ID or farmId == FarmManager.SINGLEPLAYER_FARM_ID then
				continue
			end
			if self.mergedFarms == nil then
				self.mergedFarms = {}
			end
			self.mergedFarms[farmId] = FarmManager.SINGLEPLAYER_FARM_ID
			spFarm:merge(farm)
		end
		spFarm.farmId = FarmManager.SINGLEPLAYER_FARM_ID
		self.farmIdToFarm = {}
		self.farmIdToFarm[FarmManager.SPECTATOR_FARM_ID] = specFarm
		self.farmIdToFarm[FarmManager.GUIDED_TOUR_FARM_ID] = tourFarm
		self.farmIdToFarm[FarmManager.SINGLEPLAYER_FARM_ID] = spFarm
		self.farms = { specFarm, spFarm, tourFarm }
		self.farmIdToFarm[FarmManager.SINGLEPLAYER_FARM_ID]:resetToSingleplayer()
	end
end
function FarmManager:mergeFarmlandsForSingleplayer()
	if not g_currentMission.missionDynamicInfo.isMultiplayer and self.mergedFarms ~= nil then
		for _, farmland in pairs(g_farmlandManager:getFarmlands()) do
			local ownerFarmId = g_farmlandManager:getFarmlandOwner(farmland.id)
			local newFarmId = self.mergedFarms[ownerFarmId]
			if newFarmId == nil then
				continue
			end
			g_farmlandManager:setLandOwnership(farmland.id, newFarmId, true)
		end
	end
end
function FarmManager:mergeObjectsForSingleplayer()
	if not g_currentMission.missionDynamicInfo.isMultiplayer and self.mergedFarms ~= nil then
		for _, vehicle in pairs(g_currentMission.vehicleSystem.vehicles) do
			local ownerFarmId = vehicle:getOwnerFarmId()
			local newFarmId = self.mergedFarms[ownerFarmId]
			if newFarmId == nil then
				continue
			end
			vehicle:setOwnerFarmId(newFarmId)
		end
		for _, placeable in pairs(g_currentMission.placeableSystem.placeables) do
			local ownerFarmId = placeable:getOwnerFarmId()
			local newFarmId = self.mergedFarms[ownerFarmId]
			if newFarmId == nil then
				continue
			end
			placeable:setOwnerFarmId(newFarmId)
		end
		for _, handTool in pairs(g_currentMission.handToolSystem.handTools) do
			local ownerFarmId = handTool:getOwnerFarmId()
			local newFarmId = self.mergedFarms[ownerFarmId]
			if newFarmId == nil then
				continue
			end
			handTool:setOwnerFarmId(newFarmId)
		end
		for _, saveItem in pairs(g_currentMission.itemSystem.itemsToSave) do
			local item = saveItem.item
			if item == nil or item.getOwnerFarmId == nil then
				continue
			end
			local ownerFarmId = item:getOwnerFarmId()
			local newFarmId = self.mergedFarms[ownerFarmId]
			if newFarmId == nil then
				continue
			end
			item:setOwnerFarmId(newFarmId)
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
function FarmManager:getFarmForUniqueUserId(uniqueUserId)
	if not g_currentMission.missionDynamicInfo.isMultiplayer then
		return self.farmIdToFarm[FarmManager.SINGLEPLAYER_FARM_ID]
	else
		for _, farm in ipairs(self.farms) do
			local player = farm.uniqueUserIdToPlayer[uniqueUserId]
			if farm.isSpectator or player == nil then
				continue
			end
			return farm
		end
		return self.farmIdToFarm[FarmManager.SPECTATOR_FARM_ID]
	end
end
function FarmManager:getFarmByUserId(userId)
	if not g_currentMission.missionDynamicInfo.isMultiplayer then
		return self.farmIdToFarm[FarmManager.SINGLEPLAYER_FARM_ID]
	else
		for _, farm in ipairs(self.farms) do
			local player = farm.userIdToPlayer[userId]
			if player == nil then
				continue
			end
			return farm
		end
		return self.farmIdToFarm[0]
	end
end
function FarmManager:getFarmById(farmId)
	return self.farmIdToFarm[farmId]
end
function FarmManager:getSpawnPoint(farmId)
	local farm = self:getFarmById(farmId)
	if farm == nil then
		return nil
	else
		return farm:getSpawnPoint()
	end
end
function FarmManager:getSleepCamera(farmId)
	local farm = self:getFarmById(farmId)
	if farm == nil then
		return nil
	else
		return farm:getSleepCamera()
	end
end
function FarmManager:updateFarms(farms, playerFarmId)
	self.farms = farms
	self.farmIdToFarm = {}
	for _, farm in ipairs(self.farms) do
		self.farmIdToFarm[farm.farmId] = farm
	end
end
function FarmManager:appendFarm(farm)
	if self.farmIdToFarm[farm.farmId] == nil then
		self.farmIdToFarm[farm.farmId] = farm
		table.insert(self.farms, farm)
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
function FarmManager:updateFarmStats(farmId, stat, delta)
	local farm = self.farmIdToFarm[farmId]
	if farm ~= nil then
		return farm.stats:updateStats(stat, delta)
	else
		return nil, nil
	end
end
function FarmManager:getFarmStatValue(farmId, stat)
	local farm = self.farmIdToFarm[farmId]
	if farm ~= nil then
		return farm.stats:getSessionValue(stat), farm.stats:getTotalValue(stat)
	else
		return 0, 0
	end
end
function FarmManager:playerJoinedGame(uniqueUserId, userId, user, connection)
	if g_currentMission:getIsServer() then
		local farm = self:getFarmForUniqueUserId(uniqueUserId)
		local didJoinFarm = farm:onUserJoinGame(uniqueUserId, userId, user)
		g_server:broadcastEvent(PlayerSwitchedFarmEvent.new(FarmManager.INVALID_FARM_ID, farm.farmId, userId), nil, connection)
		if didJoinFarm then
			local player = farm.userIdToPlayer[userId]
			if player ~= nil then
				g_server:broadcastEvent(PlayerPermissionsEvent.new(userId, player.permissions, player.isFarmManager), nil, connection)
			end
		end
	else
		printError("Error: FarmManager:playerJoinedGame() only allowed on server")
	end
end
function FarmManager:playerQuitGame(userId)
	if g_currentMission:getIsServer() then
		local farm = self:getFarmByUserId(userId)
		farm:onUserQuitGame(userId)
		g_server:broadcastEvent(PlayerSwitchedFarmEvent.new(farm.farmId, FarmManager.INVALID_FARM_ID, userId))
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
function FarmManager:createFarm(name, color, password, farmId)
	if not g_currentMission:getIsServer() then
		printError("Error: FarmManager:createFarm() only allowed on server")
		return nil
	elseif not (farmId ~= FarmManager.SINGLEPLAYER_FARM_ID and (not g_currentMission.missionDynamicInfo.isMultiplayer and 2 < #self.farms)) then
		local farm = Farm.new(true, g_client ~= nil)
		if farmId ~= FarmManager.SINGLEPLAYER_FARM_ID and #self.farms == FarmManager.MAX_NUM_FARMS + 2 then
			return nil, "Farm limit reached"
		end
		if self.farmIdToFarm[farmId] ~= nil then
			farmId = nil
		end
		if farmId == nil then
			farmId = self:findNextFarmId()
		end
		farm.farmId = farmId
		farm.name = name
		farm.color = color
		if password ~= "" then
			farm.password = password
		end
		farm:register()
		table.insert(self.farms, farm)
		self.farmIdToFarm[farm.farmId] = farm
		g_messageCenter:publish(MessageType.FARM_CREATED, farm.farmId)
		return farm
	else
		return nil
	end
end
function FarmManager:destroyFarm(farmId)
	if not g_currentMission.missionDynamicInfo.isMultiplayer then
		return
	else
		local farm = self.farmIdToFarm[farmId]
		if farm ~= nil then
			farm:delete()
			self:removeFarm(farmId)
			for i = #g_currentMission.vehicleSystem.vehicles, 1, -1 do
				local vehicle = g_currentMission.vehicleSystem.vehicles[i]
				if vehicle:getOwnerFarmId() == farmId then
					vehicle:delete()
				end
			end
			for i = #g_currentMission.placeableSystem.placeables, 1, -1 do
				local placeable = g_currentMission.placeableSystem.placeables[i]
				if placeable:getOwnerFarmId() == farmId then
					if placeable:getSellAction() == Placeable.SELL_AND_SPECTATOR_FARM then
						placeable:setOwnerFarmId(FarmManager.SPECTATOR_FARM_ID)
					else
						placeable:delete()
					end
				end
			end
			for _, item in pairs(g_currentMission.itemSystem.itemsToSave) do
				if item.getOwnerFarmId == nil then
					continue
				end
				if item:getOwnerFarmId() == farmId then
					item:delete()
				end
			end
			g_messageCenter:publish(MessageType.FARM_DELETED, farmId)
		end
	end
end
function FarmManager:removeFarm(farmId)
	self.farmIdToFarm[farmId] = nil
	for i, farm in ipairs(self.farms) do
		if farm.farmId == farmId then
			table.remove(self.farms, i)
			return
		end
	end
end
function FarmManager:findNextFarmId()
	for i = 1, FarmManager.MAX_FARM_ID do
		local inUse = false
		for _, farm in ipairs(self.farms) do
			if i == farm.farmId then
				inUse = true
				break
			end
		end
		if inUse then
			continue
		end
		return i
	end
	return nil
end
function FarmManager:consoleCommandSetFarm(farmId)
	local playerVehicle = g_localPlayer:getCurrentVehicle()
	if farmId ~= nil then
		farmId = tonumber(farmId)
		if playerVehicle == nil then
			g_client:getServerConnection():sendEvent(PlayerSetFarmEvent.new(g_localPlayer, farmId))
			return string.format("Updated farm id for player to '%d'", farmId)
		end
		if not g_currentMission:getIsServer() then
			return "This command currently only works on server"
		end
		local farm = self:getFarmById(farmId)
		if farm == nil then
			return string.format("Farm with id %d does not exist.", farmId)
		else
			playerVehicle:setOwnerFarmId(farmId)
			return string.format("Updated farm id for vehicle '%s' to '%d'", playerVehicle.configFileName, farmId)
		end
	elseif playerVehicle ~= nil then
		return string.format("No farmId specified. Current vehicle farmId is %s", playerVehicle:getOwnerFarmId())
	else
		return string.format("No farmId specified. Current player farmId is %d", g_localPlayer:getFarmId())
	end
end
g_farmManager = FarmManager.new()
