-- Local values: PlayerPositionalInterpolator_mt
PlayerPositionalInterpolator = {}
local PlayerPositionalInterpolator_mt = Class(PlayerPositionalInterpolator)
PlayerPositionalInterpolator.INTERPOLATION_TARGET_ENUM = {
	["ROOT_NODE"] = 1,
	["GRAPHICAL_NODE"] = 2
}

-- Upvalues: PlayerPositionalInterpolator_mt
-- Local values: self, playerPositionX, playerPositionY, playerPositionZ, playerYaw, playerSpeed, playerVerticalVelocity
function PlayerPositionalInterpolator.new(player, targetNodeType)
	-- upvalues: (copy) PlayerPositionalInterpolator_mt
	local v4_ = PlayerPositionalInterpolator_mt
	local v5_ = setmetatable({}, v4_)
	v5_.player = player
	v5_.targetNodeType = targetNodeType
	v5_.timeInterpolator = InterpolationTime.new(1.2)
	local v6_, v7_, v8_ = v5_.player:getPosition()
	v5_.positionInterpolator = InterpolatorPosition.new(v6_, v7_, v8_)
	v5_.interpolatedPositionX = v6_
	v5_.interpolatedPositionY = v7_
	v5_.interpolatedPositionZ = v8_
	v5_.interpolatedSpeed = 0
	v5_.interpolatedVelocityX = 0
	v5_.interpolatedVelocityY = 0
	v5_.interpolatedVelocityZ = 0
	local v9_ = v5_.player:getYaw()
	v5_.yawInterpolator = InterpolatorAngle.new(v9_)
	local v10_ = v5_.player:getSpeed()
	v5_.speedInterpolator = InterpolatorValue.new(v10_)
	local v11_ = v5_.player.mover.currentVelocityY
	v5_.verticalVelocityInterpolator = InterpolatorValue.new(v11_)
	v5_.directionX = 0
	v5_.directionZ = 0
	v5_.targetPhysicsIndex = -1
	v5_.player.mover.onPositionTeleport:registerListener(PlayerPositionalInterpolator.onPlayerPositionTeleport, v5_)
	return v5_
end

-- Local values: deltaTime, alpha, interpolatedPositionX, interpolatedPositionY, interpolatedPositionZ, interpolatedYaw, dirX, dirZ, distance, speedXZ, speedY
function PlayerPositionalInterpolator:update(dt)
	local v13_ = g_physicsDtUnclamped
	self.timeInterpolator:update(v13_)
	local v14_ = self.timeInterpolator:getAlpha()
	local v15_, v16_, v17_ = self.positionInterpolator:getInterpolatedValues(v14_)
	local v18_ = self.yawInterpolator:getInterpolatedValue(v14_)
	local v19_ = v15_ - self.interpolatedPositionX
	local v20_ = v17_ - self.interpolatedPositionZ
	local v21_ = MathUtil.vector2Length(v19_, v20_)
	local _ = self.player.isOwner
	local v22_, v23_
	if v21_ > 0 then
		v19_, v20_ = MathUtil.vector2Normalize(v19_, v20_)
		v22_ = v21_ / v13_
		v23_ = (v16_ - self.interpolatedPositionY) / v13_
	else
		v23_ = 0
		v22_ = 0
	end
	self.interpolatedPositionX = v15_
	self.interpolatedPositionY = v16_
	self.interpolatedPositionZ = v17_
	self.interpolatedYaw = v18_
	self.interpolatedSpeed = v22_ * 1000
	self.interpolatedVelocityX = v19_ * v22_
	self.interpolatedVelocityZ = v20_ * v22_
	self.interpolatedVelocityY = v23_
	if self.targetNodeType == PlayerPositionalInterpolator.INTERPOLATION_TARGET_ENUM.ROOT_NODE then
		self.player.mover:setPosition(v15_, v16_, v17_)
		self.player.mover:setMovementYaw(v18_)
		self.player.mover:setSpeed(v22_)
		self.player.mover:setVelocity(self.interpolatedVelocityX, self.interpolatedVelocityZ, self.interpolatedVelocityZ)
	end
end

-- Local values: interpolator, x, y, z, targetPositionX, targetPositionY, targetPositionZ, distanceX, distanceY, distanceZ, isVeryClose, playerYaw, targetYaw
function PlayerPositionalInterpolator:updateTick(dt)
	if self.targetNodeType == PlayerPositionalInterpolator.INTERPOLATION_TARGET_ENUM.GRAPHICAL_NODE then
		local v25_ = self.positionInterpolator
		if self.targetPhysicsIndex >= 0 then
			local v26_, v27_, v28_ = self.player.mover:getPosition()
			local v29_, v30_, v31_
			if self.player.isOwner or not getIsPhysicsUpdateIndexSimulated(self.targetPhysicsIndex) then
				v29_ = v25_.targetPositionX
				v30_ = v25_.targetPositionY
				v31_ = v25_.targetPositionZ
				local v32_ = v26_ - v29_
				local v33_ = math.abs(v32_)
				local v34_ = v27_ - v30_
				local v35_ = math.abs(v34_)
				local v36_ = v28_ - v31_
				local v37_ = math.abs(v36_)
				local v38_
				if v33_ < 0.001 and v35_ < 0.001 then
					v38_ = v37_ < 0.001
				else
					v38_ = false
				end
				if not v38_ then
					v31_ = v28_
					v30_ = v27_
					v29_ = v26_
				end
			else
				self.targetPhysicsIndex = -1
				v31_ = v28_
				v30_ = v27_
				v29_ = v26_
			end
			self:setTargetPosition(v29_, v30_, v31_)
			self.timeInterpolator:startNewPhase(75)
			local v39_ = self.player:getYaw()
			local v40_ = self.yawInterpolator.targetValue
			local v41_ = v39_ - v40_
			if math.abs(v41_) < 0.005 then
				v39_ = v40_ or v39_
			end
			self:setTargetYaw(v39_)
		end
	end
end

function PlayerPositionalInterpolator:startNetworkNewPhase()
	self.timeInterpolator:startNewPhaseNetwork()
end

function PlayerPositionalInterpolator:setTargetPosition(targetPositionX, targetPositionY, targetPositionZ)
	local _ = self.player.isOwner
	self.positionInterpolator:setTargetPosition(targetPositionX, targetPositionY, targetPositionZ)
end

function PlayerPositionalInterpolator:setPosition(x, y, z)
	self.positionInterpolator:setPosition(x, y, z)
	self.timeInterpolator:reset()
	self.targetPhysicsIndex = -1
end

function PlayerPositionalInterpolator:onPlayerPositionTeleport(x, y, z)
	self.positionInterpolator:setPosition(x, y, z)
end

function PlayerPositionalInterpolator:setTargetPhysicsIndex(targetPhysicsIndex)
	self.targetPhysicsIndex = targetPhysicsIndex
end

function PlayerPositionalInterpolator:getInterpolatedPosition()
	return self.interpolatedPositionX, self.interpolatedPositionY, self.interpolatedPositionZ
end

function PlayerPositionalInterpolator:setTargetYaw(targetYaw)
	local v60_ = MathUtil.getValidLimit(targetYaw)
	self.yawInterpolator:setTargetAngle(v60_)
end

function PlayerPositionalInterpolator:getInterpolatedYaw()
	return self.interpolatedYaw
end

function PlayerPositionalInterpolator:getInterpolatedSpeed()
	return self.interpolatedSpeed
end

function PlayerPositionalInterpolator:getInterpolatedVelocity()
	return self.interpolatedVelocityX, self.interpolatedVelocityY, self.interpolatedVelocityZ
end
