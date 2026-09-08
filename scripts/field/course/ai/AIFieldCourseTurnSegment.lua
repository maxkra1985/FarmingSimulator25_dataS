-- Local values: AIFieldCourseTurnSegment_mt
AIFieldCourseTurnSegment = {}
local AIFieldCourseTurnSegment_mt = Class(AIFieldCourseTurnSegment)

-- Upvalues: AIFieldCourseTurnSegment_mt
-- Local values: self
function AIFieldCourseTurnSegment.new(distance, segmentType, drivingDirection)
	-- upvalues: (copy) AIFieldCourseTurnSegment_mt
	local v5_ = AIFieldCourseTurnSegment_mt
	local v6_ = setmetatable({}, v5_)
	v6_.distance = math.abs(distance)
	v6_.segmentType = segmentType
	v6_.drivingDirection = drivingDirection
	if distance < 0 then
		v6_:inverseDirection()
	end
	return v6_
end

function AIFieldCourseTurnSegment:inverseSteering()
	if self.segmentType == AIFieldCourseTurnSegmentType.LEFT then
		self.segmentType = AIFieldCourseTurnSegmentType.RIGHT
	elseif self.segmentType == AIFieldCourseTurnSegmentType.RIGHT then
		self.segmentType = AIFieldCourseTurnSegmentType.LEFT
	end
end

function AIFieldCourseTurnSegment:inverseDirection()
	self.drivingDirection = -self.drivingDirection
end

function AIFieldCourseTurnSegment:getLength()
	return self.distance
end

function AIFieldCourseTurnSegment:move(x, z, phi, delta, turnRadius)
	local v16_ = delta * self.drivingDirection
	if self.segmentType == AIFieldCourseTurnSegmentType.LEFT then
		local v17_ = phi - v16_
		local v18_ = x - math.sin(v17_) * turnRadius + math.sin(phi) * turnRadius
		local v19_ = phi - v16_
		return v18_, z + math.cos(v19_) * turnRadius - math.cos(phi) * turnRadius, phi - v16_
	elseif self.segmentType == AIFieldCourseTurnSegmentType.RIGHT then
		local v20_ = phi + v16_
		local v21_ = x + math.sin(v20_) * turnRadius - math.sin(phi) * turnRadius
		local v22_ = phi + v16_
		return v21_, z - math.cos(v22_) * turnRadius + math.cos(phi) * turnRadius, phi + v16_
	elseif self.segmentType == AIFieldCourseTurnSegmentType.STRAIGHT then
		return x + v16_ * math.cos(phi) * turnRadius, z + v16_ * math.sin(phi) * turnRadius, phi
	else
		return x, z, phi
	end
end
