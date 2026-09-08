-- Local values: WoodUnloadTriggerActivatable_mt
WoodUnloadTriggerActivatable = {}
local WoodUnloadTriggerActivatable_mt = Class(WoodUnloadTriggerActivatable)

-- Upvalues: WoodUnloadTriggerActivatable_mt
-- Local values: self
function WoodUnloadTriggerActivatable.new(woodUnloadTrigger)
	-- upvalues: (copy) WoodUnloadTriggerActivatable_mt
	local v3_ = WoodUnloadTriggerActivatable_mt
	local v4_ = setmetatable({}, v3_)
	v4_.woodUnloadTrigger = woodUnloadTrigger
	v4_.activateText = g_i18n:getText("action_sellWood")
	return v4_
end

function WoodUnloadTriggerActivatable:getIsActivatable()
	local v5_ = not g_localPlayer:getIsInVehicle()
	if v5_ then
		v5_ = g_currentMission:getFarmId() ~= FarmManager.SPECTATOR_FARM_ID
	end
	return v5_
end

function WoodUnloadTriggerActivatable:run()
	self.woodUnloadTrigger:processWood(g_currentMission:getFarmId())
end

-- Local values: tx, ty, tz
function WoodUnloadTriggerActivatable:getDistance(x, y, z)
	if self.woodUnloadTrigger.activationTrigger == nil then
		return math.huge
	end
	local v11_, v12_, v13_ = getWorldTranslation(self.woodUnloadTrigger.activationTrigger)
	return MathUtil.vector3Length(x - v11_, y - v12_, z - v13_)
end
