GoalVehicleInFillTrigger = {}
GoalVehicleInFillTrigger.NAME = "vehicleInFillRange"
local GoalVehicleInFillTrigger_mt = Class(GoalVehicleInFillTrigger)
function GoalVehicleInFillTrigger.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. "#vehicle", "Name of the vehicle", nil, true)
end
function GoalVehicleInFillTrigger.new(vehicleName, customMt)
	local self = setmetatable({}, customMt or GoalVehicleInFillTrigger_mt)
	self.vehicleName = vehicleName
	return self
end
function GoalVehicleInFillTrigger:activate(tour, step)
	self.vehicle = g_guidedTourManager:getVehicleByName(self.vehicleName)
	if self.vehicle == nil then
		Logging.warning("GoalVehicleInFillTrigger.activate: Vehicle '%s' not found", self.vehicleName)
	else
		if self.vehicle.spec_fillUnit == nil or self.vehicle.spec_fillUnit.fillTrigger == nil then
			Logging.warning("GoalVehicleInFillTrigger.activate: Vehicle '%s' has no fill trigger", self.vehicleName)
		end
	end
end
function GoalVehicleInFillTrigger:deactivate()
	self.vehicle = nil
end
function GoalVehicleInFillTrigger:isAchieved()
	if self.vehicle == nil then
		return true
	end
	local fillTrigger = self.vehicle.spec_fillUnit.fillTrigger
	if fillTrigger.activatable:getIsActivatable() then
		return true
	else
		return false
	end
end
function GoalVehicleInFillTrigger.createFromXML(xmlFile, key, baseDirectory, customEnvironment)
	local vehicleName = xmlFile:getValue(key .. "#vehicle")
	if vehicleName == nil then
		Logging.xmlWarning(xmlFile, "Missing 'vehicle' for '%s'", key)
		return nil
	else
		return GoalVehicleInFillTrigger.new(vehicleName)
	end
end
g_guidedTourManager:registerGoalClass(GoalVehicleInFillTrigger.NAME, GoalVehicleInFillTrigger)
