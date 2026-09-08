-- Local values: AIUserSettingShowLines_mt
AIUserSettingShowLines = {}
local AIUserSettingShowLines_mt = Class(AIUserSettingShowLines, AIUserSetting)

-- Upvalues: AIUserSettingShowLines_mt
-- Local values: self
function AIUserSettingShowLines.new(customMt)
	-- upvalues: (copy) AIUserSettingShowLines_mt
	local v3_ = AIUserSetting.new(customMt or AIUserSettingShowLines_mt)
	v3_.identifier = "showLines"
	v3_.title = g_i18n:getText("ai_settingShowLines")
	v3_.isVineyardSetting = true
	return v3_
end

function AIUserSettingShowLines:init(settingData, fieldCourseSettings, mode, usesDefaultFieldCourseSettings)
	local v_u_9_ = AIUserSettingShowLines:superClass().init(self, settingData, fieldCourseSettings, mode, usesDefaultFieldCourseSettings)
	function v_u_9_.callback(_, p10_, _)
		-- upvalues: (ref) v_u_9_
		v_u_9_.value = p10_
		return false
	end
	v_u_9_.value = g_gameSettings:getValue(GameSettings.SETTING.STEERING_ASSIST_LINES)
	return v_u_9_
end

function AIUserSettingShowLines:apply(settingData, fieldCourseSettings, mode)
	g_gameSettings:setValue(GameSettings.SETTING.STEERING_ASSIST_LINES, settingData.value, true)
end

function AIUserSettingShowLines:registerXMLPath(schema, path)
	schema:register(XMLValueType.BOOL, string.format("%s#%s", path, self.identifier), self.title)
end
