-- Local values: WildlifeSpeciesCrow_mt
WildlifeSpeciesCrow = {}
local WildlifeSpeciesCrow_mt = Class(WildlifeSpeciesCrow, WildlifeSpeciesSimple)
g_xmlManager:addInitSchemaFunction(function()
	local _ = WildlifeSpecies.xmlSchema
end)

-- Upvalues: WildlifeSpeciesCrow_mt
-- Local values: self
function WildlifeSpeciesCrow.new(customMt)
	-- upvalues: (copy) WildlifeSpeciesCrow_mt
	local v3_ = WildlifeSpeciesSimple.new(customMt or WildlifeSpeciesCrow_mt)
	v3_.spawnCallbackFunc = nil
	v3_.nonFieldSpawnChange = 0.1
	v3_.maxNumExtraInstances = 2
	v3_.flyByChance = 0.8
	v3_.maxNumExtraInstancesFlyBy = 5
	v3_.minSpawnDistanceRadiusFlyBy = 70
	v3_.maxSpawnDistanceRadiusFlyBy = 100
	v3_.spawnTimerThreshold = 7000
	v3_.spawnTimer = v3_.spawnTimerThreshold
	v3_.groupMinRadius = 0.5
	v3_.groupMaxRadius = 10
	return v3_
end

function WildlifeSpeciesCrow:trySpawnAt(playerX, playerZ, playerRotY, cameraFovY, callbackFunc)
	if WildlifeSpeciesCrow:superClass().trySpawnAt(self, playerX, playerZ, playerRotY, cameraFovY, callbackFunc) then
		return self:spawn(playerX, playerZ, playerRotY, cameraFovY)
	else
		return false
	end
end

-- Local values: spawnDistance, x, z, terrainY, isOnField, fruitIndex, growthState, waterLevel, fruitTypeDesc
function WildlifeSpeciesCrow:spawn(playerX, playerZ, playerRotY, cameraFovY)
	local v15_ = MathUtil.randomFloat(self.spawnRadiusMin, self.spawnRadiusMax)
	local v16_, v17_ = WildlifeUtil.calculateRandomSpawnPosition(playerX, playerZ, playerRotY, cameraFovY, v15_)
	local v18_ = getTerrainHeightAtWorldPos(g_terrainNode, v16_, 0, v17_)
	if FSDensityMapUtil.getIsFieldAtWorldPos(v16_, v17_) then
		local v19_, v20_ = FSDensityMapUtil.getFruitTypeIndexAtWorldPos(v16_, v17_)
		if v19_ ~= nil then
			if g_currentMission.fieldGroundSystem:getValueAtWorldPos(FieldDensityMap.WATER_LEVEL, v16_, 0, v17_) > 0 then
				self:finishSpawning(false)
				return false
			else
				local v21_ = g_fruitTypeManager:getFruitTypeByIndex(v19_)
				if v21_ == nil then
					self:finishSpawning(false)
					return false
				elseif v21_:getIsCut(v20_) and math.random() < 0.6 then
					self:spawnInstances(v16_, v18_, v17_, math.random(1, self.maxNumExtraInstances), nil, nil, nil)
					return true
				elseif v21_:getIsWeedable(v20_) and math.random() < 0.6 then
					self:spawnInstances(v16_, v18_, v17_, math.random(1, self.maxNumExtraInstances), nil, nil, nil)
					return true
				else
					self:finishSpawning(false)
					return false
				end
			end
		end
	end
	if math.random() > self.nonFieldSpawnChange then
		self:finishSpawning(false)
		return false
	else
		raycastClosestAsync(v16_, v18_ + 100, v17_, 0, -1, 0, 200, "onSpawnYCallback", self, CollisionFlag.TERRAIN + CollisionFlag.ROAD + CollisionFlag.WATER)
		return true
	end
end

-- Local values: transformCollisionGroup, isRoad, isWater, isObject
function WildlifeSpeciesCrow:onSpawnYCallback(nodeId, x, y, z, distance, nx, ny, nz, subShapeIndex, shapeId, isLast)
	if nodeId == nil or nodeId == 0 then
		self:finishSpawning(false)
		return
	else
		local v27_ = getCollisionFilterGroup(nodeId)
		local v28_ = CollisionFlag.getHasGroupFlagSet(nodeId, CollisionFlag.ROAD)
		if v28_ then
			v28_ = nodeId ~= g_terrainNode
		end
		if v28_ then
			self:finishSpawning(false)
			return
		elseif CollisionFlag.getHasGroupFlagSet(nodeId, CollisionFlag.WATER) then
			self:finishSpawning(false)
			return
		else
			local v29_ = CollisionFlag.TERRAIN
			local v30_ = bit32.band(v27_, v29_) == 0
			if self.canSpawnOnObjects or not v30_ then
				self:spawnInstances(x, y, z, math.random(1, self.maxNumExtraInstances), nodeId, nil, nil)
			else
				self:finishSpawning(false)
			end
		end
	end
end

-- Local values: i, instance, angle, radius
function WildlifeSpeciesCrow:spawnInstances(x, y, z, numInstances, nodeId, dirX, dirZ)
	for v38_ = 1, numInstances do
		local v39_ = self:createInstance()
		local v40_ = v38_ * (6.283185307179586 / numInstances)
		local v41_ = MathUtil.lerp(self.groupMinRadius, self.groupMaxRadius, math.random())
		x = x + math.cos(v40_) * v41_
		z = z + math.sin(v40_) * v41_
		v39_:spawnAt(x, y, z)
		if dirX ~= nil and dirZ ~= nil then
			v39_.stateMachine.states.flee:fleeToDespawn(dirX, dirZ, false)
			v39_.mover.overiddenSpeed = nil
			v39_.mover:randomiseCurrentSpeed()
		end
	end
	self:finishSpawning(true)
end

function WildlifeSpeciesCrow:debugSpawn(x, y, z, numInstances)
	WildlifeSpeciesCrow:superClass().debugSpawn(self, x, y, z, numInstances)
	self:spawnInstances(x, y, z, numInstances, nil, nil, nil)
end
