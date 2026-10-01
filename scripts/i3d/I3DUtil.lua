I3DUtil = {}
function I3DUtil.checkChildIndex(node, index)
	if getNumOfChildren(node) <= index then
		Logging.error("Failed to find child %d from node %q, only %s children given", tostring(index), I3DUtil.getNodePath(node), tostring(getNumOfChildren(node)))
		printCallstack()
		return false
	else
		return true
	end
end
function I3DUtil.indexToObject(components, index, mappings, realNumComponents)
	if index == nil or components == nil then
		return nil
	end
	if mappings ~= nil then
		local mapping = mappings[index]
		if mapping ~= nil then
			if type(mapping) == "table" then
				return mapping.nodeId, mapping.rootNode
			end
			index = mapping
		end
	end
	local curPos = 1
	local rootNode = nil
	local iStart, iEnd = string.find(index, ">", 1, true)
	if iStart ~= nil then
		curPos = iEnd + 1
	end
	if type(components) == "table" then
		local componentIndex = 1
		if iStart ~= nil then
			local curCompIndex = tonumber(string.sub(index, 1, iStart - 1))
			if curCompIndex == nil then
				Logging.error("Invalid index format: %s", index)
			end
			componentIndex = curCompIndex + 1
		end
		if components[componentIndex] == nil then
			if (realNumComponents or #components) < componentIndex then
				Logging.error("Invalid compound index: %s", index)
			end
			return nil
		end
		rootNode = components[componentIndex].node
	else
		rootNode = components
	end
	if iStart ~= nil and iEnd == string.len(index) then
		return rootNode, rootNode
	end
	if type(components) ~= "table" and iStart ~= nil then
		Logging.error("Invalid usage of '>'! Works with vehicle & placeable components table only. Please replace '>' with '|' in the xml config. Referenced node: '%s'", index)
		printCallstack()
		return nil
	end
	local retVal = rootNode
	iStart, iEnd = string.find(index, "|", curPos, true)
	while iStart ~= nil do
		local indexNumber = tonumber(string.sub(index, curPos, iStart - 1))
		if indexNumber == nil or not I3DUtil.checkChildIndex(retVal, indexNumber) then
			Logging.error("Index not found: %s", index)
			return nil
		end
		retVal = getChildAt(retVal, indexNumber)
		curPos = iEnd + 1
		iStart, iEnd = string.find(index, "|", curPos, true)
	end
	local indexNumber = tonumber(string.sub(index, curPos))
	if indexNumber == nil or not I3DUtil.checkChildIndex(retVal, indexNumber) then
		Logging.error("Index not found: %s", index)
		return nil
	end
	retVal = getChildAt(retVal, indexNumber)
	return retVal, rootNode
end
function I3DUtil.setNumberShaderByValue(numbers, value, precision, showZero)
	if numbers ~= nil then
		value = math.floor(value * 10 ^ precision)
		for i = 0, getNumOfChildren(numbers) - 1 do
			local elem = getChildAt(numbers, i)
			if 0 < value then
				local curNumber = value - math.floor(value / 10) * 10
				value = (value - curNumber) / 10
				setShaderParameter(elem, "number", curNumber, 0, 0, 0, false)
			elseif showZero then
				if i <= precision then
					setShaderParameter(elem, "number", 0, 0, 0, 0, false)
				else
					setShaderParameter(elem, "number", -1, 0, 0, 0, false)
				end
			end
		end
	end
end
function I3DUtil.wakeUpObject(node)
	addImpulse(node, 0, 0.001, 0, 0, 0, 0, true)
end
function I3DUtil.setWorldDirection(node, dirX, dirY, dirZ, upX, upY, upZ, limitedAxis, minRot, maxRot)
	local parent = getParent(node)
	if dirX ~= dirX or dirY ~= dirY or dirZ ~= dirZ then
		Logging.error("Failed to set world direction: Object '%s' dir %.2f %.2f %.2f up %.2f %.2f %.2f", getName(node), dirX, dirY, dirZ, upX, upY, upZ)
		return
	end
	if parent ~= 0 then
		dirX, dirY, dirZ = worldDirectionToLocal(parent, dirX, dirY, dirZ)
		upX, upY, upZ = worldDirectionToLocal(parent, upX, upY, upZ)
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
	if 0.0001 < dirX * dirX + dirY * dirY + dirZ * dirZ then
		setDirection(node, dirX, dirY, dirZ, upX, upY, upZ)
	end
end
function I3DUtil.setDirection(node, dirX, dirY, dirZ, upX, upY, upZ)
	if 0.0001 < MathUtil.vector3LengthSq(dirX, dirY, dirZ) then
		setDirection(node, dirX, dirY, dirZ, upX, upY, upZ)
	end
end
function I3DUtil.setShaderParameterRec(node, shaderParam, x, y, z, w)
	if getHasClassId(node, ClassIds.SHAPE) and getHasShaderParameter(node, shaderParam) then
		setShaderParameter(node, shaderParam, x, y, z, w, false)
	end
	local numChildren = getNumOfChildren(node)
	for i = 0, numChildren - 1 do
		I3DUtil.setShaderParameterRec(getChildAt(node, i), shaderParam, x, y, z, w)
	end
end
function I3DUtil.setMaterialSlotShaderParameterRec(node, materialSlotName, shaderParam, x, y, z, w)
	if getHasClassId(node, ClassIds.SHAPE) and getHasShaderParameter(node, shaderParam) then
		for i = 1, getNumOfMaterials(node) do
			if getMaterialSlotName(node, i - 1) == materialSlotName then
				setShaderParameter(node, shaderParam, x, y, z, w, false, i - 1)
			end
		end
	end
	local numChildren = getNumOfChildren(node)
	for i = 1, numChildren do
		I3DUtil.setMaterialSlotShaderParameterRec(getChildAt(node, i - 1), materialSlotName, shaderParam, x, y, z, w)
	end
end
function I3DUtil.setShaderParameter(node, shaderParameter, x, y, z, w, shared)
	if getHasClassId(node, ClassIds.SHAPE) then
		setShaderParameter(node, shaderParameter, x, y, z, w, shared, -1)
	end
end
function I3DUtil.setHideByIndexRec(node, fillLevelPercentage)
	if getHasClassId(node, ClassIds.SHAPE) and getHasShaderParameter(node, "hideByIndex") then
		local hideByIndexMaxIndex = getUserAttribute(node, "hideByIndexMaxIndex")
		if hideByIndexMaxIndex == nil then
			Logging.warning("Try to set hideByIndex on node '%s', but 'hideByIndexMaxIndex' user attribute is missing!", getName(node))
			printCallstack()
		else
			local offset = getUserAttribute(node, "hideByIndexOffset") or 0
			setShaderParameter(node, "hideByIndex", (1 - fillLevelPercentage) * hideByIndexMaxIndex - offset, 0, 0, 0, false)
		end
	end
	local numChildren = getNumOfChildren(node)
	for i = 0, numChildren - 1 do
		I3DUtil.setHideByIndexRec(getChildAt(node, i), fillLevelPercentage)
	end
end
function I3DUtil.setShapeBonesRec(node, skeleton, oldSkeleton, keepBindPoses)
	if getHasClassId(node, ClassIds.SHAPE) then
		setShapeBones(node, skeleton, oldSkeleton, keepBindPoses)
	end
	local numChildren = getNumOfChildren(node)
	if 0 < numChildren then
		for i = 0, numChildren - 1 do
			I3DUtil.setShapeBonesRec(getChildAt(node, i), skeleton, oldSkeleton, keepBindPoses)
		end
	end
end
function I3DUtil.setShapeCastShadowmapRec(node, castShadowmap)
	if getHasClassId(node, ClassIds.SHAPE) then
		setShapeCastShadowmap(node, castShadowmap)
	end
	local numChildren = getNumOfChildren(node)
	if 0 < numChildren then
		for i = 0, numChildren - 1 do
			I3DUtil.setShapeCastShadowmapRec(getChildAt(node, i), castShadowmap)
		end
	end
end
function I3DUtil.getHasShaderParameterRec(node, shaderParam)
	if getHasClassId(node, ClassIds.SHAPE) and getHasShaderParameter(node, shaderParam) then
		return true
	end
	local numChildren = getNumOfChildren(node)
	if 0 < numChildren then
		for i = 0, numChildren - 1 do
			if I3DUtil.getHasShaderParameterRec(getChildAt(node, i), shaderParam) then
				return true
			end
		end
	end
	return false
end
function I3DUtil.getShaderParameterRec(node, shaderParam)
	if getHasClassId(node, ClassIds.SHAPE) and getHasShaderParameter(node, shaderParam) then
		return getShaderParameter(node, shaderParam)
	end
	local numChildren = getNumOfChildren(node)
	if 0 < numChildren then
		for i = 0, numChildren - 1 do
			local x, y, z, w = I3DUtil.getShaderParameterRec(getChildAt(node, i), shaderParam)
			if x == nil then
				continue
			end
			return x, y, z, w
		end
	end
	return nil, nil, nil, nil
end
function I3DUtil.getNodesByShaderParam(node, shaderParam, nodes, asList)
	if nodes == nil then
		nodes = {}
	end
	if getHasClassId(node, ClassIds.SHAPE) and getHasShaderParameter(node, shaderParam) then
		if asList == nil or not asList then
			nodes[node] = node
		else
			table.insert(nodes, node)
		end
	end
	local numChildren = getNumOfChildren(node)
	if 0 < numChildren then
		for i = 0, numChildren - 1 do
			I3DUtil.getNodesByShaderParam(getChildAt(node, i), shaderParam, nodes, asList)
		end
	end
	return nodes
end
function I3DUtil.getNodesByShaderParameters(node, shaderParameters, nodes, asList)
	if nodes == nil then
		nodes = {}
	end
	if getHasClassId(node, ClassIds.SHAPE) then
		for _, shaderParam in ipairs(shaderParameters) do
			if getHasShaderParameter(node, shaderParam) then
				if asList == nil or not asList then
					nodes[node] = node
				else
					table.insert(nodes, node)
				end
				local numChildren = getNumOfChildren(node)
				if 0 < numChildren then
					for i = 0, numChildren - 1 do
						I3DUtil.getNodesByShaderParameters(getChildAt(node, i), shaderParameters, nodes, asList)
					end
				end
				return nodes
			end
		end
	end
end
function I3DUtil.printChildren(node, indentation, depth)
	indentation = indentation or "    "
	depth = depth or 0
	for i = 0, getNumOfChildren(node) - 1 do
		local child = getChildAt(node, i)
		log(string.rep(indentation, depth), child, getName(child))
		I3DUtil.printChildren(child, indentation, depth + 1)
	end
end
function I3DUtil.hasNamedChildren(node, name)
	for i = 0, getNumOfChildren(node) - 1 do
		local child = getChildAt(node, i)
		if getName(child) == name or I3DUtil.hasNamedChildren(child, name) then
			return true
		end
	end
	return false
end
function I3DUtil.getChildByName(node, name)
	for i = 0, getNumOfChildren(node) - 1 do
		local child = getChildAt(node, i)
		if getName(child) == name then
			return child
		end
		local foundChild = I3DUtil.getChildByName(child, name)
		if foundChild == nil then
			continue
		end
		return foundChild
	end
	return nil
end
function I3DUtil.iterateRecursively(node, func, includeStartNode)
	if includeStartNode and func(node, 0) == false then
		return false
	end
	local function iterateRecursivelyRec(node, func, depth)
		for i = 0, getNumOfChildren(node) - 1 do
			local child = getChildAt(node, i)
			if func(child, depth) == false then
				return false
			end
			if iterateRecursivelyRec(child, func, depth + 1) == false then
				return false
			end
		end
		return true
	end
	return iterateRecursivelyRec(node, func, 0)
end
function I3DUtil.iteratorChildren(node)
	if node == nil or not entityExists(node) then
		return function() end
	end
	if not getHasClassId(node, ClassIds.TRANSFORM_GROUP) then
		Logging.error("I3DUtil.iteratorChildren() called with non-transform entity %q (%d)", getName(node), node)
		printCallstack()
		return function() end
	else
		local currentIndex = 0
		local numChildren = getNumOfChildren(node)
		local iterator = function()
			if numChildren <= currentIndex then
				return nil
			else
				currentIndex = currentIndex + 1
				return currentIndex, getChildAt(node, currentIndex - 1)
			end
		end
		return iterator
	end
end
function I3DUtil.iteratorChildrenReverse(node)
	if node == nil or not entityExists(node) then
		return function() end
	end
	if not getHasClassId(node, ClassIds.TRANSFORM_GROUP) then
		Logging.error("I3DUtil.iteratorChildren() called with non-transform entity %q (%d)", getName(node), node)
		printCallstack()
		return function() end
	else
		local currentIndex = getNumOfChildren(node)
		local iterator = function()
			if currentIndex <= 0 then
				return nil
			else
				currentIndex = currentIndex - 1
				return currentIndex + 1, getChildAt(node, currentIndex)
			end
		end
		return iterator
	end
end
function I3DUtil.traverseToRoot(node, callback, stopNode)
	local success = callback(node)
	if success then
		local parent = getParent(node)
		if parent ~= 0 then
			if stopNode ~= nil and parent == stopNode then
				return
			end
			I3DUtil.traverseToRoot(parent, callback, stopNode)
		end
	end
end
function I3DUtil.iterateShaderParameterNodesRecursively(node, shaderParameter, func, funcTarget)
	if getHasClassId(node, ClassIds.SHAPE) and getHasShaderParameter(node, shaderParameter) then
		if funcTarget ~= nil then
			func(funcTarget, node)
		else
			func(node)
		end
	end
	for i = 0, getNumOfChildren(node) - 1 do
		I3DUtil.iterateShaderParameterNodesRecursively(getChildAt(node, i), shaderParameter, func, funcTarget)
	end
end
function I3DUtil.iterateShaderParametersNodesRecursively(node, shaderParameters, func, funcTarget)
	if getHasClassId(node, ClassIds.SHAPE) then
		for _, shaderParameter in ipairs(shaderParameters) do
			if getHasShaderParameter(node, shaderParameter) then
				if funcTarget ~= nil then
					func(funcTarget, node)
					break
				end
				func(node)
				break
			end
		end
	end
	for i = 0, getNumOfChildren(node) - 1 do
		I3DUtil.iterateShaderParametersNodesRecursively(getChildAt(node, i), shaderParameters, func, funcTarget)
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
	if node ~= 0 and (getHasClassId(node, ClassIds.SHAPE) and getGeometry(node) ~= 0) then
		getHasClassId(getGeometry(node), ClassIds.SPLINE)
	end
	return false
end
function I3DUtil.getIsTransformGroup(node)
	if node == nil or not entityExists(node) then
		return false
	end
	for _, id in pairs(ClassIds) do
		if id == ClassIds.TRANSFORM_GROUP then
			continue
		end
		if getHasClassId(node, id) then
			return false
		end
	end
	return true
end
function I3DUtil.getSupportsLOD(node)
	if getHasClassId(node, ClassIds.SHAPE) and not getIsNonRenderable(node) then
		local _v9 = not I3DUtil.getIsSpline(node) or getHasClassId(node, ClassIds.LIGHT_SOURCE) or getHasClassId(node, ClassIds.AUDIO_SOURCE)
	end
	getHasClassId(node, ClassIds.LIGHT_SOURCE)
	return getHasClassId(node, ClassIds.AUDIO_SOURCE)
end
function I3DUtil.getNodePath(node, stopAtNode, stopAtReference)
	local parent = getParent(node)
	if parent ~= 0 and node ~= stopAtNode then
		local isRef, filePath = getReferenceInfo(parent)
		if isRef then
			if stopAtReference then
				return "(Ref:" .. Utils.getFilenameFromPath(filePath) .. ")|" .. getName(node)
			else
				return I3DUtil.getNodePath(parent, stopAtNode, stopAtReference) .. "(Ref:" .. filePath .. ")|" .. getName(node)
			end
		end
		return I3DUtil.getNodePath(parent, stopAtNode, stopAtReference) .. "|" .. getName(node)
	end
	return getName(node)
end
function I3DUtil.getNodePathIndices(node, stopAtNode, includeStopNode)
	local parent = getParent(node)
	if parent ~= 0 and (getChildIndex(parent) ~= -1 and (node ~= stopAtNode and (parent ~= stopAtNode or includeStopNode ~= false))) then
		local spacer = "|"
		if getParent(parent) == getRootNode() then
			spacer = ">"
		end
		local path = I3DUtil.getNodePathIndices(parent, stopAtNode, includeStopNode)
		return string.format("%s%s%d", path, spacer, getChildIndex(node))
	end
	return string.format("%d", getChildIndex(node))
end
function I3DUtil.getRelativeNodePathIndices(node, parentNode)
	local parent = getParent(node)
	if parent ~= 0 and parent ~= parentNode then
		return I3DUtil.getRelativeNodePathIndices(parent, parentNode) .. "|" .. getChildIndex(node)
	end
	return getChildIndex(node)
end
function I3DUtil.getNodeNameAndIndexPath(node)
	return string.format("%s (%s)", I3DUtil.getNodePath(node), I3DUtil.getNodePathIndices(node))
end
function I3DUtil.checkForChildCollisions(node, errorFunc, ...)
	local rigidBodyType = getRigidBodyType(node)
	if rigidBodyType == RigidBodyType.STATIC or rigidBodyType == RigidBodyType.DYNAMIC or getIsCompoundChild(node) then
		errorFunc(node, ...)
	end
	for i = 0, getNumOfChildren(node) - 1 do
		I3DUtil.checkForChildCollisions(getChildAt(node, i), errorFunc, ...)
	end
end
function I3DUtil.registerI3dMappingXMLPaths(schema, path)
	schema:register(XMLValueType.STRING, path .. ".i3dMappings.i3dMapping(?)#id", "Identifier to be used in xml")
	schema:register(XMLValueType.STRING, path .. ".i3dMappings.i3dMapping(?)#node", "Index path to node in i3d file")
end
function I3DUtil.loadI3DMapping(xmlFile, path, components, mappings, realNumComponents)
	mappings = mappings or {}
	if xmlFile == nil then
		Logging.warning("Cannot load i3d mapping because xml file is missing")
		return mappings
	else
		path = path or xmlFile:getRootName()
		xmlFile:iterate(path .. ".i3dMappings.i3dMapping", function(_, key)
			local id = xmlFile:getString(key .. "#id")
			local node = xmlFile:getString(key .. "#node")
			if id ~= nil and node ~= nil then
				local nodeId, rootNode = I3DUtil.indexToObject(components, node, nil, realNumComponents)
				if nodeId ~= nil then
					mappings[id] = { nodeId = nodeId, rootNode = rootNode }
					return
				end
				mappings[id] = node
			end
		end)
		return mappings
	end
end
function I3DUtil.loadI3DComponents(rootNode, components)
	components = components or {}
	local numChildren = getNumOfChildren(rootNode)
	for i = 0, numChildren - 1 do
		table.insert(components, { node = getChildAt(rootNode, i) })
	end
	return components
end
