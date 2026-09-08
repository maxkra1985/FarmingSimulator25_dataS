-- Local values: TrapezoidDecomposition_mt, sortLineFunction
TrapezoidDecomposition = {}
local TrapezoidDecomposition_mt = Class(TrapezoidDecomposition)
TrapezoidDecomposition.MAX_MERGE_ANGLE = 4.1887902047863905
TrapezoidDecomposition.MAX_ORIENTATION_MERGE_DIFFERENCE = 0.6108652381980153
TrapezoidDecomposition.MIN_MERGE_LENGTH_PERCENTAGE = 0.1
TrapezoidDecomposition.OPTIMAL_ANGLE_STEPS = 16
TrapezoidDecomposition.COLORS = {
	{ 0.7079, 0.6987, 0.2864 },
	{ 0.9628, 0.5908, 0.4254 },
	{ 0.078, 0.3129, 0.7987 },
	{ 0.0244, 0.6147, 0.5057 },
	{ 0.2402, 0.7016, 0.8469 },
	{ 0.2624, 0.4573, 0.5326 },
	{ 0.22, 0.859, 0.6861 },
	{ 0.7581, 0.1639, 0.3565 },
	{ 0.0544, 0.6152, 0.1018 },
	{ 0.747, 0.2893, 0.3946 }
}

-- Upvalues: TrapezoidDecomposition_mt
-- Local values: self
function TrapezoidDecomposition.new(boundary, singleGroupMode)
	-- upvalues: (copy) TrapezoidDecomposition_mt
	local v4_ = TrapezoidDecomposition_mt
	local v5_ = setmetatable({}, v4_)
	v5_.boundary = boundary
	v5_.trapezoidLines = {}
	v5_.trapezoids = {}
	v5_.trapezoidGroups = {}
	v5_.numGroups = {}
	v5_.singleGroupMode = Utils.getNoNil(singleGroupMode, false)
	v5_.step = 0
	return v5_
end

-- Local values: startTime
function TrapezoidDecomposition:update(dt, frameBudget)
	local v8_ = getTimeSec()
	while getTimeSec() - v8_ < frameBudget do
		if self.step == 1 then
			self:generateVerticalLines()
		elseif self.step == 2 then
			self:generateTrapezoids()
		elseif self.step == 3 then
			self:assignMergeGroups()
		elseif self.step == 4 then
			self:generateGroups()
		elseif self.step == 5 then
			self:mergeGroupsBySize()
		elseif self.step == 6 then
			self:mergeGroupsByWorkDirection()
		elseif self.step == 7 then
			self:mergeGroupsByCost()
		elseif self.step == 8 then
			self:updateGroups()
			return false
		end
		self.step = self.step + 1
	end
	return true
end

-- Local values: sortedBoundaryPositions, posIndex, foundBoundaryIntersection, position, closestIntersectionX, closestIntersectionZ, lastPosition, nextPosition, point
function TrapezoidDecomposition:generateVerticalLines()
	self.trapezoidLines = {}
	local v10_ = table.clone(self.boundary)
	table.remove(v10_, #v10_)
	table.sort(v10_, function(p11_, p12_)
		return p11_[1] < p12_[1]
	end)
	for v13_ = 1, #v10_ do
		local v14_ = v10_[v13_]
		local v15_, v16_ = TrapezoidDecomposition.getClosestIntersectionWithBoundary(v14_, 0, 1, self.boundary)
		local v17_
		if v15_ == nil then
			v17_ = false
		else
			local v18_ = self.trapezoidLines
			local v19_ = {
				{ v14_[1], v16_ },
				{ v14_[1], v14_[2] }
			}
			table.insert(v18_, v19_)
			v17_ = true
		end
		local v20_, v21_ = TrapezoidDecomposition.getClosestIntersectionWithBoundary(v14_, 0, -1, self.boundary)
		if v20_ ~= nil then
			local v22_ = self.trapezoidLines
			local v23_ = {
				{ v14_[1], v14_[2] },
				{ v14_[1], v21_ }
			}
			table.insert(v22_, v23_)
			v17_ = true
		end
		if not v17_ then
			local v24_ = v10_[v13_ - 1]
			local v25_ = v10_[v13_ + 1]
			if v24_ ~= nil then
				local v26_ = v24_[1] - v14_[1]
				if math.abs(v26_) < 0.00001 then
					if v14_[2] > v24_[2] then
						local v27_ = self.trapezoidLines
						local v28_ = {
							{ v14_[1], v14_[2] },
							{ v14_[1], v24_[2] }
						}
						table.insert(v27_, v28_)
						v17_ = true
					else
						local v29_ = self.trapezoidLines
						local v30_ = {
							{ v14_[1], v24_[2] },
							{ v14_[1], v14_[2] }
						}
						table.insert(v29_, v30_)
						v17_ = true
					end
				end
			end
			if v25_ ~= nil then
				local v31_ = v25_[1] - v14_[1]
				if math.abs(v31_) < 0.00001 then
					if v14_[2] > v25_[2] then
						local v32_ = self.trapezoidLines
						local v33_ = {
							{ v14_[1], v14_[2] },
							{ v14_[1], v25_[2] }
						}
						table.insert(v32_, v33_)
						v17_ = true
					else
						local v34_ = self.trapezoidLines
						local v35_ = {
							{ v14_[1], v25_[2] },
							{ v14_[1], v14_[2] }
						}
						table.insert(v34_, v35_)
						v17_ = true
					end
				end
			end
			if not v17_ then
				local v36_ = { v14_[1], v14_[2] }
				local v37_ = self.trapezoidLines
				table.insert(v37_, { v36_, v36_ })
			end
		end
	end
end

-- Local values: generateTrapezoidFromLine, lineIndex, doNotMergeUntilIndex, line1, newLine, newLineEndIndex, nextIndex, nextLine, newLineIndex, success, trapezoidIndex, trapezoid
function TrapezoidDecomposition:generateTrapezoids()
	self.trapezoids = {}
	local v39_ = 1
	local v40_ = 0
	local function v61_(p41_, p42_, p43_, p44_)
		-- upvalues: (copy) self
		for v45_ = p42_, #self.trapezoidLines do
			local v46_ = self.trapezoidLines[v45_]
			if v46_[1][1] > p41_[1][1] then
				local v47_ = true
				if p43_ ~= nil and p44_ ~= nil then
					for v48_ = p43_, p44_ do
						if not TrapezoidDecomposition.getIsNeighbouringLine(self.trapezoidLines[v48_], v46_, self.boundary, self.trapezoidLines) then
							v47_ = false
							break
						end
					end
				end
				if v47_ and TrapezoidDecomposition.getIsNeighbouringLine(p41_, v46_, self.boundary, self.trapezoidLines) then
					local v49_ = {
						["line1"] = p41_,
						["line2"] = v46_,
						["groupId"] = 0,
						["size"] = TrapezoidDecomposition.getTrapezoidSize(p41_, v46_)
					}
					local v50_ = v45_ + 1
					while true do
						local v51_ = self.trapezoidLines[v50_]
						if v51_ == nil or v46_[1][1] < v51_[1][1] then
							break
						end
						if TrapezoidDecomposition.getIsNeighbouringLine(p41_, v51_, self.boundary, self.trapezoidLines) then
							local v52_ = {}
							local v53_ = v49_.line2[1][1]
							local v54_ = v49_.line2[1][2]
							local v55_ = v51_[1][2]
							__set_list(v52_, 1, {v53_, (math.max(v54_, v55_))})
							local v56_ = {}
							local v57_ = v49_.line2[2][1]
							local v58_ = v49_.line2[2][2]
							local v59_ = v51_[2][2]
							__set_list(v56_, 1, {v57_, (math.min(v58_, v59_))})
							v49_.line2 = { v52_, v56_ }
						end
						v50_ = v50_ + 1
					end
					local v60_ = self.trapezoids
					table.insert(v60_, v49_)
					return p42_, true
				end
			end
		end
		return p42_, false
	end
	while true do
		local v62_ = self.trapezoidLines[v39_]
		if v62_ == nil then
			break
		end
		local v63_ = nil
		local v64_ = nil
		for v65_ = v39_ + 1, #self.trapezoidLines do
			if v40_ < v65_ then
				local v66_ = self.trapezoidLines[v65_]
				local v67_ = v66_[1][1] - self.trapezoidLines[v39_][1][1]
				if math.abs(v67_) < 0.0001 then
					v63_ = v63_ == nil and {
						{ v62_[1][1], v62_[1][2] },
						{ v62_[2][1], v62_[2][2] }
					} or v63_
					local v68_ = v63_[1]
					local v69_ = v63_[1][2]
					local v70_ = v66_[1][2]
					v68_[2] = math.max(v69_, v70_)
					local v71_ = v63_[2]
					local v72_ = v63_[2][2]
					local v73_ = v66_[2][2]
					v71_[2] = math.min(v72_, v73_)
					v64_ = v65_
				end
			end
		end
		if v63_ == nil then
			v39_ = v61_(v62_, v39_ + 1)
		else
			local v74_, v75_ = v61_(v63_, v64_ + 1, v39_, v64_)
			if v75_ then
				v39_ = v74_
			else
				v39_ = v61_(v62_, v39_ + 1)
				v40_ = v74_
			end
		end
	end
	for v76_ = #self.trapezoids, 1, -1 do
		local v77_ = self.trapezoids[v76_]
		local v78_ = v77_.line1[1][1] - v77_.line2[1][1]
		if math.abs(v78_) < 1e-7 then
			table.remove(self.trapezoids, v76_)
		end
	end
end

-- Local values: getAngleFromPoints
function TrapezoidDecomposition.getCanTrapezoidsBeMerged(trapezoid1, trapezoid2)
	local function v104_(p81_, p82_, p83_, p84_)
		local v85_ = p81_[1]
		local v86_ = p81_[2]
		local v87_ = p82_[1]
		local v88_ = p82_[2]
		local v89_ = p83_[1]
		local v90_ = p83_[2]
		local v91_ = p84_[1]
		local v92_ = p84_[2]
		local v93_, v94_ = MathUtil.vector2Normalize(v85_ - v87_, v86_ - v88_)
		local v95_, v96_ = MathUtil.vector2Normalize(v89_ - v87_, v90_ - v88_)
		local v97_ = v91_ - v87_
		local v98_ = v92_ - v88_
		local v99_ = MathUtil.vector2Length(v97_, v98_)
		if v99_ == 0 then
			return math.huge
		end
		local v100_ = v97_ / v99_
		local v101_ = v98_ / v99_
		local v102_ = MathUtil.dotProduct(v93_, 0, v94_, v100_, 0, v101_)
		local v103_ = MathUtil.dotProduct(v95_, 0, v96_, v100_, 0, v101_)
		return math.acos(v102_) + math.acos(v103_)
	end
	if v104_(trapezoid1.line1[1], trapezoid1.line2[1], trapezoid2.line2[1], trapezoid1.line2[2]) > TrapezoidDecomposition.MAX_MERGE_ANGLE then
		return false
	else
		return v104_(trapezoid2.line2[2], trapezoid1.line2[2], trapezoid1.line1[2], trapezoid1.line2[1]) <= TrapezoidDecomposition.MAX_MERGE_ANGLE
	end
end
local function v_u_107_(p105_, p106_)
	return p105_[2] > p106_[2]
end

-- Upvalues: sortLineFunction
-- Local values: isPointIdentical, invalidPoints, detectInvalidPoints, boundaryPositions, trapezoidIndex, trapezoid, ti, trapezoid, points1, _, invalidPoint, alpha, points2, _, invalidPoint, alpha, getNextPoint, index, trapezoid, index, trapezoid, i, i
function TrapezoidDecomposition:generateBoundaryByGroupId(groupId, additionalGroupId)
	-- upvalues: (copy) v_u_107_
	local v_u_111_ = additionalGroupId or -1
	local v_u_112_ = {}
	local function v130_(p113_, p114_)
		-- upvalues: (copy) self, (copy) groupId, (ref) v_u_111_, (copy) v_u_112_
		for v115_ = 1, 2 do
			local v116_ = p114_[v115_]
			local v117_ = false
			for v118_ = 1, #self.trapezoids do
				if p113_ ~= v118_ then
					local v119_ = self.trapezoids[v118_]
					if v119_.groupId == groupId or v119_.groupId == v_u_111_ then
						for v120_ = 1, 2 do
							local v121_ = v119_.line1[v120_]
							local v122_ = v116_[1] - v121_[1]
							local v123_
							if math.abs(v122_) < 1e-7 then
								local v124_ = v116_[2] - v121_[2]
								v123_ = math.abs(v124_) < 1e-7
							else
								v123_ = false
							end
							if v123_ then
								v117_ = true
								break
							end
							local v125_ = v119_.line2[v120_]
							local v126_ = v116_[1] - v125_[1]
							local v127_
							if math.abs(v126_) < 1e-7 then
								local v128_ = v116_[2] - v125_[2]
								v127_ = math.abs(v128_) < 1e-7
							else
								v127_ = false
							end
							if v127_ then
								v117_ = true
								break
							end
						end
						if v117_ then
							break
						end
					end
				end
			end
			if not v117_ then
				local v129_ = v_u_112_
				table.insert(v129_, v116_)
			end
		end
	end
	local v_u_131_ = v_u_111_
	local v_u_132_ = {}
	for v133_ = 1, #self.trapezoids do
		local v134_ = self.trapezoids[v133_]
		if v134_.groupId == groupId or v134_.groupId == v_u_131_ then
			v130_(v133_, v134_.line1)
			v130_(v133_, v134_.line2)
		end
	end
	for v135_ = 1, #self.trapezoids do
		local v136_ = self.trapezoids[v135_]
		if v136_.groupId == groupId or v136_.groupId == v_u_131_ then
			local v137_ = nil
			for _, v138_ in ipairs(v_u_112_) do
				local v139_ = v136_.line1[1][1] - v138_[1]
				if math.abs(v139_) < 0.0001 then
					local v140_ = MathUtil.inverseLerp(v136_.line1[1][2], v136_.line1[2][2], v138_[2])
					if v140_ > 0 and v140_ < 1 then
						v137_ = v137_ == nil and {} or v137_
						local v141_ = table.clone
						table.insert(v137_, v141_(v138_))
					end
				end
			end
			local v142_ = nil
			for _, v143_ in ipairs(v_u_112_) do
				local v144_ = v136_.line2[1][1] - v143_[1]
				if math.abs(v144_) < 0.0001 then
					local v145_ = MathUtil.inverseLerp(v136_.line2[1][2], v136_.line2[2][2], v143_[2])
					if v145_ > 0 and v145_ < 1 then
						v142_ = v142_ == nil and {} or v142_
						local v146_ = table.clone
						table.insert(v142_, v146_(v143_))
					end
				end
			end
			if v137_ == nil then
				v136_.points1 = v136_.line1
			else
				local v147_ = v136_.line1[1]
				table.insert(v137_, v147_)
				local v148_ = v136_.line1[2]
				table.insert(v137_, v148_)
				table.sort(v137_, v_u_107_)
				v136_.points1 = v137_
			end
			if v142_ == nil then
				v136_.points2 = table.clone(v136_.line2, math.huge)
			else
				local v149_ = v136_.line2[1]
				table.insert(v142_, v149_)
				local v150_ = v136_.line2[2]
				table.insert(v142_, v150_)
				table.sort(v142_, v_u_107_)
				v136_.points2 = table.clone(v142_, math.huge)
			end
		end
	end
	local function v_u_176_(p151_, p152_, p153_, p154_)
		-- upvalues: (copy) v_u_132_, (copy) self, (copy) groupId, (ref) v_u_131_, (copy) v_u_176_
		local v155_ = p152_[1] - p153_[1]
		local v156_
		if math.abs(v155_) < 1e-7 then
			local v157_ = p152_[2] - p153_[2]
			v156_ = math.abs(v157_) < 1e-7
		else
			v156_ = false
		end
		if not v156_ or #v_u_132_ <= 0 then
			if not p154_ then
				local v158_ = v_u_132_
				table.insert(v158_, p152_)
			end
			p152_.detected = true
			for v159_ = 1, #self.trapezoids do
				if v159_ ~= p151_ then
					local v160_ = self.trapezoids[v159_]
					if v160_.groupId == groupId or v160_.groupId == v_u_131_ then
						for v161_ = 1, #v160_.points1 do
							local v162_ = v160_.points1[v161_]
							local v163_ = p152_[1] - v162_[1]
							local v164_
							if math.abs(v163_) < 1e-7 then
								local v165_ = p152_[2] - v162_[2]
								v164_ = math.abs(v165_) < 1e-7
							else
								v164_ = false
							end
							if v164_ and not v160_.points1[v161_].detected then
								return v_u_176_(v159_, v160_.points1[v161_], p153_, true)
							end
						end
						for v166_ = 1, #v160_.points2 do
							local v167_ = v160_.points2[v166_]
							local v168_ = p152_[1] - v167_[1]
							local v169_
							if math.abs(v168_) < 1e-7 then
								local v170_ = p152_[2] - v167_[2]
								v169_ = math.abs(v170_) < 1e-7
							else
								v169_ = false
							end
							if v169_ and not v160_.points2[v166_].detected then
								return v_u_176_(v159_, v160_.points2[v166_], p153_, true)
							end
						end
					end
				end
			end
			local v171_ = self.trapezoids[p151_]
			for v172_ = 1, #v171_.points1 do
				local v173_ = v171_.points1[v172_ + 1]
				if v173_ == nil then
					v173_ = v171_.points2[#v171_.points2]
				end
				if v171_.points1[v172_] == p152_ and not v173_.detected then
					return v_u_176_(p151_, v173_, p153_)
				end
			end
			for v174_ = #v171_.points2, 1, -1 do
				local v175_ = v171_.points2[v174_ - 1]
				if v175_ == nil then
					v175_ = v171_.points1[1]
				end
				if v171_.points2[v174_] == p152_ and not v175_.detected then
					return v_u_176_(p151_, v175_, p153_)
				end
			end
			return nil
		end
	end
	for v177_ = 1, #self.trapezoids do
		local v178_ = self.trapezoids[v177_]
		if v178_.groupId == groupId or v178_.groupId == v_u_131_ then
			v_u_176_(v177_, v178_.points1[1], v178_.points1[1])
			break
		end
	end
	for v179_ = 1, #self.trapezoids do
		local v180_ = self.trapezoids[v179_]
		if v180_.groupId == groupId or v180_.groupId == v_u_131_ then
			for v181_ = 1, #v180_.points1 do
				v180_.points1[v181_].detected = nil
			end
			for v182_ = 1, #v180_.points2 do
				v180_.points2[v182_].detected = nil
			end
		end
	end
	if #v_u_132_ <= 0 then
		return nil
	end
	local v183_ = table.clone
	local v184_ = v_u_132_[1]
	table.insert(v_u_132_, v183_(v184_))
	return v_u_132_
end

-- Local values: size, index, trapezoid
function TrapezoidDecomposition:getSizeByGroupId(groupId)
	local v187_ = 0
	for v188_ = 1, #self.trapezoids do
		local v189_ = self.trapezoids[v188_]
		if v189_.groupId == groupId then
			v187_ = v187_ + v189_.size
		end
	end
	return v187_
end

-- Local values: longestLine, index, trapezoid, length1, length2
function TrapezoidDecomposition:getLongestLineByGroupId(groupId)
	local v192_ = 0
	for v193_ = 1, #self.trapezoids do
		local v194_ = self.trapezoids[v193_]
		if v194_.groupId == groupId then
			local v195_ = MathUtil.vector2Length(v194_.line1[1][1] - v194_.line1[2][1], v194_.line1[1][2] - v194_.line1[2][2])
			local v196_ = MathUtil.vector2Length(v194_.line2[1][1] - v194_.line2[2][1], v194_.line2[1][2] - v194_.line2[2][2])
			v192_ = math.max(v192_, v195_, v196_)
		end
	end
	return v192_
end

-- Local values: isOverlapping, nextId, index1, isStandalone, index2, trapezoid1, trapezoid2, trapezoid1
function TrapezoidDecomposition:assignMergeGroups()
	local v198_ = 1
	local function v202_(p199_, p200_)
		local v201_ = p199_[1][1] - p200_[1][1]
		return math.abs(v201_) < 0.0001 and (p199_[1][2] > p200_[1][2] and p199_[1][2] < p200_[2][2] or p199_[2][2] > p200_[1][2] and p199_[2][2] < p200_[2][2])
	end
	for v203_ = 1, #self.trapezoids do
		local v204_ = true
		for v205_ = v203_ + 1, #self.trapezoids do
			local v206_ = self.trapezoids[v203_]
			local v207_ = self.trapezoids[v205_]
			if (v206_.line2 == v207_.line1 or v202_(v206_.line2, v207_.line1)) and TrapezoidDecomposition.getCanTrapezoidsBeMerged(v206_, v207_) then
				if v206_.groupId == 0 then
					v206_.groupId = v198_
					v198_ = v198_ + 1
				end
				v207_.groupId = v206_.groupId
				v204_ = false
			end
		end
		if v204_ then
			local v208_ = self.trapezoids[v203_]
			if v208_.groupId == 0 then
				v208_.groupId = v198_
				v198_ = v198_ + 1
			end
		end
	end
	self.numGroups = v198_ - 1
end

-- Local values: groupId, boundaryPositions, simplifiedBoundary, sumX, sumZ, numPositions, i, centerX, centerZ, yRot, group
function TrapezoidDecomposition:generateGroups()
	self.trapezoidGroups = {}
	for v210_ = 1, self.numGroups do
		local v211_ = self:generateBoundaryByGroupId(v210_)
		if v211_ ~= nil then
			local v212_ = table.clone(v211_)
			FieldCourseUtil.douglasPeucker(v212_, 0.01)
			local v213_ = #v211_
			local v214_ = 0
			local v215_ = 0
			for v216_ = 1, v213_ do
				v214_ = v214_ + v211_[v216_][1]
				v215_ = v215_ + v211_[v216_][2]
			end
			local v217_ = v214_ / v213_
			local v218_ = v215_ / v213_
			local v219_ = BoundaryLineGenerationTask.getOptimalBoundaryAngle(v217_, v218_, v212_, TrapezoidDecomposition.OPTIMAL_ANGLE_STEPS)
			local v220_ = {
				["positions"] = v211_,
				["simplifiedBoundary"] = v212_,
				["size"] = self:getSizeByGroupId(v210_),
				["longestLine"] = self:getLongestLineByGroupId(v210_),
				["center"] = { v217_, v218_ },
				["yRot"] = v219_
			}
			v220_.direction = { MathUtil.getDirectionFromYRotation(v220_.yRot) }
			self.trapezoidGroups[v210_] = v220_
		end
	end
end

-- Local values: group1, group2, color, indexToChange, trapezoidToChange
function TrapezoidDecomposition:mergeGroups(groupId1, groupId2)
	local v224_ = self.trapezoidGroups[groupId1]
	local v225_ = self.trapezoidGroups[groupId2]
	local v226_ = nil
	for v227_ = 1, #self.trapezoids do
		local v228_ = self.trapezoids[v227_]
		if v228_.groupId == groupId2 or v228_.groupId == groupId1 then
			if v226_ == nil then
				v226_ = v228_.color
			end
			v228_.groupId = groupId2
			v228_.color = v226_
		end
	end
	local v229_ = v225_.center
	local v230_ = v225_.center
	local v231_ = (v225_.center[1] + v224_.center[1]) * 0.5
	local v232_ = (v225_.center[2] + v224_.center[2]) * 0.5
	v229_[1] = v231_
	v230_[2] = v232_
	if v224_.size > v225_.size then
		v225_.yRot = v224_.yRot
		v225_.direction = v224_.direction
	end
	v225_.size = v225_.size + v224_.size
	local v233_ = v225_.longestLine
	local v234_ = v224_.longestLine
	v225_.longestLine = math.max(v233_, v234_)
	v225_.boundaryDirty = true
	self.trapezoidGroups[groupId1] = nil
end

-- Local values: index1, index2, trapezoid1, trapezoid2, size1, size2
function TrapezoidDecomposition:mergeGroupsBySize()
	for v236_ = 1, #self.trapezoids do
		for v237_ = v236_ + 1, #self.trapezoids do
			local v238_ = self.trapezoids[v236_]
			local v239_ = self.trapezoids[v237_]
			if v238_.groupId ~= v239_.groupId and (self.trapezoidGroups[v238_.groupId] ~= nil and self.trapezoidGroups[v239_.groupId] ~= nil) then
				local v240_ = v238_.line2[1][1] - v239_.line1[1][1]
				if math.abs(v240_) < 0.0001 then
					if self.singleGroupMode then
						self:mergeGroups(v238_.groupId, v239_.groupId)
					else
						local v241_ = self.trapezoidGroups[v238_.groupId].size
						local v242_ = self.trapezoidGroups[v239_.groupId].size
						if v241_ / v242_ < 0.2 then
							self:mergeGroups(v238_.groupId, v239_.groupId)
						elseif v242_ / v241_ < 0.2 then
							self:mergeGroups(v239_.groupId, v238_.groupId)
						end
					end
				end
			end
		end
	end
end

-- Local values: index1, index2, trapezoid1, trapezoid2, yRot1, yRot2, diff
function TrapezoidDecomposition:mergeGroupsByWorkDirection()
	for v244_ = 1, #self.trapezoids do
		for v245_ = v244_ + 1, #self.trapezoids do
			local v246_ = self.trapezoids[v244_]
			local v247_ = self.trapezoids[v245_]
			if v246_.groupId ~= v247_.groupId and (self.trapezoidGroups[v246_.groupId] ~= nil and self.trapezoidGroups[v247_.groupId] ~= nil) then
				local v248_ = v246_.line2[1][1] - v247_.line1[1][1]
				if math.abs(v248_) < 0.0001 then
					local v249_ = self.trapezoidGroups[v246_.groupId].yRot - self.trapezoidGroups[v247_.groupId].yRot
					local v250_ = math.abs(v249_)
					if v250_ < TrapezoidDecomposition.MAX_ORIENTATION_MERGE_DIFFERENCE or (6.283185307179586 - TrapezoidDecomposition.MAX_ORIENTATION_MERGE_DIFFERENCE < v250_ or 3.141592653589793 - TrapezoidDecomposition.MAX_ORIENTATION_MERGE_DIFFERENCE < v250_ and v250_ < 3.141592653589793 + TrapezoidDecomposition.MAX_ORIENTATION_MERGE_DIFFERENCE) then
						self:mergeGroups(v247_.groupId, v246_.groupId)
					end
				end
			end
		end
	end
end

-- Local values: index1, index2, trapezoid1, trapezoid2, sharedLineLength, sharedLinePct1, sharedLinePct2, group1, group2, combinedBoundaryPositions, boundaryPositions1, boundaryPositions2, numLinesGroup1, numLinesGroup2, numLinesCombined
function TrapezoidDecomposition:mergeGroupsByCost()
	for v252_ = 1, #self.trapezoids do
		for v253_ = v252_ + 1, #self.trapezoids do
			local v254_ = self.trapezoids[v252_]
			local v255_ = self.trapezoids[v253_]
			if v254_.groupId ~= v255_.groupId then
				local v256_ = v254_.line2[1][1] - v255_.line1[1][1]
				if math.abs(v256_) < 0.0001 then
					local v257_ = MathUtil.vector2Length(v254_.line2[1][1] - v254_.line2[2][1], v254_.line2[1][2] - v254_.line2[2][2])
					local v258_ = v257_ / self.trapezoidGroups[v254_.groupId].longestLine
					local v259_ = v257_ / self.trapezoidGroups[v255_.groupId].longestLine
					if TrapezoidDecomposition.MIN_MERGE_LENGTH_PERCENTAGE < v258_ or TrapezoidDecomposition.MIN_MERGE_LENGTH_PERCENTAGE < v259_ then
						local v260_ = self.trapezoidGroups[v254_.groupId]
						local v261_ = self.trapezoidGroups[v255_.groupId]
						if v260_ ~= nil and v261_ ~= nil then
							local v262_ = self:generateBoundaryByGroupId(v254_.groupId, v255_.groupId)
							local v263_ = self:generateBoundaryByGroupId(v254_.groupId)
							local v264_ = self:generateBoundaryByGroupId(v255_.groupId)
							if v262_ ~= nil and (v263_ ~= nil and v264_ ~= nil) then
								local v265_ = BoundaryLineGenerationTask.getNumLinesByAngle(v260_.center[1], v260_.center[2], v263_, v260_.yRot)
								local v266_ = BoundaryLineGenerationTask.getNumLinesByAngle(v261_.center[1], v261_.center[2], v264_, v261_.yRot)
								local v267_ = BoundaryLineGenerationTask.getNumLinesByAngle(v261_.center[1], v261_.center[2], v262_, v260_.yRot)
								if v265_ + v266_ - v267_ > math.min(v265_, v266_) * 0.2 then
									self:mergeGroups(v255_.groupId, v254_.groupId)
								else
									local v268_ = BoundaryLineGenerationTask.getNumLinesByAngle(v261_.center[1], v261_.center[2], v262_, v261_.yRot)
									if v265_ + v266_ - v268_ > math.min(v265_, v266_) * 0.2 then
										self:mergeGroups(v254_.groupId, v255_.groupId)
									end
								end
							end
						end
					end
				end
			end
		end
	end
end

-- Local values: groupId, group, yRot
function TrapezoidDecomposition:updateGroups()
	for v270_, v271_ in pairs(self.trapezoidGroups) do
		if v271_.boundaryDirty then
			v271_.positions = self:generateBoundaryByGroupId(v270_)
			v271_.simplifiedBoundary = table.clone(v271_.positions)
			FieldCourseUtil.douglasPeucker(v271_.simplifiedBoundary, 0.01)
			v271_.boundaryDirty = false
		end
		v271_.yRot = BoundaryLineGenerationTask.getOptimalBoundaryAngle(v271_.center[1], v271_.center[2], v271_.simplifiedBoundary, TrapezoidDecomposition.OPTIMAL_ANGLE_STEPS)
		local v272_ = v271_.direction
		local v273_ = v271_.direction
		local v274_, v275_ = MathUtil.getDirectionFromYRotation(v271_.yRot)
		v272_[1] = v274_
		v273_[2] = v275_
	end
end

function TrapezoidDecomposition:getGroups()
	return self.trapezoidGroups
end

-- Local values: y, _, trapezoid, _, trapezoid, color, vtx1, vtx2, vtx3, vtx4, groupId, groupBoundary, r, g, b, i, x1, z1, x2, z2, cx, cz, i, x1, z1, x2, z2
function TrapezoidDecomposition:draw()
	local v278_ = 0
	for _, v279_ in ipairs(self.trapezoids) do
		local v280_ = getTerrainHeightAtWorldPos
		local v281_ = g_terrainNode
		local v282_ = v279_.line1[1][1]
		local v283_ = v279_.line1[1][2]
		local v284_ = math.max(v278_, v280_(v281_, v282_, 0, v283_))
		local v285_ = getTerrainHeightAtWorldPos
		local v286_ = g_terrainNode
		local v287_ = v279_.line2[1][1]
		local v288_ = v279_.line2[1][2]
		local v289_ = math.max(v284_, v285_(v286_, v287_, 0, v288_))
		local v290_ = getTerrainHeightAtWorldPos
		local v291_ = g_terrainNode
		local v292_ = v279_.line1[2][1]
		local v293_ = v279_.line1[2][2]
		local v294_ = math.max(v289_, v290_(v291_, v292_, 0, v293_))
		local v295_ = getTerrainHeightAtWorldPos
		local v296_ = g_terrainNode
		local v297_ = v279_.line2[2][1]
		local v298_ = v279_.line2[2][2]
		v278_ = math.max(v294_, v295_(v296_, v297_, 0, v298_))
	end
	local v299_ = v278_ + 0.5
	for _, v300_ in ipairs(self.trapezoids) do
		local v301_ = TrapezoidDecomposition.COLORS[v300_.groupId % #TrapezoidDecomposition.COLORS + 1]
		local v302_ = v300_.line1[1]
		local v303_ = v300_.line2[1]
		local v304_ = v300_.line1[2]
		local v305_ = v300_.line2[2]
		drawDebugTriangle(v302_[1], v299_ + 0.05, v302_[2], v303_[1], v299_ + 0.05, v303_[2], v304_[1], v299_ + 0.05, v304_[2], v301_[1], v301_[2], v301_[3], 0.1, false)
		drawDebugLine(v302_[1], v299_ + 0.05, v302_[2], v301_[1], v301_[2], v301_[3], v303_[1], v299_ + 0.05, v303_[2], v301_[1], v301_[2], v301_[3], true)
		drawDebugLine(v304_[1], v299_ + 0.05, v304_[2], v301_[1], v301_[2], v301_[3], v305_[1], v299_ + 0.05, v305_[2], v301_[1], v301_[2], v301_[3], true)
		local v306_ = v300_.line2[1]
		local v307_ = v300_.line2[2]
		local v308_ = v300_.line1[2]
		local v309_ = v300_.line1[1]
		drawDebugTriangle(v306_[1], v299_ + 0.05, v306_[2], v307_[1], v299_ + 0.05, v307_[2], v308_[1], v299_ + 0.05, v308_[2], v301_[1], v301_[2], v301_[3], 0.1, false)
		drawDebugLine(v306_[1], v299_ + 0.05, v306_[2], v301_[1], v301_[2], v301_[3], v307_[1], v299_ + 0.05, v307_[2], v301_[1], v301_[2], v301_[3], true)
		drawDebugLine(v308_[1], v299_ + 0.05, v308_[2], v301_[1], v301_[2], v301_[3], v309_[1], v299_ + 0.05, v309_[2], v301_[1], v301_[2], v301_[3], true)
		drawDebugPoint(v306_[1], v299_ + 0.05, v306_[2], v301_[1], v301_[2], v301_[3], 1, false)
		drawDebugPoint(v307_[1], v299_ + 0.05, v307_[2], v301_[1], v301_[2], v301_[3], 1, false)
		drawDebugPoint(v308_[1], v299_ + 0.05, v308_[2], v301_[1], v301_[2], v301_[3], 1, false)
		drawDebugPoint(v309_[1], v299_ + 0.05, v309_[2], v301_[1], v301_[2], v301_[3], 1, false)
	end
	for v310_, v311_ in pairs(self.trapezoidGroups) do
		local v312_ = v310_ / 5
		local v313_ = 1 - v310_ / 5
		for v314_ = 1, #v311_.simplifiedBoundary - 1 do
			local v315_ = v311_.simplifiedBoundary[v314_][1]
			local v316_ = v311_.simplifiedBoundary[v314_][2]
			local v317_ = v311_.simplifiedBoundary[v314_ + 1][1]
			local v318_ = v311_.simplifiedBoundary[v314_ + 1][2]
			drawDebugLine(v315_, v299_, v316_, v312_, v313_, 1, v317_, v299_, v318_, v312_, v313_, 1, true)
			Utils.renderTextAtWorldPosition(v315_, v299_, v316_, string.format("%d", v314_), 0.015, 0, 0, 1, 1, 1)
		end
		local v319_ = v311_.center[1]
		local v320_ = v311_.center[2]
		Utils.renderTextAtWorldPosition(v319_, v299_, v320_, string.format("group%d", v310_), 0.015, 0, 0, 1, 1, 1)
		drawDebugLine(v319_, v299_, v320_, 0, 1, 0, v319_ + v311_.direction[1] * 10, v299_, v320_ + v311_.direction[2] * 10, 0, 1, 0, true)
	end
	for v321_ = 1, #self.boundary - 1 do
		local v322_ = self.boundary[v321_][1]
		local v323_ = self.boundary[v321_][2]
		local v324_ = self.boundary[v321_ + 1][1]
		local v325_ = self.boundary[v321_ + 1][2]
		drawDebugLine(v322_, v299_, v323_, 1, 0, 0, v324_, v299_, v325_, 1, 0, 0, true)
	end
end

-- Local values: minDistance, minDistanceIntersectionX, minDistanceIntersectionZ, posIndex, p1, p2, lDirX, lDirZ, length, intersect, t1, t2, pX, pZ, distance
function TrapezoidDecomposition.getClosestIntersectionWithBoundary(position, dirX, dirZ, boundary)
	local v330_ = math.huge
	local v331_ = nil
	local v332_ = nil
	for v333_ = 1, #boundary - 1 do
		local v334_ = boundary[v333_]
		local v335_ = boundary[v333_ + 1]
		if position ~= v334_ and position ~= v335_ then
			local v336_ = v335_[1] - v334_[1]
			local v337_ = v335_[2] - v334_[2]
			local v338_ = MathUtil.vector2Length(v336_, v337_)
			local v339_ = v336_ / v338_
			local v340_ = v337_ / v338_
			local v341_, v342_, v343_ = MathUtil.getLineLineIntersection2D(position[1], position[2], dirX, dirZ, v334_[1], v334_[2], v339_, v340_)
			if v341_ and (v342_ > 0 and (v343_ >= 0 and v343_ <= v338_)) then
				local v344_ = v334_[1] + v339_ * v343_
				local v345_ = v334_[2] + v340_ * v343_
				local v346_ = MathUtil.vector2Length(position[1] - v344_, position[2] - v345_)
				if v346_ > 0.1 and (FieldCourseUtil.getIsSegmentInsideBoundary(position[1], position[2], v344_, v345_, boundary) and v346_ < v330_) then
					v332_ = v345_
					v331_ = v344_
					v330_ = v346_
				end
			end
		end
	end
	return v331_, v332_
end

-- Local values: sx, sz, ex, ez, _, otherLine
function TrapezoidDecomposition.getIsNeighbouringLine(line1, line2, boundary, otherLines)
	local v351_ = (line1[1][1] + line1[2][1]) * 0.5
	local v352_ = (line1[1][2] + line1[2][2]) * 0.5
	local v353_ = (line2[1][1] + line2[2][1]) * 0.5
	local v354_ = (line2[1][2] + line2[2][2]) * 0.5
	if not FieldCourseUtil.getIsSegmentInsideBoundary(v351_, v352_, v353_, v354_, boundary) then
		return false
	end
	for _, v355_ in ipairs(otherLines) do
		if v355_ ~= line1 and (v355_ ~= line2 and MathUtil.getLineSegmentsIntersection(v351_, v352_, v353_, v354_, v355_[1][1], v355_[1][2], v355_[2][1], v355_[2][2])) then
			return false
		end
	end
	return true
end

-- Local values: width, height
function TrapezoidDecomposition.getTrapezoidSize(line1, line2)
	local v358_ = line1[1][1] - line2[1][1]
	return math.abs(v358_) * ((line1[1][2] - line1[2][2] + (line2[1][2] - line2[2][2])) * 0.5)
end
