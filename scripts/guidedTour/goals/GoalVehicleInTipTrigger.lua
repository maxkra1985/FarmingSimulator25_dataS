GoalVehicleInTipTrigger = {}
GoalVehicleInTipTrigger.NAME = "vehicleInTipTrigger"
local GoalVehicleInTipTrigger_mt = Class(GoalVehicleInTipTrigger)
function GoalVehicleInTipTrigger.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. "#vehicle", "Name of the vehicle", nil, true)
end
function GoalVehicleInTipTrigger.new(vehicleName, customMt)
	local self = setmetatable({}, customMt or GoalVehicleInTipTrigger_mt)
	self.vehicleName = vehicleName
	return self
end
function GoalVehicleInTipTrigger:activate(tour, step)
	self.vehicle = g_guidedTourManager:getVehicleByName(self.vehicleName)
	if self.vehicle == nil then
		Logging.warning("GoalVehicleInTipTrigger.activate: Vehicle '%s' not found", self.vehicleName)
	elseif self.vehicle.getIsPossibleToDischargeToObject == nil then
		Logging.warning("GoalVehicleInTipTrigger.activate: Vehicle '%s' does not have discharge feature", self.vehicleName)
	end
end
function GoalVehicleInTipTrigger:deactivate()
	self.vehicle = nil
end
function GoalVehicleInTipTrigger:isAchieved()
	if self.vehicle == nil then
		return true
	elseif self.vehicle:getIsPossibleToDischargeToObject() then
		return true
	else
		return false
	end
end
function GoalVehicleInTipTrigger.createFromXML(xmlFile, key, baseDirectory, customEnvironment)
	local vehicleName = xmlFile:getValue(key .. "#vehicle")
	if vehicleName == nil then
		Logging.xmlWarning(xmlFile, "Missing 'vehicle' for '%s'", key)
		return nil
	else
		return GoalVehicleInTipTrigger.new(vehicleName)
	end
end
g_guidedTourManager:registerGoalClass(GoalVehicleInTipTrigger.NAME, GoalVehicleInTipTrigger)
