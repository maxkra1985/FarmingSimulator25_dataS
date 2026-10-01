ExtendedWearable = {}
ExtendedWearable.SPEC_TABLE_NAME = "spec_" .. g_currentModName .. ".extendedWearable"
function ExtendedWearable.prerequisitesPresent(specializations)
	return SpecializationUtil.hasSpecialization(Wearable, specializations) and SpecializationUtil.hasSpecialization(PrecisionFarmingStatistic, specializations)
end
function ExtendedWearable.registerFunctions(vehicleType) end
function ExtendedWearable.registerOverwrittenFunctions(vehicleType) end
function ExtendedWearable.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", ExtendedWearable)
	SpecializationUtil.registerEventListener(vehicleType, "onPostUpdateTick", ExtendedWearable)
end
function ExtendedWearable:onLoad(savegame)
	local spec = self[ExtendedWearable.SPEC_TABLE_NAME]
	spec.lastDamage = -1
end
function ExtendedWearable:onPostUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self[ExtendedWearable.SPEC_TABLE_NAME]
	local damage = self.spec_wearable.damage
	if 0 < spec.lastDamage then
		local price = self:getPrice()
		local lastRepairPrice = Wearable.calculateRepairPrice(price, spec.lastDamage)
		local repairPrice = Wearable.calculateRepairPrice(price, damage)
		local repairCosts = repairPrice - lastRepairPrice
		if 0 < repairCosts then
			local _, isOnField, _ = self:getPFStatisticInfo()
			if isOnField then
				self:updatePFStatistic("vehicleCosts", repairCosts)
			end
		end
	end
	spec.lastDamage = damage
end
