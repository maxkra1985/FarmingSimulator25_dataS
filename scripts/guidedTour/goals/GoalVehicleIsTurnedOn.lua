-- Local values: GoalVehicleIsTurnedOn_mt
GoalVehicleIsTurnedOn = {}
GoalVehicleIsTurnedOn.NAME = "vehicleIsTurnedOn"
local GoalVehicleIsTurnedOn_mt = Class(GoalVehicleIsTurnedOn)

function GoalVehicleIsTurnedOn.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. "#vehicle", "Identifier of the vehicle", nil, true)
end

-- Upvalues: GoalVehicleIsTurnedOn_mt
-- Local values: self
function GoalVehicleIsTurnedOn.new(vehicleName, customMt)
	-- upvalues: (copy) GoalVehicleIsTurnedOn_mt
	local v6_ = customMt or GoalVehicleIsTurnedOn_mt
	local v7_ = setmetatable({}, v6_)
	v7_.vehicleName = vehicleName
	return v7_
end

function GoalVehicleIsTurnedOn:activate(tour, step)
	self.vehicle = g_guidedTourManager:getVehicleByName(self.vehicleName)
	if self.vehicle == nil then
		Logging.warning("GoalVehicleIsTurnedOn.activate: Vehicle \'%s\' not found", self.vehicleName)
		return
	elseif self.vehicle.getIsTurnedOn == nil then
		self.vehicle = nil
		Logging.warning("GoalVehicleIsTurnedOn.activate: Vehicle \'%s\' cannot be turned on", self.vehicleName)
	end
end

function GoalVehicleIsTurnedOn:deactivate()
	self.vehicle = nil
end

function GoalVehicleIsTurnedOn:isAchieved()
	return self.vehicle == nil and true or self.vehicle:getIsTurnedOn()
end

-- Local values: vehicleName
function GoalVehicleIsTurnedOn.createFromXML(xmlFile, key, baseDirectory, customEnvironment)
	local v13_ = xmlFile:getValue(key .. "#vehicle")
	if v13_ ~= nil then
		return GoalVehicleIsTurnedOn.new(v13_)
	end
	Logging.xmlWarning(xmlFile, "Missing \'vehicle\' for \'%s\'", key)
	return nil
end
g_guidedTourManager:registerGoalClass(GoalVehicleIsTurnedOn.NAME, GoalVehicleIsTurnedOn)
