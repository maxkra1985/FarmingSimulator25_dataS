InputHelpDisplayExtension = {}
InputHelpDisplayExtension.MOD_NAME = g_currentModName
InputHelpDisplayExtension.MOD_DIR = g_currentModDirectory
local InputHelpDisplayExtension_mt = Class(InputHelpDisplayExtension)
function InputHelpDisplayExtension.new(precisionFarming, customMt)
	local self = setmetatable({}, customMt or InputHelpDisplayExtension_mt)
	self.isEnabled = true
	self.precisionFarming = precisionFarming
	self.headline = utf8ToUpper(g_i18n:getText("ui_header"))
	self.precisionFarming:addSetting("inputHelpDisplay", g_i18n:getText("settingTitle_inputHelpDisplay"), g_i18n:getText("settingDescription_inputHelpDisplay"), self.onInputHelpDisplaySettingChanged, self, self.isEnabled, true)
	return self
end
function InputHelpDisplayExtension:onInputHelpDisplaySettingChanged(state)
	self.isEnabled = state
end
function InputHelpDisplayExtension:overwriteGameFunctions(pfModule)
	pfModule:overwriteGameFunction(InputHelpDisplay, "draw", function(superFunc, _self, offsetX, offsetY)
		if self.isEnabled then
			if not _self:getVisible() then
				local posX, posY = _self:getPosition()
				local numElements = 0
				local _ = nil
				posX = posX + (offsetX or 0)
				posY = posY + (offsetY or 0)
				posY, _ = _self:drawVehicleSchema(posX, posY, false)
				table.sort(_self.helpExtensions, function(a, b)
					return a.priority < b.priority
				end)
				local helpExtensionTotalHeight = 0
				for i = #_self.helpExtensions, 1, -1 do
					local helpExtension = _self.helpExtensions[i]
					local height = helpExtension:getHeight()
					if 0 < height then
						helpExtensionTotalHeight = helpExtensionTotalHeight + height + _self.lineOffsetY
					else
						table.remove(_self.helpExtensions, i)
					end
				end
				for k, extension in pairs(_self.helpExtensions) do
					local maxNumElements = extension.priority <= GS_PRIO_HIGH and InputHelpDisplay.MAX_NUM_ELEMENTS_HIGH_PRIORITY or InputHelpDisplay.MAX_NUM_ELEMENTS
					if numElements < maxNumElements then
						posY = extension:draw(_self, posX, posY)
						posY = posY - _self.lineOffsetY
						numElements = numElements + 1
					end
					_self.helpExtensions[k] = nil
				end
				return
			else
				superFunc(_self, offsetX, offsetY)
				return
			end
		end
		superFunc(_self, offsetX, offsetY)
	end)
	pfModule:overwriteGameFunction(InputHelpDisplay, "addHelpExtension", function(superFunc, _self, extension)
		if self.isEnabled and not _self:getVisible() then
			if extension:isa(ExtendedSowingMachineHUDExtension) or extension:isa(ExtendedSprayerHUDExtension) or extension:isa(ExtendedCombineHUDExtension) then
				table.insert(_self.helpExtensions, extension)
				return
			end
			superFunc(_self, extension)
			return
		end
		superFunc(_self, extension)
	end)
end
