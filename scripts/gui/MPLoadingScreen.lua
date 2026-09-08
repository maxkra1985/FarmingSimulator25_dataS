-- Local values: percentagePerMs, MPLoadingScreen_mt
MPLoadingScreen = {}
MPLoadingScreen.STATE_NONE = 0
MPLoadingScreen.STATE_CONNECTING = 1
MPLoadingScreen.STATE_WAIT_FOR_ACCEPT = 2
MPLoadingScreen.STATE_SYNCHRONIZING = 3
MPLoadingScreen.STATE_LOADING = 4
MPLoadingScreen.STATE_WAIT_FOR_MISSION = 5
MPLoadingScreen.STATE_READY = 6
MPLoadingScreen.STATE_PORT_TESTING = 7
MPLoadingScreen.NUM_GAMEPLAY_HINTS = 4
MPLoadingScreen.SAVEGAME_LOADING_DIALOG_DELAY = 500
local v1_ = 0.000015833333333333333
MPLoadingScreen.LOAD_TARGETS = {
	["WAIT_FOR_ACCEPT"] = 1,
	["VEHICLE_VALIDATION"] = 2,
	["SPECIALIZATIONS"] = 3,
	["STORE"] = 4,
	["DATA"] = 5,
	["MAP"] = 6,
	["TERRAIN"] = 7,
	["ADDITIONAL_FILES"] = 8,
	["VEHICLES"] = 9,
	["FINISHED"] = 10
}
MPLoadingScreen.LOAD_TARGET_DATA = {}
MPLoadingScreen.LOAD_TARGET_DATA[MPLoadingScreen.LOAD_TARGETS.WAIT_FOR_ACCEPT] = {
	["percentage"] = 0,
	["percentagePerMs"] = 0,
	["nextStepText"] = nil,
	["nextStepTextMultiplayer"] = "ui_loading_connectingToServer"
}
MPLoadingScreen.LOAD_TARGET_DATA[MPLoadingScreen.LOAD_TARGETS.VEHICLE_VALIDATION] = {
	["percentage"] = 0.1,
	["percentagePerMs"] = v1_,
	["nextStepText"] = "ui_loading_data"
}
MPLoadingScreen.LOAD_TARGET_DATA[MPLoadingScreen.LOAD_TARGETS.SPECIALIZATIONS] = {
	["percentage"] = 0.15,
	["percentagePerMs"] = v1_,
	["nextStepText"] = "ui_loading_store"
}
MPLoadingScreen.LOAD_TARGET_DATA[MPLoadingScreen.LOAD_TARGETS.STORE] = {
	["percentage"] = 0.2,
	["percentagePerMs"] = v1_,
	["nextStepText"] = "ui_loading_map"
}
MPLoadingScreen.LOAD_TARGET_DATA[MPLoadingScreen.LOAD_TARGETS.DATA] = {
	["percentage"] = 0.4,
	["percentagePerMs"] = v1_,
	["nextStepText"] = "ui_loading_map"
}
MPLoadingScreen.LOAD_TARGET_DATA[MPLoadingScreen.LOAD_TARGETS.MAP] = {
	["percentage"] = 0.55,
	["percentagePerMs"] = v1_,
	["nextStepText"] = "ui_loading_map"
}
MPLoadingScreen.LOAD_TARGET_DATA[MPLoadingScreen.LOAD_TARGETS.TERRAIN] = {
	["percentage"] = 0.58,
	["percentagePerMs"] = v1_,
	["nextStepText"] = "ui_loading_map"
}
MPLoadingScreen.LOAD_TARGET_DATA[MPLoadingScreen.LOAD_TARGETS.ADDITIONAL_FILES] = {
	["percentage"] = 0.6,
	["percentagePerMs"] = 0,
	["nextStepText"] = "ui_loading_vehicles"
}
MPLoadingScreen.LOAD_TARGET_DATA[MPLoadingScreen.LOAD_TARGETS.VEHICLES] = {
	["percentage"] = 0.9,
	["percentagePerMs"] = 0,
	["nextStepText"] = "ui_loading_compilingShaders",
	["nextStepTextConsole"] = "ui_loading_vehicles"
}
MPLoadingScreen.LOAD_TARGET_DATA[MPLoadingScreen.LOAD_TARGETS.FINISHED] = {
	["percentage"] = 1,
	["percentagePerMs"] = 0,
	["nextStepText"] = "ui_loading_finished"
}
local percentagePerMs = Class(MPLoadingScreen, ScreenElement)
function MPLoadingScreen.register()
	local v3_ = MPLoadingScreen.new()
	g_gui:loadGui("dataS/gui/MPLoadingScreen.xml", "MPLoadingScreen", v3_)
	return v3_
end

-- Upvalues: MPLoadingScreen_mt
-- Local values: self
function MPLoadingScreen.new(target, custom_mt)
	-- upvalues: (copy) percentagePerMs
	local v6_ = ScreenElement.new(target, custom_mt or percentagePerMs)
	v6_.acceptCancelTimer = -1
	v6_.actionTimerCount = -1
	v6_.doLoad = false
	v6_.preSimulateCount = -1
	v6_.preSimulateSteps = 5
	v6_.loadFunction = OnLoadingScreen
	v6_.isClient = false
	v6_.isBackAllowed = false
	v6_.currentGameplayHint = nil
	v6_.currentGameplayHints = nil
	v6_.isCancel = true
	v6_.gameplayHintDuration = 6500
	v6_.gameplayHintTime = v6_.gameplayHintDuration
	v6_.savegameLoadingDialogDelay = -1
	v6_.state = MPLoadingScreen.STATE_NONE
	v6_.currentTarget = MPLoadingScreen.LOAD_TARGETS.WAIT_FOR_ACCEPT
	return v6_
end

function MPLoadingScreen:onCreate()
	self.button = self.buttonOkPC
end

function MPLoadingScreen:onOpen()
	MPLoadingScreen:superClass().onOpen(self)
	self.button:setVisible(false)
	self:setMapTitleAndPreview()
	self.loadingBar.absSize[1] = 0
	self.gameTitle = self.missionInfo.savegameName
	if self.missionDynamicInfo.isMultiplayer then
		self.gameTitle = ""
	end
	self.mpLoadingAnimation:setVisible(true)
	self.mpLoadingAnimationDone:setVisible(false)
	self.loadPercentage = 0
	self.totalLoadPercentage = 0
	self.loadTarget = 1
	g_messageCenter:subscribe(MessageType.ENQUEUED_ALL_LOADINGS, self.onEnqueuedAllLoadings, self)
	self:hitLoadingTarget(MPLoadingScreen.LOAD_TARGETS.WAIT_FOR_ACCEPT)
	enterCpuBoostMode()
end

function MPLoadingScreen:onClose()
	MPLoadingScreen:superClass().onClose(self)
	self.mapSelectionPreview:setImageFilename("dataS/menu/black.png")
	g_messageCenter:unsubscribe(MessageType.ENQUEUED_ALL_LOADINGS, self)
	leaveCpuBoostMode()
end

-- Local values: restartScreen
function MPLoadingScreen:cancelLoading(showConnectionLost)
	saveReadSavegameFinish("", self)
	leaveCpuBoostMode()
	g_cameraManager:setDefaultCamera()
	if self.state == MPLoadingScreen.STATE_PORT_TESTING then
		netShutdown(0, 0)
		g_gui:changeScreen(nil, self.returnScreenClass or MultiplayerScreen)
	elseif self.isClient then
		if g_currentMission == nil then
			self:cleanup()
		else
			OnInGameMenuMenu()
		end
		if masterServerConnectFront == nil then
			local v12_ = RestartManager.START_SCREEN_MULTIPLAYER
			RestartManager:setStartScreen(v12_)
			doRestart(false, "")
		else
			g_gui:changeScreen(nil, self.returnScreenClass or MultiplayerScreen)
		end
	else
		if g_currentMission == nil then
			self:cleanup()
		end
		OnInGameMenuMenu()
	end
	if showConnectionLost then
		InfoDialog.show(g_i18n:getText("ui_connectionLost"))
	end
end

function MPLoadingScreen:onClickCancel()
	if self.isCancel and (self.missionDynamicInfo.isMultiplayer and self.missionDynamicInfo.isClient) then
		self:cancelLoading()
	end
end

function MPLoadingScreen:onClickOk(element)
	MPLoadingScreen:superClass().onClickOk(self)
	if self.state == MPLoadingScreen.STATE_READY then
		self:setButtonState(MPLoadingScreen.STATE_NONE)
		g_inputBinding:revertContext(false)
		g_currentMission:onStartMission()
		g_inputBinding:setContext(Gui.INPUT_CONTEXT_MENU, false, false)
		g_gui:showGui("")
		g_inputBinding:setShowMouseCursor(false)
		g_currentMission.pressStartPaused = false
		if g_currentMission:getIsServer() then
			g_currentMission:tryUnpauseGame()
		end
		if g_dedicatedServer ~= nil then
			g_dedicatedServer:lowerFramerate()
			if g_dedicatedServer.pauseGameIfEmpty then
				g_currentMission.dediEmptyPaused = true
				g_currentMission:pauseGame()
			end
		end
		if Profiler.IS_INITIALIZED then
			Profiler.setIsReady()
		end
		g_messageCenter:publish(MessageType.CURRENT_MISSION_LOADED)
		if g_dedicatedServer == nil and (Platform.hasWardrobe and not Profiler.IS_INITIALIZED) and (g_currentMission:getIsServer() and not self.missionInfo.isValid or not g_currentMission:getIsServer() and self.knownPlayerOnServer == false) then
			self:openWardrobe()
		end
	end
end

-- Local values: dlcsVerified, targetData, nextData, maxTarget, maxAdditionalPercentage, additionalPercentage, pendingObjects, ratio, percentage, ratio, locaString, text, numRemainingShaders, percentage, loadPercentage, hints
function MPLoadingScreen:update(dt)
	MPLoadingScreen:superClass().update(self, dt)
	if storeHaveDlcsChanged() then
		g_forceNeedsDlcsAndModsReload = true
		if not verifyDlcs() then
			OnInGameMenuMenu()
			InfoDialog.show(g_i18n:getText("ui_storageDeviceWithDlcsRemoved"), self.dlcProblemOnQuitOk, self)
			return
		end
	end
	if GS_PLATFORM_PLAYSTATION and self.missionDynamicInfo.isMultiplayer then
		if getMultiplayerAvailability() == MultiplayerAvailability.NOT_AVAILABLE then
			if g_currentMission == nil then
				self:cleanup()
				g_gui:showGui("MainScreen")
			else
				OnInGameMenuMenu()
			end
		end
		if getNetworkError() then
			if g_currentMission == nil then
				self:cleanup()
				ConnectionFailedDialog.showMasterServerConnectionFailedReason(MasterServerConnection.FAILED_CONNECTION_LOST, "MainScreen")
			else
				OnInGameMenuMenu(nil, true)
			end
		end
	end
	local v17_ = MPLoadingScreen.LOAD_TARGET_DATA[self.currentTarget]
	local v18_ = MPLoadingScreen.LOAD_TARGET_DATA[self.currentTarget + 1]
	local v19_ = v18_ ~= nil and v18_.percentage or v17_.percentage
	local v20_ = v19_ - v17_.percentage
	local v21_ = 0
	if self.currentTarget == MPLoadingScreen.LOAD_TARGETS.ADDITIONAL_FILES and self.totalPendingObjects ~= nil then
		local v22_ = self:getNumPendingObjects()
		if v22_ > 0 and self.totalPendingObjects > 0 then
			local v23_ = v22_ / self.totalPendingObjects
			v21_ = (1 - math.clamp(v23_, 0, 1)) * v20_
		else
			self:hitLoadingTarget(MPLoadingScreen.LOAD_TARGETS.VEHICLES)
		end
	elseif self.currentTarget == MPLoadingScreen.LOAD_TARGETS.VEHICLES then
		local v24_ = 0
		local v25_ = v17_.nextStepText
		if Platform.isConsole then
			v25_ = v17_.nextStepTextConsole or v25_
		end
		local v26_ = g_i18n:getText(v25_)
		if self.numRemainingShaders > 0 then
			local v27_ = getRemainingShadersToWarmup()
			v24_ = v27_ / self.numRemainingShaders
			local v28_ = string.format
			local v29_ = self.numRemainingShaders - v27_
			v26_ = v28_("%s\n(%d/%d)", v26_, math.max(0, v29_), self.numRemainingShaders)
		end
		self.loadingInfo:setText(v26_)
		v21_ = (1 - math.clamp(v24_, 0, 1)) * v20_
	end
	self.loadPercentage = self.loadPercentage + v17_.percentagePerMs * dt
	local v30_ = self.loadPercentage + v21_
	local v31_ = math.min(v30_, v19_)
	self.totalLoadPercentage = v31_
	self.loadingBar.absSize[1] = self.loadingBar.parent.absSize[1] * v31_
	self.loadingBarPercentage:setText(string.format("%d%%", v31_ * 100))
	if self.state == MPLoadingScreen.STATE_WAIT_FOR_ACCEPT then
		if GS_PLATFORM_PLAYSTATION and self.acceptCancelTimer > 0 then
			self.acceptCancelTimer = self.acceptCancelTimer - dt
			if self.acceptCancelTimer <= 0 then
				print("Waited too long for accept ... cancelling entire process")
				self:cancelLoading(true)
				return
			end
		end
		self.loadingInfo:setText(g_i18n:getText("ui_waitingForAccept"))
	end
	if self.state == MPLoadingScreen.STATE_WAIT_FOR_MISSION then
		self:onReadyToStart()
	end
	if self.actionTimerCount >= 0 then
		self.actionTimerCount = self.actionTimerCount - 1
		if self.actionTimerCount < 0 then
			if self.doLoad then
				self.doLoad = false
				g_currentMission:onConnectionRequestAcceptedLoad(self.loadConnection)
			elseif self.preSimulateCount >= 0 then
				self.preSimulateCount = self.preSimulateCount - 1
				if self.preSimulateCount < 0 then
					simulatePhysics(false)
					self:onReadyToStart()
				else
					self.actionTimerCount = 0
					extraUpdatePhysics(g_currentMission.preSimulateTime / self.preSimulateSteps)
				end
			end
		end
	end
	if self.currentGameplayHints == nil then
		if g_gameplayHintManager:getIsLoaded() then
			local v32_ = g_gameplayHintManager:getRandomGameplayHint(MPLoadingScreen.NUM_GAMEPLAY_HINTS)
			if v32_ ~= nil then
				self.currentGameplayHints = v32_
				self.currentGameplayHint = 1
				self.hintStateBox:setPageCount(MPLoadingScreen.NUM_GAMEPLAY_HINTS)
				self:setGameplayHint(self.currentGameplayHints, self.currentGameplayHint)
			end
			self.gameplayHintTime = self.gameplayHintDuration
			self.gameplayHintText:setVisible(true)
		end
	else
		self.gameplayHintTime = self.gameplayHintTime - dt
		if self.gameplayHintTime <= 0 then
			self.gameplayHintTime = self.gameplayHintDuration
			self.currentGameplayHint = self.currentGameplayHint + 1
			if self.currentGameplayHint > #self.currentGameplayHints then
				self.currentGameplayHint = 1
			end
			self:setGameplayHint(self.currentGameplayHints, self.currentGameplayHint)
		end
	end
	if self.savegameLoadingDialogDelay > 0 then
		self.savegameLoadingDialogDelay = self.savegameLoadingDialogDelay - dt
		if self.savegameLoadingDialogDelay <= 0 then
			self.loadingDialog = g_gui:showDialog("InfoDialog")
			self.loadingDialog.target:setText(g_i18n:getText("ui_loadingSavegame"))
			self.loadingDialog.target:setButtonTexts(g_i18n:getText("button_cancel"))
			self.loadingDialog.target:setCallback(self.onCancelSavegameLoading, self)
		end
	end
end

function MPLoadingScreen:openWardrobe()
	g_wardrobeScreen:setNextOpenIsNewCharacter()
	g_gui:changeScreen(nil, WardrobeScreen)
end

function MPLoadingScreen:dlcProblemOnQuitOk()
	if g_gui:getIsGuiVisible() and g_gui.currentGuiName == "InfoDialog" then
		g_gui:showGui("MainScreen")
	end
end

-- Local values: savegame
function MPLoadingScreen:loadSavegameAndStart()
	local v34_ = self.missionInfo
	if v34_.isValid then
		self.savegameLoadingDialogDelay = MPLoadingScreen.SAVEGAME_LOADING_DIALOG_DELAY
		saveReadSavegameStart(v34_.savegameIndex, "onSavegameLoaded", self)
	else
		self:onSavegameLoaded(Savegame.ERROR_OK, nil)
	end
end

function MPLoadingScreen:loadGameRelatedData()
	g_asyncTaskManager:setAllowedTimePerFrame(33.333333333333336)
	g_asyncTaskManager:addTask(function()
		g_toolTypeManager:loadMapData()
	end)
	g_asyncTaskManager:addTask(function()
		g_splitShapeManager:loadMapData()
	end)
	g_asyncTaskManager:addTask(function()
		g_vehicleConfigurationManager:loadMapData()
	end)
	g_asyncTaskManager:addTask(function()
		g_placeableConfigurationManager:loadMapData()
	end)
	g_asyncTaskManager:addTask(function()
		g_specializationManager:loadMapData()
	end)
	g_asyncTaskManager:addTask(function()
		g_placeableSpecializationManager:loadMapData()
	end)
	g_asyncTaskManager:addTask(function()
		g_handToolSpecializationManager:loadMapData()
	end)
	g_asyncTaskManager:addTask(function()
		g_vehicleTypeManager:loadMapData()
	end)
	g_asyncTaskManager:addTask(function()
		g_placeableTypeManager:loadMapData()
	end)
	g_asyncTaskManager:addTask(function()
		g_handToolTypeManager:loadMapData()
	end)
	g_asyncTaskManager:addTask(function()
		g_constructionBrushTypeManager:loadMapData()
	end)
	g_asyncTaskManager:addTask(function()
		g_brandManager:loadMapData()
	end)
	g_asyncTaskManager:addTask(function()
		g_workAreaTypeManager:loadMapData()
	end)
end

function MPLoadingScreen:unloadGameRelatedData()
	g_specializationManager:unloadMapData()
	g_placeableSpecializationManager:unloadMapData()
	g_handToolSpecializationManager:unloadMapData()
	g_vehicleTypeManager:unloadMapData()
	g_placeableTypeManager:unloadMapData()
	g_handToolTypeManager:unloadMapData()
	g_constructionBrushTypeManager:unloadMapData()
	g_brandManager:unloadMapData()
	g_storeManager:unloadMapData()
	g_workAreaTypeManager:unloadMapData()
	g_vehicleConfigurationManager:unloadMapData()
	g_placeableConfigurationManager:unloadMapData()
	g_toolTypeManager:unloadMapData()
	g_splitShapeManager:unloadMapData()
	g_xmlManager:unloadMapData()
end

function MPLoadingScreen:startClient()
	self:loadGameRelatedData()
	resetSplitShapes()
	setTerrainLoadDirectory("", TerrainLoadFlags.GAME_DEFAULT)
	self.isClient = true
	self.isCancel = true
	Logging.info("Starting multiplayer client game...")
	self:setButtonState(MPLoadingScreen.STATE_CONNECTING)
	g_asyncTaskManager:addTask(function()
		-- upvalues: (copy) self
		g_client = Client.new()
		g_masterServerConnection:setCallbackTarget(self)
		masterServerRequestServerDetails(self.missionDynamicInfo.serverId)
	end)
end

function MPLoadingScreen:startLocal()
	Logging.info("Starting singleplayer game...")
	self.isClient = false
	self:setButtonState(MPLoadingScreen.STATE_LOADING)
	g_asyncTaskManager:addTask(function()
		g_server = Server.new()
		g_client = Client.new()
	end)
	self:initializeLoading()
end

function MPLoadingScreen:showPortTesting()
	self:setMapTitleAndPreview()
	self:setButtonState(MPLoadingScreen.STATE_PORT_TESTING)
	g_gui:showGui("MPLoadingScreen")
end

function MPLoadingScreen:startServer()
	Logging.info("Starting multiplayer server game %s ...", g_dedicatedServer == nil and "(Self-hosted)" or "(Dedicated Server)")
	self.isClient = false
	self:setButtonState(MPLoadingScreen.STATE_LOADING)
	self.serverName = self.missionDynamicInfo.serverName
	self.serverPassword = self.missionDynamicInfo.password
	self.capacity = self.missionDynamicInfo.capacity
	self.mods = self.missionDynamicInfo.mods
	g_asyncTaskManager:addTask(function()
		-- upvalues: (copy) self
		g_server = Server.new()
		g_client = Client.new()
		g_server:start(self.missionDynamicInfo.serverPort, self.missionDynamicInfo.serverAddress, self.missionDynamicInfo.capacity)
	end)
	g_connectToMasterServerScreen:setNextScreenClass(MPLoadingScreen)
	g_connectToMasterServerScreen:setPrevScreenClass(CreateGameScreen)
	g_gui:changeScreen(nil, ConnectToMasterServerScreen)
	g_asyncTaskManager:addTask(function()
		g_connectToMasterServerScreen:connectToFront()
	end)
end

function MPLoadingScreen:loadWithConnection(connection, knownPlayerOnServer)
	self:setButtonState(MPLoadingScreen.STATE_SYNCHRONIZING)
	self:hitLoadingTarget(self.currentTarget, false)
	self.actionTimerCount = 1
	self.doLoad = true
	self.loadConnection = connection
	self.knownPlayerOnServer = knownPlayerOnServer
end

function MPLoadingScreen:onWaitingForAccept()
	if self.isClient then
		self:setButtonState(MPLoadingScreen.STATE_WAIT_FOR_ACCEPT)
		self.acceptCancelTimer = 120000
	end
end

function MPLoadingScreen:onWaitingForDynamicData()
	self:setButtonState(MPLoadingScreen.STATE_LOADING)
end

function MPLoadingScreen:reloadAsNewSavegame()
	self.missionInfo:loadDefaults()
	g_careerScreen:startSavegame(self.missionInfo)
end

function MPLoadingScreen:onCancelSavegameLoading()
	self:cancelLoading()
	g_gui:changeScreen(nil, self.returnScreenClass or CareerScreen)
end

-- Local values: savegame
function MPLoadingScreen:onSavegameLoaded(errorCode, savegameDirectory)
	if self.savegameLoadingDialogDelay > 0 then
		self.savegameLoadingDialogDelay = -1
	end
	if self.loadingDialog ~= nil then
		self.loadingDialog.target:close()
	end
	if errorCode == Savegame.ERROR_OK then
		self:loadGameRelatedData()
		local v49_ = self.missionInfo
		if v49_.isValid then
			v49_:setSavegameDirectory(savegameDirectory)
		else
			v49_:setSavegameDirectory(nil)
		end
		if v49_.environmentXML == nil or not fileExists(v49_.environmentXML) then
			v49_.environmentXMLLoad = v49_.defaultEnvironmentXMLFilename
		else
			v49_.environmentXMLLoad = v49_.environmentXML
		end
		if v49_.vehiclesXML == nil or not fileExists(v49_.vehiclesXML) then
			v49_.vehiclesXMLLoad = v49_.defaultVehiclesXMLFilename
		else
			v49_.vehiclesXMLLoad = v49_.vehiclesXML
		end
		if v49_.handToolsXML == nil or not fileExists(v49_.handToolsXML) then
			v49_.handToolsXMLLoad = v49_.defaultHandToolsXMLFilename
		else
			v49_.handToolsXMLLoad = v49_.handToolsXML
		end
		if v49_.placeablesXML == nil or not fileExists(v49_.placeablesXML) then
			v49_.placeablesXMLLoad = v49_.defaultPlaceablesXMLFilename
		else
			v49_.placeablesXMLLoad = v49_.placeablesXML
		end
		if v49_.itemsXML == nil or not fileExists(v49_.itemsXML) then
			v49_.itemsXMLLoad = v49_.defaultItemsXMLFilename
		else
			v49_.itemsXMLLoad = v49_.itemsXML
		end
		if v49_.aiSystemXML == nil or not fileExists(v49_.aiSystemXML) then
			v49_.aiSystemXMLLoad = nil
		else
			v49_.aiSystemXMLLoad = v49_.aiSystemXML
		end
		if v49_.navigationSystemXML == nil or not fileExists(v49_.navigationSystemXML) then
			v49_.navigationSystemXMLLoad = nil
		else
			v49_.navigationSystemXMLLoad = v49_.navigationSystemXML
		end
		if v49_.onCreateObjectsXML == nil or not fileExists(v49_.onCreateObjectsXML) then
			v49_.onCreateObjectsXMLLoad = nil
		else
			v49_.onCreateObjectsXMLLoad = v49_.onCreateObjectsXML
		end
		if v49_.economyXML == nil or not fileExists(v49_.economyXML) then
			v49_.economyXMLLoad = nil
		else
			v49_.economyXMLLoad = v49_.economyXML
		end
		if v49_.farmlandXML == nil or not fileExists(v49_.farmlandXML) then
			v49_.farmlandXMLLoad = nil
		else
			v49_.farmlandXMLLoad = v49_.farmlandXML
		end
		if v49_.npcXML == nil or not fileExists(v49_.npcXML) then
			v49_.npcXMLLoad = nil
		else
			v49_.npcXMLLoad = v49_.npcXML
		end
		if v49_.missionsXML == nil or not fileExists(v49_.missionsXML) then
			v49_.missionsXMLLoad = nil
		else
			v49_.missionsXMLLoad = v49_.missionsXML
		end
		if v49_.farmsXML == nil or not fileExists(v49_.farmsXML) then
			v49_.farmsXMLLoad = nil
		else
			v49_.farmsXMLLoad = v49_.farmsXML
		end
		if v49_.guidedTourXML == nil or not fileExists(v49_.guidedTourXML) then
			v49_.guidedTourXMLLoad = nil
		else
			v49_.guidedTourXMLLoad = v49_.guidedTourXML
		end
		if v49_.playersXML == nil or not fileExists(v49_.playersXML) then
			v49_.playersXMLLoad = nil
		else
			v49_.playersXMLLoad = v49_.playersXML
		end
		if v49_.treeMarkerXML == nil or not fileExists(v49_.treeMarkerXML) then
			v49_.treeMarkerXMLLoad = nil
		else
			v49_.treeMarkerXMLLoad = v49_.treeMarkerXML
		end
		if v49_.destructibleMapObjectsXML == nil or not fileExists(v49_.destructibleMapObjectsXML) then
			v49_.destructibleMapObjectsXMLLoad = nil
		else
			v49_.destructibleMapObjectsXMLLoad = v49_.destructibleMapObjectsXML
		end
		if v49_.fieldsXML == nil or not fileExists(v49_.fieldsXML) then
			v49_.fieldsXMLLoad = nil
		else
			v49_.fieldsXMLLoad = v49_.fieldsXML
		end
		if v49_.densityMapHeightXML == nil or not fileExists(v49_.densityMapHeightXML) then
			v49_.densityMapHeightXMLLoad = nil
		else
			v49_.densityMapHeightXMLLoad = v49_.densityMapHeightXML
		end
		if v49_.treePlantXML == nil or not fileExists(v49_.treePlantXML) then
			v49_.treePlantXMLLoad = nil
		else
			v49_.treePlantXMLLoad = v49_.treePlantXML
		end
		if self.missionDynamicInfo.isMultiplayer then
			self:startServer()
		else
			self:startLocal()
		end
	else
		if errorCode == Savegame.ERROR_DATA_CORRUPT then
			if g_gui:getIsGuiVisible() and g_gui.currentGuiName == "MPLoadingScreen" then
				YesNoDialog.show(self.onYesNoSavegameCorrupted, self, g_i18n:getText("ui_savegameCorrupt"), nil, g_i18n:getText("button_continue"), g_i18n:getText("button_cancel"))
				return
			end
		elseif errorCode == Savegame.ERROR_LOAD_INVALID_USER then
			if g_gui:getIsGuiVisible() and g_gui.currentGuiName == "MPLoadingScreen" then
				YesNoDialog.show(self.onYesNoSavegameCorrupted, self, g_i18n:getText("ui_savegameInvalidUser"), nil, g_i18n:getText("button_continue"), g_i18n:getText("button_cancel"))
				return
			end
		elseif errorCode == Savegame.ERROR_CLOUD_CONFLICT then
			if g_gui:getIsGuiVisible() and g_gui.currentGuiName == "MPLoadingScreen" then
				InfoDialog.show(g_i18n:getText("ui_savegameLoadCloudConflict"), self.onOkSavegameCloudConflict, self)
				return
			end
		elseif errorCode == Savegame.ERROR_CANCELLED then
			if g_gui:getIsGuiVisible() and g_gui.currentGuiName == "MPLoadingScreen" then
				self:cancelLoading()
			end
		elseif g_gui:getIsGuiVisible() and g_gui.currentGuiName == "MPLoadingScreen" then
			InfoDialog.show(g_i18n:getText("ui_savegameLoadFailed"), self.onOkSavegameLoadFailed, self)
			return
		end
		return
	end
end

-- Local values: text, callback, target, yesText, noText
function MPLoadingScreen:onSaveGameLoadingFinished(errorCode)
	if errorCode == Savegame.ERROR_OK then
		if g_currentMission:getIsServer() then
			g_messageCenter:publish(MessageType.SAVEGAME_LOADED)
			if g_currentMission.preSimulateTime > 0 then
				simulatePhysics(true)
				extraUpdatePhysics(g_currentMission.preSimulateTime / self.preSimulateSteps)
				self.actionTimerCount = 1
				self.preSimulateCount = self.preSimulateSteps - 1
			else
				self:onReadyToStart()
			end
		else
			self:onReadyToStart()
			return
		end
	else
		if errorCode == Savegame.ERROR_DATA_CORRUPT then
			if g_gui:getIsGuiVisible() and g_gui.currentGuiName == "MPLoadingScreen" then
				local v52_ = g_i18n:getText("ui_savegameCorrupt")
				local v53_ = self.onYesNoSavegameCorrupted
				local v54_ = g_i18n:getText("button_continue")
				local v55_ = g_i18n:getText("button_cancel")
				YesNoDialog.show(v53_, self, v52_, nil, v54_, v55_)
				return
			end
		elseif errorCode == Savegame.ERROR_LOAD_INVALID_USER then
			if g_gui:getIsGuiVisible() and g_gui.currentGuiName == "MPLoadingScreen" then
				YesNoDialog.show(self.onYesNoSavegameCorrupted, self, g_i18n:getText("ui_savegameInvalidUser"), nil, g_i18n:getText("button_continue"), g_i18n:getText("button_cancel"))
				return
			end
		elseif errorCode == Savegame.ERROR_CANCELLED then
			if g_gui:getIsGuiVisible() and g_gui.currentGuiName == "MPLoadingScreen" then
				self:cancelLoading()
			end
		elseif g_gui:getIsGuiVisible() and g_gui.currentGuiName == "MPLoadingScreen" then
			InfoDialog.show(g_i18n:getText("ui_savegameLoadFailed"), self.onOkSavegameLoadFailed, self)
			return
		end
		return
	end
end

function MPLoadingScreen:onOkSavegameLoadFailed()
	self:cancelLoading()
end

function MPLoadingScreen:onOkSavegameCloudConflict()
	self:cancelLoading()
	g_gui:changeScreen(nil, self.returnScreenClass or CareerScreen)
	g_savegameController:tryToResolveConflict(self.missionInfo.savegameIndex)
end

function MPLoadingScreen:onYesNoSavegameCorrupted(yes)
	if yes then
		self:cancelLoading()
		g_gui:showGui("MPLoadingScreen")
		self:reloadAsNewSavegame()
	else
		self:cancelLoading()
	end
end

function MPLoadingScreen:onFinishedReceivingDynamicData()
	if self.missionInfo.isValid then
		g_asyncTaskManager:addTask(function()
			-- upvalues: (copy) self
			saveReadSavegameFinish("onSaveGameLoadingFinished", self)
		end)
	else
		self:onSaveGameLoadingFinished(Savegame.ERROR_OK)
	end
end

-- Local values: numRemainingShaders, numPendingObjects
function MPLoadingScreen:onReadyToStart()
	local v62_ = getRemainingShadersToWarmup()
	local v63_ = self:getNumPendingObjects()
	if g_currentMission:canStartMission() and (v62_ == 0 and v63_ == 0) then
		setIs3DAudioRenderingEnabled(true)
		setIs3DGraphicsRenderingEnabled(true)
		self.mpLoadingAnimation:setVisible(false)
		self.mpLoadingAnimationDone:setVisible(true)
		self.isCancel = false
		self:setButtonState(MPLoadingScreen.STATE_READY)
		self:hitLoadingTarget(MPLoadingScreen.LOAD_TARGETS.FINISHED)
		if g_dedicatedServer ~= nil or (Platform.autoStartAfterLoad or (Profiler.IS_INITIALIZED or StartParams.getIsSet("autoStart"))) then
			self:onClickOk()
			return
		end
	else
		self:setButtonState(MPLoadingScreen.STATE_WAIT_FOR_MISSION)
	end
end

function MPLoadingScreen:initializeLoading()
	g_gameStateManager:setGameState(GameState.LOADING)
	self:setMapTitleAndPreview()
	Object.resetObjectIds()
	g_asyncTaskManager:addTask(function()
		-- upvalues: (copy) self
		if self.missionInfo:isa(FSCareerMissionInfo) then
			InitClientOnce()
			masterServerConnectFront = nil
			masterServerConnectBack = nil
			masterServerAddServer = nil
			masterServerAddServerModStart = nil
			masterServerAddServerMod = nil
			masterServerAddServerModEnd = nil
			masterServerRequestConnectionToServer = nil
			netConnect = nil
			if #self.missionDynamicInfo.mods > 0 then
				if self.missionInfo.map.prohibitOtherMods and not g_isDevelopmentVersion then
					local v65_ = g_mapManager:getModNameFromMapId(self.missionInfo.mapId)
					local v66_ = { (g_modManager:getModByName(v65_)) }
					self.missionDynamicInfo.mods = v66_
				else
					table.sort(self.missionDynamicInfo.mods, MPLoadingScreen.modSortFunc)
				end
				local v67_ = false
				for _, v68_ in ipairs(self.missionDynamicInfo.mods) do
					if not (v67_ or (v68_.isDLC or v68_.isFreeDLC)) then
						setReflectionMapCustomCamera = nil
						v67_ = true
					end
					loadMod(v68_.modName, v68_.modDir, v68_.modFile, v68_.title)
				end
			end
		end
	end)
	g_asyncTaskManager:addTask(function()
		g_xmlManager:createSchemas()
	end)
	g_asyncTaskManager:addTask(function()
		g_xmlManager:initSchemas()
	end)
	g_asyncTaskManager:addTask(function()
		-- upvalues: (copy) self
		g_vehicleTypeManager:validateTypes()
		self:hitLoadingTarget(MPLoadingScreen.LOAD_TARGETS.VEHICLE_VALIDATION)
	end)
	g_asyncTaskManager:addTask(function()
		g_vehicleTypeManager:finalizeTypes()
	end)
	g_asyncTaskManager:addTask(function()
		g_placeableTypeManager:validateTypes()
	end)
	g_asyncTaskManager:addTask(function()
		g_placeableTypeManager:finalizeTypes()
	end)
	g_asyncTaskManager:addTask(function()
		g_handToolTypeManager:validateTypes()
	end)
	g_asyncTaskManager:addTask(function()
		g_handToolTypeManager:finalizeTypes()
	end)
	g_asyncTaskManager:addTask(function()
		Vehicle.init()
	end)
	g_asyncTaskManager:addTask(function()
		Placeable.init()
	end)
	g_asyncTaskManager:addTask(function()
		HandTool.init()
	end)
	g_asyncTaskManager:addTask(function()
		g_specializationManager:initSpecializations()
	end)
	g_asyncTaskManager:addTask(function()
		g_placeableSpecializationManager:initSpecializations()
	end)
	g_asyncTaskManager:addTask(function()
		g_handToolSpecializationManager:initSpecializations()
	end)
	g_asyncTaskManager:addTask(function()
		Vehicle.postInit()
	end)
	g_asyncTaskManager:addTask(function()
		Placeable.postInit()
	end)
	g_asyncTaskManager:addTask(function()
		HandTool.postInit()
	end)
	g_asyncTaskManager:addTask(function()
		g_specializationManager:postInitSpecializations()
	end)
	g_asyncTaskManager:addTask(function()
		g_placeableSpecializationManager:postInitSpecializations()
	end)
	g_asyncTaskManager:addTask(function()
		g_handToolSpecializationManager:postInitSpecializations()
	end)
	g_asyncTaskManager:addTask(function()
		-- upvalues: (copy) self
		self:hitLoadingTarget(MPLoadingScreen.LOAD_TARGETS.SPECIALIZATIONS)
	end)
	g_asyncTaskManager:addTask(function()
		g_xmlManager:initSchemas()
	end)
	g_asyncTaskManager:addTask(function()
		g_constructionBrushTypeManager:initBrushTypes()
	end)
	setIs3DAudioRenderingEnabled(false)
	setIs3DGraphicsRenderingEnabled(false)
	self.loadFunction(self.missionInfo, self.missionDynamicInfo, self)
end

-- Local values: mapName, balanceText, playTimeText, mapPreview, name, map
function MPLoadingScreen:setMapTitleAndPreview()
	local v70_ = ""
	local v71_ = ""
	local v72_ = ""
	local v73_ = self.mapSelectionPreview.overlay.filename
	if self.missionInfo ~= nil then
		local v74_ = self.gameTitle or self.missionInfo.savegameName
		self.savegameTitle:setText(v74_)
		if self.missionInfo.name then
			local v75_ = self.missionInfo.name
			v70_ = tostring(v75_)
		end
		if self.missionDynamicInfo.isClient then
			self.balanceText:setVisible(false)
			self.playTimeText:setVisible(false)
			self.balanceSeparator:setVisible(false)
			self.playTimeSeparator:setVisible(false)
		else
			v71_ = g_i18n:formatMoney(self.missionInfo.money or self.missionInfo.initialMoney)
			v72_ = g_i18n:formatMinutes(self.missionInfo.playTime)
		end
		local v76_ = g_mapManager:getMapById(self.missionInfo.mapId)
		if v76_ ~= nil then
			v73_ = v76_.iconFilename
			if self.missionInfo:isa(FSCareerMissionInfo) then
				v70_ = v76_.title
			end
		end
	end
	self.mapSelectionPreview:setImageFilename(v73_)
	self.mapNameText:setText(v70_)
	self.balanceText:setText(v71_)
	self.playTimeText:setText(v72_)
	self.infoLayout:invalidateLayout()
end

-- Local values: missingMods, numMissingsMods, i, modItem, parts, text, i, modItem
function MPLoadingScreen:onServerInfoDetails(id, name, language, capacity, numPlayers, mapName, mapId, hasPassword, isLanServer, modTitles, modHashes, allowCrossPlay, platformId, password)
	if id ~= self.missionDynamicInfo.serverId then
		local v83_ = Logging.warning
		local v84_ = tostring(id)
		local v85_ = tostring(name)
		local v86_ = self.missionDynamicInfo.serverId
		v83_("Invalid server id \'%s\' for server \'%s\'. Requested server id \'%s\'!", v84_, v85_, (tostring(v86_)))
		g_deepLinkingInfo = nil
		self:showFailedToConnectDialog()
		return
	end
	local v87_ = ""
	local v88_ = 0
	for v89_ = 1, #modHashes do
		if g_modManager:getModByFileHash(modHashes[v89_]) == nil then
			local v90_ = modTitles[v89_]:split(";")
			if v87_:len() ~= 0 then
				v87_ = v87_ .. ", "
			end
			v87_ = v87_ .. v90_[1]
			v88_ = v88_ + 1
			if v88_ >= 4 then
				break
			end
		end
	end
	if v88_ > 0 then
		local v91_ = g_i18n:getText("ui_notAllModsAvailable") .. "\n" .. v87_
		g_deepLinkingInfo = nil
		self:showFailedToConnectDialog(v91_)
		return
	elseif self.missionInfo:setMapId(mapId) then
		self.missionDynamicInfo.mods = {}
		for v92_ = 1, #modHashes do
			local v93_ = g_modManager:getModByFileHash(modHashes[v92_])
			local v94_ = self.missionDynamicInfo.mods
			table.insert(v94_, v93_)
		end
		g_deepLinkingInfo = nil
		self.gameTitle = name
		self:setMapTitleAndPreview()
		masterServerRequestConnectionToServer(self.missionDynamicInfo.password, id, "onNatPunchSuceeded", "onNatPunchFailed", self)
	else
		g_deepLinkingInfo = nil
		self:showFailedToConnectDialog()
	end
end

function MPLoadingScreen:showFailedToConnectDialog(text)
	ConnectionFailedDialog.show(text or g_i18n:getText("ui_failedToConnectToGame"), g_connectionFailedDialog.onOkCallback, g_connectionFailedDialog, { "JoinGameScreen" })
	self:cleanup()
end

function MPLoadingScreen:onServerInfoDetailsFailed(reason)
	g_deepLinkingInfo = nil
	self:showFailedToConnectDialog()
end

function MPLoadingScreen:onNatPunchSuceeded(ip, port, platformSessionId, relayHeader)
	print("nat punch suceeded")
	self.missionDynamicInfo.serverAddress = ip
	self.missionDynamicInfo.serverPort = port
	self.missionDynamicInfo.platformSessionId = platformSessionId
	self.missionDynamicInfo.relayHeader = relayHeader
	self:initializeLoading()
end

function MPLoadingScreen:onNatPunchFailed(reason)
	ConnectionFailedDialog.showMasterServerConnectionFailedReason(reason, "JoinGameScreen")
	self:cleanup()
end

-- Local values: i, modItem, modTitleStr, map
function MPLoadingScreen:onMasterServerConnectionReady()
	if self.missionDynamicInfo.isClient then
		masterServerRequestConnectionToServer(self.missionDynamicInfo.password, self.missionDynamicInfo.serverId, "onNatPunchSuceeded", "onNatPunchFailed", self)
	else
		g_masterServerConnection:setCallbackTarget(self)
		log("STARTING MP Game")
		masterServerAddServerModStart()
		for v106_ = 1, #self.missionDynamicInfo.mods do
			local v107_ = self.missionDynamicInfo.mods[v106_]
			local v108_ = v107_.fileHash ~= nil
			assert(v108_)
			local v109_ = ServerDetailScreen.packModInfo(v107_.title, v107_.version, v107_.author, v107_.modName)
			log("    adding mod", v109_, v107_.fileHash)
			masterServerAddServerMod(v109_, v107_.fileHash)
		end
		masterServerAddServerModEnd()
		local v110_ = g_mapManager:getMapById(self.missionInfo.mapId)
		masterServerAddServer(self.missionDynamicInfo.serverName, self.missionDynamicInfo.password, self.missionDynamicInfo.capacity, 0, v110_.title, self.missionInfo.mapId, self.missionDynamicInfo.allowOnlyFriends, g_createGameScreen.usePendingInvites, self.missionDynamicInfo.allowCrossPlay)
		self:initializeLoading()
	end
end

-- Local values: nextScreen
function MPLoadingScreen:onMasterServerConnectionFailed(reason)
	local v113_ = g_currentMission == nil
	assert(v113_)
	saveReadSavegameFinish("", self)
	self:cleanup()
	local v114_ = self.isClient and "MultiplayerScreen" or "CreateGameScreen"
	ConnectionFailedDialog.showMasterServerConnectionFailedReason(reason, v114_)
end

function MPLoadingScreen:cleanup()
	self:unloadGameRelatedData()
	g_masterServerConnection:disconnectFromMasterServer()
	g_asyncTaskManager:flushAllTasks()
	g_asyncTaskManager:flushAllTasks()
	if g_client ~= nil then
		g_client:delete()
		g_client = nil
	end
	if g_server == nil then
		g_connectionManager:shutdownAll()
	else
		g_server:delete()
		g_server = nil
	end
end

function MPLoadingScreen:setMissionInfo(missionInfo, missionDynamicInfo)
	self.missionInfo = missionInfo
	self.missionDynamicInfo = missionDynamicInfo
	self.preSimulateCount = -1
	self.doLoad = false
end

-- Local values: text
function MPLoadingScreen:setGameplayHint(currentGameplayHints, id)
	if currentGameplayHints[id] ~= nil then
		local v122_ = string.gsub(currentGameplayHints[id], "$CURRENCY_SYMBOL", g_i18n:getCurrencySymbol(true))
		self.gameplayHintText:setText(v122_)
		self.hintStateBox:setPageIndex(id)
	end
end

-- Local values: isDlc1, isDlc2
function MPLoadingScreen.modSortFunc(mod1, mod2)
	local v125_ = mod1.isDLC or mod1.isFreeDLC
	if v125_ == (mod2.isDLC or mod2.isFreeDLC) then
		return string.lower(mod1.modName) < string.lower(mod2.modName)
	else
		return v125_ and true or false
	end
end

-- Local values: isStartButtonVisible, isCancelButtonVisible
function MPLoadingScreen:setButtonState(state)
	self.state = state
	local v128_ = false
	local v129_ = false
	if self.state == MPLoadingScreen.STATE_CONNECTING then
		v129_ = true
	elseif self.state == MPLoadingScreen.STATE_LOADING then
		if self.missionDynamicInfo.isMultiplayer and self.isClient then
			v129_ = true
		end
	elseif self.state == MPLoadingScreen.STATE_READY then
		FocusManager:setFocus(self.buttonOkPC)
		v128_ = true
	elseif self.state == MPLoadingScreen.STATE_PORT_TESTING then
		v129_ = true
	elseif self.state == MPLoadingScreen.STATE_SYNCHRONIZING or self.state == MPLoadingScreen.STATE_LOADING then
		if self.missionDynamicInfo.isMultiplayer and self.isClient then
			v129_ = true
		end
	elseif self.state == MPLoadingScreen.STATE_WAIT_FOR_ACCEPT then
		v129_ = true
	end
	self.buttonOkPC:setVisible(v128_)
	self.buttonDeletePC:setVisible(v129_)
end

-- Local values: numPendingVehicles, numPendingPlaceables, numPendingHandTools
function MPLoadingScreen:getNumPendingObjects()
	if g_currentMission == nil then
		return 0
	end
	local v130_ = g_currentMission.vehicleSystem:getNumPendingVehicles()
	local v131_ = g_currentMission.placeableSystem:getNumPendingPlaceables()
	local v132_ = g_currentMission.handToolSystem:getNumPendingHandTools()
	return v130_ + v131_ + v132_
end

function MPLoadingScreen:onEnqueuedAllLoadings()
	self.totalPendingObjects = self:getNumPendingObjects()
end

-- Local values: targetData, text
function MPLoadingScreen:hitLoadingTarget(target, updatePercentage)
	self.currentTarget = target
	local v137_ = MPLoadingScreen.LOAD_TARGET_DATA[target]
	if v137_ ~= nil then
		if updatePercentage == nil or updatePercentage then
			self.loadPercentage = v137_.percentage or self.loadPercentage
		end
		local v138_ = v137_.nextStepText
		if Platform.isConsole then
			v138_ = v137_.nextStepTextConsole or v138_
		end
		if self.missionDynamicInfo.isMultiplayer then
			v138_ = v137_.nextStepTextMultiplayer or v138_
		end
		self.loadingInfo:setText(v138_ == nil and "" or (g_i18n:getText(v138_) or ""))
	end
	if target == MPLoadingScreen.LOAD_TARGETS.VEHICLES then
		self.numRemainingShaders = getRemainingShadersToWarmup()
	end
end
