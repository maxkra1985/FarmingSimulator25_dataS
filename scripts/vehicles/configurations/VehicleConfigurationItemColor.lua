-- Local values: VehicleConfigurationItemColor_mt
VehicleConfigurationItemColor = {}
VehicleConfigurationItemColor.SELECTOR = ConfigurationUtil.SELECTOR_COLOR
local VehicleConfigurationItemColor_mt = Class(VehicleConfigurationItemColor, VehicleConfigurationItem)

-- Upvalues: VehicleConfigurationItemColor_mt
-- Local values: self
function VehicleConfigurationItemColor.new(configName, customMt)
	-- upvalues: (copy) VehicleConfigurationItemColor_mt
	local v3_ = VehicleConfigurationItemColor:superClass().new(configName, VehicleConfigurationItemColor_mt)
	v3_.isCustomColor = false
	v3_.isManualConfig = false
	return v3_
end

-- Local values: colorStr, color, title, color, title
function VehicleConfigurationItemColor:loadFromXML(xmlFile, baseKey, configKey, baseDirectory, customEnvironment)
	if not VehicleConfigurationItemColor:superClass().loadFromXML(self, xmlFile, baseKey, configKey, baseDirectory, customEnvironment) then
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
	self.customEnvironment = customEnvironment
	self.materialTemplateName = xmlFile:getValue(configKey .. "#materialTemplateName")
	self.isMetallic = xmlFile:getValue(configKey .. "#isMetallic", false)
	self.isMat = xmlFile:getValue(configKey .. "#isMat", false)
	if self.materialTemplateName ~= nil then
		local v13_, v14_ = g_vehicleMaterialManager:getMaterialTemplateColorAndTitleByName(self.materialTemplateName, customEnvironment)
		if v13_ == nil then
			Logging.xmlWarning(xmlFile, "Material template \'%s\' not defined for \'%s\'", self.materialTemplateName, configKey)
		else
			self.color = self.color or v13_
			if self.hasDefaultName then
				self.name = v14_ or self.name
			end
			if string.contains(string.lower(self.materialTemplateName), "chrome") then
				self.isMetallic = true
				self.uiColor = { 0.3, 0.3, 0.3 }
			elseif string.contains(string.lower(self.materialTemplateName), "silver") then
				self.uiColor = { 0.4, 0.4, 0.4 }
			end
		end
	end
	if self.color == nil then
		self.color = { 1, 1, 1 }
	end
	self.uiColor = self.uiColor or self.color
	self.isManualConfig = true
	return true
end

function VehicleConfigurationItemColor:saveToXMLFile(xmlFile, key, isActive, configurationData)
	VehicleConfigurationItemColor:superClass().saveToXMLFile(self, xmlFile, key, isActive, configurationData)
	if self.isCustomColor then
		if configurationData.color ~= nil then
			xmlFile:setValue(key .. "#color", configurationData.color[1], configurationData.color[2], configurationData.color[3])
		end
		if configurationData.materialTemplateName ~= nil then
			xmlFile:setValue(key .. "#materialTemplateName", configurationData.materialTemplateName)
		end
	end
end

function VehicleConfigurationItemColor:loadFromSavegameXMLFile(xmlFile, key, configurationData)
	VehicleConfigurationItemColor:superClass().loadFromSavegameXMLFile(self, xmlFile, key, configurationData)
	if self.isCustomColor then
		configurationData.color = xmlFile:getValue(key .. "#color", nil, true)
		configurationData.materialTemplateName = xmlFile:getValue(key .. "#materialTemplateName")
	end
end

-- Local values: r, g, b, templateIndex
function VehicleConfigurationItemColor:readFromStream(streamId, connection, configurationData)
	if self.isCustomColor then
		local v27_, v28_, v29_ = NetworkUtil.readCompressedColor(streamId)
		configurationData.color = { v27_, v28_, v29_ }
		local v30_ = streamReadUIntN(streamId, VehicleMaterialManager.NUM_BITS_TEMPLATE)
		configurationData.materialTemplateName = g_vehicleMaterialManager:getMaterialTemplateNameByIndex(v30_)
	end
end

-- Local values: r, g, b, templateIndex
function VehicleConfigurationItemColor:writeToStream(streamId, connection, configurationData)
	if self.isCustomColor then
		local v34_, v35_, v36_
		if configurationData.color == nil then
			v34_ = 1
			v35_ = 1
			v36_ = 1
		else
			v34_ = configurationData.color[1]
			v35_ = configurationData.color[2]
			v36_ = configurationData.color[3]
		end
		NetworkUtil.writeCompressedColor(streamId, v34_, v35_, v36_)
		local v37_ = g_vehicleMaterialManager:getMaterialTemplateIndexByName(configurationData.materialTemplateName)
		local v38_ = streamWriteUIntN
		local v39_ = VehicleMaterialManager.MAX_TEMPLATE_INDEX
		v38_(streamId, math.clamp(v37_, 0, v39_), VehicleMaterialManager.NUM_BITS_TEMPLATE)
	end
end

function VehicleConfigurationItemColor:hasDataChanged(configurationData1, configurationData2)
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
		local v43_ = configurationData1.color[1] - configurationData2.color[1]
		if math.abs(v43_) <= 0.00001 then
			local v44_ = configurationData1.color[2] - configurationData2.color[2]
			if math.abs(v44_) <= 0.00001 then
				local v45_ = configurationData1.color[3] - configurationData2.color[3]
				if math.abs(v45_) <= 0.00001 then
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

-- Local values: color, materialTemplateName
function VehicleConfigurationItemColor:updateMaterial(vehicle)
	if self.material == nil or self.isCustomColor then
		self.material = VehicleMaterial.new()
		local v48_, v49_ = self:getColorAndMaterialFromVehicle(vehicle)
		if v49_ ~= nil then
			self.material:setTemplateName(v49_, nil, self.customEnvironment)
		end
		self.material:setColor(v48_)
	end
end

function VehicleConfigurationItemColor:getColor()
	return { self.color[1], self.color[2], self.color[3] }
end

function VehicleConfigurationItemColor:getMaterial(vehicle)
	self:updateMaterial(vehicle)
	return self.material
end

function VehicleConfigurationItemColor:onSizeLoad(xmlFile, sizeData)
	if self.configKey ~= "" then
		VehicleConfigurationItemColor:superClass().onSizeLoad(self, xmlFile, sizeData)
	end
end

-- Local values: color, materialTemplateName, data, configurationData
function VehicleConfigurationItemColor:getColorAndMaterialFromVehicle(vehicle)
	local v58_ = self.color
	local v59_ = self.materialTemplateName
	local v60_ = vehicle.configurationData[self.configName]
	if v60_ ~= nil then
		local v61_ = v60_[self.index]
		if v61_ ~= nil then
			if v61_.color ~= nil then
				v58_ = v61_.color
			end
			if v61_.materialTemplateName ~= nil then
				v59_ = v61_.materialTemplateName
			end
		end
	end
	return v58_, v59_
end

-- Local values: configurationDesc
function VehicleConfigurationItemColor:onPostLoad(object, configId)
	VehicleConfigurationItemColor:superClass().onPostLoad(self, object, configId)
	local v65_ = g_vehicleConfigurationManager:getConfigurationDescByName(self.configName)
	object.xmlFile:iterate(v65_.configurationsKey .. ".material", function(_, p66_)
		-- upvalues: (copy) object, (copy) self
		local v67_ = VehicleMaterial.new(object.baseDirectory)
		local v68_, v69_ = self:getColorAndMaterialFromVehicle(object)
		if object.xmlFile:getValue(p66_ .. "#useContrastColor", false) then
			if object.xmlFile:getValue(p66_ .. "#contrastThreshold", 0.5) < MathUtil.getBrightnessFromColor(v68_[1], v68_[2], v68_[3]) then
				v68_ = object.xmlFile:getValue(p66_ .. "#contrastColorDark", "0 0 0", true)
			else
				v68_ = object.xmlFile:getValue(p66_ .. "#contrastColorBright", "0.9 0.9 0.9", true)
			end
		end
		if object.xmlFile:getValue(p66_ .. "#materialTemplateName", nil) == nil then
			if not object.xmlFile:getValue(p66_ .. "#materialTemplateUseColorOnly", false) then
				v67_:setTemplateName(v69_, nil, object.customEnvironment)
			end
			v67_:setColor(v68_)
		end
		v67_:loadFromXML(object.xmlFile, p66_, object.customEnvironment)
		if v67_.targetMaterialSlotName == nil then
			Logging.xmlWarning(object.xmlFile, "Missing material slot name in \'%s\'", p66_)
		elseif not v67_:applyToVehicle(object) then
			Logging.xmlWarning(object.xmlFile, "Failed to find material by material slot name \'%s\' in \'%s\'", v67_.targetMaterialSlotName, p66_)
			return
		end
	end)
end

-- Local values: defaultColorIndex, price, defaultColorMaterialTemplateName, _, configItem, i, brandMaterialName, color, title, configItem, configItem, defaultIsDefined, _, configItem
function VehicleConfigurationItemColor.postLoad(xmlFile, baseKey, baseDir, customEnvironment, isMod, configurationItems, storeItem, configName)
	VehicleConfigurationItemColor:superClass().postLoad(xmlFile, baseKey, baseDir, customEnvironment, isMod, configurationItems, storeItem, configName)
	local v78_ = xmlFile:getValue(baseKey .. "#defaultColorIndex")
	if xmlFile:getValue(baseKey .. "#useDefaultColors", false) or g_modIsLoaded.FS25_unlimitedColorConfigurations and #configurationItems > 0 then
		local v79_ = xmlFile:getValue(baseKey .. "#price", 0)
		local v80_ = xmlFile:getValue(baseKey .. "#defaultColorMaterialTemplateName", "calibratedPaint")
		for _, v81_ in ipairs(configurationItems) do
			if v81_.materialTemplateName == nil then
				v81_.materialTemplateName = v80_
			end
		end
		for v82_, v83_ in pairs(VehicleConfigurationItemColor.DEFAULT_COLORS) do
			local v84_, v85_ = g_vehicleMaterialManager:getMaterialTemplateColorAndTitleByName(v83_, customEnvironment)
			if v84_ ~= nil then
				local v86_ = VehicleConfigurationItemColor.new(configName)
				v86_.name = v85_ or v86_.name
				if v82_ == v78_ then
					v86_.isDefault = true
					v86_.price = 0
				else
					v86_.price = v79_
				end
				v86_.color = v84_
				v86_.uiColor = v84_
				v86_.materialTemplateName = v80_
				v86_.isMetallic = false
				v86_.isMat = false
				v86_.saveId = v83_
				table.insert(configurationItems, v86_)
				v86_:setIndex(#configurationItems)
			end
		end
		local v87_ = VehicleConfigurationItemColor.new(configName)
		v87_.name = g_i18n:getText("ui_colorPicker_custom")
		v87_.price = v79_
		v87_.color = {
			1,
			1,
			1,
			1
		}
		v87_.uiColor = {
			1,
			1,
			1,
			1
		}
		v87_.materialTemplateName = "calibratedPaint"
		v87_.isCustomColor = true
		v87_.isSelectable = false
		v87_.isMetallic = false
		v87_.isMat = false
		v87_.saveId = "CUSTOM_COLOR"
		table.insert(configurationItems, v87_)
		v87_:setIndex(#configurationItems)
	end
	if v78_ == nil then
		local v88_ = false
		for _, v89_ in ipairs(configurationItems) do
			if v89_.isDefault ~= nil and v89_.isDefault then
				v88_ = true
			end
		end
		if not v88_ and #configurationItems > 0 then
			configurationItems[1].isDefault = true
			configurationItems[1].price = 0
		end
	end
end

-- Local values: numManualConfigs, _, config, configIndex, brandMaterialName, _, config
function VehicleConfigurationItemColor.getFallbackConfigId(configs, configId, configName, configFileName)
	local v92_ = 0
	for _, v93_ in pairs(configs) do
		if v93_.isManualConfig then
			v92_ = v92_ + 1
		end
	end
	local v94_ = tonumber(configId)
	if v94_ == nil then
		return nil, nil
	end
	if v92_ < v94_ then
		local v95_ = VehicleConfigurationItemColor.DEFAULT_COLORS_PATCH_1_2[v94_ - v92_]
		for _, v96_ in pairs(configs) do
			if v96_.saveId == v95_ then
				return v96_.index, v96_.saveId
			end
		end
	end
	return nil, nil
end

-- Local values: configId, item, configItems, config
function VehicleConfigurationItemColor.getMaterialByColorConfiguration(vehicle, configName)
	local v99_ = vehicle.configurations[configName]
	if v99_ ~= nil then
		local v100_ = g_storeManager:getItemByXMLFilename(vehicle.configFileName)
		if v100_.configurations ~= nil then
			local v101_ = v100_.configurations[configName]
			if v101_ ~= nil then
				local v102_ = v101_[v99_]
				if v102_ ~= nil and v102_:isa(VehicleConfigurationItemColor) then
					return v102_:getMaterial(vehicle)
				end
			end
		end
	end
	return nil
end

function VehicleConfigurationItemColor.registerXMLPaths(schema, rootPath, configPath)
	VehicleConfigurationItemColor:superClass().registerXMLPaths(schema, rootPath, configPath)
	schema:register(XMLValueType.INT, rootPath .. "#defaultColorIndex", "Default color index on start")
	schema:register(XMLValueType.BOOL, rootPath .. "#useDefaultColors", "Use default colors", false)
	schema:register(XMLValueType.INT, rootPath .. "#price", "Price of the default colors", 0)
	schema:register(XMLValueType.STRING, rootPath .. "#defaultColorMaterialTemplateName", "Base template for all default colors and for configs that have just a \'color\' attribute defined", "calibratedPaint")
	VehicleMaterial.registerXMLPaths(schema, rootPath .. ".material(?)")
	schema:register(XMLValueType.BOOL, rootPath .. ".material(?)#useContrastColor", "Use contrast color", false)
	schema:register(XMLValueType.FLOAT, rootPath .. ".material(?)#contrastThreshold", "Color brightness threshold to switch to contrast color", 0.5)
	schema:register(XMLValueType.COLOR, rootPath .. ".material(?)#contrastColorDark", "Color to be used when the brightness is below the threshold", "0 0 0")
	schema:register(XMLValueType.COLOR, rootPath .. ".material(?)#contrastColorBright", "Color to be used when the brightness is above the threshold", "0.9 0.9 0.9")
	schema:register(XMLValueType.STRING, configPath .. "#color", "Configuration color", "1 1 1 1")
	schema:register(XMLValueType.COLOR, configPath .. "#uiColor", "Configuration UI color", "1 1 1 1")
	schema:register(XMLValueType.BOOL, configPath .. "#isMetallic", "Color is metallic color (Only for UI)", false)
	schema:register(XMLValueType.BOOL, configPath .. "#isMat", "Color is mat color (Only for UI)", false)
	schema:register(XMLValueType.STRING, configPath .. "#materialTemplateName", "Name of material template to use")
end

function VehicleConfigurationItemColor.registerSavegameXMLPaths(schema, basePath)
	VehicleConfigurationItemColor:superClass().registerSavegameXMLPaths(schema, basePath)
	schema:register(XMLValueType.VECTOR_3, basePath .. "#color", "Configuration color", "1 1 1")
	schema:register(XMLValueType.STRING, basePath .. "#materialTemplateName", "Name of material template to use")
end
VehicleConfigurationItemColor.DEFAULT_COLORS = {
	"SHARED_WHITE2",
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
VehicleConfigurationItemColor.DEFAULT_COLORS_PATCH_1_2 = {
	"SHARED_WHITE2",
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
