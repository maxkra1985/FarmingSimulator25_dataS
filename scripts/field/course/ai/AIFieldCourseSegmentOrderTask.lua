-- Local values: AIFieldCourseSegmentOrderTask_mt
AIFieldCourseSegmentOrderTask = {}
local AIFieldCourseSegmentOrderTask_mt = Class(AIFieldCourseSegmentOrderTask)

-- Upvalues: AIFieldCourseSegmentOrderTask_mt
-- Local values: self
function AIFieldCourseSegmentOrderTask.new(aiFieldCourse)
	-- upvalues: (copy) AIFieldCourseSegmentOrderTask_mt
	local v3_ = AIFieldCourseSegmentOrderTask_mt
	local v4_ = setmetatable({}, v3_)
	v4_.aiFieldCourse = aiFieldCourse
	v4_.fieldCourse = aiFieldCourse.fieldCourse
	v4_.segments = aiFieldCourse.fieldCourse.segments
	v4_.fieldCourseSettings = aiFieldCourse.fieldCourseSettings
	v4_.turnGenerator = AIFieldCourseTurnGenerator.new(aiFieldCourse)
	v4_.turnGenerator:setCallback(v4_.onSegmentTurnDataFound, v4_)
	v4_.cornerCutOut = AIFieldCourseCornerCutOut.new(aiFieldCourse)
	v4_.cornerCutOut:setCallback(v4_.onCutOutSegmentFound, v4_)
	v4_.firstSegmentDetection = AIFieldCourseFirstSegmentDetection.new(aiFieldCourse, v4_)
	v4_.firstSegmentDetection:setCallback(v4_.onFoundFirstSegment, v4_)
	v4_.segmentCollisionCheck = AIFieldCourseSegmentCollisionCheck.new(v4_.fieldCourseSettings, v4_.aiFieldCourse.fieldRootBoundary.boundaryLine)
	v4_.extendedHeadlandSegments = {}
	v4_.alternativeTurnSegments = {}
	v4_.startX = nil
	v4_.startZ = nil
	v4_.startDirX = nil
	v4_.startDirZ = nil
	v4_.orderedSegments = {}
	v4_.usedSegments = {}
	v4_.adjustedSegments = {}
	v4_.segmentExcludeListPositive = {}
	v4_.segmentExcludeListNegative = {}
	v4_.unreachableSegments = {}
	v4_.excludedSegments = {}
	v4_.segmentsToSkip = {}
	v4_.allowedProtectedBoundaryCrossings = {}
	v4_.segmentBuffer = {}
	v4_.turnSegmentBuffer = {}
	v4_.curSegmentIndex = 1
	v4_.firstRun = true
	v4_.segment = nil
	v4_.direction = nil
	return v4_
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

-- Local values: i, loadedSegmentData, segment, data
function AIFieldCourseSegmentOrderTask:setOverwrittenSegments(overwrittenSegments)
	self.overwrittenSegments = overwrittenSegments
	self.segmentBuffer = {}
	for v14_, v15_ in ipairs(overwrittenSegments) do
		local v16_ = AIFieldCourseSegment.new()
		v16_:setPositions(v15_.positions)
		v16_.index = v14_
		v16_.isTurn = v15_.isTurn
		v16_.isHeadlandSegment = v15_.isHeadlandSegment
		v16_.isIslandSegment = v15_.isIslandSegment
		if v16_:isValid() then
			local v17_ = {
				["segment"] = v16_,
				["adjustedSegment"] = v16_,
				["direction"] = 1
			}
			if v14_ == 1 then
				self.usedSegments[v17_.segment] = true
				local v18_ = self.orderedSegments
				table.insert(v18_, v17_)
				local v19_ = v17_.segment
				local v20_ = v17_.direction
				self.segment = v19_
				self.direction = v20_
			else
				local v21_ = self.segmentBuffer
				table.insert(v21_, v17_)
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

-- Local values: segmentData, nextSegmentData, nextTurn, _, turnSegmentData, _, segment
function AIFieldCourseSegmentOrderTask:onBufferFillFinished()
	if self.cornerCutOutInProgress then
		return
	end
	if #self.segmentBuffer <= 0 then
		self:onFoundSegment(nil, 1, false, true, nil, true)
		for _, v39_ in pairs(self.segments) do
			if self.usedSegments[v39_] == nil then
				Logging.devInfo("AIFieldCourseSegmentOrderTask: Segment %d could not be reached. (%dm, x %.2f, z %.2f)", v39_.index, v39_.length, v39_.positions[1][1], v39_.positions[1][2])
			end
		end
		return
	end
	local v40_ = self.segmentBuffer[1]
	local v41_ = self.segmentBuffer[2]
	self.usedSegments[v40_.segment] = true
	local v42_ = self.orderedSegments
	table.insert(v42_, v40_)
	local v43_ = nil
	if v41_ ~= nil then
		for _, v44_ in ipairs(self.turnSegmentBuffer) do
			if v44_.from == v40_.segment and v44_.to == v41_.segment then
				v43_ = v44_.turn
				break
			end
		end
	end
	if self.fieldCourseSettings.cornerCutOutSupported and (self.fieldCourseSettings.canTurnBackward and (v41_ ~= nil and self.cornerCutOut:validateSegments(v40_.adjustedSegment, v40_.direction, v41_.adjustedSegment, v41_.direction))) then
		self.aiFieldCourse:debugPrint("Corner cut out calculations started from segment %d to %d", v40_.adjustedSegment.index, v41_.adjustedSegment.index)
		self.cornerCutOutInProgress = true
		self.cornerCutOutAlternativeTurn = v43_
		self.cornerCutOutAlternativeTurnDirection = v40_.direction
		self:onFoundSegment(v40_.adjustedSegment, v40_.direction, false, true, nil, false)
		table.remove(self.segmentBuffer, 1)
	else
		self:onFoundSegment(v40_.adjustedSegment, v40_.direction, false, true, v43_, false)
		if v43_ ~= nil then
			self:onFoundSegment(v43_, v40_.direction, true, true, nil, true)
		end
		table.remove(self.segmentBuffer, 1)
		self.pendingSegmentSearch = false
	end
end

-- Local values: lastSegment, lastBufferElement, segment, _, segment, _, excludedSegment, _, _, segment, unreachableSegment, _, i, segmentData
function AIFieldCourseSegmentOrderTask:fillBuffer()
	local v46_ = self.segmentBuffer[#self.segmentBuffer]
	local v47_
	if v46_ == nil then
		v47_ = nil
	else
		v47_ = v46_.segment
	end
	if v47_ == nil and self.firstSegmentDetection ~= nil then
		self.firstSegmentDetection:detect()
		return false
	end
	for v48_, _ in pairs(self.segmentExcludeListPositive) do
		self.segmentExcludeListPositive[v48_] = nil
	end
	for v49_, _ in pairs(self.segmentExcludeListNegative) do
		self.segmentExcludeListNegative[v49_] = nil
	end
	for v50_, _ in pairs(self.excludedSegments) do
		self.segmentExcludeListPositive[v50_] = true
		self.segmentExcludeListNegative[v50_] = true
	end
	for _, v51_ in ipairs(self.segments) do
		if self.segmentsToSkip[v51_.segmentId] then
			self.segmentExcludeListPositive[v51_] = true
			self.segmentExcludeListNegative[v51_] = true
		end
	end
	for v52_, _ in pairs(self.unreachableSegments) do
		self.segmentExcludeListPositive[v52_] = true
		self.segmentExcludeListNegative[v52_] = true
	end
	for _, v53_ in ipairs(self.segmentBuffer) do
		self.segmentExcludeListPositive[v53_.segment] = true
		self.segmentExcludeListNegative[v53_.segment] = true
	end
	if self:fillNextBufferSlot() then
		return true
	end
	self:onBufferSlotFilled()
	return false
end

function AIFieldCourseSegmentOrderTask:onBufferSlotFilled()
	if self.numBufferFillIterations > 0 then
		self.numBufferFillIterations = self.numBufferFillIterations - 1
		if self.numBufferFillIterations > 0 and not self:fillBuffer() then
			self.numBufferFillIterations = 0
			return
		end
	end
	if self.numBufferFillIterations == 0 then
		self:onBufferFillFinished()
	end
end

-- Local values: lastSegment, lastDirection, lastBufferElement, segment, direction
function AIFieldCourseSegmentOrderTask:fillNextBufferSlot()
	local v56_ = self.segmentBuffer[#self.segmentBuffer]
	local v_u_57_, v_u_58_
	if v56_ == nil then
		v_u_57_ = nil
		v_u_58_ = nil
	else
		v_u_57_ = v56_.segment
		v_u_58_ = v56_.direction
	end
	local v_u_59_, v_u_60_ = self:findNextValidSegment(v_u_57_, v_u_58_)
	if v_u_59_ == nil then
		return false
	end
	self:adjustSegmentLength(v_u_59_, v_u_60_, function(p61_)
		-- upvalues: (copy) self, (copy) v_u_59_, (ref) v_u_57_, (ref) v_u_58_, (copy) v_u_60_
		self.adjustedSegments[v_u_59_] = p61_
		local v62_ = self
		local v63_ = v_u_58_
		self.curTurnSegment1 = v_u_57_
		v62_.curTurnSegmentDirection1 = v63_
		local v64_ = self
		local v65_ = v_u_60_
		self.curTurnSegment2 = v_u_59_
		v64_.curTurnSegmentDirection2 = v65_
		self.turnGenerator:setAllowProtectedBoundary(false)
		if v_u_58_ == v_u_60_ and self.allowedProtectedBoundaryCrossings[self.curTurnSegment1] == self.curTurnSegment2 then
			self.turnGenerator:setAllowProtectedBoundary(true)
		end
		self.turnGenerator:generateSegmentToSegment(self.adjustedSegments[v_u_57_], v_u_58_, p61_, v_u_60_)
	end)
	return true
end

-- Local values: excludeCombination
function AIFieldCourseSegmentOrderTask:onSegmentTurnDataFound(turn)
	if turn == nil then
		local v68_
		if self.curTurnSegment1.isHeadlandSegment and (self.curTurnSegment2.isHeadlandSegment and self.curTurnSegmentDirection1 == self.curTurnSegmentDirection2) then
			self.allowedProtectedBoundaryCrossings[self.curTurnSegment1] = self.curTurnSegment2
			v68_ = false
		else
			v68_ = true
		end
		if v68_ then
			if self.curTurnSegmentDirection2 > 0 then
				self.segmentExcludeListPositive[self.curTurnSegment2] = true
			else
				self.segmentExcludeListNegative[self.curTurnSegment2] = true
			end
		end
		if not self:fillNextBufferSlot() then
			self:onBufferSlotFilled()
		end
	else
		self.adjustedSegments[self.curTurnSegment1].lastEndOffset = turn.turnData.endOffset
		self.adjustedSegments[self.curTurnSegment2].lastStartOffset = turn.turnData.startOffset
		local v69_ = self.segmentBuffer
		local v70_ = {
			["segment"] = self.curTurnSegment2,
			["adjustedSegment"] = self.adjustedSegments[self.curTurnSegment2],
			["direction"] = self.curTurnSegmentDirection2
		}
		table.insert(v69_, v70_)
		local v71_ = self.turnSegmentBuffer
		local v72_ = {
			["from"] = self.curTurnSegment1,
			["to"] = self.curTurnSegment2,
			["turn"] = turn
		}
		table.insert(v71_, v72_)
		self:onBufferSlotFilled()
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

-- Local values: headlandForcedDirection, _, otherSegment
function AIFieldCourseSegmentOrderTask:onFoundFirstSegment(success, segment, direction)
	if success then
		if segment ~= nil and segment.isHeadlandSegment then
			local v83_ = self.fieldCourseSettings.headlandForcedDirection
			local v84_ = -math.sign(v83_)
			if v84_ ~= 0 then
				for _, v85_ in ipairs(self.segments) do
					if v85_.lockedDirection == nil then
						if v85_.isHeadlandSegment and v85_.headlandIndex ~= segment.headlandIndex then
							if segment.isHeadlandSegment or segment.isIslandSegment then
								v85_.lockedDirection = -v84_
							end
						elseif v85_.isHeadlandSegment and v85_.headlandIndex == segment.headlandIndex then
							v85_.lockedDirection = direction
						end
						if v85_.isIslandSegment then
							v85_.lockedDirection = v84_
						end
					end
				end
			end
		end
		self:adjustSegmentLength(segment, direction, function(p86_)
			-- upvalues: (copy) self, (copy) segment, (copy) direction
			self.adjustedSegments[segment] = p86_
			local v87_ = self.segmentBuffer
			local v88_ = {
				["segment"] = segment,
				["adjustedSegment"] = p86_,
				["direction"] = direction
			}
			table.insert(v87_, v88_)
			self.firstSegmentDetection = nil
			self:fillBuffer()
		end)
	else
		self.firstSegmentDetection = nil
		self:fillBuffer()
	end
end

function AIFieldCourseSegmentOrderTask:hasFinished()
	return not self.firstRun and self.segment == nil and true or false
end

-- Local values: segment, direction
function AIFieldCourseSegmentOrderTask:findNextValidSegment(lastSegment, lastDirection)
	local v93_ = nil
	local v94_ = nil
	while v93_ == nil do
		v93_, v94_ = self:findNextSegment(lastSegment, lastDirection)
		if v93_ == nil then
			return v93_, v94_
		end
		if not self:getIsSegmentValid(v93_) then
			self.excludedSegments[v93_] = true
			self.segmentExcludeListPositive[v93_] = true
			self.segmentExcludeListNegative[v93_] = true
			v93_ = nil
		end
	end
	return v93_, v94_
end

-- Local values: halfWidth, i, p1, p2, dirX, dirZ, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ
function AIFieldCourseSegmentOrderTask:getIsSegmentValid(segment)
	local v97_ = self.fieldCourseSettings.implementWidth * 0.5
	for v98_ = 1, #segment.positions - 1 do
		local v99_ = segment.positions[v98_]
		local v100_ = segment.positions[v98_ + 1]
		local v101_, v102_ = MathUtil.vector2Normalize(v100_[1] - v99_[1], v100_[2] - v99_[2])
		local v103_ = v99_[1] - v102_ * v97_
		local v104_ = v99_[2] + v101_ * v97_
		local v105_ = v99_[1] + v102_ * v97_
		local v106_ = v99_[2] - v101_ * v97_
		local v107_ = v100_[1] - v102_ * v97_
		local v108_ = v100_[2] + v101_ * v97_
		if self.aiFieldCourse:getIsSegmentAreaValid(v103_, v104_, v105_, v106_, v107_, v108_) then
			return true
		end
	end
	return false
end

-- Local values: islandsSegment, islandSegmentDirection, nextHeadlandDirection, segment, direction, islandsSegment, islandSegmentDirection, x, z, sideOffset, islandsSegment, islandSegmentDirection, x, z, sideOffset, straightSegmentAny, straightSegmentAnyDirection, straightSegment, straightSegmentDirection, islandsSegment, islandSegmentDirection, nextHeadlandDirection, islandsSegment, islandSegmentDirection, x, z, sideOffset, straightSegment, straightSegmentDirection, segment, direction, _, segment, closestSegment, direction, segment, direction
function AIFieldCourseSegmentOrderTask:findNextSegment(lastSegment, lastDirection)
	if lastSegment == nil then
		return nil
	end
	if self.fieldCourseSettings.headlandsFirst then
		if lastSegment.isIslandSegment then
			local v112_, v113_ = self:findClosestSegment(lastSegment, lastDirection, false, true, nil, nil, lastSegment.headlandIndex, lastSegment.islandIndex)
			if v112_ ~= nil then
				return v112_, v113_
			end
			local v114_ = self.fieldCourseSettings.headlandsFirst and -1 or 1
			local v115_, v116_ = self:findClosestSegment(lastSegment, lastDirection, false, true, nil, nil, lastSegment.headlandIndex + v114_, lastSegment.islandIndex)
			if v115_ ~= nil then
				return v115_, v116_
			end
		end
		local v117_, v118_ = self:findNextHeadlandSegment(lastSegment, lastDirection, false)
		if v117_ ~= nil then
			local v119_, v120_ = self:findClosestSegment(lastSegment, lastDirection, false, true, nil, nil, -1)
			if v119_ ~= nil then
				local v121_, v122_ = AIFieldCourseUtil.getSegmentPosition(true, v119_, v120_)
				if AIFieldCourseUtil.getSegmentSideOffset(lastSegment, v121_, v122_) > self.fieldCourseSettings.implementWidth * 2.01 then
					v119_ = nil
				end
			end
			local v123_, v124_ = self:getCloserSegment(lastSegment, lastDirection, v117_, v118_, v119_, v120_)
			if v123_ ~= nil then
				return v123_, v124_
			end
		end
		local v125_, v126_ = self:findClosestSegment(lastSegment, lastDirection, false, true, nil, nil, -1)
		if v125_ ~= nil then
			local v127_, v128_ = AIFieldCourseUtil.getSegmentPosition(true, v125_, v126_)
			if AIFieldCourseUtil.getSegmentSideOffset(lastSegment, v127_, v128_) > self.fieldCourseSettings.implementWidth * 2.01 then
				v125_ = nil
			end
		end
		local v129_, v130_ = self:findClosestStraightSegment(lastSegment, lastDirection, lastSegment.lineGroupIndex, false)
		local v131_, v132_ = self:getCloserSegment(lastSegment, lastDirection, v125_, v126_, v129_, v130_)
		if v131_ ~= nil and v131_ == v125_ then
			return v131_, v132_
		end
		local v133_, v134_ = self:findClosestStraightSegment(lastSegment, lastDirection, lastSegment.lineGroupIndex, true)
		if v133_ ~= nil then
			return v133_, v134_
		end
	else
		if lastSegment.isIslandSegment then
			local v135_, v136_ = self:findClosestSegment(lastSegment, lastDirection, false, true, nil, nil, lastSegment.headlandIndex, lastSegment.islandIndex)
			if v135_ ~= nil then
				return v135_, v136_
			end
			local v137_ = self.fieldCourseSettings.headlandsFirst and -1 or 1
			local v138_, v139_ = self:findClosestSegment(lastSegment, lastDirection, false, true, nil, nil, lastSegment.headlandIndex + v137_, lastSegment.islandIndex)
			if v138_ ~= nil then
				return v138_, v139_
			end
		end
		local v140_, v141_ = self:findClosestSegment(lastSegment, lastDirection, false, true, nil, nil, -1)
		if v140_ ~= nil then
			local v142_, v143_ = AIFieldCourseUtil.getSegmentPosition(true, v140_, v141_)
			if AIFieldCourseUtil.getSegmentSideOffset(lastSegment, v142_, v143_) > self.fieldCourseSettings.implementWidth * 2.01 then
				v140_ = nil
			end
		end
		local v144_, v145_ = self:findClosestStraightSegment(lastSegment, lastDirection, lastSegment.lineGroupIndex, true)
		local v146_, v147_ = self:getCloserSegment(lastSegment, lastDirection, v140_, v141_, v144_, v145_)
		if v146_ ~= nil then
			return v146_, v147_
		end
	end
	if lastSegment.lineGroupIndex ~= nil then
		for _, v148_ in ipairs(self.segments) do
			if self.usedSegments[v148_] == nil and (self.segmentExcludeListPositive[v148_] == nil and self.segmentExcludeListNegative[v148_] == nil) then
				if lastSegment.lineGroupIndex == v148_.lineGroupIndex then
					return v148_, -lastDirection
				end
				local v149_, v150_ = self:findClosestSegment(lastSegment, lastDirection, false, false)
				if v149_ ~= nil then
					return v149_, v150_
				end
			end
		end
	end
	if not self.fieldCourseSettings.headlandsFirst then
		local v151_, v152_ = self:findNextHeadlandSegment(lastSegment, lastDirection, true)
		if v151_ ~= nil then
			return v151_, v152_
		end
		local v153_, v154_ = self:findNextHeadlandSegment(lastSegment, lastDirection, false)
		if v153_ ~= nil then
			return v153_, v154_
		end
	end
	return nil
end

-- Local values: lastIndex, minSegment, maxSegment, i, segment, nextIndex, _, segment, excludeList, numNextHeadland, i, segment, closestSegment, direction, closestSegment, direction
function AIFieldCourseSegmentOrderTask:findNextHeadlandSegment(lastSegment, lastDirection, useIslands)
	if lastSegment.headlandIndex == nil then
		local v159_, v160_ = self:findClosestSegment(lastSegment, lastDirection, not useIslands, useIslands)
		if v159_ ~= nil then
			return v159_, v160_
		end
	else
		local v161_ = #self.segments
		local v162_ = 1
		local v163_ = nil
		for v164_, v165_ in ipairs(self.segments) do
			if v165_ == lastSegment then
				v163_ = v164_
			end
			if self.usedSegments[v165_] == nil and (self.segmentExcludeListPositive[v165_] == nil and (self.segmentExcludeListNegative[v165_] == nil and (lastSegment.headlandIndex == v165_.headlandIndex and lastSegment.islandIndex == v165_.islandIndex))) then
				v161_ = math.min(v161_, v164_)
				v162_ = math.max(v162_, v164_)
			end
		end
		if v163_ ~= nil then
			local v166_ = v163_ + lastDirection
			for _ = 1, v162_ - v161_ do
				local v167_ = self.segments[v166_]
				if v167_ == nil or (lastSegment.headlandIndex ~= v167_.headlandIndex or lastSegment.islandIndex ~= v167_.islandIndex) then
					if lastDirection > 0 then
						v166_ = v161_
					else
						v166_ = v162_
					end
				else
					local v168_ = lastDirection > 0 and self.segmentExcludeListPositive or self.segmentExcludeListNegative
					if self.usedSegments[v167_] == nil and (v168_[v167_] == nil and v167_.lockedDirection ~= -lastDirection) then
						return v167_, lastDirection
					end
					v166_ = v166_ + lastDirection
				end
			end
			local v169_ = 0
			for _, v170_ in ipairs(self.segments) do
				local _ = v170_ == lastSegment
				if self.usedSegments[v170_] == nil and (self.segmentExcludeListPositive[v170_] == nil and (self.segmentExcludeListNegative[v170_] == nil and (lastSegment.headlandIndex + 1 == v170_.headlandIndex and lastSegment.islandIndex == v170_.islandIndex))) then
					v169_ = v169_ + 1
				end
			end
		end
		local v171_, v172_ = self:findClosestSegment(lastSegment, lastDirection, not useIslands, useIslands)
		if v171_ ~= nil then
			return v171_, v172_
		end
	end
	return nil
end

-- Local values: searchDirection, negSegments, posSegments, foundSegment, _, segment, sx1, sz1, ex1, ez1, sx2, sz2, ex2, ez2, x1, z1, minDistance, minDistanceSegment, minDistanceSegmentDirection, allowed, _, segment, distance, distance
function AIFieldCourseSegmentOrderTask:findClosestStraightSegment(lastSegment, direction, groupIndex, workLessSegmentSideFirst)
	local v178_ = 0
	if workLessSegmentSideFirst and groupIndex ~= nil then
		local v179_ = false
		local v180_ = 0
		local v181_ = 0
		for _, v182_ in pairs(self.segments) do
			if v182_ == lastSegment then
				v179_ = true
			elseif self.usedSegments[v182_] == nil and (self.segmentExcludeListPositive[v182_] == nil and (self.segmentExcludeListNegative[v182_] == nil and v182_.lineGroupIndex == lastSegment.lineGroupIndex)) then
				local v183_ = lastSegment.positions[1][1]
				local v184_ = lastSegment.positions[1][2]
				local v185_ = lastSegment.positions[2][1]
				local v186_ = lastSegment.positions[2][2]
				local v187_ = v182_.positions[1][1]
				local v188_ = v182_.positions[1][2]
				local v189_ = v182_.positions[2][1]
				local v190_ = v182_.positions[2][2]
				if FieldCourseUtil.getAreParallelSegmentsNextToEachOther(v183_, v184_, v185_, v186_, v187_, v188_, v189_, v190_) then
					if v179_ then
						v180_ = v180_ + 1
					else
						v181_ = v181_ + 1
					end
				end
			end
		end
		if v181_ > 0 and v181_ < v180_ then
			v178_ = -1
		elseif v180_ > 0 and v180_ < v181_ then
			v178_ = 1
		end
	end
	local v191_, v192_ = AIFieldCourseUtil.getSegmentPosition(false, lastSegment, direction)
	local v193_ = v178_ <= 0
	local v194_ = math.huge
	local v195_ = nil
	local v196_ = 1
	for _, v197_ in ipairs(self.segments) do
		v193_ = v178_ == 0 or lastSegment ~= v197_ or not v193_
		if not v193_ then
			break
		end
		if v193_ and self.usedSegments[v197_] == nil and (groupIndex == nil and v197_.lineGroupIndex ~= nil or groupIndex ~= nil and v197_.lineGroupIndex == groupIndex) then
			local v198_
			if self.segmentExcludeListPositive[v197_] == nil and v197_.lockedDirection ~= -1 then
				v198_ = self:getCostDistanceToSegment(v197_, true, v191_, v192_)
				if v198_ < v194_ and v198_ > 0 then
					v195_ = v197_
					v196_ = 1
				else
					v198_ = v194_
				end
			else
				v198_ = v194_
			end
			if self.segmentExcludeListNegative[v197_] == nil and v197_.lockedDirection ~= 1 then
				v194_ = self:getCostDistanceToSegment(v197_, false, v191_, v192_)
				if v194_ < v198_ and v194_ > 0 then
					v195_ = v197_
					v196_ = -1
				else
					v194_ = v198_
				end
			else
				v194_ = v198_
			end
		end
	end
	return v195_, v196_
end

-- Local values: x2, z2, distance, _, segment, intersect
function AIFieldCourseSegmentOrderTask:getCostDistanceToSegment(targetSegment, startPosition, x, z)
	local v204_, v205_ = AIFieldCourseUtil.getSegmentPosition(startPosition, targetSegment, 1)
	local v206_ = MathUtil.vector2Length(v204_ - x, v205_ - z)
	for _, v207_ in ipairs(self.segments) do
		if not v207_.isHeadlandSegment and (not v207_.isIslandSegment and (self.usedSegments[v207_] == nil and (self.segmentExcludeListPositive[v207_] == nil and (self.segmentExcludeListNegative[v207_] == nil and FieldCourseUtil.getSegmentBoundaryIntersection(x, z, v204_, v205_, v207_.positions))))) then
			v206_ = v206_ * 3
		end
	end
	return v206_
end

-- Local values: x1, z1
function AIFieldCourseSegmentOrderTask:findClosestSegment(lastSegment, direction, headlands, islands, groupIndex, maxSideOffset, headlandIndex, islandIndex, excludeBoundaryChecks)
	local v218_, v219_ = AIFieldCourseUtil.getSegmentPosition(false, lastSegment, direction)
	return self:getClosestSegmentToPosition(v218_, v219_, headlands, islands, groupIndex, maxSideOffset, headlandIndex, islandIndex, lastSegment, excludeBoundaryChecks, nil, nil)
end

-- Local values: minDistance, minDistanceRaw, minDistanceSegment, minDistanceSegmentDirection, _, segment, segmentIsAllowed, island, curHeadlandIndex, _, otherSegment, validSegmentsLeft, foundSegments, _, otherSegment, x2, z2, x3, z3, dirX, dirZ, x4, z4, distance, x2, z2, distanceRaw, correctedDistance, distance, px2, pz2, x3, z3, distanceRaw, correctedDistance, distance, px3, pz3
function AIFieldCourseSegmentOrderTask:getClosestSegmentToPosition(x, z, headlands, islands, groupIndex, maxSideOffset, headlandIndex, islandIndex, excludeSegment, excludeBoundaryChecks, prevDirX, prevDirZ)
	local v233_ = math.huge
	local v234_ = nil
	local v235_ = 1
	for _, v236_ in ipairs(self.segments) do
		if self.usedSegments[v236_] == nil and v236_ ~= excludeSegment then
			local v237_
			if headlands == nil or headlands == v236_.isHeadlandSegment then
				v237_ = islands == nil and true or islands == v236_.isIslandSegment
			else
				v237_ = false
			end
			if headlandIndex == -1 then
				if v236_.islandIndex ~= nil then
					local v238_ = self.aiFieldCourse.islands[v236_.islandIndex]
					if v238_ ~= nil and v238_.hasCutSegments then
						headlandIndex = nil
					end
				end
				if headlandIndex ~= nil then
					if v236_.headlandIndex == nil then
						v237_ = false
					else
						local v239_ = 1
						if self.fieldCourseSettings.headlandsFirst and v236_.islandIndex ~= nil then
							for _, v240_ in ipairs(self.segments) do
								if v240_.islandIndex == v236_.islandIndex then
									local v241_ = v240_.headlandIndex
									v239_ = math.max(v239_, v241_)
								end
							end
						end
						while true do
							local v242_ = 0
							local v243_ = false
							for _, v244_ in ipairs(self.segments) do
								if v244_.islandIndex == v236_.islandIndex and v244_.headlandIndex == v239_ then
									v242_ = v242_ + 1
									if self.usedSegments[v244_] == nil then
										v243_ = true
										break
									end
								end
							end
							if v243_ then
								break
							end
							if self.fieldCourseSettings.headlandsFirst and v236_.islandIndex ~= nil then
								v239_ = v239_ - 1
							else
								v239_ = v239_ + 1
							end
							if v242_ == 0 then
								break
							end
						end
						if v237_ then
							v237_ = v236_.headlandIndex == v239_
						end
					end
				end
			elseif v237_ then
				v237_ = headlandIndex == nil and true or v236_.headlandIndex == headlandIndex
			end
			if v237_ then
				v237_ = islandIndex == nil and true or v236_.islandIndex == islandIndex
			end
			if groupIndex ~= nil then
				if v237_ then
					v237_ = v236_.lineGroupIndex == groupIndex
				end
				if maxSideOffset ~= nil then
					local v245_, v246_ = AIFieldCourseUtil.getSegmentPosition(true, v236_, 1)
					local v247_, v248_ = AIFieldCourseUtil.getSegmentPosition(false, v236_, 1)
					local v249_, v250_ = MathUtil.vector2Normalize(v247_ - v245_, v248_ - v246_)
					local v251_, v252_ = MathUtil.projectOnLine(x, z, v245_, v246_, v249_, v250_)
					local v253_ = MathUtil.vector2Length(v251_ - x, v252_ - z)
					if v237_ then
						v237_ = v253_ < maxSideOffset
					end
				end
			end
			if v237_ then
				local v254_
				if self.segmentExcludeListPositive[v236_] == nil and v236_.lockedDirection ~= -1 then
					local v255_, v256_ = AIFieldCourseUtil.getSegmentPosition(true, v236_, 1)
					local v257_ = MathUtil.vector2Length(v255_ - x, v256_ - z)
					if v257_ <= v233_ + 0.1 then
						local v258_
						if excludeBoundaryChecks == true then
							v258_ = v257_
						else
							v258_ = self:getBoundaryCorrectedDistance(x, z, v255_, v256_)
						end
						if maxSideOffset == nil or (v258_ == nil or v258_ == nil) then
							v254_ = (v258_ or v257_) * self:getSegmentToSegmentFactor(x, z, v236_)
							if prevDirX ~= nil and prevDirZ ~= nil then
								local v259_, v260_ = AIFieldCourseUtil.getSegmentPosition(true, v236_, 1, 1)
								v254_ = v254_ * self:getSegmentDirectionFactor(v255_, v256_, v259_, v260_, prevDirX, prevDirZ)
							end
							if v254_ < v233_ then
								v234_ = v236_
								v235_ = 1
							else
								v254_ = v233_
							end
						else
							v254_ = v233_
						end
					else
						v254_ = v233_
					end
				else
					v254_ = v233_
				end
				if self.segmentExcludeListNegative[v236_] == nil and v236_.lockedDirection ~= 1 then
					local v261_, v262_ = AIFieldCourseUtil.getSegmentPosition(false, v236_, 1)
					local v263_ = MathUtil.vector2Length(v261_ - x, v262_ - z)
					if v263_ <= v254_ + 0.1 then
						local v264_
						if excludeBoundaryChecks == true then
							v264_ = nil
						else
							v264_ = self:getBoundaryCorrectedDistance(x, z, v261_, v262_)
						end
						if maxSideOffset == nil or (v264_ == nil or v264_ == nil) then
							v233_ = (v264_ or v263_) * self:getSegmentToSegmentFactor(x, z, v236_)
							if prevDirX ~= nil and prevDirZ ~= nil then
								local v265_, v266_ = AIFieldCourseUtil.getSegmentPosition(false, v236_, 1, 1)
								v233_ = v233_ * self:getSegmentDirectionFactor(v261_, v262_, v265_, v266_, prevDirX, prevDirZ)
							end
							if v233_ < v254_ then
								v234_ = v236_
								v235_ = -1
							else
								v233_ = v254_
							end
						else
							v233_ = v254_
						end
					else
						v233_ = v254_
					end
				else
					v233_ = v254_
				end
			end
		end
	end
	return v234_, v235_
end

-- Local values: x2, z2, x3, z3, dirX, dirZ, length, x4, z4, distance, factor
function AIFieldCourseSegmentOrderTask:getSegmentToSegmentFactor(x, z, segment)
	local v271_, v272_ = AIFieldCourseUtil.getSegmentPosition(true, segment, 1)
	local v273_, v274_ = AIFieldCourseUtil.getSegmentPosition(false, segment, 1)
	local v275_ = v273_ - v271_
	local v276_ = v274_ - v272_
	local v277_ = MathUtil.vector2Length(v275_, v276_)
	if v277_ <= 0 then
		return 1
	end
	local v278_ = v275_ / v277_
	local v279_ = v276_ / v277_
	local v280_, v281_ = MathUtil.projectOnLine(x, z, v271_, v272_, v278_, v279_)
	return (MathUtil.vector2Length(v280_ - x, v281_ - z) / self.fieldCourseSettings.implementWidth - 1) * 0.25 + 1
end

-- Local values: dirX, dirZ, yRot1, yRot2, rotOffset
function AIFieldCourseSegmentOrderTask:getSegmentDirectionFactor(x1, z1, x2, z2, prevDirX, prevDirZ)
	local v288_, v289_ = MathUtil.vector2Normalize(x2 - x1, z2 - z1)
	local v290_ = MathUtil.getYRotationFromDirection(v288_, v289_)
	local v291_ = MathUtil.getYRotationFromDirection(prevDirX, prevDirZ) - v290_
	if v291_ > 3.141592653589793 then
		v291_ = v291_ - 6.283185307179586
	end
	if v291_ < -3.141592653589793 then
		v291_ = v291_ + 6.283185307179586
	end
	return 1 + math.abs(v291_) * 0.5
end

-- Local values: x1, z1, x2, z2, x3, z3, distance1, distance2, _, segment, intersect, _, _
function AIFieldCourseSegmentOrderTask:getCloserSegment(lastSegment, lastDirection, segment1, direction1, segment2, direction2)
	if segment1 == nil or segment2 == nil then
		if segment1 == nil then
			if segment2 == nil then
				return nil, nil
			else
				return segment2, direction2
			end
		else
			return segment1, direction1
		end
	else
		local v299_, v300_ = AIFieldCourseUtil.getSegmentPosition(false, lastSegment, lastDirection)
		local v301_, v302_ = AIFieldCourseUtil.getSegmentPosition(true, segment1, direction1)
		local v303_, v304_ = AIFieldCourseUtil.getSegmentPosition(true, segment2, direction2)
		local v305_ = MathUtil.vector2Length(v301_ - v299_, v302_ - v300_)
		local v306_ = MathUtil.vector2Length(v303_ - v299_, v304_ - v300_)
		for _, v307_ in ipairs(self.segments) do
			local v308_, _, _ = FieldCourseUtil.getSegmentBoundaryIntersection(v299_, v300_, v301_, v302_, v307_.positions)
			if v308_ then
				v305_ = v305_ * 1.05
			end
			local v309_, _, _ = FieldCourseUtil.getSegmentBoundaryIntersection(v299_, v300_, v303_, v304_, v307_.positions)
			if v309_ then
				v306_ = v306_ * 1.05
			end
		end
		if v305_ < v306_ then
			return segment1, direction1
		else
			return segment2, direction2
		end
	end
end

-- Local values: boundaryLine, distance, _, island, distance
function AIFieldCourseSegmentOrderTask:getBoundaryCorrectedDistance(x1, z1, x2, z2)
	local v315_ = self.aiFieldCourse.fieldRootBoundary.boundaryLine
	if FieldCourseUtil.getIsPointInsideBoundary(x1, z1, v315_) and FieldCourseUtil.getIsPointInsideBoundary(x2, z2, v315_) then
		local v316_ = self:getBoundaryCorrectedDistanceByBoundary(v315_, x1, z1, x2, z2)
		if v316_ ~= nil then
			return v316_
		end
	end
	for _, v317_ in ipairs(self.aiFieldCourse.islands) do
		if not (FieldCourseUtil.getIsPointInsideBoundary(x1, z1, v317_.protectedBoundary.boundaryLine) or FieldCourseUtil.getIsPointInsideBoundary(x2, z2, v317_.protectedBoundary.boundaryLine)) then
			local v318_ = self:getBoundaryCorrectedDistanceByBoundary(v317_.protectedBoundary.boundaryLine, x1, z1, x2, z2)
			if v318_ ~= nil then
				return v318_
			end
		end
	end
	return nil
end

-- Local values: i, x3, z3, x4, z4, intersect, _, _, _, distance, baseDistance
function AIFieldCourseSegmentOrderTask:getBoundaryCorrectedDistanceByBoundary(boundaryLine, x1, z1, x2, z2)
	for v325_ = 1, #boundaryLine - 1 do
		local v326_ = boundaryLine[v325_][1]
		local v327_ = boundaryLine[v325_][2]
		local v328_ = boundaryLine[v325_ + 1][1]
		local v329_ = boundaryLine[v325_ + 1][2]
		local v330_, _, _ = MathUtil.getLineSegmentsIntersection(x1, z1, x2, z2, v326_, v327_, v328_, v329_)
		if v330_ then
			local _, v331_ = self:getNextDirectConnectBoundaryPosition(boundaryLine, v325_, x2, z2)
			if v331_ ~= nil and v331_ > 0 then
				return v331_ + MathUtil.vector2Length(v326_ - z1, v327_ - z1)
			end
		end
	end
	return nil
end

-- Local values: distancePos, distanceNeg, i, pos1, x1, z1, intersect, _, _, pos2, x2, z2
function AIFieldCourseSegmentOrderTask:getNextDirectConnectBoundaryPosition(boundaryLine, index, x, z)
	local v336_ = 0
	local v337_ = 0
	for v338_ = 1, #boundaryLine do
		if boundaryLine[index + v338_] == nil then
			break
		end
		local v339_ = boundaryLine[index + v338_][1]
		local v340_ = boundaryLine[index + v338_][2]
		local v341_, _, _ = FieldCourseUtil.getSegmentBoundaryIntersection(v339_, v340_, x, z, boundaryLine)
		if not v341_ then
			local v342_ = v336_ + MathUtil.vector2Length(v339_ - x, v340_ - z)
			return index + v338_, v342_
		end
		v336_ = v336_ + MathUtil.vector2Length(boundaryLine[index + v338_][1] - boundaryLine[index + v338_ - 1][1], boundaryLine[index + v338_][2] - boundaryLine[index + v338_ - 1][2])
		if boundaryLine[index - v338_] == nil then
			break
		end
		local v343_ = boundaryLine[index - v338_][1]
		local v344_ = boundaryLine[index - v338_][2]
		local v345_, _, _ = FieldCourseUtil.getSegmentBoundaryIntersection(v343_, v344_, x, z, boundaryLine)
		if not v345_ then
			local v346_ = v337_ + MathUtil.vector2Length(v343_ - x, v344_ - z)
			return index - v338_, v346_
		end
		v337_ = v337_ + MathUtil.vector2Length(boundaryLine[index - v338_][1] - boundaryLine[index - v338_ + 1][1], boundaryLine[index - v338_][2] - boundaryLine[index - v338_ + 1][2])
	end
	return nil
end

-- Local values: boundaryLine, headlandBoundary, island, headlandBoundary, isFirstSegment, otherSegment, _, toolDirection, i, p1, p2, sideOffset, preferedSide
function AIFieldCourseSegmentOrderTask:adjustSegmentLength(segment, direction, callback)
	if (segment.isHeadlandSegment or segment.isIslandSegment) and self.extendedHeadlandSegments[segment] == nil then
		local v351_ = self.aiFieldCourse.fieldRootBoundary.boundaryLine
		if segment.islandIndex == nil then
			if segment.headlandIndex > 1 then
				local v352_ = self.aiFieldCourse.headlandBoundaries[segment.headlandIndex - 1]
				if v352_ ~= nil then
					v351_ = v352_.boundaryLine
				end
			end
		else
			local v353_ = self.aiFieldCourse.islands[segment.islandIndex]
			if v353_ ~= nil then
				if segment.headlandIndex > 1 then
					local v354_ = v353_.boundaries[segment.headlandIndex - 1]
					if v354_ ~= nil then
						v351_ = v354_.boundaryLine
					end
				else
					v351_ = v353_.rootBoundary.boundaryLine
				end
			end
		end
		local v355_ = true
		for v356_, _ in pairs(self.extendedHeadlandSegments) do
			if segment.islandIndex == v356_.islandIndex and segment.headlandIndex == v356_.headlandIndex then
				v355_ = false
				break
			end
		end
		self.extendedHeadlandSegments[segment] = true
		local v357_ = self.fieldCourseSettings.toolFrontOffset
		local v358_ = math.sign(v357_)
		AIFieldCourseUtil.extendHeadlandSegment(self.segments, segment.index, direction, v358_, self.fieldCourseSettings.implementWidth, v351_)
		if v355_ then
			AIFieldCourseUtil.extendHeadlandSegment(self.segments, segment.index, -direction, 1, self.fieldCourseSettings.implementWidth, v351_, true, direction)
		end
	end
	local v359_ = table.clone(segment, 5)
	if dp ~= nil then
		for v360_ = 1, #v359_.positions - 1 do
			local v361_ = v359_.positions[v360_]
			local v362_ = v359_.positions[v360_ + 1]
			if MathUtil.vector2Length(v362_[1] - v361_[1], v362_[2] - v361_[2]) == 0 then
				dp(v361_[1], v361_[2], "Zero Length Segment")
			end
		end
	end
	if self.fieldCourseSettings.sideOffset ~= 0 then
		if v359_.sideOffsetToApply == nil then
			local v363_ = self.fieldCourseSettings.sideOffset
			local v364_
			if self.fieldCourseSettings.variableSideOffset == true then
				local v365_ = self:getPreferedOffsetSide(v359_, direction)
				if v365_ == nil then
					v364_ = v363_ / direction
				else
					v364_ = math.abs(v363_) * v365_
				end
			else
				v364_ = v363_ * direction
			end
			FieldCourseBoundary.segmentApplySideOffset(v359_, v364_)
			v359_.sideOffset = v364_ * direction
		else
			FieldCourseBoundary.segmentApplySideOffset(v359_, v359_.sideOffsetToApply)
			v359_.sideOffsetToApply = nil
		end
	end
	if self.fieldCourseSettings.toolFullOverlap then
		FieldCourseUtil.extendSegment(v359_.positions, direction, -self.fieldCourseSettings.toolBackOffset)
		FieldCourseUtil.extendSegment(v359_.positions, -direction, self.fieldCourseSettings.toolFrontOffset)
	elseif self.fieldCourseSettings.toolFullOverlapInside and not (v359_.isHeadlandSegment or v359_.isIslandSegment) then
		FieldCourseUtil.extendSegment(v359_.positions, direction, -self.fieldCourseSettings.toolBackOffset)
		FieldCourseUtil.extendSegment(v359_.positions, -direction, self.fieldCourseSettings.toolFrontOffset)
	else
		FieldCourseUtil.extendSegment(v359_.positions, direction, -self.fieldCourseSettings.toolFrontOffset)
		if self.fieldCourseSettings.canTurnBackward or self.fieldCourseSettings.allowStraightReversing then
			FieldCourseUtil.extendSegment(v359_.positions, -direction, self.fieldCourseSettings.toolBackOffset)
		end
	end
	self.segmentCollisionCheck:checkSegment(v359_, direction, function(p366_)
		-- upvalues: (copy) callback
		callback(p366_)
	end)
end

-- Local values: prevSegment, nextSegment, originalSegment, adjustedSegment, offset
function AIFieldCourseSegmentOrderTask:getNeighbouringUsedSegment(segment)
	if segment.lineGroupIndex == nil then
		if segment.headlandIndex ~= nil then
			for v369_, v370_ in pairs(self.adjustedSegments) do
				if v370_.islandIndex == segment.islandIndex and (v370_.headlandIndex == segment.headlandIndex + 1 or v370_.headlandIndex == segment.headlandIndex - 1) and AIFieldCourseUtil.getSegmentToSegmentDistance(segment, v369_) < self.fieldCourseSettings.implementWidth + 0.01 then
					return v370_
				end
			end
		end
	else
		local v371_ = self.segments[segment.index - 1]
		if v371_ ~= nil and self.adjustedSegments[v371_] ~= nil then
			return self.adjustedSegments[v371_]
		end
		local v372_ = self.segments[segment.index + 1]
		if v372_ ~= nil and self.adjustedSegments[v372_] ~= nil then
			return self.adjustedSegments[v372_]
		end
	end
end

-- Local values: segmentBoundary, island, x1, z1, x2, z2, numPositions, dirX, dirZ, cx, cz, maxDistance, intersect1, ix1, iz1, intersect2, ix2, iz2, distance1, distance2, x1, z1, x2, z2, numPositions, dirX, dirZ, cx, cz, neighbouringSegment, maxDistance, intersect1, ix1, iz1, intersect2, ix2, iz2, distance1, distance2, boundaryLine, intersect1, ix1, iz1, intersect2, ix2, iz2, distance1, distance2
function AIFieldCourseSegmentOrderTask:getPreferedOffsetSide(segment, direction)
	if segment.headlandIndex == nil then
		local v376_, v377_, v378_, v379_
		if direction < 0 then
			local v380_ = #segment.positions
			v376_ = segment.positions[v380_][1]
			v377_ = segment.positions[v380_][2]
			v378_ = segment.positions[v380_ - 1][1]
			v379_ = segment.positions[v380_ - 1][2]
		else
			v376_ = segment.positions[1][1]
			v377_ = segment.positions[1][2]
			v378_ = segment.positions[2][1]
			v379_ = segment.positions[2][2]
		end
		local v381_, v382_ = MathUtil.vector2Normalize(v378_ - v376_, v379_ - v377_)
		local v383_ = (v376_ + v378_) * 0.5
		local v384_ = (v377_ + v379_) * 0.5
		local v385_ = self:getNeighbouringUsedSegment(segment)
		if v385_ == nil then
			local v386_ = self.aiFieldCourse.fieldRootBoundary.boundaryLine
			local v387_, v388_, v389_ = FieldCourseUtil.getSegmentClosestBoundaryIntersection(v383_, v384_, v383_ + v382_ * 100, v384_ - v381_ * 100, v386_)
			local v390_, v391_, v392_ = FieldCourseUtil.getSegmentClosestBoundaryIntersection(v383_, v384_, v383_ - v382_ * 100, v384_ + v381_ * 100, v386_)
			if v387_ and v390_ then
				if MathUtil.vector2Length(v383_ - v388_, v384_ - v389_) > MathUtil.vector2Length(v383_ - v391_, v384_ - v392_) then
					direction = -direction or direction
				end
				return direction
			end
			if v387_ then
				return direction
			end
			if v390_ then
				return -direction
			end
		else
			local v393_ = self.fieldCourseSettings.implementWidth * self.fieldCourseSettings.numHeadlands
			local v394_, v395_, v396_ = FieldCourseUtil.getSegmentBoundaryIntersection(v383_, v384_, v383_ + v382_ * v393_, v384_ - v381_ * v393_, v385_.positions)
			local v397_, v398_, v399_ = FieldCourseUtil.getSegmentBoundaryIntersection(v383_, v384_, v383_ + v382_ * v393_, v384_ - v381_ * v393_, v385_.positions)
			if v394_ and v397_ then
				if MathUtil.vector2Length(v383_ - v395_, v384_ - v396_) > MathUtil.vector2Length(v383_ - v398_, v384_ - v399_) then
					direction = -direction or direction
				end
				return direction
			end
			if v394_ then
				return direction
			end
			if v397_ then
				return -direction
			end
		end
	else
		local v400_ = self.aiFieldCourse.fieldRootBoundary.boundaryLine
		if segment.islandIndex ~= nil then
			local v401_ = self.aiFieldCourse.islands[segment.islandIndex]
			if v401_ ~= nil then
				v400_ = v401_.rootBoundary.boundaryLine
			end
		end
		local v402_, v403_, v404_, v405_
		if direction < 0 then
			local v406_ = #segment.positions
			v402_ = segment.positions[v406_][1]
			v403_ = segment.positions[v406_][2]
			v404_ = segment.positions[v406_ - 1][1]
			v405_ = segment.positions[v406_ - 1][2]
		else
			v402_ = segment.positions[1][1]
			v403_ = segment.positions[1][2]
			v404_ = segment.positions[2][1]
			v405_ = segment.positions[2][2]
		end
		local v407_, v408_ = MathUtil.vector2Normalize(v404_ - v402_, v405_ - v403_)
		local v409_ = (v402_ + v404_) * 0.5
		local v410_ = (v403_ + v405_) * 0.5
		local v411_ = self.fieldCourseSettings.implementWidth * self.fieldCourseSettings.numHeadlands
		local v412_, v413_, v414_ = FieldCourseUtil.getSegmentClosestBoundaryIntersection(v409_, v410_, v409_ + v408_ * v411_, v410_ - v407_ * v411_, v400_)
		local v415_, v416_, v417_ = FieldCourseUtil.getSegmentClosestBoundaryIntersection(v409_, v410_, v409_ - v408_ * v411_, v410_ + v407_ * v411_, v400_)
		if v412_ and v415_ then
			return MathUtil.vector2Length(v409_ - v413_, v410_ - v414_) > MathUtil.vector2Length(v409_ - v416_, v410_ - v417_) and direction and direction or -direction
		end
		if v412_ then
			return -direction
		end
		if v415_ then
			return direction
		end
	end
	return nil
end
