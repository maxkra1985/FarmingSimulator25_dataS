-- Local values: PlayerCamera_mt
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

-- Upvalues: PlayerCamera_mt
-- Local values: self
function PlayerCamera.new(player)
	-- upvalues: (copy) PlayerCamera_mt
	local v3_ = PlayerCamera_mt
	local v4_ = setmetatable({}, v3_)
	v4_.player = player
	v4_.isFirstPerson = true
	v4_.isSwitchingLocked = false
	v4_.isCollisionEnabled = true
	v4_.noClipCollisionMask = PlayerCamera.COLLISION_MASK
	v4_.lastCollisionDistance = nil
	v4_.lastDistanceOffset = nil
	v4_.yawNode = nil
	v4_.pitchNode = nil
	v4_.cameraRootNode = nil
	v4_.offsetY = 0
	v4_.startPositionX = nil
	v4_.startPositionY = nil
	v4_.startPositionZ = nil
	v4_.startRotationX = nil
	v4_.startRotationY = nil
	v4_.startRotationZ = nil
	v4_.startRotationW = nil
	v4_.targetPositionX = nil
	v4_.targetPositionY = nil
	v4_.targetPositionZ = nil
	v4_.targetRotationX = nil
	v4_.targetRotationY = nil
	v4_.targetRotationZ = nil
	v4_.targetRotationW = nil
	v4_.overrideTransitionStartTime = nil
	v4_.overrideTransitionDuration = nil
	v4_.lastBobOffsetX = 0
	v4_.lastBobOffsetY = 0
	v4_.desiredZoomDistance = PlayerCamera.DEFAULT_ZOOM
	v4_.currentZoomDistance = v4_.desiredZoomDistance
	g_messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.FOV_Y_PLAYER_FIRST_PERSON], v4_.onFovySettingChanged, v4_)
	g_messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.FOV_Y_PLAYER_THIRD_PERSON], v4_.onFovySettingChanged, v4_)
	return v4_
end

function PlayerCamera:initialise()
	self:initialiseCameraNodes()
end

-- Local values: dofInfoFirstPerson, dofInfo, dofInfoConversation
function PlayerCamera:initialiseCameraNodes()
	self.yawNode = createTransformGroup("cameraYawNode")
	self.pitchNode = createTransformGroup("cameraPitchNode")
	self.cameraRootNode = createTransformGroup("cameraRootNode")
	self.firstPersonCamera = createCamera("playerCameraFirstPerson", g_gameSettings:getValue(GameSettings.SETTING.FOV_Y_PLAYER_FIRST_PERSON), 0.15, 6000)
	link(self.cameraRootNode, self.firstPersonCamera)
	local v7_ = g_depthOfFieldManager:createInfo(0.8, 0.5, 0, 1000, 1400, false)
	g_cameraManager:addCamera(self.firstPersonCamera, nil, false, nil, v7_)
	self.thirdPersonCamera = createCamera("playerCameraThirdPerson", g_gameSettings:getValue(GameSettings.SETTING.FOV_Y_PLAYER_THIRD_PERSON), 0.15, 6000)
	link(self.cameraRootNode, self.thirdPersonCamera)
	local v8_ = g_depthOfFieldManager:createInfo(0.5, 4, 0.3, 30, 200, false)
	g_cameraManager:addCamera(self.thirdPersonCamera, nil, false, nil, v8_)
	self.thirdPersonConversationCamera = createCamera("playerCameraThirdPersonConversation", g_gameSettings:getValue(GameSettings.SETTING.FOV_Y_PLAYER_THIRD_PERSON), 0.15, 6000)
	link(self.cameraRootNode, self.thirdPersonConversationCamera)
	local v9_ = g_depthOfFieldManager:createInfo(0.75, 2, 0.75, 2, 7, false)
	g_cameraManager:addCamera(self.thirdPersonConversationCamera, nil, false, nil, v9_)
	link(getRootNode(), self.yawNode)
	link(self.yawNode, self.pitchNode)
	link(self.pitchNode, self.cameraRootNode)
	setRotation(self.cameraRootNode, 0, 3.141592653589793, 0)
	self:zoomSmoothly(0)
	self:setCurrentZoomDistance(self.desiredZoomDistance)
	self:applyZoom(g_currentDt)
end

function PlayerCamera:onPlayerLoad()
	self.player.toggleNoClipCommand.onEnabled:registerListener(function(p11_)
		-- upvalues: (copy) self
		self.noClipCollisionMask = Utils.stringToBoolean(p11_) and 0 or CollisionFlag.TERRAIN
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
		return
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
	if not (self.isFirstPerson or self.isSwitchingLocked) then
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

-- Local values: pitch, yaw
function PlayerCamera:switchToThirdPersonMode()
	if self.isFirstPerson and not self.isSwitchingLocked then
		self.isFirstPerson = false
		self:makeCurrent()
		self:setCurrentZoomDistance(self.desiredZoomDistance)
		local v21_, v22_ = self:getRotation()
		self:setRotation(v21_, v22_, 0)
		self.player:onPerspectiveSwitched(self.isFirstPerson)
	end
end

function PlayerCamera:lockThirdPersonMode()
	self:switchToThirdPersonMode()
	self:lockSwitching()
end

-- Local values: currentYaw
function PlayerCamera:switchToFirstPersonMode()
	if not (self.isFirstPerson or self.isSwitchingLocked) then
		self.isFirstPerson = true
		self:makeCurrent()
		if self:getHasOverriddenTarget() then
			self:clearTargetOverride()
		end
		self:setRotation(0, self.player:getGraphicalYaw(), 0)
		self:setCurrentZoomDistance(0, true)
		self.lastBobOffsetX = 0
		self.lastBobOffsetY = 0
		self.player:onPerspectiveSwitched(self.isFirstPerson)
	end
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
	if self:getIsCollisionEnabled() then
		if self.player.toggleNoClipCommand == nil or not self.player.toggleNoClipCommand.value then
			if self.player.mover.currentWaterSubmergeDistance > 0 then
				return CollisionFlag.TERRAIN + CollisionFlag.CAMERA_BLOCKING
			else
				return CollisionFlag.TERRAIN + CollisionFlag.CAMERA_BLOCKING + CollisionFlag.WATER
			end
		else
			return self.noClipCollisionMask
		end
	else
		return 0
	end
end

function PlayerCamera:getIsCollisionEnabled()
	return self.isCollisionEnabled
end

function PlayerCamera:setIsCollisionEnabled(isCollisionEnabled)
	self.isCollisionEnabled = isCollisionEnabled
end

function PlayerCamera:getIsTerrainCorrectionEnabled()
	local v34_ = CollisionFlag.TERRAIN
	return bit32.band(v34_, self:getCollisionMask()) ~= 0
end

function PlayerCamera:getHasOverriddenTarget()
	local v36_
	if self.targetPositionX == nil then
		v36_ = false
	else
		v36_ = self.overrideTransitionDuration ~= nil
	end
	return v36_
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
	return self.isFirstPerson and 0 or self.desiredZoomDistance
end

-- Local values: cameraLookX, _, cameraLookZ, _, cameraLookY, _, pitch, yaw, _, _, roll
function PlayerCamera:getFocusRotation()
	local v46_, _, v47_ = localDirectionToWorld(self.yawNode, 0, 0, 1)
	local _, v48_, _ = localDirectionToWorld(self.pitchNode, 0, 0, 1)
	local v49_, v50_, v51_ = MathUtil.vector3Normalize(v46_, v48_, v47_)
	local v52_, v53_ = MathUtil.directionToPitchYaw(v49_, v50_, v51_)
	local _, _, v54_ = getRotation(self.cameraRootNode)
	return v52_, v53_, v54_
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
		local v63_, v64_, v65_ = getWorldTranslation(node)
		self.targetPositionX = v63_
		self.targetPositionY = v64_
		self.targetPositionZ = v65_
		local v66_, v67_, v68_, v69_ = getWorldQuaternion(node)
		self.targetRotationX = v66_
		self.targetRotationY = v67_
		self.targetRotationZ = v68_
		self.targetRotationW = v69_
		if transitionDuration ~= nil then
			self.overrideTransitionStartTime = g_time
			self.overrideTransitionDuration = transitionDuration
			local v70_, v71_, v72_ = self:getCameraPosition()
			self.startPositionX = v70_
			self.startPositionY = v71_
			self.startPositionZ = v72_
			local v73_, v74_, v75_, v76_ = getWorldQuaternion(self.cameraRootNode)
			self.startRotationX = v73_
			self.startRotationY = v74_
			self.startRotationZ = v75_
			self.startRotationW = v76_
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

-- Local values: cameraLookX, cameraLookY, cameraLookZ, pitch, yaw, _, _, roll
function PlayerCamera:getRotation()
	local v80_, v81_, v82_ = localDirectionToWorld(self.cameraRootNode, 0, 0, -1)
	local v83_, v84_ = MathUtil.directionToPitchYaw(v80_, v81_, v82_)
	local _, _, v85_ = getRotation(self.cameraRootNode)
	return v83_, v84_, v85_
end

function PlayerCamera:setRotation(pitch, yaw, roll)
	setRotation(self.pitchNode, pitch or 0, 0, 0)
	setRotation(self.yawNode, 0, yaw or 0, 0)
	setRotation(self.cameraRootNode, 0, 3.141592653589793, roll or 0)
end

-- Local values: worldDirectionX, _, worldDirectionZ
function PlayerCamera:calculateWorldDirection(directionX, directionZ)
	local v93_, _, v94_ = localDirectionToWorld(self.yawNode, directionX, 0, directionZ)
	return v93_, v94_
end

-- Local values: localDirectionX, _, localDirectionZ
function PlayerCamera:calculateLocalDirection(directionX, directionZ)
	local v98_, _, v99_ = worldDirectionToLocal(self.yawNode, directionX, 0, directionZ)
	return v98_, v99_
end

function PlayerCamera:zoomSmoothly(offset)
	if not self.isFirstPerson then
		local v102_ = self.desiredZoomDistance + offset
		local v103_ = self.MINIMUM_ZOOM
		local v104_ = self.MAXIMUM_ZOOM
		self.desiredZoomDistance = math.clamp(v102_, v103_, v104_)
	end
end

-- Local values: cameraSensitivity, rotationDeltaX, rotationDeltaY, cameraPitch, cameraYaw, cameraRoll
function PlayerCamera:updateRotation(dt)
	if self:getHasOverriddenTarget() then
		self:updateRotationFromTarget()
	else
		local v106_ = g_gameSettings:getValue(GameSettings.SETTING.CAMERA_SENSITIVITY)
		local v107_ = self.player.inputComponent.cameraRotationX * v106_
		local v108_ = -self.player.inputComponent.cameraRotationY * v106_
		local v109_, v110_, v111_ = self:getRotation()
		local v112_ = v109_ + v107_
		local v113_ = PlayerCamera.LOWEST_PITCH
		local v114_ = PlayerCamera.HIGHEST_PITCH
		self:setRotation(math.clamp(v112_, v113_, v114_), MathUtil.getValidLimit(v110_ + v108_), v111_)
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

-- Local values: currentX, currentY, currentZ
function PlayerCamera:focusOnPlayer()
	local v118_, v119_, v120_ = self.player:getGraphicalPosition()
	self:focusOnPosition(v118_, v119_, v120_)
end

-- Local values: alpha, currentPositionX, currentPositionY, currentPositionZ
function PlayerCamera:updatePositionFromTarget()
	if self:getHasOverriddenTarget() then
		local v122_ = self.overrideTransitionDuration == 0 and 1 or (g_time - self.overrideTransitionStartTime) / self.overrideTransitionDuration
		local v123_, v124_, v125_
		if v122_ >= 1 then
			v123_ = self.targetPositionX
			v124_ = self.targetPositionY
			v125_ = self.targetPositionZ
		else
			v123_, v124_, v125_ = MathUtil.vector3Lerp(self.startPositionX, self.startPositionY, self.startPositionZ, self.targetPositionX, self.targetPositionY, self.targetPositionZ, v122_)
		end
		setTranslation(self.cameraRootNode, 0, 0, 0)
		setWorldTranslation(self.yawNode, v123_, v124_, v125_)
	end
end

-- Local values: alpha, currentRotationX, currentRotationY, currentRotationZ, currentRotationW, pitch, yaw
function PlayerCamera:updateRotationFromTarget()
	if self:getHasOverriddenTarget() then
		local v127_ = self.overrideTransitionDuration == 0 and 1 or (g_time - self.overrideTransitionStartTime) / self.overrideTransitionDuration
		local v128_, v129_, v130_, v131_
		if v127_ >= 1 then
			v128_ = self.targetRotationX
			v129_ = self.targetRotationY
			v130_ = self.targetRotationZ
			v131_ = self.targetRotationW
		else
			v128_, v129_, v130_, v131_ = MathUtil.nlerpQuaternionShortestPath(self.startRotationX, self.startRotationY, self.startRotationZ, self.startRotationW, self.targetRotationX, self.targetRotationY, self.targetRotationZ, self.targetRotationW, v127_)
		end
		setWorldQuaternion(self.cameraRootNode, v128_, v129_, v130_, v131_)
		local v132_, v133_ = self:getRotation()
		self:setRotation(v132_, v133_, 0)
	end
end

-- Local values: baseOffsetY
function PlayerCamera:focusOnPosition(x, y, z)
	local v138_ = self:getBaseOffsetY()
	self:setFocusPosition(x, y + self.offsetY + v138_, z)
end

-- Local values: doCameraBobbing, targetBobOffsetX, targetBobOffsetY, bobRoll, isMoving, roundedSpeed, randomOffsetX, oscillationX, oscillationY, bobOffsetX, bobOffsetY, maxBobMovementX, maxBobMovementY, currentPitch, currentYaw
function PlayerCamera:tryApplyViewBobbing(dt)
	if self.isFirstPerson then
		if g_gameSettings:getValue(GameSettings.SETTING.CAMERA_BOBBING) then
			if self.player.mover.currentSpeed <= 10 then
				local v140_ = self.player.mover.currentSpeed
				local v141_, v142_, v143_
				if math.abs(v140_) >= PlayerMover.SMALL_SPEED_THRESHOLD and self.player.mover.isGrounded then
					local v144_ = MathUtil.round(self.player.mover.currentSpeed)
					local v145_ = math.random(-self.BOBBING_OSCILLATION_RANDOMNESS, self.BOBBING_OSCILLATION_RANDOMNESS)
					local v146_ = g_time * 0.001 * v144_
					local v147_ = math.sin(v146_)
					local v148_ = (v147_ + v145_ + 0.5) * 3.141592653589793
					local v149_ = math.sin(v148_)
					v141_ = v147_ * PlayerCamera.ROLL_BOBBING
					v142_ = v147_ * self.HORIZONTAL_BOBBING
					v143_ = v149_ * self.VERTICAL_BOBBING
				else
					v142_ = 0
					v143_ = 0
					v141_ = 0
				end
				local v150_ = self.HORIZONTAL_BOBBING * self.MAXIMUM_BOBBING_OSCILLATION
				local v151_ = self.VERTICAL_BOBBING * self.MAXIMUM_BOBBING_OSCILLATION
				local v152_
				if self.lastBobOffsetX < v142_ then
					local v153_ = self.lastBobOffsetX + v150_
					v152_ = math.min(v153_, v142_)
				else
					local v154_ = self.lastBobOffsetX - v150_
					v152_ = math.max(v154_, v142_)
				end
				local v155_
				if self.lastBobOffsetY < v143_ then
					local v156_ = self.lastBobOffsetY + v151_
					v155_ = math.min(v156_, v143_)
				else
					local v157_ = self.lastBobOffsetY - v151_
					v155_ = math.max(v157_, v143_)
				end
				setTranslation(self.cameraRootNode, v152_, v155_, 0)
				local v158_, v159_ = self:getRotation()
				self:setRotation(v158_, v159_, v141_)
				self.lastBobOffsetX = v152_
				self.lastBobOffsetY = v155_
			end
		else
			setTranslation(self.cameraRootNode, 0, 0, 0)
			return
		end
	else
		setTranslation(self.cameraRootNode, 0, 0, -self.currentZoomDistance)
		return
	end
end

-- Local values: targetZoomDistance, snapToDistance, zoom
function PlayerCamera:applyZoom(dt)
	if self.isFirstPerson then
		return
	else
		self:applyTerrainHeightCorrection()
		local v162_, v163_ = self:calculateCollisionZoom()
		if v163_ then
			self:setCurrentZoomDistance(v162_)
		elseif self.currentZoomDistance ~= v162_ then
			self:setCurrentZoomDistance(v162_ + math.pow(0.99579, dt) * (self.currentZoomDistance - v162_))
		end
	end
end

-- Local values: iterationsCount, i, cameraPositionX, cameraPositionY, cameraPositionZ, _, focusPositionY, _, terrainHeight, waterHeight, height, minimumHeight, pitchSine, newPitch, _, currentYaw, currentRoll
function PlayerCamera:applyTerrainHeightCorrection()
	if self:getIsTerrainCorrectionEnabled() then
		for _ = 1, 4 do
			local v165_, v166_, v167_ = self:getCameraPosition()
			local _, v168_, _ = self:getFocusPosition()
			local v169_ = getTerrainHeightAtWorldPos(g_terrainNode, v165_, v166_, v167_)
			local v170_ = g_currentMission.environmentAreaSystem:getWaterYAtWorldPosition(v165_, v166_ + 15, v167_)
			if v170_ ~= nil then
				v169_ = math.max(v170_, v169_)
			end
			local v171_ = v169_ + 0.2
			if v171_ <= v166_ then
				return
			end
			local v172_ = (v171_ - v168_) / self:getCurrentZoomDistance()
			local v173_ = math.clamp(v172_, -1, 1)
			local v174_ = math.asin(v173_)
			local v175_ = PlayerCamera.LOWEST_PITCH
			local v176_ = PlayerCamera.HIGHEST_PITCH
			local v177_ = math.clamp(v174_, v175_, v176_)
			local _, v178_, v179_ = self:getRotation()
			self:setRotation(v177_, v178_, v179_)
		end
	end
end

-- Local values: originX, originY, originZ, directionX, directionY, directionZ, currentZoomDistance, newZoomDistance, snapToDistance
function PlayerCamera:calculateCollisionZoom()
	if not self:getIsCollisionEnabled() then
		return self.desiredZoomDistance, false
	end
	local v181_, v182_, v183_ = self:getFocusPosition()
	local v184_, v185_, v186_ = localDirectionToWorld(self.cameraRootNode, 0, 0, 1)
	raycastClosestAsync(v181_, v182_, v183_, v184_, v185_, v186_, self.desiredZoomDistance, "distanceRaycastCallback", self, self:getCollisionMask())
	if self.lastCollisionDistance == nil then
		return self.desiredZoomDistance, false
	end
	local v187_ = self:getCurrentZoomDistance()
	local v188_ = self.desiredZoomDistance
	local v189_ = self.lastCollisionDistance - self.lastDistanceOffset
	local v190_ = math.min(v188_, v189_)
	local v191_
	if v190_ < v187_ then
		v191_ = true
	else
		local v192_ = v187_ - v190_
		v191_ = math.abs(v192_) <= 0.025
	end
	return v190_, v191_
end

-- Local values: rayDirectionX, rayDirectionY, rayDirectionZ, dotProduct, absoluteDotProduct, distanceOffset
function PlayerCamera:distanceRaycastCallback(nodeId, x, y, z, distance, nx, ny, nz, subShapeIndex, shapeId, isLast)
	if nodeId == nil or nodeId == 0 then
		self.lastCollisionDistance = nil
		self.lastDistanceOffset = nil
	else
		self.lastCollisionDistance = distance
		local v199_, v200_, v201_ = localDirectionToWorld(self.cameraRootNode, 0, 0, 1)
		local v202_ = MathUtil.dotProduct(nx, ny, nz, v199_, v200_, v201_)
		local v203_ = math.abs(v202_)
		self.lastDistanceOffset = MathUtil.lerp(0.4, 0.1, v203_ * v203_ * (3 - 2 * v203_))
	end
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

-- Local values: originX, originY, originZ, rotationX, rotationY, rotationZ
function PlayerCamera:debugDraw(x, y, textSize)
	local v209_ = DebugUtil.renderTextLine(x, y, textSize * 1.5, "Camera", nil, true)
	local v210_, v211_, v212_ = self:getFocusPosition()
	local v213_ = DebugUtil.renderTextLine(x, v209_, textSize, string.format("Focus position: %.2fm, %.2fm, %.2fm", v210_, v211_, v212_))
	local v214_ = DebugUtil.renderTextLine(x, v213_, textSize, string.format("Current zoom: %.2fm", self.currentZoomDistance))
	local v215_ = DebugUtil.renderTextLine(x, v214_, textSize, string.format("Current offset: %.2fm", self.lastDistanceOffset or 0))
	local v216_ = DebugUtil.renderTextLine(x, v215_, textSize, string.format("Collision distance: %.2fm", self.lastCollisionDistance or 0))
	local v217_, v218_, v219_ = self:getRotation()
	local v220_ = DebugUtil.renderTextLine(x, v216_, textSize, string.format("Pitch: %.2f\194\176, Yaw: %.2f\194\176, Roll: %.2f\194\176", math.deg(v217_), math.deg(v218_), (math.deg(v219_))))
	DebugUtil.drawDebugNode(self.yawNode, "yaw")
	return v220_
end
