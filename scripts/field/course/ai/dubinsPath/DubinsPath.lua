DubinsPath = {}
local DubinsPath_mt = Class(DubinsPath)
function DubinsPath.new(turnData, forcedDirection)
	local self = setmetatable({}, DubinsPath_mt)
	self.turnData = turnData
	self.forcedDirection = forcedDirection or 0
	local sAngle = MathUtil.getYRotationFromDirection(turnData.sDirX, turnData.sDirZ)
	sAngle = (sAngle - 1.5707963267948966) % 6.283185307179586
	local eAngle = MathUtil.getYRotationFromDirection(turnData.eDirX, turnData.eDirZ)
	eAngle = (eAngle - 1.5707963267948966) % 6.283185307179586
	local dx = turnData.ex - turnData.sx
	local dz = turnData.ez - turnData.sz
	local length = MathUtil.vector2Length(dx, dz)
	self.distance = length / turnData.turnRadius
	local theta = (MathUtil.getYRotationFromDirection(dx, dz) - 1.5707963267948966) % 6.283185307179586
	self.alpha = (sAngle - theta) % 6.283185307179586
	self.beta = (eAngle - theta) % 6.283185307179586
	if math.abs(3.141592653589793 - theta) < 0.001 and 0 < self.distance then
		dx = dx / length
		dz = dz / length
		if math.abs(dx - turnData.sDirX) < 0.001 and (math.abs(dz - turnData.sDirZ) < 0.001 and (math.abs(dx - turnData.eDirX) < 0.001 and math.abs(dz - turnData.eDirZ) < 0.001)) then
			self.straightSegmentOnly = true
		end
	end
	return self
end
function DubinsPath:generate(callback)
	if self.forcedDirection < 0 then
		return
	else
		if self.straightSegmentOnly then
			local segments = {}
			table.insert(segments, AIFieldCourseTurnSegment.new(self.distance, AIFieldCourseTurnSegmentType.STRAIGHT, 1))
			callback(AIFieldCourseTurn.new(self.turnData, segments))
		end
		for _, func in ipairs(DubinsPath.PATH_FUNCTIONS) do
			local segments = func(self.alpha, self.beta, self.distance)
			if segments == nil then
				continue
			end
			if 0 < #segments then
				callback(AIFieldCourseTurn.new(self.turnData, segments))
			end
		end
	end
end
DubinsPath.PATH_FUNCTIONS = {}
DubinsPath.PATH_FUNCTIONS[1] = function(alpha, beta, d)
	local lrl = (6 - d * d + 2 * math.cos(alpha - beta) + 2 * d * (-math.sin(alpha) + math.sin(beta))) / 8
	if 1 < math.abs(lrl) then
		return nil
	else
		local segments = {}
		local p = (6.283185307179586 - math.acos(lrl)) % 6.283185307179586
		local t = (-alpha - math.atan2(math.cos(alpha) - math.cos(beta), d + math.sin(alpha) - math.sin(beta)) + p / 2) % 6.283185307179586
		local q = (beta % 6.283185307179586 - alpha - t + p % 6.283185307179586) % 6.283185307179586
		table.insert(segments, AIFieldCourseTurnSegment.new(t, AIFieldCourseTurnSegmentType.LEFT, 1))
		table.insert(segments, AIFieldCourseTurnSegment.new(p, AIFieldCourseTurnSegmentType.RIGHT, 1))
		table.insert(segments, AIFieldCourseTurnSegment.new(q, AIFieldCourseTurnSegmentType.LEFT, 1))
		return segments
	end
end
DubinsPath.PATH_FUNCTIONS[2] = function(alpha, beta, d)
	local lsl = math.atan2(math.cos(beta) - math.cos(alpha), d + math.sin(alpha) - math.sin(beta))
	local pSq = 2 + d * d - 2 * math.cos(alpha - beta) + 2 * d * (math.sin(alpha) - math.sin(beta))
	if pSq < 0 then
		return nil
	else
		local segments = {}
		local t = (lsl - alpha) % 6.283185307179586
		local p = math.sqrt(pSq)
		local q = (beta - lsl) % 6.283185307179586
		table.insert(segments, AIFieldCourseTurnSegment.new(t, AIFieldCourseTurnSegmentType.LEFT, 1))
		table.insert(segments, AIFieldCourseTurnSegment.new(p, AIFieldCourseTurnSegmentType.STRAIGHT, 1))
		table.insert(segments, AIFieldCourseTurnSegment.new(q, AIFieldCourseTurnSegmentType.LEFT, 1))
		return segments
	end
end
DubinsPath.PATH_FUNCTIONS[3] = function(alpha, beta, d)
	local lsr = d + math.sin(alpha) + math.sin(beta)
	local pSq = -2 + d * d + 2 * math.cos(alpha - beta) + 2 * d * (math.sin(alpha) + math.sin(beta))
	if pSq < 0 then
		return nil
	else
		local segments = {}
		local p = math.sqrt(pSq)
		local lsr2 = math.atan2(-math.cos(alpha) - math.cos(beta), lsr) - math.atan2(-2, p)
		local t = (lsr2 - alpha) % 6.283185307179586
		local q = (lsr2 - beta) % 6.283185307179586
		table.insert(segments, AIFieldCourseTurnSegment.new(t, AIFieldCourseTurnSegmentType.LEFT, 1))
		table.insert(segments, AIFieldCourseTurnSegment.new(p, AIFieldCourseTurnSegmentType.STRAIGHT, 1))
		table.insert(segments, AIFieldCourseTurnSegment.new(q, AIFieldCourseTurnSegmentType.RIGHT, 1))
		return segments
	end
end
DubinsPath.PATH_FUNCTIONS[4] = function(alpha, beta, d)
	local rlr = (6 - d * d + 2 * math.cos(alpha - beta) + 2 * d * (math.sin(alpha) - math.sin(beta))) / 8
	if 1 < math.abs(rlr) then
		return nil
	else
		local segments = {}
		local p = (6.283185307179586 - math.acos(rlr)) % 6.283185307179586
		local t = (alpha - math.atan2(math.cos(alpha) - math.cos(beta), d - math.sin(alpha) + math.sin(beta)) + p / 2 % 6.283185307179586) % 6.283185307179586
		local q = (alpha - beta - t + p % 6.283185307179586) % 6.283185307179586
		table.insert(segments, AIFieldCourseTurnSegment.new(t, AIFieldCourseTurnSegmentType.RIGHT, 1))
		table.insert(segments, AIFieldCourseTurnSegment.new(p, AIFieldCourseTurnSegmentType.LEFT, 1))
		table.insert(segments, AIFieldCourseTurnSegment.new(q, AIFieldCourseTurnSegmentType.RIGHT, 1))
		return segments
	end
end
DubinsPath.PATH_FUNCTIONS[5] = function(alpha, beta, d)
	local rsl = d - math.sin(alpha) - math.sin(beta)
	local pSq = -2 + d * d + 2 * math.cos(alpha - beta) - 2 * d * (math.sin(alpha) + math.sin(beta))
	if pSq < 0 then
		return nil
	else
		local segments = {}
		local p = math.sqrt(pSq)
		local rsl2 = math.atan2(math.cos(alpha) + math.cos(beta), rsl) - math.atan2(2, p)
		local t = (alpha - rsl2) % 6.283185307179586
		local q = (beta - rsl2) % 6.283185307179586
		table.insert(segments, AIFieldCourseTurnSegment.new(t, AIFieldCourseTurnSegmentType.RIGHT, 1))
		table.insert(segments, AIFieldCourseTurnSegment.new(p, AIFieldCourseTurnSegmentType.STRAIGHT, 1))
		table.insert(segments, AIFieldCourseTurnSegment.new(q, AIFieldCourseTurnSegmentType.LEFT, 1))
		return segments
	end
end
DubinsPath.PATH_FUNCTIONS[6] = function(alpha, beta, d)
	local rsr1 = d - math.sin(alpha) + math.sin(beta)
	local rsr2 = math.atan2(math.cos(alpha) - math.cos(beta), rsr1)
	local pSq = 2 + d * d - 2 * math.cos(alpha - beta) + 2 * d * (math.sin(beta) - math.sin(alpha))
	if pSq < 0 then
		return nil
	else
		local segments = {}
		local t = (alpha - rsr2) % 6.283185307179586
		local p = math.sqrt(pSq)
		local q = (-beta + rsr2) % 6.283185307179586
		table.insert(segments, AIFieldCourseTurnSegment.new(t, AIFieldCourseTurnSegmentType.RIGHT, 1))
		table.insert(segments, AIFieldCourseTurnSegment.new(p, AIFieldCourseTurnSegmentType.STRAIGHT, 1))
		table.insert(segments, AIFieldCourseTurnSegment.new(q, AIFieldCourseTurnSegmentType.RIGHT, 1))
		return segments
	end
end
