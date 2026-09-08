-- Local values: InputBinding_mt, sortEventByOrderValue
InputBinding = {}
local InputBinding_mt = Class(InputBinding)
source("dataS/scripts/input/InputAction.lua")
source("dataS/scripts/input/InputDevice.lua")
source("dataS/scripts/input/Binding.lua")
source("dataS/scripts/input/InputEvent.lua")
InputBinding.version = 4
InputBinding.currentBindingVersion = 1
InputBinding.PATHS = {
	["DEFAULT_BINDINGS_KB_MOUSE"] = getAppBasePath() .. "profileTemplate/inputBindingDefault_KeyboardMouse.xml",
	["DEFAULT_BINDINGS_GAMEPAD"] = getAppBasePath() .. "profileTemplate/inputBindingDefault_Gamepad.xml",
	["DEFAULT_BINDINGS_JOYSTICK"] = getAppBasePath() .. "profileTemplate/inputBindingDefault_Joystick.xml",
	["DEFAULT_BINDINGS_WHEEL"] = getAppBasePath() .. "profileTemplate/inputBindingDefault_Wheel.xml",
	["DEFAULT_BINDINGS_WHEEL_AND_PANEL"] = getAppBasePath() .. "profileTemplate/inputBindingDefault_WheelAndPanel.xml",
	["DEFAULT_BINDINGS"] = getAppBasePath() .. "profileTemplate/inputBindingDefault_Gamepad.xml",
	["DEFAULT_BINDINGS_XBOX"] = getAppBasePath() .. "profileTemplate/inputBindingDefault_Gamepad.xml",
	["DEFAULT_BINDINGS_IOS"] = getAppBasePath() .. "profileTemplate/inputBindingDefault_Mobile.xml",
	["DEFAULT_BINDINGS_ANDROID"] = getAppBasePath() .. "profileTemplate/inputBindingDefault_Mobile.xml",
	["DEFAULT_BINDINGS_SWITCH"] = getAppBasePath() .. "profileTemplate/inputBindingDefault_Switch.xml",
	["DEFAULT_BINDINGS_SAITEK_WHEEL_AND_PANEL"] = getAppBasePath() .. "profileTemplate/inputBindingDefault_SaitekWheelAndPanel.xml",
	["DEFAULT_BINDINGS_SAITEK_WHEEL"] = getAppBasePath() .. "profileTemplate/inputBindingDefault_SaitekWheel.xml",
	["DEFAULT_BINDINGS_SAITEK_PANEL"] = getAppBasePath() .. "profileTemplate/inputBindingDefault_SaitekPanel.xml",
	["DEFAULT_BINDINGS_HORI_WHEEL"] = getAppBasePath() .. "profileTemplate/inputBindingDefault_HoriFarmingControllerWheel.xml",
	["DEFAULT_BINDINGS_HORI_PANEL"] = getAppBasePath() .. "profileTemplate/inputBindingDefault_HoriFarmingControllerPanel.xml",
	["DEFAULT_BINDINGS_THURSTMASTER_FARMJOYSTICK"] = getAppBasePath() .. "profileTemplate/inputBindingDefault_ThrustmasterFarmJoystick.xml",
	["DEFAULT_BINDINGS_THURSTMASTER_FARMJOYSTICK_PS"] = getAppBasePath() .. "profileTemplate/inputBindingDefault_ThrustmasterFarmJoystickConsole_PS.xml",
	["DEFAULT_BINDINGS_THURSTMASTER_FARMJOYSTICK_XBOX"] = getAppBasePath() .. "profileTemplate/inputBindingDefault_ThrustmasterFarmJoystickConsole.xml",
	["DEFAULT_BINDINGS_THURSTMASTER_FARMJOYSTICK_DUAL"] = getAppBasePath() .. "profileTemplate/inputBindingDefault_ThrustmasterFarmJoystickConsoleDual.xml",
	["DEFAULT_BINDINGS_MOZA_FARMING_CONTROL_SYSTEM"] = getAppBasePath() .. "profileTemplate/inputBindingDefault_MozaFarmingControlSystem.xml",
	["ACTION_DEFINITIONS"] = getAppBasePath() .. "dataS/inputActions.xml",
	["USER_BINDINGS"] = getUserProfileAppPath() .. "inputBinding.xml"
}
if Platform.isConsole then
	if Platform.isPlaystation then
		InputBinding.PATHS.DEFAULT_BINDINGS_THURSTMASTER_FARMJOYSTICK = getAppBasePath() .. "profileTemplate/inputBindingDefault_ThrustmasterFarmJoystickConsole_PS.xml"
		InputBinding.PATHS.DEFAULT_BINDINGS_THURSTMASTER_FARMJOYSTICK_DUAL = getAppBasePath() .. "profileTemplate/inputBindingDefault_ThrustmasterFarmJoystickConsoleDual_PS.xml"
	else
		InputBinding.PATHS.DEFAULT_BINDINGS_THURSTMASTER_FARMJOYSTICK = getAppBasePath() .. "profileTemplate/inputBindingDefault_ThrustmasterFarmJoystickConsole.xml"
		InputBinding.PATHS.DEFAULT_BINDINGS_THURSTMASTER_FARMJOYSTICK_DUAL = getAppBasePath() .. "profileTemplate/inputBindingDefault_ThrustmasterFarmJoystickConsoleDual.xml"
	end
end
InputBinding.THURSTMASTER_FARMJOYSTICK_LEFT_PRODUCT_IDS = {
	1052,
	1054,
	1088,
	1090,
	1092
}
InputBinding.THURSTMASTER_FARMJOYSTICK_RIGHT_PRODUCT_IDS = {
	1051,
	1053,
	1055,
	1091
}
InputBinding.DEVICE_CATEGORY_DEFAULTS_PATHS = {
	[InputDevice.CATEGORY.GAMEPAD] = InputBinding.PATHS.DEFAULT_BINDINGS_GAMEPAD,
	[InputDevice.CATEGORY.JOYSTICK] = InputBinding.PATHS.DEFAULT_BINDINGS_JOYSTICK,
	[InputDevice.CATEGORY.WHEEL] = InputBinding.PATHS.DEFAULT_BINDINGS_WHEEL,
	[InputDevice.CATEGORY.FARMWHEEL] = InputBinding.PATHS.DEFAULT_BINDINGS_SAITEK_WHEEL,
	[InputDevice.CATEGORY.FARMPANEL] = InputBinding.PATHS.DEFAULT_BINDINGS_SAITEK_PANEL,
	[InputDevice.CATEGORY.UNKNOWN] = InputBinding.PATHS.DEFAULT_BINDINGS_GAMEPAD,
	[InputDevice.CATEGORY.WHEEL_AND_PANEL] = InputBinding.PATHS.DEFAULT_BINDINGS_WHEEL_AND_PANEL,
	[InputDevice.CATEGORY.FARMWHEEL_AND_PANEL] = InputBinding.PATHS.DEFAULT_BINDINGS_SAITEK_WHEEL_AND_PANEL,
	[InputDevice.CATEGORY.FARMWHEEL_HORI] = InputBinding.PATHS.DEFAULT_BINDINGS_HORI_WHEEL,
	[InputDevice.CATEGORY.FARMPANEL_HORI] = InputBinding.PATHS.DEFAULT_BINDINGS_HORI_PANEL,
	[InputDevice.CATEGORY.FARMJOYSTICK_THRUSTMASTER] = InputBinding.PATHS.DEFAULT_BINDINGS_THURSTMASTER_FARMJOYSTICK,
	[InputDevice.CATEGORY.FARMJOYSTICK_THRUSTMASTER_DUAL] = InputBinding.PATHS.DEFAULT_BINDINGS_THURSTMASTER_FARMJOYSTICK_DUAL,
	[InputDevice.CATEGORY.FARMPANEL_MOZA] = InputBinding.PATHS.DEFAULT_BINDINGS_MOZA_FARMING_CONTROL_SYSTEM
}
InputBinding.DEVICE_CATEGORY_DEFAULT_LOAD_ORDER = {
	InputDevice.CATEGORY.FARMWHEEL_AND_PANEL,
	InputDevice.CATEGORY.WHEEL_AND_PANEL,
	InputDevice.CATEGORY.FARMJOYSTICK_THRUSTMASTER_DUAL,
	InputDevice.CATEGORY.FARMJOYSTICK_THRUSTMASTER,
	InputDevice.CATEGORY.FARMWHEEL,
	InputDevice.CATEGORY.FARMWHEEL_HORI,
	InputDevice.CATEGORY.WHEEL,
	InputDevice.CATEGORY.GAMEPAD,
	InputDevice.CATEGORY.JOYSTICK,
	InputDevice.CATEGORY.FARMPANEL,
	InputDevice.CATEGORY.FARMPANEL_HORI,
	InputDevice.CATEGORY.FARMPANEL_MOZA
}
InputBinding.INPUTTYPE_NONE = 0
InputBinding.INPUTTYPE_KEYBOARD = 1
InputBinding.INPUTTYPE_MOUSE_BUTTON = 2
InputBinding.INPUTTYPE_MOUSE_WHEEL = 3
InputBinding.INPUTTYPE_MOUSE_AXIS = 4
InputBinding.INPUTTYPE_GAMEPAD = 5
InputBinding.INPUTTYPE_GAMEPAD_AXIS = 6
InputBinding.MOUSE_AXIS_NONE = 0
InputBinding.MOUSE_AXIS_X = 1
InputBinding.MOUSE_AXIS_Y = 2
InputBinding.SYMBOL_AFFIX_POSITIVE = "_1"
InputBinding.SYMBOL_AFFIX_NEGATIVE = "_2"
InputBinding.MOUSE_AXES = {
	["AXIS_X"] = Input.AXIS_X,
	["AXIS_Y"] = Input.AXIS_Y,
	["AXIS_X+"] = Input.AXIS_X,
	["AXIS_Y+"] = Input.AXIS_Y,
	["AXIS_X-"] = Input.AXIS_X,
	["AXIS_Y-"] = Input.AXIS_Y
}
InputBinding.MOUSE_AXIS_NAMES = {
	[Input.AXIS_X] = "AXIS_X",
	[Input.AXIS_Y] = "AXIS_Y"
}
InputBinding.MOUSE_BUTTONS = {
	["MOUSE_BUTTON_LEFT"] = Input.MOUSE_BUTTON_LEFT,
	["MOUSE_BUTTON_RIGHT"] = Input.MOUSE_BUTTON_RIGHT,
	["MOUSE_BUTTON_MIDDLE"] = Input.MOUSE_BUTTON_MIDDLE,
	["MOUSE_BUTTON_WHEEL_UP"] = Input.MOUSE_BUTTON_WHEEL_UP,
	["MOUSE_BUTTON_WHEEL_DOWN"] = Input.MOUSE_BUTTON_WHEEL_DOWN,
	["MOUSE_BUTTON_X1"] = Input.MOUSE_BUTTON_X1,
	["MOUSE_BUTTON_X2"] = Input.MOUSE_BUTTON_X2
}
InputBinding.MOUSE_WHEEL = {
	[Input.MOUSE_BUTTON_WHEEL_UP] = true,
	[Input.MOUSE_BUTTON_WHEEL_DOWN] = true
}
InputBinding.MOUSE_BUTTON_NAMES = {
	[Input.MOUSE_BUTTON_LEFT] = "MOUSE_BUTTON_LEFT",
	[Input.MOUSE_BUTTON_RIGHT] = "MOUSE_BUTTON_RIGHT",
	[Input.MOUSE_BUTTON_MIDDLE] = "MOUSE_BUTTON_MIDDLE",
	[Input.MOUSE_BUTTON_WHEEL_UP] = "MOUSE_BUTTON_WHEEL_UP",
	[Input.MOUSE_BUTTON_WHEEL_DOWN] = "MOUSE_BUTTON_WHEEL_DOWN",
	[Input.MOUSE_BUTTON_X1] = "MOUSE_BUTTON_X1",
	[Input.MOUSE_BUTTON_X2] = "MOUSE_BUTTON_X2"
}
InputBinding.GAMEPAD_DPAD = {
	[Input.BUTTON_16] = true,
	[Input.BUTTON_17] = true,
	[Input.BUTTON_18] = true,
	[Input.BUTTON_19] = true
}
InputBinding.COMBO_MASK_CONSOLE_COMMAND_1 = 1
InputBinding.COMBO_MASK_CONSOLE_COMMAND_2 = 2
InputBinding.COMBO_MASK_CONSOLE_COMMAND_3 = 4
InputBinding.COMBO_MASK_MOUSE_COMMAND_1 = 1
InputBinding.COMBO_MASK_MOUSE_COMMAND_2 = 2
InputBinding.COMBO_MASK_MOUSE_COMMAND_3 = 4
InputBinding.COMBO_MASK_MOUSE_COMMAND_4 = 8
InputBinding.GAMEPAD_COMBOS = {
	[InputAction.CONSOLE_ALT_COMMAND_BUTTON] = {
		["mask"] = InputBinding.COMBO_MASK_CONSOLE_COMMAND_1,
		["controls"] = InputAction.CONSOLE_ALT_COMMAND_BUTTON
	},
	[InputAction.CONSOLE_ALT_COMMAND2_BUTTON] = {
		["mask"] = InputBinding.COMBO_MASK_CONSOLE_COMMAND_2,
		["controls"] = InputAction.CONSOLE_ALT_COMMAND2_BUTTON
	},
	[InputAction.CONSOLE_ALT_COMMAND3_BUTTON] = {
		["mask"] = InputBinding.COMBO_MASK_CONSOLE_COMMAND_3,
		["controls"] = InputAction.CONSOLE_ALT_COMMAND3_BUTTON
	}
}
InputBinding.ORDERED_GAMEPAD_COMBOS = { InputBinding.GAMEPAD_COMBOS[InputAction.CONSOLE_ALT_COMMAND_BUTTON], InputBinding.GAMEPAD_COMBOS[InputAction.CONSOLE_ALT_COMMAND3_BUTTON], InputBinding.GAMEPAD_COMBOS[InputAction.CONSOLE_ALT_COMMAND2_BUTTON] }
InputBinding.MOUSE_COMBOS = {
	[InputAction.MOUSE_ALT_COMMAND_BUTTON] = {
		["mask"] = InputBinding.COMBO_MASK_MOUSE_COMMAND_1,
		["controls"] = InputAction.MOUSE_ALT_COMMAND_BUTTON
	},
	[InputAction.MOUSE_ALT_COMMAND2_BUTTON] = {
		["mask"] = InputBinding.COMBO_MASK_MOUSE_COMMAND_2,
		["controls"] = InputAction.MOUSE_ALT_COMMAND2_BUTTON
	},
	[InputAction.MOUSE_ALT_COMMAND3_BUTTON] = {
		["mask"] = InputBinding.COMBO_MASK_MOUSE_COMMAND_3,
		["controls"] = InputAction.MOUSE_ALT_COMMAND3_BUTTON
	},
	[InputAction.MOUSE_ALT_COMMAND4_BUTTON] = {
		["mask"] = InputBinding.COMBO_MASK_MOUSE_COMMAND_4,
		["controls"] = InputAction.MOUSE_ALT_COMMAND4_BUTTON
	}
}
InputBinding.ORDERED_MOUSE_COMBOS = {
	InputBinding.MOUSE_COMBOS[InputAction.MOUSE_ALT_COMMAND_BUTTON],
	InputBinding.MOUSE_COMBOS[InputAction.MOUSE_ALT_COMMAND3_BUTTON],
	InputBinding.MOUSE_COMBOS[InputAction.MOUSE_ALT_COMMAND4_BUTTON],
	InputBinding.MOUSE_COMBOS[InputAction.MOUSE_ALT_COMMAND2_BUTTON]
}
InputBinding.ALL_COMBOS = { InputBinding.GAMEPAD_COMBOS, InputBinding.MOUSE_COMBOS }
InputBinding.GAMEPAD_COMBO_BINDINGS = {
	[InputAction.CONSOLE_ALT_COMMAND_BUTTON] = { Input.buttonIdToIdName[Input.BUTTON_5] },
	[InputAction.CONSOLE_ALT_COMMAND2_BUTTON] = { Input.buttonIdToIdName[Input.BUTTON_6] },
	[InputAction.CONSOLE_ALT_COMMAND3_BUTTON] = { Input.buttonIdToIdName[Input.BUTTON_5], Input.buttonIdToIdName[Input.BUTTON_6] }
}
InputBinding.GAMEPAD_COMBO_AXIS_NAMES = {
	[Input.buttonIdToIdName[Input.BUTTON_5]] = true,
	[Input.buttonIdToIdName[Input.BUTTON_6]] = true
}
InputBinding.MOUSE_COMBO_BINDINGS = {
	[InputAction.MOUSE_ALT_COMMAND_BUTTON] = { InputBinding.MOUSE_BUTTON_NAMES[Input.MOUSE_BUTTON_LEFT] },
	[InputAction.MOUSE_ALT_COMMAND2_BUTTON] = { InputBinding.MOUSE_BUTTON_NAMES[Input.MOUSE_BUTTON_RIGHT] },
	[InputAction.MOUSE_ALT_COMMAND3_BUTTON] = { InputBinding.MOUSE_BUTTON_NAMES[Input.MOUSE_BUTTON_MIDDLE] },
	[InputAction.MOUSE_ALT_COMMAND4_BUTTON] = { InputBinding.MOUSE_BUTTON_NAMES[Input.MOUSE_BUTTON_LEFT], InputBinding.MOUSE_BUTTON_NAMES[Input.MOUSE_BUTTON_RIGHT] }
}
InputBinding.MOUSE_COMBO_AXIS_NAMES = {
	[InputBinding.MOUSE_BUTTON_NAMES[Input.MOUSE_BUTTON_LEFT]] = true,
	[InputBinding.MOUSE_BUTTON_NAMES[Input.MOUSE_BUTTON_RIGHT]] = true,
	[InputBinding.MOUSE_BUTTON_NAMES[Input.MOUSE_BUTTON_MIDDLE]] = true
}
InputBinding.MOUSE_MOVE_BASE_FACTOR = 75
InputBinding.MOUSE_MOVE_LIMIT = 4
InputBinding.MOUSE_MOTION_SCALE_X_DEFAULT = 1
InputBinding.MOUSE_MOTION_SCALE_Y_DEFAULT = 1
InputBinding.MOUSE_WHEEL_INPUT_FACTOR = 3
InputBinding.INPUT_MODE_CHANGE_THRESHOLD = 0.2
InputBinding.INPUT_MODE_CHANGE_MIN_INTERVAL = GS_IS_MOBILE_VERSION and 0 or 5000
InputBinding.KB_MOUSE_INTERNAL_ID = 255
InputBinding.ROOT_CONTEXT_NAME = "ROOT"
InputBinding.NO_REGISTRATION_CONTEXT = {
	["actionEvents"] = {},
	["name"] = "",
	["previousContextName"] = "",
	["eventOrderCounter"] = 0
}
InputBinding.NO_ACTION_EVENTS = {}
InputBinding.MESSAGE_PARAM_INPUT_MODE = {
	[GS_INPUT_HELP_MODE_KEYBOARD] = { GS_INPUT_HELP_MODE_KEYBOARD },
	[GS_INPUT_HELP_MODE_GAMEPAD] = { GS_INPUT_HELP_MODE_GAMEPAD },
	[GS_INPUT_HELP_MODE_TOUCH] = { GS_INPUT_HELP_MODE_TOUCH }
}

-- Upvalues: InputBinding_mt
-- Local values: self
function InputBinding.new(modManager, messageCenter, isConsoleVersion)
	-- upvalues: (copy) InputBinding_mt
	local v5_ = InputBinding_mt
	local v6_ = setmetatable({}, v5_)
	v6_.debugEnabled = false
	v6_.debugContextEnabled = false
	v6_.debugRegisteredActions = false
	v6_.modManager = modManager
	v6_.messageCenter = messageCenter
	v6_.isConsoleVersion = isConsoleVersion
	v6_.devicesByInternalId = {}
	v6_.devicesByCategory = {}
	v6_.deviceIdToInternal = {}
	v6_.internalToDeviceId = {}
	v6_.engineDeviceIdCounts = {}
	v6_.internalIdToEngineDeviceId = {}
	v6_.newlyConnectedDevices = {}
	v6_.missingDevices = {}
	v6_.actions = {}
	v6_.nameActions = {}
	v6_.originalActionBindings = nil
	v6_.activeDeviceBindingsBuffer = {}
	v6_.mouseMovementX = 0
	v6_.mouseMovementY = 0
	v6_.accumMouseMovementX = 0
	v6_.accumMouseMovementY = 0
	v6_.actionEvents = {}
	v6_.displayActionEvents = {}
	v6_.events = {}
	v6_.eventOrder = {}
	v6_.loadedBindings = {}
	v6_.activeBindings = {}
	v6_.eventBindings = {}
	v6_.linkedBindings = {}
	v6_.currentContextName = InputBinding.ROOT_CONTEXT_NAME
	v6_.contexts = {
		[InputBinding.ROOT_CONTEXT_NAME] = {
			["previousContextName"] = "",
			["actionEvents"] = {},
			["eventOrderCounter"] = 0
		}
	}
	v6_.registrationContext = InputBinding.NO_REGISTRATION_CONTEXT
	v6_.comboInputAxisMasks = {}
	v6_.comboInputActions = {}
	v6_.comboInputBindings = {}
	v6_.pressedMouseComboMask = 0
	v6_.pressedGamepadComboMask = 0
	v6_.needUpdateAbort = false
	v6_.eventChangeCallback = nil
	v6_.wrapMousePositionEnabled = false
	v6_.saveCursorX = 0.5
	v6_.saveCursorY = 0.5
	v6_.mouseMotionScaleX = 0.75
	v6_.mouseMotionScaleY = 0.75
	v6_.devicesToMigrateCategory = {}
	v6_.isInputCapturing = false
	v6_.gatherInputStoredMouseEvent = nil
	v6_.gatherInputStoredKeyEvent = nil
	v6_.gatherInputStoredUpdate = nil
	v6_.gamepadInputState = {}
	v6_.timeSinceLastInputHelpModeChange = InputBinding.INPUT_MODE_CHANGE_MIN_INTERVAL
	v6_.lastInputHelpMode = GS_INPUT_HELP_MODE_KEYBOARD
	if isConsoleVersion then
		v6_.lastInputHelpMode = GS_INPUT_HELP_MODE_GAMEPAD
	end
	v6_.lastInputMode = v6_.lastInputHelpMode
	v6_.inputHelpModeSetting = g_gameSettings:getValue(GameSettings.SETTING.INPUT_HELP_MODE)
	v6_.isGamepadEnabled = isConsoleVersion or g_gameSettings:getValue(GameSettings.SETTING.IS_GAMEPAD_ENABLED)
	messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.INPUT_HELP_MODE], v6_.onInputHelpModeSettingChange, v6_)
	messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.IS_GAMEPAD_ENABLED], v6_.onGamepadEnabledSettingChanged, v6_)
	v6_.settingsPath = nil
	v6_:assignPlatformBindingPaths()
	addConsoleCommand("gsInputDebug", "", "consoleCommandEnableInputDebug", v6_)
	addConsoleCommand("gsInputContextPrint", "", "consoleCommandPrintInputContext", v6_)
	addConsoleCommand("gsInputContextShow", "", "consoleCommandShowInputContext", v6_)
	addConsoleCommand("gsInputRegisteredActionsShow", "", "consoleCommandShowRegisteredActions", v6_)
	return v6_
end

function InputBinding:delete()
	g_messageCenter:unsubscribeAll(self)
end

-- Local values: xmlFileActionDefinitions, xmlFileInputBinding, k
function InputBinding:load()
	self:clearState()
	local v9_ = loadXMLFile("ActionDefinitions", InputBinding.PATHS.ACTION_DEFINITIONS)
	self:loadActions(v9_)
	delete(v9_)
	self:loadModActions()
	local v10_ = loadXMLFile("InputBindings", self.settingsPath)
	self.version = getXMLInt(v10_, "inputBinding#version") or 1
	self.mouseMotionScaleX = (getXMLFloat(v10_, "inputBinding#mouseSensitivityScaleX") or 1) * self.MOUSE_MOTION_SCALE_X_DEFAULT
	self.mouseMotionScaleY = (getXMLFloat(v10_, "inputBinding#mouseSensitivityScaleY") or 1) * self.MOUSE_MOTION_SCALE_Y_DEFAULT
	self:initializeGamepadMapping(v10_)
	self:loadActionBindingsFromXML(v10_, false, nil, nil, nil, true)
	self:upgradeBindingVersion(v10_)
	self:resolveBindingDevices()
	self:migrateDevicesCategory()
	delete(v10_)
	self:loadDefaultBindings()
	self:validateAndRepairComboActionBindings()
	self:storeComboInputMappings()
	self:assignComboMasks()
	self:assignActionPrimaryBindings()
	self:storeLinkedBindings()
	self:restoreInputContexts()
	self:notifyBindingChanges()
	self:refreshEventCollections()
	for v11_ in pairs(self.newlyConnectedDevices) do
		self.newlyConnectedDevices[v11_] = nil
	end
	self:checkDefaultInputExclusiveActionBindings()
end

-- Local values: xmlFile, categorySetsWithBindings, ignoredDevices, _, category, templatePath, xmlFileControllerTemplate, requiredCategorySet, _, category, templatePath, deviceId, _, gamepadName, xmlFileControllerTemplate, usedDevices
function InputBinding:loadDefaultBindings()
	if self.inputBindingPathTemplate ~= nil then
		local v13_ = loadXMLFile("DefaultKeyboardMouseBindings", self.inputBindingPathTemplate)
		self:loadActionBindingsFromXML(v13_, true, nil, nil, true, false)
		delete(v13_)
	end
	if self.numGamepads > 0 then
		local v14_ = self:getBindingCategorySet(self:getAllDeviceIdsWithBindings())
		local v15_ = self:getAllDeviceIdsWithoutBindings()
		for _, v16_ in ipairs(InputBinding.DEVICE_CATEGORY_DEFAULT_LOAD_ORDER) do
			if v14_[v16_] then
				local v17_ = InputBinding.DEVICE_CATEGORY_DEFAULTS_PATHS[v16_]
				local v18_ = loadXMLFile("ControllerTemplate", v17_)
				if v18_ ~= 0 then
					self:loadActionBindingsFromXML(v18_, true, nil, v15_, true, false)
					delete(v18_)
				end
			end
		end
		local v19_ = self:getBindingCategorySet(v15_)
		for _, v20_ in ipairs(InputBinding.DEVICE_CATEGORY_DEFAULT_LOAD_ORDER) do
			if v19_[v20_] then
				local v21_ = InputBinding.DEVICE_CATEGORY_DEFAULTS_PATHS[v20_]
				if v20_ == InputDevice.CATEGORY.FARMJOYSTICK_THRUSTMASTER and not Platform.isConsole then
					for v22_, _ in pairs(v15_) do
						local v23_ = getGamepadName(v22_)
						if string.startsWith(string.upper(v23_), "SIMTASK FARMSTICK X") then
							v21_ = InputBinding.PATHS.DEFAULT_BINDINGS_THURSTMASTER_FARMJOYSTICK_XBOX
							break
						end
						if string.startsWith(string.upper(v23_), "SIMTASK FARMSTICK P") then
							v21_ = InputBinding.PATHS.DEFAULT_BINDINGS_THURSTMASTER_FARMJOYSTICK_PS
							break
						end
					end
				end
				Logging.devInfo("Loading default input binding: %s", v21_)
				local v24_ = loadXMLFile("ControllerTemplate", v21_)
				if v24_ ~= 0 then
					self:loadActionBindingsFromXML(v24_, true, nil, self:getAllDevicesWithBindings(), false, false)
					delete(v24_)
				end
			end
		end
	end
	self:loadModBindingDefaults()
end

function InputBinding:onInputHelpModeSettingChange(newMode)
	self.inputHelpModeSetting = newMode
end

function InputBinding:onGamepadEnabledSettingChanged(isEnabled)
	self.isGamepadEnabled = isEnabled
end

-- Local values: categorySet, hasLeftFarmStick, hasRightFarmStick, deviceId, _, device, category, productId, hasWheel, hasFarmWheel, hasPanel
function InputBinding:getBindingCategorySet(deviceIds)
	local v31_ = {}
	local v32_ = false
	local v33_ = false
	for v34_, _ in pairs(deviceIds) do
		local v35_ = self.devicesByInternalId[v34_].category
		v31_[v35_] = true
		if v35_ == InputDevice.CATEGORY.FARMJOYSTICK_THRUSTMASTER then
			local v36_ = getGamepadProductId(v34_)
			v32_ = table.hasElement(InputBinding.THURSTMASTER_FARMJOYSTICK_LEFT_PRODUCT_IDS, v36_) and true or v32_
			if table.hasElement(InputBinding.THURSTMASTER_FARMJOYSTICK_RIGHT_PRODUCT_IDS, v36_) then
				v33_ = true
			end
		elseif v35_ == InputDevice.CATEGORY.FARMJOYSTICK_THRUSTMASTER_LEFT then
			v32_ = true
		end
	end
	local v37_ = v31_[InputDevice.CATEGORY.WHEEL] ~= nil
	local v38_ = v31_[InputDevice.CATEGORY.FARMWHEEL] ~= nil
	if (v37_ or v38_) and v31_[InputDevice.CATEGORY.FARMPANEL] ~= nil then
		v31_[InputDevice.CATEGORY.WHEEL] = nil
		v31_[InputDevice.CATEGORY.FARMWHEEL] = nil
		v31_[InputDevice.CATEGORY.FARMPANEL] = nil
		if v38_ then
			v31_[InputDevice.CATEGORY.FARMWHEEL_AND_PANEL] = true
		else
			v31_[InputDevice.CATEGORY.WHEEL_AND_PANEL] = true
		end
	end
	if v32_ and v33_ then
		v31_[InputDevice.CATEGORY.FARMJOYSTICK_THRUSTMASTER_DUAL] = true
	end
	return v31_
end

-- Local values: _, action, _, binding
function InputBinding:getDeviceHasAnyBindings(device)
	for _, v41_ in pairs(self.actions) do
		if InputBinding.GAMEPAD_COMBO_BINDINGS[v41_.name] == nil then
			for _, v42_ in pairs(v41_.bindings) do
				if v42_.deviceId == device.deviceId then
					return true
				end
			end
		end
	end
	return false
end

-- Local values: usedDevices, _, action, _, binding
function InputBinding:getAllDevicesWithBindings()
	local v44_ = {}
	for _, v45_ in pairs(self.actions) do
		if InputBinding.GAMEPAD_COMBO_BINDINGS[v45_.name] == nil then
			for _, v46_ in pairs(v45_.bindings) do
				v44_[v46_.deviceId] = true
			end
		end
	end
	return v44_
end

-- Local values: deviceIds, deviceId, device
function InputBinding:getAllDeviceIdsWithoutBindings()
	local v48_ = 0
	local v49_ = self.devicesByInternalId[v48_]
	local v50_ = {}
	while v49_ ~= nil do
		if not self:getDeviceHasAnyBindings(v49_) then
			v50_[v48_] = true
		end
		v48_ = v48_ + 1
		v49_ = self.devicesByInternalId[v48_]
	end
	return v50_
end

-- Local values: deviceIds, deviceId, device
function InputBinding:getAllDeviceIdsWithBindings()
	local v52_ = 0
	local v53_ = self.devicesByInternalId[v52_]
	local v54_ = {}
	while v53_ ~= nil do
		if self:getDeviceHasAnyBindings(v53_) then
			v54_[v52_] = true
		end
		v52_ = v52_ + 1
		v53_ = self.devicesByInternalId[v52_]
	end
	return v54_
end

function InputBinding:reloadModActions()
	self:load()
end

-- Local values: _, modDesc, xmlFile
function InputBinding:loadModActions()
	for _, v57_ in ipairs(self.modManager:getMods()) do
		local v58_ = loadXMLFile("InputBinding ModActions ModFile", v57_.modFile)
		if v58_ ~= 0 then
			self:loadActions(v58_, v57_.modName)
			delete(v58_)
		end
	end
end

-- Local values: _, modDesc, xmlFile
function InputBinding:loadModBindingDefaults()
	for _, v60_ in ipairs(self.modManager:getMods()) do
		local v61_ = loadXMLFile("InputBinding BindingDefaults ModFile", v60_.modFile)
		if v61_ ~= 0 then
			self:loadActionBindingsFromXML(v61_, true, v60_.modName, nil, true, false)
			delete(v61_)
		end
	end
end

function InputBinding:assignPlatformBindingPaths()
	if GS_PLATFORM_PLAYSTATION then
		self.settingsPath = InputBinding.PATHS.DEFAULT_BINDINGS
		return
	elseif GS_PLATFORM_XBOX then
		self.settingsPath = InputBinding.PATHS.DEFAULT_BINDINGS_XBOX
		return
	elseif GS_PLATFORM_SWITCH2 then
		self.settingsPath = InputBinding.PATHS.DEFAULT_BINDINGS
		return
	elseif GS_PLATFORM_ID == PlatformId.IOS then
		self.settingsPath = InputBinding.PATHS.DEFAULT_BINDINGS_IOS
		return
	elseif GS_PLATFORM_ID == PlatformId.ANDROID then
		self.settingsPath = InputBinding.PATHS.DEFAULT_BINDINGS_ANDROID
		return
	elseif GS_PLATFORM_SWITCH then
		self.settingsPath = InputBinding.PATHS.DEFAULT_BINDINGS_SWITCH
	else
		self.settingsPath = InputBinding.PATHS.USER_BINDINGS
		self.inputBindingPathTemplate = InputBinding.PATHS.DEFAULT_BINDINGS_KB_MOUSE
		self:overwriteSettingsWithDefault(false)
		if not self:checkSettingsIntegrity(self.settingsPath, self.inputBindingPathTemplate) then
			self:overwriteSettingsWithDefault(true)
		end
	end
end

function InputBinding:overwriteSettingsWithDefault(forceOverwrite)
	copyFile(self.inputBindingPathTemplate, self.settingsPath, forceOverwrite)
end

-- Local values: contextName, context, previousActionEvents, newActionEvents, oldAction, eventList, newAction
function InputBinding:restoreInputContexts()
	for v66_, v67_ in pairs(self.contexts) do
		local v68_ = v67_.actionEvents
		local v69_ = {}
		for v70_, v71_ in pairs(v68_) do
			v69_[self.nameActions[v70_.name]] = v71_
		end
		if v66_ == self.currentContextName then
			self.actionEvents = v69_
		end
		v67_.actionEvents = v69_
	end
end

function InputBinding:setShowMouseCursor(doShow, saveCursorPosition)
	self.saveCursorX = saveCursorPosition and (self.mousePosXLast or 0.5) or 0.5
	self.saveCursorY = saveCursorPosition and (self.mousePosYLast or 0.5) or 0.5
	self.mousePosXLastValid = self.mousePosXLast or self.mousePosXLastValid
	self.mousePosYLastValid = self.mousePosYLast or self.mousePosYLastValid
	self.mousePosXLast = nil
	self.mousePosYLast = nil
	setShowMouseCursor(doShow)
	self.wrapMousePositionEnabled = not doShow
end

function InputBinding:getShowMouseCursor()
	return not self.wrapMousePositionEnabled
end

-- Local values: helpMode, nonGamepadMode
function InputBinding:getInputHelpMode()
	local v77_ = GS_INPUT_HELP_MODE_GAMEPAD
	local v78_ = GS_IS_MOBILE_VERSION and GS_INPUT_HELP_MODE_TOUCH or GS_INPUT_HELP_MODE_KEYBOARD
	if self.isConsoleVersion then
		v78_ = v77_
	elseif self.isGamepadEnabled then
		if self.inputHelpModeSetting == GS_INPUT_HELP_MODE_AUTO then
			return self.lastInputHelpMode
		elseif self.numGamepads > 0 and self.inputHelpModeSetting == GS_INPUT_HELP_MODE_GAMEPAD then
			return GS_INPUT_HELP_MODE_GAMEPAD
		else
			return v78_
		end
	end
	return v78_
end

function InputBinding:getLastInputMode()
	if Platform.isMobile and self.lastInputMode == GS_INPUT_HELP_MODE_KEYBOARD then
		return GS_INPUT_HELP_MODE_TOUCH
	else
		return self.lastInputMode
	end
end

-- Local values: action
function InputBinding:validateActionEventParameters(actionName, targetObject, eventCallback, triggerUp, triggerDown, triggerAlways)
	if actionName == nil then
		Logging.devWarning("Tried registering an unknown action")
		printCallstack()
		return false
	elseif InputAction[actionName] == nil then
		Logging.devWarning("Tried registering an event for an unknown action: %s", actionName)
		return false
	elseif eventCallback then
		if triggerUp or (triggerDown or triggerAlways) then
			local v86_ = self.nameActions[actionName]
			return (v86_ == nil or v86_:getIsSupportedOnCurrentPlatform()) and true or false
		else
			Logging.devWarning("Tried registering an action event without any active trigger flags.")
			return false
		end
	else
		Logging.devWarning("Tried registering an action event without an event callback.")
		return false
	end
end

-- Local values: valid, actionEvents, eventOrderCounter, eventCollision, collidingAction, eventId, event, action, actionEventList, isFirstEventOnAction, _, regEvent
function InputBinding:registerActionEvent(actionName, targetObject, eventCallback, triggerUp, triggerDown, triggerAlways, startActive, callbackState, disableConflictingBindings, reportAnyDeviceCollision)
	local v98_ = self:validateActionEventParameters(actionName, targetObject, eventCallback, triggerUp, triggerDown, triggerAlways)
	local v99_ = self.actionEvents
	local v100_ = self.contexts[self.currentContextName].eventOrderCounter
	if self.registrationContext ~= InputBinding.NO_REGISTRATION_CONTEXT then
		v99_ = self.registrationContext.actionEvents
		v100_ = self.registrationContext.eventOrderCounter
	end
	if startActive and v98_ then
		local v101_, v102_ = self:checkEventCollision(actionName, disableConflictingBindings, reportAnyDeviceCollision)
		if v98_ then
			v98_ = not v101_
		end
		if v101_ then
			return false, "", v99_[v102_]
		end
	end
	local v103_ = ""
	if v98_ then
		local v104_ = InputEvent.new
		if triggerUp == nil then
			triggerUp = false
		end
		if triggerDown == nil then
			triggerDown = false
		end
		if triggerAlways == nil then
			triggerAlways = false
		end
		if startActive == nil then
			startActive = false
		end
		local v105_ = v104_(actionName, targetObject, eventCallback, triggerUp, triggerDown, triggerAlways, startActive, callbackState, v100_)
		local v106_ = self.nameActions[actionName]
		local v107_ = v99_[v106_]
		if v107_ == nil then
			v107_ = {}
			v99_[v106_] = v107_
		end
		local v108_ = #v107_ == 0
		for _, v109_ in ipairs(v107_) do
			if v109_.actionName == v105_.actionName and v109_:getTriggerCode() == v105_:getTriggerCode() then
				return false, v103_, { v109_ }
			end
		end
		table.insert(v107_, v105_)
		self.events[v105_.id] = v105_
		v103_ = v105_.id
		v105_.displayIsVisible = v108_
		v105_:initializeDisplayText(v106_)
		v105_:setIgnoreComboMask(v106_:getIgnoreComboMask())
		if self.registrationContext == InputBinding.NO_REGISTRATION_CONTEXT then
			self:refreshEventCollections()
			self.contexts[self.currentContextName].eventOrderCounter = v100_ + 1
		else
			self.registrationContext.eventOrderCounter = v100_ + 1
		end
	end
	return v98_, v103_, nil
end

-- Local values: testAction, testBindings, actionEvents, collidingAction, disabledBindings, otherAction, events, isSameCategory, isSelf, isEitherLocked, canConflict, otherHasActiveEvents, _, event, otherBindings, _, testBinding, _, otherBinding, hasCollision, _, binding
function InputBinding:checkEventCollision(actionName, disableConflictingBindings, reportAnyDeviceCollision)
	local v114_ = self.nameActions[actionName]
	if v114_ == nil then
		Logging.error("Unknown action name %q", actionName)
		return false, nil
	end
	local v115_ = v114_:getBindings()
	local v116_ = self.actionEvents
	if self.registrationContext ~= InputBinding.NO_REGISTRATION_CONTEXT then
		v116_ = self.registrationContext.actionEvents
	end
	local v117_ = nil
	local v118_ = nil
	for v119_, v120_ in pairs(v116_) do
		local v121_ = table.hasSetIntersection(v114_.categories, v119_.categories)
		local v122_ = v114_ == v119_
		local v123_ = v114_.isLocked or v119_.isLocked
		local v124_ = not v122_
		if v124_ then
			if v121_ then
				v121_ = not v123_
			end
		else
			v121_ = v124_
		end
		local v125_ = false
		for _, v126_ in pairs(v120_) do
			if v126_.isActive then
				v125_ = true
				break
			end
		end
		if v121_ and v125_ then
			local v127_ = v119_:getActiveBindings()
			for _, v128_ in pairs(v115_) do
				for _, v129_ in pairs(v127_) do
					if v128_:hasEventCollision(v129_) then
						if not disableConflictingBindings then
							return true, v119_
						end
						v114_:disableBinding(v128_)
						v117_ = v117_ or {}
						table.insert(v117_, v128_)
						v118_ = v119_
					end
				end
			end
		end
	end
	local v130_
	if v117_ and #v117_ > 0 then
		if reportAnyDeviceCollision == true then
			return true, v118_
		end
		if #v114_:getBindings() > 0 then
			v130_ = v114_:getNumActiveBindings() == 0
		else
			v130_ = false
		end
		if v130_ then
			for _, v131_ in pairs(v117_) do
				v114_:enableBinding(v131_)
			end
		end
	else
		v130_ = false
	end
	return v130_, v118_
end

-- Local values: createdNewContext, context
function InputBinding:beginActionEventsModification(inContextName, forceCreateNew)
	if inContextName == nil or inContextName == InputBinding.NO_REGISTRATION_CONTEXT.name then
		Logging.devWarning("Cannot begin action event registration with an empty context name.")
		printCallstack()
	else
		local v135_ = self.contexts[inContextName]
		local v136_
		if v135_ == nil or forceCreateNew then
			v135_ = self:createContext(inContextName)
			v136_ = true
		else
			v136_ = false
		end
		if self.debugEnabled then
			Logging.devInfo("[InputBinding] Beginning action events modification in context [%s]", inContextName)
		end
		self.registrationContext = v135_
		if v136_ then
			registerGlobalActionEvents(self)
		end
	end
end

function InputBinding:endActionEventsModification(ignoreCheck)
	if ignoreCheck or self.registrationContext ~= InputBinding.NO_REGISTRATION_CONTEXT then
		if self.debugEnabled then
			Logging.devInfo("[InputBinding] Ended action events modification in context [%s]", self.registrationContext.name)
		end
		self.registrationContext = InputBinding.NO_REGISTRATION_CONTEXT
		self:refreshEventCollections()
	else
		Logging.devWarning("Called InputBinding:endActionEventsModification() when the registration context is already reset. Check call order.")
		printCallstack()
	end
end

function InputBinding:refreshEventCollections()
	self.needsRefresh = true
	if self.markIt then
		self.markIt = false
	end
end

-- Local values: action, events, _, event, bindings, firstControllerBindingIndex, firstGamepadBindingIndex, _, binding, device, inlineModifierButtons
function InputBinding:storeDisplayActionEvents()
	self.displayActionEvents = {}
	for v141_, v142_ in pairs(self.actionEvents) do
		for _, v143_ in ipairs(v142_) do
			local v144_ = v141_:getActiveBindings()
			if v143_.isActive and (v143_.displayIsVisible and #v144_ > 0) then
				local v145_ = Binding.MAX_ALTERNATIVES_GAMEPAD + 1
				local v146_ = Binding.MAX_ALTERNATIVES_GAMEPAD + 1
				for _, v147_ in pairs(v144_) do
					local v148_ = self.devicesByInternalId[v147_.internalDeviceId]
					if v147_.isActive and v148_.category ~= InputDevice.CATEGORY.KEYBOARD_MOUSE then
						if v148_.category == InputDevice.CATEGORY.GAMEPAD and v147_.index < v146_ then
							v146_ = v147_.index
						elseif v147_.index < v145_ then
							v145_ = v147_.index
						end
					end
				end
				local v149_ = v145_ < v146_
				local v150_ = self.displayActionEvents
				table.insert(v150_, {
					["action"] = v141_,
					["event"] = v143_,
					["inlineModifierButtons"] = v149_
				})
				break
			end
		end
	end
end
local function v_u_153_(p151_, p152_)
	if p151_.orderValue == p152_.orderValue then
		return p151_.id < p152_.id
	else
		return p151_.orderValue < p152_.orderValue
	end
end

-- Upvalues: sortEventByOrderValue
-- Local values: k, k, k, action, eventList, bindings, _, event, activeEventBindings, _, binding
function InputBinding:storeEventBindings()
	-- upvalues: (copy) v_u_153_
	for v155_ in pairs(self.activeBindings) do
		self.activeBindings[v155_] = nil
	end
	for v156_ in pairs(self.eventBindings) do
		self.eventBindings[v156_] = nil
	end
	for v157_ in pairs(self.eventOrder) do
		self.eventOrder[v157_] = nil
	end
	for v158_, v159_ in pairs(self.actionEvents) do
		local v160_ = v158_:getActiveBindings()
		for _, v161_ in pairs(v159_) do
			if v161_.isActive then
				local v162_ = self.eventBindings[v161_]
				if not v162_ then
					v162_ = {}
					self.eventBindings[v161_] = v162_
				end
				for _, v163_ in ipairs(v160_) do
					if v163_.isActive then
						table.insert(v162_, v163_)
						self.activeBindings[v163_] = v163_
					end
				end
				local v164_ = self.eventOrder
				table.insert(v164_, v161_)
			end
		end
	end
	table.sort(self.eventOrder, v_u_153_)
	self.needUpdateAbort = true
end

-- Local values: actionEvents, action, eventList, i, event
function InputBinding:iterateEvents(processingFunction)
	local v167_ = self.actionEvents
	if self.registrationContext ~= InputBinding.NO_REGISTRATION_CONTEXT then
		v167_ = self.registrationContext.actionEvents
	end
	for v168_, v169_ in pairs(v167_) do
		for v170_ = #v169_, 1, -1 do
			if processingFunction(v169_[v170_], v168_.name, v169_, v170_) then
				return
			end
		end
	end
end

-- Local values: eventBindings, _, binding
function InputBinding:removeEventInternal(event, eventList, index)
	if event.triggerAlways then
		local v175_ = self.eventBindings[event]
		if v175_ ~= nil then
			for _, v176_ in pairs(v175_) do
				self:neutralizeEventBindingInput(event, v176_)
			end
		end
	end
	self.events[event.id] = nil
	table.remove(eventList, index)
end

-- Local values: hasChange, removeById
function InputBinding:removeActionEvent(eventId)
	local v_u_179_ = false
	self:iterateEvents(function(p180_, _, p181_, p182_)
		-- upvalues: (copy) eventId, (copy) self, (ref) v_u_179_
		if p180_.id == eventId then
			self:removeEventInternal(p180_, p181_, p182_)
			v_u_179_ = true
			return true
		end
	end)
	if v_u_179_ then
		self:refreshEventCollections()
	end
end

-- Local values: hasChange, removeByName
function InputBinding:removeActionEventsByActionName(actionName)
	local v_u_185_ = false
	self:iterateEvents(function(p186_, _, p187_, p188_)
		-- upvalues: (copy) actionName, (copy) self, (ref) v_u_185_
		if p186_.actionName == actionName then
			self:removeEventInternal(p186_, p187_, p188_)
			v_u_185_ = true
		end
	end)
	if v_u_185_ then
		self:refreshEventCollections()
	end
end

-- Local values: hasChange, removeByTarget
function InputBinding:removeActionEventsByTarget(targetObject)
	local v_u_191_ = false
	self:iterateEvents(function(p192_, _, p193_, p194_)
		-- upvalues: (copy) targetObject, (copy) self, (ref) v_u_191_
		if p192_.targetObject == targetObject then
			self:removeEventInternal(p192_, p193_, p194_)
			v_u_191_ = true
		end
	end)
	if v_u_191_ then
		self:refreshEventCollections()
	end
end

-- Local values: event
function InputBinding:getActionEventsHasBinding(actionEventId)
	local v197_ = self.events[actionEventId]
	if v197_ == nil then
		return false
	else
		return self:getNumActiveBindings(v197_.actionName) > 0
	end
end

function InputBinding:getDisplayActionEvents()
	return self.displayActionEvents
end

-- Local values: event, hasChange
function InputBinding:setActionEventText(eventId, actionText)
	local v202_ = self.events[eventId]
	local v203_
	if v202_ then
		v203_ = v202_.contextDisplayText ~= actionText
		v202_.contextDisplayText = actionText
	else
		v203_ = false
	end
	if v203_ then
		self:refreshEventCollections()
	end
end

-- Local values: event, hasChange
function InputBinding:setActionEventIcon(eventId, iconName)
	local v207_ = self.events[eventId]
	local v208_
	if v207_ then
		v208_ = v207_.contextDisplayIconName ~= iconName
		v207_.contextDisplayIconName = iconName
	else
		v208_ = false
	end
	if v208_ then
		self:refreshEventCollections()
	end
end

-- Local values: event, hasChange
function InputBinding:setActionEventTextVisibility(eventId, isVisible)
	local v212_ = self.events[eventId]
	local v213_
	if v212_ then
		v213_ = v212_.displayIsVisible ~= isVisible
		v212_.displayIsVisible = isVisible
	else
		v213_ = false
	end
	if v213_ then
		self:refreshEventCollections()
	end
end

-- Local values: event, hasChange
function InputBinding:setActionEventTextPriority(eventId, priority)
	local v217_ = self.events[eventId]
	local v218_
	if v217_ and type(priority) == "number" then
		v218_ = v217_.displayPriority ~= priority
		v217_.displayPriority = priority
	else
		v218_ = false
	end
	if v218_ then
		self:refreshEventCollections()
	end
end

-- Local values: event
function InputBinding:setActionEventActive(eventId, isActive)
	self:setEventActive(self.events[eventId], isActive)
end

-- Local values: hasChange
function InputBinding:setEventActive(event, isActive)
	local v225_
	if event then
		v225_ = event.isActive ~= isActive
		event.isActive = isActive
		if v225_ then
			if isActive then
				self:checkEventCollision(event.actionName, true)
			else
				self.nameActions[event.actionName]:resetActiveBindings()
			end
		end
	else
		v225_ = false
	end
	if v225_ then
		self:refreshEventCollections()
	end
end

-- Local values: hasChange, setActiveByTarget
function InputBinding:setActionEventsActiveByTarget(targetObject, isActive)
	local v_u_229_ = false
	self:iterateEvents(function(p230_)
		-- upvalues: (copy) targetObject, (ref) v_u_229_, (copy) isActive, (copy) self
		if p230_.targetObject == targetObject then
			v_u_229_ = p230_.isActive ~= isActive
			p230_.isActive = isActive
			if v_u_229_ then
				if isActive then
					self:checkEventCollision(p230_.actionName, true)
					return
				end
				self.nameActions[p230_.actionName]:resetActiveBindings()
			end
		end
	end)
	if v_u_229_ then
		self:refreshEventCollections()
	end
end

-- Local values: comboMaskGamepad, comboMaskMouse, actionName, maskControls, comboActionBinding, actionName, maskControls
function InputBinding:getComboCommandPressedMask()
	local v232_ = 0
	local v233_ = 0
	if self.numGamepads > 0 then
		for v234_, v235_ in pairs(InputBinding.GAMEPAD_COMBOS) do
			local v236_ = self.comboInputBindings[v234_]
			if v236_ ~= nil and (v236_.isPressed and v232_ < v235_.mask) then
				v232_ = v235_.mask
			end
		end
	end
	if not self.isConsoleVersion then
		for v237_, v238_ in pairs(InputBinding.MOUSE_COMBOS) do
			if self.comboInputBindings[v237_].isPressed and v233_ < v238_.mask then
				v233_ = v238_.mask
			end
		end
	end
	return v232_, v233_
end

-- Local values: comboSet, comboActionName
function InputBinding:getComboActionNameForAxisSet(modifierAxisSet)
	for v241_, v242_ in pairs(self.comboInputActions) do
		if table.equalSets(v241_, modifierAxisSet) then
			return v242_
		end
	end
	return nil
end

function InputBinding:getInternalIdByDeviceId(deviceId)
	return self.deviceIdToInternal[deviceId]
end

function InputBinding:getDeviceByInternalId(internalDeviceId)
	return self.devicesByInternalId[internalDeviceId]
end

-- Local values: device, internalId
function InputBinding:getDeviceById(deviceId)
	local v249_ = self.deviceIdToInternal[deviceId]
	local v250_
	if v249_ == nil then
		v250_ = nil
	else
		v250_ = self.devicesByInternalId[v249_]
	end
	return v250_
end

function InputBinding:getMissingDeviceById(deviceId)
	return self.missingDevices[deviceId]
end

function InputBinding:getHasMissingDevices()
	return next(self.missingDevices) ~= nil
end

-- Local values: needCurrentInputModeNotification, needInputHelpModeNotification
function InputBinding:assignLastInputHelpMode(inputHelpMode, force)
	local v257_ = self.lastInputMode ~= inputHelpMode and true or force
	self.lastInputMode = inputHelpMode
	if v257_ then
		self:notifyInputModeChange(inputHelpMode, false)
	end
	if inputHelpMode == GS_INPUT_HELP_MODE_KEYBOARD or self.timeSinceLastInputHelpModeChange >= InputBinding.INPUT_MODE_CHANGE_MIN_INTERVAL then
		local v258_ = self.lastInputHelpMode ~= inputHelpMode and true or force
		self.lastInputHelpMode = inputHelpMode
		if v258_ then
			self:notifyInputModeChange(inputHelpMode, true)
		end
		if v258_ or inputHelpMode == GS_INPUT_HELP_MODE_KEYBOARD then
			self.timeSinceLastInputHelpModeChange = 0
		end
	end
	if GS_IS_MOBILE_VERSION and self.lastInputHelpMode == GS_INPUT_HELP_MODE_KEYBOARD then
		self.lastInputHelpMode = GS_INPUT_HELP_MODE_TOUCH
	end
end

function InputBinding:keyEvent(unicode, sym, modifier, isDown)
	self:assignLastInputHelpMode(GS_INPUT_HELP_MODE_KEYBOARD)
end

function InputBinding:mouseEvent(posX, posY, isDown, isUp, button)
	if isDown then
		self:assignLastInputHelpMode(GS_IS_MOBILE_VERSION and GS_INPUT_HELP_MODE_TOUCH or GS_INPUT_HELP_MODE_KEYBOARD)
	end
	if self.mousePosXLast == nil or self.mousePosYLast == nil then
		self.mousePosXLast = posX
		self.mousePosYLast = posY
	end
	self.mouseMovementX = self.mouseMotionScaleX * (posX - self.mousePosXLast)
	self.mouseMovementY = self.mouseMotionScaleY * (posY - self.mousePosYLast) / g_screenAspectRatio
	self.mousePosXLast = posX
	self.mousePosYLast = posY
	self.accumMouseMovementX = self.accumMouseMovementX + self.mouseMovementX
	self.accumMouseMovementY = self.accumMouseMovementY + self.mouseMovementY
	if isDown then
		self.mouseButtonLast = button
		self.mouseButtonStateLast = true
	elseif isUp then
		self.mouseButtonLast = Input.MOUSE_BUTTON_NONE
		self.mouseButtonStateLast = false
	end
end

function InputBinding:touchEvent(posX, posY, isDown, isUp, touchId)
	self:assignLastInputHelpMode(GS_INPUT_HELP_MODE_TOUCH)
end

function InputBinding:getMousePosition()
	return self.mousePosXLast or self.saveCursorX, self.mousePosYLast or self.saveCursorY
end

function InputBinding:getMouseButtonState()
	return self.mouseButtonLast, self.mouseButtonStateLast
end

-- Local values: _, action, bindings, clonedBindings, _, binding
function InputBinding:startBindingChanges()
	self.originalActionBindings = {}
	for _, v270_ in pairs(self.actions) do
		local v271_ = v270_:getBindings()
		local v272_ = {}
		for _, v273_ in pairs(v271_) do
			table.insert(v272_, v273_:clone())
		end
		self.originalActionBindings[v270_] = v272_
	end
end

function InputBinding:commitBindingChanges()
	self.originalActionBindings = nil
	self:assignComboMasks()
	self:assignActionPrimaryBindings()
	self:notifyBindingChanges()
	self:refreshEventCollections()
end

-- Local values: newLoadedBindings, _, bindings, _, binding, loadedBinding, oldLoadedBinding, action, originalBindings, _, originalBinding, newBinding
function InputBinding:rollbackBindingChanges()
	local v276_ = {}
	for _, v277_ in pairs(self.originalActionBindings) do
		for _, v280_ in pairs(v277_) do
			v280_:makeId()
			local v279_ = v276_[v280_.id]
			if v279_ == nil then
				v276_[v280_.id] = v280_
			else
				local v280_ = v279_
			end
			local v281_ = self.loadedBindings[v280_.id]
			if v281_ ~= nil then
				v280_:copyInputStateFrom(v281_)
			end
		end
	end
	self.loadedBindings = v276_
	for v282_, v283_ in pairs(self.originalActionBindings) do
		v282_:clearBindings()
		for _, v284_ in pairs(v283_) do
			v282_:addBinding(self.loadedBindings[v284_.id])
		end
	end
	self:storeEventBindings()
end

-- Local values: cbInput, cbAbort, cbDelete
function InputBinding:startInputCapture(isKeyboard, isMouse, callbackTarget, callbackState, inputCallback, abortCallback, deleteCallback)
	self.isInputCapturing = true
	self.gatherInputStoredMouseEvent = mouseEvent
	self.gatherInputStoredKeyEvent = keyEvent
	self.gatherInputStoredUpdate = update
	local function v297_(p293_, p294_, p295_, p296_)
		-- upvalues: (copy) callbackTarget, (copy) inputCallback, (copy) callbackState
		if callbackTarget then
			inputCallback(callbackTarget, p293_, p294_, p295_, p296_, callbackState)
		else
			inputCallback(p294_, p293_, p295_, p296_, callbackState)
		end
	end
	local function v298_()
		-- upvalues: (copy) callbackTarget, (copy) abortCallback
		if callbackTarget then
			abortCallback(callbackTarget)
		else
			abortCallback()
		end
	end
	local function v299_()
		-- upvalues: (copy) callbackTarget, (copy) deleteCallback, (copy) callbackState
		if callbackTarget then
			deleteCallback(callbackTarget, callbackState)
		else
			deleteCallback(callbackState)
		end
	end
	if isKeyboard then
		self:captureKeyboardInput(v298_, v299_, v297_)
		function mouseEvent() end
		function update()
			setTextWidthScale(g_textWidthScale)
		end
		return
	elseif isMouse then
		self:captureKeyboardInput(v298_, v299_)
		self:captureMouseInput(v297_)
		function update()
			setTextWidthScale(g_textWidthScale)
		end
	else
		self:captureKeyboardInput(v298_, v299_)
		self:captureGamepadInput(v297_)
		function mouseEvent() end
	end
end

-- Local values: device
function InputBinding:captureKeyboardInput(abortCallback, deleteCallback, inputCallback)
	local v_u_303_ = InputDevice.DEFAULT_DEVICE_NAMES.KB_MOUSE_DEFAULT
	function keyEvent(_, p304_, _, p305_)
		-- upvalues: (copy) abortCallback, (copy) deleteCallback, (copy) inputCallback, (copy) v_u_303_
		local v306_ = Input.keyIdToIdName[p304_]
		if abortCallback and p304_ == Input.KEY_esc then
			abortCallback()
			return
		elseif deleteCallback and p304_ == Input.KEY_backspace then
			deleteCallback()
		elseif inputCallback and v306_ then
			inputCallback(v_u_303_, v306_, p305_ and 1 or 0)
		end
	end
end

-- Local values: dragStartX, dragStartY, draggingButton, startX, startY, device, axisNameX, axisNameY
function InputBinding:captureMouseInput(callback)
	local v_u_309_ = nil
	local v_u_310_ = nil
	local v_u_311_ = nil
	local v_u_312_ = self.mousePosXLast or self.mousePosXLastValid
	local v_u_313_ = self.mousePosYLast or self.mousePosYLastValid
	local v_u_314_ = InputDevice.DEFAULT_DEVICE_NAMES.KB_MOUSE_DEFAULT
	local v_u_315_ = InputBinding.MOUSE_AXIS_NAMES[Input.AXIS_X]
	local v_u_316_ = InputBinding.MOUSE_AXIS_NAMES[Input.AXIS_Y]
	callback(v_u_314_, v_u_315_, false, 0)
	callback(v_u_314_, v_u_316_, false, 0)
	function mouseEvent(p317_, p318_, p319_, p320_, p321_)
		-- upvalues: (ref) v_u_311_, (ref) v_u_309_, (ref) v_u_310_, (copy) callback, (copy) v_u_314_, (copy) v_u_315_, (copy) v_u_316_, (ref) v_u_312_, (ref) v_u_313_
		local v322_ = Input.mouseButtonIdToIdName[p321_]
		if p321_ == Input.MOUSE_BUTTON_WHEEL_UP or p321_ == Input.MOUSE_BUTTON_WHEEL_DOWN then
			callback(v_u_314_, v322_, 1)
			callback(v_u_314_, v322_, 0)
		elseif p319_ then
			if v_u_311_ == nil then
				v_u_311_ = p321_
				v_u_309_ = p317_
				v_u_310_ = p318_
				callback(v_u_314_, v_u_315_, 0)
				callback(v_u_314_, v_u_316_, 0)
			end
			callback(v_u_314_, v322_, 1)
		elseif p320_ then
			local v323_ = p321_ == v_u_311_
			callback(v_u_314_, v322_, 0)
			if v323_ then
				v_u_311_ = nil
				v_u_309_ = nil
				v_u_310_ = nil
			end
		end
		if v_u_311_ ~= nil then
			v_u_312_ = p317_
			v_u_313_ = p318_
		end
		local v324_ = v_u_312_
		local v325_ = v_u_313_
		if v_u_311_ ~= nil then
			v324_ = v_u_309_
			v325_ = v_u_310_
		end
		local v326_ = p317_ - v324_
		local v327_ = p318_ - v325_
		callback(v_u_314_, v_u_315_, v326_)
		callback(v_u_314_, v_u_316_, v327_)
	end
end

-- Local values: gamepadInitStates
function InputBinding:captureGamepadInput(callback)
	local v_u_330_ = {}
	function update(_)
		-- upvalues: (copy) v_u_330_, (copy) self, (copy) callback
		setTextWidthScale(g_textWidthScale)
		local v331_ = getNumOfGamepads()
		if v331_ ~= #v_u_330_ then
			for v332_, _ in pairs(v_u_330_) do
				v_u_330_[v332_] = nil
			end
			for v333_ = 1, v331_ do
				local v334_ = {
					["axes"] = {},
					["buttons"] = {}
				}
				local v335_ = v_u_330_
				table.insert(v335_, v334_)
				for v336_ = 1, Input.MAX_NUM_BUTTONS do
					if getInputButton(v336_ - 1, v333_ - 1) > 0 then
						v334_.buttons[v336_] = true
					end
				end
				for v337_ = 1, Input.MAX_NUM_AXES do
					v334_.axes[v337_] = getInputAxis(v337_ - 1, v333_ - 1)
					if Input.isHalfAxis(v337_ - 1) then
						v334_.axes[v337_] = (1 - v334_.axes[v337_]) * 0.5
					end
				end
			end
		end
		for v338_ = 1, v331_ do
			local v339_ = v338_ - 1
			local v340_ = self.internalToDeviceId[v339_]
			if v340_ ~= nil then
				local v341_ = v_u_330_[v338_]
				local v342_ = {}
				for v343_ = 1, Input.MAX_NUM_AXES do
					local v344_ = getInputAxis(v343_ - 1, v339_)
					local v345_ = v341_.axes[v343_]
					if Input.isHalfAxis(v343_ - 1) then
						v344_ = (1 - v344_) * 0.5
					end
					callback(v340_, Input.axisIdToIdName[v343_ - 1], v344_, v345_)
				end
				for v346_ = 1, Input.MAX_NUM_BUTTONS do
					local v347_ = Input.buttonIdToIdName[v346_ - 1]
					if getInputButton(v346_ - 1, v339_) > 0 then
						if not v341_.buttons[v346_] then
							v342_[v346_ - 1] = true
							callback(v340_, v347_, 1, 0)
						end
					else
						v341_.buttons[v346_] = nil
						callback(v340_, v347_, 0, 0)
					end
				end
			end
		end
	end
end

function InputBinding:stopInputGathering()
	if self.isInputCapturing then
		mouseEvent = self.gatherInputStoredMouseEvent
		keyEvent = self.gatherInputStoredKeyEvent
		update = self.gatherInputStoredUpdate
		self.gatherInputCallbackFunction = nil
		self.gatherInputCallbackObject = nil
		self.gatherInputStoredMouseEvent = nil
		self.gatherInputStoredKeyEvent = nil
		self.gatherInputStoredUpdate = nil
		self.isInputCapturing = false
	end
end

function InputBinding:restoreDefaultBindings()
	copyFile(self.inputBindingPathTemplate, self.settingsPath, true)
	self:load()
	self:refresh()
end

-- Local values: defaultInputMode
function InputBinding:clearState()
	self.loadedBindings = {}
	self.eventBindings = {}
	self.nameActions = {}
	self.actions = {}
	self.missingDevices = {}
	self.gamepadInputState = {}
	local v351_ = GS_INPUT_HELP_MODE_KEYBOARD
	if self.isConsoleVersion then
		v351_ = GS_INPUT_HELP_MODE_GAMEPAD
	elseif GS_IS_MOBILE_VERSION then
		v351_ = GS_INPUT_HELP_MODE_TOUCH
	end
	self.lastInputMode = v351_
	self.lastInputHelpMode = v351_
end

-- Local values: rootPath, i18n
function InputBinding:loadActions(xmlFile, modName)
	local v355_ = g_i18n
	local v356_
	if modName then
		v355_ = _G[modName].g_i18n
		v356_ = "modDesc.actions"
	else
		v356_ = "actions"
	end
	self:loadActionsFromXMLPath(xmlFile, v356_, v355_, modName)
end

-- Local values: actionIndex, actionPath, action, inputSymbol, modPart, mod, isComboAction, isLocked, needLocalization, symbolPositive, symbolNegative, i, action2
function InputBinding:loadActionsFromXMLPath(xmlFile, rootPath, i18n, modName)
	local v362_ = 0
	while true do
		local v363_ = rootPath .. string.format(".action(%d)", v362_)
		if not hasXMLProperty(xmlFile, v363_) then
			return
		end
		local v364_ = InputAction.createFromXML(xmlFile, v363_)
		if v364_ ~= nil then
			local v365_ = string.format("input_%s", v364_.name)
			local v366_ = modName and (string.format(" in mod \'%s\'", modName) or "") or ""
			if modName ~= nil then
				v364_.displayCategory = g_modManager:getModByName(modName).title
			end
			v364_.displayNamePositive = v364_.name
			v364_.displayNameNegative = v364_.name
			local v367_
			if InputBinding.MOUSE_COMBOS[v364_.name] == nil then
				v367_ = false
			else
				v367_ = InputBinding.GAMEPAD_COMBOS[v364_.name] ~= nil
			end
			local v368_ = v364_.isLocked
			local v369_ = not v367_
			if v369_ then
				v369_ = not v368_
			end
			if v364_.axisType == InputAction.AXIS_TYPE.FULL then
				local v370_ = v365_ .. InputBinding.SYMBOL_AFFIX_POSITIVE
				local v371_ = v365_ .. InputBinding.SYMBOL_AFFIX_NEGATIVE
				if i18n:hasText(v370_) then
					v364_.displayNamePositive = i18n:getText(v370_)
				elseif v369_ then
					Logging.warning("Missing l10n \'%s\'%s", v370_, v366_)
				end
				if i18n:hasText(v371_) then
					v364_.displayNameNegative = i18n:getText(v371_)
				elseif v369_ then
					Logging.warning("Missing l10n \'%s\'%s", v371_, v366_)
				end
			elseif i18n:hasText(v365_) then
				v364_.displayNamePositive = i18n:getText(v365_)
			elseif v369_ then
				Logging.warning("Missing l10n \'%s\'%s", v365_, v366_)
			end
			if self.nameActions[v364_.name] == nil then
				local v372_ = self.actions
				table.insert(v372_, v364_)
			else
				for v373_ = 1, #self.actions do
					local v374_ = self.actions[v373_]
					if v374_.name == v364_.name then
						v364_.bindings = v374_.bindings
						v364_:resetActiveBindings()
						self.actions[v373_] = v364_
						break
					end
				end
			end
			self.nameActions[v364_.name] = v364_
		end
		v362_ = v362_ + 1
	end
end

-- Local values: previousDevices
function InputBinding:resetDeviceInformation()
	local v376_ = self.devicesByInternalId
	self.devicesByInternalId = {}
	self.devicesByCategory = {}
	self.deviceIdToInternal = {}
	self.internalToDeviceId = {}
	return v376_
end

-- Local values: kbMouseDevice
function InputBinding:createDefaultDevices()
	local v378_ = InputDevice.new(InputBinding.KB_MOUSE_INTERNAL_ID, InputDevice.DEFAULT_DEVICE_NAMES.KB_MOUSE_DEFAULT, InputDevice.DEFAULT_DEVICE_NAMES.KB_MOUSE_DEFAULT, InputDevice.CATEGORY.KEYBOARD_MOUSE)
	v378_.isActive = not self.isConsoleVersion
	self.devicesByInternalId[InputBinding.KB_MOUSE_INTERNAL_ID] = v378_
	self.devicesByCategory[InputDevice.CATEGORY.KEYBOARD_MOUSE] = { v378_ }
	self.deviceIdToInternal[v378_.deviceId] = InputBinding.KB_MOUSE_INTERNAL_ID
end

-- Local values: internalId, engineDeviceId, deviceName, existingPrefix, baseDeviceId, count, uniqueDeviceId, deviceCategory, device, _, device
function InputBinding:enumerateGamepadDevices(previousDevices)
	self.engineDeviceIdCounts = {}
	self.numGamepads = getNumOfGamepads()
	self.numActiveGamepads = 0
	self.internalIdToEngineDeviceId = {}
	g_ignitionLockManager:reset()
	for v381_ = 0, self.numGamepads - 1 do
		local v382_ = getGamepadId(v381_)
		local v383_ = getGamepadName(v381_)
		self.internalIdToEngineDeviceId[v381_] = v382_
		if InputDevice.getIsDeviceSupported(v382_, v383_) then
			local v384_, v385_ = InputDevice.getDeviceIdPrefix(v382_)
			if v384_ < 0 then
				v385_ = v382_
			end
			local v386_ = self.engineDeviceIdCounts[v385_] or 0
			self.engineDeviceIdCounts[v385_] = v386_ + 1
			local v387_
			if v384_ >= 0 then
				v387_ = v382_
			else
				v387_ = InputDevice.getPrefixedDeviceId(v385_, v386_)
			end
			self.deviceIdToInternal[v387_] = v381_
			self.internalToDeviceId[v381_] = v387_
			self.numActiveGamepads = self.numActiveGamepads + 1
			local v388_ = InputBinding.getDeviceCategory(v381_)
			local v389_ = InputDevice.new(v381_, v387_, v383_, v388_)
			self.devicesByInternalId[v381_] = v389_
			if not self.devicesByCategory[v388_] then
				self.devicesByCategory[v388_] = {}
			end
			local v390_ = self.devicesByCategory[v388_]
			table.insert(v390_, v389_)
		end
		g_ignitionLockManager:tryToAddDevice(v381_, v382_, v383_)
	end
	for _, v391_ in pairs(previousDevices) do
		if not self.deviceIdToInternal[v391_.deviceId] then
			v391_.internalId = -1
			self.missingDevices[v391_.deviceId] = v391_
		end
	end
end

-- Local values: deviceList, _, device
function InputBinding:getGamepadDevices()
	local v393_ = {}
	for _, v394_ in pairs(self.devicesByInternalId) do
		if v394_:isController() then
			local v395_ = {
				["deviceId"] = v394_.deviceId,
				["name"] = v394_.deviceName
			}
			table.insert(v393_, v395_)
		end
	end
	return v393_
end

-- Local values: hasLoadedDevice, elementIndex, deviceElement, deviceId, deviceInternalId, device, xmlCategory, missingDeviceCategory, missingDeviceName, device, deviceId
function InputBinding:loadDeviceSettingsFromXML(xmlFile)
	local v398_ = 0
	local v399_ = {}
	while true do
		local v400_ = string.format("inputBinding.devices.device(%d)", v398_)
		if not hasXMLProperty(xmlFile, v400_) then
			break
		end
		local v401_ = InputDevice.loadIdFromXML(xmlFile, v400_)
		v399_[v401_] = true
		local v402_ = self.deviceIdToInternal[v401_]
		if v402_ then
			local v403_ = self.devicesByInternalId[v402_]
			v403_:loadSettingsFromXML(xmlFile, v400_)
			local v404_ = InputDevice.loadCategoryFromXML(xmlFile, v400_)
			if v404_ == InputDevice.CATEGORY.UNKNOWN and v404_ ~= v403_.category then
				self.devicesToMigrateCategory[v401_] = v403_
			end
		elseif v401_ and v401_ ~= "" then
			local v405_ = InputDevice.loadCategoryFromXML(xmlFile, v400_)
			local v406_ = InputDevice.loadNameFromXML(xmlFile, v400_)
			local v407_ = InputDevice.new(-1, v401_, v406_, v405_)
			v407_:loadSettingsFromXML(xmlFile, v400_)
			self.missingDevices[v401_] = v407_
		end
		v398_ = v398_ + 1
	end
	for v408_ in pairs(self.deviceIdToInternal) do
		if not v399_[v408_] then
			self.newlyConnectedDevices[v408_] = true
		end
	end
end

-- Local values: _, device, axis
function InputBinding:applyGamepadDeadzones()
	if GS_PLATFORM_PC then
		for _, v410_ in pairs(self.devicesByInternalId) do
			if v410_:isController() then
				for v411_ = 0, Input.MAX_NUM_AXES - 1 do
					setGamepadDeadzone(0, v410_.internalId, v411_)
				end
			end
		end
	end
end

-- Local values: previousDevices
function InputBinding:initializeGamepadMapping(xmlFile)
	local v414_ = self:resetDeviceInformation()
	self:createDefaultDevices()
	self:enumerateGamepadDevices(v414_)
	if xmlFile ~= nil then
		self:loadDeviceSettingsFromXML(xmlFile)
	end
	self:applyGamepadDeadzones()
end

-- Local values: _, action, bindings, comboAxisNames, comboBindingIndex, comboBindingDevice, comboBindingDeviceCategory, axisNames, k, newBinding, comboBinding, internalDeviceId, couldResolve
function InputBinding:validateAndRepairComboActionBindings()
	for _, v416_ in pairs(self.actions) do
		local v417_ = v416_:getBindings()
		local v418_ = nil
		local v419_ = 1
		local v420_ = nil
		local v421_ = InputDevice.CATEGORY.UNKNOWN
		if self.numGamepads > 0 and InputBinding.GAMEPAD_COMBO_BINDINGS[v416_.name] then
			v418_ = InputBinding.GAMEPAD_COMBO_BINDINGS[v416_.name]
			v420_ = InputDevice.DEFAULT_DEVICE_NAMES.GAMEPAD_DEFAULT
		elseif not self.isConsoleVersion and InputBinding.MOUSE_COMBO_BINDINGS[v416_.name] then
			v418_ = InputBinding.MOUSE_COMBO_BINDINGS[v416_.name]
			v419_ = Binding.MAX_ALTERNATIVES_KB_MOUSE
			v420_ = InputDevice.DEFAULT_DEVICE_NAMES.KB_MOUSE_DEFAULT
		end
		if v418_ then
			local v422_ = table.clone(v418_)
			for v423_ in pairs(v417_) do
				v417_[v423_] = nil
			end
			local v424_ = Binding.new(v420_, v422_, Binding.AXIS_COMPONENT.POSITIVE, Binding.INPUT_COMPONENT.POSITIVE, 0, v419_)
			table.insert(v417_, v424_)
			local v425_ = v417_[1]
			local v426_ = self.deviceIdToInternal[v425_.deviceId]
			if v426_ ~= nil then
				v420_ = v425_.deviceId
				v421_ = self.devicesByInternalId[v426_].category
			end
			v425_:setIndex(v419_)
			v425_:updateData(v420_, v421_, v422_, Binding.INPUT_COMPONENT.POSITIVE)
			v425_:setActive((self:resolveBindingDefaultDevice(v425_, nil)))
			v425_:makeId()
		end
	end
end

-- Local values: rootPath
function InputBinding:loadActionBindingsFromXML(xmlFile, silentIgnoreDuplicates, modName, disallowedDeviceIds, requireUnknownBindings, markActionKnown)
	self:loadActionBindingsFromXMLPath(xmlFile, modName and "modDesc.inputBinding" or "inputBinding", silentIgnoreDuplicates, disallowedDeviceIds, requireUnknownBindings, markActionKnown)
end

-- Local values: actionIndex, actionPath, actionName, action
function InputBinding:loadActionBindingsFromXMLPath(xmlFile, rootPath, silentIgnoreDuplicates, disallowedDeviceIds, requireUnknownBindings, markActionKnown)
	local v441_ = 0
	while true do
		local v442_ = string.format("%s.actionBinding(%d)", rootPath, v441_)
		if not hasXMLProperty(xmlFile, v442_) then
			break
		end
		local v443_ = getXMLString(xmlFile, v442_ .. "#action")
		if v443_ and v443_ ~= "" then
			local v444_ = self.nameActions[v443_]
			if v444_ and not (v444_.bindingsKnown and requireUnknownBindings) then
				if markActionKnown then
					v444_.bindingsKnown = true
				end
				self:loadBindingsFromXML(xmlFile, v442_, v444_, silentIgnoreDuplicates, disallowedDeviceIds)
			end
		end
		v441_ = v441_ + 1
	end
end

-- Local values: bindingIndex, bindingPath, binding
function InputBinding:loadBindingsFromXML(xmlFile, actionPath, action, silentIgnoreDuplicates, disallowedDeviceIds)
	local v451_ = 0
	while true do
		local v452_ = actionPath .. string.format(".binding(%d)", v451_)
		if not hasXMLProperty(xmlFile, v452_) then
			break
		end
		local v453_ = Binding.createFromXML(xmlFile, v452_)
		if self:resolveBindingDefaultDevice(v453_, disallowedDeviceIds) then
			self:addBinding(action, v453_, silentIgnoreDuplicates)
		end
		v451_ = v451_ + 1
	end
end

-- Local values: combos, _, deviceCombos, comboActionName, combo, comboAction, validComboBinding, _, binding, device
function InputBinding:storeComboInputMappings()
	self.comboInputAxisMasks = {}
	self.comboInputActions = {}
	self.comboInputBindings = {}
	local v455_ = { InputBinding.GAMEPAD_COMBOS }
	local v456_ = not self.isConsoleVersion and { InputBinding.GAMEPAD_COMBOS, InputBinding.MOUSE_COMBOS } or v455_
	for _, v457_ in pairs(v456_) do
		for v458_, v459_ in pairs(v457_) do
			local v460_ = self.nameActions[v458_]
			if v460_ then
				local v461_ = nil
				for _, v462_ in ipairs(v460_:getBindings()) do
					if v462_.isActive and (self.devicesByInternalId[v462_.internalDeviceId].category == InputDevice.CATEGORY.GAMEPAD or v462_.isMouse) then
						v461_ = v462_
						break
					end
				end
				if v461_ ~= nil then
					self.comboInputAxisMasks[v461_.axisNameSet] = v459_.mask
					self.comboInputActions[v461_.axisNameSet] = v458_
					self.comboInputBindings[v458_] = v461_
				end
			end
		end
	end
end

-- Local values: comboSet, mask
function InputBinding:getBindingComboMask(binding)
	for v465_, v466_ in pairs(self.comboInputAxisMasks) do
		if table.equalSets(v465_, binding.modifierAxisSet) then
			return v466_
		end
	end
	return 0
end

-- Local values: _, action, bindings, _, binding, bindingComboMask, device, isPrimaryGamepadBinding, isNotComboAction
function InputBinding:assignComboMasks()
	for _, v468_ in pairs(self.actions) do
		local v469_ = v468_:getActiveBindings()
		v468_.comboMaskMouse = 0
		v468_.comboMaskGamepad = 0
		for _, v470_ in pairs(v469_) do
			local v471_ = self:getBindingComboMask(v470_)
			if v470_.isMouse then
				if InputBinding.MOUSE_COMBOS[v468_.name] == nil then
					v468_.comboMaskMouse = v471_
					v470_:setComboMask(v471_)
				end
			elseif v470_.isActive then
				local v472_
				if self.devicesByInternalId[v470_.internalDeviceId].category == InputDevice.CATEGORY.GAMEPAD then
					v472_ = v470_.isGamepad
				else
					v472_ = false
				end
				if v472_ and InputBinding.GAMEPAD_COMBOS[v468_.name] == nil then
					v468_.comboMaskGamepad = v471_
					v470_:setComboMask(v471_)
				end
			end
		end
	end
end

-- Local values: _, action, linkedActionName, linkedAction, _, binding, links, linkedBindings, _, linkedBinding
function InputBinding:storeLinkedBindings()
	for _, v474_ in pairs(self.actions) do
		local v475_ = InputAction.LINKED_ACTIONS[v474_.name]
		if v475_ ~= nil then
			local v476_ = self.nameActions[v475_]
			for _, v477_ in pairs(v474_:getBindings()) do
				local v478_ = self.linkedBindings[v477_]
				if v478_ == nil then
					v478_ = {}
					self.linkedBindings[v477_] = v478_
				end
				local v479_ = v476_:getBindings()
				for _, v480_ in pairs(v479_) do
					if v480_.deviceId == v477_.deviceId and v480_.index == v477_.index then
						table.insert(v478_, v480_)
					end
				end
			end
		end
	end
end

-- Local values: _, action, bindings, _, binding
function InputBinding:assignActionPrimaryBindings()
	for _, v482_ in pairs(self.actions) do
		local v483_ = v482_:getActiveBindings()
		for _, v484_ in pairs(v483_) do
			if v484_.deviceId == InputDevice.DEFAULT_DEVICE_NAMES.KB_MOUSE_DEFAULT and v484_.index == 1 then
				v482_:setPrimaryKeyboardBinding(v484_)
			end
		end
	end
end

-- Local values: isKbMouse, maxBindings, i
function InputBinding:adjustBindingSlotIndex(binding, action)
	if binding.index >= 1 then
		return true
	end
	local v487_ = binding.deviceId == InputDevice.DEFAULT_DEVICE_NAMES.KB_MOUSE_DEFAULT
	if v487_ and InputBinding.getIsMouseInput(binding.axisNames) then
		if action:getBindingAtSlot(binding.axisComponent, v487_, Binding.MAX_ALTERNATIVES_KB_MOUSE) == nil then
			binding:setIndex(Binding.MAX_ALTERNATIVES_KB_MOUSE)
			return true
		end
	else
		local v488_
		if v487_ then
			v488_ = Binding.MAX_ALTERNATIVES_KB_MOUSE - 1
		else
			v488_ = Binding.MAX_ALTERNATIVES_GAMEPAD
		end
		for v489_ = 1, v488_ do
			if action:getBindingAtSlot(binding.axisComponent, v487_, v489_) == nil then
				binding:setIndex(v489_)
				return true
			end
		end
	end
	return false
end

-- Local values: bindingVersion, _, action, bindingsCopy, bindingI, binding, _, binding, device, internalId, newAxisNames, changed, _, axisName, newAxisName, axisNameNoSign, sign, lastAxisName, inputComponent, newBinding
function InputBinding:upgradeBindingVersion(xmlFileInputBinding)
	if (getXMLInt(xmlFileInputBinding, "inputBinding#bindingVersion") or 0) == 0 then
		for _, v492_ in pairs(self.actions) do
			local v493_ = {}
			for v494_, v495_ in pairs(v492_.bindings) do
				v493_[v494_] = v495_
			end
			for _, v496_ in pairs(v493_) do
				if v496_.isGamepad then
					local v497_ = self.deviceIdToInternal[v496_.deviceId]
					local v498_
					if v497_ then
						v498_ = self.devicesByInternalId[v497_]
					else
						v498_ = nil
					end
					local v499_ = v498_ or self.missingDevices[v496_.deviceId]
					if v499_ and v499_.category == InputDevice.CATEGORY.UNKNOWN then
						local v500_ = {}
						local v501_ = false
						for _, v505_ in ipairs(v496_.axisNames) do
							local v503_ = v505_:sub(v505_:len())
							local v504_
							if v503_ == "+" or v503_ == "-" then
								v504_ = v505_:sub(1, v505_:len() - 1)
							else
								v504_ = v505_
								v503_ = ""
							end
							local v505_
							if v504_ == "HALF_AXIS_1" or v504_ == "AXIS_11" then
								v505_ = "AXIS_2-"
								v501_ = true
							elseif v504_ == "HALF_AXIS_2" or v504_ == "AXIS_12" then
								v505_ = "AXIS_2+"
								v501_ = true
							elseif v504_ == "AXIS_2" then
								v505_ = "AXIS_7" .. v503_
								v501_ = true
							elseif v504_ == "AXIS_7" then
								v505_ = "AXIS_8" .. v503_
								v501_ = true
							elseif v504_ == "BUTTON_21" then
								v505_ = "BUTTON_25"
								v501_ = true
							elseif v504_ == "BUTTON_22" then
								v505_ = "BUTTON_26"
								v501_ = true
							elseif v504_ == "BUTTON_23" then
								v505_ = "BUTTON_27"
								v501_ = true
							elseif v504_ == "BUTTON_24" then
								v505_ = "BUTTON_28"
								v501_ = true
							elseif v504_ == "BUTTON_25" then
								v505_ = "BUTTON_29"
								v501_ = true
							elseif v504_ == "BUTTON_26" then
								v505_ = "BUTTON_30"
								v501_ = true
							elseif v504_ == "BUTTON_27" then
								v505_ = "BUTTON_31"
								v501_ = true
							elseif v504_ == "BUTTON_28" then
								v505_ = "BUTTON_32"
								v501_ = true
							end
							table.insert(v500_, v505_)
						end
						if v501_ and #v500_ > 0 then
							local v506_ = v500_[#v500_]
							local v507_ = Binding.INPUT_COMPONENT.POSITIVE
							if v506_:sub(v506_:len()) == "-" then
								v507_ = Binding.INPUT_COMPONENT.NEGATIVE
							end
							v492_:removeBinding(v496_)
							self:addBinding(v492_, (Binding.new(v496_.deviceId, v500_, v496_.axisComponent, v507_, v496_.neutralInput, v496_.index)))
						end
					end
				end
			end
		end
	end
end

-- Local values: _, action, _, binding
function InputBinding:resolveBindingDevice(oldDevice, newDevice)
	if oldDevice.category == InputDevice.CATEGORY.UNKNOWN and oldDevice.category ~= newDevice.category then
		self.devicesToMigrateCategory[newDevice.deviceId] = newDevice
	end
	for _, v511_ in pairs(self.actions) do
		for _, v512_ in pairs(v511_.bindings) do
			if v512_.deviceId == oldDevice.deviceId then
				v512_.deviceId = newDevice.deviceId
				v512_.internalDeviceId = newDevice.internalId
				v512_:setActive(true)
				v512_:makeId()
			end
		end
	end
end

-- Local values: usedDevices, missingDeviceId, missingDevice, _, device, missingDeviceId, missingDevice, _, device, missingDeviceId
function InputBinding:resolveBindingDevices()
	local v514_ = self:getAllDevicesWithBindings()
	for v515_, v516_ in pairs(self.missingDevices) do
		if v514_[v515_] then
			for _, v517_ in pairs(self.devicesByInternalId) do
				if v517_.deviceName == v516_.deviceName and not v514_[v517_.deviceId] then
					self:resolveBindingDevice(v516_, v517_)
					v514_[v517_.deviceId] = true
					self.missingDevices[v515_] = nil
					break
				end
			end
		end
	end
	for v518_, v519_ in pairs(self.missingDevices) do
		if v514_[v518_] and v519_.category ~= InputDevice.CATEGORY.UNKNOWN then
			for _, v520_ in pairs(self.devicesByInternalId) do
				if v520_.category == v519_.category and not v514_[v520_.deviceId] then
					self:resolveBindingDevice(v519_, v520_)
					v514_[v520_.deviceId] = true
					self.missingDevices[v518_] = nil
					break
				end
			end
		end
	end
	for v521_ in pairs(self.missingDevices) do
		if not v514_[v521_] then
			self.missingDevices[v521_] = nil
		end
	end
end

-- Local values: isDefaultBinding, category, _, device
function InputBinding:resolveBindingDefaultDevice(binding, disallowedDeviceIds)
	if not InputDevice.DEFAULT_DEVICE_NAMES[binding.deviceId] then
		return true
	end
	local v525_ = InputDevice.DEFAULT_DEVICE_CATEGORIES[binding.deviceId]
	for _, v526_ in pairs(self.devicesByInternalId) do
		if v526_.category == v525_ and (disallowedDeviceIds == nil or not disallowedDeviceIds[v526_.deviceId]) then
			binding.deviceId = v526_.deviceId
			binding.internalDeviceId = v526_.internalId
			return true
		end
	end
	return false
end

-- Local values: id, device, gamepad, newAxisMappingsPos, newAxisMappingsNeg, i, mapping, inverted, newButtonMappings, i, _, action, bindingsCopy, bindingI, binding, _, binding, newAxisNames, axisNameI, axisName, newAxisName, axisId, sign, mappings, mapping, newSign, buttonId, mapping, lastAxisName, inputComponent, neutralInput, newBinding
function InputBinding:migrateDevicesCategory()
	if GS_PLATFORM_PC then
		for v528_, v529_ in pairs(self.devicesToMigrateCategory) do
			local v530_ = self.deviceIdToInternal[v529_.deviceId]
			if v530_ == nil or self.numGamepads <= v530_ then
				self.devicesToMigrateCategory[v528_] = nil
			elseif getIsGamepadMappingReliable(v530_) then
				local v531_ = {}
				local v532_ = {}
				for v533_ = 0, Input.MAX_NUM_AXES - 1 do
					local v534_, v535_ = getGamepadMappedUnknownAxis(v533_, v530_, 1)
					v531_[v533_] = { v534_, v535_ }
					local v536_, v537_ = getGamepadMappedUnknownAxis(v533_, v530_, -1)
					v532_[v533_] = { v536_, v537_ }
				end
				local v538_ = {}
				for v539_ = 0, Input.MAX_NUM_BUTTONS - 1 do
					v538_[v539_] = getGamepadMappedUnknownButton(v539_, v530_)
				end
				for _, v540_ in pairs(self.actions) do
					local v541_ = {}
					for v542_, v543_ in pairs(v540_.bindings) do
						v541_[v542_] = v543_
					end
					for _, v544_ in pairs(v541_) do
						if v544_.deviceId == v529_.deviceId then
							local v545_ = {}
							for v546_, v549_ in ipairs(v544_.axisNames) do
								local v548_ = Input.axisIdNameToId[v549_]
								local v549_
								if v548_ then
									local v550_ = v549_:sub(v549_:len())
									local v551_ = v546_ == #v544_.axisNames and (not Input.isHalfAxis(v548_) and v544_.neutralInput ~= 0) and (v544_.neutralInput == 1 and "-" or "+") or v550_
									local v552_ = (v551_ == "-" and v532_ and v532_ or v531_)[v548_]
									if v552_ and v552_[1] < Input.MAX_NUM_AXES then
										local v553_ = Input.isHalfAxis(v552_[1]) and "" or (v552_[2] and (v551_ == "-" and "+" or "-") or v551_)
										v549_ = Input.axisIdToIdName[v552_[1]] .. v553_
									end
								else
									local v554_ = Input.buttonIdNameToId[v549_]
									if v554_ then
										local v555_ = v538_[v554_]
										if v555_ and v555_ < Input.MAX_NUM_BUTTONS then
											v549_ = Input.buttonIdToIdName[v555_]
										end
									end
								end
								table.insert(v545_, v549_)
							end
							if #v545_ > 0 then
								local v556_ = v545_[#v545_]
								local v557_ = Binding.INPUT_COMPONENT.POSITIVE
								if v556_:sub(v556_:len()) == "-" then
									v557_ = Binding.INPUT_COMPONENT.NEGATIVE
								end
								local v558_ = v544_.neutralInput
								local v559_ = Input.axisIdNameToId[v556_] and Input.isHalfAxis(Input.axisIdNameToId[v556_]) and 0 or v558_
								v540_:removeBinding(v544_)
								self:addBinding(v540_, (Binding.new(v544_.deviceId, v545_, v544_.axisComponent, v557_, v559_, v544_.index)))
							end
						end
					end
				end
				self.devicesToMigrateCategory[v528_] = nil
			end
		end
	elseif next(self.devicesToMigrateCategory) then
		self.devicesToMigrateCategory = {}
	end
end

-- Local values: functionResults, _, otherAction, bindings, _, knownBinding, _, check, hasResult, result
function InputBinding:checkBindings(contextAction, checkFunctions)
	local v562_ = {}
	for _, v563_ in pairs(self.actions) do
		local v564_ = v563_:getBindings()
		for _, v565_ in pairs(v564_) do
			for _, v566_ in pairs(checkFunctions) do
				local v567_, v568_ = v566_(v565_, v563_)
				if v567_ then
					v562_[v566_] = v568_
				end
			end
		end
	end
	return v562_
end

-- Local values: shouldBeMouse, shouldBeKeyboard, maxAlternatives, hasValidIndex, checkCollision, checkDuplicate, checkSlotOccupied, checkResults, hasDuplicate, slotOccupied, collision, hasCollision
function InputBinding:validateBinding(binding, action)
	local v572_ = false
	local v573_ = false
	local v574_ = Binding.MAX_ALTERNATIVES_GAMEPAD
	if binding.deviceId == InputDevice.DEFAULT_DEVICE_NAMES.KB_MOUSE_DEFAULT then
		v574_ = Binding.MAX_ALTERNATIVES_KB_MOUSE
		if binding.index == v574_ then
			v572_ = true
		else
			v573_ = true
		end
	end
	local v575_
	if v572_ then
		v575_ = InputBinding.getIsMouseInput(binding.axisNames)
	elseif v573_ then
		if binding.index > 0 and binding.index <= v574_ then
			v575_ = InputBinding.getIsKeyboardInput(binding.axisNames)
		else
			v575_ = false
		end
	elseif binding.index > 0 and binding.index <= v574_ then
		v575_ = InputBinding.getIsGamepadInput(binding.axisNames)
	else
		v575_ = false
	end
	local function v578_(p576_, p577_)
		-- upvalues: (copy) binding
		if binding:hasCollisionWith(p576_) then
			return true, {
				["collisionBinding"] = p576_,
				["collisionAction"] = p577_
			}
		else
			return false, nil
		end
	end
	local function v581_(p579_, p580_)
		-- upvalues: (copy) action, (copy) binding
		if action == p580_ and binding.id == p579_.id then
			return true, true
		else
			return false, nil
		end
	end
	local function v584_(p582_, p583_)
		-- upvalues: (copy) action, (copy) binding
		if p583_ == action and binding:isSameSlot(p582_) then
			return true, true
		else
			return false, nil
		end
	end
	local v585_ = self:checkBindings(action, { v578_, v581_, v584_ })
	local v586_ = v585_[v581_] and true or false
	local v587_ = v585_[v584_] and true or false
	local v588_ = v585_[v578_]
	return v575_, v586_, v587_, v588_ and true or false, v588_
end

-- Local values: hasAddedBinding, collisionAction, hasValidIndex, hasDuplicate, slotOccupied, _hasCollision, collisionRef, canAdd, bindingDevice, loadedBinding
function InputBinding:addBinding(action, binding, silentIgnoreDuplicates)
	if not self:adjustBindingSlotIndex(binding, action) then
		if not silentIgnoreDuplicates then
			local v593_ = Logging.warning
			local v594_ = tostring(binding)
			local v595_ = action.name
			v593_("Tried to add additional alternative binding %s to %s. The maximum alternative count has been reached. The new binding has been ignored.", v594_, (tostring(v595_)))
		end
		return false, nil
	end
	local v596_ = false
	local v597_, v598_, v599_, _, v600_ = self:validateBinding(binding, action)
	if v597_ then
		v597_ = not v598_
		if v597_ then
			v597_ = not v599_
		end
	end
	if not v597_ then
		if v598_ then
			if not silentIgnoreDuplicates then
				local v601_ = Logging.warning
				local v602_ = tostring(binding)
				local v603_ = action.name
				v601_("Tried to add duplicate binding %s to %s. The new binding has been ignored.", v602_, (tostring(v603_)))
				return v596_, v600_
			end
		elseif v599_ and not silentIgnoreDuplicates then
			local v604_ = Logging.warning
			local v605_ = tostring(binding)
			local v606_ = action.name
			v604_("Tried assigning the binding %s to %s to an occupied slot. The new binding has been ignored", v605_, (tostring(v606_)))
		end
		return v596_, v600_
	end
	binding.internalDeviceId = self.deviceIdToInternal[binding.deviceId]
	binding:setIsAnalog(InputBinding.getIsAnalogInput(binding.unmodifiedAxis))
	binding:setActive(binding.internalDeviceId ~= nil)
	local v607_ = self.devicesByInternalId[binding.internalDeviceId]
	if v607_ ~= nil then
		binding:updateData(nil, v607_.category)
	end
	binding:makeId()
	local v608_ = self.loadedBindings[binding.id]
	if v608_ == nil or not v608_.isActive then
		self.loadedBindings[binding.id] = binding
	else
		binding = v608_
	end
	action:addBinding(binding)
	return true, v600_
end

-- Local values: blockAdd, updateBinding, action, bindings, _, binding, inputString, hasUpdated, collisionAction, newBinding
function InputBinding:updateBinding(findDeviceId, findActionName, findBindingIndex, findAxisComponent, deviceId, axisNames, inputComponent, neutralInput)
	local v618_ = false
	local v619_ = nil
	local v620_ = self.nameActions[findActionName]
	if v620_ ~= nil then
		local v621_ = v620_:getBindings()
		for _, v622_ in pairs(v621_) do
			if v622_.deviceId == findDeviceId and v622_.axisComponent == findAxisComponent then
				if table.concat(axisNames, " ") == v622_.inputString then
					v618_ = true
				elseif v622_.index == findBindingIndex then
					v619_ = v622_
				end
			end
		end
	end
	local v623_, v624_
	if v619_ == nil or v618_ then
		v623_ = false
		v624_ = nil
	else
		v620_:removeBinding(v619_)
		v623_, v624_ = self:addBinding(v620_, Binding.new(deviceId, axisNames, findAxisComponent, inputComponent, neutralInput, findBindingIndex), true)
		if not v623_ then
			self:addBinding(v620_, v619_, true)
		end
	end
	return v623_, v624_, v618_
end

-- Local values: action, bindings, i, binding
function InputBinding:deleteBinding(findDeviceId, findActionName, findBindingIndex, findAxisComponent)
	local v630_ = self.nameActions[findActionName]
	if v630_ ~= nil then
		local v631_ = v630_:getBindings()
		for v632_, v633_ in pairs(v631_) do
			if v633_.deviceId == findDeviceId and (v633_.index == findBindingIndex and v633_.axisComponent == findAxisComponent) then
				table.remove(v631_, v632_)
				return
			end
		end
	end
end

-- Local values: allActive, inputValue, _, inputAxis, inputId
function InputBinding:getKeyboardMouseInputActiveAndValue(axes, axisDirection, inputDirection)
	if not next(axes) then
		return false, 0
	end
	local v638_ = 0
	local v639_ = true
	for _, v640_ in pairs(axes) do
		local v641_ = Input[v640_]
		if not v641_ then
			return false, v638_
		end
		if InputBinding.MOUSE_AXES[v640_] and v641_ == Input.AXIS_X then
			v638_ = self.inputMouseXAxisValue
			if axisDirection ~= inputDirection then
				v638_ = -v638_
			end
		elseif InputBinding.MOUSE_AXES[v640_] and v641_ == Input.AXIS_Y then
			v638_ = self.inputMouseYAxisValue
			if axisDirection ~= inputDirection then
				v638_ = -v638_
			end
		else
			if not (InputBinding.MOUSE_BUTTONS[v640_] and Input.isMouseButtonPressed(v641_) or Input.isKeyPressed(v641_)) then
				return false, 0
			end
			v638_ = axisDirection
		end
	end
	return v639_, v638_
end

-- Local values: numAxes, i, value, inputValue, isAxis
function InputBinding:getGamepadInputActiveAndValue(internalDeviceId, axisNames, neutralInput, axisDirection)
	local v647_ = #axisNames
	if v647_ == 0 then
		return false, 0
	end
	for v648_ = 1, v647_ - 1 do
		if self:getGamepadAxisOrButtonValue(internalDeviceId, axisNames[v648_], neutralInput) < Binding.PRESSED_MAGNITUDE_THRESHOLD then
			return false, 0
		end
	end
	local v649_, v650_ = self:getGamepadAxisOrButtonValue(internalDeviceId, axisNames[v647_], neutralInput)
	if not v650_ and v649_ < Binding.PRESSED_MAGNITUDE_THRESHOLD then
		return false, 0
	end
	if axisDirection < 0 then
		v649_ = -v649_
	end
	return true, v649_
end

-- Local values: buttonId, axisId, value, device, sensitivity
function InputBinding:getGamepadAxisOrButtonValue(internalDeviceId, axisName, neutralInput)
	local v655_ = Input.buttonIdNameToId[axisName]
	if v655_ ~= nil then
		return getInputButton(v655_, internalDeviceId), false
	end
	local v656_ = Input.axisIdNameToId[axisName]
	if v656_ == nil then
		return 0, false
	end
	local v657_ = self:getGamepadAxisValue(internalDeviceId, v656_, axisName, neutralInput)
	if v657_ ~= 0 then
		local v658_ = self.devicesByInternalId[internalDeviceId]
		if v658_ ~= nil then
			v657_ = v657_ * (v658_.sensitivities[v656_] or 1)
		end
	end
	return v657_, true
end

-- Local values: value, device, deadzone
function InputBinding:getGamepadAxisValue(internalDeviceId, axisId, axisName, neutralInput, overrideDeadzone)
	local v665_
	if Input.isHalfAxis(axisId) then
		v665_ = (1 - getInputAxis(axisId, internalDeviceId)) * 0.5
	else
		v665_ = getInputAxis(axisId, internalDeviceId)
		if neutralInput ~= 0 then
			v665_ = (v665_ - neutralInput) * 0.5
		end
		if axisName:sub(axisName:len()) == "-" then
			v665_ = -v665_
		end
	end
	local v666_ = self.devicesByInternalId[internalDeviceId]
	if v666_ then
		if v665_ ~= 0 then
			v666_:updateForceFeedbackState(axisId)
		end
		if GS_PLATFORM_PC then
			local v667_ = v666_:getDeadzone(axisId)
			if overrideDeadzone == nil then
				overrideDeadzone = v667_
			end
			if overrideDeadzone > 0.999 or math.abs(v665_) < overrideDeadzone then
				return 0
			end
			if v665_ > 0 then
				return (v665_ - overrideDeadzone) / (1 - overrideDeadzone)
			end
			v665_ = (v665_ + overrideDeadzone) / (1 - overrideDeadzone)
		end
	end
	return v665_
end
function InputBinding.update(p668_, p669_)
	p668_.needUpdateAbort = false
	p668_.timeSinceLastInputHelpModeChange = p668_.timeSinceLastInputHelpModeChange + p669_
	p668_:checkGamepadsChanged()
	p668_:checkGamepadsCategoryChanged()
	p668_:checkGamepadActive(p668_.numGamepads)
	p668_:updateMouseInput()
	p668_:updateInput()
	p668_:finalizeMouseInput()
end

function InputBinding:refresh(forced)
	if self.needsRefresh or forced then
		self.needsRefresh = false
		self:storeEventBindings()
		self:storeDisplayActionEvents()
		self:notifyEventChanges()
		self.markIt = true
	end
end

function InputBinding:draw()
	if self.debugEnabled then
		self:updateDebugDisplay()
	end
	if self.debugContextEnabled then
		self:debugRenderInputContext()
	end
	if self.debugRegisteredActions then
		self:debugRenderRegisteredActions()
	end
end

-- Local values: numGamepads, changed, internalId, engineDeviceId
function InputBinding:checkGamepadsChanged()
	local v674_ = getNumOfGamepads()
	local v675_ = v674_ ~= self.numGamepads
	if not v675_ then
		for v676_ = 0, v674_ - 1 do
			if getGamepadId(v676_) ~= self.internalIdToEngineDeviceId[v676_] then
				v675_ = true
				break
			end
		end
	end
	if v675_ then
		self.numGamepads = v674_
		self:load()
		self:refresh(true)
		self.messageCenter:publish(MessageType.INPUT_DEVICES_CHANGED)
	end
end

-- Local values: gamepad, device, newCategory, id, device, internalId
function InputBinding:checkGamepadsCategoryChanged()
	if GS_PLATFORM_PC then
		for v678_ = 0, self.numGamepads - 1 do
			local v679_ = self.devicesByInternalId[v678_]
			if v679_ and (v679_.category == InputDevice.CATEGORY.UNKNOWN and getGamepadCategory(v678_) ~= v679_.category) then
				self.devicesToMigrateCategory[v679_.deviceId] = v679_
			end
		end
		for v680_, v681_ in pairs(self.devicesToMigrateCategory) do
			local v682_ = self.deviceIdToInternal[v681_.deviceId]
			if v682_ then
				if getIsGamepadMappingReliable(v682_) then
					self:load()
					return
				end
			else
				self.devicesToMigrateCategory[v680_] = nil
			end
		end
	end
end

-- Local values: isActive, threshold, d, gamepadState, buttons, axes, i, prevButtonState, buttonState, i, defaultState, prevAxisState, axisState
function InputBinding:checkGamepadActive(numGamepads)
	local v685_ = false
	if numGamepads > 0 and self.lastInputHelpMode ~= GS_INPUT_HELP_MODE_GAMEPAD then
		local v686_ = InputBinding.INPUT_MODE_CHANGE_THRESHOLD
		for v687_ = 0, numGamepads - 1 do
			local v688_ = self.gamepadInputState[v687_]
			if v688_ == nil then
				v688_ = {
					["buttons"] = {},
					["axes"] = {}
				}
				self.gamepadInputState[v687_] = v688_
			end
			local v689_ = v688_.buttons
			local v690_ = v688_.axes
			for v691_ = 0, Input.MAX_NUM_BUTTONS - 1 do
				local v692_ = v689_[v691_] or 0
				local v693_ = getInputButton(v691_, v687_)
				if not v685_ then
					local v694_ = v693_ - v692_
					v685_ = v686_ < math.abs(v694_)
				end
				v689_[v691_] = v693_
			end
			for v695_ = 0, Input.MAX_NUM_AXES - 1 do
				local v696_ = Input.isHalfAxis(v695_) and 1 or 0
				local v697_ = v690_[v695_] or v696_
				local v698_ = getInputAxis(v695_, v687_)
				if not v685_ then
					local v699_ = v698_ - v697_
					v685_ = v686_ < math.abs(v699_)
				end
				v690_[v695_] = v698_
			end
		end
	end
	if v685_ then
		self:assignLastInputHelpMode(GS_INPUT_HELP_MODE_GAMEPAD)
	end
end

-- Local values: mouseMovementX, mouseMovementY
function InputBinding:updateMouseInput()
	local v701_ = self.accumMouseMovementX
	local v702_ = -self.accumMouseMovementY
	local v703_ = -InputBinding.MOUSE_MOVE_LIMIT
	local v704_ = InputBinding.MOUSE_MOVE_LIMIT
	self.inputMouseXAxisValue = math.clamp(v701_, v703_, v704_) * InputBinding.MOUSE_MOVE_BASE_FACTOR
	local v705_ = -InputBinding.MOUSE_MOVE_LIMIT
	local v706_ = InputBinding.MOUSE_MOVE_LIMIT
	self.inputMouseYAxisValue = math.clamp(v702_, v705_, v706_) * InputBinding.MOUSE_MOVE_BASE_FACTOR
	local v707_ = self.inputMouseXAxisValue
	if math.abs(v707_) <= 0.001 then
		local v708_ = self.inputMouseYAxisValue
		if math.abs(v708_) <= 0.001 then
			::l3::
			return
		end
	end
	self:assignLastInputHelpMode(GS_INPUT_HELP_MODE_KEYBOARD)
	goto l3
end

function InputBinding:finalizeMouseInput()
	if self.wrapMousePositionEnabled then
		wrapMousePosition(self.saveCursorX, self.saveCursorY)
		self.mousePosXLast = self.saveCursorX
		self.mousePosYLast = self.saveCursorY
	end
	self.accumMouseMovementX = 0
	self.accumMouseMovementY = 0
	self.inputMouseXAxisValue = 0
	self.inputMouseYAxisValue = 0
end

-- Local values: dId, bindings
function InputBinding:clearActiveBindingBuffer(activeBindingsBuffer)
	for v712_ in pairs(self.devicesByInternalId) do
		local v713_ = activeBindingsBuffer[v712_]
		if v713_ then
			table.clear(v713_)
		else
			activeBindingsBuffer[v712_] = {}
		end
	end
end

-- Local values: binding, deviceBindings, bindingActive, _, otherBinding, otherActive
function InputBinding:updateEventBindings(activeBindingsBuffer)
	for v716_ in pairs(self.activeBindings) do
		if v716_.isActive then
			self:updateBindingInput(v716_)
			local v717_ = activeBindingsBuffer[v716_.internalDeviceId]
			local v718_ = v716_.isUpFlank or v716_.inputValue ~= 0
			for _, v719_ in ipairs(v717_) do
				if v719_ ~= v716_ then
					if v718_ and (not v719_.isShadowed and table.isSubset(v719_.axisNameSet, v716_.axisNameSet)) then
						v719_.isShadowed = true
					end
					if (v719_.isUpFlank or v719_.inputValue ~= 0) and (not v716_.isShadowed and table.isSubset(v716_.axisNameSet, v719_.axisNameSet)) then
						v716_.isShadowed = true
					end
				end
			end
			v717_[#v717_ + 1] = v716_
		end
	end
end

-- Local values: binding
function InputBinding:hasBindingForPressedMouseComboMask(pressedMouseComboMask)
	for v722_ in pairs(self.activeBindings) do
		if v722_.isMouse and v722_:getComboMask() == pressedMouseComboMask then
			return true
		end
	end
	return false
end

-- Local values: binding, linkedBindings, _, linkedBinding
function InputBinding:shadowLinkedBindings()
	for v724_, v725_ in pairs(self.linkedBindings) do
		if v724_.isShadowed then
			for _, v726_ in pairs(v725_) do
				v726_.isShadowed = true
			end
		end
	end
end

-- Local values: _, deviceCombos, actionName, comboBinding
function InputBinding:updateComboBindings()
	for _, v728_ in pairs(InputBinding.ALL_COMBOS) do
		for v729_ in pairs(v728_) do
			local v730_ = self.comboInputBindings[v729_]
			if v730_ and v730_.isActive then
				self:updateBindingInput(v730_)
			end
		end
	end
end

-- Local values: pressedGamepadComboMask, pressedMouseComboMask, forceMouseMask, _, event, selectedBinding, highestInputMagnitude, bindings, _, binding, matchComboMask, forceMouseAxisMask, event, eventBindings
function InputBinding:updateInput()
	self.needUpdateAbort = false
	local v732_, v733_ = self:getComboCommandPressedMask()
	if v732_ ~= self.pressedGamepadComboMask or v733_ ~= self.pressedMouseComboMask then
		self:resetContinuousEventBindings(true, self.pressedGamepadComboMask, self.pressedMouseComboMask)
	end
	self.pressedGamepadComboMask = v732_
	self.pressedMouseComboMask = v733_
	self:clearActiveBindingBuffer(self.activeDeviceBindingsBuffer)
	self:updateEventBindings(self.activeDeviceBindingsBuffer)
	self:shadowLinkedBindings()
	local v734_ = self:hasBindingForPressedMouseComboMask(v733_)
	for _, v735_ in ipairs(self.eventOrder) do
		if self.needUpdateAbort then
			self.needUpdateAbort = false
			break
		end
		local v736_ = nil
		local v737_ = 0
		local v738_ = self.eventBindings[v735_]
		if v738_ ~= nil then
			for _, v739_ in pairs(v738_) do
				local v740_ = true
				local v741_ = v734_ and v739_.isMouse
				if v741_ then
					v741_ = InputBinding.MOUSE_AXES[v739_.unmodifiedAxis]
				end
				if not v735_:getIgnoreComboMask() or v741_ then
					if v739_.isMouse then
						v740_ = v739_.comboMask == v733_ and true or InputBinding.MOUSE_COMBO_AXIS_NAMES[v739_.unmodifiedAxis]
					else
						v740_ = v739_.comboMask == v732_ and true or InputBinding.GAMEPAD_COMBO_AXIS_NAMES[v739_.unmodifiedAxis]
					end
				end
				if v740_ and (v739_.isInputActive and not (v739_.isShadowed or v739_:getFrameTriggered())) then
					if v736_ then
						local v742_ = v739_.inputValue
						if v737_ < math.abs(v742_) or v739_.isUpFlank and v737_ == 0 then
							goto l30
						end
					else
						::l30::
						local v743_ = v739_.inputValue
						v737_ = math.abs(v743_)
						v736_ = v739_
					end
				end
			end
		end
		if v736_ ~= nil then
			v735_:notifyInput(v736_)
		end
	end
	self:updateComboBindings()
	for v744_, _ in pairs(self.eventBindings) do
		v744_:frameReset()
	end
end

-- Local values: device, bindingInputActive, bindingInputValue
function InputBinding:updateBindingInput(binding)
	local v747_ = self.devicesByInternalId[binding.internalDeviceId]
	if v747_ ~= nil then
		local v748_ = false
		local v749_ = 0
		if v747_.category == InputDevice.CATEGORY.KEYBOARD_MOUSE then
			v748_, v749_ = self:getKeyboardMouseInputActiveAndValue(binding.axisNames, binding.axisDirection, binding.inputDirection)
		elseif self.isGamepadEnabled then
			v748_, v749_ = self:getGamepadInputActiveAndValue(binding.internalDeviceId, binding.axisNames, binding.neutralInput, binding.axisDirection)
		end
		binding:updateInput(v749_, v748_)
	end
end

-- Local values: event, bindings, _, binding, matchMask
function InputBinding:resetContinuousEventBindings(checkComboMasks, gamepadComboMask, mouseComboMask)
	for v754_, v755_ in pairs(self.eventBindings) do
		if v754_.triggerAlways and not v754_:getIgnoreComboMask() then
			for _, v756_ in pairs(v755_) do
				local v757_
				if checkComboMasks then
					v757_ = ((not v756_.isGamepad or v756_.comboMask ~= gamepadComboMask) and true or false) and v756_.isMouse
					if v757_ then
						v757_ = v756_.comboMask == mouseComboMask
					end
				else
					v757_ = true
				end
				if v757_ then
					self:neutralizeEventBindingInput(v754_, v756_)
				end
			end
		end
	end
end

-- Local values: event, bindings, _, binding
function InputBinding:resetBindingInputStates()
	for _, v759_ in pairs(self.eventBindings) do
		for _, v760_ in pairs(v759_) do
			v760_:resetInputState()
		end
	end
end

function InputBinding:neutralizeEventBindingInput(event, binding)
	binding:updateInput(0, true)
	event:frameReset()
	event:notifyInput(binding, true)
end

-- Local values: posX, stepY, d, posY, i, i, i, i
function InputBinding:updateDebugDisplay()
	local v764_ = 0.02
	for v765_ = 0, self.numGamepads - 1 do
		setTextColor(1, 1, 1, 1)
		local v766_ = 0.95
		setTextBold(true)
		renderText(v764_, v766_, getCorrectTextSize(0.012), getGamepadName(v765_))
		setTextBold(false)
		local v767_ = v766_ - 0.015
		for v768_ = 0, Input.MAX_NUM_BUTTONS - 1 do
			if getHasGamepadButton(v768_, v765_) then
				renderText(v764_, v767_, getCorrectTextSize(0.012), "- " .. v768_)
				renderText(v764_ + 0.05, v767_, getCorrectTextSize(0.012), getGamepadButtonLabel(v768_, v765_) or "n/a")
				local v769_ = renderText
				local v770_ = v764_ + 0.1
				local v771_ = getCorrectTextSize(0.012)
				local v772_ = getInputButton(v768_, v765_) > 0
				v769_(v770_, v767_, v771_, (tostring(v772_)))
				v767_ = v767_ - 0.015
			end
		end
		for v773_ = 0, Input.MAX_NUM_AXES - 1 do
			if getHasGamepadAxis(v773_, v765_) then
				renderText(v764_, v767_, getCorrectTextSize(0.012), "+ " .. v773_)
				renderText(v764_ + 0.05, v767_, getCorrectTextSize(0.012), getGamepadAxisLabel(v773_, v765_) or "n/a")
				renderText(v764_ + 0.1, v767_, getCorrectTextSize(0.012), string.format("%.4f", getInputAxis(v773_, v765_)))
				v767_ = v767_ - 0.015
			end
		end
		setTextColor(1, 0, 0, 1)
		local v774_ = 0.95 + 0.5 * g_pixelSizeY
		local v775_ = v764_ - 0.5 * g_pixelSizeX
		setTextBold(true)
		renderText(v775_, v774_, getCorrectTextSize(0.012), getGamepadName(v765_))
		setTextBold(false)
		local v776_ = v774_ - 0.015
		for v777_ = 0, Input.MAX_NUM_BUTTONS - 1 do
			if getHasGamepadButton(v777_, v765_) then
				renderText(v775_, v776_, getCorrectTextSize(0.012), "- " .. v777_)
				renderText(v775_ + 0.05, v776_, getCorrectTextSize(0.012), getGamepadButtonLabel(v777_, v765_) or "n/a")
				local v778_ = renderText
				local v779_ = v775_ + 0.1
				local v780_ = getCorrectTextSize(0.012)
				local v781_ = getInputButton(v777_, v765_) > 0
				v778_(v779_, v776_, v780_, (tostring(v781_)))
				v776_ = v776_ - 0.015
			end
		end
		for v782_ = 0, Input.MAX_NUM_AXES - 1 do
			if getHasGamepadAxis(v782_, v765_) then
				renderText(v775_, v776_, getCorrectTextSize(0.012), "+ " .. v782_)
				renderText(v775_ + 0.05, v776_, getCorrectTextSize(0.012), getGamepadAxisLabel(v782_, v765_) or "n/a")
				renderText(v775_ + 0.1, v776_, getCorrectTextSize(0.012), string.format("%.4f", getInputAxis(v782_, v765_)))
				v776_ = v776_ - 0.015
			end
		end
		v764_ = v775_ + 0.15
	end
	setTextColor(1, 1, 1, 1)
end

-- Local values: xmlFile, i, storedActions, actionBindingElement, actionName, firstElement, action, bindings, j, binding, bindingElement, _, action, actionBindingElement, bindings, j, binding, bindingElement
function InputBinding:saveToXMLFile()
	if self.settingsPath == InputBinding.PATHS.USER_BINDINGS then
		local v784_ = loadXMLFile("InputBindings", self.settingsPath)
		local v785_ = 1
		local v786_ = {}
		while true do
			local v787_ = string.format("inputBinding.actionBinding(%d)", v785_ - 1)
			if not hasXMLProperty(v784_, v787_) then
				break
			end
			local v788_ = getXMLString(v784_, v787_ .. "#action")
			if v788_ and InputAction[v788_] then
				if self.nameActions[v788_] ~= nil then
					local v789_ = string.format("%s.binding(0)", v787_)
					while hasXMLProperty(v784_, v789_) do
						removeXMLProperty(v784_, v789_)
					end
					local v790_ = self.nameActions[v788_]:getBindings()
					for v791_, v792_ in ipairs(v790_) do
						v792_:saveToXMLFile(v784_, (string.format("%s.binding(%d)", v787_, v791_ - 1)))
					end
				end
				v786_[v788_] = true
			end
			v785_ = v785_ + 1
		end
		for _, v793_ in ipairs(self.actions) do
			if not v786_[v793_.name] then
				local v794_ = string.format("inputBinding.actionBinding(%d)", v785_ - 1)
				setXMLString(v784_, v794_ .. "#action", v793_.name)
				local v795_ = v793_:getBindings()
				for v796_, v797_ in ipairs(v795_) do
					v797_:saveToXMLFile(v784_, (string.format("%s.binding(%d)", v794_, v796_ - 1)))
				end
				v785_ = v785_ + 1
			end
		end
		self:saveDeviceSettings(v784_)
		setXMLFloat(v784_, "inputBinding#mouseSensitivityScaleX", self.mouseMotionScaleX)
		setXMLFloat(v784_, "inputBinding#mouseSensitivityScaleY", self.mouseMotionScaleY)
		setXMLInt(v784_, "inputBinding#bindingVersion", InputBinding.currentBindingVersion)
		saveXMLFile(v784_)
		delete(v784_)
		syncProfileFiles()
	end
end

-- Local values: firstDeviceKey, elementIndex, _, device, deviceElement, _, device, deviceElement
function InputBinding:saveDeviceSettings(xmlFile)
	while hasXMLProperty(xmlFile, "inputBinding.devices.device(0)") do
		removeXMLProperty(xmlFile, "inputBinding.devices.device(0)")
	end
	local v800_ = 0
	for _, v801_ in pairs(self.devicesByInternalId) do
		if not InputDevice.DEFAULT_DEVICE_NAMES[v801_.deviceId] then
			v801_:saveSettingsToXML(xmlFile, (string.format("inputBinding.devices.device(%d)", v800_)))
			v800_ = v800_ + 1
		end
	end
	for _, v802_ in pairs(self.missingDevices) do
		if not InputDevice.DEFAULT_DEVICE_NAMES[v802_.deviceId] then
			v802_:saveSettingsToXML(xmlFile, (string.format("inputBinding.devices.device(%d)", v800_)))
			v800_ = v800_ + 1
		end
	end
end

-- Local values: tableCopy, _, action, actionCopy
function InputBinding:getActionList()
	local v804_ = {}
	for _, v805_ in ipairs(self.actions) do
		local v806_ = v805_:clone()
		table.insert(v804_, v806_)
	end
	return v804_
end

function InputBinding:getActionByName(actionName)
	return self.nameActions[actionName]
end

-- Local values: action, events, _, event, bindings, i, binding
function InputBinding:disableAlternateBindingsForAction(actionName)
	local v811_ = self.nameActions[actionName]
	local v812_ = self.actionEvents[v811_]
	if v812_ ~= nil then
		for _, v813_ in pairs(v812_) do
			local v814_ = self.eventBindings[v813_]
			if v814_ ~= nil then
				for v815_ = #v814_, 1, -1 do
					if v814_[v815_].index > 1 then
						table.remove(v814_, v815_)
					end
				end
			end
		end
	end
end

-- Local values: _, action
function InputBinding:resetActiveActionBindings()
	for _, v817_ in pairs(self.nameActions) do
		v817_:resetActiveBindings()
	end
end

-- Local values: context
function InputBinding:createContext(name)
	self:deleteContext(name)
	local v820_ = {
		["actionEvents"] = {},
		["name"] = name,
		["previousContextName"] = "",
		["eventOrderCounter"] = 1
	}
	self.contexts[name] = v820_
	return v820_
end

-- Local values: oldContext, _, eventList, i, event
function InputBinding:deleteContext(name)
	local v823_ = self.contexts[name]
	if v823_ ~= nil then
		for _, v824_ in pairs(v823_.actionEvents) do
			for v825_ = #v824_, 1, -1 do
				self:removeEventInternal(v824_[v825_], v824_, v825_)
			end
		end
	end
	self.contexts[name] = nil
end

-- Local values: _, context, previousContextName
function InputBinding:replaceContextInStack(oldContextName, newContextName)
	for _, v829_ in pairs(self.contexts) do
		if v829_.previousContextName == oldContextName then
			v829_.previousContextName = newContextName
		end
	end
end

-- Local values: context, hasCreatedNew
function InputBinding:setContext(name, createNew, deletePrevious)
	local v834_ = self.contexts[name]
	local v835_
	if v834_ == nil or createNew then
		v834_ = self:createContext(name)
		v835_ = true
	else
		v835_ = false
	end
	if deletePrevious and self.currentContextName ~= InputBinding.ROOT_CONTEXT_NAME then
		self:deleteContext(self.currentContextName)
	end
	if self.debugEnabled then
		local v836_ = Logging.devInfo
		local v837_ = self.currentContextName
		v836_("[InputBinding] Set input context from [%s] to [%s], createNew=%s, deletePrevious=%s", tostring(v837_), tostring(name), tostring(createNew or false), (tostring(deletePrevious or false)))
	end
	if name ~= self.currentContextName then
		v834_.previousContextName = self.currentContextName
		self.currentContextName = name
	end
	self:resetContinuousEventBindings(false)
	self:resetBindingInputStates()
	self.actionEvents = v834_.actionEvents
	if v835_ then
		registerGlobalActionEvents(self)
	end
	self:refreshEventCollections()
end

-- Local values: currentContext, prevContextName, prevContext
function InputBinding:revertContext(deleteCurrent)
	if self.currentContextName == InputBinding.ROOT_CONTEXT_NAME then
		Logging.devWarning("Tried reverting input context when at root level.")
		return
	else
		local v840_ = self.contexts[self.currentContextName].previousContextName
		local v841_ = self.contexts[v840_]
		if v841_ then
			if deleteCurrent then
				self:deleteContext(self.currentContextName)
			end
			if self.debugEnabled then
				local v842_ = Logging.devInfo
				local v843_ = self.currentContextName
				v842_("[InputBinding] Reverting input context from [%s] to [%s], deleteCurrent=%s", tostring(v843_), tostring(v840_), (tostring(deleteCurrent or false)))
			end
			self.currentContextName = v840_
			self.actionEvents = v841_.actionEvents
			self:refreshEventCollections()
			self:resetBindingInputStates()
		else
			Logging.warning("Tried reverting to input context [%s] which is not defined. Current context [%s]", tostring(v840_), self.currentContextName)
			printCallstack()
		end
	end
end

-- Local values: context
function InputBinding:setPreviousContext(forContextName, previousContextName)
	local v847_ = self.contexts[forContextName]
	if v847_ ~= nil and self.contexts[previousContextName] ~= nil then
		v847_.previousContextName = previousContextName
	end
end

-- Local values: contextName
function InputBinding:clearAllContexts()
	for v849_ in pairs(self.contexts) do
		if v849_ ~= InputBinding.ROOT_CONTEXT_NAME then
			self:deleteContext(v849_)
		end
	end
	if self.debugEnabled then
		Logging.devInfo("[InputBinding] Cleared all contexts")
	end
	self:setContext(InputBinding.ROOT_CONTEXT_NAME, false, false)
end

function InputBinding:getContextName()
	return self.currentContextName
end

-- Local values: tableCopy, _, action, bindings, actionCopy, bindingsCopy, entry, _, binding
function InputBinding:getActionBindingsCopy(onlyAssignable)
	local v853_ = {}
	for _, v854_ in ipairs(self.actions) do
		if not onlyAssignable or onlyAssignable and not v854_.isLocked then
			local v855_ = v854_:getBindings()
			local v856_ = {}
			local v857_ = {
				["action"] = v854_:clone(),
				["bindings"] = v856_
			}
			table.insert(v853_, v857_)
			for _, v858_ in ipairs(v855_) do
				table.insert(v856_, v858_:clone())
			end
		end
	end
	return v853_
end

-- Local values: actionBindings, _, action
function InputBinding:getActionBindings()
	local v860_ = {}
	for _, v861_ in pairs(self.actions) do
		v860_[v861_] = v861_:getActiveBindings()
	end
	return v860_
end

-- Local values: action, events
function InputBinding:getEventsForActionName(actionName)
	local v864_ = self.nameActions[actionName]
	if v864_ ~= nil then
		local v865_ = self.actionEvents[v864_]
		if v865_ ~= nil then
			return { unpack(v865_) }
		end
	end
	return InputBinding.NO_ACTION_EVENTS
end

-- Local values: action, events, _, event
function InputBinding:getFirstActiveEventForActionName(actionName)
	local v868_ = self.nameActions[actionName]
	if v868_ ~= nil then
		local v869_ = self.actionEvents[v868_]
		if v869_ ~= nil then
			for _, v870_ in ipairs(v869_) do
				if v870_.isActive then
					return v870_
				end
			end
		end
	end
	return InputEvent.NO_EVENT
end

function InputBinding:setMouseMotionScale(scale)
	self.mouseMotionScaleX = InputBinding.MOUSE_MOTION_SCALE_X_DEFAULT * scale
	self.mouseMotionScaleY = InputBinding.MOUSE_MOTION_SCALE_Y_DEFAULT * scale
end

function InputBinding:getMouseMotionScale()
	return self.mouseMotionScaleX, self.mouseMotionScaleY
end

function InputBinding:setEventChangeCallback(callback)
	self.eventChangeCallback = callback
end

function InputBinding:notifyBindingChanges()
	self.messageCenter:publish(MessageType.INPUT_BINDINGS_CHANGED, self:getActionBindings())
end

function InputBinding:notifyEventChanges()
	if self.eventChangeCallback then
		self.eventChangeCallback(self.displayActionEvents)
	end
end

-- Local values: messageType
function InputBinding:notifyInputModeChange(inputMode, isHelpModeUpdate)
	if not self.isConsoleVersion then
		local v881_ = MessageType.INPUT_MODE_CHANGED
		if isHelpModeUpdate then
			v881_ = MessageType.INPUT_HELP_MODE_CHANGED
		end
		self.messageCenter:publish(v881_, InputBinding.MESSAGE_PARAM_INPUT_MODE[inputMode])
	end
end

-- Local values: isCorrupted, xmlFile1, rootName, xmlFile2, version1, version2
function InputBinding:checkSettingsIntegrity(inputBindingPath, inputBindingPathTemplate)
	local v884_ = loadXMLFile("InputBindings1", inputBindingPath)
	if v884_ == 0 then
		return false
	end
	local v885_ = getXMLRootName(v884_)
	local v886_ = not v885_ or v885_ == ""
	if v886_ then
		Logging.error("User input bindings corrupted. Replacing with defaults...")
	end
	local v887_ = loadXMLFile("InputBindings2", inputBindingPathTemplate)
	local v888_ = getXMLInt(v884_, "inputBinding#version") or 1
	local v889_ = getXMLInt(v887_, "inputBinding#version") or 1
	delete(v884_)
	delete(v887_)
	local v890_ = not v886_
	if v890_ then
		v890_ = v888_ == v889_
	end
	return v890_
end

-- Local values: groupId, exclusiveActions, i, actionName1, action1, j, action2, _, binding1, _, binding2, bothPrimary, sameInput
function InputBinding:checkDefaultInputExclusiveActionBindings()
	for v892_, v893_ in pairs(InputAction.EXCLUSIVE_ACTION_GROUPS) do
		for v894_, v895_ in ipairs(v893_) do
			local v896_ = self.nameActions[v895_]
			for v897_ = v894_ + 1, #v893_ do
				local v898_ = self.nameActions[v893_[v897_]]
				for _, v899_ in ipairs(v896_.bindings) do
					for _, v900_ in ipairs(v898_.bindings) do
						local v901_
						if v899_.index == 1 then
							v901_ = v900_.index == 1
						else
							v901_ = false
						end
						if v901_ and v899_.inputString == v900_.inputString then
							Logging.devError("Currently loaded input bindings have conflicting primary bindings in action group \'%s\' for actions [%s] and [%s], both bound to [%s]", v892_, v896_.name, v898_.name, v900_.inputString)
						end
					end
				end
			end
		end
	end
end

-- Local values: device, axisIndex, i, isSupported
function InputBinding:getBindingForceFeedbackInfo(binding)
	if binding == nil then
		return false, nil, 0
	else
		local v903_ = g_inputBinding:getDeviceById(binding.deviceId)
		local v904_ = nil
		for v905_ = 1, #binding.axisNames do
			v904_ = Input.axisIdNameToId[binding.axisNames[v905_]]
		end
		if v903_ == nil or v904_ == nil then
			return false, nil, 0
		else
			return v903_:getIsForceFeedbackSupported(v904_), v903_, v904_
		end
	end
end

-- Local values: action
function InputBinding:getNumActiveBindings(actionName)
	local v908_ = self.nameActions[actionName]
	return v908_ == nil and 0 or v908_:getNumActiveBindings()
end

-- Local values: context, action, actionEvents, _, event
function InputBinding:setContextEventsActive(contextName, actionName, isActive)
	local v913_ = self.contexts[contextName] or {}
	local v914_ = self.nameActions[actionName]
	local v915_ = v913_.actionEvents[v914_]
	for _, v916_ in ipairs(v915_) do
		self:setEventActive(v916_, isActive)
	end
end

-- Local values: isMouseAxis, axisId
function InputBinding.getIsPhysicalFullAxis(inputAxisName)
	local v918_ = InputBinding.MOUSE_AXES[inputAxisName] ~= nil
	local v919_ = Input.axisIdNameToId[inputAxisName]
	if not v918_ then
		if v919_ == nil then
			v918_ = false
		else
			v918_ = not Input.isHalfAxis(v919_)
		end
	end
	return v918_
end

-- Local values: gamepadAxisId
function InputBinding.getIsHalfAxis(inputAxisName)
	local v921_ = Input.axisIdNameToId[inputAxisName]
	return Input.isHalfAxis(v921_)
end

-- Local values: isMouseAxis, isGamepadAxis
function InputBinding.getIsAnalogInput(inputName)
	return InputBinding.MOUSE_AXES[inputName] and true or false or (Input.axisIdNameToId[inputName] and true or false)
end

-- Local values: isKb, _, inputAxisName
function InputBinding.getIsKeyboardInput(inputAxisNames)
	if not inputAxisNames or #inputAxisNames == 0 then
		return false
	end
	local v924_ = true
	for _, v925_ in pairs(inputAxisNames) do
		if v924_ then
			v924_ = Input.keyIdToIdName[Input[v925_]]
		end
	end
	return v924_
end

-- Local values: isMouse, _, inputAxisName
function InputBinding.getIsMouseInput(inputAxisNames)
	if not inputAxisNames or #inputAxisNames == 0 then
		return false
	end
	local v927_ = true
	for _, v928_ in pairs(inputAxisNames) do
		if v927_ then
			v927_ = InputBinding.MOUSE_AXES[v928_] or InputBinding.MOUSE_BUTTONS[v928_]
		end
	end
	return v927_
end

-- Local values: buttonId
function InputBinding.getIsMouseWheelInput(inputAxisNames)
	if not inputAxisNames or #inputAxisNames == 0 then
		return false
	end
	local v930_ = InputBinding.MOUSE_BUTTONS[inputAxisNames[1]] or ""
	return InputBinding.MOUSE_WHEEL[v930_]
end

-- Local values: isGamepad, _, inputAxisName
function InputBinding.getIsGamepadInput(inputAxisNames)
	if not inputAxisNames or #inputAxisNames == 0 then
		return false
	end
	local v932_ = true
	for _, v933_ in pairs(inputAxisNames) do
		if v932_ then
			v932_ = Input.axisIdNameToId[v933_] ~= nil and true or Input.buttonIdNameToId[v933_] ~= nil
		end
	end
	return v932_
end

-- Local values: buttonId
function InputBinding.getIsDPadInput(inputAxisNames)
	if inputAxisNames and #inputAxisNames ~= 0 then
		local v935_ = Input.buttonIdNameToId[inputAxisNames[1]]
		if v935_ == nil then
			return false
		else
			return InputBinding.GAMEPAD_DPAD[v935_]
		end
	else
		return false
	end
end

function InputBinding.isAxisZero(value)
	return value == nil and true or math.abs(value) < 0.0001
end

-- Local values: category, productId
function InputBinding.getDeviceCategory(internalDeviceId)
	if internalDeviceId == InputBinding.KB_MOUSE_INTERNAL_ID then
		return InputDevice.CATEGORY.KEYBOARD_MOUSE
	end
	local v938_ = getGamepadCategory(internalDeviceId)
	if v938_ == InputDevice.CATEGORY.FARMJOYSTICK_THRUSTMASTER then
		local v939_ = getGamepadProductId(internalDeviceId)
		if table.hasElement(InputBinding.THURSTMASTER_FARMJOYSTICK_LEFT_PRODUCT_IDS, v939_) then
			v938_ = InputDevice.CATEGORY.FARMJOYSTICK_THRUSTMASTER_LEFT
		end
	end
	return v938_
end

-- Local values: action, eventList, i, event, _, context, action, eventList, i, event
function InputBinding:printAll()
	for _, v941_ in pairs(self.actionEvents) do
		for v942_ = #v941_, 1, -1 do
			local v943_ = v941_[v942_]
			log(nil, self.currentContextName, "EventTable:", self.actionEvents, v943_)
		end
	end
	for _, v944_ in pairs(self.contexts) do
		for _, v945_ in pairs(v944_.actionEvents) do
			for v946_ = #v945_, 1, -1 do
				local v947_ = v945_[v946_]
				log(v944_, v944_.name, "EventTable:", v944_.actionEvents, v947_)
			end
		end
	end
end

-- Local values: context, action, events, _, binding, _, event
function InputBinding:debugPrintInputContext(contextName)
	local v950_ = contextName or self.currentContextName
	local v951_ = self.contexts[v950_] or {}
	printf("Context [%s]: previousContextName=%s, eventOrderCounter=%s", v950_, v951_.previousContextName, v951_.eventOrderCounter)
	for v952_, v953_ in pairs(v951_.actionEvents) do
		printf("  Action %s", v952_)
		printf("    Bindings:")
		for _, v954_ in ipairs(v952_:getBindings()) do
			printf("      %s", v954_)
		end
		printf("    Events:")
		for _, v955_ in ipairs(v953_) do
			printf("      %s", v955_)
		end
	end
end

-- Local values: xPos, yPos, textSize, spacing, actions, _, action, _, action, bindings, text
function InputBinding:debugRenderRegisteredActions()
	local v957_ = {}
	local v958_ = 0.01
	local v959_ = 0.98
	for _, v960_ in ipairs(self.actions) do
		table.insert(v957_, v960_)
	end
	table.sort(v957_, function(p961_, p962_)
		return p961_.name < p962_.name
	end)
	for _, v963_ in ipairs(v957_) do
		local v964_ = v963_:getBindings()
		local v965_ = string.format("%s (%d Bindings)", v963_.name, #v964_)
		setTextBold(true)
		setTextColor(0, 0, 0, 1)
		renderText(v958_, v959_, 0.012, v965_)
		setTextColor(1, 1, 1, 1)
		renderText(v958_ + g_pixelSizeX, v959_ + g_pixelSizeY, 0.012, string.format("%s (%d Bindings)", v963_.name, #v964_))
		v959_ = v959_ - 0.012 - 0.0005
		if v959_ < 0 then
			v958_ = v958_ + 0.2
			v959_ = 0.98
		end
	end
	setTextColor(1, 1, 1, 1)
end

-- Local values: context, posX, posY, textSize, textSizeDevice, textOffset, numColumns, action, events, _, d, action, events, neededLines, actionText, currentDeviceId, activeBindings, _, binding, isActive, _, event, target, className
function InputBinding:debugRenderInputContext(contextName)
	local v968_ = contextName or self.currentContextName
	local v969_ = self.contexts[v968_] or {}
	new2DLayer()
	drawFilledRect(0, 0, 1, 1, 0, 0, 0, 0.8)
	setTextBold(false)
	setTextAlignment(RenderText.ALIGN_LEFT)
	renderText(0.01, 0.98, 0.015, string.format("Context [%s]: previousContextName=%s, eventOrderCounter=%s", v968_, v969_.previousContextName, v969_.eventOrderCounter))
	self.debugActionEvents = self.debugActionEvents or {}
	table.clear(self.debugActionEvents)
	local v970_ = 0.96
	local v971_ = 0.01
	local v972_ = 1
	for v973_, v974_ in pairs(v969_.actionEvents) do
		local v975_ = self.debugActionEvents
		table.insert(v975_, { v973_, v974_ })
	end
	table.sort(self.debugActionEvents, function(p976_, p977_)
		return p976_[1].name < p977_[1].name
	end)
	for _, v978_ in ipairs(self.debugActionEvents) do
		local v979_ = v978_[1]
		local v980_ = v978_[2]
		if v970_ - (1 + 1.5 * #v979_:getBindings() + #v980_) * 0.013 < 0 then
			v970_ = 0.96
			v971_ = v971_ + 0.26
			v972_ = v972_ + 1
			if v972_ > 2 then
				new2DLayer()
			end
		end
		setTextColor(1, 0.3, 0.3, 1)
		setTextBold(true)
		local v981_ = string.format("%s (%s) - isLocked:%s", v979_.name, v979_.axisType, v979_.isLocked)
		renderText(v971_, v970_, 0.01, v981_)
		setTextBold(false)
		local v982_ = v970_ - 0.011
		local v983_ = v979_:getActiveBindings()
		local v984_ = nil
		for _, v985_ in ipairs(v979_:getBindings()) do
			setTextColor(0.4, 0.4, 0.4, 1)
			if v984_ ~= v985_.deviceId then
				v984_ = v985_.deviceId
				local v986_ = renderText
				local v987_ = v971_ + 0.005
				local v988_ = v985_.deviceId
				local v989_ = v985_.deviceId
				local v990_ = string.len(v989_) - 80
				local v991_ = math.max(1, v990_)
				local v992_ = string.sub(v988_, v991_)
				v986_(v987_, v982_, 0.007, "Device: " .. tostring(v992_))
				v982_ = v982_ - 0.0105
			end
			local v993_ = table.hasElement(v983_, v985_)
			setTextColor(1, 1, 1, 1)
			if v985_.isShadowed then
				setTextColor(1, 0, 0, 1)
				if v985_.inputValue ~= 0 then
					setTextColor(0.4, 0.4, 0, 1)
				end
			elseif v993_ then
				if v985_.inputValue ~= 0 then
					setTextColor(0, 1, 0, 1)
				end
			else
				setTextColor(0.4, 0.4, 0.4, 1)
				if v985_.inputValue ~= 0 then
					setTextColor(0, 0.4, 0, 1)
				end
			end
			local v994_ = renderText
			local v995_ = v971_ + 0.005
			local v996_ = v985_.isActive
			v994_(v995_, v982_, 0.009, "    Active: " .. tostring(v996_))
			local v997_ = renderText
			local v998_ = v971_ + 0.04
			local v999_ = v985_.isShadowed
			v997_(v998_, v982_, 0.009, "Shadowed: " .. tostring(v999_))
			renderText(v971_ + 0.08, v982_, 0.009, "Value: " .. string.format("%.4f", v985_.inputValue))
			local v1000_ = renderText
			local v1001_ = v971_ + 0.12
			local v1002_ = v985_.index
			local v1003_ = tostring(v1002_)
			local v1004_ = table.concat(v985_.axisNames, ", ")
			local v1005_ = v985_.axisComponent
			v1000_(v1001_, v982_, 0.009, v1003_ .. ": [" .. v1004_ .. "] " .. tostring(v1005_))
			v982_ = v982_ - 0.0105
		end
		setTextColor(1, 1, 1, 1)
		local v1006_ = v982_ - 0.003
		for _, v1007_ in ipairs(v980_) do
			local v1008_ = renderText
			local v1009_ = v971_ + 0.005
			local v1010_ = v1007_.isActive
			v1008_(v1009_, v1006_, 0.009, "E: Active: " .. tostring(v1010_))
			local v1011_ = renderText
			local v1012_ = v971_ + 0.04
			local v1013_ = v1007_.displayIsVisible
			v1011_(v1012_, v1006_, 0.009, "Visible: " .. tostring(v1013_))
			local v1014_ = renderText
			local v1015_ = v971_ + 0.08
			local v1016_ = v1007_.hasFrameTriggered
			v1014_(v1015_, v1006_, 0.009, "Triggered: " .. tostring(v1016_))
			local v1017_ = v1007_.targetObject
			local v1018_ = tostring(v1017_)
			local v1019_ = ClassUtil.getClassNameByObject(v1007_.targetObject)
			if v1019_ ~= nil then
				v1018_ = string.format("%s (%s)", v1019_, v1018_)
			end
			renderText(v971_ + 0.12, v1006_, 0.009, "Target: " .. v1018_)
			v1006_ = v1006_ - 0.0105
		end
		v970_ = v1006_ - 0.006
	end
end

function InputBinding:consoleCommandEnableInputDebug()
	self.debugEnabled = not self.debugEnabled
	local v1021_ = self.debugEnabled
	return "InputBinding.debugEnabled = " .. tostring(v1021_)
end

function InputBinding:consoleCommandPrintInputContext(enable)
	self:debugPrintInputContext()
end

function InputBinding:consoleCommandShowInputContext(enable)
	self.debugContextEnabled = not self.debugContextEnabled
end

function InputBinding:consoleCommandShowRegisteredActions(enable)
	self.debugRegisteredActions = not self.debugRegisteredActions
end
