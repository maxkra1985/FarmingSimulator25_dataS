-- Local values: CareerScreen_mt
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
	local v2_ = CareerScreen.new()
	g_gui:loadGui("dataS/gui/CareerScreen.xml", "CareerScreen", v2_)
	return v2_
end

-- Upvalues: CareerScreen_mt
-- Local values: self
function CareerScreen.new(target, custom_mt)
	-- upvalues: (copy) CareerScreen_mt
	local v5_ = ScreenElement.new(target, custom_mt or CareerScreen_mt)
	v5_.isMultiplayer = false
	v5_.mapNameTexts = {}
	v5_.playerNameTexts = {}
	v5_.playerCharacterTexts = {}
	v5_.savegameNameTexts = {}
	v5_.moneyTexts = {}
	v5_.timePlayedTexts = {}
	v5_.difficultyTexts = {}
	v5_.dateTexts = {}
	v5_.statusTexts = {}
	v5_.statusIcons = {}
	v5_.listItemData = {}
	v5_.listItemTexts = {}
	v5_.listItemInfoText = {}
	v5_.economicDifficultyTexts = { g_i18n:getText("button_easy"), g_i18n:getText("button_normal"), g_i18n:getText("button_hard") }
	v5_.savegames = {}
	v5_.tempIsSliderScrolling = false
	v5_.ignoreCorruptOnNextUpdate = false
	v5_.gameIcons = {}
	v5_.currentIndex = 0
	v5_.totalPlayedHours = 0
	v5_.selectedIndexToRestore = 0
	v5_.recreateListOnOpen = true
	v5_.savegameUpdateTimer = CareerScreen.SAVEGAME_UPDATE_TIME
	v5_.savegameRefreshTimer = CareerScreen.SAVEGAME_REFRESH_TIME
	v5_.savegameLoadingDialogDelay = -1
	return v5_
end

-- Local values: newGui
function CareerScreen.createFromExistingGui(gui, guiName)
	local v8_ = CareerScreen.new()
	g_gui.guis[guiName]:delete()
	g_gui.guis[guiName].target:delete()
	g_gui:loadGui(gui.xmlFilename, guiName, v8_)
	return v8_
end

-- Local values: canStart
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
	if g_startMissionInfo.canStart then
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

-- Local values: _, rightInset, _, _
function CareerScreen:updateInsets()
	local _, v12_, _, _ = getSafeFrameInsets()
	self.contentBox:setSize(1 - v12_, 1)
	self.contentBox:updateAbsolutePosition()
	self.savegameList:updateView()
end

-- Local values: savegame, savegameNumber, savegame, duration, duration
function CareerScreen:update(dt)
	CareerScreen:superClass().update(self, dt)
	if g_dedicatedServer == nil then
		if Profiler.IS_INITIALIZED then
			local v15_ = Profiler.SAVEGAME_NUMBER
			local v16_ = g_savegameController:getSavegame(v15_)
			if not v16_.isValid or v16_.mapId ~= Profiler.MAP then
				g_savegameController:deleteSavegame(v15_)
				v16_ = g_savegameController:getSavegame(v15_)
			end
			if v16_ == SavegameController.NO_SAVEGAME then
				g_startMissionInfo.createGame = true
			end
			self:startSavegame(v16_)
		else
			if self.savegameUpdateTimer >= 0 and not (g_savegameController:getIsWaitingForSavegameInfo() or g_gui:getIsDialogVisible()) then
				self.savegameUpdateTimer = self.savegameUpdateTimer - dt
				if self.savegameUpdateTimer <= 0 then
					self.savegameUpdateTimer = -1
					self:recreateSavegameList()
				end
			end
			if self.savegameRefreshTimer >= 0 and not g_savegameController:getIsWaitingForSavegameInfo() then
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
			if self.savegameLoadingDialogDelay > 0 then
				self.savegameLoadingDialogDelay = self.savegameLoadingDialogDelay - dt
				if self.savegameLoadingDialogDelay <= 0 then
					self.loadingDialog = g_gui:showDialog("InfoDialog")
					self.loadingDialog.target:setText(g_i18n:getText("ui_loadingSavegames"))
					self.loadingDialog.target:setButtonTexts(g_i18n:getText("button_cancel"))
					self.loadingDialog.target:setCallback(self.onCancelSavegameLoading, self)
				end
			end
			if Platform.supportsSavegameDebugUpload then
				if self.isAcceptPressed or g_updateLoopIndex - self.openUpdateLoopIndex ~= 2 then
					if g_gui:getIsDialogVisible() then
						self.isAcceptActionReady = false
					end
				else
					self.isAcceptActionReady = true
				end
				if self.acceptDownStartTimer ~= nil and (g_time - self.acceptDownStartTimer > CareerScreen.SAVEGAME_UPLOAD_TRIGGER_DURATION and self:uploadDebugSavegame()) then
					self.acceptDownStartTimer = nil
				end
				self.isAcceptPressed = false
			end
			if Platform.allowSavegameMigration then
				if self.isActivatePressed or g_updateLoopIndex - self.openUpdateLoopIndex ~= 2 then
					if g_gui:getIsDialogVisible() then
						self.isActivateActionReady = false
					end
				else
					self.isActivateActionReady = true
				end
				if self.activateDownStartTimer ~= nil and (g_time - self.activateDownStartTimer > CareerScreen.SAVEGAME_UPLOAD_TRIGGER_DURATION and self:migrateSavegame()) then
					self.activateDownStartTimer = nil
				end
				self.isActivatetPressed = false
			end
		end
	else
		self.selectedIndex = g_dedicatedServer.savegame
		self:startSavegame((g_savegameController:getSavegame(self.selectedIndex)))
		return
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

-- Local values: duration, duration
function CareerScreen:onPressed(element, pressDuration)
	if Platform.supportsSavegameDebugUpload then
		if CareerScreen.SAVEGAME_UPLOAD_TRIGGER_DURATION < pressDuration then
			self.savegameList:resetInput()
			if self:uploadDebugSavegame() then
				self.ignoreNextClick = true
			end
		end
		if self.isAcceptPressed or g_updateLoopIndex - self.openUpdateLoopIndex ~= 2 then
			if g_gui:getIsDialogVisible() then
				self.isAcceptActionReady = false
			end
		else
			self.isAcceptActionReady = true
		end
		if self.acceptDownStartTimer ~= nil and (g_time - self.acceptDownStartTimer > CareerScreen.SAVEGAME_UPLOAD_TRIGGER_DURATION and self:uploadDebugSavegame()) then
			self.acceptDownStartTimer = nil
		end
		self.isAcceptPressed = false
	end
	if Platform.allowSavegameMigration then
		if self.isActivatePressed or g_updateLoopIndex - self.openUpdateLoopIndex ~= 2 then
			if g_gui:getIsDialogVisible() then
				self.isActivateActionReady = false
			end
		else
			self.isActivateActionReady = true
		end
		if self.activateDownStartTimer ~= nil and (g_time - self.activateDownStartTimer > CareerScreen.SAVEGAME_UPLOAD_TRIGGER_DURATION and self:uploadDebugSavegame()) then
			self.activateDownStartTimer = nil
		end
		self.isActivatePressed = false
	end
end

function CareerScreen:onAcceptUp()
	if self.isAcceptActionReady then
		if self.acceptDownStartTimer ~= nil then
			self.acceptDownStartTimer = nil
			self:onStartAction()
		end
	else
		self.isAcceptActionReady = true
		return
	end
end

function CareerScreen:onAcceptPressed()
	self.isAcceptPressed = true
	if self.isAcceptActionReady then
		if self.acceptDownStartTimer == nil then
			self.acceptDownStartTimer = g_time
		end
	end
end

function CareerScreen:onActivateUp()
	if self.isActivateActionReady then
		if self.activateDownStartTimer ~= nil then
		end
	else
		self.isActivateActionReady = true
		return
	end
end

function CareerScreen:onActivatePressed()
	self.isActivatePressed = true
	if self.isActivateActionReady then
		if self.activateDownStartTimer == nil then
			self.activateDownStartTimer = g_time
		end
	end
end

-- Local values: savegame
function CareerScreen:onStartAction(isMouseClick)
	if self.ignoreNextClick then
		self.ignoreNextClick = false
		return
	else
		self.savegameList:resetInput()
		g_savegameController:tryToResolveConflict(self.savegameList.selectedIndex, {
			["target"] = self,
			["callback"] = self.onStartAction,
			["extraAttributes"] = { isMouseClick }
		}, {
			["target"] = self,
			["callback"] = self.recreateSavegameList,
			["extraAttributes"] = {}
		})
		self.savegameList:resetInput()
		local v26_ = g_savegameController:getSavegame(self.savegameList.selectedIndex)
		if Platform.allowCrossPlatformSavegames or v26_.isCrossPlatformSavegame then
			if g_savegameController:getCanStartGame(self.savegameList.selectedIndex) then
				self:startSavegame(v26_)
			elseif v26_ ~= nil then
				self:checkMissingMods(v26_)
			end
		else
			InfoDialog.show(g_i18n:getText("ui_savegameDisabledCrossPlatform"))
			return
		end
	end
end

-- Local values: currentIndex
function CareerScreen:onDeleteAction(sender)
	self.savegameList:resetInput()
	local v28_ = self.savegameList.selectedIndex
	if g_savegameController:getIsSavegameConflicted(v28_) then
		g_savegameController:tryToResolveConflict(v28_, {
			["target"] = self,
			["callback"] = self.recreateSavegameList,
			["extraAttributes"] = {}
		}, nil, false)
	elseif g_savegameController:getCanDeleteGame(v28_) then
		self.currentSavegame = g_savegameController:getSavegame(v28_)
		if GS_PLATFORM_PHONE then
			YesNoDialog.show(self.onYesNoDeleteSavegame, self, g_i18n:getText("ui_youWantToDeleteSavegameMobile"))
			return
		end
		YesNoDialog.show(self.onYesNoDeleteSavegame, self, g_i18n:getText("ui_youWantToDeleteSavegame"))
	end
end

-- Local values: ignoreCorruptOnNextUpdate
function CareerScreen:onSaveGameUpdateComplete(errorCode)
	self.savegameRefreshTimer = CareerScreen.SAVEGAME_REFRESH_TIME
	self.savegameUpdateTimer = CareerScreen.SAVEGAME_UPDATE_TIME
	local v31_ = self.ignoreCorruptOnNextUpdate
	self.ignoreCorruptOnNextUpdate = false
	if errorCode == Savegame.ERROR_OK or errorCode == Savegame.ERROR_DATA_CORRUPT then
		g_savegameController:loadSavegames()
		if errorCode == Savegame.ERROR_DATA_CORRUPT and (not v31_ and (g_gui:getIsGuiVisible() and g_gui.currentGuiName == "CareerScreen")) then
			YesNoDialog.show(self.onYesNoSavegameCorrupted, self, g_i18n:getText("ui_someSavegamesCorrupt"), nil, g_i18n:getText("button_continue"), g_i18n:getText("button_cancel"))
		end
	elseif errorCode == Savegame.ERROR_SCAN_IN_PROGRESS then
		self.savegameUpdateTimer = 0
	elseif errorCode == Savegame.ERROR_SCAN_FAILED then
		if g_gui:getIsGuiVisible() and g_gui.currentGuiName == "CareerScreen" then
			InfoDialog.show(g_i18n:getText("ui_savegamesScanFailed"), self.onOkSavegameScanFailed, self)
		end
	elseif errorCode == Savegame.ERROR_DEVICE_UNAVAILABLE then
		if g_gui:getIsGuiVisible() and g_gui.currentGuiName == "CareerScreen" then
			InfoDialog.show(g_i18n:getText("ui_savegamesScanNoDevice"), self.onOkSavegameScanFailed, self)
		end
	elseif g_gui:getIsGuiVisible() and g_gui.currentGuiName == "CareerScreen" then
		self:changeScreen(MainScreen)
	end
	if self.savegameUpdateTimer > 0 then
		self.savegameLoadingDialogDelay = -1
		if self.loadingDialog ~= nil then
			self.loadingDialog.target:close()
			self.loadingDialog = nil
		end
	end
end

-- Local values: totalMinutes, i, savegame
function CareerScreen:calculateTotalPlaytime()
	local v32_ = 0
	for v33_ = 1, SavegameController.NUM_SAVEGAMES do
		local v34_ = g_savegameController:getSavegame(v33_)
		if v34_.isValid then
			v32_ = v32_ + v34_.playTime
		end
	end
	if g_gameSettings:getValue(GameSettings.SETTING.TOTAL_PLAYED_SECONDS) < 0 then
		local v35_ = g_gameSettings
		local v36_ = GameSettings.SETTING.TOTAL_PLAYED_SECONDS
		local v37_ = v32_ * 60
		v35_:setValue(v36_, math.floor(v37_), true)
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
	if g_savegameController:getIsWaitingForSavegameInfo() then
		if self.savegameUpdateTimer > 0 then
			self.savegameUpdateTimer = 0
		end
	else
		self.savegameUpdateTimer = -1
		self.savegameRefreshTimer = -1
		self.savegameLoadingDialogDelay = CareerScreen.SAVEGAME_LOADING_DIALOG_DELAY
		g_savegameController:updateSavegames(self.onSaveGameUpdateComplete, self)
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

-- Local values: canDeleteGame
function CareerScreen:updateButtons()
	if not g_gui.currentlyReloading then
		local v47_ = g_savegameController:getCanDeleteGame(self.savegameList.selectedIndex)
		if self.buttonDelete then
			self.buttonDelete:setDisabled(not v47_)
		end
		if self.buttonDeleteMobile then
			self.buttonDeleteMobile:setDisabled(not v47_)
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

-- Local values: continue
function CareerScreen:startSavegame(savegame)
	self.savegameList:resetInput()
	self.currentSavegame = savegame
	if savegame.isValid then
		if savegame.map and (not savegame.map.isMultiplayerSupported and self.isMultiplayer) then
			InfoDialog.show(string.format(g_i18n:getText("ui_modsZipOnly"), savegame.map.title))
			return
		elseif savegame.slotUsage > SlotSystem.TOTAL_NUM_GARAGE_SLOTS[GS_PLATFORM_ID] then
			YesNoDialog.show(function(p52_)
				-- upvalues: (copy) self, (copy) savegame
				if p52_ then
					self:doModCheck(savegame)
				end
			end, nil, g_i18n:getText("ui_savegameSlotLimitReached"), nil, g_i18n:getText("button_continue"), g_i18n:getText("button_cancel"))
		else
			self:doModCheck(savegame)
		end
	elseif savegame.isInvalidUser then
		YesNoDialog.show(self.onYesNoSavegameInvalidUser, self, g_i18n:getText("ui_savegameInvalidUser"), nil, g_i18n:getText("button_continue"), g_i18n:getText("button_cancel"))
		return
	elseif savegame.isCorruptFile then
		YesNoDialog.show(self.onYesNoSavegameInvalidUser, self, g_i18n:getText("ui_savegameCorrupt"), nil, g_i18n:getText("button_continue"), g_i18n:getText("button_cancel"))
	else
		self:onYesNoSavegameInvalidUser(true)
	end
end

function CareerScreen:doModCheck(savegame)
	if self:checkMissingMods(savegame) then
		self:startCurrentSavegame()
	end
end

-- Local values: missingModTitles, missingModIds, hasRequiredMissing, hasNoMpMods, totalSize, _, modInfo, addModHubId, mod, modId, showMissingModsDialog, text, yesText, noText, callback
function CareerScreen:checkMissingMods(savegame)
	local v_u_57_ = false
	local v_u_58_ = {}
	local v_u_59_ = 0
	local v_u_60_ = {}
	local v_u_61_ = false
	for _, v62_ in pairs(savegame.mods) do
		local v63_ = false
		local v64_ = g_modManager:getModByName(v62_.modName)
		if v64_ == nil then
			if v62_.required then
				local v65_ = v62_.title
				table.insert(v_u_58_, 1, v65_)
				v63_ = true
				v_u_57_ = true
			else
				local v66_ = v62_.title
				table.insert(v_u_58_, v66_)
				v63_ = true
			end
		elseif not v64_.isMultiplayerSupported and self.isMultiplayer then
			if v_u_57_ or GS_IS_CONSOLE_VERSION then
				local v67_ = v64_.title
				table.insert(v_u_58_, v67_)
				v63_ = true
			else
				local v68_ = v64_.title
				table.insert(v_u_58_, 1, v68_)
				v63_ = true
				v_u_61_ = true
			end
		end
		if v63_ then
			local v69_ = getModIdByFilename(v62_.modName)
			if v69_ ~= 0 then
				v_u_59_ = v_u_59_ + getModMetaAttributeInt(v69_, "filesize")
				table.insert(v_u_60_, v69_)
			end
		end
	end
	if #v_u_58_ <= 0 or g_dedicatedServer ~= nil then
		return true
	end
	local function v_u_79_()
		-- upvalues: (copy) v_u_58_, (ref) v_u_57_, (ref) v_u_61_, (copy) self
		local v70_ = #v_u_58_
		local v71_ = math.min(v70_, 4)
		local v72_ = v_u_58_[1]
		for v73_ = 2, v71_ do
			v72_ = v72_ .. ", " .. v_u_58_[v73_]
		end
		if v_u_57_ then
			InfoDialog.show(g_i18n:getText("ui_savegameHasMissingDlcs") .. "\n" .. v72_)
			return
		elseif v_u_61_ then
			InfoDialog.show(string.format(g_i18n:getText("ui_modsZipOnly"), v_u_58_[1]), CareerScreen.onOkZipModsOptional, self)
		else
			local v74_ = g_i18n:getText("ui_savegameHasMissingDlcsOptional") .. "\n" .. v72_ .. "\n\n" .. g_i18n:getText("ui_continueQuestion")
			local v75_ = self.onYesNoInstallMissingModsOptional
			local v76_ = self
			local v77_ = g_i18n:getText("button_continue")
			local v78_ = g_i18n:getText("button_cancel")
			YesNoDialog.show(v75_, v76_, v74_, nil, v77_, v78_)
		end
	end
	if #v_u_60_ <= 0 then
		v_u_79_()
		return false
	end
	local v80_ = g_i18n:getText("ui_savegameInstallMissingModsFromModHub")
	local v81_ = g_i18n:getText("button_modHubDownload")
	local v82_ = g_i18n:getText("button_cancel")
	YesNoDialog.show(function(p83_)
		-- upvalues: (ref) v_u_59_, (copy) v_u_60_, (copy) v_u_79_
		if p83_ then
			local v84_ = g_modHubController:getFreeModSpaceKb()
			local v85_ = (v_u_59_ + 1023) / 1024
			v_u_59_ = math.floor(v85_)
			if v84_ < v_u_59_ then
				InfoDialog.show(string.format(g_i18n:getText("modHub_installNoFreeSpace"), v_u_59_, v84_))
				return
			else
				local function v_u_87_()
					-- upvalues: (copy) v_u_87_, (ref) v_u_60_
					if PlatformPrivilegeUtil.checkModDownload(v_u_87_, nil) then
						g_modHubController:installOrUpdateMods(v_u_60_, function(p86_)
							g_masterServerConnection:disconnectFromMasterServer()
							g_connectionManager:shutdownAll()
							g_modHubScreen:openDownloads()
							if p86_ > 0 then
								InfoDialog.show(g_i18n:getText("modHub_installFailed"))
							end
						end)
					end
				end
				if PlatformPrivilegeUtil.checkModDownload(v_u_87_, nil) then
					g_modHubController:installOrUpdateMods(v_u_60_, function(p88_)
						g_masterServerConnection:disconnectFromMasterServer()
						g_connectionManager:shutdownAll()
						g_modHubScreen:openDownloads()
						if p88_ > 0 then
							InfoDialog.show(g_i18n:getText("modHub_installFailed"))
						end
					end)
				end
			end
		else
			v_u_79_()
			return
		end
	end, nil, v80_, nil, v81_, v82_)
	return false
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
		return
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

-- Local values: savegame, missionInfo, missionDynamicInfo, mapModName, mapMod
function CareerScreen:startCurrentSavegame(useStartMissionInfo)
	local v98_ = self.currentSavegame
	if useStartMissionInfo then
		v98_:applyStartInfo(g_startMissionInfo)
	end
	v98_.isNewSPCareer = false
	if not v98_.isValid then
		v98_.vehiclesXMLLoad = v98_.defaultVehiclesXMLFilename
		v98_.handToolsXMLLoad = v98_.defaultHandToolsXMLFilename
		v98_.itemsXMLLoad = v98_.defaultItemsXMLFilename
		v98_.placeablesXMLLoad = v98_.defaultPlaceablesXMLFilename
		v98_.onCreateObjectsXMLLoad = nil
		v98_.environmentXML = nil
		v98_.economyXMLLoad = nil
		v98_.farmlandXMLLoad = nil
		v98_.aiSystemXMLLoad = nil
		v98_.navigationSystemXMLLoad = nil
		v98_.npcXMLLoad = nil
		v98_.densityMapHeightXMLLoad = nil
		v98_.treePlantXMLLoad = nil
		v98_.isNewSPCareer = true
	end
	local v99_ = {
		["isMultiplayer"] = self.isMultiplayer,
		["autoSave"] = false
	}
	self.buttonStart:setClickSound(GuiSoundPlayer.SOUND_SAMPLES.START)
	if v98_.map == nil then
		if g_dedicatedServer ~= nil then
			Logging.error("Map used in savegame is not available anymore or was uninstalled!")
			doExit()
		end
		return
	elseif v98_.map.prohibitOtherMods then
		local v100_ = g_mapManager:getModNameFromMapId(v98_.mapId)
		v99_.mods = { (g_modManager:getModByName(v100_)) }
		self:startGame(v98_, v99_)
		return
	elseif self.isMultiplayer and g_modManager:getHasSelectableValidMod() or not self.isMultiplayer and g_modManager:getHasSelectableMod() then
		g_modSelectionScreen:setMissionInfo(v98_, v99_)
		g_startMissionInfo.canStart = false
		self.buttonStart:setClickSound(GuiSoundPlayer.SOUND_SAMPLES.CLICK)
		self:changeScreen(ModSelectionScreen, v98_.isValid and CareerScreen or NewGameScreen)
	else
		v99_.mods = {}
		self:startGame(v98_, v99_)
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

-- Local values: text, dialogType
function CareerScreen:deleteCurrentSavegame()
	local v107_ = g_i18n:getText("ui_deletingSavegame")
	local v108_ = DialogElement.TYPE_LOADING
	MessageDialog.show(v107_, nil, nil, v108_, false)
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

-- Local values: filename
function CareerScreen:updateTheme()
	local v114_ = Platform.gameLogos[g_languageShort]
	if v114_ == nil then
		v114_ = Platform.gameLogos.en
	end
	if self.logo ~= nil then
		self.logo:setImageFilename(v114_)
	end
end

-- Local values: totalButtonWidth
function CareerScreen:resizeButtonTexts()
	self.buttonBackMobile:setInputMode(false, true, false)
	self.buttonDeleteMobile:setInputMode(false, true, false)
	self.buttonStartMobile:setInputMode(false, true, false)
	local v116_ = self.buttonBackMobile.absSize[1] + self.buttonDeleteMobile.absSize[1] + self.buttonStartMobile.absSize[1] + self.buttonsMobile.elementSpacing * 2
	while self.buttonsMobile.absSize[1] < v116_ do
		self.buttonBackMobile:setTextSize(self.buttonBackMobile.textSize - g_pixelSizeY)
		self.buttonDeleteMobile:setTextSize(self.buttonDeleteMobile.textSize - g_pixelSizeY)
		self.buttonStartMobile:setTextSize(self.buttonStartMobile.textSize - g_pixelSizeY)
		v116_ = self.buttonBackMobile.absSize[1] + self.buttonDeleteMobile.absSize[1] + self.buttonStartMobile.absSize[1] + self.buttonsMobile.elementSpacing * 2
	end
end

function CareerScreen:getNumberOfItemsInSection(list, section)
	return g_savegameController:getMaxNumberOfSavegames()
end

-- Local values: titleText, savegame, playTimeHoursF, playTimeHours, playTimeMinutes, stateText
function CareerScreen:populateCellForItemInSection(list, section, index, cell)
	local v120_ = tostring(index) .. " - "
	local v121_ = g_savegameController:getSavegame(index)
	cell:getAttribute("gameIcon"):setVisible(v121_.isValid)
	if v121_.isValid then
		cell:getAttribute("gameIconBg"):applyProfile("fs25_savegameListItemBg", nil, true)
	else
		cell:getAttribute("gameIconBg"):applyProfile("fs25_savegameListItemBgEmpty", nil, true)
	end
	cell:getAttribute("title"):setVisible(not Platform.isMobile)
	cell:getAttribute("dataBox"):setVisible(v121_.isValid)
	cell:getAttribute("infoText"):setVisible(not v121_.isValid)
	if v121_.isValid then
		local v122_ = v121_.playTime / 60 + 0.0001
		local v123_ = math.floor(v122_)
		local v124_ = (v122_ - v123_) * 60
		local v125_ = math.floor(v124_)
		v120_ = v120_ .. v121_.savegameName
		if v121_.map == nil then
			cell:getAttribute("mapName"):setText(Utils.getNoNil(v121_.mapTitle, v121_.mapId))
			cell:getAttribute("gameIcon"):setImageFilename(CareerScreen.MISSING_MAP_ICON_PATH)
		else
			cell:getAttribute("mapName"):setText(v121_.map.title)
			cell:getAttribute("gameIcon"):setImageFilename(v121_.map.iconFilename)
		end
		cell:getAttribute("money"):setText(g_i18n:formatMoney(v121_.money or 0, 0, not GS_IS_MOBILE_VERSION))
		cell:getAttribute("timePlayed"):setText(string.format("%02d:%02d", v123_, v125_))
		cell:getAttribute("difficulty"):setText(self.economicDifficultyTexts[v121_.economicDifficulty])
		cell:getAttribute("createDate"):setText(v121_.saveDateFormatted)
		if Platform.isMobile then
			local v126_ = not GS_PLATFORM_PHONE and "" or g_i18n:getText(v121_:getStateI18NKey())
			cell:getAttribute("statusIcon"):setVisible(GS_PLATFORM_PHONE)
			cell:getAttribute("status"):setText(v126_)
			cell:getAttribute("status"):setVisible(GS_PLATFORM_PHONE)
		end
	elseif v121_.isInvalidUser then
		cell:getAttribute("infoText"):setLocaKey("ui_savegameBelongsToAnotherUser")
	elseif v121_.isCorruptFile then
		cell:getAttribute("infoText"):setLocaKey("ui_savegameIsCorrupted")
	elseif Platform.isMobile then
		cell:getAttribute("infoText"):setLocaKey("ui_newGame")
	else
		v120_ = v120_ .. g_i18n:getText("ui_savegameEmptySlot")
	end
	cell:getAttribute("title"):setText(v120_)
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

-- Local values: savegame, callback
function CareerScreen:migrateSavegame()
	local v129_ = g_savegameController:getSavegame(self.savegameList.selectedIndex)
	if v129_ == nil or not v129_.isValid then
		return false
	end
	SavegameMigrationDialog.show(function(p130_)
		if p130_ then
			SavegameMigrationProgressDialog.show(0)
			if not saveStartMigrateToPlayfab("progressCallback", nil) then
				SavegameMigrationProgressDialog.hide()
				InfoDialog.show(g_i18n:getText("savegameMigration_unknownError"))
			end
		end
	end)
	return true
end

-- Local values: savegame, callback
function CareerScreen:uploadDebugSavegame()
	local v_u_132_ = g_savegameController:getSavegame(self.savegameList.selectedIndex)
	if v_u_132_ == nil or not v_u_132_.isValid then
		return false
	end
	SavegameUploadDialog.show(function(p133_, p134_)
		-- upvalues: (copy) v_u_132_
		if p134_ then
			local v135_ = v_u_132_.savegameIndex
			SavegameUploadProgressDialog.show(0)
			if not g_savegameController:uploadDebugSavegame(v135_, p133_, function(_, p136_, p137_)
				if p136_ == SavegameController.UPLOAD_STATE_PROGRESS then
					SavegameUploadProgressDialog.INSTANCE:setProgress(p137_ * 100)
					return
				else
					SavegameUploadProgressDialog.hide()
					if p136_ == SavegameController.UPLOAD_STATE_OK then
						InfoDialog.show(g_i18n:getText("savegameUpload_done"))
						return
					elseif p136_ == SavegameController.UPLOAD_STATE_BAD_INDEX then
						InfoDialog.show(g_i18n:getText("savegameUpload_invalidSavegameIndex"))
						return
					elseif p136_ == SavegameController.UPLOAD_STATE_LOAD_FAILED then
						InfoDialog.show(g_i18n:getText("savegameUpload_loadFailed"))
					else
						InfoDialog.show(g_i18n:getText("savegameUpload_unknownError"))
						Logging.error("Savegame Upload failed with error code %d and progress %d%%", p136_, p137_ or 0)
					end
				end
			end, nil) then
				SavegameUploadProgressDialog.hide()
				InfoDialog.show(g_i18n:getText("savegameUpload_unknownError"))
			end
		end
	end)
	return true
end

-- Local values: progressCallback
function CareerScreen:downloadDebugSavegame(uploadKey, savegameIndex, savegameId)
	local v142_ = tonumber(savegameIndex)
	if v142_ == nil then
		Logging.error("SavegameIndex needs to be an integer")
		return false
	else
		local v143_ = tonumber(savegameId)
		if v143_ == nil then
			Logging.error("SavegameId needs to be an integer")
			return false
		else
			g_savegameController:downloadDebugSavegame(uploadKey, v142_, v143_, function(_, p144_, p145_)
				-- upvalues: (copy) self
				if p144_ == SavegameController.DOWNLOAD_STATE_PROGRESS then
					return
				elseif p144_ == SavegameController.DOWNLOAD_STATE_OK then
					InfoDialog.show(g_i18n:getText("savegameDownload_done"))
					self.savegameRefreshTimer = CareerScreen.SAVEGAME_REFRESH_TIME
					g_savegameController:loadSavegames()
					return
				elseif p144_ == SavegameController.DOWNLOAD_STATE_NOT_FOUND then
					InfoDialog.show(g_i18n:getText("savegameDownload_savegameNotFound"))
				else
					InfoDialog.show(g_i18n:getText("savegameDownload_unknownError"))
					Logging.error("Savegame download failed with error code %d and progress %d%%", p144_, p145_ or 0)
				end
			end, nil)
			return true
		end
	end
end
