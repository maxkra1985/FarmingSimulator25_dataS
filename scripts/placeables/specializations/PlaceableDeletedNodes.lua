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

-- Local values: nodes, bones, _, deletedNodeKey, node, _, node
function PlaceableDeletedNodes:onLoadFinished(savegame)
	if self.xmlFile == nil then
		return
	elseif self.xmlFile:getNumOfElements("placeable.deletedNodes.deletedNode") ~= 0 then
		local v_u_5_ = {}
		I3DUtil.iterateRecursively(self.rootNode, function(p6_)
			-- upvalues: (copy) v_u_5_
			if getHasClassId(p6_, ClassIds.SHAPE) and getShapeIsSkinned(p6_) then
				for v7_ = 0, getNumOfShapeBones(p6_) - 1 do
					v_u_5_[getShapeBone(p6_, v7_)] = p6_
				end
			end
		end)
		local v8_ = {}
		for _, v9_ in self.xmlFile:iterator("placeable.deletedNodes.deletedNode") do
			local v10_ = self.xmlFile:getValue(v9_ .. "#node", nil, self.components, self.i3dMappings)
			if v10_ ~= nil then
				if v_u_5_[v10_] == nil or v_u_5_[v10_] == v10_ then
					table.insert(v8_, v10_)
				else
					Logging.xmlWarning(self.xmlFile, "DeleteNode %q at %q is a bone of the skinned mesh %q and cannot be deleted on its own, ignoring", getName(v10_), v9_, getName(v_u_5_[v10_]))
				end
			end
		end
		for _, v11_ in ipairs(v8_) do
			delete(v11_)
		end
	end
end
