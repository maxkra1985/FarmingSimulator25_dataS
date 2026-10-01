GoalVehiclePipeState = {}
GoalVehiclePipeState.NAME = "vehiclePipeState"
local GoalVehiclePipeState_mt = Class(GoalVehiclePipeState)
function GoalVehiclePipeState.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. "#vehicle", "Identifier of the vehicle", nil, true)
	schema:register(XMLValueType.INT, basePath .. "#pipeState", "Target pipe state value", nil, true)
end
function GoalVehiclePipeState.new(vehicleName, pipeState, customMt)
	local self = setmetatable({}, customMt or GoalVehiclePipeState_mt)
	self.vehicleName = vehicleName
	self.pipeState = pipeState
	return self
end
function GoalVehiclePipeState:activate(tour, step)
	self.vehicle = g_guidedTourManager:getVehicleByName(self.vehicleName)
	if self.vehicle == nil then
		Logging.warning("GoalVehiclePipeState.activate: Vehicle '%s' not found", self.vehicleName)
	elseif self.vehicle.getCurrentPipeState == nil then
		self.vehicle = nil
		Logging.warning("GoalVehiclePipeState.activate: Vehicle '%s' pipe cannot be unfolded", self.vehicleName)
	end
end
function GoalVehiclePipeState:deactivate()
	self.vehicle = nil
end
function GoalVehiclePipeState:isAchieved()
	if self.vehicle == nil then
		return true
	else
		local pipeState = self.vehicle:getCurrentPipeState()
		return pipeState == self.pipeState
	end
end
function GoalVehiclePipeState.createFromXML(xmlFile, key, baseDirectory, customEnvironment)
	local vehicleName = xmlFile:getValue(key .. "#vehicle")
	if vehicleName == nil then
		Logging.xmlWarning(xmlFile, "Missing 'vehicle' for '%s'", key)
		return nil
	end
	local pipeState = xmlFile:getValue(key .. "#pipeState")
	if pipeState == nil then
		Logging.xmlWarning(xmlFile, "Missing 'pipeState' for '%s'", key)
		return nil
	else
		return GoalVehiclePipeState.new(vehicleName, pipeState)
	end
end
g_guidedTourManager:registerGoalClass(GoalVehiclePipeState.NAME, GoalVehiclePipeState)
