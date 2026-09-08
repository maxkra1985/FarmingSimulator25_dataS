-- Local values: WildlifeWanderState_mt
WildlifeWanderState = {}
local WildlifeWanderState_mt = Class(WildlifeWanderState, BaseStateMachineState)
local v2_ = {
	["frequency"] = {
		["minimum"] = 120,
		["maximum"] = 360
	},
	["walkRange"] = {
		["minimum"] = 1,
		["maximum"] = 2
	},
	["flyRange"] = nil,
	["swimRange"] = nil,
	["flyChance"] = nil
}
WildlifeWanderState.DEFAULT_ATTRIBUTES = v2_
WildlifeWanderState.MAXIMUM_WALKABLE_HEIGHT = 1
WildlifeWanderState.CALCULATION_STATE_ENUM = {
	["NONE"] = 1,
	["FINDING_TARGET"] = 2,
	["MOVING"] = 3,
	["REACHED_TARGET"] = 4
}

function WildlifeWanderState.registerXMLPaths(xmlSchema)
	xmlSchema:register(XMLValueType.VECTOR_2, "species.behavior.wander#frequency", "The minimum and maximum frequency that this species will want to move somewhere else. Every time the species moves, a value between these values will be generated", WildlifeSpecies.formatRange(WildlifeWanderState.DEFAULT_ATTRIBUTES.frequency), false)
	xmlSchema:register(XMLValueType.VECTOR_2, "species.behavior.wander.walk#range", "The minimum and maximum range that this species will walk", WildlifeSpecies.formatRange(WildlifeWanderState.DEFAULT_ATTRIBUTES.walkRange), false)
	xmlSchema:register(XMLValueType.VECTOR_2, "species.behavior.wander.fly#range", "The minimum and maximum range that this species will fly", WildlifeSpecies.formatRange(WildlifeWanderState.DEFAULT_ATTRIBUTES.flyRange), false)
	xmlSchema:register(XMLValueType.FLOAT, "species.behavior.wander.fly#chance", "The chance that this species will fly rather than walk to its target", WildlifeWanderState.DEFAULT_ATTRIBUTES.flyChance, false)
	xmlSchema:register(XMLValueType.VECTOR_2, "species.behavior.wander.swim#range", "The minimum and maximum range that this species will swim", WildlifeSpecies.formatRange(WildlifeWanderState.DEFAULT_ATTRIBUTES.swimRange), false)
end

-- Upvalues: WildlifeWanderState_mt
-- Local values: self
function WildlifeWanderState.new(stateMachine)
	-- upvalues: (copy) WildlifeWanderState_mt
	local v5_ = BaseStateMachineState.new(stateMachine, WildlifeWanderState_mt)
	v5_.isActive = false
	v5_.mover = stateMachine.instance.mover
	v5_.frequency = WildlifeWanderState.DEFAULT_ATTRIBUTES.frequency
	v5_.walkRange = WildlifeWanderState.DEFAULT_ATTRIBUTES.walkRange
	v5_.flyRange = WildlifeWanderState.DEFAULT_ATTRIBUTES.flyRange
	v5_.swimRange = WildlifeWanderState.DEFAULT_ATTRIBUTES.swimRange
	v5_.flyChance = WildlifeWanderState.DEFAULT_ATTRIBUTES.flyChance
	v5_.lastWanderedAt = nil
	v5_.wanderCooldown = 0
	v5_.calculationState = WildlifeWanderState.CALCULATION_STATE_ENUM.NONE
	v5_.isFlying = false
	v5_.pendingTargetCheck = nil
	return v5_
end

function WildlifeWanderState:createTransitions()
	self:addTransition(self.hasFinishedWandering, self.stateMachine.states.idle, self)
end

function WildlifeWanderState:initialiseToSpecies(species) end

function WildlifeWanderState:canStartWandering()
	local v8_ = self.isActive and not self.stateMachine.instance.mover:getIsMoving()
	if v8_ then
		local v9_ = g_time * 0.001
		local v10_ = self.lastWanderedAt
		if v9_ - math.abs(v10_) >= self.wanderCooldown then
			v8_ = self.calculationState == WildlifeWanderState.CALCULATION_STATE_ENUM.NONE
		else
			v8_ = false
		end
	end
	return v8_
end

function WildlifeWanderState:hasFinishedWandering()
	return self.calculationState == WildlifeWanderState.CALCULATION_STATE_ENUM.REACHED_TARGET
end

function WildlifeWanderState:onStateEntered(previousState)
	self.wanderCooldown = MathUtil.randomFloat(self.frequency.minimum, self.frequency.maximum)
	self:randomlySetTarget()
	self.stateMachine.instance.graphics:transitionToAnimation("idleAttention")
end

function WildlifeWanderState:onStateExited(nextState)
	self.lastWanderedAt = g_time * 0.001
	self.calculationState = WildlifeWanderState.CALCULATION_STATE_ENUM.NONE
	self.pendingTargetCheck = nil
end

-- Local values: range, isFlying, currentX, currentY, currentZ, randomAngle, randomDistance, randomX, randomZ
function WildlifeWanderState:randomlySetTarget()
	self.calculationState = WildlifeWanderState.CALCULATION_STATE_ENUM.FINDING_TARGET
	local v15_ = false
	local v16_
	if self.mover.canFly and (self.flyRange and math.random() <= self.flyChance) then
		v16_ = self.flyRange
		v15_ = true
	elseif self.mover.canSwim and (self.swimRange and self.mover.isSwimming) then
		v16_ = self.swimRange
	else
		v16_ = self.walkRange
	end
	local v17_, v18_, v19_ = self.mover.instance:getCurrentPosition()
	local v20_ = MathUtil.randomFloat(-3.141592653589793, 3.141592653589793)
	local v21_ = MathUtil.randomFloat
	local v22_ = v16_.minimum
	local v23_ = WildlifeInstanceMover.MINIMUM_TARGET_DISTANCE
	local v24_ = v21_(math.min(v22_, v23_), v16_.maximum)
	local v25_ = v17_ + math.cos(v20_) * v24_
	local v26_ = v19_ + math.sin(v20_) * v24_
	self.pendingTargetCheck = true
	self.isFlying = v15_
	raycastClosestAsync(v25_, v18_ + 100, v26_, 0, -1, 0, 200, "onTargetCallback", self, WildlifeInstanceMover.COLLISION_MASK)
end

-- Local values: correctedTargetY, isMoving
function WildlifeWanderState:onTargetCallback(nodeId, x, y, z, distance, nx, ny, nz, subShapeIndex, shapeId, isLast)
	if self.pendingTarget == nil then
		return
	else
		self.pendingTargetCheck = nil
		if nodeId == nil or nodeId == 0 then
			return
		else
			local v32_ = WildlifeInstanceMover.adjustRayHitForWater(nodeId, x, y, z, self.stateMachine.instance.species.movementAttributes, true)
			if v32_ == nil then
				return
			else
				local v33_
				if self.isFlying then
					v33_ = self.mover:flyToTarget(x, v32_, z)
				else
					v33_ = self.mover:moveToTarget(x, v32_, z)
				end
				if v33_ then
					self.calculationState = WildlifeWanderState.CALCULATION_STATE_ENUM.MOVING
					self.stateMachine.instance.graphics:transitionToAnimation("idleWalk")
				end
			end
		end
	end
end

function WildlifeWanderState:onInstanceSpawned(spawnX, spawnY, spawnZ, species, group, mainInstance)
	self.isActive = species.behaviourAttributes.wander ~= nil
	if self.isActive then
		self.frequency = species.behaviourAttributes.wander.frequency
		self.walkRange = species.behaviourAttributes.wander.walkRange
		self.flyRange = species.behaviourAttributes.wander.flyRange
		self.flyChance = species.behaviourAttributes.wander.flyChance
		self.swimRange = species.behaviourAttributes.wander.swimRange
		self.lastWanderedAt = g_time * 0.001 - MathUtil.randomFloat(0, self.frequency.maximum)
		self.wanderCooldown = MathUtil.randomFloat(self.frequency.minimum, self.frequency.maximum)
	end
end

function WildlifeWanderState:onInstanceDespawned()
	self.calculationState = WildlifeWanderState.CALCULATION_STATE_ENUM.NONE
	self.pendingTargetCheck = nil
end

function WildlifeWanderState:onMovementTargetReached()
	self.wanderCooldown = MathUtil.randomFloat(self.frequency.minimum, self.frequency.maximum)
	self.lastWanderedAt = g_time * 0.001
	if self.stateMachine.currentState == self then
		self.calculationState = WildlifeWanderState.CALCULATION_STATE_ENUM.REACHED_TARGET
	else
		self.calculationState = WildlifeWanderState.CALCULATION_STATE_ENUM.NONE
	end
end

function WildlifeWanderState:updateAsCurrent(dt)
	if self.calculationState == WildlifeWanderState.CALCULATION_STATE_ENUM.FINDING_TARGET and not self.pendingTargetCheck then
		self:randomlySetTarget()
	end
	self:trySwitchToValidTransition()
end

-- Local values: attributes, frequency, walkRange, flyRange, flyChance, swimRange
function WildlifeWanderState.loadAttributesTable(xmlFile)
	local v40_ = {}
	local v41_ = xmlFile:getValue("species.behavior.wander#frequency", nil, true)
	if not v41_ then
		return nil
	end
	v40_.frequency = {
		["minimum"] = v41_[1],
		["maximum"] = v41_[2]
	}
	local v42_ = xmlFile:getValue("species.behavior.wander.walk#range", nil, true)
	if not v42_ then
		return nil
	end
	v40_.walkRange = {
		["minimum"] = v42_[1],
		["maximum"] = v42_[2]
	}
	local v43_ = xmlFile:getValue("species.behavior.wander.fly#range", nil, true)
	local v44_ = xmlFile:getValue("species.behavior.wander.fly#chance", nil)
	if v43_ and v44_ then
		v40_.flyRange = {
			["minimum"] = v43_[1],
			["maximum"] = v43_[2]
		}
		v40_.flyChance = v44_
	else
		if v43_ ~= nil ~= (v44_ ~= nil) then
			Logging.xmlError(xmlFile, "Fly attribute node is missing either range or chance")
			return nil
		end
		v40_.flyRange = WildlifeWanderState.DEFAULT_ATTRIBUTES.flyRange
		v40_.flyChance = WildlifeWanderState.DEFAULT_ATTRIBUTES.flyChance
	end
	local v45_ = xmlFile:getValue("species.behavior.wander.swim#range", nil, true)
	v40_.swimRange = v45_ and {
		["minimum"] = v45_[1],
		["maximum"] = v45_[2]
	} or WildlifeWanderState.DEFAULT_ATTRIBUTES.swimRange
	return v40_
end
