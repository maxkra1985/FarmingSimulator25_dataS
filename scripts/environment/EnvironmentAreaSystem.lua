-- Local values: EnvironmentAreaSystem_mt
EnvironmentAreaSystem = {}
local EnvironmentAreaSystem_mt = Class(EnvironmentAreaSystem)

-- Local values: name, id
function EnvironmentAreaSystem.getName(index)
	for v3_, v4_ in pairs(EnvironmentAreaSystem) do
		if index == v4_ then
			return v3_
		end
	end
	return ""
end

-- Upvalues: EnvironmentAreaSystem_mt
-- Local values: self
function EnvironmentAreaSystem.new(customMt)
	-- upvalues: (copy) EnvironmentAreaSystem_mt
	local v6_ = customMt or EnvironmentAreaSystem_mt
	local v7_ = setmetatable({}, v6_)
	v7_.isDebugViewActive = false
	v7_.referenceNode = g_cameraManager:getActiveCamera()
	v7_.raycastCollisionMask = CollisionFlag.BUILDING
	v7_.raycastsXZMaxDistance = 30
	v7_.raycastsYMaxDistance = 30
	v7_.raycastsXZ = {
		{
			["dir"] = { MathUtil.vector3Normalize(0, 0, 1) }
		},
		{
			["dir"] = { MathUtil.vector3Normalize(1, 0, 0) }
		},
		{
			["dir"] = { MathUtil.vector3Normalize(0, 0, -1) }
		},
		{
			["dir"] = { MathUtil.vector3Normalize(-1, 0, 0) }
		},
		{
			["dir"] = { MathUtil.vector3Normalize(1, 0, 1) }
		},
		{
			["dir"] = { MathUtil.vector3Normalize(1, 0, -1) }
		},
		{
			["dir"] = { MathUtil.vector3Normalize(-1, 0, -1) }
		},
		{
			["dir"] = { MathUtil.vector3Normalize(-1, 0, 1) }
		}
	}
	v7_.raycastsY = {
		{
			["dir"] = { MathUtil.vector3Normalize(0, 1, 0) },
			["isTopRaycast"] = true
		},
		{
			["dir"] = { MathUtil.vector3Normalize(0, 1.5, 1) },
			["isTopRaycast"] = false
		},
		{
			["dir"] = { MathUtil.vector3Normalize(1, 1.5, 0) },
			["isTopRaycast"] = false
		},
		{
			["dir"] = { MathUtil.vector3Normalize(0, 1.5, -1) },
			["isTopRaycast"] = false
		},
		{
			["dir"] = { MathUtil.vector3Normalize(-1, 1.5, 0) },
			["isTopRaycast"] = false
		},
		{
			["dir"] = { MathUtil.vector3Normalize(0, 1, 0) },
			["isTopRaycast"] = true
		},
		{
			["dir"] = { MathUtil.vector3Normalize(1, 1.5, 1) },
			["isTopRaycast"] = false
		},
		{
			["dir"] = { MathUtil.vector3Normalize(1, 1.5, -1) },
			["isTopRaycast"] = false
		},
		{
			["dir"] = { MathUtil.vector3Normalize(-1, 1.5, -1) },
			["isTopRaycast"] = false
		},
		{
			["dir"] = { MathUtil.vector3Normalize(-1, 1.5, 1) },
			["isTopRaycast"] = false
		}
	}
	v7_.lastPosition = {
		["x"] = 0,
		["y"] = 0,
		["z"] = 0
	}
	v7_.tileSize = 4
	v7_.dataGrid = DynamicDataGrid.new(60, v7_.tileSize)
	v7_.treeCheckRadius = 25
	v7_.maxNumForestThreshold = 15
	v7_.minNumForestThreshold = 8
	v7_.minTopCollisionDistanceThreshold = 10
	v7_.maxTopCollisionDistanceThreshold = 20
	v7_.minWallCollisionDistanceThreshold = 5
	v7_.maxWallCollisionDistanceThreshold = 15
	v7_.normalizedWeights = {}
	v7_.currentWeight = EnvironmentAreaWeight.new()
	addConsoleCommand("gsEnvironmentAreaSystemToggleDebugView", "Toggles the environment checker debug view", "consoleCommandToggleDebugView", v7_)
	return v7_
end

-- Local values: mission
function EnvironmentAreaSystem:delete()
	g_currentMission:removeDrawable(self)
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

-- Local values: outOfBoundsAreaTypeKey, outOfBoundsAreaTypeStr
function EnvironmentAreaSystem:loadMapData(mapXMLFile, missionInfo, baseDirectory)
	local v13_ = getXMLString(mapXMLFile, "map.environmentAreaSystem#outOfBoundsAreaType")
	if v13_ ~= nil then
		self.outOfBoundsAreaType = AreaType.getByName(v13_)
		if self.outOfBoundsAreaType == nil then
			Logging.xmlWarning(mapXMLFile, "Unknown AreaType %q at %q", v13_, "map.environmentAreaSystem#outOfBoundsAreaType")
		end
	end
end

-- Local values: infoLayer, startChannel, numChannels, value
function EnvironmentAreaSystem:getAreaTypeFromInfoLayerAtWorldPos(x, z)
	local v17_ = self.infoLayer
	if v17_ == nil then
		return nil
	end
	if self.outOfBoundsAreaType and (math.abs(x) > g_terrainSizeHalf or math.abs(z) > g_terrainSizeHalf) then
		return self.outOfBoundsAreaType
	end
	local v18_ = v17_:getValueAtWorldPos(x, z, self.areaTypeStartChannel, self.areaTypeNumChannels)
	return self.areaTypeMapping[v18_]
end

-- Local values: infoLayer, startChannel, numChannels, value
function EnvironmentAreaSystem:getWaterTypeFromInfoLayerAtWorldPos(x, z)
	local v22_ = self.infoLayer
	if v22_ == nil then
		return nil
	end
	local v23_ = v22_:getValueAtWorldPos(x, z, self.waterStartChannel, self.waterNumChannels)
	return self.waterTypeMapping[v23_]
end

function EnvironmentAreaSystem:getAreaWeights()
	return self.currentWeight
end

-- Local values: x, y, z, cell, wx, wz, raycastXZ1, raycastXZ2
function EnvironmentAreaSystem:update(dt)
	if not entityExists(self.referenceNode) then
		self.referenceNode = g_cameraManager:getActiveCamera()
	end
	if self.currentCell ~= nil then
		self:updateCell(self.currentCell)
		self:updateWeights()
	end
	local v26_, v27_, v28_ = getWorldTranslation(self.referenceNode)
	self.dataGrid:setWorldPosition(v26_, v28_)
	local v29_ = self.dataGrid:getCellFromLocalIndices(0, 0)
	local v30_, v31_ = self.dataGrid:getWorldPositionByLocalIndices(0, 0)
	self.currentCell = v29_
	if v29_.raycastIndexXZ == nil then
		self:setupCell(v29_, v30_, v31_)
	else
		v29_.raycastIndexXZ = v29_.raycastIndexXZ + 2
	end
	if v29_.raycastIndexXZ >= #self.raycastsXZ then
		v29_.raycastIndexXZ = 0
		v29_.isDone = true
		self.lastDoneCell = v29_
	end
	local v32_ = self.raycastsXZ[v29_.raycastIndexXZ + 1]
	raycastClosestAsync(v26_, v27_, v28_, v32_.dir[1], v32_.dir[2], v32_.dir[3], self.raycastsXZMaxDistance, "raycastXZCallback1", self, self.raycastCollisionMask)
	local v33_ = self.raycastsXZ[v29_.raycastIndexXZ + 2]
	raycastClosestAsync(v26_, v27_, v28_, v33_.dir[1], v33_.dir[2], v33_.dir[3], self.raycastsXZMaxDistance, "raycastXZCallback2", self, self.raycastCollisionMask)
	if not v29_.hasTopHit then
		raycastClosestAsync(v26_, v27_, v28_, 0, 1, 0, self.raycastsYMaxDistance, "raycastYCallback", self, self.raycastCollisionMask)
	end
	if v29_.treeCount == nil then
		v29_.treeCount = 0
		overlapSphereAsync(v30_, v27_, v31_, self.treeCheckRadius, "forestCheckCallback", self, CollisionFlag.TREE, false, false, true, false)
	end
	self.lastPosition.x = v26_
	self.lastPosition.y = v27_
	self.lastPosition.z = v28_
end

-- Local values: areaType, waterType
function EnvironmentAreaSystem:setupCell(cell, wx, wz)
	local v38_ = self:getAreaTypeFromInfoLayerAtWorldPos(wx, wz)
	local v39_ = self:getWaterTypeFromInfoLayerAtWorldPos(wx, wz)
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
	if v39_ == WaterType.NEAR_WATER then
		cell.weights.isNearWaterWeight = 1
	end
	if v38_ ~= nil then
		cell.weights.areaTypeWeights[v38_] = 1
	end
end

-- Local values: weights, nearestWallDistance, _, data, wallWeight
function EnvironmentAreaSystem:updateCell(cell)
	local v42_ = cell.weights
	if cell.treeCount > self.maxNumForestThreshold then
		v42_.isInForestWeight = 1
	elseif cell.treeCount > self.minNumForestThreshold then
		v42_.isInForestWeight = MathUtil.inverseLerp(self.minNumForestThreshold, self.maxNumForestThreshold, cell.treeCount)
	end
	if cell.hasTopHit then
		v42_.isUnderRoofWeight = 1
	end
	local v43_ = math.huge
	for _, v44_ in pairs(cell.hitDataXZ) do
		local v45_ = v44_.distance
		v43_ = math.min(v43_, v45_)
	end
	if v43_ < self.maxWallCollisionDistanceThreshold then
		v42_.isNearWallWeight = 1 - MathUtil.inverseLerp(self.minWallCollisionDistanceThreshold, self.maxWallCollisionDistanceThreshold, v43_)
	end
end

-- Local values: currentWeight, fallbackCell, cellOffset, weightSum, i, j, cell, wx, wz, distance, weightFactor, cell, normalizedWeight, weights, areaTypeIndex, weight, appliedWeight
function EnvironmentAreaSystem:updateWeights()
	local v47_ = self.currentWeight
	v47_:reset()
	local v48_ = self.dataGrid:getCellFromLocalIndices(0, 0)
	if not v48_.isDone and (self.lastDoneCell ~= nil and self.lastDoneCell.weights ~= nil) then
		v48_ = self.lastDoneCell
	end
	local v49_ = 0
	for v50_ = 1, 3 do
		for v51_ = 1, 3 do
			local v52_ = self.dataGrid:getCellFromLocalIndices(v50_ - 2, v51_ - 2)
			local v53_, v54_ = self.dataGrid:getWorldPositionByLocalIndices(v50_ - 2, v51_ - 2)
			local v55_ = MathUtil.vector2Length(v53_ - self.lastPosition.x, v54_ - self.lastPosition.z)
			local v56_ = self.tileSize
			local v57_ = 1 - math.min(v55_, v56_) / self.tileSize
			local v58_ = math.clamp(v57_, 0, 1)
			self.normalizedWeights[v52_] = v58_
			v49_ = v49_ + v58_
		end
	end
	for v59_, v60_ in pairs(self.normalizedWeights) do
		local v61_ = v60_ / v49_
		local v62_ = v59_.weights
		if v62_ == nil or not v59_.isDone then
			v62_ = v48_.weights
		end
		v47_.isNearWallWeight = v47_.isNearWallWeight + v62_.isNearWallWeight * v61_
		v47_.isNearWaterWeight = v47_.isNearWaterWeight + v62_.isNearWaterWeight * v61_
		v47_.isUnderRoofWeight = v47_.isUnderRoofWeight + v62_.isUnderRoofWeight * v61_
		v47_.isInForestWeight = v47_.isInForestWeight + v62_.isInForestWeight * v61_
		for v63_, v64_ in pairs(v62_.areaTypeWeights) do
			local v65_ = v64_ * v61_
			v47_.areaTypeWeights[v63_] = v47_.areaTypeWeights[v63_] + v65_
		end
		self.normalizedWeights[v59_] = nil
	end
end

function EnvironmentAreaSystem:raycastXZCallback1(hitObjectId, x, y, z, distance, nx, ny, nz, subShapeIndex, shapeId, isLast)
	self:handleRaycast(1, hitObjectId, x, y, z, distance, nx, ny, nz, subShapeIndex, shapeId, isLast)
end

function EnvironmentAreaSystem:raycastXZCallback2(hitObjectId, x, y, z, distance, nx, ny, nz, subShapeIndex, shapeId, isLast)
	self:handleRaycast(2, hitObjectId, x, y, z, distance, nx, ny, nz, subShapeIndex, shapeId, isLast)
end

-- Local values: cell, raycastIndexXZ
function EnvironmentAreaSystem:handleRaycast(indexOffset, hitObjectId, x, y, z, distance, nx, ny, nz, subShapeIndex, shapeId, isLast)
	local v97_ = self.currentCell
	local v98_ = v97_.raycastIndexXZ + indexOffset
	if hitObjectId ~= 0 and (v97_.hitDataXZ[v98_] == nil or distance < v97_.hitDataXZ[v98_].distance) then
		v97_.hitDataXZ[v98_] = {
			["name"] = getName(hitObjectId),
			["x"] = x,
			["y"] = y,
			["z"] = z,
			["distance"] = distance
		}
	end
end

-- Local values: cell
function EnvironmentAreaSystem:raycastYCallback(hitObjectId, x, y, z, distance, nx, ny, nz, subShapeIndex, shapeId, isLast)
	local v101_ = self.currentCell
	if hitObjectId ~= 0 then
		v101_.hasTopHit = true
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

-- Local values: terrainNode
function EnvironmentAreaSystem:draw()
	local v_u_107_ = g_terrainNode
	self.dataGrid:drawDebug(function(p108_)
		if p108_.isValid then
			if p108_.isDone then
				return 0, 1, 0, 0.1
			else
				return 0, 0, 1, 0.1
			end
		else
			return 1, 0, 0, 0.1
		end
	end, function(p109_, p110_, p111_)
		-- upvalues: (copy) v_u_107_, (copy) self
		local v112_ = nil
		if p109_.treeCount ~= nil then
			v112_ = string.format("%s\nTrees: %d", v112_ or "", p109_.treeCount)
		end
		if v112_ ~= nil then
			local v113_ = getTerrainHeightAtWorldPos(v_u_107_, p110_, 0, p111_) + 0.1
			DebugGizmo.renderAtPosition(p110_, v113_, p111_, 0, 0, 1, 0, 1, 0, v112_, false)
		end
		if p109_ == self.currentCell and p109_.hitDataXZ ~= nil then
			for v114_, v115_ in pairs(p109_.hitDataXZ) do
				DebugPoint.renderAtPosition(v115_.x, v115_.y, v115_.z, nil, false, string.format("Raycast-XZ %d\n%.3f", v114_, v115_.distance), nil, nil, 150)
			end
		end
	end)
	setTextColor(1, 1, 1, 1)
	self.currentWeight:drawDebug(0.3, 0.6, getCorrectTextSize(0.012))
end

function EnvironmentAreaSystem:getWaterYAtWorldPosition(x, y, z)
	self.waterY = nil
	raycastClosest(x, (y or 100) + 100, z, 0, -1, 0, 200, "onWaterRaycastCallback", self, CollisionFlag.WATER)
	return self.waterY
end

function EnvironmentAreaSystem:onWaterRaycastCallback(hitObjectId, x, y, z, distance, nx, ny, nz, subShapeIndex, shapeId, isLast)
	if hitObjectId ~= 0 then
		self.waterY = y
	end
end

-- Local values: target
function EnvironmentAreaSystem:getWaterYAtWorldPositionAsync(x, y, z, callbackFunction, callbackTarget, executeImmediately, arguments)
	raycastClosestAsync(x, y + 100, z, 0, -1, 0, 200, "onWaterCallback", {
		["onWaterCallback"] = function(_, p129_, _, p130_, _, _, _, _, _, _, _, _)
			-- upvalues: (copy) callbackTarget, (copy) callbackFunction, (copy) arguments
			if p129_ == 0 then
				p130_ = nil
			end
			if callbackTarget == nil then
				callbackFunction(p130_, arguments)
			else
				callbackFunction(callbackTarget, p130_, arguments)
			end
		end
	}, CollisionFlag.WATER)
end

-- Local values: target
function EnvironmentAreaSystem:getWaterDepthAtWorldPositionAsync(x, y, z, callbackFunction, callbackTarget, arguments)
	raycastClosestAsync(x, y + 100, z, 0, -1, 0, 200, "onWaterCallback", {
		["onWaterCallback"] = function(_, p137_, p138_, p139_, p140_, _, _, _, _, _, _, _)
			-- upvalues: (copy) callbackTarget, (copy) callbackFunction, (copy) arguments
			local v141_ = 0
			if p137_ == 0 then
				p139_ = nil
			else
				local v142_ = getTerrainHeightAtWorldPos(g_terrainNode, p138_, 0, p140_)
				if v142_ < p139_ then
					v141_ = p139_ - v142_
				end
			end
			if callbackTarget == nil then
				callbackFunction(v141_, p139_, arguments)
			else
				callbackFunction(callbackTarget, v141_, p139_, arguments)
			end
		end
	}, CollisionFlag.WATER)
end

-- Local values: mission
function EnvironmentAreaSystem:consoleCommandToggleDebugView()
	self.isDebugViewActive = not self.isDebugViewActive
	local v144_ = g_currentMission
	if self.isDebugViewActive then
		v144_:addDrawable(self)
	else
		v144_:removeDrawable(self)
	end
	return string.format("EnvironmentAreaSystem.isDebugViewActive=%s", self.isDebugViewActive)
end
