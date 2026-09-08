-- Local values: DebugPoint_mt
DebugPoint = {}
local DebugPoint_mt = Class(DebugPoint, DebugElement)

-- Upvalues: DebugPoint_mt
-- Local values: self
function DebugPoint.new(customMt)
	-- upvalues: (copy) DebugPoint_mt
	local v3_ = DebugPoint:superClass().new(customMt or DebugPoint_mt)
	v3_.solid = false
	v3_.alignToGround = false
	v3_.text = nil
	return v3_
end

function DebugPoint:draw()
	DebugPoint.renderAtPosition(self.x, self.y, self.z, self.color, self.solid, self.text, self.textSize, self.clipDistance, self.textClipDistance)
end

-- Local values: r, g, b, a
function DebugPoint.renderAtPosition(x, y, z, color, solid, text, textSize, clipDistance, textClipDistance)
	if y == nil then
		if g_terrainNode == nil then
			return
		end
		y = getTerrainHeightAtWorldPos(g_terrainNode, x, 0, z) + 0.01
	end
	if clipDistance == nil or DebugUtil.isPositionInCameraRange(x, y, z, clipDistance) then
		local v14_, v15_, v16_, v17_ = (color or Color.PRESETS.WHITE):unpack()
		drawDebugPoint(x, y, z, v14_, v15_, v16_, v17_, solid)
		if text ~= nil and (textClipDistance == nil or DebugUtil.isPositionInCameraRange(x, y, z, textClipDistance)) then
			Utils.renderTextAtWorldPosition(x, y, z, text, textSize or 0.016, 0.005, v14_, v15_, v16_, v17_)
		end
	end
end

-- Local values: x, y, z
function DebugPoint.renderAtNode(node, offsets, color, solid, text, textSize, clipDistance, textClipDistance)
	local v26_, v27_, v28_ = getWorldTranslation(node)
	if offsets ~= nil then
		v26_ = v26_ + offsets[1]
		v27_ = v27_ + offsets[2]
		v28_ = v28_ + offsets[3]
	end
	DebugPoint.renderAtPosition(v26_, v27_, v28_, color, solid, text, textSize, clipDistance, textClipDistance)
end

-- Local values: x, y, z
function DebugPoint:createWithNode(node, alignToGround, solid, clipDistance)
	local v34_, v35_, v36_ = getWorldTranslation(node)
	self:createWithWorldPos(v34_, v35_, v36_, alignToGround, solid, clipDistance)
	return self
end

function DebugPoint:createWithWorldPos(x, y, z, alignToGround, solid, clipDistance)
	if alignToGround and g_terrainNode ~= nil then
		y = getTerrainHeightAtWorldPos(g_terrainNode, x, 0, z) + 0.1
	end
	self.x = x
	self.y = y
	self.z = z
	self.solid = Utils.getNoNil(solid, self.solid)
	self.clipDistance = Utils.getNoNil(clipDistance, self.clipDistance)
	return self
end
