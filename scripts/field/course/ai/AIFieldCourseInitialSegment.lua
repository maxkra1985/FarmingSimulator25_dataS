-- Local values: AIFieldCourseInitialSegment_mt
AIFieldCourseInitialSegment = {}
local AIFieldCourseInitialSegment_mt = Class(AIFieldCourseInitialSegment)

-- Upvalues: AIFieldCourseInitialSegment_mt
-- Local values: self, initialTurnRadius
function AIFieldCourseInitialSegment.new(aiFieldCourse, segments)
	-- upvalues: (copy) AIFieldCourseInitialSegment_mt
	local v3_ = AIFieldCourseInitialSegment_mt
	local v4_ = setmetatable({}, v3_)
	v4_.aiFieldCourse = aiFieldCourse
	v4_.fieldCourseSettings = aiFieldCourse.fieldCourseSettings
	v4_.turnGenerator = AIFieldCourseTurnGenerator.new(aiFieldCourse)
	v4_.turnGenerator:setCallback(v4_.onSegmentTurnDataFound, v4_)
	local v5_ = v4_.fieldCourseSettings.minTurnRadius * v4_.fieldCourseSettings.initialTurnRadiusFactor
	v4_.turnGenerator:setMaxOffset(v5_ * 3)
	v4_.turnGenerator:setOverwrittenTurnRadius(v5_)
	v4_.furtherSegments = {}
	return v4_
end

function AIFieldCourseInitialSegment:setCallback(callbackFunc, callbackTarget)
	self.callbackFunc = callbackFunc
	self.callbackTarget = callbackTarget
end

-- Local values: initialTurnRadius, minDistance, intersect, ix, iz, cx, cz, side, i, cost, radius, circleX, circleZ, _intersect, _ix, _iz, distance, circleX, circleZ, distance, circleHitDirX, circleHitDirZ, cDirX, cDirZ
function AIFieldCourseInitialSegment:generate(startX, startZ, startDirX, startDirZ)
	self.startX = startX
	self.startZ = startZ
	self.startDirX = startDirX
	self.startDirZ = startDirZ
	if FieldCourseUtil.getIsPointInsideBoundary(self.startX, self.startZ, self.aiFieldCourse.protectedBoundary.boundaryLine) then
		self:generateFinalSegment(startX, startZ, startDirX, startDirZ)
		return true
	end
	local v14_ = self.fieldCourseSettings.minTurnRadius * self.fieldCourseSettings.initialTurnRadiusFactor
	local v15_ = math.huge
	local v16_ = nil
	local v17_ = nil
	local v18_ = nil
	local v19_ = nil
	local v20_ = nil
	local v21_ = nil
	for v22_ = 10, 1, -1 do
		local v23_ = 1 + (10 - v22_) * 0.05
		local v24_ = v14_ * v22_ + 0.01
		local v25_ = self.startX - startDirZ * v24_
		local v26_ = self.startZ + startDirX * v24_
		local v27_, v28_, v29_ = FieldCourseUtil.getSegmentClosestBoundaryCircleIntersection(self.startX + startDirX * 0.5, self.startZ + startDirZ * 0.5, v25_, v26_, v24_, self.aiFieldCourse.protectedBoundary.boundaryLine)
		local v30_
		if v27_ then
			v30_ = MathUtil.vector2Length(v28_ - self.startX, v29_ - self.startZ) * v23_
			if v30_ < v15_ then
				v16_ = true
				v21_ = 1
			else
				v26_ = v20_
				v29_ = v19_
				v25_ = v18_
				v28_ = v17_
				v30_ = v15_
			end
		else
			v26_ = v20_
			v29_ = v19_
			v25_ = v18_
			v28_ = v17_
			v30_ = v15_
		end
		v18_ = self.startX + startDirZ * v24_
		v20_ = self.startZ - startDirX * v24_
		local v31_
		v31_, v17_, v19_ = FieldCourseUtil.getSegmentClosestBoundaryCircleIntersection(self.startX + startDirX * 0.5, self.startZ + startDirZ * 0.5, v18_, v20_, v24_, self.aiFieldCourse.protectedBoundary.boundaryLine)
		if v31_ then
			v15_ = MathUtil.vector2Length(v17_ - self.startX, v19_ - self.startZ) * v23_
			if v15_ < v30_ then
				v16_ = true
				v21_ = -1
			else
				v20_ = v26_
				v19_ = v29_
				v18_ = v25_
				v17_ = v28_
				v15_ = v30_
			end
		else
			v20_ = v26_
			v19_ = v29_
			v18_ = v25_
			v17_ = v28_
			v15_ = v30_
		end
	end
	if not v16_ then
		return false
	end
	local v32_, v33_ = MathUtil.vector2Normalize(v17_ - v18_, v19_ - v20_)
	local v34_ = -v33_ * v21_
	local v35_ = v32_ * v21_
	local v36_ = v17_ + v34_ * 0.1
	local v37_ = v19_ + v35_ * 0.1
	self.turnGenerator:setIgnoreBoundaryIntersections(true)
	self.turnGenerator:setMaxOffset(v14_ * 2)
	self.turnGenerator:setCallback(self.onIntoFieldSegmentTurnDataFound, self)
	self.turnGenerator:generatePositionToPosition(self.startX, self.startZ, startDirX, startDirZ, v36_, v37_, v34_, v35_)
	return true
end

-- Local values: turnData
function AIFieldCourseInitialSegment:onIntoFieldSegmentTurnDataFound(turn)
	if turn == nil then
		self:debugPrint("Failed to generate into-field segment")
		self:doCallback(false)
	else
		turn.isInitialLine = true
		self.intoFieldSegment = turn
		local v40_ = turn.turnData
		self:generateFinalSegment(v40_.ex, v40_.ez, v40_.eDirX, v40_.eDirZ)
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

-- Local values: furtherSegmentData, firstSegment
function AIFieldCourseInitialSegment:onFirstSegmentFound(segmentData, direction, isTurn, addStraighting, nextTurn, isLast)
	if segmentData == nil then
		self:debugPrint("Failed to find first segment.")
		self:doCallback(false)
	else
		local v52_ = self.furtherSegments
		table.insert(v52_, {
			["segmentData"] = segmentData,
			["direction"] = direction,
			["isTurn"] = isTurn,
			["addStraighting"] = addStraighting
		})
		if isLast then
			local v53_ = self.furtherSegments[1]
			self.turnGenerator:setIgnoreBoundaryIntersections(true)
			self.turnGenerator:setCallback(self.onSegmentOutsideFieldTurnDataFound, self)
			self.turnGenerator:generatePositionToSegment(self.startX, self.startZ, self.startDirX, self.startDirZ, v53_.segmentData, v53_.direction)
		end
	end
end

function AIFieldCourseInitialSegment:onSegmentOutsideFieldTurnDataFound(turn)
	if turn == nil then
		self:debugPrint("Failed to generate initial segment with full boundary intersections")
		self:doCallback(false, true)
	else
		AIFieldCourseTurnCollisionCheck.new(turn, self.fieldCourseSettings, self.onSegmentOutsideFieldCollisionCheckFinished, self)
	end
end

-- Local values: firstSegment
function AIFieldCourseInitialSegment:onSegmentOutsideFieldCollisionCheckFinished(success, turn)
	if success then
		self.intoFieldSegment = nil
		self:onSegmentTurnDataFound(turn)
	else
		local v59_ = self.furtherSegments[1]
		self.turnGenerator:setIgnoreBoundaryIntersections(false)
		self.turnGenerator:setCallback(self.onSegmentTurnDataFound, self)
		self.turnGenerator:generatePositionToSegment(self.isx, self.isz, self.isDirX, self.isDirZ, v59_.segmentData, v59_.direction)
	end
end

-- Local values: firstSegment, numSegments, i, furtherSegment, nextTurn, nextSegment, allowFieldBoundary
function AIFieldCourseInitialSegment:onSegmentTurnDataFound(turn)
	local v62_ = self.furtherSegments[1]
	if turn == nil then
		if self.isAlternativeSearch then
			self:debugPrint("Failed to generate additional turn segment with protected boundary intersection")
			self:doCallback(false, true)
		else
			self.isAlternativeSearch = true
			local v63_ = not FieldCourseUtil.getIsPointInsideBoundary(self.isx, self.isz, self.aiFieldCourse.fieldRootBoundary.boundaryLine)
			self.turnGenerator:setIgnoreBoundaryIntersections(v63_)
			self.turnGenerator:setMaxOffset(nil)
			self.turnGenerator:setCallback(self.onSegmentTurnDataFound, self)
			self.turnGenerator:generatePositionToSegment(self.isx, self.isz, self.isDirX, self.isDirZ, v62_.segmentData, v62_.direction)
		end
	else
		v62_.segmentData.lastStartOffset = turn.turnData.startOffset
		if self.intoFieldSegment ~= nil then
			turn.isInitialLine = true
			self:doCallback(true, false, self.intoFieldSegment, 1, true, false)
		end
		self:doCallback(true, false, turn, 1, true, true)
		local v64_ = #self.furtherSegments
		for v65_, v66_ in ipairs(self.furtherSegments) do
			local v67_ = nil
			if v65_ < #self.furtherSegments then
				local v68_ = self.furtherSegments[v65_ + 1]
				if v68_.isTurn then
					v67_ = v68_.segmentData
				end
			end
			self:doCallback(true, v65_ == v64_, v66_.segmentData, v66_.direction, v66_.isTurn, v66_.addStraighting, v67_)
		end
		return
	end
end

function AIFieldCourseInitialSegment:doCallback(success, isLast, segment, segmentDirection, segmentIsTurn, addStraighting, nextTurn)
	if self.callbackTarget == nil then
		self.callbackFunc(success, isLast, segment, segmentDirection, segmentIsTurn, addStraighting, nextTurn)
	else
		self.callbackFunc(self.callbackTarget, success, isLast, segment, segmentDirection, segmentIsTurn, addStraighting, nextTurn)
	end
end
function AIFieldCourseInitialSegment.debugPrint(_, p77_, ...)
	if VehicleDebug.state == VehicleDebug.DEBUG_AI then
		print("AIFieldCourseInitialSegment: " .. string.format(p77_, ...))
	end
end
