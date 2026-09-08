-- Local values: AIUserSettingImplementWidth_mt
AIUserSettingImplementWidth = {}
local AIUserSettingImplementWidth_mt = Class(AIUserSettingImplementWidth, AIUserSetting)

-- Upvalues: AIUserSettingImplementWidth_mt
-- Local values: self, i
function AIUserSettingImplementWidth.new(customMt)
	-- upvalues: (copy) AIUserSettingImplementWidth_mt
	local v3_ = AIUserSetting.new(customMt or AIUserSettingImplementWidth_mt)
	v3_.identifier = "implementWidth"
	v3_.title = g_i18n:getText("ai_settingImplementWidth")
	v3_.unitText = g_i18n:getText("unit_mShort")
	v3_.defaultPostFix = g_i18n:getText("ai_settingDefaultPostFix")
	v3_.valueTexts = {}
	v3_.valueToTextIndex = {}
	v3_.min = 5
	v3_.max = 600
	v3_.step = 1
	for v4_ = v3_.min, v3_.max, v3_.step do
		local v5_ = v3_.valueTexts
		local v6_ = string.format
		local v7_ = v4_ * 0.1
		table.insert(v5_, v6_("%.1f m", v7_))
		v3_.valueToTextIndex[v4_] = #v3_.valueTexts
	end
	v3_.inputDelay = 1
	return v3_
end

-- Local values: implementWidth
function AIUserSettingImplementWidth:init(settingData, fieldCourseSettings, mode, usesDefaultFieldCourseSettings)
	local v_u_13_ = AIUserSettingImplementWidth:superClass().init(self, settingData, fieldCourseSettings, mode, usesDefaultFieldCourseSettings)
	function v_u_13_.callback(_, p14_, _)
		-- upvalues: (ref) v_u_13_
		local v15_ = v_u_13_
		local v16_ = string.split(p14_, " ")[1]
		v15_.value = (tonumber(v16_) or 1) * 10
		return true
	end
	if fieldCourseSettings == nil then
		v_u_13_.value = v_u_13_.loadedValue or 30
		v_u_13_.min = self.min
		v_u_13_.max = self.max
	else
		local v17_ = MathUtil.round(fieldCourseSettings.implementWidth * 10)
		local v18_ = self.min
		local v19_ = self.max
		local v20_ = math.clamp(v17_, v18_, v19_)
		v_u_13_.value = MathUtil.round(v_u_13_.loadedValue or v20_)
		if usesDefaultFieldCourseSettings then
			v_u_13_.defaultValue = v20_
		end
		v_u_13_.min = self.min
		v_u_13_.max = self.max
	end
	v_u_13_.loadedValue = nil
	return v_u_13_
end

function AIUserSettingImplementWidth:apply(settingData, fieldCourseSettings, mode)
	fieldCourseSettings.implementWidth = settingData.value * 0.1
end
