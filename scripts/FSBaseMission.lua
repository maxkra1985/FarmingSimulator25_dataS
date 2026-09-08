-- Local values: l_engineState, l_engineStateTimer, onEngineStateCallback, FSBaseMission_mt
FSBaseMission = {}
FSBaseMission.USER_STATE_LOADING = 1
FSBaseMission.USER_STATE_SYNCHRONIZING = 2
FSBaseMission.USER_STATE_CONNECTED = 3
FSBaseMission.USER_STATE_INGAME = 4
FSBaseMission.CONNECTION_LOST_DEFAULT = 0
FSBaseMission.CONNECTION_LOST_KICKED = 1
FSBaseMission.CONNECTION_LOST_BANNED = 2
FSBaseMission.LIMITED_OBJECT_TYPE_BALE = 1
FSBaseMission.INGAME_NOTIFICATION_OK = {
	0.305,
	0.521,
	0.0356,
	1
}
FSBaseMission.INGAME_NOTIFICATION_INFO = {
	1,
	1,
	1,
	1
}
FSBaseMission.INGAME_NOTIFICATION_GREATDEMAND = {
	1,
	1,
	1,
	1
}
FSBaseMission.INGAME_NOTIFICATION_CRITICAL = {
	1,
	0.305,
	0,
	1
}
FSBaseMission.RECORDING_DEVICE_CHECK_INTERVAL = 2500
local l_engineState = math.random(900000, 1200000)
local l_engineStateTimer
if getEngineState == nil then
	l_engineStateTimer = true
else
	l_engineStateTimer = getEngineState()
	getEngineState = nil
end
local function v_u_3_()
	openWebFile(Platform.urlBuyNow, "")
end
source("dataS/scripts/events/SavegameSettingsEvent.lua")
source("dataS/scripts/events/BaseMissionFinishedLoadingEvent.lua")
source("dataS/scripts/events/BaseMissionReadyEvent.lua")
source("dataS/scripts/events/SetSplitShapesEvent.lua")
source("dataS/scripts/events/UpdateSplitShapesEvent.lua")
source("dataS/scripts/events/ConnectionRequestEvent.lua")
source("dataS/scripts/events/ConnectionRequestAnswerEvent.lua")
source("dataS/scripts/events/ChangeLoanEvent.lua")
source("dataS/scripts/events/GamePauseEvent.lua")
source("dataS/scripts/events/GamePauseRequestEvent.lua")
source("dataS/scripts/events/PlayerPermissionsEvent.lua")
source("dataS/scripts/events/FinanceStatsEvent.lua")
local v_u_4_ = Class(FSBaseMission, BaseMission)

-- Upvalues: FSBaseMission_mt
-- Local values: self
function FSBaseMission.new(baseDirectory, customMt)
	-- upvalues: (copy) v_u_4_
	local v7_ = FSBaseMission:superClass().new(baseDirectory, customMt or v_u_4_)
	g_inGameMenu:setClient(g_client)
	g_inGameMenu:setServer(g_server)
	g_shopMenu:setClient(g_client)
	g_shopMenu:setServer(g_server)
	v7_.trainSystems = {}
	v7_.objectsToCallOnMapFinished = {}
	v7_:registerToLoadOnMapFinished(g_inGameMenu)
	v7_:registerToLoadOnMapFinished(g_shopMenu)
	v7_.mapDensityMapRevision = 1
	v7_.mapTerrainTextureRevision = 1
	v7_.mapTerrainLodTextureRevision = 1
	v7_.mapSplitShapesRevision = 1
	v7_.mapTipCollisionRevision = 1
	v7_.mapPlacementCollisionRevision = 1
	v7_.mapNavigationCollisionRevision = 1
	v7_.densityMapSyncer = nil
	v7_.fieldGroundSystem = FieldGroundSystem.new()
	v7_.stoneSystem = StoneSystem.new()
	v7_.weedSystem = WeedSystem.new()
	v7_.playersToAccept = {}
	v7_.playersLoading = {}
	v7_.doSaveGameState = SavegameController.SAVE_STATE_NONE
	v7_.currentDeviceHasNoSpace = false
	v7_.dediEmptyPaused = false
	v7_.userSigninPaused = false
	v7_.isSynchronizingWithPlayers = false
	v7_.playersSynchronizing = {}
	v7_.isServerSaving = false
	v7_.userManager = UserManager.new(v7_:getIsServer())
	v7_.aiSystem = AISystem.new(v7_:getIsServer(), v7_)
	v7_.aiJobTypeManager = AIJobTypeManager.new(v7_:getIsServer())
	v7_.aiMessageManager = AIMessageManager.new()
	v7_.animalSystem = AnimalSystem.new(v7_:getIsServer(), v7_)
	v7_.animalFoodSystem = AnimalFoodSystem.new(v7_)
	v7_.animalNameSystem = AnimalNameSystem.new(v7_)
	v7_.husbandrySystem = HusbandrySystem.new(v7_:getIsServer(), v7_)
	v7_.navigationSystem = NavigationSystem.new()
	v7_.vineSystem = VineSystem.new(v7_:getIsServer(), v7_)
	v7_.vehicleSaleSystem = VehicleSaleSystem.new(v7_)
	v7_.collectiblesSystem = CollectiblesSystem.new(v7_:getIsServer())
	v7_.indoorMask = IndoorMask.new(v7_, v7_:getIsServer())
	v7_.snowSystem = SnowSystem.new(v7_, v7_:getIsServer())
	v7_.growthSystem = GrowthSystem.new(v7_, v7_:getIsServer())
	v7_.foliageSystem = FoliageSystem.new()
	v7_.slotSystem = SlotSystem.new(v7_, v7_:getIsServer())
	v7_.economyManager = EconomyManager.new()
	v7_.treeMarkerSystem = TreeMarkerSystem.new(v7_:getIsServer())
	v7_.destructibleMapObjectSystem = DestructibleMapObjectSystem.new(v7_, v7_:getIsServer())
	v7_.shipSystem = ShipSystem.new()
	v7_.playerUserId = -1
	v7_.playerNickname = g_gameSettings:getValue(GameSettings.SETTING.ONLINE_PRESENCE_NAME)
	v7_.clientUserId = nil
	v7_.terrainSize = 1
	v7_.terrainDetailMapSize = 1
	v7_.fruitMapSize = 1
	v7_.dynamicFoliageLayers = {}
	v7_.terrainDetailId = 0
	v7_.mapsSplitShapeFileIds = {}
	v7_.isMasterUser = false
	v7_.connectionWasClosed = false
	v7_.connectionWasAccepted = false
	v7_.checkRecordingDeviceTimer = 0
	v7_.lastRecordingDeviceState = not Platform.hasRecordingDeviceDetection
	v7_.lastConstructionScreenOpenTime = -1
	v7_.cameraPaths = {}
	v7_.cullingWorldXZOffset = 0
	v7_.cullingWorldMinY = -100
	v7_.cullingWorldMaxY = 500
	v7_.cullingClipDistanceThreshold1 = 150
	v7_.cullingClipDistanceThreshold2 = 400
	v7_.densityMapPercentageFraction = 0.7
	v7_.splitShapesPercentageFraction = 0.2
	v7_.restPercentageFraction = 1 - v7_.densityMapPercentageFraction - v7_.splitShapesPercentageFraction
	v7_.doghouses = {}
	v7_.tireTrackSystem = nil
	v7_.liquidManureLoadingStations = {}
	v7_.manureLoadingStations = {}
	v7_.connectedToDedicatedServer = false
	v7_.wasNetworkError = false
	v7_.ambientSoundSystem = AmbientSoundSystem.new(g_soundPlayer)
	v7_.environmentAreaSystem = EnvironmentAreaSystem.new()
	v7_.reverbSystem = ReverbSystem.new(v7_)
	v7_.radioEvents = {}
	v7_.moneyChanges = {}
	v7_.introductionHelpSystem = IntroductionHelpSystem.new()
	if v7_:getIsServer() and StartParams.getIsSet("debugCameraClone") then
		v7_.debugCameraClone = DebugCameraClone.new(true, true)
		v7_.debugCameraClone:register(false)
	end
	return v7_
end

function FSBaseMission:initialize()
	FSBaseMission:superClass().initialize(self)
	g_treePlantManager:initialize()
	MoneyType.reset()
	self.foliageBendingSystem = nil
	if Platform.supportsFoliageBending then
		self.foliageBendingSystem = FoliageBendingSystem.new()
	end
	self.accessHandler = AccessHandler.new()
	self.storageSystem = StorageSystem.new(self.accessHandler)
	self:subscribeMessages()
	g_inGameMenu:setInGameMap(self.hud:getIngameMap())
	g_inGameMenu:setHUD(self.hud)
	self.productionChainManager = ProductionChainManager.new(self:getIsServer())
end

-- Local values: _, v
function FSBaseMission:delete()
	self.isExitingGame = true
	g_inGameMenu:reset()
	self:pauseRadio()
	if self.missionDynamicInfo ~= nil and self.missionDynamicInfo.isMultiplayer then
		voiceChatCleanup()
	end
	if self.mapOverlayGenerator ~= nil then
		self.mapOverlayGenerator:delete()
	end
	if self.receivingDensityMapEvent ~= nil then
		self.receivingDensityMapEvent:delete()
		self.receivingDensityMapEvent = nil
	end
	if self.receivingSplitShapesEvent ~= nil then
		self.receivingSplitShapesEvent:delete()
		self.receivingSplitShapesEvent = nil
	end
	if self.densityMapSyncer ~= nil then
		self.densityMapSyncer:delete()
	end
	if self.terrainDeformationSyncer ~= nil then
		self.terrainDeformationSyncer:delete()
		self.terrainDeformationSyncer = nil
	end
	destroyLowResCollisionHandler()
	if self.accessHandler ~= nil then
		self.accessHandler:delete()
	end
	if self.storageSystem ~= nil then
		self.storageSystem:delete()
	end
	if self.playerSystem ~= nil then
		self.playerSystem:delete()
	end
	if self.debugCameraClone ~= nil then
		self.debugCameraClone:delete()
	end
	if g_dedicatedServer ~= nil then
		g_dedicatedServer:delete()
	end
	self.growthSystem:delete()
	self.snowSystem:delete()
	self.indoorMask:delete()
	self.collectiblesSystem:delete()
	self.vehicleSaleSystem:delete()
	self.reverbSystem:delete()
	self.environmentAreaSystem:delete()
	self.ambientSoundSystem:delete()
	self.aiSystem:delete()
	self.husbandrySystem:delete()
	self.animalFoodSystem:delete()
	self.animalNameSystem:delete()
	self.animalSystem:delete()
	self.fieldGroundSystem:delete()
	self.stoneSystem:delete()
	self.weedSystem:delete()
	self.vineSystem:delete()
	self.foliageSystem:delete()
	self.slotSystem:delete()
	self.aiJobTypeManager:delete()
	self.aiMessageManager:delete()
	self.introductionHelpSystem:delete()
	self.navigationSystem:delete()
	self.treeMarkerSystem:delete()
	self.destructibleMapObjectSystem:delete()
	g_guidedTourManager:unloadMapData()
	g_farmManager:unloadMapData()
	g_helperManager:unloadMapData()
	g_npcManager:unloadMapData()
	g_farmlandManager:unloadMapData()
	g_missionManager:unloadMapData()
	g_fieldManager:unloadMapData()
	g_gameplayHintManager:unloadMapData()
	g_sprayTypeManager:unloadMapData()
	g_connectionHoseManager:unloadMapData()
	g_consumableManager:unloadMapData()
	g_densityMapHeightManager:unloadMapData()
	g_vehicleTypeManager:unloadMapData()
	g_placeableTypeManager:unloadMapData()
	g_constructionBrushTypeManager:unloadMapData()
	g_specializationManager:unloadMapData()
	g_placeableSpecializationManager:unloadMapData()
	g_treePlantManager:unloadMapData()
	g_materialManager:unloadMapData()
	g_particleSystemManager:unloadMapData()
	g_motionPathEffectManager:unloadMapData()
	g_effectManager:unloadMapData()
	g_animationManager:unloadMapData()
	g_tensionBeltManager:unloadMapData()
	g_groundTypeManager:unloadMapData()
	g_gui:unloadMapData()
	g_xmlManager:unloadMapData()
	g_debugManager:unloadMapData()
	g_noteManager:unloadMapData()
	g_fieldCourseManager:unloadMapData()
	FSBaseMission:superClass().delete(self)
	if AIFieldWorker ~= nil then
		AIFieldWorker.deleteCollisionBox()
	end
	g_shopMenu:reset()
	FSDensityMapUtil.clearCache()
	DensityMapHeightUtil.clearCache()
	g_fillTypeManager:unloadMapData()
	g_fruitTypeManager:unloadMapData()
	g_baleManager:unloadMapData()
	g_vehicleMaterialManager:unloadMapData()
	g_licensePlateManager:unloadMapData()
	g_helpLineManager:unloadMapData()
	g_storeManager:unloadMapData()
	g_workAreaTypeManager:unloadMapData()
	g_vehicleConfigurationManager:unloadMapData()
	g_placeableConfigurationManager:unloadMapData()
	g_toolTypeManager:unloadMapData()
	g_splitShapeManager:unloadMapData()
	g_brandManager:unloadMapData()
	g_sleepManager:unloadMapData()
	if g_dedicatedServer == nil then
		g_wildlifeManager:unloadMapData()
	end
	if self.productionChainManager ~= nil then
		self.productionChainManager:unloadMapData()
	end
	if self.tireTrackSystem ~= nil then
		self.tireTrackSystem:delete()
	end
	if self.foliageBendingSystem ~= nil then
		self.foliageBendingSystem:delete()
	end
	if self.economyManager ~= nil then
		self.economyManager:delete()
		self.economyManager = nil
	end
	if self.shipSystem ~= nil then
		self.shipSystem:delete()
		self.shipSystem = nil
	end
	if g_soundPlayer ~= nil then
		g_soundPlayer:removeEventListener(self)
		if not (GS_IS_CONSOLE_VERSION or GS_IS_MOBILE_VERSION) then
			g_soundPlayer:setStreamingAccessOwner(nil)
		end
	end
	removeConsoleCommand("gsMoneyAdd")
	removeConsoleCommand("gsStoreItemsExport")
	removeConsoleCommand("gsGreatDemandStart")
	removeConsoleCommand("gsTeleport")
	removeConsoleCommand("gsSaveGame")
	removeConsoleCommand("gsActivateCameraPath")
	removeConsoleCommand("gsDisplacementDebug")
	removeConsoleCommand("gsDisplacementReset")
	removeConsoleCommand("gsUnloadTriggersValidate")
	removeConsoleCommand("gsPhysicsStressTest")
	for _, v10_ in pairs(self.cameraPaths) do
		v10_:delete()
	end
	g_gui:setClient(nil)
	g_gui:setServer(nil)
	g_inGameMenu:setInGameMap(nil)
	g_inGameMenu:setHUD(nil)
	g_inGameMenu:setPlayerFarm(nil)
	g_shopMenu:setPlayerFarm(nil)
	self.userManager:delete()
end

function FSBaseMission:load()
	self:startLoadingTask()
	if self:getIsServer() and g_addTestCommands then
		addConsoleCommand("gsStoreItemsExport", "Exports storeItem data", "consoleCommandExportStoreItems", self)
		addConsoleCommand("gsGreatDemandStart", "Starts a great demand", "consoleStartGreatDemand", self)
		addConsoleCommand("gsSaveGame", "Saves the current savegame", "consoleCommandSaveGame", self)
		addConsoleCommand("gsDisplacementDebug", "Opens the displacement debug dialog", "consoleCommandDisplacementDebug", self)
		addConsoleCommand("gsDisplacementReset", "Resets the displacement", "consoleCommandDisplacementReset", self)
		addConsoleCommand("gsUnloadTriggersValidate", "Validate the height of unload triggers to detect if they are below the terrain", "consoleCommandValidateUnloadTriggers", self)
		addConsoleCommand("gsRunFSDensityMapUtilBenchmark", "Runs a benchmark on FS Density Map Util", "consoleCommandRunDSDensityMapUtil", self)
		addConsoleCommand("gsPhysicsStressTest", "Starts spawning random physic objects", "consoleCommandTogglePhysicsStressTest", self)
	end
	if g_isDevelopmentVersion then
		addConsoleCommand("gsActivateCameraPath", "Activate camera path", "consoleActivateCameraPath", self)
	end
	if self:getIsServer() and g_addCheatCommands or g_isDevelopmentVersion then
		addConsoleCommand("gsTeleport", "Teleports to given field or x/z-position", "consoleCommandTeleport", self, "farmlandId or xPos; [zPos]; [useWorldCoords]")
	end
	self.economyManager:init(self)
	FSBaseMission:superClass().load(self)
	g_inGameMenu:setTerrainSize(self.terrainSize)
	local v12_ = Platform.gameplay.harvestScaleRation
	self:setHarvestScaleRatio(unpack(v12_))
	self:finishLoadingTask()
end

function FSBaseMission:setHarvestScaleRatio(sprayRatio, plowRatio, limeRatio, weedRatio, stubbleRatio, rollerRatio)
	self.harvestSprayScaleRatio = sprayRatio
	self.harvestPlowScaleRatio = plowRatio
	self.harvestLimeScaleRatio = limeRatio
	self.harvestWeedScaleRatio = weedRatio
	self.harvestStubbleScaleRatio = stubbleRatio
	self.harvestRollerRatio = rollerRatio
end

-- Local values: multiplier
function FSBaseMission:getHarvestScaleMultiplier(fruitTypeIndex, sprayFactor, plowFactor, limeFactor, weedFactor, stubbleFactor, rollerFactor, beeYieldBonusPercentage)
	return 1 + self.harvestSprayScaleRatio * sprayFactor + self.harvestPlowScaleRatio * plowFactor + self.harvestLimeScaleRatio * limeFactor + self.harvestWeedScaleRatio * weedFactor + self.harvestStubbleScaleRatio * stubbleFactor + self.harvestRollerRatio * rollerFactor + (beeYieldBonusPercentage or 0)
end

-- Local values: connection, user, farm, farmId
function FSBaseMission:onStartMission()
	FSBaseMission:superClass().onStartMission(self)
	g_asyncTaskManager:setAllowedTimePerFrame(nil)
	if g_client ~= nil then
		if self:getIsServer() then
			local v29_ = g_server.clientConnections[NetworkNode.LOCAL_STREAM_ID]
			local v30_ = self.userManager:getUserByConnection(v29_)
			local v31_ = g_farmManager:getFarmByUserId(v30_:getId())
			local v32_ = FarmManager.SPECTATOR_FARM_ID
			if v31_ ~= nil then
				v32_ = v31_.farmId
			end
			Player.createServerInstance(true, true, v29_, v30_:getId(), v32_, self.userManager)
			v30_:setState(FSBaseMission.USER_STATE_INGAME)
		else
			g_client:getServerConnection():sendEvent(ClientStartMissionEvent.new())
		end
		if g_dedicatedServer == nil and Platform.hasAdjustableFrameLimit then
			setFramerateLimiter(true, g_gameSettings:getValue(SettingsModel.SETTING.FRAME_LIMIT))
		end
		if not g_gameSettings:getValue(GameSettings.SETTING.RADIO_VEHICLE_ONLY) then
			self:playRadio()
		end
		g_soundMixer:setAudioGroupVolumeFactor(AudioGroup.RADIO, g_gameSettings:getValue(GameSettings.SETTING.VOLUME_RADIO))
		g_soundMixer:setAudioGroupVolumeFactor(AudioGroup.VEHICLE, g_gameSettings:getValue(GameSettings.SETTING.VOLUME_VEHICLE))
		g_soundMixer:setAudioGroupVolumeFactor(AudioGroup.ENVIRONMENT, g_gameSettings:getValue(GameSettings.SETTING.VOLUME_ENVIRONMENT))
		g_soundMixer:setAudioGroupVolumeFactor(AudioGroup.GUI, g_gameSettings:getValue(GameSettings.SETTING.VOLUME_GUI))
		g_soundMixer:setAudioGroupVolumeFactor(AudioGroup.CHARACTER, g_gameSettings:getValue(GameSettings.SETTING.VOLUME_CHARACTER))
	end
	if self.missionInfo ~= nil then
		Logging.info("Savegame Setting \'dirtInterval\': %d", self.missionInfo.dirtInterval)
		Logging.info("Savegame Setting \'snowEnabled\': %s", self.missionInfo.isSnowEnabled)
		Logging.info("Savegame Setting \'trafficEnabled\': %s", self.missionInfo.trafficEnabled)
		Logging.info("Savegame Setting \'growthMode\': %s", GrowthMode.getName(self.missionInfo.growthMode))
		Logging.info("Savegame Setting \'fuelUsage\': %d", self.missionInfo.fuelUsage)
		Logging.info("Savegame Setting \'plowingRequiredEnabled\': %s", self.missionInfo.plowingRequiredEnabled)
		Logging.info("Savegame Setting \'weedsEnabled\': %s", self.missionInfo.weedsEnabled)
		Logging.info("Savegame Setting \'limeRequired\': %s", self.missionInfo.limeRequired)
		Logging.info("Savegame Setting \'stonesEnabled\': %s", self.missionInfo.stonesEnabled)
		Logging.info("Savegame Setting \'economicDifficulty\': %s", EconomicDifficulty.getName(self.missionInfo.economicDifficulty))
		Logging.info("Savegame Setting \'fixedSeasonalVisuals\': %s", self.missionInfo.fixedSeasonalVisuals)
		Logging.info("Savegame Setting \'plannedDaysPerPeriod\': %s", self.missionInfo.plannedDaysPerPeriod)
		if self:getIsServer() then
			self.pendingSavegameDateAchievement = true
		end
		self.introductionHelpSystem:loadHelpElementsFromXML()
		self.introductionHelpSystem:loadShownElements()
	end
	if g_dedicatedServer ~= nil then
		g_dedicatedServer:onStartMission(self)
	end
	if self.helpIconsBase ~= nil then
		self.helpIconsBase:showHelpIcons(g_gameSettings:getValue(GameSettings.SETTING.SHOW_HELP_ICONS))
	end
	self:notifyPlayerFarmChanged(g_localPlayer)
	if self.missionDynamicInfo.isMultiplayer and g_dedicatedServer == nil then
		voiceChatAddLocalUser(self:getIsServer())
	end
	self.slotSystem:updateSlotUsage()
end

function FSBaseMission:getClientPosition()
	return getWorldTranslation(g_cameraManager:getActiveCamera())
end

function FSBaseMission:getClientGuiVisibility()
	return g_gui:getIsGuiVisible()
end

function FSBaseMission:setLoadingScreen(loadingScreen)
	self.loadingScreen = loadingScreen
end

function FSBaseMission:onConnectionOpened(connection) end

-- Local values: mpLanguage, playerName
function FSBaseMission:onConnectionAccepted(connection)
	self.connectionWasAccepted = true
	if self.loadingScreen ~= nil then
		self.loadingScreen:onWaitingForAccept()
	end
	local v36_ = g_gameSettings:getValue(GameSettings.SETTING.MP_LANGUAGE)
	local v37_ = g_gameSettings:getValue(GameSettings.SETTING.ONLINE_PRESENCE_NAME)
	g_client:getServerConnection():sendEvent(ConnectionRequestEvent.new(v36_, self.missionDynamicInfo.password, getUniqueUserId(), getUserId(), getPlatformId(), v37_, self.missionDynamicInfo.platformSessionId), nil, true)
end

-- Local values: userCount, user, keyAlreadyInUse, _, playerToAccept, oldConnection, userId, user, knownPlayer
function FSBaseMission:onConnectionRequest(connection, languageIndex, password, uniqueUserId, platformUserId, platformId, playerName, platformSessionId)
	if connection.streamId == NetworkNode.LOCAL_STREAM_ID then
		local v47_ = self.userManager:getNextUserId()
		local v48_ = v47_ == 1
		assert(v48_)
		self.playerUserId = 1
		local v49_ = User.new()
		v49_:setId(v47_)
		v49_:setConnection(connection)
		v49_:setUniqueUserId(uniqueUserId)
		v49_:setPlatformUserId(platformUserId)
		v49_:setPlatformId(platformId)
		v49_:setIsMasterUser(true)
		v49_:setLanguageIndex(languageIndex)
		v49_:setConnectedTime(self.time)
		v49_:setState(FSBaseMission.USER_STATE_CONNECTED)
		v49_:setNickname(playerName)
		self.playerNickname = playerName
		local v50_ = self.playerSystem:getHasPlayerWithUniqueId(uniqueUserId)
		self.userManager:addUser(v49_)
		self.userManager:addMasterUserByConnection(connection)
		self:sendNumPlayersToMasterServer(1)
		connection:sendEvent(ConnectionRequestAnswerEvent.new(ConnectionRequestAnswerEvent.ANSWER_OK, self.missionInfo.economicDifficulty, self.missionInfo.timeScale, g_dedicatedServer ~= nil, self.playerUserId, playerName, v50_), nil, true)
		self.slotSystem:updateSlotLimit()
		return
	end
	local v51_ = self.userManager:getNumberOfUsers()
	if g_dedicatedServer ~= nil then
		v51_ = v51_ - 1
	end
	if v51_ + #self.playersToAccept >= self.missionDynamicInfo.capacity then
		connection:sendEvent(ConnectionRequestAnswerEvent.new(ConnectionRequestAnswerEvent.ANSWER_FULL), nil, true)
		g_server:closeConnection(connection)
		return
	end
	if getIsUserBlocked(uniqueUserId, platformUserId, platformId) then
		connection:sendEvent(ConnectionRequestAnswerEvent.new(ConnectionRequestAnswerEvent.ANSWER_ALWAYS_DENIED), nil, true)
		g_server:closeConnection(connection)
		return
	end
	local v52_ = self.userManager:getUserByUniqueId(uniqueUserId)
	local v53_ = v52_ ~= nil
	if not v53_ then
		for _, v54_ in ipairs(self.playersToAccept) do
			if v54_.uniqueUserId == uniqueUserId then
				v53_ = true
				break
			end
		end
	end
	if v53_ then
		if not Platform.isConsole then
			connection:sendEvent(ConnectionRequestAnswerEvent.new(ConnectionRequestAnswerEvent.ALREADY_IN_USE), nil, true)
			g_server:closeConnection(connection)
			return
		end
		local v55_ = v52_:getConnection()
		if v55_:getIsServer() then
			connection:sendEvent(ConnectionRequestAnswerEvent.new(ConnectionRequestAnswerEvent.ALREADY_IN_USE), nil, true)
			g_server:closeConnection(connection)
			return
		end
		g_server:closeConnection(v55_)
	end
	if self.slotSystem:getCanConnect(uniqueUserId, platformId) then
		if self.missionDynamicInfo.password == password then
			local v56_ = self.playersToAccept
			table.insert(v56_, {
				["connection"] = connection,
				["playerName"] = playerName,
				["language"] = languageIndex,
				["platformUserId"] = platformUserId,
				["platformId"] = platformId,
				["uniqueUserId"] = uniqueUserId,
				["platformSessionId"] = platformSessionId
			})
		else
			connection:sendEvent(ConnectionRequestAnswerEvent.new(ConnectionRequestAnswerEvent.ANSWER_WRONG_PASSWORD), nil, true)
			g_server:closeConnection(connection)
		end
	else
		connection:sendEvent(ConnectionRequestAnswerEvent.new(ConnectionRequestAnswerEvent.SLOT_LIMIT_REACHED), nil, true)
		g_server:closeConnection(connection)
		return
	end
end

-- Local values: name, filteredName, newNickname, existingUser, index
function FSBaseMission:canPlayerChangeNickname(player, nickname)
	if utf8Strlen(nickname) < 3 then
		return false
	end
	local v60_ = string.trim(nickname)
	if v60_ ~= filterText(v60_, true, true) then
		return false
	end
	local v61_ = self.userManager:getUserByNickname(nickname, true)
	local v62_ = nickname
	local v63_ = 1
	while v61_ ~= nil and v61_.id ~= player.userId do
		nickname = v62_ .. " (" .. v63_ .. ")"
		v61_ = self.userManager:getUserByNickname(nickname, true)
		v63_ = v63_ + 1
	end
	return true, nickname
end

-- Local values: allowed, user, farm, user
function FSBaseMission:setPlayerNickname(player, nickname, userId, noEventSend)
	if self:getIsServer() then
		local v69_, v70_ = self:canPlayerChangeNickname(player, nickname)
		if v69_ then
			local v71_ = self.userManager:getUserByUserId(player.userId)
			v71_:setNickname(v70_)
			if g_localPlayer == player then
				self.playerNickname = v70_
			end
			g_messageCenter:publish(MessageType.PLAYER_NICKNAME_CHANGED, player)
			local v72_ = g_farmManager:getFarmByUserId(player.userId)
			if v72_ ~= nil then
				v72_:updateLastNickname(player.userId, v71_)
			end
			if noEventSend == nil or noEventSend == false then
				g_server:broadcastEvent(PlayerSetNicknameEvent.new(player, v70_, player.userId), false, nil, player)
				return
			end
		end
	else
		if noEventSend == nil or noEventSend == false then
			g_client:getServerConnection():sendEvent(PlayerSetNicknameEvent.new(player, nickname, player.userId))
			return
		end
		if noEventSend == true then
			local v73_ = self.userManager:getUserByUserId(userId)
			if v73_ ~= nil then
				v73_:setNickname(nickname)
			end
			if g_localPlayer == player then
				self.playerNickname = nickname
			end
			g_messageCenter:publish(MessageType.PLAYER_NICKNAME_CHANGED, player)
		end
	end
end

-- Local values: playerToAccept, i, p, playerName, user, knownPlayer, answer, languageIndex, uniqueUserId, platformUserId, platformId, platformSessionId, newNickname, index, existingUser, financeUpdateSendTime, playerFarm, userId
function FSBaseMission:onConnectionDenyAccept(connection, isDenied, isAlwaysDenied)
	local v78_ = nil
	for v79_ = 1, #self.playersToAccept do
		local v80_ = self.playersToAccept[v79_]
		if v80_.connection == connection then
			table.remove(self.playersToAccept, v79_)
			v78_ = v80_
			break
		end
	end
	if v78_ == nil then
		return
	else
		local v81_ = ""
		local v82_ = nil
		local v83_ = false
		local v84_ = ConnectionRequestAnswerEvent.ANSWER_OK
		if isAlwaysDenied then
			setIsUserBlocked(v78_.uniqueUserId, v78_.platformUserId, v78_.platformId, true, v78_.playerName)
			g_messageCenter:publish(MessageType.BLOCK_LIST_CHANGED)
			v84_ = ConnectionRequestAnswerEvent.ANSWER_ALWAYS_DENIED
		elseif isDenied then
			v84_ = ConnectionRequestAnswerEvent.ANSWER_DENIED
		else
			v81_ = v78_.playerName
			local v85_ = v78_.language
			local v86_ = v78_.uniqueUserId
			local v87_ = v78_.platformUserId
			local v88_ = v78_.platformId
			local v89_ = v78_.platformSessionId
			v83_ = self.playerSystem:getHasPlayerWithUniqueId(v86_)
			local v90_ = self.userManager:getUserByNickname(v81_, true)
			local v91_ = v81_
			local v92_ = 1
			while v90_ ~= nil do
				v81_ = v91_ .. " (" .. v92_ .. ")"
				v90_ = self.userManager:getUserByNickname(v81_, true)
				v92_ = v92_ + 1
			end
			local v93_ = self.time
			local v94_ = math.random() * 300 + 400
			local v95_ = v93_ + math.floor(v94_)
			v82_ = User.new()
			v82_:setId(self.userManager:getNextUserId())
			v82_:setNickname(v81_)
			v82_:setConnection(connection)
			v82_:setUniqueUserId(v86_)
			v82_:setPlatformUserId(v87_)
			v82_:setPlatformId(v88_)
			v82_:setPlatformSessionId(v89_)
			v82_:setLanguageIndex(v85_)
			v82_:setConnectedTime(self.time)
			v82_:setState(FSBaseMission.USER_STATE_LOADING)
			v82_:setFinanceUpdateSendTime(v95_)
			self.userManager:addUser(v82_)
			self:sendNumPlayersToMasterServer(self.userManager:getNumberOfUsers())
			self:sendPlatformSessionIdsToMasterServer(self.userManager:getAllPlatformSessionIds())
			voiceChatAddConnection(connection.streamId, v78_.uniqueUserId, v78_.platformUserId, v78_.platformId)
			self.playersLoading[connection] = {
				["connection"] = connection,
				["user"] = v82_
			}
			self.slotSystem:updateSlotLimit()
		end
		local v96_ = g_farmManager:getFarmForUniqueUserId(v78_.uniqueUserId)
		local v97_
		if v82_ == nil then
			v97_ = nil
		else
			v97_ = v82_:getId() or nil
		end
		connection:sendEvent(ConnectionRequestAnswerEvent.new(v84_, self.missionInfo.economicDifficulty, self.missionInfo.timeScale, g_dedicatedServer ~= nil, v97_, v81_, v83_), nil, true)
		if v84_ == ConnectionRequestAnswerEvent.ANSWER_OK then
			Player.createServerInstance(g_client ~= nil, false, connection, v82_:getId(), v96_.farmId, self.userManager)
		else
			g_server:closeConnection(connection)
		end
	end
end

-- Local values: text
function FSBaseMission:onConnectionRequestAnswer(connection, answer, economicDifficulty, timeScale, connectedToDedicatedServer, clientUserId, playerName, knownPlayer)
	if answer == ConnectionRequestAnswerEvent.ANSWER_OK then
		self.missionInfo.economicDifficulty = economicDifficulty
		self.missionInfo.timeScale = timeScale
		self.connectedToDedicatedServer = connectedToDedicatedServer
		self:onConnectionRequestAccepted(connection, knownPlayer)
		self.playerUserId = clientUserId
		self.playerNickname = playerName
	else
		self.connectionWasClosed = true
		local v107_ = g_i18n:getText("ui_serverDeniedAccess")
		if answer == ConnectionRequestAnswerEvent.ANSWER_WRONG_PASSWORD then
			v107_ = g_i18n:getText("ui_wrongPassword")
		elseif answer == ConnectionRequestAnswerEvent.ANSWER_ALWAYS_DENIED then
			v107_ = g_i18n:getText("ui_banned")
		elseif answer == ConnectionRequestAnswerEvent.ANSWER_FULL then
			v107_ = g_i18n:getText("ui_gameFull")
		elseif answer == ConnectionRequestAnswerEvent.ALREADY_IN_USE then
			v107_ = g_i18n:getText("ui_connectionLostKeyInUse")
		elseif answer == ConnectionRequestAnswerEvent.SLOT_LIMIT_REACHED then
			v107_ = g_i18n:getText("ui_serverDeniedSlotLimitReached")
		elseif answer == ConnectionRequestAnswerEvent.MATCH_IN_PROGRESS then
			v107_ = g_i18n:getText("ui_serverDeniedMatchInProgress")
		end
		InfoDialog.show(v107_, self.onConnectionRequestAnswerOk, self)
	end
end

function FSBaseMission:onConnectionRequestAnswerOk()
	OnInGameMenuMenu()
	if masterServerConnectFront ~= nil then
		g_multiplayerScreen:initJoinGameScreen()
		g_gui:showGui("ConnectToMasterServerScreen")
		if g_masterServerConnection.lastBackServerIndex >= 0 then
			g_connectToMasterServerScreen:connectToBack(g_masterServerConnection.lastBackServerIndex)
			return
		end
		g_connectToMasterServerScreen:connectToFront()
	end
end

function FSBaseMission:onConnectionRequestAccepted(connection, knownPlayer)
	if self.loadingScreen ~= nil then
		self.loadingScreen:loadWithConnection(connection, knownPlayer)
	end
end

function FSBaseMission:onConnectionRequestAcceptedLoad(connection)
	self.loadingConnection = connection
	simulatePhysics(false)
	self:load()
end

-- Local values: connection, x, y, z
function FSBaseMission:onFinishedLoading()
	FSBaseMission:superClass().onFinishedLoading(self)
	self.lastPlayTimeSampleTime = g_time
	if self.missionDynamicInfo.isMultiplayer and not g_gameSettings:getValue(GameSettings.SETTING.PLAYED_MULTIPLAYER) then
		g_gameSettings:setValue(GameSettings.SETTING.PLAYED_MULTIPLAYER, true, true)
	end
	local v114_ = self.loadingConnection
	if self:getIsServer() then
		self.pressStartPaused = true
		self:pauseGame()
		if self.loadingScreen ~= nil then
			self.loadingScreen:onFinishedReceivingDynamicData()
		end
	else
		g_cameraManager:setDefaultCamera()
		local v115_, v116_, v117_ = self:getClientPosition()
		if self.loadingScreen ~= nil then
			self.loadingScreen:onWaitingForDynamicData()
		end
		self.pressStartPaused = true
		self:pauseGame()
		v114_:sendEvent(BaseMissionFinishedLoadingEvent.new(v115_, v116_, v117_, getViewDistanceCoeff()), nil, true)
	end
end

function FSBaseMission:getAllowsGuiDisplay()
	if self.isSynchronizingWithPlayers and g_localPlayer ~= nil then
		return false
	else
		return not g_sleepManager:getIsSleeping()
	end
end

-- Local values: user, syncPlayer, farm, splitShapesEvent
function FSBaseMission:onConnectionFinishedLoading(connection, x, y, z, viewDistanceCoeff)
	local v125_ = not connection:getIsLocal()
	assert(v125_, "No local connection allowed in BaseMission:onConnectionFinishedLoading")
	if self.playersSynchronizing[connection] == nil and self.playersLoading[connection] ~= nil then
		local v126_ = self.playersLoading[connection].user
		self.playersLoading[connection] = nil
		addSplitShapeConnection(connection.streamId, v126_:getPlatformId())
		if self.densityMapSyncer ~= nil then
			self.densityMapSyncer:addConnection(connection.streamId)
		end
		addTerrainUpdateConnection(g_terrainNode, connection.streamId)
		connection:setIsReadyForEvents(true)
		v126_:setState(FSBaseMission.USER_STATE_SYNCHRONIZING)
		local v127_ = {
			["connection"] = connection,
			["user"] = v126_
		}
		self.playersSynchronizing[connection] = v127_
		if g_dedicatedServer ~= nil then
			g_dedicatedServer:raiseFramerate()
			self.dediEmptyPaused = false
		end
		self.isSynchronizingWithPlayers = true
		self:pauseGame()
		g_farmManager:playerJoinedGame(v126_:getUniqueUserId(), v126_:getId(), v126_, connection)
		g_server:sendEventIds(connection)
		g_server:sendObjectClassIds(connection)
		connection:sendEvent(OnCreateLoadedObjectEvent.new())
		connection:sendEvent(PlaceablePreplacedInfoEvent.new())
		g_server:sendObjects(connection, x, y, z, viewDistanceCoeff)
		connection:sendEvent(SavegameSettingsEvent.new())
		connection:sendEvent(SlotSystemUpdateEvent.new(self.slotSystem.slotLimit))
		self:sendInitialClientState(connection, v126_, (g_farmManager:getFarmForUniqueUserId(v126_:getUniqueUserId())))
		g_server:broadcastEvent(UserEvent.new(self.userManager:getUsers(), {}, self.missionDynamicInfo.capacity))
		local v128_ = SetSplitShapesEvent.new()
		v127_.splitShapesEvent = v128_
		connection:sendEvent(v128_, false)
	else
		g_server:closeConnection(connection)
	end
end

-- Local values: weather, i
function FSBaseMission:sendInitialClientState(connection, user, farm)
	connection:sendEvent(EnvironmentTimeEvent.new(self.environment.currentMonotonicDay, self.environment.currentDay, self.environment.dayTime, self.environment.daysPerPeriod))
	self.environment.weather:sendInitialState(connection)
	connection:sendEvent(FarmsInitialStateEvent.new(farm.farmId))
	if farm.farmId ~= 0 then
		connection:sendEvent(ChangeLoanEvent.new(farm.loan, farm.farmId))
		for v133_ = 0, 4 do
			connection:sendEvent(FinanceStatsEvent.new(v133_, farm.farmId))
		end
		user:setFinancesVersionCounter(farm.stats.financesVersionCounter)
	end
	connection:sendEvent(FarmlandInitialStateEvent.new())
	connection:sendEvent(GreatDemandsEvent.new(self.economyManager.greatDemands))
	connection:sendEvent(PricingHistoryInitialEvent.new())
	self.vehicleSaleSystem:sendAllToClient(connection)
	self.collectiblesSystem:onClientJoined(connection)
	self.aiSystem:onClientJoined(connection)
	self.destructibleMapObjectSystem:onClientJoined(connection)
	self.treeMarkerSystem:onClientJoined(connection)
end

-- Local values: syncPlayer
function FSBaseMission:onSplitShapesProgress(connection, percentage)
	if percentage >= 1 and self:getIsServer() then
		local v137_ = self.playersSynchronizing[connection]
		if v137_ ~= nil then
			if v137_.splitShapesEvent ~= nil then
				v137_.splitShapesEvent:delete()
				v137_.splitShapesEvent = nil
			end
			connection:sendEvent(BaseMissionReadyEvent.new(), nil, true)
		end
	end
end

function FSBaseMission:onFinishedReceivingDynamicData(connection)
	if self.loadingScreen ~= nil then
		self.loadingScreen:onFinishedReceivingDynamicData()
		connection:sendEvent(BaseMissionReadyEvent.new(), nil, true)
	end
end

-- Local values: syncPlayer, user
function FSBaseMission:onConnectionReady(connection)
	local v142_ = self.playersSynchronizing[connection]
	if v142_ == nil then
		g_server:closeConnection(connection)
	else
		if v142_.densityMapEvent ~= nil then
			v142_.densityMapEvent:delete()
			v142_.densityMapEvent = nil
		end
		if v142_.splitShapesEvent ~= nil then
			v142_.splitShapesEvent:delete()
			v142_.splitShapesEvent = nil
		end
		connection:setIsReadyForObjects(true)
		v142_.user:setState(FSBaseMission.USER_STATE_CONNECTED)
		self.playersSynchronizing[connection] = nil
		if next(self.playersSynchronizing) == nil then
			self.isSynchronizingWithPlayers = false
			self:tryUnpauseGame()
			self:showPauseDisplay(self.paused)
		end
	end
end

-- Local values: text, i, user, syncPlayer, player, userCount
function FSBaseMission:onConnectionClosed(connection, disconnectReason)
	if self:getIsServer() then
		removeSplitShapeConnection(connection.streamId)
		if self.densityMapSyncer ~= nil then
			self.densityMapSyncer:removeConnection(connection.streamId)
		end
		removeTerrainUpdateConnection(g_terrainNode, connection.streamId)
		for v146_ = 1, #self.playersToAccept do
			if self.playersToAccept[v146_].connection == connection then
				table.remove(self.playersToAccept, v146_)
				break
			end
		end
		self.playersLoading[connection] = nil
		local v147_ = self.userManager:getUserByConnection(connection)
		if v147_ ~= nil then
			g_farmManager:playerQuitGame(v147_:getId())
		end
		self.userManager:removeUserByConnection(connection, disconnectReason)
		voiceChatRemoveConnection(connection.streamId)
		local v148_ = self.playersSynchronizing[connection]
		if v148_ ~= nil then
			if v148_.densityMapEvent ~= nil then
				v148_.densityMapEvent:delete()
			end
			if v148_.splitShapesEvent ~= nil then
				v148_.splitShapesEvent:delete()
			end
			self.playersSynchronizing[connection] = nil
			if next(self.playersSynchronizing) == nil then
				self.isSynchronizingWithPlayers = false
				self:tryUnpauseGame()
				self:showPauseDisplay(self.paused)
			end
		end
		if self.connectionsToPlayer[connection] ~= nil then
			self.connectionsToPlayer[connection]:delete()
			self.connectionsToPlayer[connection] = nil
		end
		local v149_ = self.userManager:getNumberOfUsers()
		self:sendNumPlayersToMasterServer(v149_)
		self:sendPlatformSessionIdsToMasterServer(self.userManager:getAllPlatformSessionIds())
		g_server:broadcastEvent(UserEvent.new({}, { v147_ }, self.missionDynamicInfo.capacity, disconnectReason))
		self.slotSystem:updateSlotLimit()
		if v149_ == 1 and g_dedicatedServer ~= nil then
			g_dedicatedServer:lowerFramerate()
			if g_dedicatedServer.pauseGameIfEmpty then
				self.dediEmptyPaused = true
				self:pauseGame()
			end
		end
	else
		if self.receivingDensityMapEvent ~= nil then
			self.receivingDensityMapEvent:delete()
			self.receivingDensityMapEvent = nil
		end
		if self.receivingSplitShapesEvent ~= nil then
			self.receivingSplitShapesEvent:delete()
			self.receivingSplitShapesEvent = nil
		end
		self:pauseGame()
		if not self.connectionWasClosed then
			self.isSynchronizingWithPlayers = false
			self.connectionWasClosed = true
			setPresenceMode(PresenceModes.PRESENCE_IDLE)
			if self.cleanServerShutDown == nil or not self.cleanServerShutDown then
				local v150_ = g_i18n:getText("ui_failedToConnectToGame")
				if self.connectionWasAccepted then
					if self.connectionLostState == FSBaseMission.CONNECTION_LOST_KICKED then
						v150_ = g_i18n:getText("ui_connectionLostKicked")
					elseif self.connectionLostState == FSBaseMission.CONNECTION_LOST_BANNED then
						v150_ = g_i18n:getText("ui_connectionLostBanned")
					else
						v150_ = g_i18n:getText("ui_connectionLost")
					end
				end
				if g_gui:getIsGuiVisible() and g_gui.currentGuiName == "ChatDialog" then
					g_gui:showGui("")
				end
				InfoDialog.show(v150_, OnInGameMenuMenu)
			end
			self.cleanServerShutDown = false
			self.connectionLostState = nil
			return
		end
	end
end

-- Local values: connection, _
function FSBaseMission:cancelPlayersSynchronizing()
	for v152_, _ in pairs(self.playersSynchronizing) do
		g_server:closeConnection(v152_)
	end
end

-- Local values: streamId, connection
function FSBaseMission:onConnectionsUpdateTick(dt)
	if self:getIsServer() and #g_server.clients > 0 then
		prepareSplitShapesServerWriteUpdateStream(dt)
		if startWriteSplitShapesServerEvents() then
			for v155_, v156_ in pairs(g_server.clientConnections) do
				if v155_ ~= NetworkNode.LOCAL_STREAM_ID then
					v156_:sendEvent(UpdateSplitShapesEvent.new())
				end
			end
			finishWriteSplitShapesServerEvents()
		end
	end
end

-- Local values: treePacketPercentage, densityPacketPercentage, terrainDeformPacketPercentage, maxTreePacketSize, densityMaxPacketSize, terrainDeformMaxPacketSize, x, y, z, viewCoeff, splitShapeStreamOffsetStart, splitShapeStreamOffsetEnd, splitShapePacketSize, remainingPacketSize, densityPacketSize, terrainPacketSize, voiceChatStreamOffsetStart, voiceChatStreamOffsetEnd, voiceChatPacketSize
function FSBaseMission:onConnectionWriteUpdateStream(connection, maxPacketSize, networkDebug)
	if not connection:getIsServer() then
		streamWriteBool(connection.streamId, g_savegameController:getIsSaving())
		local v161_ = maxPacketSize * 0.3
		local v162_ = maxPacketSize * 0.2
		local v163_ = maxPacketSize * 0.2
		local v164_, v165_, v166_ = g_server:getClientPosition(connection.streamId)
		local v167_ = g_server:getClientClipDistCoeff(connection.streamId)
		local v168_ = streamGetWriteOffset(connection.streamId)
		if networkDebug then
			streamWriteInt32(connection.streamId, 0)
		end
		writeSplitShapesServerUpdateToStream(connection.streamId, connection.streamId, v164_, v165_, v166_, v167_, v161_)
		local v169_ = streamGetWriteOffset(connection.streamId)
		local v170_ = v169_ - v168_
		local v171_ = v161_ - v170_
		local v172_ = math.max(v171_, 0)
		g_server:addPacketSize(connection, NetworkNode.PACKET_SPLITSHAPES, v170_ / 8)
		if networkDebug then
			streamSetWriteOffset(connection.streamId, v168_)
			streamWriteInt32(connection.streamId, v169_ - (v168_ + 32))
			streamSetWriteOffset(connection.streamId, v169_)
		end
		if self.densityMapSyncer ~= nil then
			local v173_ = v162_ + v172_
			local v174_ = v173_ - self.densityMapSyncer:writeUpdateStream(connection, v173_, v164_, v165_, v166_, v167_, networkDebug)
			v172_ = math.max(v174_, 0)
		end
		if self.terrainDeformationSyncer ~= nil then
			local v175_ = v163_ + v172_
			local v176_ = v175_ - self.terrainDeformationSyncer:writeUpdateStream(connection, v175_, v164_, v165_, v166_, v167_, networkDebug)
			math.max(v176_, 0)
		end
		local v177_ = streamGetWriteOffset(connection.streamId)
		if networkDebug then
			streamWriteInt32(connection.streamId, 0)
		end
		voiceChatWriteServerUpdateToStream(connection.streamId, connection.streamId, connection.lastSeqSent)
		local v178_ = streamGetWriteOffset(connection.streamId)
		local v179_ = v178_ - v177_
		g_server:addPacketSize(connection, NetworkNode.PACKET_VOICE_CHAT, v179_ / 8)
		if networkDebug then
			streamSetWriteOffset(connection.streamId, v177_)
			streamWriteInt32(connection.streamId, v178_ - (v177_ + 32))
			streamSetWriteOffset(connection.streamId, v178_)
		end
	end
end

-- Local values: startOffset, numBits
function FSBaseMission:onConnectionReadUpdateStream(connection, networkDebug)
	if connection:getIsServer() then
		self.isServerSaving = streamReadBool(connection.streamId)
		local v183_, v184_
		if networkDebug then
			v183_ = streamGetReadOffset(connection.streamId)
			v184_ = streamReadInt32(connection.streamId)
		else
			v184_ = 0
			v183_ = 0
		end
		readSplitShapesServerUpdateFromStream(connection.streamId, g_clientInterpDelay, g_packetPhysicsNetworkTime, g_client.tickDuration)
		if networkDebug then
			g_client:checkObjectUpdateDebugReadSize(connection.streamId, v184_, v183_, "splitshape")
		end
		if self.densityMapSyncer ~= nil then
			self.densityMapSyncer:readUpdateStream(connection, networkDebug)
		end
		if self.terrainDeformationSyncer ~= nil then
			self.terrainDeformationSyncer:readUpdateStream(connection, networkDebug)
		end
		local v185_, v186_
		if networkDebug then
			v185_ = streamGetReadOffset(connection.streamId)
			v186_ = streamReadInt32(connection.streamId)
		else
			v186_ = 0
			v185_ = 0
		end
		voiceChatReadServerUpdateFromStream(connection.streamId, g_clientInterpDelay, connection.lastSeqSent)
		if networkDebug then
			g_client:checkObjectUpdateDebugReadSize(connection.streamId, v186_, v185_, "voicechat")
		end
	end
end

function FSBaseMission:onFinishedClientsWriteUpdateStream() end

function FSBaseMission:onConnectionPacketSent(connection, packetId)
	voiceChatNotifyPacketSent(packetId)
end

function FSBaseMission:onConnectionPacketLost(connection, packetId)
	voiceChatNotifyPacketLost(packetId)
	if not connection:getIsServer() and self.densityMapSyncer ~= nil then
		self.densityMapSyncer:onPacketLost(connection, packetId)
	end
end

-- Local values: user
function FSBaseMission:onShutdownEvent(connection)
	if self:getIsServer() then
		local v193_ = self.userManager:getUserByConnection(connection)
		self.userManager:removeUserByConnection(connection)
		voiceChatRemoveConnection(connection.streamId)
		self:sendNumPlayersToMasterServer(self.userManager:getNumberOfUsers())
		self:sendPlatformSessionIdsToMasterServer(self.userManager:getAllPlatformSessionIds())
		g_server:broadcastEvent(UserEvent.new({}, { v193_ }, self.missionDynamicInfo.capacity))
	else
		g_gui:closeAllDialogs()
		self.cleanServerShutDown = true
		setPresenceMode(PresenceModes.PRESENCE_IDLE)
		InfoDialog.show(g_i18n:getText("ui_serverWasShutdown"), self.onShutdownEventOk, self)
	end
end

function FSBaseMission:onShutdownEventOk()
	OnInGameMenuMenu()
end

function FSBaseMission:onMasterServerConnectionReady() end

function FSBaseMission:onMasterServerConnectionFailed(reason)
	if g_dedicatedServer == nil then
		if self.isMissionStarted then
			g_gui:showGui("InGameMenu")
			g_inGameMenu:setMasterServerConnectionFailed(reason)
		else
			OnInGameMenuMenu(false, true)
		end
	else
		Logging.error("Lost connection to master server. Shutting down server...")
		doExit()
		return
	end
end

function FSBaseMission:getServerUserId()
	return 1
end

-- Local values: player
function FSBaseMission:getFarmId(connection)
	if self:getIsServer() then
		if g_localPlayer == nil or connection ~= nil then
			if connection == nil then
				return nil
			else
				local v198_ = self:getPlayerByConnection(connection)
				if v198_ == nil then
					return nil
				else
					return v198_.farmId
				end
			end
		else
			return g_localPlayer.farmId
		end
	else
		return g_localPlayer == nil and 0 or g_localPlayer.farmId
	end
end

-- Local values: farm
function FSBaseMission:farmStats(farmId)
	if farmId == nil then
		farmId = g_localPlayer.farmId
	end
	local v200_ = g_farmManager:getFarmById(farmId)
	if v200_ ~= nil then
		return v200_.stats
	end
	printError("Error: Farm not found for stats")
	return FarmStats.new()
end

function FSBaseMission:getPlayerByConnection(connection)
	return self.connectionsToPlayer[connection]
end

-- Local values: connection
function FSBaseMission:kickUser(user)
	assert(self:getIsServer())
	local v205_ = user:getConnection()
	v205_:sendEvent(KickBanNotificationEvent.new(true))
	g_server:closeConnection(v205_, DisconnectReason.KICKED)
end

-- Local values: connection
function FSBaseMission:banUser(user)
	user:block()
	if self:getIsServer() then
		local v208_ = user:getConnection()
		v208_:sendEvent(KickBanNotificationEvent.new(false))
		g_server:closeConnection(v208_, DisconnectReason.BANNED)
	end
end

-- Local values: vehicle, placeable, item, handTool, handToolHolder, player
function FSBaseMission:getObjectByUniqueId(uniqueId)
	local v211_ = self.vehicleSystem:getVehicleByUniqueId(uniqueId)
	if v211_ == nil then
		local v212_ = self.placeableSystem:getPlaceableByUniqueId(uniqueId)
		if v212_ == nil then
			local v213_ = self.itemSystem:getItemByUniqueId(uniqueId)
			if v213_ == nil then
				local v214_ = self.handToolSystem:getHandToolByUniqueId(uniqueId)
				if v214_ == nil then
					local v215_ = self.handToolSystem:getHandToolHolderByUniqueId(uniqueId)
					if v215_ == nil then
						local v216_ = self.playerSystem:getPlayerByUniqueId(uniqueId)
						if v216_ == nil then
							return nil
						else
							return v216_
						end
					else
						return v215_
					end
				else
					return v214_
				end
			else
				return v213_
			end
		else
			return v212_
		end
	else
		return v211_
	end
end

function FSBaseMission:onObjectCreated(object)
	FSBaseMission:superClass().onObjectCreated(self, object)
	if self.slotSystem:getIsCountableObject(object) then
		self.slotSystem:updateSlotUsage()
	end
end

function FSBaseMission:onObjectDeleted(object)
	FSBaseMission:superClass().onObjectDeleted(self, object)
	if self.slotSystem:getIsCountableObject(object) then
		self.slotSystem:updateSlotUsage()
	end
end

-- Local values: farmId
function FSBaseMission:addOwnedItem(item)
	FSBaseMission:superClass().addOwnedItem(self, item)
	local v223_ = g_localPlayer ~= nil and g_localPlayer.farmId or AccessHandler.EVERYONE
	g_shopController:setOwnedFarmItems(self.ownedItems, v223_)
end

-- Local values: farmId
function FSBaseMission:removeOwnedItem(item)
	FSBaseMission:superClass().removeOwnedItem(self, item)
	local v226_ = g_localPlayer ~= nil and g_localPlayer.farmId or AccessHandler.EVERYONE
	g_shopController:setOwnedFarmItems(self.ownedItems, v226_)
end

-- Local values: farmId
function FSBaseMission:addLeasedItem(item)
	FSBaseMission:superClass().addLeasedItem(self, item)
	local v229_ = g_localPlayer ~= nil and g_localPlayer.farmId or AccessHandler.EVERYONE
	g_shopController:setLeasedFarmItems(self.leasedItems, v229_)
end

-- Local values: farmId
function FSBaseMission:removeLeasedItem(item)
	FSBaseMission:superClass().removeLeasedItem(self, item)
	local v232_ = g_localPlayer ~= nil and g_localPlayer.farmId or AccessHandler.EVERYONE
	g_shopController:setLeasedFarmItems(self.leasedItems, v232_)
end

-- Local values: loadingFileId, splitShapeFileId
function FSBaseMission:loadMap(filename, addPhysics, asyncCallbackFunction, asyncCallbackObject, asyncCallbackArguments)
	local v239_ = self.missionInfo.mapsSplitShapeFileIds == nil and -1 or Utils.getNoNil(self.missionInfo.mapsSplitShapeFileIds[#self.mapsSplitShapeFileIds + 1], -1)
	setSplitShapesLoadingFileId(v239_)
	local v240_ = setSplitShapesNextFileId()
	local v241_ = self.mapsSplitShapeFileIds
	table.insert(v241_, v240_)
	FSBaseMission:superClass().loadMap(self, filename, addPhysics, asyncCallbackFunction, asyncCallbackObject, asyncCallbackArguments)
end

function FSBaseMission:registerToLoadOnMapFinished(object)
	local v244_ = self.objectsToCallOnMapFinished
	table.insert(v244_, object)
end

-- Local values: startedRepeat, asyncCallbackFunction, asyncCallbackObject, asyncCallbackArguments, terrainNode, numChildren, i, t, _, object
function FSBaseMission:loadMapFinished(node, failedReason, arguments, callAsyncCallback)
	local v250_ = startFrameRepeatMode()
	FSBaseMission:superClass().loadMapFinished(self, node, failedReason, arguments, false)
	local v251_ = arguments.asyncCallbackFunction
	local v252_ = arguments.asyncCallbackObject
	local v253_ = arguments.asyncCallbackArguments
	if not self.missionDynamicInfo.isMultiplayer and (self.trafficSystem ~= nil and (self.trafficSystem.trafficSystemId ~= nil and (self.pedestrianSystem ~= nil and self.pedestrianSystem.pedestrianSystemId ~= nil))) then
		setPedestrianSystemTrafficSystem(self.pedestrianSystem.pedestrianSystemId, self.trafficSystem.trafficSystemId)
	end
	if g_dedicatedServer == nil then
		self.mapOverlayGenerator = MapOverlayGenerator.new(g_i18n, g_fruitTypeManager, g_fillTypeManager, g_farmlandManager, g_farmManager, self.weedSystem)
		self.mapOverlayGenerator:setColorBlindMode(Utils.getNoNil(g_gameSettings:getValue(GameSettings.SETTING.USE_COLORBLIND_MODE), false))
		self.mapOverlayGenerator:setFieldColor(self.mapFieldColor, self.mapGrassFieldColor)
	end
	if node ~= 0 then
		local v254_ = 0
		for v255_ = 0, getNumOfChildren(node) - 1 do
			local v256_ = getChildAt(node, v255_)
			if getHasClassId(v256_, ClassIds.TERRAIN_TRANSFORM_GROUP) then
				v254_ = v256_
				break
			end
		end
		if v254_ ~= 0 then
			self:initTerrain(v254_, arguments.filename)
		end
	end
	if self.trafficSystem ~= nil and (self.trafficSystem.trafficSystemId ~= nil and (self.aiSystem ~= nil and self.aiSystem.navigationMap ~= nil)) then
		setTrafficSystemVehicleNavigationMap(self.trafficSystem.trafficSystemId, self.aiSystem.navigationMap)
		setVehicleNavigationMapTrafficSystem(self.aiSystem.navigationMap, self.trafficSystem.trafficSystemId)
	end
	if (callAsyncCallback == nil or callAsyncCallback) and v251_ ~= nil then
		v251_(v252_, node, v253_)
	end
	if v250_ then
		endFrameRepeatMode()
	end
	if not self.cancelLoading then
		if g_dedicatedServer == nil then
			g_asyncTaskManager:addTask(function()
				-- upvalues: (copy) self
				g_wildlifeManager:loadMapData(self.xmlFile, self.baseDirectory)
			end)
		end
		for _, v257_ in pairs(self.objectsToCallOnMapFinished) do
			v257_:onLoadMapFinished()
		end
		g_inGameMenu:setManureTriggers(self.manureLoadingStations, self.liquidManureLoadingStations)
		g_inGameMenu:setConnectedUsers(self.userManager:getUsers())
	end
	self.objectsToCallOnMapFinished = {}
end

-- Local values: _, isMultiplayer, terrainColMask, newTerrainColMask, cellSizeMeters, cellCollisionMask, sphereCollisionMask, numSpheres, x, y, z, worldSizeHalf, worldMinY, worldMaxY, clipDistanceThreshold1, clipDistanceThreshold2, foliageViewCoeff, lodBlendStart, lodBlendEnd, _, id, fruitTypes, _, fruitTypeDesc, isValid, layerName, foliageTransfromGroupId, terrainDataPlaneId, terrainDataPlaneIndex, mapName, layerNameHaulm, terrainDataPlaneIdHaulm, terrainDataPlaneIndexHaulm, generatedTipCollisionMap, generatedPlacementCollisionMap, terrainHeightUpdater
function FSBaseMission:initTerrain(terrainNode, filename)
	local v261_ = self.missionDynamicInfo.isMultiplayer
	self.terrainRootNode = terrainNode
	g_terrainNode = terrainNode
	local v262_ = getCollisionFilterMask(terrainNode)
	local v263_
	if CollisionFlag.getHasGroupFlagSet(terrainNode, CollisionFlag.TERRAIN) then
		v263_ = v262_
	else
		local v264_ = CollisionFlag.TERRAIN
		v263_ = bit32.bor(v262_, v264_)
		Logging.warning("Missing collision mask bit \'%d\'. Automatically added bit to terrain node \'%s\'", CollisionFlag.getBit(CollisionFlag.TERRAIN), getName(terrainNode))
	end
	if CollisionFlag.getHasGroupFlagSet(terrainNode, CollisionFlag.AI_BLOCKING) then
		local v265_ = CollisionFlag.AI_BLOCKING
		local v266_ = bit32.bnot(v265_)
		v263_ = bit32.band(v263_, v266_)
		Logging.warning("Terrain node \'%s\' has bit \'%d\' activated. Automatically removed this bit from collision mask", getName(terrainNode), CollisionFlag.getBit(CollisionFlag.AI_BLOCKING))
	end
	if v262_ ~= v263_ then
		setCollisionFilterMask(terrainNode, v263_)
	end
	self.terrainSize = getTerrainSize(terrainNode)
	g_terrainSize = self.terrainSize
	g_terrainSizeHalf = self.terrainSize * 0.5
	g_inGameMenu:setTerrainSize(self.terrainSize)
	local v267_ = CollisionFlag.STATIC_OBJECT + CollisionFlag.TREE + CollisionFlag.BUILDING + CollisionFlag.PRECIPITATION_BLOCKING + CollisionFlag.DYNAMIC_OBJECT + CollisionFlag.WATER
	createLowResCollisionHandler(Platform.lowResCollisionHandlerGridSize, Platform.lowResCollisionHandlerGridSize, 1, v267_, Platform.lowResCollisionHandlerCellRaysPerFrame, v267_, 5)
	addLowResCollisionHandlerLOD(2, Platform.lowResCollisionHandlerCellRaysPerFrame / 2)
	addLowResCollisionHandlerLOD(2, Platform.lowResCollisionHandlerCellRaysPerFrame / 2)
	setLowResCollisionHandlerTerrainRootNode(terrainNode)
	local v268_, v269_, v270_ = getWorldTranslation(terrainNode)
	if math.abs(v268_) > 0.1 or (math.abs(v270_) > 0.1 or v269_ < 0) then
		printWarning("Warning: the terrain node needs to be a x=0 and z=0 and y >= 0")
	end
	self.areaCompressionParams = NetworkUtil.createWorldPositionCompressionParams(self.terrainSize, 0.5 * self.terrainSize, 0.02)
	self.areaRelativeCompressionParams = NetworkUtil.createWorldPositionCompressionParams(100, 50, 0.02)
	self.vehicleXZPosCompressionParams = NetworkUtil.createWorldPositionCompressionParams(self.terrainSize + 500, 0.5 * (self.terrainSize + 500), 0.005)
	self.vehicleYPosCompressionParams = NetworkUtil.createWorldPositionCompressionParams(1500, 0, 0.005)
	self.vehicleXZPosHighPrecisionCompressionParams = NetworkUtil.createWorldPositionCompressionParams(self.terrainSize + 500, 0.5 * (self.terrainSize + 500), 0.0001)
	self.vehicleYPosHighPrecisionCompressionParams = NetworkUtil.createWorldPositionCompressionParams(1500, 0, 0.0001)
	setSplitShapesWorldCompressionParams(self.terrainSize, 0.5 * self.terrainSize, 0.005, 1700, 200, 0.005, self.terrainSize, 0.5 * self.terrainSize, 0.005)
	local v271_ = 0.5 * self.terrainSize + self.cullingWorldXZOffset
	local v272_ = self.cullingWorldMinY
	local v273_ = self.cullingWorldMaxY
	local v274_ = self.cullingClipDistanceThreshold1
	local v275_ = self.cullingClipDistanceThreshold2
	setAudioCullingWorldProperties(-v271_, v272_, -v271_, v271_, v273_, v271_, 16, v274_, v275_)
	setLightCullingWorldProperties(-v271_, v272_, -v271_, v271_, v273_, v271_, 16, v274_, v275_)
	setShapeCullingWorldProperties(-v271_, v272_, -v271_, v271_, v273_, v271_, 64, v274_, v275_)
	local v276_ = getFoliageViewDistanceCoeff()
	local v277_, v278_ = getTerrainLodBlendDynamicDistances(terrainNode)
	setTerrainLodBlendDynamicDistances(terrainNode, v277_ * v276_, v278_ * v276_)
	setGroundFogTerrainEntityId(terrainNode)
	if self.foliageBendingSystem then
		self.foliageBendingSystem:setTerrainTransformGroup(terrainNode)
	end
	local v279_, _ = getTerrainDataPlaneByName(terrainNode, "terrainDetail")
	self.terrainDetailId = v279_
	if self.terrainDetailId ~= 0 then
		self.terrainDetailMapSize = getDensityMapSize(self.terrainDetailId)
	end
	self.fieldGroundSystem:initTerrain(self, terrainNode, self.terrainDetailId)
	self.stoneSystem:initTerrain(self, terrainNode, self.terrainDetailId)
	self.weedSystem:initTerrain(self, terrainNode, self.terrainDetailId)
	self.vineSystem:initTerrain(self.terrainSize, self.terrainDetailMapSize)
	self.foliageSystem:initTerrain(self, terrainNode, self.terrainDetailId)
	self.treeMarkerSystem:initTerrain()
	self.environmentAreaSystem:initTerrain(terrainNode)
	if v261_ then
		self.densityMapSyncer = DensityMapSyncer.new(terrainNode, 32)
		self.terrainDeformationSyncer = TerrainDeformationSyncer.new(terrainNode, self.terrainSize)
		for _, v280_ in pairs(self.dynamicFoliageLayers) do
			self.densityMapSyncer:addDensityMap(v280_)
		end
		self.fieldGroundSystem:addDensityMapSyncer(self.densityMapSyncer)
		self.stoneSystem:addDensityMapSyncer(self.densityMapSyncer)
		self.weedSystem:addDensityMapSyncer(self.densityMapSyncer)
		self.foliageSystem:addDensityMapSyncer(self.densityMapSyncer)
	end
	local v281_ = {}
	for _, v282_ in ipairs(g_fruitTypeManager:getFruitTypes()) do
		local v283_ = v282_:getLayerName()
		local v284_ = getFoliageTransformGroupIdByFoliageName(terrainNode, v283_)
		local v285_, v286_ = getTerrainDataPlaneByName(terrainNode, v283_)
		local v287_
		if v285_ == 0 then
			v287_ = false
		else
			v287_ = true
			v282_:setTerrainDataPlane(v285_)
			v282_:setTerrainDataPlaneIndex(v286_)
			v282_:setFoliageTransformGroup(v284_)
			g_fruitTypeManager:addTerrainDataPlane(v285_)
			g_fruitTypeManager:setTerrainDataPlaneIndex(v282_, v286_)
			local v288_ = self.fruitMapSize
			local v289_ = getDensityMapSize
			self.fruitMapSize = math.max(v288_, v289_(v285_))
			if self:getIsServer() then
				local v290_ = getDensityMapFilename(v285_)
				local v291_ = Utils.getFilenameInfo(v290_)
				self.growthSystem:setFruitLayer(v291_, v282_, v283_, v285_)
			end
			if v261_ then
				self.densityMapSyncer:addDensityMap(v285_)
			end
		end
		local v292_ = v282_:getHaulmLayerName()
		if v292_ ~= nil then
			local v293_, v294_ = getTerrainDataPlaneByName(terrainNode, v292_)
			if v293_ ~= 0 then
				v287_ = true
				g_fruitTypeManager:addTerrainDataPlane(v293_)
				g_fruitTypeManager:addHaulmFruitType(v282_)
				v282_:setTerrainDataPlaneHaulm(v293_)
				v282_:setTerrainDataPlaneHaulmIndex(v294_)
				if v261_ then
					self.densityMapSyncer:addDensityMap(v293_)
				end
			end
		end
		if v287_ then
			table.insert(v281_, v282_)
		end
	end
	if self.mapOverlayGenerator ~= nil then
		self.mapOverlayGenerator:setMissionFruitTypes(v281_)
	end
	self.growthSystem:onTerrainLoad(terrainNode)
	if self.terrainDetailId ~= 0 then
		self.fieldCropsQuery = FieldCropsQuery.new(self.terrainDetailId)
	end
	self.terrainDetailHeightId = getTerrainDataPlaneByName(terrainNode, "terrainDetailHeight")
	self.terrainDetailHeightTGId = getTerrainDetailByName(terrainNode, "terrainDetailHeight")
	self.terrainDetailHeightMapSize = self.fruitMapSize
	if self.terrainDetailHeightId ~= 0 then
		self.terrainDetailHeightMapSize = getDensityMapSize(self.terrainDetailHeightId)
		g_densityMapHeightManager:loadFromXMLFile(self.missionInfo.densityMapHeightXMLLoad)
		local v295_ = getInfoLayerFromTerrain(terrainNode, "tipCollisionGenerated")
		local v296_ = getInfoLayerFromTerrain(terrainNode, "placementCollisionGenerated")
		g_densityMapHeightManager:initialize(self:getIsServer(), v295_, v296_)
		if g_densityMapHeightManager:getTerrainDetailHeightUpdater() ~= nil and v261_ then
			self.densityMapSyncer:addDensityMap(self.terrainDetailHeightId, true)
		end
	end
	if v261_ then
		self.densityMapSyncer:onDensityMapsAdded()
	end
	self.indoorMask:onTerrainLoad(terrainNode)
	self.snowSystem:onTerrainLoad(terrainNode)
	self.aiSystem:onTerrainLoad(terrainNode, filename)
	if self.shallowWaterSimulation ~= nil then
		self.shallowWaterSimulation:onTerrainLoad(terrainNode)
	end
	g_groundTypeManager:initTerrain(terrainNode)
	DensityMapHeightUtil.initTerrain(self, self.terrainDetailId, self.terrainDetailHeightId)
	g_mpLoadingScreen:hitLoadingTarget(MPLoadingScreen.LOAD_TARGETS.TERRAIN)
end

function FSBaseMission:addTrainSystem(trainSystem)
	self.trainSystems[trainSystem] = trainSystem
end

function FSBaseMission:removeTrainSystem(trainSystem)
	self.trainSystems[trainSystem] = nil
end

-- Local values: trainSystem, _
function FSBaseMission:setTrainSystemTabbable(isTabbable)
	for v303_, _ in pairs(self.trainSystems) do
		v303_:setIsTrainTabbable(isTabbable)
	end
end

function FSBaseMission:mouseEvent(posX, posY, isDown, isUp, button)
	FSBaseMission:superClass().mouseEvent(self, posX, posY, isDown, isUp, button)
	self.hud:mouseEvent(posX, posY, isDown, isUp, button)
end

-- Local values: inputBinding, hasPauseContext, needPause, needUnpause
function FSBaseMission:updatePauseInputContext()
	local v311_ = g_inputBinding
	local v312_ = v311_:getContextName() == BaseMission.INPUT_CONTEXT_PAUSE and true or v311_:getContextName() == BaseMission.INPUT_CONTEXT_SYNCHRONIZING
	local v313_ = self.gameStarted and self.paused
	if v313_ then
		v313_ = not g_gui:getIsGuiVisible() or self.isSynchronizingWithPlayers
	end
	local v314_ = self.gameStarted
	if v314_ then
		v314_ = not self.paused
	end
	if not self.isSynchronizingWithPlayers and v311_:getContextName() == BaseMission.INPUT_CONTEXT_SYNCHRONIZING then
		v311_:revertContext()
	end
	if v313_ and not v312_ then
		v311_:setContext(BaseMission.INPUT_CONTEXT_PAUSE)
	elseif v314_ and v312_ then
		v311_:revertContext()
	end
	if v313_ and (self.isSynchronizingWithPlayers and v311_:getContextName() ~= BaseMission.INPUT_CONTEXT_SYNCHRONIZING) then
		v311_:setContext(BaseMission.INPUT_CONTEXT_SYNCHRONIZING, true)
	end
end
local function v346_(p315_, p316_)
	-- upvalues: (ref) l_engineStateTimer, (ref) l_engineState, (copy) v_u_3_
	FSBaseMission:superClass().update(p315_, p316_)
	if not l_engineStateTimer and (p315_.isRunning and Utils.getNoNil(g_farmManager:getFarmById(g_localPlayer.farmId).stats:getTotalValue("playTime"), 0) / 60 > 4) then
		l_engineState = l_engineState - p316_
		if l_engineState < 0 and not g_gui:getIsGuiVisible() then
			InfoDialog.show(g_i18n:getText("dialog_getFullVersion"), v_u_3_)
			l_engineState = math.random(1200000, 1800000)
		end
	end
	if p315_.debugPhysicsStressTest then
		p315_.debugPhysicsStressTestSpawn()
		p315_.debugPhysicsStressTestRemove(p316_)
	end
	p315_.hud:updateMessage(p316_)
	p315_.hud:setIsSaving(p315_.isServerSaving or g_savegameController:getIsSaving())
	p315_.hud:updateMap(p316_)
	p315_.introductionHelpSystem:update(p316_)
	p315_.aiSystem:update(p316_)
	p315_.environmentAreaSystem:update(p316_)
	p315_.reverbSystem:update(p316_)
	p315_.ambientSoundSystem:update(p316_)
	p315_.vineSystem:update(p316_)
	p315_.userManager:update(p316_)
	p315_.snowSystem:update(p316_)
	if p315_.economyManager ~= nil then
		p315_.economyManager:update(p316_)
	end
	g_densityMapHeightManager:update(p316_)
	if g_dedicatedServer == nil then
		g_wildlifeManager:update(p316_)
	end
	p315_:updatePauseInputContext()
	if p315_.isRunning or g_dedicatedServer ~= nil then
		if #p315_.playersToAccept > 0 then
			if p315_.missionDynamicInfo.autoAccept then
				p315_:onConnectionDenyAccept(p315_.playersToAccept[1].connection, false, false)
			elseif p315_:getCanAcceptPlayers() then
				local v317_ = p315_.playersToAccept[1]
				DenyAcceptDialog.show(p315_.onConnectionDenyAccept, p315_, v317_.connection, v317_.playerName, v317_.platformId, getIsSplitShapeConnectionWithinLimits(v317_.platformId))
			end
		end
		if p315_.pendingSavegameDateAchievement then
			local v318_ = p315_.missionInfo.saveDate
			if v318_ ~= nil then
				local v319_ = getDate("%Y-%m-%d")
				local v320_, v321_ = string.match(v318_, "(%d%d%d%d)-(%d%d)")
				local v322_, v323_ = string.match(v319_, "(%d%d%d%d)-(%d%d)")
				local v324_ = tonumber(v320_)
				local v325_ = tonumber(v321_)
				local v326_ = tonumber(v322_)
				local v327_ = tonumber(v323_)
				local v328_
				if v324_ == nil or (v325_ == nil or v326_ == nil) then
					v328_ = false
				else
					v328_ = v327_ ~= nil
				end
				if v328_ then
					local v329_ = (v326_ - v324_) * 12 + (v327_ - v325_)
					if v329_ > 0 then
						g_achievementManager:tryUnlock("LoadedOldSavegame", v329_)
					end
				end
			end
			p315_.pendingSavegameDateAchievement = nil
		end
		g_effectManager:update(p316_)
		g_animationManager:update(p316_)
		g_guidedTourManager:update(p316_)
		p315_.growthSystem:update(p316_)
		g_npcManager:update(p316_)
		if p315_.mapOverlayGenerator ~= nil then
			p315_.mapOverlayGenerator:update(p316_)
		end
		if p315_:getIsServer() then
			for v330_, v331_ in ipairs(p315_.userManager:getUsers()) do
				if v330_ > 1 then
					local v332_ = g_farmManager:getFarmByUserId(v331_:getId())
					if v331_:getState() == FSBaseMission.USER_STATE_INGAME and v331_:getFinanceUpdateSendTime() < p315_.time then
						local v333_ = p315_.time
						local v334_ = math.random() * 300 + 5000
						v331_:setFinanceUpdateSendTime(v333_ + math.floor(v334_))
						if v332_.stats.financesVersionCounter ~= v331_:getFinancesVersionCounter() then
							v331_:setFinancesVersionCounter(v332_.stats.financesVersionCounter)
							v331_:getConnection():sendEvent(FinanceStatsEvent.new(0, v332_.farmId))
						end
					end
				end
			end
			g_treePlantManager:updateTrees(p316_, p316_ * p315_:getEffectiveTimeScale())
		end
		if g_dedicatedServer ~= nil then
			g_dedicatedServer:update(p316_)
		end
		if p315_:getIsClient() then
			if not g_gui:getIsGuiVisible() then
				if g_soundPlayer ~= nil then
					local v335_ = g_localPlayer:getCurrentVehicle()
					local v336_ = v335_ ~= nil and v335_.supportsRadio or not g_gameSettings:getValue(GameSettings.SETTING.RADIO_VEHICLE_ONLY)
					g_inputBinding:setActionEventActive(g_localPlayer.inputComponent.radioActionId, v336_)
				end
				p315_.hud:updateVehicleName(p316_)
			end
			p315_:updateSaving()
			p315_:checkRecordingDeviceState(p316_)
		end
		local v337_
		if p315_.missionDynamicInfo.isMultiplayer then
			if p315_:getIsServer() then
				local v338_ = 0
				local v339_ = false
				for _, v340_ in ipairs(p315_.userManager:getUsers()) do
					local v341_ = v340_:getConnection()
					if v340_:getState() == FSBaseMission.USER_STATE_INGAME and (v341_ ~= nil and p315_.connectionsToPlayer[v341_] ~= nil) then
						v338_ = v338_ + 1
						if v340_:getId() ~= p315_.playerUserId and not getPlatformIdsAreCompatible(v340_:getPlatformId(), getPlatformId()) then
							v339_ = true
						end
					end
				end
				if v338_ > 1 then
					if v339_ then
						v337_ = PresenceModes.PRESENCE_MULTIPLAYER_CROSSPLAY
					else
						v337_ = PresenceModes.PRESENCE_MULTIPLAYER
					end
				else
					v337_ = PresenceModes.PRESENCE_MULTIPLAYER_ALONE
				end
			else
				local v342_ = false
				for _, v343_ in ipairs(p315_.userManager:getUsers()) do
					if v343_:getId() ~= p315_.playerUserId and not getPlatformIdsAreCompatible(v343_:getPlatformId(), getPlatformId()) then
						v342_ = true
					end
				end
				if v342_ then
					v337_ = PresenceModes.PRESENCE_MULTIPLAYER_CROSSPLAY
				else
					v337_ = PresenceModes.PRESENCE_MULTIPLAYER
				end
			end
		else
			v337_ = PresenceModes.PRESENCE_CAREER
		end
		if p315_.wasNetworkError and GS_PLATFORM_PLAYSTATION then
			v337_ = PresenceModes.PRESENCE_IDLE
		end
		if p315_.presenceMode ~= v337_ then
			if p315_.presenceMode == PresenceModes.PRESENCE_MULTIPLAYER or p315_.presenceMode == PresenceModes.PRESENCE_MULTIPLAYER_CROSSPLAY then
				setPresenceMode(v337_)
				p315_.presenceMode = v337_
			elseif not g_gui:getIsGuiVisible() or p315_:getIsServer() then
				setPresenceMode(v337_)
				p315_.presenceMode = v337_
			end
		end
		if GS_PLATFORM_PLAYSTATION and p315_.missionDynamicInfo.isMultiplayer then
			local v344_ = getNetworkError()
			if v344_ and not p315_.wasNetworkError then
				local v345_ = string.gsub(v344_, "Network", "dialog_network")
				p315_.wasNetworkError = true
				ConnectionFailedDialog.show(g_i18n:getText(v345_), g_connectionFailedDialog.onOkCallback, g_connectionFailedDialog, { g_gui.currentGuiName })
			elseif not v344_ and p315_.wasNetworkError then
				p315_.wasNetworkError = false
			end
			if getMultiplayerAvailability() == MultiplayerAvailability.NOT_AVAILABLE then
				OnInGameMenuMenu()
			end
		end
		if p315_.isExitingGame then
			OnInGameMenuMenu()
		end
		if Platform.supportsGameRating then
			p315_:testForGameRating()
		end
	else
		if p315_.paused and (not p315_.isSynchronizingWithPlayers and (not g_gui:getIsGuiVisible() and GS_PLATFORM_PLAYSTATION)) then
			setPresenceMode(PresenceModes.PRESENCE_IDLE)
			p315_.presenceMode = PresenceModes.PRESENCE_IDLE
		end
		p315_:updateSaving()
	end
end
FSBaseMission.update = v346_

function FSBaseMission:postUpdate(dt)
	self.hud:postUpdateMap(dt)
end

-- Local values: hasDevice
function FSBaseMission:checkRecordingDeviceState(dt)
	if self.missionDynamicInfo.isMultiplayer and Platform.hasRecordingDeviceDetection then
		self.checkRecordingDeviceTimer = self.checkRecordingDeviceTimer + dt
		if self.checkRecordingDeviceTimer >= FSBaseMission.RECORDING_DEVICE_CHECK_INTERVAL then
			self.checkRecordingDeviceTimer = 0
			local v351_ = VoiceChatUtil.getHasRecordingDevice()
			if v351_ ~= self.lastRecordingDeviceState then
				self.lastRecordingDeviceState = v351_
				if v351_ then
					self:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_OK, g_i18n:getText("ui_microphoneDetected"))
					return
				end
				self:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_OK, g_i18n:getText("ui_microphoneRemoved"))
			end
		end
	end
end

-- Local values: lifetimeStats, totalPlayTime, amountGameRateDialogShown, show
function FSBaseMission:testForGameRating()
	if g_gui:getIsGuiVisible() then
		return
	elseif not self.introductionHelpSystem:getIsHelpVisible() then
		local v353_ = g_lifetimeStats
		local v354_ = v353_:getTotalRuntime()
		local v355_ = v353_.gameRateMessagesShown
		local v356_
		if v355_ < 4 then
			v356_ = v355_ * 3 + 1 <= v354_
		else
			v356_ = false
		end
		if v356_ then
			v353_.gameRateMessagesShown = v355_ + 1
			v353_:save()
			GameRateDialog.show()
		end
	end
end

-- Local values: inGameMenu, metadata, _, errorCode
function FSBaseMission:updateSaving()
	if self.doSaveGameState == SavegameController.SAVE_STATE_NONE then
		return
	else
		local v_u_358_ = g_inGameMenu
		if self.doSaveGameState == SavegameController.SAVE_STATE_VALIDATE_LIST then
			if g_savegameController:isStorageDeviceUnavailable() then
				self.doSaveGameState = SavegameController.SAVE_STATE_VALIDATE_LIST_DIALOG_WAIT
				if g_dedicatedServer == nil then
					InfoDialog.show(g_i18n:getText("ui_savegameSaveNoSpace"))
				else
					Logging.error("The device has no space to save the game.")
				end
			else
				self.doSaveGameState = SavegameController.SAVE_STATE_OVERWRITE_DIALOG
				return
			end
		elseif self.doSaveGameState == SavegameController.SAVE_STATE_OVERWRITE_DIALOG then
			local v359_, _ = saveGetInfoById(self.missionInfo.savegameIndex)
			if v359_ == "" then
				self.doSaveGameState = SavegameController.SAVE_STATE_NOP_WRITE
				return
			else
				self.doSaveGameState = SavegameController.SAVE_STATE_OVERWRITE_DIALOG_WAIT
				if g_dedicatedServer == nil then
					v_u_358_:notifyOverwriteSavegame(self.onYesNoSavegameOverwrite, self)
				else
					self:onYesNoSavegameOverwrite(true)
				end
			end
		elseif self.doSaveGameState == SavegameController.SAVE_STATE_NOP_WRITE then
			self.doSaveGameState = SavegameController.SAVE_STATE_WRITE
			return
		elseif self.doSaveGameState == SavegameController.SAVE_STATE_WRITE then
			if g_dedicatedServer == nil then
				v_u_358_:notifyStartSaving()
			end
			self.doSaveGameState = SavegameController.SAVE_STATE_WRITE_WAIT
			self.savingMinEndTime = getTimeSec() + SavegameController.SAVING_DURATION
			self:saveSavegame(self.doSaveGameBlocking)
		elseif self.doSaveGameState == SavegameController.SAVE_STATE_WRITE_WAIT and not g_savegameController:getIsSaving() then
			local v360_ = g_savegameController:getSavingErrorCode()
			if v360_ == Savegame.ERROR_OK then
				self.doSaveGameState = SavegameController.SAVE_STATE_NONE
				if g_dedicatedServer == nil then
					v_u_358_:notifySaveComplete()
				end
			else
				self.doSaveGameState = SavegameController.SAVE_STATE_NONE
				self.savingMinEndTime = 0
				if v360_ == Savegame.ERROR_SAVE_NO_SPACE and not GS_PLATFORM_PLAYSTATION then
					self.currentDeviceHasNoSpace = true
					if g_dedicatedServer == nil then
						InfoDialog.show(g_i18n:getText("ui_savegameSaveNoSpace"), function()
							-- upvalues: (copy) v_u_358_
							v_u_358_:notifySavegameNotSaved()
						end)
						return
					end
				else
					g_savegameController:resetStorageDeviceSelection()
					if g_dedicatedServer == nil then
						v_u_358_:notifySavegameNotSaved()
						return
					end
				end
			end
		end
	end
end

function FSBaseMission:onSaveGameUpdateComplete(errorCode)
	if self.doSaveGameState == SavegameController.SAVE_STATE_VALIDATE_LIST_WAIT then
		if errorCode == Savegame.ERROR_OK or errorCode == Savegame.ERROR_DATA_CORRUPT then
			self.currentDeviceHasNoSpace = false
			self.doSaveGameState = SavegameController.SAVE_STATE_OVERWRITE_DIALOG
			return
		end
		self.doSaveGameState = SavegameController.SAVE_STATE_NONE
		g_savegameController:resetStorageDeviceSelection()
		g_inGameMenu:notifySavegameNotSaved(errorCode)
	end
end

function FSBaseMission:onYesNoSavegameOverwrite(yes)
	if yes then
		self.doSaveGameState = InGameMenu.SAVE_STATE_NOP_WRITE
	else
		self.doSaveGameState = InGameMenu.SAVE_STATE_NONE
		self.savingMinEndTime = 0
		g_inGameMenu:notifySavegameNotSaved()
	end
end

-- Local values: percentage, numSyncPlayers, _, syncPlayer
function FSBaseMission:getSynchronizingPercentage()
	local v366_ = 0
	local v367_ = 0
	for _, v368_ in pairs(self.playersSynchronizing) do
		v366_ = v366_ + self.restPercentageFraction
		if v368_.densityMapEvent ~= nil then
			v366_ = v366_ + v368_.densityMapEvent.percentage * self.densityMapPercentageFraction
		end
		if v368_.splitShapesEvent ~= nil then
			v366_ = v366_ + v368_.splitShapesEvent.percentage * self.splitShapesPercentageFraction
		end
		v367_ = v367_ + 1
	end
	if v367_ > 0 then
		v366_ = v366_ / v367_
	end
	local v369_ = v366_ * 100
	return math.floor(v369_)
end

-- Local values: pauseText
function FSBaseMission:showPauseDisplay(enableDisplay)
	local v372_
	if enableDisplay then
		v372_ = g_i18n:getText("ui_gamePaused")
		if GS_IS_CONSOLE_VERSION and self:getIsServer() then
			v372_ = v372_ .. " " .. g_i18n:getText("ui_continueGame")
		end
	else
		v372_ = ""
	end
	if self.hud ~= nil then
		self.hud:onPauseGameChange(enableDisplay, v372_)
	end
end

-- Local values: percentageStr, pauseText, menuVisible, drawHud
function FSBaseMission:draw()
	if self.paused then
		if self.isSynchronizingWithPlayers then
			local v374_ = not self:getIsServer() and "" or string.format(" %i%%", self:getSynchronizingPercentage())
			local v375_ = g_i18n:getText("ui_synchronizingWithOtherPlayers") .. v374_
			self.hud:onPauseGameChange(nil, v375_)
		end
		local v376_ = g_gui:getIsGuiVisible()
		if v376_ then
			v376_ = not g_gui:getIsOverlayGuiVisible()
		end
		if not v376_ or self.isSynchronizingWithPlayers then
			local v377_ = self.hud
			local v378_ = not self.isMissionStarted
			if v378_ then
				v378_ = not v376_
			end
			v377_:drawGamePaused(v378_)
		end
	end
	if not self.paused and self.introductionHelpSystem ~= nil then
		self.introductionHelpSystem:draw()
	end
	local v379_ = not g_gui:getIsMenuVisible()
	if v379_ and (g_gui:getIsDialogVisible() and not Platform.ui.drawHudOnDialog) then
		v379_ = false
	end
	if self.isRunning and (v379_ or g_gui:getIsOverlayGuiVisible()) and not self.hud:getIsFading() then
		if self.hud:getIsVisible() then
			self.hud:drawBaseHUD()
			self.hud:drawVehicleName()
		end
		g_guidedTourManager:draw()
	end
	FSBaseMission:superClass().draw(self)
	if not self.hud:getIsFading() then
		self.hud:drawInGameMessageAndIcon()
	end
end

-- Local values: changes
function FSBaseMission:addMoneyChange(amount, farmId, moneyType, forceShow)
	if self:getIsServer() then
		if self.moneyChanges[moneyType.id] == nil then
			self.moneyChanges[moneyType.id] = {}
		end
		local v385_ = self.moneyChanges[moneyType.id]
		if v385_[farmId] == nil then
			v385_[farmId] = 0
		end
		v385_[farmId] = v385_[farmId] + amount
		if self:getFarmId() == farmId then
			self.hud:addMoneyChange(moneyType, amount)
		end
		if forceShow then
			self:broadcastNotifications(moneyType, farmId)
			return
		end
	else
		Logging.error("addMoneyChange() called on client")
		printCallstack()
	end
end

-- Local values: _, farm
function FSBaseMission:showMoneyChange(moneyType, text, allFarms, farmId)
	if self:getIsServer() then
		if allFarms then
			for _, v391_ in ipairs(g_farmManager:getFarms()) do
				self:broadcastNotifications(moneyType, v391_.farmId, text)
			end
		else
			self:broadcastNotifications(moneyType, farmId or self:getFarmId(), text)
		end
	else
		g_client:getServerConnection():sendEvent(RequestMoneyChangeEvent.new(moneyType))
		return
	end
end

-- Local values: farms, amount
function FSBaseMission:broadcastNotifications(moneyType, farmId, text)
	if moneyType == nil then
		printCallstack()
	end
	local v396_ = self.moneyChanges[moneyType.id]
	local v397_ = v396_ and v396_[farmId]
	if v397_ then
		self:broadcastEventToFarm(MoneyChangeEvent.new(v397_, moneyType, farmId, text), farmId, false)
		if farmId == self:getFarmId() then
			if text ~= nil then
				text = g_i18n:getText(text)
			end
			self.hud:showMoneyChange(moneyType, text)
		end
		v396_[farmId] = nil
	end
end

-- Local values: x, z, y
function FSBaseMission:setMapTargetHotspot(mapHotspot)
	FSBaseMission:superClass().setMapTargetHotspot(self, mapHotspot)
	if self.navigationSystem ~= nil then
		self.navigationSystem:stop()
		if mapHotspot ~= nil then
			local v400_, v401_ = mapHotspot:getWorldPosition()
			local v402_ = getTerrainHeightAtWorldPos(g_terrainNode, v400_, 0, v401_) + 0.25
			self.navigationSystem:navigateTo(v400_, v402_, v401_)
		end
	end
end

function FSBaseMission:showAttachContext(attachableVehicle)
	self.hud:showAttachContext(attachableVehicle:getUppercaseName())
end

-- Local values: fillType
function FSBaseMission:showTipContext(fillTypeIndex)
	local v407_ = g_fillTypeManager:getFillTypeByIndex(fillTypeIndex)
	self.hud:showTipContext(v407_.title)
end

function FSBaseMission:showFuelContext(fuelingVehicle)
	self.hud:showFuelContext(fuelingVehicle:getUppercaseName())
end

function FSBaseMission:showFillDogBowlContext(dogName)
	self.hud:showFillDogBowlContext(dogName)
end

function FSBaseMission:addIngameNotification(notificationType, text)
	self.hud:addSideNotification(notificationType, text)
end

function FSBaseMission:getIsAutoSaveSupported()
	return true
end

function FSBaseMission:doPauseGame()
	FSBaseMission:superClass().doPauseGame(self)
	g_inGameMenu:setIsGamePaused(true)
	g_shopMenu:setIsGamePaused(true)
	if self.growthSystem ~= nil then
		self.growthSystem:setIsGamePaused(true)
	end
end

function FSBaseMission:canUnpauseGame()
	local v417_ = FSBaseMission:superClass().canUnpauseGame(self) and not (self.isSynchronizingWithPlayers or self.dediEmptyPaused)
	if v417_ then
		v417_ = not self.userSigninPaused
	end
	return v417_
end

function FSBaseMission:doUnpauseGame()
	FSBaseMission:superClass().doUnpauseGame(self)
	g_inGameMenu:setIsGamePaused(false)
	g_shopMenu:setIsGamePaused(false)
	self.growthSystem:setIsGamePaused(false)
	if g_dedicatedServer ~= nil then
		g_dedicatedServer:raiseFramerate()
	end
end

function FSBaseMission:getCanAcceptPlayers()
	local v419_ = not (g_gui:getIsDialogVisible() or g_sleepManager:getIsSleeping())
	if v419_ then
		v419_ = not g_savegameController:getIsSaving()
	end
	return v419_
end

function FSBaseMission:onEndMissionCallback()
	if self.state == BaseMission.STATE_FINISHED or self.state == BaseMission.STATE_FAILED then
		self.isExitingGame = true
	end
end

function FSBaseMission:setMissionInfo(missionInfo, missionDynamicInfo)
	g_asyncTaskManager:addTask(function()
		-- upvalues: (copy) self
		resetSplitShapes()
		Logging.info("resetSplitShapes()")
		setUseKinematicSplitShapes(not self:getIsServer())
	end)
	g_asyncTaskManager:addTask(function()
		-- upvalues: (copy) missionInfo, (copy) self
		if missionInfo.isValid then
			local v424_ = TerrainLoadFlags.TEXTURE_CACHE + TerrainLoadFlags.NORMAL_MAP_CACHE + TerrainLoadFlags.OCCLUDER_CACHE
			if missionInfo:getIsDensityMapValid(self) then
				v424_ = v424_ + TerrainLoadFlags.DENSITY_MAPS_USE_LOAD_DIR
			else
				Logging.warning("density map is not valid, ignoring density map from savegame")
			end
			if not GS_IS_MOBILE_VERSION then
				v424_ = v424_ + TerrainLoadFlags.HEIGHT_MAP_USE_LOAD_DIR + TerrainLoadFlags.NORMAL_MAP_CACHE_USE_LOAD_DIR + TerrainLoadFlags.OCCLUDER_CACHE_USE_LOAD_DIR
				if missionInfo:getIsTerrainLodTextureValid(self) then
					v424_ = v424_ + TerrainLoadFlags.TEXTURE_CACHE_USE_LOAD_DIR
					if missionInfo:getIsTerrainLodTextureValid(self) and (g_densityMapHeightManager ~= nil and g_densityMapHeightManager:checkTypeMappings()) then
						v424_ = v424_ + TerrainLoadFlags.LOD_TEXTURE_CACHE
					end
				end
			end
			setTerrainLoadDirectory(missionInfo.savegameDirectory, v424_)
		else
			setTerrainLoadDirectory("", TerrainLoadFlags.GAME_DEFAULT)
		end
	end)
	g_asyncTaskManager:addTask(function()
		-- upvalues: (copy) missionInfo, (copy) self
		if missionInfo:getAreSplitShapesValid(self) then
			local v425_ = missionInfo.savegameDirectory .. "/splitShapes.gmss"
			if fileExists(v425_) and not loadSplitShapesFromFile(v425_) then
				Logging.error("Unable to load split shapes from \'%s\'", v425_)
				return
			end
		elseif missionInfo.isValid then
			Logging.warning("splitshapes are not valid, ignoring splitshapes from savegame")
		end
	end)
	g_asyncTaskManager:addTask(function()
		-- upvalues: (copy) self, (copy) missionInfo, (copy) missionDynamicInfo
		FSBaseMission:superClass().setMissionInfo(self, missionInfo, missionDynamicInfo)
	end)
	g_asyncTaskManager:addTask(function()
		-- upvalues: (copy) self
		if g_soundPlayer ~= nil then
			g_soundPlayer:addEventListener(self)
			if not (GS_IS_CONSOLE_VERSION or GS_IS_MOBILE_VERSION) then
				g_soundPlayer:setStreamingAccessOwner(self)
			end
		end
		self:updateMaxNumHirables()
		self.hud:setIngameMapSize(g_gameSettings:getValue(GameSettings.SETTING.INGAME_MAP_STATE))
	end)
end

function FSBaseMission:updateMaxNumHirables()
	if self.missionDynamicInfo.isMultiplayer then
		if self.missionDynamicInfo.capacity ~= nil then
			local v427_ = self.missionDynamicInfo.capacity
			local v428_ = g_helperManager
			local v429_ = math.min(v427_, v428_:getNumOfHelpers())
			self.maxNumHirables = math.max(4, v429_)
			return
		end
	else
		local v430_ = Platform.gameplay.maxNumHirables
		local v431_ = g_helperManager
		self.maxNumHirables = math.min(v430_, v431_:getNumOfHelpers())
	end
end

-- Local values: success
function FSBaseMission:addLiquidManureLoadingStation(loadingStation)
	if not table.addElement(self.liquidManureLoadingStations, loadingStation) then
		printError("Error: Liquid manure loading station already added")
	end
end

function FSBaseMission:removeLiquidManureLoadingStation(loadingStation)
	table.removeElement(self.liquidManureLoadingStations, loadingStation)
end

-- Local values: success
function FSBaseMission:addManureLoadingStation(loadingStation)
	if not table.addElement(self.manureLoadingStations, loadingStation) then
		printError("Error: Manure loading station already added")
	end
end

function FSBaseMission:removeManureLoadingStation(loadingStation)
	table.removeElement(self.manureLoadingStations, loadingStation)
end

-- Local values: farm
function FSBaseMission:addMoney(amount, farmId, moneyType, addChange, forceShowChange)
	if self:getIsServer() then
		if farmId == 0 then
			printError("Error: Can\'t change money of spectator farm")
			printCallstack()
			return
		end
		local v446_ = g_farmManager:getFarmById(farmId)
		if v446_ == nil then
			return
		end
		v446_:changeBalance(amount, moneyType)
		if addChange then
			self:addMoneyChange(amount, farmId, moneyType, forceShowChange)
			return
		end
	else
		printError("Error: FSBaseMission:addMoney is only allowed on a server")
		printCallstack()
	end
end

-- Local values: farm
function FSBaseMission:addPurchasedMoney(amount)
	if self:getIsServer() then
		local v449_ = g_farmManager:getFarmById(FarmManager.SINGLEPLAYER_FARM_ID)
		if v449_ ~= nil then
			v449_:addPurchasedCoins(amount)
		end
	else
		printError("Error: FSBaseMission:addPurchasedMoney is only allowed on a server")
		printCallstack()
		return
	end
end

-- Local values: farm
function FSBaseMission:getMoney(farmId)
	if farmId == nil then
		farmId = g_localPlayer == nil and FarmManager.SINGLEPLAYER_FARM_ID or g_localPlayer.farmId
	end
	local v452_ = g_farmManager:getFarmById(farmId)
	if v452_ == nil then
		return 0
	end
	self.cacheFarm = v452_
	return v452_.money
end

-- Local values: farm, player
function FSBaseMission:setPlayerPermission(userId, permission, allow)
	if self:getIsServer() then
		local v457_ = g_farmManager:getFarmByUserId(userId)
		if v457_ == nil then
			return
		end
		v457_.userIdToPlayer[userId].permissions[permission] = allow
	end
end

-- Local values: farm, player, _, permission
function FSBaseMission:setPlayerPermissions(userId, permissions)
	if self:getIsServer() then
		local v461_ = g_farmManager:getFarmByUserId(userId)
		if v461_ == nil then
			return
		end
		local v462_ = v461_.userIdToPlayer[userId]
		for _, v463_ in ipairs(Farm.PERMISSIONS) do
			if permissions[v463_] ~= nil then
				v462_.permissions[v463_] = permissions[v463_]
			end
		end
	end
end

-- Local values: user, farm, player
function FSBaseMission:getHasPlayerPermission(permission, connection, farmId, checkClient)
	if checkClient == nil or not checkClient then
		if self:getIsServer() then
			if connection == nil or (connection:getIsLocal() or (connection:getIsServer() or self.userManager:getIsConnectionMasterUser(connection))) then
				return true
			end
		elseif self.isMasterUser then
			return true
		end
		if connection ~= nil and connection:getIsServer() then
			return true
		end
	end
	local v469_
	if connection == nil then
		v469_ = self.userManager:getUserByUserId(self.playerUserId)
	else
		v469_ = self.userManager:getUserByConnection(connection)
	end
	if v469_ == nil then
		return false
	else
		local v470_ = g_farmManager:getFarmByUserId(v469_:getId())
		if v470_ == nil then
			return false
		else
			local v471_ = v470_.userIdToPlayer[v469_:getId()]
			if farmId == nil or v470_.farmId == farmId then
				if v471_ == nil then
					return false
				else
					return v471_.isFarmManager or Utils.getNoNil(v471_.permissions[permission], false)
				end
			else
				return false
			end
		end
	end
end

-- Local values: f
function FSBaseMission:getTerrainDetailPixelsToSqm()
	local v473_ = self.terrainSize / self.terrainDetailMapSize
	return v473_ * v473_
end

-- Local values: f
function FSBaseMission:getFruitPixelsToSqm()
	local v475_ = self.terrainSize / self.fruitMapSize
	return v475_ * v475_
end

function FSBaseMission:getIngameMap()
	return self.hud:getIngameMap()
end

function FSBaseMission:sendNumPlayersToMasterServer(numPlayers)
	if self.missionDynamicInfo.isMultiplayer then
		if g_dedicatedServer ~= nil then
			numPlayers = numPlayers - 1
		end
		masterServerSetServerNumPlayers(numPlayers)
	end
end

function FSBaseMission:sendPlatformSessionIdsToMasterServer(platformSessionIds)
	if self.missionDynamicInfo.isMultiplayer then
		masterServerSetServerPlatformSessionIds(platformSessionIds)
	end
end

function FSBaseMission:setTimeScale(timeScale, noEventSend)
	if timeScale ~= self.missionInfo.timeScale then
		self.missionInfo.timeScale = timeScale
		g_messageCenter:publish(MessageType.TIMESCALE_CHANGED)
		SavegameSettingsEvent.sendEvent(noEventSend)
		if g_server ~= nil then
			EnvironmentTimeEvent.broadcastEvent()
		end
	end
end

function FSBaseMission:setTimeScaleMultiplier(timeScaleMultiplier)
	if timeScaleMultiplier ~= self.missionInfo.timeScaleMultiplier then
		self.missionInfo.timeScaleMultiplier = timeScaleMultiplier
		g_messageCenter:publish(MessageType.TIMESCALE_CHANGED)
	end
end

function FSBaseMission:getEffectiveTimeScale()
	return self.missionInfo:getEffectiveTimeScale()
end

function FSBaseMission:setEconomicDifficulty(economicDifficulty, noEventSend)
	if economicDifficulty ~= self.missionInfo.economicDifficulty then
		self.missionInfo.economicDifficulty = economicDifficulty
		SavegameSettingsEvent.sendEvent(noEventSend)
		Logging.info("Savegame Setting \'economicDifficulty\': %s", EconomicDifficulty.getName(economicDifficulty))
	end
end

function FSBaseMission:setSnowEnabled(isEnabled, noEventSend)
	if isEnabled ~= self.missionInfo.isSnowEnabled then
		self.missionInfo.isSnowEnabled = isEnabled
		SavegameSettingsEvent.sendEvent(noEventSend)
		if not isEnabled then
			self.snowSystem:removeAll(true)
		end
		Logging.info("Savegame Setting \'snowEnabled\': %s", isEnabled)
	end
end

function FSBaseMission:setSavegameName(name, noEventSend)
	if name ~= self.missionInfo.savegameName then
		self.missionInfo.savegameName = name
		SavegameSettingsEvent.sendEvent(noEventSend)
	end
end

function FSBaseMission:startSaveCurrentGame(hiddenUI, blocking)
	self.currentDeviceHasNoSpace = false
	if g_dedicatedServer == nil then
		self.doSaveGameState = InGameMenu.SAVE_STATE_WRITE
		self.doSaveGameBlocking = blocking
		g_inGameMenu:startSavingGameDisplay()
	else
		self:saveSavegame(blocking)
	end
	self:accumulatePlayedTime()
	g_gameSettings:save()
end

-- Local values: now, deltaMs, deltaSeconds, total
function FSBaseMission:accumulatePlayedTime()
	local v499_ = g_time
	local v500_ = v499_ - (self.lastPlayTimeSampleTime or v499_)
	self.lastPlayTimeSampleTime = v499_
	if v500_ > 0 then
		local v501_ = v500_ / 1000
		local v502_ = math.floor(v501_)
		local v503_ = g_gameSettings:getValue(GameSettings.SETTING.TOTAL_PLAYED_SECONDS)
		local v504_ = v503_ < 0 and 0 or v503_
		g_gameSettings:setValue(GameSettings.SETTING.TOTAL_PLAYED_SECONDS, v504_ + v502_)
	end
end

function FSBaseMission:saveSavegame(blocking)
	if not g_sleepManager:getIsSleeping() then
		if GS_IS_CONSOLE_VERSION or GS_IS_MOBILE_VERSION then
			self.isSaving = true
			self:pauseGame()
		end
		g_savegameController:saveSavegame(self.missionInfo, blocking)
	end
end

function FSBaseMission:setGrowthMode(mode, noEventSend)
	self.growthSystem:setGrowthMode(mode, noEventSend)
	g_inGameMenu:onGrowthModeChanged()
end

function FSBaseMission:setFixedSeasonalVisuals(period, noEventSend)
	if period ~= self.missionInfo.fixedSeasonalVisuals then
		self.environment:setFixedPeriod(period)
		SavegameSettingsEvent.sendEvent(noEventSend)
		Logging.info("Savegame Setting \'fixedSeasonalVisuals\': %s", period)
	end
end

function FSBaseMission:setPlannedDaysPerPeriod(days, noEventSend)
	local v516_ = Environment.MAX_DAYS_PER_PERIOD
	local v517_ = math.clamp(days, 1, v516_)
	if v517_ ~= self.missionInfo.plannedDaysPerPeriod then
		self.environment:setPlannedDaysPerPeriod(v517_)
		SavegameSettingsEvent.sendEvent(noEventSend)
		Logging.info("Savegame Setting \'plannedDaysPerPeriod\': %s", v517_)
	end
end

function FSBaseMission:setFruitDestructionEnabled(isEnabled, noEventSend)
	if isEnabled ~= self.missionInfo.fruitDestruction then
		self.missionInfo.fruitDestruction = isEnabled
		SavegameSettingsEvent.sendEvent(noEventSend)
		Logging.info("Savegame Setting \'fruitDesctructionEnabled\': %s", isEnabled)
	end
end

function FSBaseMission:setPlowingRequiredEnabled(isEnabled, noEventSend)
	if isEnabled ~= self.missionInfo.plowingRequiredEnabled then
		self.missionInfo.plowingRequiredEnabled = isEnabled
		SavegameSettingsEvent.sendEvent(noEventSend)
		Logging.info("Savegame Setting \'plowingRequiredEnabled\': %s", isEnabled)
		g_inGameMenu:onSoilSettingChanged()
	end
end

function FSBaseMission:setStonesEnabled(isEnabled, noEventSend)
	if isEnabled ~= self.missionInfo.stonesEnabled then
		self.missionInfo.stonesEnabled = isEnabled
		SavegameSettingsEvent.sendEvent(noEventSend)
		Logging.info("Savegame Setting \'stonesEnabled\': %s", isEnabled)
		g_inGameMenu:onSoilSettingChanged()
	end
end

function FSBaseMission:setLimeRequired(isEnabled, noEventSend)
	if isEnabled ~= self.missionInfo.limeRequired then
		self.missionInfo.limeRequired = isEnabled
		SavegameSettingsEvent.sendEvent(noEventSend)
		Logging.info("Savegame Setting \'limeRequired\': %s", isEnabled)
		g_inGameMenu:onSoilSettingChanged()
	end
end

function FSBaseMission:setWeedsEnabled(isEnabled, noEventSend)
	if isEnabled ~= self.missionInfo.weedsEnabled then
		self.missionInfo.weedsEnabled = isEnabled
		self.growthSystem:onWeedGrowthChanged()
		SavegameSettingsEvent.sendEvent(noEventSend)
		Logging.info("Savegame Setting \'weedsEnabled\': %s", isEnabled)
		g_inGameMenu:onSoilSettingChanged()
	end
end

function FSBaseMission:setStopAndGoBraking(isEnabled, noEventSend)
	if isEnabled ~= self.missionInfo.stopAndGoBraking then
		self.missionInfo.stopAndGoBraking = isEnabled
		SavegameSettingsEvent.sendEvent(noEventSend)
	end
end

function FSBaseMission:setTrailerFillLimit(isEnabled, noEventSend)
	if isEnabled ~= self.missionInfo.trailerFillLimit then
		self.missionInfo.trailerFillLimit = isEnabled
		SavegameSettingsEvent.sendEvent(noEventSend)
	end
end

function FSBaseMission:setDisasterDestructionState(state, noEventSend)
	if state ~= self.missionInfo.disasterDestructionState then
		self.missionInfo.disasterDestructionState = state
		SavegameSettingsEvent.sendEvent(noEventSend)
	end
end

function FSBaseMission:setAutoSaveInterval(intervalMinutes, noEventSend)
	if intervalMinutes ~= g_autoSaveManager:getInterval() then
		g_autoSaveManager:setInterval(intervalMinutes)
		SavegameSettingsEvent.sendEvent(noEventSend)
	end
end

function FSBaseMission:setTrafficEnabled(isEnabled, noEventSend)
	if isEnabled ~= self.missionInfo.trafficEnabled then
		self.missionInfo.trafficEnabled = isEnabled
		SavegameSettingsEvent.sendEvent(noEventSend)
		if self.trafficSystem ~= nil then
			self.trafficSystem:setEnabled(self.missionInfo.trafficEnabled)
			if not self.missionInfo.trafficEnabled then
				self.trafficSystem:reset()
			end
			Logging.info("Savegame Setting \'trafficEnabled\': %s", isEnabled)
		end
	end
end

function FSBaseMission:setDirtInterval(dirtInterval, noEventSend)
	if dirtInterval ~= self.missionInfo.dirtInterval then
		self.missionInfo.dirtInterval = dirtInterval
		SavegameSettingsEvent.sendEvent(noEventSend)
		Logging.info("Savegame Setting \'dirtInterval\': %d", dirtInterval)
	end
end

function FSBaseMission:setFuelUsage(fuelUsage, noEventSend)
	if fuelUsage ~= self.missionInfo.fuelUsage then
		self.missionInfo.fuelUsage = fuelUsage
		SavegameSettingsEvent.sendEvent(noEventSend)
		Logging.info("Savegame Setting \'fuelUsage\': %d", fuelUsage)
	end
end

function FSBaseMission:setHelperBuyFuel(helperBuyFuel, noEventSend)
	if helperBuyFuel ~= self.missionInfo.helperBuyFuel then
		self.missionInfo.helperBuyFuel = helperBuyFuel
		SavegameSettingsEvent.sendEvent(noEventSend)
	end
end

function FSBaseMission:setHelperBuySeeds(helperBuySeeds, noEventSend)
	if helperBuySeeds ~= self.missionInfo.helperBuySeeds then
		self.missionInfo.helperBuySeeds = helperBuySeeds
		SavegameSettingsEvent.sendEvent(noEventSend)
	end
end

function FSBaseMission:setHelperBuyFertilizer(helperBuyFertilizer, noEventSend)
	if helperBuyFertilizer ~= self.missionInfo.helperBuyFertilizer then
		self.missionInfo.helperBuyFertilizer = helperBuyFertilizer
		SavegameSettingsEvent.sendEvent(noEventSend)
	end
end

-- Local values: loadingStation
function FSBaseMission:setHelperSlurrySource(helperSlurrySource, noEventSend)
	if helperSlurrySource ~= self.missionInfo.helperSlurrySource then
		local v565_ = self.liquidManureLoadingStations[helperSlurrySource - 2]
		if v565_ == nil then
			if helperSlurrySource == 2 then
				Logging.devInfo("Set Helper Slurry Source to \'Buy\'")
			elseif helperSlurrySource == 1 then
				Logging.devInfo("Set Helper Slurry Source to \'None\'")
			end
		else
			Logging.devInfo("Set Helper Slurry Source to \'%s\'", v565_:getName())
		end
		self.missionInfo.helperSlurrySource = helperSlurrySource
		SavegameSettingsEvent.sendEvent(noEventSend)
	end
end

-- Local values: loadingStation
function FSBaseMission:setHelperManureSource(helperManureSource, noEventSend)
	if helperManureSource ~= self.missionInfo.helperManureSource then
		self.missionInfo.helperManureSource = helperManureSource
		local v569_ = self.manureLoadingStations[helperManureSource - 2]
		if v569_ == nil then
			if helperManureSource == 2 then
				Logging.devInfo("Set Helper Manure Source to \'Buy\'")
			elseif helperManureSource == 1 then
				Logging.devInfo("Set Helper Manure Source to \'None\'")
			end
		else
			Logging.devInfo("Set Helper Manure Source to %s", v569_:getName())
		end
		SavegameSettingsEvent.sendEvent(noEventSend)
	end
end

function FSBaseMission:setAutomaticMotorStartEnabled(isEnabled, noEventSend)
	if isEnabled ~= self.missionInfo.automaticMotorStartEnabled then
		self.missionInfo.automaticMotorStartEnabled = isEnabled
		SavegameSettingsEvent.sendEvent(noEventSend)
	end
end

function FSBaseMission:addKnownSplitShape(shape) end

function FSBaseMission:removeKnownSplitShape(shape) end

-- Local values: _, doghouse
function FSBaseMission:getDoghouse(farmId)
	for _, v575_ in pairs(self.doghouses) do
		if v575_:getOwnerFarmId() == farmId then
			return v575_
		end
	end
	return nil
end

function FSBaseMission:onDayChanged() end

function FSBaseMission:onHourChanged()
	if self:getIsServer() then
		self:showMoneyChange(MoneyType.AI, nil, true)
	end
end

function FSBaseMission:onMinuteChanged() end

function FSBaseMission:pauseRadio()
	if g_soundPlayer ~= nil then
		self:setRadioActionEventsState(false)
		if self.hud ~= nil then
			self.hud:hideTopNotification()
		end
		g_soundPlayer:pause()
	end
end

-- Local values: hasStartedPlaying
function FSBaseMission:playRadio()
	if g_soundPlayer ~= nil and g_gameSettings:getValue(GameSettings.SETTING.RADIO_IS_ACTIVE) then
		self:setRadioActionEventsState((g_soundPlayer:play()))
	end
end

function FSBaseMission:getIsRadioPlaying()
	if g_soundPlayer == nil then
		return false
	else
		return g_soundPlayer:getIsPlaying()
	end
end

-- Local values: rating
function FSBaseMission:onSoundPlayerChange(channelName, itemName, isOnlineStream, iconFilename)
	if not GS_IS_MOBILE_VERSION then
		self:addGameNotification(channelName, itemName, not isOnlineStream and "" or g_i18n:getText("ui_radioRating"), iconFilename, 4000)
	end
	g_messageCenter:publish(MessageType.RADIO_CHANNEL_CHANGE, channelName, itemName, isOnlineStream)
end

function FSBaseMission:onSoundPlayerStreamAccess()
	if g_gameSettings:getValue(GameSettings.SETTING.IS_SOUND_PLAYER_STREAM_ACCESS_ALLOWED) then
		self:onStreamAccessAllowed(true)
	else
		YesNoDialog.show(self.onStreamAccessAllowed, self, g_i18n:getText("ui_radioRating") .. "\n\n" .. g_i18n:getText("ui_continueQuestion"))
	end
end

function FSBaseMission:onStreamAccessAllowed(yes)
	if g_soundPlayer ~= nil then
		if yes then
			g_gameSettings:setValue(GameSettings.SETTING.IS_SOUND_PLAYER_STREAM_ACCESS_ALLOWED, true, true)
		end
		g_soundPlayer:setStreamAccessAllowed(yes)
	end
end

function FSBaseMission:setMoneyUnit(unit)
	FSBaseMission:superClass().setMoneyUnit(self, unit)
	self.hud:setMoneyUnit(unit)
end

-- Local values: vehicleCombos, vehicles, attachedVehicles, addVehiclePositions, _, attachedVehicle, attacherVehicle, k, data, k, data, x, z, y, xRot, yRot, zRot, k, data, _, combo
function FSBaseMission:teleportVehicle(teleportVehicle, targetX, targetZ, rotY)
	self.isTeleporting = true
	local v_u_593_ = {}
	local v_u_594_ = {}
	local v_u_595_ = {}
	local function v_u_616_(p596_)
		-- upvalues: (copy) teleportVehicle, (copy) v_u_594_, (copy) v_u_616_, (copy) v_u_595_, (copy) v_u_593_
		local v597_, v598_, v599_ = getWorldTranslation(p596_.rootNode)
		local v600_, v601_, v602_ = getWorldRotation(p596_.rootNode)
		local v603_, v604_, v605_ = worldToLocal(teleportVehicle.rootNode, v597_, v598_, v599_)
		local v606_, v607_, v608_ = worldRotationToLocal(teleportVehicle.rootNode, v600_, v601_, v602_)
		local v609_ = v_u_594_
		table.insert(v609_, {
			["vehicle"] = p596_,
			["offset"] = { v603_, v604_, v605_ },
			["rotationOffset"] = { v606_, v607_, v608_ }
		})
		if p596_.getAttachedImplements ~= nil then
			local v610_ = p596_:getAttachedImplements()
			for _, v611_ in ipairs(v610_) do
				if not v611_.object:getIsAdditionalAttachment() then
					v_u_616_(v611_.object)
					local v612_ = v_u_595_
					local v613_ = v611_.object
					table.insert(v612_, v613_)
					local v614_ = v_u_593_
					local v615_ = {
						["vehicle"] = p596_,
						["object"] = v611_.object,
						["jointDescIndex"] = v611_.jointDescIndex,
						["inputAttacherJointDescIndex"] = v611_.object:getActiveInputAttacherJointDescIndex()
					}
					table.insert(v614_, v615_)
				end
			end
		end
	end
	v_u_616_(teleportVehicle)
	for _, v617_ in ipairs(v_u_595_) do
		local v618_ = v617_:getAttacherVehicle()
		if v618_ ~= nil then
			v618_:detachImplementByObject(v617_, true)
		end
	end
	for _, v619_ in pairs(v_u_594_) do
		v619_.vehicle:removeFromPhysics()
	end
	for v620_, v621_ in pairs(v_u_594_) do
		local v622_ = 0
		local v623_ = 0
		local v624_, v625_, v626_, v627_
		if v620_ > 1 then
			local v628_ = localToWorld
			local v629_ = teleportVehicle.rootNode
			local v630_ = v621_.offset
			v624_, v625_, v626_ = v628_(v629_, unpack(v630_))
			local v631_ = localRotationToWorld
			local v632_ = teleportVehicle.rootNode
			local v633_ = v621_.rotationOffset
			v622_, v627_, v623_ = v631_(v632_, unpack(v633_))
		else
			v625_ = getTerrainHeightAtWorldPos(g_terrainNode, targetX, 300, targetZ) + 0.5
			v627_ = rotY
			v626_ = targetZ
			v624_ = targetX
		end
		v621_.vehicle:setAbsolutePosition(v624_, v625_, v626_, v622_, v627_, v623_)
	end
	for _, v634_ in pairs(v_u_594_) do
		v634_.vehicle:addToPhysics()
	end
	for _, v635_ in pairs(v_u_593_) do
		v635_.vehicle:attachImplement(v635_.object, v635_.inputAttacherJointDescIndex, v635_.jointDescIndex, true)
	end
	self.isTeleporting = false
end

function FSBaseMission:consoleCommandCheatMoney(amount, farmId)
	if not (self:getIsServer() or self.isMasterUser) then
		return "gsMoneyAdd is only available for server and/or admins"
	end
	local v639_ = tonumber(amount) or 10000000
	local v640_ = math.clamp(v639_, -1000000000, 1000000000)
	local v641_ = tonumber(farmId) or g_localPlayer.farmId
	if g_farmManager:getFarmById(v641_) == nil then
		return string.format("No farm for id \'%s\'", v641_)
	end
	if self:getIsServer() then
		self:addMoney(v640_, v641_, MoneyType.OTHER, true, true)
	else
		g_client:getServerConnection():sendEvent(CheatMoneyEvent.new(v640_, v641_))
	end
	return string.format("Added money %d. Use \'gsMoneyAdd <amount> <farmId>\' to add or remove a custom amount to a specific farm", v640_)
end

-- Local values: csvFile, specTypes, file, header, _, spec, storeItems, _, storeItem, brand, brushType, brushCategory, brushTab, data, _, spec, value
function FSBaseMission:consoleCommandExportStoreItems()
	local v642_ = getUserProfileAppPath() .. "storeItems.csv"
	local v643_ = g_storeManager:getSpecTypes()
	local v644_ = io.open(v642_, "w")
	if v644_ == nil then
		printError(string.format("Error: Unable to create csv file \'%s\'", v642_))
	else
		local v645_ = "xmlFilename;category;brand;brandTitle;name;price;lifetime;dailyUpkeep;showInStore;brushType;brushCategory;brushTab;"
		for _, v646_ in ipairs(v643_) do
			v645_ = v645_ .. v646_.name .. ";"
		end
		v644_:write(v645_ .. "\n")
		local v647_ = g_storeManager:getItems()
		for _, v648_ in pairs(v647_) do
			local v649_ = g_brandManager:getBrandByIndex(v648_.brandIndex)
			local v650_, v651_, v652_
			if v648_.brush == nil then
				v650_ = ""
				v651_ = ""
				v652_ = ""
			else
				v650_ = v648_.brush.type
				v651_ = v648_.brush.category.name
				v652_ = v648_.brush.tab.name
			end
			local v653_ = string.format("%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;", v648_.xmlFilename, v648_.categoryName, v649_.name, v649_.title, v648_.name, v648_.price, v648_.lifetime, v648_.dailyUpkeep, v648_.showInStore, v650_, v651_, v652_)
			StoreItemUtil.loadSpecsFromXML(v648_)
			for _, v654_ in ipairs(v643_) do
				local v655_
				if v654_.species == v648_.species then
					v655_ = v654_.getValueFunc(v648_, nil)
				else
					v655_ = nil
				end
				local v656_ = (v655_ == nil or type(v655_) == "table") and "" or v655_
				if v654_.name == "placeableSlots" then
					v656_ = string.gsub(v656_, " %$SLOTS%$", "")
				end
				v653_ = v653_ .. string.trim((tostring(v656_))) .. ";"
			end
			v644_:write(v653_ .. "\n")
		end
		printf("Exported %i store items to \'%s\'", #v647_, v642_)
		v644_:close()
	end
end

-- Local values: _, greatDemand, _, greatDemand
function FSBaseMission:consoleStartGreatDemand()
	for _, v658_ in pairs(self.economyManager.greatDemands) do
		self.economyManager:stopGreatDemand(v658_)
	end
	for _, v659_ in pairs(self.economyManager.greatDemands) do
		v659_:setUpRandomDemand(true, self.economyManager.greatDemands, self)
		v659_.demandStart.day = g_currentMission.environment.currentDay
		v659_.demandStart.hour = g_currentMission.environment.currentHour + 1
	end
	return "Great demand starts in the next hour..."
end

-- Local values: usage, targetX, targetZ, farmland, worldSizeX, worldSizeZ, playerVehicle, y, terrainHeight, raycastLength, _, _, colY, _, _, ry, _
function FSBaseMission:consoleCommandTeleport(farmlandIdOrX, zPos, useWorldCoords)
	local v664_ = tonumber(farmlandIdOrX)
	local v665_ = tonumber(zPos)
	local v666_ = Utils.stringToBoolean(useWorldCoords)
	if v664_ == nil then
		return "Error: Invalid farmland-id or x-position\nUsage: gsTeleport xPos|farmland [zPos] [useWorldCoords]\n  if zPos is not given first parameter is used as field id.\n  set useWorldCoords to true if given coordinates are in 3D/world (0 0 = map center) instead of minimap (0 0 = map corner) space."
	end
	if v665_ == nil then
		local v667_ = g_farmlandManager:getFarmlandById(v664_)
		if v667_ == nil then
			return string.format("Error: Invalid farmland id \'%s\'\n%s", v664_, "Usage: gsTeleport xPos|farmland [zPos] [useWorldCoords]\n  if zPos is not given first parameter is used as field id.\n  set useWorldCoords to true if given coordinates are in 3D/world (0 0 = map center) instead of minimap (0 0 = map corner) space.")
		end
		v664_, v665_ = v667_:getTeleportPosition()
	elseif not v666_ then
		local v668_ = self.terrainSize
		local v669_ = self.terrainSize
		v664_ = math.clamp(v664_, 0, v668_) - v668_ * 0.5
		v665_ = math.clamp(v665_, 0, v669_) - v669_ * 0.5
	end
	local v670_ = g_localPlayer:getCurrentVehicle()
	if v670_ == nil then
		local v671_ = getTerrainHeightAtWorldPos(g_terrainNode, v664_, 0, v665_)
		local v672_ = getTerrainHeightAtWorldPos(g_terrainNode, v664_, 0, v665_)
		local _, _, v673_, _ = RaycastUtil.raycastClosest(v664_, v672_ + 30, v665_, 0, -1, 0, 30, CollisionFlag.STATIC_OBJECT + CollisionFlag.ROAD + CollisionFlag.BUILDING)
		local v674_ = (v673_ or v672_) + 0.1
		local v675_ = math.max(v674_, v671_)
		g_localPlayer:teleportTo(v664_, v675_ + 0.1, v665_)
	else
		local _, v676_, _ = getWorldRotation(v670_.rootNode)
		if self:getIsServer() then
			self:teleportVehicle(v670_, v664_, v665_, v676_)
		else
			g_client:getServerConnection():sendEvent(VehicleTeleportEvent.new(v670_, v664_, v665_, v676_))
		end
	end
	return string.format("Teleported to world coordinates x=%d z=%d", v664_, v665_)
end

-- Local values: finishedCallback
function FSBaseMission:consoleActivateCameraPath(cameraPathIndex)
	local v679_ = tonumber(cameraPathIndex)
	if v679_ == nil or (v679_ < 1 or #self.cameraPaths < v679_) then
		return "Invalid argument. Argument: cameraPathIndex"
	end
	if self.currentCameraPath ~= nil then
		self.currentCameraPath:deactivate()
	end
	self.currentCameraPath = self.cameraPaths[v679_]
	function self.currentCameraPath.finishedCallback()
		-- upvalues: (copy) self
		print("camera path finished")
		self.currentCameraPath:deactivate()
	end
	self.currentCameraPath:activate()
	self:addUpdateable(self.currentCameraPath)
	return "Camera path activated"
end

function FSBaseMission:consoleCommandSaveGame()
	self:saveSavegame(true)
end

function FSBaseMission:consoleCommandDisplacementDebug()
	DebugDisplacementDialog.show()
end

-- Local values: terrainRootNode, fieldGroundSystem, displacementMapId, displacementFirstChannel, displacementNumChannels, modifier, value
function FSBaseMission:consoleCommandDisplacementReset()
	local v682_ = g_terrainNode
	local v683_ = self.fieldGroundSystem
	local v684_, v685_, v686_ = v683_:getDisplacementData()
	DensityMapModifier.new(v684_, v685_, v686_, v682_):executeSet((v683_:getDisplacementResetValue()))
end

-- Local values: triggerTopDistanceToTerrainThresholdMin, triggerTopDistanceToTerrainThresholdMax
function FSBaseMission:consoleCommandValidateUnloadTriggers()
	I3DUtil.iterateRecursively(getRootNode(), function(p_u_687_)
		if getHasClassId(p_u_687_, ClassIds.SHAPE) and (getRigidBodyType(p_u_687_) ~= RigidBodyType.DYNAMIC and (getHasCollision(p_u_687_) and CollisionFlag.getHasGroupFlagSet(p_u_687_, CollisionFlag.FILLABLE))) then
			local v688_ = g_currentMission:getNodeObject(p_u_687_)
			if v688_ ~= nil and (v688_.isa ~= nil and v688_:isa(Vehicle)) then
				return
			end
			local v_u_689_, v_u_690_, v_u_691_ = getWorldTranslation(p_u_687_)
			local v692_ = {}
			local v_u_693_ = 0.03
			local v_u_694_ = 0.2
			
-- Upvalues: node, x, z, y, triggerTopDistanceToTerrainThresholdMin, triggerTopDistanceToTerrainThresholdMax
-- Local values: ty, diff, col, _, colH
function v692_.onRaycastHit(_, actorId, hx, hy, hz)
				-- upvalues: (copy) p_u_687_, (copy) v_u_689_, (copy) v_u_691_, (copy) v_u_690_, (copy) v_u_693_, (copy) v_u_694_
				if actorId == g_terrainNode then
					Logging.error("Terrain is above trigger/unloadFillNode %q at %d %d", I3DUtil.getNodePath(p_u_687_), v_u_689_, v_u_691_)
					return false
				end
				if actorId ~= p_u_687_ then
					return true
				end
				local v697_ = getTerrainHeightAtWorldPos(g_terrainNode, v_u_689_, v_u_690_, v_u_691_)
				if hy - v697_ < 0.03 then
					Logging.warning("Terrain very close to trigger %q (trigger top face %.4f, terrain %.4f) at %d %d", I3DUtil.getNodePath(p_u_687_), hy, v697_, v_u_689_, v_u_691_)
					return false
				end
				local v698_, _, v699_ = RaycastUtil.raycastClosest(v_u_689_, v_u_690_ + 3, v_u_691_, 0, -1, 0, 5, CollisionFlag.STATIC_OBJECT + CollisionFlag.ROAD + CollisionFlag.AI_DRIVABLE + CollisionFlag.TERRAIN)
				if v699_ == nil or (v698_ == p_u_687_ or hy - v699_ <= 0.2) then
					return false
				end
				Logging.warning("trigger %q too far from terrain (trigger top face %.4f, col %s %.4f) at %d %d", I3DUtil.getNodePath(p_u_687_), hy, getName(v698_), v697_, v_u_689_, v_u_691_)
				return false
			end
			raycastAll(v_u_689_, v_u_690_ + 3, v_u_691_, 0, -1, 0, 5, "onRaycastHit", v692_, CollisionFlag.FILLABLE + CollisionFlag.TERRAIN)
		end
	end)
end

function FSBaseMission:consoleCommandRunDSDensityMapUtil()
	FSDensityMapUtil.runBenchmark()
end

-- Local values: _, data
function FSBaseMission:consoleCommandTogglePhysicsStressTest()
	if self.debugPhysicsStressTest == nil then
		self.debugPhysicsStressTest = true
		self.debugPhysicsStressTestNextTime = 0
		self.debugPhysicsStressTestNumBlocksPerRow = 10
		self.debugPhysicsStressTestObjects = {}
		self.debugPhysicsStressTestFilename = "data/shared/assets/physicsTest.i3d"
		g_i3DManager:pinSharedI3DFileInCache(self.debugPhysicsStressTestFilename)
		function self.debugPhysicsStressTestSpawn()
			-- upvalues: (copy) self
			if g_time > self.debugPhysicsStressTestNextTime then
				local v701_, v702_, v703_ = g_localPlayer:getPosition()
				local v704_, v705_ = g_localPlayer:getCurrentFacingDirection()
				local v706_ = v701_ + v704_ * 4
				local v707_ = v702_ + 1
				local v708_ = v703_ + v705_ * 4
				for v709_ = 1, self.debugPhysicsStressTestNumBlocksPerRow do
					for v710_ = 1, self.debugPhysicsStressTestNumBlocksPerRow do
						for v711_ = 1, self.debugPhysicsStressTestNumBlocksPerRow do
							local v712_ = v706_ + v709_ * 0.25
							local v713_ = v707_ + v710_ * 0.25
							local v714_ = v708_ + v711_ * 0.25
							local v715_, v716_ = g_i3DManager:loadSharedI3DFile(self.debugPhysicsStressTestFilename, false, true)
							setName(v715_, "DebugPhysicsStressTest_" .. v715_)
							link(getRootNode(), v715_)
							setWorldTranslation(v715_, v712_, v713_, v714_)
							local v717_ = self.debugPhysicsStressTestObjects
							table.insert(v717_, {
								["node"] = v715_,
								["requestId"] = v716_
							})
						end
					end
				end
				self.debugPhysicsStressTestNextTime = g_time + 3000
			end
		end
		function self.debugPhysicsStressTestRemove(p718_)
			-- upvalues: (copy) self
			local v719_ = p718_ / 16.666666666666668 * 8
			local v720_ = math.floor(v719_)
			local v721_ = 0
			while v721_ < v720_ do
				if #self.debugPhysicsStressTestObjects > 200 then
					local v722_ = math.random(1, #self.debugPhysicsStressTestObjects)
					local v723_ = table.remove(self.debugPhysicsStressTestObjects, v722_)
					if v723_ ~= nil then
						delete(v723_.node)
						g_i3DManager:releaseSharedI3DFile(v723_.requestId)
					end
				end
				v721_ = v721_ + 1
			end
		end
	else
		for _, v724_ in ipairs(self.debugPhysicsStressTestObjects) do
			delete(v724_.node)
			g_i3DManager:releaseSharedI3DFile(v724_.requestId)
		end
		g_i3DManager:unpinSharedI3DFileInCache(self.debugPhysicsStressTestFilename)
		self.debugPhysicsStressTestObjects = nil
		self.debugPhysicsStressTest = nil
		self.debugPhysicsStressTestNextTime = nil
		self.debugPhysicsStressTestNumBlocksPerRow = nil
		self.debugPhysicsStressTestFilename = nil
		self.debugPhysicsStressTestRemove = nil
		self.debugPhysicsStressTestSpawn = nil
	end
end

-- Local values: i
function FSBaseMission:updateFoundHelpIcons()
	if self.helpIconsBase ~= nil then
		local v726_ = self.missionInfo.foundHelpIcons
		for v727_ = 1, string.len(v726_) do
			local v728_ = self.missionInfo.foundHelpIcons
			if string.sub(v728_, v727_, v727_) == "1" then
				self.helpIconsBase:deleteHelpIcon(v727_)
			end
		end
	end
end

-- Local values: i
function FSBaseMission:removeAllHelpIcons()
	if self.helpIconsBase ~= nil then
		local v730_ = self.missionInfo.foundHelpIcons
		for v731_ = 1, string.len(v730_) do
			self.helpIconsBase:deleteHelpIcon(v731_)
		end
	end
end

-- Local values: k, _
function FSBaseMission:playerOwnsAllFields()
	for v732_, _ in pairs(g_farmlandManager:getFarmlands()) do
		g_client:getServerConnection():sendEvent(FarmlandStateEvent.new(v732_, 1, 0))
	end
end

-- Local values: _, user, connection
function FSBaseMission:broadcastEventToMasterUser(event, ignoreConnection)
	for _, v736_ in pairs(self.userManager:getMasterUsers()) do
		local v737_ = v736_:getConnection()
		if v737_ ~= ignoreConnection then
			v737_:sendEvent(event)
		end
	end
	event:delete()
end

function FSBaseMission:broadcastMissionDynamicInfo(connection)
	local v740_ = self:getIsServer()
	assert(v740_, "broadcastMissionDynamicInfo call is only allowed on Server")
	self:broadcastEventToMasterUser(MissionDynamicInfoEvent.new(), connection)
end

function FSBaseMission:updateMissionDynamicInfo(serverName, capacity, password, autoAccept, allowOnlyFriends, allowCrossPlay)
	if serverName ~= "" and g_dedicatedServer == nil then
		self.missionDynamicInfo.serverName = serverName
	end
	if g_dedicatedServer == nil then
		self.missionDynamicInfo.capacity = capacity
	end
	self.missionDynamicInfo.password = password
	self.missionDynamicInfo.autoAccept = autoAccept or g_dedicatedServer ~= nil
	self.missionDynamicInfo.allowOnlyFriends = allowOnlyFriends
	self.missionDynamicInfo.allowCrossPlay = allowCrossPlay
	self:updateMaxNumHirables()
	if g_dedicatedServer ~= nil then
		self:updateDedicatedServerXML()
	end
end

-- Local values: userCount, missionDynamicInfo
function FSBaseMission:updateMasterServerInfo(connection)
	if self:getIsServer() then
		local v750_ = self.userManager:getNumberOfUsers()
		if g_dedicatedServer ~= nil then
			v750_ = v750_ - 1
		end
		local v751_ = g_currentMission.missionDynamicInfo
		masterServerSetServerInfo(v751_.serverName, v751_.password, v751_.capacity, v750_, v751_.allowOnlyFriends)
		self:broadcastMissionDynamicInfo(connection)
	end
end

-- Local values: info
function FSBaseMission:updateDedicatedServerXML()
	if g_dedicatedServer ~= nil then
		local v753_ = self.missionDynamicInfo
		g_dedicatedServer:updateServerInfo(v753_.serverName, v753_.password, v753_.capacity)
	end
end

function FSBaseMission:setConnectionLostState(state)
	self.shapeLostState = state
end

function FSBaseMission:addMapHotspot(hotspot)
	return self.hud:addMapHotspot(hotspot)
end

function FSBaseMission:removeMapHotspot(hotspot)
	if self.hud ~= nil then
		self.hud:removeMapHotspot(hotspot)
	end
end

function FSBaseMission:onShowHelpIconsChanged(isVisible)
	if self.helpIconsBase ~= nil then
		self.helpIconsBase:showHelpIcons(isVisible)
	end
end

-- Local values: isRadioPlayingSettingActive, playerVehicle, canPlayRadioNow
function FSBaseMission:onRadioVehicleOnlyChanged(isVehicleOnly)
	local v764_ = g_gameSettings:getValue(GameSettings.SETTING.RADIO_IS_ACTIVE)
	local v765_ = g_localPlayer:getCurrentVehicle()
	local v766_ = not isVehicleOnly
	if v766_ then
		isVehicleOnly = v766_
	elseif isVehicleOnly then
		if v765_ == nil then
			isVehicleOnly = false
		else
			isVehicleOnly = v765_.supportsRadio
		end
	end
	if v764_ then
		if isVehicleOnly then
			if not self:getIsRadioPlaying() then
				self:playRadio()
				return
			end
		else
			self:pauseRadio()
		end
	end
end

-- Local values: isVehicleOnly, playerVehicle
function FSBaseMission:onRadioIsActiveChanged(isActive)
	if isActive then
		local v769_ = g_gameSettings:getValue(GameSettings.SETTING.RADIO_VEHICLE_ONLY)
		local v770_ = g_localPlayer:getCurrentVehicle()
		if not v769_ or v769_ and (v770_ ~= nil and v770_.supportsRadio) then
			self:playRadio()
		end
	else
		self:pauseRadio()
	end
end

-- Local values: _, eventId
function FSBaseMission:setRadioActionEventsState(isActive)
	for _, v773_ in pairs(self.radioEvents) do
		g_inputBinding:setActionEventActive(v773_, isActive)
	end
end

function FSBaseMission:subscribeMessages()
	g_messageCenter:subscribe(SaveEvent, self.startSaveCurrentGame, self)
	g_messageCenter:subscribe(MessageType.PLAYER_FARM_CHANGED, self.notifyPlayerFarmChanged, self)
	g_messageCenter:subscribe(MessageType.USER_ADDED, self.onUserAdded, self)
	g_messageCenter:subscribe(MessageType.USER_REMOVED, self.onUserRemoved, self)
	g_messageCenter:subscribe(MessageType.MASTERUSER_ADDED, self.onMasterUserAdded, self)
	g_messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.IS_TRAIN_TABBABLE], self.setTrainSystemTabbable, self)
	g_messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.SHOW_HELP_ICONS], self.onShowHelpIconsChanged, self)
	g_messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.RADIO_VEHICLE_ONLY], self.onRadioVehicleOnlyChanged, self)
	g_messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.RADIO_IS_ACTIVE], self.onRadioIsActiveChanged, self)
	g_messageCenter:subscribe(MessageType.APP_SUSPENDED, self.onAppSuspended, self)
	g_messageCenter:subscribe(MessageType.APP_RESUMED, self.onAppResumed, self)
	g_messageCenter:subscribe(MessageType.WINDOW_SIZE_CHANGED, self.onWindowSizeChanged, self)
	g_messageCenter:subscribe(MessageType.GUIDED_TOUR_STARTED, self.onGuidedTourStarted, self)
	g_messageCenter:subscribe(MessageType.GUIDED_TOUR_FINISHED, self.onGuidedTourFinished, self)
	g_messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.USE_COLORBLIND_MODE], self.setColorBlindMode, self)
end

function FSBaseMission:onWindowSizeChanged()
	if self.isLoaded then
		if GS_IS_MOBILE_VERSION and not g_savegameController:getIsSaving() then
			self:saveSavegame(true)
		end
	end
end

function FSBaseMission:onAppSuspended()
	if self.isLoaded then
		if GS_IS_MOBILE_VERSION and not g_savegameController:getIsSaving() then
			self:saveSavegame(true)
		end
	end
end

function FSBaseMission:onAppResumed()
	if not g_gui:getIsGuiVisible() then
		g_autoSaveManager:resetTime()
		if not g_sleepManager:getIsSleeping() then
			g_gui:changeScreen(nil, InGameMenu)
			if GS_IS_MOBILE_VERSION then
				g_inGameMenu:goToPage(g_inGameMenu.pageMain)
			end
		end
	end
end

function FSBaseMission:getCanShowHelpTriggers()
	if g_guidedTourManager:getIsTourRunning() then
		return false
	else
		return FSBaseMission:superClass().getCanShowHelpTriggers(self)
	end
end

function FSBaseMission:onGuidedTourStarted()
	if not g_gameSettings:getValue(GameSettings.SETTING.STARTED_GUIDED_TOUR) then
		g_gameSettings:setValue(GameSettings.SETTING.STARTED_GUIDED_TOUR, true, true)
	end
end

function FSBaseMission:onGuidedTourFinished() end

function FSBaseMission:setColorBlindMode(isActive)
	if self.mapOverlayGenerator ~= nil then
		self.mapOverlayGenerator:setColorBlindMode(isActive)
	end
end

-- Local values: localPlayer, farm
function FSBaseMission:notifyPlayerFarmChanged(player)
	local v782_ = g_localPlayer
	if v782_ ~= nil and player == v782_ then
		if self:getIsClient() and v782_:getIsInVehicle() then
			v782_:leaveVehicle()
		end
		local v783_ = g_farmManager:getFarmById(v782_:getFarmId())
		g_inGameMenu:setPlayerFarm(v783_)
		g_shopMenu:setPlayerFarm(v783_)
		g_shopController:setOwnedFarmItems(self.ownedItems, v782_.farmId)
		g_shopController:setLeasedFarmItems(self.leasedItems, v782_.farmId)
		g_shopMenu:onMoneyChange()
	end
end

function FSBaseMission:onUserAdded(user)
	self:updateMaxNumHirables()
	if user:getId() == self.playerUserId then
		g_inGameMenu:setCurrentUserId(self.playerUserId)
		g_shopMenu:setCurrentUserId(self.playerUserId)
	end
	if user:getId() ~= self:getServerUserId() and user:getId() ~= self.playerUserId then
		print(user:getNickname() .. " joined the game")
		g_currentMission:addChatMessage(user:getNickname(), g_i18n:getText("ui_serverUserJoin"), FarmManager.SPECTATOR_FARM_ID)
	end
	g_inGameMenu:setConnectedUsers(self.userManager:getUsers())
	self.userManager:setUserBlockDataDirty()
end

-- Local values: nickname
function FSBaseMission:onUserRemoved(user, disconnectReason)
	self:updateMaxNumHirables()
	if user:getId() ~= self:getServerUserId() and user:getId() ~= self.playerUserId then
		local v789_ = user:getNickname()
		if disconnectReason == nil or disconnectReason == DisconnectReason.PLAYER_LEFT then
			print(v789_ .. " left the game")
			g_currentMission:addChatMessage(v789_, g_i18n:getText("ui_serverUserLeave"), FarmManager.SPECTATOR_FARM_ID)
		elseif disconnectReason == DisconnectReason.PLAYER_LOST_CONNECTION then
			print(v789_ .. " lost shape to the game")
			g_currentMission:addChatMessage(v789_, g_i18n:getText("ui_serverUserLostConnection"), FarmManager.SPECTATOR_FARM_ID)
		elseif disconnectReason == DisconnectReason.KICKED then
			print(v789_ .. " was kicked from the game")
			g_currentMission:addChatMessage(v789_, g_i18n:getText("ui_serverUserWasKicked"), FarmManager.SPECTATOR_FARM_ID)
		elseif disconnectReason == DisconnectReason.BANNED then
			print(v789_ .. " was banned")
			g_currentMission:addChatMessage(v789_, g_i18n:getText("ui_serverUserWasBanned"), FarmManager.SPECTATOR_FARM_ID)
		end
	end
	g_inGameMenu:setConnectedUsers(self.userManager:getUsers())
end

function FSBaseMission:onMasterUserAdded(user)
	if user:getId() == self.playerUserId then
		self.isMasterUser = true
		if g_addCheatCommands then
			addConsoleCommand("gsMoneyAdd", "Add a lot of money", "consoleCommandCheatMoney", self, "[amount]; [farmId]")
		end
	end
	if self:getIsServer() then
		g_server:broadcastEvent(UserDataEvent.new({ user }))
	end
end

-- Local values: connectionList, streamId, connection, player
function FSBaseMission:broadcastEventToFarm(event, farmId, sendLocal, ignoreConnection, ghostObject, force)
	local v799_ = {}
	for v800_, v801_ in pairs(g_server.clientConnections) do
		local v802_ = self.shapesToPlayer[v801_]
		if v802_ ~= nil and v802_.farmId == farmId then
			v799_[v800_] = v801_
		end
	end
	g_server:broadcastEvent(event, sendLocal, ignoreConnection, ghostObject, force, v799_)
end

-- Local values: name, nickname
function FSBaseMission:getDefaultServerName()
	local v803_ = g_gameSettings:getValue(GameSettings.SETTING.ONLINE_PRESENCE_NAME)
	if g_languageShort == "pl" then
		return v803_ .. " - " .. g_i18n:getText("ui_serverNameGame")
	elseif v803_:endsWith("s") then
		return v803_ .. "\' " .. g_i18n:getText("ui_serverNameGame")
	elseif v803_:endsWith("\'") then
		return v803_ .. "s " .. g_i18n:getText("ui_serverNameGame")
	else
		return v803_ .. "\'s " .. g_i18n:getText("ui_serverNameGame")
	end
end

-- Local values: copy
function FSBaseMission:setLastCreatedLicensePlate(licensePlateData)
	if licensePlateData ~= nil and licensePlateData.placementIndex ~= LicensePlateManager.PLATE_POSITION.NONE then
		local v805_ = {
			["variation"] = licensePlateData.variation,
			["colorIndex"] = licensePlateData.colorIndex,
			["placementIndex"] = licensePlateData.placementIndex,
			["characters"] = table.clone(licensePlateData.characters),
			["xmlFilename"] = g_licensePlateManager.xmlFilename
		}
		g_gameSettings.lastCreatedLicensePlate = v805_
		g_gameSettings:save()
	end
end

-- Local values: data, copy
function FSBaseMission:getLastCreatedLicensePlate()
	local v806_ = g_gameSettings.lastCreatedLicensePlate
	if v806_ == nil then
		return nil
	elseif v806_.xmlFilename == g_licensePlateManager.xmlFilename then
		return v806_.characters ~= nil and {
			["variation"] = v806_.variation,
			["colorIndex"] = v806_.colorIndex,
			["placementIndex"] = v806_.placementIndex,
			["characters"] = table.clone(v806_.characters)
		} or nil
	else
		return nil
	end
end
