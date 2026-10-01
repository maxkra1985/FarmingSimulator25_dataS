MouseHelper = {}
KeyboardHelper = {}
GamepadHelper = {}
function MouseHelper.getButtonName(mouseButtonId)
	return getMouseButtonName(mouseButtonId)
end
function MouseHelper.getButtonNames(mouseButtons)
	local buttonsText = ""
	for i, buttonId in ipairs(mouseButtons) do
		local buttonName = getMouseButtonName(buttonId)
		if buttonName then
			if i ~= 1 then
				buttonsText = buttonsText .. " "
			end
			buttonsText = buttonsText .. buttonName
		end
	end
	return buttonsText
end
function MouseHelper.getInputDisplayText(mouseInputs)
	local names = {}
	for _, inputName in ipairs(mouseInputs) do
		local inputId = InputBinding.MOUSE_AXES[inputName]
		if inputId then
			local axisText = "X"
			if inputId == Input.AXIS_Y then
				axisText = "Y"
			end
			table.insert(names, axisText)
		else
			inputId = InputBinding.MOUSE_BUTTONS[inputName]
			if inputId then
				table.insert(names, getMouseButtonName(inputId))
			end
		end
	end
	return table.concat(names, ", ")
end
function MouseHelper.getButtonsXMLString(mouseButtons)
	local buttonsText = ""
	for i, buttonId in ipairs(mouseButtons) do
		local buttonIdName = Input.mouseButtonIdToIdName[buttonId]
		if buttonIdName == nil then
			continue
		end
		if i ~= 1 then
			buttonsText = buttonsText .. " "
		end
		buttonsText = buttonsText .. buttonIdName
	end
	return buttonsText
end
KeyboardHelper.KEY_GLYPHS = { [13] = "keyGlyph_return", [271] = "keyGlyph_enter", [8] = "keyGlyph_backspace", [27] = "keyGlyph_escape", [32] = "keyGlyph_space", [273] = "keyGlyph_up", [274] = "keyGlyph_down", [275] = "keyGlyph_right", [276] = "keyGlyph_left", [306] = "keyGlyph_ctrl", [308] = "keyGlyph_alt" }
if getPlatformId() == PlatformId.MAC then
	KeyboardHelper.KEY_GLYPHS[308] = "keyGlyph_option"
end
function KeyboardHelper.getDisplayKeyName(keyId)
	local keyName = nil
	local glyphSymbol = KeyboardHelper.KEY_GLYPHS[keyId]
	if glyphSymbol ~= nil then
		keyName = g_i18n:getText(glyphSymbol)
	end
	if keyName == nil then
		keyName = getKeyName(keyId)
	end
	return keyName
end
function KeyboardHelper.getKeyNames(keyList)
	local keyText = ""
	for i, keyId in ipairs(keyList) do
		if i ~= 1 then
			keyText = keyText .. " "
		end
		keyText = keyText .. KeyboardHelper.getDisplayKeyName(keyId)
	end
	return keyText
end
function KeyboardHelper.getKeyNameTable(keyList)
	local keyTable = {}
	for _, keyId in ipairs(keyList) do
		table.insert(keyTable, KeyboardHelper.getDisplayKeyName(keyId))
	end
	return keyTable
end
function KeyboardHelper.getInputDisplayText(keyNames)
	local names = {}
	for _, keyName in ipairs(keyNames) do
		local keyId = Input[keyName]
		table.insert(names, KeyboardHelper.getDisplayKeyName(keyId))
	end
	return table.concat(names, ", ")
end
function KeyboardHelper.getKeysXMLString(keyList)
	if keyList == nil or keyList == -1 then
		return ""
	end
	local keyText = ""
	for i, keyId in ipairs(keyList) do
		local keyString = Input.keyIdToIdName[keyId]
		if keyString == nil then
			continue
		end
		if i ~= 1 then
			keyText = keyText .. " "
		end
		keyText = keyText .. keyString
	end
	return keyText
end
function GamepadHelper.getGamepadInputCombinedName(gamepadsHash)
	local gamepadList = {}
	local gamepadListData = {}
	for gamepadId, gamepadData in pairs(gamepadsHash) do
		table.insert(gamepadList, gamepadId)
		gamepadListData[gamepadId] = {}
		gamepadListData[gamepadId].buttonsList = {}
		gamepadListData[gamepadId].axesList = {}
		for gamepadButtonId, _ in pairs(gamepadData.buttons) do
			table.insert(gamepadListData[gamepadId].buttonsList, gamepadButtonId)
		end
		for gamepadAxisId, _ in pairs(gamepadData.axes) do
			table.insert(gamepadListData[gamepadId].axesList, gamepadAxisId)
		end
		table.sort(gamepadListData[gamepadId].buttonsList)
		table.sort(gamepadListData[gamepadId].axesList)
	end
	table.sort(gamepadList)
	local finalString = nil
	local buttonsString = ""
	local axesString = ""
	for _, gamepadId in ipairs(gamepadList) do
		for j, gamepadButtonId in ipairs(gamepadListData[gamepadId].buttonsList) do
			buttonsString = buttonsString .. (j ~= 1 and ", " or "") .. GamepadHelper.getButtonName(gamepadButtonId, gamepadId)
		end
		for j, gamepadAxisId in ipairs(gamepadListData[gamepadId].axesList) do
			axesString = axesString .. (j ~= 1 and ", " or "") .. GamepadHelper.getAxisName(gamepadAxisId, gamepadId)
		end
	end
	if axesString ~= "" then
		local _v63 = g_i18n:getText("ui_axis") .. " " .. axesString or ""
	end
	finalString = (buttonsString ~= "" and g_i18n:getText("ui_button") .. " " .. buttonsString .. " " or "") .. ""
	return finalString
end
function GamepadHelper.getButtonName(buttonId, deviceId)
	if buttonId == nil then
		return ""
	else
		if deviceId == nil then
			deviceId = 0
		end
		return getGamepadButtonLabel(buttonId, deviceId)
	end
end
function GamepadHelper.getAxisName(axisId, deviceId)
	if axisId == nil then
		return ""
	else
		return getGamepadAxisLabel(axisId, deviceId)
	end
end
function GamepadHelper.getButtonNames(buttonIdList, deviceId)
	if buttonIdList == nil then
		return ""
	else
		local buttonString = ""
		local listCount = #buttonIdList
		for i, buttonId in ipairs(buttonIdList) do
			local currentButton = GamepadHelper.getButtonName(buttonId, i ~= listCount and deviceId or 0)
			buttonString = buttonString .. (i == 1 and "" or " ") .. currentButton
		end
		local buttonNamePrefix = ""
		if listCount == 1 then
			buttonNamePrefix = g_i18n:getText("ui_button") .. " "
		elseif 1 < listCount then
			buttonNamePrefix = g_i18n:getText("ui_buttons") .. " "
		end
		return buttonNamePrefix .. buttonString
	end
end
function GamepadHelper.getButtonAndAxisNames(buttonIdList, axisId, deviceId)
	local buttonString = GamepadHelper.getButtonNames(buttonIdList)
	local axisString = GamepadHelper.getAxisName(axisId, deviceId)
	local gamePadName = GamepadHelper.getLocalizedGamepadName(deviceId)
	local deviceString = "('" .. gamePadName .. "' " .. GamepadHelper.getDeviceString(deviceId) .. ")"
	if buttonString == "" then
		local _v9 = axisString ~= "" and " " .. deviceString or ""
	end
	local _v30 = " "
	local _v22 = deviceString
	return buttonString .. (buttonString ~= "" and axisString ~= "" and ", " or "") .. (axisString ~= "" and axisString or "") .. ""
end
function GamepadHelper.getLocalizedGamepadName(internalDeviceId)
	local gamepadName = getGamepadName(internalDeviceId)
	if g_i18n:hasText(gamepadName) then
		gamepadName = g_i18n:getText(gamepadName)
	end
	return gamepadName
end
function GamepadHelper.getInputDisplayText(inputList, internalDeviceId)
	local names = {}
	for _, input in ipairs(inputList) do
		if Input.buttonIdNameToId[input] then
			local buttonId = Input.buttonIdNameToId[input]
			table.insert(names, GamepadHelper.getButtonName(buttonId, internalDeviceId))
		elseif Input.axisIdNameToId[input] then
			local axisId = Input.axisIdNameToId[input]
			table.insert(names, GamepadHelper.getAxisName(axisId, internalDeviceId))
		end
	end
	local gamePadName = GamepadHelper.getLocalizedGamepadName(internalDeviceId)
	return string.format("%s [%s]", table.concat(names, ", "), gamePadName)
end
function GamepadHelper.getDeviceString(deviceId)
	return "[" .. deviceId + 1 .. "]"
end
function GamepadHelper.getButtonsXMLString(buttonIdList)
	if buttonIdList == nil then
		return ""
	else
		local buttonString = ""
		for i, buttonId in ipairs(buttonIdList) do
			buttonString = buttonString .. (i == 1 and "" or " ") .. "BUTTON" .. "_" .. buttonId + 1
		end
		return buttonString
	end
end
function GamepadHelper.getAxisXMLString(gamepadAxisId)
	if gamepadAxisId == nil or gamepadAxisId == -1 then
		return ""
	end
	return "AXIS_" .. gamepadAxisId + 1
end
function GamepadHelper.getDeviceXMLInt(gamepadId)
	if gamepadId == nil or gamepadId == -1 then
		return 0
	end
	return gamepadId
end
