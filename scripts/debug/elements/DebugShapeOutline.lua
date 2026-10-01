DebugShapeOutline = {}
local DebugShapeOutline_mt = Class(DebugShapeOutline, DebugElement)
function DebugShapeOutline.new(customMt)
	local self = DebugShapeOutline:superClass().new(customMt or DebugShapeOutline_mt)
	self.node = nil
	return self
end
function DebugShapeOutline:draw()
	DebugShapeOutline.render(self.node, self.recursive)
end
function DebugShapeOutline:createWithNode(node, recursive)
	self.node = node
	self.recursive = recursive
	return self
end
function DebugShapeOutline.render(node, recursive)
	if not entityExists(node) then
		return
	else
		I3DUtil.iterateRecursively(node, function(iteratingNode)
			if getHasClassId(iteratingNode, ClassIds.SHAPE) and not getIsNonRenderable(iteratingNode) then
				renderShapeOutline(iteratingNode, false)
				if not recursive then
					return false
				else
					return true
				end
			end
			return true
		end, true)
	end
end
function DebugShapeOutline.setOutlineColor(color)
	if color ~= nil then
		setOutlineColor(color:unpack())
	end
end
