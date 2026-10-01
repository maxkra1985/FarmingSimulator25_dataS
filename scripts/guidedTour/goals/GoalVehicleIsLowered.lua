GoalVehicleIsLowered = {}
GoalVehicleIsLowered.NAME = "vehicleIsLowered"
local GoalVehicleIsLowered_mt = Class(GoalVehicleIsLowered)
function GoalVehicleIsLowered.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. "#vehicle", "Identifier of the vehicle", nil, true)
end
function GoalVehicleIsLowered.new(vehicleName, customMt)
	local self = setmetatable({}, customMt or GoalVehicleIsLowered_mt)
	self.vehicleName = vehicleName
	return self
end
function GoalVehicleIsLowered:activate(tour, step)
	self.vehicle = g_guidedTourManager:getVehicleByName(self.vehicleName)
	if self.vehicle == nil then
		Logging.warning("GoalVehicleIsLowered.activate: Vehicle '%s' not found", self.vehicleName)
	elseif self.vehicle.getIsLowered == nil then
		self.vehicle = nil
		Logging.warning("GoalVehicleIsLowered.activate: Vehicle '%s' cannot be lowered", self.vehicleName)
	end
end
function GoalVehicleIsLowered:deactivate()
	self.vehicle = nil
end
function GoalVehicleIsLowered:isAchieved()
	if self.vehicle == nil then
		return true
	else
		return self.vehicle:getIsLowered()
	end
end
function GoalVehicleIsLowered.createFromXML(xmlFile, key, baseDirectory, customEnvironment)
	local vehicleName = xmlFile:getValue(key .. "#vehicle")
	if vehicleName == nil then
		Logging.xmlWarning(xmlFile, "Missing 'vehicle' for '%s'", key)
		return nil
	else
		return GoalVehicleIsLowered.new(vehicleName)
	end
end
g_guidedTourManager:registerGoalClass(GoalVehicleIsLowered.NAME, GoalVehicleIsLowered)
