AIFieldCourseUtil = {}

-- Local values: numPositions
function AIFieldCourseUtil.getSegmentPosition(startPosition, segment, direction, offset)
	if not startPosition then
		direction = -direction
	end
	local v5_ = offset or 0
	if direction >= 0 then
		return segment.positions[1 + v5_][1], segment.positions[1 + v5_][2]
	end
	local v6_ = #segment.positions
	return segment.positions[v6_ - v5_][1], segment.positions[v6_ - v5_][2]
end

-- Local values: drivingDirection, x, z, dirX, dirZ, numPositions, x, z, dirX, dirZ
function AIFieldCourseUtil.getSegmentPositionAndDirection(startPosition, segment, direction, offset, limitToOneSegment)
	local v12_ = offset or 0
	if not startPosition then
		direction = -direction
	end
	local v13_ = startPosition and -1 or 1
	if direction >= 0 then
		local v14_ = segment.positions[1][1]
		local v15_ = segment.positions[1][2]
		local v16_, v17_ = MathUtil.vector2Normalize(segment.positions[1][1] - segment.positions[2][1], segment.positions[1][2] - segment.positions[2][2])
		if v12_ ~= 0 then
			v14_, v15_, v16_, v17_ = AIFieldCourseUtil.getSegmentPositionOffset(segment, -direction, -v12_, limitToOneSegment)
		end
		return v14_, v15_, v16_ * v13_, v17_ * v13_
	end
	local v18_ = #segment.positions
	local v19_ = segment.positions[v18_][1]
	local v20_ = segment.positions[v18_][2]
	local v21_, v22_ = MathUtil.vector2Normalize(segment.positions[v18_][1] - segment.positions[v18_ - 1][1], segment.positions[v18_][2] - segment.positions[v18_ - 1][2])
	if v12_ ~= 0 then
		v19_, v20_, v21_, v22_ = AIFieldCourseUtil.getSegmentPositionOffset(segment, -direction, -v12_, limitToOneSegment)
	end
	return v19_, v20_, v21_ * v13_, v22_ * v13_
end

-- Local values: indexOffset, p1, p2, dirX, dirZ, length, p3, indexOffset, p1, p2, dirX, dirZ, length, p3
function AIFieldCourseUtil.getSegmentPositionOffset(segment, direction, offset, limitToOneSegment)
	if direction > 0 then
		local v27_ = 0
		while true do
			local v28_ = segment.positions[#segment.positions - v27_ - 1]
			local v29_ = segment.positions[#segment.positions - v27_]
			local v30_, v31_, v32_
			if v28_ == nil then
				local v33_ = segment.positions[#segment.positions - v27_ + 1]
				local v34_ = v33_[1] - v29_[1]
				local v35_ = v33_[2] - v29_[2]
				v30_ = MathUtil.vector2Length(v34_, v35_)
				v31_ = v34_ / v30_
				v32_ = v35_ / v30_
			else
				local v36_ = v29_[1] - v28_[1]
				local v37_ = v29_[2] - v28_[2]
				v30_ = MathUtil.vector2Length(v36_, v37_)
				v31_ = v36_ / v30_
				v32_ = v37_ / v30_
			end
			if offset >= 0 then
				return v29_[1] + v31_ * offset, v29_[2] + v32_ * offset, v31_, v32_
			end
			if v30_ >= -offset then
				return v29_[1] + v31_ * offset, v29_[2] + v32_ * offset, v31_, v32_
			end
			if limitToOneSegment == true or v28_ == nil then
				if limitToOneSegment == true then
					offset = v30_ * math.sign(offset)
				end
				return v29_[1] + v31_ * offset, v29_[2] + v32_ * offset, v31_, v32_
			end
			offset = offset + v30_
			v27_ = v27_ + 1
		end
	else
		local v38_ = 0
		while true do
			local v39_ = segment.positions[v38_ + 1]
			local v40_ = segment.positions[v38_ + 2]
			local v41_, v42_, v43_
			if v40_ == nil then
				local v44_ = segment.positions[v38_]
				local v45_ = v44_[1] - v39_[1]
				local v46_ = v44_[2] - v39_[2]
				v41_ = MathUtil.vector2Length(v45_, v46_)
				v42_ = v45_ / v41_
				v43_ = v46_ / v41_
			else
				local v47_ = v39_[1] - v40_[1]
				local v48_ = v39_[2] - v40_[2]
				v41_ = MathUtil.vector2Length(v47_, v48_)
				v42_ = v47_ / v41_
				v43_ = v48_ / v41_
			end
			if offset >= 0 then
				return v39_[1] + v42_ * offset, v39_[2] + v43_ * offset, v42_, v43_
			end
			if v41_ >= -offset then
				return v39_[1] + v42_ * offset, v39_[2] + v43_ * offset, v42_, v43_
			end
			if limitToOneSegment == true or v40_ == nil then
				if limitToOneSegment == true then
					offset = v41_ * math.sign(offset)
				end
				return v39_[1] + v42_ * offset, v39_[2] + v43_ * offset, v42_, v43_
			end
			offset = offset + v41_
			v38_ = v38_ + 1
		end
	end
end

-- Local values: numPositions, minDistance, minDistanceIndex, i, x2, z2, x3, z3, dirX, dirZ, length, dot, hitX, hitZ, distance, distance, x2, z2, x3, z3, dirX, dirZ, length, dot, hitX, hitZ, distance, hitX, hitZ, distance
function AIFieldCourseUtil.getSegmentSideOffset(segment, x, z, extendSegment)
	if segment == nil then
		return math.huge, -1
	end
	local v53_ = #segment.positions
	local v54_ = math.huge
	local v55_ = -1
	for v56_ = 1, v53_ - 1 do
		local v57_ = segment.positions[v56_][1]
		local v58_ = segment.positions[v56_][2]
		local v59_ = segment.positions[v56_ + 1][1]
		local v60_ = segment.positions[v56_ + 1][2]
		local v61_ = v59_ - v57_
		local v62_ = v60_ - v58_
		local v63_ = MathUtil.vector2Length(v61_, v62_)
		local v64_ = v61_ / v63_
		local v65_ = v62_ / v63_
		local v66_ = MathUtil.getProjectOnLineParameter(x, z, v57_, v58_, v64_, v65_)
		if v66_ >= 0 and v66_ <= v63_ then
			local v67_ = v57_ + v64_ * v66_
			local v68_ = v58_ + v65_ * v66_
			local v69_ = MathUtil.vector2Length(v67_ - x, v68_ - z)
			if v69_ < v54_ then
				v55_ = v56_
				v54_ = v69_
			end
		else
			local v70_ = MathUtil.vector2Length(v57_ - x, v58_ - z)
			if v70_ < v54_ then
				v55_ = v56_
			else
				v70_ = v54_
			end
			v54_ = MathUtil.vector2Length(v59_ - x, v60_ - z)
			if v54_ < v70_ then
				v55_ = v56_
			else
				v54_ = v70_
			end
		end
	end
	if v55_ < 0 and extendSegment ~= false then
		local v71_ = segment.positions[1][1]
		local v72_ = segment.positions[1][2]
		local v73_ = segment.positions[2][1]
		local v74_ = segment.positions[2][2]
		local v75_ = v73_ - v71_
		local v76_ = v74_ - v72_
		local v77_ = MathUtil.vector2Length(v75_, v76_)
		local v78_ = v75_ / v77_
		local v79_ = v76_ / v77_
		local v80_ = MathUtil.getProjectOnLineParameter(x, z, v71_, v72_, v78_, v79_)
		local v81_
		if v80_ <= v77_ then
			local v82_ = v71_ + v78_ * v80_
			local v83_ = v72_ + v79_ * v80_
			v81_ = MathUtil.vector2Length(v82_ - x, v83_ - z)
			if v81_ < v54_ then
				v55_ = 1
			else
				v81_ = v54_
			end
		else
			v81_ = v54_
		end
		local v84_ = segment.positions[v53_ - 1][1]
		local v85_ = segment.positions[v53_ - 1][2]
		local v86_ = segment.positions[v53_][1]
		local v87_ = segment.positions[v53_][2]
		local v88_ = v86_ - v84_
		local v89_ = v87_ - v85_
		local v90_ = MathUtil.vector2Length(v88_, v89_)
		local v91_ = v88_ / v90_
		local v92_ = v89_ / v90_
		local v93_ = MathUtil.getProjectOnLineParameter(x, z, v84_, v85_, v91_, v92_)
		if v93_ > 0 then
			local v94_ = v84_ + v91_ * v93_
			local v95_ = v85_ + v92_ * v93_
			v54_ = MathUtil.vector2Length(v94_ - x, v95_ - z)
			if v54_ < v81_ then
				v55_ = v53_ - 1
			else
				v54_ = v81_
			end
		else
			v54_ = v81_
		end
	end
	return v54_, v55_
end

-- Local values: numPositions, i, x1, z1, x2, z2, dx, dz, length, dirX, dirZ, x, z, indexToRemove, i, x1, z1, x2, z2, dx, dz, length, dirX, dirZ, x, z, indexToRemove
function AIFieldCourseUtil.cutSegmentByDistance(segment, direction, distance)
	local v99_ = #segment.positions
	if direction > 0 then
		for v100_ = 1, v99_ - 1 do
			local v101_ = segment.positions[v100_][1]
			local v102_ = segment.positions[v100_][2]
			local v103_ = segment.positions[v100_ + 1][1]
			local v104_ = segment.positions[v100_ + 1][2]
			local v105_ = v103_ - v101_
			local v106_ = v104_ - v102_
			local v107_ = MathUtil.vector2Length(v105_, v106_)
			if distance < v107_ then
				local v108_ = v105_ / v107_
				local v109_ = v106_ / v107_
				local v110_ = v101_ + v108_ * distance
				local v111_ = v102_ + v109_ * distance
				local v112_ = segment.positions[v100_]
				local v113_ = segment.positions[v100_]
				v112_[1] = v110_
				v113_[2] = v111_
				for _ = 1, v100_ - 1 do
					table.remove(segment.positions, 1)
				end
				return true
			end
			distance = distance - v107_
		end
		return false
	else
		for v114_ = v99_, 2, -1 do
			local v115_ = segment.positions[v114_][1]
			local v116_ = segment.positions[v114_][2]
			local v117_ = segment.positions[v114_ - 1][1]
			local v118_ = segment.positions[v114_ - 1][2]
			local v119_ = v117_ - v115_
			local v120_ = v118_ - v116_
			local v121_ = MathUtil.vector2Length(v119_, v120_)
			if distance < v121_ then
				local v122_ = v119_ / v121_
				local v123_ = v120_ / v121_
				local v124_ = v115_ + v122_ * distance
				local v125_ = v116_ + v123_ * distance
				local v126_ = segment.positions[v114_]
				local v127_ = segment.positions[v114_]
				v126_[1] = v124_
				v127_[2] = v125_
				for _ = v99_, v114_ + 1, -1 do
					table.remove(segment.positions)
				end
				return true
			end
			distance = distance - v121_
		end
		return false
	end
end

-- Local values: fullLength, length, i, x1, z1, x2, z2, direction, y1, y2, tx, tz, ty, segmentLength, dx, dz, numArrows, j, offset, alpha, sx, sz, y
function AIFieldCourseUtil.drawPath(positions, r, g, b, limitedPositionIndex, indexToDraw, yOffset, drawArrows)
	local v136_ = FieldCourseUtil.getSegmentLength(positions)
	local v137_ = yOffset or 0.25
	local v138_ = 0
	for v139_ = 1, #positions - 1 do
		if limitedPositionIndex == nil or (limitedPositionIndex == 0 or v139_ == limitedPositionIndex) then
			local v140_ = positions[v139_][1]
			local v141_ = positions[v139_][2]
			local v142_ = positions[v139_ + 1][1]
			local v143_ = positions[v139_ + 1][2]
			local v144_ = positions[v139_ + 1][3] or 1
			local v145_ = getTerrainHeightAtWorldPos(g_terrainNode, v140_, 0, v141_) + v137_
			local v146_ = getTerrainHeightAtWorldPos(g_terrainNode, v142_, 0, v143_) + v137_
			if v144_ < 0 then
				drawDebugLine(v140_, v145_ + 0.01, v141_, 1, 0, 0, v142_, v146_ + 0.01, v143_, 1, 0, 0, false)
				drawDebugPoint(v140_, v145_ + 0.01, v141_, 1, 0, 0, 1, false)
				drawDebugPoint(v142_, v146_ + 0.01, v143_, 1, 0, 0, 1, false)
			else
				drawDebugLine(v140_, v145_, v141_, r, g, b, v142_, v146_, v143_, r, g, b, false)
				drawDebugPoint(v140_, v145_, v141_, r, g, b, 1, false)
				drawDebugPoint(v142_, v146_, v143_, r, g, b, 1, false)
			end
			if indexToDraw ~= nil and v139_ == 1 then
				local v147_ = (v140_ + v142_) * 0.5
				local v148_ = (v141_ + v143_) * 0.5
				local v149_ = getTerrainHeightAtWorldPos(g_terrainNode, v147_, 0, v148_) + v137_
				Utils.renderTextAtWorldPosition(v147_, v149_, v148_, tostring(indexToDraw), 0.02, 0, r, g, b, 1)
			end
			if drawArrows ~= false then
				local v150_ = MathUtil.vector2Length(v142_ - v140_, v143_ - v141_)
				if v150_ > 0 then
					local v151_, v152_ = MathUtil.vector2Normalize(v142_ - v140_, v143_ - v141_)
					local v153_ = v150_ / math.min(0.9, v150_)
					local v154_ = math.floor(v153_)
					local v155_ = math.min(v154_, 10)
					for v156_ = 1, v155_ do
						local v157_ = (v156_ - 1) * v150_ / v155_
						local v158_ = (v138_ + v157_) / v136_
						local v159_ = v140_ + v151_ * v157_
						local v160_ = v141_ + v152_ * v157_
						local v161_ = getTerrainHeightAtWorldPos(g_terrainNode, v159_, 0, v160_) + v137_
						drawDebugTriangle(v159_ + v152_ * 0.25, v161_, v160_ - v151_ * 0.25, v159_ - v152_ * 0.25, v161_, v160_ + v151_ * 0.25, v159_ + v151_ * 0.5, v161_, v160_ + v152_ * 0.5, v158_, 1 - v158_, 0, 0.3, true)
					end
					v138_ = v138_ + v150_
				end
			end
		end
	end
end

-- Local values: i, x1, z1, x2, z2, y1, y2, dx, dz
function AIFieldCourseUtil.drawPathArea(positions, r, g, b, a, width)
	local v168_ = width * 0.5
	for v169_ = 1, #positions - 1 do
		local v170_ = positions[v169_][1]
		local v171_ = positions[v169_][2]
		local v172_ = positions[v169_ + 1][1]
		local v173_ = positions[v169_ + 1][2]
		local v174_ = getTerrainHeightAtWorldPos(g_terrainNode, v170_, 0, v171_) + 0.25
		local v175_ = getTerrainHeightAtWorldPos(g_terrainNode, v172_, 0, v173_) + 0.25
		local v176_, v177_ = MathUtil.vector2Normalize(v172_ - v170_, v173_ - v171_)
		drawDebugTriangle(v170_ + v177_ * v168_, v174_, v171_ - v176_ * v168_, v170_ - v177_ * v168_, v174_, v171_ + v176_ * v168_, v172_ + v177_ * v168_, v175_, v173_ - v176_ * v168_, r, g, b, a, true)
		drawDebugTriangle(v170_ - v177_ * v168_, v174_, v171_ + v176_ * v168_, v172_ - v177_ * v168_, v175_, v173_ + v176_ * v168_, v172_ + v177_ * v168_, v175_, v173_ - v176_ * v168_, r, g, b, a, true)
	end
end

-- Local values: segment, drivingDirection, nextSegment, min, max, step, i, segmentToCheck, numPositions, pos1, pos2, pos3, pos4, x1, z1, x2, z2, x3, z3, x4, z4, dx1, dz1, dx2, dz2, yRot1, yRot2, rotationOffset, halfWidth, offset, lineLength, intersection, side2, distance1, _, _, distance2, _, _, maxDistance, segmentLength, maxDistance, ox1, oz1, ox2, oz2, dot1, dot2, maxIntersectOffset, sx, sz, intersect, ix, iz, _, _, _, _, distance, sideOffset
function AIFieldCourseUtil.extendHeadlandSegment(segments, segmentIndex, direction, adjustDirection, implementWidth, boundaryLine, applyChanges, lockDirection)
	local v186_ = applyChanges == nil and true or applyChanges
	local v187_ = segments[segmentIndex]
	local v188_ = segments[segmentIndex + direction]
	if v188_ ~= nil and (v187_.isHeadlandSegment ~= v188_.isHeadlandSegment or (v187_.headlandIndex ~= v188_.headlandIndex or (v187_.isIslandSegment ~= v188_.isIslandSegment or v187_.islandIndex ~= v188_.islandIndex))) then
		v188_ = nil
	end
	local v189_
	if v188_ == nil then
		v189_ = direction
		for v190_ = direction < 0 and #segments or 1, segmentIndex, direction do
			local v191_ = segments[v190_]
			if v187_.isHeadlandSegment == v191_.isHeadlandSegment and (v187_.headlandIndex == v191_.headlandIndex and (v187_.isIslandSegment == v191_.isIslandSegment and v187_.islandIndex == v191_.islandIndex)) then
				v188_ = v191_
				break
			end
		end
	else
		v189_ = direction
	end
	if v188_ ~= nil then
		if adjustDirection < 0 then
			direction = -direction
		else
			local v192_ = v187_
			v187_ = v188_
			v188_ = v192_
		end
		local v193_ = #v188_.positions
		local v194_ = v188_.positions[v193_ - 1]
		local v195_ = v188_.positions[v193_]
		local v196_ = v187_.positions[1]
		local v197_ = v187_.positions[2]
		if direction < 0 then
			v194_ = v188_.positions[2]
			v195_ = v188_.positions[1]
			local v198_ = #v187_.positions
			v196_ = v187_.positions[v198_]
			v197_ = v187_.positions[v198_ - 1]
		end
		local v199_ = v194_[1]
		local v200_ = v194_[2]
		local v_u_201_ = v195_[1]
		local v_u_202_ = v195_[2]
		local v_u_203_ = v196_[1]
		local v_u_204_ = v196_[2]
		local v205_ = v197_[1]
		local v206_ = v197_[2]
		local v_u_207_, v_u_208_ = MathUtil.vector2Normalize(v_u_201_ - v199_, v_u_202_ - v200_)
		local v_u_209_, v_u_210_ = MathUtil.vector2Normalize(v_u_203_ - v205_, v_u_204_ - v206_)
		local v211_ = MathUtil.getYRotationFromDirection(v_u_207_, v_u_208_) - MathUtil.getYRotationFromDirection(v_u_209_, v_u_210_)
		if v211_ > 3.141592653589793 then
			v211_ = v211_ - 6.283185307179586
		elseif v211_ < -3.141592653589793 then
			v211_ = v211_ + 6.283185307179586
		end
		local v_u_212_ = implementWidth * 0.5
		local v_u_213_ = implementWidth * 5
		local v_u_214_ = v_u_213_ * 2
		local function v229_(p215_, p216_, p217_)
			-- upvalues: (copy) v_u_201_, (copy) v_u_207_, (copy) v_u_213_, (copy) v_u_208_, (copy) v_u_212_, (copy) v_u_202_, (copy) v_u_203_, (copy) v_u_209_, (copy) v_u_210_, (copy) v_u_204_, (copy) v_u_214_
			local v218_, v219_, v220_, v221_, v222_, v223_, v224_, v225_
			if p215_ > 0 then
				v218_ = v_u_201_ - v_u_207_ * v_u_213_ + v_u_208_ * v_u_212_ * p216_
				v219_ = v_u_202_ - v_u_208_ * v_u_213_ - v_u_207_ * v_u_212_ * p216_
				v220_ = v_u_207_
				v221_ = v_u_208_
				v222_ = v_u_203_ - v_u_209_ * v_u_213_ + v_u_210_ * v_u_212_ * p217_
				v223_ = v_u_204_ - v_u_210_ * v_u_213_ - v_u_209_ * v_u_212_ * p217_
				v224_ = v_u_209_
				v225_ = v_u_210_
			else
				v218_ = v_u_203_ - v_u_209_ * v_u_213_ + v_u_210_ * v_u_212_ * p216_
				v219_ = v_u_204_ - v_u_210_ * v_u_213_ - v_u_209_ * v_u_212_ * p216_
				v220_ = v_u_209_
				v221_ = v_u_210_
				v222_ = v_u_201_ - v_u_207_ * v_u_213_ + v_u_208_ * v_u_212_ * p217_
				v223_ = v_u_202_ - v_u_208_ * v_u_213_ - v_u_207_ * v_u_212_ * p217_
				v224_ = v_u_207_
				v225_ = v_u_208_
			end
			local v226_, v227_, v228_ = MathUtil.getLineSegmentsIntersection(v218_, v219_, v218_ + v220_ * v_u_214_, v219_ + v221_ * v_u_214_, v222_, v223_, v222_ + v224_ * v_u_214_, v223_ + v225_ * v_u_214_)
			if v226_ then
				return MathUtil.vector2Length(v227_ - v218_, v228_ - v219_) - v_u_213_, v227_, v228_
			else
				return nil, nil, nil
			end
		end
		if MathUtil.vector2Length(v_u_203_ - v_u_201_, v_u_204_ - v_u_202_) < 0.01 then
			local v230_ = (v211_ < 0 and 1 or -1) * direction
			local v231_, _, _ = v229_(direction, 1, v230_)
			local v232_, _, _ = v229_(direction, -1, v230_)
			if v231_ ~= nil and v232_ ~= nil then
				local v233_ = math.max(v231_, v232_)
				local v234_ = MathUtil.vector2Length(v197_[1] - v196_[1], v197_[2] - v196_[2])
				local v235_ = math.abs(v233_)
				local v236_ = v234_ - 0.01
				local v237_ = math.min(v235_, v236_) * math.sign(v233_)
				if v186_ then
					local v238_ = v_u_203_ + v_u_209_ * v237_
					local v239_ = v_u_204_ + v_u_210_ * v237_
					v196_[1] = v238_
					v196_[2] = v239_
				end
			end
			local v240_, _, _ = v229_(-direction, 1, v230_)
			local v241_, _, _ = v229_(-direction, -1, v230_)
			if v240_ ~= nil and v241_ ~= nil then
				local v242_ = math.max(v240_, v241_)
				if math.abs(v211_) > 1.5707963267948966 then
					local v243_ = v196_[1] + v_u_210_ * v_u_212_
					local v244_ = v196_[2] - v_u_209_ * v_u_212_
					local v245_ = v196_[1] - v_u_210_ * v_u_212_
					local v246_ = v196_[2] + v_u_209_ * v_u_212_
					local v247_ = MathUtil.getProjectOnLineParameter(v243_, v244_, v_u_201_, v_u_202_, v_u_207_, v_u_208_)
					local v248_ = MathUtil.getProjectOnLineParameter(v245_, v246_, v_u_201_, v_u_202_, v_u_207_, v_u_208_)
					local v249_ = math.max(v247_, v248_)
					v242_ = math.min(v249_, v242_)
				else
					local v250_ = 0
					local v251_ = v195_[1]
					local v252_ = v195_[2]
					local v253_, v254_, v255_, _, _, _, _ = FieldCourseUtil.getSegmentClosestBoundaryIntersection(v251_, v252_, v251_ + v_u_207_ * v242_, v252_ + v_u_208_ * v242_, boundaryLine)
					if v253_ then
						local v256_ = MathUtil.vector2Length(v251_ - v254_, v255_ - v252_)
						local v257_ = math.max(v250_, v256_)
						local v258_ = v_u_212_ - 0.01
						local v259_ = v195_[1] + v_u_208_ * v258_
						local v260_ = v195_[2] - v_u_207_ * v258_
						local v261_, v262_, v263_, _, _, _, _ = FieldCourseUtil.getSegmentClosestBoundaryIntersection(v259_, v260_, v259_ + v_u_207_ * v242_, v260_ + v_u_208_ * v242_, boundaryLine)
						if v261_ then
							local v264_ = MathUtil.vector2Length(v259_ - v262_, v263_ - v260_)
							v257_ = math.max(v257_, v264_)
						end
						local v265_ = v195_[1] - v_u_208_ * v258_
						local v266_ = v195_[2] + v_u_207_ * v258_
						local v267_, v268_, v269_, _, _, _, _ = FieldCourseUtil.getSegmentClosestBoundaryIntersection(v265_, v266_, v265_ + v_u_207_ * v242_, v266_ + v_u_208_ * v242_, boundaryLine)
						if v267_ then
							local v270_ = MathUtil.vector2Length(v265_ - v268_, v269_ - v266_)
							v257_ = math.max(v257_, v270_)
						end
						v242_ = math.min(v242_, v257_)
					end
				end
				if not v186_ then
					return v_u_201_ + v_u_207_ * v242_, v_u_202_ + v_u_208_ * v242_
				end
				local v271_ = v_u_201_ + v_u_207_ * v242_
				local v272_ = v_u_202_ + v_u_208_ * v242_
				v195_[1] = v271_
				v195_[2] = v272_
			end
			if v186_ then
				v188_.length = FieldCourseUtil.getSegmentLength(v188_.positions)
				v187_.length = FieldCourseUtil.getSegmentLength(v187_.positions)
				if v188_.lockedDirection == nil then
					v188_.lockedDirection = lockDirection or v189_
				end
				if v187_.lockedDirection == nil then
					v187_.lockedDirection = lockDirection or v189_
				end
			end
		end
	end
	return nil, nil
end

-- Local values: numPositions, minDistance, minDistanceIndex, minDistanceX, minDistanceZ, i, x2, z2, x3, z3, dirX, dirZ, length, dot, hitX, hitZ, distance, i, px, pz, distance
function AIFieldCourseUtil.getClosestPositionOnSegment(positions, x, z)
	local v276_ = #positions
	local v277_ = math.huge
	local v278_ = 0
	local v279_ = 0
	local v280_ = -1
	for v281_ = 1, v276_ - 1 do
		local v282_ = positions[v281_][1]
		local v283_ = positions[v281_][2]
		local v284_ = positions[v281_ + 1][1]
		local v285_ = positions[v281_ + 1][2]
		local v286_ = v284_ - v282_
		local v287_ = v285_ - v283_
		local v288_ = MathUtil.vector2Length(v286_, v287_)
		local v289_ = v286_ / v288_
		local v290_ = v287_ / v288_
		local v291_ = MathUtil.getProjectOnLineParameter(x, z, v282_, v283_, v289_, v290_)
		if v291_ >= 0 and v291_ <= v288_ then
			local v292_ = v282_ + v289_ * v291_
			local v293_ = v283_ + v290_ * v291_
			local v294_ = MathUtil.vector2Length(v292_ - x, v293_ - z)
			if v294_ < v277_ then
				v280_ = v281_
				v279_ = v293_
				v278_ = v292_
				v277_ = v294_
			end
		end
	end
	for v295_ = 1, v276_ do
		local v296_ = positions[v295_][1]
		local v297_ = positions[v295_][2]
		local v298_ = MathUtil.vector2Length(v296_ - x, v297_ - z)
		if v298_ < v277_ then
			v280_ = v295_
			v279_ = v297_
			v278_ = v296_
			v277_ = v298_
		end
	end
	return v278_, v279_, v277_, v280_
end

-- Local values: distance, i, x1, z1, x2, z2, cx, cz, sx, sz
function AIFieldCourseUtil.getSegmentToSegmentDistance(segment1, segment2)
	local v301_ = math.huge
	for v302_ = 1, #segment1.positions - 1 do
		local v303_ = segment1.positions[v302_][1]
		local v304_ = segment1.positions[v302_][2]
		local v305_ = segment1.positions[v302_ + 1][1]
		local v306_ = segment1.positions[v302_ + 1][2]
		local v307_ = (v303_ + v305_) * 0.5
		local v308_ = (v304_ + v306_) * 0.5
		local v309_, v310_ = AIFieldCourseUtil.getClosestPositionOnSegment(segment2.positions, v307_, v308_)
		local v311_ = MathUtil.vector2Length
		local v312_ = v309_ - v307_
		local v313_ = v310_ - v308_
		v301_ = math.min(v301_, v311_(v312_, v313_))
	end
	return v301_
end
