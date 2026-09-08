-- Local values: ActionVehicleBlockDetaching_mt
ActionVehicleBlockDetaching = {}
ActionVehicleBlockDetaching.NAME = "vehicleBlockDetaching"
local ActionVehicleBlockDetaching_mt = Class(ActionVehicleBlockDetaching)

function ActionVehicleBlockDetaching.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. "#vehicle", "Name of the vehicle. If not defined the current vehicle is used", nil, false)
	schema:register(XMLValueType.BOOL, basePath .. "#isBlocked", "Value if detaching is blocked or not", nil, true)
end

-- Upvalues: ActionVehicleBlockDetaching_mt
-- Local values: self
function ActionVehicleBlockDetaching.new(vehicleName, isBlocked, customMt)
	-- upvalues: (copy) ActionVehicleBlockDetaching_mt
	local v7_ = customMt or ActionVehicleBlockDetaching_mt
	local v8_ = setmetatable({}, v7_)
	v8_.vehicleName = vehicleName
	v8_.isBlocked = isBlocked
	return v8_
end

-- Local values: vehicle
function ActionVehicleBlockDetaching:run(tour, step)
	local v10_ = g_localPlayer:getCurrentVehicle()
	if self.vehicleName ~= nil then
		v10_ = g_guidedTourManager:getVehicleByName(self.vehicleName)
	end
	if v10_ == nil then
		return false
	end
	if v10_.setIsDetachingBlocked ~= nil then
		v10_:setIsDetachingBlocked(self.isBlocked)
	end
	return true
end

-- Local values: vehicleName, isBlocked
function ActionVehicleBlockDetaching.createFromXML(xmlFile, key, baseDirectory, customEnvironment)
	local v13_ = xmlFile:getValue(key .. "#vehicle")
	local v14_ = xmlFile:getValue(key .. "#isBlocked")
	if v13_ == nil or v14_ == nil then
		return nil
	else
		return ActionVehicleBlockDetaching.new(v13_, v14_)
	end
end
g_guidedTourManager:registerActionClass(ActionVehicleBlockDetaching.NAME, ActionVehicleBlockDetaching)
