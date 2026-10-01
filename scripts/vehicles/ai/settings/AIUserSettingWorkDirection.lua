AIUserSettingWorkDirection = {}
local AIUserSettingWorkDirection_mt = Class(AIUserSettingWorkDirection, AIUserSetting)
function AIUserSettingWorkDirection.new(customMt)
	local self = AIUserSetting.new(customMt or AIUserSettingWorkDirection_mt)
	self.identifier = "workDirection"
	self.title = g_i18n:getText("ai_settingWorkDirection")
	self.texts = {}
	self.textMapping = {}
	table.insert(self.texts, g_i18n:getText("ai_settingAutomatic"))
	self.textMapping[1] = -57.29577951308232
	for i = 0, 175, 5 do
		table.insert(self.texts, string.format("%d \194\176", i))
		self.textMapping[#self.texts] = i
	end
	self.inputDelay = 100
	return self
end
function AIUserSettingWorkDirection:init(settingData, fieldCourseSettings, mode, usesDefaultFieldCourseSettings)
	settingData = AIUserSettingWorkDirection:superClass().init(self, settingData, fieldCourseSettings, mode, usesDefaultFieldCourseSettings)
	function settingData.callback(_, value, index)
		settingData.value = settingData.setting.textMapping[index]
		return true
	end
	if fieldCourseSettings ~= nil then
		settingData.value = settingData.loadedValue or math.deg(fieldCourseSettings.workDirection)
	else
		settingData.value = settingData.loadedValue or -57.29577951308232
	end
	settingData.loadedValue = nil
	return settingData
end
function AIUserSettingWorkDirection:apply(settingData, fieldCourseSettings, mode)
	if settingData.value == nil then
		fieldCourseSettings.workDirection = -1
	else
		fieldCourseSettings.workDirection = math.rad(settingData.value)
	end
end
function AIUserSettingWorkDirection:registerXMLPath(schema, path)
	schema:register(XMLValueType.INT, string.format("%s#%s", path, self.identifier), self.title)
end
