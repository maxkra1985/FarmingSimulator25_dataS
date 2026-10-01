GoalVehicleIsUnfolded = {}
GoalVehicleIsUnfolded.NAME = "vehicleIsUnfolded"
local GoalVehicleIsUnfolded_mt = Class(GoalVehicleIsUnfolded)
function GoalVehicleIsUnfolded.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. "#vehicle", "Identifier of the vehicle", nil, true)
end
function GoalVehicleIsUnfolded.new(vehicleName, customMt)
	local self = setmetatable({}, customMt or GoalVehicleIsUnfolded_mt)
	self.vehicleName = vehicleName
	return self
end
function GoalVehicleIsUnfolded:activate(tour, step)
	self.vehicle = g_guidedTourManager:getVehicleByName(self.vehicleName)
	if self.vehicle == nil then
		Logging.warning("GoalVehicleIsUnfolded.activate: Vehicle '%s' not found", self.vehicleName)
	elseif self.vehicle.getIsUnfolded == nil then
		self.vehicle = nil
		Logging.warning("GoalVehicleIsUnfolded.activate: Vehicle '%s' cannot be unfolded", self.vehicleName)
	end
end
function GoalVehicleIsUnfolded:deactivate()
	self.vehicle = nil
end
function GoalVehicleIsUnfolded:isAchieved()
	if self.vehicle == nil then
		return true
	else
		return self.vehicle:getIsUnfolded()
	end
end
function GoalVehicleIsUnfolded.createFromXML(xmlFile, key, baseDirectory, customEnvironment)
	local vehicleName = xmlFile:getValue(key .. "#vehicle")
	if vehicleName == nil then
		Logging.xmlWarning(xmlFile, "Missing 'vehicle' for '%s'", key)
		return nil
	else
		return GoalVehicleIsUnfolded.new(vehicleName)
	end
end
g_guidedTourManager:registerGoalClass(GoalVehicleIsUnfolded.NAME, GoalVehicleIsUnfolded)
