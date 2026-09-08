I3DUtil = {}

function I3DUtil.checkChildIndex(node, index)
	if getNumOfChildren(node) > index then
		return true
	end
	local v3_ = Logging.error
	local v4_ = tostring(index)
	local v5_ = I3DUtil.getNodePath(node)
	local v6_ = getNumOfChildren
	v3_("Failed to find child %d from node %q, only %s children given", v4_, v5_, (tostring(v6_(node))))
	printCallstack()
	return false
end

-- Local values: mapping, curPos, rootNode, iStart, iEnd, componentIndex, curCompIndex, retVal, indexNumber, indexNumber
function I3DUtil.indexToObject(components, index, mappings, realNumComponents)
	if index == nil or components == nil then
		return nil
	end
	local v11_
	if mappings == nil then
		v11_ = index
	else
		v11_ = mappings[index]
		if v11_ == nil then
			v11_ = index
		elseif type(v11_) == "table" then
			return v11_.nodeId, v11_.rootNode
		end
	end
	local v12_, v13_ = string.find(v11_, ">", 1, true)
	local v14_ = v12_ == nil and 1 or v13_ + 1
	local v15_
	if type(components) == "table" then
		local v16_
		if v12_ == nil then
			v16_ = 1
		else
			local v17_ = v12_ - 1
			local v18_ = string.sub(v11_, 1, v17_)
			local v19_ = tonumber(v18_)
			if v19_ == nil then
				Logging.error("Invalid index format: %s", v11_)
			end
			v16_ = v19_ + 1
		end
		if components[v16_] == nil then
			if (realNumComponents or #components) < v16_ then
				Logging.error("Invalid compound index: %s", v11_)
			end
			return nil
		end
		v15_ = components[v16_].node
	else
		v15_ = components
	end
	if v12_ ~= nil and v13_ == string.len(v11_) then
		return v15_, v15_
	end
	if type(components) ~= "table" and v12_ ~= nil then
		Logging.error("Invalid usage of \'>\'! Works with vehicle & placeable components table only. Please replace \'>\' with \'|\' in the xml config. Referenced node: \'%s\'", v11_)
		printCallstack()
		return nil
	end
	local v20_, v21_ = string.find(v11_, "|", v14_, true)
	local v22_ = v15_
	while v20_ ~= nil do
		local v23_ = v20_ - 1
		local v24_ = string.sub(v11_, v14_, v23_)
		local v25_ = tonumber(v24_)
		if v25_ == nil or not I3DUtil.checkChildIndex(v15_, v25_) then
			Logging.error("Index not found: %s", v11_)
			return nil
		end
		v15_ = getChildAt(v15_, v25_)
		v14_ = v21_ + 1
		v20_, v21_ = string.find(v11_, "|", v14_, true)
	end
	local v26_ = string.sub(v11_, v14_)
	local v27_ = tonumber(v26_)
	if v27_ ~= nil and I3DUtil.checkChildIndex(v15_, v27_) then
		return getChildAt(v15_, v27_), v22_
	end
	Logging.error("Index not found: %s", v11_)
	return nil
end

-- Local values: i, elem, curNumber
function I3DUtil.setNumberShaderByValue(numbers, value, precision, showZero)
	if numbers ~= nil then
		local v32_ = value * 10 ^ precision
		local v33_ = math.floor(v32_)
		for v34_ = 0, getNumOfChildren(numbers) - 1 do
			local v35_ = getChildAt(numbers, v34_)
			if v33_ > 0 then
				local v36_ = v33_ / 10
				local v37_ = v33_ - math.floor(v36_) * 10
				v33_ = (v33_ - v37_) / 10
				setShaderParameter(v35_, "number", v37_, 0, 0, 0, false)
			elseif showZero and v34_ <= precision then
				setShaderParameter(v35_, "number", 0, 0, 0, 0, false)
			else
				setShaderParameter(v35_, "number", -1, 0, 0, 0, false)
			end
		end
	end
end

function I3DUtil.wakeUpObject(node)
	addImpulse(node, 0, 0.001, 0, 0, 0, 0, true)
end

-- Local values: parent
function I3DUtil.setWorldDirection(node, dirX, dirY, dirZ, upX, upY, upZ, limitedAxis, minRot, maxRot)
	local v49_ = getParent(node)
	if dirX == dirX and (dirY == dirY and dirZ == dirZ) then
		if v49_ ~= 0 then
			dirX, dirY, dirZ = worldDirectionToLocal(v49_, dirX, dirY, dirZ)
			upX, upY, upZ = worldDirectionToLocal(v49_, upX, upY, upZ)
		end
		if limitedAxis ~= nil then
			if limitedAxis == 1 then
				dirX = 0
				if minRot ~= nil then
					dirZ, dirY = MathUtil.getRotationLimitedVector2(dirZ, dirY, minRot, maxRot)
				end
			elseif limitedAxis == 2 then
				dirY = 0
				if minRot ~= nil then
					dirZ, dirX = MathUtil.getRotationLimitedVector2(dirZ, dirX, minRot, maxRot)
				end
			else
				dirZ = 0
				if minRot ~= nil then
					dirX, dirY = MathUtil.getRotationLimitedVector2(dirX, dirY, minRot, maxRot)
				end
			end
		end
		if dirX * dirX + dirY * dirY + dirZ * dirZ > 0.0001 then
			setDirection(node, dirX, dirY, dirZ, upX, upY, upZ)
		end
	else
		Logging.error("Failed to set world direction: Object \'%s\' dir %.2f %.2f %.2f up %.2f %.2f %.2f", getName(node), dirX, dirY, dirZ, upX, upY, upZ)
	end
end

function I3DUtil.setDirection(node, dirX, dirY, dirZ, upX, upY, upZ)
	if MathUtil.vector3LengthSq(dirX, dirY, dirZ) > 0.0001 then
		setDirection(node, dirX, dirY, dirZ, upX, upY, upZ)
	end
end

-- Local values: numChildren, i
function I3DUtil.setShaderParameterRec(node, shaderParam, x, y, z, w)
	if getHasClassId(node, ClassIds.SHAPE) and getHasShaderParameter(node, shaderParam) then
		setShaderParameter(node, shaderParam, x, y, z, w, false)
	end
	for v63_ = 0, getNumOfChildren(node) - 1 do
		I3DUtil.setShaderParameterRec(getChildAt(node, v63_), shaderParam, x, y, z, w)
	end
end

-- Local values: i, numChildren, i
function I3DUtil.setMaterialSlotShaderParameterRec(node, materialSlotName, shaderParam, x, y, z, w)
	if getHasClassId(node, ClassIds.SHAPE) and getHasShaderParameter(node, shaderParam) then
		for v71_ = 1, getNumOfMaterials(node) do
			if getMaterialSlotName(node, v71_ - 1) == materialSlotName then
				setShaderParameter(node, shaderParam, x, y, z, w, false, v71_ - 1)
			end
		end
	end
	for v72_ = 1, getNumOfChildren(node) do
		I3DUtil.setMaterialSlotShaderParameterRec(getChildAt(node, v72_ - 1), materialSlotName, shaderParam, x, y, z, w)
	end
end

function I3DUtil.setShaderParameter(node, shaderParameter, x, y, z, w, shared)
	if getHasClassId(node, ClassIds.SHAPE) then
		setShaderParameter(node, shaderParameter, x, y, z, w, shared, -1)
	end
end

-- Local values: hideByIndexMaxIndex, offset, numChildren, i
function I3DUtil.setHideByIndexRec(node, fillLevelPercentage)
	if getHasClassId(node, ClassIds.SHAPE) and getHasShaderParameter(node, "hideByIndex") then
		local v82_ = getUserAttribute(node, "hideByIndexMaxIndex")
		if v82_ == nil then
			Logging.warning("Try to set hideByIndex on node \'%s\', but \'hideByIndexMaxIndex\' user attribute is missing!", getName(node))
			printCallstack()
		else
			local v83_ = getUserAttribute(node, "hideByIndexOffset") or 0
			setShaderParameter(node, "hideByIndex", (1 - fillLevelPercentage) * v82_ - v83_, 0, 0, 0, false)
		end
	end
	for v84_ = 0, getNumOfChildren(node) - 1 do
		I3DUtil.setHideByIndexRec(getChildAt(node, v84_), fillLevelPercentage)
	end
end

-- Local values: numChildren, i
function I3DUtil.setShapeBonesRec(node, skeleton, oldSkeleton, keepBindPoses)
	if getHasClassId(node, ClassIds.SHAPE) then
		setShapeBones(node, skeleton, oldSkeleton, keepBindPoses)
	end
	local v89_ = getNumOfChildren(node)
	if v89_ > 0 then
		for v90_ = 0, v89_ - 1 do
			I3DUtil.setShapeBonesRec(getChildAt(node, v90_), skeleton, oldSkeleton, keepBindPoses)
		end
	end
end

-- Local values: numChildren, i
function I3DUtil.setShapeCastShadowmapRec(node, castShadowmap)
	if getHasClassId(node, ClassIds.SHAPE) then
		setShapeCastShadowmap(node, castShadowmap)
	end
	local v93_ = getNumOfChildren(node)
	if v93_ > 0 then
		for v94_ = 0, v93_ - 1 do
			I3DUtil.setShapeCastShadowmapRec(getChildAt(node, v94_), castShadowmap)
		end
	end
end

-- Local values: numChildren, i
function I3DUtil.getHasShaderParameterRec(node, shaderParam)
	if getHasClassId(node, ClassIds.SHAPE) and getHasShaderParameter(node, shaderParam) then
		return true
	end
	local v97_ = getNumOfChildren(node)
	if v97_ > 0 then
		for v98_ = 0, v97_ - 1 do
			if I3DUtil.getHasShaderParameterRec(getChildAt(node, v98_), shaderParam) then
				return true
			end
		end
	end
	return false
end

-- Local values: numChildren, i, x, y, z, w
function I3DUtil.getShaderParameterRec(node, shaderParam)
	if getHasClassId(node, ClassIds.SHAPE) and getHasShaderParameter(node, shaderParam) then
		return getShaderParameter(node, shaderParam)
	end
	local v101_ = getNumOfChildren(node)
	if v101_ > 0 then
		for v102_ = 0, v101_ - 1 do
			local v103_, v104_, v105_, v106_ = I3DUtil.getShaderParameterRec(getChildAt(node, v102_), shaderParam)
			if v103_ ~= nil then
				return v103_, v104_, v105_, v106_
			end
		end
	end
	return nil, nil, nil, nil
end

-- Local values: numChildren, i
function I3DUtil.getNodesByShaderParam(node, shaderParam, nodes, asList)
	local v111_ = nodes == nil and {} or nodes
	if getHasClassId(node, ClassIds.SHAPE) and getHasShaderParameter(node, shaderParam) then
		if asList == nil or not asList then
			v111_[node] = node
		else
			table.insert(v111_, node)
		end
	end
	local v112_ = getNumOfChildren(node)
	if v112_ > 0 then
		for v113_ = 0, v112_ - 1 do
			I3DUtil.getNodesByShaderParam(getChildAt(node, v113_), shaderParam, v111_, asList)
		end
	end
	return v111_
end

-- Local values: _, shaderParam, numChildren, i
function I3DUtil.getNodesByShaderParameters(node, shaderParameters, nodes, asList)
	local v118_ = nodes == nil and {} or nodes
	if getHasClassId(node, ClassIds.SHAPE) then
		for _, v119_ in ipairs(shaderParameters) do
			if getHasShaderParameter(node, v119_) then
				if asList == nil or not asList then
					v118_[node] = node
				else
					table.insert(v118_, node)
				end
				break
			end
		end
	end
	local v120_ = getNumOfChildren(node)
	if v120_ > 0 then
		for v121_ = 0, v120_ - 1 do
			I3DUtil.getNodesByShaderParameters(getChildAt(node, v121_), shaderParameters, v118_, asList)
		end
	end
	return v118_
end

-- Local values: i, child
function I3DUtil.printChildren(node, indentation, depth)
	local v125_ = indentation or "    "
	local v126_ = depth or 0
	for v127_ = 0, getNumOfChildren(node) - 1 do
		local v128_ = getChildAt(node, v127_)
		log(string.rep(v125_, v126_), v128_, getName(v128_))
		I3DUtil.printChildren(v128_, v125_, v126_ + 1)
	end
end

-- Local values: i, child
function I3DUtil.hasNamedChildren(node, name)
	for v131_ = 0, getNumOfChildren(node) - 1 do
		local v132_ = getChildAt(node, v131_)
		if getName(v132_) == name or I3DUtil.hasNamedChildren(v132_, name) then
			return true
		end
	end
	return false
end

-- Local values: i, child, foundChild
function I3DUtil.getChildByName(node, name)
	for v135_ = 0, getNumOfChildren(node) - 1 do
		local v136_ = getChildAt(node, v135_)
		if getName(v136_) == name then
			return v136_
		end
		local v137_ = I3DUtil.getChildByName(v136_, name)
		if v137_ ~= nil then
			return v137_
		end
	end
	return nil
end

-- Local values: iterateRecursivelyRec
function I3DUtil.iterateRecursively(node, func, includeStartNode)
	if includeStartNode and func(node, 0) == false then
		return false
	end
	local function v_u_146_(p141_, p142_, p143_)
		-- upvalues: (copy) v_u_146_
		for v144_ = 0, getNumOfChildren(p141_) - 1 do
			local v145_ = getChildAt(p141_, v144_)
			if p142_(v145_, p143_) == false then
				return false
			end
			if v_u_146_(v145_, p142_, p143_ + 1) == false then
				return false
			end
		end
		return true
	end
	return v_u_146_(node, func, 0)
end

-- Local values: currentIndex, numChildren, iterator
function I3DUtil.iteratorChildren(node)
	if node == nil or not entityExists(node) then
		return function() end
	elseif getHasClassId(node, ClassIds.TRANSFORM_GROUP) then
		local v_u_148_ = 0
		local v_u_149_ = getNumOfChildren(node)
		return function()
			-- upvalues: (ref) v_u_148_, (copy) v_u_149_, (copy) node
			if v_u_149_ <= v_u_148_ then
				return nil
			end
			v_u_148_ = v_u_148_ + 1
			return v_u_148_, getChildAt(node, v_u_148_ - 1)
		end
	else
		Logging.error("I3DUtil.iteratorChildren() called with non-transform entity %q (%d)", getName(node), node)
		printCallstack()
		return function() end
	end
end

-- Local values: currentIndex, iterator
function I3DUtil.iteratorChildrenReverse(node)
	if node == nil or not entityExists(node) then
		return function() end
	end
	if getHasClassId(node, ClassIds.TRANSFORM_GROUP) then
		local v_u_151_ = getNumOfChildren(node)
		return function()
			-- upvalues: (ref) v_u_151_, (copy) node
			if v_u_151_ <= 0 then
				return nil
			end
			v_u_151_ = v_u_151_ - 1
			return v_u_151_ + 1, getChildAt(node, v_u_151_)
		end
	end
	Logging.error("I3DUtil.iteratorChildren() called with non-transform entity %q (%d)", getName(node), node)
	printCallstack()
	return function() end
end

-- Local values: success, parent
function I3DUtil.traverseToRoot(node, callback, stopNode)
	if callback(node) then
		local v155_ = getParent(node)
		if v155_ ~= 0 then
			if stopNode ~= nil and v155_ == stopNode then
				return
			end
			I3DUtil.traverseToRoot(v155_, callback, stopNode)
		end
	end
end

-- Local values: i
function I3DUtil.iterateShaderParameterNodesRecursively(node, shaderParameter, func, funcTarget)
	if getHasClassId(node, ClassIds.SHAPE) and getHasShaderParameter(node, shaderParameter) then
		if funcTarget == nil then
			func(node)
		else
			func(funcTarget, node)
		end
	end
	for v160_ = 0, getNumOfChildren(node) - 1 do
		I3DUtil.iterateShaderParameterNodesRecursively(getChildAt(node, v160_), shaderParameter, func, funcTarget)
	end
end

-- Local values: _, shaderParameter, i
function I3DUtil.iterateShaderParametersNodesRecursively(node, shaderParameters, func, funcTarget)
	if getHasClassId(node, ClassIds.SHAPE) then
		for _, v165_ in ipairs(shaderParameters) do
			if getHasShaderParameter(node, v165_) then
				if funcTarget == nil then
					func(node)
				else
					func(funcTarget, node)
				end
				break
			end
		end
	end
	for v166_ = 0, getNumOfChildren(node) - 1 do
		I3DUtil.iterateShaderParametersNodesRecursively(getChildAt(node, v166_), shaderParameters, func, funcTarget)
	end
end

function I3DUtil.getIsLinkedToNode(parent, node)
	while node ~= 0 do
		if parent == node then
			return true
		end
		node = getParent(node)
	end
	return false
end

function I3DUtil.getIsSpline(node)
	local v170_ = node ~= 0 and getHasClassId(node, ClassIds.SHAPE)
	if v170_ then
		if getGeometry(node) == 0 then
			v170_ = false
		else
			v170_ = getHasClassId(getGeometry(node), ClassIds.SPLINE)
		end
	end
	return v170_
end

-- Local values: _, id
function I3DUtil.getIsTransformGroup(node)
	if node == nil or not entityExists(node) then
		return false
	end
	for _, v172_ in pairs(ClassIds) do
		if v172_ ~= ClassIds.TRANSFORM_GROUP and getHasClassId(node, v172_) then
			return false
		end
	end
	return true
end

function I3DUtil.getSupportsLOD(node)
	return getHasClassId(node, ClassIds.SHAPE) and not getIsNonRenderable(node) and not I3DUtil.getIsSpline(node) or (getHasClassId(node, ClassIds.LIGHT_SOURCE) or getHasClassId(node, ClassIds.AUDIO_SOURCE))
end

-- Local values: parent, isRef, filePath
function I3DUtil.getNodePath(node, stopAtNode, stopAtReference)
	local v177_ = getParent(node)
	if v177_ == 0 or node == stopAtNode then
		return getName(node)
	else
		local v178_, v179_ = getReferenceInfo(v177_)
		if v178_ then
			if stopAtReference then
				return "(Ref:" .. Utils.getFilenameFromPath(v179_) .. ")|" .. getName(node)
			else
				return I3DUtil.getNodePath(v177_, stopAtNode, stopAtReference) .. "(Ref:" .. v179_ .. ")|" .. getName(node)
			end
		else
			return I3DUtil.getNodePath(v177_, stopAtNode, stopAtReference) .. "|" .. getName(node)
		end
	end
end

-- Local values: parent, spacer, path
function I3DUtil.getNodePathIndices(node, stopAtNode, includeStopNode)
	local v183_ = getParent(node)
	if v183_ == 0 or (getChildIndex(v183_) == -1 or (node == stopAtNode or v183_ == stopAtNode and includeStopNode == false)) then
		return string.format("%d", getChildIndex(node))
	end
	local v184_ = getParent(v183_) == getRootNode() and ">" or "|"
	local v185_ = I3DUtil.getNodePathIndices(v183_, stopAtNode, includeStopNode)
	return string.format("%s%s%d", v185_, v184_, getChildIndex(node))
end

-- Local values: parent
function I3DUtil.getRelativeNodePathIndices(node, parentNode)
	local v188_ = getParent(node)
	if v188_ == 0 or v188_ == parentNode then
		return getChildIndex(node)
	else
		return I3DUtil.getRelativeNodePathIndices(v188_, parentNode) .. "|" .. getChildIndex(node)
	end
end

function I3DUtil.getNodeNameAndIndexPath(node)
	return string.format("%s (%s)", I3DUtil.getNodePath(node), I3DUtil.getNodePathIndices(node))
end
function I3DUtil.checkForChildCollisions(p190_, p191_, ...)
	local v192_ = getRigidBodyType(p190_)
	if v192_ == RigidBodyType.STATIC or (v192_ == RigidBodyType.DYNAMIC or getIsCompoundChild(p190_)) then
		p191_(p190_, ...)
	end
	for v193_ = 0, getNumOfChildren(p190_) - 1 do
		I3DUtil.checkForChildCollisions(getChildAt(p190_, v193_), p191_, ...)
	end
end

function I3DUtil.registerI3dMappingXMLPaths(schema, path)
	schema:register(XMLValueType.STRING, path .. ".i3dMappings.i3dMapping(?)#id", "Identifier to be used in xml")
	schema:register(XMLValueType.STRING, path .. ".i3dMappings.i3dMapping(?)#node", "Index path to node in i3d file")
end

function I3DUtil.loadI3DMapping(xmlFile, path, components, mappings, realNumComponents)
	local v_u_201_ = mappings or {}
	if xmlFile == nil then
		Logging.warning("Cannot load i3d mapping because xml file is missing")
		return v_u_201_
	else
		xmlFile:iterate((path or xmlFile:getRootName()) .. ".i3dMappings.i3dMapping", function(_, p202_)
			-- upvalues: (copy) xmlFile, (copy) components, (copy) realNumComponents, (ref) v_u_201_
			local v203_ = xmlFile:getString(p202_ .. "#id")
			local v204_ = xmlFile:getString(p202_ .. "#node")
			if v203_ ~= nil and v204_ ~= nil then
				local v205_, v206_ = I3DUtil.indexToObject(components, v204_, nil, realNumComponents)
				if v205_ ~= nil then
					v_u_201_[v203_] = {
						["nodeId"] = v205_,
						["rootNode"] = v206_
					}
					return
				end
				v_u_201_[v203_] = v204_
			end
		end)
		return v_u_201_
	end
end

-- Local values: numChildren, i
function I3DUtil.loadI3DComponents(rootNode, components)
	local v209_ = components or {}
	for v210_ = 0, getNumOfChildren(rootNode) - 1 do
		local v211_ = {
			["node"] = getChildAt(rootNode, v210_)
		}
		table.insert(v209_, v211_)
	end
	return v209_
end
