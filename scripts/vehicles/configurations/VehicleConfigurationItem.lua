-- Local values: VehicleConfigurationItem_mt
VehicleConfigurationItem = {}
VehicleConfigurationItem.SELECTOR = ConfigurationUtil.SELECTOR_MULTIOPTION
VehicleConfigurationItem.GLOBAL_DATA = {}

function VehicleConfigurationItem.registerGlobalConfigurationData(data)
	local v2_ = VehicleConfigurationItem.GLOBAL_DATA
	table.insert(v2_, data)
end
source("dataS/scripts/vehicles/configurations/data/VehicleConfigurationDataAdditionalMass.lua")
source("dataS/scripts/vehicles/configurations/data/VehicleConfigurationDataAttacherJoint.lua")
source("dataS/scripts/vehicles/configurations/data/VehicleConfigurationDataDependentConfig.lua")
source("dataS/scripts/vehicles/configurations/data/VehicleConfigurationDataMaterial.lua")
source("dataS/scripts/vehicles/configurations/data/VehicleConfigurationDataObjectChange.lua")
source("dataS/scripts/vehicles/configurations/data/VehicleConfigurationDataOverwrites.lua")
source("dataS/scripts/vehicles/configurations/data/VehicleConfigurationDataSize.lua")
local v_u_3_ = Class(VehicleConfigurationItem)

-- Upvalues: VehicleConfigurationItem_mt
-- Local values: self
function VehicleConfigurationItem.new(configName, customMt)
	-- upvalues: (copy) v_u_3_
	local v6_ = customMt or v_u_3_
	local v7_ = setmetatable({}, v6_)
	v7_.configName = configName
	v7_.name = ""
	v7_.index = -1
	v7_.hasDefaultName = false
	v7_.configKey = ""
	v7_.desc = nil
	v7_.price = 0
	v7_.dailyUpkeep = 0
	v7_.isDefault = false
	v7_.isSelectable = true
	v7_.saveId = nil
	v7_.isYesNoOption = false
	return v7_
end

-- Local values: params, vehicleBrandName, vehicleIcon, brandName, _, data
function VehicleConfigurationItem:loadFromXML(xmlFile, baseKey, configKey, baseDirectory, customEnvironment)
	self.name = xmlFile:getValue(configKey .. "#name", self.name, customEnvironment, false)
	local v14_ = xmlFile:getValue(configKey .. "#params")
	if v14_ ~= nil then
		self.name = g_i18n:insertTextParams(self.name, v14_, customEnvironment, xmlFile)
	end
	if self.name == "" then
		local v15_ = self.index
		self.name = tostring(v15_)
		self.hasDefaultName = true
	end
	self.configKey = configKey
	self.desc = xmlFile:getValue(configKey .. "#desc", self.desc, customEnvironment, false)
	self.price = xmlFile:getValue(configKey .. "#price", self.price)
	self.dailyUpkeep = xmlFile:getValue(configKey .. "#dailyUpkeep", self.dailyUpkeep)
	self.isDefault = xmlFile:getValue(configKey .. "#isDefault", self.isDefault)
	self.isSelectable = xmlFile:getValue(configKey .. "#isSelectable", self.isSelectable)
	self.saveId = xmlFile:getValue(configKey .. "#saveId", self.saveId)
	self.overwrittenTitle = xmlFile:getValue(baseKey .. "#title", nil, customEnvironment, false)
	self.isYesNoOption = xmlFile:getValue(baseKey .. "#isYesNoOption", self.isYesNoOption)
	local v16_ = xmlFile:getValue(configKey .. "#vehicleBrand")
	self.vehicleBrand = g_brandManager:getBrandIndexByName(v16_)
	self.vehicleName = xmlFile:getValue(configKey .. "#vehicleName", nil, customEnvironment, false)
	local v17_ = xmlFile:getValue(configKey .. "#vehicleIcon")
	if v17_ ~= nil then
		self.vehicleIcon = Utils.getFilename(v17_, baseDirectory)
		if not textureFileExists(self.vehicleIcon) then
			Logging.xmlWarning(xmlFile, "Custom configuration vehicle icon \'%s\' not found.", self.vehicleIcon)
			self.vehicleIcon = nil
		end
	end
	local v18_ = xmlFile:getValue(configKey .. "#displayBrand")
	self.brandIndex = g_brandManager:getBrandIndexByName(v18_)
	self.shopTranslationOffset = xmlFile:getValue(configKey .. ".shopOffset#translation", nil, true)
	self.shopRotationOffset = xmlFile:getValue(configKey .. ".shopOffset#rotation", nil, true)
	for _, v19_ in ipairs(VehicleConfigurationItem.GLOBAL_DATA) do
		if v19_.loadConfigItem ~= nil then
			v19_.loadConfigItem(self, xmlFile, baseKey, configKey, baseDirectory, customEnvironment)
		end
	end
	return true
end

function VehicleConfigurationItem:saveToXMLFile(xmlFile, key, isActive, configurationData)
	xmlFile:setValue(key .. "#name", self.configName)
	xmlFile:setValue(key .. "#id", self.saveId)
	xmlFile:setValue(key .. "#isActive", Utils.getNoNil(isActive, false))
end

function VehicleConfigurationItem:loadFromSavegameXMLFile(xmlFile, key, configurationData) end

function VehicleConfigurationItem:setIndex(index)
	self.index = index
	if self.saveId == nil then
		self.saveId = tostring(index)
	end
end

function VehicleConfigurationItem:getNeedsRenaming(otherItem)
	return self.name == otherItem.name
end

-- Local values: _, data
function VehicleConfigurationItem:onPreLoad(object, configId)
	for _, v31_ in ipairs(VehicleConfigurationItem.GLOBAL_DATA) do
		if v31_.onPreLoad ~= nil then
			v31_.onPreLoad(object, self, configId)
		end
	end
end

-- Local values: _, data
function VehicleConfigurationItem:onLoad(object, configId)
	for _, v35_ in ipairs(VehicleConfigurationItem.GLOBAL_DATA) do
		if v35_.onLoad ~= nil then
			v35_.onLoad(object, self, configId)
		end
	end
end

-- Local values: _, data
function VehicleConfigurationItem:onPrePostLoad(object, configId)
	for _, v39_ in ipairs(VehicleConfigurationItem.GLOBAL_DATA) do
		if v39_.onPrePostLoad ~= nil then
			v39_.onPrePostLoad(object, self, configId)
		end
	end
end

-- Local values: _, data
function VehicleConfigurationItem:onPostLoad(object, configId)
	for _, v43_ in ipairs(VehicleConfigurationItem.GLOBAL_DATA) do
		if v43_.onPostLoad ~= nil then
			v43_.onPostLoad(object, self, configId)
		end
	end
end

-- Local values: _, data
function VehicleConfigurationItem:onLoadFinished(object, configId)
	for _, v47_ in ipairs(VehicleConfigurationItem.GLOBAL_DATA) do
		if v47_.onLoadFinished ~= nil then
			v47_.onLoadFinished(object, self, configId)
		end
	end
end

-- Local values: _, data
function VehicleConfigurationItem:onSizeLoad(xmlFile, sizeData)
	for _, v51_ in ipairs(VehicleConfigurationItem.GLOBAL_DATA) do
		if v51_.onSizeLoad ~= nil then
			v51_.onSizeLoad(self, xmlFile, sizeData)
		end
	end
end

-- Local values: i, renameIndex, j, i
function VehicleConfigurationItem.postLoad(xmlFile, baseKey, baseDir, customEnvironment, isMod, configurationItems, storeItem)
	for v54_ = 1, #configurationItems do
		local v55_ = 0
		for v56_ = 1, #configurationItems do
			if configurationItems[v54_] ~= configurationItems[v56_] then
				if configurationItems[v54_]:getNeedsRenaming(configurationItems[v56_]) then
					configurationItems[v54_].renameIndex = (configurationItems[v56_].renameIndex or v55_) + 1
				end
				if configurationItems[v54_].saveId ~= nil and configurationItems[v54_].saveId == configurationItems[v56_].saveId then
					Logging.xmlWarning(xmlFile, "Duplicated saveId \'%s\' in \'%s\' configurations", configurationItems[v54_].saveId, configurationItems[v54_].configName)
				end
			end
		end
	end
	for v57_ = 1, #configurationItems do
		if configurationItems[v57_].renameIndex ~= nil and configurationItems[v57_].renameIndex > 1 then
			configurationItems[v57_].name = string.format("%s\194\160(%d)", configurationItems[v57_].name, configurationItems[v57_].renameIndex)
			configurationItems[v57_].renameIndex = nil
		end
	end
end

-- Local values: _, data
function VehicleConfigurationItem.registerXMLPaths(schema, rootPath, configPath)
	schema:register(XMLValueType.L10N_STRING, rootPath .. "#title", "configuration title to display in shop")
	schema:register(XMLValueType.BOOL, rootPath .. "#isYesNoOption", "UI in the shop will just show a yes/no slider element", false)
	schema:register(XMLValueType.L10N_STRING, configPath .. "#name", "Configuration name")
	schema:register(XMLValueType.STRING, configPath .. "#params", "Extra parameters to insert in #name text")
	schema:register(XMLValueType.L10N_STRING, configPath .. "#desc", "Configuration description")
	schema:register(XMLValueType.FLOAT, configPath .. "#price", "Price of configuration", 0)
	schema:register(XMLValueType.FLOAT, configPath .. "#dailyUpkeep", "Daily up keep with this configuration", 0)
	schema:register(XMLValueType.BOOL, configPath .. "#isDefault", "Is selected by default in shop config screen", false)
	schema:register(XMLValueType.BOOL, configPath .. "#isSelectable", "Configuration can be selected in the shop", true)
	schema:register(XMLValueType.STRING, configPath .. "#saveId", "Custom save id", "Number of configuration")
	schema:register(XMLValueType.STRING, configPath .. "#displayBrand", "If defined a brand icon is displayed in the shop config screen")
	schema:register(XMLValueType.STRING, configPath .. "#vehicleBrand", "Custom brand to display after bought with this configuration")
	schema:register(XMLValueType.L10N_STRING, configPath .. "#vehicleName", "Custom vehicle name to display after bought with this configuration")
	schema:register(XMLValueType.STRING, configPath .. "#vehicleIcon", "Custom icon to display after bought with this configuration")
	schema:register(XMLValueType.VECTOR_TRANS, configPath .. ".shopOffset#translation", "Shop translation offset when this config is used")
	schema:register(XMLValueType.VECTOR_ROT, configPath .. ".shopOffset#rotation", "Shop rotation offset when this config is used")
	for _, v61_ in ipairs(VehicleConfigurationItem.GLOBAL_DATA) do
		if v61_.registerXMLPaths ~= nil then
			v61_.registerXMLPaths(schema, rootPath, configPath)
		end
	end
end

function VehicleConfigurationItem.registerSavegameXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. "#name", "Name of configuration")
	schema:register(XMLValueType.STRING, basePath .. "#id", "Save id")
	schema:register(XMLValueType.BOOL, basePath .. "#isActive", "Configuration is currently active")
end
