FindNodeDelete = {}
FindNodeDelete.NODES = {}
function FindNodeDelete.init()
	if StartParams.getIsSet("findNodeDelete") then
		local v_u_1_ = delete
		function delete(p2_)
			-- upvalues: (copy) v_u_1_
			if getHasClassId(p2_, ClassIds.TRANSFORM_GROUP) and next(FindNodeDelete.NODES) ~= nil then
				I3DUtil.iterateRecursively(p2_, function(p3_)
					if FindNodeDelete.NODES[p3_] ~= nil then
						printWarning(string.format("FindNodeDelete: Node \'%s\' will be deleted", getName(p3_)))
						printCallstack()
						FindNodeDelete.NODES[p3_] = nil
					end
					return next(FindNodeDelete.NODES) ~= nil
				end)
			end
			v_u_1_(p2_)
		end
		printWarning("Warning: FindNodeDelete is active!")
	end
end

function FindNodeDelete.addNode(node)
	if StartParams.getIsSet("findNodeDelete") then
		FindNodeDelete.NODES[node] = true
	end
end
