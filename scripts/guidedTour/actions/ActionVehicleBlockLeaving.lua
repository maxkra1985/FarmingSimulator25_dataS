ActionVehicleBlockLeaving = {}
ActionVehicleBlockLeaving.NAME = "vehicleBlockLeaving"
local ActionVehicleBlockLeaving_mt = Class(ActionVehicleBlockLeaving)
function ActionVehicleBlockLeaving.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. "#vehicle", "Name of the vehicle. If not defined the current vehicle is used", nil, false)
	schema:register(XMLValueType.BOOL, basePath .. "#isBlocked", "Value if leaving is blocked or not", nil, true)
end
function ActionVehicleBlockLeaving.new(vehicleName, isBlocked, customMt)
	local self = setmetatable({}, customMt or ActionVehicleBlockLeaving_mt)
	self.vehicleName = vehicleName
	self.isBlocked = isBlocked
	return self
end
function ActionVehicleBlockLeaving:run(tour, step)
	local vehicle = g_localPlayer:getCurrentVehicle()
	if self.vehicleName ~= nil then
		vehicle = g_guidedTourManager:getVehicleByName(self.vehicleName)
	end
	if vehicle == nil then
		return false
	else
		if vehicle.setIsLeavingAllowed ~= nil then
			vehicle:setIsLeavingAllowed(not self.isBlocked)
		end
		return true
	end
end
function ActionVehicleBlockLeaving.createFromXML(xmlFile, key, baseDirectory, customEnvironment)
	local vehicleName = xmlFile:getValue(key .. "#vehicle")
	local isBlocked = xmlFile:getValue(key .. "#isBlocked")
	if vehicleName ~= nil and isBlocked ~= nil then
		return ActionVehicleBlockLeaving.new(vehicleName, isBlocked)
	end
	return nil
end
g_guidedTourManager:registerActionClass(ActionVehicleBlockLeaving.NAME, ActionVehicleBlockLeaving)
