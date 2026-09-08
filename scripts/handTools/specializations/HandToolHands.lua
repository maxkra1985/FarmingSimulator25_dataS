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

-- Local values: spec
function HandToolHands:onLoad(xmlFile, baseDirectory)
	local v6_ = self.spec_hands
	v6_.hasSuperStrength = false
	v6_.currentMaximumMass = HandToolHands.MAXIMUM_PICKUP_MASS
	v6_.pickupDistance = HandToolHands.PICKUP_DISTANCE
	v6_.currentThrowTime = nil
	v6_.pickUpActionEventId = nil
	v6_.throwActionEventId = nil
	v6_.pitchActionEventId = nil
	v6_.yawActionEventId = nil
	v6_.heldItemJointId = nil
	v6_.heldItemNode = nil
	v6_.currentHoldDistance = HandToolHands.PICKUP_DISTANCE
	v6_.kinematicNode = nil
	v6_.kinematicRotationNode = nil
	v6_.lastThrowUpdateIndex = nil
	v6_.pickupPhysicsIndex = nil
	v6_.dirtyFlag = self:getNextDirtyFlag()
	v6_.kinematicLoadingTask = self:createLoadingTask(v6_)
	v6_.kinematicSharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync("dataS/character/shared/kinematicHelper.i3d", true, false, HandToolHands.onKinematicHelperLoaded, self, nil)
	v6_.lastShootTime = g_time
	v6_.canShoot = false
	v6_.football = nil
	v6_.actionPassText = g_i18n:getText("action_passFootball")
	v6_.actionShootText = g_i18n:getText("action_shootFootball")
	v6_.pickupText = g_i18n:getText("action_pickUpObject")
	v6_.throwText = g_i18n:getText("input_THROW_OBJECT")
	if self.isClient then
		v6_.crosshair = self:createCrosshairOverlay("gui.crosshairDefault", HandTool.DEFAULT_CROSSHAIR_SIZE_PIXELS * 0.5)
		v6_.crosshair:setColor(nil, nil, nil, 0.25)
		v6_.pickUpCrosshair = self:createCrosshairOverlay("gui.grab")
		v6_.throwCrosshair = self:createCrosshairOverlay("gui.crosshairThrow")
	end
end

-- Local values: spec
function HandToolHands:onKinematicHelperLoaded(kinematicNode, failedReason)
	local v9_ = self.spec_hands
	self:finishLoadingTask(v9_.kinematicLoadingTask)
	v9_.kinematicLoadingTask = nil
	if kinematicNode == nil or kinematicNode == 0 then
		Logging.error("Hands could not load kinematic helper i3d!")
	else
		v9_.kinematicNode = getChildAt(kinematicNode, 0)
		link(getRootNode(), v9_.kinematicNode)
		addToPhysics(v9_.kinematicNode)
		v9_.kinematicRotationNode = createTransformGroup("kinematicRotationHelper")
		link(v9_.kinematicNode, v9_.kinematicRotationNode)
		delete(kinematicNode)
	end
end

-- Local values: spec, player
function HandToolHands:onDelete()
	local v11_ = self.spec_hands
	self:dropHeldItem(true)
	if v11_.kinematicSharedLoadRequestId ~= nil then
		g_i3DManager:releaseSharedI3DFile(v11_.kinematicSharedLoadRequestId)
		v11_.kinematicSharedLoadRequestId = nil
	end
	if v11_.kinematicNode ~= nil then
		delete(v11_.kinematicNode)
		v11_.kinematicNode = nil
	end
	local v12_ = self:getCarryingPlayer()
	if v12_ ~= nil and v12_.isOwner then
		removeConsoleCommand("gsPlayerSuperStrengthToggle")
	end
	if v11_.crosshair ~= nil then
		v11_.crosshair:delete()
		v11_.crosshair = nil
	end
	if v11_.pickUpCrosshair ~= nil then
		v11_.pickUpCrosshair:delete()
		v11_.pickUpCrosshair = nil
	end
	if v11_.throwCrosshair ~= nil then
		v11_.throwCrosshair:delete()
		v11_.throwCrosshair = nil
	end
end

-- Local values: spec, kinematicNode, kinematicRotationNode, kinematicNodePitch, kinematicNodeYaw, kinematicNodeRoll, kinematicNodePositionX, kinematicNodePositionY, kinematicNodePositionZ, kinematicNodeDirectionX, _, kinematicNodeDirectionZ, paramsXZ, paramsY
function HandToolHands:onWriteUpdateStream(streamId, connection, dirtyMask)
	if connection:getIsServer() then
		local v17_ = self.spec_hands
		local v18_ = streamWriteBool
		local v19_ = v17_.dirtyFlag
		if v18_(streamId, (bit32.btest(dirtyMask, v19_))) then
			local v20_, v21_ = self:getKinematicNode()
			local v22_, v23_, v24_ = getWorldRotation(v21_)
			local v25_, v26_, v27_ = getWorldTranslation(v20_)
			local v28_, _, v29_ = localDirectionToWorld(v20_, 0, 0, 1)
			local v30_, v31_ = MathUtil.vector2Normalize(v28_, v29_)
			local v32_ = g_currentMission.vehicleXZPosCompressionParams
			local v33_ = g_currentMission.vehicleYPosCompressionParams
			NetworkUtil.writeCompressedWorldPosition(streamId, v25_, v32_)
			NetworkUtil.writeCompressedWorldPosition(streamId, v26_, v33_)
			NetworkUtil.writeCompressedWorldPosition(streamId, v27_, v32_)
			NetworkUtil.writeCompressedRange(streamId, v30_, -1, 1, HandToolHands.KINEMATIC_NODE_DIRECTION_NUM_BITS)
			NetworkUtil.writeCompressedRange(streamId, v31_, -1, 1, HandToolHands.KINEMATIC_NODE_DIRECTION_NUM_BITS)
			NetworkUtil.writeCompressedAngle(streamId, v22_)
			NetworkUtil.writeCompressedAngle(streamId, v23_)
			NetworkUtil.writeCompressedAngle(streamId, v24_)
		end
	end
end

-- Local values: kinematicNode, kinematicRotationNode, paramsXZ, paramsY, kinematicNodePositionX, kinematicNodePositionY, kinematicNodePositionZ, kinematicNodeDirectionX, kinematicNodeDirectionZ, kinematicNodePitch, kinematicNodeYaw, kinematicNodeRoll, spec
function HandToolHands:onReadUpdateStream(streamId, timestamp, connection)
	if not connection:getIsServer() and streamReadBool(streamId) then
		local v37_, v38_ = self:getKinematicNode()
		local v39_ = g_currentMission.vehicleXZPosCompressionParams
		local v40_ = g_currentMission.vehicleYPosCompressionParams
		local v41_ = NetworkUtil.readCompressedWorldPosition(streamId, v39_)
		local v42_ = NetworkUtil.readCompressedWorldPosition(streamId, v40_)
		local v43_ = NetworkUtil.readCompressedWorldPosition(streamId, v39_)
		local v44_ = NetworkUtil.readCompressedRange(streamId, -1, 1, HandToolHands.KINEMATIC_NODE_DIRECTION_NUM_BITS)
		local v45_ = NetworkUtil.readCompressedRange(streamId, -1, 1, HandToolHands.KINEMATIC_NODE_DIRECTION_NUM_BITS)
		local v46_ = NetworkUtil.readCompressedAngle(streamId)
		local v47_ = NetworkUtil.readCompressedAngle(streamId)
		local v48_ = NetworkUtil.readCompressedAngle(streamId)
		setWorldTranslation(v37_, v41_, v42_, v43_)
		setWorldDirection(v37_, v44_, 0, v45_, 0, 1, 0)
		setWorldRotation(v38_, v46_, v47_, v48_)
		if self:getHasJoint() then
			local v49_ = self.spec_hands
			setJointFrame(v49_.heldItemJointId, 0, v38_)
		end
	end
end

-- Local values: carryingPlayer, spec, targetNode, canPickUpTarget, mission, object, x, y, z, canShoot, throwForceScalar, footballNode, px, py, pz, bx, by, bz, distance, camera, dirX, _, dirZ
function HandToolHands:onUpdate(dt)
	local v51_ = self:getCarryingPlayer()
	if v51_ == nil then
		return
	elseif self:getIsHeld() then
		local v52_ = self.spec_hands
		if self:getIsAwaitingJointCreation() and getIsPhysicsUpdateIndexSimulated(v52_.pickupPhysicsIndex) then
			self:createItemJoint()
		end
		self:updateKinematicNode()
		if v51_.isOwner then
			v52_.canShoot = v52_.lastShootTime + HandToolHands.FOOTBALL_SHOOT_THRESHOLD < g_time
			v52_.football = nil
			if self:getIsHoldingItem() and (self.isServer and (v52_.heldItemNode ~= nil and not entityExists(v52_.heldItemNode))) then
				self:dropHeldItem()
			end
			if self:getIsHoldingItem() then
				if self:getIsThrowingItem() and (v52_.lastThrowUpdateIndex ~= nil and v52_.lastThrowUpdateIndex ~= g_updateLoopIndex) then
					local v53_ = v52_.currentThrowTime / HandToolHands.MAXIMUM_THROW_TIME
					self:throwHeldItemWithForceScalar((math.clamp(v53_, 0, 1)))
				end
			else
				local v54_ = v51_.targeter:getClosestTargetedNodeFromType(HandToolHands)
				local v55_ = self:getCanPickUpNode(v54_)
				if not v55_ then
					local v56_ = g_currentMission:getNodeObject(v54_)
					if v56_ ~= nil and v56_:isa(Football) then
						v52_.football = v56_
					end
					if v52_.football == nil then
						local v57_, v58_, v59_ = getWorldTranslation(v51_.graphicsComponent.graphicsRootNode)
						overlapSphere(v57_, v58_, v59_, HandToolHands.FOOTBALL_DETECTION_RADIUS, "findFootballCallback", self, CollisionFlag.DYNAMIC_OBJECT, true, false, false)
					end
				end
				local v60_
				if v52_.football == nil then
					v60_ = false
				else
					v60_ = v52_.canShoot
				end
				g_inputBinding:setActionEventActive(v52_.pickUpActionEventId, v55_ or v60_)
				g_inputBinding:setActionEventActive(v52_.throwActionEventId, v52_.heldItemNode or v60_)
				if v60_ then
					g_inputBinding:setActionEventText(v52_.pickUpActionEventId, v52_.actionPassText)
					g_inputBinding:setActionEventText(v52_.throwActionEventId, v52_.actionShootText)
				else
					g_inputBinding:setActionEventText(v52_.pickUpActionEventId, v52_.pickupText)
					g_inputBinding:setActionEventText(v52_.throwActionEventId, v52_.throwText)
				end
			end
			if v52_.football ~= nil and v52_.canShoot then
				local v61_ = v52_.football.nodeId
				local v62_, v63_, v64_ = getWorldTranslation(v51_.graphicsComponent.graphicsRootNode)
				local v65_, v66_, v67_ = getWorldTranslation(v61_)
				local v68_ = MathUtil.vector3Length(v62_ - v65_, v63_ - v66_, v64_ - v67_)
				if HandToolHands.FOOTBALL_DRIBBLE_MIN_DISTANCE < v68_ and v68_ < HandToolHands.FOOTBALL_DRIBBLE_MAX_DISTANCE then
					local v69_ = g_cameraManager:getActiveCamera()
					local v70_, _, v71_ = localDirectionToWorld(v69_, 0, 0, -1)
					local v72_, _, v73_ = MathUtil.vector3Normalize(v70_, 0, v71_)
					self:shootBall(v52_.football, v72_, v73_, 0, HandToolHands.FOOTBALL_DRIBBLE_VELOCITY, Football.TYPE_DRIBBLE)
				end
			end
		end
	else
		return
	end
end

-- Local values: spec, carryingPlayer, player, target, node, throwForceScalar
function HandToolHands:onDraw()
	local v75_ = self.spec_hands
	local v76_ = self:getCarryingPlayer()
	if v76_ ~= nil and (v76_.isOwner and v76_.camera.isFirstPerson) then
		local v77_ = self:getCarryingPlayer().targeter.closestTargetsByKey[HandToolHands]
		local v78_ = v77_ and v77_.node or nil
		if self:getIsThrowingItem() then
			local v79_ = v75_.currentThrowTime / HandToolHands.MAXIMUM_THROW_TIME
			local v80_ = math.clamp(v79_, 0, 1)
			v75_.throwCrosshair:setScale(v80_, v80_)
			v75_.throwCrosshair:render()
			return
		end
		if v75_.heldItemNode ~= nil or self:getCanPickUpNode(v78_) then
			v75_.pickUpCrosshair:render()
			return
		end
		v75_.crosshair:render()
	end
end

-- Local values: spec, _, actionEventId
function HandToolHands:onRegisterActionEvents()
	if self:getIsActiveForInput(true) then
		local v82_ = self.spec_hands
		local _, v83_ = self:addActionEvent(InputAction.ACTIVATE_HANDTOOL, self, HandToolHands.onPickUpAction, true, false, false, false, nil)
		g_inputBinding:setActionEventTextPriority(v83_, GS_PRIO_VERY_HIGH)
		g_inputBinding:setActionEventText(v83_, v82_.pickupText)
		v82_.pickUpActionEventId = v83_
		local _, v84_ = self:addActionEvent(InputAction.ACTIVATE_HANDTOOL_SECONDARY, self, HandToolHands.onThrowAction, false, true, true, false, nil)
		g_inputBinding:setActionEventTextPriority(v84_, GS_PRIO_VERY_HIGH)
		g_inputBinding:setActionEventText(v84_, v82_.throwText)
		v82_.throwActionEventId = v84_
		local _, v85_ = self:addActionEvent(InputAction.ROTATE_OBJECT_UP_DOWN, self, HandToolHands.onPitchAction, false, false, true, false, nil)
		g_inputBinding:setActionEventText(v85_, g_i18n:getText("action_rotateObjectVertically"))
		v82_.pitchActionEventId = v85_
		local _, v86_ = self:addActionEvent(InputAction.ROTATE_OBJECT_LEFT_RIGHT, self, HandToolHands.onYawAction, false, false, true, false, nil)
		g_inputBinding:setActionEventText(v86_, g_i18n:getText("action_rotateObjectHorizontally"))
		v82_.yawActionEventId = v86_
		local _, v87_ = self:addActionEvent(InputAction.HANDS_LEVEL_ITEM, self, HandToolHands.onLevelAction, true, false, false, false, nil)
		v82_.levelActionEventId = v87_
	end
end

-- Local values: carryingPlayer, spec, targeter
function HandToolHands:onHeldStart()
	local v89_ = self:getCarryingPlayer()
	if v89_ ~= nil and v89_.isOwner then
		local v90_ = self.spec_hands
		self:getCarryingPlayer().targeter:addTargetType(HandToolHands, HandToolHands.TARGET_MASK, 0.5, v90_.pickupDistance)
	end
end

-- Local values: carryingPlayer
function HandToolHands:onHeldEnd()
	local v92_ = self:getCarryingPlayer()
	if v92_ ~= nil and v92_.isOwner then
		v92_.targeter:removeTargetType(HandToolHands)
		self:dropHeldItem()
	end
end

function HandToolHands:onCarryingPlayerChanged(player, lastPlayer)
	if player == nil or not player.isOwner then
		if lastPlayer ~= nil and lastPlayer.isOwner then
			removeConsoleCommand("gsPlayerSuperStrengthToggle")
		end
	else
		addConsoleCommand("gsPlayerSuperStrengthToggle", "Toggles the super strength mode for the player", "consoleCommandToggleSuperStrength", self)
	end
end

function HandToolHands:getCanBeDropped(superFunc)
	return false
end

-- Local values: spec, x, y, z, dx, dy, dz
function HandToolHands:updateKinematicNode()
	local v97_ = self.spec_hands
	if v97_.kinematicNode == nil then
		return
	elseif self:getIsHeld() then
		if self:getCarryingPlayer().isOwner then
			local v98_, v99_, v100_, v101_, v102_, v103_ = self:getCarryingPlayer().targeter:getLastLookRay()
			if v98_ ~= nil then
				self:raiseDirtyFlags(v97_.dirtyFlag)
				local v104_ = v98_ + v101_ * v97_.currentHoldDistance
				local v105_ = v99_ + v102_ * v97_.currentHoldDistance
				local v106_ = v100_ + v103_ * v97_.currentHoldDistance
				setWorldTranslation(v97_.kinematicNode, v104_, v105_, v106_)
				local v107_, v108_ = MathUtil.vector2Normalize(v101_, v103_)
				setWorldDirection(v97_.kinematicNode, v107_, 0, v108_, 0, 1, 0)
			end
		else
			return
		end
	else
		return
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

-- Local values: spec, mass, mission, object
function HandToolHands:getCanPickUpNode(node)
	if node == nil or (node == 0 or not entityExists(node)) then
		return false
	end
	if self.isServer and getRigidBodyType(node) ~= RigidBodyType.DYNAMIC then
		return false
	end
	if self:getIsHoldingItem() then
		return false
	end
	local v117_ = self.spec_hands
	local v118_ = HandToolHands.calculateItemMass(node)
	if self.isServer and (v118_ == nil or v117_.currentMaximumMass < v118_) then
		return false
	end
	local v119_ = g_currentMission:getNodeObject(node)
	if v119_ ~= nil then
		if v119_.dynamicMountObject ~= nil or v119_.tensionMountObject ~= nil then
			return false
		end
		if not v117_.hasSuperStrength and (v119_.getCanBePickedUp ~= nil and not v119_:getCanBePickedUp(self:getCarryingPlayer())) then
			return false
		end
	end
	return true
end

-- Local values: player, spec, camera, dirX, _, dirZ, target
function HandToolHands:onPickUpAction(_, inputValue)
	local v121_ = self:getCarryingPlayer()
	if v121_.isOwner then
		local v122_ = self.spec_hands
		if v122_.football == nil then
			if self:getIsHoldingItem() then
				self:dropHeldItem()
			else
				self:pickUpTarget(v121_.targeter.closestTargetsByKey[HandToolHands])
			end
		else
			local v123_ = g_cameraManager:getActiveCamera()
			local v124_, _, v125_ = localDirectionToWorld(v123_, 0, 0, -1)
			local v126_, _, v127_ = MathUtil.vector3Normalize(v124_, 0, v125_)
			self:shootBall(v122_.football, v126_, v127_, 0, HandToolHands.FOOTBALL_PASS_VELOCITY, Football.TYPE_PASS)
			return
		end
	else
		return
	end
end

-- Local values: player, spec, camera, dirX, _, dirZ
function HandToolHands:onThrowAction(_, inputValue)
	if self:getCarryingPlayer().isOwner then
		local v129_ = self.spec_hands
		if v129_.football ~= nil then
			local v130_ = g_cameraManager:getActiveCamera()
			local v131_, _, v132_ = localDirectionToWorld(v130_, 0, 0, -1)
			local v133_, _, v134_ = MathUtil.vector3Normalize(v131_, 0, v132_)
			self:shootBall(v129_.football, v133_, v134_, 30, HandToolHands.FOOTBALL_SHOT_VELOCITY, Football.TYPE_SHOT)
		end
		if self:getIsHoldingItem() then
			v129_.lastThrowUpdateIndex = g_updateLoopIndex
			if v129_.currentThrowTime == nil then
				v129_.currentThrowTime = 0
			else
				v129_.currentThrowTime = v129_.currentThrowTime + g_currentDt
			end
		else
			return
		end
	else
		return
	end
end

-- Local values: kinematicNode, rotationNode, directionX, directionY, directionZ
function HandToolHands:onPitchAction(_, inputDelta)
	local v137_, v138_ = self:getKinematicNode()
	local v139_, v140_, v141_ = localDirectionToLocal(v137_, v138_, 1, 0, 0)
	self:rotateHeldItem(inputDelta, v139_, v140_, v141_)
end

-- Local values: kinematicNode, rotationNode, directionX, directionY, directionZ
function HandToolHands:onYawAction(_, inputDelta)
	local v144_, v145_ = self:getKinematicNode()
	local v146_, v147_, v148_ = localDirectionToLocal(v144_, v145_, 0, 1, 0)
	self:rotateHeldItem(inputDelta, v146_, v147_, v148_)
end

function HandToolHands:onLevelAction(_, inputValue)
	self:levelHeldItem()
end

-- Local values: rotation, spec, _, rotationNode
function HandToolHands:rotateHeldItem(inputDelta, directionX, directionY, directionZ)
	local v155_ = 1.5707963267948966 * (g_physicsDt * 0.001) * inputDelta
	local v156_ = self.spec_hands
	local _, v157_ = self:getKinematicNode()
	rotateAboutLocalAxis(v157_, v155_, directionX, directionY, directionZ)
	if self.isServer and v156_.heldItemJointId ~= nil then
		setJointFrame(v156_.heldItemJointId, 0, v157_)
	end
end

-- Local values: spec, kinematicNode, rotationNode, itemDirectionX, _, itemDirectionZ, preservedYaw
function HandToolHands:levelHeldItem()
	if self:getIsHoldingItem() then
		local v159_ = self.spec_hands
		local v160_, v161_ = self:getKinematicNode()
		local v162_, _, v163_ = localDirectionToLocal(v159_.heldItemNode, v160_, 0, 0, 1)
		local v164_ = MathUtil.getYRotationFromDirection(v162_, v163_)
		setRotation(v161_, 0, v164_, 0)
		if self.isServer then
			setJointFrame(v159_.heldItemJointId, 0, v161_)
		end
	end
end

function HandToolHands:dropHeldItem(noEventSend)
	if self:getIsHoldingItem() then
		HandsThrowObjectEvent.sendEvent(self, 0, 0, 0, 0, noEventSend)
		self:onHeldItemJointBroken(nil, nil, true)
	end
end

-- Local values: player, _, _, _, cameraDirectionX, cameraDirectionY, cameraDirectionZ
function HandToolHands:throwHeldItemWithForceScalar(throwForceScalar, noEventSend)
	if self:getIsHoldingItem() then
		local v170_ = self:getCarryingPlayer()
		if v170_ == nil or v170_.targeter == nil then
			Logging.error("HandToolHands:throwHeldItemWithForceScalar can only be used on the owning player, as it uses their camera direction!")
		else
			local _, _, _, v171_, v172_, v173_ = v170_.targeter:getLastLookRay()
			self:throwHeldItemWithForceVector(v171_, v172_, v173_, throwForceScalar, noEventSend)
		end
	else
		return
	end
end

-- Local values: spec, heldItemNode, player, playerPositionX, playerPositionY, playerPositionZ, mission, object, mass, massFactor, throwForce, throwForceX, throwForceY, throwForceZ, dogHouse, dog, dogDistance
function HandToolHands:throwHeldItemWithForceVector(dirX, dirY, dirZ, throwForceScalar, noEventSend)
	if self:getIsHoldingItem() then
		HandsThrowObjectEvent.sendEvent(self, dirX, dirY, dirZ, throwForceScalar, noEventSend)
		local v180_ = self.spec_hands
		local v181_ = self:getHeldItem()
		v180_.lastThrowUpdateIndex = nil
		v180_.currentThrowTime = nil
		local v182_ = self:getCarryingPlayer()
		local v183_, v184_, v185_ = v182_:getPosition()
		local v186_ = g_currentMission
		local v187_ = v186_:getNodeObject(v181_)
		if v187_ ~= nil then
			v187_.thrownFromPosition = { v183_, v184_, v185_ }
		end
		if self.isServer then
			self:dropHeldItem()
			local v188_ = HandToolHands.calculateItemMass(v181_)
			if v188_ ~= nil then
				local v189_ = v188_ / v180_.currentMaximumMass
				local v190_ = 8 * (1.1 - math.min(v189_, 1)) * throwForceScalar
				local v191_ = dirX * v190_
				local v192_ = dirY * v190_
				local v193_ = dirZ * v190_
				setLinearVelocity(v181_, v191_, v192_, v193_)
				if v187_ ~= nil and v187_:isa(DogBall) then
					local v194_ = v186_:getDoghouse(v182_.farmId)
					if v194_ then
						v194_ = v194_:getDog()
					end
					local v195_
					if v194_ == nil then
						v195_ = nil
					else
						v195_ = getCompanionClosestDistance(v194_.dogInstance, v183_, v184_, v185_)
					end
					if v195_ ~= nil and v195_ < Dog.FETCH_RANGE then
						v194_:fetchItem(v182_, v187_)
					end
				end
			end
		else
			return
		end
	else
		return
	end
end

-- Local values: mission, heldObject, rootHasRigidBody, heldItemNode, spec, player, cctIndex, objectName
function HandToolHands:pickUpTarget(target, noEventSend)
	if target == nil or not self:getCanPickUpNode(target.node) then
		return false
	end
	HandsPickUpObjectEvent.sendEvent(self, target, noEventSend)
	local v199_ = g_currentMission:getNodeObject(target.node)
	local v200_
	if v199_ == nil or v199_.rootNode == nil then
		v200_ = false
	else
		v200_ = getRigidBodyType(v199_.rootNode) ~= RigidBodyType.NONE
	end
	local v201_ = v200_ and v199_.rootNode or target.node
	local v202_ = self.spec_hands
	v202_.heldItemNode = v201_
	local v203_ = self:getCarryingPlayer()
	if v203_ ~= nil and v203_.capsuleController ~= nil then
		local v204_ = v203_.capsuleController.capsuleId
		if v204_ ~= nil then
			setCCTPairCollision(v204_, v202_.heldItemNode, false)
		end
	end
	v202_.currentHoldDistance = target.distance
	self:updateKinematicNode()
	g_inputBinding:setActionEventActive(v202_.throwActionEventId, true)
	g_inputBinding:setActionEventActive(v202_.pitchActionEventId, true)
	g_inputBinding:setActionEventActive(v202_.yawActionEventId, true)
	g_inputBinding:setActionEventActive(v202_.pickUpActionEventId, true)
	g_inputBinding:setActionEventText(v202_.pickUpActionEventId, g_i18n:getText("action_dropObject"))
	if v199_ ~= nil and (v199_.isPallet or v199_:isa(Bale) and not v199_.isRoundbale) then
		g_inputBinding:setActionEventActive(v202_.levelActionEventId, true)
		local v205_ = "object"
		if v199_.isPallet then
			v205_ = g_i18n:getText("typeDesc_pallet")
		elseif v199_:isa(Bale) then
			v205_ = g_i18n:getText("fillType_squareBale")
		end
		g_inputBinding:setActionEventText(v202_.levelActionEventId, string.namedFormat(g_i18n:getText("action_levelObject"), "objectName", v205_))
	end
	if self.isServer then
		v202_.pickupPhysicsIndex = getPhysicsUpdateIndex()
	else
		self:orientRotationNodeToItem(v201_)
	end
	return true
end

-- Local values: spec, carryingPlayer, player, cctIndex
function HandToolHands:pickupFailed()
	Logging.devInfo("HandToolHands.pickupFailed")
	local v207_ = self.spec_hands
	local v208_ = self:getCarryingPlayer()
	if v208_ ~= nil and v208_.isOwner then
		g_inputBinding:setActionEventActive(v207_.throwActionEventId, false)
		g_inputBinding:setActionEventActive(v207_.pitchActionEventId, false)
		g_inputBinding:setActionEventActive(v207_.yawActionEventId, false)
		g_inputBinding:setActionEventActive(v207_.levelActionEventId, false)
		g_inputBinding:setActionEventActive(v207_.pickUpActionEventId, false)
		g_inputBinding:setActionEventText(v207_.pickUpActionEventId, g_i18n:getText("action_pickUpObject"))
	end
	if v207_.heldItemNode ~= nil and (entityExists(v207_.heldItemNode) and self:getIsHoldingItem()) then
		local v209_ = self:getCarryingPlayer()
		if v209_ ~= nil and v209_.capsuleController ~= nil then
			local v210_ = v209_.capsuleController.capsuleId
			if v210_ ~= nil then
				setCCTPairCollision(v210_, v207_.heldItemNode, true)
			end
		end
	end
	v207_.heldItemNode = nil
end

-- Local values: targetCentreX, targetCentreY, targetCentreZ, targetWorldX, targetWorldY, targetWorldZ, _, kinematicRotationNode
function HandToolHands:orientRotationNodeToItem(targetItemNode)
	local v213_, v214_, v215_ = getCenterOfMass(targetItemNode)
	local v216_, v217_, v218_ = localToWorld(targetItemNode, v213_, v214_, v215_)
	local _, v219_ = self:getKinematicNode()
	setWorldTranslation(v219_, v216_, v217_, v218_)
	setWorldRotation(v219_, getWorldRotation(targetItemNode))
end

-- Local values: spec, joint, targetCentreX, targetCentreY, targetCentreZ, targetWorldX, targetWorldY, targetWorldZ, targetLeftX, targetLeftY, targetLeftZ, targetUpX, targetUpY, targetUpZ, dampingRatio, mass, rotationLimitSpring, rotationLimitDamper, translationLimitSpring, translationLimitDamper, forceAcceleration, forceLimit
function HandToolHands:createItemJoint()
	local v221_ = self.spec_hands
	v221_.pickupPhysicsIndex = nil
	if self.isServer then
		if self:getIsHoldingItem() then
			if entityExists(v221_.heldItemNode) then
				if getRigidBodyType(v221_.heldItemNode) == RigidBodyType.DYNAMIC then
					local v222_ = JointConstructor.new()
					v222_:setActors(v221_.kinematicNode, v221_.heldItemNode)
					local v223_, v224_, v225_ = getCenterOfMass(v221_.heldItemNode)
					local v226_, v227_, v228_ = localToWorld(v221_.heldItemNode, v223_, v224_, v225_)
					v222_:setJointWorldPositions(v226_, v227_, v228_, v226_, v227_, v228_)
					v222_:setTranslationLimit(0, true, 0, 0)
					v222_:setTranslationLimit(1, true, 0, 0)
					v222_:setTranslationLimit(2, true, 0, 0)
					v222_:setRotationLimit(0, 0, 0)
					v222_:setRotationLimit(1, 0, 0)
					v222_:setRotationLimit(2, 0, 0)
					local v229_, v230_, v231_ = localDirectionToWorld(v221_.heldItemNode, 1, 0, 0)
					v222_:setJointWorldAxes(v229_, v230_, v231_, v229_, v230_, v231_)
					local v232_, v233_, v234_ = localDirectionToWorld(v221_.heldItemNode, 0, 1, 0)
					v222_:setJointWorldNormals(v232_, v233_, v234_, v232_, v233_, v234_)
					v222_:setEnableCollision(false)
					self:orientRotationNodeToItem(v221_.heldItemNode)
					local v235_ = HandToolHands.calculateItemMass(v221_.heldItemNode)
					local v236_ = {}
					local v237_ = {}
					v236_[1] = v235_ * 60
					local v238_ = v235_ * v236_[1]
					v237_[1] = 2 * math.sqrt(v238_)
					v236_[2] = v235_ * 60
					local v239_ = v235_ * v236_[2]
					v237_[2] = 2 * math.sqrt(v239_)
					v236_[3] = v235_ * 60
					local v240_ = v235_ * v236_[3]
					v237_[3] = 2 * math.sqrt(v240_)
					v222_:setRotationLimitSpring(v236_[1], v237_[1], v236_[2], v237_[2], v236_[3], v237_[3])
					local v241_ = {}
					local v242_ = {}
					v241_[1] = v235_ * 60
					local v243_ = v235_ * v241_[1]
					v242_[1] = 2 * math.sqrt(v243_)
					v241_[2] = v235_ * 60
					local v244_ = v235_ * v241_[2]
					v242_[2] = 2 * math.sqrt(v244_)
					v241_[3] = v235_ * 60
					local v245_ = v235_ * v241_[3]
					v242_[3] = 2 * math.sqrt(v245_)
					v222_:setTranslationLimitSpring(v241_[1], v242_[1], v241_[2], v242_[2], v241_[3], v242_[3])
					if not v221_.hasSuperStrength then
						local v246_ = 4 * v235_ * 40
						v222_:setBreakable(v246_, v246_)
					end
					v221_.heldItemJointId = v222_:finalize()
					addJointBreakReport(v221_.heldItemJointId, "onHeldItemJointBroken", self)
				else
					Logging.devWarning("HandToolHands:createItemJoint - held item node is not a dynamic rigid body, aborting pickup")
					self:dropHeldItem()
				end
			else
				self:dropHeldItem()
				return
			end
		else
			Logging.error("Cannot create joint for held item when no item is being held!")
			return
		end
	else
		return
	end
end

-- Local values: spec, carryingPlayer, player, cctIndex, itemExists
function HandToolHands:onHeldItemJointBroken(jointIndex, breakingImpulse, noEventSend)
	local v249_ = self.spec_hands
	local v250_ = self:getCarryingPlayer()
	if v250_ ~= nil and v250_.isOwner then
		g_inputBinding:setActionEventActive(v249_.throwActionEventId, false)
		g_inputBinding:setActionEventActive(v249_.pitchActionEventId, false)
		g_inputBinding:setActionEventActive(v249_.yawActionEventId, false)
		g_inputBinding:setActionEventActive(v249_.levelActionEventId, false)
		g_inputBinding:setActionEventActive(v249_.pickUpActionEventId, false)
		g_inputBinding:setActionEventText(v249_.pickUpActionEventId, g_i18n:getText("action_pickUpObject"))
	end
	if entityExists(v249_.heldItemNode) and self:getIsHoldingItem() then
		local v251_ = self:getCarryingPlayer()
		if v251_ ~= nil and v251_.capsuleController ~= nil then
			local v252_ = v251_.capsuleController.capsuleId
			if v252_ ~= nil then
				setCCTPairCollision(v252_, v249_.heldItemNode, true)
			end
		end
	end
	local v253_ = entityExists(v249_.heldItemNode)
	v249_.heldItemNode = nil
	if self.isServer then
		HandsThrowObjectEvent.sendEvent(self, 0, 0, 0, 0, noEventSend)
		if self:getHasJoint() then
			if v253_ then
				removeJoint(v249_.heldItemJointId)
			end
			v249_.heldItemJointId = nil
		elseif self:getIsAwaitingJointCreation() then
			v249_.pickupPhysicsIndex = nil
		end
	else
		return
	end
end

-- Local values: mission, object, spec
function HandToolHands:findFootballCallback(transformId)
	if transformId ~= 0 and getHasClassId(transformId, ClassIds.SHAPE) then
		local v256_ = g_currentMission:getNodeObject(transformId)
		if v256_ ~= nil and v256_:isa(Football) then
			self.spec_hands.football = v256_
			return false
		end
	end
	return true
end

-- Local values: spec
function HandToolHands:shootBall(football, dirX, dirZ, angleDeg, velocity, shotType)
	local v264_ = self.spec_hands
	v264_.lastShootTime = g_time
	v264_.canShoot = false
	football:shoot(dirX, dirZ, angleDeg, velocity, shotType)
end

-- Local values: mission, object, mass
function HandToolHands.calculateItemMass(itemNode)
	if itemNode == nil or not entityExists(itemNode) then
		return nil
	end
	local v266_ = g_currentMission:getNodeObject(itemNode)
	local v267_
	if v266_ == nil or v266_.getTotalMass == nil then
		v267_ = nil
	else
		v267_ = v266_:getTotalMass()
	end
	return v267_ or getMass(itemNode)
end

-- Local values: kinematicNode, rotationNode, heldItemNode, heldItemPositionX, heldItemPositionY, heldItemPositionZ, kinematicPositionX, kinematicPositionY, kinematicPositionZ, distance
function HandToolHands:onDebugDraw()
	local v269_, v270_ = self:getKinematicNode()
	if v269_ ~= nil then
		DebugUtil.drawDebugNode(v269_, "kinematic")
		DebugUtil.drawDebugNode(v270_, "rotation")
	end
	if self:getIsHoldingItem() then
		local v271_ = self:getHeldItem()
		DebugUtil.drawDebugNode(v271_, "heldItem")
		local v272_, v273_, v274_ = getWorldTranslation(v271_)
		local v275_, v276_, v277_ = getWorldTranslation(v269_)
		local v278_ = MathUtil.vector3Length(v272_ - v275_, v273_ - v276_, v274_ - v277_)
		DebugLine.renderBetweenNodes(v269_, v271_, Color.PRESETS.WHITE, true, string.format("%.3fm", v278_), 0.03, Color.PRESETS.GREEN, Color.PRESETS.RED)
	end
end

-- Local values: spec, text, carryingPlayer
function HandToolHands:consoleCommandToggleSuperStrength()
	local v280_ = self.spec_hands
	v280_.hasSuperStrength = not v280_.hasSuperStrength
	local v281_ = "Disabled super strength"
	if v280_.hasSuperStrength then
		v280_.currentMaximumMass = HandToolHands.SUPER_STRENGTH_PICKUP_MASS
		v280_.pickupDistance = 10
		v281_ = "Enabled super strength"
	else
		v280_.currentMaximumMass = HandToolHands.MAXIMUM_PICKUP_MASS
		v280_.pickupDistance = HandToolHands.PICKUP_DISTANCE
	end
	local v282_ = self:getCarryingPlayer()
	if v282_ == nil or not v282_.isOwner then
		return v281_
	end
	v282_.targeter:removeTargetType(HandToolHands)
	v282_.targeter:addTargetType(HandToolHands, HandToolHands.TARGET_MASK, 0.5, v280_.pickupDistance)
	return v281_
end
