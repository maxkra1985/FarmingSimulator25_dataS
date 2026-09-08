-- Local values: GoalVehicleDetached_mt
GoalVehicleDetached = {}
GoalVehicleDetached.NAME = "vehicleDetached"
local GoalVehicleDetached_mt = Class(GoalVehicleDetached)

function GoalVehicleDetached.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. "#vehicle", "Identifier of the vehicle", nil, true)
end

-- Upvalues: GoalVehicleDetached_mt
-- Local values: self
function GoalVehicleDetached.new(vehicleName, customMt)
	-- upvalues: (copy) GoalVehicleDetached_mt
	local v6_ = customMt or GoalVehicleDetached_mt
	local v7_ = setmetatable({}, v6_)
	v7_.vehicleName = vehicleName
	return v7_
end

function GoalVehicleDetached:activate(tour, step)
	self.vehicle = g_guidedTourManager:getVehicleByName(self.vehicleName)
	if self.vehicle == nil then
		Logging.warning("GoalVehicleDetached.activate: Vehicle \'%s\' not found", self.vehicleName)
	end
end

function GoalVehicleDetached:deactivate()
	self.vehicle = nil
end

-- Local values: attacherVehicle
function GoalVehicleDetached:isAchieved()
	return self.vehicle == nil and true or self.vehicle:getAttacherVehicle() == nil
end

-- Local values: vehicleName
function GoalVehicleDetached.createFromXML(xmlFile, key, baseDirectory, customEnvironment)
	local v13_ = xmlFile:getValue(key .. "#vehicle")
	if v13_ ~= nil then
		return GoalVehicleDetached.new(v13_)
	end
	Logging.xmlWarning(xmlFile, "Missing \'vehicle\' for \'%s\'", key)
	return nil
end
g_guidedTourManager:registerGoalClass(GoalVehicleDetached.NAME, GoalVehicleDetached)
