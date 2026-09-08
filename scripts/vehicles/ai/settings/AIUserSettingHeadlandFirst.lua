-- Local values: AIUserSettingHeadlandFirst_mt
AIUserSettingHeadlandFirst = {}
local AIUserSettingHeadlandFirst_mt = Class(AIUserSettingHeadlandFirst, AIUserSetting)

-- Upvalues: AIUserSettingHeadlandFirst_mt
-- Local values: self
function AIUserSettingHeadlandFirst.new(customMt)
	-- upvalues: (copy) AIUserSettingHeadlandFirst_mt
	local v3_ = AIUserSetting.new(customMt or AIUserSettingHeadlandFirst_mt)
	v3_.identifier = "headlandFirst"
	v3_.title = g_i18n:getText("ai_settingHeadlandFirst")
	v3_.texts = {}
	local v4_ = v3_.texts
	local v5_ = g_i18n
	table.insert(v4_, v5_:getText("ai_settingHeadlandFirstValue1"))
	local v6_ = v3_.texts
	local v7_ = g_i18n
	table.insert(v6_, v7_:getText("ai_settingHeadlandFirstValue2"))
	v3_.textMapping = {}
	v3_.textMapping[1] = false
	v3_.textMapping[2] = true
	return v3_
end

-- Local values: _, settingData
function AIUserSettingHeadlandFirst:getIsDisabled(settings)
	for _, v10_ in pairs(settings) do
		if v10_.setting.identifier == "workHeadlands" and not v10_.value then
			return true
		end
	end
	return AIUserSettingHeadlandFirst:superClass().getIsDisabled(self, settings)
end

function AIUserSettingHeadlandFirst:init(settingData, fieldCourseSettings, mode, usesDefaultFieldCourseSettings)
	local v_u_16_ = AIUserSettingHeadlandFirst:superClass().init(self, settingData, fieldCourseSettings, mode, usesDefaultFieldCourseSettings)
	function v_u_16_.callback(_, _, p17_)
		-- upvalues: (ref) v_u_16_
		v_u_16_.value = v_u_16_.setting.textMapping[p17_]
		return false
	end
	if fieldCourseSettings == nil then
		v_u_16_.value = Utils.getNoNil(v_u_16_.loadedValue, false)
	else
		v_u_16_.value = Utils.getNoNil(v_u_16_.loadedValue, fieldCourseSettings.headlandsFirst)
		if usesDefaultFieldCourseSettings then
			v_u_16_.defaultValue = fieldCourseSettings.headlandsFirst
		end
	end
	v_u_16_.loadedValue = nil
	return v_u_16_
end

function AIUserSettingHeadlandFirst:apply(settingData, fieldCourseSettings, mode)
	if mode == AIModeSelection.MODE.WORKER then
		fieldCourseSettings.headlandsFirst = settingData.value
	end
end

function AIUserSettingHeadlandFirst:registerXMLPath(schema, path)
	schema:register(XMLValueType.BOOL, string.format("%s#%s", path, self.identifier), self.title)
end
