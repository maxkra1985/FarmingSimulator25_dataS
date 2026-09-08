-- Local values: AIFieldCourseFirstSegmentDetection_mt
AIFieldCourseFirstSegmentDetection = {}
local AIFieldCourseFirstSegmentDetection_mt = Class(AIFieldCourseFirstSegmentDetection)

-- Upvalues: AIFieldCourseFirstSegmentDetection_mt
-- Local values: self
function AIFieldCourseFirstSegmentDetection.new(aiFieldCourse, segmentOrderTask)
	-- upvalues: (copy) AIFieldCourseFirstSegmentDetection_mt
	local v4_ = AIFieldCourseFirstSegmentDetection_mt
	local v5_ = setmetatable({}, v4_)
	v5_.aiFieldCourse = aiFieldCourse
	v5_.fieldCourseSettings = aiFieldCourse.fieldCourseSettings
	v5_.segmentOrderTask = segmentOrderTask
	v5_.segments = segmentOrderTask.segments
	v5_.segmentsToSkip = {}
	v5_.lastActiveSegmentId = nil
	return v5_
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

-- Local values: hasSegment, _, segment, numStraightSegments, numHeadlandSegments, _, segment, headlandsFirst, numHeadlands, _, segment, i, _, segment, scoreScale
function AIFieldCourseFirstSegmentDetection:detect()
	if self.lastActiveSegmentId ~= nil then
		local v19_ = false
		for _, v20_ in ipairs(self.segments) do
			if self.segmentsToSkip[v20_.segmentId] == nil and (self.lastActiveSegmentId == nil or self.lastActiveSegmentId == v20_.segmentId) then
				v19_ = true
				break
			end
		end
		if not v19_ then
			self.lastActiveSegmentId = false
		end
	end
	local v21_ = 0
	local v22_ = 0
	for _, v23_ in ipairs(self.segments) do
		if self.segmentsToSkip[v23_.segmentId] == nil and (self.lastActiveSegmentId == nil or self.lastActiveSegmentId == v23_.segmentId) then
			if v23_.lineGroupIndex ~= nil then
				v22_ = v22_ + 1
			end
			if v23_.isHeadlandSegment then
				v21_ = v21_ + 1
			end
		end
	end
	local v24_ = ((not self.fieldCourseSettings.headlandsFirst or v21_ <= 0) and true or false) and not self.fieldCourseSettings.headlandsFirst
	if v24_ then
		v24_ = v22_ == 0
	end
	local v25_ = 0
	if v24_ then
		for _, v26_ in ipairs(self.segments) do
			if self.segmentsToSkip[v26_.segmentId] == nil and (self.lastActiveSegmentId == nil or self.lastActiveSegmentId == v26_.segmentId) and v26_.isHeadlandSegment then
				local v27_ = v26_.headlandIndex
				v25_ = math.max(v25_, v27_)
			end
		end
		if v25_ > 0 then
			for v28_ = 1, v25_ do
				self:splitClosestSegment(self.startX, self.startZ, self.startDirX, self.startDirZ, true, v28_)
			end
		end
	else
		self:splitClosestSegment(self.startX, self.startZ, self.startDirX, self.startDirZ, false, nil)
	end
	self.potentialSegments = {}
	for _, v29_ in ipairs(self.segments) do
		if self.segmentsToSkip[v29_.segmentId] == nil and (self.lastActiveSegmentId == nil or self.lastActiveSegmentId == v29_.segmentId) then
			if v24_ then
				if v29_.isHeadlandSegment then
					local v30_ = 1 - (v29_.headlandIndex - 1) / v25_
					if v29_.lockedDirection == nil or v29_.lockedDirection == 1 then
						local v31_ = self.potentialSegments
						local v32_ = {
							["segment"] = v29_,
							["direction"] = 1,
							["score"] = self:getSegmentScore(v29_, 1) * v30_
						}
						table.insert(v31_, v32_)
					end
					if v29_.lockedDirection == nil or v29_.lockedDirection == -1 then
						local v33_ = self.potentialSegments
						local v34_ = {
							["segment"] = v29_,
							["direction"] = -1,
							["score"] = self:getSegmentScore(v29_, -1) * v30_
						}
						table.insert(v33_, v34_)
					end
				end
			elseif v29_.lineGroupIndex ~= nil then
				if v29_.lockedDirection == nil or v29_.lockedDirection == 1 then
					local v35_ = self.potentialSegments
					local v36_ = {
						["segment"] = v29_,
						["direction"] = 1,
						["score"] = self:getSegmentScore(v29_, 1)
					}
					table.insert(v35_, v36_)
				end
				if v29_.lockedDirection == nil or v29_.lockedDirection == -1 then
					local v37_ = self.potentialSegments
					local v38_ = {
						["segment"] = v29_,
						["direction"] = -1,
						["score"] = self:getSegmentScore(v29_, -1)
					}
					table.insert(v37_, v38_)
				end
			end
		end
	end
	table.sort(self.potentialSegments, function(p39_, p40_)
		return p39_.score > p40_.score
	end)
	g_fieldCourseManager:addUpdateable(self)
end

-- Local values: i, segmentData, x, z
function AIFieldCourseFirstSegmentDetection:debugScoring()
	for v42_, v43_ in ipairs(self.potentialSegments) do
		local v44_, v45_ = AIFieldCourseUtil.getSegmentPosition(v43_.direction == 1, v43_.segment, 1)
		dp(v44_, v45_, string.format("seg%d d%d s%.4f", v43_.segment.index, v43_.direction, v43_.score), v42_ * 0.1)
	end
end

-- Local values: sizeX, sizeY, sizeZ, segmentData, boundaryLine, sx, sz, x1, z1, x2, z2, dirX, dirZ, bx, bz, rx, ry, rz, by
function AIFieldCourseFirstSegmentDetection:update(dt)
	if #self.potentialSegments > 0 then
		if not self.overlapInProgress then
			local v47_ = self.fieldCourseSettings.implementWidth + 0.5
			local v48_ = self.fieldCourseSettings.agentHeight + 0.5
			local v49_ = self.fieldCourseSettings.toolBackOffset + self.fieldCourseSettings.agentBackOffset
			local v50_ = self.potentialSegments[1]
			local v51_ = self.aiFieldCourse.fieldRootBoundary.boundaryLine
			local v52_, v53_ = AIFieldCourseUtil.extendHeadlandSegment(self.segments, v50_.segment.index, -v50_.direction, 1, self.fieldCourseSettings.implementWidth, v51_, false)
			local v54_, v55_ = AIFieldCourseUtil.getSegmentPosition(v50_.direction == 1, v50_.segment, 1)
			if v52_ == nil then
				v52_ = v54_
				v53_ = v55_
			end
			local v56_, v57_ = AIFieldCourseUtil.getSegmentPosition(v50_.direction == 1, v50_.segment, 1, 1)
			local v58_, v59_ = MathUtil.vector2Normalize(v56_ - v54_, v57_ - v55_)
			local v60_ = v52_ - v58_ * (v49_ * 0.5)
			local v61_ = v53_ - v59_ * (v49_ * 0.5)
			local v62_ = MathUtil.getYRotationFromDirection(v58_, v59_)
			local v63_ = getTerrainHeightAtWorldPos(g_terrainNode, v60_, 0, v61_) + v48_ * 0.5
			overlapBoxAsync(v60_, v63_, v61_, 0, v62_, 0, v47_ * 0.5, v48_ * 0.5, v49_ * 0.5, "overlapCallback", self, CollisionFlag.AI_BLOCKING, false, false, true, true)
			self.overlapInProgress = true
			return
		end
	else
		g_fieldCourseManager:removeUpdateable(self)
		self:doCallback(false, nil, 1)
	end
end

-- Local values: segmentData
function AIFieldCourseFirstSegmentDetection:overlapCallback(nodeId, subShapeIndex)
	if nodeId == 0 then
		g_fieldCourseManager:removeUpdateable(self)
		local v66_ = self.potentialSegments[1]
		self:doCallback(true, v66_.segment, v66_.direction)
	else
		table.remove(self.potentialSegments, 1)
	end
	self.overlapInProgress = false
	return false
end

-- Local values: sx, sz, ox, oz, dx, dz, dot, distance
function AIFieldCourseFirstSegmentDetection:getSegmentScore(segment, direction)
	local v70_, v71_ = AIFieldCourseUtil.getSegmentPosition(direction == 1, segment, 1)
	local v72_, v73_ = AIFieldCourseUtil.getSegmentPosition(direction == 1, segment, 1, 1)
	local v74_, v75_ = MathUtil.vector2Normalize(v72_ - v70_, v73_ - v71_)
	local v76_ = MathUtil.dotProduct(self.startDirX, 0, self.startDirZ, v74_, 0, v75_)
	local v77_ = MathUtil.vector2Length(v70_ - self.startX, v71_ - self.startZ)
	local v78_ = (v76_ + 1) * 0.5
	local v79_ = v77_ / 100
	return v78_ * (1 - math.min(v79_, 0.99))
end

function AIFieldCourseFirstSegmentDetection:doCallback(success, segment, segmentDirection)
	if self.callbackTarget == nil then
		self.callbackFunc(success, segment, segmentDirection)
	else
		self.callbackFunc(self.callbackTarget, success, segment, segmentDirection)
	end
end
function AIFieldCourseFirstSegmentDetection.debugPrint(_, p84_, ...)
	if VehicleDebug.state == VehicleDebug.DEBUG_AI then
		print("AIFieldCourseFirstSegmentDetection: " .. string.format(p84_, ...))
	end
end

-- Local values: toolFrontOffset, toolBackOffset, minDistance, _, segment, isAllowed, x2, z2, x3, z3, startDistance, endDistance, minSideOffset, minSideOffsetSegmentIndex, minSideOffsetSegmentPosIndex, segmentIndex, segment, isAllowed, sideOffset, positionIndex, segment, p1x, p1z, p2x, p2z, dirX, dirZ, length, dot, splitX, splitZ, prevLength, i, px1, pz1, px2, pz2, nextLength, i, px1, pz1, px2, pz2, minDistanceToSegmentEnd, newSegment, i, i, endX, endZ, nextSegment, prevSegment, nx2, nz2, nx3, nz3, nextDistance, px2, pz2, px3, pz3, prevDistance, index, seg
function AIFieldCourseFirstSegmentDetection:splitClosestSegment(x1, z1, dirX, dirZ, headlandSegment, headlandIndex)
	if dirX ~= nil and dirZ ~= nil then
		if self.fieldCourseSettings.toolFullOverlap then
			local v92_ = self.fieldCourseSettings.toolFrontOffset
			x1 = x1 + dirX * v92_
			z1 = z1 + dirZ * v92_
		else
			local v93_ = self.fieldCourseSettings.toolBackOffset
			x1 = x1 + dirX * v93_
			z1 = z1 + dirZ * v93_
		end
	end
	local v94_ = math.huge
	for _, v95_ in ipairs(self.segments) do
		local v96_
		if headlandSegment then
			v96_ = v95_.isHeadlandSegment or v95_.isIslandSegment
			if v96_ then
				v96_ = headlandIndex == nil and true or v95_.headlandIndex == headlandIndex
			end
		else
			v96_ = v95_.lineGroupIndex ~= nil
		end
		if v96_ then
			local v97_, v98_ = AIFieldCourseUtil.getSegmentPosition(true, v95_, 1)
			local v99_, v100_ = AIFieldCourseUtil.getSegmentPosition(false, v95_, 1)
			local v101_ = MathUtil.vector2Length(v97_ - x1, v98_ - z1)
			if v101_ >= v94_ then
				v101_ = v94_
			end
			v94_ = MathUtil.vector2Length(v99_ - x1, v100_ - z1)
			if v94_ >= v101_ then
				v94_ = v101_
			end
		end
	end
	if v94_ ~= math.huge then
		local v102_ = math.huge
		local v103_ = nil
		local v104_ = nil
		for v105_, v106_ in ipairs(self.segments) do
			local v107_
			if headlandSegment then
				v107_ = v106_.isHeadlandSegment or v106_.isIslandSegment
				if v107_ then
					v107_ = headlandIndex == nil and true or v106_.headlandIndex == headlandIndex
				end
			else
				v107_ = v106_.lineGroupIndex ~= nil
			end
			if v107_ then
				local v108_, v109_ = AIFieldCourseUtil.getSegmentSideOffset(v106_, x1, z1, false)
				if v108_ < v94_ and v108_ < v102_ then
					v104_ = v109_
					v103_ = v105_
					v102_ = v108_
				end
			end
		end
		if v103_ ~= nil then
			local v110_ = self.segments[v103_]
			local v111_ = v110_.positions[v104_][1]
			local v112_ = v110_.positions[v104_][2]
			local v113_ = v110_.positions[v104_ + 1][1]
			local v114_ = v110_.positions[v104_ + 1][2]
			local v115_ = v113_ - v111_
			local v116_ = v114_ - v112_
			local v117_ = MathUtil.vector2Length(v115_, v116_)
			local v118_ = v115_ / v117_
			local v119_ = v116_ / v117_
			local v120_ = MathUtil.getProjectOnLineParameter(x1, z1, v111_, v112_, v118_, v119_)
			local v121_ = v117_ - 0.1
			local v122_ = math.clamp(v120_, 0.1, v121_)
			local v123_ = v111_ + v118_ * v122_
			local v124_ = v112_ + v119_ * v122_
			local v125_ = v122_
			for v126_ = v104_, 2, -1 do
				local v127_ = v110_.positions[v126_][1]
				local v128_ = v110_.positions[v126_][2]
				local v129_ = v110_.positions[v126_ - 1][1]
				local v130_ = v110_.positions[v126_ - 1][2]
				v122_ = v122_ + MathUtil.vector2Length(v127_ - v129_, v128_ - v130_)
			end
			local v131_ = v117_ - v125_
			for v132_ = v104_ + 1, #v110_.positions - 1 do
				local v133_ = v110_.positions[v132_][1]
				local v134_ = v110_.positions[v132_][2]
				local v135_ = v110_.positions[v132_ + 1][1]
				local v136_ = v110_.positions[v132_ + 1][2]
				v131_ = v131_ + MathUtil.vector2Length(v133_ - v135_, v134_ - v136_)
			end
			local v137_ = self.fieldCourseSettings.implementWidth
			local v138_ = math.max(v137_, 5)
			if v122_ < v138_ or v131_ < v138_ then
				return
			end
			local v139_ = table.clone(v110_, math.huge)
			for v140_ = #v110_.positions, v104_ + 2, -1 do
				table.remove(v110_.positions, v140_)
			end
			local v141_ = v110_.positions[v104_ + 1]
			local v142_ = v110_.positions[v104_ + 1]
			v141_[1] = v123_
			v142_[2] = v124_
			for v143_ = v104_ - 1, 1, -1 do
				table.remove(v139_.positions, v143_)
			end
			local v144_ = v139_.positions[1]
			local v145_ = v139_.positions[1]
			v144_[1] = v123_
			v145_[2] = v124_
			local v146_ = v139_.positions[#v139_.positions][1]
			local v147_ = v139_.positions[#v139_.positions][2]
			local v148_ = self.segments[v103_ + 1]
			local v149_ = self.segments[v103_ - 1]
			if v148_ == nil then
				local v150_ = self.segments
				table.insert(v150_, v139_)
			elseif v149_ == nil then
				local v151_ = self.segments
				table.insert(v151_, 1, v139_)
			else
				local v152_, v153_ = AIFieldCourseUtil.getSegmentPosition(true, v148_, 1)
				local v154_, v155_ = AIFieldCourseUtil.getSegmentPosition(false, v148_, 1)
				local v156_ = MathUtil.vector2Length(v146_ - v152_, v147_ - v153_)
				local v157_ = MathUtil.vector2Length
				local v158_ = v146_ - v154_
				local v159_ = v147_ - v155_
				local v160_ = math.min(v156_, v157_(v158_, v159_))
				local v161_, v162_ = AIFieldCourseUtil.getSegmentPosition(true, v149_, 1)
				local v163_, v164_ = AIFieldCourseUtil.getSegmentPosition(false, v149_, 1)
				local v165_ = MathUtil.vector2Length(v146_ - v161_, v147_ - v162_)
				local v166_ = MathUtil.vector2Length
				local v167_ = v146_ - v163_
				local v168_ = v147_ - v164_
				if v160_ < math.min(v165_, v166_(v167_, v168_)) then
					local v169_ = self.segments
					local v170_ = v103_ + 1
					table.insert(v169_, v170_, v139_)
				else
					local v171_ = self.segments
					table.insert(v171_, v103_, v139_)
				end
			end
			for v172_, v173_ in ipairs(self.segments) do
				v173_.index = v172_
			end
		end
	end
	return false
end
