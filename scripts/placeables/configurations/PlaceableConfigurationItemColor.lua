-- Local values: PlaceableConfigurationItemColor_mt
PlaceableConfigurationItemColor = {}
PlaceableConfigurationItemColor.SELECTOR = ConfigurationUtil.SELECTOR_COLOR
local PlaceableConfigurationItemColor_mt = Class(PlaceableConfigurationItemColor, PlaceableConfigurationItem)

-- Upvalues: PlaceableConfigurationItemColor_mt
-- Local values: self
function PlaceableConfigurationItemColor.new(configName, customMt)
	-- upvalues: (copy) PlaceableConfigurationItemColor_mt
	local v3_ = PlaceableConfigurationItemColor:superClass().new(configName, PlaceableConfigurationItemColor_mt)
	v3_.isCustomColor = false
	v3_.isManualConfig = false
	return v3_
end

-- Local values: colorStr, color, title, materialTemplateName
function PlaceableConfigurationItemColor:loadFromXML(xmlFile, baseKey, configKey, baseDirectory, customEnvironment)
	if not PlaceableConfigurationItemColor:superClass().loadFromXML(self, xmlFile, baseKey, configKey, baseDirectory, customEnvironment) then
		return false
	end
	local v10_ = xmlFile:getValue(configKey .. "#color", nil, true)
	local v11_, v12_ = g_vehicleMaterialManager:getMaterialTemplateColorAndTitleByName(v10_, customEnvironment)
	if v11_ == nil then
		self.color = string.getVector(v10_)
		if self.color ~= nil and #self.color ~= 3 then
			Logging.xmlWarning(xmlFile, "Invalid rgb color \'%s\' in \'%s\'", v10_, configKey)
			self.color = nil
		end
	else
		if self.hasDefaultName then
			self.name = v12_ or self.name
		end
		self.color = v11_
	end
	self.uiColor = xmlFile:getValue(configKey .. "#uiColor", nil, true)
	local v13_ = xmlFile:getValue(configKey .. "#materialTemplateName")
	if v13_ ~= nil then
		local v14_, v15_ = g_vehicleMaterialManager:getMaterialTemplateColorAndTitleByName(v13_, customEnvironment)
		if v14_ == nil then
			Logging.xmlWarning(xmlFile, "Material template \'%s\' not defined for \'%s\'", v13_, configKey)
		else
			self.color = self.color or v14_
			if self.name == nil or self.name == "" then
				self.name = v15_ or self.name
			end
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

-- Local values: r, g, b, templateIndex
function PlaceableConfigurationItemColor:readFromStream(streamId, connection, configurationData)
	if self.isCustomColor then
		local v28_, v29_, v30_ = NetworkUtil.readCompressedColor(streamId)
		configurationData.color = { v28_, v29_, v30_ }
		local v31_ = streamReadUIntN(streamId, VehicleMaterialManager.NUM_BITS_TEMPLATE)
		configurationData.materialTemplateName = g_vehicleMaterialManager:getMaterialTemplateNameByIndex(v31_)
	end
end

-- Local values: r, g, b, templateIndex
function PlaceableConfigurationItemColor:writeToStream(streamId, connection, configurationData)
	if self.isCustomColor then
		local v35_, v36_, v37_
		if configurationData.color == nil then
			v35_ = 1
			v36_ = 1
			v37_ = 1
		else
			v35_ = configurationData.color[1]
			v36_ = configurationData.color[2]
			v37_ = configurationData.color[3]
		end
		NetworkUtil.writeCompressedColor(streamId, v35_, v36_, v37_)
		local v38_ = g_vehicleMaterialManager:getMaterialTemplateIndexByName(configurationData.materialTemplateName)
		local v39_ = streamWriteUIntN
		local v40_ = VehicleMaterialManager.MAX_TEMPLATE_INDEX
		v39_(streamId, math.clamp(v38_, 0, v40_), VehicleMaterialManager.NUM_BITS_TEMPLATE)
	end
end

function PlaceableConfigurationItemColor:hasDataChanged(configurationData1, configurationData2)
	if not self.isCustomColor then
		::l2::
		return false
	end
	if configurationData1.color == nil or configurationData2.color == nil then
		if configurationData1.color ~= nil or configurationData2.color ~= nil then
			return true
		end
		goto l9
	else
		local v44_ = configurationData1.color[1] - configurationData2.color[1]
		if math.abs(v44_) <= 0.00001 then
			local v45_ = configurationData1.color[2] - configurationData2.color[2]
			if math.abs(v45_) <= 0.00001 then
				local v46_ = configurationData1.color[3] - configurationData2.color[3]
				if math.abs(v46_) <= 0.00001 then
					::l9::
					if configurationData1.materialTemplateName ~= configurationData2.materialTemplateName then
						return true
					end
					goto l2
				end
			end
		end
		return true
	end
end

-- Local values: color, _, colorOffset
function PlaceableConfigurationItemColor:getColor(placeable)
	local v49_, _, v50_ = self:getColorAndMaterialFromPlaceable(placeable)
	return v49_, v50_
end

-- Local values: color, materialTemplateName, data, configurationData
function PlaceableConfigurationItemColor:getColorAndMaterialFromPlaceable(placeable)
	local v53_ = self.color
	local v54_ = self.materialTemplateName
	if placeable ~= nil then
		local v55_ = placeable.configurationData[self.configName]
		if v55_ ~= nil then
			local v56_ = v55_[self.index]
			if v56_ ~= nil then
				if v56_.color ~= nil then
					v53_ = v56_.color
				end
				if v56_.materialTemplateName ~= nil then
					v54_ = v56_.materialTemplateName
				end
			end
		end
	end
	return table.clone(v53_), v54_, self.colorOffset
end

function PlaceableConfigurationItemColor:onSizeLoad(xmlFile, sizeData)
	if self.configKey ~= "" then
		PlaceableConfigurationItemColor:superClass().onSizeLoad(self, xmlFile, sizeData)
	end
end

-- Local values: configurationDesc, xmlFile, color, _, colorOffset, r, g, b, _, materialKey, slotName, _, nodeKey, node
function PlaceableConfigurationItemColor:onPostLoad(placeable, configId)
	PlaceableConfigurationItemColor:superClass().onPostLoad(self, placeable, configId)
	local v63_ = g_placeableConfigurationManager:getConfigurationDescByName(self.configName)
	local v64_ = placeable.xmlFile
	local v65_, _, v66_ = self:getColorAndMaterialFromPlaceable(placeable)
	local v67_, v68_, v69_ = unpack(v65_)
	for _, v70_ in v64_:iterator(v63_.configurationsKey .. ".material") do
		local v71_ = v64_:getValue(v70_ .. "#slotName")
		PlaceableConfigurationItemColor.applyColor(placeable.rootNode, v71_, v67_, v68_, v69_, v66_)
	end
	for _, v72_ in v64_:iterator(v63_.configurationsKey .. ".node") do
		local v73_ = v64_:getValue(v72_ .. "#node", nil, placeable.components, placeable.i3dMappings)
		if v73_ ~= nil then
			setShaderParameter(v73_, "colorScale0", v67_, v68_, v69_, 1, false)
		end
	end
end

-- Local values: materialIndex, materialSlotName, h, s, l, i
function PlaceableConfigurationItemColor.applyColor(node, slotName, r, g, b, colorOffset)
	if getHasClassId(node, ClassIds.SHAPE) then
		for v80_ = 0, getNumOfMaterials(node) - 1 do
			if getMaterialSlotName(node, v80_) == slotName then
				if getHasShaderParameter(node, "HSL", v80_) then
					local v81_, v82_, v83_ = Color.rgbToHsl(r, g, b, colorOffset)
					setShaderParameter(node, "HSL", v81_, v82_, v83_, 0, false, v80_)
				else
					setShaderParameter(node, "colorScale0", r, g, b, 1, false, v80_)
				end
			end
		end
	end
	for v84_ = 1, getNumOfChildren(node) do
		PlaceableConfigurationItemColor.applyColor(getChildAt(node, v84_ - 1), slotName, r, g, b, colorOffset)
	end
end

-- Local values: defaultColorIndex, price, i, brandMaterialName, color, title, configItem, configItem, defaultIsDefined, _, item
function PlaceableConfigurationItemColor.postLoad(xmlFile, baseKey, baseDir, customEnvironment, isMod, configurationItems, storeItem, configName)
	PlaceableConfigurationItemColor:superClass().postLoad(xmlFile, baseKey, baseDir, customEnvironment, isMod, configurationItems, storeItem, configName)
	local v93_ = xmlFile:getValue(baseKey .. "#defaultColorIndex")
	if xmlFile:getValue(baseKey .. "#useDefaultColors", false) or g_modIsLoaded.FS25_unlimitedColorConfigurations and #configurationItems > 0 then
		local v94_ = xmlFile:getValue(baseKey .. "#price", 1000)
		for v95_, v96_ in pairs(PlaceableConfigurationItemColor.DEFAULT_COLORS) do
			local v97_, v98_ = g_vehicleMaterialManager:getMaterialTemplateColorAndTitleByName(v96_, customEnvironment)
			if v97_ ~= nil then
				local v99_ = PlaceableConfigurationItemColor.new(configName)
				v99_.name = v98_ or v99_.name
				if v95_ == v93_ then
					v99_.isDefault = true
					v99_.price = 0
				else
					v99_.price = v94_
				end
				v99_.name = v99_.name or v98_
				v99_.color = v97_
				v99_.uiColor = v97_
				v99_.saveId = v96_
				table.insert(configurationItems, v99_)
				v99_:setIndex(#configurationItems)
			end
		end
		local v100_ = PlaceableConfigurationItemColor.new(configName)
		v100_.name = g_i18n:getText("ui_colorPicker_custom")
		v100_.price = v94_
		v100_.color = {
			1,
			1,
			1,
			1
		}
		v100_.uiColor = {
			1,
			1,
			1,
			1
		}
		v100_.materialTemplateName = "calibratedPaint"
		v100_.isCustomColor = true
		v100_.isSelectable = false
		v100_.saveId = "CUSTOM_COLOR"
		table.insert(configurationItems, v100_)
		v100_:setIndex(#configurationItems)
	end
	if v93_ == nil then
		local v101_ = false
		for _, v102_ in ipairs(configurationItems) do
			if v102_.isDefault ~= nil and v102_.isDefault then
				v101_ = true
			end
		end
		if not v101_ and #configurationItems > 0 then
			configurationItems[1].isDefault = true
			configurationItems[1].price = 0
		end
	end
end

-- Local values: numManualConfigs, _, config, configIndex, brandMaterialName, _, config
function PlaceableConfigurationItemColor.getFallbackConfigId(configs, configId, configName, configFileName)
	local v105_ = 0
	for _, v106_ in pairs(configs) do
		if v106_.isManualConfig then
			v105_ = v105_ + 1
		end
	end
	local v107_ = tonumber(configId)
	if v107_ == nil then
		return nil, nil
	end
	if v105_ < v107_ then
		local v108_ = PlaceableConfigurationItemColor.DEFAULT_COLORS_PATCH_1_2[v107_ - v105_]
		for _, v109_ in pairs(configs) do
			if v109_.saveId == v108_ then
				return v109_.index, v109_.saveId
			end
		end
	end
	return nil, nil
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
PlaceableConfigurationItemColor.DEFAULT_COLORS = {
	"SHARED_WHITE2",
	"SHARED_BEIGE",
	"SHARED_SILVER",
	"SHARED_GREYLIGHT",
	"SHARED_GREY",
	"SHARED_GREYDARK",
	"SHARED_BLACKONYX",
	"SHARED_BLACKJET",
	"JOHNDEERE_YELLOW1",
	"JCB_YELLOW1",
	"CHALLENGER_YELLOW1",
	"SCHOUTEN_ORANGE1",
	"FENDT_RED1",
	"CASEIH_RED1",
	"MASSEYFERGUSON_RED",
	"HARDI_RED",
	"NEWHOLLAND_BLUE2",
	"RABE_BLUE1",
	"LEMKEN_BLUE1",
	"NEWHOLLAND_BLUE1",
	"BOECKMANN_BLUE1",
	"GOLDHOFER_BLUE",
	"SHARED_BLUENAVY",
	"LIZARD_PURPLE1",
	"VALTRA_GREEN2",
	"DEUTZ_GREEN5",
	"JOHNDEERE_GREEN1",
	"FENDT_NEWGREEN1",
	"FENDT_OLDGREEN1",
	"KOTTE_GREEN2",
	"CLAAS_GREEN1",
	"LIZARD_OLIVE1",
	"LIZARD_ECRU1",
	"SHARED_BROWN",
	"SHARED_REDCRIMSON",
	"LIZARD_PINK1"
}
PlaceableConfigurationItemColor.DEFAULT_COLORS_PATCH_1_2 = {
	"SHARED_WHITE2",
	"SHARED_BEIGE",
	"SHARED_SILVER",
	"SHARED_GREYLIGHT",
	"SHARED_GREY",
	"SHARED_GREYDARK",
	"SHARED_BLACKONYX",
	"SHARED_BLACKJET",
	"JOHNDEERE_YELLOW1",
	"JCB_YELLOW1",
	"CHALLENGER_YELLOW1",
	"SCHOUTEN_ORANGE1",
	"FENDT_RED1",
	"CASEIH_RED1",
	"MASSEYFERGUSON_RED",
	"HARDI_RED",
	"NEWHOLLAND_BLUE2",
	"RABE_BLUE1",
	"LEMKEN_BLUE1",
	"NEWHOLLAND_BLUE1",
	"BOECKMANN_BLUE1",
	"GOLDHOFER_BLUE",
	"SHARED_BLUENAVY",
	"LIZARD_PURPLE1",
	"VALTRA_GREEN2",
	"DEUTZ_GREEN5",
	"JOHNDEERE_GREEN1",
	"FENDT_NEWGREEN1",
	"FENDT_OLDGREEN1",
	"KOTTE_GREEN2",
	"CLAAS_GREEN1",
	"LIZARD_OLIVE1",
	"LIZARD_ECRU1",
	"SHARED_BROWN",
	"SHARED_REDCRIMSON",
	"LIZARD_PINK1"
}
