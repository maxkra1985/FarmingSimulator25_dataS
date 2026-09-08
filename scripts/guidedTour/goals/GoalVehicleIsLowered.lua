-- Local values: GoalVehicleIsLowered_mt
GoalVehicleIsLowered = {}
GoalVehicleIsLowered.NAME = "vehicleIsLowered"
local GoalVehicleIsLowered_mt = Class(GoalVehicleIsLowered)

function GoalVehicleIsLowered.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. "#vehicle", "Identifier of the vehicle", nil, true)
end

-- Upvalues: GoalVehicleIsLowered_mt
-- Local values: self
function GoalVehicleIsLowered.new(vehicleName, customMt)
	-- upvalues: (copy) GoalVehicleIsLowered_mt
	local v6_ = customMt or GoalVehicleIsLowered_mt
	local v7_ = setmetatable({}, v6_)
	v7_.vehicleName = vehicleName
	return v7_
end

function GoalVehicleIsLowered:activate(tour, step)
	self.vehicle = g_guidedTourManager:getVehicleByName(self.vehicleName)
	if self.vehicle == nil then
		Logging.warning("GoalVehicleIsLowered.activate: Vehicle \'%s\' not found", self.vehicleName)
		return
	elseif self.vehicle.getIsLowered == nil then
		self.vehicle = nil
		Logging.warning("GoalVehicleIsLowered.activate: Vehicle \'%s\' cannot be lowered", self.vehicleName)
	end
end

function GoalVehicleIsLowered:deactivate()
	self.vehicle = nil
end

function GoalVehicleIsLowered:isAchieved()
	return self.vehicle == nil and true or self.vehicle:getIsLowered()
end

-- Local values: vehicleName
function GoalVehicleIsLowered.createFromXML(xmlFile, key, baseDirectory, customEnvironment)
	local v13_ = xmlFile:getValue(key .. "#vehicle")
	if v13_ ~= nil then
		return GoalVehicleIsLowered.new(v13_)
	end
	Logging.xmlWarning(xmlFile, "Missing \'vehicle\' for \'%s\'", key)
	return nil
end
g_guidedTourManager:registerGoalClass(GoalVehicleIsLowered.NAME, GoalVehicleIsLowered)
