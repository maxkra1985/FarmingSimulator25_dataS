-- Local values: DebugSphere_mt
DebugSphere = {}
local DebugSphere_mt = Class(DebugSphere, DebugElement)

-- Upvalues: DebugSphere_mt
-- Local values: self
function DebugSphere.new(customMt)
	-- upvalues: (copy) DebugSphere_mt
	local v3_ = DebugSphere:superClass().new(customMt or DebugSphere_mt)
	v3_.radius = 1
	v3_.numSegments = 16
	v3_.solid = false
	v3_.alignToGround = false
	v3_.text = nil
	return v3_
end

function DebugSphere:delete() end

function DebugSphere:draw()
	DebugSphere.renderAtPosition(self.x, self.y, self.z, self.radius, self.color, self.numSegments, self.solid, self.alignToGround, self.text, self.textSize)
end

-- Local values: r, g, b, a, i, a1, a2, c1, s1, c2, s2, x1, y1, z1, x2, y2, z2, x3, y3, z3, x4, y4, z4, x5, y5, z5, x6, y6, z6
function DebugSphere.renderAtPosition(x, y, z, radius, color, numSegments, solid, alignToGround, text, textSize)
	local v15_ = numSegments or 16
	if alignToGround and g_terrainNode ~= nil then
		y = getTerrainHeightAtWorldPos(g_terrainNode, x, y, z) + 0.05
	end
	local v16_, v17_, v18_, v19_ = (color or Color.PRESETS.WHITE):unpack()
	for v20_ = 1, v15_ do
		local v21_ = (v20_ - 1) / v15_ * 2 * 3.141592653589793
		local v22_ = v20_ / v15_ * 2 * 3.141592653589793
		local v23_ = math.cos(v21_) * radius
		local v24_ = math.sin(v21_) * radius
		local v25_ = math.cos(v22_) * radius
		local v26_ = math.sin(v22_) * radius
		local v27_ = x + v23_
		local v28_ = z + v24_
		local v29_ = x + v25_
		local v30_ = z + v26_
		local v31_ = x + v23_
		local v32_ = y + v24_
		local v33_ = x + v25_
		local v34_ = y + v26_
		local v35_ = y + v24_
		local v36_ = z + v23_
		local v37_ = y + v26_
		local v38_ = z + v25_
		drawDebugLine(v27_, y, v28_, v16_, v17_, v18_, v29_, y, v30_, v16_, v17_, v18_, solid)
		drawDebugLine(v31_, v32_, z, v16_, v17_, v18_, v33_, v34_, z, v16_, v17_, v18_, solid)
		drawDebugLine(x, v35_, v36_, v16_, v17_, v18_, x, v37_, v38_, v16_, v17_, v18_, solid)
	end
	drawDebugPoint(x, y, z, v16_, v17_, v18_, 1, solid)
	if text ~= nil then
		Utils.renderTextAtWorldPosition(x, y, z, text, textSize or 0.016, 0.005, v16_, v17_, v18_, v19_)
	end
end

-- Local values: x, y, z
function DebugSphere.renderAtNode(node, offsets, radius, color, numSegments, solid, alignToGround, text, textSize)
	local v48_, v49_, v50_ = getWorldTranslation(node)
	if alignToGround then
		v49_ = nil
	elseif offsets ~= nil then
		v48_ = v48_ + offsets[1]
		v49_ = v49_ + offsets[2]
		v50_ = v50_ + offsets[3]
	end
	DebugSphere.renderAtPosition(v48_, v49_, v50_, radius, color, numSegments, solid, alignToGround, text, textSize)
end

-- Local values: x, y, z, bvRadius
function DebugSphere.renderShapeBoundingSphere(shape, color, numSegments, solid, text, textSize)
	if getHasClassId(shape, ClassIds.SHAPE) then
		local v57_, v58_, v59_, v60_ = getShapeWorldBoundingSphere(shape)
		DebugSphere.renderAtPosition(v57_, v58_, v59_, v60_, color, numSegments, solid, false, text, textSize)
	end
end

-- Local values: x, y, z
function DebugSphere:createWithNode(node, radius, color, numSegments, solid, alignToGround)
	local v68_, v69_, v70_ = getWorldTranslation(node)
	self:createWithWorldPos(v68_, v69_, v70_, radius, color, numSegments, solid, alignToGround)
	return self
end

-- Local values: x, y, z, bvRadius, text
function DebugSphere:createShapeBoundingSphere(node, color, numSegments, solid)
	if not getHasClassId(node, ClassIds.SHAPE) then
		Logging.error("DebugSphere:createShapeBoundingSphere(): node \'%s\' is not a shape", getName(node))
		return self
	end
	local v76_, v77_, v78_, v79_ = getShapeWorldBoundingSphere(node)
	self:createWithWorldPos(v76_, v77_, v78_, v79_, color, numSegments, solid, false, (string.format("\'%s\' (id=%d)\nBV", getName(node), node)))
	return self
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
