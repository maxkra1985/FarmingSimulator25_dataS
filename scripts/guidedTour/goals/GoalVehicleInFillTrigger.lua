-- Local values: GoalVehicleInFillTrigger_mt
GoalVehicleInFillTrigger = {}
GoalVehicleInFillTrigger.NAME = "vehicleInFillRange"
local GoalVehicleInFillTrigger_mt = Class(GoalVehicleInFillTrigger)

function GoalVehicleInFillTrigger.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. "#vehicle", "Name of the vehicle", nil, true)
end

-- Upvalues: GoalVehicleInFillTrigger_mt
-- Local values: self
function GoalVehicleInFillTrigger.new(vehicleName, customMt)
	-- upvalues: (copy) GoalVehicleInFillTrigger_mt
	local v6_ = customMt or GoalVehicleInFillTrigger_mt
	local v7_ = setmetatable({}, v6_)
	v7_.vehicleName = vehicleName
	return v7_
end

function GoalVehicleInFillTrigger:activate(tour, step)
	self.vehicle = g_guidedTourManager:getVehicleByName(self.vehicleName)
	if self.vehicle == nil then
		Logging.warning("GoalVehicleInFillTrigger.activate: Vehicle \'%s\' not found", self.vehicleName)
		return
	elseif self.vehicle.spec_fillUnit == nil or self.vehicle.spec_fillUnit.fillTrigger == nil then
		Logging.warning("GoalVehicleInFillTrigger.activate: Vehicle \'%s\' has no fill trigger", self.vehicleName)
	end
end

function GoalVehicleInFillTrigger:deactivate()
	self.vehicle = nil
end

-- Local values: fillTrigger
function GoalVehicleInFillTrigger:isAchieved()
	return self.vehicle == nil and true or (self.vehicle.spec_fillUnit.fillTrigger.activatable:getIsActivatable() and true or false)
end

-- Local values: vehicleName
function GoalVehicleInFillTrigger.createFromXML(xmlFile, key, baseDirectory, customEnvironment)
	local v13_ = xmlFile:getValue(key .. "#vehicle")
	if v13_ ~= nil then
		return GoalVehicleInFillTrigger.new(v13_)
	end
	Logging.xmlWarning(xmlFile, "Missing \'vehicle\' for \'%s\'", key)
	return nil
end
g_guidedTourManager:registerGoalClass(GoalVehicleInFillTrigger.NAME, GoalVehicleInFillTrigger)
