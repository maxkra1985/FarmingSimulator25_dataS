-- Local values: MainScreen_mt
MainScreen = {}
local MainScreen_mt = Class(MainScreen, ScreenElement)
function MainScreen.register()
	local v2_ = MainScreen.new()
	g_gui:loadGui("dataS/gui/MainScreen.xml", "MainScreen", v2_)
	return v2_
end
MainScreen.NOTIFICATION_ANIMATION_DURATION = 500
MainScreen.NOTIFICATION_CHECK_DELAY = 500
MainScreen.NOTIFICATION_ANIM_DELAY = 2000
MainScreen.NO_STORE_URL = "noStore"

-- Upvalues: MainScreen_mt
-- Local values: self
function MainScreen.new(target, custom_mt)
	-- upvalues: (copy) MainScreen_mt
	local v5_ = ScreenElement.new(target, custom_mt or MainScreen_mt)
	v5_.firstTimeOpened = true
	v5_.lastActiveButton = nil
	v5_.blendDir = 0
	v5_.blendingAlpha = 1
	v5_.disableMultiplayer = false
	v5_.showGamepadModeDialog = true
	v5_.showHeadTrackingDialog = true
	v5_.notificationShowAnimation = TweenSequence.NO_SEQUENCE
	v5_.notificationsHidePosition = { 2, 0 }
	local v6_ = Platform.checkGPUDriver
	if v6_ then
		v6_ = not StartParams.getIsSet("restart")
	end
	v5_.doGPUDriveCheck = v6_
	v5_.isDeleted = false
	v5_.checkForModHubLoaded = true
	return v5_
end

-- Local values: newGui
function MainScreen.createFromExistingGui(gui, guiName)
	local v9_ = MainScreen.new()
	g_gui.guis[guiName]:delete()
	g_gui.guis[guiName].target:delete()
	g_gui:loadGui(gui.xmlFilename, guiName, v9_)
	return v9_
end

function MainScreen:onCreate()
	self.lastButtonPressed = nil
	self.isBackAllowed = false
	self:setupButtons()
	self:setupNotifications()
	self:updateTheme()
end

function MainScreen:onClickBack(forceBack, usedMenuButton)
	if GS_PLATFORM_ID ~= PlatformId.ANDROID then
		return MainScreen:superClass().onClickBack(self)
	end
	YesNoDialog.show(self.onYesNoQuitGame, self, g_i18n:getText("ui_youWantToQuitGame"))
	return false
end

function MainScreen:onYesNoQuitGame(yes)
	if yes then
		requestExit()
	end
end

-- Local values: buttonSetup, previousButton, index, button
function MainScreen:setupButtons()
	local v14_ = { self.careerButton }
	if Platform.supportsMultiplayer then
		local v15_ = self.multiplayerButton
		table.insert(v14_, v15_)
	end
	if Platform.supportsMods then
		local v16_ = self.downloadModsButton
		table.insert(v14_, v16_)
	end
	local v17_ = self.achievementsButton
	table.insert(v14_, v17_)
	if Platform.hasNativeStore then
		local v18_ = self.storeButton
		table.insert(v14_, v18_)
	end
	if not Platform.isMobile then
		local v19_ = self.settingsButton
		table.insert(v14_, v19_)
	end
	local v20_ = self.creditsButton
	table.insert(v14_, v20_)
	if Platform.canQuitApplication then
		local v21_ = self.quitButton
		table.insert(v14_, v21_)
	end
	if Platform.needsSignIn then
		local v22_ = self.changeUserButton
		table.insert(v14_, v22_)
	end
	if Platform.hasMainScreenLanguageSelection then
		local v23_ = self.changeLanguageButton
		table.insert(v14_, v23_)
	end
	local v24_ = nil
	for _, v25_ in pairs(v14_) do
		v25_:setVisible(true)
		if v24_ ~= nil then
			FocusManager:linkElements(v25_, FocusManager.LEFT, v24_)
		end
		v24_ = v25_
	end
	FocusManager:linkElements(v24_, FocusManager.BOTTOM, v14_[1])
	FocusManager:linkElements(v14_[1], FocusManager.TOP, v24_)
	self.buttonBox:invalidateLayout()
	v14_[#v14_].focusChangeOverride = nil
	self.activeButtons = v14_
end

-- Local values: gameVersionText
function MainScreen:onCreateGameVersion(element)
	element:setText(g_gameVersionDisplay .. g_gameVersionDisplayExtra .. " (" .. getEngineRevision() .. "/" .. g_gameRevision .. ")")
	self.versionElement = element
end

function MainScreen:onHighlight(element)
	if not Platform.isConsole then
		FocusManager:setFocus(element)
	end
end

function MainScreen:delete()
	self.isDeleted = true
	g_messageCenter:unsubscribeAll(self)
	MainScreen:superClass().delete(self)
end

function MainScreen:onClose()
	MainScreen:superClass().onClose(self)
	g_inputBinding:removeActionEventsByTarget(self)
	g_messageCenter:unsubscribeAll(self)
	GuiOverlay.deleteOverlay(self.notificationImage.overlay)
	GuiOverlay.deleteOverlay(self.notificationImagePrev.overlay)
	GuiOverlay.deleteOverlay(self.notificationImageNext.overlay)
	if GS_IS_NETFLIX_VERSION then
		hideNetflixButton()
	end
end

function MainScreen:onOpen()
	MainScreen:superClass().onOpen(self)
	setPresenceMode(PresenceModes.PRESENCE_IDLE)
	flushWebCache()
	self:resetNotifications()
	if self.firstTimeOpened then
		self.firstTimeOpened = false
		if isGameFullyInstalled() then
			FocusManager:setFocus(self.careerButton)
		else
			error("Fatal error: the game was not fully installed but the game code expects it to be.")
		end
	end
	startMenuMusic()
	if g_isServerStreamingVersion then
		self.notificationElement:setVisible(false)
		self.notificationElement:setDisabled(true)
	end
	FocusManager:lockFocusInput(InputAction.MENU_ACCEPT, 150)
	self:setSoundSuppressed(true)
	if self.lastActiveButton ~= nil then
		FocusManager:unsetFocus(self.lastActiveButton)
		FocusManager:setFocus(self.lastActiveButton)
	end
	self:setSoundSuppressed(false)
	self:updateTheme()
	g_gameStateManager:setGameState(GameState.MENU_MAIN)
	if self.googlePlayButton ~= nil then
		local v32_ = self.googlePlayButton
		local v33_
		if getPlatformId() == PlatformId.ANDROID then
			v33_ = not GS_IS_NETFLIX_VERSION
		else
			v33_ = false
		end
		v32_:setVisible(v33_)
		if g_buildTypeParam == "CHINA_GAPP" or g_buildTypeParam == "CHINA" then
			self.googlePlayButton:setIconSize(0, 0)
		end
	end
	self.lastSignedInState = nil
	g_messageCenter:publish(MessageType.GUI_MAIN_SCREEN_OPEN)
	g_messageCenter:subscribe(MessageType.INSETS_CHANGED, self.updateInsets, self)
	if GS_IS_NETFLIX_VERSION then
		showNetflixButton()
		netflixCheckUserAuth()
	end
	if isESRBDiscVersion() and not g_gameSettings:getValue(GameSettings.SETTING.ESRB_UPDATE_SHOWN) then
		self:showESRBUpdateinfo()
	end
	if g_modNameToDirectory[g_uniqueDlcNamePrefix .. "highlandsFishingPack"] == nil then
		self.backgroundImage:setImageFilename("shared/splash.png")
	else
		self.backgroundImage:setImageFilename("shared/splash_highlandsFishing.png")
	end
	self.checkForModHubLoaded = true
end

-- Local values: _, rightInset_, _, _, showPosition, anim, moveIn
function MainScreen:setupNotifications()
	local _, v35_, _, _ = getSafeFrameInsets()
	local v36_ = { self.notificationElement.position[1] - v35_, self.notificationElement.position[2] }
	self.notificationsHidePosition = { -self.notificationElement.position[1] + self.notificationElement.size[1], self.notificationElement.position[2] }
	local v37_ = TweenSequence.new(self)
	v37_:addInterval(MainScreen.NOTIFICATION_ANIM_DELAY)
	local v38_ = MultiValueTween.new(self.notificationElement.setPosition, self.notificationsHidePosition, v36_, MainScreen.NOTIFICATION_ANIMATION_DURATION)
	v37_:addTween(v38_)
	v38_:setTarget(self.notificationElement)
	v37_:addCallback(self.setNotificationButtonsDisabled, false)
	self.notificationShowAnimation = v37_
	self:resetNotifications()
end

-- Local values: _, button, _, button
function MainScreen:setNotificationButtonsDisabled(isDisabled)
	self.notificationButtonLeft:setVisible(#self.notifications >= 2)
	self.notificationButtonRight:setVisible(#self.notifications >= 2)
	if self.notificationButtonLeft:getIsVisible() then
		for _, v41_ in ipairs(self.activeButtons) do
			FocusManager:linkElements(v41_, FocusManager.RIGHT, self.notificationButtonLeft)
		end
		FocusManager:linkElements(self.notificationButtonLeft, FocusManager.LEFT, self.activeButtons[1])
		FocusManager:linkElements(self.notificationButtonLeft, FocusManager.TOP, self.activeButtons[1])
		FocusManager:linkElements(self.notificationButtonLeft, FocusManager.BOTTOM, self.activeButtons[#self.activeButtons])
		FocusManager:linkElements(self.notificationButtonRight, FocusManager.TOP, self.activeButtons[1])
		FocusManager:linkElements(self.notificationButtonRight, FocusManager.BOTTOM, self.activeButtons[#self.activeButtons])
	else
		for _, v42_ in ipairs(self.activeButtons) do
			FocusManager:linkElements(v42_, FocusManager.RIGHT, nil)
			FocusManager:linkElements(v42_, FocusManager.LEFT, nil)
		end
	end
	self.notificationButtonLeft:setDisabled(isDisabled)
	self.notificationButtonRight:setDisabled(isDisabled)
	self.notificationButtonOpen:setDisabled(isDisabled)
end

function MainScreen:resetNotifications()
	if not self.isDeleted then
		self.notificationsReady = false
		self.notificationsCheckTimer = 0
		self.notifications = {}
		self.activeNotification = 0
		self.notificationShowAnimation:reset()
		self:setNotificationButtonsDisabled(true)
		local v44_ = self.notificationElement
		local v45_ = self.notificationsHidePosition
		v44_:setPosition(unpack(v45_))
	end
end

function MainScreen:onYesNoUseGamepadMode(yes)
	g_gameSettings:setValue("gamepadEnabledSetByUser", true)
	g_gameSettings:setValue("isGamepadEnabled", yes)
	g_gameSettings:save()
end

function MainScreen:onYesNoUseHeadTracking(yes)
	g_gameSettings:setValue("headTrackingEnabledSetByUser", true)
	g_gameSettings:setValue("isHeadTrackingEnabled", yes)
	g_gameSettings:save()
end

function MainScreen:onMultiplayerClick(element)
	self.lastActiveButton = element
	resetMultiplayerChecks()
	self:onMultiplayerClickPerform()
end

function MainScreen:onMultiplayerClickPerform()
	if isGameFullyInstalled() then
		if masterServerConnectFront == nil then
			RestartManager:setStartScreen(RestartManager.START_SCREEN_MULTIPLAYER)
			doRestart(false, "")
			return
		elseif PlatformPrivilegeUtil.checkMultiplayer(self.onMultiplayerClickPerform, self) then
			g_startMissionInfo:reset()
			g_startMissionInfo.isMultiplayer = true
			g_gui:setIsMultiplayer(true)
			g_gui:showGui("MultiplayerScreen")
		end
	else
		showGameInstallProgress()
		return
	end
end

function MainScreen:onCareerClick(element)
	self.lastActiveButton = element
	if isGameFullyInstalled() then
		g_startMissionInfo:reset()
		g_startMissionInfo.isMultiplayer = false
		g_gui:setIsMultiplayer(false)
		self:changeScreen(CareerScreen)
	else
		showGameInstallProgress()
	end
end

function MainScreen:onDownloadModsClick(element)
	self.lastActiveButton = element
	resetMultiplayerChecks()
	self:onDownloadModsClickPerform()
end

function MainScreen:onDownloadModsClickPerform()
	if getNetworkError() then
		ConnectionFailedDialog.showMasterServerConnectionFailedReason(MasterServerConnection.FAILED_CONNECTION_LOST, "MainScreen")
		return
	elseif PlatformPrivilegeUtil.checkModDownload(self.onDownloadModsClickPerform, self) then
		modDownloadManagerUpdateSync(true)
		g_gui:showGui("ModHubScreen")
	end
end

function MainScreen:onAchievementsClick(element)
	self.lastActiveButton = element
	if Platform.hasOnlineAchievements and getNetworkError() then
		ConnectionFailedDialog.showMasterServerConnectionFailedReason(MasterServerConnection.FAILED_CONNECTION_LOST, "MainScreen")
	else
		g_gui:showGui("AchievementsScreen")
	end
end

function MainScreen:onStoreClick(element)
	self.lastActiveButton = element
	if storeHasNativeGUI() and (getNetworkError() ~= nil or not storeShow("")) then
		InfoDialog.show(g_i18n:getText("ui_dlcStoreNotConnected"), MainScreen.onStoreFailedOk, self)
	end
end

function MainScreen:onStoreFailedOk()
	g_gui:showGui("MainScreen")
end

function MainScreen:onSettingsClick(element)
	self.lastActiveButton = element
	g_gui:showGui("SettingsScreen")
end

function MainScreen:onCreditsClick(element)
	self.lastActiveButton = element
	g_gui:showGui("CreditsScreen")
end

function MainScreen:onChangeUserClick()
	g_gamepadSigninScreen.forceShowSigninGui = true
	g_gui:showGui("GamepadSigninScreen")
end

function MainScreen:onChangeLanguageClick() end

function MainScreen:onChangeMobileSettingsClick(element)
	self.lastActiveButton = element
	g_gui:showGui("MobileSettingsScreen")
end

function MainScreen:onQuitClick()
	doExit()
end

function MainScreen:cycleNotification(signedDelta)
	self.activeNotification = self.activeNotification + signedDelta
	if self.activeNotification > #self.notifications then
		self.activeNotification = 1
	elseif self.activeNotification < 1 then
		self.activeNotification = #self.notifications
	end
	self:assignNotificationData()
end

function MainScreen:onClickNextNotification(element)
	self:cycleNotification(1)
end

function MainScreen:onClickPreviousNotification(element)
	self:cycleNotification(-1)
end

-- Local values: url
function MainScreen:onClickOpenNotification()
	if #self.notifications > 0 then
		if self.notifications[self.activeNotification].url == "openOptionsGraphics" then
			g_gui:showGui("SettingsScreen")
			g_settingsScreen:showDisplaySettings()
			return
		end
		local v71_ = self.notifications[self.activeNotification].url
		if v71_ ~= MainScreen.NO_STORE_URL and v71_ ~= "" then
			if storeHasNativeGUI() then
				if not storeShow(v71_) then
					InfoDialog.show(g_i18n:getText("ui_dlcStoreNotConnected"), MainScreen.onStoreFailedOk, self)
					return
				end
			else
				openWebFile(self.notifications[self.activeNotification].url, "")
			end
		end
	end
end

function MainScreen:onDlcCorruptClick()
	g_gui:showGui("MainScreen")
end

-- Local values: notificationCount, i, title, message, url, image, date, category
function MainScreen:updateNotifications(dt)
	if self.notificationsReady and (#self.notifications > 0 and not self.notificationShowAnimation:getFinished()) then
		self.notificationShowAnimation:update(dt)
	end
	if not self.notificationsReady then
		self.notificationsCheckTimer = self.notificationsCheckTimer + dt
		if self.notificationsCheckTimer > MainScreen.NOTIFICATION_CHECK_DELAY then
			self.notificationsCheckTimer = 0
			self.notificationsReady = notificationsLoaded()
			if self.notificationsReady then
				local v74_ = getNumOfNotifications()
				Logging.devInfo("Loaded %d notification(s)", v74_)
				for v75_ = 0, v74_ - 1 do
					local v76_, v77_, v78_, v79_, v80_, v81_ = getNotification(v75_)
					if v76_ == "" or v77_ == "" then
						Logging.devWarning("Recieved invalid notification \'%d\'.\n    Title: %s\n    Message: %s\n    Url: %s\n    Image: %s\n    Date: %s", v75_, v76_, v77_, v78_, v79_, v80_)
					else
						local v82_ = self.notifications
						table.insert(v82_, {
							["title"] = v76_,
							["message"] = v77_,
							["url"] = v78_,
							["image"] = v79_,
							["date"] = v80_,
							["category"] = v81_
						})
					end
				end
				if #self.notifications > 0 then
					self.activeNotification = 1
					self.indexState:setPageCount(#self.notifications, self.activeNotification)
					self:assignNotificationData()
					self.notificationShowAnimation:start()
					return
				end
				self.indexState:setPageCount(0)
			end
		end
	end
end

-- Local values: _, numUpdates, _
function MainScreen:updateAvailableModUpdates()
	if self.checkForModHubLoaded and modDownloadManagerLoaded() then
		g_modHubController:load()
		local _, v84_, _ = g_modHubController:getCategoryData(ModHubController.CATEGORY_ID_UPDATE)
		self.iconHasUpdates:setVisible(v84_ > 0)
		self.checkForModHubLoaded = false
	end
end

-- Local values: openDriverUpdatePage, signedIn
function MainScreen:update(dt)
	MainScreen:superClass().update(self, dt)
	self:updateAvailableModUpdates()
	if self.doGPUDriveCheck then
		self.doGPUDriveCheck = false
		if getIsGPUDriverOutdated() then
			YesNoDialog.show(function(p87_)
				if p87_ then
					openWebFile(Platform.urlUpdateGPUDriver, "")
				end
			end, nil, g_i18n:getText("warning_gpuDriverOutdated"), nil, nil, nil, DialogElement.TYPE_WARNING)
		end
	end
	modDownloadManagerUpdateSync(false)
	if getPlatformId() == PlatformId.ANDROID then
		local v88_ = getIsUserSignedIn()
		if GS_IS_NETFLIX_VERSION then
			if not v88_ then
				g_gui:showGui("NetflixSigninScreen")
			end
		elseif v88_ ~= self.lastSignedInState then
			if v88_ then
				self.googlePlayButton:setText(getUserName())
				self.achievementsButton:setDisabled(false)
			else
				self.googlePlayButton:setText("")
				self.achievementsButton:setDisabled(true)
			end
		end
		self.lastSignedInState = v88_
	end
	if self.showGamepadModeDialog and (Platform.showGamepadModeDialog and (not g_gameSettings:getValue(GameSettings.SETTING.GAMEPAD_ENABLED_SET_BY_USER) and getNumOfGamepads() > 0)) then
		YesNoDialog.show(self.onYesNoUseGamepadMode, self, g_i18n:getText("ui_activateGamepads"), g_i18n:getText("ui_activateGamepadsTitle"))
		self.showGamepadModeDialog = false
	end
	if self.showHeadTrackingDialog and (Platform.showHeadTrackingDialog and (not g_gameSettings:getValue(GameSettings.SETTING.HEAD_TRACKING_ENABLED_SET_BY_USER) and isHeadTrackingAvailable())) then
		YesNoDialog.show(self.onYesNoUseHeadTracking, self, g_i18n:getText("ui_activateHeadTracking"), g_i18n:getText("ui_activateHeadTrackingTitle"))
		self.showHeadTrackingDialog = false
	end
	if Platform.showGamerTagInMainScreen then
		self.gamerTagElement:setText(g_gameSettings:getValue(GameSettings.SETTING.ONLINE_PRESENCE_NAME))
	end
	if GS_IS_CONSOLE_VERSION then
		self:updateStoreButtons()
	end
	if self.isFirstOpen == nil then
		if isGameFullyInstalled() then
			FocusManager:setFocus(self.careerButton)
		else
			error("Not fully installed. This state is currently not supported")
		end
		FocusManager:setFocus(FocusManager.currentFocusData.initialFocusElement)
		self.isFirstOpen = true
	end
	if not g_isServerStreamingVersion then
		self:updateNotifications(dt)
	end
	if GS_IS_CONSOLE_VERSION then
		if storeHaveDlcsChanged() or (haveModsChanged() or g_forceNeedsDlcsAndModsReload) then
			g_forceNeedsDlcsAndModsReload = false
			reloadDlcsAndMods()
			self:resetNotifications()
			self:updateTheme()
		end
	elseif haveModsChanged() then
		reloadDlcsAndMods()
	end
	if storeAreDlcsCorrupted() then
		InfoDialog.show(g_i18n:getText("ui_dlcsCorruptRedownload"), self.onDlcCorruptClick, self)
	end
end

function MainScreen:updateStoreButtons()
	if getNetworkError() then
		if self.storeButton:getIsActive() then
			self.storeButton:setDisabled(true)
			return
		end
	elseif not self.storeButton:getIsActive() then
		self.storeButton:setDisabled(false)
	end
end

-- Local values: prevNotification, nextNotification, imageFile, imageFilePrev, imageFileNext, url, showButton
function MainScreen:assignNotificationData()
	if self.activeNotification > 0 and self.activeNotification <= #self.notifications then
		local v91_ = self.activeNotification - 1
		local v92_ = v91_ == 0 and self.activeNotification ~= #self.notifications and #self.notifications or v91_
		self.notificationElementPrev:setVisible(v92_ > 0)
		local v93_ = self.activeNotification + 1
		local v94_ = #self.notifications < v93_ and self.activeNotification ~= 1 and 1 or v93_
		self.notificationElementNext:setVisible(v94_ <= #self.notifications)
		if GS_IS_CONSOLE_VERSION then
			self.notificationMessage:setText(g_i18n:getText("notification_nowAvailable"))
			if v92_ > 0 then
				self.notificationMessagePrev:setText(g_i18n:getText("notification_nowAvailable"))
			end
			if v94_ <= #self.notifications then
				self.notificationMessageNext:setText(g_i18n:getText("notification_nowAvailable"))
			end
		else
			self.notificationMessage:setText(self.notifications[self.activeNotification].message)
			if v92_ > 0 then
				self.notificationMessagePrev:setText(self.notifications[v92_].message)
			end
			if v94_ <= #self.notifications then
				self.notificationMessageNext:setText(self.notifications[v94_].message)
			end
		end
		self.notificationTitle:setText(self.notifications[self.activeNotification].title)
		if v92_ > 0 then
			self.notificationTitlePrev:setText(self.notifications[v92_].title)
		end
		if v94_ <= #self.notifications then
			self.notificationTitleNext:setText(self.notifications[v94_].title)
		end
		local v95_ = self.notifications[self.activeNotification].image
		local v96_ = v95_ == "graphicsOptionsImage" and "dataS/menu/notification_dummy.png" or v95_
		self.notificationImage:setImageFilename(v96_)
		if v92_ > 0 then
			local v97_ = self.notifications[v92_].image
			local v98_ = v97_ == "graphicsOptionsImage" and "dataS/menu/notification_dummy.png" or v97_
			self.notificationImagePrev:setImageFilename(v98_)
		end
		if v94_ <= #self.notifications then
			local v99_ = self.notifications[v94_].image
			local v100_ = v99_ == "graphicsOptionsImage" and "dataS/menu/notification_dummy.png" or v99_
			self.notificationImageNext:setImageFilename(v100_)
		end
		if self.notifications[self.activeNotification].url == "openOptionsGraphics" then
			self.notificationButtonOpen:setText(g_i18n:getText("button_settings"))
		else
			if storeHasNativeGUI() then
				self.notificationButtonOpen:setText(g_i18n:getText("button_dlcStore"))
			else
				self.notificationButtonOpen:setText(g_i18n:getText("button_visitWebsite"))
			end
			local v101_ = self.notifications[self.activeNotification].url
			local v102_
			if v101_ == MainScreen.NO_STORE_URL then
				v102_ = false
			else
				v102_ = v101_ ~= ""
			end
			self.notificationButtonOpen:setVisible(v102_)
		end
		self.indexState:setPageIndex(self.activeNotification)
	end
end

-- Local values: _, name
function MainScreen:hasAllDLCs(list)
	for _, v104_ in ipairs(list) do
		if GS_IS_EPIC_VERSION then
			if g_modManager:getModByName(g_uniqueDlcNamePrefix .. v104_) == nil then
				return false
			end
		elseif g_modNameToDirectory[g_uniqueDlcNamePrefix .. v104_] == nil then
			return false
		end
	end
	return true
end

-- Local values: filename
function MainScreen:updateTheme()
	local v106_ = Platform.gameLogos[g_languageShort]
	if v106_ == nil then
		v106_ = Platform.gameLogos.en
	end
	if self.logo ~= nil then
		self.logo:setImageFilename(v106_)
	end
end

function MainScreen:onClickGooglePlayButton()
	if g_buildTypeParam == "CHINA_GAPP" or g_buildTypeParam == "CHINA" then
		userSignout()
		g_gui:showGui("ChinaSigninScreen")
	elseif getIsUserSignedIn() then
		userSignout()
	else
		requestUserSignin()
	end
	g_messageCenter:publish(MessageType.USER_PROFILE_CHANGED)
end

-- Local values: text
function MainScreen:inputEvent(action, value, eventUsed)
	local v111_ = MainScreen:superClass().inputEvent(self, action, value, eventUsed)
	if Platform.isAndroid and action == InputAction.MENU_BACK then
		local v112_ = g_i18n:getText(InGameMenu.L10N_SYMBOL.END_GAME)
		YesNoDialog.show(self.onYesNoEnd, self, v112_)
		v111_ = true
	end
	return v111_
end

function MainScreen:onYesNoEnd(yes)
	if yes then
		doExit()
	end
end

-- Local values: leftInset, _, _, _
function MainScreen:updateInsets()
	if self.versionElementPosX == nil then
		self.versionElementPosX = self.versionElement.absPosition[1]
	end
	local v115_, _, _, _ = getSafeFrameInsets()
	self.versionElement.absPosition[1] = self.versionElementPosX + v115_
end

function MainScreen:showESRBUpdateinfo()
	g_gameSettings:setValue(GameSettings.SETTING.ESRB_UPDATE_SHOWN, true, true)
	ESRBUpdateDialog.show(g_i18n:getText("ui_ESRBUpdateInfo"), self.onESRBUpdateShown, self)
end
