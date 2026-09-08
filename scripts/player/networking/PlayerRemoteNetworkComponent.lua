-- Local values: PlayerRemoteNetworkComponent_mt
PlayerRemoteNetworkComponent = {}
local PlayerRemoteNetworkComponent_mt = Class(PlayerRemoteNetworkComponent, PlayerNetworkComponent)

-- Upvalues: PlayerRemoteNetworkComponent_mt
-- Local values: self
function PlayerRemoteNetworkComponent.new(player)
	-- upvalues: (copy) PlayerRemoteNetworkComponent_mt
	local v3_ = PlayerNetworkComponent.new(player, PlayerRemoteNetworkComponent_mt)
	v3_.player = player
	return v3_
end

-- Local values: isControlled, skipModel, skipMover, receivedPositionX, receivedPositionY, receivedPositionZ, receivedYaw, isGrounded, isFirstPerson, isCrouching, isVisible, interpolator
function PlayerRemoteNetworkComponent:readUpdateStream(streamId, connection, timestamp)
	PlayerRemoteNetworkComponent:superClass().readUpdateStream(self, streamId, connection, timestamp)
	local v8_ = streamReadBool(streamId)
	local v9_ = streamReadBool(streamId)
	local v10_ = streamReadBool(streamId)
	self.player:updateControlledState(v8_, v9_, v10_)
	local v11_ = streamReadFloat32(streamId)
	local v12_ = streamReadFloat32(streamId)
	local v13_ = streamReadFloat32(streamId)
	local v14_ = NetworkUtil.readCompressedAngle(streamId)
	local v15_ = streamReadBool(streamId)
	local v16_ = streamReadBool(streamId)
	local v17_ = streamReadBool(streamId)
	local v18_ = streamReadBool(streamId)
	self.player.graphicsComponent:setGraphicsRootNodeVisibility(v18_)
	local v19_ = self.player.positionalInterpolator
	v19_:setTargetPosition(v11_, v12_, v13_)
	v19_:setTargetYaw(v14_)
	v19_:startNetworkNewPhase()
	self.player.mover.isGrounded = v15_
	self.player.mover:setIsCrouching(v17_)
	self.player.isFirstPerson = v16_
end
