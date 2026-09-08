-- Local values: PlayerStateMachine_mt
PlayerStateMachine = {}
local PlayerStateMachine_mt = Class(PlayerStateMachine, StateMachine)

-- Upvalues: PlayerStateMachine_mt
-- Local values: self
function PlayerStateMachine.new(player)
	-- upvalues: (copy) PlayerStateMachine_mt
	local v3_ = StateMachine.new(PlayerStateMachine_mt)
	v3_.player = player
	v3_.states = {
		["onFoot"] = PlayerOnFootStateMachine.new(player),
		["driving"] = PlayerStateDriving.new(player, v3_),
		["passenger"] = PlayerStatePassenger.new(player, v3_),
		["rollercoaster"] = PlayerStateRollercoaster.new(player, v3_)
	}
	v3_:initialiseStateTransitions()
	v3_.currentState = v3_.states.onFoot
	v3_.defaultState = v3_.states.onFoot
	v3_:setIsPassive(true)
	return v3_
end

function PlayerStateMachine:updateWhilePaused(dt, isInGui, isFrozen)
	self:callStateFunction("updateWhilePaused", dt, isInGui, isFrozen)
end
