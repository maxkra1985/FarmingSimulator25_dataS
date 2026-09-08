-- Local values: localDeleteFile, localDeleteFolder, KioskMode_mt
local localDeleteFile = deleteFile
local localDeleteFolder = deleteFolder
KioskMode = {}
KioskMode.GAMEPAD_NAME = "JoyWarrior Gamepad 32"
KioskMode.BIT_TO_BUTTON_ID = {
	[1] = 7,
	[2] = 6,
	[3] = 5,
	[4] = 4,
	[5] = 3,
	[6] = 2,
	[7] = 1,
	[8] = 0,
	[15] = 8,
	[16] = 9,
	[17] = 10
}
function KioskMode.EMPTY_FUNC() end
KioskMode.END_SLIDE_BAR_POSITION = "576px 130px"
KioskMode.END_SLIDE_BAR_SIZE = "768px 13px"
KioskMode.END_SLIDE_TEXT_SIZE = "22px"
KioskMode.END_SLIDE_TEXT_OFFSET = "13px"
KioskMode.END_SLIDE_BUTTON_OFFSET = "14px"
local KioskMode_mt = Class(KioskMode)

-- Upvalues: KioskMode_mt
-- Local values: self, path
function KioskMode.new(customMt)
	-- upvalues: (copy) KioskMode_mt
	local v5_ = customMt or KioskMode_mt
	local v6_ = setmetatable({}, v5_)
	v6_.configPaths = { "dataS/kioskMode/", "data/kioskMode/", getUserProfileAppPath() .. "kioskMode/" }
	v6_.profileSelectorGamepadId = nil
	v6_.currentProfile = nil
	v6_.profiles = {}
	v6_.maskToProfile = {}
	v6_.settings = {}
	v6_.nextLanguageRestartTimer = nil
	v6_.nextLanguageIndex = nil
	v6_.maps = {}
	return v6_
end

-- Local values: mapping, generatedMasks, hashedMasks, printResult, bitmask, target, masks, i, mask, str, k
function KioskMode:generateBitmasks()
	local v_u_7_ = {
		1,
		2,
		3,
		4,
		5,
		6,
		7,
		8,
		15,
		16,
		17
	}
	local v_u_8_ = {}
	local v_u_9_ = {}
	local function v_u_15_(p10_, _)
		-- upvalues: (copy) v_u_7_, (copy) v_u_9_, (copy) v_u_8_
		local v11_ = 0
		for v12_, v13_ in ipairs(p10_) do
			if v13_ == 1 then
				v11_ = Utils.setBit(v11_, v_u_7_[v12_])
			end
		end
		if v_u_9_[v11_] == nil then
			local v14_ = v_u_8_
			table.insert(v14_, v11_)
			v_u_9_[v11_] = true
		else
			Logging.warning("Mask %s already exists", table.concat(p10_, ""))
		end
	end
	local function v_u_19_(p16_, p17_, p18_)
		-- upvalues: (copy) v_u_15_, (copy) v_u_19_
		if p18_ == p16_ then
			v_u_15_(p17_, p16_)
		else
			p17_[p18_] = 0
			v_u_19_(p16_, p17_, p18_ + 1)
			p17_[p18_] = 1
			v_u_19_(p16_, p17_, p18_ + 1)
		end
	end
	local v20_ = { 0 }
	v_u_19_(12, v20_, 2)
	v20_[1] = 1
	v_u_19_(12, v20_, 2)
	for _, v21_ in ipairs(v_u_8_) do
		local v22_ = ""
		for v23_ = 1, 20 do
			if (v23_ - 1) % 5 == 0 then
				v22_ = v22_ .. " "
			end
			if v23_ == 18 then
				v22_ = v22_ .. "0"
			elseif KioskMode.BIT_TO_BUTTON_ID[v23_] == nil then
				v22_ = v22_ .. (math.random() > 0.5 and 1 or 0)
			else
				v22_ = v22_ .. (Utils.isBitSet(v21_, v23_) and 1 or 0)
			end
		end
		print(string.format("%s", v22_))
	end
end

function KioskMode:delete()
	self:disposeVideo()
end

-- Upvalues: localDeleteFile
-- Local values: isLoaded, _, path, inputBinding, gameSettings
function KioskMode:load()
	-- upvalues: (copy) localDeleteFile
	if StartParams.getIsSet("kioskDisabled") then
		return false
	end
	local v26_ = false
	for _, v27_ in ipairs(self.configPaths) do
		if self:loadFromPath(v27_) then
			v26_ = true
		end
	end
	if not v26_ then
		return false
	end
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
		local v28_ = getUserProfileAppPath() .. "inputBinding.xml"
		if fileExists(v28_) then
			localDeleteFile(v28_)
		end
		local v29_ = getUserProfileAppPath() .. "gameSettings.xml"
		if fileExists(v29_) then
			localDeleteFile(v29_)
		end
	end
	function modDownloadManagerLoaded()
		return false
	end
	return true
end

-- Local values: configFileName, zipFilePath, xmlFile, defaultConfigFile, _, key, name, configFile, mask, bitCount, bitsStr, len, i, bit, usedProfile, profile
function KioskMode:loadFromPath(path)
	local v32_ = path .. "kioskMode.xml"
	if not fileExists(v32_) then
		return false
	end
	local v33_ = #path - 1
	local v34_ = string.sub(path, 1, v33_) .. ".zip"
	if folderExists(path) and fileExists(v34_) then
		Logging.error("Kiosk mode config directory %q also has a zip file with the same name %q next to it overriding any changes made in the directory. Delete or rename the zip file!", path, v34_)
		return false
	end
	local v35_ = XMLFile.load("KioskMode", v32_, nil)
	if v35_ == nil then
		return false
	end
	local v36_ = Utils.getFilename(v35_:getString("kioskMode.defaultProfile.configFile", ""), path)
	if not fileExists(v36_) then
		Logging.xmlWarning(v35_, "KioskMode:loadFromPath - default config file \'%s\' not found", v36_)
		return false
	end
	self.defaultConfigFile = v36_
	for _, v37_ in v35_:iterator("kioskMode.profiles.profile") do
		local v38_ = v35_:getString(v37_ .. "#name", "")
		local v39_ = Utils.getFilename(v35_:getString(v37_ .. ".configFile", ""), path)
		if fileExists(v39_) then
			local v40_ = 0
			local v41_ = 1
			local v42_ = v35_:getString(v37_ .. "#bits", "")
			if v42_:len() == 23 then
				for v43_ = 1, v42_:len() do
					local v44_ = v42_:sub(v43_, v43_)
					if v44_ ~= " " then
						if tonumber(v44_) == 1 then
							if KioskMode.BIT_TO_BUTTON_ID[v41_] == nil then
								if v41_ == 18 then
									Logging.xmlWarning(v35_, "KioskMode:loadFromPath - Bit %d cannot be used. Please replace it with 0 for profile \'%s\'", v41_, v38_)
								end
							else
								v40_ = Utils.setBit(v40_, v41_)
							end
						end
						v41_ = v41_ + 1
					end
				end
				if self.maskToProfile[v40_] == nil then
					local v45_ = {
						["id"] = #self.profiles + 1,
						["name"] = v38_,
						["mask"] = v40_,
						["configFile"] = v39_
					}
					self.maskToProfile[v40_] = v45_
					local v46_ = self.profiles
					table.insert(v46_, v45_)
				else
					local v47_ = self.maskToProfile[v40_]
					Logging.xmlWarning(v35_, "KioskMode:loadFromPath - %s mask already used for profile \'%s\'. Ignoring this profile", v38_, v47_.name)
				end
			else
				Logging.xmlWarning(v35_, "KioskMode:loadFromPath - invalid bitsformat (##### ##### ##### #####) for profile \'%s\'. Ignoring this profile", v38_)
			end
		else
			Logging.xmlWarning(v35_, "KioskMode:loadFromPath - config file \'%s\' for profile \'%s\' not found. Ignoring this profile", v39_, v38_)
		end
	end
	v35_:delete()
	if #self.profiles == 0 then
		Logging.xmlWarning(v35_, "KioskMode:loadFromPath - No profiles defined!")
		return false
	end
	self.configFileName = v32_
	local v48_ = g_dlcsDirectories
	local v49_ = {
		["path"] = path .. "pdlc/",
		["isLoaded"] = true
	}
	table.insert(v48_, v49_)
	return true
end

-- Local values: xmlFileObj, xmlFile
function KioskMode:loadInputActions()
	if self.configFileName ~= nil then
		local v51_ = XMLFile.load("KioskMode Inputs", self.configFileName)
		local v52_ = v51_:getHandle()
		g_inputBinding:loadActionsFromXMLPath(v52_, "kioskMode.input.actions", g_i18n, nil)
		v51_:delete()
	end
end

-- Local values: xmlFileObj, xmlFile
function KioskMode:loadInputBindings()
	if self.configFileName ~= nil then
		local v54_ = XMLFile.load("KioskMode Inputs", self.configFileName)
		local v55_ = v54_:getHandle()
		g_inputBinding:loadActionBindingsFromXMLPath(v55_, "kioskMode.input.bindings", true, nil, true, true)
		v54_:delete()
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
	function MissionManager.update(screen) end
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

-- Local values: numOfGamepads, i, gamepadName, oldGetIsDeviceSupported
function KioskMode:initProfileSelectorGamepad()
	for v58_ = 0, getNumOfGamepads() - 1 do
		local v59_ = getGamepadName(v58_)
		if v59_ == KioskMode.GAMEPAD_NAME then
			Logging.info("KioskMode:initProfileSelectorGamepad - Found Gaming Station with gamepad \'%s\'", v59_)
			self.profileSelectorGamepadId = v58_
		end
	end
	if self.profileSelectorGamepadId ~= nil then
		local v_u_60_ = InputDevice.getIsDeviceSupported
		function InputDevice.getIsDeviceSupported(p61_, p62_)
			-- upvalues: (copy) v_u_60_
			if v_u_60_(p61_, p62_) then
				return p62_ ~= KioskMode.GAMEPAD_NAME
			else
				return false
			end
		end
	end
	return self.profileSelectorGamepadId ~= nil
end

-- Local values: xmlFile, path, savegamePath, logo, endSlide, timescales, newTimescales, mapsStr, mapIds, _, id, storeItems, videos, duration, videosDirectory, files, _, file, videoPath, playtimeSeconds, mods
function KioskMode:loadProfileConfig(configFileName)
	Logging.info("KioskMode:loadProfileConfig - Loading profile config \'%s\'", configFileName)
	local v_u_65_ = XMLFile.load("KioskMode Profile", configFileName)
	local v66_ = Utils.getDirectory(configFileName)
	self.settings.canSelectSavegame = v_u_65_:getBool("config.canSelectSavegame", false)
	self.settings.canSelectMods = v_u_65_:getBool("config.canSelectMods", false)
	if not self.settings.canSelectSavegame then
		local v67_ = v_u_65_:getString("config.savegame")
		if v67_ ~= nil then
			v67_ = Utils.getFilename(v67_, v66_)
		end
		self:setSavegame(v67_)
		self.settings.savegame = v67_
	end
	local v68_ = v_u_65_:getString("config.logo")
	if v68_ ~= nil then
		self.settings.logoFilename = Utils.getFilename(v68_, v66_)
		self.settings.logoWidth = v_u_65_:getInt("config.logo#width", 600)
		self.settings.logoHeight = v_u_65_:getInt("config.logo#height", 150)
	end
	self.settings.logoEnabled = v68_ ~= nil
	local v69_ = v_u_65_:getString("config.endSlide")
	if v69_ ~= nil then
		self.settings.endSlide = Utils.getFilename(v69_, v66_)
	end
	self.settings.tourEnabled = v_u_65_:getBool("config.tourEnabled", false)
	self.settings.aiEnabled = v_u_65_:getBool("config.aiEnabled", true)
	self.settings.aiWorkerEnabled = v_u_65_:getBool("config.aiWorkerEnabled", true)
	self.settings.mainMenuEnabled = v_u_65_:getBool("config.mainMenuEnabled", false)
	self.settings.watermarkEnabled = v_u_65_:getBool("config.watermarkEnabled", false)
	self.settings.ingameMenuEnabled = v_u_65_:getBool("config.ingameMenuEnabled", true)
	self.settings.reloadEnabled = v_u_65_:getBool("config.reloadEnabled", false)
	self.settings.animalShopEnabled = v_u_65_:getBool("config.shopsEnabled.animals", false)
	self.settings.vehicleShopEnabled = v_u_65_:getBool("config.shopsEnabled.vehicles", false)
	self.settings.farmlandShopEnabled = v_u_65_:getBool("config.shopsEnabled.farmlands", false)
	self.settings.placeableShopEnabled = v_u_65_:getBool("config.shopsEnabled.placeables", false)
	self.settings.wardrobeShopEnabled = v_u_65_:getBool("config.shopsEnabled.wardrobe", false)
	self.settings.productionEnabled = v_u_65_:getBool("config.productionEnabled", true)
	self.settings.trainEnabled = v_u_65_:getBool("config.trainEnabled", false)
	self.settings.riceFieldEnabled = v_u_65_:getBool("config.riceFieldEnabled", true)
	self.settings.helpLineTriggerEnabled = v_u_65_:getBool("config.helpLineTriggerEnabled", true)
	self.settings.extendedDrivingHelp = v_u_65_:getBool("config.extendedDrivingHelp", false)
	self.settings.alwaysDay = v_u_65_:getBool("config.alwaysDay", false)
	self.settings.startMoney = v_u_65_:getInt("config.startMoney", 1000000)
	self.settings.skipMainMenu = v_u_65_:getBool("config.skipMainMenu", false)
	self.settings.farmlandsBuyAll = v_u_65_:getBool("config.farmlandsBuyAll", false)
	self.settings.startVehicleIndex = v_u_65_:getInt("config.startVehicleIndex", nil)
	self.settings.playerCanToggleCamera = v_u_65_:getBool("config.player.canToggleCamera", false)
	if KioskMode.TIMESCALE_BACKUP == nil then
		KioskMode.TIMESCALE_BACKUP = Platform.gameplay.timeScaleSettings
		KioskMode.TIMESCALE_DEV_BACKUP = Platform.gameplay.timeScaleDevSettings
	end
	Platform.gameplay.timeScaleSettings = KioskMode.TIMESCALE_BACKUP
	Platform.gameplay.timeScaleDevSettings = KioskMode.TIMESCALE_DEV_BACKUP
	local v70_ = v_u_65_:getString("config.timescales", nil)
	if v70_ ~= nil then
		local v71_ = string.getVector(v70_)
		if #v71_ > 0 then
			Platform.gameplay.timeScaleSettings = v71_
			Platform.gameplay.timeScaleDevSettings = {}
		end
	end
	local v72_ = v_u_65_:getString("config.maps", "")
	local v73_ = string.split(v72_, " ")
	self.settings.maps = nil
	for _, v74_ in ipairs(v73_) do
		if self.settings.maps == nil then
			self.settings.maps = {}
		end
		self.settings.maps[v74_] = true
	end
	self:updateAvailableMaps()
	local v75_ = v_u_65_:getString("config.storeItems", "")
	local v76_
	if v75_ == "" then
		v76_ = nil
	else
		v76_ = Utils.getFilename(v75_, v66_)
	end
	self.settings.storeItems = v76_
	local v77_ = nil
	local v78_ = v_u_65_:getString("config.videos", "")
	local v79_
	if v78_ == "" then
		v79_ = nil
	else
		local v80_ = Utils.getFilename(v78_, v66_)
		local v81_ = Files.new(v80_).files
		for _, v82_ in ipairs(v81_) do
			local v83_ = v80_ .. "/" .. v82_.filename
			if fileExists(v83_) then
				v77_ = v77_ == nil and {} or v77_
				local v84_ = v80_ .. "/" .. v82_.filename
				table.insert(v77_, v84_)
			end
		end
		v79_ = v_u_65_:getInt("config.videos#inactiveDurationSeconds", 180) * 1000
		if v77_ == nil or #v77_ == 0 then
			Logging.warning("KioskMode: No videos found in \'%s\'", v80_)
			v77_ = nil
			v79_ = nil
		end
	end
	self.settings.videos = v77_
	self.settings.videoTimer = v79_
	local v85_ = v_u_65_:getFloat("config.playtimeSeconds")
	if v85_ ~= nil then
		self.settings.playtimeDuration = v85_ * 1000
	end
	self.settings.playtimeEnabled = v85_ ~= nil
	local v_u_86_ = {}
	v_u_65_:iterate("config.mods.mod", function(_, p87_)
		-- upvalues: (copy) v_u_65_, (copy) v_u_86_
		local v88_ = v_u_65_:getString(p87_)
		if v88_ ~= nil then
			local v89_ = v_u_86_
			table.insert(v89_, v88_)
		end
	end)
	self.settings.mods = v_u_86_
	self:openMainMenu()
	self:setupMainMenu()
	v_u_65_:delete()
end
function KioskMode.update(p90_, p91_)
	if (p90_.profileSelectorGamepadId ~= nil or (StartParams.getIsSet("kioskProfileId") or StartParams.getIsSet("kioskProfileName"))) and (g_gui.currentGuiName == "MainScreen" and p90_.currentProfile == nil) then
		local v92_ = p90_:getProfile()
		if v92_ ~= nil then
			p90_:loadProfileConfig(v92_.configFile)
			p90_.currentProfile = v92_
		end
	end
	if GS_PLATFORM_PC and (p90_.nextLanguageRestartTimer ~= nil and p90_.nextLanguageRestartTimer < g_time) then
		doRestart(false, "")
	end
	if g_currentMission ~= nil and p90_.playtimeReloadTimer ~= nil then
		p90_.playtimeReloadTimer = p90_.playtimeReloadTimer - p91_
		if p90_.playtimeReloadTimer <= 0 then
			p90_.playtimeReloadTimer = nil
			p90_:onPlaytimeReload()
		end
	end
	if p90_.currentVideoIndex == nil then
		if p90_.videoStartTimer ~= nil then
			p90_.videoStartTimer = p90_.videoStartTimer - p91_
			if p90_.videoStartTimer < 0 then
				p90_:nextVideo()
				return
			end
		end
	else
		if p90_.videoOverlay ~= nil and isVideoOverlayPlaying(p90_.videoOverlay) then
			updateVideoOverlay(p90_.videoOverlay)
			return
		end
		if p90_.videoOverlay ~= nil then
			p90_:disposeVideo()
			p90_:nextVideo()
		end
	end
end

-- Local values: timeLeft, langName, name, isNotFading, isUIVisible, left, right
function KioskMode:draw()
	self:drawEndSlide()
	if self.nextLanguageIndex ~= nil then
		setTextAlignment(RenderText.ALIGN_CENTER)
		setTextBold(true)
		setTextColor(0, 0, 0, 1)
		local v94_ = (self.nextLanguageRestartTimer - g_time) / 1000
		local v95_ = math.ceil(v94_)
		local v96_ = getLanguageName(self.nextLanguageIndex)
		renderText(0.5 + 2 * g_pixelSizeX, 0.75 - g_pixelSizeY, 0.025, string.format("Changing Language.\nNew language after restart will be \'%s\'. \nRestarting in %d seconds...", v96_, v95_))
		setTextColor(1, 1, 1, 1)
		renderText(0.5, 0.75, 0.025, string.format("Changing Language.\nNew language after restart will be \'%s\'. \nRestarting in %d seconds...", v96_, v95_))
		setTextAlignment(RenderText.ALIGN_LEFT)
		setTextBold(false)
	end
	if g_gui.currentGuiName == "MainScreen" and self.currentProfile ~= nil then
		setTextAlignment(RenderText.ALIGN_LEFT)
		local v97_ = self.currentProfile.name
		setTextColor(0, 0, 0, 0.75)
		renderText(0.01, 0.9585, 0.011, v97_)
		setTextColor(1, 1, 1, 1)
		renderText(0.01, 0.96, 0.011, v97_)
	end
	if g_currentMission ~= nil and g_currentMission.hud ~= nil then
		local v98_ = not g_currentMission.hud:getIsFading()
		local v99_ = g_gui:getIsGuiVisible()
		if self:getSetting("logoEnabled") and (not v99_ and v98_) then
			g_currentMission.hud.kioskModeLogoElement:draw()
		end
		if self.playtimeReloadTimer ~= nil then
			local v100_ = string.format("%0.1d:", self.playtimeReloadTimer / 60000)
			local v101_ = string.format("%0.2d", self.playtimeReloadTimer / 1000 % 60)
			setTextBold(true)
			setTextAlignment(RenderText.ALIGN_RIGHT)
			renderText(0.5, v99_ and 0.85 or 0.932, 0.05, v100_)
			setTextAlignment(RenderText.ALIGN_LEFT)
			renderText(0.5, v99_ and 0.85 or 0.932, 0.05, v101_)
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

-- Local values: endSlide, isLoadingScreen, progress, barPosition, barSize, barX, barY, barWidth, barHeight, textSize, textOffset, percentageY, isReady, button, buttonOffset, buttonX, buttonY
function KioskMode:drawEndSlide()
	local v103_ = self:getEndSlideOnLoad()
	local v104_
	if v103_ == nil then
		v104_ = false
	else
		v104_ = g_gui.currentGuiName == "MPLoadingScreen"
	end
	if v104_ then
		if self.endSlideOverlay == nil then
			self.endSlideOverlay = Overlay.new(v103_, 0, 0, 1, g_screenAspectRatio)
		end
		new2DLayer()
		self.endSlideOverlay:render()
		local v105_ = g_mpLoadingScreen ~= nil and g_mpLoadingScreen.totalLoadPercentage or 0
		local v106_ = math.clamp(v105_, 0, 1)
		local v107_ = GuiUtils.getNormalizedScreenValues(KioskMode.END_SLIDE_BAR_POSITION)
		local v108_ = GuiUtils.getNormalizedScreenValues(KioskMode.END_SLIDE_BAR_SIZE)
		local v109_ = v107_[1]
		local v110_ = v107_[2]
		local v111_ = v108_[1]
		local v112_ = v108_[2]
		drawFilledRect(v109_, v110_, v111_, v112_, 0, 0, 0, 0.5)
		drawFilledRect(v109_, v110_, v111_ * v106_, v112_, 1, 1, 1, 1)
		local v113_ = GuiUtils.getNormalizedValue(KioskMode.END_SLIDE_TEXT_SIZE, false)
		local v114_ = GuiUtils.getNormalizedValue(KioskMode.END_SLIDE_TEXT_OFFSET, false)
		setTextAlignment(RenderText.ALIGN_CENTER)
		setTextBold(true)
		setTextColor(1, 1, 1, 1)
		local v115_ = v110_ + v112_ + v114_
		renderText(0.5, v115_, v113_, string.format("%d%%", v106_ * 100))
		setTextAlignment(RenderText.ALIGN_LEFT)
		setTextBold(false)
		local v116_
		if g_mpLoadingScreen == nil or g_mpLoadingScreen.button == nil then
			v116_ = false
		else
			v116_ = g_mpLoadingScreen.state == MPLoadingScreen.STATE_READY
		end
		if v116_ then
			local v117_ = g_mpLoadingScreen.button
			local v118_ = GuiUtils.getNormalizedValue(KioskMode.END_SLIDE_BUTTON_OFFSET, false)
			v117_:setAbsolutePosition(0.5 - v117_.absSize[1] / 2, v110_ - v118_ - v117_.absSize[2])
			v117_:draw()
		end
	elseif self.endSlideOverlay ~= nil then
		self.endSlideOverlay:delete()
		self.endSlideOverlay = nil
	end
end

function KioskMode:getSetting(name)
	return self.settings[name]
end

-- Local values: profileId, profile, name, nameUpper, _, profile, mask, bit, buttonId, value, profile
function KioskMode:getProfile()
	if StartParams.getIsSet("kioskProfileId") then
		local v122_ = StartParams.getValue
		local v123_ = tonumber(v122_("kioskProfileId"))
		local v124_ = self.profiles[v123_]
		if v124_ ~= nil then
			return v124_
		end
		if not self.startParamProfileIdWarningShown then
			self.startParamProfileIdWarningShown = true
			Logging.error("Invalid kioskProfileId \'%s\'!", v123_)
		end
		return nil
	else
		if not StartParams.getIsSet("kioskProfileName") then
			if self.profileSelectorGamepadId ~= nil then
				local v125_ = 0
				for v126_, v127_ in pairs(KioskMode.BIT_TO_BUTTON_ID) do
					if getInputButton(v127_, self.profileSelectorGamepadId) > 0 then
						v125_ = Utils.setBit(v125_, v126_)
					end
				end
				local v128_ = self.maskToProfile[v125_]
				if v128_ ~= nil then
					return v128_
				end
			end
			return nil
		end
		local v129_ = StartParams.getValue("kioskProfileName")
		local v130_ = string.upper(v129_)
		for _, v131_ in pairs(self.profiles) do
			if string.upper(v131_.name) == v130_ then
				return v131_
			end
		end
		if not self.startParamProfileNameWarningShown then
			self.startParamProfileNameWarningShown = true
			Logging.error("Invalid kioskProfileName \'%s\'!", v129_)
		end
		return nil
	end
end

-- Upvalues: localDeleteFolder
-- Local values: savegamePath, newFiles, _, file, savegamePath
function KioskMode:setSavegame(path)
	-- upvalues: (copy) localDeleteFolder
	if path == nil then
		if not GS_IS_CONSOLE_VERSION then
			localDeleteFolder(getUserProfileAppPath() .. "savegame1")
		end
	else
		if GS_IS_CONSOLE_VERSION then
			saveSetFixedSavegame(path)
			return
		end
		local v133_ = getUserProfileAppPath() .. "savegame1"
		localDeleteFolder(v133_)
		createFolder(v133_)
		local v134_ = Files.new(path).files
		for _, v135_ in ipairs(v134_) do
			copyFile(path .. "/" .. v135_.filename, v133_ .. "/" .. v135_.filename, true)
		end
		if not fileExists(v133_ .. "/careerSavegame.xml") then
			Logging.error("Failed to copy savegame from \'%s\' to \'%s\'!", path, v133_)
			return
		end
	end
end

-- Local values: mainMenuEnabled, areButtonsDisabled
function KioskMode:setupMainMenu()
	local v137_ = not self:getSetting("mainMenuEnabled")
	g_mainScreen.careerButton:setDisabled(self:getSetting("bscSPAutoStart"))
	g_mainScreen.multiplayerButton:setDisabled(v137_)
	g_mainScreen.downloadModsButton:setDisabled(v137_)
	g_mainScreen.achievementsButton:setDisabled(v137_)
	if Platform.isConsole then
		g_mainScreen.settingsButton:setDisabled(true)
	else
		g_mainScreen.settingsButton:setDisabled(v137_)
	end
	g_mainScreen.quitButton:setDisabled(v137_)
	g_mainScreen.storeButton:setDisabled(v137_)
	g_mainScreen.buttonBox:invalidateLayout()
end

function KioskMode:addRegisteredMaps(map)
	table.addElement(self.maps, map)
end

-- Local values: mapIds, _, map
function KioskMode:updateAvailableMaps()
	local v141_ = self.settings.maps
	table.clear(g_mapManager.maps)
	for _, v142_ in ipairs(self.maps) do
		if v141_ == nil or v141_[v142_.id] == true then
			local v143_ = g_mapManager.maps
			table.insert(v143_, v142_)
			g_mapManager.idToMap[v142_.id] = v142_
		end
	end
end

-- Local values: wasVideoPlaying
function KioskMode:resetVideoTimer()
	if self:getSetting("videos") == nil then
		return false
	end
	local v145_ = self.videoOverlay ~= nil
	self.videoStartTimer = self:getSetting("videoTimer")
	self:disposeVideo()
	self.currentVideoIndex = nil
	return v145_
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
	if self.currentVideoIndex == nil or self.currentVideoIndex >= #self:getSetting("videos") then
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

-- Local values: currentLanguage, nextIndex, k, v
function KioskMode:onToggleLanguage(actionName, inputValue, callbackState, isAnalog, isMouse, deviceCategory, binding)
	if GS_PLATFORM_PC and g_gui.currentGuiName == "MainScreen" then
		local v151_ = getLanguage()
		local v152_ = nil
		for v153_, v154_ in ipairs(g_availableLanguagesTable) do
			if v154_ == v151_ then
				v152_ = v153_ + math.sign(inputValue)
			end
		end
		local v155_ = (v152_ == nil or #g_availableLanguagesTable < v152_) and 1 or (v152_ < 1 and #g_availableLanguagesTable or v152_)
		local v156_ = g_availableLanguagesTable[v155_]
		g_kioskMode.nextLanguageIndex = v156_
		g_kioskMode.nextLanguageRestartTimer = g_time + 5000
		setLanguage(v156_)
		g_kioskMode:resetVideoTimer()
	end
end

function KioskMode:onReloadSavegame()
	if g_kioskMode:getSetting("reloadEnabled") or self.playtimeReloadTimer ~= nil then
		OnInGameMenuMenu()
	end
end

function KioskMode:getEndSlideOnLoad()
	if StartParams.getIsSet("kioskEndSlide") then
		return self.settings.endSlide
	else
		return nil
	end
end

-- Local values: restartArgs
function KioskMode:onPlaytimeReload()
	if g_currentMission ~= nil then
		local v160_ = self.settings.endSlide == nil and "" or "-kioskEndSlide"
		OnInGameMenuMenu(nil, nil, v160_)
	end
end

-- Local values: originalOnClickOk
function KioskMode.inj_mpLoadingScreen_onReadyToStart(screen, superFunc)
	if g_kioskMode:getEndSlideOnLoad() == nil then
		superFunc(screen)
	else
		local v163_ = screen.onClickOk
		screen.onClickOk = KioskMode.EMPTY_FUNC
		superFunc(screen)
		screen.onClickOk = v163_
	end
end

-- Local values: _, eventId
function KioskMode:registerGlobalInputActionEvents()
	if GS_PLATFORM_PC then
		local _, v164_ = g_inputBinding:registerActionEvent(InputAction.KIOSK_MODE_RESET_FILES, g_kioskMode, g_kioskMode.onResetFiles, false, true, false, true)
		g_inputBinding:setActionEventTextVisibility(v164_, false)
		local _, v165_ = g_inputBinding:registerActionEvent(InputAction.KIOSK_MODE_RELOAD_GAME, g_kioskMode, g_kioskMode.onReloadSavegame, false, true, false, true)
		g_inputBinding:setActionEventTextVisibility(v165_, false)
		local _, v166_ = g_inputBinding:registerActionEvent(InputAction.KIOSK_MODE_TOGGLE_LANGUAGE, nil, g_kioskMode.onToggleLanguage, false, true, false, true)
		g_inputBinding:setActionEventTextVisibility(v166_, false)
		local _, v167_ = g_inputBinding:registerActionEvent(InputAction.KIOSK_MODE_START_VIDEOS, nil, g_kioskMode.onStartVideos, false, true, false, true)
		g_inputBinding:setActionEventTextVisibility(v167_, false)
	end
end
function KioskMode.inj_mapManager_addMapItem(p168_, p169_, ...)
	local v170_ = p169_(p168_, ...)
	if v170_ then
		local v171_ = table.remove(p168_.maps, #p168_.maps)
		p168_.idToMap[v171_.id] = nil
		g_kioskMode:addRegisteredMaps(v171_)
	end
	g_kioskMode:updateAvailableMaps()
	return v170_
end
function KioskMode.inj_Farm_setInitialEconomy(p172_, ...)
	if not p172_.isSpectator then
		p172_.money = g_kioskMode:getSetting("startMoney")
		Logging.info("Set Kiosk-Mode farm startmoney: %d", p172_.money)
	end
end
function KioskMode.inj_ingameMap_registerInput(p173_, p174_, ...)
	if not g_kioskMode:getSetting("logoEnabled") then
		p174_(p173_, ...)
	end
end
function KioskMode.inj_inGameMenuMapFrame_updateInputGlyphs(p175_, ...)
	local v176_ = g_kioskMode:getSetting("farmlandShopEnabled")
	p175_.buttonSwitchMapMode:setDisabled(not v176_)
end
function KioskMode.inj_storeManager_getDefaultStoreItemsFilename(p177_, p178_, ...)
	local v179_ = g_kioskMode:getSetting("storeItems")
	if v179_ == nil then
		return p178_(p177_, ...)
	else
		return v179_
	end
end
function KioskMode.inj_environment_load(p180_, p181_, ...)
	local v182_ = p181_(p180_, ...)
	if g_kioskMode:getSetting("alwaysDay") then
		p180_.dayNightCycle = false
	end
	return v182_
end
function KioskMode.inj_loanTrigger_new(p183_, p184_, ...)
	local v185_ = p184_(p183_)
	v185_.isEnabled = g_kioskMode:getSetting("vehicleShopEnabled")
	return v185_
end
function KioskMode.inj_shopTrigger_new(p186_, p187_, ...)
	local v188_ = p187_(p186_)
	v188_.isEnabled = g_kioskMode:getSetting("vehicleShopEnabled")
	return v188_
end
function KioskMode.inj_vehicleSellingPoint_load(p189_, p190_, ...)
	local v191_ = p190_(p189_, ...)
	p189_.isEnabled = g_kioskMode:getSetting("vehicleShopEnabled")
	return v191_
end
function KioskMode.inj_animalLoadingTrigger_load(p192_, p193_, ...)
	local v194_ = p193_(p192_, ...)
	p192_.isEnabled = g_kioskMode:getSetting("animalShopEnabled")
	return v194_
end

function KioskMode.inj_fsBaseMission_getIsAutoSaveSupported(screen)
	return false
end

function KioskMode.inj_playerInputComponent_registerGlobalPlayerActionEvents(screen)
	g_kioskMode:getSetting("reloadEnabled")
end
function KioskMode.inj_playerInputComponent_getCanToggleCamera(p195_, p196_, ...)
	if g_kioskMode:getSetting("playerCanToggleCamera") then
		return p196_(p195_, ...)
	else
		return false
	end
end

function KioskMode.inj_fsBaseMission_update(mission, dt)
	if g_kioskMode.tryToEnterVehicle ~= nil then
		g_localPlayer:requestToEnterVehicle(g_kioskMode.tryToEnterVehicle)
		g_kioskMode.tryToEnterVehicle = nil
	end
end
function KioskMode.inj_player00_onStartMission()
	if g_kioskMode:getSetting("playtimeEnabled") then
		g_kioskMode.playtimeReloadTimer = g_kioskMode:getSetting("playtimeDuration")
	end
	if g_kioskMode:getSetting("farmlandsBuyAll") then
		g_currentMission:playerOwnsAllFields()
	end
	local v197_ = g_kioskMode:getSetting("startVehicleIndex")
	if v197_ ~= nil then
		local v198_ = g_currentMission.vehicleSystem.enterables[v197_]
		if v198_ ~= nil then
			g_kioskMode.tryToEnterVehicle = v198_
		end
	end
	if not g_kioskMode:getSetting("helpLineTriggerEnabled") then
		g_currentMission:setShowHelpTrigger(false)
	end
end

function KioskMode.inj_inGameMenu_makeIsAIEnabledPredicate(screen)
	return function()
		return g_kioskMode:getSetting("aiEnabled")
	end
end

function KioskMode.inj_inGameMenu_makeIsPricesEnabledPredicate(screen)
	return function()
		return false
	end
end

function KioskMode.inj_inGameMenu_makeIsAnimalsEnabledPredicate(screen)
	return function()
		return false
	end
end

function KioskMode.inj_inGameMenu_makeIsContractsEnabledPredicate(screen)
	return function()
		return false
	end
end

function KioskMode.inj_inGameMenu_makeIsGarageEnabledPredicate(screen)
	return function()
		return false
	end
end

function KioskMode.inj_inGameMenu_makeIsSettingsEnabledPredicate(screen)
	return function()
		return false
	end
end

function KioskMode.inj_inGameMenu_makeIsHelpEnabledPredicate(screen)
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
	if g_kioskMode:getSetting("productionEnabled") then
		superFunc(self)
	else
		InfoDialog.show(g_i18n:getText("ui_featureDisabled"))
	end
end

function KioskMode:inj_railroadCallerActivatable_run(superFunc)
	if g_kioskMode:getSetting("trainEnabled") then
		superFunc(self)
	else
		InfoDialog.show(g_i18n:getText("ui_featureDisabled"))
	end
end
function KioskMode.inj_specializationManager_addSpecialization(p208_, _, p209_, ...)
	if p208_ == g_specializationManager then
		if p209_ == "AIJobVehicle" then
			if not g_kioskMode:getSetting("aiEnabled") then
				local v_u_210_ = AIJobVehicle.onRegisterActionEvents
				function AIJobVehicle.onRegisterActionEvents(p211_, p212_, p213_)
					-- upvalues: (copy) v_u_210_
					if p211_.isClient then
						p211_:clearActionEventsTable(p211_.spec_aiJobVehicle.actionEvents)
					end
					if g_kioskMode:getSetting("aiEnabled") then
						if g_kioskMode:getSetting("ingameMenuEnabled") or p211_:getStartableAIJob() ~= nil then
							v_u_210_(p211_, p212_, p213_)
						end
					else
						return
					end
				end
			end
			if not g_kioskMode:getSetting("aiWorkerEnabled") then
				local v_u_214_ = AIJobVehicle.onRegisterActionEvents
				function AIJobVehicle.toggleAIVehicle(p215_)
					-- upvalues: (copy) v_u_214_
					if g_kioskMode:getSetting("aiWorkerEnabled") then
						v_u_214_(p215_)
					else
						InfoDialog.show(g_i18n:getText("ui_featureDisabled"))
					end
				end
				return
			end
		elseif p209_ == "Drivable" and g_kioskMode:getSetting("extendedDrivingHelp") then
			local v_u_216_ = Drivable.onRegisterActionEvents
			function Drivable.onRegisterActionEvents(p217_, p218_, p219_)
				-- upvalues: (copy) v_u_216_
				v_u_216_(p217_, p218_, p219_)
				local v220_ = p217_.spec_drivable
				for _, v221_ in pairs(v220_.actionEvents) do
					local v222_ = v221_.actionEventId
					local v223_ = g_inputBinding.events[v222_]
					if v223_.displayPriority == GS_PRIO_VERY_LOW then
						g_inputBinding:setActionEventTextPriority(v222_, GS_PRIO_VERY_HIGH)
					elseif v223_.displayPriority == GS_PRIO_LOW then
						g_inputBinding:setActionEventTextPriority(v222_, GS_PRIO_HIGH)
					end
					if not v223_.displayIsVisible then
						g_inputBinding:setActionEventTextVisibility(v222_, true)
					end
				end
			end
			return
		end
	elseif p208_ == g_placeableSpecializationManager then
		if p209_ == "PlaceableWardrobe" then
			if not g_kioskMode:getSetting("wardrobeShopEnabled") then
				function WardrobeActivatable.run()
					InfoDialog.show(g_i18n:getText("ui_featureDisabled"))
				end
				return
			end
		elseif p209_ == "PlaceableRiceField" and not g_kioskMode:getSetting("riceFieldEnabled") then
			function PlaceableRiceFieldActivatable.run()
				InfoDialog.show(g_i18n:getText("ui_featureDisabled"))
			end
		end
	end
end
function KioskMode.inj_ingameMenu00_getIsTourSupported(p224_, p225_)
	if g_kioskMode:getSetting("tourEnabled") then
		return p225_(p224_)
	else
		return false
	end
end

-- Local values: width, height, filename, overlay
function KioskMode.inj_hud_createDisplayComponents(hud, uiScale)
	if g_kioskMode:getSetting("logoEnabled") then
		hud.ingameMap:setIsVisible(false)
		local v227_ = g_kioskMode:getSetting("logoWidth")
		local v228_ = g_kioskMode:getSetting("logoHeight")
		local v229_ = g_kioskMode:getSetting("logoFilename")
		local v230_, v231_ = getNormalizedScreenValues(v227_, v228_)
		local v232_ = Overlay.new(v229_, g_safeFrameOffsetX, g_safeFrameOffsetY, v230_, v231_)
		hud.kioskModeLogoElement = HUDElement.new(v232_)
		local v233_ = hud.displayComponents
		local v234_ = hud.kioskModeLogoElement
		table.insert(v233_, v234_)
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

-- Local values: _, modItem, _, modName, modItem
function KioskMode.inj_modSelectionScreenn_update(screen, dt)
	if not g_kioskMode:getSetting("canSelectMods") then
		for _, v238_ in pairs(screen.selectedMods) do
			screen:setItemState(v238_, false)
		end
		for _, v239_ in pairs(g_kioskMode:getSetting("mods")) do
			local v240_ = g_modManager:getModByName(v239_)
			if v240_ ~= nil then
				if screen:shouldShowModInList(v240_) then
					screen:setItemState(v240_, true)
				else
					Logging.error("Mod \'%s\' is not available for current kiosk mode setup", v240_.title)
				end
			end
		end
		screen:onClickOk()
	end
end

-- Local values: info, map
function KioskMode.inj_newGameScreen_update(screen, dt)
	local v242_ = screen.startMissionInfo or g_startMissionInfo
	if g_mapManager:getNumOfMaps() == 1 then
		v242_.mapId = g_mapManager:getMapDataByIndex(1).id
	end
	v242_.initialMoney = g_kioskMode:getSetting("startMoney") or 100000
	screen:onClickOk()
end

-- Local values: savegameController, savegame
function KioskMode.inj_careerScreen_update(screen, dt)
	if not g_kioskMode:getSetting("canSelectSavegame") then
		screen.selectedIndex = 1
		screen:startSavegame(((screen.savegameController or g_savegameController):getSavegame(screen.selectedIndex)))
	end
end

function KioskMode.inj_mainScreen_inputEvent(screen, superFunc, action, value, eventUsed)
	return superFunc(screen, action, value, action == InputAction.KIOSK_MODE_START_VIDEOS and true or (g_kioskMode:resetVideoTimer() and true or eventUsed))
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
function KioskMode.inj_gui_changeScreen(p252_, p253_, p254_, p255_, ...)
	if p255_ == InGameMenu then
		if not g_kioskMode:getSetting("screenEnabled") then
			return
		end
	elseif p255_ == ShopMenu then
		if not g_kioskMode:getSetting("vehicleShopEnabled") then
			return
		end
	elseif p255_ == WardrobeScreen then
		if not g_kioskMode:getSetting("wardrobeShopEnabled") then
			return
		end
	elseif p255_ == ConstructionScreen then
		if not g_kioskMode:getSetting("placeableShopEnabled") then
			return
		end
	elseif p255_ == AnimalScreen and not g_kioskMode:getSetting("animalShopEnabled") then
		return
	end
	return p253_(p252_, p254_, p255_, ...)
end
function KioskMode.inj_gui_showGui(p256_, p257_, p258_, ...)
	if p258_ == "InGameMenu" then
		if not g_kioskMode:getSetting("screenEnabled") then
			return
		end
	elseif p258_ == "ShopMenu" then
		if not g_kioskMode:getSetting("vehicleShopEnabled") then
			return
		end
	elseif p258_ == "WardrobeScreen" then
		if not g_kioskMode:getSetting("wardrobeShopEnabled") then
			return
		end
	elseif p258_ == "ConstructionScreen" then
		if not g_kioskMode:getSetting("placeableShopEnabled") then
			return
		end
	elseif p258_ == "AnimalScreen" and not g_kioskMode:getSetting("animalShopEnabled") then
		return
	end
	return p257_(p256_, p258_, ...)
end
function KioskMode.inj_messageCenter_publish(p259_, p260_, p261_, ...)
	if g_kioskMode:getSetting("screenEnabled") or p261_ ~= MessageType.GUI_INGAME_OPEN_AI_SCREEN then
		return p260_(p259_, p261_, ...)
	end
end
