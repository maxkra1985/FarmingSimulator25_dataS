-- Local values: GoalVehicleInTipTrigger_mt
GoalVehicleInTipTrigger = {}
GoalVehicleInTipTrigger.NAME = "vehicleInTipTrigger"
local GoalVehicleInTipTrigger_mt = Class(GoalVehicleInTipTrigger)

function GoalVehicleInTipTrigger.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. "#vehicle", "Name of the vehicle", nil, true)
end

-- Upvalues: GoalVehicleInTipTrigger_mt
-- Local values: self
function GoalVehicleInTipTrigger.new(vehicleName, customMt)
	-- upvalues: (copy) GoalVehicleInTipTrigger_mt
	local v6_ = customMt or GoalVehicleInTipTrigger_mt
	local v7_ = setmetatable({}, v6_)
	v7_.vehicleName = vehicleName
	return v7_
end

function GoalVehicleInTipTrigger:activate(tour, step)
	self.vehicle = g_guidedTourManager:getVehicleByName(self.vehicleName)
	if self.vehicle == nil then
		Logging.warning("GoalVehicleInTipTrigger.activate: Vehicle \'%s\' not found", self.vehicleName)
		return
	elseif self.vehicle.getIsPossibleToDischargeToObject == nil then
		Logging.warning("GoalVehicleInTipTrigger.activate: Vehicle \'%s\' does not have discharge feature", self.vehicleName)
	end
end

function GoalVehicleInTipTrigger:deactivate()
	self.vehicle = nil
end

function GoalVehicleInTipTrigger:isAchieved()
	return self.vehicle == nil and true or (self.vehicle:getIsPossibleToDischargeToObject() and true or false)
end

-- Local values: vehicleName
function GoalVehicleInTipTrigger.createFromXML(xmlFile, key, baseDirectory, customEnvironment)
	local v13_ = xmlFile:getValue(key .. "#vehicle")
	if v13_ ~= nil then
		return GoalVehicleInTipTrigger.new(v13_)
	end
	Logging.xmlWarning(xmlFile, "Missing \'vehicle\' for \'%s\'", key)
	return nil
end
g_guidedTourManager:registerGoalClass(GoalVehicleInTipTrigger.NAME, GoalVehicleInTipTrigger)
