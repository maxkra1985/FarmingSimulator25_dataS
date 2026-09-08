-- Local values: GoalVehicleIsControlled_mt
GoalVehicleIsControlled = {}
GoalVehicleIsControlled.NAME = "vehicleIsControlled"
local GoalVehicleIsControlled_mt = Class(GoalVehicleIsControlled)

function GoalVehicleIsControlled.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. "#vehicle", "Identifier of the vehicle", nil, true)
	schema:register(XMLValueType.BOOL, basePath .. "#isControlled", "If vehicle should be controlled", true, false)
end

-- Upvalues: GoalVehicleIsControlled_mt
-- Local values: self
function GoalVehicleIsControlled.new(vehicleName, isControlled, customMt)
	-- upvalues: (copy) GoalVehicleIsControlled_mt
	local v7_ = customMt or GoalVehicleIsControlled_mt
	local v8_ = setmetatable({}, v7_)
	v8_.vehicleName = vehicleName
	v8_.isControlled = isControlled
	return v8_
end

function GoalVehicleIsControlled:activate(tour, step)
	self.vehicle = g_guidedTourManager:getVehicleByName(self.vehicleName)
	if self.vehicle == nil then
		Logging.warning("GoalVehicleIsControlled.activate: Vehicle \'%s\' not found", self.vehicleName)
	end
end

function GoalVehicleIsControlled:deactivate()
	self.vehicle = nil
end

function GoalVehicleIsControlled:isAchieved()
	if self.vehicle == nil then
		return true
	elseif self.isControlled then
		return g_localPlayer:getCurrentVehicle() == self.vehicle
	else
		return g_localPlayer:getCurrentVehicle() ~= self.vehicle
	end
end

-- Local values: vehicleName, isControlled
function GoalVehicleIsControlled.createFromXML(xmlFile, key, baseDirectory, customEnvironment)
	local v14_ = xmlFile:getValue(key .. "#vehicle")
	local v15_ = xmlFile:getValue(key .. "#isControlled", true)
	if v14_ ~= nil then
		return GoalVehicleIsControlled.new(v14_, v15_)
	end
	Logging.xmlWarning(xmlFile, "Missing \'vehicle\' for \'%s\'", key)
	return nil
end
g_guidedTourManager:registerGoalClass(GoalVehicleIsControlled.NAME, GoalVehicleIsControlled)
