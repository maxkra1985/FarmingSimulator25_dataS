local localDeleteFile = deleteFile
local localDeleteFolder = deleteFolder
KioskMode = {}
KioskMode.GAMEPAD_NAME = "JoyWarrior Gamepad 32"
KioskMode.BIT_TO_BUTTON_ID = { 7, 6, 5, 4, 3, 2, 1, 0, [15] = 8, [16] = 9, [17] = 10 }
function KioskMode.EMPTY_FUNC() end
KioskMode.END_SLIDE_BAR_POSITION = "576px 130px"
KioskMode.END_SLIDE_BAR_SIZE = "768px 13px"
KioskMode.END_SLIDE_TEXT_SIZE = "22px"
KioskMode.END_SLIDE_TEXT_OFFSET = "13px"
KioskMode.END_SLIDE_BUTTON_OFFSET = "14px"
local KioskMode_mt = Class(KioskMode)
function KioskMode.new(customMt)
	local self = setmetatable({}, customMt or KioskMode_mt)
	local path = "kioskMode/"
	self.configPaths = { "dataS/" .. "kioskMode/", "data/" .. "kioskMode/", getUserProfileAppPath() .. "kioskMode/" }
	self.profileSelectorGamepadId = nil
	self.currentProfile = nil
	self.profiles = {}
	self.maskToProfile = {}
	self.settings = {}
	self.nextLanguageRestartTimer = nil
	self.nextLanguageIndex = nil
	self.maps = {}
	return self
end
function KioskMode:generateBitmasks()
	local mapping = { 1, 2, 3, 4, 5, 6, 7, 8, 15, 16, 17 }
	local generatedMasks = {}
	local hashedMasks = {}
	local printResult = function(target, n)
		local bitMask = 0
		for k, v in ipairs(target) do
			if v == 1 then
				bitMask = Utils.setBit(bitMask, mapping[k])
			end
		end
		if hashedMasks[bitMask] == nil then
			table.insert(generatedMasks, bitMask)
			hashedMasks[bitMask] = true
		else
			Logging.warning("Mask %s already exists", table.concat(target, ""))
		end
	end
	local function bitmask(n, target, i)
		if i == n then
			printResult(target, n)
		else
			target[i] = 0
			bitmask(n, target, i + 1)
			target[i] = 1
			bitmask(n, target, i + 1)
		end
	end
	local target = {}
	masks[1] = 0
	bitmask(12, masks, 2)
	masks[1] = 1
	bitmask(12, masks, 2)
	for i, mask in ipairs(generatedMasks) do
		local str = ""
		for k = 1, 20 do
			if (k - 1) % 5 == 0 then
				str = str .. " "
			end
			if k == 18 then
				str = str .. "0"
			elseif KioskMode.BIT_TO_BUTTON_ID[k] == nil then
				str = str .. (0.5 < math.random() and 1 or 0)
			else
				str = str .. (Utils.isBitSet(mask, k) and 1 or 0)
			end
		end
		print(string.format("%s", str))
	end
end
function KioskMode:delete()
	self:disposeVideo()
end
function KioskMode:load()
	if StartParams.getIsSet("kioskDisabled") then
		return false
	end
	local isLoaded = false
	for _, path in ipairs(self.configPaths) do
		if self:loadFromPath(path) then
			isLoaded = true
		end
	end
	if not isLoaded then
		return false
	else
		InGameMenu.makeIsAIEnabledPredicate = KioskMode.inj_inGameMenu_makeIsAIEnabledPredicate
		InGameMenu.makeIsPricesEnabledPredicate = KioskMode.inj_inGameMenu_makeIsPricesEnabledPredicate
		InGameMenu.makeIsAnimalsEnabledPredicate = KioskMode.inj_inGameMenu_makeIsAnimalsEnabledPredicate
		InGameMenu.makeIsContractsEnabledPredicate = KioskMode.inj_inGameMenu_makeIsContractsEnabledPredicate
		InGameMenu.makeIsGarageEnabledPredicate = KioskMode.inj_inGameMenu_makeIsGarageEnabledPredicate
		InGameMenu.makeIsSettingsEnabledPredicate = KioskMode.inj_inGameMenu_makeIsSettingsEnabledPredicate
		InGameMenu.makeIsHelpEnabledPredicate = KioskMode.inj_inGameMenu_makeIsHelpEnabledPredicate
		InGameMenuSettingsFrame.initializeButtons = Utils.overwrittenFunction(InGameMenuSettingsFrame.initializeButtons, KioskMode.inj_inGameMenuSettingsFrame_initializeButtons)
		MapManager.addMapItem = Utils.overwrittenFunction(MapManager.addMapItem, KioskMode.inj_mapManager_addMapItem)
		function loadMods()
			haveModsChanged()
		end
		InputBinding.loadModActions = Utils.overwrittenFunction(InputBinding.loadModActions, KioskMode.inj_inputBinding_loadModActions)
		InputBinding.loadModBindingDefaults = Utils.overwrittenFunction(InputBinding.loadModBindingDefaults, KioskMode.inj_inputBinding_loadModBindingDefaults)
		Gui.changeScreen = Utils.overwrittenFunction(Gui.changeScreen, KioskMode.inj_gui_changeScreen)
		Gui.showGui = Utils.overwrittenFunction(Gui.showGui, KioskMode.inj_gui_showGui)
		MessageCenter.publish = Utils.overwrittenFunction(MessageCenter.publish, KioskMode.inj_messageCenter_publish)
		if Platform.isPC and StartParams.getIsSet("kioskModeResetFiles") then
			local inputBinding = getUserProfileAppPath() .. "inputBinding.xml"
			if fileExists(inputBinding) then
				localDeleteFile(inputBinding)
			end
			local gameSettings = getUserProfileAppPath() .. "gameSettings.xml"
			if fileExists(gameSettings) then
				localDeleteFile(gameSettings)
			end
		end
		function modDownloadManagerLoaded()
			return false
		end
		return true
	end
end
function KioskMode:loadFromPath(path)
	local configFileName = path .. "kioskMode.xml"
	if not fileExists(configFileName) then
		return false
	end
	local zipFilePath = string.sub(path, 1, #path - 1) .. ".zip"
	if folderExists(path) and fileExists(zipFilePath) then
		Logging.error("Kiosk mode config directory %q also has a zip file with the same name %q next to it overriding any changes made in the directory. Delete or rename the zip file!", path, zipFilePath)
		return false
	end
	local xmlFile = XMLFile.load("KioskMode", configFileName, nil)
	if xmlFile == nil then
		return false
	end
	local defaultConfigFile = Utils.getFilename(xmlFile:getString("kioskMode.defaultProfile.configFile", ""), path)
	if not fileExists(defaultConfigFile) then
		Logging.xmlWarning(xmlFile, "KioskMode:loadFromPath - default config file '%s' not found", defaultConfigFile)
		return false
	end
	self.defaultConfigFile = defaultConfigFile
	for _, key in xmlFile:iterator("kioskMode.profiles.profile") do
		local name = xmlFile:getString(key .. "#name", "")
		local configFile = Utils.getFilename(xmlFile:getString(key .. ".configFile", ""), path)
		if not fileExists(configFile) then
			Logging.xmlWarning(xmlFile, "KioskMode:loadFromPath - config file '%s' for profile '%s' not found. Ignoring this profile", configFile, name)
		else
			local mask = 0
			local bitCount = 1
			local bitsStr = xmlFile:getString(key .. "#bits", "")
			local len = bitsStr:len()
			if len ~= 23 then
				Logging.xmlWarning(xmlFile, "KioskMode:loadFromPath - invalid bitsformat (##### ##### ##### #####) for profile '%s'. Ignoring this profile", name)
			else
				for i = 1, bitsStr:len() do
					local bit = bitsStr:sub(i, i)
					if bit == " " then
						continue
					end
					bit = tonumber(bit)
					if bit == 1 then
						if KioskMode.BIT_TO_BUTTON_ID[bitCount] ~= nil then
							mask = Utils.setBit(mask, bitCount)
						elseif bitCount == 18 then
							Logging.xmlWarning(xmlFile, "KioskMode:loadFromPath - Bit %d cannot be used. Please replace it with 0 for profile '%s'", bitCount, name)
						end
					end
					bitCount = bitCount + 1
				end
				if self.maskToProfile[mask] ~= nil then
					local usedProfile = self.maskToProfile[mask]
					Logging.xmlWarning(xmlFile, "KioskMode:loadFromPath - %s mask already used for profile '%s'. Ignoring this profile", name, usedProfile.name)
				else
					local profile = { name = name, mask = mask, configFile = configFile }
					profile.id = #self.profiles + 1
					self.maskToProfile[mask] = profile
					table.insert(self.profiles, profile)
				end
			end
		end
	end
	xmlFile:delete()
	if #self.profiles == 0 then
		Logging.xmlWarning(xmlFile, "KioskMode:loadFromPath - No profiles defined!")
		return false
	else
		self.configFileName = configFileName
		table.insert(g_dlcsDirectories, { path = path .. "pdlc/", isLoaded = true })
		return true
	end
end
function KioskMode:loadInputActions()
	if self.configFileName ~= nil then
		local xmlFileObj = XMLFile.load("KioskMode Inputs", self.configFileName)
		local xmlFile = xmlFileObj:getHandle()
		g_inputBinding:loadActionsFromXMLPath(xmlFile, "kioskMode.input.actions", g_i18n, nil)
		xmlFileObj:delete()
	end
end
function KioskMode:loadInputBindings()
	if self.configFileName ~= nil then
		local xmlFileObj = XMLFile.load("KioskMode Inputs", self.configFileName)
		local xmlFile = xmlFileObj:getHandle()
		g_inputBinding:loadActionBindingsFromXMLPath(xmlFile, "kioskMode.input.bindings", true, nil, true, true)
		xmlFileObj:delete()
	end
end
function KioskMode:initializedGUIClasses()
	MainScreen.onOpen = Utils.appendedFunction(MainScreen.onOpen, KioskMode.inj_mainScreen_onOpen)
	MainScreen.update = Utils.overwrittenFunction(MainScreen.update, KioskMode.inj_mainScreen_update)
	MainScreen.onClose = Utils.appendedFunction(MainScreen.onClose, KioskMode.inj_mainScreen_onClose)
	MainScreen.inputEvent = Utils.overwrittenFunction(MainScreen.inputEvent, KioskMode.inj_mainScreen_inputEvent)
	MainScreen.updateStoreButtons = KioskMode.EMPTY_FUNC
	MPLoadingScreen.openWardrobe = KioskMode.EMPTY_FUNC
	MPLoadingScreen.onReadyToStart = Utils.overwrittenFunction(MPLoadingScreen.onReadyToStart, KioskMode.inj_mpLoadingScreen_onReadyToStart)
	InGameMenuMobileSettingsFrame.onFrameOpen = Utils.appendedFunction(InGameMenuMobileSettingsFrame.onFrameOpen, KioskMode.inj_inGameMenuMobileSettingsFrame_onFrameOpen)
	InGameMenu.onButtonSaveGame = KioskMode.EMPTY_FUNC
	CareerScreen.updateButtons = Utils.appendedFunction(CareerScreen.updateButtons, KioskMode.inj_careerScreen_updateButtons)
	CareerScreen.update = Utils.appendedFunction(CareerScreen.update, KioskMode.inj_careerScreen_update)
	ModSelectionScreen.update = Utils.appendedFunction(ModSelectionScreen.update, KioskMode.inj_modSelectionScreenn_update)
	NewGameScreen.update = Utils.appendedFunction(NewGameScreen.update, KioskMode.inj_newGameScreen_update)
	InGameMenuMapFrame.updateInputGlyphs = Utils.appendedFunction(InGameMenuMapFrame.updateInputGlyphs, KioskMode.inj_inGameMenuMapFrame_updateInputGlyphs)
end
function KioskMode:init()
	self:initProfileSelectorGamepad()
	HUD.createDisplayComponents = Utils.appendedFunction(HUD.createDisplayComponents, KioskMode.inj_hud_createDisplayComponents)
	Mission00.getIsTourSupported = Utils.overwrittenFunction(Mission00.getIsTourSupported, KioskMode.inj_mission00_getIsTourSupported)
	Mission00.onStartMission = Utils.appendedFunction(Mission00.onStartMission, KioskMode.inj_mission00_onStartMission)
	SpecializationManager.addSpecialization = Utils.appendedFunction(SpecializationManager.addSpecialization, KioskMode.inj_specializationManager_addSpecialization)
	PlayerInputComponent.registerGlobalPlayerActionEvents = Utils.appendedFunction(PlayerInputComponent.registerGlobalPlayerActionEvents, KioskMode.inj_playerInputComponent_registerGlobalPlayerActionEvents)
	PlayerInputComponent.getCanToggleCamera = Utils.appendedFunction(PlayerInputComponent.getCanToggleCamera, KioskMode.inj_playerInputComponent_getCanToggleCamera)
	FSBaseMission.getIsAutoSaveSupported = Utils.appendedFunction(FSBaseMission.getIsAutoSaveSupported, KioskMode.inj_fsBaseMission_getIsAutoSaveSupported)
	FSBaseMission.update = Utils.appendedFunction(FSBaseMission.update, KioskMode.inj_fsBaseMission_update)
	AnimalLoadingTrigger.load = Utils.overwrittenFunction(AnimalLoadingTrigger.load, KioskMode.inj_animalLoadingTrigger_load)
	VehicleSellingPoint.load = Utils.overwrittenFunction(VehicleSellingPoint.load, KioskMode.inj_vehicleSellingPoint_load)
	ShopTrigger.new = Utils.overwrittenFunction(ShopTrigger.new, KioskMode.inj_shopTrigger_new)
	LoanTrigger.new = Utils.overwrittenFunction(LoanTrigger.new, KioskMode.inj_loanTrigger_new)
	Environment.load = Utils.overwrittenFunction(Environment.load, KioskMode.inj_environment_load)
	StoreManager.getDefaultStoreItemsFilename = Utils.overwrittenFunction(StoreManager.getDefaultStoreItemsFilename, KioskMode.inj_storeManager_getDefaultStoreItemsFilename)
	ProductionPointActivatable.run = Utils.overwrittenFunction(ProductionPointActivatable.run, KioskMode.inj_productionPointActivatable_run)
	Farm.setInitialEconomy = Utils.appendedFunction(Farm.setInitialEconomy, KioskMode.inj_Farm_setInitialEconomy)
	function MissionManager.update(dt) end
	function SavegameController.getCanDeleteGame()
		return false
	end
	IngameMap.registerInput = Utils.overwrittenFunction(IngameMap.registerInput, KioskMode.inj_ingameMap_registerInput)
	RailroadCallerActivatable.run = Utils.overwrittenFunction(RailroadCallerActivatable.run, KioskMode.inj_railroadCallerActivatable_run)
	function getNumOfNotifications()
		return 0
	end
	function areAchievementsAvailable()
		return false
	end
	self:loadProfileConfig(self.defaultConfigFile)
	if GS_PLATFORM_PC and not g_gameSettings:getValue("gamepadEnabledSetByUser") then
		g_gameSettings:setValue("gamepadEnabledSetByUser", true)
		g_gameSettings:setValue("isGamepadEnabled", true)
		g_gameSettings:save()
	end
end
function KioskMode:initProfileSelectorGamepad()
	local numOfGamepads = getNumOfGamepads()
	for i = 0, numOfGamepads - 1 do
		local gamepadName = getGamepadName(i)
		if gamepadName == KioskMode.GAMEPAD_NAME then
			Logging.info("KioskMode:initProfileSelectorGamepad - Found Gaming Station with gamepad '%s'", gamepadName)
			self.profileSelectorGamepadId = i
		end
	end
	if self.profileSelectorGamepadId ~= nil then
		local oldGetIsDeviceSupported = InputDevice.getIsDeviceSupported
		function InputDevice.getIsDeviceSupported(engineDeviceId, deviceName)
			if not oldGetIsDeviceSupported(engineDeviceId, deviceName) then
				return false
			elseif deviceName == KioskMode.GAMEPAD_NAME then
				return false
			else
				return true
			end
		end
	end
	return self.profileSelectorGamepadId ~= nil
end
function KioskMode:loadProfileConfig(configFileName)
	Logging.info("KioskMode:loadProfileConfig - Loading profile config '%s'", configFileName)
	local xmlFile = XMLFile.load("KioskMode Profile", configFileName)
	local path = Utils.getDirectory(configFileName)
	self.settings.canSelectSavegame = xmlFile:getBool("config.canSelectSavegame", false)
	self.settings.canSelectMods = xmlFile:getBool("config.canSelectMods", false)
	if not self.settings.canSelectSavegame then
		local savegamePath = xmlFile:getString("config.savegame")
		if savegamePath ~= nil then
			savegamePath = Utils.getFilename(savegamePath, path)
		end
		self:setSavegame(savegamePath)
		self.settings.savegame = savegamePath
	end
	local logo = xmlFile:getString("config.logo")
	if logo ~= nil then
		self.settings.logoFilename = Utils.getFilename(logo, path)
		self.settings.logoWidth = xmlFile:getInt("config.logo#width", 600)
		self.settings.logoHeight = xmlFile:getInt("config.logo#height", 150)
	end
	self.settings.logoEnabled = logo ~= nil
	local endSlide = xmlFile:getString("config.endSlide")
	if endSlide ~= nil then
		self.settings.endSlide = Utils.getFilename(endSlide, path)
	end
	self.settings.tourEnabled = xmlFile:getBool("config.tourEnabled", false)
	self.settings.aiEnabled = xmlFile:getBool("config.aiEnabled", true)
	self.settings.aiWorkerEnabled = xmlFile:getBool("config.aiWorkerEnabled", true)
	self.settings.mainMenuEnabled = xmlFile:getBool("config.mainMenuEnabled", false)
	self.settings.watermarkEnabled = xmlFile:getBool("config.watermarkEnabled", false)
	self.settings.ingameMenuEnabled = xmlFile:getBool("config.ingameMenuEnabled", true)
	self.settings.reloadEnabled = xmlFile:getBool("config.reloadEnabled", false)
	self.settings.animalShopEnabled = xmlFile:getBool("config.shopsEnabled.animals", false)
	self.settings.vehicleShopEnabled = xmlFile:getBool("config.shopsEnabled.vehicles", false)
	self.settings.farmlandShopEnabled = xmlFile:getBool("config.shopsEnabled.farmlands", false)
	self.settings.placeableShopEnabled = xmlFile:getBool("config.shopsEnabled.placeables", false)
	self.settings.wardrobeShopEnabled = xmlFile:getBool("config.shopsEnabled.wardrobe", false)
	self.settings.productionEnabled = xmlFile:getBool("config.productionEnabled", true)
	self.settings.trainEnabled = xmlFile:getBool("config.trainEnabled", false)
	self.settings.riceFieldEnabled = xmlFile:getBool("config.riceFieldEnabled", true)
	self.settings.helpLineTriggerEnabled = xmlFile:getBool("config.helpLineTriggerEnabled", true)
	self.settings.extendedDrivingHelp = xmlFile:getBool("config.extendedDrivingHelp", false)
	self.settings.alwaysDay = xmlFile:getBool("config.alwaysDay", false)
	self.settings.startMoney = xmlFile:getInt("config.startMoney", 1000000)
	self.settings.skipMainMenu = xmlFile:getBool("config.skipMainMenu", false)
	self.settings.farmlandsBuyAll = xmlFile:getBool("config.farmlandsBuyAll", false)
	self.settings.startVehicleIndex = xmlFile:getInt("config.startVehicleIndex", nil)
	self.settings.playerCanToggleCamera = xmlFile:getBool("config.player.canToggleCamera", false)
	if KioskMode.TIMESCALE_BACKUP == nil then
		KioskMode.TIMESCALE_BACKUP = Platform.gameplay.timeScaleSettings
		KioskMode.TIMESCALE_DEV_BACKUP = Platform.gameplay.timeScaleDevSettings
	end
	Platform.gameplay.timeScaleSettings = KioskMode.TIMESCALE_BACKUP
	Platform.gameplay.timeScaleDevSettings = KioskMode.TIMESCALE_DEV_BACKUP
	local timescales = xmlFile:getString("config.timescales", nil)
	if timescales ~= nil then
		local newTimescales = string.getVector(timescales)
		if 0 < #newTimescales then
			Platform.gameplay.timeScaleSettings = newTimescales
			Platform.gameplay.timeScaleDevSettings = {}
		end
	end
	local mapsStr = xmlFile:getString("config.maps", "")
	local mapIds = string.split(mapsStr, " ")
	self.settings.maps = nil
	for _, id in ipairs(mapIds) do
		if self.settings.maps == nil then
			self.settings.maps = {}
		end
		self.settings.maps[id] = true
	end
	self:updateAvailableMaps()
	local storeItems = xmlFile:getString("config.storeItems", "")
	if storeItems ~= "" then
		storeItems = Utils.getFilename(storeItems, path)
	else
		storeItems = nil
	end
	self.settings.storeItems = storeItems
	local videos = nil
	local duration = nil
	local videosDirectory = xmlFile:getString("config.videos", "")
	if videosDirectory ~= "" then
		videosDirectory = Utils.getFilename(videosDirectory, path)
		local files = Files.new(videosDirectory).files
		for _, file in ipairs(files) do
			local videoPath = videosDirectory .. "/" .. file.filename
			if fileExists(videoPath) then
				if videos == nil then
					videos = {}
				end
				table.insert(videos, videosDirectory .. "/" .. file.filename)
			end
		end
		duration = xmlFile:getInt("config.videos#inactiveDurationSeconds", 180) * 1000
		if videos == nil or #videos == 0 then
			videos = nil
			duration = nil
			Logging.warning("KioskMode: No videos found in '%s'", videosDirectory)
		end
	end
	self.settings.videos = videos
	self.settings.videoTimer = duration
	local playtimeSeconds = xmlFile:getFloat("config.playtimeSeconds")
	if playtimeSeconds ~= nil then
		self.settings.playtimeDuration = playtimeSeconds * 1000
	end
	self.settings.playtimeEnabled = playtimeSeconds ~= nil
	local mods = {}
	xmlFile:iterate("config.mods.mod", function(_, key)
		local modId = xmlFile:getString(key)
		if modId ~= nil then
			table.insert(mods, modId)
		end
	end)
	self.settings.mods = mods
	self:openMainMenu()
	self:setupMainMenu()
	xmlFile:delete()
end
function KioskMode:update(dt)
	if (self.profileSelectorGamepadId ~= nil or StartParams.getIsSet("kioskProfileId") or StartParams.getIsSet("kioskProfileName")) and (g_gui.currentGuiName == "MainScreen" and self.currentProfile == nil) then
		local profile = self:getProfile()
		if profile ~= nil then
			self:loadProfileConfig(profile.configFile)
			self.currentProfile = profile
		end
	end
	if GS_PLATFORM_PC and (self.nextLanguageRestartTimer ~= nil and self.nextLanguageRestartTimer < g_time) then
		doRestart(false, "")
	end
	if g_currentMission ~= nil and self.playtimeReloadTimer ~= nil then
		self.playtimeReloadTimer = self.playtimeReloadTimer - dt
		if self.playtimeReloadTimer <= 0 then
			self.playtimeReloadTimer = nil
			self:onPlaytimeReload()
		end
	end
	if self.currentVideoIndex == nil then
		if self.videoStartTimer ~= nil then
			self.videoStartTimer = self.videoStartTimer - dt
			if self.videoStartTimer < 0 then
				self:nextVideo()
			end
		end
	else
		if self.videoOverlay ~= nil and isVideoOverlayPlaying(self.videoOverlay) then
			updateVideoOverlay(self.videoOverlay)
			return
		end
		if self.videoOverlay ~= nil then
			self:disposeVideo()
			self:nextVideo()
		end
	end
end
function KioskMode:draw()
	self:drawEndSlide()
	if self.nextLanguageIndex ~= nil then
		setTextAlignment(RenderText.ALIGN_CENTER)
		setTextBold(true)
		setTextColor(0, 0, 0, 1)
		local timeLeft = math.ceil((self.nextLanguageRestartTimer - g_time) / 1000)
		local langName = getLanguageName(self.nextLanguageIndex)
		renderText(0.5 + 2 * g_pixelSizeX, 0.75 - g_pixelSizeY, 0.025, string.format("Changing Language.\nNew language after restart will be '%s'. \nRestarting in %d seconds...", langName, timeLeft))
		setTextColor(1, 1, 1, 1)
		renderText(0.5, 0.75, 0.025, string.format("Changing Language.\nNew language after restart will be '%s'. \nRestarting in %d seconds...", langName, timeLeft))
		setTextAlignment(RenderText.ALIGN_LEFT)
		setTextBold(false)
	end
	if g_gui.currentGuiName == "MainScreen" and self.currentProfile ~= nil then
		setTextAlignment(RenderText.ALIGN_LEFT)
		local name = self.currentProfile.name
		setTextColor(0, 0, 0, 0.75)
		renderText(0.01, 0.9585, 0.011, name)
		setTextColor(1, 1, 1, 1)
		renderText(0.01, 0.96, 0.011, name)
	end
	if g_currentMission ~= nil and g_currentMission.hud ~= nil then
		local isNotFading = not g_currentMission.hud:getIsFading()
		local isUIVisible = g_gui:getIsGuiVisible()
		if self:getSetting("logoEnabled") and (not isUIVisible and isNotFading) then
			g_currentMission.hud.kioskModeLogoElement:draw()
		end
		if self.playtimeReloadTimer ~= nil then
			local left = string.format("%0.1d:", self.playtimeReloadTimer / 60000)
			local right = string.format("%0.2d", self.playtimeReloadTimer / 1000 % 60)
			setTextBold(true)
			setTextAlignment(RenderText.ALIGN_RIGHT)
			renderText(0.5, isUIVisible and 0.85 or 0.932, 0.05, left)
			setTextAlignment(RenderText.ALIGN_LEFT)
			renderText(0.5, isUIVisible and 0.85 or 0.932, 0.05, right)
			setTextBold(false)
		end
	end
	if self:getSetting("watermarkEnabled") then
		setTextAlignment(RenderText.ALIGN_CENTER)
		setTextBold(true)
		setTextColor(1, 1, 1, 0.5)
		renderText(0.5, 0.75, getCorrectTextSize(0.075), "INTERNAL USE ONLY")
		renderText(0.5, 0.73, getCorrectTextSize(0.03), "Copyright GIANTS Software GmbH")
		setTextColor(1, 1, 1, 1)
		setTextBold(false)
		setTextAlignment(RenderText.ALIGN_LEFT)
	end
	if self.videoOverlay ~= nil and isVideoOverlayPlaying(self.videoOverlay) then
		new2DLayer()
		renderOverlay(self.videoOverlay, 0, 0, 1, 1)
	end
end
function KioskMode:drawEndSlide()
	local endSlide = self:getEndSlideOnLoad()
	local isLoadingScreen = endSlide ~= nil and g_gui.currentGuiName == "MPLoadingScreen"
	if not isLoadingScreen then
		if self.endSlideOverlay ~= nil then
			self.endSlideOverlay:delete()
			self.endSlideOverlay = nil
		end
	else
		if self.endSlideOverlay == nil then
			self.endSlideOverlay = Overlay.new(endSlide, 0, 0, 1, g_screenAspectRatio)
		end
		new2DLayer()
		self.endSlideOverlay:render()
		local progress = g_mpLoadingScreen ~= nil and g_mpLoadingScreen.totalLoadPercentage or 0
		progress = math.clamp(progress, 0, 1)
		local barPosition = GuiUtils.getNormalizedScreenValues(KioskMode.END_SLIDE_BAR_POSITION)
		local barSize = GuiUtils.getNormalizedScreenValues(KioskMode.END_SLIDE_BAR_SIZE)
		local barX = barPosition[1]
		local barY = barPosition[2]
		local barWidth = barSize[1]
		local barHeight = barSize[2]
		drawFilledRect(barX, barY, barWidth, barHeight, 0, 0, 0, 0.5)
		drawFilledRect(barX, barY, barWidth * progress, barHeight, 1, 1, 1, 1)
		local textSize = GuiUtils.getNormalizedValue(KioskMode.END_SLIDE_TEXT_SIZE, false)
		local textOffset = GuiUtils.getNormalizedValue(KioskMode.END_SLIDE_TEXT_OFFSET, false)
		setTextAlignment(RenderText.ALIGN_CENTER)
		setTextBold(true)
		setTextColor(1, 1, 1, 1)
		local percentageY = barY + barHeight + textOffset
		renderText(0.5, percentageY, textSize, string.format("%d%%", progress * 100))
		setTextAlignment(RenderText.ALIGN_LEFT)
		setTextBold(false)
		local isReady = g_mpLoadingScreen ~= nil and g_mpLoadingScreen.button ~= nil and g_mpLoadingScreen.state == MPLoadingScreen.STATE_READY
		if isReady then
			local button = g_mpLoadingScreen.button
			local buttonOffset = GuiUtils.getNormalizedValue(KioskMode.END_SLIDE_BUTTON_OFFSET, false)
			local buttonX = 0.5 - button.absSize[1] / 2
			local buttonY = barY - buttonOffset - button.absSize[2]
			button:setAbsolutePosition(buttonX, buttonY)
			button:draw()
		end
	end
end
function KioskMode:getSetting(name)
	return self.settings[name]
end
function KioskMode:getProfile()
	if StartParams.getIsSet("kioskProfileId") then
		local profileId = tonumber(StartParams.getValue("kioskProfileId"))
		local profile = self.profiles[profileId]
		if profile ~= nil then
			return profile
		else
			if not self.startParamProfileIdWarningShown then
				self.startParamProfileIdWarningShown = true
				Logging.error("Invalid kioskProfileId '%s'!", profileId)
			end
			return nil
		end
	elseif StartParams.getIsSet("kioskProfileName") then
		local name = StartParams.getValue("kioskProfileName")
		local nameUpper = string.upper(name)
		for _, profile in pairs(self.profiles) do
			if string.upper(profile.name) == nameUpper then
				return profile
			end
		end
		if not self.startParamProfileNameWarningShown then
			self.startParamProfileNameWarningShown = true
			Logging.error("Invalid kioskProfileName '%s'!", name)
		end
		return nil
	else
		if self.profileSelectorGamepadId ~= nil then
			local mask = 0
			for bit, buttonId in pairs(KioskMode.BIT_TO_BUTTON_ID) do
				local value = getInputButton(buttonId, self.profileSelectorGamepadId)
				if 0 < value then
					mask = Utils.setBit(mask, bit)
				end
			end
			local profile = self.maskToProfile[mask]
			if profile ~= nil then
				return profile
			end
		end
		return nil
	end
end
function KioskMode:setSavegame(path)
	if path ~= nil then
		if GS_IS_CONSOLE_VERSION then
			saveSetFixedSavegame(path)
			return
		end
		local savegamePath = getUserProfileAppPath() .. "savegame1"
		localDeleteFolder(savegamePath)
		createFolder(savegamePath)
		local newFiles = Files.new(path).files
		for _, file in ipairs(newFiles) do
			copyFile(path .. "/" .. file.filename, savegamePath .. "/" .. file.filename, true)
		end
		if not fileExists(savegamePath .. "/careerSavegame.xml") then
			Logging.error("Failed to copy savegame from '%s' to '%s'!", path, savegamePath)
		end
	elseif not GS_IS_CONSOLE_VERSION then
		local savegamePath = getUserProfileAppPath() .. "savegame1"
		localDeleteFolder(savegamePath)
	end
end
function KioskMode:setupMainMenu()
	local mainMenuEnabled = self:getSetting("mainMenuEnabled")
	local areButtonsDisabled = not mainMenuEnabled
	g_mainScreen.careerButton:setDisabled(self:getSetting("bscSPAutoStart"))
	g_mainScreen.multiplayerButton:setDisabled(areButtonsDisabled)
	g_mainScreen.downloadModsButton:setDisabled(areButtonsDisabled)
	g_mainScreen.achievementsButton:setDisabled(areButtonsDisabled)
	if not Platform.isConsole then
		g_mainScreen.settingsButton:setDisabled(areButtonsDisabled)
	else
		g_mainScreen.settingsButton:setDisabled(true)
	end
	g_mainScreen.quitButton:setDisabled(areButtonsDisabled)
	g_mainScreen.storeButton:setDisabled(areButtonsDisabled)
	g_mainScreen.buttonBox:invalidateLayout()
end
function KioskMode:addRegisteredMaps(map)
	table.addElement(self.maps, map)
end
function KioskMode:updateAvailableMaps()
	local mapIds = self.settings.maps
	table.clear(g_mapManager.maps)
	for _, map in ipairs(self.maps) do
		if mapIds == nil or mapIds[map.id] == true then
			table.insert(g_mapManager.maps, map)
			g_mapManager.idToMap[map.id] = map
		end
	end
end
function KioskMode:resetVideoTimer()
	if self:getSetting("videos") ~= nil then
		local wasVideoPlaying = self.videoOverlay ~= nil
		self.videoStartTimer = self:getSetting("videoTimer")
		self:disposeVideo()
		self.currentVideoIndex = nil
		return wasVideoPlaying
	else
		return false
	end
end
function KioskMode:openMainMenu()
	self:resetVideoTimer()
end
function KioskMode:closeMainMenu()
	self.videoStartTimer = nil
end
function KioskMode:disposeVideo()
	if self.videoOverlay ~= nil and isVideoOverlayPlaying(self.videoOverlay) then
		stopVideoOverlay(self.videoOverlay)
		delete(self.videoOverlay)
		self.videoOverlay = nil
	end
end
function KioskMode:nextVideo()
	self:disposeVideo()
	if self.currentVideoIndex == nil or #self:getSetting("videos") <= self.currentVideoIndex then
		self.currentVideoIndex = 1
	else
		self.currentVideoIndex = self.currentVideoIndex + 1
	end
	self.videoStartTimer = nil
	self.videoOverlay = createVideoOverlay(self.settings.videos[self.currentVideoIndex], false, 1)
	playVideoOverlay(self.videoOverlay)
end
function KioskMode:onResetFiles()
	if GS_PLATFORM_PC then
		doRestart(false, "-kioskModeResetFiles")
	end
end
function KioskMode:onStartVideos()
	if g_gui.currentGuiName == "MainScreen" then
		g_kioskMode:nextVideo()
	end
end
function KioskMode:onToggleLanguage(actionName, inputValue, callbackState, isAnalog, isMouse, deviceCategory, binding)
	if GS_PLATFORM_PC and g_gui.currentGuiName == "MainScreen" then
		local currentLanguage = getLanguage()
		local nextIndex = nil
		for k, v in ipairs(g_availableLanguagesTable) do
			if v == currentLanguage then
				nextIndex = k + math.sign(inputValue)
			end
		end
		if nextIndex == nil or #g_availableLanguagesTable < nextIndex then
			nextIndex = 1
		else
			if nextIndex < 1 then
				nextIndex = #g_availableLanguagesTable
			end
		end
		currentLanguage = g_availableLanguagesTable[nextIndex]
		g_kioskMode.nextLanguageIndex = currentLanguage
		g_kioskMode.nextLanguageRestartTimer = g_time + 5000
		setLanguage(currentLanguage)
		g_kioskMode:resetVideoTimer()
	end
end
function KioskMode:onReloadSavegame()
	if g_kioskMode:getSetting("reloadEnabled") or self.playtimeReloadTimer ~= nil then
		OnInGameMenuMenu()
	end
end
function KioskMode:getEndSlideOnLoad()
	if not StartParams.getIsSet("kioskEndSlide") then
		return nil
	else
		return self.settings.endSlide
	end
end
function KioskMode:onPlaytimeReload()
	if g_currentMission == nil then
		return
	else
		local restartArgs = ""
		if self.settings.endSlide ~= nil then
			restartArgs = "-kioskEndSlide"
		end
		OnInGameMenuMenu(nil, nil, restartArgs)
	end
end
function KioskMode.inj_mpLoadingScreen_onReadyToStart(screen, superFunc)
	if g_kioskMode:getEndSlideOnLoad() == nil then
		superFunc(screen)
	else
		local originalOnClickOk = screen.onClickOk
		screen.onClickOk = KioskMode.EMPTY_FUNC
		superFunc(screen)
		screen.onClickOk = originalOnClickOk
	end
end
function KioskMode:registerGlobalInputActionEvents()
	if GS_PLATFORM_PC then
		local _, eventId = g_inputBinding:registerActionEvent(InputAction.KIOSK_MODE_RESET_FILES, g_kioskMode, g_kioskMode.onResetFiles, false, true, false, true)
		g_inputBinding:setActionEventTextVisibility(eventId, false)
		_, eventId = g_inputBinding:registerActionEvent(InputAction.KIOSK_MODE_RELOAD_GAME, g_kioskMode, g_kioskMode.onReloadSavegame, false, true, false, true)
		g_inputBinding:setActionEventTextVisibility(eventId, false)
		_, eventId = g_inputBinding:registerActionEvent(InputAction.KIOSK_MODE_TOGGLE_LANGUAGE, nil, g_kioskMode.onToggleLanguage, false, true, false, true)
		g_inputBinding:setActionEventTextVisibility(eventId, false)
		_, eventId = g_inputBinding:registerActionEvent(InputAction.KIOSK_MODE_START_VIDEOS, nil, g_kioskMode.onStartVideos, false, true, false, true)
		g_inputBinding:setActionEventTextVisibility(eventId, false)
	end
end
function KioskMode.inj_mapManager_addMapItem(mapManager, superFunc, ...)
	local success = superFunc(mapManager, ...)
	if success then
		local map = table.remove(mapManager.maps, #mapManager.maps)
		mapManager.idToMap[map.id] = nil
		g_kioskMode:addRegisteredMaps(map)
	end
	g_kioskMode:updateAvailableMaps()
	return success
end
function KioskMode.inj_Farm_setInitialEconomy(farm, ...)
	if not farm.isSpectator then
		farm.money = g_kioskMode:getSetting("startMoney")
		Logging.info("Set Kiosk-Mode farm startmoney: %d", farm.money)
	end
end
function KioskMode.inj_ingameMap_registerInput(ingameMap, superFunc, ...)
	if g_kioskMode:getSetting("logoEnabled") then
		return
	else
		superFunc(ingameMap, ...)
	end
end
function KioskMode.inj_inGameMenuMapFrame_updateInputGlyphs(ingameMenu, ...)
	local farmlandShopEnabled = g_kioskMode:getSetting("farmlandShopEnabled")
	ingameMenu.buttonSwitchMapMode:setDisabled(not farmlandShopEnabled)
end
function KioskMode.inj_storeManager_getDefaultStoreItemsFilename(storeManager, superFunc, ...)
	local storeConfig = g_kioskMode:getSetting("storeItems")
	if storeConfig ~= nil then
		return storeConfig
	else
		return superFunc(storeManager, ...)
	end
end
function KioskMode.inj_environment_load(environment, superFunc, ...)
	local success = superFunc(environment, ...)
	if g_kioskMode:getSetting("alwaysDay") then
		environment.dayNightCycle = false
	end
	return success
end
function KioskMode.inj_loanTrigger_new(id, superFunc, ...)
	local loanTrigger = superFunc(id)
	loanTrigger.isEnabled = g_kioskMode:getSetting("vehicleShopEnabled")
	return loanTrigger
end
function KioskMode.inj_shopTrigger_new(id, superFunc, ...)
	local shopTrigger = superFunc(id)
	shopTrigger.isEnabled = g_kioskMode:getSetting("vehicleShopEnabled")
	return shopTrigger
end
function KioskMode.inj_vehicleSellingPoint_load(vehicleSellingPoint, superFunc, ...)
	local ret = superFunc(vehicleSellingPoint, ...)
	vehicleSellingPoint.isEnabled = g_kioskMode:getSetting("vehicleShopEnabled")
	return ret
end
function KioskMode.inj_animalLoadingTrigger_load(animalTrigger, superFunc, ...)
	local ret = superFunc(animalTrigger, ...)
	animalTrigger.isEnabled = g_kioskMode:getSetting("animalShopEnabled")
	return ret
end
function KioskMode.inj_fsBaseMission_getIsAutoSaveSupported(mission)
	return false
end
function KioskMode.inj_playerInputComponent_registerGlobalPlayerActionEvents(player) end
function KioskMode.inj_playerInputComponent_getCanToggleCamera(player, superFunc, ...)
	if not g_kioskMode:getSetting("playerCanToggleCamera") then
		return false
	else
		return superFunc(player, ...)
	end
end
function KioskMode.inj_fsBaseMission_update(mission, dt)
	if g_kioskMode.tryToEnterVehicle ~= nil then
		g_localPlayer:requestToEnterVehicle(g_kioskMode.tryToEnterVehicle)
		g_kioskMode.tryToEnterVehicle = nil
	end
end
function KioskMode.inj_mission00_onStartMission()
	if g_kioskMode:getSetting("playtimeEnabled") then
		g_kioskMode.playtimeReloadTimer = g_kioskMode:getSetting("playtimeDuration")
	end
	if g_kioskMode:getSetting("farmlandsBuyAll") then
		g_currentMission:playerOwnsAllFields()
	end
	local startVehicleIndex = g_kioskMode:getSetting("startVehicleIndex")
	if startVehicleIndex ~= nil then
		local vehicle = g_currentMission.vehicleSystem.enterables[startVehicleIndex]
		if vehicle ~= nil then
			g_kioskMode.tryToEnterVehicle = vehicle
		end
	end
	if not g_kioskMode:getSetting("helpLineTriggerEnabled") then
		g_currentMission:setShowHelpTrigger(false)
	end
end
function KioskMode.inj_inGameMenu_makeIsAIEnabledPredicate(ingameMenu)
	return function()
		return g_kioskMode:getSetting("aiEnabled")
	end
end
function KioskMode.inj_inGameMenu_makeIsPricesEnabledPredicate(ingameMenu)
	return function()
		return false
	end
end
function KioskMode.inj_inGameMenu_makeIsAnimalsEnabledPredicate(ingameMenu)
	return function()
		return false
	end
end
function KioskMode.inj_inGameMenu_makeIsContractsEnabledPredicate(ingameMenu)
	return function()
		return false
	end
end
function KioskMode.inj_inGameMenu_makeIsGarageEnabledPredicate(ingameMenu)
	return function()
		return false
	end
end
function KioskMode.inj_inGameMenu_makeIsSettingsEnabledPredicate(ingameMenu)
	return function()
		return false
	end
end
function KioskMode.inj_inGameMenu_makeIsHelpEnabledPredicate(ingameMenu)
	return function()
		return false
	end
end
function KioskMode.inj_inGameMenuSettingsFrame_initializeButtons(frame)
	frame.saveButton = nil
end
function KioskMode.inj_inputBinding_loadModActions(inputBinding, superFunc)
	superFunc(inputBinding)
	g_kioskMode:loadInputActions()
end
function KioskMode.inj_inputBinding_loadModBindingDefaults(inputBinding, superFunc)
	superFunc(inputBinding)
	g_kioskMode:loadInputBindings()
end
function KioskMode:inj_productionPointActivatable_run(superFunc)
	if not g_kioskMode:getSetting("productionEnabled") then
		InfoDialog.show(g_i18n:getText("ui_featureDisabled"))
	else
		superFunc(self)
	end
end
function KioskMode:inj_railroadCallerActivatable_run(superFunc)
	if not g_kioskMode:getSetting("trainEnabled") then
		InfoDialog.show(g_i18n:getText("ui_featureDisabled"))
	else
		superFunc(self)
	end
end
function KioskMode.inj_specializationManager_addSpecialization(specializationManager, name, className, ...)
	if specializationManager == g_specializationManager then
		if className == "AIJobVehicle" then
			if not g_kioskMode:getSetting("aiEnabled") then
				local old = AIJobVehicle.onRegisterActionEvents
				function AIJobVehicle.onRegisterActionEvents(vehicle, isActiveForInput, isActiveForInputIgnoreSelection)
					if vehicle.isClient then
						local spec = vehicle.spec_aiJobVehicle
						vehicle:clearActionEventsTable(spec.actionEvents)
					end
					if not g_kioskMode:getSetting("aiEnabled") then
						return
					else
						if not g_kioskMode:getSetting("ingameMenuEnabled") then
							local startableJob = vehicle:getStartableAIJob()
							if startableJob == nil then
								return
							end
						end
						old(vehicle, isActiveForInput, isActiveForInputIgnoreSelection)
					end
				end
			end
			if not g_kioskMode:getSetting("aiWorkerEnabled") then
				local old = AIJobVehicle.onRegisterActionEvents
				function AIJobVehicle.toggleAIVehicle(vehicle)
					if not g_kioskMode:getSetting("aiWorkerEnabled") then
						InfoDialog.show(g_i18n:getText("ui_featureDisabled"))
					else
						old(vehicle)
					end
				end
			end
		elseif className == "Drivable" then
			if g_kioskMode:getSetting("extendedDrivingHelp") then
				local old = Drivable.onRegisterActionEvents
				function Drivable.onRegisterActionEvents(vehicle, isActiveForInput, isActiveForInputIgnoreSelection)
					old(vehicle, isActiveForInput, isActiveForInputIgnoreSelection)
					local spec = vehicle.spec_drivable
					for inputAction, data in pairs(spec.actionEvents) do
						local actionEventId = data.actionEventId
						local event = g_inputBinding.events[actionEventId]
						if event.displayPriority == GS_PRIO_VERY_LOW then
							g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_VERY_HIGH)
						elseif event.displayPriority == GS_PRIO_LOW then
							g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_HIGH)
						end
						if event.displayIsVisible then
							continue
						end
						g_inputBinding:setActionEventTextVisibility(actionEventId, true)
					end
				end
			end
		end
	elseif specializationManager == g_placeableSpecializationManager then
		if className == "PlaceableWardrobe" then
			if not g_kioskMode:getSetting("wardrobeShopEnabled") then
				function WardrobeActivatable.run()
					InfoDialog.show(g_i18n:getText("ui_featureDisabled"))
				end
			end
		elseif className == "PlaceableRiceField" then
			if not g_kioskMode:getSetting("riceFieldEnabled") then
				function PlaceableRiceFieldActivatable.run()
					InfoDialog.show(g_i18n:getText("ui_featureDisabled"))
				end
			end
		end
	end
end
function KioskMode.inj_mission00_getIsTourSupported(mission, superFunc)
	if not g_kioskMode:getSetting("tourEnabled") then
		return false
	else
		return superFunc(mission)
	end
end
function KioskMode.inj_hud_createDisplayComponents(hud, uiScale)
	if g_kioskMode:getSetting("logoEnabled") then
		hud.ingameMap:setIsVisible(false)
		local width = g_kioskMode:getSetting("logoWidth")
		local height = g_kioskMode:getSetting("logoHeight")
		local filename = g_kioskMode:getSetting("logoFilename")
		width, height = getNormalizedScreenValues(width, height)
		local overlay = Overlay.new(filename, g_safeFrameOffsetX, g_safeFrameOffsetY, width, height)
		hud.kioskModeLogoElement = HUDElement.new(overlay)
		table.insert(hud.displayComponents, hud.kioskModeLogoElement)
	end
end
function KioskMode.inj_inGameMenuMobileSettingsFrame_onFrameOpen(frame)
	frame.multiGraphics:setDisabled(true)
	frame.checkGyroscope:setDisabled(true)
	frame.checkTilt:setDisabled(true)
end
function KioskMode.inj_careerScreen_updateButtons(screen)
	if screen.buttonDelete then
		screen.buttonDelete:setDisabled(true)
	end
end
function KioskMode.inj_modSelectionScreenn_update(screen, dt)
	if g_kioskMode:getSetting("canSelectMods") then
		return
	else
		for _, modItem in pairs(screen.selectedMods) do
			screen:setItemState(modItem, false)
		end
		for _, modName in pairs(g_kioskMode:getSetting("mods")) do
			local modItem = g_modManager:getModByName(modName)
			if modItem == nil then
				continue
			end
			if screen:shouldShowModInList(modItem) then
				screen:setItemState(modItem, true)
			else
				Logging.error("Mod '%s' is not available for current kiosk mode setup", modItem.title)
			end
		end
		screen:onClickOk()
	end
end
function KioskMode.inj_newGameScreen_update(screen, dt)
	local info = screen.startMissionInfo or g_startMissionInfo
	if g_mapManager:getNumOfMaps() == 1 then
		local map = g_mapManager:getMapDataByIndex(1)
		info.mapId = map.id
	end
	info.initialMoney = g_kioskMode:getSetting("startMoney") or 100000
	screen:onClickOk()
end
function KioskMode.inj_careerScreen_update(screen, dt)
	if g_kioskMode:getSetting("canSelectSavegame") then
		return
	else
		screen.selectedIndex = 1
		local savegameController = screen.savegameController or g_savegameController
		local savegame = savegameController:getSavegame(screen.selectedIndex)
		screen:startSavegame(savegame)
	end
end
function KioskMode.inj_mainScreen_inputEvent(screen, superFunc, action, value, eventUsed)
	if action == InputAction.KIOSK_MODE_START_VIDEOS then
		eventUsed = true
	elseif g_kioskMode:resetVideoTimer() then
		eventUsed = true
	end
	return superFunc(screen, action, value, eventUsed)
end
function KioskMode.inj_mainScreen_onClose(screen)
	g_kioskMode:closeMainMenu()
end
function KioskMode.inj_mainScreen_update(screen, superFunc, dt)
	if g_kioskMode:getSetting("skipMainMenu") then
		screen:onCareerClick()
	else
		superFunc(screen, dt)
	end
end
function KioskMode.inj_mainScreen_onOpen(screen)
	g_kioskMode:openMainMenu()
end
function KioskMode.inj_gui_changeScreen(gui, superFunc, sourceScreen, screenClass, ...)
	if screenClass == InGameMenu then
		if not g_kioskMode:getSetting("ingameMenuEnabled") then
			return
		end
	elseif screenClass == ShopMenu then
		if not g_kioskMode:getSetting("vehicleShopEnabled") then
			return
		end
	elseif screenClass == WardrobeScreen then
		if not g_kioskMode:getSetting("wardrobeShopEnabled") then
			return
		end
	elseif screenClass == ConstructionScreen then
		if not g_kioskMode:getSetting("placeableShopEnabled") then
			return
		end
	elseif screenClass == AnimalScreen then
		if not g_kioskMode:getSetting("animalShopEnabled") then
			return
		end
	end
	return superFunc(gui, sourceScreen, screenClass, ...)
end
function KioskMode.inj_gui_showGui(gui, superFunc, screenName, ...)
	if screenName == "InGameMenu" then
		if not g_kioskMode:getSetting("ingameMenuEnabled") then
			return
		end
	elseif screenName == "ShopMenu" then
		if not g_kioskMode:getSetting("vehicleShopEnabled") then
			return
		end
	elseif screenName == "WardrobeScreen" then
		if not g_kioskMode:getSetting("wardrobeShopEnabled") then
			return
		end
	elseif screenName == "ConstructionScreen" then
		if not g_kioskMode:getSetting("placeableShopEnabled") then
			return
		end
	elseif screenName == "AnimalScreen" then
		if not g_kioskMode:getSetting("animalShopEnabled") then
			return
		end
	end
	return superFunc(gui, screenName, ...)
end
function KioskMode.inj_messageCenter_publish(messageCenter, superFunc, msg, ...)
	if not g_kioskMode:getSetting("ingameMenuEnabled") and msg == MessageType.GUI_INGAME_OPEN_AI_SCREEN then
		return
	end
	return superFunc(messageCenter, msg, ...)
end
