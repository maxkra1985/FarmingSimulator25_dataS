-- Local values: BuyBuildingActivatable_mt
BuyBuildingActivatable = {}
local BuyBuildingActivatable_mt = Class(BuyBuildingActivatable)

-- Upvalues: BuyBuildingActivatable_mt
-- Local values: self
function BuyBuildingActivatable.new(placeable)
	-- upvalues: (copy) BuyBuildingActivatable_mt
	local v3_ = BuyBuildingActivatable_mt
	local v4_ = setmetatable({}, v3_)
	v4_.placeable = placeable
	v4_.activateText = g_i18n:getText("action_buyBuilding")
	return v4_
end

function BuyBuildingActivatable:getIsActivatable()
	return g_currentMission.accessHandler:canFarmAccess(g_currentMission:getFarmId(), self.placeable)
end

-- Local values: ownerFarmId
function BuyBuildingActivatable:run()
	if self.placeable:getOwnerFarmId() == AccessHandler.EVERYONE then
		self.placeable:buyRequest()
	end
end

-- Local values: triggerNode, tx, ty, tz
function BuyBuildingActivatable:getDistance(x, y, z)
	local v11_ = self.placeable.spec_buyable.triggerNode
	if v11_ == nil then
		return math.huge
	end
	local v12_, v13_, v14_ = getWorldTranslation(v11_)
	return MathUtil.vector3Length(x - v12_, y - v13_, z - v14_)
end
