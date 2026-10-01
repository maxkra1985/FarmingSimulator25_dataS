FieldCourseSegmentGenerator = {}
local FieldCourseSegmentGenerator_mt = Class(FieldCourseSegmentGenerator)
function FieldCourseSegmentGenerator.new(fieldCourseSettings, callback)
	local self = setmetatable({}, FieldCourseSegmentGenerator_mt)
	self.fieldCourseSettings = fieldCourseSettings
	self.callback = callback
	self.state = FieldCourseGenerationState.FIELD_DETECTION
	self.frameBudget = 0.00025
	self.numHeadlandsToCreate = fieldCourseSettings.numHeadlands
	self.headlandOnly = false
	self.skipHeadland = false
	self.isVineyardCourse = false
	self.isUICourse = false
	self.headlandBoundaries = {}
	self.linesByGroup = {}
	self.boundaryByGroup = {}
	self.boundaryLineGenerationTasks = {}
	self.currentOverlapLineIndex = 1
	return self
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
			return
		end
		self.state = FieldCourseGenerationState.FIELD_DETECTION
		self.courseField = FieldCourseField.generateAtPosition(self.x, self.z, self.fieldCourseSettings, function(courseField, success)
			if success then
				self:setFieldData(courseField)
			else
				self.state = FieldCourseGenerationState.INVALID
				self:finish()
			end
		end)
	else
		self.state = FieldCourseGenerationState.VINEYARD_DETECTION
	end
end
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
				local singleGroupMode = -0.01 <= self.fieldCourseSettings.workDirection
				local baseBoundary = self.headlandBoundaries[#self.headlandBoundaries] or self.innerBoundary
				self.trapezoidDecomposition = TrapezoidDecomposition.new(baseBoundary.boundaryLine, singleGroupMode)
			end
		end
	elseif self.state == FieldCourseGenerationState.SUB_AREA_DETECTION then
		if not self.trapezoidDecomposition:update(dt, self.frameBudget) then
			self.state = FieldCourseGenerationState.SUB_AREA_PATH_CREATION
			local trapezoidGroups = self.trapezoidDecomposition:getGroups()
			for groupId, group in pairs(trapezoidGroups) do
				local callback = function(lines)
					self.linesByGroup[groupId] = lines
					self.boundaryByGroup[groupId] = group.simplifiedBoundary
				end
				local task = BoundaryLineGenerationTask.new(group.simplifiedBoundary, group.center[1], group.center[2], group.direction[1], group.direction[2], self.islands, self.fieldCourseSettings, callback)
				table.insert(self.boundaryLineGenerationTasks, task)
			end
			self.trapezoidDecomposition = nil
		end
	elseif self.state == FieldCourseGenerationState.SUB_AREA_PATH_CREATION then
		for i = #self.boundaryLineGenerationTasks, 1, -1 do
			if self.boundaryLineGenerationTasks[i]:update(dt, self.frameBudget) then
				continue
			end
			table.remove(self.boundaryLineGenerationTasks, i)
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
		local sideOffset = self.fieldCourseSettings.implementWidth * 0.5
		local offsetStep = self.fieldCourseSettings.implementWidth * 0.1
		local startTime = getTimeSec()
		local isValid = false
		for groupIndex, lines in pairs(self.linesByGroup) do
			local line = lines[self.currentOverlapLineIndex]
			if line == nil then
				continue
			end
			local positions = line.positions
			FieldCourseUtil.shrinkSegmentUntilOverlap(self.linesByGroup, self.islands, self.headlandBoundaries, groupIndex, positions, -1, sideOffset, sideOffset, offsetStep)
			FieldCourseUtil.shrinkSegmentUntilOverlap(self.linesByGroup, self.islands, self.headlandBoundaries, groupIndex, positions, 1, sideOffset, sideOffset, offsetStep)
			FieldCourseUtil.extendSegmentUntilOverlap(self.linesByGroup, self.islands, self.headlandBoundaries, groupIndex, positions, -1, sideOffset, sideOffset, offsetStep)
			FieldCourseUtil.extendSegmentUntilOverlap(self.linesByGroup, self.islands, self.headlandBoundaries, groupIndex, positions, 1, sideOffset, sideOffset, offsetStep)
			isValid = true
		end
		while isValid do
			self.currentOverlapLineIndex = self.currentOverlapLineIndex + 1
			local endTime = getTimeSec()
			if self.frameBudget < endTime - startTime then
				break
			end
		end
		if not isValid then
			self.state = FieldCourseGenerationState.FINISHED
		end
	elseif self.state == FieldCourseGenerationState.SEGMENT_TO_BOUNDARY_EXTENSION then
		local rootBoundary = self.headlandBoundaries[#self.headlandBoundaries] or self.fieldRootBoundary
		for groupIndex, lines in pairs(self.linesByGroup) do
			for _, line in ipairs(lines) do
				local boundaryLine = self.boundaryByGroup[groupIndex] or rootBoundary.boundaryLine
				FieldCourseSegmentGenerator.extendSegmentToBoundary(line.positions, boundaryLine, self.islands)
			end
		end
		self.state = FieldCourseGenerationState.FINISHED
	end
	if self:getHasFinished() then
		self:finish()
	end
end
function FieldCourseSegmentGenerator:generateNextHeadland()
	if self.numHeadlandsToCreate <= 0 then
		local baseBoundary = self.headlandBoundaries[#self.headlandBoundaries] or self.fieldRootBoundary
		self.innerBoundary = baseBoundary:extend(self.fieldCourseSettings.implementWidth * 0.5) or baseBoundary
		for _, island in ipairs(self.islands) do
			for i = #island.boundaries, 1, -1 do
				if 1 < i and self.innerBoundary:isInsideOf(island.boundaries[i]) then
					island.boundaries[i] = nil
				end
			end
			for i = #island.boundaries, 1, -1 do
				if island.boundaries[i]:removeCollidingSegments(self.fieldRootBoundary, self.fieldCourseSettings.implementWidth * 0.5) then
					if not island.boundaries[i]:isValid() then
						table.remove(island.boundaries, i)
					end
					island.hasCutSegments = true
				end
			end
			local baseIslandBoundary = island.boundaries[#island.boundaries] or island.rootBoundary
			if baseIslandBoundary:isColliding(self.innerBoundary) and 0 < #island.boundaries then
				for i = #island.boundaries, 1, -1 do
					if 1 < i and island.boundaries[i]:isColliding(self.innerBoundary) then
						island.boundaries[i] = nil
					end
				end
			end
			island.validPathBoundary = island.boundaries[1] or island.rootBoundary
			island.innerBoundary = island.validPathBoundary
		end
		for i, headlandBoundary in ipairs(self.headlandBoundaries) do
			for _, island in ipairs(self.islands) do
				headlandBoundary:cut(island.innerBoundary)
			end
		end
		return false
	else
		local baseBoundary = self.headlandBoundaries[#self.headlandBoundaries] or self.fieldRootBoundary
		local offset = #self.headlandBoundaries == 0 and self.fieldCourseSettings.implementWidth * 0.5 or self.fieldCourseSettings.implementWidth
		local offsetBoundary = baseBoundary:extend(offset)
		if offsetBoundary ~= nil then
			table.insert(self.headlandBoundaries, offsetBoundary)
		else
			self.numHeadlandsToCreate = 0
		end
		if 0 < self.numHeadlandsToCreate then
			for _, island in ipairs(self.islands) do
				baseBoundary = island.boundaries[#island.boundaries] or island.rootBoundary
				offset = #island.boundaries == 0 and -self.fieldCourseSettings.implementWidth * 0.5 or -self.fieldCourseSettings.implementWidth
				local islandOffsetBoundary = baseBoundary:extend(offset)
				if islandOffsetBoundary == nil then
					continue
				end
				for _, otherIsland in ipairs(self.islands) do
					if otherIsland == island then
						continue
					end
					for _, otherBoundary in ipairs(otherIsland.boundaries) do
						if otherBoundary:isColliding(islandOffsetBoundary) then
							islandOffsetBoundary = nil
							break
						end
					end
					if islandOffsetBoundary ~= nil then
						continue
					end
					if islandOffsetBoundary ~= nil and 0 < #island.boundaries then
						local lastMainBoundary = self.headlandBoundaries[#self.headlandBoundaries] or self.fieldRootBoundary
						if lastMainBoundary:isColliding(islandOffsetBoundary) then
							islandOffsetBoundary = nil
						end
					end
					if islandOffsetBoundary ~= nil then
						table.insert(island.boundaries, islandOffsetBoundary)
					end
				end
			end
		end
		self.numHeadlandsToCreate = self.numHeadlandsToCreate - 1
		return true
	end
end
function FieldCourseSegmentGenerator:getHasFinished()
	return self.state == FieldCourseGenerationState.FINISHED or self.state == FieldCourseGenerationState.INVALID
end
function FieldCourseSegmentGenerator:finish()
	local segments = {}
	if self.state == FieldCourseGenerationState.FINISHED then
		if self.fieldCourseSettings.segmentHeadlandReverseLines then
			self:doHeadlandReverseSegmentExtension(-1)
		end
		for groupIndex, lines in pairs(self.linesByGroup) do
			for i = 1, #lines do
				local segment = lines[i]
				segment.lineGroupIndex = groupIndex
				segment.isHeadlandSegment = false
				segment.isIslandSegment = false
				table.insert(segments, segment)
			end
		end
		if not self.skipHeadland then
			for islandIndex, island in ipairs(self.islands) do
				for headlandIndex, islandBoundary in ipairs(island.boundaries) do
					for i = 1, #islandBoundary.segments do
						islandBoundary.segments[i].isHeadlandSegment = false
						islandBoundary.segments[i].isIslandSegment = true
						islandBoundary.segments[i].islandIndex = islandIndex
						islandBoundary.segments[i].headlandIndex = headlandIndex
						table.insert(segments, islandBoundary.segments[i])
					end
				end
			end
			for headlandIndex, headlandBoundary in ipairs(self.headlandBoundaries) do
				for i = 1, #headlandBoundary.segments do
					headlandBoundary.segments[i].isHeadlandSegment = true
					headlandBoundary.segments[i].isIslandSegment = false
					headlandBoundary.segments[i].headlandIndex = headlandIndex
					table.insert(segments, headlandBoundary.segments[i])
				end
			end
		end
		for segmentIndex = #segments, 1, -1 do
			local segment = segments[segmentIndex]
			FieldCourseUtil.extendSegmentPositions(segment, self.fieldCourseSettings.toolFrontOffset)
		end
		for segmentIndex = #segments, 1, -1 do
			local segment = segments[segmentIndex]
			segment.length = FieldCourseUtil.getSegmentLength(segment.positions)
			if segment.lineGroupIndex == nil then
				continue
			end
			if segment.length < FieldCourse.MIN_SEGMENT_LENGTH then
				table.remove(segments, segmentIndex)
			end
		end
	end
	if self.callback ~= nil then
		self.callback(segments, self.courseField, self.isVineyardCourse)
	end
end
function FieldCourseSegmentGenerator:doVineyardDetection()
	if g_currentMission.placeableSystem == nil then
		return false
	end
	local boundary = self.fieldRootBoundary.boundaryLine
	local placeables = g_currentMission.placeableSystem.placeables
	for _, placeable in ipairs(placeables) do
		if placeable.spec_vine == nil or placeable.spec_fence == nil then
			continue
		end
		local anyVineInsideBoundary = false
		for i, segment in pairs(placeable.spec_fence.segments) do
			if FieldCourseUtil.getIsPointInsideBoundary(segment.x1, segment.z1, boundary) or FieldCourseUtil.getIsPointInsideBoundary(segment.x2, segment.z2, boundary) then
				anyVineInsideBoundary = true
			else
			end
			if anyVineInsideBoundary then
				local group = {}
				local sideOffset = 0
				if self.fieldCourseSettings.isVineyardRowTool then
					sideOffset = placeable:getSnapDistance() * 0.5
				end
				for i, segment in pairs(placeable.spec_fence.segments) do
					if FieldCourseUtil.getIsPointInsideBoundary(segment.x1, segment.z1, boundary) or FieldCourseUtil.getIsPointInsideBoundary(segment.x2, segment.z2, boundary) then
						local dx = segment.x2 - segment.x1
						local dz = segment.z2 - segment.z1
						dx, dz = MathUtil.vector2Normalize(dx, dz)
						local sx = segment.x1 + dz * sideOffset
						local sz = segment.z1 - dx * sideOffset
						local ex = segment.x2 + dz * sideOffset
						local ez = segment.z2 - dx * sideOffset
						sx = sx - dx * 2
						sz = sz - dz * 2
						ex = ex + dx * 2
						ez = ez + dz * 2
						table.insert(group, { { sx, sz }, { ex, ez } })
						local sx = segment.x1 - dz * sideOffset
						local sz = segment.z1 + dx * sideOffset
						local ex = segment.x2 - dz * sideOffset
						local ez = segment.z2 + dx * sideOffset
						sx = sx - dx * 2
						sz = sz - dz * 2
						ex = ex + dx * 2
						ez = ez + dz * 2
						table.insert(group, { { sx, sz }, { ex, ez } })
					end
				end
				for i = #group, 1, -1 do
					local line = group[i]
					if line ~= nil then
						local x1 = line[1][1]
						local z1 = line[1][2]
						local x2 = line[2][1]
						local z2 = line[2][2]
						local dx = x2 - x1
						local dz = z2 - z1
						local length = MathUtil.vector2Length(dx, dz)
						dx = dx / length
						dz = dz / length
						for j = #group, 1, -1 do
							if j == i then
								continue
							end
							local otherLine = group[j]
							local x3 = otherLine[1][1]
							local z3 = otherLine[1][2]
							local x4 = otherLine[2][1]
							local z4 = otherLine[2][2]
							local dot1 = MathUtil.getProjectOnLineParameter(x3, z3, x1, z1, dx, dz)
							local px = x1 + dx * dot1
							local pz = z1 + dz * dot1
							local sideOffset = MathUtil.vector2Length(px - x3, pz - z3)
							if sideOffset < 0.01 then
								local dot2 = MathUtil.getProjectOnLineParameter(x4, z4, x1, z1, dx, dz)
								if -0.25 <= dot1 and (dot1 <= length + 0.25 and -0.25 <= dot2) then
									if dot2 <= length + 0.25 then
										table.remove(group, j)
									elseif -0.25 <= dot1 then
										if dot1 <= length + 0.25 then
											if length < dot2 then
												x2 = x4
												z2 = z4
												line[2][1] = x2
												line[2][2] = z2
												length = MathUtil.vector2Length(x2 - x1, z2 - z1)
											elseif dot2 < 0 then
												x1 = x4
												z1 = z4
												line[1][1] = x1
												line[1][2] = z1
												length = MathUtil.vector2Length(x2 - x1, z2 - z1)
											end
										elseif -0.25 <= dot2 then
											if dot2 <= length + 0.25 then
												if dot1 < 0 then
													x1 = x3
													z1 = z3
													line[1][1] = x1
													line[1][2] = z1
													length = MathUtil.vector2Length(x2 - x1, z2 - z1)
												elseif length < dot2 then
													x2 = x3
													z2 = z3
													line[2][1] = x2
													line[2][2] = z2
													length = MathUtil.vector2Length(x2 - x1, z2 - z1)
												end
											end
										end
									end
								end
							end
						end
					end
				end
				if 0 < #group then
					local lines = {}
					for i = 1, #group do
						local line = {}
						line.positions = group[i]
						table.insert(lines, line)
					end
					table.insert(self.linesByGroup, lines)
				end
			end
		end
	end
	if 0 < #self.linesByGroup then
		self.isVineyardCourse = true
		return true
	else
		return false
	end
end
function FieldCourseSegmentGenerator:doHeadlandReverseSegmentExtension(direction)
	local maxDistance = math.sqrt(self.fieldCourseSettings.implementWidth ^ 2 + self.fieldCourseSettings.implementWidth ^ 2)
	for headlandIndex, headlandBoundary in ipairs(self.headlandBoundaries) do
		for i = 1, #headlandBoundary.segments do
			local segment = headlandBoundary.segments[i]
			local prevSegment = headlandBoundary.segments[i - 1]
			if prevSegment == nil then
				prevSegment = headlandBoundary.segments[#headlandBoundary.segments]
			end
			local x1 = segment.positions[1][1]
			local z1 = segment.positions[1][2]
			local x2 = segment.positions[2][1]
			local z2 = segment.positions[2][2]
			local dirX, dirZ = MathUtil.vector2Normalize(x2 - x1, z2 - z1)
			local numPositions = #prevSegment.positions
			local x3 = prevSegment.positions[numPositions - 1][1]
			local z3 = prevSegment.positions[numPositions - 1][2]
			local x4 = prevSegment.positions[numPositions][1]
			local z4 = prevSegment.positions[numPositions][2]
			local nextDirX, nextDirZ = MathUtil.vector2Normalize(x4 - x3, z4 - z3)
			local angle = math.acos(FieldCourseUtil.vector2Dot(dirX, dirZ, nextDirX, nextDirZ))
			if 0.7853981633974483 < angle then
				if direction == nil or direction == 1 then
					FieldCourseUtil.extendSegmentToBoundary(segment.positions, self.fieldRootBoundary.boundaryLine, true, false, maxDistance)
				else
					FieldCourseUtil.extendSegmentToBoundary(prevSegment.positions, self.fieldRootBoundary.boundaryLine, false, true, maxDistance)
				end
			end
		end
	end
end
function FieldCourseSegmentGenerator.extendSegmentToBoundary(positions, boundary, islands, maxDistance)
	maxDistance = maxDistance or math.huge
	local getSegmentClosestBoundariesIntersection = function(l1x, l1z, l2x, l2z)
		local minDistance = math.huge
		local ix = nil
		local iz = nil
		for i = 1, #boundary - 1 do
			local sx = boundary[i][1]
			local sz = boundary[i][2]
			local ex = boundary[i + 1][1]
			local ez = boundary[i + 1][2]
			local intersect, x, z = MathUtil.getLineSegmentsIntersection(sx, sz, ex, ez, l1x, l1z, l2x, l2z)
			if intersect then
				local distance = MathUtil.vector2Length(l1x - x, l1z - z)
				if distance < minDistance then
					minDistance = distance
					ix = x
					iz = z
				end
			end
		end
		for _, island in ipairs(islands) do
			local islandBoundary = island.boundaries[#island.boundaries] or island.rootBoundary
			if islandBoundary == nil then
				continue
			end
			for i = 1, #islandBoundary.boundaryLine - 1 do
				local sx = islandBoundary.boundaryLine[i][1]
				local sz = islandBoundary.boundaryLine[i][2]
				local ex = islandBoundary.boundaryLine[i + 1][1]
				local ez = islandBoundary.boundaryLine[i + 1][2]
				local intersect, x, z = MathUtil.getLineSegmentsIntersection(sx, sz, ex, ez, l1x, l1z, l2x, l2z)
				if intersect then
					local distance = MathUtil.vector2Length(l1x - x, l1z - z)
					if distance < minDistance then
						minDistance = distance
						ix = x
						iz = z
					end
				end
			end
		end
		return minDistance ~= math.huge, ix, iz
	end
	local p1 = positions[1]
	local p2 = positions[2]
	local dirX = p1[1] - p2[1]
	local dirZ = p1[2] - p2[2]
	local length = MathUtil.vector2Length(dirX, dirZ)
	dirX = dirX / length
	dirZ = dirZ / length
	local intersect1, ix1, iz1 = getSegmentClosestBoundariesIntersection(p1[1] - dirX * 0.1, p1[2] - dirZ * 0.1, p1[1] + dirX * 65535, p1[2] + dirZ * 65535)
	if intersect1 then
		local extensionLength = MathUtil.vector2Length(ix1 - p1[1], iz1 - p1[2])
		if extensionLength < maxDistance then
			p1[1] = ix1
			p1[2] = iz1
		end
	end
	p1 = positions[#positions]
	p2 = positions[#positions - 1]
	dirX = p1[1] - p2[1]
	dirZ = p1[2] - p2[2]
	length = MathUtil.vector2Length(dirX, dirZ)
	dirX = dirX / length
	dirZ = dirZ / length
	intersect1, ix1, iz1 = getSegmentClosestBoundariesIntersection(p1[1] - dirX * 0.1, p1[2] - dirZ * 0.1, p1[1] + dirX * 65535, p1[2] + dirZ * 65535)
	if intersect1 then
		local extensionLength = MathUtil.vector2Length(ix1 - p1[1], iz1 - p1[2])
		if extensionLength < maxDistance then
			p1[1] = ix1
			p1[2] = iz1
		end
	end
end
