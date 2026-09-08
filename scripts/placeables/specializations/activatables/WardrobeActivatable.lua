-- Local values: WardrobeActivatable_mt
WardrobeActivatable = {}
local WardrobeActivatable_mt = Class(WardrobeActivatable)

-- Upvalues: WardrobeActivatable_mt
-- Local values: self
function WardrobeActivatable.new(placeable)
	-- upvalues: (copy) WardrobeActivatable_mt
	local v3_ = WardrobeActivatable_mt
	local v4_ = setmetatable({}, v3_)
	v4_.placeable = placeable
	v4_.activateText = g_i18n:getText("action_openWardrobe")
	return v4_
end

function WardrobeActivatable:getIsActivatable()
	return self.placeable.spec_wardrobe.isFreeForAll or g_currentMission:getFarmId() == self.placeable:getOwnerFarmId()
end

function WardrobeActivatable:run()
	if g_guidedTourManager:getIsTourRunning() then
		InfoDialog.show(g_i18n:getText("guidedTour_feature_deactivated"))
	else
		g_gui:changeScreen(nil, WardrobeScreen)
	end
end
