-- Local values: InGameMenuMobileSettingsFrame_mt
InGameMenuMobileSettingsFrame = {}
local InGameMenuMobileSettingsFrame_mt = Class(InGameMenuMobileSettingsFrame, TabbedMenuFrameElement)
function InGameMenuMobileSettingsFrame.register()
	if Platform.isMobile then
		local v2_ = InGameMenuMobileSettingsFrame.new()
		g_gui:loadGui("dataS/gui/InGameMenuMobileSettingsFrame.xml", "MobileSettingsFrame", v2_, true)
	end
end

-- Upvalues: InGameMenuMobileSettingsFrame_mt
-- Local values: self
function InGameMenuMobileSettingsFrame.new(target, custom_mt)
	-- upvalues: (copy) InGameMenuMobileSettingsFrame_mt
	local v5_ = TabbedMenuFrameElement.new(target, custom_mt or InGameMenuMobileSettingsFrame_mt)
	v5_.missionInfo = nil
	v5_.hasMasterRights = false
	v5_.checkboxMapping = {}
	v5_.checkboxMappingGame = {}
	v5_.optionMapping = {}
	v5_.manureLoadingStations = {}
	v5_.liquidManureLoadingStations = {}
	v5_.instantApplySettings = {}
	v5_.instantApplySettings[GameSettings.SETTING.VOLUME_MASTER] = true
	v5_.instantApplySettings[GameSettings.SETTING.VOLUME_MUSIC] = true
	v5_.instantApplySettings[GameSettings.SETTING.VOLUME_GUI] = true
	v5_.hasCustomMenuButtons = false
	return v5_
end

-- Local values: newGui
function InGameMenuMobileSettingsFrame.createFromExistingGui(gui, guiName)
	local v8_ = InGameMenuMobileSettingsFrame.new()
	g_gui.frames[gui.name].target:delete()
	g_gui.frames[gui.name]:delete()
	g_gui:loadGui(gui.xmlFilename, guiName, v8_, true)
	return v8_
end

function InGameMenuMobileSettingsFrame:initialize()
	self.checkboxMapping[self.checkGyroscope] = SettingsModel.SETTING.GYROSCOPE_STEERING
	self.checkboxMapping[self.checkTilt] = SettingsModel.SETTING.CAMERA_TILTING
	self.checkboxMapping[self.checkUseMiles] = g_settingsModel.SETTING.USE_MILES
	self.checkboxMapping[self.checkUseFahrenheit] = g_settingsModel.SETTING.USE_FAHRENHEIT
	self.checkboxMapping[self.checkUseAcre] = g_settingsModel.SETTING.USE_ACRE
	self.checkboxMapping[self.checkColorBlindMode] = g_settingsModel.SETTING.USE_COLORBLIND_MODE
	self.checkboxMapping[self.checkShowTriggerMarker] = g_settingsModel.SETTING.SHOW_TRIGGER_MARKER
	self.checkboxMapping[self.checkShowHelpTrigger] = g_settingsModel.SETTING.SHOW_HELP_TRIGGER
	self.checkboxMapping[self.checkResetCamera] = g_settingsModel.SETTING.RESET_CAMERA
	self.checkboxMapping[self.checkCameraCheckCollision] = g_settingsModel.SETTING.CAMERA_CHECK_COLLISION
	self.checkboxMapping[self.checkUseWorldCamera] = g_settingsModel.SETTING.USE_WORLD_CAMERA
	self.checkboxMapping[self.checkInvertYLook] = g_settingsModel.SETTING.INVERT_Y_LOOK
	self.checkUseMiles:setTexts(g_settingsModel:getDistanceUnitTexts())
	self.checkUseFahrenheit:setTexts(g_settingsModel:getTemperatureUnitTexts())
	self.checkUseAcre:setTexts(g_settingsModel:getAreaUnitTexts())
	self.optionMapping[self.multiMoneyUnit] = SettingsModel.SETTING.MONEY_UNIT
	self.multiMoneyUnit:setTexts(g_settingsModel:getMoneyUnitTexts())
	self.optionMapping[self.multiVolumeMusic] = SettingsModel.SETTING.VOLUME_MUSIC
	self.multiVolumeMusic:setTexts(g_settingsModel:getAudioVolumeTexts())
	self.optionMapping[self.multiVolumeVehicle] = SettingsModel.SETTING.VOLUME_VEHICLE
	self.multiVolumeVehicle:setTexts(g_settingsModel:getAudioVolumeTexts())
	self.optionMapping[self.multiVolumeEnvironment] = SettingsModel.SETTING.VOLUME_ENVIRONMENT
	self.multiVolumeEnvironment:setTexts(g_settingsModel:getAudioVolumeTexts())
	self.optionMapping[self.multiVolumeCharacter] = SettingsModel.SETTING.VOLUME_CHARACTER
	self.multiVolumeCharacter:setTexts(g_settingsModel:getAudioVolumeTexts())
	self.optionMapping[self.multiVolumeGUI] = SettingsModel.SETTING.VOLUME_GUI
	self.multiVolumeGUI:setTexts(g_settingsModel:getAudioVolumeTexts())
	self.optionMapping[self.multiCameraSensitivity] = g_settingsModel.SETTING.CAMERA_SENSITIVITY
	self.multiCameraSensitivity:setTexts(g_settingsModel:getCameraSensitivityTexts())
	self.optionMapping[self.multiSteeringBackSpeed] = g_settingsModel.SETTING.STEERING_BACK_SPEED
	self.multiSteeringBackSpeed:setTexts(g_settingsModel:getSteeringBackSpeedTexts())
	self.optionMapping[self.multiUIScale] = g_settingsModel.SETTING.UI_SCALE
	self.multiUIScale:setTexts(g_settingsModel:getUiScaleTexts())
	self.optionMapping[self.multiSteeringSensitivity] = g_settingsModel.SETTING.STEERING_SENSITIVITY
	self.multiSteeringSensitivity:setTexts(g_settingsModel:getSteeringSensitivityTexts())
	self.optionMapping[self.multiGraphics] = SettingsModel.SETTING.PERFORMANCE_CLASS
	self.multiGraphics:setTexts(g_settingsModel:getPerformanceClassTexts())
	self.multiGraphics.parent:setVisible(GS_PLATFORM_PHONE)
	self.optionMapping[self.multiFrameLimit] = SettingsModel.SETTING.FRAME_LIMIT
	self.multiFrameLimit:setTexts(g_settingsModel:getFrameLimitTexts())
	self.multiFrameLimit.parent:setVisible(#Platform.frameLimits > 1)
	self.separatorGraphics:setVisible(self.multiGraphics.parent.visible or self.multiFrameLimit.parent.visible)
end

function InGameMenuMobileSettingsFrame:setMissionInfo(missionInfo)
	self.missionInfo = missionInfo
end

function InGameMenuMobileSettingsFrame:setHasMasterRights(hasMasterRights)
	self.hasMasterRights = hasMasterRights
end

-- Local values: showRestoreButton
function InGameMenuMobileSettingsFrame:onFrameOpen(element)
	InGameMenuMobileSettingsFrame:superClass().onFrameOpen(self)
	self:assignDynamicTexts()
	self:updateGeneralSettings()
	self:updateGameSettings()
	local v15_ = g_inAppPurchaseController:getHasPurchasesToRestore()
	self.iapRestoreSeparator:setVisible(v15_)
	self.iapRestoreButton:setVisible(v15_)
	self.iapRestoreSeparatorEnd:setVisible(v15_)
	if FocusManager:getFocusedElement() == nil then
		self:setSoundSuppressed(true)
		FocusManager:setFocus(self.multiTimeScale)
		self:setSoundSuppressed(false)
	end
	self.boxLayout:invalidateLayout()
end

function InGameMenuMobileSettingsFrame:onFrameClose()
	InGameMenuMobileSettingsFrame:superClass().onFrameClose(self)
	if g_settingsModel:hasChanges() then
		if g_settingsModel:getHasValueChanged(SettingsModel.SETTING.PERFORMANCE_CLASS) then
			g_settingsModel:applyChanges(SettingsModel.SETTING_CLASS.SAVE_ALL)
			return
		end
		g_settingsModel:applyChanges(SettingsModel.SETTING_CLASS.SAVE_GAMEPLAY_SETTINGS)
	end
end

-- Local values: element, settingsKey, element, settingsKey
function InGameMenuMobileSettingsFrame:updateGeneralSettings()
	g_settingsModel:refresh()
	for v18_, v19_ in pairs(self.checkboxMapping) do
		v18_:setIsChecked(g_settingsModel:getValue(v19_))
	end
	for v20_, v21_ in pairs(self.optionMapping) do
		if type(v21_) == "table" then
			v20_:setState(g_settingsModel:getValue(v21_[1]))
		else
			v20_:setState(g_settingsModel:getValue(v21_))
		end
	end
end

-- Local values: timeScaleTable, numTimeScales, i
function InGameMenuMobileSettingsFrame:updateGameSettings()
	self.checkTraffic:setIsChecked(self.missionInfo.trafficEnabled)
	self.checkHelperRefillSlurry:setState(self.missionInfo.helperSlurrySource)
	self.checkHelperRefillManure:setState(self.missionInfo.helperManureSource)
	self.checkHelperRefillFuel:setIsChecked(self.missionInfo.helperBuyFuel)
	self.checkHelperRefillSeed:setIsChecked(self.missionInfo.helperBuySeeds)
	self.checkHelperRefillFertilizer:setIsChecked(self.missionInfo.helperBuyFertilizer)
	self.checkIntroductionHelp:setIsChecked(self.missionInfo.introductionHelpActive)
	local v23_ = {}
	for v24_ = 1, Utils.getNumTimeScales() do
		local v25_ = Utils.getTimeScaleString
		table.insert(v23_, v25_(v24_))
	end
	self.multiTimeScale:setTexts(v23_)
	self.multiTimeScale:setState(Utils.getTimeScaleIndex(self.missionInfo.timeScale))
end

-- Local values: helperTexts, textTable, stationIndex, station, stationIndex, station
function InGameMenuMobileSettingsFrame:assignDynamicTexts()
	self.helperManureTextToStationIndexMapping = { 1, 2 }
	self.helperSlurryTextToStationIndexMapping = { 1, 2 }
	local v27_ = { g_i18n:getText("ui_off"), g_i18n:getText("ui_buy") }
	local v28_ = {}
	local v29_ = v27_[1]
	table.insert(v28_, v29_)
	local v30_ = v27_[2]
	table.insert(v28_, v30_)
	for v31_, v32_ in ipairs(self.manureLoadingStations) do
		if g_currentMission.accessHandler:canPlayerAccess(v32_) then
			table.insert(v28_, v32_:getName())
			self.helperManureTextToStationIndexMapping[#v28_] = v31_ + 2
		end
	end
	self.checkHelperRefillManure:setTexts(v28_)
	local v33_ = {}
	local v34_ = v27_[1]
	table.insert(v33_, v34_)
	local v35_ = v27_[2]
	table.insert(v33_, v35_)
	for v36_, v37_ in ipairs(self.liquidManureLoadingStations) do
		if g_currentMission.accessHandler:canPlayerAccess(v37_) and v37_:getIsFillAllowedToFarm(g_currentMission:getFarmId()) then
			table.insert(v33_, v37_:getName())
			self.helperSlurryTextToStationIndexMapping[#v33_] = v36_ + 2
		end
	end
	self.checkHelperRefillSlurry:setTexts(v33_)
end

function InGameMenuMobileSettingsFrame:setManureTriggers(manureLoadingStations, liquidManureLoadingStations)
	self.manureLoadingStations = manureLoadingStations
	self.liquidManureLoadingStations = liquidManureLoadingStations
end

function InGameMenuMobileSettingsFrame:onClickTraffic(state)
	if self.hasMasterRights then
		g_currentMission:setTrafficEnabled(state == CheckedOptionElement.STATE_CHECKED)
	end
end

function InGameMenuMobileSettingsFrame:onClickTimeScale(state)
	if self.hasMasterRights then
		g_currentMission:setTimeScale(Utils.getTimeScaleFromIndex(state))
	end
end

-- Local values: settingsKey
function InGameMenuMobileSettingsFrame:onClickCheckbox(state, checkboxElement)
	local v48_ = self.checkboxMapping[checkboxElement]
	if v48_ == nil then
		printWarning("Warning: Invalid settings checkbox event or key configuration for element " .. checkboxElement:toString())
	else
		g_settingsModel:setValue(v48_, state == CheckedOptionElement.STATE_CHECKED)
	end
end

-- Local values: settingsKey, _, v
function InGameMenuMobileSettingsFrame:onClickMultiOption(state, optionElement)
	local v52_ = self.optionMapping[optionElement]
	if v52_ == nil then
		printWarning("Warning: Invalid settings multi option event or key configuration for element " .. optionElement:toString())
	else
		if type(v52_) == "table" then
			for _, v53_ in ipairs(v52_) do
				g_settingsModel:setValue(v53_, state)
			end
		else
			g_settingsModel:setValue(v52_, state)
		end
		if self.instantApplySettings[v52_] then
			g_settingsModel:applyChange(v52_)
			return
		end
	end
end

-- Local values: settingsKey
function InGameMenuMobileSettingsFrame:onClickGraphics(state, optionElement)
	local v57_ = self.optionMapping[optionElement]
	if v57_ == nil then
		printWarning("Warning: Invalid settings multi option event or key configuration for element " .. optionElement:toString())
	else
		g_settingsModel:setValue(v57_, state)
	end
end

function InGameMenuMobileSettingsFrame:onClickHelperRefillFuel(state)
	if self.hasMasterRights then
		g_currentMission:setHelperBuyFuel(state == CheckedOptionElement.STATE_CHECKED)
	end
end

function InGameMenuMobileSettingsFrame:onClickHelperRefillSeed(state)
	if self.hasMasterRights then
		g_currentMission:setHelperBuySeeds(state == CheckedOptionElement.STATE_CHECKED)
	end
end

function InGameMenuMobileSettingsFrame:onClickHelperRefillFertilizer(state)
	if self.hasMasterRights then
		g_currentMission:setHelperBuyFertilizer(state == CheckedOptionElement.STATE_CHECKED)
	end
end

function InGameMenuMobileSettingsFrame:onClickHelperRefillSlurry(state)
	if self.hasMasterRights then
		if self.helperSlurryTextToStationIndexMapping ~= nil then
			g_currentMission:setHelperSlurrySource(self.helperSlurryTextToStationIndexMapping[state] or 1)
			return
		end
		g_currentMission:setHelperSlurrySource(1)
	end
end

function InGameMenuMobileSettingsFrame:onClickHelperRefillManure(state)
	if self.hasMasterRights then
		if self.helperManureTextToStationIndexMapping ~= nil then
			g_currentMission:setHelperManureSource(self.helperManureTextToStationIndexMapping[state] or 1)
			return
		end
		g_currentMission:setHelperManureSource(1)
	end
end

function InGameMenuMobileSettingsFrame:onClickIntroductionHelp(state)
	if self.hasMasterRights then
		self.missionInfo.introductionHelpActive = state == CheckedOptionElement.STATE_CHECKED
	end
end

function InGameMenuMobileSettingsFrame:onClickRestoreInAppPurchases(state)
	g_inAppPurchaseController:restorePurchases()
end
