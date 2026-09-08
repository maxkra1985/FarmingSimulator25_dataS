-- Local values: WildlifeAnimalFlyBy_mt
WildlifeAnimalFlyBy = {}
local WildlifeAnimalFlyBy_mt = Class(WildlifeAnimalFlyBy, WildlifeAnimal)

-- Upvalues: WildlifeAnimalFlyBy_mt
-- Local values: self
function WildlifeAnimalFlyBy.new(species, customMt)
	-- upvalues: (copy) WildlifeAnimalFlyBy_mt
	local v4_ = WildlifeAnimal.new(customMt or WildlifeAnimalFlyBy_mt)
	v4_.species = species
	v4_.flyDirectionX = 0
	v4_.flyDirectionZ = 1
	v4_.graphics = WildlifeInstanceGraphics.new(species.graphics)
	v4_.graphics:load(v4_.rootNode)
	return v4_
end

function WildlifeAnimalFlyBy:delete()
	self.graphics:delete()
	WildlifeAnimalFlyBy:superClass().delete(self)
end

function WildlifeAnimalFlyBy:setFlyDirection(directionX, directionZ)
	self.flyDirectionX = directionX
	self.flyDirectionZ = directionZ
	setWorldDirection(self.rootNode, directionX, 0, directionZ, 0, 1, 0)
end

function WildlifeAnimalFlyBy:spawnAt(x, y, z)
	WildlifeAnimalFlyBy:superClass().spawnAt(self, x, y, z)
	self.graphics:setAnimation("fly")
	self.graphics:setAnimationOffset(math.random())
end

-- Local values: species, x, y, z, movedDistance, groundY, targetHeight, delta
function WildlifeAnimalFlyBy:update(dt)
	WildlifeAnimalFlyBy:superClass().update(self, dt)
	local v15_ = self.species
	local v16_, v17_, v18_ = getWorldTranslation(self.rootNode)
	local v19_ = v15_.moveDistancePerMs * dt
	local v20_ = v16_ + self.flyDirectionX * v19_
	local v21_ = v18_ + self.flyDirectionZ * v19_
	local v22_ = getTerrainHeightAtWorldPos(g_terrainNode, v20_, 0, v21_) + v15_.minDistanceToGround
	local v23_
	if v22_ - v17_ > 0 then
		local v24_ = v17_ + v15_.climbPerMeter * v19_
		v23_ = math.min(v24_, v22_)
	else
		local v25_ = v17_ - v15_.fallPerMeter * v19_
		v23_ = math.max(v25_, v22_)
	end
	setWorldTranslation(self.rootNode, v20_, v23_, v21_)
	self.graphics:update(dt)
end

function WildlifeAnimalFlyBy:drawDebug()
	DebugText.renderAtNode(self.rootNode, string.format("%s\nnode:%d", self.species.name, self.rootNode), DebugUtil.getDebugColor(self.rootNode), 0.015)
end
