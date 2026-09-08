-- Local values: SettingsDisplayFrame_mt, NO_CALLBACK
SettingsDisplayFrame = {}
local SettingsDisplayFrame_mt = Class(SettingsDisplayFrame, TabbedMenuFrameElement)
local function NO_CALLBACK() end
function SettingsDisplayFrame.register()
	local v3_ = SettingsDisplayFrame.new()
	g_gui:loadGui("dataS/gui/SettingsDisplayFrame.xml", "SettingsDisplayFrame", v3_, true)
end

-- Upvalues: SettingsDisplayFrame_mt
-- Local values: self
function SettingsDisplayFrame.new(target, custom_mt)
	-- upvalues: (copy) SettingsDisplayFrame_mt
	local v6_ = TabbedMenuFrameElement.new(target, custom_mt or SettingsDisplayFrame_mt)
	v6_.hasCustomMenuButtons = true
	return v6_
end

-- Local values: newGui
function SettingsDisplayFrame.createFromExistingGui(gui, guiName)
	local v9_ = SettingsDisplayFrame.new()
	g_gui.frames[gui.name].target:delete()
	g_gui.frames[gui.name]:delete()
	g_gui:loadGui(gui.xmlFilename, guiName, v9_, true)
	v9_.hasCustomMenuButtons = gui.hasCustomMenuButtons
	return v9_
end

function SettingsDisplayFrame:copyAttributes(src)
	SettingsDisplayFrame:superClass().copyAttributes(self, src)
	self.hasCustomMenuButtons = src.hasCustomMenuButtons
end

function SettingsDisplayFrame:initialize()
	self.backButtonInfo = {
		["inputAction"] = InputAction.MENU_BACK
	}
	self.nextPageButtonInfo = {
		["inputAction"] = InputAction.MENU_PAGE_NEXT,
		["text"] = g_i18n:getText("ui_ingameMenuNext"),
		["callback"] = self.onPageNext
	}
	self.prevPageButtonInfo = {
		["inputAction"] = InputAction.MENU_PAGE_PREV,
		["text"] = g_i18n:getText("ui_ingameMenuPrev"),
		["callback"] = self.onPagePrevious
	}
	self.applyButtonInfo = {
		["inputAction"] = InputAction.MENU_ACCEPT,
		["text"] = g_i18n:getText(SettingsDisplayFrame.L10N_SYMBOL.BUTTON_APPLY),
		["callback"] = function()
			-- upvalues: (copy) self
			self:onApplySettings()
		end
	}
	self.advancedButtonInfo = {
		["inputAction"] = InputAction.MENU_ACTIVATE,
		["text"] = g_i18n:getText(SettingsDisplayFrame.L10N_SYMBOL.BUTTON_ADVANCED),
		["callback"] = function()
			-- upvalues: (copy) self
			self:onClickAdvancedButton()
		end
	}
end

-- Local values: _, container
function SettingsDisplayFrame:onGuiSetupFinished()
	SettingsDisplayFrame:superClass().onGuiSetupFinished(self)
	for _, v14_ in pairs(self.boxLayout.elements) do
		if v14_:getDescendantByName("iconDisabled") ~= nil then
			v14_.setDisabled = Utils.appendedFunction(v14_.setDisabled, function(p15_, p16_)
				p15_:getDescendantByName("iconDisabled"):setDisabled(not p16_)
			end)
		end
	end
end

-- Upvalues: NO_CALLBACK
function SettingsDisplayFrame:setOpenAdvancedSettingsCallback(itemSelectedCallback)
	-- upvalues: (copy) NO_CALLBACK
	self.notifyAdvancedSettingsButton = itemSelectedCallback or NO_CALLBACK
end

-- Local values: showResolutionWarning, callBackFunc
function SettingsDisplayFrame:onApplySettings()
	local v20_ = g_settingsModel:getSettingExists(SettingsModel.SETTING.RESOLUTION_SCALE) and (g_settingsModel:getHasValueChanged(SettingsModel.SETTING.RESOLUTION_SCALE) and g_settingsModel:getValue(SettingsModel.SETTING.RESOLUTION_SCALE) > SettingsModel.getScalingStateFromResolutionScaling(1)) and true or false
	if g_settingsModel:getSettingExists(SettingsModel.SETTING.RESOLUTION_SCALE_3D) and (g_settingsModel:getHasValueChanged(SettingsModel.SETTING.RESOLUTION_SCALE_3D) and g_settingsModel:getValue(SettingsModel.SETTING.RESOLUTION_SCALE_3D) > SettingsModel.getScalingStateFromResolutionScaling(1)) and true or v20_ then
		YesNoDialog.show(function(p21_)
			-- upvalues: (copy) self
			if p21_ then
				self:applySettings()
			end
		end, nil, g_i18n:getText("ui_resolutionScaleWarning"))
	else
		self:applySettings()
	end
end

-- Local values: needsRestart, needsProcessRestart
function SettingsDisplayFrame:applySettings()
	local v23_, v_u_24_ = g_settingsModel:needsRestartToApplyChanges()
	g_settingsModel:applyChanges(SettingsModel.SETTING_CLASS.SAVE_ALL)
	if v23_ then
		RestartManager:setStartScreen(RestartManager.START_SCREEN_SETTINGS_ADVANCED)
		InfoDialog.show(g_i18n:getText("dialog_restartToApplyChanges"), function()
			-- upvalues: (copy) v_u_24_
			doRestart(v_u_24_, "")
		end, nil)
	else
		self:setMenuButtonInfoDirty()
	end
	self.hdrCalibrationButton:setDisabled(not getScreenHdrOutput())
end

-- Local values: buttons
function SettingsDisplayFrame:getMenuButtonInfo()
	local v26_ = { self.backButtonInfo, self.nextPageButtonInfo, self.prevPageButtonInfo }
	if g_settingsModel:hasChanges() then
		local v27_ = self.applyButtonInfo
		table.insert(v26_, v27_)
	end
	local v28_ = self.advancedButtonInfo
	table.insert(v26_, v28_)
	return v26_
end

-- Local values: settingFSR30, settingFSR, settingXeSS, settingDLSS, isFSR30Active, isFSRActive, isXeSSActive, isDLSSActive
function SettingsDisplayFrame:updateValues()
	self:updatePerformanceClass()
	self.performanceClassElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.PERFORMANCE_CLASS))
	self.fullscreenModeElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.FULLSCREEN_MODE) + 1)
	self.resolutionElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.RESOLUTION) + 1)
	self.vSyncElement:setIsChecked(g_settingsModel:getValue(SettingsModel.SETTING.V_SYNC), self.isOpening)
	self.brightnessElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.BRIGHTNESS))
	self.uiScaleElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.UI_SCALE))
	self.resolutionScaleElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.RESOLUTION_SCALE))
	self.hdrEnabledElement:setIsChecked(g_settingsModel:getValue(SettingsModel.SETTING.HDR_ENABLED), self.isOpening)
	if Platform.hasAdjustableFrameLimit and #Platform.frameLimits > 1 then
		self.frameLimitElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.FRAME_LIMIT))
	end
	local v30_ = g_settingsModel:getRawValue(SettingsModel.SETTING.FIDELITYFX_SR_30)
	local v31_ = g_settingsModel:getRawValue(SettingsModel.SETTING.FIDELITYFX_SR)
	local v32_ = g_settingsModel:getRawValue(SettingsModel.SETTING.XESS)
	local v33_ = g_settingsModel:getRawValue(SettingsModel.SETTING.DLSS)
	local v34_
	if v30_ == FidelityFxSR30Quality.OFF then
		v34_ = false
	else
		v34_ = v30_ ~= nil
	end
	local v35_
	if v31_ == FidelityFxSRQuality.OFF then
		v35_ = false
	else
		v35_ = v31_ ~= nil
	end
	local v36_
	if v32_ == XeSSQuality.OFF then
		v36_ = false
	else
		v36_ = v32_ ~= nil
	end
	local v37_
	if v33_ == DLSSQuality.OFF then
		v37_ = false
	else
		v37_ = v33_ ~= nil
	end
	self.resolutionScaleContainer:setDisabled(v37_ or (v36_ or (v34_ or v35_)))
	self:setMenuButtonInfoDirty()
end

-- Local values: isAlternate, _, container
function SettingsDisplayFrame:onFrameOpen()
	SettingsDisplayFrame:superClass().onFrameOpen(self)
	self.isOpening = true
	self.hdrCalibrationButton.parent:setVisible(getHdrAvailable())
	self.hdrCalibrationButton:setDisabled(not getScreenHdrOutput())
	self.hdrEnabledElement.parent:setVisible(getHdrAvailable())
	self.resolutionScaleElement.parent:setVisible(true)
	self.performanceClassElement.parent:setVisible(true)
	self.resolutionElement.parent:setVisible(true)
	self.fullscreenModeElement.parent:setVisible(true)
	self.vSyncElement.parent:setVisible(true)
	local v39_ = self.frameLimitElement.parent
	local v40_ = Platform.hasAdjustableFrameLimit
	if v40_ then
		v40_ = #Platform.frameLimits > 1
	end
	v39_:setVisible(v40_)
	local v41_ = true
	for _, v42_ in pairs(self.boxLayout.elements) do
		local v43_ = SettingsScreen.COLOR_ALTERNATING[v41_]
		v42_:setImageColor(nil, unpack(v43_))
		v41_ = not v41_
	end
	self.boxLayout:invalidateLayout()
	self:updateValues()
	self.isOpening = false
end

-- Local values: texts, _, _
function SettingsDisplayFrame:updatePerformanceClass()
	local v45_, _, _ = g_settingsModel:getPerformanceClassTexts()
	self.performanceClassElement:setTexts(v45_)
end

-- Upvalues: NO_CALLBACK
function SettingsDisplayFrame:setOpenHDRSettingsCallback(itemSelectedCallback)
	-- upvalues: (copy) NO_CALLBACK
	self.notifyHDRSettingsButton = itemSelectedCallback or NO_CALLBACK
end

-- Local values: texts, _, _
function SettingsDisplayFrame:onCreatePerformanceClass(element)
	local v49_, _, _ = g_settingsModel:getPerformanceClassTexts()
	element:setTexts(v49_)
end

function SettingsDisplayFrame:onCreateResolution(element)
	element:setTexts(g_settingsModel:getResolutionTexts())
end

function SettingsDisplayFrame:onCreateFullscreenMode(element)
	element:setTexts(g_settingsModel:getFullscreenModeTexts())
end

function SettingsDisplayFrame:onCreateBrightness(element)
	element:setTexts(g_settingsModel:getBrightnessTexts())
end

function SettingsDisplayFrame:onCreateUIScale(element)
	element:setTexts(g_settingsModel:getUiScaleTexts())
end

function SettingsDisplayFrame:onCreateResolutionScale(element)
	element:setTexts(g_settingsModel:getResolutionScaleTexts())
end

function SettingsDisplayFrame:onCreateFrameLimit(element)
	element:setTexts(g_settingsModel:getFrameLimitTexts())
end

function SettingsDisplayFrame:onClickPerformanceClass(state)
	g_settingsModel:applyPerformanceClass(state)
	self:updateValues()
end

function SettingsDisplayFrame:onClickResolution(state)
	g_settingsModel:setValue(SettingsModel.SETTING.RESOLUTION, state - 1)
	self:setMenuButtonInfoDirty()
end

function SettingsDisplayFrame:onClickBrightness(state)
	g_settingsModel:setValue(SettingsModel.SETTING.BRIGHTNESS, state)
	self:setMenuButtonInfoDirty()
end

function SettingsDisplayFrame:onClickFullscreenMode(state)
	g_settingsModel:setValue(SettingsModel.SETTING.FULLSCREEN_MODE, state - 1)
	self:setMenuButtonInfoDirty()
end

function SettingsDisplayFrame:onClickVSync(state)
	g_settingsModel:setValue(SettingsModel.SETTING.V_SYNC, self.vSyncElement:getIsChecked())
	self:setMenuButtonInfoDirty()
	self:updateValues()
end

function SettingsDisplayFrame:onClickFrameLimit(state)
	g_settingsModel:setValue(SettingsModel.SETTING.FRAME_LIMIT, state)
	self:setMenuButtonInfoDirty()
end

function SettingsDisplayFrame:onClickUIScale(state)
	g_settingsModel:setValue(SettingsModel.SETTING.UI_SCALE, state)
	self:setMenuButtonInfoDirty()
end

function SettingsDisplayFrame:onClickAdvancedButton()
	self.notifyAdvancedSettingsButton()
end

function SettingsDisplayFrame:onClickResolutionScale(state)
	g_settingsModel:setValue(SettingsModel.SETTING.RESOLUTION_SCALE, state)
	self:setMenuButtonInfoDirty()
end

-- Local values: hdrEnabled
function SettingsDisplayFrame:onClickHDREnabled(state)
	local v73_ = self.hdrEnabledElement:getIsChecked()
	g_settingsModel:setValue(SettingsModel.SETTING.HDR_ENABLED, v73_)
	self.hdrCalibrationButton.parent:setVisible(getHdrAvailable())
	self:setMenuButtonInfoDirty()
end

function SettingsDisplayFrame:onHDRCalibration()
	self.notifyHDRSettingsButton()
end

function SettingsDisplayFrame:onClickLockedIcon() end

function SettingsDisplayFrame:onFocusLockedIcon(icon)
	self.boxLayout:scrollToMakeElementVisible(icon)
end
SettingsDisplayFrame.L10N_SYMBOL = {
	["BUTTON_APPLY"] = "button_apply",
	["BUTTON_ADVANCED"] = "setting_advanced"
}
