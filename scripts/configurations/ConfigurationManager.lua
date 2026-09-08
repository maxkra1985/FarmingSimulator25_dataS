-- Local values: ConfigurationManager_mt
ConfigurationManager = {}
local ConfigurationManager_mt = Class(ConfigurationManager, AbstractManager)

-- Upvalues: ConfigurationManager_mt
-- Local values: self
function ConfigurationManager.new(typeName, rootElementName, customMt)
	-- upvalues: (copy) ConfigurationManager_mt
	local v5_ = AbstractManager.new(customMt or ConfigurationManager_mt)
	v5_.typeName = typeName
	v5_.rootElementName = rootElementName
	v5_:initDataStructures()
	return v5_
end

function ConfigurationManager:initDataStructures()
	self.configurations = {}
	self.intToConfigurationName = {}
	self.configurationNameToInt = {}
	self.sortedConfigurationNames = {}
end

-- Local values: entry
function ConfigurationManager:addConfigurationType(name, title, xmlKey, itemClass, subConfigurationTitle, getSubConfigurationValuesFunc, getItemsBySubConfigurationIdentifierFunc, priority)
	if self.configurations[name] == nil then
		if self:getNumOfConfigurationTypes() >= 2 ^ ConfigurationUtil.SEND_NUM_BITS then
			printError("Error: ConfigurationManager.addConfigurationType too many configuration types. Only " .. 2 ^ ConfigurationUtil.SEND_NUM_BITS .. " configuration types are supported")
			return
		elseif itemClass == nil then
			Logging.error("Missing \'itemClass\' for configuration \'%s\'. (\'addConfigurationType\' function arguments: name, title, xmlKey, itemClass, subConfigurationTitle, getSubConfigurationValuesFunc, getItemsBySubConfigurationIdentifierFunc, priority)", name)
			printCallstack()
		else
			local v16_ = {
				["name"] = name,
				["xmlKey"] = xmlKey,
				["title"] = title,
				["itemClass"] = itemClass,
				["subConfigurationTitle"] = subConfigurationTitle,
				["getSubConfigurationValuesFunc"] = getSubConfigurationValuesFunc,
				["getItemsBySubConfigurationIdentifierFunc"] = getItemsBySubConfigurationIdentifierFunc,
				["hasSubselection"] = getSubConfigurationValuesFunc ~= nil,
				["priority"] = priority or #self.intToConfigurationName + 1000
			}
			if v16_.xmlKey == nil then
				v16_.configurationsKey = string.format("%s.%sConfigurations", self.rootElementName, name)
			else
				v16_.configurationsKey = string.format("%s.%s.%sConfigurations", self.rootElementName, xmlKey, name)
			end
			v16_.configurationKey = string.format("%s.%sConfiguration", v16_.configurationsKey, name)
			self.configurations[name] = v16_
			local v17_ = self.intToConfigurationName
			table.insert(v17_, name)
			self.configurationNameToInt[name] = self:getNumOfConfigurationTypes()
			local v18_ = self.sortedConfigurationNames
			table.insert(v18_, name)
			table.sort(self.sortedConfigurationNames, function(p19_, p20_)
				-- upvalues: (copy) self
				return self.configurations[p19_].priority < self.configurations[p20_].priority
			end)
			print("  Register configuration \'" .. name .. "\'")
		end
	else
		printError("Error: configuration name \'" .. name .. "\' is already in use!")
		return
	end
end

function ConfigurationManager:getNumOfConfigurationTypes()
	return #self.intToConfigurationName
end

function ConfigurationManager:getConfigurationTypes()
	return self.intToConfigurationName
end

function ConfigurationManager:getSortedConfigurationTypes()
	return self.sortedConfigurationNames
end

function ConfigurationManager:getConfigurationNameByIndex(index)
	return self.intToConfigurationName[index]
end

function ConfigurationManager:getConfigurationIndexByName(name)
	return self.configurationNameToInt[name]
end

function ConfigurationManager:getConfigurations()
	return self.configurations
end

function ConfigurationManager:getConfigurationDescByName(name)
	return self.configurations[name]
end

-- Local values: config
function ConfigurationManager:getConfigurationAttribute(configurationName, attribute)
	return self:getConfigurationDescByName(configurationName)[attribute]
end

-- Local values: config
function ConfigurationManager:getConfigurationSelectorType(configurationName)
	local v36_ = self:getConfigurationDescByName(configurationName)
	if v36_ == nil then
		return ConfigurationUtil.SELECTOR_MULTIOPTION
	else
		return v36_.itemClass.SELECTOR
	end
end

-- Local values: config
function ConfigurationManager:getConfigurationKeys(configurationName)
	local v39_ = self:getConfigurationDescByName(configurationName)
	if v39_ == nil then
		return nil, nil
	else
		return v39_.configurationsKey, v39_.configurationKey
	end
end

-- Local values: currentIndex, numElements
function ConfigurationManager:configurationKeyIterator()
	local v_u_41_ = 0
	local v_u_42_ = #self.intToConfigurationName
	return function()
		-- upvalues: (ref) v_u_41_, (copy) v_u_42_, (copy) self
		if v_u_42_ <= v_u_41_ then
			return nil
		end
		v_u_41_ = v_u_41_ + 1
		local v43_, v44_ = self:getConfigurationKeys(self.intToConfigurationName[v_u_41_])
		return v43_, v44_ .. "(?)"
	end
end
g_vehicleConfigurationManager = ConfigurationManager.new("vehicle", "vehicle")
g_placeableConfigurationManager = ConfigurationManager.new("placeable", "placeable")
g_configurationManager = {
	["addConfigurationType"] = function()
		Logging.error("g_configurationManager is not available anymore. Please adjust mod script to use new g_vehicleConfigurationManager and VehicleConfigurationItems instead")
	end,
	["getConfigurationDescByName"] = function()
		Logging.error("g_configurationManager is not available anymore. Please adjust mod script to use new g_vehicleConfigurationManager and VehicleConfigurationItems instead")
		return nil
	end,
	["configurations"] = {}
}
