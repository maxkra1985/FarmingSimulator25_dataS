StoreItemUtil = {}
function StoreItemUtil.getIsVehicle(storeItem)
	return storeItem ~= nil and storeItem.species == StoreSpecies.VEHICLE
end
function StoreItemUtil.getIsAnimal(storeItem)
	return storeItem ~= nil and storeItem.species == StoreSpecies.ANIMAL
end
function StoreItemUtil.getIsPlaceable(storeItem)
	return storeItem ~= nil and storeItem.species == StoreSpecies.PLACEABLE
end
function StoreItemUtil.getIsObject(storeItem)
	return storeItem ~= nil and storeItem.species == StoreSpecies.OBJECT
end
function StoreItemUtil.getIsHandTool(storeItem)
	return storeItem ~= nil and storeItem.species == StoreSpecies.HANDTOOL
end
function StoreItemUtil.getIsConfigurable(storeItem)
	local hasConfigurations = storeItem ~= nil and storeItem.configurations ~= nil
	local hasMoreThanOneOption = false
	if hasConfigurations then
		for _, configItems in pairs(storeItem.configurations) do
			local selectableItems = 0
			for i = 1, #configItems do
				if configItems[i].isSelectable == false then
					continue
				end
				selectableItems = selectableItems + 1
				if 1 < selectableItems then
					hasMoreThanOneOption = true
					break
				end
			end
			if not hasMoreThanOneOption then
				continue
			end
			return hasConfigurations and hasMoreThanOneOption
		end
	end
end
function StoreItemUtil.getCanBeShownInConfigScreen(storeItem)
	local isHandTool = StoreItemUtil.getIsHandTool(storeItem)
	return not isHandTool
end
function StoreItemUtil.getIsLeasable(storeItem)
	return false
end
function StoreItemUtil.getDefaultConfigId(storeItem, configurationName)
	return ConfigurationUtil.getDefaultConfigIdFromItems(storeItem.configurations[configurationName])
end
function StoreItemUtil.getDefaultPrice(storeItem, configurations)
	return StoreItemUtil.getCosts(storeItem, configurations, "price")
end
function StoreItemUtil.getDailyUpkeep(storeItem, configurations)
	return StoreItemUtil.getCosts(storeItem, configurations, "dailyUpkeep")
end
function StoreItemUtil.getCosts(storeItem, configurations, costType)
	if storeItem ~= nil then
		local costs = storeItem[costType]
		if costs == nil then
			costs = 0
		end
		if storeItem.configurations ~= nil then
			for name, value in pairs(configurations) do
				local nameConfig = storeItem.configurations[name]
				if nameConfig == nil then
					continue
				end
				local valueConfig = nameConfig[value]
				if valueConfig == nil then
					continue
				end
				local costTypeConfig = valueConfig[costType]
				if costTypeConfig == nil then
					continue
				end
				costs = costs + tonumber(costTypeConfig)
			end
		end
		return costs
	else
		return 0
	end
end
function StoreItemUtil.getPriceWithBoughtConfigurations(storeItem, boughtConfigurations, costType)
	if storeItem ~= nil then
		local costs = storeItem[costType]
		if costs == nil then
			costs = 0
		end
		if storeItem.configurations ~= nil then
			for name, values in pairs(boughtConfigurations) do
				for value, check in pairs(values) do
					if check then
						local nameConfig = storeItem.configurations[name]
						if nameConfig == nil then
							continue
						end
						local valueConfig = nameConfig[value]
						if valueConfig == nil then
							continue
						end
						local costTypeConfig = valueConfig[costType]
						if costTypeConfig == nil then
							continue
						end
						costs = costs + tonumber(costTypeConfig)
					end
				end
			end
		end
		return costs
	else
		return 0
	end
end
function StoreItemUtil.getFunctionsFromXML(xmlFile, storeDataXMLName, customEnvironment)
	local functions = nil
	for functionIndex, functionKey in xmlFile:iterator(storeDataXMLName .. ".functions.function") do
		local functionName = xmlFile:getValue(functionKey, nil, customEnvironment, true)
		if functionName == nil then
			continue
		end
		functions = functions or {}
		table.insert(functions, functionName)
	end
	return functions
end
function StoreItemUtil.loadSpecsFromXML(item)
	if item.specs == nil then
		local storeItemXmlFile = XMLFile.load("storeItemXML", item.xmlFilename, item.xmlSchema)
		if storeItemXmlFile ~= nil then
			item.specs = StoreItemUtil.getSpecsFromXML(g_storeManager:getSpecTypes(), item.species, storeItemXmlFile, item.customEnvironment, item.baseDir)
			storeItemXmlFile:delete()
		end
	end
	if item.bundleInfo ~= nil then
		local bundleItems = item.bundleInfo.bundleItems
		for i = 1, #bundleItems do
			StoreItemUtil.loadSpecsFromXML(bundleItems[i].item)
		end
	end
end
function StoreItemUtil.getSpecsFromXML(specTypes, species, xmlFile, customEnvironment, baseDirectory)
	local specs = {}
	for _, specType in ipairs(specTypes) do
		if specType.species == species then
			if specType.loadFunc == nil then
				continue
			end
			specs[specType.name] = specType.loadFunc(xmlFile, customEnvironment, baseDirectory)
		end
	end
	return specs
end
function StoreItemUtil.getBrandIndexFromXML(xmlFile, storeDataXMLKey)
	local brandName = xmlFile:getValue(storeDataXMLKey .. ".brand", "")
	return g_brandManager:getBrandIndexByName(brandName)
end
function StoreItemUtil.getVRamUsageFromXML(xmlFile, storeDataXMLName)
	local vertexBufferMemoryUsage = xmlFile:getValue(storeDataXMLName .. ".vertexBufferMemoryUsage", 0)
	local indexBufferMemoryUsage = xmlFile:getValue(storeDataXMLName .. ".indexBufferMemoryUsage", 0)
	local textureMemoryUsage = xmlFile:getValue(storeDataXMLName .. ".textureMemoryUsage", 0)
	local instanceVertexBufferMemoryUsage = xmlFile:getValue(storeDataXMLName .. ".instanceVertexBufferMemoryUsage", 0)
	local instanceIndexBufferMemoryUsage = xmlFile:getValue(storeDataXMLName .. ".instanceIndexBufferMemoryUsage", 0)
	local ignoreVramUsage = xmlFile:getValue(storeDataXMLName .. ".ignoreVramUsage", false)
	local perInstanceVramUsage = instanceVertexBufferMemoryUsage + instanceIndexBufferMemoryUsage
	local sharedVramUsage = vertexBufferMemoryUsage + indexBufferMemoryUsage + textureMemoryUsage
	return sharedVramUsage, perInstanceVramUsage, ignoreVramUsage
end
function StoreItemUtil.getSubConfigurationIndex(storeItem, configName, configIndex)
	local subConfigurations = storeItem.subConfigurations[configName]
	local subConfigValues = subConfigurations.subConfigValues
	for k, identifier in ipairs(subConfigValues) do
		local items = subConfigurations.subConfigItemMapping[identifier]
		for _, item in ipairs(items) do
			if item.index == configIndex then
				return k
			end
		end
	end
	return nil
end
function StoreItemUtil.getSubConfigurationItems(storeItem, configName, state)
	local subConfigurations = storeItem.subConfigurations[configName]
	local subConfigValues = subConfigurations.subConfigValues
	local identifier = subConfigValues[state]
	return subConfigurations.subConfigItemMapping[identifier]
end
function StoreItemUtil.getSizeValues(xmlFilename, baseName, rotationOffset, configurations)
	local xmlFile = XMLFile.load("storeItemGetSizeXml", xmlFilename, Vehicle.xmlSchema)
	local size = { width = Vehicle.defaultWidth, length = Vehicle.defaultLength, height = Vehicle.defaultHeight, widthOffset = 0, lengthOffset = 0, heightOffset = 0 }
	if xmlFile ~= nil then
		size = StoreItemUtil.getSizeValuesFromXML(xmlFilename, xmlFile, baseName, rotationOffset, configurations)
		xmlFile:delete()
	end
	return size
end
function StoreItemUtil.getSizeValuesFromXML(xmlFilename, xmlFile, baseName, rotationOffset, configurations)
	return StoreItemUtil.getSizeValuesFromXMLByKey(xmlFilename, xmlFile, baseName, "base", "size", "size", rotationOffset, configurations, Vehicle.DEFAULT_SIZE)
end
function StoreItemUtil.getSizeValuesFromXMLByKey(xmlFilename, xmlFile, baseName, baseKey, elementKey, configKey, rotationOffset, configurations, defaults)
	local baseSizeKey = string.format("%s.%s.%s", baseName, baseKey, elementKey)
	local size = {}
	size.width = xmlFile:getValue(baseSizeKey .. "#width", defaults.width)
	size.length = xmlFile:getValue(baseSizeKey .. "#length", defaults.length)
	size.height = xmlFile:getValue(baseSizeKey .. "#height", defaults.height)
	size.widthOffset = xmlFile:getValue(baseSizeKey .. "#widthOffset", defaults.widthOffset)
	size.lengthOffset = xmlFile:getValue(baseSizeKey .. "#lengthOffset", defaults.lengthOffset)
	size.heightOffset = xmlFile:getValue(baseSizeKey .. "#heightOffset", defaults.heightOffset)
	if configurations ~= nil then
		for name, id in pairs(configurations) do
			local configItem = ConfigurationUtil.getConfigItemByConfigId(xmlFilename, name, id)
			if configItem == nil or configItem.onSizeLoad == nil then
				continue
			end
			configItem.onSizeLoad(configItem, xmlFile, size)
		end
		if size.minWidth ~= nil then
			size.width = math.max(size.width, size.minWidth)
		end
		if size.minLength ~= nil then
			size.length = math.max(size.length, size.minLength)
		end
		if size.minHeight ~= nil then
			size.height = math.max(size.height, size.minHeight)
		end
	end
	rotationOffset = math.floor(rotationOffset / 1.5707963267948966 + 0.5) * 1.5707963267948966
	rotationOffset = rotationOffset % 6.283185307179586
	if rotationOffset < 0 then
		rotationOffset = rotationOffset + 6.283185307179586
	end
	local rotationIndex = math.floor(rotationOffset / 1.5707963267948966 + 0.5)
	if rotationIndex == 1 then
		size.width = size.length
		size.length = size.width
		size.widthOffset = size.lengthOffset
		size.lengthOffset = -size.widthOffset
		return size
	elseif rotationIndex == 2 then
		size.widthOffset = -size.widthOffset
		size.lengthOffset = -size.lengthOffset
		return size
	else
		if rotationIndex == 3 then
			size.width = size.length
			size.length = size.width
			size.widthOffset = -size.lengthOffset
			size.lengthOffset = size.widthOffset
		end
		return size
	end
end
function StoreItemUtil.registerConfigurationSetXMLPaths(schema, baseKey)
	baseKey = baseKey .. ".configurationSets"
	schema:register(XMLValueType.L10N_STRING, baseKey .. "#title", "Title to display in config screen")
	schema:register(XMLValueType.BOOL, baseKey .. "#isYesNoOption", "Defines if the configuration set is a yes/no option", false)
	local setKey = baseKey .. ".configurationSet(?)"
	schema:register(XMLValueType.L10N_STRING, setKey .. "#name", "Set name")
	schema:register(XMLValueType.STRING, setKey .. "#params", "Parameters to insert into name")
	schema:register(XMLValueType.BOOL, setKey .. "#isDefault", "Is default set")
	schema:register(XMLValueType.STRING, setKey .. ".configuration(?)#name", "Configuration name")
	schema:register(XMLValueType.INT, setKey .. ".configuration(?)#index", "Selected index")
	schema:register(XMLValueType.BOOL, setKey .. ".configuration(?)#showWarning", "Show warning if config is not available (e.g. config that is added via a mod like Precision Farming)", true)
end
