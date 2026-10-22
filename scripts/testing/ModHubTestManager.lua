ModHubTestManager = {}
local ModHubTestManager_mt = Class(ModHubTestManager)
ModHubTestManager.COMMAND_NAME = "gsModHubTestInstallAll"
ModHubTestManager.PARAM_BATCH_START = "modHubTestBatchStart"
ModHubTestManager.PARAM_BATCH_END = "modHubTestBatchEnd"
ModHubTestManager.PARAM_NEXT_MAP = "modHubTestNextMap"
ModHubTestManager.PARAM_AUTO_START = "autoStart"
ModHubTestManager.WARDROBE_SCREEN_NAME = "WardrobeScreen"
ModHubTestManager.STATE = { IDLE = 1, RESUME = 2, BEGIN = 3, UNINSTALL_ALL = 4, INSTALL_BATCH = 5, WAIT_INSTALL = 6, REFRESH_SAVEGAMES = 7, DELETE_SLOT = 8, START_GAME = 9, WAIT_IN_GAME = 10, LOAD_VEHICLES = 11, LOAD_PLACEABLES = 12, QUIT = 13, FINAL_UNINSTALL = 14, DONE = 15 }
ModHubTestManager.TIMEOUT = { MODHUB_LOAD = 120000, INSTALL = 1800000, REFRESH = 60000, DELETE = 60000, GAME_LOAD = 600000, LOAD = 1800000 }
ModHubTestManager.SAVEGAME_SLOT = 1
ModHubTestManager.MIN_FREE_SPACE_KB = 0
ModHubTestManager.MAX_BATCH_SIZE_NON_CONSOLE = 10
function ModHubTestManager.new(customMt)
	local self = setmetatable({}, customMt or ModHubTestManager_mt)
	self.state = ModHubTestManager.STATE.IDLE
	self.stateTimer = 0
	self.downloadMods = {}
	self.batchStartIndex = 1
	self.batchEndIndex = 0
	self.batchModIds = {}
	self.mapIndex = 1
	self.numMaps = 0
	self.refreshReturnState = ModHubTestManager.STATE.DELETE_SLOT
	self.pendingResume = ModHubTestManager.readResumeToken()
	self:resetTransientFlags()
	self:resetSummary()
	return self
end
function ModHubTestManager:addConsoleCommands()
	addConsoleCommand(ModHubTestManager.COMMAND_NAME, "Stress-tests installing and loading all ModHub mods on all maps", "consoleCommandTestInstallAll", self)
end
function ModHubTestManager:removeConsoleCommands()
	removeConsoleCommand(ModHubTestManager.COMMAND_NAME)
end
function ModHubTestManager:consoleCommandTestInstallAll()
	if self.state ~= ModHubTestManager.STATE.IDLE then
		return "ModHub test already running"
	elseif g_currentMission ~= nil then
		return "Error: command must be started from the main menu"
	elseif g_modHubController == nil then
		return "Error: ModHub controller not available"
	else
		self.batchStartIndex = 1
		self.mapIndex = 1
		self:setState(ModHubTestManager.STATE.BEGIN)
		return "ModHub install/load stress test started"
	end
end
function ModHubTestManager:update(dt)
	if self.state == ModHubTestManager.STATE.IDLE then
		self:tryStartPendingResume()
	else
		self.stateTimer = self.stateTimer + dt
		local handler = ModHubTestManager.STATE_HANDLERS[self.state]
		if handler ~= nil then
			handler(self)
		end
	end
end
function ModHubTestManager:setState(newState)
	self:log("state %s -> %s", ModHubTestManager.getStateName(self.state), ModHubTestManager.getStateName(newState))
	self.state = newState
	self.stateTimer = 0
	self:resetTransientFlags()
end
function ModHubTestManager:resetTransientFlags()
	self.actionIssued = false
	self.deleteRequested = false
	self.deleteDone = false
	self.refreshRequested = false
	self.refreshDone = false
	self.wardrobeDismissed = false
end
function ModHubTestManager:resetSummary()
	self.installFailures = 0
	self.timeoutCount = 0
end
function ModHubTestManager:tryStartPendingResume()
	if self.pendingResume == nil then
		return
	else
		local controllersReady = g_modHubController ~= nil and g_mapManager ~= nil and g_savegameController ~= nil
		local atMenu = g_gameStateManager ~= nil and g_gameStateManager:getGameState() == GameState.MENU_MAIN and g_currentMission == nil
		if not controllersReady or not atMenu then
			return
		end
		self:setState(ModHubTestManager.STATE.RESUME)
	end
end
function ModHubTestManager:updateResume()
	local resume = self.pendingResume
	if resume == nil then
		self:setState(ModHubTestManager.STATE.DONE)
		return
	end
	if not self:isModHubReady() then
		if ModHubTestManager.TIMEOUT.MODHUB_LOAD < self.stateTimer then
			self:log("ModHub not ready after timeout - aborting resume")
			self.pendingResume = nil
			self:setState(ModHubTestManager.STATE.DONE)
		end
		return
	end
	self:buildDownloadMods()
	if #self.downloadMods == 0 then
		self:log("no downloadable mods on resume - finishing")
		self.pendingResume = nil
		self:setState(ModHubTestManager.STATE.DONE)
	else
		self.pendingResume = nil
		self.numMaps = g_mapManager:getNumOfMaps()
		self:log("resuming: batch %d..%d nextMap %d (downloadMods %d, maps %d)", resume.batchStart, resume.batchEnd, resume.nextMap, #self.downloadMods, self.numMaps)
		if resume.nextMap <= self.numMaps then
			self.batchStartIndex = resume.batchStart
			self.batchEndIndex = resume.batchEnd
			self.mapIndex = resume.nextMap
			self:enterMapLoop()
		else
			self.batchStartIndex = resume.batchEnd + 1
			if #self.downloadMods < self.batchStartIndex then
				self:log("all %d mods checked - uninstalling everything", #self.downloadMods)
				self:setState(ModHubTestManager.STATE.FINAL_UNINSTALL)
			else
				self.mapIndex = 1
				self:setState(ModHubTestManager.STATE.BEGIN)
			end
		end
	end
end
function ModHubTestManager:updateBegin()
	if not self:isModHubReady() then
		if ModHubTestManager.TIMEOUT.MODHUB_LOAD < self.stateTimer then
			self:log("ModHub not ready after timeout - finishing")
			self:setState(ModHubTestManager.STATE.DONE)
		end
		return
	end
	self:buildDownloadMods()
	if #self.downloadMods == 0 then
		self:log("no downloadable mods available - finishing")
		self:setState(ModHubTestManager.STATE.DONE)
	else
		self.batchModIds = {}
		self:setState(ModHubTestManager.STATE.UNINSTALL_ALL)
	end
end
function ModHubTestManager:updateUninstallAll()
	self:updateUninstallStep(ModHubTestManager.STATE.INSTALL_BATCH)
end
function ModHubTestManager:updateFinalUninstall()
	self:updateUninstallStep(ModHubTestManager.STATE.DONE)
end
function ModHubTestManager:updateUninstallStep(nextState)
	self:uninstallAllInstalled()
	self:setState(nextState)
end
function ModHubTestManager:updateInstallBatch()
	self.batchModIds = {}
	local index = self.batchStartIndex
	while index <= #self.downloadMods do
		local reachedBatchLimit = not GS_IS_CONSOLE_VERSION and ModHubTestManager.MAX_BATCH_SIZE_NON_CONSOLE <= #self.batchModIds
		if reachedBatchLimit then
			break
		end
		local modInfo = self.downloadMods[index]
		local modId = modInfo:getId()
		local neededKb = g_modHubController:getTotalFilesizeKb(modId)
		local freeKb = g_modHubController:getFreeModSpaceKb()
		if freeKb - neededKb < ModHubTestManager.MIN_FREE_SPACE_KB then
			break
		end
		g_modHubController:install(modId)
		table.insert(self.batchModIds, modId)
		self:log("install queued: id %d '%s' (%d KB, free %d KB)", modId, modInfo:getName(), neededKb, freeKb)
		index = index + 1
	end
	self.batchEndIndex = index - 1
	if self.batchEndIndex < self.batchStartIndex then
		self:log("mod at index %d does not fit in storage - skipping", self.batchStartIndex)
		self.batchEndIndex = self.batchStartIndex
	end
	self:log("batch installs index range %d..%d (%d mods)", self.batchStartIndex, self.batchEndIndex, #self.batchModIds)
	self:setState(ModHubTestManager.STATE.WAIT_INSTALL)
end
function ModHubTestManager:updateWaitInstall()
	local stillDownloading = 0
	local failed = 0
	for _, modId in ipairs(self.batchModIds) do
		stillDownloading, failed = self:accumulateInstallState(modId, stillDownloading, failed)
		for _, dependentInfo in ipairs(g_modHubController:getDependentMods(modId)) do
			stillDownloading, failed = self:accumulateInstallState(dependentInfo:getId(), stillDownloading, failed)
		end
	end
	if stillDownloading == 0 then
		self.installFailures = failed
		self:log("batch install finished (%d failed)", failed)
		self.mapIndex = 1
		self.numMaps = g_mapManager:getNumOfMaps()
		self:enterMapLoop()
	else
		if ModHubTestManager.TIMEOUT.INSTALL < self.stateTimer then
			self:log("TIMEOUT installing, %d mods still downloading - continuing", stillDownloading)
			self.timeoutCount = self.timeoutCount + 1
			self.mapIndex = 1
			self.numMaps = g_mapManager:getNumOfMaps()
			self:enterMapLoop()
		end
	end
end
function ModHubTestManager:updateRefreshSavegames()
	if not self.refreshRequested then
		self.refreshDone = false
		self.refreshRequested = true
		g_savegameController:updateSavegames(self.onSavegamesUpdated, self)
	elseif self.refreshDone then
		self:setState(self.refreshReturnState)
	else
		if ModHubTestManager.TIMEOUT.REFRESH < self.stateTimer then
			self:log("TIMEOUT refreshing savegames - continuing")
			self.timeoutCount = self.timeoutCount + 1
			self:setState(self.refreshReturnState)
		end
	end
end
function ModHubTestManager:updateDeleteSlot()
	if not self.deleteRequested then
		local savegame = g_savegameController:getSavegame(ModHubTestManager.SAVEGAME_SLOT)
		if not savegame.isValid then
			self:setState(ModHubTestManager.STATE.START_GAME)
		else
			self.deleteDone = false
			self.deleteRequested = true
			self:log("deleting savegame slot %d", ModHubTestManager.SAVEGAME_SLOT)
			g_savegameController:deleteSavegame(ModHubTestManager.SAVEGAME_SLOT, self.onSavegameDeleted, self)
		end
	elseif self.deleteDone then
		self.refreshReturnState = ModHubTestManager.STATE.START_GAME
		self:setState(ModHubTestManager.STATE.REFRESH_SAVEGAMES)
	else
		if ModHubTestManager.TIMEOUT.DELETE < self.stateTimer then
			self:log("TIMEOUT deleting savegame - continuing")
			self.timeoutCount = self.timeoutCount + 1
			self:setState(ModHubTestManager.STATE.START_GAME)
		end
	end
end
function ModHubTestManager:updateStartGame()
	local mapData = g_mapManager:getMapDataByIndex(self.mapIndex)
	if mapData == nil then
		self:log("no map at index %d - advancing", self.mapIndex)
		self:advanceMapInSession()
		return
	end
	local savegame = g_savegameController:getSavegame(ModHubTestManager.SAVEGAME_SLOT)
	self:configureNewSavegame(savegame, mapData.id)
	if savegame.map == nil then
		self:log("map '%s' not available - advancing", mapData.id)
		self:advanceMapInSession()
	else
		local missionDynamicInfo = self:buildMissionDynamicInfo(savegame, mapData.id)
		self:log("starting map %d/%d '%s' with %d active mods", self.mapIndex, self.numMaps, mapData.id, #missionDynamicInfo.mods)
		StartParams.setValue(ModHubTestManager.PARAM_AUTO_START, "")
		g_mpLoadingScreen:setMissionInfo(savegame, missionDynamicInfo)
		g_gui:changeScreen(nil, MPLoadingScreen)
		g_mpLoadingScreen:loadSavegameAndStart()
		g_startMissionInfo:reset()
		self:setState(ModHubTestManager.STATE.WAIT_IN_GAME)
	end
end
function ModHubTestManager:updateWaitInGame()
	if g_gui.currentGuiName == ModHubTestManager.WARDROBE_SCREEN_NAME then
		if not self.wardrobeDismissed then
			self:log("confirming wardrobe screen")
			g_wardrobeScreen:onButtonBack()
			self.wardrobeDismissed = true
		end
	else
		local isPlaying = g_gameStateManager:getGameState() == GameState.PLAY
		if g_currentMission ~= nil and (g_currentMission.isLoaded and isPlaying) then
			self:setState(ModHubTestManager.STATE.LOAD_VEHICLES)
			return
		end
		if ModHubTestManager.TIMEOUT.GAME_LOAD < self.stateTimer then
			self:log("TIMEOUT loading game - quitting to menu")
			self.timeoutCount = self.timeoutCount + 1
			self:setState(ModHubTestManager.STATE.QUIT)
		end
	end
end
function ModHubTestManager:updateLoadVehicles()
	local vehicleSystem = g_currentMission ~= nil and g_currentMission.vehicleSystem or nil
	if vehicleSystem == nil then
		self:setState(ModHubTestManager.STATE.QUIT)
	elseif not self.actionIssued then
		local result = vehicleSystem:consoleCommandLoadAllVehicles("false", "true")
		self:log("load all mod vehicles: %s", tostring(result))
		self.actionIssued = true
	elseif vehicleSystem.debugVehiclesToBeLoaded == nil then
		self:log("mod vehicles loaded and removed")
		self:setState(ModHubTestManager.STATE.LOAD_PLACEABLES)
	else
		if ModHubTestManager.TIMEOUT.LOAD < self.stateTimer then
			self:log("TIMEOUT loading vehicles - continuing")
			self.timeoutCount = self.timeoutCount + 1
			self:setState(ModHubTestManager.STATE.LOAD_PLACEABLES)
		end
	end
end
function ModHubTestManager:updateLoadPlaceables()
	local placeableSystem = g_currentMission ~= nil and g_currentMission.placeableSystem or nil
	if placeableSystem == nil then
		self:setState(ModHubTestManager.STATE.QUIT)
	elseif not self.actionIssued then
		local result = placeableSystem:consoleCommandLoadAllPlaceables("true")
		self:log("load all mod placeables: %s", tostring(result))
		self.actionIssued = true
	elseif not placeableSystem.isLoadAllRunning then
		self:log("placeables loaded and removed")
		self:setState(ModHubTestManager.STATE.QUIT)
	else
		if ModHubTestManager.TIMEOUT.LOAD < self.stateTimer then
			self:log("TIMEOUT loading placeables - continuing")
			self.timeoutCount = self.timeoutCount + 1
			self:setState(ModHubTestManager.STATE.QUIT)
		end
	end
end
function ModHubTestManager:updateQuit()
	local nextMap = self.mapIndex + 1
	local restartArgs = string.format("-%s %d -%s %d -%s %d", ModHubTestManager.PARAM_BATCH_START, self.batchStartIndex, ModHubTestManager.PARAM_BATCH_END, self.batchEndIndex, ModHubTestManager.PARAM_NEXT_MAP, nextMap)
	self:log("quitting to menu with resume token: batch %d..%d nextMap %d", self.batchStartIndex, self.batchEndIndex, nextMap)
	self.state = ModHubTestManager.STATE.IDLE
	OnInGameMenuMenu(false, false, restartArgs)
end
function ModHubTestManager:updateDone()
	self:log("FINISHED: all %d ModHub mods checked across all maps", #self.downloadMods)
	self.state = ModHubTestManager.STATE.IDLE
end
function ModHubTestManager:onSavegameDeleted(errorCode)
	if errorCode ~= Savegame.ERROR_OK then
		self:log("savegame deletion returned error code %s", tostring(errorCode))
	end
	self.deleteDone = true
end
function ModHubTestManager:onSavegamesUpdated(errorCode)
	if errorCode == Savegame.ERROR_OK or errorCode == Savegame.ERROR_DATA_CORRUPT then
		g_savegameController:loadSavegames()
	else
		self:log("savegame list update returned error code %s", tostring(errorCode))
	end
	self.refreshDone = true
end
function ModHubTestManager:isModHubReady()
	if not modDownloadManagerLoaded() then
		return false
	else
		g_modHubController:load()
		self:setupModHubCallbacks()
		return true
	end
end
function ModHubTestManager:setupModHubCallbacks()
	local noOp = function() end
	g_modHubController:setUninstalledCallback(noOp, nil)
	g_modHubController:setUninstallFailedCallback(noOp, nil)
	g_modHubController:setModInstallFailedCallback(noOp, nil)
	g_modHubController:setDependentModInstallFailedCallback(noOp, nil)
	g_modHubController:setAddedToDownloadCallback(noOp, nil)
end
function ModHubTestManager:buildDownloadMods()
	local seen = {}
	local modIds = {}
	local numCategories = getNumModCategories()
	for categoryId = 1, numCategories do
		if self:getIsContentCategory(categoryId) then
			for _, modInfo in ipairs(g_modHubController:getModsByCategory(categoryId, true)) do
				local modId = modInfo:getId()
				local isInstallable = false
				if 0 <= modId then
					isInstallable = not modInfo:getIsDLC()
				end
				if isInstallable then
					if seen[modId] then
						continue
					end
					seen[modId] = true
					table.insert(modIds, modId)
				end
			end
		end
	end
	table.sort(modIds)
	local mods = {}
	for _, modId in ipairs(modIds) do
		table.insert(mods, g_modHubController:getModInfo(modId))
	end
	self.downloadMods = mods
end
function ModHubTestManager:getIsContentCategory(categoryId)
	local name = getModCategoryName(categoryId - 1)
	if name == nil then
		return false
	end
	local localCategory = g_modHubController.localCategories[name]
	if localCategory == nil then
		return false
	else
		return not localCategory.isTab and not localCategory.isHidden
	end
end
function ModHubTestManager:uninstallAllInstalled()
	local category = g_modHubController:getCategory("installed")
	if category == nil then
		return
	else
		local mods = g_modHubController:getModsByCategory(category.id, true)
		self:log("uninstalling %d installed mods", #mods)
		for _, modInfo in ipairs(mods) do
			g_modHubController:uninstall(modInfo:getId())
		end
	end
end
function ModHubTestManager:accumulateInstallState(modId, stillDownloading, failed)
	local modInfo = g_modHubController:getModInfo(modId)
	if modInfo == nil then
		return stillDownloading, failed
	elseif modInfo:getIsFailed() then
		return stillDownloading, failed + 1
	elseif not modInfo:getIsInstalled() then
		return stillDownloading + 1, failed
	else
		return stillDownloading, failed
	end
end
function ModHubTestManager:configureNewSavegame(savegame, mapId)
	g_startMissionInfo:reset()
	g_startMissionInfo.isMultiplayer = false
	g_startMissionInfo.mapId = mapId
	g_startMissionInfo.economicDifficulty = EconomicDifficulty.NORMAL
	g_startMissionInfo.initialMoney = 100000
	g_startMissionInfo.initialLoan = 0
	g_startMissionInfo.hasStartFarm = true
	g_startMissionInfo.startWithGuidedTour = false
	savegame:applyStartInfo(g_startMissionInfo)
	savegame.isNewSPCareer = true
	savegame.vehiclesXMLLoad = savegame.defaultVehiclesXMLFilename
	savegame.handToolsXMLLoad = savegame.defaultHandToolsXMLFilename
	savegame.itemsXMLLoad = savegame.defaultItemsXMLFilename
	savegame.placeablesXMLLoad = savegame.defaultPlaceablesXMLFilename
	savegame.onCreateObjectsXMLLoad = nil
	savegame.environmentXML = nil
	savegame.economyXMLLoad = nil
	savegame.farmlandXMLLoad = nil
	savegame.aiSystemXMLLoad = nil
	savegame.navigationSystemXMLLoad = nil
	savegame.npcXMLLoad = nil
	savegame.densityMapHeightXMLLoad = nil
	savegame.treePlantXMLLoad = nil
end
function ModHubTestManager:buildMissionDynamicInfo(savegame, mapId)
	local missionDynamicInfo = {}
	missionDynamicInfo.isMultiplayer = false
	missionDynamicInfo.autoSave = false
	if savegame.map.prohibitOtherMods then
		local mapModName = g_mapManager:getModNameFromMapId(mapId)
		local mapMod = g_modManager:getModByName(mapModName)
		missionDynamicInfo.mods = mapMod ~= nil and { mapMod } or {}
		return missionDynamicInfo
	else
		missionDynamicInfo.mods = self:buildActiveModsList(mapId)
		return missionDynamicInfo
	end
end
function ModHubTestManager:buildActiveModsList(mapId)
	local mods = {}
	local chosenMapModName = g_mapManager:getModNameFromMapId(mapId)
	for _, mod in ipairs(g_modManager:getMods()) do
		if mod.isSelectable then
			local _v11 = self:getIsMapMod(mod.modName)
			local isOtherMapMod = false
			if isOtherMapMod then
				continue
			end
			table.insert(mods, mod)
		end
	end
	return mods
end
function ModHubTestManager:getIsMapMod(modName)
	if modName == nil then
		return false
	else
		for mapId in pairs(g_mapManager.idToMap) do
			if g_mapManager:getModNameFromMapId(mapId) == modName then
				return true
			end
		end
		return false
	end
end
function ModHubTestManager:enterMapLoop()
	self.refreshReturnState = ModHubTestManager.STATE.DELETE_SLOT
	self:setState(ModHubTestManager.STATE.REFRESH_SAVEGAMES)
end
function ModHubTestManager:advanceMapInSession()
	if self.mapIndex < self.numMaps then
		self.mapIndex = self.mapIndex + 1
		self:enterMapLoop()
		return
	end
	self.batchStartIndex = self.batchEndIndex + 1
	if #self.downloadMods < self.batchStartIndex then
		self:setState(ModHubTestManager.STATE.FINAL_UNINSTALL)
	else
		self.mapIndex = 1
		self:setState(ModHubTestManager.STATE.BEGIN)
	end
end
function ModHubTestManager:log(message, ...)
	Logging.info("[ModHubTest] " .. message, ...)
end
function ModHubTestManager.readResumeToken()
	local batchStartValue = StartParams.getValue(ModHubTestManager.PARAM_BATCH_START)
	if batchStartValue == nil then
		return nil
	else
		local batchStart = tonumber(batchStartValue)
		local batchEnd = tonumber(StartParams.getValue(ModHubTestManager.PARAM_BATCH_END))
		local nextMap = tonumber(StartParams.getValue(ModHubTestManager.PARAM_NEXT_MAP))
		if batchStart == nil or batchEnd == nil or nextMap == nil then
			return nil
		end
		local resume = { ["batchStart"] = batchStart, ["batchEnd"] = batchEnd, ["nextMap"] = nextMap }
		return resume
	end
end
function ModHubTestManager.getStateName(state)
	for name, value in pairs(ModHubTestManager.STATE) do
		if value == state then
			return name
		end
	end
	return tostring(state)
end
ModHubTestManager.STATE_HANDLERS = {
	[ModHubTestManager.STATE.RESUME] = ModHubTestManager.updateResume,
	[ModHubTestManager.STATE.BEGIN] = ModHubTestManager.updateBegin,
	[ModHubTestManager.STATE.UNINSTALL_ALL] = ModHubTestManager.updateUninstallAll,
	[ModHubTestManager.STATE.INSTALL_BATCH] = ModHubTestManager.updateInstallBatch,
	[ModHubTestManager.STATE.WAIT_INSTALL] = ModHubTestManager.updateWaitInstall,
	[ModHubTestManager.STATE.REFRESH_SAVEGAMES] = ModHubTestManager.updateRefreshSavegames,
	[ModHubTestManager.STATE.DELETE_SLOT] = ModHubTestManager.updateDeleteSlot,
	[ModHubTestManager.STATE.START_GAME] = ModHubTestManager.updateStartGame,
	[ModHubTestManager.STATE.WAIT_IN_GAME] = ModHubTestManager.updateWaitInGame,
	[ModHubTestManager.STATE.LOAD_VEHICLES] = ModHubTestManager.updateLoadVehicles,
	[ModHubTestManager.STATE.LOAD_PLACEABLES] = ModHubTestManager.updateLoadPlaceables,
	[ModHubTestManager.STATE.QUIT] = ModHubTestManager.updateQuit,
	[ModHubTestManager.STATE.FINAL_UNINSTALL] = ModHubTestManager.updateFinalUninstall,
	[ModHubTestManager.STATE.DONE] = ModHubTestManager.updateDone,
}
g_modHubTestManager = ModHubTestManager.new()
