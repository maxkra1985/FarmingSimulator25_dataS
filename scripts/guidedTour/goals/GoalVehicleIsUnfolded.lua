-- Local values: GoalVehicleIsUnfolded_mt
GoalVehicleIsUnfolded = {}
GoalVehicleIsUnfolded.NAME = "vehicleIsUnfolded"
local GoalVehicleIsUnfolded_mt = Class(GoalVehicleIsUnfolded)

function GoalVehicleIsUnfolded.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. "#vehicle", "Identifier of the vehicle", nil, true)
end

-- Upvalues: GoalVehicleIsUnfolded_mt
-- Local values: self
function GoalVehicleIsUnfolded.new(vehicleName, customMt)
	-- upvalues: (copy) GoalVehicleIsUnfolded_mt
	local v6_ = customMt or GoalVehicleIsUnfolded_mt
	local v7_ = setmetatable({}, v6_)
	v7_.vehicleName = vehicleName
	return v7_
end

function GoalVehicleIsUnfolded:activate(tour, step)
	self.vehicle = g_guidedTourManager:getVehicleByName(self.vehicleName)
	if self.vehicle == nil then
		Logging.warning("GoalVehicleIsUnfolded.activate: Vehicle \'%s\' not found", self.vehicleName)
		return
	elseif self.vehicle.getIsUnfolded == nil then
		self.vehicle = nil
		Logging.warning("GoalVehicleIsUnfolded.activate: Vehicle \'%s\' cannot be unfolded", self.vehicleName)
	end
end

function GoalVehicleIsUnfolded:deactivate()
	self.vehicle = nil
end

function GoalVehicleIsUnfolded:isAchieved()
	return self.vehicle == nil and true or self.vehicle:getIsUnfolded()
end

-- Local values: vehicleName
function GoalVehicleIsUnfolded.createFromXML(xmlFile, key, baseDirectory, customEnvironment)
	local v13_ = xmlFile:getValue(key .. "#vehicle")
	if v13_ ~= nil then
		return GoalVehicleIsUnfolded.new(v13_)
	end
	Logging.xmlWarning(xmlFile, "Missing \'vehicle\' for \'%s\'", key)
	return nil
end
g_guidedTourManager:registerGoalClass(GoalVehicleIsUnfolded.NAME, GoalVehicleIsUnfolded)
