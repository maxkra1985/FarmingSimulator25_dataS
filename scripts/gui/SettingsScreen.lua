-- Local values: SettingsScreen_mt
SettingsScreen = {}
local SettingsScreen_mt = Class(SettingsScreen, TabbedMenuWithDetails)
SettingsScreen.CONTROLS = {
	["PAGING_SETTINGS_GENERAL"] = "pageSettingsGeneral",
	["PAGING_SETTINGS_DISPLAY"] = "pageSettingsDisplay",
	["PAGING_SETTINGS_ADVANCED"] = "pageSettingsAdvanced",
	["PAGING_SETTINGS_CONTROLS"] = "pageSettingsControls",
	["PAGING_SETTINGS_CONSOLE"] = "pageSettingsConsole",
	["PAGING_SETTINGS_DEVICE"] = "pageSettingsDevice",
	["PAGING_SETTINGS_HDR"] = "pageSettingsHDR"
}
function SettingsScreen.register()
	SettingsAdvancedFrame.register()
	SettingsConsoleFrame.register()
	SettingsControlsFrame.register()
	SettingsDeviceFrame.register()
	SettingsDisplayFrame.register()
	SettingsGeneralFrame.register()
	SettingsHDRFrame.register()
	local v2_ = SettingsScreen.new()
	g_gui:loadGui("dataS/gui/SettingsScreen.xml", "SettingsScreen", v2_)
	return v2_
end

-- Upvalues: SettingsScreen_mt
-- Local values: self
function SettingsScreen.new(target, custom_mt)
	-- upvalues: (copy) SettingsScreen_mt
	return TabbedMenuWithDetails.new(target, custom_mt or SettingsScreen_mt)
end

-- Local values: newGui
function SettingsScreen.createFromExistingGui(gui, guiName)
	SettingsAdvancedFrame.createFromExistingGui(g_gui.frames.settingsAdvanced.target, "SettingsAdvancedFrame")
	SettingsConsoleFrame.createFromExistingGui(g_gui.frames.settingsConsole.target, "SettingsConsoleFrame")
	SettingsControlsFrame.createFromExistingGui(g_gui.frames.settingsControls.target, "SettingsControlsFrame")
	SettingsDeviceFrame.createFromExistingGui(g_gui.frames.settingsDevice.target, "SettingsDeviceFrame")
	SettingsDisplayFrame.createFromExistingGui(g_gui.frames.settingsDisplay.target, "SettingsDisplayFrame")
	SettingsGeneralFrame.createFromExistingGui(g_gui.frames.settingsGeneral.target, "SettingsGeneralFrame")
	SettingsHDRFrame.createFromExistingGui(g_gui.frames.settingsHDR.target, "SettingsHDRFrame")
	local v7_ = SettingsScreen.new()
	g_gui.guis[gui.name]:delete()
	g_gui.guis[gui.name].target:delete()
	g_gui:loadGui(gui.xmlFilename, guiName, v7_, false)
	return v7_
end

-- Local values: controlsController
function SettingsScreen:onGuiSetupFinished()
	SettingsScreen:superClass().onGuiSetupFinished(self)
	self.clickBackCallback = self:makeSelfCallback(self.onButtonBack)
	self.clickNextCallback = self:makeSelfCallback(self.onPageNext)
	self.clickPrevCallback = self:makeSelfCallback(self.onPagePrevious)
	self.pageSettingsGeneral:initialize()
	self.pageSettingsDisplay:initialize()
	self.pageSettingsDisplay:setOpenAdvancedSettingsCallback(function()
		-- upvalues: (copy) self
		self:onClickAdvancedSettings()
	end)
	self.pageSettingsDisplay:setOpenHDRSettingsCallback(function()
		-- upvalues: (copy) self
		self:onClickHDRSettings()
	end)
	self.pageSettingsAdvanced:initialize()
	self.pageSettingsHDR:initialize()
	self.pageSettingsConsole:initialize()
	self.pageSettingsConsole:setOpenHDRSettingsCallback(function()
		-- upvalues: (copy) self
		self:onClickHDRSettings()
	end)
	self.pageSettingsDevice:initialize()
	local v9_ = ControlsController.new()
	self.pageSettingsControls:initialize(v9_)
	self:setupPages()
	self:setupMenuButtonInfo()
end

-- Local values: orderedPages, i, pageDef, page, predicate, sliceId
function SettingsScreen:setupPages()
	local v11_ = {
		{ self.pageSettingsGeneral, self:hasExtendedSettings(), SettingsScreen.SLICE_ID.GENERAL_SETTINGS },
		{ self.pageSettingsDisplay, self:canManageDisplaySettings(), SettingsScreen.SLICE_ID.DISPLAY_SETTINGS },
		{ self.pageSettingsControls, self:canManageInputBindings(), SettingsScreen.SLICE_ID.CONTROLS_SETTINGS },
		{ self.pageSettingsDevice, self:makeCanManageInputDevices(), SettingsScreen.SLICE_ID.DEVICE_SETTINGS },
		{ self.pageSettingsConsole, self:hasSimplifiedSettings(), SettingsScreen.SLICE_ID.CONSOLE_SETTINGS },
		{ self.pageSettingsAdvanced, function()
				return false
			end, SettingsScreen.SLICE_ID.DISPLAY_SETTINGS },
		{ self.pageSettingsHDR, function()
				return false
			end, SettingsScreen.SLICE_ID.DISPLAY_SETTINGS }
	}
	for v12_, v13_ in ipairs(v11_) do
		local v14_, v15_, v16_ = unpack(v13_)
		self:registerPage(v14_, v12_, v15_)
		self:addPageTab(v14_, nil, nil, v16_)
	end
	self:rebuildTabList()
end

-- Local values: onButtonBackFunction, onButtonNextFunction, onButtonPrevFunction, onButtonQuitFunction, onButtonSaveGameFunction
function SettingsScreen:setupMenuButtonInfo()
	local v18_ = self.clickBackCallback
	local v19_ = self.clickNextCallback
	local v20_ = self.clickPrevCallback
	local v21_ = self:makeSelfCallback(self.onButtonQuit)
	local v22_ = self:makeSelfCallback(self.onButtonSaveGame)
	self.defaultMenuButtonInfo = {
		{
			["inputAction"] = InputAction.MENU_BACK,
			["text"] = g_i18n:getText(InGameMenu.L10N_SYMBOL.BUTTON_BACK),
			["callback"] = v18_
		},
		{
			["inputAction"] = InputAction.MENU_PAGE_NEXT,
			["text"] = g_i18n:getText("ui_ingameMenuNext"),
			["callback"] = v19_
		},
		{
			["inputAction"] = InputAction.MENU_PAGE_PREV,
			["text"] = g_i18n:getText("ui_ingameMenuPrev"),
			["callback"] = v20_
		}
	}
	self.defaultMenuButtonInfoByActions[InputAction.MENU_BACK] = self.defaultMenuButtonInfo[1]
	self.defaultMenuButtonInfoByActions[InputAction.MENU_PAGE_NEXT] = self.defaultMenuButtonInfo[2]
	self.defaultMenuButtonInfoByActions[InputAction.MENU_PAGE_PREV] = self.defaultMenuButtonInfo[3]
	self.defaultMenuButtonInfoByActions[InputAction.MENU_ACTIVATE] = self.defaultMenuButtonInfo[4]
	self.defaultMenuButtonInfoByActions[InputAction.MENU_CANCEL] = self.defaultMenuButtonInfo[5]
	self.defaultButtonActionCallbacks = {
		[InputAction.MENU_BACK] = self.clickBackCallback,
		[InputAction.MENU_PAGE_NEXT] = v19_,
		[InputAction.MENU_PAGE_PREV] = v20_,
		[InputAction.MENU_ACTIVATE] = v22_,
		[InputAction.MENU_CANCEL] = v21_
	}
end

-- Local values: needsProcessRestart
function SettingsScreen:onSaveChangesBackCallback(yes)
	if yes then
		local v_u_25_ = g_settingsModel:needsProcessRestartToApplyChanges()
		g_settingsModel:applyChanges(SettingsModel.SETTING_CLASS.SAVE_ALL)
		if Platform.allowRestartOnSettingsChange then
			RestartManager:setStartScreen(RestartManager.START_SCREEN_SETTINGS_ADVANCED)
			InfoDialog.show(g_i18n:getText("dialog_restartToApplyChanges"), function()
				-- upvalues: (copy) v_u_25_
				doRestart(v_u_25_, "")
			end, nil)
		else
			self:changeScreen(MainScreen)
		end
	else
		g_settingsModel:reset()
		self:changeScreen(MainScreen)
		return
	end
end

function SettingsScreen:exitMenu()
	if g_settingsModel:hasChanges() then
		YesNoDialog.show(self.onSaveChangesBackCallback, self, g_i18n:getText("ui_saveChanges"), g_i18n:getText("ui_saveSettings"))
	elseif self.currentPage:requestClose(self.clickBackCallback) then
		self:changeScreen(MainScreen)
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
		local v33_ = Platform.settings.canManageInputDevices
		if v33_ then
			v33_ = getNumOfGamepads() > 0 and true or getIsKeyboardAvailable()
		end
		return v33_
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
SettingsScreen.SLICE_ID = {
	["GENERAL_SETTINGS"] = "gui.icon_options_generalSettings2",
	["DISPLAY_SETTINGS"] = "gui.icon_options_displaySettings.",
	["CONSOLE_SETTINGS"] = "gui.consoleSettings",
	["CONTROLS_SETTINGS"] = "gui.icon_options_keyboardControls",
	["DEVICE_SETTINGS"] = "gui.icon_options_device"
}
SettingsScreen.COLOR_ALTERNATING = {
	[true] = {
		0.02956,
		0.02956,
		0.02956,
		0.6
	},
	[false] = {
		0.02956,
		0.02956,
		0.02956,
		0.2
	}
}
