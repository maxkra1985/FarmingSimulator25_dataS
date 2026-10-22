VineSystem = {}
VineSystem.MAX_NUM_OBJECTS_PER_FRAME = 5
VineSystem.MAX_NUM_OBJECTS_PER_FRAME_WHILE_LOADING = 50
VineSystem.CELL_SIZE = 16
VineSystem.SPIRAL_RADIUS = 24
VineSystem.DM_UPDATE_DEBUG_RANGE = 12
VineSystem.DM_UPDATE_DEBUG_TEXT_OFFSET_Y = 2
VineSystem.DM_UPDATE_DEBUG_TEXT_SIZE = 0.014
VineSystem.DM_UPDATE_DEBUG_INFO_TEXT_X = 0.02
VineSystem.DM_UPDATE_DEBUG_INFO_TEXT_Y = 0.9
VineSystem.DM_UPDATE_DEBUG_COLOR_OUTLINE = Color.new(1, 1, 1, 1)
VineSystem.DM_UPDATE_DEBUG_COLOR_AREA = Color.new(0, 1, 0, 0.35)
VineSystem.DM_UPDATE_DEBUG_COLOR_LISTENER_CELL = Color.new(0, 0.4, 1, 0.12)
VineSystem.DM_UPDATE_DEBUG_COLOR_AREA_CELL = Color.new(1, 0.5, 0, 0.12)
VineSystem.dmUpdateDebugGrowthStates = {}
VineSystem.dmUpdateDebugPlaceables = {}
local VineSystem_mt = Class(VineSystem)
function VineSystem.new(isServer, mission, customMt)
	local self = setmetatable({}, customMt or VineSystem_mt)
	self.mission = mission
	self.isServer = isServer
	self.isDebugAreaActive = false
	self.isDMUpdateDebugActive = false
	self.debugAreas = {}
	self.densityMapCellIdToNode = {}
	self.nodeToSyncerCells = {}
	self.nodeToSyncerDensityMap = {}
	self.nodeToCellKey = {}
	self.dirtyCells = {}
	self.dirtyNodeCount = 0
	self.nodes = {}
	self.poleNodes = {}
	if g_addCheatCommands then
		if mission:getIsServer() then
			addConsoleCommand("gsVineSystemSetGrowthState", "Sets the growth state of all vine/orchard areas of a fruit type, optionally limited to one field/farmland", "consoleCommandSetGrowthState", self, "fruitTypeName; growthStateNameOrIndex; [farmlandId]")
		end
		addConsoleCommand("gsVineSystemUpdateVisuals", "Updates the visuals", "consoleCommandUpdateVisuals", self)
		addConsoleCommand("gsVineSystemPrintCellMapping", "Print the current cellmapping", "consoleCommandPrintCellMapping", self)
		addConsoleCommand("gsVineSystemToggleDebug", "Toggles debug view", "consoleCommandToggleDebug", self)
		addConsoleCommand("gsVineSystemDMUpdateDebugToggle", "Toggles the density map update debug view of the node closest to the camera", "consoleCommandToggleDMUpdateDebug", self)
	end
	return self
end
function VineSystem:initTerrain(terrainSize, terrainDetailMapSize)
	self.cellOffset = math.ceil(terrainSize / VineSystem.CELL_SIZE)
	self.cellStride = self.cellOffset * 2 + 1
	self.spiralOffsets = VineSystem.createSpiralOffsets(VineSystem.SPIRAL_RADIUS)
	g_messageCenter:subscribe(MessageType.FINISHED_GROWTH_PERIOD, self.onFinishedGrowthPeriod, self)
end
function VineSystem.createSpiralOffsets(radius)
	local offsets = {}
	table.insert(offsets, Vector3.new(0, 0, 0))
	for ring = 1, radius do
		for dx = -ring, ring do
			table.insert(offsets, vector.create(dx, 0, -ring))
			table.insert(offsets, vector.create(dx, 0, ring))
		end
		for dz = -ring + 1, ring - 1 do
			table.insert(offsets, vector.create(-ring, 0, dz))
			table.insert(offsets, vector.create(ring, 0, dz))
		end
	end
	return offsets
end
function VineSystem:delete()
	g_messageCenter:unsubscribeAll(self)
	removeConsoleCommand("gsVineSystemSetGrowthState")
	removeConsoleCommand("gsVineSystemUpdateVisuals")
	removeConsoleCommand("gsVineSystemPrintCellMapping")
	removeConsoleCommand("gsVineSystemToggleDebug")
	removeConsoleCommand("gsVineSystemDMUpdateDebugToggle")
	if self.isDMUpdateDebugActive then
		self.isDMUpdateDebugActive = false
		if g_currentMission ~= nil then
			g_currentMission:removeDrawable(self)
		end
	end
	table.clear(VineSystem.dmUpdateDebugPlaceables)
	for fruitTypeIndex, debugArea in pairs(self.debugAreas) do
		debugArea:delete()
		self.debugAreas[fruitTypeIndex] = nil
	end
end
function VineSystem:addElement(placeable, node, sizeX, sizeZ, updateImmediately)
	if self.nodes[node] ~= nil then
		self:removeElement(self.nodes[node], node, sizeX, sizeZ)
	end
	local fruitTypeIndex = placeable:getVineFruitType()
	if self.debugAreas[fruitTypeIndex] == nil then
		local fruitType = g_fruitTypeManager:getFruitTypeByIndex(fruitTypeIndex)
		if fruitType.terrainDataPlaneId ~= nil then
			local colors = {}
			colors[0] = Color.new(0, 0.5, 0, 0.05)
			colors[1] = Color.new(0, 0, 1, 0.075)
			colors[2] = Color.new(0.995, 0.685, 0, 0.05)
			colors[3] = Color.new(0.846, 0.216, 0, 0.05)
			colors[4] = Color.new(0.695, 0.007, 0, 0.05)
			colors[5] = Color.new(0, 1, 0, 0.05)
			colors[6] = Color.new(0, 1, 0, 0.05)
			colors[7] = Color.new(0, 1, 0, 0.05)
			colors[8] = Color.new(0, 1, 0, 0.05)
			colors[9] = Color.new(0, 1, 0, 0.05)
			colors[10] = Color.new(0, 1, 0, 0.05)
			colors[11] = Color.new(0, 1, 0, 0.05)
			colors[12] = Color.new(0, 1, 0, 0.05)
			colors[13] = Color.new(0, 1, 0, 0.05)
			colors[14] = Color.new(0, 1, 0, 0.05)
			colors[15] = Color.new(0, 1, 0, 0.05)
			colors[16] = Color.new(0, 1, 0, 0.05)
			self.debugAreas[fruitTypeIndex] = DebugDensityMap.newFromMap(fruitType.terrainDataPlaneId, fruitType.startStateChannel, fruitType.numStateChannels, 10, 0.05, colors)
		end
	end
	if not self.isServer and self.mission.missionDynamicInfo.isMultiplayer then
		self:addSyncerCellListeners(placeable, node, fruitTypeIndex, sizeX, sizeZ)
	end
	local panel = getParent(node)
	local pole = nil
	if panel ~= nil and panel ~= 0 then
		pole = getParent(panel)
	end
	local hasPoleHierarchy = pole ~= nil and pole ~= 0 and 0 < getNumOfChildren(pole)
	if hasPoleHierarchy then
		self.poleNodes[getChildAt(pole, 0)] = node
	end
	local nodeX, _, nodeZ = getWorldTranslation(node)
	self.nodeToCellKey[node] = self:getCellKey(nodeX, nodeZ)
	self.nodes[node] = placeable
	if updateImmediately then
		placeable:updateVineNode(node, false)
	else
		self:markNodeDirty(node)
	end
end
function VineSystem:removeElement(placeable, node, sizeX, sizeZ)
	if self.nodes[node] == nil then
		return
	else
		self:removeSyncerCellListeners(placeable, node)
		for poleCollision, panelNode in pairs(self.poleNodes) do
			if panelNode == node then
				self.poleNodes[poleCollision] = nil
				break
			end
		end
		self:clearNodeDirty(node)
		self.nodeToCellKey[node] = nil
		self.nodes[node] = nil
	end
end
function VineSystem:addSyncerCellListeners(placeable, node, fruitTypeIndex, sizeX, sizeZ)
	local densityMapSyncer = g_currentMission.densityMapSyncer
	if densityMapSyncer == nil then
		return
	end
	local densityMapId = densityMapSyncer:activateFruitUpdateCallback(fruitTypeIndex)
	if densityMapId == nil then
		return
	else
		local x, _, z = getWorldTranslation(node)
		local dirX, _, dirZ = localDirectionToWorld(node, 0, 0, 1)
		local minCellX, maxCellX, minCellZ, maxCellZ = self:getDensityMapSyncerCellIndexRange(fruitTypeIndex, x, z, dirX, dirZ, sizeX, sizeZ)
		local cellData = self.densityMapCellIdToNode[densityMapId]
		if cellData == nil then
			cellData = {}
			self.densityMapCellIdToNode[densityMapId] = cellData
		end
		local cells = {}
		local numCellValues = 0
		for cellX = minCellX, maxCellX do
			for cellZ = minCellZ, maxCellZ do
				local cellId = densityMapSyncer:addCellUpdateListener(self, densityMapId, cellX, cellZ)
				if cellId == nil then
					continue
				end
				VineSystem.addCellNodeMapping(cellData, cellId, placeable, node)
				cells[numCellValues + 1] = cellX
				cells[numCellValues + 2] = cellZ
				numCellValues = numCellValues + 2
			end
		end
		self.nodeToSyncerCells[node] = cells
		self.nodeToSyncerDensityMap[node] = densityMapId
	end
end
function VineSystem:removeSyncerCellListeners(placeable, node)
	local cells = self.nodeToSyncerCells[node]
	local densityMapId = self.nodeToSyncerDensityMap[node]
	self.nodeToSyncerCells[node] = nil
	self.nodeToSyncerDensityMap[node] = nil
	local densityMapSyncer = g_currentMission.densityMapSyncer
	if cells == nil or densityMapId == nil or densityMapSyncer == nil then
		return
	end
	local cellData = self.densityMapCellIdToNode[densityMapId]
	for i = 1, #cells, 2 do
		local cellX = cells[i]
		local cellZ = cells[i + 1]
		densityMapSyncer:removeCellUpdateListener(self, densityMapId, cellX, cellZ)
		if cellData == nil then
			continue
		end
		local cellId = densityMapSyncer:getCellId(densityMapId, cellX, cellZ)
		VineSystem.clearCellNodeMapping(cellData, cellId, placeable, node)
	end
end
function VineSystem.addCellNodeMapping(cellData, cellId, placeable, node)
	local placeables = cellData[cellId]
	if placeables == nil then
		placeables = {}
		cellData[cellId] = placeables
	end
	local nodes = placeables[placeable]
	if nodes == nil then
		nodes = {}
		placeables[placeable] = nodes
	end
	nodes[node] = true
end
function VineSystem.clearCellNodeMapping(cellData, cellId, placeable, node)
	local placeables = cellData[cellId]
	if placeables == nil then
		return
	end
	local nodes = placeables[placeable]
	if nodes == nil then
		return
	end
	nodes[node] = nil
	if next(nodes) ~= nil then
		return
	else
		placeables[placeable] = nil
		if next(placeables) == nil then
			cellData[cellId] = nil
		end
	end
end
function VineSystem:onDensityMapSyncerUpdate(densityMapId, cellX, cellZ, cellId)
	local densityMapCellData = self.densityMapCellIdToNode[densityMapId]
	if densityMapCellData == nil then
		Logging.devWarning("VineSystem:onDensityMapSyncerUpdate: No placeables registered for densityMap '%d'", densityMapId)
		return
	end
	local placeables = densityMapCellData[cellId]
	if placeables == nil then
		Logging.devWarning("VineSystem:onDensityMapSyncerUpdate: No placeables registered for cellId '%d'", cellId)
	else
		for _, nodes in pairs(placeables) do
			for node, _ in pairs(nodes) do
				self:markNodeDirty(node)
			end
		end
	end
end
function VineSystem:onFinishedGrowthPeriod(period)
	for node, _ in pairs(self.nodes) do
		self:markNodeDirty(node)
	end
end
function VineSystem:update(dt)
	if self.dirtyNodeCount == 0 then
		return
	else
		local objectsPerFrame = VineSystem.MAX_NUM_OBJECTS_PER_FRAME
		if g_currentMission ~= nil and not g_currentMission.isMissionStarted then
			objectsPerFrame = VineSystem.MAX_NUM_OBJECTS_PER_FRAME_WHILE_LOADING
		end
		local processed = self:updateNearestDirtyNodes(objectsPerFrame)
		if processed < objectsPerFrame and 0 < self.dirtyNodeCount then
			self:updateRemainingDirtyNodes(objectsPerFrame - processed)
		end
	end
end
function VineSystem:updateNearestDirtyNodes(budget)
	local camera = nil
	if g_cameraManager ~= nil then
		camera = g_cameraManager:getActiveCamera()
	end
	if camera == nil or camera == 0 or not entityExists(camera) then
		return 0
	end
	local x, _, z = getWorldTranslation(camera)
	local camCellX = math.floor(x / VineSystem.CELL_SIZE)
	local camCellZ = math.floor(z / VineSystem.CELL_SIZE)
	local processed = 0
	for _, offset in ipairs(self.spiralOffsets) do
		local cellKey = self:packCellKey(camCellX + offset.x, camCellZ + offset.z)
		local bucket = self.dirtyCells[cellKey]
		if bucket == nil then
			continue
		end
		processed = processed + self:drainBucket(bucket, budget - processed)
		if next(bucket) == nil then
			self.dirtyCells[cellKey] = nil
		end
		if not (budget <= processed) then
			continue
		end
		return processed
	end
end
function VineSystem:updateRemainingDirtyNodes(budget)
	local processed = 0
	while processed < budget do
		local cellKey = next(self.dirtyCells)
		if cellKey == nil then
			break
		end
		local bucket = self.dirtyCells[cellKey]
		if bucket == nil then
			continue
		end
		processed = processed + self:drainBucket(bucket, budget - processed)
		if next(bucket) == nil then
			self.dirtyCells[cellKey] = nil
		end
	end
end
function VineSystem:drainBucket(bucket, budget)
	local processed = 0
	while processed < budget do
		local node = next(bucket)
		if node == nil then
			break
		end
		local placeable = self.nodes[node]
		if placeable ~= nil then
			placeable:updateVineNode(node, true)
		end
		bucket[node] = nil
		self.dirtyNodeCount = self.dirtyNodeCount - 1
		processed = processed + 1
	end
	return processed
end
function VineSystem:draw()
	if not self.isDMUpdateDebugActive then
		return
	else
		local camera = nil
		if g_cameraManager ~= nil then
			camera = g_cameraManager:getActiveCamera()
		end
		if camera == nil or camera == 0 or not entityExists(camera) then
			return
		end
		local cameraX, _, cameraZ = getWorldTranslation(camera)
		local node, placeable = self:getFencePartClosestToPosition(cameraX, cameraZ, VineSystem.DM_UPDATE_DEBUG_RANGE)
		if node == nil then
			node, placeable = self:getRegisteredNodeClosestToPosition(cameraX, cameraZ, VineSystem.DM_UPDATE_DEBUG_RANGE)
		end
		if node == nil or placeable == nil then
			setTextBold(false)
			setTextColor(1, 1, 1, 1)
			setTextAlignment(RenderText.ALIGN_LEFT)
			renderText(VineSystem.DM_UPDATE_DEBUG_INFO_TEXT_X, VineSystem.DM_UPDATE_DEBUG_INFO_TEXT_Y, VineSystem.DM_UPDATE_DEBUG_TEXT_SIZE, "VineSystem: no pole or panel in range")
			return
		end
		DebugShapeOutline.setOutlineColor(VineSystem.DM_UPDATE_DEBUG_COLOR_OUTLINE)
		DebugShapeOutline.render(node, true, false)
		local fruitTypeIndex = placeable:getVineFruitType()
		local startX, startZ, widthX, widthZ, heightX, heightZ = placeable:getVineAreaByNode(node)
		if startX ~= nil then
			DebugPlane.renderWithPositions(startX, 0, startZ, widthX, 0, widthZ, heightX, 0, heightZ, VineSystem.DM_UPDATE_DEBUG_COLOR_AREA, true, true, true, false, nil)
		end
		local cellSize = VineSystem.getSyncerCellSizeInMeters(fruitTypeIndex)
		local numListenerCells = 0
		if cellSize ~= nil then
			numListenerCells = self:renderListenerDebugCells(node, fruitTypeIndex, cellSize)
			if startX ~= nil then
				VineSystem.renderAreaDebugCells(fruitTypeIndex, startX, startZ, widthX, widthZ, heightX, heightZ, cellSize)
			end
		end
		self:renderNodeDebugInfo(node, fruitTypeIndex, startX, startZ, widthX, widthZ, heightX, heightZ, numListenerCells)
	end
end
function VineSystem:getFencePartClosestToPosition(x, z, maxDistance)
	local placeables = VineSystem.dmUpdateDebugPlaceables
	table.clear(placeables)
	for _, placeable in pairs(self.nodes) do
		placeables[placeable] = true
	end
	local closestNode = nil
	local closestPlaceable = nil
	local closestDistance = maxDistance
	for placeable in pairs(placeables) do
		local node, distance = VineSystem.getClosestFencePartOfPlaceable(placeable, x, z, closestDistance)
		if node == nil or distance == nil then
			continue
		end
		closestDistance = distance
		closestNode = node
		closestPlaceable = placeable
	end
	return closestNode, closestPlaceable
end
function VineSystem.getClosestFencePartOfPlaceable(placeable, x, z, maxDistance)
	if placeable.getFence == nil then
		return nil
	end
	local fence = placeable:getFence()
	if fence == nil then
		return nil
	else
		local closestNode = nil
		local closestDistance = maxDistance
		for _, segment in ipairs(fence:getSegments()) do
			local node, distance = VineSystem.getClosestFencePartOfSegment(placeable, segment, x, z, closestDistance)
			if node == nil or distance == nil then
				continue
			end
			closestDistance = distance
			closestNode = node
		end
		return closestNode, closestDistance
	end
end
function VineSystem.getClosestFencePartOfSegment(placeable, segment, x, z, maxDistance)
	local root = segment.root
	if root == nil or not entityExists(root) then
		return nil
	end
	local closestNode = nil
	local closestDistance = maxDistance
	for i = 0, getNumOfChildren(root) - 1 do
		local node = getChildAt(root, i)
		local distance = VineSystem.getNodeAreaDistance(placeable, node, x, z, maxDistance)
		if distance == nil then
			continue
		end
		if distance < closestDistance then
			closestDistance = distance
			closestNode = node
		end
	end
	return closestNode, closestDistance
end
function VineSystem.getNodeAreaDistance(placeable, node, x, z, maxDistance)
	local nodeX, _, nodeZ = getWorldTranslation(node)
	local nodeDistance = MathUtil.vector2Length(nodeX - x, nodeZ - z)
	if maxDistance < nodeDistance then
		return nil
	end
	local centerX, centerZ = VineSystem.getVineAreaCenter(placeable, node)
	if centerX == nil then
		return nodeDistance
	else
		return MathUtil.vector2Length(centerX - x, centerZ - z)
	end
end
function VineSystem:getRegisteredNodeClosestToPosition(x, z, maxDistance)
	local closestNode = nil
	local closestPlaceable = nil
	local closestDistance = maxDistance
	for node, placeable in pairs(self.nodes) do
		if entityExists(node) then
			local distance = VineSystem.getNodeAreaDistance(placeable, node, x, z, maxDistance)
			if distance == nil then
				continue
			end
			if distance < closestDistance then
				closestDistance = distance
				closestNode = node
				closestPlaceable = placeable
			end
		end
	end
	return closestNode, closestPlaceable
end
function VineSystem.getVineAreaCenter(placeable, node)
	local startX, _, widthX, widthZ, heightX, heightZ = placeable:getVineAreaByNode(node)
	if startX == nil then
		return nil
	else
		return (widthX + heightX) * 0.5, (widthZ + heightZ) * 0.5
	end
end
function VineSystem:renderListenerDebugCells(node, fruitTypeIndex, cellSize)
	local cells = self.nodeToSyncerCells[node]
	if cells == nil then
		return 0
	else
		for i = 1, #cells, 2 do
			VineSystem.renderDebugCell(fruitTypeIndex, cells[i], cells[i + 1], cellSize, VineSystem.DM_UPDATE_DEBUG_COLOR_LISTENER_CELL)
		end
		return math.floor(#cells * 0.5)
	end
end
function VineSystem.renderAreaDebugCells(fruitTypeIndex, startX, startZ, widthX, widthZ, heightX, heightZ, cellSize)
	local densityMapSyncer = g_currentMission.densityMapSyncer
	if densityMapSyncer == nil then
		return
	else
		local cornerX = widthX + heightX - startX
		local cornerZ = widthZ + heightZ - startZ
		local firstCellX, firstCellZ = densityMapSyncer:getFruitCellIndicesAtWorldPosition(fruitTypeIndex, startX, startZ)
		local secondCellX, secondCellZ = densityMapSyncer:getFruitCellIndicesAtWorldPosition(fruitTypeIndex, widthX, widthZ)
		local thirdCellX, thirdCellZ = densityMapSyncer:getFruitCellIndicesAtWorldPosition(fruitTypeIndex, heightX, heightZ)
		local fourthCellX, fourthCellZ = densityMapSyncer:getFruitCellIndicesAtWorldPosition(fruitTypeIndex, cornerX, cornerZ)
		if firstCellX == nil or secondCellX == nil or thirdCellX == nil or fourthCellX == nil then
			return
		end
		local minCellX = math.min(firstCellX, secondCellX, thirdCellX, fourthCellX)
		local maxCellX = math.max(firstCellX, secondCellX, thirdCellX, fourthCellX)
		local minCellZ = math.min(firstCellZ, secondCellZ, thirdCellZ, fourthCellZ)
		local maxCellZ = math.max(firstCellZ, secondCellZ, thirdCellZ, fourthCellZ)
		for cellX = minCellX, maxCellX do
			for cellZ = minCellZ, maxCellZ do
				VineSystem.renderDebugCell(fruitTypeIndex, cellX, cellZ, cellSize, VineSystem.DM_UPDATE_DEBUG_COLOR_AREA_CELL)
			end
		end
	end
end
function VineSystem.renderDebugCell(fruitTypeIndex, cellX, cellZ, cellSize, color)
	local terrainSize = g_currentMission.terrainSize
	local startX = cellX * cellSize - terrainSize * 0.5
	local startZ = cellZ * cellSize - terrainSize * 0.5
	local widthX = startX + cellSize
	local heightZ = startZ + cellSize
	local centerX = startX + cellSize * 0.5
	local centerZ = startZ + cellSize * 0.5
	local checkCellX, checkCellZ = g_currentMission.densityMapSyncer:getFruitCellIndicesAtWorldPosition(fruitTypeIndex, centerX, centerZ)
	local isVerified = checkCellX == cellX and checkCellZ == cellZ
	local text = string.format("%d/%d", cellX, cellZ)
	if not isVerified then
		text = text .. " MISMATCH"
	end
	DebugPlane.renderWithPositions(startX, 0, startZ, widthX, 0, startZ, startX, 0, heightZ, color, true, true, true, false, text)
end
function VineSystem:renderNodeDebugInfo(node, fruitTypeIndex, startX, startZ, widthX, widthZ, heightX, heightZ, numListenerCells)
	local fruitTypeDesc = g_fruitTypeManager:getFruitTypeByIndex(fruitTypeIndex)
	local fruitTypeName = fruitTypeDesc ~= nil and fruitTypeDesc.name or "?"
	local cellKey = self.nodeToCellKey[node]
	local bucket = cellKey ~= nil and self.dirtyCells[cellKey] or nil
	local isDirty = bucket ~= nil and bucket[node] ~= nil
	local growthStateText = "no area"
	if startX ~= nil then
		local growthState = VineSystem.getDominantGrowthState(fruitTypeIndex, startX, startZ, widthX, widthZ, heightX, heightZ)
		if growthState == nil then
			growthStateText = "none (area is empty)"
		else
			local growthStateName = fruitTypeDesc ~= nil and fruitTypeDesc:getGrowthStateName(growthState) or nil
			growthStateText = string.format("%d (%s)", growthState, growthStateName or "?")
		end
	end
	local listenerCellText = nil
	if g_currentMission.densityMapSyncer == nil then
		listenerCellText = "no syncer (singleplayer)"
	elseif self.isServer then
		listenerCellText = "not registered (server)"
	else
		listenerCellText = tostring(numListenerCells)
	end
	local registeredText = "yes"
	if self.nodes[node] == nil then
		registeredText = "NO (never updated)"
	end
	local numRegisteredSiblings, numSegmentParts = self:getNumRegisteredSiblings(node)
	local text = string.format("node %d '%s'\nfruitType %s\nisRegistered %s\nsegmentParts registered %d/%d\ngrowthState %s\nisDirty %s  isPoleMapped %s\nlistenerCells %s", node, getName(node), fruitTypeName, registeredText, numRegisteredSiblings, numSegmentParts, growthStateText, tostring(isDirty), tostring(self:getIsNodeMappedFromPole(node)), listenerCellText)
	local nodeX, nodeY, nodeZ = getWorldTranslation(node)
	Utils.renderTextAtWorldPosition(nodeX, nodeY + VineSystem.DM_UPDATE_DEBUG_TEXT_OFFSET_Y, nodeZ, text, VineSystem.DM_UPDATE_DEBUG_TEXT_SIZE, 0, 1, 1, 1, 1)
end
function VineSystem:getNumRegisteredSiblings(node)
	local root = getParent(node)
	if root == nil or root == 0 then
		return 0, 0
	end
	local numParts = getNumOfChildren(root)
	local numRegistered = 0
	for i = 0, numParts - 1 do
		if self.nodes[getChildAt(root, i)] == nil then
			continue
		end
		numRegistered = numRegistered + 1
	end
	return numRegistered, numParts
end
function VineSystem:getIsNodeMappedFromPole(node)
	for _, mappedNode in pairs(self.poleNodes) do
		if mappedNode == node then
			return true
		end
	end
	return false
end
function VineSystem.getDominantGrowthState(fruitTypeIndex, startX, startZ, widthX, widthZ, heightX, heightZ)
	local fruitTypeDesc = g_fruitTypeManager:getFruitTypeByIndex(fruitTypeIndex)
	if fruitTypeDesc == nil then
		return nil
	else
		local states = VineSystem.dmUpdateDebugGrowthStates
		table.clear(states)
		for growthState = 1, fruitTypeDesc.numFoliageStates do
			states[growthState] = 0
		end
		FSDensityMapUtil.updateVineAreaValues(fruitTypeIndex, startX, startZ, widthX, widthZ, heightX, heightZ, states)
		local dominantState = nil
		local maxArea = 0
		for growthState, area in pairs(states) do
			if maxArea < area then
				maxArea = area
				dominantState = growthState
			end
		end
		return dominantState
	end
end
function VineSystem.getSyncerCellSizeInMeters(fruitTypeIndex)
	local densityMapSyncer = g_currentMission.densityMapSyncer
	if densityMapSyncer == nil then
		return nil
	else
		local fruitTypeDesc = g_fruitTypeManager:getFruitTypeByIndex(fruitTypeIndex)
		if fruitTypeDesc == nil or fruitTypeDesc.terrainDataPlaneId == nil then
			return nil
		end
		local densityMapSize = getDensityMapSize(fruitTypeDesc.terrainDataPlaneId)
		if densityMapSize == nil or densityMapSize == 0 then
			return nil
		end
		return densityMapSyncer.defaultCellSize * g_currentMission.terrainSize / densityMapSize
	end
end
function VineSystem:packCellKey(cellX, cellZ)
	local cellKey = (cellX + self.cellOffset) * self.cellStride + (cellZ + self.cellOffset)
	return cellKey
end
function VineSystem:getCellKey(x, z)
	local cellX = math.floor(x / VineSystem.CELL_SIZE)
	local cellZ = math.floor(z / VineSystem.CELL_SIZE)
	local cellKey = self:packCellKey(cellX, cellZ)
	return cellKey
end
function VineSystem:markNodeDirty(node)
	local cellKey = self.nodeToCellKey[node]
	if cellKey == nil then
		return
	else
		local bucket = self.dirtyCells[cellKey]
		if bucket == nil then
			bucket = {}
			self.dirtyCells[cellKey] = bucket
		end
		if bucket[node] == nil then
			bucket[node] = true
			self.dirtyNodeCount = self.dirtyNodeCount + 1
		end
	end
end
function VineSystem:clearNodeDirty(node)
	local cellKey = self.nodeToCellKey[node]
	if cellKey == nil then
		return
	else
		local bucket = self.dirtyCells[cellKey]
		if bucket == nil or bucket[node] == nil then
			return
		end
		bucket[node] = nil
		self.dirtyNodeCount = self.dirtyNodeCount - 1
		if next(bucket) == nil then
			self.dirtyCells[cellKey] = nil
		end
	end
end
function VineSystem:getDensityMapSyncerCellIndexRange(fruitTypeIndex, x, z, dirX, dirZ, sizeX, sizeZ)
	local normX, _, normZ = MathUtil.crossProduct(dirX, 0, dirZ, 0, 1, 0)
	local sizeHalfX = sizeX * 0.5
	local p1x = x + normX * -sizeHalfX
	local p1z = z + normZ * -sizeHalfX
	local p2x = x + normX * sizeHalfX
	local p2z = z + normZ * sizeHalfX
	local p3x = x + dirX * sizeZ + normX * -sizeHalfX
	local p3z = z + dirZ * sizeZ + normZ * -sizeHalfX
	local p4x = x + dirX * sizeZ + normX * sizeHalfX
	local p4z = z + dirZ * sizeZ + normZ * sizeHalfX
	local p1CellX, p1CellZ = g_currentMission.densityMapSyncer:getFruitCellIndicesAtWorldPosition(fruitTypeIndex, p1x, p1z)
	local p2CellX, p2CellZ = g_currentMission.densityMapSyncer:getFruitCellIndicesAtWorldPosition(fruitTypeIndex, p2x, p2z)
	local p3CellX, p3CellZ = g_currentMission.densityMapSyncer:getFruitCellIndicesAtWorldPosition(fruitTypeIndex, p3x, p3z)
	local p4CellX, p4CellZ = g_currentMission.densityMapSyncer:getFruitCellIndicesAtWorldPosition(fruitTypeIndex, p4x, p4z)
	local minCellX = math.min(p1CellX, p2CellX, p3CellX, p4CellX)
	local maxCellX = math.max(p1CellX, p2CellX, p3CellX, p4CellX)
	local minCellZ = math.min(p1CellZ, p2CellZ, p3CellZ, p4CellZ)
	local maxCellZ = math.max(p1CellZ, p2CellZ, p3CellZ, p4CellZ)
	return minCellX, maxCellX, minCellZ, maxCellZ
end
function VineSystem:getPlaceable(node)
	if node == nil then
		return nil
	end
	local placeable = self.nodes[node]
	if placeable == nil and self.poleNodes[node] ~= nil then
		placeable = self.nodes[self.poleNodes[node]]
	end
	if placeable == nil then
		return nil
	else
		return placeable
	end
end
function VineSystem.getGrowthStateNames(fruitTypeDesc)
	local names = {}
	local count = 0
	for growthState = 1, fruitTypeDesc.numFoliageStates do
		local name = fruitTypeDesc:getGrowthStateName(growthState)
		if name == nil then
			continue
		end
		count = count + 1
		names[count] = name
	end
	return names
end
function VineSystem.getIsNodeOnFarmland(node, farmlandId)
	local nodeX, _, nodeZ = getWorldTranslation(node)
	return g_farmlandManager:getFarmlandIdAtWorldPosition(nodeX, nodeZ) == farmlandId
end
function VineSystem:consoleCommandSetGrowthState(fruitTypeName, growthState, farmlandId)
	local fruitType = g_fruitTypeManager:getFruitTypeByName(fruitTypeName)
	if fruitType == nil then
		return "FruitType " .. tostring(fruitTypeName) .. " not defined"
	end
	local growthStateIndex = fruitType:getGrowthStateByName(growthState)
	if growthStateIndex == nil then
		growthStateIndex = tonumber(growthState)
	end
	if growthStateIndex == nil then
		local validNames = VineSystem.getGrowthStateNames(fruitType)
		return string.format("Invalid growth state '%s'. Valid: %s", tostring(growthState), table.concat(validNames, ", "))
	end
	local farmlandIdFilter = nil
	if farmlandId ~= nil then
		farmlandIdFilter = tonumber(farmlandId)
		if farmlandIdFilter == nil or not g_farmlandManager:getIsValidFarmlandId(farmlandIdFilter) then
			return string.format("Invalid field/farmland id '%s'", tostring(farmlandId))
		end
	end
	local fruitTypeIndex = fruitType.index
	local count = 0
	for node, placeable in pairs(self.nodes) do
		if placeable:getVineFruitType() == fruitTypeIndex and (farmlandIdFilter == nil or VineSystem.getIsNodeOnFarmland(node, farmlandIdFilter)) then
			local startX, startZ, widthX, widthZ, heightX, heightZ = placeable:getVineAreaByNode(node)
			if startX == nil then
				continue
			end
			FSDensityMapUtil:setVineAreaValue(fruitTypeIndex, startX, startZ, widthX, widthZ, heightX, heightZ, growthStateIndex)
			placeable:updateVineNode(node, false)
			count = count + 1
		end
	end
	local stateName = fruitType:getGrowthStateName(growthStateIndex) or tostring(growthStateIndex)
	if farmlandIdFilter ~= nil then
		return string.format("Updated %d vine areas on field/farmland %d to growth state '%s'", count, farmlandIdFilter, stateName)
	else
		return string.format("Updated %d vine areas to growth state '%s'", count, stateName)
	end
end
function VineSystem:consoleCommandUpdateVisuals()
	for node, _ in pairs(self.nodes) do
		self:markNodeDirty(node)
	end
end
function VineSystem:consoleCommandPrintCellMapping()
	for densityMapId, cellIds in pairs(self.densityMapCellIdToNode) do
		log("DensityMapId", densityMapId)
		for cellId, placeables in pairs(cellIds) do
			log("    CellId", cellId)
			for placeable, nodes in pairs(placeables) do
				log("        Placeable", placeable, placeable.spec_vine.fruitType.name)
				for node, _ in pairs(nodes) do
					log("            ", node, getName(node))
				end
			end
		end
	end
end
function VineSystem:consoleCommandToggleDebug()
	self.isDebugAreaActive = not self.isDebugAreaActive
	for _, debugArea in pairs(self.debugAreas) do
		if self.isDebugAreaActive then
			g_currentMission:addDrawable(debugArea)
		else
			g_currentMission:removeDrawable(debugArea)
		end
	end
end
function VineSystem:consoleCommandToggleDMUpdateDebug()
	self.isDMUpdateDebugActive = not self.isDMUpdateDebugActive
	if self.isDMUpdateDebugActive then
		g_currentMission:addDrawable(self)
		return string.format("Density map update debug view enabled (range %d m)", VineSystem.DM_UPDATE_DEBUG_RANGE)
	else
		g_currentMission:removeDrawable(self)
		table.clear(VineSystem.dmUpdateDebugPlaceables)
		return "Density map update debug view disabled"
	end
end
