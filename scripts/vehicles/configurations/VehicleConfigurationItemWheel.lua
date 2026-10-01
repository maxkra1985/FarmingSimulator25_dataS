VehicleConfigurationItemWheel = {}
VehicleConfigurationItemWheel.SELECTOR = ConfigurationUtil.SELECTOR_MULTIOPTION
local VehicleConfigurationItemWheel_mt = Class(VehicleConfigurationItemWheel, VehicleConfigurationItem)
function VehicleConfigurationItemWheel.new(configName, customMt)
	local self = VehicleConfigurationItemWheel:superClass().new(configName, VehicleConfigurationItemWheel_mt)
	return self
end
function VehicleConfigurationItemWheel:loadFromXML(xmlFile, baseKey, configKey, baseDirectory, customEnvironment)
	if not VehicleConfigurationItemWheel:superClass().loadFromXML(self, xmlFile, baseKey, configKey, baseDirectory, customEnvironment) then
		return false
	end
	local name = xmlFile:getValue(configKey .. "#brand")
	self.wheelBrandKey = configKey
	if name ~= nil then
		local brandDesc = g_brandManager:getBrandByName(name)
		if brandDesc ~= nil then
			self.wheelBrandName = brandDesc.title
			self.wheelBrandIconFilename = brandDesc.image
		else
			Logging.xmlWarning(xmlFile, "Wheel brand '%s' is not defined for '%s'!", name, configKey)
		end
	end
	self.maxForwardSpeed = xmlFile:getValue(configKey .. "#maxForwardSpeed")
	self.maxForwardSpeedShop = xmlFile:getValue(configKey .. "#maxForwardSpeedShop")
	local configurationIndexToParentConfigIndex = Wheels.createConfigToParentConfigMapping(xmlFile)
	self.baseWheelData = {}
	xmlFile:iterate(configKey .. ".wheels.wheel", function(index, key)
		local wheeXMLObject = WheelXMLObject.new(xmlFile, "vehicle.wheels.wheelConfigurations.wheelConfiguration", 1, string.format(".wheels.wheel(%d)", index - 1), configurationIndexToParentConfigIndex)
		wheeXMLObject:setXMLLoadKey("")
		local dimension = nil
		local dimensionsStr = wheeXMLObject:getLocalValue("#dimensions")
		if dimensionsStr ~= nil then
			local dimensionParts = dimensionsStr:split(" ")
			if 0 < #dimensionParts then
				dimension = dimensionParts[1]
			end
		end
		local xOffset = wheeXMLObject:getLocalValue(".physics#xOffset", 0)
		local rimOffset = wheeXMLObject:getLocalValue("#rimOffset", 0)
		local radius = nil
		local width = nil
		if dimension ~= nil then
			radius, width = g_wheelManager:getWheelRadiusAndWidthFromDimension(dimension)
		else
			local filename = wheeXMLObject:getLocalValue("#filename")
			if filename ~= nil then
				filename = Utils.getFilename(filename, baseDirectory)
				radius, width = g_wheelManager:getWheelRadiusAndWidthFromFilename(filename)
			end
		end
		wheeXMLObject:delete()
		if radius ~= nil and width ~= nil then
			self.baseWheelData[index] = { radius = radius, width = width, xOffset = xOffset, rimOffset = rimOffset }
		end
	end)
	local dimensionCombinations = {}
	local numWheels = 0
	xmlFile:iterate(configKey .. ".wheels.wheel", function(index, key)
		local wheeXMLObject = WheelXMLObject.new(xmlFile, "vehicle.wheels.wheelConfigurations.wheelConfiguration", self.index, string.format(".wheels.wheel(%d)", index - 1), configurationIndexToParentConfigIndex)
		wheeXMLObject:setXMLLoadKey("")
		local dimensionsStr = wheeXMLObject:getLocalValue("#dimensions")
		if dimensionsStr ~= nil then
			local dimensionParts = dimensionsStr:split(" ")
			for i, dimension in ipairs(dimensionParts) do
				if dimensionCombinations[i] == nil then
					dimensionCombinations[i] = {}
				end
				table.insert(dimensionCombinations[i], index, dimension)
			end
		end
		wheeXMLObject:delete()
		numWheels = numWheels + 1
	end)
	for i, dimensions in pairs(dimensionCombinations) do
		for i = 1, numWheels do
			if dimensions[i] == nil then
				dimensions[i] = "-"
			end
		end
	end
	if #dimensionCombinations == 0 then
		return true
	elseif self.wheelBrandName ~= nil then
		Logging.xmlWarning(xmlFile, "Wheel brand defined for dynamic configuration, this is not allowed! (%s)", configKey)
		return true
	else
		local customBrandOrder = xmlFile:getValue("vehicle.wheels.wheelConfigurations#customBrandOrder", nil, true)
		if customBrandOrder ~= nil then
			self.customBrandOrder = {}
			for i, v in ipairs(customBrandOrder) do
				self.customBrandOrder[string.upper(v)] = i
			end
		end
		local tireCategories = xmlFile:getValue(configKey .. "#tireCategories") or xmlFile:getValue("vehicle.wheels.wheelConfigurations#tireCategories")
		if tireCategories ~= nil then
			tireCategories = tireCategories:split(" ")
			if 0 < #tireCategories then
				self.tireCategories = {}
				for _, category in ipairs(tireCategories) do
					self.tireCategories[category] = true
				end
			end
		end
		self.whitelistedCombinations = {}
		xmlFile:iterate("vehicle.wheels.wheelConfigurations.tireCombination", function(index, key)
			local brandName = xmlFile:getValue(key .. "#brand")
			local brand = g_brandManager:getBrandByName(brandName)
			if brand ~= nil then
				local names = xmlFile:getValue(key .. "#names")
				if names ~= nil then
					if names == "-" then
						table.insert(self.whitelistedCombinations, { brand = brand, names = {} })
						return
					end
					names = names:split(" ")
					if 0 < #names then
						table.insert(self.whitelistedCombinations, { brand = brand, names = names })
					end
				end
			end
		end)
		local configWhitelistedCombinations = {}
		local function addTireCombinations(index)
			local parentIndex = configurationIndexToParentConfigIndex[index]
			if parentIndex ~= nil then
				addTireCombinations(parentIndex)
			end
			xmlFile:iterate(string.format("vehicle.wheels.wheelConfigurations.wheelConfiguration(%d).tireCombination", index - 1), function(_, key)
				local brandName = xmlFile:getValue(key .. "#brand")
				local brand = g_brandManager:getBrandByName(brandName)
				if brand ~= nil then
					local names = xmlFile:getValue(key .. "#names")
					if names ~= nil then
						if names == "-" then
							table.insert(configWhitelistedCombinations, { brand = brand, names = {} })
							return
						end
						names = names:split(" ")
						if 0 < #names then
							table.insert(configWhitelistedCombinations, { brand = brand, names = names })
						end
					end
				end
			end)
		end
		addTireCombinations(self.index)
		self.numDynamicConfigurations = xmlFile:getValue(configKey .. "#numDynamicConfigurations", math.huge)
		for _, combination in ipairs(configWhitelistedCombinations) do
			for i = #self.whitelistedCombinations, 1, -1 do
				local defaultCombination = self.whitelistedCombinations[i]
				if defaultCombination.brand == combination.brand then
					table.remove(self.whitelistedCombinations, i)
				end
			end
		end
		for _, combination in ipairs(configWhitelistedCombinations) do
			table.insert(self.whitelistedCombinations, combination)
		end
		self.dimensionCombinations = dimensionCombinations
		return true
	end
end
function VehicleConfigurationItemWheel:getNeedsRenaming(otherItem)
	if self.wheelBrandName ~= otherItem.wheelBrandName then
		return false
	else
		return VehicleConfigurationItemWheel:superClass().getNeedsRenaming(self, otherItem)
	end
end
function VehicleConfigurationItemWheel:onSizeLoad(xmlFile, sizeData)
	VehicleConfigurationItemWheel:superClass().onSizeLoad(self, xmlFile, sizeData)
	if self.isDynamicConfig then
		self:applyGeneratedConfiguration(xmlFile)
		if xmlFile:getValue(self.configKey .. ".size#width") ~= nil then
			return
		end
		local configurationIndexToParentConfigIndex = Wheels.createConfigToParentConfigMapping(xmlFile)
		local maxOffset = 0
		for wheelIndex, wheelData in ipairs(self.tireCombination.wheels) do
			if wheelData.path == nil then
				continue
			end
			local wheelKey = string.format(".wheels.wheel(%d)", wheelIndex - 1)
			local baseWidth = wheelData.width
			local baseXOffset = 0
			local baseRimOffset = 0
			if self.baseConfigItem.baseWheelData ~= nil and self.baseConfigItem.baseWheelData[wheelIndex] ~= nil then
				baseWidth = self.baseConfigItem.baseWheelData[wheelIndex].width
				baseXOffset = self.baseConfigItem.baseWheelData[wheelIndex].xOffset
				baseRimOffset = self.baseConfigItem.baseWheelData[wheelIndex].rimOffset
			end
			local wheeXMLObject = WheelXMLObject.new(xmlFile, "vehicle.wheels.wheelConfigurations.wheelConfiguration", self.index, wheelKey, configurationIndexToParentConfigIndex)
			wheeXMLObject:setXMLLoadKey("")
			local xOffsetDifference = (wheeXMLObject:getLocalValue(".physics#xOffset", 0) - baseXOffset) * 2
			xOffsetDifference = xOffsetDifference + (wheeXMLObject:getLocalValue("#rimOffset", 0) - baseRimOffset) * 2
			maxOffset = math.max(maxOffset, wheelData.width - baseWidth + xOffsetDifference)
			local additionalOffset = 0
			local i = 0
			while true do
				local key = string.format(".additionalWheel(%d)", i)
				local _xmlFile, _ = wheeXMLObject:getXMLFileAndPropertyKey(key)
				if _xmlFile == nil then
					break
				end
				local additionalWheelOffset = wheeXMLObject:getLocalValue(key .. "#offset", 0)
				additionalOffset = additionalOffset + (additionalWheelOffset + wheelData.width)
				i = i + 1
			end
			maxOffset = math.max(maxOffset, additionalOffset * 2 + (wheelData.width - baseWidth) + xOffsetDifference)
			wheeXMLObject:delete()
		end
		sizeData.width = sizeData.width + maxOffset
	end
end
function VehicleConfigurationItemWheel.postLoad(xmlFile, baseKey, baseDir, customEnvironment, isMod, configurationItems, storeItem, configName)
	VehicleConfigurationItemWheel:superClass().postLoad(xmlFile, baseKey, baseDir, customEnvironment, isMod, configurationItems, storeItem, configName)
	for i, baseConfigItem in ipairs(configurationItems) do
		if baseConfigItem.dimensionCombinations == nil then
			continue
		end
		if baseConfigItem.isSelectable then
			baseConfigItem.isSelectable = false
			VehicleConfigurationItemWheel.generateConfigurations(configurationItems, xmlFile, configName, baseConfigItem)
		end
	end
	local hasWheelBrands = false
	for _, item in ipairs(configurationItems) do
		if item.wheelBrandName ~= nil then
			hasWheelBrands = true
			break
		end
	end
	if hasWheelBrands then
		for _, item in ipairs(configurationItems) do
			if item.isSelectable and item.wheelBrandName == nil then
				Logging.xmlWarning(xmlFile, "Wheel brand missing for wheel configuration '%s'!", item.wheelBrandKey)
			end
		end
	end
end
function VehicleConfigurationItemWheel.getFallbackConfigId(configs, configId, configName, configFileName)
	local parts = configId:split("_")
	local maxNumMatches = 0
	local maxNumMatchesConfig = nil
	for _, config in pairs(configs) do
		local otherParts = config.saveId:split("_")
		local numMatches = 0
		for i = 1, math.min(#parts, #otherParts) do
			if parts[i] == otherParts[i] then
				numMatches = numMatches + 1
			end
		end
		if maxNumMatches < numMatches then
			maxNumMatches = numMatches
			maxNumMatchesConfig = config
		end
	end
	if maxNumMatchesConfig ~= nil then
		return maxNumMatchesConfig.index, maxNumMatchesConfig.saveId
	else
		return nil, nil
	end
end
function VehicleConfigurationItemWheel.generateConfigurations(configurationItems, xmlFile, configName, baseConfigItem)
	local tireCombinations = g_wheelManager:getTiresForDimensionCombinations(baseConfigItem.dimensionCombinations, baseConfigItem.tireCategories, baseConfigItem.whitelistedCombinations, baseConfigItem.numDynamicConfigurations, baseConfigItem.customBrandOrder)
	for _, tireCombination in ipairs(tireCombinations) do
		local configItem = VehicleConfigurationItemWheel.new(configName)
		configItem.name = baseConfigItem.name
		if 1 < tireCombination.index then
			configItem.name = string.format("%s (%d)", configItem.name, tireCombination.index)
		end
		configItem.price = baseConfigItem.price
		configItem.wheelBrandName = tireCombination.wheelBrand.name
		configItem.wheelBrandIconFilename = tireCombination.wheelBrand.image
		configItem.isDefault = baseConfigItem.isDefault
		configItem.saveId = baseConfigItem.saveId .. "_" .. tireCombination.wheelSaveId
		configItem.isDynamicConfig = true
		configItem.tireCombination = tireCombination
		configItem.baseConfigItem = baseConfigItem
		configItem.maxForwardSpeed = baseConfigItem.maxForwardSpeed
		configItem.maxForwardSpeedShop = baseConfigItem.maxForwardSpeedShop
		table.insert(configurationItems, configItem)
		local index = #configurationItems
		configItem:setIndex(index)
		configItem.configKey = string.format("vehicle.wheels.wheelConfigurations.wheelConfiguration(%d)", index - 1)
	end
end
function VehicleConfigurationItemWheel:applyGeneratedConfiguration(xmlFile)
	if self.isDynamicConfig then
		xmlFile:copyTree(self.baseConfigItem.configKey, self.configKey, true, ".wheel")
		xmlFile:setValue(self.configKey .. ".wheels#baseConfig", self.baseConfigItem.saveId)
		local configurationIndexToParentConfigIndex = Wheels.createConfigToParentConfigMapping(xmlFile)
		for wheelIndex, wheelData in ipairs(self.tireCombination.wheels) do
			local wheelKey = string.format(".wheels.wheel(%d)", wheelIndex - 1)
			local wheeXMLObject = WheelXMLObject.new(xmlFile, "vehicle.wheels.wheelConfigurations.wheelConfiguration", self.baseConfigItem.index, wheelKey, configurationIndexToParentConfigIndex)
			wheeXMLObject:setXMLLoadKey("")
			if wheelData.path ~= nil then
				local path = wheelData.path
				if string.startsWith(path, "data/shared/wheels") then
					path = "$" .. path
				end
				xmlFile:setValue(self.configKey .. wheelKey .. "#filename", path)
				local baseRadius = wheelData.radius
				if self.baseConfigItem.baseWheelData ~= nil and self.baseConfigItem.baseWheelData[wheelIndex] ~= nil then
					baseRadius = self.baseConfigItem.baseWheelData[wheelIndex].radius
				end
				local baseYOffset = wheeXMLObject:getLocalValue(".physics#yOffset") or 0
				xmlFile:setValue(self.configKey .. wheelKey .. ".physics#yOffset", baseYOffset - (baseRadius - wheelData.radius))
			else
				xmlFile:setBool(self.configKey .. wheelKey .. "#temp", true)
			end
			wheeXMLObject:delete()
		end
	end
end
function VehicleConfigurationItemWheel:applyObjectChanges(vehicle, configurationIndexToParentConfigIndex, index)
	local parentConfigIndex = configurationIndexToParentConfigIndex[index or self.index]
	if parentConfigIndex ~= nil then
		self:applyObjectChanges(vehicle, configurationIndexToParentConfigIndex, parentConfigIndex)
	end
	local key = string.format("vehicle.wheels.wheelConfigurations.wheelConfiguration(%d)", (index or self.index) - 1)
	local objects = {}
	ObjectChangeUtil.loadObjectChangeFromXML(vehicle.xmlFile, key, objects, vehicle.components, vehicle)
	ObjectChangeUtil.setObjectChanges(objects, true, vehicle, vehicle.setMovingToolDirty)
end
function VehicleConfigurationItemWheel.registerXMLPaths(schema, rootPath, configPath)
	VehicleConfigurationItemWheel:superClass().registerXMLPaths(schema, rootPath, configPath)
	schema:register(XMLValueType.STRING, configPath .. "#brand", "Name of wheel brand")
	schema:register(XMLValueType.FLOAT, configPath .. "#maxForwardSpeed", "Max. speed to set on the transmission")
	schema:register(XMLValueType.FLOAT, configPath .. "#maxForwardSpeedShop", "Max. speed to display in the shop")
end
