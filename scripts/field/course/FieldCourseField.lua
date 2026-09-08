-- Local values: FieldCourseField_mt
FieldCourseField = {}
local FieldCourseField_mt = Class(FieldCourseField)
FieldCourseField.NUM_BOUNDARY_SYNC_BITS = 9
FieldCourseField.MAX_BOUNDARY_SIZE = 2 ^ FieldCourseField.NUM_BOUNDARY_SYNC_BITS - 1
FieldCourseField.NUM_ISLANDS_SYNC_BITS = 5
FieldCourseField.MAX_ISLAND_AMOUNT = 2 ^ FieldCourseField.NUM_ISLANDS_SYNC_BITS - 1
FieldCourseField.MIN_BOUNDARY_LENGTH = 20
FieldCourseField.THIGHT_CORNER_ANGLE = 2.443460952792061

-- Upvalues: FieldCourseField_mt
-- Local values: self
function FieldCourseField.new(fieldCourseSettings)
	-- upvalues: (copy) FieldCourseField_mt
	local v3_ = FieldCourseField_mt
	local v4_ = setmetatable({}, v3_)
	v4_.fieldCourseSettings = fieldCourseSettings
	local v5_ = fieldCourseSettings.segmentSplitAngle
	v4_.segmentSplitAngle = math.rad(v5_)
	v4_.boundaryPositions = {}
	v4_.headlandBoundaries = {}
	v4_.islandBoundaries = {}
	v4_.state = FieldCourseDetectionState.BOUNDARY_DETECTION
	v4_.boundaryCollisionCheckSegmentIndex = 0
	v4_.boundaryCollisionCheckPending = false
	v4_.boundaryCollisionCheckRequiresSegmentUpdate = false
	v4_.ignoreIslands = false
	v4_.ignoreCollisions = false
	return v4_
end

-- Local values: field
function FieldCourseField.generateAtPosition(x, z, fieldCourseSettings, callback, callbackTarget)
	local v11_, v12_ = g_fieldCourseManager:roundToTerrainDetailPixel(x, z)
	local v13_ = FieldCourseField.new(fieldCourseSettings)
	v13_:detectAtPosition(v11_, v12_, callback, callbackTarget)
	return v13_
end

-- Local values: _, island
function FieldCourseField:reset()
	self.headlandBoundaries = {}
	if self.islands ~= nil then
		for _, v15_ in ipairs(self.islands) do
			v15_.boundaries = {}
			v15_.hasCutSegments = false
		end
	end
end

function FieldCourseField:setIgnoreIslands(ignoreIslands)
	self.ignoreIslands = ignoreIslands
end

function FieldCourseField:setIgnoreCollisions(ignoreCollisions)
	self.ignoreCollisions = ignoreCollisions
end

-- Local values: y, _, _, _, riceField, numVerts, i, x, z, x, z, inverted, i, i
function FieldCourseField:detectAtPosition(x, z, callback, callbackTarget)
	self.startX = x
	self.startZ = z
	self.callback = callback
	self.callbackTarget = callbackTarget
	self.terrainDetailResolution = g_currentMission.terrainSize / g_currentMission.terrainDetailMapSize
	self.islandSamplePoints = {}
	local v25_ = getTerrainHeightAtWorldPos(g_terrainNode, x, 0, z)
	local _, _, _, v26_ = PlaceableRiceField.getRiceFieldAtPosition(x, v25_, z)
	if v26_ == nil then
		self.boundaryDetectionTask = BoundaryDetectionTask.new(x, z)
		if self.boundaryDetectionTask == nil then
			self:finishTask(false)
			return nil
		end
		return
	else
		for v27_ = 1, v26_.polygon:getNumVertices() do
			local v28_, v29_ = v26_.polygon:getVertex(v27_)
			local v30_ = self.boundaryPositions
			table.insert(v30_, { v28_, v29_ })
		end
		local v31_, v32_ = v26_.polygon:getVertex(1)
		local v33_ = self.boundaryPositions
		table.insert(v33_, { v31_, v32_ })
		if FieldCourseBoundary.getIsBoundaryLineInverted(self.boundaryPositions) then
			local v34_ = {}
			for v35_ = #self.boundaryPositions, 1, -1 do
				local v36_ = self.boundaryPositions[v35_]
				table.insert(v34_, v36_)
			end
			self.boundaryPositions = v34_
		end
		for v37_ = 1, #self.boundaryPositions do
			local v38_ = self.boundaryPositions[v37_]
			local v39_ = self.boundaryPositions[v37_]
			local v40_, v41_ = g_fieldCourseManager:roundToTerrainDetailPixel(self.boundaryPositions[v37_][1], self.boundaryPositions[v37_][2])
			v38_[1] = v40_
			v39_[2] = v41_
		end
		self.fieldRootBoundary = FieldCourseBoundary.createByBoundaryLine(self.boundaryPositions, self.segmentSplitAngle)
		self.fieldRootBoundary = self.fieldRootBoundary:extend(0.75)
		if self.fieldRootBoundary == nil then
			Logging.warning("Failed to create field boundary from rice field")
			self:finishTask(false)
			return nil
		else
			self.boundaryPositions = table.clone(self.fieldRootBoundary.boundaryLine, math.huge)
			self:finishTask(true)
			return self
		end
	end
end

-- Local values: boundaryPositionStr, i, i, island, islandKey, islandBoundaryPositionStr, j
function FieldCourseField:saveToXML(xmlFile, key)
	local v45_ = ""
	for v46_ = 1, #self.boundaryPositions do
		v45_ = v45_ .. string.format("%.2f %.2f ", self.boundaryPositions[v46_][1], self.boundaryPositions[v46_][2])
	end
	xmlFile:setValue(key .. ".boundary#positions", string.trim(v45_))
	for v47_, v48_ in ipairs(self.islands) do
		local v49_ = string.format("%s.island(%d)", key, v47_ - 1)
		local v50_ = ""
		for v51_ = 1, #v48_.rootBoundary.boundaryLine do
			v50_ = v50_ .. string.format("%.2f %.2f ", v48_.rootBoundary.boundaryLine[v51_][1], v48_.rootBoundary.boundaryLine[v51_][2])
		end
		xmlFile:setValue(v49_ .. "#positions", string.trim(v50_))
	end
end

-- Local values: boundaryStr, positions, i, x, z, _, key, islandBoundaryStr, island, boundaryLine, islandPositions, i, x, z
function FieldCourseField:loadFromXML(xmlFile, key)
	if not xmlFile:hasProperty(key) then
		return false
	end
	local v55_ = xmlFile:getValue(key .. ".boundary#positions")
	if v55_ == nil then
		return false
	end
	self.boundaryPositions = {}
	local v56_ = string.split(v55_, " ")
	for v57_ = 1, #v56_, 2 do
		local v58_ = v56_[v57_]
		local v59_ = tonumber(v58_)
		local v60_ = v56_[v57_ + 1]
		local v61_ = tonumber(v60_)
		local v62_ = self.boundaryPositions
		table.insert(v62_, { v59_, v61_ })
	end
	self.fieldRootBoundary = FieldCourseBoundary.createByBoundaryLine(self.boundaryPositions, self.segmentSplitAngle)
	if self.fieldRootBoundary == nil then
		Logging.xmlWarning(xmlFile, "Failed to create fieldRootBoundary from \'%s\' in \'%s\'", v55_, key)
		return false
	end
	self.islands = {}
	for _, v63_ in xmlFile:iterator(key .. ".island") do
		local v64_ = xmlFile:getValue(v63_ .. "#positions")
		if v64_ == nil then
			break
		end
		local v65_ = string.split(v64_, " ")
		local v66_ = {}
		local v67_ = {
			["boundaries"] = {},
			["hasCutSegments"] = false
		}
		for v68_ = 1, #v65_, 2 do
			local v69_ = v65_[v68_]
			local v70_ = tonumber(v69_)
			local v71_ = v65_[v68_ + 1]
			local v72_ = { v70_, (tonumber(v71_)) }
			table.insert(v66_, v72_)
		end
		v67_.rootBoundary = FieldCourseBoundary.createByBoundaryLine(v66_, self.segmentSplitAngle)
		local v73_ = self.islands
		table.insert(v73_, v67_)
	end
	self.state = FieldCourseDetectionState.FINISHED
	return true
end

-- Local values: i, _, island, i
function FieldCourseField:writeStream(streamId, connection)
	streamWriteUIntN(streamId, #self.boundaryPositions, FieldCourseField.NUM_BOUNDARY_SYNC_BITS)
	for v76_ = 1, #self.boundaryPositions do
		g_fieldCourseManager:writeTerrainDetailPixel(streamId, self.boundaryPositions[v76_][1], self.boundaryPositions[v76_][2])
	end
	streamWriteUIntN(streamId, #self.islands, FieldCourseField.NUM_ISLANDS_SYNC_BITS)
	for _, v77_ in ipairs(self.islands) do
		streamWriteUIntN(streamId, #v77_.rootBoundary.boundaryLine, FieldCourseField.NUM_BOUNDARY_SYNC_BITS)
		for v78_ = 1, #v77_.rootBoundary.boundaryLine do
			g_fieldCourseManager:writeTerrainDetailPixel(streamId, v77_.rootBoundary.boundaryLine[v78_][1], v77_.rootBoundary.boundaryLine[v78_][2])
		end
	end
end

-- Local values: numBoundaryPositions, i, x, z, numIslands, i, island, boundaryLine, j, x, z
function FieldCourseField:readStream(streamId, connection)
	self.boundaryPositions = {}
	for _ = 1, streamReadUIntN(streamId, FieldCourseField.NUM_BOUNDARY_SYNC_BITS) do
		local v81_, v82_ = g_fieldCourseManager:readTerrainDetailPixel(streamId)
		local v83_ = self.boundaryPositions
		table.insert(v83_, { v81_, v82_ })
	end
	self.fieldRootBoundary = FieldCourseBoundary.createByBoundaryLine(self.boundaryPositions, self.segmentSplitAngle)
	self.islands = {}
	for _ = 1, streamReadUIntN(streamId, FieldCourseField.NUM_ISLANDS_SYNC_BITS) do
		local v84_ = {}
		local v85_ = {
			["boundaries"] = {},
			["hasCutSegments"] = false
		}
		for _ = 1, streamReadUIntN(streamId, FieldCourseField.NUM_BOUNDARY_SYNC_BITS) do
			local v86_, v87_ = g_fieldCourseManager:readTerrainDetailPixel(streamId)
			table.insert(v84_, { v86_, v87_ })
		end
		v85_.rootBoundary = FieldCourseBoundary.createByBoundaryLine(v84_, self.segmentSplitAngle)
		local v88_ = self.islands
		table.insert(v88_, v85_)
	end
	self.state = FieldCourseDetectionState.FINISHED
end

-- Local values: boundaryPositions, i, boundaryPositions, maxZ, i, length, i, x1, z1, x2, z2, fieldRootBoundary, islandPositions, invertedPositions, i, i, sx, sz, isValid, _, island, boundary, offsetBoundary, boundaryLine, i
function FieldCourseField:update(dt, frameBudget)
	if self.state == FieldCourseDetectionState.BOUNDARY_DETECTION then
		if self.boundaryDetectionTask ~= nil and not self.boundaryDetectionTask:update(dt, frameBudget) then
			if #self.boundaryDetectionTask.boundaryPositions > 0 then
				self.state = FieldCourseDetectionState.BOUNDARY_SIMPLIFICATION1
			else
				self:finishTask(false)
			end
		end
	elseif self.state == FieldCourseDetectionState.BOUNDARY_SIMPLIFICATION1 then
		local v92_ = self.boundaryDetectionTask.boundaryPositions
		FieldCourseUtil.pointAveragePositions(v92_)
		for v93_ = #v92_, 1, -2 do
			table.remove(v92_, v93_)
		end
		local v94_ = v92_[1]
		local v95_ = v92_[1]
		local v96_ = v92_[#v92_][1]
		local v97_ = v92_[#v92_][2]
		v94_[1] = v96_
		v95_[2] = v97_
		FieldCourseUtil.semiConvexSimplification(v92_, 10)
		FieldCourseUtil.douglasPeucker(v92_, 0.25)
		self.state = FieldCourseDetectionState.BOUNDARY_SIMPLIFICATION2
	elseif self.state == FieldCourseDetectionState.BOUNDARY_SIMPLIFICATION2 then
		local v98_ = self.boundaryDetectionTask.boundaryPositions
		if FieldCourseUtil.getIsPointInsideBoundary(self.startX, self.startZ, v98_) then
			for v99_ = 1, #v98_ do
				local v100_ = v98_[v99_]
				local v101_ = v98_[v99_]
				local v102_, v103_ = g_fieldCourseManager:roundToTerrainDetailPixel(v98_[v99_][1], v98_[v99_][2])
				v100_[1] = v102_
				v101_[2] = v103_
			end
			FieldCourseUtil.visvalingamWhyattSimplification(v98_, 5)
			FieldCourseUtil.douglasPeucker(v98_, 0.5)
			local v104_ = 0
			for v105_ = 1, #v98_ - 1 do
				local v106_ = v98_[v105_][1]
				local v107_ = v98_[v105_][2]
				local v108_ = v98_[v105_ + 1][1]
				local v109_ = v98_[v105_ + 1][2]
				v104_ = v104_ + MathUtil.vector2Length(v106_ - v108_, v107_ - v109_)
				if FieldCourseField.MIN_BOUNDARY_LENGTH <= v104_ then
					break
				end
			end
			if v104_ < FieldCourseField.MIN_BOUNDARY_LENGTH then
				self:finishTask(false)
			else
				self.boundaryPositions = v98_
				self.state = FieldCourseDetectionState.BOUNDARY_SEGMENT_CREATION
			end
			self.boundaryDetectionTask = nil
		else
			local v110_ = self.boundaryDetectionTask:getMaxZ()
			self.boundaryDetectionTask = BoundaryDetectionTask.new(self.startX, v110_ + self.terrainDetailResolution)
			if self.boundaryDetectionTask == nil then
				self:finishTask(false)
			else
				self.state = FieldCourseDetectionState.BOUNDARY_DETECTION
			end
		end
	elseif self.state == FieldCourseDetectionState.BOUNDARY_SEGMENT_CREATION then
		self.fieldRootBoundary = FieldCourseBoundary.createByBoundaryLine(self.boundaryPositions, self.segmentSplitAngle)
		if self.fieldRootBoundary == nil then
			self:finishTask(false)
		else
			self.state = FieldCourseDetectionState.BOUNDARY_SHRINK
		end
	elseif self.state == FieldCourseDetectionState.BOUNDARY_SHRINK then
		self.originalBoundary = self.fieldRootBoundary
		local v111_ = self.fieldRootBoundary:extend(2.5)
		if v111_ == nil then
			self.state = FieldCourseDetectionState.BOUNDARY_COLLISION_CHECK
		else
			self.fieldRootBoundary = v111_
			self.state = FieldCourseDetectionState.BOUNDARY_EXTENSION
		end
	elseif self.state == FieldCourseDetectionState.BOUNDARY_EXTENSION then
		self.fieldRootBoundary = self.fieldRootBoundary:extend(-2.5)
		if self.fieldRootBoundary == nil then
			self.fieldRootBoundary = self.originalBoundary
		end
		self.originalBoundary = nil
		if self.ignoreCollisions then
			if self.ignoreIslands then
				self:finishTask(true)
			else
				self:islandDetection(self.fieldRootBoundary.boundaryLine)
				self.state = FieldCourseDetectionState.ISLAND_DETECTION
			end
		else
			self.state = FieldCourseDetectionState.BOUNDARY_COLLISION_CHECK
		end
	elseif self.state == FieldCourseDetectionState.BOUNDARY_COLLISION_CHECK then
		if not self.boundaryCollisionCheckPending then
			self.boundaryCollisionCheckPending = true
			self.fieldRootBoundary:segmentCollisionOffset(5, 1, function(_)
				-- upvalues: (copy) self
				local v112_ = self.fieldRootBoundary.boundaryLine
				for v113_ = 1, #v112_ do
					local v114_ = v112_[v113_]
					local v115_ = v112_[v113_]
					local v116_, v117_ = g_fieldCourseManager:roundToTerrainDetailPixel(v112_[v113_][1], v112_[v113_][2])
					v114_[1] = v116_
					v115_[2] = v117_
				end
				self.fieldRootBoundary:regenerateSegments()
				self.boundaryPositions = self.fieldRootBoundary.boundaryLine
				if self.ignoreIslands then
					self:finishTask(true)
				else
					self:islandDetection(self.fieldRootBoundary.boundaryLine)
					self.state = FieldCourseDetectionState.ISLAND_DETECTION
				end
			end)
		end
	elseif self.state == FieldCourseDetectionState.ISLAND_DETECTION then
		if self.curIslandDetectionTask ~= nil and not self.curIslandDetectionTask:update(dt, frameBudget) then
			local v118_ = self.curIslandDetectionTask.boundaryPositions
			FieldCourseUtil.pointAveragePositions(v118_)
			local v119_ = {}
			for v120_ = #v118_, 1, -1 do
				local v121_ = v118_[v120_]
				table.insert(v119_, v121_)
			end
			FieldCourseUtil.semiConvexSimplification(v119_, 15)
			local v122_ = {}
			for v123_ = #v119_, 1, -1 do
				local v124_ = v119_[v123_]
				table.insert(v122_, v124_)
			end
			FieldCourseUtil.douglasPeucker(v122_, 0.25)
			FieldCourseUtil.visvalingamWhyattSimplification(v122_, 5)
			local v125_ = v122_[1][1]
			local v126_ = v122_[1][2]
			local v127_ = true
			for _, v128_ in ipairs(self.islandBoundaries) do
				if FieldCourseUtil.getAreBoundariesColliding(v128_.boundaryLine, v122_) or FieldCourseUtil.getIsPointInsideBoundary(v125_, v126_, v128_.boundaryLine) then
					v127_ = false
					break
				end
			end
			if v127_ then
				local v129_ = FieldCourseBoundary.createByBoundaryLine(v122_, self.segmentSplitAngle)
				if v129_ ~= nil then
					local v130_ = v129_:extend(-0.25)
					if v130_ == nil then
						Logging.error("FieldCourseField: Failed to extend island boundary")
					end
					local v131_ = v130_ or v129_
					local v132_ = v131_.boundaryLine
					for v133_ = 1, #v132_ do
						local v134_ = v132_[v133_]
						local v135_ = v132_[v133_]
						local v136_, v137_ = g_fieldCourseManager:roundToTerrainDetailPixel(v132_[v133_][1], v132_[v133_][2])
						v134_[1] = v136_
						v135_[2] = v137_
					end
					v131_:regenerateSegments()
					local v138_ = self.islandBoundaries
					table.insert(v138_, v131_)
				end
			end
			self.curIslandDetectionTask = nil
			if #self.islandSamplePoints == 0 then
				self:finishTask(true)
			end
		end
		if (#self.islandSamplePoints > 0 or self.islandSamplePointsDetected == false) and not self:continueIslandDetection(frameBudget) then
			self:finishTask(true)
		end
	end
	return self.state ~= FieldCourseDetectionState.FINISHED
end

-- Local values: _, island
function FieldCourseField:setProtectedBoundary(protectedBoundarySize)
	self.protectedBoundary = self.fieldRootBoundary:extend(protectedBoundarySize) or self.fieldRootBoundary
	for _, v141_ in ipairs(self.islands) do
		v141_.protectedBoundary = v141_.rootBoundary:extend(-protectedBoundarySize) or v141_.rootBoundary
	end
	return self.protectedBoundary
end

-- Local values: _, islandBoundary, island
function FieldCourseField:finishTask(success)
	self.state = FieldCourseDetectionState.FINISHED
	if success then
		self.islands = {}
		for _, v144_ in ipairs(self.islandBoundaries) do
			local v145_ = self.islands
			table.insert(v145_, {
				["rootBoundary"] = v144_,
				["boundaries"] = {},
				["hasCutSegments"] = false
			})
		end
		self.islandBoundaries = nil
	end
	if self.callbackTarget == nil then
		if self.callback ~= nil then
			self.callback(self, success)
		end
	else
		self.callback(self.callbackTarget, self, success)
	end
end

-- Local values: boundingBox, i
function FieldCourseField:generateBoundingBoxFromBoundary(boundary)
	if #boundary == 0 then
		return {
			0,
			0,
			0,
			0
		}
	end
	local v147_ = {
		math.huge,
		-math.huge,
		math.huge,
		-math.huge
	}
	for v148_ = 1, #boundary do
		local v149_ = v147_[1]
		local v150_ = boundary[v148_][1]
		v147_[1] = math.min(v149_, v150_)
		local v151_ = v147_[2]
		local v152_ = boundary[v148_][1]
		v147_[2] = math.max(v151_, v152_)
		local v153_ = v147_[3]
		local v154_ = boundary[v148_][2]
		v147_[3] = math.min(v153_, v154_)
		local v155_ = v147_[4]
		local v156_ = boundary[v148_][2]
		v147_[4] = math.max(v155_, v156_)
	end
	return v147_
end

-- Local values: groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels
function FieldCourseField:islandDetection(boundary)
	self.islandSamplePoints = {}
	self.islandSamplePointsDetected = false
	self.islandSamplePointsBoundingBox = self:generateBoundingBoxFromBoundary(boundary)
	self.islandSamplePointsLastX = self.islandSamplePointsBoundingBox[1]
	local v159_, v160_, v161_ = g_currentMission.fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
	if v159_ == nil then
		self:finishTask(true)
	else
		self.islandSampleModifier = DensityMapModifier.new(v159_, v160_, v161_, g_terrainNode)
		self.islandSampleFilter = DensityMapFilter.new(v159_, v160_, v161_)
		self.islandSampleFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)
		if not self:continueIslandDetection(0) then
			self:finishTask(true)
		end
	end
end

-- Local values: startTime, terrainDetailId, boundingBox, rasterSize, subRasterSize, x, z, x1, z1, x2, z2, x3, z3, _, numPixels, totalPixels, x4, z4, lastState, foundPosition, subX, subZ, delta, p, x, z, isValid, _, island
function FieldCourseField:continueIslandDetection(frameBudget)
	if not self.islandSamplePointsDetected then
		local v164_ = getTimeSec()
		local v165_ = g_currentMission.terrainDetailId
		local v166_ = self.islandSamplePointsBoundingBox
		for v167_ = self.islandSamplePointsLastX, v166_[2], 15 do
			for v168_ = v166_[3], v166_[4], 15 do
				local v169_ = v167_ + 15
				local v170_ = v168_ + 15
				self.islandSampleModifier:setParallelogramWorldCoords(v167_, v168_, v169_, v168_, v167_, v170_, DensityCoordType.POINT_POINT_POINT)
				local _, v171_, v172_ = self.islandSampleModifier:executeGet(self.islandSampleFilter)
				local v173_
				if v171_ < v172_ then
					local v174_ = v167_ + 15
					local v175_ = v168_ + 15
					if FieldCourseUtil.getIsPointInsideBoundary(v167_, v168_, self.boundaryPositions) and (FieldCourseUtil.getIsPointInsideBoundary(v169_, v168_, self.boundaryPositions) and (FieldCourseUtil.getIsPointInsideBoundary(v167_, v170_, self.boundaryPositions) and FieldCourseUtil.getIsPointInsideBoundary(v174_, v175_, self.boundaryPositions))) then
						v173_ = v168_
						local v176_ = false
						local v177_ = false
						for v178_ = v167_, v169_ do
							for v179_ = v168_, v170_ do
								if getDensityAtWorldPos(v165_, v178_, 0, v179_) ~= 0 ~= v177_ then
									v177_ = not v177_
									if not v177_ and (FieldCourseUtil.getIsPointInsideBoundary(v178_, v179_, self.boundaryPositions) and (FieldCourseUtil.getIsPointInsideBoundary(v178_ + 2, v179_ + 2, self.boundaryPositions) and (FieldCourseUtil.getIsPointInsideBoundary(v178_ - 2, v179_ - 2, self.boundaryPositions) and (FieldCourseUtil.getIsPointInsideBoundary(v178_ - 2, v179_ + 2, self.boundaryPositions) and (FieldCourseUtil.getIsPointInsideBoundary(v178_ + 2, v179_ - 2, self.boundaryPositions) and FieldCourseUtil.getDistanceToBoundary(v178_, v179_, self.boundaryPositions) > 3))))) then
										local v180_ = self.islandSamplePoints
										table.insert(v180_, { v178_, v179_ })
										v176_ = true
									end
								end
								if v176_ then
									break
								end
							end
							if v176_ then
								break
							end
						end
					else
						v173_ = v168_
					end
				else
					v173_ = v168_
				end
			end
			self.islandSamplePointsLastX = v167_ + 15
			if frameBudget < getTimeSec() - v164_ then
				break
			end
		end
		if self.islandSamplePointsLastX >= v166_[2] then
			self.islandSamplePointsDetected = true
			if #self.islandSamplePoints <= 0 then
				return false
			end
		end
		return true
	end
	if self.curIslandDetectionTask == nil then
		while #self.islandSamplePoints > 0 do
			local v181_ = self.islandSamplePoints[#self.islandSamplePoints]
			local v182_ = v181_[1]
			local v183_ = v181_[2]
			self.islandSamplePoints[#self.islandSamplePoints] = nil
			local v184_ = true
			for _, v185_ in ipairs(self.islandBoundaries) do
				if FieldCourseUtil.getIsPointInsideBoundary(v182_, v183_, v185_.boundaryLine) then
					v184_ = false
					break
				end
			end
			if v184_ then
				self.curIslandDetectionTask = BoundaryDetectionTaskInsideOut.new(v182_, v183_)
			end
		end
	end
	return #self.islandSamplePoints > 0 and true or self.curIslandDetectionTask ~= nil
end

function FieldCourseField:getIsPointInsideBoundary(x, z)
	return FieldCourseUtil.getIsPointInsideBoundary(x, z, self.boundaryPositions) or (FieldCourseUtil.getIsPointInsideBoundary(x + 2, z + 2, self.boundaryPositions) or FieldCourseUtil.getIsPointInsideBoundary(x - 2, z - 2, self.boundaryPositions) or (FieldCourseUtil.getIsPointInsideBoundary(x + 2, z - 2, self.boundaryPositions) or FieldCourseUtil.getIsPointInsideBoundary(x - 2, z + 2, self.boundaryPositions)))
end

-- Local values: numPositions, minX, maxX, minZ, maxZ, _, pos
function FieldCourseField:getBoundingBox()
	if #self.boundaryPositions == 0 then
		return 0, 0, 0, 0
	end
	local v190_ = math.huge
	local v191_ = -math.huge
	local v192_ = math.huge
	local v193_ = -math.huge
	for _, v194_ in ipairs(self.boundaryPositions) do
		local v195_ = v194_[1]
		v190_ = math.min(v190_, v195_)
		local v196_ = v194_[1]
		v191_ = math.max(v191_, v196_)
		local v197_ = v194_[2]
		v192_ = math.min(v192_, v197_)
		local v198_ = v194_[2]
		v193_ = math.max(v193_, v198_)
	end
	return v190_, v191_, v192_, v193_
end

-- Local values: _, island
function FieldCourseField:draw()
	if self.fieldRootBoundary ~= nil then
		self.fieldRootBoundary:draw(0, 0, 1, 0.2)
	end
	if self.protectedBoundary ~= nil then
		self.protectedBoundary:draw(1, 0, 0, 0.2)
	end
	if self.islands ~= nil then
		for _, v200_ in ipairs(self.islands) do
			if v200_.rootBoundary ~= nil then
				v200_.rootBoundary:draw(0, 0, 1, 0.2)
			end
			if v200_.protectedBoundary ~= nil then
				v200_.protectedBoundary:draw(1, 0, 0, 0.2)
			end
		end
	end
end

-- Local values: i, x1, z1, x2, z2, x3, z3, dir1X, dir1Z, dir2X, dir2Z, angle
function FieldCourseField.thightCornerExtension(boundaryPositions)
	for v202_ = 1, #boundaryPositions - 2 do
		local v203_ = boundaryPositions[v202_][1]
		local v204_ = boundaryPositions[v202_][2]
		local v205_ = boundaryPositions[v202_ + 1][1]
		local v206_ = boundaryPositions[v202_ + 1][2]
		local v207_ = boundaryPositions[v202_ + 2][1]
		local v208_ = boundaryPositions[v202_ + 2][2]
		local v209_, v210_ = MathUtil.vector2Normalize(v205_ - v203_, v206_ - v204_)
		local v211_, v212_ = MathUtil.vector2Normalize(v205_ - v207_, v206_ - v208_)
		local v213_ = MathUtil.dotProduct(v209_, 0, v210_, v211_, 0, v212_)
		if 3.141592653589793 - math.acos(v213_) > FieldCourseField.THIGHT_CORNER_ANGLE then
			local v214_ = boundaryPositions[v202_ + 1]
			local v215_ = boundaryPositions[v202_ + 1]
			local v216_ = v205_ + v209_ * 0.1
			local v217_ = v206_ + v210_ * 0.1
			v214_[1] = v216_
			v215_[2] = v217_
			local v218_ = v202_ + 1
			local v219_ = { v205_ + v211_ * 0.1, v206_ + v212_ * 0.1 }
			table.insert(boundaryPositions, v218_, v219_)
		end
	end
end

function FieldCourseField.registerXMLPaths(schema, path)
	schema:register(XMLValueType.STRING, path .. ".boundary#positions", "List of boundary positions (x z)")
	schema:register(XMLValueType.STRING, path .. ".island(?)#positions", "List of boundary positions (x z)")
end
