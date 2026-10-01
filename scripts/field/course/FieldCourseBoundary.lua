FieldCourseBoundary = {}
FieldCourseBoundary.SEGMENT_SPLIT_ANGLE = 0.4363323129985824
local FieldCourseBoundary_mt = Class(FieldCourseBoundary)
function FieldCourseBoundary.new()
	local self = setmetatable({}, FieldCourseBoundary_mt)
	self.segmentSplitAngle = FieldCourseBoundary.SEGMENT_SPLIT_ANGLE
	self.segments = {}
	self.boundaryLine = {}
	return self
end
function FieldCourseBoundary.createByBoundaryLine(boundaryLine, segmentSplitAngle)
	local removedSegments = false
	local self = FieldCourseBoundary.new()
	self.segmentSplitAngle = segmentSplitAngle
	self.segments, removedSegments = FieldCourseBoundary.generateSegmentsByBoundaryLine(boundaryLine, segmentSplitAngle)
	if self.segments ~= nil and 0 < #self.segments then
		self.boundaryLine = boundaryLine
		if removedSegments then
			self:generateBoundaryLine()
		end
		return self
	end
	return nil
end
function FieldCourseBoundary:isValid()
	return 0 < #self.segments
end
function FieldCourseBoundary:extend(offset)
	if self.segments == nil or #self.segments == 0 then
		return nil
	end
	local segmentParts = {}
	for _, segment in ipairs(self.segments) do
		for i = 1, #segment.positions - 1 do
			local segmentPart = {}
			segmentPart.p1 = segment.positions[i]
			segmentPart.p2 = segment.positions[i + 1]
			table.insert(segmentParts, segmentPart)
		end
	end
	local boundaryLine = FieldCourseBoundary.getOffsetBoundaryBySegmentParts(segmentParts, offset)
	if #boundaryLine == 0 then
		return nil
	end
	table.insert(boundaryLine, table.clone(boundaryLine[1]))
	FieldCourseUtil.removeShortSegments(boundaryLine, 0.25)
	local lengthBefore = FieldCourseUtil.getSegmentLength(boundaryLine)
	if not FieldCourseBoundary.resolveSelfIntersections(boundaryLine) then
		return nil
	end
	local lengthAfter = FieldCourseUtil.getSegmentLength(boundaryLine)
	if lengthAfter < lengthBefore * 0.66 then
		return nil
	end
	if lengthAfter <= 0.1 then
		return nil
	end
	local originalLength = FieldCourseUtil.getSegmentLength(self.boundaryLine)
	if 0 < offset then
		if originalLength < lengthAfter then
			return nil
		end
	elseif lengthAfter < originalLength then
		return nil
	end
	if FieldCourseBoundary.getIsBoundaryLineInverted(boundaryLine) then
		return nil
	elseif not FieldCourseUtil.getAreBoundariesColliding(boundaryLine, self.boundaryLine) then
		return FieldCourseBoundary.createByBoundaryLine(boundaryLine, self.segmentSplitAngle)
	else
		return nil
	end
end
function FieldCourseBoundary:generateBoundaryLine()
	local boundaryLine = {}
	local numSegments = #self.segments
	for i, segment in ipairs(self.segments) do
		local numPositions = #segment.positions
		local maxPosition = i == numSegments and numPositions or numPositions - 1
		for posIndex = 1, maxPosition do
			table.insert(boundaryLine, table.clone(segment.positions[posIndex]))
		end
	end
	self.boundaryLine = boundaryLine
end
function FieldCourseBoundary:isColliding(otherBoundary)
	return FieldCourseUtil.getAreBoundariesColliding(self.boundaryLine, otherBoundary.boundaryLine)
end
function FieldCourseBoundary:isInsideOf(otherBoundary)
	for i = 1, #self.boundaryLine - 1 do
		if FieldCourseUtil.getIsPointInsideBoundary(self.boundaryLine[i][1], self.boundaryLine[i][2], otherBoundary.boundaryLine) then
			continue
		end
		return false
	end
	return true
end
function FieldCourseBoundary:cut(otherBoundary, invert)
	if invert == nil then
		invert = false
	end
	for segmentIndex, segment in ipairs(self.segments) do
		if 2 <= #segment.positions then
			local posIndex = 1
			while posIndex <= #segment.positions do
				local x1 = segment.positions[posIndex][1]
				local z1 = segment.positions[posIndex][2]
				if FieldCourseUtil.getIsPointInsideBoundary(x1, z1, otherBoundary.boundaryLine) == not invert then
					local lastPosition = segment.positions[posIndex - 1]
					if lastPosition ~= nil then
						if FieldCourseUtil.getIsPointInsideBoundary(lastPosition[1], lastPosition[2], otherBoundary.boundaryLine) == invert then
							local intersect, ix, iz = FieldCourseUtil.getSegmentBoundaryIntersection(x1, z1, lastPosition[1], lastPosition[2], otherBoundary.boundaryLine)
							if intersect then
								for i = posIndex + 1, #segment.positions do
									local nextPos = segment.positions[i]
									if FieldCourseUtil.getIsPointInsideBoundary(nextPos[1], nextPos[2], otherBoundary.boundaryLine) == invert then
										local prevPos = segment.positions[i - 1]
										local intersect2, ix2, iz2 = FieldCourseUtil.getSegmentBoundaryIntersection(prevPos[1], prevPos[2], nextPos[1], nextPos[2], otherBoundary.boundaryLine)
										if intersect2 then
											segment.positions[posIndex][1] = ix
											segment.positions[posIndex][2] = iz
											local newSegment = {}
											newSegment.positions = {}
											table.insert(newSegment.positions, { ix2, iz2 })
											for indexToRemove = i, #segment.positions do
												table.insert(newSegment.positions, segment.positions[indexToRemove])
												segment.positions[indexToRemove] = nil
											end
											for indexToRemove = i - 1, posIndex + 1, -1 do
												segment.positions[indexToRemove] = nil
											end
											table.insert(self.segments, segmentIndex + 1, newSegment)
											return self:cut(otherBoundary, invert)
										end
									end
								end
								for i = #segment.positions, posIndex + 1, -1 do
									segment.positions[i] = nil
								end
							end
						end
					else
						local nextPos = segment.positions[posIndex + 1]
						if nextPos ~= nil then
							if FieldCourseUtil.getIsPointInsideBoundary(nextPos[1], nextPos[2], otherBoundary.boundaryLine) == not invert then
								table.remove(segment.positions, posIndex)
								posIndex = posIndex - 1
							else
								local intersect, ix, iz = FieldCourseUtil.getSegmentBoundaryIntersection(x1, z1, nextPos[1], nextPos[2], otherBoundary.boundaryLine)
								if intersect then
									segment.positions[posIndex][1] = ix
									segment.positions[posIndex][2] = iz
								end
							end
						end
					end
				else
					local nextPos = segment.positions[posIndex + 1]
					if nextPos ~= nil then
						local x2 = segment.positions[posIndex + 1][1]
						local z2 = segment.positions[posIndex + 1][2]
						if FieldCourseUtil.getIsPointInsideBoundary(x1, z1, otherBoundary.boundaryLine) == invert and FieldCourseUtil.getIsPointInsideBoundary(x2, z2, otherBoundary.boundaryLine) == invert then
							local intersect, ix1, iz1 = FieldCourseUtil.getSegmentClosestBoundaryIntersection(x1, z1, x2, z2, otherBoundary.boundaryLine)
							if intersect then
								local intersect2, ix2, iz2 = FieldCourseUtil.getSegmentClosestBoundaryIntersection(x2, z2, x1, z1, otherBoundary.boundaryLine)
								if intersect2 then
									table.insert(segment.positions, posIndex + 1, { ix1, iz1 })
									local newSegment = {}
									newSegment.positions = {}
									table.insert(newSegment.positions, { ix2, iz2 })
									for i = posIndex + 2, #segment.positions do
										table.insert(newSegment.positions, segment.positions[i])
										segment.positions[i] = nil
									end
									table.insert(self.segments, segmentIndex + 1, newSegment)
									return self:cut(otherBoundary, invert)
								end
							end
						end
					end
				end
				posIndex = posIndex + 1
			end
		end
	end
	for i = #self.segments, 1, -1 do
		local positions = self.segments[i].positions
		if #positions < 2 then
			table.remove(self.segments, i)
		elseif FieldCourseUtil.getSegmentLength(positions) == 0 then
			table.remove(self.segments, i)
		end
	end
end
function FieldCourseBoundary:removeCollidingSegments(otherBoundary, workWidth)
	local numSegmentsStart = #self.segments
	for i = numSegmentsStart, 1, -1 do
		local segment = self.segments[i]
		for posIndex = #segment.positions - 1, 1, -1 do
			local x1 = segment.positions[posIndex][1]
			local z1 = segment.positions[posIndex][2]
			local x2 = segment.positions[posIndex + 1][1]
			local z2 = segment.positions[posIndex + 1][2]
			local dirX, dirZ = MathUtil.vector2Normalize(x2 - x1, z2 - z1)
			if FieldCourseUtil.getIsSegmentInsideBoundary(x1 - dirZ * workWidth, z1 + dirX * workWidth, x2 - dirZ * workWidth, z2 + dirX * workWidth, otherBoundary.boundaryLine) then
				if FieldCourseUtil.getIsSegmentInsideBoundary(x1 + dirZ * workWidth, z1 - dirX * workWidth, x2 + dirZ * workWidth, z2 - dirX * workWidth, otherBoundary.boundaryLine) then
					continue
				end
				if posIndex == 1 then
					table.remove(segment.positions, posIndex)
				else
					table.remove(segment.positions, posIndex + 1)
				end
			elseif posIndex ~= 1 then
				table.remove(segment.positions, posIndex + 1)
			else
				table.remove(segment.positions, posIndex)
			end
		end
		if #segment.positions < 2 then
			table.remove(self.segments, i)
		end
	end
	return numSegmentsStart ~= #self.segments
end
function FieldCourseBoundary:generateDebugLines(line)
	if dl == nil or dp == nil then
		return
	end
	if line ~= nil then
		local numPositions = #line
		for posIndex = 1, numPositions - 1 do
			local x1 = line[posIndex][1]
			local z1 = line[posIndex][2]
			local x2 = line[posIndex + 1][1]
			local z2 = line[posIndex + 1][2]
			dl(x1, z1, x2, z2, 0.5, false, { 1, 0, 0 })
		end
	else
		for segmentIndex, segment in ipairs(self.segments) do
			if segment.invalid == true then
				continue
			end
			local numPositions = #segment.positions
			for posIndex = 1, numPositions - 1 do
				local x1 = segment.positions[posIndex][1]
				local z1 = segment.positions[posIndex][2]
				local x2 = segment.positions[posIndex + 1][1]
				local z2 = segment.positions[posIndex + 1][2]
				dl(x1, z1, x2, z2, 0.5, false, { 1, 0, 0 })
			end
		end
	end
end
function FieldCourseBoundary:draw(r, g, b, offset)
	for _, segment in ipairs(self.segments) do
		local numPositions = #segment.positions
		for posIndex = 1, numPositions - 1 do
			local x1 = segment.positions[posIndex][1]
			local z1 = segment.positions[posIndex][2]
			local x2 = segment.positions[posIndex + 1][1]
			local z2 = segment.positions[posIndex + 1][2]
			local y1 = getTerrainHeightAtWorldPos(g_terrainNode, x1, 0, z1) + (offset or 1)
			local y2 = getTerrainHeightAtWorldPos(g_terrainNode, x2, 0, z2) + (offset or 1)
			drawDebugLine(x1, y1, z1, r, g, b, x2, y2, z2, r, g, b, false)
			drawDebugPoint(x1, y1, z1, r, g, b, 1, false)
			if posIndex + 1 == numPositions then
				drawDebugPoint(x2, y2, z2, r, g, b, 1, false)
			end
		end
	end
end
function FieldCourseBoundary.generateSegmentsByBoundaryLine(boundaryLine, segmentSplitAngle)
	local numBoundaryPositions = #boundaryLine
	if numBoundaryPositions < 4 then
		return nil, false
	end
	segmentSplitAngle = segmentSplitAngle or FieldCourseBoundary.SEGMENT_SPLIT_ANGLE
	local splitSegments = FieldCourseBoundary.splitBoundary(boundaryLine, segmentSplitAngle)
	if splitSegments == nil then
		return nil, false
	else
		local segments = {}
		for _, splitSegment in ipairs(splitSegments) do
			local segment = {}
			segment.positions = splitSegment
			table.insert(segments, segment)
		end
		local removedSegments = false
		if segments ~= nil then
			for i = #segments, 1, -1 do
				local length = FieldCourseUtil.getSegmentLength(segments[i].positions)
				if length < FieldCourse.MIN_SEGMENT_LENGTH then
					local prevSegment = segments[i - 1] or segments[#segments]
					local nextSegment = segments[i + 1] or segments[1]
					if prevSegment ~= nil and nextSegment ~= nil then
						local p1 = prevSegment.positions[#prevSegment.positions]
						local p2 = nextSegment.positions[1]
						local x = (p1[1] + p2[1]) * 0.5
						local z = (p1[2] + p2[2]) * 0.5
						p1[1] = x
						p1[2] = z
						p2[1] = x
						p2[2] = z
					end
					table.remove(segments, i)
					removedSegments = true
				end
			end
		end
		return segments, removedSegments
	end
end
function FieldCourseBoundary.getLineSegmentIntersections(boundaryLine, ignoreIndex, x, z, dirX, dirZ)
	local intersectCount = 0
	for posIndex = 1, #boundaryLine - 1 do
		if posIndex == ignoreIndex then
			continue
		end
		local pos1 = boundaryLine[posIndex]
		local pos2 = boundaryLine[posIndex + 1]
		local intersect, ix, iz = MathUtil.getLineSegmentsIntersection(x, z, x + dirX * 65535, z + dirZ * 65535, pos1[1], pos1[2], pos2[1], pos2[2])
		if intersect then
			local distance1 = MathUtil.vector2Length(ix - pos1[1], iz - pos1[2])
			local distance2 = MathUtil.vector2Length(ix - pos2[1], iz - pos2[2])
			if distance1 == 0 or distance2 == 0 then
				continue
			end
			intersectCount = intersectCount + 1
		end
	end
	for posIndex = 1, #boundaryLine - 1 do
		local pos = boundaryLine[posIndex]
		local dot = MathUtil.getProjectOnLineParameter(pos[1], pos[2], x, z, dirX, dirZ)
		if 0 < dot then
			local ix = x + dirX * dot
			local iz = z + dirZ * dot
			if MathUtil.vector2Length(ix - pos[1], iz - pos[2]) == 0 then
				local isInside1 = FieldCourseUtil.getIsPointInsideBoundary(pos[1] - dirX * 0.01, pos[2] - dirZ * 0.01, boundaryLine)
				local isInside2 = FieldCourseUtil.getIsPointInsideBoundary(pos[1] + dirX * 0.01, pos[2] + dirZ * 0.01, boundaryLine)
				if isInside1 == isInside2 then
					continue
				end
				intersectCount = intersectCount + 1
			end
		end
	end
	return intersectCount
end
function FieldCourseBoundary.getIsBoundaryLineInverted(boundaryLine)
	for posIndex = 1, #boundaryLine - 1 do
		local pos1 = boundaryLine[posIndex]
		local pos2 = boundaryLine[posIndex + 1]
		if pos2 == nil then
			pos1 = boundaryLine[posIndex - 1]
			pos2 = boundaryLine[posIndex]
		end
		local x = (pos2[1] + pos1[1]) * 0.5
		local z = (pos2[2] + pos1[2]) * 0.5
		local dirX, dirZ = MathUtil.vector2Normalize(pos2[1] - pos1[1], pos2[2] - pos1[2])
		dirZ = dirX
		dirX = -dirZ
		local intersectCount = FieldCourseBoundary.getLineSegmentIntersections(boundaryLine, posIndex, x, z, dirX, dirZ)
		if intersectCount % 2 == 0 then
			return true
		end
	end
	return false
end
function FieldCourseBoundary.resolveSelfIntersections(boundaryLine)
	local p1 = boundaryLine[1]
	local p2 = boundaryLine[#boundaryLine]
	local length = MathUtil.vector2Length(p1[1] - p2[1], p1[2] - p2[2])
	local isLoop = length < 0.001
	local startIndex = 1
	local foundIntersection = false
	for index1 = startIndex, #boundaryLine - 1 do
		for index2 = #boundaryLine, index1 + 3, -1 do
			local p1 = boundaryLine[index1]
			local p2 = boundaryLine[index1 + 1]
			local p3 = boundaryLine[index2 - 1]
			local p4 = boundaryLine[index2]
			local intersect, pX, pZ = MathUtil.getLineSegmentsIntersection(p1[1], p1[2], p2[1], p2[2], p3[1], p3[2], p4[1], p4[2])
			if intersect then
				table.insert(boundaryLine, index2, { pX, pZ })
				table.insert(boundaryLine, index1 + 1, { pX, pZ })
				startIndex = index1 + 1
				foundIntersection = true
				break
			end
		end
		if not foundIntersection then
			continue
		end
		while foundIntersection do
		end
		for posIndex = 1, #boundaryLine - 1 do
			local pos1 = boundaryLine[posIndex]
			local pos2 = boundaryLine[posIndex + 1]
			if pos2 == nil then
				pos1 = boundaryLine[posIndex - 1]
				pos2 = boundaryLine[posIndex]
			end
			local x = (pos2[1] + pos1[1]) * 0.5
			local z = (pos2[2] + pos1[2]) * 0.5
			local dirX = pos2[1] - pos1[1]
			local dirZ = pos2[2] - pos1[2]
			local length = MathUtil.vector2Length(pos2[1] - pos1[1], pos2[2] - pos1[2])
			if 0 < length then
				if isLoop then
					dirX = dirX / length
					dirZ = dirZ / length
					dirZ = dirX
					dirX = -dirZ
					local intersectCount = FieldCourseBoundary.getLineSegmentIntersections(boundaryLine, posIndex, x, z, dirX, dirZ)
					if intersectCount % 2 == 0 then
						pos1.isInvalid1 = true
						pos2.isInvalid2 = true
					end
				end
			else
				pos1.isInvalid1 = true
				pos2.isInvalid2 = true
			end
		end
		for posIndex = #boundaryLine, 1, -1 do
			if boundaryLine[posIndex].isInvalid1 and boundaryLine[posIndex].isInvalid2 then
				table.remove(boundaryLine, posIndex)
			end
		end
		local pointsRemove = false
		local boundaryLineLength = #boundaryLine
		local _v137 = 1
		for _v207 = _v137, boundaryLineLength - 1 do
			local posIndex1 = _v137
			for posOffset = 1, boundaryLineLength do
				local posIndex2 = posIndex1 + math.ceil(math.min(posOffset * 0.5, math.floor(boundaryLineLength * 0.5))) * (posOffset % 2 == 0 and 1 or -1)
				local pos1 = boundaryLine[(posIndex1 - 1) % boundaryLineLength + 1]
				local pos2 = boundaryLine[(posIndex2 - 1) % boundaryLineLength + 1]
				if MathUtil.vector2Length(pos1[1] - pos2[1], pos1[2] - pos2[2]) < 0.001 then
					if posIndex2 < posIndex1 then
						posIndex2 = posIndex1
						posIndex1 = posIndex2
					end
					for i = posIndex1 + 1, posIndex2 do
						boundaryLine[(i - 1) % boundaryLineLength + 1].isInvalid = true
					end
				end
			end
		end
		for posIndex = #boundaryLine, 1, -1 do
			if boundaryLine[posIndex].isInvalid then
				table.remove(boundaryLine, posIndex)
				pointsRemove = true
			end
		end
		while pointsRemove do
		end
		if #boundaryLine == 0 then
			return false
		else
			if isLoop then
				table.insert(boundaryLine, table.clone(boundaryLine[1], 1))
			end
			return true
		end
	end
end
function FieldCourseBoundary.getMaxSegmentAngle(points, maxSamples)
	if #points <= 3 then
		return 0
	else
		local angle = {}
		for i = 1, #points - 2 do
			local x1 = points[i][1]
			local z1 = points[i][2]
			local x2 = points[i + 1][1]
			local z2 = points[i + 1][2]
			local x3 = points[i + 2][1]
			local z3 = points[i + 2][2]
			local dir1X = x2 - x1
			local dir1Z = z2 - z1
			local dir2X = x2 - x3
			local dir2Z = z2 - z3
			local length1 = MathUtil.vector2Length(dir1X, dir1Z)
			local length2 = MathUtil.vector2Length(dir2X, dir2Z)
			if 0 < length1 and 0 < length2 then
				table.insert(angle, 3.141592653589793 - math.acos(MathUtil.dotProduct(dir1X / length1, 0, dir1Z / length1, dir2X / length2, 0, dir2Z / length2)))
			end
		end
		table.sort(angle, function(a, b)
			return b < a
		end)
		for i = maxSamples, 1, -1 do
			if angle[i] == nil then
				continue
			end
			return angle[i]
		end
		return 0
	end
end
function FieldCourseBoundary.segmentApplySideOffset(segment, sideOffset)
	FieldCourseUtil.extendSegment(segment.positions, -1, 100)
	FieldCourseUtil.extendSegment(segment.positions, 1, 100)
	local offsetLine = FieldCourseBoundary.getOffsetBoundaryLine(segment.positions, -sideOffset, 0.01)
	if offsetLine ~= nil then
		FieldCourseUtil.extendSegment(offsetLine, -1, -100)
		FieldCourseUtil.extendSegment(offsetLine, 1, -100)
		if 2 <= #offsetLine then
			segment.positions = offsetLine
			return true
		end
	end
	FieldCourseUtil.extendSegment(segment.positions, -1, -100)
	FieldCourseUtil.extendSegment(segment.positions, 1, -100)
	return false
end
function FieldCourseBoundary.getOffsetBoundaryLine(boundaryLine, offset, minSegmentLength)
	local segmentParts = {}
	for i = 1, #boundaryLine - 1 do
		local segmentPart = {}
		segmentPart.p1 = boundaryLine[i]
		segmentPart.p2 = boundaryLine[i + 1]
		local length = MathUtil.vector2Length(segmentPart.p2[1] - segmentPart.p1[1], segmentPart.p2[2] - segmentPart.p1[2])
		if (minSegmentLength or 0.001) < length then
			table.insert(segmentParts, segmentPart)
		end
	end
	local p1 = boundaryLine[1]
	local p2 = boundaryLine[#boundaryLine]
	local length = MathUtil.vector2Length(p1[1] - p2[1], p1[2] - p2[2])
	local isLoop = length < 0.001
	if #segmentParts < 1 then
		return nil
	else
		return FieldCourseBoundary.getOffsetBoundaryBySegmentParts(segmentParts, offset, isLoop)
	end
end
function FieldCourseBoundary.getOffsetBoundaryBySegmentParts(segmentParts, offset, isLoop)
	local connectSingleSegments = function(segments, segmentIndex, nextSegmentIndex)
		local segment = segments[segmentIndex]
		local nextSegment = segments[nextSegmentIndex]
		if not segment.connected and (math.abs(segment.p2Offset[1] - nextSegment.p1Offset[1]) < 0.01 and math.abs(segment.p2Offset[2] - nextSegment.p1Offset[2]) < 0.01) then
			segment.p2Offset[1] = nextSegment.p1Offset[1]
			segment.p2Offset[2] = nextSegment.p1Offset[2]
			segment.connected = true
		end
		if not segment.connected then
			local intersect, pX, pZ = MathUtil.getLineSegmentsIntersection(segment.p1Offset[1], segment.p1Offset[2], segment.p2Offset[1], segment.p2Offset[2], nextSegment.p1Offset[1], nextSegment.p1Offset[2], nextSegment.p2Offset[1], nextSegment.p2Offset[2])
			if intersect then
				segment.p2Offset[1] = pX
				segment.p2Offset[2] = pZ
				nextSegment.p1Offset[1] = pX
				nextSegment.p1Offset[2] = pZ
				segment.connected = true
				return
			end
			local sx = segment.p1Offset[1]
			local sz = segment.p1Offset[2]
			local dirSX = segment.p2Offset[1] - segment.p1Offset[1]
			local dirSZ = segment.p2Offset[2] - segment.p1Offset[2]
			local sLength = MathUtil.vector2Length(dirSX, dirSZ)
			if 0 < sLength then
				dirSX = dirSX / sLength
				dirSZ = dirSZ / sLength
				local ex = nextSegment.p2Offset[1]
				local ez = nextSegment.p2Offset[2]
				local dirEX = nextSegment.p1Offset[1] - nextSegment.p2Offset[1]
				local dirEZ = nextSegment.p1Offset[2] - nextSegment.p2Offset[2]
				local eLength = MathUtil.vector2Length(dirEX, dirEZ)
				if 0 < eLength then
					dirEX = dirEX / eLength
					dirEZ = dirEZ / eLength
					local intersectionPos = nil
					local _ = nil
					intersect, intersectionPos, _ = MathUtil.getLineLineIntersection2D(sx, sz, dirSX, dirSZ, ex, ez, dirEX, dirEZ)
					if intersect then
						pX = sx + dirSX * intersectionPos
						pZ = sz + dirSZ * intersectionPos
						segment.p2Offset[1] = pX
						segment.p2Offset[2] = pZ
						nextSegment.p1Offset[1] = pX
						nextSegment.p1Offset[2] = pZ
						segment.connected = true
					end
				end
			end
		end
	end
	local connectSegments = function()
		local numSegmentParts = #segmentParts
		for segmentIndex = 1, numSegmentParts do
			segmentParts[segmentIndex].connected = false
		end
		local start = numSegmentParts
		local limit = numSegmentParts + numSegmentParts - 1
		if isLoop == false then
			start = numSegmentParts + 1
			limit = numSegmentParts + numSegmentParts - 2
		end
		for segmentIndex = start, limit do
			connectSingleSegments(segmentParts, (segmentIndex - 1) % numSegmentParts + 1, (segmentIndex + 1 - 1) % numSegmentParts + 1)
		end
		for segmentIndex = start, limit do
			connectSingleSegments(segmentParts, (segmentIndex - 1) % numSegmentParts + 1, (segmentIndex + 1 - 1) % numSegmentParts + 1)
		end
		local finished = true
		for segmentIndex = 1, #segmentParts do
			local segment = segmentParts[segmentIndex]
			if segment.connected then
				continue
			end
			if isLoop ~= false or segmentIndex < #segmentParts - 1 then
				local nextIndex = (segmentIndex + 1 - 1) % numSegmentParts + 1
				local nextSegment = segmentParts[nextIndex]
				local length = MathUtil.vector2Length(segment.p2Offset[1] - segment.p1Offset[1], segment.p2Offset[2] - segment.p1Offset[2])
				local nextLength = MathUtil.vector2Length(nextSegment.p2Offset[1] - nextSegment.p1Offset[1], nextSegment.p2Offset[2] - nextSegment.p1Offset[2])
				if length < nextLength then
					segment.pendingRemove = true
				else
					nextSegment.pendingRemove = true
				end
			end
		end
		for segmentIndex = numSegmentParts, 1, -1 do
			if segmentParts[segmentIndex].pendingRemove then
				table.remove(segmentParts, segmentIndex)
				finished = false
			end
		end
		return finished or #segmentParts == 0
	end
	local numSegmentParts = #segmentParts
	for segmentIndex = 1, numSegmentParts do
		local segment = segmentParts[segmentIndex]
		local x1 = segment.p1[1]
		local z1 = segment.p1[2]
		local x2 = segment.p2[1]
		local z2 = segment.p2[2]
		local dirX1, dirZ1 = MathUtil.vector2Normalize(x2 - x1, z2 - z1)
		segment.p1Offset = { segment.p1[1] - dirZ1 * offset, segment.p1[2] + dirX1 * offset }
		segment.p2Offset = { segment.p2[1] - dirZ1 * offset, segment.p2[2] + dirX1 * offset }
	end
	while not connectSegments() do
	end
	local reconnectionRequired = false
	for i = #segmentParts, 1, -1 do
		local segmentPart = segmentParts[i]
		if segmentPart.connected then
			local dirX1, dirZ1 = MathUtil.vector2Normalize(segmentPart.p2[1] - segmentPart.p1[1], segmentPart.p2[2] - segmentPart.p1[2])
			local dirX2 = segmentPart.p2Offset[1] - segmentPart.p1Offset[1]
			local dirZ2 = segmentPart.p2Offset[2] - segmentPart.p1Offset[2]
			local length = MathUtil.vector2Length(dirX2, dirZ2)
			if length == 0 then
				reconnectionRequired = true
				table.remove(segmentParts, i)
			else
				dirX2 = dirX2 / length
				dirZ2 = dirZ2 / length
				local dot = MathUtil.dotProduct(dirX1, 0, dirZ1, dirX2, 0, dirZ2)
				if dot < 0 then
					reconnectionRequired = true
					table.remove(segmentParts, i)
				end
			end
		end
	end
	if reconnectionRequired then
		for i = 1, #segmentParts do
			segmentParts[i].connected = false
		end
		while not connectSegments() do
		end
	end
	if isLoop == false then
		segmentParts[1].connected = true
		local numSegments = #segmentParts
		if 1 < numSegments then
			segmentParts[numSegments - 1].connected = true
			segmentParts[numSegments].connected = true
		end
	end
	local boundaryLine = {}
	for segmentPartIndex, segmentPart in ipairs(segmentParts) do
		if segmentPart.connected then
			table.insert(boundaryLine, segmentPart.p1Offset)
			if isLoop == false and segmentPartIndex == #segmentParts then
				table.insert(boundaryLine, segmentPart.p2Offset)
			end
		end
	end
	return boundaryLine
end
function FieldCourseBoundary:adjustSegmentByHitPoints(hitPoints, segmentAdjustLength, offset)
	for _, hitPoint in ipairs(hitPoints) do
		local posIndex = #self.boundaryLine - 1
		while true do
			local p1 = self.boundaryLine[posIndex]
			if p1 == nil then
				break
			end
			local p2 = self.boundaryLine[posIndex + 1]
			local sx = p1[1]
			local sz = p1[2]
			local ex = p2[1]
			local ez = p2[2]
			local dx = ex - sx
			local dz = ez - sz
			local length = MathUtil.vector2Length(dx, dz)
			dx = dx / length
			dz = dz / length
			local dot = MathUtil.getProjectOnLineParameter(hitPoint[1], hitPoint[2], p1[1], p1[2], dx, dz)
			if 0 <= dot and dot <= length then
				local lx = p1[1] + dx * dot
				local lz = p1[2] + dz * dot
				if MathUtil.vector2Length(hitPoint[1] - lx, hitPoint[2] - lz) < segmentAdjustLength * 2 then
					if dot < length - segmentAdjustLength then
						table.insert(self.boundaryLine, posIndex + 1, { sx + dx * (dot + segmentAdjustLength), sz + dz * (dot + segmentAdjustLength) })
					else
						local lengthLeft = length - dot
						local p3 = self.boundaryLine[posIndex + 2]
						if p3 ~= nil then
							local dx2 = p3[1] - ex
							local dz2 = p3[2] - ez
							local nextLength = MathUtil.vector2Length(dx2, dz2)
							dx2 = dx2 / nextLength
							dz2 = dz2 / nextLength
							lengthLeft = math.min(lengthLeft, nextLength - 0.05)
							table.insert(self.boundaryLine, posIndex + 2, { ex + dx2 * lengthLeft, ez + dz2 * lengthLeft })
						end
					end
					table.insert(self.boundaryLine, posIndex + 1, { sx + dx * dot, sz + dz * dot })
					if segmentAdjustLength < dot then
						table.insert(self.boundaryLine, posIndex + 1, { sx + dx * (dot - segmentAdjustLength), sz + dz * (dot - segmentAdjustLength) })
					else
						local lengthLeft = segmentAdjustLength - dot
						local p0 = self.boundaryLine[posIndex - 1]
						if p0 ~= nil then
							local dx2 = p0[1] - sx
							local dz2 = p0[2] - sz
							local prevLength = MathUtil.vector2Length(dx2, dz2)
							dx2 = dx2 / prevLength
							dz2 = dz2 / prevLength
							lengthLeft = math.min(lengthLeft, prevLength - 0.05)
							table.insert(self.boundaryLine, posIndex, { sx + dx2 * lengthLeft, sz + dz2 * lengthLeft })
							posIndex = posIndex - 1
						end
					end
				end
			end
			posIndex = posIndex - 1
		end
		FieldCourseUtil.removeShortSegments(self.boundaryLine, 0.25)
	end
	FieldCourseUtil.removeShortSegments(self.boundaryLine, 0.25)
	local pendingPositionChanges = {}
	for _, hitPoint in ipairs(hitPoints) do
		local hx = hitPoint[1]
		local hz = hitPoint[2]
		local cx, cz = FieldCourseUtil.getClosestPositionOnBoundary(hx, hz, self.boundaryLine)
		local distanceToBoundary = MathUtil.vector2Length(cx - hx, cz - hz)
		if FieldCourseUtil.getIsPointInsideBoundary(hx, hz, self.boundaryLine) then
			distanceToBoundary = -distanceToBoundary
		end
		if VehicleDebug.state == VehicleDebug.DEBUG_AI then
			local debugCircle = DebugCircle.new():createWithWorldPos(cx, 0, cz, self.segmentCollisionCheckSafetyOffset, nil, 25, false, true, false, false)
			g_debugManager:addElement(debugCircle, nil, math.huge, math.huge)
		end
		for i = 1, #self.boundaryLine do
			local p0 = self.boundaryLine[i - 1]
			local p1 = self.boundaryLine[i]
			local p2 = self.boundaryLine[i + 1]
			local pdx = nil
			local pdz = nil
			if p0 ~= nil then
				if p2 ~= nil then
					local pdx1, pdz1 = MathUtil.vector2Normalize(p1[1] - p0[1], p1[2] - p0[2])
					local pdx2, pdz2 = MathUtil.vector2Normalize(p2[1] - p1[1], p2[2] - p1[2])
					pdx, pdz = MathUtil.vector2Normalize(pdx1 + pdx2, pdz1 + pdz2)
				elseif p0 ~= nil then
					pdx, pdz = MathUtil.vector2Normalize(p1[1] - p0[1], p1[2] - p0[2])
				elseif p2 ~= nil then
					pdx, pdz = MathUtil.vector2Normalize(p2[1] - p1[1], p2[2] - p1[2])
				end
			end
			local alpha = 1 - math.min(MathUtil.vector2Length(p1[1] - cx, p1[2] - cz) / 5, 1)
			if 0 < alpha then
				alpha = math.min(alpha * 1.5, 1)
				local offset = math.max(self.segmentCollisionCheckSafetyOffset + 1 - distanceToBoundary, 0.5) * alpha
				if 0 < offset then
					if pendingPositionChanges[i] == nil then
						pendingPositionChanges[i] = {}
					end
					table.insert(pendingPositionChanges[i], { -pdz * offset, pdx * offset })
				end
			end
		end
	end
	for index, positions in pairs(pendingPositionChanges) do
		local numPositions = #positions
		local x = 0
		local z = 0
		local max = 0
		for i = 1, numPositions do
			x = x + positions[i][1]
			z = z + positions[i][2]
			max = math.max(max, MathUtil.vector2Length(positions[i][1], positions[i][2]))
		end
		x = x / numPositions
		z = z / numPositions
		local dirX, dirZ = MathUtil.vector2Normalize(x, z)
		local p = self.boundaryLine[index]
		if VehicleDebug.state == VehicleDebug.DEBUG_AI then
			local debugLine = DebugLine.new():createWithStartAndEndPos(p[1], 0, p[2], p[1] + dirX * max, 0, p[2] + dirZ * max, true, true)
			g_debugManager:addElement(debugLine, nil, math.huge, math.huge)
		end
		p[1] = p[1] + dirX * max
		p[2] = p[2] + dirZ * max
	end
	self.boundaryLine[1] = table.clone(self.boundaryLine[#self.boundaryLine])
	FieldCourseUtil.removeShortSegments(self.boundaryLine, 0.25)
	FieldCourseUtil.douglasPeucker(self.boundaryLine, 1)
end
function FieldCourseBoundary:segmentCollisionOverlapCallback(nodeId, subShapeIndex, isLast)
	if nodeId ~= 0 then
		local object = g_currentMission:getNodeObject(nodeId)
		if object == nil or object.spec_vine == nil then
			local x, _, z = getWorldTranslation(nodeId)
			table.insert(self.segmentCollisionCheckHitPoints, { x, z })
			if VehicleDebug.state == VehicleDebug.DEBUG_AI then
				local debugCircle = DebugCircle.new():createWithWorldPos(x, 0, z, self.segmentCollisionCheckSafetyOffset, nil, 25, false, true, false, false)
				debugCircle.text = "obstacle: " .. getName(nodeId)
				g_debugManager:addElement(debugCircle, nil, math.huge, math.huge)
			end
		end
	end
	if isLast then
		self.segmentCollisionCheckNumOverlapChecks = self.segmentCollisionCheckNumOverlapChecks - 1
		if self.segmentCollisionCheckNumOverlapChecks <= 0 then
			local numHitPoints = #self.segmentCollisionCheckHitPoints
			if 0 < numHitPoints then
				self:adjustSegmentByHitPoints(self.segmentCollisionCheckHitPoints, 15, 4)
			end
			self.segmentCollisionCheckCallback(0 < numHitPoints)
		end
	end
	return true
end
function FieldCourseBoundary:segmentCollisionOffset(testWidth, safetyOffset, callback)
	self.segmentCollisionCheckCallback = callback
	self.segmentCollisionCheckFinished = false
	self.segmentCollisionCheckSafetyOffset = safetyOffset
	self.segmentCollisionCheckHitPoints = {}
	self.segmentCollisionCheckNumOverlapChecks = #self.boundaryLine - 1
	for i = 1, #self.boundaryLine - 1 do
		local p1 = self.boundaryLine[i]
		local p2 = self.boundaryLine[i + 1]
		local dx = p2[1] - p1[1]
		local dz = p2[2] - p1[2]
		local length = MathUtil.vector2Length(dx, dz)
		dx = dx / length
		dz = dz / length
		local rotY = MathUtil.getYRotationFromDirection(dx, dz)
		local y1 = getTerrainHeightAtWorldPos(g_terrainNode, p1[1], 0, p1[2])
		local y2 = getTerrainHeightAtWorldPos(g_terrainNode, p2[1], 0, p2[2])
		local rotX = -math.atan((y2 - y1) / length)
		local rotZ = 0
		local sx = testWidth + safetyOffset
		local sy = 4
		local sz = length
		local bx = (p1[1] + p2[1]) * 0.5
		local by = (y1 + y2) * 0.5 + 2
		local bz = (p1[2] + p2[2]) * 0.5
		bx = bx - dz * (testWidth - safetyOffset) * 0.5
		bz = bz + dx * (testWidth - safetyOffset) * 0.5
		overlapBoxAsync(bx, by, bz, rotX, rotY, 0, sx * 0.5, 2, sz * 0.5, "segmentCollisionOverlapCallback", self, CollisionFlag.AI_BLOCKING, false, false, true, true)
	end
end
function FieldCourseBoundary:regenerateSegments()
	local _ = nil
	self.segments, _ = FieldCourseBoundary.generateSegmentsByBoundaryLine(self.boundaryLine)
end
function FieldCourseBoundary.getBoundaryOffsetPosition(positions, index, length, direction, isLoop)
	local numPositions = #positions
	local numChecks = numPositions
	if not isLoop then
		numChecks = 0 < direction and numPositions - index or index - 1
	end
	for i = 0, numChecks - 1 do
		local pos3 = nil
		local pos4 = nil
		if 0 < direction then
			pos3 = positions[(index + i - 1) % numPositions + 1]
			pos4 = positions[(index + i + 1 - 1) % numPositions + 1]
		else
			pos3 = positions[(index - i - 1) % numPositions + 1]
			pos4 = positions[(index - i - 1 - 1) % numPositions + 1]
		end
		local dir2X = pos4[1] - pos3[1]
		local dir2Z = pos4[2] - pos3[2]
		local segmentLength = MathUtil.vector2Length(dir2X, dir2Z)
		if length < segmentLength or i == numChecks - 1 then
			dir2X = dir2X / segmentLength
			dir2Z = dir2Z / segmentLength
			length = math.min(length, segmentLength)
			return pos3[1] + dir2X * length, pos3[2] + dir2Z * length
		end
		length = length - segmentLength
	end
	return positions[index][1], positions[index][2]
end
function FieldCourseBoundary.getSegmentAngle(positions, excludeIndex, isLoop)
	local maxAngle = 0
	local maxAngleIndex = -1
	local numPositions = #positions
	local min = 0
	local max = numPositions + 1
	if not isLoop then
		min = 2
		max = numPositions - 1
	end
	for i = min, max do
		local x1, z1 = FieldCourseBoundary.getBoundaryOffsetPosition(positions, i, 2, -1, isLoop)
		local p2 = positions[(i - 1) % numPositions + 1]
		local x2 = p2[1]
		local z2 = p2[2]
		local x3, z3 = FieldCourseBoundary.getBoundaryOffsetPosition(positions, i, 2, 1, isLoop)
		local dirX1 = x2 - x1
		local dirZ1 = z2 - z1
		local length1 = MathUtil.vector2Length(dirX1, dirZ1)
		local dirX2 = x3 - x2
		local dirZ2 = z3 - z2
		local length2 = MathUtil.vector2Length(dirX2, dirZ2)
		if 0 < length1 and 0 < length2 then
			dirX1 = dirX1 / length1
			dirZ1 = dirZ1 / length1
			dirX2 = dirX2 / length2
			dirZ2 = dirZ2 / length2
			local angle = math.acos(FieldCourseUtil.vector2Dot(dirX1, dirZ1, dirX2, dirZ2))
			if maxAngle < angle and (excludeIndex == nil or (i - 1) % numPositions + 1 ~= excludeIndex) then
				maxAngle = angle
				maxAngleIndex = (i - 1) % numPositions + 1
			end
		end
	end
	return maxAngle, maxAngleIndex
end
function FieldCourseBoundary.splitBoundarySegment(positions, splitAngle)
	local maxAngle, maxAngleIndex = FieldCourseBoundary.getSegmentAngle(positions, nil, false)
	if maxAngleIndex ~= -1 and splitAngle < maxAngle then
		local numPositions = #positions
		local segment1 = {}
		for i = 1, maxAngleIndex do
			local pos = positions[i]
			if i == maxAngleIndex then
				pos = table.clone(pos)
			end
			table.insert(segment1, pos)
		end
		local segment2 = {}
		for i = maxAngleIndex, numPositions do
			table.insert(segment2, positions[i])
		end
		return segment1, segment2
	end
	return positions, nil
end
function FieldCourseBoundary.splitBoundarySegments(segments, splitAngle)
	local segmentsSplit = false
	for i = #segments, 1, -1 do
		local segment = segments[i]
		local segment1, segment2 = FieldCourseBoundary.splitBoundarySegment(segment, splitAngle)
		if segment2 == nil then
			continue
		end
		table.remove(segments, i)
		table.insert(segments, i, segment2)
		table.insert(segments, i, segment1)
		segmentsSplit = true
	end
	return segmentsSplit
end
function FieldCourseBoundary.splitBoundary(positions, splitAngle)
	positions = table.clone(positions, math.huge)
	table.remove(positions, #positions)
	local _, maxAngleIndex1 = FieldCourseBoundary.getSegmentAngle(positions, nil, true)
	local _, maxAngleIndex2 = FieldCourseBoundary.getSegmentAngle(positions, maxAngleIndex1, true)
	if maxAngleIndex1 == -1 or maxAngleIndex2 == -1 then
		return nil
	end
	if maxAngleIndex2 < maxAngleIndex1 then
		maxAngleIndex2 = maxAngleIndex1
		maxAngleIndex1 = maxAngleIndex2
	end
	local segments = {}
	local numPositions = #positions
	local segment1 = {}
	for i = maxAngleIndex1, maxAngleIndex2 do
		local pos = positions[(i - 1) % numPositions + 1]
		if (i - 1) % numPositions + 1 == maxAngleIndex2 then
			pos = table.clone(pos)
		end
		table.insert(segment1, pos)
	end
	table.insert(segments, segment1)
	local segment2 = {}
	for i = maxAngleIndex2, numPositions + maxAngleIndex1 do
		local pos = positions[(i - 1) % numPositions + 1]
		if (i - 1) % numPositions + 1 == maxAngleIndex1 then
			pos = table.clone(pos)
		end
		table.insert(segment2, pos)
	end
	table.insert(segments, segment2)
	while FieldCourseBoundary.splitBoundarySegments(segments, splitAngle) do
	end
	return segments
end
function FieldCourseBoundary.extendBoundaryLine(boundaryLine, offset)
	local boundary = FieldCourseBoundary.createByBoundaryLine(boundaryLine, nil)
	if boundary ~= nil then
		boundary = boundary:extend(offset)
		if boundary ~= nil then
			return boundary.boundaryLine
		end
	end
	return nil
end
