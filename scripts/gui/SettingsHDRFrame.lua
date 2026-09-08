-- Local values: SettingsHDRFrame_mt
SettingsHDRFrame = {}
local SettingsHDRFrame_mt = Class(SettingsHDRFrame, TabbedMenuFrameElement)
SettingsHDRFrame.DEFAULT_HDR_PEAK_BRIGHTNESS = 300
SettingsHDRFrame.DEFAULT_HDR_CONTRAST = 1
SettingsHDRFrame.DEFAULT_OVERLAY_BRIGHTNESS = 300
function SettingsHDRFrame.register()
	local v2_ = SettingsHDRFrame.new()
	g_gui:loadGui("dataS/gui/SettingsHDRFrame.xml", "SettingsHDRFrame", v2_, true)
end

-- Upvalues: SettingsHDRFrame_mt
-- Local values: self
function SettingsHDRFrame.new(target, custom_mt)
	-- upvalues: (copy) SettingsHDRFrame_mt
	local v5_ = TabbedMenuFrameElement.new(target, custom_mt or SettingsHDRFrame_mt)
	v5_.lastHDRActive = false
	v5_.hasCustomMenuButtons = true
	return v5_
end

-- Local values: newGui
function SettingsHDRFrame.createFromExistingGui(gui, guiName)
	local v8_ = SettingsHDRFrame.new()
	g_gui.frames[gui.name].target:delete()
	g_gui.frames[gui.name]:delete()
	g_gui:loadGui(gui.xmlFilename, guiName, v8_, true)
	v8_.hasCustomMenuButtons = gui.hasCustomMenuButtons
	return v8_
end

function SettingsHDRFrame:copyAttributes(src)
	SettingsHDRFrame:superClass().copyAttributes(self, src)
	self.hasCustomMenuButtons = src.hasCustomMenuButtons
end

-- Local values: isAlternate, _, container
function SettingsHDRFrame:onGuiSetupFinished()
	SettingsHDRFrame:superClass().onGuiSetupFinished(self)
	self.hdrSceneElement:setTexts({ g_i18n:getText("ui_day"), g_i18n:getText("ui_night") })
	local v12_ = true
	for _, v13_ in pairs(self.boxLayout.elements) do
		local v14_ = SettingsScreen.COLOR_ALTERNATING[v12_]
		v13_:setImageColor(nil, unpack(v14_))
		v12_ = not v12_
	end
	self.boxLayout:invalidateLayout()
end

function SettingsHDRFrame:initialize()
	SettingsHDRFrame:superClass().initialize(self)
	self.backButtonInfo = {
		["inputAction"] = InputAction.MENU_BACK
	}
	self.applyButtonInfo = {
		["inputAction"] = InputAction.MENU_ACCEPT,
		["text"] = g_i18n:getText(SettingsHDRFrame.L10N_SYMBOL.BUTTON_APPLY),
		["callback"] = function()
			-- upvalues: (copy) self
			self:onApplySettings()
		end
	}
	self.resetButtonInfo = {
		["inputAction"] = InputAction.MENU_CANCEL,
		["text"] = g_i18n:getText(SettingsHDRFrame.L10N_SYMBOL.BUTTON_RESET),
		["callback"] = function()
			-- upvalues: (copy) self
			self:onResetSettings()
		end
	}
end

function SettingsHDRFrame:delete()
	if self.loadRequestId ~= nil then
		g_i3DManager:cancelStreamI3DFile(self.loadRequestId)
		self.loadRequestId = nil
	end
	SettingsHDRFrame:superClass().delete(self)
end

-- Local values: needsRestart, needsProcessRestart
function SettingsHDRFrame:onApplySettings()
	local v18_, v_u_19_ = g_settingsModel:needsRestartToApplyChanges()
	g_settingsModel:applyChanges(SettingsModel.SETTING_CLASS.SAVE_ALL)
	if v18_ then
		RestartManager:setStartScreen(RestartManager.START_SCREEN_SETTINGS_ADVANCED)
		InfoDialog.show(g_i18n:getText("dialog_restartToApplyChanges"), function()
			-- upvalues: (copy) v_u_19_
			doRestart(v_u_19_, "")
		end, nil)
	else
		self:setMenuButtonInfoDirty()
	end
end

function SettingsHDRFrame:onResetSettings()
	self.hdrPeakBrightnessElement:setState(SettingsHDRFrame.DEFAULT_HDR_PEAK_BRIGHTNESS, true)
	self.hdrContrastElement:setState(SettingsHDRFrame.DEFAULT_HDR_CONTRAST, true)
	self.overlayBrightnessElement:setState(SettingsHDRFrame.DEFAULT_OVERLAY_BRIGHTNESS, true)
end

-- Local values: buttons
function SettingsHDRFrame:getMenuButtonInfo()
	local v22_ = { self.backButtonInfo }
	if g_settingsModel:hasChanges() then
		local v23_ = self.applyButtonInfo
		table.insert(v22_, v23_)
		local v24_ = self.resetButtonInfo
		table.insert(v22_, v24_)
	end
	return v22_
end

function SettingsHDRFrame:updateValues()
	self.hdrPeakBrightnessElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.HDR_PEAK_BRIGHTNESS))
	self.hdrContrastElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.HDR_CONTRAST))
	self.overlayBrightnessElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.OVERLAY_BRIGHTNESS))
	self:setMenuButtonInfoDirty()
end

-- Local values: isHDRActive
function SettingsHDRFrame:update(dt)
	SettingsHDRFrame:superClass().update(self, dt)
	local v28_ = getHdrAvailable()
	if self.lastHDRActive ~= v28_ then
		self.hdrPeakBrightnessElement:setDisabled(not v28_)
		self.hdrContrastElement:setDisabled(not v28_)
		self.overlayBrightnessElement:setDisabled(not v28_)
		self.lastHDRActive = v28_
	end
end

function SettingsHDRFrame:onFrameOpen()
	SettingsHDRFrame:superClass().onFrameOpen(self)
	self.lastHDRActive = getHdrAvailable()
	self:loadHDRPlane()
	self:updateValues()
end

-- Local values: isDay
function SettingsHDRFrame:hdrPlaneChanged()
	local v31_ = self.hdrSceneElement:getIsChecked() == false
	if v31_ then
		setFixedLuminanceForExposure(0.0630673)
	else
		setFixedLuminanceForExposure(0.0630672)
	end
	if self.hdrPlaneRootNode ~= nil then
		if v31_ then
			setVisibility(self.dayPlaneNode, true)
			setVisibility(self.nightPlaneNode, false)
			return
		end
		setVisibility(self.dayPlaneNode, false)
		setVisibility(self.nightPlaneNode, true)
	end
end

-- Local values: left, top, nX, nY
function SettingsHDRFrame:hdrPlaneLoaded(i3dNode, failedReason, args)
	link(getRootNode(), i3dNode)
	self.hdrPlaneRootNode = i3dNode
	self.cameraId = getChild(i3dNode, "hdrPlaneCamera")
	self.dayPlaneNode = getChild(i3dNode, "hdrPlaneDay")
	self.nightPlaneNode = getChild(i3dNode, "hdrPlaneNight")
	g_cameraManager:addCamera(self.cameraId, nil, false)
	g_cameraManager:setActiveCamera(self.cameraId)
	local v34_ = self.hdrImage.absPosition[1]
	local v35_ = self.hdrImage.absPosition[2]
	local v36_ = self.hdrImage.size[1] / 2 + v34_
	local v37_ = self.hdrImage.size[2] / 2 + v35_
	setTranslation(self.cameraId, (-v36_ + 0.5) * g_screenAspectRatio, 1, v37_ - 0.5)
	self:hdrPlaneChanged()
end

function SettingsHDRFrame:loadHDRPlane()
	if self.loadRequestId ~= nil then
		g_i3DManager:cancelStreamI3DFile(self.loadRequestId)
		self.loadRequestId = nil
	end
	self.loadRequestId = g_i3DManager:loadI3DFileAsync("dataS/menu/hdrPlane/hdrPlane.i3d", true, true, SettingsHDRFrame.hdrPlaneLoaded, self, nil)
end

function SettingsHDRFrame:onFrameClose()
	if self.cameraId ~= nil then
		g_cameraManager:setDefaultCamera()
		g_cameraManager:removeCamera(self.cameraId)
		self.cameraId = nil
	end
	self.dayPlaneNode = nil
	self.nightPlaneNode = nil
	if self.hdrPlaneRootNode ~= nil then
		delete(self.hdrPlaneRootNode)
		self.hdrPlaneRootNode = nil
	end
	setFixedLuminanceForExposure(-1)
end

function SettingsHDRFrame:getMainElementSize()
	return self.settingsContainer.size
end

function SettingsHDRFrame:getMainElementPosition()
	return self.settingsContainer.absPosition
end

-- Local values: texts, _, _
function SettingsHDRFrame:onCreateHDRPeakBrightness(element)
	local v43_, _, _ = g_settingsModel:getHDRPeakBrightnessTexts()
	element:setTexts(v43_)
end

-- Local values: texts, _, _
function SettingsHDRFrame:onCreateHDRContrast(element)
	local v45_, _, _ = g_settingsModel:getHDRContrastTexts()
	element:setTexts(v45_)
end

-- Local values: texts, _, _
function SettingsHDRFrame:onCreateOverlayBrightness(element)
	local v47_, _, _ = g_settingsModel:getOverlayBrightnessTexts()
	element:setTexts(v47_)
end

function SettingsHDRFrame:onClickHDRPeakBrightness(state)
	g_settingsModel:setValue(SettingsModel.SETTING.HDR_PEAK_BRIGHTNESS, state)
	g_settingsModel:applyCustomSettings()
	self:setMenuButtonInfoDirty()
end

function SettingsHDRFrame:onClickHDRContrast(state)
	g_settingsModel:setValue(SettingsModel.SETTING.HDR_CONTRAST, state)
	g_settingsModel:applyCustomSettings()
	self:setMenuButtonInfoDirty()
end

function SettingsHDRFrame:onClickOverlayBrightness(state)
	g_settingsModel:setValue(SettingsModel.SETTING.OVERLAY_BRIGHTNESS, state)
	g_settingsModel:applyCustomSettings()
	self:setMenuButtonInfoDirty()
end

function SettingsHDRFrame:onClickHDRSceneChange(state)
	self:hdrPlaneChanged()
end
SettingsHDRFrame.L10N_SYMBOL = {
	["BUTTON_APPLY"] = "button_apply",
	["BUTTON_RESET"] = "button_reset"
}
