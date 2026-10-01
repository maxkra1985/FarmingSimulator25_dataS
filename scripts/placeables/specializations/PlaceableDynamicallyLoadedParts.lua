PlaceableDynamicallyLoadedParts = {}
function PlaceableDynamicallyLoadedParts.prerequisitesPresent(specializations)
	return true
end
function PlaceableDynamicallyLoadedParts.registerFunctions(placeableType)
	SpecializationUtil.registerFunction(placeableType, "onDynamicallyPartI3DLoaded", PlaceableDynamicallyLoadedParts.onDynamicallyPartI3DLoaded)
end
function PlaceableDynamicallyLoadedParts.registerEventListeners(placeableType)
	SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableDynamicallyLoadedParts)
	SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableDynamicallyLoadedParts)
	SpecializationUtil.registerEventListener(placeableType, "onFinalizePlacement", PlaceableDynamicallyLoadedParts)
end
function PlaceableDynamicallyLoadedParts.registerXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("DynamicallyLoadedParts")
	basePath = basePath .. ".dynamicallyLoadedParts.dynamicallyLoadedPart(?)"
	schema:register(XMLValueType.STRING, basePath .. "#filename", "Filename to i3d file")
	schema:register(XMLValueType.NODE_INDEX, basePath .. "#node", "Node in external i3d file", "0")
	schema:register(XMLValueType.NODE_INDEX, basePath .. "#linkNode", "Link node", "0>")
	schema:register(XMLValueType.VECTOR_TRANS, basePath .. "#position", "Position")
	schema:register(XMLValueType.NODE_INDEX, basePath .. "#rotationNode", "Rotation node", "node")
	schema:register(XMLValueType.VECTOR_ROT, basePath .. "#rotation", "Rotation node rotation")
	schema:register(XMLValueType.STRING, basePath .. "#shaderParameterName", "Shader parameter name")
	schema:register(XMLValueType.VECTOR_4, basePath .. "#shaderParameter", "Shader parameter to apply")
	ObjectChangeUtil.registerObjectChangeSingleXMLPaths(schema, basePath)
	schema:setXMLSpecializationType()
end
function PlaceableDynamicallyLoadedParts:onLoad(savegame)
	local spec = self.spec_dynamicallyLoadedParts
	spec.sharedLoadRequestIds = {}
	spec.parts = {}
	self.xmlFile:iterate("placeable.dynamicallyLoadedParts.dynamicallyLoadedPart", function(_, partKey)
		local filename = self.xmlFile:getValue(partKey .. "#filename")
		if filename ~= nil then
			filename = Utils.getFilename(filename, self.baseDirectory)
			local args = { key = partKey, filename = filename }
			args.xmlFile = self.xmlFile
			args.loadingTask = self:createLoadingTask(spec)
			local sharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(filename, true, true, self.onDynamicallyPartI3DLoaded, self, args)
			table.insert(spec.sharedLoadRequestIds, sharedLoadRequestId)
		else
			Logging.xmlWarning(self.xmlFile, "Missing filename for dynamically loaded part '%s'", partKey)
		end
	end)
end
function PlaceableDynamicallyLoadedParts:onDynamicallyPartI3DLoaded(i3dNode, failedReason, args)
	local spec = self.spec_dynamicallyLoadedParts
	local loadingTask = args.loadingTask
	local filename = args.filename
	local xmlFile = args.xmlFile
	local partKey = args.key
	if i3dNode == 0 then
		Logging.xmlError(xmlFile, "Could not load load part %q at %q!", filename, partKey)
		self:finishLoadingTask(loadingTask)
		return false
	end
	local node = xmlFile:getValue(partKey .. "#node", "0", i3dNode)
	if node == nil then
		Logging.xmlWarning(xmlFile, "Failed to load dynamicallyLoadedPart '%s'. Unable to find node in loaded i3d", partKey)
		self:finishLoadingTask(loadingTask)
		delete(i3dNode)
		return false
	else
		local linkedSkinnedShapes = nil
		I3DUtil.iterateRecursively(node, function(toBeLinkedNode)
			if getHasClassId(toBeLinkedNode, ClassIds.SHAPE) and getShapeIsSkinned(toBeLinkedNode) then
				linkedSkinnedShapes = linkedSkinnedShapes or {}
				linkedSkinnedShapes[toBeLinkedNode] = true
			end
		end)
		local linkedBones = nil
		I3DUtil.iterateRecursively(i3dNode, function(loadedNode)
			if getHasClassId(loadedNode, ClassIds.SHAPE) and getShapeIsSkinned(loadedNode) then
				local numBones = getNumOfShapeBones(loadedNode)
				for boneIndex = 0, numBones - 1 do
					local bone = getShapeBone(loadedNode, boneIndex)
					linkedBones = linkedBones or {}
					linkedBones[bone] = loadedNode
				end
			end
		end)
		if linkedSkinnedShapes ~= nil or linkedBones ~= nil then
			local missingShapesForBones = nil
			I3DUtil.iterateRecursively(node, function(toBeLinkedNode)
				local shape = linkedBones[toBeLinkedNode]
				if shape ~= nil then
					linkedBones[toBeLinkedNode] = nil
					if linkedSkinnedShapes == nil or linkedSkinnedShapes[shape] == nil then
						missingShapesForBones = missingShapesForBones or {}
						missingShapesForBones[shape] = toBeLinkedNode
					end
				end
			end)
			if missingShapesForBones ~= nil then
				for shape, bone in pairs(missingShapesForBones) do
					Logging.xmlWarning(self.xmlFile, "Node %q at %q do not contain the skinned shape %q for bone %q, ignoring", getName(node), partKey .. "#node", getName(shape), getName(bone))
				end
				self:finishLoadingTask(loadingTask)
				delete(i3dNode)
				return false
			end
			if next(linkedBones) ~= nil then
				for bone, shape in pairs(linkedBones) do
					if linkedSkinnedShapes == nil or linkedSkinnedShapes[shape] ~= nil then
						Logging.xmlWarning(self.xmlFile, "Node %q at %q does not contain all bones of the skinned shape %q and cannot be linked on their own, ignoring", getName(node), partKey .. "#node", getName(shape))
						for bone2, shape2 in pairs(linkedBones) do
							if shape == shape2 then
								linkedBones[bone2] = nil
							end
						end
						if linkedSkinnedShapes == nil then
							continue
						end
						linkedSkinnedShapes[shape] = nil
					end
				end
				self:finishLoadingTask(loadingTask)
				delete(i3dNode)
				return false
			end
		end
		local linkNode = xmlFile:getValue(partKey .. "#linkNode", "0>", self.components, self.i3dMappings)
		if linkNode == nil then
			Logging.xmlWarning(xmlFile, "Failed to load dynamicallyLoadedPart '%s'. Unable to find linkNode", partKey)
			self:finishLoadingTask(loadingTask)
			delete(i3dNode)
			return false
		else
			removeFromPhysics(node)
			local x, y, z = xmlFile:getValue(partKey .. "#position")
			if x ~= nil and (y ~= nil and z ~= nil) then
				setTranslation(node, x, y, z)
			end
			local rotationNode = xmlFile:getValue(partKey .. "#rotationNode", node, i3dNode)
			local rotX, rotY, rotZ = xmlFile:getValue(partKey .. "#rotation")
			if rotX ~= nil and (rotY ~= nil and rotZ ~= nil) then
				setRotation(rotationNode, rotX, rotY, rotZ)
			end
			local shaderParameterName = xmlFile:getValue(partKey .. "#shaderParameterName")
			local sx, sy, sz, sw = xmlFile:getValue(partKey .. "#shaderParameter")
			if shaderParameterName ~= nil and (sx ~= nil and (sy ~= nil and (sz ~= nil and sw ~= nil))) then
				setShaderParameter(node, shaderParameterName, sx, sy, sz, sw, false)
			end
			local objectChanges = ObjectChangeUtil.loadObjectChangeFromXML(xmlFile, partKey, nil, i3dNode, nil)
			ObjectChangeUtil.setObjectChanges(objectChanges, true, nil)
			link(linkNode, node)
			delete(i3dNode)
			local dynamicallyLoadedPart = {}
			dynamicallyLoadedPart.filename = filename
			dynamicallyLoadedPart.node = node
			table.insert(spec.parts, dynamicallyLoadedPart)
			self:finishLoadingTask(loadingTask)
			return true
		end
	end
end
function PlaceableDynamicallyLoadedParts:onDelete()
	local spec = self.spec_dynamicallyLoadedParts
	if spec.sharedLoadRequestIds ~= nil then
		for _, sharedLoadRequestId in ipairs(spec.sharedLoadRequestIds) do
			g_i3DManager:releaseSharedI3DFile(sharedLoadRequestId)
		end
		spec.sharedLoadRequestIds = nil
	end
	if spec.parts ~= nil then
		for _, part in pairs(spec.parts) do
			delete(part.node)
		end
	end
end
function PlaceableDynamicallyLoadedParts:onFinalizePlacement()
	local spec = self.spec_dynamicallyLoadedParts
	if spec.parts ~= nil then
		for _, part in pairs(spec.parts) do
			addToPhysics(part.node)
		end
	end
end
