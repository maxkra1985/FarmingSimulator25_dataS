ActionVehicleDetach = {}
ActionVehicleDetach.NAME = "vehicleDetach"
local ActionVehicleDetach_mt = Class(ActionVehicleDetach)
function ActionVehicleDetach.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. "#vehicle", "Name of the vehicle", nil, true)
end
function ActionVehicleDetach.new(vehicleName, customMt)
	local self = setmetatable({}, customMt or ActionVehicleDetach_mt)
	self.vehicleName = vehicleName
	return self
end
function ActionVehicleDetach:run(tour, step)
	local vehicle = g_guidedTourManager:getVehicleByName(self.vehicleName)
	if vehicle == nil then
		Logging.warning("ActionVehicleDetach.run: Vehicle '%s' not found", self.vehicleName)
	end
	if vehicle.getAttacherVehicle == nil then
		return true
	else
		local attacherVehicle = vehicle:getAttacherVehicle()
		if attacherVehicle ~= nil then
			attacherVehicle:detachImplementByObject(vehicle)
		end
		return true
	end
end
function ActionVehicleDetach.createFromXML(xmlFile, key, baseDirectory, customEnvironment)
	local vehicleName = xmlFile:getValue(key .. "#vehicle")
	if vehicleName ~= nil then
		return ActionVehicleDetach.new(vehicleName)
	else
		return nil
	end
end
g_guidedTourManager:registerActionClass(ActionVehicleDetach.NAME, ActionVehicleDetach)
