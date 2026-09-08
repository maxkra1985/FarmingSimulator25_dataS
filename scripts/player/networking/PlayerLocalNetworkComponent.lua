-- Local values: PlayerLocalNetworkComponent_mt
PlayerLocalNetworkComponent = {}
local PlayerLocalNetworkComponent_mt = Class(PlayerLocalNetworkComponent, PlayerNetworkComponent)
PlayerLocalNetworkComponent.NETWORK_HISTORY_MAX_LENGTH = 100

-- Upvalues: PlayerLocalNetworkComponent_mt
-- Local values: self
function PlayerLocalNetworkComponent.new(player)
	-- upvalues: (copy) PlayerLocalNetworkComponent_mt
	local v3_ = PlayerNetworkComponent.new(player, PlayerLocalNetworkComponent_mt)
	v3_.player = player
	v3_.tickHistory = {}
	v3_.currentTickIndex = 0
	v3_.movementX = 0
	v3_.movementY = 0
	v3_.movementZ = 0
	v3_.movementYaw = 0
	return v3_
end

function PlayerLocalNetworkComponent:reset()
	if self.tickHistory ~= nil then
		table.clear(self.tickHistory)
	end
end

-- Local values: history, currentTickHistory
function PlayerLocalNetworkComponent:update(dt)
	if self.needNewTick then
		self.currentTickIndex = self.currentTickIndex + 1
		while #self.tickHistory > PlayerLocalNetworkComponent.NETWORK_HISTORY_MAX_LENGTH do
			table.remove(self.tickHistory, 1)
		end
		local v6_ = {
			["tickIndex"] = self.currentTickIndex,
			["movementX"] = 0,
			["movementY"] = 0,
			["movementZ"] = 0
		}
		local v7_ = self.tickHistory
		table.insert(v7_, v6_)
		self.needNewTick = false
	end
	self.movementX = self.movementX + self.player.mover.positionDeltaX
	self.movementY = self.movementY + self.player.mover.positionDeltaY
	self.movementZ = self.movementZ + self.player.mover.positionDeltaZ
	self.movementYaw = self.player.mover:getMovementYaw()
	local v8_ = self.tickHistory[#self.tickHistory]
	if v8_ ~= nil then
		v8_.movementX = v8_.movementX + self.player.mover.positionDeltaX
		v8_.movementY = v8_.movementY + self.player.mover.positionDeltaY
		v8_.movementZ = v8_.movementZ + self.player.mover.positionDeltaZ
	end
end

function PlayerLocalNetworkComponent:updateTick(dt)
	self.needNewTick = true
end

function PlayerLocalNetworkComponent:writeUpdateStream(streamId, connection, dirtyMask)
	PlayerLocalNetworkComponent:superClass().writeUpdateStream(self, streamId, connection, dirtyMask)
	streamWriteUInt32(streamId, self.currentTickIndex)
	streamWriteFloat32(streamId, self.movementX)
	streamWriteFloat32(streamId, self.movementY)
	streamWriteFloat32(streamId, self.movementZ)
	NetworkUtil.writeCompressedAngle(streamId, self.movementYaw)
	streamWriteBool(streamId, self.player.camera.isFirstPerson)
	streamWriteBool(streamId, self.player.mover.isCrouching)
	self.movementX = 0
	self.movementY = 0
	self.movementZ = 0
	self.movementYaw = 0
end

-- Local values: tickIndex, isControlled, skipModel, skipMover, receivedPositionX, receivedPositionY, receivedPositionZ, historyToDelete, numHistoryEntries, numAggregationTicks, totalMovementX, totalMovementY, totalMovementZ, numSteps, _, history
function PlayerLocalNetworkComponent:readUpdateStream(streamId, connection, timestamp)
	PlayerLocalNetworkComponent:superClass().readUpdateStream(self, streamId, connection, timestamp)
	local v18_ = streamReadUInt32(streamId)
	local v19_ = streamReadBool(streamId)
	local v20_ = streamReadBool(streamId)
	local v21_ = streamReadBool(streamId)
	self.player:updateControlledState(v19_, v20_, v21_)
	local v22_ = streamReadFloat32(streamId)
	local v23_ = streamReadFloat32(streamId)
	local v24_ = streamReadFloat32(streamId)
	self.player.mover:setPosition(v22_, v23_, v24_)
	local v25_ = self.tickHistory[1]
	while v25_ ~= nil and v25_.tickIndex <= v18_ do
		table.remove(self.tickHistory, 1)
		v25_ = self.tickHistory[1]
	end
	local v26_ = #self.tickHistory / 5
	local v27_ = math.ceil(v26_)
	local v28_ = nil
	local v29_ = nil
	local v30_ = nil
	local v31_ = 0
	for _, v32_ in ipairs(self.tickHistory) do
		if v28_ == nil then
			v28_ = 0
			v29_ = 0
			v30_ = 0
		end
		v28_ = v28_ + v32_.movementX
		v29_ = v29_ + v32_.movementY
		v30_ = v30_ + v32_.movementZ
		v31_ = v31_ + 1
		if v27_ <= v31_ then
			self.player.capsuleController:move(v28_, v29_, v30_)
			v28_ = nil
			v31_ = 0
		end
	end
	if v31_ > 0 then
		self.player.capsuleController:move(v28_, v29_, v30_)
	end
end
