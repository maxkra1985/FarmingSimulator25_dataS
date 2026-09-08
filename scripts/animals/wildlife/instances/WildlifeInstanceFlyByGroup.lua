-- Local values: WildlifeInstanceFlyByGroup_mt
WildlifeInstanceFlyByGroup = {}
local WildlifeInstanceFlyByGroup_mt = Class(WildlifeInstanceFlyByGroup, WildlifeInstance)

-- Upvalues: WildlifeInstanceFlyByGroup_mt
-- Local values: self
function WildlifeInstanceFlyByGroup.new(species, customMt)
	-- upvalues: (copy) WildlifeInstanceFlyByGroup_mt
	local v4_ = WildlifeInstance.new(species, customMt or WildlifeInstanceFlyByGroup_mt)
	v4_.pooledAnimals = ObjectPool.new(WildlifeAnimalFlyBy.new, species)
	v4_.animals = {}
	v4_.numAnimals = 0
	v4_.flyDirectionX = 0
	v4_.flyDirectionZ = 1
	v4_.groupMinRadius = 0.5
	v4_.groupMaxRadius = 10
	return v4_
end

-- Local values: _, animal, _, animal
function WildlifeInstanceFlyByGroup:delete()
	for _, v6_ in ipairs(self.animals) do
		self.pooledAnimals:returnToPool(v6_)
	end
	table.clear(self.animals)
	for _, v7_ in pairs(self.pooledAnimals.pool) do
		v7_:delete()
	end
	WildlifeInstanceFlyByGroup:superClass().delete(self)
end

function WildlifeInstanceFlyByGroup:getNumAnimals()
	return self.numAnimals
end

function WildlifeInstanceFlyByGroup:setNumAnimals(numAnimals)
	self.numAnimals = numAnimals
end

function WildlifeInstanceFlyByGroup:calculateDistanceFrom(positionX, positionZ)
	return #self.animals == 0 and math.huge or self.animals[1]:calculateDistanceFrom(positionX, positionZ)
end

-- Local values: _, animal
function WildlifeInstanceFlyByGroup:setFlyDirection(directionX, directionZ)
	self.flyDirectionX = directionX
	self.flyDirectionZ = directionZ
	for _, v17_ in ipairs(self.animals) do
		v17_:setFlyDirection(directionX, directionZ)
	end
end

function WildlifeInstanceFlyByGroup:setGroupRadius(minRadius, maxRadius)
	self.groupMinRadius = minRadius
	self.groupMaxRadius = maxRadius
end

-- Local values: animal, offsetAngle, numExtraAnimals, i, sectionAngle, offset, angle, radius, x1, z2
function WildlifeInstanceFlyByGroup:spawnAt(x, y, z)
	WildlifeInstanceFlyByGroup:superClass().spawnAt(self, x, y, z)
	local v25_ = self.pooledAnimals:getOrCreateNext()
	v25_:setFlyDirection(self.flyDirectionX, self.flyDirectionZ)
	v25_:spawnAt(x, y, z)
	table.addElement(self.animals, v25_)
	local v26_ = MathUtil.getYRotationFromDirection(self.flyDirectionX, self.flyDirectionZ) * 3.141592653589793 * 0.5
	local v27_ = self.numAnimals - 1
	for v28_ = 1, v27_ do
		local v29_ = 6.283185307179586 / v27_
		local v30_ = v26_ + v29_ * MathUtil.lerp(0.1, 0.9, math.random())
		local v31_ = (v28_ - 1) * v29_ + v30_
		local v32_ = MathUtil.lerp(self.groupMinRadius, self.groupMaxRadius, math.random())
		local v33_ = x + math.cos(v31_) * v32_
		local v34_ = z + math.sin(v31_) * v32_
		local v35_ = self.pooledAnimals:getOrCreateNext()
		v35_:setFlyDirection(self.flyDirectionX, self.flyDirectionZ)
		v35_:spawnAt(v33_, y, v34_)
		table.addElement(self.animals, v35_)
	end
end

-- Local values: _, animal
function WildlifeInstanceFlyByGroup:despawn()
	for _, v37_ in ipairs(self.animals) do
		v37_:despawn()
		self.pooledAnimals:returnToPool(v37_)
	end
	table.clear(self.animals)
	WildlifeInstanceFlyByGroup:superClass().despawn(self)
end

-- Local values: _, animal
function WildlifeInstanceFlyByGroup:update(dt)
	WildlifeInstanceFlyByGroup:superClass().update(dt)
	for _, v40_ in ipairs(self.animals) do
		v40_:update(dt)
	end
end

-- Local values: _, animal
function WildlifeInstanceFlyByGroup:drawDebug()
	for _, v42_ in ipairs(self.animals) do
		v42_:drawDebug()
	end
end
