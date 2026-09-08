-- Local values: FillTypeManager_mt
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

-- Local values: fillTypeCategoryKey, fillTypeConverterKey, fillTypeSoundKey
function FillTypeManager.registerXMLPaths(schema, basePath)
	FillTypeDesc.registerXMLPaths(schema, basePath .. ".fillTypes.fillType(?)")
	local v3_ = basePath .. ".fillTypeCategories.fillTypeCategory(?)"
	schema:register(XMLValueType.STRING, v3_ .. "#name", "Name of category")
	schema:register(XMLValueType.STRING_LIST, v3_, "list of fillTypes, space separated")
	local v4_ = basePath .. ".fillTypeConverters.fillTypeConverter(?)"
	schema:register(XMLValueType.STRING, v4_ .. "#name", "Converter name")
	schema:register(XMLValueType.STRING, v4_ .. ".converter(?)#from", "From fill type")
	schema:register(XMLValueType.STRING, v4_ .. ".converter(?)#to", "To fill type")
	schema:register(XMLValueType.FLOAT, v4_ .. ".converter(?)#factor", "Multiplied by factor")
	local v5_ = basePath .. ".fillTypeSounds.fillTypeSound(?)"
	SoundManager.registerSampleXMLPaths(schema, v5_, "sound")
	schema:register(XMLValueType.STRING_LIST, v5_ .. "#fillTypes", "list of fillTypes, space separated")
	schema:register(XMLValueType.BOOL, v5_ .. "#isDefault", "Is default sound", false)
end

function FillTypeManager.registerConfigXMLFilltypes(schema, basePath, fillTypesKey, fillTypeCategoriesKey, fillTypesExcludeKey)
	schema:register(XMLValueType.STRING_LIST, basePath .. (fillTypesKey or "#fillTypes"), "list of fillTypes, space separated")
	schema:register(XMLValueType.STRING_LIST, basePath .. (fillTypeCategoriesKey or "#fillTypeCategories"), "list of fillType category names, space separated")
	schema:register(XMLValueType.STRING_LIST, basePath .. (fillTypesExcludeKey or "#fillTypesExclude"), "list of fillType category names, space separated")
end
local v_u_11_ = Class(FillTypeManager, AbstractManager)

-- Upvalues: FillTypeManager_mt
-- Local values: self
function FillTypeManager.new(customMt)
	-- upvalues: (copy) v_u_11_
	return AbstractManager.new(customMt or v_u_11_)
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

-- Local values: xmlFile
function FillTypeManager:loadDefaultTypes()
	local v15_ = loadXMLFile("fillTypes", "data/maps/maps_fillTypes.xml")
	self:loadFillTypes(v15_, nil, true, nil, false)
	delete(v15_)
end

-- Local values: _, fillType
function FillTypeManager:loadMapData(xmlFile, missionInfo, baseDirectory)
	FillTypeManager:superClass().loadMapData(self)
	self:loadDefaultTypes()
	if not XMLUtil.loadDataFromMapXML(xmlFile, "fillTypes", baseDirectory, self, self.loadFillTypes, baseDirectory, false, missionInfo.customEnvironment, false) then
		return false
	end
	for _, v20_ in ipairs(self.fillTypes) do
		v20_:finalize()
	end
	return true
end

function FillTypeManager:addModWithFillTypes(xmlFilename, baseDirectory, customEnvironment)
	local v25_ = self.modsToLoad
	table.insert(v25_, { xmlFilename, baseDirectory, customEnvironment })
end

-- Local values: _, data, xmlFilename, baseDirectoryMod, customEnvironment, fillTypesXMLFile, numFillTypes, numLoadedFillTypes, _, fillType
function FillTypeManager:loadModFillTypes()
	if #self.modsToLoad > 0 then
		for _, v27_ in ipairs(self.modsToLoad) do
			local v28_, v29_, v30_ = unpack(v27_)
			local v31_ = XMLFile.load("fillTypes", v28_, FillTypeManager.xmlSchema)
			if v31_ ~= nil then
				local v32_ = #self.fillTypes
				g_fillTypeManager:loadFillTypes(v31_, v29_, false, v30_, false)
				v31_:delete()
				local v33_ = #self.fillTypes - v32_
				if v33_ > 0 then
					Logging.info("Loaded %d fill types from mod: %s", v33_, v30_)
				end
			end
		end
		for _, v34_ in ipairs(self.fillTypes) do
			v34_:finalize()
		end
	end
end

-- Local values: _, sample, _, fillTypeDesc
function FillTypeManager:unloadMapData()
	for _, v36_ in pairs(self.fillTypeSamples) do
		g_soundManager:deleteSample(v36_.sample)
	end
	for _, v37_ in pairs(self.fillTypes) do
		v37_:delete()
	end
	FillTypeManager:superClass().unloadMapData(self)
end

-- Local values: rootName, unknownFillType, _, ftKey, name, fillTypeDesc, _, ftCategoryKey, name, fillTypesList, fillTypeCategoryIndex, _, fillTypeName, fillType, _, ftConverterKey, name, converter, _, converterRuleKey, from, to, factor, sourceFillType, targetFillType, _, fillTypeSoundKey, sample, entry, fillTypes, _, fillTypeName, fillType, fillType, _
function FillTypeManager:loadFillTypes(xmlFile, baseDirectory, isBaseType, customEnv, finalizeType)
	if xmlFile == nil or xmlFile == 0 then
		return false
	end
	if type(xmlFile) ~= "table" then
		xmlFile = XMLFile.wrap(xmlFile, FillTypeManager.xmlSchema)
	end
	local v44_ = xmlFile:getRootName()
	if isBaseType then
		local v45_ = FillTypeDesc.new()
		v45_.economy.sychronizeData = false
		self:addFillType(v45_)
	end
	for _, v46_ in xmlFile:iterator(v44_ .. ".fillTypes.fillType") do
		local v47_ = xmlFile:getValue(v46_ .. "#name")
		if v47_ ~= nil then
			local v48_ = string.upper(v47_)
			if isBaseType and self.nameToFillType[v48_] ~= nil then
				Logging.warning("FillType \'%s\' already exists. Ignoring fillType!", v48_)
			else
				local v49_ = self.nameToFillType[v48_]
				if v49_ == nil then
					v49_ = FillTypeDesc.new()
				end
				if v49_:loadFromXMLFile(xmlFile, v46_, baseDirectory, customEnv) then
					if self.nameToFillType[v48_] == nil then
						self:addFillType(v49_)
					end
					if finalizeType == true then
						v49_:finalize()
					end
				end
			end
		end
	end
	for _, v50_ in xmlFile:iterator(v44_ .. ".fillTypeCategories.fillTypeCategory") do
		local v51_ = xmlFile:getValue(v50_ .. "#name")
		local v52_ = xmlFile:getValue(v50_)
		local v53_ = self:addFillTypeCategory(v51_, isBaseType)
		if v52_ ~= nil and v53_ ~= nil then
			for _, v54_ in ipairs(v52_) do
				local v55_ = self:getFillTypeByName(v54_)
				if v55_ == nil then
					Logging.warning("Unknown FillType \'" .. tostring(v54_) .. "\' in fillTypeCategory \'" .. tostring(v51_) .. "\'!")
				elseif not self:addFillTypeToCategory(v55_.index, v53_) then
					Logging.warning("Could not add fillType \'" .. tostring(v54_) .. "\' to fillTypeCategory \'" .. tostring(v51_) .. "\'!")
				end
			end
		end
	end
	for _, v56_ in xmlFile:iterator(v44_ .. ".fillTypeConverters.fillTypeConverter") do
		local v57_ = self:addFillTypeConverter(xmlFile:getValue(v56_ .. "#name"), isBaseType)
		if v57_ ~= nil then
			for _, v58_ in xmlFile:iterator(v56_ .. ".converter") do
				local v59_ = xmlFile:getValue(v58_ .. "#from")
				local v60_ = xmlFile:getValue(v58_ .. "#to")
				local v61_ = xmlFile:getValue(v58_ .. "#factor")
				local v62_ = g_fillTypeManager:getFillTypeByName(v59_)
				local v63_ = g_fillTypeManager:getFillTypeByName(v60_)
				if v62_ ~= nil and (v63_ ~= nil and v61_ ~= nil) then
					self:addFillTypeConversion(v57_, v62_.index, v63_.index, v61_)
				end
			end
		end
	end
	for _, v64_ in xmlFile:iterator(v44_ .. ".fillTypeSounds.fillTypeSound") do
		local v65_ = g_soundManager:loadSampleFromXML(xmlFile, v64_, "sound", baseDirectory, getRootNode(), 0, AudioGroup.VEHICLE, nil, nil)
		if v65_ ~= nil then
			local v66_ = {
				["sample"] = v65_,
				["fillTypes"] = {}
			}
			local v67_ = xmlFile:getValue(v64_ .. "#fillTypes")
			if v67_ ~= nil then
				for _, v68_ in ipairs(v67_) do
					local v69_ = self:getFillTypeIndexByName(v68_)
					if v69_ == nil then
						Logging.xmlWarning(xmlFile, "Unable to load fill type \'%s\' for fillTypeSound \'%s\'", v68_, v64_)
					else
						local v70_ = v66_.fillTypes
						table.insert(v70_, v69_)
						self.fillTypeToSample[v69_] = v65_
					end
				end
			end
			if xmlFile:getValue(v64_ .. "#isDefault") then
				for v71_, _ in ipairs(self.fillTypes) do
					if self.fillTypeToSample[v71_] == nil then
						self.fillTypeToSample[v71_] = v65_
					end
				end
			end
			local v72_ = self.fillTypeSamples
			table.insert(v72_, v66_)
		end
	end
	return true
end

-- Local values: maxNumFillTypes
function FillTypeManager:addFillType(fillTypeDesc)
	local v75_ = 2 ^ FillTypeManager.SEND_NUM_BITS - 1
	if v75_ <= #self.fillTypes then
		Logging.error("FillTypeManager.addFillType too many fill types. Only %d fill types are supported. Ignoring \'%s\'.", v75_, fillTypeDesc.name)
		return false
	end
	fillTypeDesc.index = #self.fillTypes + 1
	self.nameToFillType[fillTypeDesc.name] = fillTypeDesc
	self.nameToIndex[fillTypeDesc.name] = fillTypeDesc.index
	self.indexToName[fillTypeDesc.index] = fillTypeDesc.name
	self.indexToTitle[fillTypeDesc.index] = fillTypeDesc.title
	self.indexToFillType[fillTypeDesc.index] = fillTypeDesc
	local v76_ = self.fillTypes
	table.insert(v76_, fillTypeDesc)
	return true
end

-- Local values: material
function FillTypeManager:assignFillTypeTextureArraysFromTerrain(nodeId, terrainRootNodeId, diffuse, normal, height)
	local v82_ = getMaterial(nodeId, 0)
	local v83_ = setTerrainFillPlanesToMaterial(terrainRootNodeId, v82_, diffuse, normal, height)
	if v83_ ~= nil then
		setMaterial(nodeId, v83_, 0)
	end
end

-- Local values: material
function FillTypeManager:assignCustomFillTypeTextureArraysFromTerrain(nodeId, terrainRootNodeId, diffuse, normal, height)
	local v89_ = getMaterial(nodeId, 0)
	local v90_ = setTerrainFillPlanesToMaterialCustom(terrainRootNodeId, v89_, diffuse, normal, height)
	if v90_ ~= nil then
		setMaterial(nodeId, v90_, 0)
	end
end

-- Local values: curIndex, i, heightType, fillType, i, mapping, nextMapping
function FillTypeManager:constructTerrainFillLayers(heightTypes, terrainRootNodeId)
	clearTerrainFillLayers(terrainRootNodeId)
	local v94_ = 1
	for v95_ = 1, #heightTypes do
		local v96_ = heightTypes[v95_]
		local v97_ = self.fillTypes[v96_.fillTypeIndex]
		if v97_ ~= nil and v97_:addTerrainFillLayer(terrainRootNodeId, v94_) then
			v94_ = v94_ + 1
			if v96_.visualHeightMapping ~= nil then
				for v98_ = 1, #v96_.visualHeightMapping do
					local v99_ = v96_.visualHeightMapping[v98_]
					local v100_ = v96_.visualHeightMapping[v98_ + 1]
					if v100_ == nil then
						setTerrainFillVisualHeight(g_currentMission.terrainDetailHeightId, v97_.textureArrayIndex, v99_.realValue, v99_.visualValue, nil, nil)
					else
						setTerrainFillVisualHeight(g_currentMission.terrainDetailHeightId, v97_.textureArrayIndex, v99_.realValue, v99_.visualValue, v100_.realValue, v100_.visualValue)
					end
				end
			end
		end
	end
	finalizeTerrainFillLayers(terrainRootNodeId)
	return true
end

-- Local values: distanceConstr, i, heightType, fillType
function FillTypeManager:constructFillTypeDistanceTextureArray(terrainDetailHeightId, typeFirstChannel, typeNumChannels, heightTypes)
	local v106_ = TerrainDetailDistanceConstructor.new(typeFirstChannel, typeNumChannels)
	for v107_ = 1, #heightTypes do
		local v108_ = heightTypes[v107_]
		local v109_ = self.fillTypes[v108_.fillTypeIndex]
		if v109_ ~= nil then
			v109_:addDistanceTexture(v106_, v107_ - 1)
		end
	end
	return v106_:finalize(terrainDetailHeightId)
end

-- Local values: fillType
function FillTypeManager:getTextureArrayIndexByFillTypeIndex(index)
	local v112_ = self.fillTypes[index]
	if v112_ then
		v112_ = v112_.textureArrayIndex
	end
	return v112_
end

-- Local values: fillType
function FillTypeManager:getPrioritizedEffectTypeByFillTypeIndex(index)
	local v115_ = self.fillTypes[index]
	if v115_ then
		v115_ = v115_.prioritizedEffectType
	end
	return v115_
end

-- Local values: fillType
function FillTypeManager:getSmokeColorByFillTypeIndex(index, fruitColor)
	local v119_ = self.fillTypes[index]
	if v119_ == nil then
		return nil
	elseif fruitColor then
		return v119_.fruitSmokeColor or v119_.fillSmokeColor
	else
		return v119_.fillSmokeColor
	end
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

-- Local values: names, fillTypeIndex
function FillTypeManager:getFillTypeNamesByIndices(indices)
	local v128_ = {}
	for v129_ in pairs(indices) do
		local v130_ = self.indexToName[v129_]
		table.insert(v128_, v130_)
	end
	return v128_
end

function FillTypeManager:getFillTypeIndexByName(name)
	local v133_ = self.nameToIndex
	if name then
		name = string.upper(name)
	end
	return v133_[name]
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

-- Local values: index, categoryFillTypes
function FillTypeManager:addFillTypeCategory(name, isBaseType)
	if not ClassUtil.getIsValidIndexName(name) then
		printWarning("Warning: \'" .. tostring(name) .. "\' is not a valid name for a fillTypeCategory. Ignoring fillTypeCategory!")
		return nil
	end
	local v140_ = string.upper(name)
	if isBaseType and self.nameToCategoryIndex[v140_] ~= nil then
		printWarning("Warning: FillTypeCategory \'" .. tostring(v140_) .. "\' already exists. Ignoring fillTypeCategory!")
		return nil
	end
	local v141_ = self.nameToCategoryIndex[v140_]
	if v141_ == nil then
		local v142_ = {}
		v141_ = #self.categories + 1
		local v143_ = self.categories
		table.insert(v143_, v140_)
		self.categoryNameToFillTypes[v140_] = v142_
		self.categoryIndexToFillTypes[v141_] = v142_
		self.nameToCategoryIndex[v140_] = v141_
	end
	return v141_
end

function FillTypeManager:addFillTypeToCategory(fillTypeIndex, categoryIndex)
	if categoryIndex == nil or (fillTypeIndex == nil or self.categoryIndexToFillTypes[categoryIndex] == nil) then
		return false
	end
	self.categoryIndexToFillTypes[categoryIndex][fillTypeIndex] = true
	if self.fillTypeIndexToCategories[fillTypeIndex] == nil then
		self.fillTypeIndexToCategories[fillTypeIndex] = {}
	end
	self.fillTypeIndexToCategories[fillTypeIndex][categoryIndex] = true
	return true
end

function FillTypeManager:getFillTypesByCategoryNames(names, warning, fillTypes)
	local v151_ = fillTypes or {}
	if names == nil then
		return v151_
	else
		return self:getFillTypesByCategoryNamesList(string.split(names, " "), warning, v151_)
	end
end

-- Local values: _, categoryName, categoryFillTypes, fillType, _
function FillTypeManager:getFillTypesByCategoryNamesList(categoryNamesList, warning, fillTypes)
	local v156_ = fillTypes or {}
	if categoryNamesList ~= nil then
		for _, v157_ in pairs(categoryNamesList) do
			local v158_ = string.upper(v157_)
			local v159_ = self.categoryNameToFillTypes[v158_]
			if v159_ == nil then
				if warning ~= nil then
					printWarning(string.format(warning, v158_))
				end
			else
				for v160_, _ in pairs(v159_) do
					if not table.hasElement(v156_, v160_) then
						table.insert(v156_, v160_)
					end
				end
			end
		end
	end
	return v156_
end

-- Local values: fillTypeNames, _, categoryName, categoryFillTypeIndices, fillTypeIndex, _, fillType
function FillTypeManager:getFillTypeNamesByCategoryNamesList(categoryNamesList, warning)
	local v164_ = {}
	if categoryNamesList ~= nil then
		for _, v165_ in pairs(categoryNamesList) do
			local v166_ = string.upper(v165_)
			local v167_ = self.categoryNameToFillTypes[v166_]
			if v167_ == nil then
				if warning ~= nil then
					printWarning(string.format(warning, v166_))
				end
			else
				for v168_, _ in pairs(v167_) do
					local v169_ = self.indexToFillType[v168_]
					if not table.hasElement(v164_, v169_.name) then
						local v170_ = v169_.name
						table.insert(v164_, v170_)
					end
				end
			end
		end
	end
	return v164_
end

-- Local values: catgegoy
function FillTypeManager:getIsFillTypeInCategory(fillTypeIndex, categoryName)
	local v174_ = self.nameToCategoryIndex[categoryName]
	if v174_ == nil or not self.fillTypeIndexToCategories[fillTypeIndex] then
		return false
	else
		return self.fillTypeIndexToCategories[fillTypeIndex][v174_] ~= nil
	end
end

-- Local values: fillTypeNames, _, name, fillTypeIndex
function FillTypeManager:getFillTypesByNames(names, warning, fillTypes)
	local v179_ = fillTypes or {}
	if names ~= nil then
		local v180_ = string.split(names, " ")
		for _, v181_ in pairs(v180_) do
			local v182_ = string.upper(v181_)
			local v183_ = self.nameToIndex[v182_]
			if v183_ == nil then
				if warning ~= nil then
					printWarning(string.format(warning, v182_))
				end
			elseif v183_ ~= FillType.UNKNOWN and not table.hasElement(v179_, v183_) then
				table.insert(v179_, v183_)
			end
		end
	end
	return v179_
end

-- Local values: fillTypes, fillTypeCategories, fillTypeNames
function FillTypeManager:getFillTypesFromXML(xmlFile, categoryKey, namesKey, requiresFillTypes)
	local v188_ = {}
	local v189_ = xmlFile:getValue(categoryKey)
	local v190_ = xmlFile:getValue(namesKey)
	if v189_ == nil or v190_ ~= nil then
		if v189_ == nil and v190_ ~= nil then
			return g_fillTypeManager:getFillTypesByNames(v190_, "Warning: \'" .. xmlFile:getFilename() .. "\' has invalid fillType \'%s\'.")
		elseif v189_ == nil or v190_ == nil then
			if requiresFillTypes ~= nil and requiresFillTypes then
				Logging.xmlWarning(xmlFile, "either the \'%s\' or \'%s\' attribute has to be set", categoryKey, namesKey)
			end
			return v188_
		else
			Logging.xmlWarning(xmlFile, "fillTypeCategories and fillTypeNames are both set, only one of the two allowed")
			return v188_
		end
	else
		return g_fillTypeManager:getFillTypesByCategoryNames(v189_, "Warning: \'" .. xmlFile:getFilename() .. "\' has invalid fillTypeCategory \'%s\'.")
	end
end

-- Local values: fillTypeNames, fillTypeCategories, fillTypeNamesExclude, fillTypeNamesFromCategories, fillTypeNamesSet, fillTypes, fillTypeName
function FillTypeManager:loadCombinedFillTypesFromConfig(xmlFile, key, fillTypesKey, fillTypeCategoriesKey, fillTypesExcludeKey)
	local v197_ = xmlFile:getValue(key .. (fillTypesKey or "#fillTypes")) or {}
	local v198_ = xmlFile:getValue(key .. (fillTypeCategoriesKey or "#fillTypeCategories"))
	local v199_ = xmlFile:getValue(key .. (fillTypesExcludeKey or "#fillTypesExclude"))
	if v198_ ~= nil then
		local v200_ = self:getFillTypeNamesByCategoryNamesList(v198_)
		v197_ = table.getListUnion(v197_, v200_)
	end
	if #v197_ == 0 then
		return nil
	end
	local v201_ = table.toSet(v197_)
	if v199_ ~= nil then
		v201_ = table.getSetSubtraction(v201_, table.toSet(v199_))
	end
	if table.size(v201_) == 0 then
		return nil
	end
	local v202_ = {}
	for v203_ in pairs(v201_) do
		local v204_ = g_fillTypeManager
		local v205_ = "Warning: invalid fillType %q at \'" .. key .. "\'"
		table.insert(v202_, v204_:getFillTypeIndexByName(v203_, v205_))
	end
	return v202_
end

-- Local values: index, converter
function FillTypeManager:addFillTypeConverter(name, isBaseType)
	if not ClassUtil.getIsValidIndexName(name) then
		printWarning("Warning: \'" .. tostring(name) .. "\' is not a valid name for a fillTypeConverter. Ignoring fillTypeConverter!")
		return nil
	end
	local v209_ = string.upper(name)
	if isBaseType and self.nameToConverter[v209_] ~= nil then
		printWarning("Warning: FillTypeConverter \'" .. tostring(v209_) .. "\' already exists. Ignoring FillTypeConverter!")
		return nil
	end
	local v210_ = self.converterNameToIndex[v209_]
	if v210_ == nil then
		local v211_ = {}
		local v212_ = self.fillTypeConverters
		table.insert(v212_, v211_)
		self.converterNameToIndex[v209_] = #self.fillTypeConverters
		self.nameToConverter[v209_] = v211_
		v210_ = #self.fillTypeConverters
	end
	return v210_
end

function FillTypeManager:addFillTypeConversion(converter, sourceFillTypeIndex, targetFillTypeIndex, conversionFactor)
	if converter ~= nil and (self.fillTypeConverters[converter] ~= nil and (sourceFillTypeIndex ~= nil and targetFillTypeIndex ~= nil)) then
		self.fillTypeConverters[converter][sourceFillTypeIndex] = {
			["targetFillTypeIndex"] = targetFillTypeIndex,
			["conversionFactor"] = conversionFactor
		}
	end
end

function FillTypeManager:getConverterDataByName(converterName)
	local v220_ = self.nameToConverter
	if converterName then
		converterName = string.upper(converterName)
	end
	return v220_[converterName]
end

function FillTypeManager:getSampleByFillType(fillType)
	return self.fillTypeToSample[fillType]
end
g_fillTypeManager = FillTypeManager.new()
