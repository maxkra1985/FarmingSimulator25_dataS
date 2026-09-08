-- Local values: WildlifeHotspot_mt
WildlifeHotspot = {}
local WildlifeHotspot_mt = Class(WildlifeHotspot)
WildlifeHotspot.MAXIMUM_INSTANCES_PER_HOTSPOT = 2
WildlifeHotspot.MAXIMUM_LIFESPAN = 10
WildlifeHotspot.HOTSPOT_TYPE_ENUM = {
	["FIELD_SEEDS"] = 0,
	["DUMPED_GRAINS"] = 1
}

-- Upvalues: WildlifeHotspot_mt
-- Local values: self
function WildlifeHotspot.new(wildlifeManager)
	-- upvalues: (copy) WildlifeHotspot_mt
	local v3_ = WildlifeHotspot_mt
	local v4_ = setmetatable({}, v3_)
	v4_.wildlifeManager = wildlifeManager
	v4_.worldX = 0
	v4_.worldY = -200
	v4_.worldZ = 0
	v4_.radius = 0
	v4_.hotspotType = WildlifeHotspot.HOTSPOT_TYPE_ENUM.FIELD_SEEDS
	v4_.attractedSpecies = {}
	v4_.spawnedInstanceCount = 0
	v4_.timeOfCreation = g_time
	return v4_
end

-- Local values: _, species
function WildlifeHotspot:spawnAt(worldX, worldY, worldZ, radius, hotspotType)
	local v11_ = worldY or getTerrainHeightAtWorldPos(g_terrainNode, worldX, 0, worldZ)
	self.worldX = worldX
	self.worldY = v11_
	self.worldZ = worldZ
	self.radius = radius
	self.hotspotType = hotspotType
	self.timeOfCreation = g_time
	table.clear(self.attractedSpecies)
	for _, v12_ in pairs(self.wildlifeManager.species) do
		if v12_.hotspotType == self.hotspotType then
			local v13_ = self.attractedSpecies
			table.insert(v13_, v12_)
		end
	end
	if #self.attractedSpecies <= 0 then
		return false
	end
	self.spawnedInstanceCount = 0
	return true
end

-- Local values: randomAngle, randomDistance, randomX, randomZ, worldY
function WildlifeHotspot:calculateRandomTargetInRadius()
	local v15_ = MathUtil.randomFloat(-3.141592653589793, 3.141592653589793)
	local v16_ = MathUtil.randomFloat(0, self.radius)
	local v17_ = self.worldX + math.cos(v15_) * v16_
	local v18_ = self.worldZ + math.sin(v15_) * v16_
	return v17_, getTerrainHeightAtWorldPos(g_terrainNode, v17_, 0, v18_), v18_
end

-- Local values: spawnX, spawnZ, spawnY
function WildlifeHotspot:calculateRandomSpawnPositionForSpecies(species)
	local v20_, v21_ = self.wildlifeManager:calculateRandomSpawnPositionAroundPlayer(g_localPlayer)
	return v20_, getTerrainHeightAtWorldPos(g_terrainNode, v20_, 0, v21_), v21_
end

-- Local values: species, spawnX, spawnY, spawnZ, mainInstance, group, targetX, targetY, targetZ, _, instance, targetX, targetY, targetZ
function WildlifeHotspot:trySpawnInstances()
	if self.spawnedInstanceCount >= WildlifeHotspot.MAXIMUM_INSTANCES_PER_HOTSPOT then
		return
	else
		local v23_ = table.getRandomElement(self.attractedSpecies)
		local v24_, v25_, v26_ = self:calculateRandomSpawnPositionForSpecies(v23_)
		local v27_, v28_ = self.wildlifeManager:spawnInstanceAt(v24_, v25_, v26_, v23_, false, true, v23_.hotspotReuseTime)
		if v27_ == nil then
			return
		elseif v28_ then
			self.spawnedInstanceCount = self.spawnedInstanceCount + #v28_
			for _, v29_ in pairs(v28_) do
				local v30_, v31_, v32_ = self:calculateRandomTargetInRadius()
				v29_.mover:flyOrMoveToTarget(v30_, v31_, v32_, nil, false)
			end
		else
			self.spawnedInstanceCount = self.spawnedInstanceCount + 1
			local v33_, v34_, v35_ = self:calculateRandomTargetInRadius()
			v27_.mover:flyOrMoveToTarget(v33_, v34_, v35_)
		end
	end
end
