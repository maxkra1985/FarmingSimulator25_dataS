Landscaping = {}
local Landscaping_mt = Class(Landscaping)
Landscaping.BRUSH_SHAPE_NUM_SEND_BITS = 2
Landscaping.OPERATION_NUM_SEND_BITS = 3
Landscaping.BRUSH_SHAPE = { SQUARE = 1, CIRCLE = 2 }
Landscaping.OPERATION = { RAISE = 1, LOWER = 2, SMOOTH = 3, FLATTEN = 4, PAINT = 5, FOLIAGE = 6, SLOPE = 7 }
Landscaping.OPERATION_HEIGHT_CHANGE_FACTOR_MAP = { [Landscaping.OPERATION.RAISE] = 1, [Landscaping.OPERATION.LOWER] = -1, [Landscaping.OPERATION.SMOOTH] = 0, [Landscaping.OPERATION.FLATTEN] = 0, [Landscaping.OPERATION.PAINT] = 0, [Landscaping.OPERATION.FOLIAGE] = 0, [Landscaping.OPERATION.SLOPE] = 1 }
Landscaping.SCULPT_BASE_COST_PER_M3 = 10
Landscaping.PAINT_BASE_COST_PER_M2 = 1
Landscaping.FOLIAGE_BASE_COST_PER_M2 = 0.2
local NO_CALLBACK = function() end
local SQRT_2_DIV_FACTOR = 0.7071067811865475
function Landscaping.new(terrainDeformationQueue, placementCollisionMap, userId, validateOnly, callbackFunction, callbackFunctionTarget)
	local self = setmetatable({}, Landscaping_mt)
	self.terrainDeformationQueue = terrainDeformationQueue
	self.placementCollisionMap = placementCollisionMap
	self.userId = userId
	self.validateOnly = validateOnly
	self.callbackFunction = callbackFunction or NO_CALLBACK
	self.callbackFunctionTarget = callbackFunctionTarget
	self.terrainUnit = getTerrainHeightmapUnitSize(g_terrainNode)
	self.halfTerrainUnit = self.terrainUnit / 2
	self.targetPositionX = nil
	self.targetPositionY = nil
	self.targetPositionZ = nil
	self.radius = 0
	self.brushShape = Landscaping.BRUSH_SHAPE.SQUARE
	self.smoothingDistance = 0
	self.sculptingOperation = Landscaping.OPERATION.RAISE
	self.modifiedAreas = {}
	return self
end
function Landscaping:delete() end
function Landscaping:hasObjectOverlapInModificationArea(x, y, z)
	local numOverlaps = overlapCylinder(x, y, z, self.radius + 0.5, 10, Axis.Y, "", nil, CollisionFlag.PLAYER, true, false, false, false)
	return 0 < numOverlaps
end
function Landscaping:addModifiedCircleArea(x, z, radius)
	if radius < self.terrainUnit + self.halfTerrainUnit then
		local size = radius * 2 * 0.7071067811865475
		self:addModifiedSquareArea(x, z, size)
	else
		for ox = -radius / self.terrainUnit, radius / self.terrainUnit - 1 do
			local xStart = ox * self.terrainUnit
			local xEnd = ox * self.terrainUnit + self.terrainUnit
			local zOffset1 = math.sin(math.acos(math.abs(xStart) / radius)) * radius
			local zOffset2 = math.sin(math.acos(math.abs(xEnd) / radius)) * radius
			local zOffset = math.min(zOffset1, zOffset2) - 0.02
			table.insert(self.modifiedAreas, { x + xStart, z - zOffset, x + xEnd, z - zOffset, x + xStart, z + zOffset })
		end
	end
end
function Landscaping:addModifiedSquareArea(x, z, side)
	local halfSide = side * 0.5
	table.insert(self.modifiedAreas, { x - halfSide, z - halfSide, x + halfSide, z - halfSide, x - halfSide, z + halfSide })
end
function Landscaping:assignSmoothingParameters(deform, x, z, radius, strength, brushShape)
	local hardness = 1
	deform:setAdditiveHeightChangeAmount(2)
	if brushShape == Landscaping.BRUSH_SHAPE.CIRCLE then
		deform:addSoftCircleBrush(x, z, radius, 1, strength)
		self:addModifiedCircleArea(x, z, radius)
	else
		deform:addSoftSquareBrush(x, z, radius * 2, 1, strength)
		self:addModifiedSquareArea(x, z, radius * 2)
	end
	deform:enableSmoothingMode()
end
function Landscaping:assignPaintingParameters(deform, x, z, radius, brushShape, layerIndex)
	if brushShape == Landscaping.BRUSH_SHAPE.CIRCLE then
		deform:addSoftCircleBrush(x, z, radius, 1, 1, layerIndex)
		self:addModifiedCircleArea(x, z, radius)
	else
		deform:addSoftSquareBrush(x, z, radius * 2, 1, 1, layerIndex)
		self:addModifiedSquareArea(x, z, radius * 2)
	end
	deform:enablePaintingMode()
end
function Landscaping:assignSculptingParameters(deform, x, y, z, nx, ny, nz, d, minY, maxY, radius, strength, brushShape, operation, smoothingDistance)
	local hardness = 0.2
	if operation == Landscaping.OPERATION.FLATTEN then
		deform:setAdditiveHeightChangeAmount(0.75)
		deform:setHeightTarget(y, y, 0, 1, 0, -y)
		deform:enableSetDeformationMode()
	elseif operation == Landscaping.OPERATION.LOWER then
		deform:enableAdditiveDeformationMode()
		deform:setAdditiveHeightChangeAmount(-0.005)
	elseif operation == Landscaping.OPERATION.RAISE then
		deform:enableAdditiveDeformationMode()
		deform:setAdditiveHeightChangeAmount(0.005)
	elseif operation == Landscaping.OPERATION.SLOPE then
		deform:setAdditiveHeightChangeAmount(0.75)
		deform:setHeightTarget(minY, maxY, nx, ny, nz, d)
		deform:enableSetDeformationMode()
	end
	if brushShape == Landscaping.BRUSH_SHAPE.SQUARE then
		deform:addSoftSquareBrush(x, z, radius * 2, 0.2, strength)
		self:addModifiedSquareArea(x, z, radius * 2)
	else
		deform:addSoftCircleBrush(x, z, radius, 0.2, strength)
		self:addModifiedCircleArea(x, z, radius)
	end
	deform:setOutsideAreaConstraints(0, 1.3089969389957472, 1.3089969389957472)
end
function Landscaping:sculpt(x, y, z, nx, ny, nz, d, minY, maxY, radius, strength, brushShape, operation, smoothingDistance, terrainPaintingLayer, terrainFoliageLayer, terrainFoliageValue)
	local deform = TerrainDeformation.new(g_terrainNode)
	self.currentTerrainDeformation = deform
	self.targetPositionX = x
	self.targetPositionY = y
	self.targetPositionZ = z
	self.radius = radius
	self.brushShape = brushShape
	self.smoothingDistance = math.max(smoothingDistance, self.terrainUnit)
	self.sculptingOperation = operation
	local displacedFoliageArea = 0
	if operation == Landscaping.OPERATION.SMOOTH then
		self:assignSmoothingParameters(deform, x, z, radius, strength, brushShape)
	elseif operation == Landscaping.OPERATION.PAINT then
		self:assignPaintingParameters(deform, x, z, radius, brushShape, terrainPaintingLayer)
	elseif operation == Landscaping.OPERATION.FOLIAGE then
		local farm = g_farmManager:getFarmByUserId(self.userId)
		if farm:getBalance() < Landscaping.FOLIAGE_BASE_COST_PER_M2 then
			self:onSculptingValidated(TerrainDeformation.STATE_FAILED_NOT_ENOUGH_MONEY, 0, false)
			return
		end
		local foliageSystem = g_currentMission.foliageSystem
		if brushShape == Landscaping.BRUSH_SHAPE.CIRCLE then
			if 1 <= radius then
				local unit = 0.5
				for ox = -radius / 0.5, radius / 0.5 - 1 do
					local xStart = ox * 0.5
					local xEnd = ox * 0.5 + 0.5
					local zOffset1 = math.sin(math.acos(math.abs(xStart) / radius)) * radius
					local zOffset2 = math.sin(math.acos(math.abs(xEnd) / radius)) * radius
					local zOffset = math.min(zOffset1, zOffset2) - 0.02
					displacedFoliageArea = displacedFoliageArea + foliageSystem:apply(foliageSystem:getFoliagePaint(terrainFoliageLayer), x + xStart, z - zOffset, x + xEnd, z - zOffset, x + xStart, z + zOffset, terrainFoliageValue)
				end
			else
				if brushShape == Landscaping.BRUSH_SHAPE.CIRCLE then
					radius = radius / 2
				end
				local x0 = x - radius
				local z0 = z - radius
				local x1 = x - radius
				local z1 = z + radius
				local x2 = x + radius
				local z2 = z - radius
				displacedFoliageArea = foliageSystem:apply(foliageSystem:getFoliagePaint(terrainFoliageLayer), x0, z0, x1, z1, x2, z2, terrainFoliageValue)
			end
		end
	else
		self:assignSculptingParameters(deform, x, y, z, nx, ny, nz, d, minY, maxY, radius, strength, brushShape, operation, self.smoothingDistance)
	end
	if operation ~= Landscaping.OPERATION.PAINT and operation ~= Landscaping.OPERATION.FOLIAGE then
		deform:setBlockedAreaMaxDisplacement(0.01)
		deform:setDynamicObjectCollisionMask(CollisionMask.LANDSCAPING)
		deform:setDynamicObjectMaxDisplacement(0.03)
		if self.placementCollisionMap ~= nil then
			deform:setBlockedAreaMap(self.placementCollisionMap, 0)
		end
	end
	if operation == Landscaping.OPERATION.FOLIAGE then
		self:onSculptingValidated(TerrainDeformation.STATE_SUCCESS, displacedFoliageArea, false)
	else
		if (operation == Landscaping.OPERATION.SMOOTH or operation == Landscaping.OPERATION.PAINT) and not self.validateOnly then
			deform:apply(true, "onSculptingValidated", self)
			return
		end
		self.terrainDeformationQueue:queueJob(deform, true, "onSculptingValidated", self)
	end
end
function Landscaping:onSculptingValidated(errorCode, displacedVolumeOrArea, blocked)
	if errorCode == TerrainDeformation.STATE_SUCCESS then
		local additionalChecksPassed = true
		local updatedErrorCode = errorCode
		local farm = g_farmManager:getFarmByUserId(self.userId)
		if farm:getBalance() < self:getCost(displacedVolumeOrArea) then
			updatedErrorCode = TerrainDeformation.STATE_FAILED_NOT_ENOUGH_MONEY
			additionalChecksPassed = false
		end
		local ownsTargetLand = Landscaping.isModificationAreaOnOwnedLand(self.targetPositionX, self.targetPositionZ, self.radius + self.smoothingDistance, farm:getId())
		if not ownsTargetLand then
			updatedErrorCode = TerrainDeformation.STATE_FAILED_NOT_OWNED
			additionalChecksPassed = false
		end
		if self.sculptingOperation ~= Landscaping.OPERATION.PAINT and self.sculptingOperation ~= Landscaping.OPERATION.FOLIAGE then
			if self:isModificationAreaPlacementBlocked(self.targetPositionX, self.targetPositionZ, self.radius) then
				updatedErrorCode = TerrainDeformation.STATE_FAILED_BLOCKED
				additionalChecksPassed = false
			end
			local dynamicObjectBlocking = self:hasObjectOverlapInModificationArea(self.targetPositionX, self.targetPositionY, self.targetPositionZ)
			if dynamicObjectBlocking then
				updatedErrorCode = TerrainDeformation.STATE_FAILED_COLLIDE_WITH_OBJECT
				additionalChecksPassed = false
			end
		end
		if self.sculptingOperation == Landscaping.OPERATION.FOLIAGE then
			self:onSculptingApplied(updatedErrorCode, displacedVolumeOrArea, nil)
			return
		elseif additionalChecksPassed and not self.validateOnly then
			self.terrainDeformationQueue:queueJob(self.currentTerrainDeformation, false, "onSculptingApplied", self)
			return
		else
			self:onSculptingApplied(updatedErrorCode, displacedVolumeOrArea, nil)
			return
		end
	end
	self.currentTerrainDeformation:cancel()
	self:onSculptingApplied(errorCode, 0, nil)
end
function Landscaping:onSculptingApplied(errorCode, displacedVolumeOrArea, _)
	if errorCode == TerrainDeformation.STATE_SUCCESS and not self.validateOnly then
		local cost = self:getCost(displacedVolumeOrArea)
		local farm = g_farmManager:getFarmByUserId(self.userId)
		farm:changeBalance(-cost, MoneyType.SHOP_PROPERTY_BUY)
		if self.sculptingOperation ~= Landscaping.OPERATION.FOLIAGE then
			local minX = math.huge
			local maxX = -math.huge
			local minZ = math.huge
			local maxZ = -math.huge
			for _, area in pairs(self.modifiedAreas) do
				local x, z, x1, z1, x2, z2 = unpack(area)
				if self.sculptingOperation ~= Landscaping.OPERATION.SMOOTH then
					FSDensityMapUtil.removeFieldArea(x, z, x1, z1, x2, z2, false)
					FSDensityMapUtil.removeWeedArea(x, z, x1, z1, x2, z2)
					FSDensityMapUtil.removeStoneArea(x, z, x1, z1, x2, z2)
				end
				FSDensityMapUtil.eraseTireTrack(x, z, x1, z1, x2, z2)
				DensityMapHeightUtil.clearArea(x, z, x1, z1, x2, z2)
				if self.sculptingOperation == Landscaping.OPERATION.PAINT then
					FSDensityMapUtil.clearDecoArea(x, z, x1, z1, x2, z2)
				end
				minX = math.min(minX, x, x1, x2, x2 + (x1 - x))
				maxX = math.max(maxX, x, x1, x2, x2 + (x1 - x))
				minZ = math.min(minZ, z, z1, z2, z2 + (z1 - z))
				maxZ = math.max(maxZ, z, z1, z2, z2 + (z1 - z))
			end
			g_currentMission.aiSystem:setAreaDirty(minX, maxX, minZ, maxZ)
		end
	end
	if self.callbackFunctionTarget ~= nil then
		self.callbackFunction(self.callbackFunctionTarget, errorCode, displacedVolumeOrArea)
	else
		self.callbackFunction(errorCode, displacedVolumeOrArea)
	end
	self.currentTerrainDeformation:delete()
	self.currentTerrainDeformation = nil
end
function Landscaping:getCost(displacedVolumeOrArea)
	local cost = 0
	if self.sculptingOperation == Landscaping.OPERATION.PAINT then
		cost = displacedVolumeOrArea * Landscaping.PAINT_BASE_COST_PER_M2
		return cost
	elseif self.sculptingOperation == Landscaping.OPERATION.FOLIAGE then
		cost = displacedVolumeOrArea * Landscaping.FOLIAGE_BASE_COST_PER_M2
		return cost
	else
		cost = displacedVolumeOrArea * Landscaping.SCULPT_BASE_COST_PER_M3
		return cost
	end
end
function Landscaping.isModificationAreaOnOwnedLand(x, z, radius, farmId)
	return g_farmlandManager:getIsOwnedByFarmAtWorldPosition(farmId, x - radius, z - radius) and g_farmlandManager:getIsOwnedByFarmAtWorldPosition(farmId, x - radius, z + radius) and g_farmlandManager:getIsOwnedByFarmAtWorldPosition(farmId, x + radius, z - radius) and g_farmlandManager:getIsOwnedByFarmAtWorldPosition(farmId, x + radius, z + radius)
end
function Landscaping:isModificationAreaPlacementBlocked(x, z, radius)
	local sx = nil
	local sz = nil
	local wx = nil
	local wz = nil
	local hx = nil
	local hz = nil
	if self.brushShape == Landscaping.BRUSH_SHAPE.CIRCLE then
		sx = x - radius
		sz = z
		wx = x
		wz = z - radius
		hx = x
		hz = z + radius
	else
		sx = x - radius
		sz = z - radius
		wx = x + radius
		wz = z - radius
		hx = x - radius
		hz = z + radius
	end
	local isBlocked = g_densityMapHeightManager:getIsPlacementAreaBlocked(sx, sz, wx, wz, hx, hz)
	return isBlocked
end
