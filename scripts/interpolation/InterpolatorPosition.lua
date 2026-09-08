-- Local values: InterpolatorPosition_mt
InterpolatorPosition = {}
local InterpolatorPosition_mt = Class(InterpolatorPosition)

-- Upvalues: InterpolatorPosition_mt
-- Local values: self
function InterpolatorPosition.new(positionX, positionY, positionZ, customMt)
	-- upvalues: (copy) InterpolatorPosition_mt
	local v6_ = customMt or InterpolatorPosition_mt
	local v7_ = setmetatable({}, v6_)
	v7_.positionX = positionX
	v7_.positionY = positionY
	v7_.positionZ = positionZ
	v7_.lastPositionX = positionX
	v7_.lastPositionY = positionY
	v7_.lastPositionZ = positionZ
	v7_.targetPositionX = positionX
	v7_.targetPositionY = positionY
	v7_.targetPositionZ = positionZ
	return v7_
end

function InterpolatorPosition:setPosition(x, y, z)
	self.positionX = x
	self.positionY = y
	self.positionZ = z
	self.lastPositionX = x
	self.lastPositionY = y
	self.lastPositionZ = z
	self.targetPositionX = x
	self.targetPositionY = y
	self.targetPositionZ = z
end

function InterpolatorPosition:setTargetPosition(x, y, z)
	self.targetPositionX = x
	self.targetPositionY = y
	self.targetPositionZ = z
	self.lastPositionX = self.positionX
	self.lastPositionY = self.positionY
	self.lastPositionZ = self.positionZ
end

function InterpolatorPosition:getInterpolatedValues(interpolationAlpha)
	self.positionX = self.lastPositionX + interpolationAlpha * (self.targetPositionX - self.lastPositionX)
	self.positionY = self.lastPositionY + interpolationAlpha * (self.targetPositionY - self.lastPositionY)
	self.positionZ = self.lastPositionZ + interpolationAlpha * (self.targetPositionZ - self.lastPositionZ)
	return self.positionX, self.positionY, self.positionZ
end
