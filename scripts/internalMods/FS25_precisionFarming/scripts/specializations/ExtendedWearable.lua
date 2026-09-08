ExtendedWearable = {}
ExtendedWearable.SPEC_TABLE_NAME = "spec_" .. g_currentModName .. ".extendedWearable"

function ExtendedWearable.prerequisitesPresent(specializations)
	local v2_ = SpecializationUtil.hasSpecialization(Wearable, specializations)
	if v2_ then
		v2_ = SpecializationUtil.hasSpecialization(PrecisionFarmingStatistic, specializations)
	end
	return v2_
end

function ExtendedWearable.registerFunctions(vehicleType) end

function ExtendedWearable.registerOverwrittenFunctions(vehicleType) end

function ExtendedWearable.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", ExtendedWearable)
	SpecializationUtil.registerEventListener(vehicleType, "onPostUpdateTick", ExtendedWearable)
end

-- Local values: spec
function ExtendedWearable:onLoad(savegame)
	self[ExtendedWearable.SPEC_TABLE_NAME].lastDamage = -1
end

-- Local values: spec, damage, price, lastRepairPrice, repairPrice, repairCosts, _, isOnField, _
function ExtendedWearable:onPostUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v6_ = self[ExtendedWearable.SPEC_TABLE_NAME]
	local v7_ = self.spec_wearable.damage
	if v6_.lastDamage > 0 then
		local v8_ = self:getPrice()
		local v9_ = Wearable.calculateRepairPrice(v8_, v6_.lastDamage)
		local v10_ = Wearable.calculateRepairPrice(v8_, v7_) - v9_
		if v10_ > 0 then
			local _, v11_, _ = self:getPFStatisticInfo()
			if v11_ then
				self:updatePFStatistic("vehicleCosts", v10_)
			end
		end
	end
	v6_.lastDamage = v7_
end
