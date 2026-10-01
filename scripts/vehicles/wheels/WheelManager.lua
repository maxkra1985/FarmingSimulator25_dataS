WheelManager = {}
WheelManager.DEFAULT_FILENAME = "data/shared/wheels/wheels.xml"
WheelManager.BRAND_TO_SORT_INDEX = {}
WheelManager.BRAND_TO_SORT_INDEX.TRELLEBORG = 1
WheelManager.BRAND_TO_SORT_INDEX.MICHELIN = 2
WheelManager.BRAND_TO_SORT_INDEX.CONTINENTAL = 3
WheelManager.BRAND_TO_SORT_INDEX.MITAS = 4
WheelManager.BRAND_TO_SORT_INDEX.BKT = 5
WheelManager.BRAND_TO_SORT_INDEX.VREDESTEIN = 6
WheelManager.BRAND_TO_SORT_INDEX.NOKIAN = 7
local WheelManager_mt = Class(WheelManager, AbstractManager)
function WheelManager.new(customMt)
	return AbstractManager.new(customMt or WheelManager_mt)
end
function WheelManager:initDataStructures()
	self.wheels = {}
	self.wheelsByBasePath = {}
	self.sortedTypedWheels = {}
	self.wheelFilenameToAttributes = {}
end
function WheelManager:loadMapData(xmlFile, missionInfo, baseDirectory)
	WheelManager:superClass().loadMapData(self)
	self.baseDirectory = baseDirectory
	local wheelsXMLFile = XMLFile.load("wheelsXML", WheelManager.DEFAULT_FILENAME)
	if wheelsXMLFile ~= nil then
		self:loadWheelsFromXML(wheelsXMLFile, "wheels", baseDirectory)
		wheelsXMLFile:delete()
	end
	return true
end
function WheelManager:loadWheelsFromXML(xmlFile, key, baseDirectory)
	xmlFile:iterate(key .. ".wheel", function(_, wheelKey)
		local wheel = {}
		wheel.path = xmlFile:getString(wheelKey .. "#filename")
		if wheel.path == nil then
			Logging.xmlWarning(xmlFile, "Missing filename for wheel '%s'", wheelKey)
			return
		end
		wheel.path = Utils.getFilename(wheel.path, baseDirectory)
		wheel.radius = xmlFile:getFloat(wheelKey .. "#radius")
		if wheel.radius == nil then
			Logging.xmlWarning(xmlFile, "Missing radius for wheel '%s'", wheelKey)
			return
		end
		wheel.width = xmlFile:getFloat(wheelKey .. "#width")
		if wheel.width == nil then
			Logging.xmlWarning(xmlFile, "Missing width for wheel '%s'", wheelKey)
		else
			wheel.category = xmlFile:getString(wheelKey .. "#category", "UNKNOWN")
			wheel.allowMixture = xmlFile:getBool(wheelKey .. "#allowMixture", true)
			wheel.priority = xmlFile:getFloat(wheelKey .. "#priority", 1)
			wheel.filename = Utils.getFilenameFromPath(wheel.path)
			wheel.filename = string.split(wheel.filename, ".")[1]
			wheel.basePath = Utils.getDirectory(wheel.path)
			local pathParts = wheel.basePath:split("/")
			wheel.wheelBrand = g_brandManager:getBrandByName(pathParts[#pathParts - 2]) or g_brandManager:getBrandByIndex(Brand.NONE)
			wheel.wheelName = pathParts[#pathParts - 1] or "Unknown"
			if self.wheelFilenameToAttributes[wheel.filename] == nil then
				self.wheelFilenameToAttributes[wheel.filename] = { baseFilename = wheel.path, radius = wheel.radius, width = wheel.width }
			else
				local targetAttributes = self.wheelFilenameToAttributes[wheel.filename]
				if 0.001 < math.abs(wheel.radius - targetAttributes.radius) then
					Logging.xmlWarning(xmlFile, "Invalid radius for wheel '%s'. Does not equal the default radius for this tire size. (Base: %.3f from %s)", wheel.path, targetAttributes.radius, targetAttributes.baseFilename)
				end
				if 0.001 < math.abs(wheel.width - targetAttributes.width) then
					Logging.xmlWarning(xmlFile, "Invalid width for wheel '%s'. Does not equal the default width for this tire size. (Base: %.3f from %s)", wheel.path, targetAttributes.width, targetAttributes.baseFilename)
				end
			end
			table.insert(self.wheels, wheel)
			if self.wheelsByBasePath[wheel.basePath] == nil then
				self.wheelsByBasePath[wheel.basePath] = {}
				table.insert(self.sortedTypedWheels, self.wheelsByBasePath[wheel.basePath])
			end
			table.insert(self.wheelsByBasePath[wheel.basePath], wheel)
		end
	end)
	table.sort(self.sortedTypedWheels, function(a, b)
		if a[1].wheelBrand.name == b[1].wheelBrand.name then
			if a[1].priority == b[1].priority then
				return a[1].wheelName < b[1].wheelName
			else
				return b[1].priority < a[1].priority
			end
		end
		return a[1].wheelBrand.name < b[1].wheelBrand.name
	end)
end
function WheelManager:getTiresForDimensionCombinations(dimensionCombinations, tireCategories, whitelistedCombinations, numDynamicConfigurations, customBrandOrder)
	local tireCombinations = {}
	local indexByBrand = {}
	for dimensionIndex, dimensionCombination in ipairs(dimensionCombinations) do
		for _, wheels in ipairs(self.sortedTypedWheels) do
			local wheelsAllowed = true
			if 0 < #whitelistedCombinations then
				local brandFound = false
				local wheelFound = false
				for _, whitelistedCombination in pairs(whitelistedCombinations) do
					if whitelistedCombination.brand == wheels[1].wheelBrand then
						brandFound = true
						for _, name in ipairs(whitelistedCombination.names) do
							if name == wheels[1].wheelName then
								wheelFound = true
							end
						end
					end
				end
				wheelsAllowed = not brandFound or brandFound and wheelFound
			end
			if wheelsAllowed then
				local tireCombination = {}
				tireCombination.wheels = {}
				tireCombination.wheelBrand = nil
				tireCombination.wheelSaveId = ""
				for wheelIndex, dimension in ipairs(dimensionCombination) do
					for _, wheel in ipairs(wheels) do
						if wheel.filename == dimension then
							if tireCategories == nil or tireCategories[wheel.category] == true then
								tireCombination.wheels[wheelIndex] = wheel
							else
								if dimension == "-" then
									tireCombination.wheels[wheelIndex] = {}
									continue
								end
							end
						end
					end
				end
				local isMixed = false
				local numWheels = table.size(tireCombination.wheels)
				if 0 < numWheels and numWheels ~= #dimensionCombination then
					self:fillCombinationWithMixedTires(dimensionCombination, tireCombination, tireCategories, whitelistedCombinations)
					isMixed = true
				end
				if table.size(tireCombination.wheels) == #dimensionCombination then
					local firstWheel = nil
					for _, wheel in pairs(tireCombination.wheels) do
						if wheel.wheelBrand == nil then
							continue
						end
						firstWheel = wheel
					end
					local isAllowed = firstWheel ~= nil
					if numDynamicConfigurations ~= math.huge then
						local numConfigurationsByBrand = 0
						for i, combination in ipairs(tireCombinations) do
							if combination.wheelBrand == firstWheel.wheelBrand then
								numConfigurationsByBrand = numConfigurationsByBrand + 1
								if numDynamicConfigurations <= numConfigurationsByBrand then
									isAllowed = false
									break
								end
							end
						end
					end
					if isMixed then
						for i, otherCombination in ipairs(tireCombinations) do
							local isEqual = true
							for i = 1, #tireCombination.wheels do
								if tireCombination.wheels[i].path ~= otherCombination.wheels[i].path then
									isEqual = false
									break
								end
							end
							if isEqual then
								isAllowed = false
								break
							end
						end
					end
					if isAllowed then
						indexByBrand[firstWheel.wheelBrand] = (indexByBrand[firstWheel.wheelBrand] or 0) + 1
						tireCombination.index = indexByBrand[firstWheel.wheelBrand]
						tireCombination.wheelBrand = firstWheel.wheelBrand
						tireCombination.wheelSaveId = firstWheel.wheelBrand.name .. "_" .. firstWheel.wheelName
						local sortIndex = 0
						if customBrandOrder ~= nil then
							sortIndex = customBrandOrder[firstWheel.wheelBrand.name] or sortIndex
						end
						if sortIndex == 0 then
							sortIndex = 100 + (WheelManager.BRAND_TO_SORT_INDEX[firstWheel.wheelBrand.name] or math.huge)
						end
						tireCombination.sortIndex = sortIndex + tireCombination.index * 0.01
						table.insert(tireCombinations, tireCombination)
					end
				end
			end
		end
	end
	table.sort(tireCombinations, function(a, b)
		return a.sortIndex < b.sortIndex
	end)
	return tireCombinations
end
function WheelManager:fillCombinationWithMixedTires(dimensionCombination, tireCombination, tireCategories, whitelistedCombinations)
	local firstWheel = tireCombination.wheels[next(tireCombination.wheels)]
	if not firstWheel.allowMixture then
		return
	else
		local wheelBrand = firstWheel.wheelBrand
		local wheelName = firstWheel.wheelName
		local limitedTireNames = nil
		if 0 < #whitelistedCombinations then
			local foundBrand = false
			for _, whitelistedCombination in pairs(whitelistedCombinations) do
				if whitelistedCombination.brand == wheelBrand then
					foundBrand = true
					for _, name in ipairs(whitelistedCombination.names) do
						if name == wheelName then
							limitedTireNames = whitelistedCombination.names
						end
					end
				end
			end
			if limitedTireNames == nil and foundBrand then
				return
			end
		end
		for _, wheels in ipairs(self.sortedTypedWheels) do
			for wheelIndex, dimension in ipairs(dimensionCombination) do
				if tireCombination.wheels[wheelIndex] == nil then
					for _, wheel in ipairs(wheels) do
						if wheel.allowMixture and (wheel.filename == dimension and wheel.wheelBrand == wheelBrand) then
							if tireCategories ~= nil and (tireCategories[wheel.category] ~= true and limitedTireNames == nil) then
								continue
							end
							local isAllowed = limitedTireNames == nil
							if limitedTireNames ~= nil then
								for _, name in ipairs(limitedTireNames) do
									if name == wheel.wheelName then
										isAllowed = true
										break
									end
								end
							end
							if isAllowed then
								tireCombination.wheels[wheelIndex] = wheel
								break
							end
						end
					end
				end
			end
		end
	end
end
function WheelManager:getWheelRadiusAndWidthFromDimension(dimension)
	for _, wheels in ipairs(self.sortedTypedWheels) do
		for _, wheel in ipairs(wheels) do
			if wheel.filename == dimension then
				return wheel.radius, wheel.width
			end
		end
	end
	return nil, nil
end
function WheelManager:getWheelRadiusAndWidthFromFilename(filename)
	for _, wheels in ipairs(self.sortedTypedWheels) do
		for _, wheel in ipairs(wheels) do
			if wheel.path == filename then
				return wheel.radius, wheel.width
			end
		end
	end
	return nil, nil
end
g_wheelManager = WheelManager.new()
