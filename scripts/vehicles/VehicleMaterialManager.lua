-- Local values: VehicleMaterialManager_mt
VehicleMaterialManager = {}
VehicleMaterialManager.DEFAULT_TEMPLATES_FILENAME = "data/shared/detailLibrary/materialTemplates.xml"
VehicleMaterialManager.DEFAULT_BRAND_TEMPLATES_FILENAME = "data/shared/brandMaterialTemplates.xml"
VehicleMaterialManager.xmlSchema = nil
VehicleMaterialManager.NUM_BITS_TEMPLATE = 16
VehicleMaterialManager.MAX_TEMPLATE_INDEX = 2 ^ VehicleMaterialManager.NUM_BITS_TEMPLATE - 1
source("dataS/scripts/vehicles/VehicleMaterial.lua")
local VehicleMaterialManager_mt = Class(VehicleMaterialManager, AbstractManager)

-- Upvalues: VehicleMaterialManager_mt
-- Local values: self
function VehicleMaterialManager.new(customMt)
	-- upvalues: (copy) VehicleMaterialManager_mt
	local v3_ = AbstractManager.new(customMt or VehicleMaterialManager_mt)
	VehicleMaterialManager.xmlSchema = XMLSchema.new("materialTemplates")
	VehicleMaterialManager.registerXMLPaths(VehicleMaterialManager.xmlSchema, "templates")
	return v3_
end

function VehicleMaterialManager:initDataStructures()
	self.materialTemplates = {}
	self.materialTemplatesByName = {}
	self.modMaterialTemplatesToLoad = {}
end

-- Local values: i, modMaterialTemplate, xmlFile
function VehicleMaterialManager:loadMapData(mapXMLFile, missionInfo, baseDirectory)
	self:loadMaterialTemplates(VehicleMaterialManager.DEFAULT_TEMPLATES_FILENAME)
	self:loadMaterialTemplates(VehicleMaterialManager.DEFAULT_BRAND_TEMPLATES_FILENAME)
	for v6_ = #self.modMaterialTemplatesToLoad, 1, -1 do
		local v7_ = self.modMaterialTemplatesToLoad[v6_]
		local v8_ = XMLFile.load("ModFile", v7_.xmlFilename, g_modDescSchema)
		if v8_ ~= nil then
			self:loadMaterialTemplatesFromXML(v8_, v7_.key, v7_.baseDirectory, v7_.customEnvironment, "calibratedPaint")
			v8_:delete()
		end
		table.remove(self.modMaterialTemplatesToLoad, v6_)
	end
end

function VehicleMaterialManager:addModMaterialTemplatesToLoad(xmlFilename, key, baseDirectory, customEnvironment)
	local v14_ = self.modMaterialTemplatesToLoad
	table.insert(v14_, {
		["xmlFilename"] = xmlFilename,
		["key"] = key,
		["baseDirectory"] = baseDirectory,
		["customEnvironment"] = customEnvironment
	})
end

-- Local values: xmlFile
function VehicleMaterialManager:loadMaterialTemplates(xmlFilename, baseDirectory, customEnvironment)
	local v19_ = XMLFile.load("templates", xmlFilename, VehicleMaterialManager.xmlSchema)
	if v19_ ~= nil then
		self:loadMaterialTemplatesFromXML(v19_, "templates", baseDirectory, customEnvironment)
		v19_:delete()
	end
end

function VehicleMaterialManager:loadMaterialTemplatesFromXML(xmlFile, key, baseDirectory, customEnvironment, parentTemplateDefault)
	local v_u_26_ = xmlFile:getValue(key .. "#parentTemplateDefault", parentTemplateDefault)
	xmlFile:iterate(key .. ".template", function(_, p27_)
		-- upvalues: (copy) xmlFile, (copy) customEnvironment, (ref) v_u_26_, (copy) self, (copy) baseDirectory
		local v28_ = xmlFile:getValue(p27_ .. "#name")
		if v28_ == nil then
			Logging.xmlWarning(xmlFile, "Missing name attribute for \'%s\'", p27_)
			return
		else
			local v29_
			if customEnvironment == nil then
				v29_ = string.upper(v28_)
			else
				v29_ = string.upper(customEnvironment .. "." .. v28_)
			end
			local v30_ = xmlFile:getValue(p27_ .. "#parentTemplate", v_u_26_)
			local v31_
			if v30_ == nil then
				v31_ = nil
			else
				v31_ = self.materialTemplatesByName[string.upper(v30_)]
				if v31_ == nil then
					Logging.xmlWarning(xmlFile, "Unable to find parent template \'%s\' for \'%s\'", v30_, p27_)
					return
				end
			end
			local v32_ = self.materialTemplatesByName[v29_]
			local v33_ = v32_ == nil and {} or v32_
			v33_.name = v29_
			v33_.parentTemplate = v31_ or v33_
			v33_.customEnvironment = customEnvironment
			local v34_ = xmlFile:getValue(p27_ .. "#brand")
			if v34_ ~= nil then
				v33_.brand = g_brandManager:getBrandByName(v34_)
				if v33_.brand == nil then
					Logging.xmlWarning(xmlFile, "Unknown brand \'%s\' defined in material template \'%s\'", v34_, p27_)
				end
			end
			v33_.titleL10N = xmlFile:getValue(p27_ .. "#title")
			v33_.colorScale = xmlFile:getValue(p27_ .. "#colorScale", nil, true)
			v33_.smoothnessScale = xmlFile:getValue(p27_ .. "#smoothnessScale")
			v33_.metalnessScale = xmlFile:getValue(p27_ .. "#metalnessScale")
			v33_.clearCoatSmoothness = xmlFile:getValue(p27_ .. "#clearCoatSmoothness")
			v33_.clearCoatIntensity = xmlFile:getValue(p27_ .. "#clearCoatIntensity")
			v33_.porosity = xmlFile:getValue(p27_ .. "#porosity")
			v33_.detailDiffuse = xmlFile:getValue(p27_ .. "#detailDiffuse")
			if v33_.detailDiffuse ~= nil then
				v33_.detailDiffuse = Utils.getFilename(v33_.detailDiffuse, baseDirectory)
				if not textureFileExists(v33_.detailDiffuse) then
					Logging.xmlWarning(xmlFile, "Unable to find detail texture \'%s\' in \'%s\'", v33_.detailDiffuse, p27_)
					v33_.detailDiffuse = nil
				end
			end
			if v33_.detailDiffuse == nil and v33_.parentTemplate.detailDiffuse == nil then
				Logging.xmlWarning(xmlFile, "Missing detail diffuse texture for \'%s\'", p27_)
				return
			else
				v33_.detailNormal = xmlFile:getValue(p27_ .. "#detailNormal")
				if v33_.detailNormal ~= nil then
					v33_.detailNormal = Utils.getFilename(v33_.detailNormal, baseDirectory)
					if not textureFileExists(v33_.detailNormal) then
						Logging.xmlWarning(xmlFile, "Unable to find detail texture \'%s\' in \'%s\'", v33_.detailNormal, p27_)
						v33_.detailNormal = nil
					end
				end
				if v33_.detailNormal == nil and v33_.parentTemplate.detailNormal == nil then
					Logging.xmlWarning(xmlFile, "Missing detail normal texture for \'%s\'", p27_)
					return
				else
					v33_.detailSpecular = xmlFile:getValue(p27_ .. "#detailSpecular")
					if v33_.detailSpecular ~= nil then
						v33_.detailSpecular = Utils.getFilename(v33_.detailSpecular, baseDirectory)
						if not textureFileExists(v33_.detailSpecular) then
							Logging.xmlWarning(xmlFile, "Unable to find detail texture \'%s\' in \'%s\'", v33_.detailSpecular, p27_)
							v33_.detailSpecular = nil
						end
					end
					if v33_.detailSpecular == nil and v33_.parentTemplate.detailSpecular == nil then
						Logging.xmlWarning(xmlFile, "Missing detail specular texture for \'%s\'", p27_)
					else
						local v35_ = self.materialTemplates
						table.insert(v35_, v33_)
						self.materialTemplatesByName[v29_] = v33_
					end
				end
			end
		end
	end)
end

-- Local values: template
function VehicleMaterialManager:getMaterialTemplateByName(name, customEnvironment)
	if name == nil then
		return nil
	end
	if customEnvironment ~= nil then
		local v39_ = self.materialTemplatesByName[string.upper(customEnvironment .. "." .. name)]
		if v39_ ~= nil then
			return v39_
		end
	end
	return self.materialTemplatesByName[string.upper(name)]
end

-- Local values: materialTemplate
function VehicleMaterialManager:getMaterialTemplateColorByName(name, customEnvironment)
	if name ~= nil then
		local v43_ = self:getMaterialTemplateByName(string.upper(name), customEnvironment)
		if v43_ ~= nil and v43_.colorScale ~= nil then
			return {
				v43_.colorScale[1],
				v43_.colorScale[2],
				v43_.colorScale[3],
				0
			}
		end
	end
	return nil
end

-- Local values: materialTemplate, title
function VehicleMaterialManager:getMaterialTemplateColorAndTitleByName(name, customEnvironment)
	if name ~= nil then
		local v47_ = self:getMaterialTemplateByName(string.upper(name), customEnvironment)
		if v47_ ~= nil then
			local v48_
			if v47_.brand == nil then
				v48_ = nil
			else
				v48_ = v47_.brand.title
			end
			if v47_.titleL10N ~= nil then
				v48_ = (v48_ == nil and "" or v48_ .. " ") .. g_i18n:convertText(v47_.titleL10N, v47_.customEnvironment)
			end
			if v47_.colorScale == nil then
				return { 1, 1, 1 }, v48_
			else
				return table.clone(v47_.colorScale), v48_
			end
		end
	end
	return nil, nil
end

-- Local values: i, materialTemplate
function VehicleMaterialManager:getMaterialTemplateIndexByName(name)
	if name ~= nil then
		local v51_ = string.upper(name)
		for v52_, v53_ in ipairs(self.materialTemplates) do
			if v53_.name == v51_ then
				return v52_
			end
		end
	end
	return 1
end

-- Local values: template
function VehicleMaterialManager:getMaterialTemplateNameByIndex(index)
	return (self.materialTemplates[index] or self.materialTemplates[1]).name
end

-- Local values: isMetallic, isMat, materialTemplateNameLower
function VehicleMaterialManager:getMaterialTemplateFinish(materialTemplateName)
	local v57_ = false
	local v58_ = false
	if materialTemplateName == nil then
		return v57_, v58_
	end
	local v59_ = string.lower(materialTemplateName)
	return (v59_:contains("silver") or (v59_:contains("copper") or (v59_:contains("gold") or (v59_:contains("bronze") or (v59_:contains("chrome") or v59_:contains("metallic")))))) and true or v57_, v59_:contains("matpaint") and true or v58_
end

function VehicleMaterialManager.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. "#id", "File Identifier")
	schema:register(XMLValueType.STRING, basePath .. "#name", "File Name")
	schema:register(XMLValueType.STRING, basePath .. "#parentTemplateDefault", "Name of default parent template")
	schema:register(XMLValueType.STRING, basePath .. "#parentTemplateFilename", "Path to parent template file")
	schema:register(XMLValueType.STRING, basePath .. ".template(?)#name", "Name of template")
	schema:register(XMLValueType.STRING, basePath .. ".template(?)#title", "Name of the color to display in the shop")
	schema:register(XMLValueType.STRING, basePath .. ".template(?)#description", "Descrpition text of the template")
	schema:register(XMLValueType.INT, basePath .. ".template(?)#usage", "Usage of the color")
	schema:register(XMLValueType.STRING, basePath .. ".template(?)#parentTemplate", "Name of parent template", "templates#parentTemplateDefault")
	schema:register(XMLValueType.STRING, basePath .. ".template(?)#brand", "Brand identifier")
	schema:register(XMLValueType.VECTOR_3, basePath .. ".template(?)#colorScale", "Color values (sRGB)")
	schema:register(XMLValueType.FLOAT, basePath .. ".template(?)#smoothnessScale")
	schema:register(XMLValueType.FLOAT, basePath .. ".template(?)#metalnessScale")
	schema:register(XMLValueType.FLOAT, basePath .. ".template(?)#clearCoatSmoothness")
	schema:register(XMLValueType.FLOAT, basePath .. ".template(?)#clearCoatIntensity")
	schema:register(XMLValueType.FLOAT, basePath .. ".template(?)#porosity")
	schema:register(XMLValueType.STRING, basePath .. ".template(?)#category", "Category name (Used by DCC Tool)")
	schema:register(XMLValueType.STRING, basePath .. ".template(?)#iconFilename", "Icon filename (Used by DCC Tool)")
	schema:register(XMLValueType.STRING, basePath .. ".template(?)#detailDiffuse", "Detail diffuse texture")
	schema:register(XMLValueType.STRING, basePath .. ".template(?)#detailNormal", "Detail normal texture")
	schema:register(XMLValueType.STRING, basePath .. ".template(?)#detailSpecular", "Detail specular texture")
	schema:register(XMLValueType.STRING, basePath .. ".template(?).colorScan#filename", "Path to scan reference")
	schema:register(XMLValueType.BOOL, basePath .. ".template(?).colorScan#channelR", "Calibrate red channel", true)
	schema:register(XMLValueType.BOOL, basePath .. ".template(?).colorScan#channelG", "Calibrate green channel", true)
	schema:register(XMLValueType.BOOL, basePath .. ".template(?).colorScan#channelB", "Calibrate blue channel", true)
	schema:register(XMLValueType.BOOL, basePath .. ".template(?).colorScan#channelSmoothness", "Calibrate smoothness", true)
	schema:register(XMLValueType.BOOL, basePath .. ".template(?).colorScan#channelMetalness", "Calibrate metalness", true)
end
g_vehicleMaterialManager = VehicleMaterialManager.new()
