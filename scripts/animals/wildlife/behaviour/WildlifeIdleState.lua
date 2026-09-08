-- Local values: WildlifeIdleState_mt
WildlifeIdleState = {}
local WildlifeIdleState_mt = Class(WildlifeIdleState, BaseStateMachineState)
local v2_ = {
	["eatDuration"] = {
		["minimum"] = 1,
		["maximum"] = 2
	},
	["attentionDuration"] = {
		["minimum"] = 1,
		["maximum"] = 2
	}
}
WildlifeIdleState.DEFAULT_ATTRIBUTES = v2_
WildlifeIdleState.SOUND_TOGGLE_TARGET = 25

function WildlifeIdleState.registerXMLPaths(xmlSchema)
	xmlSchema:register(XMLValueType.VECTOR_2, "species.behavior.idle#eatDuration", "The range of durations in which the wildlife will eat", WildlifeSpecies.formatRange(WildlifeIdleState.DEFAULT_ATTRIBUTES.eatDuration), false)
	xmlSchema:register(XMLValueType.VECTOR_2, "species.behavior.idle#attentionDuration", "The range of durations in which the wildlife will look for danger", WildlifeSpecies.formatRange(WildlifeIdleState.DEFAULT_ATTRIBUTES.attentionDuration), false)
end

-- Upvalues: WildlifeIdleState_mt
-- Local values: self
function WildlifeIdleState.new(stateMachine)
	-- upvalues: (copy) WildlifeIdleState_mt
	local v5_ = BaseStateMachineState.new(stateMachine, WildlifeIdleState_mt)
	v5_.isEating = false
	v5_.currentAnimationTimer = 0
	v5_.soundToggleCounter = 0
	return v5_
end

function WildlifeIdleState:createTransitions()
	self:addTransition(self.stateMachine.states.wander.canStartWandering, self.stateMachine.states.wander)
end

function WildlifeIdleState:onStateEntered(previousState)
	self.isEating = true
	self:toggleCurrentAnimation()
end

-- Local values: timerRange
function WildlifeIdleState:toggleCurrentAnimation()
	local v9_
	if self.isEating then
		self.isEating = false
		self.stateMachine.instance.graphics:transitionToAnimation("idleAttention")
		v9_ = self.stateMachine.instance.species.behaviourAttributes.idle.attentionDuration
	else
		self.isEating = true
		self.stateMachine.instance.graphics:transitionToAnimation("idleEat")
		v9_ = self.stateMachine.instance.species.behaviourAttributes.idle.eatDuration
	end
	if self.soundToggleCounter >= WildlifeIdleState.SOUND_TOGGLE_TARGET then
		self.stateMachine.instance.sounds:playSound("idle")
		self.soundToggleCounter = 0
	else
		self.soundToggleCounter = self.soundToggleCounter + 1
	end
	self.currentAnimationTimer = MathUtil.randomFloat(v9_.minimum, v9_.maximum) * 1000
end

function WildlifeIdleState:updateAsCurrent(dt)
	if self:trySwitchToValidTransition() == nil then
		self.currentAnimationTimer = self.currentAnimationTimer - dt
		if self.currentAnimationTimer <= 0 then
			self:toggleCurrentAnimation()
		end
	end
end

-- Local values: attributes, eatDuration, attentionDuration
function WildlifeIdleState.loadAttributesTable(xmlFile)
	local v13_ = {}
	local v14_ = xmlFile:getValue("species.behavior.idle#eatDuration", nil, true)
	if v14_ == nil then
		v13_.eatDuration = WildlifeIdleState.DEFAULT_ATTRIBUTES.eatDuration
	else
		v13_.eatDuration = {
			["minimum"] = v14_[1],
			["maximum"] = v14_[2]
		}
	end
	local v15_ = xmlFile:getValue("species.behavior.idle#attentionDuration", nil, true)
	if v15_ == nil then
		v13_.attentionDuration = WildlifeIdleState.DEFAULT_ATTRIBUTES.attentionDuration
		return v13_
	else
		v13_.attentionDuration = {
			["minimum"] = v15_[1],
			["maximum"] = v15_[2]
		}
		return v13_
	end
end
