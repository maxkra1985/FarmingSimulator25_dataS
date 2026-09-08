-- Local values: FruitTypeManager_mt
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

-- Local values: fruitTypeCategoriesKey, fruitTypeConverterssKey
function FruitTypeManager.registerXMLPaths(schema, key)
	schema:register(XMLValueType.STRING, key .. ".fruitTypes.fruitType(?)#filename", "")
	local v3_ = key .. ".fruitTypeCategories.fruitTypeCategory(?)"
	schema:register(XMLValueType.STRING, v3_ .. "#name", "")
	schema:register(XMLValueType.STRING, v3_, "")
	local v4_ = key .. ".fruitTypeConverters.fruitTypeConverter(?)"
	schema:register(XMLValueType.STRING, v4_ .. "#name", "")
	schema:register(XMLValueType.STRING, v4_ .. ".converter(?)#from", "")
	schema:register(XMLValueType.STRING, v4_ .. ".converter(?)#to", "")
	schema:register(XMLValueType.FLOAT, v4_ .. ".converter(?)#factor", "")
end
local v_u_5_ = Class(FruitTypeManager, AbstractManager)

-- Upvalues: FruitTypeManager_mt
-- Local values: self
function FruitTypeManager.new(customMt)
	-- upvalues: (copy) v_u_5_
	local v7_ = AbstractManager.new(customMt or v_u_5_)
	addConsoleCommand("gsFruitTypesExportStats", "Exports the fruit type stats into a text file", "consoleCommandExportStats", v7_)
	return v7_
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

-- Local values: xmlFile
function FruitTypeManager:loadDefaultTypes()
	local v10_ = loadXMLFile("fuitTypes", "data/maps/maps_fruitTypes.xml")
	self:loadFruitTypes(v10_, nil, "", true)
	delete(v10_)
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

-- Local values: xmlFile, rootName, _, key, filename, fruitTypeDesc
function FruitTypeManager:loadMapFruitTypes(xmlFileHandle, missionInfo, baseDirectory)
	local v18_ = XMLFile.wrap(xmlFileHandle)
	for _, v19_ in v18_:iterator(v18_:getRootName() .. ".fruitTypes.fruitType") do
		local v20_ = v18_:getString(v19_ .. "#filename")
		if v20_ ~= nil then
			local v21_ = Utils.getFilename(v20_, baseDirectory)
			local v22_ = FruitTypeDesc.new()
			if v22_:loadFromFoliageXMLFile(v21_) then
				local v23_ = self.modFruitTypes
				table.insert(v23_, v22_)
			end
		end
	end
	v18_:delete()
end

-- Local values: fruitTypeDesc
function FruitTypeManager:loadFruitTypeFromXML(xmlFilename)
	local v26_ = FruitTypeDesc.new()
	if v26_:loadFromFoliageXMLFile(xmlFilename) then
		self:addFruitType(v26_)
	end
end

-- Local values: xmlFile, rootName
function FruitTypeManager:loadMapCategoriesAndConverters(xmlFileHandle, missionInfo, baseDirectory)
	local v29_ = XMLFile.wrap(xmlFileHandle)
	local v30_ = v29_:getRootName()
	self:loadCategoriesFromXML(v29_, v30_, false)
	self:loadConvertersFromXML(v29_, v30_, false)
	v29_:delete()
end

-- Local values: converter, converterData, _, data, fruitType, fillType
function FruitTypeManager:initializeFruitTypeConverters()
	for v32_, v33_ in pairs(self.fruitTypeConverterLoadData) do
		if self.fruitTypeConverters[v32_] ~= nil then
			for _, v34_ in ipairs(v33_) do
				local v35_ = self:getFruitTypeByName(v34_.fruitTypeName)
				local v36_ = g_fillTypeManager:getFillTypeByName(v34_.fillTypeName)
				if v35_ ~= nil and v36_ ~= nil then
					self.fruitTypeConverters[v32_][v35_.index] = {
						["fillTypeIndex"] = v36_.index,
						["conversionFactor"] = v34_.conversionFactor
					}
				end
			end
		end
	end
	self.fruitTypeConverterLoadData = {}
end

-- Local values: windrowFillType
function FruitTypeManager:addFruitType(fruitTypeDesc)
	Logging.info("Loaded fruit type \'%s\' from \'%s\'", fruitTypeDesc.name, fruitTypeDesc.xmlFilename)
	local v39_ = self.fruitTypes
	table.insert(v39_, fruitTypeDesc)
	fruitTypeDesc.index = #self.fruitTypes
	self.nameToFruitType[fruitTypeDesc.name] = fruitTypeDesc
	self.nameToIndex[fruitTypeDesc.name] = fruitTypeDesc.index
	self.indexToFruitType[fruitTypeDesc.index] = fruitTypeDesc
	self.filenameToFruitType[fruitTypeDesc.xmlFilename] = fruitTypeDesc
	self.fillTypeIndexToFruitTypeIndex[fruitTypeDesc.fillType.index] = fruitTypeDesc.index
	self.fruitTypeIndexToFillType[fruitTypeDesc.index] = fruitTypeDesc.fillType
	local v40_ = fruitTypeDesc.windrowFillType
	if v40_ ~= nil then
		self.windrowFillTypes[v40_.index] = true
		self.fruitTypeIndexToWindrowFillTypeIndex[fruitTypeDesc.index] = v40_.index
		self.fillTypeIndexToFruitTypeIndex[v40_.index] = fruitTypeDesc.index
	end
	if fruitTypeDesc.windrowCutFillType ~= nil then
		self.windrowCutFillTypeIndexToFruitTypeIndex[fruitTypeDesc.windrowCutFillType.index] = fruitTypeDesc.index
	end
end

-- Local values: xmlFile, rootName, maxNumFruitTypes, _, key, filename, fruitTypeDesc, k, modFruitTypeDesc, _, modFruitTypeDesc
function FruitTypeManager:loadFruitTypes(xmlFileHandle, missionInfo, baseDirectory, isBaseType)
	local v45_ = XMLFile.wrap(xmlFileHandle)
	local v46_ = v45_:getRootName()
	local v47_ = 2 ^ FruitTypeManager.SEND_NUM_BITS - 1
	for _, v48_ in v45_:iterator(v46_ .. ".fruitTypes.fruitType") do
		if v47_ <= #self.fruitTypes then
			Logging.xmlError(v45_, "FruitTypeManager.loadFruitTypes: too many fruit types. Only %d fruit types are supported", v47_)
		end
		local v49_ = v45_:getString(v48_ .. "#filename")
		if v49_ == nil then
			Logging.xmlWarning(v45_, "FruitTypeManager.loadFruitTypes: Missing fruit type filename for \'%s\'", v48_)
		else
			local v50_ = Utils.getFilename(v49_, baseDirectory)
			local v51_ = FruitTypeDesc.new()
			if v51_:loadFromFoliageXMLFile(v50_) then
				if self.modFruitTypes ~= nil then
					for v52_, v53_ in ipairs(self.modFruitTypes) do
						if v53_.name == v51_.name then
							v51_:delete()
							table.remove(self.modFruitTypes, v52_)
							v51_ = v53_
							break
						end
					end
				end
				self:addFruitType(v51_)
			end
		end
	end
	if self.modFruitTypes ~= nil then
		for _, v54_ in ipairs(self.modFruitTypes) do
			self:addFruitType(v54_)
		end
	end
	self.modFruitTypes = nil
	self:loadCategoriesFromXML(v45_, v46_, isBaseType)
	self:loadConvertersFromXML(v45_, v46_, isBaseType)
	v45_:delete()
end

-- Local values: _, key, name, fruitTypesStr, fruitTypeCategoryIndex, fruitTypeNames, _, fruitTypeName, fruitType
function FruitTypeManager:loadCategoriesFromXML(xmlFile, rootName, isBaseType)
	for _, v59_ in xmlFile:iterator(rootName .. ".fruitTypeCategories.fruitTypeCategory") do
		local v60_ = xmlFile:getString(v59_ .. "#name")
		local v61_ = xmlFile:getString(v59_)
		local v62_ = self:addFruitTypeCategory(v60_, isBaseType)
		if v62_ ~= nil then
			local v63_ = string.split(v61_, " ")
			for _, v64_ in ipairs(v63_) do
				local v65_ = self:getFruitTypeByName(v64_)
				if v65_ == nil then
					Logging.xmlWarning(xmlFile, "FruitTypeManager.loadFruitTypes: FruitType \'%s\' referenced in fruitTypeCategory \'%s\' is not defined!", v64_, v60_)
				elseif not self:addFruitTypeToCategory(v65_.index, v62_) then
					Logging.xmlWarning(xmlFile, "FruitTypeManager.loadFruitTypes: Could not add fruitType \'%s\' to fruitTypeCategory \'%s\'!", v64_, v60_)
				end
			end
		end
	end
end

-- Local values: _, key, name, converter, _, converterKey, from, to, factor
function FruitTypeManager:loadConvertersFromXML(xmlFile, rootName, isBaseType)
	for _, v70_ in xmlFile:iterator(rootName .. ".fruitTypeConverters.fruitTypeConverter") do
		local v71_ = self:addFruitTypeConverter(xmlFile:getString(v70_ .. "#name"), isBaseType)
		if v71_ ~= nil then
			for _, v72_ in xmlFile:iterator(v70_ .. ".converter") do
				self:addFruitTypeConversion(v71_, xmlFile:getString(v72_ .. "#from"), xmlFile:getString(v72_ .. "#to"), (xmlFile:getFloat(v72_ .. "#factor", 1)))
			end
		end
	end
end

function FruitTypeManager:getFruitTypeByIndex(index)
	return self.indexToFruitType[index]
end

-- Local values: fruitType
function FruitTypeManager:getFruitTypeNameByIndex(index)
	local v77_ = self.indexToFruitType[index]
	if v77_ == nil then
		return index == FruitType.UNKNOWN and "UNKNOWN" or nil
	else
		return v77_.name
	end
end

function FruitTypeManager:getFruitTypeByName(name)
	if name == nil then
		return nil
	else
		return self.nameToFruitType[string.upper(name)]
	end
end

-- Local values: fruitType
function FruitTypeManager:getFruitTypeIndexByName(name)
	local v82_ = self:getFruitTypeByName(name)
	if v82_ == nil then
		return nil
	else
		return v82_.index
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

-- Local values: fillType
function FruitTypeManager:getFillTypeIndexByFruitTypeIndex(index)
	local v90_ = self.fruitTypeIndexToFillType[index]
	if v90_ == nil then
		return nil
	else
		return v90_.index
	end
end

function FruitTypeManager:getFillTypeByFruitTypeIndex(index)
	return self.fruitTypeIndexToFillType[index]
end

-- Local values: fillTypeIndex
function FruitTypeManager:getFillTypeNameByFruitTypeIndex(index)
	local v95_ = self.fruitTypeIndexToFillType[index]
	return v95_ and v95_.name or nil
end

-- Local values: fruitType
function FruitTypeManager:getCutHeightByFruitTypeIndex(index, isForageCutter)
	local v99_ = self.indexToFruitType[index]
	return isForageCutter and (v99_ and (v99_.forageCutHeight or v99_.cutHeight or 0.15) or 0.15) or (v99_ and v99_.cutHeight or 0.15)
end

-- Local values: fruitType
function FruitTypeManager:getFruitTypeAreaLiters(fruitTypeIndex, area, useWindrow)
	local v104_ = self.indexToFruitType[fruitTypeIndex]
	return v104_ == nil and 0 or v104_:getAreaLiters(area, useWindrow)
end

-- Local values: index
function FruitTypeManager:addFruitTypeCategory(name, isBaseType)
	if not ClassUtil.getIsValidIndexName(name) then
		printWarning("Warning: \'" .. tostring(name) .. "\' is not a valid name for a fruitTypeCategory. Ignoring fruitTypeCategory!")
		return nil
	end
	local v108_ = string.upper(name)
	if isBaseType and self.categories[v108_] ~= nil then
		printWarning("Warning: FruitTypeCategory \'" .. tostring(v108_) .. "\' already exists. Ignoring fruitTypeCategory!")
		return nil
	end
	local v109_ = self.categories[v108_]
	if v109_ == nil then
		self.numCategories = self.numCategories + 1
		self.categories[v108_] = self.numCategories
		self.indexToCategory[self.numCategories] = v108_
		self.categoryIndexToFruitTypeIndex[self.numCategories] = {}
		v109_ = self.numCategories
	end
	return v109_
end

function FruitTypeManager:addFruitTypeToCategory(fruitTypeIndex, categoryIndex)
	if categoryIndex == nil or fruitTypeIndex == nil then
		return false
	end
	local v113_ = self.categoryIndexToFruitTypeIndex[categoryIndex]
	table.insert(v113_, fruitTypeIndex)
	return true
end

-- Local values: fruitTypes, alreadyAdded, categories, _, categoryName, categoryIndex, categoryFruitTypeIndices, _, fruitTypeIndex, fruitType
function FruitTypeManager:getFruitTypesByCategoryNames(names, warning)
	local v117_ = string.split(names, " ")
	local v118_ = {}
	local v119_ = {}
	for _, v120_ in pairs(v117_) do
		local v121_ = string.upper(v120_)
		local v122_ = self.categories[v121_]
		local v123_ = self.categoryIndexToFruitTypeIndex[v122_]
		if v123_ == nil then
			if warning ~= nil then
				printWarning(string.format(warning, v121_))
			end
		else
			for _, v124_ in ipairs(v123_) do
				local v125_ = self.indexToFruitType[v124_]
				if v118_[v125_] == nil then
					table.insert(v119_, v125_)
					v118_[v125_] = true
				end
			end
		end
	end
	return v119_
end

-- Local values: fruitTypes, index, fruitType
function FruitTypeManager:getFruitTypeIndicesByCategoryNames(names, warning)
	local v129_ = self:getFruitTypesByCategoryNames(names, warning)
	for v130_, v131_ in ipairs(v129_) do
		v129_[v130_] = v131_.index
	end
	return v129_
end

-- Local values: fruitTypes, alreadyAdded, fruitTypeNames, _, name, fruitType
function FruitTypeManager:getFruitTypesByNames(names, warning)
	local v135_ = string.split(names, " ")
	local v136_ = {}
	local v137_ = {}
	for _, v138_ in pairs(v135_) do
		local v139_ = string.upper(v138_)
		local v140_ = self.nameToFruitType[v139_]
		if v140_ == nil then
			if warning ~= nil then
				printWarning(string.format(warning, v139_))
			end
		elseif v136_[v140_] == nil then
			table.insert(v137_, v140_)
			v136_[v140_] = true
		end
	end
	return v137_
end

-- Local values: fruitTypes, index, fruitType
function FruitTypeManager:getFruitTypeIndicesByNames(names, warning)
	local v144_ = self:getFruitTypesByNames(names, warning)
	for v145_, v146_ in ipairs(v144_) do
		v144_[v145_] = v146_.index
	end
	return v144_
end

-- Local values: fillTypes, alreadyAdded, fruitTypeNames, _, name, fillType, fruitType
function FruitTypeManager:getFillTypesByFruitTypeNames(names, warning)
	local v150_ = string.split(names, " ")
	local v151_ = {}
	local v152_ = {}
	for _, v153_ in pairs(v150_) do
		local v154_ = self:getFruitTypeByName(v153_)
		local v155_
		if v154_ == nil then
			v155_ = nil
		else
			v155_ = self:getFillTypeByFruitTypeIndex(v154_.index)
		end
		if v155_ == nil then
			if warning ~= nil then
				printWarning(string.format(warning, v153_))
			end
		elseif v151_[v155_] == nil then
			table.insert(v152_, v155_)
			v151_[v155_] = true
		end
	end
	return v152_
end

-- Local values: fillTypes, index, fillType
function FruitTypeManager:getFillTypeIndicesByFruitTypeNames(names, warning)
	local v159_ = self:getFillTypesByFruitTypeNames(names, warning)
	for v160_, v161_ in ipairs(v159_) do
		v159_[v160_] = v161_.index
	end
	return v159_
end

-- Local values: fillTypes, alreadyAdded, categories, _, categoryName, category, _, fruitTypeIndex, fillType
function FruitTypeManager:getFillTypesByFruitTypeCategoryNames(fruitTypeCategoryNames, warning)
	local v165_ = string.split(fruitTypeCategoryNames, " ")
	local v166_ = {}
	local v167_ = {}
	for _, v168_ in pairs(v165_) do
		local v169_ = string.upper(v168_)
		local v170_ = self.categories[v169_]
		if v170_ == nil then
			if warning ~= nil then
				printWarning(string.format(warning, v169_))
			end
		else
			for _, v171_ in ipairs(self.categoryIndexToFruitTypeIndex[v170_]) do
				local v172_ = self:getFillTypeByFruitTypeIndex(v171_)
				if v172_ ~= nil and v166_[v172_] == nil then
					table.insert(v167_, v172_)
					v166_[v172_] = true
				end
			end
		end
	end
	return v167_
end

-- Local values: fillTypes, index, fillType
function FruitTypeManager:getFillTypeIndicesByFruitTypeCategoryName(fruitTypeCategoryNames, warning)
	local v176_ = self:getFillTypesByFruitTypeCategoryNames(fruitTypeCategoryNames, warning)
	for v177_, v178_ in ipairs(v176_) do
		v176_[v177_] = v178_.index
	end
	return v176_
end

function FruitTypeManager:isFillTypeWindrow(index)
	if index == nil then
		return false
	else
		return self.windrowFillTypes[index] == true
	end
end

function FruitTypeManager:getWindrowFillTypeIndexByFruitTypeIndex(index)
	return self.fruitTypeIndexToWindrowFillTypeIndex[index]
end

-- Local values: fruitType
function FruitTypeManager:getFillTypeLiterPerSqm(fillTypeIndex, defaultValue)
	local v186_ = self.fruitTypes[self:getFruitTypeIndexByFillTypeIndex(fillTypeIndex)]
	if v186_ == nil then
		return defaultValue
	elseif v186_.hasWindrow then
		return v186_.windrowLiterPerSqm
	else
		return v186_.literPerSqm
	end
end

-- Local values: fruitTypeIndex, fruitType
function FruitTypeManager:getCutWindrowHarvestFillLevel(fillTypeIndex, liters)
	local v190_ = self.windrowCutFillTypeIndexToFruitTypeIndex[fillTypeIndex]
	if v190_ ~= nil then
		local v191_ = self.indexToFruitType[v190_]
		if v191_ ~= nil then
			if v191_.windrowLiterPerSqm ~= nil then
				liters = liters / v191_.windrowLiterPerSqm
			end
			return liters * v191_.literPerSqm * v191_.windrowCutFactor
		end
	end
	return liters
end

-- Local values: index, converter
function FruitTypeManager:addFruitTypeConverter(name, isBaseType)
	if not ClassUtil.getIsValidIndexName(name) then
		printWarning("Warning: \'" .. tostring(name) .. "\' is not a valid name for a fruitTypeConverter. Ignoring fruitTypeConverter!")
		return nil
	end
	local v195_ = string.upper(name)
	if isBaseType and self.converterNameToIndex[v195_] ~= nil then
		printWarning("Warning: FruitTypeConverter \'" .. tostring(v195_) .. "\' already exists. Ignoring fruitTypeConverter!")
		return nil
	end
	local v196_ = self.converterNameToIndex[v195_]
	if v196_ == nil then
		local v197_ = {}
		local v198_ = self.fruitTypeConverters
		table.insert(v198_, v197_)
		self.converterNameToIndex[v195_] = #self.fruitTypeConverters
		self.nameToConverter[v195_] = v197_
		v196_ = #self.fruitTypeConverters
	end
	return v196_
end

function FruitTypeManager:addFruitTypeConversion(converter, fruitTypeName, fillTypeName, conversionFactor)
	if converter ~= nil then
		if self.fruitTypeConverterLoadData[converter] == nil then
			self.fruitTypeConverterLoadData[converter] = {}
		end
		local v204_ = self.fruitTypeConverterLoadData[converter]
		table.insert(v204_, {
			["fruitTypeName"] = fruitTypeName,
			["fillTypeName"] = fillTypeName,
			["conversionFactor"] = conversionFactor
		})
	end
end

function FruitTypeManager:getConverterDataByName(converterName)
	local v207_ = self.nameToConverter
	if converterName then
		converterName = string.upper(converterName)
	end
	return v207_[converterName]
end

function FruitTypeManager:addModFoliageType(name, filename)
	local v211_ = self.modFoliageTypesToLoad
	table.insert(v211_, {
		["name"] = name,
		["filename"] = filename
	})
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

-- Local values: content, _, fruitTypeDesc, i, _, fruitTypeDesc, profilePath, filename, file
function FruitTypeManager:consoleCommandExportStats()
	local v224_ = ""
	for _, v225_ in ipairs(self.fruitTypes) do
		v224_ = v224_ .. v225_:getStatsText() .. "\n"
	end
	local v226_ = (((v224_ .. "\n") .. "\n") .. "Weeder / How States\n") .. " Name          "
	for v227_ = 1, 9 do
		v226_ = v226_ .. string.format("[  %d  ] ", v227_)
	end
	local v228_ = v226_ .. "\n"
	for _, v229_ in ipairs(self.fruitTypes) do
		v228_ = v228_ .. v229_:getWeedingStateText() .. "\n"
	end
	local v230_ = getUserProfileAppPath() .. "fruitTypeStats.txt"
	local v231_ = io.open(v230_, "w")
	v231_:write(v228_)
	v231_:close()
	Logging.info("Fruit type stats exported to %s", v230_)
end

-- Upvalues: name, xmlFile, key
-- Local values: foliageXml

-- Local values: name, convert, path, foliageXml, path, foliageXml, path, foliageXml, path, foliageXml
function FruitTypeManager.convert(xmlFile, key)
	local v234_ = xmlFile:getString(key .. "#name")
	if v234_ == "meadow" then
		local v235_ = "data/foliage/" .. v234_ .. "/" .. v234_ .. "DLC.xml"
		local v236_ = XMLFile.load("foliage", v235_)
		if v236_ ~= nil then
			FruitTypeManager.convertFruitType(v234_, xmlFile, key, v236_, false)
			v236_:save()
			v236_:delete()
		end
		local v237_ = "data/foliage/" .. v234_ .. "/" .. v234_ .. "US.xml"
		local v238_ = XMLFile.load("foliage", v237_)
		if v238_ ~= nil then
			FruitTypeManager.convertFruitType(v234_, xmlFile, key, v238_, false)
			v238_:save()
			v238_:delete()
		end
		local v239_ = "data/foliage/" .. v234_ .. "/" .. v234_ .. "FR.xml"
		local v240_ = XMLFile.load("foliage", v239_)
		if v240_ ~= nil then
			FruitTypeManager.convertFruitType(v234_, xmlFile, key, v240_, true)
			v240_:save()
			v240_:delete()
		end
	else
		local v241_ = "data/foliage/" .. v234_ .. "/" .. v234_ .. ".xml"
		local v242_ = XMLFile.load("foliage", v241_)
		if v242_ ~= nil then
			FruitTypeManager.convertFruitType(v234_, xmlFile, key, v242_, true)
			v242_:save()
			v242_:delete()
		end
	end
	xmlFile:setString(key .. "#filename", "$data/foliage/" .. v234_ .. "/" .. v234_ .. ".xml")
	xmlFile:save()
end

-- Local values: cultivationStates, hasCultivationStates, k, cultivationKey, cultivationState, stateNames, k, stateKey, stateName, parts, newName, numParts, i, nextPart, firstChar, remainingChars, removeAttribute, copyAttribute, oldPath, path, oldPath, path, oldPath, path, oldPath, path, oldPath, path, oldPath, path, oldPath, path, oldPath, path, oldPath, path, oldPath, path, oldPath, path, oldPath, path, oldPath, path, oldPath, path, oldPath, path, oldPath, path, oldPath, path, oldPath, path, oldPath, path, oldPath, path, oldPath, path, oldPath, path, oldPath, path, oldPath, path, oldPath, path, oldPath, path, oldPath, path, oldPath, path, oldPath, path, markFoliageState, numGrowthStates, path, maxWeederState, path, maxWeederHoeState, path, witheredState, path, cutState, path, forageGrowthState, path, firstRegrowthState, path, mulcherState, path, weedState, path, filterStart, filterEnd, path, path, destructionState, path, minHarvest, maxHarvest, path, path, minPrepareState, maxPrepareState, path, path, preparedState, path, growthGroundTypeChangeState, groundType, groundTypeMask, path, path, path, k, harvestKey, srcState, targetState, newKey, path, path, path, path, path, path, path, path, path, path, path, path, path, path, path, path, path, path, path, path, path, path
function FruitTypeManager:convertFruitType(name, xmlFile, key, foliageXMLFile, removeProperties)
	local v247_ = {}
	local v248_ = false
	for _, v249_ in xmlFile:iterator(key .. ".cultivation.state") do
		v247_[xmlFile:getInt(v249_ .. "#state")] = true
		v248_ = true
	end
	local v250_ = {}
	for v251_, v252_ in foliageXMLFile:iterator("foliageType.foliageLayer.foliageState") do
		local v253_ = foliageXMLFile:getString(v252_ .. "#name")
		local v254_ = string.split(v253_, " ")
		local v255_ = table.remove(v254_, 1)
		for _ = 1, #v254_ do
			local v256_ = table.remove(v254_, 1)
			local v257_ = string.sub(v256_, 1, 1)
			local v258_ = string.sub(v256_, 2)
			v255_ = v255_ .. string.upper(v257_) .. v258_
		end
		v250_[v251_] = v255_
		foliageXMLFile:setString(v252_ .. "#name", v255_)
		if v248_ and not v247_[v251_] then
			foliageXMLFile:setBool(v252_ .. "#isCultivatable", false)
		end
	end
	local v259_ = key .. "#name"
	if xmlFile:hasProperty(v259_) then
		foliageXMLFile:setString("foliageType.fruitType#name", xmlFile:getString(v259_))
		if removeProperties then
			xmlFile:removeProperty(v259_)
		end
	end
	local v260_ = key .. ".cultivation#alignsToSun"
	if xmlFile:hasProperty(v260_) then
		foliageXMLFile:setString("foliageType.foliageLayer(0)#alignsToSun", xmlFile:getString(v260_))
		if removeProperties then
			xmlFile:removeProperty(v260_)
		end
	end
	local v261_ = key .. "#shownOnMap"
	if xmlFile:hasProperty(v261_) then
		foliageXMLFile:setString("foliageType.fruitType#shownOnMap", xmlFile:getString(v261_))
		if removeProperties then
			xmlFile:removeProperty(v261_)
		end
	end
	local v262_ = key .. "#useForFieldJob"
	if xmlFile:hasProperty(v262_) then
		foliageXMLFile:setString("foliageType.fruitType#useForFieldMissions", xmlFile:getString(v262_))
		if removeProperties then
			xmlFile:removeProperty(v262_)
		end
	end
	local v263_ = key .. ".mapColors#default"
	if xmlFile:hasProperty(v263_) then
		foliageXMLFile:setString("foliageType.fruitType.mapColors#default", xmlFile:getString(v263_))
		if removeProperties then
			xmlFile:removeProperty(v263_)
		end
	end
	local v264_ = key .. ".mapColors#colorBlind"
	if xmlFile:hasProperty(v264_) then
		foliageXMLFile:setString("foliageType.fruitType.mapColors#colorBlind", xmlFile:getString(v264_))
		if removeProperties then
			xmlFile:removeProperty(v264_)
		end
	end
	local v265_ = key .. ".windrow#name"
	if xmlFile:hasProperty(v265_) then
		foliageXMLFile:setString("foliageType.fruitType.windrow#fillType", xmlFile:getString(v265_))
		if removeProperties then
			xmlFile:removeProperty(v265_)
		end
	end
	local v266_ = key .. ".windrow#litersPerSqm"
	if xmlFile:hasProperty(v266_) then
		foliageXMLFile:setString("foliageType.fruitType.windrow#litersPerSqm", xmlFile:getString(v266_))
		if removeProperties then
			xmlFile:removeProperty(v266_)
		end
	end
	local v267_ = key .. ".harvest#literPerSqm"
	if xmlFile:hasProperty(v267_) then
		foliageXMLFile:setString("foliageType.fruitType.harvest#litersPerSqm", xmlFile:getString(v267_))
		if removeProperties then
			xmlFile:removeProperty(v267_)
		end
	end
	local v268_ = key .. ".harvest#cutHeight"
	if xmlFile:hasProperty(v268_) then
		foliageXMLFile:setString("foliageType.fruitType.harvest#cutHeight", xmlFile:getString(v268_))
		if removeProperties then
			xmlFile:removeProperty(v268_)
		end
	end
	local v269_ = key .. ".harvest#chopperTypeName"
	if xmlFile:hasProperty(v269_) then
		foliageXMLFile:setString("foliageType.fruitType.harvest#chopperTypeName", xmlFile:getString(v269_))
		if removeProperties then
			xmlFile:removeProperty(v269_)
		end
	end
	local v270_ = key .. ".growth#resetsSpray"
	if xmlFile:hasProperty(v270_) then
		foliageXMLFile:setString("foliageType.fruitType.growth#resetsSpray", xmlFile:getString(v270_))
		if removeProperties then
			xmlFile:removeProperty(v270_)
		end
	end
	local v271_ = key .. ".growth#growthRequiresLime"
	if xmlFile:hasProperty(v271_) then
		foliageXMLFile:setString("foliageType.fruitType.growth#growthRequiresLime", xmlFile:getString(v271_))
		if removeProperties then
			xmlFile:removeProperty(v271_)
		end
	end
	local v272_ = key .. ".options#lowSoilDensityRequired"
	if xmlFile:hasProperty(v272_) then
		foliageXMLFile:setString("foliageType.fruitType.soil#lowDensityRequired", xmlFile:getString(v272_))
		if removeProperties then
			xmlFile:removeProperty(v272_)
		end
	end
	local v273_ = key .. ".options#increasesSoilDensity"
	if xmlFile:hasProperty(v273_) then
		foliageXMLFile:setString("foliageType.fruitType.soil#increasesDensity", xmlFile:getString(v273_))
		if removeProperties then
			xmlFile:removeProperty(v273_)
		end
	end
	local v274_ = key .. ".options#consumesLime"
	if xmlFile:hasProperty(v274_) then
		foliageXMLFile:setString("foliageType.fruitType.soil#consumesLime", xmlFile:getString(v274_))
		if removeProperties then
			xmlFile:removeProperty(v274_)
		end
	end
	local v275_ = key .. ".cultivation#directionSnapAngle"
	if xmlFile:hasProperty(v275_) then
		foliageXMLFile:setString("foliageType.fruitType.seeding#directionSnapAngle", xmlFile:getString(v275_))
		if removeProperties then
			xmlFile:removeProperty(v275_)
		end
	end
	local v276_ = key .. ".cultivation#needsRolling"
	if xmlFile:hasProperty(v276_) then
		foliageXMLFile:setString("foliageType.fruitType.seeding#needsRolling", xmlFile:getString(v276_))
		if removeProperties then
			xmlFile:removeProperty(v276_)
		end
	end
	local v277_ = key .. ".cultivation#seedUsagePerSqm"
	if xmlFile:hasProperty(v277_) then
		foliageXMLFile:setString("foliageType.fruitType.seeding#litersPerSqm", xmlFile:getString(v277_))
		if removeProperties then
			xmlFile:removeProperty(v277_)
		end
	end
	local v278_ = key .. ".cultivation#allowsSeeding"
	if xmlFile:hasProperty(v278_) then
		foliageXMLFile:setString("foliageType.fruitType.seeding#isAvailable", xmlFile:getString(v278_))
		if removeProperties then
			xmlFile:removeProperty(v278_)
		end
	end
	local v279_ = key .. ".cultivation#plantsWeed"
	if xmlFile:hasProperty(v279_) then
		foliageXMLFile:setString("foliageType.fruitType.seeding#plantsWeed", xmlFile:getString(v279_))
		if removeProperties then
			xmlFile:removeProperty(v279_)
		end
	end
	local v280_ = key .. ".harvest#forageCutHeight"
	if xmlFile:hasProperty(v280_) then
		foliageXMLFile:setString("foliageType.fruitType.harvest#forageCutHeight", xmlFile:getString(v280_))
		if removeProperties then
			xmlFile:removeProperty(v280_)
		end
	end
	local v281_ = key .. ".harvest#beeYieldBonusPercentage"
	if xmlFile:hasProperty(v281_) then
		foliageXMLFile:setString("foliageType.fruitType.harvest#beeYieldBonusPercentage", xmlFile:getString(v281_))
		if removeProperties then
			xmlFile:removeProperty(v281_)
		end
	end
	local v282_ = key .. ".harvest#chopperType"
	if xmlFile:hasProperty(v282_) then
		foliageXMLFile:setString("foliageType.fruitType.harvest#chopperGroundType", xmlFile:getString(v282_))
		if removeProperties then
			xmlFile:removeProperty(v282_)
		end
	end
	local v283_ = key .. ".destruction#canBeDestroyed"
	if xmlFile:hasProperty(v283_) then
		foliageXMLFile:setString("foliageType.fruitType.cultivation#isAllowed", xmlFile:getString(v283_))
		if removeProperties then
			xmlFile:removeProperty(v283_)
		end
	end
	local v284_ = key .. ".mulcher#chopperTypeName"
	if xmlFile:hasProperty(v284_) then
		foliageXMLFile:setString("foliageType.fruitType.mulcher#chopperType", xmlFile:getString(v284_))
		if removeProperties then
			xmlFile:removeProperty(v284_)
		end
	end
	local v285_ = key .. ".options#startSprayState"
	if xmlFile:hasProperty(v285_) then
		foliageXMLFile:setString("foliageType.fruitType.soil#startSprayLevel", xmlFile:getString(v285_))
		if removeProperties then
			xmlFile:removeProperty(v285_)
		end
	end
	local v286_ = key .. ".harvestGroundTypeChange#groundType"
	if xmlFile:hasProperty(v286_) then
		foliageXMLFile:setString("foliageType.fruitType.harvest#groundType", xmlFile:getString(v286_))
		if removeProperties then
			xmlFile:removeProperty(v286_)
		end
	end
	local v287_ = key .. ".preparing#outputName"
	if xmlFile:hasProperty(v287_) then
		foliageXMLFile:setString("foliageType.fruitType.haulm#layerName", xmlFile:getString(v287_))
		if removeProperties then
			xmlFile:removeProperty(v287_)
		end
	end
	local function v294_(p288_, p289_, p290_, p291_)
		-- upvalues: (copy) foliageXMLFile
		for v292_, v293_ in foliageXMLFile:iterator("foliageType.foliageLayer.foliageState") do
			if p288_ <= v292_ and v292_ <= p289_ then
				foliageXMLFile:setString(v293_ .. "#" .. p290_, p291_)
			end
		end
	end
	local v295_ = xmlFile:getInt(key .. ".growth#numGrowthStates")
	if v295_ ~= nil then
		v294_(1, v295_, "isGrowing", "true")
		local v296_ = key .. ".growth#numGrowthStates"
		if removeProperties then
			xmlFile:removeProperty(v296_)
		end
	end
	local v297_ = xmlFile:getInt(key .. ".cropCare#maxWeederState")
	if v297_ ~= nil then
		v294_(1, v297_, "allowsWeeding", "true")
		local v298_ = key .. ".cropCare#maxWeederState"
		if removeProperties then
			xmlFile:removeProperty(v298_)
		end
	end
	local v299_ = xmlFile:getInt(key .. ".cropCare#maxWeederHoeState")
	if v299_ ~= nil then
		v294_(1, v299_, "allowsHoeing", "true")
		local v300_ = key .. ".cropCare#maxWeederHoeState"
		if removeProperties then
			xmlFile:removeProperty(v300_)
		end
	end
	local v301_ = xmlFile:getInt(key .. ".growth#witheredState")
	if v301_ ~= nil then
		v294_(v301_, v301_, "isWithered", "true")
		local v302_ = key .. ".growth#witheredState"
		if removeProperties then
			xmlFile:removeProperty(v302_)
		end
	end
	local v303_ = xmlFile:getInt(key .. ".harvest#cutState")
	if v303_ ~= nil then
		v294_(v303_, v303_, "isCut", "true")
		local v304_ = key .. ".harvest#cutState"
		if removeProperties then
			xmlFile:removeProperty(v304_)
		end
	end
	local v305_ = xmlFile:getInt(key .. ".harvest#minForageGrowthState")
	if v305_ ~= nil then
		v294_(v305_, v305_, "isForageReady", "true")
		local v306_ = key .. ".harvest#minForageGrowthState"
		if removeProperties then
			xmlFile:removeProperty(v306_)
		end
	end
	local v307_ = xmlFile:getInt(key .. ".growth#firstRegrowthState")
	if v307_ ~= nil then
		v294_(v307_, v307_, "regrowthStart", "true")
		local v308_ = key .. ".growth#firstRegrowthState"
		if removeProperties then
			xmlFile:removeProperty(v308_)
		end
	end
	local v309_ = xmlFile:getInt(key .. ".mulcher#state")
	if v309_ ~= nil then
		v294_(v309_, v309_, "isMulched", "true")
		local v310_ = key .. ".mulcher#state"
		if removeProperties then
			xmlFile:removeProperty(v310_)
		end
	end
	local v311_ = xmlFile:getInt(key .. ".harvest#weedState")
	if v311_ ~= nil then
		v294_(v311_, v311_, "isWeed", "true")
		local v312_ = key .. ".harvest#weedState"
		if removeProperties then
			xmlFile:removeProperty(v312_)
		end
	end
	local v313_ = xmlFile:getInt(key .. ".destruction#filterStart")
	local v314_ = xmlFile:getInt(key .. ".destruction#filterEnd")
	if v313_ ~= nil then
		v294_(v313_, v314_, "isDestructibleByWheel", "true")
		local v315_ = key .. ".destruction#filterStart"
		if removeProperties then
			xmlFile:removeProperty(v315_)
		end
		local v316_ = key .. ".destruction#filterEnd"
		if removeProperties then
			xmlFile:removeProperty(v316_)
		end
	end
	local v317_ = xmlFile:getInt(key .. ".destruction#state")
	if v317_ == nil then
		if v303_ ~= nil then
			v294_(v303_, v303_, "isDestructedByWheel", "true")
		end
	else
		v294_(v317_, v317_, "isDestructedByWheel", "true")
		local v318_ = key .. ".destruction#state"
		if removeProperties then
			xmlFile:removeProperty(v318_)
		end
	end
	local v319_ = xmlFile:getInt(key .. ".harvest#minHarvestingGrowthState")
	local v320_ = xmlFile:getInt(key .. ".harvest#maxHarvestingGrowthState")
	if v319_ ~= nil then
		v294_(v319_, v320_, "isHarvestReady", "true")
		local v321_ = key .. ".harvest#minHarvestingGrowthState"
		if removeProperties then
			xmlFile:removeProperty(v321_)
		end
		local v322_ = key .. ".harvest#maxHarvestingGrowthState"
		if removeProperties then
			xmlFile:removeProperty(v322_)
		end
	end
	local v323_ = xmlFile:getInt(key .. ".preparing#minGrowthState")
	local v324_ = xmlFile:getInt(key .. ".preparing#maxGrowthState")
	if v323_ ~= nil then
		v294_(v323_, v324_, "isPreparable", "true")
		local v325_ = key .. ".preparing#minGrowthState"
		if removeProperties then
			xmlFile:removeProperty(v325_)
		end
		local v326_ = key .. ".preparing#maxGrowthState"
		if removeProperties then
			xmlFile:removeProperty(v326_)
		end
	end
	local v327_ = xmlFile:getInt(key .. ".preparing#preparedGrowthState")
	if v327_ ~= nil then
		v294_(v327_, v327_, "isPrepared", "true")
		local v328_ = key .. ".preparing#preparedGrowthState"
		if removeProperties then
			xmlFile:removeProperty(v328_)
		end
	end
	local v329_ = xmlFile:getInt(key .. ".growthGroundTypeChange#state")
	local v330_ = xmlFile:getString(key .. ".growthGroundTypeChange#groundType")
	local v331_ = xmlFile:getString(key .. ".growthGroundTypeChange#groundTypeMask")
	if v329_ ~= nil and v330_ ~= nil then
		v294_(v329_, v329_, "groundType", v330_)
		if v331_ ~= nil then
			v294_(v329_, v329_, "groundTypeMask", v331_)
		end
		local v332_ = key .. ".growthGroundTypeChange#state"
		if removeProperties then
			xmlFile:removeProperty(v332_)
		end
		local v333_ = key .. ".growthGroundTypeChange#groundType"
		if removeProperties then
			xmlFile:removeProperty(v333_)
		end
		local v334_ = key .. ".growthGroundTypeChange#groundTypeMask"
		if removeProperties then
			xmlFile:removeProperty(v334_)
		end
	end
	for v335_, v336_ in xmlFile:iterator(key .. ".harvest.transition") do
		local v337_ = xmlFile:getInt(v336_ .. "#srcState")
		local v338_ = xmlFile:getInt(v336_ .. "#targetState")
		local v339_ = string.format("foliageType.fruitType.harvest.transition(%d)", v335_ - 1)
		foliageXMLFile:setString(v339_ .. "#src", v250_[v337_])
		foliageXMLFile:setString(v339_ .. "#target", v250_[v338_])
	end
	local v340_ = key .. ".general#startStateChannel"
	if removeProperties then
		xmlFile:removeProperty(v340_)
	end
	local v341_ = key .. ".general#numStateChannels"
	if removeProperties then
		xmlFile:removeProperty(v341_)
	end
	local v342_ = key .. ".growth#growthStateTime"
	if removeProperties then
		xmlFile:removeProperty(v342_)
	end
	local v343_ = key .. ".growth#regrows"
	if removeProperties then
		xmlFile:removeProperty(v343_)
	end
	local v344_ = key .. ".growth#numGrowthStates"
	if removeProperties then
		xmlFile:removeProperty(v344_)
	end
	local v345_ = key .. ".cultivation#needsSeeding"
	if removeProperties then
		xmlFile:removeProperty(v345_)
	end
	local v346_ = key .. ".mulcher#hasChopperGroundLayer"
	if removeProperties then
		xmlFile:removeProperty(v346_)
	end
	local v347_ = key .. "#name"
	if removeProperties then
		xmlFile:removeProperty(v347_)
	end
	local v348_ = key .. ".harvest#allowsPartialGrowthState"
	if removeProperties then
		xmlFile:removeProperty(v348_)
	end
	local v349_ = key .. ".general"
	if removeProperties then
		xmlFile:removeProperty(v349_)
	end
	local v350_ = key .. ".harvest"
	if removeProperties then
		xmlFile:removeProperty(v350_)
	end
	local v351_ = key .. ".growth"
	if removeProperties then
		xmlFile:removeProperty(v351_)
	end
	local v352_ = key .. ".growthGroundTypeChange"
	if removeProperties then
		xmlFile:removeProperty(v352_)
	end
	local v353_ = key .. ".harvestGroundTypeChange"
	if removeProperties then
		xmlFile:removeProperty(v353_)
	end
	local v354_ = key .. ".windrow"
	if removeProperties then
		xmlFile:removeProperty(v354_)
	end
	local v355_ = key .. ".cropCare"
	if removeProperties then
		xmlFile:removeProperty(v355_)
	end
	local v356_ = key .. ".options"
	if removeProperties then
		xmlFile:removeProperty(v356_)
	end
	local v357_ = key .. ".destruction"
	if removeProperties then
		xmlFile:removeProperty(v357_)
	end
	local v358_ = key .. ".mapColors"
	if removeProperties then
		xmlFile:removeProperty(v358_)
	end
	local v359_ = key .. ".mulcher"
	if removeProperties then
		xmlFile:removeProperty(v359_)
	end
	local v360_ = key .. ".cultivation"
	if removeProperties then
		xmlFile:removeProperty(v360_)
	end
	local v361_ = key .. ".preparing"
	if removeProperties then
		xmlFile:removeProperty(v361_)
	end
end
g_fruitTypeManager = FruitTypeManager.new()
