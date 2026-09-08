-- Local values: AIUserSettingWorkDirection_mt
AIUserSettingWorkDirection = {}
local AIUserSettingWorkDirection_mt = Class(AIUserSettingWorkDirection, AIUserSetting)

-- Upvalues: AIUserSettingWorkDirection_mt
-- Local values: self, i
function AIUserSettingWorkDirection.new(customMt)
	-- upvalues: (copy) AIUserSettingWorkDirection_mt
	local v3_ = AIUserSetting.new(customMt or AIUserSettingWorkDirection_mt)
	v3_.identifier = "workDirection"
	v3_.title = g_i18n:getText("ai_settingWorkDirection")
	v3_.texts = {}
	v3_.textMapping = {}
	local v4_ = v3_.texts
	local v5_ = g_i18n
	table.insert(v4_, v5_:getText("ai_settingAutomatic"))
	v3_.textMapping[1] = -57.29577951308232
	for v6_ = 0, 175, 5 do
		local v7_ = v3_.texts
		local v8_ = string.format
		table.insert(v7_, v8_("%d \194\176", v6_))
		v3_.textMapping[#v3_.texts] = v6_
	end
	v3_.inputDelay = 100
	return v3_
end

function AIUserSettingWorkDirection:init(settingData, fieldCourseSettings, mode, usesDefaultFieldCourseSettings)
	local v_u_14_ = AIUserSettingWorkDirection:superClass().init(self, settingData, fieldCourseSettings, mode, usesDefaultFieldCourseSettings)
	function v_u_14_.callback(_, _, p15_)
		-- upvalues: (ref) v_u_14_
		v_u_14_.value = v_u_14_.setting.textMapping[p15_]
		return true
	end
	if fieldCourseSettings == nil then
		v_u_14_.value = v_u_14_.loadedValue or -57.29577951308232
	else
		local v16_ = v_u_14_.loadedValue
		if not v16_ then
			local v17_ = fieldCourseSettings.workDirection
			v16_ = math.deg(v17_)
		end
		v_u_14_.value = v16_
	end
	v_u_14_.loadedValue = nil
	return v_u_14_
end

function AIUserSettingWorkDirection:apply(settingData, fieldCourseSettings, mode)
	if settingData.value == nil then
		fieldCourseSettings.workDirection = -1
	else
		local v20_ = settingData.value
		fieldCourseSettings.workDirection = math.rad(v20_)
	end
end

function AIUserSettingWorkDirection:registerXMLPath(schema, path)
	schema:register(XMLValueType.INT, string.format("%s#%s", path, self.identifier), self.title)
end
