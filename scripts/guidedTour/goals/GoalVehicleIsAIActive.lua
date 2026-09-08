-- Local values: GoalVehicleIsAIActive_mt
GoalVehicleIsAIActive = {}
GoalVehicleIsAIActive.NAME = "vehicleIsAIActive"
local GoalVehicleIsAIActive_mt = Class(GoalVehicleIsAIActive)

function GoalVehicleIsAIActive.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. "#vehicle", "Identifier of the vehicle", nil, true)
end

-- Upvalues: GoalVehicleIsAIActive_mt
-- Local values: self
function GoalVehicleIsAIActive.new(vehicleName, customMt)
	-- upvalues: (copy) GoalVehicleIsAIActive_mt
	local v6_ = customMt or GoalVehicleIsAIActive_mt
	local v7_ = setmetatable({}, v6_)
	v7_.vehicleName = vehicleName
	return v7_
end

function GoalVehicleIsAIActive:activate(tour, step)
	self.vehicle = g_guidedTourManager:getVehicleByName(self.vehicleName)
	if self.vehicle == nil then
		Logging.warning("GoalVehicleIsAIActive.activate: Vehicle \'%s\' not found", self.vehicleName)
		return
	elseif self.vehicle.getIsAIActive == nil then
		self.vehicle = nil
		Logging.warning("GoalVehicleIsAIActive.activate: Vehicle \'%s\' does not support AI", self.vehicleName)
	end
end

function GoalVehicleIsAIActive:deactivate()
	self.vehicle = nil
end

function GoalVehicleIsAIActive:isAchieved()
	return self.vehicle == nil and true or self.vehicle:getIsAIActive()
end

-- Local values: vehicleName
function GoalVehicleIsAIActive.createFromXML(xmlFile, key, baseDirectory, customEnvironment)
	local v13_ = xmlFile:getValue(key .. "#vehicle")
	if v13_ ~= nil then
		return GoalVehicleIsAIActive.new(v13_)
	end
	Logging.xmlWarning(xmlFile, "Missing \'vehicle\' for \'%s\'", key)
	return nil
end
g_guidedTourManager:registerGoalClass(GoalVehicleIsAIActive.NAME, GoalVehicleIsAIActive)
