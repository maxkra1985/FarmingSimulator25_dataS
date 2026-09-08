-- Local values: FarmhouseActivatable_mt
FarmhouseActivatable = {}
local FarmhouseActivatable_mt = Class(FarmhouseActivatable)

-- Upvalues: FarmhouseActivatable_mt
-- Local values: self
function FarmhouseActivatable.new(placeable)
	-- upvalues: (copy) FarmhouseActivatable_mt
	local v3_ = FarmhouseActivatable_mt
	local v4_ = setmetatable({}, v3_)
	v4_.placeable = placeable
	v4_.activateText = g_i18n:getText("ui_inGameSleep")
	return v4_
end

function FarmhouseActivatable:getIsActivatable()
	local v6_ = self.placeable:getIsAllowedToSleep(g_currentMission:getFarmId())
	if v6_ then
		v6_ = not g_sleepManager.isSleeping
	end
	return v6_
end

function FarmhouseActivatable:run()
	g_sleepManager:showDialog()
end
