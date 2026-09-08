-- Local values: FieldCourseBoundary_mt
FieldCourseBoundary = {}
FieldCourseBoundary.SEGMENT_SPLIT_ANGLE = 0.4363323129985824
local FieldCourseBoundary_mt = Class(FieldCourseBoundary)
function FieldCourseBoundary.new()
	-- upvalues: (copy) FieldCourseBoundary_mt
	local v2_ = FieldCourseBoundary_mt
	local v3_ = setmetatable({}, v2_)
	v3_.segmentSplitAngle = FieldCourseBoundary.SEGMENT_SPLIT_ANGLE
	v3_.segments = {}
	v3_.boundaryLine = {}
	return v3_
end

-- Local values: removedSegments, self
function FieldCourseBoundary.createByBoundaryLine(boundaryLine, segmentSplitAngle)
	local v6_ = FieldCourseBoundary.new()
	v6_.segmentSplitAngle = segmentSplitAngle
	local v7_, v8_ = FieldCourseBoundary.generateSegmentsByBoundaryLine(boundaryLine, segmentSplitAngle)
	v6_.segments = v7_
	if v6_.segments == nil or #v6_.segments <= 0 then
		return nil
	end
	v6_.boundaryLine = boundaryLine
	if v8_ then
		v6_:generateBoundaryLine()
	end
	return v6_
end

function FieldCourseBoundary:isValid()
	return #self.segments > 0
end

-- Local values: segmentParts, _, segment, i, segmentPart, boundaryLine, lengthBefore, lengthAfter, originalLength
function FieldCourseBoundary:extend(offset)
	if self.segments == nil or #self.segments == 0 then
		return nil
	else
		local v12_ = {}
		for _, v13_ in ipairs(self.segments) do
			for v14_ = 1, #v13_.positions - 1 do
				local v15_ = {
					["p1"] = v13_.positions[v14_],
					["p2"] = v13_.positions[v14_ + 1]
				}
				table.insert(v12_, v15_)
			end
		end
		local v16_ = FieldCourseBoundary.getOffsetBoundaryBySegmentParts(v12_, offset)
		if #v16_ == 0 then
			return nil
		else
			local v17_ = table.clone
			local v18_ = v16_[1]
			table.insert(v16_, v17_(v18_))
			FieldCourseUtil.removeShortSegments(v16_, 0.25)
			local v19_ = FieldCourseUtil.getSegmentLength(v16_)
			if FieldCourseBoundary.resolveSelfIntersections(v16_) then
				local v20_ = FieldCourseUtil.getSegmentLength(v16_)
				if v20_ < v19_ * 0.66 then
					return nil
				elseif v20_ <= 0.1 then
					return nil
				else
					local v21_ = FieldCourseUtil.getSegmentLength(self.boundaryLine)
					if offset > 0 then
						if v21_ < v20_ then
							return nil
						end
					elseif v20_ < v21_ then
						return nil
					end
					if FieldCourseBoundary.getIsBoundaryLineInverted(v16_) then
						return nil
					elseif FieldCourseUtil.getAreBoundariesColliding(v16_, self.boundaryLine) then
						return nil
					else
						return FieldCourseBoundary.createByBoundaryLine(v16_, self.segmentSplitAngle)
					end
				end
			else
				return nil
			end
		end
	end
end

-- Local values: boundaryLine, numSegments, i, segment, numPositions, maxPosition, posIndex
function FieldCourseBoundary:generateBoundaryLine()
	local v23_ = #self.segments
	local v24_ = {}
	for v25_, v26_ in ipairs(self.segments) do
		local v27_ = #v26_.positions
		for v28_ = 1, v25_ == v23_ and v27_ and v27_ or v27_ - 1 do
			local v29_ = table.clone
			local v30_ = v26_.positions[v28_]
			table.insert(v24_, v29_(v30_))
		end
	end
	self.boundaryLine = v24_
end

function FieldCourseBoundary:isColliding(otherBoundary)
	return FieldCourseUtil.getAreBoundariesColliding(self.boundaryLine, otherBoundary.boundaryLine)
end

-- Local values: i
function FieldCourseBoundary:isInsideOf(otherBoundary)
	for v35_ = 1, #self.boundaryLine - 1 do
		if not FieldCourseUtil.getIsPointInsideBoundary(self.boundaryLine[v35_][1], self.boundaryLine[v35_][2], otherBoundary.boundaryLine) then
			return false
		end
	end
	return true
end

-- Local values: segmentIndex, segment, posIndex, x1, z1, lastPosition, intersect, ix, iz, i, nextPos, prevPos, intersect2, ix2, iz2, newSegment, indexToRemove, indexToRemove, i, nextPos, intersect, ix, iz, nextPos, x2, z2, intersect, ix1, iz1, intersect2, ix2, iz2, newSegment, i, i, positions
function FieldCourseBoundary:cut(otherBoundary, invert)
	if invert == nil then
		invert = false
	end
	for v39_, v40_ in ipairs(self.segments) do
		if #v40_.positions >= 2 then
			local v41_ = 1
			while v41_ <= #v40_.positions do
				local v42_ = v40_.positions[v41_][1]
				local v43_ = v40_.positions[v41_][2]
				if FieldCourseUtil.getIsPointInsideBoundary(v42_, v43_, otherBoundary.boundaryLine) == not invert then
					local v44_ = v40_.positions[v41_ - 1]
					if v44_ == nil then
						local v45_ = v40_.positions[v41_ + 1]
						if v45_ ~= nil then
							if FieldCourseUtil.getIsPointInsideBoundary(v45_[1], v45_[2], otherBoundary.boundaryLine) == not invert then
								table.remove(v40_.positions, v41_)
								v41_ = v41_ - 1
							else
								local v46_, v47_, v48_ = FieldCourseUtil.getSegmentBoundaryIntersection(v42_, v43_, v45_[1], v45_[2], otherBoundary.boundaryLine)
								if v46_ then
									local v49_ = v40_.positions[v41_]
									local v50_ = v40_.positions[v41_]
									v49_[1] = v47_
									v50_[2] = v48_
								end
							end
						end
					elseif FieldCourseUtil.getIsPointInsideBoundary(v44_[1], v44_[2], otherBoundary.boundaryLine) == invert then
						local v51_, v52_, v53_ = FieldCourseUtil.getSegmentBoundaryIntersection(v42_, v43_, v44_[1], v44_[2], otherBoundary.boundaryLine)
						if v51_ then
							for v54_ = v41_ + 1, #v40_.positions do
								local v55_ = v40_.positions[v54_]
								if FieldCourseUtil.getIsPointInsideBoundary(v55_[1], v55_[2], otherBoundary.boundaryLine) == invert then
									local v56_ = v40_.positions[v54_ - 1]
									local v57_, v58_, v59_ = FieldCourseUtil.getSegmentBoundaryIntersection(v56_[1], v56_[2], v55_[1], v55_[2], otherBoundary.boundaryLine)
									if v57_ then
										local v60_ = v40_.positions[v41_]
										local v61_ = v40_.positions[v41_]
										v60_[1] = v52_
										v61_[2] = v53_
										local v62_ = {
											["positions"] = {}
										}
										local v63_ = v62_.positions
										table.insert(v63_, { v58_, v59_ })
										for v64_ = v54_, #v40_.positions do
											local v65_ = v62_.positions
											local v66_ = v40_.positions[v64_]
											table.insert(v65_, v66_)
											v40_.positions[v64_] = nil
										end
										for v67_ = v54_ - 1, v41_ + 1, -1 do
											v40_.positions[v67_] = nil
										end
										local v68_ = self.segments
										local v69_ = v39_ + 1
										table.insert(v68_, v69_, v62_)
										return self:cut(otherBoundary, invert)
									end
									break
								end
							end
							for v70_ = #v40_.positions, v41_ + 1, -1 do
								v40_.positions[v70_] = nil
							end
						end
					end
				elseif v40_.positions[v41_ + 1] ~= nil then
					local v71_ = v40_.positions[v41_ + 1][1]
					local v72_ = v40_.positions[v41_ + 1][2]
					if FieldCourseUtil.getIsPointInsideBoundary(v42_, v43_, otherBoundary.boundaryLine) == invert and FieldCourseUtil.getIsPointInsideBoundary(v71_, v72_, otherBoundary.boundaryLine) == invert then
						local v73_, v74_, v75_ = FieldCourseUtil.getSegmentClosestBoundaryIntersection(v42_, v43_, v71_, v72_, otherBoundary.boundaryLine)
						if v73_ then
							local v76_, v77_, v78_ = FieldCourseUtil.getSegmentClosestBoundaryIntersection(v71_, v72_, v42_, v43_, otherBoundary.boundaryLine)
							if v76_ then
								local v79_ = v40_.positions
								local v80_ = v41_ + 1
								table.insert(v79_, v80_, { v74_, v75_ })
								local v81_ = {
									["positions"] = {}
								}
								local v82_ = v81_.positions
								table.insert(v82_, { v77_, v78_ })
								for v83_ = v41_ + 2, #v40_.positions do
									local v84_ = v81_.positions
									local v85_ = v40_.positions[v83_]
									table.insert(v84_, v85_)
									v40_.positions[v83_] = nil
								end
								local v86_ = self.segments
								local v87_ = v39_ + 1
								table.insert(v86_, v87_, v81_)
								return self:cut(otherBoundary, invert)
							end
						end
					end
				end
				v41_ = v41_ + 1
			end
		end
	end
	for v88_ = #self.segments, 1, -1 do
		local v89_ = self.segments[v88_].positions
		if #v89_ < 2 then
			table.remove(self.segments, v88_)
		elseif FieldCourseUtil.getSegmentLength(v89_) == 0 then
			table.remove(self.segments, v88_)
		end
	end
end

-- Local values: numSegmentsStart, i, segment, posIndex, x1, z1, x2, z2, dirX, dirZ
function FieldCourseBoundary:removeCollidingSegments(otherBoundary, workWidth)
	local v93_ = #self.segments
	for v94_ = v93_, 1, -1 do
		local v95_ = self.segments[v94_]
		for v96_ = #v95_.positions - 1, 1, -1 do
			local v97_ = v95_.positions[v96_][1]
			local v98_ = v95_.positions[v96_][2]
			local v99_ = v95_.positions[v96_ + 1][1]
			local v100_ = v95_.positions[v96_ + 1][2]
			local v101_, v102_ = MathUtil.vector2Normalize(v99_ - v97_, v100_ - v98_)
			if FieldCourseUtil.getIsSegmentInsideBoundary(v97_ - v102_ * workWidth, v98_ + v101_ * workWidth, v99_ - v102_ * workWidth, v100_ + v101_ * workWidth, otherBoundary.boundaryLine) then
				if not FieldCourseUtil.getIsSegmentInsideBoundary(v97_ + v102_ * workWidth, v98_ - v101_ * workWidth, v99_ + v102_ * workWidth, v100_ - v101_ * workWidth, otherBoundary.boundaryLine) then
					if v96_ == 1 then
						table.remove(v95_.positions, v96_)
					else
						table.remove(v95_.positions, v96_ + 1)
					end
				end
			elseif v96_ == 1 then
				table.remove(v95_.positions, v96_)
			else
				table.remove(v95_.positions, v96_ + 1)
			end
		end
		if #v95_.positions < 2 then
			table.remove(self.segments, v94_)
		end
	end
	return v93_ ~= #self.segments
end

-- Local values: numPositions, posIndex, x1, z1, x2, z2, segmentIndex, segment, numPositions, posIndex, x1, z1, x2, z2
function FieldCourseBoundary:generateDebugLines(line)
	if dl == nil or dp == nil then
		return
	elseif line == nil then
		for _, v105_ in ipairs(self.segments) do
			if v105_.invalid ~= true then
				for v106_ = 1, #v105_.positions - 1 do
					local v107_ = v105_.positions[v106_][1]
					local v108_ = v105_.positions[v106_][2]
					local v109_ = v105_.positions[v106_ + 1][1]
					local v110_ = v105_.positions[v106_ + 1][2]
					dl(v107_, v108_, v109_, v110_, 0.5, false, { 1, 0, 0 })
				end
			end
		end
	else
		for v111_ = 1, #line - 1 do
			local v112_ = line[v111_][1]
			local v113_ = line[v111_][2]
			local v114_ = line[v111_ + 1][1]
			local v115_ = line[v111_ + 1][2]
			dl(v112_, v113_, v114_, v115_, 0.5, false, { 1, 0, 0 })
		end
	end
end

-- Local values: _, segment, numPositions, posIndex, x1, z1, x2, z2, y1, y2
function FieldCourseBoundary:draw(r, g, b, offset)
	for _, v121_ in ipairs(self.segments) do
		local v122_ = #v121_.positions
		for v123_ = 1, v122_ - 1 do
			local v124_ = v121_.positions[v123_][1]
			local v125_ = v121_.positions[v123_][2]
			local v126_ = v121_.positions[v123_ + 1][1]
			local v127_ = v121_.positions[v123_ + 1][2]
			local v128_ = getTerrainHeightAtWorldPos(g_terrainNode, v124_, 0, v125_) + (offset or 1)
			local v129_ = getTerrainHeightAtWorldPos(g_terrainNode, v126_, 0, v127_) + (offset or 1)
			drawDebugLine(v124_, v128_, v125_, r, g, b, v126_, v129_, v127_, r, g, b, false)
			drawDebugPoint(v124_, v128_, v125_, r, g, b, 1, false)
			if v123_ + 1 == v122_ then
				drawDebugPoint(v126_, v129_, v127_, r, g, b, 1, false)
			end
		end
	end
end

-- Local values: numBoundaryPositions, splitSegments, segments, _, splitSegment, segment, removedSegments, i, length, prevSegment, nextSegment, p1, p2, x, z
function FieldCourseBoundary.generateSegmentsByBoundaryLine(boundaryLine, segmentSplitAngle)
	if #boundaryLine < 4 then
		return nil, false
	end
	local v132_ = segmentSplitAngle or FieldCourseBoundary.SEGMENT_SPLIT_ANGLE
	local v133_ = FieldCourseBoundary.splitBoundary(boundaryLine, v132_)
	if v133_ == nil then
		return nil, false
	end
	local v134_ = {}
	for _, v135_ in ipairs(v133_) do
		table.insert(v134_, {
			["positions"] = v135_
		})
	end
	local v136_ = false
	if v134_ ~= nil then
		for v137_ = #v134_, 1, -1 do
			if FieldCourseUtil.getSegmentLength(v134_[v137_].positions) < FieldCourse.MIN_SEGMENT_LENGTH then
				local v138_ = v134_[v137_ - 1] or v134_[#v134_]
				local v139_ = v134_[v137_ + 1] or v134_[1]
				if v138_ ~= nil and v139_ ~= nil then
					local v140_ = v138_.positions[#v138_.positions]
					local v141_ = v139_.positions[1]
					local v142_ = (v140_[1] + v141_[1]) * 0.5
					local v143_ = (v140_[2] + v141_[2]) * 0.5
					v140_[1] = v142_
					v140_[2] = v143_
					v141_[1] = v142_
					v141_[2] = v143_
				end
				table.remove(v134_, v137_)
				v136_ = true
			end
		end
	end
	return v134_, v136_
end

-- Local values: intersectCount, posIndex, pos1, pos2, intersect, ix, iz, distance1, distance2, posIndex, pos, dot, ix, iz, isInside1, isInside2
function FieldCourseBoundary.getLineSegmentIntersections(boundaryLine, ignoreIndex, x, z, dirX, dirZ)
	local v150_ = 0
	for v151_ = 1, #boundaryLine - 1 do
		if v151_ ~= ignoreIndex then
			local v152_ = boundaryLine[v151_]
			local v153_ = boundaryLine[v151_ + 1]
			local v154_, v155_, v156_ = MathUtil.getLineSegmentsIntersection(x, z, x + dirX * 65535, z + dirZ * 65535, v152_[1], v152_[2], v153_[1], v153_[2])
			if v154_ then
				local v157_ = MathUtil.vector2Length(v155_ - v152_[1], v156_ - v152_[2])
				local v158_ = MathUtil.vector2Length(v155_ - v153_[1], v156_ - v153_[2])
				if v157_ ~= 0 and v158_ ~= 0 then
					v150_ = v150_ + 1
				end
			end
		end
	end
	for v159_ = 1, #boundaryLine - 1 do
		local v160_ = boundaryLine[v159_]
		local v161_ = MathUtil.getProjectOnLineParameter(v160_[1], v160_[2], x, z, dirX, dirZ)
		if v161_ > 0 then
			local v162_ = x + dirX * v161_
			local v163_ = z + dirZ * v161_
			if MathUtil.vector2Length(v162_ - v160_[1], v163_ - v160_[2]) == 0 and FieldCourseUtil.getIsPointInsideBoundary(v160_[1] - dirX * 0.01, v160_[2] - dirZ * 0.01, boundaryLine) ~= FieldCourseUtil.getIsPointInsideBoundary(v160_[1] + dirX * 0.01, v160_[2] + dirZ * 0.01, boundaryLine) then
				v150_ = v150_ + 1
			end
		end
	end
	return v150_
end

-- Local values: posIndex, pos1, pos2, x, z, dirX, dirZ, intersectCount
function FieldCourseBoundary.getIsBoundaryLineInverted(boundaryLine)
	for v165_ = 1, #boundaryLine - 1 do
		local v166_ = boundaryLine[v165_]
		local v167_ = boundaryLine[v165_ + 1]
		if v167_ == nil then
			v166_ = boundaryLine[v165_ - 1]
			v167_ = boundaryLine[v165_]
		end
		local v168_ = (v167_[1] + v166_[1]) * 0.5
		local v169_ = (v167_[2] + v166_[2]) * 0.5
		local v170_, v171_ = MathUtil.vector2Normalize(v167_[1] - v166_[1], v167_[2] - v166_[2])
		local v172_ = -v171_
		if FieldCourseBoundary.getLineSegmentIntersections(boundaryLine, v165_, v168_, v169_, v172_, v170_) % 2 == 0 then
			return true
		end
	end
	return false
end

-- Local values: p1, p2, length, isLoop, startIndex, foundIntersection, index1, index2, p1, p2, p3, p4, intersect, pX, pZ, posIndex, pos1, pos2, x, z, dirX, dirZ, length, intersectCount, posIndex, pointsRemove, boundaryLineLength, posIndex1, posOffset, posIndex2, pos1, pos2, i, posIndex
function FieldCourseBoundary.resolveSelfIntersections(boundaryLine)
	local v174_ = boundaryLine[1]
	local v175_ = boundaryLine[#boundaryLine]
	local v176_ = MathUtil.vector2Length(v174_[1] - v175_[1], v174_[2] - v175_[2]) < 0.001
	local v177_ = 1
	while true do
		local v178_ = false
		for v179_ = v177_, #boundaryLine - 1 do
			for v180_ = #boundaryLine, v179_ + 3, -1 do
				local v181_ = boundaryLine[v179_]
				local v182_ = boundaryLine[v179_ + 1]
				local v183_ = boundaryLine[v180_ - 1]
				local v184_ = boundaryLine[v180_]
				local v185_, v186_, v187_ = MathUtil.getLineSegmentsIntersection(v181_[1], v181_[2], v182_[1], v182_[2], v183_[1], v183_[2], v184_[1], v184_[2])
				if v185_ then
					table.insert(boundaryLine, v180_, { v186_, v187_ })
					local v188_ = v179_ + 1
					table.insert(boundaryLine, v188_, { v186_, v187_ })
					v177_ = v179_ + 1
					v178_ = true
				end
			end
			if v178_ then
				goto l5
			end
		end
		::l5::
		if not v178_ then
			for v189_ = 1, #boundaryLine - 1 do
				local v190_ = boundaryLine[v189_]
				local v191_ = boundaryLine[v189_ + 1]
				if v191_ == nil then
					v190_ = boundaryLine[v189_ - 1]
					v191_ = boundaryLine[v189_]
				end
				local v192_ = (v191_[1] + v190_[1]) * 0.5
				local v193_ = (v191_[2] + v190_[2]) * 0.5
				local v194_ = v191_[1] - v190_[1]
				local v195_ = v191_[2] - v190_[2]
				local v196_ = MathUtil.vector2Length(v191_[1] - v190_[1], v191_[2] - v190_[2])
				if v196_ > 0 then
					if v176_ then
						local v197_ = v194_ / v196_
						local v198_ = -(v195_ / v196_)
						if FieldCourseBoundary.getLineSegmentIntersections(boundaryLine, v189_, v192_, v193_, v198_, v197_) % 2 == 0 then
							v190_.isInvalid1 = true
							v191_.isInvalid2 = true
						end
					end
				else
					v190_.isInvalid1 = true
					v191_.isInvalid2 = true
				end
			end
			for v199_ = #boundaryLine, 1, -1 do
				if boundaryLine[v199_].isInvalid1 and boundaryLine[v199_].isInvalid2 then
					table.remove(boundaryLine, v199_)
				end
			end
			while true do
				local v200_ = #boundaryLine
				local v201_ = false
				for v202_ = 1, v200_ - 1 do
					local v203_ = v202_
					for v204_ = 1, v200_ do
						local v205_ = v204_ * 0.5
						local v206_ = v200_ * 0.5
						local v207_ = math.floor(v206_)
						local v208_ = math.min(v205_, v207_)
						local v209_ = v203_ + math.ceil(v208_) * (v204_ % 2 == 0 and 1 or -1)
						local v210_ = boundaryLine[(v203_ - 1) % v200_ + 1]
						local v211_ = boundaryLine[(v209_ - 1) % v200_ + 1]
						if MathUtil.vector2Length(v210_[1] - v211_[1], v210_[2] - v211_[2]) < 0.001 then
							if v209_ >= v203_ then
								local v212_ = v203_
								v203_ = v209_
								v209_ = v212_
							end
							v203_ = v209_
							for v213_ = v209_ + 1, v203_ do
								boundaryLine[(v213_ - 1) % v200_ + 1].isInvalid = true
								v209_ = v203_
								v203_ = v209_
							end
						end
					end
				end
				for v214_ = #boundaryLine, 1, -1 do
					if boundaryLine[v214_].isInvalid then
						table.remove(boundaryLine, v214_)
						v201_ = true
					end
				end
				if not v201_ then
					if #boundaryLine == 0 then
						return false
					end
					if v176_ then
						local v215_ = table.clone
						local v216_ = boundaryLine[1]
						table.insert(boundaryLine, v215_(v216_, 1))
					end
					return true
				end
			end
		end
	end
end

-- Local values: angle, i, x1, z1, x2, z2, x3, z3, dir1X, dir1Z, dir2X, dir2Z, length1, length2, i
function FieldCourseBoundary.getMaxSegmentAngle(points, maxSamples)
	if #points <= 3 then
		return 0
	end
	local v219_ = {}
	for v220_ = 1, #points - 2 do
		local v221_ = points[v220_][1]
		local v222_ = points[v220_][2]
		local v223_ = points[v220_ + 1][1]
		local v224_ = points[v220_ + 1][2]
		local v225_ = points[v220_ + 2][1]
		local v226_ = points[v220_ + 2][2]
		local v227_ = v223_ - v221_
		local v228_ = v224_ - v222_
		local v229_ = v223_ - v225_
		local v230_ = v224_ - v226_
		local v231_ = MathUtil.vector2Length(v227_, v228_)
		local v232_ = MathUtil.vector2Length(v229_, v230_)
		if v231_ > 0 and v232_ > 0 then
			local v233_ = MathUtil.dotProduct(v227_ / v231_, 0, v228_ / v231_, v229_ / v232_, 0, v230_ / v232_)
			local v234_ = 3.141592653589793 - math.acos(v233_)
			table.insert(v219_, v234_)
		end
	end
	table.sort(v219_, function(p235_, p236_)
		return p236_ < p235_
	end)
	for v237_ = maxSamples, 1, -1 do
		if v219_[v237_] ~= nil then
			return v219_[v237_]
		end
	end
	return 0
end

-- Local values: offsetLine
function FieldCourseBoundary.segmentApplySideOffset(segment, sideOffset)
	FieldCourseUtil.extendSegment(segment.positions, -1, 100)
	FieldCourseUtil.extendSegment(segment.positions, 1, 100)
	local v240_ = FieldCourseBoundary.getOffsetBoundaryLine(segment.positions, -sideOffset, 0.01)
	if v240_ ~= nil then
		FieldCourseUtil.extendSegment(v240_, -1, -100)
		FieldCourseUtil.extendSegment(v240_, 1, -100)
		if #v240_ >= 2 then
			segment.positions = v240_
			return true
		end
	end
	FieldCourseUtil.extendSegment(segment.positions, -1, -100)
	FieldCourseUtil.extendSegment(segment.positions, 1, -100)
	return false
end

-- Local values: segmentParts, i, segmentPart, length, p1, p2, length, isLoop
function FieldCourseBoundary.getOffsetBoundaryLine(boundaryLine, offset, minSegmentLength)
	local v244_ = {}
	for v245_ = 1, #boundaryLine - 1 do
		local v246_ = {
			["p1"] = boundaryLine[v245_],
			["p2"] = boundaryLine[v245_ + 1]
		}
		if (minSegmentLength or 0.001) < MathUtil.vector2Length(v246_.p2[1] - v246_.p1[1], v246_.p2[2] - v246_.p1[2]) then
			table.insert(v244_, v246_)
		end
	end
	local v247_ = boundaryLine[1]
	local v248_ = boundaryLine[#boundaryLine]
	local v249_ = MathUtil.vector2Length(v247_[1] - v248_[1], v247_[2] - v248_[2]) < 0.001
	if #v244_ < 1 then
		return nil
	else
		return FieldCourseBoundary.getOffsetBoundaryBySegmentParts(v244_, offset, v249_)
	end
end

-- Local values: connectSingleSegments, connectSegments, numSegmentParts, segmentIndex, segment, x1, z1, x2, z2, dirX1, dirZ1, reconnectionRequired, i, segmentPart, dirX1, dirZ1, dirX2, dirZ2, length, dot, i, numSegments, boundaryLine, segmentPartIndex, segmentPart
function FieldCourseBoundary.getOffsetBoundaryBySegmentParts(segmentParts, offset, isLoop)
	local function v_u_293_(p253_, p254_, p255_)
		local v256_ = p253_[p254_]
		local v257_ = p253_[p255_]
		if not v256_.connected then
			local v258_ = v256_.p2Offset[1] - v257_.p1Offset[1]
			if math.abs(v258_) < 0.01 then
				local v259_ = v256_.p2Offset[2] - v257_.p1Offset[2]
				if math.abs(v259_) < 0.01 then
					local v260_ = v256_.p2Offset
					local v261_ = v256_.p2Offset
					local v262_ = v257_.p1Offset[1]
					local v263_ = v257_.p1Offset[2]
					v260_[1] = v262_
					v261_[2] = v263_
					v256_.connected = true
				end
			end
		end
		if not v256_.connected then
			local v264_, v265_, v266_ = MathUtil.getLineSegmentsIntersection(v256_.p1Offset[1], v256_.p1Offset[2], v256_.p2Offset[1], v256_.p2Offset[2], v257_.p1Offset[1], v257_.p1Offset[2], v257_.p2Offset[1], v257_.p2Offset[2])
			if v264_ then
				local v267_ = v256_.p2Offset
				local v268_ = v256_.p2Offset
				v267_[1] = v265_
				v268_[2] = v266_
				local v269_ = v257_.p1Offset
				local v270_ = v257_.p1Offset
				v269_[1] = v265_
				v270_[2] = v266_
				v256_.connected = true
				return
			end
			local v271_ = v256_.p1Offset[1]
			local v272_ = v256_.p1Offset[2]
			local v273_ = v256_.p2Offset[1] - v256_.p1Offset[1]
			local v274_ = v256_.p2Offset[2] - v256_.p1Offset[2]
			local v275_ = MathUtil.vector2Length(v273_, v274_)
			if v275_ > 0 then
				local v276_ = v273_ / v275_
				local v277_ = v274_ / v275_
				local v278_ = v257_.p2Offset[1]
				local v279_ = v257_.p2Offset[2]
				local v280_ = v257_.p1Offset[1] - v257_.p2Offset[1]
				local v281_ = v257_.p1Offset[2] - v257_.p2Offset[2]
				local v282_ = MathUtil.vector2Length(v280_, v281_)
				if v282_ > 0 then
					local v283_ = v280_ / v282_
					local v284_ = v281_ / v282_
					local v285_, v286_, _ = MathUtil.getLineLineIntersection2D(v271_, v272_, v276_, v277_, v278_, v279_, v283_, v284_)
					if v285_ then
						local v287_ = v271_ + v276_ * v286_
						local v288_ = v272_ + v277_ * v286_
						local v289_ = v256_.p2Offset
						local v290_ = v256_.p2Offset
						v289_[1] = v287_
						v290_[2] = v288_
						local v291_ = v257_.p1Offset
						local v292_ = v257_.p1Offset
						v291_[1] = v287_
						v292_[2] = v288_
						v256_.connected = true
					end
				end
			end
		end
	end
	local function v305_()
		-- upvalues: (copy) segmentParts, (copy) isLoop, (copy) v_u_293_
		local v294_ = #segmentParts
		for v295_ = 1, v294_ do
			segmentParts[v295_].connected = false
		end
		local v296_ = v294_ + v294_ - 1
		local v297_
		if isLoop == false then
			v297_ = v294_ + 1
			v296_ = v294_ + v294_ - 2
		else
			v297_ = v294_
		end
		for v298_ = v297_, v296_ do
			v_u_293_(segmentParts, (v298_ - 1) % v294_ + 1, (v298_ + 1 - 1) % v294_ + 1)
		end
		for v299_ = v297_, v296_ do
			v_u_293_(segmentParts, (v299_ - 1) % v294_ + 1, (v299_ + 1 - 1) % v294_ + 1)
		end
		local v300_ = true
		for v301_ = 1, #segmentParts do
			local v302_ = segmentParts[v301_]
			if not v302_.connected and (isLoop ~= false or v301_ < #segmentParts - 1) then
				local v303_ = segmentParts[(v301_ + 1 - 1) % v294_ + 1]
				if MathUtil.vector2Length(v302_.p2Offset[1] - v302_.p1Offset[1], v302_.p2Offset[2] - v302_.p1Offset[2]) < MathUtil.vector2Length(v303_.p2Offset[1] - v303_.p1Offset[1], v303_.p2Offset[2] - v303_.p1Offset[2]) then
					v302_.pendingRemove = true
				else
					v303_.pendingRemove = true
				end
			end
		end
		for v304_ = v294_, 1, -1 do
			if segmentParts[v304_].pendingRemove then
				table.remove(segmentParts, v304_)
				v300_ = false
			end
		end
		return v300_ or #segmentParts == 0
	end
	for v306_ = 1, #segmentParts do
		local v307_ = segmentParts[v306_]
		local v308_ = v307_.p1[1]
		local v309_ = v307_.p1[2]
		local v310_ = v307_.p2[1]
		local v311_ = v307_.p2[2]
		local v312_, v313_ = MathUtil.vector2Normalize(v310_ - v308_, v311_ - v309_)
		v307_.p1Offset = { v307_.p1[1] - v313_ * offset, v307_.p1[2] + v312_ * offset }
		v307_.p2Offset = { v307_.p2[1] - v313_ * offset, v307_.p2[2] + v312_ * offset }
	end
	while not v305_() do

	end
	local v314_ = false
	for v315_ = #segmentParts, 1, -1 do
		local v316_ = segmentParts[v315_]
		if v316_.connected then
			local v317_, v318_ = MathUtil.vector2Normalize(v316_.p2[1] - v316_.p1[1], v316_.p2[2] - v316_.p1[2])
			local v319_ = v316_.p2Offset[1] - v316_.p1Offset[1]
			local v320_ = v316_.p2Offset[2] - v316_.p1Offset[2]
			local v321_ = MathUtil.vector2Length(v319_, v320_)
			if v321_ == 0 then
				table.remove(segmentParts, v315_)
				v314_ = true
			else
				local v322_ = v319_ / v321_
				local v323_ = v320_ / v321_
				if MathUtil.dotProduct(v317_, 0, v318_, v322_, 0, v323_) < 0 then
					table.remove(segmentParts, v315_)
					v314_ = true
				end
			end
		end
	end
	if v314_ then
		for v324_ = 1, #segmentParts do
			segmentParts[v324_].connected = false
		end
		while not v305_() do

		end
	end
	if isLoop == false then
		segmentParts[1].connected = true
		local v325_ = #segmentParts
		if v325_ > 1 then
			segmentParts[v325_ - 1].connected = true
			segmentParts[v325_].connected = true
		end
	end
	local v326_ = {}
	for v327_, v328_ in ipairs(segmentParts) do
		if v328_.connected then
			local v329_ = v328_.p1Offset
			table.insert(v326_, v329_)
			if isLoop == false and v327_ == #segmentParts then
				local v330_ = v328_.p2Offset
				table.insert(v326_, v330_)
			end
		end
	end
	return v326_
end

-- Local values: _, hitPoint, posIndex, p1, p2, sx, sz, ex, ez, dx, dz, length, dot, lx, lz, lengthLeft, p3, dx2, dz2, nextLength, lengthLeft, p0, dx2, dz2, prevLength, pendingPositionChanges, _, hitPoint, hx, hz, cx, cz, distanceToBoundary, debugCircle, i, p0, p1, p2, pdx, pdz, pdx1, pdz1, pdx2, pdz2, alpha, offset, index, positions, numPositions, x, z, max, i, dirX, dirZ, p, debugLine
function FieldCourseBoundary:adjustSegmentByHitPoints(hitPoints, segmentAdjustLength, offset)
	for _, v334_ in ipairs(hitPoints) do
		local v335_ = #self.boundaryLine - 1
		while true do
			local v336_ = self.boundaryLine[v335_]
			if v336_ == nil then
				break
			end
			local v337_ = self.boundaryLine[v335_ + 1]
			local v338_ = v336_[1]
			local v339_ = v336_[2]
			local v340_ = v337_[1]
			local v341_ = v337_[2]
			local v342_ = v340_ - v338_
			local v343_ = v341_ - v339_
			local v344_ = MathUtil.vector2Length(v342_, v343_)
			local v345_ = v342_ / v344_
			local v346_ = v343_ / v344_
			local v347_ = MathUtil.getProjectOnLineParameter(v334_[1], v334_[2], v336_[1], v336_[2], v345_, v346_)
			if v347_ >= 0 and v347_ <= v344_ then
				local v348_ = v336_[1] + v345_ * v347_
				local v349_ = v336_[2] + v346_ * v347_
				if MathUtil.vector2Length(v334_[1] - v348_, v334_[2] - v349_) < segmentAdjustLength * 2 then
					if v347_ < v344_ - segmentAdjustLength then
						local v350_ = self.boundaryLine
						local v351_ = v335_ + 1
						local v352_ = { v338_ + v345_ * (v347_ + segmentAdjustLength), v339_ + v346_ * (v347_ + segmentAdjustLength) }
						table.insert(v350_, v351_, v352_)
					else
						local v353_ = v344_ - v347_
						local v354_ = self.boundaryLine[v335_ + 2]
						if v354_ ~= nil then
							local v355_ = v354_[1] - v340_
							local v356_ = v354_[2] - v341_
							local v357_ = MathUtil.vector2Length(v355_, v356_)
							local v358_ = v355_ / v357_
							local v359_ = v356_ / v357_
							local v360_ = v357_ - 0.05
							local v361_ = math.min(v353_, v360_)
							local v362_ = self.boundaryLine
							local v363_ = v335_ + 2
							local v364_ = { v340_ + v358_ * v361_, v341_ + v359_ * v361_ }
							table.insert(v362_, v363_, v364_)
						end
					end
					local v365_ = self.boundaryLine
					local v366_ = v335_ + 1
					local v367_ = { v338_ + v345_ * v347_, v339_ + v346_ * v347_ }
					table.insert(v365_, v366_, v367_)
					if segmentAdjustLength < v347_ then
						local v368_ = self.boundaryLine
						local v369_ = v335_ + 1
						local v370_ = { v338_ + v345_ * (v347_ - segmentAdjustLength), v339_ + v346_ * (v347_ - segmentAdjustLength) }
						table.insert(v368_, v369_, v370_)
					else
						local v371_ = segmentAdjustLength - v347_
						local v372_ = self.boundaryLine[v335_ - 1]
						if v372_ ~= nil then
							local v373_ = v372_[1] - v338_
							local v374_ = v372_[2] - v339_
							local v375_ = MathUtil.vector2Length(v373_, v374_)
							local v376_ = v373_ / v375_
							local v377_ = v374_ / v375_
							local v378_ = v375_ - 0.05
							local v379_ = math.min(v371_, v378_)
							local v380_ = self.boundaryLine
							local v381_ = { v338_ + v376_ * v379_, v339_ + v377_ * v379_ }
							table.insert(v380_, v335_, v381_)
							v335_ = v335_ - 1
						end
					end
				end
			end
			v335_ = v335_ - 1
		end
		FieldCourseUtil.removeShortSegments(self.boundaryLine, 0.25)
	end
	FieldCourseUtil.removeShortSegments(self.boundaryLine, 0.25)
	local v382_ = {}
	for _, v383_ in ipairs(hitPoints) do
		local v384_ = v383_[1]
		local v385_ = v383_[2]
		local v386_, v387_ = FieldCourseUtil.getClosestPositionOnBoundary(v384_, v385_, self.boundaryLine)
		local v388_ = MathUtil.vector2Length(v386_ - v384_, v387_ - v385_)
		if FieldCourseUtil.getIsPointInsideBoundary(v384_, v385_, self.boundaryLine) then
			v388_ = -v388_
		end
		if VehicleDebug.state == VehicleDebug.DEBUG_AI then
			local v389_ = DebugCircle.new():createWithWorldPos(v386_, 0, v387_, self.segmentCollisionCheckSafetyOffset, nil, 25, false, true, false, false)
			g_debugManager:addElement(v389_, nil, math.huge, math.huge)
		end
		for v390_ = 1, #self.boundaryLine do
			local v391_ = self.boundaryLine[v390_ - 1]
			local v392_ = self.boundaryLine[v390_]
			local v393_ = self.boundaryLine[v390_ + 1]
			local v394_ = nil
			local v395_ = nil
			if v391_ == nil or v393_ == nil then
				if v391_ == nil then
					if v393_ ~= nil then
						v394_, v395_ = MathUtil.vector2Normalize(v393_[1] - v392_[1], v393_[2] - v392_[2])
					end
				else
					v394_, v395_ = MathUtil.vector2Normalize(v392_[1] - v391_[1], v392_[2] - v391_[2])
				end
			else
				local v396_, v397_ = MathUtil.vector2Normalize(v392_[1] - v391_[1], v392_[2] - v391_[2])
				local v398_, v399_ = MathUtil.vector2Normalize(v393_[1] - v392_[1], v393_[2] - v392_[2])
				v394_, v395_ = MathUtil.vector2Normalize(v396_ + v398_, v397_ + v399_)
			end
			local v400_ = MathUtil.vector2Length(v392_[1] - v386_, v392_[2] - v387_) / 5
			local v401_ = 1 - math.min(v400_, 1)
			if v401_ > 0 then
				local v402_ = v401_ * 1.5
				local v403_ = math.min(v402_, 1)
				local v404_ = self.segmentCollisionCheckSafetyOffset + 1 - v388_
				local v405_ = math.max(v404_, 0.5) * v403_
				if v405_ > 0 then
					if v382_[v390_] == nil then
						v382_[v390_] = {}
					end
					local v406_ = v382_[v390_]
					local v407_ = { -v395_ * v405_, v394_ * v405_ }
					table.insert(v406_, v407_)
				end
			end
		end
	end
	for v408_, v409_ in pairs(v382_) do
		local v410_ = #v409_
		local v411_ = 0
		local v412_ = 0
		local v413_ = 0
		for v414_ = 1, v410_ do
			v411_ = v411_ + v409_[v414_][1]
			v412_ = v412_ + v409_[v414_][2]
			local v415_ = MathUtil.vector2Length
			local v416_ = v409_[v414_][1]
			local v417_ = v409_[v414_][2]
			v413_ = math.max(v413_, v415_(v416_, v417_))
		end
		local v418_ = v411_ / v410_
		local v419_ = v412_ / v410_
		local v420_, v421_ = MathUtil.vector2Normalize(v418_, v419_)
		local v422_ = self.boundaryLine[v408_]
		if VehicleDebug.state == VehicleDebug.DEBUG_AI then
			local v423_ = DebugLine.new():createWithStartAndEndPos(v422_[1], 0, v422_[2], v422_[1] + v420_ * v413_, 0, v422_[2] + v421_ * v413_, true, true)
			g_debugManager:addElement(v423_, nil, math.huge, math.huge)
		end
		local v424_ = v422_[1] + v420_ * v413_
		local v425_ = v422_[2] + v421_ * v413_
		v422_[1] = v424_
		v422_[2] = v425_
	end
	self.boundaryLine[1] = table.clone(self.boundaryLine[#self.boundaryLine])
	FieldCourseUtil.removeShortSegments(self.boundaryLine, 0.25)
	FieldCourseUtil.douglasPeucker(self.boundaryLine, 1)
end

-- Local values: object, x, _, z, debugCircle, numHitPoints
function FieldCourseBoundary:segmentCollisionOverlapCallback(nodeId, subShapeIndex, isLast)
	if nodeId ~= 0 then
		local v429_ = g_currentMission:getNodeObject(nodeId)
		if v429_ == nil or v429_.spec_vine == nil then
			local v430_, _, v431_ = getWorldTranslation(nodeId)
			local v432_ = self.segmentCollisionCheckHitPoints
			table.insert(v432_, { v430_, v431_ })
			if VehicleDebug.state == VehicleDebug.DEBUG_AI then
				local v433_ = DebugCircle.new():createWithWorldPos(v430_, 0, v431_, self.segmentCollisionCheckSafetyOffset, nil, 25, false, true, false, false)
				v433_.text = "obstacle: " .. getName(nodeId)
				g_debugManager:addElement(v433_, nil, math.huge, math.huge)
			end
		end
	end
	if isLast then
		self.segmentCollisionCheckNumOverlapChecks = self.segmentCollisionCheckNumOverlapChecks - 1
		if self.segmentCollisionCheckNumOverlapChecks <= 0 then
			local v434_ = #self.segmentCollisionCheckHitPoints
			if v434_ > 0 then
				self:adjustSegmentByHitPoints(self.segmentCollisionCheckHitPoints, 15, 4)
			end
			self.segmentCollisionCheckCallback(v434_ > 0)
		end
	end
	return true
end

-- Local values: i, p1, p2, dx, dz, length, rotY, y1, y2, rotX, rotZ, sx, sy, sz, bx, by, bz
function FieldCourseBoundary:segmentCollisionOffset(testWidth, safetyOffset, callback)
	self.segmentCollisionCheckCallback = callback
	self.segmentCollisionCheckFinished = false
	self.segmentCollisionCheckSafetyOffset = safetyOffset
	self.segmentCollisionCheckHitPoints = {}
	self.segmentCollisionCheckNumOverlapChecks = #self.boundaryLine - 1
	for v439_ = 1, #self.boundaryLine - 1 do
		local v440_ = self.boundaryLine[v439_]
		local v441_ = self.boundaryLine[v439_ + 1]
		local v442_ = v441_[1] - v440_[1]
		local v443_ = v441_[2] - v440_[2]
		local v444_ = MathUtil.vector2Length(v442_, v443_)
		local v445_ = v442_ / v444_
		local v446_ = v443_ / v444_
		local v447_ = MathUtil.getYRotationFromDirection(v445_, v446_)
		local v448_ = getTerrainHeightAtWorldPos(g_terrainNode, v440_[1], 0, v440_[2])
		local v449_ = getTerrainHeightAtWorldPos(g_terrainNode, v441_[1], 0, v441_[2])
		local v450_ = (v449_ - v448_) / v444_
		local v451_ = -math.atan(v450_)
		local v452_ = testWidth + safetyOffset
		local v453_ = (v440_[1] + v441_[1]) * 0.5
		local v454_ = (v448_ + v449_) * 0.5 + 2
		local v455_ = (v440_[2] + v441_[2]) * 0.5
		local v456_ = v453_ - v446_ * (testWidth - safetyOffset) * 0.5
		local v457_ = v455_ + v445_ * (testWidth - safetyOffset) * 0.5
		overlapBoxAsync(v456_, v454_, v457_, v451_, v447_, 0, v452_ * 0.5, 2, v444_ * 0.5, "segmentCollisionOverlapCallback", self, CollisionFlag.AI_BLOCKING, false, false, true, true)
	end
end

-- Local values: _
function FieldCourseBoundary:regenerateSegments()
	local v459_, _ = FieldCourseBoundary.generateSegmentsByBoundaryLine(self.boundaryLine)
	self.segments = v459_
end

-- Local values: numPositions, numChecks, i, pos3, pos4, dir2X, dir2Z, segmentLength
function FieldCourseBoundary.getBoundaryOffsetPosition(positions, index, length, direction, isLoop)
	local v465_ = #positions
	local v466_
	if isLoop then
		v466_ = v465_
	elseif direction > 0 then
		v466_ = v465_ - index
	else
		v466_ = index - 1
	end
	for v467_ = 0, v466_ - 1 do
		local v468_, v469_
		if direction > 0 then
			v468_ = positions[(index + v467_ - 1) % v465_ + 1]
			v469_ = positions[(index + v467_ + 1 - 1) % v465_ + 1]
		else
			v468_ = positions[(index - v467_ - 1) % v465_ + 1]
			v469_ = positions[(index - v467_ - 1 - 1) % v465_ + 1]
		end
		local v470_ = v469_[1] - v468_[1]
		local v471_ = v469_[2] - v468_[2]
		local v472_ = MathUtil.vector2Length(v470_, v471_)
		if length < v472_ or v467_ == v466_ - 1 then
			local v473_ = v470_ / v472_
			local v474_ = v471_ / v472_
			local v475_ = math.min(length, v472_)
			return v468_[1] + v473_ * v475_, v468_[2] + v474_ * v475_
		end
		length = length - v472_
	end
	return positions[index][1], positions[index][2]
end

-- Local values: maxAngle, maxAngleIndex, numPositions, min, max, i, x1, z1, p2, x2, z2, x3, z3, dirX1, dirZ1, length1, dirX2, dirZ2, length2, angle
function FieldCourseBoundary.getSegmentAngle(positions, excludeIndex, isLoop)
	local v479_ = 0
	local v480_ = -1
	local v481_ = #positions
	local v482_ = v481_ + 1
	local v483_
	if isLoop then
		v483_ = 0
	else
		v482_ = v481_ - 1
		v483_ = 2
	end
	for v484_ = v483_, v482_ do
		local v485_, v486_ = FieldCourseBoundary.getBoundaryOffsetPosition(positions, v484_, 2, -1, isLoop)
		local v487_ = positions[(v484_ - 1) % v481_ + 1]
		local v488_ = v487_[1]
		local v489_ = v487_[2]
		local v490_, v491_ = FieldCourseBoundary.getBoundaryOffsetPosition(positions, v484_, 2, 1, isLoop)
		local v492_ = v488_ - v485_
		local v493_ = v489_ - v486_
		local v494_ = MathUtil.vector2Length(v492_, v493_)
		local v495_ = v490_ - v488_
		local v496_ = v491_ - v489_
		local v497_ = MathUtil.vector2Length(v495_, v496_)
		if v494_ > 0 and v497_ > 0 then
			local v498_ = v492_ / v494_
			local v499_ = v493_ / v494_
			local v500_ = v495_ / v497_
			local v501_ = v496_ / v497_
			local v502_ = FieldCourseUtil.vector2Dot(v498_, v499_, v500_, v501_)
			local v503_ = math.acos(v502_)
			if v479_ < v503_ and (excludeIndex == nil or (v484_ - 1) % v481_ + 1 ~= excludeIndex) then
				v480_ = (v484_ - 1) % v481_ + 1
				v479_ = v503_
			end
		end
	end
	return v479_, v480_
end

-- Local values: maxAngle, maxAngleIndex, numPositions, segment1, i, pos, segment2, i
function FieldCourseBoundary.splitBoundarySegment(positions, splitAngle)
	local v506_, v507_ = FieldCourseBoundary.getSegmentAngle(positions, nil, false)
	if v507_ == -1 or splitAngle >= v506_ then
		return positions, nil
	end
	local v508_ = #positions
	local v509_ = {}
	for v510_ = 1, v507_ do
		local v511_ = positions[v510_]
		if v510_ == v507_ then
			v511_ = table.clone(v511_)
		end
		table.insert(v509_, v511_)
	end
	local v512_ = {}
	for v513_ = v507_, v508_ do
		local v514_ = positions[v513_]
		table.insert(v512_, v514_)
	end
	return v509_, v512_
end

-- Local values: segmentsSplit, i, segment, segment1, segment2
function FieldCourseBoundary.splitBoundarySegments(segments, splitAngle)
	local v517_ = false
	for v518_ = #segments, 1, -1 do
		local v519_ = segments[v518_]
		local v520_, v521_ = FieldCourseBoundary.splitBoundarySegment(v519_, splitAngle)
		if v521_ ~= nil then
			table.remove(segments, v518_)
			table.insert(segments, v518_, v521_)
			table.insert(segments, v518_, v520_)
			v517_ = true
		end
	end
	return v517_
end

-- Local values: _, maxAngleIndex1, _, maxAngleIndex2, segments, numPositions, segment1, i, pos, segment2, i, pos
function FieldCourseBoundary.splitBoundary(positions, splitAngle)
	local v524_ = table.clone(positions, math.huge)
	table.remove(v524_, #v524_)
	local _, v525_ = FieldCourseBoundary.getSegmentAngle(v524_, nil, true)
	local _, v526_ = FieldCourseBoundary.getSegmentAngle(v524_, v525_, true)
	if v525_ == -1 or v526_ == -1 then
		return nil
	end
	if v526_ >= v525_ then
		local v527_ = v525_
		v525_ = v526_
		v526_ = v527_
	end
	local v528_ = #v524_
	local v529_ = {}
	local v530_ = {}
	for v531_ = v526_, v525_ do
		local v532_ = v524_[(v531_ - 1) % v528_ + 1]
		if (v531_ - 1) % v528_ + 1 == v525_ then
			v532_ = table.clone(v532_)
		end
		table.insert(v529_, v532_)
	end
	table.insert(v530_, v529_)
	local v533_ = {}
	for v534_ = v525_, v528_ + v526_ do
		local v535_ = v524_[(v534_ - 1) % v528_ + 1]
		if (v534_ - 1) % v528_ + 1 == v526_ then
			v535_ = table.clone(v535_)
		end
		table.insert(v533_, v535_)
	end
	table.insert(v530_, v533_)
	while FieldCourseBoundary.splitBoundarySegments(v530_, splitAngle) do

	end
	return v530_
end

-- Local values: boundary
function FieldCourseBoundary.extendBoundaryLine(boundaryLine, offset)
	local v538_ = FieldCourseBoundary.createByBoundaryLine(boundaryLine, nil)
	if v538_ ~= nil then
		local v539_ = v538_:extend(offset)
		if v539_ ~= nil then
			return v539_.boundaryLine
		end
	end
	return nil
end
