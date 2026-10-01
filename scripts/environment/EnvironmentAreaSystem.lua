EnvironmentAreaSystem = {}
local EnvironmentAreaSystem_mt = Class(EnvironmentAreaSystem)
function EnvironmentAreaSystem.getName(index)
	for name, id in pairs(EnvironmentAreaSystem) do
		if index == id then
			return name
		end
	end
	return ""
end
function EnvironmentAreaSystem.new(customMt)
	local self = setmetatable({}, customMt or EnvironmentAreaSystem_mt)
	self.isDebugViewActive = false
	self.referenceNode = g_cameraManager:getActiveCamera()
	self.raycastCollisionMask = CollisionFlag.BUILDING
	self.raycastsXZMaxDistance = 30
	self.raycastsYMaxDistance = 30
	self.raycastsXZ = { { dir = { MathUtil.vector3Normalize(0, 0, 1) } }, { dir = { MathUtil.vector3Normalize(1, 0, 0) } }, { dir = { MathUtil.vector3Normalize(0, 0, -1) } }, { dir = { MathUtil.vector3Normalize(-1, 0, 0) } }, { dir = { MathUtil.vector3Normalize(1, 0, 1) } }, { dir = { MathUtil.vector3Normalize(1, 0, -1) } }, { dir = { MathUtil.vector3Normalize(-1, 0, -1) } }, { dir = { MathUtil.vector3Normalize(-1, 0, 1) } } }
	self.raycastsY = { { dir = { MathUtil.vector3Normalize(0, 1, 0) }, isTopRaycast = true }, { dir = { MathUtil.vector3Normalize(0, 1.5, 1) }, isTopRaycast = false }, { dir = { MathUtil.vector3Normalize(1, 1.5, 0) }, isTopRaycast = false }, { dir = { MathUtil.vector3Normalize(0, 1.5, -1) }, isTopRaycast = false }, { dir = { MathUtil.vector3Normalize(-1, 1.5, 0) }, isTopRaycast = false }, { dir = { MathUtil.vector3Normalize(0, 1, 0) }, isTopRaycast = true }, { dir = { MathUtil.vector3Normalize(1, 1.5, 1) }, isTopRaycast = false }, { dir = { MathUtil.vector3Normalize(1, 1.5, -1) }, isTopRaycast = false }, { dir = { MathUtil.vector3Normalize(-1, 1.5, -1) }, isTopRaycast = false }, { dir = { MathUtil.vector3Normalize(-1, 1.5, 1) }, isTopRaycast = false } }
	self.lastPosition = { x = 0, y = 0, z = 0 }
	self.tileSize = 4
	self.dataGrid = DynamicDataGrid.new(60, self.tileSize)
	self.treeCheckRadius = 25
	self.maxNumForestThreshold = 15
	self.minNumForestThreshold = 8
	self.minTopCollisionDistanceThreshold = 10
	self.maxTopCollisionDistanceThreshold = 20
	self.minWallCollisionDistanceThreshold = 5
	self.maxWallCollisionDistanceThreshold = 15
	self.normalizedWeights = {}
	self.currentWeight = EnvironmentAreaWeight.new()
	addConsoleCommand("gsEnvironmentAreaSystemToggleDebugView", "Toggles the environment checker debug view", "consoleCommandToggleDebugView", self)
	return self
end
function EnvironmentAreaSystem:delete()
	local mission = g_currentMission
	mission:removeDrawable(self)
	removeConsoleCommand("gsEnvironmentAreaSystemToggleDebugView")
	if self.infoLayer ~= nil then
		self.infoLayer:delete()
		self.infoLayer = nil
	end
end
function EnvironmentAreaSystem:initTerrain(terrainNode)
	self.infoLayer = InfoLayer.newFromMap(terrainNode, "environment")
	self.areaTypeStartChannel = 0
	self.areaTypeNumChannels = 3
	self.areaTypeMapping = {}
	self.areaTypeMapping[0] = AreaType.OPEN_FIELD
	self.areaTypeMapping[1] = AreaType.CITY
	self.areaTypeMapping[2] = AreaType.VILLAGE
	self.areaTypeMapping[3] = AreaType.HARBOR
	self.areaTypeMapping[4] = AreaType.INDUSTRIAL
	self.areaTypeMapping[5] = AreaType.OPEN_WATER
	self.waterStartChannel = 3
	self.waterNumChannels = 1
	self.waterTypeMapping = {}
	self.waterTypeMapping[0] = WaterType.NO_WATER
	self.waterTypeMapping[1] = WaterType.NEAR_WATER
end
function EnvironmentAreaSystem:loadMapData(mapXMLFile, missionInfo, baseDirectory)
	local outOfBoundsAreaTypeKey = "map.environmentAreaSystem#outOfBoundsAreaType"
	local outOfBoundsAreaTypeStr = getXMLString(mapXMLFile, "map.environmentAreaSystem#outOfBoundsAreaType")
	if outOfBoundsAreaTypeStr ~= nil then
		self.outOfBoundsAreaType = AreaType.getByName(outOfBoundsAreaTypeStr)
		if self.outOfBoundsAreaType == nil then
			Logging.xmlWarning(mapXMLFile, "Unknown AreaType %q at %q", outOfBoundsAreaTypeStr, "map.environmentAreaSystem#outOfBoundsAreaType")
		end
	end
end
function EnvironmentAreaSystem:getAreaTypeFromInfoLayerAtWorldPos(x, z)
	local infoLayer = self.infoLayer
	if infoLayer == nil then
		return nil
	elseif self.outOfBoundsAreaType and (g_terrainSizeHalf < math.abs(x) or g_terrainSizeHalf < math.abs(z)) then
		return self.outOfBoundsAreaType
	else
		local startChannel = self.areaTypeStartChannel
		local numChannels = self.areaTypeNumChannels
		local value = infoLayer:getValueAtWorldPos(x, z, startChannel, numChannels)
		return self.areaTypeMapping[value]
	end
end
function EnvironmentAreaSystem:getWaterTypeFromInfoLayerAtWorldPos(x, z)
	local infoLayer = self.infoLayer
	if infoLayer == nil then
		return nil
	else
		local startChannel = self.waterStartChannel
		local numChannels = self.waterNumChannels
		local value = infoLayer:getValueAtWorldPos(x, z, startChannel, numChannels)
		return self.waterTypeMapping[value]
	end
end
function EnvironmentAreaSystem:getAreaWeights()
	return self.currentWeight
end
function EnvironmentAreaSystem:update(dt)
	if not entityExists(self.referenceNode) then
		self.referenceNode = g_cameraManager:getActiveCamera()
	end
	if self.currentCell ~= nil then
		self:updateCell(self.currentCell)
		self:updateWeights()
	end
	local x, y, z = getWorldTranslation(self.referenceNode)
	self.dataGrid:setWorldPosition(x, z)
	local cell = self.dataGrid:getCellFromLocalIndices(0, 0)
	local wx, wz = self.dataGrid:getWorldPositionByLocalIndices(0, 0)
	self.currentCell = cell
	if cell.raycastIndexXZ == nil then
		self:setupCell(cell, wx, wz)
	else
		cell.raycastIndexXZ = cell.raycastIndexXZ + 2
	end
	if #self.raycastsXZ <= cell.raycastIndexXZ then
		cell.raycastIndexXZ = 0
		cell.isDone = true
		self.lastDoneCell = cell
	end
	local raycastXZ1 = self.raycastsXZ[cell.raycastIndexXZ + 1]
	raycastClosestAsync(x, y, z, raycastXZ1.dir[1], raycastXZ1.dir[2], raycastXZ1.dir[3], self.raycastsXZMaxDistance, "raycastXZCallback1", self, self.raycastCollisionMask)
	local raycastXZ2 = self.raycastsXZ[cell.raycastIndexXZ + 2]
	raycastClosestAsync(x, y, z, raycastXZ2.dir[1], raycastXZ2.dir[2], raycastXZ2.dir[3], self.raycastsXZMaxDistance, "raycastXZCallback2", self, self.raycastCollisionMask)
	if not cell.hasTopHit then
		raycastClosestAsync(x, y, z, 0, 1, 0, self.raycastsYMaxDistance, "raycastYCallback", self, self.raycastCollisionMask)
	end
	if cell.treeCount == nil then
		cell.treeCount = 0
		overlapSphereAsync(wx, y, wz, self.treeCheckRadius, "forestCheckCallback", self, CollisionFlag.TREE, false, false, true, false)
	end
	self.lastPosition.x = x
	self.lastPosition.y = y
	self.lastPosition.z = z
end
function EnvironmentAreaSystem:setupCell(cell, wx, wz)
	local areaType = self:getAreaTypeFromInfoLayerAtWorldPos(wx, wz)
	local waterType = self:getWaterTypeFromInfoLayerAtWorldPos(wx, wz)
	cell.isValid = true
	cell.isDone = false
	cell.raycastIndexXZ = 0
	cell.hitDataXZ = {}
	cell.areaTypeWeights = {}
	cell.treeCount = nil
	if cell.weights == nil then
		cell.weights = EnvironmentAreaWeight.new()
	else
		cell.weights:reset()
	end
	if waterType == WaterType.NEAR_WATER then
		cell.weights.isNearWaterWeight = 1
	end
	if areaType ~= nil then
		cell.weights.areaTypeWeights[areaType] = 1
	end
end
function EnvironmentAreaSystem:updateCell(cell)
	local weights = cell.weights
	if self.maxNumForestThreshold < cell.treeCount then
		weights.isInForestWeight = 1
	elseif self.minNumForestThreshold < cell.treeCount then
		weights.isInForestWeight = MathUtil.inverseLerp(self.minNumForestThreshold, self.maxNumForestThreshold, cell.treeCount)
	end
	if cell.hasTopHit then
		weights.isUnderRoofWeight = 1
	end
	local nearestWallDistance = math.huge
	for _, data in pairs(cell.hitDataXZ) do
		nearestWallDistance = math.min(nearestWallDistance, data.distance)
	end
	if nearestWallDistance < self.maxWallCollisionDistanceThreshold then
		local wallWeight = 1 - MathUtil.inverseLerp(self.minWallCollisionDistanceThreshold, self.maxWallCollisionDistanceThreshold, nearestWallDistance)
		weights.isNearWallWeight = wallWeight
	end
end
function EnvironmentAreaSystem:updateWeights()
	local currentWeight = self.currentWeight
	currentWeight:reset()
	local fallbackCell = self.dataGrid:getCellFromLocalIndices(0, 0)
	if not fallbackCell.isDone and (self.lastDoneCell ~= nil and self.lastDoneCell.weights ~= nil) then
		fallbackCell = self.lastDoneCell
	end
	local cellOffset = 3
	local weightSum = 0
	for i = 1, 3 do
		for j = 1, 3 do
			local cell = self.dataGrid:getCellFromLocalIndices(i - 2, j - 2)
			local wx, wz = self.dataGrid:getWorldPositionByLocalIndices(i - 2, j - 2)
			local distance = math.min(MathUtil.vector2Length(wx - self.lastPosition.x, wz - self.lastPosition.z), self.tileSize)
			local weightFactor = math.clamp(1 - distance / self.tileSize, 0, 1)
			self.normalizedWeights[cell] = weightFactor
			weightSum = weightSum + weightFactor
		end
	end
	for cell, normalizedWeight in pairs(self.normalizedWeights) do
		local normalizedWeight = normalizedWeight / weightSum
		local weights = cell.weights
		if weights == nil or not cell.isDone then
			weights = fallbackCell.weights
		end
		currentWeight.isNearWallWeight = currentWeight.isNearWallWeight + weights.isNearWallWeight * normalizedWeight
		currentWeight.isNearWaterWeight = currentWeight.isNearWaterWeight + weights.isNearWaterWeight * normalizedWeight
		currentWeight.isUnderRoofWeight = currentWeight.isUnderRoofWeight + weights.isUnderRoofWeight * normalizedWeight
		currentWeight.isInForestWeight = currentWeight.isInForestWeight + weights.isInForestWeight * normalizedWeight
		for areaTypeIndex, weight in pairs(weights.areaTypeWeights) do
			local appliedWeight = weight * normalizedWeight
			currentWeight.areaTypeWeights[areaTypeIndex] = currentWeight.areaTypeWeights[areaTypeIndex] + appliedWeight
		end
		self.normalizedWeights[cell] = nil
	end
end
function EnvironmentAreaSystem:raycastXZCallback1(hitObjectId, x, y, z, distance, nx, ny, nz, subShapeIndex, shapeId, isLast)
	self:handleRaycast(1, hitObjectId, x, y, z, distance, nx, ny, nz, subShapeIndex, shapeId, isLast)
end
function EnvironmentAreaSystem:raycastXZCallback2(hitObjectId, x, y, z, distance, nx, ny, nz, subShapeIndex, shapeId, isLast)
	self:handleRaycast(2, hitObjectId, x, y, z, distance, nx, ny, nz, subShapeIndex, shapeId, isLast)
end
function EnvironmentAreaSystem:handleRaycast(indexOffset, hitObjectId, x, y, z, distance, nx, ny, nz, subShapeIndex, shapeId, isLast)
	local cell = self.currentCell
	local raycastIndexXZ = cell.raycastIndexXZ + indexOffset
	if hitObjectId ~= 0 and (cell.hitDataXZ[raycastIndexXZ] == nil or distance < cell.hitDataXZ[raycastIndexXZ].distance) then
		cell.hitDataXZ[raycastIndexXZ] = { x = x, y = y, z = z, distance = distance, name = getName(hitObjectId) }
	end
end
function EnvironmentAreaSystem:raycastYCallback(hitObjectId, x, y, z, distance, nx, ny, nz, subShapeIndex, shapeId, isLast)
	local cell = self.currentCell
	if hitObjectId ~= 0 then
		cell.hasTopHit = true
	end
end
function EnvironmentAreaSystem:setReferenceNode(node)
	self.referenceNode = node
end
function EnvironmentAreaSystem:forestCheckCallback(transformId)
	if transformId ~= 0 and (getHasClassId(transformId, ClassIds.MESH_SPLIT_SHAPE) and (getSplitType(transformId) ~= 0 and not getIsSplitShapeSplit(transformId))) then
		self.currentCell.treeCount = self.currentCell.treeCount + 1
	end
	return true
end
function EnvironmentAreaSystem:draw()
	local terrainNode = g_terrainNode
	self.dataGrid:drawDebug(function(cell)
		local alpha = 0.1
		if not cell.isValid then
			return 1, 0, 0, 0.1
		elseif not cell.isDone then
			return 0, 0, 1, 0.1
		else
			return 0, 1, 0, 0.1
		end
	end, function(cell, cx, cz)
		local text = nil
		if cell.treeCount ~= nil then
			text = string.format("%s\nTrees: %d", text or "", cell.treeCount)
		end
		if text ~= nil then
			local cy = getTerrainHeightAtWorldPos(terrainNode, cx, 0, cz) + 0.1
			DebugGizmo.renderAtPosition(cx, cy, cz, 0, 0, 1, 0, 1, 0, text, false)
		end
		if cell == self.currentCell and cell.hitDataXZ ~= nil then
			for k, data in pairs(cell.hitDataXZ) do
				DebugPoint.renderAtPosition(data.x, data.y, data.z, nil, false, string.format("Raycast-XZ %d\n%.3f", k, data.distance), nil, nil, 150)
			end
		end
	end)
	setTextColor(1, 1, 1, 1)
	self.currentWeight:drawDebug(0.3, 0.6, getCorrectTextSize(0.012))
end
function EnvironmentAreaSystem:getWaterYAtWorldPosition(x, y, z)
	y = y or 100
	self.waterY = nil
	raycastClosest(x, y + 100, z, 0, -1, 0, 200, "onWaterRaycastCallback", self, CollisionFlag.WATER)
	return self.waterY
end
function EnvironmentAreaSystem:onWaterRaycastCallback(hitObjectId, x, y, z, distance, nx, ny, nz, subShapeIndex, shapeId, isLast)
	if hitObjectId ~= 0 then
		self.waterY = y
	end
end
function EnvironmentAreaSystem:getWaterYAtWorldPositionAsync(x, y, z, callbackFunction, callbackTarget, executeImmediately, arguments)
	local target = {}
	function target.onWaterCallback(_, nodeId, x, y, z, distance, nx, ny, nz, subShapeIndex, shapeId, isLast)
		local waterY = nil
		if nodeId ~= 0 then
			waterY = y
		end
		if callbackTarget ~= nil then
			callbackFunction(callbackTarget, waterY, arguments)
		else
			callbackFunction(waterY, arguments)
		end
	end
	raycastClosestAsync(x, y + 100, z, 0, -1, 0, 200, "onWaterCallback", target, CollisionFlag.WATER)
end
function EnvironmentAreaSystem:getWaterDepthAtWorldPositionAsync(x, y, z, callbackFunction, callbackTarget, arguments)
	local target = {}
	function target.onWaterCallback(_, nodeId, x, y, z, distance, nx, ny, nz, subShapeIndex, shapeId, isLast)
		local depth = 0
		local waterSurfaceWorldY = nil
		if nodeId ~= 0 then
			waterSurfaceWorldY = y
			local terrainHeight = getTerrainHeightAtWorldPos(g_terrainNode, x, 0, z)
			if terrainHeight < y then
				depth = y - terrainHeight
			end
		end
		if callbackTarget ~= nil then
			callbackFunction(callbackTarget, depth, waterSurfaceWorldY, arguments)
		else
			callbackFunction(depth, waterSurfaceWorldY, arguments)
		end
	end
	raycastClosestAsync(x, y + 100, z, 0, -1, 0, 200, "onWaterCallback", target, CollisionFlag.WATER)
end
function EnvironmentAreaSystem:consoleCommandToggleDebugView()
	self.isDebugViewActive = not self.isDebugViewActive
	local mission = g_currentMission
	if self.isDebugViewActive then
		mission:addDrawable(self)
	else
		mission:removeDrawable(self)
	end
	return string.format("EnvironmentAreaSystem.isDebugViewActive=%s", self.isDebugViewActive)
end
