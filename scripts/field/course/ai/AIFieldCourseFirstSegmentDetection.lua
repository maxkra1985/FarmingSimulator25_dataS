AIFieldCourseFirstSegmentDetection = {}
local AIFieldCourseFirstSegmentDetection_mt = Class(AIFieldCourseFirstSegmentDetection)
function AIFieldCourseFirstSegmentDetection.new(aiFieldCourse, segmentOrderTask)
	local self = setmetatable({}, AIFieldCourseFirstSegmentDetection_mt)
	self.aiFieldCourse = aiFieldCourse
	self.fieldCourseSettings = aiFieldCourse.fieldCourseSettings
	self.segmentOrderTask = segmentOrderTask
	self.segments = segmentOrderTask.segments
	self.segmentsToSkip = {}
	self.lastActiveSegmentId = nil
	return self
end
function AIFieldCourseFirstSegmentDetection:setStartPosition(startX, startZ, dirX, dirZ)
	self.startX = startX
	self.startZ = startZ
	self.startDirX = dirX
	self.startDirZ = dirZ
end
function AIFieldCourseFirstSegmentDetection:setSegmentsToSkip(segmentsToSkip)
	self.segmentsToSkip = segmentsToSkip
end
function AIFieldCourseFirstSegmentDetection:setLastActiveSegmentId(lastActiveSegmentId)
	self.lastActiveSegmentId = lastActiveSegmentId
end
function AIFieldCourseFirstSegmentDetection:setCallback(callbackFunc, callbackTarget)
	self.callbackFunc = callbackFunc
	self.callbackTarget = callbackTarget
end
function AIFieldCourseFirstSegmentDetection:detect()
	if self.lastActiveSegmentId ~= nil then
		local hasSegment = false
		for _, segment in ipairs(self.segments) do
			if self.segmentsToSkip[segment.segmentId] == nil then
				if self.lastActiveSegmentId == nil or self.lastActiveSegmentId == segment.segmentId then
					hasSegment = true
				else
				end
				if not hasSegment then
					self.lastActiveSegmentId = false
				end
				local numStraightSegments = 0
				local numHeadlandSegments = 0
				for _, segment in ipairs(self.segments) do
					if self.segmentsToSkip[segment.segmentId] == nil and (self.lastActiveSegmentId == nil or self.lastActiveSegmentId == segment.segmentId) then
						if segment.lineGroupIndex ~= nil then
							numStraightSegments = numStraightSegments + 1
						end
						if segment.isHeadlandSegment then
							numHeadlandSegments = numHeadlandSegments + 1
						end
					end
				end
				if self.fieldCourseSettings.headlandsFirst then
					local headlandsFirst = 0 < numHeadlandSegments or not not self.fieldCourseSettings.headlandsFirst or numStraightSegments == 0
				end
				local _v21 = not self.fieldCourseSettings.headlandsFirst
				local numHeadlands = 0
				if headlandsFirst then
					for _, segment in ipairs(self.segments) do
						if self.segmentsToSkip[segment.segmentId] == nil and ((self.lastActiveSegmentId == nil or self.lastActiveSegmentId == segment.segmentId) and segment.isHeadlandSegment) then
							numHeadlands = math.max(numHeadlands, segment.headlandIndex)
						end
					end
					if 0 < numHeadlands then
						for i = 1, numHeadlands do
							self:splitClosestSegment(self.startX, self.startZ, self.startDirX, self.startDirZ, true, i)
						end
					end
				else
					self:splitClosestSegment(self.startX, self.startZ, self.startDirX, self.startDirZ, false, nil)
				end
				self.potentialSegments = {}
				for _, segment in ipairs(self.segments) do
					if self.segmentsToSkip[segment.segmentId] == nil and (self.lastActiveSegmentId == nil or self.lastActiveSegmentId == segment.segmentId) then
						if headlandsFirst then
							if segment.isHeadlandSegment then
								local scoreScale = 1 - (segment.headlandIndex - 1) / numHeadlands
								if segment.lockedDirection == nil or segment.lockedDirection == 1 then
									table.insert(self.potentialSegments, { segment = segment, direction = 1, score = self:getSegmentScore(segment, 1) * scoreScale })
								end
								if segment.lockedDirection == nil or segment.lockedDirection == -1 then
									table.insert(self.potentialSegments, { segment = segment, direction = -1, score = self:getSegmentScore(segment, -1) * scoreScale })
								end
							end
						else
							if segment.lineGroupIndex == nil then
								continue
							end
							if segment.lockedDirection == nil or segment.lockedDirection == 1 then
								table.insert(self.potentialSegments, { segment = segment, direction = 1, score = self:getSegmentScore(segment, 1) })
							end
							if segment.lockedDirection == nil or segment.lockedDirection == -1 then
								table.insert(self.potentialSegments, { segment = segment, direction = -1, score = self:getSegmentScore(segment, -1) })
							end
						end
					end
				end
				table.sort(self.potentialSegments, function(a, b)
					return b.score < a.score
				end)
				g_fieldCourseManager:addUpdateable(self)
				return
			end
		end
	end
end
function AIFieldCourseFirstSegmentDetection:debugScoring()
	for i, segmentData in ipairs(self.potentialSegments) do
		local x, z = AIFieldCourseUtil.getSegmentPosition(segmentData.direction == 1, segmentData.segment, 1)
		dp(x, z, string.format("seg%d d%d s%.4f", segmentData.segment.index, segmentData.direction, segmentData.score), i * 0.1)
	end
end
function AIFieldCourseFirstSegmentDetection:update(dt)
	if 0 < #self.potentialSegments then
		if not self.overlapInProgress then
			local sizeX = self.fieldCourseSettings.implementWidth + 0.5
			local sizeY = self.fieldCourseSettings.agentHeight + 0.5
			local sizeZ = self.fieldCourseSettings.toolBackOffset + self.fieldCourseSettings.agentBackOffset
			local segmentData = self.potentialSegments[1]
			local boundaryLine = self.aiFieldCourse.fieldRootBoundary.boundaryLine
			local sx, sz = AIFieldCourseUtil.extendHeadlandSegment(self.segments, segmentData.segment.index, -segmentData.direction, 1, self.fieldCourseSettings.implementWidth, boundaryLine, false)
			local x1, z1 = AIFieldCourseUtil.getSegmentPosition(segmentData.direction == 1, segmentData.segment, 1)
			if sx == nil then
				sx = x1
				sz = z1
			end
			local x2, z2 = AIFieldCourseUtil.getSegmentPosition(segmentData.direction == 1, segmentData.segment, 1, 1)
			local dirX, dirZ = MathUtil.vector2Normalize(x2 - x1, z2 - z1)
			local bx = sx - dirX * (sizeZ * 0.5)
			local bz = sz - dirZ * (sizeZ * 0.5)
			local rx = 0
			local ry = MathUtil.getYRotationFromDirection(dirX, dirZ)
			local rz = 0
			local by = getTerrainHeightAtWorldPos(g_terrainNode, bx, 0, bz) + sizeY * 0.5
			overlapBoxAsync(bx, by, bz, 0, ry, 0, sizeX * 0.5, sizeY * 0.5, sizeZ * 0.5, "overlapCallback", self, CollisionFlag.AI_BLOCKING, false, false, true, true)
			self.overlapInProgress = true
		end
	else
		g_fieldCourseManager:removeUpdateable(self)
		self:doCallback(false, nil, 1)
	end
end
function AIFieldCourseFirstSegmentDetection:overlapCallback(nodeId, subShapeIndex)
	if nodeId == 0 then
		g_fieldCourseManager:removeUpdateable(self)
		local segmentData = self.potentialSegments[1]
		self:doCallback(true, segmentData.segment, segmentData.direction)
	else
		table.remove(self.potentialSegments, 1)
	end
	self.overlapInProgress = false
	return false
end
function AIFieldCourseFirstSegmentDetection:getSegmentScore(segment, direction)
	local sx, sz = AIFieldCourseUtil.getSegmentPosition(direction == 1, segment, 1)
	local ox, oz = AIFieldCourseUtil.getSegmentPosition(direction == 1, segment, 1, 1)
	local dx, dz = MathUtil.vector2Normalize(ox - sx, oz - sz)
	local dot = MathUtil.dotProduct(self.startDirX, 0, self.startDirZ, dx, 0, dz)
	local distance = MathUtil.vector2Length(sx - self.startX, sz - self.startZ)
	return (dot + 1) * 0.5 * (1 - math.min(distance / 100, 0.99))
end
function AIFieldCourseFirstSegmentDetection:doCallback(success, segment, segmentDirection)
	if self.callbackTarget ~= nil then
		self.callbackFunc(self.callbackTarget, success, segment, segmentDirection)
	else
		self.callbackFunc(success, segment, segmentDirection)
	end
end
function AIFieldCourseFirstSegmentDetection:debugPrint(text, ...)
	if VehicleDebug.state == VehicleDebug.DEBUG_AI then
		print("AIFieldCourseFirstSegmentDetection: " .. string.format(text, ...))
	end
end
function AIFieldCourseFirstSegmentDetection:splitClosestSegment(x1, z1, dirX, dirZ, headlandSegment, headlandIndex)
	if dirX ~= nil and dirZ ~= nil then
		if self.fieldCourseSettings.toolFullOverlap then
			local toolFrontOffset = self.fieldCourseSettings.toolFrontOffset
			x1 = x1 + dirX * toolFrontOffset
			z1 = z1 + dirZ * toolFrontOffset
		else
			local toolBackOffset = self.fieldCourseSettings.toolBackOffset
			x1 = x1 + dirX * toolBackOffset
			z1 = z1 + dirZ * toolBackOffset
		end
	end
	local minDistance = math.huge
	for _, segment in ipairs(self.segments) do
		local isAllowed = nil
		if headlandSegment then
			if not segment.isHeadlandSegment then
				local _v183 = segment.isIslandSegment
				local _v74 = segment.headlandIndex
			end
			isAllowed = _v183 and headlandIndex ~= nil and segment.headlandIndex == headlandIndex
		else
			isAllowed = segment.lineGroupIndex ~= nil
		end
		if isAllowed then
			local x2, z2 = AIFieldCourseUtil.getSegmentPosition(true, segment, 1)
			local x3, z3 = AIFieldCourseUtil.getSegmentPosition(false, segment, 1)
			local startDistance = MathUtil.vector2Length(x2 - x1, z2 - z1)
			if startDistance < minDistance then
				minDistance = startDistance
			end
			local endDistance = MathUtil.vector2Length(x3 - x1, z3 - z1)
			if endDistance < minDistance then
				minDistance = endDistance
			end
		end
	end
	if minDistance ~= math.huge then
		local minSideOffset = math.huge
		local minSideOffsetSegmentIndex = nil
		local minSideOffsetSegmentPosIndex = nil
		for segmentIndex, segment in ipairs(self.segments) do
			local isAllowed = nil
			if headlandSegment then
				if not segment.isHeadlandSegment then
					local _v206 = segment.isIslandSegment
					local _v94 = segment.headlandIndex
				end
				isAllowed = _v206 and headlandIndex ~= nil and segment.headlandIndex == headlandIndex
			else
				isAllowed = segment.lineGroupIndex ~= nil
			end
			if isAllowed then
				local sideOffset, positionIndex = AIFieldCourseUtil.getSegmentSideOffset(segment, x1, z1, false)
				if sideOffset < minDistance and sideOffset < minSideOffset then
					minSideOffset = sideOffset
					minSideOffsetSegmentIndex = segmentIndex
					minSideOffsetSegmentPosIndex = positionIndex
				end
			end
		end
		if minSideOffsetSegmentIndex ~= nil then
			local segment = self.segments[minSideOffsetSegmentIndex]
			local p1x = segment.positions[minSideOffsetSegmentPosIndex][1]
			local p1z = segment.positions[minSideOffsetSegmentPosIndex][2]
			local p2x = segment.positions[minSideOffsetSegmentPosIndex + 1][1]
			local p2z = segment.positions[minSideOffsetSegmentPosIndex + 1][2]
			local dirX = p2x - p1x
			local dirZ = p2z - p1z
			local length = MathUtil.vector2Length(dirX, dirZ)
			dirX = dirX / length
			dirZ = dirZ / length
			local dot = MathUtil.getProjectOnLineParameter(x1, z1, p1x, p1z, dirX, dirZ)
			dot = math.clamp(dot, 0.1, length - 0.1)
			local splitX = p1x + dirX * dot
			local splitZ = p1z + dirZ * dot
			local prevLength = dot
			for i = minSideOffsetSegmentPosIndex, 2, -1 do
				local px1 = segment.positions[i][1]
				local pz1 = segment.positions[i][2]
				local px2 = segment.positions[i - 1][1]
				local pz2 = segment.positions[i - 1][2]
				prevLength = prevLength + MathUtil.vector2Length(px1 - px2, pz1 - pz2)
			end
			local nextLength = length - dot
			for i = minSideOffsetSegmentPosIndex + 1, #segment.positions - 1 do
				local px1 = segment.positions[i][1]
				local pz1 = segment.positions[i][2]
				local px2 = segment.positions[i + 1][1]
				local pz2 = segment.positions[i + 1][2]
				nextLength = nextLength + MathUtil.vector2Length(px1 - px2, pz1 - pz2)
			end
			local minDistanceToSegmentEnd = math.max(self.fieldCourseSettings.implementWidth, 5)
			if prevLength < minDistanceToSegmentEnd or nextLength < minDistanceToSegmentEnd then
				return
			end
			local newSegment = table.clone(segment, math.huge)
			for i = #segment.positions, minSideOffsetSegmentPosIndex + 2, -1 do
				table.remove(segment.positions, i)
			end
			segment.positions[minSideOffsetSegmentPosIndex + 1][1] = splitX
			segment.positions[minSideOffsetSegmentPosIndex + 1][2] = splitZ
			for i = minSideOffsetSegmentPosIndex - 1, 1, -1 do
				table.remove(newSegment.positions, i)
			end
			newSegment.positions[1][1] = splitX
			newSegment.positions[1][2] = splitZ
			local endX = newSegment.positions[#newSegment.positions][1]
			local endZ = newSegment.positions[#newSegment.positions][2]
			local nextSegment = self.segments[minSideOffsetSegmentIndex + 1]
			local prevSegment = self.segments[minSideOffsetSegmentIndex - 1]
			if nextSegment == nil then
				table.insert(self.segments, newSegment)
			elseif prevSegment == nil then
				table.insert(self.segments, 1, newSegment)
			else
				local nx2, nz2 = AIFieldCourseUtil.getSegmentPosition(true, nextSegment, 1)
				local nx3, nz3 = AIFieldCourseUtil.getSegmentPosition(false, nextSegment, 1)
				local nextDistance = math.min(MathUtil.vector2Length(endX - nx2, endZ - nz2), MathUtil.vector2Length(endX - nx3, endZ - nz3))
				local px2, pz2 = AIFieldCourseUtil.getSegmentPosition(true, prevSegment, 1)
				local px3, pz3 = AIFieldCourseUtil.getSegmentPosition(false, prevSegment, 1)
				local prevDistance = math.min(MathUtil.vector2Length(endX - px2, endZ - pz2), MathUtil.vector2Length(endX - px3, endZ - pz3))
				if nextDistance < prevDistance then
					table.insert(self.segments, minSideOffsetSegmentIndex + 1, newSegment)
				else
					table.insert(self.segments, minSideOffsetSegmentIndex, newSegment)
				end
			end
			for index, seg in ipairs(self.segments) do
				seg.index = index
			end
		end
	end
	return false
end
