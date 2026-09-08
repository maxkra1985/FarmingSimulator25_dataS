-- Local values: TypeManager_mt
TypeManager = {}
local TypeManager_mt = Class(TypeManager)

-- Upvalues: TypeManager_mt
-- Local values: self
function TypeManager.new(typeName, rootElementName, xmlFilename, specializationManager, customMt)
	-- upvalues: (copy) TypeManager_mt
	local v7_ = customMt or TypeManager_mt
	local v8_ = setmetatable({}, v7_)
	v8_.types = {}
	v8_.typeName = typeName
	v8_.rootElementName = rootElementName
	v8_.xmlFilename = xmlFilename
	v8_.specializationManager = specializationManager
	return v8_
end

function TypeManager.registerTypeXMLPath(xmlSchema, baseKey)
	xmlSchema:register(XMLValueType.STRING, baseKey .. "#name", "The name of the type", nil, true)
	xmlSchema:register(XMLValueType.STRING, baseKey .. "#className", "The name of the class to use", nil, false)
	xmlSchema:register(XMLValueType.STRING, baseKey .. "#parent", "The name of the parent type to inherit from", nil, false)
	xmlSchema:register(XMLValueType.STRING, baseKey .. "#filename", "The path of the types lua script file", nil, true)
	xmlSchema:register(XMLValueType.STRING, baseKey .. ".specialization(?)#name", "The name of the specialization to be part of this type")
end

-- Local values: xmlFile, i, key, typeName
function TypeManager:loadMapData()
	local v_u_12_ = loadXMLFile("typesXML", self.xmlFilename)
	local v13_ = 0
	while true do
		local v_u_14_ = string.format("%s.type(%d)", self.rootElementName, v13_)
		if not hasXMLProperty(v_u_12_, v_u_14_) then
			break
		end
		local v15_ = getXMLString(v_u_12_, v_u_14_ .. "#name")
		g_asyncTaskManager:addSubtask(function()
			-- upvalues: (copy) self, (copy) v_u_12_, (copy) v_u_14_
			self:loadTypeFromXML(v_u_12_, v_u_14_, nil, nil, nil)
		end, string.format("TypeManager - Load Type \'%s\'", v15_))
		v13_ = v13_ + 1
	end
	g_asyncTaskManager:addSubtask(function()
		-- upvalues: (copy) v_u_12_
		delete(v_u_12_)
	end)
	g_asyncTaskManager:addSubtask(function()
		-- upvalues: (copy) self
		print("  Loaded " .. self.typeName .. " types")
	end)
	return true
end

function TypeManager:unloadMapData()
	self.types = {}
end

-- Local values: typeEntry
function TypeManager:addType(typeName, className, filename, customEnvironment, parent)
	if self.types[typeName] ~= nil then
		Logging.error("Multiple specifications of %s type \'%s\'", self.typeName, typeName)
		return false
	end
	if className == nil then
		Logging.error("No className specified for %s type \'%s\'", self.typeName, typeName)
		return false
	end
	if filename == nil then
		Logging.error("No filename specified for %s type \'%s\'", self.typeName, typeName)
		return false
	end
	local v23_ = customEnvironment or ""
	source(filename, v23_)
	self.types[typeName] = {
		["name"] = typeName,
		["className"] = className,
		["filename"] = filename,
		["specializations"] = {},
		["specializationNames"] = {},
		["specializationsByName"] = {},
		["functions"] = {},
		["events"] = {},
		["eventListeners"] = {},
		["customEnvironment"] = v23_,
		["parent"] = parent
	}
	return true
end

-- Local values: typeName, parentName, parent, className, filename, customEnvironment, useModDirectory, _, specName, j, specKey, specName, entry
function TypeManager:loadTypeFromXML(xmlFile, key, isDLC, modDir, modName)
	local v30_ = getXMLString(xmlFile, key .. "#name")
	local v31_ = getXMLString(xmlFile, key .. "#parent")
	if v30_ == nil and v31_ == nil then
		Logging.error("Missing name or parent for placeableType \'%s\'", key)
		return false
	end
	local v32_
	if v31_ == nil then
		v32_ = nil
	else
		v32_ = self.types[v31_]
		if v32_ == nil then
			if modName ~= nil and modName ~= "" then
				v31_ = modName .. "." .. v31_
			end
			v32_ = self.types[v31_]
			if v32_ == nil then
				Logging.error("Parent %s type \'%s\' is not defined!", self.typeName, v31_)
				return false
			end
		end
	end
	local v33_ = getXMLString(xmlFile, key .. "#className")
	local v34_ = getXMLString(xmlFile, key .. "#filename")
	if v32_ ~= nil then
		v33_ = v33_ or v32_.className
		v34_ = v34_ or v32_.filename
	end
	if modName ~= nil and modName ~= "" then
		v30_ = modName .. "." .. v30_
	end
	if v33_ == nil or v34_ == nil then
		Logging.error("Can\'t register %s type as its className and filename do not resolve to any valid values. Ensure the types have a className and filename defined, or a base type with them defined.", self.typeName)
	else
		local v35_ = nil
		if modDir ~= nil then
			local v36_
			v34_, v36_ = Utils.getFilename(v34_, modDir)
			if v36_ then
				v33_ = modName .. "." .. v33_
				v35_ = modName
			end
		end
		if Platform.allowsScriptMods or (isDLC or v35_ == nil) then
			self:addType(v30_, v33_, v34_, v35_, v32_)
			if v32_ ~= nil then
				for _, v37_ in ipairs(v32_.specializationNames) do
					self:addSpecialization(v30_, v37_)
				end
			end
			local v38_ = 0
			while true do
				local v39_ = string.format("%s.specialization(%d)", key, v38_)
				if not hasXMLProperty(xmlFile, v39_) then
					break
				end
				local v40_ = getXMLString(xmlFile, v39_ .. "#name")
				if self.specializationManager:getSpecializationByName(v40_) == nil then
					if modName ~= nil then
						v40_ = modName .. "." .. v40_
					end
					if self.specializationManager:getSpecializationByName(v40_) == nil then
						Logging.error("Could not find specialization \'%s\' for %s type \'%s\'.", v40_, self.typeName, v30_)
						v40_ = nil
					end
				end
				if v40_ ~= nil then
					self:addSpecialization(v30_, v40_)
				end
				v38_ = v38_ + 1
			end
			return true
		end
		Logging.error("Can\'t register %s type \'%s\' with scripts on consoles.", self.typeName, v30_)
	end
	return false
end

-- Local values: typeEntry, spec
function TypeManager:addSpecialization(typeName, specName)
	local v44_ = self.types[typeName]
	if v44_ == nil then
		Logging.error("%s type \'%s\' is not defined!", self.typeName, typeName)
		return false
	end
	if v44_.specializationsByName[specName] ~= nil then
		Logging.error("Specialization \'%s\' already exists for %s type \'%s\'!", specName, self.typeName, typeName)
		return false
	end
	local v45_ = self.specializationManager:getSpecializationObjectByName(specName)
	if v45_ == nil then
		Logging.error("%s type \'%s\' has unknown specialization \'%s!", self.typeName, tostring(typeName), (tostring(specName)))
		return false
	end
	local v46_ = v44_.specializations
	table.insert(v46_, v45_)
	local v47_ = v44_.specializationNames
	table.insert(v47_, specName)
	v44_.specializationsByName[specName] = v45_
	return true
end

-- Local values: typeName, typeEntry
function TypeManager:validateTypes()
	for v_u_49_, v_u_50_ in pairs(self.types) do
		g_asyncTaskManager:addSubtask(function()
			-- upvalues: (copy) v_u_50_, (copy) self, (copy) v_u_49_
			for _, v51_ in ipairs(v_u_50_.specializationNames) do
				local v52_ = v_u_50_.specializationsByName[v51_]
				if v52_.prerequisitesPresent == nil then
					Logging.error("Specialisation with name %s is missing prerequisitesPresent function. If no prerequisites are needed, this function can just return true.", v51_)
					self:removeType(v_u_49_)
				elseif not v52_.prerequisitesPresent(v_u_50_.specializations) then
					Logging.error("Not all prerequisites of specialization \'%s\' in %s type \'%s\' are fulfilled", v51_, self.typeName, v_u_49_)
					self:removeType(v_u_49_)
				end
			end
		end)
	end
end

-- Local values: typeName, typeEntry, classObject
function TypeManager:finalizeTypes()
	for v_u_54_, v_u_55_ in pairs(self.types) do
		local v_u_56_ = ClassUtil.getClassObject(v_u_55_.className)
		g_asyncTaskManager:addSubtask(function()
			-- upvalues: (copy) v_u_56_, (copy) v_u_55_
			if v_u_56_.registerEvents ~= nil then
				v_u_56_.registerEvents(v_u_55_)
			end
		end)
		g_asyncTaskManager:addSubtask(function()
			-- upvalues: (copy) v_u_56_, (copy) v_u_55_
			if v_u_56_.registerFunctions ~= nil then
				v_u_56_.registerFunctions(v_u_55_)
			end
		end)
		g_asyncTaskManager:addSubtask(function()
			-- upvalues: (copy) v_u_55_
			for _, v57_ in ipairs(v_u_55_.specializations) do
				if v57_.registerEvents ~= nil then
					v57_.registerEvents(v_u_55_)
				end
			end
		end)
		g_asyncTaskManager:addSubtask(function()
			-- upvalues: (copy) v_u_55_
			for _, v58_ in ipairs(v_u_55_.specializations) do
				if v58_.registerFunctions ~= nil then
					v58_.registerFunctions(v_u_55_)
				end
			end
		end)
		g_asyncTaskManager:addSubtask(function()
			-- upvalues: (copy) v_u_55_
			for _, v59_ in ipairs(v_u_55_.specializations) do
				if v59_.registerOverwrittenFunctions ~= nil then
					v59_.registerOverwrittenFunctions(v_u_55_)
				end
			end
		end)
		g_asyncTaskManager:addSubtask(function()
			-- upvalues: (copy) v_u_55_
			for _, v60_ in ipairs(v_u_55_.specializations) do
				if v60_.registerEventListeners ~= nil then
					v60_.registerEventListeners(v_u_55_)
				end
			end
		end)
		g_asyncTaskManager:addSubtask(function()
			-- upvalues: (copy) v_u_55_, (copy) self, (copy) v_u_54_
			if v_u_55_.customEnvironment ~= "" then
				print(string.format("  Register %s type: %s", self.typeName, v_u_54_))
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

-- Local values: typeEntry
function TypeManager:getTypeByName(typeName, modName)
	if typeName ~= nil then
		local v67_ = self.types[typeName]
		if v67_ ~= nil then
			return v67_
		end
		if g_modIsLoaded[modName] == nil or not g_modIsLoaded[modName] then
			Logging.error("Unable to get type \'%s\' from xml file. Corresponding mod is not loaded", modName)
			return nil
		end
		if v67_ == nil then
			local v68_ = modName .. "." .. typeName
			return self.types[v68_]
		end
	end
	return nil
end

function TypeManager:setXMLSchema(xmlSchema)
	self.xmlSchema = xmlSchema
end

-- Local values: xmlFile, typeName, modName, _, typeEntry, class
function TypeManager:getObjectTypeFromXML(xmlFilename)
	local v73_ = XMLFile.loadIfExists(string.format("%sXML", self.typeName), xmlFilename, self.xmlSchema)
	if v73_ == nil then
		Logging.error("Unable to find %s xml file \'%s\'", self.typeName, xmlFilename)
		return nil, nil
	end
	local v74_ = v73_:getValue(v73_:getRootName() .. "#type")
	v73_:delete()
	if v74_ == nil then
		Logging.error("Missing type declaration in \'%s\'", xmlFilename)
		return nil, nil
	end
	local v75_, _ = Utils.getModNameAndBaseDirectory(xmlFilename)
	local v76_ = self:getTypeByName(v74_, v75_)
	if v76_ == nil then
		Logging.error("Unknown type \'%s\' in \'%s\'", v74_, xmlFilename)
		return nil, nil
	end
	local v77_ = ClassUtil.getClassObject(v76_.className)
	if v77_ ~= nil then
		return v76_, v77_
	end
	Logging.error("Unknown type className \'%s\' of type \'%s\' (%s)", v76_.className, v74_, xmlFilename)
	return nil, nil
end
g_vehicleTypeManager = TypeManager.new("vehicle", "vehicleTypes", "dataS/vehicleTypes.xml", g_specializationManager)
g_placeableTypeManager = TypeManager.new("placeable", "placeableTypes", "dataS/placeableTypes.xml", g_placeableSpecializationManager)
g_handToolTypeManager = TypeManager.new("handTool", "handToolTypes", "dataS/handToolTypes.xml", g_handToolSpecializationManager)
