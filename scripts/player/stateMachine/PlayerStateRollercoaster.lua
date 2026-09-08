-- Local values: PlayerStateRollercoaster_mt
PlayerStateRollercoaster = {}
local PlayerStateRollercoaster_mt = Class(PlayerStateRollercoaster, PlayerStateDriving)

-- Upvalues: PlayerStateRollercoaster_mt
-- Local values: self
function PlayerStateRollercoaster.new(player, stateMachine)
	-- upvalues: (copy) PlayerStateRollercoaster_mt
	local v4_ = BaseStateMachineState.new(stateMachine, PlayerStateRollercoaster_mt)
	v4_.player = player
	v4_.rollercoaster = nil
	v4_.player:addStateEvent(PlayerStateRollercoaster.onEnterRollercoaster, v4_, "onEnterRollercoaster")
	return v4_
end

function PlayerStateRollercoaster:calculateIfShouldBeForced()
	local v6_ = self:getIsInRollercoaster()
	if v6_ then
		v6_ = self.stateMachine.currentState ~= self.stateMachine.states.rollercoaster
	end
	return v6_
end

-- Local values: currentVehicle
function PlayerStateRollercoaster:onEnterRollercoaster(rollercoaster, seatIndex)
	local v10_ = self.player:getCurrentVehicle()
	if v10_ ~= nil then
		self.player:leaveVehicle(v10_, true)
	end
	self.stateMachine:changeState(self, rollercoaster, seatIndex)
end

-- Local values: hud, rollercoasterSpec, seat, camera
function PlayerStateRollercoaster:onStateEntered(previousState, rollercoaster, seatIndex)
	self.rollercoaster = rollercoaster
	self.seatIndex = seatIndex
	if self.player.isOwner then
		g_inputBinding:setContext(PlaceableRollercoaster.INPUT_CONTEXT_ROLLERCOASTER, true)
		g_currentMission.hud:setIsControllingPlayer(false)
	end
	rollercoaster:enterRide(seatIndex, self.player)
	self.player:hide()
	local v14_ = self.rollercoaster.spec_rollercoaster.seats[seatIndex]
	if v14_ == nil then
		Logging.error("Player seat not defined for seat index \'%s\'!", self.seatIndex)
		return
	else
		local v15_ = v14_.camera
		if v15_ == nil then
			Logging.error("No rollercoaster camera defined for seat \'%s\'!", self.seatIndex)
		else
			self.cameraNode = v15_.cameraNode
		end
	end
end

-- Local values: spec, exitNodeIndex, exitNode, x, y, z
function PlayerStateRollercoaster:onStateExited(newState)
	if self.rollercoaster == nil then
		Logging.devInfo("PlayerStateRollercoaster.onStateExited: Failed to exit rollercoaster state. Player Controlled: %s - rollercoaster: %s", self.player:getIsControlled(), self.rollercoaster)
	else
		local v17_ = self.rollercoaster.spec_rollercoaster
		local v18_ = (self.seatIndex - 1) % #v17_.exitPoints + 1
		local v19_ = v17_.exitPoints[v18_]
		local v20_, v21_, v22_ = getWorldTranslation(v19_)
		self.player:teleportTo(v20_, v21_, v22_, true, true)
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

-- Local values: cameraForwardX, _, cameraForwardZ
function PlayerStateRollercoaster:getYaw()
	local v27_, _, v28_ = localDirectionToWorld(self.cameraNode, 0, 0, -1)
	return MathUtil.getYRotationFromDirection(v27_, v28_)
end

-- Local values: cameraForwardX, _, cameraForwardZ
function PlayerStateRollercoaster:getCurrentFacingDirection()
	local v30_, _, v31_ = localDirectionToWorld(self.cameraNode, 0, 0, -1)
	return v30_, v31_
end

function PlayerStateRollercoaster:getCurrentCameraNode()
	return self.cameraNode
end
