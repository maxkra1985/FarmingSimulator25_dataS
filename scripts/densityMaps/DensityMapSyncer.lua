-- Local values: DensityMapSyncer_mt
DensityMapSyncer = {}
local DensityMapSyncer_mt = Class(DensityMapSyncer)

-- Upvalues: DensityMapSyncer_mt
-- Local values: self
function DensityMapSyncer.new(terrainRootNode, defaultCellSize, customMt)
	-- upvalues: (copy) DensityMapSyncer_mt
	local v5_ = customMt or DensityMapSyncer_mt
	local v6_ = setmetatable({}, v5_)
	v6_.defaultCellSize = defaultCellSize
	v6_.updateListeners = {}
	v6_.syncerId = createDensityMapSyncer("DensityMapSyncer", terrainRootNode)
	return v6_
end

function DensityMapSyncer:delete()
	if self.syncerId ~= nil then
		delete(self.syncerId)
	end
end

function DensityMapSyncer:addDensityMap(densityMapId, usedByTerrainVT, cellSize, maxSyncDistance, deprioritizationDistance)
	if self.syncerId ~= nil then
		addDensityMapSyncerDensityMap(self.syncerId, densityMapId, cellSize or self.defaultCellSize, maxSyncDistance or 0, deprioritizationDistance or 0, usedByTerrainVT or false)
	end
end

function DensityMapSyncer:onDensityMapsAdded()
	if self.syncerId ~= nil then
		onDensityMapSyncerDensityMapsAdded(self.syncerId)
	end
end

function DensityMapSyncer:addConnection(streamId)
	if self.syncerId ~= nil then
		addDensityMapSyncerConnection(self.syncerId, streamId)
	end
end

function DensityMapSyncer:removeConnection(streamId)
	if self.syncerId ~= nil then
		removeDensityMapSyncerConnection(self.syncerId, streamId)
	end
end

-- Local values: densityStreamOffsetStart, densityStreamOffsetEnd, densityPacketSizeBits
function DensityMapSyncer:writeUpdateStream(connection, maxPacketSize, x, y, z, viewCoeff, networkDebug)
	if self.syncerId == nil then
		return 0
	end
	local v27_ = streamGetWriteOffset(connection.streamId)
	if networkDebug then
		streamWriteInt32(connection.streamId, 0)
	end
	writeDensityMapSyncerServerUpdateToStream(self.syncerId, connection.streamId, connection.streamId, x, y, z, viewCoeff, maxPacketSize, connection.lastSeqSent)
	local v28_ = streamGetWriteOffset(connection.streamId)
	local v29_ = v28_ - v27_
	g_server:addPacketSize(connection, NetworkNode.PACKET_DENSITY_MAPS, v29_ / 8)
	if networkDebug then
		streamSetWriteOffset(connection.streamId, v27_)
		streamWriteInt32(connection.streamId, v28_ - (v27_ + 32))
		streamSetWriteOffset(connection.streamId, v28_)
	end
	return v29_
end

-- Local values: startOffset, numBits
function DensityMapSyncer:readUpdateStream(connection, networkDebug)
	if self.syncerId ~= nil then
		local v33_, v34_
		if networkDebug then
			v33_ = streamGetReadOffset(connection.streamId)
			v34_ = streamReadInt32(connection.streamId)
		else
			v34_ = 0
			v33_ = 0
		end
		readDensityMapSyncerServerUpdateFromStream(self.syncerId, connection.streamId, g_clientInterpDelay, g_packetPhysicsNetworkTime, g_client.tickDuration)
		if networkDebug then
			g_client:checkObjectUpdateDebugReadSize(connection.streamId, v34_, v33_, "densitymapsyncer")
		end
	end
end

function DensityMapSyncer:onPacketLost(connection, packetId)
	if self.syncerId ~= nil then
		setDensityMapSyncerLostPacket(self.syncerId, connection.streamId, packetId)
	end
end

-- Local values: desc, densityMapId
function DensityMapSyncer:activateFruitUpdateCallback(fruitTypeIndex)
	local v40_ = g_fruitTypeManager:getFruitTypeByIndex(fruitTypeIndex)
	if v40_.terrainDataPlaneId == nil then
		return nil
	end
	local v41_ = v40_.foliageTransformGroupId
	if self.updateListeners[v41_] == nil then
		self.updateListeners[v41_] = {}
		setDensityMapSyncerCellChangedCallback(self.syncerId, v41_, "onCellUpdate", self)
	end
	return v41_
end

-- Local values: densityMapListeners, cellId, listeners, listener, _
function DensityMapSyncer:onCellUpdate(densityMapId, cellX, cellZ)
	local v46_ = self.updateListeners[densityMapId]
	if v46_ ~= nil then
		local v47_ = self:getCellId(densityMapId, cellX, cellZ)
		local v48_ = v46_[v47_]
		if v48_ ~= nil then
			for v49_, _ in pairs(v48_) do
				v49_:onDensityMapSyncerUpdate(densityMapId, cellX, cellZ, v47_)
			end
		end
	end
end

function DensityMapSyncer:getCellId(densityMapId, cellX, cellZ)
	return cellX * 65536 + cellZ
end

-- Local values: cellId, densityMapListeners, listeners
function DensityMapSyncer:addCellUpdateListener(listener, densityMapId, cellX, cellZ)
	local v57_ = self:getCellId(densityMapId, cellX, cellZ)
	local v58_ = self.updateListeners[densityMapId]
	if v58_ == nil then
		return nil
	end
	local v59_ = v58_[v57_]
	if v59_ == nil then
		v59_ = {}
		v58_[v57_] = v59_
		setEnableDensityMapSyncerCellChangedCallback(self.syncerId, densityMapId, cellX, cellZ, true)
	end
	if v59_[listener] == nil then
		v59_[listener] = 0
	end
	v59_[listener] = v59_[listener] + 1
	return v57_
end

-- Local values: cellId, densityMapListeners, listeners
function DensityMapSyncer:removeCellUpdateListener(listener, densityMapId, cellX, cellZ)
	local v65_ = self:getCellId(densityMapId, cellX, cellZ)
	local v66_ = self.updateListeners[densityMapId]
	if v66_ == nil then
		return false
	end
	local v67_ = v66_[v65_]
	if v67_ == nil then
		return false
	end
	if v67_[listener] == nil then
		return false
	end
	v67_[listener] = v67_[listener] - 1
	if v67_[listener] == 0 then
		v67_[listener] = nil
	end
	if next(v67_) == nil then
		v66_[v65_] = nil
		setEnableDensityMapSyncerCellChangedCallback(self.syncerId, densityMapId, cellX, cellZ, false)
	end
	return true
end

-- Local values: desc, densityMapId, cellX, cellZ
function DensityMapSyncer:getFruitCellIndicesAtWorldPosition(fruitTypeIndex, x, z)
	local v72_ = g_fruitTypeManager:getFruitTypeByIndex(fruitTypeIndex)
	if v72_.terrainDataPlaneId == nil then
		return nil
	end
	local v73_ = v72_.terrainDataPlaneId
	local v74_, v75_ = getDensityMapSyncerCellIndicesAtWorldPosition(self.syncerId, v73_, x, z)
	return v74_, v75_
end
