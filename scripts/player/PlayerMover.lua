PlayerMover = {}
local PlayerMover_mt = Class(PlayerMover)
PlayerMover.GRAVITY = 9.81
PlayerMover.MAXIMUM_DOWNWARD_SPEED = PlayerMover.GRAVITY * -4
PlayerMover.MAXIMUM_UPWARD_SPEED = 35
PlayerMover.DECELERATION = 10
PlayerMover.ACCELERATION = PlayerMover.DECELERATION + 6
PlayerMover.ROTATION_SPEED = 10.471975511965978
PlayerMover.SMALL_SPEED_THRESHOLD = 0.005
PlayerMover.CLOSE_TO_GROUND_THRESHOLD = 1.4
PlayerMover.SWIM_SUBMERGE_THRESHOLD = 1.4
PlayerMover.SLOW_SUBMERGE_THRESHOLD = 0.4
PlayerMover.LADDER_CLIMB_SPEED = 4
PlayerMover.FLIGHT_MOVE_SPEED = 8
PlayerMover.FLIGHT_MOVE_SPEED_FAST = 100
PlayerMover.FLIGHT_HEIGHT_SPEED = 15
PlayerMover.FLIGHT_HEIGHT_SPEED_FAST = 45
function PlayerMover.new(player)
	local self = setmetatable({}, PlayerMover_mt)
	self.player = player
	self.isPhysicsEnabled = true
	self.currentForceX = 0
	self.currentForceY = 0
	self.currentForceZ = 0
	self.movementDirectionYaw = 0
	self.movementDirectionNode = nil
	self.currentSpeed = 0
	self.currentVelocityX = 0
	self.currentVelocityY = 0
	self.currentVelocityZ = 0
	self.positionDeltaX = 0
	self.positionDeltaY = 0
	self.positionDeltaZ = 0
	self.currentRotationVelocity = 0
	self.waterUnderfootY = 0
	self.currentWaterSubmergeDistance = 0
	self.groundUnderfootY = 0
	self.currentGroundDistance = 0
	self.isGrounded = true
	self.isCloseToGround = true
	self.isInWater = false
	self.isSwimming = false
	self.needSwimming = false
	self.isCrouching = false
	self.isOnLadder = false
	self.currentAirTime = 0
	self.currentFallTime = 0
	self.currentGroundTime = 0
	self.isFlightActive = false
	self.dirtyFlag = self.player:getNextDirtyFlag()
	self.onPositionTeleport = ListenerList.new()
	return self
end
function PlayerMover:initialise()
	self.movementDirectionNode = createTransformGroup("movementDirectionNode")
	link(getRootNode(), self.movementDirectionNode)
end
function PlayerMover:onPlayerLoad()
	if self.player.toggleFlightModeCommand ~= nil then
		self.player.toggleFlightModeCommand.onDisabled:registerListener(function()
			self:setFlightActive(false, true)
		end)
	end
end
function PlayerMover:delete()
	if self.movementDirectionNode ~= nil then
		delete(self.movementDirectionNode)
		self.movementDirectionNode = nil
	end
end
function PlayerMover.calculateWadeScalar(currentWaterSubmergeDistance)
	local adjustedStart = currentWaterSubmergeDistance - PlayerMover.SLOW_SUBMERGE_THRESHOLD
	local adjustedEnd = PlayerMover.SWIM_SUBMERGE_THRESHOLD - PlayerMover.SLOW_SUBMERGE_THRESHOLD
	return math.clamp(1 - adjustedStart / adjustedEnd, 0, 1)
end
function PlayerMover:calculateSmoothSpeed(moveScalar, doWading, minimumSpeed, maximumSpeed)
	if doWading then
		if moveScalar == 0 then
			return 0
		end
		if PlayerMover.SLOW_SUBMERGE_THRESHOLD < self.currentWaterSubmergeDistance then
			minimumSpeed = PlayerStateSwim.MAXIMUM_MOVE_SPEED
		end
		moveScalar = moveScalar * PlayerMover.calculateWadeScalar(self.currentWaterSubmergeDistance)
	end
	return MathUtil.lerp(minimumSpeed, maximumSpeed, moveScalar)
end
function PlayerMover:toggleFlightActive()
	self:setFlightActive(not self.isFlightActive)
end
function PlayerMover:setFlightActive(isFlightActive, isForced)
	if not (not isForced and (self.player.toggleFlightModeCommand == nil or self.player.toggleFlightModeCommand.value == false)) then
		self.isFlightActive = isFlightActive == true
	end
end
function PlayerMover:getIsPhysicsEnabled()
	return self.isPhysicsEnabled
end
function PlayerMover:enablePhysics()
	if self.isPhysicsEnabled then
		return
	else
		self.isPhysicsEnabled = true
	end
end
function PlayerMover:disablePhysics()
	if not self.isPhysicsEnabled then
		return
	else
		self.isPhysicsEnabled = false
	end
end
function PlayerMover:getForce()
	return self.currentForceX, self.currentForceY, self.currentForceZ
end
function PlayerMover:setForce(forceX, forceY, forceZ)
	self.currentForceX = forceX
	self.currentForceY = forceY
	self.currentForceZ = forceZ
end
function PlayerMover:getMovementYaw()
	return self.movementDirectionYaw
end
function PlayerMover:setMovementYaw(yaw)
	yaw = MathUtil.getValidLimit(yaw)
	self.movementDirectionYaw = yaw
	setWorldRotation(self.movementDirectionNode, 0, self.movementDirectionYaw, 0)
	if self.player.camera ~= nil and self.player.camera.isFirstPerson then
		local cameraPitch = self.player.camera:getRotation()
		self.player.camera:setRotation(cameraPitch, self.movementDirectionYaw, 0)
	end
end
function PlayerMover:rotateTowards(targetYaw, rotationSpeed, dt)
	local targetYawRotation = MathUtil.normalizeRotationForShortestPath(targetYaw, self.movementDirectionYaw)
	local maxDeltaYaw = (rotationSpeed or 9.42477796076938) * dt * 0.001
	if self.movementDirectionYaw < targetYawRotation then
		self.movementDirectionYaw = math.min(self.movementDirectionYaw + maxDeltaYaw, targetYawRotation)
	else
		self.movementDirectionYaw = math.max(self.movementDirectionYaw - maxDeltaYaw, targetYawRotation)
	end
	self.movementDirectionYaw = MathUtil.getValidLimit(self.movementDirectionYaw)
end
function PlayerMover:getSimulatedPosition()
	local positionX, positionY, positionZ = self:getPosition()
	return positionX + self.positionDeltaX, positionY + self.positionDeltaY, positionZ + self.positionDeltaZ
end
function PlayerMover:getPosition()
	return self.player.capsuleController:getPosition()
end
function PlayerMover:setPosition(x, y, z, setNodeTranslation)
	self.player.capsuleController:setPosition(x, y, z, setNodeTranslation)
	self.player:raiseDefaultDirtyFlag()
end
function PlayerMover:getAcceleration()
	return self.player.isOwner and self.player.toggleSuperSpeedCommand.value and PlayerMover.ACCELERATION * 8 or PlayerMover.ACCELERATION
end
function PlayerMover:getDeceleration()
	return self.player.isOwner and self.player.toggleSuperSpeedCommand.value and PlayerMover.DECELERATION * 8 or PlayerMover.DECELERATION
end
function PlayerMover:getSpeed()
	return self.currentSpeed
end
function PlayerMover:setSpeed(speed)
	self.player:raiseDefaultDirtyFlag()
	self.currentSpeed = speed
end
function PlayerMover:resetHorizontalVelocity()
	self.currentVelocityX = 0
	self.currentVelocityZ = 0
end
function PlayerMover:getVelocity()
	return self.currentVelocityX, self.currentVelocityY, self.currentVelocityZ
end
function PlayerMover:setIsCrouching(isCrouching)
	self.isCrouching = isCrouching
end
function PlayerMover:setIsOnLadder(isOnLadder)
	self.isOnLadder = isOnLadder
end
function PlayerMover:getLocalVelocity(velocityX, velocityZ, speed)
	speed = speed or self:getSpeed()
	if speed == 0 then
		return 0, 0
	else
		velocityX = velocityX or self.currentVelocityX
		velocityZ = velocityZ or self.currentVelocityZ
		local movementDirectionX = velocityX / speed
		local _ = 0
		local movementDirectionZ = velocityZ / speed
		movementDirectionX, _, movementDirectionZ = worldDirectionToLocal(self.movementDirectionNode, movementDirectionX, 0, movementDirectionZ)
		return movementDirectionX * speed, movementDirectionZ * speed
	end
end
function PlayerMover:setVelocity(velocityX, velocityY, velocityZ)
	self.player:raiseDefaultDirtyFlag()
	self.currentVelocityX = velocityX
	self.currentVelocityY = velocityY
	self.currentVelocityZ = velocityZ
end
function PlayerMover:getLocalMovementDirection(velocityX, velocityZ)
	if velocityX == 0 and velocityZ == 0 then
		return 0, 1
	end
	local movementDirectionX, _, movementDirectionZ = worldDirectionToLocal(self.movementDirectionNode, velocityX, 0, velocityZ)
	return MathUtil.vector2Normalize(movementDirectionX, movementDirectionZ)
end
function PlayerMover:teleportTo(x, y, z, setNodeTranslation, noEventSend)
	g_messageCenter:publish(MessageType.PLAYER_PRE_TELEPORT, self.player)
	if not noEventSend and (not self.player.isServer and self.player.isOwner) then
		g_client:getServerConnection():sendEvent(PlayerTeleportEvent.new(x, y, z, true, false))
	end
	self.lastPositionX, self.lastPositionY, self.lastPositionZ = self:getPosition()
	self:setPosition(x, y, z, setNodeTranslation)
	self.onPositionTeleport:invoke(x, y, z)
end
function PlayerMover:teleportToNPC(npc, noEventSend)
	local x, y, z = npc:getTeleportWorldPosition()
	local rotY = npc:getTeleportWorldRotation()
	self:teleportTo(x, y, z, true, noEventSend)
	self.player.graphicsComponent:setModelYaw(rotY)
	self:setMovementYaw(rotY)
end
function PlayerMover:teleportToSpawnPoint(noEventSend)
	local spawnPositionX, spawnPositionY, spawnPositionZ, spawnYaw = self.player:findSpawnPositionAndYaw()
	spawnPositionY = math.max(spawnPositionY, getTerrainHeightAtWorldPos(g_terrainNode, spawnPositionX, 0, spawnPositionZ) + 0.2)
	self:teleportTo(spawnPositionX, spawnPositionY, spawnPositionZ, true, noEventSend)
	self:setMovementYaw(spawnYaw)
end
function PlayerMover:teleportToExitPoint(vehicle, noEventSend)
	if vehicle ~= nil and vehicle.getExitNode ~= nil then
		local exitPoint = vehicle:getExitNode(self.player)
		local x, y, z = getWorldTranslation(exitPoint)
		local terrainHeight = getTerrainHeightAtWorldPos(g_terrainNode, x, 0, z)
		local raycastLength = 2
		local _, _, colY, _ = RaycastUtil.raycastClosest(x, terrainHeight + 2, z, 0, -1, 0, 2, CollisionFlag.STATIC_OBJECT + CollisionFlag.ROAD)
		colY = colY or terrainHeight
		y = math.max(colY + 0.1, y)
		y = math.max(y, vehicle.waterY)
		self:teleportTo(x, y, z, true, noEventSend)
		local exitDirectionX, _, exitDirectionZ = localDirectionToWorld(exitPoint, 0, 0, 1)
		local exitYaw = MathUtil.getYRotationFromDirection(exitDirectionX, exitDirectionZ)
		self.player.graphicsComponent:setModelYaw(exitYaw)
		self:setMovementYaw(exitYaw)
	end
end
function PlayerMover:moveHorizontally(currentForceX, currentForceZ)
	self.currentForceX = self.currentForceX + currentForceX
	self.currentForceZ = self.currentForceZ + currentForceZ
	self.player:raiseDefaultDirtyFlag()
end
function PlayerMover:moveVertically(currentForceY)
	self.currentForceY = self.currentForceY + currentForceY
	self.player:raiseDefaultDirtyFlag()
end
function PlayerMover:updateFloorDistance(dt, isGrounded, currentX, currentY, currentZ)
	if isGrounded ~= nil then
		self.isGrounded = isGrounded
	end
	if self.isGrounded then
		self.currentGroundDistance = 0
		self.groundUnderfootY = currentY
	else
		self.groundUnderfootY = nil
		raycastClosest(currentX, currentY + 10, currentZ, 0, -1, 0, 200, "onGroundRaycastCallback", self, CollisionFlag.TERRAIN + CollisionFlag.STATIC_OBJECT + CollisionFlag.ROAD)
		if self.groundUnderfootY ~= nil then
			self.currentGroundDistance = math.max(0, currentY - self.groundUnderfootY)
		else
			self.groundUnderfootY = 0
			self.currentGroundDistance = currentY
		end
	end
	self.isCloseToGround = self.isGrounded or self.currentGroundDistance <= self.CLOSE_TO_GROUND_THRESHOLD
	local _v18 = self.isGrounded and self.currentGroundTime + dt * 0.001 or 0
	self.currentGroundTime = _v18
	if self.isGrounded or self.isInWater then
		self.currentAirTime = _v18
		if self.currentAirTime == 0 or 0 <= self.currentVelocityY then
			self.currentFallTime = _v18
		end
	end
end
function PlayerMover:onGroundRaycastCallback(hitObjectId, x, y, z)
	if hitObjectId ~= 0 then
		self.groundUnderfootY = y
	end
end
function PlayerMover:updateWaterSubmergeDistance(currentX, currentY, currentZ)
	self.waterUnderfootY = nil
	self.updateWaterSubmergeDistanceCurrentY = currentY
	raycastClosestAsync(currentX, currentY + 3, currentZ, 0, -1, 0, 6, "onWaterRaycastCallback", self, CollisionFlag.WATER)
end
function PlayerMover:onWaterRaycastCallback(hitObjectId, x, y, z)
	if hitObjectId ~= 0 then
		self.waterUnderfootY = y
	end
	self.currentWaterSubmergeDistance = 0
	if self.waterUnderfootY ~= nil then
		self.currentWaterSubmergeDistance = math.max(0, self.waterUnderfootY - self.updateWaterSubmergeDistanceCurrentY)
	end
	self.isInWater = 0 < self.currentWaterSubmergeDistance
	self.needSwimming = PlayerMover.SWIM_SUBMERGE_THRESHOLD <= self.currentWaterSubmergeDistance
	self.isSwimming = PlayerMover.SWIM_SUBMERGE_THRESHOLD - 0.2 <= self.currentWaterSubmergeDistance
end
function PlayerMover:update(dt)
	local nextPositionX = nil
	local nextPositionY = nil
	local nextPositionZ = nil
	if self:getIsPhysicsEnabled() then
		self.positionDeltaX, self.positionDeltaY, self.positionDeltaZ = self:updateDeltas(dt)
		local currentPositionX, currentPositionY, currentPositionZ = self:getPosition()
		nextPositionX = currentPositionX + self.positionDeltaX
		nextPositionY = currentPositionY + self.positionDeltaY
		nextPositionZ = currentPositionZ + self.positionDeltaZ
		setWorldTranslation(self.movementDirectionNode, nextPositionX, nextPositionY, nextPositionZ)
		self.player.capsuleController:move(self.positionDeltaX, self.positionDeltaY, self.positionDeltaZ)
	end
	if nextPositionX == nil then
		nextPositionX, nextPositionY, nextPositionZ = self:getPosition()
	end
	local isGrounded = nil
	if self.player.isServer or self:getIsPhysicsEnabled() then
		isGrounded = self.player.capsuleController:calculateIfBottomTouchesGround()
	end
	self:updateWaterSubmergeDistance(nextPositionX, nextPositionY, nextPositionZ)
	self:updateFloorDistance(dt, isGrounded, nextPositionX, nextPositionY, nextPositionZ)
	if not self:getIsPhysicsEnabled() then
		return
	else
		local movementYaw = nil
		if self.player.isStrafeWalkMode then
			local _, yaw = self.player.camera:getRotation()
			movementYaw = yaw
		else
			local currentSpeed = self:getSpeed()
			movementYaw = currentSpeed <= 0 and self.movementDirectionYaw or MathUtil.getYRotationFromDirection(self.currentVelocityX / currentSpeed, self.currentVelocityZ / currentSpeed)
		end
		local oldDirectionYaw = self.movementDirectionYaw
		self:updateRotation(dt, movementYaw)
		self.currentRotationVelocity = MathUtil.getValidLimit(self.movementDirectionYaw - oldDirectionYaw) / (dt * 0.001)
	end
end
function PlayerMover:updateDeltas(dt)
	self:updateHorizontalVelocity(dt)
	self:updateVerticalVelocity(dt)
	self.currentForceX = 0
	self.currentForceY = 0
	self.currentForceZ = 0
	local positionDeltaX = self.currentVelocityX * dt * 0.001
	local positionDeltaY = self.currentVelocityY * dt * 0.001
	local positionDeltaZ = self.currentVelocityZ * dt * 0.001
	return positionDeltaX, positionDeltaY, positionDeltaZ
end
function PlayerMover:updateHorizontalVelocity(dt)
	if self.isFlightActive then
		local desiredSpeed = nil
		if 0 < self.player.inputComponent.runAxis then
			local moveScalar = self.player.inputComponent.runAxis * self.player.inputComponent.walkAxis
			desiredSpeed = self:calculateSmoothSpeed(moveScalar, false, PlayerMover.FLIGHT_MOVE_SPEED, PlayerMover.FLIGHT_MOVE_SPEED_FAST)
		else
			local moveScalar = self.player.inputComponent.walkAxis
			desiredSpeed = self:calculateSmoothSpeed(moveScalar, false, 0, PlayerMover.FLIGHT_MOVE_SPEED)
		end
		self.currentVelocityX = self.player.inputComponent.worldDirectionX * desiredSpeed
		self.currentVelocityZ = self.player.inputComponent.worldDirectionZ * desiredSpeed
		self.currentSpeed = desiredSpeed
	else
		if 0 < self.currentSpeed then
			local newSpeed = math.max(self.currentSpeed - self:getDeceleration() * dt * 0.001, 0)
			self.currentVelocityX = self.currentVelocityX / self.currentSpeed * newSpeed
			self.currentVelocityZ = self.currentVelocityZ / self.currentSpeed * newSpeed
			self.currentSpeed = newSpeed
		end
		local desiredSpeed = MathUtil.vector2Length(self.currentForceX, self.currentForceZ)
		if 0 < desiredSpeed and self.currentSpeed < desiredSpeed then
			local desiredDirectionX = self.currentForceX / desiredSpeed
			local desiredDirectionZ = self.currentForceZ / desiredSpeed
			local acceleration = self:getAcceleration()
			local movementAccelerationX = desiredDirectionX * acceleration * (dt * 0.001)
			local movementAccelerationZ = desiredDirectionZ * acceleration * (dt * 0.001)
			self.currentVelocityX = self.currentVelocityX + movementAccelerationX
			self.currentVelocityZ = self.currentVelocityZ + movementAccelerationZ
			self.currentSpeed = MathUtil.vector2Length(self.currentVelocityX, self.currentVelocityZ)
			if desiredSpeed < self.currentSpeed then
				self.currentVelocityX = self.currentVelocityX / self.currentSpeed * desiredSpeed
				self.currentVelocityZ = self.currentVelocityZ / self.currentSpeed * desiredSpeed
				self.currentSpeed = desiredSpeed
			end
		end
	end
end
function PlayerMover:updateVerticalVelocity(dt)
	if self.isGrounded and self.currentVelocityY < 0 then
		self.currentVelocityY = 0
	end
	if self.isFlightActive then
		local desiredSpeed = nil
		desiredSpeed = 0 < self.player.inputComponent.runAxis and PlayerMover.FLIGHT_HEIGHT_SPEED_FAST * self.player.inputComponent.runAxis * self.player.inputComponent.flightAxis or PlayerMover.FLIGHT_HEIGHT_SPEED * self.player.inputComponent.flightAxis
		self.currentVelocityY = desiredSpeed
	elseif self.isOnLadder then
		local desiredSpeed = PlayerMover.LADDER_CLIMB_SPEED * self.player.inputComponent.walkAxis
		self.currentVelocityY = desiredSpeed
	else
		if self.needSwimming and (self.player.toggleNoClipCommand == nil or not self.player.toggleNoClipCommand.value) then
			local overDepthAmount = math.max(self.currentWaterSubmergeDistance - PlayerMover.SWIM_SUBMERGE_THRESHOLD, 0)
			self.currentVelocityY = overDepthAmount
			return
		end
		self:moveVertically(-PlayerMover.GRAVITY)
		local movementAccelerationY = self.currentForceY * dt * 0.001
		self.currentVelocityY = math.clamp(self.currentVelocityY + movementAccelerationY, PlayerMover.MAXIMUM_DOWNWARD_SPEED, PlayerMover.MAXIMUM_UPWARD_SPEED)
	end
end
function PlayerMover:updateRotation(dt, movementYaw)
	if self.player.camera ~= nil and self.player.camera.isFirstPerson then
		local _, yaw = self.player.camera:getRotation()
		self.movementDirectionYaw = yaw
		setWorldRotation(self.movementDirectionNode, 0, self.movementDirectionYaw, 0)
		return
	end
	if self:getSpeed() <= 0 then
		setWorldRotation(self.movementDirectionNode, 0, self.movementDirectionYaw, 0)
	else
		local targetGraphicsYawRotation = MathUtil.normalizeRotationForShortestPath(movementYaw, self.movementDirectionYaw)
		local maxDeltaRotationY = PlayerMover.ROTATION_SPEED * dt * 0.001
		if self.movementDirectionYaw < targetGraphicsYawRotation then
			self.movementDirectionYaw = math.min(self.movementDirectionYaw + maxDeltaRotationY, targetGraphicsYawRotation)
		else
			self.movementDirectionYaw = math.max(self.movementDirectionYaw - maxDeltaRotationY, targetGraphicsYawRotation)
		end
		self.movementDirectionYaw = MathUtil.getValidLimit(self.movementDirectionYaw)
		setWorldRotation(self.movementDirectionNode, 0, self.movementDirectionYaw, 0)
	end
end
function PlayerMover:debugDraw(x, y, textSize)
	DebugUtil.drawDebugNode(self.movementDirectionNode, "MDIR", false, 0)
	y = DebugUtil.renderTextLine(x, y, textSize * 1.5, "Mover", nil, true)
	y = DebugUtil.renderTextLine(x, y, textSize, "Movement", nil, true)
	local positionX, positionY, positionZ = self:getPosition()
	y = DebugUtil.renderTextLine(x, y, textSize, string.format("Position: %.2f, %.2f, %.2f", positionX, positionY, positionZ))
	y = DebugUtil.renderTextLine(x, y, textSize, string.format("Velocity: %.2f, %.2f, %.2f", self.currentVelocityX, self.currentVelocityY, self.currentVelocityZ))
	y = DebugUtil.renderTextLine(x, y, textSize, string.format("Movement yaw: %.4f", self:getMovementYaw()))
	y = DebugUtil.renderTextLine(x, y, textSize, string.format("Rotation: %.4f", self.movementDirectionYaw))
	y = DebugUtil.renderTextLine(x, y, textSize, string.format("Rotation velocity: %.4f", self.currentRotationVelocity))
	y = DebugUtil.renderTextLine(x, y, textSize, string.format("Speed: %.4f", self.currentSpeed))
	y = DebugUtil.renderNewLine(y, textSize)
	y = DebugUtil.renderTextLine(x, y, textSize, "Ground/water", nil, true)
	y = DebugUtil.renderTextLine(x, y, textSize, string.format("Water level: %.4f", self.waterUnderfootY or 0))
	y = DebugUtil.renderTextLine(x, y, textSize, string.format("Submerge distance: %.4f", self.currentWaterSubmergeDistance))
	y = DebugUtil.renderTextLine(x, y, textSize, string.format("Swimming/in water: %s/%s", self.isSwimming, self.isInWater))
	y = DebugUtil.renderTextLine(x, y, textSize, string.format("Ground level: %.4f", self.groundUnderfootY or 0))
	y = DebugUtil.renderTextLine(x, y, textSize, string.format("Ground distance: %.4f", self.currentGroundDistance))
	y = DebugUtil.renderTextLine(x, y, textSize, string.format("Grounded: %s", self.isGrounded))
	y = DebugUtil.renderTextLine(x, y, textSize, string.format("Close to ground: %s", self.isCloseToGround))
	y = DebugUtil.renderTextLine(x, y, textSize, string.format("Fall/air/ground time: %.4f/%.4f/%.4f", self.currentFallTime, self.currentAirTime, self.currentGroundTime))
	return y
end
