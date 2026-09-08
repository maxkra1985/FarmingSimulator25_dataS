-- Local values: PalletUnloadTriggerActivatable_mt
PalletUnloadTriggerActivatable = {}
local PalletUnloadTriggerActivatable_mt = Class(PalletUnloadTriggerActivatable)

-- Upvalues: PalletUnloadTriggerActivatable_mt
-- Local values: self
function PalletUnloadTriggerActivatable.new(palletUnloadTrigger)
	-- upvalues: (copy) PalletUnloadTriggerActivatable_mt
	local v3_ = PalletUnloadTriggerActivatable_mt
	local v4_ = setmetatable({}, v3_)
	v4_.owner = palletUnloadTrigger
	v4_.activateText = g_i18n:getText("button_unload")
	return v4_
end

-- Local values: owner, mission, canAccess, vehicle, _
function PalletUnloadTriggerActivatable:getIsActivatable()
	local v6_ = self.owner
	if not v6_.isEnabled then
		return false
	end
	if g_gui.currentGui ~= nil then
		return false
	end
	if not g_currentMission.accessHandler:canPlayerAccess(self.owner) then
		return false
	end
	if #v6_.palletsInRange == 0 then
		return false
	end
	if v6_.isPlayerInRange then
		return true
	end
	for v7_, _ in pairs(v6_.vehiclesInRange) do
		if v7_.rootVehicle == g_localPlayer:getCurrentVehicle() then
			return true
		end
	end
	return false
end

-- Local values: mission
function PalletUnloadTriggerActivatable:run()
	local v9_ = g_currentMission
	self.owner:unloadPallets(v9_:getFarmId())
end

-- Local values: tx, ty, tz
function PalletUnloadTriggerActivatable:getDistance(x, y, z)
	if self.owner.triggerNode == nil then
		return math.huge
	end
	local v14_, v15_, v16_ = getWorldTranslation(self.owner.triggerNode)
	return MathUtil.vector3Length(x - v14_, y - v15_, z - v16_)
end
