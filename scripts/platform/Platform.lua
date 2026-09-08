Platform = {}
function Platform.init()
	local v1_ = Platform
	v1_.id = getPlatformId()
	v1_.gameplay = {}
	v1_.ingameMap = {}
	v1_.settings = {}
	v1_.ui = {}
	v1_.blockedKeyboardCombos = {}
	v1_.lockedInputActionNames = {}
	v1_.playerInfo = {}
	Platform.applyDefault()
	if GS_PLATFORM_XBOX then
		Platform.applyConsole()
		Platform.applyXbox()
	elseif GS_PLATFORM_PLAYSTATION then
		Platform.applyConsole()
		Platform.applyPlaystation()
	elseif GS_PLATFORM_SWITCH2 then
		Platform.applyConsole()
		Platform.applySwitch2()
	elseif GS_PLATFORM_SWITCH then
		Platform.applyMobile()
		Platform.applySwitch()
	elseif GS_PLATFORM_ID == PlatformId.IOS then
		Platform.applyMobile()
		Platform.applyIOS()
		if GS_IS_NETFLIX_VERSION then
			Platform.applyNetflix()
		end
	elseif GS_PLATFORM_ID == PlatformId.ANDROID then
		Platform.applyMobile()
		Platform.applyAndroid()
		if GS_IS_NETFLIX_VERSION then
			Platform.applyNetflix()
		end
	elseif GS_IS_MSSTORE_VERSION then
		Platform.applyMSStore()
	end
	if GS_IS_STEAM_VERSION then
		Platform.applySteam()
	end
end
function Platform.applyDefault()
	print("Platform: loading defaults")
	local v2_ = Platform
	v2_.isPC = GS_PLATFORM_PC
	v2_.isSteam = GS_IS_STEAM_VERSION
	v2_.checkGPUDriver = true
	v2_.showVideoGIANTS = true
	v2_.showVideoFS = true
	v2_.showStartupScreen = true
	v2_.showGamerTagInMainScreen = false
	v2_.canChangeGamerTag = true
	v2_.canChangeControls = true
	v2_.showRentServerWebButton = true
	v2_.hasFriendInvitation = false
	v2_.hasFriendFilter = false
	v2_.hasNativeProfiles = false
	v2_.hasNetworkSettings = true
	v2_.hasExtraContent = true
	v2_.hasWardrobe = true
	v2_.hasMapSelection = true
	v2_.hasModHub = true
	v2_.hasConfigScreen = true
	v2_.hasOnlineAchievements = true
	v2_.autoStartAfterLoad = false
	v2_.hasContruction = true
	v2_.hasIngameMenuGameFrame = false
	v2_.hasAnimalTradingDialog = false
	v2_.hasRecordingDeviceDetection = false
	v2_.hasTourDialog = false
	v2_.hasDifficulty = true
	v2_.hasAdjustableFrameLimit = true
	v2_.supportsRealBeaconLights = true
	v2_.canChangeLanguage = true
	v2_.allowSavegameMigration = false
	v2_.allowRestartOnSettingsChange = true
	v2_.frameLimits = {
		30,
		60,
		90,
		120,
		144,
		240
	}
	v2_.defaultUIScale = 1
	v2_.defaultFrameLimit = 60
	v2_.guiPrefixes = {}
	v2_.l10nPostfixes = {}
	v2_.gameLogos = {
		["en"] = "dataS/menu/main_logo_en.png"
	}
	v2_.supportsMods = true
	v2_.allowsScriptMods = true
	v2_.allowsModDirectoryOverride = v2_.isPC
	v2_.hasSlotLimitation = true
	v2_.supportsCustomInternetRadios = v2_.isPC
	v2_.hasLimitedModSpace = false
	v2_.autoSelectDLCs = false
	v2_.verboseDLCLoading = false
	v2_.allowCrossPlatformSavegames = true
	v2_.supportsPushToTalk = true
	v2_.hasTextChat = true
	v2_.hasAudioChat = false
	v2_.hasPlayer = true
	v2_.allowPlayerPickUp = true
	v2_.supportsPedestrians = true
	v2_.supportsFoliageBending = true
	v2_.canQuitApplication = true
	v2_.supportsMultiplayer = true
	v2_.hasMainScreenLanguageSelection = false
	v2_.hasCloudSyncSetting = false
	v2_.hasGrassFilterEnabledByDefault = false
	v2_.supportsSavegameDebugUpload = true
	v2_.supportsSavegameDebugDownload = true
	v2_.supportsGameRating = false
	v2_.gameRatingEnabled = false
	v2_.showGamepadModeDialog = true
	v2_.showHeadTrackingDialog = true
	v2_.urlBuyNow = "buy-now.php"
	v2_.urlEshop = "lp/fs25-go-to-eshop.php"
	v2_.urlUpdate = "updates.php"
	v2_.urlUpdateGPUDriver = "gpuDriverDownload.php"
	v2_.urlDedicatedServer = "fs25-rent-a-dedicated-server.php"
	v2_.urlRating = "lp/fs25-rating.php"
	v2_.hasHints = false
	v2_.hasInGameMenuMainPage = false
	v2_.safeFrameOffsetX = 25
	v2_.safeFrameOffsetY = 25
	v2_.lowResCollisionHandlerGridSize = 64
	v2_.lowResCollisionHandlerCellRaysPerFrame = 16
	v2_.safeFrameMajorOffsetX = 25
	v2_.safeFrameMajorOffsetY = 25
	v2_.minFovY = g_fovYMin
	v2_.maxFovY = g_fovYMax
	v2_.maxNumMirrors = 3
	v2_.forcedUIResolution = nil
	v2_.usesFixedExposure = false
	v2_.hasShallowWaterSimulation = true
	v2_.verifyMultiplayerAvailabilityInMenu = Platform.verifyMultiplayerAvailabilityInMenu
	v2_.ui.drawHudOnDialog = false
	v2_.preShaderContentFiles = nil
	v2_.settings.canManageInputDevices = true
	v2_.settings.canManageInputBindings = true
	v2_.settings.canManageDisplaySettings = true
	v2_.gameplay.hasLoans = true
	v2_.gameplay.hasVehicleSales = true
	v2_.gameplay.hasMissions = true
	v2_.gameplay.defaultTimeScale = 5
	v2_.gameplay.timeScaleSettings = {
		0.5,
		1,
		2,
		3,
		5,
		6,
		10,
		15,
		30,
		60,
		120,
		240,
		360
	}
	v2_.gameplay.timeScaleDevSettings = { 2000, 12000, 60000 }
	v2_.gameplay.canSellFromMenu = true
	v2_.gameplay.sprayLevelMaxValue = 2
	v2_.gameplay.harvestScaleRation = {
		0.45,
		0.15,
		0.15,
		0.2,
		0.025,
		0.025
	}
	v2_.gameplay.useSprayDiffuseMaps = true
	v2_.gameplay.useMultipleSprayLevels = true
	v2_.gameplay.usePlowCounter = true
	v2_.gameplay.useLimeCounter = true
	v2_.gameplay.useStubbleShred = true
	v2_.gameplay.useRolling = true
	v2_.gameplay.ingameMapFruitsPerPage = 15
	v2_.gameplay.supportsWithering = true
	v2_.gameplay.maxNumHirables = math.huge
	v2_.gameplay.canVisitPOI = true
	v2_.gameplay.supportSeasonalGrowth = true
	v2_.gameplay.supportSnow = true
	v2_.gameplay.autoActivateTrigger = false
	v2_.gameplay.canCreateFields = true
	v2_.gameplay.treeCutFarmlandRestrictions = true
	v2_.gameplay.hasDynamicPallets = true
	v2_.gameplay.hasVehicleConfigs = true
	v2_.gameplay.hasWeeder = true
	v2_.gameplay.supportsTwister = true
	v2_.gameplay.automaticDischarge = false
	v2_.gameplay.automaticFilling = false
	v2_.gameplay.automaticAttach = false
	v2_.gameplay.automaticBaleDrop = false
	v2_.gameplay.automaticLights = false
	v2_.gameplay.automaticPipeUnfolding = false
	v2_.gameplay.automaticVehicleControl = false
	v2_.gameplay.keepFoldingWhileDetached = false
	v2_.gameplay.foldAfterAIFinished = false
	v2_.gameplay.lightsProfile = nil
	v2_.gameplay.useWorldCameraInside = true
	v2_.gameplay.useWorldCameraOutside = true
	v2_.gameplay.hasShadowFocusBox = true
	v2_.gameplay.hasVehicleCharacterIdleAnimations = true
	v2_.gameplay.allowVehicleCharacterIKDirtyUpdate = true
	v2_.gameplay.hasDetachedPowerTakeOffs = true
	v2_.gameplay.hasTMRMixing = true
	v2_.gameplay.dischargeSpeedFactor = 1
	v2_.gameplay.maxCameraZoomFactor = 1
	v2_.gameplay.dirtDurationScale = 1
	v2_.gameplay.hasVehicleDamage = true
	v2_.gameplay.allowSuspensionNodes = true
	v2_.gameplay.allowTestAreas = true
	v2_.gameplay.allowAutomaticHeaderTilt = true
	v2_.gameplay.hasBaleFermentation = true
	v2_.gameplay.steeringBackSpeedSettings = {
		0,
		1,
		2,
		3,
		4,
		5,
		6,
		7,
		8,
		9,
		10
	}
	v2_.gameplay.disabledShopSpecValues = {}
	v2_.gameplay.wheelTerrainDisplacement = true
	v2_.gameplay.wheelDensityHeightSmooth = true
	v2_.gameplay.wheelVisualPressure = true
	v2_.gameplay.wheelVisualPressureUpdateThreshold = 0.0003
	v2_.gameplay.wheelTireTracks = true
	v2_.gameplay.defaultFruitDestruction = true
	v2_.gameplay.defaultGyroscopeSteering = false
	v2_.gameplay.defaultCameraTilt = false
	v2_.gameplay.needHorseCleaning = true
	v2_.gameplay.canRenameHorses = true
	v2_.ingameMap.canZoom = true
	v2_.ingameMap.needsSolidBackground = true
	v2_.ingameMap.sortsSpatially = false
	v2_.ingameMap.zoomDefault = 2
	v2_.ingameMap.zoomSpeedFactor = 0.1
	v2_.ingameMap.dragStartDistance = 2
	v2_.ingameMap.taggedHotspotsArePersistent = true
	v2_.ingameMap.resetZoomOnOpen = true
	v2_.playerInfo.showVehicleInfo = true
	v2_.playerInfo.showPlaceableInfo = true
	v2_.playerInfo.showNPCNames = true
	v2_.playerInfo.fieldInfoDistance = { 5, 5 }
end
function Platform.applyConsole()
	print("Platform: loading console")
	local v3_ = Platform
	v3_.isConsole = true
	v3_.checkGPUDriver = false
	v3_.allowsScriptMods = false
	v3_.allowsModDirectoryOverride = false
	v3_.hasSlotLimitation = true
	v3_.canChangeGamerTag = false
	v3_.canChangeControls = false
	v3_.hasLimitedModSpace = true
	v3_.showRentServerWebButton = false
	v3_.hasFriendInvitation = true
	v3_.hasFriendFilter = true
	v3_.hasNativeProfiles = true
	v3_.hasNetworkSettings = false
	v3_.hasAdjustableFrameLimit = false
	v3_.canChangeLanguage = false
	v3_.verboseDLCLoading = true
	v3_.allowRestartOnSettingsChange = false
	v3_.supportsPushToTalk = false
	v3_.supportsSavegameDebugUpload = true
	v3_.hasTextChat = false
	v3_.hasAudioChat = true
	v3_.canQuitApplication = false
	v3_.hasNativeStore = true
	v3_.requiresConnectedGamepad = true
	v3_.showGamepadModeDialog = false
	v3_.showHeadTrackingDialog = false
	v3_.safeFrameOffsetX = 40
	v3_.safeFrameOffsetY = 40
	v3_.safeFrameMajorOffsetX = 96
	v3_.safeFrameMajorOffsetY = 54
	v3_.forcedUIResolution = 1080
	v3_.gameplay.maxNumHirables = 6
	v3_.settings.canManageInputDevices = false
	v3_.settings.canManageInputBindings = false
	v3_.settings.canManageDisplaySettings = false
	v3_.settings.simplified = true
	v3_.maxFovY = 1.5707963267948966
	v3_.maxNumMirrors = 0
	local v4_ = Files.new("data/shaders/").files
	for _, v5_ in ipairs(v4_) do
		addReplacedCustomShader(v5_.filename, "data/shaders/" .. v5_.filename)
	end
end
function Platform.applyXbox()
	print("Platform: loading Xbox")
	local v6_ = Platform
	v6_.isXbox = true
	v6_.needsSignIn = true
	v6_.showGamerTagInMainScreen = true
	v6_.maxNumMirrors = 3
	local v7_ = v6_.guiPrefixes
	table.insert(v7_, "xbox_")
	local v8_ = v6_.l10nPostfixes
	table.insert(v8_, "_xboxseries")
	local v9_ = v6_.l10nPostfixes
	table.insert(v9_, "_xbox")
end
function Platform.applyPlaystation()
	print("Platform: loading Playstation")
	local v10_ = Platform
	v10_.isPlaystation = true
	v10_.maxNumMirrors = 5
	local v11_ = v10_.guiPrefixes
	table.insert(v11_, "ps_")
	local v12_ = v10_.l10nPostfixes
	table.insert(v12_, "_ps5")
	local v13_ = v10_.l10nPostfixes
	table.insert(v13_, "_ps")
end
function Platform.applyMobile()
	print("Platform: loading mobile")
	local v14_ = Platform
	v14_.isMobile = true
	v14_.frameLimits = { 30 }
	v14_.defaultFrameLimit = 30
	v14_.lowResCollisionHandlerGridSize = 32
	v14_.lowResCollisionHandlerCellRaysPerFrame = 4
	v14_.checkGPUDriver = false
	v14_.showStartupScreen = false
	v14_.hasMainScreenLanguageSelection = true
	v14_.hasCloudSyncSetting = true
	v14_.hasGrassFilterEnabledByDefault = true
	v14_.supportsSavegameDebugUpload = true
	v14_.hasHDRSettings = false
	v14_.showGamepadModeDialog = false
	v14_.showHeadTrackingDialog = false
	v14_.supportsRealBeaconLights = false
	v14_.canChangeLanguage = false
	v14_.hasTouchInput = true
	v14_.supportsMods = false
	v14_.allowsScriptMods = v14_.supportsMods
	v14_.supportsPedestrians = false
	v14_.supportsFoliageBending = false
	v14_.hasExtraContent = false
	v14_.hasWardrobe = false
	v14_.hasMapSelection = true
	v14_.hasConfigScreen = false
	v14_.autoStartAfterLoad = true
	v14_.hasContruction = false
	v14_.hasIngameMenuGameFrame = true
	v14_.hasAnimalTradingDialog = true
	v14_.hasTourDialog = true
	v14_.hasDifficulty = false
	v14_.hasTouchSliders = true
	v14_.hasModHub = false
	v14_.canQuitApplication = false
	v14_.supportsMultiplayer = false
	v14_.hasHints = true
	v14_.hasInGameMenuMainPage = true
	v14_.hasPlayer = true
	v14_.allowPlayerPickUp = false
	v14_.safeFrameOffsetX = 50
	v14_.safeFrameOffsetY = 50
	v14_.forcedUIResolution = 1080
	v14_.urlRating = "lp/fs23-rating.php"
	v14_.settings.simplified = false
	v14_.settings.canManageInputDevices = false
	v14_.settings.canManageInputBindings = false
	v14_.settings.canManageDisplaySettings = false
	v14_.gameLogos = {
		["en"] = "dataS/menu/main_logo_mobile_en.png",
		["de"] = "dataS/menu/main_logo_mobile_de.png"
	}
	v14_.usesFixedExposure = true
	v14_.preShaderContentFiles = {
		"data/preShaderContent/map_part1.i3d",
		"data/preShaderContent/map_part2.i3d",
		"data/preShaderContent/map_part3.i3d",
		"data/preShaderContent/map_part4.i3d",
		"data/preShaderContent/map_part5.i3d",
		"data/preShaderContent/vehicle_part1.i3d",
		"data/preShaderContent/vehicle_part2.i3d",
		"data/preShaderContent/vehicle_part3.i3d",
		"data/preShaderContent/vehicle_part4.i3d",
		"data/preShaderContent/vehicle_part5.i3d"
	}
	v14_.gameplay.defaultTimeScale = 60
	v14_.gameplay.timeScaleSettings = {
		1,
		2,
		5,
		10,
		30,
		45,
		60,
		90
	}
	v14_.gameplay.hasShortNights = true
	v14_.gameplay.hasLoans = false
	v14_.gameplay.hasVehicleSales = false
	v14_.gameplay.sprayLevelMaxValue = 1
	v14_.gameplay.harvestScaleRation = {
		0.6,
		0.2,
		0,
		0.2,
		0,
		0
	}
	v14_.gameplay.useSprayDiffuseMaps = false
	v14_.gameplay.useMultipleSprayLevels = false
	v14_.gameplay.usePlowCounter = true
	v14_.gameplay.defaultPlowingRequiredEnabled = true
	v14_.gameplay.useLimeCounter = false
	v14_.gameplay.useStubbleShred = false
	v14_.gameplay.useRolling = false
	v14_.gameplay.ingameMapFruitsPerPage = math.huge
	v14_.gameplay.supportsWithering = false
	v14_.gameplay.maxNumHirables = 6
	v14_.gameplay.canVisitPOI = false
	v14_.gameplay.supportSeasonalGrowth = false
	v14_.gameplay.supportSnow = false
	v14_.gameplay.automaticDischarge = true
	v14_.gameplay.automaticFilling = false
	v14_.gameplay.automaticAttach = true
	v14_.gameplay.automaticBaleDrop = true
	v14_.gameplay.automaticLights = true
	v14_.gameplay.automaticPipeUnfolding = true
	v14_.gameplay.automaticVehicleControl = true
	v14_.gameplay.keepFoldingWhileDetached = true
	v14_.gameplay.foldAfterAIFinished = true
	v14_.gameplay.lightsProfile = GS_PROFILE_LOW
	v14_.gameplay.useWorldCameraInside = false
	v14_.gameplay.useWorldCameraOutside = true
	v14_.gameplay.hasShadowFocusBox = false
	v14_.gameplay.hasVehicleCharacterIdleAnimations = false
	v14_.gameplay.allowVehicleCharacterIKDirtyUpdate = false
	v14_.gameplay.hasDetachedPowerTakeOffs = false
	v14_.gameplay.hasTMRMixing = false
	v14_.gameplay.dischargeSpeedFactor = 2
	v14_.gameplay.maxCameraZoomFactor = 0.6
	v14_.gameplay.dirtDurationScale = 2
	v14_.gameplay.hasVehicleDamage = false
	v14_.gameplay.allowSuspensionNodes = false
	v14_.gameplay.allowTestAreas = false
	v14_.gameplay.allowAutomaticHeaderTilt = false
	v14_.gameplay.hasBaleFermentation = false
	v14_.gameplay.steeringBackSpeedSettings = { 5, 7.5, 10 }
	v14_.gameplay.canCreateFields = false
	v14_.gameplay.treeCutFarmlandRestrictions = false
	v14_.gameplay.hasDynamicPallets = false
	v14_.gameplay.hasVehicleConfigs = false
	v14_.gameplay.hasWeeder = false
	v14_.gameplay.needHorseCleaning = false
	v14_.gameplay.canRenameHorses = false
	v14_.gameplay.disabledShopSpecValues = {
		["balerBaleSizeRound"] = true,
		["balerBaleSizeSquare"] = true,
		["baleWrapperBaleSizeRound"] = true,
		["baleWrapperBaleSizeSquare"] = true,
		["baleLoaderBaleSizeRound"] = true,
		["baleLoaderBaleSizeSquare"] = true,
		["transmission"] = true,
		["woodHarvesterMaxTreeSize"] = true
	}
	v14_.ui.drawHudOnDialog = true
	v14_.gameplay.wheelDensityHeightSmooth = false
	v14_.gameplay.wheelVisualPressure = true
	v14_.gameplay.wheelVisualPressureUpdateThreshold = 0.0025
	v14_.gameplay.wheelTireTracks = false
	v14_.gameplay.defaultFruitDestruction = false
	v14_.ingameMap.canZoom = true
	v14_.ingameMap.needsSolidBackground = false
	v14_.ingameMap.sortsSpatially = true
	v14_.ingameMap.zoomDefault = 1
	v14_.ingameMap.zoomSpeedFactor = 0.07
	v14_.ingameMap.dragStartDistance = 3
	v14_.ingameMap.taggedHotspotsArePersistent = false
	v14_.ingameMap.resetZoomOnOpen = false
	v14_.playerInfo.showVehicleInfo = false
	v14_.playerInfo.showPlaceableInfo = false
	v14_.playerInfo.showNPCNames = false
	v14_.playerInfo.fieldInfoDistance = { 1, 1 }
	local v15_ = v14_.l10nPostfixes
	table.insert(v15_, "_mobile")
end
function Platform.applySwitch2()
	print("Platform: loading Switch 2")
	local v16_ = Platform
	v16_.isSwitch2 = true
	v16_.canQuitApplication = false
	v16_.supportsMultiplayer = false
	v16_.requiresConnectedGamepad = false
	v16_.supportsMods = true
	v16_.hasNativeStore = false
	v16_.showGamepadModeDialog = false
	v16_.showHeadTrackingDialog = false
	v16_.autoSelectDLCs = true
	v16_.hasTouchInput = true
	v16_.hasOnlineAchievements = false
	v16_.maxNumMirrors = 0
	v16_.canChangeLanguage = true
	v16_.showVideoFS = false
	v16_.defaultUIScale = 1.25
	v16_.gameplay.supportsTwister = false
	v16_.allowRestartOnSettingsChange = true
	local v17_ = v16_.guiPrefixes
	table.insert(v17_, "switch2_")
	local v18_ = v16_.guiPrefixes
	table.insert(v18_, "switch_")
	local v19_ = v16_.l10nPostfixes
	table.insert(v19_, "_switch2")
	local v20_ = v16_.l10nPostfixes
	table.insert(v20_, "_switch")
	v16_.gameLogos = {
		["en"] = "dataS/menu/main_logo_signatureEdition_en.png",
		["de"] = "dataS/menu/main_logo_signatureEdition_de.png"
	}
end
function Platform.applySwitch()
	print("Platform: loading Switch")
	local v21_ = Platform
	v21_.isSwitch = true
	v21_.showStartupScreen = true
	v21_.showVideoFS = false
	v21_.hasTouchSliders = false
	v21_.hasCloudSyncSetting = false
	v21_.preShaderContentFiles = nil
	local v22_ = v21_.guiPrefixes
	table.insert(v22_, "switch_")
	local v23_ = v21_.l10nPostfixes
	table.insert(v23_, "_switch")
	v21_.gameLogos = {
		["en"] = "dataS/menu/main_logo_switch_en.png",
		["de"] = "dataS/menu/main_logo_switch_de.png"
	}
	v21_.gameplay.defaultGyroscopeSteering = false
	v21_.gameplay.defaultCameraTilt = false
end
function Platform.applyIOS()
	print("Platform: loading iOS")
	local v24_ = Platform
	v24_.isIOS = true
	v24_.hasInAppPurchases = true
	v24_.gameRatingEnabled = true
	v24_.showGamerTagInMainScreen = false
end
function Platform.applyAndroid()
	print("Platform: loading Android")
	local v25_ = Platform
	v25_.isAndroid = true
	v25_.hasInAppPurchases = true
	v25_.gameRatingEnabled = true
	v25_.showGamerTagInMainScreen = false
end
function Platform.applyNetflix()
	print("Platform: loading Netflix")
	Platform.gameRatingEnabled = true
	Platform.urlRating = "lp/fs23Netflix-rating.php"
	Platform.hasInAppPurchases = false
	Platform.isNetflix = true
	Platform.gameLogos = {
		["en"] = "dataS/menu/main_logo_netflix_en.png",
		["de"] = "dataS/menu/main_logo_netflix_de.png"
	}
end
function Platform.applyMSStore()
	print("Platform: loading MSStore")
	local v26_ = Platform
	v26_.canChangeGamerTag = false
	v26_.showGamerTagInMainScreen = true
end
function Platform.applySteam()
	print("Platform: loading Steam")
	Platform.urlDedicatedServer = "fs25-rent-a-dedicated-server-from-steam.php"
end
function Platform.verifyMultiplayerAvailabilityInMenu()
	if getMultiplayerAvailability() == MultiplayerAvailability.NOT_AVAILABLE then
		g_masterServerConnection:disconnectFromMasterServer()
		g_gui:changeScreen(nil, MainScreen)
	end
	if getNetworkError() then
		g_masterServerConnection:disconnectFromMasterServer()
		ConnectionFailedDialog.showMasterServerConnectionFailedReason(MasterServerConnection.FAILED_CONNECTION_LOST, "MainScreen")
	end
end
Platform.init()
