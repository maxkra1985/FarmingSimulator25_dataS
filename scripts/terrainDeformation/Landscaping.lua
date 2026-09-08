-- Local values: Landscaping_mt, NO_CALLBACK, SQRT_2_DIV_FACTOR
Landscaping = {}
local Landscaping_mt = Class(Landscaping)
Landscaping.BRUSH_SHAPE_NUM_SEND_BITS = 2
Landscaping.OPERATION_NUM_SEND_BITS = 3
Landscaping.BRUSH_SHAPE = {
	["SQUARE"] = 1,
	["CIRCLE"] = 2
}
Landscaping.OPERATION = {
	["RAISE"] = 1,
	["LOWER"] = 2,
	["SMOOTH"] = 3,
	["FLATTEN"] = 4,
	["PAINT"] = 5,
	["FOLIAGE"] = 6,
	["SLOPE"] = 7
}
Landscaping.OPERATION_HEIGHT_CHANGE_FACTOR_MAP = {
	[Landscaping.OPERATION.RAISE] = 1,
	[Landscaping.OPERATION.LOWER] = -1,
	[Landscaping.OPERATION.SMOOTH] = 0,
	[Landscaping.OPERATION.FLATTEN] = 0,
	[Landscaping.OPERATION.PAINT] = 0,
	[Landscaping.OPERATION.FOLIAGE] = 0,
	[Landscaping.OPERATION.SLOPE] = 1
}
Landscaping.SCULPT_BASE_COST_PER_M3 = 10
Landscaping.PAINT_BASE_COST_PER_M2 = 1
Landscaping.FOLIAGE_BASE_COST_PER_M2 = 0.2
local function NO_CALLBACK() end
local SQRT_2_DIV_FACTOR = 0.7071067811865475

-- Upvalues: Landscaping_mt, NO_CALLBACK
-- Local values: self
function Landscaping.new(terrainDeformationQueue, placementCollisionMap, userId, validateOnly, callbackFunction, callbackFunctionTarget)
	-- upvalues: (copy) Landscaping_mt, (copy) NO_CALLBACK
	local v10_ = Landscaping_mt
	local v11_ = setmetatable({}, v10_)
	v11_.terrainDeformationQueue = terrainDeformationQueue
	v11_.placementCollisionMap = placementCollisionMap
	v11_.userId = userId
	v11_.validateOnly = validateOnly
	v11_.callbackFunction = callbackFunction or NO_CALLBACK
	v11_.callbackFunctionTarget = callbackFunctionTarget
	v11_.terrainUnit = getTerrainHeightmapUnitSize(g_terrainNode)
	v11_.halfTerrainUnit = v11_.terrainUnit / 2
	v11_.targetPositionX = nil
	v11_.targetPositionY = nil
	v11_.targetPositionZ = nil
	v11_.radius = 0
	v11_.brushShape = Landscaping.BRUSH_SHAPE.SQUARE
	v11_.smoothingDistance = 0
	v11_.sculptingOperation = Landscaping.OPERATION.RAISE
	v11_.modifiedAreas = {}
	return v11_
end

function Landscaping:delete() end

-- Local values: numOverlaps
function Landscaping:hasObjectOverlapInModificationArea(x, y, z)
	return overlapCylinder(x, y, z, self.radius + 0.5, 10, Axis.Y, "", nil, CollisionFlag.PLAYER, true, false, false, false) > 0
end

-- Upvalues: SQRT_2_DIV_FACTOR
-- Local values: size, ox, xStart, xEnd, zOffset1, zOffset2, zOffset
function Landscaping:addModifiedCircleArea(x, z, radius)
	-- upvalues: (copy) SQRT_2_DIV_FACTOR
	if radius < self.terrainUnit + self.halfTerrainUnit then
		self:addModifiedSquareArea(x, z, radius * 2 * 0.7071067811865475)
	else
		for v20_ = -radius / self.terrainUnit, radius / self.terrainUnit - 1 do
			local v21_ = v20_ * self.terrainUnit
			local v22_ = v20_ * self.terrainUnit + self.terrainUnit
			local v23_ = math.abs(v21_) / radius
			local v24_ = math.acos(v23_)
			local v25_ = math.sin(v24_) * radius
			local v26_ = math.abs(v22_) / radius
			local v27_ = math.acos(v26_)
			local v28_ = math.sin(v27_) * radius
			local v29_ = math.min(v25_, v28_) - 0.02
			local v30_ = self.modifiedAreas
			local v31_ = {
				x + v21_,
				z - v29_,
				x + v22_,
				z - v29_,
				x + v21_,
				z + v29_
			}
			table.insert(v30_, v31_)
		end
	end
end

-- Local values: halfSide
function Landscaping:addModifiedSquareArea(x, z, side)
	local v36_ = side * 0.5
	local v37_ = self.modifiedAreas
	local v38_ = {
		x - v36_,
		z - v36_,
		x + v36_,
		z - v36_,
		x - v36_,
		z + v36_
	}
	table.insert(v37_, v38_)
end

-- Local values: hardness
function Landscaping:assignSmoothingParameters(deform, x, z, radius, strength, brushShape)
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

-- Local values: hardness
function Landscaping:assignSculptingParameters(deform, x, y, z, nx, ny, nz, d, minY, maxY, radius, strength, brushShape, operation, smoothingDistance)
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

-- Local values: deform, displacedFoliageArea, farm, foliageSystem, unit, ox, xStart, xEnd, zOffset1, zOffset2, zOffset, x0, z0, x1, z1, x2, z2
function Landscaping:sculpt(x, y, z, nx, ny, nz, d, minY, maxY, radius, strength, brushShape, operation, smoothingDistance, terrainPaintingLayer, terrainFoliageLayer, terrainFoliageValue)
	local v86_ = TerrainDeformation.new(g_terrainNode)
	self.currentTerrainDeformation = v86_
	self.targetPositionX = x
	self.targetPositionY = y
	self.targetPositionZ = z
	self.radius = radius
	self.brushShape = brushShape
	local v87_ = self.terrainUnit
	self.smoothingDistance = math.max(smoothingDistance, v87_)
	self.sculptingOperation = operation
	local v88_ = 0
	if operation == Landscaping.OPERATION.SMOOTH then
		self:assignSmoothingParameters(v86_, x, z, radius, strength, brushShape)
	elseif operation == Landscaping.OPERATION.PAINT then
		self:assignPaintingParameters(v86_, x, z, radius, brushShape, terrainPaintingLayer)
	elseif operation == Landscaping.OPERATION.FOLIAGE then
		if g_farmManager:getFarmByUserId(self.userId):getBalance() < Landscaping.FOLIAGE_BASE_COST_PER_M2 then
			self:onSculptingValidated(TerrainDeformation.STATE_FAILED_NOT_ENOUGH_MONEY, 0, false)
			return
		end
		local v89_ = g_currentMission.foliageSystem
		if brushShape == Landscaping.BRUSH_SHAPE.CIRCLE and radius >= 1 then
			for v90_ = -radius / 0.5, radius / 0.5 - 1 do
				local v91_ = v90_ * 0.5
				local v92_ = v90_ * 0.5 + 0.5
				local v93_ = math.abs(v91_) / radius
				local v94_ = math.acos(v93_)
				local v95_ = math.sin(v94_) * radius
				local v96_ = math.abs(v92_) / radius
				local v97_ = math.acos(v96_)
				local v98_ = math.sin(v97_) * radius
				local v99_ = math.min(v95_, v98_) - 0.02
				v88_ = v88_ + v89_:apply(v89_:getFoliagePaint(terrainFoliageLayer), x + v91_, z - v99_, x + v92_, z - v99_, x + v91_, z + v99_, terrainFoliageValue)
			end
		else
			if brushShape == Landscaping.BRUSH_SHAPE.CIRCLE then
				radius = radius / 2
			end
			local v100_ = x - radius
			local v101_ = z - radius
			local v102_ = x - radius
			local v103_ = z + radius
			local v104_ = x + radius
			local v105_ = z - radius
			v88_ = v89_:apply(v89_:getFoliagePaint(terrainFoliageLayer), v100_, v101_, v102_, v103_, v104_, v105_, terrainFoliageValue)
		end
	else
		self:assignSculptingParameters(v86_, x, y, z, nx, ny, nz, d, minY, maxY, radius, strength, brushShape, operation, self.smoothingDistance)
	end
	if operation ~= Landscaping.OPERATION.PAINT and operation ~= Landscaping.OPERATION.FOLIAGE then
		v86_:setBlockedAreaMaxDisplacement(0.01)
		v86_:setDynamicObjectCollisionMask(CollisionMask.LANDSCAPING)
		v86_:setDynamicObjectMaxDisplacement(0.03)
		if self.placementCollisionMap ~= nil then
			v86_:setBlockedAreaMap(self.placementCollisionMap, 0)
		end
	end
	if operation == Landscaping.OPERATION.FOLIAGE then
		self:onSculptingValidated(TerrainDeformation.STATE_SUCCESS, v88_, false)
		return
	elseif (operation == Landscaping.OPERATION.SMOOTH or operation == Landscaping.OPERATION.PAINT) and not self.validateOnly then
		v86_:apply(true, "onSculptingValidated", self)
	else
		self.terrainDeformationQueue:queueJob(v86_, true, "onSculptingValidated", self)
	end
end

-- Local values: additionalChecksPassed, updatedErrorCode, farm, ownsTargetLand, dynamicObjectBlocking
function Landscaping:onSculptingValidated(errorCode, displacedVolumeOrArea, blocked)
	if errorCode == TerrainDeformation.STATE_SUCCESS then
		local v109_ = g_farmManager:getFarmByUserId(self.userId)
		local v110_
		if v109_:getBalance() < self:getCost(displacedVolumeOrArea) then
			errorCode = TerrainDeformation.STATE_FAILED_NOT_ENOUGH_MONEY
			v110_ = false
		else
			v110_ = true
		end
		if not Landscaping.isModificationAreaOnOwnedLand(self.targetPositionX, self.targetPositionZ, self.radius + self.smoothingDistance, v109_:getId()) then
			errorCode = TerrainDeformation.STATE_FAILED_NOT_OWNED
			v110_ = false
		end
		if self.sculptingOperation ~= Landscaping.OPERATION.PAINT and self.sculptingOperation ~= Landscaping.OPERATION.FOLIAGE then
			if self:isModificationAreaPlacementBlocked(self.targetPositionX, self.targetPositionZ, self.radius) then
				errorCode = TerrainDeformation.STATE_FAILED_BLOCKED
				v110_ = false
			end
			if self:hasObjectOverlapInModificationArea(self.targetPositionX, self.targetPositionY, self.targetPositionZ) then
				errorCode = TerrainDeformation.STATE_FAILED_COLLIDE_WITH_OBJECT
				v110_ = false
			end
		end
		if self.sculptingOperation == Landscaping.OPERATION.FOLIAGE then
			self:onSculptingApplied(errorCode, displacedVolumeOrArea, nil)
			return
		elseif v110_ and not self.validateOnly then
			self.terrainDeformationQueue:queueJob(self.currentTerrainDeformation, false, "onSculptingApplied", self)
		else
			self:onSculptingApplied(errorCode, displacedVolumeOrArea, nil)
		end
	else
		self.currentTerrainDeformation:cancel()
		self:onSculptingApplied(errorCode, 0, nil)
		return
	end
end

-- Local values: cost, farm, minX, maxX, minZ, maxZ, _, area, x, z, x1, z1, x2, z2
function Landscaping:onSculptingApplied(errorCode, displacedVolumeOrArea, _)
	if errorCode == TerrainDeformation.STATE_SUCCESS and not self.validateOnly then
		local v114_ = self:getCost(displacedVolumeOrArea)
		g_farmManager:getFarmByUserId(self.userId):changeBalance(-v114_, MoneyType.SHOP_PROPERTY_BUY)
		if self.sculptingOperation ~= Landscaping.OPERATION.FOLIAGE then
			local v115_ = math.huge
			local v116_ = -math.huge
			local v117_ = math.huge
			local v118_ = -math.huge
			for _, v119_ in pairs(self.modifiedAreas) do
				local v120_, v121_, v122_, v123_, v124_, v125_ = unpack(v119_)
				if self.sculptingOperation ~= Landscaping.OPERATION.SMOOTH then
					FSDensityMapUtil.removeFieldArea(v120_, v121_, v122_, v123_, v124_, v125_, false)
					FSDensityMapUtil.removeWeedArea(v120_, v121_, v122_, v123_, v124_, v125_)
					FSDensityMapUtil.removeStoneArea(v120_, v121_, v122_, v123_, v124_, v125_)
				end
				FSDensityMapUtil.eraseTireTrack(v120_, v121_, v122_, v123_, v124_, v125_)
				DensityMapHeightUtil.clearArea(v120_, v121_, v122_, v123_, v124_, v125_)
				if self.sculptingOperation == Landscaping.OPERATION.PAINT then
					FSDensityMapUtil.clearDecoArea(v120_, v121_, v122_, v123_, v124_, v125_)
				end
				local v126_ = v124_ + (v122_ - v120_)
				v115_ = math.min(v115_, v120_, v122_, v124_, v126_)
				local v127_ = v124_ + (v122_ - v120_)
				v116_ = math.max(v116_, v120_, v122_, v124_, v127_)
				local v128_ = v125_ + (v123_ - v121_)
				v117_ = math.min(v117_, v121_, v123_, v125_, v128_)
				local v129_ = v125_ + (v123_ - v121_)
				v118_ = math.max(v118_, v121_, v123_, v125_, v129_)
			end
			g_currentMission.aiSystem:setAreaDirty(v115_, v116_, v117_, v118_)
		end
	end
	if self.callbackFunctionTarget == nil then
		self.callbackFunction(errorCode, displacedVolumeOrArea)
	else
		self.callbackFunction(self.callbackFunctionTarget, errorCode, displacedVolumeOrArea)
	end
	self.currentTerrainDeformation:delete()
	self.currentTerrainDeformation = nil
end

-- Local values: cost
function Landscaping:getCost(displacedVolumeOrArea)
	if self.sculptingOperation == Landscaping.OPERATION.PAINT then
		return displacedVolumeOrArea * Landscaping.PAINT_BASE_COST_PER_M2
	elseif self.sculptingOperation == Landscaping.OPERATION.FOLIAGE then
		return displacedVolumeOrArea * Landscaping.FOLIAGE_BASE_COST_PER_M2
	else
		return displacedVolumeOrArea * Landscaping.SCULPT_BASE_COST_PER_M3
	end
end

function Landscaping.isModificationAreaOnOwnedLand(x, z, radius, farmId)
	local v136_ = g_farmlandManager:getIsOwnedByFarmAtWorldPosition(farmId, x - radius, z - radius) and (g_farmlandManager:getIsOwnedByFarmAtWorldPosition(farmId, x - radius, z + radius) and g_farmlandManager:getIsOwnedByFarmAtWorldPosition(farmId, x + radius, z - radius))
	if v136_ then
		v136_ = g_farmlandManager:getIsOwnedByFarmAtWorldPosition(farmId, x + radius, z + radius)
	end
	return v136_
end
function Landscaping.isModificationAreaPlacementBlocked(p137_, p138_, p139_, p140_)
	local v141_, v142_, v143_, v144_, v145_
	if p137_.brushShape == Landscaping.BRUSH_SHAPE.CIRCLE then
		v141_ = p138_ - p140_
		v142_ = p139_ - p140_
		v143_ = p139_ + p140_
		v144_ = p138_
		v145_ = p139_
	else
		v141_ = p138_ - p140_
		v145_ = p139_ - p140_
		v144_ = p138_ + p140_
		v142_ = p139_ - p140_
		p138_ = p138_ - p140_
		v143_ = p139_ + p140_
	end
	return g_densityMapHeightManager:getIsPlacementAreaBlocked(v141_, v145_, v144_, v142_, p138_, v143_)
end
