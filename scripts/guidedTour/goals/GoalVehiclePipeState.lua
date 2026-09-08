-- Local values: GoalVehiclePipeState_mt
GoalVehiclePipeState = {}
GoalVehiclePipeState.NAME = "vehiclePipeState"
local GoalVehiclePipeState_mt = Class(GoalVehiclePipeState)

function GoalVehiclePipeState.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. "#vehicle", "Identifier of the vehicle", nil, true)
	schema:register(XMLValueType.INT, basePath .. "#pipeState", "Target pipe state value", nil, true)
end

-- Upvalues: GoalVehiclePipeState_mt
-- Local values: self
function GoalVehiclePipeState.new(vehicleName, pipeState, customMt)
	-- upvalues: (copy) GoalVehiclePipeState_mt
	local v7_ = customMt or GoalVehiclePipeState_mt
	local v8_ = setmetatable({}, v7_)
	v8_.vehicleName = vehicleName
	v8_.pipeState = pipeState
	return v8_
end

function GoalVehiclePipeState:activate(tour, step)
	self.vehicle = g_guidedTourManager:getVehicleByName(self.vehicleName)
	if self.vehicle == nil then
		Logging.warning("GoalVehiclePipeState.activate: Vehicle \'%s\' not found", self.vehicleName)
		return
	elseif self.vehicle.getCurrentPipeState == nil then
		self.vehicle = nil
		Logging.warning("GoalVehiclePipeState.activate: Vehicle \'%s\' pipe cannot be unfolded", self.vehicleName)
	end
end

function GoalVehiclePipeState:deactivate()
	self.vehicle = nil
end

-- Local values: pipeState
function GoalVehiclePipeState:isAchieved()
	return self.vehicle == nil and true or self.vehicle:getCurrentPipeState() == self.pipeState
end

-- Local values: vehicleName, pipeState
function GoalVehiclePipeState.createFromXML(xmlFile, key, baseDirectory, customEnvironment)
	local v14_ = xmlFile:getValue(key .. "#vehicle")
	if v14_ == nil then
		Logging.xmlWarning(xmlFile, "Missing \'vehicle\' for \'%s\'", key)
		return nil
	end
	local v15_ = xmlFile:getValue(key .. "#pipeState")
	if v15_ ~= nil then
		return GoalVehiclePipeState.new(v14_, v15_)
	end
	Logging.xmlWarning(xmlFile, "Missing \'pipeState\' for \'%s\'", key)
	return nil
end
g_guidedTourManager:registerGoalClass(GoalVehiclePipeState.NAME, GoalVehiclePipeState)
