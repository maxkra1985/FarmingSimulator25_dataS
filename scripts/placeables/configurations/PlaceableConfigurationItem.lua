-- Local values: PlaceableConfigurationItem_mt
PlaceableConfigurationItem = {}
PlaceableConfigurationItem.SELECTOR = ConfigurationUtil.SELECTOR_MULTIOPTION
PlaceableConfigurationItem.GLOBAL_DATA = {}

function PlaceableConfigurationItem.registerGlobalConfigurationData(data)
	local v2_ = PlaceableConfigurationItem.GLOBAL_DATA
	table.insert(v2_, data)
end
local v_u_3_ = Class(PlaceableConfigurationItem)
source("dataS/scripts/placeables/configurations/data/PlaceableConfigurationDataObjectChange.lua")

-- Upvalues: PlaceableConfigurationItem_mt
-- Local values: self
function PlaceableConfigurationItem.new(configName, customMt)
	-- upvalues: (copy) v_u_3_
	local v6_ = customMt or v_u_3_
	local v7_ = setmetatable({}, v6_)
	v7_.configName = configName
	v7_.name = ""
	v7_.index = -1
	v7_.configKey = ""
	v7_.desc = nil
	v7_.price = 0
	v7_.dailyUpkeep = 0
	v7_.isDefault = false
	v7_.isSelectable = true
	v7_.saveId = nil
	return v7_
end

-- Local values: params
function PlaceableConfigurationItem:loadFromXML(xmlFile, baseKey, configKey, baseDirectory, customEnvironment)
	self.name = xmlFile:getValue(configKey .. "#name", nil, customEnvironment, false)
	local v13_ = xmlFile:getValue(configKey .. "#params")
	if v13_ ~= nil then
		self.name = g_i18n:insertTextParams(self.name, v13_, customEnvironment, xmlFile)
	end
	if self.name == "" then
		self.name = configKey
	end
	self.configKey = configKey
	self.desc = xmlFile:getValue(configKey .. "#desc", self.desc, customEnvironment, false)
	self.price = xmlFile:getValue(configKey .. "#price", self.price)
	self.dailyUpkeep = xmlFile:getValue(configKey .. "#dailyUpkeep", self.dailyUpkeep)
	self.isDefault = xmlFile:getValue(configKey .. "#isDefault", self.isDefault)
	self.isSelectable = xmlFile:getValue(configKey .. "#isSelectable", self.isSelectable)
	self.saveId = xmlFile:getValue(configKey .. "#saveId", self.saveId)
	self.overwrittenTitle = xmlFile:getValue(baseKey .. "#title", nil, customEnvironment, false)
	return true
end

function PlaceableConfigurationItem:saveToXMLFile(xmlFile, key, isActive, configurationData)
	xmlFile:setValue(key .. "#name", self.configName)
	xmlFile:setValue(key .. "#id", self.saveId)
	xmlFile:setValue(key .. "#isActive", Utils.getNoNil(isActive, false))
end

function PlaceableConfigurationItem:loadFromSavegameXMLFile(xmlFile, key, configurationData) end

function PlaceableConfigurationItem:setIndex(index)
	self.index = index
	if self.saveId == nil then
		self.saveId = tostring(index)
	end
end

function PlaceableConfigurationItem:getNeedsRenaming(otherItem)
	return self.name == otherItem.name
end

-- Local values: _, data
function PlaceableConfigurationItem:onPreLoad(placeable, configId)
	for _, v25_ in ipairs(PlaceableConfigurationItem.GLOBAL_DATA) do
		if v25_.onPreLoad ~= nil then
			v25_.onPreLoad(placeable, self, configId)
		end
	end
end

-- Local values: _, data
function PlaceableConfigurationItem:onLoad(placeable, configId)
	for _, v29_ in ipairs(PlaceableConfigurationItem.GLOBAL_DATA) do
		if v29_.onLoad ~= nil then
			v29_.onLoad(placeable, self, configId)
		end
	end
end

-- Local values: _, data
function PlaceableConfigurationItem:onPostLoad(placeable, configId)
	for _, v33_ in ipairs(PlaceableConfigurationItem.GLOBAL_DATA) do
		if v33_.onPostLoad ~= nil then
			v33_.onPostLoad(placeable, self, configId)
		end
	end
end

-- Local values: _, data
function PlaceableConfigurationItem:onLoadFinished(placeable, configId)
	for _, v37_ in ipairs(PlaceableConfigurationItem.GLOBAL_DATA) do
		if v37_.onLoadFinished ~= nil then
			v37_.onLoadFinished(placeable, self, configId)
		end
	end
end

-- Local values: _, data
function PlaceableConfigurationItem:onSizeLoad(xmlFile, sizeData)
	for _, v41_ in ipairs(PlaceableConfigurationItem.GLOBAL_DATA) do
		if v41_.onSizeLoad ~= nil then
			v41_.onSizeLoad(self, xmlFile, sizeData)
		end
	end
end

-- Local values: i, renameIndex, j, i
function PlaceableConfigurationItem.postLoad(xmlFile, baseKey, baseDir, customEnvironment, isMod, configurationItems, storeItem)
	for v44_ = 1, #configurationItems do
		local v45_ = 0
		for v46_ = 1, #configurationItems do
			if configurationItems[v44_] ~= configurationItems[v46_] then
				if configurationItems[v44_]:getNeedsRenaming(configurationItems[v46_]) then
					configurationItems[v44_].renameIndex = (configurationItems[v46_].renameIndex or v45_) + 1
				end
				if configurationItems[v44_].saveId ~= nil and configurationItems[v44_].saveId == configurationItems[v46_].saveId then
					Logging.xmlWarning(xmlFile, "Duplicated saveId \'%s\' in \'%s\' configurations", configurationItems[v44_].saveId, configurationItems[v44_].configName)
				end
			end
		end
	end
	for v47_ = 1, #configurationItems do
		if configurationItems[v47_].renameIndex ~= nil and configurationItems[v47_].renameIndex > 1 then
			configurationItems[v47_].name = string.format("%s\194\160(%d)", configurationItems[v47_].name, configurationItems[v47_].renameIndex)
			configurationItems[v47_].renameIndex = nil
		end
	end
end

-- Local values: _, data
function PlaceableConfigurationItem.registerXMLPaths(schema, rootPath, configPath)
	schema:register(XMLValueType.L10N_STRING, rootPath .. "#title", "configuration title to display in shop")
	schema:register(XMLValueType.L10N_STRING, configPath .. "#name", "Configuration name")
	schema:register(XMLValueType.STRING, configPath .. "#params", "Extra parameters to insert in #name text")
	schema:register(XMLValueType.L10N_STRING, configPath .. "#desc", "Configuration description")
	schema:register(XMLValueType.FLOAT, configPath .. "#price", "Price of configuration", 0)
	schema:register(XMLValueType.FLOAT, configPath .. "#dailyUpkeep", "Daily up keep with this configuration", 0)
	schema:register(XMLValueType.BOOL, configPath .. "#isDefault", "Is selected by default in shop config screen", false)
	schema:register(XMLValueType.BOOL, configPath .. "#isSelectable", "Configuration can be selected in the shop", true)
	schema:register(XMLValueType.STRING, configPath .. "#saveId", "Custom save id", "Number of configuration")
	for _, v51_ in ipairs(PlaceableConfigurationItem.GLOBAL_DATA) do
		if v51_.registerXMLPaths ~= nil then
			v51_.registerXMLPaths(schema, rootPath, configPath)
		end
	end
end

function PlaceableConfigurationItem.registerSavegameXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. "#name", "Name of configuration")
	schema:register(XMLValueType.STRING, basePath .. "#id", "Save id")
	schema:register(XMLValueType.BOOL, basePath .. "#isActive", "Configuration is currently active")
end
