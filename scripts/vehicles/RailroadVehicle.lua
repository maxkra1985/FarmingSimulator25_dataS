-- Local values: RailroadVehicle_mt
RailroadVehicle = {}
local RailroadVehicle_mt = Class(RailroadVehicle, Vehicle)
InitStaticObjectClass(RailroadVehicle, "RailroadVehicle")

function RailroadVehicle.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "setTrainSystem", RailroadVehicle.setTrainSystem)
	RailroadVehicle:superClass().registerFunctions(vehicleType)
end

-- Upvalues: RailroadVehicle_mt
-- Local values: self
function RailroadVehicle.new(isServer, isClient, customMt)
	-- upvalues: (copy) RailroadVehicle_mt
	local v6_ = Vehicle.new(isServer, isClient, customMt or RailroadVehicle_mt)
	v6_.trainSystem = nil
	return v6_
end

function RailroadVehicle:setTrainSystem(trainSystem)
	self.trainSystem = trainSystem
	self.synchronizePosition = false
end
function RailroadVehicle.update(p9_, ...)
	if p9_.isServer and p9_.trainSystem == nil then
		p9_:delete()
	else
		RailroadVehicle:superClass().update(p9_, ...)
	end
end
