-- Local values: ControlsController_mt, NO_CALLBACK, sortMouseAxisNames
ControlsController = {
	["BINDING_PRIMARY"] = 1,
	["BINDING_SECONDARY"] = 2,
	["BINDING_TERTIARY"] = 3,
	["AXIS_DIRECTION_POSITIVE"] = 1,
	["AXIS_DIRECTION_NEGATIVE"] = -1,
	["MESSAGE_CLEAR"] = 0,
	["MESSAGE_CANNOT_MAP_KEY"] = 1,
	["MESSAGE_CANNOT_MAP_MOUSE"] = 2,
	["MESSAGE_CANNOT_MAP_CONTROLLER"] = 3,
	["MESSAGE_PROMPT_KEY"] = 4,
	["MESSAGE_PROMPT_MOUSE"] = 5,
	["MESSAGE_PROMPT_CONTROLLER"] = 6,
	["MESSAGE_PROMPT_CANCEL_DELETE"] = 7,
	["MESSAGE_SELECT_ACTION"] = 8,
	["MESSAGE_CONFLICT_KEY"] = 9,
	["MESSAGE_CONFLICT_MOUSE"] = 10,
	["MESSAGE_CONFLICT_BUTTON"] = 11,
	["MESSAGE_CONFLICT_AXIS"] = 12,
	["MESSAGE_REMAPPED"] = 13,
	["MESSAGE_ENSURE_IN_NEUTRAL"] = 14,
	["MESSAGE_CONFLICT_BLOCKED_KEY"] = 15,
	["AXIS_NAME_X"] = "X",
	["AXIS_NAME_Y"] = "Y",
	["AXIS_AFFIX_POSITIVE"] = "(+)",
	["AXIS_AFFIX_NEGATIVE"] = "(-)",
	["MODIFIER_BUTTON_CONCAT"] = " + "
}
local v1_ = ControlsController
local v2_ = {
	[ControlsController.BINDING_PRIMARY] = {
		[InputAction.MENU] = true,
		[InputAction.MENU_CANCEL] = true,
		[InputAction.MENU_BACK] = true,
		[InputAction.MENU_ACCEPT] = true,
		[InputAction.MENU_ACTIVATE] = true,
		[InputAction.MENU_PAGE_PREV] = true,
		[InputAction.MENU_PAGE_NEXT] = true,
		[InputAction.MENU_AXIS_UP_DOWN] = true,
		[InputAction.MENU_AXIS_UP_DOWN_SECONDARY] = true,
		[InputAction.MENU_AXIS_LEFT_RIGHT] = true
	},
	[ControlsController.BINDING_SECONDARY] = {},
	[ControlsController.BINDING_TERTIARY] = {}
}
v1_.LOCKED_BINDINGS = v2_
local ControlsController_mt = Class(ControlsController)
ControlsController.INPUT_DELAY = 500
ControlsController.MOUSE_MOVE_THRESHOLD = 10
local function NO_CALLBACK() end
function ControlsController.new()
	-- upvalues: (copy) ControlsController_mt, (copy) NO_CALLBACK
	local v5_ = ControlsController_mt
	local v6_ = setmetatable({}, v5_)
	v6_.messageCallback = NO_CALLBACK
	v6_.inputDoneCallback = NO_CALLBACK
	v6_.controlsActions = {}
	v6_.controlsAnalogActions = {}
	v6_.controlsDigitalActions = {}
	v6_.actionBindings = nil
	v6_.waitForInput = false
	v6_.gatheringDevice = nil
	v6_.gatheringBindingIndex = nil
	v6_.gatheringAction = nil
	v6_.gatheringActionIndex = 0
	v6_.mouseMoveThresholdX = ControlsController.MOUSE_MOVE_THRESHOLD * g_pixelSizeScaledX
	v6_.mouseMoveThresholdY = ControlsController.MOUSE_MOVE_THRESHOLD * g_pixelSizeScaledY
	v6_:loadBindings()
	return v6_
end

-- Upvalues: NO_CALLBACK
function ControlsController:setMessageCallback(messageCallback)
	-- upvalues: (copy) NO_CALLBACK
	self.messageCallback = messageCallback or NO_CALLBACK
end

-- Upvalues: NO_CALLBACK
function ControlsController:setInputDoneCallback(inputDoneCallback)
	-- upvalues: (copy) NO_CALLBACK
	self.inputDoneCallback = inputDoneCallback or NO_CALLBACK
end

-- Local values: action, bindings, displayActionBinding, needKbMouse, needController, needsAllBindings, axisComponent, _, binding, isBindingKbMouse, matchCategory, inputText, index
function ControlsController:createDisplayAction(deviceCategory, actionBinding, isAxisPositive, deviceToBindingIndexMapping)
	local v16_ = actionBinding.action
	local v17_ = actionBinding.bindings
	local v18_ = DisplayActionBinding.new(v16_, v16_.displayNamePositive, isAxisPositive, v17_)
	if not isAxisPositive then
		v18_.displayName = v16_.displayNameNegative
	end
	local v19_ = deviceCategory == InputDevice.CATEGORY.KEYBOARD_MOUSE
	local v20_ = deviceCategory == InputDevice.CATEGORY.GAMEPAD
	local v21_ = isAxisPositive and Binding.AXIS_COMPONENT.POSITIVE or Binding.AXIS_COMPONENT.NEGATIVE
	local v22_ = not (v19_ or v20_)
	for _, v23_ in ipairs(v17_) do
		local v24_ = v23_.deviceId == InputDevice.DEFAULT_DEVICE_NAMES.KB_MOUSE_DEFAULT
		local v25_
		if v22_ then
			v25_ = v22_
		elseif v19_ and v24_ then
			v25_ = v24_
		elseif v20_ then
			v25_ = not v24_
		else
			v25_ = v20_
		end
		if v25_ and v23_.axisComponent == v21_ then
			local v26_ = self:getBindingInputDisplayText(v23_)
			local v27_ = v24_ and v23_.index or deviceToBindingIndexMapping[v23_.deviceId]
			if v27_ ~= nil then
				v18_:setBindingDisplay(v23_, v26_, v27_)
			end
		end
	end
	return v18_
end

-- Local values: categories, categoryMapping, deviceToBindingIndexMapping, index, device, _, actionBinding, bindingCategory, cat
function ControlsController:getDeviceCategoryActionBindings(deviceCategory)
	self.numGamepads = getNumOfGamepads()
	local v30_ = {}
	local v31_ = {}
	local v32_ = {}
	for v33_, v34_ in pairs(g_inputBinding:getGamepadDevices()) do
		v30_[v34_.deviceId] = v33_ + 3
	end
	for _, v35_ in ipairs(self.actionBindings) do
		local v36_ = v35_.action.displayCategory
		local v37_ = v36_ == nil and "$l10n_inputCategory_OTHER" or v36_
		local v38_
		if v31_[v37_] == nil then
			v38_ = {
				["name"] = v37_
			}
			table.insert(v32_, v38_)
			v31_[v37_] = #v32_
		else
			v38_ = v32_[v31_[v37_]]
		end
		table.insert(v38_, self:createDisplayAction(deviceCategory, v35_, true, v30_))
		if v35_.action:isFullAxis() then
			table.insert(v38_, self:createDisplayAction(deviceCategory, v35_, false, v30_))
		end
	end
	return v32_
end

-- Local values: text, postFix
function ControlsController:getMouseAxisDisplayText(axis)
	local v40_ = ""
	if InputBinding.MOUSE_AXES[axis] == Input.AXIS_X then
		v40_ = ControlsController.AXIS_NAME_X
	elseif InputBinding.MOUSE_AXES[axis] == Input.AXIS_Y then
		v40_ = ControlsController.AXIS_NAME_Y
	end
	if v40_ ~= "" then
		local v41_ = ControlsController.AXIS_AFFIX_POSITIVE
		if axis:sub(axis:len()) == "-" then
			v41_ = ControlsController.AXIS_AFFIX_NEGATIVE
		end
		v40_ = v40_ .. v41_
	end
	return v40_
end

function ControlsController:getGamepadButtonDisplayText(buttonName, internalDeviceId)
	if internalDeviceId == nil or internalDeviceId < 0 then
		return string.format("%d", Input[buttonName] + 1)
	else
		return getGamepadButtonLabel(Input[buttonName], internalDeviceId)
	end
end

-- Local values: axisLabel, directionAffix
function ControlsController:getGamepadAxisDisplayText(axisName, internalDeviceId)
	local v46_
	if internalDeviceId == nil or internalDeviceId < 0 then
		v46_ = string.format("Axis %d", Input[axisName] + 1)
	else
		v46_ = getGamepadAxisLabel(Input[axisName], internalDeviceId)
	end
	local v47_ = ControlsController.AXIS_AFFIX_POSITIVE
	if axisName:sub(axisName:len()) == "-" then
		v47_ = ControlsController.AXIS_AFFIX_NEGATIVE
	end
	return v46_ .. v47_
end

-- Local values: texts, deviceLabel, isKeyboard, _, axis, _, axis, device, gamepadName
function ControlsController:getBindingInputDisplayText(binding)
	if #binding.axisNames < 1 then
		return ""
	end
	local v50_ = {}
	local v51_ = ""
	if binding.deviceId == InputDevice.DEFAULT_DEVICE_NAMES.KB_MOUSE_DEFAULT then
		for _, v52_ in pairs(binding.axisNames) do
			if InputBinding.MOUSE_BUTTONS[v52_] then
				local v53_ = getMouseButtonName
				local v54_ = Input[v52_]
				table.insert(v50_, v53_(v54_))
			elseif InputBinding.MOUSE_AXES[v52_] then
				table.insert(v50_, self:getMouseAxisDisplayText(v52_))
			else
				local v55_ = KeyboardHelper.getDisplayKeyName
				local v56_ = Input[v52_]
				table.insert(v50_, v55_(v56_))
			end
		end
	else
		for _, v57_ in pairs(binding.axisNames) do
			if Input.buttonIdNameToId[v57_] then
				local v58_ = binding.internalDeviceId
				table.insert(v50_, self:getGamepadButtonDisplayText(v57_, v58_))
			elseif Input.axisIdNameToId[v57_] then
				local v59_ = binding.internalDeviceId
				table.insert(v50_, self:getGamepadAxisDisplayText(v57_, v59_))
			end
		end
		if self.numGamepads > 1 or g_inputBinding:getHasMissingDevices() then
			local v60_ = g_inputBinding:getDeviceByInternalId(binding.internalDeviceId)
			if v60_ == nil then
				v60_ = g_inputBinding:getMissingDeviceById(binding.deviceId)
			end
			if v60_ ~= nil then
				local v61_ = v60_.deviceName
				if g_i18n:hasText(v61_) then
					v61_ = g_i18n:getText(v61_)
				end
				v51_ = string.format(" [%s]", v61_)
			end
		end
	end
	return table.concat(v50_, " + ") .. v51_
end

function ControlsController:saveChanges()
	g_inputBinding:commitBindingChanges()
	g_inputBinding:saveToXMLFile()
end

function ControlsController:discardChanges()
	g_inputBinding:rollbackBindingChanges()
end

function ControlsController:loadBindings()
	self.actionBindings = g_inputBinding:getActionBindingsCopy(true)
end

-- Local values: startedListening
function ControlsController:onClickInput(deviceCategory, bindingIndex, displayActionBinding, bindingControlsRowIndex)
	local v68_ = false
	if not self.waitForInput then
		if ControlsController.LOCKED_BINDINGS[bindingIndex][displayActionBinding.action.name] then
			if deviceCategory == InputDevice.CATEGORY.KEYBOARD_MOUSE then
				if bindingIndex == ControlsController.BINDING_TERTIARY then
					self.messageCallback(ControlsController.MESSAGE_CANNOT_MAP_MOUSE)
					return v68_
				else
					self.messageCallback(ControlsController.MESSAGE_CANNOT_MAP_KEY)
					return v68_
				end
			else
				self.messageCallback(ControlsController.MESSAGE_CANNOT_MAP_CONTROLLER)
				return v68_
			end
		end
		self:beginWaitForInput(deviceCategory, bindingIndex, displayActionBinding, bindingControlsRowIndex)
		v68_ = true
	end
	return v68_
end

-- Local values: gatheringState
function ControlsController:beginWaitForInput(deviceCategory, bindingIndex, displayActionBinding, bindingControlsRowIndex)
	g_inputBinding:startBindingChanges()
	self.waitForInput = true
	local v74_ = {
		["binding"] = displayActionBinding,
		["bindingIndex"] = bindingIndex,
		["bindingControlsRowIndex"] = bindingControlsRowIndex
	}
	if deviceCategory == InputDevice.CATEGORY.KEYBOARD_MOUSE then
		if bindingControlsRowIndex == ControlsController.BINDING_TERTIARY then
			v74_.mouseState = {}
			g_inputBinding:startInputCapture(false, true, self, v74_, self.onCaptureMouseInput, self.onAbortInputGathering, self.onDeleteInputBinding)
		else
			v74_.keyState = {}
			g_inputBinding:startInputCapture(true, false, self, v74_, self.onCaptureKeyboardInput, self.onAbortInputGathering, self.onDeleteInputBinding)
		end
	else
		v74_.gamepadState = {}
		g_inputBinding:startInputCapture(false, false, self, v74_, self.onCaptureGamepadInput, self.onAbortInputGathering, self.onDeleteInputBinding)
		return
	end
end

function ControlsController:onAbortInputGathering()
	self:endWaitForInput(false)
end

-- Local values: hasDeleted
function ControlsController:onDeleteInputBinding(gatheringState)
	self:endWaitForInput((self:deleteBinding(gatheringState.binding, gatheringState.bindingControlsRowIndex or gatheringState.bindingIndex)))
end

-- Local values: keyState, displayActionBinding, couldAssign
function ControlsController:onCaptureKeyboardInput(_, keyName, inputValue, initInputValue, gatheringState)
	local v82_ = gatheringState.keyState
	if inputValue > 0 then
		table.insert(v82_, keyName)
	else
		self:endWaitForInput((self:assignKeyboardBinding(gatheringState.binding, gatheringState.bindingIndex, v82_)))
	end
end

-- Local values: mouseState, lastInput, xAxisName, yAxisName, xValue, yValue, hasButtonInput, buttonName, inputDirection, displayActionBinding, isAxisAction, axisNames, buttonName, inputValid, couldAssign, absX, absY, couldAssign
function ControlsController:onCaptureMouseInput(_, inputAxisName, inputValue, initInputValue, gatheringState)
	if not self.waitForInput then
		return
	end
	local v87_ = gatheringState.mouseState
	local v88_ = v87_[inputAxisName]
	v87_[inputAxisName] = inputValue
	local v89_ = InputBinding.MOUSE_AXIS_NAMES[Input.AXIS_X]
	local v90_ = InputBinding.MOUSE_AXIS_NAMES[Input.AXIS_Y]
	local v91_ = v87_[v89_] or 0
	local v92_ = v87_[v90_] or 0
	local v93_ = false
	for v94_ in pairs(InputBinding.MOUSE_BUTTONS) do
		if v87_[v94_] ~= nil then
			v93_ = true
			break
		end
	end
	local v95_ = 1
	local v96_ = gatheringState.binding
	local v97_ = v96_.action:isFullAxis()
	local v98_ = {}
	if InputBinding.MOUSE_BUTTONS[inputAxisName] == nil or (v88_ ~= 1 or inputValue ~= 0) then
		if v97_ and not v93_ then
			local v99_ = math.abs(v91_)
			local v100_ = math.abs(v92_)
			if self.mouseMoveThresholdX < v99_ and v100_ < v99_ then
				table.insert(v98_, v89_)
				v92_ = v91_
			elseif self.mouseMoveThresholdY < v100_ and v99_ < v100_ then
				table.insert(v98_, v90_)
			else
				v92_ = v95_
			end
			if #v98_ > 0 then
				self:endWaitForInput((self:assignMouseBinding(v96_, v98_, v92_)))
			end
		end
	else
		table.insert(v98_, inputAxisName)
		for v101_ in pairs(InputBinding.MOUSE_BUTTONS) do
			if v87_[v101_] == 1 then
				table.insert(v98_, v101_)
				break
			end
			v87_[v101_] = nil
		end
		local v102_
		if v97_ then
			v102_ = v91_ ~= 0 and true or v92_ ~= 0
			if v102_ then
				if math.abs(v92_) > math.abs(v91_) then
					table.insert(v98_, v90_)
				else
					table.insert(v98_, v89_)
					v92_ = v91_
				end
			else
				v92_ = v95_
			end
		else
			v92_ = v95_
			v102_ = true
		end
		if v102_ then
			self:endWaitForInput((self:assignMouseBinding(v96_, v98_, v92_)))
			return
		end
	end
end

-- Local values: deviceState, lastInput, axisNames, axisName, axisInput, axisInputValue, axisIntInputValue, axisNeutralInput, neutralInput, inputDirection, couldAssign
function ControlsController:onCaptureGamepadInput(deviceId, inputAxisName, inputValue, initInputValue, gatheringState)
	if not self.waitForInput then
		return
	end
	local v109_ = gatheringState.gamepadState[deviceId]
	if not v109_ then
		v109_ = {}
		gatheringState.gamepadState[deviceId] = v109_
	end
	local v110_ = v109_[inputAxisName]
	v109_[inputAxisName] = { inputValue, initInputValue }
	if v110_ then
		local v111_ = v110_[1] - initInputValue
		if math.abs(v111_) > 0.3 then
			local v112_ = inputValue - initInputValue
			if math.abs(v112_) <= 0.3 then
				local v113_ = {}
				for v114_, v115_ in pairs(v109_) do
					local v116_ = v115_[1]
					local v117_ = v115_[2]
					local v118_ = v117_ > 0.5 and 1 or (v117_ < -0.5 and -1 or 0)
					if v114_ ~= inputAxisName and math.abs(v116_) > 0.5 then
						if v118_ == 0 then
							::l18::
							if v116_ < 0 then
								local v119_ = v114_ .. "-"
								table.insert(v113_, v119_)
							else
								table.insert(v113_, v114_)
							end
						else
							local v120_ = v116_ - v118_
							if math.abs(v120_) > 0.6 or Input.isHalfAxis(Input[v114_]) then
								goto l18
							end
						end
					end
				end
				table.sort(v113_)
				table.insert(v113_, inputAxisName)
				local v121_ = 0
				if not Input.isHalfAxis(Input[inputAxisName]) then
					v121_ = initInputValue > 0.5 and 1 or (initInputValue < -0.5 and -1 or v121_)
				end
				local v122_ = v110_[1] - initInputValue
				self:endWaitForInput((self:assignGamepadBinding(gatheringState.binding, gatheringState.bindingIndex, gatheringState.bindingControlsRowIndex, deviceId, v113_, v122_, v121_)))
				goto l6
			end
		end
	end
	::l6::
end

function ControlsController:endWaitForInput(madeChange)
	self.waitForInput = false
	g_inputBinding:stopInputGathering()
	self.inputDoneCallback(madeChange)
	self:lockInput()
end

-- Local values: _, actionName
function ControlsController:lockInput()
	for _, v125_ in pairs(Gui.NAV_ACTIONS) do
		FocusManager:lockFocusInput(v125_, ControlsController.INPUT_DELAY)
	end
end

-- Local values: currentBinding, _, actionBinding, _, binding, lastAxisName
function ControlsController:deleteBinding(displayActionBinding, currentBindingIndex)
	local v129_ = displayActionBinding.columnBindings[currentBindingIndex]
	for _, v130_ in pairs(self.actionBindings) do
		if v130_.action == displayActionBinding.action then
			for _, v131_ in ipairs(v130_.bindings) do
				if v129_ == v131_ then
					g_inputBinding:deleteBinding(v131_.deviceId, displayActionBinding.action.name, v131_.index, v131_.axisComponent)
					local v132_ = v129_.axisNames[#v129_.axisNames]
					if InputBinding.getIsPhysicalFullAxis(v132_) then
						g_inputBinding:deleteBinding(v131_.deviceId, v130_.action.name, v131_.index, Binding.getOppositeAxisComponent(v131_.axisComponent))
					end
					self.messageCallback(ControlsController.MESSAGE_CLEAR)
					return true
				end
			end
		end
	end
	return false
end

-- Local values: blockedCombos, numKeys, _, combo, areEqual, _, keyName, found, _, comboKey
function ControlsController:areKeyCombinationsBlocked(keyNames)
	local v134_ = Platform.blockedKeyboardCombos
	local v135_ = #keyNames
	for _, v136_ in ipairs(v134_) do
		if #v136_ == v135_ then
			local v137_ = true
			for _, v138_ in ipairs(keyNames) do
				local v139_ = false
				for _, v140_ in ipairs(v136_) do
					if v138_ == v140_ then
						v139_ = true
						break
					end
				end
				if not v139_ then
					v137_ = false
				end
			end
			if v137_ then
				return true
			end
		end
	end
	return false
end

-- Local values: success, collision, blockAdd, binding, action, isPositiveAxisBinding, displayName
function ControlsController:assignKeyboardBinding(displayActionBinding, bindingIndex, keyNames)
	if self:areKeyCombinationsBlocked(keyNames) then
		self.messageCallback(ControlsController.MESSAGE_CONFLICT_BLOCKED_KEY, {})
		return false
	end
	local v145_, v146_, v147_ = self:assignBinding(InputDevice.DEFAULT_DEVICE_NAMES.KB_MOUSE_DEFAULT, displayActionBinding.action, bindingIndex, keyNames, displayActionBinding.isPositive, 1, 0)
	if not v145_ then
		if v147_ then
			InfoDialog.show(g_i18n:getText("ui_duplicateKeyCombination"), nil, nil, DialogElement.TYPE_WARNING)
		end
		return v145_
	end
	if v146_ and not v146_.collisionAction.isLocked then
		local v148_ = v146_.collisionBinding
		local v149_ = v146_.collisionAction
		local v150_ = v148_.axisComponent == Binding.AXIS_COMPONENT.POSITIVE and v149_.displayNamePositive or v149_.displayNameNegative
		self.messageCallback(ControlsController.MESSAGE_CONFLICT_KEY, { " (" .. v150_ .. ")" })
	end
	self.messageCallback(ControlsController.MESSAGE_REMAPPED, { displayActionBinding.displayName, string.upper(KeyboardHelper.getInputDisplayText(keyNames)) }, v146_ ~= nil)
	return v145_
end
local function v_u_155_(p151_, p152_)
	local v153_ = InputBinding.MOUSE_BUTTONS[p151_]
	local v154_ = InputBinding.MOUSE_BUTTONS[p152_]
	if v153_ == nil then
		return false
	else
		return v154_ == nil and true or v153_ < v154_
	end
end

-- Local values: modifierAxisList, i, _, buttonNames
function ControlsController:validateMouseCombo(inputAxisNames)
	if #inputAxisNames == 1 then
		return true
	end
	local v157_ = {}
	for v158_ = 1, #inputAxisNames - 1 do
		local v159_ = inputAxisNames[v158_]
		table.insert(v157_, v159_)
	end
	for _, v160_ in pairs(InputBinding.MOUSE_COMBO_BINDINGS) do
		if table.equalLists(v157_, v160_) then
			return true
		end
	end
	return false
end

-- Upvalues: sortMouseAxisNames
-- Local values: bindingIndex, device, success, collision, lastAxisName, binding, action, isPositiveAxisBinding, displayName
function ControlsController:assignMouseBinding(displayActionBinding, inputAxisNames, inputDirection)
	-- upvalues: (copy) v_u_155_
	local v165_ = ControlsController.BINDING_TERTIARY
	local v166_ = InputDevice.DEFAULT_DEVICE_NAMES.KB_MOUSE_DEFAULT
	table.sort(inputAxisNames, v_u_155_)
	if not self:validateMouseCombo(inputAxisNames) then
		return false
	end
	local v167_, v168_ = self:assignBinding(v166_, displayActionBinding.action, v165_, inputAxisNames, displayActionBinding.isPositive, inputDirection, 0)
	if v167_ then
		local v169_ = inputAxisNames[#inputAxisNames]
		if displayActionBinding.action:isFullAxis() and InputBinding.getIsPhysicalFullAxis(v169_) then
			self:assignBinding(v166_, displayActionBinding.action, v165_, inputAxisNames, not displayActionBinding.isPositive, -inputDirection, 0)
		end
		if v168_ and not v168_.collisionAction.isLocked then
			local v170_ = v168_.collisionBinding
			local v171_ = v168_.collisionAction
			local v172_ = v170_.axisComponent == Binding.AXIS_COMPONENT.POSITIVE and v171_.displayNamePositive or v171_.displayNameNegative
			self.messageCallback(ControlsController.MESSAGE_CONFLICT_MOUSE, { " (" .. v172_ .. ")" })
		end
		self.messageCallback(ControlsController.MESSAGE_REMAPPED, { displayActionBinding.displayName, string.upper(MouseHelper.getInputDisplayText(inputAxisNames)) }, v168_ ~= nil)
	end
	return v167_
end

-- Local values: previousBinding, previousDeviceId, success, collision, lastAxisName, binding, action, messageId, isPositiveAxisBinding, displayName
function ControlsController:assignGamepadBinding(displayActionBinding, bindingIndex, bindingControlsRowIndex, deviceId, inputAxisNames, inputDirection, neutralInput)
	if self:areKeyCombinationsBlocked(inputAxisNames) then
		self.messageCallback(ControlsController.MESSAGE_CONFLICT_BLOCKED_KEY, {})
		return false
	end
	local v181_ = displayActionBinding.columnBindings[bindingControlsRowIndex]
	local v182_
	if v181_ then
		v182_ = v181_.deviceId
	else
		v182_ = deviceId
	end
	local v183_, v184_ = self:assignBinding(deviceId, displayActionBinding.action, bindingIndex, inputAxisNames, displayActionBinding.isPositive, inputDirection, neutralInput, v182_)
	if v183_ then
		local v185_ = inputAxisNames[#inputAxisNames]
		if displayActionBinding.action:isFullAxis() and (InputBinding.getIsPhysicalFullAxis(v185_) and neutralInput == 0) then
			self:assignBinding(deviceId, displayActionBinding.action, bindingIndex, inputAxisNames, not displayActionBinding.isPositive, -inputDirection, neutralInput)
		end
		if v184_ and not v184_.collisionAction.isLocked then
			local v186_ = v184_.collisionBinding
			local v187_ = v184_.collisionAction
			local v188_ = ControlsController.MESSAGE_CONFLICT_BUTTON
			if displayActionBinding.action:isFullAxis() then
				v188_ = ControlsController.MESSAGE_CONFLICT_AXIS
			end
			local v189_ = v186_.axisComponent == Binding.AXIS_COMPONENT.POSITIVE and v187_.displayNamePositive or v187_.displayNameNegative
			self.messageCallback(v188_, { " (" .. v189_ .. ")" })
		end
		self.messageCallback(ControlsController.MESSAGE_REMAPPED, { displayActionBinding.displayName, string.upper(GamepadHelper.getInputDisplayText(inputAxisNames, g_inputBinding:getInternalIdByDeviceId(deviceId))) }, v184_ ~= nil)
	end
	return v183_
end

-- Local values: axisComponent, inputComponent, couldUpdate, collisionAction, blockAdd, couldAdd, binding, action
function ControlsController:assignBinding(deviceId, displayAction, bindingIndex, inputAxisNames, isPositiveAxis, inputDirection, neutralInput, previousDeviceId)
	local v198_ = isPositiveAxis and Binding.AXIS_COMPONENT.POSITIVE or Binding.AXIS_COMPONENT.NEGATIVE
	local v199_ = inputDirection >= 0 and Binding.INPUT_COMPONENT.POSITIVE or Binding.INPUT_COMPONENT.NEGATIVE
	local v200_, v201_, v202_ = g_inputBinding:updateBinding(previousDeviceId or deviceId, displayAction.name, bindingIndex, v198_, deviceId, inputAxisNames, v199_, neutralInput)
	local v203_
	if v200_ or v202_ then
		v203_ = true
	else
		local v204_ = Binding.new(deviceId, inputAxisNames, v198_, v199_, neutralInput, bindingIndex)
		local v205_ = g_inputBinding:getActionByName(displayAction.name)
		v203_, v201_ = g_inputBinding:addBinding(v205_, v204_)
	end
	local v206_ = not v202_
	if v206_ then
		v206_ = v200_ or v203_
	end
	return v206_, v201_, v202_
end

function ControlsController:loadDefaultSettings()
	g_inputBinding:restoreDefaultBindings()
	self:loadBindings()
end
