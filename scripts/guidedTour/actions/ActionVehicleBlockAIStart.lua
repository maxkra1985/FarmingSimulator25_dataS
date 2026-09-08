-- Local values: ActionVehicleBlockAIStart_mt
ActionVehicleBlockAIStart = {}
ActionVehicleBlockAIStart.NAME = "vehicleBlockAIStart"
local ActionVehicleBlockAIStart_mt = Class(ActionVehicleBlockAIStart)

function ActionVehicleBlockAIStart.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. "#vehicle", "Name of the vehicle. If not defined the current vehicle is used", nil, false)
	schema:register(XMLValueType.BOOL, basePath .. "#isBlocked", "Value if ai start is blocked or not", nil, true)
end

-- Upvalues: ActionVehicleBlockAIStart_mt
-- Local values: self
function ActionVehicleBlockAIStart.new(vehicleName, isBlocked, customMt)
	-- upvalues: (copy) ActionVehicleBlockAIStart_mt
	local v7_ = customMt or ActionVehicleBlockAIStart_mt
	local v8_ = setmetatable({}, v7_)
	v8_.vehicleName = vehicleName
	v8_.isBlocked = isBlocked
	return v8_
end

-- Local values: vehicle
function ActionVehicleBlockAIStart:run(tour, step)
	local v10_ = g_localPlayer:getCurrentVehicle()
	if self.vehicleName ~= nil then
		v10_ = g_guidedTourManager:getVehicleByName(self.vehicleName)
	end
	if v10_ == nil then
		return false
	end
	if v10_.setIsAIStartAllowed ~= nil then
		v10_:setIsAIStartAllowed(not self.isBlocked)
	end
	return true
end

-- Local values: vehicleName, isBlocked
function ActionVehicleBlockAIStart.createFromXML(xmlFile, key, baseDirectory, customEnvironment)
	local v13_ = xmlFile:getValue(key .. "#vehicle")
	local v14_ = xmlFile:getValue(key .. "#isBlocked")
	if v13_ == nil or v14_ == nil then
		return nil
	else
		return ActionVehicleBlockAIStart.new(v13_, v14_)
	end
end
g_guidedTourManager:registerActionClass(ActionVehicleBlockAIStart.NAME, ActionVehicleBlockAIStart)
