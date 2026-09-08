-- Local values: TerrainDeformationSyncer_mt
TerrainDeformationSyncer = {}
TerrainDeformationSyncer.DEBUG_ENABLED = false
TerrainDeformationSyncer.DEBUG_COLOR = Color.new(0, 1, 0, 0.15)
local TerrainDeformationSyncer_mt = Class(TerrainDeformationSyncer)

-- Upvalues: TerrainDeformationSyncer_mt
-- Local values: self, numCellsPerSide
function TerrainDeformationSyncer.new(terrainNode, terrainSize, customMt)
	-- upvalues: (copy) TerrainDeformationSyncer_mt
	local v5_ = customMt or TerrainDeformationSyncer_mt
	local v6_ = setmetatable({}, v5_)
	v6_.terrainNode = terrainNode
	v6_.updateListeners = {}
	v6_.cellSize = 4
	local v7_ = terrainSize / v6_.cellSize
	setTerrainHeightSyncerCellChangedCallback(terrainNode, "onCellUpdate", v7_, v6_)
	v6_.cellIdOffset = v7_ * v7_
	addConsoleCommand("gsTerrainDeformationDebug", "Toggles debug mode", "consoleCommandToggleDebug", v6_)
	return v6_
end

-- Local values: cellId, cellX, cellZ
function TerrainDeformationSyncer:delete()
	removeConsoleCommand("gsTerrainDeformationDebug")
	for v9_ in pairs(self.updateListeners) do
		local v10_, v11_ = self:getCellIndicesById(v9_)
		setEnableTerrainHeightSyncerCellChangedCallback(self.terrainNode, v10_, v11_, false)
	end
	table.clear(self.updateListeners)
end

-- Local values: terrainStreamOffsetStart, terrainStreamOffsetEnd, terrainPacketSizeBits
function TerrainDeformationSyncer:writeUpdateStream(connection, maxPacketSize, x, y, z, viewCoeff, networkDebug)
	local v19_ = streamGetWriteOffset(connection.streamId)
	if networkDebug then
		streamWriteInt32(connection.streamId, 0)
	end
	writeTerrainUpdateStream(self.terrainNode, connection.streamId, connection.streamId, maxPacketSize, x, y, z)
	local v20_ = streamGetWriteOffset(connection.streamId)
	local v21_ = v20_ - v19_
	g_server:addPacketSize(connection, NetworkNode.PACKET_TERRAIN_DEFORM, v21_ / 8)
	if networkDebug then
		streamSetWriteOffset(connection.streamId, v19_)
		streamWriteInt32(connection.streamId, v20_ - (v19_ + 32))
		streamSetWriteOffset(connection.streamId, v20_)
	end
	return v21_
end

-- Local values: startOffset, numBits
function TerrainDeformationSyncer:readUpdateStream(connection, networkDebug)
	local v25_, v26_
	if networkDebug then
		v25_ = streamGetReadOffset(connection.streamId)
		v26_ = streamReadInt32(connection.streamId)
	else
		v26_ = 0
		v25_ = 0
	end
	readTerrainUpdateStream(self.terrainNode, connection.streamId)
	if networkDebug then
		g_client:checkObjectUpdateDebugReadSize(connection.streamId, v26_, v25_, "terrainmods")
	end
end

-- Local values: cellId, listeners, cellX, cellZ, startX, startZ, widthX, widthZ, heightX, heightZ, text
function TerrainDeformationSyncer:draw()
	if TerrainDeformationSyncer.DEBUG_ENABLED then
		for v28_, _ in pairs(self.updateListeners) do
			local v29_, v30_ = self:getCellIndicesById(v28_)
			local v31_ = v29_ * self.cellSize - g_currentMission.terrainSize * 0.5
			local v32_ = v30_ * self.cellSize - g_currentMission.terrainSize * 0.5
			local v33_ = v31_ + self.cellSize
			local v34_ = v32_ + self.cellSize
			local v35_ = tostring(v28_)
			DebugPlane.renderWithPositions(v31_, 0, v32_, v33_, 0, v32_, v31_, 0, v34_, TerrainDeformationSyncer.DEBUG_COLOR, true, true, true, false, v35_)
		end
	end
end

-- Local values: cellX, cellZ, inRange
function TerrainDeformationSyncer:getCellIndicesAtWorldPosition(x, z)
	local v39_, v40_, v41_ = getTerrainHeightSyncerCellIndicesAtWorldPosition(self.terrainNode, x, z)
	if v41_ then
		return v39_, v40_
	else
		return nil, nil
	end
end

-- Local values: cellId
function TerrainDeformationSyncer:getCellId(cellX, cellZ)
	return cellX * self.cellIdOffset + cellZ
end

-- Local values: cellX, cellZ
function TerrainDeformationSyncer:getCellIndicesById(cellId)
	local v47_ = cellId / self.cellIdOffset
	return math.floor(v47_), cellId % self.cellIdOffset
end

-- Local values: cellId, listeners
function TerrainDeformationSyncer:addCellUpdateListener(listener, cellX, cellZ)
	local v52_ = self:getCellId(cellX, cellZ)
	local v53_ = self.updateListeners[v52_]
	if v53_ == nil then
		v53_ = {}
		self.updateListeners[v52_] = v53_
		setEnableTerrainHeightSyncerCellChangedCallback(self.terrainNode, cellX, cellZ, true)
	end
	if v53_[listener] == nil then
		v53_[listener] = 0
	end
	v53_[listener] = v53_[listener] + 1
	return v52_
end

-- Local values: cellId, listeners
function TerrainDeformationSyncer:removeCellUpdateListener(listener, cellX, cellZ)
	local v58_ = self:getCellId(cellX, cellZ)
	local v59_ = self.updateListeners[v58_]
	if v59_ == nil then
		return false
	end
	if v59_[listener] == nil then
		return false
	end
	v59_[listener] = v59_[listener] - 1
	if v59_[listener] == 0 then
		v59_[listener] = nil
	end
	if next(v59_) == nil then
		self.updateListeners[v58_] = nil
		setEnableTerrainHeightSyncerCellChangedCallback(self.terrainNode, cellX, cellZ, false)
	end
	return true
end

-- Local values: cellId, listeners, listener, _
function TerrainDeformationSyncer:onCellUpdate(cellX, cellZ)
	local v63_ = self:getCellId(cellX, cellZ)
	local v64_ = self.updateListeners[v63_]
	if v64_ ~= nil then
		for v65_, _ in pairs(v64_) do
			v65_:onTerrainDeformationSyncerUpdate(cellX, cellZ, v63_)
		end
	end
end

function TerrainDeformationSyncer:consoleCommandToggleDebug()
	TerrainDeformationSyncer.DEBUG_ENABLED = not TerrainDeformationSyncer.DEBUG_ENABLED
	if TerrainDeformationSyncer.DEBUG_ENABLED then
		g_currentMission:addDrawable(self)
	else
		g_currentMission:removeDrawable(self)
	end
end
