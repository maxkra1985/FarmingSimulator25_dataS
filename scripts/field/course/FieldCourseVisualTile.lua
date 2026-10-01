FieldCourseVisualTile = {}
FieldCourseVisualTile.TILE_SIZE = 32
local FieldCourseVisualTile_mt = Class(FieldCourseVisualTile)
function FieldCourseVisualTile.new(fieldCourseVisual)
	local self = setmetatable({}, FieldCourseVisualTile_mt)
	self.fieldCourseVisual = fieldCourseVisual
	self.visualSegments = {}
	self.toolSideSegments = {}
	self.sideOffsetSegmentsLeft = {}
	self.sideOffsetSegmentsRight = {}
	self.index = -1
	self.isValid = false
	self.foliageDataPlaneId = g_fruitTypeManager:getDefaultDataPlaneId()
	return self
end
function FieldCourseVisualTile:reset()
	for i = #self.visualSegments, 1, -1 do
		self.fieldCourseVisual:releaseVisualSegment(self.visualSegments[i])
		table.remove(self.visualSegments, i)
	end
	for i = #self.toolSideSegments, 1, -1 do
		self.fieldCourseVisual:releaseVisualSegment(self.toolSideSegments[i])
		table.remove(self.toolSideSegments, i)
	end
	for i = #self.sideOffsetSegmentsLeft, 1, -1 do
		self.fieldCourseVisual:releaseVisualSegment(self.sideOffsetSegmentsLeft[i])
		table.remove(self.sideOffsetSegmentsLeft, i)
	end
	for i = #self.sideOffsetSegmentsRight, 1, -1 do
		self.fieldCourseVisual:releaseVisualSegment(self.sideOffsetSegmentsRight[i])
		table.remove(self.sideOffsetSegmentsRight, i)
	end
	self.index = -1
	self.isValid = false
end
function FieldCourseVisualTile:init(index)
	self.index = index
	self.isValid = true
	local numRows = g_currentMission.terrainSize / FieldCourseVisualTile.TILE_SIZE
	local tilePositionZ = math.floor(index / numRows)
	local tilePositionX = index - tilePositionZ * numRows
	self.tileMinX = tilePositionX * FieldCourseVisualTile.TILE_SIZE - g_currentMission.terrainSize * 0.5
	self.tileMinZ = tilePositionZ * FieldCourseVisualTile.TILE_SIZE - g_currentMission.terrainSize * 0.5
	self.tileMaxX = self.tileMinX + FieldCourseVisualTile.TILE_SIZE
	self.tileMaxZ = self.tileMinZ + FieldCourseVisualTile.TILE_SIZE
	self:fillTile(self.fieldCourseVisual.fieldCourse.segments, self.visualSegments, true)
end
function FieldCourseVisualTile:fillTile(segments, target, doReset)
	if doReset then
		for i = #target, 1, -1 do
			self.fieldCourseVisual:releaseVisualSegment(target[i])
			table.remove(target, i)
		end
	end
	for segmentIndex, segment in ipairs(segments) do
		self:fillTileBySegment(segment, segmentIndex, target)
	end
end
function FieldCourseVisualTile:resetAdditionalSegments()
	for i = #self.toolSideSegments, 1, -1 do
		self.fieldCourseVisual:releaseVisualSegment(self.toolSideSegments[i])
		table.remove(self.toolSideSegments, i)
	end
	for i = #self.sideOffsetSegmentsLeft, 1, -1 do
		self.fieldCourseVisual:releaseVisualSegment(self.sideOffsetSegmentsLeft[i])
		table.remove(self.sideOffsetSegmentsLeft, i)
	end
	for i = #self.sideOffsetSegmentsRight, 1, -1 do
		self.fieldCourseVisual:releaseVisualSegment(self.sideOffsetSegmentsRight[i])
		table.remove(self.sideOffsetSegmentsRight, i)
	end
end
function FieldCourseVisualTile:fillAdditionalTileSegment(segment, segmentIndex, isToolSideSegment, isSideOffsetSegmentLeft, isSideOffsetSegmentRight)
	if segment ~= nil then
		if isToolSideSegment then
			self:fillTileBySegment(segment, segmentIndex, self.toolSideSegments)
			return
		end
		if isSideOffsetSegmentLeft then
			self:fillTileBySegment(segment, segmentIndex, self.sideOffsetSegmentsLeft)
			return
		end
		if isSideOffsetSegmentRight then
			self:fillTileBySegment(segment, segmentIndex, self.sideOffsetSegmentsRight)
		end
	end
end
function FieldCourseVisualTile:fillTileBySegment(segment, segmentIndex, target)
	for i = 1, #segment.positions - 1 do
		local p1 = segment.positions[i]
		local p2 = segment.positions[i + 1]
		local sx = p1[1]
		local sz = p1[2]
		local ex = p2[1]
		local ez = p2[2]
		local p1Inside = self.tileMinX <= sx and sx <= self.tileMaxX and self.tileMinZ <= sz and sz <= self.tileMaxZ
		local p2Inside = self.tileMinX <= ex and ex <= self.tileMaxX and self.tileMinZ <= ez and ez <= self.tileMaxZ
		if p1Inside then
			if p2Inside then
				self:addSegment(sx, sz, ex, ez, segmentIndex, target)
				if sx == self.tileMinX and ex == self.tileMinX then
					local z1 = math.clamp(sz, self.tileMinZ, self.tileMaxZ)
					local z2 = math.clamp(ez, self.tileMinZ, self.tileMaxZ)
					self:addSegment(sx, z1, ex, z2, segmentIndex, target)
				end
				if sz == self.tileMinZ and ez == self.tileMinZ then
					local x1 = math.clamp(sx, self.tileMinX, self.tileMaxX)
					local x2 = math.clamp(ex, self.tileMinX, self.tileMaxX)
					self:addSegment(x1, sz, x2, ez, segmentIndex, target)
				end
			elseif p1Inside or p2Inside then
				local intersect, x, z = MathUtil.getLineSegmentsIntersection(sx, sz, ex, ez, self.tileMinX, self.tileMinZ, self.tileMaxX, self.tileMinZ)
				if intersect then
					if p1Inside then
						self:addSegment(sx, sz, x, z, segmentIndex, target)
					else
						self:addSegment(x, z, ex, ez, segmentIndex, target)
					end
				else
					intersect, x, z = MathUtil.getLineSegmentsIntersection(sx, sz, ex, ez, self.tileMinX, self.tileMaxZ, self.tileMaxX, self.tileMaxZ)
					if intersect then
						if p1Inside then
							self:addSegment(sx, sz, x, z, segmentIndex, target)
						else
							self:addSegment(x, z, ex, ez, segmentIndex, target)
						end
					else
						intersect, x, z = MathUtil.getLineSegmentsIntersection(sx, sz, ex, ez, self.tileMinX, self.tileMinZ, self.tileMinX, self.tileMaxZ)
						if intersect then
							if p1Inside then
								self:addSegment(sx, sz, x, z, segmentIndex, target)
							else
								self:addSegment(x, z, ex, ez, segmentIndex, target)
							end
						else
							intersect, x, z = MathUtil.getLineSegmentsIntersection(sx, sz, ex, ez, self.tileMaxX, self.tileMinZ, self.tileMaxX, self.tileMaxZ)
							if intersect then
								if p1Inside then
									self:addSegment(sx, sz, x, z, segmentIndex, target)
								else
									self:addSegment(x, z, ex, ez, segmentIndex, target)
								end
							end
						end
					end
				end
			else
				local ix1 = nil
				local iz1 = nil
				local intersect, x, z = MathUtil.getLineSegmentsIntersection(sx, sz, ex, ez, self.tileMinX, self.tileMinZ, self.tileMaxX, self.tileMinZ)
				if intersect then
					ix1 = x
					iz1 = z
				end
				intersect, x, z = MathUtil.getLineSegmentsIntersection(sx, sz, ex, ez, self.tileMinX, self.tileMaxZ, self.tileMaxX, self.tileMaxZ)
				if intersect then
					if ix1 == nil then
						ix1 = x
						iz1 = z
						intersect, x, z = MathUtil.getLineSegmentsIntersection(sx, sz, ex, ez, self.tileMinX, self.tileMinZ, self.tileMinX, self.tileMaxZ)
						if intersect then
							if ix1 == nil then
								ix1 = x
								iz1 = z
								intersect, x, z = MathUtil.getLineSegmentsIntersection(sx, sz, ex, ez, self.tileMaxX, self.tileMinZ, self.tileMaxX, self.tileMaxZ)
								if intersect and ix1 ~= nil then
									self:addSegment(ix1, iz1, x, z, segmentIndex, target)
								end
							else
								self:addSegment(ix1, iz1, x, z, segmentIndex, target)
							end
						end
					else
						self:addSegment(ix1, iz1, x, z, segmentIndex, target)
					end
				end
			end
		end
	end
end
function FieldCourseVisualTile:addSegment(x1, z1, x2, z2, segmentIndex, target)
	local maxLength = self.fieldCourseVisual:getMaxVisualLineLength()
	local dirX = x2 - x1
	local dirZ = z2 - z1
	local length = MathUtil.vector2Length(dirX, dirZ)
	if 0 < length then
		dirX = dirX / length
		dirZ = dirZ / length
		for offset = 0, length - 0.01, maxLength do
			local sx = x1 + dirX * offset
			local sz = z1 + dirZ * offset
			local sy = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, sx, 0, sz)
			local l = math.min(length - offset, maxLength)
			if 0 < l then
				local segmentLength = math.min(math.ceil(l), maxLength)
				local lineSegment = self.fieldCourseVisual:getVisualSegment(segmentLength)
				setTranslation(lineSegment, sx, sy, sz)
				local yRot = MathUtil.getYRotationFromDirection(dirX, dirZ)
				setRotation(lineSegment, 0, yRot, 0)
				setUserAttribute(lineSegment, "segmentIndex", UserAttributeType.INTEGER, segmentIndex)
				setShaderParameter(lineSegment, "intensitySize", nil, l / segmentLength, nil, segmentLength, false)
				table.insert(target, lineSegment)
			end
		end
	end
end
function FieldCourseVisualTile:setSegmentData(segmentToData, isEnabled, isLeft, activeSegmentIndex)
	local hasSideOffset = self.fieldCourseVisual.fieldCourseSettings.sideOffset ~= 0
	for _, segment in ipairs(self.visualSegments) do
		local segmentIndex = getUserAttribute(segment, "segmentIndex")
		local data = segmentToData[segmentIndex]
		if data == nil then
			continue
		end
		if hasSideOffset and segmentIndex == activeSegmentIndex then
			data = FieldCourseVisual.VISUALS[self.fieldCourseVisual.isColorBlindMode].INACTIVE
		end
		local visibility = data[4]
		if visibility then
			local color = data[1]
			setShaderParameter(segment, "emitColor", color[1], color[2], color[3], color[4], false)
			setShaderParameter(segment, "intensitySize", data[2], nil, data[3], nil, false)
			local borderColor = data[5]
			if borderColor ~= nil then
				setShaderParameter(segment, "borderColor", borderColor[1], borderColor[2], borderColor[3], borderColor[4], false)
			else
				setShaderParameter(segment, "borderColor", nil, nil, nil, 1, false)
			end
			local dashNumLength = data[6]
			if dashNumLength ~= nil then
				setShaderParameter(segment, "dashNumLength", dashNumLength[1], dashNumLength[2], nil, nil, false)
			else
				setShaderParameter(segment, "dashNumLength", 0, nil, nil, nil, false)
			end
		end
		setVisibility(segment, visibility)
	end
	local toolData = FieldCourseVisual.VISUALS[self.fieldCourseVisual.isColorBlindMode].TOOL_SIDE
	for _, segment in ipairs(self.toolSideSegments) do
		local color = toolData[1]
		setShaderParameter(segment, "emitColor", color[1], color[2], color[3], color[4], false)
		setShaderParameter(segment, "intensitySize", toolData[2], nil, toolData[3], nil, false)
		local borderColor = toolData[5]
		if borderColor ~= nil then
			setShaderParameter(segment, "borderColor", borderColor[1], borderColor[2], borderColor[3], borderColor[4], false)
		else
			setShaderParameter(segment, "borderColor", nil, nil, nil, 1, false)
		end
		local dashNumLength = toolData[6]
		if dashNumLength ~= nil then
			setShaderParameter(segment, "dashNumLength", dashNumLength[1], dashNumLength[2], nil, nil, false)
		else
			setShaderParameter(segment, "dashNumLength", 0, nil, nil, nil, false)
		end
	end
	for _, segment in ipairs(self.sideOffsetSegmentsLeft) do
		local segmentIndex = getUserAttribute(segment, "segmentIndex")
		local data = segmentToData[segmentIndex]
		if data == nil then
			continue
		end
		local visibility = data[4] and isLeft
		if visibility then
			local color = data[1]
			setShaderParameter(segment, "emitColor", color[1], color[2], color[3], color[4], false)
			setShaderParameter(segment, "intensitySize", data[2], nil, data[3], nil, false)
			local borderColor = data[5]
			if borderColor ~= nil then
				setShaderParameter(segment, "borderColor", borderColor[1], borderColor[2], borderColor[3], borderColor[4], false)
			else
				setShaderParameter(segment, "borderColor", nil, nil, nil, 1, false)
			end
			local dashNumLength = data[6]
			if dashNumLength ~= nil then
				setShaderParameter(segment, "dashNumLength", dashNumLength[1], dashNumLength[2], nil, nil, false)
			else
				setShaderParameter(segment, "dashNumLength", 0, nil, nil, nil, false)
			end
		end
		setVisibility(segment, visibility)
	end
	for _, segment in ipairs(self.sideOffsetSegmentsRight) do
		local segmentIndex = getUserAttribute(segment, "segmentIndex")
		local data = segmentToData[segmentIndex]
		if data == nil then
			continue
		end
		local visibility = data[4] and not isLeft
		if visibility then
			local color = data[1]
			setShaderParameter(segment, "emitColor", color[1], color[2], color[3], color[4], false)
			setShaderParameter(segment, "intensitySize", data[2], nil, data[3], nil, false)
			local borderColor = data[5]
			if borderColor ~= nil then
				setShaderParameter(segment, "borderColor", borderColor[1], borderColor[2], borderColor[3], borderColor[4], false)
			else
				setShaderParameter(segment, "borderColor", nil, nil, nil, 1, false)
			end
			local dashNumLength = data[6]
			if dashNumLength ~= nil then
				setShaderParameter(segment, "dashNumLength", dashNumLength[1], dashNumLength[2], nil, nil, false)
			else
				setShaderParameter(segment, "dashNumLength", 0, nil, nil, nil, false)
			end
		end
		setVisibility(segment, visibility)
	end
end
function FieldCourseVisualTile:debugDraw()
	local title = string.format("Tile %d\nNumSegments: %d\nSeg Data Update: %.5fms", self.index, #self.visualSegments, self.segmentDataTime or -1)
	DebugPlane.renderWithPositions(self.tileMinX, 0, self.tileMinZ, self.tileMinX, 0, self.tileMaxZ, self.tileMaxX, 0, self.tileMinZ, self.color, true, false, true, false, title, nil)
end
