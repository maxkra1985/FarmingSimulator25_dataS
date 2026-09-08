-- Local values: GuiTopDownCamera_mt
GuiTopDownCamera = {}
local GuiTopDownCamera_mt = Class(GuiTopDownCamera)
GuiTopDownCamera.TERRAIN_BORDER = 40
GuiTopDownCamera.INPUT_MOVE_FACTOR = 0.88
GuiTopDownCamera.MOVE_SPEED = 0.01
GuiTopDownCamera.MOVE_SPEED_FACTOR_NEAR = 1
GuiTopDownCamera.MOVE_SPEED_FACTOR_FAR = 64
GuiTopDownCamera.ROTATION_SPEED = 0.0005
GuiTopDownCamera.ROTATION_MIN_X_NEAR = 10
GuiTopDownCamera.ROTATION_MAX_X_NEAR = 90
GuiTopDownCamera.ROTATION_MIN_X_FAR = 50
GuiTopDownCamera.ROTATION_MAX_X_FAR = 90
GuiTopDownCamera.DISTANCE_MIN_Z = -10
GuiTopDownCamera.DISTANCE_RANGE_Z = -420
GuiTopDownCamera.GROUND_DISTANCE_MIN_Y = 2
GuiTopDownCamera.CAMERA_TERRAIN_OFFSET = 2
GuiTopDownCamera.CAMERA_ZOOM_FACTOR_MIN = 0.05
GuiTopDownCamera.CAMERA_ZOOM_FACTOR = 0.3
GuiTopDownCamera.COLLISION_MASK = CollisionMask.ALL - CollisionFlag.TRIGGER - CollisionFlag.GROUND_TIP_BLOCKING - CollisionFlag.TERRAIN_DISPLACEMENT

-- Upvalues: GuiTopDownCamera_mt
-- Local values: self
function GuiTopDownCamera.new(subclass_mt)
	-- upvalues: (copy) GuiTopDownCamera_mt
	local v3_ = subclass_mt or GuiTopDownCamera_mt
	local v4_ = setmetatable({}, v3_)
	v4_.hud = nil
	v4_.terrainRootNode = nil
	v4_.terrainSize = 0
	v4_.previousCamera = nil
	local v5_, v6_ = v4_:createCameraNodes()
	v4_.camera = v5_
	v4_.cameraBaseNode = v6_
	g_cameraManager:addCamera(v4_.camera, nil, false)
	v4_.isActive = false
	v4_.cameraX = 0
	v4_.targetCameraX = 0
	v4_.cameraZ = 0
	v4_.targetCameraZ = 0
	v4_.cameraRotY = 0.7853981633974483
	v4_.targetRotation = v4_.cameraRotY
	v4_.isMouseEdgeScrollingActive = true
	v4_.isMouseMode = false
	v4_.mousePosX = 0.5
	v4_.mousePosY = 0.5
	v4_.tiltFactor = 0.5
	v4_.targetTiltFactor = 0.5
	v4_.zoomFactor = 0.3
	v4_.targetZoomFactor = 0.3
	v4_.isCatchingCursor = false
	v4_.lastActionFrame = 0
	v4_.inputZoom = 0
	v4_.inputMoveSide = 0
	v4_.inputMoveForward = 0
	v4_.inputRotate = 0
	v4_.inputTilt = 0
	v4_.eventMoveSide = nil
	v4_.eventMoveForward = nil
	v4_.movementDisabledForGamepad = false
	v4_.edgeScrollingOffset = {
		0,
		0,
		1,
		1
	}
	return v4_
end

-- Local values: camera, cameraBaseNode
function GuiTopDownCamera:createCameraNodes()
	local v7_ = createCamera("TopDownCamera", 1.0471975511965976, 1, 10000)
	local v8_ = createTransformGroup("topDownCameraBaseNode")
	link(v8_, v7_)
	setRotation(v7_, 0, 3.141592653589793, 0)
	setTranslation(v7_, 0, 0, -5)
	setRotation(v8_, 0, 0, 0)
	setTranslation(v8_, 0, 110, 0)
	setFastShadowUpdate(v7_, true)
	return v7_, v8_
end

function GuiTopDownCamera:delete()
	if self.isActive then
		self:deactivate()
	end
	g_cameraManager:removeCamera(self.camera)
	delete(self.cameraBaseNode)
	self.camera = nil
	self.cameraBaseNode = nil
	self:reset()
end

function GuiTopDownCamera:reset()
	self.terrainRootNode = nil
	self.terrainSize = 0
	self.previousCamera = nil
	self.isCatchingCursor = false
end

function GuiTopDownCamera:setTerrainRootNode(terrainRootNode)
	self.terrainRootNode = terrainRootNode
	self.terrainSize = getTerrainSize(self.terrainRootNode)
end

-- Local values: x, _y, z
function GuiTopDownCamera:activate()
	g_inputBinding:setShowMouseCursor(true)
	self:onInputModeChanged({ g_inputBinding:getLastInputMode() })
	self:updatePosition()
	self.previousCamera = g_cameraManager:getActiveCamera()
	g_cameraManager:setActiveCamera(self.camera)
	local v14_, _, v15_ = g_localPlayer:getPosition()
	self:setCameraPosition(v14_, v15_)
	self:registerActionEvents()
	g_messageCenter:subscribe(MessageType.INPUT_MODE_CHANGED, self.onInputModeChanged, self)
	self.isActive = true
end

function GuiTopDownCamera:deactivate()
	self.isActive = false
	g_messageCenter:unsubscribeAll(self)
	self:removeActionEvents()
	g_inputBinding:setShowMouseCursor(false)
	if self.previousCamera ~= nil then
		g_cameraManager:setActiveCamera(self.previousCamera)
	end
	self.previousCamera = nil
end

function GuiTopDownCamera:getIsActive()
	return self.isActive
end

function GuiTopDownCamera:setCameraPosition(mapX, mapZ)
	self.cameraX = mapX
	self.cameraZ = mapZ
	self.targetCameraX = mapX
	self.targetCameraZ = mapZ
	self:updatePosition()
end

function GuiTopDownCamera:determineMapPosition()
	return self.cameraX, 0, self.cameraZ, self.cameraRotY - 3.141592653589793, 0
end

function GuiTopDownCamera:getPickRay()
	return RaycastUtil.getCameraPickingRay(self.mousePosX, self.mousePosY, self.camera)
end

-- Local values: samplingGridStep, cameraTargetHeight, x, z, sampleTerrainHeight, rotMin, rotMax, rotationX, cameraZ, cameraX, cameraY, terrainHeight, x, z, y, hit, _, hitY, _
function GuiTopDownCamera:updatePosition()
	local v24_ = 0
	for v25_ = -2, 2, 2 do
		for v26_ = -2, 2, 2 do
			local v27_ = getTerrainHeightAtWorldPos(self.terrainRootNode, self.cameraX + v25_, 0, self.cameraZ + v26_)
			v24_ = math.max(v24_, v27_)
		end
	end
	local v28_ = v24_ + GuiTopDownCamera.CAMERA_TERRAIN_OFFSET
	local v29_ = GuiTopDownCamera.ROTATION_MIN_X_NEAR + (GuiTopDownCamera.ROTATION_MIN_X_FAR - GuiTopDownCamera.ROTATION_MIN_X_NEAR) * self.zoomFactor
	local v30_ = math.rad(v29_)
	local v31_ = GuiTopDownCamera.ROTATION_MAX_X_NEAR + (GuiTopDownCamera.ROTATION_MAX_X_FAR - GuiTopDownCamera.ROTATION_MAX_X_NEAR) * self.zoomFactor
	local v32_ = v30_ + (math.rad(v31_) - v30_) * self.tiltFactor
	local v33_ = GuiTopDownCamera.DISTANCE_MIN_Z + self.zoomFactor * GuiTopDownCamera.DISTANCE_RANGE_Z
	setTranslation(self.camera, 0, 0, v33_)
	setRotation(self.cameraBaseNode, v32_, self.cameraRotY, 0)
	setTranslation(self.cameraBaseNode, self.cameraX, v28_, self.cameraZ)
	local v34_, v35_, v36_ = getWorldTranslation(self.camera)
	local v37_ = 0
	for v38_ = -2, 2, 2 do
		for v39_ = -2, 2, 2 do
			local v40_ = getTerrainHeightAtWorldPos(self.terrainRootNode, v34_ + v38_, 0, v36_ + v39_)
			local v41_, _, v42_, _ = RaycastUtil.raycastClosest(v34_ + v38_, v40_ + 100, v36_ + v39_, 0, -1, 0, 100, GuiTopDownCamera.COLLISION_MASK)
			if not v41_ then
				v42_ = v40_
			end
			v37_ = math.max(v37_, v42_)
		end
	end
	if v35_ < v37_ + GuiTopDownCamera.GROUND_DISTANCE_MIN_Y then
		local v43_ = v28_ + (v37_ - v35_ + GuiTopDownCamera.GROUND_DISTANCE_MIN_Y)
		setTranslation(self.cameraBaseNode, self.cameraX, v43_, self.cameraZ)
	end
end

-- Local values: xChange, zChange, zoomChange, tiltChange, rotateChange
function GuiTopDownCamera:applyMovement(dt)
	local v46_ = (self.targetCameraX - self.cameraX) / dt * 5
	if v46_ < 0.0001 and v46_ > -0.0001 then
		self.cameraX = self.targetCameraX
	else
		self.cameraX = self.cameraX + v46_
	end
	local v47_ = (self.targetCameraZ - self.cameraZ) / dt * 5
	if v47_ < 0.0001 and v47_ > -0.0001 then
		self.cameraZ = self.targetCameraZ
	else
		self.cameraZ = self.cameraZ + v47_
	end
	local v48_ = (self.targetZoomFactor - self.zoomFactor) / dt * 2
	if v48_ < 0.0001 and v48_ > -0.0001 then
		self.zoomFactor = self.targetZoomFactor
	else
		local v49_ = self.zoomFactor + v48_
		self.zoomFactor = math.clamp(v49_, 0, 1)
	end
	local v50_ = (self.targetTiltFactor - self.tiltFactor) / dt * 5
	if v50_ < 0.0001 and v50_ > -0.0001 then
		self.tiltFactor = self.targetTiltFactor
	else
		local v51_ = self.tiltFactor + v50_
		self.tiltFactor = math.clamp(v51_, 0, 1)
	end
	local v52_ = (self.targetRotation - self.cameraRotY) / dt * 5
	if v52_ < 0.0001 and v52_ > -0.0001 then
		self.cameraRotY = self.targetRotation
	else
		self.cameraRotY = self.cameraRotY + v52_
	end
end

function GuiTopDownCamera:setMouseEdgeScrollingActive(isActive)
	self.isMouseEdgeScrollingActive = isActive
end

function GuiTopDownCamera:setEdgeScrollingOffset(xMin, yMin, xMax, yMax)
	self.edgeScrollingOffset[1] = xMin or self.edgeScrollingOffset[1]
	self.edgeScrollingOffset[2] = yMin or self.edgeScrollingOffset[2]
	self.edgeScrollingOffset[3] = xMax or self.edgeScrollingOffset[3]
	self.edgeScrollingOffset[4] = yMax or self.edgeScrollingOffset[4]
end

-- Local values: moveMarginStartX, moveMarginStartY, moveMarginEndX, moveMarginEndY, moveX, moveZ
function GuiTopDownCamera:getMouseEdgeScrollingMovement()
	local v61_ = 0
	local v62_ = 0
	if self.mousePosX >= self.edgeScrollingOffset[3] - 0.015 and self.mousePosX <= self.edgeScrollingOffset[3] then
		local v63_ = (0.015 - (self.edgeScrollingOffset[3] - self.mousePosX)) / 0.005000000000000001
		v61_ = math.min(v63_, 1)
	elseif self.mousePosX <= self.edgeScrollingOffset[1] + 0.02 and self.mousePosX >= self.edgeScrollingOffset[1] then
		local v64_ = (0.02 - self.edgeScrollingOffset[1] + self.mousePosX) / 0.005000000000000001
		v61_ = -math.min(v64_, 1)
	end
	if self.mousePosY >= self.edgeScrollingOffset[4] - 0.015 and self.mousePosY <= self.edgeScrollingOffset[4] then
		local v65_ = (0.015 - (self.edgeScrollingOffset[4] - self.mousePosY)) / 0.005000000000000001
		return v61_, math.min(v65_, 1)
	else
		if self.mousePosY <= self.edgeScrollingOffset[2] + 0.02 and self.mousePosY >= self.edgeScrollingOffset[2] then
			local v66_ = (0.02 - self.edgeScrollingOffset[2] + self.mousePosY) / 0.005000000000000001
			v62_ = -math.min(v66_, 1)
		end
		return v61_, v62_
	end
end

function GuiTopDownCamera:setMovementDisabledForGamepad(disabled)
	self.movementDisabledForGamepad = disabled
end

function GuiTopDownCamera:update(dt)
	if self.isActive and (self.isMouseMode or not self.movementDisabledForGamepad) then
		self:updateMovement(dt)
		self:resetInputState()
	end
end

-- Local values: moveX, moveZ, zoomMovementSpeedFactor, dirX, dirZ, moveFactor, newTargetPosX, newTargetPosZ
function GuiTopDownCamera:updateMovement(dt)
	local v73_ = self.targetZoomFactor - self.inputZoom * 0.2
	self.targetZoomFactor = math.clamp(v73_, 0, 1)
	self.targetRotation = self.targetRotation + dt * self.inputRotate * GuiTopDownCamera.ROTATION_SPEED
	local v74_ = self.targetTiltFactor + self.inputTilt * dt * GuiTopDownCamera.ROTATION_SPEED
	self.targetTiltFactor = math.clamp(v74_, 0, 1)
	local v75_ = self.inputMoveSide * dt
	local v76_ = -self.inputMoveForward * dt
	if v75_ == 0 and (v76_ == 0 and self.isMouseEdgeScrollingActive) then
		v75_, v76_ = self:getMouseEdgeScrollingMovement()
	end
	local v77_ = GuiTopDownCamera.MOVE_SPEED_FACTOR_NEAR + self.zoomFactor * (GuiTopDownCamera.MOVE_SPEED_FACTOR_FAR - GuiTopDownCamera.MOVE_SPEED_FACTOR_NEAR)
	local v78_ = v75_ * v77_
	local v79_ = v76_ * v77_
	local v80_ = self.cameraRotY
	local v81_ = math.sin(v80_) * v79_
	local v82_ = self.cameraRotY
	local v83_ = v81_ + math.cos(v82_) * -v78_
	local v84_ = self.cameraRotY
	local v85_ = math.cos(v84_) * v79_
	local v86_ = self.cameraRotY
	local v87_ = v85_ - math.sin(v86_) * -v78_
	local v88_ = dt * GuiTopDownCamera.MOVE_SPEED
	local v89_ = self.targetCameraX + v83_ * v88_
	local v90_ = self.targetCameraZ + v87_ * v88_
	local v91_, v92_ = g_currentMission.placeableSystem:limitPositionToBoundary(v89_, v90_)
	self.targetCameraX = v91_
	self.targetCameraZ = v92_
	self:applyMovement(dt)
	self:updatePosition()
end

function GuiTopDownCamera:setCursorLocked(locked)
	self.cursorLocked = locked
end

function GuiTopDownCamera:mouseEvent(posX, posY, isDown, isUp, button)
	if self.lastActionFrame >= g_time or self.cursorLocked then
		return
	elseif self.isCatchingCursor then
		self.isCatchingCursor = false
		g_inputBinding:setShowMouseCursor(true)
		wrapMousePosition(0.5, 0.5)
		self.mousePosX = 0.5
		self.mousePosY = 0.5
	elseif self.isMouseMode then
		self.mousePosX = posX
		self.mousePosY = posY
	end
end

function GuiTopDownCamera:resetInputState()
	self.inputZoom = 0
	self.inputMoveSide = 0
	self.inputMoveForward = 0
	self.inputTilt = 0
	self.inputRotate = 0
end

-- Local values: _, eventId
function GuiTopDownCamera:registerActionEvents()
	local _, v100_ = g_inputBinding:registerActionEvent(InputAction.AXIS_MOVE_SIDE_PLAYER, self, self.onMoveSide, false, false, true, true)
	g_inputBinding:setActionEventTextPriority(v100_, GS_PRIO_VERY_LOW)
	g_inputBinding:setActionEventTextVisibility(v100_, false)
	self.eventMoveSide = v100_
	local _, v101_ = g_inputBinding:registerActionEvent(InputAction.AXIS_MOVE_FORWARD_PLAYER, self, self.onMoveForward, false, false, true, true)
	g_inputBinding:setActionEventTextPriority(v101_, GS_PRIO_VERY_LOW)
	g_inputBinding:setActionEventTextVisibility(v101_, false)
	self.eventMoveForward = v101_
	local _, v102_ = g_inputBinding:registerActionEvent(InputAction.AXIS_CONSTRUCTION_CAMERA_ZOOM, self, self.onZoom, false, false, true, true)
	g_inputBinding:setActionEventTextPriority(v102_, GS_PRIO_LOW)
	local _, v103_ = g_inputBinding:registerActionEvent(InputAction.AXIS_CONSTRUCTION_CAMERA_ROTATE, self, self.onRotate, false, false, true, true)
	g_inputBinding:setActionEventTextPriority(v103_, GS_PRIO_LOW)
	local _, v104_ = g_inputBinding:registerActionEvent(InputAction.AXIS_CONSTRUCTION_CAMERA_TILT, self, self.onTilt, false, false, true, true)
	g_inputBinding:setActionEventTextPriority(v104_, GS_PRIO_LOW)
end

function GuiTopDownCamera:removeActionEvents()
	g_inputBinding:removeActionEventsByTarget(self)
end

-- Local values: change
function GuiTopDownCamera:onZoom(_, inputValue, _, isAnalog, isMouse)
	if not (isMouse and self.mouseDisabled) then
		local v110_ = GuiTopDownCamera.CAMERA_ZOOM_FACTOR * self.zoomFactor
		local v111_ = GuiTopDownCamera.CAMERA_ZOOM_FACTOR_MIN
		local v112_ = math.max(v110_, v111_) * inputValue
		if isAnalog then
			v112_ = v112_ * 0.5
		elseif isMouse then
			v112_ = v112_ * InputBinding.MOUSE_WHEEL_INPUT_FACTOR
		end
		self.inputZoom = v112_
	end
end

function GuiTopDownCamera:onMoveSide(_, inputValue)
	self.inputMoveSide = inputValue * GuiTopDownCamera.INPUT_MOVE_FACTOR / g_currentDt
end

function GuiTopDownCamera:onMoveForward(_, inputValue)
	self.inputMoveForward = inputValue * GuiTopDownCamera.INPUT_MOVE_FACTOR / g_currentDt
end

function GuiTopDownCamera:onRotate(_, inputValue, _, isAnalog, isMouse)
	if not (isMouse and self.mouseDisabled) then
		if isMouse and inputValue ~= 0 then
			self.lastActionFrame = g_time
			if not self.isCatchingCursor then
				g_inputBinding:setShowMouseCursor(false)
				self.isCatchingCursor = true
			end
		end
		if isMouse and isAnalog then
			inputValue = inputValue * 3
		end
		self.inputRotate = -inputValue * 3 / g_currentDt * 16
	end
end

function GuiTopDownCamera:onTilt(_, inputValue, _, isAnalog, isMouse)
	if not (isMouse and self.mouseDisabled) then
		if isMouse and inputValue ~= 0 then
			self.lastActionFrame = g_time
			if not self.isCatchingCursor then
				g_inputBinding:setShowMouseCursor(false)
				self.isCatchingCursor = true
			end
		end
		if isMouse and isAnalog then
			inputValue = inputValue * 3
		end
		self.inputTilt = inputValue * 3
	end
end

function GuiTopDownCamera:onInputModeChanged(inputMode)
	self.isMouseMode = inputMode[1] == GS_INPUT_HELP_MODE_KEYBOARD
	if not self.isMouseMode then
		self.mousePosX = 0.5
		self.mousePosY = 0.5
	end
end
