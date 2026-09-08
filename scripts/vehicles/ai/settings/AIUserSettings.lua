-- Local values: AIUserSettings_mt
AIUserSettings = {}
local AIUserSettings_mt = Class(AIUserSettings)
source("dataS/scripts/vehicles/ai/settings/AIUserSetting.lua")
source("dataS/scripts/vehicles/ai/settings/AIUserSettingCruiseControl.lua")
source("dataS/scripts/vehicles/ai/settings/AIUserSettingHeadlandFirst.lua")
source("dataS/scripts/vehicles/ai/settings/AIUserSettingImplementWidth.lua")
source("dataS/scripts/vehicles/ai/settings/AIUserSettingNumHeadlands.lua")
source("dataS/scripts/vehicles/ai/settings/AIUserSettingShowLines.lua")
source("dataS/scripts/vehicles/ai/settings/AIUserSettingSideOffset.lua")
source("dataS/scripts/vehicles/ai/settings/AIUserSettingSkipNumLines.lua")
source("dataS/scripts/vehicles/ai/settings/AIUserSettingWorkDirection.lua")
source("dataS/scripts/vehicles/ai/settings/AIUserSettingWorkHeadlands.lua")
AIUserSettings.SETTINGS = {}
AIUserSettings.SETTINGS[AIModeSelection.MODE.WORKER] = {
	AIUserSettingImplementWidth.new(),
	AIUserSettingNumHeadlands.new(),
	AIUserSettingWorkDirection.new(),
	AIUserSettingWorkHeadlands.new(),
	AIUserSettingHeadlandFirst.new(),
	AIUserSettingSkipNumLines.new()
}
AIUserSettings.SETTINGS[AIModeSelection.MODE.STEERING_ASSIST] = {
	AIUserSettingImplementWidth.new(),
	AIUserSettingNumHeadlands.new(),
	AIUserSettingWorkDirection.new(),
	AIUserSettingSideOffset.new(),
	AIUserSettingShowLines.new(),
	AIUserSettingCruiseControl.new()
}

-- Upvalues: AIUserSettings_mt
-- Local values: self, mode, settings, settingIndex, setting
function AIUserSettings.new(fieldCourseSettings)
	-- upvalues: (copy) AIUserSettings_mt
	local v3_ = AIUserSettings_mt
	local v4_ = setmetatable({}, v3_)
	v4_.settings = {}
	for v5_, v6_ in pairs(AIUserSettings.SETTINGS) do
		v4_.settings[v5_] = {}
		for v7_, v8_ in ipairs(v6_) do
			v4_.settings[v5_][v7_] = v8_:init(nil, fieldCourseSettings, v5_, true)
		end
	end
	return v4_
end

-- Local values: mode, settings, settingIndex, settingData
function AIUserSettings:reinitialize(fieldCourseSettings, usesDefaultFieldCourseSettings)
	for v12_, v13_ in pairs(self.settings) do
		for v14_, v15_ in ipairs(v13_) do
			v13_[v14_] = v15_.setting:init(v15_, fieldCourseSettings, v12_, usesDefaultFieldCourseSettings)
		end
	end
end

-- Local values: settingMode, settings, settingIndex, settingData, settingIndex, settingData
function AIUserSettings:apply(fieldCourseSettings, mode)
	for v19_, v20_ in pairs(self.settings) do
		if v19_ ~= mode then
			for _, v21_ in ipairs(v20_) do
				v21_.setting:apply(v21_, fieldCourseSettings, mode)
			end
		end
	end
	for _, v22_ in ipairs(self.settings[mode]) do
		v22_.setting:apply(v22_, fieldCourseSettings, mode)
	end
end

-- Local values: settingIndex, settingData
function AIUserSettings:adjustToCourse(fieldCourse, mode)
	for _, v26_ in ipairs(self.settings[mode]) do
		if v26_.setting.adjustToCourse ~= nil then
			v26_.setting:adjustToCourse(v26_, fieldCourse, mode)
		end
	end
end

-- Local values: mode, settings, key, _, settingData
function AIUserSettings:loadFromXML(xmlFile, basePath)
	for v30_, v31_ in pairs(self.settings) do
		local v32_ = basePath .. string.format(".%s", string.lower(AIModeSelection.MODE.getName(v30_)))
		for _, v33_ in ipairs(v31_) do
			v33_.setting:loadFromXML(xmlFile, v32_, v33_)
		end
	end
end

-- Local values: mode, settings, key, _, settingData
function AIUserSettings:saveToXML(xmlFile, basePath)
	for v37_, v38_ in pairs(self.settings) do
		local v39_ = basePath .. string.format(".%s", string.lower(AIModeSelection.MODE.getName(v37_)))
		for _, v40_ in ipairs(v38_) do
			v40_.setting:saveToXML(xmlFile, v39_, v40_)
		end
	end
end

-- Local values: mode, settings, key, _, setting
function AIUserSettings.registerXMLPaths(schema, basePath)
	for v43_, v44_ in pairs(AIUserSettings.SETTINGS) do
		local v45_ = basePath .. string.format(".%s", string.lower(AIModeSelection.MODE.getName(v43_)))
		for _, v46_ in ipairs(v44_) do
			v46_:registerXMLPath(schema, v45_)
		end
	end
end
