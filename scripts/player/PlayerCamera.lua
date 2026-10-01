PlayerCamera = {}
local PlayerCamera_mt = Class(PlayerCamera)
PlayerCamera.FIRST_PERSON_Y_OFFSET = 1.75
PlayerCamera.THIRD_PERSON_BASE_Y_OFFSET = 1.6
PlayerCamera.DEFAULT_ZOOM = 5
PlayerCamera.MINIMUM_ZOOM = 1
PlayerCamera.MAXIMUM_ZOOM = 10
PlayerCamera.TARGET_DISTANCE_OFFSET = 0.75
PlayerCamera.COLLISION_MASK = CollisionFlag.TERRAIN + CollisionFlag.CAMERA_BLOCKING + CollisionFlag.WATER
PlayerCamera.LOWEST_PITCH = -1.3962634015954636
PlayerCamera.HIGHEST_PITCH = 1.4835298641951802
PlayerCamera.ROLL_BOBBING = 0
PlayerCamera.HORIZONTAL_BOBBING = 0
PlayerCamera.VERTICAL_BOBBING = 0
PlayerCamera.MAXIMUM_BOBBING_OSCILLATION = 0
PlayerCamera.BOBBING_OSCILLATION_RANDOMNESS = 0
function PlayerCamera.new(player)
	local self = setmetatable({}, PlayerCamera_mt)
	self.player = player
	self.isFirstPerson = true
	self.isSwitchingLocked = false
	self.isCollisionEnabled = true
	self.noClipCollisionMask = PlayerCamera.COLLISION_MASK
	self.lastCollisionDistance = nil
	self.lastDistanceOffset = nil
	self.yawNode = nil
	self.pitchNode = nil
	self.cameraRootNode = nil
	self.offsetY = 0
	self.startPositionX = nil
	self.startPositionY = nil
	self.startPositionZ = nil
	self.startRotationX = nil
	self.startRotationY = nil
	self.startRotationZ = nil
	self.startRotationW = nil
	self.targetPositionX = nil
	self.targetPositionY = nil
	self.targetPositionZ = nil
	self.targetRotationX = nil
	self.targetRotationY = nil
	self.targetRotationZ = nil
	self.targetRotationW = nil
	self.overrideTransitionStartTime = nil
	self.overrideTransitionDuration = nil
	self.lastBobOffsetX = 0
	self.lastBobOffsetY = 0
	self.desiredZoomDistance = PlayerCamera.DEFAULT_ZOOM
	self.currentZoomDistance = self.desiredZoomDistance
	g_messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.FOV_Y_PLAYER_FIRST_PERSON], self.onFovySettingChanged, self)
	g_messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.FOV_Y_PLAYER_THIRD_PERSON], self.onFovySettingChanged, self)
	return self
end
function PlayerCamera:initialise()
	self:initialiseCameraNodes()
end
function PlayerCamera:initialiseCameraNodes()
	self.yawNode = createTransformGroup("cameraYawNode")
	self.pitchNode = createTransformGroup("cameraPitchNode")
	self.cameraRootNode = createTransformGroup("cameraRootNode")
	self.firstPersonCamera = createCamera("playerCameraFirstPerson", g_gameSettings:getValue(GameSettings.SETTING.FOV_Y_PLAYER_FIRST_PERSON), 0.15, 6000)
	link(self.cameraRootNode, self.firstPersonCamera)
	local dofInfoFirstPerson = g_depthOfFieldManager:createInfo(0.8, 0.5, 0, 1000, 1400, false)
	g_cameraManager:addCamera(self.firstPersonCamera, nil, false, nil, dofInfoFirstPerson)
	self.thirdPersonCamera = createCamera("playerCameraThirdPerson", g_gameSettings:getValue(GameSettings.SETTING.FOV_Y_PLAYER_THIRD_PERSON), 0.15, 6000)
	link(self.cameraRootNode, self.thirdPersonCamera)
	local dofInfo = g_depthOfFieldManager:createInfo(0.5, 4, 0.3, 30, 200, false)
	g_cameraManager:addCamera(self.thirdPersonCamera, nil, false, nil, dofInfo)
	self.thirdPersonConversationCamera = createCamera("playerCameraThirdPersonConversation", g_gameSettings:getValue(GameSettings.SETTING.FOV_Y_PLAYER_THIRD_PERSON), 0.15, 6000)
	link(self.cameraRootNode, self.thirdPersonConversationCamera)
	local dofInfoConversation = g_depthOfFieldManager:createInfo(0.75, 2, 0.75, 2, 7, false)
	g_cameraManager:addCamera(self.thirdPersonConversationCamera, nil, false, nil, dofInfoConversation)
	link(getRootNode(), self.yawNode)
	link(self.yawNode, self.pitchNode)
	link(self.pitchNode, self.cameraRootNode)
	setRotation(self.cameraRootNode, 0, 3.141592653589793, 0)
	self:zoomSmoothly(0)
	self:setCurrentZoomDistance(self.desiredZoomDistance)
	self:applyZoom(g_currentDt)
end
function PlayerCamera:onPlayerLoad()
	self.player.toggleNoClipCommand.onEnabled:registerListener(function(disableTerrainCollision)
		local newCollision = Utils.stringToBoolean(disableTerrainCollision) and 0 or CollisionFlag.TERRAIN
		self.noClipCollisionMask = newCollision
	end)
end
function PlayerCamera:delete()
	if self.firstPersonCamera ~= nil then
		g_cameraManager:removeCamera(self.firstPersonCamera)
	end
	if self.thirdPersonCamera ~= nil then
		g_cameraManager:removeCamera(self.thirdPersonCamera)
	end
	if self.thirdPersonConversationCamera ~= nil then
		g_cameraManager:removeCamera(self.thirdPersonConversationCamera)
	end
	if self.yawNode ~= nil then
		delete(self.yawNode)
		self.yawNode = nil
	end
	g_messageCenter:unsubscribeAll(self)
end
function PlayerCamera:makeCurrent()
	if self.isFirstPerson then
		g_cameraManager:setActiveCamera(self.firstPersonCamera)
	elseif self.isInConversation then
		g_cameraManager:setActiveCamera(self.thirdPersonConversationCamera)
	else
		g_cameraManager:setActiveCamera(self.thirdPersonCamera)
	end
end
function PlayerCamera:toggleThirdPersonMode()
	self:switchToPerspective(not self.isFirstPerson)
end
function PlayerCamera:setIsInConversation(isInConversation)
	if not self.isFirstPerson and not self.isSwitchingLocked then
		self.isInConversation = isInConversation
		self:makeCurrent()
	end
end
function PlayerCamera:getCurrentCameraNode()
	if self.isFirstPerson then
		return self.firstPersonCamera
	elseif self.isInConversation then
		return self.thirdPersonConversationCamera
	else
		return self.thirdPersonCamera
	end
end
function PlayerCamera:switchToPerspective(isFirstPerson)
	if isFirstPerson then
		self:switchToFirstPersonMode()
	else
		self:switchToThirdPersonMode()
	end
end
function PlayerCamera:switchToThirdPersonMode()
	if self.isFirstPerson and not self.isSwitchingLocked then
		self.isFirstPerson = false
		self:makeCurrent()
		self:setCurrentZoomDistance(self.desiredZoomDistance)
		local pitch, yaw = self:getRotation()
		self:setRotation(pitch, yaw, 0)
		self.player:onPerspectiveSwitched(self.isFirstPerson)
	end
end
function PlayerCamera:lockThirdPersonMode()
	self:switchToThirdPersonMode()
	self:lockSwitching()
end
function PlayerCamera:switchToFirstPersonMode()
	if self.isFirstPerson or self.isSwitchingLocked then
		return
	end
	self.isFirstPerson = true
	self:makeCurrent()
	if self:getHasOverriddenTarget() then
		self:clearTargetOverride()
	end
	local currentYaw = self.player:getGraphicalYaw()
	self:setRotation(0, currentYaw, 0)
	self:setCurrentZoomDistance(0, true)
	self.lastBobOffsetX = 0
	self.lastBobOffsetY = 0
	self.player:onPerspectiveSwitched(self.isFirstPerson)
end
function PlayerCamera:lockFirstPersonMode()
	self:switchToFirstPersonMode()
	self:lockSwitching()
end
function PlayerCamera:getIsSwitchingLocked()
	return self.isSwitchingLocked
end
function PlayerCamera:lockSwitching()
	self.isSwitchingLocked = true
end
function PlayerCamera:unlockSwitching()
	self.isSwitchingLocked = false
end
function PlayerCamera:getCollisionMask()
	if not self:getIsCollisionEnabled() then
		return 0
	end
	if self.player.toggleNoClipCommand ~= nil and self.player.toggleNoClipCommand.value then
		return self.noClipCollisionMask
	end
	if 0 < self.player.mover.currentWaterSubmergeDistance then
		return CollisionFlag.TERRAIN + CollisionFlag.CAMERA_BLOCKING
	else
		return CollisionFlag.TERRAIN + CollisionFlag.CAMERA_BLOCKING + CollisionFlag.WATER
	end
end
function PlayerCamera:getIsCollisionEnabled()
	return self.isCollisionEnabled
end
function PlayerCamera:setIsCollisionEnabled(isCollisionEnabled)
	self.isCollisionEnabled = isCollisionEnabled
end
function PlayerCamera:getIsTerrainCorrectionEnabled()
	return bit32.band(CollisionFlag.TERRAIN, self:getCollisionMask()) ~= 0
end
function PlayerCamera:getHasOverriddenTarget()
	return self.targetPositionX ~= nil and self.overrideTransitionDuration ~= nil
end
function PlayerCamera:getBaseOffsetY()
	if self.isFirstPerson then
		return PlayerCamera.FIRST_PERSON_Y_OFFSET
	else
		return PlayerCamera.THIRD_PERSON_BASE_Y_OFFSET
	end
end
function PlayerCamera:getOffsetY()
	return self.offsetY
end
function PlayerCamera:setOffsetY(offsetY)
	self.offsetY = offsetY or 0
end
function PlayerCamera:getCurrentZoomDistance()
	return self.currentZoomDistance
end
function PlayerCamera:setCurrentZoomDistance(zoomDistance, isForced)
	self.currentZoomDistance = zoomDistance
	setTranslation(self.cameraRootNode, 0, 0, -self.currentZoomDistance)
end
function PlayerCamera:getDesiredZoomDistance()
	if self.isFirstPerson then
		return 0
	else
		return self.desiredZoomDistance
	end
end
function PlayerCamera:getFocusRotation()
	local cameraLookX, _, cameraLookZ = localDirectionToWorld(self.yawNode, 0, 0, 1)
	local _, cameraLookY, _ = localDirectionToWorld(self.pitchNode, 0, 0, 1)
	cameraLookX, cameraLookY, cameraLookZ = MathUtil.vector3Normalize(cameraLookX, cameraLookY, cameraLookZ)
	local pitch, yaw = MathUtil.directionToPitchYaw(cameraLookX, cameraLookY, cameraLookZ)
	local _, _, roll = getRotation(self.cameraRootNode)
	return pitch, yaw, roll
end
function PlayerCamera:getFocusPosition()
	return getWorldTranslation(self.yawNode)
end
function PlayerCamera:setFocusPosition(x, y, z)
	setWorldTranslation(self.yawNode, x, y, z)
end
function PlayerCamera:setTargetOverrideFromNode(node, transitionDuration)
	if self.isFirstPerson then
		if self:getHasOverriddenTarget() then
			self:clearTargetOverride()
		end
	else
		self.targetPositionX, self.targetPositionY, self.targetPositionZ = getWorldTranslation(node)
		self.targetRotationX, self.targetRotationY, self.targetRotationZ, self.targetRotationW = getWorldQuaternion(node)
		if transitionDuration ~= nil then
			self.overrideTransitionStartTime = g_time
			self.overrideTransitionDuration = transitionDuration
			self.startPositionX, self.startPositionY, self.startPositionZ = self:getCameraPosition()
			self.startRotationX, self.startRotationY, self.startRotationZ, self.startRotationW = getWorldQuaternion(self.cameraRootNode)
			if transitionDuration == 0 then
				self:updateRotationFromTarget()
				self:updatePositionFromTarget()
			end
		end
	end
end
function PlayerCamera:clearTargetOverride()
	self.startPositionX = nil
	self.startPositionY = nil
	self.startPositionZ = nil
	self.startRotationX = nil
	self.startRotationY = nil
	self.startRotationZ = nil
	self.startRotationW = nil
	self.targetPositionX = nil
	self.targetPositionY = nil
	self.targetPositionZ = nil
	self.targetRotationX = nil
	self.targetRotationY = nil
	self.targetRotationZ = nil
	self.targetRotationW = nil
	self.overrideTransitionStartTime = nil
	self.overrideTransitionDuration = nil
	self:setCurrentZoomDistance(self:getCurrentZoomDistance())
end
function PlayerCamera:getCameraPosition()
	return getWorldTranslation(self.cameraRootNode)
end
function PlayerCamera:getRotation()
	local cameraLookX, cameraLookY, cameraLookZ = localDirectionToWorld(self.cameraRootNode, 0, 0, -1)
	local pitch, yaw = MathUtil.directionToPitchYaw(cameraLookX, cameraLookY, cameraLookZ)
	local _, _, roll = getRotation(self.cameraRootNode)
	return pitch, yaw, roll
end
function PlayerCamera:setRotation(pitch, yaw, roll)
	setRotation(self.pitchNode, pitch or 0, 0, 0)
	setRotation(self.yawNode, 0, yaw or 0, 0)
	setRotation(self.cameraRootNode, 0, 3.141592653589793, roll or 0)
end
function PlayerCamera:calculateWorldDirection(directionX, directionZ)
	local worldDirectionX, _, worldDirectionZ = localDirectionToWorld(self.yawNode, directionX, 0, directionZ)
	return worldDirectionX, worldDirectionZ
end
function PlayerCamera:calculateLocalDirection(directionX, directionZ)
	local localDirectionX, _, localDirectionZ = worldDirectionToLocal(self.yawNode, directionX, 0, directionZ)
	return localDirectionX, localDirectionZ
end
function PlayerCamera:zoomSmoothly(offset)
	if self.isFirstPerson then
		return
	else
		self.desiredZoomDistance = math.clamp(self.desiredZoomDistance + offset, self.MINIMUM_ZOOM, self.MAXIMUM_ZOOM)
	end
end
function PlayerCamera:updateRotation(dt)
	if self:getHasOverriddenTarget() then
		self:updateRotationFromTarget()
	else
		local cameraSensitivity = g_gameSettings:getValue(GameSettings.SETTING.CAMERA_SENSITIVITY)
		local rotationDeltaX = self.player.inputComponent.cameraRotationX * cameraSensitivity
		local rotationDeltaY = -self.player.inputComponent.cameraRotationY * cameraSensitivity
		local cameraPitch, cameraYaw, cameraRoll = self:getRotation()
		cameraPitch = math.clamp(cameraPitch + rotationDeltaX, PlayerCamera.LOWEST_PITCH, PlayerCamera.HIGHEST_PITCH)
		cameraYaw = MathUtil.getValidLimit(cameraYaw + rotationDeltaY)
		self:setRotation(cameraPitch, cameraYaw, cameraRoll)
	end
end
function PlayerCamera:updatePosition(dt)
	if self:getHasOverriddenTarget() then
		self:updatePositionFromTarget()
	else
		self:focusOnPlayer()
		self:tryApplyViewBobbing(dt)
		self:applyZoom(dt)
	end
end
function PlayerCamera:focusOnPlayer()
	local currentX, currentY, currentZ = self.player:getGraphicalPosition()
	self:focusOnPosition(currentX, currentY, currentZ)
end
function PlayerCamera:updatePositionFromTarget()
	if not self:getHasOverriddenTarget() then
		return
	else
		local alpha = self.overrideTransitionDuration == 0 and 1 or (g_time - self.overrideTransitionStartTime) / self.overrideTransitionDuration
		local currentPositionX = nil
		local currentPositionY = nil
		local currentPositionZ = nil
		if 1 <= alpha then
			currentPositionX = self.targetPositionX
			currentPositionY = self.targetPositionY
			currentPositionZ = self.targetPositionZ
		else
			currentPositionX, currentPositionY, currentPositionZ = MathUtil.vector3Lerp(self.startPositionX, self.startPositionY, self.startPositionZ, self.targetPositionX, self.targetPositionY, self.targetPositionZ, alpha)
		end
		setTranslation(self.cameraRootNode, 0, 0, 0)
		setWorldTranslation(self.yawNode, currentPositionX, currentPositionY, currentPositionZ)
	end
end
function PlayerCamera:updateRotationFromTarget()
	if not self:getHasOverriddenTarget() then
		return
	else
		local alpha = self.overrideTransitionDuration == 0 and 1 or (g_time - self.overrideTransitionStartTime) / self.overrideTransitionDuration
		local currentRotationX = nil
		local currentRotationY = nil
		local currentRotationZ = nil
		local currentRotationW = nil
		if 1 <= alpha then
			currentRotationX = self.targetRotationX
			currentRotationY = self.targetRotationY
			currentRotationZ = self.targetRotationZ
			currentRotationW = self.targetRotationW
		else
			currentRotationX, currentRotationY, currentRotationZ, currentRotationW = MathUtil.nlerpQuaternionShortestPath(self.startRotationX, self.startRotationY, self.startRotationZ, self.startRotationW, self.targetRotationX, self.targetRotationY, self.targetRotationZ, self.targetRotationW, alpha)
		end
		setWorldQuaternion(self.cameraRootNode, currentRotationX, currentRotationY, currentRotationZ, currentRotationW)
		local pitch, yaw = self:getRotation()
		self:setRotation(pitch, yaw, 0)
	end
end
function PlayerCamera:focusOnPosition(x, y, z)
	local baseOffsetY = self:getBaseOffsetY()
	self:setFocusPosition(x, y + self.offsetY + baseOffsetY, z)
end
function PlayerCamera:tryApplyViewBobbing(dt)
	if not self.isFirstPerson then
		setTranslation(self.cameraRootNode, 0, 0, -self.currentZoomDistance)
		return
	end
	local doCameraBobbing = g_gameSettings:getValue(GameSettings.SETTING.CAMERA_BOBBING)
	if not doCameraBobbing then
		setTranslation(self.cameraRootNode, 0, 0, 0)
	elseif 10 >= self.player.mover.currentSpeed then
		local targetBobOffsetX = 0
		local targetBobOffsetY = 0
		local bobRoll = 0
		local isMoving = PlayerMover.SMALL_SPEED_THRESHOLD <= math.abs(self.player.mover.currentSpeed)
		if isMoving and self.player.mover.isGrounded then
			local roundedSpeed = MathUtil.round(self.player.mover.currentSpeed)
			local randomOffsetX = math.random(-self.BOBBING_OSCILLATION_RANDOMNESS, self.BOBBING_OSCILLATION_RANDOMNESS)
			local oscillationX = math.sin(g_time * 0.001 * roundedSpeed)
			local oscillationY = math.sin((oscillationX + randomOffsetX + 0.5) * 3.141592653589793)
			bobRoll = oscillationX * PlayerCamera.ROLL_BOBBING
			targetBobOffsetX = oscillationX * self.HORIZONTAL_BOBBING
			targetBobOffsetY = oscillationY * self.VERTICAL_BOBBING
		end
		local bobOffsetX = nil
		local bobOffsetY = nil
		local maxBobMovementX = self.HORIZONTAL_BOBBING * self.MAXIMUM_BOBBING_OSCILLATION
		local maxBobMovementY = self.VERTICAL_BOBBING * self.MAXIMUM_BOBBING_OSCILLATION
		if self.lastBobOffsetX < targetBobOffsetX then
			bobOffsetX = math.min(self.lastBobOffsetX + maxBobMovementX, targetBobOffsetX)
		else
			bobOffsetX = math.max(self.lastBobOffsetX - maxBobMovementX, targetBobOffsetX)
		end
		if self.lastBobOffsetY < targetBobOffsetY then
			bobOffsetY = math.min(self.lastBobOffsetY + maxBobMovementY, targetBobOffsetY)
		else
			bobOffsetY = math.max(self.lastBobOffsetY - maxBobMovementY, targetBobOffsetY)
		end
		setTranslation(self.cameraRootNode, bobOffsetX, bobOffsetY, 0)
		local currentPitch, currentYaw = self:getRotation()
		self:setRotation(currentPitch, currentYaw, bobRoll)
		self.lastBobOffsetX = bobOffsetX
		self.lastBobOffsetY = bobOffsetY
	end
end
function PlayerCamera:applyZoom(dt)
	if self.isFirstPerson then
		return
	end
	self:applyTerrainHeightCorrection()
	local targetZoomDistance, snapToDistance = self:calculateCollisionZoom()
	if snapToDistance then
		self:setCurrentZoomDistance(targetZoomDistance)
	else
		if self.currentZoomDistance ~= targetZoomDistance then
			local zoom = targetZoomDistance + math.pow(0.99579, dt) * (self.currentZoomDistance - targetZoomDistance)
			self:setCurrentZoomDistance(zoom)
		end
	end
end
function PlayerCamera:applyTerrainHeightCorrection()
	if not self:getIsTerrainCorrectionEnabled() then
		return
	else
		local iterationsCount = 4
		for i = 1, 4 do
			local cameraPositionX, cameraPositionY, cameraPositionZ = self:getCameraPosition()
			local _, focusPositionY, _ = self:getFocusPosition()
			local terrainHeight = getTerrainHeightAtWorldPos(g_terrainNode, cameraPositionX, cameraPositionY, cameraPositionZ)
			local waterHeight = g_currentMission.environmentAreaSystem:getWaterYAtWorldPosition(cameraPositionX, cameraPositionY + 15, cameraPositionZ)
			local height = terrainHeight
			if waterHeight ~= nil then
				height = math.max(waterHeight, terrainHeight)
			end
			local minimumHeight = height + 0.2
			if minimumHeight <= cameraPositionY then
				return
			end
			local pitchSine = math.clamp((minimumHeight - focusPositionY) / self:getCurrentZoomDistance(), -1, 1)
			local newPitch = math.clamp(math.asin(pitchSine), PlayerCamera.LOWEST_PITCH, PlayerCamera.HIGHEST_PITCH)
			local _, currentYaw, currentRoll = self:getRotation()
			self:setRotation(newPitch, currentYaw, currentRoll)
		end
	end
end
function PlayerCamera:calculateCollisionZoom()
	if not self:getIsCollisionEnabled() then
		return self.desiredZoomDistance, false
	end
	local originX, originY, originZ = self:getFocusPosition()
	local directionX, directionY, directionZ = localDirectionToWorld(self.cameraRootNode, 0, 0, 1)
	raycastClosestAsync(originX, originY, originZ, directionX, directionY, directionZ, self.desiredZoomDistance, "distanceRaycastCallback", self, self:getCollisionMask())
	if self.lastCollisionDistance == nil then
		return self.desiredZoomDistance, false
	else
		local currentZoomDistance = self:getCurrentZoomDistance()
		local newZoomDistance = math.min(self.desiredZoomDistance, self.lastCollisionDistance - self.lastDistanceOffset)
		local snapToDistance = newZoomDistance < currentZoomDistance or math.abs(currentZoomDistance - newZoomDistance) <= 0.025
		return newZoomDistance, snapToDistance
	end
end
function PlayerCamera:distanceRaycastCallback(nodeId, x, y, z, distance, nx, ny, nz, subShapeIndex, shapeId, isLast)
	if nodeId == nil or nodeId == 0 then
		self.lastCollisionDistance = nil
		self.lastDistanceOffset = nil
		return
	end
	self.lastCollisionDistance = distance
	local rayDirectionX, rayDirectionY, rayDirectionZ = localDirectionToWorld(self.cameraRootNode, 0, 0, 1)
	local dotProduct = MathUtil.dotProduct(nx, ny, nz, rayDirectionX, rayDirectionY, rayDirectionZ)
	local absoluteDotProduct = math.abs(dotProduct)
	local distanceOffset = MathUtil.lerp(0.4, 0.1, absoluteDotProduct * absoluteDotProduct * (3 - 2 * absoluteDotProduct))
	self.lastDistanceOffset = distanceOffset
end
function PlayerCamera:onFovySettingChanged()
	if self.firstPersonCamera ~= nil then
		setFovY(self.firstPersonCamera, g_gameSettings:getValue(GameSettings.SETTING.FOV_Y_PLAYER_FIRST_PERSON))
	end
	if self.thirdPersonCamera ~= nil then
		setFovY(self.thirdPersonCamera, g_gameSettings:getValue(GameSettings.SETTING.FOV_Y_PLAYER_THIRD_PERSON))
	end
	if self.thirdPersonConversationCamera ~= nil then
		setFovY(self.thirdPersonConversationCamera, g_gameSettings:getValue(GameSettings.SETTING.FOV_Y_PLAYER_THIRD_PERSON))
	end
end
function PlayerCamera:debugDraw(x, y, textSize)
	y = DebugUtil.renderTextLine(x, y, textSize * 1.5, "Camera", nil, true)
	local originX, originY, originZ = self:getFocusPosition()
	y = DebugUtil.renderTextLine(x, y, textSize, string.format("Focus position: %.2fm, %.2fm, %.2fm", originX, originY, originZ))
	y = DebugUtil.renderTextLine(x, y, textSize, string.format("Current zoom: %.2fm", self.currentZoomDistance))
	y = DebugUtil.renderTextLine(x, y, textSize, string.format("Current offset: %.2fm", self.lastDistanceOffset or 0))
	y = DebugUtil.renderTextLine(x, y, textSize, string.format("Collision distance: %.2fm", self.lastCollisionDistance or 0))
	local rotationX, rotationY, rotationZ = self:getRotation()
	y = DebugUtil.renderTextLine(x, y, textSize, string.format("Pitch: %.2f\194\176, Yaw: %.2f\194\176, Roll: %.2f\194\176", math.deg(rotationX), math.deg(rotationY), math.deg(rotationZ)))
	DebugUtil.drawDebugNode(self.yawNode, "yaw")
	return y
end
