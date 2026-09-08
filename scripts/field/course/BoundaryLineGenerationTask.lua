-- Local values: BoundaryLineGenerationTask_mt
BoundaryLineGenerationTask = {}
local BoundaryLineGenerationTask_mt = Class(BoundaryLineGenerationTask)

-- Upvalues: BoundaryLineGenerationTask_mt
-- Local values: self, forceStraightLines, yRot, snapAngle, refX, refZ, intersect, t1, _, roundedT1, offset, maxFactor, _, segment, maxAngle, angleSum, length, anglePerMeter, factor, p1, p2, sdx, sdz, edx, edz
function BoundaryLineGenerationTask.new(boundaryLine, sx, sz, dirX, dirZ, islands, fieldCourseSettings, callback)
	-- upvalues: (copy) BoundaryLineGenerationTask_mt
	local v10_ = BoundaryLineGenerationTask_mt
	local v11_ = setmetatable({}, v10_)
	local v12_
	if fieldCourseSettings.workDirection >= 0 then
		dirX, dirZ = MathUtil.getDirectionFromYRotation(fieldCourseSettings.workDirection)
		v12_ = true
	else
		v12_ = false
	end
	if fieldCourseSettings.rowSpacing ~= 0 and fieldCourseSettings.workDirection < 0 then
		local v13_ = MathUtil.getYRotationFromDirection(dirX, dirZ)
		local v14_ = fieldCourseSettings.rowSnapAngle
		if v14_ == 0 then
			v14_ = g_currentMission.fieldGroundSystem:getGroundAngleStep()
		end
		if v14_ > 0 then
			local v15_ = MathUtil.round(v13_ / v14_) * v14_
			dirX, dirZ = MathUtil.getDirectionFromYRotation(v15_)
			v12_ = true
		end
	end
	local v16_, v17_, v18_, v19_, v20_ = BoundaryLineGenerationTask.getFurthestPointToLine(sx, sz, dirX, dirZ, boundaryLine)
	v11_.sx = v16_
	v11_.sz = v17_
	v11_.offsetDirX = v18_
	v11_.offsetDirZ = v19_
	v11_.distanceToCheck = v20_
	if v11_.sx == nil then
		return nil
	end
	if fieldCourseSettings.rowSpacing ~= 0 then
		local v21_ = -g_currentMission.terrainSize * 0.5
		local v22_ = -g_currentMission.terrainSize * 0.5
		local v23_, v24_, _ = MathUtil.getLineLineIntersection2D(v11_.sx, v11_.sz, v11_.offsetDirX, v11_.offsetDirZ, v21_, v22_, dirX, dirZ)
		if v23_ then
			local v25_ = MathUtil.round(v24_ / fieldCourseSettings.rowSpacing) * fieldCourseSettings.rowSpacing - v24_
			if MathUtil.round(fieldCourseSettings.implementWidth / fieldCourseSettings.rowSpacing) % 2 ~= 0 then
				v25_ = v25_ + fieldCourseSettings.rowSpacing * 0.5
			end
			local v26_ = v25_ + fieldCourseSettings.rowOffset
			local v27_ = v11_.sx - v11_.offsetDirX * v26_
			local v28_ = v11_.sz - v11_.offsetDirZ * v26_
			v11_.sx = v27_
			v11_.sz = v28_
		end
	end
	local v29_ = fieldCourseSettings.segmentSplitAngle
	v11_.segmentSplitAngle = math.rad(v29_)
	v11_.boundary = FieldCourseBoundary.createByBoundaryLine(boundaryLine, v11_.segmentSplitAngle)
	if v11_.boundary == nil then
		Logging.warning("BoundaryLineGenerationTask: Failed to create boundary from boundary line")
		return nil
	end
	v11_.boundaryLine = v11_.boundary.boundaryLine
	v11_.dirX = dirX
	v11_.dirZ = dirZ
	v11_.islands = islands
	v11_.lineToLineDistance = fieldCourseSettings.implementWidth
	v11_.segmentMinOffset = fieldCourseSettings.segmentMinOffset or 0
	v11_.segmentMinLength = fieldCourseSettings.segmentMinLength or 0
	v11_.callback = callback
	local v30_ = v11_.sx + v11_.offsetDirX * v11_.lineToLineDistance * 0.5
	local v31_ = v11_.sz + v11_.offsetDirZ * v11_.lineToLineDistance * 0.5
	v11_.curX = v30_
	v11_.curZ = v31_
	v11_.hasFinished = false
	local v32_ = 0
	v11_.rootSegment = nil
	if not v12_ then
		for _, v33_ in ipairs(v11_.boundary.segments) do
			local v34_, v35_ = BoundaryLineGenerationTask.getSegmentsAngleData(v33_.positions)
			if v34_ < v11_.segmentSplitAngle then
				local v36_ = FieldCourseUtil.getSegmentLength(v33_.positions)
				local v37_ = v35_ / v36_ / 0.005
				local v38_ = v36_ * (1 - math.min(v37_, 1) * 0.66)
				if v32_ < v38_ then
					v11_.rootSegment = v33_
					v32_ = v38_
				end
			end
		end
	end
	v11_.detectStraightLines = true
	v11_.offsetLineIndex = 0
	v11_.straightLines = {}
	v11_.contourLines = {}
	if v11_.rootSegment ~= nil then
		v11_.detectStraightLines = false
		v11_.lastContourLine = v11_.rootSegment.positions
		local v39_ = v11_.lastContourLine[1]
		local v40_ = v11_.lastContourLine[2]
		local v41_, v42_ = MathUtil.vector2Normalize(v39_[1] - v40_[1], v39_[2] - v40_[2])
		local v43_ = v39_[1] + v41_ * 65535
		local v44_ = v39_[2] + v42_ * 65535
		v39_[1] = v43_
		v39_[2] = v44_
		local v45_ = v11_.lastContourLine[#v11_.lastContourLine]
		local v46_ = v11_.lastContourLine[#v11_.lastContourLine - 1]
		local v47_, v48_ = MathUtil.vector2Normalize(v45_[1] - v46_[1], v45_[2] - v46_[2])
		local v49_ = v45_[1] + v47_ * 65535
		local v50_ = v45_[2] + v48_ * 65535
		v45_[1] = v49_
		v45_[2] = v50_
		v11_.contourExtensionDirection = 1
	end
	return v11_
end

-- Local values: startTime, continueGeneration, success, continueGeneration, success, dirX, dirZ, startTime, lines, numContourLines, numStraightLines, i, line
function BoundaryLineGenerationTask:update(dt, frameBudget)
	if self.detectStraightLines then
		local v53_ = self.dirX
		local v54_ = self.dirZ
		local v55_ = getTimeSec()
		while getTimeSec() - v55_ < frameBudget do
			self.offsetLineIndex = self.offsetLineIndex + 1
			BoundaryLineGenerationTask.detectInsideBoundaryLines(self.straightLines, self.curX, self.curZ, v53_, v54_, self.boundaryLine, self.islands, self.offsetLineIndex)
			local v56_ = self.curX + self.offsetDirX * self.lineToLineDistance
			local v57_ = self.curZ + self.offsetDirZ * self.lineToLineDistance
			self.curX = v56_
			self.curZ = v57_
			self.distanceToCheck = self.distanceToCheck - self.lineToLineDistance
			if self.distanceToCheck <= 0 then
				self.hasFinished = true
				local v58_ = self.straightLines
				if self.contourLines ~= nil then
					local v59_ = #self.contourLines
					local v60_ = #self.straightLines
					if v59_ > 0 then
						local v61_ = v59_ - v60_
						local v62_ = v60_ * 0.15
						if v61_ <= math.max(v62_, 1) then
							v58_ = self.contourLines
						end
					end
				end
				if self.segmentMinOffset > 0 then
					BoundaryLineGenerationTask.removeMinOffsetLines(v58_, self.boundaryLine, self.segmentMinOffset)
				end
				if self.segmentMinLength > 0 then
					for v63_ = #v58_, 1, -1 do
						local v64_ = v58_[v63_]
						if FieldCourseUtil.getSegmentLength(v64_.positions) < self.segmentMinLength then
							table.remove(v58_, v63_)
						end
					end
				end
				if self.callback ~= nil then
					self.callback(v58_)
				end
				break
			end
		end
	else
		local v65_ = getTimeSec()
		while getTimeSec() - v65_ < frameBudget do
			if self.contourExtensionDirection == 1 then
				if #self.contourLines == 0 then
					self:extendContourLine(0.01, self.offsetLineIndex)
					self.initialContourLine = self.contourLines[1]
				end
				self.offsetLineIndex = self.offsetLineIndex + 1
				local v66_, v67_ = self:extendContourLine(self.lineToLineDistance, self.offsetLineIndex)
				if self.initialContourLine ~= nil then
					table.remove(self.contourLines, 1)
					self.initialContourLine = nil
				end
				if not v66_ then
					if not v67_ then
						self.detectStraightLines = true
						self.contourLines = nil
						break
					end
					self:extendContourLine(0.5, self.offsetLineIndex)
					self.lastContourLine = self.rootSegment.positions
					self.contourExtensionDirection = -1
					self.offsetLineIndex = 0
					self:extendContourLine(-0.01, self.offsetLineIndex)
				end
			else
				self.offsetLineIndex = self.offsetLineIndex - 1
				local v68_, v69_ = self:extendContourLine(-self.lineToLineDistance, self.offsetLineIndex)
				if not v68_ then
					if not v69_ then
						self.contourLines = nil
					end
					self.detectStraightLines = true
					self.offsetLineIndex = 0
					break
				end
			end
		end
	end
	return not self.hasFinished
end

-- Local values: contourLine, maxAngle, _, continueGeneration
function BoundaryLineGenerationTask:extendContourLine(lineToLineDistance, offsetLineIndex)
	local v73_ = FieldCourseBoundary.getOffsetBoundaryLine(self.lastContourLine, lineToLineDistance, 0.25)
	if v73_ == nil then
		return false, false
	end
	FieldCourseUtil.removeShortSegments(v73_, 0.25)
	FieldCourseUtil.douglasPeucker(v73_, 0.25)
	if not FieldCourseBoundary.resolveSelfIntersections(v73_) then
		return false, false
	end
	if FieldCourseUtil.getSegmentLength(v73_) < 0.25 then
		return false, true
	end
	local v74_, _ = BoundaryLineGenerationTask.getSegmentsAngleData(v73_)
	if self.segmentSplitAngle < v74_ then
		return false, false
	end
	FieldCourseUtil.douglasPeucker(v73_, 0.25)
	self.lastContourLine = v73_
	return BoundaryLineGenerationTask.resolveBoundaryIntersections(self.contourLines, v73_, self.boundaryLine, self.islands, offsetLineIndex), true
end

-- Local values: offset, minDistance, minDistancePoint, maxDistance, maxDistancePoint, offsetDirX, offsetDirZ, i, x1, z1, x2, z2, distance, distance
function BoundaryLineGenerationTask.getFurthestPointToLine(x, z, dirX, dirZ, boundary)
	local v80_ = x - dirZ * 4096
	local v81_ = z + dirX * 4096
	local v82_ = 0
	local v83_ = math.huge
	local v84_ = 0
	local v85_ = 0
	local v86_ = nil
	local v87_ = nil
	for v88_ = 1, #boundary do
		local v89_ = boundary[v88_][1]
		local v90_ = boundary[v88_][2]
		local v91_, v92_ = MathUtil.projectOnLine(v89_, v90_, v80_, v81_, dirX, dirZ)
		local v93_ = MathUtil.vector2Length(v91_ - v89_, v92_ - v90_)
		if v82_ < v93_ then
			v86_ = (v91_ - v89_) / v93_
			v87_ = (v92_ - v90_) / v93_
			v85_ = v88_
			v82_ = v93_
		end
		if v93_ < v83_ then
			v84_ = v88_
			v83_ = v93_
		end
	end
	if v84_ <= 0 or v85_ <= 0 then
		return nil
	end
	local v94_ = v82_ - v83_
	return boundary[v85_][1], boundary[v85_][2], v86_, v87_, v94_
end

-- Local values: intersections, sx, sz, ex, ez, i, intersect, ix, iz, _, island, innerBoundary, innerBoundaryLine, i, intersect, ix, iz, numIntersections, foundIntersections, i, line
function BoundaryLineGenerationTask.detectInsideBoundaryLines(lines, x, z, dirX, dirZ, boundary, islands, offsetLineIndex)
	local v103_ = x - dirX * 65535
	local v104_ = z - dirZ * 65535
	local v105_ = x + dirX * 65535
	local v106_ = z + dirZ * 65535
	local v107_ = {}
	for v108_ = 1, #boundary - 1 do
		local v109_, v110_, v111_ = MathUtil.getLineSegmentsIntersection(boundary[v108_][1], boundary[v108_][2], boundary[v108_ + 1][1], boundary[v108_ + 1][2], v103_, v104_, v105_, v106_)
		if v109_ then
			table.insert(v107_, { v110_, v111_ })
		end
	end
	for _, v112_ in ipairs(islands) do
		local v113_ = (v112_.boundaries[#v112_.boundaries] or v112_.innerBoundary).boundaryLine
		for v114_ = 1, #v113_ - 1 do
			local v115_, v116_, v117_ = MathUtil.getLineSegmentsIntersection(v113_[v114_][1], v113_[v114_][2], v113_[v114_ + 1][1], v113_[v114_ + 1][2], v103_, v104_, v105_, v106_)
			if v115_ then
				if FieldCourseUtil.getIsPointInsideBoundary(v116_, v117_, boundary) then
					table.insert(v107_, { v116_, v117_ })
				else
					table.insert(v107_, { v116_, v117_, true })
				end
			end
		end
	end
	table.sort(v107_, function(p118_, p119_)
		return p118_[1] + p118_[2] < p119_[1] + p119_[2]
	end)
	local v120_ = #v107_
	if v120_ % 2 ~= 0 then
		return false
	end
	local v121_ = false
	for v122_ = 1, v120_ - 1, 2 do
		if v107_[v122_][3] ~= true and v107_[v122_ + 1][3] ~= true then
			local v123_ = {
				["offsetLineIndex"] = offsetLineIndex,
				["positions"] = { v107_[v122_], v107_[v122_ + 1] }
			}
			table.insert(lines, v123_)
			v121_ = true
		end
	end
	return v121_
end

-- Local values: i, line, isIntersecting, j, p1, p2, dx, dz, offset, cx, cz, intersect, _, _
function BoundaryLineGenerationTask.removeMinOffsetLines(lines, boundary, minOffset)
	for v127_ = #lines, 1, -1 do
		local v128_ = lines[v127_]
		local v129_ = true
		for v130_ = 1, #v128_.positions - 1 do
			local v131_ = v128_.positions[v130_]
			local v132_ = v128_.positions[v130_ + 1]
			local v133_, v134_ = MathUtil.vector2Normalize(v132_[1] - v131_[1], v132_[2] - v131_[2])
			for v135_ = 0.25, 0.75, 0.25 do
				local v136_ = MathUtil.lerp(v131_[1], v132_[1], v135_)
				local v137_ = MathUtil.lerp(v131_[2], v132_[2], v135_)
				local v138_, _, _ = FieldCourseUtil.getSegmentBoundaryIntersection(v136_ + v134_ * minOffset, v137_ - v133_ * minOffset, v136_ - v134_ * minOffset, v137_ + v133_ * minOffset, boundary)
				if not v138_ then
					v129_ = false
					break
				end
			end
			if not v129_ then
				break
			end
		end
		if v129_ then
			table.remove(lines, v127_)
		end
	end
end

-- Local values: numIntersections, sx, sz, ex, ez, i, intersect, _, _
function BoundaryLineGenerationTask.getNumBoundaryLines(x, z, dirX, dirZ, boundary)
	local v144_ = x - dirX * 65535
	local v145_ = z - dirZ * 65535
	local v146_ = x + dirX * 65535
	local v147_ = z + dirZ * 65535
	local v148_ = 0
	for v149_ = 1, #boundary - 1 do
		local v150_, _, _ = MathUtil.getLineSegmentsIntersection(boundary[v149_][1], boundary[v149_][2], boundary[v149_ + 1][1], boundary[v149_ + 1][2], v144_, v145_, v146_, v147_)
		if v150_ then
			v148_ = v148_ + 1
		end
	end
	return v148_ % 2 ~= 0 and 0 or v148_ / 2
end

-- Local values: minLineAmount, minLineAngle, angle, numLines
function BoundaryLineGenerationTask.getOptimalBoundaryAngle(centerX, centerZ, boundary, steps)
	local v155_ = math.huge
	local v156_ = 0
	for v157_ = 0, 3.1315926535897933, 3.141592653589793 / steps do
		local v158_ = BoundaryLineGenerationTask.getNumLinesByAngle(centerX, centerZ, boundary, v157_)
		if v158_ < v155_ then
			v156_ = v157_
			v155_ = v158_
		end
	end
	return v156_
end

-- Local values: dirX, dirZ, sx, sz, offsetDirX, offsetDirZ, distance, offset, numLines, newLines
function BoundaryLineGenerationTask.getNumLinesByAngle(centerX, centerZ, boundary, angle)
	local v163_, v164_ = MathUtil.getDirectionFromYRotation(angle)
	local v165_, v166_, v167_, v168_, v169_ = BoundaryLineGenerationTask.getFurthestPointToLine(centerX, centerZ, v163_, v164_, boundary, true)
	if v165_ == nil then
		return 0
	end
	local v170_ = v165_ + v167_ * 0.1
	local v171_ = v166_ + v168_ * 0.1
	local v172_ = 0
	while true do
		v170_ = v170_ + v167_ * 10
		v171_ = v171_ + v168_ * 10
		local v173_ = BoundaryLineGenerationTask.getNumBoundaryLines(v170_, v171_, v163_, v164_, boundary)
		if v173_ > 0 then
			v172_ = v172_ + v173_
		end
		v169_ = v169_ - 10
		if v169_ <= 0 then
			return v172_
		end
	end
end

-- Local values: isValid, remainingLine, i, p1, p2, dx, dz, intersect, ix1, iz1, edx, edz, intersect, ix2, iz2, hitIndex, j, sp1, sp2, newLine, indexToAdd, i
function BoundaryLineGenerationTask.resolveBoundaryIntersections(lines, line, boundary, islands, offsetLineIndex)
	local v179_ = false
	local v180_ = nil
	for v181_ = 1, #line - 1 do
		local v182_ = line[v181_]
		local v183_ = line[v181_ + 1]
		local v184_, v185_ = MathUtil.vector2Normalize(v183_[1] - v182_[1], v183_[2] - v182_[2])
		local v186_, v187_, v188_ = BoundaryLineGenerationTask.getSegmentClosestBoundaryOrIslandsIntersection(v182_[1], v182_[2], v183_[1], v183_[2], boundary, islands)
		if v186_ then
			local v189_, v190_, v191_ = BoundaryLineGenerationTask.getSegmentClosestBoundaryOrIslandsIntersection(v187_ + v184_ * 0.0001, v188_ + v185_ * 0.0001, v183_[1], v183_[2], boundary, islands)
			local v192_, v193_, v194_
			if v189_ then
				v192_ = v184_
				v193_ = v185_
				v194_ = v181_
			else
				v192_ = v184_
				v193_ = v185_
				v194_ = v181_
				for v195_ = v181_ + 1, #line - 1 do
					local v196_ = line[v195_]
					local v197_ = line[v195_ + 1]
					v184_, v193_ = MathUtil.vector2Normalize(v197_[1] - v196_[1], v197_[2] - v196_[2])
					v189_, v190_, v191_ = BoundaryLineGenerationTask.getSegmentClosestBoundaryOrIslandsIntersection(v196_[1], v196_[2], v197_[1], v197_[2], boundary, islands)
					if v189_ then
						v194_ = v195_
						break
					end
				end
			end
			if v189_ then
				local v198_ = {
					["offsetLineIndex"] = offsetLineIndex,
					["positions"] = {}
				}
				local v199_ = v198_.positions
				local v200_ = { v187_ + v192_ * 0.0001, v188_ + v185_ * 0.0001 }
				table.insert(v199_, v200_)
				for v201_ = v181_ + 1, v194_ do
					local v202_ = v198_.positions
					local v203_ = line[v201_]
					table.insert(v202_, v203_)
				end
				local v204_ = v198_.positions
				local v205_ = { v190_ - v184_ * 0.0001, v191_ - v193_ * 0.0001 }
				table.insert(v204_, v205_)
				table.insert(lines, v198_)
				v179_ = true
				if #line - v194_ > 0 then
					v180_ = {}
					local v206_ = { v190_ + v184_ * 0.0001, v191_ + v193_ * 0.0001 }
					table.insert(v180_, v206_)
					for v207_ = v194_ + 1, #line do
						local v208_ = line[v207_]
						table.insert(v180_, v208_)
					end
				end
			end
		end
	end
	if v179_ and v180_ ~= nil then
		BoundaryLineGenerationTask.resolveBoundaryIntersections(lines, v180_, boundary, islands, offsetLineIndex)
	end
	return v179_
end

-- Local values: minDistance, ix, iz, psx, psz, pex, pez, i, sx, sz, ex, ez, intersect, x, z, distance, _, island, innerBoundary, innerBoundaryLine, i, sx, sz, ex, ez, intersect, x, z, distance
function BoundaryLineGenerationTask.getSegmentClosestBoundaryOrIslandsIntersection(l1x, l1z, l2x, l2z, boundary, islands)
	local v215_ = math.huge
	local v216_ = nil
	local v217_ = nil
	local v218_ = nil
	local v219_ = nil
	local v220_ = nil
	local v221_ = nil
	for v222_ = 1, #boundary - 1 do
		local v223_ = boundary[v222_][1]
		local v224_ = boundary[v222_][2]
		local v225_ = boundary[v222_ + 1][1]
		local v226_ = boundary[v222_ + 1][2]
		local v227_, v228_, v229_ = MathUtil.getLineSegmentsIntersection(v223_, v224_, v225_, v226_, l1x, l1z, l2x, l2z)
		if v227_ then
			local v230_ = MathUtil.vector2Length(l1x - v228_, l1z - v229_)
			if v230_ < v215_ then
				v221_ = v226_
				v220_ = v225_
				v219_ = v224_
				v218_ = v223_
				v217_ = v229_
				v216_ = v228_
				v215_ = v230_
			end
		end
	end
	for _, v231_ in ipairs(islands) do
		local v232_ = (v231_.boundaries[#v231_.boundaries] or v231_.innerBoundary).boundaryLine
		for v233_ = 1, #v232_ - 1 do
			local v234_ = v232_[v233_][1]
			local v235_ = v232_[v233_][2]
			local v236_ = v232_[v233_ + 1][1]
			local v237_ = v232_[v233_ + 1][2]
			local v238_, v239_, v240_ = MathUtil.getLineSegmentsIntersection(v234_, v235_, v236_, v237_, l1x, l1z, l2x, l2z)
			if v238_ then
				local v241_ = MathUtil.vector2Length(l1x - v239_, l1z - v240_)
				if v241_ < v215_ then
					v221_ = v237_
					v220_ = v236_
					v219_ = v235_
					v218_ = v234_
					v217_ = v240_
					v216_ = v239_
					v215_ = v241_
				end
			end
		end
	end
	return v215_ ~= math.huge, v216_, v217_, v218_, v219_, v220_, v221_
end

-- Local values: maxRotDifference, angleSum, i, p1, p2, p3, yRot1, yRot2, rotDifference
function BoundaryLineGenerationTask.getSegmentsAngleData(positions)
	if #positions <= 2 then
		return 0, 0
	end
	local v243_ = 0
	local v244_ = 0
	for v245_ = 1, #positions - 2 do
		local v246_ = positions[v245_]
		local v247_ = positions[v245_ + 1]
		local v248_ = positions[v245_ + 2]
		local v249_ = MathUtil.getYRotationFromDirection(MathUtil.vector2Normalize(v247_[1] - v246_[1], v247_[2] - v246_[2]))
		local v250_ = MathUtil.getYRotationFromDirection(MathUtil.vector2Normalize(v248_[1] - v247_[1], v248_[2] - v247_[2])) - v249_
		if v250_ > 3.141592653589793 then
			v250_ = v250_ - 6.283185307179586
		end
		local v251_ = math.abs(v250_)
		v243_ = math.max(v243_, v251_)
		v244_ = v244_ + math.abs(v250_)
	end
	return v243_, v244_
end
