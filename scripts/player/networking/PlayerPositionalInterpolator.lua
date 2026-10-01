PlayerPositionalInterpolator = {}
local PlayerPositionalInterpolator_mt = Class(PlayerPositionalInterpolator)
PlayerPositionalInterpolator.INTERPOLATION_TARGET_ENUM = { ROOT_NODE = 1, GRAPHICAL_NODE = 2 }
function PlayerPositionalInterpolator.new(player, targetNodeType)
	local self = setmetatable({}, PlayerPositionalInterpolator_mt)
	self.player = player
	self.targetNodeType = targetNodeType
	self.timeInterpolator = InterpolationTime.new(1.2)
	local playerPositionX, playerPositionY, playerPositionZ = self.player:getPosition()
	self.positionInterpolator = InterpolatorPosition.new(playerPositionX, playerPositionY, playerPositionZ)
	self.interpolatedPositionX = playerPositionX
	self.interpolatedPositionY = playerPositionY
	self.interpolatedPositionZ = playerPositionZ
	self.interpolatedSpeed = 0
	self.interpolatedVelocityX = 0
	self.interpolatedVelocityY = 0
	self.interpolatedVelocityZ = 0
	local playerYaw = self.player:getYaw()
	self.yawInterpolator = InterpolatorAngle.new(playerYaw)
	local playerSpeed = self.player:getSpeed()
	self.speedInterpolator = InterpolatorValue.new(playerSpeed)
	local playerVerticalVelocity = self.player.mover.currentVelocityY
	self.verticalVelocityInterpolator = InterpolatorValue.new(playerVerticalVelocity)
	self.directionX = 0
	self.directionZ = 0
	self.targetPhysicsIndex = -1
	self.player.mover.onPositionTeleport:registerListener(PlayerPositionalInterpolator.onPlayerPositionTeleport, self)
	return self
end
function PlayerPositionalInterpolator:update(dt)
	local deltaTime = g_physicsDtUnclamped
	self.timeInterpolator:update(deltaTime)
	local alpha = self.timeInterpolator:getAlpha()
	local interpolatedPositionX, interpolatedPositionY, interpolatedPositionZ = self.positionInterpolator:getInterpolatedValues(alpha)
	local interpolatedYaw = self.yawInterpolator:getInterpolatedValue(alpha)
	local dirX = interpolatedPositionX - self.interpolatedPositionX
	local dirZ = interpolatedPositionZ - self.interpolatedPositionZ
	local distance = MathUtil.vector2Length(dirX, dirZ)
	local speedXZ = 0
	local speedY = 0
	if 0 < distance then
		dirX, dirZ = MathUtil.vector2Normalize(dirX, dirZ)
		speedXZ = distance / deltaTime
		speedY = (interpolatedPositionY - self.interpolatedPositionY) / deltaTime
	end
	self.interpolatedPositionX = interpolatedPositionX
	self.interpolatedPositionY = interpolatedPositionY
	self.interpolatedPositionZ = interpolatedPositionZ
	self.interpolatedYaw = interpolatedYaw
	self.interpolatedSpeed = speedXZ * 1000
	self.interpolatedVelocityX = dirX * speedXZ
	self.interpolatedVelocityZ = dirZ * speedXZ
	self.interpolatedVelocityY = speedY
	if self.targetNodeType == PlayerPositionalInterpolator.INTERPOLATION_TARGET_ENUM.ROOT_NODE then
		self.player.mover:setPosition(interpolatedPositionX, interpolatedPositionY, interpolatedPositionZ)
		self.player.mover:setMovementYaw(interpolatedYaw)
		self.player.mover:setSpeed(speedXZ)
		self.player.mover:setVelocity(self.interpolatedVelocityX, self.interpolatedVelocityZ, self.interpolatedVelocityZ)
	end
end
function PlayerPositionalInterpolator:updateTick(dt)
	if self.targetNodeType == PlayerPositionalInterpolator.INTERPOLATION_TARGET_ENUM.GRAPHICAL_NODE then
		local interpolator = self.positionInterpolator
		if 0 <= self.targetPhysicsIndex then
			local x, y, z = self.player.mover:getPosition()
			if not self.player.isOwner then
				if getIsPhysicsUpdateIndexSimulated(self.targetPhysicsIndex) then
					self.targetPhysicsIndex = -1
				else
					local targetPositionX = interpolator.targetPositionX
					local targetPositionY = interpolator.targetPositionY
					local targetPositionZ = interpolator.targetPositionZ
					local distanceX = math.abs(x - targetPositionX)
					local distanceY = math.abs(y - targetPositionY)
					local distanceZ = math.abs(z - targetPositionZ)
					local isVeryClose = distanceX < 0.001 and distanceY < 0.001 and distanceZ < 0.001
					if isVeryClose then
						x = targetPositionX
						y = targetPositionY
						z = targetPositionZ
					end
				end
			end
			self:setTargetPosition(x, y, z)
			self.timeInterpolator:startNewPhase(75)
			local playerYaw = self.player:getYaw()
			local targetYaw = self.yawInterpolator.targetValue
			self:setTargetYaw(math.abs(playerYaw - targetYaw) < 0.005 and targetYaw or playerYaw)
		end
	end
end
function PlayerPositionalInterpolator:startNetworkNewPhase()
	self.timeInterpolator:startNewPhaseNetwork()
end
function PlayerPositionalInterpolator:setTargetPosition(targetPositionX, targetPositionY, targetPositionZ)
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
	targetYaw = MathUtil.getValidLimit(targetYaw)
	self.yawInterpolator:setTargetAngle(targetYaw)
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
