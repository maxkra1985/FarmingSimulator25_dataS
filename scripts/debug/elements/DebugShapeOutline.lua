DebugShapeOutline = {}
local DebugShapeOutline_mt = Class(DebugShapeOutline, DebugElement)
function DebugShapeOutline.new(customMt)
	local self = DebugShapeOutline:superClass().new(customMt or DebugShapeOutline_mt)
	self.node = nil
	self.recursive = nil
	self.excludeHidden = nil
	return self
end
function DebugShapeOutline:draw()
	DebugShapeOutline.render(self.node, self.recursive, self.excludeHidden)
end
function DebugShapeOutline:createWithNode(node, recursive, excludeHidden)
	self.node = node
	self.recursive = recursive
	self.excludeHidden = excludeHidden
	return self
end
local function renderOutlineRecursively(node, recursive, excludeHidden)
	if excludeHidden and not getVisibility(node) then
		return true
	end
	if getHasClassId(node, ClassIds.SHAPE) and not getIsNonRenderable(node) then
		renderShapeOutline(node, false)
		if not recursive then
			return false
		end
	end
	local numChildren = getNumOfChildren(node)
	if getIsLODTransformGroup(node) then
		numChildren = math.min(numChildren, 1)
	end
	for i = 0, numChildren - 1 do
		if renderOutlineRecursively(getChildAt(node, i), recursive, excludeHidden) then
			continue
		end
		return false
	end
	return true
end
function DebugShapeOutline.render(node, recursive, excludeHidden)
	if not entityExists(node) then
		return
	elseif not (excludeHidden and not getEffectiveVisibility(node)) then
		renderOutlineRecursively(node, recursive, excludeHidden)
	end
end
function DebugShapeOutline.setOutlineColor(color)
	if color ~= nil then
		setOutlineColor(color:unpack())
	end
end
