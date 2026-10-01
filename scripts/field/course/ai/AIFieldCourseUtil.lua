AIFieldCourseUtil = {}
function AIFieldCourseUtil.getSegmentPosition(startPosition, segment, direction, offset)
	if not startPosition then
		direction = -direction
	end
	offset = offset or 0
	if 0 <= direction then
		return segment.positions[1 + offset][1], segment.positions[1 + offset][2]
	else
		local numPositions = #segment.positions
		return segment.positions[numPositions - offset][1], segment.positions[numPositions - offset][2]
	end
end
function AIFieldCourseUtil.getSegmentPositionAndDirection(startPosition, segment, direction, offset, limitToOneSegment)
	offset = offset or 0
	if not startPosition then
		direction = -direction
	end
	local drivingDirection = 1
	if startPosition then
		drivingDirection = -1
	end
	if 0 <= direction then
		local x = segment.positions[1][1]
		local z = segment.positions[1][2]
		local dirX, dirZ = MathUtil.vector2Normalize(segment.positions[1][1] - segment.positions[2][1], segment.positions[1][2] - segment.positions[2][2])
		if offset ~= 0 then
			x, z, dirX, dirZ = AIFieldCourseUtil.getSegmentPositionOffset(segment, -direction, -offset, limitToOneSegment)
		end
		return x, z, dirX * drivingDirection, dirZ * drivingDirection
	else
		local numPositions = #segment.positions
		local x = segment.positions[numPositions][1]
		local z = segment.positions[numPositions][2]
		local dirX, dirZ = MathUtil.vector2Normalize(segment.positions[numPositions][1] - segment.positions[numPositions - 1][1], segment.positions[numPositions][2] - segment.positions[numPositions - 1][2])
		if offset ~= 0 then
			x, z, dirX, dirZ = AIFieldCourseUtil.getSegmentPositionOffset(segment, -direction, -offset, limitToOneSegment)
		end
		return x, z, dirX * drivingDirection, dirZ * drivingDirection
	end
end
function AIFieldCourseUtil.getSegmentPositionOffset(segment, direction, offset, limitToOneSegment)
	if 0 < direction then
		local indexOffset = 0
		while true do
			local p1 = segment.positions[#segment.positions - indexOffset - 1]
			local p2 = segment.positions[#segment.positions - indexOffset]
			local dirX = nil
			local dirZ = nil
			local length = nil
			if p1 == nil then
				break
			end
			dirX = p2[1] - p1[1]
			dirZ = p2[2] - p1[2]
			length = MathUtil.vector2Length(dirX, dirZ)
			dirX = dirX / length
			dirZ = dirZ / length
			if offset >= 0 then
				return p2[1] + dirX * offset, p2[2] + dirZ * offset, dirX, dirZ
			elseif length >= -offset then
				return p2[1] + dirX * offset, p2[2] + dirZ * offset, dirX, dirZ
			else
				if limitToOneSegment ~= true and p1 ~= nil then
					offset = offset + length
					indexOffset = indexOffset + 1
					continue
				end
				if limitToOneSegment == true then
					offset = length * math.sign(offset)
				end
				return p2[1] + dirX * offset, p2[2] + dirZ * offset, dirX, dirZ
			end
		end
		local p3 = segment.positions[#segment.positions - indexOffset + 1]
		dirX = p3[1] - p2[1]
		dirZ = p3[2] - p2[2]
		length = MathUtil.vector2Length(dirX, dirZ)
		dirX = dirX / length
		dirZ = dirZ / length
	else
		local indexOffset = 0
		while true do
			local p1 = segment.positions[indexOffset + 1]
			local p2 = segment.positions[indexOffset + 2]
			local dirX = nil
			local dirZ = nil
			local length = nil
			if p2 == nil then
				break
			end
			dirX = p1[1] - p2[1]
			dirZ = p1[2] - p2[2]
			length = MathUtil.vector2Length(dirX, dirZ)
			dirX = dirX / length
			dirZ = dirZ / length
			if offset >= 0 then
				return p1[1] + dirX * offset, p1[2] + dirZ * offset, dirX, dirZ
			elseif length >= -offset then
				return p1[1] + dirX * offset, p1[2] + dirZ * offset, dirX, dirZ
			else
				if limitToOneSegment ~= true and p2 ~= nil then
					offset = offset + length
					indexOffset = indexOffset + 1
					continue
				end
				if limitToOneSegment == true then
					offset = length * math.sign(offset)
				end
				return p1[1] + dirX * offset, p1[2] + dirZ * offset, dirX, dirZ
			end
		end
		local p3 = segment.positions[indexOffset]
		dirX = p3[1] - p1[1]
		dirZ = p3[2] - p1[2]
		length = MathUtil.vector2Length(dirX, dirZ)
		dirX = dirX / length
		dirZ = dirZ / length
	end
end
function AIFieldCourseUtil.getSegmentSideOffset(segment, x, z, extendSegment)
	if segment == nil then
		return math.huge, -1
	else
		local numPositions = #segment.positions
		local minDistance = math.huge
		local minDistanceIndex = -1
		for i = 1, numPositions - 1 do
			local x2 = segment.positions[i][1]
			local z2 = segment.positions[i][2]
			local x3 = segment.positions[i + 1][1]
			local z3 = segment.positions[i + 1][2]
			local dirX = x3 - x2
			local dirZ = z3 - z2
			local length = MathUtil.vector2Length(dirX, dirZ)
			dirX = dirX / length
			dirZ = dirZ / length
			local dot = MathUtil.getProjectOnLineParameter(x, z, x2, z2, dirX, dirZ)
			if 0 <= dot then
				if dot <= length then
					local hitX = x2 + dirX * dot
					local hitZ = z2 + dirZ * dot
					local distance = MathUtil.vector2Length(hitX - x, hitZ - z)
					if distance < minDistance then
						minDistance = distance
						minDistanceIndex = i
					end
				else
					local distance = MathUtil.vector2Length(x2 - x, z2 - z)
					if distance < minDistance then
						minDistance = distance
						minDistanceIndex = i
					end
					distance = MathUtil.vector2Length(x3 - x, z3 - z)
					if distance < minDistance then
						minDistance = distance
						minDistanceIndex = i
					end
				end
			end
		end
		if minDistanceIndex < 0 and extendSegment ~= false then
			local x2 = segment.positions[1][1]
			local z2 = segment.positions[1][2]
			local x3 = segment.positions[2][1]
			local z3 = segment.positions[2][2]
			local dirX = x3 - x2
			local dirZ = z3 - z2
			local length = MathUtil.vector2Length(dirX, dirZ)
			dirX = dirX / length
			dirZ = dirZ / length
			local dot = MathUtil.getProjectOnLineParameter(x, z, x2, z2, dirX, dirZ)
			if dot <= length then
				local hitX = x2 + dirX * dot
				local hitZ = z2 + dirZ * dot
				local distance = MathUtil.vector2Length(hitX - x, hitZ - z)
				if distance < minDistance then
					minDistance = distance
					minDistanceIndex = 1
				end
			end
			x2 = segment.positions[numPositions - 1][1]
			z2 = segment.positions[numPositions - 1][2]
			x3 = segment.positions[numPositions][1]
			z3 = segment.positions[numPositions][2]
			dirX = x3 - x2
			dirZ = z3 - z2
			length = MathUtil.vector2Length(dirX, dirZ)
			dirX = dirX / length
			dirZ = dirZ / length
			dot = MathUtil.getProjectOnLineParameter(x, z, x2, z2, dirX, dirZ)
			if 0 < dot then
				local hitX = x2 + dirX * dot
				local hitZ = z2 + dirZ * dot
				local distance = MathUtil.vector2Length(hitX - x, hitZ - z)
				if distance < minDistance then
					minDistance = distance
					minDistanceIndex = numPositions - 1
				end
			end
		end
		return minDistance, minDistanceIndex
	end
end
function AIFieldCourseUtil.cutSegmentByDistance(segment, direction, distance)
	local numPositions = #segment.positions
	if 0 < direction then
		for i = 1, numPositions - 1 do
			local x1 = segment.positions[i][1]
			local z1 = segment.positions[i][2]
			local x2 = segment.positions[i + 1][1]
			local z2 = segment.positions[i + 1][2]
			local dx = x2 - x1
			local dz = z2 - z1
			local length = MathUtil.vector2Length(dx, dz)
			if distance < length then
				local dirX = dx / length
				local dirZ = dz / length
				local x = x1 + dirX * distance
				local z = z1 + dirZ * distance
				segment.positions[i][1] = x
				segment.positions[i][2] = z
				for indexToRemove = 1, i - 1 do
					table.remove(segment.positions, 1)
				end
				return true
			else
				distance = distance - length
			end
		end
		return false
	else
		for i = numPositions, 2, -1 do
			local x1 = segment.positions[i][1]
			local z1 = segment.positions[i][2]
			local x2 = segment.positions[i - 1][1]
			local z2 = segment.positions[i - 1][2]
			local dx = x2 - x1
			local dz = z2 - z1
			local length = MathUtil.vector2Length(dx, dz)
			if distance < length then
				local dirX = dx / length
				local dirZ = dz / length
				local x = x1 + dirX * distance
				local z = z1 + dirZ * distance
				segment.positions[i][1] = x
				segment.positions[i][2] = z
				for indexToRemove = numPositions, i + 1, -1 do
					table.remove(segment.positions)
				end
				return true
			else
				distance = distance - length
			end
		end
		return false
	end
end
function AIFieldCourseUtil.drawPath(positions, r, g, b, limitedPositionIndex, indexToDraw, yOffset, drawArrows)
	yOffset = yOffset or 0.25
	local fullLength = FieldCourseUtil.getSegmentLength(positions)
	local length = 0
	for i = 1, #positions - 1 do
		if limitedPositionIndex == nil or limitedPositionIndex == 0 or i == limitedPositionIndex then
			local x1 = positions[i][1]
			local z1 = positions[i][2]
			local x2 = positions[i + 1][1]
			local z2 = positions[i + 1][2]
			local direction = positions[i + 1][3] or 1
			local y1 = getTerrainHeightAtWorldPos(g_terrainNode, x1, 0, z1) + yOffset
			local y2 = getTerrainHeightAtWorldPos(g_terrainNode, x2, 0, z2) + yOffset
			if direction < 0 then
				drawDebugLine(x1, y1 + 0.01, z1, 1, 0, 0, x2, y2 + 0.01, z2, 1, 0, 0, false)
				drawDebugPoint(x1, y1 + 0.01, z1, 1, 0, 0, 1, false)
				drawDebugPoint(x2, y2 + 0.01, z2, 1, 0, 0, 1, false)
			else
				drawDebugLine(x1, y1, z1, r, g, b, x2, y2, z2, r, g, b, false)
				drawDebugPoint(x1, y1, z1, r, g, b, 1, false)
				drawDebugPoint(x2, y2, z2, r, g, b, 1, false)
			end
			if indexToDraw ~= nil and i == 1 then
				local tx = (x1 + x2) * 0.5
				local tz = (z1 + z2) * 0.5
				local ty = getTerrainHeightAtWorldPos(g_terrainNode, tx, 0, tz) + yOffset
				Utils.renderTextAtWorldPosition(tx, ty, tz, tostring(indexToDraw), 0.02, 0, r, g, b, 1)
			end
			if drawArrows ~= false then
				local segmentLength = MathUtil.vector2Length(x2 - x1, z2 - z1)
				if 0 < segmentLength then
					local dx, dz = MathUtil.vector2Normalize(x2 - x1, z2 - z1)
					local numArrows = math.min(math.floor(segmentLength / math.min(0.9, segmentLength)), 10)
					for j = 1, numArrows do
						local offset = (j - 1) * segmentLength / numArrows
						local alpha = (length + offset) / fullLength
						local sx = x1 + dx * offset
						local sz = z1 + dz * offset
						local y = getTerrainHeightAtWorldPos(g_terrainNode, sx, 0, sz) + yOffset
						drawDebugTriangle(sx + dz * 0.25, y, sz - dx * 0.25, sx - dz * 0.25, y, sz + dx * 0.25, sx + dx * 0.5, y, sz + dz * 0.5, alpha, 1 - alpha, 0, 0.3, true)
					end
					length = length + segmentLength
				end
			end
		end
	end
end
function AIFieldCourseUtil.drawPathArea(positions, r, g, b, a, width)
	width = width * 0.5
	for i = 1, #positions - 1 do
		local x1 = positions[i][1]
		local z1 = positions[i][2]
		local x2 = positions[i + 1][1]
		local z2 = positions[i + 1][2]
		local y1 = getTerrainHeightAtWorldPos(g_terrainNode, x1, 0, z1) + 0.25
		local y2 = getTerrainHeightAtWorldPos(g_terrainNode, x2, 0, z2) + 0.25
		local dx, dz = MathUtil.vector2Normalize(x2 - x1, z2 - z1)
		drawDebugTriangle(x1 + dz * width, y1, z1 - dx * width, x1 - dz * width, y1, z1 + dx * width, x2 + dz * width, y2, z2 - dx * width, r, g, b, a, true)
		drawDebugTriangle(x1 - dz * width, y1, z1 + dx * width, x2 - dz * width, y2, z2 + dx * width, x2 + dz * width, y2, z2 - dx * width, r, g, b, a, true)
	end
end
function AIFieldCourseUtil.extendHeadlandSegment(segments, segmentIndex, direction, adjustDirection, implementWidth, boundaryLine, applyChanges, lockDirection)
	if applyChanges == nil then
		applyChanges = true
	end
	local segment = segments[segmentIndex]
	local drivingDirection = direction
	local nextSegment = segments[segmentIndex + direction]
	if nextSegment ~= nil and (segment.isHeadlandSegment ~= nextSegment.isHeadlandSegment or segment.headlandIndex ~= nextSegment.headlandIndex or segment.isIslandSegment ~= nextSegment.isIslandSegment or segment.islandIndex ~= nextSegment.islandIndex) then
		nextSegment = nil
	end
	if nextSegment == nil then
		local min = 1
		local max = segmentIndex
		local step = direction
		if direction < 0 then
			min = #segments
			max = segmentIndex
			step = direction
		end
		for i = min, max, step do
			local segmentToCheck = segments[i]
			if segment.isHeadlandSegment == segmentToCheck.isHeadlandSegment and (segment.headlandIndex == segmentToCheck.headlandIndex and (segment.isIslandSegment == segmentToCheck.isIslandSegment and segment.islandIndex == segmentToCheck.islandIndex)) then
				nextSegment = segmentToCheck
				break
			end
		end
	end
	if nextSegment ~= nil then
		if adjustDirection < 0 then
			nextSegment = segment
			segment = nextSegment
			direction = -direction
		end
		local numPositions = #segment.positions
		local pos1 = segment.positions[numPositions - 1]
		local pos2 = segment.positions[numPositions]
		local pos3 = nextSegment.positions[1]
		local pos4 = nextSegment.positions[2]
		if direction < 0 then
			pos1 = segment.positions[2]
			pos2 = segment.positions[1]
			numPositions = #nextSegment.positions
			pos3 = nextSegment.positions[numPositions]
			pos4 = nextSegment.positions[numPositions - 1]
		end
		local x1 = pos1[1]
		local z1 = pos1[2]
		local x2 = pos2[1]
		local z2 = pos2[2]
		local x3 = pos3[1]
		local z3 = pos3[2]
		local x4 = pos4[1]
		local z4 = pos4[2]
		local dx1, dz1 = MathUtil.vector2Normalize(x2 - x1, z2 - z1)
		local dx2, dz2 = MathUtil.vector2Normalize(x3 - x4, z3 - z4)
		local yRot1 = MathUtil.getYRotationFromDirection(dx1, dz1)
		local yRot2 = MathUtil.getYRotationFromDirection(dx2, dz2)
		local rotationOffset = yRot1 - yRot2
		if 3.141592653589793 < rotationOffset then
			rotationOffset = rotationOffset - 6.283185307179586
		elseif rotationOffset < -3.141592653589793 then
			rotationOffset = rotationOffset + 6.283185307179586
		end
		local halfWidth = implementWidth * 0.5
		local offset = implementWidth * 5
		local lineLength = offset * 2
		local intersection = function(dir, side1, side2)
			local sx = nil
			local sz = nil
			local ex = nil
			local ez = nil
			local sdx = nil
			local sdz = nil
			local edx = nil
			local edz = nil
			if 0 < dir then
				sx = x2 - dx1 * offset + dz1 * halfWidth * side1
				sz = z2 - dz1 * offset - dx1 * halfWidth * side1
				sdx = dx1
				sdz = dz1
				ex = x3 - dx2 * offset + dz2 * halfWidth * side2
				ez = z3 - dz2 * offset - dx2 * halfWidth * side2
				edx = dx2
				edz = dz2
			else
				sx = x3 - dx2 * offset + dz2 * halfWidth * side1
				sz = z3 - dz2 * offset - dx2 * halfWidth * side1
				sdx = dx2
				sdz = dz2
				ex = x2 - dx1 * offset + dz1 * halfWidth * side2
				ez = z2 - dz1 * offset - dx1 * halfWidth * side2
				edx = dx1
				edz = dz1
			end
			local intersect, px, pz = MathUtil.getLineSegmentsIntersection(sx, sz, sx + sdx * lineLength, sz + sdz * lineLength, ex, ez, ex + edx * lineLength, ez + edz * lineLength)
			if intersect then
				return MathUtil.vector2Length(px - sx, pz - sz) - offset, px, pz
			else
				return nil, nil, nil
			end
		end
		if MathUtil.vector2Length(x3 - x2, z3 - z2) < 0.01 then
			local side2 = (rotationOffset < 0 and 1 or -1) * direction
			local distance1, _, _ = intersection(direction, 1, side2)
			local distance2, _, _ = intersection(direction, -1, side2)
			if distance1 ~= nil and distance2 ~= nil then
				local maxDistance = math.max(distance1, distance2)
				local segmentLength = MathUtil.vector2Length(pos4[1] - pos3[1], pos4[2] - pos3[2])
				maxDistance = math.min(math.abs(maxDistance), segmentLength - 0.01) * math.sign(maxDistance)
				if applyChanges then
					pos3[1] = x3 + dx2 * maxDistance
					pos3[2] = z3 + dz2 * maxDistance
				end
			end
			distance1, _, _ = intersection(-direction, 1, side2)
			distance2, _, _ = intersection(-direction, -1, side2)
			if distance1 ~= nil and distance2 ~= nil then
				local maxDistance = math.max(distance1, distance2)
				if 1.5707963267948966 < math.abs(rotationOffset) then
					local ox1 = pos3[1] + dz2 * halfWidth
					local oz1 = pos3[2] - dx2 * halfWidth
					local ox2 = pos3[1] - dz2 * halfWidth
					local oz2 = pos3[2] + dx2 * halfWidth
					local dot1 = MathUtil.getProjectOnLineParameter(ox1, oz1, x2, z2, dx1, dz1)
					local dot2 = MathUtil.getProjectOnLineParameter(ox2, oz2, x2, z2, dx1, dz1)
					maxDistance = math.min(math.max(dot1, dot2), maxDistance)
				else
					local maxIntersectOffset = 0
					local sx = pos2[1]
					local sz = pos2[2]
					local intersect, ix, iz, _, _, _, _ = FieldCourseUtil.getSegmentClosestBoundaryIntersection(sx, sz, sx + dx1 * maxDistance, sz + dz1 * maxDistance, boundaryLine)
					if intersect then
						local distance = MathUtil.vector2Length(sx - ix, iz - sz)
						maxIntersectOffset = math.max(maxIntersectOffset, distance)
						local sideOffset = halfWidth - 0.01
						sx = pos2[1] + dz1 * sideOffset
						sz = pos2[2] - dx1 * sideOffset
						intersect, ix, iz, _, _, _, _ = FieldCourseUtil.getSegmentClosestBoundaryIntersection(sx, sz, sx + dx1 * maxDistance, sz + dz1 * maxDistance, boundaryLine)
						if intersect then
							distance = MathUtil.vector2Length(sx - ix, iz - sz)
							maxIntersectOffset = math.max(maxIntersectOffset, distance)
						end
						sx = pos2[1] - dz1 * sideOffset
						sz = pos2[2] + dx1 * sideOffset
						intersect, ix, iz, _, _, _, _ = FieldCourseUtil.getSegmentClosestBoundaryIntersection(sx, sz, sx + dx1 * maxDistance, sz + dz1 * maxDistance, boundaryLine)
						if intersect then
							distance = MathUtil.vector2Length(sx - ix, iz - sz)
							maxIntersectOffset = math.max(maxIntersectOffset, distance)
						end
						maxDistance = math.min(maxDistance, maxIntersectOffset)
					end
				end
				if applyChanges then
					pos2[1] = x2 + dx1 * maxDistance
					pos2[2] = z2 + dz1 * maxDistance
				else
					return x2 + dx1 * maxDistance, z2 + dz1 * maxDistance
				end
			end
			if applyChanges then
				segment.length = FieldCourseUtil.getSegmentLength(segment.positions)
				nextSegment.length = FieldCourseUtil.getSegmentLength(nextSegment.positions)
				if segment.lockedDirection == nil then
					segment.lockedDirection = lockDirection or drivingDirection
				end
				if nextSegment.lockedDirection == nil then
					nextSegment.lockedDirection = lockDirection or drivingDirection
				end
			end
		end
	end
	return nil, nil
end
function AIFieldCourseUtil.getClosestPositionOnSegment(positions, x, z)
	local numPositions = #positions
	local minDistance = math.huge
	local minDistanceIndex = -1
	local minDistanceX = 0
	local minDistanceZ = 0
	for i = 1, numPositions - 1 do
		local x2 = positions[i][1]
		local z2 = positions[i][2]
		local x3 = positions[i + 1][1]
		local z3 = positions[i + 1][2]
		local dirX = x3 - x2
		local dirZ = z3 - z2
		local length = MathUtil.vector2Length(dirX, dirZ)
		dirX = dirX / length
		dirZ = dirZ / length
		local dot = MathUtil.getProjectOnLineParameter(x, z, x2, z2, dirX, dirZ)
		if 0 <= dot and dot <= length then
			local hitX = x2 + dirX * dot
			local hitZ = z2 + dirZ * dot
			local distance = MathUtil.vector2Length(hitX - x, hitZ - z)
			if distance < minDistance then
				minDistance = distance
				minDistanceIndex = i
				minDistanceX = hitX
				minDistanceZ = hitZ
			end
		end
	end
	for i = 1, numPositions do
		local px = positions[i][1]
		local pz = positions[i][2]
		local distance = MathUtil.vector2Length(px - x, pz - z)
		if distance < minDistance then
			minDistance = distance
			minDistanceIndex = i
			minDistanceX = px
			minDistanceZ = pz
		end
	end
	return minDistanceX, minDistanceZ, minDistance, minDistanceIndex
end
function AIFieldCourseUtil.getSegmentToSegmentDistance(segment1, segment2)
	local distance = math.huge
	for i = 1, #segment1.positions - 1 do
		local x1 = segment1.positions[i][1]
		local z1 = segment1.positions[i][2]
		local x2 = segment1.positions[i + 1][1]
		local z2 = segment1.positions[i + 1][2]
		local cx = (x1 + x2) * 0.5
		local cz = (z1 + z2) * 0.5
		local sx, sz = AIFieldCourseUtil.getClosestPositionOnSegment(segment2.positions, cx, cz)
		distance = math.min(distance, MathUtil.vector2Length(sx - cx, sz - cz))
	end
	return distance
end
