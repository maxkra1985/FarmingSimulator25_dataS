source("dataS/scripts/handTools/events/HandsPickUpObjectEvent.lua")
source("dataS/scripts/handTools/events/HandsThrowObjectEvent.lua")
source("dataS/scripts/handTools/events/HandsPickUpFailedEvent.lua")
HandToolHands = {}
HandToolHands.TARGET_MASK = CollisionFlag.DYNAMIC_OBJECT + CollisionFlag.TREE + CollisionFlag.VEHICLE
HandToolHands.MAXIMUM_PICKUP_MASS = 0.2
HandToolHands.SUPER_STRENGTH_PICKUP_MASS = 500
HandToolHands.PICKUP_DISTANCE = 2
HandToolHands.MAXIMUM_THROW_TIME = 1200
HandToolHands.MINIMUM_THROW_CHARGE_DISTANCE = 1.5
HandToolHands.KINEMATIC_NODE_DIRECTION_NUM_BITS = 12
HandToolHands.FOOTBALL_DETECTION_RADIUS = 1.5
HandToolHands.FOOTBALL_DRIBBLE_MAX_DISTANCE = 0.75
HandToolHands.FOOTBALL_DRIBBLE_MIN_DISTANCE = 0.35
HandToolHands.FOOTBALL_SHOOT_THRESHOLD = 500
HandToolHands.FOOTBALL_DRIBBLE_VELOCITY = 5
HandToolHands.FOOTBALL_PASS_VELOCITY = 12
HandToolHands.FOOTBALL_SHOT_VELOCITY = 15
function HandToolHands.registerXMLPaths(xmlSchema)
	xmlSchema:setXMLSpecializationType("HandToolHands")
	xmlSchema:setXMLSpecializationType()
end
function HandToolHands.registerFunctions(handToolType)
	SpecializationUtil.registerFunction(handToolType, "updateKinematicNode", HandToolHands.updateKinematicNode)
	SpecializationUtil.registerFunction(handToolType, "getKinematicNode", HandToolHands.getKinematicNode)
	SpecializationUtil.registerFunction(handToolType, "getIsHoldingItem", HandToolHands.getIsHoldingItem)
	SpecializationUtil.registerFunction(handToolType, "getIsThrowingItem", HandToolHands.getIsThrowingItem)
	SpecializationUtil.registerFunction(handToolType, "getIsAwaitingJointCreation", HandToolHands.getIsAwaitingJointCreation)
	SpecializationUtil.registerFunction(handToolType, "getHasJoint", HandToolHands.getHasJoint)
	SpecializationUtil.registerFunction(handToolType, "getHeldItem", HandToolHands.getHeldItem)
	SpecializationUtil.registerFunction(handToolType, "getCanPickUpNode", HandToolHands.getCanPickUpNode)
	SpecializationUtil.registerFunction(handToolType, "orientRotationNodeToItem", HandToolHands.orientRotationNodeToItem)
	SpecializationUtil.registerFunction(handToolType, "createItemJoint", HandToolHands.createItemJoint)
	SpecializationUtil.registerFunction(handToolType, "pickUpTarget", HandToolHands.pickUpTarget)
	SpecializationUtil.registerFunction(handToolType, "pickupFailed", HandToolHands.pickupFailed)
	SpecializationUtil.registerFunction(handToolType, "dropHeldItem", HandToolHands.dropHeldItem)
	SpecializationUtil.registerFunction(handToolType, "throwHeldItemWithForceScalar", HandToolHands.throwHeldItemWithForceScalar)
	SpecializationUtil.registerFunction(handToolType, "throwHeldItemWithForceVector", HandToolHands.throwHeldItemWithForceVector)
	SpecializationUtil.registerFunction(handToolType, "rotateHeldItem", HandToolHands.rotateHeldItem)
	SpecializationUtil.registerFunction(handToolType, "levelHeldItem", HandToolHands.levelHeldItem)
	SpecializationUtil.registerFunction(handToolType, "onHeldItemJointBroken", HandToolHands.onHeldItemJointBroken)
	SpecializationUtil.registerFunction(handToolType, "findFootballCallback", HandToolHands.findFootballCallback)
	SpecializationUtil.registerFunction(handToolType, "shootBall", HandToolHands.shootBall)
	SpecializationUtil.registerFunction(handToolType, "consoleCommandToggleSuperStrength", HandToolHands.consoleCommandToggleSuperStrength)
end
function HandToolHands.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanBeDropped", HandToolHands.getCanBeDropped)
end
function HandToolHands.registerEventListeners(handToolType)
	SpecializationUtil.registerEventListener(handToolType, "onLoad", HandToolHands)
	SpecializationUtil.registerEventListener(handToolType, "onDelete", HandToolHands)
	SpecializationUtil.registerEventListener(handToolType, "onUpdate", HandToolHands)
	SpecializationUtil.registerEventListener(handToolType, "onDraw", HandToolHands)
	SpecializationUtil.registerEventListener(handToolType, "onWriteUpdateStream", HandToolHands)
	SpecializationUtil.registerEventListener(handToolType, "onReadUpdateStream", HandToolHands)
	SpecializationUtil.registerEventListener(handToolType, "onRegisterActionEvents", HandToolHands)
	SpecializationUtil.registerEventListener(handToolType, "onCarryingPlayerChanged", HandToolHands)
	SpecializationUtil.registerEventListener(handToolType, "onHeldStart", HandToolHands)
	SpecializationUtil.registerEventListener(handToolType, "onHeldEnd", HandToolHands)
	SpecializationUtil.registerEventListener(handToolType, "onDebugDraw", HandToolHands)
end
function HandToolHands.prerequisitesPresent(specializations)
	return true
end
function HandToolHands:onLoad(xmlFile, baseDirectory)
	local spec = self.spec_hands
	spec.hasSuperStrength = false
	spec.currentMaximumMass = HandToolHands.MAXIMUM_PICKUP_MASS
	spec.pickupDistance = HandToolHands.PICKUP_DISTANCE
	spec.currentThrowTime = nil
	spec.pickUpActionEventId = nil
	spec.throwActionEventId = nil
	spec.pitchActionEventId = nil
	spec.yawActionEventId = nil
	spec.heldItemJointId = nil
	spec.heldItemNode = nil
	spec.currentHoldDistance = HandToolHands.PICKUP_DISTANCE
	spec.kinematicNode = nil
	spec.kinematicRotationNode = nil
	spec.lastThrowUpdateIndex = nil
	spec.pickupPhysicsIndex = nil
	spec.dirtyFlag = self:getNextDirtyFlag()
	spec.kinematicLoadingTask = self:createLoadingTask(spec)
	spec.kinematicSharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync("dataS/character/shared/kinematicHelper.i3d", true, false, HandToolHands.onKinematicHelperLoaded, self, nil)
	spec.lastShootTime = g_time
	spec.canShoot = false
	spec.football = nil
	spec.actionPassText = g_i18n:getText("action_passFootball")
	spec.actionShootText = g_i18n:getText("action_shootFootball")
	spec.pickupText = g_i18n:getText("action_pickUpObject")
	spec.throwText = g_i18n:getText("input_THROW_OBJECT")
	if self.isClient then
		spec.crosshair = self:createCrosshairOverlay("gui.crosshairDefault", HandTool.DEFAULT_CROSSHAIR_SIZE_PIXELS * 0.5)
		spec.crosshair:setColor(nil, nil, nil, 0.25)
		spec.pickUpCrosshair = self:createCrosshairOverlay("gui.grab")
		spec.throwCrosshair = self:createCrosshairOverlay("gui.crosshairThrow")
	end
end
function HandToolHands:onKinematicHelperLoaded(kinematicNode, failedReason)
	local spec = self.spec_hands
	self:finishLoadingTask(spec.kinematicLoadingTask)
	spec.kinematicLoadingTask = nil
	if kinematicNode == nil or kinematicNode == 0 then
		Logging.error("Hands could not load kinematic helper i3d!")
		return
	end
	spec.kinematicNode = getChildAt(kinematicNode, 0)
	link(getRootNode(), spec.kinematicNode)
	addToPhysics(spec.kinematicNode)
	spec.kinematicRotationNode = createTransformGroup("kinematicRotationHelper")
	link(spec.kinematicNode, spec.kinematicRotationNode)
	delete(kinematicNode)
end
function HandToolHands:onDelete()
	local spec = self.spec_hands
	self:dropHeldItem(true)
	if spec.kinematicSharedLoadRequestId ~= nil then
		g_i3DManager:releaseSharedI3DFile(spec.kinematicSharedLoadRequestId)
		spec.kinematicSharedLoadRequestId = nil
	end
	if spec.kinematicNode ~= nil then
		delete(spec.kinematicNode)
		spec.kinematicNode = nil
	end
	local player = self:getCarryingPlayer()
	if player ~= nil and player.isOwner then
		removeConsoleCommand("gsPlayerSuperStrengthToggle")
	end
	if spec.crosshair ~= nil then
		spec.crosshair:delete()
		spec.crosshair = nil
	end
	if spec.pickUpCrosshair ~= nil then
		spec.pickUpCrosshair:delete()
		spec.pickUpCrosshair = nil
	end
	if spec.throwCrosshair ~= nil then
		spec.throwCrosshair:delete()
		spec.throwCrosshair = nil
	end
end
function HandToolHands:onWriteUpdateStream(streamId, connection, dirtyMask)
	if connection:getIsServer() then
		local spec = self.spec_hands
		if streamWriteBool(streamId, bit32.btest(dirtyMask, spec.dirtyFlag)) then
			local kinematicNode, kinematicRotationNode = self:getKinematicNode()
			local kinematicNodePitch, kinematicNodeYaw, kinematicNodeRoll = getWorldRotation(kinematicRotationNode)
			local kinematicNodePositionX, kinematicNodePositionY, kinematicNodePositionZ = getWorldTranslation(kinematicNode)
			local kinematicNodeDirectionX, _, kinematicNodeDirectionZ = localDirectionToWorld(kinematicNode, 0, 0, 1)
			kinematicNodeDirectionX, kinematicNodeDirectionZ = MathUtil.vector2Normalize(kinematicNodeDirectionX, kinematicNodeDirectionZ)
			local paramsXZ = g_currentMission.vehicleXZPosCompressionParams
			local paramsY = g_currentMission.vehicleYPosCompressionParams
			NetworkUtil.writeCompressedWorldPosition(streamId, kinematicNodePositionX, paramsXZ)
			NetworkUtil.writeCompressedWorldPosition(streamId, kinematicNodePositionY, paramsY)
			NetworkUtil.writeCompressedWorldPosition(streamId, kinematicNodePositionZ, paramsXZ)
			NetworkUtil.writeCompressedRange(streamId, kinematicNodeDirectionX, -1, 1, HandToolHands.KINEMATIC_NODE_DIRECTION_NUM_BITS)
			NetworkUtil.writeCompressedRange(streamId, kinematicNodeDirectionZ, -1, 1, HandToolHands.KINEMATIC_NODE_DIRECTION_NUM_BITS)
			NetworkUtil.writeCompressedAngle(streamId, kinematicNodePitch)
			NetworkUtil.writeCompressedAngle(streamId, kinematicNodeYaw)
			NetworkUtil.writeCompressedAngle(streamId, kinematicNodeRoll)
		end
	end
end
function HandToolHands:onReadUpdateStream(streamId, timestamp, connection)
	if not connection:getIsServer() and streamReadBool(streamId) then
		local kinematicNode, kinematicRotationNode = self:getKinematicNode()
		local paramsXZ = g_currentMission.vehicleXZPosCompressionParams
		local paramsY = g_currentMission.vehicleYPosCompressionParams
		local kinematicNodePositionX = NetworkUtil.readCompressedWorldPosition(streamId, paramsXZ)
		local kinematicNodePositionY = NetworkUtil.readCompressedWorldPosition(streamId, paramsY)
		local kinematicNodePositionZ = NetworkUtil.readCompressedWorldPosition(streamId, paramsXZ)
		local kinematicNodeDirectionX = NetworkUtil.readCompressedRange(streamId, -1, 1, HandToolHands.KINEMATIC_NODE_DIRECTION_NUM_BITS)
		local kinematicNodeDirectionZ = NetworkUtil.readCompressedRange(streamId, -1, 1, HandToolHands.KINEMATIC_NODE_DIRECTION_NUM_BITS)
		local kinematicNodePitch = NetworkUtil.readCompressedAngle(streamId)
		local kinematicNodeYaw = NetworkUtil.readCompressedAngle(streamId)
		local kinematicNodeRoll = NetworkUtil.readCompressedAngle(streamId)
		setWorldTranslation(kinematicNode, kinematicNodePositionX, kinematicNodePositionY, kinematicNodePositionZ)
		setWorldDirection(kinematicNode, kinematicNodeDirectionX, 0, kinematicNodeDirectionZ, 0, 1, 0)
		setWorldRotation(kinematicRotationNode, kinematicNodePitch, kinematicNodeYaw, kinematicNodeRoll)
		if self:getHasJoint() then
			local spec = self.spec_hands
			setJointFrame(spec.heldItemJointId, 0, kinematicRotationNode)
		end
	end
end
function HandToolHands:onUpdate(dt)
	local carryingPlayer = self:getCarryingPlayer()
	if carryingPlayer == nil then
		return
	end
	if not self:getIsHeld() then
		return
	end
	local spec = self.spec_hands
	if self:getIsAwaitingJointCreation() and getIsPhysicsUpdateIndexSimulated(spec.pickupPhysicsIndex) then
		self:createItemJoint()
	end
	self:updateKinematicNode()
	if not carryingPlayer.isOwner then
		return
	else
		spec.canShoot = spec.lastShootTime + HandToolHands.FOOTBALL_SHOOT_THRESHOLD < g_time
		spec.football = nil
		if self:getIsHoldingItem() and (self.isServer and (spec.heldItemNode ~= nil and not entityExists(spec.heldItemNode))) then
			self:dropHeldItem()
		end
		if not self:getIsHoldingItem() then
			local targetNode = carryingPlayer.targeter:getClosestTargetedNodeFromType(HandToolHands)
			local canPickUpTarget = self:getCanPickUpNode(targetNode)
			if not canPickUpTarget then
				local mission = g_currentMission
				local object = mission:getNodeObject(targetNode)
				if object ~= nil and object:isa(Football) then
					spec.football = object
				end
				if spec.football == nil then
					local x, y, z = getWorldTranslation(carryingPlayer.graphicsComponent.graphicsRootNode)
					overlapSphere(x, y, z, HandToolHands.FOOTBALL_DETECTION_RADIUS, "findFootballCallback", self, CollisionFlag.DYNAMIC_OBJECT, true, false, false)
				end
			end
			local canShoot = false
			if spec.football ~= nil then
				canShoot = spec.canShoot
			end
			g_inputBinding:setActionEventActive(spec.pickUpActionEventId, canPickUpTarget or canShoot)
			g_inputBinding:setActionEventActive(spec.throwActionEventId, spec.heldItemNode or canShoot)
			if canShoot then
				g_inputBinding:setActionEventText(spec.pickUpActionEventId, spec.actionPassText)
				g_inputBinding:setActionEventText(spec.throwActionEventId, spec.actionShootText)
			else
				g_inputBinding:setActionEventText(spec.pickUpActionEventId, spec.pickupText)
				g_inputBinding:setActionEventText(spec.throwActionEventId, spec.throwText)
			end
		elseif self:getIsThrowingItem() then
			if spec.lastThrowUpdateIndex ~= nil and spec.lastThrowUpdateIndex ~= g_updateLoopIndex then
				local throwForceScalar = math.clamp(spec.currentThrowTime / HandToolHands.MAXIMUM_THROW_TIME, 0, 1)
				self:throwHeldItemWithForceScalar(throwForceScalar)
			end
		end
		if spec.football ~= nil and spec.canShoot then
			local footballNode = spec.football.nodeId
			local px, py, pz = getWorldTranslation(carryingPlayer.graphicsComponent.graphicsRootNode)
			local bx, by, bz = getWorldTranslation(footballNode)
			local distance = MathUtil.vector3Length(px - bx, py - by, pz - bz)
			if HandToolHands.FOOTBALL_DRIBBLE_MIN_DISTANCE < distance and distance < HandToolHands.FOOTBALL_DRIBBLE_MAX_DISTANCE then
				local camera = g_cameraManager:getActiveCamera()
				local dirX, _, dirZ = localDirectionToWorld(camera, 0, 0, -1)
				dirX, _, dirZ = MathUtil.vector3Normalize(dirX, 0, dirZ)
				self:shootBall(spec.football, dirX, dirZ, 0, HandToolHands.FOOTBALL_DRIBBLE_VELOCITY, Football.TYPE_DRIBBLE)
			end
		end
	end
end
function HandToolHands:onDraw()
	local spec = self.spec_hands
	local carryingPlayer = self:getCarryingPlayer()
	if carryingPlayer ~= nil and (carryingPlayer.isOwner and carryingPlayer.camera.isFirstPerson) then
		local player = self:getCarryingPlayer()
		local node = player.targeter.closestTargetsByKey[HandToolHands] and target.node or nil
		if self:getIsThrowingItem() then
			local throwForceScalar = math.clamp(spec.currentThrowTime / HandToolHands.MAXIMUM_THROW_TIME, 0, 1)
			spec.throwCrosshair:setScale(throwForceScalar, throwForceScalar)
			spec.throwCrosshair:render()
			return
		end
		if spec.heldItemNode ~= nil or self:getCanPickUpNode(node) then
			spec.pickUpCrosshair:render()
			return
		end
		spec.crosshair:render()
	end
end
function HandToolHands:onRegisterActionEvents()
	if not self:getIsActiveForInput(true) then
		return
	else
		local spec = self.spec_hands
		local _, actionEventId = self:addActionEvent(InputAction.ACTIVATE_HANDTOOL, self, HandToolHands.onPickUpAction, true, false, false, false, nil)
		g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_VERY_HIGH)
		g_inputBinding:setActionEventText(actionEventId, spec.pickupText)
		spec.pickUpActionEventId = actionEventId
		_, actionEventId = self:addActionEvent(InputAction.ACTIVATE_HANDTOOL_SECONDARY, self, HandToolHands.onThrowAction, false, true, true, false, nil)
		g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_VERY_HIGH)
		g_inputBinding:setActionEventText(actionEventId, spec.throwText)
		spec.throwActionEventId = actionEventId
		_, actionEventId = self:addActionEvent(InputAction.ROTATE_OBJECT_UP_DOWN, self, HandToolHands.onPitchAction, false, false, true, false, nil)
		g_inputBinding:setActionEventText(actionEventId, g_i18n:getText("action_rotateObjectVertically"))
		spec.pitchActionEventId = actionEventId
		_, actionEventId = self:addActionEvent(InputAction.ROTATE_OBJECT_LEFT_RIGHT, self, HandToolHands.onYawAction, false, false, true, false, nil)
		g_inputBinding:setActionEventText(actionEventId, g_i18n:getText("action_rotateObjectHorizontally"))
		spec.yawActionEventId = actionEventId
		_, actionEventId = self:addActionEvent(InputAction.HANDS_LEVEL_ITEM, self, HandToolHands.onLevelAction, true, false, false, false, nil)
		spec.levelActionEventId = actionEventId
	end
end
function HandToolHands:onHeldStart()
	local carryingPlayer = self:getCarryingPlayer()
	if carryingPlayer ~= nil and carryingPlayer.isOwner then
		local spec = self.spec_hands
		local targeter = self:getCarryingPlayer().targeter
		targeter:addTargetType(HandToolHands, HandToolHands.TARGET_MASK, 0.5, spec.pickupDistance)
	end
end
function HandToolHands:onHeldEnd()
	local carryingPlayer = self:getCarryingPlayer()
	if carryingPlayer ~= nil and carryingPlayer.isOwner then
		carryingPlayer.targeter:removeTargetType(HandToolHands)
		self:dropHeldItem()
	end
end
function HandToolHands:onCarryingPlayerChanged(player, lastPlayer)
	if player ~= nil and player.isOwner then
		addConsoleCommand("gsPlayerSuperStrengthToggle", "Toggles the super strength mode for the player", "consoleCommandToggleSuperStrength", self)
		return
	end
	if lastPlayer ~= nil and lastPlayer.isOwner then
		removeConsoleCommand("gsPlayerSuperStrengthToggle")
	end
end
function HandToolHands:getCanBeDropped(superFunc)
	return false
end
function HandToolHands:updateKinematicNode()
	local spec = self.spec_hands
	if spec.kinematicNode == nil then
		return
	end
	if not self:getIsHeld() then
		return
	end
	if not self:getCarryingPlayer().isOwner then
		return
	end
	local x, y, z, dx, dy, dz = self:getCarryingPlayer().targeter:getLastLookRay()
	if x == nil then
		return
	else
		self:raiseDirtyFlags(spec.dirtyFlag)
		x = x + dx * spec.currentHoldDistance
		y = y + dy * spec.currentHoldDistance
		z = z + dz * spec.currentHoldDistance
		setWorldTranslation(spec.kinematicNode, x, y, z)
		dx, dz = MathUtil.vector2Normalize(dx, dz)
		setWorldDirection(spec.kinematicNode, dx, 0, dz, 0, 1, 0)
	end
end
function HandToolHands:getKinematicNode()
	return self.spec_hands.kinematicNode, self.spec_hands.kinematicRotationNode
end
function HandToolHands:getIsHoldingItem()
	return self.spec_hands.heldItemNode ~= nil
end
function HandToolHands:getIsThrowingItem()
	return self.spec_hands.currentThrowTime ~= nil
end
function HandToolHands:getIsAwaitingJointCreation()
	return self.spec_hands.pickupPhysicsIndex ~= nil
end
function HandToolHands:getHasJoint()
	return self.spec_hands.heldItemJointId ~= nil
end
function HandToolHands:getHeldItem()
	return self.spec_hands.heldItemNode
end
function HandToolHands:getCanPickUpNode(node)
	if node == nil or node == 0 or not entityExists(node) then
		return false
	end
	if self.isServer and getRigidBodyType(node) ~= RigidBodyType.DYNAMIC then
		return false
	end
	if self:getIsHoldingItem() then
		return false
	else
		local spec = self.spec_hands
		local mass = HandToolHands.calculateItemMass(node)
		if self.isServer and (mass == nil or spec.currentMaximumMass < mass) then
			return false
		end
		local mission = g_currentMission
		local object = mission:getNodeObject(node)
		if object ~= nil then
			if object.dynamicMountObject ~= nil or object.tensionMountObject ~= nil then
				return false
			end
			if not spec.hasSuperStrength and (object.getCanBePickedUp ~= nil and not object:getCanBePickedUp(self:getCarryingPlayer())) then
				return false
			end
		end
		return true
	end
end
function HandToolHands:onPickUpAction(_, inputValue)
	local player = self:getCarryingPlayer()
	if not player.isOwner then
		return
	end
	local spec = self.spec_hands
	if spec.football ~= nil then
		local camera = g_cameraManager:getActiveCamera()
		local dirX, _, dirZ = localDirectionToWorld(camera, 0, 0, -1)
		dirX, _, dirZ = MathUtil.vector3Normalize(dirX, 0, dirZ)
		self:shootBall(spec.football, dirX, dirZ, 0, HandToolHands.FOOTBALL_PASS_VELOCITY, Football.TYPE_PASS)
	elseif self:getIsHoldingItem() then
		self:dropHeldItem()
	else
		local target = player.targeter.closestTargetsByKey[HandToolHands]
		self:pickUpTarget(target)
	end
end
function HandToolHands:onThrowAction(_, inputValue)
	local player = self:getCarryingPlayer()
	if not player.isOwner then
		return
	end
	local spec = self.spec_hands
	if spec.football ~= nil then
		local camera = g_cameraManager:getActiveCamera()
		local dirX, _, dirZ = localDirectionToWorld(camera, 0, 0, -1)
		dirX, _, dirZ = MathUtil.vector3Normalize(dirX, 0, dirZ)
		self:shootBall(spec.football, dirX, dirZ, 30, HandToolHands.FOOTBALL_SHOT_VELOCITY, Football.TYPE_SHOT)
	end
	if not self:getIsHoldingItem() then
		return
	end
	spec.lastThrowUpdateIndex = g_updateLoopIndex
	if spec.currentThrowTime == nil then
		spec.currentThrowTime = 0
	else
		spec.currentThrowTime = spec.currentThrowTime + g_currentDt
	end
end
function HandToolHands:onPitchAction(_, inputDelta)
	local kinematicNode, rotationNode = self:getKinematicNode()
	local directionX, directionY, directionZ = localDirectionToLocal(kinematicNode, rotationNode, 1, 0, 0)
	self:rotateHeldItem(inputDelta, directionX, directionY, directionZ)
end
function HandToolHands:onYawAction(_, inputDelta)
	local kinematicNode, rotationNode = self:getKinematicNode()
	local directionX, directionY, directionZ = localDirectionToLocal(kinematicNode, rotationNode, 0, 1, 0)
	self:rotateHeldItem(inputDelta, directionX, directionY, directionZ)
end
function HandToolHands:onLevelAction(_, inputValue)
	self:levelHeldItem()
end
function HandToolHands:rotateHeldItem(inputDelta, directionX, directionY, directionZ)
	local rotation = 1.5707963267948966 * (g_physicsDt * 0.001) * inputDelta
	local spec = self.spec_hands
	local _, rotationNode = self:getKinematicNode()
	rotateAboutLocalAxis(rotationNode, rotation, directionX, directionY, directionZ)
	if self.isServer and spec.heldItemJointId ~= nil then
		setJointFrame(spec.heldItemJointId, 0, rotationNode)
	end
end
function HandToolHands:levelHeldItem()
	if not self:getIsHoldingItem() then
		return
	else
		local spec = self.spec_hands
		local kinematicNode, rotationNode = self:getKinematicNode()
		local itemDirectionX, _, itemDirectionZ = localDirectionToLocal(spec.heldItemNode, kinematicNode, 0, 0, 1)
		local preservedYaw = MathUtil.getYRotationFromDirection(itemDirectionX, itemDirectionZ)
		setRotation(rotationNode, 0, preservedYaw, 0)
		if self.isServer then
			setJointFrame(spec.heldItemJointId, 0, rotationNode)
		end
	end
end
function HandToolHands:dropHeldItem(noEventSend)
	if not self:getIsHoldingItem() then
		return
	else
		HandsThrowObjectEvent.sendEvent(self, 0, 0, 0, 0, noEventSend)
		self:onHeldItemJointBroken(nil, nil, true)
	end
end
function HandToolHands:throwHeldItemWithForceScalar(throwForceScalar, noEventSend)
	if not self:getIsHoldingItem() then
		return
	else
		local player = self:getCarryingPlayer()
		if player == nil or player.targeter == nil then
			Logging.error("HandToolHands:throwHeldItemWithForceScalar can only be used on the owning player, as it uses their camera direction!")
			return
		end
		local _, _, _, cameraDirectionX, cameraDirectionY, cameraDirectionZ = player.targeter:getLastLookRay()
		self:throwHeldItemWithForceVector(cameraDirectionX, cameraDirectionY, cameraDirectionZ, throwForceScalar, noEventSend)
	end
end
function HandToolHands:throwHeldItemWithForceVector(dirX, dirY, dirZ, throwForceScalar, noEventSend)
	if not self:getIsHoldingItem() then
		return
	end
	HandsThrowObjectEvent.sendEvent(self, dirX, dirY, dirZ, throwForceScalar, noEventSend)
	local spec = self.spec_hands
	local heldItemNode = self:getHeldItem()
	spec.lastThrowUpdateIndex = nil
	spec.currentThrowTime = nil
	local player = self:getCarryingPlayer()
	local playerPositionX, playerPositionY, playerPositionZ = player:getPosition()
	local mission = g_currentMission
	local object = mission:getNodeObject(heldItemNode)
	if object ~= nil then
		object.thrownFromPosition = { playerPositionX, playerPositionY, playerPositionZ }
	end
	if not self.isServer then
		return
	end
	self:dropHeldItem()
	local mass = HandToolHands.calculateItemMass(heldItemNode)
	if mass == nil then
		return
	else
		local massFactor = math.min(mass / spec.currentMaximumMass, 1)
		local throwForce = 8 * (1.1 - massFactor) * throwForceScalar
		local throwForceX = dirX * throwForce
		local throwForceY = dirY * throwForce
		local throwForceZ = dirZ * throwForce
		setLinearVelocity(heldItemNode, throwForceX, throwForceY, throwForceZ)
		if object ~= nil and object:isa(DogBall) then
			local dogHouse = mission:getDoghouse(player.farmId)
			local dog = dogHouse and dogHouse:getDog()
			local dogDistance = nil
			if dog ~= nil then
				dogDistance = getCompanionClosestDistance(dog.dogInstance, playerPositionX, playerPositionY, playerPositionZ)
			end
			if dogDistance ~= nil and dogDistance < Dog.FETCH_RANGE then
				dog:fetchItem(player, object)
			end
		end
	end
end
function HandToolHands:pickUpTarget(target, noEventSend)
	if target == nil or not self:getCanPickUpNode(target.node) then
		return false
	end
	HandsPickUpObjectEvent.sendEvent(self, target, noEventSend)
	local mission = g_currentMission
	local heldObject = mission:getNodeObject(target.node)
	local heldItemNode = heldObject ~= nil and heldObject.rootNode ~= nil and getRigidBodyType(heldObject.rootNode) ~= RigidBodyType.NONE and heldObject.rootNode or target.node
	local spec = self.spec_hands
	spec.heldItemNode = heldItemNode
	local player = self:getCarryingPlayer()
	if player ~= nil and player.capsuleController ~= nil then
		local cctIndex = player.capsuleController.capsuleId
		if cctIndex ~= nil then
			setCCTPairCollision(cctIndex, spec.heldItemNode, false)
		end
	end
	spec.currentHoldDistance = target.distance
	self:updateKinematicNode()
	g_inputBinding:setActionEventActive(spec.throwActionEventId, true)
	g_inputBinding:setActionEventActive(spec.pitchActionEventId, true)
	g_inputBinding:setActionEventActive(spec.yawActionEventId, true)
	g_inputBinding:setActionEventActive(spec.pickUpActionEventId, true)
	g_inputBinding:setActionEventText(spec.pickUpActionEventId, g_i18n:getText("action_dropObject"))
	if heldObject ~= nil and (heldObject.isPallet or heldObject:isa(Bale) and not heldObject.isRoundbale) then
		g_inputBinding:setActionEventActive(spec.levelActionEventId, true)
		local objectName = "object"
		if heldObject.isPallet then
			objectName = g_i18n:getText("typeDesc_pallet")
		elseif heldObject:isa(Bale) then
			objectName = g_i18n:getText("fillType_squareBale")
		end
		g_inputBinding:setActionEventText(spec.levelActionEventId, string.namedFormat(g_i18n:getText("action_levelObject"), "objectName", objectName))
	end
	if self.isServer then
		spec.pickupPhysicsIndex = getPhysicsUpdateIndex()
	else
		self:orientRotationNodeToItem(heldItemNode)
	end
	return true
end
function HandToolHands:pickupFailed()
	Logging.devInfo("HandToolHands.pickupFailed")
	local spec = self.spec_hands
	local carryingPlayer = self:getCarryingPlayer()
	if carryingPlayer ~= nil and carryingPlayer.isOwner then
		g_inputBinding:setActionEventActive(spec.throwActionEventId, false)
		g_inputBinding:setActionEventActive(spec.pitchActionEventId, false)
		g_inputBinding:setActionEventActive(spec.yawActionEventId, false)
		g_inputBinding:setActionEventActive(spec.levelActionEventId, false)
		g_inputBinding:setActionEventActive(spec.pickUpActionEventId, false)
		g_inputBinding:setActionEventText(spec.pickUpActionEventId, g_i18n:getText("action_pickUpObject"))
	end
	if spec.heldItemNode ~= nil and (entityExists(spec.heldItemNode) and self:getIsHoldingItem()) then
		local player = self:getCarryingPlayer()
		if player ~= nil and player.capsuleController ~= nil then
			local cctIndex = player.capsuleController.capsuleId
			if cctIndex ~= nil then
				setCCTPairCollision(cctIndex, spec.heldItemNode, true)
			end
		end
	end
	spec.heldItemNode = nil
end
function HandToolHands:orientRotationNodeToItem(targetItemNode)
	local targetCentreX, targetCentreY, targetCentreZ = getCenterOfMass(targetItemNode)
	local targetWorldX, targetWorldY, targetWorldZ = localToWorld(targetItemNode, targetCentreX, targetCentreY, targetCentreZ)
	local _, kinematicRotationNode = self:getKinematicNode()
	setWorldTranslation(kinematicRotationNode, targetWorldX, targetWorldY, targetWorldZ)
	setWorldRotation(kinematicRotationNode, getWorldRotation(targetItemNode))
end
function HandToolHands:createItemJoint()
	local spec = self.spec_hands
	spec.pickupPhysicsIndex = nil
	if not self.isServer then
		return
	elseif not self:getIsHoldingItem() then
		Logging.error("Cannot create joint for held item when no item is being held!")
	elseif not entityExists(spec.heldItemNode) then
		self:dropHeldItem()
	elseif getRigidBodyType(spec.heldItemNode) ~= RigidBodyType.DYNAMIC then
		Logging.devWarning("HandToolHands:createItemJoint - held item node is not a dynamic rigid body, aborting pickup")
		self:dropHeldItem()
	else
		local joint = JointConstructor.new()
		joint:setActors(spec.kinematicNode, spec.heldItemNode)
		local targetCentreX, targetCentreY, targetCentreZ = getCenterOfMass(spec.heldItemNode)
		local targetWorldX, targetWorldY, targetWorldZ = localToWorld(spec.heldItemNode, targetCentreX, targetCentreY, targetCentreZ)
		joint:setJointWorldPositions(targetWorldX, targetWorldY, targetWorldZ, targetWorldX, targetWorldY, targetWorldZ)
		joint:setTranslationLimit(0, true, 0, 0)
		joint:setTranslationLimit(1, true, 0, 0)
		joint:setTranslationLimit(2, true, 0, 0)
		joint:setRotationLimit(0, 0, 0)
		joint:setRotationLimit(1, 0, 0)
		joint:setRotationLimit(2, 0, 0)
		local targetLeftX, targetLeftY, targetLeftZ = localDirectionToWorld(spec.heldItemNode, 1, 0, 0)
		joint:setJointWorldAxes(targetLeftX, targetLeftY, targetLeftZ, targetLeftX, targetLeftY, targetLeftZ)
		local targetUpX, targetUpY, targetUpZ = localDirectionToWorld(spec.heldItemNode, 0, 1, 0)
		joint:setJointWorldNormals(targetUpX, targetUpY, targetUpZ, targetUpX, targetUpY, targetUpZ)
		joint:setEnableCollision(false)
		self:orientRotationNodeToItem(spec.heldItemNode)
		local dampingRatio = 1
		local mass = HandToolHands.calculateItemMass(spec.heldItemNode)
		local rotationLimitSpring = {}
		local rotationLimitDamper = {}
		rotationLimitSpring[1] = mass * 60
		rotationLimitDamper[1] = 2 * math.sqrt(mass * rotationLimitSpring[1])
		rotationLimitSpring[2] = mass * 60
		rotationLimitDamper[2] = 2 * math.sqrt(mass * rotationLimitSpring[2])
		rotationLimitSpring[3] = mass * 60
		rotationLimitDamper[3] = 2 * math.sqrt(mass * rotationLimitSpring[3])
		joint:setRotationLimitSpring(rotationLimitSpring[1], rotationLimitDamper[1], rotationLimitSpring[2], rotationLimitDamper[2], rotationLimitSpring[3], rotationLimitDamper[3])
		local translationLimitSpring = {}
		local translationLimitDamper = {}
		translationLimitSpring[1] = mass * 60
		translationLimitDamper[1] = 2 * math.sqrt(mass * translationLimitSpring[1])
		translationLimitSpring[2] = mass * 60
		translationLimitDamper[2] = 2 * math.sqrt(mass * translationLimitSpring[2])
		translationLimitSpring[3] = mass * 60
		translationLimitDamper[3] = 2 * math.sqrt(mass * translationLimitSpring[3])
		joint:setTranslationLimitSpring(translationLimitSpring[1], translationLimitDamper[1], translationLimitSpring[2], translationLimitDamper[2], translationLimitSpring[3], translationLimitDamper[3])
		if not spec.hasSuperStrength then
			local forceAcceleration = 4
			local forceLimit = forceAcceleration * mass * 40
			joint:setBreakable(forceLimit, forceLimit)
		end
		spec.heldItemJointId = joint:finalize()
		addJointBreakReport(spec.heldItemJointId, "onHeldItemJointBroken", self)
	end
end
function HandToolHands:onHeldItemJointBroken(jointIndex, breakingImpulse, noEventSend)
	local spec = self.spec_hands
	local carryingPlayer = self:getCarryingPlayer()
	if carryingPlayer ~= nil and carryingPlayer.isOwner then
		g_inputBinding:setActionEventActive(spec.throwActionEventId, false)
		g_inputBinding:setActionEventActive(spec.pitchActionEventId, false)
		g_inputBinding:setActionEventActive(spec.yawActionEventId, false)
		g_inputBinding:setActionEventActive(spec.levelActionEventId, false)
		g_inputBinding:setActionEventActive(spec.pickUpActionEventId, false)
		g_inputBinding:setActionEventText(spec.pickUpActionEventId, g_i18n:getText("action_pickUpObject"))
	end
	if entityExists(spec.heldItemNode) and self:getIsHoldingItem() then
		local player = self:getCarryingPlayer()
		if player ~= nil and player.capsuleController ~= nil then
			local cctIndex = player.capsuleController.capsuleId
			if cctIndex ~= nil then
				setCCTPairCollision(cctIndex, spec.heldItemNode, true)
			end
		end
	end
	local itemExists = entityExists(spec.heldItemNode)
	spec.heldItemNode = nil
	if not self.isServer then
		return
	end
	HandsThrowObjectEvent.sendEvent(self, 0, 0, 0, 0, noEventSend)
	if self:getHasJoint() then
		if itemExists then
			removeJoint(spec.heldItemJointId)
		end
		spec.heldItemJointId = nil
	else
		if self:getIsAwaitingJointCreation() then
			spec.pickupPhysicsIndex = nil
		end
	end
end
function HandToolHands:findFootballCallback(transformId)
	if transformId ~= 0 and getHasClassId(transformId, ClassIds.SHAPE) then
		local mission = g_currentMission
		local object = mission:getNodeObject(transformId)
		if object ~= nil and object:isa(Football) then
			local spec = self.spec_hands
			spec.football = object
			return false
		end
	end
	return true
end
function HandToolHands:shootBall(football, dirX, dirZ, angleDeg, velocity, shotType)
	local spec = self.spec_hands
	spec.lastShootTime = g_time
	spec.canShoot = false
	football:shoot(dirX, dirZ, angleDeg, velocity, shotType)
end
function HandToolHands.calculateItemMass(itemNode)
	if itemNode == nil or not entityExists(itemNode) then
		return nil
	end
	local mission = g_currentMission
	local object = mission:getNodeObject(itemNode)
	local mass = nil
	if object ~= nil and object.getTotalMass ~= nil then
		mass = object:getTotalMass()
	end
	return mass or getMass(itemNode)
end
function HandToolHands:onDebugDraw()
	local kinematicNode, rotationNode = self:getKinematicNode()
	if kinematicNode ~= nil then
		DebugUtil.drawDebugNode(kinematicNode, "kinematic")
		DebugUtil.drawDebugNode(rotationNode, "rotation")
	end
	if self:getIsHoldingItem() then
		local heldItemNode = self:getHeldItem()
		DebugUtil.drawDebugNode(heldItemNode, "heldItem")
		local heldItemPositionX, heldItemPositionY, heldItemPositionZ = getWorldTranslation(heldItemNode)
		local kinematicPositionX, kinematicPositionY, kinematicPositionZ = getWorldTranslation(kinematicNode)
		local distance = MathUtil.vector3Length(heldItemPositionX - kinematicPositionX, heldItemPositionY - kinematicPositionY, heldItemPositionZ - kinematicPositionZ)
		DebugLine.renderBetweenNodes(kinematicNode, heldItemNode, Color.PRESETS.WHITE, true, string.format("%.3fm", distance), 0.03, Color.PRESETS.GREEN, Color.PRESETS.RED)
	end
end
function HandToolHands:consoleCommandToggleSuperStrength()
	local spec = self.spec_hands
	spec.hasSuperStrength = not spec.hasSuperStrength
	local text = "Disabled super strength"
	if spec.hasSuperStrength then
		spec.currentMaximumMass = HandToolHands.SUPER_STRENGTH_PICKUP_MASS
		spec.pickupDistance = 10
		text = "Enabled super strength"
	else
		spec.currentMaximumMass = HandToolHands.MAXIMUM_PICKUP_MASS
		spec.pickupDistance = HandToolHands.PICKUP_DISTANCE
	end
	local carryingPlayer = self:getCarryingPlayer()
	if carryingPlayer == nil or not carryingPlayer.isOwner then
		return text
	end
	carryingPlayer.targeter:removeTargetType(HandToolHands)
	carryingPlayer.targeter:addTargetType(HandToolHands, HandToolHands.TARGET_MASK, 0.5, spec.pickupDistance)
	return text
end
