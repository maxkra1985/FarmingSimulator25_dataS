-- Local values: PlayerStateFall_mt
PlayerStateFall = {}
local PlayerStateFall_mt = Class(PlayerStateFall, BaseStateMachineState)
PlayerStateFall.MAXIMUM_ROTATION_SPEED = 45
PlayerStateFall.MAXIMUM_MOVE_SPEED = 3
PlayerStateFall.GROUND_LANDING_DISTANCE = 2
PlayerStateFall.FALL_TIME_THRESHOLD = 1.2

-- Upvalues: PlayerStateFall_mt
-- Local values: self
function PlayerStateFall.new(player, stateMachine)
	-- upvalues: (copy) PlayerStateFall_mt
	local v4_ = BaseStateMachineState.new(stateMachine, PlayerStateFall_mt)
	v4_.player = player
	return v4_
end

function PlayerStateFall:calculateIfShouldBeForced()
	local v6_ = self:calculateIfFalling()
	if v6_ then
		v6_ = self.stateMachine.currentState ~= self.stateMachine.states.jumping
	end
	return v6_
end

function PlayerStateFall:calculateIfFalling()
	local v8_ = not self.stateMachine.states.swimming:calculateIfSubmerged()
	if v8_ then
		v8_ = self.player.mover.currentFallTime >= PlayerStateFall.FALL_TIME_THRESHOLD
	end
	return v8_
end

function PlayerStateFall:calculateIfLanding()
	return self.player.mover.currentGroundDistance <= PlayerStateFall.GROUND_LANDING_DISTANCE
end

function PlayerStateFall:updateAsCurrent(dt)
	if not self:calculateIfShouldBeForced() then
		self.stateMachine:determineState()
	end
end

function PlayerStateFall:calculateMaximumSpeed()
	return PlayerStateFall.MAXIMUM_MOVE_SPEED
end

-- Local values: maximumMoveSpeed
function PlayerStateFall:calculateDesiredHorizontalVelocity(directionX, directionZ)
	local v14_ = self.player.toggleSuperSpeedCommand.value and PlayerStateFall.MAXIMUM_MOVE_SPEED * 8 or PlayerStateFall.MAXIMUM_MOVE_SPEED
	return directionX * v14_, directionZ * v14_
end
