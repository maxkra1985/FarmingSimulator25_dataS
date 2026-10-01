CareerScreen = {}
local CareerScreen_mt = Class(CareerScreen, ScreenElement)
CareerScreen.MISSING_MAP_ICON_PATH = "dataS/menu/hud/missingMap.png"
CareerScreen.SAVEGAME_LOADING_DIALOG_DELAY = 100
CareerScreen.SAVEGAME_UPDATE_TIME = 20000
CareerScreen.SAVEGAME_REFRESH_TIME = 3000
CareerScreen.SAVEGAME_UPLOAD_TRIGGER_DURATION = 5000
CareerScreen.CELL_NAME_DEFAULT = "listItem"
CareerScreen.CELL_NAME_MOBILE = "listItemMobile"
function CareerScreen.register()
	local careerScreen = CareerScreen.new()
	g_gui:loadGui("dataS/gui/CareerScreen.xml", "CareerScreen", careerScreen)
	return careerScreen
end
function CareerScreen.new(target, custom_mt)
	local self = ScreenElement.new(target, custom_mt or CareerScreen_mt)
	self.isMultiplayer = false
	self.mapNameTexts = {}
	self.playerNameTexts = {}
	self.playerCharacterTexts = {}
	self.savegameNameTexts = {}
	self.moneyTexts = {}
	self.timePlayedTexts = {}
	self.difficultyTexts = {}
	self.dateTexts = {}
	self.statusTexts = {}
	self.statusIcons = {}
	self.listItemData = {}
	self.listItemTexts = {}
	self.listItemInfoText = {}
	self.economicDifficultyTexts = { g_i18n:getText("button_easy"), g_i18n:getText("button_normal"), g_i18n:getText("button_hard") }
	self.savegames = {}
	self.tempIsSliderScrolling = false
	self.ignoreCorruptOnNextUpdate = false
	self.gameIcons = {}
	self.currentIndex = 0
	self.totalPlayedHours = 0
	self.selectedIndexToRestore = 0
	self.recreateListOnOpen = true
	self.savegameUpdateTimer = CareerScreen.SAVEGAME_UPDATE_TIME
	self.savegameRefreshTimer = CareerScreen.SAVEGAME_REFRESH_TIME
	self.savegameLoadingDialogDelay = -1
	return self
end
function CareerScreen.createFromExistingGui(gui, guiName)
	local newGui = CareerScreen.new()
	g_gui.guis[guiName]:delete()
	g_gui.guis[guiName].target:delete()
	g_gui:loadGui(gui.xmlFilename, guiName, newGui)
	return newGui
end
function CareerScreen:onOpen()
	CareerScreen:superClass().onOpen(self)
	g_messageCenter:subscribe(MessageType.INSETS_CHANGED, self.updateInsets, self)
	if Platform.supportsSavegameDebugUpload then
		if g_isDevelopmentVersion then
			addConsoleCommand("gsSavegameUploadSelected", "Uploads the selected savegame", "uploadDebugSavegame", self)
		end
		self.buttonStart.isTriggerableByGlobalAction = false
		self.ignoreNextClick = false
		g_inputBinding:registerActionEvent(InputAction.MENU_ACCEPT, self, self.onAcceptPressed, false, false, true, true)
		g_inputBinding:registerActionEvent(InputAction.MENU_ACCEPT, self, self.onAcceptUp, true, false, false, true)
		self.openUpdateLoopIndex = g_updateLoopIndex
		self.isAcceptActionReady = false
		self.acceptDownStartTimer = nil
	end
	if Platform.allowSavegameMigration then
		g_inputBinding:registerActionEvent(InputAction.MENU_ACTIVATE, self, self.onActivatePressed, false, false, true, true)
		g_inputBinding:registerActionEvent(InputAction.MENU_ACTIVATE, self, self.onActivateUp, true, false, false, true)
		self.openUpdateLoopIndex = g_updateLoopIndex
		self.isActivateActionReady = false
		self.activateDownStartTimer = nil
	end
	if Platform.supportsSavegameDebugDownload and g_isDevelopmentVersion then
		addConsoleCommand("gsSavegameDownload", "Downloads given savegame", "downloadDebugSavegame", self)
	end
	if Platform.hasMainScreenLanguageSelection then
		self.changeLanguageButton:setVisible(true)
		self.buttonBox:invalidateLayout()
	end
	local canStart = g_startMissionInfo.canStart
	if canStart then
		self:startCurrentSavegame(true)
	else
		g_messageCenter:subscribe(MessageType.SAVEGAMES_LOADED, self.onSavegamesLoaded, self)
		self.selectedIndexToRestore = 0
		self.ignoreCorruptOnNextUpdate = false
		flushPhysicsCaches()
		if self.recreateListOnOpen then
			g_savegameController:resetStorageDeviceSelection()
			self:recreateSavegameList()
		end
		self:updateButtons()
	end
	self:updateTheme()
	self.savegameList:reloadData()
	FocusManager:setFocus(self.savegameList)
end
function CareerScreen:onClose()
	g_messageCenter:unsubscribe(MessageType.SAVEGAMES_LOADED, self)
	g_messageCenter:unsubscribe(MessageType.INSETS_CHANGED, self)
	g_inputBinding:removeActionEventsByTarget(self)
	removeConsoleCommand("gsSavegameUploadSelected")
	removeConsoleCommand("gsSavegameDownload")
	CareerScreen:superClass().onClose(self)
end
function CareerScreen:updateInsets()
	local _, rightInset, _, _ = getSafeFrameInsets()
	self.contentBox:setSize(1 - rightInset, 1)
	self.contentBox:updateAbsolutePosition()
	self.savegameList:updateView()
end
function CareerScreen:update(dt)
	CareerScreen:superClass().update(self, dt)
	if g_dedicatedServer ~= nil then
		self.selectedIndex = g_dedicatedServer.savegame
		local savegame = g_savegameController:getSavegame(self.selectedIndex)
		self:startSavegame(savegame)
	elseif Profiler.IS_INITIALIZED then
		local savegameNumber = Profiler.SAVEGAME_NUMBER
		local savegame = g_savegameController:getSavegame(savegameNumber)
		if not savegame.isValid or savegame.mapId ~= Profiler.MAP then
			g_savegameController:deleteSavegame(savegameNumber)
			savegame = g_savegameController:getSavegame(savegameNumber)
		end
		if savegame == SavegameController.NO_SAVEGAME then
			g_startMissionInfo.createGame = true
		end
		self:startSavegame(savegame)
	else
		if 0 <= self.savegameUpdateTimer and (not g_savegameController:getIsWaitingForSavegameInfo() and not g_gui:getIsDialogVisible()) then
			self.savegameUpdateTimer = self.savegameUpdateTimer - dt
			if self.savegameUpdateTimer <= 0 then
				self.savegameUpdateTimer = -1
				self:recreateSavegameList()
			end
		end
		if 0 <= self.savegameRefreshTimer and not g_savegameController:getIsWaitingForSavegameInfo() then
			self.savegameRefreshTimer = self.savegameRefreshTimer - dt
			if self.savegameRefreshTimer <= 0 then
				self.savegameRefreshTimer = CareerScreen.SAVEGAME_REFRESH_TIME
				g_savegameController:loadSavegames()
			end
		end
		if not MessageDialog.getIsOpen() and (not g_savegameController:getIsWaitingForSavegameInfo() and g_savegameController:isStorageDeviceUnavailable()) then
			YesNoDialog.show(self.onYesNoSavegameSelectDevice, self, g_i18n:getText("ui_savegamesScanSelectDevice"))
		end
		if self.isMultiplayer then
			Platform.verifyMultiplayerAvailabilityInMenu()
		end
		if g_savegameController:getIsWaitingForSavegameInfo() then
			if self.savegameLoadingDialogDelay <= 0 then
				self.savegameLoadingDialogDelay = CareerScreen.SAVEGAME_LOADING_DIALOG_DELAY
			end
		elseif self.loadingDialog ~= nil then
			self.loadingDialog.target:close()
			self.loadingDialog = nil
		end
		if 0 < self.savegameLoadingDialogDelay then
			self.savegameLoadingDialogDelay = self.savegameLoadingDialogDelay - dt
			if self.savegameLoadingDialogDelay <= 0 then
				self.loadingDialog = g_gui:showDialog("InfoDialog")
				self.loadingDialog.target:setText(g_i18n:getText("ui_loadingSavegames"))
				self.loadingDialog.target:setButtonTexts(g_i18n:getText("button_cancel"))
				self.loadingDialog.target:setCallback(self.onCancelSavegameLoading, self)
			end
		end
		if Platform.supportsSavegameDebugUpload then
			if not self.isAcceptPressed then
				if g_updateLoopIndex - self.openUpdateLoopIndex == 2 then
					self.isAcceptActionReady = true
				elseif g_gui:getIsDialogVisible() then
					self.isAcceptActionReady = false
				end
			end
			if self.acceptDownStartTimer ~= nil then
				local duration = g_time - self.acceptDownStartTimer
				if CareerScreen.SAVEGAME_UPLOAD_TRIGGER_DURATION < duration and self:uploadDebugSavegame() then
					self.acceptDownStartTimer = nil
				end
			end
			self.isAcceptPressed = false
		end
		if Platform.allowSavegameMigration then
			if not self.isActivatePressed then
				if g_updateLoopIndex - self.openUpdateLoopIndex == 2 then
					self.isActivateActionReady = true
				elseif g_gui:getIsDialogVisible() then
					self.isActivateActionReady = false
				end
			end
			if self.activateDownStartTimer ~= nil then
				local duration = g_time - self.activateDownStartTimer
				if CareerScreen.SAVEGAME_UPLOAD_TRIGGER_DURATION < duration and self:migrateSavegame() then
					self.activateDownStartTimer = nil
				end
			end
			self.isActivatetPressed = false
		end
	end
end
function CareerScreen:onSavegamesLoaded()
	self.savegameRefreshTimer = CareerScreen.SAVEGAME_REFRESH_TIME
	self:setSoundSuppressed(true)
	self.savegameList:reloadData()
	self:setSoundSuppressed(false)
	self:calculateTotalPlaytime()
	self:updateButtons()
end
function CareerScreen:onPressed(element, pressDuration)
	if Platform.supportsSavegameDebugUpload then
		if CareerScreen.SAVEGAME_UPLOAD_TRIGGER_DURATION < pressDuration then
			self.savegameList:resetInput()
			if self:uploadDebugSavegame() then
				self.ignoreNextClick = true
			end
		end
		if not self.isAcceptPressed then
			if g_updateLoopIndex - self.openUpdateLoopIndex == 2 then
				self.isAcceptActionReady = true
			elseif g_gui:getIsDialogVisible() then
				self.isAcceptActionReady = false
			end
		end
		if self.acceptDownStartTimer ~= nil then
			local duration = g_time - self.acceptDownStartTimer
			if CareerScreen.SAVEGAME_UPLOAD_TRIGGER_DURATION < duration and self:uploadDebugSavegame() then
				self.acceptDownStartTimer = nil
			end
		end
		self.isAcceptPressed = false
	end
	if Platform.allowSavegameMigration then
		if not self.isActivatePressed then
			if g_updateLoopIndex - self.openUpdateLoopIndex == 2 then
				self.isActivateActionReady = true
			elseif g_gui:getIsDialogVisible() then
				self.isActivateActionReady = false
			end
		end
		if self.activateDownStartTimer ~= nil then
			local duration = g_time - self.activateDownStartTimer
			if CareerScreen.SAVEGAME_UPLOAD_TRIGGER_DURATION < duration and self:uploadDebugSavegame() then
				self.activateDownStartTimer = nil
			end
		end
		self.isActivatePressed = false
	end
end
function CareerScreen:onAcceptUp()
	if not self.isAcceptActionReady then
		self.isAcceptActionReady = true
	elseif self.acceptDownStartTimer ~= nil then
		self.acceptDownStartTimer = nil
		self:onStartAction()
	end
end
function CareerScreen:onAcceptPressed()
	self.isAcceptPressed = true
	if not self.isAcceptActionReady then
		return
	else
		if self.acceptDownStartTimer == nil then
			self.acceptDownStartTimer = g_time
		end
	end
end
function CareerScreen:onActivateUp()
	if not self.isActivateActionReady then
		self.isActivateActionReady = true
	elseif self.activateDownStartTimer ~= nil then
		return
	end
end
function CareerScreen:onActivatePressed()
	self.isActivatePressed = true
	if not self.isActivateActionReady then
		return
	else
		if self.activateDownStartTimer == nil then
			self.activateDownStartTimer = g_time
		end
	end
end
function CareerScreen:onStartAction(isMouseClick)
	if self.ignoreNextClick then
		self.ignoreNextClick = false
		return
	end
	self.savegameList:resetInput()
	g_savegameController:tryToResolveConflict(self.savegameList.selectedIndex, { target = self, callback = self.onStartAction, extraAttributes = { isMouseClick } }, { target = self, callback = self.recreateSavegameList, extraAttributes = {} })
	self.savegameList:resetInput()
	local savegame = g_savegameController:getSavegame(self.savegameList.selectedIndex)
	if not Platform.allowCrossPlatformSavegames and not savegame.isCrossPlatformSavegame then
		InfoDialog.show(g_i18n:getText("ui_savegameDisabledCrossPlatform"))
		return
	end
	if g_savegameController:getCanStartGame(self.savegameList.selectedIndex) then
		self:startSavegame(savegame)
	else
		if savegame ~= nil then
			self:checkMissingMods(savegame)
		end
	end
end
function CareerScreen:onDeleteAction(sender)
	self.savegameList:resetInput()
	local currentIndex = self.savegameList.selectedIndex
	if g_savegameController:getIsSavegameConflicted(currentIndex) then
		g_savegameController:tryToResolveConflict(currentIndex, { target = self, callback = self.recreateSavegameList, extraAttributes = {} }, nil, false)
	else
		if g_savegameController:getCanDeleteGame(currentIndex) then
			self.currentSavegame = g_savegameController:getSavegame(currentIndex)
			if GS_PLATFORM_PHONE then
				YesNoDialog.show(self.onYesNoDeleteSavegame, self, g_i18n:getText("ui_youWantToDeleteSavegameMobile"))
				return
			end
			YesNoDialog.show(self.onYesNoDeleteSavegame, self, g_i18n:getText("ui_youWantToDeleteSavegame"))
		end
	end
end
function CareerScreen:onSaveGameUpdateComplete(errorCode)
	self.savegameRefreshTimer = CareerScreen.SAVEGAME_REFRESH_TIME
	self.savegameUpdateTimer = CareerScreen.SAVEGAME_UPDATE_TIME
	local ignoreCorruptOnNextUpdate = self.ignoreCorruptOnNextUpdate
	self.ignoreCorruptOnNextUpdate = false
	if errorCode == Savegame.ERROR_OK or errorCode == Savegame.ERROR_DATA_CORRUPT then
		g_savegameController:loadSavegames()
		if errorCode == Savegame.ERROR_DATA_CORRUPT and (not ignoreCorruptOnNextUpdate and (g_gui:getIsGuiVisible() and g_gui.currentGuiName == "CareerScreen")) then
			YesNoDialog.show(self.onYesNoSavegameCorrupted, self, g_i18n:getText("ui_someSavegamesCorrupt"), nil, g_i18n:getText("button_continue"), g_i18n:getText("button_cancel"))
		end
	else
		if errorCode == Savegame.ERROR_SCAN_IN_PROGRESS then
			self.savegameUpdateTimer = 0
		elseif errorCode == Savegame.ERROR_SCAN_FAILED then
			if g_gui:getIsGuiVisible() and g_gui.currentGuiName == "CareerScreen" then
				InfoDialog.show(g_i18n:getText("ui_savegamesScanFailed"), self.onOkSavegameScanFailed, self)
			end
		elseif errorCode == Savegame.ERROR_DEVICE_UNAVAILABLE then
			if g_gui:getIsGuiVisible() and g_gui.currentGuiName == "CareerScreen" then
				InfoDialog.show(g_i18n:getText("ui_savegamesScanNoDevice"), self.onOkSavegameScanFailed, self)
			end
		elseif g_gui:getIsGuiVisible() then
			if g_gui.currentGuiName == "CareerScreen" then
				self:changeScreen(MainScreen)
			end
		end
	end
	if 0 < self.savegameUpdateTimer then
		self.savegameLoadingDialogDelay = -1
		if self.loadingDialog ~= nil then
			self.loadingDialog.target:close()
			self.loadingDialog = nil
		end
	end
end
function CareerScreen:calculateTotalPlaytime()
	local totalMinutes = 0
	for i = 1, SavegameController.NUM_SAVEGAMES do
		local savegame = g_savegameController:getSavegame(i)
		if savegame.isValid then
			totalMinutes = totalMinutes + savegame.playTime
		end
	end
	if g_gameSettings:getValue(GameSettings.SETTING.TOTAL_PLAYED_SECONDS) < 0 then
		g_gameSettings:setValue(GameSettings.SETTING.TOTAL_PLAYED_SECONDS, math.floor(totalMinutes * 60), true)
	end
end
function CareerScreen:onYesNoSavegameCorrupted(yes)
	if yes then
		self.recreateListOnOpen = false
		self:changeScreen(CareerScreen, MainScreen)
		self.recreateListOnOpen = true
	else
		self:changeScreen(MainScreen)
	end
end
function CareerScreen:onOkSavegameScanFailed()
	self:changeScreen(MainScreen)
end
function CareerScreen:onSaveComplete(errorCode)
	if errorCode == Savegame.ERROR_OK then
		self:updateSavegameText(self.currentSavegame.savegameIndex)
	end
end
function CareerScreen:onCancelSavegameLoading()
	g_savegameController:cancelSavegameUpdate()
end
function CareerScreen:recreateSavegameList()
	if not g_savegameController:getIsWaitingForSavegameInfo() then
		self.savegameUpdateTimer = -1
		self.savegameRefreshTimer = -1
		self.savegameLoadingDialogDelay = CareerScreen.SAVEGAME_LOADING_DIALOG_DELAY
		g_savegameController:updateSavegames(self.onSaveGameUpdateComplete, self)
	else
		if 0 < self.savegameUpdateTimer then
			self.savegameUpdateTimer = 0
		end
	end
end
function CareerScreen:onYesNoDeleteSavegame(yes)
	if yes then
		self:deleteCurrentSavegame()
	else
		self.recreateListOnOpen = false
		self:changeScreen(CareerScreen, MainScreen)
		self.recreateListOnOpen = true
	end
end
function CareerScreen:updateButtons()
	if not g_gui.currentlyReloading then
		local canDeleteGame = g_savegameController:getCanDeleteGame(self.savegameList.selectedIndex)
		if self.buttonDelete then
			self.buttonDelete:setDisabled(not canDeleteGame)
		end
		if self.buttonDeleteMobile then
			self.buttonDeleteMobile:setDisabled(not canDeleteGame)
		end
	end
end
function CareerScreen:onYesNoSavegameSelectDevice(yes)
	if yes then
		self:changeScreen(CareerScreen)
	else
		self:changeScreen(MainScreen)
	end
end
function CareerScreen:startSavegame(savegame)
	self.savegameList:resetInput()
	self.currentSavegame = savegame
	if not savegame.isValid then
		if savegame.isInvalidUser then
			YesNoDialog.show(self.onYesNoSavegameInvalidUser, self, g_i18n:getText("ui_savegameInvalidUser"), nil, g_i18n:getText("button_continue"), g_i18n:getText("button_cancel"))
		elseif savegame.isCorruptFile then
			YesNoDialog.show(self.onYesNoSavegameInvalidUser, self, g_i18n:getText("ui_savegameCorrupt"), nil, g_i18n:getText("button_continue"), g_i18n:getText("button_cancel"))
		else
			self:onYesNoSavegameInvalidUser(true)
		end
	else
		if savegame.map and (not savegame.map.isMultiplayerSupported and self.isMultiplayer) then
			InfoDialog.show(string.format(g_i18n:getText("ui_modsZipOnly"), savegame.map.title))
			return
		end
		if SlotSystem.TOTAL_NUM_GARAGE_SLOTS[GS_PLATFORM_ID] < savegame.slotUsage then
			local continue = function(yes)
				if yes then
					self:doModCheck(savegame)
				end
			end
			YesNoDialog.show(continue, nil, g_i18n:getText("ui_savegameSlotLimitReached"), nil, g_i18n:getText("button_continue"), g_i18n:getText("button_cancel"))
		else
			self:doModCheck(savegame)
		end
	end
end
function CareerScreen:doModCheck(savegame)
	if self:checkMissingMods(savegame) then
		self:startCurrentSavegame()
	end
end
function CareerScreen:checkMissingMods(savegame)
	local missingModTitles = {}
	local missingModIds = {}
	local hasRequiredMissing = false
	local hasNoMpMods = false
	local totalSize = 0
	for _, modInfo in pairs(savegame.mods) do
		local addModHubId = false
		local mod = g_modManager:getModByName(modInfo.modName)
		if mod == nil then
			if modInfo.required then
				table.insert(missingModTitles, 1, modInfo.title)
				addModHubId = true
				hasRequiredMissing = true
			else
				table.insert(missingModTitles, modInfo.title)
				addModHubId = true
			end
		elseif not mod.isMultiplayerSupported then
			if self.isMultiplayer and not hasRequiredMissing then
				if not GS_IS_CONSOLE_VERSION then
					hasNoMpMods = true
					table.insert(missingModTitles, 1, mod.title)
					addModHubId = true
				else
					table.insert(missingModTitles, mod.title)
					addModHubId = true
				end
			end
		end
		if addModHubId then
			local modId = getModIdByFilename(modInfo.modName)
			if modId == 0 then
				continue
			end
			totalSize = totalSize + getModMetaAttributeInt(modId, "filesize")
			table.insert(missingModIds, modId)
		end
	end
	if 0 < #missingModTitles and g_dedicatedServer == nil then
		local showMissingModsDialog = function()
			local numMissing = math.min(#missingModTitles, 4)
			local modsText = missingModTitles[1]
			for i = 2, numMissing do
				modsText = modsText .. ", " .. missingModTitles[i]
			end
			if hasRequiredMissing then
				InfoDialog.show(g_i18n:getText("ui_savegameHasMissingDlcs") .. "\n" .. modsText)
			elseif hasNoMpMods then
				InfoDialog.show(string.format(g_i18n:getText("ui_modsZipOnly"), missingModTitles[1]), CareerScreen.onOkZipModsOptional, self)
			else
				local text = g_i18n:getText("ui_savegameHasMissingDlcsOptional") .. "\n" .. modsText .. "\n\n" .. g_i18n:getText("ui_continueQuestion")
				local callback = self.onYesNoInstallMissingModsOptional
				local target = self
				local yesText = g_i18n:getText("button_continue")
				local noText = g_i18n:getText("button_cancel")
				YesNoDialog.show(callback, target, text, nil, yesText, noText)
			end
		end
		if 0 < #missingModIds then
			local text = g_i18n:getText("ui_savegameInstallMissingModsFromModHub")
			local yesText = g_i18n:getText("button_modHubDownload")
			local noText = g_i18n:getText("button_cancel")
			local callback = function(yes)
				if yes then
					local freeSpaceKb = g_modHubController:getFreeModSpaceKb()
					totalSize = math.floor((totalSize + 1023) / 1024)
					if freeSpaceKb < totalSize then
						InfoDialog.show(string.format(g_i18n:getText("modHub_installNoFreeSpace"), totalSize, freeSpaceKb))
						return
					end
					local function checkModHubDownload()
						if not PlatformPrivilegeUtil.checkModDownload(checkModHubDownload, nil) then
							return
						else
							local finishCallback = function(numFailed)
								g_masterServerConnection:disconnectFromMasterServer()
								g_connectionManager:shutdownAll()
								g_modHubScreen:openDownloads()
								if 0 < numFailed then
									InfoDialog.show(g_i18n:getText("modHub_installFailed"))
								end
							end
							g_modHubController:installOrUpdateMods(missingModIds, finishCallback)
						end
					end
					if not PlatformPrivilegeUtil.checkModDownload(checkModHubDownload, nil) then
						return
					else
						local finishCallback = function(numFailed)
							g_masterServerConnection:disconnectFromMasterServer()
							g_connectionManager:shutdownAll()
							g_modHubScreen:openDownloads()
							if 0 < numFailed then
								InfoDialog.show(g_i18n:getText("modHub_installFailed"))
							end
						end
						g_modHubController:installOrUpdateMods(missingModIds, finishCallback)
						return
					end
				end
				showMissingModsDialog()
			end
			YesNoDialog.show(callback, nil, text, nil, yesText, noText)
			return false
		else
			showMissingModsDialog()
			return false
		end
	end
	return true
end
function CareerScreen:onYesNoNotEnoughSpaceForNewSaveGame(yes)
	g_startMissionInfo.createGame = yes
	if yes then
		self:changeScreen(NewGameScreen, CareerScreen)
	else
		self:changeScreen(CareerScreen)
	end
end
function CareerScreen:onYesNoSavegameInvalidUser(yes)
	if yes then
		if saveGetHasSpaceForSaveGame(self.currentSavegame.savegameIndex, FSCareerMissionInfo.MaxSavegameSize) then
			self:onYesNoNotEnoughSpaceForNewSaveGame(true)
		else
			YesNoDialog.show(self.onYesNoNotEnoughSpaceForNewSaveGame, self, g_i18n:getText("ui_notEnoughSpaceForNewSavegame"), nil, g_i18n:getText("button_continue"), g_i18n:getText("button_cancel"))
		end
	else
		self.recreateListOnOpen = false
		self:changeScreen(CareerScreen)
		self.recreateListOnOpen = true
	end
end
function CareerScreen:onYesNoInstallMissingModsOptional(yes)
	if yes then
		self:startCurrentSavegame()
	else
		self.recreateListOnOpen = false
		self:changeScreen(CareerScreen)
		self.recreateListOnOpen = true
	end
end
function CareerScreen:onOkZipModsOptional()
	self:startCurrentSavegame()
end
function CareerScreen:startCurrentSavegame(useStartMissionInfo)
	local savegame = self.currentSavegame
	if useStartMissionInfo then
		savegame:applyStartInfo(g_startMissionInfo)
	end
	savegame.isNewSPCareer = false
	if not savegame.isValid then
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
		savegame.isNewSPCareer = true
	end
	local missionDynamicInfo = {}
	missionDynamicInfo.isMultiplayer = self.isMultiplayer
	missionDynamicInfo.autoSave = false
	self.buttonStart:setClickSound(GuiSoundPlayer.SOUND_SAMPLES.START)
	if savegame.map == nil then
		if g_dedicatedServer ~= nil then
			Logging.error("Map used in savegame is not available anymore or was uninstalled!")
			doExit()
		end
	elseif savegame.map.prohibitOtherMods then
		local mapModName = g_mapManager:getModNameFromMapId(savegame.mapId)
		local mapMod = g_modManager:getModByName(mapModName)
		missionDynamicInfo.mods = { mapMod }
		self:startGame(savegame, missionDynamicInfo)
	elseif not self.isMultiplayer or not g_modManager:getHasSelectableValidMod() then
		if not self.isMultiplayer and g_modManager:getHasSelectableMod() then
			g_modSelectionScreen:setMissionInfo(savegame, missionDynamicInfo)
			g_startMissionInfo.canStart = false
			self.buttonStart:setClickSound(GuiSoundPlayer.SOUND_SAMPLES.CLICK)
			self:changeScreen(ModSelectionScreen, savegame.isValid and CareerScreen or NewGameScreen)
			return
		end
		missionDynamicInfo.mods = {}
		self:startGame(savegame, missionDynamicInfo)
	end
end
function CareerScreen:startGame(missionInfo, missionDynamicInfo, returnScreenClass)
	if self.isMultiplayer then
		g_startMissionInfo.createGame = true
		g_createGameScreen:setMissionInfo(missionInfo, missionDynamicInfo)
		g_gui:changeScreen(nil, CreateGameScreen, returnScreenClass or CareerScreen)
	else
		g_mpLoadingScreen:setMissionInfo(missionInfo, missionDynamicInfo)
		g_gui:changeScreen(nil, MPLoadingScreen, CareerScreen)
		g_mpLoadingScreen:loadSavegameAndStart()
		g_startMissionInfo:reset()
	end
end
function CareerScreen:onSavegameDeleted(errorCode)
	self.recreateListOnOpen = false
	self:changeScreen(CareerScreen)
	self.recreateListOnOpen = true
	MessageDialog.hide()
	self.selectedIndexToRestore = self.currentSavegame.savegameIndex
	self.currentSavegame = nil
	self.ignoreCorruptOnNextUpdate = not g_savegameController:isStorageDeviceUnavailable()
	self:recreateSavegameList()
end
function CareerScreen:deleteCurrentSavegame()
	local text = g_i18n:getText("ui_deletingSavegame")
	local dialogType = DialogElement.TYPE_LOADING
	MessageDialog.show(text, nil, nil, dialogType, false)
	g_savegameController:deleteSavegame(self.savegameList.selectedIndex, self.onSavegameDeleted, self)
end
function CareerScreen:setSelectedSavegameIndex(savegameIndex)
	self.savegameList:setSelectedIndex(savegameIndex, true)
end
function CareerScreen:setIsMultiplayer(isMultiplayer)
	self.isMultiplayer = isMultiplayer
	if self.isMultiplayer then
		self:setReturnScreenClass(MultiplayerScreen)
	else
		self:setReturnScreenClass(MainScreen)
	end
end
function CareerScreen:updateTheme()
	local filename = Platform.gameLogos[g_languageShort]
	if filename == nil then
		filename = Platform.gameLogos.en
	end
	if self.logo ~= nil then
		self.logo:setImageFilename(filename)
	end
end
function CareerScreen:resizeButtonTexts()
	self.buttonBackMobile:setInputMode(false, true, false)
	self.buttonDeleteMobile:setInputMode(false, true, false)
	self.buttonStartMobile:setInputMode(false, true, false)
	local totalButtonWidth = self.buttonBackMobile.absSize[1] + self.buttonDeleteMobile.absSize[1] + self.buttonStartMobile.absSize[1] + self.buttonsMobile.elementSpacing * 2
	while self.buttonsMobile.absSize[1] < totalButtonWidth do
		self.buttonBackMobile:setTextSize(self.buttonBackMobile.textSize - g_pixelSizeY)
		self.buttonDeleteMobile:setTextSize(self.buttonDeleteMobile.textSize - g_pixelSizeY)
		self.buttonStartMobile:setTextSize(self.buttonStartMobile.textSize - g_pixelSizeY)
		totalButtonWidth = self.buttonBackMobile.absSize[1] + self.buttonDeleteMobile.absSize[1] + self.buttonStartMobile.absSize[1] + self.buttonsMobile.elementSpacing * 2
	end
end
function CareerScreen:getNumberOfItemsInSection(list, section)
	return g_savegameController:getMaxNumberOfSavegames()
end
function CareerScreen:populateCellForItemInSection(list, section, index, cell)
	local titleText = tostring(index) .. " - "
	local savegame = g_savegameController:getSavegame(index)
	cell:getAttribute("gameIcon"):setVisible(savegame.isValid)
	if savegame.isValid then
		cell:getAttribute("gameIconBg"):applyProfile("fs25_savegameListItemBg", nil, true)
	else
		cell:getAttribute("gameIconBg"):applyProfile("fs25_savegameListItemBgEmpty", nil, true)
	end
	cell:getAttribute("title"):setVisible(not Platform.isMobile)
	cell:getAttribute("dataBox"):setVisible(savegame.isValid)
	cell:getAttribute("infoText"):setVisible(not savegame.isValid)
	if savegame.isValid then
		local playTimeHoursF = savegame.playTime / 60 + 0.0001
		local playTimeHours = math.floor(playTimeHoursF)
		local playTimeMinutes = math.floor((playTimeHoursF - playTimeHours) * 60)
		titleText = titleText .. savegame.savegameName
		if savegame.map ~= nil then
			cell:getAttribute("mapName"):setText(savegame.map.title)
			cell:getAttribute("gameIcon"):setImageFilename(savegame.map.iconFilename)
		else
			cell:getAttribute("mapName"):setText(Utils.getNoNil(savegame.mapTitle, savegame.mapId))
			cell:getAttribute("gameIcon"):setImageFilename(CareerScreen.MISSING_MAP_ICON_PATH)
		end
		cell:getAttribute("money"):setText(g_i18n:formatMoney(savegame.money or 0, 0, not GS_IS_MOBILE_VERSION))
		cell:getAttribute("timePlayed"):setText(string.format("%02d:%02d", playTimeHours, playTimeMinutes))
		cell:getAttribute("difficulty"):setText(self.economicDifficultyTexts[savegame.economicDifficulty])
		cell:getAttribute("createDate"):setText(savegame.saveDateFormatted)
		if Platform.isMobile then
			local stateText = ""
			if GS_PLATFORM_PHONE then
				stateText = g_i18n:getText(savegame:getStateI18NKey())
			end
			cell:getAttribute("statusIcon"):setVisible(GS_PLATFORM_PHONE)
			cell:getAttribute("status"):setText(stateText)
			cell:getAttribute("status"):setVisible(GS_PLATFORM_PHONE)
		end
	elseif savegame.isInvalidUser then
		cell:getAttribute("infoText"):setLocaKey("ui_savegameBelongsToAnotherUser")
	elseif savegame.isCorruptFile then
		cell:getAttribute("infoText"):setLocaKey("ui_savegameIsCorrupted")
	elseif Platform.isMobile then
		cell:getAttribute("infoText"):setLocaKey("ui_newGame")
	else
		titleText = titleText .. g_i18n:getText("ui_savegameEmptySlot")
	end
	cell:getAttribute("title"):setText(titleText)
end
function CareerScreen:getCellTypeForItemInSection(list, section, index)
	if Platform.isMobile then
		return CareerScreen.CELL_NAME_MOBILE
	else
		return CareerScreen.CELL_NAME_DEFAULT
	end
end
function CareerScreen:onListSelectionChanged(list, section, index)
	self:updateButtons()
end
function CareerScreen:migrateSavegame()
	local savegame = g_savegameController:getSavegame(self.savegameList.selectedIndex)
	if savegame ~= nil and savegame.isValid then
		local callback = function(ok)
			if ok then
				local progressCallback = function(_, errorCode, progress)
					if errorCode == SavegameController.UPLOAD_STATE_PROGRESS then
						local savegameUploadProgressDialog = SavegameMigrationProgressDialog.INSTANCE
						savegameUploadProgressDialog:setProgress(progress * 100)
						return
					end
					SavegameMigrationProgressDialog.hide()
					if errorCode == SavegameController.UPLOAD_STATE_OK then
						InfoDialog.show(g_i18n:getText("savegameMigration_done"))
					elseif errorCode == SavegameController.UPLOAD_STATE_BAD_INDEX then
						InfoDialog.show(g_i18n:getText("savegameMigration_invalidSavegameIndex"))
					elseif errorCode == SavegameController.UPLOAD_STATE_LOAD_FAILED then
						InfoDialog.show(g_i18n:getText("savegameMigration_loadFailed"))
					else
						InfoDialog.show(g_i18n:getText("savegameMigration_unknownError"))
						Logging.error("Savegame Migration failed with error code %d and progress %d%%", errorCode, progress or 0)
					end
				end
				SavegameMigrationProgressDialog.show(0)
				local success = saveStartMigrateToPlayfab("progressCallback", nil)
				if not success then
					SavegameMigrationProgressDialog.hide()
					InfoDialog.show(g_i18n:getText("savegameMigration_unknownError"))
				end
			end
		end
		SavegameMigrationDialog.show(callback)
		return true
	end
	return false
end
function CareerScreen:uploadDebugSavegame()
	local savegame = g_savegameController:getSavegame(self.savegameList.selectedIndex)
	if savegame ~= nil and savegame.isValid then
		local callback = function(uploadKey, ok)
			if ok then
				local savegameIndex = savegame.savegameIndex
				local progressCallback = function(_, errorCode, progress)
					if errorCode == SavegameController.UPLOAD_STATE_PROGRESS then
						local savegameUploadProgressDialog = SavegameUploadProgressDialog.INSTANCE
						savegameUploadProgressDialog:setProgress(progress * 100)
						return
					end
					SavegameUploadProgressDialog.hide()
					if errorCode == SavegameController.UPLOAD_STATE_OK then
						InfoDialog.show(g_i18n:getText("savegameUpload_done"))
					elseif errorCode == SavegameController.UPLOAD_STATE_BAD_INDEX then
						InfoDialog.show(g_i18n:getText("savegameUpload_invalidSavegameIndex"))
					elseif errorCode == SavegameController.UPLOAD_STATE_LOAD_FAILED then
						InfoDialog.show(g_i18n:getText("savegameUpload_loadFailed"))
					else
						InfoDialog.show(g_i18n:getText("savegameUpload_unknownError"))
						Logging.error("Savegame Upload failed with error code %d and progress %d%%", errorCode, progress or 0)
					end
				end
				SavegameUploadProgressDialog.show(0)
				local success = g_savegameController:uploadDebugSavegame(savegameIndex, uploadKey, progressCallback, nil)
				if not success then
					SavegameUploadProgressDialog.hide()
					InfoDialog.show(g_i18n:getText("savegameUpload_unknownError"))
				end
			end
		end
		SavegameUploadDialog.show(callback)
		return true
	end
	return false
end
function CareerScreen:downloadDebugSavegame(uploadKey, savegameIndex, savegameId)
	savegameIndex = tonumber(savegameIndex)
	if savegameIndex == nil then
		Logging.error("SavegameIndex needs to be an integer")
		return false
	end
	savegameId = tonumber(savegameId)
	if savegameId == nil then
		Logging.error("SavegameId needs to be an integer")
		return false
	else
		local progressCallback = function(_, errorCode, progress)
			if errorCode == SavegameController.DOWNLOAD_STATE_PROGRESS then
				return
			elseif errorCode == SavegameController.DOWNLOAD_STATE_OK then
				InfoDialog.show(g_i18n:getText("savegameDownload_done"))
				self.savegameRefreshTimer = CareerScreen.SAVEGAME_REFRESH_TIME
				g_savegameController:loadSavegames()
			elseif errorCode == SavegameController.DOWNLOAD_STATE_NOT_FOUND then
				InfoDialog.show(g_i18n:getText("savegameDownload_savegameNotFound"))
			else
				InfoDialog.show(g_i18n:getText("savegameDownload_unknownError"))
				Logging.error("Savegame download failed with error code %d and progress %d%%", errorCode, progress or 0)
			end
		end
		g_savegameController:downloadDebugSavegame(uploadKey, savegameIndex, savegameId, progressCallback, nil)
		return true
	end
end
