-- Local values: VehicleConfigurationItemTreeSapling_mt
VehicleConfigurationItemTreeSapling = {}
VehicleConfigurationItemTreeSapling.SELECTOR = ConfigurationUtil.SELECTOR_MULTIOPTION
local VehicleConfigurationItemTreeSapling_mt = Class(VehicleConfigurationItemTreeSapling, VehicleConfigurationItem)

-- Upvalues: VehicleConfigurationItemTreeSapling_mt
-- Local values: self
function VehicleConfigurationItemTreeSapling.new(configName, customMt)
	-- upvalues: (copy) VehicleConfigurationItemTreeSapling_mt
	return VehicleConfigurationItemTreeSapling:superClass().new(configName, VehicleConfigurationItemTreeSapling_mt)
end

function VehicleConfigurationItemTreeSapling:loadFromXML(xmlFile, baseKey, configKey, baseDirectory, customEnvironment)
	if not VehicleConfigurationItemTreeSapling:superClass().loadFromXML(self, xmlFile, baseKey, configKey, baseDirectory, customEnvironment) then
		return false
	end
	self.useMapTreeTypes = xmlFile:getValue(configKey .. "#useMapTreeTypes", false)
	if self.useMapTreeTypes then
		self.numSaplings = xmlFile:getInt("vehicle.storeData.specs.capacity", 0)
	end
	self.fillUnitIndex = xmlFile:getValue(configKey .. "#fillUnitIndex", 1)
	self.treeTypeName = xmlFile:getValue(configKey .. "#treeType", "spruce")
	self.variationName = xmlFile:getValue(configKey .. "#variationName")
	self.filename = xmlFile:getValue(configKey .. "#filename", nil, baseDirectory)
	return true
end

-- Local values: i, baseConfigItem
function VehicleConfigurationItemTreeSapling.postLoad(xmlFile, baseKey, baseDir, customEnvironment, isMod, configurationItems, storeItem, configName)
	VehicleConfigurationItemTreeSapling:superClass().postLoad(xmlFile, baseKey, baseDir, customEnvironment, isMod, configurationItems, storeItem, configName)
	for _, v17_ in ipairs(configurationItems) do
		if v17_.useMapTreeTypes then
			VehicleConfigurationItemTreeSapling.generateConfigurations(configurationItems, xmlFile, configName, v17_)
			return
		end
	end
end

-- Local values: i, _, treeTypeDesc, configItem, index
function VehicleConfigurationItemTreeSapling.generateConfigurations(configurationItems, xmlFile, configName, baseConfigItem)
	for v21_ = #configurationItems, 1, -1 do
		configurationItems[v21_] = nil
	end
	for _, v22_ in ipairs(g_treePlantManager.treeTypes) do
		if #v22_.stages > 1 and v22_.supportsPlanting then
			local v23_ = VehicleConfigurationItemTreeSapling.new(configName)
			v23_.name = v22_.title
			v23_.price = v22_.saplingPrice * baseConfigItem.numSaplings
			v23_.saveId = v22_.name
			v23_.fillUnitIndex = baseConfigItem.fillUnitIndex
			v23_.treeTypeName = v22_.name
			v23_.variationName = baseConfigItem.variationName
			v23_.filename = nil
			table.insert(configurationItems, v23_)
			v23_:setIndex(#configurationItems)
			v23_.configKey = baseConfigItem.configKey
		end
	end
end

function VehicleConfigurationItemTreeSapling.registerXMLPaths(schema, rootPath, configPath)
	VehicleConfigurationItemTreeSapling:superClass().registerXMLPaths(schema, rootPath, configPath)
	schema:register(XMLValueType.BOOL, configPath .. "#useMapTreeTypes", "Create configuration for each tree type on the map", false)
	schema:register(XMLValueType.INT, configPath .. "#fillUnitIndex", "Index of the saplings fill unit", 1)
	schema:register(XMLValueType.STRING, configPath .. "#treeType", "Tree Type Name", "spruce")
	schema:register(XMLValueType.STRING, configPath .. "#variationName", "Stage variation name to use", "DEFAULT")
	schema:register(XMLValueType.FILENAME, configPath .. "#filename", "Custom tree sapling i3d file")
end
