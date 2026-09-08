-- Local values: AIFieldCourseTurnGenerator_mt, tempData
AIFieldCourseTurnGenerator = {}
local AIFieldCourseTurnGenerator_mt = Class(AIFieldCourseTurnGenerator)

-- Upvalues: AIFieldCourseTurnGenerator_mt
-- Local values: self
function AIFieldCourseTurnGenerator.new(aiFieldCourse, segments)
	-- upvalues: (copy) AIFieldCourseTurnGenerator_mt
	local v3_ = AIFieldCourseTurnGenerator_mt
	local v4_ = setmetatable({}, v3_)
	v4_.aiFieldCourse = aiFieldCourse
	v4_.fieldCourseSettings = aiFieldCourse.fieldCourseSettings
	v4_.alternativeTurnSegments = aiFieldCourse.alternativeTurnSegments
	v4_.state = AIFieldCourseTurnGeneratorState.INITIAL
	v4_.offsetTurns = {}
	v4_.ignoreBoundaryIntersections = false
	v4_.allowProtectedBoundary = false
	v4_.preferOneDrivingDirection = false
	v4_.forcedDrivingDirection = 0
	v4_.maxOffset = nil
	v4_.overwrittenTurnRadius = nil
	return v4_
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

-- Local values: sx, sz, sDirX, sDirZ, ex, ez, eDirX, eDirZ, turnData, startOffset, endOffset
function AIFieldCourseTurnGenerator:generateSegmentToSegment(segment1, direction1, segment2, direction2)
	self.segment1 = segment1
	self.direction1 = direction1
	self.segment2 = segment2
	self.direction2 = direction2
	local v25_, v26_, v27_, v28_ = AIFieldCourseUtil.getSegmentPositionAndDirection(false, segment1, direction1)
	local v29_, v30_, v31_, v32_ = AIFieldCourseUtil.getSegmentPositionAndDirection(true, segment2, direction2)
	local v33_ = AIFieldCourseTurnData(v25_, v26_, v27_, v28_, v29_, v30_, v31_, v32_, segment1, direction1, segment2, direction2, self.aiFieldCourse, self.overwrittenTurnRadius)
	local v34_
	if AIFieldCourseTurnGenerator.isPositionOutsideField(v25_, v26_, v33_, true) then
		v34_ = AIFieldCourseTurnGenerator.getSegmentMinOffset(true, segment1, direction1, v33_, self.fieldCourseSettings.minTurnRadius * 2)
		if v34_ ~= nil then
			v33_ = v33_:offset(v34_, nil)
		end
	else
		v34_ = nil
	end
	if AIFieldCourseTurnGenerator.isPositionOutsideField(v29_, v30_, v33_, true) then
		local v35_ = AIFieldCourseTurnGenerator.getSegmentMinOffset
		local v36_ = self.fieldCourseSettings.minTurnRadius * 2
		local v37_ = segment2.length
		local v38_ = v35_(false, segment2, direction2, v33_, (math.min(v36_, v37_)))
		if v38_ ~= nil then
			v33_ = v33_:offset(v34_, v38_)
		end
	end
	self.state = AIFieldCourseTurnGeneratorState.DEFAULT
	self.originalTurnData = v33_
	g_fieldCourseManager:addUpdateable(self)
end

-- Local values: ex, ez, eDirX, eDirZ, turnData
function AIFieldCourseTurnGenerator:generatePositionToSegment(sx, sz, sDirX, sDirZ, segment2, direction2)
	self.segment2 = segment2
	self.direction2 = direction2
	local v46_, v47_, v48_, v49_ = AIFieldCourseUtil.getSegmentPositionAndDirection(true, segment2, direction2)
	local v50_ = AIFieldCourseTurnData(sx, sz, sDirX, sDirZ, v46_, v47_, v48_, v49_, nil, nil, segment2, direction2, self.aiFieldCourse, self.overwrittenTurnRadius)
	self.state = AIFieldCourseTurnGeneratorState.DEFAULT
	self.originalTurnData = v50_
	g_fieldCourseManager:addUpdateable(self)
end

-- Local values: turnData
function AIFieldCourseTurnGenerator:generatePositionToPosition(sx, sz, sDirX, sDirZ, ex, ez, eDirX, eDirZ)
	local v60_ = AIFieldCourseTurnData(sx, sz, sDirX, sDirZ, ex, ez, eDirX, eDirZ, nil, nil, nil, nil, self.aiFieldCourse, self.overwrittenTurnRadius)
	self.state = AIFieldCourseTurnGeneratorState.DEFAULT
	self.originalTurnData = v60_
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

-- Local values: startTime, minCostTurn, _, i, minCostTurn, _, directLength, minCostOffsetTurn, minCostOffsetTurn, i
function AIFieldCourseTurnGenerator:update(dt)
	local v64_ = getTimeSec()
	while getTimeSec() - v64_ < 0.0005 do
		if self.state == AIFieldCourseTurnGeneratorState.DEFAULT then
			local v65_, _ = self:getBestTurnByTurnData(self.originalTurnData)
			if v65_ ~= nil then
				self:onFinished(v65_)
				return
			end
			local v66_ = self.originalTurnData.startOffset or 3
			local v67_ = self.originalTurnData.endOffset or 3
			self.defaultStartOffset = v66_
			self.defaultEndOffset = v67_
			for v68_ = #self.offsetTurns, 1, -1 do
				self.offsetTurns[v68_] = nil
			end
			local v69_ = self.fieldCourseSettings.minTurnRadius * 6
			local v70_ = self.fieldCourseSettings.minTurnRadius * 6
			self.startOffsetLimit = v69_
			self.endOffsetLimit = v70_
			if not (self.fieldCourseSettings.canTurnBackward or self.fieldCourseSettings.allowStraightReversing) then
				self.startOffsetLimit = self.segment1 ~= nil and self.segment1.length - (self.segment1.lastStartOffset or 0) or self.startOffsetLimit
				self.endOffsetLimit = self.segment2 ~= nil and self.segment2.length - (self.segment2.lastEndOffset or 0) or self.endOffsetLimit
			end
			local v71_ = self.defaultStartOffset
			local v72_ = self.defaultEndOffset
			self.startOffset = v71_
			self.endOffset = v72_
			self.state = AIFieldCourseTurnGeneratorState.EXTEND_SEGMENT
		elseif self.state == AIFieldCourseTurnGeneratorState.EXTEND_SEGMENT or self.state == AIFieldCourseTurnGeneratorState.SHRINK_SEGMENT then
			if self.state == AIFieldCourseTurnGeneratorState.EXTEND_SEGMENT then
				self.turnData = self.originalTurnData:offset(self.startOffset, self.endOffset)
			else
				self.turnData = self.originalTurnData:offset(-self.startOffset, -self.endOffset)
			end
			local v73_, _ = self:getBestTurnByTurnData(self.turnData)
			if v73_ ~= nil then
				local v74_ = self.offsetTurns
				table.insert(v74_, v73_)
				local v75_ = MathUtil.vector2Length(self.turnData.ex - self.turnData.sx, self.turnData.ez - self.turnData.sz)
				if v73_.length * self.turnData.turnRadius < v75_ * 1.25 then
					self:onFinished(AIFieldCourseTurnGenerator.getLowestCostTurn(self.offsetTurns) or v73_)
					return
				end
			end
			self.startOffset = self.startOffset + 3
			if self.startOffset > self.startOffsetLimit then
				self.startOffset = self.defaultStartOffset
				self.endOffset = self.endOffset + 3
				if self.endOffset > self.endOffsetLimit then
					local v76_ = AIFieldCourseTurnGenerator.getLowestCostTurn(self.offsetTurns)
					if v76_ ~= nil then
						self:onFinished(v76_)
						return
					end
					if self.state ~= AIFieldCourseTurnGeneratorState.EXTEND_SEGMENT then
						self:onFinished(nil)
						return
					end
					for v77_ = #self.offsetTurns, 1, -1 do
						self.offsetTurns[v77_] = nil
					end
					local v78_ = self.defaultStartOffset
					local v79_ = self.defaultEndOffset
					self.startOffset = v78_
					self.endOffset = v79_
					self.state = AIFieldCourseTurnGeneratorState.SHRINK_SEGMENT
				end
			end
		end
	end
end

-- Local values: minCostOffsetTurn, minCostOffset, _, turn, cost
function AIFieldCourseTurnGenerator.getLowestCostTurn(turns)
	local v81_ = math.huge
	local v82_ = nil
	for _, v83_ in ipairs(turns) do
		if v83_.numBoundaryIntersections == 0 then
			local v84_ = v83_:getOverallCost()
			if v84_ < v81_ then
				v82_ = v83_
				v81_ = v84_
			end
		end
	end
	return v82_
end

-- Local values: boundary, _, island
function AIFieldCourseTurnGenerator.isPositionOutsideField(sx, sz, turnData, useProtectedBoundary, useRootBoundary)
	local v90_ = turnData.validPathBoundary.boundaryLine
	if useProtectedBoundary then
		v90_ = turnData.protectedBoundary.boundaryLine
	end
	if useRootBoundary then
		v90_ = turnData.fieldRootBoundary.boundaryLine
	end
	if FieldCourseUtil.getDistanceToBoundary(sx, sz, v90_) > 0.01 and not FieldCourseUtil.getIsPointInsideBoundary(sx, sz, v90_) then
		return true
	end
	for _, v91_ in ipairs(turnData.islands) do
		local v92_ = v91_.validPathBoundary
		if useProtectedBoundary then
			v92_ = v91_.protectedBoundary
		end
		if useRootBoundary then
			v92_ = v91_.rootBoundary
		end
		if FieldCourseUtil.getDistanceToBoundary(sx, sz, v92_.boundaryLine) > 0.01 and FieldCourseUtil.getIsPointInsideBoundary(sx, sz, v92_.boundaryLine) then
			return true
		end
	end
	return false
end

-- Local values: maxOffset, sDistance, sOffset, segment1, direction1, segment2, direction2, validateHit, sIndex, lastIndex1, p1, p2, eIndex, eDistance, eOffset, lastIndex2, p3, p4, dirX1, dirZ1, length1, x1, z1, maxLength1, extendedLength1, dirX2, dirZ2, length2, x2, z2, maxLength2, extendedLength2, intersect, t1, t2, segDistance, segDistance
function AIFieldCourseTurnGenerator.findCommonTurnRadiusIntersection(callback, turnData)
	if turnData.segment1 == nil or turnData.segment2 == nil then
		return
	end
	local v95_ = turnData.turnRadius * 6
	local v96_ = turnData.segment1
	local v97_ = turnData.segment1Direction
	local v98_ = turnData.segment2
	local v99_ = turnData.segment2Direction
	local v100_ = 1
	local v101_ = 0
	local function v123_(p102_, p103_, p104_, p105_)
		-- upvalues: (copy) turnData, (copy) callback
		local v106_ = p102_ + 0.01 + p104_
		local v107_ = p103_ + 0.01 + p105_
		local v108_ = turnData:offset(v106_, v107_)
		local v109_ = v108_.sx
		local v110_ = v108_.sz
		local v111_ = v108_.originalTurnData.sx
		local v112_ = v108_.originalTurnData.sz
		local v113_ = v108_.ex
		local v114_ = v108_.ez
		local v115_ = v108_.originalTurnData.ex
		local v116_ = v108_.originalTurnData.ez
		if FieldCourseUtil.getIsPointInsideBoundary(v109_, v110_, turnData.protectedBoundary.boundaryLine) and FieldCourseUtil.getIsPointInsideBoundary(v111_, v112_, turnData.protectedBoundary.boundaryLine) then
			local v117_, _, _ = FieldCourseUtil.getSegmentBoundaryIntersection(v109_, v110_, v111_, v112_, turnData.protectedBoundary.boundaryLine)
			if v117_ then
				return
			end
		end
		for _, v118_ in ipairs(turnData.islands) do
			if not (FieldCourseUtil.getIsPointInsideBoundary(v109_, v110_, v118_.protectedBoundary.boundaryLine) or FieldCourseUtil.getIsPointInsideBoundary(v111_, v112_, v118_.protectedBoundary.boundaryLine)) then
				local v119_, _, _ = FieldCourseUtil.getSegmentBoundaryIntersection(v109_, v110_, v111_, v112_, v118_.protectedBoundary.boundaryLine)
				if v119_ then
					return
				end
			end
		end
		if FieldCourseUtil.getIsPointInsideBoundary(v113_, v114_, turnData.protectedBoundary.boundaryLine) and FieldCourseUtil.getIsPointInsideBoundary(v115_, v116_, turnData.protectedBoundary.boundaryLine) then
			local v120_, _, _ = FieldCourseUtil.getSegmentBoundaryIntersection(v113_, v114_, v115_, v116_, turnData.protectedBoundary.boundaryLine)
			if v120_ then
				return
			end
		end
		for _, v121_ in ipairs(turnData.islands) do
			if not (FieldCourseUtil.getIsPointInsideBoundary(v113_, v114_, v121_.protectedBoundary.boundaryLine) or FieldCourseUtil.getIsPointInsideBoundary(v115_, v116_, v121_.protectedBoundary.boundaryLine)) then
				local v122_, _, _ = FieldCourseUtil.getSegmentBoundaryIntersection(v113_, v114_, v115_, v116_, v121_.protectedBoundary.boundaryLine)
				if v122_ then
					return
				end
			end
		end
		callback(v106_, v107_, turnData.turnRadius)
	end
	while v95_ > 0 do
		local v124_ = v100_ + 1
		if v97_ > 0 then
			v124_ = #v96_.positions - v100_
		end
		local v125_ = v96_.positions[v124_]
		local v126_ = v96_.positions[v124_ + v97_]
		if v125_ == nil or v126_ == nil then
			break
		end
		local v127_ = turnData.turnRadius * 6
		local v128_ = 1
		local v129_ = 0
		while v127_ > 0 do
			local v130_ = #v98_.positions - (v128_ - 1)
			if v99_ > 0 then
				v130_ = v128_
			end
			local v131_ = v98_.positions[v130_]
			local v132_ = v98_.positions[v130_ + v99_]
			if v131_ == nil or v132_ == nil then
				break
			end
			local v133_ = v125_[1] - v126_[1]
			local v134_ = v125_[2] - v126_[2]
			local v135_ = MathUtil.vector2Length(v133_, v134_)
			local v136_ = v133_ / v135_
			local v137_ = v134_ / v135_
			local v138_ = v126_[1] + v137_ * turnData.turnRadius
			local v139_ = v126_[2] - v136_ * turnData.turnRadius
			local v140_, v141_
			if v126_ == v96_.positions[1] or v126_ == v96_.positions[#v96_.positions] then
				v138_ = v138_ - v136_ * 50
				v139_ = v139_ - v137_ * 50
				v140_ = v135_ + 50
				v141_ = 50
			else
				v140_ = v135_
				v141_ = 0
			end
			if v125_ == v96_.positions[1] or v125_ == v96_.positions[#v96_.positions] then
				v140_ = v140_ + 50
			end
			local v142_ = v132_[1] - v131_[1]
			local v143_ = v132_[2] - v131_[2]
			local v144_ = MathUtil.vector2Length(v142_, v143_)
			local v145_ = v142_ / v144_
			local v146_ = v143_ / v144_
			local v147_ = v131_[1] + v146_ * turnData.turnRadius
			local v148_ = v131_[2] - v145_ * turnData.turnRadius
			local v149_, v150_
			if v131_ == v98_.positions[1] or v131_ == v98_.positions[#v98_.positions] then
				v147_ = v147_ - v145_ * 50
				v148_ = v148_ - v146_ * 50
				v149_ = v144_ + 50
				v150_ = 50
			else
				v149_ = v144_
				v150_ = 0
			end
			if v132_ == v98_.positions[1] or v132_ == v98_.positions[#v98_.positions] then
				v149_ = v149_ + 50
			end
			local v151_, v152_, v153_ = MathUtil.getLineLineIntersection2D(v138_, v139_, v136_, v137_, v147_, v148_, v145_, v146_)
			if v151_ and (v152_ > 0 and (v152_ <= v140_ and (v153_ > 0 and v153_ <= v149_))) then
				if v141_ > 0 then
					v152_ = v152_ - v141_
				end
				if v150_ > 0 then
					v153_ = v153_ - v150_
				end
				v123_(v152_, v153_, v101_, v129_)
			end
			local v154_ = v126_[1] - v137_ * turnData.turnRadius
			local v155_ = v126_[2] + v136_ * turnData.turnRadius
			local v156_, v157_
			if v126_ == v96_.positions[1] or v126_ == v96_.positions[#v96_.positions] then
				v154_ = v154_ - v136_ * 50
				v155_ = v155_ - v137_ * 50
				v156_ = v135_ + 50
				v157_ = 50
			else
				v156_ = v135_
				v157_ = 0
			end
			if v125_ == v96_.positions[1] or v125_ == v96_.positions[#v96_.positions] then
				v156_ = v156_ + 50
			end
			local v158_, v159_, v160_ = MathUtil.getLineLineIntersection2D(v154_, v155_, v136_, v137_, v147_, v148_, v145_, v146_)
			if v158_ and (v159_ > 0 and (v159_ <= v156_ and (v160_ > 0 and v160_ <= v149_))) then
				if v157_ > 0 then
					v159_ = v159_ - v157_
				end
				if v150_ > 0 then
					v160_ = v160_ - v150_
				end
				v123_(v159_, v160_, v101_, v129_)
			end
			local v161_ = v131_[1] - v146_ * turnData.turnRadius
			local v162_ = v131_[2] + v145_ * turnData.turnRadius
			local v163_, v164_
			if v131_ == v98_.positions[1] or v131_ == v98_.positions[#v98_.positions] then
				v161_ = v161_ - v145_ * 50
				v162_ = v162_ - v146_ * 50
				v163_ = v144_ + 50
				v164_ = 50
			else
				v163_ = v144_
				v164_ = 0
			end
			if v132_ == v98_.positions[1] or v132_ == v98_.positions[#v98_.positions] then
				v163_ = v163_ + 50
			end
			local v165_, v166_, v167_ = MathUtil.getLineLineIntersection2D(v154_, v155_, v136_, v137_, v161_, v162_, v145_, v146_)
			if v165_ and (v166_ > 0 and (v166_ <= v156_ and (v167_ > 0 and v167_ <= v163_))) then
				if v157_ > 0 then
					v166_ = v166_ - v157_
				end
				if v164_ > 0 then
					v167_ = v167_ - v164_
				end
				v123_(v166_, v167_, v101_, v129_)
			end
			local v168_ = v126_[1] + v137_ * turnData.turnRadius
			local v169_ = v126_[2] - v136_ * turnData.turnRadius
			local v170_
			if v126_ == v96_.positions[1] or v126_ == v96_.positions[#v96_.positions] then
				v168_ = v168_ - v136_ * 50
				v169_ = v169_ - v137_ * 50
				v135_ = v135_ + 50
				v170_ = 50
			else
				v170_ = 0
			end
			if v125_ == v96_.positions[1] or v125_ == v96_.positions[#v96_.positions] then
				v135_ = v135_ + 50
			end
			local v171_ = v131_[1] - v146_ * turnData.turnRadius
			local v172_ = v131_[2] + v145_ * turnData.turnRadius
			local v173_
			if v131_ == v98_.positions[1] or v131_ == v98_.positions[#v98_.positions] then
				v171_ = v171_ - v145_ * 50
				v172_ = v172_ - v146_ * 50
				v144_ = v144_ + 50
				v173_ = 50
			else
				v173_ = 0
			end
			if v132_ == v98_.positions[1] or v132_ == v98_.positions[#v98_.positions] then
				v144_ = v144_ + 50
			end
			local v174_, v175_, v176_ = MathUtil.getLineLineIntersection2D(v168_, v169_, v136_, v137_, v171_, v172_, v145_, v146_)
			if v174_ and (v175_ > 0 and (v175_ <= v135_ and (v176_ > 0 and v176_ <= v144_))) then
				if v170_ > 0 then
					v175_ = v175_ - v170_
				end
				if v173_ > 0 then
					v176_ = v176_ - v173_
				end
				v123_(v175_, v176_, v101_, v129_)
			end
			local v177_ = MathUtil.vector2Length(v132_[1] - v131_[1], v132_[2] - v131_[2])
			v127_ = v127_ - v177_
			v129_ = v129_ + v177_
			v128_ = v128_ + 1
		end
		local v178_ = MathUtil.vector2Length(v126_[1] - v125_[1], v126_[2] - v125_[2])
		v95_ = v95_ - v178_
		v101_ = v101_ + v178_
		v100_ = v100_ + 1
	end
end

-- Local values: boundaryLine, numPoints, getDistanceToTargetPoint, startIndex1, startIndex2, i, pos, distance1, endIndex1, distance2, endIndex2, i, index, pos, lastPos, i, index, pos, lastPos, distance1, endIndex1, distance2, endIndex2, i, index, pos, lastPos, i, index, pos, lastPos, lastPos
function AIFieldCourseTurnGenerator.generateTurnIntersectionPoints(turnData, intersectionPositions, intersectData, ix, iz, psx, psz, pex, pez)
	local v_u_188_ = intersectData.boundary
	local v_u_189_ = #v_u_188_
	local v190_ = nil
	local v191_ = nil
	local function v200_(p192_, p193_, p194_, p195_)
		-- upvalues: (copy) v_u_189_, (copy) v_u_188_, (copy) turnData, (copy) psx, (copy) psz, (copy) pex, (copy) pez, (copy) ix, (copy) iz
		local v196_ = p192_
		local v197_ = 0
		for v198_ = p192_, p192_ + v_u_189_ * p193_, p193_ do
			local v199_ = v_u_188_[(v198_ - 1) % v_u_189_ + 1]
			if not FieldCourseUtil.getIsPointInsideBoundary(v199_[1], v199_[2], turnData.protectedBoundary.boundaryLine) then
				return math.huge, v196_
			end
			v197_ = v197_ + MathUtil.vector2Length(p194_ - v199_[1], p195_ - v199_[2])
			p194_ = v199_[1]
			p195_ = v199_[2]
			if v199_[1] == psx and v199_[2] == psz or v199_[1] == pex and v199_[2] == pez then
				p192_ = v198_
				break
			end
		end
		return v197_ + MathUtil.vector2Length(p194_ - ix, p195_ - iz), p192_
	end
	for v201_ = 1, #v_u_188_ do
		local v202_ = v_u_188_[v201_]
		if v202_[1] == intersectData.psx then
			if v202_[2] == intersectData.psz then
				v190_ = v201_
			end
		end
		if v202_[1] == intersectData.pex then
			if v202_[2] == intersectData.pez then
				v191_ = v201_
			end
		end
		if v190_ ~= nil and v191_ ~= nil then
			break
		end
	end
	local v203_ = { intersectData.ix, intersectData.iz }
	table.insert(intersectionPositions, v203_)
	local v204_ = v190_ - v191_
	if math.abs(v204_) > 1 then
		if v190_ < v191_ then
			v190_ = v190_ + v_u_189_
		else
			v191_ = v191_ + v_u_189_
		end
	end
	if v191_ < v190_ then
		local v205_, v206_ = v200_(v190_, 1, intersectData.ix, intersectData.iz)
		local v207_, v208_ = v200_(v191_, -1, intersectData.ix, intersectData.iz)
		if v205_ < v207_ then
			for v209_ = v190_, v206_ do
				local v210_ = v_u_188_[(v209_ - 1) % v_u_189_ + 1]
				local v211_ = intersectionPositions[#intersectionPositions]
				if v210_[1] ~= v211_[1] or v210_[2] ~= v211_[2] then
					local v212_ = { v210_[1], v210_[2] }
					table.insert(intersectionPositions, v212_)
				end
			end
		else
			for v213_ = v191_, v208_, -1 do
				local v214_ = v_u_188_[(v213_ - 1) % v_u_189_ + 1]
				local v215_ = intersectionPositions[#intersectionPositions]
				if v214_[1] ~= v215_[1] or v214_[2] ~= v215_[2] then
					local v216_ = { v214_[1], v214_[2] }
					table.insert(intersectionPositions, v216_)
				end
			end
		end
	else
		local v217_, v218_ = v200_(v190_, -1, intersectData.ix, intersectData.iz)
		local v219_, v220_ = v200_(v191_, 1, intersectData.ix, intersectData.iz)
		if v217_ < v219_ then
			for v221_ = v190_, v218_, -1 do
				local v222_ = v_u_188_[(v221_ - 1) % v_u_189_ + 1]
				local v223_ = intersectionPositions[#intersectionPositions]
				if v222_[1] ~= v223_[1] or v222_[2] ~= v223_[2] then
					local v224_ = { v222_[1], v222_[2] }
					table.insert(intersectionPositions, v224_)
				end
			end
		else
			for v225_ = v191_, v220_ do
				local v226_ = v_u_188_[(v225_ - 1) % v_u_189_ + 1]
				local v227_ = intersectionPositions[#intersectionPositions]
				if v226_[1] ~= v227_[1] or v226_[2] ~= v227_[2] then
					local v228_ = { v226_[1], v226_[2] }
					table.insert(intersectionPositions, v228_)
				end
			end
		end
	end
	local v229_ = intersectionPositions[#intersectionPositions]
	if ix ~= v229_[1] or iz ~= v229_[2] then
		table.insert(intersectionPositions, { ix, iz })
	end
end
local v_u_230_ = {
	["ix"] = 0,
	["iz"] = 0,
	["psx"] = 0,
	["psz"] = 0,
	["pex"] = 0,
	["pez"] = 0,
	["boundary"] = nil,
	["isValid"] = false
}

-- Upvalues: tempData
-- Local values: dx, dz, length, intersect, ix, iz, psx, psz, pex, pez, sideOffset, minDistance, minDistanceIsland, _, island, _intersect, _ix, _iz, _psx, _psz, _pex, _pez, sideOffset, distance
function AIFieldCourseTurnGenerator.doIntersectionChecks(intersectionPositions, sx, sz, ex, ez, turnData, intersectData)
	-- upvalues: (copy) v_u_230_
	local v238_ = ex - sx
	local v239_ = ez - sz
	local v240_ = MathUtil.vector2Length(v238_, v239_)
	if v240_ == 0 then
		return true
	end
	local v241_ = v238_ / v240_
	local v242_ = v239_ / v240_
	if #intersectionPositions == 0 and intersectData == nil then
		sx = sx - v241_ * 0.001
		sz = sz - v242_ * 0.001
	end
	local v243_, v244_, v245_, v246_, v247_, v248_, v249_ = FieldCourseUtil.getSegmentClosestBoundaryIntersection(sx + v241_ * 0.001, sz + v242_ * 0.001, ex + v241_ * 0.001, ez + v242_ * 0.001, turnData.validPathBoundary.boundaryLine)
	if v243_ then
		if FieldCourseUtil.getDistanceToSegment(v246_, v247_, v248_, v249_, sx + v241_ * 0.001, sz + v242_ * 0.001) > 0.001 then
			if intersectData ~= nil and (intersectData.isValid and intersectData.boundary == turnData.validPathBoundary.boundaryLine) then
				if turnData.validPathBoundary == turnData.protectedBoundary then
					return false
				end
				AIFieldCourseTurnGenerator.generateTurnIntersectionPoints(turnData, intersectionPositions, intersectData, v244_, v245_, v246_, v247_, v248_, v249_)
				v_u_230_.boundary = nil
				v_u_230_.isValid = false
				return AIFieldCourseTurnGenerator.doIntersectionChecks(intersectionPositions, v244_, v245_, ex, ez, turnData)
			end
			local v250_ = v_u_230_
			v_u_230_.ix = v244_
			v250_.iz = v245_
			local v251_ = v_u_230_
			v_u_230_.psx = v246_
			v251_.psz = v247_
			local v252_ = v_u_230_
			v_u_230_.pex = v248_
			v252_.pez = v249_
			v_u_230_.boundary = turnData.validPathBoundary.boundaryLine
			v_u_230_.isValid = true
			return AIFieldCourseTurnGenerator.doIntersectionChecks(intersectionPositions, v244_, v245_, ex, ez, turnData, v_u_230_)
		end
	else
		local v253_ = math.huge
		local v254_ = false
		local v255_ = 0
		local v256_ = 0
		local v257_ = 0
		local v258_ = 0
		local v259_ = 0
		local v260_ = 0
		local v261_ = nil
		for _, v262_ in ipairs(turnData.islands) do
			local v263_, v264_, v265_, v266_, v267_, v268_, v269_ = FieldCourseUtil.getSegmentClosestBoundaryIntersection(sx + v241_ * 0.001, sz + v242_ * 0.001, ex + v241_ * 0.001, ez + v242_ * 0.001, v262_.validPathBoundary.boundaryLine)
			if v263_ and FieldCourseUtil.getDistanceToSegment(v266_, v267_, v268_, v269_, sx + v241_ * 0.001, sz + v242_ * 0.001) > 0.001 then
				local v270_ = MathUtil.vector2Length(v264_ - sx, v265_ - sz)
				if v270_ < v253_ then
					v261_ = v262_
					v260_ = v269_
					v259_ = v268_
					v258_ = v267_
					v257_ = v266_
					v256_ = v265_
					v255_ = v264_
					v254_ = v263_
					v253_ = v270_
				end
			end
		end
		if v254_ then
			if intersectData ~= nil and (intersectData.isValid and intersectData.boundary == v261_.validPathBoundary.boundaryLine) then
				if v261_.validPathBoundary == v261_.protectedBoundary then
					return false
				end
				AIFieldCourseTurnGenerator.generateTurnIntersectionPoints(turnData, intersectionPositions, intersectData, v255_, v256_, v257_, v258_, v259_, v260_)
				v_u_230_.boundary = nil
				v_u_230_.isValid = false
				return AIFieldCourseTurnGenerator.doIntersectionChecks(intersectionPositions, v255_, v256_, ex, ez, turnData)
			end
			local v271_ = v_u_230_
			v_u_230_.ix = v255_
			v271_.iz = v256_
			local v272_ = v_u_230_
			v_u_230_.psx = v257_
			v272_.psz = v258_
			local v273_ = v_u_230_
			v_u_230_.pex = v259_
			v273_.pez = v260_
			v_u_230_.boundary = v261_.validPathBoundary.boundaryLine
			v_u_230_.isValid = true
			return AIFieldCourseTurnGenerator.doIntersectionChecks(intersectionPositions, v255_, v256_, ex, ez, turnData, v_u_230_)
		end
	end
	return true
end

-- Local values: otherIndex, otherPos, ex, ez, sx, sz, dx, dz, length, intersect, _, _, _, _, _, _, _, island
function AIFieldCourseTurnGenerator.getSkipToPositionIndex(intersectionPositions, startIndex, curX, curZ, turnData)
	for v279_ = #intersectionPositions + 1, startIndex + 1, -1 do
		local v280_ = intersectionPositions[v279_]
		local v281_, v282_
		if v280_ == nil then
			v281_ = turnData.ex
			v282_ = turnData.ez
		else
			v281_ = v280_[1]
			v282_ = v280_[2]
		end
		local v283_ = v281_ - curX
		local v284_ = v282_ - curZ
		local v285_ = MathUtil.vector2Length(v283_, v284_)
		if v285_ > 0 then
			local v286_ = v283_ / v285_
			local v287_ = v284_ / v285_
			local v288_ = curX + v286_ * 0.01
			local v289_ = curZ + v287_ * 0.01
			local v290_ = v281_ - v286_ * 0.01
			local v291_ = v282_ - v287_ * 0.01
			local v292_, _, _, _, _, _, _ = FieldCourseUtil.getSegmentClosestBoundaryIntersection(v288_, v289_, v290_, v291_, turnData.validPathBoundary.boundaryLine)
			if not v292_ then
				v292_ = not FieldCourseUtil.getIsSegmentInsideBoundary(v288_, v289_, v290_, v291_, turnData.validPathBoundary.boundaryLine) and true or v292_
				if not v292_ then
					for _, v293_ in ipairs(turnData.islands) do
						local v294_, v295_, v296_, v297_, v298_, v299_
						v292_, v294_, v295_, v296_, v297_, v298_, v299_ = FieldCourseUtil.getSegmentClosestBoundaryIntersection(v288_, v289_, v290_, v291_, v293_.validPathBoundary.boundaryLine)
						if v292_ then
							break
						end
						if FieldCourseUtil.getIsSegmentInsideBoundary(v288_, v289_, v290_, v291_, v293_.validPathBoundary.boundaryLine) then
							v292_ = true
							break
						end
					end
				end
			end
			if not v292_ then
				return v279_
			end
		end
	end
end

-- Local values: intersectionPositions, startIsOutsideField, sx, sz, ex, ez, intersect, ix, iz, _, _, _, _, numIntersectionPositions, index, sx, sz, skipIndex, indexToRemove, skipIndex, i, firstPosition, dx, dz, secondPosition, length, length, direction, angleDifference, subTurnData, oldIgnoreBoundaryIntersections, turn, lastX, lastZ, lastDx, lastDz, i, p1, p2, p3, p4, dx1, dz1, l1, dx2, dz2, l2, searchPath, ax1, az1, ax2, az2, bx1, bz1, bx2, bz2, intersect, a, b, isLeft, sx, sz, ex, ez, cx, cz, yRot1, yRot2, angle, s, segTurnData, subTurn, _, segment, l1, endTurnData, subTurn, _, segment, directTurn
function AIFieldCourseTurnGenerator:getIntersectionTurn(turnData)
	local v302_ = {}
	local v303_ = turnData.sx
	local v304_ = turnData.sz
	local v305_ = turnData.ex
	local v306_ = turnData.ez
	local v307_, v308_, v309_
	if FieldCourseUtil.getIsPointInsideBoundary(v303_, v304_, turnData.fieldRootBoundary.boundaryLine) then
		v307_ = v304_
		v308_ = v303_
		v309_ = false
	else
		local v310_, v311_, v312_, v313_, v314_
		v310_, v308_, v307_, v311_, v312_, v313_, v314_ = FieldCourseUtil.getSegmentClosestBoundaryIntersection(v303_, v304_, v305_, v306_, turnData.validPathBoundary.boundaryLine)
		if v310_ then
			table.insert(v302_, { v308_, v307_ })
		else
			v307_ = v304_
			v308_ = v303_
		end
		v309_ = true
	end
	if not AIFieldCourseTurnGenerator.doIntersectionChecks(v302_, v308_, v307_, v305_, v306_, turnData) then
		return nil
	end
	local v315_ = #v302_
	if v315_ < 2 then
		return nil
	end
	local v316_ = 1
	while v316_ < #v302_ do
		local v317_ = v302_[v316_][1]
		local v318_ = v302_[v316_][2]
		local v319_ = AIFieldCourseTurnGenerator.getSkipToPositionIndex(v302_, v316_, v317_, v318_, turnData)
		if v319_ ~= nil then
			for v320_ = v319_ - 1, v316_ + 1, -1 do
				table.remove(v302_, v320_)
			end
			v315_ = #v302_
		end
		v316_ = v316_ + 1
	end
	local v321_ = AIFieldCourseTurnGenerator.getSkipToPositionIndex(v302_, 0, turnData.sx, turnData.sz, turnData)
	if v321_ ~= nil then
		for _ = 1, v321_ - 1 do
			table.remove(v302_, 1)
		end
		v315_ = #v302_
	end
	if v315_ <= 0 then
		return nil
	end
	local v322_ = v302_[1]
	local v323_ = v302_[2]
	local v324_, v325_
	if v323_ == nil then
		local v326_ = turnData.ex - v322_[1]
		local v327_ = turnData.ez - v322_[2]
		local v328_ = MathUtil.vector2Length(v326_, v327_)
		v324_ = v326_ / v328_
		v325_ = v327_ / v328_
	else
		local v329_ = v323_[1] - v322_[1]
		local v330_ = v323_[2] - v322_[2]
		local v331_ = MathUtil.vector2Length(v329_, v330_)
		v324_ = v329_ / v331_
		v325_ = v330_ / v331_
	end
	local v332_ = 1
	if self.fieldCourseSettings.allowTurnBackward then
		local v333_ = MathUtil.dotProduct(turnData.sDirX, 0, turnData.sDirZ, v324_, 0, v325_)
		if math.acos(v333_) > 1.5707963267948966 then
			v332_ = -1
			v324_ = v324_ * v332_
			v325_ = v325_ * v332_
		end
	end
	local v334_ = turnData:clone(true, false)
	local v335_ = v322_[1]
	local v336_ = v322_[2]
	v334_.ex = v335_
	v334_.ez = v336_
	v334_.eDirX = v324_
	v334_.eDirZ = v325_
	local v337_ = self.ignoreBoundaryIntersections
	self.ignoreBoundaryIntersections = self.ignoreBoundaryIntersections or v309_
	local v338_ = self:getLowestCostTurnByData(v334_)
	if v338_ == nil then
		return nil
	end
	self.ignoreBoundaryIntersections = v337_
	local v339_ = v322_[1]
	local v340_ = v322_[2]
	local v341_ = 1
	while v341_ < v315_ do
		local v342_ = v302_[v341_]
		local v343_ = v302_[v341_ + 1]
		local v344_ = v302_[v341_ + 1]
		local v345_ = v302_[v341_ + 2]
		if v344_ == nil or v345_ == nil then
			local v346_ = MathUtil.vector2Length(v343_[1] - v339_, v343_[2] - v340_)
			local v347_ = v338_.segments
			local v348_ = AIFieldCourseTurnSegment.new
			local v349_ = v346_ / turnData.turnRadius
			local v350_ = AIFieldCourseTurnSegmentType.STRAIGHT
			table.insert(v347_, v348_(v349_, v350_, v332_))
			v339_ = v344_[1]
			v340_ = v344_[2]
			v324_, v325_ = MathUtil.vector2Normalize(v343_[1] - v342_[1], v343_[2] - v342_[2])
		else
			local v351_ = v343_[1] - v339_
			local v352_ = v343_[2] - v340_
			local v353_ = MathUtil.vector2Length(v351_, v352_)
			local v354_ = v351_ / v353_
			local v355_ = v352_ / v353_
			local v356_ = v345_[1] - v344_[1]
			local v357_ = v345_[2] - v344_[2]
			local v358_ = MathUtil.vector2Length(v356_, v357_)
			local v359_ = v356_ / v358_
			local v360_ = v357_ / v358_
			local v361_ = false
			local v362_, v363_
			if v343_ == v344_ then
				local v364_ = v339_ + v355_ * turnData.turnRadius
				local v365_ = v340_ - v354_ * turnData.turnRadius
				local v366_ = v343_[1] + v355_ * turnData.turnRadius
				local v367_ = v343_[2] - v354_ * turnData.turnRadius
				local v368_ = v344_[1] + v360_ * turnData.turnRadius
				local v369_ = v344_[2] - v359_ * turnData.turnRadius
				local v370_ = v345_[1] + v360_ * turnData.turnRadius
				local v371_ = v345_[2] - v359_ * turnData.turnRadius
				local v372_, v373_, v374_ = MathUtil.getLineSegmentsIntersectionParameter(v364_, v365_, v366_, v367_, v368_, v369_, v370_, v371_)
				local v375_
				if v372_ then
					v375_ = true
				else
					v364_ = v339_ - v355_ * turnData.turnRadius
					v365_ = v340_ + v354_ * turnData.turnRadius
					local v376_ = v343_[1] - v355_ * turnData.turnRadius
					local v377_ = v343_[2] + v354_ * turnData.turnRadius
					local v378_ = v344_[1] - v360_ * turnData.turnRadius
					local v379_ = v344_[2] + v359_ * turnData.turnRadius
					local v380_ = v345_[1] - v360_ * turnData.turnRadius
					local v381_ = v345_[2] + v359_ * turnData.turnRadius
					v372_, v373_, v374_ = MathUtil.getLineSegmentsIntersectionParameter(v364_, v365_, v376_, v377_, v378_, v379_, v380_, v381_)
					v375_ = false
				end
				if v372_ then
					local v382_ = v339_ + v354_ * v373_ * v353_
					local v383_ = v340_ + v355_ * v373_ * v353_
					v362_ = v344_[1] + v359_ * v374_ * v358_
					v363_ = v344_[2] + v360_ * v374_ * v358_
					local v384_ = v364_ + v354_ * v373_ * v353_
					local v385_ = v365_ + v355_ * v373_ * v353_
					local v386_ = MathUtil.getYRotationFromDirection(MathUtil.vector2Normalize(v384_ - v382_, v385_ - v383_))
					local v387_ = MathUtil.getYRotationFromDirection(MathUtil.vector2Normalize(v384_ - v362_, v385_ - v363_))
					local v388_ = v386_ - MathUtil.normalizeRotationForShortestPath(v387_, v386_)
					local v389_ = math.abs(v388_)
					local v390_ = v373_ * v353_
					if v390_ > 0 then
						local v391_ = v338_.segments
						local v392_ = AIFieldCourseTurnSegment.new
						local v393_ = v390_ / turnData.turnRadius
						local v394_ = AIFieldCourseTurnSegmentType.STRAIGHT
						table.insert(v391_, v392_(v393_, v394_, v332_))
						local v395_ = v338_.segments
						local v396_ = AIFieldCourseTurnSegment.new
						local v397_ = v375_ and AIFieldCourseTurnSegmentType.LEFT or AIFieldCourseTurnSegmentType.RIGHT
						table.insert(v395_, v396_(v389_, v397_, v332_))
					else
						v360_ = v325_
						v359_ = v324_
						v363_ = v340_
						v362_ = v339_
						v361_ = true
					end
				else
					v360_ = v325_
					v359_ = v324_
					v363_ = v340_
					v362_ = v339_
					v361_ = true
				end
			else
				v360_ = v325_
				v359_ = v324_
				v363_ = v340_
				v362_ = v339_
				v361_ = true
			end
			if v361_ then
				local v398_ = MathUtil.vector2Length(v343_[1] - v362_, v343_[2] - v363_)
				local v399_ = v338_.segments
				local v400_ = AIFieldCourseTurnSegment.new
				local v401_ = v398_ / turnData.turnRadius
				local v402_ = AIFieldCourseTurnSegmentType.STRAIGHT
				table.insert(v399_, v400_(v401_, v402_, v332_))
				local v403_ = turnData:clone(false, false)
				local v404_ = v343_[1]
				local v405_ = v343_[2]
				v403_.sx = v404_
				v403_.sz = v405_
				local v406_, v407_ = MathUtil.vector2Normalize(v343_[1] - v362_, v343_[2] - v363_)
				v403_.sDirX = v406_
				v403_.sDirZ = v407_
				local v408_ = v344_[1]
				local v409_ = v344_[2]
				v403_.ex = v408_
				v403_.ez = v409_
				local v410_, v411_ = MathUtil.vector2Normalize(v345_[1] - v344_[1], v345_[2] - v344_[2])
				v403_.eDirX = v410_
				v403_.eDirZ = v411_
				local v412_ = self:getLowestCostTurnByData(v403_)
				if v412_ == nil then
					return nil
				end
				for _, v413_ in ipairs(v412_.segments) do
					local v414_ = v338_.segments
					table.insert(v414_, v413_)
				end
				v338_:updateLength()
				v339_ = v344_[1]
				v340_ = v344_[2]
				v324_, v325_ = MathUtil.vector2Normalize(v343_[1] - v342_[1], v343_[2] - v342_[2])
			else
				v325_ = v360_
				v324_ = v359_
				v340_ = v363_
				v339_ = v362_
			end
		end
		v338_:updateLength()
		v341_ = v341_ + 1
	end
	local v415_ = turnData:clone(false, true)
	v415_.sx = v339_
	v415_.sz = v340_
	local v416_ = v324_ * v332_
	local v417_ = v325_ * v332_
	v415_.sDirX = v416_
	v415_.sDirZ = v417_
	local v418_ = self:getLowestCostTurnByData(v415_)
	if v418_ == nil then
		return nil
	end
	for _, v419_ in ipairs(v418_.segments) do
		local v420_ = v338_.segments
		table.insert(v420_, v419_)
	end
	v338_.turnData.segment2 = v418_.turnData.segment2
	v338_.turnData.segment2Direction = v418_.turnData.segment2Direction
	v338_:updateLength()
	v338_:updateCost()
	if v315_ == 1 then
		local v421_ = self:getLowestCostTurnByData(turnData)
		if v421_ ~= nil and (v421_.numBoundaryIntersections == 0 and v421_:getOverallCost() < v338_:getOverallCost()) then
			return v421_
		end
	end
	v338_.turnData = turnData:clone()
	return v338_
end

-- Local values: turn
function AIFieldCourseTurnGenerator:getBestTurnByTurnData(turnData)
	local v424_ = self:getIntersectionTurn(turnData)
	if v424_ == nil then
		return self:getLowestCostTurnByData(turnData)
	else
		return v424_
	end
end

-- Local values: dubinsPath, reedsSheppPath
function AIFieldCourseTurnGenerator:generateTurnsByData(turns, turnData)
	DubinsPath.new(turnData, self.forcedDrivingDirection):generate(function(p428_)
		-- upvalues: (copy) turns, (copy) self
		local v429_ = turns
		table.insert(v429_, p428_)
		if dp ~= nil then
			local v430_ = self.alternativeTurnSegments
			table.insert(v430_, p428_)
		end
	end)
	if turnData.canTurnBackward then
		ReedsSheppPath.new(turnData, self.forcedDrivingDirection):generate(function(p431_)
			-- upvalues: (copy) turns, (copy) self
			local v432_ = turns
			table.insert(v432_, p431_)
			if dp ~= nil then
				local v433_ = self.alternativeTurnSegments
				table.insert(v433_, p431_)
			end
		end)
	end
end

-- Local values: turns, offsetTurnData, offsetStep, offset, startOffset, endOffset, offsetTurnData, minCostTurn, minCost, _, turn, cost
function AIFieldCourseTurnGenerator:getLowestCostTurnByData(turnData)
	if not self.ignoreBoundaryIntersections and (AIFieldCourseTurnGenerator.isPositionOutsideField(turnData.sx, turnData.sz, turnData, true, self.allowProtectedBoundary) or AIFieldCourseTurnGenerator.isPositionOutsideField(turnData.ex, turnData.ez, turnData, true, self.allowProtectedBoundary)) then
		return nil
	end
	local v_u_436_ = {}
	self:generateTurnsByData(v_u_436_, turnData)
	if self.maxOffset == nil and (not turnData.canTurnBackward and turnData.allowStraightReversing) then
		self:generateTurnsByData(v_u_436_, (turnData:offset(0, 2.5)))
	end
	if self.maxOffset ~= nil then
		for v437_ = 3, self.maxOffset, 3 do
			local v438_, v439_
			if turnData.canTurnBackward or turnData.allowStraightReversing then
				v438_ = v437_
				v439_ = v438_
				local v440_ = v438_
				v438_ = v439_
				v440_ = v439_
			else
				if turnData.segment1 == nil then
					v439_ = v437_
				else
					local v441_ = turnData.segment1.length - (turnData.segment1.lastStartOffset or 0)
					v439_ = math.min(v437_, v441_)
				end
				if turnData.segment2 == nil then
					v438_ = v437_
				else
					local v442_ = turnData.segment2.length - (turnData.segment2.lastEndOffset or 0)
					v438_ = math.min(v437_, v442_)
				end
			end
			self:generateTurnsByData(v_u_436_, (turnData:offset(v439_, v438_)))
		end
	end
	AIFieldCourseTurnGenerator.findCommonTurnRadiusIntersection(function(p443_, p444_, p445_)
		-- upvalues: (copy) turnData, (copy) self, (copy) v_u_436_
		if turnData.turnRadius >= p443_ and turnData.turnRadius >= p444_ then
			local v446_ = turnData:offset(p443_, p444_)
			if not (turnData.canTurnBackward or turnData.allowStraightReversing) then
				if -p443_ > turnData.segment1.length then
					return
				end
				if turnData.segment2.length < p444_ then
					return
				end
			end
			v446_.turnRadius = p445_
			self:generateTurnsByData(v_u_436_, v446_)
		end
	end, turnData)
	local v447_ = math.huge
	local v448_ = nil
	for _, v449_ in ipairs(v_u_436_) do
		v449_:updateCost(self.allowProtectedBoundary, self.preferOneDrivingDirection)
		local v450_ = v449_:getOverallCost()
		if v450_ < v447_ and (v449_.numBoundaryIntersections == 0 or self.ignoreBoundaryIntersections) then
			v448_ = v449_
			v447_ = v450_
		end
	end
	return v448_, v_u_436_
end

-- Local values: numPositions, pos1, pos2, dx, dz, intersect, ix, iz, distanceToIntersection, startIndex, limit, direction, distanceToIntersection, i, pos, nextPos, intersect, ix, iz
function AIFieldCourseTurnGenerator.getSegmentMinOffset(startPosition, segment, segmentDirection, turnData, offsetLimit)
	local v456_ = #segment.positions
	if startPosition then
		local v457_ = segment.positions[1]
		local v458_ = segment.positions[2]
		if segmentDirection > 0 then
			v457_ = segment.positions[v456_]
			v458_ = segment.positions[v456_ - 1]
		end
		local v459_, v460_ = MathUtil.vector2Normalize(v457_[1] - v458_[1], v457_[2] - v458_[2])
		local v461_, v462_, v463_ = FieldCourseUtil.getSegmentClosestBoundaryIntersection(v457_[1], v457_[2], v457_[1] + v459_ * offsetLimit, v457_[2] + v460_ * offsetLimit, turnData.protectedBoundary.boundaryLine)
		if v461_ then
			return -(MathUtil.vector2Length(v462_ - v457_[1], v463_ - v457_[2]) + 0.1)
		end
	else
		local v464_ = v456_ - 1
		local v465_
		if segmentDirection < 0 then
			v464_ = 2
			v465_ = -1
		else
			v456_ = 1
			v465_ = 1
		end
		local v466_ = 0
		for v467_ = v456_, v464_, v465_ do
			local v468_ = segment.positions[v467_]
			local v469_ = segment.positions[v467_ + v465_]
			if not AIFieldCourseTurnGenerator.isPositionOutsideField(v468_[1], v468_[2], turnData, true) then
				break
			end
			if not AIFieldCourseTurnGenerator.isPositionOutsideField(v469_[1], v469_[2], turnData, true) then
				local v470_, v471_, v472_ = FieldCourseUtil.getSegmentClosestBoundaryIntersection(v468_[1], v468_[2], v469_[1], v469_[2], turnData.protectedBoundary.boundaryLine)
				if v470_ then
					local v473_ = v466_ + MathUtil.vector2Length(v471_ - v468_[1], v472_ - v468_[2])
					return math.min(v473_, offsetLimit)
				end
				break
			end
			v466_ = v466_ + MathUtil.vector2Length(v469_[1] - v468_[1], v469_[2] - v468_[2])
		end
	end
	return nil
end
