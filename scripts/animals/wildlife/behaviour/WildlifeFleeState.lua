-- Local values: WildlifeFleeState_mt
WildlifeFleeState = {}
local WildlifeFleeState_mt = Class(WildlifeFleeState, BaseStateMachineState)
WildlifeFleeState.DEFAULT_ATTRIBUTES = {
	["distance"] = 6,
	["patienceLossPerMove"] = 45,
	["patiencePerSecond"] = 5,
	["moveSpeed"] = nil
}

function WildlifeFleeState.registerXMLPaths(xmlSchema)
	xmlSchema:register(XMLValueType.FLOAT, "species.behavior.flee#distance", "The range at which the species will run from the player", WildlifeFleeState.DEFAULT_ATTRIBUTES.distance, false)
	xmlSchema:register(XMLValueType.FLOAT, "species.behavior.flee#patienceLossPerMove", "How many points of patience are lost every time this speies has to flee", WildlifeFleeState.DEFAULT_ATTRIBUTES.patienceLossPerMove, false)
	xmlSchema:register(XMLValueType.FLOAT, "species.behavior.flee#patiencePerSecond", "How many points of patience are restored per second", WildlifeFleeState.DEFAULT_ATTRIBUTES.patiencePerSecond, false)
	xmlSchema:register(XMLValueType.FLOAT, "species.behavior.flee#moveSpeed", "How fast the instance moves while fleeing", WildlifeFleeState.DEFAULT_ATTRIBUTES.moveSpeed, false)
end

-- Upvalues: WildlifeFleeState_mt
-- Local values: self
function WildlifeFleeState.new(stateMachine)
	-- upvalues: (copy) WildlifeFleeState_mt
	local v4_ = BaseStateMachineState.new(stateMachine, WildlifeFleeState_mt)
	v4_.patience = 100
	v4_.fleeingToDespawn = false
	v4_.pendingTargetCheck = nil
	return v4_
end

function WildlifeFleeState:calculateIfShouldBeForced()
	return self:calculateIfShouldFlee()
end

-- Local values: playerX, playerZ, distanceFromPlayer
function WildlifeFleeState:calculateIfShouldFlee()
	if self.stateMachine.currentState == self then
		return false
	end
	local v7_, v8_ = g_localPlayer:getMapPositionAndLookYaw()
	return self.stateMachine.instance:calculateDistanceFrom(v7_, v8_) < self.stateMachine.instance.species.behaviourAttributes.flee.distance
end

-- Local values: patiencePerSecond
function WildlifeFleeState:replenishPatience(dt)
	if not self.fleeingToDespawn then
		local v11_ = self.stateMachine.instance.species.behaviourAttributes.flee.patiencePerSecond
		local v12_ = self.patience + v11_ * dt * 0.001
		self.patience = math.min(v12_, 100)
	end
end

-- Local values: patienceLossPerMove, currentX, _, currentZ, playerX, playerZ, fleeDirectionX, fleeDirectionZ
function WildlifeFleeState:fleeFromPlayer(patienceLossMultiplier)
	if not self.fleeingToDespawn then
		local v15_ = self.stateMachine.instance.species.behaviourAttributes.flee.patienceLossPerMove
		local v16_ = self.patience - v15_ * (patienceLossMultiplier or 1)
		self.patience = math.max(v16_, 0)
		local v17_, _, v18_ = self.stateMachine.instance:getCurrentPosition()
		local v19_, v20_ = g_localPlayer:getMapPositionAndLookYaw()
		local v21_, v22_ = MathUtil.vector2Normalize(v17_ - v19_, v18_ - v20_)
		self:fleeInDirection(v21_, v22_)
	end
end

-- Local values: fleeDistance, currentX, _, currentZ, targetX, targetZ, targetY
function WildlifeFleeState:fleeInDirection(fleeDirectionX, fleeDirectionZ)
	if self.fleeingToDespawn or self.pendingTargetCheck then
		return
	elseif self.patience <= 0 then
		self:fleeToDespawn(fleeDirectionX, fleeDirectionZ)
	else
		local v26_ = self.stateMachine.instance.species.behaviourAttributes.flee.distance * (1 + math.random())
		local v27_, _, v28_ = self.stateMachine.instance:getCurrentPosition()
		local v29_ = v27_ + fleeDirectionX * v26_
		local v30_ = v28_ + fleeDirectionZ * v26_
		local v31_ = getTerrainHeightAtWorldPos(g_terrainNode, v29_, 0, v30_)
		self.pendingTargetCheck = true
		self.fleeDirectionX = fleeDirectionX
		self.fleeDirectionZ = fleeDirectionZ
		raycastClosestAsync(v29_, v31_ + 100, v30_, 0, -1, 0, 200, "onTargetCallback", self, WildlifeInstanceMover.COLLISION_MASK)
	end
end

-- Local values: adjustedTargetY, moveSpeed
function WildlifeFleeState:onTargetCallback(nodeId, x, y, z, distance, nx, ny, nz, subShapeIndex, shapeId, isLast)
	if self.pendingTargetCheck == nil then
		return
	else
		self.pendingTargetCheck = nil
		local v37_ = WildlifeInstanceMover.adjustRayHitForWater(nodeId, x, y, z, self.stateMachine.instance.species.movementAttributes)
		if v37_ == nil then
			self:fleeToDespawn(self.fleeDirectionX, self.fleeDirectionZ)
		else
			local v38_ = self.stateMachine.instance.species.behaviourAttributes.flee.moveSpeed
			self.stateMachine.instance.mover:flyOrMoveToTarget(x, v37_, z, v38_)
		end
	end
end

-- Local values: fleeDistance, currentX, _, currentZ, targetX, targetZ, terrainX, terrainZ, targetY, moveSpeed
function WildlifeFleeState:fleeToDespawn(fleeDirectionX, fleeDirectionZ, shouldTakeOff)
	self.fleeingToDespawn = true
	local v43_ = g_currentMission.mapWidth + g_currentMission.mapHeight
	local v44_, _, v45_ = self.stateMachine.instance:getCurrentPosition()
	local v46_ = v44_ + fleeDirectionX * v43_
	local v47_ = v45_ + fleeDirectionZ * v43_
	local v48_ = g_currentMission.mapWidth / -2
	local v49_ = g_currentMission.mapWidth / 2
	local v50_ = math.clamp(v46_, v48_, v49_)
	local v51_ = g_currentMission.mapHeight / -2
	local v52_ = g_currentMission.mapHeight / 2
	local v53_ = math.clamp(v47_, v51_, v52_)
	local v54_ = getTerrainHeightAtWorldPos(g_terrainNode, v50_, 0, v53_)
	if self.stateMachine.instance.species.movementAttributes.canFly then
		v54_ = v54_ + 50
	end
	local v55_ = self.stateMachine.instance.species.behaviourAttributes.flee.moveSpeed
	self.stateMachine.instance.mover:flyOrMoveToTarget(v46_, v54_, v47_, v55_, shouldTakeOff)
end

function WildlifeFleeState:onStateEntered(previousState)
	self:fleeFromPlayer()
end

function WildlifeFleeState:onInstanceSpawned(spawnX, spawnY, spawnZ, species, group)
	self.pendingTargetCheck = nil
	self.patience = 100
	self.fleeingToDespawn = false
end

function WildlifeFleeState:onInstanceDespawned()
	self.pendingTargetCheck = nil
end

function WildlifeFleeState:onMovementTargetReached()
	self.pendingTargetCheck = nil
	if self.stateMachine.currentState == self then
		if self:calculateIfShouldFlee() then
			self:fleeFromPlayer(2.5)
		else
			self.stateMachine:determineState()
		end
	else
		return
	end
end

function WildlifeFleeState:updateAsCurrent(dt)
	self:replenishPatience(dt)
end

function WildlifeFleeState:updateAsInactive(dt)
	self:replenishPatience(dt)
end

-- Local values: attributes
function WildlifeFleeState.loadAttributesTable(xmlFile)
	return {
		["distance"] = xmlFile:getValue("species.behavior.flee#distance", WildlifeFleeState.DEFAULT_ATTRIBUTES.distance),
		["patienceLossPerMove"] = xmlFile:getValue("species.behavior.flee#patienceLossPerMove", WildlifeFleeState.DEFAULT_ATTRIBUTES.patienceLossPerMove),
		["patiencePerSecond"] = xmlFile:getValue("species.behavior.flee#patiencePerSecond", WildlifeFleeState.DEFAULT_ATTRIBUTES.patiencePerSecond),
		["moveSpeed"] = xmlFile:getValue("species.behavior.flee#moveSpeed", WildlifeFleeState.DEFAULT_ATTRIBUTES.moveSpeed)
	}
end
