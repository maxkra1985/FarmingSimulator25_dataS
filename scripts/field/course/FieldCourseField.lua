FieldCourseField = {}
local FieldCourseField_mt = Class(FieldCourseField)
FieldCourseField.NUM_BOUNDARY_SYNC_BITS = 9
FieldCourseField.MAX_BOUNDARY_SIZE = 2 ^ FieldCourseField.NUM_BOUNDARY_SYNC_BITS - 1
FieldCourseField.NUM_ISLANDS_SYNC_BITS = 5
FieldCourseField.MAX_ISLAND_AMOUNT = 2 ^ FieldCourseField.NUM_ISLANDS_SYNC_BITS - 1
FieldCourseField.MIN_BOUNDARY_LENGTH = 20
FieldCourseField.THIGHT_CORNER_ANGLE = 2.443460952792061
function FieldCourseField.new(fieldCourseSettings)
	local self = setmetatable({}, FieldCourseField_mt)
	self.fieldCourseSettings = fieldCourseSettings
	self.segmentSplitAngle = math.rad(fieldCourseSettings.segmentSplitAngle)
	self.boundaryPositions = {}
	self.headlandBoundaries = {}
	self.islandBoundaries = {}
	self.state = FieldCourseDetectionState.BOUNDARY_DETECTION
	self.boundaryCollisionCheckSegmentIndex = 0
	self.boundaryCollisionCheckPending = false
	self.boundaryCollisionCheckRequiresSegmentUpdate = false
	self.ignoreIslands = false
	self.ignoreCollisions = false
	return self
end
function FieldCourseField.generateAtPosition(x, z, fieldCourseSettings, callback, callbackTarget)
	x, z = g_fieldCourseManager:roundToTerrainDetailPixel(x, z)
	local field = FieldCourseField.new(fieldCourseSettings)
	field:detectAtPosition(x, z, callback, callbackTarget)
	return field
end
function FieldCourseField:reset()
	self.headlandBoundaries = {}
	if self.islands ~= nil then
		for _, island in ipairs(self.islands) do
			island.boundaries = {}
			island.hasCutSegments = false
		end
	end
end
function FieldCourseField:setIgnoreIslands(ignoreIslands)
	self.ignoreIslands = ignoreIslands
end
function FieldCourseField:setIgnoreCollisions(ignoreCollisions)
	self.ignoreCollisions = ignoreCollisions
end
function FieldCourseField:detectAtPosition(x, z, callback, callbackTarget)
	self.startX = x
	self.startZ = z
	self.callback = callback
	self.callbackTarget = callbackTarget
	self.terrainDetailResolution = g_currentMission.terrainSize / g_currentMission.terrainDetailMapSize
	self.islandSamplePoints = {}
	local y = getTerrainHeightAtWorldPos(g_terrainNode, x, 0, z)
	local _, _, _, riceField = PlaceableRiceField.getRiceFieldAtPosition(x, y, z)
	if riceField ~= nil then
		local numVerts = riceField.polygon:getNumVertices()
		for i = 1, numVerts do
			local x, z = riceField.polygon:getVertex(i)
			table.insert(self.boundaryPositions, { x, z })
		end
		local x, z = riceField.polygon:getVertex(1)
		table.insert(self.boundaryPositions, { x, z })
		if FieldCourseBoundary.getIsBoundaryLineInverted(self.boundaryPositions) then
			local inverted = {}
			for i = #self.boundaryPositions, 1, -1 do
				table.insert(inverted, self.boundaryPositions[i])
			end
			self.boundaryPositions = inverted
		end
		for i = 1, #self.boundaryPositions do
			self.boundaryPositions[i][1], self.boundaryPositions[i][2] = g_fieldCourseManager:roundToTerrainDetailPixel(self.boundaryPositions[i][1], self.boundaryPositions[i][2])
		end
		self.fieldRootBoundary = FieldCourseBoundary.createByBoundaryLine(self.boundaryPositions, self.segmentSplitAngle)
		self.fieldRootBoundary = self.fieldRootBoundary:extend(0.75)
		if self.fieldRootBoundary ~= nil then
			self.boundaryPositions = table.clone(self.fieldRootBoundary.boundaryLine, math.huge)
			self:finishTask(true)
			return self
		else
			Logging.warning("Failed to create field boundary from rice field")
			self:finishTask(false)
			return nil
		end
	else
		self.boundaryDetectionTask = BoundaryDetectionTask.new(x, z)
		if self.boundaryDetectionTask == nil then
			self:finishTask(false)
			return nil
		else
			return
		end
	end
end
function FieldCourseField:saveToXML(xmlFile, key)
	local boundaryPositionStr = ""
	for i = 1, #self.boundaryPositions do
		boundaryPositionStr = boundaryPositionStr .. string.format("%.2f %.2f ", self.boundaryPositions[i][1], self.boundaryPositions[i][2])
	end
	xmlFile:setValue(key .. ".boundary#positions", string.trim(boundaryPositionStr))
	for i, island in ipairs(self.islands) do
		local islandKey = string.format("%s.island(%d)", key, i - 1)
		local islandBoundaryPositionStr = ""
		for j = 1, #island.rootBoundary.boundaryLine do
			islandBoundaryPositionStr = islandBoundaryPositionStr .. string.format("%.2f %.2f ", island.rootBoundary.boundaryLine[j][1], island.rootBoundary.boundaryLine[j][2])
		end
		xmlFile:setValue(islandKey .. "#positions", string.trim(islandBoundaryPositionStr))
	end
end
function FieldCourseField:loadFromXML(xmlFile, key)
	if not xmlFile:hasProperty(key) then
		return false
	end
	local boundaryStr = xmlFile:getValue(key .. ".boundary#positions")
	if boundaryStr == nil then
		return false
	end
	self.boundaryPositions = {}
	local positions = string.split(boundaryStr, " ")
	for i = 1, #positions, 2 do
		local x = tonumber(positions[i])
		local z = tonumber(positions[i + 1])
		table.insert(self.boundaryPositions, { x, z })
	end
	self.fieldRootBoundary = FieldCourseBoundary.createByBoundaryLine(self.boundaryPositions, self.segmentSplitAngle)
	if self.fieldRootBoundary == nil then
		Logging.xmlWarning(xmlFile, "Failed to create fieldRootBoundary from '%s' in '%s'", boundaryStr, key)
		return false
	else
		self.islands = {}
		for _, key in xmlFile:iterator(key .. ".island") do
			local islandBoundaryStr = xmlFile:getValue(key .. "#positions")
			if islandBoundaryStr == nil then
				break
			end
			local island = {}
			island.boundaries = {}
			island.hasCutSegments = false
			local boundaryLine = {}
			local islandPositions = string.split(islandBoundaryStr, " ")
			for i = 1, #islandPositions, 2 do
				local x = tonumber(islandPositions[i])
				local z = tonumber(islandPositions[i + 1])
				table.insert(boundaryLine, { x, z })
			end
			island.rootBoundary = FieldCourseBoundary.createByBoundaryLine(boundaryLine, self.segmentSplitAngle)
			table.insert(self.islands, island)
		end
		self.state = FieldCourseDetectionState.FINISHED
		return true
	end
end
function FieldCourseField:writeStream(streamId, connection)
	streamWriteUIntN(streamId, #self.boundaryPositions, FieldCourseField.NUM_BOUNDARY_SYNC_BITS)
	for i = 1, #self.boundaryPositions do
		g_fieldCourseManager:writeTerrainDetailPixel(streamId, self.boundaryPositions[i][1], self.boundaryPositions[i][2])
	end
	streamWriteUIntN(streamId, #self.islands, FieldCourseField.NUM_ISLANDS_SYNC_BITS)
	for _, island in ipairs(self.islands) do
		streamWriteUIntN(streamId, #island.rootBoundary.boundaryLine, FieldCourseField.NUM_BOUNDARY_SYNC_BITS)
		for i = 1, #island.rootBoundary.boundaryLine do
			g_fieldCourseManager:writeTerrainDetailPixel(streamId, island.rootBoundary.boundaryLine[i][1], island.rootBoundary.boundaryLine[i][2])
		end
	end
end
function FieldCourseField:readStream(streamId, connection)
	self.boundaryPositions = {}
	local numBoundaryPositions = streamReadUIntN(streamId, FieldCourseField.NUM_BOUNDARY_SYNC_BITS)
	for i = 1, numBoundaryPositions do
		local x, z = g_fieldCourseManager:readTerrainDetailPixel(streamId)
		table.insert(self.boundaryPositions, { x, z })
	end
	self.fieldRootBoundary = FieldCourseBoundary.createByBoundaryLine(self.boundaryPositions, self.segmentSplitAngle)
	self.islands = {}
	local numIslands = streamReadUIntN(streamId, FieldCourseField.NUM_ISLANDS_SYNC_BITS)
	for i = 1, numIslands do
		local island = {}
		island.boundaries = {}
		island.hasCutSegments = false
		local boundaryLine = {}
		numBoundaryPositions = streamReadUIntN(streamId, FieldCourseField.NUM_BOUNDARY_SYNC_BITS)
		for j = 1, numBoundaryPositions do
			local x, z = g_fieldCourseManager:readTerrainDetailPixel(streamId)
			table.insert(boundaryLine, { x, z })
		end
		island.rootBoundary = FieldCourseBoundary.createByBoundaryLine(boundaryLine, self.segmentSplitAngle)
		table.insert(self.islands, island)
	end
	self.state = FieldCourseDetectionState.FINISHED
end
function FieldCourseField:update(dt, frameBudget)
	if self.state == FieldCourseDetectionState.BOUNDARY_DETECTION then
		if self.boundaryDetectionTask ~= nil and not self.boundaryDetectionTask:update(dt, frameBudget) then
			if 0 < #self.boundaryDetectionTask.boundaryPositions then
				self.state = FieldCourseDetectionState.BOUNDARY_SIMPLIFICATION1
			else
				self:finishTask(false)
			end
		end
	elseif self.state == FieldCourseDetectionState.BOUNDARY_SIMPLIFICATION1 then
		local boundaryPositions = self.boundaryDetectionTask.boundaryPositions
		FieldCourseUtil.pointAveragePositions(boundaryPositions)
		for i = #boundaryPositions, 1, -2 do
			table.remove(boundaryPositions, i)
		end
		boundaryPositions[1][1] = boundaryPositions[#boundaryPositions][1]
		boundaryPositions[1][2] = boundaryPositions[#boundaryPositions][2]
		FieldCourseUtil.semiConvexSimplification(boundaryPositions, 10)
		FieldCourseUtil.douglasPeucker(boundaryPositions, 0.25)
		self.state = FieldCourseDetectionState.BOUNDARY_SIMPLIFICATION2
	elseif self.state == FieldCourseDetectionState.BOUNDARY_SIMPLIFICATION2 then
		local boundaryPositions = self.boundaryDetectionTask.boundaryPositions
		if not FieldCourseUtil.getIsPointInsideBoundary(self.startX, self.startZ, boundaryPositions) then
			local maxZ = self.boundaryDetectionTask:getMaxZ()
			self.boundaryDetectionTask = BoundaryDetectionTask.new(self.startX, maxZ + self.terrainDetailResolution)
			if self.boundaryDetectionTask == nil then
				self:finishTask(false)
			else
				self.state = FieldCourseDetectionState.BOUNDARY_DETECTION
			end
		else
			for i = 1, #boundaryPositions do
				boundaryPositions[i][1], boundaryPositions[i][2] = g_fieldCourseManager:roundToTerrainDetailPixel(boundaryPositions[i][1], boundaryPositions[i][2])
			end
			FieldCourseUtil.visvalingamWhyattSimplification(boundaryPositions, 5)
			FieldCourseUtil.douglasPeucker(boundaryPositions, 0.5)
			local length = 0
			for i = 1, #boundaryPositions - 1 do
				local x1 = boundaryPositions[i][1]
				local z1 = boundaryPositions[i][2]
				local x2 = boundaryPositions[i + 1][1]
				local z2 = boundaryPositions[i + 1][2]
				length = length + MathUtil.vector2Length(x1 - x2, z1 - z2)
				if not (FieldCourseField.MIN_BOUNDARY_LENGTH <= length) then
					continue
				end
				if length < FieldCourseField.MIN_BOUNDARY_LENGTH then
					self:finishTask(false)
				else
					self.boundaryPositions = boundaryPositions
					self.state = FieldCourseDetectionState.BOUNDARY_SEGMENT_CREATION
				end
				self.boundaryDetectionTask = nil
				return self.state ~= FieldCourseDetectionState.FINISHED
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
		local fieldRootBoundary = self.fieldRootBoundary:extend(2.5)
		if fieldRootBoundary == nil then
			self.state = FieldCourseDetectionState.BOUNDARY_COLLISION_CHECK
		else
			self.fieldRootBoundary = fieldRootBoundary
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
			self.fieldRootBoundary:segmentCollisionOffset(5, 1, function(segmentsAdjusted)
				local boundaryLine = self.fieldRootBoundary.boundaryLine
				for i = 1, #boundaryLine do
					boundaryLine[i][1], boundaryLine[i][2] = g_fieldCourseManager:roundToTerrainDetailPixel(boundaryLine[i][1], boundaryLine[i][2])
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
			local islandPositions = self.curIslandDetectionTask.boundaryPositions
			FieldCourseUtil.pointAveragePositions(islandPositions)
			local invertedPositions = {}
			for i = #islandPositions, 1, -1 do
				table.insert(invertedPositions, islandPositions[i])
			end
			FieldCourseUtil.semiConvexSimplification(invertedPositions, 15)
			islandPositions = {}
			for i = #invertedPositions, 1, -1 do
				table.insert(islandPositions, invertedPositions[i])
			end
			FieldCourseUtil.douglasPeucker(islandPositions, 0.25)
			FieldCourseUtil.visvalingamWhyattSimplification(islandPositions, 5)
			local sx = islandPositions[1][1]
			local sz = islandPositions[1][2]
			local isValid = true
			for _, island in ipairs(self.islandBoundaries) do
				if FieldCourseUtil.getAreBoundariesColliding(island.boundaryLine, islandPositions) then
					isValid = false
					break
				end
				if FieldCourseUtil.getIsPointInsideBoundary(sx, sz, island.boundaryLine) then
					isValid = false
					break
				end
			end
			if isValid then
				local boundary = FieldCourseBoundary.createByBoundaryLine(islandPositions, self.segmentSplitAngle)
				if boundary ~= nil then
					local offsetBoundary = boundary:extend(-0.25)
					if offsetBoundary == nil then
						Logging.error("FieldCourseField: Failed to extend island boundary")
					end
					boundary = offsetBoundary or boundary
					local boundaryLine = boundary.boundaryLine
					for i = 1, #boundaryLine do
						boundaryLine[i][1], boundaryLine[i][2] = g_fieldCourseManager:roundToTerrainDetailPixel(boundaryLine[i][1], boundaryLine[i][2])
					end
					boundary:regenerateSegments()
					table.insert(self.islandBoundaries, boundary)
				end
			end
			self.curIslandDetectionTask = nil
			if #self.islandSamplePoints == 0 then
				self:finishTask(true)
			end
		end
		if (0 < #self.islandSamplePoints or self.islandSamplePointsDetected == false) and not self:continueIslandDetection(frameBudget) then
			self:finishTask(true)
		end
	end
end
function FieldCourseField:setProtectedBoundary(protectedBoundarySize)
	self.protectedBoundary = self.fieldRootBoundary:extend(protectedBoundarySize) or self.fieldRootBoundary
	for _, island in ipairs(self.islands) do
		island.protectedBoundary = island.rootBoundary:extend(-protectedBoundarySize) or island.rootBoundary
	end
	return self.protectedBoundary
end
function FieldCourseField:finishTask(success)
	self.state = FieldCourseDetectionState.FINISHED
	if success then
		self.islands = {}
		for _, islandBoundary in ipairs(self.islandBoundaries) do
			local island = {}
			island.rootBoundary = islandBoundary
			island.boundaries = {}
			island.hasCutSegments = false
			table.insert(self.islands, island)
		end
		self.islandBoundaries = nil
	end
	if self.callbackTarget ~= nil then
		self.callback(self.callbackTarget, self, success)
	else
		if self.callback ~= nil then
			self.callback(self, success)
		end
	end
end
function FieldCourseField:generateBoundingBoxFromBoundary(boundary)
	if #boundary == 0 then
		return { 0, 0, 0, 0 }
	else
		local boundingBox = { math.huge, -math.huge, math.huge, -math.huge }
		for i = 1, #boundary do
			boundingBox[1] = math.min(boundingBox[1], boundary[i][1])
			boundingBox[2] = math.max(boundingBox[2], boundary[i][1])
			boundingBox[3] = math.min(boundingBox[3], boundary[i][2])
			boundingBox[4] = math.max(boundingBox[4], boundary[i][2])
		end
		return boundingBox
	end
end
function FieldCourseField:islandDetection(boundary)
	self.islandSamplePoints = {}
	self.islandSamplePointsDetected = false
	self.islandSamplePointsBoundingBox = self:generateBoundingBoxFromBoundary(boundary)
	self.islandSamplePointsLastX = self.islandSamplePointsBoundingBox[1]
	local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = g_currentMission.fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
	if groundTypeMapId ~= nil then
		self.islandSampleModifier = DensityMapModifier.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, g_terrainNode)
		self.islandSampleFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
		self.islandSampleFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)
		if not self:continueIslandDetection(0) then
			self:finishTask(true)
		end
	else
		self:finishTask(true)
	end
end
function FieldCourseField:continueIslandDetection(frameBudget)
	if not self.islandSamplePointsDetected then
		local startTime = getTimeSec()
		local terrainDetailId = g_currentMission.terrainDetailId
		local boundingBox = self.islandSamplePointsBoundingBox
		local rasterSize = 15
		local subRasterSize = 1
		for x = self.islandSamplePointsLastX, boundingBox[2], 15 do
			for z = boundingBox[3], boundingBox[4], 15 do
				local x1 = x
				local z1 = z
				local x2 = x + 15
				local z2 = z
				local x3 = x
				local z3 = z + 15
				self.islandSampleModifier:setParallelogramWorldCoords(x1, z1, x2, z2, x3, z3, DensityCoordType.POINT_POINT_POINT)
				local _, numPixels, totalPixels = self.islandSampleModifier:executeGet(self.islandSampleFilter)
				if numPixels < totalPixels then
					local x4 = x + 15
					local z4 = z + 15
					if FieldCourseUtil.getIsPointInsideBoundary(x1, z1, self.boundaryPositions) and (FieldCourseUtil.getIsPointInsideBoundary(x2, z2, self.boundaryPositions) and (FieldCourseUtil.getIsPointInsideBoundary(x3, z3, self.boundaryPositions) and FieldCourseUtil.getIsPointInsideBoundary(x4, z4, self.boundaryPositions))) then
						local lastState = false
						local foundPosition = false
						for subX = x1, x2 do
							for subZ = z1, z3 do
								if getDensityAtWorldPos(terrainDetailId, subX, 0, subZ) ~= 0 ~= lastState then
									lastState = not lastState
									if not lastState and (FieldCourseUtil.getIsPointInsideBoundary(subX, subZ, self.boundaryPositions) and (FieldCourseUtil.getIsPointInsideBoundary(subX + 2, subZ + 2, self.boundaryPositions) and (FieldCourseUtil.getIsPointInsideBoundary(subX - 2, subZ - 2, self.boundaryPositions) and (FieldCourseUtil.getIsPointInsideBoundary(subX - 2, subZ + 2, self.boundaryPositions) and (FieldCourseUtil.getIsPointInsideBoundary(subX + 2, subZ - 2, self.boundaryPositions) and 3 < FieldCourseUtil.getDistanceToBoundary(subX, subZ, self.boundaryPositions)))))) then
										foundPosition = true
										table.insert(self.islandSamplePoints, { subX, subZ })
									end
								end
								if not foundPosition then
									continue
								end
							end
						end
					end
				end
			end
			self.islandSamplePointsLastX = x + 15
			local delta = getTimeSec() - startTime
			if frameBudget < delta then
				break
			end
		end
		if boundingBox[2] <= self.islandSamplePointsLastX then
			self.islandSamplePointsDetected = true
			if #self.islandSamplePoints <= 0 then
				return false
			end
		end
		return true
	else
		if self.curIslandDetectionTask == nil then
			while 0 < #self.islandSamplePoints do
				local p = self.islandSamplePoints[#self.islandSamplePoints]
				local x = p[1]
				local z = p[2]
				self.islandSamplePoints[#self.islandSamplePoints] = nil
				local isValid = true
				for _, island in ipairs(self.islandBoundaries) do
					if FieldCourseUtil.getIsPointInsideBoundary(x, z, island.boundaryLine) then
						isValid = false
						break
					end
				end
				if isValid then
					self.curIslandDetectionTask = BoundaryDetectionTaskInsideOut.new(x, z)
					break
				end
			end
		end
		return 0 < #self.islandSamplePoints or self.curIslandDetectionTask ~= nil
	end
end
function FieldCourseField:getIsPointInsideBoundary(x, z)
	return FieldCourseUtil.getIsPointInsideBoundary(x, z, self.boundaryPositions) or FieldCourseUtil.getIsPointInsideBoundary(x + 2, z + 2, self.boundaryPositions) or FieldCourseUtil.getIsPointInsideBoundary(x - 2, z - 2, self.boundaryPositions) or FieldCourseUtil.getIsPointInsideBoundary(x + 2, z - 2, self.boundaryPositions) or FieldCourseUtil.getIsPointInsideBoundary(x - 2, z + 2, self.boundaryPositions)
end
function FieldCourseField:getBoundingBox()
	local numPositions = #self.boundaryPositions
	if numPositions == 0 then
		return 0, 0, 0, 0
	else
		local minX = math.huge
		local maxX = -math.huge
		local minZ = math.huge
		local maxZ = -math.huge
		for _, pos in ipairs(self.boundaryPositions) do
			minX = math.min(minX, pos[1])
			maxX = math.max(maxX, pos[1])
			minZ = math.min(minZ, pos[2])
			maxZ = math.max(maxZ, pos[2])
		end
		return minX, maxX, minZ, maxZ
	end
end
function FieldCourseField:draw()
	if self.fieldRootBoundary ~= nil then
		self.fieldRootBoundary:draw(0, 0, 1, 0.2)
	end
	if self.protectedBoundary ~= nil then
		self.protectedBoundary:draw(1, 0, 0, 0.2)
	end
	if self.islands ~= nil then
		for _, island in ipairs(self.islands) do
			if island.rootBoundary ~= nil then
				island.rootBoundary:draw(0, 0, 1, 0.2)
			end
			if island.protectedBoundary == nil then
				continue
			end
			island.protectedBoundary:draw(1, 0, 0, 0.2)
		end
	end
end
function FieldCourseField.thightCornerExtension(boundaryPositions)
	for i = 1, #boundaryPositions - 2 do
		local x1 = boundaryPositions[i][1]
		local z1 = boundaryPositions[i][2]
		local x2 = boundaryPositions[i + 1][1]
		local z2 = boundaryPositions[i + 1][2]
		local x3 = boundaryPositions[i + 2][1]
		local z3 = boundaryPositions[i + 2][2]
		local dir1X, dir1Z = MathUtil.vector2Normalize(x2 - x1, z2 - z1)
		local dir2X, dir2Z = MathUtil.vector2Normalize(x2 - x3, z2 - z3)
		local angle = 3.141592653589793 - math.acos(MathUtil.dotProduct(dir1X, 0, dir1Z, dir2X, 0, dir2Z))
		if FieldCourseField.THIGHT_CORNER_ANGLE < angle then
			boundaryPositions[i + 1][1] = x2 + dir1X * 0.1
			boundaryPositions[i + 1][2] = z2 + dir1Z * 0.1
			table.insert(boundaryPositions, i + 1, { x2 + dir2X * 0.1, z2 + dir2Z * 0.1 })
		end
	end
end
function FieldCourseField.registerXMLPaths(schema, path)
	schema:register(XMLValueType.STRING, path .. ".boundary#positions", "List of boundary positions (x z)")
	schema:register(XMLValueType.STRING, path .. ".island(?)#positions", "List of boundary positions (x z)")
end
