-- Local values: VehicleBuyingStationActivatable_mt
VehicleBuyingStationActivatable = {}
local VehicleBuyingStationActivatable_mt = Class(VehicleBuyingStationActivatable)

-- Upvalues: VehicleBuyingStationActivatable_mt
-- Local values: self
function VehicleBuyingStationActivatable.new(placeable, callbackFunc, text)
	-- upvalues: (copy) VehicleBuyingStationActivatable_mt
	local v5_ = VehicleBuyingStationActivatable_mt
	local v6_ = setmetatable({}, v5_)
	v6_.placeable = placeable
	v6_.callbackFunc = callbackFunc
	v6_.activateText = text
	return v6_
end

function VehicleBuyingStationActivatable:getIsActivatable()
	return g_currentMission.accessHandler:canPlayerAccess(self.placeable)
end

function VehicleBuyingStationActivatable:run()
	self.callbackFunc()
end
