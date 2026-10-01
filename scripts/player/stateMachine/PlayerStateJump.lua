PlayerStateJump = {}
local PlayerStateJump_mt = Class(PlayerStateJump, BaseStateMachineState)
PlayerStateJump.MINIMUM_GROUND_TIME_THRESHOLD = 0.7
PlayerStateJump.FALL_TIME_THRESHOLD = 1
PlayerStateJump.JUMP_TIME_THRESHOLD = 0.25
PlayerStateJump.JUMP_UPFORCE = 5.5
PlayerStateJump.GROUND_LANDING_DISTANCE = 1
PlayerStateJump.MAXIMUM_MOVE_SPEED = 3
function PlayerStateJump.new(player, stateMachine)
	local self = BaseStateMachineState.new(stateMachine, PlayerStateJump_mt)
	self.player = player
	self.timeSpentFallingDown = 0
	self.timeSpentJumping = 0
	return self
end
function PlayerStateJump:createTransitions()
	self:addTransition(self.calculateIfFalling, self.stateMachine.states.falling, self)
end
function PlayerStateJump:calculateIfFalling()
	return self.FALL_TIME_THRESHOLD <= self.timeSpentFallingDown
end
function PlayerStateJump:calculateIfJumping()
	if self.player.isOwner then
		return false
	else
		return false
	end
end
function PlayerStateJump:calculateIfTakingOff()
	return self.timeSpentJumping <= self.JUMP_TIME_THRESHOLD and 0 < self.player.mover.currentVelocityY
end
function PlayerStateJump:calculateIfLanding()
	local _v3 = false
	if self.player.mover.currentGroundDistance <= self.GROUND_LANDING_DISTANCE then
		_v3 = not self:calculateIfTakingOff()
	end
	return _v3
end
function PlayerStateJump:onStateEntered(previousState)
	self.player.mover.currentVelocityY = PlayerStateJump.JUMP_UPFORCE * self.player:getJumpMultiplier()
	self:resetTimers()
end
function PlayerStateJump:onStateExited(previousState)
	self.player.mover.currentUpForce = 0
	self:resetTimers()
end
function PlayerStateJump:resetTimers()
	self.timeSpentFallingDown = 0
	self.timeSpentJumping = 0
end
function PlayerStateJump:updateAsCurrent(dt)
	if self.player.mover.currentVelocityY < 0 then
		self.timeSpentFallingDown = self.timeSpentFallingDown + dt * 0.001
	end
	self.timeSpentJumping = self.timeSpentJumping + dt * 0.001
	if self.player.mover.isGrounded and not self:calculateIfTakingOff() then
		self.stateMachine:determineState()
		return
	end
	self:trySwitchToValidTransition()
end
function PlayerStateJump:calculateDesiredHorizontalVelocity(directionX, directionZ)
	local maximumMovepeed = self.player.toggleSuperSpeedCommand.value and PlayerStateJump.MAXIMUM_MOVE_SPEED * 8 or PlayerStateJump.MAXIMUM_MOVE_SPEED
	local speed = self.player.mover:calculateSmoothSpeed(self.player.inputComponent.walkAxis, false, 0, maximumMovepeed)
	return directionX * speed, directionZ * speed
end
