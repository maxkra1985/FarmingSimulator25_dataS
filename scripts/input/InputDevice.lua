-- Local values: InputDevice_mt
InputDevice = {}
local InputDevice_mt = Class(InputDevice)
InputDevice.CATEGORY = {
	["UNKNOWN"] = GamepadCategories.CATEGORY_UNKNOWN,
	["GAMEPAD"] = GamepadCategories.CATEGORY_GAMEPAD,
	["WHEEL"] = GamepadCategories.CATEGORY_WHEEL,
	["JOYSTICK"] = GamepadCategories.CATEGORY_JOYSTICK,
	["FARMWHEEL"] = GamepadCategories.CATEGORY_FARMWHEEL,
	["FARMPANEL"] = GamepadCategories.CATEGORY_FARMSIDEPANEL,
	["FARMWHEEL_HORI"] = GamepadCategories.CATEGORY_FARMWHEEL_HORI,
	["FARMPANEL_HORI"] = GamepadCategories.CATEGORY_FARMSIDEPANEL_HORI,
	["FARMPANEL_MOZA"] = GamepadCategories.CATEGORY_FARMSIDEPANEL_MOZA,
	["FARMJOYSTICK_THRUSTMASTER"] = GamepadCategories.CATEGORY_FARMJOYSTICK_THRUSTMASTER,
	["FARMJOYSTICK_THRUSTMASTER_LEFT"] = 251,
	["FARMJOYSTICK_THRUSTMASTER_DUAL"] = 252,
	["KEYBOARD_MOUSE"] = 253,
	["WHEEL_AND_PANEL"] = 254,
	["FARMWHEEL_AND_PANEL"] = 255
}
InputDevice.DEFAULT_DEVICE_NAMES = {
	["KB_MOUSE_DEFAULT"] = "KB_MOUSE_DEFAULT",
	["GAMEPAD_DEFAULT"] = "GAMEPAD_DEFAULT",
	["JOYSTICK_DEFAULT"] = "JOYSTICK_DEFAULT",
	["WHEEL_DEFAULT"] = "WHEEL_DEFAULT",
	["FARM_WHEEL_DEFAULT"] = "FARM_WHEEL_DEFAULT",
	["PANEL_DEFAULT"] = "PANEL_DEFAULT",
	["FARM_WHEEL_HORI_DEFAULT"] = "FARM_WHEEL_HORI_DEFAULT",
	["FARM_PANEL_HORI_DEFAULT"] = "FARM_PANEL_HORI_DEFAULT",
	["FARM_JOYSTICK_THRUSTMASTER_DEFAULT"] = "FARM_JOYSTICK_THRUSTMASTER_DEFAULT",
	["FARM_JOYSTICK_THRUSTMASTER_DEFAULT_LEFT"] = "FARM_JOYSTICK_THRUSTMASTER_DEFAULT_LEFT",
	["FARM_PANEL_MOZA_DEFAULT"] = "FARM_PANEL_MOZA_DEFAULT"
}
InputDevice.NAMES = {
	["SAITEK_WHEEL"] = "Saitek Heavy Eqpt. Wheel & Pedal",
	["SAITEK_PANEL"] = "Saitek Side Panel Control Deck",
	["HORI_WHEEL"] = "HORI FARMING CONTROLLER STEERING",
	["HORI_PANEL"] = "HORI FARMING CONTROLLER PANEL",
	["XINPUT_GAMEPAD"] = "XINPUT_GAMEPAD",
	["XBOX_GAMEPAD"] = "Xbox Gamepad",
	["PS_GAMEPAD"] = "DUALSHOCK(R)4",
	["PS5_GAMEPAD"] = "DualSense Wireless Controller",
	["STADIA_GAMEPAD"] = "Stadia Controller",
	["SWITCH_GAMEPAD"] = "Nintendo Controller",
	["MOZA_PANEL"] = "MOZA Farming Control System"
}
InputDevice.DEFAULT_DEVICE_CATEGORIES = {
	[InputDevice.DEFAULT_DEVICE_NAMES.KB_MOUSE_DEFAULT] = InputDevice.CATEGORY.KEYBOARD_MOUSE,
	[InputDevice.DEFAULT_DEVICE_NAMES.GAMEPAD_DEFAULT] = InputDevice.CATEGORY.GAMEPAD,
	[InputDevice.DEFAULT_DEVICE_NAMES.JOYSTICK_DEFAULT] = InputDevice.CATEGORY.JOYSTICK,
	[InputDevice.DEFAULT_DEVICE_NAMES.WHEEL_DEFAULT] = InputDevice.CATEGORY.WHEEL,
	[InputDevice.DEFAULT_DEVICE_NAMES.FARM_WHEEL_DEFAULT] = InputDevice.CATEGORY.FARMWHEEL,
	[InputDevice.DEFAULT_DEVICE_NAMES.PANEL_DEFAULT] = InputDevice.CATEGORY.FARMPANEL,
	[InputDevice.DEFAULT_DEVICE_NAMES.FARM_WHEEL_HORI_DEFAULT] = InputDevice.CATEGORY.FARMWHEEL_HORI,
	[InputDevice.DEFAULT_DEVICE_NAMES.FARM_PANEL_HORI_DEFAULT] = InputDevice.CATEGORY.FARMPANEL_HORI,
	[InputDevice.DEFAULT_DEVICE_NAMES.FARM_JOYSTICK_THRUSTMASTER_DEFAULT] = InputDevice.CATEGORY.FARMJOYSTICK_THRUSTMASTER,
	[InputDevice.DEFAULT_DEVICE_NAMES.FARM_JOYSTICK_THRUSTMASTER_DEFAULT_LEFT] = InputDevice.CATEGORY.FARMJOYSTICK_THRUSTMASTER_LEFT,
	[InputDevice.DEFAULT_DEVICE_NAMES.FARM_PANEL_MOZA_DEFAULT] = InputDevice.CATEGORY.FARMPANEL_MOZA
}

-- Upvalues: InputDevice_mt
-- Local values: self, i, state
function InputDevice.new(internalId, deviceId, deviceName, category)
	-- upvalues: (copy) InputDevice_mt
	local v6_ = InputDevice_mt
	local v7_ = setmetatable({}, v6_)
	v7_.internalId = internalId
	v7_.deviceId = deviceId
	v7_.deviceName = deviceName
	v7_.category = category
	v7_.deadzones = {}
	v7_.sensitivities = {}
	v7_.isActive = false
	v7_.forceFeedbackState = {}
	for v8_ = 0, Input.MAX_NUM_AXES do
		v7_.forceFeedbackState[v8_] = {
			["isSupported"] = nil,
			["force"] = 0,
			["position"] = 0
		}
	end
	return v7_
end

-- Local values: attrIndex, attributeKey, axis, deadzone, sensitivity
function InputDevice:loadSettingsFromXML(xmlFile, deviceElement)
	self.deadzones = {}
	self.sensitivities = {}
	local v12_ = 0
	while true do
		local v13_ = string.format(deviceElement .. ".attributes(%d)", v12_)
		if not hasXMLProperty(xmlFile, v13_) then
			break
		end
		local v14_ = getXMLInt(xmlFile, v13_ .. "#axis")
		if v14_ then
			local v15_ = getXMLFloat(xmlFile, v13_ .. "#deadzone")
			self.deadzones[v14_] = v15_ or getGamepadDefaultDeadzone()
			local v16_ = getXMLFloat(xmlFile, v13_ .. "#sensitivity")
			self.sensitivities[v14_] = v16_ or 1
		end
		v12_ = v12_ + 1
	end
end

-- Local values: firstAttributeKey, writtenIndex, axisIndex, hasAxis, attributeKey
function InputDevice:saveSettingsToXML(xmlFile, deviceElement)
	setXMLString(xmlFile, deviceElement .. "#id", self.deviceId)
	setXMLString(xmlFile, deviceElement .. "#name", self.deviceName)
	setXMLInt(xmlFile, deviceElement .. "#category", self.category)
	local v20_ = deviceElement .. ".attributes(0)"
	while hasXMLProperty(xmlFile, v20_) do
		removeXMLProperty(xmlFile, v20_)
	end
	local v21_ = 0
	for v22_ = 0, Input.MAX_NUM_AXES - 1 do
		local v23_
		if self.internalId >= 0 then
			v23_ = getHasGamepadAxis(v22_, self.internalId)
		else
			v23_ = self.deadzones[v22_] ~= nil and true or self.sensitivities[v22_] ~= nil
		end
		if v23_ then
			local v24_ = string.format(deviceElement .. ".attributes(%d)", v21_)
			setXMLInt(xmlFile, v24_ .. "#axis", v22_)
			setXMLFloat(xmlFile, v24_ .. "#deadzone", self:getDeadzone(v22_))
			setXMLFloat(xmlFile, v24_ .. "#sensitivity", self:getSensitivity(v22_))
			v21_ = v21_ + 1
		end
	end
end

function InputDevice:isController()
	local v26_ = self.category
	if v26_ then
		v26_ = self.category ~= InputDevice.CATEGORY.KEYBOARD_MOUSE
	end
	return v26_
end

function InputDevice:setDeadzone(axisIndex, deadzone)
	self.deadzones[axisIndex] = deadzone
end

function InputDevice:getDeadzone(axisIndex)
	if self.deadzones[axisIndex] == nil then
		return getGamepadDefaultDeadzone()
	else
		return self.deadzones[axisIndex]
	end
end

function InputDevice:setSensitivity(axisIndex, sensitivity)
	self.sensitivities[axisIndex] = sensitivity
end

function InputDevice:getSensitivity(axisIndex)
	return self.sensitivities[axisIndex] == nil and 1 or self.sensitivities[axisIndex]
end

-- Local values: axisState
function InputDevice:updateForceFeedbackState(axisIndex)
	local v39_ = self.forceFeedbackState[axisIndex]
	if v39_ ~= nil and v39_.isSupported == nil then
		v39_.isSupported = getHasGamepadAxisForceFeedback(self.internalId, axisIndex)
	end
	return false
end

-- Local values: axisState
function InputDevice:getIsForceFeedbackSupported(axisIndex)
	local v42_ = self.forceFeedbackState[axisIndex]
	if v42_ == nil or v42_.isSupported == nil then
		return false
	else
		return v42_.isSupported
	end
end

-- Local values: axisState
function InputDevice:setForceFeedback(axisIndex, force, position)
	local v47_ = self.forceFeedbackState[axisIndex]
	if v47_ ~= nil then
		v47_.force = force
		v47_.position = position
		setGamepadAxisForceFeedback(self.internalId, axisIndex, force, position)
	end
end

function InputDevice.loadIdFromXML(xmlFile, deviceElement)
	return getXMLString(xmlFile, deviceElement .. "#id") or ""
end

function InputDevice.loadNameFromXML(xmlFile, deviceElement)
	return getXMLString(xmlFile, deviceElement .. "#name") or ""
end

function InputDevice.loadCategoryFromXML(xmlFile, deviceElement)
	return getXMLInt(xmlFile, deviceElement .. "#category") or InputDevice.CATEGORY.UNKNOWN
end

-- Local values: prefix, engineDeviceId, number
function InputDevice.getDeviceIdPrefix(deviceId)
	local v55_, v56_ = string.match(deviceId, "^(-?%d+)_(.+)$")
	return not (v55_ and tonumber(v55_)) and -1 or tonumber(v55_), v56_
end

function InputDevice.getPrefixedDeviceId(deviceId, number)
	return string.format("%d_%s", number, deviceId)
end

function InputDevice.getIsDeviceSupported(engineDeviceId, deviceName)
	return deviceName ~= IgnitionLockManager.DEVICE_NAME
end

function InputDevice:toString()
	local v61_ = string.format
	local v62_ = self.deviceName
	local v63_ = tostring(v62_)
	local v64_ = self.isActive
	local v65_ = tostring(v64_)
	local v66_ = self.internalId
	local v67_ = tostring(v66_)
	local v68_ = self.deviceId
	local v69_ = tostring(v68_)
	local v70_ = self.category
	return v61_("[%s (active: %s), internalId: %s, deviceId: %s, category: %s]", v63_, v65_, v67_, v69_, (tostring(v70_)))
end
InputDevice_mt.__tostring = InputDevice.toString
