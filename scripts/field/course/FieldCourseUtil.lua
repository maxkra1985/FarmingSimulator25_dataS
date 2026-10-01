FieldCourseUtil = {}
function FieldCourseUtil.douglasPeucker(points, minDistance)
	local numPoints = #points
	if numPoints <= 2 then
		return
	end
	local isLoop = false
	if points[1][1] == points[numPoints][1] and points[1][2] == points[numPoints][2] then
		table.remove(points, numPoints)
		isLoop = true
		numPoints = numPoints - 1
	end
	local getMaxDistancePoint = function(startIndex, endIndex)
		if endIndex - startIndex <= 1 then
			return 0, -1
		end
		local firstPoint = points[(startIndex - 1) % #points + 1]
		local lastPoint = points[(endIndex - 1) % #points + 1]
		local lineDirX = lastPoint[1] - firstPoint[1]
		local lineDirZ = lastPoint[2] - firstPoint[2]
		local lineLength = MathUtil.vector2Length(lineDirX, lineDirZ)
		if 0 < lineLength then
			lineDirX = lineDirX / lineLength
			lineDirZ = lineDirZ / lineLength
			local maxLength = -1
			local maxLengthPoint = 0
			for i = startIndex + 1, endIndex - 1 do
				local p = points[(i - 1) % #points + 1]
				local px = p[1]
				local pz = p[2]
				local lx, lz = MathUtil.projectOnLine(px, pz, firstPoint[1], firstPoint[2], lineDirX, lineDirZ)
				local length = MathUtil.vector2Length(px - lx, pz - lz)
				if maxLength < length then
					maxLength = length
					maxLengthPoint = i
				end
			end
			return maxLengthPoint, maxLength
		else
			return 0, -1
		end
	end
	local function douglasPeuckerRec(startIndex, endIndex)
		local maxDistancePoint, maxDistance = getMaxDistancePoint(startIndex, endIndex)
		if minDistance < maxDistance then
			if 0 < maxDistancePoint - startIndex then
				douglasPeuckerRec(startIndex, maxDistancePoint)
			end
			if 0 < endIndex - maxDistancePoint then
				douglasPeuckerRec(maxDistancePoint, endIndex)
			end
		elseif maxDistance ~= -1 then
			for i = startIndex + 1, endIndex - 1 do
				points[(i - 1) % #points + 1].valid = false
			end
		end
	end
	if isLoop then
		douglasPeuckerRec(1, numPoints - 1)
		for i = numPoints, 1, -1 do
			if points[i].valid == false then
				table.remove(points, i)
			end
		end
		numPoints = #points
		douglasPeuckerRec(math.floor(numPoints * 0.5) + 1, numPoints + math.floor(numPoints * 0.5))
		for i = numPoints, 1, -1 do
			if points[i].valid == false then
				table.remove(points, i)
			end
		end
		table.insert(points, { points[1][1], points[1][2] })
	else
		douglasPeuckerRec(1, numPoints)
		for i = numPoints, 1, -1 do
			if points[i].valid == false then
				table.remove(points, i)
			end
		end
	end
end
function FieldCourseUtil.visvalingamWhyattSimplification(positions, areaThreshold)
	local minIndex = -1
	local minArea = math.huge
	for i = 1, #positions - 2 do
		local p1 = positions[i]
		local p2 = positions[i + 1]
		local p3 = positions[i + 2]
		local a = MathUtil.vector2Length(p2[1] - p1[1], p2[2] - p1[2])
		local b = MathUtil.vector2Length(p3[1] - p1[1], p3[2] - p1[2])
		local c = MathUtil.vector2Length(p3[1] - p2[1], p3[2] - p2[2])
		local area = 0.25 * math.sqrt((a ^ 2 + b ^ 2 + c ^ 2) ^ 2 - 2 * (a ^ 4 + b ^ 4 + c ^ 4))
		if area < areaThreshold and area < minArea then
			minArea = area
			minIndex = i + 1
		end
	end
	while 0 < minIndex do
		table.remove(positions, minIndex)
	end
end
function FieldCourseUtil.langSimplification(positions, maxOffset, regionSize)
	local index = 1
	local curRegionSize = regionSize
	while true do
		curRegionSize = math.min(curRegionSize, #positions - index)
		local startPos = positions[index]
		local endPos = positions[index + curRegionSize]
		if startPos == nil or endPos == nil then
			break
		end
		local lx = startPos[1]
		local lz = startPos[2]
		local lineDirX, lineDirZ = MathUtil.vector2Normalize(endPos[1], endPos[2])
		local greaterThanOffset = false
		for i = index, index + curRegionSize - 1 do
			local p = positions[i]
			local plx, plz = MathUtil.projectOnLine(p[1], p[2], lx, lz, lineDirX, lineDirZ)
			local length = MathUtil.vector2Length(p[1] - plx, p[2] - plz)
			if maxOffset < length then
				greaterThanOffset = true
				break
			end
		end
		if greaterThanOffset then
			curRegionSize = curRegionSize - 1
		else
			for i = index + curRegionSize - 1, index, -1 do
				table.remove(positions, i)
			end
			index = index + 1
			curRegionSize = regionSize
		end
	end
	local numPositions = #positions
	if positions[1][1] ~= positions[numPositions][1] or positions[1][2] ~= positions[numPositions][2] then
		table.insert(positions, table.clone(positions[1], 1))
	end
end
function FieldCourseUtil.pointAveragePositions(positions)
	local numPositions = #positions
	if numPositions == 0 then
		return
	else
		for i = 1, numPositions - 1 do
			local p1 = positions[i]
			local p2 = positions[i + 1]
			p1[1] = (p1[1] + p2[1]) * 0.5
			p1[2] = (p1[2] + p2[2]) * 0.5
		end
		local lastPosition = positions[numPositions]
		lastPosition[1] = positions[1][1]
		lastPosition[2] = positions[1][2]
	end
end
function FieldCourseUtil.vector2Dot(x1, z1, x2, z2)
	return x1 * x2 + z1 * z2
end
function FieldCourseUtil.semiConvexSimplification(positions, maxDistance, direction)
	local numPositions = #positions
	local index1 = 1
	while index1 < numPositions - 1 do
		local maxAngle = 0
		local maxAngleIndex = -1
		for distance = 1, maxDistance do
			local index2 = index1 + distance
			if numPositions < index2 then
				break
			end
			local p1 = positions[index1]
			local p1_2 = positions[index1 + 1]
			local p2 = positions[index2]
			local bDirX = p1_2[1] - p1[1]
			local bDirZ = p1_2[2] - p1[2]
			local bLength = MathUtil.vector2Length(bDirX, bDirZ)
			if 0 < bLength then
				bDirX = bDirX / bLength
				bDirZ = bDirZ / bLength
				local dirX = p2[1] - p1[1]
				local dirZ = p2[2] - p1[2]
				local length = MathUtil.vector2Length(dirX, dirZ)
				if 0 < length then
					dirX = dirX / length
					dirZ = dirZ / length
					if FieldCourseUtil.vector2Dot(dirX, dirZ, -bDirZ, bDirX) < 0 then
						local angle = math.acos(FieldCourseUtil.vector2Dot(dirX, dirZ, bDirX, bDirZ))
						if maxAngle < angle then
							maxAngle = angle
							maxAngleIndex = index2
						end
					end
				end
			end
		end
		if 0 < maxAngleIndex then
			local startIndex = math.max(index1 - 1, 1)
			local p1 = positions[startIndex]
			local p2 = positions[startIndex + 1]
			local p3 = positions[math.min(maxAngleIndex, numPositions - 1)]
			local p4 = positions[math.min(maxAngleIndex + 1, numPositions)]
			local dirX1 = p2[1] - p1[1]
			local dirZ1 = p2[2] - p1[2]
			local length1 = MathUtil.vector2Length(dirX1, dirZ1)
			if 0 < length1 then
				dirX1 = dirX1 / length1
				dirZ1 = dirZ1 / length1
				local dirX2 = p4[1] - p3[1]
				local dirZ2 = p4[2] - p3[2]
				local length2 = MathUtil.vector2Length(dirX2, dirZ2)
				if 0 < length2 then
					dirX2 = dirX2 / length2
					dirZ2 = dirZ2 / length2
					if math.acos(FieldCourseUtil.vector2Dot(dirX1, dirZ1, dirX2, dirZ2)) < 0.7853981633974483 then
						for i = index1 + 1, maxAngleIndex - 1 do
							positions[i].invalid = true
						end
						index1 = maxAngleIndex - 1
					end
				end
			end
		end
		index1 = index1 + 1
	end
	for i = numPositions, 1, -1 do
		if positions[i].invalid then
			table.remove(positions, i)
		end
	end
end
function FieldCourseUtil.getLineSegmentsIntersection(ax1, az1, ax2, az2, bx1, bz1, bx2, bz2)
	local denominator = (bz2 - bz1) * (ax2 - ax1) - (bx2 - bx1) * (az2 - az1)
	if denominator ~= 0 then
		local uA = ((bx2 - bx1) * (az1 - bz1) - (bz2 - bz1) * (ax1 - bx1)) / denominator
		local uB = ((ax2 - ax1) * (az1 - bz1) - (az2 - az1) * (ax1 - bx1)) / denominator
		if 0 < uA and (uA < 1 and (0 < uB and uB < 1)) then
			local x = ax1 + uA * (ax2 - ax1)
			local z = az1 + uA * (az2 - az1)
			return true, x, z
		end
	end
	local dirX = ax2 - ax1
	local dirZ = az2 - az1
	local length = MathUtil.vector2Length(dirX, dirZ)
	dirX = dirX / length
	dirZ = dirZ / length
	local dot = MathUtil.getProjectOnLineParameter(bx1, bz1, ax1, az1, dirX, dirZ)
	if 0 < dot and dot < length then
		local ix = ax1 + dirX * dot
		local iz = az1 + dirZ * dot
		if MathUtil.vector2Length(ix - bx1, iz - bz1) == 0 then
			return true, ix, iz
		end
	end
	dot = MathUtil.getProjectOnLineParameter(bx2, bz2, ax1, az1, dirX, dirZ)
	if 0 < dot and dot < length then
		local ix = ax1 + dirX * dot
		local iz = az1 + dirZ * dot
		if MathUtil.vector2Length(ix - bx2, iz - bz2) == 0 then
			return true, ix, iz
		end
	end
	return false, 0, 0
end
function FieldCourseUtil.getIsPointInsideBoundary(x, z, boundary)
	local intersectCount = 0
	for i = 1, #boundary - 1 do
		local x2 = boundary[i][1]
		local z2 = boundary[i][2]
		local x3 = boundary[i + 1][1]
		local z3 = boundary[i + 1][2]
		if z == z2 or z == z3 then
			z = z + 0.00001
		end
		if MathUtil.getLineSegmentsIntersection(x, z, x + 65535, z, x2, z2, x3, z3) then
			intersectCount = intersectCount + 1
		end
	end
	return intersectCount % 2 ~= 0, intersectCount
end
function FieldCourseUtil.getDistanceToBoundary(x, z, boundary)
	local minDistance = math.huge
	local minDistanceIndex = -1
	for i = 1, #boundary - 1 do
		local x2 = boundary[i][1]
		local z2 = boundary[i][2]
		local x3 = boundary[i + 1][1]
		local z3 = boundary[i + 1][2]
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
	return minDistance, minDistanceIndex
end
function FieldCourseUtil.getPositionSegmentOverlap(x, z, segment, maxDistance)
	for i = 1, #segment - 1 do
		local x2 = segment[i][1]
		local z2 = segment[i][2]
		local x3 = segment[i + 1][1]
		local z3 = segment[i + 1][2]
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
			if distance < maxDistance then
				return true
			end
		end
		local distance = MathUtil.vector2Length(x2 - x, z2 - z)
		if distance < maxDistance then
			return true
		end
		if distance < maxDistance then
			return true
		end
	end
	return false
end
function FieldCourseUtil.getDistanceToSegment(sx1, sz1, sx2, sz2, x, z)
	local dirX = sx2 - sx1
	local dirZ = sz2 - sz1
	local length = MathUtil.vector2Length(dirX, dirZ)
	dirX = dirX / length
	dirZ = dirZ / length
	local dot = MathUtil.getProjectOnLineParameter(x, z, sx1, sz1, dirX, dirZ)
	if 0 <= dot and dot <= length then
		local hitX = sx1 + dirX * dot
		local hitZ = sz1 + dirZ * dot
		return MathUtil.vector2Length(hitX - x, hitZ - z)
	end
	local sDistance = MathUtil.vector2Length(sx1 - x, sz1 - z)
	local eDistance = MathUtil.vector2Length(sx2 - x, sz2 - z)
	return math.min(sDistance, eDistance)
end
function FieldCourseUtil.getAreParallelSegmentsNextToEachOther(sx1, sz1, ex1, ez1, sx2, sz2, ex2, ez2)
	local dirX = ex1 - sx1
	local dirZ = ez1 - sz1
	local length = MathUtil.vector2Length(dirX, dirZ)
	dirX = dirX / length
	dirZ = dirZ / length
	local dot = MathUtil.getProjectOnLineParameter(sx2, sz2, sx1, sz1, dirX, dirZ)
	if 0 <= dot and dot <= length then
		return true
	end
	dot = MathUtil.getProjectOnLineParameter(ex2, ez2, sx1, sz1, dirX, dirZ)
	if 0 <= dot and dot <= length then
		return true
	end
	dirX = ex2 - sx2
	dirZ = ez2 - sz2
	length = MathUtil.vector2Length(dirX, dirZ)
	dirX = dirX / length
	dirZ = dirZ / length
	local dot = MathUtil.getProjectOnLineParameter(sx1, sz1, sx2, sz2, dirX, dirZ)
	if 0 <= dot and dot <= length then
		return true
	end
	dot = MathUtil.getProjectOnLineParameter(ex1, ez1, sx2, sz2, dirX, dirZ)
	if 0 <= dot and dot <= length then
		return true
	end
	return false
end
function FieldCourseUtil.getAreBoundariesColliding(boundary1, boundary2)
	for i1 = 1, #boundary1 - 1 do
		local x1 = boundary1[i1][1]
		local z1 = boundary1[i1][2]
		local x2 = boundary1[i1 + 1][1]
		local z2 = boundary1[i1 + 1][2]
		for i2 = 1, #boundary2 - 1 do
			local x3 = boundary2[i2][1]
			local z3 = boundary2[i2][2]
			local x4 = boundary2[i2 + 1][1]
			local z4 = boundary2[i2 + 1][2]
			local intersect = MathUtil.getLineSegmentsIntersection(x1, z1, x2, z2, x3, z3, x4, z4)
			if intersect then
				return true
			end
		end
	end
	return false
end
function FieldCourseUtil.getIsSegmentInsideBoundary(l1x, l1z, l2x, l2z, boundary)
	local lDirX, lDirZ = MathUtil.vector2Normalize(l2x - l1x, l2z - l1z)
	l1x = l1x + lDirX * 0.001
	l1z = l1z + lDirZ * 0.001
	l2x = l2x - lDirX * 0.001
	l2z = l2z - lDirZ * 0.001
	if FieldCourseUtil.getIsPointInsideBoundary(l1x, l1z, boundary) and FieldCourseUtil.getIsPointInsideBoundary(l2x, l2z, boundary) then
		local numIntersections = 0
		for i = 1, #boundary - 1 do
			local sx = boundary[i][1]
			local sz = boundary[i][2]
			local ex = boundary[i + 1][1]
			local ez = boundary[i + 1][2]
			local intersect, _, _ = MathUtil.getLineSegmentsIntersection(sx, sz, ex, ez, l1x, l1z, l2x, l2z)
			if intersect then
				numIntersections = numIntersections + 1
			end
		end
		return numIntersections == 0
	end
	return false
end
function FieldCourseUtil.getSegmentBoundaryIntersection(l1x, l1z, l2x, l2z, boundary)
	for i = 1, #boundary - 1 do
		local sx = boundary[i][1]
		local sz = boundary[i][2]
		local ex = boundary[i + 1][1]
		local ez = boundary[i + 1][2]
		local intersect, x, z = MathUtil.getLineSegmentsIntersection(sx, sz, ex, ez, l1x, l1z, l2x, l2z)
		if intersect then
			return intersect, x, z
		end
	end
	return false, 0, 0
end
function FieldCourseUtil.getSegmentNumBoundaryIntersections(l1x, l1z, l2x, l2z, boundary)
	local intersections = 0
	for i = 1, #boundary - 1 do
		local sx = boundary[i][1]
		local sz = boundary[i][2]
		local ex = boundary[i + 1][1]
		local ez = boundary[i + 1][2]
		local intersect, _, _ = MathUtil.getLineSegmentsIntersection(sx, sz, ex, ez, l1x, l1z, l2x, l2z)
		if intersect then
			intersections = intersections + 1
		end
	end
	return intersections
end
function FieldCourseUtil.getSegmentClosestBoundaryIntersection(l1x, l1z, l2x, l2z, boundary)
	local minDistance = math.huge
	local ix = nil
	local iz = nil
	local psx = nil
	local psz = nil
	local pex = nil
	local pez = nil
	for i = 1, #boundary - 1 do
		local sx = boundary[i][1]
		local sz = boundary[i][2]
		local ex = boundary[i + 1][1]
		local ez = boundary[i + 1][2]
		local intersect, x, z = MathUtil.getLineSegmentsIntersection(sx, sz, ex, ez, l1x, l1z, l2x, l2z)
		if intersect then
			local distance = MathUtil.vector2Length(l1x - x, l1z - z)
			if distance < minDistance then
				minDistance = distance
				ix = x
				iz = z
				psx = sx
				psz = sz
				pex = ex
				pez = ez
			end
		end
	end
	return minDistance ~= math.huge, ix, iz, psx, psz, pex, pez
end
function FieldCourseUtil.getSegmentClosestBoundaryCircleIntersection(refX, refZ, circleX, circleZ, radius, boundary)
	local minDistance = math.huge
	local ix = nil
	local iz = nil
	for i = 1, #boundary - 1 do
		local sx = boundary[i][1]
		local sz = boundary[i][2]
		local ex = boundary[i + 1][1]
		local ez = boundary[i + 1][2]
		local length = MathUtil.vector2Length(sx - ex, sz - ez)
		if 0 < length then
			local intersect, ix1, iz1, ix2, iz2 = MathUtil.getCircleLineIntersection(circleX, circleZ, radius, sx, sz, ex, ez)
			if intersect then
				if ix1 ~= nil and iz1 ~= nil then
					local distance = MathUtil.vector2Length(ix1 - refX, iz1 - refZ)
					if distance < minDistance then
						minDistance = distance
						ix = ix1
						iz = iz1
					end
				end
				if ix2 == nil or iz2 == nil then
					continue
				end
				local distance = MathUtil.vector2Length(ix2 - refX, iz2 - refZ)
				if distance < minDistance then
					minDistance = distance
					ix = ix2
					iz = iz2
				end
			end
		end
	end
	return ix ~= nil, ix, iz
end
function FieldCourseUtil.getClosestPositionOnBoundary(x, z, boundary)
	local minDistance = math.huge
	local cx = nil
	local cz = nil
	for i = 1, #boundary - 1 do
		local sx = boundary[i][1]
		local sz = boundary[i][2]
		local ex = boundary[i + 1][1]
		local ez = boundary[i + 1][2]
		local dirX = ex - sx
		local dirZ = ez - sz
		local length = MathUtil.vector2Length(dirX, dirZ)
		dirX = dirX / length
		dirZ = dirZ / length
		local dot = MathUtil.getProjectOnLineParameter(x, z, sx, sz, dirX, dirZ)
		if 0 <= dot and dot <= length then
			local ix = sx + dirX * dot
			local iz = sz + dirZ * dot
			local distance = MathUtil.vector2Length(ix - x, iz - z)
			if distance < minDistance then
				minDistance = distance
				cx = ix
				cz = iz
			end
		end
		local distance = MathUtil.vector2Length(sx - x, sz - z)
		if distance < minDistance then
			minDistance = distance
			cx = sx
			cz = sz
		end
		local distance = MathUtil.vector2Length(ex - x, ez - z)
		if distance < minDistance then
			minDistance = distance
			cx = ex
			cz = ez
		end
	end
	return cx, cz
end
function FieldCourseUtil.getClosestPositionAndDirectionOnBoundary(x, z, boundary)
	local minDistance = math.huge
	local cx = nil
	local cz = nil
	local cDirX = nil
	local cDirZ = nil
	for i = 1, #boundary - 1 do
		local sx = boundary[i][1]
		local sz = boundary[i][2]
		local ex = boundary[i + 1][1]
		local ez = boundary[i + 1][2]
		local dirX = ex - sx
		local dirZ = ez - sz
		local length = MathUtil.vector2Length(dirX, dirZ)
		dirX = dirX / length
		dirZ = dirZ / length
		local dot = MathUtil.getProjectOnLineParameter(x, z, sx, sz, dirX, dirZ)
		if 0 <= dot and dot <= length then
			local ix = sx + dirX * dot
			local iz = sz + dirZ * dot
			local distance = MathUtil.vector2Length(ix - x, iz - z)
			if distance < minDistance then
				minDistance = distance
				cx = ix
				cz = iz
				cDirX = dirX
				cDirZ = dirZ
			end
		end
		local distance = MathUtil.vector2Length(sx - x, sz - z)
		if distance < minDistance then
			minDistance = distance
			cx = sx
			cz = sz
			cDirX = dirX
			cDirZ = dirZ
		end
		local distance = MathUtil.vector2Length(ex - x, ez - z)
		if distance < minDistance then
			minDistance = distance
			cx = ex
			cz = ez
			cDirX = dirX
			cDirZ = dirZ
		end
	end
	return cx, cz, cDirX, cDirZ
end
function FieldCourseUtil.getClosestExtendedPositionAndDirectionOnSegment(x, z, positions, maxExtension)
	local numPositions = #positions
	local minDistance = math.huge
	local cx = nil
	local cz = nil
	local cDirX = nil
	local cDirZ = nil
	local onLineX = nil
	local onLineZ = nil
	for i = 1, numPositions - 1 do
		local sx = positions[i][1]
		local sz = positions[i][2]
		local ex = positions[i + 1][1]
		local ez = positions[i + 1][2]
		local dirX = ex - sx
		local dirZ = ez - sz
		local length = MathUtil.vector2Length(dirX, dirZ)
		dirX = dirX / length
		dirZ = dirZ / length
		local dot = MathUtil.getProjectOnLineParameter(x, z, sx, sz, dirX, dirZ)
		if 0 <= dot and dot <= length then
			local ix = sx + dirX * dot
			local iz = sz + dirZ * dot
			local distance = MathUtil.vector2Length(ix - x, iz - z)
			if distance < minDistance then
				minDistance = distance
				cx = ix
				cz = iz
				cDirX = dirX
				cDirZ = dirZ
			end
		end
		local distance = MathUtil.vector2Length(sx - x, sz - z)
		if distance < minDistance then
			minDistance = distance
			cx = sx
			cz = sz
			cDirX = dirX
			cDirZ = dirZ
		end
		local distance = MathUtil.vector2Length(ex - x, ez - z)
		if distance < minDistance then
			minDistance = distance
			cx = ex
			cz = ez
			cDirX = dirX
			cDirZ = dirZ
		end
	end
	onLineX = cx
	onLineZ = cz
	local sx = positions[1][1]
	local sz = positions[1][2]
	local ex = positions[2][1]
	local ez = positions[2][2]
	local dirX, dirZ = MathUtil.vector2Normalize(sx - ex, sz - ez)
	local dot = MathUtil.getProjectOnLineParameter(x, z, sx, sz, dirX, dirZ)
	if 0 < dot then
		dot = math.min(dot, maxExtension)
		local ix = sx + dirX * dot
		local iz = sz + dirZ * dot
		local distance = MathUtil.vector2Length(ix - x, iz - z)
		if distance < minDistance then
			minDistance = distance
			cx = ix
			cz = iz
			cDirX = dirX
			cDirZ = dirZ
			onLineX = sx
			onLineZ = sz
		end
	end
	sx = positions[numPositions][1]
	sz = positions[numPositions][2]
	ex = positions[numPositions - 1][1]
	ez = positions[numPositions - 1][2]
	dirX, dirZ = MathUtil.vector2Normalize(sx - ex, sz - ez)
	dot = MathUtil.getProjectOnLineParameter(x, z, sx, sz, dirX, dirZ)
	if 0 < dot then
		dot = math.min(dot, maxExtension)
		local ix = sx + dirX * dot
		local iz = sz + dirZ * dot
		local distance = MathUtil.vector2Length(ix - x, iz - z)
		if distance < minDistance then
			minDistance = distance
			cx = ix
			cz = iz
			cDirX = dirX
			cDirZ = dirZ
			onLineX = sx
			onLineZ = sz
		end
	end
	return cx, cz, cDirX, cDirZ, onLineX, onLineZ
end
function FieldCourseUtil.getSegmentLength(positions)
	local length = 0
	for i = 1, #positions - 1 do
		local sx = positions[i][1]
		local sz = positions[i][2]
		local ex = positions[i + 1][1]
		local ez = positions[i + 1][2]
		length = length + MathUtil.vector2Length(ex - sx, ez - sz)
	end
	return length
end
function FieldCourseUtil.extendSegment(positions, direction, offset)
	if 0 < direction then
		local p1 = positions[#positions - 1]
		local p2 = positions[#positions]
		local dirX = p2[1] - p1[1]
		local dirZ = p2[2] - p1[2]
		local length = MathUtil.vector2Length(dirX, dirZ)
		dirX = dirX / length
		dirZ = dirZ / length
		if offset >= 0 then
			p2[1] = p2[1] + dirX * offset
			p2[2] = p2[2] + dirZ * offset
		elseif length >= -offset then
			p2[1] = p2[1] + dirX * offset
			p2[2] = p2[2] + dirZ * offset
		else
			if 2 < #positions then
				offset = offset + length
				table.remove(positions, #positions)
				FieldCourseUtil.extendSegment(positions, direction, offset)
			end
		end
	else
		local p1 = positions[1]
		local p2 = positions[2]
		local dirX = p1[1] - p2[1]
		local dirZ = p1[2] - p2[2]
		local length = MathUtil.vector2Length(dirX, dirZ)
		dirX = dirX / length
		dirZ = dirZ / length
		if offset >= 0 then
			p1[1] = p1[1] + dirX * offset
			p1[2] = p1[2] + dirZ * offset
		elseif length >= -offset then
			p1[1] = p1[1] + dirX * offset
			p1[2] = p1[2] + dirZ * offset
		else
			if 2 < #positions then
				offset = offset + length
				table.remove(positions, 1)
				FieldCourseUtil.extendSegment(positions, direction, offset)
			end
		end
	end
end
function FieldCourseUtil.extendSegmentToBoundary(positions, boundary, extendStart, extendEnd, maxDistance)
	maxDistance = maxDistance or math.huge
	if extendStart ~= false then
		local p1 = positions[1]
		local p2 = positions[2]
		local dirX = p1[1] - p2[1]
		local dirZ = p1[2] - p2[2]
		local length = MathUtil.vector2Length(dirX, dirZ)
		dirX = dirX / length
		dirZ = dirZ / length
		local intersect1, ix1, iz1 = FieldCourseUtil.getSegmentBoundaryIntersection(p1[1], p1[2], p1[1] + dirX * 65535, p1[2] + dirZ * 65535, boundary)
		if intersect1 then
			local extensionLength = MathUtil.vector2Length(ix1 - p1[1], iz1 - p1[2])
			if extensionLength < maxDistance then
				p1[1] = ix1
				p1[2] = iz1
			end
		end
	end
	if extendEnd ~= false then
		local p1 = positions[#positions]
		local p2 = positions[#positions - 1]
		local dirX = p1[1] - p2[1]
		local dirZ = p1[2] - p2[2]
		local length = MathUtil.vector2Length(dirX, dirZ)
		dirX = dirX / length
		dirZ = dirZ / length
		local intersect1, ix1, iz1 = FieldCourseUtil.getSegmentBoundaryIntersection(p1[1], p1[2], p1[1] + dirX * 65535, p1[2] + dirZ * 65535, boundary)
		if intersect1 then
			local extensionLength = MathUtil.vector2Length(ix1 - p1[1], iz1 - p1[2])
			if extensionLength < maxDistance then
				p1[1] = ix1
				p1[2] = iz1
			end
		end
	end
end
function FieldCourseUtil.extendSegmentUntilOverlap(lines, islands, boundaries, groupIndex, positions, direction, sideOffset, distanceToAdjust, step)
	local pos1 = positions[1]
	local pos2 = positions[2]
	if direction == 1 then
		local numPositions = #positions
		pos1 = positions[numPositions]
		pos2 = positions[numPositions - 1]
	end
	local dx, dz = MathUtil.vector2Normalize(pos1[1] - pos2[1], pos1[2] - pos2[2])
	local x1 = pos1[1] + dz * sideOffset
	local z1 = pos1[2] - dx * sideOffset
	local x2 = pos1[1] - dz * sideOffset
	local z2 = pos1[2] + dx * sideOffset
	local overlap1 = false
	local overlap2 = false
	for otherGroupIndex, otherLines in pairs(lines) do
		if groupIndex ~= otherGroupIndex then
			for _, otherLine in ipairs(otherLines) do
				if FieldCourseUtil.getPositionSegmentOverlap(x1, z1, otherLine.positions, sideOffset) then
					overlap1 = true
				end
				if FieldCourseUtil.getPositionSegmentOverlap(x2, z2, otherLine.positions, sideOffset) then
					overlap2 = true
				end
				if overlap1 then
					if not overlap2 then
						continue
					end
					if not overlap1 or not overlap2 then
						for islandIndex, island in ipairs(islands) do
							for headlandIndex, islandBoundary in ipairs(island.boundaries) do
								for i = 1, #islandBoundary.segments do
									local otherLine = islandBoundary.segments[i]
									if FieldCourseUtil.getPositionSegmentOverlap(x1, z1, otherLine.positions, sideOffset) then
										overlap1 = true
									end
									if FieldCourseUtil.getPositionSegmentOverlap(x2, z2, otherLine.positions, sideOffset) then
										overlap2 = true
									end
									if not overlap1 or not overlap2 then
										for headlandIndex, headlandBoundary in ipairs(boundaries) do
											for i = 1, #headlandBoundary.segments do
												local otherLine = headlandBoundary.segments[i]
												if FieldCourseUtil.getPositionSegmentOverlap(x1, z1, otherLine.positions, sideOffset) then
													overlap1 = true
												end
												if FieldCourseUtil.getPositionSegmentOverlap(x2, z2, otherLine.positions, sideOffset) then
													overlap2 = true
												end
												if not overlap1 or not overlap2 then
													distanceToAdjust = distanceToAdjust - step
													if 0 < distanceToAdjust then
														FieldCourseUtil.extendSegment(positions, direction, step)
														FieldCourseUtil.extendSegmentUntilOverlap(lines, islands, boundaries, groupIndex, positions, direction, sideOffset, distanceToAdjust, step)
													end
												end
												return
											end
										end
									end
								end
							end
						end
					end
				end
			end
		end
	end
end
function FieldCourseUtil.shrinkSegmentUntilOverlap(lines, islands, boundaries, groupIndex, positions, direction, sideOffset, distanceToAdjust, step)
	local pos1 = positions[1]
	local pos2 = positions[2]
	if direction == 1 then
		local numPositions = #positions
		pos1 = positions[numPositions]
		pos2 = positions[numPositions - 1]
	end
	local dx, dz = MathUtil.vector2Normalize(pos1[1] - pos2[1], pos1[2] - pos2[2])
	local x1 = pos1[1] + dz * sideOffset
	local z1 = pos1[2] - dx * sideOffset
	local x2 = pos1[1] - dz * sideOffset
	local z2 = pos1[2] + dx * sideOffset
	local overlap1 = false
	local overlap2 = false
	for otherGroupIndex, otherLines in pairs(lines) do
		if groupIndex ~= otherGroupIndex then
			for _, otherLine in ipairs(otherLines) do
				if FieldCourseUtil.getPositionSegmentOverlap(x1, z1, otherLine.positions, sideOffset) then
					overlap1 = true
				end
				if FieldCourseUtil.getPositionSegmentOverlap(x2, z2, otherLine.positions, sideOffset) then
					overlap2 = true
				end
				if overlap1 then
					if not overlap2 then
						continue
					end
					if not overlap1 or not overlap2 then
						for islandIndex, island in ipairs(islands) do
							for headlandIndex, islandBoundary in ipairs(island.boundaries) do
								for i = 1, #islandBoundary.segments do
									local otherLine = islandBoundary.segments[i]
									if FieldCourseUtil.getPositionSegmentOverlap(x1, z1, otherLine.positions, sideOffset) then
										overlap1 = true
									end
									if FieldCourseUtil.getPositionSegmentOverlap(x2, z2, otherLine.positions, sideOffset) then
										overlap2 = true
									end
									if not overlap1 or not overlap2 then
										for headlandIndex, headlandBoundary in ipairs(boundaries) do
											for i = 1, #headlandBoundary.segments do
												local otherLine = headlandBoundary.segments[i]
												if FieldCourseUtil.getPositionSegmentOverlap(x1, z1, otherLine.positions, sideOffset) then
													overlap1 = true
												end
												if FieldCourseUtil.getPositionSegmentOverlap(x2, z2, otherLine.positions, sideOffset) then
													overlap2 = true
												end
												if overlap1 and overlap2 then
													distanceToAdjust = distanceToAdjust - step
													if 0 <= distanceToAdjust and step + 1 < FieldCourseUtil.getSegmentLength(positions) then
														FieldCourseUtil.extendSegment(positions, direction, -step)
														FieldCourseUtil.shrinkSegmentUntilOverlap(lines, islands, boundaries, groupIndex, positions, direction, sideOffset, distanceToAdjust, step)
													end
												end
												return
											end
										end
									end
								end
							end
						end
					end
				end
			end
		end
	end
end
function FieldCourseUtil.extendSegmentPositions(segment, toolFrontOffset)
	if 0 < toolFrontOffset then
		for i = #segment.positions - 1, 2, -1 do
			local p1 = segment.positions[i - 1]
			local p2 = segment.positions[i]
			local p3 = segment.positions[i + 1]
			local x = p2[1]
			local z = p2[2]
			local dx1 = x - p1[1]
			local dz1 = z - p1[2]
			local dx2 = p3[1] - x
			local dz2 = p3[2] - z
			local length1 = MathUtil.vector2Length(dx1, dz1)
			local length2 = MathUtil.vector2Length(dx2, dz2)
			dx1 = dx1 / length1
			dz1 = dz1 / length1
			dx2 = dx2 / length2
			dz2 = dz2 / length2
			local offset1 = math.min(length1 * 0.5, toolFrontOffset)
			local offset2 = math.min(length2 * 0.5, toolFrontOffset)
			p2[1] = x - dx1 * offset1
			p2[2] = z - dz1 * offset1
			table.insert(segment.positions, i + 1, { x + dx2 * offset2, z + dz2 * offset2 })
		end
	end
end
function FieldCourseUtil.segmentApplySideOffset(segment, sideOffset)
	local numPositions = #segment.positions
	for i = 1, numPositions - 1 do
		local p1 = segment.positions[i]
		local p2 = segment.positions[i + 1]
		local dx, dz = MathUtil.vector2Normalize(p2[1] - p1[1], p2[2] - p1[2])
		p1[1] = p1[1] + dz * sideOffset
		p1[2] = p1[2] - dx * sideOffset
		if i + 1 == numPositions then
			p2[1] = p2[1] + dz * sideOffset
			p2[2] = p2[2] - dx * sideOffset
		end
	end
	return true
end
function FieldCourseUtil.removeShortSegments(boundaryLine, threshold, isLoop)
	for posIndex = #boundaryLine - 1, 1, -1 do
		local pos1 = boundaryLine[posIndex]
		local pos2 = boundaryLine[posIndex + 1]
		local length = MathUtil.vector2Length(pos2[1] - pos1[1], pos2[2] - pos1[2])
		if length < threshold then
			table.remove(boundaryLine, posIndex)
			if posIndex == 1 then
				if isLoop == false then
					continue
				end
				boundaryLine[1] = table.clone(boundaryLine[#boundaryLine])
			end
		end
	end
	return false
end
