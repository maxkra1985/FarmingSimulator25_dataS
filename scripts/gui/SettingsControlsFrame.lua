-- Local values: SettingsControlsFrame_mt, NO_CALLBACK
SettingsControlsFrame = {}
local SettingsControlsFrame_mt = Class(SettingsControlsFrame, TabbedMenuFrameElement)
local function NO_CALLBACK() end
function SettingsControlsFrame.register()
	local v3_ = SettingsControlsFrame.new()
	g_gui:loadGui("dataS/gui/SettingsControlsFrame.xml", "SettingsControlsFrame", v3_, true)
end

-- Upvalues: SettingsControlsFrame_mt
-- Local values: self
function SettingsControlsFrame.new(target, custom_mt)
	-- upvalues: (copy) SettingsControlsFrame_mt
	local v6_ = TabbedMenuFrameElement.new(target, custom_mt or SettingsControlsFrame_mt)
	v6_.controlsController = nil
	v6_.controlsData = {}
	v6_.controlsMessageText = ""
	v6_.userChangedInput = false
	v6_.currentFocusCell = nil
	v6_.dataRowOffset = 0
	v6_.hasCustomMenuButtons = true
	v6_.backButtonInfo = {}
	v6_.saveButtonInfo = {}
	v6_.resetButtonInfo = {}
	return v6_
end

-- Local values: newGui
function SettingsControlsFrame.createFromExistingGui(gui, guiName)
	local v9_ = SettingsControlsFrame.new()
	g_gui.frames[gui.name].target:delete()
	g_gui.frames[gui.name]:delete()
	g_gui:loadGui(gui.xmlFilename, guiName, v9_, true)
	return v9_
end

-- Local values: messageCallback, inputDoneCallback, buttonSaveChangesFunction, buttonDefaultsFunction
function SettingsControlsFrame:initialize(controlsController)
	self.controlsController = controlsController
	self.controlsController:setMessageCallback(function(p12_, p13_, p14_)
		-- upvalues: (copy) self
		self:setControlsMessage(p12_, p13_, p14_)
	end)
	self.controlsController:setInputDoneCallback(function(p15_)
		-- upvalues: (copy) self
		self:notifyInputGatheringFinished(p15_)
	end)
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
		["text"] = g_i18n:getText(SettingsControlsFrame.L10N_SYMBOL.BUTTON_SAVE),
		["callback"] = function()
			-- upvalues: (copy) self
			self:saveChanges()
		end,
		["showWhenPaused"] = true
	}
	self.resetButtonInfo = {
		["inputAction"] = InputAction.MENU_CANCEL,
		["text"] = g_i18n:getText(SettingsControlsFrame.L10N_SYMBOL.BUTTON_DEFAULTS),
		["callback"] = function()
			-- upvalues: (copy) self
			self:onClickDefaults()
		end,
		["showWhenPaused"] = true
	}
	function self.controlsList.queueReusableCell(p16_, p17_, _)
		local v18_ = p17_:getAttribute("actionButton1") ~= nil and p17_:getAttribute("actionButton1"):getIsFocused() or p17_:getAttribute("actionButton2") ~= nil and p17_:getAttribute("actionButton2"):getIsFocused()
		if not v18_ then
			if p17_:getAttribute("actionButton3") == nil then
				v18_ = false
			else
				v18_ = p17_:getAttribute("actionButton3"):getIsFocused()
			end
		end
		if not v18_ and p16_.sections[p17_.sectionIndex] ~= nil then
			p16_.sections[p17_.sectionIndex].cells[p17_.indexInSection] = nil
		end
		if not v18_ then
			p17_.sectionIndex = nil
			p17_.indexInSection = nil
			local v19_ = p16_.cellCache[p17_.reusableName]
			v19_[#v19_ + 1] = p17_
			FocusManager:removeElement(p17_)
			p17_:unlinkElement()
		end
	end
end

-- Local values: _
function SettingsControlsFrame:onFrameOpen()
	SettingsControlsFrame:superClass().onFrameOpen(self)
	self.numTotalDevices = 3 + g_inputBinding.numActiveGamepads
	self.dataRowOffset = 0
	self:assignDeviceTableData()
	self.controlsList:makeCellVisible(1, 1)
	self.nextFocusSection = 1
	self.nextFocusCell = 1
	self.nextFocusedButtonName = "actionButton1"
	self.controlsMessageText = ""
	self:updateMenuButtons()
	g_messageCenter:subscribe(MessageType.INPUT_DEVICES_CHANGED, self.onControllerChanged, self)
	local _, v21_ = g_inputBinding:registerActionEvent(InputAction.MENU_ACCEPT, self, self.onMenuAcceptUp, true, false, false, true)
	self.menuAcceptUpEventId = v21_
	g_inputBinding:resetBindingInputStates()
end

-- Local values: canClose
function SettingsControlsFrame:requestClose(callback)
	local v24_ = not self.userChangedInput
	if self.userChangedInput then
		SettingsControlsFrame:superClass().requestClose(self, callback)
		YesNoDialog.show(self.onYesNoSaveControls, self, g_i18n:getText(SettingsControlsFrame.L10N_SYMBOL.SAVE_CHANGES_PROMPT))
	end
	return v24_
end

function SettingsControlsFrame:onFrameClose()
	g_messageCenter:unsubscribe(MessageType.INPUT_DEVICES_CHANGED, self)
	g_inputBinding:removeActionEvent(self.menuAcceptUpEventId)
	SettingsControlsFrame:superClass().onFrameClose(self)
end

-- Local values: newCell, newButton
function SettingsControlsFrame:update(dt)
	SettingsControlsFrame:superClass().update(self, dt)
	if self.nextFocusSection ~= nil then
		local v28_ = self.controlsList:getElementAtSectionIndex(self.nextFocusSection, self.nextFocusCell)
		if v28_ ~= nil then
			local v29_ = v28_:getAttribute(self.nextFocusedButtonName)
			FocusManager:setFocus(v29_)
			self.nextFocusSection = nil
			self.nextFocusCell = nil
		end
	end
end

-- Upvalues: NO_CALLBACK
function SettingsControlsFrame:onYesNoSaveControls(yes)
	-- upvalues: (copy) NO_CALLBACK
	if yes then
		self:saveChanges()
	else
		self:revertChanges()
		self.requestCloseCallback()
		self.requestCloseCallback = NO_CALLBACK
	end
end

function SettingsControlsFrame:revertChanges()
	self.controlsController:discardChanges()
	self.userChangedInput = false
	self:updateMenuButtons()
end

-- Upvalues: NO_CALLBACK
function SettingsControlsFrame:saveChanges()
	-- upvalues: (copy) NO_CALLBACK
	if self.userChangedInput then
		self.controlsController:saveChanges()
		self.userChangedInput = false
		self:updateMenuButtons()
		InfoDialog.show(g_i18n:getText(SettingsControlsFrame.L10N_SYMBOL.SAVED_CHANGES_INFO), self.requestCloseCallback)
		self.requestCloseCallback = NO_CALLBACK
	end
end

function SettingsControlsFrame:updateMenuButtons()
	if self.userChangedInput then
		self.menuButtonInfo = {
			self.backButtonInfo,
			self.nextPageButtonInfo,
			self.prevPageButtonInfo,
			self.saveButtonInfo,
			self.resetButtonInfo
		}
	else
		self.menuButtonInfo = {
			self.backButtonInfo,
			self.nextPageButtonInfo,
			self.prevPageButtonInfo,
			self.resetButtonInfo
		}
	end
	self.menuButtonInfo = self.menuButtonInfo
	self:setMenuButtonInfoDirty()
end

function SettingsControlsFrame:assignDeviceTableData()
	self.controlsController:loadBindings()
	self.controlsData = self.controlsController:getDeviceCategoryActionBindings()
	self.controlsList:reloadData()
	self:updateListHeaderNames()
end

-- Local values: gamepads, index, headerName
function SettingsControlsFrame:updateListHeaderNames()
	local v37_ = g_inputBinding:getGamepadDevices()
	local v38_ = 1 + self.dataRowOffset
	local v39_
	if v38_ <= 3 then
		v39_ = g_i18n:getText(SettingsControlsFrame.DEVICES[v38_].name)
	else
		v39_ = v37_[v38_ - 3].name
		if g_i18n:hasText(v39_) then
			v39_ = g_i18n:getText(v39_)
		elseif InputDevice.NAMES[v39_] ~= nil then
			v39_ = InputDevice.NAMES[v39_]
		end
	end
	self.headerText1:setText(v39_)
	local v40_ = v38_ + 1
	local v41_
	if v40_ <= 3 then
		v41_ = g_i18n:getText(SettingsControlsFrame.DEVICES[v40_].name)
	else
		v41_ = v37_[v40_ - 3].name
		if g_i18n:hasText(v41_) then
			v41_ = g_i18n:getText(v41_)
		elseif InputDevice.NAMES[v41_] ~= nil then
			v41_ = InputDevice.NAMES[v41_]
		end
	end
	self.headerText2:setText(v41_)
	local v42_ = v40_ + 1
	local v43_
	if v42_ <= 3 then
		v43_ = g_i18n:getText(SettingsControlsFrame.DEVICES[v42_].name)
	else
		v43_ = v37_[v42_ - 3].name
		if g_i18n:hasText(v43_) then
			v43_ = g_i18n:getText(v43_)
		elseif InputDevice.NAMES[v43_] ~= nil then
			v43_ = InputDevice.NAMES[v43_]
		end
	end
	self.headerText3:setText(v43_)
	self.buttonPrevRow:setVisible(self.dataRowOffset > 0)
	self.buttonNextRow:setVisible(self.dataRowOffset < self.numTotalDevices - 3)
	self.gamepads = v37_
end

-- Local values: text, uiSymbol, isWarning, dialogType, formatString
function SettingsControlsFrame:setControlsMessage(messageId, additionalText, addLine)
	if messageId and messageId ~= ControlsController.MESSAGE_CLEAR then
		local v48_ = not addLine and "" or self.controlsMessageText .. "\n"
		local v49_ = SettingsControlsFrame.CONTROLS_UI_STRINGS[messageId]
		local v50_ = SettingsControlsFrame.CONFLICT_MESSAGES[messageId] == true and DialogElement.TYPE_WARNING or DialogElement.TYPE_INFO
		local v51_
		if v49_ then
			v51_ = v48_ .. g_i18n:getText(v49_)
			if additionalText and #additionalText > 0 then
				v51_ = v51_ .. additionalText[1]
			end
		else
			local v52_ = SettingsControlsFrame.L10N_TEMPLATE_SYMBOL[messageId]
			local v53_ = g_i18n:getText(v52_)
			if additionalText and #additionalText > 0 then
				v51_ = v48_ .. string.format(v53_, unpack(additionalText))
			else
				v51_ = v48_ .. v53_
			end
		end
		self.controlsMessageText = v51_
		InfoDialog.show(v51_, nil, nil, v50_)
	else
		self.controlsMessageText = ""
	end
end

function SettingsControlsFrame:notifyInputGatheringFinished(madeChange)
	self:setSoundSuppressed(true)
	g_gui:closeAllDialogs()
	FocusManager:setGui(self.name)
	self:setSoundSuppressed(false)
	if madeChange then
		self:assignDeviceTableData()
		self.userChangedInput = true
		self:updateMenuButtons()
	end
	self:playSample(GuiSoundPlayer.SOUND_SAMPLES.CLICK)
end

-- Local values: promptStringSymbol, promptTemplate, text, ensureInNeutral
function SettingsControlsFrame:showInputPrompt(deviceCategory, bindingId, actionData)
	local v59_
	if deviceCategory == InputDevice.CATEGORY.KEYBOARD_MOUSE then
		if bindingId == ControlsController.BINDING_PRIMARY or bindingId == ControlsController.BINDING_SECONDARY then
			v59_ = SettingsControlsFrame.L10N_SYMBOL.KEY_PROMPT
		else
			v59_ = SettingsControlsFrame.L10N_SYMBOL.MOUSE_PROMPT
		end
	else
		v59_ = SettingsControlsFrame.L10N_SYMBOL.BUTTON_PROMPT
	end
	local v60_ = g_i18n:getText(v59_)
	local v61_ = string.format(v60_, actionData.displayName) .. "\n" .. g_i18n:getText(SettingsControlsFrame.CONTROLS_UI_STRINGS[ControlsController.MESSAGE_PROMPT_CANCEL_DELETE])
	local v62_ = g_i18n:getText(SettingsControlsFrame.CONTROLS_UI_STRINGS[ControlsController.MESSAGE_ENSURE_IN_NEUTRAL])
	if utf8Strlen(v62_) > 1 then
		v61_ = v61_ .. "\n\n" .. v62_
	end
	MessageDialog.show(v61_, nil, nil, DialogElement.TYPE_KEY)
end
SettingsControlsFrame.KB_MOUSE_BOUND_CONTROLS = {
	["ACTION"] = "action",
	["KEY_1"] = "key1",
	["KEY_2"] = "key2",
	["MOUSE_BUTTON"] = "mouseButton"
}
SettingsControlsFrame.GAMEPAD_BOUND_CONTROLS = {
	["ACTION"] = "gamepadAction",
	["BUTTON_1"] = "gamepadButton1",
	["BUTTON_2"] = "gamepadButton2"
}

function SettingsControlsFrame:getNumberOfSections(list)
	return #self.controlsData
end

-- Local values: key
function SettingsControlsFrame:getTitleForSectionHeader(list, section)
	local v66_ = self.controlsData[section].name
	return g_i18n:convertText(v66_)
end

function SettingsControlsFrame:getNumberOfItemsInSection(list, section)
	return #self.controlsData[section]
end

-- Local values: actionBinding, i, dataIndex, bindingColumnIndex, binding, deviceId, id, columnBinding, glyph, button, hasIcon, _, keyName, oldFocusEnterFunc, oldFocusLeaveFunc, oldFocusEnterFuncButton
function SettingsControlsFrame:populateCellForItemInSection(list, section, index, cell)
	local v74_ = self.controlsData[section][index]
	cell:getAttribute("actionName"):setText(v74_.displayName)
	for v_u_75_ = 1, 3 do
		local v76_ = v_u_75_ + self.dataRowOffset
		local v77_ = nil
		local v_u_78_
		if v76_ - 3 > 0 then
			local v79_ = self.gamepads[v76_ - 3].deviceId
			v_u_78_ = v76_
			for v80_, v81_ in pairs(v74_.columnBindings) do
				if v81_.deviceId == v79_ then
					v77_ = v81_
					v76_ = v80_
					break
				end
			end
		else
			v77_ = v74_.columnBindings[v76_]
			v_u_78_ = v76_
		end
		local v_u_82_ = cell:getAttribute("actionGlyph" .. v_u_75_)
		local v_u_83_ = cell:getAttribute("actionButton" .. v_u_75_)
		v_u_82_:setActions({ v74_.action.name }, nil, nil, nil, v77_)
		local v84_ = false
		if v_u_82_.glyphElement ~= nil then
			for _, v85_ in pairs(v_u_82_.glyphElement.actionNames) do
				if v_u_82_.glyphElement.keyNames[v85_] ~= nil and v_u_82_.glyphElement.keyNames[v85_][1] ~= "" then
					v84_ = true
				end
			end
		end
		local v86_
		if v77_ == nil then
			v86_ = false
		else
			v86_ = v84_
		end
		v_u_82_:setVisible(v86_)
		if v84_ then
			v_u_83_:setText("")
		else
			v_u_83_:setText(v74_.columnTexts[v76_])
		end
		local v_u_87_ = v_u_82_.onFocusEnter
		function v_u_82_.onFocusEnter()
			-- upvalues: (copy) v_u_87_, (copy) v_u_82_
			v_u_87_(v_u_82_)
			v_u_82_.glyphElement:setButtonGlyphColor(SettingsControlsFrame.COLOR.BLACK)
		end
		local v_u_88_ = v_u_82_.onFocusLeave
		function v_u_82_.onFocusLeave(_)
			-- upvalues: (copy) v_u_88_, (copy) v_u_82_
			v_u_88_(v_u_82_)
			if v_u_82_.glyphElement ~= nil then
				v_u_82_.glyphElement:setButtonGlyphColor(SettingsControlsFrame.COLOR.GREEN)
			end
		end
		local v_u_89_ = v_u_83_.onFocusEnter
		function v_u_83_.onFocusEnter()
			-- upvalues: (copy) v_u_89_, (copy) v_u_83_, (copy) list, (copy) cell, (copy) self, (copy) v_u_75_
			v_u_89_(v_u_83_)
			list:makeCellVisible(cell.sectionIndex, cell.indexInSection)
			self.currentFocusCell = cell
			local v90_ = self
			local v91_ = self
			local v92_ = cell.sectionIndex
			local v93_ = cell.indexInSection
			v90_.currentFocusSection = v92_
			v91_.currentFocusIndex = v93_
			self["headerText" .. 1]:setSelected(v_u_75_ == 1)
			self["headerText" .. 2]:setSelected(v_u_75_ == 2)
			self["headerText" .. 3]:setSelected(v_u_75_ == 3)
		end
		function v_u_83_.shouldFocusChange(_, p94_)
			-- upvalues: (copy) cell, (copy) self, (copy) v_u_78_, (copy) list, (copy) v_u_75_
			if g_gui:getIsDialogVisible() then
				return false
			end
			local v95_ = cell.sectionIndex
			local v96_ = cell.indexInSection
			if v95_ == nil then
				v95_ = self.currentFocusSection
				v96_ = self.currentFocusIndex
			end
			if p94_ == FocusManager.LEFT then
				if v_u_78_ == 1 then
					return false
				end
				if v_u_78_ == 1 + self.dataRowOffset then
					self.dataRowOffset = self.dataRowOffset - 1
					self.controlsList:reloadData()
					self:updateListHeaderNames()
					return false
				end
			elseif p94_ == FocusManager.RIGHT then
				if v_u_78_ == self.numTotalDevices then
					return false
				end
				if v_u_78_ == 3 + self.dataRowOffset then
					self.dataRowOffset = self.dataRowOffset + 1
					self.controlsList:reloadData()
					self:updateListHeaderNames()
					return false
				end
			else
				if p94_ == FocusManager.TOP then
					local v97_ = v96_ - 1
					if v97_ == 0 then
						v95_ = v95_ - 1
						if v95_ == 0 then
							return false
						end
						v97_ = list.sections[v95_].numItems
					end
					list:makeCellVisible(v95_, v97_)
					local v98_ = self
					self.nextFocusSection = v95_
					v98_.nextFocusCell = v97_
					self.nextFocusedButtonName = "actionButton" .. v_u_75_
					return false
				end
				if p94_ == FocusManager.BOTTOM then
					local v99_ = v96_ + 1
					if list.sections[v95_].numItems < v99_ then
						v95_ = v95_ + 1
						if #list.sections < v95_ then
							return false
						end
						v99_ = 1
					end
					list:makeCellVisible(v95_, v99_)
					local v100_ = self
					self.nextFocusSection = v95_
					v100_.nextFocusCell = v99_
					self.nextFocusedButtonName = "actionButton" .. v_u_75_
					return false
				end
			end
			return true
		end
	end
	cell.actionBinding = v74_
end

function SettingsControlsFrame:inputEvent(action, value, eventUsed)
	return action == InputAction.MENU_ACCEPT and true or eventUsed
end

-- Local values: rowIndex, focusedButton, bindingControlsRowIndex, deviceInfoIndex
function SettingsControlsFrame:onMenuAcceptUp(action, value, eventUsed)
	local v104_ = 1
	if self.currentFocusCell ~= nil then
		local v105_ = FocusManager:getFocusedElement()
		v104_ = v105_.name == "actionButton2" and 2 or (v105_.name == "actionButton3" and 3 or v104_)
	end
	local v106_ = v104_ + self.dataRowOffset
	local v107_ = math.min(v106_, 4)
	self:onInputClicked(SettingsControlsFrame.DEVICES[v107_].category, SettingsControlsFrame.DEVICES[v107_].binding, self.currentFocusCell.actionBinding, v106_)
	return true
end

function SettingsControlsFrame:onInputClicked(deviceCategory, bindingId, actionData, bindingControlsRowIndex)
	if self.controlsController:onClickInput(deviceCategory, bindingId, actionData, bindingControlsRowIndex) then
		self:showInputPrompt(deviceCategory, bindingId, actionData)
	end
end

-- Local values: wrappedCallback
function SettingsControlsFrame:onClickDefaults()
	YesNoDialog.show(function(p114_)
		-- upvalues: (copy) self
		if p114_ then
			self.controlsController:loadDefaultSettings()
			self.userChangedInput = false
			self:assignDeviceTableData()
			self:updateMenuButtons()
			InfoDialog.show(g_i18n:getText(SettingsControlsFrame.L10N_SYMBOL.DEFAULTS_LOADED), function(p115_)
				p115_.controlsList:makeCellVisible(1, 1)
				p115_.nextFocusSection = 1
				p115_.nextFocusCell = 1
				p115_.nextFocusedButtonName = "actionButton1"
			end, self, DialogElement.TYPE_INFO)
		end
	end, nil, g_i18n:getText(SettingsControlsFrame.L10N_SYMBOL.LOAD_DEFAULTS), g_i18n:getText(SettingsControlsFrame.L10N_SYMBOL.BUTTON_RESET))
end

function SettingsControlsFrame:onControllerChanged()
	self.dataRowOffset = 0
	self.numTotalDevices = 3 + g_inputBinding.numActiveGamepads
	self.controlsList:makeCellVisible(1, 1, true)
	self.nextFocusSection = 1
	self.nextFocusCell = 1
	self.nextFocusedButtonName = "actionButton1"
	self:assignDeviceTableData()
	self.controlsMessageText = ""
	self:updateMenuButtons()
end

function SettingsControlsFrame:onClickNextRow()
	self.dataRowOffset = self.dataRowOffset + 1
	self.controlsList:reloadData()
	self:updateListHeaderNames()
end

function SettingsControlsFrame:onClickPrevRow()
	self.dataRowOffset = self.dataRowOffset - 1
	self.controlsList:reloadData()
	self:updateListHeaderNames()
end
SettingsControlsFrame.CONTROLS_UI_STRINGS = {
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
SettingsControlsFrame.CONFLICT_MESSAGES = {
	[ControlsController.MESSAGE_CANNOT_MAP_KEY] = true,
	[ControlsController.MESSAGE_CANNOT_MAP_MOUSE] = true,
	[ControlsController.MESSAGE_CANNOT_MAP_CONTROLLER] = true,
	[ControlsController.MESSAGE_CONFLICT_KEY] = true,
	[ControlsController.MESSAGE_CONFLICT_MOUSE] = true,
	[ControlsController.MESSAGE_CONFLICT_BUTTON] = true,
	[ControlsController.MESSAGE_CONFLICT_AXIS] = true,
	[ControlsController.MESSAGE_CONFLICT_BLOCKED_KEY] = true
}
SettingsControlsFrame.L10N_TEMPLATE_SYMBOL = {
	[ControlsController.MESSAGE_REMAPPED] = "ui_actionRemapped"
}
SettingsControlsFrame.L10N_SYMBOL = {
	["BUTTON_SAVE"] = "button_saveControls",
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
	["BUTTON_RESET"] = "button_reset"
}
SettingsControlsFrame.COLOR = {
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
local v119_ = SettingsControlsFrame
local v120_ = {
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
v119_.DEVICES = v120_
