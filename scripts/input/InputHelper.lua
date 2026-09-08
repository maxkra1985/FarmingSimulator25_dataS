MouseHelper = {}
KeyboardHelper = {}
GamepadHelper = {}

function MouseHelper.getButtonName(mouseButtonId)
	return getMouseButtonName(mouseButtonId)
end

-- Local values: buttonsText, i, buttonId, buttonName
function MouseHelper.getButtonNames(buttonIdList)
	local v3_ = ""
	for v4_, v5_ in ipairs(buttonIdList) do
		local v6_ = getMouseButtonName(v5_)
		if v6_ then
			if v4_ ~= 1 then
				v3_ = v3_ .. " "
			end
			v3_ = v3_ .. v6_
		end
	end
	return v3_
end

-- Local values: names, _, inputName, inputId, axisText

-- Local values: names, _, keyName, keyId
function MouseHelper.getInputDisplayText(keyNames)
	local v8_ = {}
	for _, v9_ in ipairs(keyNames) do
		local v10_ = InputBinding.MOUSE_AXES[v9_]
		if v10_ then
			local v11_ = v10_ == Input.AXIS_Y and "Y" or "X"
			table.insert(v8_, v11_)
		else
			local v12_ = InputBinding.MOUSE_BUTTONS[v9_]
			if v12_ then
				local v13_ = getMouseButtonName
				table.insert(v8_, v13_(v12_))
			end
		end
	end
	return table.concat(v8_, ", ")
end

-- Local values: buttonsText, i, buttonId, buttonIdName

-- Local values: buttonString, i, buttonId
function MouseHelper.getButtonsXMLString(buttonIdList)
	local v15_ = ""
	for v16_, v17_ in ipairs(buttonIdList) do
		local v18_ = Input.mouseButtonIdToIdName[v17_]
		if v18_ ~= nil then
			if v16_ ~= 1 then
				v15_ = v15_ .. " "
			end
			v15_ = v15_ .. v18_
		end
	end
	return v15_
end
KeyboardHelper.KEY_GLYPHS = {
	[13] = "keyGlyph_return",
	[271] = "keyGlyph_enter",
	[8] = "keyGlyph_backspace",
	[27] = "keyGlyph_escape",
	[32] = "keyGlyph_space",
	[273] = "keyGlyph_up",
	[274] = "keyGlyph_down",
	[275] = "keyGlyph_right",
	[276] = "keyGlyph_left",
	[306] = "keyGlyph_ctrl",
	[308] = "keyGlyph_alt"
}
if getPlatformId() == PlatformId.MAC then
	KeyboardHelper.KEY_GLYPHS[308] = "keyGlyph_option"
end

-- Local values: keyName, glyphSymbol
function KeyboardHelper.getDisplayKeyName(keyId)
	local v20_ = KeyboardHelper.KEY_GLYPHS[keyId]
	local v21_
	if v20_ == nil then
		v21_ = nil
	else
		v21_ = g_i18n:getText(v20_)
	end
	if v21_ == nil then
		v21_ = getKeyName(keyId)
	end
	return v21_
end

-- Local values: keyText, i, keyId
function KeyboardHelper.getKeyNames(keyList)
	local v23_ = ""
	for v24_, v25_ in ipairs(keyList) do
		if v24_ ~= 1 then
			v23_ = v23_ .. " "
		end
		v23_ = v23_ .. KeyboardHelper.getDisplayKeyName(v25_)
	end
	return v23_
end

-- Local values: keyTable, _, keyId
function KeyboardHelper.getKeyNameTable(keyList)
	local v27_ = {}
	for _, v28_ in ipairs(keyList) do
		local v29_ = KeyboardHelper.getDisplayKeyName
		table.insert(v27_, v29_(v28_))
	end
	return v27_
end
function KeyboardHelper.getInputDisplayText(p30_)
	local v31_ = {}
	for _, v32_ in ipairs(p30_) do
		local v33_ = Input[v32_]
		local v34_ = KeyboardHelper.getDisplayKeyName
		table.insert(v31_, v34_(v33_))
	end
	return table.concat(v31_, ", ")
end

-- Local values: keyText, i, keyId, keyString
function KeyboardHelper.getKeysXMLString(keyList)
	if keyList == nil or keyList == -1 then
		return ""
	end
	local v36_ = ""
	for v37_, v38_ in ipairs(keyList) do
		local v39_ = Input.keyIdToIdName[v38_]
		if v39_ ~= nil then
			if v37_ ~= 1 then
				v36_ = v36_ .. " "
			end
			v36_ = v36_ .. v39_
		end
	end
	return v36_
end

-- Local values: gamepadList, gamepadListData, gamepadId, gamepadData, gamepadButtonId, _, gamepadAxisId, _, finalString, buttonsString, axesString, _, gamepadId, j, gamepadButtonId, j, gamepadAxisId
function GamepadHelper.getGamepadInputCombinedName(gamepadsHash)
	local v41_ = {}
	local v42_ = {}
	for v43_, v44_ in pairs(gamepadsHash) do
		table.insert(v41_, v43_)
		v42_[v43_] = {}
		v42_[v43_].buttonsList = {}
		v42_[v43_].axesList = {}
		for v45_, _ in pairs(v44_.buttons) do
			local v46_ = v42_[v43_].buttonsList
			table.insert(v46_, v45_)
		end
		for v47_, _ in pairs(v44_.axes) do
			local v48_ = v42_[v43_].axesList
			table.insert(v48_, v47_)
		end
		table.sort(v42_[v43_].buttonsList)
		table.sort(v42_[v43_].axesList)
	end
	table.sort(v41_)
	local v49_ = ""
	local v50_ = ""
	for _, v51_ in ipairs(v41_) do
		for v52_, v53_ in ipairs(v42_[v51_].buttonsList) do
			v49_ = v49_ .. (v52_ == 1 and "" or ", ") .. GamepadHelper.getButtonName(v53_, v51_)
		end
		for v54_, v55_ in ipairs(v42_[v51_].axesList) do
			v50_ = v50_ .. (v54_ == 1 and "" or ", ") .. GamepadHelper.getAxisName(v55_, v51_)
		end
	end
	return (v49_ == "" and "" or (g_i18n:getText("ui_button") .. " " .. v49_ .. " " or "")) .. (v50_ == "" and "" or (g_i18n:getText("ui_axis") .. " " .. v50_ or ""))
end
function GamepadHelper.getButtonName(p56_, p57_)
	if p56_ == nil then
		return ""
	end
	local v58_ = p57_ == nil and 0 or p57_
	return getGamepadButtonLabel(p56_, v58_)
end

function GamepadHelper.getAxisName(axisId, deviceId)
	return axisId == nil and "" or getGamepadAxisLabel(axisId, deviceId)
end
function GamepadHelper.getButtonNames(p61_, p62_)
	if p61_ == nil then
		return ""
	end
	local v63_ = #p61_
	local v64_ = ""
	for v65_, v66_ in ipairs(p61_) do
		local v67_ = GamepadHelper.getButtonName(v66_, (v65_ == v63_ or not p62_) and 0 or p62_)
		v64_ = v64_ .. (v65_ == 1 and "" or " ") .. v67_
	end
	local v68_ = ""
	if v63_ == 1 then
		v68_ = g_i18n:getText("ui_button") .. " "
	elseif v63_ > 1 then
		v68_ = g_i18n:getText("ui_buttons") .. " "
	end
	return v68_ .. v64_
end

-- Local values: buttonString, axisString, gamePadName, deviceString
function GamepadHelper.getButtonAndAxisNames(buttonIdList, axisId, deviceId)
	local v72_ = GamepadHelper.getButtonNames(buttonIdList)
	local v73_ = GamepadHelper.getAxisName(axisId, deviceId)
	local v74_ = "(\'" .. GamepadHelper.getLocalizedGamepadName(deviceId) .. "\' " .. GamepadHelper.getDeviceString(deviceId) .. ")"
	return v72_ .. ((v72_ == "" or v73_ == "") and "" or ", ") .. ((v73_ == "" or not v73_) and "" or v73_) .. (v72_ == "" and v73_ == "" and "" or (" " .. v74_ or ""))
end

-- Local values: gamepadName
function GamepadHelper.getLocalizedGamepadName(internalDeviceId)
	local v76_ = getGamepadName(internalDeviceId)
	if g_i18n:hasText(v76_) then
		v76_ = g_i18n:getText(v76_)
	end
	return v76_
end
function GamepadHelper.getInputDisplayText(p77_, p78_)
	local v79_ = {}
	for _, v80_ in ipairs(p77_) do
		if Input.buttonIdNameToId[v80_] then
			local v81_ = Input.buttonIdNameToId[v80_]
			local v82_ = GamepadHelper.getButtonName
			table.insert(v79_, v82_(v81_, p78_))
		elseif Input.axisIdNameToId[v80_] then
			local v83_ = Input.axisIdNameToId[v80_]
			local v84_ = GamepadHelper.getAxisName
			table.insert(v79_, v84_(v83_, p78_))
		end
	end
	local v85_ = GamepadHelper.getLocalizedGamepadName(p78_)
	return string.format("%s [%s]", table.concat(v79_, ", "), v85_)
end

function GamepadHelper.getDeviceString(deviceId)
	return "[" .. deviceId + 1 .. "]"
end
function GamepadHelper.getButtonsXMLString(p87_)
	if p87_ == nil then
		return ""
	end
	local v88_ = ""
	for v89_, v90_ in ipairs(p87_) do
		v88_ = v88_ .. (v89_ == 1 and "" or " ") .. "BUTTON" .. "_" .. v90_ + 1
	end
	return v88_
end

function GamepadHelper.getAxisXMLString(gamepadAxisId)
	return (gamepadAxisId == nil or gamepadAxisId == -1) and "" or "AXIS_" .. gamepadAxisId + 1
end

function GamepadHelper.getDeviceXMLInt(gamepadId)
	return (gamepadId == nil or gamepadId == -1) and 0 or gamepadId
end
