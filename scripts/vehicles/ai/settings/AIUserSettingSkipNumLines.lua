-- Local values: AIUserSettingSkipNumLines_mt
AIUserSettingSkipNumLines = {}
local AIUserSettingSkipNumLines_mt = Class(AIUserSettingSkipNumLines, AIUserSetting)

-- Upvalues: AIUserSettingSkipNumLines_mt
-- Local values: self
function AIUserSettingSkipNumLines.new(customMt)
	-- upvalues: (copy) AIUserSettingSkipNumLines_mt
	local v3_ = AIUserSetting.new(customMt or AIUserSettingSkipNumLines_mt)
	v3_.identifier = "skipNumLines"
	v3_.title = g_i18n:getText("ai_settingSkipNumLines")
	return v3_
end

function AIUserSettingSkipNumLines:init(settingData, fieldCourseSettings, mode, usesDefaultFieldCourseSettings)
	local v_u_9_ = AIUserSettingSkipNumLines:superClass().init(self, settingData, fieldCourseSettings, mode, usesDefaultFieldCourseSettings)
	function v_u_9_.callback(_, p10_, _)
		-- upvalues: (ref) v_u_9_
		v_u_9_.value = tonumber(p10_)
		return false
	end
	if fieldCourseSettings == nil then
		v_u_9_.value = v_u_9_.loadedValue or 0
	else
		v_u_9_.value = v_u_9_.loadedValue or (fieldCourseSettings.skipNumLines or 0)
	end
	v_u_9_.min = 0
	v_u_9_.max = 5
	v_u_9_.step = 1
	v_u_9_.loadedValue = nil
	return v_u_9_
end

function AIUserSettingSkipNumLines:apply(settingData, fieldCourseSettings, mode)
	if mode == AIModeSelection.MODE.WORKER then
		fieldCourseSettings.skipNumLines = settingData.value
	else
		fieldCourseSettings.skipNumLines = 0
	end
end

function AIUserSettingSkipNumLines:registerXMLPath(schema, path)
	schema:register(XMLValueType.INT, string.format("%s#%s", path, self.identifier), self.title)
end
