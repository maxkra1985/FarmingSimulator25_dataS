-- Local values: AIUserSettingWorkHeadlands_mt
AIUserSettingWorkHeadlands = {}
local AIUserSettingWorkHeadlands_mt = Class(AIUserSettingWorkHeadlands, AIUserSetting)

-- Upvalues: AIUserSettingWorkHeadlands_mt
-- Local values: self
function AIUserSettingWorkHeadlands.new(customMt)
	-- upvalues: (copy) AIUserSettingWorkHeadlands_mt
	local v3_ = AIUserSetting.new(customMt or AIUserSettingWorkHeadlands_mt)
	v3_.identifier = "workHeadlands"
	v3_.title = g_i18n:getText("ai_settingWorkHeadlands")
	return v3_
end

function AIUserSettingWorkHeadlands:init(settingData, fieldCourseSettings, mode, usesDefaultFieldCourseSettings)
	local v_u_9_ = AIUserSettingWorkHeadlands:superClass().init(self, settingData, fieldCourseSettings, mode, usesDefaultFieldCourseSettings)
	function v_u_9_.callback(_, p10_, _)
		-- upvalues: (ref) v_u_9_
		v_u_9_.value = p10_
		return false
	end
	if fieldCourseSettings == nil then
		v_u_9_.value = Utils.getNoNil(v_u_9_.loadedValue, true)
	else
		v_u_9_.value = Utils.getNoNil(v_u_9_.loadedValue, fieldCourseSettings.workHeadlands)
	end
	v_u_9_.loadedValue = nil
	return v_u_9_
end

function AIUserSettingWorkHeadlands:apply(settingData, fieldCourseSettings, mode)
	if mode == AIModeSelection.MODE.WORKER then
		fieldCourseSettings.workHeadlands = settingData.value
	else
		fieldCourseSettings.workHeadlands = true
	end
end

-- Local values: _, otherSettingData
function AIUserSettingWorkHeadlands:onSettingsChanged(settingData, otherSettings)
	AIUserSettingWorkHeadlands:superClass().onSettingsChanged(self, settingData, otherSettings)
	for _, v17_ in pairs(otherSettings) do
		if v17_.setting.identifier == "headlandFirst" then
			if settingData.value then
				v17_.value = Utils.getNoNil(v17_.defaultValue, false)
			else
				v17_.value = false
			end
		end
	end
	return true
end

function AIUserSettingWorkHeadlands:registerXMLPath(schema, path)
	schema:register(XMLValueType.BOOL, string.format("%s#%s", path, self.identifier), self.title)
end
