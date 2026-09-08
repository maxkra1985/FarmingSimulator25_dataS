-- Local values: PrecisionFarmingSettings_mt
PrecisionFarmingSettings = {}
PrecisionFarmingSettings.MOD_NAME = g_currentModName
source(g_currentModDirectory .. "scripts/events/PrecisionFarmingSettingsInitialEvent.lua")
source(g_currentModDirectory .. "scripts/events/PrecisionFarmingSettingsEvent.lua")
local PrecisionFarmingSettings_mt = Class(PrecisionFarmingSettings)

-- Upvalues: PrecisionFarmingSettings_mt
-- Local values: self
function PrecisionFarmingSettings.new(precisionFarming, customMt)
	-- upvalues: (copy) PrecisionFarmingSettings_mt
	local v4_ = customMt or PrecisionFarmingSettings_mt
	local v5_ = setmetatable({}, v4_)
	v5_.precisionFarming = precisionFarming
	v5_.elementsCreated = false
	v5_.settingsHeadline = g_i18n:getText("ui_header")
	v5_.settings = {}
	v5_.settingIndexNumBits = 1
	return v5_
end

-- Local values: setting
function PrecisionFarmingSettings:addSetting(name, title, description, callback, callbackTarget, default, isCheckbox, optionTexts, isServerSetting)
	local v16_ = {
		["name"] = name,
		["title"] = title,
		["description"] = description
	}
	if default == nil then
		if isCheckbox then
			v16_.state = false
		else
			v16_.state = 0
		end
	else
		v16_.state = default
	end
	v16_.callback = callback
	v16_.callbackTarget = callbackTarget
	v16_.isCheckbox = isCheckbox
	v16_.optionTexts = optionTexts
	v16_.isServerSetting = Utils.getNoNil(isServerSetting, false)
	v16_.element = nil
	v16_.index = #self.settings + 1
	local v17_ = self.settings
	table.insert(v17_, v16_)
	self.settingIndexNumBits = MathUtil.getNumRequiredBits(#self.settings)
	self:loadSettings()
	self:onSettingChanged(v16_, true)
end

function PrecisionFarmingSettings:sendInitialClientState(connection, user, farm)
	connection:sendEvent(PrecisionFarmingSettingsInitialEvent.new(self.settings))
end

function PrecisionFarmingSettings:onSettingChanged(setting, noEventSend)
	if setting.callback == nil or setting.callbackTarget ~= nil then
		if setting.callback ~= nil and setting.callbackTarget ~= nil then
			setting.callback(setting.callbackTarget, setting.state)
		end
	else
		setting.callback(setting.state)
	end
	self:saveSettings()
	if setting.isServerSetting then
		PrecisionFarmingSettingsEvent.sendEvent(setting, noEventSend)
	end
end

-- Local values: i, setting
function PrecisionFarmingSettings:saveSettings()
	if g_savegameXML ~= nil then
		for v24_ = 1, #self.settings do
			local v25_ = self.settings[v24_]
			if v25_.isCheckbox then
				setXMLBool(g_savegameXML, string.format("gameSettings.precisionFarming.settings.%s#state", v25_.name), v25_.state)
			else
				setXMLInt(g_savegameXML, string.format("gameSettings.precisionFarming.settings.%s#state", v25_.name), v25_.state)
			end
		end
	end
	g_gameSettings:save()
end

-- Local values: i, setting
function PrecisionFarmingSettings:loadSettings()
	if g_savegameXML ~= nil then
		for v27_ = 1, #self.settings do
			local v28_ = self.settings[v27_]
			if v28_.isCheckbox then
				v28_.state = Utils.getNoNil(getXMLBool(g_savegameXML, string.format("gameSettings.precisionFarming.settings.%s#state", v28_.name)), v28_.state)
			else
				v28_.state = Utils.getNoNil(getXMLInt(g_savegameXML, string.format("gameSettings.precisionFarming.settings.%s#state", v28_.name)), v28_.state)
			end
		end
	end
end

-- Local values: i, setting
function PrecisionFarmingSettings:onClickCheckbox(state, checkboxElement)
	for v32_ = 1, #self.settings do
		local v33_ = self.settings[v32_]
		if v33_.element == checkboxElement then
			v33_.state = state == CheckedOptionElement.STATE_CHECKED
			self:onSettingChanged(v33_)
		end
	end
end

-- Local values: i, setting
function PrecisionFarmingSettings:onClickMultiOption(state, optionElement)
	for v37_ = 1, #self.settings do
		local v38_ = self.settings[v37_]
		if v38_.element == optionElement then
			v38_.state = state
			self:onSettingChanged(v38_)
		end
	end
end

-- Local values: numSettings, i, setting, i, elem, header, binaryOptionElem, multiTextOptionElem, i, elem, i, setting
function PrecisionFarmingSettings:addSettingsToLayout(frame, layout, settings, isServerSetting)
	local v43_ = 0
	for v44_ = 1, #settings do
		if settings[v44_].isServerSetting == isServerSetting then
			v43_ = v43_ + 1
		end
	end
	if v43_ > 0 then
		for v45_ = 1, #layout.elements do
			local v46_ = layout.elements[v45_]
			if v46_:isa(TextElement) then
				v46_:clone(layout):setText(self.settingsHeadline)
				break
			end
		end
		local v47_ = nil
		local v48_ = nil
		for v49_ = 1, #layout.elements do
			local v50_ = layout.elements[v49_]
			if v50_:isa(BitmapElement) and #v50_.elements > 0 then
				if v50_.elements[1]:isa(BinaryOptionElement) and v47_ == nil then
					v47_ = v50_
					v50_ = v48_
				elseif v50_.elements[1]:isa(MultiTextOptionElement) then
					if v48_ ~= nil then
						v50_ = v48_
					end
				else
					v50_ = v48_
				end
			else
				v50_ = v48_
			end
			if v47_ ~= nil and v50_ ~= nil then
				v48_ = v50_
				break
			end
			v48_ = v50_
		end
		for v51_ = 1, #self.settings do
			local v52_ = self.settings[v51_]
			if v52_.isServerSetting == isServerSetting then
				if v52_.isCheckbox then
					if v47_ ~= nil then
						v52_.parent = v47_:clone(layout, false)
						v52_.element = v52_.parent.elements[1]
						function v52_.element.onClickCallback(_, ...)
							-- upvalues: (copy) self
							self:onClickCheckbox(...)
						end
						v52_.element:setIsChecked(v52_.state, true)
						v52_.element:setDisabled(false)
						v52_.element:updateSelection()
						v52_.parent.elements[2]:setText(v52_.title)
						v52_.element.elements[1]:setText(v52_.description)
					end
				elseif v48_ ~= nil then
					v52_.parent = v48_:clone(layout, false)
					v52_.element = v52_.parent.elements[1]
					v52_.element:setTexts(v52_.optionTexts)
					function v52_.element.onClickCallback(_, ...)
						-- upvalues: (copy) self
						self:onClickMultiOption(...)
					end
					v52_.element:setState(v52_.state)
					v52_.parent.elements[2]:setText(v52_.title)
					v52_.element.elements[1]:setText(v52_.description)
				end
			end
		end
		layout:invalidateLayout()
	end
end

function PrecisionFarmingSettings:overwriteGameFunctions(pfModule)
	pfModule:overwriteGameFunction(InGameMenuSettingsFrame, "onFrameOpen", function(p55_, p56_, p57_)
		-- upvalues: (copy) self
		p55_(p56_, p57_)
		if not self.elementsCreated then
			self:addSettingsToLayout(p56_, p56_.generalSettingsLayout, self.settings, false)
			self:addSettingsToLayout(p56_, p56_.gameSettingsLayout, self.settings, true)
			self.elementsCreated = true
			if p56_.checkLimeRequired ~= nil then
				p56_.checkLimeRequired.parent:setVisible(false)
				p56_.gameSettingsLayout:invalidateLayout()
			end
		end
	end)
end
