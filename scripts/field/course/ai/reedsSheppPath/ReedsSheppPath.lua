ReedsSheppPath = {}
local ReedsSheppPath_mt = Class(ReedsSheppPath)
function ReedsSheppPath.new(turnData, forcedDirection)
	local self = setmetatable({}, ReedsSheppPath_mt)
	self.turnData = turnData
	self.forcedDirection = forcedDirection or 0
	self.sAngle = MathUtil.getYRotationFromDirection(turnData.sDirX, turnData.sDirZ)
	self.eAngle = MathUtil.getYRotationFromDirection(turnData.eDirX, turnData.eDirZ)
	self.helperTransformGroup = createTransformGroup("helper")
	link(getRootNode(), self.helperTransformGroup)
	setTranslation(self.helperTransformGroup, turnData.sx, 0, turnData.sz)
	setDirection(self.helperTransformGroup, turnData.sDirX, 0, turnData.sDirZ, 0, 1, 0)
	local z, _, x = worldToLocal(self.helperTransformGroup, turnData.ex, 0, turnData.ez)
	local dx, _, dz = worldDirectionToLocal(self.helperTransformGroup, turnData.eDirX, 0, turnData.eDirZ)
	self.phi = MathUtil.getYRotationFromDirection(dx, dz)
	self.z = z / turnData.turnRadius
	self.x = x / turnData.turnRadius
	delete(self.helperTransformGroup)
	return self
end
function ReedsSheppPath:generate(callback)
	if self.forcedDirection == 0 then
		for _, func in pairs(ReedsSheppPath.PATH_FUNCTIONS) do
			local segments = func(self.x, self.z, self.phi)
			if segments ~= nil then
				callback(AIFieldCourseTurn.new(self.turnData, segments))
			end
			segments = func(-self.x, self.z, -self.phi)
			if segments ~= nil then
				callback(AIFieldCourseTurn.new(self.turnData, self:inverseDirection(segments)))
			end
			segments = func(self.x, -self.z, -self.phi)
			if segments ~= nil then
				callback(AIFieldCourseTurn.new(self.turnData, self:inverseSteering(segments)))
			end
			segments = func(-self.x, -self.z, self.phi)
			if segments == nil then
				continue
			end
			callback(AIFieldCourseTurn.new(self.turnData, self:inverse(segments)))
		end
	else
		for _, func in pairs(ReedsSheppPath.FORWARD_FUNCTIONS) do
			if self.forcedDirection == 1 then
				local segments = func(self.x, self.z, self.phi)
				if segments == nil then
					continue
				end
				callback(AIFieldCourseTurn.new(self.turnData, segments))
			else
				local segments = func(-self.x, -self.z, self.phi)
				if segments == nil then
					continue
				end
				callback(AIFieldCourseTurn.new(self.turnData, self:inverse(segments)))
			end
		end
	end
end
function ReedsSheppPath:inverseSteering(segments)
	for _, segment in ipairs(segments) do
		segment:inverseSteering()
	end
	return segments
end
function ReedsSheppPath:inverseDirection(segments)
	for _, segment in ipairs(segments) do
		segment:inverseDirection()
	end
	return segments
end
function ReedsSheppPath:inverse(segments)
	for _, segment in ipairs(segments) do
		segment:inverseSteering()
		segment:inverseDirection()
	end
	return segments
end
local getPolarCoordinates = function(dx, dz)
	local length = MathUtil.vector2Length(dx, dz)
	local yRot = MathUtil.getYRotationFromDirection(dz, dx)
	return length, yRot
end
local normalizeRotation = function(r)
	r = r % 6.283185307179586
	if r < -3.141592653589793 then
		r = r + 6.283185307179586
		return r
	else
		if 3.141592653589793 < r then
			r = r - 6.283185307179586
		end
		return r
	end
end
ReedsSheppPath.PATH_FUNCTIONS = {}
ReedsSheppPath.PATH_FUNCTIONS[1] = function(x, z, phi)
	local segments = {}
	local dx = x - math.sin(phi)
	local dz = z - 1 + math.cos(phi)
	local length = MathUtil.vector2Length(dx, dz)
	local yRot = MathUtil.getYRotationFromDirection(dz, dx)
	local u = length
	local t = yRot
	local r = phi - t
	r = r % 6.283185307179586
	if r < -3.141592653589793 then
		r = r + 6.283185307179586
	elseif 3.141592653589793 < r then
		r = r - 6.283185307179586
	end
	local v = r
	table.insert(segments, AIFieldCourseTurnSegment.new(t, AIFieldCourseTurnSegmentType.LEFT, 1))
	table.insert(segments, AIFieldCourseTurnSegment.new(u, AIFieldCourseTurnSegmentType.STRAIGHT, 1))
	table.insert(segments, AIFieldCourseTurnSegment.new(v, AIFieldCourseTurnSegmentType.LEFT, 1))
	return segments
end
ReedsSheppPath.PATH_FUNCTIONS[2] = function(x, z, phi)
	local r = phi
	r = r % 6.283185307179586
	if r < -3.141592653589793 then
		r = r + 6.283185307179586
	elseif 3.141592653589793 < r then
		r = r - 6.283185307179586
	end
	phi = r
	local dx = x + math.sin(phi)
	local dz = z - 1 - math.cos(phi)
	local length = MathUtil.vector2Length(dx, dz)
	local yRot = MathUtil.getYRotationFromDirection(dz, dx)
	local u1 = length
	local t1 = yRot
	u1 = u1 * u1
	if 4 <= u1 then
		local u = math.sqrt(u1 - 4)
		local theta = math.atan2(2, u)
		local r = t1 + theta
		r = r % 6.283185307179586
		if r < -3.141592653589793 then
			r = r + 6.283185307179586
		elseif 3.141592653589793 < r then
			r = r - 6.283185307179586
		end
		local t = r
		local r = t - phi
		r = r % 6.283185307179586
		if r < -3.141592653589793 then
			r = r + 6.283185307179586
		elseif 3.141592653589793 < r then
			r = r - 6.283185307179586
		end
		local v = r
		local segments = {}
		table.insert(segments, AIFieldCourseTurnSegment.new(t, AIFieldCourseTurnSegmentType.LEFT, 1))
		table.insert(segments, AIFieldCourseTurnSegment.new(u, AIFieldCourseTurnSegmentType.STRAIGHT, 1))
		table.insert(segments, AIFieldCourseTurnSegment.new(v, AIFieldCourseTurnSegmentType.RIGHT, 1))
		return segments
	else
		return nil
	end
end
ReedsSheppPath.PATH_FUNCTIONS[3] = function(x, y, phi)
	local dx = x - math.sin(phi)
	local dz = y - 1 + math.cos(phi)
	local length = MathUtil.vector2Length(dx, dz)
	local yRot = MathUtil.getYRotationFromDirection(dz, dx)
	local u1 = length
	local t1 = yRot
	if u1 <= 4 then
		local a = math.acos(u1 / 4)
		local r = t1 + 1.5707963267948966 + a
		r = r % 6.283185307179586
		if r < -3.141592653589793 then
			r = r + 6.283185307179586
		elseif 3.141592653589793 < r then
			r = r - 6.283185307179586
		end
		local t = r
		local r = 3.141592653589793 - 2 * a
		r = r % 6.283185307179586
		if r < -3.141592653589793 then
			r = r + 6.283185307179586
		elseif 3.141592653589793 < r then
			r = r - 6.283185307179586
		end
		local u = r
		local r = phi - t - u
		r = r % 6.283185307179586
		if r < -3.141592653589793 then
			r = r + 6.283185307179586
		elseif 3.141592653589793 < r then
			r = r - 6.283185307179586
		end
		local v = r
		local segments = {}
		table.insert(segments, AIFieldCourseTurnSegment.new(t, AIFieldCourseTurnSegmentType.LEFT, 1))
		table.insert(segments, AIFieldCourseTurnSegment.new(u, AIFieldCourseTurnSegmentType.RIGHT, -1))
		table.insert(segments, AIFieldCourseTurnSegment.new(v, AIFieldCourseTurnSegmentType.LEFT, 1))
		return segments
	else
		return nil
	end
end
ReedsSheppPath.PATH_FUNCTIONS[4] = function(x, y, phi)
	local dx = x - math.sin(phi)
	local dz = y - 1 + math.cos(phi)
	local length = MathUtil.vector2Length(dx, dz)
	local yRot = MathUtil.getYRotationFromDirection(dz, dx)
	local u1 = length
	local t1 = yRot
	if u1 <= 4 then
		local a = math.acos(u1 / 4)
		local r = t1 + 1.5707963267948966 + a
		r = r % 6.283185307179586
		if r < -3.141592653589793 then
			r = r + 6.283185307179586
		elseif 3.141592653589793 < r then
			r = r - 6.283185307179586
		end
		local t = r
		local r = 3.141592653589793 - 2 * a
		r = r % 6.283185307179586
		if r < -3.141592653589793 then
			r = r + 6.283185307179586
		elseif 3.141592653589793 < r then
			r = r - 6.283185307179586
		end
		local u = r
		local r = t + u - phi
		r = r % 6.283185307179586
		if r < -3.141592653589793 then
			r = r + 6.283185307179586
		elseif 3.141592653589793 < r then
			r = r - 6.283185307179586
		end
		local v = r
		local segments = {}
		table.insert(segments, AIFieldCourseTurnSegment.new(t, AIFieldCourseTurnSegmentType.LEFT, 1))
		table.insert(segments, AIFieldCourseTurnSegment.new(u, AIFieldCourseTurnSegmentType.RIGHT, -1))
		table.insert(segments, AIFieldCourseTurnSegment.new(v, AIFieldCourseTurnSegmentType.LEFT, -1))
		return segments
	else
		return nil
	end
end
ReedsSheppPath.PATH_FUNCTIONS[5] = function(x, y, phi)
	local dx = x - math.sin(phi)
	local dz = y - 1 + math.cos(phi)
	local length = MathUtil.vector2Length(dx, dz)
	local yRot = MathUtil.getYRotationFromDirection(dz, dx)
	local u1 = length
	local t1 = yRot
	if 0 < u1 and u1 <= 4 then
		local u = math.acos(1 - u1 * u1 / 8)
		local a = math.asin(math.clamp(2 * math.sin(u) / u1, -1, 1))
		local r = t1 + 1.5707963267948966 - a
		r = r % 6.283185307179586
		if r < -3.141592653589793 then
			r = r + 6.283185307179586
		elseif 3.141592653589793 < r then
			r = r - 6.283185307179586
		end
		local t = r
		local r = t - u - phi
		r = r % 6.283185307179586
		if r < -3.141592653589793 then
			r = r + 6.283185307179586
		elseif 3.141592653589793 < r then
			r = r - 6.283185307179586
		end
		local v = r
		local segments = {}
		table.insert(segments, AIFieldCourseTurnSegment.new(t, AIFieldCourseTurnSegmentType.LEFT, 1))
		table.insert(segments, AIFieldCourseTurnSegment.new(u, AIFieldCourseTurnSegmentType.RIGHT, 1))
		table.insert(segments, AIFieldCourseTurnSegment.new(v, AIFieldCourseTurnSegmentType.LEFT, -1))
		return segments
	end
	return nil
end
ReedsSheppPath.PATH_FUNCTIONS[6] = function(x, y, phi)
	local dx = x + math.sin(phi)
	local dz = y - 1 - math.cos(phi)
	local length = MathUtil.vector2Length(dx, dz)
	local yRot = MathUtil.getYRotationFromDirection(dz, dx)
	local u1 = length
	local t1 = yRot
	if u1 <= 4 then
		local t = nil
		local u = nil
		local v = nil
		if u1 <= 2 then
			local a = math.acos((u1 + 2) / 4)
			local r = t1 + 1.5707963267948966 + a
			r = r % 6.283185307179586
			if r < -3.141592653589793 then
				r = r + 6.283185307179586
			elseif 3.141592653589793 < r then
				r = r - 6.283185307179586
			end
			t = r
			local r = a
			r = r % 6.283185307179586
			if r < -3.141592653589793 then
				r = r + 6.283185307179586
			elseif 3.141592653589793 < r then
				r = r - 6.283185307179586
			end
			u = r
			local r = phi - t + 2 * u
			r = r % 6.283185307179586
			if r < -3.141592653589793 then
				r = r + 6.283185307179586
			elseif 3.141592653589793 < r then
				r = r - 6.283185307179586
			end
			v = r
		else
			local a = math.acos((u1 - 2) / 4)
			local r = t1 + 1.5707963267948966 - a
			r = r % 6.283185307179586
			if r < -3.141592653589793 then
				r = r + 6.283185307179586
			elseif 3.141592653589793 < r then
				r = r - 6.283185307179586
			end
			t = r
			local r = 3.141592653589793 - a
			r = r % 6.283185307179586
			if r < -3.141592653589793 then
				r = r + 6.283185307179586
			elseif 3.141592653589793 < r then
				r = r - 6.283185307179586
			end
			u = r
			local r = phi - t + 2 * u
			r = r % 6.283185307179586
			if r < -3.141592653589793 then
				r = r + 6.283185307179586
			elseif 3.141592653589793 < r then
				r = r - 6.283185307179586
			end
			v = r
		end
		local segments = {}
		table.insert(segments, AIFieldCourseTurnSegment.new(t, AIFieldCourseTurnSegmentType.LEFT, 1))
		table.insert(segments, AIFieldCourseTurnSegment.new(u, AIFieldCourseTurnSegmentType.RIGHT, 1))
		table.insert(segments, AIFieldCourseTurnSegment.new(u, AIFieldCourseTurnSegmentType.LEFT, -1))
		table.insert(segments, AIFieldCourseTurnSegment.new(v, AIFieldCourseTurnSegmentType.RIGHT, -1))
		return segments
	else
		return nil
	end
end
ReedsSheppPath.PATH_FUNCTIONS[7] = function(x, y, phi)
	local dx = x + math.sin(phi)
	local dz = y - 1 - math.cos(phi)
	local length = MathUtil.vector2Length(dx, dz)
	local yRot = MathUtil.getYRotationFromDirection(dz, dx)
	local u1 = length
	local t1 = yRot
	local u2 = (20 - u1 * u1) / 16
	if 0 < u1 and (u1 <= 6 and (0 <= u2 and u2 <= 1)) then
		local u = math.acos(u2)
		local a = math.asin(math.clamp(2 * math.sin(u) / u1, -1, 1))
		local r = t1 + 1.5707963267948966 + a
		r = r % 6.283185307179586
		if r < -3.141592653589793 then
			r = r + 6.283185307179586
		elseif 3.141592653589793 < r then
			r = r - 6.283185307179586
		end
		local t = r
		local r = t - phi
		r = r % 6.283185307179586
		if r < -3.141592653589793 then
			r = r + 6.283185307179586
		elseif 3.141592653589793 < r then
			r = r - 6.283185307179586
		end
		local v = r
		local segments = {}
		table.insert(segments, AIFieldCourseTurnSegment.new(t, AIFieldCourseTurnSegmentType.LEFT, 1))
		table.insert(segments, AIFieldCourseTurnSegment.new(u, AIFieldCourseTurnSegmentType.RIGHT, -1))
		table.insert(segments, AIFieldCourseTurnSegment.new(u, AIFieldCourseTurnSegmentType.LEFT, -1))
		table.insert(segments, AIFieldCourseTurnSegment.new(v, AIFieldCourseTurnSegmentType.RIGHT, 1))
		return segments
	end
	return nil
end
ReedsSheppPath.FORWARD_FUNCTIONS = {}
table.insert(ReedsSheppPath.FORWARD_FUNCTIONS, ReedsSheppPath.PATH_FUNCTIONS[1])
table.insert(ReedsSheppPath.FORWARD_FUNCTIONS, ReedsSheppPath.PATH_FUNCTIONS[2])
