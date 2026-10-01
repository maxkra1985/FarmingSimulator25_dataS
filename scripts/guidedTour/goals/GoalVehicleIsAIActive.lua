GoalVehicleIsAIActive = {}
GoalVehicleIsAIActive.NAME = "vehicleIsAIActive"
local GoalVehicleIsAIActive_mt = Class(GoalVehicleIsAIActive)
function GoalVehicleIsAIActive.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. "#vehicle", "Identifier of the vehicle", nil, true)
end
function GoalVehicleIsAIActive.new(vehicleName, customMt)
	local self = setmetatable({}, customMt or GoalVehicleIsAIActive_mt)
	self.vehicleName = vehicleName
	return self
end
function GoalVehicleIsAIActive:activate(tour, step)
	self.vehicle = g_guidedTourManager:getVehicleByName(self.vehicleName)
	if self.vehicle == nil then
		Logging.warning("GoalVehicleIsAIActive.activate: Vehicle '%s' not found", self.vehicleName)
	elseif self.vehicle.getIsAIActive == nil then
		self.vehicle = nil
		Logging.warning("GoalVehicleIsAIActive.activate: Vehicle '%s' does not support AI", self.vehicleName)
	end
end
function GoalVehicleIsAIActive:deactivate()
	self.vehicle = nil
end
function GoalVehicleIsAIActive:isAchieved()
	if self.vehicle == nil then
		return true
	else
		return self.vehicle:getIsAIActive()
	end
end
function GoalVehicleIsAIActive.createFromXML(xmlFile, key, baseDirectory, customEnvironment)
	local vehicleName = xmlFile:getValue(key .. "#vehicle")
	if vehicleName == nil then
		Logging.xmlWarning(xmlFile, "Missing 'vehicle' for '%s'", key)
		return nil
	else
		return GoalVehicleIsAIActive.new(vehicleName)
	end
end
g_guidedTourManager:registerGoalClass(GoalVehicleIsAIActive.NAME, GoalVehicleIsAIActive)
