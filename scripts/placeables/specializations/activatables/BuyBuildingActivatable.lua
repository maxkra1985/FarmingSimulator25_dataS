BuyBuildingActivatable = {}
local BuyBuildingActivatable_mt = Class(BuyBuildingActivatable)
function BuyBuildingActivatable.new(placeable)
	local self = setmetatable({}, BuyBuildingActivatable_mt)
	self.placeable = placeable
	self.activateText = g_i18n:getText("action_buyBuilding")
	return self
end
function BuyBuildingActivatable:getIsActivatable()
	return g_currentMission.accessHandler:canFarmAccess(g_currentMission:getFarmId(), self.placeable)
end
function BuyBuildingActivatable:run()
	local ownerFarmId = self.placeable:getOwnerFarmId()
	if ownerFarmId == AccessHandler.EVERYONE then
		self.placeable:buyRequest()
	end
end
function BuyBuildingActivatable:getDistance(x, y, z)
	local triggerNode = self.placeable.spec_buyable.triggerNode
	if triggerNode ~= nil then
		local tx, ty, tz = getWorldTranslation(triggerNode)
		return MathUtil.vector3Length(x - tx, y - ty, z - tz)
	else
		return math.huge
	end
end
