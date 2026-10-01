AIFieldCourseCornerCutOut = {}
AIFieldCourseCornerCutOut.MIN_ANGLE = 0.5235987755982988
AIFieldCourseCornerCutOut.MAX_ANGLE = 2.0943951023931953
local AIFieldCourseCornerCutOut_mt = Class(AIFieldCourseCornerCutOut)
function AIFieldCourseCornerCutOut.new(aiFieldCourse, segments)
	local self = setmetatable({}, AIFieldCourseCornerCutOut_mt)
	self.aiFieldCourse = aiFieldCourse
	self.fieldCourseSettings = aiFieldCourse.fieldCourseSettings
	self.turnGenerator = AIFieldCourseTurnGenerator.new(aiFieldCourse)
	self.turnGenerator:setCallback(self.onSegmentTurnDataFound, self)
	self.turnGenerator:setPreferOneDrivingDirection(true)
	return self
end
function AIFieldCourseCornerCutOut:setCallback(callbackFunc, callbackTarget)
	self.callbackFunc = callbackFunc
	self.callbackTarget = callbackTarget
end
function AIFieldCourseCornerCutOut:validateSegments(segment1, direction1, segment2, direction2)
	if not segment1.isHeadlandSegment or not segment2.isHeadlandSegment then
		return false
	end
	local totalLength = self.fieldCourseSettings.agentBackOffset + self.fieldCourseSettings.agentFrontOffset
	if totalLength < self.fieldCourseSettings.implementWidth then
		return false
	else
		local x1, z1 = AIFieldCourseUtil.getSegmentPosition(false, segment1, direction1)
		local x2, z2 = AIFieldCourseUtil.getSegmentPosition(false, segment1, direction1, 1)
		local x3, z3 = AIFieldCourseUtil.getSegmentPosition(true, segment2, direction2)
		local x4, z4 = AIFieldCourseUtil.getSegmentPosition(true, segment2, direction2, 1)
		local dirX1 = x2 - x1
		local dirZ1 = z2 - z1
		local length1 = MathUtil.vector2Length(dirX1, dirZ1)
		dirX1 = dirX1 / length1
		dirZ1 = dirZ1 / length1
		local dirX2 = x4 - x3
		local dirZ2 = z4 - z3
		local length2 = MathUtil.vector2Length(dirX2, dirZ2)
		dirX2 = dirX2 / length2
		dirZ2 = dirZ2 / length2
		if totalLength + 0.1 < length1 and totalLength + 0.1 < length2 then
			local dot1 = MathUtil.dotProduct(-dirZ1, 0, dirX1, dirX2, 0, dirZ2)
			local dot2 = MathUtil.dotProduct(dirZ1, 0, -dirX1, dirX2, 0, dirZ2)
			local signedDir = dot1 < dot2 and 1 or -1
			local angleToNextSegment = math.acos(MathUtil.dotProduct(dirX1, 0, dirZ1, dirX2, 0, dirZ2))
			if AIFieldCourseCornerCutOut.MIN_ANGLE < angleToNextSegment and angleToNextSegment < AIFieldCourseCornerCutOut.MAX_ANGLE then
				local frontOffset = self.fieldCourseSettings.agentFrontOffset
				local backOffset = self.fieldCourseSettings.agentBackOffset
				local sx = x3 + dirX2 * frontOffset
				local sz = z3 + dirZ2 * frontOffset
				local intersect, ix, iz = FieldCourseUtil.getSegmentBoundaryIntersection(sx, sz, x3 - dirX2 * backOffset, z3 - dirZ2 * backOffset, self.aiFieldCourse.fieldRootBoundary.boundaryLine)
				if intersect or segment2.cutDistance ~= nil then
					local cutDistance = nil
					if segment2.cutDistance ~= nil then
						local distanceToIntersection = segment2.cutDistance - frontOffset
						cutDistance = math.max(backOffset - distanceToIntersection, 1)
						cutDistance = cutDistance + math.max(self.fieldCourseSettings.toolFrontOffset, 0)
					else
						local distanceToIntersection = MathUtil.vector2Length(sx - ix, sz - iz) - frontOffset
						cutDistance = math.max(backOffset - distanceToIntersection, 1)
						if 0 < direction2 then
							local firstPosition = segment2.positions[1]
							firstPosition[1] = x3 + dirX2 * cutDistance
							firstPosition[2] = z3 + dirZ2 * cutDistance
						else
							local lastPosition = segment2.positions[#segment2.positions]
							lastPosition[1] = x3 + dirX2 * cutDistance
							lastPosition[2] = z3 + dirZ2 * cutDistance
						end
					end
					cutDistance = cutDistance + 0.5
					local numExtraSegments = math.max(MathUtil.round(cutDistance / self.fieldCourseSettings.implementWidth), 1)
					local originOffset = totalLength + math.min(cutDistance, self.fieldCourseSettings.implementWidth) + self.fieldCourseSettings.minTurnRadius
					local originPosX = x1 + dirX1 * originOffset
					local originPosZ = z1 + dirZ1 * originOffset
					local firstSegment = { ["positions"] = { { x1, z1, -1 }, { originPosX, originPosZ, -1 } } }
					local helperSegment = {}
					helperSegment.positions = { { x1 + dirX1 * (originOffset + 0.25), z1 + dirZ1 * (originOffset + 0.25), -1 }, { originPosX, originPosZ, -1 } }
					helperSegment.length = FieldCourseUtil.getSegmentLength(helperSegment.positions)
					self.segments = {}
					self.segmentProcessIndex = 1
					table.insert(self.segments, { straight = firstSegment, direction = 1 })
					for i = 1, numExtraSegments do
						local sideOffset = math.clamp(i * self.fieldCourseSettings.implementWidth * signedDir, -cutDistance, cutDistance)
						local segmentExtension = sideOffset * math.tan(1.5707963267948966 - angleToNextSegment) * signedDir
						local ex = x1 + dirZ1 * sideOffset
						local ez = z1 - dirX1 * sideOffset
						ex = ex + dirX1 * segmentExtension
						ez = ez + dirZ1 * segmentExtension
						local length = totalLength * (1 - (i - 1) / numExtraSegments)
						local sx = ex + dirX1 * length
						local sz = ez + dirZ1 * length
						local segment = {}
						segment.positions = { { sx, sz }, { ex, ez } }
						segment.length = FieldCourseUtil.getSegmentLength(segment.positions)
						table.insert(self.segments, { turnToGenerate = { helperSegment, 1, segment, 1, ["forcedDrivingDirection"] = 1 }, direction = 1, isActualLine = true })
						table.insert(self.segments, { straight = segment, direction = 1 })
						table.insert(self.segments, { turnToGenerate = { segment, 1, helperSegment, 1, ["forcedDrivingDirection"] = -1 }, direction = 1 })
					end
					local finalSegment = {}
					finalSegment.positions = { { originPosX, originPosZ, 1 }, { x1 + dirX1 * totalLength, z1 + dirZ1 * totalLength, 1 } }
					finalSegment.length = FieldCourseUtil.getSegmentLength(finalSegment.positions)
					table.insert(self.segments, { straight = finalSegment, direction = 1 })
					table.insert(self.segments, { turnToGenerate = { finalSegment, 1, segment2, direction2 }, direction = 1 })
					self:processSegments()
					return true
				end
			end
		end
		return false
	end
end
function AIFieldCourseCornerCutOut:processSegments()
	while self.segmentProcessIndex <= #self.segments do
		local segment = self.segments[self.segmentProcessIndex]
		if segment.turnToGenerate ~= nil then
			local turn = segment.turnToGenerate
			self.turnGenerator:setForcedDrivingDirection(turn.forcedDrivingDirection or 0)
			self.turnGenerator:generateSegmentToSegment(turn[1], turn[2], turn[3], turn[4])
			break
		end
		self.segmentProcessIndex = self.segmentProcessIndex + 1
	end
	if #self.segments < self.segmentProcessIndex and self.callbackFunc ~= nil then
		for segmentIndex, segment in ipairs(self.segments) do
			local nextSegment = self.segments[segmentIndex + 1]
			local nextTurn = nextSegment ~= nil and nextSegment.turn ~= nil and nextSegment.turn or nil
			local isLast = segmentIndex == #self.segments
			if self.callbackTarget ~= nil then
				self.callbackFunc(self.callbackTarget, segment.straight or segment.turn, segment.direction, segment.turn ~= nil, nextTurn, isLast)
			else
				self.callbackFunc(segment.straight or segment.turn, segment.direction, segment.turn ~= nil, nextTurn, isLast)
			end
		end
	end
end
function AIFieldCourseCornerCutOut:onSegmentTurnDataFound(turn)
	if turn ~= nil then
		local segment = self.segments[self.segmentProcessIndex]
		segment.turn = turn
		segment.turn.isActualLine = segment.isActualLine
		self.segmentProcessIndex = self.segmentProcessIndex + 1
		self:processSegments()
	elseif self.callbackTarget ~= nil then
		self.callbackFunc(self.callbackTarget, nil, nil, nil, nil, true)
	else
		self.callbackFunc(nil, nil, nil, nil, true)
	end
end
