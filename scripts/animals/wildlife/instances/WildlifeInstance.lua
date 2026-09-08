-- Local values: WildlifeInstance_mt
WildlifeInstance = {}
local WildlifeInstance_mt = Class(WildlifeInstance)

-- Upvalues: WildlifeInstance_mt
-- Local values: self
function WildlifeInstance.new(species, customMt)
	-- upvalues: (copy) WildlifeInstance_mt
	local v4_ = customMt or WildlifeInstance_mt
	local v5_ = setmetatable({}, v4_)
	v5_.species = species
	v5_.spawnedAtTimestamp = 0
	v5_.despawnTime = nil
	return v5_
end

function WildlifeInstance:delete() end

function WildlifeInstance:update(dt) end

function WildlifeInstance:drawDebug() end

function WildlifeInstance:getNumAnimals()
	return 1
end

function WildlifeInstance:spawnAt(x, y, z)
	self:setSpawnTimestampToNow()
	self:randomiseDespawnTime()
end

function WildlifeInstance:despawn() end

function WildlifeInstance:getSecondsSinceSpawn()
	return g_time * 0.001 - self.spawnedAtTimestamp
end

function WildlifeInstance:setSpawnTimestampToNow()
	self.spawnedAtTimestamp = g_time * 0.001
end

function WildlifeInstance:randomiseDespawnTime()
	if self.species.despawnTimeRange == nil then
		self.despawnTime = nil
	else
		self.despawnTime = MathUtil.randomFloat(self.species.despawnTimeRange.minimum, self.species.despawnTimeRange.maximum)
	end
end
