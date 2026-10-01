SettingsScreen = {}
local SettingsScreen_mt = Class(SettingsScreen, TabbedMenuWithDetails)
SettingsScreen.CONTROLS = { PAGING_SETTINGS_GENERAL = "pageSettingsGeneral", PAGING_SETTINGS_DISPLAY = "pageSettingsDisplay", PAGING_SETTINGS_ADVANCED = "pageSettingsAdvanced", PAGING_SETTINGS_CONTROLS = "pageSettingsControls", PAGING_SETTINGS_CONSOLE = "pageSettingsConsole", PAGING_SETTINGS_DEVICE = "pageSettingsDevice", PAGING_SETTINGS_HDR = "pageSettingsHDR" }
function SettingsScreen.register()
	SettingsAdvancedFrame.register()
	SettingsConsoleFrame.register()
	SettingsControlsFrame.register()
	SettingsDeviceFrame.register()
	SettingsDisplayFrame.register()
	SettingsGeneralFrame.register()
	SettingsHDRFrame.register()
	local settingsScreen = SettingsScreen.new()
	g_gui:loadGui("dataS/gui/SettingsScreen.xml", "SettingsScreen", settingsScreen)
	return settingsScreen
end
function SettingsScreen.new(target, custom_mt)
	local self = TabbedMenuWithDetails.new(target, custom_mt or SettingsScreen_mt)
	return self
end
function SettingsScreen.createFromExistingGui(gui, guiName)
	SettingsAdvancedFrame.createFromExistingGui(g_gui.frames.settingsAdvanced.target, "SettingsAdvancedFrame")
	SettingsConsoleFrame.createFromExistingGui(g_gui.frames.settingsConsole.target, "SettingsConsoleFrame")
	SettingsControlsFrame.createFromExistingGui(g_gui.frames.settingsControls.target, "SettingsControlsFrame")
	SettingsDeviceFrame.createFromExistingGui(g_gui.frames.settingsDevice.target, "SettingsDeviceFrame")
	SettingsDisplayFrame.createFromExistingGui(g_gui.frames.settingsDisplay.target, "SettingsDisplayFrame")
	SettingsGeneralFrame.createFromExistingGui(g_gui.frames.settingsGeneral.target, "SettingsGeneralFrame")
	SettingsHDRFrame.createFromExistingGui(g_gui.frames.settingsHDR.target, "SettingsHDRFrame")
	local newGui = SettingsScreen.new()
	g_gui.guis[gui.name]:delete()
	g_gui.guis[gui.name].target:delete()
	g_gui:loadGui(gui.xmlFilename, guiName, newGui, false)
	return newGui
end
function SettingsScreen:onGuiSetupFinished()
	SettingsScreen:superClass().onGuiSetupFinished(self)
	self.clickBackCallback = self:makeSelfCallback(self.onButtonBack)
	self.clickNextCallback = self:makeSelfCallback(self.onPageNext)
	self.clickPrevCallback = self:makeSelfCallback(self.onPagePrevious)
	self.pageSettingsGeneral:initialize()
	self.pageSettingsDisplay:initialize()
	self.pageSettingsDisplay:setOpenAdvancedSettingsCallback(function()
		self:onClickAdvancedSettings()
	end)
	self.pageSettingsDisplay:setOpenHDRSettingsCallback(function()
		self:onClickHDRSettings()
	end)
	self.pageSettingsAdvanced:initialize()
	self.pageSettingsHDR:initialize()
	self.pageSettingsConsole:initialize()
	self.pageSettingsConsole:setOpenHDRSettingsCallback(function()
		self:onClickHDRSettings()
	end)
	self.pageSettingsDevice:initialize()
	local controlsController = ControlsController.new()
	self.pageSettingsControls:initialize(controlsController)
	self:setupPages()
	self:setupMenuButtonInfo()
end
function SettingsScreen:setupPages()
	local orderedPages = { { self.pageSettingsGeneral, self:hasExtendedSettings(), SettingsScreen.SLICE_ID.GENERAL_SETTINGS }, { self.pageSettingsDisplay, self:canManageDisplaySettings(), SettingsScreen.SLICE_ID.DISPLAY_SETTINGS }, { self.pageSettingsControls, self:canManageInputBindings(), SettingsScreen.SLICE_ID.CONTROLS_SETTINGS }, i, pageDef, {
		self.pageSettingsAdvanced,
		function()
			return false
		end,
		SettingsScreen.SLICE_ID.DISPLAY_SETTINGS,
	}, {
		self.pageSettingsHDR,
		function()
			return false
		end,
		SettingsScreen.SLICE_ID.DISPLAY_SETTINGS,
	} }
	local i = { self.pageSettingsDevice, self:makeCanManageInputDevices(), SettingsScreen.SLICE_ID.DEVICE_SETTINGS }
	local pageDef = { self.pageSettingsConsole, self:hasSimplifiedSettings(), SettingsScreen.SLICE_ID.CONSOLE_SETTINGS }
	for i, pageDef in ipairs(orderedPages) do
		local page, predicate, sliceId = unpack(pageDef)
		self:registerPage(page, i, predicate)
		self:addPageTab(page, nil, nil, sliceId)
	end
	self:rebuildTabList()
end
function SettingsScreen:setupMenuButtonInfo()
	local onButtonBackFunction = self.clickBackCallback
	local onButtonNextFunction = self.clickNextCallback
	local onButtonPrevFunction = self.clickPrevCallback
	local onButtonQuitFunction = self:makeSelfCallback(self.onButtonQuit)
	local onButtonSaveGameFunction = self:makeSelfCallback(self.onButtonSaveGame)
	self.defaultMenuButtonInfo = { { callback = onButtonBackFunction, inputAction = InputAction.MENU_BACK, text = g_i18n:getText(InGameMenu.L10N_SYMBOL.BUTTON_BACK) }, { callback = onButtonNextFunction, inputAction = InputAction.MENU_PAGE_NEXT, text = g_i18n:getText("ui_ingameMenuNext") }, { callback = onButtonPrevFunction, inputAction = InputAction.MENU_PAGE_PREV, text = g_i18n:getText("ui_ingameMenuPrev") } }
	self.defaultMenuButtonInfoByActions[InputAction.MENU_BACK] = self.defaultMenuButtonInfo[1]
	self.defaultMenuButtonInfoByActions[InputAction.MENU_PAGE_NEXT] = self.defaultMenuButtonInfo[2]
	self.defaultMenuButtonInfoByActions[InputAction.MENU_PAGE_PREV] = self.defaultMenuButtonInfo[3]
	self.defaultMenuButtonInfoByActions[InputAction.MENU_ACTIVATE] = self.defaultMenuButtonInfo[4]
	self.defaultMenuButtonInfoByActions[InputAction.MENU_CANCEL] = self.defaultMenuButtonInfo[5]
	self.defaultButtonActionCallbacks = { [InputAction.MENU_BACK] = self.clickBackCallback, [InputAction.MENU_PAGE_NEXT] = onButtonNextFunction, [InputAction.MENU_PAGE_PREV] = onButtonPrevFunction, [InputAction.MENU_ACTIVATE] = onButtonSaveGameFunction, [InputAction.MENU_CANCEL] = onButtonQuitFunction }
end
function SettingsScreen:onSaveChangesBackCallback(yes)
	if yes then
		local needsProcessRestart = g_settingsModel:needsProcessRestartToApplyChanges()
		g_settingsModel:applyChanges(SettingsModel.SETTING_CLASS.SAVE_ALL)
		if Platform.allowRestartOnSettingsChange then
			RestartManager:setStartScreen(RestartManager.START_SCREEN_SETTINGS_ADVANCED)
			InfoDialog.show(g_i18n:getText("dialog_restartToApplyChanges"), function()
				doRestart(needsProcessRestart, "")
			end, nil)
			return
		else
			self:changeScreen(MainScreen)
			return
		end
	end
	g_settingsModel:reset()
	self:changeScreen(MainScreen)
end
function SettingsScreen:exitMenu()
	if g_settingsModel:hasChanges() then
		YesNoDialog.show(self.onSaveChangesBackCallback, self, g_i18n:getText("ui_saveChanges"), g_i18n:getText("ui_saveSettings"))
	else
		if self.currentPage:requestClose(self.clickBackCallback) then
			self:changeScreen(MainScreen)
		end
	end
end
function SettingsScreen:showDisplaySettings()
	self:goToPage(self.pageSettingsDisplay)
end
function SettingsScreen:showGeneralSettings()
	self:goToPage(self.pageSettingsGeneral)
end
function SettingsScreen:onClickAdvancedSettings()
	self:pushDetail(self.pageSettingsAdvanced)
end
function SettingsScreen:onClickHDRSettings()
	self:pushDetail(self.pageSettingsHDR)
end
function SettingsScreen:onPagePrevious()
	if self.currentPage ~= self.pageSettingsHDR then
		SettingsScreen:superClass().onPagePrevious(self)
	end
end
function SettingsScreen:onPageNext()
	if self.currentPage ~= self.pageSettingsHDR then
		SettingsScreen:superClass().onPageNext(self)
	end
end
function SettingsScreen:makeCanManageInputDevices()
	return function()
		local _v0 = Platform.settings.canManageInputDevices
		if _v0 and not (0 < getNumOfGamepads()) then
			getIsKeyboardAvailable()
		end
		return _v0
	end
end
function SettingsScreen:canManageInputBindings()
	return function()
		return Platform.settings.canManageInputBindings
	end
end
function SettingsScreen:canManageDisplaySettings()
	return function()
		return Platform.settings.canManageDisplaySettings
	end
end
function SettingsScreen:hasExtendedSettings()
	return function()
		return not Platform.settings.simplified
	end
end
function SettingsScreen:hasSimplifiedSettings()
	return function()
		return Platform.settings.simplified
	end
end
SettingsScreen.SLICE_ID = { GENERAL_SETTINGS = "gui.icon_options_generalSettings2", DISPLAY_SETTINGS = "gui.icon_options_displaySettings.", CONSOLE_SETTINGS = "gui.consoleSettings", CONTROLS_SETTINGS = "gui.icon_options_keyboardControls", DEVICE_SETTINGS = "gui.icon_options_device" }
SettingsScreen.COLOR_ALTERNATING = { [true] = { 0.02956, 0.02956, 0.02956, 0.6 }, [false] = { 0.02956, 0.02956, 0.02956, 0.2 } }
