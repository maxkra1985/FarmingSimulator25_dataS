-- Local values: PlayerMover_mt
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

-- Upvalues: PlayerMover_mt
-- Local values: self
function PlayerMover.new(player)
	-- upvalues: (copy) PlayerMover_mt
	local v3_ = PlayerMover_mt
	local v4_ = setmetatable({}, v3_)
	v4_.player = player
	v4_.isPhysicsEnabled = true
	v4_.currentForceX = 0
	v4_.currentForceY = 0
	v4_.currentForceZ = 0
	v4_.movementDirectionYaw = 0
	v4_.movementDirectionNode = nil
	v4_.currentSpeed = 0
	v4_.currentVelocityX = 0
	v4_.currentVelocityY = 0
	v4_.currentVelocityZ = 0
	v4_.positionDeltaX = 0
	v4_.positionDeltaY = 0
	v4_.positionDeltaZ = 0
	v4_.currentRotationVelocity = 0
	v4_.waterUnderfootY = 0
	v4_.currentWaterSubmergeDistance = 0
	v4_.groundUnderfootY = 0
	v4_.currentGroundDistance = 0
	v4_.isGrounded = true
	v4_.isCloseToGround = true
	v4_.isInWater = false
	v4_.isSwimming = false
	v4_.needSwimming = false
	v4_.isCrouching = false
	v4_.isOnLadder = false
	v4_.currentAirTime = 0
	v4_.currentFallTime = 0
	v4_.currentGroundTime = 0
	v4_.isFlightActive = false
	v4_.dirtyFlag = v4_.player:getNextDirtyFlag()
	v4_.onPositionTeleport = ListenerList.new()
	return v4_
end

function PlayerMover:initialise()
	self.movementDirectionNode = createTransformGroup("movementDirectionNode")
	link(getRootNode(), self.movementDirectionNode)
end

function PlayerMover:onPlayerLoad()
	if self.player.toggleFlightModeCommand ~= nil then
		self.player.toggleFlightModeCommand.onDisabled:registerListener(function()
			-- upvalues: (copy) self
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

-- Local values: adjustedStart, adjustedEnd
function PlayerMover.calculateWadeScalar(currentWaterSubmergeDistance)
	local v9_ = 1 - (currentWaterSubmergeDistance - PlayerMover.SLOW_SUBMERGE_THRESHOLD) / (PlayerMover.SWIM_SUBMERGE_THRESHOLD - PlayerMover.SLOW_SUBMERGE_THRESHOLD)
	return math.clamp(v9_, 0, 1)
end

function PlayerMover:calculateSmoothSpeed(moveScalar, doWading, minimumSpeed, maximumSpeed)
	if doWading then
		if moveScalar == 0 then
			return 0
		end
		if self.currentWaterSubmergeDistance > PlayerMover.SLOW_SUBMERGE_THRESHOLD then
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
	if isForced or self.player.toggleFlightModeCommand ~= nil and self.player.toggleFlightModeCommand.value ~= false then
		self.isFlightActive = isFlightActive == true
	end
end

function PlayerMover:getIsPhysicsEnabled()
	return self.isPhysicsEnabled
end

function PlayerMover:enablePhysics()
	if not self.isPhysicsEnabled then
		self.isPhysicsEnabled = true
	end
end

function PlayerMover:disablePhysics()
	if self.isPhysicsEnabled then
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

-- Local values: cameraPitch
function PlayerMover:setMovementYaw(yaw)
	self.movementDirectionYaw = MathUtil.getValidLimit(yaw)
	setWorldRotation(self.movementDirectionNode, 0, self.movementDirectionYaw, 0)
	if self.player.camera ~= nil and self.player.camera.isFirstPerson then
		local v30_ = self.player.camera:getRotation()
		self.player.camera:setRotation(v30_, self.movementDirectionYaw, 0)
	end
end

-- Local values: targetYawRotation, maxDeltaYaw
function PlayerMover:rotateTowards(targetYaw, rotationSpeed, dt)
	local v35_ = MathUtil.normalizeRotationForShortestPath(targetYaw, self.movementDirectionYaw)
	local v36_ = (rotationSpeed or 9.42477796076938) * dt * 0.001
	if self.movementDirectionYaw < v35_ then
		local v37_ = self.movementDirectionYaw + v36_
		self.movementDirectionYaw = math.min(v37_, v35_)
	else
		local v38_ = self.movementDirectionYaw - v36_
		self.movementDirectionYaw = math.max(v38_, v35_)
	end
	self.movementDirectionYaw = MathUtil.getValidLimit(self.movementDirectionYaw)
end

-- Local values: positionX, positionY, positionZ
function PlayerMover:getSimulatedPosition()
	local v40_, v41_, v42_ = self:getPosition()
	return v40_ + self.positionDeltaX, v41_ + self.positionDeltaY, v42_ + self.positionDeltaZ
end

function PlayerMover:getPosition()
	return self.player.capsuleController:getPosition()
end

function PlayerMover:setPosition(x, y, z, setNodeTranslation)
	self.player.capsuleController:setPosition(x, y, z, setNodeTranslation)
	self.player:raiseDefaultDirtyFlag()
end

function PlayerMover:getAcceleration()
	return self.player.isOwner and (self.player.toggleSuperSpeedCommand.value and PlayerMover.ACCELERATION * 8) or PlayerMover.ACCELERATION
end

function PlayerMover:getDeceleration()
	return self.player.isOwner and (self.player.toggleSuperSpeedCommand.value and PlayerMover.DECELERATION * 8) or PlayerMover.DECELERATION
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

-- Local values: movementDirectionX, _, movementDirectionZ
function PlayerMover:getLocalVelocity(velocityX, velocityZ, speed)
	local v64_ = speed or self:getSpeed()
	if v64_ == 0 then
		return 0, 0
	end
	local v65_ = velocityX or self.currentVelocityX
	local v66_ = velocityZ or self.currentVelocityZ
	local v67_ = v65_ / v64_
	local v68_ = v66_ / v64_
	local v69_, _, v70_ = worldDirectionToLocal(self.movementDirectionNode, v67_, 0, v68_)
	return v69_ * v64_, v70_ * v64_
end

function PlayerMover:setVelocity(velocityX, velocityY, velocityZ)
	self.player:raiseDefaultDirtyFlag()
	self.currentVelocityX = velocityX
	self.currentVelocityY = velocityY
	self.currentVelocityZ = velocityZ
end

-- Local values: movementDirectionX, _, movementDirectionZ
function PlayerMover:getLocalMovementDirection(velocityX, velocityZ)
	if velocityX == 0 and velocityZ == 0 then
		return 0, 1
	end
	local v78_, _, v79_ = worldDirectionToLocal(self.movementDirectionNode, velocityX, 0, velocityZ)
	return MathUtil.vector2Normalize(v78_, v79_)
end

function PlayerMover:teleportTo(x, y, z, setNodeTranslation, noEventSend)
	g_messageCenter:publish(MessageType.PLAYER_PRE_TELEPORT, self.player)
	if not noEventSend and (not self.player.isServer and self.player.isOwner) then
		g_client:getServerConnection():sendEvent(PlayerTeleportEvent.new(x, y, z, true, false))
	end
	local v86_, v87_, v88_ = self:getPosition()
	self.lastPositionX = v86_
	self.lastPositionY = v87_
	self.lastPositionZ = v88_
	self:setPosition(x, y, z, setNodeTranslation)
	self.onPositionTeleport:invoke(x, y, z)
end

-- Local values: x, y, z, rotY
function PlayerMover:teleportToNPC(npc, noEventSend)
	local v92_, v93_, v94_ = npc:getTeleportWorldPosition()
	local v95_ = npc:getTeleportWorldRotation()
	self:teleportTo(v92_, v93_, v94_, true, noEventSend)
	self.player.graphicsComponent:setModelYaw(v95_)
	self:setMovementYaw(v95_)
end

-- Local values: spawnPositionX, spawnPositionY, spawnPositionZ, spawnYaw
function PlayerMover:teleportToSpawnPoint(noEventSend)
	local v98_, v99_, v100_, v101_ = self.player:findSpawnPositionAndYaw()
	local v102_ = getTerrainHeightAtWorldPos(g_terrainNode, v98_, 0, v100_) + 0.2
	self:teleportTo(v98_, math.max(v99_, v102_), v100_, true, noEventSend)
	self:setMovementYaw(v101_)
end

-- Local values: exitPoint, x, y, z, terrainHeight, raycastLength, _, _, colY, _, exitDirectionX, _, exitDirectionZ, exitYaw
function PlayerMover:teleportToExitPoint(vehicle, noEventSend)
	if vehicle ~= nil and vehicle.getExitNode ~= nil then
		local v106_ = vehicle:getExitNode(self.player)
		local v107_, v108_, v109_ = getWorldTranslation(v106_)
		local v110_ = getTerrainHeightAtWorldPos(g_terrainNode, v107_, 0, v109_)
		local _, _, v111_, _ = RaycastUtil.raycastClosest(v107_, v110_ + 2, v109_, 0, -1, 0, 2, CollisionFlag.STATIC_OBJECT + CollisionFlag.ROAD)
		local v112_ = (v111_ or v110_) + 0.1
		local v113_ = math.max(v112_, v108_)
		local v114_ = vehicle.waterY
		self:teleportTo(v107_, math.max(v113_, v114_), v109_, true, noEventSend)
		local v115_, _, v116_ = localDirectionToWorld(v106_, 0, 0, 1)
		local v117_ = MathUtil.getYRotationFromDirection(v115_, v116_)
		self.player.graphicsComponent:setModelYaw(v117_)
		self:setMovementYaw(v117_)
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
		if self.groundUnderfootY == nil then
			self.groundUnderfootY = 0
			self.currentGroundDistance = currentY
		else
			local v129_ = currentY - self.groundUnderfootY
			self.currentGroundDistance = math.max(0, v129_)
		end
	end
	self.isCloseToGround = self.isGrounded or self.currentGroundDistance <= self.CLOSE_TO_GROUND_THRESHOLD
	self.currentGroundTime = self.isGrounded and (self.currentGroundTime + dt * 0.001 or 0) or 0
	self.currentAirTime = (self.isGrounded or self.isInWater) and 0 or self.currentAirTime + dt * 0.001
	self.currentFallTime = (self.currentAirTime == 0 or self.currentVelocityY >= 0) and 0 or self.currentFallTime + dt * 0.001
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
		local v140_ = self.waterUnderfootY - self.updateWaterSubmergeDistanceCurrentY
		self.currentWaterSubmergeDistance = math.max(0, v140_)
	end
	self.isInWater = self.currentWaterSubmergeDistance > 0
	self.needSwimming = self.currentWaterSubmergeDistance >= PlayerMover.SWIM_SUBMERGE_THRESHOLD
	self.isSwimming = self.currentWaterSubmergeDistance >= PlayerMover.SWIM_SUBMERGE_THRESHOLD - 0.2
end

-- Local values: nextPositionX, nextPositionY, nextPositionZ, currentPositionX, currentPositionY, currentPositionZ, isGrounded, movementYaw, _, yaw, currentSpeed, oldDirectionYaw
function PlayerMover:update(dt)
	local v143_, v144_, v145_
	if self:getIsPhysicsEnabled() then
		local v146_, v147_, v148_ = self:updateDeltas(dt)
		self.positionDeltaX = v146_
		self.positionDeltaY = v147_
		self.positionDeltaZ = v148_
		local v149_, v150_, v151_ = self:getPosition()
		v143_ = v149_ + self.positionDeltaX
		v144_ = v150_ + self.positionDeltaY
		v145_ = v151_ + self.positionDeltaZ
		setWorldTranslation(self.movementDirectionNode, v143_, v144_, v145_)
		self.player.capsuleController:move(self.positionDeltaX, self.positionDeltaY, self.positionDeltaZ)
	else
		v143_ = nil
		v144_ = nil
		v145_ = nil
	end
	if v143_ == nil then
		v143_, v144_, v145_ = self:getPosition()
	end
	local v152_
	if self.player.isServer or self:getIsPhysicsEnabled() then
		v152_ = self.player.capsuleController:calculateIfBottomTouchesGround()
	else
		v152_ = nil
	end
	self:updateWaterSubmergeDistance(v143_, v144_, v145_)
	self:updateFloorDistance(dt, v152_, v143_, v144_, v145_)
	if self:getIsPhysicsEnabled() then
		local v153_
		if self.player.isStrafeWalkMode then
			local v154_
			v154_, v153_ = self.player.camera:getRotation()
		else
			local v155_ = self:getSpeed()
			v153_ = v155_ <= 0 and self.movementDirectionYaw or MathUtil.getYRotationFromDirection(self.currentVelocityX / v155_, self.currentVelocityZ / v155_)
		end
		local v156_ = self.movementDirectionYaw
		self:updateRotation(dt, v153_)
		self.currentRotationVelocity = MathUtil.getValidLimit(self.movementDirectionYaw - v156_) / (dt * 0.001)
	end
end

-- Local values: positionDeltaX, positionDeltaY, positionDeltaZ
function PlayerMover:updateDeltas(dt)
	self:updateHorizontalVelocity(dt)
	self:updateVerticalVelocity(dt)
	self.currentForceX = 0
	self.currentForceY = 0
	self.currentForceZ = 0
	return self.currentVelocityX * dt * 0.001, self.currentVelocityY * dt * 0.001, self.currentVelocityZ * dt * 0.001
end

-- Local values: desiredSpeed, moveScalar, moveScalar, newSpeed, desiredSpeed, desiredDirectionX, desiredDirectionZ, acceleration, movementAccelerationX, movementAccelerationZ
function PlayerMover:updateHorizontalVelocity(dt)
	if self.isFlightActive then
		local v161_
		if self.player.inputComponent.runAxis > 0 then
			v161_ = self:calculateSmoothSpeed(self.player.inputComponent.runAxis * self.player.inputComponent.walkAxis, false, PlayerMover.FLIGHT_MOVE_SPEED, PlayerMover.FLIGHT_MOVE_SPEED_FAST)
		else
			v161_ = self:calculateSmoothSpeed(self.player.inputComponent.walkAxis, false, 0, PlayerMover.FLIGHT_MOVE_SPEED)
		end
		local v162_ = self.player.inputComponent.worldDirectionX * v161_
		local v163_ = self.player.inputComponent.worldDirectionZ * v161_
		self.currentVelocityX = v162_
		self.currentVelocityZ = v163_
		self.currentSpeed = v161_
	else
		if self.currentSpeed > 0 then
			local v164_ = self.currentSpeed - self:getDeceleration() * dt * 0.001
			local v165_ = math.max(v164_, 0)
			local v166_ = self.currentVelocityX / self.currentSpeed * v165_
			local v167_ = self.currentVelocityZ / self.currentSpeed * v165_
			self.currentVelocityX = v166_
			self.currentVelocityZ = v167_
			self.currentSpeed = v165_
		end
		local v168_ = MathUtil.vector2Length(self.currentForceX, self.currentForceZ)
		if v168_ > 0 and self.currentSpeed < v168_ then
			local v169_ = self.currentForceX / v168_
			local v170_ = self.currentForceZ / v168_
			local v171_ = self:getAcceleration()
			local v172_ = v169_ * v171_ * (dt * 0.001)
			local v173_ = v170_ * v171_ * (dt * 0.001)
			local v174_ = self.currentVelocityX + v172_
			local v175_ = self.currentVelocityZ + v173_
			self.currentVelocityX = v174_
			self.currentVelocityZ = v175_
			self.currentSpeed = MathUtil.vector2Length(self.currentVelocityX, self.currentVelocityZ)
			if v168_ < self.currentSpeed then
				local v176_ = self.currentVelocityX / self.currentSpeed * v168_
				local v177_ = self.currentVelocityZ / self.currentSpeed * v168_
				self.currentVelocityX = v176_
				self.currentVelocityZ = v177_
				self.currentSpeed = v168_
			end
		end
	end
end

-- Local values: desiredSpeed, desiredSpeed, overDepthAmount, movementAccelerationY
function PlayerMover:updateVerticalVelocity(dt)
	if self.isGrounded and self.currentVelocityY < 0 then
		self.currentVelocityY = 0
	end
	if self.isFlightActive then
		local v180_
		if self.player.inputComponent.runAxis > 0 then
			v180_ = PlayerMover.FLIGHT_HEIGHT_SPEED_FAST * self.player.inputComponent.runAxis * self.player.inputComponent.flightAxis
		else
			v180_ = PlayerMover.FLIGHT_HEIGHT_SPEED * self.player.inputComponent.flightAxis
		end
		self.currentVelocityY = v180_
		return
	elseif self.isOnLadder then
		self.currentVelocityY = PlayerMover.LADDER_CLIMB_SPEED * self.player.inputComponent.walkAxis
		return
	elseif self.needSwimming and (self.player.toggleNoClipCommand == nil or not self.player.toggleNoClipCommand.value) then
		local v181_ = self.currentWaterSubmergeDistance - PlayerMover.SWIM_SUBMERGE_THRESHOLD
		self.currentVelocityY = math.max(v181_, 0)
	else
		self:moveVertically(-PlayerMover.GRAVITY)
		local v182_ = self.currentForceY * dt * 0.001
		local v183_ = self.currentVelocityY + v182_
		local v184_ = PlayerMover.MAXIMUM_DOWNWARD_SPEED
		local v185_ = PlayerMover.MAXIMUM_UPWARD_SPEED
		self.currentVelocityY = math.clamp(v183_, v184_, v185_)
	end
end

-- Local values: _, yaw, targetGraphicsYawRotation, maxDeltaRotationY
function PlayerMover:updateRotation(dt, movementYaw)
	if self.player.camera == nil or not self.player.camera.isFirstPerson then
		if self:getSpeed() <= 0 then
			setWorldRotation(self.movementDirectionNode, 0, self.movementDirectionYaw, 0)
		else
			local v189_ = MathUtil.normalizeRotationForShortestPath(movementYaw, self.movementDirectionYaw)
			local v190_ = PlayerMover.ROTATION_SPEED * dt * 0.001
			if self.movementDirectionYaw < v189_ then
				local v191_ = self.movementDirectionYaw + v190_
				self.movementDirectionYaw = math.min(v191_, v189_)
			else
				local v192_ = self.movementDirectionYaw - v190_
				self.movementDirectionYaw = math.max(v192_, v189_)
			end
			self.movementDirectionYaw = MathUtil.getValidLimit(self.movementDirectionYaw)
			setWorldRotation(self.movementDirectionNode, 0, self.movementDirectionYaw, 0)
		end
	else
		local _, v193_ = self.player.camera:getRotation()
		self.movementDirectionYaw = v193_
		setWorldRotation(self.movementDirectionNode, 0, self.movementDirectionYaw, 0)
		return
	end
end

-- Local values: positionX, positionY, positionZ
function PlayerMover:debugDraw(x, y, textSize)
	DebugUtil.drawDebugNode(self.movementDirectionNode, "MDIR", false, 0)
	local v198_ = DebugUtil.renderTextLine(x, y, textSize * 1.5, "Mover", nil, true)
	local v199_ = DebugUtil.renderTextLine(x, v198_, textSize, "Movement", nil, true)
	local v200_, v201_, v202_ = self:getPosition()
	local v203_ = DebugUtil.renderTextLine(x, v199_, textSize, string.format("Position: %.2f, %.2f, %.2f", v200_, v201_, v202_))
	local v204_ = DebugUtil.renderTextLine(x, v203_, textSize, string.format("Velocity: %.2f, %.2f, %.2f", self.currentVelocityX, self.currentVelocityY, self.currentVelocityZ))
	local v205_ = DebugUtil.renderTextLine(x, v204_, textSize, string.format("Movement yaw: %.4f", self:getMovementYaw()))
	local v206_ = DebugUtil.renderTextLine(x, v205_, textSize, string.format("Rotation: %.4f", self.movementDirectionYaw))
	local v207_ = DebugUtil.renderTextLine(x, v206_, textSize, string.format("Rotation velocity: %.4f", self.currentRotationVelocity))
	local v208_ = DebugUtil.renderTextLine(x, v207_, textSize, string.format("Speed: %.4f", self.currentSpeed))
	local v209_ = DebugUtil.renderNewLine(v208_, textSize)
	local v210_ = DebugUtil.renderTextLine(x, v209_, textSize, "Ground/water", nil, true)
	local v211_ = DebugUtil.renderTextLine(x, v210_, textSize, string.format("Water level: %.4f", self.waterUnderfootY or 0))
	local v212_ = DebugUtil.renderTextLine(x, v211_, textSize, string.format("Submerge distance: %.4f", self.currentWaterSubmergeDistance))
	local v213_ = DebugUtil.renderTextLine(x, v212_, textSize, string.format("Swimming/in water: %s/%s", self.isSwimming, self.isInWater))
	local v214_ = DebugUtil.renderTextLine(x, v213_, textSize, string.format("Ground level: %.4f", self.groundUnderfootY or 0))
	local v215_ = DebugUtil.renderTextLine(x, v214_, textSize, string.format("Ground distance: %.4f", self.currentGroundDistance))
	local v216_ = DebugUtil.renderTextLine(x, v215_, textSize, string.format("Grounded: %s", self.isGrounded))
	local v217_ = DebugUtil.renderTextLine(x, v216_, textSize, string.format("Close to ground: %s", self.isCloseToGround))
	return DebugUtil.renderTextLine(x, v217_, textSize, string.format("Fall/air/ground time: %.4f/%.4f/%.4f", self.currentFallTime, self.currentAirTime, self.currentGroundTime))
end
