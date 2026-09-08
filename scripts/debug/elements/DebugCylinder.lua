-- Local values: DebugCylinder_mt
DebugCylinder = {}
local DebugCylinder_mt = Class(DebugCylinder, DebugElement)

-- Upvalues: DebugCylinder_mt
-- Local values: self
function DebugCylinder.new(customMt)
	-- upvalues: (copy) DebugCylinder_mt
	local v3_ = DebugCylinder:superClass().new(customMt or DebugCylinder_mt)
	v3_.radius = 1
	v3_.height = 1
	v3_.axis = Axis.Y
	v3_.numSegments = 16
	v3_.solid = false
	v3_.alignToGround = false
	v3_.text = nil
	return v3_
end

function DebugCylinder:delete() end

function DebugCylinder:draw()
	DebugCylinder.renderAtPosition(self.x, self.y, self.z, self.radius, self.height, self.axis, self.color, self.numSegments, self.solid, self.alignToGround, self.text)
end

-- Local values: r, g, b, a, i, a1, a2, c1, s1, c2, s2, x1, y1, z1, x2, y2, z2, x1, y1, z1, x2, y2, z2, x1, y1, z1, x2, y2, z2
function DebugCylinder.renderAtPosition(x, y, z, radius, height, axis, color, numSegments, solid, alignToGround, text)
	local v16_ = numSegments or 16
	if alignToGround and g_terrainNode ~= nil then
		y = getTerrainHeightAtWorldPos(g_terrainNode, x, y, z) + 0.05
	end
	local v17_, v18_, v19_, v20_ = (color or Color.PRESETS.WHITE):unpack()
	for v21_ = 1, v16_ do
		local v22_ = (v21_ - 1) / v16_ * 2 * 3.141592653589793
		local v23_ = v21_ / v16_ * 2 * 3.141592653589793
		local v24_ = math.cos(v22_) * radius
		local v25_ = math.sin(v22_) * radius
		local v26_ = math.cos(v23_) * radius
		local v27_ = math.sin(v23_) * radius
		if axis == Axis.Y then
			local v28_ = x + v24_
			local v29_ = z + v25_
			local v30_ = x + v26_
			local v31_ = z + v27_
			drawDebugLine(v28_, y - height * 0.5, v29_, v17_, v18_, v19_, v30_, y - height * 0.5, v31_, v17_, v18_, v19_)
			drawDebugLine(v28_, y + height * 0.5, v29_, v17_, v18_, v19_, v30_, y + height * 0.5, v31_, v17_, v18_, v19_)
			drawDebugLine(v28_, y - height * 0.5, v29_, v17_, v18_, v19_, v28_, y + height * 0.5, v29_, v17_, v18_, v19_)
			drawDebugLine(v30_, y - height * 0.5, v31_, v17_, v18_, v19_, v30_, y + height * 0.5, v31_, v17_, v18_, v19_)
		elseif axis == Axis.X then
			local v32_ = y + v24_
			local v33_ = z + v25_
			local v34_ = y + v26_
			local v35_ = z + v27_
			drawDebugLine(x - height * 0.5, v32_, v33_, v17_, v18_, v19_, x - height * 0.5, v34_, v35_, v17_, v18_, v19_)
			drawDebugLine(x + height * 0.5, v32_, v33_, v17_, v18_, v19_, x + height * 0.5, v34_, v35_, v17_, v18_, v19_)
			drawDebugLine(x - height * 0.5, v32_, v33_, v17_, v18_, v19_, x + height * 0.5, v32_, v33_, v17_, v18_, v19_)
			drawDebugLine(x - height * 0.5, v34_, v35_, v17_, v18_, v19_, x + height * 0.5, v34_, v35_, v17_, v18_, v19_)
		elseif axis == Axis.Z then
			local v36_ = x + v24_
			local v37_ = y + v25_
			local v38_ = x + v26_
			local v39_ = y + v27_
			drawDebugLine(v36_, v37_, z - height * 0.5, v17_, v18_, v19_, v38_, v39_, z - height * 0.5, v17_, v18_, v19_)
			drawDebugLine(v36_, v37_, z + height * 0.5, v17_, v18_, v19_, v38_, v39_, z + height * 0.5, v17_, v18_, v19_)
			drawDebugLine(v36_, v37_, z - height * 0.5, v17_, v18_, v19_, v36_, v37_, z + height * 0.5, v17_, v18_, v19_)
			drawDebugLine(v38_, v39_, z - height * 0.5, v17_, v18_, v19_, v38_, v39_, z + height * 0.5, v17_, v18_, v19_)
		end
		DebugGizmo.renderAtPosition(x, y, z, 0, 0, 1, 0, 1, 0)
	end
	drawDebugPoint(x, y, z, v17_, v18_, v19_, 1, solid)
	if text ~= nil then
		Utils.renderTextAtWorldPosition(x, y, z, text, 0.02, 0.005, v17_, v18_, v19_, v20_)
	end
end

-- Local values: x, y, z
function DebugCylinder.renderAtNode(node, offsets, radius, height, axis, color, numSegments, solid, alignToGround, text)
	local v50_, v51_, v52_ = getWorldTranslation(node)
	if alignToGround then
		v51_ = nil
	elseif offsets ~= nil then
		v50_ = v50_ + offsets[1]
		v51_ = v51_ + offsets[2]
		v52_ = v52_ + offsets[3]
	end
	DebugCylinder.renderAtPosition(v50_, v51_, v52_, radius, height, axis, color, numSegments, solid, alignToGround, text)
end

-- Local values: x, y, z
function DebugCylinder:createWithNode(node, radius, height, axis, color, numSegments, solid, alignToGround)
	local v62_, v63_, v64_ = getWorldTranslation(node)
	self:createWithWorldPos(v62_, v63_, v64_, radius, height, axis, color, numSegments, solid, alignToGround)
	return self
end

function DebugCylinder:createWithWorldPos(x, y, z, radius, height, axis, color, numSegments, solid, alignToGround, text)
	self.x = x
	self.y = y
	self.z = z
	self.radius = radius
	self.height = height
	self.axis = axis or Axis.Y
	self.color = color or self.color
	self.numSegments = numSegments or self.numSegments
	self.solid = Utils.getNoNil(solid, self.solid)
	self.alignToGround = Utils.getNoNil(alignToGround, self.alignToGround)
	self.text = text or self.text
	return self
end
