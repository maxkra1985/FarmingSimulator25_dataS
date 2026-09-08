-- Local values: BoatyardActivatable_mt
BoatyardActivatable = {}
local BoatyardActivatable_mt = Class(BoatyardActivatable)

-- Upvalues: BoatyardActivatable_mt
-- Local values: self
function BoatyardActivatable.new(boatyard)
	-- upvalues: (copy) BoatyardActivatable_mt
	local v3_ = BoatyardActivatable_mt
	local v4_ = setmetatable({}, v3_)
	v4_.boatyard = boatyard
	v4_.activateText = string.format(g_i18n:getText("action_buyOBJECT"), v4_.boatyard:getName())
	return v4_
end

-- Local values: ownerFarmId
function BoatyardActivatable:getIsActivatable()
	return self.boatyard:getOwnerFarmId() == AccessHandler.EVERYONE
end

-- Local values: ownerFarmId
function BoatyardActivatable:run()
	if self.boatyard:getOwnerFarmId() == AccessHandler.EVERYONE then
		self.boatyard:buyRequest()
	end
end
