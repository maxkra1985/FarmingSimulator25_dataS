-- Local values: PlayerStateJump_mt
PlayerStateJump = {}
local PlayerStateJump_mt = Class(PlayerStateJump, BaseStateMachineState)
PlayerStateJump.MINIMUM_GROUND_TIME_THRESHOLD = 0.7
PlayerStateJump.FALL_TIME_THRESHOLD = 1
PlayerStateJump.JUMP_TIME_THRESHOLD = 0.25
PlayerStateJump.JUMP_UPFORCE = 5.5
PlayerStateJump.GROUND_LANDING_DISTANCE = 1
PlayerStateJump.MAXIMUM_MOVE_SPEED = 3

-- Upvalues: PlayerStateJump_mt
-- Local values: self
function PlayerStateJump.new(player, stateMachine)
	-- upvalues: (copy) PlayerStateJump_mt
	local v4_ = BaseStateMachineState.new(stateMachine, PlayerStateJump_mt)
	v4_.player = player
	v4_.timeSpentFallingDown = 0
	v4_.timeSpentJumping = 0
	return v4_
end

function PlayerStateJump:createTransitions()
	self:addTransition(self.calculateIfFalling, self.stateMachine.states.falling, self)
end

function PlayerStateJump:calculateIfFalling()
	return self.timeSpentFallingDown >= self.FALL_TIME_THRESHOLD
end

function PlayerStateJump:calculateIfJumping()
	if self.player.isOwner then
		local v8_
		if self.player.inputComponent.jumpPower * self.player:getJumpMultiplier() > 0 then
			v8_ = self.player.mover.currentGroundTime >= PlayerStateJump.MINIMUM_GROUND_TIME_THRESHOLD
		else
			v8_ = false
		end
		return v8_
	else
		local v9_
		if self.player.mover.currentVelocityY > 0 then
			v9_ = self.player.mover.currentGroundTime >= PlayerStateJump.MINIMUM_GROUND_TIME_THRESHOLD
		else
			v9_ = false
		end
		return v9_
	end
end

function PlayerStateJump:calculateIfTakingOff()
	local v11_
	if self.timeSpentJumping <= self.JUMP_TIME_THRESHOLD then
		v11_ = self.player.mover.currentVelocityY > 0
	else
		v11_ = false
	end
	return v11_
end

function PlayerStateJump:calculateIfLanding()
	local v13_
	if self.player.mover.currentGroundDistance <= self.GROUND_LANDING_DISTANCE then
		v13_ = not self:calculateIfTakingOff()
	else
		v13_ = false
	end
	return v13_
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
	else
		self:trySwitchToValidTransition()
	end
end

-- Local values: maximumMovepeed, speed
function PlayerStateJump:calculateDesiredHorizontalVelocity(directionX, directionZ)
	local v22_ = self.player.toggleSuperSpeedCommand.value and PlayerStateJump.MAXIMUM_MOVE_SPEED * 8 or PlayerStateJump.MAXIMUM_MOVE_SPEED
	local v23_ = self.player.mover:calculateSmoothSpeed(self.player.inputComponent.walkAxis, false, 0, v22_)
	return directionX * v23_, directionZ * v23_
end
