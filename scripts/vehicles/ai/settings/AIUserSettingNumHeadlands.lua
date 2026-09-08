-- Local values: AIUserSettingNumHeadlands_mt
AIUserSettingNumHeadlands = {}
local AIUserSettingNumHeadlands_mt = Class(AIUserSettingNumHeadlands, AIUserSetting)

-- Upvalues: AIUserSettingNumHeadlands_mt
-- Local values: self
function AIUserSettingNumHeadlands.new(customMt)
	-- upvalues: (copy) AIUserSettingNumHeadlands_mt
	local v3_ = AIUserSetting.new(customMt or AIUserSettingNumHeadlands_mt)
	v3_.identifier = "numHeadlands"
	v3_.title = g_i18n:getText("ai_settingNumHeadlands")
	v3_.defaultPostFix = g_i18n:getText("ai_settingDefaultPostFix")
	return v3_
end

-- Local values: numHeadlands
function AIUserSettingNumHeadlands:init(settingData, fieldCourseSettings, mode, usesDefaultFieldCourseSettings)
	local v9_ = AIUserSettingNumHeadlands:superClass().init(self, settingData, fieldCourseSettings, mode, usesDefaultFieldCourseSettings)
	if fieldCourseSettings == nil then
		v9_.value = v9_.loadedValue or 1
		v9_.min = 1
		v9_.max = 5
		v9_.step = 1
	else
		v9_.value = v9_.loadedValue or fieldCourseSettings.numHeadlands
		if usesDefaultFieldCourseSettings then
			v9_.defaultValue = fieldCourseSettings.numHeadlands
		end
		if mode == AIModeSelection.MODE.WORKER then
			local v10_ = v9_.defaultValue or fieldCourseSettings.numHeadlands
			v9_.min = v10_
			local v11_ = v10_ * 2
			v9_.max = math.ceil(v11_)
		else
			v9_.min = 1
			local v12_ = (v9_.defaultValue or fieldCourseSettings.numHeadlands) * 2
			v9_.max = math.ceil(v12_)
		end
		v9_.step = 1
	end
	v9_.useSlider = true
	v9_.loadedValue = nil
	return v9_
end

function AIUserSettingNumHeadlands:apply(settingData, fieldCourseSettings, mode)
	fieldCourseSettings.numHeadlands = settingData.value
end

-- Local values: numCreatedBoundaries
function AIUserSettingNumHeadlands:adjustToCourse(settingData, fieldCourse, mode)
	local v17_ = #fieldCourse.courseField.headlandBoundaries
	if v17_ < settingData.value then
		settingData.value = v17_
	end
end

function AIUserSettingNumHeadlands:registerXMLPath(schema, path)
	schema:register(XMLValueType.INT, string.format("%s#%s", path, self.identifier), self.title)
end
