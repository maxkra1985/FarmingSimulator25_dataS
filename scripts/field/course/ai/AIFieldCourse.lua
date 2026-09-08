-- Local values: AIFieldCourse_mt
AIFieldCourse = {}
source("dataS/scripts/field/course/ai/AIFieldCourseState.lua")
source("dataS/scripts/field/course/ai/AIFieldCourseUtil.lua")
source("dataS/scripts/field/course/ai/AIFieldCourseReconstructionData.lua")
source("dataS/scripts/field/course/ai/AIFieldCourseCornerCutOut.lua")
source("dataS/scripts/field/course/ai/AIFieldCourseFirstSegmentDetection.lua")
source("dataS/scripts/field/course/ai/AIFieldCourseInitialSegment.lua")
source("dataS/scripts/field/course/ai/AIFieldCourseSegment.lua")
source("dataS/scripts/field/course/ai/AIFieldCourseSegmentOrderTask.lua")
source("dataS/scripts/field/course/ai/AIFieldCourseSegmentCollisionCheck.lua")
source("dataS/scripts/field/course/ai/AIFieldCourseTurn.lua")
source("dataS/scripts/field/course/ai/AIFieldCourseTurnCollisionCheck.lua")
source("dataS/scripts/field/course/ai/AIFieldCourseTurnData.lua")
source("dataS/scripts/field/course/ai/AIFieldCourseTurnSegment.lua")
source("dataS/scripts/field/course/ai/AIFieldCourseTurnSegmentType.lua")
source("dataS/scripts/field/course/ai/AIFieldCourseTurnGenerator.lua")
source("dataS/scripts/field/course/ai/AIFieldCourseTurnGeneratorState.lua")
source("dataS/scripts/field/course/ai/dubinsPath/DubinsPath.lua")
source("dataS/scripts/field/course/ai/reedsSheppPath/ReedsSheppPath.lua")
AIFieldCourse.SEGMENT_INITIALIZATION_BUDGET = 0.00025
AIFieldCourse.SEGMENT_INITIALIZATION_STEP = 10
AIFieldCourse.QUEUE_MIN_LENGTH = 2
local AIFieldCourse_mt = Class(AIFieldCourse)

-- Upvalues: AIFieldCourse_mt
-- Local values: self
function AIFieldCourse.new(fieldCourse)
	-- upvalues: (copy) AIFieldCourse_mt
	local v3_ = AIFieldCourse_mt
	local v4_ = setmetatable({}, v3_)
	v4_.fieldCourse = fieldCourse
	v4_.fieldCourseSettings = fieldCourse.fieldCourseSettings
	v4_.fieldRootBoundary = fieldCourse.courseField.fieldRootBoundary
	v4_.islands = fieldCourse.courseField.islands
	v4_.headlandBoundaries = fieldCourse.courseField.headlandBoundaries
	v4_.implementWidth = v4_.fieldCourseSettings.implementWidth
	v4_.segmentAreaValidityFunc = nil
	v4_.startX = nil
	v4_.startZ = nil
	v4_.startYRot = nil
	v4_.startDirX = nil
	v4_.startDirZ = nil
	v4_.lastVehicleX = nil
	v4_.lastVehicleZ = nil
	v4_.alternativeTurnSegments = {}
	v4_.segmentQueue = {}
	v4_.segmentPosition = 0
	v4_.segmentLength = 1
	v4_.subSegmentPosition = 0
	v4_.subSegmentLength = 1
	v4_.usedSegments = {}
	v4_.state = AIFieldCourseState.NONE
	v4_.lastSegmentLength = -1
	v4_.segmentInitializeIndex = 1
	v4_.segmentInitializeTime = 0
	v4_.segmentInitializeFrames = 0
	v4_.segmentsToSkip = {}
	v4_.lastActiveSegmentId = nil
	v4_.headlandTailAvoidanceIndex = 1
	v4_.headlandTailAvoidanceMaxIndex = -1
	return v4_
end

function AIFieldCourse:setStartPosition(x, z, yRot)
	self.startX = x
	self.startZ = z
	self.startYRot = yRot
	local v9_, v10_ = MathUtil.getDirectionFromYRotation(yRot)
	self.startDirX = v9_
	self.startDirZ = v10_
end

function AIFieldCourse:setInitialSegmentCallback(callback)
	self.initialSegmentCallback = callback
	self.initialSegmentDone = false
end

function AIFieldCourse:setSegmentsToSkip(segmentsToSkip)
	self.segmentsToSkip = segmentsToSkip
end

function AIFieldCourse:setLastActiveSegmentId(lastActiveSegmentId)
	self.lastActiveSegmentId = lastActiveSegmentId
end

function AIFieldCourse:finalize(finalizeCallback, finalizeCallbackTarget)
	if self.fieldCourse.courseField == nil then
		Logging.error("Invalid AIFieldCourse. Missing field data in FieldCourse.")
	else
		self.fieldRootBoundary = self.fieldCourse.courseField.fieldRootBoundary
		self.protectedBoundary = self.fieldCourse.courseField:setProtectedBoundary(self.fieldCourseSettings:getProtectedBoundarySize())
		self.validPathBoundary = self.headlandBoundaries[1] or self.fieldRootBoundary
		self.islands = self.fieldCourse.courseField.islands
		self.segmentOrderTask = AIFieldCourseSegmentOrderTask.new(self)
		if self.overwrittenSegments ~= nil then
			self.segmentOrderTask:setOverwrittenSegments(self.overwrittenSegments)
		end
		self.segmentOrderTask:setSegmentsToSkip(self.segmentsToSkip)
		self.segmentOrderTask:setLastActiveSegmentId(self.lastActiveSegmentId)
		self.segmentOrderTask:setAlternativeTurnSegmentData(self.alternativeTurnSegments)
		self.finalizeCallback = finalizeCallback
		self.finalizeCallbackTarget = finalizeCallbackTarget
		self.state = AIFieldCourseState.INITIALIZATION
	end
end

function AIFieldCourse:setOverwrittenSegments(overwrittenSegments)
	self.overwrittenSegments = overwrittenSegments
end

function AIFieldCourse:setSegmentSwitchedCallback(segmentSwitchedCallback)
	self.segmentSwitchedCallback = segmentSwitchedCallback
end

-- Local values: nextAvailableSegment, i, segment
function AIFieldCourse:onNextSegmentFound(segmentData, direction, isTurn, addStraighting, nextTurn, isLast)
	if segmentData == nil then
		if self.state ~= AIFieldCourseState.NO_MORE_SEGMENTS_FOUND then
			self:debugPrint("No more new segments found. Finishing segment queue.")
			self.state = AIFieldCourseState.NO_MORE_SEGMENTS_FOUND
		end
		return
	end
	local v30_ = nil
	for v31_ = 1, #self.segmentQueue do
		local v32_ = self.segmentQueue[v31_]
		if not v32_:isValid() and v32_:isReady() then
			v30_ = v32_
			break
		end
	end
	if v30_ == nil then
		local v33_ = self.segmentQueue
		local v34_ = AIFieldCourseSegment.new
		local v35_ = self.fieldCourseSettings
		table.insert(v33_, v34_(v35_))
		v30_ = self.segmentQueue[#self.segmentQueue]
	end
	if isTurn then
		self.lastTurn = segmentData
		v30_:setTurn(segmentData, addStraighting)
	else
		v30_:setSegment(segmentData, direction, self.lastTurn, nextTurn)
	end
end

-- Local values: segment
function AIFieldCourse:skipCurrentSubSegment(maxDistance)
	local v38_ = self.segmentQueue[1]
	if v38_ ~= nil and (v38_:isReady() and v38_:isValid()) then
		v38_:skipCurrentSubSegment(maxDistance)
		self:update(999)
	end
end

function AIFieldCourse:setSegmentAreaValidityFunction(segmentAreaValidityFunc)
	self.segmentAreaValidityFunc = segmentAreaValidityFunc
end

function AIFieldCourse:getIsSegmentAreaValid(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	return self.segmentAreaValidityFunc == nil and true or self.segmentAreaValidityFunc(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
end

-- Local values: segment
function AIFieldCourse:getActiveSegment()
	local v49_ = self.segmentQueue[1]
	if v49_ == nil or not (v49_:isValid() and v49_:isReady()) then
		return nil
	else
		return v49_
	end
end

-- Local values: segment
function AIFieldCourse:getActiveSegmentData()
	local v51_ = self.segmentQueue[1]
	if v51_ == nil or not (v51_:isValid() and v51_:isReady()) then
		return nil, nil, nil, nil, nil
	else
		return not v51_:getIsOnActualLine(), v51_.isInitialLine, self.segmentPosition, self.segmentLength, self.subSegmentPosition, self.subSegmentLength
	end
end

-- Local values: segment
function AIFieldCourse:getIsCornerCutOutActive()
	local v53_ = self.segmentQueue[1]
	if v53_ == nil or not (v53_:isValid() and v53_:isReady()) then
		return false
	else
		return v53_.isCornerCutOut
	end
end

-- Local values: segment
function AIFieldCourse:getNextSegmentData()
	local v55_ = self.segmentQueue[2]
	if v55_ == nil or not (v55_:isValid() and v55_:isReady()) then
		return nil, nil
	else
		return v55_.isInitialLine, v55_.sideOffset
	end
end

-- Local values: segment
function AIFieldCourse:getActiveSegmentSideOffset()
	local v57_ = self.segmentQueue[1]
	return (v57_ == nil or not (v57_:isValid() and v57_:isReady())) and 0 or v57_.sideOffset
end

-- Local values: segment
function AIFieldCourse:getPositionOffsetToActiveSegment(x, z)
	local v61_ = self.segmentQueue[1]
	return (v61_ == nil or not (v61_:isValid() and v61_:isReady())) and math.huge or v61_:getSignedOffsetToSegment(x, z)
end

-- Local values: startTime, delta, index, segment, sideOffset, _, segment, i, segment, i, segment, index, segment, index, segment, numSegmentsLeft, _, segment, segment, segmentId
function AIFieldCourse:update(dt, forceSegmentSkip)
	if self.state == AIFieldCourseState.INITIALIZATION then
		local v64_ = getTimeSec()
		while self:updateSegmentInitialization() do
			local v65_ = getTimeSec() - v64_
			if AIFieldCourse.SEGMENT_INITIALIZATION_BUDGET < v65_ then
				self.segmentInitializeFrames = self.segmentInitializeFrames + 1
				self.segmentInitializeTime = self.segmentInitializeTime + v65_
				return
			end
		end
		self.segmentInitializeFrames = self.segmentInitializeFrames + 1
		self.segmentInitializeTime = self.segmentInitializeTime + (getTimeSec() - v64_)
		for v66_, v67_ in ipairs(self.fieldCourse.segments) do
			v67_.index = v66_
		end
		local v68_ = self.fieldCourseSettings.sideOffset
		if v68_ ~= 0 then
			for _, v69_ in ipairs(self.fieldCourse.segments) do
				if v69_.isHeadlandSegment or v69_.isIslandSegment then
					if self.fieldCourseSettings.sideOffsetHeadlandAlternate then
						if v69_.headlandIndex % 2 == 0 then
							v69_.sideOffset = -v68_
							v69_.sideOffsetToApply = -math.abs(v68_)
							v69_.lockedDirection = -math.sign(v68_)
						else
							v69_.sideOffset = v68_
							v69_.sideOffsetToApply = math.abs(v68_)
							v69_.lockedDirection = math.sign(v68_)
						end
					elseif v68_ > 0 then
						v69_.sideOffset = -v68_
						v69_.sideOffsetToApply = -v68_
						v69_.lockedDirection = -1
					else
						v69_.sideOffset = v68_
						v69_.sideOffsetToApply = v68_
						v69_.lockedDirection = 1
					end
				end
			end
		end
		if self.fieldCourseSettings.skipNumLines > 0 then
			for v70_ = #self.fieldCourse.segments, 1, -1 do
				local v71_ = self.fieldCourse.segments[v70_]
				if v71_.lineGroupIndex ~= nil and (v71_.offsetLineIndex - 1) % (self.fieldCourseSettings.skipNumLines + 1) ~= 0 then
					table.remove(self.fieldCourse.segments, v70_)
				end
			end
		end
		if not self.fieldCourseSettings.workHeadlands then
			for v72_ = #self.fieldCourse.segments, 1, -1 do
				local v73_ = self.fieldCourse.segments[v72_]
				if v73_.isHeadlandSegment or v73_.isIslandSegment then
					table.remove(self.fieldCourse.segments, v72_)
				end
			end
		end
		for v74_, v75_ in ipairs(self.fieldCourse.segments) do
			v75_.index = v74_
		end
		self.state = AIFieldCourseState.HEADLAND_TAIL_AVOIDANCE
		self:debugPrint("Segment initialization took %.1fms / %d frames", self.segmentInitializeTime * 1000, self.segmentInitializeFrames)
	elseif self.state == AIFieldCourseState.HEADLAND_TAIL_AVOIDANCE then
		if not (self.fieldCourseSettings.headlandTailAvoidance and self.fieldCourseSettings.workHeadlands) then
			self.state = AIFieldCourseState.INITIAL_SEGMENT_CREATION
			return
		end
		if not self:updateHeadlandTailAvoidance() then
			for v76_, v77_ in ipairs(self.fieldCourse.segments) do
				v77_.index = v76_
			end
			self.state = AIFieldCourseState.INITIAL_SEGMENT_CREATION
			return
		end
	elseif self.state == AIFieldCourseState.INITIAL_SEGMENT_CREATION then
		if self.initialSegment == nil then
			if #self.fieldCourse.segments == 0 then
				self:debugPrint("No valid segments found. Stopping AI.")
				self.state = AIFieldCourseState.FINISHED
				if self.finalizeCallback ~= nil then
					self.finalizeCallback(self.finalizeCallbackTarget)
					self.finalizeCallback = nil
				end
			else
				self:debugPrint("Initial segment detection")
				self.initialSegment = AIFieldCourseInitialSegment.new(self)
				self.initialSegment:setCallback(function(p78_, p79_, p80_, p81_, p82_, p83_, p84_)
					-- upvalues: (copy) self
					if p78_ then
						self:onNextSegmentFound(p80_, p81_, p82_, p83_, p84_)
						if p79_ then
							if self.initialSegment.intoFieldSegment == nil then
								self:debugPrint("No into field segment found. Directly prepare for work.")
								if not self.initialSegmentDone then
									if self.initialSegmentCallback ~= nil then
										self.initialSegmentCallback()
									end
									self.initialSegmentDone = true
								end
							end
							self.state = AIFieldCourseState.REGULAR_SEGMENTS
							self.initialSegment = nil
						end
					else
						self:debugPrint("Failed to generate initial segment")
						self.state = AIFieldCourseState.FINISHED
						self.initialSegment = nil
					end
					if self.finalizeCallback ~= nil then
						self.finalizeCallback(self.finalizeCallbackTarget)
						self.finalizeCallback = nil
					end
				end, nil)
				self.initialSegment:generate(self.startX, self.startZ, self.startDirX, self.startDirZ)
			end
		end
	elseif self.state == AIFieldCourseState.REGULAR_SEGMENTS or self.state == AIFieldCourseState.NO_MORE_SEGMENTS_FOUND then
		local v85_ = 0
		for _, v86_ in ipairs(self.segmentQueue) do
			if v86_:isValid() or not v86_:isReady() then
				v85_ = v85_ + 1
			end
		end
		if v85_ > 0 then
			local v87_ = self.segmentQueue[1]
			if v87_ ~= nil and v87_:isReady() then
				if v87_:isValid() then
					if self.lastSegmentLength ~= v87_.length then
						self.lastSegmentLength = v87_.length
						if self.segmentSwitchedCallback ~= nil then
							self.segmentSwitchedCallback(v87_)
						end
					end
					if forceSegmentSkip then
						v87_:skipCurrentSubSegment(math.huge)
					end
				else
					local v88_ = self.segmentQueue[1].segmentId
					if v88_ ~= nil then
						self.usedSegments[v88_] = true
					end
					table.remove(self.segmentQueue, 1)
					local v89_ = self.segmentQueue
					table.insert(v89_, v87_)
					v87_:reset()
					if not self.initialSegmentDone then
						if self.initialSegmentCallback ~= nil then
							self.initialSegmentCallback()
						end
						self.initialSegmentDone = true
					end
				end
			end
		end
		if v85_ < AIFieldCourse.QUEUE_MIN_LENGTH then
			if self.state == AIFieldCourseState.NO_MORE_SEGMENTS_FOUND then
				if v85_ == 0 then
					self.state = AIFieldCourseState.FINISHED
				end
			elseif not self.segmentOrderTask:getSegmentSearchPending() then
				self.segmentOrderTask:next(self.onNextSegmentFound, self)
				return
			end
		end
	end
end

-- Local values: halfWidth, segment, step, state, i, p1, p2, dirX, dirZ, length, startPos, endPos, startPosClamped, endPosClamped, offsetLeft, offsetRight, segmentValidityCheckOffset, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, j, newSegment, j, j, removedSegmentId, segmentIdStillValid, _, otherSegment
function AIFieldCourse:updateSegmentInitialization()
	local v91_ = self.implementWidth * 0.5 - 0.15
	local v92_ = self.fieldCourse.segments[self.segmentInitializeIndex]
	local v93_ = self.fieldCourseSettings.segmentSplitDistance
	if v92_ == nil then
		return false
	end
	local v94_ = nil
	for v95_ = 1, #v92_.positions - 1 do
		local v96_ = v92_.positions[v95_]
		local v97_ = v92_.positions[v95_ + 1]
		local v98_ = v97_[1] - v96_[1]
		local v99_ = v97_[2] - v96_[2]
		local v100_ = MathUtil.vector2Length(v98_, v99_)
		local v101_ = v98_ / v100_
		local v102_ = v99_ / v100_
		local v103_ = 0
		for v104_ = v93_, v100_ + v93_ - 0.01, v93_ do
			local v105_ = v103_ / v100_
			local v106_ = math.min(v105_, 1) * v100_
			local v107_ = v104_ / v100_
			local v108_ = math.min(v107_, 1) * v100_
			local v109_, v110_
			if v92_.isHeadlandSegment then
				if v92_.headlandIndex == 1 then
					local v111_ = v91_ - 0.25
					v109_ = math.max(v111_, 0.5)
					v110_ = v91_
				elseif v92_.headlandIndex == self.fieldCourse.numHeadlands then
					local v112_ = v91_ - 0.5
					v110_ = math.max(v112_, 0.5)
					v109_ = v91_
				else
					v109_ = v91_
					v110_ = v109_
					local v113_ = v109_
					v109_ = v110_
					v113_ = v110_
				end
			else
				v109_ = v91_
				v110_ = v109_
				local v114_ = v109_
				v109_ = v110_
				v114_ = v110_
			end
			local v115_ = self.fieldCourseSettings.segmentValidityCheckOffset
			if v115_ ~= 0 then
				local v116_ = v109_ - v115_
				v109_ = math.max(v116_, 0.5)
				local v117_ = v110_ - v115_
				v110_ = math.max(v117_, 0.5)
			end
			if self:getIsSegmentAreaValid(v96_[1] + v101_ * v103_ - v102_ * v110_, v96_[2] + v102_ * v103_ + v101_ * v110_, v96_[1] + v101_ * v103_ + v102_ * v109_, v96_[2] + v102_ * v103_ - v101_ * v109_, v96_[1] + v101_ * v104_ - v102_ * v110_, v96_[2] + v102_ * v104_ + v101_ * v110_) then
				if v94_ == false then
					v92_.positions[v95_] = { v96_[1] + v101_ * v106_, v96_[2] + v102_ * v106_ }
					for v118_ = v95_ - 1, 1, -1 do
						table.remove(v92_.positions, v118_)
					end
					FieldCourseUtil.removeShortSegments(v92_.positions, 0.01, false)
					v92_.length = FieldCourseUtil.getSegmentLength(v92_.positions)
					if v92_.length <= 0 or #v92_.positions < 2 then
						self.usedSegments[v92_.segmentId] = true
						table.remove(self.fieldCourse.segments, self.segmentInitializeIndex)
					end
					return true
				end
				v94_ = true
			else
				if v94_ == true then
					local v119_ = {
						["positions"] = {}
					}
					for v120_ = 1, v95_ do
						local v121_ = v119_.positions
						local v122_ = v92_.positions[v120_]
						table.insert(v121_, v122_)
					end
					local v123_ = v119_.positions
					local v124_ = { v96_[1] + v101_ * v106_, v96_[2] + v102_ * v106_ }
					table.insert(v123_, v124_)
					for v125_ = v95_, 1, -1 do
						table.remove(v92_.positions, v125_)
					end
					local v126_ = v92_.positions
					local v127_ = { v96_[1] + v101_ * v108_, v96_[2] + v102_ * v108_ }
					table.insert(v126_, 1, v127_)
					FieldCourseUtil.removeShortSegments(v92_.positions, 0.01, false)
					v92_.length = FieldCourseUtil.getSegmentLength(v92_.positions)
					if v92_.length <= 0 or #v92_.positions < 2 then
						table.remove(self.fieldCourse.segments, self.segmentInitializeIndex)
					end
					FieldCourseUtil.removeShortSegments(v119_.positions, 0.01, false)
					v119_.length = FieldCourseUtil.getSegmentLength(v119_.positions)
					if v119_.length > 0 and #v119_.positions >= 2 then
						v119_.lineGroupIndex = v92_.lineGroupIndex
						v119_.isHeadlandSegment = v92_.isHeadlandSegment
						v119_.isIslandSegment = v92_.isIslandSegment
						v119_.islandIndex = v92_.islandIndex
						v119_.headlandIndex = v92_.headlandIndex
						v119_.segmentId = v92_.segmentId
						v119_.offsetLineIndex = v92_.offsetLineIndex
						local v128_ = self.fieldCourse.segments
						local v129_ = self.segmentInitializeIndex
						table.insert(v128_, v129_, v119_)
						self.segmentInitializeIndex = self.segmentInitializeIndex + 1
					end
					return true
				end
				v94_ = false
			end
			v103_ = v104_
		end
	end
	if v94_ == false then
		local v130_ = v92_.segmentId
		table.remove(self.fieldCourse.segments, self.segmentInitializeIndex)
		local v131_ = false
		for _, v132_ in ipairs(self.fieldCourse.segments) do
			if v132_.segmentId == v130_ then
				v131_ = true
			end
		end
		if not v131_ then
			self.usedSegments[v92_.segmentId] = true
		end
	else
		self.segmentInitializeIndex = self.segmentInitializeIndex + 1
	end
	return true
end

-- Local values: headlandDirection, _, segment, cutDistance, agentBackOffset, _, segment, x1, z1, x2, z2, dx, dz, boundary, i, sx, sz, ex, ez, intersect, ix, iz, distance, segmentCutDistance, i, _, segment, x1, z1, x2, z2, dx, dz, minDistance, minX, minZ, boundary, i, sx, sz, ex, ez, intersect, ix, iz, distance, _, segment
function AIFieldCourse:updateHeadlandTailAvoidance()
	local v134_ = self.fieldCourseSettings.sideOffset == 0 and 1 or -1
	if self.headlandTailAvoidanceMaxIndex < 0 then
		for _, v135_ in ipairs(self.fieldCourse.segments) do
			if v135_.isHeadlandSegment then
				local v136_ = v135_.headlandIndex
				local v137_ = self.headlandTailAvoidanceMaxIndex
				self.headlandTailAvoidanceMaxIndex = math.max(v136_, v137_)
			end
		end
	end
	local v138_ = self.fieldCourseSettings.implementWidth * (self.headlandTailAvoidanceIndex + 0.5)
	local v139_ = self.fieldCourseSettings.agentBackOffset
	local v140_ = self.fieldCourseSettings.toolBackOffset
	local v141_ = v139_ + math.max(v140_, 0)
	for _, v142_ in ipairs(self.fieldCourse.segments) do
		if v142_.isHeadlandSegment and v142_.headlandIndex == self.headlandTailAvoidanceIndex then
			local v143_, v144_ = AIFieldCourseUtil.getSegmentPosition(true, v142_, v134_, 0)
			local v145_, v146_ = AIFieldCourseUtil.getSegmentPosition(true, v142_, v134_, 1)
			local v147_, v148_ = MathUtil.vector2Normalize(v143_ - v145_, v144_ - v146_)
			local v149_ = self.fieldRootBoundary.boundaryLine
			for v150_ = 1, #v149_ - 1 do
				local v151_ = v149_[v150_][1]
				local v152_ = v149_[v150_][2]
				local v153_ = v149_[v150_ + 1][1]
				local v154_ = v149_[v150_ + 1][2]
				local v155_, v156_, v157_ = MathUtil.getLineSegmentsIntersection(v151_, v152_, v153_, v154_, v143_, v144_, v143_ + v147_ * v141_, v144_ + v148_ * v141_)
				if v155_ then
					local v158_ = v141_ - MathUtil.vector2Length(v156_ - v143_, v157_ - v144_)
					if AIFieldCourseUtil.cutSegmentByDistance(v142_, v134_, v158_) then
						v142_.cutDistance = v158_
					else
						v142_.isInvalid = true
					end
					break
				end
			end
		end
	end
	for v159_ = #self.fieldCourse.segments, 1, -1 do
		if self.fieldCourse.segments[v159_].isInvalid then
			self.usedSegments[self.fieldCourse.segments[v159_].segmentId] = true
			table.remove(self.fieldCourse.segments, v159_)
		end
	end
	for _, v160_ in ipairs(self.fieldCourse.segments) do
		if v160_.isHeadlandSegment and v160_.headlandIndex == self.headlandTailAvoidanceIndex then
			local v161_, v162_ = AIFieldCourseUtil.getSegmentPosition(false, v160_, v134_, 0)
			local v163_, v164_ = AIFieldCourseUtil.getSegmentPosition(false, v160_, v134_, 1)
			local v165_, v166_ = MathUtil.vector2Normalize(v161_ - v163_, v162_ - v164_)
			local v167_ = self.fieldRootBoundary.boundaryLine
			local v168_ = math.huge
			local v169_ = nil
			local v170_ = nil
			for v171_ = 1, #v167_ - 1 do
				local v172_ = v167_[v171_][1]
				local v173_ = v167_[v171_][2]
				local v174_ = v167_[v171_ + 1][1]
				local v175_ = v167_[v171_ + 1][2]
				local v176_, v177_, v178_ = MathUtil.getLineSegmentsIntersection(v172_, v173_, v174_, v175_, v161_, v162_, v161_ + v165_ * v138_, v162_ + v166_ * v138_)
				if v176_ then
					if MathUtil.vector2Length(v177_ - v161_, v178_ - v162_) < v168_ then
						v170_ = v178_
						v169_ = v177_
					end
					break
				end
			end
			if v169_ ~= nil then
				if v134_ == 1 then
					v160_.positions[#v160_.positions] = { v169_, v170_ }
				else
					v160_.positions[1] = { v169_, v170_ }
				end
			end
		end
	end
	for _, v179_ in ipairs(self.fieldCourse.segments) do
		if v179_.isHeadlandSegment then
			v179_.lockedDirection = v134_
		end
	end
	self.headlandTailAvoidanceIndex = self.headlandTailAvoidanceIndex + 1
	return self.headlandTailAvoidanceIndex <= self.headlandTailAvoidanceMaxIndex
end

-- Local values: segment, steeringFactorLength, steeringFactor, tx, tz, direction, segmentPosition, segmentLength, subSegmentPosition, subSegmentLength, maxSpeed, distanceToEnd
function AIFieldCourse:getDriveData(dt, vX, vY, vZ, vSpeed, steeringOffset, toolReverserDirectionNode)
	if self.state == AIFieldCourseState.FINISHED then
		return nil, nil, true, 0, 0
	end
	self.lastVehicleX = vX
	self.lastVehicleZ = vZ
	local v188_ = self.segmentQueue[1]
	if v188_ ~= nil and (v188_:isReady() and v188_:isValid()) then
		local v189_ = self.subSegmentLength * 0.5
		local v190_ = math.min(v189_, 4)
		local v191_
		if self.subSegmentPosition < 0.5 then
			local v192_ = self.subSegmentPosition * self.subSegmentLength
			v191_ = math.clamp(v192_, 0, v190_) / v190_
		else
			local v193_ = (1 - self.subSegmentPosition) * self.subSegmentLength
			v191_ = math.clamp(v193_, 0, v190_) / v190_
		end
		local v194_, v195_, v196_, v197_, v198_, v199_, v200_ = v188_:getDriveData(dt, vX, vY, vZ, vSpeed, steeringOffset * (0.35 + v191_ * 0.65), toolReverserDirectionNode)
		if v194_ ~= nil and v195_ ~= nil then
			if v197_ ~= nil then
				self.segmentPosition = v197_
				self.segmentLength = v198_
				self.subSegmentPosition = v199_
				self.subSegmentLength = v200_
			end
			local v201_ = (v188_.isTurn or v196_ == -1) and (self.subSegmentLength < 15 and 10 or 15) or 25
			local v202_ = (1 - self.subSegmentPosition) * self.subSegmentLength
			if v202_ < 3 then
				local v203_ = v202_ / 3
				local v204_ = v201_ * math.min(v203_, 1)
				v201_ = math.max(v204_, 4)
			end
			return v194_, v195_, v196_ == 1, v201_, 10
		end
	end
	return 0, 0, true, 0, 0
end

-- Local values: i
function AIFieldCourse:clearAlternativeSegments()
	for v206_ = #self.alternativeTurnSegments, 1, -1 do
		self.alternativeTurnSegments[v206_] = nil
	end
end

-- Local values: _, island, _, segment, r, g, b, a, numPositions, i, x1, z1, x2, z2, y1, y2, _, turnSegment, i, segment
function AIFieldCourse:draw()
	if self.fieldRootBoundary ~= nil then
		self.fieldRootBoundary:draw(0, 0, 1, 0.2)
	end
	if self.protectedBoundary ~= nil then
		self.protectedBoundary:draw(1, 0, 0, 0.2)
	end
	for _, v208_ in ipairs(self.islands) do
		v208_.rootBoundary:draw(1, 0, 1, 0.2)
		if v208_.protectedBoundary ~= nil then
			v208_.protectedBoundary:draw(1, 0, 0, 0.15)
		end
	end
	for _, v209_ in pairs(self.fieldCourse.segments) do
		local v210_ = 0.1
		local v211_ = 0.1
		local v212_ = 0.1
		local v213_ = 0.1
		if self.segmentsToSkip[v209_.segmentId] then
			v211_ = 0
			v212_ = 0
			v213_ = 0.1
			v210_ = 0.1
		elseif v209_.isHeadlandSegment then
			v211_ = 0
			v212_ = 0.1
			v213_ = 0.1
			v210_ = 0
		elseif v209_.isIslandSegment then
			v211_ = 0
			v212_ = 0.1
			v213_ = 0.1
			v210_ = 0.1
		end
		local v214_ = #v209_.positions
		for v215_ = 1, v214_ - 1 do
			local v216_ = v209_.positions[v215_][1]
			local v217_ = v209_.positions[v215_][2]
			local v218_ = v209_.positions[v215_ + 1][1]
			local v219_ = v209_.positions[v215_ + 1][2]
			local v220_ = getTerrainHeightAtWorldPos(g_terrainNode, v216_, 0, v217_)
			local v221_ = getTerrainHeightAtWorldPos(g_terrainNode, v218_, 0, v219_)
			drawDebugLine(v216_, v220_, v217_, v210_, v211_, v212_, v218_, v221_, v219_, v210_, v211_, v212_, false)
			drawDebugPoint(v216_, v220_, v217_, v210_, v211_, v212_, v213_, false)
			if v215_ + 1 == v214_ then
				drawDebugPoint(v218_, v221_, v219_, v210_, v211_, v212_, v213_, false)
			end
		end
	end
	for _, v222_ in ipairs(self.alternativeTurnSegments) do
		v222_:draw(0.1, 0.1, 0.1)
	end
	for v223_, v224_ in ipairs(self.segmentQueue) do
		if v224_:isReady() then
			if v223_ == 1 then
				v224_:draw(0, 1, 0)
			else
				v224_:draw(1, 1, 0)
			end
		end
	end
end

-- Local values: i, segment
function AIFieldCourse:addDebugTexts(vehicle)
	vehicle:addAIDebugText(string.format(" Segment Queue (%d):", #self.segmentQueue))
	local v227_ = #self.segmentQueue
	for v228_ = 1, math.min(v227_, 10) do
		local v229_ = self.segmentQueue[v228_]
		if v229_:isValid() and v229_:isReady() then
			vehicle:addAIDebugText(string.format("%s%d: (%s) L:%.1fm Side:%.2fm", v228_ == 1 and "   A" or "     ", v228_, v229_.isTurn and "turn" or "straight", v229_.length, v229_.sideOffset))
		elseif v229_:isValid() and not v229_:isReady() then
			vehicle:addAIDebugText(string.format("     %d: Getting Ready", v228_))
		else
			vehicle:addAIDebugText(string.format("     %d: Invalid", v228_))
		end
	end
end
function AIFieldCourse.debugPrint(_, p230_, ...)
	if VehicleDebug.state == VehicleDebug.DEBUG_AI then
		print("AIFieldCourse: " .. string.format(p230_, ...))
	end
end
