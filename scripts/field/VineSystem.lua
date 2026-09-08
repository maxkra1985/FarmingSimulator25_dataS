-- Local values: VineSystem_mt
VineSystem = {}
VineSystem.MAX_NUM_OBJECTS_PER_FRAME = 5
local VineSystem_mt = Class(VineSystem)

-- Upvalues: VineSystem_mt
-- Local values: self
function VineSystem.new(isServer, mission, customMt)
	-- upvalues: (copy) VineSystem_mt
	local v5_ = customMt or VineSystem_mt
	local v6_ = setmetatable({}, v5_)
	v6_.mission = mission
	v6_.isServer = isServer
	v6_.isDebugAreaActive = false
	v6_.debugAreas = {}
	v6_.densityMapCellIdToNode = {}
	v6_.dirtyNodes = {}
	v6_.nodes = {}
	v6_.poleNodes = {}
	if g_addCheatCommands then
		if mission:getIsServer() then
			addConsoleCommand("gsVineSystemSetGrowthState", "Sets vineyard growthstate", "consoleCommandSetGrowthState", v6_)
		end
		addConsoleCommand("gsVineSystemUpdateVisuals", "Updates the visuals", "consoleCommandUpdateVisuals", v6_)
		addConsoleCommand("gsVineSystemPrintCellMapping", "Print the current cellmapping", "consoleCommandPrintCellMapping", v6_)
		addConsoleCommand("gsVineSystemToggleDebug", "Toggles debug view", "consoleCommandToggleDebug", v6_)
	end
	return v6_
end

function VineSystem:initTerrain(terrainSize, terrainDetailMapSize)
	g_messageCenter:subscribe(MessageType.FINISHED_GROWTH_PERIOD, self.onFinishedGrowthPeriod, self)
end

-- Local values: fruitTypeIndex, debugArea
function VineSystem:delete()
	g_messageCenter:unsubscribeAll(self)
	removeConsoleCommand("gsVineSystemSetGrowthState")
	removeConsoleCommand("gsVineSystemUpdateVisuals")
	removeConsoleCommand("gsVineSystemPrintCellMapping")
	removeConsoleCommand("gsVineSystemToggleDebug")
	for v9_, v10_ in pairs(self.debugAreas) do
		v10_:delete()
		self.debugAreas[v9_] = nil
	end
end

-- Local values: fruitTypeIndex, fruitType, colors, densityMapId, x, _, z, dirX, _, dirZ, minCellX, maxCellX, minCellZ, maxCellZ, cellX, cellZ, cellId, panel, pole, poleCollision
function VineSystem:addElement(placeable, node, sizeX, sizeZ)
	if self.nodes[node] == nil then
		local v16_ = placeable:getVineFruitType()
		if self.debugAreas[v16_] == nil then
			local v17_ = g_fruitTypeManager:getFruitTypeByIndex(v16_)
			if v17_.terrainDataPlaneId ~= nil then
				local v18_ = {
					[0] = Color.new(0, 0.5, 0, 0.05),
					[1] = Color.new(0, 0, 1, 0.075),
					[2] = Color.new(0.995, 0.685, 0, 0.05),
					[3] = Color.new(0.846, 0.216, 0, 0.05),
					[4] = Color.new(0.695, 0.007, 0, 0.05),
					[5] = Color.new(0, 1, 0, 0.05),
					[6] = Color.new(0, 1, 0, 0.05),
					[7] = Color.new(0, 1, 0, 0.05),
					[8] = Color.new(0, 1, 0, 0.05),
					[9] = Color.new(0, 1, 0, 0.05),
					[10] = Color.new(0, 1, 0, 0.05),
					[11] = Color.new(0, 1, 0, 0.05),
					[12] = Color.new(0, 1, 0, 0.05),
					[13] = Color.new(0, 1, 0, 0.05),
					[14] = Color.new(0, 1, 0, 0.05),
					[15] = Color.new(0, 1, 0, 0.05),
					[16] = Color.new(0, 1, 0, 0.05)
				}
				self.debugAreas[v16_] = DebugDensityMap.newFromMap(v17_.terrainDataPlaneId, v17_.startStateChannel, v17_.numStateChannels, 10, 0.05, v18_)
			end
		end
		if not self.isServer and self.mission.missionDynamicInfo.isMultiplayer then
			local v19_ = g_currentMission.densityMapSyncer:activateFruitUpdateCallback(v16_)
			if v19_ ~= nil then
				local v20_, _, v21_ = getWorldTranslation(node)
				local v22_, _, v23_ = localDirectionToWorld(node, 0, 0, 1)
				local v24_, v25_, v26_, v27_ = self:getDensityMapSyncerCellIndexRange(v16_, v20_, v21_, v22_, v23_, sizeX, sizeZ)
				for v28_ = v24_, v25_ do
					for v29_ = v26_, v27_ do
						local v30_ = g_currentMission.densityMapSyncer:addCellUpdateListener(self, v19_, v28_, v29_)
						if v30_ ~= nil then
							if self.densityMapCellIdToNode[v19_] == nil then
								self.densityMapCellIdToNode[v19_] = {}
							end
							if self.densityMapCellIdToNode[v19_][v30_] == nil then
								self.densityMapCellIdToNode[v19_][v30_] = {}
							end
							if self.densityMapCellIdToNode[v19_][v30_][placeable] == nil then
								self.densityMapCellIdToNode[v19_][v30_][placeable] = {}
							end
							if self.densityMapCellIdToNode[v19_][v30_][placeable][node] == nil then
								self.densityMapCellIdToNode[v19_][v30_][placeable][node] = true
							end
						end
					end
				end
			end
		end
		local v31_ = getParent(node)
		local v32_ = getParent(v31_)
		local v33_ = getChildAt(v32_, 0)
		self.poleNodes[v33_] = node
		self.nodes[node] = placeable
		self.dirtyNodes[node] = true
	end
end

-- Local values: fruitTypeIndex, desc, densityMapId, x, _, z, dirX, _, dirZ, minCellX, maxCellX, minCellZ, maxCellZ, cellX, cellZ, cellId, poleCollision, panelNode
function VineSystem:removeElement(placeable, node, sizeX, sizeZ)
	if self.nodes[node] == nil or not entityExists(node) then
		return
	end
	if not self.isServer and self.mission.missionDynamicInfo.isMultiplayer then
		local v39_ = placeable:getVineFruitType()
		local v40_ = g_fruitTypeManager:getFruitTypeByIndex(v39_)
		if v40_.foliageTransformGroupId == nil then
			return
		end
		local v41_ = v40_.foliageTransformGroupId
		if v41_ ~= nil then
			local v42_, _, v43_ = getWorldTranslation(node)
			local v44_, _, v45_ = localDirectionToWorld(node, 0, 0, 1)
			local v46_, v47_, v48_, v49_ = self:getDensityMapSyncerCellIndexRange(v39_, v42_, v43_, v44_, v45_, sizeX, sizeZ)
			for v50_ = v46_, v47_ do
				for v51_ = v48_, v49_ do
					local v52_ = g_currentMission.densityMapSyncer:removeCellUpdateListener(self, v41_, v50_, v51_)
					if v52_ ~= nil and self.densityMapCellIdToNode[v41_][v52_] ~= nil then
						if self.densityMapCellIdToNode[v41_][v52_][placeable] ~= nil then
							self.densityMapCellIdToNode[v41_][v52_][placeable][node] = nil
						end
						if next(self.densityMapCellIdToNode[v41_][v52_][placeable]) == nil then
							self.densityMapCellIdToNode[v41_][v52_][placeable] = nil
							if next(self.densityMapCellIdToNode[v41_][v52_]) == nil then
								self.densityMapCellIdToNode[v41_][v52_] = nil
							end
						end
					end
				end
			end
		end
	end
	for v53_, v54_ in pairs(self.poleNodes) do
		if v54_ == node then
			self.poleNodes[v53_] = nil
			break
		end
	end
	self.nodes[node] = nil
	self.dirtyNodes[node] = nil
end

-- Local values: densityMapCellData, placeables, placeable, nodes, node, _
function VineSystem:onDensityMapSyncerUpdate(densityMapId, cellX, cellZ, cellId)
	local v58_ = self.densityMapCellIdToNode[densityMapId]
	if v58_ == nil then
		Logging.devWarning("VineSystem:onDensityMapSyncerUpdate: No placeables registered for densityMap \'%d\'", densityMapId)
		return
	else
		local v59_ = v58_[cellId]
		if v59_ == nil then
			Logging.devWarning("VineSystem:onDensityMapSyncerUpdate: No placeables registered for cellId \'%d\'", cellId)
		else
			for _, v60_ in pairs(v59_) do
				for v61_, _ in pairs(v60_) do
					self.dirtyNodes[v61_] = true
				end
			end
		end
	end
end

-- Local values: node, placeable
function VineSystem:onFinishedGrowthPeriod(period)
	for v63_, _ in pairs(self.nodes) do
		self.dirtyNodes[v63_] = true
	end
end

-- Local values: i, node, placeable
function VineSystem:update(dt)
	for _ = 1, VineSystem.MAX_NUM_OBJECTS_PER_FRAME do
		local v65_ = next(self.dirtyNodes)
		if v65_ ~= nil then
			local v66_ = self.nodes[v65_]
			if v66_ ~= nil then
				v66_:updateVineNode(v65_, true)
			end
			self.dirtyNodes[v65_] = nil
		end
	end
end

-- Local values: normX, _, normZ, sizeHalfX, p1x, p1z, p2x, p2z, p3x, p3z, p4x, p4z, p1CellX, p1CellZ, p2CellX, p2CellZ, p3CellX, p3CellZ, p4CellX, p4CellZ, minCellX, maxCellX, minCellZ, maxCellZ
function VineSystem:getDensityMapSyncerCellIndexRange(fruitTypeIndex, x, z, dirX, dirZ, sizeX, sizeZ)
	local v74_, _, v75_ = MathUtil.crossProduct(dirX, 0, dirZ, 0, 1, 0)
	local v76_ = sizeX * 0.5
	local v77_ = x + v74_ * -v76_
	local v78_ = z + v75_ * -v76_
	local v79_ = x + v74_ * v76_
	local v80_ = z + v75_ * v76_
	local v81_ = x + dirX * sizeZ + v74_ * -v76_
	local v82_ = z + dirZ * sizeZ + v75_ * -v76_
	local v83_ = x + dirX * sizeZ + v74_ * v76_
	local v84_ = z + dirZ * sizeZ + v75_ * v76_
	local v85_, v86_ = g_currentMission.densityMapSyncer:getFruitCellIndicesAtWorldPosition(fruitTypeIndex, v77_, v78_)
	local v87_, v88_ = g_currentMission.densityMapSyncer:getFruitCellIndicesAtWorldPosition(fruitTypeIndex, v79_, v80_)
	local v89_, v90_ = g_currentMission.densityMapSyncer:getFruitCellIndicesAtWorldPosition(fruitTypeIndex, v81_, v82_)
	local v91_, v92_ = g_currentMission.densityMapSyncer:getFruitCellIndicesAtWorldPosition(fruitTypeIndex, v83_, v84_)
	return math.min(v85_, v87_, v89_, v91_), math.max(v85_, v87_, v89_, v91_), math.min(v86_, v88_, v90_, v92_), math.max(v86_, v88_, v90_, v92_)
end

-- Local values: placeable
function VineSystem:getPlaceable(node)
	if node == nil then
		return nil
	else
		local v95_ = self.nodes[node]
		if v95_ == nil and self.poleNodes[node] ~= nil then
			v95_ = self.nodes[self.poleNodes[node]]
		end
		if v95_ == nil then
			return nil
		else
			return v95_
		end
	end
end

-- Local values: fruitType, fruitTypeIndex, count, node, placeable, startX, startZ, widthX, widthZ, heightX, heightZ
function VineSystem:consoleCommandSetGrowthState(fruitTypeName, growthState)
	local v99_ = g_fruitTypeManager:getFruitTypeByName(fruitTypeName)
	if v99_ == nil then
		return "FruitType " .. tostring(fruitTypeName) .. " not defined"
	end
	local v100_ = tonumber(growthState)
	if v100_ == nil then
		return "Invalid growthstate " .. tostring(v100_)
	end
	local v101_ = v99_.index
	local v102_ = 0
	for v103_, v104_ in pairs(self.nodes) do
		if v104_:getVineFruitType() == v101_ then
			local v105_, v106_, v107_, v108_, v109_, v110_ = v104_:getVineAreaByNode(v103_)
			FSDensityMapUtil:setVineAreaValue(v101_, v105_, v106_, v107_, v108_, v109_, v110_, v100_)
			self.dirtyNodes[v103_] = true
			v102_ = v102_ + 1
		end
	end
	return string.format("Updated %d vine areas", v102_)
end

-- Local values: node, _
function VineSystem:consoleCommandUpdateVisuals()
	for v112_, _ in pairs(self.nodes) do
		self.dirtyNodes[v112_] = true
	end
end

-- Local values: densityMapId, cellIds, cellId, placeables, placeable, nodes, node, _
function VineSystem:consoleCommandPrintCellMapping()
	for v114_, v115_ in pairs(self.densityMapCellIdToNode) do
		log("DensityMapId", v114_)
		for v116_, v117_ in pairs(v115_) do
			log("    CellId", v116_)
			for v118_, v119_ in pairs(v117_) do
				log("        Placeable", v118_, v118_.spec_vine.fruitType.name)
				for v120_, _ in pairs(v119_) do
					log("            ", v120_, getName(v120_))
				end
			end
		end
	end
end

-- Local values: _, debugArea
function VineSystem:consoleCommandToggleDebug()
	self.isDebugAreaActive = not self.isDebugAreaActive
	for _, v122_ in pairs(self.debugAreas) do
		if self.isDebugAreaActive then
			g_currentMission:addDrawable(v122_)
		else
			g_currentMission:removeDrawable(v122_)
		end
	end
end
