-- Local values: PlayerStateIdle_mt
PlayerStateIdle = {}
local PlayerStateIdle_mt = Class(PlayerStateIdle, BaseStateMachineState)

-- Upvalues: PlayerStateIdle_mt
-- Local values: self
function PlayerStateIdle.new(player, stateMachine)
	-- upvalues: (copy) PlayerStateIdle_mt
	local v4_ = BaseStateMachineState.new(stateMachine, PlayerStateIdle_mt)
	v4_.player = player
	return v4_
end

function PlayerStateIdle:createTransitions()
	self:addTransition(self.stateMachine.states.walking.calculateIfMoving, self.stateMachine.states.walking)
	self:addTransition(self.stateMachine.states.jumping.calculateIfJumping, self.stateMachine.states.jumping)
	self:addTransition(self.stateMachine.states.crouching.calculateIfCrouching, self.stateMachine.states.crouching)
end

function PlayerStateIdle:calculateIfValidEntryState()
	local v7_ = self:calculateIfIdle()
	if v7_ then
		v7_ = self.player.mover.isGrounded
	end
	return v7_
end

function PlayerStateIdle:calculateIfIdle()
	if not self.player.isOwner then
		local v9_
		if self.player.mover:getSpeed() <= 0.01 then
			v9_ = not self.stateMachine.states.crouching:calculateIfCrouching()
		else
			v9_ = false
		end
		return v9_
	end
	local v10_ = self.player.mover:getSpeed() <= 0.01 and not self.player.inputComponent.hasMovementInputs
	if v10_ then
		v10_ = not self.stateMachine.states.crouching:calculateIfCrouching()
	end
	return v10_
end
