-- Local values: PlayerGraphicsState_mt
PlayerGraphicsState = {}
local PlayerGraphicsState_mt = Class(PlayerGraphicsState, HumanGraphicsComponentState)
function PlayerGraphicsState.new()
	-- upvalues: (copy) PlayerGraphicsState_mt
	return HumanGraphicsComponentState.new(PlayerGraphicsState_mt)
end

-- Local values: onFootStateMachine, mover, speed, maxWalkingSpeed, graphicalVelocityX, graphicalVelocityY, graphicalVelocityZ
function PlayerGraphicsState:updateLocal(player)
	if player.stateMachine.states.onFoot == player.stateMachine.currentState then
		if player.isOwner and g_gui:getIsGuiVisible() then
			self:setDefault()
		else
			local v4_ = player.mover
			local v5_ = player:getGraphicalSpeed()
			local v6_ = PlayerStateWalk.MAXIMUM_WALK_SPEED + 0.5
			local v7_, v8_, v9_ = player:getGraphicalVelocity()
			local v10_, v11_ = player.mover:getLocalMovementDirection(v7_, v9_)
			self.movementDirX = v10_
			self.movementDirZ = v11_
			self.absSpeed = v5_
			self.relativeVelocityX = 0
			self.relativeVelocityY = v8_
			self.relativeVelocityZ = 0
			self.rotationVelocity = 0
			self.distanceToGround = v4_.currentGroundDistance
			self.isCloseToGround = v4_.isCloseToGround
			self.isIdling = v5_ < 0.1
			local v12_
			if v5_ >= 0.1 then
				v12_ = v5_ < v6_
			else
				v12_ = false
			end
			self.isWalking = v12_
			self.isRunning = v6_ <= v5_
			self.isCrouching = v4_.isCrouching
			local v13_ = v4_.isGrounded
			if v13_ then
				v13_ = not v4_.isSwimming
			end
			self.isGrounded = v13_
			self.isInWater = v4_.isInWater
			self.isSwimming = v4_.isSwimming
			self.isStrafeWalkMode = player.isStrafeWalkMode
			self.isFirstPerson = player.camera.isFirstPerson
			self.isHoldingChainsaw = player.isHoldingChainsaw
		end
	else
		return
	end
end

-- Local values: mover, speed, maxWalkingSpeed, graphicalVelocityX, graphicalVelocityY, graphicalVelocityZ, smoothedSpeed
function PlayerGraphicsState:updateRemote(player)
	local v16_ = player.mover
	local v17_ = player:getGraphicalSpeed()
	local v18_ = PlayerStateWalk.MAXIMUM_WALK_SPEED + 2
	local v19_, v20_, v21_ = player:getGraphicalVelocity()
	local v22_, v23_ = player.mover:getLocalMovementDirection(v19_, v21_)
	self.movementDirX = v22_
	self.movementDirZ = v23_
	local v24_ = self.absSpeed * 0.8 + v17_ * 0.2
	self.absSpeed = v24_
	self.relativeVelocityX = 0
	self.relativeVelocityY = v20_
	self.relativeVelocityZ = 0
	self.rotationVelocity = 0
	self.distanceToGround = v16_.currentGroundDistance
	self.isCloseToGround = v16_.isCloseToGround
	self.isIdling = v24_ < 0.1
	local v25_
	if v24_ >= 0.1 then
		v25_ = v24_ < v18_
	else
		v25_ = false
	end
	self.isWalking = v25_
	self.isRunning = v18_ <= v24_
	self.isCrouching = v16_.isCrouching
	local v26_ = v16_.isGrounded
	if v26_ then
		v26_ = not v16_.isSwimming
	end
	self.isGrounded = v26_
	self.isInWater = v16_.isInWater
	self.isSwimming = v16_.isSwimming
	self.isStrafeWalkMode = player.isStrafeWalkMode
	self.isFirstPerson = player.isFirstPerson
	self.isHoldingChainsaw = player.isHoldingChainsaw
	self.isCutting = player.isCutting
	self.isVerticalCut = player.isVerticalCut
end
