-- Local values: PlayerOnFootStateMachine_mt
PlayerOnFootStateMachine = {}
local PlayerOnFootStateMachine_mt = Class(PlayerOnFootStateMachine, StateMachine)
PlayerOnFootStateMachine:implementStateInterface()

-- Upvalues: PlayerOnFootStateMachine_mt
-- Local values: self
function PlayerOnFootStateMachine.new(player)
	-- upvalues: (copy) PlayerOnFootStateMachine_mt
	local v3_ = StateMachine.new(PlayerOnFootStateMachine_mt)
	v3_.player = player
	v3_.stateMachine = player.stateMachine
	v3_.states = {
		["idle"] = PlayerStateIdle.new(player, v3_),
		["walking"] = PlayerStateWalk.new(player, v3_),
		["swimming"] = PlayerStateSwim.new(player, v3_),
		["falling"] = PlayerStateFall.new(player, v3_),
		["jumping"] = PlayerStateJump.new(player, v3_),
		["crouching"] = PlayerStateCrouch.new(player, v3_)
	}
	v3_:initialiseStateTransitions()
	v3_.currentState = v3_.states.idle
	v3_.defaultState = v3_.states.idle
	v3_.canUseHandTools = true
	v3_.player:addStateEvent(PlayerOnFootStateMachine.onLeaveVehicle, v3_, "onLeaveVehicle")
	v3_.player:addStateEvent(PlayerOnFootStateMachine.onLeaveVehicle, v3_, "onLeaveVehicleAsPassenger")
	v3_.player:addStateEvent(PlayerOnFootStateMachine.onLeaveVehicle, v3_, "onLeaveRollercoaster")
	return v3_
end

function PlayerOnFootStateMachine:onLeaveVehicle()
	self.player.stateMachine:changeState(self)
end

-- Local values: oldContext, mission
function PlayerOnFootStateMachine:onStateEntered(previousState)
	self.player.networkComponent:reset()
	self.player.graphicsState:setDefault()
	self.player.graphicsComponent:applyState(self.player.graphicsState)
	self.player.mover:setSpeed(0)
	self.player.mover:resetHorizontalVelocity()
	if self.player.isServer then
		self.player:show()
	end
	if self.player.isOwner then
		local v6_ = g_inputBinding:getContextName()
		if v6_ ~= Vehicle.INPUT_CONTEXT_NAME then
			g_inputBinding:replaceContextInStack(Vehicle.INPUT_CONTEXT_NAME, PlayerInputComponent.INPUT_CONTEXT_NAME)
		end
		if v6_ == InputBinding.ROOT_CONTEXT_NAME or (v6_ == Vehicle.INPUT_CONTEXT_NAME or v6_ == PlaceableRollercoaster.INPUT_CONTEXT_ROLLERCOASTER) then
			self.player.inputComponent:makeCurrent()
		end
		local v7_ = g_currentMission
		v7_.activatableObjectsSystem:activate(PlayerInputComponent.INPUT_CONTEXT_NAME)
		v7_.hud:setIsControllingPlayer(true)
		self:determineState()
	end
end

-- Local values: mission
function PlayerOnFootStateMachine:onStateExited(nextState)
	self.player.networkComponent:reset()
	self.player.graphicsState:setDefault()
	self.player.graphicsComponent:applyState(self.player.graphicsState)
	self.player.graphicsComponent:setModelPosition(self.player:getGraphicalPosition())
	if self.player.isOwner then
		self.player.mover:setSpeed(0)
		self.player.mover:resetHorizontalVelocity()
		self.player:setCurrentHandTool(nil, true)
		g_currentMission.activatableObjectsSystem:deactivate(PlayerInputComponent.INPUT_CONTEXT_NAME)
	end
end

function PlayerOnFootStateMachine:getIsInVehicle()
	return false
end

function PlayerOnFootStateMachine:getCurrentVehicle()
	return nil
end

function PlayerOnFootStateMachine:getCurrentRootNode()
	return self.player.rootNode
end

function PlayerOnFootStateMachine:getSpeed()
	return self.player.mover:getSpeed()
end

function PlayerOnFootStateMachine:getMaximumSpeed()
	return self.currentState.calculateMaximumSpeed == nil and 0 or self.currentState:calculateMaximumSpeed()
end

function PlayerOnFootStateMachine:getPosition()
	return self.player.mover:getPosition()
end

function PlayerOnFootStateMachine:getYaw()
	return self.player.mover:getMovementYaw()
end

function PlayerOnFootStateMachine:getCurrentFacingDirection()
	return MathUtil.getDirectionFromYRotation(self:getYaw())
end

function PlayerOnFootStateMachine:getCurrentCameraNode()
	local v16_ = self.player.camera
	if v16_ then
		v16_ = self.player.camera:getCurrentCameraNode()
	end
	return v16_
end

-- Local values: mission, movementX, movementZ, x, y, z, dirX, dirZ, activatableObjectsSystem
function PlayerOnFootStateMachine:updateAsCurrent(dt)
	local v19_ = g_currentMission
	if self.player.inputComponent ~= nil then
		self.player.inputComponent:update(dt)
	end
	if self.player.targeter ~= nil then
		self.player.targeter:update(dt)
	end
	if self.player.networkComponent ~= nil then
		self.player.networkComponent:preUpdate(dt)
	end
	if self.player.camera ~= nil then
		self.player.camera:updateRotation(dt)
	end
	self.player.capsuleController:update(dt)
	self:update(dt)
	if self.player.inputComponent ~= nil and self.currentState.calculateDesiredHorizontalVelocity then
		local v20_, v21_ = self.currentState:calculateDesiredHorizontalVelocity(self.player.inputComponent.worldDirectionX, self.player.inputComponent.worldDirectionZ)
		self.player.mover:moveHorizontally(v20_, v21_)
	end
	self.player.mover:update(dt)
	if self.player.camera ~= nil then
		self.player.camera:setOffsetY(self.currentState.cameraOffsetY)
	end
	if self.player.positionalInterpolator ~= nil then
		self.player.positionalInterpolator:update(dt)
	end
	if self.player.isOwner then
		self.player.graphicsState:updateLocal(self.player)
	else
		self.player.graphicsState:updateRemote(self.player)
	end
	self.player.graphicsComponent:applyState(self.player.graphicsState)
	self.player.graphicsComponent:setModelYaw(self.player:getGraphicalYaw())
	self.player.graphicsComponent:setModelPosition(self.player:getGraphicalPosition())
	self.player.graphicsComponent:update(dt)
	if self.player.camera ~= nil then
		self.player.camera:updatePosition(dt)
	end
	if self.player.isOwner then
		local v22_, v23_, v24_ = self.player:getPosition()
		local v25_, v26_ = self.player:getCurrentFacingDirection()
		local v27_ = v19_.activatableObjectsSystem
		v27_:setPosition(v22_, v23_, v24_)
		v27_:setDirection(v25_, 0, v26_)
	end
	if self.player.inputComponent ~= nil then
		self.player.inputComponent:resetState()
	end
	if self.player.networkComponent ~= nil then
		self.player.networkComponent:update(dt)
	end
end

function PlayerOnFootStateMachine:updateTick(dt)
	if self.player.networkComponent then
		self.player.networkComponent:updateTick(dt)
	end
	if self.player.positionalInterpolator ~= nil then
		self.player.positionalInterpolator:updateTick(dt)
	end
end

-- Local values: focusNode, playerPositionX, _, playerPositionZ, npcPositionX, _, npcPositionZ, playerNPCDirectionX, _, playerNPCDirectionZ, targetYaw
function PlayerOnFootStateMachine:updateWhileInConversation(dt, npc)
	local v32_ = npc.playerGraphics.model.thirdPersonHeadNode
	if npc.playerGraphics.facialAnimation ~= nil then
		v32_ = npc.playerGraphics.facialAnimation.headFocusNode
	end
	if v32_ ~= nil then
		self.player.graphicsComponent:pointRightShoulderCameraNodeAt(v32_)
	end
	local v33_, _, v34_ = self.player:getPosition()
	local v35_, _, v36_ = npc:getPosition()
	local v37_, _, v38_ = MathUtil.vector3Normalize(v35_ - v33_, 0, v36_ - v34_)
	local v39_ = MathUtil.getYRotationFromDirection(v37_, v38_)
	self.player.mover:setMovementYaw(v39_)
	self.player.graphicsComponent:defaultAllParameters()
	self.player.graphicsComponent:setModelYaw(self.player:getGraphicalYaw())
	self.player.graphicsComponent:setModelPosition(self.player:getGraphicalPosition())
	if self.player.camera ~= nil then
		self.player.camera:setTargetOverrideFromNode(self.player.graphicsComponent.rightShoulderCameraNode)
	end
end
