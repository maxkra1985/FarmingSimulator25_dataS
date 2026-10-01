AIFieldCourseInitialSegment = {}
local AIFieldCourseInitialSegment_mt = Class(AIFieldCourseInitialSegment)
function AIFieldCourseInitialSegment.new(aiFieldCourse, segments)
	local self = setmetatable({}, AIFieldCourseInitialSegment_mt)
	self.aiFieldCourse = aiFieldCourse
	self.fieldCourseSettings = aiFieldCourse.fieldCourseSettings
	self.turnGenerator = AIFieldCourseTurnGenerator.new(aiFieldCourse)
	self.turnGenerator:setCallback(self.onSegmentTurnDataFound, self)
	local initialTurnRadius = self.fieldCourseSettings.minTurnRadius * self.fieldCourseSettings.initialTurnRadiusFactor
	self.turnGenerator:setMaxOffset(initialTurnRadius * 3)
	self.turnGenerator:setOverwrittenTurnRadius(initialTurnRadius)
	self.furtherSegments = {}
	return self
end
function AIFieldCourseInitialSegment:setCallback(callbackFunc, callbackTarget)
	self.callbackFunc = callbackFunc
	self.callbackTarget = callbackTarget
end
function AIFieldCourseInitialSegment:generate(startX, startZ, startDirX, startDirZ)
	self.startX = startX
	self.startZ = startZ
	self.startDirX = startDirX
	self.startDirZ = startDirZ
	if FieldCourseUtil.getIsPointInsideBoundary(self.startX, self.startZ, self.aiFieldCourse.protectedBoundary.boundaryLine) then
		self:generateFinalSegment(startX, startZ, startDirX, startDirZ)
		return true
	end
	local initialTurnRadius = self.fieldCourseSettings.minTurnRadius * self.fieldCourseSettings.initialTurnRadiusFactor
	local minDistance = math.huge
	local intersect = nil
	local ix = nil
	local iz = nil
	local cx = nil
	local cz = nil
	local side = nil
	for i = 10, 1, -1 do
		local cost = 1 + (10 - i) * 0.05
		local radius = initialTurnRadius * i + 0.01
		local circleX = self.startX - startDirZ * radius
		local circleZ = self.startZ + startDirX * radius
		local _intersect, _ix, _iz = FieldCourseUtil.getSegmentClosestBoundaryCircleIntersection(self.startX + startDirX * 0.5, self.startZ + startDirZ * 0.5, circleX, circleZ, radius, self.aiFieldCourse.protectedBoundary.boundaryLine)
		if _intersect then
			local distance = MathUtil.vector2Length(_ix - self.startX, _iz - self.startZ) * cost
			if distance < minDistance then
				intersect = true
				ix = _ix
				iz = _iz
				cx = circleX
				cz = circleZ
				side = 1
				minDistance = distance
			end
		end
		local circleX = self.startX + startDirZ * radius
		local circleZ = self.startZ - startDirX * radius
		_intersect, _ix, _iz = FieldCourseUtil.getSegmentClosestBoundaryCircleIntersection(self.startX + startDirX * 0.5, self.startZ + startDirZ * 0.5, circleX, circleZ, radius, self.aiFieldCourse.protectedBoundary.boundaryLine)
		if _intersect then
			local distance = MathUtil.vector2Length(_ix - self.startX, _iz - self.startZ) * cost
			if distance < minDistance then
				intersect = true
				ix = _ix
				iz = _iz
				cx = circleX
				cz = circleZ
				side = -1
				minDistance = distance
			end
		end
	end
	if intersect then
		local circleHitDirX, circleHitDirZ = MathUtil.vector2Normalize(ix - cx, iz - cz)
		local cDirX = -circleHitDirZ * side
		local cDirZ = circleHitDirX * side
		ix = ix + cDirX * 0.1
		iz = iz + cDirZ * 0.1
		self.turnGenerator:setIgnoreBoundaryIntersections(true)
		self.turnGenerator:setMaxOffset(initialTurnRadius * 2)
		self.turnGenerator:setCallback(self.onIntoFieldSegmentTurnDataFound, self)
		self.turnGenerator:generatePositionToPosition(self.startX, self.startZ, startDirX, startDirZ, ix, iz, cDirX, cDirZ)
		return true
	else
		return false
	end
end
function AIFieldCourseInitialSegment:onIntoFieldSegmentTurnDataFound(turn)
	if turn ~= nil then
		turn.isInitialLine = true
		self.intoFieldSegment = turn
		local turnData = turn.turnData
		self:generateFinalSegment(turnData.ex, turnData.ez, turnData.eDirX, turnData.eDirZ)
	else
		self:debugPrint("Failed to generate into-field segment")
		self:doCallback(false)
	end
end
function AIFieldCourseInitialSegment:generateFinalSegment(sx, sz, sDirX, sDirZ)
	self.isx = sx
	self.isz = sz
	self.isDirX = sDirX
	self.isDirZ = sDirZ
	self.aiFieldCourse.segmentOrderTask:setStartPosition(sx, sz, sDirX, sDirZ)
	self.aiFieldCourse.segmentOrderTask:next(self.onFirstSegmentFound, self, 1)
end
function AIFieldCourseInitialSegment:onFirstSegmentFound(segmentData, direction, isTurn, addStraighting, nextTurn, isLast)
	if segmentData == nil then
		self:debugPrint("Failed to find first segment.")
		self:doCallback(false)
	else
		local furtherSegmentData = {}
		furtherSegmentData.segmentData = segmentData
		furtherSegmentData.direction = direction
		furtherSegmentData.isTurn = isTurn
		furtherSegmentData.addStraighting = addStraighting
		table.insert(self.furtherSegments, furtherSegmentData)
		if isLast then
			local firstSegment = self.furtherSegments[1]
			self.turnGenerator:setIgnoreBoundaryIntersections(true)
			self.turnGenerator:setCallback(self.onSegmentOutsideFieldTurnDataFound, self)
			self.turnGenerator:generatePositionToSegment(self.startX, self.startZ, self.startDirX, self.startDirZ, firstSegment.segmentData, firstSegment.direction)
		end
	end
end
function AIFieldCourseInitialSegment:onSegmentOutsideFieldTurnDataFound(turn)
	if turn ~= nil then
		AIFieldCourseTurnCollisionCheck.new(turn, self.fieldCourseSettings, self.onSegmentOutsideFieldCollisionCheckFinished, self)
	else
		self:debugPrint("Failed to generate initial segment with full boundary intersections")
		self:doCallback(false, true)
	end
end
function AIFieldCourseInitialSegment:onSegmentOutsideFieldCollisionCheckFinished(success, turn)
	if success then
		self.intoFieldSegment = nil
		self:onSegmentTurnDataFound(turn)
	else
		local firstSegment = self.furtherSegments[1]
		self.turnGenerator:setIgnoreBoundaryIntersections(false)
		self.turnGenerator:setCallback(self.onSegmentTurnDataFound, self)
		self.turnGenerator:generatePositionToSegment(self.isx, self.isz, self.isDirX, self.isDirZ, firstSegment.segmentData, firstSegment.direction)
	end
end
function AIFieldCourseInitialSegment:onSegmentTurnDataFound(turn)
	local firstSegment = self.furtherSegments[1]
	if turn ~= nil then
		firstSegment.segmentData.lastStartOffset = turn.turnData.startOffset
		if self.intoFieldSegment ~= nil then
			turn.isInitialLine = true
			self:doCallback(true, false, self.intoFieldSegment, 1, true, false)
		end
		self:doCallback(true, false, turn, 1, true, true)
		local numSegments = #self.furtherSegments
		for i, furtherSegment in ipairs(self.furtherSegments) do
			local nextTurn = nil
			if i < #self.furtherSegments then
				local nextSegment = self.furtherSegments[i + 1]
				if nextSegment.isTurn then
					nextTurn = nextSegment.segmentData
				end
			end
			self:doCallback(true, i == numSegments, furtherSegment.segmentData, furtherSegment.direction, furtherSegment.isTurn, furtherSegment.addStraighting, nextTurn)
		end
	elseif not self.isAlternativeSearch then
		self.isAlternativeSearch = true
		local allowFieldBoundary = not FieldCourseUtil.getIsPointInsideBoundary(self.isx, self.isz, self.aiFieldCourse.fieldRootBoundary.boundaryLine)
		self.turnGenerator:setIgnoreBoundaryIntersections(allowFieldBoundary)
		self.turnGenerator:setMaxOffset(nil)
		self.turnGenerator:setCallback(self.onSegmentTurnDataFound, self)
		self.turnGenerator:generatePositionToSegment(self.isx, self.isz, self.isDirX, self.isDirZ, firstSegment.segmentData, firstSegment.direction)
	else
		self:debugPrint("Failed to generate additional turn segment with protected boundary intersection")
		self:doCallback(false, true)
	end
end
function AIFieldCourseInitialSegment:doCallback(success, isLast, segment, segmentDirection, segmentIsTurn, addStraighting, nextTurn)
	if self.callbackTarget ~= nil then
		self.callbackFunc(self.callbackTarget, success, isLast, segment, segmentDirection, segmentIsTurn, addStraighting, nextTurn)
	else
		self.callbackFunc(success, isLast, segment, segmentDirection, segmentIsTurn, addStraighting, nextTurn)
	end
end
function AIFieldCourseInitialSegment:debugPrint(text, ...)
	if VehicleDebug.state == VehicleDebug.DEBUG_AI then
		print("AIFieldCourseInitialSegment: " .. string.format(text, ...))
	end
end
