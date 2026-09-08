FieldCourseUtil = {}

-- Local values: numPoints, isLoop, getMaxDistancePoint, douglasPeuckerRec, i, i, i
function FieldCourseUtil.douglasPeucker(points, minDistance)
	local v3_ = #points
	if v3_ <= 2 then
		return
	else
		local v4_
		if points[1][1] == points[v3_][1] and points[1][2] == points[v3_][2] then
			table.remove(points, v3_)
			v3_ = v3_ - 1
			v4_ = true
		else
			v4_ = false
		end
		local function v_u_23_(p5_, p6_)
			-- upvalues: (copy) points
			if p6_ - p5_ <= 1 then
				return 0, -1
			end
			local v7_ = points[(p5_ - 1) % #points + 1]
			local v8_ = points[(p6_ - 1) % #points + 1]
			local v9_ = v8_[1] - v7_[1]
			local v10_ = v8_[2] - v7_[2]
			local v11_ = MathUtil.vector2Length(v9_, v10_)
			if v11_ <= 0 then
				return 0, -1
			end
			local v12_ = v9_ / v11_
			local v13_ = v10_ / v11_
			local v14_ = -1
			local v15_ = 0
			for v16_ = p5_ + 1, p6_ - 1 do
				local v17_ = points[(v16_ - 1) % #points + 1]
				local v18_ = v17_[1]
				local v19_ = v17_[2]
				local v20_, v21_ = MathUtil.projectOnLine(v18_, v19_, v7_[1], v7_[2], v12_, v13_)
				local v22_ = MathUtil.vector2Length(v18_ - v20_, v19_ - v21_)
				if v14_ < v22_ then
					v15_ = v16_
					v14_ = v22_
				end
			end
			return v15_, v14_
		end
		local function v_u_29_(p24_, p25_)
			-- upvalues: (copy) v_u_23_, (copy) minDistance, (copy) v_u_29_, (copy) points
			local v26_, v27_ = v_u_23_(p24_, p25_)
			if minDistance < v27_ then
				if v26_ - p24_ > 0 then
					v_u_29_(p24_, v26_)
				end
				if p25_ - v26_ > 0 then
					v_u_29_(v26_, p25_)
					return
				end
			elseif v27_ ~= -1 then
				for v28_ = p24_ + 1, p25_ - 1 do
					points[(v28_ - 1) % #points + 1].valid = false
				end
			end
		end
		if v4_ then
			v_u_29_(1, v3_ - 1)
			for v30_ = v3_, 1, -1 do
				if points[v30_].valid == false then
					table.remove(points, v30_)
				end
			end
			local v31_ = #points
			local v32_ = v31_ * 0.5
			local v33_ = math.floor(v32_) + 1
			local v34_ = v31_ * 0.5
			v_u_29_(v33_, v31_ + math.floor(v34_))
			for v35_ = v31_, 1, -1 do
				if points[v35_].valid == false then
					table.remove(points, v35_)
				end
			end
			local v36_ = { points[1][1], points[1][2] }
			table.insert(points, v36_)
		else
			v_u_29_(1, v3_)
			for v37_ = v3_, 1, -1 do
				if points[v37_].valid == false then
					table.remove(points, v37_)
				end
			end
		end
	end
end

-- Local values: minIndex, minArea, i, p1, p2, p3, a, b, c, area
function FieldCourseUtil.visvalingamWhyattSimplification(positions, areaThreshold)
	while true do
		local v40_ = math.huge
		local v41_ = -1
		for v42_ = 1, #positions - 2 do
			local v43_ = positions[v42_]
			local v44_ = positions[v42_ + 1]
			local v45_ = positions[v42_ + 2]
			local v46_ = MathUtil.vector2Length(v44_[1] - v43_[1], v44_[2] - v43_[2])
			local v47_ = MathUtil.vector2Length(v45_[1] - v43_[1], v45_[2] - v43_[2])
			local v48_ = MathUtil.vector2Length(v45_[1] - v44_[1], v45_[2] - v44_[2])
			local v49_ = (v46_ ^ 2 + v47_ ^ 2 + v48_ ^ 2) ^ 2 - 2 * (v46_ ^ 4 + v47_ ^ 4 + v48_ ^ 4)
			local v50_ = 0.25 * math.sqrt(v49_)
			if v50_ < areaThreshold and v50_ < v40_ then
				v41_ = v42_ + 1
				v40_ = v50_
			end
		end
		if v41_ <= 0 then
			return
		end
		table.remove(positions, v41_)
	end
end

-- Local values: index, curRegionSize, startPos, endPos, lx, lz, lineDirX, lineDirZ, greaterThanOffset, i, p, plx, plz, length, i, numPositions
function FieldCourseUtil.langSimplification(positions, maxOffset, regionSize)
	local v54_ = regionSize
	local v55_ = 1
	while true do
		local v56_ = #positions - v55_
		local v57_ = math.min(regionSize, v56_)
		local v58_ = positions[v55_]
		local v59_ = positions[v55_ + v57_]
		if v58_ == nil or v59_ == nil then
			local v60_ = #positions
			if positions[1][1] ~= positions[v60_][1] or positions[1][2] ~= positions[v60_][2] then
				local v61_ = table.clone
				local v62_ = positions[1]
				table.insert(positions, v61_(v62_, 1))
			end
			return
		end
		local v63_ = v58_[1]
		local v64_ = v58_[2]
		local v65_, v66_ = MathUtil.vector2Normalize(v59_[1], v59_[2])
		local v67_ = false
		for v68_ = v55_, v55_ + v57_ - 1 do
			local v69_ = positions[v68_]
			local v70_, v71_ = MathUtil.projectOnLine(v69_[1], v69_[2], v63_, v64_, v65_, v66_)
			if maxOffset < MathUtil.vector2Length(v69_[1] - v70_, v69_[2] - v71_) then
				v67_ = true
				break
			end
		end
		if v67_ then
			regionSize = v57_ - 1
		else
			for v72_ = v55_ + v57_ - 1, v55_, -1 do
				table.remove(positions, v72_)
			end
			v55_ = v55_ + 1
			regionSize = v54_
		end
	end
end

-- Local values: numPositions, i, p1, p2, lastPosition
function FieldCourseUtil.pointAveragePositions(positions)
	local v74_ = #positions
	if v74_ ~= 0 then
		for v75_ = 1, v74_ - 1 do
			local v76_ = positions[v75_]
			local v77_ = positions[v75_ + 1]
			local v78_ = (v76_[1] + v77_[1]) * 0.5
			local v79_ = (v76_[2] + v77_[2]) * 0.5
			v76_[1] = v78_
			v76_[2] = v79_
		end
		local v80_ = positions[v74_]
		v80_[1] = positions[1][1]
		v80_[2] = positions[1][2]
	end
end

function FieldCourseUtil.vector2Dot(x1, z1, x2, z2)
	return x1 * x2 + z1 * z2
end

-- Local values: numPositions, index1, maxAngle, maxAngleIndex, distance, index2, p1, p1_2, p2, bDirX, bDirZ, bLength, dirX, dirZ, length, angle, startIndex, p1, p2, p3, p4, dirX1, dirZ1, length1, dirX2, dirZ2, length2, i, i
function FieldCourseUtil.semiConvexSimplification(positions, maxDistance, direction)
	local v87_ = #positions
	local v88_ = 1
	while true do
		if v88_ >= v87_ - 1 then
			for v89_ = v87_, 1, -1 do
				if positions[v89_].invalid then
					table.remove(positions, v89_)
				end
			end
			return
		end
		local v90_ = 0
		local v91_ = -1
		for v92_ = 1, maxDistance do
			local v93_ = v88_ + v92_
			if v87_ < v93_ then
				break
			end
			local v94_ = positions[v88_]
			local v95_ = positions[v88_ + 1]
			local v96_ = positions[v93_]
			local v97_ = v95_[1] - v94_[1]
			local v98_ = v95_[2] - v94_[2]
			local v99_ = MathUtil.vector2Length(v97_, v98_)
			if v99_ > 0 then
				local v100_ = v97_ / v99_
				local v101_ = v98_ / v99_
				local v102_ = v96_[1] - v94_[1]
				local v103_ = v96_[2] - v94_[2]
				local v104_ = MathUtil.vector2Length(v102_, v103_)
				if v104_ > 0 then
					local v105_ = v102_ / v104_
					local v106_ = v103_ / v104_
					if FieldCourseUtil.vector2Dot(v105_, v106_, -v101_, v100_) < 0 then
						local v107_ = FieldCourseUtil.vector2Dot(v105_, v106_, v100_, v101_)
						local v108_ = math.acos(v107_)
						if v90_ < v108_ then
							v91_ = v93_
							v90_ = v108_
						end
					end
				end
			end
		end
		if v91_ > 0 then
			local v109_ = v88_ - 1
			local v110_ = math.max(v109_, 1)
			local v111_ = positions[v110_]
			local v112_ = positions[v110_ + 1]
			local v113_ = v87_ - 1
			local v114_ = positions[math.min(v91_, v113_)]
			local v115_ = v91_ + 1
			local v116_ = positions[math.min(v115_, v87_)]
			local v117_ = v112_[1] - v111_[1]
			local v118_ = v112_[2] - v111_[2]
			local v119_ = MathUtil.vector2Length(v117_, v118_)
			if v119_ > 0 then
				local v120_ = v117_ / v119_
				local v121_ = v118_ / v119_
				local v122_ = v116_[1] - v114_[1]
				local v123_ = v116_[2] - v114_[2]
				local v124_ = MathUtil.vector2Length(v122_, v123_)
				if v124_ > 0 then
					local v125_ = v122_ / v124_
					local v126_ = v123_ / v124_
					local v127_ = FieldCourseUtil.vector2Dot(v120_, v121_, v125_, v126_)
					if math.acos(v127_) < 0.7853981633974483 then
						for v128_ = v88_ + 1, v91_ - 1 do
							positions[v128_].invalid = true
						end
						v88_ = v91_ - 1
					end
				end
			end
		end
		v88_ = v88_ + 1
	end
end

-- Local values: denominator, uA, uB, x, z, dirX, dirZ, length, dot, ix, iz, ix, iz
function FieldCourseUtil.getLineSegmentsIntersection(ax1, az1, ax2, az2, bx1, bz1, bx2, bz2)
	local v137_ = (bz2 - bz1) * (ax2 - ax1) - (bx2 - bx1) * (az2 - az1)
	if v137_ ~= 0 then
		local v138_ = ((bx2 - bx1) * (az1 - bz1) - (bz2 - bz1) * (ax1 - bx1)) / v137_
		local v139_ = ((ax2 - ax1) * (az1 - bz1) - (az2 - az1) * (ax1 - bx1)) / v137_
		if v138_ > 0 and (v138_ < 1 and (v139_ > 0 and v139_ < 1)) then
			return true, ax1 + v138_ * (ax2 - ax1), az1 + v138_ * (az2 - az1)
		end
	end
	local v140_ = ax2 - ax1
	local v141_ = az2 - az1
	local v142_ = MathUtil.vector2Length(v140_, v141_)
	local v143_ = v140_ / v142_
	local v144_ = v141_ / v142_
	local v145_ = MathUtil.getProjectOnLineParameter(bx1, bz1, ax1, az1, v143_, v144_)
	if v145_ > 0 and v145_ < v142_ then
		local v146_ = ax1 + v143_ * v145_
		local v147_ = az1 + v144_ * v145_
		if MathUtil.vector2Length(v146_ - bx1, v147_ - bz1) == 0 then
			return true, v146_, v147_
		end
	end
	local v148_ = MathUtil.getProjectOnLineParameter(bx2, bz2, ax1, az1, v143_, v144_)
	if v148_ > 0 and v148_ < v142_ then
		local v149_ = ax1 + v143_ * v148_
		local v150_ = az1 + v144_ * v148_
		if MathUtil.vector2Length(v149_ - bx2, v150_ - bz2) == 0 then
			return true, v149_, v150_
		end
	end
	return false, 0, 0
end

-- Local values: intersectCount, i, x2, z2, x3, z3
function FieldCourseUtil.getIsPointInsideBoundary(x, z, boundary)
	local v154_ = 0
	for v155_ = 1, #boundary - 1 do
		local v156_ = boundary[v155_][1]
		local v157_ = boundary[v155_][2]
		local v158_ = boundary[v155_ + 1][1]
		local v159_ = boundary[v155_ + 1][2]
		if z == v157_ or z == v159_ then
			z = z + 0.00001
		end
		if MathUtil.getLineSegmentsIntersection(x, z, x + 65535, z, v156_, v157_, v158_, v159_) then
			v154_ = v154_ + 1
		end
	end
	return v154_ % 2 ~= 0, v154_
end

-- Local values: minDistance, minDistanceIndex, i, x2, z2, x3, z3, dirX, dirZ, length, dot, hitX, hitZ, distance, distance
function FieldCourseUtil.getDistanceToBoundary(x, z, boundary)
	local v163_ = math.huge
	local v164_ = -1
	for v165_ = 1, #boundary - 1 do
		local v166_ = boundary[v165_][1]
		local v167_ = boundary[v165_][2]
		local v168_ = boundary[v165_ + 1][1]
		local v169_ = boundary[v165_ + 1][2]
		local v170_ = v168_ - v166_
		local v171_ = v169_ - v167_
		local v172_ = MathUtil.vector2Length(v170_, v171_)
		local v173_ = v170_ / v172_
		local v174_ = v171_ / v172_
		local v175_ = MathUtil.getProjectOnLineParameter(x, z, v166_, v167_, v173_, v174_)
		if v175_ >= 0 and v175_ <= v172_ then
			local v176_ = v166_ + v173_ * v175_
			local v177_ = v167_ + v174_ * v175_
			local v178_ = MathUtil.vector2Length(v176_ - x, v177_ - z)
			if v178_ < v163_ then
				v164_ = v165_
				v163_ = v178_
			end
		else
			local v179_ = MathUtil.vector2Length(v166_ - x, v167_ - z)
			if v179_ < v163_ then
				v164_ = v165_
			else
				v179_ = v163_
			end
			v163_ = MathUtil.vector2Length(v168_ - x, v169_ - z)
			if v163_ < v179_ then
				v164_ = v165_
			else
				v163_ = v179_
			end
		end
	end
	return v163_, v164_
end

-- Local values: i, x2, z2, x3, z3, dirX, dirZ, length, dot, hitX, hitZ, distance, distance
function FieldCourseUtil.getPositionSegmentOverlap(x, z, segment, maxDistance)
	for v184_ = 1, #segment - 1 do
		local v185_ = segment[v184_][1]
		local v186_ = segment[v184_][2]
		local v187_ = segment[v184_ + 1][1]
		local v188_ = segment[v184_ + 1][2]
		local v189_ = v187_ - v185_
		local v190_ = v188_ - v186_
		local v191_ = MathUtil.vector2Length(v189_, v190_)
		local v192_ = v189_ / v191_
		local v193_ = v190_ / v191_
		local v194_ = MathUtil.getProjectOnLineParameter(x, z, v185_, v186_, v192_, v193_)
		if v194_ >= 0 and v194_ <= v191_ then
			local v195_ = v185_ + v192_ * v194_
			local v196_ = v186_ + v193_ * v194_
			if MathUtil.vector2Length(v195_ - x, v196_ - z) < maxDistance then
				return true
			end
		else
			local v197_ = MathUtil.vector2Length(v185_ - x, v186_ - z)
			if v197_ < maxDistance then
				return true
			end
			if v197_ < maxDistance then
				return true
			end
		end
	end
	return false
end

-- Local values: dirX, dirZ, length, dot, hitX, hitZ, sDistance, eDistance
function FieldCourseUtil.getDistanceToSegment(sx1, sz1, sx2, sz2, x, z)
	local v204_ = sx2 - sx1
	local v205_ = sz2 - sz1
	local v206_ = MathUtil.vector2Length(v204_, v205_)
	local v207_ = v204_ / v206_
	local v208_ = v205_ / v206_
	local v209_ = MathUtil.getProjectOnLineParameter(x, z, sx1, sz1, v207_, v208_)
	if v209_ >= 0 and v209_ <= v206_ then
		local v210_ = sx1 + v207_ * v209_
		local v211_ = sz1 + v208_ * v209_
		return MathUtil.vector2Length(v210_ - x, v211_ - z)
	else
		local v212_ = MathUtil.vector2Length(sx1 - x, sz1 - z)
		local v213_ = MathUtil.vector2Length(sx2 - x, sz2 - z)
		return math.min(v212_, v213_)
	end
end

-- Local values: dirX, dirZ, length, dot, dot
function FieldCourseUtil.getAreParallelSegmentsNextToEachOther(sx1, sz1, ex1, ez1, sx2, sz2, ex2, ez2)
	local v222_ = ex1 - sx1
	local v223_ = ez1 - sz1
	local v224_ = MathUtil.vector2Length(v222_, v223_)
	local v225_ = v222_ / v224_
	local v226_ = v223_ / v224_
	local v227_ = MathUtil.getProjectOnLineParameter(sx2, sz2, sx1, sz1, v225_, v226_)
	if v227_ >= 0 and v227_ <= v224_ then
		return true
	end
	local v228_ = MathUtil.getProjectOnLineParameter(ex2, ez2, sx1, sz1, v225_, v226_)
	if v228_ >= 0 and v228_ <= v224_ then
		return true
	end
	local v229_ = ex2 - sx2
	local v230_ = ez2 - sz2
	local v231_ = MathUtil.vector2Length(v229_, v230_)
	local v232_ = v229_ / v231_
	local v233_ = v230_ / v231_
	local v234_ = MathUtil.getProjectOnLineParameter(sx1, sz1, sx2, sz2, v232_, v233_)
	if v234_ >= 0 and v234_ <= v231_ then
		return true
	end
	local v235_ = MathUtil.getProjectOnLineParameter(ex1, ez1, sx2, sz2, v232_, v233_)
	return v235_ >= 0 and v235_ <= v231_
end

-- Local values: i1, x1, z1, x2, z2, i2, x3, z3, x4, z4, intersect
function FieldCourseUtil.getAreBoundariesColliding(boundary1, boundary2)
	for v238_ = 1, #boundary1 - 1 do
		local v239_ = boundary1[v238_][1]
		local v240_ = boundary1[v238_][2]
		local v241_ = boundary1[v238_ + 1][1]
		local v242_ = boundary1[v238_ + 1][2]
		for v243_ = 1, #boundary2 - 1 do
			local v244_ = boundary2[v243_][1]
			local v245_ = boundary2[v243_][2]
			local v246_ = boundary2[v243_ + 1][1]
			local v247_ = boundary2[v243_ + 1][2]
			if MathUtil.getLineSegmentsIntersection(v239_, v240_, v241_, v242_, v244_, v245_, v246_, v247_) then
				return true
			end
		end
	end
	return false
end

-- Local values: lDirX, lDirZ, numIntersections, i, sx, sz, ex, ez, intersect, _, _
function FieldCourseUtil.getIsSegmentInsideBoundary(l1x, l1z, l2x, l2z, boundary)
	local v253_, v254_ = MathUtil.vector2Normalize(l2x - l1x, l2z - l1z)
	local v255_ = l1x + v253_ * 0.001
	local v256_ = l1z + v254_ * 0.001
	local v257_ = l2x - v253_ * 0.001
	local v258_ = l2z - v254_ * 0.001
	if not (FieldCourseUtil.getIsPointInsideBoundary(v255_, v256_, boundary) and FieldCourseUtil.getIsPointInsideBoundary(v257_, v258_, boundary)) then
		return false
	end
	local v259_ = 0
	for v260_ = 1, #boundary - 1 do
		local v261_ = boundary[v260_][1]
		local v262_ = boundary[v260_][2]
		local v263_ = boundary[v260_ + 1][1]
		local v264_ = boundary[v260_ + 1][2]
		local v265_, _, _ = MathUtil.getLineSegmentsIntersection(v261_, v262_, v263_, v264_, v255_, v256_, v257_, v258_)
		if v265_ then
			v259_ = v259_ + 1
		end
	end
	return v259_ == 0
end

-- Local values: i, sx, sz, ex, ez, intersect, x, z
function FieldCourseUtil.getSegmentBoundaryIntersection(l1x, l1z, l2x, l2z, boundary)
	for v271_ = 1, #boundary - 1 do
		local v272_ = boundary[v271_][1]
		local v273_ = boundary[v271_][2]
		local v274_ = boundary[v271_ + 1][1]
		local v275_ = boundary[v271_ + 1][2]
		local v276_, v277_, v278_ = MathUtil.getLineSegmentsIntersection(v272_, v273_, v274_, v275_, l1x, l1z, l2x, l2z)
		if v276_ then
			return v276_, v277_, v278_
		end
	end
	return false, 0, 0
end

-- Local values: intersections, i, sx, sz, ex, ez, intersect, _, _
function FieldCourseUtil.getSegmentNumBoundaryIntersections(l1x, l1z, l2x, l2z, boundary)
	local v284_ = 0
	for v285_ = 1, #boundary - 1 do
		local v286_ = boundary[v285_][1]
		local v287_ = boundary[v285_][2]
		local v288_ = boundary[v285_ + 1][1]
		local v289_ = boundary[v285_ + 1][2]
		local v290_, _, _ = MathUtil.getLineSegmentsIntersection(v286_, v287_, v288_, v289_, l1x, l1z, l2x, l2z)
		if v290_ then
			v284_ = v284_ + 1
		end
	end
	return v284_
end

-- Local values: minDistance, ix, iz, psx, psz, pex, pez, i, sx, sz, ex, ez, intersect, x, z, distance
function FieldCourseUtil.getSegmentClosestBoundaryIntersection(l1x, l1z, l2x, l2z, boundary)
	local v296_ = math.huge
	local v297_ = nil
	local v298_ = nil
	local v299_ = nil
	local v300_ = nil
	local v301_ = nil
	local v302_ = nil
	for v303_ = 1, #boundary - 1 do
		local v304_ = boundary[v303_][1]
		local v305_ = boundary[v303_][2]
		local v306_ = boundary[v303_ + 1][1]
		local v307_ = boundary[v303_ + 1][2]
		local v308_, v309_, v310_ = MathUtil.getLineSegmentsIntersection(v304_, v305_, v306_, v307_, l1x, l1z, l2x, l2z)
		if v308_ then
			local v311_ = MathUtil.vector2Length(l1x - v309_, l1z - v310_)
			if v311_ < v296_ then
				v302_ = v307_
				v301_ = v306_
				v300_ = v305_
				v299_ = v304_
				v298_ = v310_
				v297_ = v309_
				v296_ = v311_
			end
		end
	end
	return v296_ ~= math.huge, v297_, v298_, v299_, v300_, v301_, v302_
end

-- Local values: minDistance, ix, iz, i, sx, sz, ex, ez, length, intersect, ix1, iz1, ix2, iz2, distance, distance
function FieldCourseUtil.getSegmentClosestBoundaryCircleIntersection(refX, refZ, circleX, circleZ, radius, boundary)
	local v318_ = math.huge
	local v319_ = nil
	local v320_ = nil
	for v321_ = 1, #boundary - 1 do
		local v322_ = boundary[v321_][1]
		local v323_ = boundary[v321_][2]
		local v324_ = boundary[v321_ + 1][1]
		local v325_ = boundary[v321_ + 1][2]
		if MathUtil.vector2Length(v322_ - v324_, v323_ - v325_) > 0 then
			local v326_, v327_, v328_, v329_, v330_ = MathUtil.getCircleLineIntersection(circleX, circleZ, radius, v322_, v323_, v324_, v325_)
			if v326_ then
				local v331_
				if v327_ == nil or v328_ == nil then
					v328_ = v320_
					v327_ = v319_
					v331_ = v318_
				else
					v331_ = MathUtil.vector2Length(v327_ - refX, v328_ - refZ)
					if v331_ >= v318_ then
						v328_ = v320_
						v327_ = v319_
						v331_ = v318_
					end
				end
				if v329_ == nil or v330_ == nil then
					v320_ = v328_
					v319_ = v327_
					v318_ = v331_
				else
					v318_ = MathUtil.vector2Length(v329_ - refX, v330_ - refZ)
					if v318_ < v331_ then
						v320_ = v330_
						v319_ = v329_
					else
						v320_ = v328_
						v319_ = v327_
						v318_ = v331_
					end
				end
			end
		end
	end
	return v319_ ~= nil, v319_, v320_
end

-- Local values: minDistance, cx, cz, i, sx, sz, ex, ez, dirX, dirZ, length, dot, ix, iz, distance, distance, distance
function FieldCourseUtil.getClosestPositionOnBoundary(x, z, boundary)
	local v335_ = math.huge
	local v336_ = nil
	local v337_ = nil
	for v338_ = 1, #boundary - 1 do
		local v339_ = boundary[v338_][1]
		local v340_ = boundary[v338_][2]
		local v341_ = boundary[v338_ + 1][1]
		local v342_ = boundary[v338_ + 1][2]
		local v343_ = v341_ - v339_
		local v344_ = v342_ - v340_
		local v345_ = MathUtil.vector2Length(v343_, v344_)
		local v346_ = v343_ / v345_
		local v347_ = v344_ / v345_
		local v348_ = MathUtil.getProjectOnLineParameter(x, z, v339_, v340_, v346_, v347_)
		local v349_, v350_, v351_
		if v348_ >= 0 and v348_ <= v345_ then
			v349_ = v339_ + v346_ * v348_
			v350_ = v340_ + v347_ * v348_
			v351_ = MathUtil.vector2Length(v349_ - x, v350_ - z)
			if v351_ >= v335_ then
				v350_ = v337_
				v349_ = v336_
				v351_ = v335_
			end
		else
			v350_ = v337_
			v349_ = v336_
			v351_ = v335_
		end
		local v352_ = MathUtil.vector2Length(v339_ - x, v340_ - z)
		if v352_ >= v351_ then
			v340_ = v350_
			v339_ = v349_
			v352_ = v351_
		end
		v335_ = MathUtil.vector2Length(v341_ - x, v342_ - z)
		if v335_ < v352_ then
			v337_ = v342_
			v336_ = v341_
		else
			v337_ = v340_
			v336_ = v339_
			v335_ = v352_
		end
	end
	return v336_, v337_
end

-- Local values: minDistance, cx, cz, cDirX, cDirZ, i, sx, sz, ex, ez, dirX, dirZ, length, dot, ix, iz, distance, distance, distance
function FieldCourseUtil.getClosestPositionAndDirectionOnBoundary(x, z, boundary)
	local v356_ = math.huge
	local v357_ = nil
	local v358_ = nil
	local v359_ = nil
	local v360_ = nil
	for v361_ = 1, #boundary - 1 do
		local v362_ = boundary[v361_][1]
		local v363_ = boundary[v361_][2]
		local v364_ = boundary[v361_ + 1][1]
		local v365_ = boundary[v361_ + 1][2]
		local v366_ = v364_ - v362_
		local v367_ = v365_ - v363_
		local v368_ = MathUtil.vector2Length(v366_, v367_)
		local v369_ = v366_ / v368_
		local v370_ = v367_ / v368_
		local v371_ = MathUtil.getProjectOnLineParameter(x, z, v362_, v363_, v369_, v370_)
		local v372_, v373_, v374_
		if v371_ >= 0 and v371_ <= v368_ then
			v372_ = v362_ + v369_ * v371_
			v373_ = v363_ + v370_ * v371_
			v374_ = MathUtil.vector2Length(v372_ - x, v373_ - z)
			if v374_ < v356_ then
				v360_ = v370_
				v359_ = v369_
			else
				v373_ = v358_
				v372_ = v357_
				v374_ = v356_
			end
		else
			v373_ = v358_
			v372_ = v357_
			v374_ = v356_
		end
		local v375_ = MathUtil.vector2Length(v362_ - x, v363_ - z)
		if v375_ < v374_ then
			v360_ = v370_
			v359_ = v369_
		else
			v363_ = v373_
			v362_ = v372_
			v375_ = v374_
		end
		v356_ = MathUtil.vector2Length(v364_ - x, v365_ - z)
		if v356_ < v375_ then
			v360_ = v370_
			v359_ = v369_
			v358_ = v365_
			v357_ = v364_
		else
			v358_ = v363_
			v357_ = v362_
			v356_ = v375_
		end
	end
	return v357_, v358_, v359_, v360_
end

-- Local values: numPositions, minDistance, cx, cz, cDirX, cDirZ, onLineX, onLineZ, i, sx, sz, ex, ez, dirX, dirZ, length, dot, ix, iz, distance, distance, distance, sx, sz, ex, ez, dirX, dirZ, dot, ix, iz, distance, ix, iz, distance
function FieldCourseUtil.getClosestExtendedPositionAndDirectionOnSegment(x, z, positions, maxExtension)
	local v380_ = #positions
	local v381_ = math.huge
	local v382_ = nil
	local v383_ = nil
	local v384_ = nil
	local v385_ = nil
	for v386_ = 1, v380_ - 1 do
		local v387_ = positions[v386_][1]
		local v388_ = positions[v386_][2]
		local v389_ = positions[v386_ + 1][1]
		local v390_ = positions[v386_ + 1][2]
		local v391_ = v389_ - v387_
		local v392_ = v390_ - v388_
		local v393_ = MathUtil.vector2Length(v391_, v392_)
		local v394_ = v391_ / v393_
		local v395_ = v392_ / v393_
		local v396_ = MathUtil.getProjectOnLineParameter(x, z, v387_, v388_, v394_, v395_)
		local v397_, v398_, v399_
		if v396_ >= 0 and v396_ <= v393_ then
			v397_ = v387_ + v394_ * v396_
			v398_ = v388_ + v395_ * v396_
			v399_ = MathUtil.vector2Length(v397_ - x, v398_ - z)
			if v399_ < v381_ then
				v385_ = v395_
				v384_ = v394_
			else
				v398_ = v383_
				v397_ = v382_
				v399_ = v381_
			end
		else
			v398_ = v383_
			v397_ = v382_
			v399_ = v381_
		end
		local v400_ = MathUtil.vector2Length(v387_ - x, v388_ - z)
		if v400_ < v399_ then
			v385_ = v395_
			v384_ = v394_
		else
			v388_ = v398_
			v387_ = v397_
			v400_ = v399_
		end
		v381_ = MathUtil.vector2Length(v389_ - x, v390_ - z)
		if v381_ < v400_ then
			v385_ = v395_
			v384_ = v394_
			v383_ = v390_
			v382_ = v389_
		else
			v383_ = v388_
			v382_ = v387_
			v381_ = v400_
		end
	end
	local v401_ = positions[1][1]
	local v402_ = positions[1][2]
	local v403_ = positions[2][1]
	local v404_ = positions[2][2]
	local v405_, v406_ = MathUtil.vector2Normalize(v401_ - v403_, v402_ - v404_)
	local v407_ = MathUtil.getProjectOnLineParameter(x, z, v401_, v402_, v405_, v406_)
	local v408_, v409_, v410_
	if v407_ > 0 then
		local v411_ = math.min(v407_, maxExtension)
		v408_ = v401_ + v405_ * v411_
		v409_ = v402_ + v406_ * v411_
		v410_ = MathUtil.vector2Length(v408_ - x, v409_ - z)
		if v410_ >= v381_ then
			v402_ = v383_
			v401_ = v382_
			v406_ = v385_
			v405_ = v384_
			v409_ = v402_
			v408_ = v401_
			v410_ = v381_
			local v412_ = v402_
			v402_ = v409_
			v412_ = v401_
			v401_ = v408_
			v412_ = v409_
			v409_ = v402_
			v412_ = v408_
			v408_ = v401_
		end
	else
		v402_ = v383_
		v401_ = v382_
		v406_ = v385_
		v405_ = v384_
		v409_ = v402_
		v408_ = v401_
		v410_ = v381_
		local v413_ = v402_
		v402_ = v409_
		v413_ = v401_
		v401_ = v408_
		v413_ = v409_
		v409_ = v402_
		v413_ = v408_
		v408_ = v401_
	end
	local v414_ = positions[v380_][1]
	local v415_ = positions[v380_][2]
	local v416_ = positions[v380_ - 1][1]
	local v417_ = positions[v380_ - 1][2]
	local v418_, v419_ = MathUtil.vector2Normalize(v414_ - v416_, v415_ - v417_)
	local v420_ = MathUtil.getProjectOnLineParameter(x, z, v414_, v415_, v418_, v419_)
	local v421_, v422_
	if v420_ > 0 then
		local v423_ = math.min(v420_, maxExtension)
		v421_ = v414_ + v418_ * v423_
		v422_ = v415_ + v419_ * v423_
		if MathUtil.vector2Length(v421_ - x, v422_ - z) >= v410_ then
			v415_ = v402_
			v414_ = v401_
			v419_ = v406_
			v418_ = v405_
			v422_ = v409_
			v421_ = v408_
		end
	else
		v415_ = v402_
		v414_ = v401_
		v419_ = v406_
		v418_ = v405_
		v422_ = v409_
		v421_ = v408_
	end
	return v421_, v422_, v418_, v419_, v414_, v415_
end

-- Local values: length, i, sx, sz, ex, ez
function FieldCourseUtil.getSegmentLength(positions)
	local v425_ = 0
	for v426_ = 1, #positions - 1 do
		local v427_ = positions[v426_][1]
		local v428_ = positions[v426_][2]
		local v429_ = positions[v426_ + 1][1]
		local v430_ = positions[v426_ + 1][2]
		v425_ = v425_ + MathUtil.vector2Length(v429_ - v427_, v430_ - v428_)
	end
	return v425_
end

-- Local values: p1, p2, dirX, dirZ, length, p1, p2, dirX, dirZ, length
function FieldCourseUtil.extendSegment(positions, direction, offset)
	if direction > 0 then
		local v434_ = positions[#positions - 1]
		local v435_ = positions[#positions]
		local v436_ = v435_[1] - v434_[1]
		local v437_ = v435_[2] - v434_[2]
		local v438_ = MathUtil.vector2Length(v436_, v437_)
		local v439_ = v436_ / v438_
		local v440_ = v437_ / v438_
		if offset >= 0 then
			local v441_ = v435_[1] + v439_ * offset
			local v442_ = v435_[2] + v440_ * offset
			v435_[1] = v441_
			v435_[2] = v442_
			return
		end
		if v438_ >= -offset then
			local v443_ = v435_[1] + v439_ * offset
			local v444_ = v435_[2] + v440_ * offset
			v435_[1] = v443_
			v435_[2] = v444_
			return
		end
		if #positions > 2 then
			local v445_ = offset + v438_
			table.remove(positions, #positions)
			FieldCourseUtil.extendSegment(positions, direction, v445_)
			return
		end
	else
		local v446_ = positions[1]
		local v447_ = positions[2]
		local v448_ = v446_[1] - v447_[1]
		local v449_ = v446_[2] - v447_[2]
		local v450_ = MathUtil.vector2Length(v448_, v449_)
		local v451_ = v448_ / v450_
		local v452_ = v449_ / v450_
		if offset < 0 then
			if v450_ >= -offset then
				local v453_ = v446_[1] + v451_ * offset
				local v454_ = v446_[2] + v452_ * offset
				v446_[1] = v453_
				v446_[2] = v454_
				return
			end
			if #positions > 2 then
				local v455_ = offset + v450_
				table.remove(positions, 1)
				FieldCourseUtil.extendSegment(positions, direction, v455_)
				return
			end
		else
			local v456_ = v446_[1] + v451_ * offset
			local v457_ = v446_[2] + v452_ * offset
			v446_[1] = v456_
			v446_[2] = v457_
		end
	end
end

-- Local values: p1, p2, dirX, dirZ, length, intersect1, ix1, iz1, extensionLength, p1, p2, dirX, dirZ, length, intersect1, ix1, iz1, extensionLength
function FieldCourseUtil.extendSegmentToBoundary(positions, boundary, extendStart, extendEnd, maxDistance)
	local v463_ = maxDistance or math.huge
	if extendStart ~= false then
		local v464_ = positions[1]
		local v465_ = positions[2]
		local v466_ = v464_[1] - v465_[1]
		local v467_ = v464_[2] - v465_[2]
		local v468_ = MathUtil.vector2Length(v466_, v467_)
		local v469_ = v466_ / v468_
		local v470_ = v467_ / v468_
		local v471_, v472_, v473_ = FieldCourseUtil.getSegmentBoundaryIntersection(v464_[1], v464_[2], v464_[1] + v469_ * 65535, v464_[2] + v470_ * 65535, boundary)
		if v471_ and MathUtil.vector2Length(v472_ - v464_[1], v473_ - v464_[2]) < v463_ then
			v464_[1] = v472_
			v464_[2] = v473_
		end
	end
	if extendEnd ~= false then
		local v474_ = positions[#positions]
		local v475_ = positions[#positions - 1]
		local v476_ = v474_[1] - v475_[1]
		local v477_ = v474_[2] - v475_[2]
		local v478_ = MathUtil.vector2Length(v476_, v477_)
		local v479_ = v476_ / v478_
		local v480_ = v477_ / v478_
		local v481_, v482_, v483_ = FieldCourseUtil.getSegmentBoundaryIntersection(v474_[1], v474_[2], v474_[1] + v479_ * 65535, v474_[2] + v480_ * 65535, boundary)
		if v481_ and MathUtil.vector2Length(v482_ - v474_[1], v483_ - v474_[2]) < v463_ then
			v474_[1] = v482_
			v474_[2] = v483_
		end
	end
end

-- Local values: pos1, pos2, numPositions, dx, dz, x1, z1, x2, z2, overlap1, overlap2, otherGroupIndex, otherLines, _, otherLine, islandIndex, island, headlandIndex, islandBoundary, i, otherLine, headlandIndex, headlandBoundary, i, otherLine
function FieldCourseUtil.extendSegmentUntilOverlap(lines, islands, boundaries, groupIndex, positions, direction, sideOffset, distanceToAdjust, step)
	local v493_ = positions[1]
	local v494_ = positions[2]
	if direction == 1 then
		local v495_ = #positions
		v493_ = positions[v495_]
		v494_ = positions[v495_ - 1]
	end
	local v496_, v497_ = MathUtil.vector2Normalize(v493_[1] - v494_[1], v493_[2] - v494_[2])
	local v498_ = v493_[1] + v497_ * sideOffset
	local v499_ = v493_[2] - v496_ * sideOffset
	local v500_ = v493_[1] - v497_ * sideOffset
	local v501_ = v493_[2] + v496_ * sideOffset
	local v502_ = false
	local v503_ = false
	for v504_, v505_ in pairs(lines) do
		if groupIndex ~= v504_ then
			for _, v506_ in ipairs(v505_) do
				v502_ = FieldCourseUtil.getPositionSegmentOverlap(v498_, v499_, v506_.positions, sideOffset) and true or v502_
				v503_ = FieldCourseUtil.getPositionSegmentOverlap(v500_, v501_, v506_.positions, sideOffset) and true or v503_
				if v502_ and v503_ then
					break
				end
			end
		end
		if v502_ and v503_ then
			break
		end
	end
	if not (v502_ and v503_) then
		for _, v507_ in ipairs(islands) do
			for _, v508_ in ipairs(v507_.boundaries) do
				for v509_ = 1, #v508_.segments do
					local v510_ = v508_.segments[v509_]
					v502_ = FieldCourseUtil.getPositionSegmentOverlap(v498_, v499_, v510_.positions, sideOffset) and true or v502_
					v503_ = FieldCourseUtil.getPositionSegmentOverlap(v500_, v501_, v510_.positions, sideOffset) and true or v503_
					if v502_ and v503_ then
						break
					end
				end
				if v502_ and v503_ then
					break
				end
			end
			if v502_ and v503_ then
				break
			end
		end
	end
	if not (v502_ and v503_) then
		for _, v511_ in ipairs(boundaries) do
			for v512_ = 1, #v511_.segments do
				local v513_ = v511_.segments[v512_]
				v502_ = FieldCourseUtil.getPositionSegmentOverlap(v498_, v499_, v513_.positions, sideOffset) and true or v502_
				v503_ = FieldCourseUtil.getPositionSegmentOverlap(v500_, v501_, v513_.positions, sideOffset) and true or v503_
				if v502_ and v503_ then
					break
				end
			end
			if v502_ and v503_ then
				break
			end
		end
	end
	if not (v502_ and v503_) then
		local v514_ = distanceToAdjust - step
		if v514_ > 0 then
			FieldCourseUtil.extendSegment(positions, direction, step)
			FieldCourseUtil.extendSegmentUntilOverlap(lines, islands, boundaries, groupIndex, positions, direction, sideOffset, v514_, step)
		end
	end
end

-- Local values: pos1, pos2, numPositions, dx, dz, x1, z1, x2, z2, overlap1, overlap2, otherGroupIndex, otherLines, _, otherLine, islandIndex, island, headlandIndex, islandBoundary, i, otherLine, headlandIndex, headlandBoundary, i, otherLine
function FieldCourseUtil.shrinkSegmentUntilOverlap(lines, islands, boundaries, groupIndex, positions, direction, sideOffset, distanceToAdjust, step)
	local v524_ = positions[1]
	local v525_ = positions[2]
	if direction == 1 then
		local v526_ = #positions
		v524_ = positions[v526_]
		v525_ = positions[v526_ - 1]
	end
	local v527_, v528_ = MathUtil.vector2Normalize(v524_[1] - v525_[1], v524_[2] - v525_[2])
	local v529_ = v524_[1] + v528_ * sideOffset
	local v530_ = v524_[2] - v527_ * sideOffset
	local v531_ = v524_[1] - v528_ * sideOffset
	local v532_ = v524_[2] + v527_ * sideOffset
	local v533_ = false
	local v534_ = false
	for v535_, v536_ in pairs(lines) do
		if groupIndex ~= v535_ then
			for _, v537_ in ipairs(v536_) do
				v533_ = FieldCourseUtil.getPositionSegmentOverlap(v529_, v530_, v537_.positions, sideOffset) and true or v533_
				v534_ = FieldCourseUtil.getPositionSegmentOverlap(v531_, v532_, v537_.positions, sideOffset) and true or v534_
				if v533_ and v534_ then
					break
				end
			end
		end
		if v533_ and v534_ then
			break
		end
	end
	if not (v533_ and v534_) then
		for _, v538_ in ipairs(islands) do
			for _, v539_ in ipairs(v538_.boundaries) do
				for v540_ = 1, #v539_.segments do
					local v541_ = v539_.segments[v540_]
					v533_ = FieldCourseUtil.getPositionSegmentOverlap(v529_, v530_, v541_.positions, sideOffset) and true or v533_
					v534_ = FieldCourseUtil.getPositionSegmentOverlap(v531_, v532_, v541_.positions, sideOffset) and true or v534_
					if v533_ and v534_ then
						break
					end
				end
				if v533_ and v534_ then
					break
				end
			end
			if v533_ and v534_ then
				break
			end
		end
	end
	if not (v533_ and v534_) then
		for _, v542_ in ipairs(boundaries) do
			for v543_ = 1, #v542_.segments do
				local v544_ = v542_.segments[v543_]
				v533_ = FieldCourseUtil.getPositionSegmentOverlap(v529_, v530_, v544_.positions, sideOffset) and true or v533_
				v534_ = FieldCourseUtil.getPositionSegmentOverlap(v531_, v532_, v544_.positions, sideOffset) and true or v534_
				if v533_ and v534_ then
					break
				end
			end
			if v533_ and v534_ then
				break
			end
		end
	end
	if v533_ and v534_ then
		local v545_ = distanceToAdjust - step
		if v545_ >= 0 then
			if FieldCourseUtil.getSegmentLength(positions) <= step + 1 then
				return
			end
			FieldCourseUtil.extendSegment(positions, direction, -step)
			FieldCourseUtil.shrinkSegmentUntilOverlap(lines, islands, boundaries, groupIndex, positions, direction, sideOffset, v545_, step)
		end
	end
end

-- Local values: i, p1, p2, p3, x, z, dx1, dz1, dx2, dz2, length1, length2, offset1, offset2
function FieldCourseUtil.extendSegmentPositions(segment, toolFrontOffset)
	if toolFrontOffset > 0 then
		for v548_ = #segment.positions - 1, 2, -1 do
			local v549_ = segment.positions[v548_ - 1]
			local v550_ = segment.positions[v548_]
			local v551_ = segment.positions[v548_ + 1]
			local v552_ = v550_[1]
			local v553_ = v550_[2]
			local v554_ = v552_ - v549_[1]
			local v555_ = v553_ - v549_[2]
			local v556_ = v551_[1] - v552_
			local v557_ = v551_[2] - v553_
			local v558_ = MathUtil.vector2Length(v554_, v555_)
			local v559_ = MathUtil.vector2Length(v556_, v557_)
			local v560_ = v554_ / v558_
			local v561_ = v555_ / v558_
			local v562_ = v556_ / v559_
			local v563_ = v557_ / v559_
			local v564_ = v558_ * 0.5
			local v565_ = math.min(v564_, toolFrontOffset)
			local v566_ = v559_ * 0.5
			local v567_ = math.min(v566_, toolFrontOffset)
			local v568_ = v552_ - v560_ * v565_
			local v569_ = v553_ - v561_ * v565_
			v550_[1] = v568_
			v550_[2] = v569_
			local v570_ = segment.positions
			local v571_ = v548_ + 1
			local v572_ = { v552_ + v562_ * v567_, v553_ + v563_ * v567_ }
			table.insert(v570_, v571_, v572_)
		end
	end
end

-- Local values: numPositions, i, p1, p2, dx, dz
function FieldCourseUtil.segmentApplySideOffset(segment, sideOffset)
	local v575_ = #segment.positions
	for v576_ = 1, v575_ - 1 do
		local v577_ = segment.positions[v576_]
		local v578_ = segment.positions[v576_ + 1]
		local v579_, v580_ = MathUtil.vector2Normalize(v578_[1] - v577_[1], v578_[2] - v577_[2])
		local v581_ = v577_[1] + v580_ * sideOffset
		local v582_ = v577_[2] - v579_ * sideOffset
		v577_[1] = v581_
		v577_[2] = v582_
		if v576_ + 1 == v575_ then
			local v583_ = v578_[1] + v580_ * sideOffset
			local v584_ = v578_[2] - v579_ * sideOffset
			v578_[1] = v583_
			v578_[2] = v584_
		end
	end
	return true
end

-- Local values: posIndex, pos1, pos2, length
function FieldCourseUtil.removeShortSegments(boundaryLine, threshold, isLoop)
	for v588_ = #boundaryLine - 1, 1, -1 do
		local v589_ = boundaryLine[v588_]
		local v590_ = boundaryLine[v588_ + 1]
		if MathUtil.vector2Length(v590_[1] - v589_[1], v590_[2] - v589_[2]) < threshold then
			table.remove(boundaryLine, v588_)
			if v588_ == 1 and isLoop ~= false then
				boundaryLine[1] = table.clone(boundaryLine[#boundaryLine])
			end
		end
	end
	return false
end
