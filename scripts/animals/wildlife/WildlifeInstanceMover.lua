WildlifeInstanceMover = {}
local WildlifeInstanceMover_mt = Class(WildlifeInstanceMover)
WildlifeInstanceMover.DEFAULT_ATTRIBUTES = { canFly = false, canSwim = false, walkSpeed = 1, flySpeed = nil, climbSpeed = 1, swimSpeed = nil, flyHeight = nil, canIdleInWater = false, wadeDepth = 0 }
WildlifeInstanceMover.COLLISION_MASK = CollisionFlag.TERRAIN + CollisionFlag.STATIC_OBJECT + CollisionFlag.WATER
WildlifeInstanceMover.MOVEMENT_HEIGHT_CHECK_INTERVAL = 2500
WildlifeInstanceMover.USE_HEIGHT_VERTICAL_DISTANCE = 2.2
WildlifeInstanceMover.TAKEOFF_LAND_HORIZONTAL_DISTANCE = 3.5
WildlifeInstanceMover.TAKEOFF_LAND_VERTICAL_DISTANCE = 2
WildlifeInstanceMover.MINIMUM_RUBBER_BAND = 0.2
WildlifeInstanceMover.MOVEMENT_SPEED_MULTIPLIER_VARIATION = 0.1
WildlifeInstanceMover.GLIDE_DURATION_RANGE = { minimum = 2, maximum = 6 }
WildlifeInstanceMover.FLAP_DURATION_RANGE = { minimum = 0.5, maximum = 1.5 }
WildlifeInstanceMover.MINIMUM_TARGET_DISTANCE = 0.1
function WildlifeInstanceMover.registerXMLPaths(xmlSchema)
	xmlSchema:register(XMLValueType.FLOAT, "species.movement#walkSpeed", "The average movement speed of the species on foot", WildlifeInstanceMover.DEFAULT_ATTRIBUTES.walkSpeed, false)
	xmlSchema:register(XMLValueType.FLOAT, "species.movement#flySpeed", "The average movement speed of the species in the air", WildlifeInstanceMover.DEFAULT_ATTRIBUTES.flySpeed, false)
	xmlSchema:register(XMLValueType.FLOAT, "species.movement#climbSpeed", "The average movement speed of the species flying upwards", WildlifeInstanceMover.DEFAULT_ATTRIBUTES.climbSpeed, false)
	xmlSchema:register(XMLValueType.FLOAT, "species.movement#swimSpeed", "The average movement speed of the species in the water", WildlifeInstanceMover.DEFAULT_ATTRIBUTES.swimSpeed, false)
	xmlSchema:register(XMLValueType.VECTOR_2, "species.movement#flyHeight", "The range of fly heights of the species in the air", WildlifeSpecies.formatRange(WildlifeInstanceMover.DEFAULT_ATTRIBUTES.flyHeight), false)
	xmlSchema:register(XMLValueType.BOOL, "species.movement#canIdleInWater", "Is true if this species can set a movement target in a body of water; otherwise false", WildlifeInstanceMover.DEFAULT_ATTRIBUTES.canIdleInWater, false)
	xmlSchema:register(XMLValueType.FLOAT, "species.movement#wadeDepth", "How far into water the instance can walk", WildlifeInstanceMover.DEFAULT_ATTRIBUTES.wadeDepth, false)
end
function WildlifeInstanceMover.new(instance)
	local self = setmetatable({}, WildlifeInstanceMover_mt)
	self.instance = instance
	self.currentAverageSpeed = WildlifeInstanceMover.DEFAULT_ATTRIBUTES.walkSpeed
	self.overiddenSpeed = nil
	self.isSwimming = false
	self.desiredHeight = 0
	self.groundReferenceHeight = 0
	self.heightCheckPending = nil
	self.timeOfLastHeightCheck = 0
	self.shouldTakeOff = true
	self.isFlapping = false
	self.flapGlideTimer = 0
	self.startX = nil
	self.startY = nil
	self.startZ = nil
	self.horizontalTotalDistance = nil
	self.targetX = nil
	self.targetY = nil
	self.targetZ = nil
	self.isFlyingToTarget = false
	self.horizontalMovedDistance = 0
	return self
end
function WildlifeInstanceMover:flyOrMoveToTarget(targetX, targetY, targetZ, moveSpeed, shouldTakeOff)
	if self.instance.species.movementAttributes.canFly then
		self:flyToTarget(targetX, targetY, targetZ, moveSpeed, shouldTakeOff)
	else
		self:moveToTarget(targetX, targetY, targetZ, moveSpeed)
	end
end
function WildlifeInstanceMover:flyToTarget(targetX, targetY, targetZ, moveSpeed, shouldTakeOff)
	if not self:checkIfTargetPositionValid(targetX, targetY, targetZ) then
		return false
	else
		self.overiddenSpeed = moveSpeed
		self:randomiseCurrentSpeed()
		self.targetX = targetX
		self.targetY = targetY
		self.targetZ = targetZ
		self.isFlyingToTarget = true
		self.shouldTakeOff = shouldTakeOff ~= nil and shouldTakeOff or true
		self:initialiseMovement()
		self.instance.sounds:playSound("flyAway")
		return true
	end
end
function WildlifeInstanceMover:moveToTarget(targetX, targetY, targetZ, moveSpeed)
	if not self:checkIfTargetPositionValid(targetX, targetY, targetZ) then
		return false
	else
		local _, currentY = self.instance:getCurrentPosition()
		if WildlifeInstanceMover.USE_HEIGHT_VERTICAL_DISTANCE <= math.abs(targetY - currentY) and self.instance.species.movementAttributes.canFly then
			return self:flyToTarget(targetX, targetY, targetZ, moveSpeed)
		end
		self.overiddenSpeed = moveSpeed
		self:randomiseCurrentSpeed()
		self.targetX = targetX
		self.targetY = targetY
		self.targetZ = targetZ
		self.isFlyingToTarget = false
		self:initialiseMovement()
		return true
	end
end
function WildlifeInstanceMover:initialiseMovement()
	self.startX, self.startY, self.startZ = self.instance:getCurrentPosition()
	self.horizontalTotalDistance = MathUtil.vector2Length(self.targetX - self.startX, self.targetZ - self.startZ)
	self.horizontalMovedDistance = 0
	self.isFlapping = false
	self.flapGlideTimer = MathUtil.randomFloat(WildlifeInstanceMover.GLIDE_DURATION_RANGE.minimum, WildlifeInstanceMover.GLIDE_DURATION_RANGE.maximum) * 1000
	self.heightCheckPending = nil
	self:randomiseDesiredHeight()
end
function WildlifeInstanceMover:getIsMoving()
	return self.targetX ~= nil and self.targetY ~= nil and self.targetZ ~= nil
end
function WildlifeInstanceMover:checkIfTargetPositionValid(targetX, targetY, targetZ)
	local currentX, _, currentZ = self.instance:getCurrentPosition()
	local distance = MathUtil.vector2Length(targetX - currentX, targetZ - currentZ)
	return WildlifeInstanceMover.MINIMUM_TARGET_DISTANCE <= distance
end
function WildlifeInstanceMover:cancelTarget()
	self.startX = nil
	self.startY = nil
	self.startZ = nil
	self.targetX = nil
	self.targetY = nil
	self.targetZ = nil
	self.horizontalTotalDistance = nil
	self.horizontalMovedDistance = 0
	self.shouldTakeOff = true
	self.isFlyingToTarget = false
	self.isFlapping = false
	self.flapGlideTimer = 0
	self.overiddenSpeed = nil
	self.heightCheckPending = nil
end
function WildlifeInstanceMover:update(dt)
	if not self:getIsMoving() then
		return
	else
		local previousX, previousY, previousZ = self.instance:getCurrentPosition()
		self.horizontalMovedDistance = MathUtil.vector2Length(self.startX - previousX, self.startZ - previousZ)
		self:tryRecalculateGroundReferenceAsync(previousX, previousY, previousZ)
		local interpolatedDesiredYLevel = self:calculateInterpolatedDesiredYLevel(previousX, previousY, previousZ, dt)
		local currentX, currentY, currentZ = self:calculateCurrentPosition(previousX, previousY, previousZ, dt, interpolatedDesiredYLevel)
		self:checkIfTargetReached(currentX, currentY, currentZ)
		self:updateNodeTransform(previousX, previousY, previousZ, currentX, currentY, currentZ, dt)
	end
end
function WildlifeInstanceMover:randomiseDesiredHeight()
	if self.isFlyingToTarget then
		local speciesFlyHeight = self.instance.species.movementAttributes.flyHeight
		local horizontalDistanceRequired = speciesFlyHeight.maximum / self.instance.species.movementAttributes.climbSpeed * self.currentAverageSpeed
		local minimumFlyHeight = speciesFlyHeight.minimum
		local maximumFlyHeight = speciesFlyHeight.maximum
		if self.horizontalTotalDistance / 3 < horizontalDistanceRequired then
			maximumFlyHeight = self.horizontalTotalDistance / 3 / self.currentAverageSpeed * self.instance.species.movementAttributes.climbSpeed
			minimumFlyHeight = math.min(minimumFlyHeight, maximumFlyHeight)
		end
		self.desiredHeight = MathUtil.randomFloat(minimumFlyHeight, maximumFlyHeight)
	else
		self.desiredHeight = 0
	end
end
function WildlifeInstanceMover:randomiseCurrentSpeed()
	self.currentAverageSpeed = self.overiddenSpeed
	if self.currentAverageSpeed ~= nil then
		return
	else
		if self.isFlyingToTarget then
			self.currentAverageSpeed = self.instance.species.movementAttributes.flySpeed
		elseif self.isSwimming then
			if self.instance.species.movementAttributes.canSwim then
				self.currentAverageSpeed = self.instance.species.movementAttributes.swimSpeed
			else
				self.currentAverageSpeed = self.instance.species.movementAttributes.walkSpeed
			end
		end
		local randomMultiplier = MathUtil.randomFloat(1 - WildlifeInstanceMover.MOVEMENT_SPEED_MULTIPLIER_VARIATION, 1 + WildlifeInstanceMover.MOVEMENT_SPEED_MULTIPLIER_VARIATION)
		self.currentAverageSpeed = self.currentAverageSpeed * randomMultiplier
	end
end
function WildlifeInstanceMover:tryRecalculateGroundReferenceAsync(previousX, previousY, previousZ)
	local horizontalTargetDistance = self.horizontalTotalDistance - self.horizontalMovedDistance
	if not self.isFlyingToTarget and horizontalTargetDistance <= 0.1 then
		self.groundReferenceHeight = self.targetY
		return
	end
	local timeSinceLastHeightCheck = g_time - self.timeOfLastHeightCheck
	if not self.heightCheckPending and timeSinceLastHeightCheck >= WildlifeInstanceMover.MOVEMENT_HEIGHT_CHECK_INTERVAL then
		self.heightCheckPending = true
		raycastClosestAsync(previousX, previousY + 100, previousZ, 0, -1, 0, 200, "recalculateGroundReference", self, WildlifeInstanceMover.COLLISION_MASK)
	end
end
function WildlifeInstanceMover:recalculateGroundReference(nodeId, x, y, z, distance, nx, ny, nz, subShapeIndex, shapeId, isLast)
	if self.heightCheckPending == nil then
		return
	end
	self.heightCheckPending = nil
	local adjustedHeight, requiresSwimming = WildlifeInstanceMover.adjustRayHitForWater(nodeId, x, y, z, self.instance.species.movementAttributes, false)
	self.isSwimming = requiresSwimming
	if adjustedHeight == nil then
		return
	else
		self.groundReferenceHeight = adjustedHeight
		self:randomiseCurrentSpeed()
		self.timeOfLastHeightCheck = g_time
	end
end
function WildlifeInstanceMover.adjustRayHitForWater(transformId, hitX, hitY, hitZ, movementAttributes, willIdle)
	if transformId == nil or transformId == 0 then
		return nil, false
	end
	local transformCollisionMask = getCollisionFilterMask(transformId)
	local isWater = bit32.band(transformCollisionMask, CollisionFlag.WATER) ~= 0
	if not isWater then
		return hitY, false
	end
	local terrainY = getTerrainHeightAtWorldPos(g_terrainNode, hitX, 0, hitZ)
	local waterDepth = math.max(hitY - terrainY, 0)
	local tooDeepToWade = movementAttributes.wadeDepth < waterDepth
	if tooDeepToWade and not movementAttributes.canSwim then
		return nil, true
	end
	if tooDeepToWade then
		if willIdle and not movementAttributes.canIdleInWater then
			return nil, true
		end
		return hitY, true
	else
		return terrainY, false
	end
end
function WildlifeInstanceMover:calculateInterpolatedDesiredYLevel(previousX, previousY, previousZ)
	if not self.isFlyingToTarget and not self.isSwimming then
		return self.groundReferenceHeight
	end
	local horizontalDistanceRequired = self.desiredHeight / self.instance.species.movementAttributes.climbSpeed * self.currentAverageSpeed
	horizontalDistanceRequired = math.min(horizontalDistanceRequired, self.horizontalTotalDistance / 2)
	if self.shouldTakeOff and self.horizontalMovedDistance <= horizontalDistanceRequired then
		local takeoffScalar = MathUtil.inverseLerp(0, horizontalDistanceRequired, self.horizontalMovedDistance)
		takeoffScalar = 1 - (1 - takeoffScalar) ^ 4
		return self.targetY + self.desiredHeight * takeoffScalar
	end
	if self.horizontalTotalDistance - self.horizontalMovedDistance < horizontalDistanceRequired then
		local landingScalar = (1 - MathUtil.inverseLerp(self.horizontalTotalDistance - horizontalDistanceRequired, self.horizontalTotalDistance, self.horizontalMovedDistance)) ^ 4
		local newHeight = self.desiredHeight * landingScalar
		if math.abs(self.groundReferenceHeight + newHeight - self.targetY) <= 0.1 then
			return self.targetY
		else
			return self.targetY + newHeight
		end
	end
	return self.groundReferenceHeight + self.desiredHeight
end
function WildlifeInstanceMover:calculateCurrentPosition(previousX, previousY, previousZ, dt, desiredYLevel)
	local horizontalMoveDelta = self.currentAverageSpeed * dt * 0.001
	local verticalMoveDelta = self.instance.species.movementAttributes.climbSpeed * dt * 0.001
	local horizontalTargetDistance = self.horizontalTotalDistance - self.horizontalMovedDistance
	if self.isFlyingToTarget then
		local verticalDesiredHeightDistance = math.abs(desiredYLevel - previousY)
		local horizontalRubberBand = math.clamp(horizontalTargetDistance / WildlifeInstanceMover.TAKEOFF_LAND_HORIZONTAL_DISTANCE, WildlifeInstanceMover.MINIMUM_RUBBER_BAND, 1)
		local verticalRubberBand = math.clamp(verticalDesiredHeightDistance / WildlifeInstanceMover.TAKEOFF_LAND_VERTICAL_DISTANCE, WildlifeInstanceMover.MINIMUM_RUBBER_BAND, 1)
		horizontalMoveDelta = horizontalMoveDelta * horizontalRubberBand
		verticalMoveDelta = verticalMoveDelta * verticalRubberBand
	end
	local currentX = nil
	local currentY = nil
	local currentZ = nil
	if horizontalTargetDistance <= horizontalMoveDelta then
		currentX = self.targetX
		currentZ = self.targetZ
	else
		local directionX, directionZ = MathUtil.vector2Normalize(self.targetX - previousX, self.targetZ - previousZ)
		currentX = previousX + horizontalMoveDelta * directionX
		currentZ = previousZ + horizontalMoveDelta * directionZ
	end
	if currentX == self.targetX and (currentZ == self.targetZ and 0.3 <= math.abs(self.targetY - previousY)) then
		verticalMoveDelta = verticalMoveDelta * MathUtil.randomFloat(1.5, 2.5)
	end
	if self.isFlyingToTarget then
		if math.abs(desiredYLevel - previousY) <= verticalMoveDelta then
			currentY = desiredYLevel
			return currentX, currentY, currentZ
		else
			currentY = previousY + math.sign(desiredYLevel - previousY) * verticalMoveDelta
			return currentX, currentY, currentZ
		end
	end
	currentY = desiredYLevel
	return currentX, currentY, currentZ
end
function WildlifeInstanceMover:checkIfTargetReached(currentX, currentY, currentZ)
	local reachedTarget = currentX == self.targetX and currentY == self.targetY and currentZ == self.targetZ
	if reachedTarget then
		self:cancelTarget()
		self.instance.stateMachine:onMovementTargetReached()
	end
	return reachedTarget
end
function WildlifeInstanceMover:updateNodeTransform(previousX, previousY, previousZ, currentX, currentY, currentZ, dt)
	setTranslation(self.instance.rootNode, currentX, currentY, currentZ)
	local horizontalMovedDelta = MathUtil.vector2Length(currentX - previousX, currentZ - previousZ)
	local verticalMovedDelta = currentY - previousY
	local movementDirectionX = nil
	local movementDirectionZ = nil
	if horizontalMovedDelta <= 0.001 then
		movementDirectionX = 0
		movementDirectionZ = 0
	else
		movementDirectionX = (currentX - previousX) / horizontalMovedDelta
		movementDirectionZ = (currentZ - previousZ) / horizontalMovedDelta
		setDirection(self.instance.rootNode, movementDirectionX, 0, movementDirectionZ, 0, 1, 0)
	end
	self:updateAnimations(horizontalMovedDelta, verticalMovedDelta, currentX, currentY, currentZ, dt)
end
function WildlifeInstanceMover:updateAnimations(horizontalMovedDelta, verticalMovedDelta, currentX, currentY, currentZ, dt)
	if not self.isFlyingToTarget then
		if self.isSwimming and self.instance.graphics:getHasStateAnimation("swim") then
			self.instance.graphics:transitionToAnimation("swim")
			return
		end
		self.instance.graphics:transitionToAnimation("idleWalk")
		return
	end
	local minimumVerticalMoveDelta = self.instance.species.movementAttributes.climbSpeed * WildlifeInstanceMover.MINIMUM_RUBBER_BAND * 0.7 * dt * 0.001
	if minimumVerticalMoveDelta <= math.abs(verticalMovedDelta) then
		self:updateVerticalAnimations(verticalMovedDelta, currentX, currentY, currentZ, dt)
	elseif self:checkFlapDuration(dt) then
		self.instance.graphics:transitionToAnimation("fly")
	else
		self.instance.graphics:transitionToAnimation("flyGlide")
	end
end
function WildlifeInstanceMover:updateVerticalAnimations(verticalMovedDelta, currentX, currentY, currentZ, dt)
	local horizontalTargetDistance = self.horizontalTotalDistance - self.horizontalMovedDistance
	local targetYDistance = math.abs(currentY - self.targetY)
	local isTakingOff = false
	if self.horizontalMovedDistance <= WildlifeInstanceMover.TAKEOFF_LAND_HORIZONTAL_DISTANCE then
		isTakingOff = 0 < verticalMovedDelta
	end
	if isTakingOff then
		self.instance.graphics:transitionToAnimation("takeOff")
		return
	end
	local isLanding = horizontalTargetDistance <= WildlifeInstanceMover.TAKEOFF_LAND_HORIZONTAL_DISTANCE and targetYDistance <= WildlifeInstanceMover.TAKEOFF_LAND_VERTICAL_DISTANCE and verticalMovedDelta < 0
	if isLanding then
		self.instance.graphics:transitionToAnimation("land")
	elseif verticalMovedDelta < 0 then
		if self:checkFlapDuration(dt) or currentX == self.targetX and currentZ == self.targetZ then
			self.instance.graphics:transitionToAnimation("flyDownFlapping")
			return
		end
		self.instance.graphics:transitionToAnimation("flyDown")
	else
		self.instance.graphics:transitionToAnimation("flyUp")
	end
end
function WildlifeInstanceMover:checkFlapDuration(dt)
	self.flapGlideTimer = self.flapGlideTimer - dt
	if 0 < self.flapGlideTimer then
		return self.isFlapping
	else
		self.isFlapping = not self.isFlapping
		if self.isFlapping then
			self.flapGlideTimer = MathUtil.randomFloat(WildlifeInstanceMover.FLAP_DURATION_RANGE.minimum, WildlifeInstanceMover.FLAP_DURATION_RANGE.maximum) * 1000
		else
			self.flapGlideTimer = MathUtil.randomFloat(WildlifeInstanceMover.GLIDE_DURATION_RANGE.minimum, WildlifeInstanceMover.GLIDE_DURATION_RANGE.maximum) * 1000
		end
		return self.isFlapping
	end
end
function WildlifeInstanceMover:debugDraw()
	if not self:getIsMoving() then
		return
	else
		DebugGizmo.renderAtPosition(self.targetX, self.targetY, self.targetZ, 0, 0, 1, 0, 1, 0, "Target", false, 1, nil, Color.PRESETS.RED)
		if self.isFlyingToTarget then
			local previousX, previousY, previousZ = self.instance:getCurrentPosition()
			local interpolatedYLevel = self:calculateInterpolatedDesiredYLevel(previousX, previousY, previousZ)
			DebugGizmo.renderAtPosition(self.targetX, self.groundReferenceHeight + self.desiredHeight, self.targetZ, 0, 0, 1, 0, 1, 0, "Fly height", false, 1, nil, Color.PRESETS.GREEN)
			DebugGizmo.renderAtPosition(self.targetX, interpolatedYLevel, self.targetZ, 0, 0, 1, 0, 1, 0, "Desired height", false, 1, nil, Color.PRESETS.BLUE)
		end
	end
end
function WildlifeInstanceMover.loadAttributesTable(xmlFile)
	local attributes = {}
	attributes.walkSpeed = xmlFile:getValue("species.movement#walkSpeed", WildlifeInstanceMover.DEFAULT_ATTRIBUTES.walkSpeed)
	attributes.flySpeed = xmlFile:getValue("species.movement#flySpeed", WildlifeInstanceMover.DEFAULT_ATTRIBUTES.flySpeed)
	attributes.climbSpeed = xmlFile:getValue("species.movement#climbSpeed", WildlifeInstanceMover.DEFAULT_ATTRIBUTES.climbSpeed)
	attributes.swimSpeed = xmlFile:getValue("species.movement#swimSpeed", WildlifeInstanceMover.DEFAULT_ATTRIBUTES.swimSpeed)
	attributes.canFly = attributes.flySpeed ~= nil
	attributes.canSwim = attributes.swimSpeed ~= nil
	local flyHeight = xmlFile:getValue("species.movement#flyHeight", nil, true)
	if attributes.canFly and flyHeight ~= nil then
		attributes.flyHeight = { minimum = flyHeight[1], maximum = flyHeight[2] }
	end
	attributes.canIdleInWater = attributes.canSwim and xmlFile:getValue("species.movement#canIdleInWater", WildlifeInstanceMover.DEFAULT_ATTRIBUTES.canIdleInWater)
	attributes.wadeDepth = xmlFile:getValue("species.movement#wadeDepth", WildlifeInstanceMover.DEFAULT_ATTRIBUTES.wadeDepth)
	return attributes
end
