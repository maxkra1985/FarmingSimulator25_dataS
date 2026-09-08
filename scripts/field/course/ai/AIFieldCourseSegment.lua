-- Local values: AIFieldCourseSegment_mt
AIFieldCourseSegment = {}
local AIFieldCourseSegment_mt = Class(AIFieldCourseSegment)

-- Upvalues: AIFieldCourseSegment_mt
-- Local values: self
function AIFieldCourseSegment.new(fieldCourseSettings)
	-- upvalues: (copy) AIFieldCourseSegment_mt
	local v3_ = AIFieldCourseSegment_mt
	local v4_ = setmetatable({}, v3_)
	v4_.positions = {}
	v4_.length = 0
	v4_.posIndex = 1
	v4_.isTurn = false
	v4_.isActualLine = nil
	v4_.isInitialLine = nil
	v4_.isCornerCutOut = false
	v4_.isHeadlandSegment = false
	v4_.isIslandSegment = false
	v4_.sideOffset = 0
	v4_.segmentId = nil
	v4_.segmentIsReady = false
	v4_.fieldCourseSettings = fieldCourseSettings
	return v4_
end

function AIFieldCourseSegment:isValid()
	local v6_
	if #self.positions > 0 then
		v6_ = self.posIndex < #self.positions
	else
		v6_ = false
	end
	return v6_
end

function AIFieldCourseSegment:isReady()
	return self.segmentIsReady
end

-- Local values: segment
function AIFieldCourseSegment:clone()
	local v9_ = AIFieldCourseSegment.new()
	v9_.positions = table.clone(self.positions, 5)
	v9_.length = self.length
	v9_.segmentIsReady = self.segmentIsReady
	v9_.isTurn = self.isTurn
	v9_.isActualLine = self.isActualLine
	v9_.isInitialLine = self.isInitialLine
	v9_.isCornerCutOut = self.isCornerCutOut
	v9_.turn = self.turn
	v9_.isHeadlandSegment = self.isHeadlandSegment
	v9_.isIslandSegment = self.isIslandSegment
	v9_.sideOffset = self.sideOffset
	v9_.segmentId = self.segmentId
	return v9_
end

-- Local values: i, _
function AIFieldCourseSegment:reset()
	for v11_, _ in ipairs(self.positions) do
		self.positions[v11_] = nil
	end
	self.length = 0
	self.posIndex = 1
	self.isTurn = false
	self.isActualLine = nil
	self.isInitialLine = nil
	self.isCornerCutOut = false
	self.turn = nil
	self.isHeadlandSegment = false
	self.isIslandSegment = false
	self.sideOffset = 0
	self.segmentId = nil
end

-- Local values: i
function AIFieldCourseSegment:setSegment(segment, direction, lastTurn, nextTurn)
	self.segmentIsReady = false
	if direction == 1 then
		self.positions = table.clone(segment.positions, 5)
	else
		self.positions = {}
		for v17_ = #segment.positions, 1, -1 do
			local v18_ = self.positions
			local v19_ = table.clone
			local v20_ = segment.positions[v17_]
			table.insert(v18_, v19_(v20_, 5))
		end
	end
	if not (self.fieldCourseSettings.canTurnBackward or self.fieldCourseSettings.allowStraightReversing) then
		if lastTurn ~= nil then
			FieldCourseUtil.extendSegment(self.positions, -1, -lastTurn.turnData.endOffset)
		end
		if nextTurn ~= nil then
			FieldCourseUtil.extendSegment(self.positions, 1, -nextTurn.turnData.startOffset)
		end
	end
	self.posIndex = 1
	self.isTurn = false
	self.turn = nil
	self.isHeadlandSegment = segment.isHeadlandSegment
	self.isIslandSegment = segment.isIslandSegment
	self.sideOffset = segment.sideOffset or 0
	self.segmentId = segment.segmentId
	self.isActualLine = nil
	if segment.isActualLine ~= nil then
		self.isActualLine = segment.isActualLine
	end
	self.isInitialLine = segment.isInitialLine
	self.isCornerCutOut = Utils.getNoNil(segment.isCornerCutOut, false)
	self.length = FieldCourseUtil.getSegmentLength(self.positions)
	self.segmentIsReady = true
end

-- Local values: segmentToValidate, pos, boxLength, bx, bz, rx, ry, rz, sx, sy, sz, by
function AIFieldCourseSegment:overlapCallback(nodeId, subShapeIndex)
	local v23_ = self.segmentToValidate
	if nodeId == 0 then
		self.segmentToValidate = nil
		self.segmentIsReady = true
		if v23_.numOverlapChecks > 1 then
			local v24_ = self.positions[v23_.posIndex]
			v24_[1] = v24_[1] + v23_.dir[1] * v23_.offset
			v24_[2] = v24_[2] + v23_.dir[2] * v23_.offset
		end
	else
		local v25_ = v23_.length - 2
		v23_.length = math.max(v25_, 0)
		if v23_.length > 0 then
			v23_.numOverlapChecks = v23_.numOverlapChecks + 1
			v23_.offset = v23_.offset - 2
			local v26_ = v23_.length
			local v27_ = v23_.s[1] + v23_.dir[1] * (v26_ * 0.5)
			local v28_ = v23_.s[2] + v23_.dir[2] * (v26_ * 0.5)
			local v29_ = MathUtil.getYRotationFromDirection(v23_.dir[1], v23_.dir[2])
			local v30_ = self.fieldCourseSettings.implementWidth + 0.5
			local v31_ = self.fieldCourseSettings.agentHeight + 0.5
			local v32_ = getTerrainHeightAtWorldPos(g_terrainNode, v27_, 0, v28_) + v31_ * 0.5
			overlapBoxAsync(v27_, v32_, v28_, 0, v29_, 0, v30_ * 0.5, v31_ * 0.5, v26_ * 0.5, "overlapCallback", self, CollisionFlag.AI_BLOCKING, false, false, true, true)
		else
			table.remove(self.positions, v23_.posIndex)
			table.remove(self.positions, v23_.posIndex)
			self.segmentToValidate = nil
			self.segmentIsReady = true
		end
	end
	return false
end

-- Local values: originalTurnData, lastX, lastZ, numPositions, dirX, dirZ, segmentLength, lastPos, x, z, boxLength, bx, bz, rx, ry, rz, sx, sy, sz, by, segmentToValidate, direction, originalTurnData
function AIFieldCourseSegment:setTurn(turn, addStraighteningSegment)
	self.segmentIsReady = false
	self.positions = {}
	if self.fieldCourseSettings.canTurnBackward or self.fieldCourseSettings.allowStraightReversing then
		local v36_ = turn.turnData.originalTurnData
		if v36_ ~= nil and turn.turnData.startOffset ~= 0 then
			local v37_ = self.positions
			local v38_ = { v36_.sx, v36_.sz, 1 }
			table.insert(v37_, v38_)
			local v39_ = self.positions
			local v40_ = {}
			local v41_ = turn.turnData.sx
			local v42_ = turn.turnData.sz
			local v43_ = turn.turnData.startOffset
			__set_list(v40_, 1, {v41_, v42_, -math.sign(v43_)})
			table.insert(v39_, v40_)
		end
	end
	local v44_ = #self.positions
	local v_u_45_, v_u_46_
	if v44_ > 0 then
		v_u_45_ = self.positions[v44_][1]
		v_u_46_ = self.positions[v44_][2]
	else
		v_u_45_ = nil
		v_u_46_ = nil
	end
	turn:iterate(1, function(p47_, p48_, p49_, p50_)
		-- upvalues: (ref) v_u_45_, (ref) v_u_46_, (copy) self
		if p47_ ~= v_u_45_ or p48_ ~= v_u_46_ then
			if p50_ then
				if #self.positions > 0 then
					local v51_ = self.positions[#self.positions]
					if v51_.shadowPositions == nil then
						v51_.shadowPositions = {}
					end
					local v52_ = v51_.shadowPositions
					table.insert(v52_, { p47_, p48_ })
					return
				end
			else
				local v53_ = self.positions
				table.insert(v53_, { p47_, p48_, p49_ })
				v_u_45_ = p47_
				v_u_46_ = p48_
			end
		end
	end, 3)
	if self.fieldCourseSettings.canTurnBackward or self.fieldCourseSettings.allowStraightReversing then
		local v54_ = turn.turnData.eDirX
		local v55_ = turn.turnData.eDirZ
		if (not self.fieldCourseSettings.canTurnBackward or self.fieldCourseSettings.toolStraighteningAlwaysActive) and addStraighteningSegment ~= false then
			local v56_ = self.fieldCourseSettings.toolStraighteningSegmentLength
			local v57_ = self.fieldCourseSettings.toolBackOffset
			local v58_ = v56_ * math.sign(v57_)
			local v59_ = self.positions[#self.positions]
			local v60_ = v59_[1] - v54_ * v58_
			local v61_ = v59_[2] - v55_ * v58_
			if self.fieldCourseSettings.toolBackOffset < 0 and not FieldCourseUtil.getIsPointInsideBoundary(v60_, v61_, turn.turnData.protectedBoundary.boundaryLine) then
				local v62_ = math.abs(v58_) + self.fieldCourseSettings.agentFrontOffset
				local v63_ = v59_[1] + v54_ * (v62_ * 0.5)
				local v64_ = v59_[2] + v55_ * (v62_ * 0.5)
				local v65_ = MathUtil.getYRotationFromDirection(v54_, v55_)
				local v66_ = self.fieldCourseSettings.implementWidth + 0.5
				local v67_ = self.fieldCourseSettings.agentHeight + 0.5
				local v68_ = getTerrainHeightAtWorldPos(g_terrainNode, v63_, 0, v64_) + v67_ * 0.5
				overlapBoxAsync(v63_, v68_, v64_, 0, v65_, 0, v66_ * 0.5, v67_ * 0.5, v62_ * 0.5, "overlapCallback", self, CollisionFlag.AI_BLOCKING, false, false, true, true)
				self.segmentToValidate = {
					["s"] = { v59_[1], v59_[2] },
					["e"] = { v60_, v61_ },
					["dir"] = { v54_, v55_ },
					["length"] = v62_,
					["offset"] = 0,
					["numOverlapChecks"] = 1,
					["posIndex"] = #self.positions + 1
				}
			end
			local v69_ = math.sign(v58_)
			local v70_ = self.positions
			local v71_ = {
				v60_,
				v61_,
				-v69_,
				true
			}
			table.insert(v70_, v71_)
			local v72_ = self.positions
			local v73_ = { v59_[1], v59_[2], v69_ }
			table.insert(v72_, v73_)
		end
		local v74_ = turn.turnData.originalTurnData
		if v74_ ~= nil and turn.turnData.endOffset ~= 0 then
			local v75_ = self.positions
			local v76_ = {}
			local v77_ = v74_.ex
			local v78_ = v74_.ez
			local v79_ = turn.turnData.endOffset
			__set_list(v76_, 1, {v77_, v78_, -math.sign(v79_)})
			table.insert(v75_, v76_)
		end
	end
	self.posIndex = 1
	self.isTurn = true
	self.turn = turn
	self.isHeadlandSegment = false
	self.isIslandSegment = false
	self.sideOffset = 0
	if turn.turnData.segment2 ~= nil then
		self.sideOffset = turn.turnData.segment2.sideOffset or 0
	end
	self.isActualLine = nil
	if turn.isActualLine ~= nil then
		self.isActualLine = turn.isActualLine
	end
	self.isInitialLine = turn.isInitialLine
	self.isCornerCutOut = Utils.getNoNil(turn.isCornerCutOut, false)
	self.length = FieldCourseUtil.getSegmentLength(self.positions)
	self.segmentIsReady = self.segmentToValidate == nil
end

function AIFieldCourseSegment:setPositions(positions)
	self.positions = positions
	self.posIndex = 1
	self.isTurn = false
	self.turn = nil
	self.isHeadlandSegment = false
	self.isIslandSegment = false
	self.length = FieldCourseUtil.getSegmentLength(self.positions)
end

-- Local values: pos
function AIFieldCourseSegment:getIsOnActualLine()
	if self.isActualLine ~= nil then
		return self.isActualLine
	end
	if self.isTurn then
		return false
	end
	local v83_ = self.positions[self.posIndex]
	return v83_ == nil or v83_[3] ~= -1
end

-- Local values: i, pos1, pos2, dirX, dirZ, length, dot, tx, tz, direction, rx, _, rz, toolReverserDirectionNodeOffset, rx, _, rz, distance, subPosition, subLength
function AIFieldCourseSegment:getDriveData(dt, vX, vY, vZ, vSpeed, steeringOffset, toolReverserDirectionNode)
	for v92_ = self.posIndex, #self.positions - 1 do
		local v93_ = self.positions[v92_]
		local v94_ = self.positions[v92_ + 1]
		local v95_ = v94_[1] - v93_[1]
		local v96_ = v94_[2] - v93_[2]
		local v97_ = MathUtil.vector2Length(v95_, v96_)
		if v97_ > 0 then
			local v98_ = v95_ / v97_
			local v99_ = v96_ / v97_
			local v100_ = MathUtil.getProjectOnLineParameter(vX, vZ, v93_[1], v93_[2], v98_, v99_)
			if v100_ <= v97_ then
				if self.posIndex < v92_ then
					self.posIndex = v92_
				end
				local v101_ = v100_ + steeringOffset
				local v102_, v103_ = self:getPositionOffset(v92_, (math.max(v101_, 0)))
				local v104_ = v94_[3] or 1
				if v104_ < 0 and toolReverserDirectionNode ~= nil then
					local v105_, _, v106_ = getWorldTranslation(toolReverserDirectionNode)
					local v107_ = v100_ + (MathUtil.vector2Length(v105_ - vX, v106_ - vZ) + 2.5)
					v102_, v103_ = self:getPositionOffset(v92_, (math.max(v107_, 0)))
				end
				if v94_[4] ~= true or toolReverserDirectionNode == nil then
					::l12::
					local v108_, v109_ = self:getSubSegmentPosition(v92_, v100_)
					return v102_, v103_, v104_, self:getSegmentPosition(v92_, v100_), self.length, v108_, v109_
				end
				local v110_, _, v111_ = getWorldTranslation(toolReverserDirectionNode)
				if FieldCourseUtil.getDistanceToSegment(v93_[1], v93_[2], v94_[1], v94_[2], v110_, v111_) >= 0.5 then
					goto l12
				end
			end
		end
	end
	self.posIndex = self.posIndex + 1
	if self.posIndex > #self.positions - 1 then
		return nil, nil
	else
		return self:getDriveData(dt, vX, vY, vZ, vSpeed, steeringOffset, toolReverserDirectionNode)
	end
end

-- Local values: pos, distance, i, pos1, pos2
function AIFieldCourseSegment:skipCurrentSubSegment(maxDistance)
	local v114_ = self.positions[self.posIndex]
	local v115_ = 0
	for v116_ = self.posIndex + 1, #self.positions - 1 do
		local v117_ = self.positions[v116_ - 1]
		local v118_ = self.positions[v116_]
		if v117_ ~= nil then
			v115_ = v115_ + MathUtil.vector2Length(v118_[1] - v117_[1], v118_[2] - v117_[2])
		end
		if maxDistance < v115_ then
			return
		end
		if self.positions[v116_][3] ~= v114_[3] then
			self.posIndex = v116_
			return
		end
	end
	self.posIndex = #self.positions
end

-- Local values: numPositions, i, pos1, pos2, dirX, dirZ, length, nextSegmentHasSameDirection, nextSegment, isLastPosition, lastShadowPos, numShadowPositions, shadowPosIndex, shadowPos, dirX, dirZ, shadowLength
function AIFieldCourseSegment:getPositionOffset(index, pos)
	local v122_ = #self.positions
	for v123_ = index, v122_ - 1 do
		local v124_ = self.positions[v123_]
		local v125_ = self.positions[v123_ + 1]
		local v126_ = v125_[1] - v124_[1]
		local v127_ = v125_[2] - v124_[2]
		local v128_ = MathUtil.vector2Length(v126_, v127_)
		if v128_ ~= 0 then
			local v129_ = v126_ / v128_
			local v130_ = v127_ / v128_
			local v131_ = self.positions[v123_ + 2]
			local v132_ = v131_ == nil and true or (v131_[3] or 1) == (v125_[3] or 1)
			local v133_ = v123_ == v122_ - 1
			if pos < v128_ or (v133_ or not v132_) then
				if v128_ < pos and v125_.shadowPositions ~= nil then
					local v134_ = #v125_.shadowPositions
					for v135_, v136_ in ipairs(v125_.shadowPositions) do
						local v137_ = v136_[1] - v125_[1]
						local v138_ = v136_[2] - v125_[2]
						local v139_ = MathUtil.vector2Length(v137_, v138_)
						if v139_ == 0 then
							return nil
						end
						local v140_ = v137_ / v139_
						local v141_ = v138_ / v139_
						if pos < v139_ or v135_ == v134_ then
							return v125_[1] + v140_ * pos, v125_[2] + v141_ * pos
						end
						pos = pos - v139_
						v125_ = v136_
					end
				end
				return v124_[1] + v129_ * pos, v124_[2] + v130_ * pos
			end
			pos = pos - v128_
		end
	end
	return nil
end

-- Local values: position, i, x1, z1, x2, z2, length
function AIFieldCourseSegment:getSegmentPosition(index, dot)
	local v145_ = 0
	for v146_ = 1, #self.positions - 1 do
		local v147_ = self.positions[v146_][1]
		local v148_ = self.positions[v146_][2]
		local v149_ = self.positions[v146_ + 1][1]
		local v150_ = self.positions[v146_ + 1][2]
		local v151_ = MathUtil.vector2Length(v149_ - v147_, v150_ - v148_)
		if v146_ == index then
			v145_ = v145_ + math.clamp(dot, 0, v151_)
			break
		end
		v145_ = v145_ + v151_
	end
	return v145_ / self.length
end

-- Local values: direction, prevLength, i, x1, z1, x2, z2, nextLength, i, x1, z1, x2, z2, x1, z1, x2, z2, length
function AIFieldCourseSegment:getSubSegmentPosition(index, dot)
	local v155_ = self.positions[index][3] or 1
	local v156_ = 0
	for v157_ = index - 1, 1, -1 do
		if (self.positions[v157_][3] or 1) ~= v155_ then
			break
		end
		local v158_ = self.positions[v157_][1]
		local v159_ = self.positions[v157_][2]
		local v160_ = self.positions[v157_ + 1][1]
		local v161_ = self.positions[v157_ + 1][2]
		v156_ = v156_ + MathUtil.vector2Length(v160_ - v158_, v161_ - v159_)
	end
	local v162_ = 0
	for v163_ = index, #self.positions - 1 do
		if (self.positions[v163_][3] or 1) ~= v155_ then
			break
		end
		local v164_ = self.positions[v163_][1]
		local v165_ = self.positions[v163_][2]
		local v166_ = self.positions[v163_ + 1][1]
		local v167_ = self.positions[v163_ + 1][2]
		v162_ = v162_ + MathUtil.vector2Length(v166_ - v164_, v167_ - v165_)
	end
	local v168_ = self.positions[index][1]
	local v169_ = self.positions[index][2]
	local v170_ = self.positions[index + 1][1]
	local v171_ = self.positions[index + 1][2]
	local v172_ = MathUtil.vector2Length(v170_ - v168_, v171_ - v169_)
	local v173_ = math.clamp(dot, 0, v172_)
	local v174_ = v156_ + v162_
	return (v156_ + v173_) / v174_, v174_
end

-- Local values: minDistance, signedDistance, i, x1, z1, x2, z2, dirX, dirZ, length, dot, lx, lz, distance, odx, odz, sideDot
function AIFieldCourseSegment:getSignedOffsetToSegment(x, z)
	local v178_ = math.huge
	local v179_ = 0
	for v180_ = 1, #self.positions - 1 do
		local v181_ = self.positions[v180_][1]
		local v182_ = self.positions[v180_][2]
		local v183_ = self.positions[v180_ + 1][1]
		local v184_ = self.positions[v180_ + 1][2]
		local v185_ = v183_ - v181_
		local v186_ = v184_ - v182_
		local v187_ = MathUtil.vector2Length(v185_, v186_)
		if v187_ > 0 then
			local v188_ = v185_ / v187_
			local v189_ = v186_ / v187_
			local v190_ = MathUtil.getProjectOnLineParameter(x, z, v181_, v182_, v188_, v189_)
			if v190_ > 0 and v190_ <= v187_ then
				local v191_ = v181_ + v188_ * v190_
				local v192_ = v182_ + v189_ * v190_
				local v193_ = MathUtil.vector2Length(x - v191_, z - v192_)
				if v193_ > 0 and v193_ < v178_ then
					local v194_, v195_ = MathUtil.vector2Normalize(x - v191_, z - v192_)
					local v196_ = MathUtil.dotProduct(v189_, 0, -v188_, v194_, 0, v195_)
					v179_ = v193_ * math.sign(v196_)
					v178_ = v193_
				end
			end
		end
	end
	return v179_
end

-- Local values: distance, numPositions, i, x1, z1, x2, z2, length, segmentAlpha
function AIFieldCourseSegment:getPosition(alpha)
	local v199_ = #self.positions
	local v200_ = 0
	for v201_ = 1, v199_ - 1 do
		local v202_ = self.positions[v201_][1]
		local v203_ = self.positions[v201_][2]
		local v204_ = self.positions[v201_ + 1][1]
		local v205_ = self.positions[v201_ + 1][2]
		local v206_ = MathUtil.vector2Length(v204_ - v202_, v205_ - v203_)
		if v200_ + v206_ > alpha * self.length then
			local v207_ = (alpha * self.length - v200_) / v206_
			return MathUtil.lerp(v202_, v204_, v207_), MathUtil.lerp(v203_, v205_, v207_)
		end
		v200_ = v200_ + v206_
	end
	return self.positions[v199_][1], self.positions[v199_][2]
end

-- Local values: _, position, lastX, lastZ, _, shadowPosition, y1, y2
function AIFieldCourseSegment:draw(r, g, b, subSegmentIndex, indexToDraw)
	AIFieldCourseUtil.drawPath(self.positions, r, g, b, subSegmentIndex, indexToDraw)
	for _, v214_ in ipairs(self.positions) do
		if v214_.shadowPositions ~= nil then
			local v215_ = v214_[1]
			local v216_ = v214_[2]
			for _, v217_ in ipairs(v214_.shadowPositions) do
				local v218_ = getTerrainHeightAtWorldPos(g_terrainNode, v215_, 0, v216_) + 0.25
				local v219_ = getTerrainHeightAtWorldPos(g_terrainNode, v217_[1], 0, v217_[2]) + 0.25
				drawDebugLine(v215_, v218_, v216_, 0.15, 0.15, 0.15, v217_[1], v219_, v217_[2], 0.15, 0.15, 0.15, false)
				v215_ = v217_[1]
				v216_ = v217_[2]
			end
		end
	end
end

-- Local values: halfWidth, i, p1, p2, dx, dz, p, direction, x1, z1, x2, z2, x3, z3, x4, z4, y
function AIFieldCourseSegment:drawToolPreview(implementWidth, toolFrontOffset, toolBackOffset)
	local v224_ = implementWidth * 0.5
	for v225_ = 1, #self.positions do
		local v226_ = self.positions[v225_ - 1]
		local v227_ = self.positions[v225_]
		if v226_ == nil then
			v226_ = self.positions[v225_]
			v227_ = self.positions[v225_ + 1]
		end
		local v228_, v229_ = MathUtil.vector2Normalize(v227_[1] - v226_[1], v227_[2] - v226_[2])
		local v230_ = self.positions[v225_]
		local v231_ = self.positions[v225_][3] or 1
		local v232_ = v230_[1] + v229_ * v224_ + v228_ * toolFrontOffset * v231_
		local v233_ = v230_[2] - v228_ * v224_ + v229_ * toolFrontOffset * v231_
		local v234_ = v230_[1] - v229_ * v224_ + v228_ * toolFrontOffset * v231_
		local v235_ = v230_[2] + v228_ * v224_ + v229_ * toolFrontOffset * v231_
		local v236_ = v230_[1] + v229_ * v224_ + v228_ * toolBackOffset * v231_
		local v237_ = v230_[2] - v228_ * v224_ + v229_ * toolBackOffset * v231_
		local v238_ = v230_[1] - v229_ * v224_ + v228_ * toolBackOffset * v231_
		local v239_ = v230_[2] + v228_ * v224_ + v229_ * toolBackOffset * v231_
		local v240_ = getTerrainHeightAtWorldPos(g_terrainNode, v232_, 0, v233_) + 0.5
		local v241_ = getTerrainHeightAtWorldPos(g_terrainNode, v234_, 0, v235_) + 0.5
		local v242_ = math.max(v240_, v241_)
		local v243_ = getTerrainHeightAtWorldPos(g_terrainNode, v236_, 0, v237_) + 0.5
		local v244_ = math.max(v242_, v243_)
		local v245_ = getTerrainHeightAtWorldPos(g_terrainNode, v238_, 0, v239_) + 0.5
		local v246_ = math.max(v244_, v245_)
		drawDebugTriangle(v232_, v246_, v233_, v236_, v246_, v237_, v234_, v246_, v235_, 0, 1, 0, 0.2, true)
		drawDebugTriangle(v238_, v246_, v239_, v234_, v246_, v235_, v236_, v246_, v237_, 0, 1, 0, 0.2, true)
	end
end
