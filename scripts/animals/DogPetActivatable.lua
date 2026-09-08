-- Local values: DogPetActivatable_mt
DogPetActivatable = {}
local DogPetActivatable_mt = Class(DogPetActivatable)

-- Upvalues: DogPetActivatable_mt
-- Local values: self
function DogPetActivatable.new(dog)
	-- upvalues: (copy) DogPetActivatable_mt
	local v3_ = DogPetActivatable_mt
	local v4_ = setmetatable({}, v3_)
	v4_.dog = dog
	v4_.activateText = g_i18n:getText("action_petAnimal")
	return v4_
end

function DogPetActivatable:getIsActivatable()
	return true
end

-- Local values: distance
function DogPetActivatable:getDistance(posX, posY, posZ)
	return self.dog:getDistanceTo(posX, posY, posZ)
end

function DogPetActivatable:run()
	self.dog:pet()
end
