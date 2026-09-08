-- Local values: WildlifeFollowState_mt
WildlifeFollowState = {}
local WildlifeFollowState_mt = Class(WildlifeFollowState, BaseStateMachineState)
local v2_ = {
	["frequency"] = {
		["minimum"] = 120,
		["maximum"] = 360
	},
	["targetRange"] = {
		["minimum"] = 2,
		["maximum"] = 4
	},
	["maximumDistance"] = 6
}
WildlifeFollowState.DEFAULT_ATTRIBUTES = v2_

function WildlifeFollowState.registerXMLPaths(xmlSchema)
	xmlSchema:register(XMLValueType.VECTOR_2, "species.behavior.follow#frequency", "The range of seconds that the instance will wait between going to a position around the target", WildlifeSpecies.formatRange(WildlifeFollowState.DEFAULT_ATTRIBUTES.frequency), false)
	xmlSchema:register(XMLValueType.VECTOR_2, "species.behavior.follow#targetRange", "The range of radii where the instance can set a target", WildlifeSpecies.formatRange(WildlifeFollowState.DEFAULT_ATTRIBUTES.targetRange), false)
	xmlSchema:register(XMLValueType.FLOAT, "species.behavior.follow#maximumDistance", "The maximum range before the instance will force find a target to the leader", WildlifeFollowState.DEFAULT_ATTRIBUTES.maximumDistance, false)
end

-- Upvalues: WildlifeFollowState_mt
-- Local values: self
function WildlifeFollowState.new(stateMachine)
	-- upvalues: (copy) WildlifeFollowState_mt
	local v5_ = BaseStateMachineState.new(stateMachine, WildlifeFollowState_mt)
	v5_.isActive = false
	v5_.mover = stateMachine.instance.mover
	v5_.frequency = WildlifeFollowState.DEFAULT_ATTRIBUTES.frequency
	v5_.targetRange = WildlifeFollowState.DEFAULT_ATTRIBUTES.targetRange
	v5_.maximumDistance = WildlifeFollowState.DEFAULT_ATTRIBUTES.maximumDistance
	v5_.timeOfLastTarget = g_time * 0.001
	v5_.targetCooldown = 0
	v5_.leaderInstance = nil
	return v5_
end

function WildlifeFollowState:calculateIfShouldBeForced()
	return self:canSetFollowTarget()
end

-- Local values: currentX, _, currentZ, distanceToLeader
function WildlifeFollowState:canSetFollowTarget()
	if not self.isActive or (self.leaderInstance == nil or self.stateMachine.states.flee.fleeingToDespawn) then
		return false
	end
	local v8_, _, v9_ = self.mover.instance:getCurrentPosition()
	return self.leaderInstance:calculateDistanceFrom(v8_, v9_) >= self.maximumDistance and true or g_time * 0.001 - self.timeOfLastTarget >= self.targetCooldown
end

function WildlifeFollowState:resetMovementState()
	self.targetCooldown = MathUtil.randomFloat(self.frequency.minimum, self.frequency.maximum)
	self.timeOfLastTarget = g_time * 0.001
end

-- Local values: targetX, targetY, targetZ, randomAngle, randomDistance, moveSpeed
function WildlifeFollowState:onStateEntered(previousState)
	self.timeOfLastTarget = g_time * 0.001
	local v12_, v13_, v14_ = self.leaderInstance:getCurrentPosition()
	local v15_ = MathUtil.randomFloat(-3.141592653589793, 3.141592653589793)
	local v16_ = MathUtil.randomFloat(self.targetRange.minimum, self.targetRange.maximum)
	local v17_ = v12_ + math.cos(v15_) * v16_
	local v18_ = v14_ + math.sin(v15_) * v16_
	local v19_ = self.leaderInstance.mover.currentAverageSpeed * 1.1
	local v20_ = math.max(1, v19_)
	if self.leaderInstance.mover.isFlyingToTarget and self.stateMachine.instance.species.movementAttributes.canFly then
		self.mover:flyToTarget(v17_, v13_, v18_, v20_)
	else
		self.mover:moveToTarget(v17_, v13_, v18_, v20_)
	end
end

function WildlifeFollowState:onStateExited(nextState)
	self:resetMovementState()
end

function WildlifeFollowState:onInstanceSpawned(spawnX, spawnY, spawnZ, species, group, mainInstance)
	self.isActive = species.behaviourAttributes.follow ~= nil
	if self.isActive then
		self.frequency = species.behaviourAttributes.follow.frequency
		self.targetRange = species.behaviourAttributes.follow.targetRange
		self.maximumDistance = species.behaviourAttributes.follow.maximumDistance
		self.timeOfLastTarget = g_time * 0.001 - MathUtil.randomFloat(0, self.frequency.maximum)
		self.targetCooldown = MathUtil.randomFloat(self.frequency.minimum, self.frequency.maximum)
		if self.mover.instance ~= mainInstance and (mainInstance ~= nil and self.stateMachine.instance.species.behaviourAttributes.follow ~= nil) then
			self.leaderInstance = mainInstance
			self.stateMachine:changeState(self)
		end
	else
		return
	end
end

function WildlifeFollowState:onInstanceDespawned()
	self.leaderInstance = nil
	self.isActive = false
	self:resetMovementState()
end

function WildlifeFollowState:onMovementTargetReached()
	if self.stateMachine.currentState == self then
		if not self:canSetFollowTarget() then
			self.stateMachine:determineState()
		end
		self:resetMovementState()
	end
end

-- Local values: attributes, frequency, targetRange
function WildlifeFollowState.loadAttributesTable(xmlFile)
	local v28_ = {}
	local v29_ = xmlFile:getValue("species.behavior.follow#frequency", nil, true)
	if v29_ == nil then
		return nil
	else
		v28_.frequency = {
			["minimum"] = v29_[1],
			["maximum"] = v29_[2]
		}
		local v30_ = xmlFile:getValue("species.behavior.follow#targetRange", nil, true)
		if v30_ == nil then
			return nil
		else
			v28_.targetRange = {
				["minimum"] = v30_[1],
				["maximum"] = v30_[2]
			}
			v28_.maximumDistance = xmlFile:getValue("species.behavior.follow#maximumDistance", nil)
			if v28_.maximumDistance == nil then
				return nil
			else
				return v28_
			end
		end
	end
end
