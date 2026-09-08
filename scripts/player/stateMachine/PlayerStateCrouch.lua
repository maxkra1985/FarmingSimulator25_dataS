-- Local values: PlayerStateCrouch_mt
PlayerStateCrouch = {}
local PlayerStateCrouch_mt = Class(PlayerStateCrouch, BaseStateMachineState)
PlayerStateCrouch.MAXIMUM_ROTATION_SPEED = 180
PlayerStateCrouch.MAXIMUM_MOVE_SPEED = 3
PlayerStateCrouch.SMOOTHING_TIME = 0.2
PlayerStateCrouch.CROUCHED_CAMERA_OFFSET = -0.6

-- Upvalues: PlayerStateCrouch_mt
-- Local values: self
function PlayerStateCrouch.new(player, stateMachine)
	-- upvalues: (copy) PlayerStateCrouch_mt
	local v4_ = BaseStateMachineState.new(stateMachine, PlayerStateCrouch_mt)
	v4_.player = player
	v4_.cameraOffsetY = 0
	v4_.crouchTime = 0
	v4_.transitionTime = 0
	return v4_
end

function PlayerStateCrouch:createTransitions()
	self:addTransition(self.stateMachine.states.idle.calculateIfIdle, self.stateMachine.states.idle)
	self:addTransition(self.stateMachine.states.walking.calculateIfMoving, self.stateMachine.states.walking)
	self:addTransition(self.stateMachine.states.jumping.calculateIfJumping, self.stateMachine.states.jumping)
end

function PlayerStateCrouch:calculateIfValidEntryState()
	local v7_ = self:calculateIfCrouching() and self.player.mover.isGrounded
	if v7_ then
		v7_ = not self.stateMachine.states.swimming:calculateIfSubmerged()
	end
	return v7_
end

function PlayerStateCrouch:calculateIfCrouching()
	if not self.player.isOwner then
		return false
	end
	local v9_ = self.player.inputComponent.crouchValue > 0 and (not self.player:getIsHoldingHandTool() or self.player:getHeldHandTool().canCrouch)
	if v9_ then
		v9_ = self.player.mover.currentWaterSubmergeDistance < 1
	end
	return v9_
end

function PlayerStateCrouch:onStateEntered(previousState)
	self.player.mover:setIsCrouching(true)
	self:resetTimers()
end

function PlayerStateCrouch:onStateExited(nextState)
	self.player.mover:setIsCrouching(false)
	self:resetTimers()
end

function PlayerStateCrouch:resetTimers()
	self.transitionTime = 0
	self.crouchTime = 0
	self.cameraOffsetY = 0
end

-- Local values: crouchProgress
function PlayerStateCrouch:updateAsCurrent(dt)
	if self:calculateIfCrouching() then
		self.player.capsuleController:setHeight(PlayerCCT.DEFAULT_HEIGHT * 0.5)
		self.crouchTime = self.crouchTime + dt * 0.001
		local v15_ = self.transitionTime + dt * 0.001
		local v16_ = PlayerStateCrouch.SMOOTHING_TIME
		self.transitionTime = math.min(v15_, v16_)
	else
		self.player.capsuleController:setHeight(PlayerCCT.DEFAULT_HEIGHT)
		if self.player.capsuleController:getHeight() == PlayerCCT.DEFAULT_HEIGHT then
			self.crouchTime = 0
			local v17_ = self.transitionTime - dt * 0.001
			self.transitionTime = math.max(0, v17_)
		end
	end
	local v18_ = self.transitionTime / PlayerStateCrouch.SMOOTHING_TIME
	local v19_ = math.clamp(v18_, 0, 1)
	self.cameraOffsetY = PlayerStateCrouch.CROUCHED_CAMERA_OFFSET * v19_
	if not self.stateMachine:getIsPassive() and (self.transitionTime <= 0 and self.player.capsuleController:getHeight() == PlayerCCT.DEFAULT_HEIGHT) then
		self:trySwitchToValidTransition()
	end
end

function PlayerStateCrouch:calculateMaximumSpeed()
	return PlayerStateCrouch.MAXIMUM_MOVE_SPEED
end

-- Local values: speed
function PlayerStateCrouch:calculateDesiredHorizontalVelocity(directionX, directionZ)
	local v23_ = self.player.mover:calculateSmoothSpeed(self.player.inputComponent.walkAxis, true, 0, PlayerStateCrouch.MAXIMUM_MOVE_SPEED)
	return directionX * v23_, directionZ * v23_
end
