TrapezoidDecomposition = {}
local TrapezoidDecomposition_mt = Class(TrapezoidDecomposition)
TrapezoidDecomposition.MAX_MERGE_ANGLE = 4.1887902047863905
TrapezoidDecomposition.MAX_ORIENTATION_MERGE_DIFFERENCE = 0.6108652381980153
TrapezoidDecomposition.MIN_MERGE_LENGTH_PERCENTAGE = 0.1
TrapezoidDecomposition.OPTIMAL_ANGLE_STEPS = 16
TrapezoidDecomposition.COLORS = { { 0.7079, 0.6987, 0.2864 }, { 0.9628, 0.5908, 0.4254 }, { 0.078, 0.3129, 0.7987 }, { 0.0244, 0.6147, 0.5057 }, { 0.2402, 0.7016, 0.8469 }, { 0.2624, 0.4573, 0.5326 }, { 0.22, 0.859, 0.6861 }, { 0.7581, 0.1639, 0.3565 }, { 0.0544, 0.6152, 0.1018 }, { 0.747, 0.2893, 0.3946 } }
function TrapezoidDecomposition.new(boundary, singleGroupMode)
	local self = setmetatable({}, TrapezoidDecomposition_mt)
	self.boundary = boundary
	self.trapezoidLines = {}
	self.trapezoids = {}
	self.trapezoidGroups = {}
	self.numGroups = {}
	self.singleGroupMode = Utils.getNoNil(singleGroupMode, false)
	self.step = 0
	return self
end
function TrapezoidDecomposition:update(dt, frameBudget)
	local startTime = getTimeSec()
	while getTimeSec() - startTime < frameBudget do
		if self.step == 1 then
			self:generateVerticalLines()
		elseif self.step == 2 then
			self:generateTrapezoids()
		elseif self.step == 3 then
			self:assignMergeGroups()
		elseif self.step == 4 then
			self:generateGroups()
		elseif self.step == 5 then
			self:mergeGroupsBySize()
		elseif self.step == 6 then
			self:mergeGroupsByWorkDirection()
		elseif self.step == 7 then
			self:mergeGroupsByCost()
		elseif self.step == 8 then
			self:updateGroups()
			return false
		end
		self.step = self.step + 1
	end
	return true
end
function TrapezoidDecomposition:generateVerticalLines()
	self.trapezoidLines = {}
	local sortedBoundaryPositions = table.clone(self.boundary)
	table.remove(sortedBoundaryPositions, #sortedBoundaryPositions)
	table.sort(sortedBoundaryPositions, function(a, b)
		return a[1] < b[1]
	end)
	for posIndex = 1, #sortedBoundaryPositions do
		local foundBoundaryIntersection = false
		local position = sortedBoundaryPositions[posIndex]
		local closestIntersectionX, closestIntersectionZ = TrapezoidDecomposition.getClosestIntersectionWithBoundary(position, 0, 1, self.boundary)
		if closestIntersectionX ~= nil then
			table.insert(self.trapezoidLines, { { position[1], closestIntersectionZ }, { position[1], position[2] } })
			foundBoundaryIntersection = true
		end
		closestIntersectionX, closestIntersectionZ = TrapezoidDecomposition.getClosestIntersectionWithBoundary(position, 0, -1, self.boundary)
		if closestIntersectionX ~= nil then
			table.insert(self.trapezoidLines, { { position[1], position[2] }, { position[1], closestIntersectionZ } })
			foundBoundaryIntersection = true
		end
		if foundBoundaryIntersection then
			continue
		end
		local lastPosition = sortedBoundaryPositions[posIndex - 1]
		local nextPosition = sortedBoundaryPositions[posIndex + 1]
		if lastPosition ~= nil and math.abs(lastPosition[1] - position[1]) < 0.00001 then
			if lastPosition[2] < position[2] then
				table.insert(self.trapezoidLines, { { position[1], position[2] }, { position[1], lastPosition[2] } })
			else
				table.insert(self.trapezoidLines, { { position[1], lastPosition[2] }, { position[1], position[2] } })
			end
			foundBoundaryIntersection = true
		end
		if nextPosition ~= nil and math.abs(nextPosition[1] - position[1]) < 0.00001 then
			if nextPosition[2] < position[2] then
				table.insert(self.trapezoidLines, { { position[1], position[2] }, { position[1], nextPosition[2] } })
			else
				table.insert(self.trapezoidLines, { { position[1], nextPosition[2] }, { position[1], position[2] } })
			end
			foundBoundaryIntersection = true
		end
		if foundBoundaryIntersection then
			continue
		end
		local point = { position[1], position[2] }
		table.insert(self.trapezoidLines, { point, point })
	end
end
function TrapezoidDecomposition:generateTrapezoids()
	self.trapezoids = {}
	local generateTrapezoidFromLine = function(rootLine, startIndex, minNeigboringCheckIndex, maxNeigboringCheckIndex)
		for nextIndex = startIndex, #self.trapezoidLines do
			local nextLine = self.trapezoidLines[nextIndex]
			if rootLine[1][1] < nextLine[1][1] then
				local connectionAllowed = true
				if minNeigboringCheckIndex ~= nil and maxNeigboringCheckIndex ~= nil then
					for i = minNeigboringCheckIndex, maxNeigboringCheckIndex do
						if not TrapezoidDecomposition.getIsNeighbouringLine(self.trapezoidLines[i], nextLine, self.boundary, self.trapezoidLines) then
							connectionAllowed = false
							break
						end
					end
				end
				if connectionAllowed and TrapezoidDecomposition.getIsNeighbouringLine(rootLine, nextLine, self.boundary, self.trapezoidLines) then
					local trapezoid = {}
					trapezoid.line1 = rootLine
					trapezoid.line2 = nextLine
					trapezoid.groupId = 0
					trapezoid.size = TrapezoidDecomposition.getTrapezoidSize(rootLine, nextLine)
					local sameXPosLineIndex = nextIndex + 1
					while true do
						local sameXPosLine = self.trapezoidLines[sameXPosLineIndex]
						if sameXPosLine == nil or nextLine[1][1] < sameXPosLine[1][1] then
							break
						end
						if TrapezoidDecomposition.getIsNeighbouringLine(rootLine, sameXPosLine, self.boundary, self.trapezoidLines) then
							local topVertex = { trapezoid.line2[1][1], math.max(trapezoid.line2[1][2], sameXPosLine[1][2]) }
							local bottomVertex = { trapezoid.line2[2][1], math.min(trapezoid.line2[2][2], sameXPosLine[2][2]) }
							trapezoid.line2 = { topVertex, bottomVertex }
						end
						sameXPosLineIndex = sameXPosLineIndex + 1
					end
					table.insert(self.trapezoids, trapezoid)
					return startIndex, true
				end
			end
		end
		return startIndex, false
	end
	local lineIndex = 1
	local doNotMergeUntilIndex = 0
	while true do
		local line1 = self.trapezoidLines[lineIndex]
		if line1 == nil then
			break
		end
		local newLine = nil
		local newLineEndIndex = nil
		for nextIndex = lineIndex + 1, #self.trapezoidLines do
			if doNotMergeUntilIndex < nextIndex then
				local nextLine = self.trapezoidLines[nextIndex]
				if math.abs(nextLine[1][1] - self.trapezoidLines[lineIndex][1][1]) < 0.0001 then
					if newLine == nil then
						newLine = { { line1[1][1], line1[1][2] }, { line1[2][1], line1[2][2] } }
					end
					newLine[1][2] = math.max(newLine[1][2], nextLine[1][2])
					newLine[2][2] = math.min(newLine[2][2], nextLine[2][2])
					newLineEndIndex = nextIndex
				end
			end
		end
		if newLine ~= nil then
			local newLineIndex, success = generateTrapezoidFromLine(newLine, newLineEndIndex + 1, lineIndex, newLineEndIndex)
			if success then
				lineIndex = newLineIndex
			else
				lineIndex = generateTrapezoidFromLine(line1, lineIndex + 1)
				doNotMergeUntilIndex = newLineIndex
			end
		else
			lineIndex = generateTrapezoidFromLine(line1, lineIndex + 1)
		end
	end
	for trapezoidIndex = #self.trapezoids, 1, -1 do
		local trapezoid = self.trapezoids[trapezoidIndex]
		if math.abs(trapezoid.line1[1][1] - trapezoid.line2[1][1]) < 0.0000001 then
			table.remove(self.trapezoids, trapezoidIndex)
		end
	end
end
function TrapezoidDecomposition.getCanTrapezoidsBeMerged(trapezoid1, trapezoid2)
	local getAngleFromPoints = function(p1, p2, p3, p4)
		local x1 = p1[1]
		local z1 = p1[2]
		local x2 = p2[1]
		local z2 = p2[2]
		local x3 = p3[1]
		local z3 = p3[2]
		local x4 = p4[1]
		local z4 = p4[2]
		local dir1X, dir1Z = MathUtil.vector2Normalize(x1 - x2, z1 - z2)
		local dir2X, dir2Z = MathUtil.vector2Normalize(x3 - x2, z3 - z2)
		local dir3X = x4 - x2
		local dir3Z = z4 - z2
		local length3 = MathUtil.vector2Length(dir3X, dir3Z)
		if length3 == 0 then
			return math.huge
		else
			dir3X = dir3X / length3
			dir3Z = dir3Z / length3
			local dot1 = MathUtil.dotProduct(dir1X, 0, dir1Z, dir3X, 0, dir3Z)
			local dot2 = MathUtil.dotProduct(dir2X, 0, dir2Z, dir3X, 0, dir3Z)
			local angle = math.acos(dot1) + math.acos(dot2)
			return angle
		end
	end
	if TrapezoidDecomposition.MAX_MERGE_ANGLE < getAngleFromPoints(trapezoid1.line1[1], trapezoid1.line2[1], trapezoid2.line2[1], trapezoid1.line2[2]) then
		return false
	elseif TrapezoidDecomposition.MAX_MERGE_ANGLE < getAngleFromPoints(trapezoid2.line2[2], trapezoid1.line2[2], trapezoid1.line1[2], trapezoid1.line2[1]) then
		return false
	else
		return true
	end
end
local sortLineFunction = function(a, b)
	return b[2] < a[2]
end
function TrapezoidDecomposition:generateBoundaryByGroupId(groupId, additionalGroupId)
	additionalGroupId = additionalGroupId or -1
	local isPointIdentical = function(p1, p2)
		if math.abs(p1[1] - p2[1]) < 0.0000001 and math.abs(p1[2] - p2[2]) < 0.0000001 then
			return true
		end
		return false
	end
	local invalidPoints = {}
	local detectInvalidPoints = function(trapezoidIndex, line)
		for i = 1, 2 do
			local point1 = line[i]
			local isValid = false
			for trapezoidIndex2 = 1, #self.trapezoids do
				if trapezoidIndex == trapezoidIndex2 then
					continue
				end
				local trapezoid2 = self.trapezoids[trapezoidIndex2]
				for j = 1, 2 do
					local p2 = trapezoid2.line1[j]
					if math.abs(point1[1] - p2[1]) < 0.0000001 then
						if math.abs(point1[2] - p2[2]) < 0.0000001 and true or false then
							isValid = true
							break
						end
						local p2 = trapezoid2.line2[j]
						if math.abs(point1[1] - p2[1]) < 0.0000001 and (math.abs(point1[2] - p2[2]) < 0.0000001 and true or false) then
							isValid = true
							break
						end
					end
				end
				if not isValid then
					continue
				end
				if not isValid then
					table.insert(invalidPoints, point1)
				end
			end
		end
	end
	local boundaryPositions = {}
	for trapezoidIndex = 1, #self.trapezoids do
		local trapezoid = self.trapezoids[trapezoidIndex]
		if trapezoid.groupId == groupId or trapezoid.groupId == additionalGroupId then
			detectInvalidPoints(trapezoidIndex, trapezoid.line1)
			detectInvalidPoints(trapezoidIndex, trapezoid.line2)
		end
	end
	for ti = 1, #self.trapezoids do
		local trapezoid = self.trapezoids[ti]
		if trapezoid.groupId == groupId or trapezoid.groupId == additionalGroupId then
			local points1 = nil
			for _, invalidPoint in ipairs(invalidPoints) do
				if math.abs(trapezoid.line1[1][1] - invalidPoint[1]) < 0.0001 then
					local alpha = MathUtil.inverseLerp(trapezoid.line1[1][2], trapezoid.line1[2][2], invalidPoint[2])
					if 0 < alpha and alpha < 1 then
						if points1 == nil then
							points1 = {}
						end
						table.insert(points1, table.clone(invalidPoint))
					end
				end
			end
			local points2 = nil
			for _, invalidPoint in ipairs(invalidPoints) do
				if math.abs(trapezoid.line2[1][1] - invalidPoint[1]) < 0.0001 then
					local alpha = MathUtil.inverseLerp(trapezoid.line2[1][2], trapezoid.line2[2][2], invalidPoint[2])
					if 0 < alpha and alpha < 1 then
						if points2 == nil then
							points2 = {}
						end
						table.insert(points2, table.clone(invalidPoint))
					end
				end
			end
			if points1 ~= nil then
				table.insert(points1, trapezoid.line1[1])
				table.insert(points1, trapezoid.line1[2])
				table.sort(points1, sortLineFunction)
				trapezoid.points1 = points1
			else
				trapezoid.points1 = trapezoid.line1
			end
			if points2 ~= nil then
				table.insert(points2, trapezoid.line2[1])
				table.insert(points2, trapezoid.line2[2])
				table.sort(points2, sortLineFunction)
				trapezoid.points2 = table.clone(points2, math.huge)
			else
				trapezoid.points2 = table.clone(trapezoid.line2, math.huge)
			end
		end
	end
	local function getNextPoint(index, p1, p2, skipAdd)
		if math.abs(p[1] - startPoint[1]) < 0.0000001 then
			if (math.abs(p[2] - startPoint[2]) < 0.0000001 and true or false) and 0 < #boundaryPositions then
				return
			end
			if not skipAdd then
				table.insert(boundaryPositions, p)
			end
			p.detected = true
			for ti = 1, #self.trapezoids do
				if ti ~= index then
					local trapezoid = self.trapezoids[ti]
					if trapezoid.groupId == groupId or trapezoid.groupId == additionalGroupId then
						for i = 1, #trapezoid.points1 do
							local p2 = trapezoid.points1[i]
							if math.abs(p1[1] - p2[1]) < 0.0000001 and (math.abs(p1[2] - p2[2]) < 0.0000001 and true or false) then
								if trapezoid.points1[i].detected then
									continue
								end
								return getNextPoint(ti, trapezoid.points1[i], startPoint, true)
							end
						end
						for i = 1, #trapezoid.points2 do
							local p2 = trapezoid.points2[i]
							if math.abs(p1[1] - p2[1]) < 0.0000001 and (math.abs(p1[2] - p2[2]) < 0.0000001 and true or false) then
								if trapezoid.points2[i].detected then
									continue
								end
								return getNextPoint(ti, trapezoid.points2[i], startPoint, true)
							end
						end
					end
				end
			end
			local trapezoid = self.trapezoids[index]
			for i = 1, #trapezoid.points1 do
				local nextPoint = trapezoid.points1[i + 1]
				if nextPoint == nil then
					nextPoint = trapezoid.points2[#trapezoid.points2]
				end
				if trapezoid.points1[i] == p then
					if nextPoint.detected then
						continue
					end
					return getNextPoint(index, nextPoint, startPoint)
				end
			end
			for i = #trapezoid.points2, 1, -1 do
				local nextPoint = trapezoid.points2[i - 1]
				if nextPoint == nil then
					nextPoint = trapezoid.points1[1]
				end
				if trapezoid.points2[i] == p then
					if nextPoint.detected then
						continue
					end
					return getNextPoint(index, nextPoint, startPoint)
				end
			end
			return nil
		end
	end
	for index = 1, #self.trapezoids do
		local trapezoid = self.trapezoids[index]
		if trapezoid.groupId == groupId or trapezoid.groupId == additionalGroupId then
			getNextPoint(index, trapezoid.points1[1], trapezoid.points1[1])
		else
		end
		for index = 1, #self.trapezoids do
			local trapezoid = self.trapezoids[index]
			if trapezoid.groupId == groupId or trapezoid.groupId == additionalGroupId then
				for i = 1, #trapezoid.points1 do
					trapezoid.points1[i].detected = nil
				end
				for i = 1, #trapezoid.points2 do
					trapezoid.points2[i].detected = nil
				end
			end
		end
		if 0 < #boundaryPositions then
			table.insert(boundaryPositions, table.clone(boundaryPositions[1]))
			return boundaryPositions
		else
			return nil
		end
	end
end
function TrapezoidDecomposition:getSizeByGroupId(groupId)
	local size = 0
	for index = 1, #self.trapezoids do
		local trapezoid = self.trapezoids[index]
		if trapezoid.groupId == groupId then
			size = size + trapezoid.size
		end
	end
	return size
end
function TrapezoidDecomposition:getLongestLineByGroupId(groupId)
	local longestLine = 0
	for index = 1, #self.trapezoids do
		local trapezoid = self.trapezoids[index]
		if trapezoid.groupId == groupId then
			local length1 = MathUtil.vector2Length(trapezoid.line1[1][1] - trapezoid.line1[2][1], trapezoid.line1[1][2] - trapezoid.line1[2][2])
			local length2 = MathUtil.vector2Length(trapezoid.line2[1][1] - trapezoid.line2[2][1], trapezoid.line2[1][2] - trapezoid.line2[2][2])
			longestLine = math.max(longestLine, length1, length2)
		end
	end
	return longestLine
end
function TrapezoidDecomposition:assignMergeGroups()
	local isOverlapping = function(line1, line2)
		if math.abs(line1[1][1] - line2[1][1]) < 0.0001 and (line2[1][2] >= line1[1][2] or not (line1[1][2] < line2[2][2])) then
			if line2[1][2] < line1[2][2] and line1[2][2] < line2[2][2] then
				return true
			end
			return false
		end
	end
	local nextId = 1
	for index1 = 1, #self.trapezoids do
		local isStandalone = true
		for index2 = index1 + 1, #self.trapezoids do
			local trapezoid1 = self.trapezoids[index1]
			local trapezoid2 = self.trapezoids[index2]
			if (trapezoid1.line2 == trapezoid2.line1 or isOverlapping(trapezoid1.line2, trapezoid2.line1)) and TrapezoidDecomposition.getCanTrapezoidsBeMerged(trapezoid1, trapezoid2) then
				if trapezoid1.groupId == 0 then
					trapezoid1.groupId = nextId
					nextId = nextId + 1
				end
				trapezoid2.groupId = trapezoid1.groupId
				isStandalone = false
			end
		end
		if isStandalone then
			local trapezoid1 = self.trapezoids[index1]
			if trapezoid1.groupId == 0 then
				trapezoid1.groupId = nextId
				nextId = nextId + 1
			end
		end
	end
	self.numGroups = nextId - 1
end
function TrapezoidDecomposition:generateGroups()
	self.trapezoidGroups = {}
	for groupId = 1, self.numGroups do
		local boundaryPositions = self:generateBoundaryByGroupId(groupId)
		if boundaryPositions ~= nil then
			local simplifiedBoundary = table.clone(boundaryPositions)
			FieldCourseUtil.douglasPeucker(simplifiedBoundary, 0.01)
			local sumX = 0
			local sumZ = 0
			local numPositions = #boundaryPositions
			for i = 1, numPositions do
				sumX = sumX + boundaryPositions[i][1]
				sumZ = sumZ + boundaryPositions[i][2]
			end
			local centerX = sumX / numPositions
			local centerZ = sumZ / numPositions
			local yRot = BoundaryLineGenerationTask.getOptimalBoundaryAngle(centerX, centerZ, simplifiedBoundary, TrapezoidDecomposition.OPTIMAL_ANGLE_STEPS)
			local group = {}
			group.positions = boundaryPositions
			group.simplifiedBoundary = simplifiedBoundary
			group.size = self:getSizeByGroupId(groupId)
			group.longestLine = self:getLongestLineByGroupId(groupId)
			group.center = { centerX, centerZ }
			group.yRot = yRot
			group.direction = { MathUtil.getDirectionFromYRotation(group.yRot) }
			self.trapezoidGroups[groupId] = group
		end
	end
end
function TrapezoidDecomposition:mergeGroups(groupId1, groupId2)
	local group1 = self.trapezoidGroups[groupId1]
	local group2 = self.trapezoidGroups[groupId2]
	local color = nil
	for indexToChange = 1, #self.trapezoids do
		local trapezoidToChange = self.trapezoids[indexToChange]
		if trapezoidToChange.groupId == groupId2 or trapezoidToChange.groupId == groupId1 then
			if color == nil then
				color = trapezoidToChange.color
			end
			trapezoidToChange.groupId = groupId2
			trapezoidToChange.color = color
		end
	end
	group2.center[1] = (group2.center[1] + group1.center[1]) * 0.5
	group2.center[2] = (group2.center[2] + group1.center[2]) * 0.5
	if group2.size < group1.size then
		group2.yRot = group1.yRot
		group2.direction = group1.direction
	end
	group2.size = group2.size + group1.size
	group2.longestLine = math.max(group2.longestLine, group1.longestLine)
	group2.boundaryDirty = true
	self.trapezoidGroups[groupId1] = nil
end
function TrapezoidDecomposition:mergeGroupsBySize()
	for index1 = 1, #self.trapezoids do
		for index2 = index1 + 1, #self.trapezoids do
			local trapezoid1 = self.trapezoids[index1]
			local trapezoid2 = self.trapezoids[index2]
			if trapezoid1.groupId == trapezoid2.groupId or self.trapezoidGroups[trapezoid1.groupId] == nil or self.trapezoidGroups[trapezoid2.groupId] == nil then
				continue
			end
			if math.abs(trapezoid1.line2[1][1] - trapezoid2.line1[1][1]) < 0.0001 then
				if self.singleGroupMode then
					self:mergeGroups(trapezoid1.groupId, trapezoid2.groupId)
				else
					local size1 = self.trapezoidGroups[trapezoid1.groupId].size
					local size2 = self.trapezoidGroups[trapezoid2.groupId].size
					if size1 / size2 < 0.2 then
						self:mergeGroups(trapezoid1.groupId, trapezoid2.groupId)
					elseif size2 / size1 < 0.2 then
						self:mergeGroups(trapezoid2.groupId, trapezoid1.groupId)
					end
				end
			end
		end
	end
end
function TrapezoidDecomposition:mergeGroupsByWorkDirection()
	for index1 = 1, #self.trapezoids do
		for index2 = index1 + 1, #self.trapezoids do
			local trapezoid1 = self.trapezoids[index1]
			local trapezoid2 = self.trapezoids[index2]
			if trapezoid1.groupId == trapezoid2.groupId or self.trapezoidGroups[trapezoid1.groupId] == nil or self.trapezoidGroups[trapezoid2.groupId] == nil then
				continue
			end
			if math.abs(trapezoid1.line2[1][1] - trapezoid2.line1[1][1]) < 0.0001 then
				local yRot1 = self.trapezoidGroups[trapezoid1.groupId].yRot
				local yRot2 = self.trapezoidGroups[trapezoid2.groupId].yRot
				local diff = math.abs(yRot1 - yRot2)
				if diff < TrapezoidDecomposition.MAX_ORIENTATION_MERGE_DIFFERENCE or 6.283185307179586 - TrapezoidDecomposition.MAX_ORIENTATION_MERGE_DIFFERENCE < diff or 3.141592653589793 - TrapezoidDecomposition.MAX_ORIENTATION_MERGE_DIFFERENCE < diff and diff < 3.141592653589793 + TrapezoidDecomposition.MAX_ORIENTATION_MERGE_DIFFERENCE then
					self:mergeGroups(trapezoid2.groupId, trapezoid1.groupId)
				end
			end
		end
	end
end
function TrapezoidDecomposition:mergeGroupsByCost()
	for index1 = 1, #self.trapezoids do
		for index2 = index1 + 1, #self.trapezoids do
			local trapezoid1 = self.trapezoids[index1]
			local trapezoid2 = self.trapezoids[index2]
			if trapezoid1.groupId == trapezoid2.groupId then
				continue
			end
			if math.abs(trapezoid1.line2[1][1] - trapezoid2.line1[1][1]) < 0.0001 then
				local sharedLineLength = MathUtil.vector2Length(trapezoid1.line2[1][1] - trapezoid1.line2[2][1], trapezoid1.line2[1][2] - trapezoid1.line2[2][2])
				local sharedLinePct1 = sharedLineLength / self.trapezoidGroups[trapezoid1.groupId].longestLine
				local sharedLinePct2 = sharedLineLength / self.trapezoidGroups[trapezoid2.groupId].longestLine
				if TrapezoidDecomposition.MIN_MERGE_LENGTH_PERCENTAGE < sharedLinePct1 or TrapezoidDecomposition.MIN_MERGE_LENGTH_PERCENTAGE < sharedLinePct2 then
					local group1 = self.trapezoidGroups[trapezoid1.groupId]
					local group2 = self.trapezoidGroups[trapezoid2.groupId]
					if group1 == nil or group2 == nil then
						continue
					end
					local combinedBoundaryPositions = self:generateBoundaryByGroupId(trapezoid1.groupId, trapezoid2.groupId)
					local boundaryPositions1 = self:generateBoundaryByGroupId(trapezoid1.groupId)
					local boundaryPositions2 = self:generateBoundaryByGroupId(trapezoid2.groupId)
					if combinedBoundaryPositions == nil or boundaryPositions1 == nil or boundaryPositions2 == nil then
						continue
					end
					local numLinesGroup1 = BoundaryLineGenerationTask.getNumLinesByAngle(group1.center[1], group1.center[2], boundaryPositions1, group1.yRot)
					local numLinesGroup2 = BoundaryLineGenerationTask.getNumLinesByAngle(group2.center[1], group2.center[2], boundaryPositions2, group2.yRot)
					local numLinesCombined = BoundaryLineGenerationTask.getNumLinesByAngle(group2.center[1], group2.center[2], combinedBoundaryPositions, group1.yRot)
					if math.min(numLinesGroup1, numLinesGroup2) * 0.2 < numLinesGroup1 + numLinesGroup2 - numLinesCombined then
						self:mergeGroups(trapezoid2.groupId, trapezoid1.groupId)
					else
						numLinesCombined = BoundaryLineGenerationTask.getNumLinesByAngle(group2.center[1], group2.center[2], combinedBoundaryPositions, group2.yRot)
						if math.min(numLinesGroup1, numLinesGroup2) * 0.2 < numLinesGroup1 + numLinesGroup2 - numLinesCombined then
							self:mergeGroups(trapezoid1.groupId, trapezoid2.groupId)
						end
					end
				end
			end
		end
	end
end
function TrapezoidDecomposition:updateGroups()
	for groupId, group in pairs(self.trapezoidGroups) do
		if group.boundaryDirty then
			group.positions = self:generateBoundaryByGroupId(groupId)
			group.simplifiedBoundary = table.clone(group.positions)
			FieldCourseUtil.douglasPeucker(group.simplifiedBoundary, 0.01)
			group.boundaryDirty = false
		end
		local yRot = BoundaryLineGenerationTask.getOptimalBoundaryAngle(group.center[1], group.center[2], group.simplifiedBoundary, TrapezoidDecomposition.OPTIMAL_ANGLE_STEPS)
		group.yRot = yRot
		group.direction[1], group.direction[2] = MathUtil.getDirectionFromYRotation(group.yRot)
	end
end
function TrapezoidDecomposition:getGroups()
	return self.trapezoidGroups
end
function TrapezoidDecomposition:draw()
	local y = 0
	for _, trapezoid in ipairs(self.trapezoids) do
		y = math.max(y, getTerrainHeightAtWorldPos(g_terrainNode, trapezoid.line1[1][1], 0, trapezoid.line1[1][2]))
		y = math.max(y, getTerrainHeightAtWorldPos(g_terrainNode, trapezoid.line2[1][1], 0, trapezoid.line2[1][2]))
		y = math.max(y, getTerrainHeightAtWorldPos(g_terrainNode, trapezoid.line1[2][1], 0, trapezoid.line1[2][2]))
		y = math.max(y, getTerrainHeightAtWorldPos(g_terrainNode, trapezoid.line2[2][1], 0, trapezoid.line2[2][2]))
	end
	y = y + 0.5
	for _, trapezoid in ipairs(self.trapezoids) do
		local color = TrapezoidDecomposition.COLORS[trapezoid.groupId % #TrapezoidDecomposition.COLORS + 1]
		local vtx1 = trapezoid.line1[1]
		local vtx2 = trapezoid.line2[1]
		local vtx3 = trapezoid.line1[2]
		local vtx4 = trapezoid.line2[2]
		drawDebugTriangle(vtx1[1], y + 0.05, vtx1[2], vtx2[1], y + 0.05, vtx2[2], vtx3[1], y + 0.05, vtx3[2], color[1], color[2], color[3], 0.1, false)
		drawDebugLine(vtx1[1], y + 0.05, vtx1[2], color[1], color[2], color[3], vtx2[1], y + 0.05, vtx2[2], color[1], color[2], color[3], true)
		drawDebugLine(vtx3[1], y + 0.05, vtx3[2], color[1], color[2], color[3], vtx4[1], y + 0.05, vtx4[2], color[1], color[2], color[3], true)
		vtx1 = trapezoid.line2[1]
		vtx2 = trapezoid.line2[2]
		vtx3 = trapezoid.line1[2]
		vtx4 = trapezoid.line1[1]
		drawDebugTriangle(vtx1[1], y + 0.05, vtx1[2], vtx2[1], y + 0.05, vtx2[2], vtx3[1], y + 0.05, vtx3[2], color[1], color[2], color[3], 0.1, false)
		drawDebugLine(vtx1[1], y + 0.05, vtx1[2], color[1], color[2], color[3], vtx2[1], y + 0.05, vtx2[2], color[1], color[2], color[3], true)
		drawDebugLine(vtx3[1], y + 0.05, vtx3[2], color[1], color[2], color[3], vtx4[1], y + 0.05, vtx4[2], color[1], color[2], color[3], true)
		drawDebugPoint(vtx1[1], y + 0.05, vtx1[2], color[1], color[2], color[3], 1, false)
		drawDebugPoint(vtx2[1], y + 0.05, vtx2[2], color[1], color[2], color[3], 1, false)
		drawDebugPoint(vtx3[1], y + 0.05, vtx3[2], color[1], color[2], color[3], 1, false)
		drawDebugPoint(vtx4[1], y + 0.05, vtx4[2], color[1], color[2], color[3], 1, false)
	end
	for groupId, groupBoundary in pairs(self.trapezoidGroups) do
		local r = groupId / 5
		local g = 1 - groupId / 5
		local b = 1
		for i = 1, #groupBoundary.simplifiedBoundary - 1 do
			local x1 = groupBoundary.simplifiedBoundary[i][1]
			local z1 = groupBoundary.simplifiedBoundary[i][2]
			local x2 = groupBoundary.simplifiedBoundary[i + 1][1]
			local z2 = groupBoundary.simplifiedBoundary[i + 1][2]
			drawDebugLine(x1, y, z1, r, g, 1, x2, y, z2, r, g, 1, true)
			Utils.renderTextAtWorldPosition(x1, y, z1, string.format("%d", i), 0.015, 0, 0, 1, 1, 1)
		end
		local cx = groupBoundary.center[1]
		local cz = groupBoundary.center[2]
		Utils.renderTextAtWorldPosition(cx, y, cz, string.format("group%d", groupId), 0.015, 0, 0, 1, 1, 1)
		drawDebugLine(cx, y, cz, 0, 1, 0, cx + groupBoundary.direction[1] * 10, y, cz + groupBoundary.direction[2] * 10, 0, 1, 0, true)
	end
	for i = 1, #self.boundary - 1 do
		local x1 = self.boundary[i][1]
		local z1 = self.boundary[i][2]
		local x2 = self.boundary[i + 1][1]
		local z2 = self.boundary[i + 1][2]
		drawDebugLine(x1, y, z1, 1, 0, 0, x2, y, z2, 1, 0, 0, true)
	end
end
function TrapezoidDecomposition.getClosestIntersectionWithBoundary(position, dirX, dirZ, boundary)
	local minDistance = math.huge
	local minDistanceIntersectionX = nil
	local minDistanceIntersectionZ = nil
	for posIndex = 1, #boundary - 1 do
		local p1 = boundary[posIndex]
		local p2 = boundary[posIndex + 1]
		if position == p1 or position == p2 then
			continue
		end
		local lDirX = p2[1] - p1[1]
		local lDirZ = p2[2] - p1[2]
		local length = MathUtil.vector2Length(lDirX, lDirZ)
		lDirX = lDirX / length
		lDirZ = lDirZ / length
		local intersect, t1, t2 = MathUtil.getLineLineIntersection2D(position[1], position[2], dirX, dirZ, p1[1], p1[2], lDirX, lDirZ)
		if intersect and (0 < t1 and (0 <= t2 and t2 <= length)) then
			local pX = p1[1] + lDirX * t2
			local pZ = p1[2] + lDirZ * t2
			local distance = MathUtil.vector2Length(position[1] - pX, position[2] - pZ)
			if 0.1 < distance and (FieldCourseUtil.getIsSegmentInsideBoundary(position[1], position[2], pX, pZ, boundary) and distance < minDistance) then
				minDistance = distance
				minDistanceIntersectionX = pX
				minDistanceIntersectionZ = pZ
			end
		end
	end
	return minDistanceIntersectionX, minDistanceIntersectionZ
end
function TrapezoidDecomposition.getIsNeighbouringLine(line1, line2, boundary, otherLines)
	local sx = (line1[1][1] + line1[2][1]) * 0.5
	local sz = (line1[1][2] + line1[2][2]) * 0.5
	local ex = (line2[1][1] + line2[2][1]) * 0.5
	local ez = (line2[1][2] + line2[2][2]) * 0.5
	if not FieldCourseUtil.getIsSegmentInsideBoundary(sx, sz, ex, ez, boundary) then
		return false
	else
		for _, otherLine in ipairs(otherLines) do
			if otherLine == line1 or otherLine == line2 then
				continue
			end
			if MathUtil.getLineSegmentsIntersection(sx, sz, ex, ez, otherLine[1][1], otherLine[1][2], otherLine[2][1], otherLine[2][2]) then
				return false
			end
		end
		return true
	end
end
function TrapezoidDecomposition.getTrapezoidSize(line1, line2)
	local width = math.abs(line1[1][1] - line2[1][1])
	local height = (line1[1][2] - line1[2][2] + (line2[1][2] - line2[2][2])) * 0.5
	return width * height
end
