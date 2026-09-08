-- Local values: AIUserSetting_mt
AIUserSetting = {}
local AIUserSetting_mt = Class(AIUserSetting)

-- Upvalues: AIUserSetting_mt
-- Local values: self
function AIUserSetting.new(customMt)
	-- upvalues: (copy) AIUserSetting_mt
	local v3_ = customMt or AIUserSetting_mt
	local v4_ = setmetatable({}, v3_)
	v4_.unitText = nil
	v4_.defaultPostFix = nil
	v4_.isVineyardSetting = false
	return v4_
end

function AIUserSetting:getIsDisabled(settings)
	return false
end

function AIUserSetting:init(settingData, fieldCourseSettings, mode, usesDefaultFieldCourseSettings)
	if settingData == nil then
		local v_u_10_ = {
			["setting"] = self,
			["callback"] = function(_, p7_, _)
				-- upvalues: (ref) v_u_10_
				v_u_10_.value = p7_
				if type(p7_) == "string" then
					local v8_ = v_u_10_
					local v9_ = string.split(p7_, " ")[1]
					v8_.value = tonumber(v9_)
				end
				return true
			end
		}
		v_u_10_.target = v_u_10_
		settingData = v_u_10_
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
