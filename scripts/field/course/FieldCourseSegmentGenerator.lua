-- Local values: FieldCourseSegmentGenerator_mt
FieldCourseSegmentGenerator = {}
local FieldCourseSegmentGenerator_mt = Class(FieldCourseSegmentGenerator)

-- Upvalues: FieldCourseSegmentGenerator_mt
-- Local values: self
function FieldCourseSegmentGenerator.new(fieldCourseSettings, callback)
	-- upvalues: (copy) FieldCourseSegmentGenerator_mt
	local v4_ = FieldCourseSegmentGenerator_mt
	local v5_ = setmetatable({}, v4_)
	v5_.fieldCourseSettings = fieldCourseSettings
	v5_.callback = callback
	v5_.state = FieldCourseGenerationState.FIELD_DETECTION
	v5_.frameBudget = 0.00025
	v5_.numHeadlandsToCreate = fieldCourseSettings.numHeadlands
	v5_.headlandOnly = false
	v5_.skipHeadland = false
	v5_.isVineyardCourse = false
	v5_.isUICourse = false
	v5_.headlandBoundaries = {}
	v5_.linesByGroup = {}
	v5_.boundaryByGroup = {}
	v5_.boundaryLineGenerationTasks = {}
	v5_.currentOverlapLineIndex = 1
	return v5_
end

function FieldCourseSegmentGenerator:setStartPosition(x, z)
	self.x = x
	self.z = z
end

function FieldCourseSegmentGenerator:setIsUICourse()
	self.isUICourse = true
end

function FieldCourseSegmentGenerator:setFieldData(courseField)
	self.courseField = courseField
	self.islands = courseField.islands
	self.headlandBoundaries = courseField.headlandBoundaries
	self.fieldRootBoundary = courseField.fieldRootBoundary
	self.state = FieldCourseGenerationState.VINEYARD_DETECTION
end

function FieldCourseSegmentGenerator:setHeadlandSettings(headlandOnly, skipHeadland)
	self.headlandOnly = headlandOnly
	self.skipHeadland = skipHeadland
end

function FieldCourseSegmentGenerator:generate()
	g_fieldCourseManager:addFieldCourseToGenerate(self)
	if self.courseField == nil then
		if self.x == nil or self.z == nil then
			self.state = FieldCourseGenerationState.INVALID
			self:finish()
		else
			self.state = FieldCourseGenerationState.FIELD_DETECTION
			self.courseField = FieldCourseField.generateAtPosition(self.x, self.z, self.fieldCourseSettings, function(p16_, p17_)
				-- upvalues: (copy) self
				if p17_ then
					self:setFieldData(p16_)
				else
					self.state = FieldCourseGenerationState.INVALID
					self:finish()
				end
			end)
		end
	else
		self.state = FieldCourseGenerationState.VINEYARD_DETECTION
		return
	end
end

-- Local values: singleGroupMode, baseBoundary, trapezoidGroups, groupId, group, callback, task, i, sideOffset, offsetStep, startTime, isValid, groupIndex, lines, line, positions, endTime, rootBoundary, groupIndex, lines, _, line, boundaryLine
function FieldCourseSegmentGenerator:update(dt)
	if self.state == FieldCourseGenerationState.FIELD_DETECTION then
		self.courseField:update(dt, self.frameBudget)
	elseif self.state == FieldCourseGenerationState.VINEYARD_DETECTION then
		if self:doVineyardDetection() then
			self.state = FieldCourseGenerationState.FINISHED
		else
			self.state = FieldCourseGenerationState.HEADLAND_CREATION
		end
	elseif self.state == FieldCourseGenerationState.HEADLAND_CREATION then
		if not self:generateNextHeadland() then
			if #self.headlandBoundaries == 0 then
				self.state = FieldCourseGenerationState.INVALID
			elseif self.headlandOnly then
				self.state = FieldCourseGenerationState.FINISHED
			else
				self.state = FieldCourseGenerationState.SUB_AREA_DETECTION
				local v20_ = self.fieldCourseSettings.workDirection >= -0.01
				local v21_ = self.headlandBoundaries[#self.headlandBoundaries] or self.innerBoundary
				self.trapezoidDecomposition = TrapezoidDecomposition.new(v21_.boundaryLine, v20_)
			end
		end
	elseif self.state == FieldCourseGenerationState.SUB_AREA_DETECTION then
		if not self.trapezoidDecomposition:update(dt, self.frameBudget) then
			self.state = FieldCourseGenerationState.SUB_AREA_PATH_CREATION
			local v22_ = self.trapezoidDecomposition:getGroups()
			for v_u_23_, v_u_24_ in pairs(v22_) do
				local v26_ = BoundaryLineGenerationTask.new(v_u_24_.simplifiedBoundary, v_u_24_.center[1], v_u_24_.center[2], v_u_24_.direction[1], v_u_24_.direction[2], self.islands, self.fieldCourseSettings, function(p25_)
					-- upvalues: (copy) self, (copy) v_u_23_, (copy) v_u_24_
					self.linesByGroup[v_u_23_] = p25_
					self.boundaryByGroup[v_u_23_] = v_u_24_.simplifiedBoundary
				end)
				local v27_ = self.boundaryLineGenerationTasks
				table.insert(v27_, v26_)
			end
			self.trapezoidDecomposition = nil
		end
	elseif self.state == FieldCourseGenerationState.SUB_AREA_PATH_CREATION then
		for v28_ = #self.boundaryLineGenerationTasks, 1, -1 do
			if not self.boundaryLineGenerationTasks[v28_]:update(dt, self.frameBudget) then
				table.remove(self.boundaryLineGenerationTasks, v28_)
			end
		end
		if #self.boundaryLineGenerationTasks == 0 then
			if self.isUICourse then
				self.state = FieldCourseGenerationState.FINISHED
			elseif self.fieldCourseSettings.segmentExtendedToBoundary then
				self.state = FieldCourseGenerationState.SEGMENT_TO_BOUNDARY_EXTENSION
			else
				self.state = FieldCourseGenerationState.LINE_OVERLAP_CHECKS
			end
		end
	elseif self.state == FieldCourseGenerationState.LINE_OVERLAP_CHECKS then
		local v29_ = self.fieldCourseSettings.implementWidth * 0.5
		local v30_ = self.fieldCourseSettings.implementWidth * 0.1
		local v31_ = getTimeSec()
		local v32_ = false
		while true do
			for v33_, v34_ in pairs(self.linesByGroup) do
				local v35_ = v34_[self.currentOverlapLineIndex]
				if v35_ ~= nil then
					local v36_ = v35_.positions
					FieldCourseUtil.shrinkSegmentUntilOverlap(self.linesByGroup, self.islands, self.headlandBoundaries, v33_, v36_, -1, v29_, v29_, v30_)
					FieldCourseUtil.shrinkSegmentUntilOverlap(self.linesByGroup, self.islands, self.headlandBoundaries, v33_, v36_, 1, v29_, v29_, v30_)
					FieldCourseUtil.extendSegmentUntilOverlap(self.linesByGroup, self.islands, self.headlandBoundaries, v33_, v36_, -1, v29_, v29_, v30_)
					FieldCourseUtil.extendSegmentUntilOverlap(self.linesByGroup, self.islands, self.headlandBoundaries, v33_, v36_, 1, v29_, v29_, v30_)
					v32_ = true
				end
			end
			if not v32_ then
				break
			end
			self.currentOverlapLineIndex = self.currentOverlapLineIndex + 1
			if getTimeSec() - v31_ > self.frameBudget then
				break
			end
		end
		if not v32_ then
			self.state = FieldCourseGenerationState.FINISHED
		end
	elseif self.state == FieldCourseGenerationState.SEGMENT_TO_BOUNDARY_EXTENSION then
		local v37_ = self.headlandBoundaries[#self.headlandBoundaries] or self.fieldRootBoundary
		for v38_, v39_ in pairs(self.linesByGroup) do
			for _, v40_ in ipairs(v39_) do
				local v41_ = self.boundaryByGroup[v38_] or v37_.boundaryLine
				FieldCourseSegmentGenerator.extendSegmentToBoundary(v40_.positions, v41_, self.islands)
			end
		end
		self.state = FieldCourseGenerationState.FINISHED
	end
	if self:getHasFinished() then
		self:finish()
	end
end

-- Local values: baseBoundary, _, island, i, i, baseIslandBoundary, i, i, headlandBoundary, _, island, baseBoundary, offset, offsetBoundary, _, island, islandOffsetBoundary, _, otherIsland, _, otherBoundary, lastMainBoundary
function FieldCourseSegmentGenerator:generateNextHeadland()
	if self.numHeadlandsToCreate <= 0 then
		local v43_ = self.headlandBoundaries[#self.headlandBoundaries] or self.fieldRootBoundary
		self.innerBoundary = v43_:extend(self.fieldCourseSettings.implementWidth * 0.5) or v43_
		for _, v44_ in ipairs(self.islands) do
			for v45_ = #v44_.boundaries, 1, -1 do
				if v45_ > 1 and self.innerBoundary:isInsideOf(v44_.boundaries[v45_]) then
					v44_.boundaries[v45_] = nil
				end
			end
			for v46_ = #v44_.boundaries, 1, -1 do
				if v44_.boundaries[v46_]:removeCollidingSegments(self.fieldRootBoundary, self.fieldCourseSettings.implementWidth * 0.5) then
					if not v44_.boundaries[v46_]:isValid() then
						table.remove(v44_.boundaries, v46_)
					end
					v44_.hasCutSegments = true
				end
			end
			if (v44_.boundaries[#v44_.boundaries] or v44_.rootBoundary):isColliding(self.innerBoundary) and #v44_.boundaries > 0 then
				for v47_ = #v44_.boundaries, 1, -1 do
					if v47_ > 1 and v44_.boundaries[v47_]:isColliding(self.innerBoundary) then
						v44_.boundaries[v47_] = nil
					end
				end
			end
			v44_.validPathBoundary = v44_.boundaries[1] or v44_.rootBoundary
			v44_.innerBoundary = v44_.validPathBoundary
		end
		for _, v48_ in ipairs(self.headlandBoundaries) do
			for _, v49_ in ipairs(self.islands) do
				v48_:cut(v49_.innerBoundary)
			end
		end
		return false
	end
	local v50_ = (self.headlandBoundaries[#self.headlandBoundaries] or self.fieldRootBoundary):extend(#self.headlandBoundaries == 0 and self.fieldCourseSettings.implementWidth * 0.5 or self.fieldCourseSettings.implementWidth)
	if v50_ == nil then
		self.numHeadlandsToCreate = 0
	else
		local v51_ = self.headlandBoundaries
		table.insert(v51_, v50_)
	end
	if self.numHeadlandsToCreate > 0 then
		for _, v52_ in ipairs(self.islands) do
			local v53_ = (v52_.boundaries[#v52_.boundaries] or v52_.rootBoundary):extend(#v52_.boundaries == 0 and -self.fieldCourseSettings.implementWidth * 0.5 or -self.fieldCourseSettings.implementWidth)
			if v53_ ~= nil then
				for _, v54_ in ipairs(self.islands) do
					if v54_ ~= v52_ then
						for _, v55_ in ipairs(v54_.boundaries) do
							if v55_:isColliding(v53_) then
								v53_ = nil
								break
							end
						end
						if v53_ == nil then
							break
						end
					end
				end
				if v53_ ~= nil and #v52_.boundaries > 0 then
					if (self.headlandBoundaries[#self.headlandBoundaries] or self.fieldRootBoundary):isColliding(v53_) then
						v53_ = nil
					end
				end
				if v53_ ~= nil then
					local v56_ = v52_.boundaries
					table.insert(v56_, v53_)
				end
			end
		end
	end
	self.numHeadlandsToCreate = self.numHeadlandsToCreate - 1
	return true
end

function FieldCourseSegmentGenerator:getHasFinished()
	return self.state == FieldCourseGenerationState.FINISHED and true or self.state == FieldCourseGenerationState.INVALID
end

-- Local values: segments, groupIndex, lines, i, segment, islandIndex, island, headlandIndex, islandBoundary, i, headlandIndex, headlandBoundary, i, segmentIndex, segment, segmentIndex, segment
function FieldCourseSegmentGenerator:finish()
	local v59_ = {}
	if self.state == FieldCourseGenerationState.FINISHED then
		if self.fieldCourseSettings.segmentHeadlandReverseLines then
			self:doHeadlandReverseSegmentExtension(-1)
		end
		for v60_, v61_ in pairs(self.linesByGroup) do
			for v62_ = 1, #v61_ do
				local v63_ = v61_[v62_]
				v63_.lineGroupIndex = v60_
				v63_.isHeadlandSegment = false
				v63_.isIslandSegment = false
				table.insert(v59_, v63_)
			end
		end
		if not self.skipHeadland then
			for v64_, v65_ in ipairs(self.islands) do
				for v66_, v67_ in ipairs(v65_.boundaries) do
					for v68_ = 1, #v67_.segments do
						v67_.segments[v68_].isHeadlandSegment = false
						v67_.segments[v68_].isIslandSegment = true
						v67_.segments[v68_].islandIndex = v64_
						v67_.segments[v68_].headlandIndex = v66_
						local v69_ = v67_.segments[v68_]
						table.insert(v59_, v69_)
					end
				end
			end
			for v70_, v71_ in ipairs(self.headlandBoundaries) do
				for v72_ = 1, #v71_.segments do
					v71_.segments[v72_].isHeadlandSegment = true
					v71_.segments[v72_].isIslandSegment = false
					v71_.segments[v72_].headlandIndex = v70_
					local v73_ = v71_.segments[v72_]
					table.insert(v59_, v73_)
				end
			end
		end
		for v74_ = #v59_, 1, -1 do
			local v75_ = v59_[v74_]
			FieldCourseUtil.extendSegmentPositions(v75_, self.fieldCourseSettings.toolFrontOffset)
		end
		for v76_ = #v59_, 1, -1 do
			local v77_ = v59_[v76_]
			v77_.length = FieldCourseUtil.getSegmentLength(v77_.positions)
			if v77_.lineGroupIndex ~= nil and v77_.length < FieldCourse.MIN_SEGMENT_LENGTH then
				table.remove(v59_, v76_)
			end
		end
	end
	if self.callback ~= nil then
		self.callback(v59_, self.courseField, self.isVineyardCourse)
	end
end

-- Local values: boundary, placeables, _, placeable, anyVineInsideBoundary, i, segment, group, sideOffset, i, segment, dx, dz, sx, sz, ex, ez, sx, sz, ex, ez, i, line, x1, z1, x2, z2, dx, dz, length, j, otherLine, x3, z3, x4, z4, dot1, px, pz, sideOffset, dot2, lines, i, line
function FieldCourseSegmentGenerator:doVineyardDetection()
	if g_currentMission.placeableSystem == nil then
		return false
	end
	local v79_ = self.fieldRootBoundary.boundaryLine
	local v80_ = g_currentMission.placeableSystem.placeables
	for _, v81_ in ipairs(v80_) do
		if v81_.spec_vine ~= nil and v81_.spec_fence ~= nil then
			local v82_ = false
			for _, v83_ in pairs(v81_.spec_fence.segments) do
				if FieldCourseUtil.getIsPointInsideBoundary(v83_.x1, v83_.z1, v79_) or FieldCourseUtil.getIsPointInsideBoundary(v83_.x2, v83_.z2, v79_) then
					v82_ = true
					break
				end
			end
			if v82_ then
				local v84_ = not self.fieldCourseSettings.isVineyardRowTool and 0 or v81_:getSnapDistance() * 0.5
				local v85_ = {}
				for _, v86_ in pairs(v81_.spec_fence.segments) do
					if FieldCourseUtil.getIsPointInsideBoundary(v86_.x1, v86_.z1, v79_) or FieldCourseUtil.getIsPointInsideBoundary(v86_.x2, v86_.z2, v79_) then
						local v87_ = v86_.x2 - v86_.x1
						local v88_ = v86_.z2 - v86_.z1
						local v89_, v90_ = MathUtil.vector2Normalize(v87_, v88_)
						local v91_ = v86_.x1 + v90_ * v84_
						local v92_ = v86_.z1 - v89_ * v84_
						local v93_ = v86_.x2 + v90_ * v84_
						local v94_ = v86_.z2 - v89_ * v84_
						local v95_ = {
							{ v91_ - v89_ * 2, v92_ - v90_ * 2 },
							{ v93_ + v89_ * 2, v94_ + v90_ * 2 }
						}
						table.insert(v85_, v95_)
						local v96_ = v86_.x1 - v90_ * v84_
						local v97_ = v86_.z1 + v89_ * v84_
						local v98_ = v86_.x2 - v90_ * v84_
						local v99_ = v86_.z2 + v89_ * v84_
						local v100_ = {
							{ v96_ - v89_ * 2, v97_ - v90_ * 2 },
							{ v98_ + v89_ * 2, v99_ + v90_ * 2 }
						}
						table.insert(v85_, v100_)
					end
				end
				for v101_ = #v85_, 1, -1 do
					local v102_ = v85_[v101_]
					if v102_ ~= nil then
						local v103_ = v102_[1][1]
						local v104_ = v102_[1][2]
						local v105_ = v102_[2][1]
						local v106_ = v102_[2][2]
						local v107_ = v105_ - v103_
						local v108_ = v106_ - v104_
						local v109_ = MathUtil.vector2Length(v107_, v108_)
						local v110_ = v107_ / v109_
						local v111_ = v108_ / v109_
						for v112_ = #v85_, 1, -1 do
							if v112_ ~= v101_ then
								local v113_ = v85_[v112_]
								local v114_ = v113_[1][1]
								local v115_ = v113_[1][2]
								local v116_ = v113_[2][1]
								local v117_ = v113_[2][2]
								local v118_ = MathUtil.getProjectOnLineParameter(v114_, v115_, v103_, v104_, v110_, v111_)
								local v119_ = v103_ + v110_ * v118_
								local v120_ = v104_ + v111_ * v118_
								if MathUtil.vector2Length(v119_ - v114_, v120_ - v115_) < 0.01 then
									local v121_ = MathUtil.getProjectOnLineParameter(v116_, v117_, v103_, v104_, v110_, v111_)
									if v118_ >= -0.25 and (v118_ <= v109_ + 0.25 and (v121_ >= -0.25 and v121_ <= v109_ + 0.25)) then
										table.remove(v85_, v112_)
									elseif v118_ >= -0.25 and v118_ <= v109_ + 0.25 then
										if v109_ < v121_ then
											local v122_ = v102_[2]
											local v123_ = v102_[2]
											v122_[1] = v116_
											v123_[2] = v117_
											v109_ = MathUtil.vector2Length(v116_ - v103_, v117_ - v104_)
											v105_ = v116_
											v106_ = v117_
										elseif v121_ < 0 then
											local v124_ = v102_[1]
											local v125_ = v102_[1]
											v124_[1] = v116_
											v125_[2] = v117_
											v109_ = MathUtil.vector2Length(v105_ - v116_, v106_ - v117_)
											v103_ = v116_
											v104_ = v117_
										end
									elseif v121_ >= -0.25 and v121_ <= v109_ + 0.25 then
										if v118_ < 0 then
											local v126_ = v102_[1]
											local v127_ = v102_[1]
											v126_[1] = v114_
											v127_[2] = v115_
											v109_ = MathUtil.vector2Length(v105_ - v114_, v106_ - v115_)
											v103_ = v114_
											v104_ = v115_
										elseif v109_ < v121_ then
											local v128_ = v102_[2]
											local v129_ = v102_[2]
											v128_[1] = v114_
											v129_[2] = v115_
											v109_ = MathUtil.vector2Length(v114_ - v103_, v115_ - v104_)
											v105_ = v114_
											v106_ = v115_
										end
									end
								end
							end
						end
					end
				end
				if #v85_ > 0 then
					local v130_ = {}
					for v131_ = 1, #v85_ do
						local v132_ = {
							["positions"] = v85_[v131_]
						}
						table.insert(v130_, v132_)
					end
					local v133_ = self.linesByGroup
					table.insert(v133_, v130_)
				end
			end
		end
	end
	if #self.linesByGroup <= 0 then
		return false
	end
	self.isVineyardCourse = true
	return true
end

-- Local values: maxDistance, headlandIndex, headlandBoundary, i, segment, prevSegment, x1, z1, x2, z2, dirX, dirZ, numPositions, x3, z3, x4, z4, nextDirX, nextDirZ, angle
function FieldCourseSegmentGenerator:doHeadlandReverseSegmentExtension(direction)
	local v136_ = self.fieldCourseSettings.implementWidth ^ 2 + self.fieldCourseSettings.implementWidth ^ 2
	local v137_ = math.sqrt(v136_)
	for _, v138_ in ipairs(self.headlandBoundaries) do
		for v139_ = 1, #v138_.segments do
			local v140_ = v138_.segments[v139_]
			local v141_ = v138_.segments[v139_ - 1]
			if v141_ == nil then
				v141_ = v138_.segments[#v138_.segments]
			end
			local v142_ = v140_.positions[1][1]
			local v143_ = v140_.positions[1][2]
			local v144_ = v140_.positions[2][1]
			local v145_ = v140_.positions[2][2]
			local v146_, v147_ = MathUtil.vector2Normalize(v144_ - v142_, v145_ - v143_)
			local v148_ = #v141_.positions
			local v149_ = v141_.positions[v148_ - 1][1]
			local v150_ = v141_.positions[v148_ - 1][2]
			local v151_ = v141_.positions[v148_][1]
			local v152_ = v141_.positions[v148_][2]
			local v153_, v154_ = MathUtil.vector2Normalize(v151_ - v149_, v152_ - v150_)
			local v155_ = FieldCourseUtil.vector2Dot(v146_, v147_, v153_, v154_)
			if math.acos(v155_) > 0.7853981633974483 then
				if direction == nil or direction == 1 then
					FieldCourseUtil.extendSegmentToBoundary(v140_.positions, self.fieldRootBoundary.boundaryLine, true, false, v137_)
				else
					FieldCourseUtil.extendSegmentToBoundary(v141_.positions, self.fieldRootBoundary.boundaryLine, false, true, v137_)
				end
			end
		end
	end
end

-- Local values: getSegmentClosestBoundariesIntersection, p1, p2, dirX, dirZ, length, intersect1, ix1, iz1, extensionLength, extensionLength
function FieldCourseSegmentGenerator.extendSegmentToBoundary(positions, boundary, islands, maxDistance)
	local v160_ = maxDistance or math.huge
	local function v188_(p161_, p162_, p163_, p164_)
		-- upvalues: (copy) boundary, (copy) islands
		local v165_ = math.huge
		local v166_ = nil
		local v167_ = nil
		for v168_ = 1, #boundary - 1 do
			local v169_ = boundary[v168_][1]
			local v170_ = boundary[v168_][2]
			local v171_ = boundary[v168_ + 1][1]
			local v172_ = boundary[v168_ + 1][2]
			local v173_, v174_, v175_ = MathUtil.getLineSegmentsIntersection(v169_, v170_, v171_, v172_, p161_, p162_, p163_, p164_)
			if v173_ then
				local v176_ = MathUtil.vector2Length(p161_ - v174_, p162_ - v175_)
				if v176_ < v165_ then
					v167_ = v175_
					v166_ = v174_
					v165_ = v176_
				end
			end
		end
		for _, v177_ in ipairs(islands) do
			local v178_ = v177_.boundaries[#v177_.boundaries] or v177_.rootBoundary
			if v178_ ~= nil then
				for v179_ = 1, #v178_.boundaryLine - 1 do
					local v180_ = v178_.boundaryLine[v179_][1]
					local v181_ = v178_.boundaryLine[v179_][2]
					local v182_ = v178_.boundaryLine[v179_ + 1][1]
					local v183_ = v178_.boundaryLine[v179_ + 1][2]
					local v184_, v185_, v186_ = MathUtil.getLineSegmentsIntersection(v180_, v181_, v182_, v183_, p161_, p162_, p163_, p164_)
					if v184_ then
						local v187_ = MathUtil.vector2Length(p161_ - v185_, p162_ - v186_)
						if v187_ < v165_ then
							v167_ = v186_
							v166_ = v185_
							v165_ = v187_
						end
					end
				end
			end
		end
		return v165_ ~= math.huge, v166_, v167_
	end
	local v189_ = positions[1]
	local v190_ = positions[2]
	local v191_ = v189_[1] - v190_[1]
	local v192_ = v189_[2] - v190_[2]
	local v193_ = MathUtil.vector2Length(v191_, v192_)
	local v194_ = v191_ / v193_
	local v195_ = v192_ / v193_
	local v196_, v197_, v198_ = v188_(v189_[1] - v194_ * 0.1, v189_[2] - v195_ * 0.1, v189_[1] + v194_ * 65535, v189_[2] + v195_ * 65535)
	if v196_ and MathUtil.vector2Length(v197_ - v189_[1], v198_ - v189_[2]) < v160_ then
		v189_[1] = v197_
		v189_[2] = v198_
	end
	local v199_ = positions[#positions]
	local v200_ = positions[#positions - 1]
	local v201_ = v199_[1] - v200_[1]
	local v202_ = v199_[2] - v200_[2]
	local v203_ = MathUtil.vector2Length(v201_, v202_)
	local v204_ = v201_ / v203_
	local v205_ = v202_ / v203_
	local v206_, v207_, v208_ = v188_(v199_[1] - v204_ * 0.1, v199_[2] - v205_ * 0.1, v199_[1] + v204_ * 65535, v199_[2] + v205_ * 65535)
	if v206_ and MathUtil.vector2Length(v207_ - v199_[1], v208_ - v199_[2]) < v160_ then
		v199_[1] = v207_
		v199_[2] = v208_
	end
end
