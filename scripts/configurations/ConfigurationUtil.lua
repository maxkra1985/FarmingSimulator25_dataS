ConfigurationUtil = {}
ConfigurationUtil.SEND_NUM_BITS = 7
ConfigurationUtil.SELECTOR_MULTIOPTION = 0
ConfigurationUtil.SELECTOR_COLOR = 1
function ConfigurationUtil.addBoughtConfiguration(manager, object, name, id)
	if manager:getConfigurationIndexByName(name) ~= nil then
		if object.boughtConfigurations[name] == nil then
			object.boughtConfigurations[name] = {}
		end
		object.boughtConfigurations[name][id] = true
	end
end
function ConfigurationUtil.hasBoughtConfiguration(object, name, id)
	if object.boughtConfigurations[name] ~= nil and object.boughtConfigurations[name][id] then
		return true
	end
	return false
end
function ConfigurationUtil.setConfiguration(object, name, id)
	object.configurations[name] = id
end
function ConfigurationUtil.getColorByConfigId(object, configName, configId)
	if configId ~= nil then
		local item = g_storeManager:getItemByXMLFilename(object.configFileName)
		if item.configurations ~= nil then
			local config = item.configurations[configName][configId]
			if config ~= nil and config:isa(VehicleConfigurationItemColor) then
				return config:getColor()
			end
		end
	end
	return nil
end
function ConfigurationUtil.getConfigItemByConfigId(configFileName, configName, configId)
	if configId ~= nil then
		local item = g_storeManager:getItemByXMLFilename(configFileName)
		if item.configurations ~= nil then
			local configItems = item.configurations[configName]
			if configItems ~= nil and configItems[configId] ~= nil then
				return configItems[configId]
			end
		end
	end
	return nil
end
function ConfigurationUtil.raiseConfigurationItemEvent(object, eventName)
	local item = g_storeManager:getItemByXMLFilename(object.configFileName)
	if item.configurations ~= nil and object.sortedConfigurationNames ~= nil then
		for _, configName in ipairs(object.sortedConfigurationNames) do
			local configItems = item.configurations[configName]
			if configItems == nil then
				continue
			end
			local configId = object.configurations[configName]
			local configItem = configItems[configId]
			if configItem == nil or configItem[eventName] == nil then
				continue
			end
			configItem[eventName](configItem, object, configId)
		end
	end
end
function ConfigurationUtil.getSaveIdByConfigId(configFileName, configName, configId)
	local item = g_storeManager:getItemByXMLFilename(configFileName)
	if item.configurations ~= nil then
		local configs = item.configurations[configName]
		if configs ~= nil then
			local config = configs[configId]
			if config ~= nil then
				return config.saveId
			end
		end
	end
	return nil
end
function ConfigurationUtil.saveConfigurationToXMLFile(itemConfigurations, configName, configId, xmlFile, key, isActive, configurationData, xmlIndex)
	local configKey = string.format("%s(%d)", key, xmlIndex)
	local configurationItems = itemConfigurations[configName]
	if configurationItems ~= nil then
		local configurationItem = configurationItems[configId]
		if configurationItem ~= nil then
			local data = configurationData[configName]
			if data ~= nil then
				configurationItem:saveToXMLFile(xmlFile, configKey, isActive, data[configId])
				xmlIndex = xmlIndex + 1
				return xmlIndex
			end
			configurationItem:saveToXMLFile(xmlFile, configKey, isActive)
			xmlIndex = xmlIndex + 1
		end
	end
	return xmlIndex
end
function ConfigurationUtil.saveConfigurationsToXMLFile(configFileName, xmlFile, key, configurations, boughtConfigurations, configurationData)
	local item = g_storeManager:getItemByXMLFilename(configFileName)
	if item.configurations ~= nil then
		local xmlIndex = 0
		for configName, configsToSave in pairs(boughtConfigurations) do
			for index, _ in pairs(configsToSave) do
				local isActive = configurations[configName] == index
				xmlIndex = ConfigurationUtil.saveConfigurationToXMLFile(item.configurations, configName, index, xmlFile, key, isActive, configurationData, xmlIndex)
			end
		end
	end
end
function ConfigurationUtil.loadConfigurationsFromXMLFile(configFileName, xmlFile, key)
	local configurations = {}
	local boughtConfigurations = {}
	local configurationData = {}
	local item = g_storeManager:getItemByXMLFilename(configFileName)
	if item.configurations ~= nil then
		for _, configKey in xmlFile:iterator(key) do
			local configName = xmlFile:getValue(configKey .. "#name")
			local configId = xmlFile:getValue(configKey .. "#id")
			local isActive = xmlFile:getValue(configKey .. "#isActive", true)
			local configurationItems = item.configurations[configName]
			if configurationItems == nil then
				continue
			end
			local configurationItem = nil
			for j = 1, #configurationItems do
				if configurationItems[j].saveId == configId then
					configurationItem = configurationItems[j]
				end
			end
			if configurationItem == nil then
				local configItemClass = ClassUtil.getClassObjectByObject(configurationItems[1])
				if configItemClass ~= nil and configItemClass.getFallbackConfigId ~= nil then
					local fallbackIndex, fallbackSaveId = configItemClass.getFallbackConfigId(configurationItems, configId, configName, configFileName)
					if fallbackIndex ~= nil then
						Logging.info("Unable to find %s configuration '%s' for object '%s'. Using config '%s' as closest match instead.", configName, configId, configFileName, fallbackSaveId)
						configurationItem = configurationItems[fallbackIndex]
					end
				end
			end
			if configurationItem == nil then
				for j = 1, #configurationItems do
					if configurationItems[j].isSelectable ~= false then
						Logging.info("Unable to find %s configuration '%s' for object '%s'. Using config '%s' instead.", configName, configId, configFileName, configurationItems[j].saveId)
						configurationItem = configurationItems[j]
						break
					end
				end
			end
			if configurationItem == nil then
				continue
			end
			if boughtConfigurations[configName] == nil then
				boughtConfigurations[configName] = {}
			end
			boughtConfigurations[configName][configurationItem.index] = true
			if isActive then
				configurations[configName] = configurationItem.index
			end
			if configurationData[configName] == nil then
				configurationData[configName] = {}
			end
			if configurationData[configName][configurationItem.index] == nil then
				configurationData[configName][configurationItem.index] = {}
			end
			configurationItem:loadFromSavegameXMLFile(xmlFile, configKey, configurationData[configName][configurationItem.index])
		end
	end
	return configurations, boughtConfigurations, configurationData
end
function ConfigurationUtil.readConfigurationsFromStream(manager, streamId, connection, configFileName)
	local configurations = {}
	local boughtConfigurations = {}
	local configurationData = {}
	local numConfigs = streamReadUIntN(streamId, ConfigurationUtil.SEND_NUM_BITS)
	for _ = 1, numConfigs do
		local configNameId = streamReadUIntN(streamId, ConfigurationUtil.SEND_NUM_BITS)
		local configName = manager:getConfigurationNameByIndex(configNameId + 1)
		boughtConfigurations[configName] = {}
		local numConfigIds = streamReadUInt16(streamId)
		for _ = 1, numConfigIds do
			local configId = streamReadUInt16(streamId) + 1
			boughtConfigurations[configName][configId] = true
			if streamReadBool(streamId) then
				configurations[configName] = configId
			end
			if streamReadBool(streamId) then
				local configItem = ConfigurationUtil.getConfigItemByConfigId(configFileName, configName, configId)
				if configItem ~= nil then
					if configurationData[configName] == nil then
						configurationData[configName] = {}
					end
					if configurationData[configName][configId] == nil then
						configurationData[configName][configId] = {}
					end
					configItem:readFromStream(streamId, connection, configurationData[configName][configId])
				else
					Logging.error("Unable to find configuration item for %s configuration '%s' with id %d on client side!", configFileName, configName, configId)
				end
			end
		end
	end
	return configurations, boughtConfigurations, configurationData
end
function ConfigurationUtil.writeConfigurationsToStream(manager, streamId, connection, configFileName, configurations, boughtConfigurations, configurationData)
	streamWriteUIntN(streamId, table.size(boughtConfigurations), ConfigurationUtil.SEND_NUM_BITS)
	for configName, configIds in pairs(boughtConfigurations) do
		local configNameId = manager:getConfigurationIndexByName(configName)
		streamWriteUIntN(streamId, configNameId - 1, ConfigurationUtil.SEND_NUM_BITS)
		streamWriteUInt16(streamId, table.size(configIds))
		for configId, _ in pairs(configIds) do
			streamWriteUInt16(streamId, configId - 1)
			streamWriteBool(streamId, configurations[configName] == configId)
			local configItem = ConfigurationUtil.getConfigItemByConfigId(configFileName, configName, configId)
			if streamWriteBool(streamId, configItem ~= nil and configItem.writeToStream ~= nil) then
				local data = configurationData[configName]
				if data ~= nil then
					configItem:writeToStream(streamId, connection, data[configId])
				else
					configItem:writeToStream(streamId, connection)
				end
			end
		end
	end
end
function ConfigurationUtil.getConfigurationDataHasChanged(configFileName, configurationData1, configurationData2)
	if configurationData1 == nil and configurationData2 == nil then
		return false
	end
	if configurationData1 == nil or configurationData2 == nil then
		return true
	end
	for configName, data in pairs(configurationData1) do
		if configurationData2[configName] == nil then
			return true
		end
		for configId, configData in pairs(data) do
			if configurationData2[configName][configId] == nil then
				return true
			end
			local configItem = ConfigurationUtil.getConfigItemByConfigId(configFileName, configName, configId)
			if configItem.hasDataChanged == nil then
				continue
			end
			if configItem:hasDataChanged(configData, configurationData2[configName][configId]) then
				return true
			end
		end
	end
	return false
end
function ConfigurationUtil.getConfigIdBySaveId(configFileName, configName, configId)
	local item = g_storeManager:getItemByXMLFilename(configFileName)
	if item.configurations ~= nil then
		local configs = item.configurations[configName]
		if configs ~= nil then
			for j = 1, #configs do
				if configs[j].saveId == configId then
					return configs[j].index
				end
			end
			local configItemClass = ClassUtil.getClassObjectByObject(configs[1])
			if configItemClass ~= nil and configItemClass.getFallbackConfigId ~= nil then
				local fallbackIndex, fallbackSaveId = configItemClass.getFallbackConfigId(configs, configId, configName, configFileName)
				if fallbackIndex ~= nil then
					Logging.info("Unable to find %s configuration '%s' for object '%s'. Using config '%s' as closest match instead.", configName, configId, configFileName, fallbackSaveId)
					return fallbackIndex
				end
			end
			for j = 1, #configs do
				if configs[j].isSelectable == false then
					continue
				end
				Logging.info("Unable to find %s configuration '%s' for object '%s'. Using config '%s' instead.", configName, configId, configFileName, configs[j].saveId)
				return configs[j].index
			end
		end
	end
	return 1
end
function ConfigurationUtil.getConfigurationValue(xmlFile, key, subKey, param, defaultValue, fallbackConfigKey, fallbackOldKey)
	if type(subKey) == "table" then
		printCallstack()
	end
	local value = nil
	if key ~= nil then
		value = xmlFile:getValue(key .. subKey .. param)
	end
	if value == nil and fallbackConfigKey ~= nil then
		value = xmlFile:getValue(fallbackConfigKey .. subKey .. param)
	end
	if value == nil and fallbackOldKey ~= nil then
		value = xmlFile:getValue(fallbackOldKey .. subKey .. param)
	end
	return Utils.getNoNil(value, defaultValue)
end
function ConfigurationUtil.getXMLConfigurationKey(xmlFile, index, key, defaultKey, configurationKey)
	local configIndex = Utils.getNoNil(index, 1)
	local configKey = string.format(key .. "(%d)", configIndex - 1)
	if index ~= nil and not xmlFile:hasProperty(configKey) then
		printWarning("Warning: Invalid " .. configurationKey .. " index '" .. tostring(index) .. "' in '" .. key .. "'. Using default " .. configurationKey .. " settings instead!")
	end
	if not xmlFile:hasProperty(configKey) then
		configKey = key .. "(0)"
	end
	if not xmlFile:hasProperty(configKey) then
		configKey = defaultKey
	end
	return configKey, configIndex
end
function ConfigurationUtil.getConfigurationsFromXML(manager, xmlFile, key, baseDir, customEnvironment, isMod, storeItem)
	local configurations = {}
	local defaultConfigurationIds = {}
	local numConfigs = 0
	local configurationDescs = manager:getConfigurations()
	for _, configurationDesc in pairs(configurationDescs) do
		local configurationItems = {}
		if configurationDesc.itemClass.preLoad ~= nil then
			configurationDesc.itemClass.preLoad(xmlFile, configurationDesc.configurationsKey, baseDir, customEnvironment, isMod, configurationItems)
		end
		local i = 0
		while 2 ^ ConfigurationUtil.SEND_NUM_BITS < i do
			Logging.xmlWarning(xmlFile, "Maximum number of configurations are reached for %s. Only %d configurations per type are allowed!", configurationDesc.name, 2 ^ ConfigurationUtil.SEND_NUM_BITS)
			break
		end
		while true do
			local configKey = string.format(configurationDesc.configurationKey .. "(%d)", i)
			if not xmlFile:hasProperty(configKey) then
				break
			end
			local configItem = configurationDesc.itemClass.new(configurationDesc.name)
			configItem:setIndex(#configurationItems + 1)
			if configItem:loadFromXML(xmlFile, configurationDesc.configurationsKey, configKey, baseDir, customEnvironment) then
				table.insert(configurationItems, configItem)
			end
			i = i + 1
		end
		if configurationDesc.itemClass.postLoad ~= nil then
			configurationDesc.itemClass.postLoad(xmlFile, configurationDesc.configurationsKey, baseDir, customEnvironment, isMod, configurationItems, storeItem, configurationDesc.name)
		end
		if 0 < #configurationItems then
			defaultConfigurationIds[configurationDesc.name] = ConfigurationUtil.getDefaultConfigIdFromItems(configurationItems)
			configurations[configurationDesc.name] = configurationItems
			numConfigs = numConfigs + 1
		end
	end
	if numConfigs == 0 then
		return nil, nil
	else
		return configurations, defaultConfigurationIds
	end
end
function ConfigurationUtil.getConfigurationSetsFromXML(storeItem, xmlFile, key, baseDir, customEnvironment, isMod)
	local configurationSetsKey = string.format("%s.configurationSets", key)
	local overwrittenTitle = xmlFile:getValue(configurationSetsKey .. "#title", nil, customEnvironment, false)
	local isYesNoOption = xmlFile:getValue(configurationSetsKey .. "#isYesNoOption", false)
	local configurationsSets = {}
	local i = 0
	while true do
		local configSetKey = string.format("%s.configurationSet(%d)", configurationSetsKey, i)
		if not xmlFile:hasProperty(configSetKey) then
			break
		end
		local configSet = {}
		configSet.name = xmlFile:getValue(configSetKey .. "#name", nil, customEnvironment, false)
		local params = xmlFile:getValue(configSetKey .. "#params")
		if params ~= nil then
			configSet.name = g_i18n:insertTextParams(configSet.name, params, customEnvironment, xmlFile)
		end
		configSet.isDefault = xmlFile:getValue(configSetKey .. "#isDefault", false)
		configSet.overwrittenTitle = overwrittenTitle
		configSet.isYesNoOption = isYesNoOption
		configSet.configurations = {}
		local j = 0
		while true do
			local configKey = string.format("%s.configuration(%d)", configSetKey, j)
			if not xmlFile:hasProperty(configKey) then
				break
			end
			local name = xmlFile:getValue(configKey .. "#name")
			if name ~= nil then
				if storeItem.configurations[name] ~= nil then
					local index = xmlFile:getValue(configKey .. "#index")
					if index ~= nil then
						if storeItem.configurations[name][index] ~= nil then
							configSet.configurations[name] = index
						else
							Logging.xmlWarning(xmlFile, "Index '%d' not defined for configuration '%s'!", index, name)
						end
					end
				elseif xmlFile:getValue(configKey .. "#showWarning", true) then
					Logging.xmlWarning(xmlFile, "Configuration name '%s' is not defined!", name)
				end
			else
				Logging.xmlWarning(xmlFile, "Missing name for configuration set item '%s'!", configSetKey)
			end
			j = j + 1
		end
		table.insert(configurationsSets, configSet)
		configSet.index = #configurationsSets
		i = i + 1
	end
	return configurationsSets
end
function ConfigurationUtil.getSubConfigurationsFromConfigurations(manager, configurations)
	local subConfigurations = nil
	if configurations ~= nil then
		subConfigurations = {}
		for name, items in pairs(configurations) do
			local config = manager:getConfigurationDescByName(name)
			if config.hasSubselection then
				local subConfigValues = config.getSubConfigurationValuesFunc(items)
				if 1 < #subConfigValues then
					local subConfigItemMapping = {}
					subConfigurations[name] = { subConfigValues = subConfigValues, subConfigItemMapping = subConfigItemMapping }
					for k, value in ipairs(subConfigValues) do
						subConfigItemMapping[value] = config.getItemsBySubConfigurationIdentifierFunc(items, value)
					end
				end
			end
		end
	end
	return subConfigurations
end
function ConfigurationUtil.getDefaultConfigIdFromItems(configItems)
	if configItems ~= nil then
		for k, item in pairs(configItems) do
			if item.isDefault then
				if item.isSelectable == false then
					continue
				end
				return k
			end
		end
		for k, item in pairs(configItems) do
			if item.isSelectable == false then
				continue
			end
			return k
		end
	end
	return 1
end
function ConfigurationUtil.getConfigurationsMatchConfigSets(configurations, configSets)
	for _, configSet in pairs(configSets) do
		local isMatch = true
		for configName, index in pairs(configSet.configurations) do
			if configurations[configName] ~= index then
				isMatch = false
				break
			end
		end
		if isMatch then
			return true
		end
	end
	return false
end
function ConfigurationUtil.getClosestConfigurationSet(configurations, configSets)
	local closestSet = nil
	local closestSetMatches = 0
	for _, configSet in pairs(configSets) do
		local numMatches = 0
		for configName, index in pairs(configSet.configurations) do
			if configurations[configName] == index then
				numMatches = numMatches + 1
			end
		end
		if closestSetMatches < numMatches then
			closestSet = configSet
			closestSetMatches = numMatches
		end
	end
	return closestSet, closestSetMatches
end
function ConfigurationUtil.isColorMetallic(materialId)
	return materialId == 2 or materialId == 3 or materialId == 19 or materialId == 30 or materialId == 31 or materialId == 35
end
function ConfigurationUtil.registerColorConfigurationXMLPaths()
	Logging.error("ConfigurationUtil.registerColorConfigurationXMLPaths is not available anymore")
end
