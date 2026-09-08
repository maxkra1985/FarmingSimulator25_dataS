-- Local values: PlayerStateWalk_mt
PlayerStateWalk = {}
local PlayerStateWalk_mt = Class(PlayerStateWalk, BaseStateMachineState)
PlayerStateWalk.MAXIMUM_WALK_SPEED = 4
PlayerStateWalk.MAXIMUM_RUN_SPEED = 7

-- Upvalues: PlayerStateWalk_mt
-- Local values: self
function PlayerStateWalk.new(player, stateMachine)
	-- upvalues: (copy) PlayerStateWalk_mt
	local v4_ = BaseStateMachineState.new(stateMachine, PlayerStateWalk_mt)
	v4_.player = player
	v4_.walkAxis = 0
	v4_.runAxis = 0
	return v4_
end

function PlayerStateWalk:createTransitions()
	self:addTransition(self.stateMachine.states.idle.calculateIfIdle, self.stateMachine.states.idle)
	self:addTransition(self.stateMachine.states.jumping.calculateIfJumping, self.stateMachine.states.jumping)
	self:addTransition(self.stateMachine.states.crouching.calculateIfCrouching, self.stateMachine.states.crouching)
end

function PlayerStateWalk:calculateIfValidEntryState()
	local v7_ = self:calculateIfMoving() and self.player.mover.isGrounded
	if v7_ then
		v7_ = not self.stateMachine.states.swimming:calculateIfSubmerged()
	end
	return v7_
end

function PlayerStateWalk:calculateIfMoving()
	if not self.player.isOwner then
		local v9_
		if self.player.mover:getSpeed() > 0.01 then
			v9_ = not self.stateMachine.states.crouching:calculateIfCrouching()
		else
			v9_ = false
		end
		return v9_
	end
	local v10_ = self.player.mover:getSpeed() <= 0.01 and self.player.inputComponent.hasMovementInputs
	if v10_ then
		v10_ = not self.stateMachine.states.crouching:calculateIfCrouching()
	end
	return v10_
end

function PlayerStateWalk:calculateIfWalking()
	local v12_ = self:calculateIfMoving()
	if v12_ then
		v12_ = self.runAxis == 0
	end
	return v12_
end

-- Local values: runMultiplier
function PlayerStateWalk:calculateIfRunning()
	local v14_ = self.player:getRunMultiplier()
	local v15_ = self:calculateIfMoving()
	if v15_ then
		if self.runAxis > 0 then
			v15_ = v14_ > 0
		else
			v15_ = false
		end
	end
	return v15_
end

function PlayerStateWalk:updateAsCurrent(dt)
	if self.player.isOwner then
		self.walkAxis = self.player.inputComponent.walkAxis
		self.runAxis = self.player.inputComponent.runAxis
		PlayerStateWalk:superClass().updateAsCurrent(self, dt)
	else
		PlayerStateWalk:superClass().updateAsCurrent(self, dt)
	end
end

function PlayerStateWalk:calculateMaximumSpeed()
	if self:calculateIfRunning() then
		return self:getMaximumRunSpeed()
	else
		return self:getMaximumWalkSpeed()
	end
end

-- Local values: runSpeed
function PlayerStateWalk:getMaximumRunSpeed()
	local v20_ = PlayerStateWalk.MAXIMUM_RUN_SPEED
	if self.player.toggleSuperSpeedCommand ~= nil and self.player.toggleSuperSpeedCommand.value then
		v20_ = v20_ * 8
	end
	return v20_
end

function PlayerStateWalk:getMaximumWalkSpeed()
	return PlayerStateWalk.MAXIMUM_WALK_SPEED
end

-- Local values: maxWalkSpeed, maxRunSpeed, moveScalar, moveScale
function PlayerStateWalk:calculateDesiredSpeed()
	local v22_ = self:getMaximumWalkSpeed()
	local v23_ = self:getMaximumRunSpeed()
	if self:calculateIfRunning() then
		local v24_ = self.runAxis * self.walkAxis * self.player:getRunMultiplier()
		return self.player.mover:calculateSmoothSpeed(v24_, true, v22_, v23_)
	else
		local v25_ = self.walkAxis * self.player:getWalkMultiplier()
		return self.player.mover:calculateSmoothSpeed(v25_, true, 0, v22_)
	end
end

-- Local values: speed
function PlayerStateWalk:calculateDesiredHorizontalVelocity(directionX, directionZ)
	local v29_ = self:calculateDesiredSpeed()
	return directionX * v29_, directionZ * v29_
end
