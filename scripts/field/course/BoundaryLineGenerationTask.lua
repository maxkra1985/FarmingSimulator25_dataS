BoundaryLineGenerationTask = {}
local BoundaryLineGenerationTask_mt = Class(BoundaryLineGenerationTask)
function BoundaryLineGenerationTask.new(boundaryLine, sx, sz, dirX, dirZ, islands, fieldCourseSettings, callback)
	local self = setmetatable({}, BoundaryLineGenerationTask_mt)
	local forceStraightLines = false
	if 0 <= fieldCourseSettings.workDirection then
		dirX, dirZ = MathUtil.getDirectionFromYRotation(fieldCourseSettings.workDirection)
		forceStraightLines = true
	end
	if fieldCourseSettings.rowSpacing ~= 0 and fieldCourseSettings.workDirection < 0 then
		local yRot = MathUtil.getYRotationFromDirection(dirX, dirZ)
		local snapAngle = fieldCourseSettings.rowSnapAngle
		if snapAngle == 0 then
			snapAngle = g_currentMission.fieldGroundSystem:getGroundAngleStep()
		end
		if 0 < snapAngle then
			yRot = MathUtil.round(yRot / snapAngle) * snapAngle
			dirX, dirZ = MathUtil.getDirectionFromYRotation(yRot)
			forceStraightLines = true
		end
	end
	self.sx, self.sz, self.offsetDirX, self.offsetDirZ, self.distanceToCheck = BoundaryLineGenerationTask.getFurthestPointToLine(sx, sz, dirX, dirZ, boundaryLine)
	if self.sx == nil then
		return nil
	end
	if fieldCourseSettings.rowSpacing ~= 0 then
		local refX = -g_currentMission.terrainSize * 0.5
		local refZ = -g_currentMission.terrainSize * 0.5
		local intersect, t1, _ = MathUtil.getLineLineIntersection2D(self.sx, self.sz, self.offsetDirX, self.offsetDirZ, refX, refZ, dirX, dirZ)
		if intersect then
			local roundedT1 = MathUtil.round(t1 / fieldCourseSettings.rowSpacing) * fieldCourseSettings.rowSpacing
			local offset = roundedT1 - t1
			if MathUtil.round(fieldCourseSettings.implementWidth / fieldCourseSettings.rowSpacing) % 2 ~= 0 then
				offset = offset + fieldCourseSettings.rowSpacing * 0.5
			end
			offset = offset + fieldCourseSettings.rowOffset
			self.sx = self.sx - self.offsetDirX * offset
			self.sz = self.sz - self.offsetDirZ * offset
		end
	end
	self.segmentSplitAngle = math.rad(fieldCourseSettings.segmentSplitAngle)
	self.boundary = FieldCourseBoundary.createByBoundaryLine(boundaryLine, self.segmentSplitAngle)
	if self.boundary == nil then
		Logging.warning("BoundaryLineGenerationTask: Failed to create boundary from boundary line")
		return nil
	else
		self.boundaryLine = self.boundary.boundaryLine
		self.dirX = dirX
		self.dirZ = dirZ
		self.islands = islands
		self.lineToLineDistance = fieldCourseSettings.implementWidth
		self.segmentMinOffset = fieldCourseSettings.segmentMinOffset or 0
		self.segmentMinLength = fieldCourseSettings.segmentMinLength or 0
		self.callback = callback
		self.curX = self.sx + self.offsetDirX * self.lineToLineDistance * 0.5
		self.curZ = self.sz + self.offsetDirZ * self.lineToLineDistance * 0.5
		self.hasFinished = false
		local maxFactor = 0
		self.rootSegment = nil
		if not forceStraightLines then
			for _, segment in ipairs(self.boundary.segments) do
				local maxAngle, angleSum = BoundaryLineGenerationTask.getSegmentsAngleData(segment.positions)
				if maxAngle < self.segmentSplitAngle then
					local length = FieldCourseUtil.getSegmentLength(segment.positions)
					local anglePerMeter = angleSum / length
					local factor = length * (1 - math.min(anglePerMeter / 0.005, 1) * 0.66)
					if maxFactor < factor then
						maxFactor = factor
						self.rootSegment = segment
					end
				end
			end
		end
		self.detectStraightLines = true
		self.offsetLineIndex = 0
		self.straightLines = {}
		self.contourLines = {}
		if self.rootSegment ~= nil then
			self.detectStraightLines = false
			self.lastContourLine = self.rootSegment.positions
			local p1 = self.lastContourLine[1]
			local p2 = self.lastContourLine[2]
			local sdx, sdz = MathUtil.vector2Normalize(p1[1] - p2[1], p1[2] - p2[2])
			p1[1] = p1[1] + sdx * 65535
			p1[2] = p1[2] + sdz * 65535
			p1 = self.lastContourLine[#self.lastContourLine]
			p2 = self.lastContourLine[#self.lastContourLine - 1]
			local edx, edz = MathUtil.vector2Normalize(p1[1] - p2[1], p1[2] - p2[2])
			p1[1] = p1[1] + edx * 65535
			p1[2] = p1[2] + edz * 65535
			self.contourExtensionDirection = 1
		end
		return self
	end
end
function BoundaryLineGenerationTask:update(dt, frameBudget)
	if not self.detectStraightLines then
		local startTime = getTimeSec()
		while getTimeSec() - startTime < frameBudget do
			if self.contourExtensionDirection == 1 then
				if #self.contourLines == 0 then
					self:extendContourLine(0.01, self.offsetLineIndex)
					self.initialContourLine = self.contourLines[1]
				end
				self.offsetLineIndex = self.offsetLineIndex + 1
				local continueGeneration, success = self:extendContourLine(self.lineToLineDistance, self.offsetLineIndex)
				if self.initialContourLine ~= nil then
					table.remove(self.contourLines, 1)
					self.initialContourLine = nil
				end
				if continueGeneration then
					continue
				end
				if success then
					self:extendContourLine(0.5, self.offsetLineIndex)
					self.lastContourLine = self.rootSegment.positions
					self.contourExtensionDirection = -1
					self.offsetLineIndex = 0
					self:extendContourLine(-0.01, self.offsetLineIndex)
				else
					self.detectStraightLines = true
					self.contourLines = nil
					break
				end
			else
				self.offsetLineIndex = self.offsetLineIndex - 1
				local continueGeneration, success = self:extendContourLine(-self.lineToLineDistance, self.offsetLineIndex)
				if continueGeneration then
					continue
				end
				if not success then
					self.contourLines = nil
					self.detectStraightLines = true
					self.offsetLineIndex = 0
					break
				else
					break
				end
			end
		end
	else
		local dirX = self.dirX
		local dirZ = self.dirZ
		local startTime = getTimeSec()
		while getTimeSec() - startTime < frameBudget do
			self.offsetLineIndex = self.offsetLineIndex + 1
			BoundaryLineGenerationTask.detectInsideBoundaryLines(self.straightLines, self.curX, self.curZ, dirX, dirZ, self.boundaryLine, self.islands, self.offsetLineIndex)
			self.curX = self.curX + self.offsetDirX * self.lineToLineDistance
			self.curZ = self.curZ + self.offsetDirZ * self.lineToLineDistance
			self.distanceToCheck = self.distanceToCheck - self.lineToLineDistance
			if self.distanceToCheck <= 0 then
				self.hasFinished = true
				local lines = self.straightLines
				if self.contourLines ~= nil then
					local numContourLines = #self.contourLines
					local numStraightLines = #self.straightLines
					if 0 < numContourLines and numContourLines - numStraightLines <= math.max(numStraightLines * 0.15, 1) then
						lines = self.contourLines
					end
				end
				if 0 < self.segmentMinOffset then
					BoundaryLineGenerationTask.removeMinOffsetLines(lines, self.boundaryLine, self.segmentMinOffset)
				end
				if 0 < self.segmentMinLength then
					for i = #lines, 1, -1 do
						local line = lines[i]
						if FieldCourseUtil.getSegmentLength(line.positions) < self.segmentMinLength then
							table.remove(lines, i)
						end
					end
				end
				if self.callback ~= nil then
					self.callback(lines)
					break
				end
				return not self.hasFinished
			end
		end
	end
end
function BoundaryLineGenerationTask:extendContourLine(lineToLineDistance, offsetLineIndex)
	local contourLine = FieldCourseBoundary.getOffsetBoundaryLine(self.lastContourLine, lineToLineDistance, 0.25)
	if contourLine == nil then
		return false, false
	end
	FieldCourseUtil.removeShortSegments(contourLine, 0.25)
	FieldCourseUtil.douglasPeucker(contourLine, 0.25)
	if not FieldCourseBoundary.resolveSelfIntersections(contourLine) then
		return false, false
	end
	if FieldCourseUtil.getSegmentLength(contourLine) < 0.25 then
		return false, true
	end
	local maxAngle, _ = BoundaryLineGenerationTask.getSegmentsAngleData(contourLine)
	if self.segmentSplitAngle < maxAngle then
		return false, false
	else
		FieldCourseUtil.douglasPeucker(contourLine, 0.25)
		self.lastContourLine = contourLine
		local continueGeneration = BoundaryLineGenerationTask.resolveBoundaryIntersections(self.contourLines, contourLine, self.boundaryLine, self.islands, offsetLineIndex)
		return continueGeneration, true
	end
end
function BoundaryLineGenerationTask.getFurthestPointToLine(x, z, dirX, dirZ, boundary)
	local offset = 4096
	x = x - dirZ * 4096
	z = z + dirX * 4096
	local minDistance = math.huge
	local minDistancePoint = 0
	local maxDistance = 0
	local maxDistancePoint = 0
	local offsetDirX = nil
	local offsetDirZ = nil
	for i = 1, #boundary do
		local x1 = boundary[i][1]
		local z1 = boundary[i][2]
		local x2, z2 = MathUtil.projectOnLine(x1, z1, x, z, dirX, dirZ)
		local distance = MathUtil.vector2Length(x2 - x1, z2 - z1)
		if maxDistance < distance then
			maxDistance = distance
			maxDistancePoint = i
			offsetDirX = (x2 - x1) / distance
			offsetDirZ = (z2 - z1) / distance
		end
		if distance < minDistance then
			minDistance = distance
			minDistancePoint = i
		end
	end
	if 0 < minDistancePoint and 0 < maxDistancePoint then
		local distance = maxDistance - minDistance
		return boundary[maxDistancePoint][1], boundary[maxDistancePoint][2], offsetDirX, offsetDirZ, distance
	end
	return nil
end
function BoundaryLineGenerationTask.detectInsideBoundaryLines(lines, x, z, dirX, dirZ, boundary, islands, offsetLineIndex)
	local intersections = {}
	local sx = x - dirX * 65535
	local sz = z - dirZ * 65535
	local ex = x + dirX * 65535
	local ez = z + dirZ * 65535
	for i = 1, #boundary - 1 do
		local intersect, ix, iz = MathUtil.getLineSegmentsIntersection(boundary[i][1], boundary[i][2], boundary[i + 1][1], boundary[i + 1][2], sx, sz, ex, ez)
		if intersect then
			table.insert(intersections, { ix, iz })
		end
	end
	for _, island in ipairs(islands) do
		local innerBoundary = island.boundaries[#island.boundaries] or island.innerBoundary
		local innerBoundaryLine = innerBoundary.boundaryLine
		for i = 1, #innerBoundaryLine - 1 do
			local intersect, ix, iz = MathUtil.getLineSegmentsIntersection(innerBoundaryLine[i][1], innerBoundaryLine[i][2], innerBoundaryLine[i + 1][1], innerBoundaryLine[i + 1][2], sx, sz, ex, ez)
			if intersect then
				if FieldCourseUtil.getIsPointInsideBoundary(ix, iz, boundary) then
					table.insert(intersections, { ix, iz })
				else
					table.insert(intersections, { ix, iz, true })
				end
			end
		end
	end
	table.sort(intersections, function(a, b)
		return a[1] + a[2] < b[1] + b[2]
	end)
	local numIntersections = #intersections
	if numIntersections % 2 == 0 then
		local foundIntersections = false
		for i = 1, numIntersections - 1, 2 do
			if intersections[i][3] == true or intersections[i + 1][3] == true then
				continue
			end
			local line = {}
			line.offsetLineIndex = offsetLineIndex
			line.positions = { intersections[i], intersections[i + 1] }
			table.insert(lines, line)
			foundIntersections = true
		end
		return foundIntersections
	else
		return false
	end
end
function BoundaryLineGenerationTask.removeMinOffsetLines(lines, boundary, minOffset)
	for i = #lines, 1, -1 do
		local line = lines[i]
		local isIntersecting = true
		for j = 1, #line.positions - 1 do
			local p1 = line.positions[j]
			local p2 = line.positions[j + 1]
			local dx, dz = MathUtil.vector2Normalize(p2[1] - p1[1], p2[2] - p1[2])
			for offset = 0.25, 0.75, 0.25 do
				local cx = MathUtil.lerp(p1[1], p2[1], offset)
				local cz = MathUtil.lerp(p1[2], p2[2], offset)
				local intersect, _, _ = FieldCourseUtil.getSegmentBoundaryIntersection(cx + dz * minOffset, cz - dx * minOffset, cx - dz * minOffset, cz + dx * minOffset, boundary)
				if not intersect then
					isIntersecting = false
					break
				end
			end
			if isIntersecting then
				continue
			end
			if isIntersecting then
				table.remove(lines, i)
			end
		end
	end
end
function BoundaryLineGenerationTask.getNumBoundaryLines(x, z, dirX, dirZ, boundary)
	local numIntersections = 0
	local sx = x - dirX * 65535
	local sz = z - dirZ * 65535
	local ex = x + dirX * 65535
	local ez = z + dirZ * 65535
	for i = 1, #boundary - 1 do
		local intersect, _, _ = MathUtil.getLineSegmentsIntersection(boundary[i][1], boundary[i][2], boundary[i + 1][1], boundary[i + 1][2], sx, sz, ex, ez)
		if intersect then
			numIntersections = numIntersections + 1
		end
	end
	if numIntersections % 2 == 0 then
		return numIntersections / 2
	else
		return 0
	end
end
function BoundaryLineGenerationTask.getOptimalBoundaryAngle(centerX, centerZ, boundary, steps)
	local minLineAmount = math.huge
	local minLineAngle = 0
	for angle = 0, 3.1315926535897933, 3.141592653589793 / steps do
		local numLines = BoundaryLineGenerationTask.getNumLinesByAngle(centerX, centerZ, boundary, angle)
		if numLines < minLineAmount then
			minLineAmount = numLines
			minLineAngle = angle
		end
	end
	return minLineAngle
end
function BoundaryLineGenerationTask.getNumLinesByAngle(centerX, centerZ, boundary, angle)
	local dirX, dirZ = MathUtil.getDirectionFromYRotation(angle)
	local sx, sz, offsetDirX, offsetDirZ, distance = BoundaryLineGenerationTask.getFurthestPointToLine(centerX, centerZ, dirX, dirZ, boundary, true)
	if sx == nil then
		return 0
	else
		sx = sx + offsetDirX * 0.1
		sz = sz + offsetDirZ * 0.1
		local offset = 10
		local numLines = 0
		while true do
			sx = sx + offsetDirX * 10
			sz = sz + offsetDirZ * 10
			local newLines = BoundaryLineGenerationTask.getNumBoundaryLines(sx, sz, dirX, dirZ, boundary)
			if 0 >= newLines then
				break
			end
			numLines = numLines + newLines
			break
		end
		while true do
			distance = distance - 10
			if distance <= 0 then
				break
			end
		end
		return numLines
	end
end
function BoundaryLineGenerationTask.resolveBoundaryIntersections(lines, line, boundary, islands, offsetLineIndex)
	local isValid = false
	local remainingLine = nil
	for i = 1, #line - 1 do
		local p1 = line[i]
		local p2 = line[i + 1]
		local dx, dz = MathUtil.vector2Normalize(p2[1] - p1[1], p2[2] - p1[2])
		local intersect, ix1, iz1 = BoundaryLineGenerationTask.getSegmentClosestBoundaryOrIslandsIntersection(p1[1], p1[2], p2[1], p2[2], boundary, islands)
		if intersect then
			local edx = dx
			local edz = dz
			local intersect, ix2, iz2 = BoundaryLineGenerationTask.getSegmentClosestBoundaryOrIslandsIntersection(ix1 + dx * 0.0001, iz1 + dz * 0.0001, p2[1], p2[2], boundary, islands)
			local hitIndex = i
			if not intersect then
				for j = i + 1, #line - 1 do
					local sp1 = line[j]
					local sp2 = line[j + 1]
					edx, edz = MathUtil.vector2Normalize(sp2[1] - sp1[1], sp2[2] - sp1[2])
					intersect, ix2, iz2 = BoundaryLineGenerationTask.getSegmentClosestBoundaryOrIslandsIntersection(sp1[1], sp1[2], sp2[1], sp2[2], boundary, islands)
					if intersect then
						hitIndex = j
						break
					end
				end
			end
			if intersect then
				local newLine = {}
				newLine.offsetLineIndex = offsetLineIndex
				newLine.positions = {}
				table.insert(newLine.positions, { ix1 + dx * 0.0001, iz1 + dz * 0.0001 })
				for indexToAdd = i + 1, hitIndex do
					table.insert(newLine.positions, line[indexToAdd])
				end
				table.insert(newLine.positions, { ix2 - edx * 0.0001, iz2 - edz * 0.0001 })
				table.insert(lines, newLine)
				isValid = true
				if 0 < #line - hitIndex then
					remainingLine = {}
					table.insert(remainingLine, { ix2 + edx * 0.0001, iz2 + edz * 0.0001 })
					for i = hitIndex + 1, #line do
						table.insert(remainingLine, line[i])
					end
				end
			end
		end
		if isValid and remainingLine ~= nil then
			BoundaryLineGenerationTask.resolveBoundaryIntersections(lines, remainingLine, boundary, islands, offsetLineIndex)
		end
		return isValid
	end
end
function BoundaryLineGenerationTask.getSegmentClosestBoundaryOrIslandsIntersection(l1x, l1z, l2x, l2z, boundary, islands)
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
	for _, island in ipairs(islands) do
		local innerBoundary = island.boundaries[#island.boundaries] or island.innerBoundary
		local innerBoundaryLine = innerBoundary.boundaryLine
		for i = 1, #innerBoundaryLine - 1 do
			local sx = innerBoundaryLine[i][1]
			local sz = innerBoundaryLine[i][2]
			local ex = innerBoundaryLine[i + 1][1]
			local ez = innerBoundaryLine[i + 1][2]
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
	end
	return minDistance ~= math.huge, ix, iz, psx, psz, pex, pez
end
function BoundaryLineGenerationTask.getSegmentsAngleData(positions)
	if #positions <= 2 then
		return 0, 0
	else
		local maxRotDifference = 0
		local angleSum = 0
		for i = 1, #positions - 2 do
			local p1 = positions[i]
			local p2 = positions[i + 1]
			local p3 = positions[i + 2]
			local yRot1 = MathUtil.getYRotationFromDirection(MathUtil.vector2Normalize(p2[1] - p1[1], p2[2] - p1[2]))
			local yRot2 = MathUtil.getYRotationFromDirection(MathUtil.vector2Normalize(p3[1] - p2[1], p3[2] - p2[2]))
			local rotDifference = yRot2 - yRot1
			if 3.141592653589793 < rotDifference then
				rotDifference = rotDifference - 6.283185307179586
			end
			maxRotDifference = math.max(maxRotDifference, math.abs(rotDifference))
			angleSum = angleSum + math.abs(rotDifference)
		end
		return maxRotDifference, angleSum
	end
end
