-- Local values: InGameMenuSettingsFrame_mt, NO_CALLBACK, fsr34LocaKey
InGameMenuSettingsFrame = {}
local InGameMenuSettingsFrame_mt = Class(InGameMenuSettingsFrame, TabbedMenuFrameElement)
local function NO_CALLBACK() end
InGameMenuSettingsFrame.SUB_CATEGORY = {
	["GAME_SETTINGS"] = 1,
	["GENERAL_SETTINGS"] = 2,
	["GRAPHIC_SETTINGS"] = 3,
	["CONTROLS"] = 4,
	["DEADZONE"] = 5,
	["SERVER_SETTINGS"] = 6
}
function InGameMenuSettingsFrame.register()
	local v3_ = InGameMenuSettingsFrame.new()
	g_gui:loadGui("dataS/gui/InGameMenuSettingsFrame.xml", "SettingsFrame", v3_, true)
end

-- Upvalues: InGameMenuSettingsFrame_mt
-- Local values: self, i
function InGameMenuSettingsFrame.new(target, custom_mt)
	-- upvalues: (copy) InGameMenuSettingsFrame_mt
	local v6_ = TabbedMenuFrameElement.new(target, custom_mt or InGameMenuSettingsFrame_mt)
	v6_.missionInfo = nil
	v6_.manureLoadingStations = {}
	v6_.liquidManureLoadingStations = {}
	v6_.hasMasterRights = false
	v6_.isOpening = false
	v6_.hasCustomMenuButtons = true
	v6_.binaryOptionMapping = {}
	v6_.optionMapping = {}
	v6_.capacityTable = {}
	v6_.capacityNumberTable = {}
	for v7_ = g_serverMinCapacity, g_serverMaxCapacity do
		local v8_ = v6_.capacityTable
		local v9_ = tostring(v7_)
		table.insert(v8_, v9_)
		local v10_ = v6_.capacityNumberTable
		table.insert(v10_, v7_)
	end
	v6_.controlsController = nil
	v6_.controlsData = {}
	v6_.controlsMessageText = ""
	v6_.userChangedInput = false
	v6_.currentFocusCell = nil
	v6_.dataRowOffset = 0
	v6_.stateBars = {}
	return v6_
end

-- Local values: newGui
function InGameMenuSettingsFrame.createFromExistingGui(gui, guiName)
	local v13_ = InGameMenuSettingsFrame.new()
	g_gui.frames[gui.name].target:delete()
	g_gui.frames[gui.name]:delete()
	g_gui:loadGui(gui.xmlFilename, guiName, v13_, true)
	return v13_
end

-- Local values: messageCallback, inputDoneCallback
function InGameMenuSettingsFrame:initialize(pageMapOverview, onClickBackCallback, controlsController, inGame)
	self:initializeSubCategoryPages()
	self:initializeGameSettings()
	self:initializeGeneralSettings()
	self:initializeGraphicSettings()
	self:initializeButtons()
	if Platform.canChangeControls then
		self.controlsController = controlsController
		self.controlsController:setMessageCallback(function(p16_, p17_, p18_)
			-- upvalues: (copy) self
			self:setControlsMessage(p16_, p17_, p18_)
		end)
		self.controlsController:setInputDoneCallback(function(p19_)
			-- upvalues: (copy) self
			self:notifyInputGatheringFinished(p19_)
		end)
		function self.controlsList.queueReusableCell(p20_, p21_, _)
			local v22_ = p21_:getAttribute("actionButton1") ~= nil and p21_:getAttribute("actionButton1"):getIsFocused() or p21_:getAttribute("actionButton2") ~= nil and p21_:getAttribute("actionButton2"):getIsFocused()
			if not v22_ then
				if p21_:getAttribute("actionButton3") == nil then
					v22_ = false
				else
					v22_ = p21_:getAttribute("actionButton3"):getIsFocused()
				end
			end
			if not v22_ and p20_.sections[p21_.sectionIndex] ~= nil then
				p20_.sections[p21_.sectionIndex].cells[p21_.indexInSection] = nil
			end
			if not v22_ then
				p21_.sectionIndex = nil
				p21_.indexInSection = nil
				local v23_ = p20_.cellCache[p21_.reusableName]
				v23_[#v23_ + 1] = p21_
				FocusManager:removeElement(p21_)
				p21_:unlinkElement()
			end
		end
		self.subCategoryPagingFocusChangeFunc = self.subCategoryPaging.shouldFocusChange
		self.sectionTemplate:unlinkElement()
		FocusManager:removeElement(self.sectionTemplate)
		self.deadzoneTemplate:unlinkElement()
		FocusManager:removeElement(self.deadzoneTemplate)
		self.sensitivityTemplate:unlinkElement()
		FocusManager:removeElement(self.sensitivityTemplate)
		self:updateController()
	end
end

-- Local values: subCategories, index, button, mission
function InGameMenuSettingsFrame:initializeSubCategoryPages()
	local v25_ = {}
	for v_u_26_, v27_ in pairs(self.subCategoryTabs) do
		v27_:getDescendantByName("background").getIsSelected = function()
			-- upvalues: (copy) v_u_26_, (copy) self
			local v28_ = v_u_26_
			local v29_ = self.subCategoryPaging.texts[self.subCategoryPaging:getState()]
			return v28_ == tonumber(v29_)
		end
		function v27_.getIsSelected()
			-- upvalues: (copy) v_u_26_, (copy) self
			local v30_ = v_u_26_
			local v31_ = self.subCategoryPaging.texts[self.subCategoryPaging:getState()]
			return v30_ == tonumber(v31_)
		end
		local v32_ = g_currentMission
		if v_u_26_ == InGameMenuSettingsFrame.SUB_CATEGORY.CONTROLS and not Platform.canChangeControls then
			v27_:setVisible(false)
		elseif v_u_26_ == InGameMenuSettingsFrame.SUB_CATEGORY.DEADZONE and not Platform.canChangeControls then
			v27_:setVisible(false)
		elseif v_u_26_ == InGameMenuSettingsFrame.SUB_CATEGORY.SERVER_SETTINGS and not (self.hasMasterRights and v32_.missionDynamicInfo.isMultiplayer) then
			v27_:setVisible(false)
		else
			if v_u_26_ == InGameMenuSettingsFrame.SUB_CATEGORY.GRAPHIC_SETTINGS then
				self.graphicSettingsLayout:setVisible(not Platform.isConsole)
				self.graphicSettingsLayoutConsole:setVisible(Platform.isConsole)
			end
			v27_:setVisible(true)
			local v33_ = tostring(v_u_26_)
			table.insert(v25_, v33_)
		end
	end
	self.subCategoryBox:invalidateLayout()
	self.subCategoryPaging:setTexts(v25_)
	self.subCategoryPaging:setSize(self.subCategoryBox.maxFlowSize + 140 * g_pixelSizeScaledX)
end

-- Upvalues: NO_CALLBACK
-- Local values: old
function InGameMenuSettingsFrame:initializeGameSettings(pageMapOverview, onClickBackCallback)
	-- upvalues: (copy) NO_CALLBACK
	self.pageMapOverview = pageMapOverview
	self:assignStaticTexts()
	self.onClickBackCallback = onClickBackCallback or NO_CALLBACK
	local v_u_37_ = self.textSavegameName.onFocusLeave
	function self.textSavegameName.onFocusLeave(...)
		-- upvalues: (copy) v_u_37_, (copy) self
		v_u_37_(...)
		self:updateSavegameName()
	end
end

function InGameMenuSettingsFrame:initializeGeneralSettings()
	self.binaryOptionMapping[self.checkAutoHelp] = g_settingsModel.SETTING.SHOW_HELP_MENU
	self.binaryOptionMapping[self.checkColorBlindMode] = g_settingsModel.SETTING.USE_COLORBLIND_MODE
	self.binaryOptionMapping[self.checkUseMiles] = g_settingsModel.SETTING.USE_MILES
	self.binaryOptionMapping[self.checkUseFahrenheit] = g_settingsModel.SETTING.USE_FAHRENHEIT
	self.binaryOptionMapping[self.checkUseAcre] = g_settingsModel.SETTING.USE_ACRE
	self.binaryOptionMapping[self.checkShowTriggerMarker] = g_settingsModel.SETTING.SHOW_TRIGGER_MARKER
	self.binaryOptionMapping[self.checkShowHelpTrigger] = g_settingsModel.SETTING.SHOW_HELP_TRIGGER
	self.binaryOptionMapping[self.checkShowFieldInfo] = g_settingsModel.SETTING.SHOW_FIELD_INFO
	self.binaryOptionMapping[self.checkIsRadioVehicleOnly] = g_settingsModel.SETTING.RADIO_VEHICLE_ONLY
	self.binaryOptionMapping[self.checkIsRadioActive] = g_settingsModel.SETTING.RADIO_IS_ACTIVE
	self.binaryOptionMapping[self.checkResetCamera] = g_settingsModel.SETTING.RESET_CAMERA
	self.binaryOptionMapping[self.checkActiveSuspensionCamera] = g_settingsModel.SETTING.ACTIVE_SUSPENSION_CAMERA
	self.binaryOptionMapping[self.checkCameraCheckCollision] = g_settingsModel.SETTING.CAMERA_CHECK_COLLISION
	self.binaryOptionMapping[self.checkUseWorldCamera] = g_settingsModel.SETTING.USE_WORLD_CAMERA
	self.binaryOptionMapping[self.checkInvertYLook] = g_settingsModel.SETTING.INVERT_Y_LOOK
	self.binaryOptionMapping[self.checkUseEasyArmControl] = g_settingsModel.SETTING.EASY_ARM_CONTROL
	self.binaryOptionMapping[self.checkIsTrainTabbable] = g_settingsModel.SETTING.IS_TRAIN_TABBABLE
	self.binaryOptionMapping[self.checkShowMultiplayerNames] = g_settingsModel.SETTING.SHOW_MULTIPLAYER_NAMES
	self.binaryOptionMapping[self.checkWoodHarvesterAutoCut] = g_settingsModel.SETTING.WOOD_HARVESTER_AUTO_CUT
	self.checkUseMiles:setTexts(g_settingsModel:getDistanceUnitTexts())
	self.checkUseFahrenheit:setTexts(g_settingsModel:getTemperatureUnitTexts())
	self.checkUseAcre:setTexts(g_settingsModel:getAreaUnitTexts())
	self.checkIsRadioVehicleOnly:setTexts(g_settingsModel:getRadioModeTexts())
	self.optionMapping[self.multiMoneyUnit] = g_settingsModel.SETTING.MONEY_UNIT
	self.optionMapping[self.multiCameraSensitivity] = g_settingsModel.SETTING.CAMERA_SENSITIVITY
	self.optionMapping[self.multiVehicleArmSensitivity] = g_settingsModel.SETTING.VEHICLE_ARM_SENSITIVITY
	self.optionMapping[self.multiSteeringBackSpeed] = g_settingsModel.SETTING.STEERING_BACK_SPEED
	self.optionMapping[self.multiSteeringSensitivity] = g_settingsModel.SETTING.STEERING_SENSITIVITY
	self.optionMapping[self.multiMasterVolume] = g_settingsModel.SETTING.VOLUME_MASTER
	self.optionMapping[self.multiVehicleVolume] = g_settingsModel.SETTING.VOLUME_VEHICLE
	self.optionMapping[self.multiEnvironmentVolume] = g_settingsModel.SETTING.VOLUME_ENVIRONMENT
	self.optionMapping[self.multiCharacterVolume] = g_settingsModel.SETTING.VOLUME_CHARACTER
	self.optionMapping[self.multiRadioVolume] = g_settingsModel.SETTING.VOLUME_RADIO
	self.optionMapping[self.multiVolumeGUI] = g_settingsModel.SETTING.VOLUME_GUI
	self.optionMapping[self.multiVolumeNoFocus] = g_settingsModel.SETTING.VOLUME_NO_FOCUS
	self.optionMapping[self.multiInputHelpMode] = g_settingsModel.SETTING.INPUT_HELP_MODE
	self.optionMapping[self.multiDirectionChangeMode] = g_settingsModel.SETTING.DIRECTION_CHANGE_MODE
	self.optionMapping[self.multiGearShiftMode] = g_settingsModel.SETTING.GEAR_SHIFT_MODE
	self.optionMapping[self.multiHudSpeedGauge] = g_settingsModel.SETTING.HUD_SPEED_GAUGE
	self.optionMapping[self.multiVolumeVoice] = g_settingsModel.SETTING.VOLUME_VOICE
	self.optionMapping[self.multiVolumeVoiceInput] = g_settingsModel.SETTING.VOLUME_VOICE_INPUT
	self.optionMapping[self.multiVoiceMode] = g_settingsModel.SETTING.VOICE_MODE
	self.optionMapping[self.multiVoiceInputSensitivity] = g_settingsModel.SETTING.VOICE_INPUT_SENSITIVITY
	self.optionMapping[self.multiRealBeaconLightBrightness] = g_settingsModel.SETTING.REAL_BEACON_LIGHT_BRIGHTNESS
	self.multiMoneyUnit:setTexts(g_settingsModel:getMoneyUnitTexts())
	self.multiCameraSensitivity:setTexts(g_settingsModel:getCameraSensitivityTexts())
	self.multiVehicleArmSensitivity:setTexts(g_settingsModel:getVehicleArmSensitivityTexts())
	self.multiSteeringBackSpeed:setTexts(g_settingsModel:getSteeringBackSpeedTexts())
	self.multiSteeringSensitivity:setTexts(g_settingsModel:getSteeringSensitivityTexts())
	self.multiMasterVolume:setTexts(g_settingsModel:getAudioVolumeTexts())
	self.multiVehicleVolume:setTexts(g_settingsModel:getAudioVolumeTexts())
	self.multiEnvironmentVolume:setTexts(g_settingsModel:getAudioVolumeTexts())
	self.multiCharacterVolume:setTexts(g_settingsModel:getAudioVolumeTexts())
	self.multiRadioVolume:setTexts(g_settingsModel:getAudioVolumeTexts())
	self.multiVolumeGUI:setTexts(g_settingsModel:getAudioVolumeTexts())
	self.multiVolumeNoFocus:setTexts(g_settingsModel:getAudioVolumeTexts())
	self.multiVolumeVoice:setTexts(g_settingsModel:getAudioVolumeTexts())
	self.multiVolumeVoiceInput:setTexts(g_settingsModel:getRecordingVolumeTexts())
	self.multiVoiceMode:setTexts(g_settingsModel:getVoiceModeTexts())
	self.multiVoiceInputSensitivity:setTexts(g_settingsModel:getVoiceInputSensitivityTexts())
	self.multiInputHelpMode:setTexts(g_settingsModel:getInputHelpModeTexts())
	self.multiDirectionChangeMode:setTexts(g_settingsModel:getDirectionChangeModeTexts())
	self.multiGearShiftMode:setTexts(g_settingsModel:getGearShiftModeTexts())
	self.multiHudSpeedGauge:setTexts(g_settingsModel:getHudSpeedGaugeTexts())
	if GS_PLATFORM_PC then
		self.multiRealBeaconLightBrightness:setTexts(g_settingsModel:getRealBeaconLightBrightnessTexts())
	end
	if GS_IS_CONSOLE_VERSION then
		self.multiInputHelpMode.parent:setVisible(false)
		self.multiSteeringBackSpeed.parent:setVisible(false)
	end
end

-- Local values: addElement
function InGameMenuSettingsFrame:initializeGraphicSettings()
	self.graphicSettingElements = {}
	local function v45_(p40_, p41_, p42_)
		-- upvalues: (copy) self
		self.graphicSettingElements[p41_] = {
			["settingsKey"] = p40_,
			["element"] = p41_,
			["isMultiElement"] = p42_
		}
		local v43_ = g_settingsModel:getTexts(p40_)
		if v43_ == nil then
			p41_:setVisible(false)
		else
			if #v43_ == 0 then
				local v44_ = g_i18n
				table.insert(v43_, v44_:getText("ui_unavailable"))
				p41_.parent:setDisabled(true)
			else
				p41_.parent:setDisabled(false)
			end
			if p42_ or #v43_ == 2 then
				p41_:setTexts(v43_)
				return
			end
		end
	end
	v45_(SettingsModel.SETTING.POST_PROCESS_AA, self.ppaaElement, true)
	v45_(SettingsModel.SETTING.LENSFLARE_QUALITY, self.lensFlareQualityElement, true)
	v45_(SettingsModel.SETTING.VALAR, self.valarElement, true)
	v45_(SettingsModel.SETTING.SCREEN_SPACE_REFLECTIONS, self.screenSpaceReflectionsElement, true)
	v45_(SettingsModel.SETTING.SCREEN_SPACE_SHADOWS_QUALITY, self.screenSpaceShadowsQualityElement, false)
	v45_(SettingsModel.SETTING.DRS_QUALITY, self.drsQualityElement, true)
	v45_(SettingsModel.SETTING.ATMOSPHERE_QUALITY, self.atmosphereQualityElement, true)
	v45_(SettingsModel.SETTING.VOLUMETRIC_FOG_QUALITY, self.volumetricFogQualityElement, true)
	v45_(SettingsModel.SETTING.TEXTURE_FILTERING, self.textureFilteringElement, true)
	self.realBeaconLightsElementBoxConsole:setVisible(Platform.supportsRealBeaconLights)
end

-- Local values: buttonSaveChangesFunction, buttonDefaultsFunction, buttonSaveServerChangesFunction, buttonSaveGraphicChangesFunction
function InGameMenuSettingsFrame:initializeButtons()
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
	self.saveButtonInfo = {
		["inputAction"] = InputAction.MENU_ACTIVATE,
		["text"] = g_i18n:getText(InGameMenuSettingsFrame.L10N_SYMBOL.BUTTON_SAVE_CONTROLS),
		["callback"] = function()
			-- upvalues: (copy) self
			self:saveControlChanges()
		end,
		["showWhenPaused"] = true
	}
	self.resetButtonInfo = {
		["inputAction"] = InputAction.MENU_CANCEL,
		["text"] = g_i18n:getText(InGameMenuSettingsFrame.L10N_SYMBOL.BUTTON_DEFAULTS),
		["callback"] = function()
			-- upvalues: (copy) self
			self:onClickDefaults()
		end,
		["showWhenPaused"] = true
	}
	self.saveServerSettingsButtonInfo = {
		["inputAction"] = InputAction.MENU_ACTIVATE,
		["text"] = g_i18n:getText(InGameMenuSettingsFrame.L10N_SYMBOL.BUTTON_SAVE),
		["callback"] = function()
			-- upvalues: (copy) self
			self:saveServerChanges()
		end,
		["showWhenPaused"] = true
	}
	self.unblockButtonInfo = {
		["inputAction"] = InputAction.MENU_EXTRA_1,
		["text"] = g_i18n:getText("button_blocklist"),
		["callback"] = function()
			-- upvalues: (copy) self
			self:onButtonUnBan()
		end
	}
	self.unblockRemoteButtonInfo = {
		["inputAction"] = InputAction.MENU_CANCEL,
		["text"] = g_i18n:getText("button_blocklist"),
		["callback"] = function()
			-- upvalues: (copy) self
			self:onButtonUnBanRemote()
		end
	}
	self.applyButtonInfo = {
		["inputAction"] = InputAction.MENU_ACCEPT,
		["text"] = g_i18n:getText(InGameMenuSettingsFrame.L10N_SYMBOL.BUTTON_APPLY),
		["callback"] = function()
			-- upvalues: (copy) self
			self:onApplyGraphicSettings()
		end
	}
	self.switchButtonInfo = {
		["inputAction"] = InputAction.MENU_EXTRA_1,
		["text"] = g_i18n:getText(InGameMenuSettingsFrame.L10N_SYMBOL.SWITCH_DEVICE),
		["callback"] = function()
			-- upvalues: (copy) self
			self:onSwitchDevice()
		end
	}
	self.applyDeadzoneButtonInfo = {
		["inputAction"] = InputAction.MENU_ACCEPT,
		["text"] = g_i18n:getText(InGameMenuSettingsFrame.L10N_SYMBOL.BUTTON_APPLY),
		["callback"] = function()
			-- upvalues: (copy) self
			self:onApplyDeadzoneChanges()
		end
	}
end

-- Local values: oldDisableFunc, containerDisableFunc, _, container, _, name, index, scalingMode
function InGameMenuSettingsFrame:onGuiSetupFinished()
	InGameMenuSettingsFrame:superClass().onGuiSetupFinished(self)
	local v_u_48_ = self.sharpnessElement.setDisabled
	local function v51_(p49_, p50_)
		-- upvalues: (copy) v_u_48_
		v_u_48_(p49_, p50_)
		p49_:getDescendantByName("iconDisabled"):setDisabled(not p50_)
	end
	for _, v52_ in pairs(self.graphicSettingsLayout.elements) do
		if v52_:getDescendantByName("iconDisabled") ~= nil then
			v52_.setDisabled = v51_
		end
	end
	function self.frameGenerationContainer.getIsActiveNonRec()
		-- upvalues: (copy) self
		return self.frameGenerationElement:getIsActiveNonRec()
	end
	self.scalingModeNameToIndexMapping = {}
	for _, v53_ in pairs(g_settingsModel:getScalingModeTexts()) do
		for v54_, v55_ in pairs(InGameMenuSettingsFrame.SCALING_MODES) do
			if g_i18n:getText(v55_.title) == v53_ then
				self.scalingModeNameToIndexMapping[v53_] = v54_
				break
			end
		end
	end
end

function InGameMenuSettingsFrame:delete()
	if self.sectionTemplate ~= nil then
		self.sectionTemplate:delete()
	end
	if self.deadzoneTemplate ~= nil then
		self.deadzoneTemplate:delete()
	end
	if self.sensitivityTemplate ~= nil then
		self.sensitivityTemplate:delete()
	end
	InGameMenuSettingsFrame:superClass().delete(self)
end

function InGameMenuSettingsFrame:onCreateNumPlayer(element)
	element:setTexts(self.capacityTable)
	element:setState(#self.capacityTable)
end

function InGameMenuSettingsFrame:setMissionInfo(missionInfo)
	self.missionInfo = missionInfo
end

function InGameMenuSettingsFrame:setManureTriggers(manureLoadingStations, liquidManureLoadingStations)
	self.manureLoadingStations = manureLoadingStations
	self.liquidManureLoadingStations = liquidManureLoadingStations
end

function InGameMenuSettingsFrame:setHasMasterRights(hasMasterRights)
	self.hasMasterRights = hasMasterRights
	if g_currentMission ~= nil then
		self:updateButtons()
	end
end

-- Local values: mission, isMultiplayer, canChangeGameSettings, enableCameraCollisionSetting, subCategoryIndex
function InGameMenuSettingsFrame:onFrameOpen(element)
	InGameMenuSettingsFrame:superClass().onFrameOpen(self)
	self:initializeSubCategoryPages()
	self.isOpening = true
	local v67_ = g_currentMission
	local v68_ = v67_.missionDynamicInfo.isMultiplayer
	if not v68_ or (g_inGameMenu.isServer or self.hasMasterRights) then
		self:assignDynamicTexts()
		self:updateGameSettings()
		self:updatePauseButtonState()
		self.gameSettingsLayout:setVisible(true)
		self.gameSettingsSeparator:setVisible(true)
		self.gameSettingsNoPermissionText:setVisible(false)
	else
		self.gameSettingsLayout:setVisible(false)
		self.gameSettingsSeparator:setVisible(false)
		self.gameSettingsNoPermissionText:setVisible(true)
	end
	self:updateAlternatingElements(self.gameSettingsLayout)
	self:updateGeneralSettings()
	self.checkIsTrainTabbableBox:setVisible(not v68_)
	local v69_ = self.multiVolumeVoiceBox
	local v70_
	if v68_ then
		v70_ = not VoiceChatUtil.getIsVoiceRestricted()
	else
		v70_ = v68_
	end
	v69_:setVisible(v70_)
	self.multiVoiceModeBox:setVisible(v68_)
	local v71_ = self.multiVolumeVoiceInputBox
	local v72_ = v68_ and VoiceChatUtil.getHasRecordingDevice()
	if v72_ then
		v72_ = not VoiceChatUtil.getIsVoiceRestricted()
	end
	v71_:setVisible(v72_)
	local v73_ = self.checkShowMultiplayerNamesBox
	local v74_
	if v68_ then
		v74_ = not GS_IS_CONSOLE_VERSION
	else
		v74_ = v68_
	end
	v73_:setVisible(v74_)
	self.multiRealBeaconLightBrightnessBox:setVisible(g_beaconLightManager:getNumOfLights() > 0)
	self.multiVoiceInputSensitivityBox:setVisible(v68_)
	local v75_ = g_modIsLoaded.FS25_disableVehicleCameraCollision or g_isDevelopmentVersion
	self.checkCameraCheckCollisionBox:setVisible(v75_)
	self:updateAlternatingElements(self.generalSettingsLayout)
	self:updateGraphicSettings()
	local v76_ = self.frameLimitElement.parent
	local v77_ = Platform.hasAdjustableFrameLimit
	if v77_ then
		v77_ = #Platform.frameLimits > 1
	end
	v76_:setVisible(v77_)
	self:updateAlternatingElements(self.graphicSettingsLayout)
	self:updateAlternatingElements(self.graphicSettingsLayoutConsole)
	if self.hasMasterRights and v67_.missionDynamicInfo.isMultiplayer then
		self:assignServerSettings()
	end
	if Platform.canChangeControls then
		self.numTotalDevices = 3 + g_inputBinding.numActiveGamepads
		self.dataRowOffset = 0
		self:assignDeviceTableData()
		self.controlsMessageText = ""
		g_messageCenter:subscribe(MessageType.INPUT_DEVICES_CHANGED, self.onControllerChanged, self)
		g_inputBinding:resetBindingInputStates()
	end
	self:updateSubCategoryPages((self.subCategoryPaging:getState()))
	self.isOpening = false
end

-- Local values: isAlternate, _, container
function InGameMenuSettingsFrame:updateAlternatingElements(layout)
	local v79_ = true
	for _, v80_ in pairs(layout.elements) do
		if v80_.name == "sectionHeader" then
			v79_ = true
		elseif v80_.visible then
			local v81_ = InGameMenuSettingsFrame.COLOR_ALTERNATING[v79_]
			v80_:setImageColor(nil, unpack(v81_))
			v79_ = not v79_
		end
	end
	layout:invalidateLayout()
end

-- Local values: dynInfo, numPlayers, capacityState, i
function InGameMenuSettingsFrame:assignServerSettings()
	self.allowOnlyFriendsElementBg:setVisible(Platform.hasFriendFilter)
	local v83_ = g_currentMission.missionDynamicInfo
	local v84_ = v83_.capacity
	local v85_ = g_serverMinCapacity
	for v86_ = 1, #self.capacityNumberTable do
		if v84_ == self.capacityNumberTable[v86_] then
			v85_ = v86_
			break
		end
	end
	self.numPlayersElement:setState(v85_)
	self.serverNameElementBg:setVisible(not g_currentMission.connectedToDedicatedServer)
	self.autoAcceptElementBg:setVisible(not g_currentMission.connectedToDedicatedServer)
	self.numPlayersBg:setVisible(not g_currentMission.connectedToDedicatedServer)
	self.serverNameElement:setText(v83_.serverName)
	self.passwordElement:setText(v83_.password)
	self.autoAcceptElement:setIsChecked(v83_.autoAccept, true)
	self.allowOnlyFriendsElement:setIsChecked(v83_.allowOnlyFriends, true)
	self:updateAlternatingElements(self.serverSettingsLayout)
end

-- Local values: hasSettingsChanges, canClose
function InGameMenuSettingsFrame:requestClose(callback)
	local v89_ = g_settingsModel:hasChanges()
	local v90_ = not (self.userChangedInput or (self.hasServerSettingsChanges or v89_))
	if self.userChangedInput then
		InGameMenuSettingsFrame:superClass().requestClose(self, callback)
		YesNoDialog.show(self.onYesNoSaveControls, self, g_i18n:getText(InGameMenuSettingsFrame.L10N_SYMBOL.SAVE_CHANGES_PROMPT))
		return v90_
	end
	if not self.hasServerSettingsChanges then
		if v89_ then
			InGameMenuSettingsFrame:superClass().requestClose(self, callback)
			YesNoDialog.show(self.onYesNoSaveGraphicSettings, self, g_i18n:getText(InGameMenuSettingsFrame.L10N_SYMBOL.SAVE_CHANGES_PROMPT))
		end
		return v90_
	end
	InGameMenuSettingsFrame:superClass().requestClose(self, callback)
	YesNoDialog.show(self.onYesNoSaveServerSettings, self, g_i18n:getText(InGameMenuSettingsFrame.L10N_SYMBOL.SAVE_CHANGES_PROMPT))
	return v90_
end

function InGameMenuSettingsFrame:onFrameClose()
	if self.menuAcceptUpEventId ~= nil then
		g_inputBinding:removeActionEvent(self.menuAcceptUpEventId)
	end
	if self.menuUpDownEvent ~= nil then
		g_inputBinding:setContextEventsActive("MENU", InputAction.MENU_AXIS_LEFT_RIGHT, true)
		g_inputBinding:setContextEventsActive("MENU", InputAction.MENU_AXIS_UP_DOWN, true)
		g_inputBinding:removeActionEvent(self.menuUpDownEvent)
		g_inputBinding:removeActionEvent(self.menuLeftRightEvent)
	end
	g_messageCenter:unsubscribe(MessageType.INPUT_DEVICES_CHANGED, self)
	g_settingsModel:saveChanges(SettingsModel.SETTING_CLASS.SAVE_GAMEPLAY_SETTINGS)
	InGameMenuSettingsFrame:superClass().onFrameClose(self)
end

-- Local values: newCell, newButton, numOfGamepads
function InGameMenuSettingsFrame:update(dt)
	InGameMenuSettingsFrame:superClass().update(self, dt)
	if self.nextFocusSection ~= nil then
		local v94_ = self.controlsList:getElementAtSectionIndex(self.nextFocusSection, self.nextFocusCell)
		if v94_ ~= nil then
			local v95_ = v94_:getAttribute(self.nextFocusedButtonName)
			FocusManager:setFocus(v95_)
			self.nextFocusSection = nil
			self.nextFocusCell = nil
		end
	end
	if self.menuUpDownEvent ~= nil then
		if getNumOfGamepads() ~= self.numOfGamepads then
			self:updateController()
		end
		self:updateGamepadInputStates()
	end
end

-- Upvalues: NO_CALLBACK
function InGameMenuSettingsFrame:onYesNoSaveControls(yes)
	-- upvalues: (copy) NO_CALLBACK
	if yes then
		self:saveControlChanges()
	else
		self:revertChanges()
		self.requestCloseCallback()
		self.requestCloseCallback = NO_CALLBACK
	end
end

function InGameMenuSettingsFrame:revertChanges()
	self.controlsController:discardChanges()
	self.userChangedInput = false
	self:updateButtons()
end

-- Upvalues: NO_CALLBACK
function InGameMenuSettingsFrame:saveControlChanges()
	-- upvalues: (copy) NO_CALLBACK
	if self.userChangedInput then
		self.controlsController:saveChanges()
		self.userChangedInput = false
		self:updateButtons()
		InfoDialog.show(g_i18n:getText(InGameMenuSettingsFrame.L10N_SYMBOL.SAVED_CHANGES_INFO), self.requestCloseCallback)
		self.requestCloseCallback = NO_CALLBACK
	end
end

-- Upvalues: NO_CALLBACK
function InGameMenuSettingsFrame:onYesNoSaveServerSettings(yes)
	-- upvalues: (copy) NO_CALLBACK
	if yes then
		self:saveServerChanges()
	else
		self:assignServerSettings()
		self.hasServerSettingsChanges = false
		self.requestCloseCallback()
		self.requestCloseCallback = NO_CALLBACK
	end
	self:updateButtons()
end

-- Upvalues: NO_CALLBACK
-- Local values: serverName, filteredServerName, password, capacity, autoAccept, allowOnlyFriends, mission
function InGameMenuSettingsFrame:saveServerChanges()
	-- upvalues: (copy) NO_CALLBACK
	if self.hasServerSettingsChanges then
		local v103_ = self.serverNameElement:getText()
		local v104_ = filterText(v103_, false, true)
		if v103_ == "" or v103_ ~= v104_ then
			if v103_ == "" then
				self.serverNameElement:setText(g_currentMission:getDefaultServerName())
			else
				self.serverNameElement:setText(v104_)
				printWarning("Warning: Gamename not allowed. Profanity text filter. Gamename adjusted")
			end
		end
		local v105_ = self.passwordElement:getText()
		local v106_ = self.capacityNumberTable[self.numPlayersElement:getState()]
		local v107_ = self.autoAcceptElement:getIsChecked()
		local v108_ = self.allowOnlyFriendsElement:getIsChecked()
		local v109_ = g_currentMission
		g_currentMission:updateMissionDynamicInfo(v103_, v106_, v105_, v107_, v108_, v109_.missionDynamicInfo.allowCrossPlay)
		if g_currentMission:getIsServer() then
			g_currentMission:updateMasterServerInfo()
		else
			g_client:getServerConnection():sendEvent(MissionDynamicInfoEvent.new())
		end
		self.hasServerSettingsChanges = false
		InfoDialog.show(g_i18n:getText(InGameMenuSettingsFrame.L10N_SYMBOL.SAVED_CHANGES_INFO), self.requestCloseCallback)
		self.requestCloseCallback = NO_CALLBACK
	end
	self:updateButtons()
end

function InGameMenuSettingsFrame:onButtonUnBan()
	UnBanDialog.show(self.updateButtons, self, true)
end

function InGameMenuSettingsFrame:onButtonUnBanRemote()
	UnBanDialog.show(self.updateButtons, self, false)
end

-- Upvalues: NO_CALLBACK
function InGameMenuSettingsFrame:onYesNoSaveGraphicSettings(yes)
	-- upvalues: (copy) NO_CALLBACK
	if yes then
		self:onApplyGraphicSettings()
	else
		g_settingsModel:reset()
		self:updateGraphicSettings()
		self.requestCloseCallback()
		self.requestCloseCallback = NO_CALLBACK
	end
	self:updateButtons()
end

-- Local values: showResolutionWarning, callBackFunc
function InGameMenuSettingsFrame:onApplyGraphicSettings()
	local v115_ = g_settingsModel:getSettingExists(SettingsModel.SETTING.RESOLUTION_SCALE) and (g_settingsModel:getHasValueChanged(SettingsModel.SETTING.RESOLUTION_SCALE) and g_settingsModel:getValue(SettingsModel.SETTING.RESOLUTION_SCALE) > SettingsModel.getScalingStateFromResolutionScaling(1)) and true or false
	if g_settingsModel:getSettingExists(SettingsModel.SETTING.RESOLUTION_SCALE_3D) and (g_settingsModel:getHasValueChanged(SettingsModel.SETTING.RESOLUTION_SCALE_3D) and g_settingsModel:getValue(SettingsModel.SETTING.RESOLUTION_SCALE_3D) > SettingsModel.getScalingStateFromResolutionScaling(1)) and true or v115_ then
		YesNoDialog.show(function(p116_)
			-- upvalues: (copy) self
			if p116_ then
				self:applyGraphicSettings()
			end
		end, nil, g_i18n:getText("ui_resolutionScaleWarning"))
	else
		self:applyGraphicSettings()
	end
end

-- Local values: needsRestart, needsProcessRestart
function InGameMenuSettingsFrame:applyGraphicSettings()
	local v118_, v119_ = g_settingsModel:needsRestartToApplyChanges()
	g_settingsModel:applyChanges(SettingsModel.SETTING_CLASS.SAVE_ALL)
	if v118_ or v119_ then
		Logging.warning("A setting change needs a restart to be applied, no such setting should be in the ingame menu!")
	else
		self:updateButtons()
	end
end

-- Local values: subCategoryIndex
function InGameMenuSettingsFrame:updateButtons()
	self.menuButtonInfo = { self.backButtonInfo, self.nextPageButtonInfo, self.prevPageButtonInfo }
	local v121_ = self.subCategoryPaging.texts[self.subCategoryPaging:getState()]
	local v122_ = tonumber(v121_)
	if v122_ == InGameMenuSettingsFrame.SUB_CATEGORY.CONTROLS and Platform.canChangeControls then
		if self.userChangedInput then
			local v123_ = self.menuButtonInfo
			local v124_ = self.saveButtonInfo
			table.insert(v123_, v124_)
		end
		local v125_ = self.menuButtonInfo
		local v126_ = self.resetButtonInfo
		table.insert(v125_, v126_)
	elseif v122_ == InGameMenuSettingsFrame.SUB_CATEGORY.SERVER_SETTINGS then
		if self.hasServerSettingsChanges then
			local v127_ = self.menuButtonInfo
			local v128_ = self.saveServerSettingsButtonInfo
			table.insert(v127_, v128_)
		end
		if getNumOfBlockedUsers() > 0 then
			local v129_ = self.menuButtonInfo
			local v130_ = self.unblockButtonInfo
			table.insert(v129_, v130_)
		end
		if g_currentMission ~= nil and g_currentMission.connectedToDedicatedServer then
			local v131_ = self.menuButtonInfo
			local v132_ = self.unblockRemoteButtonInfo
			table.insert(v131_, v132_)
		end
	elseif v122_ == InGameMenuSettingsFrame.SUB_CATEGORY.GRAPHIC_SETTINGS then
		if g_settingsModel:hasChanges() then
			local v133_ = self.menuButtonInfo
			local v134_ = self.applyButtonInfo
			table.insert(v133_, v134_)
		end
	elseif v122_ == InGameMenuSettingsFrame.SUB_CATEGORY.DEADZONE then
		if g_settingsModel:getNumDevices() > 1 then
			local v135_ = self.menuButtonInfo
			local v136_ = self.switchButtonInfo
			table.insert(v135_, v136_)
		end
		if g_settingsModel:hasChanges() then
			local v137_ = self.menuButtonInfo
			local v138_ = self.applyDeadzoneButtonInfo
			table.insert(v137_, v138_)
		end
	end
	self:setMenuButtonInfoDirty()
end

-- Local values: period, days, isTourRunning
function InGameMenuSettingsFrame:updateGameSettings()
	self.savegameName = self.missionInfo.savegameName
	self.textSavegameName:setText(self.missionInfo.savegameName)
	self.multiTimeScale:setState(Utils.getTimeScaleIndex(self.missionInfo.timeScale))
	self.economicDifficulty:setState(self.missionInfo.economicDifficulty)
	self.checkSnowEnabled:setIsChecked(self.missionInfo.isSnowEnabled, self.isOpening)
	self.multiGrowthMode:setState(self.missionInfo.growthMode)
	local v140_ = self.missionInfo.fixedSeasonalVisuals
	self.multiFixedSeasonalVisuals:setState(v140_ == nil and 1 or v140_ + 1)
	local v141_ = self.missionInfo.plannedDaysPerPeriod
	self.multiPlannedDaysPerPeriod:setState(v141_)
	self.checkFruitDestruction:setIsChecked(self.missionInfo.fruitDestruction, self.isOpening)
	self.checkPlowingRequired:setIsChecked(self.missionInfo.plowingRequiredEnabled, self.isOpening)
	self.checkStonesEnabled:setIsChecked(self.missionInfo.stonesEnabled, self.isOpening)
	self.checkLimeRequired:setIsChecked(self.missionInfo.limeRequired, self.isOpening)
	self.checkWeedsEnabled:setIsChecked(self.missionInfo.weedsEnabled, self.isOpening)
	self.multiAutoSaveInterval:setState(g_autoSaveManager:getIndexFromInterval(g_autoSaveManager:getInterval()))
	self.checkTraffic:setIsChecked(self.missionInfo.trafficEnabled, self.isOpening)
	self.multiDirt:setState(self.missionInfo.dirtInterval)
	self.checkAutoMotorStart:setIsChecked(self.missionInfo.automaticMotorStartEnabled, self.isOpening)
	self.checkHelperRefillFuel:setIsChecked(self.missionInfo.helperBuyFuel, self.isOpening)
	self.checkHelperRefillSeed:setIsChecked(self.missionInfo.helperBuySeeds, self.isOpening)
	self.checkHelperRefillFertilizer:setIsChecked(self.missionInfo.helperBuyFertilizer, self.isOpening)
	self.multiFuelUsage:setState(self.missionInfo.fuelUsage)
	self.checkStopAndGoBraking:setIsChecked(self.missionInfo.stopAndGoBraking, self.isOpening)
	self.checkTrailerFillLimit:setIsChecked(self.missionInfo.trailerFillLimit, self.isOpening)
	self.multiDisasterDestructionState:setState(self.missionInfo.disasterDestructionState)
	self.multiHelperRefillSlurry:setState(self.missionInfo.helperSlurrySource)
	self.multiHelperRefillManure:setState(self.missionInfo.helperManureSource)
	local v142_ = g_guidedTourManager:getIsTourRunning()
	self.textSavegameName:setDisabled(not self.hasMasterRights)
	self.multiTimeScale:setDisabled(not self.hasMasterRights or v142_)
	self.economicDifficulty:setDisabled(not self.hasMasterRights)
	self.checkSnowEnabled:setDisabled(not self.hasMasterRights)
	self.multiGrowthMode:setDisabled(not self.hasMasterRights)
	self.multiFixedSeasonalVisuals:setDisabled(not self.hasMasterRights)
	self.multiPlannedDaysPerPeriod:setDisabled(not self.hasMasterRights)
	self.checkFruitDestruction:setDisabled(not self.hasMasterRights)
	self.checkPlowingRequired:setDisabled(not self.hasMasterRights)
	self.checkLimeRequired:setDisabled(not self.hasMasterRights)
	self.checkWeedsEnabled:setDisabled(not self.hasMasterRights)
	self.multiDirt:setDisabled(not self.hasMasterRights)
	self.multiAutoSaveInterval:setDisabled(not g_currentMission:getIsServer())
	if self.multiAutoSaveIntervalBox == nil then
		self.multiAutoSaveInterval:setVisible(g_currentMission:getIsServer())
	else
		self.multiAutoSaveIntervalBox:setVisible(g_currentMission:getIsServer())
	end
end

function InGameMenuSettingsFrame:updatePauseButtonState()
	if g_currentMission.paused then
		self.buttonPauseGame:applyProfile(InGameMenuSettingsFrame.PROFILE.BUTTON_UNPAUSE)
		self.buttonPauseGame:setText(g_i18n:getText(InGameMenuSettingsFrame.L10N_SYMBOL.UNPAUSE))
	else
		self.buttonPauseGame:applyProfile(InGameMenuSettingsFrame.PROFILE.BUTTON_PAUSE)
		self.buttonPauseGame:setText(g_i18n:getText(InGameMenuSettingsFrame.L10N_SYMBOL.PAUSE))
	end
end

-- Local values: helperTexts, options, i, days, i
function InGameMenuSettingsFrame:assignStaticTexts()
	self:assignTimeScaleTexts()
	self:assignEconomicDifficultyTexts()
	self:assignDirtTexts()
	self:assignAutoSaveTexts()
	self.multiFuelUsage:setTexts({ g_i18n:getText(InGameMenuSettingsFrame.L10N_SYMBOL.USAGE_LOW), g_i18n:getText(InGameMenuSettingsFrame.L10N_SYMBOL.USAGE_DEFAULT), g_i18n:getText(InGameMenuSettingsFrame.L10N_SYMBOL.USAGE_HIGH) })
	self.multiDisasterDestructionState:setTexts({ g_i18n:getText("setting_disasterDestructionState_enabled"), g_i18n:getText("setting_disasterDestructionState_visualsOnly"), g_i18n:getText("setting_disasterDestructionState_disabled") })
	local v145_ = { g_i18n:getText(InGameMenuSettingsFrame.L10N_SYMBOL.OFF), g_i18n:getText(InGameMenuSettingsFrame.L10N_SYMBOL.BUY) }
	self.checkHelperRefillFuel:setTexts(v145_)
	self.checkHelperRefillSeed:setTexts(v145_)
	self.checkHelperRefillFertilizer:setTexts(v145_)
	self.multiGrowthMode:setTexts({ g_i18n:getText("ui_yes"), g_i18n:getText("ui_no"), g_i18n:getText("ui_paused") })
	local v146_ = { g_i18n:getText("ui_off") }
	for v147_ = 1, 12 do
		local v148_ = g_i18n
		table.insert(v146_, v148_:formatPeriod(v147_))
	end
	self.multiFixedSeasonalVisuals:setTexts(v146_)
	local v149_ = {}
	for v150_ = 1, Environment.MAX_DAYS_PER_PERIOD do
		local v151_ = g_i18n
		table.insert(v149_, v151_:formatNumDay(v150_))
	end
	self.multiPlannedDaysPerPeriod:setTexts(v149_)
end

-- Local values: timeScaleTable, numTimeScales, i
function InGameMenuSettingsFrame:assignTimeScaleTexts()
	local v153_ = {}
	for v154_ = 1, Utils.getNumTimeScales() do
		local v155_ = Utils.getTimeScaleString
		table.insert(v153_, v155_(v154_))
	end
	self.multiTimeScale:setTexts(v153_)
end

-- Local values: economicDifficultyTable
function InGameMenuSettingsFrame:assignEconomicDifficultyTexts()
	local v157_ = {}
	local v158_ = g_i18n
	local v159_ = InGameMenuSettingsFrame.L10N_SYMBOL.DIFFICULTY_EASY
	table.insert(v157_, v158_:getText(v159_))
	local v160_ = g_i18n
	local v161_ = InGameMenuSettingsFrame.L10N_SYMBOL.DIFFICULTY_NORMAL
	table.insert(v157_, v160_:getText(v161_))
	local v162_ = g_i18n
	local v163_ = InGameMenuSettingsFrame.L10N_SYMBOL.DIFFICULTY_HARD
	table.insert(v157_, v162_:getText(v163_))
	self.economicDifficulty:setTexts(v157_)
end

-- Local values: textTable, i
function InGameMenuSettingsFrame:assignDirtTexts()
	local v165_ = {}
	local v166_ = g_i18n
	local v167_ = InGameMenuSettingsFrame.L10N_SYMBOL.OFF
	table.insert(v165_, v166_:getText(v167_))
	for v168_ = 1, 3 do
		local v169_ = g_i18n
		local v170_ = InGameMenuSettingsFrame.L10N_SYMBOL.DIRT_TEMPLATE .. v168_
		table.insert(v165_, v169_:getText(v170_))
	end
	self.multiDirt:setTexts(v165_)
end

-- Local values: textTable, _, interval
function InGameMenuSettingsFrame:assignAutoSaveTexts()
	local v172_ = {}
	for _, v173_ in ipairs(g_autoSaveManager:getIntervalOptions()) do
		if v173_ > 0 then
			local v174_ = v173_ .. " " .. g_i18n:getText("unit_minutesShort")
			table.insert(v172_, v174_)
		else
			local v175_ = g_i18n
			local v176_ = InGameMenuSettingsFrame.L10N_SYMBOL.OFF
			table.insert(v172_, v175_:getText(v176_))
		end
	end
	self.multiAutoSaveInterval:setTexts(v172_)
end

-- Local values: helperTexts, textTable, stationIndex, station, stationIndex, station
function InGameMenuSettingsFrame:assignDynamicTexts()
	self.helperManureTextToStationIndexMapping = { 1, 2 }
	self.helperSlurryTextToStationIndexMapping = { 1, 2 }
	local v178_ = { g_i18n:getText(InGameMenuSettingsFrame.L10N_SYMBOL.OFF), g_i18n:getText(InGameMenuSettingsFrame.L10N_SYMBOL.BUY) }
	local v179_ = {}
	local v180_ = v178_[1]
	table.insert(v179_, v180_)
	local v181_ = v178_[2]
	table.insert(v179_, v181_)
	for v182_, v183_ in ipairs(self.manureLoadingStations) do
		if g_currentMission.accessHandler:canPlayerAccess(v183_) then
			table.insert(v179_, v183_:getName())
			self.helperManureTextToStationIndexMapping[#v179_] = v182_ + 2
		end
	end
	self.multiHelperRefillManure:setTexts(v179_)
	local v184_ = {}
	local v185_ = v178_[1]
	table.insert(v184_, v185_)
	local v186_ = v178_[2]
	table.insert(v184_, v186_)
	for v187_, v188_ in ipairs(self.liquidManureLoadingStations) do
		if g_currentMission.accessHandler:canPlayerAccess(v188_) and v188_:getIsFillAllowedToFarm(g_currentMission:getFarmId()) then
			table.insert(v184_, v188_:getName())
			self.helperSlurryTextToStationIndexMapping[#v184_] = v187_ + 2
		end
	end
	self.multiHelperRefillSlurry:setTexts(v184_)
end

-- Local values: element, settingsKey, element, settingsKey
function InGameMenuSettingsFrame:updateGeneralSettings()
	g_settingsModel:refresh()
	for v190_, v191_ in pairs(self.binaryOptionMapping) do
		v190_:setIsChecked(g_settingsModel:getValue(v191_), self.isOpening)
	end
	for v192_, v193_ in pairs(self.optionMapping) do
		v192_:setState(g_settingsModel:getValue(v193_))
	end
end

-- Local values: performanceTexts, _, _, _, data, postProcessAA, isNativeFSR3, settingFSR30, isFSR30Active, settingFSR, isFSRActive, supportsFrameGeneration, frameGenerationActive, supportsXeSSFrameGeneration, isNativeXeSS, settingXeSS, isXeSSActive, xessFrameGenerationActive, supportsDLSSFrameGeneration, settingDLSS, isDLSSActive, isDLAAActive, dlssFrameGenerationActive, isDRSAvailable, frameGenerationElementTexts, textsFunc, i, frameGenerationState, settingsKey, _, setting, currentValue, state, texts, sharpnessAvailable
function InGameMenuSettingsFrame:updateGraphicSettings()
	if Platform.isConsole then
		self.fovYElementConsole:setState(g_settingsModel:getValue(SettingsModel.SETTING.FOV_Y))
		self.fovYPlayerFirstPersonElementConsole:setState(g_settingsModel:getValue(SettingsModel.SETTING.FOV_Y_PLAYER_FIRST_PERSON))
		self.fovYPlayerThirdPersonElementConsole:setState(g_settingsModel:getValue(SettingsModel.SETTING.FOV_Y_PLAYER_THIRD_PERSON))
		self.uiScaleElementConsole:setState(g_settingsModel:getValue(SettingsModel.SETTING.UI_SCALE))
		self.brightnessElementConsole:setState(g_settingsModel:getValue(SettingsModel.SETTING.BRIGHTNESS))
		self.realBeaconLightsElementConsole:setIsChecked(g_settingsModel:getValue(SettingsModel.SETTING.REAL_BEACON_LIGHTS), self.isOpening)
		self:updateButtons()
		self.graphicSettingsLayoutConsole:invalidateLayout()
		return
	end
	local v195_, _, _ = g_settingsModel:getPerformanceClassTexts()
	self.performanceClassElement:setTexts(v195_)
	self.performanceClassElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.PERFORMANCE_CLASS))
	self.vSyncElement:setIsChecked(g_settingsModel:getValue(SettingsModel.SETTING.V_SYNC), self.isOpening)
	self.brightnessElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.BRIGHTNESS))
	self.uiScaleElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.UI_SCALE))
	self.resolutionScaleElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.RESOLUTION_SCALE))
	if Platform.hasAdjustableFrameLimit and #Platform.frameLimits > 1 then
		self.frameLimitElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.FRAME_LIMIT))
	end
	for _, v196_ in pairs(self.graphicSettingElements) do
		if v196_.isMultiElement then
			v196_.element:setState(g_settingsModel:getValue(v196_.settingsKey) or 1)
		else
			v196_.element:setIsChecked(g_settingsModel:getValue(v196_.settingsKey) == BinaryOptionElement.STATE_RIGHT, self.isOpening)
		end
	end
	self.drsTargetFPSElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.DRS_TARGET_FPS))
	self.sharpnessElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.SHARPNESS))
	self.shadingRateQualityElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.SHADING_RATE_QUALITY))
	self.textureFilteringElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.TEXTURE_FILTERING))
	self.textureResolutionElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.TEXTURE_RESOLUTION))
	self.shadowQualityElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.SHADOW_QUALITY))
	self.shadowDistanceQualityElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.SHADOW_DISTANCE_QUALITY))
	self.softShadowsElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.SOFT_SHADOWS))
	self.shaderQualityElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.SHADER_QUALITY))
	self.shadowMapFilteringElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.SHADOW_MAP_FILTERING))
	self.maxLightsElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.MAX_LIGHTS))
	self.terrainQualityElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.TERRAIN_QUALITY))
	self.objectDrawDistanceElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.OBJECT_DRAW_DISTANCE))
	self.foliageDrawDistanceElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.FOLIAGE_DRAW_DISTANCE))
	self.lodDistanceElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.LOD_DISTANCE))
	self.terrainLODDistanceElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.TERRAIN_LOD_DISTANCE))
	self.foliageLODDistanceElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.FOLIAGE_LOD_DISTANCE))
	self.volumeMeshTessellationElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.VOLUME_MESH_TESSELLATION))
	self.maxTireTracksElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.MAX_TIRE_TRACKS))
	self.lightsProfileElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.LIGHTS_PROFILE) - 1)
	self.realBeaconLightsElement:setIsChecked(g_settingsModel:getValue(SettingsModel.SETTING.REAL_BEACON_LIGHTS), self.isOpening)
	self.maxMirrorsElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.MAX_MIRRORS))
	self.foliageShadowsElement:setIsChecked(g_settingsModel:getValue(SettingsModel.SETTING.FOLIAGE_SHADOW), self.isOpening)
	self.ssaoQualityElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.SSAO_QUALITY))
	self.cloudShadowsQualityElement:setIsChecked(g_settingsModel:getValue(SettingsModel.SETTING.CLOUD_SHADOWS_QUALITY), self.isOpening)
	self.resolutionScale3dElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.RESOLUTION_SCALE_3D))
	self.fovYElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.FOV_Y))
	self.fovYPlayerFirstPersonElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.FOV_Y_PLAYER_FIRST_PERSON))
	self.fovYPlayerThirdPersonElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.FOV_Y_PLAYER_THIRD_PERSON))
	local v197_ = g_settingsModel:getRawValue(SettingsModel.SETTING.POST_PROCESS_AA)
	local v198_ = v197_ == PostProcessAntiAliasing.FSR3
	local v199_ = g_settingsModel:getRawValue(SettingsModel.SETTING.FIDELITYFX_SR_30)
	local v200_
	if v199_ == FidelityFxSR30Quality.OFF then
		v200_ = false
	else
		v200_ = v199_ ~= nil
	end
	local v201_ = g_settingsModel:getRawValue(SettingsModel.SETTING.FIDELITYFX_SR)
	local v202_
	if v201_ == FidelityFxSRQuality.OFF then
		v202_ = false
	else
		v202_ = v201_ ~= nil
	end
	local v203_ = getSupportsFidelityFxFrameInterpolation(FrameInterpolationMode.FRAME_INTERPOLATION_2X)
	if v203_ then
		if v198_ or v200_ then
			v203_ = g_settingsModel:getValue(SettingsModel.SETTING.FULLSCREEN_MODE) ~= FullscreenMode.EXCLUSIVE_FULLSCREEN
		else
			v203_ = v200_
		end
	end
	local v204_ = getSupportsXeSSFrameInterpolation(FrameInterpolationMode.FRAME_INTERPOLATION_2X)
	local v205_ = v197_ == PostProcessAntiAliasing.XESS
	local v206_ = g_settingsModel:getRawValue(SettingsModel.SETTING.XESS)
	local v207_
	if v206_ == XeSSQuality.OFF then
		v207_ = false
	else
		v207_ = v206_ ~= nil
	end
	if v204_ then
		if v205_ or v207_ then
			v204_ = g_settingsModel:getValue(SettingsModel.SETTING.FULLSCREEN_MODE) ~= FullscreenMode.EXCLUSIVE_FULLSCREEN
		else
			v204_ = v207_
		end
	end
	local v208_ = getSupportsDLSSFrameInterpolation(FrameInterpolationMode.FRAME_INTERPOLATION_2X)
	local v209_ = g_settingsModel:getRawValue(SettingsModel.SETTING.DLSS)
	local v210_
	if v209_ == DLSSQuality.OFF then
		v210_ = false
	else
		v210_ = v209_ ~= nil
	end
	local v211_ = g_settingsModel:getRawValue(SettingsModel.SETTING.POST_PROCESS_AA) == PostProcessAntiAliasing.DLAA
	if v208_ then
		if v210_ or v211_ then
			v211_ = g_settingsModel:getValue(SettingsModel.SETTING.FULLSCREEN_MODE) ~= FullscreenMode.EXCLUSIVE_FULLSCREEN
		end
	else
		v211_ = v208_
	end
	local v212_ = getIsDRSAvailable()
	self.drsQualityContainer:setDisabled(not v212_)
	self.drsTargetFPSContainer:setDisabled(not v212_)
	self.frameGenerationContainer:setDisabled(not (v203_ or (v204_ or v211_)))
	local v213_ = { getFrameInterpolationModeName(FrameInterpolationMode.FRAME_INTERPOLATION_OFF) }
	local v214_ = getSupportsDLSSFrameInterpolation
	if v204_ then
		v214_ = getSupportsXeSSFrameInterpolation
	elseif v203_ then
		v214_ = getSupportsFidelityFxFrameInterpolation
	end
	for v215_ = 1, EnumUtil.getNumEntries(FrameInterpolationMode) - 1 do
		if v214_(v215_) then
			local v216_ = getFrameInterpolationModeName
			table.insert(v213_, v216_(v215_))
		end
	end
	self.frameGenerationElement:setTexts(v213_)
	local v217_ = g_settingsModel:getValue(SettingsModel.SETTING.FIDELITYFX_SR_30_FRAME_GENERATION)
	local v218_ = g_settingsModel:getValue(SettingsModel.SETTING.XESS_FRAME_GENERATION)
	local v219_ = g_settingsModel
	local v220_ = SettingsModel.SETTING.DLSS_FRAME_GENERATION
	local v221_ = math.max(v217_, v218_, v219_:getValue(v220_))
	self.frameGenerationElement:setState(v221_ + 1)
	if v205_ or v207_ then
		self.frameGenerationTitle:setText(g_i18n:getText("setting_xeSSFrameGeneration"))
		self.frameGenerationTooltip:setText(g_i18n:getText("toolTip_xeSSFrameGeneration"))
	elseif v198_ or v200_ then
		self.frameGenerationTitle:setText(g_i18n:getText("setting_fidelityFxSR30FrameInterpolation"))
		self.frameGenerationTooltip:setText(g_i18n:getText("toolTip_fidelityFxSR30FrameInterpolation"))
	elseif v210_ then
		self.frameGenerationTitle:setText(g_i18n:getText("setting_dlssFrameInterpolation"))
		self.frameGenerationTooltip:setText(g_i18n:getText("toolTip_dlssFrameInterpolation"))
	else
		self.frameGenerationTitle:setText(g_i18n:getText("setting_frameGeneration"))
	end
	self.resolutionScaleContainer:setDisabled(v210_ or (v207_ or (v200_ or v202_)))
	self.resolutionScale3dContainer:setDisabled(v210_ or (v207_ or (v200_ or v202_)))
	local v222_ = nil
	for _, v223_ in pairs(InGameMenuSettingsFrame.SCALING_MODES) do
		local v224_ = g_settingsModel:getRawValue(v223_.name)
		if v224_ ~= nil and v224_ ~= v223_.enum.OFF then
			local v225_ = self.scalingModeNameToIndexMapping[g_i18n:getText(v223_.title)] or 1
			self.scalingModeElement:setState(v225_)
			v222_ = v223_.name
			break
		end
	end
	if v222_ == nil then
		self.scalingModeElement:setState(1)
	else
		local v226_ = g_settingsModel:getTexts(v222_)
		if v212_ and g_settingsModel:getRawValue(SettingsModel.SETTING.DRS_QUALITY) ~= DRSQuality.OFF then
			self.scalingModeQualityElement:setTexts({ g_i18n:getText("ui_auto") })
			self.scalingModeQualityElement:setState(1)
			self.scalingModeQualityContainer:setDisabled(true)
		else
			self.scalingModeQualityElement:setTexts(v226_)
			self.scalingModeQualityContainer:setDisabled(false)
			self.scalingModeQualityElement:setState(g_settingsModel:getValue(v222_))
		end
	end
	local v227_ = self.ppaaElement:getState() ~= 1 and true or v222_ ~= nil
	self.sharpnessContainer:setDisabled(not v227_)
	self.scalingModeQualityContainer:setDisabled(v222_ == nil)
	self:updateButtons()
	self.graphicSettingsLayout:invalidateLayout()
end

-- Local values: hasGamepads, hasKeyboard
function InGameMenuSettingsFrame:updateHeader()
	local v229_ = g_inputBinding.numActiveGamepads > 0
	local v230_ = getIsKeyboardAvailable()
	self.gamepadHeaderText:setVisible(v229_)
	self.keyboardHeaderText:setVisible(v230_)
	self.gamepadHeaderText:setDisabled(true)
	self.keyboardHeaderText:setDisabled(true)
	if v230_ then
		self.keyboardHeaderText:setDisabled(false)
	elseif v229_ then
		self.gamepadHeaderText:setDisabled(false)
	end
end

-- Local values: hasKeyboard, hasGamepads
function InGameMenuSettingsFrame:setupControlsView()
	if getIsKeyboardAvailable() then
		self.deviceCategoryTables[InputDevice.CATEGORY.KEYBOARD_MOUSE] = self.keyboardMouseTable
		self:bindControls(InGameMenuSettingsFrame.KB_MOUSE_BOUND_CONTROLS, InputDevice.CATEGORY.KEYBOARD_MOUSE)
	else
		self.deviceCategoryTables[InputDevice.CATEGORY.KEYBOARD_MOUSE] = nil
		self.deviceCategoryDataBindings[InputDevice.CATEGORY.KEYBOARD_MOUSE] = nil
	end
	if g_inputBinding.numActiveGamepads > 0 then
		self:bindControls(InGameMenuSettingsFrame.GAMEPAD_BOUND_CONTROLS, InputDevice.CATEGORY.GAMEPAD)
		self.deviceCategoryTables[InputDevice.CATEGORY.GAMEPAD] = self.gamepadTable
	else
		self.deviceCategoryTables[InputDevice.CATEGORY.GAMEPAD] = nil
		self.deviceCategoryDataBindings[InputDevice.CATEGORY.GAMEPAD] = nil
	end
end

function InGameMenuSettingsFrame:assignDeviceTableData()
	self.controlsController:loadBindings()
	self.controlsData = self.controlsController:getDeviceCategoryActionBindings()
	self.controlsList:reloadData()
	self:updateListHeaderNames()
end

-- Local values: gamepads, index, headerName
function InGameMenuSettingsFrame:updateListHeaderNames()
	local v234_ = g_inputBinding:getGamepadDevices()
	local v235_ = 1 + self.dataRowOffset
	local v236_
	if v235_ <= 3 then
		v236_ = g_i18n:getText(SettingsControlsFrame.DEVICES[v235_].name)
	else
		v236_ = v234_[v235_ - 3].name
		if g_i18n:hasText(v236_) then
			v236_ = g_i18n:getText(v236_)
		elseif InputDevice.NAMES[v236_] ~= nil then
			v236_ = InputDevice.NAMES[v236_]
		end
	end
	self.headerText1:setText(v236_)
	local v237_ = v235_ + 1
	local v238_
	if v237_ <= 3 then
		v238_ = g_i18n:getText(SettingsControlsFrame.DEVICES[v237_].name)
	else
		v238_ = v234_[v237_ - 3].name
		if g_i18n:hasText(v238_) then
			v238_ = g_i18n:getText(v238_)
		elseif InputDevice.NAMES[v238_] ~= nil then
			v238_ = InputDevice.NAMES[v238_]
		end
	end
	self.headerText2:setText(v238_)
	local v239_ = v237_ + 1
	local v240_
	if v239_ <= 3 then
		v240_ = g_i18n:getText(SettingsControlsFrame.DEVICES[v239_].name)
	else
		v240_ = v234_[v239_ - 3].name
		if g_i18n:hasText(v240_) then
			v240_ = g_i18n:getText(v240_)
		elseif InputDevice.NAMES[v240_] ~= nil then
			v240_ = InputDevice.NAMES[v240_]
		end
	end
	self.headerText3:setText(v240_)
	self.buttonPrevRow:setVisible(self.dataRowOffset > 0)
	self.buttonNextRow:setVisible(self.dataRowOffset < self.numTotalDevices - 3)
	self.gamepads = v234_
end

-- Local values: text, uiSymbol, isWarning, dialogType, formatString
function InGameMenuSettingsFrame:setControlsMessage(messageId, additionalText, addLine)
	if messageId and messageId ~= ControlsController.MESSAGE_CLEAR then
		local v245_ = not addLine and "" or self.controlsMessageText .. "\n"
		local v246_ = SettingsControlsFrame.CONTROLS_UI_STRINGS[messageId]
		local v247_ = InGameMenuSettingsFrame.CONFLICT_MESSAGES[v246_] ~= nil and DialogElement.TYPE_WARNING or DialogElement.TYPE_INFO
		local v248_
		if v246_ then
			v248_ = v245_ .. g_i18n:getText(v246_)
			if additionalText and #additionalText > 0 then
				v248_ = v248_ .. additionalText[1]
			end
		else
			local v249_ = SettingsControlsFrame.L10N_TEMPLATE_SYMBOL[messageId]
			local v250_ = g_i18n:getText(v249_)
			if additionalText and #additionalText > 0 then
				v248_ = v245_ .. string.format(v250_, unpack(additionalText))
			else
				v248_ = v245_ .. v250_
			end
		end
		self.controlsMessageText = v248_
		InfoDialog.show(v248_, nil, nil, v247_)
	else
		self.controlsMessageText = ""
	end
end

function InGameMenuSettingsFrame:notifyInputGatheringFinished(madeChange)
	self:setSoundSuppressed(true)
	g_gui:closeAllDialogs()
	FocusManager:setGui(self.name)
	self:setSoundSuppressed(false)
	if madeChange then
		self:assignDeviceTableData()
		self.userChangedInput = true
		self:updateButtons()
	end
	self:playSample(GuiSoundPlayer.SOUND_SAMPLES.CLICK)
end

-- Local values: promptStringSymbol, promptTemplate, text, ensureInNeutral
function InGameMenuSettingsFrame:showInputPrompt(deviceCategory, bindingId, actionData)
	local v256_
	if deviceCategory == InputDevice.CATEGORY.KEYBOARD_MOUSE then
		if bindingId == ControlsController.BINDING_PRIMARY or bindingId == ControlsController.BINDING_SECONDARY then
			v256_ = InGameMenuSettingsFrame.L10N_SYMBOL.KEY_PROMPT
		else
			v256_ = InGameMenuSettingsFrame.L10N_SYMBOL.MOUSE_PROMPT
		end
	else
		v256_ = InGameMenuSettingsFrame.L10N_SYMBOL.BUTTON_PROMPT
	end
	local v257_ = g_i18n:getText(v256_)
	local v258_ = string.format(v257_, actionData.displayName) .. "\n" .. g_i18n:getText(InGameMenuSettingsFrame.CONTROLS_UI_STRINGS[ControlsController.MESSAGE_PROMPT_CANCEL_DELETE])
	local v259_ = g_i18n:getText(InGameMenuSettingsFrame.CONTROLS_UI_STRINGS[ControlsController.MESSAGE_ENSURE_IN_NEUTRAL])
	if utf8Strlen(v259_) > 1 then
		v258_ = v258_ .. "\n\n" .. v259_
	end
	MessageDialog.show(v258_, nil, nil, DialogElement.TYPE_KEY)
end
InGameMenuSettingsFrame.KB_MOUSE_BOUND_CONTROLS = {
	["ACTION"] = "action",
	["KEY_1"] = "key1",
	["KEY_2"] = "key2",
	["MOUSE_BUTTON"] = "mouseButton"
}
InGameMenuSettingsFrame.GAMEPAD_BOUND_CONTROLS = {
	["ACTION"] = "gamepadAction",
	["BUTTON_1"] = "gamepadButton1",
	["BUTTON_2"] = "gamepadButton2"
}

-- Local values: bindingName, columnName
function InGameMenuSettingsFrame:bindControls(bindings, deviceCategory)
	for v263_, v264_ in pairs(bindings) do
		if not self.deviceCategoryDataBindings[deviceCategory] then
			self.deviceCategoryDataBindings[deviceCategory] = {}
		end
		self.deviceCategoryDataBindings[deviceCategory][v263_] = v264_
	end
end

function InGameMenuSettingsFrame:onEnterPressedSavegameName()
	self:updateSavegameName()
end

-- Local values: newName
function InGameMenuSettingsFrame:updateSavegameName()
	local v267_ = self.textSavegameName.text
	if v267_ ~= self.savegameName then
		if v267_ == "" then
			v267_ = g_i18n:getText("defaultSavegameName")
			self.textSavegameName:setText(v267_)
		end
		self.missionInfo.savegameName = v267_
		self.savegameName = v267_
		SavegameSettingsEvent.sendEvent()
	end
end

function InGameMenuSettingsFrame:onClickTimeScale(state)
	if self.hasMasterRights then
		g_currentMission:setTimeScale(Utils.getTimeScaleFromIndex(state))
	end
end

function InGameMenuSettingsFrame:onClickEconomicDifficulty(state)
	if self.hasMasterRights then
		g_currentMission:setEconomicDifficulty(state)
	end
end

function InGameMenuSettingsFrame:onClickTraffic(state, binaryElement)
	if self.hasMasterRights then
		g_currentMission:setTrafficEnabled(binaryElement:getIsChecked())
	end
end

function InGameMenuSettingsFrame:onClickDirt(state)
	if self.hasMasterRights then
		g_currentMission:setDirtInterval(state)
	end
end

function InGameMenuSettingsFrame:onClickFuelUsage(state)
	if self.hasMasterRights then
		g_currentMission:setFuelUsage(state)
	end
end

function InGameMenuSettingsFrame:onClickHelperRefillFuel(state, binaryElement)
	if self.hasMasterRights then
		g_currentMission:setHelperBuyFuel(binaryElement:getIsChecked())
	end
end

function InGameMenuSettingsFrame:onClickHelperRefillSeed(state, binaryElement)
	if self.hasMasterRights then
		g_currentMission:setHelperBuySeeds(binaryElement:getIsChecked())
	end
end

function InGameMenuSettingsFrame:onClickHelperRefillFertilizer(state, binaryElement)
	if self.hasMasterRights then
		g_currentMission:setHelperBuyFertilizer(binaryElement:getIsChecked())
	end
end

function InGameMenuSettingsFrame:onClickHelperRefillSlurry(state)
	if self.hasMasterRights then
		if self.helperSlurryTextToStationIndexMapping ~= nil then
			g_currentMission:setHelperSlurrySource(self.helperSlurryTextToStationIndexMapping[state] or 1)
			return
		end
		g_currentMission:setHelperSlurrySource(1)
	end
end

function InGameMenuSettingsFrame:onClickHelperRefillManure(state)
	if self.hasMasterRights then
		if self.helperManureTextToStationIndexMapping ~= nil then
			g_currentMission:setHelperManureSource(self.helperManureTextToStationIndexMapping[state] or 1)
			return
		end
		g_currentMission:setHelperManureSource(1)
	end
end

function InGameMenuSettingsFrame:onClickAutomaticMotorStart(state, binaryElement)
	if self.hasMasterRights then
		g_currentMission:setAutomaticMotorStartEnabled(binaryElement:getIsChecked())
	end
end

function InGameMenuSettingsFrame:onClickSnowEnabled(state, binaryElement)
	if self.hasMasterRights then
		g_currentMission:setSnowEnabled(binaryElement:getIsChecked())
	end
end

function InGameMenuSettingsFrame:onClickPlannedDaysPerPeriod(state)
	if self.hasMasterRights then
		g_currentMission:setPlannedDaysPerPeriod(state)
	end
end

function InGameMenuSettingsFrame:onClickGrowthMode(state)
	if self.hasMasterRights then
		g_currentMission:setGrowthMode(state)
	end
end

function InGameMenuSettingsFrame:onClickFixedSeasonalVisuals(state)
	if self.hasMasterRights then
		if state == 1 then
			g_currentMission:setFixedSeasonalVisuals(nil)
			return
		end
		g_currentMission:setFixedSeasonalVisuals(state - 1)
	end
end

function InGameMenuSettingsFrame:onClickDisasterDestructionState(state)
	if self.hasMasterRights then
		g_currentMission:setDisasterDestructionState(state)
	end
end

function InGameMenuSettingsFrame:onClickFruitDestruction(state, binaryElement)
	if self.hasMasterRights then
		g_currentMission:setFruitDestructionEnabled(binaryElement:getIsChecked())
	end
end

function InGameMenuSettingsFrame:onClickPlowingRequired(state, binaryElement)
	if self.hasMasterRights then
		g_currentMission:setPlowingRequiredEnabled(binaryElement:getIsChecked())
	end
end

function InGameMenuSettingsFrame:onClickStonesEnabled(state, binaryElement)
	if self.hasMasterRights then
		g_currentMission:setStonesEnabled(binaryElement:getIsChecked())
	end
end

function InGameMenuSettingsFrame:onClickLimeRequired(state, binaryElement)
	if self.hasMasterRights then
		g_currentMission:setLimeRequired(binaryElement:getIsChecked())
	end
end

function InGameMenuSettingsFrame:onClickWeedsEnabled(state, binaryElement)
	if self.hasMasterRights then
		g_currentMission:setWeedsEnabled(binaryElement:getIsChecked())
	end
end

function InGameMenuSettingsFrame:onClickStopAndGoBraking(state, binaryElement)
	if self.hasMasterRights then
		g_currentMission:setStopAndGoBraking(binaryElement:getIsChecked())
	end
end

function InGameMenuSettingsFrame:onClickTrailerFillLimit(state, binaryElement)
	if self.hasMasterRights then
		g_currentMission:setTrailerFillLimit(binaryElement:getIsChecked())
	end
end

function InGameMenuSettingsFrame:onClickAutoSaveInterval(state)
	if self.hasMasterRights then
		g_currentMission:setAutoSaveInterval(g_autoSaveManager:getIntervalFromIndex(state))
	end
end

function InGameMenuSettingsFrame:onClickPauseGame()
	if GS_IS_CONSOLE_VERSION then
		self.onClickBackCallback()
	end
	g_currentMission:setManualPause(not g_currentMission.paused)
	self:updatePauseButtonState()
end

-- Local values: settingsKey
function InGameMenuSettingsFrame:onClickBinaryOption(state, binaryElement)
	local v319_ = self.binaryOptionMapping[binaryElement]
	if v319_ == nil then
		printWarning("Warning: Invalid settings checkbox event or key configuration for element " .. binaryElement:toString())
	else
		g_settingsModel:setValue(v319_, binaryElement:getIsChecked())
		g_settingsModel:applyChanges(SettingsModel.SETTING_CLASS.SAVE_NONE)
		self.dirty = true
	end
end

-- Local values: settingsKey
function InGameMenuSettingsFrame:onClickMultiOption(state, optionElement)
	if optionElement == self.multiVoiceMode and VoiceChatUtil.getIsVoiceRestricted() then
		VoiceChatUtil.showVoiceRestrictedPopup()
		optionElement:setState(VoiceChatUtil.MODE.DISABLED)
	else
		local v323_ = self.optionMapping[optionElement]
		if v323_ == nil then
			printWarning("Warning: Invalid settings multi option event or key configuration for element " .. optionElement:toString())
		else
			g_settingsModel:setValue(v323_, state)
			g_settingsModel:applyChanges(SettingsModel.SETTING_CLASS.SAVE_NONE)
			self.dirty = true
		end
		if optionElement == self.multiRealBeaconLightBrightness then
			g_beaconLightManager:updateBeaconLights()
		end
	end
end

-- Local values: mission
function InGameMenuSettingsFrame:onEnterPressedServerName()
	if g_currentMission.missionDynamicInfo.serverName ~= self.serverNameElement:getText() then
		self.hasServerSettingsChanges = true
	end
	self:updateButtons()
end

-- Local values: mission
function InGameMenuSettingsFrame:onEnterOrEscPressedServerPassword()
	if g_currentMission.missionDynamicInfo.password ~= self.passwordElement:getText() then
		self.hasServerSettingsChanges = true
	end
	self:updateButtons()
end

function InGameMenuSettingsFrame:onClickServerNumPlayers()
	if g_currentMission.missionDynamicInfo.capacity ~= self.numPlayersElement.textElement:getText() then
		self.hasServerSettingsChanges = true
	end
	self:updateButtons()
end

-- Local values: mission
function InGameMenuSettingsFrame:onClickServerAutoAccept()
	if g_currentMission.missionDynamicInfo.autoAccept ~= self.autoAcceptElement:getIsChecked() then
		self.hasServerSettingsChanges = true
	end
	self:updateButtons()
end

-- Local values: mission
function InGameMenuSettingsFrame:onClickServerAllowOnlyFriends()
	if g_currentMission.missionDynamicInfo.allowOnlyFriends ~= self.allowOnlyFriendsElement:getIsChecked() then
		self.hasServerSettingsChanges = true
	end
	self:updateButtons()
end

-- Local values: texts, _, _
function InGameMenuSettingsFrame:onCreatePerformanceClass(element)
	local v330_, _, _ = g_settingsModel:getPerformanceClassTexts()
	element:setTexts(v330_)
end

function InGameMenuSettingsFrame:onCreateBrightness(element)
	element:setTexts(g_settingsModel:getBrightnessTexts())
end

function InGameMenuSettingsFrame:onCreateUIScale(element)
	element:setTexts(g_settingsModel:getUiScaleTexts())
end

function InGameMenuSettingsFrame:onCreateResolutionScale(element)
	element:setTexts(g_settingsModel:getResolutionScaleTexts())
end

function InGameMenuSettingsFrame:onCreateFrameLimit(element)
	element:setTexts(g_settingsModel:getFrameLimitTexts())
end

function InGameMenuSettingsFrame:onCreatePPAAToolTip(element)
	element:setText(g_settingsModel:getPostProcessAAToolTip())
end

function InGameMenuSettingsFrame:onCreateDRSTargetFPS(element)
	element:setTexts(g_settingsModel:getDRSTargetFPSTexts())
end

function InGameMenuSettingsFrame:onCreateSharpness(element)
	element:setTexts(g_settingsModel:getSharpnessTexts())
end

function InGameMenuSettingsFrame:onCreateScalingMode(element)
	element:setTexts(g_settingsModel:getScalingModeTexts())
end

function InGameMenuSettingsFrame:onCreateScalingModeQuality(element)
	element:setTexts(g_settingsModel:getTexts(SettingsModel.SETTING.FIDELITYFX_SR))
end

function InGameMenuSettingsFrame:onCreateShadingRateQuality(element)
	element:setTexts(g_settingsModel:getShadingRateQualityTexts())
end

function InGameMenuSettingsFrame:onCreateShadowQuality(element)
	element:setTexts(g_settingsModel:getShadowQualityTexts())
end

function InGameMenuSettingsFrame:onCreateShadowDistanceQuality(element)
	element:setTexts(g_settingsModel:getShadowDistanceQualityTexts())
end

function InGameMenuSettingsFrame:onCreateSoftShadows(element)
	element:setTexts(g_settingsModel:getSoftShadowsTexts())
end

function InGameMenuSettingsFrame:onCreateSSAOQuality(element)
	element:setTexts(g_settingsModel:getSSAOQualityTexts())
end

function InGameMenuSettingsFrame:onCreateShaderQuality(element)
	element:setTexts(g_settingsModel:getShaderQualityTexts())
end

function InGameMenuSettingsFrame:onCreateTextureResolution(element)
	element:setTexts(g_settingsModel:getTextureResolutionTexts())
end

function InGameMenuSettingsFrame:onCreateShadowMapFiltering(element)
	element:setTexts(g_settingsModel:getShadowMapFilteringTexts())
end

function InGameMenuSettingsFrame:onCreateLightsProfile(element)
	element:setTexts(g_settingsModel:getLightsProfileTexts())
end

function InGameMenuSettingsFrame:onCreateTerrainQuality(element)
	element:setTexts(g_settingsModel:getTerraingQualityTexts())
end

function InGameMenuSettingsFrame:onCreateShadowMaxLights(element)
	element:setTexts(g_settingsModel:getShadowMapLightsTexts())
end

function InGameMenuSettingsFrame:onCreateObjectDrawDistance(element)
	element:setTexts(g_settingsModel:getObjectDrawDistanceTexts())
end

function InGameMenuSettingsFrame:onCreateFoliageDrawDistance(element)
	element:setTexts(g_settingsModel:getFoliageDrawDistanceTexts())
end

function InGameMenuSettingsFrame:onCreateLODDistance(element)
	element:setTexts(g_settingsModel:getLODDistanceTexts())
end

function InGameMenuSettingsFrame:onCreateTerrainLODDistance(element)
	element:setTexts(g_settingsModel:getTerrainLODDistanceTexts())
end

function InGameMenuSettingsFrame:onCreateFoliageLODDistance(element)
	element:setTexts(g_settingsModel:getFoliageLODDistanceTexts())
end

function InGameMenuSettingsFrame:onCreateVolumeMeshTessellation(element)
	element:setTexts(g_settingsModel:getVolumeMeshTessalationTexts())
end

function InGameMenuSettingsFrame:onCreateMaxTireTracks(element)
	element:setTexts(g_settingsModel:getMaxTireTracksTexts())
end

function InGameMenuSettingsFrame:onCreateMaxMirrors(element)
	element:setTexts(g_settingsModel:getMaxMirrorsTexts())
end

function InGameMenuSettingsFrame:onCreateResolutionScale3d(element)
	element:setTexts(g_settingsModel:getResolutionScale3dTexts())
end

function InGameMenuSettingsFrame:onCreateFovY(element)
	element:setTexts(g_settingsModel:getFovYTexts())
end

function InGameMenuSettingsFrame:onCreateFovYPlayerFirstPerson(element)
	element:setTexts(g_settingsModel:getFovYTexts())
end

function InGameMenuSettingsFrame:onCreateFovYPlayerThirdPerson(element)
	element:setTexts(g_settingsModel:getFovYTexts())
end

function InGameMenuSettingsFrame:onCreateFrameGenerationTooltip(element)
	if getFidelityFxSuperResolutionVersion() == 4 then
		element:setText(g_i18n:getText("toolTip_frameGenerationDisabledFSR4"))
	end
end

function InGameMenuSettingsFrame:onClickGameSettings()
	self.subCategoryPaging:setState(InGameMenuSettingsFrame.SUB_CATEGORY.GAME_SETTINGS, true)
end

function InGameMenuSettingsFrame:onClickGeneralSettings()
	self.subCategoryPaging:setState(InGameMenuSettingsFrame.SUB_CATEGORY.GENERAL_SETTINGS, true)
end

function InGameMenuSettingsFrame:onClickGraphicSettingss()
	self.subCategoryPaging:setState(InGameMenuSettingsFrame.SUB_CATEGORY.GRAPHIC_SETTINGS, true)
end

function InGameMenuSettingsFrame:onClickServerSettings()
	self.subCategoryPaging:setState(InGameMenuSettingsFrame.SUB_CATEGORY.SERVER_SETTINGS, true)
end

function InGameMenuSettingsFrame:onClickControls()
	self.subCategoryPaging:setState(InGameMenuSettingsFrame.SUB_CATEGORY.CONTROLS, true)
end

function InGameMenuSettingsFrame:onClickDeadzoneSettings()
	self.subCategoryPaging:setState(InGameMenuSettingsFrame.SUB_CATEGORY.DEADZONE, true)
end

function InGameMenuSettingsFrame:onClickPreviousSubCategory()
	self.subCategoryPaging:onLeftButtonClicked()
end

function InGameMenuSettingsFrame:onClickNextSubCategory()
	self.subCategoryPaging:onRightButtonClicked()
end

-- Local values: subCategoryIndex, makeSubCategoryUpdateCallback, index, page, layout, _, _
function InGameMenuSettingsFrame:updateSubCategoryPages(state)
	local v374_ = self.subCategoryPaging.texts[state]
	if v374_ == nil then
		return
	else
		local v375_ = tonumber(v374_)
		if self:requestClose(v375_ == InGameMenuSettingsFrame.SUB_CATEGORY.CONTROLS and function()
			-- upvalues: (copy) self, (copy) state
			self:assignDeviceTableData()
			self:updateSubCategoryPages(state)
		end or function()
			-- upvalues: (copy) self, (copy) state
			self:updateSubCategoryPages(state)
		end) then
			for v376_, v377_ in pairs(self.subCategoryPages) do
				v377_:setVisible(v376_ == v375_)
			end
			self.subCategoryPaging.shouldFocusChange = self.subCategoryPagingFocusChangeFunc
			self.categoryHeaderIcon:setImageSlice(nil, InGameMenuSettingsFrame.HEADER_SLICES[v375_])
			self.categoryHeaderText:setText(g_i18n:getText(InGameMenuSettingsFrame.HEADER_TITLES[v375_]))
			if self.menuAcceptUpEventId ~= nil then
				g_inputBinding:removeActionEvent(self.menuAcceptUpEventId)
			end
			if self.menuUpDownEvent ~= nil then
				g_inputBinding:setContextEventsActive("MENU", InputAction.MENU_AXIS_LEFT_RIGHT, true)
				g_inputBinding:setContextEventsActive("MENU", InputAction.MENU_AXIS_UP_DOWN, true)
				g_inputBinding:removeActionEvent(self.menuUpDownEvent)
				g_inputBinding:removeActionEvent(self.menuLeftRightEvent)
			end
			if v375_ == InGameMenuSettingsFrame.SUB_CATEGORY.GAME_SETTINGS then
				self.settingsSlider:setDataElement(self.gameSettingsLayout)
				FocusManager:linkElements(self.subCategoryPaging, FocusManager.TOP, self.gameSettingsLayout.elements[#self.gameSettingsLayout.elements].elements[1])
				FocusManager:linkElements(self.subCategoryPaging, FocusManager.BOTTOM, self.gameSettingsLayout:findFirstFocusable(true))
			elseif v375_ == InGameMenuSettingsFrame.SUB_CATEGORY.GENERAL_SETTINGS then
				self.settingsSlider:setDataElement(self.generalSettingsLayout)
				FocusManager:linkElements(self.subCategoryPaging, FocusManager.TOP, self.generalSettingsLayout.elements[#self.generalSettingsLayout.elements].elements[1])
				FocusManager:linkElements(self.subCategoryPaging, FocusManager.BOTTOM, self.generalSettingsLayout:findFirstFocusable(true))
			elseif v375_ == InGameMenuSettingsFrame.SUB_CATEGORY.GRAPHIC_SETTINGS then
				local v378_ = Platform.isConsole and self.graphicSettingsLayoutConsole or self.graphicSettingsLayout
				self.settingsSlider:setDataElement(v378_)
				FocusManager:linkElements(self.subCategoryPaging, FocusManager.TOP, v378_.elements[#v378_.elements].elements[1])
				FocusManager:linkElements(self.subCategoryPaging, FocusManager.BOTTOM, v378_:findFirstFocusable(true))
			elseif v375_ == InGameMenuSettingsFrame.SUB_CATEGORY.SERVER_SETTINGS then
				self.settingsSlider:setDataElement(self.serverSettingsLayout)
				FocusManager:linkElements(self.subCategoryPaging, FocusManager.TOP, self.serverSettingsLayout.elements[#self.serverSettingsLayout.elements].elements[1])
				FocusManager:linkElements(self.subCategoryPaging, FocusManager.BOTTOM, self.serverSettingsLayout:findFirstFocusable(true))
			elseif v375_ == InGameMenuSettingsFrame.SUB_CATEGORY.CONTROLS then
				local _, v379_ = g_inputBinding:registerActionEvent(InputAction.MENU_ACCEPT, self, self.onMenuAcceptUp, true, false, false, true)
				self.menuAcceptUpEventId = v379_
				self.settingsSlider:setDataElement(self.controlsList)
				self.controlsList:makeCellVisible(1, 1)
				function self.subCategoryPaging.shouldFocusChange(_, p380_)
					-- upvalues: (copy) self
					if p380_ == FocusManager.TOP then
						local v381_ = #self.controlsList.sections
						local v382_ = self.controlsList.sections[v381_].numItems
						self.controlsList:makeCellVisible(v381_, v382_)
						local v383_ = self
						self.nextFocusSection = v381_
						v383_.nextFocusCell = v382_
						self.nextFocusedButtonName = "actionButton1"
						return false
					end
					if p380_ ~= FocusManager.BOTTOM then
						return self.subCategoryPagingFocusChangeFunc(p380_)
					end
					local v384_ = 1
					local v385_ = 1
					self.controlsList:makeCellVisible(v384_, v385_)
					local v386_ = self
					self.nextFocusSection = v384_
					v386_.nextFocusCell = v385_
					self.nextFocusedButtonName = "actionButton1"
					return false
				end
			elseif v375_ == InGameMenuSettingsFrame.SUB_CATEGORY.DEADZONE then
				g_settingsModel:initDeviceSettings()
				g_settingsModel:refresh()
				self:updateDeadzoneView()
				g_inputBinding:setContextEventsActive("MENU", InputAction.MENU_AXIS_LEFT_RIGHT, false)
				g_inputBinding:setContextEventsActive("MENU", InputAction.MENU_AXIS_UP_DOWN, false)
				local _, v387_ = g_inputBinding:registerActionEvent(InputAction.AXIS_CONSTRUCTION_MENU_UP_DOWN, self, self.onAxisUpDown, false, true, false, true)
				self.menuUpDownEvent = v387_
				local _, v388_ = g_inputBinding:registerActionEvent(InputAction.AXIS_CONSTRUCTION_MENU_LEFT_RIGHT, self, self.onAxisLeftRight, true, true, true, true)
				self.menuLeftRightEvent = v388_
				self.settingsSlider:setDataElement(self.deadzoneLayout)
			end
			self:updateButtons()
			FocusManager:setFocus(self.subCategoryPaging)
		end
	end
end

function InGameMenuSettingsFrame:onClickNativeHelp()
	openNativeHelpMenu()
end

-- Local values: data
function InGameMenuSettingsFrame:onClick(state, element)
	local v392_ = self.graphicSettingElements[element]
	g_settingsModel:setValue(v392_.settingsKey, state)
	g_settingsModel:applyCustomSettings()
	self:updateGraphicSettings()
end

function InGameMenuSettingsFrame:onClickPerformanceClass(state)
	g_settingsModel:applyPerformanceClass(state)
	self:updateGraphicSettings()
end

function InGameMenuSettingsFrame:onClickResolution(state)
	g_settingsModel:setValue(SettingsModel.SETTING.RESOLUTION, state - 1)
	self:updateGraphicSettings()
end

function InGameMenuSettingsFrame:onClickBrightness(state)
	g_settingsModel:setValue(SettingsModel.SETTING.BRIGHTNESS, state)
	self:updateGraphicSettings()
end

function InGameMenuSettingsFrame:onClickFullscreenMode(state)
	g_settingsModel:setValue(SettingsModel.SETTING.FULLSCREEN_MODE, state - 1)
	self:updateGraphicSettings()
end

function InGameMenuSettingsFrame:onClickVSync(state)
	g_settingsModel:setValue(SettingsModel.SETTING.V_SYNC, self.vSyncElement:getIsChecked())
	self:updateGraphicSettings()
end

function InGameMenuSettingsFrame:onClickFrameLimit(state)
	g_settingsModel:setValue(SettingsModel.SETTING.FRAME_LIMIT, state)
	self:updateGraphicSettings()
end

function InGameMenuSettingsFrame:onClickUIScale(state)
	g_settingsModel:setValue(SettingsModel.SETTING.UI_SCALE, state)
	self:updateGraphicSettings()
end

function InGameMenuSettingsFrame:onClickResolutionScale(state)
	g_settingsModel:setValue(SettingsModel.SETTING.RESOLUTION_SCALE, state)
	self:updateGraphicSettings()
end

-- Local values: data
function InGameMenuSettingsFrame:onClickPPAA(state, element)
	local v411_ = self.graphicSettingElements[element]
	g_settingsModel:setValue(v411_.settingsKey, state)
	g_settingsModel:applyCustomSettings()
	self:updateGraphicSettings()
end

-- Local values: foundSetting, settingName, name, index, setting, texts
function InGameMenuSettingsFrame:onClickScalingMode(state)
	local v414_ = g_settingsModel:getScalingModeTexts()[state]
	local v415_ = nil
	for v416_, v417_ in pairs(self.scalingModeNameToIndexMapping) do
		local v418_ = InGameMenuSettingsFrame.SCALING_MODES[v417_]
		if v416_ == v414_ then
			v415_ = v418_
		else
			g_settingsModel:setRawValue(v418_.name, v418_.enum.OFF)
		end
	end
	if v415_ ~= nil then
		g_settingsModel:setValue(v415_.name, 1)
		local v419_ = g_settingsModel:getTexts(v415_.name)
		self.scalingModeQualityElement:setTexts(v419_)
	end
	g_settingsModel:applyCustomSettings()
	if not getIsDRSAvailable() then
		g_settingsModel:setRawValue(SettingsModel.SETTING.DRS_QUALITY, DRSQuality.OFF)
	end
	self:updateGraphicSettings()
end

-- Local values: foundSetting, settingName, name, index, setting, settingsKey
function InGameMenuSettingsFrame:onClickScalingModeQuality(state)
	local v422_ = g_settingsModel:getScalingModeTexts()[self.scalingModeElement:getState()]
	local v423_ = nil
	for v424_, v425_ in pairs(self.scalingModeNameToIndexMapping) do
		local v426_ = InGameMenuSettingsFrame.SCALING_MODES[v425_]
		if v424_ == v422_ then
			v423_ = v426_
			break
		end
	end
	local v427_ = v423_.name
	g_settingsModel:setValue(v427_, state)
	g_settingsModel:applyCustomSettings()
	self:updateGraphicSettings()
end

-- Local values: isNativeXeSS, isXeSSActive, isDLSSActive, isNativeFSR3, isFSR30Active
function InGameMenuSettingsFrame:onClickFrameGeneration(state)
	local v429_ = g_settingsModel:getRawValue(SettingsModel.SETTING.POST_PROCESS_AA) == PostProcessAntiAliasing.XESS
	local v430_ = g_settingsModel:getRawValue(SettingsModel.SETTING.XESS) ~= XeSSQuality.OFF
	local v431_ = g_settingsModel:getRawValue(SettingsModel.SETTING.DLSS) ~= DLSSQuality.OFF
	local v432_ = g_settingsModel:getRawValue(SettingsModel.SETTING.POST_PROCESS_AA) == PostProcessAntiAliasing.FSR3
	local v433_ = g_settingsModel:getRawValue(SettingsModel.SETTING.FIDELITYFX_SR_30) ~= FidelityFxSR30Quality.OFF
	if v429_ or v430_ then
		g_settingsModel:setValue(SettingsModel.SETTING.XESS_FRAME_GENERATION, self.frameGenerationElement:getState() - 1)
	elseif v431_ then
		g_settingsModel:setValue(SettingsModel.SETTING.DLSS_FRAME_GENERATION, self.frameGenerationElement:getState() - 1)
	elseif v432_ or v433_ then
		g_settingsModel:setValue(SettingsModel.SETTING.FIDELITYFX_SR_30_FRAME_GENERATION, self.frameGenerationElement:getState() - 1)
	end
	g_settingsModel:applyCustomSettings()
	self:updateGraphicSettings()
end

function InGameMenuSettingsFrame:onClickDRSTargetFPS(state)
	g_settingsModel:setValue(SettingsModel.SETTING.DRS_TARGET_FPS, state)
	g_settingsModel:applyCustomSettings()
	self:updateGraphicSettings()
end

function InGameMenuSettingsFrame:onClickSharpness(state)
	g_settingsModel:setValue(SettingsModel.SETTING.SHARPNESS, state)
	g_settingsModel:applyCustomSettings()
	self:updateGraphicSettings()
end

function InGameMenuSettingsFrame:onClickShadingRateQuality(state)
	g_settingsModel:setValue(SettingsModel.SETTING.SHADING_RATE_QUALITY, state)
	g_settingsModel:applyCustomSettings()
	self:updateGraphicSettings()
end

function InGameMenuSettingsFrame:onClickTextureResolution(state)
	g_settingsModel:setValue(SettingsModel.SETTING.TEXTURE_RESOLUTION, state)
	g_settingsModel:applyCustomSettings()
	self:updateGraphicSettings()
end

function InGameMenuSettingsFrame:onClickShadowQuality(state)
	g_settingsModel:setValue(SettingsModel.SETTING.SHADOW_QUALITY, state)
	g_settingsModel:applyCustomSettings()
	self:updateGraphicSettings()
end

function InGameMenuSettingsFrame:onClickShadowDistanceQuality(state)
	g_settingsModel:setValue(SettingsModel.SETTING.SHADOW_DISTANCE_QUALITY, state)
	g_settingsModel:applyCustomSettings()
	self:updateGraphicSettings()
end

function InGameMenuSettingsFrame:onClickSoftShadows(state)
	g_settingsModel:setValue(SettingsModel.SETTING.SOFT_SHADOWS, state)
	g_settingsModel:applyCustomSettings()
	self:updateGraphicSettings()
end

function InGameMenuSettingsFrame:onClickShaderQuality(state)
	g_settingsModel:setValue(SettingsModel.SETTING.SHADER_QUALITY, state)
	g_settingsModel:applyCustomSettings()
	self:updateGraphicSettings()
end

function InGameMenuSettingsFrame:onClickShadowMapFiltering(state)
	g_settingsModel:setValue(SettingsModel.SETTING.SHADOW_MAP_FILTERING, state)
	g_settingsModel:applyCustomSettings()
	self:updateGraphicSettings()
end

function InGameMenuSettingsFrame:onClickShadowMaxLights(state)
	g_settingsModel:setValue(SettingsModel.SETTING.MAX_LIGHTS, state)
	g_settingsModel:applyCustomSettings()
	self:updateGraphicSettings()
end

function InGameMenuSettingsFrame:onClickTerrainQuality(state)
	g_settingsModel:setValue(SettingsModel.SETTING.TERRAIN_QUALITY, state)
	g_settingsModel:applyCustomSettings()
	self:updateGraphicSettings()
end

function InGameMenuSettingsFrame:onClickObjectDrawDistance(state)
	g_settingsModel:setValue(SettingsModel.SETTING.OBJECT_DRAW_DISTANCE, state)
	g_settingsModel:applyCustomSettings()
	self:updateGraphicSettings()
end

function InGameMenuSettingsFrame:onClickFoliageDrawDistance(state)
	g_settingsModel:setValue(SettingsModel.SETTING.FOLIAGE_DRAW_DISTANCE, state)
	g_settingsModel:applyCustomSettings()
	self:updateGraphicSettings()
end

function InGameMenuSettingsFrame:onClickLODDistance(state)
	g_settingsModel:setValue(SettingsModel.SETTING.LOD_DISTANCE, state)
	g_settingsModel:applyCustomSettings()
	self:updateGraphicSettings()
end

function InGameMenuSettingsFrame:onClickTerrainLODDistance(state)
	g_settingsModel:setValue(SettingsModel.SETTING.TERRAIN_LOD_DISTANCE, state)
	g_settingsModel:applyCustomSettings()
	self:updateGraphicSettings()
end

function InGameMenuSettingsFrame:onClickFoliageLODDistance(state)
	g_settingsModel:setValue(SettingsModel.SETTING.FOLIAGE_LOD_DISTANCE, state)
	g_settingsModel:applyCustomSettings()
	self:updateGraphicSettings()
end

function InGameMenuSettingsFrame:onClickVolumeMeshTessellation(state)
	g_settingsModel:setValue(SettingsModel.SETTING.VOLUME_MESH_TESSELLATION, state)
	g_settingsModel:applyCustomSettings()
	self:updateGraphicSettings()
end

function InGameMenuSettingsFrame:onClickMaxTireTracks(state)
	g_settingsModel:setValue(SettingsModel.SETTING.MAX_TIRE_TRACKS, state)
	g_settingsModel:applyCustomSettings()
	self:updateGraphicSettings()
end

function InGameMenuSettingsFrame:onClickLightsProfile(state)
	g_settingsModel:setValue(SettingsModel.SETTING.LIGHTS_PROFILE, state + 1)
	g_settingsModel:applyCustomSettings()
	self:updateGraphicSettings()
end

function InGameMenuSettingsFrame:onClickRealBeaconLights(state)
	g_settingsModel:setValue(SettingsModel.SETTING.REAL_BEACON_LIGHTS, self.realBeaconLightsElement:getIsChecked())
	g_settingsModel:applyCustomSettings()
	self:updateGraphicSettings()
end

function InGameMenuSettingsFrame:onClickRealBeaconLightsConsole(state)
	g_settingsModel:setValue(SettingsModel.SETTING.REAL_BEACON_LIGHTS, self.realBeaconLightsElementConsole:getIsChecked())
	g_settingsModel:applyCustomSettings()
	self:updateGraphicSettings()
end

function InGameMenuSettingsFrame:onClickFoliageShadows(state)
	g_settingsModel:setValue(SettingsModel.SETTING.FOLIAGE_SHADOW, self.foliageShadowsElement:getIsChecked())
	g_settingsModel:applyCustomSettings()
	self:updateGraphicSettings()
end

function InGameMenuSettingsFrame:onClickMaxMirrors(state)
	g_settingsModel:setValue(SettingsModel.SETTING.MAX_MIRRORS, state)
	g_settingsModel:applyCustomSettings()
	self:updateGraphicSettings()
end

function InGameMenuSettingsFrame:onClickSSAOQuality(state)
	g_settingsModel:setValue(SettingsModel.SETTING.SSAO_QUALITY, state)
	g_settingsModel:applyCustomSettings()
	self:updateGraphicSettings()
end

function InGameMenuSettingsFrame:onClickAtmosphereQuality(state)
	g_settingsModel:setValue(SettingsModel.SETTING.ATMOSPHERE_QUALITY, state)
	g_settingsModel:applyCustomSettings()
	self:updateGraphicSettings()
end

function InGameMenuSettingsFrame:onClickCloudShadowsQuality(state)
	g_settingsModel:setValue(SettingsModel.SETTING.CLOUD_SHADOWS_QUALITY, self.cloudShadowsQualityElement:getIsChecked())
	g_settingsModel:applyCustomSettings()
	self:updateGraphicSettings()
end

function InGameMenuSettingsFrame:onClickResolutionScale3d(state)
	g_settingsModel:setValue(SettingsModel.SETTING.RESOLUTION_SCALE_3D, state)
	g_settingsModel:applyCustomSettings()
	self:updateGraphicSettings()
end

function InGameMenuSettingsFrame:onClickFovY(state)
	g_settingsModel:setValue(SettingsModel.SETTING.FOV_Y, state)
	g_settingsModel:applyCustomSettings()
	self:updateGraphicSettings()
end

function InGameMenuSettingsFrame:onClickFovYPlayerFirstPerson(state)
	g_settingsModel:setValue(SettingsModel.SETTING.FOV_Y_PLAYER_FIRST_PERSON, state)
	g_settingsModel:applyCustomSettings()
	self:updateGraphicSettings()
end

function InGameMenuSettingsFrame:onClickFovYPlayerThirdPerson(state)
	g_settingsModel:setValue(SettingsModel.SETTING.FOV_Y_PLAYER_THIRD_PERSON, state)
	g_settingsModel:applyCustomSettings()
	self:updateGraphicSettings()
end

function InGameMenuSettingsFrame:onClickLockedIcon() end

function InGameMenuSettingsFrame:onFocusLockedIcon(icon)
	self.graphicSettingsLayout:scrollToMakeElementVisible(icon)
end

function InGameMenuSettingsFrame:onApplyDeadzoneChanges()
	g_settingsModel:applyChanges(SettingsModel.SETTING_CLASS.SAVE_ALL)
	self:updateButtons()
end

function InGameMenuSettingsFrame:onSwitchDevice()
	g_settingsModel:nextDevice()
	self:updateDeadzoneView()
end

-- Local values: _, barInfo, device, gamepadIndex, deadzone, sensitivity, neutralInput, value, bar, boxSize
function InGameMenuSettingsFrame:updateGamepadInputStates()
	for _, v495_ in pairs(self.stateBars) do
		local v496_ = g_settingsModel.deviceSettings[g_settingsModel.currentDevice].device.internalId
		local v497_ = g_settingsModel:getCurrentDeviceDeadzoneValue(v495_.axisIndex)
		local v498_ = g_settingsModel:getCurrentDeviceSensitivityValue(v495_.axisIndex)
		local v499_ = g_inputBinding:getGamepadAxisValue(v496_, v495_.axisIndex, "", 0, v497_) * v498_
		local v500_ = math.clamp(v499_, -1, 1)
		local v501_ = v495_.element.elements[1]
		local v502_ = v495_.element.absSize[1]
		local v503_ = math.abs(v500_) * v502_ * 0.5
		local v504_ = 2 * g_pixelSizeX
		v501_:setSize((math.max(v503_, v504_)))
		if v500_ < 0 then
			v501_:setPosition((1 - math.abs(v500_)) * v502_ * 0.5)
		else
			v501_:setPosition(v502_ * 0.5)
		end
		v495_.element:updateAbsolutePosition()
	end
end

function InGameMenuSettingsFrame:onAxisUpDown(actionName, value)
	g_gui:notifyControls(InputAction.MENU_AXIS_UP_DOWN, value)
end

function InGameMenuSettingsFrame:onAxisLeftRight(actionName, value)
	g_gui:notifyControls(InputAction.MENU_AXIS_LEFT_RIGHT, value)
end

function InGameMenuSettingsFrame:updateController()
	self.numOfGamepads = getNumOfGamepads()
	g_settingsModel:initDeviceSettings()
	self:updateDeadzoneView()
	self:updateButtons()
end

-- Local values: name, firstOptionElement, addSectionHeader, i, isMouse, sensitivityTemplate, optionElement, hasHeadTracking, isKeyboardAvailable, isHeadTrackingVisible, sensitivityTemplate, optionElement, device, gamepadIndex, axis, hasDeadzone, hasSensitiviy, label, title, deadzoneTemplate, optionElement, sensitivityTemplate, optionElement, isAlternate, _, container
function InGameMenuSettingsFrame:updateDeadzoneView()
	local v509_ = g_settingsModel:getCurrentDeviceName()
	if v509_ == InputDevice.DEFAULT_DEVICE_NAMES.KB_MOUSE_DEFAULT then
		v509_ = g_i18n:getText("ui_mouse")
	elseif g_i18n:hasText(v509_) then
		v509_ = g_i18n:getText(v509_)
	end
	self.deadzoneTitleElement:setText(string.format("%s: %s", g_i18n:getText("ui_deviceConfiguration"), v509_))
	local function v515_(p510_, p511_)
		-- upvalues: (copy) self
		local v512_ = self.sectionTemplate:clone(self.deadzoneLayout)
		v512_:getDescendantByName("title"):setText(p510_)
		local v513_ = v512_:getDescendantByName("box")
		v513_:setVisible(p511_ ~= nil)
		if p511_ ~= nil then
			local v514_ = self.stateBars
			table.insert(v514_, {
				["element"] = v513_,
				["axisIndex"] = p511_
			})
		end
	end
	local v516_ = nil
	for v517_ = #self.deadzoneLayout.elements, 1, -1 do
		self.deadzoneLayout.elements[v517_]:delete()
		self.deadzoneLayout.elements[v517_] = nil
	end
	self.stateBars = {}
	local v518_ = g_settingsModel:getIsDeviceMouse()
	local v519_
	if v518_ then
		v515_(g_i18n:getText("ui_mouse"))
		v519_ = self.sensitivityTemplate:clone(self.deadzoneLayout).elements[1]
		v519_:setTexts(g_settingsModel:getSensitivityTexts())
		v519_:setState(g_settingsModel:getMouseSensitivityValue())
		function v519_.onClickCallback(_, p520_)
			-- upvalues: (copy) self
			g_settingsModel:setMouseSensitivity(p520_)
			self:updateButtons()
		end
		if v516_ ~= nil then
			v519_ = v516_
		end
	else
		v519_ = v516_
	end
	local v521_ = g_gameSettings:getValue(GameSettings.SETTING.IS_HEAD_TRACKING_ENABLED)
	if v521_ then
		v521_ = isHeadTrackingAvailable()
	end
	local v522_ = getIsKeyboardAvailable()
	if v521_ then
		v521_ = v518_ or not v522_
	end
	local v523_
	if v521_ then
		v515_(g_i18n:getText("setting_headTracking"))
		v523_ = self.sensitivityTemplate:clone(self.deadzoneLayout).elements[1]
		v523_:setTexts(g_settingsModel:getHeadTrackingSensitivityTexts())
		v523_:setState(g_settingsModel:getHeadTrackingSensitivityValue())
		function v523_.onClickCallback(_, p524_)
			-- upvalues: (copy) self
			g_settingsModel:setHeadTrackingSensitivity(p524_)
			self:updateButtons()
		end
		if v519_ ~= nil then
			v523_ = v519_
		end
	else
		v523_ = v519_
	end
	if not v518_ then
		local v525_ = g_settingsModel.deviceSettings[g_settingsModel.currentDevice].device.internalId
		for v_u_526_ = 0, Input.MAX_NUM_AXES - 1 do
			local v527_ = g_settingsModel:getDeviceHasAxisDeadzone(v_u_526_)
			local v528_ = g_settingsModel:getDeviceHasAxisSensitivity(v_u_526_)
			if v527_ or v528_ then
				local v529_ = getGamepadAxisLabel(v_u_526_, v525_)
				local v530_ = string.format(g_i18n:getText("setting_gamepadAxis"), v_u_526_ + 1)
				if v529_ ~= "" then
					v530_ = v530_ .. " (" .. v529_ .. ")"
				end
				v515_(v530_, v_u_526_)
				local v531_
				if v527_ then
					v531_ = self.deadzoneTemplate:clone(self.deadzoneLayout).elements[1]
					v531_:setTexts(g_settingsModel:getDeadzoneTexts())
					v531_:setState(g_settingsModel:getDeviceAxisDeadzoneValue(v_u_526_))
					function v531_.onClickCallback(_, p532_)
						-- upvalues: (copy) v_u_526_, (copy) self
						g_settingsModel:setDeviceDeadzoneValue(v_u_526_, p532_)
						self:updateButtons()
					end
					if v523_ ~= nil then
						v531_ = v523_
					end
				else
					v531_ = v523_
				end
				if v528_ then
					v523_ = self.sensitivityTemplate:clone(self.deadzoneLayout).elements[1]
					v523_:setTexts(g_settingsModel:getSensitivityTexts())
					v523_:setState(g_settingsModel:getDeviceAxisSensitivityValue(v_u_526_))
					function v523_.onClickCallback(_, p533_)
						-- upvalues: (copy) v_u_526_, (copy) self
						g_settingsModel:setDeviceSensitivityValue(v_u_526_, p533_)
						self:updateButtons()
					end
					if v531_ ~= nil then
						v523_ = v531_
					end
				else
					v523_ = v531_
				end
			end
		end
	end
	self.deadzoneLayout:scrollTo(0, true)
	local v534_ = true
	for _, v535_ in pairs(self.deadzoneLayout.elements) do
		if v535_.name == "sectionHeader" then
			v534_ = true
		elseif v535_:getIsVisible() then
			local v536_ = SettingsScreen.COLOR_ALTERNATING[v534_]
			v535_:setImageColor(nil, unpack(v536_))
			v534_ = not v534_
		end
	end
	self.deadzoneLayout:invalidateLayout()
	if v523_ ~= nil then
		self.deadzoneLayout:scrollToMakeElementVisible(v523_)
		FocusManager:setFocus(v523_)
		FocusManager:linkElements(self.subCategoryPaging, FocusManager.TOP, self.deadzoneLayout:findLastFocusable(true))
		FocusManager:linkElements(self.subCategoryPaging, FocusManager.BOTTOM, self.deadzoneLayout:findFirstFocusable(true))
		v523_.forceFocusScrollToTop = true
	end
end

function InGameMenuSettingsFrame:getNumberOfSections(list)
	return #self.controlsData
end

-- Local values: key
function InGameMenuSettingsFrame:getTitleForSectionHeader(list, section)
	local v540_ = self.controlsData[section].name
	return g_i18n:convertText(v540_)
end

function InGameMenuSettingsFrame:getNumberOfItemsInSection(list, section)
	return #self.controlsData[section]
end

-- Local values: actionBinding, i, dataIndex, bindingColumnIndex, binding, deviceId, id, columnBinding, glyph, button, hasIcon, _, keyName, oldFocusEnterFunc, oldFocusLeaveFunc, oldFocusEnterFuncButton
function InGameMenuSettingsFrame:populateCellForItemInSection(list, section, index, cell)
	local v548_ = self.controlsData[section][index]
	cell:getAttribute("actionName"):setText(v548_.displayName)
	for v_u_549_ = 1, 3 do
		local v550_ = v_u_549_ + self.dataRowOffset
		local v551_ = nil
		local v_u_552_
		if v550_ - 3 > 0 then
			local v553_ = self.gamepads[v550_ - 3].deviceId
			v_u_552_ = v550_
			for v554_, v555_ in pairs(v548_.columnBindings) do
				if v555_.deviceId == v553_ then
					v551_ = v555_
					v550_ = v554_
					break
				end
			end
		else
			v551_ = v548_.columnBindings[v550_]
			v_u_552_ = v550_
		end
		local v_u_556_ = cell:getAttribute("actionGlyph" .. v_u_549_)
		local v_u_557_ = cell:getAttribute("actionButton" .. v_u_549_)
		v_u_556_:setActions({ v548_.action.name }, nil, nil, nil, v551_)
		local v558_ = false
		if v_u_556_.glyphElement ~= nil then
			for _, v559_ in pairs(v_u_556_.glyphElement.actionNames) do
				if v_u_556_.glyphElement.keyNames[v559_] ~= nil and v_u_556_.glyphElement.keyNames[v559_][1] ~= "" then
					v558_ = true
				end
			end
		end
		local v560_
		if v551_ == nil then
			v560_ = false
		else
			v560_ = v558_
		end
		v_u_556_:setVisible(v560_)
		if v558_ then
			v_u_557_:setText("")
		else
			v_u_557_:setText(v548_.columnTexts[v550_])
		end
		local v_u_561_ = v_u_556_.onFocusEnter
		function v_u_556_.onFocusEnter()
			-- upvalues: (copy) v_u_561_, (copy) v_u_556_
			v_u_561_(v_u_556_)
			v_u_556_.glyphElement:setButtonGlyphColor(SettingsControlsFrame.COLOR.BLACK)
		end
		local v_u_562_ = v_u_556_.onFocusLeave
		function v_u_556_.onFocusLeave(self)
			-- upvalues: (copy) v_u_562_, (copy) v_u_556_
			v_u_562_(v_u_556_)
			if v_u_556_.glyphElement ~= nil then
				v_u_556_.glyphElement:setButtonGlyphColor(SettingsControlsFrame.COLOR.GREEN)
			end
		end
		local v_u_563_ = v_u_557_.onFocusEnter
		function v_u_557_.onFocusEnter()
			-- upvalues: (copy) v_u_563_, (copy) v_u_557_, (copy) list, (copy) cell, (copy) self, (copy) v_u_549_
			v_u_563_(v_u_557_)
			list:makeCellVisible(cell.sectionIndex, cell.indexInSection)
			self.currentFocusCell = cell
			local v564_ = self
			local v565_ = self
			local v566_ = cell.sectionIndex
			local v567_ = cell.indexInSection
			v564_.currentFocusSection = v566_
			v565_.currentFocusIndex = v567_
			self["headerText" .. 1]:setSelected(v_u_549_ == 1)
			self["headerText" .. 2]:setSelected(v_u_549_ == 2)
			self["headerText" .. 3]:setSelected(v_u_549_ == 3)
		end
		function v_u_557_.shouldFocusChange(_, p568_)
			-- upvalues: (copy) cell, (copy) self, (copy) v_u_552_, (copy) list, (copy) v_u_549_
			if g_gui:getIsDialogVisible() then
				return false
			end
			local v569_ = cell.sectionIndex
			local v570_ = cell.indexInSection
			if v569_ == nil then
				v569_ = self.currentFocusSection
				v570_ = self.currentFocusIndex
			end
			if p568_ == FocusManager.LEFT then
				if v_u_552_ == 1 then
					return false
				end
				if v_u_552_ == 1 + self.dataRowOffset then
					self.dataRowOffset = self.dataRowOffset - 1
					self.controlsList:reloadData()
					self:updateListHeaderNames()
					return false
				end
			elseif p568_ == FocusManager.RIGHT then
				if v_u_552_ == self.numTotalDevices then
					return false
				end
				if v_u_552_ == 3 + self.dataRowOffset then
					self.dataRowOffset = self.dataRowOffset + 1
					self.controlsList:reloadData()
					self:updateListHeaderNames()
					return false
				end
			else
				if p568_ == FocusManager.TOP then
					local v571_ = v570_ - 1
					if v571_ == 0 then
						v569_ = v569_ - 1
						if v569_ == 0 then
							FocusManager:setFocus(self.subCategoryPaging)
							return false
						end
						v571_ = list.sections[v569_].numItems
					end
					list:makeCellVisible(v569_, v571_)
					local v572_ = self
					self.nextFocusSection = v569_
					v572_.nextFocusCell = v571_
					self.nextFocusedButtonName = "actionButton" .. v_u_549_
					return false
				end
				if p568_ == FocusManager.BOTTOM then
					local v573_ = v570_ + 1
					if list.sections[v569_].numItems < v573_ then
						v569_ = v569_ + 1
						if #list.sections < v569_ then
							FocusManager:setFocus(self.subCategoryPaging)
							return false
						end
						v573_ = 1
					end
					list:makeCellVisible(v569_, v573_)
					local v574_ = self
					self.nextFocusSection = v569_
					v574_.nextFocusCell = v573_
					self.nextFocusedButtonName = "actionButton" .. v_u_549_
					return false
				end
			end
			return true
		end
	end
	cell.actionBinding = v548_
end

function InGameMenuSettingsFrame:inputEvent(action, value, eventUsed)
	if action == InputAction.MENU_ACCEPT then
		return FocusManager:getFocusedElement() ~= self.buttonPauseGame
	else
		return eventUsed
	end
end

-- Local values: rowIndex, focusedButton, bindingControlsRowIndex, deviceInfoIndex
function InGameMenuSettingsFrame:onMenuAcceptUp(action, value, eventUsed)
	local v579_ = 1
	if self.currentFocusCell == nil then
		return false
	end
	local v580_ = FocusManager:getFocusedElement()
	local v581_ = (v580_.name == "actionButton2" and 2 or (v580_.name == "actionButton3" and 3 or v579_)) + self.dataRowOffset
	local v582_ = math.min(v581_, 4)
	self:onInputClicked(InGameMenuSettingsFrame.DEVICES[v582_].category, InGameMenuSettingsFrame.DEVICES[v582_].binding, self.currentFocusCell.actionBinding, v581_)
	return true
end

function InGameMenuSettingsFrame:onInputClicked(deviceCategory, bindingId, actionData, bindingControlsRowIndex)
	if self.controlsController:onClickInput(deviceCategory, bindingId, actionData, bindingControlsRowIndex) then
		self:showInputPrompt(deviceCategory, bindingId, actionData)
	end
end

-- Local values: wrappedCallback
function InGameMenuSettingsFrame:onClickDefaults()
	YesNoDialog.show(function(p589_)
		-- upvalues: (copy) self
		if p589_ then
			self.controlsController:loadDefaultSettings()
			self.userChangedInput = false
			self:assignDeviceTableData()
			self:updateButtons()
			InfoDialog.show(g_i18n:getText(SettingsControlsFrame.L10N_SYMBOL.DEFAULTS_LOADED), function(p590_)
				p590_.controlsList:makeCellVisible(1, 1)
				p590_.nextFocusSection = 1
				p590_.nextFocusCell = 1
				p590_.nextFocusedButtonName = "actionButton1"
			end, self, DialogElement.TYPE_INFO)
		end
	end, nil, g_i18n:getText(InGameMenuSettingsFrame.L10N_SYMBOL.LOAD_DEFAULTS), g_i18n:getText(InGameMenuSettingsFrame.L10N_SYMBOL.BUTTON_RESET))
end

function InGameMenuSettingsFrame:onControllerChanged()
	self.dataRowOffset = 0
	self.numTotalDevices = 3 + g_inputBinding.numActiveGamepads
	self.controlsList:makeCellVisible(1, 1, true)
	self.nextFocusSection = 1
	self.nextFocusCell = 1
	self.nextFocusedButtonName = "actionButton1"
	self:assignDeviceTableData()
	self.controlsMessageText = ""
	self:updateButtons()
end

function InGameMenuSettingsFrame:onClickNextRow()
	self.dataRowOffset = self.dataRowOffset + 1
	self.controlsList:reloadData()
	self:updateListHeaderNames()
end

function InGameMenuSettingsFrame:onClickPrevRow()
	self.dataRowOffset = self.dataRowOffset - 1
	self.controlsList:reloadData()
	self:updateListHeaderNames()
end
InGameMenuSettingsFrame.PROFILE = {
	["BUTTON_PAUSE"] = "fs25_settingsPauseButton",
	["BUTTON_UNPAUSE"] = "fs25_settingsUnpauseButton"
}
InGameMenuSettingsFrame.L10N_SYMBOL = {
	["DIRT_TEMPLATE"] = "setting_dirtState",
	["OFF"] = "ui_off",
	["BUY"] = "ui_buy",
	["USAGE_LOW"] = "setting_fuelUsageLow",
	["USAGE_DEFAULT"] = "setting_fuelUsageDefault",
	["USAGE_HIGH"] = "setting_fuelUsageHigh",
	["PAUSE"] = "input_PAUSE",
	["UNPAUSE"] = "ui_unpause",
	["DIFFICULTY_EASY"] = "button_easy",
	["DIFFICULTY_NORMAL"] = "button_normal",
	["DIFFICULTY_HARD"] = "button_hard",
	["SUBSTITUTION_PREFIX"] = "$l10n_",
	["BUTTON_SAVE_CONTROLS"] = "button_saveControls",
	["BUTTON_SAVE"] = "ui_saveSettings",
	["BUTTON_DEFAULTS"] = "button_defaults",
	["BUTTON_KEYBOARD"] = "ui_keyboard",
	["BUTTON_GAMEPAD"] = "ui_gamepad",
	["SAVE_CHANGES_PROMPT"] = "ui_saveChanges",
	["SAVED_CHANGES_INFO"] = "ui_savingFinished",
	["LOAD_DEFAULTS"] = "ui_loadDefaultSettings",
	["DEFAULTS_LOADED"] = "ui_loadedDefaultSettings",
	["KEY_PROMPT"] = "ui_pressKeyToMap",
	["MOUSE_PROMPT"] = "ui_pressMouseButtonToMap",
	["BUTTON_PROMPT"] = "ui_pressGamepadButtonToMap",
	["BUTTON_RESET"] = "button_reset",
	["BUTTON_APPLY"] = "button_apply",
	["SWITCH_DEVICE"] = "ui_switchDevice",
	["SAVING_FINISHED"] = "ui_savingFinished"
}
InGameMenuSettingsFrame.HEADER_SLICES = {
	[InGameMenuSettingsFrame.SUB_CATEGORY.GAME_SETTINGS] = "gui.icon_options_gameSettings2",
	[InGameMenuSettingsFrame.SUB_CATEGORY.GENERAL_SETTINGS] = "gui.icon_options_generalSettings2",
	[InGameMenuSettingsFrame.SUB_CATEGORY.GRAPHIC_SETTINGS] = "gui.icon_options_displaySettings",
	[InGameMenuSettingsFrame.SUB_CATEGORY.SERVER_SETTINGS] = "gui.icon_options_serverSettings",
	[InGameMenuSettingsFrame.SUB_CATEGORY.CONTROLS] = "gui.icon_options_keyboardControls",
	[InGameMenuSettingsFrame.SUB_CATEGORY.DEADZONE] = "gui.icon_options_device"
}
InGameMenuSettingsFrame.HEADER_TITLES = {
	[InGameMenuSettingsFrame.SUB_CATEGORY.GAME_SETTINGS] = "ui_ingameMenuGameSettingsGame",
	[InGameMenuSettingsFrame.SUB_CATEGORY.GENERAL_SETTINGS] = "ui_ingameMenuGameSettingsGeneral",
	[InGameMenuSettingsFrame.SUB_CATEGORY.GRAPHIC_SETTINGS] = "ui_inGameMenuGraphicSettings",
	[InGameMenuSettingsFrame.SUB_CATEGORY.SERVER_SETTINGS] = "button_serverSettings",
	[InGameMenuSettingsFrame.SUB_CATEGORY.CONTROLS] = "ui_inGameMenuControls",
	[InGameMenuSettingsFrame.SUB_CATEGORY.DEADZONE] = "ui_inGameMenuDevices"
}
InGameMenuSettingsFrame.COLOR_ALTERNATING = {
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
InGameMenuSettingsFrame.CONTROLS_UI_STRINGS = {
	[ControlsController.MESSAGE_CANNOT_MAP_KEY] = "ui_cannotMapKeyHere",
	[ControlsController.MESSAGE_CANNOT_MAP_MOUSE] = "ui_cannotMapMouseHere",
	[ControlsController.MESSAGE_CANNOT_MAP_CONTROLLER] = "ui_cannotMapGamepadHere",
	[ControlsController.MESSAGE_PROMPT_KEY] = "ui_pressKeyToMap",
	[ControlsController.MESSAGE_PROMPT_MOUSE] = "ui_pressMouseButtonToMap",
	[ControlsController.MESSAGE_PROMPT_CONTROLLER] = "ui_pressGamepadButtonToMap",
	[ControlsController.MESSAGE_PROMPT_CANCEL_DELETE] = "ui_pressESCToCancel",
	[ControlsController.MESSAGE_ENSURE_IN_NEUTRAL] = "ui_ensureAxisToMapInNeutral",
	[ControlsController.MESSAGE_SELECT_ACTION] = "ui_selectActionToRemap",
	[ControlsController.MESSAGE_CONFLICT_KEY] = "ui_keyAlreadyMapped",
	[ControlsController.MESSAGE_CONFLICT_MOUSE] = "ui_buttonAlreadyMapped",
	[ControlsController.MESSAGE_CONFLICT_BUTTON] = "ui_buttonAlreadyMapped",
	[ControlsController.MESSAGE_CONFLICT_AXIS] = "ui_axisAlreadyMapped",
	[ControlsController.MESSAGE_CONFLICT_BLOCKED_KEY] = "ui_blockedKeyCombination"
}
InGameMenuSettingsFrame.CONFLICT_MESSAGES = {
	[ControlsController.MESSAGE_CANNOT_MAP_KEY] = true,
	[ControlsController.MESSAGE_CANNOT_MAP_MOUSE] = true,
	[ControlsController.MESSAGE_CANNOT_MAP_CONTROLLER] = true,
	[ControlsController.MESSAGE_CONFLICT_KEY] = true,
	[ControlsController.MESSAGE_CONFLICT_MOUSE] = true,
	[ControlsController.MESSAGE_CONFLICT_BUTTON] = true,
	[ControlsController.MESSAGE_CONFLICT_AXIS] = true,
	[ControlsController.MESSAGE_CONFLICT_BLOCKED_KEY] = true
}
InGameMenuSettingsFrame.L10N_TEMPLATE_SYMBOL = {
	[ControlsController.MESSAGE_REMAPPED] = "ui_actionRemapped"
}
InGameMenuSettingsFrame.COLOR = {
	["BLACK"] = {
		0.00439,
		0.00478,
		0.00368,
		1
	},
	["GREEN"] = {
		0.22323,
		0.40724,
		0.00368,
		1
	}
}
InGameMenuSettingsFrame.DEVICES = {
	{
		["name"] = "ui_key1",
		["category"] = InputDevice.CATEGORY.KEYBOARD_MOUSE,
		["binding"] = ControlsController.BINDING_PRIMARY
	},
	{
		["name"] = "ui_key2",
		["category"] = InputDevice.CATEGORY.KEYBOARD_MOUSE,
		["binding"] = ControlsController.BINDING_SECONDARY
	},
	{
		["name"] = "ui_mouse",
		["category"] = InputDevice.CATEGORY.KEYBOARD_MOUSE,
		["binding"] = ControlsController.BINDING_TERTIARY
	},
	{
		["category"] = InputDevice.CATEGORY.GAMEPAD,
		["binding"] = ControlsController.BINDING_PRIMARY
	}
}
local v594_ = getFidelityFxSuperResolutionVersion() == 4 and "setting_fsr4" or "setting_fsr3"
InGameMenuSettingsFrame.SCALING_MODES = {
	[2] = {
		["name"] = SettingsModel.SETTING.FIDELITYFX_SR,
		["enum"] = FidelityFxSRQuality,
		["title"] = "setting_fsr1"
	},
	[3] = {
		["name"] = SettingsModel.SETTING.FIDELITYFX_SR_30,
		["enum"] = FidelityFxSR30Quality,
		["title"] = v594_
	},
	[4] = {
		["name"] = SettingsModel.SETTING.DLSS,
		["enum"] = DLSSQuality,
		["title"] = "setting_DLSS"
	},
	[5] = {
		["name"] = SettingsModel.SETTING.XESS,
		["enum"] = XeSSQuality,
		["title"] = "setting_xeSS"
	}
}
