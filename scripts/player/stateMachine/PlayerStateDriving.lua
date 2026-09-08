-- Local values: PlayerStateDriving_mt
PlayerStateDriving = {}
local PlayerStateDriving_mt = Class(PlayerStateDriving, BaseStateMachineState)
source("dataS/scripts/vehicles/VehicleEnterRequestEvent.lua")
source("dataS/scripts/vehicles/VehicleEnterResponseEvent.lua")
source("dataS/scripts/vehicles/VehicleLeaveEvent.lua")

-- Upvalues: PlayerStateDriving_mt
-- Local values: self
function PlayerStateDriving.new(player, stateMachine)
	-- upvalues: (copy) PlayerStateDriving_mt
	local v4_ = BaseStateMachineState.new(stateMachine, PlayerStateDriving_mt)
	v4_.player = player
	v4_.currentVehicle = nil
	v4_.player:addStateEvent(PlayerStateDriving.onEnterVehicle, v4_, "onEnterVehicle")
	return v4_
end

function PlayerStateDriving:calculateIfShouldBeForced()
	local v6_ = self:getIsInVehicle()
	if v6_ then
		v6_ = self.stateMachine.currentState ~= self.stateMachine.states.driving
	end
	return v6_
end

-- Local values: currentVehicle
function PlayerStateDriving:onEnterVehicle(vehicle)
	local v9_ = self.player:getCurrentVehicle()
	if v9_ ~= nil then
		self.player:leaveVehicle(v9_, true)
	end
	self.stateMachine:changeState(self, vehicle)
end

-- Local values: mission, oldContext, hud, playerHotspot
function PlayerStateDriving:onStateEntered(previousState, vehicle)
	local v12_ = g_currentMission
	if self.player.isOwner then
		local v13_ = g_inputBinding:getContextName()
		if v13_ ~= PlayerInputComponent.INPUT_CONTEXT_NAME then
			g_inputBinding:replaceContextInStack(PlayerInputComponent.INPUT_CONTEXT_NAME, Vehicle.INPUT_CONTEXT_NAME)
		end
		if v13_ == InputBinding.ROOT_CONTEXT_NAME or (v13_ == PlayerInputComponent.INPUT_CONTEXT_NAME or v13_ == PlayerInputComponent.INPUT_CONTEXT_NAME_ANIMAL_RIDING) then
			g_inputBinding:setContext(Vehicle.INPUT_CONTEXT_NAME, true, false)
		end
		local v14_ = v12_.hud
		v14_:setControlledVehicle(vehicle)
		v14_:setIsControllingPlayer(false)
		v14_:showVehicleName(vehicle:getUppercaseName())
		if v12_:getIsRadioPlaying() then
			if not vehicle.supportsRadio and g_gameSettings:getValue(GameSettings.SETTING.RADIO_VEHICLE_ONLY) then
				v12_:pauseRadio()
			end
		elseif vehicle.supportsRadio then
			v12_:playRadio()
		end
	end
	local v15_ = self.player.playerHotspot
	if v15_ ~= nil then
		v15_:setVehicle(vehicle)
	end
	self.currentVehicle = vehicle
	self.player:hide()
	vehicle:onPlayerEnterVehicle(self.player.isOwner, self.player.graphicsComponent:getStyle(), self.player.farmId, self.player.userId)
	g_messageCenter:publish(MessageType.VEHICLE_PLAYER_ENTERED, self.currentVehicle, self.player)
end

-- Local values: vehicleLeft, playerHotspot, mission
function PlayerStateDriving:onStateExited(newState, targetX, targetY, targetZ)
	if self.currentVehicle == nil then
		Logging.devInfo("PlayerStateDriving.onStateExited: Failed to exit driving state. Player Controlled: %s - Current Vehicle: %s", self.player:getIsControlled(), self.currentVehicle)
	else
		if targetX == nil or (targetY == nil or targetZ == nil) then
			if newState ~= nil then
				self.player:teleportToExitPoint(self.currentVehicle, true)
			end
		else
			self.player:teleportTo(targetX, targetY, targetZ, nil, true)
		end
		local v21_ = self.currentVehicle
		self.currentVehicle = nil
		local v22_ = self.player.playerHotspot
		if v22_ ~= nil then
			v22_:setVehicle(nil)
		end
		if self.player.isOwner then
			local v23_ = g_currentMission
			v23_.hud:setControlledVehicle(nil)
			if g_gameSettings:getValue(GameSettings.SETTING.RADIO_VEHICLE_ONLY) then
				v23_:pauseRadio()
			end
		end
		g_messageCenter:publish(MessageType.VEHICLE_PLAYER_LEFT, v21_, self.player)
	end
end

function PlayerStateDriving:getIsInVehicle()
	return self.currentVehicle ~= nil
end

function PlayerStateDriving:getCurrentVehicle()
	return self.currentVehicle
end

function PlayerStateDriving:getCurrentRootNode()
	return self.currentVehicle.rootNode
end

function PlayerStateDriving:getSpeed()
	return MathUtil.kmhToMps(self.currentVehicle:getLastSpeed())
end

function PlayerStateDriving:getPosition()
	return getWorldTranslation(self.currentVehicle.rootNode)
end

function PlayerStateDriving:getYaw()
	return self.currentVehicle:getMapHotspotRotation(false) - 3.141592653589793
end

-- Local values: yRot
function PlayerStateDriving:getCurrentFacingDirection()
	local v31_ = self.currentVehicle:getMapHotspotRotation(false) - 3.141592653589793
	return MathUtil.getDirectionFromYRotation(v31_)
end

-- Local values: enterable, vehicleCamera
function PlayerStateDriving:getCurrentCameraNode()
	local v33_ = self.currentVehicle.spec_enterable
	if v33_ == nil then
		Logging.error("Player has somehow entered a vehicle with no enterable spec, and needs the vehicle\'s camera!")
		return nil
	end
	local v34_ = v33_.cameras[v33_.camIndex]
	if v34_ ~= nil and (v34_.cameraNode ~= nil and v34_.cameraNode ~= 0) then
		return v34_.cameraNode
	end
	Logging.error("Player has somehow entered an enterable vehicle with no camera!")
	return nil
end

function PlayerStateDriving:updateWhileInConversation() end
