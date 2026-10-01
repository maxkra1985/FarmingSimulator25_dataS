AIUserSettingNumHeadlands = {}
local AIUserSettingNumHeadlands_mt = Class(AIUserSettingNumHeadlands, AIUserSetting)
function AIUserSettingNumHeadlands.new(customMt)
	local self = AIUserSetting.new(customMt or AIUserSettingNumHeadlands_mt)
	self.identifier = "numHeadlands"
	self.title = g_i18n:getText("ai_settingNumHeadlands")
	self.defaultPostFix = g_i18n:getText("ai_settingDefaultPostFix")
	return self
end
function AIUserSettingNumHeadlands:init(settingData, fieldCourseSettings, mode, usesDefaultFieldCourseSettings)
	settingData = AIUserSettingNumHeadlands:superClass().init(self, settingData, fieldCourseSettings, mode, usesDefaultFieldCourseSettings)
	if fieldCourseSettings ~= nil then
		settingData.value = settingData.loadedValue or fieldCourseSettings.numHeadlands
		if usesDefaultFieldCourseSettings then
			settingData.defaultValue = fieldCourseSettings.numHeadlands
		end
		if mode == AIModeSelection.MODE.WORKER then
			local numHeadlands = settingData.defaultValue or fieldCourseSettings.numHeadlands
			settingData.min = numHeadlands
			settingData.max = math.ceil(numHeadlands * 2)
		else
			settingData.min = 1
			settingData.max = math.ceil((settingData.defaultValue or fieldCourseSettings.numHeadlands) * 2)
		end
		settingData.step = 1
	else
		settingData.value = settingData.loadedValue or 1
		settingData.min = 1
		settingData.max = 5
		settingData.step = 1
	end
	settingData.useSlider = true
	settingData.loadedValue = nil
	return settingData
end
function AIUserSettingNumHeadlands:apply(settingData, fieldCourseSettings, mode)
	fieldCourseSettings.numHeadlands = settingData.value
end
function AIUserSettingNumHeadlands:adjustToCourse(settingData, fieldCourse, mode)
	local numCreatedBoundaries = #fieldCourse.courseField.headlandBoundaries
	if numCreatedBoundaries < settingData.value then
		settingData.value = numCreatedBoundaries
	end
end
function AIUserSettingNumHeadlands:registerXMLPath(schema, path)
	schema:register(XMLValueType.INT, string.format("%s#%s", path, self.identifier), self.title)
end
