SteeringFieldCourse = {}
SteeringFieldCourse.NUM_BITS_SEGMENT_INDEX = 11
SteeringFieldCourse.MAX_SEGMENT_INDEX = 2 ^ SteeringFieldCourse.NUM_BITS_SEGMENT_INDEX - 1
local SteeringFieldCourse_mt = Class(SteeringFieldCourse)
function SteeringFieldCourse.new(fieldCourse)
	local self = setmetatable({}, SteeringFieldCourse_mt)
	self.fieldCourse = fieldCourse
	self.fieldCourseSettings = fieldCourse.fieldCourseSettings
	self.segments = fieldCourse.segments
	self.rootBoundaryLine = fieldCourse.courseField.fieldRootBoundary.boundaryLine
	self.segmentStates = {}
	for i = 1, #self.segments do
		self.segmentStates[i] = false
	end
	self.segmentStatesDirty = false
	self.currentSegment = nil
	self.currentSegmentIndex = -1
	self.currentSegmentIsLeft = false
	self.vehiclePosition = { 0, 0 }
	self.vehicleSteeringEnabled = false
	self.vehicleSteeringEnabledTimer = 0
	return self
end
function SteeringFieldCourse:writeStream(streamId, connection)
	self:writeSegmentStatesToStream(streamId, connection)
	self.fieldCourse:writeStream(streamId, connection)
end
function SteeringFieldCourse.readStream(streamId, connection, callback)
	local segmentStates = {}
	local numSegmentStates = streamReadUIntN(streamId, SteeringFieldCourse.NUM_BITS_SEGMENT_INDEX)
	for i = 1, numSegmentStates do
		segmentStates[i] = streamReadBool(streamId)
	end
	FieldCourse.readStream(streamId, connection, function(fieldCourse)
		if fieldCourse ~= nil then
			local steeringFieldCourse = SteeringFieldCourse.new(fieldCourse)
			for i = 1, #steeringFieldCourse.segmentStates do
				steeringFieldCourse.segmentStates[i] = segmentStates[i] or false
			end
			callback(steeringFieldCourse)
		else
			callback(nil)
		end
	end)
end
function SteeringFieldCourse:writeSegmentStatesToStream(streamId, connection)
	local numSegments = math.min(#self.segmentStates, SteeringFieldCourse.MAX_SEGMENT_INDEX)
	streamWriteUIntN(streamId, numSegments, SteeringFieldCourse.NUM_BITS_SEGMENT_INDEX)
	for i = 1, numSegments do
		streamWriteBool(streamId, self.segmentStates[i])
	end
end
function SteeringFieldCourse.readSegmentStatesFromStream(steeringFieldCourse, streamId, connection)
	local numSegmentStates = streamReadUIntN(streamId, SteeringFieldCourse.NUM_BITS_SEGMENT_INDEX)
	for i = 1, numSegmentStates do
		local state = streamReadBool(streamId)
		if steeringFieldCourse == nil then
			continue
		end
		steeringFieldCourse.segmentStates[i] = state
	end
end
function SteeringFieldCourse:saveToXML(xmlFile, key)
	self.fieldCourse:saveToXML(xmlFile, key)
	local workedLinesStr = ""
	for i = 1, #self.segmentStates do
		if self.segmentStates[i] then
			workedLinesStr = workedLinesStr .. string.format("%d ", i)
		end
	end
	xmlFile:setValue(key .. ".workedLines#indices", string.trim(workedLinesStr))
end
function SteeringFieldCourse.loadFromXML(xmlFile, key, callback)
	local workedLinesStr = xmlFile:getValue(key .. ".workedLines#indices")
	FieldCourse.loadFromXML(xmlFile, key, function(fieldCourse)
		if fieldCourse ~= nil then
			local steeringFieldCourse = SteeringFieldCourse.new(fieldCourse)
			local indices = string.split(workedLinesStr, " ")
			for i = 1, #indices do
				local index = tonumber(indices[i])
				if steeringFieldCourse.segmentStates[index] == nil then
					continue
				end
				steeringFieldCourse.segmentStates[index] = true
			end
			callback(steeringFieldCourse)
		else
			callback(nil)
		end
	end)
end
function SteeringFieldCourse:getIsPointInsideBoundary(x, z)
	if self.fieldCourse.courseField ~= nil then
		return self.fieldCourse.courseField:getIsPointInsideBoundary(x, z)
	else
		return true
	end
end
function SteeringFieldCourse:updateVehicleData(dt, steeringEnabled, vx, vz, vDirX, vDirZ, sideOffsetReversed)
	if steeringEnabled ~= self.vehicleSteeringEnabled then
		self.vehicleSteeringEnabled = steeringEnabled
		self.vehicleSteeringEnabledTimer = 0
	end
	self.vehiclePosition[1] = vx
	self.vehiclePosition[2] = vz
	if not steeringEnabled then
		local maxExtension = self.fieldCourseSettings.implementWidth * self.fieldCourseSettings.numHeadlands
		local minDistanceValid = math.huge
		local minDistanceValidSegmentIndex = -1
		local minDistanceValidIsLeft = false
		for index, segment in ipairs(self.segments) do
			local lx, lz, lDirX, lDirZ, onLineX, onLineZ = FieldCourseUtil.getClosestExtendedPositionAndDirectionOnSegment(vx, vz, segment.positions, maxExtension)
			if lx == nil then
				continue
			end
			local distance = MathUtil.vector2Length(vx - lx, vz - lz)
			if distance < math.min(self.fieldCourseSettings.implementWidth * 3 + math.abs(self.fieldCourseSettings.sideOffset), 20) then
				local isLeft = nil
				local angle = math.acos(MathUtil.dotProduct(lDirX, 0, lDirZ, vDirX, 0, vDirZ))
				if angle < 0.8796459430051422 then
					isLeft = true
				elseif 2.261946710584651 < angle then
					isLeft = false
				end
				if isLeft == nil then
					continue
				end
				local offsetX = vx - vDirX
				local offsetZ = vz - vDirZ
				local dlx, dlz = MathUtil.vector2Normalize(onLineX - offsetX, onLineZ - offsetZ)
				local isForward = 0 < MathUtil.dotProduct(dlx, 0, dlz, vDirX, 0, vDirZ)
				if sideOffsetReversed then
					isLeft = not isLeft
				end
				local offset = (isLeft and 1 or -1) * self.fieldCourseSettings.sideOffset
				lx = lx + lDirZ * offset
				lz = lz - lDirX * offset
				distance = MathUtil.vector2Length(vx - lx, vz - lz)
				if 1.5707963267948966 < angle then
					angle = 3.141592653589793 - angle
				end
				local factor = 1 + math.max(angle / 0.7853981633974483 - 0.25, 0)
				if not isForward then
					factor = factor * 1.5
				end
				distance = distance * factor
				if distance < minDistanceValid then
					minDistanceValid = distance
					minDistanceValidSegmentIndex = index
					minDistanceValidIsLeft = isLeft
				end
			end
		end
		return self:setCurrentSegmentIndex(minDistanceValidSegmentIndex, minDistanceValidIsLeft)
	else
		self.vehicleSteeringEnabledTimer = self.vehicleSteeringEnabledTimer + dt
		if 2500 < self.vehicleSteeringEnabledTimer and (0 < self.currentSegmentIndex and not self.segmentStates[self.currentSegmentIndex]) then
			self.segmentStates[self.currentSegmentIndex] = true
			self.segmentStatesDirty = true
		end
		return false
	end
end
function SteeringFieldCourse:setCurrentSegmentIndex(segmentIndex, isLeft)
	if segmentIndex ~= self.currentSegmentIndex or isLeft ~= self.currentSegmentIsLeft then
		self.currentSegment = self.segments[segmentIndex]
		if self.currentSegment ~= nil then
			self.currentSegmentIndex = segmentIndex
			if isLeft ~= nil then
				self.currentSegmentIsLeft = isLeft
			else
				self.currentSegmentIsLeft = false
			end
			if self.fieldCourseSettings.sideOffset ~= 0 then
				if self.currentSegmentIsLeft then
					self.currentSegment = table.clone(self.currentSegment, 3)
					FieldCourseBoundary.segmentApplySideOffset(self.currentSegment, self.fieldCourseSettings.sideOffset)
				else
					self.currentSegment = table.clone(self.currentSegment, 3)
					FieldCourseBoundary.segmentApplySideOffset(self.currentSegment, -self.fieldCourseSettings.sideOffset)
				end
			end
		else
			self.currentSegmentIndex = -1
			self.currentSegmentIsLeft = false
		end
		return true
	end
	return false
end
function SteeringFieldCourse:resetCurrentSegment()
	self.vehicleSteeringEnabled = false
	if self.currentSegment ~= nil then
		self.currentSegment = nil
		self.currentSegmentIndex = -1
		self.currentSegmentIsLeft = false
		return true
	else
		return false
	end
end
function SteeringFieldCourse.getClosestPositionSegment(segment, wx, wz)
	local minDistance = math.huge
	local minDistanceIndex = -1
	local minDistanceHitX = 0
	local minDistanceHitZ = 0
	local numPositions = #segment.positions
	for i = 1, numPositions - 1 do
		local x1 = segment.positions[i][1]
		local z1 = segment.positions[i][2]
		local x2 = segment.positions[i + 1][1]
		local z2 = segment.positions[i + 1][2]
		local dirX = x2 - x1
		local dirZ = z2 - z1
		local length = MathUtil.vector2Length(dirX, dirZ)
		dirX = dirX / length
		dirZ = dirZ / length
		local dot = MathUtil.getProjectOnLineParameter(wx, wz, x1, z1, dirX, dirZ)
		if 0 <= dot and dot <= length then
			local hitX = x1 + dirX * dot
			local hitZ = z1 + dirZ * dot
			local distance = MathUtil.vector2Length(hitX - wx, hitZ - wz)
			if distance < minDistance then
				minDistance = distance
				minDistanceIndex = i
				minDistanceHitX = hitX
				minDistanceHitZ = hitZ
			end
		end
	end
	return minDistanceHitX, minDistanceHitZ, minDistanceIndex
end
function SteeringFieldCourse:getSteeringTarget(aiRootNode, lookAHeadDistance, sideOffsetReversed)
	if self.currentSegment ~= nil then
		local segment = self.currentSegment
		local numPositions = #segment.positions
		local distanceToEnd = nil
		local wx, y, wz = getWorldTranslation(aiRootNode)
		local ox, _, oz = localToWorld(aiRootNode, 0, 0, lookAHeadDistance)
		local minDistanceHitX, minDistanceHitZ, minDistanceIndex = SteeringFieldCourse.getClosestPositionSegment(segment, wx, wz)
		if 0 < minDistanceIndex then
			if minDistanceIndex == 1 then
				local x1 = segment.positions[1][1]
				local z1 = segment.positions[1][2]
				local x2 = segment.positions[2][1]
				local z2 = segment.positions[2][2]
				local segmentLength = MathUtil.vector2Length(x2 - x1, z2 - z1)
				distanceToEnd = MathUtil.vector2Length(minDistanceHitX - x1, minDistanceHitZ - z1)
				if numPositions == 2 and segmentLength * 0.5 < distanceToEnd then
					distanceToEnd = segmentLength - distanceToEnd
				end
			elseif minDistanceIndex == numPositions - 1 then
				distanceToEnd = MathUtil.vector2Length(minDistanceHitX - segment.positions[numPositions][1], minDistanceHitZ - segment.positions[numPositions][2])
			end
			local minDistanceOffsetHitX, minDistanceOffsetHitZ, minDistanceOffsetIndex = SteeringFieldCourse.getClosestPositionSegment(segment, ox, oz)
			if 0 < minDistanceOffsetIndex then
				local tX, _, tZ = worldToLocal(aiRootNode, minDistanceOffsetHitX, y, minDistanceOffsetHitZ)
				return tX, tZ, distanceToEnd
			end
		end
		local x1 = segment.positions[1][1]
		local z1 = segment.positions[1][2]
		local x2 = segment.positions[2][1]
		local z2 = segment.positions[2][2]
		local x3 = segment.positions[numPositions][1]
		local z3 = segment.positions[numPositions][2]
		local x4 = segment.positions[numPositions - 1][1]
		local z4 = segment.positions[numPositions - 1][2]
		local startDistance = MathUtil.vector2Length(x1 - ox, z1 - oz)
		local endDistance = MathUtil.vector2Length(x3 - ox, z3 - oz)
		if startDistance < endDistance then
			local dirX, dirZ = MathUtil.vector2Normalize(x1 - x2, z1 - z2)
			local dot = MathUtil.getProjectOnLineParameter(ox, oz, x1, z1, dirX, dirZ)
			local hitX = x1 + dirX * dot
			local hitZ = z1 + dirZ * dot
			local tX, _, tZ = worldToLocal(aiRootNode, hitX, y, hitZ)
			return tX, tZ, distanceToEnd
		else
			local dirX, dirZ = MathUtil.vector2Normalize(x3 - x4, z3 - z4)
			local dot = MathUtil.getProjectOnLineParameter(ox, oz, x3, z3, dirX, dirZ)
			local hitX = x3 + dirX * dot
			local hitZ = z3 + dirZ * dot
			local tX, _, tZ = worldToLocal(aiRootNode, hitX, y, hitZ)
			return tX, tZ, distanceToEnd
		end
	end
	return 0, 0, nil
end
function SteeringFieldCourse:draw()
	if self.fieldCourse.courseField ~= nil then
		self.fieldCourse.courseField:draw()
	end
	if self.fieldCourse.fieldCourseSettings ~= nil then
		self.fieldCourse.fieldCourseSettings:draw()
	end
end
function SteeringFieldCourse.registerXMLPaths(schema, path)
	FieldCourseSettings.registerXMLPaths(schema, path .. ".fieldCourseSettings")
	FieldCourseField.registerXMLPaths(schema, path .. ".field")
	schema:register(XMLValueType.STRING, path .. ".workedLines#indices", "List of worked line indices")
end
