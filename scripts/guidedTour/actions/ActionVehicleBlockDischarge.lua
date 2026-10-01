ActionVehicleBlockDischarge = {}
ActionVehicleBlockDischarge.NAME = "vehicleBlockDischarge"
local ActionVehicleBlockDischarge_mt = Class(ActionVehicleBlockDischarge)
function ActionVehicleBlockDischarge.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. "#vehicle", "Name of the vehicle. If not defined the current vehicle is used", nil, false)
	schema:register(XMLValueType.BOOL, basePath .. "#isBlocked", "Value if discharge is blocked or not", nil, true)
end
function ActionVehicleBlockDischarge.new(vehicleName, isBlocked, customMt)
	local self = setmetatable({}, customMt or ActionVehicleBlockDischarge_mt)
	self.vehicleName = vehicleName
	self.isBlocked = isBlocked
	return self
end
function ActionVehicleBlockDischarge:run(tour, step)
	local vehicle = g_localPlayer:getCurrentVehicle()
	if self.vehicleName ~= nil then
		vehicle = g_guidedTourManager:getVehicleByName(self.vehicleName)
	end
	if vehicle == nil then
		return false
	else
		if vehicle.setIsDischargeAllowed ~= nil then
			vehicle:setIsDischargeAllowed(not self.isBlocked)
		end
		return true
	end
end
function ActionVehicleBlockDischarge.createFromXML(xmlFile, key, baseDirectory, customEnvironment)
	local vehicleName = xmlFile:getValue(key .. "#vehicle")
	local isBlocked = xmlFile:getValue(key .. "#isBlocked")
	if vehicleName ~= nil and isBlocked ~= nil then
		return ActionVehicleBlockDischarge.new(vehicleName, isBlocked)
	end
	return nil
end
g_guidedTourManager:registerActionClass(ActionVehicleBlockDischarge.NAME, ActionVehicleBlockDischarge)
