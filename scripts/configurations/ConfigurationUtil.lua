ConfigurationUtil = {}
ConfigurationUtil.SEND_NUM_BITS = 7
ConfigurationUtil.SELECTOR_MULTIOPTION = 0
ConfigurationUtil.SELECTOR_COLOR = 1

function ConfigurationUtil.addBoughtConfiguration(manager, object, name, id)
	if manager:getConfigurationIndexByName(name) ~= nil then
		if object.boughtConfigurations[name] == nil then
			object.boughtConfigurations[name] = {}
		end
		object.boughtConfigurations[name][id] = true
	end
end

function ConfigurationUtil.hasBoughtConfiguration(object, name, id)
	return object.boughtConfigurations[name] ~= nil and object.boughtConfigurations[name][id] and true or false
end

function ConfigurationUtil.setConfiguration(object, name, id)
	object.configurations[name] = id
end

-- Local values: item, config
function ConfigurationUtil.getColorByConfigId(object, configName, configId)
	if configId ~= nil then
		local v14_ = g_storeManager:getItemByXMLFilename(object.configFileName)
		if v14_.configurations ~= nil then
			local v15_ = v14_.configurations[configName][configId]
			if v15_ ~= nil and v15_:isa(VehicleConfigurationItemColor) then
				return v15_:getColor()
			end
		end
	end
	return nil
end

-- Local values: item, configItems
function ConfigurationUtil.getConfigItemByConfigId(configFileName, configName, configId)
	if configId ~= nil then
		local v19_ = g_storeManager:getItemByXMLFilename(configFileName)
		if v19_.configurations ~= nil then
			local v20_ = v19_.configurations[configName]
			if v20_ ~= nil and v20_[configId] ~= nil then
				return v20_[configId]
			end
		end
	end
	return nil
end

-- Local values: item, _, configName, configItems, configId, configItem
function ConfigurationUtil.raiseConfigurationItemEvent(object, eventName)
	local v23_ = g_storeManager:getItemByXMLFilename(object.configFileName)
	if v23_.configurations ~= nil and object.sortedConfigurationNames ~= nil then
		for _, v24_ in ipairs(object.sortedConfigurationNames) do
			local v25_ = v23_.configurations[v24_]
			if v25_ ~= nil then
				local v26_ = object.configurations[v24_]
				local v27_ = v25_[v26_]
				if v27_ ~= nil and v27_[eventName] ~= nil then
					v27_[eventName](v27_, object, v26_)
				end
			end
		end
	end
end

-- Local values: item, configs, config
function ConfigurationUtil.getSaveIdByConfigId(configFileName, configName, configId)
	local v31_ = g_storeManager:getItemByXMLFilename(configFileName)
	if v31_.configurations ~= nil then
		local v32_ = v31_.configurations[configName]
		if v32_ ~= nil then
			local v33_ = v32_[configId]
			if v33_ ~= nil then
				return v33_.saveId
			end
		end
	end
	return nil
end

-- Local values: configKey, configurationItems, configurationItem, data
function ConfigurationUtil.saveConfigurationToXMLFile(itemConfigurations, configName, configId, xmlFile, key, isActive, configurationData, xmlIndex)
	local v42_ = string.format("%s(%d)", key, xmlIndex)
	local v43_ = itemConfigurations[configName]
	if v43_ ~= nil then
		local v44_ = v43_[configId]
		if v44_ ~= nil then
			local v45_ = configurationData[configName]
			if v45_ ~= nil then
				v44_:saveToXMLFile(xmlFile, v42_, isActive, v45_[configId])
				return xmlIndex + 1
			end
			v44_:saveToXMLFile(xmlFile, v42_, isActive)
			xmlIndex = xmlIndex + 1
		end
	end
	return xmlIndex
end

-- Local values: item, xmlIndex, configName, configsToSave, index, _, isActive
function ConfigurationUtil.saveConfigurationsToXMLFile(configFileName, xmlFile, key, configurations, boughtConfigurations, configurationData)
	local v52_ = g_storeManager:getItemByXMLFilename(configFileName)
	if v52_.configurations ~= nil then
		local v53_ = 0
		for v54_, v55_ in pairs(boughtConfigurations) do
			for v56_, _ in pairs(v55_) do
				local v57_ = configurations[v54_] == v56_
				v53_ = ConfigurationUtil.saveConfigurationToXMLFile(v52_.configurations, v54_, v56_, xmlFile, key, v57_, configurationData, v53_)
			end
		end
	end
end

-- Local values: configurations, boughtConfigurations, configurationData, item, _, configKey, configName, configId, isActive, configurationItems, configurationItem, j, configItemClass, fallbackIndex, fallbackSaveId, j
function ConfigurationUtil.loadConfigurationsFromXMLFile(configFileName, xmlFile, key)
	local v61_ = {}
	local v62_ = {}
	local v63_ = {}
	local v64_ = g_storeManager:getItemByXMLFilename(configFileName)
	if v64_.configurations ~= nil then
		for _, v65_ in xmlFile:iterator(key) do
			local v66_ = xmlFile:getValue(v65_ .. "#name")
			local v67_ = xmlFile:getValue(v65_ .. "#id")
			local v68_ = xmlFile:getValue(v65_ .. "#isActive", true)
			local v69_ = v64_.configurations[v66_]
			if v69_ ~= nil then
				local v70_ = nil
				for v71_ = 1, #v69_ do
					if v69_[v71_].saveId == v67_ then
						v70_ = v69_[v71_]
					end
				end
				if v70_ == nil then
					local v72_ = ClassUtil.getClassObjectByObject(v69_[1])
					if v72_ ~= nil and v72_.getFallbackConfigId ~= nil then
						local v73_, v74_ = v72_.getFallbackConfigId(v69_, v67_, v66_, configFileName)
						if v73_ ~= nil then
							Logging.info("Unable to find %s configuration \'%s\' for object \'%s\'. Using config \'%s\' as closest match instead.", v66_, v67_, configFileName, v74_)
							v70_ = v69_[v73_]
						end
					end
				end
				if v70_ == nil then
					for v75_ = 1, #v69_ do
						if v69_[v75_].isSelectable ~= false then
							Logging.info("Unable to find %s configuration \'%s\' for object \'%s\'. Using config \'%s\' instead.", v66_, v67_, configFileName, v69_[v75_].saveId)
							v70_ = v69_[v75_]
							break
						end
					end
				end
				if v70_ ~= nil then
					if v62_[v66_] == nil then
						v62_[v66_] = {}
					end
					v62_[v66_][v70_.index] = true
					if v68_ then
						v61_[v66_] = v70_.index
					end
					if v63_[v66_] == nil then
						v63_[v66_] = {}
					end
					if v63_[v66_][v70_.index] == nil then
						v63_[v66_][v70_.index] = {}
					end
					v70_:loadFromSavegameXMLFile(xmlFile, v65_, v63_[v66_][v70_.index])
				end
			end
		end
	end
	return v61_, v62_, v63_
end

-- Local values: configurations, boughtConfigurations, configurationData, numConfigs, _, configNameId, configName, numConfigIds, _, configId, configItem
function ConfigurationUtil.readConfigurationsFromStream(manager, streamId, connection, configFileName)
	local v80_ = {}
	local v81_ = {}
	local v82_ = {}
	for _ = 1, streamReadUIntN(streamId, ConfigurationUtil.SEND_NUM_BITS) do
		local v83_ = manager:getConfigurationNameByIndex(streamReadUIntN(streamId, ConfigurationUtil.SEND_NUM_BITS) + 1)
		v80_[v83_] = {}
		for _ = 1, streamReadUInt16(streamId) do
			local v84_ = streamReadUInt16(streamId) + 1
			v80_[v83_][v84_] = true
			if streamReadBool(streamId) then
				v81_[v83_] = v84_
			end
			if streamReadBool(streamId) then
				local v85_ = ConfigurationUtil.getConfigItemByConfigId(configFileName, v83_, v84_)
				if v85_ == nil then
					Logging.error("Unable to find configuration item for %s configuration \'%s\' with id %d on client side!", configFileName, v83_, v84_)
				else
					if v82_[v83_] == nil then
						v82_[v83_] = {}
					end
					if v82_[v83_][v84_] == nil then
						v82_[v83_][v84_] = {}
					end
					v85_:readFromStream(streamId, connection, v82_[v83_][v84_])
				end
			end
		end
	end
	return v81_, v80_, v82_
end

-- Local values: configName, configIds, configNameId, configId, _, configItem, data
function ConfigurationUtil.writeConfigurationsToStream(manager, streamId, connection, configFileName, configurations, boughtConfigurations, configurationData)
	streamWriteUIntN(streamId, table.size(boughtConfigurations), ConfigurationUtil.SEND_NUM_BITS)
	for v93_, v94_ in pairs(boughtConfigurations) do
		local v95_ = manager:getConfigurationIndexByName(v93_)
		streamWriteUIntN(streamId, v95_ - 1, ConfigurationUtil.SEND_NUM_BITS)
		streamWriteUInt16(streamId, table.size(v94_))
		for v96_, _ in pairs(v94_) do
			streamWriteUInt16(streamId, v96_ - 1)
			streamWriteBool(streamId, configurations[v93_] == v96_)
			local v97_ = ConfigurationUtil.getConfigItemByConfigId(configFileName, v93_, v96_)
			local v98_ = streamWriteBool
			local v99_
			if v97_ == nil then
				v99_ = false
			else
				v99_ = v97_.writeToStream ~= nil
			end
			if v98_(streamId, v99_) then
				local v100_ = configurationData[v93_]
				if v100_ == nil then
					v97_:writeToStream(streamId, connection)
				else
					v97_:writeToStream(streamId, connection, v100_[v96_])
				end
			end
		end
	end
end

-- Local values: configName, data, configId, configData, configItem
function ConfigurationUtil.getConfigurationDataHasChanged(configFileName, configurationData1, configurationData2)
	if configurationData1 == nil and configurationData2 == nil then
		return false
	end
	if configurationData1 == nil or configurationData2 == nil then
		return true
	end
	for v104_, v105_ in pairs(configurationData1) do
		if configurationData2[v104_] == nil then
			return true
		end
		for v106_, v107_ in pairs(v105_) do
			if configurationData2[v104_][v106_] == nil then
				return true
			end
			local v108_ = ConfigurationUtil.getConfigItemByConfigId(configFileName, v104_, v106_)
			if v108_.hasDataChanged ~= nil and v108_:hasDataChanged(v107_, configurationData2[v104_][v106_]) then
				return true
			end
		end
	end
	return false
end

-- Local values: item, configs, j, configItemClass, fallbackIndex, fallbackSaveId, j
function ConfigurationUtil.getConfigIdBySaveId(configFileName, configName, configId)
	local v112_ = g_storeManager:getItemByXMLFilename(configFileName)
	if v112_.configurations ~= nil then
		local v113_ = v112_.configurations[configName]
		if v113_ ~= nil then
			for v114_ = 1, #v113_ do
				if v113_[v114_].saveId == configId then
					return v113_[v114_].index
				end
			end
			local v115_ = ClassUtil.getClassObjectByObject(v113_[1])
			if v115_ ~= nil and v115_.getFallbackConfigId ~= nil then
				local v116_, v117_ = v115_.getFallbackConfigId(v113_, configId, configName, configFileName)
				if v116_ ~= nil then
					Logging.info("Unable to find %s configuration \'%s\' for object \'%s\'. Using config \'%s\' as closest match instead.", configName, configId, configFileName, v117_)
					return v116_
				end
			end
			for v118_ = 1, #v113_ do
				if v113_[v118_].isSelectable ~= false then
					Logging.info("Unable to find %s configuration \'%s\' for object \'%s\'. Using config \'%s\' instead.", configName, configId, configFileName, v113_[v118_].saveId)
					return v113_[v118_].index
				end
			end
		end
	end
	return 1
end

-- Local values: value
function ConfigurationUtil.getConfigurationValue(xmlFile, key, subKey, param, defaultValue, fallbackConfigKey, fallbackOldKey)
	if type(subKey) == "table" then
		printCallstack()
	end
	local v126_
	if key == nil then
		v126_ = nil
	else
		v126_ = xmlFile:getValue(key .. subKey .. param)
	end
	if v126_ == nil and fallbackConfigKey ~= nil then
		v126_ = xmlFile:getValue(fallbackConfigKey .. subKey .. param)
	end
	if v126_ == nil and fallbackOldKey ~= nil then
		v126_ = xmlFile:getValue(fallbackOldKey .. subKey .. param)
	end
	return Utils.getNoNil(v126_, defaultValue)
end

-- Local values: configIndex, configKey
function ConfigurationUtil.getXMLConfigurationKey(xmlFile, index, key, defaultKey, configurationKey)
	local v132_ = Utils.getNoNil(index, 1)
	local v133_ = string.format(key .. "(%d)", v132_ - 1)
	if index ~= nil and not xmlFile:hasProperty(v133_) then
		printWarning("Warning: Invalid " .. configurationKey .. " index \'" .. tostring(index) .. "\' in \'" .. key .. "\'. Using default " .. configurationKey .. " settings instead!")
	end
	if not xmlFile:hasProperty(v133_) then
		v133_ = key .. "(0)"
	end
	if xmlFile:hasProperty(v133_) then
		defaultKey = v133_
	end
	return defaultKey, v132_
end

-- Local values: configurations, defaultConfigurationIds, numConfigs, configurationDescs, _, configurationDesc, configurationItems, i, configKey, configItem
function ConfigurationUtil.getConfigurationsFromXML(manager, xmlFile, key, baseDir, customEnvironment, isMod, storeItem)
	local v140_ = manager:getConfigurations()
	local v141_ = {}
	local v142_ = 0
	local v143_ = {}
	for _, v144_ in pairs(v140_) do
		local v145_ = {}
		local v146_
		if v144_.itemClass.preLoad == nil then
			v146_ = 0
		else
			v144_.itemClass.preLoad(xmlFile, v144_.configurationsKey, baseDir, customEnvironment, isMod, v145_)
			v146_ = 0
		end
		while true do
			if 2 ^ ConfigurationUtil.SEND_NUM_BITS < v146_ then
				Logging.xmlWarning(xmlFile, "Maximum number of configurations are reached for %s. Only %d configurations per type are allowed!", v144_.name, 2 ^ ConfigurationUtil.SEND_NUM_BITS)
			end
			local v147_ = string.format(v144_.configurationKey .. "(%d)", v146_)
			if not xmlFile:hasProperty(v147_) then
				break
			end
			local v148_ = v144_.itemClass.new(v144_.name)
			v148_:setIndex(#v145_ + 1)
			if v148_:loadFromXML(xmlFile, v144_.configurationsKey, v147_, baseDir, customEnvironment) then
				table.insert(v145_, v148_)
			end
			v146_ = v146_ + 1
		end
		if v144_.itemClass.postLoad ~= nil then
			v144_.itemClass.postLoad(xmlFile, v144_.configurationsKey, baseDir, customEnvironment, isMod, v145_, storeItem, v144_.name)
		end
		if #v145_ > 0 then
			v143_[v144_.name] = ConfigurationUtil.getDefaultConfigIdFromItems(v145_)
			v141_[v144_.name] = v145_
			v142_ = v142_ + 1
		end
	end
	if v142_ == 0 then
		return nil, nil
	else
		return v141_, v143_
	end
end

-- Local values: configurationSetsKey, overwrittenTitle, isYesNoOption, configurationsSets, i, configSetKey, configSet, params, j, configKey, name, index
function ConfigurationUtil.getConfigurationSetsFromXML(storeItem, xmlFile, key, baseDir, customEnvironment, isMod)
	local v153_ = string.format("%s.configurationSets", key)
	local v154_ = xmlFile:getValue(v153_ .. "#title", nil, customEnvironment, false)
	local v155_ = xmlFile:getValue(v153_ .. "#isYesNoOption", false)
	local v156_ = 0
	local v157_ = {}
	while true do
		local v158_ = string.format("%s.configurationSet(%d)", v153_, v156_)
		if not xmlFile:hasProperty(v158_) then
			break
		end
		local v159_ = {
			["name"] = xmlFile:getValue(v158_ .. "#name", nil, customEnvironment, false)
		}
		local v160_ = xmlFile:getValue(v158_ .. "#params")
		if v160_ ~= nil then
			v159_.name = g_i18n:insertTextParams(v159_.name, v160_, customEnvironment, xmlFile)
		end
		v159_.isDefault = xmlFile:getValue(v158_ .. "#isDefault", false)
		v159_.overwrittenTitle = v154_
		v159_.isYesNoOption = v155_
		v159_.configurations = {}
		local v161_ = 0
		while true do
			local v162_ = string.format("%s.configuration(%d)", v158_, v161_)
			if not xmlFile:hasProperty(v162_) then
				break
			end
			local v163_ = xmlFile:getValue(v162_ .. "#name")
			if v163_ == nil then
				Logging.xmlWarning(xmlFile, "Missing name for configuration set item \'%s\'!", v158_)
			elseif storeItem.configurations[v163_] == nil then
				if xmlFile:getValue(v162_ .. "#showWarning", true) then
					Logging.xmlWarning(xmlFile, "Configuration name \'%s\' is not defined!", v163_)
				end
			else
				local v164_ = xmlFile:getValue(v162_ .. "#index")
				if v164_ ~= nil then
					if storeItem.configurations[v163_][v164_] == nil then
						Logging.xmlWarning(xmlFile, "Index \'%d\' not defined for configuration \'%s\'!", v164_, v163_)
					else
						v159_.configurations[v163_] = v164_
					end
				end
			end
			v161_ = v161_ + 1
		end
		table.insert(v157_, v159_)
		v159_.index = #v157_
		v156_ = v156_ + 1
	end
	return v157_
end

-- Local values: subConfigurations, name, items, config, subConfigValues, subConfigItemMapping, k, value
function ConfigurationUtil.getSubConfigurationsFromConfigurations(manager, configurations)
	local v167_
	if configurations == nil then
		v167_ = nil
	else
		v167_ = {}
		for v168_, v169_ in pairs(configurations) do
			local v170_ = manager:getConfigurationDescByName(v168_)
			if v170_.hasSubselection then
				local v171_ = v170_.getSubConfigurationValuesFunc(v169_)
				if #v171_ > 1 then
					local v172_ = {}
					v167_[v168_] = {
						["subConfigValues"] = v171_,
						["subConfigItemMapping"] = v172_
					}
					for _, v173_ in ipairs(v171_) do
						v172_[v173_] = v170_.getItemsBySubConfigurationIdentifierFunc(v169_, v173_)
					end
				end
			end
		end
	end
	return v167_
end

-- Local values: k, item, k, item
function ConfigurationUtil.getDefaultConfigIdFromItems(configItems)
	if configItems ~= nil then
		for v175_, v176_ in pairs(configItems) do
			if v176_.isDefault and v176_.isSelectable ~= false then
				return v175_
			end
		end
		for v177_, v178_ in pairs(configItems) do
			if v178_.isSelectable ~= false then
				return v177_
			end
		end
	end
	return 1
end

-- Local values: _, configSet, isMatch, configName, index
function ConfigurationUtil.getConfigurationsMatchConfigSets(configurations, configSets)
	for _, v181_ in pairs(configSets) do
		local v182_ = true
		for v183_, v184_ in pairs(v181_.configurations) do
			if configurations[v183_] ~= v184_ then
				v182_ = false
				break
			end
		end
		if v182_ then
			return true
		end
	end
	return false
end

-- Local values: closestSet, closestSetMatches, _, configSet, numMatches, configName, index
function ConfigurationUtil.getClosestConfigurationSet(configurations, configSets)
	local v187_ = 0
	local v188_ = nil
	for _, v189_ in pairs(configSets) do
		local v190_ = 0
		for v191_, v192_ in pairs(v189_.configurations) do
			if configurations[v191_] == v192_ then
				v190_ = v190_ + 1
			end
		end
		if v187_ < v190_ then
			v188_ = v189_
			v187_ = v190_
		end
	end
	return v188_, v187_
end

function ConfigurationUtil.isColorMetallic(materialId)
	return (materialId == 2 or (materialId == 3 or (materialId == 19 or (materialId == 30 or materialId == 31)))) and true or materialId == 35
end
function ConfigurationUtil.registerColorConfigurationXMLPaths()
	Logging.error("ConfigurationUtil.registerColorConfigurationXMLPaths is not available anymore")
end
