-- Local values: PalletBuyingStationActivatable_mt
PalletBuyingStationActivatable = {}
local PalletBuyingStationActivatable_mt = Class(PalletBuyingStationActivatable)

-- Upvalues: PalletBuyingStationActivatable_mt
-- Local values: self
function PalletBuyingStationActivatable.new(placeable, text)
	-- upvalues: (copy) PalletBuyingStationActivatable_mt
	local v4_ = PalletBuyingStationActivatable_mt
	local v5_ = setmetatable({}, v4_)
	v5_.placeable = placeable
	v5_.activateText = text
	return v5_
end

function PalletBuyingStationActivatable:getIsActivatable()
	return g_currentMission.accessHandler:canPlayerAccess(self.placeable)
end

function PalletBuyingStationActivatable:run()
	self.placeable:openShop()
end
