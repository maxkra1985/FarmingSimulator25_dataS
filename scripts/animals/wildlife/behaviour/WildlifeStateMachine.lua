-- Local values: WildlifeStateMachine_mt
WildlifeStateMachine = {}
local WildlifeStateMachine_mt = Class(WildlifeStateMachine, StateMachine)

-- Upvalues: WildlifeStateMachine_mt
-- Local values: self
function WildlifeStateMachine.new(instance)
	-- upvalues: (copy) WildlifeStateMachine_mt
	local v3_ = StateMachine.new(WildlifeStateMachine_mt)
	v3_.instance = instance
	v3_.states = {
		["idle"] = WildlifeIdleState.new(v3_),
		["wander"] = WildlifeWanderState.new(v3_),
		["flee"] = WildlifeFleeState.new(v3_),
		["follow"] = WildlifeFollowState.new(v3_)
	}
	v3_:initialiseStateTransitions()
	v3_.currentState = v3_.states.idle
	v3_.defaultState = v3_.states.idle
	return v3_
end

function WildlifeStateMachine:onInstanceSpawned(spawnX, spawnY, spawnZ, species, group, mainInstance)
	self:callStateFunction("onInstanceSpawned", spawnX, spawnY, spawnZ, species, group, mainInstance)
	self:changeState(self.states.idle)
	self.states.idle:updateAsCurrent(g_currentDt)
end

function WildlifeStateMachine:onInstanceDespawned()
	self:callStateFunction("onInstanceDespawned")
end

function WildlifeStateMachine:onMovementTargetReached()
	self:callStateFunction("onMovementTargetReached")
end
function WildlifeStateMachine.callStateFunction(p13_, p14_, ...)
	WildlifeStateMachine:superClass().callStateFunction(p13_, p14_, ...)
end
