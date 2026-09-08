-- Local values: WildlifeAnimal_mt
WildlifeAnimal = {}
local WildlifeAnimal_mt = Class(WildlifeAnimal)

-- Upvalues: WildlifeAnimal_mt
-- Local values: self
function WildlifeAnimal.new(customMt)
	-- upvalues: (copy) WildlifeAnimal_mt
	local v3_ = customMt or WildlifeAnimal_mt
	local v4_ = setmetatable({}, v3_)
	v4_.rootNode = createTransformGroup("WildlifeAnimal")
	link(getRootNode(), v4_.rootNode)
	return v4_
end

function WildlifeAnimal:delete()
	delete(self.rootNode)
end

-- Local values: x, _, z
function WildlifeAnimal:calculateDistanceFrom(positionX, positionZ)
	local v9_, _, v10_ = getWorldTranslation(self.rootNode)
	return MathUtil.vector2Length(positionX - v9_, positionZ - v10_)
end

function WildlifeAnimal:spawnAt(x, y, z)
	setWorldTranslation(self.rootNode, x, y, z)
	setVisibility(self.rootNode, true)
end

function WildlifeAnimal:despawn()
	setVisibility(self.rootNode, false)
end

function WildlifeAnimal:update(dt) end

function WildlifeAnimal:drawDebug() end
