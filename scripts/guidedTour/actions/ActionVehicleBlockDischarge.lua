-- Local values: ActionVehicleBlockDischarge_mt
ActionVehicleBlockDischarge = {}
ActionVehicleBlockDischarge.NAME = "vehicleBlockDischarge"
local ActionVehicleBlockDischarge_mt = Class(ActionVehicleBlockDischarge)

function ActionVehicleBlockDischarge.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. "#vehicle", "Name of the vehicle. If not defined the current vehicle is used", nil, false)
	schema:register(XMLValueType.BOOL, basePath .. "#isBlocked", "Value if discharge is blocked or not", nil, true)
end

-- Upvalues: ActionVehicleBlockDischarge_mt
-- Local values: self
function ActionVehicleBlockDischarge.new(vehicleName, isBlocked, customMt)
	-- upvalues: (copy) ActionVehicleBlockDischarge_mt
	local v7_ = customMt or ActionVehicleBlockDischarge_mt
	local v8_ = setmetatable({}, v7_)
	v8_.vehicleName = vehicleName
	v8_.isBlocked = isBlocked
	return v8_
end

-- Local values: vehicle
function ActionVehicleBlockDischarge:run(tour, step)
	local v10_ = g_localPlayer:getCurrentVehicle()
	if self.vehicleName ~= nil then
		v10_ = g_guidedTourManager:getVehicleByName(self.vehicleName)
	end
	if v10_ == nil then
		return false
	end
	if v10_.setIsDischargeAllowed ~= nil then
		v10_:setIsDischargeAllowed(not self.isBlocked)
	end
	return true
end

-- Local values: vehicleName, isBlocked
function ActionVehicleBlockDischarge.createFromXML(xmlFile, key, baseDirectory, customEnvironment)
	local v13_ = xmlFile:getValue(key .. "#vehicle")
	local v14_ = xmlFile:getValue(key .. "#isBlocked")
	if v13_ == nil or v14_ == nil then
		return nil
	else
		return ActionVehicleBlockDischarge.new(v13_, v14_)
	end
end
g_guidedTourManager:registerActionClass(ActionVehicleBlockDischarge.NAME, ActionVehicleBlockDischarge)
