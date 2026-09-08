-- Local values: ActionVehicleSetCustomBrake_mt
ActionVehicleSetCustomBrake = {}
ActionVehicleSetCustomBrake.NAME = "vehicleCustomBrake"
local ActionVehicleSetCustomBrake_mt = Class(ActionVehicleSetCustomBrake)

function ActionVehicleSetCustomBrake.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. "#vehicle", "Name of the vehicle. If not defined the current vehicle is used", nil, false)
	schema:register(XMLValueType.FLOAT, basePath .. "#brakeForce", "Value of the custom brake force", nil, true)
end

-- Upvalues: ActionVehicleSetCustomBrake_mt
-- Local values: self
function ActionVehicleSetCustomBrake.new(vehicleName, brakeForce, customMt)
	-- upvalues: (copy) ActionVehicleSetCustomBrake_mt
	local v7_ = customMt or ActionVehicleSetCustomBrake_mt
	local v8_ = setmetatable({}, v7_)
	v8_.vehicleName = vehicleName
	v8_.brakeForce = brakeForce
	return v8_
end

-- Local values: vehicle, brakeForce
function ActionVehicleSetCustomBrake:run(tour, step)
	local v10_ = g_localPlayer:getCurrentVehicle()
	if self.vehicleName ~= nil then
		v10_ = g_guidedTourManager:getVehicleByName(self.vehicleName)
	end
	if v10_ == nil then
		return false
	end
	local v11_ = self.brakeForce
	if v11_ ~= nil and v10_.setCruiseControlState ~= nil then
		v10_:setCruiseControlState(Drivable.CRUISECONTROL_STATE_OFF)
	end
	if v10_.setCustomBrakeForce ~= nil then
		v10_:setCustomBrakeForce(v11_)
	end
	return true
end

-- Local values: brakeForce, vehicleName
function ActionVehicleSetCustomBrake.createFromXML(xmlFile, key, baseDirectory, customEnvironment)
	local v14_ = xmlFile:getValue(key .. "#brakeForce")
	if v14_ == nil then
		return nil
	end
	local v15_ = xmlFile:getValue(key .. "#vehicle")
	if v14_ <= 0 then
		v14_ = nil
	end
	return ActionVehicleSetCustomBrake.new(v15_, v14_)
end
g_guidedTourManager:registerActionClass(ActionVehicleSetCustomBrake.NAME, ActionVehicleSetCustomBrake)
