PlaceableDeletedNodes = {}
function PlaceableDeletedNodes.prerequisitesPresent(specializations)
	return true
end
function PlaceableDeletedNodes.registerEventListeners(placeableType)
	SpecializationUtil.registerEventListener(placeableType, "onLoadFinished", PlaceableDeletedNodes)
end
function PlaceableDeletedNodes.registerXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("DeletedNodes")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".deletedNodes.deletedNode(?)#node", "The node that should be deleted")
	schema:setXMLSpecializationType()
end
function PlaceableDeletedNodes:onLoadFinished(savegame)
	if self.xmlFile == nil then
		return
	end
	if self.xmlFile:getNumOfElements("placeable.deletedNodes.deletedNode") == 0 then
		return
	end
	local nodes = {}
	local bones = {}
	I3DUtil.iterateRecursively(self.rootNode, function(node)
		if getHasClassId(node, ClassIds.SHAPE) and getShapeIsSkinned(node) then
			local numBones = getNumOfShapeBones(node)
			for boneIndex = 0, numBones - 1 do
				local bone = getShapeBone(node, boneIndex)
				bones[bone] = node
			end
		end
	end)
	for _, deletedNodeKey in self.xmlFile:iterator("placeable.deletedNodes.deletedNode") do
		local node = self.xmlFile:getValue(deletedNodeKey .. "#node", nil, self.components, self.i3dMappings)
		if node == nil then
			continue
		end
		if bones[node] ~= nil then
			if bones[node] ~= node then
				Logging.xmlWarning(self.xmlFile, "DeleteNode %q at %q is a bone of the skinned mesh %q and cannot be deleted on its own, ignoring", getName(node), deletedNodeKey, getName(bones[node]))
			else
				table.insert(nodes, node)
			end
		end
	end
	for _, node in ipairs(nodes) do
		delete(node)
	end
end
