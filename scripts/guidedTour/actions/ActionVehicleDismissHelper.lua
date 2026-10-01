ActionVehicleDismissHelper = {}
ActionVehicleDismissHelper.NAME = "vehicleDismissHelper"
local ActionVehicleDismissHelper_mt = Class(ActionVehicleDismissHelper)
function ActionVehicleDismissHelper.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. "#vehicle", "Name of the vehicle", nil, true)
end
function ActionVehicleDismissHelper.new(vehicleName, customMt)
	local self = setmetatable({}, customMt or ActionVehicleDismissHelper_mt)
	self.vehicleName = vehicleName
	return self
end
function ActionVehicleDismissHelper:run(tour, step)
	local vehicle = g_guidedTourManager:getVehicleByName(self.vehicleName)
	if vehicle == nil then
		Logging.warning("ActionVehicleDismissHelper.run: Vehicle '%s' not found", self.vehicleName)
	end
	if vehicle.stopCurrentAIJob ~= nil then
		vehicle:stopCurrentAIJob()
	end
	return true
end
function ActionVehicleDismissHelper.createFromXML(xmlFile, key, baseDirectory, customEnvironment)
	local vehicleName = xmlFile:getValue(key .. "#vehicle")
	if vehicleName ~= nil then
		return ActionVehicleDismissHelper.new(vehicleName)
	else
		return nil
	end
end
g_guidedTourManager:registerActionClass(ActionVehicleDismissHelper.NAME, ActionVehicleDismissHelper)
