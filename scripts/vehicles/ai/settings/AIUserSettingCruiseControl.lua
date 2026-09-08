-- Local values: AIUserSettingCruiseControl_mt
AIUserSettingCruiseControl = {}
local AIUserSettingCruiseControl_mt = Class(AIUserSettingCruiseControl, AIUserSetting)

-- Upvalues: AIUserSettingCruiseControl_mt
-- Local values: self
function AIUserSettingCruiseControl.new(customMt)
	-- upvalues: (copy) AIUserSettingCruiseControl_mt
	local v3_ = AIUserSetting.new(customMt or AIUserSettingCruiseControl_mt)
	v3_.identifier = "cruiseControl"
	v3_.title = g_i18n:getText("ai_settingCruiseControl")
	v3_.isVineyardSetting = true
	v3_.texts = {}
	local v4_ = v3_.texts
	local v5_ = g_i18n
	table.insert(v4_, v5_:getText("ai_settingManual"))
	local v6_ = v3_.texts
	local v7_ = g_i18n
	table.insert(v6_, v7_:getText("ai_settingAutomatic"))
	v3_.textMapping = {}
	v3_.textMapping[1] = false
	v3_.textMapping[2] = true
	return v3_
end

function AIUserSettingCruiseControl:init(settingData, fieldCourseSettings, mode, usesDefaultFieldCourseSettings)
	local v_u_13_ = AIUserSettingCruiseControl:superClass().init(self, settingData, fieldCourseSettings, mode, usesDefaultFieldCourseSettings)
	function v_u_13_.callback(_, p14_, _)
		-- upvalues: (ref) v_u_13_
		v_u_13_.value = p14_
		return false
	end
	v_u_13_.value = g_gameSettings:getValue(GameSettings.SETTING.STEERING_ASSIST_CRUISE_CONTROL)
	return v_u_13_
end

function AIUserSettingCruiseControl:apply(settingData, fieldCourseSettings, mode)
	g_gameSettings:setValue(GameSettings.SETTING.STEERING_ASSIST_CRUISE_CONTROL, settingData.value, true)
end

function AIUserSettingCruiseControl:registerXMLPath(schema, path)
	schema:register(XMLValueType.BOOL, string.format("%s#%s", path, self.identifier), self.title)
end
