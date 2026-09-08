-- Local values: InterpolatorQuaternion_mt
InterpolatorQuaternion = {}
local InterpolatorQuaternion_mt = Class(InterpolatorQuaternion)

-- Upvalues: InterpolatorQuaternion_mt
-- Local values: self
function InterpolatorQuaternion.new(qx, qy, qz, qw, customMt)
	-- upvalues: (copy) InterpolatorQuaternion_mt
	local v7_ = customMt or InterpolatorQuaternion_mt
	local v8_ = setmetatable({}, v7_)
	v8_.quaternionX = qx
	v8_.quaternionY = qy
	v8_.quaternionZ = qz
	v8_.quaternionW = qw
	v8_.lastQuaternionX = qx
	v8_.lastQuaternionY = qy
	v8_.lastQuaternionZ = qz
	v8_.lastQuaternionW = qw
	v8_.targetQuaternionX = qx
	v8_.targetQuaternionY = qy
	v8_.targetQuaternionZ = qz
	v8_.targetQuaternionW = qw
	return v8_
end

function InterpolatorQuaternion:setQuaternion(qx, qy, qz, qw)
	self.quaternionX = qx
	self.quaternionY = qy
	self.quaternionZ = qz
	self.quaternionW = qw
	self.lastQuaternionX = qx
	self.lastQuaternionY = qy
	self.lastQuaternionZ = qz
	self.lastQuaternionW = qw
	self.targetQuaternionX = qx
	self.targetQuaternionY = qy
	self.targetQuaternionZ = qz
	self.targetQuaternionW = qw
end

function InterpolatorQuaternion:setTargetQuaternion(qx, qy, qz, qw)
	self.targetQuaternionX = qx
	self.targetQuaternionY = qy
	self.targetQuaternionZ = qz
	self.targetQuaternionW = qw
	self.lastQuaternionX = self.quaternionX
	self.lastQuaternionY = self.quaternionY
	self.lastQuaternionZ = self.quaternionZ
	self.lastQuaternionW = self.quaternionW
end

function InterpolatorQuaternion:getInterpolatedValues(interpolationAlpha)
	local v21_, v22_, v23_, v24_ = MathUtil.nlerpQuaternionShortestPath(self.lastQuaternionX, self.lastQuaternionY, self.lastQuaternionZ, self.lastQuaternionW, self.targetQuaternionX, self.targetQuaternionY, self.targetQuaternionZ, self.targetQuaternionW, interpolationAlpha)
	self.quaternionX = v21_
	self.quaternionY = v22_
	self.quaternionZ = v23_
	self.quaternionW = v24_
	return self.quaternionX, self.quaternionY, self.quaternionZ, self.quaternionW
end
