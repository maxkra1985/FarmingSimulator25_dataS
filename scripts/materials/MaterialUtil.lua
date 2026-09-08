MaterialUtil = {}

-- Local values: materialNameStr
function MaterialUtil.onCreateBaseMaterial(_, id)
	local v2_ = getUserAttribute(id, "materialName")
	if v2_ == nil then
		Logging.i3dWarning(id, "Missing \'materialName\' user attribute for MaterialUtil.onCreateBaseMaterial")
	else
		g_materialManager:addBaseMaterial(v2_, getMaterial(id, 0))
	end
end

-- Local values: fillTypeStr, fillTypeIndex, materialTypeName, materialType, matIdStr, materialIndex
function MaterialUtil.validateMaterialAttributes(node, sourceFuncName)
	local v5_ = getUserAttribute(node, "fillType")
	if v5_ == nil then
		Logging.i3dWarning(node, "Missing \'fillType\' user attribute for %q", sourceFuncName)
		return false
	end
	local v6_ = g_fillTypeManager:getFillTypeIndexByName(v5_)
	if v6_ == nil then
		Logging.i3dWarning(node, "Unknown fillType %q in user attribute \'fillType\' for %q", v5_, sourceFuncName)
		return false
	end
	local v7_ = getUserAttribute(node, "materialType")
	if v7_ == nil then
		Logging.i3dWarning(node, "Missing \'materialType\' user attribute for %q", sourceFuncName)
		return false
	end
	local v8_ = g_materialManager:getMaterialTypeByName(v7_)
	if v8_ == nil then
		Logging.i3dWarning(node, "Unknown materialType %q for %q", v7_, sourceFuncName)
		return false
	end
	local v9_ = Utils.getNoNil(getUserAttribute(node, "materialIndex"), 1)
	local v10_ = tonumber(v9_)
	if v10_ ~= nil then
		return true, v6_, v8_, v10_
	end
	Logging.i3dWarning(node, "Invalid materialIndex %q for %q", v9_, sourceFuncName)
	return false
end

-- Local values: isValid, fillTypeIndex, materialType, materialIndex
function MaterialUtil.onCreateMaterial(_, id)
	local v12_, v13_, v14_, v15_ = MaterialUtil.validateMaterialAttributes(id, "MaterialUtil.onCreateMaterial")
	if v12_ then
		g_materialManager:addMaterial(v13_, v14_, v15_, getMaterial(id, 0))
	end
end

-- Local values: isValid, fillTypeIndex, materialType, materialIndex
function MaterialUtil.onCreateParticleMaterial(_, id)
	local v17_, v18_, v19_, v20_ = MaterialUtil.validateMaterialAttributes(id, "MaterialUtil.onCreateParticleMaterial")
	if v17_ then
		g_materialManager:addParticleMaterial(v18_, v19_, v20_, getMaterial(id, 0))
	end
end

-- Local values: particleTypeName, particleType, defaultEmittingState, worldSpace, forceFullLifespan, particleSystem
function MaterialUtil.onCreateParticleSystem(_, id)
	local v22_ = getUserAttribute(id, "particleType")
	if v22_ == nil then
		Logging.i3dWarning(id, "Missing \'particleType\' user attribute for MaterialUtil.onCreateParticleSystem")
		return
	else
		local v23_ = g_particleSystemManager:getParticleSystemTypeByName(v22_)
		if v23_ == nil then
			Logging.i3dWarning(id, "Unknown particleType \'%s\' given in \'particleType\' user attribute for MaterialUtil.onCreateParticleSystem", v22_)
			print(string.format("Available types: %s", table.concat(g_particleSystemManager.particleTypes, " ")))
		else
			local v24_ = Utils.getNoNil(getUserAttribute(id, "defaultEmittingState"), false)
			local v25_ = Utils.getNoNil(getUserAttribute(id, "worldSpace"), true)
			local v26_ = Utils.getNoNil(getUserAttribute(id, "forceFullLifespan"), false)
			local v27_ = {}
			ParticleUtil.loadParticleSystemFromNode(id, v27_, v24_, v25_, v26_)
			g_particleSystemManager:addParticleSystem(v23_, v27_)
		end
	end
end

-- Local values: numMaterials, i, numChildren, i, child, materialId
function MaterialUtil.getMaterialBySlotName(node, materialName)
	if getHasClassId(node, ClassIds.SHAPE) then
		for v30_ = 1, getNumOfMaterials(node) do
			if getMaterialSlotName(node, v30_ - 1) == materialName then
				return getMaterial(node, v30_ - 1)
			end
		end
	end
	for v31_ = 1, getNumOfChildren(node) do
		local v32_ = getChildAt(node, v31_ - 1)
		local v33_ = MaterialUtil.getMaterialBySlotName(v32_, materialName)
		if v33_ ~= nil then
			return v33_
		end
	end
	return nil
end

-- Local values: numMaterials, i, nodeMaterial, numChildren, i
function MaterialUtil.replaceMaterialRec(node, oldMaterial, newMaterial)
	if getHasClassId(node, ClassIds.SHAPE) then
		for v37_ = 1, getNumOfMaterials(node) do
			if getMaterial(node, v37_ - 1) == oldMaterial then
				setMaterial(node, newMaterial, v37_ - 1)
			end
		end
	end
	local v38_ = getNumOfChildren(node)
	if v38_ > 0 then
		for v39_ = 0, v38_ - 1 do
			MaterialUtil.replaceMaterialRec(getChildAt(node, v39_), oldMaterial, newMaterial)
		end
	end
end
