VehicleConfigurationDataDependentConfig = {}

function VehicleConfigurationDataDependentConfig.registerXMLPaths(schema, rootPath, configPath)
	schema:register(XMLValueType.STRING, configPath .. ".dependentConfiguration(?)#name", "Name of the other configuration to set")
	schema:register(XMLValueType.INT, configPath .. ".dependentConfiguration(?)#index", "Index of the configuration to use")
end

-- Local values: _, key, dependentConfiguration
function VehicleConfigurationDataDependentConfig.loadConfigItem(configItem, xmlFile, baseKey, configKey, baseDirectory, customEnvironment)
	configItem.dependentConfigurations = {}
	for _, v6_ in xmlFile:iterator(configKey .. ".dependentConfiguration") do
		local v7_ = {
			["name"] = xmlFile:getValue(v6_ .. "#name"),
			["index"] = xmlFile:getValue(v6_ .. "#index")
		}
		if v7_.name ~= nil and v7_.index ~= nil then
			local v8_ = configItem.dependentConfigurations
			table.insert(v8_, v7_)
		end
	end
end
VehicleConfigurationItem.registerGlobalConfigurationData(VehicleConfigurationDataDependentConfig)
