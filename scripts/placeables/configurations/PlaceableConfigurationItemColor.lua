PlaceableConfigurationItemColor = {}
PlaceableConfigurationItemColor.SELECTOR = ConfigurationUtil.SELECTOR_COLOR
local PlaceableConfigurationItemColor_mt = Class(PlaceableConfigurationItemColor, PlaceableConfigurationItem)
function PlaceableConfigurationItemColor.new(configName, customMt)
	local self = PlaceableConfigurationItemColor:superClass().new(configName, PlaceableConfigurationItemColor_mt)
	self.isCustomColor = false
	self.isManualConfig = false
	return self
end
function PlaceableConfigurationItemColor:loadFromXML(xmlFile, baseKey, configKey, baseDirectory, customEnvironment)
	if not PlaceableConfigurationItemColor:superClass().loadFromXML(self, xmlFile, baseKey, configKey, baseDirectory, customEnvironment) then
		return false
	else
		local colorStr = xmlFile:getValue(configKey .. "#color", nil, true)
		local color, title = g_vehicleMaterialManager:getMaterialTemplateColorAndTitleByName(colorStr, customEnvironment)
		if color ~= nil then
			if self.hasDefaultName then
				self.name = title or self.name
			end
			self.color = color
		else
			self.color = string.getVector(colorStr)
			if self.color ~= nil and #self.color ~= 3 then
				Logging.xmlWarning(xmlFile, "Invalid rgb color '%s' in '%s'", colorStr, configKey)
				self.color = nil
			end
		end
		self.uiColor = xmlFile:getValue(configKey .. "#uiColor", nil, true)
		local materialTemplateName = xmlFile:getValue(configKey .. "#materialTemplateName")
		if materialTemplateName ~= nil then
			color, title = g_vehicleMaterialManager:getMaterialTemplateColorAndTitleByName(materialTemplateName, customEnvironment)
			if color ~= nil then
				self.color = self.color or color
				if self.name == nil or self.name == "" then
					self.name = title or self.name
				end
			else
				Logging.xmlWarning(xmlFile, "Material template '%s' not defined for '%s'", materialTemplateName, configKey)
			end
		end
		if self.color == nil then
			self.color = { 1, 1, 1 }
		end
		self.colorOffset = xmlFile:getValue(configKey .. "#colorOffset", 0.71)
		self.uiColor = self.uiColor or self.color
		self.isManualConfig = true
		return true
	end
end
function PlaceableConfigurationItemColor:saveToXMLFile(xmlFile, key, isActive, configurationData)
	PlaceableConfigurationItemColor:superClass().saveToXMLFile(self, xmlFile, key, isActive, configurationData)
	if self.isCustomColor then
		if configurationData.color ~= nil then
			xmlFile:setValue(key .. "#color", configurationData.color[1], configurationData.color[2], configurationData.color[3])
		end
		if configurationData.materialTemplateName ~= nil then
			xmlFile:setValue(key .. "#materialTemplateName", configurationData.materialTemplateName)
		end
	end
end
function PlaceableConfigurationItemColor:loadFromSavegameXMLFile(xmlFile, key, configurationData)
	PlaceableConfigurationItemColor:superClass().loadFromSavegameXMLFile(self, xmlFile, key, configurationData)
	if self.isCustomColor then
		configurationData.color = xmlFile:getValue(key .. "#color", nil, true)
		configurationData.materialTemplateName = xmlFile:getValue(key .. "#materialTemplateName")
	end
end
function PlaceableConfigurationItemColor:readFromStream(streamId, connection, configurationData)
	if self.isCustomColor then
		local r, g, b = NetworkUtil.readCompressedColor(streamId)
		configurationData.color = { r, g, b }
		local templateIndex = streamReadUIntN(streamId, VehicleMaterialManager.NUM_BITS_TEMPLATE)
		configurationData.materialTemplateName = g_vehicleMaterialManager:getMaterialTemplateNameByIndex(templateIndex)
	end
end
function PlaceableConfigurationItemColor:writeToStream(streamId, connection, configurationData)
	if self.isCustomColor then
		local r = 1
		local g = 1
		local b = 1
		if configurationData.color ~= nil then
			r = configurationData.color[1]
			g = configurationData.color[2]
			b = configurationData.color[3]
		end
		NetworkUtil.writeCompressedColor(streamId, r, g, b)
		local templateIndex = g_vehicleMaterialManager:getMaterialTemplateIndexByName(configurationData.materialTemplateName)
		streamWriteUIntN(streamId, math.clamp(templateIndex, 0, VehicleMaterialManager.MAX_TEMPLATE_INDEX), VehicleMaterialManager.NUM_BITS_TEMPLATE)
	end
end
function PlaceableConfigurationItemColor:hasDataChanged(configurationData1, configurationData2)
	if self.isCustomColor then
		if configurationData1.color ~= nil and configurationData2.color ~= nil then
			if 0.00001 < math.abs(configurationData1.color[1] - configurationData2.color[1]) or 0.00001 < math.abs(configurationData1.color[2] - configurationData2.color[2]) or 0.00001 < math.abs(configurationData1.color[3] - configurationData2.color[3]) then
				return true
			end
			if configurationData1.materialTemplateName ~= configurationData2.materialTemplateName then
				return true
			else
				return false
			end
		end
		if configurationData1.color ~= nil or configurationData2.color ~= nil then
			return true
		end
	end
end
function PlaceableConfigurationItemColor:getColor(placeable)
	local color, _, colorOffset = self:getColorAndMaterialFromPlaceable(placeable)
	return color, colorOffset
end
function PlaceableConfigurationItemColor:getColorAndMaterialFromPlaceable(placeable)
	local color = self.color
	local materialTemplateName = self.materialTemplateName
	if placeable ~= nil then
		local data = placeable.configurationData[self.configName]
		if data ~= nil then
			local configurationData = data[self.index]
			if configurationData ~= nil then
				if configurationData.color ~= nil then
					color = configurationData.color
				end
				if configurationData.materialTemplateName ~= nil then
					materialTemplateName = configurationData.materialTemplateName
				end
			end
		end
	end
	return table.clone(color), materialTemplateName, self.colorOffset
end
function PlaceableConfigurationItemColor:onSizeLoad(xmlFile, sizeData)
	if self.configKey ~= "" then
		PlaceableConfigurationItemColor:superClass().onSizeLoad(self, xmlFile, sizeData)
	end
end
function PlaceableConfigurationItemColor:onPostLoad(placeable, configId)
	PlaceableConfigurationItemColor:superClass().onPostLoad(self, placeable, configId)
	local configurationDesc = g_placeableConfigurationManager:getConfigurationDescByName(self.configName)
	local xmlFile = placeable.xmlFile
	local color, _, colorOffset = self:getColorAndMaterialFromPlaceable(placeable)
	local r, g, b = unpack(color)
	for _, materialKey in xmlFile:iterator(configurationDesc.configurationsKey .. ".material") do
		local slotName = xmlFile:getValue(materialKey .. "#slotName")
		PlaceableConfigurationItemColor.applyColor(placeable.rootNode, slotName, r, g, b, colorOffset)
	end
	for _, nodeKey in xmlFile:iterator(configurationDesc.configurationsKey .. ".node") do
		local node = xmlFile:getValue(nodeKey .. "#node", nil, placeable.components, placeable.i3dMappings)
		if node == nil then
			continue
		end
		setShaderParameter(node, "colorScale0", r, g, b, 1, false)
	end
end
function PlaceableConfigurationItemColor.applyColor(node, slotName, r, g, b, colorOffset)
	if getHasClassId(node, ClassIds.SHAPE) then
		for materialIndex = 0, getNumOfMaterials(node) - 1 do
			local materialSlotName = getMaterialSlotName(node, materialIndex)
			if materialSlotName == slotName then
				if getHasShaderParameter(node, "HSL", materialIndex) then
					local h, s, l = Color.rgbToHsl(r, g, b, colorOffset)
					setShaderParameter(node, "HSL", h, s, l, 0, false, materialIndex)
				else
					setShaderParameter(node, "colorScale0", r, g, b, 1, false, materialIndex)
				end
			end
		end
	end
	for i = 1, getNumOfChildren(node) do
		PlaceableConfigurationItemColor.applyColor(getChildAt(node, i - 1), slotName, r, g, b, colorOffset)
	end
end
function PlaceableConfigurationItemColor.postLoad(xmlFile, baseKey, baseDir, customEnvironment, isMod, configurationItems, storeItem, configName)
	PlaceableConfigurationItemColor:superClass().postLoad(xmlFile, baseKey, baseDir, customEnvironment, isMod, configurationItems, storeItem, configName)
	local defaultColorIndex = xmlFile:getValue(baseKey .. "#defaultColorIndex")
	if xmlFile:getValue(baseKey .. "#useDefaultColors", false) or g_modIsLoaded.FS25_unlimitedColorConfigurations and 0 < #configurationItems then
		local price = xmlFile:getValue(baseKey .. "#price", 1000)
		for i, brandMaterialName in pairs(PlaceableConfigurationItemColor.DEFAULT_COLORS) do
			local color, title = g_vehicleMaterialManager:getMaterialTemplateColorAndTitleByName(brandMaterialName, customEnvironment)
			if color == nil then
				continue
			end
			local configItem = PlaceableConfigurationItemColor.new(configName)
			configItem.name = title or configItem.name
			if i == defaultColorIndex then
				configItem.isDefault = true
				configItem.price = 0
			else
				configItem.price = price
			end
			configItem.name = configItem.name or title
			configItem.color = color
			configItem.uiColor = color
			configItem.saveId = brandMaterialName
			table.insert(configurationItems, configItem)
			configItem:setIndex(#configurationItems)
		end
		local configItem = PlaceableConfigurationItemColor.new(configName)
		configItem.name = g_i18n:getText("ui_colorPicker_custom")
		configItem.price = price
		configItem.color = { 1, 1, 1, 1 }
		configItem.uiColor = { 1, 1, 1, 1 }
		configItem.materialTemplateName = "calibratedPaint"
		configItem.isCustomColor = true
		configItem.isSelectable = false
		configItem.saveId = "CUSTOM_COLOR"
		table.insert(configurationItems, configItem)
		configItem:setIndex(#configurationItems)
	end
	if defaultColorIndex == nil then
		local defaultIsDefined = false
		for _, item in ipairs(configurationItems) do
			if item.isDefault == nil then
				continue
			end
			if item.isDefault then
				defaultIsDefined = true
			end
		end
		if not defaultIsDefined and 0 < #configurationItems then
			configurationItems[1].isDefault = true
			configurationItems[1].price = 0
		end
	end
end
function PlaceableConfigurationItemColor.getFallbackConfigId(configs, configId, configName, configFileName)
	local numManualConfigs = 0
	for _, config in pairs(configs) do
		if config.isManualConfig then
			numManualConfigs = numManualConfigs + 1
		end
	end
	local configIndex = tonumber(configId)
	if configIndex ~= nil then
		if numManualConfigs < configIndex then
			local brandMaterialName = PlaceableConfigurationItemColor.DEFAULT_COLORS_PATCH_1_2[configIndex - numManualConfigs]
			for _, config in pairs(configs) do
				if config.saveId == brandMaterialName then
					return config.index, config.saveId
				end
			end
		end
		return nil, nil
	else
		return nil, nil
	end
end
function PlaceableConfigurationItemColor.registerXMLPaths(schema, rootPath, configPath)
	PlaceableConfigurationItemColor:superClass().registerXMLPaths(schema, rootPath, configPath)
	schema:register(XMLValueType.INT, rootPath .. "#defaultColorIndex", "Default color index on start")
	schema:register(XMLValueType.BOOL, rootPath .. "#useDefaultColors", "Use default colors", false)
	schema:register(XMLValueType.INT, rootPath .. "#price", "Default color price", 1000)
	schema:register(XMLValueType.STRING, rootPath .. ".material(?)#slotName")
	schema:register(XMLValueType.NODE_INDEX, rootPath .. ".node(?)#node")
	schema:register(XMLValueType.FLOAT, configPath .. "#colorOffset", "colorOffset when use HSL ShaderParam and the baseTextureColor isn\194\180t blue", 0.71)
	schema:register(XMLValueType.STRING, configPath .. "#color", "Configuration color", "1 1 1 1")
	schema:register(XMLValueType.COLOR, configPath .. "#uiColor", "Configuration UI color", "1 1 1 1")
	schema:register(XMLValueType.STRING, configPath .. "#materialTemplateName", "Name of the material template to use")
end
function PlaceableConfigurationItemColor.registerSavegameXMLPaths(schema, basePath)
	PlaceableConfigurationItemColor:superClass().registerSavegameXMLPaths(schema, basePath)
	schema:register(XMLValueType.FLOAT, basePath .. "#colorOffset", "colorOffset HSL", 0.71)
	schema:register(XMLValueType.VECTOR_3, basePath .. "#color", "Configuration color", "1 1 1")
	schema:register(XMLValueType.STRING, basePath .. "#materialTemplateName", "Name of material template to use")
end
PlaceableConfigurationItemColor.DEFAULT_COLORS = { "SHARED_WHITE2", "SHARED_BEIGE", "SHARED_SILVER", "SHARED_GREYLIGHT", "SHARED_GREY", "SHARED_GREYDARK", "SHARED_BLACKONYX", "SHARED_BLACKJET", "JOHNDEERE_YELLOW1", "JCB_YELLOW1", "CHALLENGER_YELLOW1", "SCHOUTEN_ORANGE1", "FENDT_RED1", "CASEIH_RED1", "MASSEYFERGUSON_RED", "HARDI_RED", "NEWHOLLAND_BLUE2", "RABE_BLUE1", "LEMKEN_BLUE1", "NEWHOLLAND_BLUE1", "BOECKMANN_BLUE1", "GOLDHOFER_BLUE", "SHARED_BLUENAVY", "LIZARD_PURPLE1", "VALTRA_GREEN2", "DEUTZ_GREEN5", "JOHNDEERE_GREEN1", "FENDT_NEWGREEN1", "FENDT_OLDGREEN1", "KOTTE_GREEN2", "CLAAS_GREEN1", "LIZARD_OLIVE1", "LIZARD_ECRU1", "SHARED_BROWN", "SHARED_REDCRIMSON", "LIZARD_PINK1" }
PlaceableConfigurationItemColor.DEFAULT_COLORS_PATCH_1_2 = { "SHARED_WHITE2", "SHARED_BEIGE", "SHARED_SILVER", "SHARED_GREYLIGHT", "SHARED_GREY", "SHARED_GREYDARK", "SHARED_BLACKONYX", "SHARED_BLACKJET", "JOHNDEERE_YELLOW1", "JCB_YELLOW1", "CHALLENGER_YELLOW1", "SCHOUTEN_ORANGE1", "FENDT_RED1", "CASEIH_RED1", "MASSEYFERGUSON_RED", "HARDI_RED", "NEWHOLLAND_BLUE2", "RABE_BLUE1", "LEMKEN_BLUE1", "NEWHOLLAND_BLUE1", "BOECKMANN_BLUE1", "GOLDHOFER_BLUE", "SHARED_BLUENAVY", "LIZARD_PURPLE1", "VALTRA_GREEN2", "DEUTZ_GREEN5", "JOHNDEERE_GREEN1", "FENDT_NEWGREEN1", "FENDT_OLDGREEN1", "KOTTE_GREEN2", "CLAAS_GREEN1", "LIZARD_OLIVE1", "LIZARD_ECRU1", "SHARED_BROWN", "SHARED_REDCRIMSON", "LIZARD_PINK1" }
