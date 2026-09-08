-- Local values: CollectibleActivatable_mt
CollectibleActivatable = {}
local CollectibleActivatable_mt = Class(CollectibleActivatable)

-- Upvalues: CollectibleActivatable_mt
-- Local values: self
function CollectibleActivatable.new(collectible)
	-- upvalues: (copy) CollectibleActivatable_mt
	local v3_ = CollectibleActivatable_mt
	local v4_ = setmetatable({}, v3_)
	v4_.collectible = collectible
	v4_.activateText = g_i18n:getText("action_collectibleCollect")
	return v4_
end

function CollectibleActivatable:run()
	if g_localPlayer.farmId ~= FarmManager.SPECTATOR_FARM_ID then
		g_currentMission.collectiblesSystem:onTriggerCollectible(self.collectible)
	end
end
