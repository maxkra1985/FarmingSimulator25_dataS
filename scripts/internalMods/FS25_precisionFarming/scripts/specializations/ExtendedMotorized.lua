ExtendedMotorized = {}

function ExtendedMotorized.prerequisitesPresent(specializations)
	local v2_ = SpecializationUtil.hasSpecialization(Motorized, specializations)
	if v2_ then
		v2_ = SpecializationUtil.hasSpecialization(PrecisionFarmingStatistic, specializations)
	end
	return v2_
end

function ExtendedMotorized.registerFunctions(vehicleType) end

function ExtendedMotorized.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "updateConsumers", ExtendedMotorized.updateConsumers)
end

function ExtendedMotorized.registerEventListeners(vehicleType) end

-- Local values: _, isOnField, _, spec, _, consumer, fillUnit
function ExtendedMotorized:updateConsumers(superFunc, dt, accInput)
	superFunc(self, dt, accInput)
	local _, v8_, _ = self:getPFStatisticInfo()
	if v8_ then
		local v9_ = self.spec_motorized
		for _, v10_ in pairs(v9_.consumers) do
			if v10_.permanentConsumption and v10_.usage > 0 then
				local v11_ = self:getFillUnitByIndex(v10_.fillUnitIndex)
				if v11_ ~= nil and v11_.lastValidFillType == FillType.DIESEL then
					self:updatePFStatistic("usedFuel", v9_.lastFuelUsage / 60 / 60 / 1000 * dt)
				end
			end
		end
	end
end
