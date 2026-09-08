PlaceableConfigurationDataObjectChange = {}

function PlaceableConfigurationDataObjectChange.registerXMLPaths(schema, rootPath, configPath)
	schema:register(XMLValueType.BOOL, rootPath .. "#postLoadObjectChange", "Defines if the object changes are applied before or after post load", false)
	ObjectChangeUtil.registerObjectChangeXMLPaths(schema, configPath)
end

function PlaceableConfigurationDataObjectChange.loadConfigItem(configItem, xmlFile, baseKey, configKey, baseDirectory, customEnvironment)
	configItem.postLoadObjectChange = xmlFile:getValue(baseKey .. "#postLoadObjectChange", false)
end

-- Local values: configurationDesc
function PlaceableConfigurationDataObjectChange.onLoad(placeable, configItem, configId)
	if not configItem.postLoadObjectChange then
		local v10_ = g_placeableConfigurationManager:getConfigurationDescByName(configItem.configName)
		ObjectChangeUtil.updateObjectChanges(placeable.xmlFile, v10_.configurationKey, configId, placeable.components, placeable)
	end
end

-- Local values: configurationDesc
function PlaceableConfigurationDataObjectChange.onPostLoad(placeable, configItem, configId)
	if configItem.postLoadObjectChange then
		local v14_ = g_placeableConfigurationManager:getConfigurationDescByName(configItem.configName)
		ObjectChangeUtil.updateObjectChanges(placeable.xmlFile, v14_.configurationKey, configId, placeable.components, placeable)
	end
end
PlaceableConfigurationItem.registerGlobalConfigurationData(PlaceableConfigurationDataObjectChange)
