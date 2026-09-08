-- Local values: AIDriveStrategy_mt
AIDriveStrategy = {}
local AIDriveStrategy_mt = Class(AIDriveStrategy)

-- Upvalues: AIDriveStrategy_mt
-- Local values: self
function AIDriveStrategy.new(reconstructionData, customMt)
	-- upvalues: (copy) AIDriveStrategy_mt
	local v3_ = customMt or AIDriveStrategy_mt
	return setmetatable({}, v3_)
end

function AIDriveStrategy:delete() end

function AIDriveStrategy:setAIVehicle(vehicle)
	self.vehicle = vehicle
end

function AIDriveStrategy:update(dt) end

function AIDriveStrategy:getDriveData(dt, vX, vY, vZ)
	return nil, nil, nil, nil, nil
end

function AIDriveStrategy:updateDriving(dt) end
function AIDriveStrategy.debugPrint(_, p6_, ...)
	if VehicleDebug.state == VehicleDebug.DEBUG_AI then
		print(string.format("AI DEBUG: %s", string.format(p6_, ...)))
	end
end
