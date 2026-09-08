VehicleConfigurationDataObjectChange = {}

function VehicleConfigurationDataObjectChange.registerXMLPaths(schema, rootPath, configPath)
	schema:register(XMLValueType.BOOL, rootPath .. "#postLoadObjectChange", "Defines if the object changes are applied before or after post load (can be helpful if you manipulate wheel nodes, which is only possible before postLoad)", false)
	ObjectChangeUtil.registerObjectChangeXMLPaths(schema, configPath)
end

function VehicleConfigurationDataObjectChange.loadConfigItem(configItem, xmlFile, baseKey, configKey, baseDirectory, customEnvironment)
	configItem.postLoadObjectChange = xmlFile:getValue(baseKey .. "#postLoadObjectChange", false)
end

-- Local values: configurationDesc
function VehicleConfigurationDataObjectChange.onLoad(vehicle, configItem, configId)
	if not configItem.postLoadObjectChange then
		local v10_ = g_vehicleConfigurationManager:getConfigurationDescByName(configItem.configName)
		ObjectChangeUtil.updateObjectChanges(vehicle.xmlFile, v10_.configurationKey, configId, vehicle.components, vehicle)
	end
end

-- Local values: configurationDesc
function VehicleConfigurationDataObjectChange.onPostLoad(vehicle, configItem, configId)
	if configItem.postLoadObjectChange then
		local v14_ = g_vehicleConfigurationManager:getConfigurationDescByName(configItem.configName)
		ObjectChangeUtil.updateObjectChanges(vehicle.xmlFile, v14_.configurationKey, configId, vehicle.components, vehicle)
	end
end
VehicleConfigurationItem.registerGlobalConfigurationData(VehicleConfigurationDataObjectChange)
