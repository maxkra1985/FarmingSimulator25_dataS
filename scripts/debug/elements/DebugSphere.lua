DebugSphere = {}
local DebugSphere_mt = Class(DebugSphere, DebugElement)
function DebugSphere.new(customMt)
	local self = DebugSphere:superClass().new(customMt or DebugSphere_mt)
	self.radius = 1
	self.numSegments = 16
	self.solid = false
	self.alignToGround = false
	self.text = nil
	return self
end
function DebugSphere:delete() end
function DebugSphere:draw()
	DebugSphere.renderAtPosition(self.x, self.y, self.z, self.radius, self.color, self.numSegments, self.solid, self.alignToGround, self.text, self.textSize)
end
function DebugSphere.renderAtPosition(x, y, z, radius, color, numSegments, solid, alignToGround, text, textSize)
	numSegments = numSegments or 16
	if alignToGround and g_terrainNode ~= nil then
		y = getTerrainHeightAtWorldPos(g_terrainNode, x, y, z) + 0.05
	end
	local r, g, b, a = (color or Color.PRESETS.WHITE):unpack()
	for i = 1, numSegments do
		local a1 = (i - 1) / numSegments * 2 * 3.141592653589793
		local a2 = i / numSegments * 2 * 3.141592653589793
		local c1 = math.cos(a1) * radius
		local s1 = math.sin(a1) * radius
		local c2 = math.cos(a2) * radius
		local s2 = math.sin(a2) * radius
		local x1 = x + c1
		local y1 = y
		local z1 = z + s1
		local x2 = x + c2
		local y2 = y
		local z2 = z + s2
		local x3 = x + c1
		local y3 = y + s1
		local z3 = z
		local x4 = x + c2
		local y4 = y + s2
		local z4 = z
		local x5 = x
		local y5 = y + s1
		local z5 = z + c1
		local x6 = x
		local y6 = y + s2
		local z6 = z + c2
		drawDebugLine(x1, y1, z1, r, g, b, x2, y2, z2, r, g, b, solid)
		drawDebugLine(x3, y3, z3, r, g, b, x4, y4, z4, r, g, b, solid)
		drawDebugLine(x5, y5, z5, r, g, b, x6, y6, z6, r, g, b, solid)
	end
	drawDebugPoint(x, y, z, r, g, b, 1, solid)
	if text ~= nil then
		Utils.renderTextAtWorldPosition(x, y, z, text, textSize or 0.016, 0.005, r, g, b, a)
	end
end
function DebugSphere.renderAtNode(node, offsets, radius, color, numSegments, solid, alignToGround, text, textSize)
	local x, y, z = getWorldTranslation(node)
	if alignToGround then
		y = nil
	elseif offsets ~= nil then
		x = x + offsets[1]
		y = y + offsets[2]
		z = z + offsets[3]
	end
	DebugSphere.renderAtPosition(x, y, z, radius, color, numSegments, solid, alignToGround, text, textSize)
end
function DebugSphere.renderShapeBoundingSphere(shape, color, numSegments, solid, text, textSize)
	if not getHasClassId(shape, ClassIds.SHAPE) then
		return
	else
		local x, y, z, bvRadius = getShapeWorldBoundingSphere(shape)
		DebugSphere.renderAtPosition(x, y, z, bvRadius, color, numSegments, solid, false, text, textSize)
	end
end
function DebugSphere:createWithNode(node, radius, color, numSegments, solid, alignToGround)
	local x, y, z = getWorldTranslation(node)
	self:createWithWorldPos(x, y, z, radius, color, numSegments, solid, alignToGround)
	return self
end
function DebugSphere:createShapeBoundingSphere(node, color, numSegments, solid)
	if not getHasClassId(node, ClassIds.SHAPE) then
		Logging.error("DebugSphere:createShapeBoundingSphere(): node '%s' is not a shape", getName(node))
		return self
	else
		local x, y, z, bvRadius = getShapeWorldBoundingSphere(node)
		local text = string.format("'%s' (id=%d)\nBV", getName(node), node)
		self:createWithWorldPos(x, y, z, bvRadius, color, numSegments, solid, false, text)
		return self
	end
end
function DebugSphere:createWithWorldPos(x, y, z, radius, color, numSegments, solid, alignToGround, text)
	self.x = x
	self.y = y
	self.z = z
	self.radius = radius
	self.color = color or self.color
	self.numSegments = numSegments or self.numSegments
	self.solid = Utils.getNoNil(solid, self.solid)
	self.alignToGround = Utils.getNoNil(alignToGround, self.alignToGround)
	self.text = text or self.text
	return self
end
