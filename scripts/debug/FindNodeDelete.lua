FindNodeDelete = {}
FindNodeDelete.NODES = {}
function FindNodeDelete.init()
	if not StartParams.getIsSet("findNodeDelete") then
		return
	else
		local oldDelete = delete
		function delete(id)
			if getHasClassId(id, ClassIds.TRANSFORM_GROUP) and next(FindNodeDelete.NODES) ~= nil then
				I3DUtil.iterateRecursively(id, function(node)
					if FindNodeDelete.NODES[node] ~= nil then
						printWarning(string.format("FindNodeDelete: Node '%s' will be deleted", getName(node)))
						printCallstack()
						FindNodeDelete.NODES[node] = nil
					end
					return next(FindNodeDelete.NODES) ~= nil
				end)
			end
			oldDelete(id)
		end
		printWarning("Warning: FindNodeDelete is active!")
	end
end
function FindNodeDelete.addNode(node)
	if not StartParams.getIsSet("findNodeDelete") then
		return
	else
		FindNodeDelete.NODES[node] = true
	end
end
