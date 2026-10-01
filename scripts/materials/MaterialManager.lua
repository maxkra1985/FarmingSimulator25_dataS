MaterialManager = {}
MaterialManager.fontMaterialXMLSchema = nil
MaterialManager.DEFAULT_FONT_MATERIAL_XML = "data/shared/alphabet/fonts.xml"
MaterialManager.FONT_CHARACTER_TYPE = {}
MaterialManager.FONT_CHARACTER_TYPE.NUMERICAL = 0
MaterialManager.FONT_CHARACTER_TYPE.ALPHABETICAL = 1
MaterialManager.FONT_CHARACTER_TYPE.SPECIAL = 2
MaterialType = nil
local MaterialManager_mt = Class(MaterialManager, AbstractManager)
function MaterialManager.new(customMt)
	local self = AbstractManager.new(customMt or MaterialManager_mt)
	MaterialManager.fontMaterialXMLSchema = XMLSchema.new("fontMaterials")
	FontMaterial.registerXMLPaths(MaterialManager.fontMaterialXMLSchema)
	return self
end
function MaterialManager:initDataStructures()
	self.nameToIndex = {}
	self.materialTypes = {}
	self.materials = {}
	self.particleMaterials = {}
	self.modMaterialHoldersToLoad = {}
	self.fontMaterials = {}
	self.fontMaterialsByName = {}
	self.baseMaterials = {}
	self.baseMaterialsByName = {}
	self.loadedMaterialHolderNodes = {}
end
function MaterialManager:loadMapData(xmlFile, missionInfo, baseDirectory, finishedLoadingCallback, callbackTarget)
	MaterialManager:superClass().loadMapData(self)
	self:addMaterialType("fillplane")
	self:addMaterialType("icon")
	self:addMaterialType("unloading")
	self:addMaterialType("smoke")
	self:addMaterialType("straw")
	self:addMaterialType("chopper")
	self:addMaterialType("soil")
	self:addMaterialType("sprayer")
	self:addMaterialType("spreader")
	self:addMaterialType("pipe")
	self:addMaterialType("mower")
	self:addMaterialType("belt")
	self:addMaterialType("belt_cropDirt")
	self:addMaterialType("belt_cropClean")
	self:addMaterialType("leveler")
	self:addMaterialType("washer")
	self:addMaterialType("pickup")
	MaterialType = self.nameToIndex
	self.finishedLoadingCallback = finishedLoadingCallback
	self.callbackTarget = callbackTarget
	self:loadFontMaterialsXML(MaterialManager.DEFAULT_FONT_MATERIAL_XML, nil, self.baseDirectory)
	return true
end
function MaterialManager:unloadMapData()
	for _, node in ipairs(self.loadedMaterialHolderNodes) do
		delete(node)
	end
	if self.xmlFile ~= nil then
		self.xmlFile:delete()
		self.xmlFile = nil
	end
	for _, font in ipairs(self.fontMaterials) do
		delete(font.materialNode)
		if font.materialNodeNoNormal ~= nil then
			delete(font.materialNodeNoNormal)
		end
		if font.characterShape ~= nil then
			delete(font.characterShape)
		end
		if font.sharedLoadRequestId == nil then
			continue
		end
		g_i3DManager:releaseSharedI3DFile(font.sharedLoadRequestId)
	end
	MaterialManager:superClass().unloadMapData(self)
end
function MaterialManager:addMaterialType(name)
	if not ClassUtil.getIsValidIndexName(name) then
		printWarning("Warning: '" .. tostring(name) .. "' is not a valid name for a materialType. Ignoring it!")
		return nil
	else
		name = string.upper(name)
		if self.nameToIndex[name] == nil then
			table.insert(self.materialTypes, name)
			self.nameToIndex[name] = #self.materialTypes
		end
		return nil
	end
end
function MaterialManager:getMaterialTypeByName(name)
	if name ~= nil then
		name = string.upper(name)
		if self.nameToIndex[name] ~= nil then
			return name
		end
	end
	return nil
end
function MaterialManager:addBaseMaterial(materialName, materialId)
	self.baseMaterialsByName[string.upper(materialName)] = materialId
	table.insert(self.baseMaterials, materialId)
end
function MaterialManager:getBaseMaterialByName(materialName)
	if materialName ~= nil then
		return self.baseMaterialsByName[string.upper(materialName)]
	else
		return nil
	end
end
function MaterialManager:addMaterial(fillTypeIndex, materialType, materialIndex, materialId)
	self:addMaterialToTarget(self.materials, fillTypeIndex, materialType, materialIndex, materialId)
end
function MaterialManager:addParticleMaterial(fillTypeIndex, materialType, materialIndex, materialId)
	self:addMaterialToTarget(self.particleMaterials, fillTypeIndex, materialType, materialIndex, materialId)
end
function MaterialManager:addMaterialToTarget(target, fillTypeIndex, materialType, materialIndex, materialId)
	if fillTypeIndex == nil or materialType == nil or materialIndex == nil or materialId == nil then
		return
	end
	if target[fillTypeIndex] == nil then
		target[fillTypeIndex] = {}
	end
	local fillTypeMaterials = target[fillTypeIndex]
	if fillTypeMaterials[materialType] == nil then
		fillTypeMaterials[materialType] = {}
	end
	local materialTypes = fillTypeMaterials[materialType]
	if g_showDevelopmentWarnings and materialTypes[materialIndex] ~= nil then
		local fillType = g_fillTypeManager:getFillTypeByIndex(fillTypeIndex)
		Logging.devWarning("Material type '%s' already exists for fillType '%s'. It will be overwritten!", tostring(materialType), tostring(fillType.name))
	end
	materialTypes[materialIndex] = materialId
end
function MaterialManager:getMaterial(fillType, materialTypeName, materialIndex)
	return self:getMaterialFromTarget(self.materials, fillType, materialTypeName, materialIndex)
end
function MaterialManager:getParticleMaterial(fillType, materialTypeName, materialIndex)
	return self:getMaterialFromTarget(self.particleMaterials, fillType, materialTypeName, materialIndex)
end
function MaterialManager:getMaterialFromTarget(target, fillType, materialTypeName, materialIndex)
	if fillType == nil or materialTypeName == nil or materialIndex == nil then
		return nil
	end
	local materialType = self:getMaterialTypeByName(materialTypeName)
	if materialType == nil then
		return nil
	end
	local fillTypeMaterials = target[fillType]
	if fillTypeMaterials == nil then
		return nil
	end
	local materials = fillTypeMaterials[materialType]
	if materials == nil then
		return nil
	else
		return materials[materialIndex]
	end
end
function MaterialManager:addModMaterialHolder(filename)
	self.modMaterialHoldersToLoad[filename] = filename
end
function MaterialManager:loadModMaterialHolders()
	for filename, _ in pairs(self.modMaterialHoldersToLoad) do
		g_i3DManager:loadI3DFileAsync(filename, true, true, MaterialManager.materialHolderLoaded, self, nil)
	end
end
function MaterialManager:materialHolderLoaded(i3dNode, failedReason, args)
	if i3dNode ~= 0 then
		for i = getNumOfChildren(i3dNode) - 1, 0, -1 do
			local child = getChildAt(i3dNode, i)
			unlink(child)
			table.insert(self.loadedMaterialHolderNodes, child)
		end
		delete(i3dNode)
	end
end
function MaterialManager:getFontMaterial(materialName, customEnvironment)
	if customEnvironment ~= nil and customEnvironment ~= "" then
		local customMaterialName = customEnvironment .. "." .. materialName
		if self.fontMaterialsByName[customMaterialName] ~= nil then
			return self.fontMaterialsByName[customMaterialName]
		end
	end
	return self.fontMaterialsByName[materialName]
end
function MaterialManager:loadFontMaterialsXML(xmlFilename, customEnvironment, baseDirectory)
	self.xmlFile = XMLFile.load("TempFonts", xmlFilename, MaterialManager.fontMaterialXMLSchema)
	if self.xmlFile ~= nil then
		self.xmlFile.references = 0
		self.xmlFile:iterate("fonts.font", function(index, key)
			self.xmlFile.references = self.xmlFile.references + 1
			local fontMaterial = FontMaterial.new()
			fontMaterial:loadFromXML(self.xmlFile, key, customEnvironment, baseDirectory, function(success)
				if self.xmlFile ~= nil then
					self.xmlFile.references = self.xmlFile.references - 1
					if self.xmlFile.references == 0 then
						self.xmlFile:delete()
						self.xmlFile = nil
						if self.finishedLoadingCallback ~= nil then
							self.finishedLoadingCallback(self.callbackTarget)
							self.finishedLoadingCallback = nil
							self.callbackTarget = nil
						end
					end
				end
				if success then
					table.insert(self.fontMaterials, fontMaterial)
					self.fontMaterialsByName[fontMaterial.name] = fontMaterial
				end
			end)
		end)
	end
	if self.xmlFile == nil or self.xmlFile.references == 0 then
		if self.xmlFile ~= nil then
			self.xmlFile:delete()
			self.xmlFile = nil
		end
		if self.finishedLoadingCallback ~= nil then
			self.finishedLoadingCallback(self.callbackTarget)
			self.finishedLoadingCallback = nil
			self.callbackTarget = nil
		end
	end
end
function MaterialManager:consoleCommandDebug()
	if MaterialManager.debugRootNode == nil then
		MaterialManager.debugRootNode = createTransformGroup("MaterialManager_DebugRootNode")
		link(getRootNode(), MaterialManager.debugRootNode)
		local x, y, z = g_localPlayer:getPosition()
		local dirX, dirZ = g_localPlayer:getCurrentFacingDirection()
		x = x + dirX * 10
		z = z + dirZ * 10
		local ry = MathUtil.getYRotationFromDirection(dirX, dirZ)
		setWorldTranslation(MaterialManager.debugRootNode, x, y + 2, z)
		setWorldRotation(MaterialManager.debugRootNode, 0, ry, 0)
		local i3dNode = loadI3DFile("data/effects/debug/effectDebugMesh.i3d", false, false, false)
		MaterialManager.debugMesh = getChildAt(i3dNode, 0)
		unlink(MaterialManager.debugMesh)
		delete(i3dNode)
	else
		for i = 1, getNumOfChildren(MaterialManager.debugRootNode) do
			local child = getChildAt(MaterialManager.debugRootNode, 0)
			delete(child)
		end
	end
	local index = 0
	for _, fillTypeDesc in pairs(g_fillTypeManager.fillTypes) do
		fillTypeDesc:reloadData()
		local textureArrayIndex = g_fillTypeManager:getTextureArrayIndexByFillTypeIndex(fillTypeDesc.index)
		if textureArrayIndex == nil then
			continue
		end
		local mesh = clone(MaterialManager.debugMesh, false, false, false)
		link(MaterialManager.debugRootNode, mesh)
		setTranslation(mesh, index * 3, 0, 0)
		local effectMaterial = g_materialManager:getBaseMaterialByName("belt")
		if effectMaterial ~= nil then
			setMaterial(mesh, effectMaterial, 0)
			local shaderFilename = getMaterialCustomShaderFilename(effectMaterial)
			local defaultUseTextureArrays = false
			if shaderFilename ~= nil then
				defaultUseTextureArrays = shaderFilename:contains("grainUnloadingSmokeShader") or shaderFilename:contains("grainUnloadingBeltShader") or shaderFilename:contains("grainUnloadingShader") or shaderFilename:contains("levelerShader")
			end
			if defaultUseTextureArrays then
				if shaderFilename ~= nil then
					if shaderFilename:find("grainUnloadingSmokeShader") ~= nil then
						g_fillTypeManager:assignFillTypeTextureArraysFromTerrain(mesh, g_terrainNode, true, false, false)
					else
						g_fillTypeManager:assignFillTypeTextureArraysFromTerrain(mesh, g_terrainNode, true, true, true)
					end
				end
				setShaderParameter(mesh, "fillTypeId", textureArrayIndex - 1, 0, 0, 0, false)
				setShaderParameter(mesh, "alphaClipScale", fillTypeDesc:getBeltEffectAlphaClipScale(), nil, nil, nil, false)
			end
		end
		local wx, wy, wz = getWorldTranslation(mesh)
		local rx, ry, rz = localRotationToWorld(mesh, 0, 3.141592653589793, 0)
		g_debugManager:addElement(DebugText3D.new():createWithWorldPos(wx, wy + 0.25, wz, rx, ry, rz, fillTypeDesc.name, 0.15), nil, nil, math.huge)
		index = index + 1
	end
end
g_materialManager = MaterialManager.new()
addConsoleCommand("gsMaterialManagerDebug", "Debug particle effect", "consoleCommandDebug", g_materialManager)
