AIUserSettingShowLines = {}
local AIUserSettingShowLines_mt = Class(AIUserSettingShowLines, AIUserSetting)
function AIUserSettingShowLines.new(customMt)
	local self = AIUserSetting.new(customMt or AIUserSettingShowLines_mt)
	self.identifier = "showLines"
	self.title = g_i18n:getText("ai_settingShowLines")
	self.isVineyardSetting = true
	return self
end
function AIUserSettingShowLines:init(settingData, fieldCourseSettings, mode, usesDefaultFieldCourseSettings)
	settingData = AIUserSettingShowLines:superClass().init(self, settingData, fieldCourseSettings, mode, usesDefaultFieldCourseSettings)
	function settingData.callback(_, value, index)
		settingData.value = value
		return false
	end
	settingData.value = g_gameSettings:getValue(GameSettings.SETTING.STEERING_ASSIST_LINES)
	return settingData
end
function AIUserSettingShowLines:apply(settingData, fieldCourseSettings, mode)
	g_gameSettings:setValue(GameSettings.SETTING.STEERING_ASSIST_LINES, settingData.value, true)
end
function AIUserSettingShowLines:registerXMLPath(schema, path)
	schema:register(XMLValueType.BOOL, string.format("%s#%s", path, self.identifier), self.title)
end
