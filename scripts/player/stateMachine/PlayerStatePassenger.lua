-- Local values: PlayerStatePassenger_mt
PlayerStatePassenger = {}
local PlayerStatePassenger_mt = Class(PlayerStatePassenger, PlayerStateDriving)

-- Upvalues: PlayerStatePassenger_mt
-- Local values: self
function PlayerStatePassenger.new(player, stateMachine)
	-- upvalues: (copy) PlayerStatePassenger_mt
	local v4_ = BaseStateMachineState.new(stateMachine, PlayerStatePassenger_mt)
	v4_.player = player
	v4_.currentVehicle = nil
	v4_.player:addStateEvent(PlayerStatePassenger.onEnterVehicleAsPassenger, v4_, "onEnterVehicleAsPassenger")
	return v4_
end

function PlayerStatePassenger:calculateIfShouldBeForced()
	local v6_ = self:getIsInVehicle()
	if v6_ then
		v6_ = self.stateMachine.currentState ~= self.stateMachine.states.passenger
	end
	return v6_
end

-- Local values: currentVehicle
function PlayerStatePassenger:onEnterVehicleAsPassenger(vehicle, seatIndex)
	local v10_ = self.player:getCurrentVehicle()
	if v10_ ~= nil then
		self.player:leaveVehicle(v10_, true)
	end
	self.stateMachine:changeState(self, vehicle, seatIndex)
end

-- Local values: mission, oldContext, hud
function PlayerStatePassenger:onStateEntered(previousState, vehicle, seatIndex)
	local v14_ = g_currentMission
	self.currentVehicle = vehicle
	if self.player.isOwner then
		local v15_ = g_inputBinding:getContextName()
		if v15_ ~= PlayerInputComponent.INPUT_CONTEXT_NAME then
			g_inputBinding:replaceContextInStack(PlayerInputComponent.INPUT_CONTEXT_NAME, Vehicle.INPUT_CONTEXT_NAME)
		end
		if v15_ == InputBinding.ROOT_CONTEXT_NAME or v15_ == PlayerInputComponent.INPUT_CONTEXT_NAME then
			g_inputBinding:setContext(Vehicle.INPUT_CONTEXT_NAME, true, false)
		end
		vehicle:enterVehiclePassengerSeat(self.player.isOwner, seatIndex, self.player.graphicsComponent:getStyle(), self.player.userId)
		local v16_ = g_currentMission.hud
		v16_:setControlledVehicle(vehicle)
		v16_:setIsControllingPlayer(false)
		v16_:showVehicleName(vehicle:getUppercaseName())
		if v14_:getIsRadioPlaying() then
			if not vehicle.supportsRadio and g_gameSettings:getValue(GameSettings.SETTING.RADIO_VEHICLE_ONLY) then
				v14_:pauseRadio()
			end
		elseif vehicle.supportsRadio then
			v14_:playRadio()
		end
	else
		vehicle:enterVehiclePassengerSeat(self.player.isOwner, seatIndex, self.player.graphicsComponent:getStyle(), self.player.userId)
	end
	self.player:hide()
	g_messageCenter:publish(MessageType.VEHICLE_PLAYER_ENTERED, self.currentVehicle, self.player)
end

-- Local values: vehicleLeft
function PlayerStatePassenger:onStateExited(newState, targetX, targetY, targetZ)
	if self.currentVehicle == nil then
		Logging.devInfo("PlayerStatePassenger.onStateExited: Failed to exit passenger state. Player Controlled: %s - Current Vehicle: %s", self.player:getIsControlled(), self.currentVehicle)
	else
		if targetX == nil or (targetY == nil or targetZ == nil) then
			if newState ~= nil then
				self.player:teleportToExitPoint(self.currentVehicle, true)
			end
		else
			self.player:teleportTo(targetX, targetY, targetZ, nil, true)
		end
		local v22_ = self.currentVehicle
		self.currentVehicle = nil
		if self.player.isOwner then
			g_currentMission.hud:setControlledVehicle(nil)
			if g_gameSettings:getValue(GameSettings.SETTING.RADIO_VEHICLE_ONLY) then
				g_currentMission:pauseRadio()
			end
		end
		g_messageCenter:publish(MessageType.VEHICLE_PLAYER_LEFT, v22_, self.player)
	end
end

function PlayerStatePassenger:getIsInVehicle()
	return self.currentVehicle ~= nil
end

function PlayerStatePassenger:getCurrentVehicle()
	return self.currentVehicle
end

function PlayerStatePassenger:getCurrentRootNode()
	return self.currentVehicle.rootNode
end

function PlayerStatePassenger:getSpeed()
	return MathUtil.kmhToMps(self.currentVehicle:getLastSpeed())
end

function PlayerStatePassenger:getPosition()
	return getWorldTranslation(self.currentVehicle.rootNode)
end

-- Local values: vehicleForwardX, _, vehicleForwardZ
function PlayerStatePassenger:getYaw()
	local v29_, _, v30_ = localDirectionToWorld(self.currentVehicle.rootNode, 0, 0, 1)
	return MathUtil.getYRotationFromDirection(v29_, v30_)
end

-- Local values: vehicleForwardX, _, vehicleForwardZ
function PlayerStatePassenger:getCurrentFacingDirection()
	local v32_, _, v33_ = localDirectionToWorld(self.currentVehicle.rootNode, 0, 0, 1)
	return v32_, v33_
end

-- Local values: enterable, vehicleCamera
function PlayerStatePassenger:getCurrentCameraNode()
	local v35_ = self.currentVehicle.spec_enterable
	if v35_ == nil then
		Logging.error("Player has somehow entered a vehicle with no enterable spec, and needs the vehicle\'s camera!")
		return nil
	end
	local v36_ = v35_.cameras[v35_.camIndex]
	if v36_ ~= nil and (v36_.cameraNode ~= nil and v36_.cameraNode ~= 0) then
		return v36_.cameraNode
	end
	Logging.error("Player has somehow entered an enterable vehicle with no camera!")
	return nil
end
