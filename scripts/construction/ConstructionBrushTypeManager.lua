ConstructionBrushTypeManager = {}
local ConstructionBrushTypeManager_mt = Class(ConstructionBrushTypeManager, AbstractManager)
function ConstructionBrushTypeManager.new(customMt)
	local self = ConstructionBrushTypeManager:superClass().new(customMt or ConstructionBrushTypeManager_mt)
	return self
end
function ConstructionBrushTypeManager:initDataStructures()
	self.brushTypes = {}
	self.brushTypesSorted = {}
end
function ConstructionBrushTypeManager:loadMapData()
	ConstructionBrushTypeManager:superClass().loadMapData(self)
	local xmlFile = XMLFile.load("BrushTypesXML", "dataS/constructionBrushTypes.xml")
	if xmlFile ~= nil then
		xmlFile:iterate("constructionBrushTypes.constructionBrushType", function(index, key)
			local typeName = xmlFile:getString(key .. "#name")
			if typeName == nil then
				return
			else
				local className = xmlFile:getString(key .. "#className")
				local filename = xmlFile:getString(key .. "#filename")
				self:addBrushType(typeName, className, filename, "")
			end
		end)
		xmlFile:delete()
		Logging.info("  Loaded construction brush types")
	end
	return true
end
function ConstructionBrushTypeManager:addBrushType(typeName, className, filename, customEnvironment)
	if not ClassUtil.getIsValidClassName(typeName) then
		printWarning("Warning: Invalid construction brush typeName: " .. tostring(typeName) .. ". Ignoring type!")
		return false
	elseif self.brushTypes[typeName] ~= nil then
		printError("Error: Construction brush type '" .. tostring(typeName) .. "' already exists. Ignoring it!")
		return false
	elseif className == nil then
		printError("Error: No className specified for construction brush type '" .. tostring(typeName) .. "'. Ignoring it!")
		return false
	elseif filename == nil then
		printError("Error: No filename specified for construction brush type '" .. tostring(typeName) .. "'. Ignoring it!")
		return false
	else
		source(filename, customEnvironment)
		local typeEntry = {}
		typeEntry.name = typeName
		typeEntry.className = className
		typeEntry.filename = filename
		if customEnvironment ~= "" then
			print("  Register construction brush type: " .. tostring(typeName))
		end
		self.brushTypes[typeName] = typeEntry
		table.insert(self.brushTypesSorted, typeEntry)
		return true
	end
end
function ConstructionBrushTypeManager:getClassObjectByTypeName(typeName)
	if typeName ~= nil then
		local brushTypes = self.brushTypes[typeName]
		if brushTypes ~= nil then
			return ClassUtil.getClassObject(brushTypes.className)
		end
	end
	return nil
end
function ConstructionBrushTypeManager:initBrushTypes()
	for _, typeEntry in pairs(self.brushTypesSorted) do
		local classObj = ClassUtil.getClassObject(typeEntry.className)
		if classObj ~= nil then
			if rawget(classObj, "initBrushType") then
				classObj.initBrushType()
			end
		else
			Logging.warning("Brush class '%s' not defined", typeEntry.className)
		end
	end
end
function ConstructionBrushTypeManager:getBrushTypes()
	return self.brushTypes
end
g_constructionBrushTypeManager = ConstructionBrushTypeManager.new()
