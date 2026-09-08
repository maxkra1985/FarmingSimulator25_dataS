-- Local values: ProductionPointActivatable_mt
ProductionPointActivatable = {}
local ProductionPointActivatable_mt = Class(ProductionPointActivatable)

-- Upvalues: ProductionPointActivatable_mt
-- Local values: self
function ProductionPointActivatable.new(productionPoint)
	-- upvalues: (copy) ProductionPointActivatable_mt
	local v3_ = ProductionPointActivatable_mt
	local v4_ = setmetatable({}, v3_)
	v4_.productionPoint = productionPoint
	v4_.mission = productionPoint.mission
	v4_:updateText()
	return v4_
end

function ProductionPointActivatable:updateText()
	if self.productionPoint.isOwned or not self.productionPoint.useInteractionTriggerForBuying then
		self.activateText = g_i18n:getText("action_manageProductionPoint")
	else
		self.activateText = g_i18n:getText("action_buyProductionPoint")
	end
end

function ProductionPointActivatable:getIsActivatable()
	return self.mission.accessHandler:canFarmAccess(self.mission:getFarmId(), self.productionPoint)
end

-- Local values: ownerFarmId
function ProductionPointActivatable:run()
	local v8_ = self.productionPoint:getOwnerFarmId()
	if v8_ == AccessHandler.EVERYONE and self.productionPoint.useInteractionTriggerForBuying then
		self.productionPoint:buyRequest()
	elseif v8_ == self.mission:getFarmId() then
		self.productionPoint:openMenu()
	end
end

-- Local values: tx, ty, tz
function ProductionPointActivatable:getDistance(x, y, z)
	if self.productionPoint.interactionTriggerNode == nil or (not self.productionPoint.isOwned or self.productionPoint.useInteractionTriggerForBuying) then
		return math.huge
	end
	local v13_, v14_, v15_ = getWorldTranslation(self.productionPoint.interactionTriggerNode)
	return MathUtil.vector3Length(x - v13_, y - v14_, z - v15_)
end
