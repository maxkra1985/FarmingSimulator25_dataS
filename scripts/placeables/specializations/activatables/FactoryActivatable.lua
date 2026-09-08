-- Local values: FactoryActivatable_mt
FactoryActivatable = {}
local FactoryActivatable_mt = Class(FactoryActivatable)

-- Upvalues: FactoryActivatable_mt
-- Local values: self
function FactoryActivatable.new(factory)
	-- upvalues: (copy) FactoryActivatable_mt
	local v3_ = FactoryActivatable_mt
	local v4_ = setmetatable({}, v3_)
	v4_.factory = factory
	v4_.activateText = string.format(g_i18n:getText("action_buyOBJECT"), v4_.factory:getName())
	return v4_
end

-- Local values: ownerFarmId
function FactoryActivatable:getIsActivatable()
	return self.factory:getOwnerFarmId() == AccessHandler.EVERYONE
end

-- Local values: ownerFarmId
function FactoryActivatable:run()
	if self.factory:getOwnerFarmId() == AccessHandler.EVERYONE then
		self.factory:buyRequest()
	end
end
