AIUserSetting = {}
local AIUserSetting_mt = Class(AIUserSetting)
function AIUserSetting.new(customMt)
	local self = setmetatable({}, customMt or AIUserSetting_mt)
	self.unitText = nil
	self.defaultPostFix = nil
	self.isVineyardSetting = false
	return self
end
function AIUserSetting:getIsDisabled(settings)
	return false
end
function AIUserSetting:init(settingData, fieldCourseSettings, mode, usesDefaultFieldCourseSettings)
	if settingData == nil then
		settingData = {}
		settingData.setting = self
		function settingData.callback(_, value, index)
			settingData.value = value
			if type(value) == "string" then
				settingData.value = tonumber(string.split(value, " ")[1])
			end
			return true
		end
		settingData.target = settingData
	end
	return settingData
end
function AIUserSetting:apply(settingData, fieldCourseSettings, mode) end
function AIUserSetting:onSettingsChanged(settingData, otherSettings)
	return false
end
function AIUserSetting:loadFromXML(xmlFile, key, settingData)
	settingData.loadedValue = xmlFile:getValue(string.format("%s#%s", key, self.identifier), settingData.value)
end
function AIUserSetting:saveToXML(xmlFile, key, settingData)
	xmlFile:setValue(string.format("%s#%s", key, self.identifier), settingData.value)
end
function AIUserSetting:registerXMLPath(schema, path)
	schema:register(XMLValueType.FLOAT, string.format("%s#%s", path, self.identifier), self.title)
end
