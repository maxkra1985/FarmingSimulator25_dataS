PlayerServerNetworkComponent = {}
local PlayerServerNetworkComponent_mt = Class(PlayerServerNetworkComponent, PlayerNetworkComponent)
function PlayerServerNetworkComponent.new(player)
	local self = PlayerNetworkComponent.new(player, PlayerServerNetworkComponent_mt)
	self.player = player
	if not player.isOwner then
		self.tickHistory = {}
		self.nextSendTick = 0
	end
	self.skipModel = false
	self.skipMover = false
	self.isFirstPerson = false
	return self
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
function PlayerServerNetworkComponent:updateTick(dt)
	if not self.player.isOwner then
		local latestSimulatedIndex = -1
		local history = self.tickHistory[1]
		while history ~= nil do
			if getIsPhysicsUpdateIndexSimulated(history.physicsIndex) then
				latestSimulatedIndex = history.index
				table.remove(self.tickHistory, 1)
				history = self.tickHistory[1]
			end
		end
		if 0 <= latestSimulatedIndex then
			self.nextSendTick = latestSimulatedIndex
			self.player:raiseDefaultDirtyFlag()
		end
	end
	self.doNextDebugDrawTick = true
end
function PlayerServerNetworkComponent:writeUpdateStream(streamId, connection, dirtyMask)
	PlayerServerNetworkComponent:superClass().writeUpdateStream(self, streamId, connection, dirtyMask)
	local isTargetPlayer = connection == self.player.connection
	if isTargetPlayer then
		streamWriteUInt32(streamId, self.nextSendTick)
	end
	streamWriteBool(streamId, self.player.isControlled)
	streamWriteBool(streamId, self.skipModel)
	streamWriteBool(streamId, self.skipMover)
	local positionX, positionY, positionZ = self.player.mover:getPosition()
	streamWriteFloat32(streamId, positionX)
	streamWriteFloat32(streamId, positionY)
	streamWriteFloat32(streamId, positionZ)
	if not isTargetPlayer then
		local yaw = self.player.mover:getMovementYaw()
		NetworkUtil.writeCompressedAngle(streamId, yaw)
		local isGrounded = self.player.capsuleController:calculateIfBottomTouchesGround()
		streamWriteBool(streamId, isGrounded)
		if self.player.isOwner then
			streamWriteBool(streamId, self.player.camera.isFirstPerson)
		else
			streamWriteBool(streamId, self.isFirstPerson)
		end
		streamWriteBool(streamId, self.player.mover.isCrouching)
		streamWriteBool(streamId, self.player.graphicsComponent.isGraphicsRootNodeVisible)
	end
end
function PlayerServerNetworkComponent:readUpdateStream(streamId, connection, timestamp)
	PlayerServerNetworkComponent:superClass().readUpdateStream(self, streamId, connection, timestamp)
	if self.player.isOwner then
		return
	else
		local tickIndex = streamReadUInt32(streamId)
		local movementX = streamReadFloat32(streamId)
		local movementY = streamReadFloat32(streamId)
		local movementZ = streamReadFloat32(streamId)
		local movementYaw = NetworkUtil.readCompressedAngle(streamId)
		self.isFirstPerson = streamReadBool(streamId)
		local isCrouching = streamReadBool(streamId)
		self.player.capsuleController:move(movementX, movementY, movementZ)
		self.player.mover:setMovementYaw(movementYaw)
		self.player.mover:setIsCrouching(isCrouching)
		local interpolator = self.player.positionalInterpolator
		interpolator:startNetworkNewPhase()
		interpolator:setTargetYaw(movementYaw)
		local physicsIndex = getPhysicsUpdateIndex()
		table.insert(self.tickHistory, { index = tickIndex, physicsIndex = physicsIndex })
		interpolator:setTargetPhysicsIndex(physicsIndex)
	end
end
