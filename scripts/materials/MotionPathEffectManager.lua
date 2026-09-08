-- Local values: MotionPathEffectManager_mt
MotionPathEffectManager = {}
MotionPathEffectManager.MOTION_PATH_SHADER_PARAMS = {
	"scrollPos",
	"fadeProgress",
	"visibilityCut",
	"density",
	"verticalOffset",
	"subUVspeed",
	"subUVelements",
	"sizeScale"
}
local MotionPathEffectManager_mt = Class(MotionPathEffectManager, AbstractManager)
g_xmlManager:addInitSchemaFunction(function()
	MotionPathEffectManager.createMotionPathEffectXMLSchema()
end)

-- Upvalues: MotionPathEffectManager_mt
-- Local values: self
function MotionPathEffectManager.new(customMt)
	-- upvalues: (copy) MotionPathEffectManager_mt
	return AbstractManager.new(customMt or MotionPathEffectManager_mt)
end

function MotionPathEffectManager:initDataStructures()
	self.xmlFiles = {}
	self.sharedLoadRequestIds = {}
	self.effectsByType = {}
	self.effects = {}
	self.modMotionPathEffectsToLoad = {}
end

-- Local values: customEnvironment, _, externalXMLFilename
function MotionPathEffectManager:loadMapData(xmlFile, missionInfo, baseDirectory)
	MotionPathEffectManager:superClass().loadMapData(self, xmlFile, missionInfo, baseDirectory)
	self.baseDirectory = baseDirectory
	local v8_, _ = Utils.getModNameAndBaseDirectory(baseDirectory)
	self:loadMotionPathEffects(xmlFile, "map.motionPathEffects.motionPathEffect", baseDirectory, v8_)
	local v9_ = getXMLString(xmlFile, "map.motionPathEffects#filename")
	if v9_ ~= nil then
		local v10_ = Utils.getFilename(v9_, baseDirectory)
		if v10_ ~= nil then
			self:loadMotionPathEffectsFromExternalFile(v10_, baseDirectory, v8_)
		end
	end
	return true
end

-- Local values: _, modMotionPathEffect
function MotionPathEffectManager:loadQueuedModMotionPathEffects()
	if self.modMotionPathEffectsToLoad ~= nil then
		for _, v12_ in ipairs(self.modMotionPathEffectsToLoad) do
			self:loadMotionPathEffectsFromExternalFile(v12_.filename, v12_.baseDirectory, v12_.customEnvironment)
		end
		self.modMotionPathEffectsToLoad = nil
	end
end

function MotionPathEffectManager:loadModMotionPathEffects(filename, baseDirectory, customEnvironment)
	if self.modMotionPathEffectsToLoad == nil then
		self:loadMotionPathEffectsFromExternalFile(filename, baseDirectory, customEnvironment)
	else
		local v17_ = self.modMotionPathEffectsToLoad
		table.insert(v17_, {
			["filename"] = filename,
			["baseDirectory"] = baseDirectory,
			["customEnvironment"] = customEnvironment
		})
	end
end

-- Local values: externalXMLFile
function MotionPathEffectManager:loadMotionPathEffectsFromExternalFile(filename, baseDirectory, customEnvironment)
	local v22_ = XMLFile.load("motionPathXML", filename)
	if v22_ ~= nil then
		self:loadMotionPathEffects(v22_.handle, "motionPathEffects.motionPathEffect", baseDirectory, customEnvironment)
		v22_:delete()
	end
end

-- Local values: i, motionPathEffectKey, filename
function MotionPathEffectManager:loadMotionPathEffects(xmlFileHandle, key, baseDirectory, customEnvironment)
	local v28_ = 0
	while true do
		local v29_ = string.format("%s(%d)", key, v28_)
		if not hasXMLProperty(xmlFileHandle, v29_) then
			break
		end
		local v30_ = getXMLString(xmlFileHandle, v29_ .. "#filename")
		if v30_ ~= nil then
			if string.contains(v30_, ".i3d") then
				Logging.xmlError(xmlFileHandle, "Motion path effect filename \'%s\' is not allowed in \'%s\'. Please use a motion path effect xml file.", v30_, v29_)
				return
			end
			self:loadMotionPathEffectsXML(v30_, baseDirectory, customEnvironment)
		end
		v28_ = v28_ + 1
	end
end

-- Local values: xmlFilename, xmlFile, i, motionPathEffectKey, motionPathEffect, effectClassName, effectClass, effectTypes, _, effectType, arguments, sharedLoadRequestId
function MotionPathEffectManager:loadMotionPathEffectsXML(filename, baseDirectory, customEnvironment)
	local v35_ = Utils.getFilename(filename, baseDirectory)
	local v36_ = XMLFile.load("mapMotionPathEffects", v35_, MotionPathEffectManager.xmlSchema)
	if v36_ ~= nil then
		self.xmlFiles[v36_] = true
		v36_.xmlReferences = 0
		local v37_ = 0
		while true do
			local v38_ = string.format("motionPathEffects.motionPathEffect(%d)", v37_)
			if not v36_:hasProperty(v38_) then
				break
			end
			local v39_ = {}
			local v40_ = v36_:getValue(v38_ .. "#effectClass", "MotionPathEffect")
			if v40_ ~= nil then
				local v41_ = g_effectManager:getEffectClass(v40_)
				if v41_ == nil then
					if customEnvironment ~= nil and customEnvironment ~= "" then
						v41_ = g_effectManager:getEffectClass(customEnvironment .. "." .. v40_)
					end
					if v41_ == nil then
						v41_ = ClassUtil.getClassObject(v40_)
					end
				end
				if v41_ == nil then
					Logging.xmlError(v36_, "Unknown motion path effect class \'%s\' in \'%s\'", v40_, v38_)
				else
					v41_.loadEffectDefinitionFromXML(v39_, v36_, v38_ .. ".typeDefinition")
					v39_.effectClass = v41_
					v39_.effectClassName = v40_
					v39_.effectTypes = {}
					v39_.effectTypeStr = v36_:getValue(v38_ .. "#effectType", "DEFAULT")
					local v42_ = v39_.effectTypeStr:split(" ")
					for _, v43_ in ipairs(v42_) do
						local v44_ = v39_.effectTypes
						local v45_ = string.upper
						table.insert(v44_, v45_(v43_))
					end
					v39_.filename = v36_:getValue(v38_ .. "#filename")
					if v39_.filename == nil then
						Logging.xmlError(v36_, "Missing filename for motion path effect \'%s\'", v38_)
					else
						v36_.xmlReferences = v36_.xmlReferences + 1
						v39_.filename = Utils.getFilename(v39_.filename, baseDirectory)
						local v46_ = g_i3DManager:loadSharedI3DFileAsync(v39_.filename, false, false, self.motionPathEffectI3DFileLoaded, self, {
							["motionPathEffect"] = v39_,
							["xmlFile"] = v36_,
							["motionPathEffectKey"] = v38_,
							["baseDirectory"] = baseDirectory
						})
						local v47_ = self.sharedLoadRequestIds
						table.insert(v47_, v46_)
					end
				end
			end
			v37_ = v37_ + 1
		end
		if v36_.xmlReferences == 0 then
			self.xmlFiles[v36_] = nil
			v36_:delete()
		end
	end
end

-- Local values: motionPathEffect, xmlFile, motionPathEffectKey, baseDirectory, loadedMeshes, j, j, i, effectType
function MotionPathEffectManager:motionPathEffectI3DFileLoaded(i3dNode, failedReason, args)
	local v_u_51_ = args.motionPathEffect
	local v_u_52_ = args.xmlFile
	local v53_ = args.motionPathEffectKey
	local v_u_54_ = args.baseDirectory
	if i3dNode ~= nil and i3dNode ~= 0 then
		local v_u_55_ = {}
		v_u_51_.effectMeshes = {}
		v_u_52_:iterate(v53_ .. ".effectMeshes.effectMesh", function(_, p56_)
			-- upvalues: (copy) v_u_52_, (copy) i3dNode, (copy) v_u_55_, (copy) v_u_51_, (copy) self
			local v57_ = v_u_52_:getValue(p56_ .. "#node", nil, i3dNode)
			if v57_ == nil or v_u_55_[v57_] ~= nil then
				if v57_ == nil then
					Logging.xmlError(v_u_52_, "Failed to load effect mesh node from xml (%s)", p56_)
				else
					Logging.xmlError(v_u_52_, "Failed to load effect mesh node from xml. Node already used. (%s)", p56_)
				end
			else
				local v58_ = {
					["node"] = v57_,
					["rowLength"] = v_u_52_:getValue(p56_ .. "#rowLength", 30),
					["numRows"] = v_u_52_:getValue(p56_ .. "#numRows", 12),
					["skipPositions"] = v_u_52_:getValue(p56_ .. "#skipPositions", 0),
					["numVariations"] = v_u_52_:getValue(p56_ .. "#numVariations", 1)
				}
				if v58_.numVariations > 1 then
					v58_.usedVariations = {}
					for v59_ = 1, v58_.numVariations do
						v58_.usedVariations[v59_] = false
					end
				end
				v58_.parent = v_u_51_
				self:loadCustomShaderSettingsFromXML(v58_, v_u_52_, p56_)
				v_u_51_.effectClass.loadEffectMeshFromXML(v58_, v_u_52_, p56_)
				v58_.growthStates = v_u_51_.growthStates
				local v60_ = v_u_51_.effectMeshes
				table.insert(v60_, v58_)
				v_u_55_[v57_] = true
				return
			end
		end)
		v_u_51_.effectMaterials = {}
		v_u_52_:iterate(v53_ .. ".effectMaterials.effectMaterial", function(_, p61_)
			-- upvalues: (copy) v_u_52_, (copy) i3dNode, (copy) v_u_51_, (copy) v_u_54_, (copy) self
			local v62_ = v_u_52_:getValue(p61_ .. "#node", nil, i3dNode)
			if v62_ == nil then
				Logging.xmlError(v_u_52_, "Failed to load effect material from xml (%s)", p61_)
			else
				local v_u_63_ = {
					["node"] = v62_,
					["materialId"] = getMaterial(v62_, 0),
					["parent"] = v_u_51_,
					["lod"] = {}
				}
				v_u_52_:iterate(p61_ .. ".lod", function(_, p64_)
					-- upvalues: (ref) v_u_52_, (ref) i3dNode, (copy) v_u_63_
					local v65_ = v_u_52_:getValue(p64_ .. "#node", nil, i3dNode)
					if v65_ ~= nil then
						local v66_ = v_u_63_.lod
						local v67_ = getMaterial
						table.insert(v66_, v67_(v65_, 0))
					end
				end)
				v_u_63_.customDiffuse = v_u_52_:getValue(p61_ .. ".textures#diffuse")
				if v_u_63_.customDiffuse ~= nil then
					v_u_63_.customDiffuse = Utils.getFilename(v_u_63_.customDiffuse, v_u_54_)
					v_u_63_.materialId = setMaterialDiffuseMapFromFile(v_u_63_.materialId, v_u_63_.customDiffuse, true, true, false)
				end
				v_u_63_.customNormal = v_u_52_:getValue(p61_ .. ".textures#normal")
				if v_u_63_.customNormal ~= nil then
					v_u_63_.customNormal = Utils.getFilename(v_u_63_.customNormal, v_u_54_)
					v_u_63_.materialId = setMaterialNormalMapFromFile(v_u_63_.materialId, v_u_63_.customDiffuse, true, false, false)
				end
				v_u_63_.customSpecular = v_u_52_:getValue(p61_ .. ".textures#specular")
				if v_u_63_.customSpecular ~= nil then
					v_u_63_.customSpecular = Utils.getFilename(v_u_63_.customSpecular, v_u_54_)
					v_u_63_.materialId = setMaterialGlossMapFromFile(v_u_63_.materialId, v_u_63_.customSpecular, true, true, false)
				end
				setMaterial(v62_, v_u_63_.materialId, 0)
				self:loadCustomShaderSettingsFromXML(v_u_63_, v_u_52_, p61_)
				v_u_51_.effectClass.loadEffectMaterialFromXML(v_u_63_, v_u_52_, p61_)
				local v68_ = v_u_51_.effectMaterials
				table.insert(v68_, v_u_63_)
			end
		end)
		self:loadCustomShaderSettingsFromXML(v_u_51_, v_u_52_, v53_ .. ".customShaderDefaults", v_u_54_)
		for v69_ = 1, #v_u_51_.effectMeshes do
			unlink(v_u_51_.effectMeshes[v69_].node)
		end
		for v70_ = 1, #v_u_51_.effectMaterials do
			unlink(v_u_51_.effectMaterials[v70_].node)
		end
		for v71_ = 1, #v_u_51_.effectTypes do
			local v72_ = v_u_51_.effectTypes[v71_]
			if self.effectsByType[v72_] == nil then
				self.effectsByType[v72_] = {}
			end
			local v73_ = self.effectsByType[v72_]
			table.insert(v73_, v_u_51_)
		end
		local v74_ = self.effects
		table.insert(v74_, v_u_51_)
		delete(i3dNode)
	end
	v_u_52_.xmlReferences = v_u_52_.xmlReferences - 1
	if v_u_52_.xmlReferences == 0 then
		self.xmlFiles[v_u_52_] = nil
		v_u_52_:delete()
	end
end

function MotionPathEffectManager:loadCustomShaderSettingsFromXML(target, xmlFile, key, baseDirectory)
	target.customShaderVariation = xmlFile:getValue(key .. ".customShaderVariation#name")
	target.customShaderMaps = {}
	xmlFile:iterate(key .. ".customShaderMap", function(_, p79_)
		-- upvalues: (copy) xmlFile, (copy) baseDirectory, (copy) target
		local v80_ = {
			["name"] = xmlFile:getValue(p79_ .. "#name"),
			["filename"] = xmlFile:getValue(p79_ .. "#filename")
		}
		v80_.filename = Utils.getFilename(v80_.filename, baseDirectory)
		if v80_.name == nil or v80_.filename == nil then
			Logging.xmlError(xmlFile, "Failed to load custom shader map from \'%s\'", p79_)
		else
			v80_.texture = createMaterialTextureFromFile(v80_.filename, true, false)
			if v80_.texture ~= nil then
				local v81_ = target.customShaderMaps
				table.insert(v81_, v80_)
				return
			end
		end
	end)
	target.customShaderParameters = {}
	xmlFile:iterate(key .. ".customShaderParameter", function(_, p82_)
		-- upvalues: (copy) xmlFile, (copy) target
		local v83_ = {
			["name"] = xmlFile:getValue(p82_ .. "#name"),
			["value"] = xmlFile:getValue(p82_ .. "#value", "0 0 0 0", true)
		}
		if v83_.name == nil or v83_.value == nil then
			Logging.xmlError(xmlFile, "Failed to load custom shader parameter from \'%s\'", p82_)
		else
			local v84_ = target.customShaderParameters
			table.insert(v84_, v83_)
		end
	end)
end

-- Local values: i, effect, j, effectMesh, j, material, i, sharedLoadRequestId, xmlFile, _
function MotionPathEffectManager:unloadMapData()
	for v86_ = 1, #self.effects do
		local v87_ = self.effects[v86_]
		self:deleteCustomShaderMaps(v87_)
		for v88_ = 1, #v87_.effectMeshes do
			local v89_ = v87_.effectMeshes[v88_]
			if v89_.node ~= nil and entityExists(v89_.node) then
				delete(v89_.node)
				v89_.node = nil
			end
			self:deleteCustomShaderMaps(v89_)
		end
		for v90_ = 1, #v87_.effectMaterials do
			local v91_ = v87_.effectMaterials[v90_]
			if v91_.node ~= nil and entityExists(v91_.node) then
				delete(v91_.node)
				v91_.node = nil
			end
			self:deleteCustomShaderMaps(v91_)
		end
	end
	for v92_ = 1, #self.sharedLoadRequestIds do
		local v93_ = self.sharedLoadRequestIds[v92_]
		g_i3DManager:releaseSharedI3DFile(v93_)
	end
	for v94_, _ in pairs(self.xmlFiles) do
		self.xmlFiles[v94_] = nil
		v94_:delete()
	end
	MotionPathEffectManager:superClass().unloadMapData(self)
end

-- Local values: _, customMap
function MotionPathEffectManager:deleteCustomShaderMaps(entity)
	for _, v96_ in ipairs(entity.customShaderMaps) do
		if v96_.texture ~= nil and entityExists(v96_.texture) then
			delete(v96_.texture)
			v96_.texture = nil
		end
	end
end

-- Local values: i, effect, i, effect
function MotionPathEffectManager:getSharedMotionPathEffect(motionPathEffectObject)
	for v99_ = 1, #self.effects do
		local v100_ = self.effects[v99_]
		if motionPathEffectObject:getIsSharedEffectMatching(v100_, false) then
			return v100_
		end
	end
	for v101_ = 1, #self.effects do
		local v102_ = self.effects[v101_]
		if motionPathEffectObject:getIsSharedEffectMatching(v102_, true) then
			return v102_
		end
	end
	return nil
end

-- Local values: j, effectMesh, j, effectMesh
function MotionPathEffectManager:getMotionPathEffectMesh(sharedEffect, motionPathEffectObject)
	for v105_ = 1, #sharedEffect.effectMeshes do
		local v106_ = sharedEffect.effectMeshes[v105_]
		if motionPathEffectObject:getIsEffectMeshMatching(v106_, false) then
			return v106_
		end
	end
	for v107_ = 1, #sharedEffect.effectMeshes do
		local v108_ = sharedEffect.effectMeshes[v107_]
		if motionPathEffectObject:getIsEffectMeshMatching(v108_, true) then
			return v108_
		end
	end
	return nil
end

-- Local values: i, effectMaterial, i, effectMaterial
function MotionPathEffectManager:getMotionPathEffectMaterial(sharedEffect, motionPathEffectObject)
	for v111_ = 1, #sharedEffect.effectMaterials do
		local v112_ = sharedEffect.effectMaterials[v111_]
		if motionPathEffectObject:getIsEffectMaterialMatching(v112_, false) then
			return v112_
		end
	end
	for v113_ = 1, #sharedEffect.effectMaterials do
		local v114_ = sharedEffect.effectMaterials[v113_]
		if motionPathEffectObject:getIsEffectMaterialMatching(v114_, true) then
			return v114_
		end
	end
	return nil
end

-- Local values: _, clonedNode, speedScale
function MotionPathEffectManager:applyEffectConfiguration(sharedEffect, effectMesh, effectMaterial, clonedNodes, textureEntityId, overwrittenSpeedScale)
	if sharedEffect == nil or clonedNodes == nil then
		return overwrittenSpeedScale or 1
	end
	for _, v122_ in ipairs(clonedNodes) do
		self:applyShaderSettingsParameters(v122_, sharedEffect)
		if effectMesh ~= nil then
			self:applyShaderSettingsParameters(v122_, effectMesh)
		end
		if effectMaterial ~= nil then
			self:applyShaderSettingsParameters(v122_, effectMaterial)
		end
		self:setEffectCustomMap(v122_, "shapeArray", textureEntityId)
		self:setEffectCustomMap(v122_, "animationArray", textureEntityId)
	end
	local v123_ = sharedEffect.speedScale or 0.5
	local v124_ = effectMesh.speedScale or v123_
	if effectMaterial ~= nil then
		v124_ = effectMaterial.speedScale or v124_
	end
	return overwrittenSpeedScale or v124_
end

-- Local values: i, customShaderMap, i, customShaderParameter
function MotionPathEffectManager:applyShaderSettingsParameters(node, target)
	for v128_ = 1, #target.customShaderMaps do
		local v129_ = target.customShaderMaps[v128_]
		self:setEffectCustomMap(node, v129_.name, v129_.texture)
	end
	if target.customShaderVariation ~= nil then
		self:setEffectCustomShaderVariation(node, target.customShaderVariation)
	end
	for v130_ = 1, #target.customShaderParameters do
		local v131_ = target.customShaderParameters[v130_]
		setShaderParameterRecursive(node, v131_.name, v131_.value[1], v131_.value[2], v131_.value[3], v131_.value[4], false)
	end
end
MotionPathEffectManager.setEffectShaderParameter = setShaderParameterRecursive

-- Local values: numChildren, i, child
function MotionPathEffectManager:getEffectShaderParameter(node, name)
	if getHasClassId(node, ClassIds.SHAPE) then
		return getShaderParameter(node, name)
	end
	for v134_ = 1, getNumOfChildren(node) do
		local v135_ = getChildAt(node, v134_ - 1)
		if getHasClassId(v135_, ClassIds.SHAPE) then
			return getShaderParameter(v135_, name)
		end
	end
	return 0, 0, 0, 0
end

-- Local values: material, newMaterial, numChildren, i, child, material, newMaterial
function MotionPathEffectManager:setEffectCustomShaderVariation(node, variation)
	if getHasClassId(node, ClassIds.SHAPE) then
		local v138_ = getMaterial(node, 0)
		local v139_ = setMaterialCustomShaderVariation(v138_, variation, false)
		if v139_ ~= v138_ then
			setMaterial(node, v139_, 0)
		end
	end
	local v140_ = getNumOfChildren(node)
	if v140_ > 0 then
		for v141_ = 1, v140_ do
			local v142_ = getChildAt(node, v141_ - 1)
			if getHasClassId(v142_, ClassIds.SHAPE) then
				local v143_ = getMaterial(v142_, 0)
				local v144_ = setMaterialCustomShaderVariation(v143_, variation, false)
				if v144_ ~= v143_ then
					setMaterial(v142_, v144_, 0)
				end
			end
		end
	end
end

-- Local values: material, newMaterial
function MotionPathEffectManager:setEffectCustomMapOnNode(node, name, textureEntityId)
	local v148_ = getMaterial(node, 0)
	if textureEntityId ~= nil then
		local v149_ = setMaterialCustomMap(v148_, name, textureEntityId, false)
		if v149_ ~= v148_ then
			setMaterial(node, v149_, 0)
		end
	end
end

-- Local values: numChildren, i, child
function MotionPathEffectManager:setEffectCustomMap(node, name, textureEntityId)
	if getHasClassId(node, ClassIds.SHAPE) then
		self:setEffectCustomMapOnNode(node, name, textureEntityId)
	end
	local v154_ = getNumOfChildren(node)
	if v154_ > 0 then
		for v155_ = 1, v154_ do
			local v156_ = getChildAt(node, v155_ - 1)
			if getHasClassId(v156_, ClassIds.SHAPE) then
				self:setEffectCustomMapOnNode(v156_, name, textureEntityId)
			end
		end
	end
end

-- Local values: numChildren, i, child, materialId
function MotionPathEffectManager:setEffectMaterial(node, material)
	if getHasClassId(node, ClassIds.SHAPE) then
		setMaterial(node, material.materialId, 0)
	end
	local v159_ = getNumOfChildren(node)
	if v159_ > 0 then
		for v160_ = 1, v159_ do
			local v161_ = getChildAt(node, v160_ - 1)
			if getHasClassId(v161_, ClassIds.SHAPE) then
				local v162_ = material.materialId
				if v160_ > 1 and material.lod[v160_] ~= nil then
					v162_ = material.lod[v160_]
				end
				setMaterial(v161_, v162_, 0)
			end
		end
	end
end
function MotionPathEffectManager.createMotionPathEffectXMLSchema()
	if MotionPathEffectManager.xmlSchema == nil then
		local v163_ = XMLSchema.new("mapMotionPathEffects")
		v163_:register(XMLValueType.STRING, "motionPathEffects.motionPathEffect(?)#effectClass", "Effect class name")
		v163_:register(XMLValueType.STRING, "motionPathEffects.motionPathEffect(?)#effectType", "Effect type name (can be multiple)")
		v163_:register(XMLValueType.STRING, "motionPathEffects.motionPathEffect(?)#filename", "Path to effects i3d file")
		v163_:register(XMLValueType.NODE_INDEX, "motionPathEffects.motionPathEffect(?).effectGeneration#rootNode", "(Only for automatic mesh generation) Mesh root node in maya file which has sub shapes")
		v163_:register(XMLValueType.VECTOR_ROT, "motionPathEffects.motionPathEffect(?).effectGeneration#minRot", "(Only for automatic mesh generation) Min. random rotation")
		v163_:register(XMLValueType.VECTOR_ROT, "motionPathEffects.motionPathEffect(?).effectGeneration#maxRot", "(Only for automatic mesh generation) Max. random rotation")
		v163_:register(XMLValueType.VECTOR_SCALE, "motionPathEffects.motionPathEffect(?).effectGeneration#minScale", "(Only for automatic mesh generation) Min. random scale")
		v163_:register(XMLValueType.VECTOR_SCALE, "motionPathEffects.motionPathEffect(?).effectGeneration#maxScale", "(Only for automatic mesh generation) Max. random scale")
		v163_:register(XMLValueType.STRING, "motionPathEffects.motionPathEffect(?).effectGeneration#useFoliage", "(Only for automatic mesh generation) Name of foliage")
		v163_:register(XMLValueType.INT, "motionPathEffects.motionPathEffect(?).effectGeneration#useFoliageStage", "(Only for automatic mesh generation) Foliage growth state")
		v163_:register(XMLValueType.INT, "motionPathEffects.motionPathEffect(?).effectGeneration#useFoliageLOD", "(Only for automatic mesh generation) LOD to use")
		MotionPathEffect.registerEffectDefinitionXMLPaths(v163_, "motionPathEffects.motionPathEffect(?).typeDefinition")
		TypedMotionPathEffect.registerEffectDefinitionXMLPaths(v163_, "motionPathEffects.motionPathEffect(?).typeDefinition")
		CutterMotionPathEffect.registerEffectDefinitionXMLPaths(v163_, "motionPathEffects.motionPathEffect(?).typeDefinition")
		CultivatorMotionPathEffect.registerEffectDefinitionXMLPaths(v163_, "motionPathEffects.motionPathEffect(?).typeDefinition")
		PlowMotionPathEffect.registerEffectDefinitionXMLPaths(v163_, "motionPathEffects.motionPathEffect(?).typeDefinition")
		WindrowerMotionPathEffect.registerEffectDefinitionXMLPaths(v163_, "motionPathEffects.motionPathEffect(?).typeDefinition")
		v163_:register(XMLValueType.NODE_INDEX, "motionPathEffects.motionPathEffect(?).effectMeshes.effectMesh(?)#node", "Index path in effect i3d")
		v163_:register(XMLValueType.NODE_INDEX, "motionPathEffects.motionPathEffect(?).effectMeshes.effectMesh(?)#sourceNode", "(Only for automatic mesh generation) Index path to source object in maya file")
		v163_:register(XMLValueType.INT, "motionPathEffects.motionPathEffect(?).effectMeshes.effectMesh(?)#rowLength", "Number of meshes on X axis (on effect texture)", 30)
		v163_:register(XMLValueType.INT, "motionPathEffects.motionPathEffect(?).effectMeshes.effectMesh(?)#numRows", "Number of meshes on Y axis (on effect texture)", 12)
		v163_:register(XMLValueType.INT, "motionPathEffects.motionPathEffect(?).effectMeshes.effectMesh(?)#skipPositions", "Number of skipped meshes on X axis", 0)
		v163_:register(XMLValueType.INT, "motionPathEffects.motionPathEffect(?).effectMeshes.effectMesh(?)#numVariations", "Number of sub random variations", 1)
		v163_:register(XMLValueType.VECTOR_SCALE, "motionPathEffects.motionPathEffect(?).effectMeshes.effectMesh(?)#boundingBox", "(Only for automatic mesh generation) Size of bounding box")
		v163_:register(XMLValueType.VECTOR_TRANS, "motionPathEffects.motionPathEffect(?).effectMeshes.effectMesh(?)#boundingBoxCenter", "(Only for automatic mesh generation) Center of bounding box")
		v163_:register(XMLValueType.NODE_INDEX, "motionPathEffects.motionPathEffect(?).effectMeshes.effectMesh(?).lod(?)#sourceNode", "(Only for automatic mesh generation) Custom node for LOD")
		v163_:register(XMLValueType.FLOAT, "motionPathEffects.motionPathEffect(?).effectMeshes.effectMesh(?).lod(?)#distance", "(Only for automatic mesh generation) Distance of LOD")
		v163_:register(XMLValueType.INT, "motionPathEffects.motionPathEffect(?).effectMeshes.effectMesh(?).lod(?)#skipPositions", "(Only for automatic mesh generation) Custom skip positions")
		MotionPathEffectManager.registerCustomShaderSettingXMLPaths(v163_, "motionPathEffects.motionPathEffect(?).effectMeshes.effectMesh(?)")
		MotionPathEffect.registerEffectMeshXMLPaths(v163_, "motionPathEffects.motionPathEffect(?).effectMeshes.effectMesh(?)")
		TypedMotionPathEffect.registerEffectMeshXMLPaths(v163_, "motionPathEffects.motionPathEffect(?).effectMeshes.effectMesh(?)")
		CutterMotionPathEffect.registerEffectMeshXMLPaths(v163_, "motionPathEffects.motionPathEffect(?).effectMeshes.effectMesh(?)")
		CultivatorMotionPathEffect.registerEffectMeshXMLPaths(v163_, "motionPathEffects.motionPathEffect(?).effectMeshes.effectMesh(?)")
		PlowMotionPathEffect.registerEffectMeshXMLPaths(v163_, "motionPathEffects.motionPathEffect(?).effectMeshes.effectMesh(?)")
		WindrowerMotionPathEffect.registerEffectMeshXMLPaths(v163_, "motionPathEffects.motionPathEffect(?).effectMeshes.effectMesh(?)")
		v163_:register(XMLValueType.NODE_INDEX, "motionPathEffects.motionPathEffect(?).effectMaterials#rootNode", "(Only for automatic mesh generation) Node which will be copied over the effect i3d file (position index in i3d is then \'0|1\')")
		v163_:register(XMLValueType.NODE_INDEX, "motionPathEffects.motionPathEffect(?).effectMaterials.effectMaterial(?)#node", "Material node")
		v163_:register(XMLValueType.NODE_INDEX, "motionPathEffects.motionPathEffect(?).effectMaterials.effectMaterial(?).lod(?)#node", "LOD node")
		v163_:register(XMLValueType.STRING, "motionPathEffects.motionPathEffect(?).effectMaterials.effectMaterial(?).textures#diffuse", "Path to custom diffuse map to apply")
		v163_:register(XMLValueType.STRING, "motionPathEffects.motionPathEffect(?).effectMaterials.effectMaterial(?).textures#normal", "Path to custom normal map to apply")
		v163_:register(XMLValueType.STRING, "motionPathEffects.motionPathEffect(?).effectMaterials.effectMaterial(?).textures#specular", "Path to custom specular map to apply")
		MotionPathEffectManager.registerCustomShaderSettingXMLPaths(v163_, "motionPathEffects.motionPathEffect(?).effectMaterials.effectMaterial(?)")
		MotionPathEffect.registerEffectMaterialXMLPaths(v163_, "motionPathEffects.motionPathEffect(?).effectMaterials.effectMaterial(?)")
		TypedMotionPathEffect.registerEffectMaterialXMLPaths(v163_, "motionPathEffects.motionPathEffect(?).effectMaterials.effectMaterial(?)")
		CutterMotionPathEffect.registerEffectMaterialXMLPaths(v163_, "motionPathEffects.motionPathEffect(?).effectMaterials.effectMaterial(?)")
		CultivatorMotionPathEffect.registerEffectMaterialXMLPaths(v163_, "motionPathEffects.motionPathEffect(?).effectMaterials.effectMaterial(?)")
		PlowMotionPathEffect.registerEffectMaterialXMLPaths(v163_, "motionPathEffects.motionPathEffect(?).effectMaterials.effectMaterial(?)")
		WindrowerMotionPathEffect.registerEffectMaterialXMLPaths(v163_, "motionPathEffects.motionPathEffect(?).effectMaterials.effectMaterial(?)")
		MotionPathEffectManager.registerCustomShaderSettingXMLPaths(v163_, "motionPathEffects.motionPathEffect(?).customShaderDefaults")
		MotionPathEffectManager.xmlSchema = v163_
	end
end

function MotionPathEffectManager.registerCustomShaderSettingXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. ".customShaderVariation#name", "Shader variation to apply")
	schema:register(XMLValueType.STRING, basePath .. ".customShaderParameter(?)#name", "Name of shader parameter")
	schema:register(XMLValueType.VECTOR_4, basePath .. ".customShaderParameter(?)#value", "Value of shader parameter")
	schema:register(XMLValueType.STRING, basePath .. ".customShaderMap(?)#name", "Name of custom shader map")
	schema:register(XMLValueType.STRING, basePath .. ".customShaderMap(?)#filename", "Path to texture file")
end

function MotionPathEffectManager.registerMotionPathXMLFiles(schema, basePath)
	schema:register(XMLValueType.FILENAME, basePath .. ".motionPathEffects.motionPathEffect(?)#filename", "motion path effect xml config filename")
end
g_motionPathEffectManager = MotionPathEffectManager.new()
