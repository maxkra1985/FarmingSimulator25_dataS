-- Local values: PlayerServerNetworkComponent_mt
PlayerServerNetworkComponent = {}
local PlayerServerNetworkComponent_mt = Class(PlayerServerNetworkComponent, PlayerNetworkComponent)

-- Upvalues: PlayerServerNetworkComponent_mt
-- Local values: self
function PlayerServerNetworkComponent.new(player)
	-- upvalues: (copy) PlayerServerNetworkComponent_mt
	local v3_ = PlayerNetworkComponent.new(player, PlayerServerNetworkComponent_mt)
	v3_.player = player
	if not player.isOwner then
		v3_.tickHistory = {}
		v3_.nextSendTick = 0
	end
	v3_.skipModel = false
	v3_.skipMover = false
	v3_.isFirstPerson = false
	return v3_
end

function PlayerServerNetworkComponent:setShowHideParameters(skipModel, skipMover)
	self.skipModel = skipModel == true
	self.skipMover = skipMover == true
end

function PlayerServerNetworkComponent:reset()
	if self.tickHistory ~= nil then
		table.clear(self.tickHistory)
	end
end

function PlayerServerNetworkComponent:update(dt) end

-- Local values: latestSimulatedIndex, history
function PlayerServerNetworkComponent:updateTick(dt)
	if not self.player.isOwner then
		local v9_ = self.tickHistory[1]
		local v10_ = -1
		while v9_ ~= nil and getIsPhysicsUpdateIndexSimulated(v9_.physicsIndex) do
			v10_ = v9_.index
			table.remove(self.tickHistory, 1)
			v9_ = self.tickHistory[1]
		end
		if v10_ >= 0 then
			self.nextSendTick = v10_
			self.player:raiseDefaultDirtyFlag()
		end
	end
	self.doNextDebugDrawTick = true
end

-- Local values: isTargetPlayer, positionX, positionY, positionZ, yaw, isGrounded
function PlayerServerNetworkComponent:writeUpdateStream(streamId, connection, dirtyMask)
	PlayerServerNetworkComponent:superClass().writeUpdateStream(self, streamId, connection, dirtyMask)
	local v15_ = connection == self.player.connection
	if v15_ then
		streamWriteUInt32(streamId, self.nextSendTick)
	end
	streamWriteBool(streamId, self.player.isControlled)
	streamWriteBool(streamId, self.skipModel)
	streamWriteBool(streamId, self.skipMover)
	local v16_, v17_, v18_ = self.player.mover:getPosition()
	streamWriteFloat32(streamId, v16_)
	streamWriteFloat32(streamId, v17_)
	streamWriteFloat32(streamId, v18_)
	if not v15_ then
		local v19_ = self.player.mover:getMovementYaw()
		NetworkUtil.writeCompressedAngle(streamId, v19_)
		local v20_ = self.player.capsuleController:calculateIfBottomTouchesGround()
		streamWriteBool(streamId, v20_)
		if self.player.isOwner then
			streamWriteBool(streamId, self.player.camera.isFirstPerson)
		else
			streamWriteBool(streamId, self.isFirstPerson)
		end
		streamWriteBool(streamId, self.player.mover.isCrouching)
		streamWriteBool(streamId, self.player.graphicsComponent.isGraphicsRootNodeVisible)
	end
end

-- Local values: tickIndex, movementX, movementY, movementZ, movementYaw, isCrouching, interpolator, physicsIndex
function PlayerServerNetworkComponent:readUpdateStream(streamId, connection, timestamp)
	PlayerServerNetworkComponent:superClass().readUpdateStream(self, streamId, connection, timestamp)
	if not self.player.isOwner then
		local v25_ = streamReadUInt32(streamId)
		local v26_ = streamReadFloat32(streamId)
		local v27_ = streamReadFloat32(streamId)
		local v28_ = streamReadFloat32(streamId)
		local v29_ = NetworkUtil.readCompressedAngle(streamId)
		self.isFirstPerson = streamReadBool(streamId)
		local v30_ = streamReadBool(streamId)
		self.player.capsuleController:move(v26_, v27_, v28_)
		self.player.mover:setMovementYaw(v29_)
		self.player.mover:setIsCrouching(v30_)
		local v31_ = self.player.positionalInterpolator
		v31_:startNetworkNewPhase()
		v31_:setTargetYaw(v29_)
		local v32_ = getPhysicsUpdateIndex()
		local v33_ = self.tickHistory
		table.insert(v33_, {
			["index"] = v25_,
			["physicsIndex"] = v32_
		})
		v31_:setTargetPhysicsIndex(v32_)
	end
end
