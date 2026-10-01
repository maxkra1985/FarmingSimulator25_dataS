GoalVehicleDetached = {}
GoalVehicleDetached.NAME = "vehicleDetached"
local GoalVehicleDetached_mt = Class(GoalVehicleDetached)
function GoalVehicleDetached.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. "#vehicle", "Identifier of the vehicle", nil, true)
end
function GoalVehicleDetached.new(vehicleName, customMt)
	local self = setmetatable({}, customMt or GoalVehicleDetached_mt)
	self.vehicleName = vehicleName
	return self
end
function GoalVehicleDetached:activate(tour, step)
	self.vehicle = g_guidedTourManager:getVehicleByName(self.vehicleName)
	if self.vehicle == nil then
		Logging.warning("GoalVehicleDetached.activate: Vehicle '%s' not found", self.vehicleName)
	end
end
function GoalVehicleDetached:deactivate()
	self.vehicle = nil
end
function GoalVehicleDetached:isAchieved()
	if self.vehicle == nil then
		return true
	else
		local attacherVehicle = self.vehicle:getAttacherVehicle()
		return attacherVehicle == nil
	end
end
function GoalVehicleDetached.createFromXML(xmlFile, key, baseDirectory, customEnvironment)
	local vehicleName = xmlFile:getValue(key .. "#vehicle")
	if vehicleName == nil then
		Logging.xmlWarning(xmlFile, "Missing 'vehicle' for '%s'", key)
		return nil
	else
		return GoalVehicleDetached.new(vehicleName)
	end
end
g_guidedTourManager:registerGoalClass(GoalVehicleDetached.NAME, GoalVehicleDetached)
