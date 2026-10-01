PrecisionFarmingSettings = {}
PrecisionFarmingSettings.MOD_NAME = g_currentModName
source(g_currentModDirectory .. "scripts/events/PrecisionFarmingSettingsInitialEvent.lua")
source(g_currentModDirectory .. "scripts/events/PrecisionFarmingSettingsEvent.lua")
local PrecisionFarmingSettings_mt = Class(PrecisionFarmingSettings)
function PrecisionFarmingSettings.new(precisionFarming, customMt)
	local self = setmetatable({}, customMt or PrecisionFarmingSettings_mt)
	self.precisionFarming = precisionFarming
	self.elementsCreated = false
	self.settingsHeadline = g_i18n:getText("ui_header")
	self.settings = {}
	self.settingIndexNumBits = 1
	return self
end
function PrecisionFarmingSettings:addSetting(name, title, description, callback, callbackTarget, default, isCheckbox, optionTexts, isServerSetting)
	local setting = {}
	setting.name = name
	setting.title = title
	setting.description = description
	if default ~= nil then
		setting.state = default
	elseif isCheckbox then
		setting.state = false
	else
		setting.state = 0
	end
	setting.callback = callback
	setting.callbackTarget = callbackTarget
	setting.isCheckbox = isCheckbox
	setting.optionTexts = optionTexts
	setting.isServerSetting = Utils.getNoNil(isServerSetting, false)
	setting.element = nil
	setting.index = #self.settings + 1
	table.insert(self.settings, setting)
	self.settingIndexNumBits = MathUtil.getNumRequiredBits(#self.settings)
	self:loadSettings()
	self:onSettingChanged(setting, true)
end
function PrecisionFarmingSettings:sendInitialClientState(connection, user, farm)
	connection:sendEvent(PrecisionFarmingSettingsInitialEvent.new(self.settings))
end
function PrecisionFarmingSettings:onSettingChanged(setting, noEventSend)
	if setting.callback ~= nil then
		if setting.callbackTarget == nil then
			setting.callback(setting.state)
		elseif setting.callback ~= nil then
			if setting.callbackTarget ~= nil then
				setting.callback(setting.callbackTarget, setting.state)
			end
		end
	end
	self:saveSettings()
	if setting.isServerSetting then
		PrecisionFarmingSettingsEvent.sendEvent(setting, noEventSend)
	end
end
function PrecisionFarmingSettings:saveSettings()
	if g_savegameXML ~= nil then
		for i = 1, #self.settings do
			local setting = self.settings[i]
			if setting.isCheckbox then
				setXMLBool(g_savegameXML, string.format("gameSettings.precisionFarming.settings.%s#state", setting.name), setting.state)
			else
				setXMLInt(g_savegameXML, string.format("gameSettings.precisionFarming.settings.%s#state", setting.name), setting.state)
			end
		end
	end
	g_gameSettings:save()
end
function PrecisionFarmingSettings:loadSettings()
	if g_savegameXML ~= nil then
		for i = 1, #self.settings do
			local setting = self.settings[i]
			if setting.isCheckbox then
				setting.state = Utils.getNoNil(getXMLBool(g_savegameXML, string.format("gameSettings.precisionFarming.settings.%s#state", setting.name)), setting.state)
			else
				setting.state = Utils.getNoNil(getXMLInt(g_savegameXML, string.format("gameSettings.precisionFarming.settings.%s#state", setting.name)), setting.state)
			end
		end
	end
end
function PrecisionFarmingSettings:onClickCheckbox(state, checkboxElement)
	for i = 1, #self.settings do
		local setting = self.settings[i]
		if setting.element == checkboxElement then
			setting.state = state == CheckedOptionElement.STATE_CHECKED
			self:onSettingChanged(setting)
		end
	end
end
function PrecisionFarmingSettings:onClickMultiOption(state, optionElement)
	for i = 1, #self.settings do
		local setting = self.settings[i]
		if setting.element == optionElement then
			setting.state = state
			self:onSettingChanged(setting)
		end
	end
end
function PrecisionFarmingSettings:addSettingsToLayout(frame, layout, settings, isServerSetting)
	local numSettings = 0
	for i = 1, #settings do
		local setting = settings[i]
		if setting.isServerSetting == isServerSetting then
			numSettings = numSettings + 1
		end
	end
	if 0 < numSettings then
		for i = 1, #layout.elements do
			local elem = layout.elements[i]
			if elem:isa(TextElement) then
				local header = elem:clone(layout)
				header:setText(self.settingsHeadline)
				break
			end
		end
		local binaryOptionElem = nil
		local multiTextOptionElem = nil
		for i = 1, #layout.elements do
			local elem = layout.elements[i]
			if elem:isa(BitmapElement) and (0 < #elem.elements and elem.elements[1]:isa(BinaryOptionElement)) then
				if binaryOptionElem == nil then
					binaryOptionElem = elem
				elseif elem.elements[1]:isa(MultiTextOptionElement) then
					if multiTextOptionElem == nil then
						multiTextOptionElem = elem
					end
				end
			end
			for i = 1, #self.settings do
				local setting = self.settings[i]
				if setting.isServerSetting == isServerSetting then
					if setting.isCheckbox then
						if binaryOptionElem == nil then
							continue
						end
						setting.parent = binaryOptionElem:clone(layout, false)
						setting.element = setting.parent.elements[1]
						function setting.element.onClickCallback(_, ...)
							self:onClickCheckbox(...)
						end
						setting.element:setIsChecked(setting.state, true)
						setting.element:setDisabled(false)
						setting.element:updateSelection()
						setting.parent.elements[2]:setText(setting.title)
						setting.element.elements[1]:setText(setting.description)
					else
						if multiTextOptionElem == nil then
							continue
						end
						setting.parent = multiTextOptionElem:clone(layout, false)
						setting.element = setting.parent.elements[1]
						setting.element:setTexts(setting.optionTexts)
						function setting.element.onClickCallback(_, ...)
							self:onClickMultiOption(...)
						end
						setting.element:setState(setting.state)
						setting.parent.elements[2]:setText(setting.title)
						setting.element.elements[1]:setText(setting.description)
					end
				end
			end
			layout:invalidateLayout()
			return
		end
	end
end
function PrecisionFarmingSettings:overwriteGameFunctions(pfModule)
	pfModule:overwriteGameFunction(InGameMenuSettingsFrame, "onFrameOpen", function(superFunc, frame, element)
		superFunc(frame, element)
		if not self.elementsCreated then
			self:addSettingsToLayout(frame, frame.generalSettingsLayout, self.settings, false)
			self:addSettingsToLayout(frame, frame.gameSettingsLayout, self.settings, true)
			self.elementsCreated = true
			if frame.checkLimeRequired ~= nil then
				frame.checkLimeRequired.parent:setVisible(false)
				frame.gameSettingsLayout:invalidateLayout()
			end
		end
	end)
end
