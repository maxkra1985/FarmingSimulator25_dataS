StoreItemUtil = {}

function StoreItemUtil.getIsVehicle(storeItem)
	local v2_
	if storeItem == nil then
		v2_ = false
	else
		v2_ = storeItem.species == StoreSpecies.VEHICLE
	end
	return v2_
end

function StoreItemUtil.getIsAnimal(storeItem)
	local v4_
	if storeItem == nil then
		v4_ = false
	else
		v4_ = storeItem.species == StoreSpecies.ANIMAL
	end
	return v4_
end

function StoreItemUtil.getIsPlaceable(storeItem)
	local v6_
	if storeItem == nil then
		v6_ = false
	else
		v6_ = storeItem.species == StoreSpecies.PLACEABLE
	end
	return v6_
end

function StoreItemUtil.getIsObject(storeItem)
	local v8_
	if storeItem == nil then
		v8_ = false
	else
		v8_ = storeItem.species == StoreSpecies.OBJECT
	end
	return v8_
end

function StoreItemUtil.getIsHandTool(storeItem)
	local v10_
	if storeItem == nil then
		v10_ = false
	else
		v10_ = storeItem.species == StoreSpecies.HANDTOOL
	end
	return v10_
end

-- Local values: hasConfigurations, hasMoreThanOneOption, _, configItems, selectableItems, i
function StoreItemUtil.getIsConfigurable(storeItem)
	local v12_
	if storeItem == nil then
		v12_ = false
	else
		v12_ = storeItem.configurations ~= nil
	end
	local v13_ = false
	if v12_ then
		for _, v14_ in pairs(storeItem.configurations) do
			local v15_ = 0
			for v16_ = 1, #v14_ do
				if v14_[v16_].isSelectable ~= false then
					v15_ = v15_ + 1
					if v15_ > 1 then
						v13_ = true
						break
					end
				end
			end
			if v13_ then
				break
			end
		end
	end
	return v12_ and v13_
end

-- Local values: isHandTool
function StoreItemUtil.getCanBeShownInConfigScreen(storeItem)
	return not StoreItemUtil.getIsHandTool(storeItem)
end

function StoreItemUtil.getIsLeasable(storeItem)
	local v19_ = storeItem ~= nil and storeItem.allowLeasing
	if v19_ then
		if storeItem.runningLeasingFactor == nil then
			v19_ = false
		else
			v19_ = not StoreItemUtil.getIsPlaceable(storeItem)
		end
	end
	return v19_
end

function StoreItemUtil.getDefaultConfigId(storeItem, configurationName)
	return ConfigurationUtil.getDefaultConfigIdFromItems(storeItem.configurations[configurationName])
end

function StoreItemUtil.getDefaultPrice(storeItem, configurations)
	return StoreItemUtil.getCosts(storeItem, configurations, "price")
end

function StoreItemUtil.getDailyUpkeep(storeItem, configurations)
	return StoreItemUtil.getCosts(storeItem, configurations, "dailyUpkeep")
end

-- Local values: costs, name, value, nameConfig, valueConfig, costTypeConfig
function StoreItemUtil.getCosts(storeItem, configurations, costType)
	if storeItem == nil then
		return 0
	end
	local v29_ = storeItem[costType]
	local v30_ = v29_ == nil and 0 or v29_
	if storeItem.configurations ~= nil then
		for v31_, v32_ in pairs(configurations) do
			local v33_ = storeItem.configurations[v31_]
			if v33_ ~= nil then
				local v34_ = v33_[v32_]
				if v34_ ~= nil then
					local v35_ = v34_[costType]
					if v35_ ~= nil then
						v30_ = v30_ + tonumber(v35_)
					end
				end
			end
		end
	end
	return v30_
end

-- Local values: costs, name, values, value, check, nameConfig, valueConfig, costTypeConfig
function StoreItemUtil.getPriceWithBoughtConfigurations(storeItem, boughtConfigurations, costType)
	if storeItem == nil then
		return 0
	end
	local v39_ = storeItem[costType]
	local v40_ = v39_ == nil and 0 or v39_
	if storeItem.configurations ~= nil then
		for v41_, v42_ in pairs(boughtConfigurations) do
			for v43_, v44_ in pairs(v42_) do
				if v44_ then
					local v45_ = storeItem.configurations[v41_]
					if v45_ ~= nil then
						local v46_ = v45_[v43_]
						if v46_ ~= nil then
							local v47_ = v46_[costType]
							if v47_ ~= nil then
								v40_ = v40_ + tonumber(v47_)
							end
						end
					end
				end
			end
		end
	end
	return v40_
end

-- Local values: functions, functionIndex, functionKey, functionName
function StoreItemUtil.getFunctionsFromXML(xmlFile, storeDataXMLName, customEnvironment)
	local v51_ = nil
	for _, v52_ in xmlFile:iterator(storeDataXMLName .. ".functions.function") do
		local v53_ = xmlFile:getValue(v52_, nil, customEnvironment, true)
		if v53_ ~= nil then
			v51_ = v51_ or {}
			table.insert(v51_, v53_)
		end
	end
	return v51_
end

-- Local values: storeItemXmlFile, bundleItems, i
function StoreItemUtil.loadSpecsFromXML(item)
	if item.specs == nil then
		local v55_ = XMLFile.load("storeItemXML", item.xmlFilename, item.xmlSchema)
		if v55_ ~= nil then
			item.specs = StoreItemUtil.getSpecsFromXML(g_storeManager:getSpecTypes(), item.species, v55_, item.customEnvironment, item.baseDir)
			v55_:delete()
		end
	end
	if item.bundleInfo ~= nil then
		local v56_ = item.bundleInfo.bundleItems
		for v57_ = 1, #v56_ do
			StoreItemUtil.loadSpecsFromXML(v56_[v57_].item)
		end
	end
end

-- Local values: specs, _, specType
function StoreItemUtil.getSpecsFromXML(specTypes, species, xmlFile, customEnvironment, baseDirectory)
	local v63_ = {}
	for _, v64_ in ipairs(specTypes) do
		if v64_.species == species and v64_.loadFunc ~= nil then
			v63_[v64_.name] = v64_.loadFunc(xmlFile, customEnvironment, baseDirectory)
		end
	end
	return v63_
end

-- Local values: brandName
function StoreItemUtil.getBrandIndexFromXML(xmlFile, storeDataXMLKey)
	local v67_ = xmlFile:getValue(storeDataXMLKey .. ".brand", "")
	return g_brandManager:getBrandIndexByName(v67_)
end

-- Local values: vertexBufferMemoryUsage, indexBufferMemoryUsage, textureMemoryUsage, instanceVertexBufferMemoryUsage, instanceIndexBufferMemoryUsage, ignoreVramUsage, perInstanceVramUsage, sharedVramUsage
function StoreItemUtil.getVRamUsageFromXML(xmlFile, storeDataXMLName)
	local v70_ = xmlFile:getValue(storeDataXMLName .. ".vertexBufferMemoryUsage", 0)
	local v71_ = xmlFile:getValue(storeDataXMLName .. ".indexBufferMemoryUsage", 0)
	local v72_ = xmlFile:getValue(storeDataXMLName .. ".textureMemoryUsage", 0)
	local v73_ = xmlFile:getValue(storeDataXMLName .. ".instanceVertexBufferMemoryUsage", 0)
	local v74_ = xmlFile:getValue(storeDataXMLName .. ".instanceIndexBufferMemoryUsage", 0)
	local v75_ = xmlFile:getValue(storeDataXMLName .. ".ignoreVramUsage", false)
	local v76_ = v73_ + v74_
	return v70_ + v71_ + v72_, v76_, v75_
end

-- Local values: subConfigurations, subConfigValues, k, identifier, items, _, item
function StoreItemUtil.getSubConfigurationIndex(storeItem, configName, configIndex)
	local v80_ = storeItem.subConfigurations[configName]
	local v81_ = v80_.subConfigValues
	for v82_, v83_ in ipairs(v81_) do
		local v84_ = v80_.subConfigItemMapping[v83_]
		for _, v85_ in ipairs(v84_) do
			if v85_.index == configIndex then
				return v82_
			end
		end
	end
	return nil
end

-- Local values: subConfigurations, subConfigValues, identifier
function StoreItemUtil.getSubConfigurationItems(storeItem, configName, state)
	local v89_ = storeItem.subConfigurations[configName]
	local v90_ = v89_.subConfigValues[state]
	return v89_.subConfigItemMapping[v90_]
end

-- Local values: xmlFile, size
function StoreItemUtil.getSizeValues(xmlFilename, baseName, rotationOffset, configurations)
	local v95_ = XMLFile.load("storeItemGetSizeXml", xmlFilename, Vehicle.xmlSchema)
	local v96_ = {
		["width"] = Vehicle.defaultWidth,
		["length"] = Vehicle.defaultLength,
		["height"] = Vehicle.defaultHeight,
		["widthOffset"] = 0,
		["lengthOffset"] = 0,
		["heightOffset"] = 0
	}
	if v95_ ~= nil then
		v96_ = StoreItemUtil.getSizeValuesFromXML(xmlFilename, v95_, baseName, rotationOffset, configurations)
		v95_:delete()
	end
	return v96_
end

function StoreItemUtil.getSizeValuesFromXML(xmlFilename, xmlFile, baseName, rotationOffset, configurations)
	return StoreItemUtil.getSizeValuesFromXMLByKey(xmlFilename, xmlFile, baseName, "base", "size", "size", rotationOffset, configurations, Vehicle.DEFAULT_SIZE)
end

-- Local values: baseSizeKey, size, name, id, configItem, rotationIndex
function StoreItemUtil.getSizeValuesFromXMLByKey(xmlFilename, xmlFile, baseName, baseKey, elementKey, configKey, rotationOffset, configurations, defaults)
	local v110_ = string.format("%s.%s.%s", baseName, baseKey, elementKey)
	local v111_ = {
		["width"] = xmlFile:getValue(v110_ .. "#width", defaults.width),
		["length"] = xmlFile:getValue(v110_ .. "#length", defaults.length),
		["height"] = xmlFile:getValue(v110_ .. "#height", defaults.height),
		["widthOffset"] = xmlFile:getValue(v110_ .. "#widthOffset", defaults.widthOffset),
		["lengthOffset"] = xmlFile:getValue(v110_ .. "#lengthOffset", defaults.lengthOffset),
		["heightOffset"] = xmlFile:getValue(v110_ .. "#heightOffset", defaults.heightOffset)
	}
	if configurations ~= nil then
		for v112_, v113_ in pairs(configurations) do
			local v114_ = ConfigurationUtil.getConfigItemByConfigId(xmlFilename, v112_, v113_)
			if v114_ ~= nil and v114_.onSizeLoad ~= nil then
				v114_.onSizeLoad(v114_, xmlFile, v111_)
			end
		end
		if v111_.minWidth ~= nil then
			local v115_ = v111_.width
			local v116_ = v111_.minWidth
			v111_.width = math.max(v115_, v116_)
		end
		if v111_.minLength ~= nil then
			local v117_ = v111_.length
			local v118_ = v111_.minLength
			v111_.length = math.max(v117_, v118_)
		end
		if v111_.minHeight ~= nil then
			local v119_ = v111_.height
			local v120_ = v111_.minHeight
			v111_.height = math.max(v119_, v120_)
		end
	end
	local v121_ = rotationOffset / 1.5707963267948966 + 0.5
	local v122_ = math.floor(v121_) * 1.5707963267948966 % 6.283185307179586
	if v122_ < 0 then
		v122_ = v122_ + 6.283185307179586
	end
	local v123_ = v122_ / 1.5707963267948966 + 0.5
	local v124_ = math.floor(v123_)
	if v124_ ~= 1 then
		if v124_ ~= 2 then
			if v124_ == 3 then
				local v125_ = v111_.length
				local v126_ = v111_.width
				v111_.width = v125_
				v111_.length = v126_
				local v127_ = -v111_.lengthOffset
				local v128_ = v111_.widthOffset
				v111_.widthOffset = v127_
				v111_.lengthOffset = v128_
			end
			return v111_
		end
		local v129_ = -v111_.widthOffset
		local v130_ = -v111_.lengthOffset
		v111_.widthOffset = v129_
		v111_.lengthOffset = v130_
		return v111_
	end
	local v131_ = v111_.length
	local v132_ = v111_.width
	v111_.width = v131_
	v111_.length = v132_
	local v133_ = v111_.lengthOffset
	local v134_ = -v111_.widthOffset
	v111_.widthOffset = v133_
	v111_.lengthOffset = v134_
	return v111_
end

-- Local values: setKey
function StoreItemUtil.registerConfigurationSetXMLPaths(schema, baseKey)
	local v137_ = baseKey .. ".configurationSets"
	schema:register(XMLValueType.L10N_STRING, v137_ .. "#title", "Title to display in config screen")
	schema:register(XMLValueType.BOOL, v137_ .. "#isYesNoOption", "Defines if the configuration set is a yes/no option", false)
	local v138_ = v137_ .. ".configurationSet(?)"
	schema:register(XMLValueType.L10N_STRING, v138_ .. "#name", "Set name")
	schema:register(XMLValueType.STRING, v138_ .. "#params", "Parameters to insert into name")
	schema:register(XMLValueType.BOOL, v138_ .. "#isDefault", "Is default set")
	schema:register(XMLValueType.STRING, v138_ .. ".configuration(?)#name", "Configuration name")
	schema:register(XMLValueType.INT, v138_ .. ".configuration(?)#index", "Selected index")
	schema:register(XMLValueType.BOOL, v138_ .. ".configuration(?)#showWarning", "Show warning if config is not available (e.g. config that is added via a mod like Precision Farming)", true)
end
