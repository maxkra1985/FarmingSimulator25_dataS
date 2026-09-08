-- Local values: ConstructionBrushTypeManager_mt
ConstructionBrushTypeManager = {}
local ConstructionBrushTypeManager_mt = Class(ConstructionBrushTypeManager, AbstractManager)

-- Upvalues: ConstructionBrushTypeManager_mt
-- Local values: self
function ConstructionBrushTypeManager.new(customMt)
	-- upvalues: (copy) ConstructionBrushTypeManager_mt
	return ConstructionBrushTypeManager:superClass().new(customMt or ConstructionBrushTypeManager_mt)
end

function ConstructionBrushTypeManager:initDataStructures()
	self.brushTypes = {}
	self.brushTypesSorted = {}
end

-- Local values: xmlFile
function ConstructionBrushTypeManager:loadMapData()
	ConstructionBrushTypeManager:superClass().loadMapData(self)
	local v_u_5_ = XMLFile.load("BrushTypesXML", "dataS/constructionBrushTypes.xml")
	if v_u_5_ ~= nil then
		v_u_5_:iterate("constructionBrushTypes.constructionBrushType", function(_, p6_)
			-- upvalues: (copy) v_u_5_, (copy) self
			local v7_ = v_u_5_:getString(p6_ .. "#name")
			if v7_ ~= nil then
				self:addBrushType(v7_, v_u_5_:getString(p6_ .. "#className"), v_u_5_:getString(p6_ .. "#filename"), "")
			end
		end)
		v_u_5_:delete()
		Logging.info("  Loaded construction brush types")
	end
	return true
end

-- Local values: typeEntry
function ConstructionBrushTypeManager:addBrushType(typeName, className, filename, customEnvironment)
	if not ClassUtil.getIsValidClassName(typeName) then
		printWarning("Warning: Invalid construction brush typeName: " .. tostring(typeName) .. ". Ignoring type!")
		return false
	end
	if self.brushTypes[typeName] ~= nil then
		printError("Error: Construction brush type \'" .. tostring(typeName) .. "\' already exists. Ignoring it!")
		return false
	end
	if className == nil then
		printError("Error: No className specified for construction brush type \'" .. tostring(typeName) .. "\'. Ignoring it!")
		return false
	end
	if filename == nil then
		printError("Error: No filename specified for construction brush type \'" .. tostring(typeName) .. "\'. Ignoring it!")
		return false
	end
	source(filename, customEnvironment)
	local v13_ = {
		["name"] = typeName,
		["className"] = className,
		["filename"] = filename
	}
	if customEnvironment ~= "" then
		print("  Register construction brush type: " .. tostring(typeName))
	end
	self.brushTypes[typeName] = v13_
	local v14_ = self.brushTypesSorted
	table.insert(v14_, v13_)
	return true
end

-- Local values: brushTypes
function ConstructionBrushTypeManager:getClassObjectByTypeName(typeName)
	if typeName ~= nil then
		local v17_ = self.brushTypes[typeName]
		if v17_ ~= nil then
			return ClassUtil.getClassObject(v17_.className)
		end
	end
	return nil
end

-- Local values: _, typeEntry, classObj
function ConstructionBrushTypeManager:initBrushTypes()
	for _, v19_ in pairs(self.brushTypesSorted) do
		local v20_ = ClassUtil.getClassObject(v19_.className)
		if v20_ == nil then
			Logging.warning("Brush class \'%s\' not defined", v19_.className)
		elseif rawget(v20_, "initBrushType") then
			v20_.initBrushType()
		end
	end
end

function ConstructionBrushTypeManager:getBrushTypes()
	return self.brushTypes
end
g_constructionBrushTypeManager = ConstructionBrushTypeManager.new()
