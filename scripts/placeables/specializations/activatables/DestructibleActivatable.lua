-- Local values: DestructibleActivatable_mt
DestructibleActivatable = {}
local DestructibleActivatable_mt = Class(DestructibleActivatable)

-- Upvalues: DestructibleActivatable_mt
-- Local values: self
function DestructibleActivatable.new(placeable)
	-- upvalues: (copy) DestructibleActivatable_mt
	local v3_ = DestructibleActivatable_mt
	local v4_ = setmetatable({}, v3_)
	v4_.placeable = placeable
	v4_.activateText = g_i18n:getText("action_destructibleStartRepairing")
	return v4_
end

function DestructibleActivatable:getIsActivatable()
	return self.placeable:getCanRepairDestructible(g_currentMission:getFarmId())
end

function DestructibleActivatable:run()
	if g_guidedTourManager:getIsTourRunning() then
		InfoDialog.show(g_i18n:getText("guidedTour_feature_deactivated"))
	else
		g_client:getServerConnection():sendEvent(PlaceableDestructibleRepairEvent.new(self.placeable))
	end
end
