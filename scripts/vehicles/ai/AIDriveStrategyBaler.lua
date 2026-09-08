-- Local values: AIDriveStrategyBaler_mt
AIDriveStrategyBaler = {}
local AIDriveStrategyBaler_mt = Class(AIDriveStrategyBaler, AIDriveStrategy)

-- Upvalues: AIDriveStrategyBaler_mt
-- Local values: self
function AIDriveStrategyBaler.new(reconstructionData, customMt)
	-- upvalues: (copy) AIDriveStrategyBaler_mt
	local v4_ = AIDriveStrategy.new(reconstructionData, customMt or AIDriveStrategyBaler_mt)
	v4_.balers = {}
	v4_.slowDownFillLevel = 200
	v4_.slowDownStartSpeed = 20
	return v4_
end

-- Local values: _, implement
function AIDriveStrategyBaler:setAIVehicle(vehicle)
	AIDriveStrategyBaler:superClass().setAIVehicle(self, vehicle)
	if SpecializationUtil.hasSpecialization(Baler, self.vehicle.specializations) then
		local v7_ = self.balers
		local v8_ = self.vehicle
		table.insert(v7_, v8_)
	end
	for _, v9_ in pairs(self.vehicle:getAttachedAIImplements()) do
		if SpecializationUtil.hasSpecialization(Baler, v9_.object.specializations) then
			local v10_ = self.balers
			local v11_ = v9_.object
			table.insert(v10_, v11_)
		end
	end
end

function AIDriveStrategyBaler:update(dt) end

-- Local values: allowedToDrive, maxSpeed, _, baler, spec, fillLevel, capacity, freeFillLevel
function AIDriveStrategyBaler:getDriveData(dt, vX, vY, vZ)
	local v13_ = true
	local v14_ = math.huge
	for _, v15_ in pairs(self.balers) do
		local v16_ = v15_.spec_baler
		if v16_.nonStopBaling then
			if v16_.platformDropInProgress then
				v14_ = v16_.platformAIDropSpeed
				if VehicleDebug.state == VehicleDebug.DEBUG_AI then
					self.vehicle:addAIDebugText(string.format("BALER -> Platform dropping active, reducing speed to %.1f km/h", v16_.platformAIDropSpeed))
				end
			end
		else
			local v17_ = v15_:getFillUnitFillLevel(v16_.fillUnitIndex)
			local v18_ = v15_:getFillUnitCapacity(v16_.fillUnitIndex)
			local v19_ = v18_ - v17_
			if v19_ < self.slowDownFillLevel then
				v14_ = 2 + v19_ / self.slowDownFillLevel * self.slowDownStartSpeed
				if VehicleDebug.state == VehicleDebug.DEBUG_AI then
					self.vehicle:addAIDebugText(string.format("BALER -> Slow down because nearly full: %.2f", v14_))
				end
			end
			if v17_ == v18_ or v16_.unloadingState ~= Baler.UNLOADING_CLOSED then
				v13_ = false
			end
		end
	end
	if v13_ then
		return nil, nil, nil, v14_, nil
	else
		return 0, 1, true, 0, math.huge
	end
end

function AIDriveStrategyBaler:updateDriving(dt) end
