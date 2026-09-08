-- Local values: DebugCircle_mt
DebugCircle = {}
local DebugCircle_mt = Class(DebugCircle, DebugElement)

-- Upvalues: DebugCircle_mt
-- Local values: self
function DebugCircle.new(customMt)
	-- upvalues: (copy) DebugCircle_mt
	local v3_ = DebugCircle:superClass().new(customMt or DebugCircle_mt)
	v3_.radius = 1
	v3_.numSegments = 16
	v3_.solid = false
	v3_.alignToGround = false
	v3_.drawSectors = false
	v3_.text = nil
	return v3_
end

function DebugCircle:draw()
	local v5_ = DebugCircle.renderAtPosition
	local v6_ = self.x
	local v7_
	if self.alignToGround then
		v7_ = nil
	else
		v7_ = self.y or nil
	end
	v5_(v6_, v7_, self.z, self.radius, self.color, self.numSegments, self.solid, self.filled, self.drawSectors, self.text)
end

-- Local values: x, y, z
function DebugCircle.renderAtNode(node, offsets, radius, color, numSegments, solid, alignToGround, filled, drawSectors, text)
	local v18_, v19_, v20_ = getWorldTranslation(node)
	if offsets ~= nil then
		v18_ = v18_ + offsets[1]
		v19_ = v19_ + offsets[2]
		v20_ = v20_ + offsets[3]
	end
	if alignToGround then
		v19_ = nil
	end
	DebugCircle.renderAtPosition(v18_, v19_, v20_, radius, color, numSegments, solid, filled, drawSectors, text)
end

-- Local values: r, g, b, a, alignToTerrain, i, a1, a2, c, s, x1, y1, z1, x2, y2, z2
function DebugCircle.renderAtPosition(x, y, z, radius, color, numSegments, solid, filled, drawSectors, text)
	local v31_, v32_, v33_, v34_
	if color == nil then
		v31_ = 1
		v32_ = 1
		v33_ = 1
		v34_ = 1
	else
		v33_, v31_, v32_, v34_ = color:unpack()
	end
	local v35_ = y == nil
	if not v35_ or g_terrainNode ~= nil then
		local v36_ = numSegments or 16
		for v37_ = 1, v36_ do
			local v38_ = (v37_ - 1) / v36_ * 2 * 3.141592653589793
			local v39_ = v37_ / v36_ * 2 * 3.141592653589793
			local v40_ = math.cos(v38_) * radius
			local v41_ = math.sin(v38_) * radius
			local v42_ = x + v40_
			local v43_ = z + v41_
			local v44_ = math.cos(v39_) * radius
			local v45_ = math.sin(v39_) * radius
			local v46_ = x + v44_
			local v47_ = z + v45_
			local v48_, v49_
			if v35_ then
				v48_ = getTerrainHeightAtWorldPos(g_terrainNode, v42_, 0, v43_) + 0.05
				v49_ = getTerrainHeightAtWorldPos(g_terrainNode, v46_, 0, v47_) + 0.05
			else
				v49_ = y
				v48_ = v49_
				local v50_ = v49_
				v49_ = v48_
				v50_ = v48_
			end
			drawDebugLine(v42_, v48_, v43_, v33_, v31_, v32_, v46_, v49_, v47_, v33_, v31_, v32_, solid)
			if filled then
				drawDebugTriangle(x, y, z, v42_, v48_, v43_, v46_, v49_, v47_, v33_, v31_, v32_, 0.5, solid)
				drawDebugTriangle(v42_, v48_, v43_, x, y, z, v46_, v49_, v47_, v33_, v31_, v32_, 0.5, solid)
				drawDebugTriangle(v42_, v48_, v43_, v46_, v49_, v47_, x, y, z, v33_, v31_, v32_, 0.5, solid)
				drawDebugTriangle(v46_, v49_, v47_, x, y, z, v42_, v48_, v43_, v33_, v31_, v32_, 0.5, solid)
			end
			if drawSectors then
				if v35_ then
					y = getTerrainHeightAtWorldPos(g_terrainNode, x, 0, z) + 0.05
				end
				drawDebugLine(x, y, z, v33_, v31_, v32_, v42_, v48_, v43_, v33_, v31_, v32_, solid)
			end
		end
		if text ~= nil then
			if y == nil then
				y = getTerrainHeightAtWorldPos(g_terrainNode, x, 0, z) + 0.05
			end
			Utils.renderTextAtWorldPosition(x, y, z, text, 0.02, 0.01, v33_, v31_, v32_, v34_)
		end
	end
end

-- Local values: x, y, z
function DebugCircle:createWithNode(node, radius, color, numSegments, solid, alignToGround, filled, drawSectors)
	local v60_, v61_, v62_ = getWorldTranslation(node)
	self:createWithWorldPos(v60_, v61_, v62_, radius, color, numSegments, solid, alignToGround, filled, drawSectors)
	return self
end

function DebugCircle:createWithWorldPos(x, y, z, radius, color, numSegments, solid, alignToGround, filled, drawSectors)
	self.x = x
	self.y = y
	self.z = z
	self.radius = radius
	self.color = color or self.color
	self.numSegments = numSegments or self.numSegments
	self.solid = Utils.getNoNil(solid, self.solid)
	self.alignToGround = Utils.getNoNil(alignToGround, self.alignToGround)
	self.filled = Utils.getNoNil(filled, self.filled)
	self.drawSectors = Utils.getNoNil(drawSectors, self.drawSectors)
	return self
end
