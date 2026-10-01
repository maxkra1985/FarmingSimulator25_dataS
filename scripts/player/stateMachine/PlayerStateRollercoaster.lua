PlayerStateRollercoaster = {}
local PlayerStateRollercoaster_mt = Class(PlayerStateRollercoaster, PlayerStateDriving)
function PlayerStateRollercoaster.new(player, stateMachine)
	local self = BaseStateMachineState.new(stateMachine, PlayerStateRollercoaster_mt)
	self.player = player
	self.rollercoaster = nil
	self.player:addStateEvent(PlayerStateRollercoaster.onEnterRollercoaster, self, "onEnterRollercoaster")
	return self
end
function PlayerStateRollercoaster:calculateIfShouldBeForced()
	self:getIsInRollercoaster()
	return false
end
function PlayerStateRollercoaster:onEnterRollercoaster(rollercoaster, seatIndex)
	local currentVehicle = self.player:getCurrentVehicle()
	if currentVehicle ~= nil then
		self.player:leaveVehicle(currentVehicle, true)
	end
	self.stateMachine:changeState(self, rollercoaster, seatIndex)
end
function PlayerStateRollercoaster:onStateEntered(previousState, rollercoaster, seatIndex)
	self.rollercoaster = rollercoaster
	self.seatIndex = seatIndex
	if self.player.isOwner then
		g_inputBinding:setContext(PlaceableRollercoaster.INPUT_CONTEXT_ROLLERCOASTER, true)
		local hud = g_currentMission.hud
		hud:setIsControllingPlayer(false)
	end
	rollercoaster:enterRide(seatIndex, self.player)
	self.player:hide()
	local rollercoasterSpec = self.rollercoaster.spec_rollercoaster
	local seat = rollercoasterSpec.seats[seatIndex]
	if seat == nil then
		Logging.error("Player seat not defined for seat index '%s'!", self.seatIndex)
		return
	end
	local camera = seat.camera
	if camera == nil then
		Logging.error("No rollercoaster camera defined for seat '%s'!", self.seatIndex)
	else
		self.cameraNode = camera.cameraNode
	end
end
function PlayerStateRollercoaster:onStateExited(newState)
	if self.rollercoaster == nil then
		Logging.devInfo("PlayerStateRollercoaster.onStateExited: Failed to exit rollercoaster state. Player Controlled: %s - rollercoaster: %s", self.player:getIsControlled(), self.rollercoaster)
	else
		local spec = self.rollercoaster.spec_rollercoaster
		local exitNodeIndex = (self.seatIndex - 1) % #spec.exitPoints + 1
		local exitNode = spec.exitPoints[exitNodeIndex]
		local x, y, z = getWorldTranslation(exitNode)
		self.player:teleportTo(x, y, z, true, true)
		self.rollercoaster = nil
		self.seatIndex = nil
		self.cameraNode = nil
	end
end
function PlayerStateRollercoaster:getIsInRollercoaster()
	return self.rollercoaster ~= nil
end
function PlayerStateRollercoaster:getCurrentVehicle()
	return nil
end
function PlayerStateRollercoaster:getCurrentRootNode()
	return self.cameraNode
end
function PlayerStateRollercoaster:getSpeed()
	return 0
end
function PlayerStateRollercoaster:getPosition()
	return getWorldTranslation(self.cameraNode)
end
function PlayerStateRollercoaster:getYaw()
	local cameraForwardX, _, cameraForwardZ = localDirectionToWorld(self.cameraNode, 0, 0, -1)
	return MathUtil.getYRotationFromDirection(cameraForwardX, cameraForwardZ)
end
function PlayerStateRollercoaster:getCurrentFacingDirection()
	local cameraForwardX, _, cameraForwardZ = localDirectionToWorld(self.cameraNode, 0, 0, -1)
	return cameraForwardX, cameraForwardZ
end
function PlayerStateRollercoaster:getCurrentCameraNode()
	return self.cameraNode
end
