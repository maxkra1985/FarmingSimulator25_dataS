source("dataS/scripts/fruits/FruitTypeDesc.lua")
FruitType = nil
FruitTypeCategory = nil
FruitTypeConverter = nil
FruitTypeManager = {}
FruitTypeManager.SEND_NUM_BITS = 6
g_xmlManager:addCreateSchemaFunction(function()
	FruitTypeManager.xmlSchema = XMLSchema.new("fruitTypes")
end)
g_xmlManager:addInitSchemaFunction(function()
	FruitTypeManager.registerXMLPaths(FruitTypeManager.xmlSchema, "map")
	FruitTypeManager.registerXMLPaths(Mission00.xmlSchema, "map")
end)
function FruitTypeManager.registerXMLPaths(schema, key)
	schema:register(XMLValueType.STRING, key .. ".fruitTypes.fruitType(?)#filename", "")
	local fruitTypeCategoriesKey = key .. ".fruitTypeCategories.fruitTypeCategory(?)"
	schema:register(XMLValueType.STRING, fruitTypeCategoriesKey .. "#name", "")
	schema:register(XMLValueType.STRING, fruitTypeCategoriesKey, "")
	local fruitTypeConverterssKey = key .. ".fruitTypeConverters.fruitTypeConverter(?)"
	schema:register(XMLValueType.STRING, fruitTypeConverterssKey .. "#name", "")
	schema:register(XMLValueType.STRING, fruitTypeConverterssKey .. ".converter(?)#from", "")
	schema:register(XMLValueType.STRING, fruitTypeConverterssKey .. ".converter(?)#to", "")
	schema:register(XMLValueType.FLOAT, fruitTypeConverterssKey .. ".converter(?)#factor", "")
end
local FruitTypeManager_mt = Class(FruitTypeManager, AbstractManager)
function FruitTypeManager.new(customMt)
	local self = AbstractManager.new(customMt or FruitTypeManager_mt)
	addConsoleCommand("gsFruitTypesExportStats", "Exports the fruit type stats into a text file", "consoleCommandExportStats", self)
	return self
end
function FruitTypeManager:initDataStructures()
	self.fruitTypes = {}
	self.indexToFruitType = {}
	self.nameToIndex = {}
	self.nameToFruitType = {}
	self.fruitTypeIndexToFillType = {}
	self.fillTypeIndexToFruitTypeIndex = {}
	self.densityTypeIndexToFruitType = {}
	self.filenameToFruitType = {}
	self.fruitTypeConverters = {}
	self.fruitTypeConverterLoadData = {}
	self.converterNameToIndex = {}
	self.nameToConverter = {}
	self.windrowFillTypes = {}
	self.fruitTypeIndexToWindrowFillTypeIndex = {}
	self.windrowCutFillTypeIndexToFruitTypeIndex = {}
	self.modFoliageTypesToLoad = {}
	self.numCategories = 0
	self.categories = {}
	self.indexToCategory = {}
	self.categoryIndexToFruitTypeIndex = {}
	FruitType = self.nameToIndex
	FruitType.UNKNOWN = 0
	FruitTypeCategory = self.categories
	FruitTypeConverter = self.converterNameToIndex
	self.defaultDataPlaneId = nil
end
function FruitTypeManager:loadDefaultTypes()
	local xmlFile = loadXMLFile("fuitTypes", "data/maps/maps_fruitTypes.xml")
	self:loadFruitTypes(xmlFile, nil, "", true)
	delete(xmlFile)
end
function FruitTypeManager:loadMapData(xmlFileHandle, missionInfo, baseDirectory)
	FruitTypeManager:superClass().loadMapData(self)
	self.modFruitTypes = {}
	XMLUtil.loadDataFromMapXML(xmlFileHandle, "fruitTypes", baseDirectory, self, self.loadMapFruitTypes, missionInfo, baseDirectory)
	self:loadDefaultTypes()
	XMLUtil.loadDataFromMapXML(xmlFileHandle, "fruitTypes", baseDirectory, self, self.loadMapCategoriesAndConverters, missionInfo, baseDirectory)
	self:initializeFruitTypeConverters()
	return true
end
function FruitTypeManager:loadMapFruitTypes(xmlFileHandle, missionInfo, baseDirectory)
	local xmlFile = XMLFile.wrap(xmlFileHandle)
	local rootName = xmlFile:getRootName()
	for _, key in xmlFile:iterator(rootName .. ".fruitTypes.fruitType") do
		local filename = xmlFile:getString(key .. "#filename")
		if filename == nil then
			continue
		end
		filename = Utils.getFilename(filename, baseDirectory)
		local fruitTypeDesc = FruitTypeDesc.new()
		if fruitTypeDesc:loadFromFoliageXMLFile(filename) then
			table.insert(self.modFruitTypes, fruitTypeDesc)
		end
	end
	xmlFile:delete()
end
function FruitTypeManager:loadFruitTypeFromXML(xmlFilename)
	local fruitTypeDesc = FruitTypeDesc.new()
	if fruitTypeDesc:loadFromFoliageXMLFile(xmlFilename) then
		self:addFruitType(fruitTypeDesc)
	end
end
function FruitTypeManager:loadMapCategoriesAndConverters(xmlFileHandle, missionInfo, baseDirectory)
	local xmlFile = XMLFile.wrap(xmlFileHandle)
	local rootName = xmlFile:getRootName()
	self:loadCategoriesFromXML(xmlFile, rootName, false)
	self:loadConvertersFromXML(xmlFile, rootName, false)
	xmlFile:delete()
end
function FruitTypeManager:initializeFruitTypeConverters()
	for converter, converterData in pairs(self.fruitTypeConverterLoadData) do
		if self.fruitTypeConverters[converter] == nil then
			continue
		end
		for _, data in ipairs(converterData) do
			local fruitType = self:getFruitTypeByName(data.fruitTypeName)
			local fillType = g_fillTypeManager:getFillTypeByName(data.fillTypeName)
			if fruitType == nil or fillType == nil then
				continue
			end
			self.fruitTypeConverters[converter][fruitType.index] = { fillTypeIndex = fillType.index, conversionFactor = data.conversionFactor }
		end
	end
	self.fruitTypeConverterLoadData = {}
end
function FruitTypeManager:addFruitType(fruitTypeDesc)
	Logging.info("Loaded fruit type '%s' from '%s'", fruitTypeDesc.name, fruitTypeDesc.xmlFilename)
	table.insert(self.fruitTypes, fruitTypeDesc)
	fruitTypeDesc.index = #self.fruitTypes
	self.nameToFruitType[fruitTypeDesc.name] = fruitTypeDesc
	self.nameToIndex[fruitTypeDesc.name] = fruitTypeDesc.index
	self.indexToFruitType[fruitTypeDesc.index] = fruitTypeDesc
	self.filenameToFruitType[fruitTypeDesc.xmlFilename] = fruitTypeDesc
	self.fillTypeIndexToFruitTypeIndex[fruitTypeDesc.fillType.index] = fruitTypeDesc.index
	self.fruitTypeIndexToFillType[fruitTypeDesc.index] = fruitTypeDesc.fillType
	local windrowFillType = fruitTypeDesc.windrowFillType
	if windrowFillType ~= nil then
		self.windrowFillTypes[windrowFillType.index] = true
		self.fruitTypeIndexToWindrowFillTypeIndex[fruitTypeDesc.index] = windrowFillType.index
		self.fillTypeIndexToFruitTypeIndex[windrowFillType.index] = fruitTypeDesc.index
	end
	if fruitTypeDesc.windrowCutFillType ~= nil then
		self.windrowCutFillTypeIndexToFruitTypeIndex[fruitTypeDesc.windrowCutFillType.index] = fruitTypeDesc.index
	end
end
function FruitTypeManager:loadFruitTypes(xmlFileHandle, missionInfo, baseDirectory, isBaseType)
	local xmlFile = XMLFile.wrap(xmlFileHandle)
	local rootName = xmlFile:getRootName()
	local maxNumFruitTypes = 2 ^ FruitTypeManager.SEND_NUM_BITS - 1
	for _, key in xmlFile:iterator(rootName .. ".fruitTypes.fruitType") do
		if maxNumFruitTypes <= #self.fruitTypes then
			Logging.xmlError(xmlFile, "FruitTypeManager.loadFruitTypes: too many fruit types. Only %d fruit types are supported", maxNumFruitTypes)
			break
		end
		local filename = xmlFile:getString(key .. "#filename")
		if filename ~= nil then
			filename = Utils.getFilename(filename, baseDirectory)
			local fruitTypeDesc = FruitTypeDesc.new()
			if fruitTypeDesc:loadFromFoliageXMLFile(filename) then
				if self.modFruitTypes ~= nil then
					for k, modFruitTypeDesc in ipairs(self.modFruitTypes) do
						if modFruitTypeDesc.name == fruitTypeDesc.name then
							fruitTypeDesc:delete()
							fruitTypeDesc = modFruitTypeDesc
							table.remove(self.modFruitTypes, k)
							break
						end
					end
				end
				self:addFruitType(fruitTypeDesc)
			end
		else
			Logging.xmlWarning(xmlFile, "FruitTypeManager.loadFruitTypes: Missing fruit type filename for '%s'", key)
		end
	end
	if self.modFruitTypes ~= nil then
		for _, modFruitTypeDesc in ipairs(self.modFruitTypes) do
			self:addFruitType(modFruitTypeDesc)
		end
	end
	self.modFruitTypes = nil
	self:loadCategoriesFromXML(xmlFile, rootName, isBaseType)
	self:loadConvertersFromXML(xmlFile, rootName, isBaseType)
	xmlFile:delete()
end
function FruitTypeManager:loadCategoriesFromXML(xmlFile, rootName, isBaseType)
	for _, key in xmlFile:iterator(rootName .. ".fruitTypeCategories.fruitTypeCategory") do
		local name = xmlFile:getString(key .. "#name")
		local fruitTypesStr = xmlFile:getString(key)
		local fruitTypeCategoryIndex = self:addFruitTypeCategory(name, isBaseType)
		if fruitTypeCategoryIndex == nil then
			continue
		end
		local fruitTypeNames = string.split(fruitTypesStr, " ")
		for _, fruitTypeName in ipairs(fruitTypeNames) do
			local fruitType = self:getFruitTypeByName(fruitTypeName)
			if fruitType ~= nil then
				if self:addFruitTypeToCategory(fruitType.index, fruitTypeCategoryIndex) then
					continue
				end
				Logging.xmlWarning(xmlFile, "FruitTypeManager.loadFruitTypes: Could not add fruitType '%s' to fruitTypeCategory '%s'!", fruitTypeName, name)
			else
				Logging.xmlWarning(xmlFile, "FruitTypeManager.loadFruitTypes: FruitType '%s' referenced in fruitTypeCategory '%s' is not defined!", fruitTypeName, name)
			end
		end
	end
end
function FruitTypeManager:loadConvertersFromXML(xmlFile, rootName, isBaseType)
	for _, key in xmlFile:iterator(rootName .. ".fruitTypeConverters.fruitTypeConverter") do
		local name = xmlFile:getString(key .. "#name")
		local converter = self:addFruitTypeConverter(name, isBaseType)
		if converter == nil then
			continue
		end
		for _, converterKey in xmlFile:iterator(key .. ".converter") do
			local from = xmlFile:getString(converterKey .. "#from")
			local to = xmlFile:getString(converterKey .. "#to")
			local factor = xmlFile:getFloat(converterKey .. "#factor", 1)
			self:addFruitTypeConversion(converter, from, to, factor)
		end
	end
end
function FruitTypeManager:getFruitTypeByIndex(index)
	return self.indexToFruitType[index]
end
function FruitTypeManager:getFruitTypeNameByIndex(index)
	local fruitType = self.indexToFruitType[index]
	if fruitType ~= nil then
		return fruitType.name
	elseif index == FruitType.UNKNOWN then
		return "UNKNOWN"
	else
		return nil
	end
end
function FruitTypeManager:getFruitTypeByName(name)
	if name == nil then
		return nil
	else
		return self.nameToFruitType[string.upper(name)]
	end
end
function FruitTypeManager:getFruitTypeIndexByName(name)
	local fruitType = self:getFruitTypeByName(name)
	if fruitType ~= nil then
		return fruitType.index
	else
		return nil
	end
end
function FruitTypeManager:getFruitTypes()
	return self.fruitTypes
end
function FruitTypeManager:getFruitTypeIndexByFillTypeIndex(index)
	return self.fillTypeIndexToFruitTypeIndex[index]
end
function FruitTypeManager:getFruitTypeByFillTypeIndex(index)
	return self.fruitTypes[self.fillTypeIndexToFruitTypeIndex[index]]
end
function FruitTypeManager:getFillTypeIndexByFruitTypeIndex(index)
	local fillType = self.fruitTypeIndexToFillType[index]
	if fillType ~= nil then
		return fillType.index
	else
		return nil
	end
end
function FruitTypeManager:getFillTypeByFruitTypeIndex(index)
	return self.fruitTypeIndexToFillType[index]
end
function FruitTypeManager:getFillTypeNameByFruitTypeIndex(index)
	return self.fruitTypeIndexToFillType[index] and fillTypeIndex.name or nil
end
function FruitTypeManager:getCutHeightByFruitTypeIndex(index, isForageCutter)
	local fruitType = self.indexToFruitType[index]
	if isForageCutter then
		return fruitType.cutHeight
	else
		return fruitType and fruitType.cutHeight or 0.15
	end
end
function FruitTypeManager:getFruitTypeAreaLiters(fruitTypeIndex, area, useWindrow)
	local fruitType = self.indexToFruitType[fruitTypeIndex]
	if fruitType ~= nil then
		return fruitType:getAreaLiters(area, useWindrow)
	else
		return 0
	end
end
function FruitTypeManager:addFruitTypeCategory(name, isBaseType)
	if not ClassUtil.getIsValidIndexName(name) then
		printWarning("Warning: '" .. tostring(name) .. "' is not a valid name for a fruitTypeCategory. Ignoring fruitTypeCategory!")
		return nil
	else
		name = string.upper(name)
		if isBaseType and self.categories[name] ~= nil then
			printWarning("Warning: FruitTypeCategory '" .. tostring(name) .. "' already exists. Ignoring fruitTypeCategory!")
			return nil
		end
		local index = self.categories[name]
		if index == nil then
			self.numCategories = self.numCategories + 1
			self.categories[name] = self.numCategories
			self.indexToCategory[self.numCategories] = name
			self.categoryIndexToFruitTypeIndex[self.numCategories] = {}
			index = self.numCategories
		end
		return index
	end
end
function FruitTypeManager:addFruitTypeToCategory(fruitTypeIndex, categoryIndex)
	if categoryIndex ~= nil and fruitTypeIndex ~= nil then
		table.insert(self.categoryIndexToFruitTypeIndex[categoryIndex], fruitTypeIndex)
		return true
	end
	return false
end
function FruitTypeManager:getFruitTypesByCategoryNames(names, warning)
	local fruitTypes = {}
	local alreadyAdded = {}
	local categories = string.split(names, " ")
	for _, categoryName in pairs(categories) do
		local categoryName = string.upper(categoryName)
		local categoryIndex = self.categories[categoryName]
		local categoryFruitTypeIndices = self.categoryIndexToFruitTypeIndex[categoryIndex]
		if categoryFruitTypeIndices ~= nil then
			for _, fruitTypeIndex in ipairs(categoryFruitTypeIndices) do
				local fruitType = self.indexToFruitType[fruitTypeIndex]
				if alreadyAdded[fruitType] == nil then
					table.insert(fruitTypes, fruitType)
					alreadyAdded[fruitType] = true
				end
			end
		else
			if warning == nil then
				continue
			end
			printWarning(string.format(warning, categoryName))
		end
	end
	return fruitTypes
end
function FruitTypeManager:getFruitTypeIndicesByCategoryNames(names, warning)
	local fruitTypes = self:getFruitTypesByCategoryNames(names, warning)
	for index, fruitType in ipairs(fruitTypes) do
		fruitTypes[index] = fruitType.index
	end
	return fruitTypes
end
function FruitTypeManager:getFruitTypesByNames(names, warning)
	local fruitTypes = {}
	local alreadyAdded = {}
	local fruitTypeNames = string.split(names, " ")
	for _, name in pairs(fruitTypeNames) do
		local name = string.upper(name)
		local fruitType = self.nameToFruitType[name]
		if fruitType ~= nil then
			if alreadyAdded[fruitType] == nil then
				table.insert(fruitTypes, fruitType)
				alreadyAdded[fruitType] = true
			end
		else
			if warning == nil then
				continue
			end
			printWarning(string.format(warning, name))
		end
	end
	return fruitTypes
end
function FruitTypeManager:getFruitTypeIndicesByNames(names, warning)
	local fruitTypes = self:getFruitTypesByNames(names, warning)
	for index, fruitType in ipairs(fruitTypes) do
		fruitTypes[index] = fruitType.index
	end
	return fruitTypes
end
function FruitTypeManager:getFillTypesByFruitTypeNames(names, warning)
	local fillTypes = {}
	local alreadyAdded = {}
	local fruitTypeNames = string.split(names, " ")
	for _, name in pairs(fruitTypeNames) do
		local fillType = nil
		local fruitType = self:getFruitTypeByName(name)
		if fruitType ~= nil then
			fillType = self:getFillTypeByFruitTypeIndex(fruitType.index)
		end
		if fillType ~= nil then
			if alreadyAdded[fillType] == nil then
				table.insert(fillTypes, fillType)
				alreadyAdded[fillType] = true
			end
		else
			if warning == nil then
				continue
			end
			printWarning(string.format(warning, name))
		end
	end
	return fillTypes
end
function FruitTypeManager:getFillTypeIndicesByFruitTypeNames(names, warning)
	local fillTypes = self:getFillTypesByFruitTypeNames(names, warning)
	for index, fillType in ipairs(fillTypes) do
		fillTypes[index] = fillType.index
	end
	return fillTypes
end
function FruitTypeManager:getFillTypesByFruitTypeCategoryNames(fruitTypeCategoryNames, warning)
	local fillTypes = {}
	local alreadyAdded = {}
	local categories = string.split(fruitTypeCategoryNames, " ")
	for _, categoryName in pairs(categories) do
		local categoryName = string.upper(categoryName)
		local category = self.categories[categoryName]
		if category ~= nil then
			for _, fruitTypeIndex in ipairs(self.categoryIndexToFruitTypeIndex[category]) do
				local fillType = self:getFillTypeByFruitTypeIndex(fruitTypeIndex)
				if fillType == nil then
					continue
				end
				if alreadyAdded[fillType] == nil then
					table.insert(fillTypes, fillType)
					alreadyAdded[fillType] = true
				end
			end
		else
			if warning == nil then
				continue
			end
			printWarning(string.format(warning, categoryName))
		end
	end
	return fillTypes
end
function FruitTypeManager:getFillTypeIndicesByFruitTypeCategoryName(fruitTypeCategoryNames, warning)
	local fillTypes = self:getFillTypesByFruitTypeCategoryNames(fruitTypeCategoryNames, warning)
	for index, fillType in ipairs(fillTypes) do
		fillTypes[index] = fillType.index
	end
	return fillTypes
end
function FruitTypeManager:isFillTypeWindrow(index)
	if index ~= nil then
		return self.windrowFillTypes[index] == true
	else
		return false
	end
end
function FruitTypeManager:getWindrowFillTypeIndexByFruitTypeIndex(index)
	return self.fruitTypeIndexToWindrowFillTypeIndex[index]
end
function FruitTypeManager:getFillTypeLiterPerSqm(fillTypeIndex, defaultValue)
	local fruitType = self.fruitTypes[self:getFruitTypeIndexByFillTypeIndex(fillTypeIndex)]
	if fruitType ~= nil then
		if fruitType.hasWindrow then
			return fruitType.windrowLiterPerSqm
		else
			return fruitType.literPerSqm
		end
	end
	return defaultValue
end
function FruitTypeManager:getCutWindrowHarvestFillLevel(fillTypeIndex, liters)
	local fruitTypeIndex = self.windrowCutFillTypeIndexToFruitTypeIndex[fillTypeIndex]
	if fruitTypeIndex ~= nil then
		local fruitType = self.indexToFruitType[fruitTypeIndex]
		if fruitType ~= nil then
			if fruitType.windrowLiterPerSqm ~= nil then
				liters = liters / fruitType.windrowLiterPerSqm
			end
			return liters * fruitType.literPerSqm * fruitType.windrowCutFactor
		end
	end
	return liters
end
function FruitTypeManager:addFruitTypeConverter(name, isBaseType)
	if not ClassUtil.getIsValidIndexName(name) then
		printWarning("Warning: '" .. tostring(name) .. "' is not a valid name for a fruitTypeConverter. Ignoring fruitTypeConverter!")
		return nil
	else
		name = string.upper(name)
		if isBaseType and self.converterNameToIndex[name] ~= nil then
			printWarning("Warning: FruitTypeConverter '" .. tostring(name) .. "' already exists. Ignoring fruitTypeConverter!")
			return nil
		end
		local index = self.converterNameToIndex[name]
		if index == nil then
			local converter = {}
			table.insert(self.fruitTypeConverters, converter)
			self.converterNameToIndex[name] = #self.fruitTypeConverters
			self.nameToConverter[name] = converter
			index = #self.fruitTypeConverters
		end
		return index
	end
end
function FruitTypeManager:addFruitTypeConversion(converter, fruitTypeName, fillTypeName, conversionFactor)
	if converter ~= nil then
		if self.fruitTypeConverterLoadData[converter] == nil then
			self.fruitTypeConverterLoadData[converter] = {}
		end
		table.insert(self.fruitTypeConverterLoadData[converter], { fruitTypeName = fruitTypeName, fillTypeName = fillTypeName, conversionFactor = conversionFactor })
	end
end
function FruitTypeManager:getConverterDataByName(converterName)
	return self.nameToConverter[converterName and string.upper(converterName)]
end
function FruitTypeManager:addModFoliageType(name, filename)
	table.insert(self.modFoliageTypesToLoad, { name = name, filename = filename })
end
function FruitTypeManager:getDefaultDataPlaneId()
	return self.defaultDataPlaneId
end
function FruitTypeManager:addTerrainDataPlane(dataPlaneId)
	if self.defaultDataPlaneId == nil then
		self.defaultDataPlaneId = dataPlaneId
	end
end
function FruitTypeManager:getFirstHaulmFruitType()
	return self.firstHaulmFruitTypeDesc
end
function FruitTypeManager:addHaulmFruitType(fruitTypeDesc)
	if self.firstHaulmFruitTypeDesc == nil then
		self.firstHaulmFruitTypeDesc = fruitTypeDesc
	end
end
function FruitTypeManager:setTerrainDataPlaneIndex(fruitType, terrainDataPlaneIndex)
	self.densityTypeIndexToFruitType[terrainDataPlaneIndex] = fruitType
end
function FruitTypeManager:getFruitTypeByDensityTypeIndex(densityTypeIndex)
	return self.densityTypeIndexToFruitType[densityTypeIndex]
end
function FruitTypeManager:consoleCommandExportStats()
	local content = ""
	for _, fruitTypeDesc in ipairs(self.fruitTypes) do
		content = content .. fruitTypeDesc:getStatsText() .. "\n"
	end
	content = content .. "\n"
	content = content .. "\n"
	content = content .. "Weeder / How States\n"
	content = content .. " Name          "
	for i = 1, 9 do
		content = content .. string.format("[  %d  ] ", i)
	end
	content = content .. "\n"
	for _, fruitTypeDesc in ipairs(self.fruitTypes) do
		content = content .. fruitTypeDesc:getWeedingStateText() .. "\n"
	end
	local profilePath = getUserProfileAppPath()
	local filename = profilePath .. "fruitTypeStats.txt"
	local file = io.open(filename, "w")
	file:write(content)
	file:close()
	Logging.info("Fruit type stats exported to %s", filename)
end
function FruitTypeManager.convert(xmlFile, key)
	local name = xmlFile:getString(key .. "#name")
	local convert = function(path, removeAttributes)
		local foliageXml = XMLFile.load("foliage", path)
		if foliageXml ~= nil then
			FruitTypeManager.convertFruitType(name, xmlFile, key, foliageXml, removeAttributes)
			foliageXml:save()
			foliageXml:delete()
		end
	end
	if name == "meadow" then
		local path = "data/foliage/" .. name .. "/" .. name .. "DLC.xml"
		local foliageXml = XMLFile.load("foliage", path)
		if foliageXml ~= nil then
			FruitTypeManager.convertFruitType(name, xmlFile, key, foliageXml, false)
			foliageXml:save()
			foliageXml:delete()
		end
		local path = "data/foliage/" .. name .. "/" .. name .. "US.xml"
		local foliageXml = XMLFile.load("foliage", path)
		if foliageXml ~= nil then
			FruitTypeManager.convertFruitType(name, xmlFile, key, foliageXml, false)
			foliageXml:save()
			foliageXml:delete()
		end
		local path = "data/foliage/" .. name .. "/" .. name .. "FR.xml"
		local foliageXml = XMLFile.load("foliage", path)
		if foliageXml ~= nil then
			FruitTypeManager.convertFruitType(name, xmlFile, key, foliageXml, true)
			foliageXml:save()
			foliageXml:delete()
		end
	else
		local path = "data/foliage/" .. name .. "/" .. name .. ".xml"
		local foliageXml = XMLFile.load("foliage", path)
		if foliageXml ~= nil then
			FruitTypeManager.convertFruitType(name, xmlFile, key, foliageXml, true)
			foliageXml:save()
			foliageXml:delete()
		end
	end
	xmlFile:setString(key .. "#filename", "$data/foliage/" .. name .. "/" .. name .. ".xml")
	xmlFile:save()
end
function FruitTypeManager:convertFruitType(name, xmlFile, key, foliageXMLFile, removeProperties)
	local cultivationStates = {}
	local hasCultivationStates = false
	for k, cultivationKey in xmlFile:iterator(key .. ".cultivation.state") do
		local cultivationState = xmlFile:getInt(cultivationKey .. "#state")
		cultivationStates[cultivationState] = true
		hasCultivationStates = true
	end
	local stateNames = {}
	for k, stateKey in foliageXMLFile:iterator("foliageType.foliageLayer.foliageState") do
		local stateName = foliageXMLFile:getString(stateKey .. "#name")
		local parts = string.split(stateName, " ")
		local newName = table.remove(parts, 1)
		local numParts = #parts
		for i = 1, numParts do
			local nextPart = table.remove(parts, 1)
			local firstChar = string.sub(nextPart, 1, 1)
			local remainingChars = string.sub(nextPart, 2)
			newName = newName .. string.upper(firstChar) .. remainingChars
		end
		stateNames[k] = newName
		foliageXMLFile:setString(stateKey .. "#name", newName)
		if hasCultivationStates then
			if cultivationStates[k] then
				continue
			end
			foliageXMLFile:setBool(stateKey .. "#isCultivatable", false)
		end
	end
	local removeAttribute = function(path)
		if removeProperties then
			xmlFile:removeProperty(path)
		end
	end
	local copyAttribute = function(oldPath, newPath)
		if xmlFile:hasProperty(oldPath) then
			foliageXMLFile:setString(newPath, xmlFile:getString(oldPath))
			if removeProperties then
				xmlFile:removeProperty(oldPath)
			end
		end
	end
	local oldPath = key .. "#name"
	if xmlFile:hasProperty(oldPath) then
		foliageXMLFile:setString("foliageType.fruitType#name", xmlFile:getString(oldPath))
		if removeProperties then
			xmlFile:removeProperty(oldPath)
		end
	end
	local oldPath = key .. ".cultivation#alignsToSun"
	if xmlFile:hasProperty(oldPath) then
		foliageXMLFile:setString("foliageType.foliageLayer(0)#alignsToSun", xmlFile:getString(oldPath))
		if removeProperties then
			xmlFile:removeProperty(oldPath)
		end
	end
	local oldPath = key .. "#shownOnMap"
	if xmlFile:hasProperty(oldPath) then
		foliageXMLFile:setString("foliageType.fruitType#shownOnMap", xmlFile:getString(oldPath))
		if removeProperties then
			xmlFile:removeProperty(oldPath)
		end
	end
	local oldPath = key .. "#useForFieldJob"
	if xmlFile:hasProperty(oldPath) then
		foliageXMLFile:setString("foliageType.fruitType#useForFieldMissions", xmlFile:getString(oldPath))
		if removeProperties then
			xmlFile:removeProperty(oldPath)
		end
	end
	local oldPath = key .. ".mapColors#default"
	if xmlFile:hasProperty(oldPath) then
		foliageXMLFile:setString("foliageType.fruitType.mapColors#default", xmlFile:getString(oldPath))
		if removeProperties then
			xmlFile:removeProperty(oldPath)
		end
	end
	local oldPath = key .. ".mapColors#colorBlind"
	if xmlFile:hasProperty(oldPath) then
		foliageXMLFile:setString("foliageType.fruitType.mapColors#colorBlind", xmlFile:getString(oldPath))
		if removeProperties then
			xmlFile:removeProperty(oldPath)
		end
	end
	local oldPath = key .. ".windrow#name"
	if xmlFile:hasProperty(oldPath) then
		foliageXMLFile:setString("foliageType.fruitType.windrow#fillType", xmlFile:getString(oldPath))
		if removeProperties then
			xmlFile:removeProperty(oldPath)
		end
	end
	local oldPath = key .. ".windrow#litersPerSqm"
	if xmlFile:hasProperty(oldPath) then
		foliageXMLFile:setString("foliageType.fruitType.windrow#litersPerSqm", xmlFile:getString(oldPath))
		if removeProperties then
			xmlFile:removeProperty(oldPath)
		end
	end
	local oldPath = key .. ".harvest#literPerSqm"
	if xmlFile:hasProperty(oldPath) then
		foliageXMLFile:setString("foliageType.fruitType.harvest#litersPerSqm", xmlFile:getString(oldPath))
		if removeProperties then
			xmlFile:removeProperty(oldPath)
		end
	end
	local oldPath = key .. ".harvest#cutHeight"
	if xmlFile:hasProperty(oldPath) then
		foliageXMLFile:setString("foliageType.fruitType.harvest#cutHeight", xmlFile:getString(oldPath))
		if removeProperties then
			xmlFile:removeProperty(oldPath)
		end
	end
	local oldPath = key .. ".harvest#chopperTypeName"
	if xmlFile:hasProperty(oldPath) then
		foliageXMLFile:setString("foliageType.fruitType.harvest#chopperTypeName", xmlFile:getString(oldPath))
		if removeProperties then
			xmlFile:removeProperty(oldPath)
		end
	end
	local oldPath = key .. ".growth#resetsSpray"
	if xmlFile:hasProperty(oldPath) then
		foliageXMLFile:setString("foliageType.fruitType.growth#resetsSpray", xmlFile:getString(oldPath))
		if removeProperties then
			xmlFile:removeProperty(oldPath)
		end
	end
	local oldPath = key .. ".growth#growthRequiresLime"
	if xmlFile:hasProperty(oldPath) then
		foliageXMLFile:setString("foliageType.fruitType.growth#growthRequiresLime", xmlFile:getString(oldPath))
		if removeProperties then
			xmlFile:removeProperty(oldPath)
		end
	end
	local oldPath = key .. ".options#lowSoilDensityRequired"
	if xmlFile:hasProperty(oldPath) then
		foliageXMLFile:setString("foliageType.fruitType.soil#lowDensityRequired", xmlFile:getString(oldPath))
		if removeProperties then
			xmlFile:removeProperty(oldPath)
		end
	end
	local oldPath = key .. ".options#increasesSoilDensity"
	if xmlFile:hasProperty(oldPath) then
		foliageXMLFile:setString("foliageType.fruitType.soil#increasesDensity", xmlFile:getString(oldPath))
		if removeProperties then
			xmlFile:removeProperty(oldPath)
		end
	end
	local oldPath = key .. ".options#consumesLime"
	if xmlFile:hasProperty(oldPath) then
		foliageXMLFile:setString("foliageType.fruitType.soil#consumesLime", xmlFile:getString(oldPath))
		if removeProperties then
			xmlFile:removeProperty(oldPath)
		end
	end
	local oldPath = key .. ".cultivation#directionSnapAngle"
	if xmlFile:hasProperty(oldPath) then
		foliageXMLFile:setString("foliageType.fruitType.seeding#directionSnapAngle", xmlFile:getString(oldPath))
		if removeProperties then
			xmlFile:removeProperty(oldPath)
		end
	end
	local oldPath = key .. ".cultivation#needsRolling"
	if xmlFile:hasProperty(oldPath) then
		foliageXMLFile:setString("foliageType.fruitType.seeding#needsRolling", xmlFile:getString(oldPath))
		if removeProperties then
			xmlFile:removeProperty(oldPath)
		end
	end
	local oldPath = key .. ".cultivation#seedUsagePerSqm"
	if xmlFile:hasProperty(oldPath) then
		foliageXMLFile:setString("foliageType.fruitType.seeding#litersPerSqm", xmlFile:getString(oldPath))
		if removeProperties then
			xmlFile:removeProperty(oldPath)
		end
	end
	local oldPath = key .. ".cultivation#allowsSeeding"
	if xmlFile:hasProperty(oldPath) then
		foliageXMLFile:setString("foliageType.fruitType.seeding#isAvailable", xmlFile:getString(oldPath))
		if removeProperties then
			xmlFile:removeProperty(oldPath)
		end
	end
	local oldPath = key .. ".cultivation#plantsWeed"
	if xmlFile:hasProperty(oldPath) then
		foliageXMLFile:setString("foliageType.fruitType.seeding#plantsWeed", xmlFile:getString(oldPath))
		if removeProperties then
			xmlFile:removeProperty(oldPath)
		end
	end
	local oldPath = key .. ".harvest#forageCutHeight"
	if xmlFile:hasProperty(oldPath) then
		foliageXMLFile:setString("foliageType.fruitType.harvest#forageCutHeight", xmlFile:getString(oldPath))
		if removeProperties then
			xmlFile:removeProperty(oldPath)
		end
	end
	local oldPath = key .. ".harvest#beeYieldBonusPercentage"
	if xmlFile:hasProperty(oldPath) then
		foliageXMLFile:setString("foliageType.fruitType.harvest#beeYieldBonusPercentage", xmlFile:getString(oldPath))
		if removeProperties then
			xmlFile:removeProperty(oldPath)
		end
	end
	local oldPath = key .. ".harvest#chopperType"
	if xmlFile:hasProperty(oldPath) then
		foliageXMLFile:setString("foliageType.fruitType.harvest#chopperGroundType", xmlFile:getString(oldPath))
		if removeProperties then
			xmlFile:removeProperty(oldPath)
		end
	end
	local oldPath = key .. ".destruction#canBeDestroyed"
	if xmlFile:hasProperty(oldPath) then
		foliageXMLFile:setString("foliageType.fruitType.cultivation#isAllowed", xmlFile:getString(oldPath))
		if removeProperties then
			xmlFile:removeProperty(oldPath)
		end
	end
	local oldPath = key .. ".mulcher#chopperTypeName"
	if xmlFile:hasProperty(oldPath) then
		foliageXMLFile:setString("foliageType.fruitType.mulcher#chopperType", xmlFile:getString(oldPath))
		if removeProperties then
			xmlFile:removeProperty(oldPath)
		end
	end
	local oldPath = key .. ".options#startSprayState"
	if xmlFile:hasProperty(oldPath) then
		foliageXMLFile:setString("foliageType.fruitType.soil#startSprayLevel", xmlFile:getString(oldPath))
		if removeProperties then
			xmlFile:removeProperty(oldPath)
		end
	end
	local oldPath = key .. ".harvestGroundTypeChange#groundType"
	if xmlFile:hasProperty(oldPath) then
		foliageXMLFile:setString("foliageType.fruitType.harvest#groundType", xmlFile:getString(oldPath))
		if removeProperties then
			xmlFile:removeProperty(oldPath)
		end
	end
	local oldPath = key .. ".preparing#outputName"
	if xmlFile:hasProperty(oldPath) then
		foliageXMLFile:setString("foliageType.fruitType.haulm#layerName", xmlFile:getString(oldPath))
		if removeProperties then
			xmlFile:removeProperty(oldPath)
		end
	end
	local markFoliageState = function(startIndex, endIndex, attributeName, value)
		for k, stateKey in foliageXMLFile:iterator("foliageType.foliageLayer.foliageState") do
			if startIndex <= k and k <= endIndex then
				foliageXMLFile:setString(stateKey .. "#" .. attributeName, value)
			end
		end
	end
	local numGrowthStates = xmlFile:getInt(key .. ".growth#numGrowthStates")
	if numGrowthStates ~= nil then
		markFoliageState(1, numGrowthStates, "isGrowing", "true")
		local path = key .. ".growth#numGrowthStates"
		if removeProperties then
			xmlFile:removeProperty(path)
		end
	end
	local maxWeederState = xmlFile:getInt(key .. ".cropCare#maxWeederState")
	if maxWeederState ~= nil then
		markFoliageState(1, maxWeederState, "allowsWeeding", "true")
		local path = key .. ".cropCare#maxWeederState"
		if removeProperties then
			xmlFile:removeProperty(path)
		end
	end
	local maxWeederHoeState = xmlFile:getInt(key .. ".cropCare#maxWeederHoeState")
	if maxWeederHoeState ~= nil then
		markFoliageState(1, maxWeederHoeState, "allowsHoeing", "true")
		local path = key .. ".cropCare#maxWeederHoeState"
		if removeProperties then
			xmlFile:removeProperty(path)
		end
	end
	local witheredState = xmlFile:getInt(key .. ".growth#witheredState")
	if witheredState ~= nil then
		markFoliageState(witheredState, witheredState, "isWithered", "true")
		local path = key .. ".growth#witheredState"
		if removeProperties then
			xmlFile:removeProperty(path)
		end
	end
	local cutState = xmlFile:getInt(key .. ".harvest#cutState")
	if cutState ~= nil then
		markFoliageState(cutState, cutState, "isCut", "true")
		local path = key .. ".harvest#cutState"
		if removeProperties then
			xmlFile:removeProperty(path)
		end
	end
	local forageGrowthState = xmlFile:getInt(key .. ".harvest#minForageGrowthState")
	if forageGrowthState ~= nil then
		markFoliageState(forageGrowthState, forageGrowthState, "isForageReady", "true")
		local path = key .. ".harvest#minForageGrowthState"
		if removeProperties then
			xmlFile:removeProperty(path)
		end
	end
	local firstRegrowthState = xmlFile:getInt(key .. ".growth#firstRegrowthState")
	if firstRegrowthState ~= nil then
		markFoliageState(firstRegrowthState, firstRegrowthState, "regrowthStart", "true")
		local path = key .. ".growth#firstRegrowthState"
		if removeProperties then
			xmlFile:removeProperty(path)
		end
	end
	local mulcherState = xmlFile:getInt(key .. ".mulcher#state")
	if mulcherState ~= nil then
		markFoliageState(mulcherState, mulcherState, "isMulched", "true")
		local path = key .. ".mulcher#state"
		if removeProperties then
			xmlFile:removeProperty(path)
		end
	end
	local weedState = xmlFile:getInt(key .. ".harvest#weedState")
	if weedState ~= nil then
		markFoliageState(weedState, weedState, "isWeed", "true")
		local path = key .. ".harvest#weedState"
		if removeProperties then
			xmlFile:removeProperty(path)
		end
	end
	local filterStart = xmlFile:getInt(key .. ".destruction#filterStart")
	local filterEnd = xmlFile:getInt(key .. ".destruction#filterEnd")
	if filterStart ~= nil then
		markFoliageState(filterStart, filterEnd, "isDestructibleByWheel", "true")
		local path = key .. ".destruction#filterStart"
		if removeProperties then
			xmlFile:removeProperty(path)
		end
		local path = key .. ".destruction#filterEnd"
		if removeProperties then
			xmlFile:removeProperty(path)
		end
	end
	local destructionState = xmlFile:getInt(key .. ".destruction#state")
	if destructionState ~= nil then
		markFoliageState(destructionState, destructionState, "isDestructedByWheel", "true")
		local path = key .. ".destruction#state"
		if removeProperties then
			xmlFile:removeProperty(path)
		end
	elseif cutState ~= nil then
		markFoliageState(cutState, cutState, "isDestructedByWheel", "true")
	end
	local minHarvest = xmlFile:getInt(key .. ".harvest#minHarvestingGrowthState")
	local maxHarvest = xmlFile:getInt(key .. ".harvest#maxHarvestingGrowthState")
	if minHarvest ~= nil then
		markFoliageState(minHarvest, maxHarvest, "isHarvestReady", "true")
		local path = key .. ".harvest#minHarvestingGrowthState"
		if removeProperties then
			xmlFile:removeProperty(path)
		end
		local path = key .. ".harvest#maxHarvestingGrowthState"
		if removeProperties then
			xmlFile:removeProperty(path)
		end
	end
	local minPrepareState = xmlFile:getInt(key .. ".preparing#minGrowthState")
	local maxPrepareState = xmlFile:getInt(key .. ".preparing#maxGrowthState")
	if minPrepareState ~= nil then
		markFoliageState(minPrepareState, maxPrepareState, "isPreparable", "true")
		local path = key .. ".preparing#minGrowthState"
		if removeProperties then
			xmlFile:removeProperty(path)
		end
		local path = key .. ".preparing#maxGrowthState"
		if removeProperties then
			xmlFile:removeProperty(path)
		end
	end
	local preparedState = xmlFile:getInt(key .. ".preparing#preparedGrowthState")
	if preparedState ~= nil then
		markFoliageState(preparedState, preparedState, "isPrepared", "true")
		local path = key .. ".preparing#preparedGrowthState"
		if removeProperties then
			xmlFile:removeProperty(path)
		end
	end
	local growthGroundTypeChangeState = xmlFile:getInt(key .. ".growthGroundTypeChange#state")
	local groundType = xmlFile:getString(key .. ".growthGroundTypeChange#groundType")
	local groundTypeMask = xmlFile:getString(key .. ".growthGroundTypeChange#groundTypeMask")
	if growthGroundTypeChangeState ~= nil and groundType ~= nil then
		markFoliageState(growthGroundTypeChangeState, growthGroundTypeChangeState, "groundType", groundType)
		if groundTypeMask ~= nil then
			markFoliageState(growthGroundTypeChangeState, growthGroundTypeChangeState, "groundTypeMask", groundTypeMask)
		end
		local path = key .. ".growthGroundTypeChange#state"
		if removeProperties then
			xmlFile:removeProperty(path)
		end
		local path = key .. ".growthGroundTypeChange#groundType"
		if removeProperties then
			xmlFile:removeProperty(path)
		end
		local path = key .. ".growthGroundTypeChange#groundTypeMask"
		if removeProperties then
			xmlFile:removeProperty(path)
		end
	end
	for k, harvestKey in xmlFile:iterator(key .. ".harvest.transition") do
		local srcState = xmlFile:getInt(harvestKey .. "#srcState")
		local targetState = xmlFile:getInt(harvestKey .. "#targetState")
		local newKey = string.format("foliageType.fruitType.harvest.transition(%d)", k - 1)
		foliageXMLFile:setString(newKey .. "#src", stateNames[srcState])
		foliageXMLFile:setString(newKey .. "#target", stateNames[targetState])
	end
	local path = key .. ".general#startStateChannel"
	if removeProperties then
		xmlFile:removeProperty(path)
	end
	local path = key .. ".general#numStateChannels"
	if removeProperties then
		xmlFile:removeProperty(path)
	end
	local path = key .. ".growth#growthStateTime"
	if removeProperties then
		xmlFile:removeProperty(path)
	end
	local path = key .. ".growth#regrows"
	if removeProperties then
		xmlFile:removeProperty(path)
	end
	local path = key .. ".growth#numGrowthStates"
	if removeProperties then
		xmlFile:removeProperty(path)
	end
	local path = key .. ".cultivation#needsSeeding"
	if removeProperties then
		xmlFile:removeProperty(path)
	end
	local path = key .. ".mulcher#hasChopperGroundLayer"
	if removeProperties then
		xmlFile:removeProperty(path)
	end
	local path = key .. "#name"
	if removeProperties then
		xmlFile:removeProperty(path)
	end
	local path = key .. ".harvest#allowsPartialGrowthState"
	if removeProperties then
		xmlFile:removeProperty(path)
	end
	local path = key .. ".general"
	if removeProperties then
		xmlFile:removeProperty(path)
	end
	local path = key .. ".harvest"
	if removeProperties then
		xmlFile:removeProperty(path)
	end
	local path = key .. ".growth"
	if removeProperties then
		xmlFile:removeProperty(path)
	end
	local path = key .. ".growthGroundTypeChange"
	if removeProperties then
		xmlFile:removeProperty(path)
	end
	local path = key .. ".harvestGroundTypeChange"
	if removeProperties then
		xmlFile:removeProperty(path)
	end
	local path = key .. ".windrow"
	if removeProperties then
		xmlFile:removeProperty(path)
	end
	local path = key .. ".cropCare"
	if removeProperties then
		xmlFile:removeProperty(path)
	end
	local path = key .. ".options"
	if removeProperties then
		xmlFile:removeProperty(path)
	end
	local path = key .. ".destruction"
	if removeProperties then
		xmlFile:removeProperty(path)
	end
	local path = key .. ".mapColors"
	if removeProperties then
		xmlFile:removeProperty(path)
	end
	local path = key .. ".mulcher"
	if removeProperties then
		xmlFile:removeProperty(path)
	end
	local path = key .. ".cultivation"
	if removeProperties then
		xmlFile:removeProperty(path)
	end
	local path = key .. ".preparing"
	if removeProperties then
		xmlFile:removeProperty(path)
	end
end
g_fruitTypeManager = FruitTypeManager.new()
