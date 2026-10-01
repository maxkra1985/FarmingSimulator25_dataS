source("dataS/scripts/fillTypes/FillTypeDesc.lua")
FillType = nil
FillTypeCategory = nil
FillTypeManager = {}
FillTypeManager.FILLTYPE_START_TOTAL_AMOUNT = 50000
FillTypeManager.SEND_NUM_BITS = 8
FillTypeManager.MASS_SCALE = 1
g_xmlManager:addCreateSchemaFunction(function()
	FillTypeManager.xmlSchema = XMLSchema.new("fillTypes")
end)
g_xmlManager:addInitSchemaFunction(function()
	FillTypeManager.registerXMLPaths(FillTypeManager.xmlSchema, "map")
end)
function FillTypeManager.registerXMLPaths(schema, basePath)
	FillTypeDesc.registerXMLPaths(schema, basePath .. ".fillTypes.fillType(?)")
	local fillTypeCategoryKey = basePath .. ".fillTypeCategories.fillTypeCategory(?)"
	schema:register(XMLValueType.STRING, fillTypeCategoryKey .. "#name", "Name of category")
	schema:register(XMLValueType.STRING_LIST, fillTypeCategoryKey, "list of fillTypes, space separated")
	local fillTypeConverterKey = basePath .. ".fillTypeConverters.fillTypeConverter(?)"
	schema:register(XMLValueType.STRING, fillTypeConverterKey .. "#name", "Converter name")
	schema:register(XMLValueType.STRING, fillTypeConverterKey .. ".converter(?)#from", "From fill type")
	schema:register(XMLValueType.STRING, fillTypeConverterKey .. ".converter(?)#to", "To fill type")
	schema:register(XMLValueType.FLOAT, fillTypeConverterKey .. ".converter(?)#factor", "Multiplied by factor")
	local fillTypeSoundKey = basePath .. ".fillTypeSounds.fillTypeSound(?)"
	SoundManager.registerSampleXMLPaths(schema, fillTypeSoundKey, "sound")
	schema:register(XMLValueType.STRING_LIST, fillTypeSoundKey .. "#fillTypes", "list of fillTypes, space separated")
	schema:register(XMLValueType.BOOL, fillTypeSoundKey .. "#isDefault", "Is default sound", false)
end
function FillTypeManager.registerConfigXMLFilltypes(schema, basePath, fillTypesKey, fillTypeCategoriesKey, fillTypesExcludeKey)
	schema:register(XMLValueType.STRING_LIST, basePath .. (fillTypesKey or "#fillTypes"), "list of fillTypes, space separated")
	schema:register(XMLValueType.STRING_LIST, basePath .. (fillTypeCategoriesKey or "#fillTypeCategories"), "list of fillType category names, space separated")
	schema:register(XMLValueType.STRING_LIST, basePath .. (fillTypesExcludeKey or "#fillTypesExclude"), "list of fillType category names, space separated")
end
local FillTypeManager_mt = Class(FillTypeManager, AbstractManager)
function FillTypeManager.new(customMt)
	local self = AbstractManager.new(customMt or FillTypeManager_mt)
	return self
end
function FillTypeManager:initDataStructures()
	self.fillTypes = {}
	self.nameToFillType = {}
	self.indexToFillType = {}
	self.nameToIndex = {}
	self.indexToName = {}
	self.indexToTitle = {}
	self.fillTypeConverters = {}
	self.converterNameToIndex = {}
	self.nameToConverter = {}
	self.categories = {}
	self.nameToCategoryIndex = {}
	self.categoryIndexToFillTypes = {}
	self.categoryNameToFillTypes = {}
	self.fillTypeIndexToCategories = {}
	self.fillTypeSamples = {}
	self.fillTypeToSample = {}
	self.modsToLoad = {}
	FillType = self.nameToIndex
	FillTypeCategory = self.categories
end
function FillTypeManager:loadDefaultTypes()
	local xmlFile = loadXMLFile("fillTypes", "data/maps/maps_fillTypes.xml")
	self:loadFillTypes(xmlFile, nil, true, nil, false)
	delete(xmlFile)
end
function FillTypeManager:loadMapData(xmlFile, missionInfo, baseDirectory)
	FillTypeManager:superClass().loadMapData(self)
	self:loadDefaultTypes()
	if XMLUtil.loadDataFromMapXML(xmlFile, "fillTypes", baseDirectory, self, self.loadFillTypes, baseDirectory, false, missionInfo.customEnvironment, false) then
		for _, fillType in ipairs(self.fillTypes) do
			fillType:finalize()
		end
		return true
	else
		return false
	end
end
function FillTypeManager:addModWithFillTypes(xmlFilename, baseDirectory, customEnvironment)
	table.insert(self.modsToLoad, { xmlFilename, baseDirectory, customEnvironment })
end
function FillTypeManager:loadModFillTypes()
	if 0 < #self.modsToLoad then
		for _, data in ipairs(self.modsToLoad) do
			local xmlFilename, baseDirectoryMod, customEnvironment = unpack(data)
			local fillTypesXMLFile = XMLFile.load("fillTypes", xmlFilename, FillTypeManager.xmlSchema)
			if fillTypesXMLFile == nil then
				continue
			end
			local numFillTypes = #self.fillTypes
			g_fillTypeManager:loadFillTypes(fillTypesXMLFile, baseDirectoryMod, false, customEnvironment, false)
			fillTypesXMLFile:delete()
			local numLoadedFillTypes = #self.fillTypes - numFillTypes
			if 0 < numLoadedFillTypes then
				Logging.info("Loaded %d fill types from mod: %s", numLoadedFillTypes, customEnvironment)
			end
		end
		for _, fillType in ipairs(self.fillTypes) do
			fillType:finalize()
		end
	end
end
function FillTypeManager:unloadMapData()
	for _, sample in pairs(self.fillTypeSamples) do
		g_soundManager:deleteSample(sample.sample)
	end
	for _, fillTypeDesc in pairs(self.fillTypes) do
		fillTypeDesc:delete()
	end
	FillTypeManager:superClass().unloadMapData(self)
end
function FillTypeManager:loadFillTypes(xmlFile, baseDirectory, isBaseType, customEnv, finalizeType)
	if xmlFile == nil or xmlFile == 0 then
		return false
	end
	if type(xmlFile) ~= "table" then
		xmlFile = XMLFile.wrap(xmlFile, FillTypeManager.xmlSchema)
	end
	local rootName = xmlFile:getRootName()
	if isBaseType then
		local unknownFillType = FillTypeDesc.new()
		unknownFillType.economy.sychronizeData = false
		self:addFillType(unknownFillType)
	end
	for _, ftKey in xmlFile:iterator(rootName .. ".fillTypes.fillType") do
		local name = xmlFile:getValue(ftKey .. "#name")
		if name == nil then
			continue
		end
		name = string.upper(name)
		if isBaseType then
			if self.nameToFillType[name] ~= nil then
				Logging.warning("FillType '%s' already exists. Ignoring fillType!", name)
			else
				local fillTypeDesc = self.nameToFillType[name]
				if fillTypeDesc == nil then
					fillTypeDesc = FillTypeDesc.new()
				end
				if fillTypeDesc:loadFromXMLFile(xmlFile, ftKey, baseDirectory, customEnv) then
					if self.nameToFillType[name] == nil then
						self:addFillType(fillTypeDesc)
					end
					if finalizeType == true then
						fillTypeDesc:finalize()
					end
				end
			end
		end
	end
	for _, ftCategoryKey in xmlFile:iterator(rootName .. ".fillTypeCategories.fillTypeCategory") do
		local name = xmlFile:getValue(ftCategoryKey .. "#name")
		local fillTypesList = xmlFile:getValue(ftCategoryKey)
		local fillTypeCategoryIndex = self:addFillTypeCategory(name, isBaseType)
		if fillTypesList == nil or fillTypeCategoryIndex == nil then
			continue
		end
		for _, fillTypeName in ipairs(fillTypesList) do
			local fillType = self:getFillTypeByName(fillTypeName)
			if fillType ~= nil then
				if self:addFillTypeToCategory(fillType.index, fillTypeCategoryIndex) then
					continue
				end
				Logging.warning("Could not add fillType '" .. tostring(fillTypeName) .. "' to fillTypeCategory '" .. tostring(name) .. "'!")
			else
				Logging.warning("Unknown FillType '" .. tostring(fillTypeName) .. "' in fillTypeCategory '" .. tostring(name) .. "'!")
			end
		end
	end
	for _, ftConverterKey in xmlFile:iterator(rootName .. ".fillTypeConverters.fillTypeConverter") do
		local name = xmlFile:getValue(ftConverterKey .. "#name")
		local converter = self:addFillTypeConverter(name, isBaseType)
		if converter == nil then
			continue
		end
		for _, converterRuleKey in xmlFile:iterator(ftConverterKey .. ".converter") do
			local from = xmlFile:getValue(converterRuleKey .. "#from")
			local to = xmlFile:getValue(converterRuleKey .. "#to")
			local factor = xmlFile:getValue(converterRuleKey .. "#factor")
			local sourceFillType = g_fillTypeManager:getFillTypeByName(from)
			local targetFillType = g_fillTypeManager:getFillTypeByName(to)
			if sourceFillType == nil or targetFillType == nil or factor == nil then
				continue
			end
			self:addFillTypeConversion(converter, sourceFillType.index, targetFillType.index, factor)
		end
	end
	for _, fillTypeSoundKey in xmlFile:iterator(rootName .. ".fillTypeSounds.fillTypeSound") do
		local sample = g_soundManager:loadSampleFromXML(xmlFile, fillTypeSoundKey, "sound", baseDirectory, getRootNode(), 0, AudioGroup.VEHICLE, nil, nil)
		if sample == nil then
			continue
		end
		local entry = { sample = sample }
		entry.fillTypes = {}
		local fillTypes = xmlFile:getValue(fillTypeSoundKey .. "#fillTypes")
		if fillTypes ~= nil then
			for _, fillTypeName in ipairs(fillTypes) do
				local fillType = self:getFillTypeIndexByName(fillTypeName)
				if fillType ~= nil then
					table.insert(entry.fillTypes, fillType)
					self.fillTypeToSample[fillType] = sample
				else
					Logging.xmlWarning(xmlFile, "Unable to load fill type '%s' for fillTypeSound '%s'", fillTypeName, fillTypeSoundKey)
				end
			end
		end
		if xmlFile:getValue(fillTypeSoundKey .. "#isDefault") then
			for fillType, _ in ipairs(self.fillTypes) do
				if self.fillTypeToSample[fillType] == nil then
					self.fillTypeToSample[fillType] = sample
				end
			end
		end
		table.insert(self.fillTypeSamples, entry)
	end
	return true
end
function FillTypeManager:addFillType(fillTypeDesc)
	local maxNumFillTypes = 2 ^ FillTypeManager.SEND_NUM_BITS - 1
	if maxNumFillTypes <= #self.fillTypes then
		Logging.error("FillTypeManager.addFillType too many fill types. Only %d fill types are supported. Ignoring '%s'.", maxNumFillTypes, fillTypeDesc.name)
		return false
	else
		fillTypeDesc.index = #self.fillTypes + 1
		self.nameToFillType[fillTypeDesc.name] = fillTypeDesc
		self.nameToIndex[fillTypeDesc.name] = fillTypeDesc.index
		self.indexToName[fillTypeDesc.index] = fillTypeDesc.name
		self.indexToTitle[fillTypeDesc.index] = fillTypeDesc.title
		self.indexToFillType[fillTypeDesc.index] = fillTypeDesc
		table.insert(self.fillTypes, fillTypeDesc)
		return true
	end
end
function FillTypeManager:assignFillTypeTextureArraysFromTerrain(nodeId, terrainRootNodeId, diffuse, normal, height)
	local material = getMaterial(nodeId, 0)
	material = setTerrainFillPlanesToMaterial(terrainRootNodeId, material, diffuse, normal, height)
	if material ~= nil then
		setMaterial(nodeId, material, 0)
	end
end
function FillTypeManager:assignCustomFillTypeTextureArraysFromTerrain(nodeId, terrainRootNodeId, diffuse, normal, height)
	local material = getMaterial(nodeId, 0)
	material = setTerrainFillPlanesToMaterialCustom(terrainRootNodeId, material, diffuse, normal, height)
	if material ~= nil then
		setMaterial(nodeId, material, 0)
	end
end
function FillTypeManager:constructTerrainFillLayers(heightTypes, terrainRootNodeId)
	clearTerrainFillLayers(terrainRootNodeId)
	local curIndex = 1
	for i = 1, #heightTypes do
		local heightType = heightTypes[i]
		local fillType = self.fillTypes[heightType.fillTypeIndex]
		if fillType ~= nil and fillType:addTerrainFillLayer(terrainRootNodeId, curIndex) then
			curIndex = curIndex + 1
			if heightType.visualHeightMapping ~= nil then
				for i = 1, #heightType.visualHeightMapping do
					local mapping = heightType.visualHeightMapping[i]
					local nextMapping = heightType.visualHeightMapping[i + 1]
					if nextMapping ~= nil then
						setTerrainFillVisualHeight(g_currentMission.terrainDetailHeightId, fillType.textureArrayIndex, mapping.realValue, mapping.visualValue, nextMapping.realValue, nextMapping.visualValue)
					else
						setTerrainFillVisualHeight(g_currentMission.terrainDetailHeightId, fillType.textureArrayIndex, mapping.realValue, mapping.visualValue, nil, nil)
					end
				end
			end
		end
	end
	finalizeTerrainFillLayers(terrainRootNodeId)
	return true
end
function FillTypeManager:constructFillTypeDistanceTextureArray(terrainDetailHeightId, typeFirstChannel, typeNumChannels, heightTypes)
	local distanceConstr = TerrainDetailDistanceConstructor.new(typeFirstChannel, typeNumChannels)
	for i = 1, #heightTypes do
		local heightType = heightTypes[i]
		local fillType = self.fillTypes[heightType.fillTypeIndex]
		if fillType == nil then
			continue
		end
		fillType:addDistanceTexture(distanceConstr, i - 1)
	end
	return distanceConstr:finalize(terrainDetailHeightId)
end
function FillTypeManager:getTextureArrayIndexByFillTypeIndex(index)
	local fillType = self.fillTypes[index]
	return fillType and fillType.textureArrayIndex
end
function FillTypeManager:getPrioritizedEffectTypeByFillTypeIndex(index)
	local fillType = self.fillTypes[index]
	return fillType and fillType.prioritizedEffectType
end
function FillTypeManager:getSmokeColorByFillTypeIndex(index, fruitColor)
	local fillType = self.fillTypes[index]
	if fillType ~= nil then
		if not fruitColor then
			return fillType.fillSmokeColor
		else
			return fillType.fruitSmokeColor or fillType.fillSmokeColor
		end
	end
	return nil
end
function FillTypeManager:getFillTypeByIndex(index)
	return self.fillTypes[index]
end
function FillTypeManager:getFillTypeNameByIndex(index)
	return self.indexToName[index]
end
function FillTypeManager:getFillTypeTitleByIndex(index)
	return self.indexToTitle[index]
end
function FillTypeManager:getFillTypeNamesByIndices(indices)
	local names = {}
	for fillTypeIndex in pairs(indices) do
		table.insert(names, self.indexToName[fillTypeIndex])
	end
	return names
end
function FillTypeManager:getFillTypeIndexByName(name)
	return self.nameToIndex[name and string.upper(name)]
end
function FillTypeManager:getFillTypeByName(name)
	if ClassUtil.getIsValidIndexName(name) then
		return self.nameToFillType[string.upper(name)]
	else
		return nil
	end
end
function FillTypeManager:getFillTypes()
	return self.fillTypes
end
function FillTypeManager:addFillTypeCategory(name, isBaseType)
	if not ClassUtil.getIsValidIndexName(name) then
		printWarning("Warning: '" .. tostring(name) .. "' is not a valid name for a fillTypeCategory. Ignoring fillTypeCategory!")
		return nil
	else
		name = string.upper(name)
		if isBaseType and self.nameToCategoryIndex[name] ~= nil then
			printWarning("Warning: FillTypeCategory '" .. tostring(name) .. "' already exists. Ignoring fillTypeCategory!")
			return nil
		end
		local index = self.nameToCategoryIndex[name]
		if index == nil then
			local categoryFillTypes = {}
			index = #self.categories + 1
			table.insert(self.categories, name)
			self.categoryNameToFillTypes[name] = categoryFillTypes
			self.categoryIndexToFillTypes[index] = categoryFillTypes
			self.nameToCategoryIndex[name] = index
		end
		return index
	end
end
function FillTypeManager:addFillTypeToCategory(fillTypeIndex, categoryIndex)
	if categoryIndex ~= nil and (fillTypeIndex ~= nil and self.categoryIndexToFillTypes[categoryIndex] ~= nil) then
		self.categoryIndexToFillTypes[categoryIndex][fillTypeIndex] = true
		if self.fillTypeIndexToCategories[fillTypeIndex] == nil then
			self.fillTypeIndexToCategories[fillTypeIndex] = {}
		end
		self.fillTypeIndexToCategories[fillTypeIndex][categoryIndex] = true
		return true
	end
	return false
end
function FillTypeManager:getFillTypesByCategoryNames(names, warning, fillTypes)
	fillTypes = fillTypes or {}
	if names ~= nil then
		return self:getFillTypesByCategoryNamesList(string.split(names, " "), warning, fillTypes)
	else
		return fillTypes
	end
end
function FillTypeManager:getFillTypesByCategoryNamesList(categoryNamesList, warning, fillTypes)
	fillTypes = fillTypes or {}
	if categoryNamesList ~= nil then
		for _, categoryName in pairs(categoryNamesList) do
			local categoryName = string.upper(categoryName)
			local categoryFillTypes = self.categoryNameToFillTypes[categoryName]
			if categoryFillTypes ~= nil then
				for fillType, _ in pairs(categoryFillTypes) do
					if table.hasElement(fillTypes, fillType) then
						continue
					end
					table.insert(fillTypes, fillType)
				end
			else
				if warning == nil then
					continue
				end
				printWarning(string.format(warning, categoryName))
			end
		end
	end
	return fillTypes
end
function FillTypeManager:getFillTypeNamesByCategoryNamesList(categoryNamesList, warning)
	local fillTypeNames = {}
	if categoryNamesList ~= nil then
		for _, categoryName in pairs(categoryNamesList) do
			local categoryName = string.upper(categoryName)
			local categoryFillTypeIndices = self.categoryNameToFillTypes[categoryName]
			if categoryFillTypeIndices ~= nil then
				for fillTypeIndex, _ in pairs(categoryFillTypeIndices) do
					local fillType = self.indexToFillType[fillTypeIndex]
					if table.hasElement(fillTypeNames, fillType.name) then
						continue
					end
					table.insert(fillTypeNames, fillType.name)
				end
			else
				if warning == nil then
					continue
				end
				printWarning(string.format(warning, categoryName))
			end
		end
	end
	return fillTypeNames
end
function FillTypeManager:getIsFillTypeInCategory(fillTypeIndex, categoryName)
	local catgegoy = self.nameToCategoryIndex[categoryName]
	if catgegoy ~= nil and self.fillTypeIndexToCategories[fillTypeIndex] then
		return self.fillTypeIndexToCategories[fillTypeIndex][catgegoy] ~= nil
	end
	return false
end
function FillTypeManager:getFillTypesByNames(names, warning, fillTypes)
	fillTypes = fillTypes or {}
	if names ~= nil then
		local fillTypeNames = string.split(names, " ")
		for _, name in pairs(fillTypeNames) do
			local name = string.upper(name)
			local fillTypeIndex = self.nameToIndex[name]
			if fillTypeIndex ~= nil then
				if fillTypeIndex == FillType.UNKNOWN or table.hasElement(fillTypes, fillTypeIndex) then
					continue
				end
				table.insert(fillTypes, fillTypeIndex)
			else
				if warning == nil then
					continue
				end
				printWarning(string.format(warning, name))
			end
		end
	end
	return fillTypes
end
function FillTypeManager:getFillTypesFromXML(xmlFile, categoryKey, namesKey, requiresFillTypes)
	local fillTypes = {}
	local fillTypeCategories = xmlFile:getValue(categoryKey)
	local fillTypeNames = xmlFile:getValue(namesKey)
	if fillTypeCategories ~= nil and fillTypeNames == nil then
		fillTypes = g_fillTypeManager:getFillTypesByCategoryNames(fillTypeCategories, "Warning: '" .. xmlFile:getFilename() .. "' has invalid fillTypeCategory '%s'.")
		return fillTypes
	end
	if fillTypeCategories == nil and fillTypeNames ~= nil then
		fillTypes = g_fillTypeManager:getFillTypesByNames(fillTypeNames, "Warning: '" .. xmlFile:getFilename() .. "' has invalid fillType '%s'.")
		return fillTypes
	end
	if fillTypeCategories ~= nil and fillTypeNames ~= nil then
		Logging.xmlWarning(xmlFile, "fillTypeCategories and fillTypeNames are both set, only one of the two allowed")
		return fillTypes
	end
	if requiresFillTypes ~= nil and requiresFillTypes then
		Logging.xmlWarning(xmlFile, "either the '%s' or '%s' attribute has to be set", categoryKey, namesKey)
	end
	return fillTypes
end
function FillTypeManager:loadCombinedFillTypesFromConfig(xmlFile, key, fillTypesKey, fillTypeCategoriesKey, fillTypesExcludeKey)
	local fillTypeNames = xmlFile:getValue(key .. (fillTypesKey or "#fillTypes")) or {}
	local fillTypeCategories = xmlFile:getValue(key .. (fillTypeCategoriesKey or "#fillTypeCategories"))
	local fillTypeNamesExclude = xmlFile:getValue(key .. (fillTypesExcludeKey or "#fillTypesExclude"))
	if fillTypeCategories ~= nil then
		local fillTypeNamesFromCategories = self:getFillTypeNamesByCategoryNamesList(fillTypeCategories)
		fillTypeNames = table.getListUnion(fillTypeNames, fillTypeNamesFromCategories)
	end
	if #fillTypeNames == 0 then
		return nil
	end
	local fillTypeNamesSet = table.toSet(fillTypeNames)
	if fillTypeNamesExclude ~= nil then
		fillTypeNamesSet = table.getSetSubtraction(fillTypeNamesSet, table.toSet(fillTypeNamesExclude))
	end
	if table.size(fillTypeNamesSet) == 0 then
		return nil
	else
		local fillTypes = {}
		for fillTypeName in pairs(fillTypeNamesSet) do
			table.insert(fillTypes, g_fillTypeManager:getFillTypeIndexByName(fillTypeName, "Warning: invalid fillType %q at '" .. key .. "'"))
		end
		return fillTypes
	end
end
function FillTypeManager:addFillTypeConverter(name, isBaseType)
	if not ClassUtil.getIsValidIndexName(name) then
		printWarning("Warning: '" .. tostring(name) .. "' is not a valid name for a fillTypeConverter. Ignoring fillTypeConverter!")
		return nil
	else
		name = string.upper(name)
		if isBaseType and self.nameToConverter[name] ~= nil then
			printWarning("Warning: FillTypeConverter '" .. tostring(name) .. "' already exists. Ignoring FillTypeConverter!")
			return nil
		end
		local index = self.converterNameToIndex[name]
		if index == nil then
			local converter = {}
			table.insert(self.fillTypeConverters, converter)
			self.converterNameToIndex[name] = #self.fillTypeConverters
			self.nameToConverter[name] = converter
			index = #self.fillTypeConverters
		end
		return index
	end
end
function FillTypeManager:addFillTypeConversion(converter, sourceFillTypeIndex, targetFillTypeIndex, conversionFactor)
	if converter ~= nil and (self.fillTypeConverters[converter] ~= nil and (sourceFillTypeIndex ~= nil and targetFillTypeIndex ~= nil)) then
		self.fillTypeConverters[converter][sourceFillTypeIndex] = { targetFillTypeIndex = targetFillTypeIndex, conversionFactor = conversionFactor }
	end
end
function FillTypeManager:getConverterDataByName(converterName)
	return self.nameToConverter[converterName and string.upper(converterName)]
end
function FillTypeManager:getSampleByFillType(fillType)
	return self.fillTypeToSample[fillType]
end
g_fillTypeManager = FillTypeManager.new()
