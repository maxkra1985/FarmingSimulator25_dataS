-- Local values: MaterialManager_mt
MaterialManager = {}
MaterialManager.fontMaterialXMLSchema = nil
MaterialManager.DEFAULT_FONT_MATERIAL_XML = "data/shared/alphabet/fonts.xml"
MaterialManager.FONT_CHARACTER_TYPE = {}
MaterialManager.FONT_CHARACTER_TYPE.NUMERICAL = 0
MaterialManager.FONT_CHARACTER_TYPE.ALPHABETICAL = 1
MaterialManager.FONT_CHARACTER_TYPE.SPECIAL = 2
MaterialType = nil
local MaterialManager_mt = Class(MaterialManager, AbstractManager)

-- Upvalues: MaterialManager_mt
-- Local values: self
function MaterialManager.new(customMt)
	-- upvalues: (copy) MaterialManager_mt
	local v3_ = AbstractManager.new(customMt or MaterialManager_mt)
	MaterialManager.fontMaterialXMLSchema = XMLSchema.new("fontMaterials")
	FontMaterial.registerXMLPaths(MaterialManager.fontMaterialXMLSchema)
	return v3_
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

-- Local values: _, node, _, font
function MaterialManager:unloadMapData()
	for _, v9_ in ipairs(self.loadedMaterialHolderNodes) do
		delete(v9_)
	end
	if self.xmlFile ~= nil then
		self.xmlFile:delete()
		self.xmlFile = nil
	end
	for _, v10_ in ipairs(self.fontMaterials) do
		delete(v10_.materialNode)
		if v10_.materialNodeNoNormal ~= nil then
			delete(v10_.materialNodeNoNormal)
		end
		if v10_.characterShape ~= nil then
			delete(v10_.characterShape)
		end
		if v10_.sharedLoadRequestId ~= nil then
			g_i3DManager:releaseSharedI3DFile(v10_.sharedLoadRequestId)
		end
	end
	MaterialManager:superClass().unloadMapData(self)
end

function MaterialManager:addMaterialType(name)
	if not ClassUtil.getIsValidIndexName(name) then
		printWarning("Warning: \'" .. tostring(name) .. "\' is not a valid name for a materialType. Ignoring it!")
		return nil
	end
	local v13_ = string.upper(name)
	if self.nameToIndex[v13_] == nil then
		local v14_ = self.materialTypes
		table.insert(v14_, v13_)
		self.nameToIndex[v13_] = #self.materialTypes
	end
	return nil
end

function MaterialManager:getMaterialTypeByName(name)
	if name ~= nil then
		local v17_ = string.upper(name)
		if self.nameToIndex[v17_] ~= nil then
			return v17_
		end
	end
	return nil
end

function MaterialManager:addBaseMaterial(materialName, materialId)
	self.baseMaterialsByName[string.upper(materialName)] = materialId
	local v21_ = self.baseMaterials
	table.insert(v21_, materialId)
end

function MaterialManager:getBaseMaterialByName(materialName)
	if materialName == nil then
		return nil
	else
		return self.baseMaterialsByName[string.upper(materialName)]
	end
end

function MaterialManager:addMaterial(fillTypeIndex, materialType, materialIndex, materialId)
	self:addMaterialToTarget(self.materials, fillTypeIndex, materialType, materialIndex, materialId)
end

function MaterialManager:addParticleMaterial(fillTypeIndex, materialType, materialIndex, materialId)
	self:addMaterialToTarget(self.particleMaterials, fillTypeIndex, materialType, materialIndex, materialId)
end

-- Local values: fillTypeMaterials, materialTypes, fillType
function MaterialManager:addMaterialToTarget(target, fillTypeIndex, materialType, materialIndex, materialId)
	if fillTypeIndex ~= nil and (materialType ~= nil and (materialIndex ~= nil and materialId ~= nil)) then
		if target[fillTypeIndex] == nil then
			target[fillTypeIndex] = {}
		end
		local v39_ = target[fillTypeIndex]
		if v39_[materialType] == nil then
			v39_[materialType] = {}
		end
		local v40_ = v39_[materialType]
		if g_showDevelopmentWarnings and v40_[materialIndex] ~= nil then
			local v41_ = g_fillTypeManager:getFillTypeByIndex(fillTypeIndex)
			local v42_ = Logging.devWarning
			local v43_ = tostring(materialType)
			local v44_ = v41_.name
			v42_("Material type \'%s\' already exists for fillType \'%s\'. It will be overwritten!", v43_, (tostring(v44_)))
		end
		v40_[materialIndex] = materialId
	end
end

function MaterialManager:getMaterial(fillType, materialTypeName, materialIndex)
	return self:getMaterialFromTarget(self.materials, fillType, materialTypeName, materialIndex)
end

function MaterialManager:getParticleMaterial(fillType, materialTypeName, materialIndex)
	return self:getMaterialFromTarget(self.particleMaterials, fillType, materialTypeName, materialIndex)
end

-- Local values: materialType, fillTypeMaterials, materials
function MaterialManager:getMaterialFromTarget(target, fillType, materialTypeName, materialIndex)
	if fillType == nil or (materialTypeName == nil or materialIndex == nil) then
		return nil
	else
		local v58_ = self:getMaterialTypeByName(materialTypeName)
		if v58_ == nil then
			return nil
		else
			local v59_ = target[fillType]
			if v59_ == nil then
				return nil
			else
				local v60_ = v59_[v58_]
				if v60_ == nil then
					return nil
				else
					return v60_[materialIndex]
				end
			end
		end
	end
end

function MaterialManager:addModMaterialHolder(filename)
	self.modMaterialHoldersToLoad[filename] = filename
end

-- Local values: filename, _
function MaterialManager:loadModMaterialHolders()
	for v64_, _ in pairs(self.modMaterialHoldersToLoad) do
		g_i3DManager:loadI3DFileAsync(v64_, true, true, MaterialManager.materialHolderLoaded, self, nil)
	end
end

-- Local values: i, child
function MaterialManager:materialHolderLoaded(i3dNode, failedReason, args)
	if i3dNode ~= 0 then
		for v67_ = getNumOfChildren(i3dNode) - 1, 0, -1 do
			local v68_ = getChildAt(i3dNode, v67_)
			unlink(v68_)
			local v69_ = self.loadedMaterialHolderNodes
			table.insert(v69_, v68_)
		end
		delete(i3dNode)
	end
end

-- Local values: customMaterialName
function MaterialManager:getFontMaterial(materialName, customEnvironment)
	if customEnvironment ~= nil and customEnvironment ~= "" then
		local v73_ = customEnvironment .. "." .. materialName
		if self.fontMaterialsByName[v73_] ~= nil then
			return self.fontMaterialsByName[v73_]
		end
	end
	return self.fontMaterialsByName[materialName]
end

function MaterialManager:loadFontMaterialsXML(xmlFilename, customEnvironment, baseDirectory)
	self.xmlFile = XMLFile.load("TempFonts", xmlFilename, MaterialManager.fontMaterialXMLSchema)
	if self.xmlFile ~= nil then
		self.xmlFile.references = 0
		self.xmlFile:iterate("fonts.font", function(_, p78_)
			-- upvalues: (copy) self, (copy) customEnvironment, (copy) baseDirectory
			self.xmlFile.references = self.xmlFile.references + 1
			local v_u_79_ = FontMaterial.new()
			v_u_79_:loadFromXML(self.xmlFile, p78_, customEnvironment, baseDirectory, function(p80_)
				-- upvalues: (ref) self, (copy) v_u_79_
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
				if p80_ then
					local v81_ = self.fontMaterials
					local v82_ = v_u_79_
					table.insert(v81_, v82_)
					self.fontMaterialsByName[v_u_79_.name] = v_u_79_
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

-- Local values: x, y, z, dirX, dirZ, ry, i3dNode, i, child, index, _, fillTypeDesc, textureArrayIndex, mesh, effectMaterial, shaderFilename, defaultUseTextureArrays, wx, wy, wz, rx, ry, rz
function MaterialManager:consoleCommandDebug()
	if MaterialManager.debugRootNode == nil then
		MaterialManager.debugRootNode = createTransformGroup("MaterialManager_DebugRootNode")
		link(getRootNode(), MaterialManager.debugRootNode)
		local v83_, v84_, v85_ = g_localPlayer:getPosition()
		local v86_, v87_ = g_localPlayer:getCurrentFacingDirection()
		local v88_ = v83_ + v86_ * 10
		local v89_ = v85_ + v87_ * 10
		local v90_ = MathUtil.getYRotationFromDirection(v86_, v87_)
		setWorldTranslation(MaterialManager.debugRootNode, v88_, v84_ + 2, v89_)
		setWorldRotation(MaterialManager.debugRootNode, 0, v90_, 0)
		local v91_ = loadI3DFile("data/effects/debug/effectDebugMesh.i3d", false, false, false)
		MaterialManager.debugMesh = getChildAt(v91_, 0)
		unlink(MaterialManager.debugMesh)
		delete(v91_)
	else
		for _ = 1, getNumOfChildren(MaterialManager.debugRootNode) do
			local v92_ = getChildAt(MaterialManager.debugRootNode, 0)
			delete(v92_)
		end
	end
	local v93_ = 0
	for _, v94_ in pairs(g_fillTypeManager.fillTypes) do
		v94_:reloadData()
		local v95_ = g_fillTypeManager:getTextureArrayIndexByFillTypeIndex(v94_.index)
		if v95_ ~= nil then
			local v96_ = clone(MaterialManager.debugMesh, false, false, false)
			link(MaterialManager.debugRootNode, v96_)
			setTranslation(v96_, v93_ * 3, 0, 0)
			local v97_ = g_materialManager:getBaseMaterialByName("belt")
			if v97_ ~= nil then
				setMaterial(v96_, v97_, 0)
				local v98_ = getMaterialCustomShaderFilename(v97_)
				local v99_
				if v98_ == nil then
					v99_ = false
				else
					v99_ = v98_:contains("grainUnloadingSmokeShader") or v98_:contains("grainUnloadingBeltShader") or (v98_:contains("grainUnloadingShader") or v98_:contains("levelerShader"))
				end
				if v99_ then
					if v98_ == nil or v98_:find("grainUnloadingSmokeShader") == nil then
						g_fillTypeManager:assignFillTypeTextureArraysFromTerrain(v96_, g_terrainNode, true, true, true)
					else
						g_fillTypeManager:assignFillTypeTextureArraysFromTerrain(v96_, g_terrainNode, true, false, false)
					end
					setShaderParameter(v96_, "fillTypeId", v95_ - 1, 0, 0, 0, false)
					setShaderParameter(v96_, "alphaClipScale", v94_:getBeltEffectAlphaClipScale(), nil, nil, nil, false)
				end
			end
			local v100_, v101_, v102_ = getWorldTranslation(v96_)
			local v103_, v104_, v105_ = localRotationToWorld(v96_, 0, 3.141592653589793, 0)
			g_debugManager:addElement(DebugText3D.new():createWithWorldPos(v100_, v101_ + 0.25, v102_, v103_, v104_, v105_, v94_.name, 0.15), nil, nil, math.huge)
			v93_ = v93_ + 1
		end
	end
end
g_materialManager = MaterialManager.new()
addConsoleCommand("gsMaterialManagerDebug", "Debug particle effect", "consoleCommandDebug", g_materialManager)
