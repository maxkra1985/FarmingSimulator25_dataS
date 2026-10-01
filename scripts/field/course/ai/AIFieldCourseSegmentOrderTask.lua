AIFieldCourseSegmentOrderTask = {}
local AIFieldCourseSegmentOrderTask_mt = Class(AIFieldCourseSegmentOrderTask)
function AIFieldCourseSegmentOrderTask.new(aiFieldCourse)
	local self = setmetatable({}, AIFieldCourseSegmentOrderTask_mt)
	self.aiFieldCourse = aiFieldCourse
	self.fieldCourse = aiFieldCourse.fieldCourse
	self.segments = aiFieldCourse.fieldCourse.segments
	self.fieldCourseSettings = aiFieldCourse.fieldCourseSettings
	self.turnGenerator = AIFieldCourseTurnGenerator.new(aiFieldCourse)
	self.turnGenerator:setCallback(self.onSegmentTurnDataFound, self)
	self.cornerCutOut = AIFieldCourseCornerCutOut.new(aiFieldCourse)
	self.cornerCutOut:setCallback(self.onCutOutSegmentFound, self)
	self.firstSegmentDetection = AIFieldCourseFirstSegmentDetection.new(aiFieldCourse, self)
	self.firstSegmentDetection:setCallback(self.onFoundFirstSegment, self)
	self.segmentCollisionCheck = AIFieldCourseSegmentCollisionCheck.new(self.fieldCourseSettings, self.aiFieldCourse.fieldRootBoundary.boundaryLine)
	self.extendedHeadlandSegments = {}
	self.alternativeTurnSegments = {}
	self.startX = nil
	self.startZ = nil
	self.startDirX = nil
	self.startDirZ = nil
	self.orderedSegments = {}
	self.usedSegments = {}
	self.adjustedSegments = {}
	self.segmentExcludeListPositive = {}
	self.segmentExcludeListNegative = {}
	self.unreachableSegments = {}
	self.excludedSegments = {}
	self.segmentsToSkip = {}
	self.allowedProtectedBoundaryCrossings = {}
	self.segmentBuffer = {}
	self.turnSegmentBuffer = {}
	self.curSegmentIndex = 1
	self.firstRun = true
	self.segment = nil
	self.direction = nil
	return self
end
function AIFieldCourseSegmentOrderTask:setStartPosition(startX, startZ, dirX, dirZ)
	self.startX = startX
	self.startZ = startZ
	self.startDirX = dirX
	self.startDirZ = dirZ
	self.firstSegmentDetection:setStartPosition(startX, startZ, dirX, dirZ)
end
function AIFieldCourseSegmentOrderTask:setAlternativeTurnSegmentData(alternativeTurnSegments)
	self.alternativeTurnSegments = alternativeTurnSegments
end
function AIFieldCourseSegmentOrderTask:setOverwrittenSegments(overwrittenSegments)
	self.overwrittenSegments = overwrittenSegments
	self.segmentBuffer = {}
	for i, loadedSegmentData in ipairs(overwrittenSegments) do
		local segment = AIFieldCourseSegment.new()
		segment:setPositions(loadedSegmentData.positions)
		segment.index = i
		segment.isTurn = loadedSegmentData.isTurn
		segment.isHeadlandSegment = loadedSegmentData.isHeadlandSegment
		segment.isIslandSegment = loadedSegmentData.isIslandSegment
		if segment:isValid() then
			local data = { segment = segment, adjustedSegment = segment, direction = 1 }
			if i == 1 then
				self.usedSegments[data.segment] = true
				table.insert(self.orderedSegments, data)
				self.segment = data.segment
				self.direction = data.direction
			else
				table.insert(self.segmentBuffer, data)
			end
		end
	end
	self.segments = overwrittenSegments
	self.firstRun = false
end
function AIFieldCourseSegmentOrderTask:setSegmentsToSkip(segmentsToSkip)
	if segmentsToSkip ~= nil then
		self.segmentsToSkip = segmentsToSkip
		self.firstSegmentDetection:setSegmentsToSkip(segmentsToSkip)
	end
end
function AIFieldCourseSegmentOrderTask:setLastActiveSegmentId(lastActiveSegmentId)
	if lastActiveSegmentId ~= nil then
		self.firstSegmentDetection:setLastActiveSegmentId(lastActiveSegmentId)
	end
end
function AIFieldCourseSegmentOrderTask:getSegmentSearchPending()
	return self.pendingSegmentSearch
end
function AIFieldCourseSegmentOrderTask:onFoundSegment(segment, direction, isTurn, addStraighting, nextTurn, isLast)
	if self.callback ~= nil then
		if self.callbackTarget ~= nil then
			self.callback(self.callbackTarget, segment, direction, isTurn, addStraighting, nextTurn, isLast)
			return
		end
		self.callback(segment, direction, isTurn, addStraighting, nextTurn, isLast)
	end
end
function AIFieldCourseSegmentOrderTask:next(callback, callbackTarget, bufferMinSize)
	if self.pendingSegmentSearch then
		Logging.error("AIFieldCourseSegmentOrderTask:next() called while a segment search is still pending")
		printCallstack()
	end
	self.callback = callback
	self.callbackTarget = callbackTarget
	self.pendingSegmentSearch = true
	self.numBufferFillIterations = (bufferMinSize or 5) - #self.segmentBuffer
	self:fillBuffer()
end
function AIFieldCourseSegmentOrderTask:onBufferFillFinished()
	if self.cornerCutOutInProgress then
		return
	elseif 0 < #self.segmentBuffer then
		local segmentData = self.segmentBuffer[1]
		local nextSegmentData = self.segmentBuffer[2]
		self.usedSegments[segmentData.segment] = true
		table.insert(self.orderedSegments, segmentData)
		local nextTurn = nil
		if nextSegmentData ~= nil then
			for _, turnSegmentData in ipairs(self.turnSegmentBuffer) do
				if turnSegmentData.from == segmentData.segment and turnSegmentData.to == nextSegmentData.segment then
					nextTurn = turnSegmentData.turn
					break
				end
			end
		end
		if self.fieldCourseSettings.cornerCutOutSupported and (self.fieldCourseSettings.canTurnBackward and (nextSegmentData ~= nil and self.cornerCutOut:validateSegments(segmentData.adjustedSegment, segmentData.direction, nextSegmentData.adjustedSegment, nextSegmentData.direction))) then
			self.aiFieldCourse:debugPrint("Corner cut out calculations started from segment %d to %d", segmentData.adjustedSegment.index, nextSegmentData.adjustedSegment.index)
			self.cornerCutOutInProgress = true
			self.cornerCutOutAlternativeTurn = nextTurn
			self.cornerCutOutAlternativeTurnDirection = segmentData.direction
			self:onFoundSegment(segmentData.adjustedSegment, segmentData.direction, false, true, nil, false)
			table.remove(self.segmentBuffer, 1)
			return
		end
		self:onFoundSegment(segmentData.adjustedSegment, segmentData.direction, false, true, nextTurn, false)
		if nextTurn ~= nil then
			self:onFoundSegment(nextTurn, segmentData.direction, true, true, nil, true)
		end
		table.remove(self.segmentBuffer, 1)
		self.pendingSegmentSearch = false
	else
		self:onFoundSegment(nil, 1, false, true, nil, true)
		for _, segment in pairs(self.segments) do
			if self.usedSegments[segment] == nil then
				Logging.devInfo("AIFieldCourseSegmentOrderTask: Segment %d could not be reached. (%dm, x %.2f, z %.2f)", segment.index, segment.length, segment.positions[1][1], segment.positions[1][2])
			end
		end
	end
end
function AIFieldCourseSegmentOrderTask:fillBuffer()
	local lastSegment = nil
	local lastBufferElement = self.segmentBuffer[#self.segmentBuffer]
	if lastBufferElement ~= nil then
		lastSegment = lastBufferElement.segment
	end
	if lastSegment == nil and self.firstSegmentDetection ~= nil then
		self.firstSegmentDetection:detect()
		return false
	end
	for segment, _ in pairs(self.segmentExcludeListPositive) do
		self.segmentExcludeListPositive[segment] = nil
	end
	for segment, _ in pairs(self.segmentExcludeListNegative) do
		self.segmentExcludeListNegative[segment] = nil
	end
	for excludedSegment, _ in pairs(self.excludedSegments) do
		self.segmentExcludeListPositive[excludedSegment] = true
		self.segmentExcludeListNegative[excludedSegment] = true
	end
	for _, segment in ipairs(self.segments) do
		if self.segmentsToSkip[segment.segmentId] then
			self.segmentExcludeListPositive[segment] = true
			self.segmentExcludeListNegative[segment] = true
		end
	end
	for unreachableSegment, _ in pairs(self.unreachableSegments) do
		self.segmentExcludeListPositive[unreachableSegment] = true
		self.segmentExcludeListNegative[unreachableSegment] = true
	end
	for i, segmentData in ipairs(self.segmentBuffer) do
		self.segmentExcludeListPositive[segmentData.segment] = true
		self.segmentExcludeListNegative[segmentData.segment] = true
	end
	if not self:fillNextBufferSlot() then
		self:onBufferSlotFilled()
		return false
	else
		return true
	end
end
function AIFieldCourseSegmentOrderTask:onBufferSlotFilled()
	if 0 < self.numBufferFillIterations then
		self.numBufferFillIterations = self.numBufferFillIterations - 1
		if 0 < self.numBufferFillIterations and not self:fillBuffer() then
			self.numBufferFillIterations = 0
			return
		end
	end
	if self.numBufferFillIterations == 0 then
		self:onBufferFillFinished()
	end
end
function AIFieldCourseSegmentOrderTask:fillNextBufferSlot()
	local lastSegment = nil
	local lastDirection = nil
	local lastBufferElement = self.segmentBuffer[#self.segmentBuffer]
	if lastBufferElement ~= nil then
		lastSegment = lastBufferElement.segment
		lastDirection = lastBufferElement.direction
	end
	local segment, direction = self:findNextValidSegment(lastSegment, lastDirection)
	if segment ~= nil then
		self:adjustSegmentLength(segment, direction, function(adjustedSegment)
			self.adjustedSegments[segment] = adjustedSegment
			self.curTurnSegment1 = lastSegment
			self.curTurnSegmentDirection1 = lastDirection
			self.curTurnSegment2 = segment
			self.curTurnSegmentDirection2 = direction
			self.turnGenerator:setAllowProtectedBoundary(false)
			if lastDirection == direction and self.allowedProtectedBoundaryCrossings[self.curTurnSegment1] == self.curTurnSegment2 then
				self.turnGenerator:setAllowProtectedBoundary(true)
			end
			self.turnGenerator:generateSegmentToSegment(self.adjustedSegments[lastSegment], lastDirection, adjustedSegment, direction)
		end)
		return true
	else
		return false
	end
end
function AIFieldCourseSegmentOrderTask:onSegmentTurnDataFound(turn)
	if turn ~= nil then
		self.adjustedSegments[self.curTurnSegment1].lastEndOffset = turn.turnData.endOffset
		self.adjustedSegments[self.curTurnSegment2].lastStartOffset = turn.turnData.startOffset
		table.insert(self.segmentBuffer, { segment = self.curTurnSegment2, adjustedSegment = self.adjustedSegments[self.curTurnSegment2], direction = self.curTurnSegmentDirection2 })
		table.insert(self.turnSegmentBuffer, { turn = turn, from = self.curTurnSegment1, to = self.curTurnSegment2 })
		self:onBufferSlotFilled()
	else
		local excludeCombination = true
		if self.curTurnSegment1.isHeadlandSegment and (self.curTurnSegment2.isHeadlandSegment and self.curTurnSegmentDirection1 == self.curTurnSegmentDirection2) then
			self.allowedProtectedBoundaryCrossings[self.curTurnSegment1] = self.curTurnSegment2
			excludeCombination = false
		end
		if excludeCombination then
			if 0 < self.curTurnSegmentDirection2 then
				self.segmentExcludeListPositive[self.curTurnSegment2] = true
			else
				self.segmentExcludeListNegative[self.curTurnSegment2] = true
			end
		end
		if not self:fillNextBufferSlot() then
			self:onBufferSlotFilled()
		end
	end
end
function AIFieldCourseSegmentOrderTask:onCutOutSegmentFound(segment, direction, isTurn, nextTurn, isLast)
	if segment == nil then
		self.aiFieldCourse:debugPrint("Corner cut out failed, use previously calculated segment")
		self.cornerCutOutInProgress = false
		self.pendingSegmentSearch = false
		if self.cornerCutOutAlternativeTurn ~= nil then
			self:onFoundSegment(self.cornerCutOutAlternativeTurn, self.cornerCutOutAlternativeTurnDirection, true, true, nil, true)
			self.cornerCutOutAlternativeTurn = nil
			self.cornerCutOutAlternativeTurnDirection = nil
		end
	else
		segment.isCornerCutOut = true
		self:onFoundSegment(segment, direction, isTurn, not isTurn, nextTurn, isLast)
		if isLast then
			self.cornerCutOutInProgress = false
			self.pendingSegmentSearch = false
		end
	end
end
function AIFieldCourseSegmentOrderTask:onFoundFirstSegment(success, segment, direction)
	if success then
		if segment ~= nil and segment.isHeadlandSegment then
			local headlandForcedDirection = -math.sign(self.fieldCourseSettings.headlandForcedDirection)
			if headlandForcedDirection ~= 0 then
				for _, otherSegment in ipairs(self.segments) do
					if otherSegment.lockedDirection == nil then
						if otherSegment.isHeadlandSegment then
							if otherSegment.headlandIndex ~= segment.headlandIndex then
								if segment.isHeadlandSegment or segment.isIslandSegment then
									otherSegment.lockedDirection = -headlandForcedDirection
								end
							elseif otherSegment.isHeadlandSegment then
								if otherSegment.headlandIndex == segment.headlandIndex then
									otherSegment.lockedDirection = direction
								end
							end
						end
						if otherSegment.isIslandSegment then
							otherSegment.lockedDirection = headlandForcedDirection
						end
					end
				end
			end
		end
		self:adjustSegmentLength(segment, direction, function(adjustedSegment)
			self.adjustedSegments[segment] = adjustedSegment
			table.insert(self.segmentBuffer, { adjustedSegment = adjustedSegment, segment = segment, direction = direction })
			self.firstSegmentDetection = nil
			self:fillBuffer()
		end)
	else
		self.firstSegmentDetection = nil
		self:fillBuffer()
	end
end
function AIFieldCourseSegmentOrderTask:hasFinished()
	if not self.firstRun and self.segment == nil then
		return true
	end
	return false
end
function AIFieldCourseSegmentOrderTask:findNextValidSegment(lastSegment, lastDirection)
	local segment = nil
	local direction = nil
	while segment == nil do
		segment, direction = self:findNextSegment(lastSegment, lastDirection)
		if segment == nil then
			return segment, direction
		end
		if self:getIsSegmentValid(segment) then
			continue
		end
		self.excludedSegments[segment] = true
		self.segmentExcludeListPositive[segment] = true
		self.segmentExcludeListNegative[segment] = true
		segment = nil
	end
	return segment, direction
end
function AIFieldCourseSegmentOrderTask:getIsSegmentValid(segment)
	local halfWidth = self.fieldCourseSettings.implementWidth * 0.5
	for i = 1, #segment.positions - 1 do
		local p1 = segment.positions[i]
		local p2 = segment.positions[i + 1]
		local dirX, dirZ = MathUtil.vector2Normalize(p2[1] - p1[1], p2[2] - p1[2])
		local startWorldX = p1[1] - dirZ * halfWidth
		local startWorldZ = p1[2] + dirX * halfWidth
		local widthWorldX = p1[1] + dirZ * halfWidth
		local widthWorldZ = p1[2] - dirX * halfWidth
		local heightWorldX = p2[1] - dirZ * halfWidth
		local heightWorldZ = p2[2] + dirX * halfWidth
		if self.aiFieldCourse:getIsSegmentAreaValid(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ) then
			return true
		end
	end
	return false
end
function AIFieldCourseSegmentOrderTask:findNextSegment(lastSegment, lastDirection)
	if lastSegment == nil then
		return nil
	else
		if self.fieldCourseSettings.headlandsFirst then
			if lastSegment.isIslandSegment then
				local islandsSegment, islandSegmentDirection = self:findClosestSegment(lastSegment, lastDirection, false, true, nil, nil, lastSegment.headlandIndex, lastSegment.islandIndex)
				if islandsSegment ~= nil then
					return islandsSegment, islandSegmentDirection
				end
				local nextHeadlandDirection = 1
				if self.fieldCourseSettings.headlandsFirst then
					nextHeadlandDirection = -1
				end
				islandsSegment, islandSegmentDirection = self:findClosestSegment(lastSegment, lastDirection, false, true, nil, nil, lastSegment.headlandIndex + nextHeadlandDirection, lastSegment.islandIndex)
				if islandsSegment ~= nil then
					return islandsSegment, islandSegmentDirection
				end
			end
			local segment, direction = self:findNextHeadlandSegment(lastSegment, lastDirection, false)
			if segment ~= nil then
				local islandsSegment, islandSegmentDirection = self:findClosestSegment(lastSegment, lastDirection, false, true, nil, nil, -1)
				if islandsSegment ~= nil then
					local x, z = AIFieldCourseUtil.getSegmentPosition(true, islandsSegment, islandSegmentDirection)
					local sideOffset = AIFieldCourseUtil.getSegmentSideOffset(lastSegment, x, z)
					if self.fieldCourseSettings.implementWidth * 2.01 < sideOffset then
						islandsSegment = nil
					end
				end
				segment, direction = self:getCloserSegment(lastSegment, lastDirection, segment, direction, islandsSegment, islandSegmentDirection)
				if segment ~= nil then
					return segment, direction
				end
			end
			local islandsSegment, islandSegmentDirection = self:findClosestSegment(lastSegment, lastDirection, false, true, nil, nil, -1)
			if islandsSegment ~= nil then
				local x, z = AIFieldCourseUtil.getSegmentPosition(true, islandsSegment, islandSegmentDirection)
				local sideOffset = AIFieldCourseUtil.getSegmentSideOffset(lastSegment, x, z)
				if self.fieldCourseSettings.implementWidth * 2.01 < sideOffset then
					islandsSegment = nil
				end
			end
			local straightSegmentAny, straightSegmentAnyDirection = self:findClosestStraightSegment(lastSegment, lastDirection, lastSegment.lineGroupIndex, false)
			segment, direction = self:getCloserSegment(lastSegment, lastDirection, islandsSegment, islandSegmentDirection, straightSegmentAny, straightSegmentAnyDirection)
			if segment ~= nil and segment == islandsSegment then
				return segment, direction
			end
			local straightSegment, straightSegmentDirection = self:findClosestStraightSegment(lastSegment, lastDirection, lastSegment.lineGroupIndex, true)
			if straightSegment ~= nil then
				return straightSegment, straightSegmentDirection
			end
		else
			if lastSegment.isIslandSegment then
				local islandsSegment, islandSegmentDirection = self:findClosestSegment(lastSegment, lastDirection, false, true, nil, nil, lastSegment.headlandIndex, lastSegment.islandIndex)
				if islandsSegment ~= nil then
					return islandsSegment, islandSegmentDirection
				end
				local nextHeadlandDirection = 1
				if self.fieldCourseSettings.headlandsFirst then
					nextHeadlandDirection = -1
				end
				islandsSegment, islandSegmentDirection = self:findClosestSegment(lastSegment, lastDirection, false, true, nil, nil, lastSegment.headlandIndex + nextHeadlandDirection, lastSegment.islandIndex)
				if islandsSegment ~= nil then
					return islandsSegment, islandSegmentDirection
				end
			end
			local islandsSegment, islandSegmentDirection = self:findClosestSegment(lastSegment, lastDirection, false, true, nil, nil, -1)
			if islandsSegment ~= nil then
				local x, z = AIFieldCourseUtil.getSegmentPosition(true, islandsSegment, islandSegmentDirection)
				local sideOffset = AIFieldCourseUtil.getSegmentSideOffset(lastSegment, x, z)
				if self.fieldCourseSettings.implementWidth * 2.01 < sideOffset then
					islandsSegment = nil
				end
			end
			local straightSegment, straightSegmentDirection = self:findClosestStraightSegment(lastSegment, lastDirection, lastSegment.lineGroupIndex, true)
			local segment, direction = self:getCloserSegment(lastSegment, lastDirection, islandsSegment, islandSegmentDirection, straightSegment, straightSegmentDirection)
			if segment ~= nil then
				return segment, direction
			end
		end
		if lastSegment.lineGroupIndex ~= nil then
			for _, segment in ipairs(self.segments) do
				if self.usedSegments[segment] == nil and (self.segmentExcludeListPositive[segment] == nil and self.segmentExcludeListNegative[segment] == nil) then
					if lastSegment.lineGroupIndex == segment.lineGroupIndex then
						return segment, -lastDirection
					end
					local closestSegment, direction = self:findClosestSegment(lastSegment, lastDirection, false, false)
					if closestSegment == nil then
						continue
					end
					return closestSegment, direction
				end
			end
		end
		if not self.fieldCourseSettings.headlandsFirst then
			local segment, direction = self:findNextHeadlandSegment(lastSegment, lastDirection, true)
			if segment ~= nil then
				return segment, direction
			end
			segment, direction = self:findNextHeadlandSegment(lastSegment, lastDirection, false)
			if segment ~= nil then
				return segment, direction
			end
		end
		return nil
	end
end
function AIFieldCourseSegmentOrderTask:findNextHeadlandSegment(lastSegment, lastDirection, useIslands)
	if lastSegment.headlandIndex ~= nil then
		local lastIndex = nil
		local minSegment = #self.segments
		local maxSegment = 1
		for i, segment in ipairs(self.segments) do
			if segment == lastSegment then
				lastIndex = i
			end
			if self.usedSegments[segment] == nil and (self.segmentExcludeListPositive[segment] == nil and (self.segmentExcludeListNegative[segment] == nil and (lastSegment.headlandIndex == segment.headlandIndex and lastSegment.islandIndex == segment.islandIndex))) then
				minSegment = math.min(minSegment, i)
				maxSegment = math.max(maxSegment, i)
			end
		end
		if lastIndex ~= nil then
			local nextIndex = lastIndex + lastDirection
			for _ = 1, maxSegment - minSegment do
				local segment = self.segments[nextIndex]
				if segment ~= nil and (lastSegment.headlandIndex == segment.headlandIndex and lastSegment.islandIndex == segment.islandIndex) then
					local excludeList = 0 < lastDirection and self.segmentExcludeListPositive or self.segmentExcludeListNegative
					if self.usedSegments[segment] == nil and (excludeList[segment] == nil and segment.lockedDirection ~= -lastDirection) then
						return segment, lastDirection
					end
					nextIndex = nextIndex + lastDirection
					continue
				end
				nextIndex = 0 < lastDirection and minSegment or maxSegment
			end
			local numNextHeadland = 0
			for i, segment in ipairs(self.segments) do
				if segment == lastSegment then
					lastIndex = i
				end
				if self.usedSegments[segment] == nil and (self.segmentExcludeListPositive[segment] == nil and (self.segmentExcludeListNegative[segment] == nil and (lastSegment.headlandIndex + 1 == segment.headlandIndex and lastSegment.islandIndex == segment.islandIndex))) then
					numNextHeadland = numNextHeadland + 1
				end
			end
		end
		local closestSegment, direction = self:findClosestSegment(lastSegment, lastDirection, not useIslands, useIslands)
		if closestSegment ~= nil then
			return closestSegment, direction
		end
	else
		local closestSegment, direction = self:findClosestSegment(lastSegment, lastDirection, not useIslands, useIslands)
		if closestSegment ~= nil then
			return closestSegment, direction
		end
	end
	return nil
end
function AIFieldCourseSegmentOrderTask:findClosestStraightSegment(lastSegment, direction, groupIndex, workLessSegmentSideFirst)
	local searchDirection = 0
	if workLessSegmentSideFirst and groupIndex ~= nil then
		local negSegments = 0
		local posSegments = 0
		local foundSegment = false
		for _, segment in pairs(self.segments) do
			if segment == lastSegment then
				foundSegment = true
			elseif self.usedSegments[segment] == nil then
				if self.segmentExcludeListPositive[segment] == nil and (self.segmentExcludeListNegative[segment] == nil and segment.lineGroupIndex == lastSegment.lineGroupIndex) then
					local sx1 = lastSegment.positions[1][1]
					local sz1 = lastSegment.positions[1][2]
					local ex1 = lastSegment.positions[2][1]
					local ez1 = lastSegment.positions[2][2]
					local sx2 = segment.positions[1][1]
					local sz2 = segment.positions[1][2]
					local ex2 = segment.positions[2][1]
					local ez2 = segment.positions[2][2]
					if FieldCourseUtil.getAreParallelSegmentsNextToEachOther(sx1, sz1, ex1, ez1, sx2, sz2, ex2, ez2) then
						if foundSegment then
							posSegments = posSegments + 1
						else
							negSegments = negSegments + 1
						end
					end
				end
			end
		end
		if 0 < negSegments then
			if negSegments < posSegments then
				searchDirection = -1
			elseif 0 < posSegments then
				if posSegments < negSegments then
					searchDirection = 1
				end
			end
		end
	end
	local x1, z1 = AIFieldCourseUtil.getSegmentPosition(false, lastSegment, direction)
	local minDistance = math.huge
	local minDistanceSegment = nil
	local minDistanceSegmentDirection = 1
	local allowed = searchDirection <= 0
	for _, segment in ipairs(self.segments) do
		allowed = not allowed
		if (searchDirection == 0 or lastSegment ~= segment or allowed) and (allowed and (self.usedSegments[segment] == nil and (groupIndex == nil and segment.lineGroupIndex == nil))) then
			if groupIndex == nil then
				continue
			end
			if segment.lineGroupIndex == groupIndex then
				if self.segmentExcludeListPositive[segment] == nil and segment.lockedDirection ~= -1 then
					local distance = self:getCostDistanceToSegment(segment, true, x1, z1)
					if distance < minDistance and 0 < distance then
						minDistance = distance
						minDistanceSegment = segment
						minDistanceSegmentDirection = 1
					end
				end
				if self.segmentExcludeListNegative[segment] == nil then
					if segment.lockedDirection == 1 then
						continue
					end
					local distance = self:getCostDistanceToSegment(segment, false, x1, z1)
					if distance < minDistance and 0 < distance then
						minDistance = distance
						minDistanceSegment = segment
						minDistanceSegmentDirection = -1
					end
				end
			end
		end
		return minDistanceSegment, minDistanceSegmentDirection
	end
end
function AIFieldCourseSegmentOrderTask:getCostDistanceToSegment(targetSegment, startPosition, x, z)
	local x2, z2 = AIFieldCourseUtil.getSegmentPosition(startPosition, targetSegment, 1)
	local distance = MathUtil.vector2Length(x2 - x, z2 - z)
	for _, segment in ipairs(self.segments) do
		if segment.isHeadlandSegment or segment.isIslandSegment then
			continue
		end
		if self.usedSegments[segment] == nil and (self.segmentExcludeListPositive[segment] == nil and self.segmentExcludeListNegative[segment] == nil) then
			local intersect = FieldCourseUtil.getSegmentBoundaryIntersection(x, z, x2, z2, segment.positions)
			if intersect then
				distance = distance * 3
			end
		end
	end
	return distance
end
function AIFieldCourseSegmentOrderTask:findClosestSegment(lastSegment, direction, headlands, islands, groupIndex, maxSideOffset, headlandIndex, islandIndex, excludeBoundaryChecks)
	local x1, z1 = AIFieldCourseUtil.getSegmentPosition(false, lastSegment, direction)
	return self:getClosestSegmentToPosition(x1, z1, headlands, islands, groupIndex, maxSideOffset, headlandIndex, islandIndex, lastSegment, excludeBoundaryChecks, nil, nil)
end
function AIFieldCourseSegmentOrderTask:getClosestSegmentToPosition(x, z, headlands, islands, groupIndex, maxSideOffset, headlandIndex, islandIndex, excludeSegment, excludeBoundaryChecks, prevDirX, prevDirZ)
	local minDistance = math.huge
	local minDistanceRaw = math.huge
	local minDistanceSegment = nil
	local minDistanceSegmentDirection = 1
	for _, segment in ipairs(self.segments) do
		if self.usedSegments[segment] == nil then
			if segment == excludeSegment then
				continue
			end
			if headlands ~= nil then
				local segmentIsAllowed = headlands == segment.isHeadlandSegment and islands ~= nil and islands == segment.isIslandSegment
				local _v13 = false
			end
			_v13 = true
			local _v142 = segment.isIslandSegment
			if headlandIndex == -1 then
				if segment.islandIndex ~= nil then
					local island = self.aiFieldCourse.islands[segment.islandIndex]
					if island ~= nil and island.hasCutSegments then
						headlandIndex = nil
					end
				end
				if headlandIndex ~= nil then
					if segment.headlandIndex == nil then
						segmentIsAllowed = false
					else
						local curHeadlandIndex = 1
						if self.fieldCourseSettings.headlandsFirst and segment.islandIndex ~= nil then
							for _, otherSegment in ipairs(self.segments) do
								if otherSegment.islandIndex == segment.islandIndex then
									curHeadlandIndex = math.max(curHeadlandIndex, otherSegment.headlandIndex)
								end
							end
						end
						local validSegmentsLeft = false
						local foundSegments = 0
						for _, otherSegment in ipairs(self.segments) do
							if otherSegment.islandIndex == segment.islandIndex and otherSegment.headlandIndex == curHeadlandIndex then
								foundSegments = foundSegments + 1
								if self.usedSegments[otherSegment] == nil then
									validSegmentsLeft = true
									break
								end
							end
						end
						while not validSegmentsLeft do
							if self.fieldCourseSettings.headlandsFirst then
								if segment.islandIndex ~= nil then
									curHeadlandIndex = curHeadlandIndex - 1
								else
									curHeadlandIndex = curHeadlandIndex + 1
								end
							end
							if foundSegments == 0 then
								break
							end
						end
						segmentIsAllowed = segmentIsAllowed and segment.headlandIndex == curHeadlandIndex
					end
				end
			else
				segmentIsAllowed = segmentIsAllowed and headlandIndex ~= nil and segment.headlandIndex == headlandIndex
			end
			segmentIsAllowed = false
			if groupIndex ~= nil then
				segmentIsAllowed = false
				if maxSideOffset ~= nil then
					local x2, z2 = AIFieldCourseUtil.getSegmentPosition(true, segment, 1)
					local x3, z3 = AIFieldCourseUtil.getSegmentPosition(false, segment, 1)
					local dirX, dirZ = MathUtil.vector2Normalize(x3 - x2, z3 - z2)
					local x4, z4 = MathUtil.projectOnLine(x, z, x2, z2, dirX, dirZ)
					local distance = MathUtil.vector2Length(x4 - x, z4 - z)
					segmentIsAllowed = segmentIsAllowed and distance < maxSideOffset
				end
			end
			if segmentIsAllowed then
				if self.segmentExcludeListPositive[segment] == nil and segment.lockedDirection ~= -1 then
					local x2, z2 = AIFieldCourseUtil.getSegmentPosition(true, segment, 1)
					local distanceRaw = MathUtil.vector2Length(x2 - x, z2 - z)
					if distanceRaw <= minDistance + 0.1 then
						local correctedDistance = distanceRaw
						if excludeBoundaryChecks ~= true then
							correctedDistance = self:getBoundaryCorrectedDistance(x, z, x2, z2)
						end
						if maxSideOffset == nil or correctedDistance == nil or correctedDistance == nil then
							local distance = correctedDistance or distanceRaw
							distance = distance * self:getSegmentToSegmentFactor(x, z, segment)
							if prevDirX ~= nil and prevDirZ ~= nil then
								local px2, pz2 = AIFieldCourseUtil.getSegmentPosition(true, segment, 1, 1)
								distance = distance * self:getSegmentDirectionFactor(x2, z2, px2, pz2, prevDirX, prevDirZ)
							end
							if distance < minDistance then
								minDistance = distance
								minDistanceRaw = distanceRaw
								minDistanceSegment = segment
								minDistanceSegmentDirection = 1
							end
						end
					end
				end
				if self.segmentExcludeListNegative[segment] == nil then
					if segment.lockedDirection == 1 then
						continue
					end
					local x3, z3 = AIFieldCourseUtil.getSegmentPosition(false, segment, 1)
					local distanceRaw = MathUtil.vector2Length(x3 - x, z3 - z)
					if distanceRaw <= minDistance + 0.1 then
						local correctedDistance = nil
						if excludeBoundaryChecks ~= true then
							correctedDistance = self:getBoundaryCorrectedDistance(x, z, x3, z3)
						end
						if maxSideOffset == nil or correctedDistance == nil or correctedDistance == nil then
							local distance = correctedDistance or distanceRaw
							distance = distance * self:getSegmentToSegmentFactor(x, z, segment)
							if prevDirX ~= nil and prevDirZ ~= nil then
								local px3, pz3 = AIFieldCourseUtil.getSegmentPosition(false, segment, 1, 1)
								distance = distance * self:getSegmentDirectionFactor(x3, z3, px3, pz3, prevDirX, prevDirZ)
							end
							if distance < minDistance then
								minDistance = distance
								minDistanceRaw = distanceRaw
								minDistanceSegment = segment
								minDistanceSegmentDirection = -1
							end
						end
					end
				end
			end
		end
	end
	return minDistanceSegment, minDistanceSegmentDirection
end
function AIFieldCourseSegmentOrderTask:getSegmentToSegmentFactor(x, z, segment)
	local x2, z2 = AIFieldCourseUtil.getSegmentPosition(true, segment, 1)
	local x3, z3 = AIFieldCourseUtil.getSegmentPosition(false, segment, 1)
	local dirX = x3 - x2
	local dirZ = z3 - z2
	local length = MathUtil.vector2Length(dirX, dirZ)
	if 0 < length then
		dirX = dirX / length
		dirZ = dirZ / length
		local x4, z4 = MathUtil.projectOnLine(x, z, x2, z2, dirX, dirZ)
		local distance = MathUtil.vector2Length(x4 - x, z4 - z)
		local factor = distance / self.fieldCourseSettings.implementWidth
		return (factor - 1) * 0.25 + 1
	else
		return 1
	end
end
function AIFieldCourseSegmentOrderTask:getSegmentDirectionFactor(x1, z1, x2, z2, prevDirX, prevDirZ)
	local dirX, dirZ = MathUtil.vector2Normalize(x2 - x1, z2 - z1)
	local yRot1 = MathUtil.getYRotationFromDirection(dirX, dirZ)
	local yRot2 = MathUtil.getYRotationFromDirection(prevDirX, prevDirZ)
	local rotOffset = yRot2 - yRot1
	if 3.141592653589793 < rotOffset then
		rotOffset = rotOffset - 6.283185307179586
	end
	if rotOffset < -3.141592653589793 then
		rotOffset = rotOffset + 6.283185307179586
	end
	return 1 + math.abs(rotOffset) * 0.5
end
function AIFieldCourseSegmentOrderTask:getCloserSegment(lastSegment, lastDirection, segment1, direction1, segment2, direction2)
	if segment1 ~= nil and segment2 ~= nil then
		local x1, z1 = AIFieldCourseUtil.getSegmentPosition(false, lastSegment, lastDirection)
		local x2, z2 = AIFieldCourseUtil.getSegmentPosition(true, segment1, direction1)
		local x3, z3 = AIFieldCourseUtil.getSegmentPosition(true, segment2, direction2)
		local distance1 = MathUtil.vector2Length(x2 - x1, z2 - z1)
		local distance2 = MathUtil.vector2Length(x3 - x1, z3 - z1)
		for _, segment in ipairs(self.segments) do
			local intersect, _, _ = FieldCourseUtil.getSegmentBoundaryIntersection(x1, z1, x2, z2, segment.positions)
			if intersect then
				distance1 = distance1 * 1.05
			end
			intersect, _, _ = FieldCourseUtil.getSegmentBoundaryIntersection(x1, z1, x3, z3, segment.positions)
			if intersect then
				distance2 = distance2 * 1.05
			end
		end
		if distance1 < distance2 then
			return segment1, direction1
		else
			return segment2, direction2
		end
	end
	if segment1 ~= nil then
		return segment1, direction1
	elseif segment2 ~= nil then
		return segment2, direction2
	else
		return nil, nil
	end
end
function AIFieldCourseSegmentOrderTask:getBoundaryCorrectedDistance(x1, z1, x2, z2)
	local boundaryLine = self.aiFieldCourse.fieldRootBoundary.boundaryLine
	if FieldCourseUtil.getIsPointInsideBoundary(x1, z1, boundaryLine) and FieldCourseUtil.getIsPointInsideBoundary(x2, z2, boundaryLine) then
		local distance = self:getBoundaryCorrectedDistanceByBoundary(boundaryLine, x1, z1, x2, z2)
		if distance ~= nil then
			return distance
		end
	end
	for _, island in ipairs(self.aiFieldCourse.islands) do
		if FieldCourseUtil.getIsPointInsideBoundary(x1, z1, island.protectedBoundary.boundaryLine) or FieldCourseUtil.getIsPointInsideBoundary(x2, z2, island.protectedBoundary.boundaryLine) then
			continue
		end
		local distance = self:getBoundaryCorrectedDistanceByBoundary(island.protectedBoundary.boundaryLine, x1, z1, x2, z2)
		if distance == nil then
			continue
		end
		return distance
	end
	return nil
end
function AIFieldCourseSegmentOrderTask:getBoundaryCorrectedDistanceByBoundary(boundaryLine, x1, z1, x2, z2)
	for i = 1, #boundaryLine - 1 do
		local x3 = boundaryLine[i][1]
		local z3 = boundaryLine[i][2]
		local x4 = boundaryLine[i + 1][1]
		local z4 = boundaryLine[i + 1][2]
		local intersect, _, _ = MathUtil.getLineSegmentsIntersection(x1, z1, x2, z2, x3, z3, x4, z4)
		if intersect then
			local _, distance = self:getNextDirectConnectBoundaryPosition(boundaryLine, i, x2, z2)
			if distance == nil then
				continue
			end
			if 0 < distance then
				local baseDistance = MathUtil.vector2Length(x3 - z1, z3 - z1)
				return distance + baseDistance
			end
		end
	end
	return nil
end
function AIFieldCourseSegmentOrderTask:getNextDirectConnectBoundaryPosition(boundaryLine, index, x, z)
	local distancePos = 0
	local distanceNeg = 0
	for i = 1, #boundaryLine do
		local pos1 = boundaryLine[index + i]
		if pos1 == nil then
			break
		end
		local x1 = boundaryLine[index + i][1]
		local z1 = boundaryLine[index + i][2]
		local intersect, _, _ = FieldCourseUtil.getSegmentBoundaryIntersection(x1, z1, x, z, boundaryLine)
		if not intersect then
			distancePos = distancePos + MathUtil.vector2Length(x1 - x, z1 - z)
			return index + i, distancePos
		end
		distancePos = distancePos + MathUtil.vector2Length(boundaryLine[index + i][1] - boundaryLine[index + i - 1][1], boundaryLine[index + i][2] - boundaryLine[index + i - 1][2])
		local pos2 = boundaryLine[index - i]
		if pos2 == nil then
			break
		end
		local x2 = boundaryLine[index - i][1]
		local z2 = boundaryLine[index - i][2]
		intersect, _, _ = FieldCourseUtil.getSegmentBoundaryIntersection(x2, z2, x, z, boundaryLine)
		if not intersect then
			distanceNeg = distanceNeg + MathUtil.vector2Length(x2 - x, z2 - z)
			return index - i, distanceNeg
		end
		distanceNeg = distanceNeg + MathUtil.vector2Length(boundaryLine[index - i][1] - boundaryLine[index - i + 1][1], boundaryLine[index - i][2] - boundaryLine[index - i + 1][2])
	end
	return nil
end
function AIFieldCourseSegmentOrderTask:adjustSegmentLength(segment, direction, callback)
	if (segment.isHeadlandSegment or segment.isIslandSegment) and self.extendedHeadlandSegments[segment] == nil then
		local boundaryLine = self.aiFieldCourse.fieldRootBoundary.boundaryLine
		if segment.islandIndex == nil then
			if 1 < segment.headlandIndex then
				local headlandBoundary = self.aiFieldCourse.headlandBoundaries[segment.headlandIndex - 1]
				if headlandBoundary ~= nil then
					boundaryLine = headlandBoundary.boundaryLine
				end
			end
		else
			local island = self.aiFieldCourse.islands[segment.islandIndex]
			if island ~= nil then
				if 1 < segment.headlandIndex then
					local headlandBoundary = island.boundaries[segment.headlandIndex - 1]
					if headlandBoundary ~= nil then
						boundaryLine = headlandBoundary.boundaryLine
					end
				else
					boundaryLine = island.rootBoundary.boundaryLine
				end
			end
		end
		local isFirstSegment = true
		for otherSegment, _ in pairs(self.extendedHeadlandSegments) do
			if segment.islandIndex == otherSegment.islandIndex and segment.headlandIndex == otherSegment.headlandIndex then
				isFirstSegment = false
				break
			end
		end
		self.extendedHeadlandSegments[segment] = true
		local toolDirection = math.sign(self.fieldCourseSettings.toolFrontOffset)
		AIFieldCourseUtil.extendHeadlandSegment(self.segments, segment.index, direction, toolDirection, self.fieldCourseSettings.implementWidth, boundaryLine)
		if isFirstSegment then
			AIFieldCourseUtil.extendHeadlandSegment(self.segments, segment.index, -direction, 1, self.fieldCourseSettings.implementWidth, boundaryLine, true, direction)
		end
	end
	segment = table.clone(segment, 5)
	if dp ~= nil then
		for i = 1, #segment.positions - 1 do
			local p1 = segment.positions[i]
			local p2 = segment.positions[i + 1]
			if MathUtil.vector2Length(p2[1] - p1[1], p2[2] - p1[2]) == 0 then
				dp(p1[1], p1[2], "Zero Length Segment")
			end
		end
	end
	if self.fieldCourseSettings.sideOffset ~= 0 then
		if segment.sideOffsetToApply ~= nil then
			FieldCourseBoundary.segmentApplySideOffset(segment, segment.sideOffsetToApply)
			segment.sideOffsetToApply = nil
		else
			local sideOffset = self.fieldCourseSettings.sideOffset
			if self.fieldCourseSettings.variableSideOffset == true then
				local preferedSide = self:getPreferedOffsetSide(segment, direction)
				if preferedSide ~= nil then
					sideOffset = math.abs(sideOffset) * preferedSide
				else
					sideOffset = sideOffset / direction
				end
			else
				sideOffset = sideOffset * direction
			end
			FieldCourseBoundary.segmentApplySideOffset(segment, sideOffset)
			segment.sideOffset = sideOffset * direction
		end
	end
	if self.fieldCourseSettings.toolFullOverlap then
		FieldCourseUtil.extendSegment(segment.positions, direction, -self.fieldCourseSettings.toolBackOffset)
		FieldCourseUtil.extendSegment(segment.positions, -direction, self.fieldCourseSettings.toolFrontOffset)
	elseif self.fieldCourseSettings.toolFullOverlapInside then
		if not segment.isHeadlandSegment then
			if not segment.isIslandSegment then
				FieldCourseUtil.extendSegment(segment.positions, direction, -self.fieldCourseSettings.toolBackOffset)
				FieldCourseUtil.extendSegment(segment.positions, -direction, self.fieldCourseSettings.toolFrontOffset)
			else
				FieldCourseUtil.extendSegment(segment.positions, direction, -self.fieldCourseSettings.toolFrontOffset)
				if self.fieldCourseSettings.canTurnBackward or self.fieldCourseSettings.allowStraightReversing then
					FieldCourseUtil.extendSegment(segment.positions, -direction, self.fieldCourseSettings.toolBackOffset)
				end
			end
		end
	end
	self.segmentCollisionCheck:checkSegment(segment, direction, function(_segment)
		callback(_segment)
	end)
end
function AIFieldCourseSegmentOrderTask:getNeighbouringUsedSegment(segment)
	if segment.lineGroupIndex ~= nil then
		local prevSegment = self.segments[segment.index - 1]
		if prevSegment ~= nil and self.adjustedSegments[prevSegment] ~= nil then
			return self.adjustedSegments[prevSegment]
		end
		local nextSegment = self.segments[segment.index + 1]
		if nextSegment ~= nil and self.adjustedSegments[nextSegment] ~= nil then
			return self.adjustedSegments[nextSegment]
		end
	elseif segment.headlandIndex ~= nil then
		for originalSegment, adjustedSegment in pairs(self.adjustedSegments) do
			if adjustedSegment.islandIndex == segment.islandIndex and (adjustedSegment.headlandIndex == segment.headlandIndex + 1 or adjustedSegment.headlandIndex == segment.headlandIndex - 1) then
				local offset = AIFieldCourseUtil.getSegmentToSegmentDistance(segment, originalSegment)
				if offset < self.fieldCourseSettings.implementWidth + 0.01 then
					return adjustedSegment
				end
			end
		end
	end
end
function AIFieldCourseSegmentOrderTask:getPreferedOffsetSide(segment, direction)
	if segment.headlandIndex ~= nil then
		local segmentBoundary = self.aiFieldCourse.fieldRootBoundary.boundaryLine
		if segment.islandIndex ~= nil then
			local island = self.aiFieldCourse.islands[segment.islandIndex]
			if island ~= nil then
				segmentBoundary = island.rootBoundary.boundaryLine
			end
		end
		local x1 = nil
		local z1 = nil
		local x2 = nil
		local z2 = nil
		if direction < 0 then
			local numPositions = #segment.positions
			x1 = segment.positions[numPositions][1]
			z1 = segment.positions[numPositions][2]
			x2 = segment.positions[numPositions - 1][1]
			z2 = segment.positions[numPositions - 1][2]
		else
			x1 = segment.positions[1][1]
			z1 = segment.positions[1][2]
			x2 = segment.positions[2][1]
			z2 = segment.positions[2][2]
		end
		local dirX, dirZ = MathUtil.vector2Normalize(x2 - x1, z2 - z1)
		local cx = (x1 + x2) * 0.5
		local cz = (z1 + z2) * 0.5
		local maxDistance = self.fieldCourseSettings.implementWidth * self.fieldCourseSettings.numHeadlands
		local intersect1, ix1, iz1 = FieldCourseUtil.getSegmentClosestBoundaryIntersection(cx, cz, cx + dirZ * maxDistance, cz - dirX * maxDistance, segmentBoundary)
		local intersect2, ix2, iz2 = FieldCourseUtil.getSegmentClosestBoundaryIntersection(cx, cz, cx - dirZ * maxDistance, cz + dirX * maxDistance, segmentBoundary)
		if intersect1 and intersect2 then
			local distance1 = MathUtil.vector2Length(cx - ix1, cz - iz1)
			local distance2 = MathUtil.vector2Length(cx - ix2, cz - iz2)
			return distance2 < distance1 and direction or -direction
		end
		if intersect1 then
			return -direction
		end
		if intersect2 then
			return direction
		end
	else
		local x1 = nil
		local z1 = nil
		local x2 = nil
		local z2 = nil
		if direction < 0 then
			local numPositions = #segment.positions
			x1 = segment.positions[numPositions][1]
			z1 = segment.positions[numPositions][2]
			x2 = segment.positions[numPositions - 1][1]
			z2 = segment.positions[numPositions - 1][2]
		else
			x1 = segment.positions[1][1]
			z1 = segment.positions[1][2]
			x2 = segment.positions[2][1]
			z2 = segment.positions[2][2]
		end
		local dirX, dirZ = MathUtil.vector2Normalize(x2 - x1, z2 - z1)
		local cx = (x1 + x2) * 0.5
		local cz = (z1 + z2) * 0.5
		local neighbouringSegment = self:getNeighbouringUsedSegment(segment)
		if neighbouringSegment ~= nil then
			local maxDistance = self.fieldCourseSettings.implementWidth * self.fieldCourseSettings.numHeadlands
			local intersect1, ix1, iz1 = FieldCourseUtil.getSegmentBoundaryIntersection(cx, cz, cx + dirZ * maxDistance, cz - dirX * maxDistance, neighbouringSegment.positions)
			local intersect2, ix2, iz2 = FieldCourseUtil.getSegmentBoundaryIntersection(cx, cz, cx + dirZ * maxDistance, cz - dirX * maxDistance, neighbouringSegment.positions)
			if intersect1 and intersect2 then
				local distance1 = MathUtil.vector2Length(cx - ix1, cz - iz1)
				local distance2 = MathUtil.vector2Length(cx - ix2, cz - iz2)
				return distance2 < distance1 and -direction or direction
			end
			if intersect1 then
				return direction
			end
			if intersect2 then
				return -direction
			end
		else
			local boundaryLine = self.aiFieldCourse.fieldRootBoundary.boundaryLine
			local intersect1, ix1, iz1 = FieldCourseUtil.getSegmentClosestBoundaryIntersection(cx, cz, cx + dirZ * 100, cz - dirX * 100, boundaryLine)
			local intersect2, ix2, iz2 = FieldCourseUtil.getSegmentClosestBoundaryIntersection(cx, cz, cx - dirZ * 100, cz + dirX * 100, boundaryLine)
			if intersect1 and intersect2 then
				local distance1 = MathUtil.vector2Length(cx - ix1, cz - iz1)
				local distance2 = MathUtil.vector2Length(cx - ix2, cz - iz2)
				return distance2 < distance1 and -direction or direction
			end
			if intersect1 then
				return direction
			end
			if intersect2 then
				return -direction
			end
		end
	end
	return nil
end
