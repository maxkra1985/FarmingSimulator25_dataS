-- Local values: InputHelpDisplayExtension_mt
InputHelpDisplayExtension = {}
InputHelpDisplayExtension.MOD_NAME = g_currentModName
InputHelpDisplayExtension.MOD_DIR = g_currentModDirectory
local InputHelpDisplayExtension_mt = Class(InputHelpDisplayExtension)

-- Upvalues: InputHelpDisplayExtension_mt
-- Local values: self
function InputHelpDisplayExtension.new(precisionFarming, customMt)
	-- upvalues: (copy) InputHelpDisplayExtension_mt
	local v4_ = customMt or InputHelpDisplayExtension_mt
	local v5_ = setmetatable({}, v4_)
	v5_.isEnabled = true
	v5_.precisionFarming = precisionFarming
	v5_.headline = utf8ToUpper(g_i18n:getText("ui_header"))
	v5_.precisionFarming:addSetting("inputHelpDisplay", g_i18n:getText("settingTitle_inputHelpDisplay"), g_i18n:getText("settingDescription_inputHelpDisplay"), v5_.onInputHelpDisplaySettingChanged, v5_, v5_.isEnabled, true)
	return v5_
end

function InputHelpDisplayExtension:onInputHelpDisplaySettingChanged(state)
	self.isEnabled = state
end

function InputHelpDisplayExtension:overwriteGameFunctions(pfModule)
	pfModule:overwriteGameFunction(InputHelpDisplay, "draw", function(p10_, p11_, p12_, p13_)
		-- upvalues: (copy) self
		if self.isEnabled then
			if p11_:getVisible() then
				p10_(p11_, p12_, p13_)
			else
				local v14_, v15_ = p11_:getPosition()
				local v16_ = v14_ + (p12_ or 0)
				local v17_, _ = p11_:drawVehicleSchema(v16_, v15_ + (p13_ or 0), false)
				table.sort(p11_.helpExtensions, function(p18_, p19_)
					return p18_.priority < p19_.priority
				end)
				local v20_ = 0
				local v21_ = 0
				for v22_ = #p11_.helpExtensions, 1, -1 do
					local v23_ = p11_.helpExtensions[v22_]:getHeight()
					if v23_ > 0 then
						v20_ = v20_ + v23_ + p11_.lineOffsetY
					else
						table.remove(p11_.helpExtensions, v22_)
					end
				end
				for v24_, v25_ in pairs(p11_.helpExtensions) do
					if v21_ < (v25_.priority <= GS_PRIO_HIGH and InputHelpDisplay.MAX_NUM_ELEMENTS_HIGH_PRIORITY or InputHelpDisplay.MAX_NUM_ELEMENTS) then
						v17_ = v25_:draw(p11_, v16_, v17_) - p11_.lineOffsetY
						v21_ = v21_ + 1
					end
					p11_.helpExtensions[v24_] = nil
				end
			end
		else
			p10_(p11_, p12_, p13_)
			return
		end
	end)
	pfModule:overwriteGameFunction(InputHelpDisplay, "addHelpExtension", function(p26_, p27_, p28_)
		-- upvalues: (copy) self
		if self.isEnabled and not p27_:getVisible() then
			if p28_:isa(ExtendedSowingMachineHUDExtension) or (p28_:isa(ExtendedSprayerHUDExtension) or p28_:isa(ExtendedCombineHUDExtension)) then
				local v29_ = p27_.helpExtensions
				table.insert(v29_, p28_)
			else
				p26_(p27_, p28_)
			end
		else
			p26_(p27_, p28_)
			return
		end
	end)
end
