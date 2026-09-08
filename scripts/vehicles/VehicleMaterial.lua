-- Local values: VehicleMaterial_mt
VehicleMaterial = {}
local VehicleMaterial_mt = Class(VehicleMaterial)

-- Upvalues: VehicleMaterial_mt
-- Local values: self
function VehicleMaterial.new(baseDirectory, customMt)
	-- upvalues: (copy) VehicleMaterial_mt
	local v4_ = customMt or VehicleMaterial_mt
	local v5_ = setmetatable({}, v4_)
	v5_.baseDirectory = baseDirectory
	v5_.colorOnly = false
	return v5_
end

-- Local values: material
function VehicleMaterial:clone()
	local v7_ = VehicleMaterial.new(self.baseDirectory)
	v7_.targetMaterialSlotName = self.targetMaterialSlotName
	v7_.templateName = self.templateName
	v7_.materialTemplate = self.materialTemplate
	v7_.colorScale = self.colorScale
	v7_.smoothnessScale = self.smoothnessScale
	v7_.metalnessScale = self.metalnessScale
	v7_.clearCoatSmoothness = self.clearCoatSmoothness
	v7_.clearCoatIntensity = self.clearCoatIntensity
	v7_.porosity = self.porosity
	v7_.detailDiffuse = self.detailDiffuse
	v7_.detailNormal = self.detailNormal
	v7_.detailSpecular = self.detailSpecular
	v7_.diffuseMap = self.diffuseMap
	v7_.normalMap = self.normalMap
	v7_.specularMap = self.specularMap
	return v7_
end

function VehicleMaterial:setColor(r, g, b)
	if r == nil then
		return
	elseif type(r) == "table" then
		self.colorScale = { r[1], r[2], r[3] }
	else
		self.colorScale = { r, g, b }
	end
end

function VehicleMaterial:getBrightness()
	if self.colorScale == nil then
		return nil
	else
		return MathUtil.getBrightnessFromColor(self.colorScale[1], self.colorScale[2], self.colorScale[3])
	end
end

function VehicleMaterial:setTemplateName(templateName, colorOnly, customEnvironment)
	self.templateName = templateName
	self.materialTemplate = g_vehicleMaterialManager:getMaterialTemplateByName(templateName, customEnvironment)
	if self.materialTemplate == nil then
		return false
	end
	self.colorScale = self.materialTemplate.colorScale or self.materialTemplate.parentTemplate.colorScale
	if self.colorScale == nil then
		self.colorScale = { 1, 1, 1 }
	end
	if colorOnly then
		return true
	end
	self.smoothnessScale = self.materialTemplate.smoothnessScale or (self.materialTemplate.parentTemplate.smoothnessScale or 1)
	self.metalnessScale = self.materialTemplate.metalnessScale or (self.materialTemplate.parentTemplate.metalnessScale or 1)
	self.clearCoatSmoothness = self.materialTemplate.clearCoatSmoothness or (self.materialTemplate.parentTemplate.clearCoatSmoothness or 0)
	self.clearCoatIntensity = self.materialTemplate.clearCoatIntensity or (self.materialTemplate.parentTemplate.clearCoatIntensity or 0)
	self.porosity = self.materialTemplate.porosity or (self.materialTemplate.parentTemplate.porosity or 0)
	self.detailDiffuse = self.materialTemplate.detailDiffuse or (self.materialTemplate.parentTemplate.detailDiffuse or "data/shared/detailLibrary/nonMetallic/default_diffuse.png")
	self.detailNormal = self.materialTemplate.detailNormal or (self.materialTemplate.parentTemplate.detailNormal or "data/shared/detailLibrary/nonMetallic/default_normal.png")
	self.detailSpecular = self.materialTemplate.detailSpecular or (self.materialTemplate.parentTemplate.detailSpecular or "data/shared/detailLibrary/nonMetallic/default_specular.png")
	return true
end

-- Local values: templateName, materialTemplateUseColorOnly, colorStr, colorTemplate, detailDiffuse, detailNormal, detailSpecular, diffuseMap, normalMap, specularMap
function VehicleMaterial:loadFromXML(xmlFile, key, customEnvironment)
	self.targetMaterialSlotName = xmlFile:getValue(key .. "#materialSlotName")
	local v21_ = self.templateName or xmlFile:getValue(key .. "#materialTemplateName")
	if v21_ ~= nil and (v21_ ~= self.templateName and not self:setTemplateName(v21_, xmlFile:getValue(key .. "#materialTemplateUseColorOnly", false), customEnvironment)) then
		Logging.xmlWarning(xmlFile.xmlFile or xmlFile, "Unable to find material template \'%s\' in \'%s\'", v21_, key)
		return false
	end
	local v22_ = xmlFile:getValue(key .. ".colorScale#value")
	if v22_ ~= nil then
		local v23_ = g_vehicleMaterialManager:getMaterialTemplateByName(v22_, customEnvironment)
		if v23_ == nil then
			self.colorScale = string.getVector(v22_, 3) or self.colorScale
		else
			self.colorScale = v23_.colorScale or v23_.parentTemplate.colorScale
		end
	end
	self.smoothnessScale = xmlFile:getValue(key .. ".smoothness#value", self.smoothnessScale)
	self.metalnessScale = xmlFile:getValue(key .. ".metalness#value", self.metalnessScale)
	self.clearCoatSmoothness = xmlFile:getValue(key .. ".clearCoat#smoothness", self.clearCoatSmoothness)
	self.clearCoatIntensity = xmlFile:getValue(key .. ".clearCoat#intensity", self.clearCoatIntensity)
	self.detailDiffuse = xmlFile:getValue(key .. ".detail#diffuse", nil, self.baseDirectory) or self.detailDiffuse
	self.detailNormal = xmlFile:getValue(key .. ".detail#normal", nil, self.baseDirectory) or self.detailNormal
	self.detailSpecular = xmlFile:getValue(key .. ".detail#specular", nil, self.baseDirectory) or self.detailSpecular
	self.diffuseMap = xmlFile:getValue(key .. ".textures#diffuse", nil, self.baseDirectory) or self.diffuseMap
	self.normalMap = xmlFile:getValue(key .. ".textures#normal", nil, self.baseDirectory) or self.normalMap
	self.specularMap = xmlFile:getValue(key .. ".textures#specular", nil, self.baseDirectory) or self.specularMap
	return (self.colorScale ~= nil or (self.smoothnessScale ~= nil or (self.metalnessScale ~= nil or (self.clearCoatSmoothness ~= nil or (self.clearCoatIntensity ~= nil or (self.porosity ~= nil or (self.detailDiffuse ~= nil or (self.detailNormal ~= nil or (self.detailSpecular ~= nil or (self.diffuseMap ~= nil or self.normalMap ~= nil)))))))))) and true or self.specularMap ~= nil
end

-- Local values: templateName, materialTemplateUseColorOnly, templateNameColor, materialTemplate
function VehicleMaterial:loadShortFromXML(xmlFile, key, customEnvironment)
	self.targetMaterialSlotName = xmlFile:getValue(key .. "#materialSlotName")
	local v28_ = self.templateName or xmlFile:getValue(key .. "#materialTemplateName")
	if v28_ == nil then
		return false
	end
	if not self:setTemplateName(v28_, xmlFile:getValue(key .. "#materialTemplateUseColorOnly", false), customEnvironment) then
		Logging.xmlWarning(xmlFile.xmlFile or xmlFile, "Unable to find material template \'%s\' in \'%s\'", v28_, key)
		return false
	end
	local v29_ = xmlFile:getValue(key .. "#materialTemplateNameColor")
	if v29_ ~= nil then
		local v30_ = g_vehicleMaterialManager:getMaterialTemplateByName(v29_, customEnvironment)
		if v30_ ~= nil then
			self.colorScale = v30_.colorScale or v30_.parentTemplate.colorScale
		end
	end
	return true
end

-- Local values: success, i, component
function VehicleMaterial:applyToVehicle(vehicle, targetMaterialSlotName)
	local v34_ = false
	for _, v35_ in ipairs(vehicle.components) do
		v34_ = self:apply(v35_.node, targetMaterialSlotName) or v34_
	end
	return v34_
end

-- Local values: success, i, materialSlotName, i
function VehicleMaterial:apply(node, targetMaterialSlotName, colorOnly)
	local v40_ = false
	local v41_ = targetMaterialSlotName or self.targetMaterialSlotName
	if getHasClassId(node, ClassIds.SHAPE) then
		for v42_ = 1, getNumOfMaterials(node) do
			if getMaterialSlotName(node, v42_ - 1) == v41_ or v41_ == nil then
				self:applyToMaterial(node, v42_ - 1, colorOnly)
				v40_ = true
			end
		end
	end
	for v43_ = 1, getNumOfChildren(node) do
		v40_ = self:apply(getChildAt(node, v43_ - 1), v41_, colorOnly) or v40_
	end
	return v40_
end

-- Local values: materialId, newMaterialId
function VehicleMaterial:applyToMaterial(node, materialIndex, colorOnly)
	if self.colorScale ~= nil then
		setShaderParameter(node, "colorScale", self.colorScale[1], self.colorScale[2], self.colorScale[3], nil, false, materialIndex)
	end
	if not colorOnly then
		if self.smoothnessScale ~= nil then
			setShaderParameter(node, "smoothnessScale", self.smoothnessScale, nil, nil, nil, false, materialIndex)
		end
		if self.metalnessScale ~= nil then
			setShaderParameter(node, "metalnessScale", self.metalnessScale, nil, nil, nil, false, materialIndex)
		end
		if self.clearCoatSmoothness ~= nil then
			setShaderParameter(node, "clearCoatSmoothness", self.clearCoatSmoothness, nil, nil, nil, false, materialIndex)
		end
		if self.clearCoatIntensity ~= nil then
			setShaderParameter(node, "clearCoatIntensity", self.clearCoatIntensity, nil, nil, nil, false, materialIndex)
		end
		if self.porosity ~= nil then
			setShaderParameter(node, "porosity", self.porosity, nil, nil, nil, false, materialIndex)
		end
		local v48_ = getMaterial(node, materialIndex)
		local v49_
		if self.detailDiffuse == nil then
			v49_ = v48_
		else
			v49_ = setMaterialCustomMapFromFile(v48_, "detailDiffuse", self.detailDiffuse, false, true, false)
		end
		if self.detailNormal ~= nil then
			v49_ = setMaterialCustomMapFromFile(v49_, "detailNormal", self.detailNormal, false, false, false)
		end
		if self.detailSpecular ~= nil then
			v49_ = setMaterialCustomMapFromFile(v49_, "detailSpecular", self.detailSpecular, false, false, false)
		end
		if self.diffuseMap ~= nil then
			v49_ = setMaterialDiffuseMapFromFile(v49_, self.diffuseMap, false, true, false)
		end
		if self.normalMap ~= nil then
			v49_ = setMaterialNormalMapFromFile(v49_, self.normalMap, false, false, false)
		end
		if self.specularMap ~= nil then
			v49_ = setMaterialGlossMapFromFile(v49_, self.specularMap, false, false, false)
		end
		if v49_ ~= v48_ then
			setMaterial(node, v49_, materialIndex)
		end
	end
end

-- Local values: r, g, b, _, smoothness, metalness, clearCoatSmoothness, clearCoatIntensity, porosity, detailDiffuse, detailNormal, detailSpecular, diffuseMap, normalMap, specularMap
function VehicleMaterial:getIsApplied(node, materialId, checkColor)
	if checkColor ~= false then
		local v53_, v54_, v55_, _ = getMaterialCustomParameter(materialId, "colorScale")
		if self.colorScale == nil then
			if v53_ ~= 1 or (v54_ ~= 1 or v55_ ~= 1) then
				return false
			end
		elseif v53_ ~= self.colorScale[1] or (v54_ ~= self.colorScale[2] or v55_ ~= self.colorScale[3]) then
			return false
		end
	end
	local v56_ = getMaterialCustomParameter(materialId, "smoothnessScale")
	if self.smoothnessScale ~= nil and v56_ ~= self.smoothnessScale then
		return false
	end
	if self.smoothnessScale == nil and v56_ ~= 1 then
		return false
	end
	local v57_ = getMaterialCustomParameter(materialId, "metalnessScale")
	if self.metalnessScale ~= nil and v57_ ~= self.metalnessScale then
		return false
	end
	if self.metalnessScale == nil and v57_ ~= 1 then
		return false
	end
	local v58_ = getMaterialCustomParameter(materialId, "clearCoatSmoothness")
	if self.clearCoatSmoothness ~= nil and v58_ ~= self.clearCoatSmoothness then
		return false
	end
	if self.clearCoatSmoothness == nil and v58_ ~= 0 then
		return false
	end
	local v59_ = getMaterialCustomParameter(materialId, "clearCoatIntensity")
	if self.clearCoatIntensity ~= nil and v59_ ~= self.clearCoatIntensity then
		return false
	end
	if self.clearCoatIntensity == nil and v59_ ~= 0 then
		return false
	end
	local v60_ = getMaterialCustomParameter(materialId, "porosity")
	if self.porosity ~= nil and v60_ ~= self.porosity then
		return false
	end
	if self.porosity == nil and v60_ ~= 0 then
		return false
	end
	local v61_ = getMaterialCustomMapFilename(materialId, "detailDiffuse")
	if self.detailDiffuse ~= nil and v61_ ~= self.detailDiffuse then
		return false
	end
	local v62_ = getMaterialCustomMapFilename(materialId, "detailNormal")
	if self.detailNormal ~= nil and v62_ ~= self.detailNormal then
		return false
	end
	local v63_ = getMaterialCustomMapFilename(materialId, "detailSpecular")
	if self.detailSpecular ~= nil and v63_ ~= self.detailSpecular then
		return false
	end
	local v64_ = getMaterialDiffuseMapFilename(materialId)
	if self.diffuseMap ~= nil and v64_ ~= self.diffuseMap then
		return false
	end
	local v65_ = getMaterialNormalMapFilename(materialId)
	if self.normalMap ~= nil and v65_ ~= self.normalMap then
		return false
	end
	local v66_ = getMaterialGlossMapFilename(materialId)
	return self.specularMap == nil or v66_ == self.specularMap
end

function VehicleMaterial.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. "#materialSlotName", "Material slot name in the i3d file")
	schema:register(XMLValueType.STRING, basePath .. "#materialTemplateName", "Name of template to apply (all attributes will be used from template)")
	schema:registerAutoCompletionDataSource(basePath .. "#materialTemplateName", "$data/shared/brandMaterialTemplates.xml", "templates.template#name")
	schema:register(XMLValueType.BOOL, basePath .. "#materialTemplateUseColorOnly", "If \'true\', only the color is used from the material template. The rest from the i3d file.", false)
	schema:register(XMLValueType.STRING, basePath .. ".colorScale#value", "Material color if it should not be used from configuration (can also be a different material template, from which then ONLY the color is taken)")
	schema:register(XMLValueType.FLOAT, basePath .. ".smoothness#value", "Smoothness value")
	schema:register(XMLValueType.FLOAT, basePath .. ".metalness#value", "Metalness value")
	schema:register(XMLValueType.FLOAT, basePath .. ".clearCoat#smoothness", "Smoothness of clear coat")
	schema:register(XMLValueType.FLOAT, basePath .. ".clearCoat#intensity", "Intensity of clear coat")
	schema:register(XMLValueType.FILENAME, basePath .. ".detail#diffuse", "Path to detail diffuse texture")
	schema:register(XMLValueType.FILENAME, basePath .. ".detail#normal", "Path to detail normal texture")
	schema:register(XMLValueType.FILENAME, basePath .. ".detail#specular", "Path to detail specular texture")
	schema:register(XMLValueType.FILENAME, basePath .. ".textures#diffuse", "Path to diffuse texture")
	schema:register(XMLValueType.FILENAME, basePath .. ".textures#normal", "Path to normal texture")
	schema:register(XMLValueType.FILENAME, basePath .. ".textures#specular", "Path to specular texture")
end

function VehicleMaterial.registerShortXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. "#materialSlotName", "Material slot name in the i3d file")
	schema:register(XMLValueType.STRING, basePath .. "#materialTemplateName", "Name of template to apply (all attributes will be used from template)")
	schema:registerAutoCompletionDataSource(basePath .. "#materialTemplateName", "$data/shared/brandMaterialTemplates.xml", "templates.template#name")
	schema:register(XMLValueType.BOOL, basePath .. "#materialTemplateUseColorOnly", "If \'true\', only the color is used from the material template. The rest from the i3d file.", false)
	schema:register(XMLValueType.STRING, basePath .. "#materialTemplateNameColor", "Name of the material template that is used ONLY for the color")
	schema:registerAutoCompletionDataSource(basePath .. "#materialTemplateNameColor", "$data/shared/brandMaterialTemplates.xml", "templates.template#name")
end
