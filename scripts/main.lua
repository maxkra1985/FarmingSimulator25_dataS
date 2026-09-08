-- Local values: debugTool
source("dataS/scripts/std.lua")
source("dataS/scripts/StartParams.lua")
source("dataS/scripts/testing.lua")
source("dataS/scripts/events.lua")
source("dataS/scripts/menu.lua")
newGetSafeFrameInsets = getSafeFrameInsets
function getSafeFrameInsets()
	return 0, 0, 0, 0
end
AutoLoadParams = {
	["enable"] = false,
	["x"] = 0,
	["y"] = 0,
	["z"] = 0
}
local debugTool = debug
debug = nil
GS_PROFILE_VERY_LOW = 1
GS_PROFILE_LOW = 2
GS_PROFILE_MEDIUM = 3
GS_PROFILE_HIGH = 4
GS_PROFILE_VERY_HIGH = 5
GS_PROFILE_ULTRA = 6
g_gameVersion = 23
g_gameVersionNotification = "1.21.1.0"
g_gameVersionDisplay = "1.21.1.0"
g_gameVersionDisplayExtra = ""
g_isDevelopmentConsoleScriptModTesting = false
g_minModDescVersion = 90
g_maxModDescVersion = 111
g_language = 0
g_languageShort = "en"
g_languageSuffix = "_en"
g_showSafeFrame = false
g_noHudModeEnabled = false
g_woodCuttingMarkerEnabled = true
g_isDevelopmentVersion = false
g_isServerStreamingVersion = false
g_addTestCommands = false
g_addCheatCommands = false
g_showDevelopmentWarnings = false
g_appIsSuspended = false
g_networkDebug = false
g_networkDebugPrints = false
g_gameRevision = "000"
g_buildName = ""
g_buildTypeParam = ""
g_gameBasePath = g_gameBasePath or ""
g_showDeeplinkingFailedMessage = false
g_isSignedIn = false
g_settingsLanguageGUI = 0
g_availableLanguageNamesTable = {}
g_availableLanguagesTable = {}
g_fovYDefault = 1.0471975511965976
g_fovYMin = 0.6981317007977318
g_fovYMax = 2.0943951023931953
g_uiDebugEnabled = false
g_uiFocusDebugEnabled = false
g_logFilePrefixTimestamp = true
g_densityMapRevision = 4
g_terrainTextureRevision = 1
g_terrainLodTextureRevision = 2
g_splitShapesRevision = 2
g_tipCollisionRevision = 2
g_placementCollisionRevision = 2
g_navigationCollisionRevision = 2
g_menuMusic = nil
g_menuMusicIsPlayingStarted = false
g_clientInterpDelay = 100
g_clientInterpDelayMin = 60
g_clientInterpDelayMax = 150
g_clientInterpDelayBufferOffset = 30
g_clientInterpDelayBufferScale = 0.5
g_clientInterpDelayBufferMin = 45
g_clientInterpDelayBufferMax = 60
g_clientInterpDelayAdjustDown = 0.002
g_clientInterpDelayAdjustUp = 0.08
g_time = 0
g_currentDt = 16.666666666666668
g_updateLoopIndex = 0
g_physicsTimeLooped = 0
g_physicsDt = 16.666666666666668
g_physicsDtUnclamped = 16.666666666666668
g_physicsDtNonInterpolated = 16.666666666666668
g_physicsDtLastValidNonInterpolated = 16.666666666666668
g_packetPhysicsNetworkTime = 0
g_networkTime = netGetTime()
g_physicsNetworkTime = g_networkTime
g_analogStickHTolerance = 0.45
g_analogStickVTolerance = 0.45
g_referenceScreenWidth = 1920
g_referenceScreenHeight = 1080
g_maxUploadRate = 30.72
g_maxUploadRatePerClient = 393.216
g_drawGuiHelper = false
g_guiHelperSteps = 0.1
g_lastMousePosX = 0
g_lastMousePosY = 0
g_screenWidth = 800
g_screenHeight = 600
g_pixelSizeX = 1 / g_screenWidth
g_pixelSizeY = 1 / g_screenHeight
g_screenAspectRatio = g_screenWidth / g_screenHeight
g_presentedScreenAspectRatio = g_screenAspectRatio
g_aspectScaleX = 1
g_aspectScaleY = 1
g_dedicatedServer = nil
g_joinServerMaxCapacity = 16
g_serverMaxClientCapacity = 16
g_serverMinCapacity = 2
g_nextModRecommendationTime = 0
g_maxNumLoadingBarSteps = 35
g_curNumLoadingBarStep = 0
g_updateDownloadFinished = false
g_updateDownloadFinishedDialogShown = false
g_skipStartupScreen = false
function initPlatform()
	local v_u_2_ = nil
	if StartParams.getIsSet("platform") then
		local v3_ = string.upper(string.trim(StartParams.getValue("platform") or ""))
		if PlatformId[v3_] == nil then
			if v3_ == "STEAM" then
				v_u_2_ = PlatformId.WIN
				GS_IS_STEAM_VERSION = true
			elseif v3_ == "EPIC" then
				v_u_2_ = PlatformId.WIN
				GS_IS_EPIC_VERSION = true
			elseif v3_ == "MSSTORE" then
				v_u_2_ = PlatformId.WIN
				GS_IS_MSSTORE_VERSION = true
			elseif v3_ == "NETFLIX" then
				v_u_2_ = PlatformId.ANDROID
				GS_IS_NETFLIX_VERSION = true
			else
				printError(string.format("Error: Invalid platform \'%s\'", v3_))
			end
		else
			v_u_2_ = PlatformId[v3_]
		end
	end
	if v_u_2_ ~= nil then
		function getPlatformId()
			-- upvalues: (ref) v_u_2_
			return v_u_2_
		end
	end
	local v4_ = getPlatformId()
	GS_PLATFORM_ID = v4_
	GS_PLATFORM_PC = v4_ == PlatformId.WIN and true or v4_ == PlatformId.MAC
	GS_PLATFORM_XBOX = v4_ == PlatformId.XBOX_SERIES
	GS_PLATFORM_PLAYSTATION = v4_ == PlatformId.PS5
	GS_PLATFORM_SWITCH = v4_ == PlatformId.SWITCH
	GS_PLATFORM_SWITCH2 = v4_ == PlatformId.SWITCH2
	GS_PLATFORM_PHONE = v4_ == PlatformId.ANDROID and true or v4_ == PlatformId.IOS
	GS_IS_CONSOLE_VERSION = GS_PLATFORM_XBOX or (GS_PLATFORM_PLAYSTATION or GS_PLATFORM_SWITCH2)
	GS_IS_MOBILE_VERSION = GS_PLATFORM_PHONE or GS_PLATFORM_SWITCH
end

-- Upvalues: debugTool
-- Local values: settingsXML, developmentLevel, kioskMode, isServerStart, autoStartSavegameId, autoLoadURI, devStartServer, devStartClient, devUniqueUserId, safeFrameOffsetX, safeFrameOffsetY, safeFrameMajorOffsetX, safeFrameMajorOffsetY, safeFramePixels, xOffset, yOffset, availableLanguagesString, _, lang, gameVersionText, nameExtra, screenshotsDir, modSettingsDir, modsDir, modDownloadDir, modsDir2, modsDirectoryParam, mapsXML, startedRepeat, userProfilePath, func, _, filename, node, defaultCamera, soundPlayerLocal, soundPlayerTemplate, soundPlayerReadmeTemplate, soundUserPlayerLocal, soundPlayerTarget, soundPlayerReadme, eventAdded, eventId, userName
function init(args)
	-- upvalues: (copy) debugTool
	StartParams.init(args)
	initPlatform()
	source("dataS/scripts/game.lua")
	getClipboard = nil
	addFoliageTypeFromXML = nil
	setModHubRating = nil
	getModHubRating = nil
	if not initTesting() then
		setTextureStreamingPaused(true)
		local v6_ = XMLFile.load("SettingsFile", "dataS/settings.xml")
		local v7_ = v6_:getString("settings#developmentLevel", "release"):lower()
		g_buildName = v6_:getString("settings#buildName", g_buildName)
		g_buildTypeParam = v6_:getString("settings#buildTypeParam", g_buildTypeParam)
		g_gameRevision = v6_:getString("settings#revision", g_gameRevision)
		g_gameRevision = g_gameRevision .. getGameRevisionExtraText()
		g_isDevelopmentVersion = false
		if v7_ == "internal" then
			print("INTERNAL VERSION")
			g_addTestCommands = true
		elseif v7_ == "development" then
			print("DEVELOPMENT VERSION")
			g_isDevelopmentVersion = true
			g_addTestCommands = true
			enableDevelopmentControls()
		end
		if StartParams.getIsSet("releaseBuild") then
			g_isDevelopmentVersion = false
		end
		if g_isDevelopmentVersion then
			g_networkDebug = true
			print(string.format("GameDirectory: %s", getAppBasePath()))
			print(string.format("UniqueUserId: %s", getUniqueUserId()))
		end
		if g_addTestCommands or StartParams.getIsSet("cheats") then
			g_addCheatCommands = true
		end
		if g_addTestCommands or StartParams.getIsSet("devWarnings") then
			g_showDevelopmentWarnings = true
		end
		if g_isDevelopmentVersion then
			if StartParams.getIsSet("consoleSimulator") then
				ConsoleSimulator.init()
				ImeSimulator.init()
			end
			if StartParams.getIsSet("imeSimulator") then
				ImeSimulator.init()
			end
			if StartParams.getIsSet("iapSimulator") then
				IAPSimulator.init()
			end
			if StartParams.getIsSet("mobileSimulator") then
				MobileSimulator.init()
			end
			if StartParams.getIsSet("gameLoadingCancelSimulator") then
				GameLoadingCancelSimulator.init()
			end
			Profiler.init()
		end
		if setLuaErrorHandler ~= nil and (StartParams.getIsSet("scriptDebug") or g_isDevelopmentVersion) then
			if debugTool == nil or debugTool.traceback == nil then
				print("Info: lua custom error handler enabled (B)")
				setLuaErrorHandler(function(p8_)
					printCallstack()
					return p8_
				end)
			else
				print("Info: lua custom error handler enabled (A)")
				setLuaErrorHandler(function(p9_)
					-- upvalues: (ref) debugTool
					return debugTool.traceback(p9_, 2)
				end)
			end
		end
		g_serverMaxCapacity = GS_IS_CONSOLE_VERSION and 6 or 16
		AudioGroup.loadGroups()
		CollisionPreset.init()
		ObjectMask.init()
		g_i3DManager:init()
		g_cameraManager:init()
		updateLoadingBarProgress()
		g_messageCenter = MessageCenter.new()
		updateLoadingBarProgress()
		g_soundMixer = SoundMixer.new()
		g_soundMixer:loadFromXML("dataS/soundMixer.xml")
		updateLoadingBarProgress()
		g_autoSaveManager = AutoSaveManager.new()
		updateLoadingBarProgress()
		local v10_ = KioskMode.new()
		if v10_:load() then
			g_kioskMode = v10_
		end
		g_lifetimeStats = LifetimeStats.new()
		g_lifetimeStats:load()
		local v11_ = StartParams.getIsSet("server") or StartParams.getIsSet("serverWithGui")
		local v12_ = StartParams.getValue("autoStartSavegameId")
		local v13_ = StartParams.getValue("autoLoadURI")
		local v14_ = StartParams.getValue("devStartServer")
		local v15_ = StartParams.getValue("devStartClient")
		local v16_ = g_isDevelopmentVersion and StartParams.getValue("uniqueUserId") or nil
		if Platform.isPlaystation then
			g_unsafeScreenWidth = 1920
			g_unsafeScreenHeight = 1080
		else
			local v17_, v18_ = getScreenModeInfo(getScreenMode())
			g_unsafeScreenWidth = v17_
			g_unsafeScreenHeight = v18_
		end
		g_safeFrameScreenOffsetX = 0
		g_safeFrameScreenOffsetY = 0
		g_screenWidth = g_unsafeScreenWidth - g_safeFrameScreenOffsetX * 2
		g_screenHeight = g_unsafeScreenHeight - g_safeFrameScreenOffsetY * 2
		g_safeFrameRatioX = g_screenWidth / g_unsafeScreenWidth
		g_safeFrameRatioY = g_screenHeight / g_unsafeScreenHeight
		g_pixelSizeX = 1 / g_unsafeScreenWidth
		g_pixelSizeY = 1 / g_unsafeScreenHeight
		g_baseUIFilename = "dataS/menu/hud/ui_elements.png"
		g_baseUIPostfix = ""
		g_iconsUIFilename = "dataS/menu/hud/ui_icons.png"
		g_baseHUDFilename = "dataS/menu/hud/hud_elements.png"
		g_controlHUDFilename = "dataS/menu/hud/hud_elements2.png"
		if g_isDevelopmentVersion then
			print(string.format(" Loading UI-textures: \'%s\' \'%s\' \'%s\'", g_baseUIFilename, g_baseHUDFilename, g_iconsUIFilename))
		end
		g_screenAspectRatio = g_screenWidth / g_screenHeight
		g_presentedScreenAspectRatio = getScreenAspectRatio()
		updateAspectRatio(g_screenAspectRatio)
		local v19_, v20_ = getNormalizedScreenValues(1, 1)
		g_pixelSizeScaledX = v19_
		g_pixelSizeScaledY = v20_
		g_colorBgUVs = GuiUtils.getUVs({
			10,
			1010,
			4,
			4
		})
		local v21_ = Platform.safeFrameOffsetX
		local v22_ = Platform.safeFrameOffsetY
		local v23_, v24_ = getNormalizedScreenValues(v21_, v22_)
		g_safeFrameOffsetX = v23_
		g_safeFrameOffsetY = v24_
		local v25_ = Platform.safeFrameMajorOffsetX
		local v26_ = Platform.safeFrameMajorOffsetY
		local v27_, v28_ = getNormalizedScreenValues(v25_, v26_)
		g_safeFrameMajorOffsetX = v27_
		g_safeFrameMajorOffsetY = v28_
		local v29_, v30_ = getNormalizedScreenValues(30, 30)
		g_hudAnchorLeft = v29_
		g_hudAnchorRight = 1 - v29_
		g_hudAnchorBottom = v30_
		g_hudAnchorTop = 1 - v30_
		registerProfileFile("gameSettings.xml")
		registerProfileFile("extraContent.xml")
		g_textWidthScale = 0.95
		setTextWidthScale(g_textWidthScale)
		g_xmlManager:earlyCreateSchemas()
		g_xmlManager:earlyInitSchemas()
		PlayerSystem.loadStyleConfigurationsXML("dataS/character/playerModels.xml")
		updateLoadingBarProgress()
		g_gameSettings = GameSettings.new()
		loadUserSettings(g_gameSettings)
		updateLoadingBarProgress()
		loadLanguageSettings(v6_)
		local v31_ = "Available Languages:"
		for _, v32_ in ipairs(g_availableLanguagesTable) do
			v31_ = v31_ .. " " .. getLanguageCode(v32_)
		end
		v6_:delete()
		g_gameTitle = "Farming Simulator 25"
		if GS_IS_MOBILE_VERSION then
			g_gameTitle = "Farming Simulator 26"
		end
		CaptionUtil.addText(g_gameTitle)
		if Platform.isPlaystation then
			CaptionUtil.addText("- PlayStation 5")
		elseif Platform.isXbox then
			CaptionUtil.addText("- Xbox Series")
		elseif Platform.isSwitch then
			CaptionUtil.addText("- Switch")
		elseif Platform.isAndroid then
			CaptionUtil.addText("- Android")
		elseif Platform.isIOS then
			CaptionUtil.addText("- iOS")
		end
		if g_isDevelopmentVersion then
			local v33_ = g_gameVersionDisplay .. g_gameVersionDisplayExtra .. " (" .. getEngineRevision() .. "/" .. g_gameRevision .. ")"
			CaptionUtil.addText("- DevelopmentVersion " .. v33_ .. " - " .. getAppBasePath() .. " - " .. getUserProfileAppPath())
		elseif g_addTestCommands then
			CaptionUtil.addText("- InternalVersion")
		end
		addNotificationFilter(GS_PRODUCT_ID, g_gameVersionNotification)
		updateLoadingBarProgress()
		local v34_ = ""
		if g_buildTypeParam ~= "" then
			v34_ = v34_ .. " " .. g_buildTypeParam
		end
		if GS_IS_STEAM_VERSION then
			v34_ = v34_ .. " (Steam)"
		end
		if GS_IS_EPIC_VERSION then
			v34_ = v34_ .. " (Epic)"
		end
		if GS_IS_MSSTORE_VERSION then
			v34_ = v34_ .. " (MSStore)"
		end
		if GS_IS_MAC_APP_STORE_VERSION then
			v34_ = v34_ .. " (Mac App Store)"
		end
		if v11_ then
			v34_ = v34_ .. " (Server)"
		end
		print(g_gameTitle .. v34_)
		print("  Game-Version: " .. g_gameVersionDisplay .. g_gameVersionDisplayExtra)
		print("  Build-Id: " .. g_buildName)
		print("  Build-Revision: " .. g_gameRevision)
		print("  " .. v31_)
		print("  Language: " .. g_languageShort)
		print("  Time: " .. getDate("%Y-%m-%d %H:%M:%S"))
		print("  ModDesc Version: " .. g_maxModDescVersion)
		if Platform.isPC then
			local v35_ = getUserProfileAppPath() .. "screenshots/"
			g_screenshotsDirectory = v35_
			createFolder(v35_)
			local v36_ = getUserProfileAppPath() .. "modSettings/"
			g_modSettingsDirectory = v36_
			createFolder(v36_)
		end
		g_adsSystem = AdsSystem.new()
		local v37_ = getModInstallPath()
		local v38_ = getModDownloadPath()
		updateLoadingBarProgress()
		if Platform.allowsModDirectoryOverride then
			local v39_ = nil
			local v40_ = StartParams.getValue("modsDirectory")
			if string.isNilOrWhitespace(v40_) then
				if Utils.getNoNil(getXMLBool(g_savegameXML, "gameSettings.modsDirectoryOverride#active"), false) then
					v39_ = getXMLString(g_savegameXML, "gameSettings.modsDirectoryOverride#directory")
				end
			else
				v39_ = v40_
			end
			if not string.isNilOrWhitespace(v39_) then
				v37_ = string.gsub(v39_, "\\", "/")
				if v37_:sub(1, 2) == "//" then
					v37_ = "\\\\" .. string.sub(v37_, 3)
				end
				local v41_ = string.len(v37_)
				local v42_ = string.len(v37_)
				if string.sub(v37_, v41_, v42_) ~= "/" then
					v37_ = v37_ .. "/"
				end
			end
		end
		updateLoadingBarProgress()
		if v37_ then
			print("  Mod Directory: " .. v37_)
			createFolder(v37_)
		end
		if v38_ then
			createFolder(v38_)
		end
		g_modsDirectory = v37_
		if g_addTestCommands then
			print("  Testing Commands: Enabled")
		elseif g_addCheatCommands then
			print("  Cheats: Enabled")
		end
		updateLoadingBarProgress()
		g_i18n = I18N.new()
		g_i18n:load()
		if Platform.hasExtraContent then
			g_extraContentSystem = ExtraContentSystem.new()
			g_extraContentSystem:loadFromXML("dataS/extraContent.xml")
			g_extraContentSystem:loadFromProfile()
		end
		updateLoadingBarProgress()
		math.randomseed(getTime())
		math.random()
		math.random()
		math.random()
		updateLoadingBarProgress()
		g_splitShapeManager:load()
		addSplitShapesShaderParameterOverwrite("windSnowLeafScale", 0, 0, 0, 80)
		local v_u_43_ = XMLFile.load("MapsXML", "dataS/maps.xml")
		v_u_43_:iterate("maps.map", function(_, p44_)
			-- upvalues: (copy) v_u_43_
			g_mapManager:loadMapFromXML(v_u_43_, p44_, "", nil, true, true, false)
		end)
		v_u_43_:delete()
		updateLoadingBarProgress()
		g_animCache = AnimationCache.new()
		g_animCache:load(AnimationCache.CHARACTER, "dataS/character/playerAnimations/animations.i3d")
		updateLoadingBarProgress()
		g_animCache:load(AnimationCache.VEHICLE_CHARACTER, "dataS/character/playerAnimations/animationsVehicleCharacter.i3d")
		if Platform.supportsPedestrians then
			g_animCache:load(AnimationCache.PEDESTRIAN, "dataS/character/playerAnimations/animationsPedestrians.i3d")
		end
		g_achievementManager = AchievementManager.new()
		g_achievementManager:load()
		g_updateables = {}
		updateLoadingBarProgress()
		if g_modsDirectory then
			initModDownloadManager(g_modsDirectory, v38_, g_minModDescVersion, g_maxModDescVersion, g_isDevelopmentVersion)
			initModDownloadManager = nil
		end
		startUpdatePendingMods()
		updateLoadingBarProgress()
		loadDlcs()
		updateLoadingBarProgress()
		local v45_ = startFrameRepeatMode()
		while isModUpdateRunning() do
			usleep(16000)
		end
		if v45_ then
			endFrameRepeatMode()
		end
		if Platform.supportsMods then
			loadAllMods()
		end
		if not Platform.isConsole then
			copyFile(getAppBasePath() .. "VERSION", getUserProfileAppPath() .. "VERSION", true)
		end
		updateLoadingBarProgress()
		g_inputBinding = InputBinding.new(g_modManager, g_messageCenter, GS_IS_CONSOLE_VERSION)
		g_inputBinding:load()
		g_overlayManager = OverlayManager.new()
		g_overlayManager:addTextureConfigFile("dataS/menu/ui_elements.xml", "ui_elements")
		g_overlayManager:addTextureConfigFile("dataS/menu/gui.xml", "gui")
		g_overlayManager:addTextureConfigFile("dataS/menu/hud/mapHotspots.xml", "mapHotspots")
		g_overlayManager:addTextureConfigFile("dataS/menu/helpline/helplineAtlasSmall.xml", HelpLineManager.SLICE_PREFIX)
		g_gui = Gui.new()
		g_gui:loadProfiles("dataS/guiProfiles.xml")
		updateLoadingBarProgress()
		g_inputDisplayManager = InputDisplayManager.new(g_messageCenter, g_inputBinding, g_modManager, GS_IS_CONSOLE_VERSION)
		g_inputDisplayManager:load()
		if Platform.hasTouchInput then
			g_touchHandler = TouchHandler.new()
		end
		simulatePhysics(false)
		if v11_ then
			local v46_ = getUserProfileAppPath()
			g_dedicatedServer = DedicatedServer.new()
			g_dedicatedServer:load(v46_ .. "dedicated_server/dedicatedServerConfig.xml", v46_ .. "dedicated_server/gameStats.xml")
		end
		updateLoadingBarProgress()
		g_connectionManager = ConnectionManager.new()
		g_masterServerConnection = MasterServerConnection.new()
		g_startMissionInfo = StartMissionInfo.new()
		g_savegameController = SavegameController.new()
		g_inAppPurchaseController = InAppPurchaseController.new()
		g_shopController = ShopController.new()
		g_modHubController = ModHubController.new()
		g_settingsModel = SettingsModel.new()
		updateLoadingBarProgress()
		AchievementsScreen.register()
		if Platform.isMobile then
			MobileSettingsScreen.register()
		end
		g_animalScreen = AnimalScreen.register()
		g_careerScreen = CareerScreen.register()
		if Platform.hasContruction then
			g_constructionScreen = ConstructionScreen.register()
		end
		g_createGameScreen = CreateGameScreen.register()
		updateLoadingBarProgress()
		CreditsScreen.register()
		g_connectToMasterServerScreen = ConnectToMasterServerScreen.register()
		if Platform.needsSignIn then
			g_gamepadSigninScreen = GamepadSigninScreen.register()
		end
		if GS_IS_NETFLIX_VERSION then
			g_netflixSigninScreen = NetflixSigninScreen.register()
		end
		g_joinGameScreen = JoinGameScreen.register()
		g_mainScreen = MainScreen.register()
		updateLoadingBarProgress()
		if Platform.supportsMods then
			g_modHubScreen = ModHubScreen.register()
		end
		g_modSelectionScreen = ModSelectionScreen.register()
		g_newGameScreen = NewGameScreen.register()
		g_mpLoadingScreen = MPLoadingScreen.register()
		g_multiplayerScreen = MultiplayerScreen.register()
		g_serverDetailScreen = ServerDetailScreen.register()
		updateLoadingBarProgress()
		g_settingsScreen = SettingsScreen.register()
		updateLoadingBarProgress()
		g_shopConfigScreen = ShopConfigScreen.register()
		g_shopMenu = ShopMenu.register()
		updateLoadingBarProgress()
		if Platform.showStartupScreen and g_skipStartupScreen == false then
			g_startupScreen = StartupScreen.register()
		end
		if Platform.hasWardrobe then
			g_wardrobeScreen = WardrobeScreen.register()
		end
		g_workshopScreen = WorkshopScreen.register()
		updateLoadingBarProgress()
		g_inGameMenu = InGameMenu.register()
		updateLoadingBarProgress()
		if Platform.hasAnimalTradingDialog then
			AnimalTradingDialog.register()
		end
		ChatDialog.register()
		ColorPickerDialog.register()
		g_connectionFailedDialog = ConnectionFailedDialog.register()
		DenyAcceptDialog.register()
		EditFarmDialog.register()
		updateLoadingBarProgress()
		GameRateDialog.register()
		InfoDialog.register()
		LeaseYesNoDialog.register()
		LicensePlateDialog.register()
		MessageDialog.register()
		ConnectionPendingDialog.register()
		ModHubScreenshotDialog.register()
		ModHubDownloadDialog.register()
		updateLoadingBarProgress()
		OptionDialog.register()
		PasswordDialog.register()
		PlaceableInfoDialog.register()
		RefillDialog.register()
		RiceFieldDialog.register()
		SellItemDialog.register()
		PalletShopDialog.register()
		VehicleShopDialog.register()
		AISettingsDialog.register()
		ESRBUpdateDialog.register()
		MultiOptionDialog.register()
		updateLoadingBarProgress()
		SavegameConflictDialog.register()
		SavegameUploadDialog.register()
		SavegameUploadProgressDialog.register()
		SavegameMigrationDialog.register()
		SavegameMigrationProgressDialog.register()
		SiloDialog.register()
		ObjectStorageDialog.register()
		SleepDialog.register()
		FieldStateDialog.register()
		ToneMappingDialog.register()
		DebugPhysicsCollisionGroupDialog.register()
		DebugDisplacementDialog.register()
		updateLoadingBarProgress()
		TextInputDialog.register()
		if Platform.hasTourDialog then
			TourDialog.register()
		end
		TransferMoneyDialog.register()
		UnBanDialog.register()
		if Platform.supportsMods then
			VoteDialog.register()
		end
		YesNoDialog.register()
		ConversationDialog.register()
		updateLoadingBarProgress()
		if g_kioskMode ~= nil then
			g_kioskMode:initializedGUIClasses()
		end
		updateLoadingBarProgress()
		g_menuMusic = createStreamedSample("menuMusic", true)
		loadStreamedSample(g_menuMusic, "data/music/menu.ogg")
		setStreamedSampleGroup(g_menuMusic, AudioGroup.MENU_MUSIC)
		setStreamedSampleVolume(g_menuMusic, 1)
		g_soundMixer:addVolumeChangedListener(AudioGroup.MENU_MUSIC, function(_, _, p47_)
			if g_menuMusicIsPlayingStarted then
				if p47_ > 0 then
					resumeStreamedSample(g_menuMusic)
					return
				end
				pauseStreamedSample(g_menuMusic)
			end
		end, nil)
		if Platform.preShaderContentFiles ~= nil then
			g_preShaderContents = {}
			for _, v48_ in ipairs(Platform.preShaderContentFiles) do
				local v49_ = g_i3DManager:loadI3DFile(v48_, false, false)
				local v50_ = g_preShaderContents
				table.insert(v50_, {
					["step"] = 0,
					["node"] = v49_
				})
			end
			g_preShaderContentStepIndex = 1
			if #g_preShaderContents == 0 then
				g_preShaderContents = nil
			end
		end
		updateLoadingBarProgress(true)
		if g_kioskMode ~= nil then
			g_kioskMode:init()
		end
		if Platform.showStartupScreen and g_skipStartupScreen == false then
			g_gui:showGui("StartupScreen")
		else
			g_gui:showGui("MainScreen")
		end
		g_inputBinding:setShowMouseCursor(true)
		local v51_ = getCamera()
		g_cameraManager:addCamera(v51_, nil, true)
		g_cameraManager:setActiveCamera(v51_)
		if g_dedicatedServer == nil then
			local v52_ = getAppBasePath() .. "data/music/"
			local v53_ = getAppBasePath() .. "profileTemplate/streamingInternetRadios.xml"
			local v54_ = getAppBasePath() .. "profileTemplate/ReadmeMusic.txt"
			local v55_, v56_
			if Platform.supportsCustomInternetRadios then
				v55_ = getUserProfileAppPath() .. "music/"
				v56_ = v55_ .. "streamingInternetRadios.xml"
				local v57_ = v55_ .. "ReadmeMusic.txt"
				createFolder(v55_)
				copyFile(v53_, v56_, false)
				copyFile(v54_, v57_, false)
			else
				v55_ = v52_
				v56_ = v53_
			end
			g_soundPlayer = SoundPlayer.new(getAppBasePath(), "https://www.farming-simulator.com/feed/fs2025-radio-station-feed.xml", v56_, v52_, v55_, g_languageShort, AudioGroup.RADIO)
		end
		RestartManager:init(args)
		if RestartManager.restarting then
			g_gui:showGui("MainScreen")
			RestartManager:handleRestart()
		end
		SystemConsoleCommands.init()
		if g_dedicatedServer ~= nil then
			g_dedicatedServer:start()
		end
		if v14_ ~= nil then
			startDevServer(v14_, v16_)
		end
		if v15_ ~= nil then
			startDevClient(v15_, v16_)
		end
		if v12_ == nil then
			if v13_ ~= nil then
				autoLoadByURI(v13_)
				return
			end
		elseif StartParams.getIsSet("restart") and not GameLoadingCancelSimulator.ACTIVE then
			Logging.info("Ignored \'autoStartSavegame\' start parameter after game restart")
		else
			autoStartLocalSavegame(v12_)
		end
		if GS_PLATFORM_PC then
			registerGlobalActionEvents(g_inputBinding)
		elseif GS_IS_CONSOLE_VERSION and g_isDevelopmentVersion then
			local v58_, v59_ = g_inputBinding:registerActionEvent(InputAction.CONSOLE_DEBUG_TOGGLE_FPS, nil, toggleShowFPS, false, true, false, true)
			if v58_ then
				g_inputBinding:setActionEventTextVisibility(v59_, false)
			end
			local v60_, v61_ = g_inputBinding:registerActionEvent(InputAction.CONSOLE_DEBUG_TOGGLE_STATS, nil, toggleStatsOverlay, false, true, false, true)
			if v60_ then
				g_inputBinding:setActionEventTextVisibility(v61_, false)
			end
		end
		if Platform.supportsMods then
			postInitMods()
		end
		g_logFilePrefixTimestamp = true
		setFileLogPrefixTimestamp(g_logFilePrefixTimestamp)
		if StartParams.getIsSet("invitePlatformServerId") then
			g_invitePlatformServerId = StartParams.getValue("invitePlatformServerId")
			local v62_ = StartParams.getValue("inviteRequestUserName")
			g_inviteRequestUserName = base64Decode(v62_)
			g_handleInviteRequest = true
		end
		if StartParams.getIsSet("restart") and Platform.needsSignIn then
			if StartParams.getIsSet("autoSignIn") and g_gui.currentGuiName ~= "GamepadSigninScreen" then
				g_autoSignIn = true
			else
				g_gui:showGui("GamepadSigninScreen")
			end
		end
		if Platform.hasAdjustableFrameLimit then
			setFramerateLimiter(true, Platform.defaultFrameLimit)
		end
		Profiler.startProfiler()
		return true
	end
end

-- Local values: data, step, _, item, platformServerId, requestUserName, _, updateable
function update(dt)
	if Platform.isMobile then
		checkInsets()
	end
	if g_preShaderContents ~= nil then
		local v64_ = g_preShaderContents[g_preShaderContentStepIndex]
		local v65_ = v64_.step
		v64_.step = v64_.step + 1
		if v65_ == 0 then
			link(getRootNode(), v64_.node)
			setTranslation(g_cameraManager:getActiveCamera(), 0, 0, 5)
			Logging.devInfo("PreShaderContent (%d/%d): render default", g_preShaderContentStepIndex, #g_preShaderContents)
		elseif v65_ == 1 then
			setTranslation(g_cameraManager:getActiveCamera(), 0, 0, 30 * getViewDistanceCoeff() + 2)
			Logging.devInfo("PreShaderContent (%d/%d): render blended", g_preShaderContentStepIndex, #g_preShaderContents)
		elseif v65_ == 2 then
			Logging.devInfo("PreShaderContent (%d/%d): compiling done", g_preShaderContentStepIndex, #g_preShaderContents)
			g_preShaderContentStepIndex = g_preShaderContentStepIndex + 1
		end
		if g_preShaderContentStepIndex > #g_preShaderContents then
			Logging.devInfo("PreShaderContent: finished shader compilation")
			for _, v66_ in ipairs(g_preShaderContents) do
				delete(v66_.node)
			end
			g_preShaderContents = nil
			setTranslation(g_cameraManager:getActiveCamera(), 0, 0, 0)
		end
	end
	if g_autoSignIn then
		g_autoSignIn = nil
		g_gamepadSigninScreen:signIn()
	end
	if g_handleInviteRequest then
		local v67_ = g_invitePlatformServerId
		local v68_ = g_inviteRequestUserName
		g_invitePlatformServerId = nil
		g_inviteRequestUserName = nil
		g_handleInviteRequest = nil
		acceptedGameInvite(v67_, v68_)
	end
	g_time = g_time + dt
	g_currentDt = dt
	g_physicsDt = getPhysicsDt()
	g_physicsDtUnclamped = getPhysicsDtUnclamped()
	g_physicsDtNonInterpolated = getPhysicsDtNonInterpolated()
	if g_physicsDtNonInterpolated > 0 then
		g_physicsDtLastValidNonInterpolated = g_physicsDtNonInterpolated
	end
	g_networkTime = netGetTime()
	g_physicsNetworkTime = g_physicsNetworkTime + g_physicsDtUnclamped
	g_physicsTimeLooped = (g_physicsTimeLooped + g_physicsDt * 10) % 65535
	g_updateLoopIndex = g_updateLoopIndex + 1
	if g_updateLoopIndex > 1073741824 then
		g_updateLoopIndex = 0
	end
	local v69_ = g_physicsDt
	g_physicsDt = math.max(v69_, 0.001)
	local v70_ = g_physicsDtUnclamped
	g_physicsDtUnclamped = math.max(v70_, 0.001)
	if g_currentTest == nil then
		setTextWidthScale(g_textWidthScale)
		g_ignitionLockManager:update(dt)
		g_debugManager:update(dt)
		g_lifetimeStats:update(dt)
		g_soundMixer:update(dt)
		g_asyncTaskManager:update(dt)
		g_messageCenter:update(dt)
		Profiler.update(dt)
		if g_nextModRecommendationTime < g_time and (g_currentMission == nil and (g_dedicatedServer == nil and g_modHubController ~= nil)) then
			g_modHubController:updateRecommendationSystem()
			g_nextModRecommendationTime = g_time + 1800000
		end
		g_inputBinding:update(dt)
		for _, v71_ in ipairs(g_updateables) do
			v71_:update(dt)
		end
		if g_currentMission ~= nil and (g_currentMission.isLoaded and g_gui.currentGuiName ~= "GamepadSigninScreen") then
			g_currentMission:preUpdate(dt)
		end
		if Platform.hasFriendInvitation and (g_showDeeplinkingFailedMessage == true and g_gui.currentGuiName ~= "GamepadSigninScreen") then
			g_showDeeplinkingFailedMessage = false
			if GS_PLATFORM_XBOX then
				if PlatformPrivilegeUtil.checkMultiplayer(onShowDeepLinkingErrorMsg, nil, nil, 30000) then
					onShowDeepLinkingErrorMsg()
				end
			else
				onShowDeepLinkingErrorMsg()
			end
		end
		if g_currentMission == nil or g_currentMission:getAllowsGuiDisplay() then
			g_gui:update(dt)
		end
		if g_currentMission ~= nil and (g_currentMission.isLoaded and g_gui.currentGuiName ~= "GamepadSigninScreen") then
			g_currentMission:update(dt)
		end
		if g_currentMission ~= nil and (g_currentMission.isLoaded and g_gui.currentGuiName ~= "GamepadSigninScreen") then
			g_currentMission:postUpdate(dt)
		end
		if g_soundPlayer ~= nil then
			g_soundPlayer:update(dt)
		end
		if g_gui.currentGuiName == "MainScreen" then
			g_achievementManager:update(dt)
		end
		g_soundManager:update(dt)
		if g_kioskMode ~= nil then
			g_kioskMode:update(dt)
		end
		Input.updateFrameEnd()
		if GS_PLATFORM_PC and g_dedicatedServer == nil then
			if getIsUpdateDownloadFinished() then
				g_updateDownloadFinished = true
			end
			if g_updateDownloadFinished and (not g_updateDownloadFinishedDialogShown and (g_gui.currentGuiName == "MainScreen" or g_currentMission ~= nil and g_currentMission.gameStarted)) then
				g_updateDownloadFinishedDialogShown = true
				InfoDialog.show(g_i18n:getText("ui_updateDownloadFinishedText"))
			end
		end
		g_inputBinding:refresh()
		if g_pendingRestartData ~= nil then
			performRestart()
		end
		if g_pendingExit then
			performExit()
		end
	else
		g_currentTest.update(dt)
	end
end
function draw()
	if g_currentTest == nil then
		if g_dedicatedServer == nil then
			g_debugManager:drawPreUI()
			if g_currentMission == nil or g_currentMission:getAllowsGuiDisplay() then
				g_gui:draw()
			end
			if g_currentMission ~= nil and (g_currentMission.isLoaded and g_gui.currentGuiName ~= "GamepadSigninScreen") then
				g_currentMission:draw()
			end
			if g_inputBinding ~= nil then
				g_inputBinding:draw()
			end
			if g_inputDisplayManager ~= nil then
				g_inputDisplayManager:draw()
			end
			if g_kioskMode ~= nil then
				g_kioskMode:draw()
			end
			if g_isDevelopmentConsoleScriptModTesting then
				renderText(0.2, 0.85, getCorrectTextSize(0.05), "CONSOLE SCRIPTS. DEVELOPMENT USE ONLY")
			end
			g_debugManager:drawPostUI()
			if g_showSafeFrame then
				if g_safeFrameOverlay == nil then
					g_safeFrameOverlay = createImageOverlay("dataS/menu/base/graph_pixel.png")
					setOverlayColor(g_safeFrameOverlay, 1, 0, 0, 0.4)
				end
				renderOverlay(g_safeFrameOverlay, g_safeFrameOffsetX, 0, 1 - 2 * g_safeFrameOffsetX, g_safeFrameOffsetY)
				renderOverlay(g_safeFrameOverlay, g_safeFrameOffsetX, 1 - g_safeFrameOffsetY, 1 - 2 * g_safeFrameOffsetX, g_safeFrameOffsetY)
				renderOverlay(g_safeFrameOverlay, 0, 0, g_safeFrameOffsetX, 1)
				renderOverlay(g_safeFrameOverlay, 1 - g_safeFrameOffsetX, 0, g_safeFrameOffsetX, 1)
				if g_safeFrameMajorOverlay == nil then
					g_safeFrameMajorOverlay = createImageOverlay("dataS/menu/base/graph_pixel.png")
					setOverlayColor(g_safeFrameMajorOverlay, 1, 0, 0, 0.4)
				end
				renderOverlay(g_safeFrameMajorOverlay, g_safeFrameMajorOffsetX, 0, 1 - 2 * g_safeFrameMajorOffsetX, g_safeFrameMajorOffsetY)
				renderOverlay(g_safeFrameMajorOverlay, g_safeFrameMajorOffsetX, 1 - g_safeFrameMajorOffsetY, 1 - 2 * g_safeFrameMajorOffsetX, g_safeFrameMajorOffsetY)
				renderOverlay(g_safeFrameMajorOverlay, 0, 0, g_safeFrameMajorOffsetX, 1)
				renderOverlay(g_safeFrameMajorOverlay, 1 - g_safeFrameMajorOffsetX, 0, g_safeFrameMajorOffsetX, 1)
			end
			if g_drawGuiHelper then
				if g_guiHelperOverlay == nil then
					g_guiHelperOverlay = createImageOverlay("dataS/menu/base/graph_pixel.png")
				end
				if g_guiHelperOverlay ~= 0 then
					setTextColor(1, 1, 1, 1)
					local v72_, v73_ = getScreenModeInfo(getScreenMode())
					for v74_ = g_guiHelperSteps, 1, g_guiHelperSteps do
						renderOverlay(g_guiHelperOverlay, v74_, 0, 1 / v72_, 1)
						renderOverlay(g_guiHelperOverlay, 0, v74_, 1, 1 / v73_)
					end
					for v75_ = 0.05, 1, 0.05 do
						renderText(v75_, 0.97, getCorrectTextSize(0.02), string.format("%.2f", v75_))
						renderText(0.01, v75_, getCorrectTextSize(0.02), string.format("%.2f", v75_))
					end
					local v76_ = getCorrectTextSize(0.016)
					setTextAlignment(RenderText.ALIGN_RIGHT)
					setTextColor(0, 0, 0, 0.9)
					renderText(g_lastMousePosX - 0.005, g_lastMousePosY - 0.01 - 0.002, v76_, string.format("y %1.4f", g_lastMousePosY))
					setTextColor(1, 1, 1, 1)
					renderText(g_lastMousePosX - 0.005, g_lastMousePosY - 0.01, v76_, string.format("y %1.4f", g_lastMousePosY))
					setTextAlignment(RenderText.ALIGN_CENTER)
					setTextColor(0, 0, 0, 0.9)
					renderText(g_lastMousePosX, g_lastMousePosY + 0.01 - 0.002, v76_, string.format("x %1.4f", g_lastMousePosX))
					setTextColor(1, 1, 1, 1)
					renderText(g_lastMousePosX, g_lastMousePosY + 0.01, v76_, string.format("x %1.4f", g_lastMousePosX))
					setTextAlignment(RenderText.ALIGN_LEFT)
					local v77_ = 5 / v72_
					local v78_ = 5 / v73_
					renderOverlay(g_guiHelperOverlay, g_lastMousePosX - v77_, g_lastMousePosY, 2 * v77_, 1 / v73_)
					renderOverlay(g_guiHelperOverlay, g_lastMousePosX, g_lastMousePosY - v78_, 1 / v72_, 2 * v78_)
				end
			end
			if Platform.requiresConnectedGamepad and (getNumOfGamepads() == 0 and (g_gui.currentGuiName ~= "StartupScreen" and g_gui.currentGuiName ~= "GamepadSigninScreen")) then
				if Platform.isXbox then
					requestGamepadSignin(Input.BUTTON_2, true, false)
				end
				setTextBold(true)
				setTextAlignment(RenderText.ALIGN_CENTER)
				setTextColor(0, 0, 0, 1)
				local v79_ = getCorrectTextSize(0.05)
				local v80_ = g_i18n:getText("ui_pleaseReconnectController")
				renderText(0.497, 0.6053333333333333, v79_, v80_)
				renderText(0.5, 0.6053333333333333, v79_, v80_)
				renderText(0.503, 0.6053333333333333, v79_, v80_)
				renderText(0.497, 0.6, v79_, v80_)
				renderText(0.503, 0.6, v79_, v80_)
				renderText(0.497, 0.5946666666666667, v79_, v80_)
				renderText(0.5, 0.5946666666666667, v79_, v80_)
				renderText(0.503, 0.5946666666666667, v79_, v80_)
				setTextColor(1, 1, 1, 1)
				renderText(0.5, 0.6, v79_, v80_)
				setTextBold(false)
				setTextColor(1, 1, 1, 1)
				setTextAlignment(RenderText.ALIGN_LEFT)
				drawFilledRect(0, 0, 1, 1, 1, 1, 1, 0.3)
			end
			if g_showRawInput then
				new2DLayer()
				setOverlayColor(GuiElement.debugOverlay, 0, 0, 0, 0.8)
				renderOverlay(GuiElement.debugOverlay, 0, 0, 1, 1)
				setTextAlignment(RenderText.ALIGN_LEFT)
				local v81_ = getNumOfGamepads()
				local v82_ = 0.95
				local v83_ = 0
				for v84_ = 0, v81_ - 1 do
					local v85_ = 0
					for v86_ = 0, Input.MAX_NUM_BUTTONS - 1 do
						if getHasGamepadButton(Input.BUTTON_1 + v86_, v84_) then
							v85_ = v85_ + 1
						end
					end
					local v87_ = 0
					for v88_ = 0, Input.MAX_NUM_AXES - 1 do
						if getHasGamepadAxis(v88_, v84_) then
							v87_ = v87_ + 1
						end
					end
					local v89_ = getGamepadVersionId(v84_)
					local v90_ = v89_ >= 65535 and "" or string.format("%04X", v89_)
					setTextColor(0.5, 0.5, 0.5, 1)
					renderText(v83_ + 0.025, v82_, 0.018, "Name:")
					local v91_ = v82_ - 0.018
					renderText(v83_ + 0.025, v91_, 0.018, "ProductId:")
					local v92_ = v91_ - 0.018
					renderText(v83_ + 0.025, v92_, 0.018, "VendorId:")
					local v93_ = v92_ - 0.018
					renderText(v83_ + 0.025, v93_, 0.018, "Version:")
					local v94_ = v93_ - 0.018
					renderText(v83_ + 0.025, v94_, 0.018, "Axis / Buttons:")
					setTextColor(1, 1, 1, 1)
					renderText(v83_ + 0.11, v82_, 0.018, string.format("%s (#%d)", getGamepadName(v84_), v84_))
					local v95_ = v82_ - 0.018
					renderText(v83_ + 0.11, v95_, 0.018, string.format("%04X", getGamepadProductId(v84_)))
					local v96_ = v95_ - 0.018
					renderText(v83_ + 0.11, v96_, 0.018, string.format("%04X", getGamepadVendorId(v84_)))
					local v97_ = v96_ - 0.018
					renderText(v83_ + 0.11, v97_, 0.018, string.format("%s", v90_))
					local v98_ = v97_ - 0.018
					renderText(v83_ + 0.11, v98_, 0.018, string.format("%d / %d", v87_, v85_))
					local v99_ = v98_ - 0.035
					setTextColor(0.5, 0.5, 0.5, 1)
					renderText(v83_ + 0.025, v99_, 0.018, "Physical")
					renderText(v83_ + 0.07, v99_, 0.018, "Logical")
					renderText(v83_ + 0.11, v99_, 0.018, "Ingame")
					renderText(v83_ + 0.165, v99_, 0.018, "Label")
					renderText(v83_ + 0.2, v99_, 0.018, "Value")
					setTextColor(1, 1, 1, 1)
					local v100_ = v99_ - 0.005
					for v101_ = 0, Input.MAX_NUM_AXES - 1 do
						if getHasGamepadAxis(v101_, v84_) then
							local v102_ = getGamepadAxisPhysicalName(v101_, v84_)
							v100_ = v100_ - 0.016
							renderText(v83_ + 0.025, v100_, 0.016, string.format("%s", v102_))
							renderText(v83_ + 0.07, v100_, 0.016, string.format("%d", v101_))
							renderText(v83_ + 0.11, v100_, 0.016, string.format("AXIS_%d", v101_ + 1))
							renderText(v83_ + 0.165, v100_, 0.016, string.format("%s", getGamepadAxisLabel(v101_, v84_)))
							renderText(v83_ + 0.2, v100_, 0.016, string.format("%1.2f", getInputAxis(v101_, v84_)))
						end
					end
					local v103_ = v100_ - 0.035
					setTextColor(0.5, 0.5, 0.5, 1)
					renderText(v83_ + 0.025, v103_, 0.018, "Physical")
					renderText(v83_ + 0.07, v103_, 0.018, "Logical")
					renderText(v83_ + 0.11, v103_, 0.018, "Ingame")
					renderText(v83_ + 0.165, v103_, 0.018, "Label")
					setTextColor(1, 1, 1, 1)
					local v104_ = v103_ - 0.005
					for v105_ = 0, Input.MAX_NUM_BUTTONS - 1 do
						if getInputButton(v105_, v84_) > 0 then
							local v106_ = getGamepadButtonPhysicalName(v105_, v84_)
							v104_ = v104_ - 0.016
							renderText(v83_ + 0.025, v104_, 0.016, string.format("%s", v106_))
							renderText(v83_ + 0.07, v104_, 0.016, string.format("%d", v105_))
							renderText(v83_ + 0.11, v104_, 0.016, string.format("BUTTON_%d", v105_ + 1))
							renderText(v83_ + 0.165, v104_, 0.016, string.format("%s", getGamepadButtonLabel(v105_, v84_)))
						end
					end
					v82_ = v104_ - 0.1
					if v82_ < 0.05 then
						v83_ = v83_ + 0.3
						v82_ = 0.95
					end
				end
				if v81_ == 0 then
					renderText(0.025, v82_, 0.025, "No gamepads found")
				end
			end
			setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_BASELINE)
			setTextAlignment(RenderText.ALIGN_LEFT)
		end
	else
		g_currentTest.draw()
		return
	end
end

-- Local values: _, callbackData
function postAnimationUpdate(dt)
	for _, v108_ in pairs(g_postAnimationUpdateCallbacks) do
		v108_.callbackFunc(v108_.callbackTarget, dt, v108_.callbackArguments)
	end
end
function cleanUp()
	if g_safeFrameOverlay ~= nil then
		delete(g_safeFrameOverlay)
	end
	if g_safeFrameMajorOverlay ~= nil then
		delete(g_safeFrameMajorOverlay)
	end
	if g_guiHelperOverlay ~= nil then
		delete(g_guiHelperOverlay)
	end
	if GuiElement.debugOverlay ~= nil then
		delete(GuiElement.debugOverlay)
	end
	deleteDrawingOverlays()
	g_masterServerConnection:disconnectFromMasterServer()
	g_connectionManager:shutdownAll()
	g_inputDisplayManager:delete()
	g_inputBinding:delete()
	g_modHubController:delete()
	g_shopController:delete()
	g_gui:delete()
	g_i18n:delete()
	g_adsSystem:delete()
	g_depthOfFieldManager:delete()
	delete(g_menuMusic)
	delete(g_savegameXML)
	Profiler.delete()
	g_lifetimeStats:save()
	if g_soundPlayer ~= nil then
		g_soundPlayer:delete()
		g_soundPlayer = nil
	end
	if g_soundMixer ~= nil then
		g_soundMixer:delete()
		g_soundMixer = nil
	end
	g_animCache:delete()
	g_i3DManager:clearEntireSharedI3DFileCache(g_isDevelopmentVersion)
	g_soundManager:delete()
	g_cameraManager:delete()
	if g_isDevelopmentVersion or StartParams.getIsSet("scriptDebug") then
		setFileLogPrefixTimestamp(false)
		printActiveEntities()
		print("\nScenegraph:")
		I3DUtil.printChildren(getRootNode())
		setFileLogPrefixTimestamp(g_logFilePrefixTimestamp)
	end
	g_messageCenter:delete()
	SystemConsoleCommands.delete()
end
function doExit()
	g_pendingExit = true
end
function performExit()
	g_pendingExit = false
	OnInGameMenuMenu()
	cleanUp()
	print("Application quit")
	requestExit()
end

-- Local values: userName
function doRestart(restartProcess, args)
	if g_invitePlatformServerId ~= nil then
		local v111_ = base64Encode(g_inviteRequestUserName)
		args = args .. "-invitePlatformServerId " .. g_invitePlatformServerId .. " -inviteRequestUserName " .. v111_
	end
	g_pendingRestartData = {
		["restartProcess"] = restartProcess,
		["args"] = args
	}
end
function checkInsets()
	local v112_, v113_, v114_, v115_ = getSafeFrameInsets()
	if g_insetLeft == nil then
		g_insetLeft = v112_
		g_insetRight = v113_
		g_insetTop = v114_
		g_insetBottom = v115_
	end
	if v112_ ~= g_insetLeft or (v113_ ~= g_insetRight or (v114_ ~= g_insetTop or v115_ ~= g_insetBottom)) then
		g_insetLeft = v112_
		g_insetRight = v113_
		g_insetTop = v114_
		g_insetBottom = v115_
		g_messageCenter:publish(MessageType.INSETS_CHANGED)
	end
end
function performRestart()
	if g_pendingRestartData ~= nil then
		local v116_ = g_pendingRestartData
		if Platform.needsSignIn and (g_isSignedIn and getStartMode() ~= RestartManager.START_SCREEN_GAMEPAD_SIGNIN) then
			v116_.args = v116_.args .. " -autoSignIn"
		end
		cleanUp()
		local v117_ = v116_.restartProcess and "" or "(soft restart)"
		print("Application restart " .. v117_)
		restartApplication(v116_.restartProcess, v116_.args)
	end
end

-- Local values: numLanguages, languageCodeToLanguage, i, language, languageSet, availableLanguages, i
function loadLanguageSettings(xmlFile)
	local v119_ = getNumOfLanguages()
	local v_u_120_ = {}
	for v121_ = 0, v119_ - 1 do
		v_u_120_[getLanguageCode(v121_)] = v121_
	end
	local v_u_122_ = getLanguage()
	local v_u_123_ = false
	local v_u_124_ = {}
	xmlFile:iterate("settings.languages.language", function(_, p125_)
		-- upvalues: (copy) xmlFile, (copy) v_u_120_, (copy) v_u_122_, (ref) v_u_123_, (copy) v_u_124_
		local v126_ = xmlFile:getString(p125_ .. "#code")
		local v127_ = xmlFile:getString(p125_ .. "#short")
		local v128_ = xmlFile:getString(p125_ .. "#suffix")
		local v129_ = v_u_120_[v126_]
		if v129_ ~= nil then
			if v129_ == v_u_122_ or not v_u_123_ then
				v_u_123_ = true
				g_language = v129_
				g_languageShort = v127_
				g_languageSuffix = v128_
			end
			if getIsLanguageEnabled(v129_) then
				v_u_124_[v129_] = true
			end
		end
	end)
	g_availableLanguagesTable = {}
	g_availableLanguageNamesTable = {}
	for v130_ = 0, v119_ - 1 do
		if v_u_124_[v130_] or v130_ == g_language then
			local v131_ = g_availableLanguagesTable
			table.insert(v131_, v130_)
			if getLanguageNativeName == nil then
				local v132_ = g_availableLanguageNamesTable
				local v133_ = getLanguageName
				table.insert(v132_, v133_(v130_))
			else
				local v134_ = g_availableLanguageNamesTable
				local v135_ = getLanguageNativeName
				table.insert(v134_, v135_(v130_))
			end
			if v130_ == g_language then
				g_settingsLanguageGUI = #g_availableLanguagesTable - 1
			end
		end
	end
	if GS_IS_CONSOLE_VERSION then
		g_gameSettings:setValue(GameSettings.SETTING.MP_LANGUAGE, getSystemLanguage())
	end
end

-- Local values: nickname, gameSettingsPathTemplate, revision, gameSettingsTemplate, revisionTemplate
function loadUserSettings(gameSettings)
	local v137_ = getUserName():trim()
	local v138_ = (v137_ == nil or v137_ == "") and "Player" or v137_
	gameSettings:setValue(GameSettings.SETTING.ONLINE_PRESENCE_NAME, v138_)
	gameSettings:setValue(GameSettings.SETTING.VOLUME_MASTER, getMasterVolume())
	gameSettings:setValue("joystickVibrationEnabled", getGamepadVibrationEnabled())
	if g_savegameXML ~= nil then
		delete(g_savegameXML)
	end
	local v139_ = getAppBasePath() .. "profileTemplate/gameSettingsTemplate.xml"
	g_savegamePath = getUserProfileAppPath() .. "gameSettings.xml"
	copyFile(v139_, g_savegamePath, false)
	g_savegameXML = loadXMLFile("savegameXML", g_savegamePath)
	if g_savegameXML == nil or g_savegameXML == 0 then
		Logging.error("Detected corrupt gameSettings.xml. Restoring default file!")
		copyFile(v139_, g_savegamePath, true)
		g_savegameXML = loadXMLFile("savegameXML", g_savegamePath)
	end
	syncProfileFiles()
	local v140_ = getXMLInt(g_savegameXML, "gameSettings#revision")
	local v141_ = loadXMLFile("GameSettingsTemplate", v139_)
	local v142_ = getXMLInt(v141_, "gameSettings#revision")
	delete(v141_)
	if v140_ == nil or v140_ ~= v142_ then
		copyFile(v139_, g_savegamePath, true)
		delete(g_savegameXML)
		g_savegameXML = loadXMLFile("savegameXML", g_savegamePath)
	end
	gameSettings:setDefault()
	gameSettings:loadFromXML(g_savegameXML)
	if g_settingsModel ~= nil then
		g_settingsModel:refresh()
	end
	g_soundMixer:setAudioGroupVolumeFactor(AudioGroup.RADIO, g_gameSettings:getValue(GameSettings.SETTING.VOLUME_RADIO))
	g_soundMixer:setAudioGroupVolumeFactor(AudioGroup.VEHICLE, g_gameSettings:getValue(GameSettings.SETTING.VOLUME_VEHICLE))
	g_soundMixer:setAudioGroupVolumeFactor(AudioGroup.MENU_MUSIC, g_gameSettings:getValue(GameSettings.SETTING.VOLUME_MUSIC))
	g_soundMixer:setAudioGroupVolumeFactor(AudioGroup.ENVIRONMENT, g_gameSettings:getValue(GameSettings.SETTING.VOLUME_ENVIRONMENT))
	g_soundMixer:setAudioGroupVolumeFactor(AudioGroup.GUI, g_gameSettings:getValue(GameSettings.SETTING.VOLUME_GUI))
	g_soundMixer:setAudioGroupVolumeFactor(AudioGroup.CHARACTER, g_gameSettings:getValue(GameSettings.SETTING.VOLUME_CHARACTER))
	g_soundMixer:setMasterVolume(g_gameSettings:getValue(GameSettings.SETTING.VOLUME_MASTER))
	g_soundMixer:immediateUpdate()
	VoiceChatUtil.setOutputVolume(g_gameSettings:getValue(GameSettings.SETTING.VOLUME_VOICE))
	VoiceChatUtil.setInputVolume(g_gameSettings:getValue(GameSettings.SETTING.VOLUME_VOICE_INPUT))
	VoiceChatUtil.setInputMode(g_gameSettings:getValue(GameSettings.SETTING.VOICE_MODE))
	g_lifetimeStats:reload()
	if g_extraContentSystem ~= nil then
		g_extraContentSystem:reset()
		g_extraContentSystem:loadFromProfile()
	end
end
function takeScreenshot()
	if g_screenshotsDirectory == nil then
		printError("Error: Screenshot directory not defined!")
	else
		local v143_ = g_screenshotsDirectory .. "fsScreen_" .. getDate("%Y_%m_%d_%H_%M_%S") .. ".png"
		print("Saving screenshot: " .. v143_)
		if not saveScreenshot(v143_) then
			printError(string.format("Error while saving screenshot \'%s\'", v143_))
		end
	end
end

-- Local values: _, eventId
function registerGlobalActionEvents(inputManager)
	local _, v144_ = g_inputBinding:registerActionEvent(InputAction.TAKE_SCREENSHOT, nil, takeScreenshot, false, true, false, true)
	g_inputBinding:setActionEventTextVisibility(v144_, false)
	if g_addTestCommands and Platform.isPC then
		g_noteManager:registerInputActionEvent()
	end
	if g_kioskMode ~= nil then
		g_kioskMode:registerGlobalInputActionEvents()
	end
end

-- Local values: referenceAspect
function updateAspectRatio(aspect)
	local v146_ = g_referenceScreenWidth / g_referenceScreenHeight
	if v146_ < aspect then
		g_aspectScaleX = v146_ / aspect
		g_aspectScaleY = 1
	else
		g_aspectScaleX = 1
		g_aspectScaleY = aspect / v146_
	end
	g_aspectScaleX = g_aspectScaleX * g_safeFrameRatioX
	g_aspectScaleY = g_aspectScaleY * g_safeFrameRatioY
end
g_postAnimationUpdateCallbacks = {}

-- Local values: callbackData
function addPostAnimationCallback(callbackFunc, callbackTarget, callbackArguments)
	local v150_ = {
		["callbackFunc"] = callbackFunc,
		["callbackTarget"] = callbackTarget,
		["callbackArguments"] = callbackArguments
	}
	local v151_ = g_postAnimationUpdateCallbacks
	table.insert(v151_, v150_)
	return v150_
end

-- Local values: i, callbackData
function removePostAnimationCallback(callbackDataToRemove)
	for v153_, v154_ in pairs(g_postAnimationUpdateCallbacks) do
		if v154_ == callbackDataToRemove then
			table.remove(g_postAnimationUpdateCallbacks, v153_)
		end
	end
end

function addGlobalUpdateable(updateable)
	table.addElement(g_updateables, updateable)
end

function removeGlobalUpdateable(updateable)
	table.removeElement(g_updateables, updateable)
end

-- Local values: ratio
function updateLoadingBarProgress(isLast)
	g_curNumLoadingBarStep = g_curNumLoadingBarStep + 1
	local v158_ = g_curNumLoadingBarStep / g_maxNumLoadingBarSteps
	if isLast and v158_ < 1 or v158_ > 1 then
		printError("Error: Invalid g_maxNumLoadingBarSteps. Last step number is " .. g_curNumLoadingBarStep)
	end
	updateLoadingBar(v158_)
end
function onShowDeepLinkingErrorMsg()
	g_deepLinkingInfo = nil
	ConnectionFailedDialog.show(g_i18n:getText("ui_failedToConnectToGame"), OnInGameMenuMenu)
	g_showDeeplinkingFailedMessage = false
end

-- Local values: savegame
function startDevServer(savegameId, uniqueUserId)
	if StartParams.getIsSet("restart") then
		print("Skipping server auto start due to restart")
		return
	else
		g_savegameController:updateSavegames()
		g_savegameController:loadSavegames()
		print("Start developer mp server (Savegame-Id: " .. tostring(savegameId) .. ")")
		g_mainScreen:onMultiplayerClick()
		g_multiplayerScreen:onClickCreateGame()
		local v160_ = g_savegameController:getSavegame((tonumber(savegameId)))
		if v160_ == SavegameController.NO_SAVEGAME or not v160_.isValid then
			printWarning("    Savegame not found! Please select savegame manually!")
		else
			g_careerScreen.savegameList.selectedIndex = tonumber(savegameId)
			g_careerScreen:onStartAction()
			if g_gui.currentGuiName == "ModSelectionScreen" then
				g_modSelectionScreen:onClickOk()
			end
			g_autoDevMP = {
				["serverName"] = "InternalTest_" .. getUserName()
			}
			g_createGameScreen.serverNameElement:setText(g_autoDevMP.serverName)
			g_createGameScreen.autoAccept = true
			g_createGameScreen:onClickOk()
		end
	end
end

function startDevClient(serverName, uniqueUserId)
	if StartParams.getIsSet("restart") then
		print("Skipping client auto join due to restart")
	else
		print("Start developer mp client")
		g_mainScreen:onMultiplayerClick()
		if serverName == nil or serverName == "" then
			serverName = "InternalTest_" .. getUserName()
		end
		g_autoDevMP = {
			["serverName"] = serverName
		}
		g_multiplayerScreen:onClickJoinGame()
	end
end

-- Local values: savegame
function autoStartLocalSavegame(savegameId)
	print("Auto start local savegame (Id: " .. tostring(savegameId) .. ")")
	g_gui:setIsMultiplayer(false)
	g_gui:showGui("CareerScreen")
	g_careerScreen:setSelectedSavegameIndex((tonumber(savegameId)))
	local v163_ = g_savegameController:getSavegame((tonumber(savegameId)))
	if v163_ == SavegameController.NO_SAVEGAME or not v163_.isValid then
		printWarning("    Savegame not found! Please select savegame manually!")
	else
		g_careerScreen.currentSavegame = v163_
		g_careerScreen:onStartAction()
		if g_gui.currentGuiName == "ModSelectionScreen" then
			g_modSelectionScreen:onClickOk()
		end
	end
end

-- Local values: uriComponents, uriParamStrings, uriParams, i, v, keyValues, map, x, z, savegameIndex, savegame
function autoLoadByURI(uri)
	local v165_ = string.split(uri, ":")
	local v166_ = string.split(v165_[2], "&")
	local v167_ = {}
	for _, v168_ in ipairs(v166_) do
		local v169_ = string.split(v168_, "=")
		v167_[v169_[1]] = v169_[2]
	end
	if v167_.map == nil then
		printError("Error: URI Parameter \'map\' not set! Cannot auto load from URI.")
	else
		local v170_ = v167_.map
		local v171_ = v167_.x
		local v172_ = v167_.z
		local v173_ = v167_.savegameIndex
		local v174_ = tonumber(v173_) or 1
		AutoLoadParams.enable = true
		AutoLoadParams.x = tonumber(v171_)
		AutoLoadParams.z = tonumber(v172_)
		g_gui:setIsMultiplayer(false)
		g_gui:showGui("CareerScreen")
		g_savegameController:deleteSavegame(v174_)
		g_careerScreen:setSelectedSavegameIndex(v174_)
		local v175_ = g_savegameController:getSavegame(v174_)
		g_careerScreen.currentSavegame = v175_
		g_startMissionInfo.mapId = v170_
		g_startMissionInfo.canStart = true
		g_careerScreen:startSavegame(v175_)
		g_gui:changeScreen(nil, CareerScreen)
		if g_gui.currentGuiName == "ModSelectionScreen" then
			g_modSelectionScreen:onClickOk()
		end
	end
end

function connectToServer(platformServerId)
	if storeHaveDlcsChanged() or (haveModsChanged() or g_forceNeedsDlcsAndModsReload) then
		g_forceNeedsDlcsAndModsReload = false
		reloadDlcsAndMods()
	end
	if storeAreDlcsCorrupted() then
		InfoDialog.show(g_i18n:getText("ui_dlcsCorruptRedownload"), g_mainScreen.onDlcCorruptClick, g_mainScreen)
	else
		g_deepLinkingInfo = {}
		g_deepLinkingInfo.platformServerId = platformServerId
		g_masterServerConnection:disconnectFromMasterServer()
		g_connectionManager:shutdownAll()
		g_gui:changeScreen(nil, CareerScreen)
		g_mainScreen:onMultiplayerClick()
		g_multiplayerScreen:onClickJoinGame()
	end
end
function startMenuMusic()
	if not g_menuMusicIsPlayingStarted then
		g_menuMusicIsPlayingStarted = true
		playStreamedSample(g_menuMusic, 0)
		if g_soundMixer:getAudioGroupVolume(AudioGroup.MENU_MUSIC) == 0 then
			pauseStreamedSample(g_menuMusic)
		end
	end
end
