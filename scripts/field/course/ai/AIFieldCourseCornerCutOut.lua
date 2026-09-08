-- Local values: AIFieldCourseCornerCutOut_mt
AIFieldCourseCornerCutOut = {}
AIFieldCourseCornerCutOut.MIN_ANGLE = 0.5235987755982988
AIFieldCourseCornerCutOut.MAX_ANGLE = 2.0943951023931953
local AIFieldCourseCornerCutOut_mt = Class(AIFieldCourseCornerCutOut)

-- Upvalues: AIFieldCourseCornerCutOut_mt
-- Local values: self
function AIFieldCourseCornerCutOut.new(aiFieldCourse, segments)
	-- upvalues: (copy) AIFieldCourseCornerCutOut_mt
	local v3_ = AIFieldCourseCornerCutOut_mt
	local v4_ = setmetatable({}, v3_)
	v4_.aiFieldCourse = aiFieldCourse
	v4_.fieldCourseSettings = aiFieldCourse.fieldCourseSettings
	v4_.turnGenerator = AIFieldCourseTurnGenerator.new(aiFieldCourse)
	v4_.turnGenerator:setCallback(v4_.onSegmentTurnDataFound, v4_)
	v4_.turnGenerator:setPreferOneDrivingDirection(true)
	return v4_
end

function AIFieldCourseCornerCutOut:setCallback(callbackFunc, callbackTarget)
	self.callbackFunc = callbackFunc
	self.callbackTarget = callbackTarget
end

-- Local values: totalLength, x1, z1, x2, z2, x3, z3, x4, z4, dirX1, dirZ1, length1, dirX2, dirZ2, length2, dot1, dot2, signedDir, angleToNextSegment, frontOffset, backOffset, sx, sz, intersect, ix, iz, cutDistance, distanceToIntersection, distanceToIntersection, firstPosition, lastPosition, numExtraSegments, originOffset, originPosX, originPosZ, firstSegment, helperSegment, i, sideOffset, segmentExtension, ex, ez, length, sx, sz, segment, finalSegment
function AIFieldCourseCornerCutOut:validateSegments(segment1, direction1, segment2, direction2)
	if not (segment1.isHeadlandSegment and segment2.isHeadlandSegment) then
		return false
	end
	local v13_ = self.fieldCourseSettings.agentBackOffset + self.fieldCourseSettings.agentFrontOffset
	if v13_ < self.fieldCourseSettings.implementWidth then
		return false
	end
	local v14_, v15_ = AIFieldCourseUtil.getSegmentPosition(false, segment1, direction1)
	local v16_, v17_ = AIFieldCourseUtil.getSegmentPosition(false, segment1, direction1, 1)
	local v18_, v19_ = AIFieldCourseUtil.getSegmentPosition(true, segment2, direction2)
	local v20_, v21_ = AIFieldCourseUtil.getSegmentPosition(true, segment2, direction2, 1)
	local v22_ = v16_ - v14_
	local v23_ = v17_ - v15_
	local v24_ = MathUtil.vector2Length(v22_, v23_)
	local v25_ = v22_ / v24_
	local v26_ = v23_ / v24_
	local v27_ = v20_ - v18_
	local v28_ = v21_ - v19_
	local v29_ = MathUtil.vector2Length(v27_, v28_)
	local v30_ = v27_ / v29_
	local v31_ = v28_ / v29_
	if v13_ + 0.1 < v24_ and v13_ + 0.1 < v29_ then
		local v32_ = MathUtil.dotProduct(-v26_, 0, v25_, v30_, 0, v31_) < MathUtil.dotProduct(v26_, 0, -v25_, v30_, 0, v31_) and 1 or -1
		local v33_ = MathUtil.dotProduct(v25_, 0, v26_, v30_, 0, v31_)
		local v34_ = math.acos(v33_)
		if AIFieldCourseCornerCutOut.MIN_ANGLE < v34_ and v34_ < AIFieldCourseCornerCutOut.MAX_ANGLE then
			local v35_ = self.fieldCourseSettings.agentFrontOffset
			local v36_ = self.fieldCourseSettings.agentBackOffset
			local v37_ = v18_ + v30_ * v35_
			local v38_ = v19_ + v31_ * v35_
			local v39_, v40_, v41_ = FieldCourseUtil.getSegmentBoundaryIntersection(v37_, v38_, v18_ - v30_ * v36_, v19_ - v31_ * v36_, self.aiFieldCourse.fieldRootBoundary.boundaryLine)
			if v39_ or segment2.cutDistance ~= nil then
				local v42_
				if segment2.cutDistance == nil then
					local v43_ = v36_ - (MathUtil.vector2Length(v37_ - v40_, v38_ - v41_) - v35_)
					v42_ = math.max(v43_, 1)
					if direction2 > 0 then
						local v44_ = segment2.positions[1]
						local v45_ = v18_ + v30_ * v42_
						local v46_ = v19_ + v31_ * v42_
						v44_[1] = v45_
						v44_[2] = v46_
					else
						local v47_ = segment2.positions[#segment2.positions]
						local v48_ = v18_ + v30_ * v42_
						local v49_ = v19_ + v31_ * v42_
						v47_[1] = v48_
						v47_[2] = v49_
					end
				else
					local v50_ = v36_ - (segment2.cutDistance - v35_)
					local v51_ = math.max(v50_, 1)
					local v52_ = self.fieldCourseSettings.toolFrontOffset
					v42_ = v51_ + math.max(v52_, 0)
				end
				local v53_ = v42_ + 0.5
				local v54_ = MathUtil.round(v53_ / self.fieldCourseSettings.implementWidth)
				local v55_ = math.max(v54_, 1)
				local v56_ = self.fieldCourseSettings.implementWidth
				local v57_ = v13_ + math.min(v53_, v56_) + self.fieldCourseSettings.minTurnRadius
				local v58_ = v14_ + v25_ * v57_
				local v59_ = v15_ + v26_ * v57_
				local v60_ = {
					["positions"] = {
						{ v14_ + v25_ * (v57_ + 0.25), v15_ + v26_ * (v57_ + 0.25), -1 },
						{ v58_, v59_, -1 }
					}
				}
				v60_.length = FieldCourseUtil.getSegmentLength(v60_.positions)
				self.segments = {}
				self.segmentProcessIndex = 1
				local v61_ = self.segments
				table.insert(v61_, {
					["straight"] = {
						["positions"] = {
							{ v14_, v15_, -1 },
							{ v58_, v59_, -1 }
						}
					},
					["direction"] = 1
				})
				for v62_ = 1, v55_ do
					local v63_ = v62_ * self.fieldCourseSettings.implementWidth * v32_
					local v64_ = -v53_
					local v65_ = math.clamp(v63_, v64_, v53_)
					local v66_ = 1.5707963267948966 - v34_
					local v67_ = v65_ * math.tan(v66_) * v32_
					local v68_ = v14_ + v26_ * v65_
					local v69_ = v15_ - v25_ * v65_
					local v70_ = v68_ + v25_ * v67_
					local v71_ = v69_ + v26_ * v67_
					local v72_ = v13_ * (1 - (v62_ - 1) / v55_)
					local v73_ = {
						["positions"] = {
							{ v70_ + v25_ * v72_, v71_ + v26_ * v72_ },
							{ v70_, v71_ }
						}
					}
					v73_.length = FieldCourseUtil.getSegmentLength(v73_.positions)
					local v74_ = self.segments
					table.insert(v74_, {
						["turnToGenerate"] = {
							v60_,
							1,
							v73_,
							1,
							["forcedDrivingDirection"] = 1
						},
						["direction"] = 1,
						["isActualLine"] = true
					})
					local v75_ = self.segments
					table.insert(v75_, {
						["straight"] = v73_,
						["direction"] = 1
					})
					local v76_ = self.segments
					table.insert(v76_, {
						["turnToGenerate"] = {
							v73_,
							1,
							v60_,
							1,
							["forcedDrivingDirection"] = -1
						},
						["direction"] = 1
					})
				end
				local v77_ = {
					["positions"] = {
						{ v58_, v59_, 1 },
						{ v14_ + v25_ * v13_, v15_ + v26_ * v13_, 1 }
					}
				}
				v77_.length = FieldCourseUtil.getSegmentLength(v77_.positions)
				local v78_ = self.segments
				table.insert(v78_, {
					["straight"] = v77_,
					["direction"] = 1
				})
				local v79_ = self.segments
				table.insert(v79_, {
					["turnToGenerate"] = {
						v77_,
						1,
						segment2,
						direction2
					},
					["direction"] = 1
				})
				self:processSegments()
				return true
			end
		end
	end
	return false
end

-- Local values: segment, turn, segmentIndex, segment, nextSegment, nextTurn, isLast
function AIFieldCourseCornerCutOut:processSegments()
	while self.segmentProcessIndex <= #self.segments do
		local v81_ = self.segments[self.segmentProcessIndex]
		if v81_.turnToGenerate ~= nil then
			local v82_ = v81_.turnToGenerate
			self.turnGenerator:setForcedDrivingDirection(v82_.forcedDrivingDirection or 0)
			self.turnGenerator:generateSegmentToSegment(v82_[1], v82_[2], v82_[3], v82_[4])
			break
		end
		self.segmentProcessIndex = self.segmentProcessIndex + 1
	end
	if self.segmentProcessIndex > #self.segments and self.callbackFunc ~= nil then
		for v83_, v84_ in ipairs(self.segments) do
			local v85_ = self.segments[v83_ + 1]
			local v86_
			if v85_ == nil or v85_.turn == nil then
				v86_ = nil
			else
				v86_ = v85_.turn or nil
			end
			local v87_ = v83_ == #self.segments
			if self.callbackTarget == nil then
				self.callbackFunc(v84_.straight or v84_.turn, v84_.direction, v84_.turn ~= nil, v86_, v87_)
			else
				self.callbackFunc(self.callbackTarget, v84_.straight or v84_.turn, v84_.direction, v84_.turn ~= nil, v86_, v87_)
			end
		end
	end
end

-- Local values: segment
function AIFieldCourseCornerCutOut:onSegmentTurnDataFound(turn)
	if turn == nil then
		if self.callbackTarget == nil then
			self.callbackFunc(nil, nil, nil, nil, true)
		else
			self.callbackFunc(self.callbackTarget, nil, nil, nil, nil, true)
		end
	else
		local v90_ = self.segments[self.segmentProcessIndex]
		v90_.turn = turn
		v90_.turn.isActualLine = v90_.isActualLine
		self.segmentProcessIndex = self.segmentProcessIndex + 1
		self:processSegments()
		return
	end
end
