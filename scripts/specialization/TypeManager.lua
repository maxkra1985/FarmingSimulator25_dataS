TypeManager = {}
local TypeManager_mt = Class(TypeManager)
function TypeManager.new(typeName, rootElementName, xmlFilename, specializationManager, customMt)
	local self = setmetatable({}, customMt or TypeManager_mt)
	self.types = {}
	self.typeName = typeName
	self.rootElementName = rootElementName
	self.xmlFilename = xmlFilename
	self.specializationManager = specializationManager
	return self
end
function TypeManager.registerTypeXMLPath(xmlSchema, baseKey)
	xmlSchema:register(XMLValueType.STRING, baseKey .. "#name", "The name of the type", nil, true)
	xmlSchema:register(XMLValueType.STRING, baseKey .. "#className", "The name of the class to use", nil, false)
	xmlSchema:register(XMLValueType.STRING, baseKey .. "#parent", "The name of the parent type to inherit from", nil, false)
	xmlSchema:register(XMLValueType.STRING, baseKey .. "#filename", "The path of the types lua script file", nil, true)
	xmlSchema:register(XMLValueType.STRING, baseKey .. ".specialization(?)#name", "The name of the specialization to be part of this type")
end
function TypeManager:loadMapData()
	local xmlFile = loadXMLFile("typesXML", self.xmlFilename)
	local i = 0
	while true do
		local key = string.format("%s.type(%d)", self.rootElementName, i)
		if not hasXMLProperty(xmlFile, key) then
			break
		end
		local typeName = getXMLString(xmlFile, key .. "#name")
		g_asyncTaskManager:addSubtask(function()
			self:loadTypeFromXML(xmlFile, key, nil, nil, nil)
		end, string.format("TypeManager - Load Type '%s'", typeName))
		i = i + 1
	end
	g_asyncTaskManager:addSubtask(function()
		delete(xmlFile)
	end)
	g_asyncTaskManager:addSubtask(function()
		print("  Loaded " .. self.typeName .. " types")
	end)
	return true
end
function TypeManager:unloadMapData()
	self.types = {}
end
function TypeManager:addType(typeName, className, filename, customEnvironment, parent)
	if self.types[typeName] ~= nil then
		Logging.error("Multiple specifications of %s type '%s'", self.typeName, typeName)
		return false
	elseif className == nil then
		Logging.error("No className specified for %s type '%s'", self.typeName, typeName)
		return false
	elseif filename == nil then
		Logging.error("No filename specified for %s type '%s'", self.typeName, typeName)
		return false
	else
		customEnvironment = customEnvironment or ""
		source(filename, customEnvironment)
		local typeEntry = { ["name"] = typeName, ["className"] = className, ["filename"] = filename, ["specializations"] = {}, ["specializationNames"] = {}, ["specializationsByName"] = {}, ["functions"] = {}, ["events"] = {}, ["eventListeners"] = {}, ["customEnvironment"] = customEnvironment, ["parent"] = parent }
		self.types[typeName] = typeEntry
		return true
	end
end
function TypeManager:loadTypeFromXML(xmlFile, key, isDLC, modDir, modName)
	local typeName = getXMLString(xmlFile, key .. "#name")
	local parentName = getXMLString(xmlFile, key .. "#parent")
	if typeName == nil and parentName == nil then
		Logging.error("Missing name or parent for placeableType '%s'", key)
		return false
	end
	local parent = nil
	if parentName ~= nil then
		parent = self.types[parentName]
		if parent == nil then
			if modName ~= nil and modName ~= "" then
				parentName = modName .. "." .. parentName
			end
			parent = self.types[parentName]
			if parent == nil then
				Logging.error("Parent %s type '%s' is not defined!", self.typeName, parentName)
				return false
			end
		end
	end
	local className = getXMLString(xmlFile, key .. "#className")
	local filename = getXMLString(xmlFile, key .. "#filename")
	if parent ~= nil then
		className = className or parent.className
		filename = filename or parent.filename
	end
	if modName ~= nil and modName ~= "" then
		typeName = modName .. "." .. typeName
	end
	if className ~= nil and filename ~= nil then
		local customEnvironment = nil
		if modDir ~= nil then
			local useModDirectory = nil
			filename, useModDirectory = Utils.getFilename(filename, modDir)
			if useModDirectory then
				customEnvironment = modName
				className = modName .. "." .. className
			end
		end
		if Platform.allowsScriptMods or isDLC or customEnvironment == nil then
			self:addType(typeName, className, filename, customEnvironment, parent)
			if parent ~= nil then
				for _, specName in ipairs(parent.specializationNames) do
					self:addSpecialization(typeName, specName)
				end
			end
			local j = 0
			while true do
				local specKey = string.format("%s.specialization(%d)", key, j)
				if not hasXMLProperty(xmlFile, specKey) then
					break
				end
				local specName = getXMLString(xmlFile, specKey .. "#name")
				local entry = self.specializationManager:getSpecializationByName(specName)
				if entry == nil then
					if modName ~= nil then
						specName = modName .. "." .. specName
					end
					entry = self.specializationManager:getSpecializationByName(specName)
					if entry == nil then
						Logging.error("Could not find specialization '%s' for %s type '%s'.", specName, self.typeName, typeName)
						specName = nil
					end
				end
				if specName ~= nil then
					self:addSpecialization(typeName, specName)
				end
				j = j + 1
			end
			return true
		end
		Logging.error("Can't register %s type '%s' with scripts on consoles.", self.typeName, typeName)
		return false
	end
	Logging.error("Can't register %s type as its className and filename do not resolve to any valid values. Ensure the types have a className and filename defined, or a base type with them defined.", self.typeName)
end
function TypeManager:addSpecialization(typeName, specName)
	local typeEntry = self.types[typeName]
	if typeEntry ~= nil then
		if typeEntry.specializationsByName[specName] == nil then
			local spec = self.specializationManager:getSpecializationObjectByName(specName)
			if spec == nil then
				Logging.error("%s type '%s' has unknown specialization '%s!", self.typeName, tostring(typeName), tostring(specName))
				return false
			else
				table.insert(typeEntry.specializations, spec)
				table.insert(typeEntry.specializationNames, specName)
				typeEntry.specializationsByName[specName] = spec
				return true
			end
		end
		Logging.error("Specialization '%s' already exists for %s type '%s'!", specName, self.typeName, typeName)
		return false
	else
		Logging.error("%s type '%s' is not defined!", self.typeName, typeName)
		return false
	end
end
function TypeManager:validateTypes()
	for typeName, typeEntry in pairs(self.types) do
		g_asyncTaskManager:addSubtask(function()
			for _, specName in ipairs(typeEntry.specializationNames) do
				local spec = typeEntry.specializationsByName[specName]
				if spec.prerequisitesPresent == nil then
					Logging.error("Specialisation with name %s is missing prerequisitesPresent function. If no prerequisites are needed, this function can just return true.", specName)
					self:removeType(typeName)
				else
					if spec.prerequisitesPresent(typeEntry.specializations) then
						continue
					end
					Logging.error("Not all prerequisites of specialization '%s' in %s type '%s' are fulfilled", specName, self.typeName, typeName)
					self:removeType(typeName)
				end
			end
		end)
	end
end
function TypeManager:finalizeTypes()
	for typeName, typeEntry in pairs(self.types) do
		local classObject = ClassUtil.getClassObject(typeEntry.className)
		g_asyncTaskManager:addSubtask(function()
			if classObject.registerEvents ~= nil then
				classObject.registerEvents(typeEntry)
			end
		end)
		g_asyncTaskManager:addSubtask(function()
			if classObject.registerFunctions ~= nil then
				classObject.registerFunctions(typeEntry)
			end
		end)
		g_asyncTaskManager:addSubtask(function()
			for _, specialization in ipairs(typeEntry.specializations) do
				if specialization.registerEvents == nil then
					continue
				end
				specialization.registerEvents(typeEntry)
			end
		end)
		g_asyncTaskManager:addSubtask(function()
			for _, specialization in ipairs(typeEntry.specializations) do
				if specialization.registerFunctions == nil then
					continue
				end
				specialization.registerFunctions(typeEntry)
			end
		end)
		g_asyncTaskManager:addSubtask(function()
			for _, specialization in ipairs(typeEntry.specializations) do
				if specialization.registerOverwrittenFunctions == nil then
					continue
				end
				specialization.registerOverwrittenFunctions(typeEntry)
			end
		end)
		g_asyncTaskManager:addSubtask(function()
			for _, specialization in ipairs(typeEntry.specializations) do
				if specialization.registerEventListeners == nil then
					continue
				end
				specialization.registerEventListeners(typeEntry)
			end
		end)
		g_asyncTaskManager:addSubtask(function()
			if typeEntry.customEnvironment ~= "" then
				print(string.format("  Register %s type: %s", self.typeName, typeName))
			end
		end)
	end
	return true
end
function TypeManager:getTypes()
	return self.types
end
function TypeManager:removeType(typeName)
	self.types[typeName] = nil
end
function TypeManager:getTypeByName(typeName, modName)
	if typeName ~= nil then
		local typeEntry = self.types[typeName]
		if typeEntry ~= nil then
			return typeEntry
		end
		if g_modIsLoaded[modName] == nil or not g_modIsLoaded[modName] then
			Logging.error("Unable to get type '%s' from xml file. Corresponding mod is not loaded", modName)
			return nil
		end
		if typeEntry == nil then
			typeName = modName .. "." .. typeName
			return self.types[typeName]
		end
	end
	return nil
end
function TypeManager:setXMLSchema(xmlSchema)
	self.xmlSchema = xmlSchema
end
function TypeManager:getObjectTypeFromXML(xmlFilename)
	local xmlFile = XMLFile.loadIfExists(string.format("%sXML", self.typeName), xmlFilename, self.xmlSchema)
	if xmlFile == nil then
		Logging.error("Unable to find %s xml file '%s'", self.typeName, xmlFilename)
		return nil, nil
	end
	local typeName = xmlFile:getValue(xmlFile:getRootName() .. "#type")
	xmlFile:delete()
	if typeName == nil then
		Logging.error("Missing type declaration in '%s'", xmlFilename)
		return nil, nil
	end
	local modName, _ = Utils.getModNameAndBaseDirectory(xmlFilename)
	local typeEntry = self:getTypeByName(typeName, modName)
	if typeEntry == nil then
		Logging.error("Unknown type '%s' in '%s'", typeName, xmlFilename)
		return nil, nil
	end
	local class = ClassUtil.getClassObject(typeEntry.className)
	if class == nil then
		Logging.error("Unknown type className '%s' of type '%s' (%s)", typeEntry.className, typeName, xmlFilename)
		return nil, nil
	else
		return typeEntry, class
	end
end
g_vehicleTypeManager = TypeManager.new("vehicle", "vehicleTypes", "dataS/vehicleTypes.xml", g_specializationManager)
g_placeableTypeManager = TypeManager.new("placeable", "placeableTypes", "dataS/placeableTypes.xml", g_placeableSpecializationManager)
g_handToolTypeManager = TypeManager.new("handTool", "handToolTypes", "dataS/handToolTypes.xml", g_handToolSpecializationManager)
