AIFieldCourseTurnGenerator = {}
local AIFieldCourseTurnGenerator_mt = Class(AIFieldCourseTurnGenerator)
function AIFieldCourseTurnGenerator.new(aiFieldCourse, segments)
	local self = setmetatable({}, AIFieldCourseTurnGenerator_mt)
	self.aiFieldCourse = aiFieldCourse
	self.fieldCourseSettings = aiFieldCourse.fieldCourseSettings
	self.alternativeTurnSegments = aiFieldCourse.alternativeTurnSegments
	self.state = AIFieldCourseTurnGeneratorState.INITIAL
	self.offsetTurns = {}
	self.ignoreBoundaryIntersections = false
	self.allowProtectedBoundary = false
	self.preferOneDrivingDirection = false
	self.forcedDrivingDirection = 0
	self.maxOffset = nil
	self.overwrittenTurnRadius = nil
	return self
end
function AIFieldCourseTurnGenerator:setCallback(callback, callbackTarget)
	self.callback = callback
	self.callbackTarget = callbackTarget
end
function AIFieldCourseTurnGenerator:setIgnoreBoundaryIntersections(ignoreBoundaryIntersections)
	self.ignoreBoundaryIntersections = ignoreBoundaryIntersections
end
function AIFieldCourseTurnGenerator:setAllowProtectedBoundary(allowProtectedBoundary)
	self.allowProtectedBoundary = allowProtectedBoundary
end
function AIFieldCourseTurnGenerator:setPreferOneDrivingDirection(preferOneDrivingDirection)
	self.preferOneDrivingDirection = preferOneDrivingDirection
end
function AIFieldCourseTurnGenerator:setForcedDrivingDirection(forcedDrivingDirection)
	self.forcedDrivingDirection = forcedDrivingDirection or 0
end
function AIFieldCourseTurnGenerator:setMaxOffset(maxOffset)
	self.maxOffset = maxOffset
end
function AIFieldCourseTurnGenerator:setOverwrittenTurnRadius(overwrittenTurnRadius)
	self.overwrittenTurnRadius = overwrittenTurnRadius
end
function AIFieldCourseTurnGenerator:generateSegmentToSegment(segment1, direction1, segment2, direction2)
	self.segment1 = segment1
	self.direction1 = direction1
	self.segment2 = segment2
	self.direction2 = direction2
	local sx, sz, sDirX, sDirZ = AIFieldCourseUtil.getSegmentPositionAndDirection(false, segment1, direction1)
	local ex, ez, eDirX, eDirZ = AIFieldCourseUtil.getSegmentPositionAndDirection(true, segment2, direction2)
	local turnData = AIFieldCourseTurnData(sx, sz, sDirX, sDirZ, ex, ez, eDirX, eDirZ, segment1, direction1, segment2, direction2, self.aiFieldCourse, self.overwrittenTurnRadius)
	local startOffset = nil
	local endOffset = nil
	if AIFieldCourseTurnGenerator.isPositionOutsideField(sx, sz, turnData, true) then
		startOffset = AIFieldCourseTurnGenerator.getSegmentMinOffset(true, segment1, direction1, turnData, self.fieldCourseSettings.minTurnRadius * 2)
		if startOffset ~= nil then
			turnData = turnData:offset(startOffset, nil)
		end
	end
	if AIFieldCourseTurnGenerator.isPositionOutsideField(ex, ez, turnData, true) then
		endOffset = AIFieldCourseTurnGenerator.getSegmentMinOffset(false, segment2, direction2, turnData, math.min(self.fieldCourseSettings.minTurnRadius * 2, segment2.length))
		if endOffset ~= nil then
			turnData = turnData:offset(startOffset, endOffset)
		end
	end
	self.state = AIFieldCourseTurnGeneratorState.DEFAULT
	self.originalTurnData = turnData
	g_fieldCourseManager:addUpdateable(self)
end
function AIFieldCourseTurnGenerator:generatePositionToSegment(sx, sz, sDirX, sDirZ, segment2, direction2)
	self.segment2 = segment2
	self.direction2 = direction2
	local ex, ez, eDirX, eDirZ = AIFieldCourseUtil.getSegmentPositionAndDirection(true, segment2, direction2)
	local turnData = AIFieldCourseTurnData(sx, sz, sDirX, sDirZ, ex, ez, eDirX, eDirZ, nil, nil, segment2, direction2, self.aiFieldCourse, self.overwrittenTurnRadius)
	self.state = AIFieldCourseTurnGeneratorState.DEFAULT
	self.originalTurnData = turnData
	g_fieldCourseManager:addUpdateable(self)
end
function AIFieldCourseTurnGenerator:generatePositionToPosition(sx, sz, sDirX, sDirZ, ex, ez, eDirX, eDirZ)
	local turnData = AIFieldCourseTurnData(sx, sz, sDirX, sDirZ, ex, ez, eDirX, eDirZ, nil, nil, nil, nil, self.aiFieldCourse, self.overwrittenTurnRadius)
	self.state = AIFieldCourseTurnGeneratorState.DEFAULT
	self.originalTurnData = turnData
	g_fieldCourseManager:addUpdateable(self)
end
function AIFieldCourseTurnGenerator:onFinished(turn)
	self.state = AIFieldCourseTurnGeneratorState.FINISHED
	g_fieldCourseManager:removeUpdateable(self)
	if self.callback ~= nil then
		if self.callbackTarget ~= nil then
			self.callback(self.callbackTarget, turn)
			return
		end
		self.callback(turn)
	end
end
function AIFieldCourseTurnGenerator:update(dt)
	local startTime = getTimeSec()
	while getTimeSec() - startTime < 0.0005 do
		if self.state == AIFieldCourseTurnGeneratorState.DEFAULT then
			local minCostTurn, _ = self:getBestTurnByTurnData(self.originalTurnData)
			if minCostTurn ~= nil then
				self:onFinished(minCostTurn)
				return
			end
			self.defaultStartOffset = self.originalTurnData.startOffset or 3
			self.defaultEndOffset = self.originalTurnData.endOffset or 3
			for i = #self.offsetTurns, 1, -1 do
				self.offsetTurns[i] = nil
			end
			self.startOffsetLimit = self.fieldCourseSettings.minTurnRadius * 6
			self.endOffsetLimit = self.fieldCourseSettings.minTurnRadius * 6
			if not self.fieldCourseSettings.canTurnBackward and not self.fieldCourseSettings.allowStraightReversing then
				self.startOffsetLimit = self.segment1 ~= nil and self.segment1.length - (self.segment1.lastStartOffset or 0) or self.startOffsetLimit
				self.endOffsetLimit = self.segment2 ~= nil and self.segment2.length - (self.segment2.lastEndOffset or 0) or self.endOffsetLimit
			end
			self.startOffset = self.defaultStartOffset
			self.endOffset = self.defaultEndOffset
			self.state = AIFieldCourseTurnGeneratorState.EXTEND_SEGMENT
		elseif self.state == AIFieldCourseTurnGeneratorState.EXTEND_SEGMENT or self.state == AIFieldCourseTurnGeneratorState.SHRINK_SEGMENT then
			if self.state == AIFieldCourseTurnGeneratorState.EXTEND_SEGMENT then
				self.turnData = self.originalTurnData:offset(self.startOffset, self.endOffset)
			else
				self.turnData = self.originalTurnData:offset(-self.startOffset, -self.endOffset)
			end
			local minCostTurn, _ = self:getBestTurnByTurnData(self.turnData)
			if minCostTurn ~= nil then
				table.insert(self.offsetTurns, minCostTurn)
				local directLength = MathUtil.vector2Length(self.turnData.ex - self.turnData.sx, self.turnData.ez - self.turnData.sz)
				if minCostTurn.length * self.turnData.turnRadius < directLength * 1.25 then
					local minCostOffsetTurn = AIFieldCourseTurnGenerator.getLowestCostTurn(self.offsetTurns)
					self:onFinished(minCostOffsetTurn or minCostTurn)
					return
				end
			end
			self.startOffset = self.startOffset + 3
			if self.startOffsetLimit < self.startOffset then
				self.startOffset = self.defaultStartOffset
				self.endOffset = self.endOffset + 3
				if self.endOffsetLimit < self.endOffset then
					local minCostOffsetTurn = AIFieldCourseTurnGenerator.getLowestCostTurn(self.offsetTurns)
					if minCostOffsetTurn ~= nil then
						self:onFinished(minCostOffsetTurn)
						return
					end
					if self.state == AIFieldCourseTurnGeneratorState.EXTEND_SEGMENT then
						for i = #self.offsetTurns, 1, -1 do
							self.offsetTurns[i] = nil
						end
						self.startOffset = self.defaultStartOffset
						self.endOffset = self.defaultEndOffset
						self.state = AIFieldCourseTurnGeneratorState.SHRINK_SEGMENT
					else
						self:onFinished(nil)
						return
					end
				end
			end
		end
	end
end
function AIFieldCourseTurnGenerator.getLowestCostTurn(turns)
	local minCostOffsetTurn = nil
	local minCostOffset = math.huge
	for _, turn in ipairs(turns) do
		if turn.numBoundaryIntersections == 0 then
			local cost = turn:getOverallCost()
			if cost < minCostOffset then
				minCostOffset = cost
				minCostOffsetTurn = turn
			end
		end
	end
	return minCostOffsetTurn
end
function AIFieldCourseTurnGenerator.isPositionOutsideField(sx, sz, turnData, useProtectedBoundary, useRootBoundary)
	local boundary = turnData.validPathBoundary.boundaryLine
	if useProtectedBoundary then
		boundary = turnData.protectedBoundary.boundaryLine
	end
	if useRootBoundary then
		boundary = turnData.fieldRootBoundary.boundaryLine
	end
	if 0.01 < FieldCourseUtil.getDistanceToBoundary(sx, sz, boundary) and not FieldCourseUtil.getIsPointInsideBoundary(sx, sz, boundary) then
		return true
	end
	for _, island in ipairs(turnData.islands) do
		boundary = island.validPathBoundary
		if useProtectedBoundary then
			boundary = island.protectedBoundary
		end
		if useRootBoundary then
			boundary = island.rootBoundary
		end
		if 0.01 < FieldCourseUtil.getDistanceToBoundary(sx, sz, boundary.boundaryLine) and FieldCourseUtil.getIsPointInsideBoundary(sx, sz, boundary.boundaryLine) then
			return true
		end
	end
	return false
end
function AIFieldCourseTurnGenerator.findCommonTurnRadiusIntersection(callback, turnData)
	if turnData.segment1 == nil or turnData.segment2 == nil then
		return
	end
	local maxOffset = 50
	local sDistance = turnData.turnRadius * 6
	local sOffset = 0
	local segment1 = turnData.segment1
	local direction1 = turnData.segment1Direction
	local segment2 = turnData.segment2
	local direction2 = turnData.segment2Direction
	local validateHit = function(t1, t2, so, eo)
		so = t1 + 0.01 + so
		eo = t2 + 0.01 + eo
		local tempTurnData = turnData:offset(so, eo)
		local x1 = tempTurnData.sx
		local z1 = tempTurnData.sz
		local x2 = tempTurnData.originalTurnData.sx
		local z2 = tempTurnData.originalTurnData.sz
		local x3 = tempTurnData.ex
		local z3 = tempTurnData.ez
		local x4 = tempTurnData.originalTurnData.ex
		local z4 = tempTurnData.originalTurnData.ez
		if FieldCourseUtil.getIsPointInsideBoundary(x1, z1, turnData.protectedBoundary.boundaryLine) and FieldCourseUtil.getIsPointInsideBoundary(x2, z2, turnData.protectedBoundary.boundaryLine) then
			local intersect, _, _ = FieldCourseUtil.getSegmentBoundaryIntersection(x1, z1, x2, z2, turnData.protectedBoundary.boundaryLine)
			if intersect then
				return
			end
		end
		for _, island in ipairs(turnData.islands) do
			if FieldCourseUtil.getIsPointInsideBoundary(x1, z1, island.protectedBoundary.boundaryLine) or FieldCourseUtil.getIsPointInsideBoundary(x2, z2, island.protectedBoundary.boundaryLine) then
				continue
			end
			local intersect, _, _ = FieldCourseUtil.getSegmentBoundaryIntersection(x1, z1, x2, z2, island.protectedBoundary.boundaryLine)
			if intersect then
				return
			end
		end
		if FieldCourseUtil.getIsPointInsideBoundary(x3, z3, turnData.protectedBoundary.boundaryLine) and FieldCourseUtil.getIsPointInsideBoundary(x4, z4, turnData.protectedBoundary.boundaryLine) then
			local intersect, _, _ = FieldCourseUtil.getSegmentBoundaryIntersection(x3, z3, x4, z4, turnData.protectedBoundary.boundaryLine)
			if intersect then
				return
			end
		end
		for _, island in ipairs(turnData.islands) do
			if FieldCourseUtil.getIsPointInsideBoundary(x3, z3, island.protectedBoundary.boundaryLine) or FieldCourseUtil.getIsPointInsideBoundary(x4, z4, island.protectedBoundary.boundaryLine) then
				continue
			end
			local intersect, _, _ = FieldCourseUtil.getSegmentBoundaryIntersection(x3, z3, x4, z4, island.protectedBoundary.boundaryLine)
			if intersect then
				return
			end
		end
		callback(so, eo, turnData.turnRadius)
	end
	local sIndex = 1
	while 0 < sDistance do
		local lastIndex1 = sIndex + 1
		if 0 < direction1 then
			lastIndex1 = #segment1.positions - sIndex
		end
		local p1 = segment1.positions[lastIndex1]
		local p2 = segment1.positions[lastIndex1 + direction1]
		if p1 == nil or p2 == nil then
			break
		end
		local eIndex = 1
		local eDistance = turnData.turnRadius * 6
		local eOffset = 0
		while 0 < eDistance do
			local lastIndex2 = #segment2.positions - (eIndex - 1)
			if 0 < direction2 then
				lastIndex2 = eIndex
			end
			local p3 = segment2.positions[lastIndex2]
			local p4 = segment2.positions[lastIndex2 + direction2]
			if p3 == nil or p4 == nil then
				break
			end
			local dirX1 = p1[1] - p2[1]
			local dirZ1 = p1[2] - p2[2]
			local length1 = MathUtil.vector2Length(dirX1, dirZ1)
			dirX1 = dirX1 / length1
			dirZ1 = dirZ1 / length1
			local x1 = p2[1] + dirZ1 * turnData.turnRadius
			local z1 = p2[2] - dirX1 * turnData.turnRadius
			local maxLength1 = length1
			local extendedLength1 = 0
			if p2 == segment1.positions[1] or p2 == segment1.positions[#segment1.positions] then
				x1 = x1 - dirX1 * 50
				z1 = z1 - dirZ1 * 50
				maxLength1 = maxLength1 + 50
				extendedLength1 = 50
			end
			if p1 == segment1.positions[1] or p1 == segment1.positions[#segment1.positions] then
				maxLength1 = maxLength1 + 50
			end
			local dirX2 = p4[1] - p3[1]
			local dirZ2 = p4[2] - p3[2]
			local length2 = MathUtil.vector2Length(dirX2, dirZ2)
			dirX2 = dirX2 / length2
			dirZ2 = dirZ2 / length2
			local x2 = p3[1] + dirZ2 * turnData.turnRadius
			local z2 = p3[2] - dirX2 * turnData.turnRadius
			local maxLength2 = length2
			local extendedLength2 = 0
			if p3 == segment2.positions[1] or p3 == segment2.positions[#segment2.positions] then
				x2 = x2 - dirX2 * 50
				z2 = z2 - dirZ2 * 50
				maxLength2 = maxLength2 + 50
				extendedLength2 = 50
			end
			if p4 == segment2.positions[1] or p4 == segment2.positions[#segment2.positions] then
				maxLength2 = maxLength2 + 50
			end
			local intersect, t1, t2 = MathUtil.getLineLineIntersection2D(x1, z1, dirX1, dirZ1, x2, z2, dirX2, dirZ2)
			if intersect and (0 < t1 and (t1 <= maxLength1 and (0 < t2 and t2 <= maxLength2))) then
				if 0 < extendedLength1 then
					t1 = t1 - extendedLength1
				end
				if 0 < extendedLength2 then
					t2 = t2 - extendedLength2
				end
				validateHit(t1, t2, sOffset, eOffset)
			end
			x1 = p2[1] - dirZ1 * turnData.turnRadius
			z1 = p2[2] + dirX1 * turnData.turnRadius
			maxLength1 = length1
			extendedLength1 = 0
			if p2 == segment1.positions[1] or p2 == segment1.positions[#segment1.positions] then
				x1 = x1 - dirX1 * 50
				z1 = z1 - dirZ1 * 50
				maxLength1 = maxLength1 + 50
				extendedLength1 = 50
			end
			if p1 == segment1.positions[1] or p1 == segment1.positions[#segment1.positions] then
				maxLength1 = maxLength1 + 50
			end
			intersect, t1, t2 = MathUtil.getLineLineIntersection2D(x1, z1, dirX1, dirZ1, x2, z2, dirX2, dirZ2)
			if intersect and (0 < t1 and (t1 <= maxLength1 and (0 < t2 and t2 <= maxLength2))) then
				if 0 < extendedLength1 then
					t1 = t1 - extendedLength1
				end
				if 0 < extendedLength2 then
					t2 = t2 - extendedLength2
				end
				validateHit(t1, t2, sOffset, eOffset)
			end
			x2 = p3[1] - dirZ2 * turnData.turnRadius
			z2 = p3[2] + dirX2 * turnData.turnRadius
			maxLength2 = length2
			extendedLength2 = 0
			if p3 == segment2.positions[1] or p3 == segment2.positions[#segment2.positions] then
				x2 = x2 - dirX2 * 50
				z2 = z2 - dirZ2 * 50
				maxLength2 = maxLength2 + 50
				extendedLength2 = 50
			end
			if p4 == segment2.positions[1] or p4 == segment2.positions[#segment2.positions] then
				maxLength2 = maxLength2 + 50
			end
			intersect, t1, t2 = MathUtil.getLineLineIntersection2D(x1, z1, dirX1, dirZ1, x2, z2, dirX2, dirZ2)
			if intersect and (0 < t1 and (t1 <= maxLength1 and (0 < t2 and t2 <= maxLength2))) then
				if 0 < extendedLength1 then
					t1 = t1 - extendedLength1
				end
				if 0 < extendedLength2 then
					t2 = t2 - extendedLength2
				end
				validateHit(t1, t2, sOffset, eOffset)
			end
			x1 = p2[1] + dirZ1 * turnData.turnRadius
			z1 = p2[2] - dirX1 * turnData.turnRadius
			maxLength1 = length1
			extendedLength1 = 0
			if p2 == segment1.positions[1] or p2 == segment1.positions[#segment1.positions] then
				x1 = x1 - dirX1 * 50
				z1 = z1 - dirZ1 * 50
				maxLength1 = maxLength1 + 50
				extendedLength1 = 50
			end
			if p1 == segment1.positions[1] or p1 == segment1.positions[#segment1.positions] then
				maxLength1 = maxLength1 + 50
			end
			x2 = p3[1] - dirZ2 * turnData.turnRadius
			z2 = p3[2] + dirX2 * turnData.turnRadius
			maxLength2 = length2
			extendedLength2 = 0
			if p3 == segment2.positions[1] or p3 == segment2.positions[#segment2.positions] then
				x2 = x2 - dirX2 * 50
				z2 = z2 - dirZ2 * 50
				maxLength2 = maxLength2 + 50
				extendedLength2 = 50
			end
			if p4 == segment2.positions[1] or p4 == segment2.positions[#segment2.positions] then
				maxLength2 = maxLength2 + 50
			end
			intersect, t1, t2 = MathUtil.getLineLineIntersection2D(x1, z1, dirX1, dirZ1, x2, z2, dirX2, dirZ2)
			if intersect and (0 < t1 and (t1 <= maxLength1 and (0 < t2 and t2 <= maxLength2))) then
				if 0 < extendedLength1 then
					t1 = t1 - extendedLength1
				end
				if 0 < extendedLength2 then
					t2 = t2 - extendedLength2
				end
				validateHit(t1, t2, sOffset, eOffset)
			end
			local segDistance = MathUtil.vector2Length(p4[1] - p3[1], p4[2] - p3[2])
			eDistance = eDistance - segDistance
			eOffset = eOffset + segDistance
			eIndex = eIndex + 1
		end
		local segDistance = MathUtil.vector2Length(p2[1] - p1[1], p2[2] - p1[2])
		sDistance = sDistance - segDistance
		sOffset = sOffset + segDistance
		sIndex = sIndex + 1
	end
end
function AIFieldCourseTurnGenerator.generateTurnIntersectionPoints(turnData, intersectionPositions, intersectData, ix, iz, psx, psz, pex, pez)
	local boundaryLine = intersectData.boundary
	local numPoints = #boundaryLine
	local getDistanceToTargetPoint = function(startIndex, direction, lastX, lastZ)
		local distance = 0
		local endIndex = startIndex
		for i = startIndex, startIndex + numPoints * direction, direction do
			local pos = boundaryLine[(i - 1) % numPoints + 1]
			if not FieldCourseUtil.getIsPointInsideBoundary(pos[1], pos[2], turnData.protectedBoundary.boundaryLine) then
				return math.huge, startIndex
			end
			distance = distance + MathUtil.vector2Length(lastX - pos[1], lastZ - pos[2])
			lastX = pos[1]
			lastZ = pos[2]
			if pos[1] == psx and pos[2] == psz then
				endIndex = i
				break
			end
			if pos[1] == pex and pos[2] == pez then
				endIndex = i
				break
			end
		end
		return distance + MathUtil.vector2Length(lastX - ix, lastZ - iz), endIndex
	end
	local startIndex1 = nil
	local startIndex2 = nil
	for i = 1, #boundaryLine do
		local pos = boundaryLine[i]
		if pos[1] == intersectData.psx and pos[2] == intersectData.psz then
			startIndex1 = i
		end
		if pos[1] == intersectData.pex and pos[2] == intersectData.pez then
			startIndex2 = i
		end
		table.insert(intersectionPositions, { intersectData.ix, intersectData.iz })
		if 1 < math.abs(startIndex1 - startIndex2) then
			if startIndex1 < startIndex2 then
				startIndex1 = startIndex1 + numPoints
			else
				startIndex2 = startIndex2 + numPoints
			end
		end
		if startIndex2 < startIndex1 then
			local distance1, endIndex1 = getDistanceToTargetPoint(startIndex1, 1, intersectData.ix, intersectData.iz)
			local distance2, endIndex2 = getDistanceToTargetPoint(startIndex2, -1, intersectData.ix, intersectData.iz)
			if distance1 < distance2 then
				for i = startIndex1, endIndex1 do
					local index = (i - 1) % numPoints + 1
					local pos = boundaryLine[index]
					local lastPos = intersectionPositions[#intersectionPositions]
					if pos[1] ~= lastPos[1] or pos[2] ~= lastPos[2] then
						table.insert(intersectionPositions, { pos[1], pos[2] })
					end
				end
			else
				for i = startIndex2, endIndex2, -1 do
					local index = (i - 1) % numPoints + 1
					local pos = boundaryLine[index]
					local lastPos = intersectionPositions[#intersectionPositions]
					if pos[1] ~= lastPos[1] or pos[2] ~= lastPos[2] then
						table.insert(intersectionPositions, { pos[1], pos[2] })
					end
				end
			end
		else
			local distance1, endIndex1 = getDistanceToTargetPoint(startIndex1, -1, intersectData.ix, intersectData.iz)
			local distance2, endIndex2 = getDistanceToTargetPoint(startIndex2, 1, intersectData.ix, intersectData.iz)
			if distance1 < distance2 then
				for i = startIndex1, endIndex1, -1 do
					local index = (i - 1) % numPoints + 1
					local pos = boundaryLine[index]
					local lastPos = intersectionPositions[#intersectionPositions]
					if pos[1] ~= lastPos[1] or pos[2] ~= lastPos[2] then
						table.insert(intersectionPositions, { pos[1], pos[2] })
					end
				end
			else
				for i = startIndex2, endIndex2 do
					local index = (i - 1) % numPoints + 1
					local pos = boundaryLine[index]
					local lastPos = intersectionPositions[#intersectionPositions]
					if pos[1] ~= lastPos[1] or pos[2] ~= lastPos[2] then
						table.insert(intersectionPositions, { pos[1], pos[2] })
					end
				end
			end
		end
		local lastPos = intersectionPositions[#intersectionPositions]
		if ix ~= lastPos[1] or iz ~= lastPos[2] then
			table.insert(intersectionPositions, { ix, iz })
		end
		return
	end
end
local tempData = { ix = 0, iz = 0, psx = 0, psz = 0, pex = 0, pez = 0, boundary = nil, isValid = false }
function AIFieldCourseTurnGenerator.doIntersectionChecks(intersectionPositions, sx, sz, ex, ez, turnData, intersectData)
	local dx = ex - sx
	local dz = ez - sz
	local length = MathUtil.vector2Length(dx, dz)
	if length == 0 then
		return true
	else
		dx = dx / length
		dz = dz / length
		if #intersectionPositions == 0 and intersectData == nil then
			sx = sx - dx * 0.001
			sz = sz - dz * 0.001
		end
		local intersect, ix, iz, psx, psz, pex, pez = FieldCourseUtil.getSegmentClosestBoundaryIntersection(sx + dx * 0.001, sz + dz * 0.001, ex + dx * 0.001, ez + dz * 0.001, turnData.validPathBoundary.boundaryLine)
		if intersect then
			local sideOffset = FieldCourseUtil.getDistanceToSegment(psx, psz, pex, pez, sx + dx * 0.001, sz + dz * 0.001)
			if 0.001 < sideOffset then
				if intersectData ~= nil and (intersectData.isValid and intersectData.boundary == turnData.validPathBoundary.boundaryLine) then
					if turnData.validPathBoundary == turnData.protectedBoundary then
						return false
					else
						AIFieldCourseTurnGenerator.generateTurnIntersectionPoints(turnData, intersectionPositions, intersectData, ix, iz, psx, psz, pex, pez)
						tempData.boundary = nil
						tempData.isValid = false
						return AIFieldCourseTurnGenerator.doIntersectionChecks(intersectionPositions, ix, iz, ex, ez, turnData)
					end
				end
				tempData.ix = ix
				tempData.iz = iz
				tempData.psx = psx
				tempData.psz = psz
				tempData.pex = pex
				tempData.pez = pez
				tempData.boundary = turnData.validPathBoundary.boundaryLine
				tempData.isValid = true
				return AIFieldCourseTurnGenerator.doIntersectionChecks(intersectionPositions, ix, iz, ex, ez, turnData, tempData)
			end
		else
			intersect = false
			ix = 0
			iz = 0
			psx = 0
			psz = 0
			pex = 0
			pez = 0
			local minDistance = math.huge
			local minDistanceIsland = nil
			for _, island in ipairs(turnData.islands) do
				local _intersect, _ix, _iz, _psx, _psz, _pex, _pez = FieldCourseUtil.getSegmentClosestBoundaryIntersection(sx + dx * 0.001, sz + dz * 0.001, ex + dx * 0.001, ez + dz * 0.001, island.validPathBoundary.boundaryLine)
				if _intersect then
					local sideOffset = FieldCourseUtil.getDistanceToSegment(_psx, _psz, _pex, _pez, sx + dx * 0.001, sz + dz * 0.001)
					if 0.001 < sideOffset then
						local distance = MathUtil.vector2Length(_ix - sx, _iz - sz)
						if distance < minDistance then
							minDistance = distance
							minDistanceIsland = island
							intersect = _intersect
							ix = _ix
							iz = _iz
							psx = _psx
							psz = _psz
							pex = _pex
							pez = _pez
						end
					end
				end
			end
			if intersect then
				if intersectData ~= nil and (intersectData.isValid and intersectData.boundary == minDistanceIsland.validPathBoundary.boundaryLine) then
					if minDistanceIsland.validPathBoundary == minDistanceIsland.protectedBoundary then
						return false
					else
						AIFieldCourseTurnGenerator.generateTurnIntersectionPoints(turnData, intersectionPositions, intersectData, ix, iz, psx, psz, pex, pez)
						tempData.boundary = nil
						tempData.isValid = false
						return AIFieldCourseTurnGenerator.doIntersectionChecks(intersectionPositions, ix, iz, ex, ez, turnData)
					end
				end
				tempData.ix = ix
				tempData.iz = iz
				tempData.psx = psx
				tempData.psz = psz
				tempData.pex = pex
				tempData.pez = pez
				tempData.boundary = minDistanceIsland.validPathBoundary.boundaryLine
				tempData.isValid = true
				return AIFieldCourseTurnGenerator.doIntersectionChecks(intersectionPositions, ix, iz, ex, ez, turnData, tempData)
			end
		end
		return true
	end
end
function AIFieldCourseTurnGenerator.getSkipToPositionIndex(intersectionPositions, startIndex, curX, curZ, turnData)
	for otherIndex = #intersectionPositions + 1, startIndex + 1, -1 do
		local otherPos = intersectionPositions[otherIndex]
		local ex = nil
		local ez = nil
		if otherPos == nil then
			ex = turnData.ex
			ez = turnData.ez
		else
			ex = otherPos[1]
			ez = otherPos[2]
		end
		local sx = curX
		local sz = curZ
		local dx = ex - sx
		local dz = ez - sz
		local length = MathUtil.vector2Length(dx, dz)
		if 0 < length then
			dx = dx / length
			dz = dz / length
			sx = sx + dx * 0.01
			sz = sz + dz * 0.01
			ex = ex - dx * 0.01
			ez = ez - dz * 0.01
			local intersect, _, _, _, _, _, _ = FieldCourseUtil.getSegmentClosestBoundaryIntersection(sx, sz, ex, ez, turnData.validPathBoundary.boundaryLine)
			if not intersect then
				if not FieldCourseUtil.getIsSegmentInsideBoundary(sx, sz, ex, ez, turnData.validPathBoundary.boundaryLine) then
					intersect = true
				end
				if not intersect then
					for _, island in ipairs(turnData.islands) do
						intersect, _, _, _, _, _, _ = FieldCourseUtil.getSegmentClosestBoundaryIntersection(sx, sz, ex, ez, island.validPathBoundary.boundaryLine)
						if intersect then
							break
						end
						if FieldCourseUtil.getIsSegmentInsideBoundary(sx, sz, ex, ez, island.validPathBoundary.boundaryLine) then
							intersect = true
							break
						end
					end
				end
			end
			if intersect then
				continue
			end
			return otherIndex
		end
	end
end
function AIFieldCourseTurnGenerator:getIntersectionTurn(turnData)
	local intersectionPositions = {}
	local startIsOutsideField = false
	local sx = turnData.sx
	local sz = turnData.sz
	local ex = turnData.ex
	local ez = turnData.ez
	if not FieldCourseUtil.getIsPointInsideBoundary(sx, sz, turnData.fieldRootBoundary.boundaryLine) then
		local intersect, ix, iz, _, _, _, _ = FieldCourseUtil.getSegmentClosestBoundaryIntersection(sx, sz, ex, ez, turnData.validPathBoundary.boundaryLine)
		if intersect then
			sx = ix
			sz = iz
			table.insert(intersectionPositions, { sx, sz })
		end
		startIsOutsideField = true
	end
	if not AIFieldCourseTurnGenerator.doIntersectionChecks(intersectionPositions, sx, sz, ex, ez, turnData) then
		return nil
	else
		local numIntersectionPositions = #intersectionPositions
		if 2 <= numIntersectionPositions then
			local index = 1
			while index < #intersectionPositions do
				local sx = intersectionPositions[index][1]
				local sz = intersectionPositions[index][2]
				local skipIndex = AIFieldCourseTurnGenerator.getSkipToPositionIndex(intersectionPositions, index, sx, sz, turnData)
				if skipIndex ~= nil then
					for indexToRemove = skipIndex - 1, index + 1, -1 do
						table.remove(intersectionPositions, indexToRemove)
					end
					numIntersectionPositions = #intersectionPositions
				end
				index = index + 1
			end
			local skipIndex = AIFieldCourseTurnGenerator.getSkipToPositionIndex(intersectionPositions, 0, turnData.sx, turnData.sz, turnData)
			if skipIndex ~= nil then
				for i = 1, skipIndex - 1 do
					table.remove(intersectionPositions, 1)
				end
				numIntersectionPositions = #intersectionPositions
			end
			if numIntersectionPositions <= 0 then
				return nil
			end
			local firstPosition = intersectionPositions[1]
			local dx = nil
			local dz = nil
			local secondPosition = intersectionPositions[2]
			if secondPosition ~= nil then
				dx = secondPosition[1] - firstPosition[1]
				dz = secondPosition[2] - firstPosition[2]
				local length = MathUtil.vector2Length(dx, dz)
				dx = dx / length
				dz = dz / length
			else
				dx = turnData.ex - firstPosition[1]
				dz = turnData.ez - firstPosition[2]
				local length = MathUtil.vector2Length(dx, dz)
				dx = dx / length
				dz = dz / length
			end
			local direction = 1
			if self.fieldCourseSettings.allowTurnBackward then
				local angleDifference = math.acos(MathUtil.dotProduct(turnData.sDirX, 0, turnData.sDirZ, dx, 0, dz))
				if 1.5707963267948966 < angleDifference then
					direction = -1
					dx = dx * direction
					dz = dz * direction
				end
			end
			local subTurnData = turnData:clone(true, false)
			subTurnData.ex = firstPosition[1]
			subTurnData.ez = firstPosition[2]
			subTurnData.eDirX = dx
			subTurnData.eDirZ = dz
			local oldIgnoreBoundaryIntersections = self.ignoreBoundaryIntersections
			self.ignoreBoundaryIntersections = self.ignoreBoundaryIntersections or startIsOutsideField
			local turn = self:getLowestCostTurnByData(subTurnData)
			if turn == nil then
				return nil
			end
			self.ignoreBoundaryIntersections = oldIgnoreBoundaryIntersections
			local lastX = firstPosition[1]
			local lastZ = firstPosition[2]
			local lastDx = dx
			local lastDz = dz
			local i = 1
			while i < numIntersectionPositions do
				local p1 = intersectionPositions[i]
				local p2 = intersectionPositions[i + 1]
				local p3 = intersectionPositions[i + 1]
				local p4 = intersectionPositions[i + 2]
				if p3 ~= nil and p4 ~= nil then
					local dx1 = p2[1] - lastX
					local dz1 = p2[2] - lastZ
					local l1 = MathUtil.vector2Length(dx1, dz1)
					dx1 = dx1 / l1
					dz1 = dz1 / l1
					local dx2 = p4[1] - p3[1]
					local dz2 = p4[2] - p3[2]
					local l2 = MathUtil.vector2Length(dx2, dz2)
					dx2 = dx2 / l2
					dz2 = dz2 / l2
					local searchPath = false
					if p2 == p3 then
						local ax1 = lastX + dz1 * turnData.turnRadius
						local az1 = lastZ - dx1 * turnData.turnRadius
						local ax2 = p2[1] + dz1 * turnData.turnRadius
						local az2 = p2[2] - dx1 * turnData.turnRadius
						local bx1 = p3[1] + dz2 * turnData.turnRadius
						local bz1 = p3[2] - dx2 * turnData.turnRadius
						local bx2 = p4[1] + dz2 * turnData.turnRadius
						local bz2 = p4[2] - dx2 * turnData.turnRadius
						local intersect, a, b = MathUtil.getLineSegmentsIntersectionParameter(ax1, az1, ax2, az2, bx1, bz1, bx2, bz2)
						local isLeft = true
						if not intersect then
							ax1 = lastX - dz1 * turnData.turnRadius
							az1 = lastZ + dx1 * turnData.turnRadius
							ax2 = p2[1] - dz1 * turnData.turnRadius
							az2 = p2[2] + dx1 * turnData.turnRadius
							bx1 = p3[1] - dz2 * turnData.turnRadius
							bz1 = p3[2] + dx2 * turnData.turnRadius
							bx2 = p4[1] - dz2 * turnData.turnRadius
							bz2 = p4[2] + dx2 * turnData.turnRadius
							intersect, a, b = MathUtil.getLineSegmentsIntersectionParameter(ax1, az1, ax2, az2, bx1, bz1, bx2, bz2)
							isLeft = false
						end
						if intersect then
							local sx = lastX + dx1 * a * l1
							local sz = lastZ + dz1 * a * l1
							local ex = p3[1] + dx2 * b * l2
							local ez = p3[2] + dz2 * b * l2
							local cx = ax1 + dx1 * a * l1
							local cz = az1 + dz1 * a * l1
							local yRot1 = MathUtil.getYRotationFromDirection(MathUtil.vector2Normalize(cx - sx, cz - sz))
							local yRot2 = MathUtil.getYRotationFromDirection(MathUtil.vector2Normalize(cx - ex, cz - ez))
							local angle = math.abs(yRot1 - MathUtil.normalizeRotationForShortestPath(yRot2, yRot1))
							local s = a * l1
							if 0 < s then
								table.insert(turn.segments, AIFieldCourseTurnSegment.new(s / turnData.turnRadius, AIFieldCourseTurnSegmentType.STRAIGHT, direction))
								table.insert(turn.segments, AIFieldCourseTurnSegment.new(angle, isLeft and AIFieldCourseTurnSegmentType.LEFT or AIFieldCourseTurnSegmentType.RIGHT, direction))
								lastX = ex
								lastZ = ez
								lastDx = dx2
								lastDz = dz2
							else
								searchPath = true
							end
						else
							searchPath = true
						end
					else
						searchPath = true
					end
					if searchPath then
						l1 = MathUtil.vector2Length(p2[1] - lastX, p2[2] - lastZ)
						table.insert(turn.segments, AIFieldCourseTurnSegment.new(l1 / turnData.turnRadius, AIFieldCourseTurnSegmentType.STRAIGHT, direction))
						local segTurnData = turnData:clone(false, false)
						segTurnData.sx = p2[1]
						segTurnData.sz = p2[2]
						segTurnData.sDirX, segTurnData.sDirZ = MathUtil.vector2Normalize(p2[1] - lastX, p2[2] - lastZ)
						segTurnData.ex = p3[1]
						segTurnData.ez = p3[2]
						segTurnData.eDirX, segTurnData.eDirZ = MathUtil.vector2Normalize(p4[1] - p3[1], p4[2] - p3[2])
						local subTurn = self:getLowestCostTurnByData(segTurnData)
						if subTurn ~= nil then
							for _, segment in ipairs(subTurn.segments) do
								table.insert(turn.segments, segment)
							end
							turn:updateLength()
							lastX = p3[1]
							lastZ = p3[2]
							lastDx, lastDz = MathUtil.vector2Normalize(p2[1] - p1[1], p2[2] - p1[2])
							turn:updateLength()
							i = i + 1
						else
							return nil
						end
					end
				end
				local l1 = MathUtil.vector2Length(p2[1] - lastX, p2[2] - lastZ)
				table.insert(turn.segments, AIFieldCourseTurnSegment.new(l1 / turnData.turnRadius, AIFieldCourseTurnSegmentType.STRAIGHT, direction))
				lastX = p3[1]
				lastZ = p3[2]
				lastDx, lastDz = MathUtil.vector2Normalize(p2[1] - p1[1], p2[2] - p1[2])
			end
			local endTurnData = turnData:clone(false, true)
			endTurnData.sx = lastX
			endTurnData.sz = lastZ
			endTurnData.sDirX = lastDx * direction
			endTurnData.sDirZ = lastDz * direction
			local subTurn = self:getLowestCostTurnByData(endTurnData)
			if subTurn ~= nil then
				for _, segment in ipairs(subTurn.segments) do
					table.insert(turn.segments, segment)
				end
				turn.turnData.segment2 = subTurn.turnData.segment2
				turn.turnData.segment2Direction = subTurn.turnData.segment2Direction
				turn:updateLength()
				turn:updateCost()
				if numIntersectionPositions == 1 then
					local directTurn = self:getLowestCostTurnByData(turnData)
					if directTurn ~= nil and (directTurn.numBoundaryIntersections == 0 and directTurn:getOverallCost() < turn:getOverallCost()) then
						return directTurn
					end
				end
				turn.turnData = turnData:clone()
				return turn
			else
				return nil
			end
		end
		return nil
	end
end
function AIFieldCourseTurnGenerator:getBestTurnByTurnData(turnData)
	local turn = self:getIntersectionTurn(turnData)
	if turn ~= nil then
		return turn
	else
		turn = self:getLowestCostTurnByData(turnData)
		return turn
	end
end
function AIFieldCourseTurnGenerator:generateTurnsByData(turns, turnData)
	local dubinsPath = DubinsPath.new(turnData, self.forcedDrivingDirection)
	dubinsPath:generate(function(turn)
		table.insert(turns, turn)
		if dp ~= nil then
			table.insert(self.alternativeTurnSegments, turn)
		end
	end)
	if turnData.canTurnBackward then
		local reedsSheppPath = ReedsSheppPath.new(turnData, self.forcedDrivingDirection)
		reedsSheppPath:generate(function(turn)
			table.insert(turns, turn)
			if dp ~= nil then
				table.insert(self.alternativeTurnSegments, turn)
			end
		end)
	end
end
function AIFieldCourseTurnGenerator:getLowestCostTurnByData(turnData)
	if not self.ignoreBoundaryIntersections and (AIFieldCourseTurnGenerator.isPositionOutsideField(turnData.sx, turnData.sz, turnData, true, self.allowProtectedBoundary) or AIFieldCourseTurnGenerator.isPositionOutsideField(turnData.ex, turnData.ez, turnData, true, self.allowProtectedBoundary)) then
		return nil
	end
	local turns = {}
	self:generateTurnsByData(turns, turnData)
	if self.maxOffset == nil and (not turnData.canTurnBackward and turnData.allowStraightReversing) then
		local offsetTurnData = turnData:offset(0, 2.5)
		self:generateTurnsByData(turns, offsetTurnData)
	end
	if self.maxOffset ~= nil then
		local offsetStep = 3
		for offset = 3, self.maxOffset, 3 do
			local startOffset = offset
			local endOffset = offset
			if not turnData.canTurnBackward and not turnData.allowStraightReversing then
				if turnData.segment1 ~= nil then
					startOffset = math.min(startOffset, turnData.segment1.length - (turnData.segment1.lastStartOffset or 0))
				end
				if turnData.segment2 ~= nil then
					endOffset = math.min(endOffset, turnData.segment2.length - (turnData.segment2.lastEndOffset or 0))
				end
			end
			local offsetTurnData = turnData:offset(startOffset, endOffset)
			self:generateTurnsByData(turns, offsetTurnData)
		end
	end
	AIFieldCourseTurnGenerator.findCommonTurnRadiusIntersection(function(startOffset, endOffset, adjustedTurnRadius)
		if turnData.turnRadius < startOffset or turnData.turnRadius < endOffset then
			return
		end
		local offsetTurnData = turnData:offset(startOffset, endOffset)
		if not turnData.canTurnBackward and not turnData.allowStraightReversing then
			if turnData.segment1.length < -startOffset then
				return
			end
			if turnData.segment2.length < endOffset then
				return
			end
		end
		offsetTurnData.turnRadius = adjustedTurnRadius
		self:generateTurnsByData(turns, offsetTurnData)
	end, turnData)
	local minCostTurn = nil
	local minCost = math.huge
	for _, turn in ipairs(turns) do
		turn:updateCost(self.allowProtectedBoundary, self.preferOneDrivingDirection)
		local cost = turn:getOverallCost()
		if cost < minCost and (turn.numBoundaryIntersections == 0 or self.ignoreBoundaryIntersections) then
			minCost = cost
			minCostTurn = turn
		end
	end
	return minCostTurn, turns
end
function AIFieldCourseTurnGenerator.getSegmentMinOffset(startPosition, segment, segmentDirection, turnData, offsetLimit)
	local numPositions = #segment.positions
	if startPosition then
		local pos1 = segment.positions[1]
		local pos2 = segment.positions[2]
		if 0 < segmentDirection then
			pos1 = segment.positions[numPositions]
			pos2 = segment.positions[numPositions - 1]
		end
		local dx, dz = MathUtil.vector2Normalize(pos1[1] - pos2[1], pos1[2] - pos2[2])
		local intersect, ix, iz = FieldCourseUtil.getSegmentClosestBoundaryIntersection(pos1[1], pos1[2], pos1[1] + dx * offsetLimit, pos1[2] + dz * offsetLimit, turnData.protectedBoundary.boundaryLine)
		if intersect then
			local distanceToIntersection = MathUtil.vector2Length(ix - pos1[1], iz - pos1[2]) + 0.1
			return -distanceToIntersection
		end
	else
		local startIndex = 1
		local limit = numPositions - 1
		local direction = 1
		if segmentDirection < 0 then
			startIndex = numPositions
			limit = 2
			direction = -1
		end
		local distanceToIntersection = 0
		for i = startIndex, limit, direction do
			local pos = segment.positions[i]
			local nextPos = segment.positions[i + direction]
			if AIFieldCourseTurnGenerator.isPositionOutsideField(pos[1], pos[2], turnData, true) then
				if not AIFieldCourseTurnGenerator.isPositionOutsideField(nextPos[1], nextPos[2], turnData, true) then
					local intersect, ix, iz = FieldCourseUtil.getSegmentClosestBoundaryIntersection(pos[1], pos[2], nextPos[1], nextPos[2], turnData.protectedBoundary.boundaryLine)
					if intersect then
						distanceToIntersection = distanceToIntersection + MathUtil.vector2Length(ix - pos[1], iz - pos[2])
						return math.min(distanceToIntersection, offsetLimit)
					end
				end
				distanceToIntersection = distanceToIntersection + MathUtil.vector2Length(nextPos[1] - pos[1], nextPos[2] - pos[2])
			end
		end
	end
	return nil
end
