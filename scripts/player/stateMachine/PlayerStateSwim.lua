-- Local values: PlayerStateSwim_mt
PlayerStateSwim = {}
local PlayerStateSwim_mt = Class(PlayerStateSwim, BaseStateMachineState)
PlayerStateSwim.MAXIMUM_ROTATION_SPEED = 180
PlayerStateSwim.MAXIMUM_MOVE_SPEED = 3
PlayerStateSwim.MAXIMUM_SPRINT_SPEED = 5
PlayerStateSwim.SWIM_SUBMERGE_THRESHOLD = 1.4
PlayerStateSwim.SLOW_SUBMERGE_THRESHOLD = 0.4

-- Upvalues: PlayerStateSwim_mt
-- Local values: self
function PlayerStateSwim.new(player, stateMachine)
	-- upvalues: (copy) PlayerStateSwim_mt
	local v4_ = BaseStateMachineState.new(stateMachine, PlayerStateSwim_mt)
	v4_.player = player
	return v4_
end

function PlayerStateSwim:calculateIfShouldBeForced()
	return self:calculateIfSubmerged()
end

function PlayerStateSwim:calculateIfSubmerged()
	if self.player.toggleNoClipCommand == nil or not self.player.toggleNoClipCommand.value then
		return self.player.mover.isSwimming
	else
		return false
	end
end

function PlayerStateSwim:calculateIfMoving()
	local v8_ = self:calculateIfSubmerged()
	if v8_ then
		v8_ = self.player.inputComponent.hasMovementInputs
	end
	return v8_
end

function PlayerStateSwim:calculateIfSwimmingNormally()
	local v10_ = self:calculateIfMoving()
	if v10_ then
		v10_ = self.player.inputComponent.runAxis == 0
	end
	return v10_
end

function PlayerStateSwim:calculateIfSprinting()
	local v12_ = self:calculateIfMoving()
	if v12_ then
		v12_ = self.player.inputComponent.runAxis > 0
	end
	return v12_
end

function PlayerStateSwim:onStateEntered(previousState)
	if self.player.isOwner and self.player:getIsHoldingHandTool() then
		self.player:setCurrentHandTool(nil)
	end
end

function PlayerStateSwim:updateAsCurrent(dt)
	if not self:calculateIfShouldBeForced() then
		self.stateMachine:determineState()
	end
end

function PlayerStateSwim:calculateMaximumSpeed()
	if self:calculateIfSprinting() then
		return PlayerStateSwim.MAXIMUM_SPRINT_SPEED
	else
		return PlayerStateSwim.MAXIMUM_MOVE_SPEED
	end
end

-- Local values: moveScalar
function PlayerStateSwim:calculateDesiredSpeed(directionX, directionZ)
	if not self:calculateIfSprinting() then
		return self.player.mover:calculateSmoothSpeed(self.player.inputComponent.walkAxis, false, 0, PlayerStateSwim.MAXIMUM_MOVE_SPEED)
	end
	local v17_ = self.player.inputComponent.runAxis * self.player.inputComponent.walkAxis
	return self.player.mover:calculateSmoothSpeed(v17_, false, PlayerStateSwim.MAXIMUM_MOVE_SPEED, PlayerStateSwim.MAXIMUM_SPRINT_SPEED)
end

-- Local values: speed
function PlayerStateSwim:calculateDesiredHorizontalVelocity(directionX, directionZ)
	local v21_ = self:calculateDesiredSpeed()
	return directionX * v21_, directionZ * v21_
end
