WildlifeFleeState = {}
local WildlifeFleeState_mt = Class(WildlifeFleeState, BaseStateMachineState)
WildlifeFleeState.DEFAULT_ATTRIBUTES = { distance = 6, patienceLossPerMove = 45, patiencePerSecond = 5, moveSpeed = nil }
function WildlifeFleeState.registerXMLPaths(xmlSchema)
	xmlSchema:register(XMLValueType.FLOAT, "species.behavior.flee#distance", "The range at which the species will run from the player", WildlifeFleeState.DEFAULT_ATTRIBUTES.distance, false)
	xmlSchema:register(XMLValueType.FLOAT, "species.behavior.flee#patienceLossPerMove", "How many points of patience are lost every time this speies has to flee", WildlifeFleeState.DEFAULT_ATTRIBUTES.patienceLossPerMove, false)
	xmlSchema:register(XMLValueType.FLOAT, "species.behavior.flee#patiencePerSecond", "How many points of patience are restored per second", WildlifeFleeState.DEFAULT_ATTRIBUTES.patiencePerSecond, false)
	xmlSchema:register(XMLValueType.FLOAT, "species.behavior.flee#moveSpeed", "How fast the instance moves while fleeing", WildlifeFleeState.DEFAULT_ATTRIBUTES.moveSpeed, false)
end
function WildlifeFleeState.new(stateMachine)
	local self = BaseStateMachineState.new(stateMachine, WildlifeFleeState_mt)
	self.patience = 100
	self.fleeingToDespawn = false
	self.pendingTargetCheck = nil
	return self
end
function WildlifeFleeState:calculateIfShouldBeForced()
	return self:calculateIfShouldFlee()
end
function WildlifeFleeState:calculateIfShouldFlee()
	if self.stateMachine.currentState == self then
		return false
	else
		local playerX, playerZ = g_localPlayer:getMapPositionAndLookYaw()
		local distanceFromPlayer = self.stateMachine.instance:calculateDistanceFrom(playerX, playerZ)
		return distanceFromPlayer < self.stateMachine.instance.species.behaviourAttributes.flee.distance
	end
end
function WildlifeFleeState:replenishPatience(dt)
	if self.fleeingToDespawn then
		return
	else
		local patiencePerSecond = self.stateMachine.instance.species.behaviourAttributes.flee.patiencePerSecond
		self.patience = math.min(self.patience + patiencePerSecond * dt * 0.001, 100)
	end
end
function WildlifeFleeState:fleeFromPlayer(patienceLossMultiplier)
	if self.fleeingToDespawn then
		return
	else
		patienceLossMultiplier = patienceLossMultiplier or 1
		local patienceLossPerMove = self.stateMachine.instance.species.behaviourAttributes.flee.patienceLossPerMove
		self.patience = math.max(self.patience - patienceLossPerMove * patienceLossMultiplier, 0)
		local currentX, _, currentZ = self.stateMachine.instance:getCurrentPosition()
		local playerX, playerZ = g_localPlayer:getMapPositionAndLookYaw()
		local fleeDirectionX, fleeDirectionZ = MathUtil.vector2Normalize(currentX - playerX, currentZ - playerZ)
		self:fleeInDirection(fleeDirectionX, fleeDirectionZ)
	end
end
function WildlifeFleeState:fleeInDirection(fleeDirectionX, fleeDirectionZ)
	if self.fleeingToDespawn or self.pendingTargetCheck then
		return
	end
	if self.patience <= 0 then
		self:fleeToDespawn(fleeDirectionX, fleeDirectionZ)
	else
		local fleeDistance = self.stateMachine.instance.species.behaviourAttributes.flee.distance * (1 + math.random())
		local currentX, _, currentZ = self.stateMachine.instance:getCurrentPosition()
		local targetX = currentX + fleeDirectionX * fleeDistance
		local targetZ = currentZ + fleeDirectionZ * fleeDistance
		local targetY = getTerrainHeightAtWorldPos(g_terrainNode, targetX, 0, targetZ)
		self.pendingTargetCheck = true
		self.fleeDirectionX = fleeDirectionX
		self.fleeDirectionZ = fleeDirectionZ
		raycastClosestAsync(targetX, targetY + 100, targetZ, 0, -1, 0, 200, "onTargetCallback", self, WildlifeInstanceMover.COLLISION_MASK)
	end
end
function WildlifeFleeState:onTargetCallback(nodeId, x, y, z, distance, nx, ny, nz, subShapeIndex, shapeId, isLast)
	if self.pendingTargetCheck == nil then
		return
	end
	self.pendingTargetCheck = nil
	local adjustedTargetY = WildlifeInstanceMover.adjustRayHitForWater(nodeId, x, y, z, self.stateMachine.instance.species.movementAttributes)
	if adjustedTargetY == nil then
		self:fleeToDespawn(self.fleeDirectionX, self.fleeDirectionZ)
	else
		local moveSpeed = self.stateMachine.instance.species.behaviourAttributes.flee.moveSpeed
		self.stateMachine.instance.mover:flyOrMoveToTarget(x, adjustedTargetY, z, moveSpeed)
	end
end
function WildlifeFleeState:fleeToDespawn(fleeDirectionX, fleeDirectionZ, shouldTakeOff)
	self.fleeingToDespawn = true
	local fleeDistance = g_currentMission.mapWidth + g_currentMission.mapHeight
	local currentX, _, currentZ = self.stateMachine.instance:getCurrentPosition()
	local targetX = currentX + fleeDirectionX * fleeDistance
	local targetZ = currentZ + fleeDirectionZ * fleeDistance
	local terrainX = math.clamp(targetX, g_currentMission.mapWidth / -2, g_currentMission.mapWidth / 2)
	local terrainZ = math.clamp(targetZ, g_currentMission.mapHeight / -2, g_currentMission.mapHeight / 2)
	local targetY = getTerrainHeightAtWorldPos(g_terrainNode, terrainX, 0, terrainZ)
	if self.stateMachine.instance.species.movementAttributes.canFly then
		targetY = targetY + 50
	end
	local moveSpeed = self.stateMachine.instance.species.behaviourAttributes.flee.moveSpeed
	self.stateMachine.instance.mover:flyOrMoveToTarget(targetX, targetY, targetZ, moveSpeed, shouldTakeOff)
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
	if self.stateMachine.currentState ~= self then
		return
	elseif self:calculateIfShouldFlee() then
		self:fleeFromPlayer(2.5)
	else
		self.stateMachine:determineState()
	end
end
function WildlifeFleeState:updateAsCurrent(dt)
	self:replenishPatience(dt)
end
function WildlifeFleeState:updateAsInactive(dt)
	self:replenishPatience(dt)
end
function WildlifeFleeState.loadAttributesTable(xmlFile)
	local attributes = { ["distance"] = xmlFile:getValue("species.behavior.flee#distance", WildlifeFleeState.DEFAULT_ATTRIBUTES.distance), ["patienceLossPerMove"] = xmlFile:getValue("species.behavior.flee#patienceLossPerMove", WildlifeFleeState.DEFAULT_ATTRIBUTES.patienceLossPerMove), ["patiencePerSecond"] = xmlFile:getValue("species.behavior.flee#patiencePerSecond", WildlifeFleeState.DEFAULT_ATTRIBUTES.patiencePerSecond), ["moveSpeed"] = xmlFile:getValue("species.behavior.flee#moveSpeed", WildlifeFleeState.DEFAULT_ATTRIBUTES.moveSpeed) }
	return attributes
end
