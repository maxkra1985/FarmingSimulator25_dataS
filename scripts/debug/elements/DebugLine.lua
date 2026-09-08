-- Local values: DebugLine_mt
DebugLine = {}
local DebugLine_mt = Class(DebugLine, DebugElement)

-- Upvalues: DebugLine_mt
-- Local values: self
function DebugLine.new(customMt)
	-- upvalues: (copy) DebugLine_mt
	local v3_ = DebugLine:superClass().new(customMt or DebugLine_mt)
	v3_.solid = false
	v3_.colorStart = nil
	v3_.colorEnd = nil
	v3_.alignToGround = false
	v3_.nodeStart = nil
	v3_.nodeEnd = nil
	return v3_
end

function DebugLine:draw()
	if self.nodeStart ~= nil and (self.nodeEnd ~= nil and (entityExists(self.nodeStart) and entityExists(self.nodeEnd))) then
		local v5_, v6_, v7_ = getWorldTranslation(self.nodeStart)
		self.xStart = v5_
		self.yStart = v6_
		self.zStart = v7_
		local v8_, v9_, v10_ = getWorldTranslation(self.nodeEnd)
		self.xEnd = v8_
		self.yEnd = v9_
		self.zEnd = v10_
	end
	DebugLine.renderBetweenPositions(self.xStart, self.yStart, self.zStart, self.xEnd, self.yEnd, self.zEnd, self.color, self.solid, self.text, self.textSize, self.colorStart, self.colorEnd, self.clipDistance, self.textClipDistance)
end

-- Local values: rStart, gStart, bStart, rEnd, gEnd, bEnd, x, y, z
function DebugLine.renderBetweenPositions(xStart, yStart, zStart, xEnd, yEnd, zEnd, color, solid, text, textSize, colorStart, colorEnd, clipDistance, textClipDistance)
	if yStart == nil or yEnd == nil then
		if g_terrainNode == nil then
			return
		end
		yStart = yStart or getTerrainHeightAtWorldPos(g_terrainNode, xStart, 0, zStart) + 0.01
		yEnd = yEnd or getTerrainHeightAtWorldPos(g_terrainNode, xEnd, 0, zEnd) + 0.01
	end
	if clipDistance == nil or (DebugUtil.isPositionInCameraRange(xStart, yStart, zStart, clipDistance) or DebugUtil.isPositionInCameraRange(xEnd, yEnd, zEnd, clipDistance)) then
		local v25_, v26_, v27_ = (colorStart or (color or Color.PRESETS.WHITE)):unpack()
		local v28_, v29_, v30_ = (colorEnd or (color or Color.PRESETS.WHITE)):unpack()
		drawDebugLine(xStart, yStart, zStart, v25_, v26_, v27_, xEnd, yEnd, zEnd, v28_, v29_, v30_, solid)
		if text ~= nil then
			local v31_ = (xStart + xEnd) / 2
			local v32_ = (yStart + yEnd) / 2
			local v33_ = (zStart + zEnd) / 2
			if textClipDistance == nil or DebugUtil.isPositionInCameraRange(v31_, v32_, v33_, textClipDistance) then
				Utils.renderTextAtWorldPosition(v31_, v32_, v33_, text, textSize or 0.016, 0.005, (color or (colorStart or (colorEnd or Color.PRESETS.WHITE))):unpack())
			end
		end
	end
end

-- Local values: xStart, yStart, zStart, xEnd, yEnd, zEnd
function DebugLine.renderBetweenNodes(nodeStart, nodeEnd, color, solid, text, textSize, colorStart, colorEnd, clipDistance, textClipDistance)
	local v44_, v45_, v46_ = getWorldTranslation(nodeStart)
	local v47_, v48_, v49_ = getWorldTranslation(nodeEnd)
	DebugLine.renderBetweenPositions(v44_, v45_, v46_, v47_, v48_, v49_, color, solid, text, textSize, colorStart, colorEnd, clipDistance, textClipDistance)
end

-- Local values: xStart, yStart, zStart, xEnd, yEnd, zEnd
function DebugLine:createWithStartAndEndNode(nodeStart, nodeEnd, alignToGround, solid, clipDistance, updatePosition)
	local v57_, v58_, v59_ = getWorldTranslation(nodeStart)
	local v60_, v61_, v62_ = getWorldTranslation(nodeEnd)
	self:createWithStartAndEndPos(v57_, v58_, v59_, v60_, v61_, v62_, alignToGround, solid, clipDistance)
	if updatePosition == true then
		self.nodeStart = nodeStart
		self.nodeEnd = nodeEnd
	end
	return self
end

function DebugLine:createWithStartAndEndPos(xStart, yStart, zStart, xEnd, yEnd, zEnd, alignToGround, solid, clipDistance)
	if alignToGround and g_terrainNode ~= nil then
		yStart = getTerrainHeightAtWorldPos(g_terrainNode, xStart, 0, zStart) + 0.1
		yEnd = getTerrainHeightAtWorldPos(g_terrainNode, xEnd, 0, zEnd) + 0.1
	end
	local v73_ = (xStart + xEnd) / 2
	local v74_ = (yStart + yEnd) / 2
	local v75_ = (zStart + zEnd) / 2
	self.x = v73_
	self.y = v74_
	self.z = v75_
	self.xStart = xStart
	self.yStart = yStart
	self.zStart = zStart
	self.xEnd = xEnd
	self.yEnd = yEnd
	self.zEnd = zEnd
	self.solid = Utils.getNoNil(solid, self.solid)
	self.clipDistance = Utils.getNoNil(clipDistance, self.clipDistance)
	return self
end

function DebugLine:setColors(colorStart, colorEnd)
	self.colorStart = colorStart or self.colorStart
	self.colorEnd = colorEnd or self.colorEnd
	return self
end
