-- Local values: DebugShapeOutline_mt
DebugShapeOutline = {}
local DebugShapeOutline_mt = Class(DebugShapeOutline, DebugElement)

-- Upvalues: DebugShapeOutline_mt
-- Local values: self
function DebugShapeOutline.new(customMt)
	-- upvalues: (copy) DebugShapeOutline_mt
	local v3_ = DebugShapeOutline:superClass().new(customMt or DebugShapeOutline_mt)
	v3_.node = nil
	return v3_
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
	if entityExists(node) then
		I3DUtil.iterateRecursively(node, function(p10_)
			-- upvalues: (copy) recursive
			if not getHasClassId(p10_, ClassIds.SHAPE) or getIsNonRenderable(p10_) then
				return true
			end
			renderShapeOutline(p10_, false)
			return recursive and true or false
		end, true)
	end
end

function DebugShapeOutline.setOutlineColor(color)
	if color ~= nil then
		setOutlineColor(color:unpack())
	end
end
