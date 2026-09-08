-- Local values: SettingsDeviceFrame_mt
SettingsDeviceFrame = {}
local SettingsDeviceFrame_mt = Class(SettingsDeviceFrame, TabbedMenuFrameElement)
function SettingsDeviceFrame.register()
	local v2_ = SettingsDeviceFrame.new()
	g_gui:loadGui("dataS/gui/SettingsDeviceFrame.xml", "SettingsDeviceFrame", v2_, true)
end

-- Upvalues: SettingsDeviceFrame_mt
-- Local values: self
function SettingsDeviceFrame.new(target, custom_mt)
	-- upvalues: (copy) SettingsDeviceFrame_mt
	local v5_ = TabbedMenuFrameElement.new(target, custom_mt or SettingsDeviceFrame_mt)
	v5_.hasCustomMenuButtons = true
	v5_.stateBars = {}
	return v5_
end

-- Local values: newGui
function SettingsDeviceFrame.createFromExistingGui(gui, guiName)
	local v8_ = SettingsDeviceFrame.new()
	g_gui.frames[gui.name].target:delete()
	g_gui.frames[gui.name]:delete()
	g_gui:loadGui(gui.xmlFilename, guiName, v8_, true)
	v8_.hasCustomMenuButtons = gui.hasCustomMenuButtons
	return v8_
end

function SettingsDeviceFrame:copyAttributes(src)
	SettingsDeviceFrame:superClass().copyAttributes(self, src)
	self.hasCustomMenuButtons = src.hasCustomMenuButtons
end

function SettingsDeviceFrame:initialize()
	self.sectionTemplate:unlinkElement()
	FocusManager:removeElement(self.sectionTemplate)
	self.deadzoneTemplate:unlinkElement()
	FocusManager:removeElement(self.deadzoneTemplate)
	self.sensitivityTemplate:unlinkElement()
	FocusManager:removeElement(self.sensitivityTemplate)
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
	self.switchButtonInfo = {
		["inputAction"] = InputAction.MENU_EXTRA_1,
		["text"] = g_i18n:getText(SettingsDeviceFrame.L10N_SYMBOL.SWITCH_DEVICE),
		["callback"] = function()
			-- upvalues: (copy) self
			self:onSwitchDevice()
		end
	}
	self.applyButtonInfo = {
		["inputAction"] = InputAction.MENU_ACCEPT,
		["text"] = g_i18n:getText(SettingsDeviceFrame.L10N_SYMBOL.BUTTON_APPLY),
		["callback"] = function()
			-- upvalues: (copy) self
			self:onApplySettings()
		end
	}
	self:updateController()
end

function SettingsDeviceFrame:delete()
	if self.sectionTemplate ~= nil then
		self.sectionTemplate:delete()
	end
	if self.deadzoneTemplate ~= nil then
		self.deadzoneTemplate:delete()
	end
	if self.sensitivityTemplate ~= nil then
		self.sensitivityTemplate:delete()
	end
	SettingsDeviceFrame:superClass().delete(self)
end

function SettingsDeviceFrame:onFrameOpen()
	SettingsDeviceFrame:superClass().onFrameOpen(self)
	g_settingsModel:initDeviceSettings()
	g_settingsModel:refresh()
	self:updateView()
	g_inputBinding:setContextEventsActive("MENU", InputAction.MENU_AXIS_LEFT_RIGHT, false)
	g_inputBinding:setContextEventsActive("MENU", InputAction.MENU_AXIS_UP_DOWN, false)
	g_inputBinding:registerActionEvent(InputAction.AXIS_CONSTRUCTION_MENU_UP_DOWN, self, self.onAxisUpDown, false, true, false, true)
	g_inputBinding:registerActionEvent(InputAction.AXIS_CONSTRUCTION_MENU_LEFT_RIGHT, self, self.onAxisLeftRight, true, true, true, true)
end

function SettingsDeviceFrame:onFrameClose()
	SettingsDeviceFrame:superClass().onFrameClose(self)
	g_inputBinding:setContextEventsActive("MENU", InputAction.MENU_AXIS_LEFT_RIGHT, true)
	g_inputBinding:setContextEventsActive("MENU", InputAction.MENU_AXIS_UP_DOWN, true)
	g_inputBinding:removeActionEventsByTarget(self)
end

function SettingsDeviceFrame:onAxisUpDown(actionName, value)
	g_gui:notifyControls(InputAction.MENU_AXIS_UP_DOWN, value)
end

function SettingsDeviceFrame:onAxisLeftRight(actionName, value)
	g_gui:notifyControls(InputAction.MENU_AXIS_LEFT_RIGHT, value)
end

-- Local values: buttons
function SettingsDeviceFrame:getMenuButtonInfo()
	local v18_ = { self.backButtonInfo, self.nextPageButtonInfo, self.prevPageButtonInfo }
	if g_settingsModel:getNumDevices() > 1 then
		local v19_ = self.switchButtonInfo
		table.insert(v18_, v19_)
	end
	if g_settingsModel:hasChanges() then
		local v20_ = self.applyButtonInfo
		table.insert(v18_, v20_)
	end
	return v18_
end

-- Local values: callbackFunc
function SettingsDeviceFrame:onApplySettings()
	g_settingsModel:saveChanges(SettingsModel.SETTING_CLASS.SAVE_ALL)
	InfoDialog.show(g_i18n:getText(SettingsDeviceFrame.L10N_SYMBOL.SAVING_FINISHED), function()
		-- upvalues: (copy) self
		self:setMenuButtonInfoDirty()
	end, nil, DialogElement.TYPE_INFO)
end

function SettingsDeviceFrame:onSwitchDevice()
	g_settingsModel:nextDevice()
	self:updateView()
end

-- Local values: numOfGamepads
function SettingsDeviceFrame:update(dt)
	SettingsDeviceFrame:superClass().update(self, dt)
	if getNumOfGamepads() ~= self.numOfGamepads then
		self:updateController()
	end
	self:updateGamepadInputStates()
end

-- Local values: _, barInfo, device, gamepadIndex, deadzone, sensitivity, neutralInput, value, bar, boxSize
function SettingsDeviceFrame:updateGamepadInputStates()
	for _, v26_ in pairs(self.stateBars) do
		local v27_ = g_settingsModel.deviceSettings[g_settingsModel.currentDevice].device.internalId
		local v28_ = g_settingsModel:getCurrentDeviceDeadzoneValue(v26_.axisIndex)
		local v29_ = g_settingsModel:getCurrentDeviceSensitivityValue(v26_.axisIndex)
		local v30_ = g_inputBinding:getGamepadAxisValue(v27_, v26_.axisIndex, "", 0, v28_) * v29_
		local v31_ = math.clamp(v30_, -1, 1)
		local v32_ = v26_.element.elements[1]
		local v33_ = v26_.element.absSize[1]
		local v34_ = math.abs(v31_) * v33_ * 0.5
		local v35_ = 2 * g_pixelSizeX
		v32_:setSize((math.max(v34_, v35_)))
		if v31_ < 0 then
			v32_:setPosition((1 - math.abs(v31_)) * v33_ * 0.5)
		else
			v32_:setPosition(v33_ * 0.5)
		end
		v26_.element:updateAbsolutePosition()
	end
end

function SettingsDeviceFrame:updateController()
	self.numOfGamepads = getNumOfGamepads()
	g_settingsModel:initDeviceSettings()
	self:updateView()
	self:setMenuButtonInfoDirty()
end

-- Local values: name, firstOptionElement, addSectionHeader, i, isMouse, sensitivityTemplate, optionElement, hasHeadTracking, isKeyboardAvailable, isHeadTrackingVisible, sensitivityTemplate, optionElement, device, gamepadIndex, axis, hasDeadzone, hasSensitiviy, label, title, deadzoneTemplate, optionElement, sensitivityTemplate, optionElement, isAlternate, _, container
function SettingsDeviceFrame:updateView()
	local v38_ = g_settingsModel:getCurrentDeviceName()
	if v38_ == InputDevice.DEFAULT_DEVICE_NAMES.KB_MOUSE_DEFAULT then
		v38_ = g_i18n:getText("ui_mouse")
	elseif g_i18n:hasText(v38_) then
		v38_ = g_i18n:getText(v38_)
	end
	self.titleElement:setText(string.format("%s: %s", g_i18n:getText("ui_deviceConfiguration"), v38_))
	local function v44_(p39_, p40_)
		-- upvalues: (copy) self
		local v41_ = self.sectionTemplate:clone(self.layout)
		v41_:getDescendantByName("title"):setText(p39_)
		local v42_ = v41_:getDescendantByName("box")
		v42_:setVisible(p40_ ~= nil)
		if p40_ ~= nil then
			local v43_ = self.stateBars
			table.insert(v43_, {
				["element"] = v42_,
				["axisIndex"] = p40_
			})
		end
	end
	local v45_ = nil
	for v46_ = #self.layout.elements, 1, -1 do
		self.layout.elements[v46_]:delete()
		self.layout.elements[v46_] = nil
	end
	self.stateBars = {}
	local v47_ = g_settingsModel:getIsDeviceMouse()
	local v48_
	if v47_ then
		v44_(g_i18n:getText("ui_mouse"))
		v48_ = self.sensitivityTemplate:clone(self.layout).elements[1]
		v48_:setTexts(g_settingsModel:getSensitivityTexts())
		v48_:setState(g_settingsModel:getMouseSensitivityValue())
		function v48_.onClickCallback(_, p49_)
			-- upvalues: (copy) self
			g_settingsModel:setMouseSensitivity(p49_)
			self:setMenuButtonInfoDirty()
		end
		if v45_ ~= nil then
			v48_ = v45_
		end
	else
		v48_ = v45_
	end
	local v50_ = g_gameSettings:getValue(GameSettings.SETTING.IS_HEAD_TRACKING_ENABLED)
	if v50_ then
		v50_ = isHeadTrackingAvailable()
	end
	local v51_ = getIsKeyboardAvailable()
	if v50_ then
		v50_ = v47_ or not v51_
	end
	local v52_
	if v50_ then
		v44_(g_i18n:getText("setting_headTracking"))
		v52_ = self.sensitivityTemplate:clone(self.layout).elements[1]
		v52_:setTexts(g_settingsModel:getHeadTrackingSensitivityTexts())
		v52_:setState(g_settingsModel:getHeadTrackingSensitivityValue())
		function v52_.onClickCallback(_, p53_)
			-- upvalues: (copy) self
			g_settingsModel:setHeadTrackingSensitivity(p53_)
			self:setMenuButtonInfoDirty()
		end
		if v48_ ~= nil then
			v52_ = v48_
		end
	else
		v52_ = v48_
	end
	if not v47_ then
		local v54_ = g_settingsModel.deviceSettings[g_settingsModel.currentDevice].device.internalId
		for v_u_55_ = 0, Input.MAX_NUM_AXES - 1 do
			local v56_ = g_settingsModel:getDeviceHasAxisDeadzone(v_u_55_)
			local v57_ = g_settingsModel:getDeviceHasAxisSensitivity(v_u_55_)
			if v56_ or v57_ then
				local v58_ = getGamepadAxisLabel(v_u_55_, v54_)
				local v59_ = string.format(g_i18n:getText("setting_gamepadAxis"), v_u_55_ + 1)
				if v58_ ~= "" then
					v59_ = v59_ .. " (" .. v58_ .. ")"
				end
				v44_(v59_, v_u_55_)
				local v60_
				if v56_ then
					v60_ = self.deadzoneTemplate:clone(self.layout).elements[1]
					v60_:setTexts(g_settingsModel:getDeadzoneTexts())
					v60_:setState(g_settingsModel:getDeviceAxisDeadzoneValue(v_u_55_))
					function v60_.onClickCallback(_, p61_)
						-- upvalues: (copy) v_u_55_, (copy) self
						g_settingsModel:setDeviceDeadzoneValue(v_u_55_, p61_)
						self:setMenuButtonInfoDirty()
					end
					if v52_ ~= nil then
						v60_ = v52_
					end
				else
					v60_ = v52_
				end
				if v57_ then
					v52_ = self.sensitivityTemplate:clone(self.layout).elements[1]
					v52_:setTexts(g_settingsModel:getSensitivityTexts())
					v52_:setState(g_settingsModel:getDeviceAxisSensitivityValue(v_u_55_))
					function v52_.onClickCallback(_, p62_)
						-- upvalues: (copy) v_u_55_, (copy) self
						g_settingsModel:setDeviceSensitivityValue(v_u_55_, p62_)
						self:setMenuButtonInfoDirty()
					end
					if v60_ ~= nil then
						v52_ = v60_
					end
				else
					v52_ = v60_
				end
			end
		end
	end
	self.layout:scrollTo(0, true)
	local v63_ = true
	for _, v64_ in pairs(self.layout.elements) do
		if v64_.name == "sectionHeader" then
			v63_ = true
		elseif v64_:getIsVisible() then
			local v65_ = SettingsScreen.COLOR_ALTERNATING[v63_]
			v64_:setImageColor(nil, unpack(v65_))
			v63_ = not v63_
		end
	end
	self.layout:invalidateLayout()
	if v52_ ~= nil then
		self.layout:scrollToMakeElementVisible(v52_)
		FocusManager:setFocus(v52_)
		v52_.forceFocusScrollToTop = true
	end
end
SettingsDeviceFrame.L10N_SYMBOL = {
	["BUTTON_APPLY"] = "button_apply",
	["SWITCH_DEVICE"] = "ui_switchDevice",
	["SAVING_FINISHED"] = "ui_savingFinished"
}
