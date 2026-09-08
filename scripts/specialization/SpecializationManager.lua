-- Local values: SpecializationManager_mt
SpecializationManager = {}
local SpecializationManager_mt = Class(SpecializationManager, AbstractManager)
g_xmlManager:addEarlyCreateSchemaFunction(function()
	SpecializationManager.xmlSchema = XMLSchema.new("specializations")
	SpecializationManager.registerXMLPaths(SpecializationManager.xmlSchema, "specializations.specialization(?)")
end)

function SpecializationManager.registerXMLPaths(xmlSchema, baseKey)
	xmlSchema:register(XMLValueType.STRING, baseKey .. "#name", "The name of the specialization", nil, true)
	xmlSchema:register(XMLValueType.STRING, baseKey .. "#className", "The name of the specialization class", nil, true)
	xmlSchema:register(XMLValueType.STRING, baseKey .. "#filename", "The path of the specialization file", nil, true)
end

-- Upvalues: SpecializationManager_mt
-- Local values: self
function SpecializationManager.new(typeName, xmlFilename, customMt)
	-- upvalues: (copy) SpecializationManager_mt
	local v7_ = AbstractManager.new(customMt or SpecializationManager_mt)
	v7_.typeName = typeName
	v7_.xmlFilename = xmlFilename
	return v7_
end

function SpecializationManager:initDataStructures()
	self.specializations = {}
	self.sortedSpecializations = {}
end

-- Local values: xmlFile, nodeIndex, nodeKey, typeName, className, filename
function SpecializationManager:loadMapData()
	SpecializationManager:superClass().loadMapData(self)
	local v10_ = XMLFile.loadIfExists("SpecializationsXML", self.xmlFilename, SpecializationManager.xmlSchema)
	if v10_ == nil then
		Logging.error("Specializations XML for %q could not be loaded from %q!", self.typeName, self.xmlFilename)
		return false
	end
	for _, v11_ in v10_:iterator("specializations.specialization") do
		local v_u_12_ = v10_:getValue(v11_ .. "#name")
		if string.isNilOrWhitespace(v_u_12_) then
			Logging.xmlWarning(v10_, "Specialization node %q has missing name!", v11_)
		else
			local v_u_13_ = v10_:getValue(v11_ .. "#className")
			if string.isNilOrWhitespace(v_u_13_) then
				Logging.xmlWarning(v10_, "Specialization node %q has missing class name!", v11_)
			else
				local v_u_14_ = v10_:getValue(v11_ .. "#filename")
				if string.isNilOrWhitespace(v_u_14_) then
					Logging.xmlWarning(v10_, "Specialization node %q has missing filename!", v11_)
				else
					g_asyncTaskManager:addSubtask(function()
						-- upvalues: (copy) self, (copy) v_u_12_, (copy) v_u_13_, (copy) v_u_14_
						self:addSpecialization(v_u_12_, v_u_13_, v_u_14_, "")
					end, string.format("SpecializationManager - Add Specialization \'%s\'", v_u_13_))
				end
			end
		end
	end
	v10_:delete()
	g_asyncTaskManager:addSubtask(function()
		-- upvalues: (copy) self
		Logging.info("Loaded %q specializations", self.typeName)
	end)
	return true
end

-- Local values: i, specialization
function SpecializationManager:unloadMapData()
	for v16_ = #self.sortedSpecializations, 1, -1 do
		local v17_ = self:getSpecializationObjectByName(self.sortedSpecializations[v16_].name)
		if v17_ ~= nil and v17_.terminateSpecialization ~= nil then
			v17_.terminateSpecialization()
		end
	end
	SpecializationManager:superClass().unloadMapData(self)
end

-- Local values: specialization, specializationObject
function SpecializationManager:addSpecialization(name, className, filename, customEnvironment)
	if self.specializations[name] ~= nil then
		Logging.error("Specialization \'%s\' already exists. Ignoring it!", (tostring(name)))
		return false
	end
	if className == nil then
		Logging.error("No className specified for specialization \'%s\'", (tostring(name)))
		return false
	end
	if filename == nil then
		Logging.error("No filename specified for specialization \'%s\'", (tostring(name)))
		return false
	end
	local v23_ = {
		["name"] = name,
		["className"] = className,
		["filename"] = filename
	}
	source(filename, customEnvironment)
	local v24_ = ClassUtil.getClassObject(className)
	if v24_ == nil then
		Logging.warning("Specialization %q could not resolve its class! Filepath: %q", name, className)
	else
		v24_.className = className
	end
	self.specializations[name] = v23_
	local v25_ = self.sortedSpecializations
	table.insert(v25_, v23_)
	return true
end

-- Local values: i, specialization
function SpecializationManager:initSpecializations()
	for v27_ = 1, #self.sortedSpecializations do
		local v_u_28_ = self:getSpecializationObjectByName(self.sortedSpecializations[v27_].name)
		if v_u_28_ ~= nil and v_u_28_.initSpecialization ~= nil then
			g_asyncTaskManager:addSubtask(function()
				-- upvalues: (copy) v_u_28_
				v_u_28_.initSpecialization()
			end, string.format("SpecializationManager-initSpecializations - \'%s\'", self.sortedSpecializations[v27_].name))
		end
	end
end

-- Local values: i, specialization
function SpecializationManager:postInitSpecializations()
	for v30_ = 1, #self.sortedSpecializations do
		local v_u_31_ = self:getSpecializationObjectByName(self.sortedSpecializations[v30_].name)
		if v_u_31_ ~= nil and v_u_31_.postInitSpecialization ~= nil then
			g_asyncTaskManager:addSubtask(function()
				-- upvalues: (copy) v_u_31_
				v_u_31_.postInitSpecialization()
			end, string.format("SpecializationManager-postInitSpecializations - \'%s\'", self.sortedSpecializations[v30_].name))
		end
	end
end

function SpecializationManager:getSpecializationByName(name)
	if name == nil then
		return nil
	else
		return self.specializations[name]
	end
end

-- Local values: entry
function SpecializationManager:getSpecializationObjectByName(name)
	local v36_ = self.specializations[name]
	if v36_ == nil then
		return nil
	else
		return ClassUtil.getClassObject(v36_.className)
	end
end

function SpecializationManager:getSpecializations()
	return self.specializations
end
g_specializationManager = SpecializationManager.new("vehicle", "dataS/specializations.xml")
g_placeableSpecializationManager = SpecializationManager.new("placeable", "dataS/placeableSpecializations.xml")
g_handToolSpecializationManager = SpecializationManager.new("handTool", "dataS/handToolSpecializations.xml")
