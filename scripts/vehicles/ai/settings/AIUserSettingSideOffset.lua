-- Local values: AIUserSettingSideOffset_mt
AIUserSettingSideOffset = {}
local AIUserSettingSideOffset_mt = Class(AIUserSettingSideOffset, AIUserSetting)

-- Upvalues: AIUserSettingSideOffset_mt
-- Local values: self
function AIUserSettingSideOffset.new(customMt)
	-- upvalues: (copy) AIUserSettingSideOffset_mt
	local v3_ = AIUserSetting.new(customMt or AIUserSettingSideOffset_mt)
	v3_.identifier = "sideOffset"
	v3_.title = g_i18n:getText("ai_settingSideOffset")
	v3_.unitText = g_i18n:getText("unit_mShort")
	v3_.defaultPostFix = g_i18n:getText("ai_settingDefaultPostFix")
	v3_.inputDelay = 100
	return v3_
end

function AIUserSettingSideOffset:init(settingData, fieldCourseSettings, mode, usesDefaultFieldCourseSettings)
	local v_u_9_ = AIUserSettingSideOffset:superClass().init(self, settingData, fieldCourseSettings, mode, usesDefaultFieldCourseSettings)
	function v_u_9_.callback(_, p10_, _)
		-- upvalues: (ref) v_u_9_
		v_u_9_.value = p10_
		if type(p10_) == "string" then
			local v11_ = v_u_9_
			local v12_ = string.split(p10_, " ")[1]
			v11_.value = tonumber(v12_)
		end
		return false
	end
	v_u_9_.step = 0.1
	v_u_9_.max = 5
	v_u_9_.min = -v_u_9_.max
	if fieldCourseSettings == nil then
		v_u_9_.value = MathUtil.round(v_u_9_.loadedValue or 0, 1)
	else
		v_u_9_.value = MathUtil.round(v_u_9_.loadedValue or fieldCourseSettings.sideOffset, 1)
		if usesDefaultFieldCourseSettings then
			v_u_9_.defaultValue = fieldCourseSettings.sideOffset
		end
	end
	v_u_9_.loadedValue = nil
	return v_u_9_
end

function AIUserSettingSideOffset:apply(settingData, fieldCourseSettings, mode)
	fieldCourseSettings.sideOffset = settingData.value
end
