AIFieldCourseTurn = {}
local AIFieldCourseTurn_mt = Class(AIFieldCourseTurn)
function AIFieldCourseTurn.new(turnData, segments)
	local self = setmetatable({}, AIFieldCourseTurn_mt)
	self.turnData = turnData
	self.segments = segments
	self.offset = 0
	self.cost = 1
	self.numNextSegmentIntersections = 0
	self.numBoundaryIntersections = 0
	self.length = 0
	self:updateLength()
	return self
end
function AIFieldCourseTurn:updateLength()
	self.length = 0
	for _, segment in ipairs(self.segments) do
		self.length = self.length + segment:getLength()
	end
end
function AIFieldCourseTurn:getPosition(alpha)
	local position = alpha * self.length
	local x = 0
	local z = 0
	local phi = 0
	for _, segment in ipairs(self.segments) do
		local delta = math.min(position, segment:getLength())
		x, z, phi = segment:move(x, z, phi, delta, self.turnData.turnRadius)
		position = position - delta
		if not (position <= 0) then
			continue
		end
		local wx = self.turnData.sx + self.turnData.sDirX * x - self.turnData.sDirZ * z
		local wz = self.turnData.sz + self.turnData.sDirZ * x + self.turnData.sDirX * z
		return wx, wz, phi
	end
end
function AIFieldCourseTurn:iterate(distance, func, extraLength)
	if #self.segments == 0 then
		return
	else
		distance = distance / self.turnData.turnRadius
		if extraLength ~= nil then
			extraLength = extraLength / self.turnData.turnRadius
		end
		local remainingLength = self.length
		local segmentIndex = 1
		local remainingSegmentLength = nil
		func(self.turnData.sx, self.turnData.sz, self.segments[1].drivingDirection)
		local x = 0
		local z = 0
		local phi = 0
		while 0 < remainingLength do
			if self.segments[segmentIndex] == nil then
				break
			end
			local segment = self.segments[segmentIndex]
			if remainingSegmentLength == nil then
				remainingSegmentLength = segment:getLength()
			end
			local delta = math.min(distance, remainingLength, remainingSegmentLength)
			x, z, phi = segment:move(x, z, phi, delta, self.turnData.turnRadius)
			local wx = self.turnData.sx + self.turnData.sDirX * x - self.turnData.sDirZ * z
			local wz = self.turnData.sz + self.turnData.sDirZ * x + self.turnData.sDirX * z
			func(wx, wz, segment.drivingDirection, false)
			remainingLength = remainingLength - delta
			remainingSegmentLength = math.min(remainingSegmentLength - delta, remainingLength)
			if remainingSegmentLength <= 0 then
				if extraLength ~= nil and 0 < extraLength then
					local startX = x
					local startZ = z
					local startPhi = phi
					for i = 0, extraLength, distance do
						delta = math.min(distance, extraLength)
						x, z, phi = segment:move(x, z, phi, delta, self.turnData.turnRadius)
						local wx = self.turnData.sx + self.turnData.sDirX * x - self.turnData.sDirZ * z
						local wz = self.turnData.sz + self.turnData.sDirZ * x + self.turnData.sDirX * z
						func(wx, wz, segment.drivingDirection, true)
					end
					x = startX
					z = startZ
					phi = startPhi
				end
				remainingSegmentLength = nil
				segmentIndex = segmentIndex + 1
			end
		end
	end
end
function AIFieldCourseTurn:updateCost(allowProtectedBoundary, preferOneDrivingDirection)
	self.cost = 1
	self.numNextSegmentIntersections = 0
	self.numBoundaryIntersections = 0
	local offset = math.abs(self.turnData.startOffset) + math.abs(self.turnData.endOffset)
	if 0 < offset then
		self.cost = self.cost * (1 + offset / 10)
	end
	for _, segment in ipairs(self.segments) do
		if segment.drivingDirection < 0 then
			self.cost = self.cost * 1.1
		end
	end
	local hasDirectionChange = false
	for i = 1, #self.segments - 1 do
		if self.segments[i].drivingDirection ~= self.segments[i + 1].drivingDirection then
			hasDirectionChange = true
			break
		end
	end
	if not hasDirectionChange then
		if preferOneDrivingDirection then
			self.cost = self.cost * 0.7
		else
			self.cost = self.cost * 0.9
		end
	end
	local fieldBoundaryLine = self.turnData.protectedBoundary.boundaryLine
	if allowProtectedBoundary then
		fieldBoundaryLine = self.turnData.fieldRootBoundary.boundaryLine
	end
	if not FieldCourseUtil.getIsPointInsideBoundary(self.turnData.sx, self.turnData.sz, fieldBoundaryLine) and not FieldCourseUtil.getIsPointInsideBoundary(self.turnData.ex, self.turnData.ez, fieldBoundaryLine) then
		self.cost = self.cost * 2
		self.numBoundaryIntersections = self.numBoundaryIntersections + 2
	end
	for _, island in ipairs(self.turnData.islands) do
		local boundary = island.protectedBoundary
		if allowProtectedBoundary then
			boundary = island.rootBoundary
		end
		if FieldCourseUtil.getIsPointInsideBoundary(self.turnData.sx, self.turnData.sz, boundary.boundaryLine) and FieldCourseUtil.getIsPointInsideBoundary(self.turnData.ex, self.turnData.ez, boundary.boundaryLine) then
			self.cost = self.cost * 2
			self.numBoundaryIntersections = self.numBoundaryIntersections + 2
		end
	end
	local checkIntersection = function(x1, z1, x2, z2)
		local intersect = nil
		local _ = nil
		if self.turnData.segment2 ~= nil then
			intersect, _, _ = FieldCourseUtil.getSegmentBoundaryIntersection(x1, z1, x2, z2, self.turnData.segment2.positions)
			if intersect then
				self.cost = self.cost * 1.25
				self.numNextSegmentIntersections = self.numNextSegmentIntersections + 1
			end
		end
		intersect, _, _ = FieldCourseUtil.getSegmentBoundaryIntersection(x1, z1, x2, z2, fieldBoundaryLine)
		if intersect then
			self.cost = self.cost * 2
			self.numBoundaryIntersections = self.numBoundaryIntersections + 1
		end
		for _, island in ipairs(self.turnData.islands) do
			local boundary = island.protectedBoundary
			if allowProtectedBoundary then
				boundary = island.rootBoundary
			end
			intersect, _, _ = FieldCourseUtil.getSegmentBoundaryIntersection(x1, z1, x2, z2, boundary.boundaryLine)
			if intersect then
				self.cost = self.cost * 2
				self.numBoundaryIntersections = self.numBoundaryIntersections + 1
			end
		end
		return self.numBoundaryIntersections == 0
	end
	local segmentIndex = 1
	local segmentPosition = nil
	local x = nil
	local z = nil
	local lx = 0
	local lz = 0
	local phi = 0
	local lastX = self.turnData.sx
	local lastZ = self.turnData.sz
	if self.turnData.startOffset < 0 then
		if not checkIntersection(self.turnData.originalTurnData.sx, self.turnData.originalTurnData.sz, self.turnData.sx, self.turnData.sz) then
			return
		end
	elseif 0 < self.turnData.startOffset then
		local x1 = self.turnData.originalTurnData.sx
		local z1 = self.turnData.originalTurnData.sz
		local x2 = self.turnData.sx
		local z2 = self.turnData.sz
		local rootIntersections = FieldCourseUtil.getSegmentNumBoundaryIntersections(x1, z1, x2, z2, fieldBoundaryLine)
		if 1 < rootIntersections then
			self.numBoundaryIntersections = 1
			return
		end
		for _, island in ipairs(self.turnData.islands) do
			local boundary = island.protectedBoundary
			if allowProtectedBoundary then
				boundary = island.rootBoundary
			end
			if 1 < rootIntersections + FieldCourseUtil.getSegmentNumBoundaryIntersections(x1, z1, x2, z2, boundary.boundaryLine) then
				self.numBoundaryIntersections = 1
				return
			end
		end
	end
	local segment = self.segments[segmentIndex]
	while segment ~= nil do
		if segment.distance <= 0.000001 then
			segmentIndex = segmentIndex + 1
			segment = self.segments[segmentIndex]
		end
	end
	while segment ~= nil do
		if segmentPosition == nil then
			segmentPosition = segment.distance
		end
		local delta = math.min(1, segmentPosition)
		if segment.segmentType == AIFieldCourseTurnSegmentType.STRAIGHT then
			delta = segment.distance
		end
		lx, lz, phi = segment:move(lx, lz, phi, delta, self.turnData.turnRadius)
		segmentPosition = segmentPosition - delta
		if segmentPosition <= 0 then
			segmentIndex = segmentIndex + 1
			segmentPosition = nil
		end
		x = self.turnData.sx + self.turnData.sDirX * lx - self.turnData.sDirZ * lz
		z = self.turnData.sz + self.turnData.sDirZ * lx + self.turnData.sDirX * lz
		if not checkIntersection(lastX, lastZ, x, z) then
			return
		end
		lastX = x
		lastZ = z
	end
	if self.turnData.endOffset < 0 then
		checkIntersection(self.turnData.originalTurnData.ex, self.turnData.originalTurnData.ez, self.turnData.ex, self.turnData.ez)
	end
end
function AIFieldCourseTurn:getOverallCost()
	local backwardLength = 0
	for _, segment in ipairs(self.segments) do
		if segment.drivingDirection < 0 then
			backwardLength = backwardLength + segment.distance
		end
	end
	return (self.length - backwardLength) * self.cost + backwardLength * self.cost * 1.15
end
function AIFieldCourseTurn:draw(r, g, b)
	if self.length <= 0 then
		return
	else
		local x = self.turnData.sx
		local z = self.turnData.sz
		local _ = nil
		local steps = math.ceil(self.length / (1 / self.turnData.turnRadius))
		local step = self.length / steps
		for position = step, self.length + 0.01, step do
			local lastX = x
			local lastZ = z
			local lastY = getTerrainHeightAtWorldPos(g_terrainNode, lastX, 0, lastZ) + 0.5
			local alpha = position / self.length
			x, z, _ = self:getPosition(alpha)
			local y = getTerrainHeightAtWorldPos(g_terrainNode, x, 0, z) + 0.5
			local sr = r or alpha
			local sg = g or 1 - alpha
			local sb = b or 0
			drawDebugLine(lastX, lastY, lastZ, sr, sg, sb, x, y, z, sr, sg, sb, true)
		end
	end
end
